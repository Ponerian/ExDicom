defmodule ExDicom.Parser do
  @moduledoc """
  Core parsing functionality for DICOM files.
  Handles both explicit and implicit VR transfer syntaxes.
  """
  alias ExDicom.Element

  @dicom_prefix <<0x44, 0x49, 0x43, 0x4D>>

  @doc """
  Parses a DICOM file and returns a map of its elements.
  """
  def parse_file(path) do
    case File.read(path) do
      {:ok, data} -> parse_data(data)
      {:error, reason} -> {:error, "Failed to read file: #{reason}"}
    end
  end

  @doc """
  Parses DICOM data from a binary string.
  """
  def parse_data(<<_preamble::binary-size(128), @dicom_prefix, rest::binary>>) do
    parse_meta_information(rest, %{})
  end

  def parse_data(_), do: {:error, "Invalid DICOM format"}

  @doc """
  Parses the meta information group (0002,xxxx).
  """
  defp parse_meta_information(data, elements) do
    case parse_group_length(data) do
      {:ok, length, rest} ->
        meta_data = binary_part(rest, 0, length)
        dataset = binary_part(rest, length, byte_size(rest) - length)
        elements = parse_meta_elements(meta_data, elements)
        parse_dataset(dataset, elements)

      error ->
        error
    end
  end

  @doc """
  Parses the group length element at the start of meta information.
  """
  defp parse_group_length(
         <<0x02, 0x00, 0x00, 0x00, "UL", _length::little-size(16), value::little-size(32),
           rest::binary>>
       ) do
    {:ok, value, rest}
  end

  defp parse_group_length(_), do: {:error, "Invalid meta information group length"}

  @doc """
  Parses individual meta information elements.
  """
  defp parse_meta_elements(<<>>, elements), do: elements

  defp parse_meta_elements(
         <<group::little-size(16), element::little-size(16), rest::binary>>,
         elements
       ) do
    case parse_explicit_element(group, element, rest) do
      {:ok, elem, rest} ->
        elements = Map.put(elements, {group, element}, elem)
        parse_meta_elements(rest, elements)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parses the main dataset elements.
  """
  defp parse_dataset(data, elements) do
    parse_dataset_elements(data, elements, get_transfer_syntax(elements))
  end

  @doc """
  Gets the transfer syntax from parsed meta information.
  """
  defp get_transfer_syntax(elements) do
    case elements[{0x0002, 0x0010}] do
      %Element{value: "1.2.840.10008.1.2"} -> :implicit
      %Element{value: "1.2.840.10008.1.2.1"} -> :explicit
      # Default to explicit VR if not specified
      _ -> :explicit
    end
  end

  @doc """
  Parses elements in the dataset based on transfer syntax.
  """
  defp parse_dataset_elements(<<>>, elements, _), do: {:ok, elements}

  defp parse_dataset_elements(
         <<group::little-size(16), element::little-size(16), rest::binary>>,
         elements,
         transfer_syntax
       ) do
    case parse_element(group, element, rest, transfer_syntax) do
      {:ok, elem, rest} ->
        elements = Map.put(elements, {group, element}, elem)
        parse_dataset_elements(rest, elements, transfer_syntax)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parses a single element based on transfer syntax.
  """
  defp parse_element(group, element, data, :explicit) do
    parse_explicit_element(group, element, data)
  end

  defp parse_element(group, element, data, :implicit) do
    parse_implicit_element(group, element, data)
  end

  @doc """
  Parses an element with explicit VR.
  """
  defp parse_explicit_element(group, element, <<"SQ", rest::binary>>) do
    case get_explicit_length("SQ", rest) do
      # Undefined length sequence
      {:ok, 0xFFFFFFFF, rest} ->
        parse_undefined_length_sequence(rest)

      {:ok, length, rest} when length >= 0 and length <= byte_size(rest) ->
        parse_defined_length_sequence(rest, length)

      {:ok, _length, _rest} ->
        {:error, "Invalid sequence length"}

      error ->
        error
    end
  end

  defp parse_undefined_length_sequence(data) do
    # Sequence Delimiter Item: (FFFE,E0DD) with length 0
    delimiter = <<0xFE, 0xFF, 0xDD, 0xE0, 0x00, 0x00, 0x00, 0x00>>

    case parse_sequence_items(data, [], delimiter) do
      {:ok, items, rest} ->
        {:ok,
         %Element{
           # Original tag
           tag: {0x0008, 0x2112},
           vr: "SQ",
           # Undefined length
           length: 0xFFFFFFFF,
           value: items
         }, rest}

      error ->
        error
    end
  end

  defp parse_sequence_items(
         <<0xFE, 0xFF, 0xDD, 0xE0, 0x00, 0x00, 0x00, 0x00, rest::binary>>,
         items,
         _delimiter
       ) do
    {:ok, Enum.reverse(items), rest}
  end

  defp parse_sequence_items(
         <<0xFE, 0xFF, 0x00, 0xE0, length::little-32, rest::binary>>,
         items,
         delimiter
       ) do
    case parse_sequence_item(rest, length) do
      {:ok, item, rest} -> parse_sequence_items(rest, [item | items], delimiter)
      error -> error
    end
  end

  defp parse_sequence_items(_, _, _), do: {:error, "Invalid sequence format"}

  defp parse_defined_length_sequence(data, total_length) do
    case parse_sequence_items_with_length(data, [], total_length) do
      {:ok, items, rest} ->
        {:ok,
         %Element{
           tag: {0x0008, 0x2112},
           vr: "SQ",
           length: total_length,
           value: items
         }, rest}

      error ->
        error
    end
  end

  defp parse_sequence_items_with_length(rest, items, 0), do: {:ok, Enum.reverse(items), rest}

  defp parse_sequence_items_with_length(
         <<0xFE, 0xFF, 0x00, 0xE0, length::little-32, rest::binary>>,
         items,
         remaining_length
       )
       when remaining_length >= 8 + length do
    case parse_sequence_item(rest, length) do
      {:ok, item, rest} ->
        parse_sequence_items_with_length(rest, [item | items], remaining_length - (8 + length))

      error ->
        error
    end
  end

  defp parse_sequence_items_with_length(_, _, _),
    do: {:error, "Invalid sequence format or length"}

  defp parse_sequence_item(data, length) do
    value = binary_part(data, 0, length)
    rest = binary_part(data, length, byte_size(data) - length)
    {:ok, value, rest}
  end

  @doc """
  Gets the length field for explicit VR elements.
  """
  defp get_explicit_length(vr, data) when vr in ["OB", "OW", "SQ", "UN"] do
    <<0::size(16), length::little-size(32), rest::binary>> = data
    {:ok, length, rest}
  end

  defp get_explicit_length(_vr, <<length::little-size(16), rest::binary>>) do
    {:ok, length, rest}
  end

  @doc """
  Parses an element with implicit VR.
  """
  defp parse_implicit_element(group, element, <<length::little-size(32), rest::binary>>) do
    value = binary_part(rest, 0, length)
    rest = binary_part(rest, length, byte_size(rest) - length)
    vr = get_implicit_vr({group, element})

    {:ok, %Element{tag: {group, element}, vr: vr, length: length, value: decode_value(vr, value)},
     rest}
  end

  @doc """
  Decodes a value based on its VR (Value Representation).
  """
  defp decode_value("DS", value) do
    value
    |> String.trim()
    |> String.split("\\")
    |> Enum.map(fn num ->
      case String.contains?(num, ".") do
        true -> String.to_float(num)
        false -> String.to_integer(num) * 1.0
      end
    end)
  end

  defp decode_value("IS", value), do: String.trim(value) |> String.to_integer()
  defp decode_value("UI", value), do: String.trim(value)
  defp decode_value("CS", value), do: String.trim(value)
  defp decode_value("DA", value), do: String.trim(value)
  defp decode_value("TM", value), do: String.trim(value)
  defp decode_value("PN", value), do: String.trim(value)
  defp decode_value("LO", value), do: String.trim(value)
  defp decode_value("SH", value), do: String.trim(value)
  defp decode_value(_, value), do: value

  @doc """
  Gets the implicit VR for a given tag based on the DICOM dictionary.
  This is a simplified version - a complete implementation would need a full DICOM dictionary.
  """
  # Modality
  defp get_implicit_vr({0x0008, 0x0060}), do: "CS"
  # Patient's Name
  defp get_implicit_vr({0x0010, 0x0010}), do: "PN"
  # Patient ID
  defp get_implicit_vr({0x0010, 0x0020}), do: "LO"
  # Study Instance UID
  defp get_implicit_vr({0x0020, 0x000D}), do: "UI"
  # Series Instance UID
  defp get_implicit_vr({0x0020, 0x000E}), do: "UI"
  # Study ID
  defp get_implicit_vr({0x0020, 0x0010}), do: "SH"
  # Unknown
  defp get_implicit_vr(_), do: "UN"
end

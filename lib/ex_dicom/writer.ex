defmodule ExDicom.Writer do
  @moduledoc """
  Handles writing DICOM datasets to files.
  Supports both explicit and implicit VR transfer syntaxes.
  """

  alias ExDicom.{Dataset, Element, UID}

  @dicom_prefix <<0x44, 0x49, 0x43, 0x4D>>
  @implicit_vr_le "1.2.840.10008.1.2"
  @explicit_vr_le "1.2.840.10008.1.2.1"

  @doc """
  Writes a DICOM dataset to a file.

  ## Parameters
    * path - The file path to write to
    * dataset - The DICOM dataset to write
    * opts - Options for writing (optional)
      * :transfer_syntax - UID string for desired transfer syntax
      * :force - Boolean to force overwrite existing file

  ## Returns
    * {:ok, bytes_written} on success
    * {:error, reason} on failure
  """
  def write_file(path, %Dataset{} = dataset, opts \\ []) do
    transfer_syntax = Keyword.get(opts, :transfer_syntax, @explicit_vr_le)
    force = Keyword.get(opts, :force, false)

    with :ok <- validate_path(path, force) do
      case File.open(path, [:write, :binary]) do
        {:ok, file} ->
          # Now do a nested `with` for everything else
          with :ok <- write_preamble(file),
               :ok <- write_prefix(file),
               :ok <- write_meta_header(file, dataset, transfer_syntax),
               :ok <- write_dataset(file, dataset, transfer_syntax),
               {:ok, size} <- File.stat(path) do
            File.close(file)
            {:ok, size.size}
          else
            {:error, _reason} = error ->
              File.close(file)
              File.rm(path)
              error
          end

        {:error, reason} ->
          {:error, reason}
      end
    else
      error ->
        error
    end
  end

  @doc """
  Encodes a DICOM dataset to binary without writing to file.
  Useful for network transmission or in-memory operations.
  """
  def encode_dataset(%Dataset{} = dataset, transfer_syntax \\ @explicit_vr_le) do
    with {:ok, meta} <- encode_meta_header(dataset, transfer_syntax),
         {:ok, data} <- encode_elements(dataset, transfer_syntax) do
      {:ok, @dicom_prefix <> meta <> data}
    end
  end

  # Private functions

  defp encode_elements(dataset, transfer_syntax) do
    vr_type = get_vr_type(transfer_syntax)

    result =
      Enum.reduce_while(dataset.elements, {:ok, <<>>}, fn {_tag, element}, {:ok, acc} ->
        case encode_element(element, vr_type) do
          {:ok, binary} -> {:cont, {:ok, acc <> binary}}
          error -> {:halt, error}
        end
      end)

    result
  end

  defp encode_meta_header(dataset, transfer_syntax) do
    meta_elements = build_meta_elements(dataset, transfer_syntax)
    encoded_meta = encode_meta_elements(meta_elements)
    group_length = byte_size(encoded_meta)

    length_element = %Element{
      tag: {0x0002, 0x0000},
      vr: "UL",
      value: group_length
    }

    with {:ok, length_binary} <- encode_element(length_element, :explicit_vr) do
      {:ok, length_binary <> encoded_meta}
    end
  end

  defp validate_path(path, force) do
    cond do
      File.exists?(path) and not force ->
        {:error, :file_exists}

      not File.exists?(Path.dirname(path)) or File.mkdir_p(Path.dirname(path)) != :ok ->
        {:error, :permission_denied}

      true ->
        :ok
    end
  end

  defp write_preamble(file) do
    # Write 128 bytes of 0x00
    :ok = IO.binwrite(file, :binary.copy(<<0>>, 128))
  end

  defp write_prefix(file) do
    :ok = IO.binwrite(file, @dicom_prefix)
  end

  defp write_meta_header(file, dataset, transfer_syntax) do
    meta_elements = build_meta_elements(dataset, transfer_syntax)
    encoded_meta = encode_meta_elements(meta_elements)
    group_length = byte_size(encoded_meta)

    # Write File Meta Information Group Length
    length_element = %Element{
      tag: {0x0002, 0x0000},
      vr: "UL",
      value: group_length
    }

    :ok = write_element(file, length_element, :explicit_vr)
    :ok = IO.binwrite(file, encoded_meta)
  end

  defp build_meta_elements(dataset, transfer_syntax) do
    [
      %Element{
        tag: {0x0002, 0x0001},
        vr: "OB",
        value: <<0, 1>>
      },
      %Element{
        tag: {0x0002, 0x0002},
        vr: "UI",
        value: dataset.media_storage_sop_class_uid || dataset.sop_class_uid
      },
      %Element{
        tag: {0x0002, 0x0003},
        vr: "UI",
        value: dataset.media_storage_sop_instance_uid || dataset.sop_instance_uid
      },
      %Element{
        tag: {0x0002, 0x0010},
        vr: "UI",
        value: transfer_syntax
      },
      %Element{
        tag: {0x0002, 0x0012},
        vr: "UI",
        value: UID.implementation_class_uid()
      },
      %Element{
        tag: {0x0002, 0x0013},
        vr: "SH",
        value: UID.implementation_version_name()
      }
    ]
  end

  defp write_dataset(file, dataset, transfer_syntax) do
    vr_type = get_vr_type(transfer_syntax)

    Enum.reduce_while(dataset.elements, :ok, fn {_tag, element}, :ok ->
      case write_element(file, element, vr_type) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp write_element(file, %Element{} = element, vr_type) do
    with {:ok, binary} <- encode_element(element, vr_type) do
      IO.binwrite(file, binary)
    end
  end

  defp encode_element(%Element{tag: {group, element}, vr: vr, value: value}, vr_type) do
    tag = <<group::little-16, element::little-16>>

    case vr_type do
      :explicit_vr ->
        encode_explicit_element(tag, vr, value)

      :implicit_vr ->
        encode_implicit_element(tag, vr, value)
    end
  end

  defp encode_explicit_element(tag, vr, value) do
    encoded_value = encode_value(value, vr)
    value_length = byte_size(encoded_value)

    value_header =
      case vr do
        vr when vr in ["OB", "OW", "SQ", "UN"] ->
          <<vr::binary-size(2), 0::little-16, value_length::little-32>>

        _ ->
          <<vr::binary-size(2), value_length::little-16>>
      end

    {:ok, tag <> value_header <> encoded_value}
  end

  defp encode_implicit_element(tag, vr, value) do
    encoded_value = encode_value(value, vr)
    value_length = byte_size(encoded_value)

    {:ok, tag <> <<value_length::little-32>> <> encoded_value}
  end

  defp encode_value(value, vr) do
    case vr do
      "DA" -> pad_string(value, 8)
      "TM" -> pad_string(value, 16)
      "UI" -> String.trim(value) <> <<0>>
      "IS" -> Integer.to_string(value)
      "DS" -> Float.to_string(value)
      "PN" -> pad_string(value, 64)
      "LO" -> pad_string(value, 64)
      "SH" -> pad_string(value, 16)
      "CS" -> pad_string(String.upcase(value), 16)
      "AS" -> pad_string(value, 4)
      "OB" -> value
      "OW" -> value
      "UN" -> value
      _ -> value
    end
  end

  defp pad_string(str, max_length) when is_binary(str) do
    str
    |> String.slice(0, max_length)
    |> String.pad_trailing(max_length, " ")
  end

  defp get_vr_type(transfer_syntax) do
    case transfer_syntax do
      @implicit_vr_le -> :implicit_vr
      @explicit_vr_le -> :explicit_vr
      # Default to explicit VR
      _ -> :explicit_vr
    end
  end

  defp encode_meta_elements(elements) do
    elements
    |> Enum.sort_by(fn %Element{tag: {group, elem}} -> {group, elem} end)
    |> Enum.reduce(<<>>, fn element, acc ->
      {:ok, binary} = encode_element(element, :explicit_vr)
      acc <> binary
    end)
  end
end

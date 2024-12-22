defmodule ExDicom.VR do
  @moduledoc """
  Handles DICOM Value Representation (VR) types and operations.
  Provides validation and formatting for different VR types.
  """

  def validator("AE"), do: fn x -> Regex.match?(~r/^[A-Za-z0-9 _\-]*$/, x) end
  def validator("AS"), do: fn x -> Regex.match?(~r/^\d{3}[DWMY]$/, x) end
  def validator("AT"), do: &(&1 |> byte_size() == 4)
  def validator("CS"), do: fn x -> Regex.match?(~r/^[A-Z0-9 _]*$/, x) end
  def validator("DA"), do: fn x -> Regex.match?(~r/^\d{8}$/, x) end
  def validator("DS"), do: fn x -> Regex.match?(~r/^[\-+]?\d*\.?\d*[Ee][\-+]?\d+$/, x) end

  def validator("DT"),
    do: fn x ->
      Regex.match?(
        ~r/^\d{4}(?:\d{2}(?:\d{2}(?:\d{2}(?:\d{2}(?:\d{2}(?:\.\d{1,6})?)?)?)?)?)?(?:[\+\-]\d{4})?$/,
        x
      )
    end

  def validator("FL"), do: &(&1 |> byte_size() == 4)
  def validator("FD"), do: &(&1 |> byte_size() == 8)
  def validator("IS"), do: fn x -> Regex.match?(~r/^[\-+]?\d+$/, x) end
  def validator("LO"), do: fn x -> Regex.match?(~r/^[^\x00-\x1F]*$/, x) end
  def validator("LT"), do: fn x -> Regex.match?(~r/^[^\x00-\x1F]*$/, x) end
  def validator("OB"), do: &is_binary/1
  def validator("OD"), do: &is_binary/1
  def validator("OF"), do: &is_binary/1
  def validator("OW"), do: &is_binary/1
  def validator("PN"), do: fn x -> Regex.match?(~r/^[^\x00-\x1F]*$/, x) end
  def validator("SH"), do: fn x -> Regex.match?(~r/^[^\x00-\x1F]*$/, x) end
  def validator("SL"), do: &(&1 |> byte_size() == 4)
  def validator("SQ"), do: &is_list/1
  def validator("SS"), do: &(&1 |> byte_size() == 2)
  def validator("ST"), do: fn x -> Regex.match?(~r/^[^\x00-\x1F]*$/, x) end

  def validator("TM"),
    do: fn x -> Regex.match?(~r/^(?:\d{2}(?:\d{2}(?:\d{2}(?:\.\d{1,6})?)?)?)?$/, x) end

  def validator("UI"), do: fn x -> Regex.match?(~r/^[0-9\.]*$/, x) end
  def validator("UL"), do: &(&1 |> byte_size() == 4)
  def validator("UN"), do: &is_binary/1
  def validator("US"), do: &(&1 |> byte_size() == 2)
  def validator("UT"), do: fn x -> Regex.match?(~r/^[^\x00-\x1F]*$/, x) end
  def validator(_), do: nil

  @vr_types %{
    "AE" => %{
      name: "Application Entity",
      max_length: 16,
      pad_char: " "
    },
    "AS" => %{
      name: "Age String",
      max_length: 4,
      pad_char: " "
    },
    "AT" => %{
      name: "Attribute Tag",
      max_length: 4,
      is_binary: true
    },
    "CS" => %{
      name: "Code String",
      max_length: 16,
      pad_char: " "
    },
    "DA" => %{
      name: "Date",
      max_length: 8,
      pad_char: " "
    },
    "DS" => %{
      name: "Decimal String",
      max_length: 16,
      pad_char: " "
    },
    "DT" => %{
      name: "Date Time",
      max_length: 26,
      pad_char: " "
    },
    "FL" => %{
      name: "Floating Point Single",
      max_length: 4,
      is_binary: true
    },
    "FD" => %{
      name: "Floating Point Double",
      max_length: 8,
      is_binary: true
    },
    "IS" => %{
      name: "Integer String",
      max_length: 12,
      pad_char: " "
    },
    "LO" => %{
      name: "Long String",
      max_length: 64,
      pad_char: " "
    },
    "LT" => %{
      name: "Long Text",
      max_length: 10240,
      pad_char: " "
    },
    "OB" => %{
      name: "Other Byte",
      is_binary: true
    },
    "OD" => %{
      name: "Other Double",
      is_binary: true
    },
    "OF" => %{
      name: "Other Float",
      is_binary: true
    },
    "OW" => %{
      name: "Other Word",
      is_binary: true
    },
    "PN" => %{
      name: "Person Name",
      max_length: 64,
      pad_char: " "
    },
    "SH" => %{
      name: "Short String",
      max_length: 16,
      pad_char: " "
    },
    "SL" => %{
      name: "Signed Long",
      max_length: 4,
      is_binary: true
    },
    "SQ" => %{
      name: "Sequence of Items"
    },
    "SS" => %{
      name: "Signed Short",
      max_length: 2,
      is_binary: true
    },
    "ST" => %{
      name: "Short Text",
      max_length: 1024,
      pad_char: " "
    },
    "TM" => %{
      name: "Time",
      max_length: 16,
      pad_char: " "
    },
    "UI" => %{
      name: "Unique Identifier",
      max_length: 64,
      pad_char: "\0"
    },
    "UL" => %{
      name: "Unsigned Long",
      max_length: 4,
      is_binary: true
    },
    "UN" => %{
      name: "Unknown",
      is_binary: true
    },
    "US" => %{
      name: "Unsigned Short",
      max_length: 2,
      is_binary: true
    },
    "UT" => %{
      name: "Unlimited Text",
      pad_char: " "
    }
  }

  @doc """
  Returns information about a VR type.
  """
  @spec info(String.t()) :: map | nil
  def info(vr) when is_binary(vr), do: Map.get(@vr_types, vr)

  @doc """
  Validates a value against its VR type.
  """
  @spec validate(any, String.t()) :: :ok | {:error, String.t()}
  def validate(value, vr) do
    case validator(vr) do
      nil ->
        {:error, "Unknown VR type: #{vr}"}

      validator_fn ->
        if validator_fn.(value) do
          :ok
        else
          {:error, "Invalid value for VR type #{vr}"}
        end
    end
  end

  @doc """
  Returns whether a VR type is binary.
  """
  @spec binary?(String.t()) :: boolean
  def binary?(vr) do
    case info(vr) do
      nil -> false
      info -> Map.get(info, :is_binary, false)
    end
  end

  @doc """
  Returns the maximum length for a VR type, if applicable.
  """
  @spec max_length(String.t()) :: integer | nil
  def max_length(vr) do
    case info(vr) do
      nil -> nil
      info -> Map.get(info, :max_length)
    end
  end

  @doc """
  Returns the padding character for a VR type, if applicable.
  """
  @spec pad_char(String.t()) :: String.t() | nil
  def pad_char(vr) do
    case info(vr) do
      nil -> nil
      info -> Map.get(info, :pad_char)
    end
  end
end

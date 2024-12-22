defmodule ExDicom.Tag do
  @moduledoc """
  Handles DICOM tag operations and lookup.
  Provides functions for working with group/element numbers and tag names.
  """

  @type t :: {char, char}

  @private_creator_block 0x0010..0x00FF
  @private_group_range 0x0001..0xFFFF

  @doc """
  Creates a new tag from group and element numbers.
  """
  @spec new(non_neg_integer, non_neg_integer) :: t
  def new(group, element) when is_integer(group) and is_integer(element) do
    {group, element}
  end

  @doc """
  Converts a tag to its string representation.
  """
  @spec to_string(t) :: String.t()
  def to_string({group, element}) do
    "(#{Integer.to_string(group, 16)},#{Integer.to_string(element, 16)})"
  end

  @doc """
  Parses a tag from its string representation.
  """
  @spec parse(String.t()) :: {:ok, t} | {:error, String.t()}
  def parse("(" <> rest) do
    case String.split(rest, ",") do
      [group, element_with_paren] ->
        element = String.trim_trailing(element_with_paren, ")")

        with {group_num, ""} <- Integer.parse(group, 16),
             {element_num, ""} <- Integer.parse(element, 16) do
          {:ok, {group_num, element_num}}
        else
          _ -> {:error, "Invalid tag format"}
        end

      _ ->
        {:error, "Invalid tag format"}
    end
  end

  def parse(_), do: {:error, "Invalid tag format"}

  @doc """
  Checks if a tag is private.
  """
  @spec private?(t) :: boolean
  def private?({group, _element}) do
    rem(group, 2) == 1
  end

  @doc """
  Checks if a tag is a private creator.
  """
  @spec private_creator?(t) :: boolean
  def private_creator?({group, element}) do
    private?({group, element}) and element in @private_creator_block
  end

  @doc """
  Checks if a group number is in the valid private group range.
  """
  @spec valid_private_group?(non_neg_integer) :: boolean
  def valid_private_group?(group), do: group in @private_group_range

  @doc """
  Compares two tags for sorting.
  """
  @spec compare(t, t) :: :lt | :eq | :gt
  def compare({group1, element1}, {group2, element2}) do
    cond do
      group1 < group2 -> :lt
      group1 > group2 -> :gt
      element1 < element2 -> :lt
      element1 > element2 -> :gt
      true -> :eq
    end
  end
end

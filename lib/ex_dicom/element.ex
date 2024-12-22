defmodule ExDicom.Element do
  @moduledoc """
  Represents a single DICOM data element.
  """

  defstruct [:tag, :vr, :length, :value]
end

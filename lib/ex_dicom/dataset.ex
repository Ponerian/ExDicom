defmodule ExDicom.Dataset do
  @moduledoc """
  Represents a DICOM dataset with convenient access methods.
  Implements Enumerable and Access protocols.
  """

  defstruct elements: %{}, meta: %{}
end

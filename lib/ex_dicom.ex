defmodule ExDicom do
  @moduledoc """
  Main interface module for the DICOM library.
  Provides high-level functions for working with DICOM files.
  """

  defdelegate parse_file(path), to: ExDicom.Parser
  defdelegate write_file(path, dataset), to: ExDicom.Writer
end

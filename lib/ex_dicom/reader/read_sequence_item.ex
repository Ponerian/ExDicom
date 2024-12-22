defmodule ExDicom.Reader.ReadSequenceItem do
  @moduledoc """
  Internal helper functions for parsing DICOM elements
  """

  alias ExDicom.ByteStream
  alias ExDicom.Reader.ReadTag

  @doc """
  Reads the tag and length of a sequence item.

  Returns a tuple of {:ok, element, byte_stream} where:
    * element is a map with the following keys:
      * :tag - string for the tag of this element in the format xggggeeee
      * :length - the number of bytes in this item or 4294967295 if undefined
      * :data_offset - the offset into the byteStream of the data for this item
    * byte_stream is the remaining byte stream after reading

  ## Parameters
    * byte_stream - The byte stream to read from. Must implement the ByteStream protocol

  ## Returns
    * {:ok, element, byte_stream} - Successfully read sequence item
    * raises ArgumentError - If byte_stream is nil
    * raises RuntimeError - If the sequence item tag (FFFE,E000) is not found
  """
  @spec read_sequence_item(ByteStream.t() | nil) ::
          {:ok, %{tag: String.t(), length: integer(), data_offset: integer()}, ByteStream.t()}
          | no_return()
  def read_sequence_item(nil) do
    raise ArgumentError, "missing required parameter 'byte_stream'"
  end

  def read_sequence_item(byte_stream) do
    with {:ok, tag, read_tag_byte_stream} <- ReadTag.read_tag(byte_stream),
         {:ok, byte_length, stream_after_length} <-
           ByteStream.read_uint32(read_tag_byte_stream),
         position <- ByteStream.get_position(stream_after_length) do
      element = %{
        tag: tag,
        length: byte_length,
        data_offset: position
      }

      # Verify the sequence item tag
      if element.tag != "xfffee000" do
        raise "read_sequence_item: item tag (FFFE,E000) not found at offset #{byte_stream.position()}"
      end

      {:ok, element, stream_after_length}
    end
  end
end
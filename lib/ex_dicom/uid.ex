defmodule ExDicom.UID do
  @moduledoc """
  Handles DICOM Unique Identifier (UID) operations.
  Provides comprehensive support for:
  - Standard DICOM UIDs lookup and validation
  - UID generation following DICOM rules
  - Transfer Syntax identification
  - SOP Class lookup
  - Well-known UIDs for common DICOM services
  """

  # Implementation-specific UIDs
  @implementation_class_uid "1.2.826.0.1.3680043.9.7134.1.1"
  @implementation_version_name "ELIXIR_DICOM_1.0"

  # Root UIDs
  @dicom_root "1.2.840.10008"
  # Example organization root
  @org_root "1.2.826.0.1.3680043.9.7134"

  # Transfer Syntax UIDs
  @transfer_syntax_uids %{
    implicit_vr_le: "1.2.840.10008.1.2",
    explicit_vr_le: "1.2.840.10008.1.2.1",
    explicit_vr_be: "1.2.840.10008.1.2.2",
    deflated_explicit_vr_le: "1.2.840.10008.1.2.1.99",
    jpeg_baseline: "1.2.840.10008.1.2.4.50",
    jpeg_extended: "1.2.840.10008.1.2.4.51",
    jpeg_lossless: "1.2.840.10008.1.2.4.70",
    jpeg_ls_lossless: "1.2.840.10008.1.2.4.80",
    jpeg_ls_lossy: "1.2.840.10008.1.2.4.81",
    jpeg_2000_lossless: "1.2.840.10008.1.2.4.90",
    jpeg_2000_lossy: "1.2.840.10008.1.2.4.91",
    mpeg2: "1.2.840.10008.1.2.4.100",
    rle_lossless: "1.2.840.10008.1.2.5"
  }

  # SOP Class UIDs
  @sop_class_uids %{
    # Storage
    ct_image: "1.2.840.10008.5.1.4.1.1.2",
    enhanced_ct_image: "1.2.840.10008.5.1.4.1.1.2.1",
    legacy_converted_enhanced_ct_image: "1.2.840.10008.5.1.4.1.1.2.2",
    mr_image: "1.2.840.10008.5.1.4.1.1.4",
    enhanced_mr_image: "1.2.840.10008.5.1.4.1.1.4.1",
    mr_spectroscopy: "1.2.840.10008.5.1.4.1.1.4.2",
    enhanced_mr_color_image: "1.2.840.10008.5.1.4.1.1.4.3",
    legacy_converted_enhanced_mr_image: "1.2.840.10008.5.1.4.1.1.4.4",
    ultrasound_image: "1.2.840.10008.5.1.4.1.1.6.1",
    enhanced_us_volume: "1.2.840.10008.5.1.4.1.1.6.2",
    secondary_capture: "1.2.840.10008.5.1.4.1.1.7",
    multi_frame_true_color_sc: "1.2.840.10008.5.1.4.1.1.7.4",
    pet_image: "1.2.840.10008.5.1.4.1.1.128",
    enhanced_pet_image: "1.2.840.10008.5.1.4.1.1.130",
    legacy_converted_enhanced_pet_image: "1.2.840.10008.5.1.4.1.1.128.1",
    digital_xray: "1.2.840.10008.5.1.4.1.1.1.1",
    digital_mammography: "1.2.840.10008.5.1.4.1.1.1.2",
    digital_intra_oral_xray: "1.2.840.10008.5.1.4.1.1.1.3",

    # Non-Image Objects
    raw_data: "1.2.840.10008.5.1.4.1.1.66",
    spatial_registration: "1.2.840.10008.5.1.4.1.1.66.1",
    spatial_fiducials: "1.2.840.10008.5.1.4.1.1.66.2",
    deformable_registration: "1.2.840.10008.5.1.4.1.1.66.3",
    segmentation: "1.2.840.10008.5.1.4.1.1.66.4",
    surface_segmentation: "1.2.840.10008.5.1.4.1.1.66.5",
    structured_report: "1.2.840.10008.5.1.4.1.1.88.11",

    # Service Class UIDs
    verification_scp: "1.2.840.10008.1.1",
    storage_scp: "1.2.840.10008.1.2",
    query_retrieve_scp: "1.2.840.10008.1.3"
  }

  # Well-known DIMSE Service UIDs
  @service_uids %{
    verification: "1.2.840.10008.1.1",
    storage_commitment: "1.2.840.10008.1.20.1",
    study_root_query_retrieve: "1.2.840.10008.5.1.4.1.2.2.1",
    patient_root_query_retrieve: "1.2.840.10008.5.1.4.1.2.1.1",
    modality_worklist: "1.2.840.10008.5.1.4.31"
  }

  @doc """
  Returns the implementation class UID for this library.
  """
  @spec implementation_class_uid :: String.t()
  def implementation_class_uid, do: @implementation_class_uid

  @doc """
  Returns the implementation version name.
  """
  @spec implementation_version_name :: String.t()
  def implementation_version_name, do: @implementation_version_name

  @doc """
  Looks up a transfer syntax name by its UID.
  Returns nil if the UID is not recognized.

  ## Examples

      iex> Dicom.UID.lookup_transfer_syntax("1.2.840.10008.1.2")
      :implicit_vr_le

      iex> Dicom.UID.lookup_transfer_syntax("unknown")
      nil
  """
  @spec lookup_transfer_syntax(String.t()) :: atom | nil
  def lookup_transfer_syntax(uid) do
    {name, _uid} = Enum.find(@transfer_syntax_uids, {nil, nil}, fn {_k, v} -> v == uid end)
    name
  end

  @doc """
  Gets a transfer syntax UID by name.
  Returns nil if the name is not recognized.

  ## Examples

      iex> Dicom.UID.transfer_syntax(:implicit_vr_le)
      "1.2.840.10008.1.2"

      iex> Dicom.UID.transfer_syntax(:unknown)
      nil
  """
  @spec transfer_syntax(atom) :: String.t() | nil
  def transfer_syntax(name), do: Map.get(@transfer_syntax_uids, name)

  @doc """
  Looks up a SOP class name by its UID.
  Returns nil if the UID is not recognized.

  ## Examples

      iex> Dicom.UID.lookup_sop_class("1.2.840.10008.5.1.4.1.1.2")
      :ct_image

      iex> Dicom.UID.lookup_sop_class("unknown")
      nil
  """
  @spec lookup_sop_class(String.t()) :: atom | nil
  def lookup_sop_class(uid) do
    {name, _uid} = Enum.find(@sop_class_uids, {nil, nil}, fn {_k, v} -> v == uid end)
    name
  end

  @doc """
  Gets a SOP class UID by name.
  Returns nil if the name is not recognized.

  ## Examples

      iex> Dicom.UID.sop_class(:ct_image)
      "1.2.840.10008.5.1.4.1.1.2"

      iex> Dicom.UID.sop_class(:unknown)
      nil
  """
  @spec sop_class(atom) :: String.t() | nil
  def sop_class(name), do: Map.get(@sop_class_uids, name)

  @doc """
  Gets a service UID by name.
  Returns nil if the name is not recognized.

  ## Examples

      iex> Dicom.UID.service(:verification)
      "1.2.840.10008.1.1"

      iex> Dicom.UID.service(:unknown)
      nil
  """
  @spec service(atom) :: String.t() | nil
  def service(name), do: Map.get(@service_uids, name)

  @doc """
  Validates a UID string according to DICOM rules:
  - Must be a series of numbers separated by periods
  - Maximum length of 64 characters
  - Must not start with 0 or contain leading zeros
  - Must not end with a period
  - Component values must be less than 2^32

  ## Examples

      iex> Dicom.UID.valid?("1.2.840.10008.1.2")
      true

      iex> Dicom.UID.valid?("1.2.03.4")
      false
  """
  @spec valid?(String.t()) :: boolean
  def valid?(uid) when is_binary(uid) do
    with true <- String.length(uid) <= 64,
         true <- String.match?(uid, ~r/^\d+(\.\d+)*$/),
         components <- String.split(uid, "."),
         true <- not Enum.any?(components, &String.starts_with?(&1, "0")),
         true <- Enum.all?(components, &(String.to_integer(&1) < 4_294_967_296)) do
      true
    else
      _ -> false
    end
  end

  def valid?(_), do: false

  @doc """
  Generates a new unique UID under the organization root.
  Uses timestamp and random components to ensure uniqueness.

  ## Examples

      iex> Dicom.UID.generate()
      "1.2.826.0.1.3680043.9.7134.1.2.20240321123456.123456"
  """
  @spec generate :: String.t()
  def generate do
    timestamp =
      DateTime.utc_now()
      |> DateTime.to_string()
      |> String.replace(~r/[^0-9]/, "")
      |> String.slice(0, 14)

    random =
      :rand.uniform(999_999)
      |> Integer.to_string()
      |> String.pad_leading(6, "0")

    "#{@org_root}.1.2.#{timestamp}.#{random}"
  end

  @doc """
  Returns whether a UID is in the DICOM root namespace.

  ## Examples

      iex> Dicom.UID.dicom_root?("1.2.840.10008.1.2")
      true

      iex> Dicom.UID.dicom_root?("1.2.826.0.1.3680043.9.7134.1.1")
      false
  """
  @spec dicom_root?(String.t()) :: boolean
  def dicom_root?(uid) when is_binary(uid) do
    String.starts_with?(uid, @dicom_root <> ".")
  end

  def dicom_root?(_), do: false

  @doc """
  Returns whether a UID is in the organization's root namespace.

  ## Examples

      iex> Dicom.UID.org_root?("1.2.826.0.1.3680043.9.7134.1.1")
      true

      iex> Dicom.UID.org_root?("1.2.840.10008.1.2")
      false
  """
  @spec org_root?(String.t()) :: boolean
  def org_root?(uid) when is_binary(uid) do
    String.starts_with?(uid, @org_root <> ".")
  end

  def org_root?(_), do: false

  @doc """
  Returns all available transfer syntax names.

  ## Examples

      iex> Dicom.UID.available_transfer_syntaxes()
      [:implicit_vr_le, :explicit_vr_le, :explicit_vr_be, ...]
  """
  @spec available_transfer_syntaxes :: [atom]
  def available_transfer_syntaxes do
    Map.keys(@transfer_syntax_uids)
  end

  @doc """
  Returns all available SOP class names.

  ## Examples

      iex> Dicom.UID.available_sop_classes()
      [:ct_image, :mr_image, :enhanced_mr_image, ...]
  """
  @spec available_sop_classes :: [atom]
  def available_sop_classes do
    Map.keys(@sop_class_uids)
  end

  @doc """
  Returns all available service names.

  ## Examples

      iex> Dicom.UID.available_services()
      [:verification, :storage_commitment, :study_root_query_retrieve, ...]
  """
  @spec available_services :: [atom]
  def available_services do
    Map.keys(@service_uids)
  end

  @doc """
  Returns whether a given UID represents a transfer syntax.

  ## Examples

      iex> Dicom.UID.transfer_syntax?("1.2.840.10008.1.2")
      true

      iex> Dicom.UID.transfer_syntax?("1.2.840.10008.5.1.4.1.1.2")
      false
  """
  @spec transfer_syntax?(String.t()) :: boolean
  def transfer_syntax?(uid) when is_binary(uid) do
    Enum.member?(Map.values(@transfer_syntax_uids), uid)
  end

  def transfer_syntax?(_), do: false

  @doc """
  Returns whether a given UID represents a SOP class.

  ## Examples

      iex> Dicom.UID.sop_class?("1.2.840.10008.5.1.4.1.1.2")
      true

      iex> Dicom.UID.sop_class?("1.2.840.10008.1.2")
      false
  """
  @spec sop_class?(String.t()) :: boolean
  def sop_class?(uid) when is_binary(uid) do
    Enum.member?(Map.values(@sop_class_uids), uid)
  end

  def sop_class?(_), do: false

  @doc """
  Returns whether a given UID represents a service.

  ## Examples

      iex> Dicom.UID.service?("1.2.840.10008.1.1")
      true

      iex> Dicom.UID.service?("1.2.840.10008.5.1.4.1.1.2")
      false
  """
  @spec service?(String.t()) :: boolean
  def service?(uid) when is_binary(uid) do
    Enum.member?(Map.values(@service_uids), uid)
  end

  def service?(_), do: false

  @doc """
  Returns a friendly description for common UIDs.
  Useful for logging and display purposes.

  ## Examples

      iex> Dicom.UID.describe("1.2.840.10008.1.2")
      "Implicit VR Little Endian Transfer Syntax"

      iex> Dicom.UID.describe("1.2.840.10008.5.1.4.1.1.2")
      "CT Image Storage"

      iex> Dicom.UID.describe("unknown")
      nil
  """
  @spec describe(String.t()) :: String.t() | nil
  def describe(uid) when is_binary(uid) do
    cond do
      transfer_syntax?(uid) ->
        case lookup_transfer_syntax(uid) do
          :implicit_vr_le -> "Implicit VR Little Endian Transfer Syntax"
          :explicit_vr_le -> "Explicit VR Little Endian Transfer Syntax"
          :explicit_vr_be -> "Explicit VR Big Endian Transfer Syntax"
          :deflated_explicit_vr_le -> "Deflated Explicit VR Little Endian Transfer Syntax"
          :jpeg_baseline -> "JPEG Baseline (Process 1) Transfer Syntax"
          :jpeg_extended -> "JPEG Extended (Process 2 & 4) Transfer Syntax"
          :jpeg_lossless -> "JPEG Lossless, Non-Hierarchical Transfer Syntax"
          :jpeg_ls_lossless -> "JPEG-LS Lossless Transfer Syntax"
          :jpeg_ls_lossy -> "JPEG-LS Lossy (Near-Lossless) Transfer Syntax"
          :jpeg_2000_lossless -> "JPEG 2000 Lossless Transfer Syntax"
          :jpeg_2000_lossy -> "JPEG 2000 Lossy Transfer Syntax"
          :mpeg2 -> "MPEG2 Main Profile @ Main Level Transfer Syntax"
          :rle_lossless -> "RLE Lossless Transfer Syntax"
          _ -> nil
        end

      sop_class?(uid) ->
        case lookup_sop_class(uid) do
          :ct_image -> "CT Image Storage"
          :mr_image -> "MR Image Storage"
          :enhanced_mr_image -> "Enhanced MR Image Storage"
          :ultrasound_image -> "Ultrasound Image Storage"
          :secondary_capture -> "Secondary Capture Image Storage"
          :pet_image -> "Positron Emission Tomography Image Storage"
          :digital_xray -> "Digital X-Ray Image Storage"
          :raw_data -> "Raw Data Storage"
          :structured_report -> "Basic Text Structured Report Storage"
          _ -> nil
        end

      service?(uid) ->
        case Enum.find(@service_uids, fn {_k, v} -> v == uid end) do
          {:verification, _} -> "Verification Service"
          {:storage_commitment, _} -> "Storage Commitment Push Model"
          {:study_root_query_retrieve, _} -> "Study Root Query/Retrieve Information Model"
          {:patient_root_query_retrieve, _} -> "Patient Root Query/Retrieve Information Model"
          {:modality_worklist, _} -> "Modality Worklist Information Model"
          _ -> nil
        end

      true ->
        nil
    end
  end

  def describe(_), do: nil

  @doc """
  Groups multiple UIDs by their type (transfer syntax, SOP class, service).
  Useful for analyzing collections of UIDs.

  ## Examples

      iex> uids = ["1.2.840.10008.1.2", "1.2.840.10008.5.1.4.1.1.2"]
      iex> Dicom.UID.group(uids)
      %{
        transfer_syntax: ["1.2.840.10008.1.2"],
        sop_class: ["1.2.840.10008.5.1.4.1.1.2"],
        service: [],
        unknown: []
      }
  """
  @spec group([String.t()]) :: %{
          transfer_syntax: [String.t()],
          sop_class: [String.t()],
          service: [String.t()],
          unknown: [String.t()]
        }
  def group(uids) when is_list(uids) do
    Enum.reduce(uids, %{transfer_syntax: [], sop_class: [], service: [], unknown: []}, fn uid,
                                                                                          acc ->
      cond do
        transfer_syntax?(uid) -> Map.update!(acc, :transfer_syntax, &[uid | &1])
        sop_class?(uid) -> Map.update!(acc, :sop_class, &[uid | &1])
        service?(uid) -> Map.update!(acc, :service, &[uid | &1])
        true -> Map.update!(acc, :unknown, &[uid | &1])
      end
    end)
  end

  def group(_), do: %{transfer_syntax: [], sop_class: [], service: [], unknown: []}
end

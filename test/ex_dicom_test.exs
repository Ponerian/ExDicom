defmodule ExDicomTest do
  use ExUnit.Case
  doctest ExDicom

  alias ExDicom.{Dataset, Element, Tag, VR}

  @mrbrain_path "test/fixtures/brain.DCM"

  describe "parse_file/1" do
    test "successfully parses brain.DCM" do
      assert {:ok, dataset} = ExDicom.parse_file(@mrbrain_path)

      # Test some common DICOM attributes
      assert get_in(dataset, [{0x0008, 0x0060}]) == %ExDicom.Element{
               tag: {0x0008, 0x0060},
               vr: "CS",
               length: 2,
               value: "MR"
             }

      # Test Patient Name (assuming it exists in the file)
      patient_name = get_in(dataset, [{0x0010, 0x0010}])
      assert patient_name.vr == "PN"

      # Test Study Instance UID (should always exist)
      study_uid = get_in(dataset, [{0x0020, 0x000D}])
      assert study_uid.vr == "UI"
      assert is_binary(study_uid.value)
    end

    test "returns error for non-existent file" do
      assert {:error, _reason} = ExDicom.parse_file("non_existent.dcm")
    end
  end

  describe "Element struct" do
    test "creates element with basic attributes" do
      element = %Element{
        tag: {0x0010, 0x0010},
        vr: "PN",
        length: 10,
        value: "JOHN^DOE"
      }

      assert element.tag == {0x0010, 0x0010}
      assert element.vr == "PN"
      assert element.length == 10
      assert element.value == "JOHN^DOE"
    end
  end

  describe "VR module" do
    test "validates person name (PN) value representation" do
      assert :ok == VR.validate("JOHN^DOE", "PN")
      assert {:error, _} = VR.validate("\x00invalid", "PN")
    end

    test "validates date (DA) value representation" do
      assert :ok == VR.validate("20240315", "DA")
      assert {:error, _} = VR.validate("invalid", "DA")
    end

    test "validates time (TM) value representation" do
      assert :ok == VR.validate("235959.999", "TM")
      assert {:error, _} = VR.validate("invalid", "TM")
    end

    test "gets correct VR info" do
      pn_info = VR.info("PN")
      assert pn_info.name == "Person Name"
      assert pn_info.max_length == 64
      assert pn_info.pad_char == " "
    end
  end

  describe "Tag module" do
    test "creates new tag" do
      tag = Tag.new(0x0010, 0x0010)
      assert tag == {0x0010, 0x0010}
    end

    test "converts tag to string" do
      assert Tag.to_string({0x0010, 0x0010}) == "(10,10)"
    end

    test "parses tag from string" do
      assert {:ok, {0x0010, 0x0010}} == Tag.parse("(10,10)")
      assert {:error, _} = Tag.parse("invalid")
    end

    test "identifies private tags" do
      assert Tag.private?({0x0011, 0x0010}) == true
      assert Tag.private?({0x0010, 0x0010}) == false
    end
  end

  describe "Dataset struct" do
    test "creates empty dataset" do
      dataset = %Dataset{}
      assert dataset.elements == %{}
      assert dataset.meta == %{}
    end
  end
end

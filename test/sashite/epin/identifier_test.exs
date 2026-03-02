defmodule Sashite.Epin.IdentifierTest do
  use ExUnit.Case, async: true

  alias Sashite.Epin.Identifier
  alias Sashite.Pin.Identifier, as: PinIdentifier

  doctest Identifier

  # ===========================================================================
  # Construction
  # ===========================================================================

  describe "new/2" do
    test "creates identifier with PIN component" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin)

      assert epin.pin == pin
      assert epin.derived == false
    end

    test "creates identifier with derived: true" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: true)

      assert epin.derived == true
    end

    test "creates identifier with derived: false" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: false)

      assert epin.derived == false
    end

    test "creates identifier with enhanced PIN" do
      pin = Sashite.Pin.parse!("+R")
      epin = Identifier.new(pin)

      assert epin.pin.state == :enhanced
    end

    test "creates identifier with terminal PIN" do
      pin = Sashite.Pin.parse!("K^")
      epin = Identifier.new(pin)

      assert epin.pin.terminal == true
    end

    test "creates identifier with all PIN modifiers" do
      pin = Sashite.Pin.parse!("+K^")
      epin = Identifier.new(pin, derived: true)

      assert epin.pin.state == :enhanced
      assert epin.pin.terminal == true
      assert epin.derived == true
    end

    test "raises on nil PIN" do
      assert_raise ArgumentError, "invalid PIN component", fn ->
        Identifier.new(nil)
      end
    end

    test "raises on string PIN" do
      assert_raise ArgumentError, "invalid PIN component", fn ->
        Identifier.new("K")
      end
    end

    test "raises on invalid derived value" do
      pin = Sashite.Pin.parse!("K")

      assert_raise ArgumentError, "derived must be true or false", fn ->
        Identifier.new(pin, derived: "true")
      end
    end

    test "raises on nil derived value" do
      pin = Sashite.Pin.parse!("K")

      assert_raise ArgumentError, "derived must be true or false", fn ->
        Identifier.new(pin, derived: nil)
      end
    end
  end

  # ===========================================================================
  # Queries
  # ===========================================================================

  describe "derived?/1" do
    test "returns true for derived" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: true)

      assert Identifier.derived?(epin) == true
    end

    test "returns false for native" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: false)

      assert Identifier.derived?(epin) == false
    end
  end

  describe "native?/1" do
    test "returns true for native" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: false)

      assert Identifier.native?(epin) == true
    end

    test "returns false for derived" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: true)

      assert Identifier.native?(epin) == false
    end
  end

  describe "derived? and native? mutual exclusivity" do
    test "are mutually exclusive" do
      pin = Sashite.Pin.parse!("K")
      epin1 = Identifier.new(pin, derived: true)
      epin2 = Identifier.new(pin, derived: false)

      refute Identifier.derived?(epin1) == Identifier.native?(epin1)
      refute Identifier.derived?(epin2) == Identifier.native?(epin2)
    end
  end

  # ===========================================================================
  # String Conversion
  # ===========================================================================

  describe "to_string/1" do
    test "returns PIN string for native" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin)

      assert Identifier.to_string(epin) == "K"
    end

    test "returns PIN string with derivation marker for derived" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: true)

      assert Identifier.to_string(epin) == "K'"
    end

    test "with lowercase PIN" do
      pin = Sashite.Pin.parse!("k")
      epin = Identifier.new(pin, derived: true)

      assert Identifier.to_string(epin) == "k'"
    end

    test "with state modifier" do
      pin = Sashite.Pin.parse!("+R")
      epin = Identifier.new(pin, derived: true)

      assert Identifier.to_string(epin) == "+R'"
    end

    test "with terminal marker" do
      pin = Sashite.Pin.parse!("K^")
      epin = Identifier.new(pin, derived: true)

      assert Identifier.to_string(epin) == "K^'"
    end

    test "with all modifiers" do
      pin = Sashite.Pin.parse!("+K^")
      epin = Identifier.new(pin, derived: true)

      assert Identifier.to_string(epin) == "+K^'"
    end

    test "native with all PIN modifiers" do
      pin = Sashite.Pin.parse!("+K^")
      epin = Identifier.new(pin, derived: false)

      assert Identifier.to_string(epin) == "+K^"
    end
  end

  # ===========================================================================
  # String.Chars Protocol
  # ===========================================================================

  describe "String.Chars protocol" do
    test "allows string interpolation" do
      pin = Sashite.Pin.parse!("K^")
      epin = Identifier.new(pin, derived: true)

      assert "#{epin}" == "K^'"
    end

    test "works with Kernel.to_string/1" do
      pin = Sashite.Pin.parse!("+R")
      epin = Identifier.new(pin, derived: true)

      assert Kernel.to_string(epin) == "+R'"
    end
  end

  # ===========================================================================
  # Inspect Protocol
  # ===========================================================================

  describe "Inspect protocol" do
    test "simple native identifier" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin)

      assert inspect(epin) == "#Sashite.Epin.Identifier<K>"
    end

    test "simple derived identifier" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: true)

      assert inspect(epin) == "#Sashite.Epin.Identifier<K'>"
    end

    test "second player identifier" do
      pin = Sashite.Pin.parse!("k")
      epin = Identifier.new(pin, derived: true)

      assert inspect(epin) == "#Sashite.Epin.Identifier<k'>"
    end

    test "enhanced terminal derived" do
      pin = Sashite.Pin.parse!("+K^")
      epin = Identifier.new(pin, derived: true)

      assert inspect(epin) == "#Sashite.Epin.Identifier<+K^'>"
    end

    test "diminished native" do
      pin = Sashite.Pin.parse!("-R")
      epin = Identifier.new(pin)

      assert inspect(epin) == "#Sashite.Epin.Identifier<-R>"
    end

    test "terminal native" do
      pin = Sashite.Pin.parse!("K^")
      epin = Identifier.new(pin)

      assert inspect(epin) == "#Sashite.Epin.Identifier<K^>"
    end

    test "is consistent with to_string/1" do
      pin = Sashite.Pin.parse!("+K^")
      epin = Identifier.new(pin, derived: true)

      assert inspect(epin) == "#Sashite.Epin.Identifier<#{Identifier.to_string(epin)}>"
    end
  end

  # ===========================================================================
  # derive/1 Transformation
  # ===========================================================================

  describe "derive/1" do
    test "returns derived identifier" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin)

      result = Identifier.derive(epin)

      assert Identifier.derived?(result)
      assert Identifier.to_string(result) == "K'"
    end

    test "returns same struct if already derived" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: true)

      result = Identifier.derive(epin)

      assert result == epin
    end

    test "preserves PIN component" do
      pin = Sashite.Pin.parse!("+K^")
      epin = Identifier.new(pin)

      result = Identifier.derive(epin)

      assert result.pin == pin
    end
  end

  # ===========================================================================
  # native/1 Transformation
  # ===========================================================================

  describe "native/1" do
    test "returns native identifier" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: true)

      result = Identifier.native(epin)

      assert Identifier.native?(result)
      assert Identifier.to_string(result) == "K"
    end

    test "returns same struct if already native" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: false)

      result = Identifier.native(epin)

      assert result == epin
    end

    test "preserves PIN component" do
      pin = Sashite.Pin.parse!("+K^")
      epin = Identifier.new(pin, derived: true)

      result = Identifier.native(epin)

      assert result.pin == pin
    end
  end

  # ===========================================================================
  # with_pin/2 Transformation
  # ===========================================================================

  describe "with_pin/2" do
    test "replaces PIN component" do
      pin1 = Sashite.Pin.parse!("K")
      pin2 = Sashite.Pin.parse!("Q")
      epin = Identifier.new(pin1)

      result = Identifier.with_pin(epin, pin2)

      assert result.pin == pin2
      assert Identifier.to_string(result) == "Q"
    end

    test "preserves derived status" do
      pin1 = Sashite.Pin.parse!("K")
      pin2 = Sashite.Pin.parse!("Q")
      epin = Identifier.new(pin1, derived: true)

      result = Identifier.with_pin(epin, pin2)

      assert Identifier.derived?(result)
      assert Identifier.to_string(result) == "Q'"
    end

    test "returns same struct if same PIN" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin)

      result = Identifier.with_pin(epin, pin)

      assert result == epin
    end

    test "raises on invalid PIN" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin)

      assert_raise ArgumentError, "invalid PIN component", fn ->
        Identifier.with_pin(epin, "Q")
      end
    end
  end

  # ===========================================================================
  # Comparison Queries
  # ===========================================================================

  describe "same_derived?/2" do
    test "returns true for same derived status (both derived)" do
      pin1 = Sashite.Pin.parse!("K")
      pin2 = Sashite.Pin.parse!("Q")
      epin1 = Identifier.new(pin1, derived: true)
      epin2 = Identifier.new(pin2, derived: true)

      assert Identifier.same_derived?(epin1, epin2) == true
    end

    test "returns true for same derived status (both native)" do
      pin1 = Sashite.Pin.parse!("K")
      pin2 = Sashite.Pin.parse!("Q")
      epin1 = Identifier.new(pin1, derived: false)
      epin2 = Identifier.new(pin2, derived: false)

      assert Identifier.same_derived?(epin1, epin2) == true
    end

    test "returns false for different derived status" do
      pin1 = Sashite.Pin.parse!("K")
      pin2 = Sashite.Pin.parse!("K")
      epin1 = Identifier.new(pin1, derived: true)
      epin2 = Identifier.new(pin2, derived: false)

      assert Identifier.same_derived?(epin1, epin2) == false
    end
  end

  # ===========================================================================
  # Equality
  # ===========================================================================

  describe "equality" do
    test "equal identifiers are equal" do
      pin = Sashite.Pin.parse!("K")
      epin1 = Identifier.new(pin, derived: true)
      epin2 = Identifier.new(pin, derived: true)

      assert epin1 == epin2
    end

    test "different PIN means not equal" do
      pin1 = Sashite.Pin.parse!("K")
      pin2 = Sashite.Pin.parse!("Q")
      epin1 = Identifier.new(pin1, derived: true)
      epin2 = Identifier.new(pin2, derived: true)

      assert epin1 != epin2
    end

    test "different derived status means not equal" do
      pin = Sashite.Pin.parse!("K")
      epin1 = Identifier.new(pin, derived: true)
      epin2 = Identifier.new(pin, derived: false)

      assert epin1 != epin2
    end

    test "different PIN state means not equal" do
      pin1 = Sashite.Pin.parse!("K")
      pin2 = Sashite.Pin.parse!("+K")
      epin1 = Identifier.new(pin1)
      epin2 = Identifier.new(pin2)

      assert epin1 != epin2
    end

    test "different PIN terminal means not equal" do
      pin1 = Sashite.Pin.parse!("K")
      pin2 = Sashite.Pin.parse!("K^")
      epin1 = Identifier.new(pin1)
      epin2 = Identifier.new(pin2)

      assert epin1 != epin2
    end
  end

  # ===========================================================================
  # Struct Properties
  # ===========================================================================

  describe "struct properties" do
    test "is a struct" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin)

      assert is_struct(epin, Identifier)
    end

    test "has pin and derived fields" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin)

      assert Map.has_key?(epin, :pin)
      assert Map.has_key?(epin, :derived)
    end

    test "pin field is a PIN Identifier" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin)

      assert is_struct(epin.pin, PinIdentifier)
    end
  end

  # ===========================================================================
  # Pattern Matching
  # ===========================================================================

  describe "pattern matching" do
    test "can pattern match on struct" do
      pin = Sashite.Pin.parse!("K")
      epin = Identifier.new(pin, derived: true)

      assert %Identifier{pin: matched_pin, derived: matched_derived} = epin
      assert matched_pin == pin
      assert matched_derived == true
    end

    test "can pattern match on nested fields" do
      pin = Sashite.Pin.parse!("+K^")
      epin = Identifier.new(pin, derived: true)

      assert %Identifier{pin: %{abbr: :K, state: :enhanced}, derived: true} = epin
    end
  end
end

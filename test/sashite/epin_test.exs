defmodule Sashite.EpinTest do
  use ExUnit.Case, async: true

  alias Sashite.Epin
  alias Sashite.Pin

  doctest Sashite.Epin

  # ==========================================================================
  # Creation: new/2
  # ==========================================================================

  describe "new/2" do
    test "creates native EPIN from PIN by default" do
      pin = Pin.parse!("K")
      epin = Epin.new(pin)

      assert epin.pin == pin
      assert epin.derived == false
    end

    test "creates derived EPIN when derived: true" do
      pin = Pin.parse!("K")
      epin = Epin.new(pin, derived: true)

      assert epin.pin == pin
      assert epin.derived == true
    end

    test "creates native EPIN when derived: false" do
      pin = Pin.parse!("K")
      epin = Epin.new(pin, derived: false)

      assert epin.derived == false
    end

    test "coerces truthy values to true for derived" do
      pin = Pin.parse!("K")
      epin = Epin.new(pin, derived: "yes")

      assert epin.derived == true
    end

    test "coerces falsy values to false for derived" do
      pin = Pin.parse!("K")
      epin = Epin.new(pin, derived: nil)

      assert epin.derived == false
    end

    test "preserves all PIN attributes" do
      pin = Pin.new(:R, :second, :enhanced, terminal: true)
      epin = Epin.new(pin, derived: true)

      assert epin.pin.type == :R
      assert epin.pin.side == :second
      assert epin.pin.state == :enhanced
      assert epin.pin.terminal == true
      assert epin.derived == true
    end
  end

  # ==========================================================================
  # Parsing: parse/1
  # ==========================================================================

  describe "parse/1" do
    test "parses simple native piece" do
      assert {:ok, epin} = Epin.parse("K")

      assert epin.pin.type == :K
      assert epin.pin.side == :first
      assert epin.pin.state == :normal
      assert epin.pin.terminal == false
      assert epin.derived == false
    end

    test "parses simple derived piece" do
      assert {:ok, epin} = Epin.parse("K'")

      assert epin.pin.type == :K
      assert epin.pin.side == :first
      assert epin.derived == true
    end

    test "parses lowercase (second side) native piece" do
      assert {:ok, epin} = Epin.parse("k")

      assert epin.pin.type == :K
      assert epin.pin.side == :second
      assert epin.derived == false
    end

    test "parses lowercase (second side) derived piece" do
      assert {:ok, epin} = Epin.parse("k'")

      assert epin.pin.type == :K
      assert epin.pin.side == :second
      assert epin.derived == true
    end

    test "parses enhanced native piece" do
      assert {:ok, epin} = Epin.parse("+R")

      assert epin.pin.type == :R
      assert epin.pin.state == :enhanced
      assert epin.derived == false
    end

    test "parses enhanced derived piece" do
      assert {:ok, epin} = Epin.parse("+R'")

      assert epin.pin.type == :R
      assert epin.pin.state == :enhanced
      assert epin.derived == true
    end

    test "parses diminished native piece" do
      assert {:ok, epin} = Epin.parse("-p")

      assert epin.pin.type == :P
      assert epin.pin.side == :second
      assert epin.pin.state == :diminished
      assert epin.derived == false
    end

    test "parses diminished derived piece" do
      assert {:ok, epin} = Epin.parse("-p'")

      assert epin.pin.type == :P
      assert epin.pin.state == :diminished
      assert epin.derived == true
    end

    test "parses terminal native piece" do
      assert {:ok, epin} = Epin.parse("K^")

      assert epin.pin.type == :K
      assert epin.pin.terminal == true
      assert epin.derived == false
    end

    test "parses terminal derived piece" do
      assert {:ok, epin} = Epin.parse("K^'")

      assert epin.pin.type == :K
      assert epin.pin.terminal == true
      assert epin.derived == true
    end

    test "parses fully decorated native piece" do
      assert {:ok, epin} = Epin.parse("+K^")

      assert epin.pin.type == :K
      assert epin.pin.side == :first
      assert epin.pin.state == :enhanced
      assert epin.pin.terminal == true
      assert epin.derived == false
    end

    test "parses fully decorated derived piece" do
      assert {:ok, epin} = Epin.parse("+K^'")

      assert epin.pin.type == :K
      assert epin.pin.side == :first
      assert epin.pin.state == :enhanced
      assert epin.pin.terminal == true
      assert epin.derived == true
    end

    test "returns error for invalid string" do
      assert {:error, "Invalid EPIN string: invalid"} = Epin.parse("invalid")
    end

    test "returns error for empty string" do
      assert {:error, "Invalid EPIN string: "} = Epin.parse("")
    end

    test "returns error for wrong marker order (derivation before terminal)" do
      assert {:error, "Invalid EPIN string: K'^"} = Epin.parse("K'^")
    end

    test "returns error for multiple derivation markers" do
      assert {:error, "Invalid EPIN string: K''"} = Epin.parse("K''")
    end

    test "returns error for non-string input" do
      assert {:error, _} = Epin.parse(123)
      assert {:error, _} = Epin.parse(nil)
      assert {:error, _} = Epin.parse(:atom)
    end

    test "returns error for string with whitespace" do
      assert {:error, _} = Epin.parse(" K")
      assert {:error, _} = Epin.parse("K ")
      assert {:error, _} = Epin.parse("K '")
    end

    test "returns error for multiple letters" do
      assert {:error, _} = Epin.parse("KK")
      assert {:error, _} = Epin.parse("KK'")
    end
  end

  # ==========================================================================
  # Parsing: parse!/1
  # ==========================================================================

  describe "parse!/1" do
    test "returns EPIN struct for valid string" do
      epin = Epin.parse!("K^'")

      assert %Epin{} = epin
      assert epin.pin.type == :K
      assert epin.pin.terminal == true
      assert epin.derived == true
    end

    test "raises ArgumentError for invalid string" do
      assert_raise ArgumentError, "Invalid EPIN string: invalid", fn ->
        Epin.parse!("invalid")
      end
    end

    test "raises ArgumentError for wrong marker order" do
      assert_raise ArgumentError, "Invalid EPIN string: K'^", fn ->
        Epin.parse!("K'^")
      end
    end
  end

  # ==========================================================================
  # Validation: valid?/1
  # ==========================================================================

  describe "valid?/1" do
    test "returns true for simple letters" do
      for letter <- ~w(A B C K P Q R a b c k p q r) do
        assert Epin.valid?(letter), "Expected #{letter} to be valid"
      end
    end

    test "returns true for derived pieces" do
      assert Epin.valid?("K'")
      assert Epin.valid?("k'")
      assert Epin.valid?("R'")
    end

    test "returns true for enhanced pieces" do
      assert Epin.valid?("+K")
      assert Epin.valid?("+K'")
      assert Epin.valid?("+k'")
    end

    test "returns true for diminished pieces" do
      assert Epin.valid?("-K")
      assert Epin.valid?("-K'")
      assert Epin.valid?("-k'")
    end

    test "returns true for terminal pieces" do
      assert Epin.valid?("K^")
      assert Epin.valid?("K^'")
      assert Epin.valid?("k^'")
    end

    test "returns true for fully decorated pieces" do
      assert Epin.valid?("+K^")
      assert Epin.valid?("+K^'")
      assert Epin.valid?("-k^'")
    end

    test "returns false for wrong marker order" do
      refute Epin.valid?("K'^")
      refute Epin.valid?("+K'^")
    end

    test "returns false for multiple derivation markers" do
      refute Epin.valid?("K''")
      refute Epin.valid?("K'''")
    end

    test "returns false for invalid strings" do
      refute Epin.valid?("")
      refute Epin.valid?("invalid")
      refute Epin.valid?("KK")
      refute Epin.valid?("123")
      refute Epin.valid?(" K")
      refute Epin.valid?("K ")
    end

    test "returns false for non-string input" do
      refute Epin.valid?(123)
      refute Epin.valid?(nil)
      refute Epin.valid?(:atom)
      refute Epin.valid?([])
    end
  end

  # ==========================================================================
  # Conversion: to_string/1
  # ==========================================================================

  describe "to_string/1" do
    test "serializes native piece without derivation marker" do
      epin = Epin.parse!("K")
      assert Epin.to_string(epin) == "K"
    end

    test "serializes derived piece with derivation marker" do
      epin = Epin.parse!("K'")
      assert Epin.to_string(epin) == "K'"
    end

    test "serializes enhanced native piece" do
      epin = Epin.parse!("+R")
      assert Epin.to_string(epin) == "+R"
    end

    test "serializes enhanced derived piece" do
      epin = Epin.parse!("+R'")
      assert Epin.to_string(epin) == "+R'"
    end

    test "serializes diminished piece" do
      epin = Epin.parse!("-p'")
      assert Epin.to_string(epin) == "-p'"
    end

    test "serializes terminal piece" do
      epin = Epin.parse!("K^'")
      assert Epin.to_string(epin) == "K^'"
    end

    test "serializes fully decorated piece" do
      epin = Epin.parse!("+K^'")
      assert Epin.to_string(epin) == "+K^'"
    end

    test "round-trips all valid EPIN tokens" do
      tokens = ~w(K K' k k' +K +K' -k -k' K^ K^' +K^ +K^' -k^ -k^')

      for token <- tokens do
        assert {:ok, epin} = Epin.parse(token)
        assert Epin.to_string(epin) == token, "Round-trip failed for #{token}"
      end
    end
  end

  # ==========================================================================
  # Transformations: with_pin/2
  # ==========================================================================

  describe "with_pin/2" do
    test "replaces PIN component while preserving derivation" do
      epin = Epin.parse!("K^'")
      new_pin = Pin.parse!("Q")

      new_epin = Epin.with_pin(epin, new_pin)

      assert new_epin.pin.type == :Q
      assert new_epin.pin.terminal == false
      assert new_epin.derived == true
    end

    test "allows changing type via PIN" do
      epin = Epin.parse!("K'")
      new_pin = Pin.with_type(epin.pin, :Q)

      assert Epin.to_string(Epin.with_pin(epin, new_pin)) == "Q'"
    end

    test "allows changing state via PIN" do
      epin = Epin.parse!("K'")
      new_pin = Pin.with_state(epin.pin, :enhanced)

      assert Epin.to_string(Epin.with_pin(epin, new_pin)) == "+K'"
    end

    test "allows changing side via PIN flip" do
      epin = Epin.parse!("K'")
      new_pin = Pin.flip(epin.pin)

      assert Epin.to_string(Epin.with_pin(epin, new_pin)) == "k'"
    end

    test "allows changing terminal via PIN" do
      epin = Epin.parse!("K'")
      new_pin = Pin.with_terminal(epin.pin, true)

      assert Epin.to_string(Epin.with_pin(epin, new_pin)) == "K^'"
    end
  end

  # ==========================================================================
  # Transformations: with_derived/2
  # ==========================================================================

  describe "with_derived/2" do
    test "sets derivation to true" do
      epin = Epin.parse!("K")
      new_epin = Epin.with_derived(epin, true)

      assert new_epin.derived == true
      assert Epin.to_string(new_epin) == "K'"
    end

    test "sets derivation to false" do
      epin = Epin.parse!("K'")
      new_epin = Epin.with_derived(epin, false)

      assert new_epin.derived == false
      assert Epin.to_string(new_epin) == "K"
    end

    test "returns same struct when derivation unchanged (true)" do
      epin = Epin.parse!("K'")
      new_epin = Epin.with_derived(epin, true)

      assert epin == new_epin
    end

    test "returns same struct when derivation unchanged (false)" do
      epin = Epin.parse!("K")
      new_epin = Epin.with_derived(epin, false)

      assert epin == new_epin
    end

    test "preserves PIN component" do
      epin = Epin.parse!("+K^")
      new_epin = Epin.with_derived(epin, true)

      assert new_epin.pin == epin.pin
    end
  end

  # ==========================================================================
  # Transformations: mark_derived/1
  # ==========================================================================

  describe "mark_derived/1" do
    test "marks native piece as derived" do
      epin = Epin.parse!("K")
      derived = Epin.mark_derived(epin)

      assert derived.derived == true
      assert Epin.to_string(derived) == "K'"
    end

    test "returns same struct when already derived" do
      epin = Epin.parse!("K'")
      same = Epin.mark_derived(epin)

      assert epin == same
    end

    test "preserves all PIN attributes" do
      epin = Epin.parse!("+K^")
      derived = Epin.mark_derived(epin)

      assert derived.pin == epin.pin
      assert Epin.to_string(derived) == "+K^'"
    end
  end

  # ==========================================================================
  # Transformations: unmark_derived/1
  # ==========================================================================

  describe "unmark_derived/1" do
    test "marks derived piece as native" do
      epin = Epin.parse!("K'")
      native = Epin.unmark_derived(epin)

      assert native.derived == false
      assert Epin.to_string(native) == "K"
    end

    test "returns same struct when already native" do
      epin = Epin.parse!("K")
      same = Epin.unmark_derived(epin)

      assert epin == same
    end

    test "preserves all PIN attributes" do
      epin = Epin.parse!("+K^'")
      native = Epin.unmark_derived(epin)

      assert native.pin == epin.pin
      assert Epin.to_string(native) == "+K^"
    end
  end

  # ==========================================================================
  # Queries: derived?/1
  # ==========================================================================

  describe "derived?/1" do
    test "returns true for derived piece" do
      epin = Epin.parse!("K'")
      assert Epin.derived?(epin) == true
    end

    test "returns false for native piece" do
      epin = Epin.parse!("K")
      assert Epin.derived?(epin) == false
    end
  end

  # ==========================================================================
  # Queries: native?/1
  # ==========================================================================

  describe "native?/1" do
    test "returns true for native piece" do
      epin = Epin.parse!("K")
      assert Epin.native?(epin) == true
    end

    test "returns false for derived piece" do
      epin = Epin.parse!("K'")
      assert Epin.native?(epin) == false
    end
  end

  # ==========================================================================
  # Queries: same_derived?/2
  # ==========================================================================

  describe "same_derived?/2" do
    test "returns true when both are derived" do
      epin1 = Epin.parse!("K'")
      epin2 = Epin.parse!("Q^'")

      assert Epin.same_derived?(epin1, epin2) == true
    end

    test "returns true when both are native" do
      epin1 = Epin.parse!("K")
      epin2 = Epin.parse!("+R^")

      assert Epin.same_derived?(epin1, epin2) == true
    end

    test "returns false when one is derived and other is native" do
      epin1 = Epin.parse!("K'")
      epin2 = Epin.parse!("K")

      assert Epin.same_derived?(epin1, epin2) == false
    end
  end

  # ==========================================================================
  # Protocol: String.Chars
  # ==========================================================================

  describe "String.Chars protocol" do
    test "converts to string via Kernel.to_string/1" do
      epin = Epin.parse!("+K^'")
      assert Kernel.to_string(epin) == "+K^'"
    end

    test "works with string interpolation" do
      epin = Epin.parse!("K'")
      assert "Piece: #{epin}" == "Piece: K'"
    end
  end

  # ==========================================================================
  # Protocol: Inspect
  # ==========================================================================

  describe "Inspect protocol" do
    test "provides readable inspect output for native piece" do
      epin = Epin.parse!("K^")
      assert inspect(epin) == "#Sashite.Epin<K^>"
    end

    test "provides readable inspect output for derived piece" do
      epin = Epin.parse!("+K^'")
      assert inspect(epin) == "#Sashite.Epin<+K^'>"
    end
  end

  # ==========================================================================
  # Cross-style game scenarios
  # ==========================================================================

  describe "cross-style game scenarios" do
    test "first player with native and derived pieces" do
      # Chess vs Makruk: first player uses Chess style natively
      native_king = Epin.parse!("K^")
      derived_pawn = Epin.parse!("P'")

      assert Epin.native?(native_king)
      assert native_king.pin.side == :first

      assert Epin.derived?(derived_pawn)
      assert derived_pawn.pin.side == :first
    end

    test "second player with native and derived pieces" do
      # Chess vs Makruk: second player uses Makruk style natively
      native_king = Epin.parse!("k^")
      derived_pawn = Epin.parse!("p'")

      assert Epin.native?(native_king)
      assert native_king.pin.side == :second

      assert Epin.derived?(derived_pawn)
      assert derived_pawn.pin.side == :second
    end

    test "piece capture and conversion scenario" do
      # First player captures second player's piece and it becomes derived
      captured = Epin.parse!("p")  # Second player's native pawn

      # Convert to first player's piece (flip side) and mark as derived
      converted_pin = Pin.flip(captured.pin)
      converted = captured
                  |> Epin.with_pin(converted_pin)
                  |> Epin.mark_derived()

      assert converted.pin.side == :first
      assert Epin.derived?(converted)
      assert Epin.to_string(converted) == "P'"
    end
  end

  # ==========================================================================
  # Backward compatibility with PIN
  # ==========================================================================

  describe "backward compatibility with PIN" do
    test "all valid PIN tokens are valid EPIN tokens" do
      pin_tokens = ~w(K k +K -k K^ +K^ -k^)

      for token <- pin_tokens do
        assert Epin.valid?(token), "PIN token #{token} should be valid EPIN"
        assert {:ok, epin} = Epin.parse(token)
        assert Epin.native?(epin), "PIN token #{token} should parse as native"
        assert Epin.to_string(epin) == token, "PIN token #{token} should round-trip"
      end
    end
  end

  # ==========================================================================
  # Complex transformation chains
  # ==========================================================================

  describe "transformation chains" do
    test "multiple PIN transformations with derivation change" do
      epin = Epin.parse!("K")

      transformed =
        epin.pin
        |> Pin.with_type(:Q)
        |> Pin.with_state(:enhanced)
        |> Pin.with_terminal(true)
        |> then(&Epin.with_pin(epin, &1))
        |> Epin.mark_derived()

      assert Epin.to_string(transformed) == "+Q^'"
    end

    test "derivation toggle preserves PIN" do
      epin = Epin.parse!("+K^")

      toggled = epin
                |> Epin.mark_derived()
                |> Epin.unmark_derived()

      assert epin.pin == toggled.pin
      assert Epin.to_string(toggled) == "+K^"
    end
  end
end

defmodule Sashite.Epin.ParserTest do
  use ExUnit.Case, async: true

  alias Sashite.Epin.Identifier
  alias Sashite.Epin.Parser

  doctest Parser

  # ===========================================================================
  # Valid Inputs - Native (No Derivation Marker)
  # ===========================================================================

  describe "parse/1 with native EPIN (no derivation marker)" do
    test "parses simple PIN 'K'" do
      assert {:ok, result} = Parser.parse("K")
      assert result.pin.abbr == :K
      assert result.pin.side == :first
      assert result.pin.state == :normal
      assert result.pin.terminal == false
      assert result.derived == false
    end

    test "parses lowercase PIN 'k'" do
      assert {:ok, result} = Parser.parse("k")
      assert result.pin.abbr == :K
      assert result.pin.side == :second
      assert result.derived == false
    end

    test "parses enhanced PIN '+R'" do
      assert {:ok, result} = Parser.parse("+R")
      assert result.pin.abbr == :R
      assert result.pin.state == :enhanced
      assert result.derived == false
    end

    test "parses diminished PIN '-p'" do
      assert {:ok, result} = Parser.parse("-p")
      assert result.pin.abbr == :P
      assert result.pin.side == :second
      assert result.pin.state == :diminished
      assert result.derived == false
    end

    test "parses terminal PIN 'K^'" do
      assert {:ok, result} = Parser.parse("K^")
      assert result.pin.abbr == :K
      assert result.pin.terminal == true
      assert result.derived == false
    end

    test "parses PIN with all modifiers '+K^'" do
      assert {:ok, result} = Parser.parse("+K^")
      assert result.pin.abbr == :K
      assert result.pin.state == :enhanced
      assert result.pin.terminal == true
      assert result.derived == false
    end
  end

  # ===========================================================================
  # Valid Inputs - Derived (With Derivation Marker)
  # ===========================================================================

  describe "parse/1 with derived EPIN (with derivation marker)" do
    test "parses derived PIN \"K'\"" do
      assert {:ok, result} = Parser.parse("K'")
      assert result.pin.abbr == :K
      assert result.pin.side == :first
      assert result.derived == true
    end

    test "parses derived lowercase PIN \"k'\"" do
      assert {:ok, result} = Parser.parse("k'")
      assert result.pin.abbr == :K
      assert result.pin.side == :second
      assert result.derived == true
    end

    test "parses derived enhanced PIN \"+R'\"" do
      assert {:ok, result} = Parser.parse("+R'")
      assert result.pin.abbr == :R
      assert result.pin.state == :enhanced
      assert result.derived == true
    end

    test "parses derived terminal PIN \"K^'\"" do
      assert {:ok, result} = Parser.parse("K^'")
      assert result.pin.abbr == :K
      assert result.pin.terminal == true
      assert result.derived == true
    end

    test "parses derived PIN with all modifiers \"+K^'\"" do
      assert {:ok, result} = Parser.parse("+K^'")
      assert result.pin.abbr == :K
      assert result.pin.state == :enhanced
      assert result.pin.terminal == true
      assert result.derived == true
    end
  end

  # ===========================================================================
  # Valid Inputs - All Letters
  # ===========================================================================

  describe "parse/1 with all letters" do
    test "parses all uppercase letters A-Z" do
      for letter <- ?A..?Z do
        char = <<letter>>
        assert {:ok, result} = Parser.parse(char)
        assert result.pin.abbr == String.to_atom(char)
        assert result.pin.side == :first
      end
    end

    test "parses all lowercase letters a-z" do
      for letter <- ?a..?z do
        char = <<letter>>
        assert {:ok, result} = Parser.parse(char)
        assert result.pin.abbr == String.to_atom(String.upcase(char))
        assert result.pin.side == :second
      end
    end

    test "parses all uppercase letters with derivation marker" do
      for letter <- ?A..?Z do
        input = <<letter>> <> "'"
        assert {:ok, result} = Parser.parse(input)
        assert result.pin.abbr == String.to_atom(<<letter>>)
        assert result.derived == true
      end
    end
  end

  # ===========================================================================
  # valid?/1
  # ===========================================================================

  describe "valid?/1" do
    test "returns true for valid native EPIN" do
      assert Parser.valid?("K")
      assert Parser.valid?("+R")
      assert Parser.valid?("K^")
      assert Parser.valid?("+K^")
    end

    test "returns true for valid derived EPIN" do
      assert Parser.valid?("K'")
      assert Parser.valid?("+R'")
      assert Parser.valid?("K^'")
      assert Parser.valid?("+K^'")
    end

    test "returns false for empty string" do
      refute Parser.valid?("")
    end

    test "returns false for invalid derivation marker" do
      refute Parser.valid?("K''")
      refute Parser.valid?("K'^")
      refute Parser.valid?("'K")
    end

    test "returns false for invalid PIN" do
      refute Parser.valid?("invalid")
      refute Parser.valid?("1")
      refute Parser.valid?("++K")
    end

    test "returns false for nil" do
      refute Parser.valid?(nil)
    end

    test "returns false for non-string" do
      refute Parser.valid?(123)
      refute Parser.valid?(:K)
      refute Parser.valid?([:K])
    end
  end

  # ===========================================================================
  # Error Cases - Empty Input
  # ===========================================================================

  describe "parse/1 error cases - empty input" do
    test "returns error for empty string" do
      assert {:error, :empty_input} = Parser.parse("")
    end
  end

  # ===========================================================================
  # Error Cases - Invalid Derivation Marker
  # ===========================================================================

  describe "parse/1 error cases - invalid derivation marker" do
    test "returns error for multiple derivation markers" do
      assert {:error, :invalid_derivation_marker} = Parser.parse("K''")
    end

    test "returns error for derivation marker not at end" do
      assert {:error, :invalid_derivation_marker} = Parser.parse("K'^")
    end

    test "returns error for derivation marker at start" do
      assert {:error, :invalid_derivation_marker} = Parser.parse("'K")
    end

    test "returns error for derivation marker in middle" do
      assert {:error, :invalid_derivation_marker} = Parser.parse("K'K")
    end
  end

  # ===========================================================================
  # Error Cases - Invalid PIN Component
  # ===========================================================================

  describe "parse/1 error cases - invalid PIN component" do
    test "returns error for digit" do
      assert {:error, :invalid_pin} = Parser.parse("1")
    end

    test "returns error for multiple letters" do
      assert {:error, :invalid_pin} = Parser.parse("KQ")
    end

    test "returns error for invalid state modifier" do
      assert {:error, :invalid_pin} = Parser.parse("++K")
    end

    test "returns error for invalid input type" do
      assert {:error, :invalid_input} = Parser.parse(123)
      assert {:error, :invalid_input} = Parser.parse(:K)
      assert {:error, :invalid_input} = Parser.parse(nil)
    end
  end

  # ===========================================================================
  # Security Tests - Null Byte Injection
  # ===========================================================================

  describe "security - null byte injection" do
    test "rejects null byte alone" do
      refute Parser.valid?(<<0>>)
    end

    test "rejects null byte in PIN" do
      refute Parser.valid?("K" <> <<0>>)
      refute Parser.valid?(<<0>> <> "K")
    end

    test "rejects null byte before derivation marker" do
      refute Parser.valid?("K" <> <<0>> <> "'")
    end
  end

  # ===========================================================================
  # Security Tests - Control Characters
  # ===========================================================================

  describe "security - control characters" do
    test "rejects newline" do
      refute Parser.valid?("K\n")
      refute Parser.valid?("K'\n")
    end

    test "rejects carriage return" do
      refute Parser.valid?("K\r")
      refute Parser.valid?("\rK")
    end

    test "rejects tab" do
      refute Parser.valid?("K\t")
      refute Parser.valid?("\tK")
    end

    test "rejects other control characters" do
      # SOH
      refute Parser.valid?(<<1>> <> "K")
      # ESC
      refute Parser.valid?("K" <> <<27>>)
      # DEL
      refute Parser.valid?("K" <> <<127>>)
    end
  end

  # ===========================================================================
  # Security Tests - Unicode Lookalikes
  # ===========================================================================

  describe "security - Unicode lookalikes" do
    test "rejects Cyrillic lookalikes" do
      # Cyrillic 'К' (U+041A) looks like Latin 'K'
      refute Parser.valid?("К")
      # Cyrillic 'а' (U+0430) looks like Latin 'a'
      refute Parser.valid?("а")
    end

    test "rejects Greek lookalikes" do
      # Greek 'Α' (U+0391) looks like Latin 'A'
      refute Parser.valid?("Α")
    end

    test "rejects full-width characters" do
      # Full-width 'K' (U+FF2B)
      refute Parser.valid?("Ｋ")
    end
  end

  # ===========================================================================
  # Security Tests - Combining Characters
  # ===========================================================================

  describe "security - combining characters" do
    test "rejects combining acute accent" do
      # 'K' + combining acute accent (U+0301)
      refute Parser.valid?("K" <> <<204, 129>>)
    end

    test "rejects combining diaeresis" do
      # 'K' + combining diaeresis (U+0308)
      refute Parser.valid?("K" <> <<204, 136>>)
    end
  end

  # ===========================================================================
  # Security Tests - Zero-Width Characters
  # ===========================================================================

  describe "security - zero-width characters" do
    test "rejects zero-width space" do
      # Zero-width space (U+200B)
      refute Parser.valid?("\u200B")
      refute Parser.valid?("K\u200B")
    end

    test "rejects zero-width non-joiner" do
      # Zero-width non-joiner (U+200C)
      refute Parser.valid?("\u200C")
    end

    test "rejects BOM" do
      # Byte order mark (U+FEFF)
      refute Parser.valid?("\uFEFF")
      refute Parser.valid?("\uFEFFK")
    end
  end

  # ===========================================================================
  # Round-Trip Tests
  # ===========================================================================

  describe "round-trip tests" do
    test "round-trip native EPIN" do
      inputs = ~w[K k +R -p K^ +K^ -k^]

      for input <- inputs do
        assert {:ok, components} = Parser.parse(input)

        pin =
          Sashite.Pin.Identifier.new(
            components.pin.abbr,
            components.pin.side,
            components.pin.state,
            terminal: components.pin.terminal
          )

        epin = Identifier.new(pin, derived: components.derived)
        assert Identifier.to_string(epin) == input
      end
    end

    test "round-trip derived EPIN" do
      inputs = ["K'", "k'", "+R'", "-p'", "K^'", "+K^'", "-k^'"]

      for input <- inputs do
        assert {:ok, components} = Parser.parse(input)

        pin =
          Sashite.Pin.Identifier.new(
            components.pin.abbr,
            components.pin.side,
            components.pin.state,
            terminal: components.pin.terminal
          )

        epin = Identifier.new(pin, derived: components.derived)
        assert Identifier.to_string(epin) == input
      end
    end
  end

  # ===========================================================================
  # PIN Compatibility
  # ===========================================================================

  describe "PIN compatibility" do
    test "every valid PIN is a valid EPIN" do
      pin_inputs = ~w[K +R -p K^ +R^ -p^]

      for input <- pin_inputs do
        assert Parser.valid?(input)
        assert {:ok, result} = Parser.parse(input)
        assert result.derived == false
      end
    end
  end
end

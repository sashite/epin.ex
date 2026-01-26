defmodule SashiteEpinTest do
  use ExUnit.Case, async: true

  alias Sashite.Epin.Identifier

  doctest SashiteEpin

  # ===========================================================================
  # Delegation Tests
  # ===========================================================================

  describe "parse/1 delegation" do
    test "delegates to Sashite.Epin.parse/1" do
      assert {:ok, epin} = SashiteEpin.parse("K^'")
      assert epin.pin.abbr == :K
      assert epin.pin.terminal == true
      assert Identifier.derived?(epin)
    end

    test "returns error tuple for invalid input" do
      assert {:error, :empty_input} = SashiteEpin.parse("")
      assert {:error, :invalid_derivation_marker} = SashiteEpin.parse("K''")
      assert {:error, :invalid_pin} = SashiteEpin.parse("invalid")
    end
  end

  describe "parse!/1 delegation" do
    test "delegates to Sashite.Epin.parse!/1" do
      epin = SashiteEpin.parse!("K^'")
      assert epin.pin.abbr == :K
      assert epin.pin.terminal == true
      assert Identifier.derived?(epin)
    end

    test "raises ArgumentError for invalid input" do
      assert_raise ArgumentError, fn ->
        SashiteEpin.parse!("")
      end

      assert_raise ArgumentError, fn ->
        SashiteEpin.parse!("K''")
      end
    end
  end

  describe "valid?/1 delegation" do
    test "delegates to Sashite.Epin.valid?/1" do
      assert SashiteEpin.valid?("K")
      assert SashiteEpin.valid?("K^'")
      assert SashiteEpin.valid?("+R^'")
      refute SashiteEpin.valid?("")
      refute SashiteEpin.valid?("invalid")
      refute SashiteEpin.valid?("K''")
    end
  end

  # ===========================================================================
  # Consistency Tests
  # ===========================================================================

  describe "consistency with Sashite.Epin" do
    test "parse/1 returns same result as Sashite.Epin.parse/1" do
      inputs = ["K", "K^'", "+R'", "", "invalid", "K''"]

      for input <- inputs do
        assert SashiteEpin.parse(input) == Sashite.Epin.parse(input)
      end
    end

    test "valid?/1 returns same result as Sashite.Epin.valid?/1" do
      inputs = ["K", "K^'", "+R'", "", "invalid", "K''", nil, 123]

      for input <- inputs do
        assert SashiteEpin.valid?(input) == Sashite.Epin.valid?(input)
      end
    end
  end
end

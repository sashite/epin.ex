defmodule Sashite.Epin.ConstantsTest do
  use ExUnit.Case, async: true

  alias Sashite.Epin.Constants

  doctest Constants

  describe "derivation_suffix/0" do
    test "returns apostrophe" do
      assert Constants.derivation_suffix() == "'"
    end

    test "returns a string" do
      assert is_binary(Constants.derivation_suffix())
    end

    test "returns a single character" do
      assert String.length(Constants.derivation_suffix()) == 1
    end
  end
end

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

  describe "max_string_length/0" do
    test "returns 4" do
      assert Constants.max_string_length() == 4
    end

    test "returns a positive integer" do
      assert is_integer(Constants.max_string_length())
      assert Constants.max_string_length() > 0
    end

    test "equals the byte size of the longest valid EPIN token" do
      # Longest valid token: [+-][A-Za-z]\^' — e.g. "+K^'"
      assert Constants.max_string_length() == byte_size("+K^'")
    end
  end
end

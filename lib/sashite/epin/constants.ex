defmodule Sashite.Epin.Constants do
  @moduledoc """
  Constants for EPIN (Extended Piece Identifier Notation).

  EPIN extends PIN with a single derivation marker.
  PIN constants (valid_abbrs, valid_sides, valid_states, etc.)
  are accessed through the sashite_pin dependency.

  ## Examples

      iex> Sashite.Epin.Constants.derivation_suffix()
      "'"

      iex> Sashite.Epin.Constants.max_string_length()
      4

  @see https://sashite.dev/specs/epin/1.0.0/
  """

  @derivation_suffix "'"
  @max_string_length 4

  @doc """
  Returns the derivation marker suffix.

  ## Example

      iex> Sashite.Epin.Constants.derivation_suffix()
      "'"
  """
  @spec derivation_suffix() :: String.t()
  def derivation_suffix, do: @derivation_suffix

  @doc """
  Returns the maximum byte length of a valid EPIN token.

  The longest valid token is `[+-][A-Za-z]\\^'` — 4 bytes.

  ## Example

      iex> Sashite.Epin.Constants.max_string_length()
      4
  """
  @spec max_string_length() :: pos_integer()
  def max_string_length, do: @max_string_length
end

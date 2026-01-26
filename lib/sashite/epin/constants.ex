defmodule Sashite.Epin.Constants do
  @moduledoc """
  Constants for EPIN (Extended Piece Identifier Notation).

  EPIN extends PIN with a single derivation marker.
  PIN constants (valid_abbrs, valid_sides, valid_states, etc.)
  are accessed through the sashite_pin dependency.

  ## Example

      iex> Sashite.Epin.Constants.derivation_suffix()
      "'"

  @see https://sashite.dev/specs/epin/1.0.0/
  """

  @derivation_suffix "'"

  @doc """
  Returns the derivation marker suffix.

  ## Example

      iex> Sashite.Epin.Constants.derivation_suffix()
      "'"
  """
  @spec derivation_suffix() :: String.t()
  def derivation_suffix, do: @derivation_suffix
end

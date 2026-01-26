defmodule SashiteEpin do
  @moduledoc """
  Convenience module that delegates to `Sashite.Epin`.

  This module provides a shorter entry point for the EPIN library.

  ## Examples

      iex> {:ok, epin} = SashiteEpin.parse("K^'")
      iex> Sashite.Epin.Identifier.to_string(epin)
      "K^'"

      iex> SashiteEpin.valid?("K")
      true

  @see `Sashite.Epin` for full documentation.
  """

  @doc """
  Parses an EPIN string into an Identifier.

  Delegates to `Sashite.Epin.parse/1`.
  """
  defdelegate parse(string), to: Sashite.Epin

  @doc """
  Parses an EPIN string into an Identifier, raising on error.

  Delegates to `Sashite.Epin.parse!/1`.
  """
  defdelegate parse!(string), to: Sashite.Epin

  @doc """
  Reports whether a string is a valid EPIN notation.

  Delegates to `Sashite.Epin.valid?/1`.
  """
  defdelegate valid?(string), to: Sashite.Epin
end

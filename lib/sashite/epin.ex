defmodule Sashite.Epin do
  @moduledoc """
  EPIN (Extended Piece Identifier Notation) implementation for Elixir.

  EPIN extends PIN with an optional derivation marker (`'`) that flags
  whether a piece uses a native or derived style.

  ## Format

      <pin>[']

  - **PIN**: Any valid PIN token (abbr, side, state, terminal)
  - **Derivation marker**: `'` (derived) or absent (native)

  ## Examples

      iex> {:ok, epin} = Sashite.Epin.parse("K^'")
      iex> epin.pin.abbr
      :K
      iex> epin.pin.terminal
      true
      iex> Sashite.Epin.Identifier.derived?(epin)
      true

      iex> {:ok, epin} = Sashite.Epin.parse("+R")
      iex> Sashite.Epin.Identifier.to_string(epin)
      "+R"

      iex> Sashite.Epin.valid?("K^'")
      true

      iex> Sashite.Epin.valid?("invalid")
      false

  @see https://sashite.dev/specs/epin/1.0.0/
  """

  alias Sashite.Epin.Identifier
  alias Sashite.Epin.Parser

  @doc """
  Parses an EPIN string into an Identifier.

  ## Parameters

  - `string` - The EPIN string to parse

  ## Returns

  - `{:ok, identifier}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> {:ok, epin} = Sashite.Epin.parse("K")
      iex> epin.pin.abbr
      :K
      iex> Sashite.Epin.Identifier.native?(epin)
      true

      iex> {:ok, epin} = Sashite.Epin.parse("K^'")
      iex> epin.pin.terminal
      true
      iex> Sashite.Epin.Identifier.derived?(epin)
      true

      iex> Sashite.Epin.parse("invalid")
      {:error, :invalid_pin}

      iex> Sashite.Epin.parse("")
      {:error, :empty_input}
  """
  @spec parse(String.t()) :: {:ok, Identifier.t()} | {:error, atom()}
  def parse(string) do
    case Parser.parse(string) do
      {:ok, components} ->
        pin =
          Sashite.Pin.Identifier.new(
            components.pin.abbr,
            components.pin.side,
            components.pin.state,
            terminal: components.pin.terminal
          )

        identifier = Identifier.new(pin, derived: components.derived)
        {:ok, identifier}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parses an EPIN string into an Identifier, raising on error.

  ## Parameters

  - `string` - The EPIN string to parse

  ## Returns

  - An `Identifier` struct on success

  ## Raises

  - `ArgumentError` if the string is not a valid EPIN

  ## Examples

      iex> epin = Sashite.Epin.parse!("K^'")
      iex> Sashite.Epin.Identifier.to_string(epin)
      "K^'"

      iex> epin = Sashite.Epin.parse!("+R")
      iex> epin.pin.state
      :enhanced
  """
  @spec parse!(String.t()) :: Identifier.t()
  def parse!(string) do
    case parse(string) do
      {:ok, identifier} ->
        identifier

      {:error, reason} ->
        raise ArgumentError, "invalid EPIN: #{reason}"
    end
  end

  @doc """
  Reports whether a string is a valid EPIN notation.

  ## Parameters

  - `string` - The string to validate

  ## Returns

  - `true` if valid
  - `false` otherwise

  ## Examples

      iex> Sashite.Epin.valid?("K")
      true

      iex> Sashite.Epin.valid?("K^'")
      true

      iex> Sashite.Epin.valid?("+R^'")
      true

      iex> Sashite.Epin.valid?("invalid")
      false

      iex> Sashite.Epin.valid?("K''")
      false

      iex> Sashite.Epin.valid?(nil)
      false
  """
  @spec valid?(term()) :: boolean()
  def valid?(string) do
    Parser.valid?(string)
  end
end

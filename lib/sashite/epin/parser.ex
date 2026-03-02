defmodule Sashite.Epin.Parser do
  @moduledoc """
  Parser for EPIN (Extended Piece Identifier Notation) strings.

  Bounded-input, allocation-free parsing:
  - Rejects inputs exceeding the maximum EPIN token length (4 bytes) immediately.
  - Detects the derivation marker with a single byte test on the last position.
  - Delegates PIN parsing to the sashite_pin library.

  ## Examples

      iex> Sashite.Epin.Parser.parse("K")
      {:ok, %{pin: %{abbr: :K, side: :first, state: :normal, terminal: false}, derived: false}}

      iex> Sashite.Epin.Parser.parse("K^'")
      {:ok, %{pin: %{abbr: :K, side: :first, state: :normal, terminal: true}, derived: true}}

      iex> Sashite.Epin.Parser.parse("K''")
      {:error, :invalid_derivation_marker}

      iex> Sashite.Epin.Parser.parse(nil)
      {:error, :not_a_string}

  @see https://sashite.dev/specs/epin/1.0.0/
  """

  alias Sashite.Epin.Constants
  alias Sashite.Pin.Parser, as: PinParser

  # Byte value of the derivation marker (apostrophe, 0x27).
  @apostrophe ?'

  @doc """
  Parses an EPIN string into its components.

  ## Parameters

  - `input` - The EPIN string to parse

  ## Returns

  - `{:ok, map}` with `:pin` (PIN components map) and `:derived` keys
  - `{:error, reason}` if the input is not a valid EPIN string

  ## Error reasons

  - `:not_a_string` — input is not a binary
  - `:empty_input` — input is an empty string
  - `:invalid_derivation_marker` — apostrophe misplaced or duplicated
  - `:invalid_pin` — PIN component is invalid (or input exceeds max length)

  ## Examples

      iex> Sashite.Epin.Parser.parse("K")
      {:ok, %{pin: %{abbr: :K, side: :first, state: :normal, terminal: false}, derived: false}}

      iex> Sashite.Epin.Parser.parse("+R'")
      {:ok, %{pin: %{abbr: :R, side: :first, state: :enhanced, terminal: false}, derived: true}}

      iex> Sashite.Epin.Parser.parse("")
      {:error, :empty_input}

      iex> Sashite.Epin.Parser.parse("K''")
      {:error, :invalid_derivation_marker}

      iex> Sashite.Epin.Parser.parse("K'^")
      {:error, :invalid_derivation_marker}

      iex> Sashite.Epin.Parser.parse(nil)
      {:error, :not_a_string}
  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, atom()}
  def parse(input) when is_binary(input) do
    len = byte_size(input)

    cond do
      len == 0 ->
        {:error, :empty_input}

      len > Constants.max_string_length() ->
        {:error, :invalid_pin}

      :binary.at(input, len - 1) == @apostrophe ->
        parse_derived(input, len)

      true ->
        parse_native(input)
    end
  end

  def parse(_input), do: {:error, :not_a_string}

  @doc """
  Reports whether the input is a valid EPIN string.

  ## Parameters

  - `input` - The string to validate

  ## Returns

  - `true` if valid
  - `false` otherwise

  ## Examples

      iex> Sashite.Epin.Parser.valid?("K")
      true

      iex> Sashite.Epin.Parser.valid?("K^'")
      true

      iex> Sashite.Epin.Parser.valid?("K''")
      false

      iex> Sashite.Epin.Parser.valid?(nil)
      false
  """
  @spec valid?(term()) :: boolean()
  def valid?(input) when is_binary(input) do
    case parse(input) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  def valid?(_input), do: false

  # ===========================================================================
  # Private Functions
  # ===========================================================================

  # Input ends with apostrophe: strip it, check for duplicates, parse PIN.
  defp parse_derived(input, len) do
    pin_string = binary_part(input, 0, len - 1)

    if has_apostrophe?(pin_string) do
      {:error, :invalid_derivation_marker}
    else
      parse_pin(pin_string, true)
    end
  end

  # Input does not end with apostrophe: check for misplaced ones, parse PIN.
  defp parse_native(input) do
    if has_apostrophe?(input) do
      {:error, :invalid_derivation_marker}
    else
      parse_pin(input, false)
    end
  end

  # Delegates to PIN parser and wraps the result.
  defp parse_pin(pin_string, derived) do
    case PinParser.parse(pin_string) do
      {:ok, pin_components} -> {:ok, %{pin: pin_components, derived: derived}}
      {:error, _reason} -> {:error, :invalid_pin}
    end
  end

  # O(1) apostrophe check. Input is bounded to at most 3 bytes at call site.
  defp has_apostrophe?(bin) do
    :binary.match(bin, <<@apostrophe>>) != :nomatch
  end
end

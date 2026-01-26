defmodule Sashite.Epin.Parser do
  @moduledoc """
  Parser for EPIN (Extended Piece Identifier Notation) strings.

  This parser extracts the derivation marker and delegates PIN parsing
  to the sashite_pin library.

  ## Examples

      iex> Sashite.Epin.Parser.parse("K")
      {:ok, %{pin: %{abbr: :K, side: :first, state: :normal, terminal: false}, derived: false}}

      iex> Sashite.Epin.Parser.parse("K^'")
      {:ok, %{pin: %{abbr: :K, side: :first, state: :normal, terminal: true}, derived: true}}

      iex> Sashite.Epin.Parser.parse("K''")
      {:error, :invalid_derivation_marker}

  @see https://sashite.dev/specs/epin/1.0.0/
  """

  alias Sashite.Epin.Constants
  alias Sashite.Pin.Parser, as: PinParser

  @doc """
  Parses an EPIN string into its components.

  ## Parameters

  - `input` - The EPIN string to parse

  ## Returns

  - `{:ok, map}` with `:pin` (PIN components map) and `:derived` keys
  - `{:error, reason}` if the input is not a valid EPIN string

  ## Examples

      iex> Sashite.Epin.Parser.parse("K")
      {:ok, %{pin: %{abbr: :K, side: :first, state: :normal, terminal: false}, derived: false}}

      iex> Sashite.Epin.Parser.parse("+R'")
      {:ok, %{pin: %{abbr: :R, side: :first, state: :enhanced, terminal: false}, derived: true}}

      iex> Sashite.Epin.Parser.parse("")
      {:error, :empty_input}

      iex> Sashite.Epin.Parser.parse("K''")
      {:error, :invalid_derivation_marker}
  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, atom()}
  def parse(input) when is_binary(input) do
    with :ok <- validate_not_empty(input),
         {:ok, derived, pin_string} <- extract_derivation(input),
         {:ok, pin_components} <- parse_pin_component(pin_string) do
      {:ok, %{pin: pin_components, derived: derived}}
    end
  end

  def parse(_input), do: {:error, :invalid_input}

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

  defp validate_not_empty(""), do: {:error, :empty_input}
  defp validate_not_empty(_input), do: :ok

  defp extract_derivation(input) do
    suffix = Constants.derivation_suffix()

    cond do
      not String.contains?(input, suffix) ->
        {:ok, false, input}

      String.ends_with?(input, suffix) and count_occurrences(input, suffix) == 1 ->
        pin_string = String.slice(input, 0..-2//1)
        {:ok, true, pin_string}

      true ->
        {:error, :invalid_derivation_marker}
    end
  end

  defp count_occurrences(string, substring) do
    string
    |> String.graphemes()
    |> Enum.count(&(&1 == substring))
  end

  defp parse_pin_component(pin_string) do
    case PinParser.parse(pin_string) do
      {:ok, pin_components} ->
        {:ok, pin_components}

      {:error, _reason} ->
        {:error, :invalid_pin}
    end
  end
end

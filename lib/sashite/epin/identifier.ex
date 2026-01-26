defmodule Sashite.Epin.Identifier do
  @moduledoc """
  Represents a parsed EPIN (Extended Piece Identifier Notation) identifier.

  An Identifier combines a PIN component with a derivation status:
  - PIN: encodes abbr, side, state, and terminal status
  - Derived: indicates whether the piece uses native or derived style

  ## Examples

      iex> pin = Sashite.Pin.parse!("K^")
      iex> epin = Sashite.Epin.Identifier.new(pin)
      iex> Sashite.Epin.Identifier.to_string(epin)
      "K^"

      iex> pin = Sashite.Pin.parse!("K^")
      iex> epin = Sashite.Epin.Identifier.new(pin, derived: true)
      iex> Sashite.Epin.Identifier.to_string(epin)
      "K^'"

  @see https://sashite.dev/specs/epin/1.0.0/
  """

  alias Sashite.Epin.Constants
  alias Sashite.Pin.Identifier, as: PinIdentifier

  @enforce_keys [:pin, :derived]
  defstruct [:pin, :derived]

  @type t :: %__MODULE__{
          pin: PinIdentifier.t(),
          derived: boolean()
        }

  # ===========================================================================
  # Construction
  # ===========================================================================

  @doc """
  Creates a new Identifier from a PIN component.

  ## Parameters

  - `pin` - A `Sashite.Pin.Identifier` struct
  - `opts` - Keyword list with optional `:derived` key (default: `false`)

  ## Examples

      iex> pin = Sashite.Pin.parse!("K")
      iex> epin = Sashite.Epin.Identifier.new(pin)
      iex> epin.derived
      false

      iex> pin = Sashite.Pin.parse!("K")
      iex> epin = Sashite.Epin.Identifier.new(pin, derived: true)
      iex> epin.derived
      true

  ## Raises

  - `ArgumentError` if `pin` is not a valid `Sashite.Pin.Identifier`
  - `ArgumentError` if `derived` is not a boolean
  """
  @spec new(PinIdentifier.t(), keyword()) :: t()
  def new(pin, opts \\ [])

  def new(%PinIdentifier{} = pin, opts) do
    derived = Keyword.get(opts, :derived, false)
    validate_derived!(derived)

    %__MODULE__{
      pin: pin,
      derived: derived
    }
  end

  def new(_pin, _opts) do
    raise ArgumentError, "invalid PIN component"
  end

  # ===========================================================================
  # Queries
  # ===========================================================================

  @doc """
  Returns `true` if the identifier has derived style status.

  ## Examples

      iex> pin = Sashite.Pin.parse!("K")
      iex> epin = Sashite.Epin.Identifier.new(pin, derived: true)
      iex> Sashite.Epin.Identifier.derived?(epin)
      true

      iex> pin = Sashite.Pin.parse!("K")
      iex> epin = Sashite.Epin.Identifier.new(pin)
      iex> Sashite.Epin.Identifier.derived?(epin)
      false
  """
  @spec derived?(t()) :: boolean()
  def derived?(%__MODULE__{derived: derived}), do: derived

  @doc """
  Returns `true` if the identifier has native style status.

  ## Examples

      iex> pin = Sashite.Pin.parse!("K")
      iex> epin = Sashite.Epin.Identifier.new(pin)
      iex> Sashite.Epin.Identifier.native?(epin)
      true

      iex> pin = Sashite.Pin.parse!("K")
      iex> epin = Sashite.Epin.Identifier.new(pin, derived: true)
      iex> Sashite.Epin.Identifier.native?(epin)
      false
  """
  @spec native?(t()) :: boolean()
  def native?(%__MODULE__{derived: derived}), do: not derived

  # ===========================================================================
  # String Conversion
  # ===========================================================================

  @doc """
  Returns the EPIN string representation.

  ## Examples

      iex> pin = Sashite.Pin.parse!("K")
      iex> epin = Sashite.Epin.Identifier.new(pin)
      iex> Sashite.Epin.Identifier.to_string(epin)
      "K"

      iex> pin = Sashite.Pin.parse!("K")
      iex> epin = Sashite.Epin.Identifier.new(pin, derived: true)
      iex> Sashite.Epin.Identifier.to_string(epin)
      "K'"

      iex> pin = Sashite.Pin.parse!("+K^")
      iex> epin = Sashite.Epin.Identifier.new(pin, derived: true)
      iex> Sashite.Epin.Identifier.to_string(epin)
      "+K^'"
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{pin: pin, derived: true}) do
    PinIdentifier.to_string(pin) <> Constants.derivation_suffix()
  end

  def to_string(%__MODULE__{pin: pin, derived: false}) do
    PinIdentifier.to_string(pin)
  end

  # ===========================================================================
  # Transformations
  # ===========================================================================

  @doc """
  Returns a new Identifier with a different PIN component.

  ## Examples

      iex> pin1 = Sashite.Pin.parse!("K")
      iex> pin2 = Sashite.Pin.parse!("+Q^")
      iex> epin = Sashite.Epin.Identifier.new(pin1, derived: true)
      iex> result = Sashite.Epin.Identifier.with_pin(epin, pin2)
      iex> Sashite.Epin.Identifier.to_string(result)
      "+Q^'"
  """
  @spec with_pin(t(), PinIdentifier.t()) :: t()
  def with_pin(%__MODULE__{pin: pin} = identifier, new_pin) when pin == new_pin do
    identifier
  end

  def with_pin(%__MODULE__{derived: derived}, %PinIdentifier{} = new_pin) do
    new(new_pin, derived: derived)
  end

  def with_pin(%__MODULE__{}, _new_pin) do
    raise ArgumentError, "invalid PIN component"
  end

  @doc """
  Returns a new Identifier marked as derived.

  Returns the same struct if already derived.

  ## Examples

      iex> pin = Sashite.Pin.parse!("K^")
      iex> epin = Sashite.Epin.Identifier.new(pin)
      iex> result = Sashite.Epin.Identifier.derive(epin)
      iex> Sashite.Epin.Identifier.to_string(result)
      "K^'"

      iex> pin = Sashite.Pin.parse!("K")
      iex> epin = Sashite.Epin.Identifier.new(pin, derived: true)
      iex> result = Sashite.Epin.Identifier.derive(epin)
      iex> result == epin
      true
  """
  @spec derive(t()) :: t()
  def derive(%__MODULE__{derived: true} = identifier), do: identifier

  def derive(%__MODULE__{pin: pin}) do
    new(pin, derived: true)
  end

  @doc """
  Returns a new Identifier marked as native.

  Returns the same struct if already native.

  ## Examples

      iex> pin = Sashite.Pin.parse!("K^")
      iex> epin = Sashite.Epin.Identifier.new(pin, derived: true)
      iex> result = Sashite.Epin.Identifier.native(epin)
      iex> Sashite.Epin.Identifier.to_string(result)
      "K^"

      iex> pin = Sashite.Pin.parse!("K")
      iex> epin = Sashite.Epin.Identifier.new(pin)
      iex> result = Sashite.Epin.Identifier.native(epin)
      iex> result == epin
      true
  """
  @spec native(t()) :: t()
  def native(%__MODULE__{derived: false} = identifier), do: identifier

  def native(%__MODULE__{pin: pin}) do
    new(pin, derived: false)
  end

  # ===========================================================================
  # Comparison Queries
  # ===========================================================================

  @doc """
  Checks if two Identifiers have the same derived status.

  ## Examples

      iex> pin1 = Sashite.Pin.parse!("K")
      iex> pin2 = Sashite.Pin.parse!("Q")
      iex> epin1 = Sashite.Epin.Identifier.new(pin1, derived: true)
      iex> epin2 = Sashite.Epin.Identifier.new(pin2, derived: true)
      iex> Sashite.Epin.Identifier.same_derived?(epin1, epin2)
      true

      iex> pin1 = Sashite.Pin.parse!("K")
      iex> pin2 = Sashite.Pin.parse!("K")
      iex> epin1 = Sashite.Epin.Identifier.new(pin1, derived: true)
      iex> epin2 = Sashite.Epin.Identifier.new(pin2, derived: false)
      iex> Sashite.Epin.Identifier.same_derived?(epin1, epin2)
      false
  """
  @spec same_derived?(t(), t()) :: boolean()
  def same_derived?(%__MODULE__{derived: d1}, %__MODULE__{derived: d2}) do
    d1 == d2
  end

  # ===========================================================================
  # Private Functions
  # ===========================================================================

  defp validate_derived!(derived) when is_boolean(derived), do: :ok

  defp validate_derived!(_derived) do
    raise ArgumentError, "derived must be true or false"
  end
end

# Implement String.Chars protocol for string interpolation
defimpl String.Chars, for: Sashite.Epin.Identifier do
  def to_string(identifier) do
    Sashite.Epin.Identifier.to_string(identifier)
  end
end

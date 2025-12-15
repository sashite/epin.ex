defmodule Sashite.Epin do
  @moduledoc """
  EPIN (Extended Piece Identifier Notation) implementation for Elixir.

  EPIN extends PIN by adding a **derivation marker** to track piece style
  in cross-style games.

  **EPIN is simply: PIN + optional style derivation marker (`'`)**

  ## Format

      <pin-token>[<derivation-marker>]

  Where `<pin-token>` is a valid PIN token and `<derivation-marker>` is
  an optional trailing apostrophe (`'`).

  ## Five Fundamental Attributes

  EPIN exposes all five attributes from the Sashité Game Protocol:

  - **Piece Name** → `epin.pin.type`
  - **Piece Side** → `epin.pin.side`
  - **Piece State** → `epin.pin.state`
  - **Terminal Status** → `epin.pin.terminal`
  - **Piece Style** → `epin.derived` (native vs derived)

  ## Examples

      iex> {:ok, epin} = Sashite.Epin.parse("K^'")
      iex> epin.pin.type
      :K
      iex> epin.pin.terminal
      true
      iex> epin.derived
      true

      iex> pin = Sashite.Pin.parse!("K^")
      iex> epin = Sashite.Epin.new(pin, derived: true)
      iex> Sashite.Epin.to_string(epin)
      "K^'"

      iex> Sashite.Epin.valid?("K^'")
      true

      iex> Sashite.Epin.valid?("K'^")
      false

  See the [EPIN Specification](https://sashite.dev/specs/epin/1.0.0/) for details.
  """

  alias Sashite.Pin

  @type t :: %__MODULE__{
          pin: Pin.t(),
          derived: boolean()
        }

  @enforce_keys [:pin, :derived]
  defstruct [:pin, :derived]

  @epin_pattern ~r/\A(?<pin>[-+]?[A-Za-z]\^?)(?<derived>')?\z/

  # ==========================================================================
  # Creation and Parsing
  # ==========================================================================

  @doc """
  Creates a new EPIN struct from a PIN struct.

  ## Parameters

  - `pin` - A `%Sashite.Pin{}` struct
  - `opts` - Options keyword list. Supports `:derived` (boolean, defaults to `false`).

  ## Examples

      iex> pin = Sashite.Pin.parse!("K^")
      iex> epin = Sashite.Epin.new(pin)
      iex> epin.derived
      false

      iex> pin = Sashite.Pin.parse!("K^")
      iex> epin = Sashite.Epin.new(pin, derived: true)
      iex> epin.derived
      true

  """
  @spec new(Pin.t(), keyword()) :: t()
  def new(%Pin{} = pin, opts \\ []) do
    derived = Keyword.get(opts, :derived, false)

    %__MODULE__{
      pin: pin,
      derived: !!derived
    }
  end

  @doc """
  Parses an EPIN string into an EPIN struct.

  Returns `{:ok, epin}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> Sashite.Epin.parse("K")
      {:ok, %Sashite.Epin{pin: %Sashite.Pin{type: :K, side: :first, state: :normal, terminal: false}, derived: false}}

      iex> Sashite.Epin.parse("K'")
      {:ok, %Sashite.Epin{pin: %Sashite.Pin{type: :K, side: :first, state: :normal, terminal: false}, derived: true}}

      iex> Sashite.Epin.parse("+R^'")
      {:ok, %Sashite.Epin{pin: %Sashite.Pin{type: :R, side: :first, state: :enhanced, terminal: true}, derived: true}}

      iex> Sashite.Epin.parse("invalid")
      {:error, "Invalid EPIN string: invalid"}

  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, String.t()}
  def parse(epin_string) when is_binary(epin_string) do
    case Regex.named_captures(@epin_pattern, epin_string) do
      nil ->
        {:error, "Invalid EPIN string: #{epin_string}"}

      captures ->
        pin_string = captures["pin"]
        derived_marker = captures["derived"]

        case Pin.parse(pin_string) do
          {:ok, pin} ->
            derived = derived_marker == "'"
            {:ok, %__MODULE__{pin: pin, derived: derived}}

          {:error, _reason} ->
            {:error, "Invalid EPIN string: #{epin_string}"}
        end
    end
  end

  def parse(epin_string) do
    {:error, "Invalid EPIN string: #{inspect(epin_string)}"}
  end

  @doc """
  Parses an EPIN string into an EPIN struct.

  Returns the EPIN struct on success, raises `ArgumentError` on failure.

  ## Examples

      iex> Sashite.Epin.parse!("K^'")
      %Sashite.Epin{pin: %Sashite.Pin{type: :K, side: :first, state: :normal, terminal: true}, derived: true}

      iex> Sashite.Epin.parse!("invalid")
      ** (ArgumentError) Invalid EPIN string: invalid

  """
  @spec parse!(String.t()) :: t()
  def parse!(epin_string) do
    case parse(epin_string) do
      {:ok, epin} -> epin
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Checks if a string is a valid EPIN notation.

  ## Examples

      iex> Sashite.Epin.valid?("K")
      true

      iex> Sashite.Epin.valid?("K'")
      true

      iex> Sashite.Epin.valid?("+R^'")
      true

      iex> Sashite.Epin.valid?("K'^")
      false

      iex> Sashite.Epin.valid?("K''")
      false

      iex> Sashite.Epin.valid?("invalid")
      false

  """
  @spec valid?(String.t()) :: boolean()
  def valid?(epin_string) when is_binary(epin_string) do
    Regex.match?(@epin_pattern, epin_string)
  end

  def valid?(_), do: false

  # ==========================================================================
  # Conversion
  # ==========================================================================

  @doc """
  Converts an EPIN struct to its string representation.

  ## Examples

      iex> pin = Sashite.Pin.parse!("K^")
      iex> epin = Sashite.Epin.new(pin)
      iex> Sashite.Epin.to_string(epin)
      "K^"

      iex> pin = Sashite.Pin.parse!("K^")
      iex> epin = Sashite.Epin.new(pin, derived: true)
      iex> Sashite.Epin.to_string(epin)
      "K^'"

      iex> pin = Sashite.Pin.parse!("+R")
      iex> epin = Sashite.Epin.new(pin, derived: true)
      iex> Sashite.Epin.to_string(epin)
      "+R'"

  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{pin: pin, derived: derived}) do
    Pin.to_string(pin) <> derivation_suffix(derived)
  end

  defp derivation_suffix(true), do: "'"
  defp derivation_suffix(false), do: ""

  # ==========================================================================
  # Transformations
  # ==========================================================================

  @doc """
  Returns a new EPIN with a different PIN component.

  ## Examples

      iex> epin = Sashite.Epin.parse!("K^'")
      iex> new_pin = Sashite.Pin.with_type(epin.pin, :Q)
      iex> new_epin = Sashite.Epin.with_pin(epin, new_pin)
      iex> Sashite.Epin.to_string(new_epin)
      "Q^'"

  """
  @spec with_pin(t(), Pin.t()) :: t()
  def with_pin(%__MODULE__{} = epin, %Pin{} = new_pin) do
    %{epin | pin: new_pin}
  end

  @doc """
  Returns a new EPIN with a different derivation status.

  ## Examples

      iex> epin = Sashite.Epin.parse!("K^")
      iex> derived_epin = Sashite.Epin.with_derived(epin, true)
      iex> Sashite.Epin.to_string(derived_epin)
      "K^'"

      iex> epin = Sashite.Epin.parse!("K^'")
      iex> native_epin = Sashite.Epin.with_derived(epin, false)
      iex> Sashite.Epin.to_string(native_epin)
      "K^"

  """
  @spec with_derived(t(), boolean()) :: t()
  def with_derived(%__MODULE__{derived: derived} = epin, derived), do: epin
  def with_derived(%__MODULE__{} = epin, new_derived), do: %{epin | derived: !!new_derived}

  @doc """
  Returns a new EPIN marked as derived.

  ## Examples

      iex> epin = Sashite.Epin.parse!("K^")
      iex> derived = Sashite.Epin.mark_derived(epin)
      iex> derived.derived
      true

  """
  @spec mark_derived(t()) :: t()
  def mark_derived(%__MODULE__{derived: true} = epin), do: epin
  def mark_derived(%__MODULE__{} = epin), do: %{epin | derived: true}

  @doc """
  Returns a new EPIN marked as native (not derived).

  ## Examples

      iex> epin = Sashite.Epin.parse!("K^'")
      iex> native = Sashite.Epin.unmark_derived(epin)
      iex> native.derived
      false

  """
  @spec unmark_derived(t()) :: t()
  def unmark_derived(%__MODULE__{derived: false} = epin), do: epin
  def unmark_derived(%__MODULE__{} = epin), do: %{epin | derived: false}

  # ==========================================================================
  # Queries
  # ==========================================================================

  @doc """
  Checks if the EPIN is derived (uses opponent's style).

  ## Examples

      iex> epin = Sashite.Epin.parse!("K^'")
      iex> Sashite.Epin.derived?(epin)
      true

      iex> epin = Sashite.Epin.parse!("K^")
      iex> Sashite.Epin.derived?(epin)
      false

  """
  @spec derived?(t()) :: boolean()
  def derived?(%__MODULE__{derived: true}), do: true
  def derived?(%__MODULE__{}), do: false

  @doc """
  Checks if the EPIN is native (uses own side's style).

  ## Examples

      iex> epin = Sashite.Epin.parse!("K^")
      iex> Sashite.Epin.native?(epin)
      true

      iex> epin = Sashite.Epin.parse!("K^'")
      iex> Sashite.Epin.native?(epin)
      false

  """
  @spec native?(t()) :: boolean()
  def native?(%__MODULE__{derived: false}), do: true
  def native?(%__MODULE__{}), do: false

  @doc """
  Checks if two EPINs have the same derivation status.

  ## Examples

      iex> epin1 = Sashite.Epin.parse!("K^'")
      iex> epin2 = Sashite.Epin.parse!("Q'")
      iex> Sashite.Epin.same_derived?(epin1, epin2)
      true

      iex> epin1 = Sashite.Epin.parse!("K^'")
      iex> epin2 = Sashite.Epin.parse!("K^")
      iex> Sashite.Epin.same_derived?(epin1, epin2)
      false

  """
  @spec same_derived?(t(), t()) :: boolean()
  def same_derived?(%__MODULE__{derived: derived}, %__MODULE__{derived: derived}), do: true
  def same_derived?(%__MODULE__{}, %__MODULE__{}), do: false
end

defimpl String.Chars, for: Sashite.Epin do
  def to_string(epin) do
    Sashite.Epin.to_string(epin)
  end
end

defimpl Inspect, for: Sashite.Epin do
  def inspect(epin, _opts) do
    "#Sashite.Epin<#{Sashite.Epin.to_string(epin)}>"
  end
end

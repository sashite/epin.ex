# epin.ex

[![Hex Version](https://img.shields.io/hexpm/v/sashite_epin.svg)](https://hex.pm/packages/sashite_epin)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/sashite_epin/)
[![CI](https://github.com/sashite/epin.ex/actions/workflows/elixir.yml/badge.svg?branch=main)](https://github.com/sashite/epin.ex/actions)
[![License](https://img.shields.io/hexpm/l/sashite_epin.svg)](https://github.com/sashite/epin.ex/blob/main/LICENSE)

> **EPIN** (Extended Piece Identifier Notation) implementation for Elixir.

## Overview

This library implements the [EPIN Specification v1.0.0](https://sashite.dev/specs/epin/1.0.0/).

EPIN extends [PIN](https://sashite.dev/specs/pin/1.0.0/) with an optional derivation marker (`'`) that flags whether a piece uses a native or derived style.

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:sashite_epin, "~> 1.1"}
  ]
end
```

## Dependencies

```elixir
{:sashite_pin, "~> 2.1"}  # Piece Identifier Notation
```

## Usage

### Parsing (String → Identifier)

Convert an EPIN string into an `Identifier` struct.

```elixir
# Safe parsing (returns {:ok, identifier} or {:error, reason})
{:ok, epin} = Sashite.Epin.parse("K^'")
Sashite.Epin.Identifier.to_string(epin)  # => "K^'"

# Access PIN attributes through the component
epin.pin.abbr      # => :K
epin.pin.side      # => :first
epin.pin.state     # => :normal
epin.pin.terminal  # => true

# Access derivation status
Sashite.Epin.Identifier.derived?(epin)  # => true
Sashite.Epin.Identifier.native?(epin)   # => false

# PIN component is a full Sashite.Pin.Identifier struct
Sashite.Pin.Identifier.enhanced?(epin.pin)      # => false
Sashite.Pin.Identifier.first_player?(epin.pin)  # => true

# Bang variant raises on error
epin = Sashite.Epin.parse!("K^'")

# Invalid input
{:error, reason} = Sashite.Epin.parse("invalid")
```

### Formatting (Identifier → String)

Convert an `Identifier` back to an EPIN string.

```elixir
alias Sashite.Epin.Identifier
alias Sashite.Pin.Identifier, as: PinId

# From PIN component
{:ok, pin} = Sashite.Pin.parse("K^")
epin = Identifier.new(pin)
Identifier.to_string(epin)  # => "K^"

# With derivation
epin = Identifier.new(pin, derived: true)
Identifier.to_string(epin)  # => "K^'"

# String interpolation works via String.Chars protocol
"Piece: #{epin}"  # => "Piece: K^'"
```

### Validation

```elixir
# Boolean check
Sashite.Epin.valid?("K")         # => true
Sashite.Epin.valid?("+R^'")      # => true
Sashite.Epin.valid?("invalid")   # => false
Sashite.Epin.valid?("K''")       # => false
Sashite.Epin.valid?("K'^")       # => false
```

### Accessing Components

```elixir
{:ok, epin} = Sashite.Epin.parse("+R^'")

# Get PIN component
epin.pin  # => %Sashite.Pin.Identifier{abbr: :R, side: :first, state: :enhanced, terminal: true}
Sashite.Pin.Identifier.to_string(epin.pin)  # => "+R^"

# Check derivation
Sashite.Epin.Identifier.derived?(epin)  # => true
Sashite.Epin.Identifier.native?(epin)   # => false

# Serialize
Sashite.Epin.Identifier.to_string(epin)  # => "+R^'"
```

### Transformations

All transformations return new immutable structs.

```elixir
alias Sashite.Epin.Identifier

{:ok, epin} = Sashite.Epin.parse("K^")

# Derivation transformations
Identifier.to_string(Identifier.derive(epin))  # => "K^'"
Identifier.to_string(Identifier.native(epin))  # => "K^"

# Replace PIN component
{:ok, new_pin} = Sashite.Pin.parse("+Q^")
Identifier.to_string(Identifier.with_pin(epin, new_pin))  # => "+Q^"
```

### Transform via PIN Component

```elixir
alias Sashite.Epin.Identifier
alias Sashite.Pin.Identifier, as: PinId

{:ok, epin} = Sashite.Epin.parse("K^'")

# Change abbr
epin
|> Identifier.with_pin(PinId.with_abbr(epin.pin, :Q))
|> Identifier.to_string()  # => "Q^'"

# Change state
epin
|> Identifier.with_pin(PinId.enhance(epin.pin))
|> Identifier.to_string()  # => "+K^'"

# Change side
epin
|> Identifier.with_pin(PinId.flip(epin.pin))
|> Identifier.to_string()  # => "k^'"

# Remove terminal
epin
|> Identifier.with_pin(PinId.non_terminal(epin.pin))
|> Identifier.to_string()  # => "K'"
```

### Component Queries

Use the PIN API directly:

```elixir
alias Sashite.Epin.Identifier
alias Sashite.Pin.Identifier, as: PinId

{:ok, epin} = Sashite.Epin.parse("+P^'")

# PIN queries
epin.pin.abbr                   # => :P
epin.pin.side                   # => :first
epin.pin.state                  # => :enhanced
epin.pin.terminal               # => true
PinId.first_player?(epin.pin)   # => true
PinId.enhanced?(epin.pin)       # => true

# EPIN queries
Identifier.derived?(epin)  # => true
Identifier.native?(epin)   # => false

# Compare EPINs
{:ok, other} = Sashite.Epin.parse("+P^")
PinId.same_abbr?(epin.pin, other.pin)    # => true
PinId.same_state?(epin.pin, other.pin)   # => true
Identifier.same_derived?(epin, other)    # => false
```

## API Reference

### Types

```elixir
# Identifier represents a parsed EPIN combining PIN with derivation status.
defmodule Sashite.Epin.Identifier do
  @type t :: %__MODULE__{
    pin: Sashite.Pin.Identifier.t(),
    derived: boolean()
  }

  # Creates an Identifier from a PIN component.
  # Raises ArgumentError if the PIN is invalid.
  @spec new(Sashite.Pin.Identifier.t(), keyword()) :: t()
  def new(pin, opts \\ [])

  # Returns true if derived style.
  @spec derived?(t()) :: boolean()
  def derived?(identifier)

  # Returns true if native style.
  @spec native?(t()) :: boolean()
  def native?(identifier)

  # Returns the EPIN string representation.
  @spec to_string(t()) :: String.t()
  def to_string(identifier)
end
```

### Parsing

```elixir
# Parses an EPIN string into an Identifier.
@spec Sashite.Epin.parse(String.t()) :: {:ok, Identifier.t()} | {:error, atom()}
def parse(string)

# Parses an EPIN string, raises on error.
@spec Sashite.Epin.parse!(String.t()) :: Identifier.t()
def parse!(string)
```

### Validation

```elixir
# Reports whether string is a valid EPIN.
@spec Sashite.Epin.valid?(term()) :: boolean()
def valid?(string)
```

### Transformations

```elixir
# PIN replacement (returns new Identifier)
@spec with_pin(t(), Sashite.Pin.Identifier.t()) :: t()
def with_pin(identifier, new_pin)

# Derivation transformations
@spec derive(t()) :: t()
def derive(identifier)

@spec native(t()) :: t()
def native(identifier)
```

### Errors

Parsing errors return tagged tuples:

| Error | Cause |
|-------|-------|
| `{:error, :invalid_derivation_marker}` | Derivation marker misplaced or duplicated |
| `{:error, :invalid_pin}` | PIN parsing failed |
| `{:error, :empty_input}` | Empty string |

The bang variant `parse!/1` raises `ArgumentError` with descriptive messages.

## PIN Compatibility

Every valid PIN is a valid EPIN (native by default):

```elixir
~w[K +R -p K^ +R^]
|> Enum.each(fn pin_token ->
  {:ok, epin} = Sashite.Epin.parse(pin_token)
  true = Sashite.Epin.Identifier.native?(epin)
  ^pin_token = Sashite.Epin.Identifier.to_string(epin)
end)
```

## Design Principles

- **Pure composition**: EPIN composes PIN without reimplementing features
- **Minimal API**: Core functions (`derived?/1`, `native?/1`, `to_string/1`) plus transformations
- **Component transparency**: Access PIN directly via `epin.pin`
- **Immutable structs**: Functional transformations return new structs
- **Elixir idioms**: `{:ok, _} | {:error, _}` tuples, bang variants, pattern matching

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [EPIN Specification](https://sashite.dev/specs/epin/1.0.0/) — Official specification
- [EPIN Examples](https://sashite.dev/specs/epin/1.0.0/examples/) — Usage examples
- [PIN Specification](https://sashite.dev/specs/pin/1.0.0/) — Base component

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).

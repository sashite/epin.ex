# Sashite.Epin

[![Hex.pm](https://img.shields.io/hexpm/v/sashite_epin.svg)](https://hex.pm/packages/sashite_epin)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/sashite_epin)
[![License](https://img.shields.io/hexpm/l/sashite_epin.svg)](https://github.com/sashite/epin.ex/blob/main/LICENSE.md)

> **EPIN** (Extended Piece Identifier Notation) implementation for Elixir.

## What is EPIN?

EPIN (Extended Piece Identifier Notation) extends [PIN](https://sashite.dev/specs/pin/1.0.0/) by adding a **derivation marker** to track piece style in cross-style games.

**EPIN is simply: PIN + optional style derivation marker (`'`)**

This library implements the [EPIN Specification v1.0.0](https://sashite.dev/specs/epin/1.0.0/) with a minimal compositional API.

## Core Concept

```elixir
# EPIN is just PIN + derived flag
pin = Sashite.Pin.parse!("K^")
epin = Sashite.Epin.new(pin)

Sashite.Epin.to_string(epin)  # => "K^" (native)
epin.pin                       # => %Sashite.Pin{} instance
epin.derived                   # => false

# Mark as derived
derived_epin = Sashite.Epin.mark_derived(epin)
Sashite.Epin.to_string(derived_epin)  # => "K^'" (derived from opposite side's style)
```

**That's it.** All piece attributes come from the PIN component.

## Installation

```elixir
def deps do
  [
    {:sashite_epin, "~> 1.0"}
  ]
end
```

This will also install `sashite_pin` as a transitive dependency.

## Quick Start

```elixir
# Parse an EPIN string
{:ok, epin} = Sashite.Epin.parse("K^'")
Sashite.Epin.to_string(epin)  # => "K^'"

# Access five fundamental attributes through PIN component + derived flag
epin.pin.type       # => :K (Piece Name)
epin.pin.side       # => :first (Piece Side)
epin.pin.state      # => :normal (Piece State)
epin.pin.terminal   # => true (Terminal Status)
epin.derived        # => true (Piece Style: derived vs native)

# PIN component is a full %Sashite.Pin{} struct
Sashite.Pin.enhanced?(epin.pin)  # => false
Sashite.Pin.letter(epin.pin)     # => "K"
```

## Basic Usage

### Creating Identifiers

```elixir
# Parse from string
{:ok, epin} = Sashite.Epin.parse("K^")    # Native
{:ok, epin} = Sashite.Epin.parse("K^'")   # Derived

# Bang version
epin = Sashite.Epin.parse!("K^'")

# Create from PIN component
pin = Sashite.Pin.parse!("K^")
epin = Sashite.Epin.new(pin)                  # Native (default)
epin = Sashite.Epin.new(pin, derived: true)   # Derived

# Validate
Sashite.Epin.valid?("K^")    # => true
Sashite.Epin.valid?("K^'")   # => true
Sashite.Epin.valid?("K^''")  # => false (multiple markers)
Sashite.Epin.valid?("K'^")   # => false (wrong order)
```

### Accessing Components

```elixir
epin = Sashite.Epin.parse!("+R^'")

# Get PIN component
epin.pin                            # => %Sashite.Pin{}
Sashite.Pin.to_string(epin.pin)     # => "+R^"

# Check derivation
epin.derived                        # => true
Sashite.Epin.derived?(epin)         # => true

# Serialize
Sashite.Epin.to_string(epin)        # => "+R^'"
```

### Five Fundamental Attributes

All attributes accessible via PIN component + derived flag:

```elixir
epin = Sashite.Epin.parse!("+R^'")

# From PIN component (4 attributes)
epin.pin.type       # => :R (Piece Name)
epin.pin.side       # => :first (Piece Side)
epin.pin.state      # => :enhanced (Piece State)
epin.pin.terminal   # => true (Terminal Status)

# From EPIN (5th attribute)
epin.derived        # => true (Piece Style: native vs derived)
```

## Transformations

All transformations return new immutable structs.

### Change Derivation Status

```elixir
epin = Sashite.Epin.parse!("K^")

# Mark as derived
derived = Sashite.Epin.mark_derived(epin)
Sashite.Epin.to_string(derived)  # => "K^'"

# Mark as native
native = Sashite.Epin.unmark_derived(derived)
Sashite.Epin.to_string(native)  # => "K^"

# Set explicitly
toggled = Sashite.Epin.with_derived(epin, true)
Sashite.Epin.to_string(toggled)  # => "K^'"
```

### Transform via PIN Component

```elixir
epin = Sashite.Epin.parse!("K^'")

# Replace PIN component
new_pin = Sashite.Pin.with_type(epin.pin, :Q)
Sashite.Epin.to_string(Sashite.Epin.with_pin(epin, new_pin))  # => "Q^'"

# Change state
new_pin = Sashite.Pin.with_state(epin.pin, :enhanced)
Sashite.Epin.to_string(Sashite.Epin.with_pin(epin, new_pin))  # => "+K^'"

# Remove terminal marker
new_pin = Sashite.Pin.with_terminal(epin.pin, false)
Sashite.Epin.to_string(Sashite.Epin.with_pin(epin, new_pin))  # => "K'"

# Change side
new_pin = Sashite.Pin.flip(epin.pin)
Sashite.Epin.to_string(Sashite.Epin.with_pin(epin, new_pin))  # => "k^'"
```

### Multiple Transformations

```elixir
epin = Sashite.Epin.parse!("K^")

# Transform PIN and derivation
new_pin = epin.pin
          |> Sashite.Pin.with_type(:Q)
          |> Sashite.Pin.with_state(:enhanced)

transformed = epin
              |> Sashite.Epin.with_pin(new_pin)
              |> Sashite.Epin.mark_derived()

Sashite.Epin.to_string(transformed)  # => "+Q^'"
```

## Component Queries

Use the PIN module API directly:

```elixir
epin = Sashite.Epin.parse!("+P^'")

# PIN queries (name, side, state, terminal)
epin.pin.type                        # => :P
epin.pin.side                        # => :first
epin.pin.state                       # => :enhanced
epin.pin.terminal                    # => true
Sashite.Pin.first_player?(epin.pin)  # => true
Sashite.Pin.enhanced?(epin.pin)      # => true
Sashite.Pin.letter(epin.pin)         # => "P"
Sashite.Pin.prefix(epin.pin)         # => "+"
Sashite.Pin.suffix(epin.pin)         # => "^"

# EPIN queries (style)
Sashite.Epin.derived?(epin)          # => true
Sashite.Epin.native?(epin)           # => false

# Compare EPINs
other = Sashite.Epin.parse!("+P^")
Sashite.Pin.same_type?(epin.pin, other.pin)   # => true (both P)
Sashite.Pin.same_state?(epin.pin, other.pin)  # => true (both enhanced)
Sashite.Epin.same_derived?(epin, other)       # => false (different derivation)
```

## API Reference

### Main Module

```elixir
# Parse EPIN string
Sashite.Epin.parse(epin_string)   # => {:ok, %Sashite.Epin{}} | {:error, reason}
Sashite.Epin.parse!(epin_string)  # => %Sashite.Epin{} | raises ArgumentError

# Create from PIN component
Sashite.Epin.new(pin)                  # => %Sashite.Epin{} (native)
Sashite.Epin.new(pin, derived: true)   # => %Sashite.Epin{} (derived)

# Validate string
Sashite.Epin.valid?(epin_string)  # => boolean
```

### Core Methods (6 total)

```elixir
# Creation
Sashite.Epin.new(pin, opts \\ [])      # Create from PIN + derivation flag

# Component access
epin.pin                               # => %Sashite.Pin{}
epin.derived                           # => boolean

# Serialization
Sashite.Epin.to_string(epin)           # => "K^'" or "K^"

# PIN replacement
Sashite.Epin.with_pin(epin, new_pin)   # New EPIN with different PIN

# Derivation transformation
Sashite.Epin.mark_derived(epin)        # Mark as derived (add ')
Sashite.Epin.unmark_derived(epin)      # Mark as native (remove ')
Sashite.Epin.with_derived(epin, bool)  # Set derivation explicitly
```

### Convenience Queries

```elixir
Sashite.Epin.derived?(epin)            # epin.derived == true
Sashite.Epin.native?(epin)             # epin.derived == false
Sashite.Epin.same_derived?(e1, e2)     # Compare derivation status
```

**That's the entire API.** Everything else uses the PIN module API directly.

## Data Structure

```elixir
%Sashite.Epin{
  pin: %Sashite.Pin{},   # Underlying PIN struct
  derived: boolean()      # Derivation status (default: false)
}
```

## Format Specification

### Structure

```
<pin>[']
```

Where:
- `<pin>` is any valid PIN token
- `'` is the optional derivation marker

### Grammar (EBNF)

```ebnf
epin ::= pin | pin "'"
pin  ::= ["+" | "-"] letter ["^"]
letter ::= "A" | ... | "Z" | "a" | ... | "z"
```

### Regular Expression

```elixir
~r/\A[-+]?[A-Za-z]\^?'?\z/
```

## Cross-Style Game Example

In a chess-vs-makruk cross-style match where:
- First side native style = chess
- Second side native style = makruk

```elixir
# First player pieces
chess_king = Sashite.Epin.parse!("K^")   # Native Chess king
makruk_pawn = Sashite.Epin.parse!("P'")  # Derived Makruk pawn (foreign)

Sashite.Epin.native?(chess_king)    # => true (uses own style)
Sashite.Epin.derived?(makruk_pawn)  # => true (uses opponent's style)

# Second player pieces
makruk_king = Sashite.Epin.parse!("k^")  # Native Makruk king
chess_pawn = Sashite.Epin.parse!("p'")   # Derived Chess pawn (foreign)

Sashite.Epin.native?(makruk_king)   # => true
Sashite.Epin.derived?(chess_pawn)   # => true
```

## Design Principles

### 1. Pure Composition

EPIN doesn't reimplement PIN features — it extends PIN minimally:

```elixir
defstruct [:pin, :derived]

def new(%Sashite.Pin{} = pin, opts \\ []) do
  %__MODULE__{
    pin: pin,
    derived: Keyword.get(opts, :derived, false)
  }
end
```

### 2. Minimal API

**6 core methods only:**
1. `new/2` — create from PIN
2. `pin` field — get PIN component
3. `derived` field / `derived?/1` — check derivation
4. `to_string/1` — serialize
5. `with_pin/2` — replace PIN
6. `with_derived/2` / `mark_derived/1` / `unmark_derived/1` — change derivation

Everything else uses the PIN module API directly.

### 3. Component Transparency

Access PIN directly — no wrappers:

```elixir
# Use PIN API directly
epin.pin.type
Sashite.Pin.with_type(epin.pin, :Q)
Sashite.Pin.enhanced?(epin.pin)
Sashite.Pin.flip(epin.pin)

# No need for wrapper functions like:
# Sashite.Epin.type(epin)
# Sashite.Epin.with_type(epin, :Q)
# Sashite.Epin.enhanced?(epin)
# Sashite.Epin.flip(epin)
```

### 4. Backward Compatibility

Every valid PIN is a valid EPIN (without derivation marker):

```elixir
# All PIN identifiers work as EPIN
~w(K +R -p K^ +R^)
|> Enum.each(fn token ->
  {:ok, epin} = Sashite.Epin.parse(token)
  true = Sashite.Epin.native?(epin)
  ^token = Sashite.Epin.to_string(epin)
end)
```

## Comparison with PIN

### What EPIN Adds

```elixir
# PIN: 4 attributes
pin = Sashite.Pin.parse!("K^")
pin.type       # Piece Name
pin.side       # Piece Side
pin.state      # Piece State
pin.terminal   # Terminal Status

# EPIN: 5 attributes (PIN + style)
epin = Sashite.Epin.parse!("K^'")
epin.pin.type       # Piece Name
epin.pin.side       # Piece Side
epin.pin.state      # Piece State
epin.pin.terminal   # Terminal Status
epin.derived        # Piece Style (5th attribute)
```

### When to Use EPIN vs PIN

**Use PIN when:**
- Single-style games (both players use same style)
- Style information not needed
- Maximum compatibility required

**Use EPIN when:**
- Cross-style games (different styles per player)
- Pieces can change style (promotion to foreign piece)
- Need to track native vs derived pieces

## Attribute Mapping

EPIN exposes all five fundamental attributes from the Sashité Game Protocol:

| Protocol Attribute | EPIN Access | Example |
|-------------------|-------------|---------|
| **Piece Name** | `epin.pin.type` | `:K` (King), `:R` (Rook) |
| **Piece Side** | `epin.pin.side` | `:first`, `:second` |
| **Piece State** | `epin.pin.state` | `:normal`, `:enhanced`, `:diminished` |
| **Terminal Status** | `epin.pin.terminal` | `true`, `false` |
| **Piece Style** | `epin.derived` | `false` (native), `true` (derived) |

## Related Specifications

- [EPIN Specification v1.0.0](https://sashite.dev/specs/epin/1.0.0/) — Technical specification
- [EPIN Examples](https://sashite.dev/specs/epin/1.0.0/examples/) — Usage examples
- [PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/) — Base component
- [Sashité Game Protocol](https://sashite.dev/game-protocol/) — Foundation

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).

## About

Maintained by [Sashité](https://sashite.com/) — promoting chess variants and sharing the beauty of board game cultures.

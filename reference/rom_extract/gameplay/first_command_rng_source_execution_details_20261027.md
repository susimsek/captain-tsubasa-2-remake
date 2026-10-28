# First-command receiver RNG: static execution details — 2026-10-27

## ROM identity

All addresses below were checked against the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. File
offsets include the 16-byte iNES header.

## `$C9C5` entry carry is source-determined

The earlier RNG notes correctly identified that `$C9C5` has no entry
`CLC`/`SEC`, but the incoming carry can be resolved from its normal NMI caller.
The relevant fixed-bank bytes are:

- `$C9E9` / file `0x03C9F9` sets `Y=$02`, then loops through `INY; CPY #$06;
  BNE` at `$CA1C–$CA20`. The final comparison is equal and sets carry.
- The routine returns to `$C7CD`. Before `$C7E4 JSR $C9C5`, the caller executes
  `LDX $8E; STX $8C; STX $8D; LDA $C8F7,X; AND #$7F; STA $C000; STA $C001;
  LDX $0469; STA $E000,X`. None of those instructions changes carry.
- Therefore the normal `$C775` NMI route enters `$C9C5` with carry set. This
  conclusion follows from control flow and instruction flags; it does not use
  RAM captures.

Caller bytes are at `$C7CA–$C7E4` / file `0x03C7DA–0x03C7F4`; the `$C9E9`
loop is at file `0x03C9F9–0x03CA30`. `$C9C5` itself is at file `0x03C9D5`:

```text
LDX $00E1
LDA $0300,X
ADC $0700,X
ROL $00E2
EOR #$FF
ROL $00E2
ADC $00E2
STA $00E2
SBC $0780,X
ADC $00E1
STA $00E3
INC $00E1
RTS
```

This makes a native implementation of the helper straightforward once its
RAM operands and call event are represented. The existing Godot replay still
loads per-call `$E1/$E2/$E3` results; it does not execute this routine.

## Operand initialization and route mutations

The reset route `$FFF0 → $C503 → $C64E` clears CPU RAM `$0000–$07FF`, including
`$0300`, `$0700`, and `$0780`. These bytes therefore start at zero after the
ROM reset clear, but they are working RAM, not immutable RNG tables:

- `$0300,X` addresses the player-record RAM page. Fresh-match setup fills
  those records from the selected roster and player data.
- `$0700,X` overlaps the sound-command queue at `$0700–$0704` and other live
  RAM used while the route runs. Cutscene and audio code mutate it.
- NES 2 KiB internal RAM mirrors at `$0800`. Thus `$0780,X` with `X >= $80`
  accesses mirrored zero-page addresses `$0000–$007F`; a Godot state model
  must apply the CPU address mirror rather than index a flat array directly.

In the audited fixed input run, `$C9C5` begins with `X=$FA`, advances X through
`$FF`, wraps through `$00`, and ends with post-call `$E1=$7F`. Its operand
addresses therefore cross both the `$E1` wrap and the `$0780,X` RAM mirror.
That observed call sequence is not a general default for other controller
histories.

## `$A116` RNG entry, `$A117` arithmetic body, NMI mode, and input timing

The byte-verified bank-$02 RNG span starts at `$A116` / file `0x004126` with
`CLC`; the first arithmetic-body instruction, `LDA $E1`, is at `$A117` / file
`0x004127`. `$A117` then performs the `$E1 += $83`, `$E2 += $0D + carry`,
`$E3 += $11 + carry` sequence. The carry chain is therefore defined internally.
`$C76E` / file `0x03C77E`
tests bit 6 of `$001B`: set routes NMI through `$C421 → bank-$02:$A000`, where
the controller-read path reaches the `$A116` entry; clear routes through `$C775`, whose
normal NMI body calls `$C9C5` at `$C7E4`. The `$001B.6` producer and the route
logic that determines which NMI branch runs are not yet represented by the
Godot route model.

The existing ROM-only Python stepper executes those ROM branches, tracks CPU
flags/RAM, and accepts controller input as a per-source-frame timeline. Its
`run_frame()` installs that frame's complete controller state before the
frame's vblank/NMI work; it does not model an asynchronous controller edge at
an arbitrary CPU cycle. It is a diagnostics tool that reads the ROM and uses
simplified PPU/DMC timing, not an allowed runtime dependency. The currently
packaged Godot schedule is a verified replay for one timeline hash, not a
general interactive RNG.

## Smallest source-faithful path

To remove the timeline-hash dependency without inventing a receiver, the
Godot route needs to own (or source-execute) the live NMI mode/call schedule,
frame-sampled controller state, and writes to the three `$C9C5` operand
regions. Then `$A117`, `$C9C5` (with proven incoming carry 1), and the ROM
receiver table can be translated directly. The carry uncertainty is closed;
the mutable RAM producers, `$001B.6` producer, and live call cadence remain
the material blockers. A ROM-free high-level translation is possible, but it
requires those route-state writers to be mapped before the receiver can be
derived generically.

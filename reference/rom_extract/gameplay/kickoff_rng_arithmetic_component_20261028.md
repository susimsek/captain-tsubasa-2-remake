# KICK OFF RNG arithmetic component — 2026-10-28

## Source identity and pinned instructions

The instruction spans below were copied from the supplied Turkish ROM after
checking whole-file SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. Offsets
include the 16-byte iNES header; PRG bank numbers are 8 KiB.

| Update | CPU span | File offset | Length | Span SHA-256 |
|---|---:|---:|---:|---|
| A117 arithmetic body, including preceding entry CLC | `$A116–$A128` in bank `$02` | `0x004126` | 19 bytes | `96d2e722dfb21bf4b41493960cfee8035306d9de9f87a1516da655a2831c5fa9` |
| C9C5 indexed update and RTS | `$C9C5–$C9E8` in fixed bank `$1E` / bank 30 | `0x03C9D5` | 36 bytes | `7989c2867a7687a0a79daed64aa10950f5222678cdafa871a7aab8a374f07de0` |

The A117 label historically used for the update names the first arithmetic
instruction. The entry `CLC` is one byte earlier, at `$A116`; `$A117` begins
`LDA $E1`. This corrects the earlier address description in the dated RNG
execution notes. The preserved bytes and manifest are in
[`rng_arithmetic/`](rng_arithmetic/).

## Godot helper contract

[`rom_kickoff_rng_arithmetic.gd`](../../../scripts/gameplay/rom_kickoff_rng_arithmetic.gd)
implements only the source arithmetic:

- `step_a117(e1, e2, e3)` models the `$A116` `CLC` followed by the three
  carry-linked additions. Its result is `Vector4i(E1, E2, E3, carry_out)`.
- `step_c9c5(e1, e2, e3, incoming_carry, ram)` follows `$C9C5–$C9E8` with an
  explicit incoming carry and 2 KiB internal RAM image. Its result has the
  same `Vector4i` layout. CPU RAM reads use address `& $07FF`, including the
  `$0780,X` range mirroring to `$0000–$007F` for `X >= $80`.

The normal `$C7E4` NMI caller reaches `$C9C5` with carry set; the helper still
takes carry explicitly so the instruction contract is visible and other
callers cannot silently inherit that assumption. The helper does not read the
ROM, trace captures, replay schedule, or emulator at runtime.

## Focused verification

Run `godot --headless --path . --script
tools/diagnostics/verify_kickoff_rng_arithmetic.gd` in the source checkout that
contains the supplied ROM. The verifier checks the full ROM hash, compares both
preserved byte spans with their original offsets, verifies the span hashes,
then interprets those pinned 6502 opcode bytes and compares the results with
the Godot helper. The current vector matrix covers 729 A117 states and 1,620
C9C5 states over five generated 2 KiB RAM patterns, both carry inputs, carry
edges, and `$0780,X` mirror cases. The synthetic RAM patterns are arithmetic
fixtures, not captured game state.

## Fidelity boundary

This component does not determine when `$A116` or `$C9C5` runs. It does not
produce live `$001B.6`, controller-poll, player-record `$0300`, sound-driver
`$0700`, or scratch/mirror `$0780` state, and it does not dispatch receiver
selection. Keep `RomKickoffRngSourceReplay` hash-bound and diagnostic for its
recorded route. Do not feed trace RAM into this helper as runtime state or
connect its result to `KickoffRouteRuntime` until source-owned call and operand
producers are integrated.

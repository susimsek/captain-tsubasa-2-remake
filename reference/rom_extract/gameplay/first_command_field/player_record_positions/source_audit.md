# Match player initial-position source audit

## Supplied ROM and spans

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- The preserved instruction/data spans and byte hashes are listed in `manifest.json`.
- `$DC07` is at file offset `0x03DC17`; `$DC87` is at `0x03DC97`; `$DCB3` is at `0x03DCC3`.
- `$CD7C` is at `0x03CD8C`; its 22-entry pointer table starts at `$CD89` / file offset `0x03CD99`.
- `$CDC9` is at file offset `0x03CDD9`.

## Corrected formation stride

The `$DC07` prologue computes each formation's table base with this 6502 sequence:

```text
LDA $002C       ; formation
ASL             ; 2 × formation
PHA
ADC $002C       ; 3 × formation
STA $3A
PLA             ; restore 2 × formation
ASL             ; 4 × formation
ASL             ; 8 × formation
ADC $3A          ; 8 + 3 = 11 × formation
STA $3A
```

The away formation at `$002E` uses the same sequence and stores its base in `$3B`.
Each source position table has 44 relevant bytes: four formation rows with 11 player slots
per row. The earlier 15-slot stride interpretation was incorrect; it is superseded by the
preserved `$DC07` bytes and the 44-byte table extents. The secondary table's next ROM byte
belongs to adjacent data and is not part of the position table.

## Slot and table selection

`$DC07` initializes global slots 0–21. Slots 0–10 use the home formation and local slot;
slots 11–21 use the away formation and local slot `global_slot - 11`. The side input at
`$05FB` must be 0 (home) or 11 (away). For each player, `$DC87` is selected when that
player's team side matches `$05FB`; otherwise `$DCB3` is selected. The encoded byte is
passed to `$CDC9`. When `$05FB` is nonzero, the returned X and Y values are independently
two's-complement mirrored. `$DC07` stores X at record offset +6 and Y at +8.

`$CDC9` repeatedly subtracts `$0C`; its loop count is the quotient and the remainder is
left in A. The resulting coordinates are `x = $34 + 8 × quotient` and
`y = $54 + 8 × remainder`. `$CD7C` doubles the global slot and reads a little-endian
pointer from `$CD89`; the 22 preserved entries resolve to `$0300 + 12 × slot`.

## Implementation and validation boundary

`scripts/gameplay/rom_match_player_position_initializer.gd` applies these byte-backed
table and transform rules from the live slot-`$05` `$DAF2` boundary. It requires
match-zero context already decoded from ROM logic and checks the live
`$002C/$002E/$05FB` inputs against it; it does not import a capture. It applies
the formation scratch updates, pointer-table reads, 22 ordered record writes,
slot-11 `$+7` clear, stack-page effects, and the `$DAF5` return contract.
Later movement and dynamic actor selection remain out of scope.

The recorded frame-8593 A-input verification compares all 22 calculated X/Y
pairs against `reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008593.bin`.
That capture is diagnostic-only and confirms values for the same recorded
input frame; it does not prove instruction-phase or source-cycle equivalence.

## Route integration status — 30 October 2026

The live Godot source route now continues past `$DAF5`: it executes the
`$DC82` receiver-table selection and `$E6EC` holder-record copy, including
`$CDE2`, then returns at `$DB0E`. This implementation is documented in
`../e6ec_holder_copy_live_route_20261030.md`. The coordinate copy is
source-executed. The live route now consumes a ROM-only, input-hash-bound RNG
replay; 3,901 retained RAM snapshots match. Its operand triples and carry
inputs match the FCEUX trace. This does not generalize RNG to arbitrary input
histories. The ROM-only operand trace and cross-check are documented in
`../../first_command_rng_operand_trace_20261030.md`.

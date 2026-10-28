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

`scripts/gameplay/rom_match_player_position_initializer.gd` applies only these byte-backed
table and transform rules. It requires explicit match index, home/away formations, side,
and caller-owned decoded-game-logic context; it neither reads emulator captures nor infers
the route's active formation/side event. It supports match index 0 and four table rows.
It initializes static record coordinates only; later movement and dynamic actor selection
are out of scope. The focused verifier calculates slot 6 from the extracted source bytes.
If the local frame-8953 RAM dump exists, the verifier compares its record coordinates only
as a diagnostic oracle; those capture values are not helper inputs or expected constants.

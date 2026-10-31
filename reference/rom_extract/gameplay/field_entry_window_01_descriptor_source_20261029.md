# Field-Entry Window Descriptor `$01` Source Contract

## Scope

This audit covers only descriptor `$01` at `$B464`: its four `$ED/$EE` row
records, fresh-match operands, ROM string conversion, and `$04A5` packet
substitutions. It does not cover the field map, palette, OAM, scroll, or raster
state. The ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

## ROM-owned inputs and handlers

| Row progress | Column | ROM stream | Handler | Source result |
| ---: | ---: | --- | --- | --- |
| 1 | 1 | `$ED 00 $FC` | `$89BA` vector → `$8AE7` | Selector-produced home team `$002A=0`; ROM string pointer `$F776`; three converted tiles `DF CD DB` |
| 1 | 5 | `$EE 00 $FC` | `$89BA` vector → `$8B2F` → `$8C55` | Fresh setup zero-fill gives `$0628=0`; formatter output remains incomplete because its caller-owned `$003C` input is unsourced |
| 3 | 1 | `$ED 01 $FC` | `$89BA` vector → `$8AE7` | Selector-produced away team `$002B=3`; ROM string pointer `$F785`; three converted tiles `D2 D8 E1` |
| 3 | 5 | `$EE 01 $FC` | `$89BA` vector → `$8B2F` → `$8C55` | Fresh-period task writes `$0629=0`; formatter output remains incomplete because its caller-owned `$003C` input is unsourced |

`$ED` reads operand 0 or 1, selects `$002A` or `$002B`, indexes the ROM
length table at `$8B0A`, adds `$76` to the team ID, and resolves a team-name
pointer through `$C53C → $F30F`. For the supported fresh-match IDs, the length
table yields three characters. The text loop at `$8A6F` visits source
characters in order and calls `$C524 → $CBC2`. For these uppercase ASCII
letters, the verified converter path applies `SBC #$AE`, `SBC #$05`, and
`CLC/ADC #$40`, producing the source byte plus `$8C`.

The team IDs come from the hash-checked `$A20F → $A86E → $A8B6 RTS` selector
result. `$0628` is inside the fresh setup's ROM `$AA06` zero-fill range
`$0468-$06FF`; `$0629` is written as zero by the fresh-period task
`$D11E-$D182` before `$DAAA`.

## Exact packet result and stop boundary

The ROM layout builder produces eight progress packets from descriptor `$01`.
With source-derived fresh-match inputs, the known `$ED` substitutions yield
these partial records:

| Progress | PPU address | Known packet bytes | Unresolved bytes |
| ---: | ---: | --- | --- |
| 1 | `$22E1` | `07 E1 22 AA DF CD DB 00 00 AB` | `$EE 00` output |
| 3 | `$2321` | `07 21 23 AA D2 D8 E1 00 00 AB` | `$EE 01` output |

The `$EE` formatter at `$8C55` reads `$003C`, decrements it, and may return
before digit conversion when the result is zero. For a zero numeric input, the
non-early-return path also emits the ROM zero tile `$33` before returning.
Therefore `$0628=$0629=0` alone does not establish the final row packets. The
source results used here do not provide `$003C`; progress-1 and progress-3
records remain incomplete, and the descriptor cannot be submitted to the
queue. This is the exact next input required to continue; no zero value is
inferred for `$003C`.

The bounded packet source supports only team IDs 0 and 3 and zero-valued
`$0628/$0629`. Other IDs or values fail closed. The component leaves `$0515`
caller-owned and does not require the ROM or emulator at runtime.

## Verification

`godot --headless --path . --quit-after 5 --script tools/diagnostics/verify_rom_field_entry_window_01_packets.gd`
passed. It verifies the two ROM-derived `$ED` packet substitutions, the known
`$0628/$0629` producers, and refusal to mark packets queue-ready when selector,
period, or `$003C` state is missing or unsupported. It does not verify a live
route event or the final `$EE` bytes.

Source bytes and per-resource hashes are recorded in
[`field_entry_window_01/manifest.json`](field_entry_window_01/manifest.json).
The muted active-route trace and its limits are recorded in
[`field_entry_window_01_descriptor_trace_addendum_20261029.md`](field_entry_window_01_descriptor_trace_addendum_20261029.md).

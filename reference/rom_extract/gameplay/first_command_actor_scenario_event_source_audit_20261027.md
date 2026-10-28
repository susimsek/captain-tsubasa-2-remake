# First-command actor scenario/event source audit — 2026-10-27

## Scope and evidence boundary

This static follow-up resolves the bytecode/event producers for the early
`$F1` actor packets logged at source frames 8481, 8624, 8663, 8708, 8759,
8779/8781, and 8822. Source bytes were checked in the supplied Turkish ROM,
SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The writer trace at
`reference/diagnostics/first_command_actor_writer_trace_20261027_170114_utc/`
is diagnostic evidence only; its actor records are not used as runtime data.

The trace's two passes have byte-identical write/call CSVs and start/end
snapshots. FCEUX exited `-11` during shutdown after completing the outputs;
that caveat remains. ROM offsets below include the 16-byte iNES header.

## Producer chain

For these events, the ROM path is:

1. The bank-`$10` scenario reader at `$8000/$803F` reads a four-byte event
   record. Its fields supply the wait (`$0523`), event/worker selector
   (`$0524`), actor-animation selector (`$0528`), and parameter (`$0529`).
   Values below `$F0` are stored directly; the `$F0+` transformer is called
   only for values at or above `$F0`.
2. The fixed-bank scenario bridge at `$ECF8–$ED03` copies `$0528` into
   `$053C` and sets `$053A=$80`. Bank-`$14` `$800F` resolves `$053C` through
   the animation pointer table at `$8968` and interprets its ROM stream.
3. Top-level animation opcode `$F1` enters the bank-`$14` actor constructor
   at `$80AA`; the constructor uses its packet bytes and ROM pointer tables
   `$A1B4/$AC47/$88E4` to create actor records. The bank-`$14` per-actor
   interpreters at `$83D9/$84DC` then advance appearance and motion streams.

The actor constructor, actor fields, table lookups, and per-actor interpreters
are mapped in
[`first_command_actor_writer_trace_source_map_20261027.md`](first_command_actor_writer_trace_source_map_20261027.md).
The route-level scenario reader and its field assignments are in
[`scenario_interpreter_kickoff_rng_audit_20261027.md`](scenario_interpreter_kickoff_rng_audit_20261027.md).

## Event-to-packet crosswalk

The bank-`$10` scenario pointer table is at `$89BF` / file `0x0209CF`. The
bank-`$14` animation pointer table is at `$8968` / file `0x028978`; its entry
for animation ID `n` is at `0x028978 + 2*n`. Bank-`$14` CPU addresses map to
file offsets with `0x028010 + (CPU - $8000)`.

| Trace frame | Scenario source event | Animation table entry → stream root | ROM `$F1` packet bytes and file offsets |
|---:|---|---|---|
| 8481 | Scenario `$35`: entry `CD B7` at `0x020A39` → `$B7CD` / `0x0237DD`; event `02 3A 8F 73` at `0x0237E0` | ID `$8F`: `85 98` at `0x028A96` → `$9885` / `0x029895` | `F1 00 91 00 D3 01` at `0x02989C`; `F1 70 92 28 C3 05` at `0x0298A2`; `F1 70 92 00 C3 08` at `0x0298A8`; `F1 71 93 B8 B3 0C` at `0x0298AE`; `F1 71 93 00 B3 10` at `0x0298B4` |
| 8624 | Scenario `$36`: entry `E4 B7` at `0x020A3B` → `$B7E4` / `0x0237F4`; event `20 0C 4E 74` at `0x0237FF` | ID `$4E`: `61 92` at `0x028A14` → `$9261` / `0x029271` | `F1 00 27 10 CB 01` at `0x029278` |
| 8663 | Scenario `$36`; event `32 72 66 F0` at `0x023808` | ID `$66`: `41 94` at `0x028A44` → `$9441` / `0x029451` | `F1 5D 31 B0 D3 04` at `0x029458`; `F1 A9 C4 B8 DB 00` at `0x02945F` |
| 8708 | Scenario `$36`; event `32 1F 4C F0` at `0x02380E` | ID `$4C`: `45 92` at `0x028A10` → `$9245` / `0x029255` | `F1 7E BA E0 BB 00` at `0x02925C` |
| 8759, 8779, 8781 | Scenario `$36`; event `3E 01 E6 75` at `0x023815` | ID `$E6`: `A3 A0` at `0x028B44` → `$A0A3` / `0x02A0B3` | The `$E6` stream starts `F5 87 F8 1A 96`. Top-level `$F8` at `$816F` / file `0x02817F` replaces the current stream pointer with its inline word, redirecting to `$961A` / file `0x02962A`. This lands inside ID `$78`'s table-rooted block (`18 96` at `0x028A68` → `$9618` / `0x029628`). Before that block's first `$F0` at `0x029660`, it contains `F1 62 5E 20 BB 0D` at `0x02962F`, `F1 62 5D 20 BB 09` at `0x029635`, `F1 62 5C 20 BB 05` at `0x02963B`, `F1 63 49 A0 9F 00` at `0x029641`, `F1 00 85 08 BB 05` at `0x029653`, and `F1 8E 84 0C BB 05` at `0x02965A`. |
| 8822 | Fresh gameplay setup calls `$E233` (file `0x03E243`), which starts scenario `$1E`. Its table entry `DA B7` at `0x020A0B` points to `$B7DA` / `0x0237EA`; after `FD 02 F6 F7 01`, event `07 45 90 F0` at `0x0237EF` selects ID `$90`. | ID `$90`: `AB 98` at `0x028A98` → `$98AB` / `0x0298BB` | `F1 00 58 00 C3 09` at `0x0298C2`; `F1 00 4B 00 C3 01` at `0x0298C8`; `F1 00 4D 00 C3 05` at `0x0298CE` |

For the scenario `$35` event, the retained frame-8473 RAM snapshot independently
shows `$0524=$3A`, `$0528=$8F`, and `$0529=$73`. Other retained frame-edge
snapshots show the expected later selectors `$4E`, `$66`, and `$E6`. These
snapshots validate the static mapping only; they are not source data or runtime
inputs. The packet bytes above, not reconstructed actor records, are the
appropriate inputs for a Godot producer.

## Direct translation versus remaining state

Directly translatable from ROM bytes are the scenario records, selectors,
animation-table pointers, the `$E6 → F8 $961A` stream redirect, and the listed
`$F1` packets. The `$83D9/$84DC` actor scripts can consume the appearance and
motion pointers created by those packets. No captured RAM values are needed to
select these packet groups.

The bank-$10 reader and bank-$14 `RomActorAnimationStreamDecoder` now provide a
source-byte bridge from a decoded scenario `event_record` to its animation
stream. The animation decoder recognizes `$F0` end, `$F1` actor construction,
`$F4` selectors, `$F5` setup operands, `$F6` actor removal with its inline
record offset, `$F8` absolute redirects, and low-byte `$053B` waits. Its
relative animation ticks are source-derived; the muted timing trace validates
one `$800F` call per active source frame. The decoder does not execute the
cooperative scenario task graph or mutate actors.

To become a route-time actor presenter, the remaining implementation must
execute task slots and `$814C` dispatch from ROM state, start the `$ECF8–$ED06`
animation worker at its source handoff, apply `$F4/$F5`, and feed `$F1/$F6`
events into byte-decoded actor records. It must also preserve the live
`$83D9/$84DC` per-actor scripts, their route-selected pointer-table entries,
and the current shared selector/mirror/scroll/clip state. Do not replace those
steps with the capture's event rows or actor arrays.

The event-to-packet provenance is now closed for all listed transitions. The
separate timing trace verifies the NMI-ready set/clear, `$0519` countdown, and
actor-loop cadence for the captured route, but it does not implement the
cooperative producer in Godot or measure physical hardware timing. The `$F0`
stop rule applies to each selected top-level animation stream; a subsequent
byte range may be a different table-rooted stream and must not be appended to
the prior entry without a ROM control-flow edge.

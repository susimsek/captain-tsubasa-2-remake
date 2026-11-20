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
| 1 | 1 | `$ED 00 $FC` | `$89BA` vector → `$8AE7` | Selector-produced home team `$002A=0`; ROM string pointer `$F776`; emitted character bytes `53 41 4F` |
| 1 | 5 | `$EE 00 $FC` | `$89BA` vector → `$8B2F` → `$8C55` | Fresh setup gives `$0628=0`; the initial pass sees `$003C=1` and emits no digit, then the row-commit pass sees `$003C=0` and writes zero tile `$33` |
| 3 | 1 | `$ED 01 $FC` | `$89BA` vector → `$8AE7` | Selector-produced away team `$002B=3`; ROM string pointer `$F785`; emitted character bytes `46 4C 55` |
| 3 | 5 | `$EE 01 $FC` | `$89BA` vector → `$8B2F` → `$8C55` | Fresh-period task gives `$0629=0`; the initial pass sees `$003C=1` and emits no digit, then the row-commit pass sees `$003C=0` and writes zero tile `$33` |

`$ED` reads operand 0 or 1, selects `$002A` or `$002B`, indexes the ROM
length table at `$8B0A`, adds `$76` to the team ID, and resolves a team-name
pointer through `$C53C → $F30F`. For the supported fresh-match IDs, the length
table yields three characters. The text loop at `$8A6F` visits source
characters in order and calls `$C524 → $CBC2`. For the team-name bytes in this
route (`$41-$55`), `$CBC4` compares against `$A0`, and `$CBC6`'s `BCC +$28`
branches to `$CBF0` (`RTS`). These bytes are emitted unchanged. The arithmetic
converter block is not reached for these team-name strings.

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
| 1 | `$22E1` | `07 E1 22 AA 53 41 4F 00 00 AB` | `$EE 00` output |
| 3 | `$2321` | `07 21 23 AA 46 4C 55 00 00 AB` | `$EE 01` output |

The worker setup at `$8881` clears `$05C5`. The descriptor-row loop at
`$8949-$8985` derives first-pass `$003C` values `[1,1,3,3]` from row progress
`[1,1,3,3]`; after advancing `$05C5` to each row's progress, it re-enters the
row with `$003C=0`. A muted, two-replay FCEUX capture directly observed the
`$8C55` calls at frames 8464/8465 and again at 8786/8787: each pair has
`($05C5,$003C)=($00,$01)` followed by `($01,$00)` or `($02,$01)` followed by
`($03,$00)`. The row-commit call takes the formatter's zero-digit path and
writes `$33` for both zero-valued `$EE` rows. Queue-buffer snapshots contain
the final records `07 E1 22 AA 53 41 4F 00 33 AB` and
`07 21 23 AA 46 4C 55 00 33 AB`.

The `$003C` producer and packet substitutions are now modeled in the focused
Godot source component. This does not show that the production field renderer
consumes these records or that the live Godot route executes the worker and
queue cadence. The component leaves `$0515` caller-owned; runtime integration
and visible field output remain unresolved.

The bounded packet source supports only team IDs 0 and 3 and zero-valued
`$0628/$0629`. Other IDs or values fail closed. Its team-name output now
follows the verified `$CBC6 -> $CBF0 RTS` identity path, and the manifest
records emitted bytes `53 41 4F` / `46 4C 55`. The component leaves `$0515`
caller-owned and does not require the ROM or emulator at runtime.

## Field-presenter handoff — 9 November 2026

`FirstMatchFieldCandidatePresenter.build_and_apply()` now accepts a separate
`descriptor_01_source_context` with exactly two source-result entries:
`selector_result` and `fresh_period_result`. It calls the checked packet source
and exposes its ROM-derived `packet_records` and readiness fields in
`status.descriptor_01_team_packets`. `KickoffCutsceneVisuals`
`present_first_match_field_candidate()` forwards that context to the presenter.

The presenter intentionally does not apply these packets to PPU memory. The
production call site must pass results from the live `$A20F` selector and
fresh-period task; the visual handoff must also wait for a validated source
worker/NMI queue receipt before any packet can change the displayed field.
Without that receipt, the packet set is derivable but its visible application
and queue cadence remain open. The expected API context shape is:

```gdscript
{
    "selector_result": <live ROM selector result>,
    "fresh_period_result": <live ROM fresh-period task result>,
}
```

The focused packet-source verifier now checks the presenter packet at
`$2321` against `07 21 23 AA 46 4C 55 00 33 AB`. This is an integration seam,
not proof that the live route displays the rival label.

## Verification

`godot --headless --path . --script res://tools/diagnostics/verify_rom_field_entry_window_01_packets.gd`
passes with the corrected identity output. It verifies both ROM team strings,
their emitted bytes, descriptor `$01` packet content, `$003C` row commits,
`$EE` zero-tile substitutions, presenter packet content, and fail-closed
handling of missing or unsupported source inputs. It does not verify the live
route worker/NMI/render path.

## Production queue-consumer boundary — 9 November 2026

The existing presentation path already applies ordered source-NMI PPU bus
events: `KickoffCutsceneVisuals.apply_source_ppu_bus_events()` updates both the
screen's nametable state and its source-write overlay, and
`present_first_match_field_candidate()` merges that overlay over the newly
built field candidate. Therefore the safe integration point is the live
`$0515/$04A5` worker/NMI queue, not a direct final-screen write from the
descriptor result.

The focused `verify_rom_slot05_live_ed01_row_bbe3.gd` now exercises the
selected slot-$05 worker through `$BBE3/$BD9F`, preserves its secondary queue
through the scheduler, consumes it on a caller-supplied normal NMI, and applies
the returned bus events through the existing field renderer. This proves the
worker-to-NMI-to-renderer plumbing for the focused route-runner harness; it is
not a full interactive route replay. A focused instruction-state assertion
checks both live passes over the away stream `$46/$4C/$55` (six conversion
events): each executes `$CBC2/$CBC4/$CBC6/$CBF0`, with `$CBC6` branching to the
identity `RTS` and the accumulator unchanged. The worker, the two-replay FCEUX
queue snapshots, the normal NMI writes, and the renderer now agree on packet
`07 21 23 AA 46 4C 55 00 33 AB`. The previous `$D2/$D8/$E1` result came from an
incorrect interpretation of the relative branch target. This correction now
also replaces the stale `+$8C` arithmetic in the offline descriptor packet
source and manifest; the ROM does not produce `$D2/$D8/$E1` for these inputs.
The recorded FCEUX queue snapshot in
[`first_command_field_producer_input_trace_20261107_055431_utc/queue_consumer_entries.csv`](../../diagnostics/first_command_field_producer_input_trace_20261107_055431_utc/queue_consumer_entries.csv)
contains the raw away-team packet bytes. No new FCEUX run was performed.

Source bytes and per-resource hashes are recorded in
[`field_entry_window_01/manifest.json`](field_entry_window_01/manifest.json).
The latest muted active-route trace and its limits are recorded in
[`fresh_field_entry_cross_correlation_20261107.md`](fresh_field_entry_cross_correlation_20261107.md)
and [`field_entry_window_01_descriptor_trace_addendum_20261029.md`](field_entry_window_01_descriptor_trace_addendum_20261029.md).

The focused worker/NMI/render check validates the source identity path, packet
contents, secondary-queue handoff, normal-NMI address/data writes, and renderer
retention. No FCEUX run was performed for this check.

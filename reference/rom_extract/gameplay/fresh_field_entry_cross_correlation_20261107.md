# Fresh field-entry cross-correlation

## Result

The same-input Godot source projection and muted FCEUX now agree that the
scenario-$36 handoff enters fixed-bank `$E0DF` at source frame 8782. This
resolves the earlier FCEUX cross-correlation gap. It does not establish
sub-frame parity or prove that Godot renders the resulting field.

FCEUX then calls the ROM renderer path from `$E0DF`: `$EF7F` at frame 8782,
followed by bank-$18 `$800C` and `$8851`. The route reaches `$E233` at frame 8789,
then `$E145` at frame 8844 and begins `$E349` input polling at frame 8845. The
trace records 44 `$E349` entries through frame 8893. These are source execution
events, not a visible-output or first-command-menu confirmation.

## Trace setup and repeat check

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Recorded post-title input SHA-256: `87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`.
- FCEUX 2.7.0, NTSC/NewPPU, muted (`--sound 0 --volume 0`, dummy audio driver).
- Replayed source frames 8400–9042 twice from an in-memory save state at frame
  8399. Each reload matched the checkpoint's frame/cycle, 2 KiB CPU RAM,
  16 KiB PPU memory, MMC3 registers, and mapped PRG bytes.
- The runner verified both passes have identical recorded source-hook events,
  frame edges, PPU packet-RAM writes, and packet-buffer start/end contents.
- Latest trace output: [`first_command_field_producer_input_trace_20261107_055431_utc/`](../../diagnostics/first_command_field_producer_input_trace_20261107_055431_utc/).
  The direct execution rows are in `source_entry_hooks.csv` and
  `source_entry_hooks_repeat.csv`.

The follow-up capture watches both worker counter `$05C5` and formatter input
`$003C`. At `$8C55`, frame 8464 records `($05C5,$003C)=($00,$01)` then
`($01,$00)`; frame 8465 records `($02,$01)` then `($03,$00)`. The same pairs
recur at frames 8786/8787. These are the initial formatting pass and subsequent
row-commit pass for descriptor progress 1 and 3. The queue packet snapshots
contain `$33` in both committed `$EE` rows:
`07 E1 22 AA DF CD DB 00 33 AB` and
`07 21 23 AA D2 D8 E1 00 33 AB`. This confirms the row-commit values and
outputs reported in
[`field_entry_window_01_descriptor_source_20261029.md`](field_entry_window_01_descriptor_source_20261029.md).
Two checkpoint replays match after normalizing the pass column across source
hooks, descriptor input writes, packet events, queue entries, frame edges, and
coordinate-pointer traces. FCEUX returned `-11` while shutting down after
writing complete outputs; the runner validated both captures and reported
success. This trace establishes source packet production, not visible field
rendering or production Godot integration.

## Aligned events

| Entry | Source frame | Cycles from frame start | PRG bank | Selected source state |
| --- | ---: | ---: | ---: | --- |
| `$DAAA` | 8460 | 24666 | `$1E` | Match setup begins. |
| `$E0DF` | 8782 | 11239 | `$1F` | `$05CD=$80`, `$05CE=$A0`; scenario bytes `$0034/$0035=$48/$03`. |
| `$EF7F` | 8782 | 11247 | `$1F` | Renderer call follows `$E0DF` by 8 CPU cycles. |
| `$800C` | 8782 | 11340 | `$18` | Bank-$18 descriptor renderer entry. |
| `$8851` | 8782 | 11342 | `$18` | Renderer body follows `$800C` by 2 CPU cycles. |
| `$E233` | 8789 | 12695 | `$1F` | Starts scenario `$1E` field animation/setup. |
| `$E145` | 8844 | 22221 | `$1F` | Field loop entry. |
| `$E349` | 8845 | 20900 | `$1F` | Input-polling entry; 44 calls through frame 8893. |

The direct hooks also record 19 `$8B2F` and 28 `$8C55` executions in the traced
window. This corrects the earlier report of no handler calls: the older trace
did not hook these addresses directly, so its negative result was not evidence
that the routines did not execute.

The recorded-input Godot route executes the ROM `$E0DF LDA #$00; JSR $EF7F`
call and its fixed-bank mapper wrapper through bank-$18 `$800C`, then runs the
descriptor-$00 `$8851` worker through `$8886->$C515->$CB0F` at frame 8782. The
route adopts the worker's seven RAM writes in source order, validates its
existing JSR stack frame, saves slot `$05` as `$01 $46 $18 $19`, and performs
the post-yield scheduler scan; the scan selects slot `$09`. The recorded-route
verifier passes these source-state checks. This execution is ROM-byte-driven,
not endpoint injection.

The accepted FCEUX trace records `$E0DF`, `$EF7F`, `$800C`, and `$8851` in frame
8782, at 11,239, 11,247, 11,340, and 11,342 cycles into that frame. It records
the later field loop at `$E145/$E349`, but does not hook `$C515` for this
descriptor call. The trace script now has that hook; a rerun stalled during
warmup at frame 0 and was terminated by its no-progress guard, so it produced
no new accepted evidence. A direct event-time comparison for the worker save
is still needed. Godot has no cycle-accurate CPU phase, and the captured field
background remains black.

The existing isolated `$800C->$8851->$C515` worker executor currently accepts
the earlier fresh-match entry state (`A/X/Y/P=$00/$00/$00/$23`). This
scenario-$36 descriptor call enters with `A/X/Y/P=$00/$50/$00/$33` from the
verified wrapper and FCEUX hook. Do not reuse that executor on this route until
its input contract and the resulting branch/write stream are source-checked for
this entry variant.

## Pattern-table writes

The ROM header has 16 8-KiB CHR units and mapper 4; the runtime renderer loads
the matching 131,072-byte CHR-ROM extract and verifies its SHA-256. Therefore
`$2007` writes targeting `$0000-$1FFF` do not mutate the pattern data; MMC3
bank selectors determine which ROM bytes are read. The Godot PPU event applier
now ignores these writes only when that verified CHR-ROM is loaded, still
advances the PPU address, and reports an ignored-write count. Other cartridges
without verified CHR-ROM continue to report the pattern-table operation as
unapplied. The source-route verifier checks this read-only behavior.

This corrects PPU bus semantics; it does not supply the active field's source
CHR selectors, nametable/attribute state, scroll/raster schedule, or actors.
The same-input Godot route now completes the source worker's `$CB0F` save and
selects slot `$09`, but still captures a black background. These corrected bus
semantics do not establish visible field rendering.

## Remaining work

- Continue the selected slot-$09 route into the field PPU queue and connect
  both descriptor renderers and scenario `$1E` setup to the production field
  renderer. Descriptor `$01` ED/EE packet substitution is modeled and
  focused-verified, but not consumed by the live renderer; full-pitch/CHR/
  palette/raster setup and visible field composition remain open.
- The latest replay adopts the slot-$09 scenario-$36 decrement (`$0519=$26->$25`)
  and selects slot `$11` at frame 8783. It then stops before the slot-$11 actor
  worker can reach its `$CB0F` yield: live record `00 C6 18 19`, stream
  `$A439`, animation `$A2B2`, `A/X/Y=$04/$04/$04`, stack `$C7:$CB=04 04 49 80`,
  and RAM `$E3:$EB=00 00 0E 0E 02 02 00 75` do not match a verified saved
  continuation context. The next task is to reconcile this dispatch with the
  bank-$19 actor stream and accepted FCEUX task events; do not weaken the
  context contract without source evidence.
- Compare same-input visible field output and continue the route to the initial
  command menu, including its unselected cursor and keyboard/controller input.
- Compare route audio and verify a packaged build without ROM/emulator or
  diagnostic files. No exact-fidelity claim is supported yet.


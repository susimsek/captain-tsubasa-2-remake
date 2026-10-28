# First-command combined scheduler, scenario, and actor trace — 2026-10-28

## Scope and reproducibility

This muted FCEUX trace combines the previously separate scheduler/callback and
actor-writer hooks. It starts from power-on once, saves an anonymous
in-memory checkpoint at source frame 8399, verifies frame/cycle, all 2 KiB RAM,
all 16 KiB PPU memory, MMC3 registers, PRG mapping, and mapped bytes after each
restore, then replays source frames 8400–8953 twice. It does not use numbered
save slots. ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`; opening
and route-input hashes match the previously retained trace timelines. FCEUX
2.7.0 ran NTSC/NewPPU with sound and volume set to zero and SDL audio routed to
the dummy driver.

Trace files are under
[`first_command_combined_state_20261028_064035_utc/`](../../diagnostics/first_command_combined_state_20261028_064035_utc/).
Both passes produced 33,011 ordered execution events and 61,473 watched writes.
After omitting only the pass label, event and write CSVs had identical hashes
(`f36bab1e…a13af0` and `5db2537b…49031e0` respectively); the validation JSON
records their full hashes. The checkpoint was frame 8399 at cycle 250126423.
FCEUX exited 0 after writing complete outputs. Captures remain diagnostics,
not runtime resources.

## New bounded source observation: field-loop caller window

The fixed-bank `$E145` field-loop entry was observed 22 times: once at frame
8844, every frame 8845–8855, and every frame 8882–8892. Its `$E14D` eligible
iteration was observed 21 times: every frame 8845–8855 and every frame
8883–8892. Each `$E14D` call was in the fixed bank, with A=`$00`; no `$E14D`
call was observed at the frame-8844 entry or after the recorded B press at
frame 8893 in this route window.

This supplies the exact source-frame call windows missing from the earlier
field-loop audit. It does not identify why `$E145` is absent during
8856–8881, prove the stamina countdown effects, or define an arbitrary
reusable cadence. This trace did not watch `$0614/$0618` or hook `$E1F7/$E2BC`;
the existing ROM rule remains that the caller decides when `$E14D` is
eligible, B is checked first, and only a timer-expiry path calls the stamina
helpers. Treat the event windows as a validation target for a future source
caller model, not as frame constants.

## Cross-checks and remaining boundary

The combined trace also reobserved the known source paths: one `$EE9F` actor
loop and bank-`$14:$800F` animation tick per source frame in frames 8461–8953;
the same eight `$EC94` wait loads; eight `$C50F` callback task starts; and
the root `$FB` depth transition `$00 → $FE → $00` for the four fresh-route
scenario streams. These results agree with the focused actor, scheduler, and
continuation notes linked from `GOAL.md`; they do not add a route-integrated
Godot scheduler.

This pass did not hook bank `$18` `$8852/$88B9`, the `$D575/$D5C3` first-panel
queue path, or writes to `$0515/$05C5/$05C6`. It therefore says nothing new
about the pre-queue wait or panel transfer batches. The source task graph,
actor state producer, field caller, first-menu composition, and full route
audio remain separate integration work.

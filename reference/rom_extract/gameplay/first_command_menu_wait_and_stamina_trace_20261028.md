# First command-menu wait and stamina trace — 2026-10-28

## Capture and replay validation

This muted FCEUX trace extends the combined route trace with the menu dispatch,
renderer queue, and stamina hooks. It uses the supplied Turkish ROM
(`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`),
FCEUX 2.7.0 NTSC/NewPPU, and the existing opening plus post-title input
timelines. The Lua run warms from power-on once, stores an anonymous in-memory
checkpoint at frame 8399, verifies RAM, PPU, MMC3, PRG mapping and mapped bytes
after both restores, then replays frames 8400–8953 twice. Audio was muted; no
numbered save slot was used.

Run command:

```text
python3 tools/diagnostics/run_first_command_menu_stamina_trace.py
```

The successful run took 18.888 seconds and is preserved under
[`first_command_menu_stamina_20261028_064701_utc/`](../../diagnostics/first_command_menu_stamina_20261028_064701_utc/).
Both passes have 7,027 events and 78,847 writes. After removing the pass-label
column, the event hash is
`15fe39c27a8d0ea3f8f7586bc25d595cb44d15212eb0c13f4a5fcca444640508` and the
write hash is
`1d7ee82dcbf64ef2955dc98d1f73dbb49d0e33543210cd7bc476a0f54c27244d`.
The 112-byte queue snapshots at the start and end of the two passes also match
pairwise. Full counts, hashes, and command metadata are in `validation.json`
and `metadata.txt` in that directory. These are diagnostic captures, not
runtime data.

## Menu wait and row queue

The same-input route presses B at source frame 8893. Fixed-bank `$D575` is
entered at frame 8908 (cycle-in-frame 23602, bank `$1E`), followed by `$D5C3`
at frame 8926 (cycle-in-frame 12729, bank `$1E`). Both snapshots are in the
`menu_stamina_events.csv` event rows, including task slots, scenario pointer,
continuation payload, registers, and the `$04A5–$0514` queue.

The bank-`$18` renderer starts descriptor `$02` at frame 8935 (`$8852`, A=2),
then starts descriptor `$03` at frame 8938 (`$8852`, A=3). The first regular
row packet is present in the `$88B9` queue snapshot at frame 8936. Counting
source frames inclusively from B at 8893 through that packet at 8936 gives 44
frames (43 frame boundaries). The `$0515/$05C5/$05C6` snapshots then show nine
queue cycles: three for descriptor `$02` on frames 8936–8938 and six for
descriptor `$03` on frames 8939–8944. Progress advances by two rows per cycle.
Descriptor `$03` ends at inclusive progress row 10, so its last cycle emits
that final row without a second row. This confirms the route's observed wait
and queue progression; it is not a universal frame-delay rule. The panel's
first fully sampled image remains frame 8953, so these queue events do not
establish the exact first visible pixel.

## Stamina-loop observation

The trace records `$0614=10` initialization at frame 8842. `$E145` entries
occur at frames 8844–8854 and 8882–8892; eligible `$E14D` entries occur at
8845–8855 and 8883–8892. The first countdown reaches zero and reloads to 10
at frame 8855. `$E1F7 → $E2BC` is observed once, at frame 8858. During that
call `$0618` changes `$00 → $01 → $00`, as recorded by its write-watch rows.

The second countdown reaches zero at frame 8892. B is processed on frame 8893
before another `$E14D` entry, so this route enters the command-menu transition
without a second `$E1F7/$E2BC` call. The trace confirms those call windows and
the B-preemption point for this input sequence. It does not exercise a
`$0618=$FF` wrap case or establish a general stamina-update cadence. The trace
also does not watch the player-stat record writes; use ROM-derived source
calculations and their separate validation for numeric stamina values.

## Limits

The register/PC hooks and RAM writes repeat byte-for-byte across the two
checkpointed passes. They verify this emulator/input route and expose the
renderer handoff, but do not prove Godot integration, physical NES timing, or
the menu's first-pixel scanout. No production runtime files were changed.

# Scenario `$1E` Callback `$45` and Map `$36` Queue Yield

## Result

The recorded-input Godot route enters scenario `$1E` callback `$45`, selects map `$36` with selector `$01`, and generates its first six metatiles from hash-verified ROM-derived map sources. Each batch contains three metatiles and a 96-byte secondary queue.

At source frame 8793, the caller-confirmed normal NMI consumes the previous batch: 15 packets are transferred, `$0515` changes from `$80` to `$00`, and the runtime PPU renderer applies 51 nametable writes with no unrepresented writes. The route then generates map indices 3–5 (`$2B,$EE,$2B`), saves the second 96-byte queue, and waits at the next normal-NMI boundary. This proves queue and renderer-path execution in the Godot route; it does not prove same-frame FCEUX RAM/PPU equality or complete visible field composition.

## ROM source

- The bank-`$0B` callback table at CPU `$8880` contains `$45 -> $8A2A` and `$46 -> $8A2D`. The bounded stream at `$8A2A` is `06 00 36`: handler `$06` receives map ID `$36`. Extracted bytes and hashes are recorded in [callback dispatch manifest](first_command_field/callback_dispatch/manifest.json).
- The ROM map-source manifest resolves map `$36` to selector `$01`, block map CPU `$9224`, file offset `$017234`, and a 32-byte map. The first six metatile IDs are `$2B,$2B,$2B,$2B,$EE,$2B`. ROM-derived metatile tile and attribute records are listed in [page-correct map sources](first_command_field/page_correct_map_sources/manifest.json).
- The map worker setup at `$875A` reads CHR pair `$00/$3C`. The matching source bytes are in [map worker manifest](first_command_field/map_worker_8525/manifest.json).
- The shared map worker checks `$0515` before row expansion. If the queue is busy it reaches the `$856F` yield/call boundary without changing the map cursor. After normal NMI drains the queue, the worker emits three metatile records, saves the queue, and yields again.

## Recorded route boundaries

- Frame 8791: slot `$15` reaches PC `$CB0F` with task record `00 E9 0B 0C`, banks `$0B/$0C`; selector `$01`, map `$36`, placement `$80`, and 32 cells remaining. `$0515=$80` gates the worker. Map pointer `$9224` is source-checked.
- Frame 8792: the worker produces the first three metatiles (`$2B,$2B,$2B`) and a 96-byte queue, then yields.
- Frame 8793: normal NMI transfers that prior queue as 15 packets, clears `$0515`, and returns 96 ordered PPU bus events. The live renderer applies 51 nametable writes with zero unrepresented writes. The resumed map worker produces the second three metatiles (`$2B,$EE,$2B`) and another 96-byte queue; its output cursor is `$05C7-$05C9 = $60,$86,$1A`.

These are Godot route-state and production-renderer results, not direct FCEUX RAM snapshots or claims about physical NES sub-frame timing. PPU application is established, but the resulting field image has not been compared against FCEUX at the same input/frame.

## Verification

- `godot --headless --path . --check-only --script tools/diagnostics/verify_kickoff_recorded_input_path.gd` — passed after adding the map `$36` PPU queue assertion.
- `CT2_ROUTE_FINAL_FRAME=8793 godot --headless --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd` — passed; the focused verifier checks both the second map batch and the preceding NMI transfer/renderer result.

Remaining work: consume the second queue and finish map `$36` expansion, establish complete field PPU/CHR/palette/scroll/raster and actor state, reach and operate the first command menu, compare same-input visible/audio behavior and timing, and verify a packaged ROM/emulator-free runtime.

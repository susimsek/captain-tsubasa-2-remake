# Slot-$01 field-marker renderer and frame-8855 route boundary — 2026-11-08

## Source-backed marker path

The recorded-input Godot route at frame 8843 enters the live slot-$01 `$EE9F` actor loop with `$062D=$80`. The ROM's `$062D.7` branch calls `$8009->$8624`; the source-derived renderer visits the marker records, updates the OAM shadow and counters, and returns through `$EF57` to the `$CA55` caller boundary. Its extracted bytes and provenance are listed in [`ee9f_actor_init_80/manifest.json`](ee9f_actor_init_80/manifest.json), and the production consumer is `scripts/gameplay/rom_ee9f_actor_init_80_executor.gd`.

The returned CPU status has known mask `$E3` and value `$23`; the required source-relevant bits `$C3` equal `$03`. The `$E3CA` caller validation now requires those bits while permitting additional known status bits. The live route then advances to frame 8844. This proves the source path was traversed by the Godot route; it does not prove same-frame marker coordinates or pixels match FCEUX.

## Current worker boundary

The latest full recorded-input Godot route reaches frame 8855. The live slot-$05 dispatcher resumes at fixed-bank `$E14A`; it executes the `$E349` field loop and its ROM-derived setup path, then reaches a bank-$1E read boundary at CPU `$D193`. The attempt is preserved as `slot05_worker_result` on the route's rejected transition so the actual CPU, mapper, RAM, stack, calls, and instruction history remain inspectable.

The source boundary is `unresolved_source_span` at `$D193`, bank `$1E`, file offset `0x03D1A3`. The worker reports A/X/Y/P/SP `$01/$01/$AC/$20/$4E`, MMC3 banks `$1C/$1D`, and the real return word `$E1F0` on the stack (`F0 E1`). The incoming worker checkpoint was produced by ordinary recorded-input execution at `$E14A` with `$0614=0`; the worker then stopped at `$D193`. Its source-dispatch proof, ROM hash, input-trace hash, RAM/stack lengths and hashes, and mirrored stack bytes were checked. This is a temporary diagnostic checkpoint only; it is not used by game runtime and contains no FCEUX RAM seed.

ROM inspection identifies the `$E1E7-$E1F0` caller and a candidate `$D193-$D299` callee span. The normal callee path updates the fresh clock and then calls `$EF7F`; that call may yield through the bank-$18 descriptor worker, so reaching `$E1F1` requires the real wrapper/scheduler continuation. The callee has not yet been added to the production source package, and the async continuation is not yet implemented.

The full recorded-input verifier remains incomplete:

`godot --headless --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd`

It exits 1 at frame 8855 on the unresolved `$D193` span, before the first command menu. The ROM-derived source route stops there; no endpoint state or FCEUX memory is injected.

## Status update — 9 November 2026

The 8 November attempt above is historical. The later full recorded-input
verifier now reaches the first command menu at `$D5EA`, frame 8953, through the
current bounded route model. That endpoint result does not establish the
clock-tick callback's return to `$E1F1` or execution of `$E1F7->$E2BC` in the
live player-state provider: the Godot menu still shows energy 400, while the
same-input FCEUX endpoint shows 397. The D193 worker's `$CB0F` handoff and its
source-ordered scheduler path remain distinct from the missing provider event.
See the refreshed [visible-output comparison report](first_menu_visible_output_comparison_boundary_20261028.md)
and [player-state source report](first_command_player_state_source_20261027.md)
for the current endpoint evidence and stamina rule.

## Remaining fidelity limits

The marker path has not yet been compared against same-input FCEUX OAM/pixels. The remaining items in this dated section are historical and have since been closed; see the superseding status below.

## Superseding route status — 10 November 2026

The earlier worker-boundary statements above are historical. The current
recorded-input production route resumes the async `$D193` path, returns through
the ROM-derived `$E1F1->$E1F7->$E2BC` update, and reaches the unselected first
command menu. At frame 8863, all eleven live player records match the
same-input FCEUX RAM snapshot byte for byte. This stamina result does not
remove the separate physical PPU-phase limit. See the focused
[stamina parity report](first_match_stamina_live_route_parity_20261110.md).

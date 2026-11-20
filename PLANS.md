# Implementation Plan

GOALS.md owns the outcome and acceptance criteria. This file tracks the current work package and the next source-backed steps.

## Active work package — first confirmed action

The fresh-start route already reaches the initial unselected command menu. Extend that live route by one confirmed soccer action, using the narrowest existing ROM/FCEUX trace and source implementation path that reaches the next player decision boundary.

1. [x] Audit available same-ROM input movies/traces after the initial menu. Pick one confirmed action and pin the exact input, ROM hash, checkpoint, and source frame convention. The selected route is PASS; see the first PASS action trace report.
2. [x] Trace PASS through the next ROM-polled decision boundary. The capture shows the new holder `$0A` at `$D5EA` from frame 9600 onward; `$D638` is polled every frame through 10072. The frame-9600 and frame-10072 PPU/screenshots are byte-identical, and this trace records no scenario `$44` event. Do not treat 10072 as a distinct menu.
3. [x] Execute the recorded Left/A input through the ROM `$D5EA->$D632->$D67C->$E93D->$CB0F->$CAA5` bridge; adopt the real slot-$05 yield and scan to slot `$09`.
4. [x] Resume the source-selected `$E945` label-render task through the PASS label and action caller `$D6C7->$CB99->$D7E8`; execute the handler prefix and save at `$CB0F`.
5. [x] Parse scenario `$38` from the source stream and create/select its slot-$15 callback `$34` task; execute callback dispatch and map `$2D` setup from `$8525` to `$856F->$C515`.
6. [x] Resume the genuine map worker at `$8572`; expand all 32 map-$2D cells into 11 ROM-matched tile/attribute batches on the ordinary-input route (frames 9053–9063).
7. [x] Resolve the live `$CA55->$E3CA` animation-$00 caller branch. Focused recorded-input verification now reaches `$CA58` and its `$CA4F->$CB0F` yield.
8. [x] Resolve slot `$09` `$86F8` for the live scenario-$38 `$0516=$01` worker profile; the recorded route now continues through the E3CA return to the PASS receiver wait.
9. [x] Execute the descriptor-$0F route through `$D7ED->$EF7F($0F)->$E6EC->$D80C->$CB0F` and restore the first `$D80F` receiver wait on the ordinary-input route.
10. [ ] Recheck the known frame-9191 `$044E/$00E2` branch on the current ordinary-input route before changing it: the retained same-input trace has `$044E=2` and `$0523=$30->$38`; a previous Godot run had `$044E=1`. The ROM-derived `$E0AB->$8000->$A103` worker path is implemented, including `$A134: LSR $00E2`; verify the current route's live worker write and selector before adding code. Do not force selector 2 or `$B4B6`. See `reference/diagnostics/pass_receiver_waiter_boundaries_20261118_223525_utc/`, `reference/diagnostics/pass_receiver_waiter_boundaries_20261118_150940_utc/events.csv`, `reference/rom_extract/gameplay/pass_scenario_1c/source_audit.md`, and `tools/diagnostics/verify_scenario1c_f3_84_target_records.gd`.
11. [ ] Replay the ordinary same-input route through the frame-9496 `$82F2->$C515` packet wait and onward to the frame-9600 `$D5EA` input wait. The last full replay stopped at frame 9495 on missing actor-$6D index-02 `$A21A` span hashes; a strict actor-scoped hash fix passes its focused verifier but has not been replayed in the full route. Do not seed FCEUX RAM or skip source execution. Frame 9600 is the next player input wait, not a redrawn command menu. See `reference/diagnostics/pass_receiver_waiter_boundaries_20261119_231454_utc/events.csv` and `reference/rom_extract/gameplay/pass_receiver_waiter_boundaries_20261118.md`.
12. [ ] At frame 9600, compare same-input visible output, event timing, menu/input state, and ROM-derived audio; document unresolved gaps. Do not enter Continue or a second action.
13. [ ] Extend fresh-export verification to the completed route and confirm the package runs without the ROM, emulator, or diagnostic captures; retain the existing opening-to-menu acceptance checks.

## Evidence and implementation entry points

- Active route and first-menu input: `scripts/gameplay/kickoff_route_runtime.gd`, `scripts/gameplay/first_action_menu_input.gd`, and `scenes/kickoff_route_runtime.tscn`.
- Same-ROM first-menu evidence: `reference/rom_extract/gameplay/first_action_menu_input_rom_trace_20261027.md`, `reference/rom_extract/gameplay/kickoff_first_command_menu_trace_20261027.md`, and the pinned input/RAM/PPU data under `reference/diagnostics/kickoff_select_test_20261027/`.
- Same-ROM PASS action input, receiver selection, audio queue IDs, and next decision boundary: `reference/rom_extract/gameplay/first_pass_action_trace_20261110.md`.
- Existing command state and result leads: `reference/rom_extract/gameplay/first_command_live_player_opponent_state_audit_20261027.md`, `reference/rom_extract/gameplay/first_command_rng_source_execution_details_20261027.md`, and `reference/rom_extract/gameplay/first_command_scenario_event_continuation_audit_20261028.md`.
- Completed prior milestone evidence is linked from GOALS.md; read only the report sections needed for the selected action.

## Constraints

Use the supplied ROM and muted FCEUX traces as evidence. The primary agent owns the shared emulator and uses validated save/load checkpoints for repeated probes; subagents may inspect static ROM bytes and existing traces only. Runtime never reads FCEUX RAM, screenshots, or captured WAVs. Use the NES and Godot project skills, keep repository Markdown in English, and do not commit or publish unless asked.

## Completed supporting work

- Extracted and hash-pinned the scenario-$1C source package; extended the bytecode reader and task runtime with context-aware `$FD/$FA/$F2/$F3` handling plus live-pointer admission/safe-stop. `tools/diagnostics/verify_scenario1c_f3_84_target_records.gd` verifies both `$044E` branch targets and their ROM-derived `$B49E/$B4B6` records, including `$B4B6`'s `$0523=$38`; its reported limit is that it does not exercise the live slot-$09 callback/worker lifecycle. The production slot-$09 path still pins selector 1 / `$B49E`; integrating the same-input selector-2 / `$B4B6` branch, the `$FD $00` result, and its callback/worker route remains open.
- Added ROM-byte fixtures for the PASS receiver confirmation waiter through `$D70C->$CC46->$CC50` and a scheduler-owned callsite adoption path. The focused executor check passes; live repeated NMI resumes through `$CC53/$CCA3/$CCD1` remain unverified.

- The context-0 action direction table at `$D6E8` is now packaged from the pinned ROM and used by `FirstActionMenuInput`; it also exposes the host input as the NES `$001C/$001E` pad-mask source.
- The ordinary recorded-input route now executes the live action caller and scenario `$38` callback `$34`; the real scheduler-selected slot-$15 task reaches its map `$2D` `$8525->$856F->$C515` save/NMI-wait boundary at frame 9052. The initial row resume at `$8572` and its tile/attribute sources remain unimplemented.
- Focused source checks verify the callback `$34`/map `$2D` prefix, first block IDs `$00/$71/$72`, selector `$02`, CHR `$00/$02`, and map-data pointer `$9104`; the recorded-input verifier now checks the same source data on the production route.
- The `$3C` audio presenter now hands off to a ROM-generated source-context clip covering frames 8607–9600 and suppresses separate playback of its embedded `$66/$2B/$2C` events. Provenance/routing and source APU-write ordering are checked; extended-interval PCM parity is not.

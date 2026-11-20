# Project Goal: First Confirmed Match Action

**Status: ACTIVE.** Extend the verified fresh-start route beyond the initial command menu and resolve one confirmed soccer command through its first ROM-defined result and next player decision boundary.

## Scope

Start from the standalone KICK OFF route and its initial unselected command menu. Select and confirm one action supported by the supplied ROM and a same-ROM FCEUX trace. Continue through the action's source-owned state/result, transition scene, and visible/audio response to the next ROM-polled player decision boundary. Identify that boundary from the live input-wait loop and holder state; do not label it a rebuilt command menu unless the menu is actually redrawn. Stop before confirming a second soccer action, Continue, or later story routes.

Runtime visuals, text, audio, and state must come from verified ROM bytes and decoded behavior. The packaged game must run without the ROM, FCEUX, or validation captures. Emulator screenshots and captured WAV files are comparison evidence only.

## Acceptance criteria

- Choose the first practical action route from ROM/FCEUX evidence; record its input sequence, relevant source frames, ROM hash, mapper/bank context, and trace/checkpoint provenance.
- Ordinary input confirms exactly one command. Execute its source-derived handler, state updates, and result path without injecting trace RAM or guessed endpoint state.
- Reach the next ROM-defined player input-wait boundary after the action, with the new holder and result state established; document separately whether a command menu is visibly redrawn there. Do not confirm a second action or enter Continue.
- Render the action result and any text/audio from ROM-derived resources. Compare same-input output and event timing against FCEUX; document unresolved frame/cycle or physical-hardware limits.
- Verify the action selection, confirmation, result state, and fresh standalone package without ROM/emulator runtime dependencies.
- Preserve the completed opening-to-first-menu behavior.

## Completed baseline

The prior slice from title KICK OFF through the unselected first command menu is complete. Its frame-8953 endpoint matches all 57,344 visible 256×224 RGB pixels; the live stamina update matches all eleven same-input FCEUX player records; the production Godot route PCM matches 3,036,345 fixed 44.1 kHz samples through the menu endpoint; and a fresh PCK reaches and holds the menu without ROM, emulator, or capture files. See the [visible-output report](reference/rom_extract/gameplay/first_menu_visible_output_comparison_boundary_20261028.md), [stamina RAM parity report](reference/rom_extract/gameplay/first_match_stamina_live_route_parity_20261110.md), and [route audio report](reference/rom_extract/gameplay/first_match_audio_integration_boundary_20261028.md).

## Current progress

The same-input FCEUX trace confirms one PASS to holder `$0A` and the next player input wait at frame 9600; identical PPU output through frame 10072 shows no command-menu redraw. The last full ordinary-input Godot replay stopped at frame 9495 because actor-$6D index-02 `$A21A` span hashes were missing. A strict actor-scoped hash fix now passes its focused verifier, but has not yet been replayed through the full route; the frame-9496 `$82F2->$C515` packet-wait verifier remains isolated. The live `$D5EA` wait, Godot/FCEUX visible-output comparison, same-input PCM parity, and fresh ROM-independent PCK acceptance remain unproven. Frame 9600 is the next player input wait, not a redrawn command menu. See the [first PASS action trace](reference/rom_extract/gameplay/first_pass_action_trace_20261110.md), [frame-9474–9477 actor boundary audit](reference/rom_extract/gameplay/pass_receiver_waiter_boundaries_20261118.md), and [$6D actor stream manifest](reference/rom_extract/gameplay/slot11_actor_parameter_6d/manifest.json).

A same-input FCEUX trace shows `$044E=2` at frame 9191 and the bank-$10 reader changes `$0523` from `$30` to `$38`; ROM `$8259` maps selector 2 to `$B4B6`. The current Godot route has no same-frame `$044E/$00E2` snapshot, so keep this check open and do not force selector 2 or `$B4B6`. See the [scenario-$1C source audit](reference/rom_extract/gameplay/pass_scenario_1c/source_audit.md).

## Out of scope

The full match loop, opponent AI, campaign, second action, Continue/save flow, later story scenes, physical NES timing, and output-device sample phase are outside this milestone. Start another goal before extending beyond the first action result.

# Active Goal: KICK OFF to the First Match Command Menu

**Status: ACTIVE — incomplete.** This file contains the current goal, a concise
status summary, and completion criteria. Detailed history and measurement
records live in the reports under reference/. The previous long GOAL log is
preserved in [the archived progress log](reference/goal_progress_history_20261028.md).

## Goal and scope

Complete a standalone Godot 4 slice that starts with KICK OFF selected on the
title screen and reaches the first match command menu. No soccer action should
be selected when the menu first appears. Do not enter the CONTINUE flow or
confirm a soccer action.

The game must not require the ROM or an emulator at runtime. Visuals, text,
audio, and behavior must derive from the supplied ROM bytes and decoded game
logic. Emulator screenshots and captured WAV files are for observation and
comparison only.

## Desktop distribution scope

Keep the About and update flows for Windows, Linux, and macOS. Automatic update
checks must not download updates. Download and installation require an explicit
user choice and a writable destination. Use the correct package type for each
platform; release packages must include third-party notices and SHA-256/Sigstore
manifests. Desktop menus must not disrupt the 256×224 game display or gameplay
flow. Details are in the Godot skill's desktop/release reference and
.github/workflows/. This scope does not change the first-match milestone
endpoint.

## Current status — 28 October 2026

- The earlier slice from cold start through the title menu is complete. A
  same-input software comparison dated 2026-10-27 reported matches for
  4,693/4,693 visible frames and 3,442,925 audio samples. This compares Godot
  with FCEUX software output; it does not claim physical NES scanout or silicon
  timing.
- Several ROM-byte executors and traces exist for the fresh KICK OFF route, but
  they are not yet connected into a live task/event chain that runs the
  production route end to end. Current standalone checks do not prove that the
  first command menu is installed on the production route.
- Live player/receiver state, task continuation, field actors, and menu setup
  remain unresolved on the route to the first menu. Same-input visual, timing,
  and audio parity for the route has not been fully verified.
- The next source-tracing work and acceptance criteria are in the **Current
  work package** section of PLANS.md. Record each new finding in its source
  report; update this summary only when the status changes.

## Completion criteria

- Normal user input takes the ROM-derived route to the first command menu.
  Tests must not inject RAM or imitate unresolved transitions with frame delays.
- No action is selected when the first menu appears; observed keyboard and
  controller navigation works correctly. Do not open CONTINUE or confirm a
  soccer action.
- Compare visible output, menu selection, source-event order, timing, and audio
  under identical startup and input sequences. Document any remaining gaps.
- A clean Godot copy reaches the same endpoint without the ROM or FCEUX.

## Active evidence

- Source task/bootstrap and NMI:
  [first-command root-task bootstrap and NMI](reference/rom_extract/gameplay/first_command_root_task_bootstrap_and_nmi_20261028.md),
  [first-command task-boundary trace](reference/rom_extract/gameplay/first_command_task_boundary_trace_20261028.md)
- $C515/$CB0F continuation and production-route boundary:
  [callback scheduler trace](reference/rom_extract/gameplay/first_command_callback_scheduler_trace_20261028.md),
  [live-route composition boundary](reference/rom_extract/gameplay/first_command_live_route_composition_boundary_20261028.md)
- Field and first-menu visual gaps:
  [kickoff field-intro visual gap](reference/rom_extract/gameplay/kickoff_field_intro_visual_gap_20261028.md),
  [first-menu visible-output comparison boundary](reference/rom_extract/gameplay/first_menu_visible_output_comparison_boundary_20261028.md)
- Route audio:
  [first-match audio source](reference/rom_extract/gameplay/first_match_audio_source.md),
  [route cue 55 asset-onset audit](reference/diagnostics/audio/route_cue55_asset_onset_audit_20261027.md)
- Earlier opening-audio build and comparison:
  [opening-audio build and PCM validation](reference/rom_extract/audio/opening_audio_build_and_pcm_validation_20261027.md)
- External research sources and their limits:
  [online reverse-engineering resources](reference/rom_extract/intro/online_reverse_engineering_resources.md)

Use AGENTS.md for working rules and PLANS.md for work order. If this status
summary conflicts with a detailed report, update the status and relevant report
to reflect the newest evidence. Do not treat an old archived entry as current.

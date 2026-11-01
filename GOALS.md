# Active Goal: KICK OFF to the First Match Command Menu

**Status: ACTIVE — incomplete.** This file owns the objective, current state, and completion criteria. Detailed evidence remains in focused reports under reference/.

## Objective and scope

Build a standalone Godot 4 route from the title screen with KICK OFF selected through the first in-match command menu. The menu must appear with no soccer action selected. Do not enter CONTINUE or confirm an action.

Runtime visuals, text, audio, and behavior must derive from verified ROM bytes and decoded game logic. The shipped project must not need the ROM or an emulator. Emulator screenshots and captured WAV files are comparison evidence only.

## Acceptance criteria

- Ordinary user input follows the source-derived route to the first command menu; no test-only RAM injection or guessed transition delays.
- The initial menu has no action selected, and observed keyboard/controller navigation works.
- Same-input visible output, menu/input behavior, event order, timing, and audio are compared; unresolved gaps are documented.
- A clean packaged copy reaches this endpoint without the ROM, emulator, or diagnostic captures.
- Stop before confirming a soccer action or entering CONTINUE.

## Current state — 1 November 2026

- A focused integration verifier passes the recorded Select route through cleanup and the selector timeline, reaching the ROM-owned $893B wait at source frame 7266. The ID-2 Select waiter is also covered.
- This check is a route-integration result, not full visible-route parity. Production stops before reading $78: the live source-owned CPU/stack/RAM/mapper/PPU/MMC3 interrupt path does not yet produce the NMI/IRQ return.
- Several source-derived setup components and diagnostic executors exist, but later caller/field results are not connected to a production route. The Godot route does not reach the first command menu.
- The live field's complete CHR/palette/nametable/scroll/raster rendering, arbitrary-input RNG, route-audio parity, and clean runtime independence remain unverified.
- Do not treat a FCEUX endpoint, synthetic executor fixture, scheduled candidate event, or isolated verifier as proof of the complete game route.

## Focused evidence

- Current $893B wait and runtime gap: [source-clock report](reference/rom_extract/gameplay/fresh_kickoff_8920_source_clock_runtime_gap_20261029.md) and [selector/IRQ candidate](reference/rom_extract/gameplay/fresh_kickoff_selector_timing_and_irq_candidate_20261031.md).
- Caller after the wait: [post-wait caller evidence](reference/rom_extract/gameplay/fresh_match_postwait_caller_20261031.md).
- Field and menu boundary: [field PPU audit](reference/rom_extract/gameplay/field_ppu_baseline_transition_20261029.md) and [visible-output comparison boundary](reference/rom_extract/gameplay/first_menu_visible_output_comparison_boundary_20261028.md).
- Route audio: [audio source](reference/rom_extract/gameplay/first_match_audio_source.md) and [integration boundary](reference/rom_extract/gameplay/first_match_audio_integration_boundary_20261028.md).
- Historical progress is in the [archived progress index](reference/goal_progress_history_20261028.md); it is not the current status source.

## Standing project requirements

Maintain the existing About/update flows and release safeguards described in the Godot skill and .github/workflows/. These requirements do not extend the active gameplay endpoint.

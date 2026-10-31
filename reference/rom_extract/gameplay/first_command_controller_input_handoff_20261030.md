# First command route: controller input handoff

Date: 2026-10-30  
ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

## ROM behavior

The controller reader stores the held pad state at `$001C` and newly pressed
bits at `$001E`, using `($previous ^ current) & current`. The A and B held bits
are `$80` and `$40`. The decoded controller-reader evidence is in
[`eb_input_wait_trace.md`](../intro/eb_input_wait_trace.md). The recorded route
has a one-frame A press at source frame 8593 and a release at frame 8594 in
[`post_title_inputs.csv`](../../diagnostics/kickoff_select_test_20261027/post_title_inputs.csv).

The fresh-match wait at `$DAE2` tests `$001C & $C0`. With A held, it branches
to `$DAE9`, executes the ROM bytes `AD FB 05 18 69 08 8D 41 04`, and writes
`$0441 = $05FB + 8`. The next instruction is the byte-verified `JSR $DC07` at
`$DAF2` (`20 07 DC`). The two spans are preserved and hash-checked in the
[`fresh_daaa_continuation` source package](fresh_daaa_continuation/manifest.json).

## Godot integration

`RomGameplayTaskScheduler.sample_controller_input()` samples actual per-frame
button state and updates `$001C/$001E`. `RomFreshKickoffSourceRouteRunner`
refreshes the selected task snapshot after that input sample. The route no
longer swallows A/B input during source-task and NMI waits. The recorded-input
verifier dispatches both press and release events.

Under the recorded frame-8593 A press, the route reaches slot `$05` at `$DAF2`
with `$001C=$80`, `$001E=$80`, and `$0441=$08`. The route now executes the
ROM-derived `$DC07` initializer and stops at `$DAF5` with SP `$50`. The 22
position pairs match the diagnostic FCEUX RAM capture for the same recorded
frame. The test also confirms the frame-8594 A release is present in the input
event stream; that release is not consumed because the route stops at `$DAF5`.

## Verification

- `godot --headless --path . --script res://tools/diagnostics/verify_rom_fresh_daaa_wait_resume.gd` — passes zero-input yield and A/B input call-request cases.
- `CT2_ROUTE_EXPECT_DAF5=1 godot --headless --path . --script res://tools/diagnostics/verify_kickoff_recorded_input_path.gd` — passes the recorded frame-8593 A route through `$DAF2->$DC07->$DAF5`, checks the live return state, and compares all 22 position pairs to the frame-8593 FCEUX RAM oracle.

These checks do not establish receiver selection, scenario `$36`, field
rendering, command-menu output, audio parity, hardware source-cycle timing, or
complete-route parity.

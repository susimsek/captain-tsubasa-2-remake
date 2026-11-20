# Title KICK OFF fade and cutscene-worker entry — 1 Nov 2026

## Finding

The production Godot route now follows the ROM's initial KICK OFF handoff:

1. The title selection enters bank-$00 `$80E6`, which calls `$9BA0`.
2. `$9BA0` runs `$99F0` until `$004A/$004B` reach zero, then calls `$98A0`
   and `$9B7F` to clear PPU nametables and OAM state.
3. The caller dispatches cutscene ID `$01` through `$8464`; its `$98EA` setup
   writes `$55` to `$23E0-$23FF` before slot `$05` resumes at `$84C6/$84E7`.

The 1 Nov muted, two-pass FCEUX trace starts from a validated in-session frame
4692 checkpoint. It records 40,298 identical normalized hook events. At frame
4693, `$80E6` runs and the first `$99F0` palette step reaches `$9FA8` with
`$004A/$004B=$0E/$0E`. The 15 fade yields occur on frames 4693–4707. At frame
4708, `$8494/$9F69` install slot `$05`, `$84C6` restores SP `$50`, and `$84E7`
is entered twice in the same source frame. The trace output is diagnostics-only
under `reference/diagnostics/kickoff_task_context_20261101_104452_utc/`.

The initial full-brightness fade state is obtained from the live ROM-derived
opening presenter, whose title setup `$9A35` establishes `$004A/$004B=$0F`; its
32-byte palette comes from the ROM `$17` background and animation `$0D` sprite
palette. Godot executes the checked `$99F0` loop, stages each `$9A71` packet,
and commits it on the following modeled source tick. It then applies the
byte-checked `$98A0/$9B7F` clear and derives the `$23E0` seed by decoding the
checked `$8464->$84B0/$84BE->$98EA` bytes. Trace RAM, emulator images, and
captured audio are not runtime inputs.

The slot-$05 seed now decodes the worker entry context as well. `$8494` passes
bank-low `$00` to `$9F69`; the separate `$C5/$84` immediates are the return
address. `$9F69` decrements Y twice to `$4E` and stores the return bytes at
`$014F/$0150`. `$9F52` restores A/X/Y=`$4E`, SP=`$50`, and RTS enters `$84C6`;
the `$9F66 TAX` establishes known-clear N/Z flags. The receipt includes only
those two source-known stack bytes; it does not claim the other stack-page
values. Production route startup now checks this context before starting the
cutscene VM. This is a source-derived entry receipt, not proof of a complete
scheduler tick or same-frame CPU execution.

The route carries only `$9F5F`'s source write `$0024=$00` into its sparse RAM
ledger as the MMC3 register-6 shadow. This records one required value without
claiming to construct the earlier event-time NMI context. The two muted FCEUX
`$C421` RAM snapshots at frame 7266 both contain `$0024=$00`; this is
validation evidence for the source-derived value, not a runtime input.

## Verification

`godot --headless --path . --script tools/diagnostics/verify_main_opening_title_handoff.gd`
passes. It checks the production title input, frame-4693 palette against the
same-input FCEUX PPU state, the next-frame palette commit, 15 source fade
yields, slot-$05 worker startup at frame 4708, and all PPU bytes
`$2000-$27FF` plus the `$3F00-$3F1F` palette against the frame-4708 FCEUX PPU
state. `verify_rom_fresh_kickoff_cutscene_worker_seed.gd` checks the worker
register and stack-byte receipt, while `verify_kickoff_recorded_input_path.gd`
confirms the route still stops at projected `$893B`. These checks stop before
any soccer action and do not claim hardware timing.

## Remaining gaps

- The fade and worker route use source-frame ticks; CPU cycles, NMI/IRQ phase,
  and within-frame PPU output are not executed.
- The worker entry receipt derives the restored CPU state from checked ROM
  bytes, but the production route does not run the full scheduler dispatch or
  preserve a fully known physical stack page.
- The two `$84E7` entries at frame 4708 are observed in the trace; complete
  same-frame CPU/task execution parity is not established by the Godot check.
- Cutscene visuals/audio after worker release, the match setup, first field,
  and initial command menu remain unfinished. Overall route fidelity and
  runtime independence at the requested endpoint are not yet verified.

## Sources

- [`title_menu_source_trace.md`](../intro/title_menu_source_trace.md) — `$9A35`
  title palette and brightness initialization.
- [`cutscene_boot_task_install_trace.md`](../intro/cutscene_boot_task_install_trace.md)
  — `$8464`, `$98EA`, and slot-$05 worker installation behavior.
- [`select_to_fresh_match_handoff_gap_20261031.md`](select_to_fresh_match_handoff_gap_20261031.md)
  — downstream Select/caller boundary.

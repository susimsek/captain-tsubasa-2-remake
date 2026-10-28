# Isolated NTSC PPU vblank/NMI clock model — 2026-10-28

## Implemented boundary

`scripts/gameplay/rom_ntsc_ppu_vblank_nmi_clock.gd` is a reusable, isolated
RP2C02 timing component. It advances explicit PPU dots (or exactly three dots
per supplied NTSC CPU cycle), sets vblank at scanline 241 dot 1, clears the
status flags at pre-render scanline 261 dot 1, applies the `$2002` read clear
and vblank race, gates the NMI request through `$2000.7`, and models the
two-dot delayed PPU output. `$2001` render-enable writes take effect after
three dots; an odd frame skips pre-render dot 340 when either background or
sprites are enabled.

The component reports PPU output-line transitions. It does **not** run a CPU,
sample the 6502 NMI interrupt boundary, execute the game's `$C76E` handler,
produce `$001B.7`, run task bodies, or call `RomGameplayTaskScheduler`. The
caller must supply exact PPU register write positions and cycle advancement.
The production `KickoffRouteRuntime` has no CPU/cycle event runner that can
supply those inputs, so this source-clocked model is not connected to the live
route and does not yet produce its gameplay scheduler's NMI-ready deliveries.

Focused checks are in
[`verify_rom_ntsc_ppu_vblank_nmi_clock.gd`](../../../tools/diagnostics/verify_rom_ntsc_ppu_vblank_nmi_clock.gd).
Run with Godot 4.7.2:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_rom_ntsc_ppu_vblank_nmi_clock.gd
```

The verifier checks dot/cycle advancement, the two-dot NMI output, `$2000.7`
enable/disable, `$2002` read and suppression cases, status/toggle clearing,
three-dot render-mask delay, NTSC frame length, and odd-frame skip behavior.
Passing these component checks establishes only the implemented timing rules;
it does not establish timing for the supplied ROM's live route.

## Route trace boundary

The CPU-write evidence remains the two-pass file
`reference/diagnostics/first_command_task_boundary_20261028_070655_utc/task_writes.csv`
and its `_repeat.csv` counterpart:

- Sequence/row 2674 in each pass: source frame 8459, cycle 15,563, PC after
  store `$98D9`, `$0020: $08→$88`.
- Sequence/row 2715 in each pass: source frame 8459, cycle 20,739, PC after
  store `$A2C1`, `$0020: $88→$08`.
- Neither pass has an `$001B` ready-writer row on frame 8459. The adjacent
  normal interval instead has frame 8461 row 2936 (`$C7F0`, ready set, cycle
  1,819) and row 2939 (`$CAB6`, ready consume, cycle 1,913).

Those task-write rows report CPU cycle and PC, not PPU beam position or an
NMI-pending edge. The independent retained PPU/MMC3 trace
`reference/diagnostics/first_command_ppu_bus_trace_20261027_181102_utc/`
contains 92,992 PPU/MMC3 bus-event rows and 554 frame-edge rows per pass, but
the `ppu_scanline` and `ppu_dot` fields in every bus row are `-1`; the
`ppu_scanline_end` and `ppu_dot_end` fields in every frame-edge row are also
`-1`. It records CPU PPU-register writes and frame-cycle bounds, not dot-level
vblank/NMI assertions. Therefore it cannot supply initial beam phase or prove
whether the frame-8459 `$08→$88` write occurred during vblank.

Do not derive route cadence from frame numbers or inject trace snapshots into
the clock. Until an event runner or richer trace supplies the actual PPU phase,
`RomGameplayTaskScheduler` must keep NMI-ready delivery external. In
particular, this component does not resolve the frame-8459 gap.

## Technical references

- [NESdev: PPU frame timing](https://www.nesdev.org/wiki/PPU_frame_timing) — NTSC
  geometry, vblank flag edges, odd-frame skip, and `$2002` race cases.
- [NESdev: PPU registers](https://www.nesdev.org/wiki/PPU_registers) — `$2000.7`
  NMI gate, `$2002` side effects, and render-mask behavior.
- [Blargg: NTSC NES PPU VBL/NMI timing tests](https://github.com/christopherpow/nes-test-roms/blob/master/vbl_nmi_timing/readme.txt)
  — describes hardware-tested one-PPU-clock vblank, NMI-suppression, and
  odd/even frame tests.
- [rsemu RP2C02 dot-engine source](https://docs.rs/rsemu/latest/src/rsemu/dev/ppu/engine.rs.html)
  — an inspectable implementation reference for two-dot NMI output delay,
  `$2002` race handling, render-mask delay, and odd-frame skip. It is an
  implementation cross-check, not the game's source and not hardware proof.

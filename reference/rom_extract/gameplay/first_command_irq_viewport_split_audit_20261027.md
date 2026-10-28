# First-command viewport and IRQ split: source evidence and timing gap

## Scope

This note checks whether the first-command field can change its viewport after
the NMI scroll setup. It uses direct bytes from the supplied Turkish ROM and
the retained frame-8953 RAM/PPU snapshots only as state validation. The
2026-10-28 follow-up also uses the muted same-input FCEUX NewPPU register trace
and now supplies a line-level approximation to the Godot field candidate; it
does not claim the first affected pixel or physical 2C02 timing.

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Fixed-bank file mapping: CPU `$C000–$FFFF` maps to file `0x03C010–0x04000F`.
- Validation RAM: `reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008953.bin`.
- Validation PPU: `reference/diagnostics/kickoff_select_test_20261027/ppu/route_frame_008953.bin`.

## Frame-start scroll is source-defined

The fresh route's `$70` animation record at bank `$0B` `$8B38` (file
`0x016B48`) executes opcode `$06`, reaches `$83D2 → $8386 → $8393`, and calls
`$84A1` with `A=$A0`. `$84A1` (file `0x0164B1`) writes PPUCTRL shadow `$0020`
and scroll shadow `$004B=$74`; the details and byte path are in
[`first_command_field_background_producers_20261027.md`](first_command_field_background_producers_20261027.md).

At the endpoint, `$0020=$8A`, `$004A=$00`, `$004B=$74`, and `$0538=$00`.
Normal NMI code at `$C7AF–$C7C8` (file `0x03C7BF–0x03C7D8`) writes `$0020` to `$2000`,
then `$004A+$0538` and `$004B` to `$2005`. This explains the frame-start
page/scroll state. It does not establish that the same viewport remains active
for every scanline.

## The ROM has an enabled gameplay IRQ path that changes PPU address and scroll

The NMI body at `$C7D3–$C7E3` (file `0x03C7E3–0x03C7F3`) also programs the MMC3 scanline IRQ. It loads
`$C8F7,X` using `$008E` as the index, masks the value with `$7F`, writes it to
`$C000/$C001`, then loads `$0469` and writes `$E000,X`. At the endpoint
`$008E=$00`, so the ROM table byte `$C8F7=$FB` supplies IRQ latch value `$7B`
(123). `$0469=$01` addresses `$E001`, enabling the IRQ. The unmasked `$FB`
also has its high bit set; the IRQ helper later uses that sign as its branch
marker. Endpoint `$0021=$1E` is the PPU mask shadow written to `$2001`, not the
IRQ latch. The frame-end snapshot validates these state values; it does not
record the NMI instruction cycle for that particular frame.

The IRQ vector at file `0x03C510` jumps to `$C821` (file `0x03C831`). Its first
instructions are `BIT $001B; BVC +3; JMP $C478`. At the endpoint `$001B=$00`,
so the standard IRQ branch is selected. That branch preserves the interrupted
registers and calls `$C852`. The helper advances its table index from `$FF` to
zero and tests byte `$C8F7`; the target ROM byte there is `$FB`, so the negative
branch goes to `$C87C`.

That branch contains these PPU writes, in order:

1. `$2006=$22,$00` (VRAM address `$2200`).
2. `$2000 = $0020 & $FE`.
3. `$2005=$00,$00`.
4. MMC3 CHR register writes selected from `$0022`, `$0087`, `$0088`, and
   `$0089`.

The opcodes are in fixed-bank bytes `$C87C–$C8DF` (file
`0x03C88C–0x03C8EF`); the initial table entry `$FB` is at file `0x03C907`.
Therefore a source-controlled raster viewport/CHR reset exists. The NMI's
`$7B` latch and `$E001` enable make a mid-screen IRQ plausible for this route,
and its table marker selects the reset branch when that IRQ runs. A single
frame-end scroll value cannot describe the full raster.

## What this does not establish

The retained gameplay trace has frame-end PPU/RAM snapshots and selected PC
hooks, but it does not record the IRQ entry cycle, `$2006/$2005/$2000` writes,
PPU scanline/dot, or each CHR register write. The input-schedule replay also
does not include a gameplay PPU-bus event log. As a result, this audit cannot
prove the IRQ fired in the compared frame, identify its first affected pixel,
convert latch `$7B` into an exact FCEUX or physical NES scanline, or show that
it explains the lower-screen map residual. The `$7B` value is a source-derived
MMC3 latch, not a measured scanline number.

The candidate-render comparison's screenshot-guided `$2006=$2240` at scanline
134 is not supported by this source trace: the ROM path writes `$2200`. The
same-input FCEUX NewPPU probe now measures the `$2200` reload at line 124 and
the zero-scroll writes at line 125. `FirstMatchFieldCandidatePresenter` applies
those events to the scanline renderer at the measured line boundaries. This
is a row-level renderer approximation, not a claim about the exact first
affected pixel or physical NES output. The frame-start `$8A/$00/$74` state
must not be treated as a single viewport for the whole frame.

## Follow-up: same-input FCEUX IRQ and register-write timing

A muted FCEUX 2.7.0 NewPPU replay was later run from power-on through source
frame 8953 with the retained opening and post-title input timelines. It confirms
the IRQ and PPU writes in the same first-command route. The exact event log and
runner are under
[`reference/diagnostics/first_command_irq_viewport_20261027_164108_utc/`](../../diagnostics/first_command_irq_viewport_20261027_164108_utc/)
and `tools/diagnostics/trace_first_command_irq_viewport.lua`.

At frame 8953 the source-frame-relative CPU cycle measurements are:

| Event | Cycle from `emu.frameadvance()` start | Evidence |
| --- | ---: | --- |
| IRQ handler entry `$C821` | 16,360 | `irq_viewport_events.csv` |
| `$C852` helper entry | 16,409 | `irq_viewport_events.csv` |
| `$2006=$22` | 16,462 | `$C883` write callback |
| `$2006=$00` | 16,468 | `$C888` write callback |
| `$2000=$8A` | 16,477 | `$C88F` write callback |
| `$2005=$00,$00` | 16,487 / 16,491 | `$C897/$C89A` callbacks |
| IRQ disable/ack `$E000` | 16,560 | `$C8CF` write callback |

The same run records the subsequent MMC3 CHR selector/data writes for R0–R3,
completing by cycle 16,554. The endpoint sequence is therefore confirmed to
write `$2200` and reset scroll to zero. These are FCEUX CPU-cycle labels for the
same input replay; they are not a physical NES timing claim.

The script attempted `ppu.getscanline()` and `ppu.getdot()`, but both were
unavailable in the installed FCEUX 2.7.0 Lua interface and returned `-1`. The
official FCEUX Lua function list documents PPU memory reads and CPU cycle
counting, but no Lua scanline/dot getter ([function list](https://fceux.com/web/help/LuaFunctionsList.html)).
In pinned FCEUX source commit
[`a6d03e7968bd77a8156a7c9b628a673753f2f4c6`](https://github.com/TASEmulators/fceux/tree/a6d03e7968bd77a8156a7c9b628a673753f2f4c6),
`src/ppu.cpp` has internal NewPPU line/dot getters while
`src/lua-engine.cpp` does not bind them to Lua.
Consequently, this follow-up closes the missing CPU-side IRQ/register trace but
does not identify the corresponding PPU scanline/dot or first changed output
pixel. The screenshot-guided `$2240` / scanline-134 candidate remains
unsupported and stays out of runtime.

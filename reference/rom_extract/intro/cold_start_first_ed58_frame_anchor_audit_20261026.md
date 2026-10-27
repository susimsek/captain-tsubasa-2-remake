# First `$ED $58` frame and its remaining cold-start anchor

## Finding

The first cue's script and post-dispatch waits are mapped from supplied-ROM
bytes, and the current Godot presenter emits `$ED $58` at source frame 282
without reading the RAM capture as schedule input. Its **absolute** frame is
not yet independent of capture evidence: the presenter's earliest controlling
anchors are its modeled first ready-worker scan at frame 8 and first
NMI-ready release at frame 9 (`FIRST_READY_WORKER_SCAN_SOURCE_FRAME` and
`FIRST_NMI_RELEASE_SOURCE_FRAME` in
`scripts/opening/cold_start_source_command_presenter.gd`). The ROM has no
“wait eight frames” command. Frame 8 is an observed startup phase, not a ROM
constant.

## Byte-backed command and wait path

The supplied ROM is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Cutscene 0 is mapped from PRG bank 3 at `$A020` / file `0x006030`. Its relevant
bytes are:

```text
$A020  E8 01
$A022  F9 00
$A024  FB 01 8D
$A027  E9
$A028  DF
$A029  EA
$A02A  ED 58
```

The local ROM table at `$8AE6` gives `$DF` a 240-tick scheduler delay. `$E9`
calls `$9FA8(A=$02)` before its 15 one-tick `$997E` fade-up passes. `$EA` calls
`$99F0`, which decrements the two fade counters, stages a palette packet, and
yields once per `$01` pass until both counters reach zero. The source handler
then clears nametables and advances to `$ED $58`. These handler operations and
wait values are decoded from ROM; the corresponding frame sequence is
cross-checked in `cold_start_vector_handler_semantics.md`,
`e9_fade_up_trace.md`, `ea_fade/README.md`, and
`cold_start_scheduler_tick_trace.md`.

The same-input dispatch trace observes `$E8/$F9` at frame 8, `$FB/$E9` at 10,
`$DF` at 27, `$EA` at 267, and `$ED $58` at 282. At the frame-282 event the
presenter reports scheduler tick 274, slot `$05` active with delay zero, and
the previous yield as an EA palette step at frame 281 / tick 273. This
sequence is consistent with the ROM command path. The frame values are
validation observations; they are not a source event table used by the
presenter.

## Current Godot behavior and narrow check

`_ready()` installs task slot `$05` with the ROM's `$FF` ready sentinel. The
presenter then starts a modeled initial ready scan at frame 8 and releases
NMI-backed scheduler passes from frame 9 onward. The capture-free source-event
export was rerun to the opening boundary, with the RAM event list read only
after source execution as a comparison oracle:

```text
COLD_START_ED_EXPORT_OK ... source_ed=12 signal=12 capture_ram=4662 exact=true
```

The first emitted source event is frame 282, script `$A02A`, bytes `ED 58`,
sound ID `$58`; its comparison row matches the captured `$0700` event at frame
282. This check confirms the presenter's output and capture comparison. It
does not prove that frame 8/9 can be recovered from ROM execution alone.

## Cold-reset path traced in a separate muted FCEUX process

The earlier statement that the complete reset path was not traced is now
superseded by a focused instruction and bus trace. Two independent runs of the
same FCEUX 2.7.0 default-PPU process reproduced every listed reset/worker/NMI
cycle and both `$2002` vblank edges exactly:

- `reference/diagnostics/cold_start_reset_path_20261026_121525/`
- `reference/diagnostics/cold_start_reset_path_20261026_121611/`
- Script: `tools/diagnostics/trace_cold_start_reset_path.lua`

Both ran as separate offscreen processes with `SDL_AUDIODRIVER=dummy`,
`--sound 0 --volume 0 --no-config 1`. FCEUX auto-loaded the configured FM2
movie even though it was not passed on the command line; the script recorded
that state, stopped movie playback, called `emu.poweron()`, then drove frames
0–12 from `reference/opening_reference_capture/input_timeline.csv`. The user's
open FCEUX process was only read via `ps` and was not controlled. The ROM
payload MD5 and full ROM SHA match the project reference.

The first reset and startup events are:

| Source frame | CPU cycle | Event | Evidence |
|---:|---:|---|---|
| 1 | 2 | `$FFF0` reset stub | ROM bytes `A9 00 8D 00 80 4C 03 C5` |
| 1 | 12 | `$C503` | jumps to `$C64E` |
| 1 | 14 | `$C64E` PPU startup | `LDA #$08; STA $2000; SEI; CLD; LDX #$FF; TXS` |
| 3 | 59,572 | `$2002` read at `$C65B` returns `$88` | exits first `BPL` wait; preceding read at cycle 59,565 returned `$08` |
| 3 | 59,578 | `$2002` read at `$C660` returns `$08` | clears vblank flag; second `BPL` wait begins |
| 4 | 89,349 | `$2002` read at `$C660` returns `$88` | exits second vblank wait |
| 4 | 92,189–111,964 | `$C675` page increments | RAM clear advances one page every 2,825 CPU cycles |
| 7 | 199,901 | first `$9EED` scheduler scan | before the cold-start call at `$801F` |
| 7 | 199,959 | `$801F` cold-start entry | main task starts the cutscene setup |
| 8 | 223,681 / 223,683 | `$8024` / `$8464` | cutscene worker setup call and dispatcher |
| 8 | 223,781 | `$8494` installs `$A020` | `$004D/$004E=$A020`; mapped ROM byte is `$E8` |
| 8 | 223,807 | `$9F69` installs worker `$FF` ready value | slot `$05` is immediately schedulable |
| 8 | 224,280 | `$2000=$88` | cutscene setup enables PPU NMI before the next vblank |
| 8 | 224,328 | `$9FA8(A=$01)` | main task yields |
| 8 | 224,570 | first `$84E7` interpreter step | script pointer `$A020`, byte `$E8`; next step is `$A022` at cycle 225,284 |
| 9 | 238,264 | first `$C500` NMI entry | first observed NMI, 16 CPU cycles after the frame edge |

These observations explain the startup wait: `$C64E` contains **two**
`LDA $2002 / BPL` loops. The ROM does not wait a fixed eight frames. It waits
for two vblank assertions, while `$2000=$08` leaves NMI disabled during that
initial synchronization. The later `$2000=$88` write enables NMI; the first
NMI then arrives on the following vblank. The first worker dispatch at frame
8 is therefore reached by the ROM's reset work, RAM clear, main-task setup,
and cooperative yield, before the first NMI.

The two runs matched all selected CPU-cycle anchors and both `$2002=$88`
reads. The default FCEUX core does not expose PPU scanline/dot getters through
this Lua API (`ppu_timing_getters_available=false`), so the trace has no
independent scanline/dot coordinate. Its metadata also omits the live PPU-mode
variable. The `default-PPU` label is not proof of Old PPU: pinned SDL describes
`--no-config 1` as loading the default config without saving, and this
machine's `~/.fceux/fceux.cfg` sets `SDL.NewPPU=1`, which pinned SDL applies at
startup. The retained trace's status-read cycles agree with New PPU; mode
attribution is therefore supported by launch/config/source evidence and the
stepper comparison, but was not directly serialized by the capture.

A ROM/CPU/PPU source stepper now models the pinned FCEUX fixed-point scheduler
and both PPU paths without using captured cycle values as inputs. Its New PPU
run matches all 17,019 selected reset-path hook rows through the two startup
frames, then derives `$C685` at cycle 111,984 and `$4010=$00` / `$4017=$40`
writes at 111,988 / 111,994. These match the retained trace as final
validation. The corresponding conditional Old PPU calculation yields first
VBlank assertion at 59,677, `$C685` at 112,096, and the two writes at 112,100 /
112,106. The 59,675 value is the Old PPU's requested cycle budget; instruction
completion crosses it by two cycles. The earlier fitted 1,134-cycle wrapper
offset corresponds to New PPU; an equivalent Old PPU offset against the same
unadjusted wrapper schedule would be 1,246 cycles. Full method and pinned
source links are in
`reference/diagnostics/audio/old_ppu_poweron_phase_audit_20261026.md`.

One frame-index distinction should remain explicit during any future model
change: the literal first `$9EED` PC hit in FCEUX is source frame 7, before
worker slot `$0005` is installed; the main-task yield then enters a ready-worker
scan, and the first `$84E7` command dispatch is source frame 8. The presenter
labels that frame-8 event as its first ready-worker scan, not the first literal
`$9EED` hook. This distinguishes the two trace edges without changing the
presenter's frame-edge convention.

## Remaining blocker and model consequence

`$801F` calls `$8464` to install the cutscene worker and then `$9FA8(A=$01)` to
yield. `$9F69` writes `$FF` to `$0005`, which `$9EED` treats as ready on the
next scan after worker installation. The main-task yield therefore dispatches
the worker immediately; the earlier literal frame-7 scan occurred before slot
`$0005` was installed. The ROM does not encode a fixed eight-frame pause. The
new reset trace records the path through this handoff, including the first
`$84E7` dispatch at frame 8, cycle 224,570, and first NMI at frame 9, cycle
238,264.

The source stepper now continues past `$C685` through worker installation,
the first NMI, sound-driver call, MMC3 raster IRQs, and the first `$ED $58`
command. It derives worker installation at frame 8 / cycle 223,781, first NMI
at frame 9 / 238,264, `$C449 → $8000 → $C44C` at 240,180 / 240,182 / 241,033,
and the first `$ED $58` at frame 282 / cycle 8,393,008. The retained export
confirms the command frame and cue ID; it does not contain an `$84E7`
instruction-cycle hook, so that absolute `$ED` cycle is source-derived rather
than directly compared. The stepper also derives the first `$4015=$0F` at
frame 283 / cycle 8,400,582, matching the retained FCEUX callback exactly.
Its New-PPU scanline IRQ model reproduces retained `$C506` entries at cycles
255,169 and 284,952. Full method and evidence are in
`reference/diagnostics/audio/cold_start_source_cpu_ppu_stepper_extension_20261026.md`.

This resolves the source timing through the first sound enable for neutral
input; it does not transfer the stepper into Godot or establish the full
opening soundtrack. The retained run still supports New PPU, with the caveat
that its metadata did not serialize the live mode variable. The conditional
Old-PPU reset result remains an alternative. Do not change production audio
from these startup edges alone.

## Next missing model

The remaining work is to transfer the source-derived worker/NMI schedule into
the Godot presenter and verify it there. The retained FCEUX event capture has
frame-level but not instruction-cycle evidence for the first `$ED $58`, so
8,393,008 remains a model result. Production waveform identity, later
sound-driver/DMC timing, and full-opening verification remain separate open
work. Runtime audio/WAV was not modified.

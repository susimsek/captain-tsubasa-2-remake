# Cold-start loop and title handoff PC trace

## Capture

A silent FCEUX 2.7.0 power-on replay used the same input timeline as the
opening capture. PC hooks for CPU ROM space `$8000–$FFFF` were installed after
source frame 4660 and recorded through source frame 4692. Audio output was
disabled (`--sound 0 --volume 0`, dummy SDL audio driver). The ROM MD5 was
`eaf2b3745263efa4b1afd2b400f68dae`.

- `reference/diagnostics/title_transition_pc_20261024_150231/pc_trace.csv`
  contains 302,156 instruction rows.
- `frame_state.csv` records the shared script pointer and Start input at each
  source-frame boundary.
- `metadata.txt` records the replay and hook window.
- The paired dispatcher trace is
  `reference/diagnostics/opening_dispatch_full_20261024_150016/opcode_flow.csv`.

## FE loop is an automatic script jump

At source frame 4207, interpreter dispatch executes `$FE` at script pointer
`$A29E`. MMC3 has PRG bank 0 mapped at `$8000` and bank 3 at `$A000`; the
bank-0 vector word is `$8861`, and RTS enters the handler at `$8862`. The ROM
bytes at `$8862` are:

```text
C8 B1 4D AA C8 B1 4D 85 4E 86 4D 4C E7 84
```

The handler reads the two following bytes (`20 A0`) as the new pointer,
stores `$A020` into the script-pointer pair, and jumps back to the interpreter
at `$84E7`. The next observed dispatch is `$E8` at `$A020` on the same source
frame. This is an unconditional script loop: the first pass ends at `$A29E`,
then a second pass starts automatically. The loop does not wait for a menu
choice.
The handler's byte sequence only reads the following 16-bit target, writes it
to the shared script pointer `$004D/$004E`, and jumps to the interpreter at
`$84E7`; it does not clear presenter, PPU, audio, or task state. The Godot
presenter therefore resets only its command cursor and increments a replay
counter at `$FE`, letting subsequent source commands update state in their
original order instead of applying a blanket scene reset.

## Start input window and pointer handoff

In this replay Start is high for source frames 4661 through 4667 inclusive and
low again at 4668. The boundary pointer remains `$A050` through frame 4662.
During frame 4663, execution loads `$A0E5`, then the routine at `$82A1` runs
`LDA #$00; STA $4E; JSR $9085; RTS`, so the shared pointer becomes `$00E5`.
The `$9085` routine advances it to `$00E7` during that frame. At frame 4664,
execution at `$9119` advances the pointer to `$00E8`. The title-side path then
continues with the pointer at `$00E8`.

This bounds the input-triggered handoff to source frames 4663–4664. It does not
by itself identify the first raster-visible title pixel or prove the exact PPU
commit edge. The `$9085` call here occurs after `$82A1` clears the pointer high
byte; it is a title-transition context and must not be conflated with the FC
vector path, which enters `$8837` and advances to the next script byte.

## VM scope supported by this trace

A replacement opening VM can now reproduce the observed byte dispatch classes,
handler entry targets, post-handler pointer changes, compact waits, cursor-back
operations, automatic `$FE` loop, and the Start handoff window. It still needs
ROM-source analysis for each vector handler's full RAM/PPU/audio effects and
operand format. The `$8027–$8031` Start poll now has a frame-level runtime model;
its variable CPU-cycle placement within each frame is not executed. Exact PPU
visibility timing and the rest of the title setup still need explicit modeling
before the remaining frame timeline can be replaced.

## 2026-10-27 Start poll cycle calibration

A later muted FCEUX 2.7.0 replay used the same ROM and the exact input timeline
above, with no movie loaded. The ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`; the input
timeline SHA-256 is
`195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3`. Its
frame-4661 PC hooks recorded `$802C` at offset 4288, `$8030` at 4292, `$8032`
at 4294, `$8048` at 4326, then the `$0700=$01` write at 4330. The ROM-only
stepper's `cycle_after_instruction` matches these FCEUX debugger counter values
for the three poll/branch instructions and `$8048`; the RAM callback matches
the `$804A` store completion. See
`reference/diagnostics/start_poll_fceux_cycles_20261027_080233/events.csv` and
`reference/diagnostics/start_poll_rom_cycle_alignment_20261026.md`.

This calibrates the modeled poll path for that measured frame. Runtime samples
held Start state at the next source-frame poll and applies the measured
38-cycle `$802C→$8048` interval; it does not reproduce the poll's changing
within-frame cycle position. It also does not resolve Godot's first visible
title pixel at subframe/PPU-dot precision.

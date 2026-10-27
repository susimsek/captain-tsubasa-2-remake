# Cold-start scheduler ticks and NMI ordering

## Source identity and method

This trace uses the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, and
the existing power-on replay from
`reference/opening_reference_capture/input_timeline.csv`. RAM/frame evidence
is from `reference/opening_timing_capture_20261024_125300/`; scheduler hooks
and script dispatch PCs are from
`reference/diagnostics/audio_scheduler_trace_20261024_135139/` and
`reference/diagnostics/opening_dispatch_full_20261024_150016/`. All are the
same input timeline and ROM MD5 `eaf2b3745263efa4b1afd2b400f68dae`. No
emulator was started for this analysis.

The external disassembly checked here is
[`cyneprepou4uk/Captain-Tsubasa-2-English-Translation`, revision
`ec03cf06e6bdae0bcd232e3a423e9d259757dc64`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64).
Relevant listings: [`bank_80.asm`](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_80.asm), [`bank_82.asm`](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_82.asm), [`bank_FF.asm`](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_FF.asm).
The instruction bytes at the addresses below were checked directly in the
supplied ROM. The `$A12F` bytes in bank 2 were checked individually; this is
not a claim that all of bank 2 matches the disassembly.

## The three clocks

1. **NES video frame:** one FCEUX `frameadvance()` is one source frame. The
   4,692 measured CPU-cycle deltas average `29,780.5006`; using the NTSC CPU
   rate `1,789,773 Hz` gives `60.09882 Hz`. Individual debugger deltas range
   from 29,775 to 29,786 cycles because cycle sampling is not an exact
   per-frame oscillator read. Use a fixed 60.0988-Hz frame accumulator in
   Godot; do not use each measured delta as a variable frame duration.
2. **Cooperative scheduler tick:** `$9FA8` records a task delay and yields.
   `$9EED` scans the delay bytes at task offsets `1, 5, 9, 13, 17, 21`,
   subtracting one from a nonzero finite delay. When a counter reaches zero,
   it switches immediately to that task's saved stack/bank; a resumed task
   continues the scan from the following slot when it yields again. Once the
   scan reaches the end, the scheduler waits for bit 7 of `$001B`, clears that
   one-bit ready latch, then begins another pass. Due tasks are therefore
   resumed one at a time in slot order, not batch-woken. The number of
   `$9FA8` calls is not the tick count: the trace records 3–6 calls in many
   individual video frames because several cooperative tasks yield during
   that frame.
3. **Cutscene command dispatch:** `$8464` selects the cutscene entry/bank,
   writes the script pointer at `$004D/$004E`, and registers its worker task.
   The worker reads one current byte at `$84E7`; command handlers can run,
   yield, update the pointer, or return to the interpreter. A video frame can
   contain multiple dispatches: the first observed frame-8 pass dispatches
   `$E8` at `$A020` and `$F9` at `$A022` in that same source frame.

## NMI release and PPU queue ordering

At fixed-bank `$C76E`, `BIT $001B` routes to `$C421` when bit 6 is set; other
states take the normal `$C775` NMI body. The normal body reads `$001B` at
`$C7EA`, ORs in bit 7, and stores it at `$C7EE`. In the captured opening's
bit-6 route (`$3B=$55`), `$C421` switches in bank 2 and calls `$A000`; that
routine consumes the staged `$05E8` PPU packet and, after its controller
scan, reads `$001B` at `$A12F`, ORs in bit 7, and stores it at `$A133`. Thus
either observed NMI route releases the cooperative scheduler through the
`$001B.7` ready latch. In the special route, the palette queue transfer occurs
before that ready signal.

The captured palette sequence corroborates this order: the packet present in
RAM at source frame 12 is written by the NMI path during source frame 13; the
PPU palette at frame 13 equals that packet. This is a staged update committed
at the next NMI, distinct from when the script task builds the packet. See
`cold_start_palette_nmi_commit_trace.md` for the bus writes and PPU comparison.

## `$DF` wait measured against RAM and dispatch

The local interpreter bytes at `$84EB` are `C9 D8`, so the real comparison is
`CMP #$D8`. `$8504` distinguishes `$D8–$DF` waits from `$E0–$E7` cursor-back
commands and `$E8–$FF` vector commands. For `$DF`, `$8508` indexes the compact
delay table at `$8AE6`; its last byte is `$F0` (240). The path calls `$899A`,
which only updates `$0099 = ($0099 & $80) | $40`, then calls `$9FA8` with
`A=$F0`. `$899A` is a state helper, not the duration wait.

The same-input observations are consistent with exactly 240 scheduler ticks:

- In source frame 27, `$84E7` dispatches `$DF` at script pointer `$A028`; the
  end-frame RAM snapshot has delay slot `$0005=$F0`.
- Frames 28 through 266 show `$0005` counting down (`$EF` through `$01`) while
  the pointer remains `$A028`.
- In source frame 267 the delay completes, the task resumes, and the pointer
  advances to `$A029`; the end-frame snapshot already shows a new `$01` delay
  from the resumed work.

So the delay spans the 240 video-frame/NMI-release intervals from source
frame 27 to 267. The exact CPU cycle within those frames when the final
decrement, task resume, and pointer advance occur is not captured. Treat the
frame numbers as cross-check anchors, not runtime event instructions.

The first `$DF` after F8 `$A4C0` is a separate, observed release phase. The
frame-3967 RAM dump has slot `$0005=00` with script pointer `$A29B`; the
frame-3968 dump has pointer `$A29D` and slot `$0005=$EF`. Thus, by the
frame-3968 edge, one decrement of the `$F0` delay has already occurred. In
the automatic replay, the second-pass `$DF` instead shows `$F0` at frame 4226
and `$EF` at 4227. The ROM scheduler continues its scan after `$9FA8` and
restarts `$9EED` if the NMI-ready latch is already set, which is consistent
with that first same-frame decrement. The precise NMI/handler subframe edge is
not recorded, so the presenter models a one-release phase credit only for the
compact pause immediately following the traced F8 service; the opcode's
source-table duration remains 240. The frame-4207 `$FE → $A020` dispatch then
matches the live trace. See `f8_00_sequence_trace.md` for the linked RAM and
service evidence.

## Online annotation correction

At `$84EB`, the pinned online listing shows bytes `C9 D8` but its disassembly
operand text says `CMP #$E5`; the label `bra_8537_E5_FF` is also inconsistent
with the relative branch target `$8504`. The supplied ROM and live trace agree
on `$D8` as the comparison and on the four observed classes above. Relevant
code bytes at `$8464`, `$84E7`, `$9EED`, `$9FA8`, `$C76E`, `$C421`, `$C7EA`, and
the selected bank-2 `$A12F` routine agree with the supplied ROM. Trust local
bytes and the live pointer/PC trace where online comments or labels conflict.

## Deterministic Godot interface to implement

Keep frame stepping and game work explicit rather than scheduling captured
`source_frame` event rows:

1. A fixed 60.0988-Hz `OpeningFrameClock` emits a monotonically increasing
   emulated frame index, independent of render refresh rate.
2. On each modeled NMI/vblank, commit PPU packets staged before this NMI; then
   set one scheduler-ready latch. Preserve the source ordering: the special
   `$C421 → bank-2:$A000` path commits `$05E8` before raising the latch.
3. `RomTaskScheduler` consumes that latch once, then reproduces `$9EED`'s
   source-order task scan. When one delay reaches zero, switch to that task
   immediately and run its existing task context until its next yield/return;
   continue scanning from the following slot rather than batch-waking all
   tasks. Only after the scan wraps does the scheduler wait for another NMI
   latch. `$9FA8(A=n)` means wait for `n` scheduler delay decrements, not `n`
   direct command dispatches.
4. Script handlers stage new PPU/audio work for a later NMI. The renderer
   draws committed PPU state plus the separately traced raster events for the
   current visible frame. Track `video_frame`, `scheduler_tick`, and
   `script_dispatch_count` separately; map their starting phase against the
   source capture once, instead of embedding captured frame rows.

This defines a viable clock/scheduler contract for the intro's measured
`$DF` wait and the sampled palette queue. Other interrupt modes, every task's
full wake ordering, and all command-to-visible-pixel timings still need
same-input comparison before replacing the main scene's capture timeline.

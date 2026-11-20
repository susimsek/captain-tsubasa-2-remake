# ROM-Only `$C421` Source Boundary — 1 Nov 2026

## Result

The ROM-only CPU/PPU stepper was run from reset through source frame 7266 using
the pinned cold-start timeline plus the recorded KICK OFF route input file. It
produced the first selector NMI boundary at `$C421` without loading an FCEUX
state or using FCEUX values as execution input.

The source event is `rom-source-nmi-7266-216355361`. The interrupted PC/status
are `$A15B/$20`; CPU at `$C421` is A/X/Y/P/SP=`$1F/$00/$00/$E6/$21`. MMC3
register shadows and the full 2 KiB RAM image are preserved with the source
context. The ROM-only RAM SHA-256 is
`aa95f576dfb1f741e55eb013acbbcb85f71c080550c3c90455cf098a6c59dde0`, exactly
matching both muted FCEUX frame-7266 `$C421` passes. The source stepper reaches
the boundary at cycle `216355361`; FCEUX records cycle `216355364`, a 3-cycle
difference.

The generated context passed `RomFreshMatchSpecialNmiExecutor.execute_from_c421`
and its zero-mask sound-driver continuation. The source state has empty queue
slots `$0700-$0705`, `$0706=$00`, and `$07E9=$00`. The Godot executor scans the
second pass, takes the ROM's zero-mask branch eight times, runs the four-channel
mask loop, reaches `$8163`, and executes the driver RTS back to `$C44C`. It
counts 669 CPU cycles from `$8061` through that RTS and performs no APU-register
writes. The executor then runs the fixed-bank `$C44C-$C471` wrapper tail: it
restores MMC3 R6/R7/command and saved A/X/Y, reverses the `$003B` rotation, and
executes RTI to the interrupted `$A15B` with P=`$20`, SP=`$24`. The full
diagnostic path counts 728 cycles from `$8061`. This is source-context
execution, not live route integration; only `$810C` and `$8163` have retained
same-input FCEUX PC timing comparisons.

## PPU comparison boundary

The source-run and repeated FCEUX `$C421` PPU images are both 16 KiB. Their
nametable range `$2000-$2FFF` and mirrored range `$3000-$3EFF` match exactly.
The canonical 32-byte palette `$3F00-$3F1F` also matches exactly; the 224 raw
differences later in `$3F20-$3FFF` come from palette-address mirroring that the
stepper's flat byte array does not model. The source stepper's unmapped pattern
table has 6,028 differences against FCEUX. A separate Godot MMC3 CHR mapper now
uses the ROM-derived 128-bank CHR resource and source mapper state at this
boundary. With command `$07` (normal CHR mode) and R0-R5=`$00,$02,$F0,$71,$66,$67`,
it selects 1 KiB banks `[0,1,2,3,112,113,102,103]`. Those ROM-derived bytes match
the `$0000-$1FFF` pattern table in both muted FCEUX passes exactly (8,192/8,192
bytes); bank selectors `$F0/$71` are masked by the 128-bank ROM address range.
The PPU comparison verifier checks this static mapping. It does not model
mid-frame CHR writes, pattern fetch latches, or the production field's raster
mapping. Do not copy the FCEUX PPU image into runtime assets.

## Same-input FCEUX continuation evidence

The retained muted two-pass route trace shows `$C421` at cycle `216355364`,
`$C449` at `216356696`, bank-$0C `$8000` at `216356698`, and `$8061` at
`216356879`. It reaches `$810C` at `216356989`, 110 cycles after `$8061`; the
Godot source executor reaches the same PC at offset 110. FCEUX reaches `$8163`
at `216357537`, 658 cycles after `$8061`; Godot reaches it at offset 656, a
2-cycle difference. The driver returns to `$C44C` in the source execution. The
byte-derived wrapper returns from `$C471 RTI` to the interrupted `$A15B`/P=`$20`/
SP=`$24`. FCEUX timing for the wrapper tail and RTI was not captured, so the
728-cycle modeled total is not claimed as a same-input timing match.

The same-frame APU-bus trace contains five `$40xx` writes: one `$4014` OAM DMA
and four `$4016` controller-strobe writes; it has no write to audio registers
`$4000-$4013` or `$4015` in frame 7266. This only describes that frame's bus
writes; it does not prove that audio state or sequence position stayed
unchanged.

Later in frame 7266 the sound-queue watch records `$0700=$01` at bank-$00
`$810A`, cycle `216367134`; `$893B` is reached at cycle `216372514` with
`$0078=$00`. `$810A` is the post-store PC for the bank-$00 `$8107` `STA $0700`
instruction. Its bytes and control-flow are documented in
`first_match_audio_source.md` and
`fresh_kickoff_80fd_to_8920_next_transition_audit_20261031.md`; the existing
normalizer executor emits that write and the production route forwards it to
`GameplayRomCueAudioPresenter`. This is a separate mainline event after the
bank-$0C driver path, not evidence that the bounded `$80CA` continuation
performed the write. Its production subframe timing and the live NMI/IRQ route
remain unresolved.

## Reproduction and artifacts

The ignored local diagnostic output is
`reference/diagnostics/kickoff_rom_source_context_snapshot_20261101/`.
Generate it with:

```sh
python3 tools/diagnostics/trace_rom_source_start_poll_scheduler_window.py \
  --first-frame 7266 --last-frame 7266 --end-frame 7266 \
  --snapshot-frame 7266 --snapshot-pc 0xC421 \
  --route-input-timeline reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv \
  --out-dir reference/diagnostics/kickoff_rom_source_context_snapshot_20261101
godot --headless --path . --script tools/diagnostics/verify_rom_source_c421_snapshot.gd
```

The source run used ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, cold-start
input SHA-256
`195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3`, and route
input SHA-256
`87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`.

## Remaining work

- Integrate the source-owned scheduler/NMI event chain into the Godot live
  route; the captured frame-7266 source boundary must not become a fixed runtime
  endpoint or injected state.
- Connect the verified MMC3 CHR mapping to source-timed production PPU state,
  including mid-frame CHR writes and pattern-fetch latches, and close the
  remaining 3-cycle NMI boundary offset. Nametables and canonical palette
  bytes already match at this boundary.
- Integrate the diagnostic NMI path into the source-driven production route.
  The zero-mask driver and wrapper now return to `$A15B`; the `$8163` point is
  still 2 cycles earlier than FCEUX, and wrapper/RTI timing has not been
  cross-checked against FCEUX. Keep the decoded bank-$00 `$8107` stop write
  (post-store PC `$810A`) as its separate mainline transition; its route
  consumer exists, but live interrupt sequencing and subframe audio timing
  remain unverified. The frame-7266 trace has no audio-register writes and does
  not establish sequence state behavior.
- Produce the raster IRQ/`$78` release and resume the caller into fresh-match
  setup.
- Continue through the ROM-derived field and first command menu, then verify
  same-input output and the ROM/emulator-free packaged runtime.

## Godot NMI PPU packet renderer bridge — 1 Nov 2026

`KickoffCutsceneVisuals.apply_source_ppu_bus_events()` now consumes the ordered
`$2002/$2006/$2007` bus operations emitted by the bounded source-route NMI
consumer. It models the PPU address latch, `$2007` increment selected by the
source PPUCTRL shadow, nametable mirroring, and background-palette writes. The
existing route calls this consumer after an accepted source-runner NMI result;
nametable and background-palette writes are retained as overlays if the field
candidate is installed afterward.

`verify_rom_fresh_kickoff_source_route_runner.gd` supplies two component-level
NMI edges to the bounded source runner and verifies that its first two ROM menu
window packets render `$2221=$00`, `$2241=$9C`, and `$2247=$9D` in the Godot
nametable state. The check proves queue-to-renderer byte flow only. It does not
prove that the production `$893B` route reaches this consumer, that the NMI
cadence or PPU beam timing is correct, or that the complete field/menu image is
visually equivalent. Pattern-table writes and sprite-palette writes remain
unrepresented by this renderer bridge.

## Bank-$0C stop-ID queue consumer prefix — 9 Nov 2026

The focused special-NMI executor now has a second bounded continuation for the
source queue state `$0700=$01`, `$0701-$0705=0`. Starting from its ROM-produced
`$8061` boundary, it checks the reverse scan through the empty-slot branches
`$8066->$80B7->$80B8`, then follows the ID-$01 branch `$806E->$80AF` into the
queue handler at `$8349`. The local ROM bytes at bank `$0C`, file offset
`0x018359`, are `86 F5 A9 00 9D 00 07 88`; `$834D` stores zero into
`$0700,X`, and the post-store PC is `$8350`. This is the point at which the
queued `$01` is consumed.
The modeled path accounts for 93 2A03 instruction cycles from `$8061` to
`$8350`; this is instruction-cycle accounting, not measured NES beam timing.

The executor validates the bank-$0C sound-driver file hash and focused source
hashes for `$8061-$80B9` and `$8349-$834F`. Its bounded result carries the
queue RAM and physical stack forward at `$8350`, with the `$80AF` JSR still
pending. It does not emulate the remainder of the ID-$01 stream lookup, its
APU behavior, the return to `$80B8`, or the NMI RTI.

The focused verifier composes that returned queue RAM with the existing
ROM-backed `$D0A8->$CBF1` helper contract for request `$3C`. The actual helper
scans the now-empty five-slot queue and executes `$CBFE STA $0700,X`, yielding
`$0700=$3C` and queue `3C 00 00 00 00`. This establishes the queue-state
transition from the bounded ID-$01 clear through the unmodified `$CBF1`
consumer. The D093 caller registers/stack are a focused contract fixture, so
this composition is not evidence that the live route has executed the full NMI
and later `$D0A8` call in one continuous run.

The retained muted FCEUX files provide a separate same-route observation:
`sound_queue_writes.csv` records `$0700: $01->$00` at post-store PC `$8350`
on frames 7244 and 7268; `slot09_source_trace.csv` then records the frame-8607
`$CBF1` entry with `$0700-$0704` all zero and `$CC01` with `$0700=$3C`
(sequences 1325-1327). The repeat pass agrees. These files were read as
existing evidence; this task did not operate FCEUX. They confirm observed
route ordering in the retained trace, while the Godot runtime still needs the
full NMI continuation wired into the live route.

Verification passed with:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_fresh_match_special_nmi_executor.gd
```

The check reads project ROM-derived bytes only; it did not operate FCEUX or
consume emulator state. Full sound-driver completion, route integration,
APU/audio timing, and same-run ordering remain open.

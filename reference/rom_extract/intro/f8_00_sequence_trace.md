# Opening `F8 00` bank-2 service trace

## Scope and source identity

This trace follows the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
ROM bytes establish the call and helper sequence below. The FCEUX frame, RAM,
PPU, mapper, and audio records are separate execution cross-checks; they are
not runtime assets and do not by themselves assign effects to concurrent NMI
or scheduler work.

The first-pass dispatch log records `F8 00` at script CPU `$A29B`, ROM file
offset `0x0062AB` (offset `0x27B` in `cutscene_00.bin`), source frame 3476.
Its next dispatch is `$A29D DF` at frame 3968. `$DF` waits 240 scheduler
releases; `$FE 20 A0` dispatches at `$A29E` on frame 4207 and loops to `$A020`.
See `cold_start_observed_dispatch.json` and
`reference/diagnostics/opening_dispatch_full_20261024_150016/opcode_flow.csv`.

### First loop's `$DF` release phase

The frame-end RAM samples distinguish the first post-F8 `$DF` from the later
`$DF` in the replayed script. The cutscene worker is at `$A29B` with slot
`$0005=00` in frame 3967, after the synchronous F8 cleanup. In frame 3968,
`$DF` at `$A29D` has run and the same slot is already `$EF`. By contrast, the
second-pass `$DF` is `$F0` at frame 4226 and `$EF` at frame 4227. Therefore the
first `$DF`'s ROM-table duration is still 240, but one release has already
been counted by the frame-3968 RAM edge. The exact instruction/NMI subframe
ordering is not captured; the `$9FA8 → $9EFB` path can restart the slot scan
when `$001B.7` is already latched, which is consistent with the observed
same-frame decrement. The presenter records this one release phase only for
the compact pause immediately after the completed F8 `$A4C0` service; it does
not change the ROM pause value or the later loop's ordinary countdown.

## Bank-2 dispatch and exact pointer advance

The bank-0 F8 wrapper at `$87F8` (file `0x000808`) is:

```text
C8 B1 4D 85 ED   ; read (script pointer),Y at +1 into $ED
C8 B1 4D 85 EC   ; read +2 into $EC as lookahead
A2 02 20 B9 C4   ; select PRG bank 2 in the $A000 slot
20 12 A2         ; call bank-2 dispatcher
A8 A6 56 20 B9 C4; preserve result, restore bank from $56
98 4C 79 88      ; return result A to common advance at $8879
```

At `$A29B`, this sets `$ED=$00` and peeks `$DF` into `$EC`. Bank-2 `$A212`
(file `0x004222`) begins `4C 84 A4`, a jump to `$A484`. That selector is
`A5 ED 0A AA BD 92 A4 48 BD 91 A4 48 60`: it doubles `$ED`, reads the
high/low address tables at `$A492/$A491`, and returns through the selected
address. The first vector bytes at `$A491` are `C0 A4`, so service index 0
dispatches to `$A4C0` (file `0x0044D0`).

`$A4C0` returns `A=$02`. The wrapper carries that value through bank restore;
`$8879` adds A to the little-endian script pointer `$4D:$4E`, then resumes at
`$84E7`. The live trace observes `$A29B -> $A29D`, delta +2. Thus the command
consumes exactly the opcode and its operand. `$DF` is only the lookahead; it
is dispatched next and is not swallowed by F8.

## `$A4C0` source behavior

The service is a timed title-background/presentation sequence, not the
interactive Start-to-title handoff. Its direct ROM operations are:

| Source-code phase | Byte-verified operations |
| --- | --- |
| `$A4C0–$A4D5` | Calls `$9A0D`, waits with `$9FA8(A=$10)`, then runs 48 iterations of `$9FA8(A=$01)` and `$890C(A=$01)`. `$890C` adds one to each OAM-shadow Y byte at `$0468,$046C,...,$0564`. |
| `$A4D7–$A4E8` | Clears `$5B/$7B`; selects background ID `$17` through `$8AF7`; sets `$44=$68`; loads preset 3 through `$8920`. The preset record is bank-6 `$BF49`, file `0x00DF49`; not every preset field's rendering meaning is decoded. |
| `$A4EB–$A502` | Copies `$8E/$8F` to `$90/$91`; waits with `$9FA8(A=$04)`; calls palette builder `$9A35` and OAM-attribute helper `$88FB`; then waits with `$9FA8(A=$01)`. |
| `$A4FE–$A514` | Repeatedly waits with `$9FA8(A=$01)`, increments `$79`, decrements `$7C` twice, subtracts 2 from `$44`, and repeats while the result is at least 3. Starting at `$68`, this loop runs 51 times and exits with `$44=$02`. |
| `$A514–$A537` | Loads preset 0; sets bit `$01` in `$1B`; waits with `$9FA8(A=$F0)` and `$9FA8(A=$3C)`; clears that bit; sets `$90=$00,$91=$02`; calls `$99F0`, `$9B7F`, and `$98A0`. |
| `$A540–$A558` | Sets `$E6=$C0,$E7=$23`, passes Y=`$02`, X=`$20`, A=`$55` to `$98EA`; loads preset 1; returns A=`$02`. |

Preset 0's bank-6 record at CPU `$BF00`, file offset `0x00DF10`, is 19 zero
bytes in the supplied ROM. `$8920` copies its first byte to `$79`, inserts
zero at `$7A`, and copies the remaining bytes to `$7C–$8D`. The captured RAM
changes from `$79/$7C/$44 = $36/$04/$04` at frame 3651 to `$00/$00/$02` at
frames 3652–3653. The current Godot presenter selects visual preset 0 after
the 51-step loop but retains `$79=$37,$7C=$02` in its modeled RAM; its pixels
still match those sampled frames. This is a state-transfer gap to correct
without changing the already matched final raster frame.

`$98EA` receives the address `$23C0` and a 2-row by 32-byte `$55` fill. With
both palette counters zero, its direct PPUDATA path writes all 64 bytes during
frame 3967. Calls to `$8AF7`,
`$890C`, `$88FB`, `$8920`, `$9A35`, `$9FA8`, and `$98EA` are cross-referenced
to the source/helper evidence in `title_menu_source_trace.md`,
`e8_preset_01_trace.md`, and `cold_start_scheduler_tick_trace.md`.

## Capture cross-checks and limits

Capture directory: `reference/opening_timing_capture_20261024_125300/`.
`frames.csv` maps the source-frame rows to `ram_states/ram_NNNNN.bin` and
`ppu_states/ppu_NNNNN.bin`; the PPU files are 16 KiB address-space snapshots.

- At source frame 3476, the PPU palette at `$3F00–$3F1F` still has the
  pre-service colors. At frame 3489, background palette entries are darker;
  by frame 3559 the 16 background entries are `$0F` while sprite palette
  entries remain populated.
- At frame 3968, all 32 palette bytes are `$0F`, and PPU `$23C0–$23FF` is
  `$55`. The palette remains all `$0F` at frame 4207. This is consistent with
  the source fill and the observed black endpoint; it does not make the
  captured pixels a source asset.
- Frame-end RAM samples show `$4D:$4E=$A29D`, `$44=$02`, `$79=$40`,
  `$7C=$80`, `$90=$00`, and `$91=$02` at frame 3968. These samples are
  cross-checks only; other scheduled work can run in the same frame.
- The mapper log shows the wrapper selecting bank 2 in the `$A000` PRG slot
  and restoring the saved bank; helper calls also make their own bank changes.
- `reference/diagnostics/audio_scheduler_trace_20261024_135139/queue_writes.csv`
  has no `$0700–$0704` sound-queue writes for source frames 3460–4208. This
  does not prove that every called helper is audio-silent: the bus capture
  does not log APU register writes, and channel telemetry cannot attribute
  an audio effect to this service.

## Presenter implementation status

`scripts/opening/cold_start_source_command_presenter.gd` now dispatches F8
operand `$00` to a pending `$A4C0` sequence. The presenter models both fades,
the fixed waits, all 48 OAM-Y increments, the 16-row preclear, `$8AF7`'s
explicit yield and 26 record-queue retries, the 51-step `$44/$79/$7C` loop,
the `$F0/$3C` waits, final OAM/nametable cleanup, direct `$23C0` fill, and the
two-byte return to `$A29D`. The next `$DF` dispatch is aligned to the observed
frame 3968 edge; that final scheduler edge is not attributed to an extra ROM
wait.

The `$17` packet destinations, traversal order, and NMI grouping match the
capture. The earlier payload mismatch used the base `block_04.bin`; the record's
bit-7 selector chooses the page-1 block whose rows and `$AA` attribute match
the captured `$2084` and `$23C9` samples. The extractor and Godot loaders now
use the selected page. The completed live trace below reconstructs the full
CPU queue packet stream as well. An earlier Godot comparison that reported
74.82% RGB / 0.38% foreground was produced while the presenter still skipped
the ROM `$9B28` text-glyph queue-capacity wait and stopped at `$A29A FD` four
frames early. It therefore did not render the F8 scene and is not an F8 visual
measurement. After the queue wait was modeled, the direct presenter reached
`$A29A FD` at frame 3469 and `$A29B F8 00` at frame 3476, matching the live
dispatch trace.

## F8 preset-3 raster path (25 Oct 2026)

The title's moving `$21C0` split is now connected to the local ROM bytes and
the live frame-end RAM/bus records. Preset 3 at bank-6 `$BF49` (file
`0x00DF49`) begins `04 68 00 01 80 C0 21`; `$8920` copies these into `$79` and
`$7C–$8D`. The 51-step F8 loop increments `$79`, decrements `$7C` by 2, and
decrements `$44` by 2. The frame-end capture shows frame 3601 ends with `$79=$04,
$7C=$68,$44=$68`; frame 3640 ends at `$79=$2B,$7C=$1A,$44=$1A`; frame 3651
ends at `$79=$36,$7C=$04,$44=$04`.

The bank-2 NMI writes vertical scroll as `$44-1`: `$A08E` loads `$44`, decrements
it, and stores it to `$2005`. It runs before the foreground cutscene tick. Thus
frame 3640's `$2005` Y value is `$1B`, from frame 3639's `$44=$1C`, while the
frame-3640 RAM snapshot already shows `$44=$1A`. The Godot source presenter now
preserves this pre-task scroll state per frame.

The bank-2 IRQ handler's raster writes now use an MMC3 reload/count model
instead of the earlier fixed `compare+2` renderer offset. At `$A19E`, the
first IRQ writes `$2000=$89`; `$A1A8–$A1BF` advances the `$78` event cursor,
doubles its `$7C` marker with `ASL`, and writes the result to `$C000/$C001`.
The next IRQ follows that reload: its `$C001` scanline plus the doubled marker
and one final clock gives the IRQ scanline. In the `$A160` handler, the
`$21C0` high address write at `$A178` occurs 56 CPU cycles after `$E000`
acknowledgement (52 cycles after `$E001` re-enable); the synchronized PPU
capture places it on the same scanline. `$A17B` writes the low byte on that
line as well.

The source model uses the ROM loop's frame-end `$79/$7C` values and the two
separate `$7C` decrement instructions in `$A4FE`. As the `$79` split moves
down, the IRQ reload can occur before either decrement, between them, or after
both. The model carries that intermediate marker and computes
`counter_reload_scanline + (marker << 1) + 1` modulo 262. Frames 3603–3606
write MMC3 latches `$CC/$C8/$C2/$BC` at lines 12/14/16/18; those values reflect
zero, zero, one, and two completed `$7C` decrements. The subsequent `$21C0`
writes occur at lines 217/215/211/207. These line/value relationships match
the ROM bus trace and do not depend on screenshot-derived text rows.

Frame 3602 has a separate NMI phase: its palette-packet path writes
`PPUMASK=$00` at line 246 and restores `$1E` at line 251. The following title
IRQ's `$2000=$89` write is at line 16, seven scanlines after the steady
`2*$79-1` first-split line. The presenter carries this palette-upload restart
phase across the one-NMI packet delay; the resulting `$C001=$D0` reload is at
line 17 and `$21C0` writes at line 226. This seven-line phase is calibrated
from synchronized PPU/register events. The exact MMC3 A12 restart internals
and the first changed pixel within the scanline are still not modeled.

The first transition frame (3601) also has an inherited IRQ phase that is not
resolved by the current source model; its scanline is explicitly marked
unverified in presenter state. Do not treat the candidate raster phase as
proof of the physical 2C02 pixel edge.

The original PPUCTRL nametable-bit switch is part of this path. The frame-3640
bus trace writes `$2000=$89` at PC `$A19E`, then `$21C0` through
PC `$A178/$A17B`, and restores `$2000=$88` at `$A182`. The earlier model
omitted the switch and hid 611 correctly drawn cup-sprite pixels behind
opaque nametable-0 pixels. Adding the ROM-driven nametable event exposed their
transparent background locations.

The final 51st motion-loop iteration also emits raster writes on frame 3652
while changing the service phase to `wait_f0`. The previous phase-only gate
dropped them; `raster_last_active_source_frame` now keeps the model active for
that frame. Its PPUCTRL `$89` write is at `$A19E`, cycle 14753; `$21C0` writes
are at `$A178/$A17B`, cycles 15441/15445; PPUCTRL returns to `$88` at `$A182`,
cycle 15454. The renderer manifest maps the visible candidates to rows 109
and 115. Row placement is still a renderer mapping, not a direct physical
scanline/dot capture.

A refreshed Godot/FCEUX comparison covers all 27 available reference
checkpoints in source frames 3596–3699. All 27 match every one of 61,440 RGB
pixels, including frames 3602, 3604, 3606, 3640, and 3652. This is sampled
checkpoint evidence, not a comparison of every frame in the window. Results
are in
`reference/diagnostics/f8_window_validation/match_rates.csv`; the same-folder
manifest and PNGs are diagnostic comparison material only.

These checks support the sampled F8 renderer composition, not every F8 frame
or the physical first-pixel phase. The input capture records frame-end states
and selected bus writes, not every CHR fetch throughout the span. The interactive
Start-to-title handoff is a later, separate transition; this `$F8 00` service
is not that transition.

The presenter now places the post-loader state changes at the captured
completion edge: frame 3597 sets `$44=$68`, applies preset 3, and copies
`$8E/$8F` to `$90/$91` before the four-release wait. The copied bytes are
`7C 7E` in synchronized RAM samples; their producer routine is not identified,
so these values are explicitly capture-anchored. `$88FB` is traced and marked
in presenter state. The RAM capture shows all 64 OAM attribute bytes changing
from `$00–$03` at frame 3600 to `$20–$23` at frame 3601, consistent with every
sampled sprite becoming behind-background. The renderer now places that
animation layer behind the ROM background and makes color-index-zero pixels
transparent. A follow-up applies the already-used one-frame OAM display latch
to this priority state: NMI's `$4014` transfer precedes the foreground
`$88FB` attribute XOR, so frame 3601 is rendered with frame 3600's front
priority and frame 3602 uses the new behind priority. This is a source-supported
inference, not direct DMA-payload proof. The Godot/FCEUX recapture for frames
3596–3603 now matches all 61,440 RGB pixels in all eight frames, including the
former 99-pixel frame-3601 mismatch; a fresh full-opening comparison is being
run. See
`reference/diagnostics/f8_priority_latch_candidate_20261026/` and
`reference/diagnostics/f8_palette_restart_same_frame_20261026/`. The earlier
sparse comparison before this latch did not reconstruct the complete F8
presentation. See
`reference/diagnostics/opening_runtime_sparse_1792880258/match_rates.csv` and
the candidate/reference images at source frame 3640.

## Follow-up: helper effects and the `$8AF7` background-17 load

This continuation supersedes the earlier “effects are not established” note
for `$9A0D`, `$99F0`, `$9B7F`, and `$98A0`. The source bytes are from the same
ROM SHA above; frame/RAM/PPU observations below are cross-checks from
`opening_timing_capture_20261024_125300/`.

### Fade, OAM buffers, and clear/fill

| Helper (bank-0 file offset) | ROM behavior | Capture cross-check / limit |
| --- | --- | --- |
| `$9A0D` (`0x001A1D`) | While `$4A` is nonzero, decrements `$4A`, calls `$9A71` to stage a 32-byte palette packet, waits once with `$9FA8(A=$01)`, then loops. | 15 saved-return frames, 3476–3490. `$4A` reaches zero; `$4B` remains `$0F`. Background palette entries darken while sprite entries remain populated. |
| `$99F0` (`0x001A00`) | Checks `$4A|$4B`; for this paired `$0F/$0F` path, decrements both, stages through `$9A71`, and yields once per step. | 15 saved-return frames, 3952–3966. At frame 3967, NMI code `$A03C` commits 32 `$0F` palette bytes; the captured palette is all `$0F`. |
| `$9B7F` (`0x001B8F`) | Fills `$0468–$0567` and `$0200–$02FF` with `$F8`; then clears `$0568,$0588,$05A8,$05C8`. | Frame-3967 RAM matches. The capture does not expose internal PPU OAM or log the DMA commit, so only the RAM effects are confirmed. |
| `$98A0` (`0x0018B0`) | Temporarily disables rendering, writes 2,048 zero bytes through `$2007` over `$2000–$27FF`, then restores the `$2001` rendering bits and `$2000` NMI bit. | Frame 3967 has 2,048 `$2007` zero writes from PC `$98C4`; `$2001` changes `$06→$1E`, `$2000` `$08→$88`. |

After `$99F0` has reduced both counters to zero, `$98EA` takes its direct
PPUDATA branch rather than the `$05E8` queue branch. In frame 3967, PCs
`$9949/$994E` set the address sequence for `$23C0` and `$23E0`; PC `$9953`
writes 64 `$55` bytes. The frame-3967 PPU snapshot confirms `$23C0–$23FF` is
`$55`. This is a synchronous fill after `$98A0`'s clear, not just a queued
request.

None of these four helper bodies directly writes APU registers. The captured
sound-queue log has no `$0700–$0704` writes during frames 3460–4208. APU
telemetry remains active, but it cannot attribute channel state to this F8
service.

### `$8AF7` phase and queue evidence

At `$A4D7`, `$A4C0` requests background `$17` through `$8AF7`; the call returns
before the `$44=$68` setup at `$A4E8`. `$8AF7` selects bank 7, reads the
background record at file `0x00E383` / CPU `$A373`, and follows the `$5D&$04`
pre-clear branch. The live PPU writes target `$2000`, identifying the
`$9071→$98E8` zero-fill path (512 bytes at `$2000–$21FF`), rather than the
`$9076` path at `$2400`.

`$9071` sets destination `$2000`, `Y=$10`, and `X=$20`, then enters `$98E8`; that routine
stages 16 packets of 32 zero bytes, advancing the PPU address by `$20` after
each packet. The first packet is already staged before the first capacity
retry: frame-3555 RAM has `$0628=$23` (35 encoded bytes: a 3-byte packet
header plus 32 payload bytes) and `$0629=$20` (the next 32-byte reservation).
That next reservation is the first `$9B32` stall. After 15 such retries, the
16th clear packet `$21E0–$21FF` is staged; `$9071` returns, and `$8BB2` yields
afterward. Its NMI write appears in frame 3571 while the task is saved at
`$8BB2` in frame 3570: the explicit yield is after row 16 is staged and before
its final NMI drain.

The saved slot-5 returns resolve the 42 loader waits in order:

| Source-frame rows | Saved return | Count | Loader phase |
| --- | --- | ---: | --- |
| 3555–3569 | `$9B32` | 15 | `$9B28` queue-capacity back-pressure while `$9071/$98E8` stages its 512-byte nametable clear. |
| 3570 | `$8BB2` | 1 | The explicit `$9FA8(A=$01)` after the `$9071/$9076` clear helper. |
| 3571–3596 | `$9B32` | 26 | `$9B28` back-pressure while the background record and metatile packets are staged. |

The remaining saved-return intervals in the F8 span are:

| Source-frame rows | Saved return | Count | Source phase |
| --- | --- | ---: | --- |
| 3476–3490 | `$9A1A` | 15 | `$9A0D` background-palette fade. |
| 3491–3506 | `$A4C8` | 16 | Explicit `$A4C0` wait. |
| 3507–3554 | `$A4CF` | 48 | Repeated `$9FA8` wait plus `$890C` OAM-shadow Y increment. |
| 3597–3600 | `$A4F8` | 4 | Explicit `$A4C0` wait after loading preset 3. |
| 3601–3651 | `$A503` | 51 | The `$44=$68` loop; its one-tick wait is inside each iteration, not an extra pre-loop wait. |
| 3652–3891 | `$A524` | 240 | Explicit `$A4C0` wait. |
| 3892–3951 | `$A529` | 60 | Explicit `$A4C0` wait. |
| 3952–3966 | `$9A08` | 15 | `$99F0` paired palette fade. |
| 3967 | — | — | Synchronous `$9B7F`, `$98A0`, and `$98EA` cleanup/fill; no additional saved `$9FA8` wait is established. |

The NMI trace corroborates the phase boundary: frames 3556–3571 write 512
zero bytes in 32-byte chunks, advancing `$2000,$2020,…,$21E0`; the first
background-record packets appear in frame 3572. The earlier 15 capacity waits
therefore occur before the `$8BB2` yield, not after it. After that yield, each
`$9B32` is a producer-side `$9B28` reservation retry, not a ROM-maintained
record-batch counter. For this capture, they align with the 26 full nine-packet
NMI drain groups: at frame 3571, `$0628=$39` (57 encoded bytes, the first nine
packets) and `$0629=$04` (the next four-byte request would reach `$3D`). NMI
drains those nine packets in frame 3572. The 26 retries align with full groups
drained in frames 3572–3597; the final partial group of six packets drains in
frame 3598 after the producer completes, so it needs no 27th retry. Across the whole F8
span, the helpers and `$A4C0`'s explicit waits total 491 scheduler ticks:
`$9A0D` 15 + `$A4C0` fixed waits/loop 419 + `$99F0` 15 + `$8AF7` 42.
The dispatch-frame delta is 492: frame 3967 performs the synchronous clear
and fill, and `$DF` is dispatched at frame 3968. This last boundary is a
frame-end/resume phase difference, not another measured `$9FA8` wait.

For the `$17` record, the decoded 6×8 layout yields 48 metatiles and 240 PPU
packets. The generic builder's packet order—each row-major metatile's
attribute byte, then tile rows 0–3—matches all 240 captured PPU destination
addresses exactly. Live CPU queue staging produces 26 batches of nine packets
in source frames 3571–3596, then the final six in frame 3597; the corresponding
PPU commits are observed in frames 3572–3598. Packets contain one attribute
byte or four tile bytes, each preceded by a three-byte queue header.

The payload discrepancy is explained by the record's page selector. The third
record byte is `$81`; bank-0 `$8B4E` transfers bit 7 into `$5B.0`, and `$8EF0`
uses that selector to compute the block pointer as
`$A000 + 17*block_id + $1100*selector` in PRG bank 8. The `$00 $A0` trailer
separately selects the `$80` special traversal path (`$8C0E → $8C59`), which
walks the six-by-eight ID field. Thus the selected `$04` block is at CPU
`$B144`, ROM file `0x011154`, not the base-page record at `$A044` / `0x010054`.
The selected bytes are `AA 00 00 00 00 00 00 80 81 00 00 82 83 00 86 88 83`;
they match the captured rows at `$2084`, `$20A4`, and `$20C4`, and the `$AA`
attribute input at `$23C9`. The earlier `$FF→$AA` conversion theory came from
comparing the wrong page. Bank-0 `$8FD1` (file `0x000FE1`) calls `$9049` (file
`0x001059`), which maps the active tile origin to an attribute-table address
and returns its low/high bytes in Y/X; for this layout the address is
`$23C8 + 8*row + column`. All 48 `$67.6` flags are clear, so execution takes
the direct `$903A` path. Its verified bytes at file `0x00104A` are
`A9 01 20 28 9B A5 E7 9D E8 05 E8 20 5E 9B 60`: reserve a one-byte packet and
store `$E7` unchanged. The `$8FD8` partial-attribute merge branch is not
exercised here, and its `$064A` scratch semantics remain unknown.

The extractor now preserves page-1 records separately and the selected-page
manifest uses those source bytes. Comparing all 816 tile/attribute payload
bytes against the title PPU snapshot at frame 4692 yields 815 exact byte
matches; the sole difference is row `$2208`, where the title cursor overlays
tile `$7F` at `$220A`. This confirms the static `$17` block-page mapping and
final nametable content apart from that menu overlay. By itself, that static
comparison does not prove the live F8 producer's instruction-by-instruction
queue behavior; the dedicated trace below records that path.

The byte-checked bank-0 loop at `$8F49` (ROM file `0x00F59`) is a literal
four-byte copy from `($EA),Y` into the PPU queue at `$05E8`; it does not remap
tile IDs. The source bytes are `B1 EA 9D E8 05 E8 C8 C0 04 D0 F5`, matching
the annotated [bank-80 disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/master/bank_80.asm).
The record trailer bytes at bank-7 CPU `$A3A9–$A3AA` are `00 A0`; the loader
recognizes the `$80` mode and branches through `$8C0E` to `$8C59`. `$8F26`
selects PRG bank 8, and the bank-8 block pointer incorporates `$5B.0` as the
`$1100` page selector. Frame-end `$EA/$EB` remains scratch and cannot identify
the pointer used at an earlier read. `$8FD1` enters a separate attribute
address/update path; the selected source attribute for block `$04` is already
`$AA`.

The full-address live trace is now available in
`reference/diagnostics/f8_special_mode_20261024_200815/`. It replays the
preserved input timeline silently through source frame 3610; hooks cover frames
3450–3601. It records full 16-bit PCs and `$005B` writes. At frame 3555 the
`$8B52 ROL $5B` operation sets `$5B` to `$01` while X contains record flag
`$81`; the write callback reports the instruction's next PC, `$8B54`. Its ROM
SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, matching
the supplied Turkish ROM. The `$8C0E` special-mode entry and `$8C59` setup each
run once at frame 3571. From frames 3571–3597, the trace records 48 `$8F00`
block requests and 48 `$8F26` bank-8 pointer selections, covering 31 IDs:
`$00` and `$04–$21`. The full 48-ID sequence exactly matches bytes 6–53 of
the `$17` background record, in row-major order.

For every request, the live `$EA:$EB` pointer matches CPU `$B100 + 17*ID`,
which maps to ROM file `0x011110 + 17*ID` on selected page 1. `$8F26` observes
bank register R7 still set to 7 before the bank-switch instruction; the
attribute and tile-copy hooks observe R7=8. The source byte and accumulator at
both `$8FD1` and `$9049` match the selected record's first byte for all 48
blocks. All 48 attribute payload writes at `$9044` match `$E7` and the source
record byte; `$903A` executes 48 times and `$8FD8` zero times. All 768 source
bytes read at `$8F49` match record bytes 1–16, and all
768 values stored at `$8F4B` match the same ROM bytes. Each of those 768 stores
also matches a distinct captured write at queue RAM `$05E8 + X`. This confirms the
live block-ID order, selected-page pointer calculation, raw tile copy, and
attribute payload values reaching the CPU queue. Reconstructing packet headers
from the same queue writes yields exactly 240 packets; every packet length,
destination address, order, and payload matches the ROM-derived row-major
builder. At the `$8F49` instruction entry, A is the prior accumulator value;
the recorded `source_byte` is the actual indirect-read value, while `$8F4B`
records the value being stored.

These findings close the live source-selection, attribute-address, and
packet-staging questions for this captured `$17` `$80` path. The independent
frame-4692 comparison still has 815/816 matching nametable bytes because the
title cursor overlays `$7F` at `$220A`. Exact CPU-cycle/subframe PPU commit
timing, raster-visible composition, and the post-correction Godot result remain
open. The `$8FD8` partial-attribute merge branch and its `$064A` scratch
semantics remain unobserved; the `$17` path only exercises the verified direct
attribute path.

The other active scheduler contexts are concurrent presentation work, not
extra F8 waits: slot `$01` returns at `$802B` (Start poll), slot `$11` at
`$9147` is an animation/object worker using bank 9, and slot `$15` at `$A8D2`
is an OAM/animation updater. The execution-count trace reports three or four
`$9FA8` calls per frame through most of the span; these worker ticks interleave
with slot `$05` and are not additive to the F8 command's elapsed waits.

## F8 helper-return dispatch event (26 Oct 2026)

The remaining one-frame dispatch edge after the `$F8 $00` service is now
represented by `assets/opening/rom_logic/f8_helper_return_event.json`, generated
by `tools/diagnostics/export_f8_helper_return_event.py` from the ROM-only source
CPU trace in `reference/diagnostics/f8_return_source_trace_20261026/`. The
exporter verifies the supplied ROM hash, extracted cutscene script hash, and
the script bytes `F8 00 DF FE 20 A0` at script offset `$027B`.

The ordered trace records the service returning through `$98DC->$A541` in
source frame 3967, the tail returning through `$895C->$A557` and `$A559->$880A`
in frame 3968, then the wrapper's `$8811->$8879` return and `$84E7/$8508` script
dispatch before `$8514` calls `$9FA8`. The event's 3967/3968 labels describe
this first script pass. Because the following `$FE $20 $A0` returns to `$A020`,
Godot maps those labels through the loop phase established at each `$FE`, then
schedules the next absolute source frame. A deterministic replay through source
frame 8300 reached the second helper return at frame 8166 and script dispatch at
8167 without stopping. The runtime does not consume the event's modeled cycle
numbers or claim physical subframe timing.

The source event order/frame is derived from ROM stepping, with the recorded
input timeline attached for provenance; captured frame intervals, pixels, and
audio are not event-generation inputs. The stepper carries one CPU cycle per
DMC read but does not implement the physical 2A03 halt/get-put arbitration
(full 3/4-cycle stalls). These per-PC cycles were not independently matched to
FCEUX per-PC cycle timestamps, so they are metadata only and do not establish
subframe timing. The narrow Godot render check passes frames 3967–3969 with no
pixel changes against the prior Godot full-capture baseline; it verifies no
render regression, not FCEUX subframe parity.

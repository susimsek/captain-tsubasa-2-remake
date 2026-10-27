# ROM source trace: Start handoff and title menu

## Scope and evidence

This note traces the cold-start Start press through the first title-menu
composition. It stops before a title option is confirmed. Source addresses and
bytes were checked in the supplied Turkish ROM:

- File: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256 (whole iNES file):
  `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- MD5 of PRG+CHR payload without its 16-byte iNES header:
  `eaf2b3745263efa4b1afd2b400f68dae`
- PRG code below is in MMC3 bank 0 at CPU `$8000`; file offset is
  `0x10 + (CPU address - $8000)`.

Primary live trace: silent FCEUX 2.7.0 power-on replay of the reference input
timeline, source frames 0–4692, with ROM-PC hooks on frames 4661–4692. The
emulator used `--sound 0 --volume 0` and the dummy SDL audio driver. See
`reference/diagnostics/title_transition_pc_20261024_150231/{metadata.txt,frame_state.csv,pc_trace.csv}`.
The paired title endpoint PPU/RAM and input evidence is in
`reference/title_menu_down_probe_20261024_131859/`; the one-frame Down pulse is
after the title endpoint and is not a confirmation input. These are diagnostic
state captures, not runtime assets.

## Public reverse-engineering leads

The annotated English-translation disassembly labels the bank-0 entry, outer
Start loop, stop request and title routine. The relevant bank-80 byte records
were checked against the local ROM (the broader source audit is documented in
`online_reverse_engineering_resources.md`). The Japanese address memo labels
the opening-demo region, while the Turkish TsubasaTR music-system article
helps locate the sound-driver table. They are leads, not substitutes for this
ROM's live trace. The available Chinese Hack CT2 page is a tool/reference lead;
it did not provide a locally verified address for this title handoff.

- [Annotated CT2 disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation)
- [Japanese CT2 address memo](https://daymoe.com/rom/code/%E3%82%AD%E3%83%A3%E3%83%97%E3%83%86%E3%83%B3%E7%BF%BC2%E3%82%A2%E3%83%89%E3%83%AC%E3%82%B9%E3%83%A1%E3%83%A2.html)
- [Turkish music-system notes](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html)
- [Chinese Hack CT2 reference](https://daymoe.com/rom/Hack%20CT2.html)

## Observed Start handoff

The reset-side outer loop in bank 0 is `$8027–$8032` (file
`0x000037–0x000042`):

```text
20 A8 9F       JSR $9FA8       ; yield through the cooperative scheduler
A5 1E          LDA $1E         ; newly-pressed input edge mask
29 10          AND #$10        ; Start
F0 F5          BEQ $8027       ; repeat while no Start edge
```

In the traced input replay, Start is high on source frames 4661–4667. On frame
4661 the edge passes the poll at `$8032`; bank-0 code clears its transition
state and writes sound command `$01` to `$0700` at `$8048–$804C`. The APU
channel telemetry is nonzero on frame 4661 and all five channel volumes are
zero from frame 4662. The `$0700` write queues a driver command; this handler
does not directly write APU registers.

The interpreter's shared pointer is `$A050` at the Start edge. During source
frame 4663, the captured bank-0 routine at `$82A1` clears its high byte and
calls `$9085`; the live trace observes the pointer progress `$A0E5 → $00E5 →
$00E7`. At frame 4664, `$9119` leaves it at `$00E8`. This is the observed
interpreter-to-title-side handoff window, not proof that the Japanese memo's
separate `0x62B1` stream is executed. The CPU mapper trace has bank 0 in the
`$8000` window and bank 2 in `$A000` when the outer Start path is executing.

The transition does not draw the title immediately. The replay continues
through the scheduler and helper calls. Title background selection starts at
source frame 4664; the shared `$8AF7` loader spends the following frames
staging and yielding on the background queue. It returns to title setup at
`$806F` on frame 4690:

| CPU address | ROM operation | Observed frame | Meaning supported by bytes/trace |
| --- | --- | ---: | --- |
| `$806A–$806E` | `LDA #$17; JSR $8AF7` | 4664 | Select background ID `$17`, the title layout entry; the loader call begins. |
| `$806F–$8079` | `LDA #$30; JSR $890C; JSR $88FB; JSR $9A35` | 4690 | Title setup helpers; palette/layout work is not fully assigned to one helper from this PC trace alone. |
| `$807A–$807D` | `LDA #$00; JSR $8920` | 4691 | Final title-state setup helper. |
| `$808D–$80A1` | set cursor state/address, `LDA #$7F; JSR $98EA` | 4691 | Initialize cursor marker and submit it to PPU helper. |
| `$80A2` onward | scheduler/input loop | 4691 | Title waits for a new menu input edge. |

FCEUX's source-frame-4692 PPU snapshot contains tile `$7F` at nametable
address `$220A` and zero at `$224A`. That independently verifies the initial
cursor is beside `KICK OFF`. The matching title endpoint frame has the original
title composition and both option rows; the asset/PPU reconstruction and its
pixel comparison are recorded in `docs/opening-scene-assets.md`.

## Live title-entry background and cursor queue

The full-address, silent source-input trace at
`reference/diagnostics/title_entry_setup_20261024_201420/` records the actual
title-entry `$17` loader beginning at frame 4664. Its 48 block IDs match the
record's six-by-eight row-major sequence. The selected page pointers, all 768
tile bytes, and all 48 attribute values match the supplied ROM. Reconstructing
queue RAM `$05E8–$0627` yields the complete 240-packet stream: packet lengths,
PPU destinations, order, and payloads all match the ROM-derived loader model.
The loader stages 26 groups of nine packets in frames 4664–4689, then six in
frame 4690.

On frame 4691, title setup queues a 32-byte palette packet at `$3F00` and the
one-byte cursor packet `$7F` at `$220A`. Both payloads match the frame-4692 PPU
snapshot: the palette packet matches all 32 palette bytes and the cursor tile
matches `$220A`, while `$224A` remains zero. The same trace observes `$806F`
resume on frame 4690, `$807A` and cursor initialization on frame 4691, then
the `$80A2` input loop. This closes the title call's ROM-record-to-queue data
mapping; it does not determine the first visible scanline/dot or prove Godot's
post-change output.

## Title cursor input, from bank-0 bytes

The wait loop begins at `$80A2`: it yields through `$9FA8`, reads the newly
pressed mask at `$80A7`, and applies `AND #$3C` at `$80A9`. Thus this menu loop
responds to Select `$20`, Start `$10`, Up `$08`, and Down `$04`; the ordinary
A/B/left/right bits are outside this first mask. The following control flow is
verified from ROM bytes:

- Select reaches `$80BC`, toggles bit `$40` of the cursor-state byte at `$ED`,
  then redraws through the shared cursor update path.
- Up and Down are decoded by shifting the masked byte. Up yields cursor offset
  `$0A`; Down yields `$4A`. The shared update stores that offset in `$ED`,
  sets PPU address base `$220A`, clears the previous marker region through
  `$98E8`, and returns to the `$8091` marker-write path, where tile `$7F` is
  submitted through `$98EA`.
- The separate Down-only probe sets RAM `$1C=$04` and `$1E=$04` at source frame
  4693; that snapshot still has `$7F` at `$220A`. At frame 4694, the PPU
  snapshot has `$220A=0` and `$224A=$7F`. This confirms the visible move one
  source frame after the pulse. It does not establish every sub-frame PPU
  write or raster-visible dot.
- Start reaches `$80D4`. The path checks held A+B bits in `$1C` before the
  cursor-dependent branch at `$80DF–$80E5`; a Start press can enter the
  option-confirmation route. This slice must stop before that branch is
  activated.

Do not overread the `$80E1` branch as a complete story-flow description: it
only selects the next ROM path from the current cursor state. The current
milestone intentionally leaves both menu options unconfirmed.

## Helper-chain source and commit trace

The helper effects below were checked against the supplied ROM bytes and the
synchronized silent FCEUX bus/RAM/PPU capture in
`reference/opening_timing_capture_20261024_125300/`. The bus file labels the
CPU's current emulator frame as `source_frame`; for example, source-frame
4692 records the NMI writes that appear in the frame-4692 PPU state. These
records are observation data, not runtime assets.

| Helper | Local ROM behavior and observed state |
| --- | --- |
| `$8AF7` (`file 0x000B07`) | Saves requested ID in `$ED`, clears loader flags, switches PRG bank for the shared background loader, indexes its background pointer table, and prepares the selected layout. The title call passes `$17`. The byte-verified record is `background_17.bin` / `background_17_layout.json` at file `0x00E383` (CPU `$A373`): CHR 2-KiB selectors `$7C,$7E` (1-KiB banks 124–127), palette flag/index `$81/$01` pointing to ROM file `0x00D020`, and a 6×8 metatile-ID field whose packed origin is `$08` / PPU `$2080`. The bus trace shows the loader's NMI consumer writing nametable data during frames 4690–4691; it is not a complete direct record-to-screen dump. |
| `$890C` (`file 0x00091C`) | Adds A to each OAM-shadow Y byte `$0468,X` for X=`0,4,…,252`. Title passes `$30`; animation descriptor `F1 26 3E` yields base Y `$4C`, then `$7C`. All 63 live title OAM entries match the source animation geometry after the shift. |
| `$88FB` (`file 0x00090B`) | XORs attribute bit `$20` in all 64 OAM-shadow records. The title call changes sprite priority; the captured title OAM attributes match the ROM descriptors after the XOR. |
| `$9A35` (`file 0x001A45`) | Loads the selected background and sprite palettes, sets brightness `$4A/$4B` to `$0F`, then builds the 32-color `$3F00` packet in `$05E8`. At frame 4691 the packet is `20 00 3F`, the 32 colors from RAM `$062A–$0649`, then terminator `01`; the PPU palette is still `$0F`. During the next NMI (source frame 4692), PC `$A03C` writes those 32 values to `$3F00–$3F1F`; the frame-4692 PPU palette equals the packet byte for byte. |
| `$8920` (`file 0x000930`) | The title passes A=`$00`. The helper computes bank-6 record address `$BF10` and copies its 19 bytes. Local ROM file `0x00DF10–0x00DF22` is all zero, so `$79` and `$7B–$8C` become zero and `$7A` is explicitly cleared. RAM snapshots show the prior `$79/$7A` state at frame 4690 and the cleared fields at 4691. This is distinct from intro preset A=`$01`, whose record starts at file `0x00DF23` and contains `40 80 00 22`. |
| `$98E8` / `$98EA` (`file 0x0018F8` / entry one byte later) | These routines construct row-write packets in `$05E8`: use `$E7:$E6` as PPU base, Y as row count and X as row width; `$98E8` fills rows with `$00`, while `$98EA` uses its input A as the tile value. Each row advances the address by `$20`; the queued packet is consumed by the NMI PPU writer. On the title setup frame 4691, `$98EA` stages tile `$7F` for `$220A`; frame 4692 NMI bus events at scanline 251, dots 93/120/147 write address `$220A` and data `$7F`. The resulting frame-4692 PPU state has `$220A=$7F`, `$224A=0`. For Down, `$98E8` stages clearing at `$220A/$222A/$224A` and `$98EA` stages `$7F` at the new row; the captured endpoint changes on the following source frame, 4694. |

The observed frame-4690 NMI nametable writes target rows/locations around
`$2314`, `$2334`, `$2354`, `$2374`, `$23F5/$23F6`; frame 4691 continues at
`$2378`, `$23F7`, `$231C`, `$233C`, `$235C`, `$237C`. They are emitted by the
NMI consumer (`$A029/$A030/$A036/$A03C`) from queued data. This anchors the
loader's delayed PPU effects, but a byte-by-byte reconstruction of every
background record field into every queued packet remains open.

## What the current Godot title does

`scenes/title_menu.tscn` uses `scripts/title_rom_background_renderer.gd`, and
the handoff runner in `scripts/title_rom_handoff_queue.gd` now applies the 240
ROM-derived `$17` packets through the ROM `$3D` queue-capacity rule, with
modeled next-frame commits. It derives the observed 26 groups of nine and final
group of six from actual packet sizes. After the last background queue drain,
it stages the 32-byte ROM-derived palette and `$7F` cursor; frame 31 commits
them and reveals the title. This models the source-frame schedule without
executing `$8AF7`, `$890C`, `$88FB`, `$9A35`, `$8920`, `$98E8/$98EA`, or the NMI
consumer as CPU instructions. The first producer release and next-frame commit
edge remain capture-aligned; CPU/NMI subframe timing is approximate. The static `title_menu.png`, scanline-0
overlay, and `title_menu_continue.png` remain reference outputs, not runtime
textures. The endpoint RGB comparison is documented in
`docs/opening-scene-assets.md`. After the menu appears, cursor state changes
are still delayed by one nominal NES frame (`1 / 60.0988 s`) after input; this
matches the observed Down pulse at source frame 4693 becoming visible in the
frame-4694 PPU snapshot. If multiple inputs arrive before the pending commit,
the latest target is shown at the original deadline; the capture establishes
only a single Down pulse, so multi-edge coalescing remains an assumption.

## Remaining evidence gaps

- The PC trace bounds the transition to source frames 4661–4664 and records
  title background setup at 4664, the loader return at 4690, title
  initialization at 4691, and the endpoint PPU snapshot at 4692. The full
  timing capture in `reference/opening_timing_capture_20261024_125300/` has
  PPU/RAM snapshots for every source frame 0–4692. Its recorded MD5
  `eaf2b3745263efa4b1afd2b400f68dae` matches the supplied ROM bytes after the
  16-byte iNES header is removed; its frame map states
  `source_frame = emulator_frame_after` and `script_frame = source_frame+1`.
  On frames 4662–4691, all 32 palette bytes at `$3F00–$3F1F` are `$0F`; the
  documented FCEUX internal palette maps color `$0F` to RGB black. Frame 4692
  restores the title palette during vblank, and the captured PPU/screen state
  shows the title menu. Endpoint screenshot evidence is retained at
  `reference/opening_reference_capture/screens/frame_004662.gd` and
  `frame_004692.gd`; no screenshot pixels are used by the runtime renderer.
  Thus the 30 black output frames after Start (4662–4691) and title appearance
  in frame 4692 are supported by source-state evidence. The first nonblack
  pixel's exact subframe position is still unmeasured.
- The title-entry `$8AF7` invocation's full record-to-queue packet mapping is
  now reconstructed from the silent CPU queue trace. The remaining gap is the
  exact per-frame visible composition and first title scanline/dot, not the
  source block bytes or packet addresses.
- The PPU capture is vblank-only for the relevant endpoint. It establishes
  queued-write commits and frame snapshots, but not the first visible pixel,
  scanline, or dot for the completed title composition.
- Godot now executes a ROM-derived packet timeline through the title handoff,
  but does not execute the ROM's Start polling, helper routines, or NMI CPU
  code. Queue back-pressure is now derived from the `$3D` capacity and packet
  sizes, yielding the observed 26×9+6 groups; palette/cursor commit completes
  the queue and reveals the title. A focused same-input Godot harness confirms
  30 black frames, frame-31 reveal, and both endpoint images pixel-exact.
  Source-cycle phase, exact raster timing, initial three-frame producer delay,
  and multi-edge behavior remain unmodeled.
- Start confirmation, including the `$80D4` A+B special check and either
  selected option's destination, is outside this trace and outside the
  requested milestone.
- Audio telemetry proves the APU channels reach zero after stop command `$01`;
  it does not prove that an emulator audio-filter tail is instantly silent.


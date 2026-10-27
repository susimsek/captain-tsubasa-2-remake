# Cold-start source-command presenter

`scenes/prototypes/cold_start_source_command_presenter.tscn` is the isolated
ROM-byte-driven presenter scene used by
`scenes/opening_source_runtime.tscn`. It reads the preserved cutscene script, models the
observed `$F9 01` field-background queue, ROM-derived F3/F4 palette changes,
text cursor/glyph packets, zero-fill commands and four capture-anchored EC streams, then renders
committed nametable bytes from ROM CHR/palette resources. Each `FB` command
replaces the active set with native ROM-frame animation nodes in list/OAM
order; the runner also uses source-frame time and the observed Q8.8 motion recurrence.
A shared packet builder validates and stages the extracted F9/FA backgrounds
through the observed queue-capacity guard. Uncaptured EC occurrences, later F1
data-table paths, full NES OAM evaluation, hidden-sprite rules and exact text
reset writers still limit the executable path. `scenes/main.tscn` now starts
the source runtime and its ROM-driver audio render, then shows the ROM-CHR title
endpoint on Start. The 30-frame black handoff is supported by the per-frame PPU
snapshots in `reference/opening_timing_capture_20261024_125300/`: every palette
byte is `$0F` on source frames 4662–4691, which the documented FCEUX RGB table
maps to black; the title palette returns on frame 4692. The title `$17` loader
does stage nametable updates during this interval, but those updates remain
black until the palette changes. Godot's 30-frame duration matches the captured
frame boundaries; exact subframe first-pixel timing and a same-input Godot
comparison remain open.

The observed `FE 20 A0` cutscene loop at source frame 4207 replays the original
Tecmo Theatre commands. Logo visibility is now derived from the active
background, E9 screen-enable state, and completion of the EA clear instead of
being limited to the first absolute frame range. On this repeated E9, the
presenter restores the ROM-byte-verified background palette at `$D020` and
animation `$8D` sprite palette at `$D670` before running the fade model. The
full 275-frame repeated-logo window directly matches FCEUX at 100% RGB and
foreground exactness. Source trace and comparison files:
`reference/rom_extract/intro/repeated_logo_loop_trace_20261025.md` and
`reference/diagnostics/repeated_logo_loop_direct_20261025/`.
The F8 `$17` packet destinations/order match capture. Its header bit-7 page
selector now chooses the original bank-8 `$1100` variant; 815/816 tile and
attribute bytes match the frame-4692 PPU snapshot, with the sole difference
being the `$7F` title cursor overlay. The silent live trace now verifies all 48
block requests in exact ROM-record order across 31 IDs, selected-page
pointers, all 768 tile bytes copied from ROM into the CPU queue, and all 48
attribute values written to that queue. Reconstructing the queue writes yields
all 240 packets with matching lengths, addresses, order, and payload (26
batches of nine, then six). Exact subframe NMI-to-PPU timing, raster
composition, and the post-change Godot frame remain unverified; see
`reference/rom_extract/intro/f8_00_sequence_trace.md`.
At the `$8AF7` completion edge, the presenter now sets `$44=$68`, loads preset
3, then applies `$A4EB`'s `$8E/$8F → $90/$91` copy before the four-release wait.
The copied values `7C 7E` are a synchronized frame-3597 RAM anchor; the code
that produced `$8E/$8F` is unresolved. `$88FB` is recorded as a priority-bit
toggle. All 64 sampled OAM attribute bytes change from `$00–$03` to `$20–$23`
between frames 3600 and 3601; the presenter now draws the animation layer
behind the ROM background and exposes sprites through color-index-zero
background pixels. This renderer change has not been runtime-compared.

## Source bytes and scheduler

- ROM SHA-256:
  `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Script extract: `reference/rom_extract/intro/cutscene_00.bin`, 641 bytes at
  ROM file offset `0x006030` / CPU `$A020`; recorded script SHA-256:
  `499ccb62b8b2b9118d7ebfaa6e6b9fce46806cd3b9173b5e1d5d61de21c2a6b7`.
- Worker registration and the source-frame-8 startup anchor are documented in
  `reference/rom_extract/intro/cutscene_boot_task_install_trace.md`, based on
  local `$9F69`/`$9EED` bytes and the saved power-on capture.
- `scripts/opening/cold_start_source_command_presenter.gd` reads and checks
  that extracted byte span, then parses commands directly from its cursor. It
  does not read `cold_start_observed_dispatch.json` as runtime authority.
- `scripts/opening/rom_cooperative_scheduler.gd` models the `$9EED` task-slot
  scan, `$9F69` ready-task installation, and `$9FA8` delay/yield contract. The
  presenter runs at a fixed 60.0988-Hz source-frame clock. On each modeled
  release it commits any staged palette packet first, raises one NMI-ready
  latch, then advances the scheduler.
- `$DF` indexes the byte-verified compact pause table at ROM offset `0x0AF6`;
  `$DF` resolves to 240 scheduler releases. The palette step data and renderer
  inputs remain the existing ROM-derived project resources.
- The first replay's frame-end RAM shows `$0005=$EF` on the same frame as the
  `$DF` dispatch after F8 cleanup. The presenter applies one source-evidenced
  release-phase credit to that pause while retaining the ROM value 240. The
  later loop's `$DF` uses the ordinary countdown; the exact NMI latch/subframe
  cause is not cycle-verified. See
  `reference/rom_extract/intro/f8_00_sequence_trace.md`.

The implemented byte path and capture-aligned scheduler behavior are:

| Command | Script CPU address | Prototype behavior |
| --- | --- | --- |
| `E8 01`, `F9 00` | `$A020`, `$A022` | Dispatch in source frame 8. F9 keeps its script pointer at `$A022` through two separate one-count waits. |
| F9 first wait | `$8BB0` | `$8AF7` background-00 loader yields once; its saved return is `$8BB2`. |
| F9 capacity wait | `$9B2E` | On the traced resume, `$0628=$39` plus `$0629=$04` reaches `$3D` and yields once more; F9 still points at `$A022`. |
| `FB 01 8D`, `E9` | `$A024`, `$A027` | Dispatch in frame 10 after F9 completes; E9 yields two releases before fade-up. |
| `DF` | `$A028` | Dispatches after fade-up in frame 27 and yields 240 releases. |
| `EA` | `$A029` | Resumes in frame 267 and stages one fade-down level per release. |
| `ED 58` | `$A02A` | Dispatches in frame 282; emits the raw ROM sound cue `$58` (Sound 00), then continues the script. |
| `DC` | `$A02C` | Uses the ROM compact-pause table's 60-release delay; the trace resumes at `$A02D` in frame 342. |
| `F1 01` | `$A02D`, `$A0D2`, `$A14C` | The three synchronized captures use direct, buffered, then direct output. The presenter reads four `$BB9A` records from the byte-preserved packet resource; direct writes apply in the captured frame, while the buffered occurrence queues 11 zero rows followed by the four records through `$9B28` and NMI commits. Exact sub-dot edges remain unmodeled; other F1 occurrences fail closed. |
| `EC 00` | `$A02F` | In frame 342, selects pointer `$BD0C`; the first packet group is decoded on the first `$89FF` call after a nonzero-speed text glyph wait, at frame 380. Later groups count down on the same ROM call path. |
| `EC 05`, `EC 02`, `EC 04` | `$A0D4`, `$A14E`, `$A1B8` | Select pointers `$BD4E`, `$BD24`, `$BD41`; the text wait call path stages first groups at frames 1120, 1780, and 2369, then commits on the next NMI. EC 02 naturally holds `$0652/$0653=$84/$01` through its `$DB` pause at frames 1800–1839 because no glyph speed-wait calls `$89FF`. |
| `EC FF` | `$A08D`, `$A120`, `$A190`, `$A1FB`, `$A22F` | Clears the stream active byte `$0652`; the delay, saved base pointer, and already staged packets are preserved. |
| `F9 01` | `$A031` | Dispatches in frame 342. The ROM-derived producer stages attr-first and four-row packets; `$9B28` capacity yields fill the NMI queue from frames 344–378. The script pointer advances in frame 378; the final five packets/17 writes commit in frame 379. |
| `F9/FA` other extracted IDs | Later commands | A shared loader validates each selected layout, block record and tile-placement map before staging attr/tile-row packets through the same `$9B28` queue. Later IDs' packet order and frame batches remain inferred from the traced F9 01 pattern. |
| `FB 01 6E` | `$A033` | Selects the ROM-derived runner animation. `rom_runner_motion_record.gd` reads the verified `$6E` F1/F7 bytes and ROM tick table, then executes the source-confirmed `$975B` velocity/position update on a 16-byte record. The live `$94/$95=$0568` bridge and F7 timing are source-traced; same-input Godot RAM/OAM/raster comparison remains pending. See `reference/rom_extract/intro/runner_motion_live_bridge.md`. |
| `F8 0A` | `$A036` | Clears the traced runner motion bytes `$000D/$000E`; it does not perform movement. |
| `F8 00` | `$A29B` | Runs bank-2 service `$A4C0`: 15-step background fade, 16-release pause, 48 OAM-Y shifts, `$17` preclear/background load, preset/palette setup, 51-step raster-state loop, 240- and 60-release pauses, paired 15-step fade, and OAM/PPU cleanup. It returns `$02`, advancing exactly two bytes. All 42 loader waits, 16 preclear rows, and all 240 record packets are traced. Header bit 7 selects the bank-8 `$1100` block page; the silent live trace verifies the 48 row-major block calls, all selected source bytes, and every queued packet header/address/payload. The PPU snapshot differs only by the expected cursor overlay; Godot's post-correction output and raster timing remain unverified. See `reference/rom_extract/intro/f8_00_sequence_trace.md`. |
| First post-F8 `DF` | `$A29D` | ROM delay is `$F0` (240); frame-3968 RAM is already `$EF`, so the presenter carries one same-frame release phase into this wait. The next loop's `$DF` uses the ordinary countdown. |
| `F3 00` | `$A038` and later scenes | Selects the background palette from the active F9/FA record and the sprite palette index from the last FB animation header. All seven later scene pairs are backed by `reference/rom_extract/intro/later_f3_f4_palette_selection_trace.md`. At `$A038`, the `$9B28` capacity check yields once at cursor `$20`; the palette stages in frame 379 and commits on the next NMI. |
| `F5 00`, `ED 68`, `F2 05` | `$A03A–$A03E` | Records `$4C=$80`, emits the raw audio cue `$68`, and sets text speed `$55=5`. |
| `F2`, text glyphs, `FC`, `E0–E7` | First text at `$A03E`; 30 FC sites | F2 changes speed only. Synchronized first-pass F2 anchors show `$51:$53 = 49 22 4A` at eight fresh-line entry PCs; the presenter seeds `$2249` there without claiming F2 caused the reset. Glyphs advance a line column; FC waits four releases, adds `$0040` to the base and resets the column. Rewind commands update the column. Initial glyph NMI writes are bus-verified; later post-FC commit/raster timing remains unverified. See `reference/rom_extract/intro/text_cursor_queue_trace.md`. |
| `F4 04/05` | Later script positions | Models four `$9A71` palette packets and four release waits per pass. F4 04 uses slot-7 values `[0F,10,20,30]`; F4 05 uses `[30,20,10,0F]`. |
| `FD` | Nine captured first-pass calls | First eight captured calls directly clear 8×21 zero bytes from `$2249`; the final call queues 8×24 bytes from `$2246` over four NMIs. Dispatch mode/address/width are capture-anchored and use the shared NMI queue; full scroll/raster screen-space placement and other FD contexts remain unknown. See `reference/rom_extract/intro/fd_scene_clear_trace.md`. |
| `EE` | `$A08F` and later | Applies the ROM-confirmed 11×30 clear at `$2221`; exact within-frame bus timing is not modeled. |
| `FE 20 A0` | `$A29E` | The parser recognizes this verified three-byte unconditional script jump and resets only its cursor to `$A020`, incrementing `script_loop_count`. The ROM handler writes `$004D/$004E` and returns to `$84E7`; it does not reset the rest of the presentation state. Unsupported commands still stop the bounded prototype. See `reference/rom_extract/intro/title_transition_pc_trace.md`. |

## Timing assumptions and limits

- The ROM's `$9F69` writes `$FF` to the worker's `$0005` task byte; `$9EED`
  treats this value as ready on the next scheduler scan. The prototype
  registers that ready state without a finite task delay.
- The trace `reference/diagnostics/opening_first_nmi_anchor_audit_20261024.md`
  records the first worker dispatch at source frame 8/cycle 224,570 before the
  first NMI at frame 9/cycle 238,264. The first NMI sets the ready latch at
  cycle 240,148 and the scheduler scans at 241,107. The presenter now starts a
  non-NMI initial ready scan at frame 8 and models the first NMI-ready release
  at frame 9. This preserves the observed dispatch order without counting a
  fabricated NMI. The scan is still a frame-boundary model of the main-task
  yield rather than full 6502 execution. `$0001=$08` is the startup RAM-clear
  pointer incremented at `$C675`, not a task delay. The trace does not model
  every reset instruction or exact PPU color edge.
- `$F9 00` keeps its observed initial/logo path; the later `$F9 01` path is
  modeled from the ROM record and blocks. Its background record selects CHR
  banks 60–63 and palette record 02. The producer creates one attribute packet
  followed by four tile-row packets for each 4×4 block. The `$9B28` guard is
  `cursor + payload_size < $3D`; its three-byte packet header and terminator
  fit within the `$05E8–$0627` buffer. Grouping those packets with the observed
  NMI drain order reproduces all 36 frame batches (344–379), including the
  final next-NMI commit. See
  `reference/rom_extract/intro/f9_task_timing_trace.md` and
  `reference/rom_extract/intro/cold_start_palette_nmi_commit_trace.md`.
- The source-frame 8/9/10 landmarks are observed capture anchors. The exact
  subframe phase of the loader resume, buffer-capacity retry, scheduler delay
  decrement, and NMI release remains unresolved.
- The observed `$FE $A020` loop at source frame 4207 is followed by the same
  `$A03E F2` dispatch at frame 4578; together with its first occurrence at 379,
  this gives a 4199-frame capture period for phase-normalizing the known F1,
  EC and FD handler anchors. It is a replay-derived period, not a CPU-cycle
  proof of every later loop.
- F8 `$00` uses the ROM helper waits and effects recorded in
  `reference/rom_extract/intro/f8_00_sequence_trace.md`. The 16×32-byte
  preclear, 15 preclear capacity retries, explicit `$8BB2` yield, 26 record
  capacity retries, 51-step `$44/$79/$7C` loop, two long waits, and both palette
  fades are modeled. The background `$17` packet destinations/order and NMI
  grouping match capture. The header-selected page-1 block records and all 240
  live queue packets match the source bytes and expected order. `$9049` maps
  attribute addresses for this title layout and `$903A` queues all 48 raw
  attribute values; the unobserved `$8FD8` merge branch and its `$064A` scratch
  meaning remain open. Exact subframe NMI/raster timing and post-change Godot
  rendering remain unresolved; do not call this interval exact.
- The `E9` two-release pre-wait, 15 palette-building passes, `$DF` delay table
  value, `$EA` per-release fade steps, and NMI-before-scheduler ordering are
  source- or capture-backed. The source-frame landmarks are cross-checks, not
  the dispatch schedule; the scheduler and extracted bytes drive this slice.
- `$ED` queues its sound ID and advances by two bytes in the observed path; it
  does not terminate the cutscene task. The `$DC` delay is ROM table entry 60,
  cross-checked against the live `$F1 01` dispatch at frame 342. At this
  occurrence, zero `$4A/$4B` brightness takes `$97B6` to the direct drawing
  path at `$9819`; it does not skip the selected graphics. The presenter
  validates the four `$BB9A` packets against their preserved byte stream and
  writes them in the two observed modes: direct for frames 342/1760, buffered
  for the `$A0D2` occurrence at frame 1108. The buffered path stages one 30-byte
  zero-fill row at a time and then the four table records through the shared
  queue; commit frames 1109–1120 follow the trace. Entry-cycle brightness at
  `$A14C` remains unknown despite its captured direct writer. Exact PPU pixel
  edges remain unresolved.
  EC selectors 00/05/02/04
  select byte-verified bases `$BD0C/$BD4E/$BD24/$BD41`; the player uses the
  verified group grammar and packet layout. The ROM call path
  `$84FC → $895D → $896D → $89FF` now drives consumer ticks from each
  positive-speed glyph wait, removing the four capture-based first-record
  anchors and the EC 02 pause frame gate. Targeted RAM/PPU state checks and
  selected rendered frames match the synchronized references; see
  `reference/diagnostics/opening_runtime_anchor_audit_20261026.md` and its
  `opening_runtime_ec_callsite_timing_20261026/` artifacts. `EC FF` clears
  `$0652` without clearing `$0653` or pending packets. See
  `f1_01_graphics_gate_trace.md`, `ec_00_pointer_trace.md`, and
  `ec_nonzero_pointer_stream_trace.md`.
- F3 00 reads the background palette index from the active record byte 2 and
  the sprite palette index from the last FB animation header. The 144-byte
  sprite palette table at ROM `0x00D310` and verified animation header bytes
  are preserved as raw resources with sidecars. All seven later palette pairs
  match source-table bytes and frame-end RAM. The first queue wait at frame 378,
  stage at 379, and frame-380 palette bytes match source traces.
  `F2` text speed is applied as the captured number of scheduler releases per
  glyph. First-pass capture anchors seed the observed `$2249` line origin at
  eight fresh-line F2 entry PCs; this records the observed state without
  attributing the reset to F2. FC advances the source-traced base by `$0040`
  and resets the glyph column. Initial glyph NMI writes are bus-confirmed;
  later post-FC NMI timing and raster-visible text remain unverified.
- The runner uses the ROM-derived `$6E` frame descriptors and their declared
  2/6-tick holds. The position recurrence and start frame are capture-derived
  from RAM snapshots; they are not presented as a fully traced CPU update
  routine. Raster CHR split, sprite overflow/priority edge, and exact visible
  pixels remain outside the current renderer.
- `FB` now creates one ROM animation renderer per active ID, including the
  observed 8D, 6E, 75, C1, 82, 76, 84, 77, C0, A2, 7D, 7C and 0D IDs. The
  first listed object draws in front, matching observed OAM allocation order.
  Five hidden/offscreen descriptors differ in sampled multi-object scenes;
  sprite limit/overflow evaluation, F7-driven positions, lifetimes outside an
  FB set and title priority mutations remain unmodeled. See
  `reference/rom_extract/intro/opening_fb_animation_coverage.md`.
- The isolated field screen consumes committed PPU-address bytes through
  `RomPpuNametableScreenRenderer`. It selects CHR banks and palettes from
  extracted background layouts. Background 01 uses banks `[60,61,62,63]` above
  and `[0,1,2,3]` below an approximate row-134 split. The zero-scroll view does
  not yet include horizontal mirroring, full OAM composition, PPU fetch timing,
  or scanline-visible edges. It has not been runtime-validated.
- At `ED 58` the prototype emits `rom_sound_requested(0x58, source_frame)`.
  The verified driver lookup maps runtime cue `$58` to Sound 00, but this
  isolated scene does not connect the signal to an audio player.
- This is a bounded command/scheduler prototype, not a full cutscene VM or NES
  emulator. F9 01's packet addresses, bytes, batch boundaries, F3 palette
  packet, first text glyph, and NMI transfer frames are source/capture matched;
  exact subframe timing, post-FC text visibility, later background packet timing,
  complete OAM/raster drawing, audio hookup, and title transition remain
  incomplete. Do not describe it as a verified exact opening. No Godot runtime
  validation or same-input visual/audio comparison was performed for this
  integration.


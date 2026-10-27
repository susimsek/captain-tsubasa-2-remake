# Godot title handoff: queue implementation and remaining gaps

> **Status:** `scripts/title_rom_handoff_queue.gd` now applies the source-
> ordered title queue progressively. It computes producer yields from the
> `$3D` queue-capacity rule and each packet's actual encoded size; the result
> matches the observed 26 groups of nine and final group of six. The integrated
> Godot output matches FCEUX frames 4692 (`KICK OFF`) and 4694 (`CONTINUE`)
> pixel-for-pixel. Start polling, the first producer-release phase, and CPU/NMI
> subframe timing remain open.

## Result

The remaining gap is CPU-exact execution of the title PPU queue, not discovery
of the `$17` layout or packet capacity. Godot intercepts Start, freezes the
opening presenter, and models the black transition while staging and committing
the decoded `$17` packets. Packet groups are now produced by the ROM queue
capacity rule; commits still happen on modeled frame edges. The ROM's Start
poll, `$8AF7` call, first task-release phase, and cycle-level NMI routine are
not executed. The milestone still stops with both title choices visible and
neither confirmed.

## ROM identity and direct byte checks

Reference: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Its PRG+CHR payload MD5 after removing the 16-byte iNES header is
`eaf2b3745263efa4b1afd2b400f68dae`, matching the replay metadata.

| CPU entry | ROM file offset | Bytes / checked effect |
| --- | ---: | --- |
| Bank-0 `$806A` | `0x00007A` | `A9 17 20 F7 8A`: select background `$17`, call `$8AF7`. |
| Bank-0 `$806F` | `0x00007F` | `A9 30 20 0C 89 20 FB 88 20 35 9A`: title sprite/OAM and palette setup helper calls. |
| Bank-2 `$A000` | `0x004010` | NMI `$05E8` queue consumer entry, reached through the traced `$C76E → $C421` route. |
| Bank-2 `$A03C` | `0x00404C` | `8D 07 20`: `STA $2007`, the queued payload write observed in the synchronized bus log. |

The bank-0 offsets use the `$8000` bank window; the bank-2 offsets use PRG
bank 2 mapped at `$A000` (`file 0x004010 + (CPU address - $A000)`). The
direct bytes and broader title helper behavior are recorded in
`title_menu_source_trace.md` and `cold_start_palette_nmi_commit_trace.md`.

## Same-input evidence and source-frame map

The silent FCEUX replay uses the same per-frame input timeline as the opening
capture. In `reference/opening_timing_capture_20261024_125300/metadata.txt`,
`source_frame = emulator_frame_after` and `script_frame = source_frame + 1`.
The ROM MD5 matches the local source ROM above. Relevant title-entry trace
metadata is in
`reference/diagnostics/title_entry_setup_20261024_201420/metadata.txt`;
the title-control-flow trace is in
`reference/diagnostics/title_transition_pc_20261024_150231/`.

- Start is polled by the bank-0 loop `$8027–$8032`; the observed Start edge is
  source frame 4661. The PPU palette is all `$0F` on frames 4662–4691 and the
  title palette is restored in frame 4692. `$0F` maps to black in the
  documented FCEUX palette.
- The title background call `$806A → $8AF7(A=$17)` begins at frame 4664;
  `$806F` resumes at frame 4690. The silent live trace verifies all 48 ROM
  block requests, selected page pointers, 768 tile bytes, 48 attributes, and
  all 240 queued packet headers, addresses, order, and payloads. Live producer
  batches are 26 groups of nine packets followed by a final group of six;
  Godot derives the yields by filling the `$3D` queue from packet sizes.
- The PPU bus trace records `$A03C` writes on frames 4665–4691. Their payload
  counts sum to 816 bytes, matching 768 tile bytes plus 48 attributes; this is
  the delayed NMI consumption of the title queue. The writes occur in vblank
  (observed scanlines 246–254), but exact subframe phase is still open.
- At frame 4691, title setup stages a 32-byte palette packet and cursor tile
  `$7F` at `$220A`. Frame 4692 records 33 `$A03C` writes: 32 palette bytes and
  the cursor byte. The resulting PPU palette and cursor match the frame-4692
  snapshot; `$224A` remains zero, so `KICK OFF` is initially selected.

These facts establish the source-frame interval and the queue's complete
content. They do not prove the first visible title pixel's dot or the CPU/NMI
subframe phase.

## Godot runtime verification

A silent Godot 4.7.2 harness instantiated `scenes/main.tscn`, sent Enter/Start,
and advanced the opening/title transition at 60 Hz. The black overlay remained
visible for elapsed frames 1–30; the title appeared at elapsed frame 31 when
the final palette/cursor queue completed. The focused queue harness checked
all 240 ROM-derived packet contents, destinations, and commit order; queue fill
now uses the source `$3D` capacity rule rather than a fixed packet count. The
harness then sent Down through the title menu and checked the one-frame cursor
update.

The generated Godot endpoint at source frame 4692 matched the FCEUX
`KICK OFF` frame in all 61,440 RGB pixels. The frame after Down, 4694, likewise
matched all 61,440 pixels of the menu probe's `CONTINUE` frame. The generated
images, FCEUX references, hashes and queue-state record are preserved in
`reference/diagnostics/title_godot_verification_20261024/comparison.json`.
These PNGs were generated from ROM-derived Godot runtime resources; the FCEUX
captures were read only for comparison.

## Current Godot behavior and implemented slice

The repeatable input-side check `tools/diagnostics/verify_title_cursor_controls.gd`
injects key and joypad events through the root viewport's input path and
exercises the decoded Up, Down, and Select paths: Down selects PPU cursor
address `$224A`, Up returns to `$220A`, and Select toggles between them. It
checks that the old PPU cursor remains until the one-frame commit, and confirms
that Start at the title endpoint does not activate either option. It passed on
2026-10-25 under Godot 4.7.2 with keyboard and gamepad Down/Up/Select; Start
remained unconfirmed. This checks Godot's action/PPU state against the
byte-checked `$80A2` menu loop and `$80BC` Select branch; only the Down pulse
currently has a separate FCEUX screen probe, so the other input paths are not
claimed as pixel-compared against live emulator output. Run with
`godot --headless --path . --script tools/diagnostics/verify_title_cursor_controls.gd`.

`scripts/opening_source_runtime.gd` consumes Start as a UI event, calls
`freeze_source_for_title_handoff()`, stops the music after the next nominal
frame edge, and reveals `TitleMenu` when the queue runner completes. The
resulting endpoint has 30 black frames and appears on elapsed frame 31. It
does not execute the ROM's Start poll or title setup path. The source presenter
does model the separate earlier F8 `$00` presentation service; that service is
not the interactive Start-to-title transition traced here.

`RomTitleBackgroundLoader.build_packets()` creates the source-derived
240-packet `$17` stream. `scripts/title_rom_handoff_queue.gd` begins production
after a modeled three-frame release and fills the queue until adding the next
packet would reach the ROM `$3D` cursor limit. The pending group commits on the
next modeled frame, then production resumes. This derives the observed 26
groups of nine plus six from packet bytes rather than storing those group
sizes. After the last background drain, it stages the ROM background/sprite
palette and `$7F` cursor packets; the next modeled commit completes the queue
and reveals the title. The renderer applies commits to evolving PPU memory and
draws from ROM CHR and palette data. The first producer release and NMI frame
edge remain capture-aligned; Godot does not execute the original producer or
NMI CPU instructions.

The remaining CPU-exact implementation should follow these rules; the current
frame runner does not yet execute the original producer/NMI instructions:

1. Keep Start as a one-frame input edge and transition into a title-handoff
   state rather than freezing the source presenter outright.
2. Execute the ROM's Start poll, `$8AF7` producer, scheduler back-pressure, and
   `$A000/$A03C` NMI consumer with source-cycle timing. The Godot queue already
   uses the `$3D` capacity rule, preserves packet order, waits for modeled
   drains, and reveals only after palette/cursor commit.
3. Keep title option confirmation outside this state machine.

The current implementation matches the observed queue contents, source-frame
boundaries, final PPU memory and selected endpoint pixels. Derive the initial
producer-release phase and commit edge from the ROM scheduler next, then refine
CPU-cycle ordering, `$8FD8` attribute merge, and subframe visibility.

## Still unresolved

- Exact CPU-cycle phase for the Start poll, task handoff, NMI, and title reveal
  in Godot; current evidence gives source-frame boundaries only.
- First visible title scanline/dot and the full MMC3/PPU raster state.
- `$8FD8` partial-attribute merge and `$064A` scratch semantics (not needed by
  the direct title layout path already traced).
- Whether every input held across the transition should be treated as one
  edge; the capture holds Start for several frames, but the menu confirmation
  route is intentionally outside this milestone.

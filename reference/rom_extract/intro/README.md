> **Correction (24 Oct 2026):** The FC-aware 1,724-byte stream and its 62 events below were generated with a counted-FC assumption now disproven for the captured cold-start path. Treat those files as preserved research artifacts, not a verified execution parse. See `fc_counted_block_trace.md`.

# Turkish ROM opening command data

`cutscene_00.bin` is the unmodified 641-byte pointer-to-next-pointer span from
the supplied ROM, file offset `0x006030–0x0062B0` inclusive (PRG bank 3, CPU
`$A020–$A2A0`). This is archival lexical evidence, not the complete execution
range: the next pointer `$A2A1` is another entry start. A former FC-aware entry-0
stream is preserved separately as `cutscene_00_execution.bin`, 1,724 bytes
from file `0x006030` through `0x0066EB` inclusive. Its `$A6DB` end is not
verified as reachable after the FC correction. `cutscene_00.json` records both ranges and their hashes, source
offsets, plus byte-exact background/animation records. All source values come
from the ROM; no emulator image, audio recording, or disassembly source is
copied here.

An isolated Godot command-state VM reads the generated project-only data at
`assets/opening/rom_logic/cutscene_00_vm.json`; see
`scripts/opening/rom_cutscene_vm.gd` and `docs/opening-cutscene-vm.md`. The original pointer-span lexical export has 181 records. A former FC-aware parse emitted 62 records, but its counted graphics-payload assumption is withdrawn and its event boundaries are not execution evidence. Entry-alias and boundary evidence is in
`fc_scene_boundary_audit.md`; FC's exact PPU output and timing are still
unknown. The VM is not wired to the main scene and does not reproduce the full
PPU/animation renderer or exact visible frame timing. Byte-traced dialogue
handlers, `$55` text-speed samples, and first-screen command boundaries are in
`reference/rom_extract/intro/dialogue_timing_observations.json`.

The ROM's hash is in the JSON. `tools/extract_intro_cutscene.py` reproduces the
extraction. Offsets count from byte 0 of the `.nes`, including the iNES header.

The opening's `$EC 00`, `$EC 02`, `$EC 04`, and `$EC 05` commands select
separate stream pointers in PRG bank 6, then use the same three-packet PPU
consumer. The 512-byte source segment `$BD00–$BEFF` is preserved byte-for-byte
as `ec_bank6_bd00_beff.bin` with source offset, ROM hash, and extract hash in
its JSON sidecar. `scripts/opening/rom_ec_stream_decoder.gd` checks that hash
and decodes the pointer table, stream bytes, and 12-byte payload groups.
`scripts/opening/rom_ec_stream_player.gd` now advances on the byte-verified
`$84FC → $895D → $896D → $89FF` text-wait call path, with base-relative `$FE`
loops, `EC FF` active-flag clears, and next-NMI writes. The four first-record
anchors and special EC `$02` pause gate have been removed. Frame-level RAM and
target PPU bytes match the synchronized references across 1,377 selected
frames; see `docs/rom-ec-stream-player.md`, `ec_00_pointer_trace.md`,
`ec_nonzero_pointer_stream_trace.md`, and
`reference/diagnostics/opening_runtime_anchor_audit_20261026.md`. Exact
CPU-cycle and sub-frame PPU visibility remain unresolved.

The first field scene's `F3 00` selects background palette 02 and animation
palette index 00. The sprite palette record at ROM file `0x00D310` / bank-6
CPU `$B300` is preserved as `animation_00_sprite_palette.bin`; run
`tools/extract_animation_palette_00.py` to reproduce it from the hash-verified
ROM. Its sidecar records the source bytes and PPU frame-380 cross-check; only
the original ROM bytes are used by the runtime palette builder.

## Proven opening flow

At cold start, bank 0 executes `LDA #$00; JSR $8464` at file
`0x000033–0x000037` (CPU `$8023–$8027`); the `JSR $8464` itself begins at
file `0x000035` / CPU `$8025`. File `0x000032` is the high operand byte
`$9B` of the preceding `JSR $9BA0`, which begins at file `0x000030` / CPU
`$8020`. The `$8464` dispatcher uses the bank table at `0x000AFE` to route
scene 0 to PRG bank 3; that bank's first pointer is `$A020`.
The Turkish ROM uses a compact script format: text tile IDs are `00–D7`,
`D8–DF` are one-byte pauses of 1/10/20/40/60/80/120/240 frames, `E0–E7`
move the text cursor backward by 0–7 tiles, and `E8–FF` are multi-purpose
control commands. This differs from a separate English translation's script
data. The main cutscene interpreter in bank 0 matches the supplied ROM's bytes
at the offsets cited in the JSON; third-party English script text must not be
used as source material for the Turkish version.

The text cursor and `$05E8` glyph packet path after `F2`/`FC` is traced in
`text_cursor_queue_trace.md`. It documents the little-endian `$51:$52` base,
per-glyph `$53` advance, FC's one-byte `$0040` line step, and the observed
`82 <low> <high> 00 <tile>` packet. Post-FC NMI commits and visible pixels
remain unverified.

The event list can be grouped at its screen changes:

| Script offset | Scene setup and key source commands |
| --- | --- |
| `0x006030` | Tecmo Theater background `00`, animation `8D`, screen on, 240-frame pause. |
| `0x00603A` | Sound command `58` starts the opening cue; background `01` and animation `6E` start the field sequence. |
| `0x0060A0` | Background `03`, animation `75`: Tsubasa portrait/card. |
| `0x0060CD` | Background `08`, animations `C1`, `82`: Hyuga action. |
| `0x006133` | Background `07`, animation `76`: Hyuga portrait/card. |
| `0x006160` | Background `09`, animation `84`: next action sequence. |
| `0x0061A3` | Background `03`, animation `77`: next portrait/card. |
| `0x0061CA` | Background `0A`, animations `C0`, `A2`, `7D`: goal/action sequence. |
| `0x00620E` | Background `0B`, animation `7C`: goalkeeper portrait/card. |
| `0x006242` | Animation `0D` and final text tiles, then fades/pauses; `0x0062AE` jumps back to `$A020`. |

The script has no `EB` wait-for-input command. It loops through the opening on
its own. Bank 0 polls Start from a loop entered at CPU `$8027` (file
`0x000037`): `JSR $9FA8` at `$8029` yields through the cooperative scheduler,
`LDA $1E; AND #$10` at `$802C–$802F` checks the Start bit, and `BEQ $8027` at
`$8030` repeats while Start is clear. A set bit falls through at `$8032`.
That route issues sound command `01` to stop audio, loads title
background ID `17` and animation `0D`, and places the initial cursor at PPU
address `$220A` (`KICK OFF`). Select toggles between `$220A` and `$224A`
(`CONTINUE`); Up selects `$220A`, Down selects `$224A`; Start confirms. A and B
are excluded by the menu's input mask. The current Godot milestone stops at
that title menu and therefore does not take the confirmation branch.

The first-pass tail's `F8 00` at `$A29B` dispatches bank-2 service `$A4C0`,
returns A=`$02`, and advances exactly two script bytes to `$A29D` (`DF`). Its
captured sequence fades to black and queues a `$23C0–$23FF` fill; it is not the
later interactive Start-to-title handoff. See `f8_00_sequence_trace.md` for
the source call chain, capture limits, and remaining helper gaps.

## Decoded graphics records

`tools/decode_intro_background.py` expands all nine backgrounds referenced by
this milestone (`00`, `01`, `03`, `07`, `08`, `09`, `0A`, `0B`, and title `17`)
into `background_XX_layout.json`. The first two bytes of each record select two
2 KiB CHR banks; the third byte's low six bits index a 16-byte background
palette in PRG bank 6 at CPU `$B000` (ROM file `0x00D010`). Bytes 3 and 4
count metatile rows and columns, and byte 5 packs the starting nametable
position. Each following metatile ID indexes a 17-byte entry in PRG bank 8:
one NES attribute byte plus sixteen 8x8 tile IDs. The base page starts at file
`0x010010`; record palette-flag bit 7 moves the selected block page by
`0x1100` through `$5B.0` and `$8EF0`, making its base `0x011110`. The decoder
preserves base records in `block_XX.bin` and selected-page records in
`block_XX_page_11.bin`, records the page and offsets in each layout, and
produces tile/palette placements from the selected bytes. Its output is layout
data, not a screenshot.

For background `01` (field), this ROM-only decoder produced 1,024 tile IDs
and 64 attribute bytes. They match the independent frame-380 PPU capture in
all 1,024/1,024 and 64/64 positions, respectively. This supports the metatile
layout and palette-quadrant decoding for that background. Background `09`
also matches all 512 tile IDs in the frame-1780 PPU capture. Background `00`
(Tecmo Theater) is also decoded as three 4x4 blocks at PPU `$218C`, but its
final displayed image includes additional animation/composition work, so its
full frame has not been matched. Background `17`'s header-selected block page
now matches the title PPU nametable bytes apart from the visible cursor tile;
its packet timing, raster composition and full rendered frame still need
matching.

Animation `8D`, selected with the logo, has exact bytes `36 F1 30 28 91 5B
FF` at ROM `0x0143E3`. The byte-verified interpreter reads `36` as the sprite
palette index, `F1 30 28` as initial Y/X coordinates, and `91 5B` as a sprite
frame reference at CPU `$B15B` in PRG bank 10 (ROM `0x01516B`). The first four
bytes there, `7C 71 52 53`, are sprite CHR selectors. `FF` ends that animation
stream. All 13 referenced animation records now have a conservative decode of
their linear entry command sequence in `cutscene_00.json`. Animation loops and
jump targets still need the interpreter to determine their complete playback;
sprite frame composition and OAM placement also remain to decode.

## What remains to decode

Text is stored as tile IDs, so the JSON intentionally preserves IDs instead
of substituting guessed Unicode. Rendering all records with exact scroll,
sprite priority, palettes, and per-frame timing requires more work. Pause
values are exact ROM operands; total visible scene duration also includes
text speed, graphics routines, fades, sound, and hardware scheduling.

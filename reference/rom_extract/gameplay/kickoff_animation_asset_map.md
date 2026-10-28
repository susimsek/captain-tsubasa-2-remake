# KICK OFF Cutscene Animation Assets

This export follows animation calls in the corrected, byte-boundary-verified
cutscene 1 and 2 event manifests. It preserves the animation source records
from the supplied Turkish ROM and derives timing and sprite-frame descriptors
with the existing ROM bytecode decoders. No emulator screenshots, captured
OAM, or captured WAV files are used as source assets.

## Source and extraction

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- Event inputs: `assets/gameplay/rom_logic/kickoff_cutscene_01_events.json`
  (222 events) and `assets/gameplay/rom_logic/kickoff_cutscene_02_events.json`
  (45 events); each manifest records the same ROM hash and verified event
  boundaries. `$FC` is a one-byte handler with no inline payload.
- Rebuild command: `python3 tools/gameplay/extract_kickoff_animation_assets.py`
- Existing decoders reused: `tools/extract_intro_cutscene.py` for animation
  entry commands, `tools/decode_intro_animation_timing.py` for animation
  interpreter ticks and frame selections, and
  `tools/decode_intro_sprite_frames.py` for ROM sprite-frame command graphs.

The animation dispatch mapping used by the existing cutscene extractor is
`$00–$6C` → PRG bank 9, table index equal to the ID; `$6D+` → PRG bank 10,
table index equal to ID minus `$6D`. Each pointer table starts at CPU `$A000`.
The resulting source spans are listed in `animations/kickoff/animation_index.json`.

## Extracted resources

The cutscene event streams invoke 16 unique animation IDs in 17 animation
events: `$0B, $12, $14, $15, $17, $2A, $2B, $2C, $3B, $3C, $50, $51, $6D,
$C6, $C7, $CB`. The `animation_XX.bin` files are byte-preserved source records.
The index stores source bank, pointer-table address and index, source CPU and
file offsets, byte length, SHA-256, bounding method, entry-path decode, and
each event invocation.

| Cutscene | Animation IDs |
| --- | --- |
| 1 | `$0B, $12, $17, $2A, $2B, $2C, $3B, $3C, $50, $51, $6D, $C6, $C7, $CB` |
| 2 | `$14, $15` |

`animation_timing.json` contains timing-decoder command traces and wait beats
for all 16 records. It currently reaches a decoder-reported unresolved `FA`
branch for IDs `$0B, $2A, $2B, $3B, $3C`; those tracks must not be treated as
complete animations. IDs `$15, $17, $2C, $50, $51, $6D` terminate without a
wait beat in the decoded path; the record bytes are preserved, but no positive
display duration is inferred by this export. The other records have decoded
wait commands, expressed as animation-driver ticks rather than cutscene frames.

`sprite_frames.json` contains 19 unique decoded sprite-frame command graphs
selected by linear animation entry paths, timing-decoder commands, and both
ROM pointer operands at each reachable `$FA` dialog branch. Each frame retains
ROM file offsets and raw command bytes, the four CHR selectors, sprite tile
IDs, relative band offsets, palette low bits, and horizontal-flip flags.
Geometry counts range from 3 to 44 component sprites per frame. These are
descriptors of the source commands, not rendered sprite images.

For every `$FA` branch target, `frame_sources/manifest.json` records the exact
bank/CPU/file spans consumed by the ROM frame parser and their SHA-256 hashes;
the corresponding byte-preserved source spans are in `frame_sources/*.bin`.
Shared tails are emitted once. In particular, animation `$3B` at `$A47A`
selects `$B310` (state bit 0 clear) or `$AD8A` (state bit 0 set); both
42-descriptor frames are now in `sprite_frames.json`. The source trace and
remaining scene timing uncertainty are documented in
`meeting_menu/scene_44_animation_3b_fa_branch_20261027.md`.

Animation `$CB` is the final valid table entry. Its following 16-bit table word
is `$F53D`, outside the selected `$A000–$BFFF` PRG window, so the extraction
does not use it as an end pointer. The record is bounded by the existing entry
parser's reachable `$FF` exit at CPU `$A836`; its preserved bytes are at file
offset `$01483B`, length 12. The fallback and its method are recorded in the
index instead of silently treating `$F53D` as a real boundary.

## What this does not establish

These resources make source commands and frame geometry available for the
fresh-start route; they do not implement the scene. The following semantics
remain unresolved and must be decoded before claiming complete animation
playback or using the data as a final Godot rendering pipeline:

- Exact display cadence and scene/text scheduler interaction for the five
  `FA` animation branches. Both pointer operands and referenced frame command
  graphs are indexed, but the live per-scene selection timing is not.
- How the two cutscene event streams schedule animation instances, pause,
  restart, or remove them relative to scene waits and text commands.
- The `F7` physical-motion triples and how driver ticks integrate into screen
  coordinates and visible frames.
- Live MMC3 CHR bank selection at each sprite-frame fetch, including bank
  changes between frame commands.
- Sprite palette index resolution, full palette effects, OAM order/allocation,
  8-sprites-per-scanline clipping, priority, and update cadence.
- The mapping from decoded descriptors to final raster pixels and agreement
  with the same-input FCEUX route.

The output is therefore a byte-preserving source export plus partial static
decodes, not a claim that these scene animations already play correctly in
Godot.

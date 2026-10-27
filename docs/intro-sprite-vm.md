# Intro animation and sprite bytecode

The supplied Turkish ROM (SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`) is the data source. `tools/decode_intro_animation_timing.py` follows the bank-0 animation interpreter at CPU `$9154–$94D7`; `tools/decode_intro_sprite_frames.py` follows the bank-0 sprite parser at `$94D8–$96F1`. Their generated records are `reference/rom_extract/intro/animation_timing_entry.json` and `sprite_frames_entry.json`. Source offsets are preserved per command and sprite descriptor. No screenshot or captured pixels are used in decoding.

## Animation timing from ROM

The table gives **animation interpreter ticks**, not total scene duration. In the sampled opening, one tick agreed with one emulator frame for the cycles checked below. A normal duration opcode `00–7F` holds for twice its byte value; `F4 xx` is a direct `xx`-tick wait. Other commands set frame, position, mirror, motion parameters, or branch/repeat state.

| Animation | ROM-driven frame behavior | Entry/loop timing |
| --- | --- | --- |
| `8D` | Static Tecmo Theater logo sprite frame `$B15B` | Stream exits at tick 0; scene keeps the resulting sprite visible. |
| `6E` | Field runner frames `$A837`, `$A86F`, `$A8BA`, `$A908` | Each held 2 ticks for two four-frame passes (ticks 0–15); then each held 6 ticks, repeating every 24 ticks from tick 16. |
| `75`, `76`, `77`, `7C` | One portrait frame each | Each has a 60-tick hold, then stream exit. |
| `7D` | Ball/action sequence | First 48 ticks repeat `$AD72`; four-frame alternation follows, then a 4-tick cycle from tick 96. |
| `82` | Hyuga action sequence | `$ADF0` appears for three 20-tick holds; four-frame alternation follows, then a 4-tick cycle from tick 108. |
| `84` | Six alternating action frames | Each 2 ticks; entire loop is 12 ticks. |
| `A2` | Goal/action overlay | `$ADD6` held in 24 two-tick steps; exits at tick 48. |
| `C1` | Repeated overlay `$B711` | Three 20-tick holds; exits at tick 60. |
| `0D`, `C0` | Static title/overlay frames | Stream exits at tick 0; sprite object lifetime is decided by the calling scene. |

The frame `378` OAM shadow begins the `6E` four-frame sequence. Frame variants change at `378`, `380`, `382`, `384`, then continue at two-frame intervals through `392`; from `394` the six-frame holds begin (`394`, `400`, `406`, `412`, ...). Animation `84` changes variant every two captured frames at `1778`, `1780`, `1782`, ... . These independent captures support the decoded hold durations. They do not establish when every scene command was issued or when a PPU update became visible.

## Sprite composition from original bytes

Each sprite frame starts with four CHR selectors and a compact descriptor stream. The decoder provides tile ID, relative X/Y, palette low bits, and local horizontal flip. The original OAM shadow is ordered exactly as these ROM descriptors for the nine sampled frames below. The formula evidenced by those samples is:

- Normal X = live animation origin X + descriptor X.
- Mirrored X = live animation origin X − descriptor X.
- Y = live animation origin Y + descriptor Y.
- OAM attribute bit 6 = live horizontal mirror XOR descriptor flip flag. Attribute low two bits are the descriptor palette bits. The title sample also sets behind-background priority bit 5.
- A sprite crossing the left edge with computed X below zero is hidden in the OAM shadow with Y=`248` and attribute bit 2 set; X remains wrapped to a byte. This was checked on frame `380`.

`tools/analyze_intro_sprite_geometry.py` reproduces the comparison and writes `reference/diagnostics/intro_sprite_oam_matches.json`. CPU RAM snapshots are validation references only. For each listed sample, **all first-object OAM entries match exactly, byte for byte** (`Y, tile, attribute, X`):

| Captured frame | Animation/frame | OAM origin X,Y | Mirror | Exact entries |
| --- | --- | ---: | --- | ---: |
| 26 | `8D` / `$B15B` | 80,96 | no | 40/40 |
| 100 | `8D` / `$B15B` | 80,96 | no | 40/40 |
| 380 | `6E` / `$A86F` | −10,60 | yes | 42/42 |
| 480 | `6E` / `$A8BA` | 75,60 | yes | 41/41 |
| 803 | `6E` / `$A837` | 139,60 | yes | 42/42 |
| 880 | `75` / `$AA8C` | 120,96 | no | 39/39 |
| 1600 | `76` / `$AAE7` | 128,96 | yes | 42/42 |
| 2190 | `77` / `$AB4A` | 120,96 | no | 41/41 |
| 2800 | `7C` / `$AD14` | 136,96 | no | 40/40 |
| 4692 | `0D` / `$A7CB` | 124,124 | no | 63/63 |

Where a synchronized PPU dump exists (frames `26`, `380`, `803`, `1600`, `2190`, `4692`), all four sprite pattern slots `$1000–$1FFF` are byte-identical to the four 1 KiB ROM CHR banks selected in that frame's original data header. The analyzer checks each 1 KiB slot separately. This verifies the CHR selector mapping for those six samples; other frames still need their own PPU timing evidence.

For logo and portrait records, the live OAM origin equals twice the `F1 Y X` coordinate operands, modulo 256. For example, animation `8D` has `F1 30 28` (`Y=48, X=40`) and gives origin `(80,96)`; portrait `75` has `F1 30 BC` and gives `(120,96)`.

## Start to title sprite changes

The bank-0 Start-to-title branch applies two explicit sprite state changes after it loads animation `0D` and background `17`. All CPU/file addresses below were checked against the supplied ROM (file offsets include the 16-byte iNES header):

| CPU / ROM file | Original bytes | Effect |
| --- | --- | --- |
| `$8061` / `0x000071` | `A9 0D 20 97 82` | Load animation `0D` via `$8297`. |
| `$806A` / `0x00007A` | `A9 17 20 F7 8A` | Load background `17` via `$8AF7`. |
| `$806F` / `0x00007F` | `A9 30 20 0C 89` | Pass `$30` to `$890C`. |
| `$890C` / `0x00091C` | `85 ED A2 00 BD 68 04 18 65 ED 9D 68 04 E8 E8 E8 E8 D0 F1 60` | Add `$30` (48) to `$0468,X` for X=`0,4,...,252`, the Y coordinate field of 64 animation slots. |
| `$8074` / `0x000084` | `20 FB 88` | Call `$88FB`. |
| `$88FB` / `0x00090B` | `A2 00 BD 6A 04 49 20 9D 6A 04 E8 E8 E8 E8 D0 F2 60` | XOR `$046A,X` with `$20` for the same 64 slots, toggling behind-background priority bit 5. |

Title animation `0D` has `F1 26 3E`; its X origin is `$3E×2=124`. Its Y becomes `$26×2+$30=$7C=124`, exactly matching all 63 title OAM entries. The `$88FB` call explains their `0x20` attribute bit. These are ROM-proven transition effects, not calibration offsets inferred solely from an image.

This proves descriptor geometry for the sampled first sprite objects, not full scene pixels. Live origin/motion, scene scheduling, PPU clipping, and transfer timing still have to be integrated before claiming the opening is exact.

## Native Godot sprite-animation prototype

`scripts/opening/rom_sprite_animation_prototype.gd` is an isolated Godot renderer for ROM animation `0x84`. The preview scene is `scenes/prototypes/rom_animation_84.tscn`; it is not connected to the playable opening controller. The renderer consumes the byte-decoded timing track, sprite-frame descriptors, and exact `chr_rom.2bpp` bytes. It selects the four 1 KiB CHR pages named in each frame header, resolves tile IDs to 2bpp pixels, and applies descriptor positions, palette slots, horizontal mirroring, and descriptor/OAM draw order. Animation `0x84` has six ROM-selected frames held for two ticks each, forming a 12-tick loop.

The preview uses the sprite palette bytes verified for animation `0x84` at source frame 1780. The frame's PPU palette RAM `$3F10–$3F1F` is byte-identical to ROM palette record `0x30` at file offset `0x00D310`; the same PPU snapshot's background palette is byte-identical to background `0x09`'s record `0x03` at `0x00D040`. Its four sprite CHR pages also match that frame's selectors. These checks use PPU/RAM state as validation evidence only; no screenshot pixels are used. Project resource `assets/opening/rom_logic/animation_84_sprite_palette.json` preserves the ROM bytes, source offsets, snapshot hash, and RGB mapping from the external FCEUX 2.7.0 internal palette.

The animation timing uses `NES_FPS = 60.0988`, matching the project's NES playback clock. The sampled `0x84` pose changes at two-source-frame intervals, consistent with the ROM's two-tick holds. The verified sprite bytes and colors enable a colored sprite-only visual comparison, but do not yet justify main-scene integration: the full-screen background, PPU raster changes, and enclosing cutscene scheduler still need reconstruction. The palette resource records an observed byte match to palette record `0x30`; the code path translating the animation record's palette operand `0x00` into that selected record has not been fully traced.

## Reusable renderer and Tecmo logo pose (`0x8D`)

The isolated renderer now chooses decoded animation data and its palette resource from the exported `animation_id`; it handles timed tracks and a no-wait static pose. `scenes/prototypes/rom_animation_8d.tscn` selects `0x8D` and is a sprite-only preview, separate from the main opening scene.

Animation `0x8D` is a static ROM entry: animation bytes at file offset `0x0143E3` are `36 F1 30 28 91 5B FF`. The timing decoder resolves `F1 30 28` to initial coordinates `(Y=48, X=40)` and `91 5B` to frame `$B15B`; this frame is in PRG bank 10 at file offset `0x01516B`. Its header selects CHR 1 KiB pages `7C 71 52 53`, and its decoded descriptor stream supplies 42 sprite tiles. The existing OAM geometry audit reports all 40 captured first-object entries matching at frame 100. The renderer uses ROM CHR and descriptor bytes; no screenshot pixels are inputs.

The first byte of animation `0x8D` is `0x36`, and its ROM loader path is now traced. Cutscene command `FB 01 8D` dispatches through `$8830` to `$9085`. The loader selects PRG bank 10 for animation IDs `>= 0x6D`, resolves ID `0x8D` to the entry at CPU `$A3D3` / file `0x0143E3`, and stores the entry's first byte (`0x36`) in zero-page `$49` (`$90FF–$9101`). When the screen-update routine `$997E` loads palettes, it calls `$9B07`, which saves the current bank and maps bank 6; `$9ADA` computes source pointer `$B300 + 16 × $49`. For `$49 = 0x36`, that is CPU `$B660`, bank-6 file offset `0x00D670`. It copies 16 bytes to `$063A–$0649`.

The palette writer `$9A71` requests a 32-byte palette update beginning at PPU `$3F00`, then emits the 32 bytes from `$062A–$0649` through its palette conversion loop. Thus the latter 16 bytes occupy `$3F10–$3F1F`. At full brightness the conversion preserves the color values. The exact ROM source at `0x00D670` is `0F 05 16 15 0F 30 27 37 0F 10 0F 0F 0F 0F 00 30`; it matches the existing frame-100 PPU dump's `$3F10–$3F1F` bytes byte-for-byte. This establishes the source bytes for the observed palette. The exact frame when the logo's staged palette update reaches the PPU is still unverified.

The extracted `animation_8D_sprite_palette.bin` and its JSON metadata now use the traced source at `0x00D670`; the stale `0x00D370` candidate is removed. The resource records its match to the frame-100 PPU palette bytes. This validates palette contents, not complete logo composition or the exact PPU upload frame.

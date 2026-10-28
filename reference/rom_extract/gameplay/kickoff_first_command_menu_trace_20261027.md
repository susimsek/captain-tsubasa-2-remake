# Fresh KICK OFF route: first command menu live capture

## Scope and source identity

This note records one muted FCEUX 2.7.0 run from the supplied Turkish ROM's
cold-start replay through the first in-match command prompt. The endpoint is the
first complete panel showing the initial field actions; no action was selected
or resolved. Screenshots, PPU/RAM dumps, and APU logs are diagnostic evidence
only. They are not runtime assets.

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256 (whole iNES file):
  `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- MD5 of PRG+CHR after the 16-byte iNES header: `eaf2b3745263efa4b1afd2b400f68dae`
- Emulator: FCEUX 2.7.0, NTSC, one process for the capture.
- Audio: disabled with `--sound 0 --volume 0` and `SDL_AUDIODRIVER=dummy`;
  no WAV was recorded or listened to.
- Input source: `reference/opening_reference_capture/input_timeline.csv`,
  replayed from power-on for frames 0–4692. Its SHA-256 is
  `195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3`.
- Capture output: `reference/diagnostics/kickoff_select_test_20261027/`.
  The post-title source and emulator frame numbers stayed aligned in this run.

## Exact route and visible transitions

The source frame is the frame after the listed one-frame input. Frames without
an input listed below were released. The opening replay itself includes Start
held on frames 4661–4667, leaving the title cursor on KICK OFF at frame 4692.

| Source frame | Input | Observation |
|---:|---|---|
| 4693 | Start, 1 frame | Confirms the initially selected KICK OFF item and enters the new-game story. |
| 4843, 4993, 5143, 5293, 5443, 5593, 5743, 5893, 6043, 6193, 6343, 6493, 6643, 6793, 6943, 7093 | A, 1 frame each | Advances the Turkish story screens. |
| 7243 | Select, 1 frame | Skips the remaining story text to the Brazil Cup / São Paulo vs Fluminense matchup. It stays on the fresh KICK OFF route. |
| 7393 | A, 1 frame | Advances to the pre-match MEETING screen. |
| 7543, 7693, 7843 | Down, 1 frame each | Moves the cursor through Bilgi, Şifre, Veri, and to Başla. At the checkpoints the marker Y in `$02FC/$0564` is `$98`, `$A8`, `$B8`, then `$C8`. |
| 7993 | A, 1 frame | Confirms Başla. |
| 8143, 8293 | A, 1 frame each | Advances the resulting transition/story sequence. Frame 8142 is black with palette RAM all `$0F`; by 8292 a character scene is present. |
| 8443 | Select, 1 frame | Skips the `Flamengo kaptanı / Carlos Santana` card and continues into the same matchup's field introduction. |
| 8593 | A, 1 frame | Satisfies the documented kickoff scenario's A/B wait. |
| 8743 | Select, 1 frame | Skips the kickoff narration while preserving the match route. The active field state is visible by frame 8892. |
| 8893 | B, 1 frame | Opens the in-match command prompt. No subsequent input was sent. |

The title, narration, meeting, and matchup transitions were identified by the
FCEUX observations and the existing byte-checked route trace in
[`fresh_start_to_first_command_menu.md`](fresh_start_to_first_command_menu.md).
The Select behavior is an observed result for this ROM and this route; the
community guide reference remains a behavioral lead, not source-code proof.

The 15-frame screenshot sampling shows the B press at 8893 with the field and
radar still visible. The prompt box is visible by 8938; the first sampled frame
with the full right-hand action panel is 8953. Therefore the full panel is
confirmed by frame 8953, but its exact first pixel frame is only bounded to
between the 8938 and 8953 samples. The script continued without input to frame
9042, where it saved a stable endpoint. It stopped there before any action was
confirmed.

## First command prompt and initial selection

At frame 8953 the screen shows a field view with radar, the score/time panel
(`29:50`, `SAO 0`, `FLU 0`), a central prompt box, and a right-hand player/action
panel. The low-resolution Turkish text is pixel-read as:

- `FW Tsubasa` (player line; name is a visual read)
- `Enerji 397`
- `Çalım 9`
- `Pas 8`
- `Şut 8`
- The short central prompt appears to read `Ya şimdi?`; punctuation and exact
  spacing are uncertain at this scale.

The three visible action labels are Çalım, Pas, and Şut. No action was confirmed.
There is no visible arrow or highlighted row in the captured panel. No
directional input was sent after opening it, so the selected row is not
established by this capture and must not be guessed. The menu's visible initial
state is the endpoint.

## Live memory and PPU evidence

The first full-panel sample is `route_frame_008953.*` in the diagnostic folder:

- Screen: `screens/route_frame_008953.gd`, 245,771 bytes,
  SHA-256 `cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559`.
- PPU: `ppu/route_frame_008953.bin`, 16,384 bytes from
  `ppu.readbyterange(0, 0x4000)`, SHA-256
  `da56b2c2dbe44a5864be61068bb23fe46f434cc2bc73a10489a471e4bfa2350e`.
- CPU RAM: `ram/route_frame_008953.bin`, 2,048 bytes from
  `memory.readbyterange(0, 0x0800)`, SHA-256
  `a8d4cae0ed26fa6fbc01dcdcae6f076c94c33b0c295b95eca6cdbf64270a2971`.
  The NES OAM shadow at `$0200–$02FF` is included in this RAM snapshot.

The no-input stable checkpoint at emulator/source frame 9042 is
`screens/endpoint_frame_009042.gd`, `ppu/endpoint_frame_009042.bin`, and
`ram/endpoint_frame_009042.bin`. The screenshot and PPU bytes match the full
panel sample at 8953; the RAM snapshot differs because counters continue to
advance. The endpoint hashes are respectively
`cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559`,
`da56b2c2dbe44a5864be61068bb23fe46f434cc2bc73a10489a471e4bfa2350e`, and
`e78c0ff79c879d02168d95c6ac6dc93057226b0241ff37dc3f6e4e0f28129577`.

The observed RAM values at source frame 8953 are:

| Address | Value | Capture meaning / evidence boundary |
|---|---:|---|
| `$0026` | `$00` | Fresh match index. |
| `$002A` | `$00` | Match setup field observed by the route. |
| `$002B` | `$03` | Opponent ID used by the byte-checked setup route. |
| `$00E2` | `$33` | Live value; semantic role is not assigned here. |
| `$0441` | `$06` | Current ball-player field used by the static route notes. |
| `$0493–$0496` | `00 08 09 0A` | Four sprite CHR selector bytes. |
| `$05FB` | `$00` | Kickoff-side base observed in the fresh-start route. |
| `$05FD` | `$01` | Controlled field state is active. |
| `$0543–$0546` | `01 23 45 08` | Six sprite-order nibbles plus adjacent live selector byte. |

Five populated 21-byte actor records begin at `$0547`, `$055C`, `$0571`,
`$0586`, and `$059B`. Their full bytes are in the RAM snapshot; the requested
`+$0C` and `+$12` values are:

| Record | `+$0C` | `+$12` |
|---:|---:|---:|
| `$0547` | `$C3` | `$00` |
| `$055C` | `$C3` | `$04` |
| `$0571` | `$C3` | `$0D` |
| `$0586` | `$C3` | `$0A` |
| `$059B` | `$B3` | `$B9` |

At frame 8953 MMC3 `$8000` select is `$07`; registers `$8001` R0–R7 are
`00, 02, 1F, 2E, 0A, 0B, 18, 19`. With CHR mode 0, the live 1-KiB PPU pattern
slots map to ROM CHR banks `$00,$01,$02,$03,$1F,$2E,$0A,$0B`; PRG R6/R7 are
`$18/$19`. Each of the eight 1-KiB pattern slots in the PPU snapshot was
byte-compared with the corresponding bank in
`reference/rom_extract/chr_rom.2bpp` and matched exactly. This validates the
captured CHR bank mapping for that sampled frame. The snapshot does not identify
the game's background-record ID, and this short logger did not capture every
raster-time bank change.

The PPU palette at `$3F00–$3F1F` in the same snapshot is:

```text
0F 1A 18 30 0F 36 25 30 0F 21 31 30 0F 3A 1A 1A
0F 0F 0F 15 0F 0F 30 15 0F 0F 30 15 0F 0F 30 15
```

The full APU register-write log is `apu_writes.csv`. At source frame 8953 it
records `$4000=$70`, `$4001=$08`, `$4002=$EF`; `$4004=$F6`, `$4005=$08`,
`$4006=$17`; `$4008=$8F`; `$400C=$30`, `$400D=$08`, `$400E=$05`, `$400F=$98`.
These are register writes while the output was muted; they do not establish an
audible cue or audio equivalence. PC hooks were limited to `$80E6`, `$83DC`, and
`$A626`; a current gameplay instruction/caller PC was not captured at the menu.

## Remaining limits

- The menu's exact first-render frame is not known more finely than the sampled
  interval 8938–8953.
- The initial action cursor/highlight is not visible and was not probed.
- The follow-up direction probe was stopped in the opening replay before it
  reached the title; no Down/Up input was sent. The cursor remains unmeasured.
  Endpoint hashes and the retry limit are recorded in
  [`first_menu_cursor_probe_status_20261027.md`](first_menu_cursor_probe_status_20261027.md).
- The central prompt and player-name text are low-resolution visual reads; no
  independent Turkish text-table decode was made in this capture task.
- The background-record ID, complete raster-time PPU state, and exact menu
  handler PC remain untraced.
- Audio was intentionally muted. APU writes were logged, but sound was not
  listened to or compared.
- Emulator screenshots and dumps remain behavioral references only. Godot
  runtime assets must continue to come from ROM bytes and decoded game logic.

# Fresh-start pre-match MEETING menu: ROM trace

## Source identity and evidence boundary

This note traces the four-choice menu on the fresh KICK OFF route, from its
banked caller through the selected KICK OFF action. All extracted `.bin` files
are exact byte ranges from the supplied ROM, identified in `manifest.json`.
The ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

The pinned English translation/disassembly at
[`ec03cf06e6bdae0bcd232e3a423e9d259757dc64`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64)
was used only to navigate labels and call structure. Its cursor descriptor
differs from the Turkish target ROM: the target bytes at bank 1 `$ADD0` are
`FC 98 FF 03 10 C8` (the listing has `FC 96 FF 03 0E C6`). The target bytes
and the supplied-ROM capture take precedence.

FCEUX RAM/PPU captures are validation references only. No screenshot or
captured audio is included as runtime content here. These fragments preserve
source roots; they do not implement the screen or establish visual/audio
equivalence.

## Caller and menu controller

After new-game setup, bank 0 CPU `$8142` (file offset `0x000152`) calls bank 1
CPU `$A64C` (file offset `0x00265C`). `$A64C` clears both nametables and sprite
memory, then starts the
coach/advice scene selected by `tbl_B393[match_index] + $44`. In the fresh
match `$26=0`, `tbl_B393[0]=$00`, so it starts cutscene `$44` and waits for its
script to finish.

The menu then installs cursor descriptor bank 1 `$ADD0` (source file
`0x002DE0`) into OAM shadow beginning at `$0564`. Its target values set initial
Y `$98`, X `$10`, and bottom limit `$C8`. The handler at bank 0 `$9BE8` samples
newly pressed input once per frame. A or Start confirms; Up and Down move one
row by `$10` and wrap at the endpoints. The shared cursor routine at `$9CE7`
does that move, using the direction delta table at `$9EE2`. On confirmation,
the selector turns the cursor Y into an even option-table offset:

| Offset | Observed Turkish label | ROM action path |
|---:|---|---|
| `$00` | Bilgi | Coach/advice scene, `$44 + tbl_B393[match]` |
| `$02` | Şifre | Score-memo scene, then password generation/display |
| `$04` | Veri | Team-options screen at bank 1 `$A721` |
| `$06` | Başla | Team-before-match scene, `$5E + tbl_B41B[match]` |

The offset table is at bank 1 `$A673`. The Turkish labels above are read from
the existing same-ROM FCEUX capture; the English disassembly's comments name
the corresponding actions “advice”, “score memo”, “options”, and “kickoff”.
The controller and table bytes confirm action dispatch; the names in comments
are translation labels, not proof of the Turkish on-screen spelling.

For the current route, selecting offset `$06` reads `tbl_B41B[0]=$00` and
dispatches cutscene `$5E`. Its bank-5 pointer is `$BFF4`, the same as the next
pointer for `$5F`; `$BFF4` contains `$FF`, so this scene ends immediately.
The branch calls bank 0 `$9BA0` to fade/clear, then returns to the caller at
`$8145`. That caller checks `tbl_83DC[$26]`; at match 0 the byte is `$02`, so
it dispatches cutscene `$02` automatically and then proceeds to `$8017` to
start the game. The route does not require entering any of the other three
menu branches.

The existing route capture records cursor Y `$98`, `$A8`, `$B8`, `$C8` at its
meeting checkpoints, consistent with the descriptor and the 16-pixel move.
Those PPU/RAM dumps are evidence, not source artwork.

## Scene and visual source roots

The target cutscene bank-threshold bytes at bank 0 `$8AEE` map ID `$44` to PRG
bank 5, pointer-table slot `$24`. The bank-5 table entry is at source file
`0x00A058`, points to `$BE84`, and its next pointer is `$BE9E`. The script's
initial pointer span is preserved as `bank5_meeting_advice_scene_44_entry.bin`.
It includes `F9 $5F` (background ID `$5F`) and `FB 01 $3B` (animation ID
`$3B`), followed by a reachable `FE $BED6` jump. The fixed-bank `$8862`
handler confirms that `FE` is an unconditional script-pointer jump. The target
at `$BED6` is preserved separately and ends with `$FF` at `$BEDA`.

Background ID `$5F` indexes the bank-7 table entry at file `0x00E0CE`, which
points to descriptor `$AE4B` (file `0x00EE5B`). The descriptor supplies CHR
bank selectors `$3C/$02`, palette/configuration bytes, and metatile-block
selectors. Its decoder is the shared bank-0 `$8AF7` routine. Animation `$3B`
indexes the bank-9 table at file `0x012086`, points to `$A476` (file
`0x012486`), and is 10 bytes up to the next animation pointer. The disassembly
labels that animation as Roberto's normal right-facing pose; check all labels
against the target bytes before adopting them in runtime documentation.

To render the menu natively, the next source-decoding work is to resolve the
background descriptor's metatile records and its referenced CHR bytes, then
replay the scene-44 commands and cursor animation from the ROM. The preserved
descriptor/animation roots are not a complete rendering package.

## Confirmed command structure versus timing

For scene `$44`, the target bytes confirm the command order and operands:
`F9 $5F` background, `FB $01 $3B` one-entry animation selection, `F1 $03`
window mode, `F2 $00` text speed, `F0 $224C` text placement, text bytes with
two `$FC` line controls, and `FE $BED6` to the `$E8 $01 $F3 $00 $FF` tail.
The fixed-bank command table and handlers establish the dispatch targets for
these opcodes; bank-7 and bank-9 pointers establish the data roots noted above.
The scene's command order, pointer targets, and terminator are byte-checked.
Per-command frame waits, text reveal cadence, animation frame progression,
audio events, and first/last visible pixel timing have not been traced here;
do not invent fixed timings from this structure alone.

## Preserved source files

`manifest.json` records every source bank, CPU interval, iNES file interval,
length, and SHA-256 for the extracted byte spans. It includes the menu
controller and shared cursor routines, match-index branch tables, scene-44
entry and branch target, the no-op scene-5E terminator, and the background
and animation pointer/data roots.

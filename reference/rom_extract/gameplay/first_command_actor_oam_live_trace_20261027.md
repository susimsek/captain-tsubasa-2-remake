# Fresh KICK OFF actor/OAM and palette trace

## Evidence and scope

This note records a muted, same-input FCEUX trace from power-on through source
frame 8953. The trace explicitly stopped the auto-restored partial movie before
power-on, then replayed the checked opening input timeline and fresh KICK OFF
route inputs. FCEUX ran with sound and volume disabled; no WAV was recorded.
The supplied ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

Diagnostic output is in
`reference/diagnostics/first_command_actor_oam_20261027_113609_utc/`.
The endpoint CPU RAM image is byte-identical to the retained route snapshot
(`2048/2048` bytes); the PPU memory image is also identical (`16384/16384`).
These dumps are validation evidence only. No captured OAM, PPU image, or
emulator output is used as a runtime asset.

## Actor pose to OAM at the first command panel

Live hooks at fixed-bank `$EF35/$EF38` bracketed 1,414 calls to the bank-$16
sprite engine from frame 8000 through 8953. The decoded static chain is in
[`first_command_actor_pose_path_20261027.md`](first_command_actor_pose_path_20261027.md):
the `$EE9F` loop walks six ordered actor records, bank `$14` updates each
animation descriptor, and bank `$16` interprets that descriptor into OAM.
The live endpoint confirms the per-call input that the earlier RAM snapshot
could not supply.

At frame 8953, the draw loop emits three active actor records. Their descriptor
and selected OAM ranges are:

| Actor record | Descriptor | Shared selector `$0546` | Actor timer | Sprite count | OAM slots |
|---:|---:|---:|---:|---:|---:|
| `$0547` | `$00` | `$08` | `$FF` | 6 | 0–5 |
| `$055C` | `$04` | `$08` | `$FF` | 13 | 6–18 |
| `$0586` | `$0A` | `$08` | `$FF` | 22 | 19–40 |

The other records `$0571`, `$059B`, and `$05B0` are skipped by the active-flag
test at this endpoint. The first two listed descriptors branch through selector
`$08`; their ROM stream roots are `$842C` / file `0x02C43C` and `$87D9` / file
`0x02C7E9`. The descriptor `$0A` stream root is `$896B` / file `0x02C97B`.
This trace establishes the effective selector and generated OAM ranges, but the
complete run/jump walk and per-sprite transforms for these streams remain to be
decoded and independently checked before a runtime actor presenter is claimed.

At each `$EF35` draw call the live MMC3 sprite CHR selectors were R2–R5
`$08,$09,$0A,$0B`, mirrored in `$0494–$0497`; `$0493` was `$00`. The MMC3
register state at the hook was select `$1E`, R0–R7=`$3C,$2E,$08,$09,$0A,$0B,$16,$17`.
This is the draw-time state. The later end-of-frame register snapshot differs
and must not be used as a substitute for it.

## ROM source for the MEETING sprite palette

The cutscene palette worker at bank 0 `$9ADA` computes the source pointer as
`tbl_0x00D310 + 16 * $49`, reads 16 bytes into `$063A–$0649`, then the palette
upload writes them to PPU `$3F10–$3F1F`. The code at `$9ADA–$9AFD` is in the
checked target ROM; the public disassembly was only used to navigate to it.

At frames 7392/7393, the preceding scene state has palette selector `$49=$37`.
The selected ROM record is file offset `0x00D680` (`0x00D310 + 16×0x37`):

```text
0F 0F 10 30  0F 0F 30 00  0F 11 30 00  0F 0F 30 36
```

That row is byte-identical to both RAM staging bytes `$063A–$0649` and the
captured PPU palette `$3F10–$3F1F` at frames 7392/7393. By frame 7398 the PPU
values have begun fading, while the RAM staging row remains unchanged.

At the actual scene `$44` `$FA` refreshes (frames 7436/7437/7441), the live
selector is `$49=$0A`, which points to file offset `0x00D3B0`. The staging
buffer still contains the earlier row `$37`, while PPU `$3F10–$3F1F` is fully
faded to `$0F`. The `$B310`/`$AD8A` frame programs select tile `$6F` with
subpalette 0 or tile `$71` with subpalette 3; they do not carry the 16 palette
colors. This identifies the scene's selected ROM palette row, but the speaker
branch refresh happens while the palette is black and does not validate a
visible colored speaker frame.

When the MEETING command menu is ready, `$49=$0A`. The corresponding original
ROM table entry is file offset `0x00D3B0` (`0x00D310 + 16×0x0A`):

```text
0F 0F 27 36  0F 0F 30 11  0F 0F 00 36  0F 0F 30 36
```

At source frame 7543 this row is byte-identical to RAM `$063A–$0649` and PPU
`$3F10–$3F1F`. This verifies that the menu loads the same row `$0A` selected
at the scene `$44` branch hooks from the shared ROM table. The palette table
bytes—not captured PPU colors—are the runtime source.

The cursor's `$ADD0` descriptor is separate from this actor palette lookup.
At frame 7543 its OAM entry is `$A8 FF 03 10` in slot 63; PPUCTRL `$88` and
MMC3 R5=`$7B` maps tile `$FF` to CHR bank `$7B`, tile index `$3F`, raw
CHR-ROM-relative offset `0x01EFF0` (ROM file offset `0x05F000`). Those 16 CHR
bytes are `00 14 02 25 0E 15 0B 0E 1C 2A 7D
5A 71 2A 14 00`. The cursor palette subrow in the same snapshot is `0F 0F 30
36`; use ROM table data for runtime and retain the PPU snapshot only as a check.

## Speaker branch cadence in the same-input route

A second muted replay records writes to `$0099`, bank-qualified execution hooks
at `$8618/$895D`, the `$946D` call that parses the selected `$FA` frame, and the
palette selector, staging-buffer bytes, and current PPU sprite palette at each
event.
Its output is
`reference/diagnostics/meeting_speaker_branch_20261027_115033_utc/`.
The `$8000` program-bank shadow `$0024` was recorded so address aliases from
other banks could be excluded. The run completed 8,954 source frames, with
sound disabled and no movie left active.

Within scene `$44`, `$99` transitions at frames 7436, 7437, and 7441 are
`$40→$C0→$80`, `$80→$C0→$80`, and `$80→$C0→$80`. At each `$C0` refresh the
`$FA` handler selects `$B310`; the `$99` low bit remains zero. There are three
frame-parser calls total for this record and no selection of `$AD8A` before the
first command-menu endpoint. The bank-0 `$8618` mouth-toggle handler and
bank-0 `$895D` text-speed handler are not called during scene `$44` in this
input replay. Apparent `$8618` hits elsewhere in the log are from other
`$8000` program banks and are not executions of the bank-0 routine.

This input route provides no observed open/closed speaker cadence to copy: the
source keeps selecting the `$B310` branch and then stops refreshing this record
before the menu is ready. Do not invent a periodic mouth timer. To recover a
speaking cadence, first identify an input/scene state that actually sets `$0099`
bit 0 and selects `$AD8A`, then trace that same source path.

## Remaining implementation gap

This trace closes source selection for the two `$FA` frames and maps the
MEETING sprite palette indices back to exact ROM bytes. It does not implement
the cutscene animation interpreter or the gameplay actor descriptor renderer in
Godot. The full per-actor descriptor-to-OAM run/jump transforms still need to
be decoded and compared; this trace only establishes their selected streams and
OAM allocation. The unvisited `$AD8A` branch's displayed cadence also needs a
source input that reaches it. Do not replace either gap with captured OAM or a
fixed guessed animation clock.

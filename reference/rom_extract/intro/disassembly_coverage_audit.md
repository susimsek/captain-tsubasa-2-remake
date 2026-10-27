# Public CT2 disassembly: build and coverage audit

Checked 2026-10-24 against the supplied Turkish ROM. This report audits the
public assembly project's actual build inputs and in-ROM byte evidence; it
does not claim that the project is a complete, revision-matched disassembly.
The prior [`annotated_disassembly_opening_audit.md`](annotated_disassembly_opening_audit.md)
already records the useful cold-start/title instructions and byte counts for
banks 80, 81, 87, and FF. Regional Chinese/Japanese source claims are summarized
in [`regional_sources_followup.md`](regional_sources_followup.md).

## Source and target identity

The audited source is [`Captain-Tsubasa-2-English-Translation`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64), pinned at commit
`ec03cf06e6bdae0bcd232e3a423e9d259757dc64`. Its [README](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/README.md)
identifies it as a NES disassembly and English translation, and says most
comments are Russian. This is not a Chinese-language full-code project.

The target file is 393,232 bytes, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, SHA-1
`a6c2c0567f502ab6badbf21f831443a8349088b5`, header
`4E 45 53 1A 10 10 41 00 ...` (256 KiB PRG, 128 KiB CHR, mapper 4). By
contrast, the repository's [assembly script](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/assemble.bat)
expects a 786,448-byte output and declares a different original SHA-1,
`43C26781D88E062AFA81C1A32F8345011FE53B8C`. Its [header](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/header.bin)
is `4E 45 53 1A 20 20 52 00 ...` (512 KiB PRG, 256 KiB CHR, mapper 5).
The [linker config](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/ld65.cfg)
and `bank___future_expansion.asm` add banks beyond the supplied image. The
published build is therefore an expanded, mapper-changed translation build,
not a drop-in reconstruction of the Turkish ROM.

The repository contains ca65 bank sources, `bank_ram.inc`/`bank_val.inc`,
`ld65.cfg`, Windows assembler tools, `preparations.lua` (which converts source
`.text` strings), `CHR_ROM.chr`, and `DPCM.bin`. The bank filenames are not a
simple one-file-per-8-KiB map: several sources represent 16-KiB ranges, some
tail code is relocated into expanded output banks, and there are reserved
expansion segments.

## Opening coverage and byte checks

I compared the source's annotated listing byte fields (`0x` file offset,
mapped-bank/CPU address, then raw hex bytes) directly to the same offsets in
the supplied `.nes`. Offsets below refer to raw file positions including the
16-byte header. This checks only bytes actually listed in those annotations;
symbolic `.word`/`.byte` data without an annotated address was not included,
and byte equality alone does not validate comments or timing.

| Source file / original file span | Result and relevance |
| --- | --- |
| `bank_80.asm`, `0x000010–0x00200F` | The existing opening audit records all 7,406 annotated bytes matching. Useful for cold boot, opening wait, Start polling, and title-menu setup. |
| `bank_81.asm`, `0x002010–0x00400F` | The existing audit records all 4,350 annotated bytes matching. |
| [`bank_82.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_82.asm), `0x004010–0x00600F` | 2,227 of 2,230 annotated bytes match. Three differ at `0x0048C7–0x0048C9`, inside `sub_A8B7_запись_номеров`; inspect the Turkish routine before relying on this sequence. |
| [`bank_83.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_83.asm), `0x006010–0x00800F` | **No game data or instructions are present**: the source declares the segment and an `.out` free-space message only. The Turkish opening pointer/script is in this exact range (`0x006010` and `0x006030`), so this public disassembly does not supply the opening command stream. The linker config fills this empty segment with `$FF`. |
| `bank_84.asm`–`bank_85.asm`, `0x008010–0x00C00F` | Source has named coach/dialogue pointer and data tables, but this audit did not resolve and compare their assembled symbolic bytes. Treat labels as leads. |
| [`bank_86.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_86.asm), `0x00C010–0x00E00F` | All 860 annotated palette bytes match. |
| [`bank_87.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_87.asm), `0x00E010–0x01000F` | All 3,869 annotated bytes match; contains the background parameter table, including the title background entry. |
| [`bank_88.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_88.asm)–[`bank_8A.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_8A.asm), `0x010010–0x01600F` | Source labels the 4×4 metatile data and sprite-animation pointer tables, including IDs useful for the opening. Their symbolic table bytes were not included in this annotated-byte comparison; verify against the Turkish ROM before using any entry. |
| `bank_8B.asm`–`bank_90.asm`, `0x016010–0x02400F` | All 38,231 annotated bytes match. [`bank_8C.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_8C.asm) specifically identifies the sound engine. |
| `bank_93.asm`, `0x026010–0x02800F`; `bank_94.asm`, `0x028010–0x02C00F`; `bank_96.asm`, `0x02C010–0x03000F`; `bank_9A.asm`, `0x034010–0x03800F`; `bank_9C.asm`, `0x038010–0x03C00F` | All 46,166 annotated bytes match. |
| [`bank_98.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_98.asm), `0x030010–0x03400F` | 4,604 of 4,613 annotated bytes match. The nine differences (`0x033D37–0x033D3A`, `0x033D42–0x033D46`) are in data entries the source labels “unused trap/clear”; opening relevance is not established. |
| `bank_9E.asm`–`bank_9F.asm`, `0x03C010–0x04000F` | Source contains tables, but code/data is partly represented in the relocated tail-bank sources; not all symbolic bytes were audited here. |

Across the raw-annotated files checked here (including the previously
documented banks 80, 81, 87, and FF, but excluding relocated `bank_A7.asm`
text), 117,405 listed byte values refer to 117,394 unique source offsets;
117,382 unique offsets match, and 12 unique offsets differ (the three in
bank 82 and nine in bank 98). This is sparse annotation coverage, not proof
that every assembled byte in the ROM has been decoded.

## Included asset comparison

`DPCM.bin` (1,009 bytes; SHA-256
`8dd8281875a73557ef4a0ad3161ea6792e35016392f79a071263f4d745313ef2`) matches
the supplied ROM exactly at raw file offsets `0x03C010–0x03C400`. This is a
useful verified original sample block, although it is not the sequenced
opening BGM by itself.

`CHR_ROM.chr` is 262,144 bytes (SHA-256
`a759d6ce15619a094207ba8e0b17e0f0a89eab31f599819efe1da9ad0038789f`), twice
the Turkish ROM's 131,072-byte CHR region. In the first 128 KiB, 128,704 bytes
match and 2,368 differ; the file is not an exact Turkish CHR source. Use the
user-supplied ROM for canonical graphics bytes.

## Practical use for the Godot opening

1. Use the byte-checked `bank_80.asm` labels to guide boot/Start/title flow;
   the local [`annotated_disassembly_opening_audit.md`](annotated_disassembly_opening_audit.md)
   already gives the exact addresses and capture cross-checks.
2. Use `bank_87.asm` background names and `bank_86.asm` palette locations as
   search aids. Continue decoding the needed tile/layout data from the
   supplied Turkish ROM; do not import the expanded `CHR_ROM.chr` as exact.
3. Inspect `bank_88.asm`–`bank_8A.asm` for metatile and animation table
   structure, but verify each relevant pointer/record locally. For the opening
   script and its command order, start from the Turkish ROM's `0x006010` table
   and `0x006030` stream: this disassembly leaves bank 83 blank.
4. Use `bank_8C.asm` as an APU-driver map and the exact `DPCM.bin` match only
   for sample-data evidence. The opening music still requires the local
   sequence/driver mapping in `ed58_music_mapping.md`.

The Chinese Hack CT2 editor and animation catalog are separate tool/data
sources, not the authorship or complete executable listing for this
repository; their scope and ROM-specific checks are documented in
[`regional_sources_followup.md`](regional_sources_followup.md).

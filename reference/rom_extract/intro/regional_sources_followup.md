# Regional CT2 research follow-up

Checked: 2026-10-24  
Target ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`  
SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`  
Size/header: 393,232 bytes; iNES header begins `4E 45 53 1A 10 10 41 00`.

This is a supplement to `online_reverse_engineering_resources.md`. It records additional Japanese and Chinese leads and what they do—and do not—establish for the Turkish ROM's cold opening.

## Findings useful for the opening

### Japanese opening-music catalog

The Japanese community article [“オープニング(キャプテン翼II)”](https://w.atwiki.jp/gamemusicbest100/pages/6979.html) identifies the opening-demo BGM as “Opening,” says it is often called sound-test `SOUND 00`, and describes it ending as the game moves to the title screen. This is a useful expected track identity and endpoint for audio tracing, but it is a music-history page, not a sequence decoder or driver disassembly.

The Turkish community [CT2 music-system note](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html) independently gives Sound `00`'s pointer-table location and sequence header. Both address claims check against this ROM:

- File `0x18C98` contains `AD B7 59 AC ...`; its first little-endian pointer is CPU `$B7AD`.
- In bank 0F, file `0x1F7BD` is the corresponding sequence header: `0x1E010 + ($B7AD - $A000) = 0x1F7BD`.
- The local opening script starts at file `0x6030` with `E8 01 F9 00 FB 01 8D E9 DF EA ED 58 ...`; `ED 58` is the observed cutscene sound command.

The pointer address by itself did not establish the script-cue mapping: the cue argument, runtime driver ID, pointer-table index, and sequence address are separate layers. A later local handler/driver trace now resolves `ED $58` to this `0x1F7BD` sequence; see `ed58_music_mapping.md` and the correction section below. The Japanese page's title-transition endpoint remains contextual evidence, not proof of the Turkish ROM's exact final note or APU stop frame.

### Chinese music-editor release notes

The Chinese [Hack CT2 feature and release page](https://daymoe.com/rom/Hack%20CT2.html) describes music extraction/conversion for Tecmo music data and NSF-to-ROM association. Its history says a music-extraction issue involving `E8`/`E9` indices was corrected in October 2014. This gives a concrete lead for researching special commands in the music stream and for locating a community parser that may clarify sequence structure. The page does not publish that parser's source or explain those commands semantically, so it is not enough to implement them.

The same page is a ROM editing tool's feature log. It documents editors, previews, data tables, and live emulator memory editing; it does not present a complete 6502 listing. The attached `HackCT2插件源码(Src).7z` is explicitly plugin source, not the game's source. The latest release entry mentioning an “AI view tool” is a feature name and does not support a claim that the game logic was AI-decoded.

### Japanese binary wiki: useful bank convention, no accessible full listing

The [Japanese CT2 binary wiki](https://w.atwiki.jp/cap2bin/) advertises analysis sections for PRO-ROM banks in `0x2000`-byte ranges, beginning at file offset `0x10`. This matches the usual iNES-header-aware bank layout. For this target, the local opening pointer at file `0x6010` is `$A020`; the live local dispatch trace enters bank 3 at CPU `$A020`, and file `0x6030` contains that command stream. That makes the wiki's bank convention useful as a navigation aid.

The currently accessible wiki page itself is only an index. Its [page list](https://w.atwiki.jp/cap2bin/list) reports 16 pages, consisting of menu, top-level, and wiki utility pages; it does not list the advertised per-bank analysis pages. I could not retrieve an opening-specific byte listing from it. Therefore the site is not evidence that all 6502 code has been published or solved.

## Cross-checks on the supplied Turkish ROM

The local file hash above was recomputed for this pass. Relevant bytes:

| File offset | Local bytes | What the external lead suggests | Status |
| --- | --- | --- | --- |
| `0x6010` | `20 A0 A1 A2 26 A6 ...` | Japanese bank map's bank-3 area contains opening data | First pointer `$A020` agrees with the local live dispatcher trace. |
| `0x6030` | `E8 01 F9 00 FB 01 8D E9 DF EA ED 58 ...` | Chinese cutscene animation tables and audio-tool notes may help decode event IDs | Actual local Turkish opening command bytes; the local driver trace maps `$ED $58` to Sound 00, while Chinese animation labels corroborate IDs only, not handler semantics. |
| `0x18C98` | `AD B7 59 AC 00 A0 FE 9F` | Turkish music note labels Sound `00` pointer | First pointer resolves to local bank-0F file offset `0x1F7BD`. |
| `0x1F7BD` | `04 BA B7 05 BD BA 06 5E BD 07 3F BF FF E0 22 ...` | Japanese catalog calls the opening cue Sound `00` | Address and `ED 58` driver path agree with `ed58_music_mapping.md`; runtime `$58` is not sound-test ordinal `58`. |

The Chinese [Ct2-Editor-Advance repository](https://github.com/Novsochetra/Ct2-Editor-Advance) includes user reference tables under `Code_data`, including the cutscene-animation index [“剧情动画代码.txt”](https://github.com/Novsochetra/Ct2-Editor-Advance/blob/master/Code_data/%E5%89%A7%E6%83%85%E5%8A%A8%E7%94%BB%E4%BB%A3%E7%A0%81.txt). The existing opening research note already records the relevant local checks: `FB 01 8D` at `0x6034`, `FB 01 6E` at `0x6043`, and animation `8D` data at `0x143E3`. These support two community labels for this scene. They do not disclose the animation VM's complete control flow or timing and are not a full game disassembly.

## “Chinese community decoded all code” claim

The sources found do show extensive CT2 editing knowledge: music and CHR editors, gameplay data tables, animation ID indexes, and a separate byte-matched 6502 disassembly project documented in the companion research note. I found no Chinese source repository or document that contains a complete, verified 6502 disassembly of this game. The Japanese binary wiki currently exposes no retrievable per-bank listing either. The defensible conclusion is that community members decoded many data formats and some addresses, while the executable and opening runtime still need to be traced.

## Next high-value use of these leads

1. The `ED $58` handler/driver trace is complete: it selects the Sound `00` pointer at `0x18C98` and sequence header `0x1F7BD`. The unresolved detail is the final operand read, which is supported by local ROM bytes but not directly recorded in the current bus log.
2. Inspect Hack CT2's music parser/plugin if its linked archive can be obtained and reviewed; treat its E8/E9 handling as a hypothesis until matched to local bank-0C/0F bytes and live driver state.
3. Use the byte-verified annotated disassembly for executable routine names, and the local Turkish ROM plus live traces for actual operands, bank mappings, and timing.

No emulator or audio playback was started for this research pass.

## Independent source audit: music tables and animation labels (2026-10-24)

This pass opened the source pages directly and checked the cited bytes in the
same supplied Turkish ROM (SHA-256 unchanged). It did not control an emulator.

| Source | What it provides | Local check and confidence | Limit |
| --- | --- | --- | --- |
| Turkish forum post [“CT2 müzik sistemi nasıl çalışır?”](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html) | A community map of music pointer entries and 63 `E0 xx` instrument-pointer entries, with claimed driver/data regions. | The ROM has the listed instrument pointer table beginning at `0x18764`; its first word is `52 89` (`$8952`) and its last word at `0x187E0` is `D2 A5` (`$A5D2`). The Sound 00 pointer at `0x18C98` is `AD B7`, resolving through bank 0F to `0x1F7BD`, matching the independent local trace in `ed58_music_mapping.md`. | The post says `0x18010–0x2000F` is 8,192 bytes, but that inclusive range is `0x8000` = 32,768 bytes. Its first instrument pointer is CPU `$8952`; with bank 0C based at file `0x18010`, that resolves to file `0x18962`, while the post lists `0x18952` (16 bytes early). Preserve its pointer words as leads, but recompute every target using the correct active-bank mapping and iNES header. The full instrument pointer execution path has not been live-traced here. |
| Chinese editor reference table [`剧情动画代码.txt`](https://github.com/Novsochetra/Ct2-Editor-Advance/blob/master/Code_data/%E5%89%A7%E6%83%85%E5%8A%A8%E7%94%BB%E4%BB%A3%E7%A0%81.txt) in [`Ct2-Editor-Advance`](https://github.com/Novsochetra/Ct2-Editor-Advance) | 258-line animation-ID catalog. It labels animation `8D` as the small Tecmo rabbit in the opening/title presentation and `6E` as Tsubasa moving forward with the ball. | At file `0x6030`, this ROM contains `E8 01 F9 00 FB 01 8D E9 DF EA ED 58 DC F1 01 EC 00 F9 01 FB 01 6E ...`; so the local opening invokes IDs `8D` and `6E` in that order. | The table is community documentation, not game source, an animation bytecode interpreter, or a frame-accurate timing specification. The repository's visible contents are an editor executable and data/reference folders; the one-line README does not provide a complete 6502 disassembly. The IDs and descriptions still need byte/PPU-trace checks before implementing their animation behavior. |
| Chinese [Hack CT2 feature/release page](https://daymoe.com/rom/Hack%20CT2.html) | Release notes document ROM editing features: music-data extraction/automatic conversion, CHR integration, model viewing, and live emulator-memory editing. | Its notes independently confirm that community tooling exists for music and graphics inspection. | This is a feature log for a ROM editor, not a parser specification or source listing for the game. Its 2023 “AI viewer” wording names a viewer feature; it is not evidence that all game code was decoded by AI or published. The tool supports multiple regional/hacked ROM layouts, so its addresses must not be copied into the Turkish ROM without checking. |
| Turkish forum tutorial [“Ara Sahne Editleme (Beklenen Paylaşım - Detaylı)”](https://tsubasatr.net/konu-ara-sahne-editleme-beklenen-paylasim-detayli.html) | A hack-oriented example stream (`E8 01 F9 16 FA 10 FB 01 4A DE E9 ED 45 DC F1 02 E6`) with community interpretations for background, animation, audio, wait, and text-layout codes. | It is relevant as an opcode/handler search checklist. | It gives generic editing advice, not a verified disassembly of this ROM's cold-start script. For example, the local opening begins `E8 01 F9 00 FB 01 8D ...`, not the example's `F9 16 ... FB 01 4A ...`; its claims such as a code being “always required” must be checked against actual handlers and the opening path before use. |
| Japanese music-history entry [“オープニング(キャプテン翼II)”](https://w.atwiki.jp/gamemusicbest100/pages/6979.html) | Identifies the opening-demo track as “Opening” / commonly `SOUND 00` and says it ends as the title screen appears. | This is consistent with the ROM-derived Sound 00 pointer and opening-to-title sequence documented above. | It is contextual corroboration only; it does not decode the music sequence, sound-driver commands, or exact APU stop frame. |

### Cross-reference correction

The earlier caution in this document that `ED $58` had not yet been traced to
Sound 00 is superseded by the ROM-backed driver analysis in
[`ed58_music_mapping.md`](ed58_music_mapping.md): runtime ID `$58` is queued,
decremented/indexed by the sound driver, and selects the pointer at `0x18C98`
to sequence header `0x1F7BD`. This distinction matters because runtime queue
ID `$58` is not the community sound-test ordinal `SOUND 58`.

## Focused audit: does a Chinese full-game code decode exist? (2026-10-24)

I inspected the reachable project pages and repository contents below rather
than relying on search-result snippets. This audit found extensive Chinese
editing/data knowledge and one substantial public assembly project, but no
publicly reachable, byte-verified *Chinese* full-game 6502 disassembly.

| Source | Verified contents | Relevance and limit |
| --- | --- | --- |
| [Captain-Tsubasa-2-English-Translation](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation), especially its [README](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/master/README.md), [assembler script](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/master/assemble.bat), and [linker config](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/master/ld65.cfg) | Public NES disassembly project with ca65/ld65 build files and many bank `.asm` files; README says comments are mostly Russian and gives a build procedure. | Strongest accessible executable-code lead found, but it is not a Chinese publication and its labels still need checking against this Turkish revision. The existing local [opening audit](annotated_disassembly_opening_audit.md) compared all annotated bytes in banks 80 and 87 successfully; an earlier wider spot-check found mismatches in banks 82, 98, and A7. Do not treat every bank comment as verified for this ROM. |
| [Daymoe “天使之翼2代码”](https://daymoe.com/rom/code.html) and its linked [`CT2-CH Tilecode.txt`](https://daymoe.com/rom/CT2-CH%20Tilecode.txt) | The page lists addresses for pre-match meetings (`BE98`, `BEB2`, `BED0`), halftime meetings, password screens, and level-up screens; the linked file is a Chinese character/tile-code mapping table. | These are script/UI address and text-encoding references, not 6502 source. The listed meeting addresses are not the cold-start opening stream: the supplied ROM's opening pointer is at file `0x6010`, resolves to CPU `$A020` in opening bank 3, and the script bytes begin at file `0x6030`. The page does not specify whether its `BE98`-style values are CPU addresses or raw file offsets; verify before mapping them. |
| [Hack CT2 feature log](https://daymoe.com/rom/Hack%20CT2.html) and [Ct2-Editor-Advance repository](https://github.com/Novsochetra/Ct2-Editor-Advance) | The Chinese editor log describes CHR/model inspection, music extraction/conversion, data editing, and live emulator-memory editing. The GitHub repository exposes an editor executable plus data/reference folders, including an animation-ID table. | Useful tooling and catalogs, not the game's executable source or a complete interpreter specification. The page's 2023 “AI viewer” entry describes a viewer feature; it does not establish AI-based full-code recovery. The editor supports multiple ROM revisions and hacks, so its addresses need per-ROM checks. |
| [Captain Tsubasa Vol. II: Super Striker - PLUS technical notes](https://romhackplaza.org/romhacks/captain-tsubasa-vol-ii-super-striker-plus-nintendo-entertainment-system-romhack) | The author describes a “byte-exact, clean-room” disassembly, says it is temporarily private, and identifies the Japanese base by SHA-1 `43c26781d88e062afa81c1a32f8345011fe53b8c`; the page currently lists no downloadable files. | Evidence that a separate private disassembly project exists, not a source we can inspect or use. Its Japanese base differs from the supplied Turkish ROM (same 393,232-byte size, but Turkish SHA-1 is `a6c2c0567f502ab6badbf21f831443a8349088b5`). |

### Address and size traps when checking community notes

- The supplied image is 393,232 bytes and has a 16-byte iNES header, so PRG data begins at file offset `0x10`. For the opening's 8 KiB PRG bank 3 mapped at CPU `$A000`, the raw-file window begins at `0x10 + 3 * 0x2000 = 0x6010`. Its first pointer is `$A020`; within that mapped bank it resolves to file `0x6010 + ($A020 - $A000) = 0x6030`. The actual bytes there are `E8 01 F9 00 FB 01 8D E9 DF EA ED 58 ...`. Do not mistake CPU `$A020` for raw file offset `0xA020`, and do not add the 16-byte header twice to offsets already expressed as raw-file positions.
- The Turkish music-system post's inclusive range `0x18010–0x2000F` is `0x8000` bytes (32 KiB), not 8 KiB. Its first pointer `$8952`, mapped from a bank starting at file `0x18010` and CPU `$8000`, resolves to `0x18962`; the post's `0x18952` target is 16 bytes early. This is a concrete warning to recalculate each pointer using the active CPU window and bank, not copy printed file locations blindly.
- The public translation/disassembly build script's expected output size `786,448` bytes is an expanded assembled ROM, not the original clean image size. Its cited original Japanese SHA-1 matches the 393,232-byte base above; it must not be compared as if both numbers described the same file.

### Result of the source search

Chinese sources inspected here establish useful editor features, glyph mappings,
animation IDs, and some script/menu addresses. They do not provide the claimed
complete Chinese code listing. I found no accessible full Chinese 6502 source
or annotated disassembly in the checked GitHub, Chinese page, and Japanese
index sources; this is a limit of this source audit, not proof that no private
or unindexed work exists. For the current opening, use the public assembly as
a byte-checked reference where it matches, then continue tracing the supplied
Turkish ROM's own handlers and banked data.

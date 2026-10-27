# Online CT2 reverse-engineering resources checked against this ROM

Last checked: 2026-10-26 (initial review 2026-10-24)

## Byte-verified disassembly

The public [Captain-Tsubasa-2-English-Translation disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation) is directly useful: it includes annotated 6502 banks, a RAM label include, and comments for cutscene, animation, PPU, NMI, and audio routines. Its README says it is a disassembly/English-translation project and that most comments are Russian. Treat its English script/text and author-specific ROM edits as separate from the supplied Turkish revision.

The local reference ROM has SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, iNES header `4E 45 53 1A 10 10 41 00 ...` (256 KiB PRG, 128 KiB CHR, mapper 4/MMC3). The disassembly's annotated raw-byte records were compared to this file at their stated file offsets (offsets include the 16-byte iNES header). Results:

- `bank_80.asm`: 3,872 annotated records / 7,406 listed byte values; all records match.
- `bank_81.asm`: 2,118 annotated records / 4,350 listed byte values; all records match.
- `bank_FF.asm`: 4,797 annotated records checked; all records match.
- `bank_87.asm`: 3,869 annotated records checked; all records match.

A broader coverage audit later counted 117,405 listed byte values across in-ROM annotated ranges (117,394 unique offsets, 117,382 matching and 12 differing). The record counts above are not byte counts; see [`disassembly_coverage_audit.md`](disassembly_coverage_audit.md) for ranges and build-layout limits. The comparison used repository revision [`ec03cf06e6bdae0bcd232e3a423e9d259757dc64`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/commit/ec03cf06e6bdae0bcd232e3a423e9d259757dc64).

This verifies the corresponding code bytes, not every comment or table interpretation. It is strong evidence that those bank listings can be used to understand the Turkish ROM's common engine routines after confirming the address/bank context. A broader spot-check found non-matching records in `bank_82.asm`, `bank_98.asm`, and `bank_A7.asm`; do not assume every disassembly bank is the same revision or rely on its addresses without byte checks.

### Opening routines matched

`bank_80.asm` comments and code bytes match the local cold-start/title bank:

- CPU `$801F` / file `0x00002F`: entry to opening setup, followed by `JSR $9BA0`.
- CPU `$8022` / file `0x000032`: selects cutscene 0; CPU `$8024` / `0x000034` calls the cutscene dispatcher at `$8464`.
- CPU `$8027–$8032` / file `0x000037–0x000042`: per-frame Start polling loop and exit.
- CPU `$8048–$804C` / `0x000058–0x00005C`: requests sound command `$01` (stop music/sound) after leaving the opening.
- CPU `$807A` onward initializes title resources; `$80A2` is the title input wait, and `$80E1/$80E6` are the KICK OFF branch.

The existing local `reference/rom_extract/intro/README.md` and dispatch trace remain the source of truth for Turkish cutscene script bytes and observed execution. The online disassembly's bank-80 labels are useful to name routines, while the local captured trace establishes which path actually ran.

For the F8 `$17` title-background load, the annotated `bank_80.asm` listing's
`$8F49` copy loop was checked against this ROM at file offset `0x00F59`:
`B1 EA 9D E8 05 E8 C8 C0 04 D0 F5`. It copies four bytes from `($EA),Y` into
the PPU queue literally, so it cannot explain the observed tile payload
difference by a tile-ID remap. Local ROM checks confirm that header bit 7
selects the `$1100` block page and bank-0 `$8F49` copies those selected bytes
literally. For block `$04`, the selected record at file `0x011154` matches the
captured `$2084/$20A4/$20C4` rows; the base-page record at `0x010054` does not.
The silent local trace at
`reference/diagnostics/f8_special_mode_20261024_200815/` now confirms all 48
live block pointers and reconstructs all 240 queue packets with exact
ROM-derived lengths, addresses, order, and payloads for this `$17/$80` path.
The trace also records the `$5B` selector write and the direct attribute path.
The annotated disassembly alone would not establish these captured runtime
values; exact subframe PPU/NMI and raster timing and the post-change Godot
comparison remain open in `f8_00_sequence_trace.md`.

## Japanese and Chinese materials

- The focused [Japanese-language source inventory](japanese_sources_opening_20261025.md) records the opening/title-relevant Japanese guides, address memo, binary wiki, developer interview, music references, and 5ch command leads. It now also catalogs the Japanese address memo's game-wide subjects (event IDs/text, graphics/palettes, animation dispatches, move records, player/opponent stats, and team data) without copying its many third-party address labels wholesale. Each item is classified by evidence type and checked/unchecked status.
- The [Japanese CT2 binary wiki](https://w.atwiki.jp/cap2bin/) home-page menu lists 32 PRO-ROM bank ranges and headings for modification guidance. Its public page list currently exposes only 16 pages and no bank-analysis page content, so treat the bank ranges as an index rather than a recovered disassembly. Verify any offset or interpretation against this Turkish ROM.
- The uploader's [Captain Tsubasa 2 address memo](https://u9.getuploader.com/cap/download/73) was downloadable and readable as Shift-JIS/CP932 text. It labels file offsets `0x6010` onward as the opening demo (OP demo), `0x62B1` onward as the demo after Start, and `0x6636` as the first Carlos match script. Local ROM confirms that `0x6010` contains the opening pointer table and `0x6030` begins the opening script, but the live Start-to-title trace does **not** prove that the `0x62B1` stream is reached; do not wire it in without tracing the pointer/bank handoff. The companion [analysis archive listing](https://u9.getuploader.com/cap/download/71) is present (25.5 KB), but the archive itself was not inspected in this pass.
- The 5ch post linking [skywingshoot's Basic Tutorial v1.3.4.H](https://medaka.5ch.io/test/read.cgi/gameurawaza/1392479553) describes it as containing basic hacking guidance and analysis materials and points to Baidu. The tutorial's contents were not accessible through the indexed page here, so no claim is made about its particular data or code mapping.
- The Chinese [Hack CT2 tool/reference page](https://daymoe.com/rom/Hack%20CT2.html) documents ROM editing features for CHR, music, skills, data/address conversion, and emulator-backed memory editing. It is a useful investigation tool/reference, not a verified disassembly of this Turkish opening.
- The [TsubasaTR forum](https://www.tsubasatr.net/) has hacking/code resources; a recent portal result includes a community post about music data offsets. Those offsets are leads only and need byte/hash checks against the supplied ROM.

The specific [Turkish music-system thread](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html) was opened directly on 2026-10-26. Its first post lists the sound-test sequence/pointer offsets and a proposed 63-instrument table; all 40 BGM and 60 SFX pointer words were already independently checked against this ROM in `reference/rom_extract/audio/sound_test_index_audit_20261025.md` and `sound_test_sfx_index_audit_20261025.md`. A later reply in that same live thread warns that the broader explanation contains errors and says a corrected, more complete account is forthcoming. Therefore only the byte-verified pointer/sequence mappings are adopted; the forum's instrument interpretations and undocumented driver-region claims remain leads. This thread does not publish the full original-game source or an opening frame/timing decoder.

The Japanese [Captain Tsubasa 2 binary wiki](https://w.atwiki.jp/cap2bin/) exposes a PRO-ROM menu with 32 bank-range labels, but its currently visible page index has only 16 pages and the bank labels do not resolve to accessible bank listings. It is a bank-layout index, not evidence that all game code or cutscene behavior is decoded. For actual annotated 6502 code, the [pinned GitHub disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64) remains the strongest external source; its comments and translation branch are not assumed identical to the Turkish ROM without local byte checks.

No web tutorial or editor documentation found in this check provides a complete, already-solved Godot-ready opening renderer. The practical gain is the annotated disassembly: use its routine names and RAM labels as hypotheses, verify the bytes in this ROM, then map the executed opening path using the local emulator trace and ROM data.

## Opening-specific source leads and byte checks

### Japanese offset memo: script, palette, and scene-table leads

The mirrored [Japanese address memo](https://daymoe.com/rom/code/%E3%82%AD%E3%83%A3%E3%83%97%E3%83%86%E3%83%B3%E7%BF%BC2%E3%82%A2%E3%83%89%E3%83%AC%E3%82%B9%E3%83%A1%E3%83%A2.html) labels `0x6010` as the opening-demo area, `0x62B1` as the demo after Start, `0x6636` as the Carlos match, `0xD010–0xD2FF` as background colors, `0xD310–0xD790` as character colors, `0xE010` as an opening-demo management area, and `0x10010–0x119B2` as a possible opening background region. Treat the question-marked graphic classifications and any behavior not observed in this ROM as hypotheses.

Several structural leads are independently consistent with the supplied Turkish ROM:

- File `0x6010` begins with the pointer table; its first little-endian word is `$A020`. File `0x6030` begins `E8 01 F9 00 FB 01 8D…`, the observed Tecmo Theatre opening command stream. The captured bank-3 dispatch trace starts at `$A020`, so the Japanese index's opening range has the right physical layout for this ROM.
- File `0x62B1` begins `E8 01 F9 5C FB 01 6D…`, matching an event-stream-shaped block. The memo's “after Start” label is not, by itself, proof this block is reached by the user's captured Start-to-title path; do not wire it into the current slice without a live pointer/bank trace.
- Bank-0 `$E010` scene-parameter table is byte-verified in `bank_87.asm` (all 3,869 annotated records in that bank match). The pointer records list scene IDs for background 00 Tecmo Theatre, 01 field runner, 03 Tsubasa portrait, 07 Hyuga portrait, 08 tackle field, 09 black scene, 0A Wakabayashi goal, 0B Wakabayashi portrait, and 17 title. The data bytes match; treat translated labels as candidate names until local behavior/data use confirms them.
- File `0xD010` begins the palette records already decoded locally. Local project documentation maps opening background palettes into this region, but the Japanese memo's full `D010–D2FF` classification has not been independently verified for every entry.

The public disassembly's `bank_87.asm` supplies a stronger scene-table interpretation for physical file `0xE010`: it names the table `tbl_0x00E010_...background parameters` and enumerates background IDs. A comparison of all annotated bytes in that bank listing against the supplied Turkish ROM found **3,869/3,869 bytes equal** at the listing's absolute file offsets. In particular, the local pointer words at `0xE010` resolve to the same `$A0D4`, `$A0DF`, `$A127`… records listed in the assembly. Its names identify the opening/title entries as ID `00` Tecmo Theatre, `01` running field, `03` Tsubasa portrait, `07` Hyuga portrait, `08` tackle field, `09` black scene, `0A` Wakabayashi goal, `0B` Wakabayashi portrait, and `17` title menu. The bytes are verified; the comment wording is a third-party label. Local cutscene/background decoding and observed command IDs provide the cross-check before using those labels.

### Turkish music map and Chinese editor

The recent Turkish community post [“CT2 müzik sistemi nasıl çalışır?”](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html) gives a sound index, pointer-table addresses, music sequence addresses, and instrument-table ranges. For Sound `00`, it lists pointer address `0x18C98` and sequence header `0x1F7BD`. In the supplied ROM, bytes at `0x18C98` begin `AD B7 59 AC`; the first word `$B7AD` is the local bank-0F sequence header CPU address, which maps exactly to file `0x1F7BD` (`0x1E010 + ($B7AD-$A000)`). This independently confirms the table-to-track address arithmetic for that entry. The local driver trace now also resolves opening `ED $58` through its runtime ID-minus-one lookup to this exact pointer-table entry and Sound 00 sequence. Keep the number spaces distinct: runtime cue `$58` is not sound-test ordinal `58` even though it selects Sound 00 here; see `ed58_music_mapping.md`.

The same Turkish post describes `0x18010–0x2000F` as the music/driver region, with driver code at the start, note/frequency support data, an instrument table around `0x18764–0x18BE9`, and sequence pointer/table data around `0x18BEA–0x18C41`. Its address split is a useful trace map, not yet a byte-by-byte semantic proof. The local ROM extract already preserves the 8 KiB bank at `0x18010` and the 8 KiB bank at `0x1E010`; use the post to guide a direct call/table trace rather than copying its labels blindly.

The Chinese [Hack CT2 tool page](https://daymoe.com/rom/Hack%20CT2.html) advertises Tecmo music-data extraction/conversion, NSF-to-ROM association, CHR preview/export, and live emulator memory editing. Its release notes explicitly mention extracting most Tecmo music data, index conversion, and CHR preview. That makes it a useful inspection aid, not a verified disassembly or proof that the whole game has been decoded. No tool binary/source or data table from that page was used as authoritative evidence here. The Japanese wiki's index exposes bank-analysis headings but its indexed page list does not expose the bank pages themselves in this pass; the more useful specific address notes were read from the mirrored uploader copy above.

### Turkish community cutscene and opening-palette leads, checked locally

The TsubasaTR tutorial [“Ara Sahne Editleme (Beklenen Paylaşım - Detaylı)”](https://tsubasatr.net/konu-ara-sahne-editleme-beklenen-paylasim-detayli.html) gives a sample event sequence and proposed meanings for `E8`, `F9`, `FA`, `FB`, `ED`, `DC`, `F1`, and `E6` (forum lines 87–98). It is useful as a list of handler hypotheses, not as a byte-for-byte script for the cold opening. The supplied Turkish ROM does **not** contain the tutorial's sample sequence `E8 01 F9 16 FA 10 FB 01 4A DE E9 ED 45 DC F1 02 E6`; the live cold-open stream begins at file `0x6030` with `E8 01 F9 00 FB 01 8D E9 DF EA ED 58 DC F1 01 EC 00...` (see `cutscene_00.json` and the dispatch trace). In particular:

- The local script contains `DC` at file `0x603C`; the compact-wait lookup table is at `0x0AF6`, whose `DC` slot (index 4) is `0x3C` / 60 scheduler frames. This is inconsistent with the forum's generic “1.6 seconds” gloss as a literal duration. Keep the ROM's table value and traced scheduler cadence as the implementation evidence.
- The local `ED 58` at `0x603A` and `ED 68` later in the script are observed runtime sound-command arguments, not sound-test track numbers. The forum's example `ED 45` occurs elsewhere in this ROM at `0x6625`, `0x9A46`, and `0xC5FE`, but not in its cited sample context; no live opening cue in this capture establishes `45` as a music index. The driver/table trace for `ED 58` is complete and resolves to Sound 00 at file `0x1F7BD`; no equivalent mapping is asserted for `ED 68` here. See `ed58_music_mapping.md`.
- Local code/trace evidence already identifies `F9`/`FA` as background-related handler calls and `FB` as loading animation descriptors. The tutorial's specific operand meanings (especially `FA 10`, `FB ... 4A`) have not been established for this ROM's opening IDs; do not substitute its example IDs for the live `F9 00`, `FB 01 8D`, and subsequent observed commands.

The Turkish community post [“Karşılama Açılış Ekranı Hakkında Bilgiler”](https://www.tsubasatr.net/portal.php?page=414) gives palette offset `0x0D020` and the 16-byte sequence `0F 16 00 30 0F 0F 0F 0F 0F 11 00 30 0F 0F 16 26`, with color-role interpretations for the opening/Tecmo and title lettering. This is directly byte-confirmed in the supplied ROM at file `0xD020`. In addition, captured PPU state `reference/opening_timing_capture_20261024_131000/ppu_states/ppu_00026.bin` has the identical 16 bytes at PPU palette address `0x3F00`, confirming that this ROM palette record is live in that captured opening frame. The post's individual color names/roles are community interpretation; exact rendered pixel-to-palette assignment still requires the corresponding nametable/attribute/OAM mapping and visual cross-check.

The TsubasaTR index page [“Bugüne Kadar Paylaşılan Tüm CT2 Paylaşımlarına Buradan Ulaşın”](https://tsubasatr.net/konu-bugune-kadar-paylasilan-tum-ct2-paylasimlarina-buradan-ulasin.html) is a useful directory, exposing dedicated topics on cutscene animation IDs, player codes, video palette offsets, and the KICK OFF/CONTINUE screen. Its listed topics are leads rather than technical evidence until their content is read and checked against this ROM.

### Limits of other regional sources

The Japanese [CT2 binary wiki](https://w.atwiki.jp/cap2bin/) explicitly organizes analysis in PRO-ROM banks of `0x2000` bytes from file offset `0x10`; that confirms the banked-offset convention, but does not establish that individual listed PRO-ROM bank contents match this Turkish translation. The Japanese hack discussion also contains expanded-ROM locations such as `0x148000` and `0x198000`; these are outside this ROM's 393,232-byte file and are inapplicable to its opening. The Chinese [Hack CT2 release notes](https://daymoe.com/rom/Hack%20CT2.html) confirm that its tool supports music conversion, CHR viewing, plugins, and live emulator memory editing, but no source code or opening-specific event/PPU/audio map was retrieved from its download links. No additional Japanese/Chinese source located here supplies byte-verified opening command handlers, sprite-animation schedules, raster palette changes, or music cue-to-sequence mapping for this Turkish ROM.

### Cayosa password-page archives: opening script and sound index (2026-10-24)

The user-provided [Cayosa CT2 archive page](https://cayosa.ysepan.com/) contains a 2015 community data collection. Its `Drama/6010-A00F 剧情完工.xls` entry labels block `00` as the opening, gives pointer bytes `20 A0`, and lists a 641-byte event stream with Japanese text, Chinese translation, and a GIF reference. Against the supplied Turkish ROM, file `0x6010` starts with pointer `$A020` and file `0x6030` starts the opening stream. The archive and Turkish stream share the first 32 bytes, including `ED 58`, but differ at stream offset `+0x20` and at 584 of 641 byte positions overall. A companion `Drama/note.doc` labels animation `8D` as the opening rabbit and proposes IDs `15/16/17` for title-scroll/Continue/title; local source tables support `17` as the title menu, while other labels remain leads. It is therefore an independent structural/text lead, not the Turkish script to import.

The same archive's `Sound/Sound.doc` labels `0x58` as the opening theme “Super Striker,” which independently supports the local command observation at file `0x603A`. The target-ROM driver route and sequence pointer remain established by `ed58_music_mapping.md`. `Colour/剧情颜色地址.doc` gives palette-address leads `D310/D320/D330/D3FB`; the project already byte-verifies D310, while the other mappings need independent checks. The separate F7/XX ZIP focuses on shot-prelude editing (`0x21D0C`, custom code around `0x3FD20`), not the opening timeline. In the supplied ROM `0x21D0C` remains `4C AB`, `0x3FD20` holds `55 7A 61 6B FC` plus `FF` fill, and the cold-open cutscene stream contains no F7. The stock cutscene `$F7` handler does not read an effect operand; animation VM `$F7` in the runner has a distinct, locally traced velocity/acceleration role. Thus the tutorial's effect meanings and patch are inapplicable to the cold-open script as-is.

The archive is a modding/reference collection, not a disassembly or a frame-to-PC/PPU/OAM/APU map. See [`cayosa_archive_review_20261024.md`](cayosa_archive_review_20261024.md) for the archive SHA-256, item classifications, byte comparison, and limits. Its scenario descriptions, track labels, and animation/effect addresses are useful reverse-engineering leads; the supplied Turkish ROM and local traces remain canonical.

### Chinese CT2 repositories: tool, data notes, and the “all code decoded” claim

The [Hack CT2 feature/release page](https://daymoe.com/rom/Hack%20CT2.html) describes a ROM editor: its release log lists hex editing, address conversion, CHR/model preview, music extraction/conversion, emulator memory editing, and data editing for players, teams, skills, and AI. It links a downloadable `HackCT2.7z` executable and separately names a `HackCT2插件源码(Src).7z` plugin-source archive. The linked feature guide at Tencent Docs timed out in this check, and the page does not offer or claim a complete game 6502 disassembly. Thus Hack CT2 is a useful modding/research tool, not evidence that all executable code has been decoded.

The public [Ct2-Editor-Advance repository](https://github.com/Novsochetra/Ct2-Editor-Advance) likewise identifies itself as a cheat/editor tool; its root contains the compiled `Hack CT2.exe`, while the README is only a title line. Its `Code_data/` directory does contain substantial user-contributed reference notes, including [“剧情动画代码.txt”](https://github.com/Novsochetra/Ct2-Editor-Advance/blob/master/Code_data/%E5%89%A7%E6%83%85%E5%8A%A8%E7%94%BB%E4%BB%A3%E7%A0%81.txt), an index of cutscene animation IDs, plus technique, portrait, player, and other address tables. That index labels animation `8D` as the opening-screen rabbit and `6E` as Tsubasa carrying the ball; these are scene/animation labels, not a 6502 listing or a description of the animation interpreter's full timing/state logic.

Two opening entries cross-check against the Turkish ROM itself: file `0x6034` contains `FB 01 8D` and file `0x6043` contains `FB 01 6E`. The local animation data for ID `8D` is at file `0x143E3`, bytes `36 F1 30 28 91 5B FF`; it initializes position `(Y=0x30, X=0x28)`, references sprite frame `$B15B`, and exits. The project trace separately ties `$B15B` to the opening OAM descriptors. This supports the community labels for these two opening IDs. It does not establish that all IDs or prose descriptions in the Chinese notes are correct, nor that the note authors decoded all game code. Other downloadable `Code_data` files include CHM manuals (`剧情方面资料.CHM`, `天使之翼二相关程序.CHM`), but the CHM payloads were not extractable with the available local archive tools in this pass; do not rely on their contents.

The same GitHub user's [Chinese ROM file](https://github.com/mengfei523060/nesrom/blob/master/%E5%A4%A9%E4%BD%BF%E4%B9%8B%E7%BF%BC2%E4%BB%A3.nes) is a distinct image despite matching the Turkish ROM's size/header: 393,232 bytes, iNES header `4E 45 53 1A 10 10 41 00 ...`, SHA-256 `ee08f9134ef0e9e3a5f77e4f08244d24739c68d781cb58e2be737916bb3ab5ae`, versus the supplied Turkish SHA-256 above; a bytewise comparison finds 35,815 differing byte positions. Several opening-relevant ranges do match exactly across the two images: `0x6010–0x604F` (opening pointers and initial commands), `0xD020–0xD02F` (opening palette), `0xE010–0xE02F` (background pointer records), `0x14050–0x1410F` (sampled animation pointer data), and the ID-`8D` animation record at `0x143E3–0x143E9`. These matches make those specific shared records useful corroboration; they do not license unverified Chinese-ROM addresses elsewhere in the Turkish ROM.

Searches for Chinese `天使之翼2` / `足球小将2` 6502 disassembly, code repositories, and “all code” claims did not surface a Chinese full disassembly. One apparent GitHub result, [WispSnow/angel2-web-remake](https://github.com/WispSnow/angel2-web-remake), is for the unrelated DOS tactical RPG *Empire of the Angel II* (`天使帝国 II`), not *Captain Tsubasa 2* (`天使之翼2`); its extensive reverse-engineering tree is a false positive for this game. The directly useful complete-ish 6502 assembly source located remains the already documented [Captain-Tsubasa-2-English-Translation disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation), whose README calls it a disassembly/translation project and says most comments are Russian. Previously recorded byte checks establish matching bytes for banks 80, 81, 87, and FF in the supplied Turkish ROM; other banks still require individual checks.

### Focused external check: frame-by-frame opening map (2026-10-24)

No inspected external source provides a complete table mapping every cold-start frame to its 6502 PC, cutscene command, PPU/OAM changes, and APU events for this Turkish ROM.

| Source | What it provides | What it does not settle for this opening |
| --- | --- | --- |
| [Public English-translation disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation) and [`bank_83.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/master/bank_83.asm) | A large annotated 6502 disassembly for a related NES build; its README calls it a disassembly/translation project and says most comments are Russian. | `bank_83.asm` itself is only 12 lines: segment/includes, `.org $C000`, and a free-bytes report, with no decoded instructions. The project is not a complete annotated listing, and its revision/build layout is not the supplied Turkish ROM. Existing local bank/byte audits still apply; use only byte-verified regions. |
| Chinese [`Ct2-Editor-Advance`](https://github.com/Novsochetra/Ct2-Editor-Advance) and [Hack CT2 feature log](https://daymoe.com/rom/Hack%20CT2.html) | The repository describes an editor/cheat tool and contains data/reference folders; the feature log documents CHR preview/export, music extraction/conversion, model viewing, and emulator memory editing. Its animation index can help label IDs such as `8D` and `6E`. | These are editors, extraction aids, and catalogs. They do not publish the full cutscene VM or an every-frame 6502/PPU/APU trace. The animation index does not define frame durations or command scheduling. |
| Japanese [manual index](https://tsubasa.yamagomori.com/ct2/manual/m0-index.html), [opening/Rio transcript](https://tsubasa.yamagomori.com/ct2/scenario/m-1.html), [story index](https://tsubasa.yamagomori.com/ct2/scenario/0-index.html), [other-analysis index](https://tsubasa.yamagomori.com/ct2/other/other.html), [progression chart](https://tsubasa.yamagomori.com/ct2/memo/chart2.html), [player-data index](https://tsubasa.yamagomori.com/ct2/data/ct2-data.html), [experience inheritance](https://tsubasa.yamagomori.com/ct2/memo/inheritance.html), [level table](https://tsubasa.yamagomori.com/ct2/memo/nextexp.html), and [GCGX story guide](https://gcgx.games/captain-tsubasa2/story.html) | Reproduced manual topics and start/continue instructions; Japanese scene narration and story arcs; Guts, through-pass, stat-conversion, move-power, tournament, roster, and experience tables. These help identify expected flow and gameplay rules to investigate. | They do not map ROM instructions or event-command bytes to frame numbers, raster writes, animation ticks, or sound-driver state. The target is a Turkish localization; text, stat ordering, offsets, and rules still require target-ROM checks. |

These sources remain useful: the assembly supplies routine names for byte-checked banks; Chinese tables help label animation records; Japanese pages provide scenario wording and gameplay context. No inspected external source resolves each opening pixel to an instruction and CHR fetch. Local evidence now resolves one narrow example: the field runner's first row comes from the `$2005=$00,$FF` coarse-Y 31/fine-Y 7 state and a dispatcher write of 32 `$55` bytes to `$23E0–$23FF`; ROM bytes, cycle-stamped `$2006/$2007` writes, PPU snapshots, and three Godot/FCEUX output checks are documented in `reference/diagnostics/field_runner_scanline0_source_render_20261024.md`. The full map remains incomplete. The clean-power-on capture at `reference/opening_timing_capture_20261024_131726/` does have 4,693 contiguous end-of-frame PPU/RAM snapshots and selected CPU-cycle/PC-stamped PPU/MMC3 events, but it is not a full instruction trace and does not record every CHR fetch or exact dot for each pixel. The official [FCEUX Lua API reference](https://fceux.com/web/help/LuaFunctionsList.html) documents the hooks and cycle counters available to that capture.


### Regional-source follow-up (2026-10-25)

A fresh web search reconfirmed the classifications above and did not locate a
new complete opening disassembly or a Godot-ready frame/audio map:

- The Japanese [CT2 binary wiki](https://w.atwiki.jp/cap2bin/) remains a
  bank-analysis index organized by `0x2000`-byte PRO-ROM banks; its page says
  it was last updated in 2014. It is an offset/data index, not evidence that
  every cutscene instruction or rendered frame was decoded.
- The Japanese [CT2 binary-hacking discussion](https://medaka.5ch.io/test/read.cgi/gameurawaza/1392479553)
  includes a 2023 community post describing continued animation/graphics
  hacking and unresolved game flags. This is evidence of useful community
  analysis, not a complete source listing or a solved opening renderer.
- The Chinese [Hack CT2 page](https://daymoe.com/rom/Hack%20CT2.html) still
  describes editing/preview/conversion features, including CHR and music
  tools. It does not publish the tool's complete source-level game
  disassembly, nor a frame-by-frame opening PPU/APU trace. Its executable and
  archives were not run or treated as authoritative data.
- The public [6502 disassembly repository](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation)
  identifies itself as a disassembly/translation project and notes that most
  comments are Russian. Only locally byte-checked regions are used as evidence
  for the supplied Turkish ROM.

Consequently, external Japanese/Chinese/Turkish research has supplied useful
labels, offsets, animation catalogs, editing techniques, and leads, but has
not supplied all 4,693 rendered opening frames or a proven sample-identical
audio renderer for this ROM revision. The current Godot output still needs
same-input visual and audio verification; see the frame/audio status in
`frame_capture_coverage_and_mapping_status.md` and `ed58_music_mapping.md`.

### Developer interview: storyboard system is a command language (2026-10-25)

The Japanese [Appliv Games developer interview with Michitaka Tsuruta](https://games.app-liv.jp/archives/135497)
is a first-person design-history source for the picture-storyboard system. In
the indexed interview text, Tsuruta says the *Captain Tsubasa II* storyboard
system was rebuilt from the previous game, substantially expanded with
subroutine calls until it resembled a dedicated language, and authored as
assembler-form data specifying sprite motion and frame counts. He also
describes conditional scene playback based on match-calculation results.

This supports modelling the cutscenes as a command interpreter plus data
streams, rather than as unrelated still images. It does **not** publish the
command opcode table, the opening script's per-frame execution, exact PPU/OAM
effects, or the audio-driver mapping. The page returned HTTP 403 to direct
retrieval during this check; the search index exposed the interview text. The
supplied ROM remains the implementation authority: file `0x6010` points to
the opening script at `0x6030`, and local byte/live-dispatch checks documented
above establish which bytes the Turkish ROM actually executes.

### Additional regional search and actionable trace plan (2026-10-25)

A targeted follow-up searched for a complete opening interpreter map or a
frame-to-PC/PPU/APU trace. It did not find one. The new results are useful only
as leads:

- Turkish [8bit “Şut Editleme / Animasyon Kodları”](https://paper55.wixsite.com/8bit/ut-editleme)
  gives byte examples for shot-scene animation edits (including F9/F7/F1 and
  F3-40 patterns), offsets, and character-specific shot mappings. It is a
  shot-editing tutorial, not a general opcode specification or opening trace.
  Check every claimed opcode/offset against the supplied ROM and its live
  handler before applying it to this opening.
- Chinese [Daymoe CT2 code page](https://daymoe.com/rom/code.html) exposes a
  tile-code list, music-mode input, and several scenario-address labels. It is
  a code/data index, not a disassembly or live trace; it does not map the
  cold-open frames to their executed commands and PPU output.
- The Japanese [5ch CT2 binary-hacking thread](https://medaka.5ch.io/test/read.cgi/gameurawaza/1392479553/220-n)
  documents ongoing ROM hacks and community discussion. The checked posts
  discuss modifications and gameplay/event conditions, not a full opening
  interpreter or pixel/audio timing trace.
- A newer Japanese [5ch part 3 thread, posts 414–416](https://medaka.5ch.io/test/read.cgi/gameurawaza/1745002085/414-416)
  lists presentation-command leads for horizontal mirroring (`F5/F6`), a
  background color (`F7`), and an `F9` delay/sound-effect pair; a later post
  corrects the `F9` argument order. These community notes do not identify the
  relevant ROM revision or whether the commands belong to the opening stream.
  The checked Turkish opening itself uses one-operand `F9` background selection;
  its `$87B8` `F5` handler selects palette effects for observed `$00/$01`
  operands and a BG08 raster model for `$10`. The forum meanings therefore
  appear to describe another command context unless further mapping proves
  otherwise.

The fastest next reverse-engineering work is targeted local tracing, not a
global instruction dump or a full recapture:

1. Reuse `tools/diagnostics/trace_opening_dispatch_full.lua`. It already hooks
   145 unique cutscene handler entries plus the dispatcher/common-advance
   paths and records 551 first-pass commands plus 34 replay entries. Add hooks
   only around unresolved helper routines, NMI/queue consumers, and transitions;
   record script pointer/opcode, handler, task state, registers, bank map, and
   CPU cycle at those boundaries.
2. Add scanline/dot fields to the existing selected `$2000/$2001/$2005/$2006/
   $2007` and MMC3 register hooks. The 4,693 end-of-frame PPU/RAM snapshots
   establish final memory state, not fetch order or the first affected pixel.
   FCEUX's official [Lua API](https://fceux.com/web/help/LuaFunctionsList.html)
   documents frame and memory execution callbacks; its [debug tools](https://fceux.com/web/help/Debug.html)
   include the trace logger, code/data logger, PPU viewer, and nametable viewer.
   A concrete case is now resolved: the line-133 `$2006=$2200` reload is
   followed by `$2005=$00,$00` at `$A187/$A18A`. Adding that ROM-derived event
   removed the stale fine-X offset in frames 502/506/758/800; the affected
   lower band is now at least 99.94% exact in targeted comparisons. This
   validates one raster event and its row boundary, not all PPU timing. See
   `reference/diagnostics/raster_fine_x_reset_20261025/` and
   `frame_capture_coverage_and_mapping_status.md`.
   A separate palette boundary is also confirmed locally: the F9 background
   profile was exposing its layout palette before F3's queued `$3F00/$2007`
   packet reached NMI. The renderer now receives only the committed palette.
   Frames 342/352/362/375/378/379 are 100% exact black; frame 380 is 97.79%.
   The same path is traced at later palette reveals 1049/2369/4579, pending
   targeted recapture. See `reference/diagnostics/palette_commit_boundary_20261025/`.
3. Extend the existing pinned-NewPPU instrumentation
   (`tools/diagnostics/instrument_fceux_chr_reads.py`) only for specific
   mismatched scenes. The frame-1522 trace already maps background nametable
   cells to CHR plane bytes, active bank, dot, and screen span. Add sprite
   selection/OAM DMA (`$4014`, `$2003/$2004`) and compact tile/pixel spans where
   a mismatch needs them. The FCEUX [2C02 technical reference](https://fceux.com/web/help/PPU.html)
   explains why fetch/shifter and fine-X timing are needed to relate a write
   to visible pixels.
4. Keep audio as a separate workstream. The APU write trace and ROM music
   sequence are already available; remaining exactness is in the DMC
   timer/buffer/DAC and frame phase. A byte-faithful offline APU model can
   synthesize from ROM data; reproducing FCEUX's exact fetch/stall diagnostic
   trace additionally needs CPU/DMA timing.

The external sources help name routines, enumerate edits, and find candidate
addresses. None found in this pass eliminates the need to confirm execution
and timing against this ROM hash.

The Japanese-language material is now collected in a focused inventory,
including the opening-address memo, cutscene-design interview, opening movie
transcript and story arcs, Guts/through/stat-conversion/special-move analyses,
hidden-event and story-skip inputs, Tecmo Theater context, sound-test controls,
and music catalog/listening notes for SOUND 00–39. It labels each source as a
guide, catalog, interview, forum lead, or offset memo and records whether its
claims were checked against the target ROM. It also records an out-of-scope
Japanese experience-sharing analysis as a lead for future match-system work:
[`japanese_sources_opening_20261025.md`](japanese_sources_opening_20261025.md).


### Music references and timing limits (2026-10-25)

Public audio references are useful for identifying tracks, but none replaces
the supplied ROM's sequence and driver:

- The Japanese [CT2 music index](https://w.atwiki.jp/gamemusicbest100/pages/2453.html)
  labels `SOUND 00` as the opening and lists `SOUND 01` as the title theme.
  Its [opening entry](https://w.atwiki.jp/gamemusicbest100/pages/6979.html) notes
  that the opening music ends as the title appears. This corroborates track
  identity and intended transition, not sample timing.
- The Japanese [VGM Registry opening commentary](https://thytimes.hatenablog.com/entry/2022/02/05/122718)
  identifies the opening track as SOUND 00 and describes approximate musical
  beats near 16 and 39 seconds and the title near the track ending. Those are
  listening estimates, not ROM cue frames or sample-accurate measurements.
- A [Nicozon-hosted BGM collection](https://www.nicozon.net/watch/sm14266393)
  says it follows the Famicom sound-test order and includes jingles. It is a
  user-uploaded listening reference, not a verified ROM extraction or source
  for runtime audio.
- [Emu-Land's NSF catalog](https://www.emu-land.net/consoles/dendy/nsf/c) lists a
  40-song Captain Tsubasa Vol. 2 NSF package. It can help inspect track names
  and sequence behavior; its ROM revision/hash is not established against the
  supplied Turkish ROM.
- The [Khinsider gamerip listing](https://downloads.khinsider.com/game-soundtracks/album/captain-tsubasa-ii-super-striker-1990-nes)
  describes 105 long-form MP3/FLAC tracks. These are listening references,
  not source APU writes or a verified runtime asset.

For the supplied ROM, `$58` intro-music command lookup and driver dispatch are
already traced. The measured audio mismatch at the Start/title transition is
the post-stop filter tail: ROM channel volumes are zero by frame 4662, but the
FCEUX output remains above 1 LSB through frame 4679; the current source-driver
render is above that threshold only through frame 4664. The next audio task is
to render the source-derived APU output through the correct mixer/resampler
while preserving its filter state after the stop command, then compare frames
4661–4679. Captured PCM must remain validation-only, and silence padding is
not an equivalent render. Detailed evidence: `reference/diagnostics/audio/start_tail_audit_20261024.json`
and `reference/diagnostics/audio/rom_source_wavehi_improvement_20261025/README.md`.

### Developer interview on the NES sound pipeline (2026-10-25)

In a first-person [Brave Wave interview with Keiji Yamagishi](https://bravewave.net/ja/interviews/a-conversation-with-keiji-yamagishi/),
Yamagishi describes NES BGM as value-based data entered through an editor,
checked on actual hardware, and iterated. He says he also created the program
and sound driver, and for *Captain Tsubasa 2* he handled the remaining songs,
all sound effects, audio-data creation, and sound programming; Mayuko Okamura
and Mikio Saito (Metal Yuki) contributed compositions. This is useful
first-person context for why a source-sequence/driver reconstruction is the
right target instead of treating the game's music as a ROM-resident WAV.

The interview does not give this game's sequence format, track pointers,
driver bytes, APU timing, or a rendering recipe. Those remain established from
the supplied ROM and local traces, not inferred from the interview. The
interview is also published by an audio label rather than being a ROM
disassembly or technical manual.

### Follow-up source check (2026-10-26)

The current public [assembly/disassembly repository](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation)
still describes itself as a Captain Tsubasa 2 NES disassembly/English
translation and notes that most comments are Russian and the translation is
unfinished. Its annotated `bank_80.asm` begins with the opening runner and
cutscene dispatcher labels. A live-page sample at file offsets `0x10` and
`0x2F` matches the supplied Turkish ROM bytes; the broader pinned-revision
bank-80 match is recorded above. Keep the listing's comments as routine-name
leads and verify byte offsets against this ROM before relying on a new label.
The current repository page does not expose a commit hash for the sampled
master page, so the earlier pinned commit remains the revision for broad byte
coverage.

The Japanese [GCGX sound-test guide](https://gcgx.games/captain-tsubasa2/tips.html)
again identifies the title-screen A+B+START sound-test input and SOUND 00–39
as BGM / SOUND 40–99 as effects. This agrees with the independently parsed
target-ROM pointer index and is catalog/control evidence, not a decoded
sequence or audio-rendering recipe; see
`reference/rom_extract/audio/sound_test_index_audit_20261025.md` and
`sound_test_sfx_index_audit_20261025.md`. This follow-up found no new public
source mapping every opening animation/pixel or replacing the local ROM/live
trace work.

The audio follow-up pinned commit
[`ec03cf06e6bdae0bcd232e3a423e9d259757dc64`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64)
and inspected its `bank_8C.asm` sound-ID bank dispatch. The supplied ROM bytes
at file offsets `$018010` and `$0027` match the annotated disassembly samples;
this supports using its labels as trace leads, but does not prove the full
translation branch is byte-identical. The Japanese GCGX guide and music catalog
continue to support the 40-BGM/60-SFX sound-test index. Zophar's NSF catalog
offers an unverified archive with generic 55-track/50-SFX entries and no hash,
so it does not resolve the production manifest's missing NSF. Full links,
classifications, and byte checks are in
`reference/diagnostics/audio/external_nsf_disassembly_source_audit_20261026.md`;
the missing NSF/build lineage remains open.

The pinned [FCEUX 2.7.0 source](https://github.com/TASEmulators/fceux/tree/a6d03e7968bd77a8156a7c9b628a673753f2f4c6)
was also checked for reset timing. Its default `newppu=0` selects the Old PPU;
the Old-PPU path has a conditional 59,675-CPU-cycle scheduled first-VBlank
budget. However, the retained `--no-config` trace does not serialize `newppu`,
and its first `$2002` edge at cycle 59,572 aligns with New PPU rather than this
Old-PPU budget. Treat the active trace mode as unresolved until a new run logs
it explicitly. CPU-instruction boundary stepping is still needed for the exact
edge. The source paths and conditional calculation are recorded in
`reference/diagnostics/audio/old_ppu_poweron_phase_audit_20261026.md`.

### PPU/MMC3 timing sources for the remaining 45-pixel gap (2026-10-26)

These sources provide hardware/emulator timing context; they do not supply a
decoded animation or raster table for this game:

- [NESdev: The skinny on NES scrolling](https://www.nesdev.org/wiki/The_skinny_on_NES_scrolling)
  explains the shared `PPUADDR`/`PPUSCROLL` write toggle and scroll address `v`,
  and notes that mid-scanline register writes interact with the background
  fetch pipeline. Classification: hardware-programming reference. Its page
  could not be opened by the web reader (403), so use it as explanatory context
  and verify implementation details against local source/trace evidence.
- [NESdev: MMC3](https://www.nesdev.org/wiki/MMC3) describes the IRQ counter's
  filtered PPU A12 rising edge, normally associated with sprite pattern fetch
  near dot 260. Classification: mapper timing reference. The exact edge is
  revision/emulator-model sensitive; it does not prove this ROM's handler dot.
- The [pinned FCEUX 2.7.0 `src/ppu.cpp`](https://github.com/TASEmulators/fceux/blob/a6d03e7968bd77a8156a7c9b628a673753f2f4c6/src/ppu.cpp)
  is primary evidence for the emulator used in the comparison. Its `B2006`
  second-write path assigns `RefreshAddr = TempAddr`; its sprite-fetch path
  reads and advances the shared refresh address. This agrees with the local
  same-run NewPPU trace that attributes all 45 remaining pixels to the ROM
  `$A175/$A178` writes coincident with sprite plane-1 fetches. This is an
  emulator-specific explanation, not proof of physical RP2C02 behavior.
- [FCEUX PPU reference](https://fceux.com/web/help/PPU.html) documents 341 PPU
  dots per normal scanline, 3 PPU dots per CPU cycle, and the shortened
  rendered line on alternating NTSC frames. Classification: emulator
  documentation. These ratios match the predictor's broad timing model, but
  do not explain its measured 3–9-dot residual on the ROM-only `$A160` replay.

For this ROM, local checks still carry the implementation facts: supplied-ROM
SHA-256 is `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`;
the writer bytes are `$A175: 8C 06 20` and `$A178: 8D 06 20`; the pinned FCEUX
same-run trace records the writes and sprite CHR reads. The ROM-only predictor
matches 36/36 stores for scanline, CPU cycle, and value, but its dot prediction
is exact in 0/36. Keep the predictor diagnostic-only; no capture-dot table,
fixed phase correction, or coordinate patch is justified until the phase
residual is derived from the source scheduler/PPU model. The pinned FCEUX
NewPPU source further narrows the likely cause: `FCEUPPU_LineUpdate()` advances
the PPU by bounded chunks and runs the CPU at those boundaries around its
sprite-fetch/MMC3 work, while the current ROM-only predictor converts CPU
cycles continuously at 3 dots per cycle. The `$2006` bus hook may therefore
observe an emulator call boundary that a continuous conversion does not
reproduce. This remains a model hypothesis until an implementation mirrors the
NewPPU chunk subdivision and matches held-out trace frames. See
`reference/diagnostics/oam_all_residual_trace_20261026/README.md` and
`reference/diagnostics/a160_rom_only_dot_prediction_20261026/prediction_report.json`.

### Additional Japanese/Chinese research leads (2026-10-26)

- A Japanese [Hitotsubashi oral-history interview with Yoshiaki Inose](https://hit-u.repo.nii.ac.jp/record/2058186/files/070iirWP18-45.pdf)
  (2018, pp. 27–30 of the PDF) says Tecmo built NES middleware/libraries so
  planners could adjust data such as difficulty without editing the program.
  This is first-person development-history evidence for a data-driven toolchain;
  the discussion is about the earlier *Captain Tsubasa* project and gives no
  CT2 opening opcodes, data structures, or PPU/APU timing. Use it as
  architectural context alongside Tsuruta's CT2 storyboard interview above.
- The Chinese [CT2 code/reference index](https://daymoe.com/rom/code.html)
  exposes a tile-code table, a sound-test input note, and labels for meeting,
  halftime, password, and level-up data areas. Classification: community
  address/data index and cheat reference. It contains no opening execution
  trace or handler implementation; its later-scene addresses do not advance
  the current opening map without target-ROM verification.

Neither lead supplies a target-ROM byte mapping or an opening trace. No new
offset or command interpretation was promoted into implementation facts.

### Japanese/Chinese opening and ROM-tool leads (2026-10-26)

These are useful indexes and tool leads, not a complete opening disassembly.
Their offsets/labels must be checked against the supplied Turkish ROM before
they become implementation facts:

- The Japanese [Captain Tsubasa 2 Binary Wiki](https://w.atwiki.jp/cap2bin/)
  advertises PRO-ROM analysis split into 32 banks, with file ranges from
  `00010h–0200Fh` through `3E010h–4000Fh`. Its currently exposed page list
  contains only 16 generic wiki pages and does not expose the promised bank
  listings, so no opening routine, graphics pointer, or timing fact could be
  recovered from it during this check. Classification: a historical ROM-hacking
  index/lead, not accessible source code or a verified disassembly.
- The Japanese [GCGX sound-test and tips page](https://gcgx.games/captain-tsubasa2/tips.html)
  records title-screen A+B+Start as the sound-test entry and indexes SOUND
  00–39 as BGM and 40–99 as sound effects. This agrees with the local target-ROM
  pointer/index audits, but does not decode the opening's music sequence or
  synthesize its APU waveform. The Japanese [music entry for the opening](https://w.atwiki.jp/gamemusicbest100/pages/6979.html)
  calls it SOUND 00 and describes it as the opening-demo BGM ending together
  with the title transition. Classification: track/catalog and listening
  context, not ROM-level timing evidence.
- The Chinese [Hack CT2 editor project](https://github.com/Novsochetra/Ct2-Editor-Advance)
  and its [feature/change log](https://daymoe.com/rom/Hack%20CT2.html) document
  a CT2-specific ROM editor with indexed model viewing, palette/portrait
  editing, music editing, Tecmo music-data extraction (including E8/E9 command
  handling), music-index conversion, and a test NSF-to-NES association path.
  The repository exposes a compiled Windows editor and data folders, not its
  parser source or a checked-in opening disassembly. Its log cites differing
  Chinese/Japanese addresses and format revisions; it is therefore a strong
  lead for known format families, but not a drop-in extractor for this Turkish
  ROM. No binary was downloaded or run. Classification: game-specific editor
  and data-index evidence, not an execution trace.
- Chinese-language search results also surfaced ROM collections and a CT2 hack
  editor/tutorial, but no public Chinese document that maps every opening
  command, raster event, or per-frame image to code for this ROM. Those results
  are not treated as proof that the game has been fully disassembled.

Local validation status: the project's supplied-ROM SHA-256 remains the value
above. Existing local sound-test index and disassembly checks are recorded in
`reference/rom_extract/audio/sound_test_index_audit_20261025.md`,
`reference/rom_extract/audio/sound_test_sfx_index_audit_20261025.md`, and
`reference/diagnostics/audio/external_nsf_disassembly_source_audit_20261026.md`.
The Japanese sources reinforce the 00–39/40–99 catalog and provide useful
editor/disassembly leads; they do not close the remaining PPU-dot or DMC
waveform gaps.

### Focused Japanese opening-music and optional-event check (2026-10-26)

- The Japanese VGM catalog blog's [opening-music listening entry](https://thytimes.hatenablog.com/entry/2022/02/05/122718)
  calls the piece "Opening" / SOUND 00, says it plays during the opening demo,
  and gives approximate listening landmarks: the main phrase settles around
  16 seconds, a higher-semitone reprise appears around 39 seconds, and the
  track closes with the title-screen transition. It also attributes the
  opening piece to Tsugihisa Yamagishi. Classification: human listening note
  and music catalog, not a score, NSF trace, or source-level timing map. The
  page does not name a ROM revision or establish exact frame/sample positions.
  Local target-ROM evidence independently confirms the cue path in
  `ed58_music_mapping.md`: cold-open `$ED $58` reaches Sound 00's sequence
  header at file `0x1F7BD` through pointer word `$B7AD` at `0x18C98`, with the
  supplied ROM SHA-256 above. The article is useful as a coarse arrangement
  sanity check only; it does not resolve the current PCM mismatch or the
  frame-380 MMC3/CPU scheduling boundary.
- The Japanese [GCGX tips page](https://gcgx.games/captain-tsubasa2/tips.html),
  updated 2026-01-01, says an optional opening event is triggered by Down+B
  while a story-text ball cursor is blinking rapidly; its description says
  the scene refers to Tsubasa arriving in Brazil three years earlier.
  Classification: gameplay guide, not an executable trace. The supplied
  reference input timeline has 9,640 rows and contains no Down or B presses,
  so this alternate event is not part of the captured standard cold-open
  route and does not account for its frame sequence. It remains an optional
  branch to investigate only if the opening slice later expands beyond the
  current standard route; verify the trigger against the Turkish ROM before
  implementing it.

No newly found Japanese/Chinese community source supplies the missing
instruction-level PPU/OAM event map, the precise MMC3 IRQ/CPU edge ordering,
or a sample-identical ROM-only APU/DMC renderer. The existing byte-checked
disassembly and pinned FCEUX source remain the useful technical references;
the two new Japanese pages add only coarse soundtrack context and an
out-of-route gameplay lead.

### Pinned FCEUX DMC timer source and measured edge check (2026-10-26)

The pinned [FCEUX 2.7.0 `src/sound.cpp`](https://github.com/TASEmulators/fceux/blob/a6d03e7968bd77a8156a7c9b628a673753f2f4c6/src/sound.cpp)
contains `FCEU_SoundCPUHook()`: it subtracts CPU hook cycles from `DMCacc`,
executes timer edges while the accumulator is non-positive, advances the DMC
shift/buffer state, and reloads the period. Classification: primary source for
the pinned emulator's DMC scheduling and WaveHi input path, not proof of
physical APU timing. A local validation-only patch records `absolute_cycle +
DMCacc` at each expiration without recording PCM. Against a fresh replay of
the supplied ROM and the same 4,693-frame input timeline, the ROM stepper's
`edge_cycle` matches **7,076/7,076** timer edges in frames 367–380 and
**99,820/99,820** in frames 4481–4661; late hook-state snapshots differ only in
the accumulator for 19,765 rows. The full-edge candidate still only moves
whole-file PCM correlation from 0.9886688 to 0.9887298 and has late-loop
correlation 0.86960/0.87884. Thus source timer-edge timing is now checked in
these windows, but the soundtrack is not sample-identical; focus next on
WaveHi/filter accumulation and output phase. No FCEUX timing/PCM was used to
synthesize runtime sound and the active Godot WAV is unchanged. Trace, patch,
hashes, and metrics: `reference/diagnostics/audio/fceux_dmc_timer_edge_validation_20261026/`
and `reference/diagnostics/audio/dmc_inner_edge_replay_audit_20261026.md`.

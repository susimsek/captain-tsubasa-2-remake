# Cayosa CT2 archive review

Date checked: 2026-10-24  
Source page: [Cayosa CT2 archive](https://cayosa.ysepan.com/) (the user supplied the password; credentials are intentionally not recorded here).  
Archive reviewed: `Data 2015.10.6.zip` from the page's data collection folder.  
Archive SHA-256: `3d6af18512f73ad50d8dfa1dc15b3dd3a9d44edca83ed53b98465817b6a868e8`.

## What the archive contains

The ZIP has 41 entries grouped under Sound, Character, Colour, Contingent, Drama, Goalkeeper, Goals, Model, Other, and Skill. Although the site requires a password to enter, the ZIP entries themselves are not encrypted. It is a community ROM-editing/reference collection: legacy Word documents, Excel workbooks, a CHM help file, a JPG, and a small text file. It is not source code for the game, a full 6502 disassembly, or a per-frame emulator trace. The workbook has GIF filenames/links for some scenario entries, but those are not frame-by-frame CPU/PPU/APU records.

The most relevant items for the cold opening and title boundary are:

| Archive item | Useful information | Limitation |
| --- | --- | --- |
| `Drama/6010-A00F 剧情完工.xls` | A scenario-block index for file/RAM area `0x6010–0x800F`; entry `00` is labeled `兔子开头` (“rabbit opening”), pointer bytes `20 A0`, followed by a 641-byte event stream, Japanese text, Chinese translation, and a GIF filename. | Its stream is not the Turkish stream after the first 32 bytes. The translations and GIF references help identify narrative/content, but do not provide executed PC, PPU/OAM writes, or frame timing. |
| `Drama/note.doc` | A second index labels action `8D` as the opening rabbit and proposes scene/background labels `15` for a title scroll, `16` for Continue, and `17` for the title screen. | These are community labels. The local ROM table and observed title state support some scene IDs, but the note is not a frame schedule or interpreter specification. |
| `Sound/Sound.doc` | Lists sound/music command IDs and calls `0x58` the opening theme, “Super Striker.” | This is a community sound index. The local driver trace is still required to establish how the Turkish ROM resolves and plays a cue. |
| `Colour/剧情颜色地址.doc` | Relates addresses `D310`, `D320`, `D330`, and `D3FB` to opening-scene palette data, including Tsubasa, close-up, and Hyuga tackle references. | Candidate address/role mappings; local project data verifies `D310`, while the other claims need their own ROM/trace checks. |
| `Character/游戏内台词相关.xls`, `Model/普通动画总结.txt`, and `Other/F1--FE的作用.doc` | Candidate dialogue, animation, and event-command references. | These are general hacking notes; each address/meaning must be checked against the supplied Turkish ROM and a live opening trace. |

The separate `F7和XX代码的特效.zip` (SHA-256 `319d5e8b386b41f500854f48380f802859cb1ffa1527c5ca6ba34887d1c08ebb`) contains only `Untitled.txt`. It describes F7/XX screen and portrait effects and gives shot-prelude patch examples around `0x21D0C` and inserted code at `0x3FD20`. This is a modding tutorial, not an opening trace. Both patch locations were checked against the Turkish ROM: `0x21D0C` begins `4C AB` (the suggested patch point still has its original bytes), while `0x3FD20` contains `55 7A 61 6B FC` followed by `FF` fill, so it is not free space. Applying that tutorial's patch would overwrite existing ROM data.

## Checks against the supplied Turkish ROM

The target ROM is 393,232 bytes with SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

- The archive labels the opening entry with pointer bytes `20 A0`. In the target ROM, file offset `0x6010` begins with little-endian pointer `$A020`, and file offset `0x6030` begins the event stream. This independently corroborates the opening table layout already recorded in `README.md` and `cutscene_boot_task_install_trace.md`.
- The first 32 bytes of the archive's 641-byte entry-00 stream exactly match the target ROM's `reference/rom_extract/intro/cutscene_00.bin` prefix: `E8 01 F9 00 FB 01 8D E9 DF EA ED 58 DC F1 01 EC 00 F9 01 FB 01 6E F8 0A F3 00 F5 00 ED 68 F2 05`.
- The entire archive stream is **not** byte-identical: 584 of 641 byte positions differ, with the first divergence at stream offset `+0x20`. Treat the archive as a close regional/revision reference for the entry structure and opening prefix, not as source bytes to import into the Turkish build. The exact cause of later differences has not been established.
- The stream's `ED 58` command is at target ROM file offset `0x603A`. `Sound.doc` independently labels `0x58` as the opening theme. The local `ed58_music_mapping.md` driver trace remains the target-ROM evidence for the actual sequence pointer and playback route.
- `FB 01 8D` and `FB 01 6E` occur in the shared opening prefix. The archive corroborates that those IDs are used by the opening script; it does not on its own define their animation frames or duration.
- The archive's `Drama/note.doc` labels animation `8D` as the opening rabbit, and the opening script's first animation selection is exactly `FB 01 8D`. Its claimed title IDs `15/16/17` are leads for the separately observed title transition; the local bank-0 `$E010` table and live title path already support ID `17` as the title menu. Do not treat the document's other scene labels as confirmed without the corresponding ROM table and runtime use.
- The opening's cutscene script has no `$F7` byte, and the existing live opcode trace reports no `$F7` dispatch. The cutscene interpreter's `$F7` vector resolves to a stock handler that does not read an `XX` operand; this is separate from animation VM `$F7`, which the opening runner animation uses for ROM-confirmed velocity/acceleration fields at `$A0CA` and `$A0E0`. The archive tutorial's portrait/screen-effect meanings therefore are not an explanation of an opening cutscene command. See `cold_start_vector_handler_semantics.md` and `animation_6e_runtime_trace.md` for local code and live-state evidence.

## Result for the opening reverse-engineering work

This is a useful independent source for opening block organization, original scenario text, an opening music-ID lead, and general command/visual-effect hypotheses. It does **not** solve the missing every-frame mapping from CPU program counter to cutscene command, PPU/nametable/OAM changes, raster timing, and APU state. Keep the ROM-derived Turkish stream and local traces canonical. Any archive-derived interpretation should be recorded as a lead until its address and behavior are checked against this exact ROM revision.

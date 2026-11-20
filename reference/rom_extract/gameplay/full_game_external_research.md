# Full-Game External Research Leads

Checked: 2026-11-20  
Target ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`  
SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

This register collects useful Japanese, Chinese, Turkish, and English CT2
references and maps each one to a bounded issue in
[`GAME_REVERSE_ENGINEERING_PRD.md`](../../../GAME_REVERSE_ENGINEERING_PRD.md).
The sources help locate questions; they do not establish this Turkish ROM's
addresses, game rules, graphics, or timing without local verification.

## Evidence Rules

- The supplied ROM hash above is the implementation authority. Resolve every
  candidate CPU address through its mapper bank to a file offset before using it.
- Guides and manuals document intended controls and user-visible rules, not
  executable code or frame timing.
- ROM editors and community catalogs document tool features or user-maintained
  indexes, not necessarily the original game's data layout. Some target other
  regional revisions or modified ROMs.
- Annotated assembly is useful only across byte-matched ranges. A matching
  disassembly label does not establish a live caller, state, or route.
- Runtime data and behavior must be decoded from this ROM. External extracted
  assets, emulator captures, and editor output are not runtime resources.

## Japanese Sources

| Source | Type and useful lead | Limit | Follow-up |
|---|---|---|---|
| [Famicom manual transcription](https://setsumei.cloudfree.jp/famicom/captaintsubasa2/captaintsubasa2.html) | Manual text covering title controls, meetings, team data, offense/defense, substitutions, set plays, penalty shootouts, and Guts costs. Useful for user-visible flow and acceptance cases. | Manual text provides no ROM addresses, state layout, or implementation timing. | RE-077, RE-095 |
| [GCGX special-move tables](https://gcgx.games/captain-tsubasa2/sp.html) | Community tables for shot/pass/dribble move values, energy costs, ball conditions, and users. | Secondary analysis; verify IDs, units, and handler semantics locally. | RE-076 |
| [GCGX Guts rules](https://gcgx.games/captain-tsubasa2/guts.html) | Reports command costs, movement drain, recovery, and Misugi-specific behavior. | Verify calculations and exceptions in ROM handlers; do not treat guide values as implementation constants. | RE-076 |
| [GCGX experience awards](https://gcgx.games/captain-tsubasa2/exp.html) and [level/experience rules](https://gcgx.games/captain-tsubasa2/lv.html) | Reports match/action experience, level thresholds, experience sharing, and a very low award after the France match. | These are guide claims. The reported bug, sharing map, and thresholds need target-ROM confirmation. | RE-075, RE-091 |
| [Japanese CT2 binary wiki](https://w.atwiki.jp/cap2bin/) | Bank-analysis index and address-navigation lead. | The accessible index does not provide a retrievable complete bank-by-bank disassembly. It is not evidence that all code has been decoded. | RE-097 |

## Chinese Sources

| Source | Type and useful lead | Limit | Follow-up |
|---|---|---|---|
| [Hack CT2 feature/change log](https://daymoe.com/rom/Hack%20CT2.html) | Editor feature notes cover teams, rosters, formations, player/keeper stats, move data and costs, AI probabilities, experience, portraits, address conversion, CHR/model viewing, and music extraction/index conversion including E8/E9 notes. | It describes an editor, not the game's source code. It supports multiple regional/hacked layouts and warns of relocated data; do not run its binary or copy its addresses into runtime. | RE-026, RE-036, RE-092, RE-093, RE-096 |
| [Daymoe CT2 code/reference page](https://daymoe.com/rom/code.html) | Lists candidate scene labels for meetings, halftime, password, and level-up screens; also claims A+B+Start enters a sound-test mode and links a Chinese tile-code table. | CPU address versus file-offset meaning and target revision are not always stated. Sound-test input has not been confirmed on this ROM. | RE-032, RE-040, RE-077 |
| [Book118 Chinese-translated gameplay guide](https://max.book118.com/html/2019/0823/6045234013002100.shtm) | Secondary descriptions of commands and stamina behavior; useful for generating questions about later match states. | No target-ROM revision, code addresses, or trace evidence is supplied. Use as a checklist only. | RE-077, RE-095 |
| [`光线.txt` at pinned Ct2-Editor-Advance revision](https://github.com/Novsochetra/Ct2-Editor-Advance/blob/bfb43daab030fdf8eaa2957ff359899eff89e810/Code_data/%E5%85%89%E7%BA%BF.txt) | User notes label RAM fields `$0523`, `$0524`, `$0528`, and `$052B`, with a special-shot/effect example. | Observational labels, not a disassembly; field meanings and effect values may vary by ROM. | RE-036, RE-092 |
| [`data/OtherData/0524.txt`](https://github.com/Novsochetra/Ct2-Editor-Advance/blob/bfb43daab030fdf8eaa2957ff359899eff89e810/data/OtherData/0524.txt) and [collated `$0524/$0528` notes](https://github.com/Novsochetra/Ct2-Editor-Advance/blob/bfb43daab030fdf8eaa2957ff359899eff89e810/Code_data/0524%200528%E8%B5%84%E6%96%99%EF%BC%88%E5%87%B3%E5%AD%90%E7%BB%99%E7%9A%84%29.txt) | Candidate background, portrait, and trajectory identifiers. The editor also has a [cutscene-animation ID catalog](https://github.com/Novsochetra/Ct2-Editor-Advance/blob/bfb43daab030fdf8eaa2957ff359899eff89e810/Code_data/%E5%89%A7%E6%83%85%E5%8A%A8%E7%94%BB%E4%BB%A3%E7%A0%81.txt). | Some catalogs disagree with each other; names do not establish CHR composition, palette, OAM, or timing. | RE-036, RE-093, RE-094 |
| [Japanese glyph table `CT2_J.txt` in the same pinned repository](https://github.com/Novsochetra/Ct2-Editor-Advance/blob/bfb43daab030fdf8eaa2957ff359899eff89e810/data/Tile/CT2_J.txt) | Candidate character-code-to-glyph index for checking text decoding. | It is an editor reference table and may target a different regional build. | RE-032, RE-094 |
| [Ct2-Editor-Advance repository](https://github.com/Novsochetra/Ct2-Editor-Advance/tree/bfb43daab030fdf8eaa2957ff359899eff89e810) | Public text catalogs and reference folders can point to teams, effects, characters, animation IDs, and music formats. | The short README and editor binary do not constitute a full 6502 disassembly or a verified runtime specification. Inspect text/catalog files only and record the pinned commit. | RE-090 through RE-096 |

The pinned editor catalogs are user-maintained and contain conflicting labels.
For example, background and portrait names in the `$0524` list do not always
agree with the collated `$0524/$0528` notes. Preserve the conflict until ROM
bytes and a same-ROM route resolve it.

## Turkish Community Sources

| Source | Type and useful lead | Limit | Follow-up |
|---|---|---|---|
| [Player IDs and cheat RAM slots](https://tsubasatr.net/konu-ct-2-cheat-kod-yazimi-183.html) | Human-readable player IDs and RAM-slot clues; the existing first-team report byte-checks the São Paulo roster order and pointer progression for this ROM. | RAM cheat slots are not ROM offsets or complete player records. | RE-026, RE-021, RE-024 |
| [Player names and text codes](https://tsubasatr.net/konu-ct-2-oyuncularin-isimlerini-degistirme.html) | Candidate player-name offsets and text codes. | Existing checks cover only listed entries; one name does not establish the complete text table or active-player schema. | RE-026, RE-021, RE-032 |
| [Special-move code tables](https://tsubasatr.net/konu-ct-2-tum-sutlarin-ve-diger-ozel-hareketlerin-kodlari-asil-icerik.html) | Six community lists split across shots, passes, dribbles, slides/tackles, combination moves, and blocks. Existing evidence byte-checks example Tsubasa/Misaki lists. | A code index does not establish move eligibility, action calculations, caller paths, or animation timing. | RE-023, RE-076 |
| [Roster expansion discussion](https://tsubasatr.net/konu-captain-tsubasa-2-milli-takim-kadro-sayisini-21-in-uzerine-cikarma.html) | Records a hacking question about extending Japan's roster beyond 21 and notes that simple pointer-list edits may not suffice. | It is a discussion of modifying the game, not evidence that the original ROM supports a larger roster. | RE-026 |
| [Player-behavior code archive post](https://tsubasatr.net/konu-oyuncu-davranis-kodlari-hepsi-bir-arada.html) | Claims to link categories for player, keeper, and second-half behavior. | The archive was inaccessible in the prior source check and remains uninspected; do not cite or import its claimed contents as facts. | RE-060 (only if the archive becomes accessible) |
| [Match/period cheat lists](https://tsubasatr.net/konu-mac-kodlari.html?pid=121078) | RAM-value leads for navigating team and match contexts during research. | Cheat writes are not game transitions and must never seed runtime or replace ordinary-input route verification. | RE-020, RE-050, RE-077 |
| [Cutscene-editing tutorial](https://tsubasatr.net/konu-ara-sahne-editleme-beklenen-paylasim-detayli.html) | Example command streams and candidate bytecode meanings for scene/background/animation/audio/wait operations. | Hacking tutorial examples are not proof of this ROM's opcode semantics. | RE-031, RE-094 |

The current first-match source report already contains the byte-check details
for the Turkish player IDs, move lists, music pointer, and menu renderer:
[`online_sources.md`](online_sources.md). Continue that report for first-match
facts; use this full-game register for other teams and systems.

## English / Russian Annotated Disassembly and Production Context

| Source | Type and useful lead | Limit | Follow-up |
|---|---|---|---|
| [Captain Tsubasa 2 English Translation/disassembly, pinned at `ec03cf0`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64) | ca65/ld65 project with bank listings and code labels. Existing reports byte-check selected ranges in opening and match-rendering banks. | Several inspected banks contain mismatches or unannotated ranges; labels do not prove a live route or transfer directly to this Turkish build. | RE-097 |
| [Keiji Yamagishi interview](https://bravewave.net/ja/interviews/a-conversation-with-keiji-yamagishi/) | First-person production context credits multiple composers and says Cinema Display music was shaped around scene imagery and length. This motivates checking scene/music boundaries as a linked source event. | No ROM track IDs, sequence bytes, driver code, or cue timing are supplied. | RE-045 |

## Issue Map

| Backlog issue | External material to inspect | Target-ROM outcome |
|---|---|---|
| RE-026 | Turkish player-ID/name/roster notes; Chinese editor roster catalogs; 21-player expansion discussion | Separate original roster/record layout from cheat slots and hack-only capacity. |
| RE-036 / RE-092 | Chinese `$0523/$0524/$0528/$052B` and special-effect catalogs | Identify local field writers/readers and trace one selected effect from source to visible result. |
| RE-094 | Chinese glyph and animation tables | Verify a character mapping and one animation ID through the target ROM and production consumer. |
| RE-076 | Japanese move/Guts tables and Turkish six-family move lists | Verify one bounded move's ID, eligibility, cost, calculation, and result handler. |
| RE-075 / RE-091 | Japanese experience, level, inheritance, and post-France bug claims | Confirm or correct formulas and sharing with target-ROM data and route traces. |
| RE-077 / RE-095 | Japanese manual and Chinese gameplay guide | Build a ROM-routed acceptance matrix for commands, substitutions, set plays, penalties, and goalkeeper choices. |
| RE-045 / RE-096 | Chinese music-tool notes and production interview | Map one scene's ROM cue, sequence, stop/loop condition, and transition boundary. |
| RE-097 | Pinned annotated assembly project and Japanese bank index | Reuse only byte-matched labels in the exact target-ROM bank/window. |

## Search Result

These sources provide substantial data indexes, editor functionality notes,
manual-level rules, and partial annotated code. The inspected public sources did
not establish a complete, byte-verified Chinese or Japanese disassembly of the
whole game. Continue with one source question at a time and use the target ROM
and same-ROM traces to settle it.

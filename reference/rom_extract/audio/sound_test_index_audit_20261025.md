# Title-screen sound test and BGM index

Checked: 2026-10-26  
Target ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

## Sound-test entry and controls

The sound test is a hidden **in-game** title-screen mode, not FCEUX's separate
NSF-file player. The Japanese guide says to press A+B+Start on the title
screen; it lists sound-test ordinals 0–39 as BGM and 40–99 as sound effects.
It gives A=play, B=stop, and Start=exit. Two Chinese guides also say to hold
A+B and then press/hold Start. Some older English, Spanish, and Portuguese
guides add Select to the combination. Use A+B+Start as the best-supported
minimal combination; the input path has not yet been independently replayed
against this exact Turkish ROM.

## ROM cross-check of the 40 BGM entries

The Turkish community post “CT2 müzik sistemi nasıl çalışır?” lists a target
sequence offset and pointer-table word location for sound-test ordinals 00–99.
For BGM 00–39, all 40 listed pointer words were checked against the supplied
ROM. Each little-endian word resolves to its listed sequence file offset using
the corresponding PRG bank and CPU mapping. The verified list is machine
readable in [`sound_test_bgm_index_00_39.json`](sound_test_bgm_index_00_39.json).

This establishes all 40 BGM **sequence locations**, not independent PCM files
or finished Godot tracks. Titles are generally not named in the sound test;
the menu uses ordinals. Sound-test ordinals also differ from runtime sound
queue IDs. For example, opening runtime cue `$ED $58` maps through the game's
driver to sound-test BGM 00 at ROM file offset `0x1F7BD`; it does not mean
sound-test BGM 58. That mapping is recorded in
[`ed58_music_mapping.md`](../intro/ed58_music_mapping.md).

The 60 sound-effect ordinals 40–99 are now byte-audited in
[`sound_test_sfx_index_audit_20261025.md`](sound_test_sfx_index_audit_20261025.md):
all 60 forum-listed pointer words resolve to the target offsets in this ROM,
and 189 channel pointers from their sequence headers were mapped to bytes in
bank `$0C`. The same note maps runtime IDs seen in the opening queue trace to
sound-test ordinals where an index entry exists. This verifies pointer/header
routes, not a full decoder or rendered SFX waveforms; the hidden sound-test
input path still has not been replayed against this Turkish ROM. The project
currently packages the opening timeline WAV, not 40 separate BGM assets. One
Chinese album comment calls this “100 songs”; treat that as informal wording
for the 100 sound-test entries, since the Japanese guide and verified index
separate them into 40 BGM entries and 60 sound effects.

## Japanese catalog labels for SOUND 00–39

The Japanese music catalog gives these scene/track labels. They are community
metadata, not names stored in the ROM; blank entries below are blank in that
catalog. The ROM audit verifies ordinal-to-sequence locations, not the
catalog's scene interpretation.

| Ordinal | Catalog label / use |
| --- | --- |
| 00 | Opening (the specific opening demo theme; catalog says it ends as title appears) |
| 01 | Title |
| 02 | Scenario: first scene |
| 03 | Meeting |
| 04 | Scenario: main BGM |
| 05 | Scenario: before Flamengo match |
| 06 | Scenario: rumors about World Youth teams |
| 07 | Unlabeled |
| 08 | Coimbra introduction scene |
| 09 | Unlabeled |
| 10 | Scenario: “So it seems the rumors were true” |
| 11 | Scenario: Sanae |
| 12 | Carlos after West Germany match (catalog wording) |
| 13 | Learning the Cyclone |
| 14 | Brazil match meeting |
| 15 | Rio Cup victory story scene |
| 16 | High-school championship victory story scene |
| 17 | World Youth victory story scene |
| 18 | Final story scene |
| 19 | Staff roll |
| 20 | Game over |
| 21 | Charlie's theme |
| 22 | Five minutes before match end |
| 23 | PK / password entry |
| 24 | Our team scores |
| 25 | Opponent scores |
| 26 | Foul |
| 27 | São Paulo FC |
| 28 | Nankatsu |
| 29 | Japan Youth |
| 30 | Opponent: Flamengo (catalog credits Mikio Saito) |
| 31 | Opponent: Toho Academy |
| 32 | Opponent: West Germany |
| 33 | Opponent: Brazil |
| 34 | Opponent: Rio Cup arc |
| 35 | Opponent: high-school championship arc |
| 36 | Opponent: Japan Cup arc |
| 37 | Opponent: Asia preliminary arc |
| 38 | Opponent: qualifying-league arc |
| 39 | Opponent: final-tournament arc |

The Japanese catalog credits the soundtrack to Tsugutoshi Yamagishi, Mikio
Saito, and Mayuko Okamura; its SOUND 00 opening entry is attributed to
Yamagishi. Treat this as soundtrack metadata, not a ROM fact or a per-track
composition audit. See the focused source inventory at
[`../intro/japanese_sources_opening_20261025.md`](../intro/japanese_sources_opening_20261025.md).

## External sources

- [Japanese CT2 guide: sound-test code, BGM/effect ranges, and controls](https://gcgx.games/captain-tsubasa2/tips.html)
- [Japanese CT2 soundtrack catalog: SOUND 00–39 labels and composer metadata](https://w.atwiki.jp/gamemusicbest100/pages/2453.html)
- [Japanese opening-theme entry: SOUND 00 identity and title transition note](https://w.atwiki.jp/gamemusicbest100/pages/6979.html)
- [Turkish CT2 music-system post: sequence and pointer-table offsets for Sound 00–99](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html)
- [Chinese FC guide: title-screen A+B, then Start](https://www.santaitu.com/youxiwenzhang/youxigonglue/2026-05-30/1779.html)
- [Chinese Angel2 code page: sound mode input](https://daymoe.com/rom/code.html)
- [Chinese soundtrack discussion: informal “100 songs” claim](https://xiapi.quotsoft.net/album/dp/dP8DtGfd9a5/)
- [Older GameFAQs guide with the alternate A+B+Start+Select combination](https://gamefaqs.gamespot.com/nes/562939-captain-tsubasa-ii-super-striker/faqs/72906)
- [FCEUX documentation: NSF is a distinct supported file format](https://fceux.com/web/help/Gamefilecompatibility.html)

### Fresh forum follow-up (2026-10-26)

The Turkish forum page is an active community explanation, not a frozen
technical specification. Its first post supplies sequence/pointer offsets for
SOUND 00–99 and a proposed 63-instrument map. A reply posted on 2026-10-26 says
the wider explanation contains clear mistakes and that a corrected, more
complete account is forthcoming. The local ROM audit independently validates
all 40 BGM and 60 SFX pointer words and their target sequence locations, so
those verified table entries remain useful. The instrument interpretation,
the claimed unexamined driver subranges, and any implied timing/rendering rules
remain provisional until byte-by-byte and execution-path checks are completed;
they are not used as PCM synthesis inputs. See the [forum discussion](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html).

## Disassembly cross-check: driver and opening track

The public [Captain-Tsubasa-2-English-Translation repository](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64)
is an annotated 6502 disassembly/translation project (its README says most
comments are Russian). Its audio-specific source files are the pinned
[`bank_8C.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_8C.asm)
and [`bank_8F.asm`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_8F.asm).
The first is executable audio-driver code plus its sound-pointer table; the
second is music sequence data. This is stronger than a music catalog or ROM
editor, but the repository targets a different expanded/mapper-changed build.
Its labels and interpretations are therefore leads; the target Turkish ROM
bytes and local traces remain authoritative.

For target ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, the
following independent byte checks agree with those listings:

| File offset | Target ROM bytes | Disassembly interpretation | Check |
| --- | --- | --- | --- |
| `0x18010` | `A2 05 BC 00 07 C0 32 B0 0E` | `bank_8C.asm` entry `$8000`, sound-engine update loop | Exact bytes; bank `$0C` maps CPU `$8000` to file `0x18010`. |
| `0x18BEA` | `42 8E 5B 8E 68 8E 89 8E ...` | `bank_8C.asm` table at CPU `$8BDA`, runtime sound-ID pointers | Exact prefix; this is the driver's runtime sound table, not the sound-test ordinal list by itself. |
| `0x18C98` | `AD B7 59 AC 00 A0 FE 9F ...` | `bank_8C.asm` CPU `$8C88` labels internal sound `$58` as the opening theme and points to `$B7AD` | Exact pointer bytes. Bank `$0F` maps `$B7AD` to file `0x1F7BD`. |
| `0x1F7BD` | `04 BA B7 05 BD BA 06 5E BD 07 3F BF FF` | `bank_8F.asm` music header for internal sound `$58`, with four channel pointers | Exact header bytes and terminator. |

This cross-check supports the local `ED $58` → runtime sound `$58` → pointer
at `0x18C98` → sequence header `0x1F7BD` route documented in
[`../intro/ed58_music_mapping.md`](../intro/ed58_music_mapping.md). Keep the
number spaces distinct: the Japanese guide's sound-test BGM ordinal `00` is
not the disassembly's internal sound ID `$58`. The separate Turkish forum
index maps ordinal `00` to this same sequence offset; all 40 BGM pointer words
from that index are byte-checked in the JSON audit above. Neither source
proves frame-accurate APU timing or a complete standalone audio renderer.

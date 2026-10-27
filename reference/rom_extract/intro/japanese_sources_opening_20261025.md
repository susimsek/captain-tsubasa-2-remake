# Japanese-language sources for the opening/title slice

Checked: 2026-10-25  
Target ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

This note collects the Japanese-language material relevant to the cold opening,
title screen, cutscene system, and music. It distinguishes what a source says
from what has been checked against the supplied Turkish ROM. Community labels
are leads, not executable proof. The ROM bytes and local execution traces remain
the implementation authority.

## Findings at a glance

| Source | What it contributes | Evidence class / limit |
| --- | --- | --- |
| [GCGX tips and tricks](https://gcgx.games/captain-tsubasa2/tips.html) | Title-screen sound test: A+B+Start; SOUND 00–39 BGM, 40–99 sound effects; A plays, B stops, Start exits. Also describes an optional opening hidden event using Down+B when the story-ball cursor blinks quickly. | Japanese gameplay/analysis guide. Useful for controls and track ranges, not a ROM trace. |
| [GCGX basic information and controls](https://gcgx.games/captain-tsubasa2/info.html) | Describes the command-based real-time simulation and controls: D-pad moves cursors/players, A confirms, B cancels/opens command input/speeds text, Select skips event scenes, Start has no listed action. | Japanese gameplay/analysis guide; these are general controls, not proof of behavior at every opening/title state in this Turkish ROM. |
| [GCGX story guide](https://gcgx.games/captain-tsubasa2/story.html) | Summarizes the prologue: Japan wins the international junior-youth final, Tsubasa later joins São Paulo FC in Brazil, and the Rio Cup begins. | Japanese walkthrough/story summary. Useful for ordering and identifying narrative beats; it does not describe the title-to-story transition's code or exact screen timing. |
| [San Paulo FC scenario index](https://tsubasa.yamagomori.com/ct2/scenario/0-index.html) and [Rio Cup / opening transcript](https://tsubasa.yamagomori.com/ct2/scenario/m-1.html) | Indexes the story in eight sections: Rio Cup, high-school championship, Japan Cup, Asian qualifiers, expedition/World Youth qualifiers, World Youth finals, final/ending, and cast/staff. The Rio page labels the opening movie and transcribes its narration and player introductions, then the prologue and Rio Cup scenes. | Japanese scenario transcript/walkthrough. Helpful for scene identity and Japanese narrative text; not the Turkish ROM's exact localized text, event bytes, or timing. |
| [San Paulo FC manual index](https://tsubasa.yamagomori.com/ct2/manual/m0-index.html), [manual page 1](https://tsubasa.yamagomori.com/ct2/manual/man1.html), and [manual page 2](https://tsubasa.yamagomori.com/ct2/manual/man2.html) | Reproduces a 16-part manual: story and start/continue, meeting, team data, screen guide, offense, defense, team changes, set pieces, PK, Rio Cup, player introductions, command Guts costs, and winning tips. Page 1 explicitly says KICK OFF starts and CONTINUE opens score-memo entry. | Manual transcription/reference. Stronger evidence for intended controls than a fan tip, but it does not show this Turkish ROM's exact title cursor/frame timing. |
| [San Paulo FC progression chart](https://tsubasa.yamagomori.com/ct2/memo/chart2.html), [player-data index](https://tsubasa.yamagomori.com/ct2/data/ct2-data.html), [experience inheritance](https://tsubasa.yamagomori.com/ct2/memo/inheritance.html), and [level/experience table](https://tsubasa.yamagomori.com/ct2/memo/nextexp.html) | Covers tournament match order, time/extra-time/PK and loss routing, opponent/player rosters, level-specific player data, experience inheritance between teams, and experience thresholds through level 64. The site notes that some player stats are reordered to a later series' format. | Community-compiled gameplay/data tables, mostly outside this opening. Treat encoding/order, values, and rules as leads; cross-check target-ROM bytes and observed state before implementation. |
| [San Paulo FC other-analysis index](https://tsubasa.yamagomori.com/ct2/other/other.html) | Links four game-data analyses: Guts costs, the effect of a “through” action/pass, converting encoded values to displayed stats, and special-move power. | Gameplay/data analysis outside the opening slice. Values and rules still need validation against the supplied Turkish ROM before implementation. |
| [San Paulo FC cheat and hidden-event page](https://tsubasa.yamagomori.com/ct2/memo/uru.html) | Lists title sound-select input, the rapidly blinking story-ball cursor plus Down+B hidden-story trigger (including the opening), Select to skip a pre-match story, and other gameplay secrets. It cites *Ura-waza Daijirin '95* and a 1995 *Family Computer Magazine* supplement. | Published cheat/walkthrough information, not a trace. It overlaps GCGX and gives useful provenance for the hidden-event lead. |
| [Tecmo Theater overview](https://www.ne.jp/asahi/krk/kct/misc/tecmotheater.htm) | Places CT2 as the fourth Tecmo Theater game and characterizes its presentation as more elaborate than CT1, including opposing-player cut-ins. | Retrospective series overview, useful design context only; it does not expose CT2's command interpreter or rendering code. |
| [Japanese Famicom game catalog entry](https://w.atwiki.jp/famicom-log/pages/67.html) | Supplies title metadata (Famicom, Tecmo, 1990-07-20, password continuation) and points to a manual. | Catalog/reference metadata; no reverse-engineering evidence. |
| [Japanese game-catalog review and system summary](https://w.atwiki.jp/gcmatome/pages/3390.html) | Summarizes system differences such as command/stat categories, field radar, player-controlled defense, and position-targeted passing. | Secondary game review/wiki; useful index of mechanics to research, not a measured or byte-verified rule table. |
| [GameCenter GX analysis blog: shared experience](https://gamecentergx.blog.fc2.com/blog-entry-4758.html) | Says match experience carries across team changes and describes correcting an earlier analysis after discovering an internal transfer. | Japanese gameplay reverse-engineering article, outside the opening/title slice. Treat as a lead for later match rules, not opening evidence or a byte-level ROM map. |
| [Captain Tsubasa 2 Binary Wiki](https://w.atwiki.jp/cap2bin/) | The home-page menu lists 32 PRO-ROM bank ranges, from `0x00010–0x0200F` through `0x3E010–0x4000F`, alongside headings for modification tools/examples/procedure. | User-maintained binary-hacking wiki, last shown update 2014-02-22. The public page list currently contains 16 pages and does not list bank-analysis pages; the bank ranges are menu text, not evidence that 32 detailed bank pages or a complete disassembly are available. |
| [Japanese address memo mirror](https://daymoe.com/rom/code/%E3%82%AD%E3%83%A3%E3%83%97%E3%83%86%E3%83%B3%E7%BF%BC2%E3%82%A2%E3%83%89%E3%83%AC%E3%82%B9%E3%83%A1%E3%83%A2.html), originally listed at the [Captain Tsubasa uploader](https://u9.getuploader.com/cap/download/73) | Opening/demo, post-Start demo, palettes, probable opening graphics/management areas, plus many game-wide scenario, character, team, and move offsets. | Rough offset memo. Several graphics labels contain `?`; it has no target-ROM hash or live trace. |
| [Michitaka Tsuruta developer interview](https://games.app-liv.jp/archives/135497) | The storyboard system was expanded with subroutine calls into a dedicated command language; sprite start/end positions and frame counts were authored as assembler-form data; scene choice could depend on match-calculation results. | First-person design-history interview. Direct page retrieval returned HTTP 403 in this review; the indexed interview text was readable. It does not provide opcode definitions or the actual opening script. |
| [Japanese game-music catalog: CT2](https://w.atwiki.jp/gamemusicbest100/pages/2453.html) | Community names/usages for SOUND 00–39 and composer credits; identifies 00 as opening, 01 as title, 30 as Flamengo theme. | Secondary soundtrack catalog, not a data dump. Track labels are not ROM-decoded titles. |
| [Japanese opening-music entry](https://w.atwiki.jp/gamemusicbest100/pages/6979.html) | Identifies SOUND 00 as the opening demo theme, tentatively titled; says the music ends as the title appears. | Community listening/metadata note; confirms intended pairing, not exact frame/sample timing. |
| [VGM Registry opening-music commentary](https://thytimes.hatenablog.com/entry/2022/02/05/122718) | Calls the track SOUND 00 and describes the opening animation; offers listening estimates around the opening phrase at 16 seconds and a semitone-raised reprise around 39 seconds, with the title appearing near the ending. | Japanese editorial/listening commentary. These are approximate audio/video observations, not ROM event times or sample-accurate cues. |
| [Nicozon full BGM collection](https://www.nicozon.net/watch/sm14266393) | Describes a user-uploaded collection of the game's BGM and jingles ordered by the Famicom sound-test sequence. | Secondary listening reference; it is not a source extraction, verified ROM revision, or runtime asset. |
| [5ch binary-hacking thread](https://medaka.5ch.io/test/read.cgi/gameurawaza/1392479553/) | Community discussion and links to the binary wiki/tutorial material; later posts show ongoing hacking and animation/event-condition work. | Forum leads and modification discussion, not a complete disassembly or opening trace. |
| [Newer 5ch part 3, posts 414–416](https://medaka.5ch.io/test/read.cgi/gameurawaza/1745002085/414-416) | Lists F5/F6 horizontal mirroring, F7 background-color selection, and F9 delay/sound-effect arguments; post 416 corrects post 414's F9 order. | Community presentation-command notes with unidentified ROM revision/data stream; not byte-checked against the supplied Turkish ROM. |

## Address memo: opening-relevant entries

The accessible Japanese memo mirror lists:

- `0x6010–`: OP demo.
- `0x62B1–`: demo after Start.
- `0x6636–0xA00F`: first-match Carlos/event material.
- `0xD010–0xD2FF`: colors applied to backgrounds.
- `0xD310–0xD790`: colors applied to characters.
- `0xD810–`: question-marked note that OP-demo colors change.
- `0xDF10–`: question-marked graphics-related area.
- `0xE010–`: question-marked OP-demo management area.
- `0x10010–0x119B2`: question-marked OP background area.
- `0x12010–`: question-marked event graphics.
- `0x16010–0x1FFF0`: question-marked graphics-related area.

The same memo is game-wide, not an opening disassembly. Its remaining entries
cover event-management IDs and match/halftime/end triggers; team, roster,
tournament, and match-title text; ending, meeting, game-over, and hidden
messages; player portraits, match sprites, team/player color records, and
special-move graphics; dribble, pass, ground-shot, high-ball/low-ball shot,
and shot/pass trajectory dispatches; move names/records and technique-cost
notes; player and opponent goalkeeper/field-player status records; and enemy
team tables. These are all catalogued here by subject, while exact
opening-relevant offsets are listed above. We do not reproduce the memo's
hundreds of game-wide address rows verbatim; the original linked memo remains
the source for those raw labels. Do not remove the question marks when citing
its uncertain graphic classifications.

### Complete subject inventory of the Japanese address memo

The [full Japanese address memo](https://daymoe.com/rom/code/%E3%82%AD%E3%83%A3%E3%83%97%E3%83%86%E3%83%B3%E7%BF%BC2%E3%82%A2%E3%83%89%E3%83%AC%E3%82%B9%E3%83%A1%E3%83%A2.html)
contains the following kinds of leads across the whole game. All remain
third-party labels until matched to the target ROM and a live code/data use:

| Memo subject | Examples of what it labels | Relevance to this milestone |
| --- | --- | --- |
| Event/scenario management | Opening demo (`0x6010`), post-Start demo (`0x62B1`), first Carlos match (`0x6636`), tournament/match start, halftime, and end event IDs | Opening and title handoff are candidates; later match IDs are out of scope. |
| Text and names | Meeting messages, ending/game-over/hidden messages, team and roster names, tournament/match labels, and character-name indexes | Helps identify script/data families; localized Turkish text still needs direct ROM decoding. |
| Backgrounds, palettes, and portraits | Background and character color ranges, uncertain opening-background/graphics ranges, portraits, score graphics, and VS cut-ins | Directly useful only where an opening offset is independently traced. |
| Match character graphics and colors | Runtime graphics IDs for player characters and per-player/team palette or leg-color records | Primarily match presentation, not cold opening. |
| Action/move dispatch | Dribble-start and success handlers, passes, ground and aerial shots, special-shot launch preparation, and shot/pass trajectory graphics | Future gameplay reverse-engineering leads; not evidence for opening rendering. |
| Player and opponent data | Named player/special-move records, move costs, field-player and goalkeeper status records, enemy teams, and team-data tables | Future gameplay/system leads; labels and values require target-ROM byte checks. |

The memo also contains isolated offsets whose labels are tentative or
incomplete. Those are deliberately not promoted into implementation facts.
For this project the verified local opening table at `0xE010`, script bytes at
`0x6010/0x6030`, and locally traced palette/music paths take precedence over
the Japanese memo's descriptions.

## What the Japanese binary wiki does and does not expose

The wiki home page lists 32 PRO-ROM bank ranges, each shown as a `0x2000`-byte
range after the iNES header. Its separate public page list reports 16 pages,
mostly generic wiki/plugin pages, and does not list the bank-analysis ranges as
content pages. In this review the bank labels therefore provided a layout
index only; no opening bank disassembly, opcode interpretation, or new code
mapping was recovered from that wiki. The supplied ROM and the separate
byte-checked English-translation disassembly remain the sources for executable
analysis.

The 32 ranges shown in the Japanese wiki's menu are:

| PRG bank | PRO-ROM file-offset range shown |
| --- | --- |
| 00 | `0x00010–0x0200F` |
| 01 | `0x02010–0x0400F` |
| 02 | `0x04010–0x0600F` |
| 03 | `0x06010–0x0800F` |
| 04 | `0x08010–0x0A00F` |
| 05 | `0x0A010–0x0C00F` |
| 06 | `0x0C010–0x0E00F` |
| 07 | `0x0E010–0x1000F` |
| 08 | `0x10010–0x1200F` |
| 09 | `0x12010–0x1400F` |
| 0A | `0x14010–0x1600F` |
| 0B | `0x16010–0x1800F` |
| 0C | `0x18010–0x1A00F` |
| 0D | `0x1A010–0x1C00F` |
| 0E | `0x1C010–0x1E00F` |
| 0F | `0x1E010–0x2000F` |
| 10 | `0x20010–0x2200F` |
| 11 | `0x22010–0x2400F` |
| 12 | `0x24010–0x2600F` |
| 13 | `0x26010–0x2800F` |
| 14 | `0x28010–0x2A00F` |
| 15 | `0x2A010–0x2C00F` |
| 16 | `0x2C010–0x2E00F` |
| 17 | `0x2E010–0x3000F` |
| 18 | `0x30010–0x3200F` |
| 19 | `0x32010–0x3400F` |
| 1A | `0x34010–0x3600F` |
| 1B | `0x36010–0x3800F` |
| 1C | `0x38010–0x3A00F` |
| 1D | `0x3A010–0x3C00F` |
| 1E | `0x3C010–0x3E00F` |
| 1F | `0x3E010–0x4000F` |

These boundaries are consistent with the supplied 256 KiB PRG image's
`0x2000`-byte banks and 16-byte iNES header, but the wiki's range table alone
does not identify the contents or prove a specific bank interpretation.

### Local ROM cross-checks

- The supplied ROM's file `0x6010` begins with the opening pointer table; its
  first little-endian pointer is `$A020`. File `0x6030` begins
  `E8 01 F9 00 FB 01 8D…`. The captured cold-start trace executes from `$A020`,
  so the opening-area label is structurally consistent with this ROM.
- File `0x62B1` begins `E8 01 F9 5C FB 01 6D…`, which looks like a valid
  cutscene stream. The Japanese “after Start” label does **not** prove that the
  current cold-start-to-title input path executes it; the live pointer/bank
  trace has not established that handoff.
- File `0xE010` is locally checked against the byte-matching public
  `bank_87.asm` listing, which names a background-parameter table and gives
  scene IDs including opening backgrounds and title ID `0x17`. This supports
  the table interpretation from byte-checked disassembly; it does not validate
  the Japanese memo's tentative wording “OP-demo management.”
- The ROM's `0xD010` region contains palette records used by local opening
  decoders. The full ranges `0xD010–0xD2FF`, `0xD310–0xD790`, `0xD810`,
  `0xDF10`, and `0x10010–0x119B2` have **not** all been independently mapped
  from this memo alone. Use local ROM references and runtime traces before
  assigning those ranges to a Godot resource.

## Sound test and music catalog

The Japanese GCGX page specifies the hidden title-screen sound test as
A+B+Start, with ordinals `00–39` for BGM and `40–99` for sound effects; A plays,
B stops, and Start exits. This is the source behind the project's **40 BGM +
60 SFX** count. The local ROM audit independently confirms all 40 BGM pointer
words and sequence destinations listed in the Turkish music-system post. A
separate byte audit now confirms all 60 SOUND 40–99 effect pointer words,
terminators, and 189 channel-stream destinations; the opening's 13 observed
queue events are listed separately with command-provenance limits. See
[`sound_test_sfx_index_audit_20261025.md`](../audio/sound_test_sfx_index_audit_20261025.md).
The hidden A+B+Start sound-test input has not yet been replayed against this
Turkish ROM, so the Japanese guide's control sequence remains an external lead.

The Japanese soundtrack catalog labels all 40 BGM ordinals. The full list,
including entries that the catalog leaves unnamed, is preserved in
[`../audio/sound_test_index_audit_20261025.md`](../audio/sound_test_index_audit_20261025.md).
These are community scene labels, not names embedded as text in the ROM. The
catalog credits the game's music to Tsugutoshi Yamagishi, Mikio Saito, and
Mayuko Okamura; it attributes SOUND 30 (Flamengo) to Saito and SOUND 00's
opening entry to Yamagishi. The opening entry says SOUND 00 ends as the title
appears. This corroborates the audio cue identity and intended scene boundary;
it does not determine exact PPU/APU timing or PCM samples.

The VGM Registry article and Nicozon compilation add listening context only.
The former describes approximate musical/visual beats; the latter says its
collection follows the sound-test order and includes jingles. Neither supplies
the supplied Turkish ROM's APU writes, sequence pointers, or filter state.

## Cutscene design interview

The Appliv Games interview with developer Michitaka Tsuruta says the CT2
storyboard/cutscene system was rebuilt from the prior game, expanded to include
subroutine calls, and had become similar to a dedicated language. He says
staff-authored data specified sprite motion between screen positions and the
number of frames, written in assembler-like form. He also describes choosing
which scene to play based on match-calculation results.

This supports the project's architecture choice: interpret command/data streams
and preserve frame counts rather than hand-authoring unrelated still images.
The interview does not give an opcode map, the Turkish opening command stream,
the handler implementation, a full frame-to-PC schedule, or exact PPU/OAM/APU
events. Those still require byte-checked local disassembly and live trace.

## Optional opening hidden event

GCGX reports that some story-text scenes show a soccer-ball cursor at lower
right; when it blinks rapidly, Down+B reveals a hidden event. Its opening entry
is described as a scene about Tsubasa arriving in Brazil three years earlier.
This is a useful clue for later opening-story input coverage, but it has not
been mapped to a specific command/frame in the supplied ROM and is outside the
current cold-start-to-title endpoint unless the local trace proves otherwise.

## General controls relevant to this slice

The GCGX controls page says A confirms, B cancels or speeds text, and Select
skips event scenes; Start is left blank in its general button table. The hidden
sound-test page assigns Start specifically to leaving that mode. Keep these
contexts separate: general in-game controls do not define the opening's exact
skip behavior or title-menu transition. Local frame/input traces are needed to
decide those behaviors in the supplied Turkish revision.

## Implementation use

1. Use the Japanese sources to find labels, track identities, and candidate
   offsets.
2. Verify each offset against the supplied ROM hash and active bank mapping.
3. Trace the actual executed pointer/handler and PPU/APU side effects before
   turning a memo label into runtime behavior.
4. Keep the sound-test track names and guide descriptions as research metadata;
   runtime audio must still be generated from the ROM's sequence/driver data.

The broader source comparison and non-Japanese leads remain in
[`online_reverse_engineering_resources.md`](online_reverse_engineering_resources.md).

## Japanese guide and transcript coverage added on 2026-10-25

The San Paulo FC site exposes more than the top-level story summary. Its
scenario index groups the game into seven story arcs plus a cast/staff page.
The Rio Cup transcript starts with an explicitly labelled opening movie: it
describes Tsubasa's dribble, then introduces Hyuga's Tiger Tackle, Misaki's
Twin Shot, and Wakabayashi's one-handed catch before the narration turns to
the final against Brazil. It then continues into the prologue, Roberto's
Brazil/São Paulo setup, the Rio Cup briefing, match scenes, and later story
events. This is a narrative/scene-order aid; compare each event to the Turkish
ROM before treating its Japanese text or ordering as target-ROM evidence.

The same site reproduces a 16-part manual covering story/start/continue,
meeting, team data, the screen, attack/defense, team changes, set pieces, PK,
teams/characters, Guts costs, and play tips. Its first page says KICK OFF
starts the game and CONTINUE enters score-memo input. The manual documents
intended behavior, but does not establish the Turkish ROM's frame-by-frame
title presentation or cursor state.

Its linked progression chart covers match order, match durations, extra time,
PK availability, and loss routing; the player-data tree covers teams and
level-specific stats; separate pages list experience inheritance and
thresholds. The site notes that some stat ordering was converted to a later
series format, so do not copy these numbers directly into the Turkish remake.
It also has four separate mechanics analyses: Guts consumption, the effect of
the through action/pass, conversion from stored data values to displayed
ability values, and special-move strength. These are leads for future gameplay
reverse-engineering, not opening-scene implementation facts.
Its cheat page independently documents the title sound-select combination,
the fast-blinking ball cursor plus Down+B hidden-event trigger (including an
opening event), and Select-based story skipping. That page names *Ura-waza
Daijirin '95* and a February 1995 *Family Computer Magazine* supplement as
sources. The inputs remain external observations until replayed on the supplied
Turkish ROM.

The retrospective Tecmo Theater overview describes CT2 as entry four in the
series and notes its expanded presentation/cut-ins. Japanese game catalogs
add release/platform/password metadata and broad gameplay-system summaries.
These are context, not technical maps.
The previously catalogued GCGX pages provide overlapping controls, sound-test,
story, and hidden-event information; the music wiki, VGM commentary, and
Nicozon upload provide track labels or listening impressions only. These
overlaps are recorded to show corroboration, not counted as independent ROM
verification.

### Scope of “all Japanese sources” in this inventory

This is an inventory of Japanese-language sources found by searches of the
game title, binary hacking, Tecmo Theater, opening/demo, sound-test, and
scenario-analysis terms, together with pages linked from those source indexes.
It records their claims, source type, opening relevance, and ROM-check status;
it is not a mirror of every webpage or a verbatim reproduction of the address
memo or scenario text. Search results can be incomplete, removed, or revised.
No Japanese source found in this pass provides a complete byte-checked
disassembly, frame-by-frame PPU/OAM map, or sample-accurate APU trace for this
Turkish ROM. Treat every community address and command description as a lead
until the local byte/bank/trace check is documented.

## Broader Japanese gameplay lead outside this opening slice

The GameCenter GX analysis blog says experience gained in a match is carried
across later team changes, and that its author revised an earlier conclusion
after finding an internal experience transfer. This may help a future story or
match-system milestone; it has no bearing on the cold-start intro/title path.
Verify the claim against the target ROM and observed game state before using it
as a rule.

## Newer community presentation-command notes

Posts 414–416 in the newer Japanese [5ch binary-hacking thread](https://medaka.5ch.io/test/read.cgi/gameurawaza/1745002085/414-416)
report a limited command list: `F5` clears horizontal mirroring, `F6` enables
it, `F7 xx` selects a background color, and `F9 xx yy` waits for delay byte
`xx` before playing sound effect `yy`. Post 416 corrects post 414's reversed
description of the two `F9` arguments. The thread does not identify the source ROM revision
or explain whether these commands belong to the opening storyboard stream, a
special-move presentation stream, or another related data path. Treat them as
community-derived leads only: none has been byte-checked or live-traced against
the supplied Turkish ROM, and they do not constitute a complete interpreter
or opening command map.

The supplied Turkish ROM's opening trace shows why this context warning
matters: its cutscene stream uses one-operand `F9 xx` records for background
selection. The locally traced `$87B8` `F5` handler is operand/background
dependent: observed `F5 00` and `F5 01` select ROM-backed palette-effect
streams, while `F5 10` selects the BG08 raster model. Those opening-stream
meanings differ from the forum's two-operand `F9` sound form and generic `F5`
mirroring description. The forum may describe a separate presentation/animation
stream or a different revision; do not apply its commands to the opening
interpreter without resolving that format boundary.

The Japanese-language searches for this audit found the command note above but
no CT2-specific PPU/CHR bank-to-screen map or full executable disassembly.
General NES mapper explanations and non-Japanese board catalogs can help with
hardware context, but they do not map this game's opening data and are not
evidence for the Turkish ROM.

# Online research leads for the first match slice

## Target ROM

All implementation facts must be checked against the supplied Turkish ROM,
SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Community labels and descriptions below are navigation/control leads, not proof
that another revision has the same bytes or opening route.

## Sources and what they establish

| Source | Type | Useful lead | Limits |
|---|---|---|---|
| [CT2 English translation/disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64) | Annotated 6502 disassembly and translation project (comments are mostly Russian; translation is incomplete) | The pinned [`bank_98.asm`](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_98.asm) labels the in-match window renderer at `$8852` and its row-packet worker at `$88B9`; locally, 154 annotated instructions / 302 encoded bytes in `$8852–$89A2` match the supplied Turkish ROM exactly. | A source listing is not a live route trace. The file omits machine-byte annotations across part of `$885E–$887B`; use the target-ROM hashes and the local renderer audit for implementation facts. It does not provide the production caller state, scheduler timing, PPU/OAM trace, or Godot-ready renderer. |
| [Japanese CT2 guide and manual summary](https://gcgx.games/captain-tsubasa2/info.html) | User manual/control guide | Describes the command-driven match controls: A confirms, B opens the command prompt, and directional choices vary by attack/defense state. | It explains user-visible controls but does not identify this ROM's routines, exact text, frame timing, or first-match state. |
| [Japanese CT2 reference/manual mirror](https://setsumei.cloudfree.jp/famicom/captaintsubasa2/captaintsubasa2.html) | Manual transcription/reference | Describes KICK OFF versus CONTINUE and the pre-match meeting/team-data flow. | Manual-level description; not a live execution trace. |
| [Japanese CT2 player/team data tables](https://tsubasa.yamagomori.com/ct2/data/ct2-data.html) | Community roster, uniform-number, skill, and level tables | Useful as a secondary checklist for team membership and displayed player values; includes the opening São Paulo roster and level-by-level Tsubasa data. | The author explicitly says values are reordered to CT4 specifications. It does not publish CT2 ROM player IDs, record pointers, raw table layout, match IDs, scene IDs, or executable code. Validate any value against the supplied ROM before use. |
| [Turkish CT2 player-name offsets and name codes](https://tsubasatr.net/konu-ct-2-oyuncularin-isimlerini-degistirme.html) | ROM-editing forum post with player-name file offsets and text codes | Tsubasa is listed at `0x3F519` with text bytes `01 02 03 FC`; those bytes match the supplied Turkish ROM at that offset. | This verifies a name-table entry, not the active-player RAM record, full player-state schema, or every listed offset. The `01 02 03` values are text codes in that name string, not by themselves the in-match player ID. |
| [Turkish CT2 cheat-code/player-ID list](https://tsubasatr.net/konu-ct-2-cheat-kod-yazimi-183.html) | Community cheat guide listing player IDs and home/away player-record RAM addresses | The São Paulo IDs begin `02` Renato, `03` Platon, …, `01` Tsubasa, `0B` Batista. The supplied ROM's match-00 home roster is `02 03 04 05 06 07 08 09 0A 01 0B 00`; its first 11 player-record pointers are `$0300,$030C,…,$0378`, matching the guide's home-team RAM slots. | This is a RAM-cheat/address map, not a ROM offset map or full player-record schema. The roster and pointer-table match corroborates this first-team mapping for the target image; it does not decode every team's records, player behavior, or route logic. |
| [Turkish CT2 shot-scene offsets](https://tsubasatr.net/konu-ayni-suta-sahip-oyuncularin-ofset-yerlerini-belirleyen-kodlar.html) | Community ROM-hacking post about special-shot/skill scene pointers | Gives one Drive-shot path around `0x21D0C` and a scene-data excerpt at `0x22B50`; both the pointer-area bytes and the posted `$22B50` bytes match the supplied ROM. | The post describes skill cutscenes, not the opening or first command menu. The sample byte match does not validate the complete bank-switch/caller path or all skill records. |
| [Turkish CT2 special-move code tables](https://tsubasatr.net/konu-ct-2-tum-sutlarin-ve-diger-ozel-hareketlerin-kodlari-asil-icerik.html) | Community ROM-hacking post describing player-specific move lists and companion-player markers | It lists Tsubasa's move bytes at `0x3935D` as `0C 3A 12 25 11 48 4A 49 44 1A 03` and Misaki's at `0x39368` as `25 01 3A 41 03`. Both sequences match the supplied ROM byte-for-byte, including the listed player IDs and `$03` terminators. | This is a useful move-list index for later action/scene work, not a complete scene interpreter. The post itself leaves at least one move code unexplained; the byte match does not verify all move labels, callers, bank transitions, or animation timing. It is outside the current first-command-menu endpoint. |
| [Turkish CT2 player-behavior code archive](https://tsubasatr.net/konu-oyuncu-davranis-kodlari-hepsi-bir-arada.html) | Forum post links an archive describing player/keeper AI and movement behavior categories | Potentially useful for later field movement, marking, passing, and keeper behavior; the post names eleven player-behavior groups plus keeper and Musashi second-half behavior. | The linked `aid=2136` archive could not be retrieved in this pass (web fetch cache miss; direct request returned HTTP 403), so it remains uninspected and unverified. Do not import its tables as runtime data or claim its offsets match this ROM. |
| [Turkish CT2 match-selection cheat list](https://tsubasatr.net/konu-mac-kodlari.html?pid=121078) and [half/period cheat list](https://tsubasatr.net/konu-captain-tsubasa-2-yeni-oyun-hileleri.html) | Community VirtuaNES address/value cheats for RAM `$0026` and `$0027` | Useful navigation leads for selecting later team/match or period states while researching. Local source analysis independently treats fresh match `$0026=0` and period `$0027=0` as the first-match state. | These are emulator RAM writes, not ROM offsets or scene IDs. The forum list starts at value 1 / second listed team; it does not by itself establish the first-match route or every revision's mapping. Keep it out of runtime logic. |
| [Turkish CT2 hacking-topic index](https://tsubasatr.net/konu-bugune-kadar-paylasilan-tum-ct2-paylasimlarina-buradan-ulasin.html) | Curated index linking player rosters, per-match lineups, special moves, shot/animation scenes, player behavior, match flow, and editing tools | Good discovery map for targeted follow-up research; it points to many narrowly scoped community write-ups. | It is an index, not one verified game-code document. Each linked post may describe a hack or emulator cheat and needs individual target-ROM byte and bank checks. |
| [Chinese CT2 discussion/guide](https://forum.nanoha.com.cn/thread-2430-1-1.html) | Community walkthrough/control table | Lists command names and directional meanings for common possession and goalkeeper situations. | Applies to described game situations, not proof of which situation appears first in the Turkish ROM. Simplified Chinese labels should not be imported as in-game Turkish text. |
| [Chinese Hack CT2 tools/reference](https://daymoe.com/rom/Hack%20CT2.html) | ROM editor and data-index utility | Can provide candidate addresses for player, team, and command data. | It is not an executable disassembly or live trace; addresses may target a different patch/revision. Verify locally. |
| [Turkish CT2 music-system notes](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html) | Community music-format and pointer index | Lists BGM/SFX sequence pointers and describes instrument records (`$E0` commands), which can shorten audio-driver table discovery. | Author notes are not an execution trace and may include assumptions; verify each pointer and format against the supplied ROM and the game's driver. |
| [Chinese CT2 code/reference page](https://daymoe.com/rom/code.html) | Cheat/secret-input index | Claims the title sound-test entry is A+B held with Start. This may help reach all sound IDs for observation. | The page is not an input trace and may target a Japanese ROM/hack; no sound-test entry behavior is assumed until verified locally. |
| [Japanese CT2 address memo](https://daymoe.com/rom/code/%E3%82%AD%E3%83%A3%E3%83%97%E3%83%86%E3%83%B3%E7%BF%BC2%E3%82%A2%E3%83%89%E3%83%AC%E3%82%B9%E3%83%A1%E3%83%A2.html) | Community ROM data/address catalog | Labels event, team, player, and cutscene data regions, including early-game events. | Data index rather than executable disassembly; labels and offsets may be from another revision, so do not directly import them. |
| [Turkish Captain Tsubasa community forum](https://tsubasatr.net/) | Community articles and ROM-hacking notes | The forum indexes game-specific work on animation IDs, player codes, music, and title assets. | Treat posts as leads. Confirm language/revision and check source bytes before adopting an interpretation. |

## Byte-checked route lead

The independent static route audit in
[`fresh_start_to_first_command_menu.md`](fresh_start_to_first_command_menu.md)
records the supplied ROM's KICK OFF branch, new-game state, and first-match
selection bytes. That local audit takes precedence over the generic guides above.
The live FCEUX capture is separately documented and used only to validate
behavior and map ROM graphics/state; captures are not packaged as runtime art or
audio.

## Byte-checked São Paulo player IDs and record slots

The Turkish [cheat-code/player-ID post](https://tsubasatr.net/konu-ct-2-cheat-kod-yazimi-183.html)
lists these São Paulo IDs and RAM cheat addresses. The supplied ROM's match-00
home roster bytes at file `0x004A57` are
`02 03 04 05 06 07 08 09 0A 01 0B 00`, which places the IDs in the same order.
All 22 little-endian entries in the ROM-derived player-pointer table match the
forum's `+$0C` address progression from `$0300` through `$03FC`.

| Match roster slot | Forum player ID | Forum label | ROM-derived RAM record base |
| ---: | ---: | --- | ---: |
| 0 | `$02` | GK Renato | `$0300` |
| 1 | `$03` | Platon | `$030C` |
| 2 | `$04` | Lima | `$0318` |
| 3 | `$05` | Amaral | `$0324` |
| 4 | `$06` | Dotoru | `$0330` |
| 5 | `$07` | Tahamata | `$033C` |
| 6 | `$08` | Marini | `$0348` |
| 7 | `$09` | Babington | `$0354` |
| 8 | `$0A` | Gil | `$0360` |
| 9 | `$01` | Tsubasa Ohzora | `$036C` |
| 10 | `$0B` | Batista | `$0378` |

The local roster and pointer bytes confirm the ordered IDs and record bases for
this target ROM. The community post supplies the human-readable labels; treat
those labels as corroborated leads, since the local match-player name resolver
and every player's name table have not all been audited independently. The
opponent record half of the same pointer table runs from `$0384` to `$03FC`;
those are slots, not match or scene IDs. These mappings are research data and
are not copied as fixed runtime constants.

## First-match pitch renderer lead: bank-$0B animation

The pinned public [CT2 disassembly bank-$0B listing](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_8B.asm)
provides routine labels and bank-map navigation. The selected `$70` record is
ROM-checked at file `0x016B48`; its opcode `$06` dispatches to `$83D2`, then
flows through `$8386` to `$8393/$8395` and `$84A1(A=$A0)`. The supplied Turkish
ROM bytes at file `0x0163A3` (`A9 A0 20 A1 84`) and file `0x0164B1` were checked
locally. That path selects page 2 and scroll `$74`, which matches the sampled
endpoint shadows and fixed-bank NMI writes. The `$8B64` table also begins at
`0x016B74`; its first 64 bytes match the pinned listing. The external listing
is a navigation/annotation source; local ROM bytes remain canonical.

This does not establish the complete endpoint raster or field composition.
The background-only render using the ROM-derived initial viewport is 51.97%
RGB-exact against the FCEUX screenshot; a `$2006=$2240` event at scanline 134
raises the diagnostic score to 83.81%, but that split is screenshot-guided and
not source-verified, so it is not used at runtime. The `$70/$56` row/attribute
residual and further palette/CHR and actor composition remain open. See
`first_command_field_background_producers_20261027.md` and
`first_command_field_residual_map_scan_20261027.md`.

## Music pointer lead from the Turkish community index

The community post [“CT2 müzik sistemi nasıl çalışır?”](https://tsubasatr.net/konu-ct2-muzik-sistemi-nasil-calisir.html)
catalogues 100 sound-test IDs, sequence pointers, and the instrument-record
table. It labels Sound 03's pointer at file offset `0x18C92` and target data at
`0x1E31F`; the same article describes `$E0 xx` as an instrument selector and
maps values `$00–$3E`. Treat these as data-index claims, not as a decoded sound
driver or proof of PCM behavior.

The supplied Turkish ROM SHA-256 above was checked locally: bytes at
`0x18C92` are `0F A3`, which resolve through bank `$0F` to file offset
`0x1E31F`; bytes there begin `04 1C A3 05 E9 A4 06 4F`. This agrees with the
project's queue `$55` mapping to the Sound 03 sequence. The ROM-derived route
audio audit independently builds the queue pointer and sequence, while its
ROM-only/WaveHi audio still does not match FCEUX PCM sample-for-sample. The
post's sound-test input and instrument descriptions remain useful leads, but
were not used as runtime data. See
[`first_match_audio_integration_audit_20261027.md`](first_match_audio_integration_audit_20261027.md).

The [Chinese code/reference page](https://daymoe.com/rom/code.html) says the
title sound test can be entered by holding A+B and pressing Start. That exact
input has not been traced on the supplied Turkish ROM, so this project does
not rely on it for its current captured route or audio assets.

## First command-menu renderer lead: bank-$18 code listing

The pinned external [`bank_98.asm`](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_98.asm)
maps its `$030010–$03400F` bank range to the target's bank-$18 CPU window. Its
comments label `$8852` as the match-window renderer and `$88B9` as the window
row/packet worker. A byte comparison of every machine-code annotation in
`$8852–$89A2` against the supplied ROM at `0x030862 + (CPU address - $8852)`
found all 154 annotated instructions (302 bytes) identical. The listing skips
encoded-byte annotations around `$885E–$887B`, so this is a matching partial
listing, not proof that the full renderer is disassembled without gaps. The
project's independent hash-checked target-ROM audit remains the implementation
source for descriptor parsing, dynamic `$E0/$E1` values, and row-packet
generation: [`menu_renderer_algorithm_audit.md`](menus/first_action_menu/menu_renderer_algorithm_audit.md).
The external source adds routine labels; it does not provide the live caller
state, task continuation, packet-consumer timing, or first-pixel trace needed
to integrate the first menu into the route.

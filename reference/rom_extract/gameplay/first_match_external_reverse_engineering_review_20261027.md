# First-match route: external reverse-engineering source review — 2026-10-27

## Question and ROM identity

This follow-up checked whether Japanese, Chinese, Turkish, or public GitHub
material already decodes the fresh KICK OFF route to the first match command
menu. The supplied Turkish ROM is
`Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
File offsets below include its 16-byte iNES header. External labels are leads;
the target-ROM bytes and the local muted trace remain authoritative.

## Findings

| Source | Classification and useful lead | Target-ROM check and limit |
| --- | --- | --- |
| [Sanpauro FC progression chart](https://tsubasa.yamagomori.com/ct2/memo/chart2.html) | Japanese gameplay/story-flow guide. It lists the first Rio Cup match as Fluminense against São Paulo and describes match rules and the loss route. | The local fresh-start trace enters the match-00 Fluminense setup and then the kickoff scenarios. This confirms the story label; it does not identify code addresses, event timing, actors, or PPU output. See [`fresh_start_to_first_command_menu.md`](fresh_start_to_first_command_menu.md). |
| [Japanese address memo mirror](https://daymoe.com/rom/code/%E3%82%AD%E3%83%A3%E3%83%97%E3%83%86%E3%83%B3%E7%BF%BC2%E3%82%A2%E3%83%89%E3%83%AC%E3%82%B9%E3%83%A1%E3%83%A2.html) | Static offset/script index. It labels file offset `0x6636` as a first-Carlos-match script. | The supplied ROM bytes at `0x6636` begin `E8 01 F9 02 FB 01 15 DE E9 ED 53 F2 02 F4 05 46`. The active fresh-start route instead resolves bank-$10 scenario pointers at `0x020A39/0x020A3B` to streams at `0x0237DD/0x0237F4`, beginning `F9 EB 44 02 3A 8F 73 FB...` and `F5 F9 02 7F 10 3A 8F F0...`. Do not substitute the memo's `0x6636` label for the locally traced `$35/$36` kickoff scenarios; the external label alone does not establish that they are the same scene or route. |
| [Chinese animation-ID index](https://github.com/Novsochetra/Ct2-Editor-Advance/blob/master/Code_data/%E5%89%A7%E6%83%85%E5%8A%A8%E7%94%BB%E4%BB%A3%E7%A0%81.txt) in [Ct2-Editor-Advance](https://github.com/Novsochetra/Ct2-Editor-Advance) | The repository calls itself a cheat/editor tool. The text file is an animation/data catalog; it labels `$5C` as Pierre facing left, `$6E` as Tsubasa carrying the ball, and `$8D` as the opening rabbit. It is not a 6502 disassembly or timing trace. | The opening stream contains `FB 01 8D` at file `0x6034` and `FB 01 6E` at `0x6043`, which supports those two labels for this ROM. Fresh-route scenario `$44` dispatches a bank-$14 `$5C` actor-packet stream at CPU `$9357` / file `0x029367`; the locally preserved 26-byte stream contains three `$F1` actor constructors. The index's `$5C` label does not explain those constructors, their route-state writers, or their frame timing. See [`first_command_actor_state_producer_20261027.md`](first_command_actor_state_producer_20261027.md). |
| [Daymoe Chinese code/data page](https://daymoe.com/rom/code.html) and [Hack CT2 feature page](https://daymoe.com/rom/Hack%20CT2.html) | Address/tile-code index and ROM editor feature description. The code page lists `$BE98` for the São Paulo pre-match meeting; the tool page advertises CHR, music, data editing, and emulator memory inspection. | These are not executable listings. `$BE98` is not the active opening stream pointer: local route evidence follows title setup and scenario IDs `$35/$36` in the bank-$10 table. The page does not state enough bank context to map the meeting label safely to a file offset. No editor executable or archive was used as authoritative evidence. |
| [Captain-Tsubasa-2-English-Translation pinned disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64) | Annotated 6502 disassembly and translation project; strongest external code source found. | Earlier audits establish matching code ranges in banks `$80`, `$81`, `$87`, `$8B`, `$98`, and `$FF`, but the audit also records differences in other banks. In the first-action renderer window, 154 annotated instructions / 302 bytes at `$8852–$89A2` match the target ROM; the external source leaves machine-byte annotations absent across `$885E–$887B`. Apply labels only after checking the specific bank and mapping in this Turkish ROM. The repository does not supply a live first-match PPU/OAM/APU trace or a Godot-ready renderer. See [`../intro/online_reverse_engineering_resources.md`](../intro/online_reverse_engineering_resources.md) and [`online_sources.md`](online_sources.md). |

## What this adds to the implementation

The external work corroborates the first opponent/story label and offers
useful animation names. It does not remove the main local reverse-engineering
gaps: actor-record writer PCs for the route history, generic live receiver RNG
state, the full field nametable/raster/scroll producer, or source-timed route
audio. Keep the current `$35/$36` pointers and same-input traces as the route
evidence. Do not turn the editor's animation labels, the Japanese address
memo's offsets, or captured PPU/RAM states into runtime logic. Current local
findings are tracked in
[`fresh_start_to_first_command_menu.md`](fresh_start_to_first_command_menu.md),
[`first_command_player_state_source_20261027.md`](first_command_player_state_source_20261027.md),
[`first_command_actor_state_producer_20261027.md`](first_command_actor_state_producer_20261027.md),
and [`first_command_field_background_producers_20261027.md`](first_command_field_background_producers_20261027.md).

## Focused follow-up: bank-$0B placement handler (2026-10-28)

The pinned public disassembly's [`bank_8B.asm` handler listing](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_8B.asm)
labels the shared `$05CD → $05CE/$05CD` transition at `$8339–$834B`. The
corresponding 19 bytes were checked against the supplied Turkish ROM at file
offset `0x16349`; all 19 match (`AD CD 05 F0 04 29 20 09 80 8D CE 05 09 80
49 20 8D CD 05`). The locally preserved excerpt is
`reference/rom_extract/gameplay/first_command_field/packet_producer/bank_0b_8327_8360_map_placement_writer.bin`.
This confirms the public listing as a useful routine-label lead for this
handler. It does not supply the live incoming shared `$05CD` value or the
cooperative `$8525`/task continuation timing.

The Japanese [CT2 binary wiki](https://w.atwiki.jp/cap2bin/) remains an index
of PRO-ROM bank ranges rather than a usable decoded listing: its currently
visible page index lists only 16 generic pages and does not expose those bank
analyses. No code or runtime evidence was adopted from that page in this
follow-up. The local two-pass FCEUX trace and target-ROM source bytes remain
necessary for the route-specific callback state.

## Focused follow-up: player, match, and scene data leads (2026-10-28)

This pass searched Japanese, Chinese, and Turkish sources for player
identifiers, team and match records, and scene/event codes. It found useful
human-readable tables and several partially byte-matching Turkish hacking
references, but no external source that identifies all of those fields in
this Turkish ROM's byte layout.

| Category | External source and what it provides | What it does not establish for this ROM |
| --- | --- | --- |
| Player/team display data | [さんぱうろFC CT2 player-data index](https://tsubasa.yamagomori.com/ct2/data/ct2-data.html) links team rosters and level tables; its [São Paulo roster](https://tsubasa.yamagomori.com/ct2/data/team1/sfc.html) shows shirt numbers and displayed skill values, and its [Tsubasa level table](https://tsubasa.yamagomori.com/ct2/data/lv1/tuba.html) lists values by level. | The site's own note says the numbers are reordered to CT4 specifications. The pages do not identify CT2 internal player IDs, pointer tables, source offsets, or the Turkish text/name encoding. Use them as a secondary checklist only after mapping each ROM record locally. No new player ID was inferred from the website. |
| Player IDs and record slots | The Turkish forum's [“Ct-2 Cheat Kod yazımı”](https://tsubasatr.net/konu-ct-2-cheat-kod-yazimi-183.html) lists São Paulo player IDs and home/away RAM record starts. | This is a cheat-address guide, but it has a particularly useful local match: the supplied ROM's match-00 home roster at file `0x004A57` is `02 03 04 05 06 07 08 09 0A 01 0B 00`, matching the listed IDs in lineup order, and the first 11 bytes in the ROM-derived player-pointer table decode to `$0300,$030C,…,$0378`, matching the forum's home-record starts. This corroborates the São Paulo player-ID/slot mapping for this target ROM; it does not establish all teams' record layouts or player behavior. |
| Match/team data | The Japanese index groups teams by story competition and gives roster tables; the Chinese [Hack CT2 feature log](https://daymoe.com/rom/Hack%20CT2.html) documents editor features for player ability/team editing; the Turkish [CT2 hacking-topic index](https://tsubasatr.net/konu-bugune-kadar-paylasilan-tum-ct2-paylasimlarina-buradan-ulasin.html) points to lineup, per-match team, player behavior, and scene-editing posts. | These sources show which content categories the community edits, but do not publish a byte-verified match-record schema for this Turkish image. The editor notes configurable addresses and support for patched ROM layouts; forum cheats and hack-specific posts must not be copied as fixed offsets. |
| Turkish player-name code/offset | The Tsubasa Türkiye post [“CT 2 Oyuncuların İsimlerini Değiştirme”](https://tsubasatr.net/konu-ct-2-oyuncularin-isimlerini-degistirme.html) lists Tsubasa's name at file offset `0x3F519` as bytes `01 02 03 FC`, followed by many other name offsets. | The supplied ROM is exactly `01 02 03 FC` at `0x3F519`. This validates that one name-table offset and string for this image. It does not mean `01 02 03` is the active in-match player ID; the thread explains these as text codes. Other offsets and player-record IDs still need individual checks. |
| Turkish skill-scene bytecode | The forum post [“Aynı Şuta Sahip Oyuncuların Ofset Yerlerini Belirleyen Kodlar”](https://tsubasatr.net/konu-ayni-suta-sahip-oyuncularin-ofset-yerlerini-belirleyen-kodlar.html) describes special-shot scene locations around `0x22000–0x24000` and gives a Drive-shot table/pointer example at `0x21D0C` and a byte excerpt beginning `0x22B50`. | The target ROM at `0x21D0C` begins `4C AB 31 AB CC AB 31 AB F0 AB 31 AB 31 AB 31 AB`; bytes at `0x22B50–0x22B8B` match the posted excerpt. This is a useful, locally corroborated skill-scene lead, but the complete active-bank/caller path and all per-player boundaries have not been traced. It concerns a later special-shot scene, not the first command menu. |
| Per-player special-move lists | The Turkish [special-move code table](https://tsubasatr.net/konu-ct-2-tum-sutlarin-ve-diger-ozel-hareketlerin-kodlari-asil-icerik.html) explains player move-list offsets, move codes, partner-player markers, and `$03` list terminators. | Its Tsubasa list at file `0x3935D` (`0C 3A 12 25 11 48 4A 49 44 1A 03`) and Misaki list at `0x39368` (`25 01 3A 41 03`) match the supplied ROM exactly. This validates the sample list bytes and makes the page useful for future move-data research. It does not decode scene dispatch or timing, and at least one listed move code is left unexplained by the post. |
| Turkish match/period navigation | The [“Maç kodları” thread](https://tsubasatr.net/konu-mac-kodlari.html?pid=121078) and [new-game cheat thread](https://tsubasatr.net/konu-captain-tsubasa-2-yeni-oyun-hileleri.html) list VirtuaNES address/value writes for RAM `$0026` and `$0027`, described as team/match and half/period selectors. | These are emulator RAM cheats, not ROM file offsets or scene IDs. The local source model already derives fresh match `$0026=0` and first period `$0027=0`; the forum's team list begins at value 1 / its second listed team. Treat other values as route-navigation candidates until their ROM behavior and Turkish revision mapping are traced. |
| Turkish player-behavior tables | [“Oyuncu Davranış Kodları (Hepsi Bir arada)”](https://tsubasatr.net/konu-oyuncu-davranis-kodlari-hepsi-bir-arada.html) describes a downloadable archive covering player behavior groups, keeper behavior, and a Musashi second-half variant. | Potentially useful for future movement/AI. The linked `aid=2136` attachment could not be retrieved in this pass (web fetch cache miss; direct request returned HTTP 403), so its tables and offsets remain uninspected and unverified against the supplied ROM. It was not used by the current route. |
| Scene/event labels | The Chinese [CT2 address index](https://daymoe.com/rom/code.html) labels `$BE98` as a São Paulo pre-match meeting; the Chinese editor's [animation-ID catalog](https://github.com/Novsochetra/Ct2-Editor-Advance/blob/master/Code_data/%E5%89%A7%E6%83%85%E5%8A%A8%E7%94%BB%E4%BB%A3%E7%A0%81.txt) names some actor animations. | `$BE98` is an address label, not a verified scene ID or complete event stream. The animation catalog does not explain scene dispatch, actor construction, or timing. For the fresh route, bank-$10 scenario IDs `$35/$36/$44` and their pointers are derived from this ROM's own bytes and traces; these external sources did not independently decode that route. |
| Executable code | The [Japanese CT2 binary wiki](https://w.atwiki.jp/cap2bin/) exposes PRO-ROM bank-range navigation, while the pinned public assembly project described above provides partial annotated 6502 code. | The wiki's currently visible index does not expose the promised per-bank analyses. The assembly project remains partial and revision-sensitive. Neither source supplies the live fresh-route task, callback, PPU/OAM, and APU sequence needed to reach the first command menu. |

The search found partial external player-ID/record-slot, special-move-list,
player-name, team/match-selection, and special-shot-scene references, including
multiple byte-for-byte matches in the supplied image. The player-ID and first
11 home-record pointers agree with the ROM-derived match-00 lineup. It did not
find a complete schema that maps every player ID, match record, scene/event
code, and route/cutscene execution path for this Turkish ROM. The local project
already extracts the match-00 home roster and player-record pointer/profile
tables from the supplied ROM; that byte mapping remains authoritative for
runtime state. Japanese tables can cross-check displayed values, and Turkish
forum offsets can guide further traces, but none is copied into runtime. See
[`first_command_player_state_source_20261027.md`](first_command_player_state_source_20261027.md),
[`fresh_start_to_first_command_menu.md`](fresh_start_to_first_command_menu.md),
and [`first_command_scenario_stack_continuation_source_20261028.md`](first_command_scenario_stack_continuation_source_20261028.md)
for the local byte- and trace-derived route model.

## Focused follow-up: bank-$18 action-menu renderer listing (2026-10-28)

The pinned [public `bank_98.asm` listing](https://raw.githubusercontent.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_98.asm)
uses file range `0x030010–0x03400F` for bank `$18`, the same mapping used by
the supplied Turkish ROM. It labels `$8852` as the in-match menu renderer and
`$88B9` as its window/row producer. A local comparison against the supplied
ROM at `0x030862 + (CPU address - $8852)` found all 154 machine-code-annotated
instructions (302 bytes) from `$8852` through `$89A2` byte-identical. This
corroborates the external routine labels for this code window and gives a
useful navigation aid alongside the local [`menu renderer audit`](menus/first_action_menu/menu_renderer_algorithm_audit.md).

The source skips byte annotations across `$885E–$887B`; do not treat the
listing as complete disassembly for that interval. It contributes no live
caller RAM, task scheduling, PPU/OAM execution trace, or first-pixel timing.
Those remain local ROM/trace integration work, and the production route still
does not reach the menu.

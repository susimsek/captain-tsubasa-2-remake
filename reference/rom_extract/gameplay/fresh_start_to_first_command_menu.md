# Fresh KICK OFF route to the first command menu: ROM trace notes

## Scope and source identity

This note records the byte-checked static route from title confirmation
through match startup. A separate muted live FCEUX capture now supplies the
first complete command-panel observation; see
[`kickoff_first_command_menu_trace_20261027.md`](kickoff_first_command_menu_trace_20261027.md).
The action menu's initial state and direction mapping are traced from the
target ROM in
[`first_action_menu_input_rom_trace_20261027.md`](first_action_menu_input_rom_trace_20261027.md):
it starts unselected, and each newly pressed direction directly chooses an
action rather than navigating the visible status lines. A live direction probe
and Godot implementation remain outstanding.

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256 (whole iNES file):
  `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- MD5 of PRG+CHR after removing the 16-byte header:
  `eaf2b3745263efa4b1afd2b400f68dae`
- Header: iNES, mapper 4/MMC3, 256 KiB PRG and 128 KiB CHR.
- Static disassembly lead: [pinned CT2 disassembly](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64), revision `ec03cf06e6bdae0bcd232e3a423e9d259757dc64`.

All file offsets below include the 16-byte iNES header. Mappings used here:

| Window/listing | File offset formula |
|---|---|
| Bank 0 at `$8000` | `0x000010 + (CPU - 0x8000)` |
| Bank 2 at `$A000` | `0x004010 + (CPU - 0xA000)` |
| Bank 3 at `$A000` | `0x006010 + (CPU - 0xA000)` |
| Listing bank `$10` at `$8000` | `0x020010 + (CPU - 0x8000)` |
| Listing bank `$1A` at `$8000` | `0x034010 + (CPU - 0x8000)` |
| Fixed bank `$FF` at `$C000` | `0x03C010 + (CPU - 0xC000)` |

The bank-80/81 and fixed-bank-FF disassembly bytes have broad local audits
documented in `reference/rom_extract/intro/online_reverse_engineering_resources.md`.
The route bytes and data excerpts below were additionally checked directly in
this ROM. Bank 82 has a known three-byte difference at file `0x0048C7–0x0048C9`
inside the roster helper's `$ED` write; the team selector, team IDs, and roster
table bytes used below match locally. Bank-98 menu descriptors are not assumed
to match this ROM.

## Route confirmed by local bytes

### Title confirmation and new-game setup

With the cursor on KICK OFF, title code at CPU `$80D4` / file `0x0000E4`
checks whether A and B are held together. That combination branches to the
music screen; otherwise `$ED` selects Continue or KICK OFF. The KICK OFF branch
at `$80E6` / file `0x0000F6` calls `$9BA0`, then loads cutscene ID `1` and calls
the `$8464` cutscene dispatcher. The first bytes at file `0x0000F6` are:

```text
20 A0 9B A9 01 20 64 84 20 B5 82 A9 C0 85 E0 ...
```

Cutscene table file `0x006010` is in bank 3 at `$A000`. Entry 1's word at
`0x006012` is `A1 A2`, little-endian `$A2A1`; its script begins at file
`0x0062B1` and starts `E8 01 F9 5C FB 01 6D DD ...`. This differs from the
title intro's scene 0 entry at `$A020`; scene 1 is the KICK OFF confirmation
cutscene entry, not a new hand-authored menu.

After that cutscene, bank 0 initializes new-game flags (`$E0=$C0`), invokes
bank-2 setup through `$A20F`, clears goals and period, queues sound command
`$01`, normalizes the roster again through `$A20C`, then calls the bank-1
pre-match setup at `$A006`. It writes music ID `$55` to `$0700` at CPU `$812C`
/ file `0x00013C` (except the final-match branch, which uses `$4C`). It then
checks `tbl_83DC[$26]` at CPU `$83DC` / file `0x0003EC`; when the fresh-start
match index `$26` is zero, the byte is `$02`, so the pre-match cutscene
dispatcher receives ID 2. Bank-3 pointer entry 2 at file `0x006014` is
`26 A6`, resolving to CPU `$A626` / file `0x006636`; that script begins
`E8 01 F9 02 FB 01 15 DE ...`.

The KICK OFF branch does not itself write `$26=0`; the match-zero interpretation
is conditional on the cold-start RAM value. The live route capture should
record `$26` before relying on it as an observed initial value.

### Preserved KICK OFF cutscene source spans

The exact pointer spans for cutscene IDs 1 and 2 are preserved unchanged from
the supplied ROM by `tools/extract_kickoff_cutscenes.py`. Their metadata records
the source ROM hash, pointer-table bytes, CPU/file ranges, and hashes in
`kickoff_cutscene_01.json` and `kickoff_cutscene_02.json`; the raw pointer spans
are the matching `.bin` files. The spans are 901 bytes at `$A2A1–$A625` and 142
bytes at `$A626–$A6B3`.

The same tool follows the supplied interpreter's linear opcode widths through
the first reachable `$FF`. The bank-0 vector at file `0x000555` dispatches
`$FC` through the RTS return word `$8836` to handler `$8837`; the handler
advances `$4D/$4E` by one byte. It does not consume the following bytes as a
counted payload. Therefore both execution spans end exactly at their next
pointer: ID 1 is 901 bytes at `$A2A1–$A625`, and ID 2 is 142 bytes at
`$A626–$A6B3`. The ROM-indexed event manifests contain 222 and 45 events,
respectively. No reachable `$FE` occurs in either linear stream. This verifies
command boundaries and order, not command timing, every graphics/audio
producer, or a Godot runtime sequence. The superseded counted-payload result
was invalid and must not be used.

The byte-indexed event manifests are generated by
`tools/gameplay/build_kickoff_cutscene_events.py` at
`assets/gameplay/rom_logic/kickoff_cutscene_01_events.json` (222 events) and
`kickoff_cutscene_02_events.json` (45 events). Each event stores its original
bytes and ROM file/CPU location. They are command-boundary data, not a timed
runtime script; cutscene frame waits and visual/audio handler effects remain
unresolved.

### Team setup for match index zero

Bank-2 trampoline `$A20F` at file `0x00421F` jumps to `$A86E` at file
`0x00487E`. For match index `$26=0`, the routine selects the São Paulo roster
record starting at file `0x004A57`. Its first 12 bytes are:

```text
02 03 04 05 06 07 08 09 0A 01 0B 00
```

The first eleven values populate player IDs; the twelfth is the formation
selector. At `$A8A8`, it reads `tbl_AA75[$26]` at file `0x004A85`: entry 0 is
team ID `0`. It calculates opponent ID as `$26+3`, giving ID `3` for match 0.
“São Paulo” and “Fluminense” are the disassembly's team labels; the numeric
IDs and bytes are the locally checked facts.

### Kickoff, music, and first field loop

After pre-match setup and cutscene ID 2, bank 0 jumps through `$8017` to bank-2
startup `$A203` (file `0x004213` trampoline), which reaches `$A2AF` and then
fixed-bank gameplay setup. The fixed-bank routine `$DAAA` / file `0x03DABA`
starts the kickoff state. It first queues audio command `$01` to stop the
previous cue, calls setup helpers, then uses `$0629` to select a kickoff-side
branch through the table at `$DB2A` / file `0x03DB3A`. Resetting gameplay RAM
clears `$0629`, so a fresh start selects branch 0 at `$DB34`.
The supplied-ROM writer path is now byte-mapped: `$A2AF->$AA06` clears
`$0468-$06FF` (152 bytes on its first pass, then 256 bytes on each of two
wrapped passes), then scheduled `$D11E->$D14F` copies the fresh period
`$0027=0` to `$0629` immediately before `$DAAA->$DB24` reads it. See
[`fresh_kickoff_0629_selector_source_audit_20261028.md`](fresh_kickoff_0629_selector_source_audit_20261028.md).

Branch 0 sets the kickoff side: if opponent ID `$2B` equals `3`, it writes
`$044F=$00` and `$05FB=$00` (left/São Paulo); otherwise a random bit can choose
the right side. This conditional is direct from code; the “match 0 takes the
left side” result depends on the observed `$2B=3` setup above.

The kickoff initializer renders the period/time/score panel, starts scenario
ID `$35`, and waits until either A or B is held (`$1C & $C0 != 0`). Scenario
ID 35 is reached through the bank-`$10` pointer word `CD B7` at file
`0x020A39`; its stream is file `0x0237DD` / CPU `$B7CD` and begins:

```text
F9 EB 44 02 3A 8F 73 FB
```

After the A/B wait, code sets the initial ball player to `$05FB+8`, initializes
formation coordinates, and selects a receiver from table `$DC82` using
`($E2+1 & 7)` reduced to `0..4`, then offset by `$05FB`. It queues scenario
ID `$36`; its pointer word is `E4 B7` at file `0x020A3B`, and its stream begins
at file `0x0237F4` / CPU `$B7E4`:

```text
F5 F9 02 7F 10 3A 8F F0 F9 02 66 20 0C 4E 74 FD ...
```

The scenario stream is direct ROM data; the command names in the disassembly
are labels, not proof of exact PPU-visible output. The receiver is not
deterministic from this static route alone because `$E2` depends on prior
runtime state.

The kickoff code stores the receiver into `$0441` (player with ball), sets
`$05FD=1` (controlled flag), and jumps to `$E0DF` / file `0x03E0EF`. That
routine initializes the field HUD, sets the ten-tick run timer, selects the
ball-side/team state, and calls the field-running scenario setup at `$E233`.
The repeated per-frame input/update loop begins at `$E145` / file `0x03E155`.
On the left/home possession path, D-pad input changes the ball-holder's field
position; the active receiver, coordinates, and actual first user action must
be read from the live capture.

## First in-match command menu: static route and live observation boundary

The fixed-bank field loop reads B in `sub_E349` at `$E35B–$E360` (file
`0x03E36B–0x03E370`). On the left-team path, B held takes the branch that
clears the defender count/flags, queues scenario `$44`, clears sprite memory,
and jumps into bank-`$1A` routine `$803C` / file `0x03404C`. The byte-checked
fresh left-team path sets context `$0621=0` and calls `$D575`; this reaches
`$D5C3`, which selects descriptors `$02` (action prompt) and `$03`
(player/status panel) through the shared renderer. The input path and IDs are
documented in the linked target-ROM trace.

The target-ROM call chain confirms descriptor IDs `$02/$03`; the full field
background/raster and exact menu packet timing are still unresolved.

Japanese manual/control guides describe A as confirm, B as command-menu access,
and directional input as menu navigation. They are control descriptions, not
ROM execution traces: [Japanese game guide](https://gcgx.games/captain-tsubasa2/info.html),
[manual transcription](https://setsumei.cloudfree.jp/famicom/captaintsubasa2/captaintsubasa2.html).
The muted same-input capture applies B at source frame 8893 after the fresh
start enters active field play. The first sampled full panel appears at frame
8953 and shows Çalım, Pas, and Şut alongside player energy/stat values. It saves
the associated PPU, RAM/OAM, MMC3, and APU-write evidence in the linked live
trace. The capture does not show a cursor/highlight, consistent with the ROM's
unselected entry state. Its screenshot samples bracket the full-panel onset
between frames 8938 and 8953; the exact pixel onset and live gameplay caller PC
remain unknown.

## Evidence classification and open items

| Finding | Evidence class | Status |
|---|---|---|
| Title cursor branch, KICK OFF cutscene ID 1, and new-game setup call chain | Local ROM bytes; bank 80 byte audit | Confirmed statically. |
| Cutscene 1 `$A2A1` / `0x62B1`, match-zero scene ID 2 `$A626` / `0x6636` | Local pointer-table bytes and script bytes | Confirmed statically. |
| Match-zero roster, team IDs 0/3, first-kickoff left side | Local bank-2 tables/code and fixed-bank branch | Confirmed if `$26=0` and the setup reaches `$DB34`; cold-start `$26` must be captured. |
| Kickoff scenarios 35/36, sound queue values, input wait, receiver formula | Local bank-10 stream and fixed-bank code bytes | Confirmed statically; actual `$E2` seed and chosen receiver unknown. |
| First field command panel and initial selection | Live FCEUX observation plus target-ROM handler bytes | Full panel captured; `$061E=0` means action unselected at entry. |
| Menu descriptor IDs `$02/$03` | Target-ROM `$803C → $D575 → $D5C3` path and context tables | Confirmed statically; full field/raster composition remains open. |

Remaining route work: implement ROM-derived selection/blink in Godot, obtain a
same-input D-pad probe if feasible, and reconstruct the field/menu screen from
ROM graphics and decoded producers. Keep route PPU/RAM/OAM/APU artifacts as
observation and mapping references only.

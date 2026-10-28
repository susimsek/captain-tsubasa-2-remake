# First-command player and opponent state: live-route source audit

## Scope and ROM identity

This audit checks whether Godot can derive the initial match state for a fresh
KICK OFF route from live route inputs and supplied-ROM logic. It does not use
endpoint RAM as runtime state and does not change runtime code. The supplied
Turkish ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Offsets below include the 16-byte iNES header. The English community
disassembly was used to navigate; the relevant bytes and data were checked in
the supplied ROM.

## Home team and current ball player

For match index `$26=0`, bank `$02` `$A86E` (file `0x00487E`) reads the
match-zero home roster at `0x004A57`:

```text
02 03 04 05 06 07 08 09 0A 01 0B 00
```

The first eleven bytes are home player IDs and the twelfth is formation. The
same setup chooses home team ID `$00` and opponent ID `$03` at `$A8A8-$A8B6`
(file `0x0048B8-$0048C6`). These bytes, plus cold-reset RAM clearing, are
source inputs; the captured endpoint slot is not.

At fixed-bank `$DAEF-$DB08` (file `0x03DAFF-$03DB18`), the kickoff routine
chooses a receiver from `$E2 & 7`, folds values 5–7 by subtracting 5, reads
`$DC82 = 05 06 07 09 0A`, adds the home-team base `$05FB`, and stores the
result to `$05FC`. `$DB13-$DB16` copies that result into current ball-player
slot `$0441`. This is a deterministic ROM formula once the *live* `$E2` at
the held A/B kickoff gate is known.

The existing `RomFreshKickoffMatchStateProvider` already derives the home
roster, zero fresh-start levels, ROM profile IDs, maximum stamina, and current
energy from extracted ROM tables. Its source path is described in
[`first_command_player_state_source_20261027.md`](first_command_player_state_source_20261027.md).
It currently obtains the receiver from `RomKickoffRngSourceReplay`, which
accepts only the audited input timeline SHA-256
`6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc`.
The provider is isolated; `KickoffRouteRuntime` does not supply a live
ROM-derived receiver or eligible `$E14D` field-loop iterations.

## Why receiver selection is not yet live-input-generic

The schedule builder executes the ROM-only CPU/PPU source stepper from cold
reset with one recorded input route. The Godot replay helper consumes the
resulting call schedule: it applies `$A117` arithmetic on fixed frame ranges
and loads recorded post-call `$E1/$E2/$E3` for `$C9C5`. Its input-hash check is
an integrity guard, not a random seed; removing it would make a different
route appear supported while returning the old route's receiver.

The supplied-ROM execution path has two mode-selected update sources:

- `$C76E` (file `0x03C77E`) checks `$001B` bit 6. When set, the NMI goes via
  `$C421` to bank `$02` `$A000`, whose controller-read path reaches `$A117`
  (file `0x004127`) and updates `$E1/$E2/$E3`.
- When bit 6 is clear, the normal NMI reaches `$C7E4` (file `0x03C7F4`) and
  calls `$C9C5` (file `0x03C9D5`). That routine reads `$0300,X`, `$0700,X`, and
  `$0780,X`, with `X=$E1`, and consumes incoming carry before incrementing
  `$E1`.

The route runtime does not model the live producer of `$001B`'s mode bit, the
NMI/task call cadence, the controller-read point, `$C9C5`'s three RAM operands,
or its carry input. Those depend on the cooperative scenario/field route and
can change with input. Therefore the fixed replay cannot be generalized by
advancing it to a different frame or by accepting another hash.

## Opponent initialization and data path

For match zero, the fixed-bank dispatch at `$DB24` (file `0x03DB34`) selects
the fresh-match branch at `$DB34` (file `0x03DB44`). That branch maps PRG
banks `$1C/$1D` and calls bank-$1C `$8B22` (file `0x038B32`). That routine:

1. Initializes opponent record slots `$0B-$15` (decimal 11–21) to clone ID 0
   and clears their first clone flag.
2. Selects an opponent parameter pointer using `opponent_id - 3`; match zero
   therefore selects entry zero of `$BAB2` (file `0x03BAC2`), pointer `$BAF6`
   (file `0x03BB06`).
3. Loads the selected opponent table's formation/defense values and reads the variable-length
   override list beginning at data offset 9. For this record the first value
   is `$0F`, the terminator checked by `$8B65`; thus this match has no
   per-slot named-player overrides in this table. The navigation disassembly
   labels entry zero “Fluminense”; the locally checked fact is team ID `$03`
   selecting that first pointer/data row.

The target bytes at `$BAF6` / file `0x03BB06` begin `00 00 76 77 77 78 A0
1F 1F 0F`. `$8B4D-$8B5A` writes the first two fields to right-side formation
and defense RAM; `$8B65` sees the final `$0F` and exits the override reader.

For clone ID 0, bank-$1C `$803A` (file `0x03804A`) maps the opponent slot
through `$818E` to a position class, reads the corresponding value from the
selected opponent parameter record, then uses the ROM stat curves. The class
map `$818E` and opponent stat-profile table `$9662` (file `0x039672` onward)
are ROM data; the team selection and `$BAB2` parameters are also ROM-derived.
`$DC07` uses the match's formation values and the `$DC87/$DCB3` coordinate
tables to initialize the player records' field positions. This establishes a
general source path for opponent identity/class/profile and initial formation
position when the match/opponent IDs are available.

There is a boundary for the first-menu state model: fixed-bank `$DB62`'s
maximum-energy initializer starts at player index 10 for match-zero team ID 0
and writes down through index 0. It does not initialize opponent record energy
in this route. The opponent parameter/profile path can calculate opponent
skills, but this audit has not identified a source writer that assigns
current/max energy to generic opponent records before the first menu. Do not
invent opponent energy values or derive them from the frame-8953 RAM dump.
Opponent energy is not required to display the initial unselected action menu;
it remains needed before implementing opponent stamina behavior.

## Exact remaining adapter and safe next step

The current state provider can remain the stat/record calculator, but runtime
integration needs a source-owned route context that supplies:

1. The match index, home/opponent team IDs, and the source event that selects
   the receiver. For arbitrary interactive routes, derive `$E2` by modeling
   the mode-gated `$A117/$C9C5` call stream and `$C9C5` operands/carry; do not
   inject a captured receiver or disable the existing timeline-hash guard.
2. For stamina updates, whether each field-loop iteration reaches `$E14D`
   after `$E349`; B/menu entry may exit before the timer check. The existing
   provider already models the `$0614=10` and `$E2BC` rules conditional on this
   source event.
3. If the first-menu presentation needs opponent records, instantiate the
   clone slots from `$8B22`, select `$BAB2[opponent_id-3]`, and evaluate their
   attributes through `$803A`/the ROM curves. Keep current/max opponent energy
   unresolved until its writer is traced.

The next feasible implementation is a separate ROM-derived match-context
adapter with a small, explicit result type. Initially it can accept only
source-verified kickoff fields and the independently verified receiver event,
keeping the current fixed-route replay marked diagnostic. Generalize the RNG
only after its scheduler mode/call sequence and RAM operands are source-driven.
No runtime wiring or capture constants are justified by this audit alone.

### Capture-only `$0614` field timer observation (2026-10-28)

The per-frame RAM snapshots in
`reference/diagnostics/kickoff_select_test_20261027/ram/route_frame_008841.bin`
through `route_frame_008893.bin` (all 53 files present, each 2 KiB) show this
single recorded-input route:

| Source frames | Captured `$0614` | Captured `$0618` |
|---|---:|---:|
| 8841 | `$00` | `$00` |
| 8842–8844 | `$0A` | `$00` |
| 8845–8854 | `$09`…`$00` | `$00` |
| 8855–8882 | `$0A` | `$00` |
| 8883–8892 | `$09`…`$00` | `$00` |
| 8893 (B input) | `$00` | `$00` |

The RAM-only capture above has no PC trace; the later expanded trace
[`first_command_menu_wait_and_stamina_trace_20261028.md`](first_command_menu_wait_and_stamina_trace_20261028.md)
adds it. `$E145` runs at 8844–8854 and 8882–8892; eligible `$E14D` runs at
8845–8855 and 8883–8892. `$0614` reaches zero/reloads at 8855, and
`$E1F7→$E2BC` runs once at 8858 while `$0618` changes `$00→$01→$00`. The next
`$0614` countdown reaches zero at 8892, but B at 8893 exits before a second
stamina-helper call. These are observed ROM call windows for one replay, not
a reusable timer schedule. They still do not explain why `$E145` is absent
during 8856–8881, establish `$0618=$FF` wrap behavior, or capture the player
record writes needed to independently verify the numeric energy change.

## Evidence boundary

ROM bytes and the cold-reset route establish the table/code path above. The
retained same-input PPU/RAM captures validate one route instance only; they
are not source inputs. The actor/OAM route has separate setup and animation
writers, documented in
[`fresh_kickoff_actor_initialization_rom_audit_20261027.md`](fresh_kickoff_actor_initialization_rom_audit_20261027.md)
and [`first_command_actor_state_producer_20261027.md`](first_command_actor_state_producer_20261027.md).
This audit does not establish that the Godot field actors, opponents, or
first-menu player state are already integrated.

# First-command-menu player state source trace — 2026-10-27

## Scope and identity

This note follows the selected player tuple used by the first in-match
command/status panel. It separates ROM-derived identity and stat calculations
from live match-state bytes that are still only observed in the FCEUX trace.
The supplied ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
FCEUX RAM snapshots are validation evidence only; none is a runtime asset or a
seed for the source-derived values below.

## Selected slot and player identity

The ROM-only KICK OFF route replay starts CPU RAM `$E1-$E3` at zero and applies
the logged cold-start input timeline. Its route identity is SHA-256
`6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc`. The
source stepper executes the bank-$02 `$A117` state update 8,446 times and the
fixed-bank `$C9C5` helper 133 times before the receiver store at `$DB08` on
source frame 8593. At that store `$E1/$E2/$E3=$7F/$BE/$3C`; the ROM reduction
`$BE & 7 = 6`, then `6 - 5 = 1`, indexes `$DC82[1]=$06`, so `$05FC=$06`.
The helper replay matches all 3,901 available route RAM snapshots through
frame 8593, rejects a mismatched input-timeline hash, and is documented in
`scenario_interpreter_kickoff_rng_audit_20261027.md` and
`first_action_menu_blink_and_ball_holder_trace_20261027.md`.

After scenario `$36`, fixed-bank `$DB13-$DB16` transfers `$05FC` into the
current ball-player slot `$0441`. In the retained same-input trace, the sampled
record changes from slot `$08` at frame 8773 to slot `$06` by frame 8788; the
route RAM dump at frame 8953 still has `$0441=$06`. For match zero the local
ROM roster bytes at file `0x004A57` are
`02 03 04 05 06 07 08 09 0A 01 0B 00`; entry 6 is player ID `$08`. The roster
table is source ROM data, and its entry agrees with the live current-player
record. The upstream bank-$82 listing's helper bytes at `$A8B7` differ from
this ROM at file `0x0048C7-$0048C9`; the roster data itself was checked locally,
so the translated listing is not treated as byte-identical executable proof
for that helper.

The fixed-bank pointer table `$CD89` is preserved as
`menus/first_action_menu/player_record_pointer_table_22.bin` (ROM file
`0x03CD99`). Entry 6 is `48 03`, so the selected record begins at RAM `$0348`.
The source `$E0/$E1` menu renderer uses the current ball-player slot to look
up this record; record byte `+0` is player ID, `+1/+2` are current energy in
little-endian order, and `+3` is level. The ROM position/name mapping and
normal-player stat profile tables are already extracted under
`menus/first_action_menu/` by
`tools/gameplay/extract_first_action_menu_dynamic_tables.py`.

For ID `$08`, ROM name pointer `$F52B` yields the original four name tiles
`10 11 08 10`; the slot-6 position bytes are `86 92`. The low-ID stat-profile
map selects profile `$06`; its record begins at `$A05E` and selectors 1, 2,
and 3 use curve indexes 1, 2, and 3. With the live record's level byte 0, the
ROM value curve resolves those stats to 8, 8, and 9. The current energy token
does not use that profile: it reads the selected live record's `+1/+2` bytes.

## Fresh-start record initialization and energy writer

The ROM's fresh-match setup at bank-$80 `$811F` calls fixed-bank jump vector
`$C572`, which jumps to the energy initializer at CPU `$DB62` (ROM file offset
`0x03DB72`). The initializer's `$DB72` instruction is inside the routine;
`$DB6D-$DB9D` iterates the team's roster, invokes `$CE08` with
stamina selector X=0, then stores the returned 16-bit maximum at player record
bytes `+1/+2` through `$DB90/$DB95`. This is the source of the initial energy
field; the frame-8788 value 400 is not a runtime constant.

For the ROM-selected slot, the bank-$1C evaluator `$803A/$8113` computes
stamina using ROM tables. The home-player profile selector comes from
`$95D6` (already extracted as `player_stat_profile_map_00_22.bin`); it indexes
the first byte of an eight-byte stamina record in `$AE86-$AFAE`. The current
level is added to that stamina curve index, clamped at `$5F`, and the result
indexes the little-endian 16-bit value table `$9F0E-$9FCD`. For this input
route, the RNG replay resolves a slot, the match-00 roster at file offset
`0x004A57` resolves its player ID, and the ROM profile/value tables then derive
that player's maximum. The slot-6 / ID-8 validation case resolves profile 6,
stamina index 0, and word `$0190` from `$9F0E`; this agrees with the retained
RAM sample but comes from ROM bytes and the reset level state.

The fresh-start level byte is zero because the cold-reset routine clears
volatile CPU RAM before the match. The match-zero roster setup assigns player
IDs; the `$DB62` initializer writes energy only. Bank-1 `$A611` (file offset `0x002621`)
recomputes a player's level from experience and writes record `+3` only when
the computed level differs. On this fresh route, reset experience and the
existing level are both zero, so the compare skips the store. Thus level 0 is a
ROM-derived fresh-reset state, not a frame-8953 value imported at runtime.

## Run timer and 400-to-397 update

Fixed-bank `$E0DF` initializes `$0614=10`. Each iteration at `$E145` waits one
game frame and calls the `$E349` input/transition handler before reading the
timer at `$E14D`. If `$0614` is nonzero, it decrements the timer and returns to
`$E145`. When an iteration arrives with `$0614=0`, `$E158` reloads 10 and the
ordinary left-team path reaches `$E1F7`, which calls `$E2BC`. Therefore the
first stamina update occurs on the 11th eligible field-loop iteration; later
updates occur every 11 eligible iterations. This is a game-loop counter, not
an unconditional 11-rendered-frame timer. D-pad movement does not change the
timer branch. B is handled earlier by `$E349` and exits to the command menu
before that iteration reaches `$E14D`; other field transitions can also leave
the loop.

`$E2BC` first increments byte `$0618`. If it wraps from `$FF` to `$00`, the
routine branches past teammate regeneration but continues to charge the
current holder. Otherwise it regenerates each non-holder by 2, capped at its
ROM-derived maximum (Misugi has a separate 1-point/alive rule), then charges
the current holder 3 energy or 5 for Misugi. The holder value is floored at
zero. The current holder's high and low energy bytes are written by `$E33F`
and `$E343`; caller `$E1F7` is the path that invokes the updater. `$0618`
starts at zero after reset, so the first 255 updates run regeneration and the
256th skips only regeneration. For the ordinary player on the verified route
the first source operation maps 400 to 397.

The retained same-input FCEUX snapshots show the selected record as
`08 90 01 00` at frame 8788 and 8848, then `08 8D 01 00` at frame 8863, with
level still zero at the command-menu snapshot. The existing PC-hook file does
not hook `$E145/$E14D/$E1F7/$E2BC` or record writes to the selected player's
energy bytes, so it bounds the 400-to-397 write to frames 8848–8863 but does
not identify its exact FCEUX cycle yet. The source-level 11-iteration cadence
and byte writer are known; exact frame/cycle alignment and the number of
eligible loop iterations in arbitrary interactive input remain open.

## Runtime-owned player-state provider

`scripts/gameplay/rom_fresh_kickoff_match_state_provider.gd` constructs all 11
match-zero home-player records from the ROM roster, profile map, stamina
profile/value tables, and player-record pointer table. It obtains the current
ball-player slot from `RomKickoffRngSourceReplay` after the receiver event; it
does not embed a captured slot, player ID, max/current energy, or record bytes.
It initializes fresh levels to zero from the reset/new-game path, derives each
maximum energy from the ROM tables, and owns current energy. Its field-loop
method models the `$0614=10` check/reload and applies the `$E2BC` `$0618` byte
counter, regeneration-skip wrap, run-cost, Misugi, cap, and zero-floor rules
only when the caller reports an eligible `$E14D` iteration. The focused
diagnostic also checks that the wrap skips teammate regeneration while
preserving holder cost.

The provider explicitly depends on the existing input-hash-bound receiver
replay, which currently supports the audited same-input route only.
`KickoffRouteRuntime` now exposes `bind_match_player_state_provider()` and
`install_first_action_menu_from_provider()` so a configured provider can be
consumed without passing captured RAM values; its
`report_eligible_field_loop_iteration()` forwards only a caller-confirmed
`$E14D` iteration while the route is in `FIELD_RUNNING`. The focused
`verify_first_action_menu_route_integration.gd` check now configures the
ROM-derived receiver replay, creates the player state from ROM tables, applies
eleven eligible timer iterations (one `$E2BC` update), and installs the menu
without reading the endpoint RAM snapshot. This checks the new API and the
dynamic panel data path, not the live route's actual input schedule.

The live route does not yet bind a provider, verify the complete interactive
input hash, or generate ROM-confirmed `$E14D` events; the forwarding method has
no production caller. For a different interactive route, a generic
source-derived RNG state machine remains necessary. Menu B and other
transitions preempt the `$E14D` check. The provider is therefore a tested
ROM-derived state owner and route interface, not proof that the running game
already supplies dynamic match state at its first menu.

## Why the current input-hash schedule cannot be generalized safely

The schedule hash is an integrity guard for one recorded input sequence; it is
not itself a ROM seed. The builder executes the ROM-only CPU/PPU stepper from
reset with that input sequence and does not seed from the target RAM captures.
The Godot `RomKickoffRngSourceReplay`, however, is a replay of the resulting
update schedule: it increments `$A117` on listed source frames and loads the
recorded post-call `$E1/$E2/$E3` states for `$C9C5`. It does not execute the
`$C9C5` arithmetic or derive either call stream from live Godot inputs. Removing
the hash check would therefore let this fixed schedule assign the wrong
receiver after a different input/timing path.

The target ROM's branch conditions are byte-checked:

- Fixed-bank `$C76E` at file `0x03C77E` is `24 1B 50 03 4C 21 C4`
  (`BIT $001B; BVC +3; JMP $C421`). When `$001B` bit 6 is set, the NMI takes
  `$C421`, maps the bank-$02 controller path, and reaches the RNG update after
  its controller-read loops. The entry `CLC` is at `$A116` / file `0x004126`;
  the first arithmetic instruction, `LDA $E1`, is at `$A117` / file `0x004127`.
  The update therefore does not depend on caller carry.
- When `$001B` bit 6 is clear, NMI falls through to the normal body at
  `$C775`. That body reaches fixed-bank `$C7E4` (file `0x03C7F4`, bytes
  `20 C5 C9`) and calls `$C9C5`; it then calls `$C982` and sets `$001B` bit 7
  at `$C7EE` to release the cooperative scheduler. The two update sources are
  selected by this NMI mode branch, not by an unconditional per-rendered-frame
  counter.
- `$C9C5` (file `0x03C9D5`) begins `AE E1 00 BD 00 03 7D 00 07 ...`:
  `X=$E1`, then it reads `$0300,X`, `$0700,X`, and `$0780,X` while rotating and
  adding/subtracting through `$E2/$E3`; finally it increments `$E1`. It has no
  initial `CLC`/`SEC`, so its first `$0300,X + $0700,X` `ADC` uses the incoming
  carry left by the normal NMI call path. The current Godot provider/replay does
  not own those three RAM arrays, that carry, or the live `$001B` mode gate.

The ROM source arithmetic and these individual branches are known, but the live
Godot route does not model the NMI dispatcher, its `$001B` mode-bit producer,
the full controller poll point, or the RAM arrays/carry that feed `$C9C5`.
Until those source call events and operands are reproduced from the route's
current input and state, there is no safe hash-free RNG integration. Keep the
input-hash-bound replay as a diagnostic route fixture only; do not turn off its
guard, inject the fixture's receiver slot, or infer player energy from an
endpoint RAM capture.

## What this closes and what remains

- The receiver slot is provided by the ROM-only stepper for this exact,
  fingerprinted input trace. It must not be used as a universal default for
  other input sequences; arbitrary routes still need dynamic
  `$0300/$0700/$0780` values in `$C9C5`.
- Given the receiver slot and match-zero roster state, player ID, ROM
  name/position, level-0 technical stats, maximum energy, and record address
  can be resolved from preserved ROM data.
- The 400-to-397 source algorithm and 11-eligible-loop cadence are known, but
  the existing FCEUX trace only bounds the observed change to frames 8848–8863;
  it does not record the exact write cycle.
- The source writer and `$0618` wrap condition are now modeled. FCEUX trace
  hooks still do not expose the write cycle, so this is verified against ROM
  instructions and a ROM-table-driven provider diagnostic, not an exact
  same-input live-emulator write timestamp.
- The provider interface is exposed by `KickoffRouteRuntime`, but the
  production route does not yet bind a provider or call the forwarding methods.
  The live route still does not supply state from its own field-loop events.
  Its current RNG dependency is tied to one verified route input hash, not
  arbitrary interactive control.

The provider and source audit cover this player-state path only; they do not
claim the entire KICK OFF route is verified in Godot.

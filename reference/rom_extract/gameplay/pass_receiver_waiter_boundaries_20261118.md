# PASS Route: Scenario-$2E Actor Boundary (2026-11-18)

## Source and capture

This note compares the same-ROM FCEUX boundary capture in `reference/diagnostics/pass_receiver_waiter_boundaries_20261118_165343_utc/events.csv` with the production Godot route verifier. The capture is observational evidence; it is not a runtime input or state fixture. ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

## FCEUX sequence

- Frame 9474, sequence 1660, slot-$09 `$CB0F_scheduler_save`: actor record `$055C` has flag `$A1`, appearance pointer `$B048`, appearance timer `$00`, and descriptor `$04`; `$0498=$00`. Sequence 1667's `$8327_callback_handler` still sees `$055C=$A1`.
- Frame 9475, sequence 1668, next slot-$01 scheduler save: record `$055C` now has flag `$81`, pointer `$B04A`, timer `$04`, and descriptor `$05`; `$0498` remains `$00`. The same-ROM trace has no write hook at this boundary, so it does not prove the exact instruction that produced the flag change.
- ROM bytes `$83E9-$83EF` are `A0 00 B1 3C 29 9F 91 3C`: when the appearance timer reaches zero, `$83D9` clears flag bit `$20` before parsing the next appearance command. `RomActorStateInterpreter.tick_appearance_only()` now models this source step; the focused interpreter verifier passes, and the live route actor flags now match `$81/$81`.
- Frame 9476, sequence 1685, `$EB8B_scenario_root` entry: `$053A-$053D=00 00 90 00`, stream cursor `$98C4`, selectors `08 09 0A 0B`, append cursor `$0498=$00`, record flags `$0547/$055C=$81/$81`.
- Same frame, sequence 1686, `$EB9E_scenario_return`: the ROM-produced state is `$053A-$053D=80 00 8B 00`, `$0498=$01`; cursor, selectors, and record flags remain `$98C4`, `08 09 0A 0B`, and `$81/$81`.
- Frame 9477, sequence 1698, after the `$8B` stream returns: cursor `$9834`, selectors `20 21 00 00`, `$0498=$01`, and record flags `$81/$00`.

## Source-owned append and OAM decoding

The latest replay with a `$0498` write hook resolves the apparent append-count mismatch. At frame 9477, `$EE9F` enters with `$0498=$00`; the `$8B` stream begins `F5 80 F4 20 21 00 00 F1`, and its `$F5` handler reaches the ROM append helper `$C533->$CCD2`. Bank-$1E `$CD07` increments `$0498`; the write hook reports the post-write PC `$CD0A`, and the `$EEB1` return has `$0498=$01`. The Godot `$8B` entry precondition is therefore correctly zero and remains strict.

With that gate corrected, the previous live route reached the actor OAM builder and exposed a missing ROM span. Frame-9477 actor `$0547` uses descriptor `$CF`, selector `$08`; pointer-table entry `$841E` contains `2D BE`, resolving to `$BE2D`. The selector path is `$BE2D->$BE9F->$BE56`, then terminates at `$BE80`. The extractor now preserves only bank-$16 `$BE2D-$BED5` (169 bytes; file offsets `$02FE3D-$02FEE5`), ending before descriptor `$D0` at `$BED6`. The focused OAM verifier passes all 18 expected ROM tile IDs for this route actor.

## Godot route status

After adding the descriptor-$CF span, the recorded-input Godot route passes its frame-8863 stamina checkpoint (all eleven player records match same-input FCEUX) and the frame-9482 actor OAM build. It then stops at a later slot-$11 `$6D` continuation: Godot reports animation pointer `$A2BC`, while the verified initial worker profile is `$A2BA` with stack `$C7-$CA=04 04 49 80`. The rejected boundary has stack `$DB E3 49 80`, which is not a captured worker entry.

The focused FCEUX trace in `reference/diagnostics/pass_receiver_waiter_boundaries_20261118_200859_utc/` records writes to `$0063/$0064` plus full scheduler events and RAM/stack snapshots. The two write logs are identical after normalizing the replay number. Neither pointer byte is written in frames 9475–9493; the first observed pointer update is frame 9494, at `$A202/$A207`, setting the low/high bytes to `$E8/$A2`. The `$A2BC` state is therefore not present in the same-input FCEUX sequence at the rejected Godot boundary. Keep the `$A2BA` source gate strict and resolve the route's premature slot-$11 continuation or scheduling step before continuing. The route through frame 9600 remains unverified.

## Remaining acceptance

After the live route reaches frame 9600, compare same-input visible output, event timing, and ROM-derived audio, then verify a fresh standalone PCK without ROM, emulator, or capture dependencies. The extended PASS route has not yet passed those acceptance checks.

## Nov 19 addendum: direct `$F2` waiter dispatch

The repeated matched-checkpoint capture in `reference/diagnostics/pass_receiver_waiter_boundaries_20261119_192357_utc/` adds an execution hook at `$804A`; its two normalized event logs match. This supersedes the older note above that described the `$DBE3` return stack as an uncaptured worker entry. At frame 9477, seq 7077 directly records a slot-$11 `$804A` entry with scenario bytes `01 00 2E 77 E8 9B 00`, stream `$9BE3`, actor `$6D`, animation `$A2BA`, F4/F5 `00/01`, registers A/X/Y/P=`E3/E3/DB/B0`, SP `$CA`, and stack `$C7-$CA=DB E3 49 80`. The following source events execute `$80B5->$C52D->$CC46->$CC50->$CB0F`; the `$9BE3` ROM manifest identifies this first stream command as `$F2`.

The source-route executor now admits that complete signature as its own scenario-$2E actor-$6D F2-waiter entry profile and executes the existing ROM-byte F2 path. The focused assertion passes. The broader slot-$11 diagnostic still exits on a later, separate parameter-$47 `$82F7` case (`$8633` instruction limit), so that run does not establish the whole diagnostic. The ordinary Godot route is being replayed to check the next `$CC53` waiter boundary; frame 9600 and export acceptance remain unverified.

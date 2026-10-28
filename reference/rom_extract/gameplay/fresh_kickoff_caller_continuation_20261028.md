# Fresh KICK OFF caller continuation — 28 Oct 2026

## Scope and source identity

This bounded source component follows the title's KICK OFF branch through the
first-match queue store and automatic pre-match cutscene dispatch. It uses
hash-checked ROM bytes, not captured screenshots, PCM, frame tables, or RAM
dumps. The source spans and exact offsets are listed in
[`fresh_kickoff_caller/manifest.json`](fresh_kickoff_caller/manifest.json).

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- Bank `$00` mapping: file `0x10 + (CPU - $8000)`.
- Caller span: bank `$00:$80DF–$815C`, file `0x0000EF–0x00016D`.
- Wait span: bank `$00:$82B5–$82EC`, file `0x0002C5–0x0002FC`.
- Pre-match ID table: `$83DC` onward, file `0x0003EC`.
- Fixed mapper helper `$C4B9–$C4C7`, file `0x03C4C9–0x03C4D7`.

## Decoded caller path

The title caller tests `$ED.6` at `$80DF–$80E1`; a clear bit branches to fresh
KICK OFF at `$80E6`. That branch calls `$9BA0`, loads cutscene ID `$01`,
dispatches through `$8464`, then calls the Select-aware wait `$82B5` at
`$80EE`. The wait returns to `$80F1` after a natural end or a fresh Select
edge; its shared cleanup clears task bytes, stores `$01` to `$0700` at `$82DC`,
calls `$9BA0`, clears `$44/$45/$7A/$7B`, and returns.

At `$80F1`, the caller writes `$C0` to `$00E0`, selects bank `$02`, and calls
the match selector at `$A20F`. It clears `$28/$29/$27`, queues stop command
`$01` at `$8107`, normalizes the roster through `$A20C`, runs the goal/period
and pre-match helpers, and reaches the source music branch:

```text
$8122  A2 55       LDX #$55
$8124  A5 26       LDA $26
$8126  C9 20       CMP #$20
$8128  90 02       BCC $812C
$812A  A2 4C       LDX #$4C
$812C  8E 00 07    STX $0700
$812F              ; post-store PC
```

After clearing `$0450–$0453`, it calls `$A009` and tests `$00E0` at `$8145`.
The fresh caller value `$E0=$C0` takes `BMI $814F`, so the `$E4` comparison is
skipped. It indexes `$83DC` by `$26`; the reset-derived match index is zero,
and `$83DC[0]=$02`. The caller dispatches ID `$02` through `$8464` at `$8157`,
then enters the second `$82B5` wait at `$815A`.

The audio queue is therefore a consequence of reaching the `$812C` instruction
with the caller's current `$26`: values below `$20` store `$55`; values at or
above `$20` store `$4C`. It is not a cutscene `$ED` command and has no
relationship to a MEETING menu confirmation.

## Component contract

[`rom_fresh_kickoff_caller_continuation.gd`](../../../scripts/gameplay/rom_fresh_kickoff_caller_continuation.gd)
verifies the packaged caller, wait, cutscene-table, and mapper spans against
the ROM identity and manifest. It derives the cold-start `$26=0` precondition
from the checked eight-page RAM clear routine. To project the path, the caller
must provide a consumed Start event, the `$ED` title-selection byte, a decoded
ID-1 natural-end or Select-edge event, the caller-owned `$26/$E0` state at
`$8145`, and named returns for each unmodeled `JSR` in the path. The component
stops at the ID-2 wait call `$815A`; it does not confirm that wait or continue
into gameplay.

The `$0700` event at `$812C` is emitted by this bounded evaluator only after
all required earlier return receipts are present and the verified instruction
sequence reaches the store. Its event contains the store and post-store PCs,
queue ID, ROM hash, and unknown source frame/cycle. The executor does not run a
general 6502, helper bodies, the `$82B5` yield loop, the nested task stack, or
the CPU/NMI scheduler, and it is not connected to `KickoffRouteRuntime`.
Verifier receipts are fixtures for the interface contract; they do not prove
that those helper bodies ran in the live route.

## Trace comparison and remaining boundary

The ROM-only source queue table
[`first_match_audio_queue_events_20261027.json`](first_match_audio_queue_events_20261027.json)
records the `$55` store at source frame `7409`, cycle `220630517`, post-store
PC `$812F`. The muted FCEUX `pc_hooks.csv` records the ID-2 script entry
`$A626` on frames `7408–7409`; its selected hook set does not include `$812C`.
The captured APU register-write sequence matches the source-stepper sequence
as described in [`first_match_audio_source.md`](first_match_audio_source.md).
These timing and register-write records are validation references only; the
component does not read them or use them to schedule its event.

The production route still needs a real source-owned continuation from the
ID-1 `$82B5` return and live callers for the bounded `$C4B9`, `$A20F`, and
`$A20C` executors. The isolated `$A20C` component follows the `$A20F` result
through the real `$A8B6 RTS->$8112` continuation. The `$8114 JSR $8920` prefix
now runs through the real `$9DEE` and `$8938->$C4B9` RTS returns, then stops at
`$893B LDA $78 / BNE $893B`. `$78` and its resume event are not sourced, so the
`$8920` routine has not been shown to return. Other pending returns include
`$9BA0`, `$8920`, `$A006`, `$C572`, and `$A009`. The source wait's repeated
`$9FA8` yields, stack contents, interleaved NMI/task work, and source CPU
frame/cycle across these calls remain unmodeled. The ID-1 completion event
alone is not enough to establish those return states. Keep the `$812C` cue
outside production audio until that live continuation supplies the actual
instruction event and source clock.

Focused verifier:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_fresh_kickoff_caller_continuation.gd
```

The verifier compares the projected queue ID/PC and ID-2 table result with
the source-stepper queue record and checks the retained muted FCEUX hook
boundary. It does not validate full runtime integration, queue-to-APU latency,
PCM parity, or NES hardware timing.

## Return-contract audit follow-up — 28 Oct 2026

Three bounded ROM return executors and one setup-prefix evaluator now exist, but the production route does not
yet supply their caller events or entry state. `RomFixedMapperSelectHelper`
checks `$C4B9-$C4C7` and all four caller JSRs, then executes the mapper helper
from explicit CPU/stack/`$0022` state; it does not produce the call event or
update the live mapper. `RomFreshMatchSelectorExecutor` now executes
`$80FA JSR $A20F` through `$A20F->$A86E->$A8B7->$A138`, both RTS instructions,
and the `$80FD` continuation for match index zero. It requires explicit
post-`$C4B9` A/X/Y/P/SP, caller stack, `$22/$23/$25/$26`, and `Y=0`; no live
caller currently provides those inputs. See
[`fresh_kickoff_match_selector_executor_20261028.md`](fresh_kickoff_match_selector_executor_20261028.md)
and [`verify_rom_fresh_match_selector_executor.gd`](../../../tools/diagnostics/verify_rom_fresh_match_selector_executor.gd).
`RomFreshMatchNormalizeExecutor` continues that returned state through the
actual `$80FD-$810F` caller bytes, `$810C->$C4B9`, and `$810F->$A20C` through
`$A8B6 RTS->$8112`. It checks all 256 possible `$E4` values symbolically,
preserves caller CPU/RAM/stack/map state, and uses no trace value. The focused
verifier's event identity is a fixture, not a production route receipt. See
[`fresh_kickoff_match_normalize_executor_20261028.md`](fresh_kickoff_match_normalize_executor_20261028.md)
and [`verify_rom_fresh_match_normalize_executor.gd`](../../../tools/diagnostics/verify_rom_fresh_match_normalize_executor.gd).

Return-contract status for this caller chain:

| Call or wait | Executable source evidence | Remaining production boundary |
|---|---|---|
| `$C4B9` mapper helper | Hash-checked helper executes the 15-byte body and RTS for five checked caller sites, including fresh setup `$8938`. | The live caller must supply its event, registers, `$0022`, and JSR stack; no production mapper update occurs. |
| `$80FA->$A20F` match selector | Hash-checked helper executes the match-zero branch, `$A8B7->$A138` copy, roster copy, and both RTS instructions. | The live caller must supply source-owned post-`$C4B9` state, `$26=0`, stack, and `$Y=0`; `KickoffRouteRuntime` does not yet call it. |
| `$9BA0` (both cleanup sites) | Its `JSR $99F0; JSR $98A0; JMP $9B7F` chain is identified; the handoff planner emits unapplied effect plans. | Child CPU/PPU and state effects are not executed by a hash-bound helper; named planner receipts are not source execution. |
| `$A20C` | Hash-checked bounded execution reaches `$A8B6 RTS->$8112`; all 256 `$E4` candidates prove the fresh `$26=0` branch and output invariant. | The isolated contract is not supplied by the production route. The subsequent `$8920` call is only executed to its `$78` wait boundary so far. |
| `$8920` | Hash-checked caller prefix executes `$8920->$9DEE->$8925`, derives `$BF00`, and executes `$8938->$C4B9` to its real RTS with bank `$06` selected. | At `$893B`, the ROM reads `$78` and loops while nonzero. No source-owned `$78` value or scheduler/resume event is available; do not seed endpoint RAM or assume a delay. The 19-byte copy, bank restore and `$8920 RTS->$8117` remain unexecuted. |
| `$A006` / `$A009` | Their bank-$01 vectors and caller roles are known. | Their target bodies and return effects are not packaged as executable, hash-checked components. |
| `$C572` | The fixed jump to `$DB62` and ROM-table stamina formula are documented; the player-state provider computes energy values. | The provider derives data but does not execute indirect record writes or return on a source CPU stack. |
| `$8464` cutscene dispatch | Cutscene IDs, scripts, and dispatcher/task-install behavior are researched; the cutscene VM executes script semantics. | Script execution is not the dispatcher plus worker/task installation and JSR return. No source-owned scheduler event connects them here. |
| `$82B5` waits | Its bytes, natural-end/Select predicates, cleanup stores, and `$0700` stop store are checked. | `$9FA8` yields, input/NMI-ready events, stack continuation, and actual resumption are not run by the caller projection; a fixed elapsed delay is not a valid substitute. |

These are implementation boundaries, not unknown ROM addresses. ROM bytes and
traces can guide future executors, but trace RAM and observed frame numbers
cannot supply the missing runtime call state. `$A20C` is modeled only as an
isolated synchronous component starting from an explicit `$A20F` result. The
current exact boundary is the `$893B` wait on `$78`; solve its source-owned
value and resume event before continuing to the preset copy or `$8920 RTS`.
No synthetic route receipt was added, and `KickoffRouteRuntime` was not changed.

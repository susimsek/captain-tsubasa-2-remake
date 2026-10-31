# Fresh KICK OFF caller return-chain audit: `$80F7` to `$812C` — 2026-10-29

## Question and conclusion

Can the existing ROM-derived executors supply real return state for the fresh
KICK OFF caller from `$80F7` through the direct BGM queue write at `$812C`?

The muted, repeated trace documented in
[`fresh_kickoff_1b6_persistence_addendum_20261029.md`](fresh_kickoff_1b6_persistence_addendum_20261029.md)
now observes the real `$893B` exit, `$895C RTS->$8117`, and `$812C` BGM `$55`
write at frame 7409. This resolves the behavioral trace question. The Godot
component still stops at `$893B`; it must execute the ROM-owned NMI/IRQ and
source-clock path before it can issue its own return receipt. Do not inject the
FCEUX trace result as production state.

## Evidence identity

- Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- The bank-$00 caller span `$80DF-$815C` is checked by
  [`fresh_kickoff_caller/manifest.json`](fresh_kickoff_caller/manifest.json),
  file offset `0x0000EF`, length 126.
- The fixed mapper helper `$C4B9-$C4C7` and checked JSR callsites are in the
  same caller source package and the mapper-helper manifest.
- The `$8920-$893E` setup prefix and `$9DEE-$9E0B` multiply helper are checked
  by [`fresh_kickoff_match_setup/manifest.json`](fresh_kickoff_match_setup/manifest.json),
  file offsets `0x000930` and `0x001DFE` respectively.
- Exact caller and setup behavior is detailed in
  [`fresh_kickoff_caller_continuation_20261028.md`](fresh_kickoff_caller_continuation_20261028.md),
  [`fresh_kickoff_match_selector_executor_20261028.md`](fresh_kickoff_match_selector_executor_20261028.md),
  [`fresh_kickoff_match_normalize_executor_20261028.md`](fresh_kickoff_match_normalize_executor_20261028.md),
  and [`fresh_kickoff_match_setup_prefix_20261028.md`](fresh_kickoff_match_setup_prefix_20261028.md).

## Source path and executable coverage

| Caller transition | Existing ROM-derived consumer | What it can return | Remaining condition |
|---|---|---|---|
| `$80F7 JSR $C4B9 -> $80FA` | `RomFixedMapperSelectHelper.execute_source_call` | Executes the checked mapper helper and validates its actual RTS stack word and `$80FA` return PC. | A source-owned call event, pre-call registers/SP/stack, and `$0022` mapper shadow are required. Mapper bus writes are returned as effects; they are not applied to live route state. |
| `$80FA JSR $A20F -> $80FD` | `RomFreshMatchSelectorExecutor.execute_source_call` | Executes the fresh `$26=0` selector path through nested copy and real outer RTS; returns an actual `source_return_receipt`. | Requires the prior mapper output, caller JSR stack, explicit A/X/Y/P with `Y=0`, and `$22/$23/$25/$26`. Its current verifier event ID is a fixture, not a production event. |
| `$810C JSR $C4B9 -> $810F`; `$810F JSR $A20C -> $8112` | `RomFreshMatchNormalizeExecutor.execute_from_selector_return` | Continues the caller bytes, executes the mapper helper and `$A20C` normalization through a real RTS, returning the `$8112` register/RAM/stack state and source receipts. | It consumes a selector result; existing verification establishes this bounded component, not a production caller clock or a live route call. |
| `$8114 JSR $8920 -> $8117` | `RomFreshMatchPresetLoaderPrefix.execute_from_normalizer_return` | Executes `$8112-$8116`, the checked `$8920` prefix, `$9DEE`, and `$8938->$C4B9`; returns source state only up to `$893B`. | Live FCEUX behavior is known, but the Godot runner does not yet execute the ROM-owned NMI/IRQ and source-clock sequence or emit its own `$8117` receipt. |
| `$811C JSR $A006 -> $A4EB` | `RomFreshPrematchA006Entry.execute_source_call` | Verifies the caller JSR, bank-$01 vector `4C EB A4`, caller stack word, and transfers to `$A4EB`. | The `$A4EB-$A610` body is preserved but not executed; there is no `$811F` return or live route call. |

The route can therefore be composed using the existing real executors **only
through the `$893B` wait boundary**. Their source-return receipts should be
passed directly between components along with the executor-produced CPU, RAM,
mapper, and stack state. Converting their test fixtures into caller receipts
would not be evidence of execution. `RomFreshKickoffCallerContinuation` still
requires the `$8920` return before advancing to its direct music write.

## Historical static boundary

The packaged setup bytes end immediately before the wait predicate:

```text
$893B  A5 78       LDA $78
$893D  D0 FC       BNE $893B
$893F              ; first byte not included in the checked setup span
```

The live wait/return evidence is now in the linked report above. The remaining
work is to implement and verify the source-owned runtime transition; these
static notes record the component boundary when this audit was written.

1. Execute the ROM-owned NMI/IRQ/source-clock sequence in Godot from the
   existing route state; the FCEUX trace is a behavioral reference only.
2. Continue the existing source executors through the remaining `$8920` callee
   bytes, the `$BF00` preset copy, mapper restoration from `$EA`, and real RTS
   to `$8117`.
3. Continue the fresh caller through `$8119->$C4B9`, `$811C->$A006`,
   `$811F->$C572`, and the branch-selected `$812C` BGM write.

In the current Godot implementation, subsequent calls `$8119->$C4B9`,
`$811F->$C572`, and the body of `$811C->$A006` remain downstream work. The
`$A006` vector transfer alone is now hash-checked and executable as a bounded
entry component. The direct music block itself is already checked: CPU `$8122`
maps to bank-$00 file offset `0x000132`, and `$812C` is offset `0x00013C`.
It stores X to `$0700`; the preceding `$8124/$8126/$8128` branch selects `$55`
when `$26<$20`, otherwise `$4C`.

## Runtime implication

The live Godot task runner starts after the second cutscene and cannot supply
this earlier `$8920` return. Model the observed NMI/IRQ source sequence in the
runtime; do not inject a return or emit BGM `$55` from a later stage. This static
audit itself uses ROM source packages and component contracts only; it uses no
FCEUX audio, captured WAV, or emulator screenshot.

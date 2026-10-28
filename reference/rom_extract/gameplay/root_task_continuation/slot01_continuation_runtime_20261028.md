# Slot `$01` continuation caller slice — 28 Oct 2026

## Source evidence

The extractor preserves 14 bytes from the supplied Turkish ROM's fixed bank:

- CPU range: `$CA4D–$CA5A` inclusive (`$CA5B` exclusive)
- iNES file offset: `0x03CA5D`
- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- Span SHA-256: `e57b4fe7ceb639050a5d21b6a8d4ea958c181137f63ded21388b9ad9715a094a`

The source sequence is `LDA #$01; JSR $CB0F; JSR $EE9F; JSR $E3CA; JMP $CA4D`.
The earlier packaged root-startup span ends at `$CA51`; its first yield resumes
at `$CA52`, the `$EE9F` call. After both callees return, `$CA58` jumps back to
`$CA4D`, where the next one-tick `$CB0F` yield is requested. The next scheduler
resume therefore re-enters at `$CA52`.

## Implemented boundary

`RomRootSlot01ContinuationRuntime` hash-checks the packaged span and interprets
only this caller control flow. It emits ordered requests for `$EE9F` and
`$E3CA`, checks each returned target and continuation PC, forwards the returned
byte-valued A/X/Y/SP/bank state, applies the source `LDA #$01`, then emits the
`$CA4F → $CB0F` yield contract with resume PC `$CA52`. The existing
`RomGameplayTaskScheduler.yield_at_verified_callsite()` applies that yield
contract and preserves its task stack/record/cursor behavior.

No frame number, captured RAM, PPU image, or emulator event is a runtime input
to this helper. Returned callee register state is explicitly supplied by a
separate decoded source runner; it is not synthesized by this caller slice.

## Verification and limits

Run the focused verifier with:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_rom_root_slot01_continuation_runtime.gd
```

The verifier checks the packaged hash/bytes, rejects a wrong slot and return
PC, checks call order and byte-sized register inputs, and confirms the source
caller produces the expected scheduler yield record. To make the scheduler
reach the resumed root within the isolated verifier, the test fixture supplies
test-only yields for the other seeded root slots and one explicit NMI-ready
event. Those synthetic test inputs are not runtime evidence and do not model
their task bodies.

This slice does **not** execute the `$EE9F` actor update/draw body, the `$E3CA`
field-input body, their RAM/PPU side effects, or NMI timing. It also does not
connect `KickoffRouteRuntime` to the scheduler or produce the live route's
receiver/player state and field-loop events. Passing the verifier proves the
caller-byte continuation contract only; it does not establish live field
movement or first-menu reachability. The adjacent root-startup boundary is
documented in
[`first_root_slot01_startup_runtime_20261028.md`](../first_root_slot01_startup_runtime_20261028.md).

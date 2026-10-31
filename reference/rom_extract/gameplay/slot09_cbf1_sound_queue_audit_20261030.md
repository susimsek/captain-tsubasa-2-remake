# Slot-$09 root-loop `$CBF1` sound-queue helper audit — 2026-10-30

## Finding

When the slot-$09 root loop reaches `$EC02` and calls `$CBF1`, the helper
scans the five-byte sound-request queue at `$0700-$0704`. It stores the
caller’s accumulator in the first zero-valued slot and returns; if all five
slots are nonzero, it returns without adding a request. This is a queue write,
not audio playback. It does not write APU registers or establish that sound
`$44` becomes audible.

An earlier Godot route observation at `$EBD7` had `$052E=$EB`, `$052F=$44`,
`$063F=$00`, and mapper banks `$18/$19`; `$052E` decrements to `$EA`, so that
call takes the nonzero-countdown backedge and does not reach `$CBF1`. The
latest recorded-input route reaches `$EBD7` with `$052E=$00` and also skips the
helper through `$EBDA->$EC05`. Thus neither observation is a live `$CBF1`
call. The helper's counter-one source path is supported when `$052E=$01`,
`$052F<$7E`, and `$063F.7=0`: the caller decrements the counter to zero, passes
`$052F` in A, and reaches `$EC02`. The queue index and stored value then depend
on live `$0700-$0704` and `$052F`. The retained FCEUX trace does not capture
this later call or queue state.

## Source identity and mapping

The supplied Turkish ROM has SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
It is iNES 1.0, mapper 4, with a 16-byte header and no trainer. The helper is
in fixed PRG bank `$1E`, CPU `$CBF1-$CC01`, file offset `0x03CC01`, length 17,
SHA-256 `fc6689183aa19a053b44b44571a373ebb48b3bf940f299fb10623c61da4791ce`.
The bytes were re-read from that ROM offset and match the existing checked
span in [`fresh_daaa_continuation/manifest.json`](fresh_daaa_continuation/manifest.json)
byte-for-byte:

```text
A2 00 BC 00 07 F0 06 E8 E0 05 D0 F6 60 9D 00 07 60
```

The existing fresh-route package already contains the extracted source span
at
[`fresh_daaa_continuation/fixed_sound_queue_CBF1_CC01.bin`](fresh_daaa_continuation/fixed_sound_queue_CBF1_CC01.bin).
Its executor is tied to the `$DAAA` fresh-start entry contract; it does not
expose a safe public entry point for resuming this helper from `$EC02`.

## Instruction path

| CPU address | Bytes | Operation | Effect |
| --- | --- | --- | --- |
| `$CBF1` | `A2 00` | `LDX #$00` | Start at queue index zero. |
| `$CBF3` | `BC 00 07` | `LDY $0700,X` | Read one queue slot. |
| `$CBF6` | `F0 06` | `BEQ $CBFE` | Use this slot if it is zero. |
| `$CBF8` | `E8` | `INX` | Move to the next slot. |
| `$CBF9` | `E0 05` | `CPX #$05` | Stop after five slots. |
| `$CBFB` | `D0 F6` | `BNE $CBF3` | Scan again while `X < 5`. |
| `$CBFD` | `60` | `RTS` | Return if all five slots were occupied. |
| `$CBFE` | `9D 00 07` | `STA $0700,X` | Store the incoming request in the first empty slot. |
| `$CC01` | `60` | `RTS` | Return after the queue write. |

The root caller’s `$EC02` JSR pushes return-minus-one `$EC04`; the helper’s
RTS resumes at `$EC05`, where the root loop jumps back to `$EB86` and yields
through `$EB88->$CB0F`.

## Result contract for the observed caller state

For request value A and a first empty queue slot at index `j` in `0..4`, the
helper writes exactly `$0700+j=A` and returns with A preserved, `X=j`, and Y
equal to the zero-valued queue byte. If A is zero, this is still a ROM `STA`
to the first empty slot but the queue value remains zero. Carry is clear for
the supported caller, which reaches `$EC02` through `CMP #$7E` with
`$052F<$7E`; the `BIT $063F` result supplies N/V/Z, with N clear on the BPL
path. If all five slots are occupied, the helper performs no memory write and
returns with `X=$05` and Y equal to the existing `$0704` value. Flags not
changed by the helper retain their incoming values.

If all five slots are occupied, the helper performs no memory write and
returns with `A=$44`, `X=$05`, `Y` equal to the existing `$0704` value,
`C=1`, `Z=1`, and `N=0`. Flags not changed by the helper retain their incoming
values. The caller then resumes at `$EC05` in either case.

## Trace evidence and limits

The two-pass muted FCEUX trace
[`first_command_daaa_transition_20261029_051902_utc`](../../diagnostics/first_command_daaa_transition_20261029_051902_utc/metadata.txt)
uses the same ROM hash and records frames 8400-8472. Its hooks do not include
`$CBF1`, `$EC02`, or `$0700-$0704`; it cannot verify the queue contents or the
actual insertion index at the later countdown boundary. The `$052E/$052F/$063F`
values cited above are the current Godot live-route observation at `$EBD7`,
not a FCEUX CPU trace of `$CBF1`.

## Bounded runtime consumer

[`rom_slot09_cbf1_sound_queue_executor.gd`](../../../scripts/gameplay/rom_slot09_cbf1_sound_queue_executor.gd)
implements this helper as a bounded instruction consumer. It accepts only the
nested `source_cbf1_call` contract from the `$EBD7` root executor, verifies the
ROM identity, both source manifests, the `$EC02` JSR frame, full RAM and stack
pages, mapper banks, matching A/`$052F`, `$052F<$7E`, `$063F.7=0`, and the
caller flags derived from `CMP #$7E` plus `BIT $063F`. The
consumer manifest
[`slot09_cbf1_sound_queue/manifest.json`](slot09_cbf1_sound_queue/manifest.json)
points to the existing extracted bytes rather than duplicating them.

The consumer records queue reads in source order, writes the caller's A value
only to the first zero slot (or reports a full queue without writes), models the helper
RTS to `$EC05`, and returns full RAM/stack/register state. The call's JSR stack
writes are carried separately as entry effects; the helper itself performs no
stack writes. It does not consume the queue, write APU registers, or claim
audible output. It has no runtime ROM dependency.

`RomSlot09Ebd7RootZeroCounterExecutor` now emits this nested call and helper
result for the checked counter-one branch, then resumes at `$EC05` and reaches
the next root `$EB88->$CB0F` call. Its focused verifier copies the actual route
result and changes only `$052E` from zero to one to cover this branch. That is
branch-coverage evidence, not proof the production route reaches the helper.

The executor's exact bounded transition contract is:

| Boundary | `$052E` | `$052F` | `$063F` | CPU / queue effect |
| --- | ---: | ---: | ---: | --- |
| Root entry `$EBD7` | `$01` | request A, `<$7E` | bit 7 clear | Root entry A=`$00`, SP=`$7A`; mapper `$18/$19`. |
| Helper entry `$CBF1` | `$00` | unchanged; A=`$052F` | unchanged | Root executes `CMP #$7E`, `BIT $063F`, BPL, then `JSR $CBF1`; X/Y are preserved from `$EBD7`. JSR pushes `$EC04` at `$0179/$017A`, SP=`$78`. C=0, N=0, V=`$063F.6`, Z=`(A & $063F)==0`. |
| Helper return `$EC05` | `$00` | unchanged | unchanged | First empty queue index `j`: exactly one ordered write `$0700+j=A`; returns with A unchanged, X=`j`, Y=`$00`. Full queue: no write; X=`$05`, Y is the old `$0704` value. The helper RTS restores SP=`$7A`. |
| Next root yield `$CB0F` | `$00` | unchanged | unchanged | `$EC05->$EB86` loads A=`$01`; root calls `$CB0F` from `$EB88` with post-helper X/Y and a fresh outer JSR frame. The returned root result records the final yield request and the nested queue writes separately. |

The current branch-coverage fixture has `$052F=$00` and `$063F=$00`; it
therefore exercises the valid zero-valued request (the ROM still executes
`STA` at the first empty slot). The actual production route currently arrives
at `$EBD7` with `$052E=$00`, so none of these counter-one boundaries has yet
been observed live. The scheduler consumer still rejects `$052E=$01`, does
not yet adopt the nested `$0700-$0704` write, and expects X/Y to be preserved
from root entry; these route-integration items remain pending.

The route-fed focused verifier
[`verify_rom_slot09_cbf1_sound_queue.gd`](../../../tools/diagnostics/verify_rom_slot09_cbf1_sound_queue.gd)
replays the recorded post-title input route and searches for the actual
root-produced `source_cbf1_call` plus `cbf1_helper_result`. It does not inject
a synthetic endpoint. It remains expected to stop before the counter-one path
while the current route reaches `$EBD7` with `$052E=$00`. Queue consumption,
PPU/APU delivery, and audible output remain outside this audit.

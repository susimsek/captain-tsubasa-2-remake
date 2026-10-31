# Slot-$05 `$CB0F` save and next scheduler boundary — 2026-10-29

## Scope and evidence

This follow-up starts from the live slot-$05 worker state adopted at `$C515`.
It applies the ROM-checked yield-save semantics, continues the fixed-bank task
scan, and stops at the next selected task before dispatching it. It does not
advance the caller-supplied NMI sequence or execute slot-$09's body.

The supplied Turkish ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. The
worker result is bound to
`reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json`,
SHA-256
`bc26416684826e4e5831acbcd82ee973332a46d4fcf4e4cc0f330ffa8e8378e2`.
The scheduler's source manifest binds the yield trampoline `$C515` to file
offset `0x03C525`, bytes `4C 0F CB`, SHA-256
`86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e`;
`$CB0F` maps to offset `0x03CB1F`, length 30, bytes
`85 7F 8A 48 98 48 A6 00 A5 24 95 02 A5 25 95 03 A5 7F 95 00 8A A8 BA 96 01 A6 00 4C A5 CA`,
SHA-256 `b6377644890b9cd6671e4e63f48da4dfe1bd4975870bb531cb684ee7aeda07fc`.
The ordered scan span `$CA97-$CAE6` is independently hash-checked in
`reference/rom_extract/gameplay/task_context/manifest.json`.

The ROM worker executes its source bytes through `$C515`. The production
scheduler then applies the bounded `$CB0F` save and `$CAA5` scan model against
that live state; the save/scan segment is not a general opcode-by-opcode 6502
execution or cycle-timing model. The handler's source bytes and call/stack
contract are checked before applying its documented writes.

## Live save result

The second caller-supplied NMI route selects slot `$05` at `$8889`; its
source-byte worker reaches `$C515` with `A=$01`, `X=$00`, `Y=$05`,
`SP=$48`, banks `$18/$19`. The `$8886 JSR $C515` return word is already on the
worker-produced stack and is validated by the scheduler. It is not pushed
again.

The checked `$CB0F` handler writes `$01` to `$007F`, pushes the live X and Y
values, stores the current mapper pair and resulting SP into slot `$05`, then
jumps to `$CAA5`. The resulting task record is `01 46 18 19`; saved SP is
`$46`. The handler's stack writes and RAM effects match the worker output plus
these source-prescribed changes.

## Next selected task

The scan starts at the slot after `$05`, namely `$09`. Its saved delay is `$01`,
so the ROM scan's finite-delay path decrements `$0009` to `$00` and selects the
existing yielded slot-$09 context. The scan checks only slot `$09` before
returning `YIELDED_RESUME`, with cursor `$09`.

The route stops before dispatch. Slot `$09` remains yielded with
`pending_resume=YIELDED_TASK`, saved record `00 76 18 19`, and context PC
`$CB0F`; the scheduler has not restored its stack or resumed its root return at
`$EB8B`. No third NMI, task body, PPU application, or synthesized cadence is
performed.

## Focused verification

Run:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_slot05_f0_worker_boundary.gd
```

The check passed. It confirms worker coverage of 1,152 instructions, 23 calls,
277 ordered RAM writes, and zero mapper writes; the `$CB0F` result record is
`01 46 18 19`; the scan changes only `$0009:01->00`; and slot `$09` is selected
at the yielded pre-dispatch boundary. The focused route verifier also passed:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_slot05_second_nmi_worker_resume.gd
```

## Next consumer contract

The next bounded consumer may dispatch the already-selected yielded slot `$09`
from its saved RAM/stack/bank state and stop at the restored `$EB8B` caller
boundary. It must not execute the unsupported nonzero `$0516/$05D2` or
`$052E` paths, provide an extra NMI, or use trace RAM as runtime input.

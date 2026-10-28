# First-command slot-$0001 wait-call trace — 2026-10-28

## Source and method

This diagnostic-only trace identifies the ROM callsites that yield task slot
`$0001` during the fresh-start KICK OFF route. The supplied Turkish ROM hash is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

FCEUX 2.7.0 ran NTSC/NewPPU with audio muted. The runner followed the recorded
opening and route inputs once to source frame 8399, saved an anonymous
in-memory state, and loaded it for both frame-8400–8953 passes. Each load was
checked against frame/cycle, all 2 KiB RAM, all 16 KiB PPU memory, MMC3
registers, and mapped PRG bytes. No numbered user slot was used. The completed
trace and validation are under
[`first_command_task_wait_calls_20261028_080139_utc/`](../../diagnostics/first_command_task_wait_calls_20261028_080139_utc/).

The added hook records bank-$00 `$9FA8` only when `$0000=$01`, including A/X/Y,
SP, the full stack page, task record, scenario cursor, and mapper state. Both
passes contain 6,139 selected events and 62,357 watched writes. Their normalized
event SHA-256 is
`3c4e42c075363bb5666ac730a553c71d864a22c5ddcda144ab71a2c79ba66fe0`; their
write SHA-256 is unchanged from the earlier task trace:
`c639dfb47435a5706c92cf16a7316947445ac03d4887ee1b26dbbedbd1a8dd22`.
FCEUX exited `-11` during shutdown after both complete files were written; the
runner accepted the output only after both pass hashes matched and both
checkpoint signatures verified.

## ROM behavior measured in the trace

The ROM shows two consecutive source callsites, each passing a one-tick delay
to `$9FA8`:

| Frames | Calls | ROM caller | Source bytes before call | Observed A / X / Y / SP |
|---|---:|---:|---|---|
| 8400–8442 | 43 | bank `$00:$82B7` | `$82B5: A9 01 20 A8 9F` | `$01 / $01 / $00 / $24` |
| 8443–8457 | 15 | bank `$00:$9A06` | `$9A04: A9 01 20 A8 9F` | `$01 / $23 / $20 / $20` |

The callsite was recovered from the JSR return bytes on the emulated 6502 stack.
At frame 8400, the independent task-boundary trace records `$0001`'s ready byte
decrementing `$01→$00` at PC-after-write `$9EF9`, cycle 3519. The new hook sees
the `$82B7` call to `$9FA8` at cycle 3681; the wait helper later writes
`$0001: $00→$01` at PC-after-write `$9FE2`, cycle 3780. This `$01→$00→$01`
wait pattern repeats across the two callsite ranges in both passes.

In bank `$00`, `$9FA8` begins with `STA $19`, saving the caller's requested
delay. The helper saves task context and later stores the delay into the
current task record at `$9FE0` before jumping back to the scheduler at `$9FE2`.
The scheduler decrement is the ROM instruction at `$9EF7` (`DEC $00,X`); FCEUX
reports its following PC `$9EF9`. The two JSR instruction spans, wait helper,
counter decrement, and task-record store are checked by
[`verify_first_command_task_wait_calls_trace.py`](../../../tools/diagnostics/verify_first_command_task_wait_calls_trace.py).

## Boundary

This explains how the already-running slot `$0001` yields one source tick at a
time during frames 8400–8457. It does not prove which route event first enters
the `$C720–$C765` three-task bootstrap, reconstruct the slot's pre-frame-8399
context, or model its full continuation and shared stack in Godot. The frame
8460 seed of slots `$0001/$0005/$0009` remains a separate ROM source path.
Callback/task execution, field actors, the initial command-menu composition,
and full-route PCM parity remain unimplemented or unverified in the runtime.

## Reproduction

Run the muted, checkpointed two-pass capture with:

```sh
python3 tools/diagnostics/run_first_command_task_wait_calls_trace.py
```

Then verify the source callsites and retained results with:

```sh
python3 tools/diagnostics/verify_first_command_task_wait_calls_trace.py reference/diagnostics/first_command_task_wait_calls_20261028_080139_utc
```

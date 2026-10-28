# Fresh KICK OFF slot-$05 entry context trace — 2026-10-28

## Result

A muted, signature-checked FCEUX replay from the anonymous frame-4692
checkpoint confirms the source-produced inputs seen by the first slot-$05
`$D11E` dispatch. Two passes match in their normalized event and memory-access
logs. The checkpoint is immediately before the frame-4693 KICK OFF input; it
was persisted before both loads, and no numbered save slots or RAM injection
were used.

| Source event | Observed source result | ROM derivation |
|---|---|---|
| Bank `$02:$A86E`, frame 7258 | Reads `$0026=$00` | Fresh match index is zero; `$A86E-$A8CD` selects the match-zero roster. |
| Bank `$02:$A8B6`, frame 7266 | Writes `$002B=$03` | `$A8AF-$A8B6` computes `$0026 + 3`; see the [match-zero source audit](fresh_kickoff_position_context/source_audit.md). |
| Bank `$00:$8105`, frame 7266 | Writes `$0027=$00` | The post-cutscene new-game path loads zero at `$80FD` and stores it to `$0027` at `$8105`; see the [`$0629` selector audit](fresh_kickoff_0629_selector_source_audit_20261028.md). |
| Fixed-bank `$D11E`, frame 8460 | Current task slot `$05`; PC `$D11E`; CPU SP `$52`; `$0026/$0027/$002B = $00/$00/$03` | The bootstrap, slot-`$01` first yield, and slot-`$05` dispatch are modeled from preserved scheduler bytes by `RomGameplayTaskScheduler`. |

The trace runner now asserts independently for both passes that no `$0026`
write occurs anywhere in the captured interval, in addition to checking the
source writer for `$002B`, the source writer for `$0027`, and values at
`$D11E`. The reset-to-frame-4692 origin is not dynamically captured by this
trace: the separate [cold-RAM/reset source audit](fresh_kickoff_position_context/source_audit.md)
derives the initial zeroing from ROM bytes. The checkpoint's RAM signature is
used only to validate the replay, never as a runtime input.

Trace artifacts and hashes are under
[`reference/diagnostics/fresh_kickoff_entry_context_20261028_134613_utc/`](../../diagnostics/fresh_kickoff_entry_context_20261028_134613_utc/).
The runner is
[`run_fresh_kickoff_entry_context_trace.py`](../../../tools/diagnostics/run_fresh_kickoff_entry_context_trace.py);
the Lua hook is
[`trace_fresh_kickoff_entry_context.lua`](../../../tools/diagnostics/trace_fresh_kickoff_entry_context.lua).
The replay used the supplied ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, muted
FCEUX 2.7.0 NTSC/NewPPU, and the recorded opening/post-title input timelines.

## Implementation boundary

This evidence is sufficient to implement a small typed *source-context
builder*: derive match index from the fresh-start selector path, period from
the ROM's `$80FD` load/store sequence, opponent as `match_index + 3` from
`$A8AF-$A8B6`, and slot/PC/SP from the scheduler dispatch result. The trace
values above must remain validation assertions, not builder defaults or
runtime operands.

The typed builder is implemented in
[`rom_fresh_kickoff_entry_context_builder.gd`](../../../scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd)
with its result contract in
[`rom_fresh_kickoff_entry_context.gd`](../../../scripts/gameplay/rom_fresh_kickoff_entry_context.gd).
It verifies packaged reset/title/selector bytes, derives the three match
inputs from those bytes, and gets slot/PC/SP by running the existing bounded
scheduler projection through slot `$01`'s first yield and slot `$05`
dispatch. The route consumes this object at its existing cutscene-2 return
fold. That source-order fold does not model exact ROM scheduler/NMI timing or
make the route live-scheduled. No callback `$3A`, `$DAAA-$DAD8` continuation,
or scenario worker is executed by this trace. The focused comparison is
`godot --headless --path . --script tools/diagnostics/verify_rom_fresh_kickoff_entry_context_builder.gd`.

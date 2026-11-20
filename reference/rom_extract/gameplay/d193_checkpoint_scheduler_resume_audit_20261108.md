# D193 checkpoint scheduler-resume audit — 8 Nov 2026

## Result

The existing Godot-produced checkpoint validates at source frame 8855, with
slot-$05 dispatch provenance at `$E14A` and a worker boundary at bank-$1E
`$D193`. It cannot safely resume the production scheduler from that file. The
checkpoint stores the D193 worker result and its RAM/stack, but omits the
pre-worker `$E14A` state and the scheduler context that owns task records,
active-task state, ready latches, and scan position.

The new diagnostic
[`audit_d193_checkpoint_scheduler_resume.gd`](../../../tools/diagnostics/audit_d193_checkpoint_scheduler_resume.gd)
validated `/tmp/ct2_d193_e14a_checkpoint.json`, configured the production
scheduler without initializing it, and reported that no scheduler restore or
checkpoint-resume API is available. It deliberately attempted no worker or
scheduler transition and replayed no title frames. The audit completed in
7 ms. Because it did not reach a post-scheduler field-worker boundary, no
route-speed comparison is established.

## Why the scheduler cannot resume from this checkpoint

The checkpoint writer in
[`verify_kickoff_recorded_input_path.gd`](../../../tools/diagnostics/verify_kickoff_recorded_input_path.gd)
stores the dispatch identity, D193 worker output registers/mapper/RAM/stack,
and D193 instruction/call/span provenance. It does not serialize the live
`$E14A` worker input or a scheduler snapshot.

Production
[`adopt_slot05_clock_tick_renderer_handoff`](../../../scripts/gameplay/rom_gameplay_task_scheduler.gd)
requires an already initialized scheduler with slot `$05` active and running
at `$E14A`; its internal RAM and stack must match the live `$E14A` boundary.
That method adopts validated source writes and marks the `$CB0F` yield in the
active task context. The production route runner then saves the task at the
verified callsite, scans the ready queue, and dispatches the next task. The
checkpoint does not contain the scheduler state required for those operations,
and the production API exposes no restore path that rebuilds it from the
checkpoint.

The existing
[`verify_d193_godot_checkpoint.gd`](../../../tools/diagnostics/verify_d193_godot_checkpoint.gd)
can run the ROM-byte D193 worker directly from the checkpoint through the
`$EF7F->$800C->$C515->$CB0F` handoff. Its own result contract leaves the
post-`$CB0F` scheduler save/rescan and return to `$E1F1` unexecuted, so it does
not establish the requested production scheduler continuation.

To resume safely, the checkpoint flow needs a route-produced scheduler
snapshot at the `$E14A` boundary, including the active slot-$05 task context,
task record, scheduler RAM/stack, ready latch and scan position, together with
a production restore API that validates and adopts that snapshot. This audit
does not fabricate those values or bypass scheduler preconditions.

## Verification performed

Command:

```sh
godot --headless --path . --script tools/diagnostics/audit_d193_checkpoint_scheduler_resume.gd
```

Observed output:

```text
CHECKPOINT VALID: frame=8855, slot-$05 dispatch=$E14A, worker boundary=$D193 bank=$1E
BLOCKED: checkpoint lacks scheduler/E14A resume state; production scheduler remains uninitialized.
No scheduler transition or worker replay attempted.
```

The diagnostic checked the checkpoint’s ROM and input-trace hashes, D193
boundary, E14A dispatch receipt, RAM/stack hashes, and mirrored stack page. It
used no FCEUX state, no hand-authored RAM, and no title-route replay. The JSON
audit output is `/tmp/ct2_d193_checkpoint_scheduler_resume_audit.json`.

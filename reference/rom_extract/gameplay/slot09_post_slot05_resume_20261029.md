# Slot-$09 resume after the slot-$05 save — 2026-10-29

## Result

The source-route runner now consumes the live slot-$09 pre-dispatch boundary
selected by `resume_selected_slot05_worker()`. It restores that exact scheduler
context, follows the already hash-checked slot-$09 prefix and zero-branch
executors through `$EB88->$CB0F`, applies the task save, and stops at the next
scheduler boundary. This pass ends at `WAIT_FOR_NMI_READY`; it does not execute
another task body or synthesize an NMI.

The public runner status now exposes `pending_selected_task_slot` and
`pending_selected_task_boundary_pc`, allowing callers to select a supported
continuation without inspecting private fields. Resume is gated by those stored
fields and a full comparison with the scheduler's live task boundary, including
registers, mapper banks, record bytes, RAM, and stack.

## Live entry and register contract

The boundary produced after the slot-$05 `$C515` save and scheduler scan is:

| Field | Value |
| --- | --- |
| Slot / phase | `$09` / yielded (`3`) |
| Ready delay / pending resume | `$00` / yielded task (`2`) |
| PC / active task | `$CB0F` / none (`-1`) |
| Record | `00 76 18 19` |
| Saved banks | `$18/$19` |
| RAM / stack supplied | Full `$0800` bytes / full `$0100` bytes |

The source scheduler dispatch restores PC `$EB8B`, A/X/Y=`$00/$00/$05`,
SP=`$7A`, and banks `$18/$19`. The saved stack bytes at `$0176-$017A` are
`00 05 00 8A EB`; the live mapper selection is `$07`. These values come from
the slot-$05 worker result and slot-$09 scheduler record, not from trace-state
injection.

This is a distinct exact resume signature from the bootstrap profile already
accepted by the prefix executor. Bootstrap uses banks `$00/$01`, record
`00 76 00 01`, and A/X=`$78/$78`; the post-slot-$05 loop uses banks `$18/$19`,
record `00 76 18 19`, and A/X=`$00/$00`. The prefix validates each profile as
a complete matching tuple, including the saved X byte on the stack.

## Source calls, returns, and route

The slot-$09 `$EB8B` prefix consumes these hash-checked call/return pairs:

| Caller | Target | Return | Return source |
| --- | --- | --- | --- |
| `$EB9B` | `$EC08` | `$EB9E` | `$EC0F RTS` |
| `$EB9E` | `$ED85` | `$EBA1` | `$ED8A RTS` |
| `$EBAC` | `$CE2D` | `$EBAF` | `$CE49 RTS` |
| `$EBB0` | `$8003` in bank `$18` | `$EBB3` | `$8003` vector jumps to `$86F8`; worker return is consumed by the next executor |

The live zero-branch chain then has these return boundaries:

1. `$86F8` sees `$0532=$00` and returns to `$EBB3`.
2. The caller invokes `$8779`; its `$0534=$00` path returns to `$EBC5`.
3. The caller invokes `$87E6`; its `$0536=$00` path returns to `$EBD7`.
4. `$EBD7` sees `$052E=$00`, branches through `$EC05->$EB86`, executes
   `LDA #$01` at `$EB86`, and reaches `$EB88 JSR $CB0F`.
5. The checked `$CB0F` save records slot `$09` as `01 76 18 19`, saves
   Y/X=`$05/$00`, and preserves the `$EB8A` return word so the resume PC is
   `$EB8B`.

After the save, the source scheduler checks empty slots `$0D/$11/$15`, leaves
the ready latch `$001B` clear, and stops with scan cursor `$19` at
`WAIT_FOR_NMI_READY`. The next boundary is an externally supplied NMI; this
increment does not model its cadence or service it.

## Source provenance and verification

All source bytes are reused from existing hash-checked packages; this change
adds no byte spans or manifests. Target ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

- [Slot-$09 `$EB8B` continuation source](slot09_eb8b_continuation/manifest.json)
  and its [audit](slot09_eb8b_continuation_audit_20261029.md).
- [Slot-$09 `$86F8` worker source](slot09_86f8_worker/manifest.json) and
  [zero-branch audit](slot09_86f8_worker_audit_20261029.md).
- [Slot-$09 `$8779` worker source](slot09_8779_worker/manifest.json) and
  [zero-branch audit](slot09_8779_worker_audit_20261029.md).
- [Slot-$09 `$87E6` worker source](slot09_87e6_worker/manifest.json) and
  [zero-branch audit](slot09_87e6_worker_audit_20261029.md).
- [Slot-$09 `$EBD7` root checks](slot09_ebd7_root_checks/manifest.json) and
  [root-loop audit](slot09_ebd7_root_checks_20261029.md).
- [Slot-$09 `$CB0F` save and scheduler scan](slot09_cb0f_scheduler_save_20261029.md).

Focused verifier:
[`verify_rom_slot09_post_slot05_resume.gd`](../../../tools/diagnostics/verify_rom_slot09_post_slot05_resume.gd)

```text
godot --headless --path . --script res://tools/diagnostics/verify_rom_slot09_post_slot05_resume.gd
```

Result: PASS on Godot 4.7.2. The verifier checked the slot-$05-produced
boundary, exact slot-$09 dispatch registers and banks, all source returns,
the `$CB0F` save, and the following scheduler wait. A negative case changed
the stored pending PC and confirmed rejection before task dispatch.

## Limits

The runner does not execute a later task body, generate an NMI, apply PPU bus
events, render visible output, or enter another match flow. `KickoffRouteRuntime`
was not modified or connected by this increment. This is a ROM-byte source-route
diagnostic component, not a claim of visible or audio parity and not evidence of
physical NES timing. The first command menu is still not reached by this
increment.

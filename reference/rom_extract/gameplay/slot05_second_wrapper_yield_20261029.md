# Slot-$05 second wrapper yield — 2026-10-29

## Result

The live source route now executes the first slot-$05 worker return through
`$EF99->$CE2D->$DACC`, enters the second wrapper at `$DACE->$EF7F->$EF96->$800C`,
and reaches its `$C515` yield. The existing route runner adopts that worker
result and saves it through the scheduler. It does not yet reach the caller at
`$DAD1` or enqueue scenario `$35`.

The next source-dispatched slot-$05 continuation stops before its read at
`$89A0`, where the second match descriptor points to bank-$19 text `$BBE0`.
The live RTS frame still contains return-minus-one `$DAD0` at stack bytes
`$014F-$0150`, so the pending return destination is `$DAD1`; this is a stack
fact, not an executed program counter.

## Evidence and verification

ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

Worker source manifest SHA-256:
`bc26416684826e4e5831acbcd82ee973332a46d4fcf4e4cc0f330ffa8e8378e2`.

Focused verifier:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_rom_slot05_second_wrapper_yield.gd
```

It passed. It creates the fresh route context from project sources, supplies
four explicit external NMI edges, runs the existing source scheduler, and checks
the second-wrapper worker yield plus the next missing source read. No FCEUX run,
trace RAM, screenshot, video, or captured audio is used as runtime input.

New non-overlapping source spans are listed in
[`slot05_second_wrapper_return_20261029/manifest.json`](slot05_second_wrapper_return_20261029/manifest.json).
They include the wrapper tail `$EF99-$EFA1`, the caller `$DACC-$DAD0`, the
predicate `$DAD1-$DAD7`, the next lookup pointer `$B3D1-$B3D2`, and its
selected descriptor `$B464-$B474`. Existing mapper-helper, `$DAD8` caller, and
`$CBB0` spans are referenced from their earlier hash-checked packages.

## Live source state

At the first wrapper return, the source-produced `$EF99` stack has the return
word `$DACB`; the mapper helper returns to `$DACC`. The caller loads `A=$01`
and calls the second `$EF7F` wrapper. That wrapper maps banks `$18/$19` and
calls `$800C`. The worker result reaches `$C515` with `A/X/Y=$01/$FF/$00`,
`SP=$48`, and mapper banks `$18/$19`; the route then saves the slot-$05 task
and selects slot `$09`.

The second worker lookup uses `$B3D1-$B3D2 = $64 $B4`, selecting descriptor
`$B464`. Its descriptor contains text pointer `$BBE0`. After the existing
slot-$09 transition and another caller-supplied NMI, slot `$05` resumes with
`A/X/Y=$00/$00/$00`, `SP=$46`, banks `$18/$19`, `$0629=$00`, and `$0515=$01`.
It stops at `$89A0` because bank-$19 `$BBE0` is not yet in the worker package.

## Remaining boundary

The next required runtime input is the selected text row beginning at `$BBE0`
and the control handler that its first token selects. Until that source path is
implemented, `$DAD1` remains only the pending stack return destination. The
`$0629` comparison, its fresh zero branch, `$DAD8->$DADA`, `$CBB0` writes
`$0518=$35` and `$0516=$80`, and the `$CB0F` save entry are not executed by this
route. No scenario parser or guessed callback state was added.

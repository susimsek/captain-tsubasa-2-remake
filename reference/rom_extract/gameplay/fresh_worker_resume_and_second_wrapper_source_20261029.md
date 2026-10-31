# Fresh worker resume and second wrapper source audit — 2026-10-29

## Evidence scope

This audit reads the supplied ROM bytes only; it does not run FCEUX or change
runtime code. ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
For the fixed `$C000-$FFFF` window, file offset is
`0x03C010 + (CPU address - 0xC000)`. For mapper bank `$18` at `$8000`, it is
`0x030010 + (CPU address - 0x8000)`. The linked manifests preserve and hash the
larger source spans.

## Worker resume predicate

The existing bank-$18 worker prefix ends at `$8889`, immediately after
`$8886: JSR $C515`; `$C515` jumps to `$CB0F`. The JSR stack word is
return-minus-one `$8888`, so an eventual task continuation returns to `$8889`.
The next ten ROM bytes are file offset `0x030899`, SHA-256
`c46324499488f3078e3435f393cf31aeabd1429a8cc5caea064dee11102714f5`:

```text
$8889: AD 15 05    LDA $0515
$888C: D0 F6       BNE $8884
$888E: A9 01       LDA #$01
$8890: 8D 15 05    STA $0515
```

After scheduler resumption, the worker checks `$0515`. If it is nonzero, the
branch repeats the worker's `$8884-$8886` yield sequence. If it is zero, the
worker sets it to one and proceeds. This proves a source-level wait predicate
and re-yield loop; these bytes alone do not identify the actor that clears the
flag, the number of iterations, or their timing. The existing
[`menu_renderer_algorithm_audit.md`](menus/first_action_menu/menu_renderer_algorithm_audit.md)
documents the related PPU transfer queue observations. The source NMI-ready
writer and scheduler consumer are documented in
[`first_command_root_task_bootstrap_and_nmi_20261028.md`](first_command_root_task_bootstrap_and_nmi_20261028.md);
that report explicitly leaves NMI delivery external to its model.

## Second `$EF7F` call and scenario-$35 caller

The fixed-bank span `$DACC-$DADC` is file offset `0x03DADC`, length 17, SHA-256
`ea94910661b9922365f53d7f77634f4cb71f13bf134f8e2e9350f670dce527e3`:

```text
$DACC: A9 01       LDA #$01
$DACE: 20 7F EF    JSR $EF7F
$DAD1: AD 29 06    LDA $0629
$DAD4: C9 04       CMP #$04
$DAD6: F0 11       BEQ $DAE9
$DAD8: A9 35       LDA #$35
$DADA: 20 B0 CB    JSR $CBB0
```

The second wrapper therefore receives A=`$01`. Its wrapper code and bank-$18
entry are already preserved in
[`fresh_daaa_continuation/manifest.json`](fresh_daaa_continuation/manifest.json)
and
[`fresh_bank18_worker_prefix/manifest.json`](fresh_bank18_worker_prefix/manifest.json).
If that worker completes, the caller resumes at `$DAD1`. On the source-derived
fresh route `$0629=0`, so the `$DAD6` equality branch is not taken and execution
reaches `$DADA: JSR $CBB0`.

The existing scenario-task package preserves `$DAD8` through `$DADC` at file
offset `0x03DAE8`, bytes `A9 35 20 B0 CB`, SHA-256
`334e25e61f3fa69e4c51961948c06c802993d03dbf9dc2c77b1cb471d857afd5`. Thus
`$DAD8` is the caller start and scenario literal, `$DAD9` is the literal byte,
and the actual enqueue/setup `JSR $CBB0` begins at `$DADA`. `$CBB0` stores `$35`
at `$0518`, writes `$80` to `$0516`, clears `$0005`, and yields at
`$CBBE: JSR $CB0F`; the routine bytes are in
[`scenario_task_runtime/manifest.json`](scenario_task_runtime/manifest.json).

## Resumed zero-flag worker: first dynamic text/control dispatch

The bounded Godot worker-resume executor accepts the source-dispatched slot-$05
continuation at bank `$18:$8889`. It reaches the `$0515!=0` re-yield at `$C515`.
With `$0515==0`, it source-executes the fixed `$C509->$CB99` inline-pointer
trampoline, `$EF->$8B48` handler, character conversion/buffer helpers, the
`$FC->$8C52` callback return, and the shared menu-window table read. It writes
`$0515=$80`, updates `$05C5=$02`, and emits the exact first two transfer
packets at `$04A5`:

```text
07 21 22 00 00 00 00 00 00 00
07 41 22 9C A8 20 34 2E A8 9D
```

The worker then returns to its caller and yields at `$8886->$C515`. The focused
worker verifier checks the resulting RAM, stack return word, source-span
provenance, and packet bytes. These are packet-buffer writes, not visible
rendered pixels: the normal-NMI consumer and renderer-owned PPU memory have
not yet been connected to this live route.

The fresh match descriptor at bank `$19:$B453-$B463` (file offset
`0x033463`, 17 bytes, SHA-256
`145ca019b72334ff6445170111b03faf47927b77535c3448d36a066417f192c4`)
contains the little-endian text pointer `$BBDC` in bytes `$B45E-$B45F` (`DC
BB`). The resumed worker sets the pointer at `$8986-$899B` and reads it at
`$89A0: LDA ($3E),Y`; `$899D` is the operand of `$899C: LDY $40`, not an
instruction boundary. Bank `$19:$BBDC` is file offset `0x033BEC`; its preserved
first byte is `$EF` (SHA-256
`4d4d75d742863ab9656f3d5f76dff8589c3922e95a24ea6812157ffe4aaa3b6b`).

Static mapping identifies `$C509: JMP $CB99` as the fixed-bank control
dispatcher. The `$EF` control selects bank-$18 worker target `$8B48` through
the inline table at `$89D8` (`48 8B`). This control path is now executed by the
bounded worker component, including its `$8B48` callback row and the `$FC`
return trampoline. It does not execute a general 6502 instruction set; only
the required source opcodes and bounded handler path are implemented.

## Limits and next source boundary

The production route now composes this worker result into the same scheduler
scan: slot `$05` yields at `$C515`, then slot `$09` is dispatched at `$EB8B`.
The next source continuation after `$EB8B` is not yet executed. The queue
consumer currently emits ordered `$2006/$2007` bus events but does not apply
them to renderer-owned PPU state; the live screen therefore does not yet prove
visible output from these packets. Retained FCEUX observations validate event
order only. Do not infer fixed frame delays or physical NES timing.

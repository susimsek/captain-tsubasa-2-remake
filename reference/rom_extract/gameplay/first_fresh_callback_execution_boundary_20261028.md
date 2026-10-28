# First fresh-route `$35/$3A` callback execution boundary — 2026-10-28

> **Context update:** The previously unresolved `$0027/$002B` inputs and the
> slot-$05 `$D11E` entry are now independently traced from a signature-checked
> frame-4692 checkpoint. See
> [`fresh_kickoff_entry_context_trace_20261028.md`](fresh_kickoff_entry_context_trace_20261028.md).
> This supersedes the statement below that those values lack a source-owned
> producer. It does not execute the `$DAAA-$DAD8` continuation or callback
> `$3A`; that boundary remains open.

## Result

The supplied ROM resolves the earliest fresh-start callback completely at the
data-selection level:

```text
scenario $35 at $B7CD: F9 EB 44 02 3A 8F 73 FB
event record +3:          02 3A 8F 73
callback pointer $3A:     $89F3
callback bytes:           02 00 42
handler vector index 0:   $8327
```

The current components do **not** execute this callback from live source-owned
task state. `RomFreshKickoffEntryContextBuilder` now derives match 0, period 0,
opponent 3 and the slot-$05 entry from checked reset/title/selector bytes plus
the bounded scheduler projection. `RomFreshPeriodTask` consumes that typed
context and executes the `$D11E` slice through `$DAAA`; this does not execute
the following helper chain or scenario `$35`. No callback task or trace-RAM
state is injected. Focused checks:
[`verify_rom_fresh_kickoff_entry_context_builder.gd`](../../../tools/diagnostics/verify_rom_fresh_kickoff_entry_context_builder.gd)
and
[`verify_first_fresh_callback_execution_boundary.gd`](../../../tools/diagnostics/verify_first_fresh_callback_execution_boundary.gd).

## Actual scheduler state reached by existing code

`RomGameplayTaskScheduler` validates packaged source bytes, derives the
fresh-game task records, dispatches slot `$01` to `$CA22`, and executes that
bounded instruction slice through its `$CA4F` yield. The next projected scan
dispatches slot `$05` at `$D11E`, SP `$52`; the muted trace independently
confirms those inputs and shows slot `$15` still empty. The typed entry-context
builder obtains `$0026/$0027/$002B = 0/0/3` from reset and ROM formulas and
passes them to `RomFreshPeriodTask`. That bounded byte runner reaches `$DAAA`
and produces its declared subset of RAM writes, but it is not a full CPU/task
execution and does not carry all live registers, stack, mapper state or NMI
cadence through the following fixed-bank caller.

## Exact remaining source chain

The actual scenario `$35` caller starts at `$DAD8` (fixed-bank file offset
`0x03DAE8`), with source bytes `A9 35 20 B0 CB`. It is reached only after the
slot-`$05` `$DAAA` continuation executes a chain of calls and state changes:

```text
$DAAA: A9 01 20 F1 CB 20 4F CF 48 A5 22 A9 1A 85 24
$DAB9: A9 1B 85 25 20 2D CE 68 20 39 80 20 24 DB
$DAC7: A9 00 20 7F EF A9 01 20 7F EF AD 29 06 C9 04
$DAD6: F0 11
$DAD8: A9 35 20 B0 CB
```

The source audit derives `$0629=0` on the fresh route, so the `$DAD6` branch
does not skip the `$DAD8` caller. However, the calls at `$DAAC`, `$DAAF`,
`$DABD`, `$DAC1`, `$DAC4`, `$DAC9`, and `$DACE` are not executed by the
current task runtime. The current `RomBank10ScenarioTaskRuntime` accepts
`$DAD8` as an explicit source-callsite argument and decodes the following
scenario bytes; that contract is useful for source inspection but is not proof
that the scheduler reached `$DAD8`.

The same distinction applies later to the bank-`$10` record setup at `$8097`.
The source record implies `$8097` setup operands and `$C50F→$CAE7` seed bytes,
but the existing callback seed executor accepts `$8097` as an argument and
does not derive it from a running scenario-reader task. It would mutate slot
`$15` if called with that argument, so the boundary verifier deliberately does
not call it. The first actual scheduler scan correctly selects slot `$01`.

The existing `RomFirstCommandCallbackDispatchApi` is scoped to the later
scenario `$44` / callback `$70` route. It does not execute callback `$3A`; the
separate `$3A` source component resolves its pointer and first operation but
explicitly stops before task dispatch.

## What can be implemented next

Continue from the bounded `$DAAA` result by executing the fixed-bank helper
calls while carrying the source-owned registers, flags, mapper pair, stack and
scheduler context. Only once this path emits a real `$DAD8` call event should
the scenario reader start `$35`, create slot `$15` from `$8097`, and let the scheduler dispatch
`$8009→$814C`. That dispatch can then consume the preserved `$3A` pointer and
`02 00 42` bytes through `$81A7→$8327`.

The source projection that separately computes `$05CD` from the `$AA06`
zero-fill routine is not callback execution and cannot stand in for these
events. Do not use trace frame numbers, captured RAM, endpoint fixtures, or a
direct `$8327` call to bridge this boundary.

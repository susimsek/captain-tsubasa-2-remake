# Fresh bank-$18 worker prefix boundary — 2026-10-28

## Implemented source slice

`RomFreshBank18WorkerPrefix` is a separate ROM-byte executor continuing from
the verified `RomFreshDaaaContinuation` state at bank `$18:$800C`. It executes
the bank-$18 entry trampoline (`JMP $8851`), the first worker's setup bytes,
its bank-$19 lookup reads, and the terminal `JSR $C515`. It stops when the
call target `$C515` becomes the PC; `$C515` itself is not executed. That fixed
ROM trampoline is the three-byte `JMP $CB0F`.

The packaged code and data are independently hash-checked against the supplied
ROM in [`fresh_bank18_worker_prefix/manifest.json`](fresh_bank18_worker_prefix/manifest.json).
The executor carries A/X/Y/P, the full internal RAM image, stack page and SP,
mapper selector and bank pair, and ordered writes. It receives only the
previous ROM-byte executor's result; it does not seed or read emulator values.

The source bytes establish these addresses precisely:

- `$800C`: `JMP $8851`
- `$8884`: `LDA #$01`
- `$8886-$8888`: `JSR $C515`
- JSR pushes return-minus-one `$8888`; a later RTS would resume at `$8889`
- `$C515`: `JMP $CB0F`, the cooperative task-yield handler entry

## Composed `$CB0F` save boundary

The task scheduler now accepts the actual bank-$18 `$8886: JSR $C515`
callsite. Its source bytes are separately preserved and hash-checked in
[`task_context/manifest.json`](task_context/manifest.json), in addition to
the larger worker span: bank-$18 CPU `$8886`, ROM file offset `0x030896`,
bytes `20 15 C5`. They can be re-extracted and hash-checked with
[`extract_rom_worker_yield_callsite.py`](../../../tools/diagnostics/extract_rom_worker_yield_callsite.py).
The bridge accepts only the byte executor's
hash-identified `$C515` result for the already-dispatched slot-$05 task; it
copies that source result's live stack window and CPU/mapper fields without
replacing other scheduler RAM or task records.

The scheduler now has a bounded, one-shot delta merge for the executed source
path from `$D11E` through `$C515`. It applies the three ordered write lists
from the period task (9 writes), `$DAAA` continuation (287), and worker prefix
(7) in that order. It never copies either executor's partial full-RAM image;
it rejects writes to active-slot pointer `$0000`, task-record bytes for slots
`$01/$05/$09/$0D/$11/$15`, or NMI-ready latch `$001B`. Page-$01 writes update
both the internal-RAM image and scheduler stack mirror. The focused verifier
checks the 303 writes' touched-byte results against the final ROM-byte worker
state, confirms scheduler records and `$001B` remain intact, and compares the
continuation/worker write streams with both retained muted FCEUX passes.

This is still a route-local delta, not a complete live RAM image: unmodified
locations retain the scheduler's current values, while earlier route events
before `$D11E` have not been source-executed into this scheduler instance. The
nine period-task writes are executed from ROM bytes and merged, but the
frame-8399 DAAA trace starts after those writes, so they are not individually
compared with that trace's writer rows. The existing broader task trace keeps
the observed slot-$05 context and `$C515` endpoint as validation evidence; it
does not supply missing runtime RAM.

At `$C515`, the worker has already pushed the `$8888` return-minus-one word
and has SP `$48`. The scheduler's yield handler therefore validates the
existing JSR frame and applies only `$CB0F`'s X/Y stack pushes, `$007F` staging
write, task record save, and post-yield cursor update. This avoids duplicating
the JSR stack writes. The source-derived record is `01 46 18 19`; the saved
stack window `$0147-$0150` is `00 FF 88 88 98 EF 1D 1C CB DA`.

The focused verifier derives the slot-$01 startup yield and slot-$05 initial
dispatch from the task scheduler, executes the existing fresh-period,
`$DAAA` continuation, and bank-$18 worker byte runners, then applies the
`$CB0F` save. It compares the pre-save `$C515/$CB0F` register/mapper/stack
boundary and post-save slot-$05 record/stack effects against both retained
muted FCEUX passes. FCEUX rows select validation evidence only; they do not
seed execution state. In both retained passes the `$C515` event is at frame
8460 / cycle offset 27552, and `$CB0F` begins at cycle offset 27555.

Run:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_fresh_worker_yield_scheduler_bridge.gd
```

## Previous focused verification

Run:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_fresh_bank18_worker_prefix.gd
```

The check passes on Godot 4.7.2. It first derives `$800C` from the context,
fresh-period task, and preceding continuation source components, then executes
the worker prefix. It compares the result with both retained muted FCEUX task
trace passes at the `$C515` boundary. CPU state is A/X/Y=`$01/$FF/$00`,
P=`$20`, SP=`$48`; mapper remains `$18/$19/$1E/$1F`; the stack bytes above SP
are `88 88 98 EF 1D 1C CB DA`. The check also compares the source callsite,
task record, selected RAM values, and ordered internal-RAM writes through the
boundary. Trace frame/cycle values select the validation row only; they are
not executor inputs or runtime timing constants.

## Exact next boundary

The composed source slice now stops after the slot-$05 `$CB0F` save and its
cursor update. It deliberately does not perform the next scheduler scan,
synthesize an NMI-ready edge, or resume the worker. The next source/runtime
boundary is deriving earlier route RAM state that the current bounded delta
leaves untouched, then deriving the required NMI delivery and later scheduler
scan from the source-owned PPU/task event path before resuming the saved
continuation;
the second `$EF7F` worker and later scenario-$35 enqueue remain beyond this
slice. No frame delay is inferred from the retained trace.

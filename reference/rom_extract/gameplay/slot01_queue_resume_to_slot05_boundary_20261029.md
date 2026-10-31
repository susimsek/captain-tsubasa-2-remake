# Slot-$01 Resume After Queue NMI — 2026-10-29

## Result

The production source route was continued from its slot-$09 scheduler wait
with exactly one caller-supplied normal NMI. The live `$0515/$04A5` queue was
validated against the source-owned pending snapshot before service. The
normal-NMI consumer returned 20 ordered PPU bus events, then the scheduler
selected slot `$01` at `$CA52`. Its supported empty-actor and no-direction
continuation ran from the task's live RAM and stack. The route saved slot
`$01` at `$CB0F`, scanned again, and stopped at slot `$05`'s yielded
pre-dispatch boundary at `$CB0F`; it did not execute the next task body or
apply bus events to a renderer.

The caller-supplied NMI label was `5`. It is a sequence label, not a measured
frame edge, cadence, beam position, or CPU/PPU timing result.

## Queue and live slot-$01 input

At the slot-$09 wait, the runner's pending queue signature matched live
scheduler RAM:

| State | Value |
| --- | --- |
| `$001B` | `$00` — normal NMI mode |
| `$0498` | `$00` — primary queue empty |
| `$0515` before NMI | `$80` — secondary queue ready |
| `$04A5[0..19]` | `07 C1 22 9C A8 A8 A8 A8 A8 9D 07 E1 22 AA 53 41 4F 00 33 AB` |
| `$0515` after NMI | `$00` |

The first packet targets `$22C1` and writes `9C A8 A8 A8 A8 A8 9D`; the
second targets `$22E1` and writes `AA 53 41 4F 00 33 AB`. The event list
contains the source-ordered `$2002`, `$2006`, and `$2007` bus operations for
both packets, 20 events total. These events remain unapplied.

The scheduler selected slot `$01` with record `00 26 00 01` and restored this
call context:

| Input | Value |
| --- | --- |
| A / X / Y / SP | `$00 / $00 / $00 / $2A` |
| PC | `$CA52` |
| Task banks | `$00 / $01` |
| Stack bytes `$0127-$012B` | `00 00 51 CA 00` |
| `$05FB` | `$00` — fresh-match path |
| `$001C & $0F` | `$00` — no directional input |
| Actor flags at `$0547/$055C/$0571/$0586/$059B/$05B0` | all `$00` |

The `$EE9F` executor visited the six source-ordered actor records and took the
inactive branch for each. It returned to `$CA55`. The root caller then issued
`$CA55->$E3CA`; the `$05FB=0` and `$001C & $0F=0` source branches returned at
`$CA58` without applying movement. The root loop yielded through its
`$CA4F->$CB0F` callsite.

## Stop boundary

The scheduler saved slot `$01` as record `01 26 00 01` at `$CB0F`. Its next
source scan selected slot `$05` as record `00 46 18 19` at `$CB0F`, with no
active task. The verifier checks that the next boundary is a yielded resume
and confirms that no task body ran, no second NMI was generated, and the 20
PPU bus events were not applied to a visible renderer.

The route implementation services the NMI, selects slot `$01`, executes its
bounded continuation, and scans to the next task in one
`advance_on_external_nmi()` call. It does not expose a separate public method
that accepts an already-detached slot-$01 pre-dispatch snapshot. The focused
verification therefore reconstructs the authentic route from its preceding
source-owned slot-$09 wait, rather than injecting a boundary snapshot.

## Verification

Focused verifier:
[`verify_rom_slot01_resume_after_queue_nmi.gd`](../../../tools/diagnostics/verify_rom_slot01_resume_after_queue_nmi.gd)

Command:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_rom_slot01_resume_after_queue_nmi.gd
```

Result: PASS on Godot 4.7.2. The verifier reconstructs the preceding route
from project-owned, hash-checked ROM extracts, validates the live pending
queue, and invokes the production runner once with the next caller-labeled
NMI. No FCEUX trace RAM, captured image, or emulator output is an input.

## Source and limits

The ROM identity is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The root caller bytes and `$EE9F` source spans are documented in
[`slot01_second_nmi_root_cycle_20261029.md`](slot01_second_nmi_root_cycle_20261029.md);
normal-NMI queue bytes and transfer behavior are documented in
[`slot09_second_nmi_queue_delivery_20261029.md`](slot09_second_nmi_queue_delivery_20261029.md).
Their existing source manifests bind the runtime extracts to this ROM hash.

This confirms only the supported source transition and ordered bus-event
output. It does not establish physical NMI cadence, PPU register side effects,
visible field pixels, the next slot-$05 task body, command-menu output, or
audio fidelity.

The follow-up slot-$05 dispatch and its first unsupported source read are
documented in [the BBE3 source-gap report](slot05_after_slot01_bbe3_source_gap_20261029.md).

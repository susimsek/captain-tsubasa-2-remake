# Fresh KICK OFF audio-wait input provenance audit — 2026-10-29

## Historical source-only result; live inputs now verified

This audit predates the muted, repeated trace in
[the live wait and BGM report](fresh_kickoff_1b6_persistence_addendum_20261029.md).
That trace supplies the live `$001B/$78/$79/$3B` values, proves `I=0`, records
the NMI and IRQ writes, and observes `$895C RTS->$8117`. The unanswered item is
now Godot's ROM-owned interrupt/source-clock implementation, not trace input
provenance.

No frame-end RAM values were used as inputs. This audit used the supplied ROM
and existing checked source reports only; it did not use FCEUX. The bounded
source bytes for reset and documented `$001B.6` setter candidates are in
[`fresh_kickoff_audio_wait_inputs_20261029/manifest.json`](fresh_kickoff_audio_wait_inputs_20261029/manifest.json).
The NMI gate, `$C421` service, bank-$02 `$A000` handler, IRQ path, `$893B`
wait, and post-wait preset copy remain hash-bound in
[`fresh_kickoff_0078_wait_20261029/manifest.json`](fresh_kickoff_0078_wait_20261029/manifest.json).

## What the ROM proves

At `$893B`, the fresh-match prefix executes `LDA $78; BNE $893B`. The isolated
source-prefix result below has I set, but that is not the live route status: the
linked FCEUX trace enters with I clear, and the maskable IRQ does release its
wait.
The isolated, hash-checked `$8920` prefix reaches `$893B` with A/X/Y/P
`$87/$06/$00/$A4`, bank `$06` selected, and the original `$8114` JSR frame
still pending. These CPU/mapper effects are source-executed by that bounded
component; it neither owns the earlier cutscene/NMI history nor supplies the
four RAM inputs below.
The checked path is:

```text
$C76E BIT $1B; BVC $C775; JMP $C421   ; $001B.6 selects this path
$C421 BIT $3B; BMI $C472              ; $003B.7 skips the service if set
$C421 SEC; ROR $3B                    ; set the in-service guard
       map PRG bank $02 at $A000; JSR $A000
$A000 ... LDA $79; BEQ $A0A9
       $79 != 0: STA $78 with $04
$A0A9 ... LDA $00; STA $E000; STA $78
$C421 ... LSR $3B; RTI                 ; clear guard bit before return
```

Therefore, the `$C76E->$C421->$A000` path writes `$78=0` only when an NMI
reaches it with `$001B.6=1`, `$003B.7=0`, and the `$A000` test sees `$0079=0`.
If `$79` is nonzero, that path writes `$04` to `$78` instead. A previously
zero `$78` would release the busy wait without this NMI path, but its value at
the call site is also not established.

## Input provenance

| Input | ROM-backed initialization or writer | What this source-only audit knew at `$893B` |
| --- | --- | --- |
| `$0078` wait byte | Cold reset `$C64E-$C679` clears all 2 KiB CPU RAM. The normal-NMI PPU-queue consumer writes a queue address high byte to `$78` at `$C917`. The special NMI setup writes `$04` or `$00` from bank `$02:$A000`. The raster IRQ worker at `$A160` advances or clears `$78`. | Reset gives `$00` before route execution, but that is not a proof of the later value. The `$80E6` cutscene/Select-wait path and its NMI activity are not source-executed through `$8114`. The `$C8FB` writer is selected when `$001B.6` is clear and can repurpose `$78` as PPU-pointer scratch. |
| `$0079` raster selector | Cold reset clears it. The `$8920` prefix does not write it before `$893B`; its `$893F` copy writes the selected preset's first byte only after the wait. The bank-$02 `$A000` NMI handler reads `$79`. | The later preset record `$BF00` is zero-filled, but that cannot establish the pre-wait `$79`. No prior route-owned writer/result is available. |
| `$001B.6` NMI mode | Cold reset clears `$001B`; the later gameplay bootstrap `$C6E8` also clears it, but that bootstrap is downstream of this `$8114` call. Documented candidate setters are bank-$02 `$A21B` (`ORA #$40; STA $1B`) and indirect mode handler `$A5CE`. The latter is selected by `$A484` when `$00ED=9`. | No checked caller shows `$C41E->$A200->$A21B` executing on this fresh caller path. The three decoded KICK OFF cutscene streams contain no `$F8` command selecting the `$A5C0/$A5CE` dispatch, but this does not account for every caller or non-stream route transition. `$001B.6` is the first missing route-owned input. |
| `$003B.7` reentrancy guard | Cold reset clears `$003B`. `$C421` tests bit 7, sets it with `SEC; ROR $3B` when clear, and clears it with `LSR $3B` before its `RTI`. | The local handler behavior is source-derived. Its entry bit at the particular wait-time NMI is not supplied by a source-executed route; do not assume the guard is clear based only on reset. |

The live values are now established by the linked trace: `$001B/$78/$79/$3B`
are `$C0/$04/$40/$55` at `$8114`, and the IRQ clears `$78` before the real
`$8117` return. The table above is a historical static-audit snapshot.

### `$001B.6` setter candidates and callers

The new hash-bound candidate spans show these distinct paths:

- Fixed `$C41E` is `JMP $A200`; bank-$02 `$A200` immediately jumps to
  `$A21B`, whose body ORs `$40` into `$001B`. This identifies a possible
  setter, not its caller. Existing static analysis found no direct
  `$C410/$C411` target and did not establish the entry state/caller for
  `$C41E`.
- Bank-$02 `$A484` computes an indexed pointer from `$00ED` and dispatches
  through `$A491`. Entries 8 and 9 point to `$A5BF/$A5CD`, whose RTS dispatch
  enters `$A5C0` (clear bit 6) or `$A5CE` (set bit 6). The decoded KICK OFF
  scripts contain no `$F8` events, so the documented `$A5CE` route is not
  selected by those script streams. Its other possible callers remain
  unmapped.
- `$C6E8`'s `LDA #$00; STA $1B` is a real writer, but it is not upstream of
  the `$8114` fresh caller; it cannot be used to fill this input.

These candidates narrow the search but do not show whether the live title to
ID-1 cutscene path sets bit 6 before `$893B`.

## Runtime boundary

At the time of this source-only audit, the existing preset-loader executor
consumed an isolated `$8112` normalizer result and stopped at `$893B`; it did not
own the caller's earlier KICK OFF cutscene dispatch, source scheduler, or NMI
delivery. The following values were only cold-reset preconditions in that
audit, not the live wait inputs later established by the linked FCEUX trace:

```text
$0078 = $00, $0079 = $00, $001B.6 = 0, $003B.7 = 0
```

No source-derived Godot `$8920 RTS->$8117` receipt is implemented yet. The
behavioral trace establishes the return, but production still needs to execute
the actual ROM-owned NMI/IRQ sequence. Do not use a trace fixture as a runtime
return or infer physical NES timing from the emulator trace.

The six newly packaged byte spans were checked against the source manifest's
length, byte listing, and SHA-256. No runtime component or route state was
changed.

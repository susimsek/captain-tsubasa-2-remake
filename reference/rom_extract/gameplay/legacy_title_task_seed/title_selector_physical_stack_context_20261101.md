# Fresh KICK OFF Selector Stack Context — 1 Nov 2026

## Result

The production route now supplies a physical `$80FA JSR $A20F` return frame to
the match-selector executor. The frame is derived from checked ROM spans, not
from FCEUX RAM or the ROM-only stepper's captured endpoint. The selector
executes its nested `$A87E JSR $A8B7` and returns through both ROM RTS
instructions. At its `$A15B` checkpoint, the four stack bytes used by those
calls are `$0125-$0128 = 80 A8 FC 80`, with SP=`$24`.

Only those four stack offsets are claimed as source-known. The returned 256-byte
array is a working representation; its other historical bytes are not asserted
as exact. The asynchronous NMI is still not dispatched by the production route.

## ROM derivation

The old root task seed at `$A281-$A291` is checked against
[`manifest.json`](manifest.json). `$A281` stages slot `$01`, delay `$1E`,
return high `$80`, bank-low `$00`, and Y=`$28` before calling `$9F69`.
The checked `$9F69` helper decrements Y twice, writes `$1E/$80` at stack-page
offsets `$27/$28`, stores SP=`$26`, and marks slot `$01` ready. `$9F52` restores
SP=`$26`; its RTS reaches `$801F` with SP=`$28`. This provides the root task's
source-derived caller baseline.

The source-verified KICK OFF caller then performs these balanced calls:

| ROM call | RTS destination | Effect on the caller stack |
| --- | --- | --- |
| `$80EE JSR $82B5` | `$80F1` | Pushes `$80F0` at `$0127/$0128`; RTS restores SP=`$28` |
| `$80F7 JSR $C4B9` | `$80FA` | Pushes `$80F9` at `$0127/$0128`; RTS restores SP=`$28` |
| `$80FA JSR $A20F` | `$80FD` | Pushes `$80FC` at `$0127/$0128`; selector entry SP=`$26` |
| `$A87E JSR $A8B7` | `$A881` | Pushes `$A880` at `$0125/$0126`; nested RTS restores SP=`$26` |

The last ROM call enters `$A8B7`, which tail-jumps to `$A138`; the two return
words therefore remain on the hardware stack until their respective RTS
instructions. The four bytes at `$0125-$0128` are produced by these calls.
The base `$A281` seed bytes at `$0127/$0128` are overwritten by the live
caller JSRs before the selector reads them.

## Runtime integration

`RomFreshKickoffTitleStackContext` validates the title-task seed, old-task
create/restore helper spans, and caller JSR bytes. It emits a selector call
receipt with SP=`$26`, the ROM-produced `$80FC` return word, and an explicit
known-offset list. `RomFreshMatchSelectorExecutor` consumes that physical
stack, writes the nested JSR bytes into the RAM timeline, and returns with
SP=`$28`. The recorded-input route verifier confirms the four `$A15B` stack
bytes and keeps the stack-page completeness flag false.

The ROM-only source context at
`reference/diagnostics/kickoff_rom_source_context_snapshot_20261101/` provides
independent validation: its `$C421` frame has the NMI bytes followed by the
same `$80A8/$80FC` return words. That source context and the muted FCEUX traces
are validation evidence only; they are not runtime inputs.

## Remaining gaps

- The production route still stops at projected `$893B` without executing the
  source-owned NMI/IRQ chain or `$8117` continuation.
- Event-time RAM is incomplete (the recorded-input verifier reports 572 of
  2,048 bytes known and 9 of 25 `$893B` NMI read-set bytes known). CPU interrupt
  status is also not fully propagated at the candidate `$A15B` event.
- Only `$0125-$0128` are source-known in the route's selector stack receipt;
  the complete hardware stack history and NMI/IRQ stack effects are not
  represented.
- The 3-cycle first-NMI boundary difference, 2-cycle `$8163` difference, and
  lack of FCEUX wrapper/RTI timing comparison remain open.
- This does not establish visible field/menu parity, same-input audio parity,
  or ROM/emulator-free packaged runtime behavior.

# Fresh KICK OFF `$0078` wait: NMI route and return boundary — 29 Oct 2026

## Static-source finding; live behavior resolved

This document records the source-only audit. Its statements about unknown live
wait inputs and an unverified return were superseded by the muted, repeated
FCEUX trace in [the live wait and BGM report](fresh_kickoff_1b6_persistence_addendum_20261029.md).
The actual route enters `$8114->$8920` with `P=$22` (`I=0`), `$78=$04`,
`$79=$40`, `$1B=$C0`, and `$3B=$55`; NMI retains `$78=$04`, then raster IRQ
clears it and `$895C RTS` returns to `$8117`. The source-only executor still
does not model that interrupt/source-clock path.

FCEUX memory-write hooks record the PC after the store. The live trace's
post-write `$A1C5` therefore corresponds to source instruction `$A1C3 STA $78`;
the static instruction addresses below use the ROM's actual instruction starts.

The static source establishes that `$893B` is a synchronous busy wait, not a
scheduler yield, and describes its conditional release paths. Its isolated
prefix state `P=$A4` (`I=1`) is not the live caller state; the live trace above
supersedes that inference.

The `$893B` loop is a synchronous busy wait, not a scheduler yield. The source
prefix reaches it with the interrupt-disable flag set (`P=$A4`, so `I=1`).
Consequently, the mainline cannot rely on the maskable IRQ route while it
waits. An NMI can still preempt it. The ROM has an NMI-side bank-2 setup path
that can clear `$0078` when the current raster preset field `$79` is zero;
after that store, the loop falls through to `$893F`. This identifies a
possible source-owned release mechanism, but the available caller result does
not establish the live `$1B.6`, `$3B.7`, `$79`, or `$78` values at this exact
fresh-match call. Therefore it does not yet prove that this route takes the
releasing branch or produce a valid `$895C RTS -> $8117` receipt.

## Source identity and checked spans

All bytes below come from the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The source-only package is
[`fresh_kickoff_0078_wait_20261029/manifest.json`](fresh_kickoff_0078_wait_20261029/manifest.json).
It includes exact source spans for the wait continuation, bank-2 setup and
IRQ worker, fixed-bank NMI/IRQ dispatch, vector trampolines, and the selected
`$BF00` preset record. No emulator state, screenshots, audio, or capture bytes
are included. No FCEUX run was made for this audit.

The original `$8920-$893E` prefix remains in
[`fresh_kickoff_match_setup/manifest.json`](fresh_kickoff_match_setup/manifest.json).
Its ROM-derived entry state is summarized in
[`fresh_kickoff_match_setup_prefix_20261028.md`](fresh_kickoff_match_setup_prefix_20261028.md):
caller A=`$00`, `$EC/$ED=$00/$BF`, saved prior bank `$EA=$02`, and bank `$06`
selected. At `$893B`, the mapper helper has returned with A/X/Y/P=`$87/$06/$00/$A4`.
The `$8114 JSR $8920` frame is still on the stack; the nested helper calls
have balanced their own stack use. `$893B` reads only RAM `$0078`, and its
`BNE` repeats at `$893B` while that byte is nonzero.

## NMI-side path that can release the wait

The fixed vectors and dispatch bytes resolve as follows:

1. The NMI vector `$FFFA` points to `$C500`, whose trampoline jumps to
   `$C76E`. At `$C76E`, `BIT $1B; BVC $C775; JMP $C421` selects the alternate
   raster NMI path only when `$001B.6` is set.
2. `$C421` first checks `$003B.7`; if set, it returns through `$C472` without
   running the service. Otherwise it saves registers, maps physical PRG bank
   `$02` into `$A000`, and calls `$A000` at `$C43A`; that call returns to
   `$C43D`. It restores mapper state and reaches `$C472 RTI`.
3. Bank-2 `$A000` examines `$0079` at `$A096`. If `$79=0`, `BEQ $A0AA` takes
   the zero path: `$A0AA` writes the IRQ-disable/ack register `$E000`, then
   `$A0AD STA $78` stores the still-zero A value. An NMI running this path
   therefore changes a nonzero wait byte to zero. If `$79!=0`, `$A0A4` loads
   `$04` and `$A0A6` stores it to `$78`; the NMI setup enables raster IRQ work.
4. The `$8920` caller is still at `I=1`, and its synchronous wait does not
   clear I. Thus the maskable IRQ handler cannot be assumed to run during this
   wait. The bank-2 IRQ consumer described below is useful for the normal
   raster lifecycle, but it is not by itself a valid explanation for this
   particular busy-wait release.

The alternate path also has a second gate: `$C421 BIT $3B; BMI $C472` skips
the bank-2 call when `$003B.7` is already set. Both that guard and `$1B.6`
must be source-owned before the NMI release can be claimed for the live route.

## Raster IRQ path and other `$78` writers

The IRQ vector `$FFFE` points to `$C506`, which jumps to `$C821`. When
`$1B.6` is set, `$C821` jumps to `$C478`; that wrapper maps bank `$02` at
`$A000`, calls `$A160` at `$C491`, resumes at `$C494`, restores the saved
registers, and returns with `RTI` at `$C4AD`.

Bank-2 `$A160` treats `$78` as a raster-event cursor. Its nonterminal path
increments `$78` by three (`$A1B2/$A1B4/$A1B6`) and reloads the next IRQ. When
the indexed event marker has no low-seven-bit payload, the branch at `$A1AC`
reaches `$A1C0`; with A=`$00`, `$A1C0 STA $E000` disables/acknowledges the IRQ
and `$A1C3 STA $78` clears the cursor. This is the raster stream's terminal
clear. It is not evidence that the IRQ can execute while `$893B` has I set.

ROM source also contains a `$78` write in the normal NMI PPU-queue consumer:
`$C8FB` loads queue address high byte `$049B,X` into `$78` at `$C917`. That
path is selected when `$1B.6` is clear. Here `$78` is a PPU-pointer scratch
byte, not proven raster progress. The checked source and branch gate are in
[`normal_nmi_ppu_queue_transfer/manifest.json`](normal_nmi_ppu_queue_transfer/manifest.json).
This reuse makes the missing `$1B.6` input material: a raw `$78` value alone
does not identify which role is active.

## Continuation and exact return boundary

Once `$78` is zero, `$893D BNE $893B` falls through to `$893F`. The checked
continuation performs:

- `$893F-$8943`: read bank-6 `$BF00` byte 0 and store it to `$79`;
- `$8946-$8948`: explicitly clear `$7A`;
- `$894B-$8955`: copy source bytes 1–18 into `$7C-$8D`, leaving `$7B`
  untouched;
- `$8957-$8959`: restore the saved bank `$EA=$02` through `$C4B9`;
- `$895C RTS`: return to caller `$8117`.

The selected `$BF00-$BF12` record is 19 zero bytes. Critically, its first byte
does not set `$79` until after the wait has already exited. It cannot explain
the pre-wait `$79` input or clear `$78` on the way into `$893B`.

## Historical source-only boundary and current runtime gap

The live values and return are now established in the linked trace report. The
remaining gap is implementation: execute the ROM-owned NMI/IRQ and source-clock
transitions in Godot, then continue to `$8117` using real source effects. Do not
turn the FCEUX trace into an injected production receipt.

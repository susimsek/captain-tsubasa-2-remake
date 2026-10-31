# Fresh slot-$05 match-zero continuation boundary — 2026-10-28

## Implemented ROM-byte slice

`RomFreshDaaaContinuation` now executes from the source-owned `$DAAA` result
through the first bank-$18 worker entry at `$800C`. It extends the earlier
`$DAC4` synchronous slice across fresh-selector dispatch, the match-zero
opponent setup, and the first `$EF7F` wrapper. It is isolated from
`KickoffRouteRuntime` and does not consume emulator state as runtime input.

The hashed package in [`fresh_daaa_continuation/manifest.json`](fresh_daaa_continuation/manifest.json)
contains all executed code/data spans, tied to the supplied ROM SHA-256. The
runner carries A/X/Y/P, the hardware stack page and SP, internal RAM, mapper
selector and bank pair, named `JSR`/`RTS` continuations, and ordered CPU and
mapper writes. The executable path is:

```text
$DAAA
 -> $CBF1 / $CF4F / 22 × $CD7C
 -> $CE2D -> bank $1A:$8039/$904E -> $DAC4
 -> $DB24 / $CB99 -> fresh selector $DB34
 -> $CE2D -> bank $1C:$8003 -> $8B22
 -> 11 × $C50C/$CD7C -> match-zero opponent setup -> $DB46/$DAC7
 -> $EF7F -> $CE2D -> bank $18:$800C
```

The byte runner supports only the 6502 opcodes encountered on this bounded
path. It stops at the `$800C` worker entry; it does not step into `$8851`.
The retained FCEUX trace observes the worker later reach `$8886: JSR $C515`,
whose fixed-bank trampoline is `JMP $CB0F`. The return-minus-one value pushed
by JSR is `$8888` (the trace's stack-write PC); RTS resumes at `$8889`. The
asynchronous continuation is not executed by this component.

## Focused verification

Run:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_fresh_daaa_continuation.gd
```

The check passes on Godot 4.7.2. It compares source execution with the
retained, muted, two-pass FCEUX replay at frame 8460. At bank `$18:$800C`, both
report A/X/Y=`$00/$00/$00`, P=`$23`, SP=`$4A`, map `$18/$19/$1E/$1F`, and the
same eight stack bytes above SP. The check also compares the three MMC3 bank
switch sequences, the source call list, the first worker boundary, selected
RAM state, and ordered non-stack RAM writes through that boundary. The trace
is validation only; none of its timing, writes, registers, or endpoint state
are runner inputs.

## Exact remaining boundary to scenario `$35`

Address correction (2026-10-29): the source manifest maps CPU `$DAD8` to file
offset `0x03DAE8`, bytes `A9 35 20 B0 CB`. Thus `$DAD8` is `LDA #$35`, `$DAD9`
is the immediate operand, and `$DADA` is `JSR $CBB0`.

This does **not** reach the bank-$10 scenario `$35` call. The first worker must
execute from `$800C -> $8851` through its `$8886 -> $C515 -> $CB0F` yield,
then resume from source-owned task continuation and NMI-ready/scheduler
state. The JSR stores `$DACB` on the stack; RTS resumes the caller at `$DACC`.
The caller then enters a
second `$EF7F` wrapper with A=`$01`; that worker also needs its source-owned
yield/resume. After it returns, fixed code at `$DAD0` checks `$0629`; on this
fresh selector-zero path the caller executes `$DAD8: LDA #$35` and
`$DADA: JSR $CBB0`. `$CBB0` stores `$35` at `$0518`, enables scenario mode,
clears `$0005`, and reaches its `$CBBE: JSR $CB0F` yield. These are the source
events that establish scenario `$35`; none can be replaced with observed frame
delays.

Still open:

- Execute bank-$18 worker code, its `$C515/$CB0F` yield/save, and the ROM task
  scheduler/NMI-ready continuation from source bytes.
- Return through both `$EF7F` calls; execute `$DAD8->$DADA->$CBB0`, verify the
  `$0518=$35` setup, and reach the source yield at `$CBBE->$CB0F`.
- Prove that the route's RAM preconditions at `$DAAA` follow from prior
  source-executed gameplay. This isolated runner starts from the documented
  reset-zero baseline plus the existing source-derived `$DAAA` handoff; the
  entire preceding route is not executed here.
- Integrate the source runner into the production route only after the live
  caller, scheduler, dynamic records, and worker events are implemented.

The passing component proves this bounded ROM-source continuation and its
comparison at `$800C`; it does not prove full match setup, field rendering,
scenario `$35`, or production route parity.

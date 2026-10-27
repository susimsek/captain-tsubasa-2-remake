# Opening audio command provenance

This note resolves the apparent conflict between the captured `$0700` queue
writes and the earlier FC-counted-payload interpretation. It records the live
CPU path and mapped source bytes for the cold-start replay. The replay ran
silently in FCEUX 2.7.0 with the saved 0–4692 input timeline; its output is
execution evidence only, not a runtime sound asset.

## Verified dispatch path

The supplied ROM is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, mapper 4
(MMC3), with 256 KiB PRG ROM. CPU-to-file conversions below include the 16-byte
iNES header.

The bank-0 command interpreter dispatches opcodes `$E8–$FF` from `$84E7` through
the 16-bit table at `$8545`. Its `RTS` trampoline pushes each table value as a
return address, so the CPU resumes at the stored address plus one:

| Opcode | Stored value | Live handler entry | Observed behavior |
| --- | ---: | ---: | --- |
| `$ED` | `$85EB` | `$85EC` | Selects a free `$0700–$0704` slot, loads `(script_ptr),Y` with `Y=1`, then stores that argument to `$0700,X` at `$85FC`. |
| `$FC` | `$8836` | `$8837` | Calls `$899A` and `$9FA8`, increments the script pointer at `$884C–$8850`, then returns to the dispatcher at `$84E3`. |

Relevant ROM instructions, mapped from bank 0:

```text
$84E7  A0 00 B1 4D C9 D8 ...       ; command/text dispatch loop
$8534  38 E9 E8 0A AA ...           ; opcode index into the handler table
$8545  74 85 7F 85 ... 36 88 ...    ; interleaved target-minus-one table
$85EC  A2 00 BD 00 07 ...            ; ED queue-slot search
$85F8  A0 01 B1 4D 9D 00 07 ...      ; read argument at ptr+1; STA $0700,X
$8837  20 9A 89 A9 04 20 A8 9F ...   ; FC live entry
$884C  E6 4D D0 02 E6 4E ...          ; increment the script pointer by one
$8879  18 65 4D 85 4D A5 4E ...      ; ED handler's common pointer-advance helper
```

The sequence `JSR $9085; JMP $84E7` is physically at `$8831`, before the FC
entry. The jump-table value `$8836` is not a callable address by itself; the
`RTS` trampoline lands at `$8837`. Therefore `$9085` is not the FC handler on
this path, and the counted-payload model inferred from that preceding routine
does not describe the observed opening interpreter.

The silent replay trace
[`dispatch_context.csv`](../../diagnostics/audio_command_context_20261024_145219/dispatch_context.csv)
records the live CPU PC, script pointer/opcode/argument, selected MMC3
registers, and mapped bytes. At FC dispatch frame 870 it records `$8837`,
pointer `$A0B7`, opcode `$FC`, argument byte `$F4`, MMC3 selector `$06`, R6
`$00`, R7 `$03`. At ED queue stores it records PC `$85FC`, Y=`1`, the same
live pointer as the queue-write trace, and R6=`$00`, R7=`$03`. The per-frame
pointer remains `$A0B7` through frame 873 and advances to `$A0B8` by frame
874. In this MMC3
mode that maps PRG bank 0 at `$8000–$9FFF` and PRG bank 3 at `$A000–$BFFF`.

## Captured sound cues

The live bank-3 source offset is
`$10 + 3*$2000 + (CPU_address - $A000)`. Every row below has the ROM bytes
`ED <ID>` at that offset, the same mapped pointer/opcode/argument in the live
trace, and a matching post-store `$0700` value at CPU PC `$85FF`.

| Replay frame | Script CPU address | Queue ID | ROM file offset | ROM bytes |
| ---: | ---: | ---: | ---: | --- |
| 282 | `$A02A` | `$58` | `$603A` | `ED 58` |
| 379 | `$A03C` | `$68` | `$604C` | `ED 68` |
| 1048 | `$A0C7` | `$28` | `$60D7` | `ED 28` |
| 1068 | `$A0CA` | `$28` | `$60DA` | `ED 28` |
| 1088 | `$A0CD` | `$28` | `$60DD` | `ED 28` |
| 1108 | `$A0D0` | `$0E` | `$60E0` | `ED 0E` |
| 1510 | `$A11C` | `$02` | `$612C` | `ED 02` |
| 1779 | `$A159` | `$0E` | `$6169` | `ED 0E` |
| 1839 | `$A162` | `$09` | `$6172` | `ED 09` |
| 2368 | `$A1C3` | `$07` | `$61D3` | `ED 07` |
| 4481 | `$A02A` | `$58` | `$603A` | `ED 58` |
| 4578 | `$A03C` | `$68` | `$604C` | `ED 68` |

The final title-entry stop is a different source: the bank-0 code at file
offset `$0058` is `A9 01 8D 00 07` (`LDA #$01; STA $0700`), captured at frame
4661 and CPU PC `$804D` after the store.

## Sound-driver pointer lookup for the opening cues

The `ED` commands above queue runtime sound IDs; the bytes are not direct
sound-test track numbers. On each sound-engine update, bank-0C code at file
`0x18010` first selects the PRG bank for the queued ID range, then its second
pass calls the pointer lookup at CPU `$8349` (file `0x18359`). That routine
clears the queue slot, computes `(ID - 1) * 2`, and reads a little-endian
pointer from the table at CPU `$8BDA`.

| Queued ID | Lookup index / CPU table address | Raw table entry | Resolved header |
| --- | --- | --- | --- |
| `$58` | `$57 * 2 = $AE`; `$8C88` | file `0x18C98`: `AD B7` → `$B7AD` | Bank `$0F`, file `0x1F7BD` |
| `$68` | `$67 * 2 = $CE`; `$8CA8` | file `0x18CB8`: `E7 99` → `$99E7` | Bank `$0C`, file `0x199F7` |

For `$58`, the first-pass `$51–$5B` branch at CPU `$803F–$8050` selects bank
`$0F` in MMC3 register 7. Bank `$0F` maps CPU `$A000–$BFFF` to file
`0x1E010–0x2000F`, so `$B7AD` resolves to `0x1F7BD`. This is the opening
sequence also called “Sound 00” by the Turkish music-system list; runtime
queue ID `$58` and sound-test ordinal `00` are different numbering schemes.

For `$68`, the `$5C+` branch at CPU `$8058–$805B` writes the previously saved
bank from `$07FC` back to register 7; it does not select a new bank for this
ID. The resolved `$99E7` header is in bank `$0C`'s fixed `$8000–$9FFF` window.
Its channel records and sequence bytes are documented separately in
[`ed68_music_mapping.md`](../intro/ed68_music_mapping.md).

These pointer resolutions are byte-checked against the supplied Turkish ROM.
The observed cue frame positions below still come from the same-input FCEUX
capture. The Godot runtime audio is not sample-exact; its offline WAV uses the
ROM-derived driver/data with a capture-derived cue schedule, and its remaining
timing, timbre, and mix differences are documented in the audio renderer
audits.

Original cue IDs and frame positions in the offline timeline remain those
observed in the same-input FCEUX replay. The runtime WAV is still rendered
from the original ROM sound driver/music data; no captured PCM became a
runtime asset. This provenance correction changes no audio samples. The
separately documented post-stop PCM tail difference is still open, as is
sample-level timbre/mix validation.

## Provenance artifacts and scope

- Queue writes: `reference/diagnostics/audio_scheduler_trace_20261024_135139/queue_writes.csv`.
- CPU/MMC3 dispatch context: `reference/diagnostics/audio_command_context_20261024_145219/dispatch_context.csv`.
- Generated cue provenance: `tools/audio/build/opening_timeline_rom_events.json`.
- Generator: `tools/audio/derive_opening_sound_events.py`.

The existing cutscene VM export and FC analysis documents were generated from
the previous incorrect FC handler attribution. They are identified for the
parent task to repair; this audio pass does not change runtime VM/parser data
or rebuild the WAV. See the project-level integration notes for the current
remake status.

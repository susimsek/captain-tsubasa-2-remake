> **Withdrawn conclusion (24 Oct 2026):** This audit's FC-counted block model is contradicted by live dispatch of the cold-start stream. The `$A020–$A6DB` boundary and payload alias claims below are not verified. Preserve this file as the original hypothesis record; use `fc_counted_block_trace.md` for corrected evidence.

# FC block and cutscene-entry boundary audit

ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`  
SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`

## Finding

The bank-3 pointer immediately after entry 0 is **not** its exclusive end. It
is entry 1's start. The FC-aware command stream beginning at `$A020` continues
past that pointer and the earlier lexical `$FE` at `$A29E`; `$FE` is inside an
FC graphics payload and is not dispatched. The stream reaches its first
reachable `$FF` at `$A6DB`.

The previous 641-byte extract (`$A020–$A2A0`) remains preserved as the raw
pointer-to-next-pointer span. A separate 1,724-byte execution extract now
preserves `$A020–$A6DB` inclusive (`$A020–$A6DC` exclusive), ending at the
verified `$FF` command. The generated VM event data uses this expanded,
handler-aware stream. This corrects the extraction boundary only; it does not
integrate the stream into the Godot runtime or claim visual/timing fidelity.

## Pointer table evidence

The dispatcher uses the bank-3 table at CPU `$A000`, ROM file `$006010`.
Its first 16 little-endian entries occupy file `$006010–$00602F` and decode to:

| Entry | Target | Entry bytes (first 8) | First FC-aware `$FF` |
|---:|---:|---|---:|
| 0 | `$A020` | `E8 01 F9 00 FB 01 8D E9` | `$A6DB` |
| 1 | `$A2A1` | `E8 01 F9 5C FB 01 6D DD` | `$A6DB` |
| 2 | `$A626` | `E8 01 F9 02 FB 01 15 DE` | `$B58F` |
| 3 | `$A6B4` | `E8 01 F9 02 FB 01 15 DE` | `$A6DB` |
| 4 | `$A6DC` | `E8 01 F9 02 FB 01 38 DE` | `$B58F` |
| 5 | `$A968` | `E8 01 F9 55 FB 01 63 DE` | `$B58F` |
| 6 | `$AB61` | `E8 01 F9 26 FA 27 FB` | `$B58F` |
| 7 | `$AE6D` | `E8 01 F9 11 FA 10 FB` | `$B58F` |
| 8 | `$AEEA` | `E8 01 F9 2B FA 10 FB` | `$B58F` |
| 9 | `$B1F1` | `E8 01 DF ED 69 DE F9 0C` | `$B58F` |
| 10 | `$B327` | `E8 01 ED 01 DE ED 69 DC` | `$B58F` |
| 11 | `$B3EE` | `E8 01 F9 10 FA 11 FB` | `$C702` |
| 12 | `$B506` | `E8 01 F9 11 FA 10 FB` | `$C702` |
| 13 | `$B590` | `E8 01 F9 11 FA 10 FB` | `$C702` |
| 14 | `$B6C8` | `E8 01 F9 11 FA 10 FB` | `$C702` |
| 15 | `$B731` | `E8 01 F9 2B FB 01 43 DE` | `$C702` |

The raw table bytes are:

```text
20 A0  A1 A2  26 A6  B4 A6  DC A6  68 A9  61 AB  6D AE
EA AE  F1 B1  27 B3  EE B3  06 B5  90 B5  C8 B6  31 B7
```

This establishes that these are multiple indexed entry points, not a list of
exclusive byte-range boundaries. Some entries intentionally point into a
continuous/interleaved bank-3 data region and can share later termination.

## Why `$A2A1` is payload for entry 0

Entry 0 reaches `$FC` at CPU `$A1B0` (ROM file `$0061C0`) with bytes `FC F4`.
The traced handler `$8836` calls `$9085`; `$9085` loads `$F4` into `$EC`, moves
the script pointer past the two-byte command, and consumes exactly 244
descriptor bytes before returning to command dispatch. The payload range is
CPU `$A1B2–$A2A5`, ROM file `$0061C2–$0062B5` inclusive. The return pointer is
CPU `$A2A6`, ROM file `$0062B6`.

Entry 1 independently points to CPU `$A2A1`, ROM file `$0062B1`. Those same
five bytes, `$A2A1–$A2A5`, are therefore interpreted in two contexts:

```text
E8 01 F9 5C FB
```

When dispatched from entry 1, these are ordinary commands and operands. While
entry 0's `$9085` is processing its counted block, they are five of the 244
graphics descriptor bytes. This is not a contradiction: ROM bytes have no
intrinsic command/data type; the active routine and pointer state determine
their interpretation. The dispatcher's pointer table makes `$A2A1` a valid
entry start, while the FC handler's verified count makes that address payload
in entry 0's execution.

## Corrected entry-0 execution source

- Start: CPU `$A020`, file `$006030`.
- Terminal: CPU `$A6DB` (`FF`), file `$0066EB`.
- Exclusive end: CPU `$A6DC`, file `$0066EC`.
- Length: 1,724 bytes.
- SHA-256: `6b620e8a888690b2ddd42c1de986a880d3c78d0b264db5db1d0c226166f0cca4`.
- Preserved bytes: `reference/rom_extract/intro/cutscene_00_execution.bin`.
- Generated handler-aware records: `assets/opening/rom_logic/cutscene_00_vm.json`.

The pointer-span export remains separately available as
`reference/rom_extract/intro/cutscene_00.bin` (641 bytes, SHA-256
`499ccb62b8b2b9118d7ebfaa6e6b9fce46806cd3b9173b5e1d5d61de21c2a6b7`). Its
lexical events are archival decoding only and must not be treated as the
entry-0 execution sequence.

Boundary finding is byte-backed and limited to this cutscene entry. The
extractor rejects a reachable `$FE` rather than assuming a jump does not alter
the path. Start-input polling happens in the outer program; its timing and
rendering remain separate questions.

The expanded event stream also reaches an `EB` command at CPU `$A326`. Its
input predicate and wait timing have not been traced and are not modeled by
the current isolated VM; boundary parsing does not imply the input behavior is
complete.

## Rebuild and checks

From the project root, reproduce the extracted source metadata/binaries and
generated VM records with:

```sh
python3 tools/extract_intro_cutscene.py
python3 tools/opening/build_cutscene_vm_data.py
```

The second command checks the expected ROM SHA-256, the distinct pointer-span
and expanded-stream hashes, both ROM byte ranges, all archived lexical byte
spans, and that the 62 generated event spans reproduce all 1,724 execution
bytes ending in `FF`. Recorded output:

```text
Extracted 641 bytes, 181 events, 9 backgrounds, 13 animation records
wrote assets/opening/rom_logic/cutscene_00_vm.json (62 handler-length events from 181 lexical records, 1724 ROM bytes)
```

These are extraction/build integrity checks, not Godot runtime or visual/audio
fidelity tests. No Godot tests or emulator validation were run for this change.

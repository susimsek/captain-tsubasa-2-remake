# PASS Candidate Selector Source Audit

## Source identity and coverage

The extracted bytes come from the supplied Turkish ROM, SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097` (393,232 bytes). All six ranges are PRG bank `$1E`, mapped in the `$C000-$DFFF` CPU window. The exact half-open ranges, raw file offsets, lengths, and per-file hashes are recorded in `manifest.json`. The extraction contains two code spans and only four lookup intervals directly referenced by `$CF8F`; unrelated assets and neighboring data are excluded.

## Decoded path

- `$D77A-$D792` initializes `$0622`, passes `$0430` to `$CF8F`, and interprets the helper result before returning at `$D791`.
- `$CF8F-$D002` prepares the selector's current data index, queues the selector update, and calls `$CB0F` at `$CFA6`. The saved continuation resumes at `$CFA9`, where the routine reads and processes `$0622`, samples `$001E`, and applies bounded selector updates before returning at `$D001`.
- `$CF8F` has four indexed reads: `$CF93 LDA $D002,X`, `$CF99 LDA $D01A,X`, `$CFB4 ADC $D00A,X`, and `$CFD3 CMP $D012,X`. Their table starts are eight bytes apart, so the package contains four exact, adjacent, non-overlapping intervals: `$D002-$D00A`, `$D00A-$D012`, `$D012-$D01A`, and `$D01A-$D022` (end-exclusive). The first three end at the next referenced base; `$D022` begins the following code. Per-table bytes and hashes are listed in `manifest.json`.

## Trace provenance and route distinction

The `$D77A->$CF8F` selector path, `$CFA6->$CB0F` yield, `$CFA9` resume, and the recorded Down/A selector outcomes were observed in a separate disk-save-state continuation beginning from FCEUX slot 0 at source frame 8399. That path diverges from the clean power-on replay; it is not evidence for the recorded cold-start PASS route. The relevant input events were Down at source frame 9068 and A at 9076. Frame labels are FCEUX trace labels, not physical NES timing claims.

## Clean power-on replay

A separate FCEUX replay began at clean power-on with no disk state loaded. At source frame 8399 its RAM matched the retained checkpoint, PPU memory matched outside palette space, and mapped PRG signatures matched; those were comparison checks only, not state seeding. This trace did not observe the `$CF8F` selector path. It records `$D6C7` at frame 9046, then the receiver wait at `$D80F` on frame 9068. The Down input writes `$0624=$78` at `$D832`; the scan calls `$D834`. A at frame 9076 reaches `$D852` and returns to `$D70C`, so this input is receiver confirmation in the cold-start trace. The next command-input wait is reached at `$D5EA` on frame 9600, cycle 285870645 (7621 cycles from that frame's start), in bank `$1E`; the event records `A=$06`, `X=$06`, `Y=$03`, `SP=$4C`, return `$D567`, and mapper banks `$1A/$1B`. At the frame-10080 RAM snapshot, holder `$0441=$0A`; the retained receiver list is `$0430=1`, `$0431=$0A`; cursor `$0624=$78`, selectable count `$0625=1`, and confirmation bytes `$05FC=$0A`, `$05FE=$78`. These RAM values do not prove that the next command wait reinterprets the retained receiver list as a new candidate scan.

## Limits

These files expose the ROM code for the selector and its scheduler yield point plus the four directly referenced lookup intervals. The table bounds are based on the adjacent ROM layout and reference bases; this audit does not claim a global bound for all possible X values. The package does not execute the code in Godot or prove full menu, rendering, audio, or cycle-level parity.

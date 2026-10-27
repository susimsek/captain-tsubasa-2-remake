# Annotated CT2 disassembly audit: opening and title path

Checked against the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Reference listing is pinned to commit
[`ec03cf06e6bdae0bcd232e3a423e9d259757dc64`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64):
[bank_80.asm](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_80.asm)
and
[bank_87.asm](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_87.asm).
The repository is named for an English translation, but the inspected bank
comments are largely Russian; use its code bytes and labels as leads, not as
Turkish script or text data.

## Byte audit

The listing's annotated byte fields were compared at their stated absolute
iNES file offsets (including the 16-byte header): `bank_80.asm` has 3,872
annotated records / 7,406 byte values, all matching; `bank_87.asm` has 3,869
annotated byte records, all matching. The disassembly itself describes bank
80 at CPU `$8000` / file `0x000010`, and bank 87 at CPU `$A000` / file
`0x00E010`. These results validate the listed bytes, not every comment or
behavioral interpretation. A prior wider spot-check found mismatches in
banks 82, 98, and A7; do not transfer those banks' offsets or labels without
separate checks.

## Verified cold-start and menu code

For bank 80, CPU `$8000` maps to file `0x000010 + (CPU - $8000)`.

| CPU address | File offset | ROM bytes | Reading, cross-checked with local evidence |
|---|---:|---|---|
| `$801F–$8026` | `0x00002F–0x000036` | `20 A0 9B A9 00 20 64 84` | Initializes the opening, selects cutscene 0, and calls `$8464`. The local dispatcher trace confirms scene 0 selects bank 3 and its first pointer `$A020` (script at file `0x006030`). |
| `$8027–$8031` | `0x000037–0x000041` | `A9 01 20 A8 9F A5 1E 29 10 F0 F5` | Yields through `$9FA8`, reads newly pressed input `$1E`, masks Start (`$10`), and repeats while clear. This is the live Start polling loop in the local trace. |
| `$8048–$804C` | `0x000058–0x00005C` | `A9 01 8D 00 07` | Queues sound command `$01` at RAM `$0700` on leaving the opening. The synchronized local trace sees APU channel volume reach zero on the next source frame. |
| `$806A–$8079` | `0x00007A–0x000089` | `A9 17 20 F7 8A A9 30 20 0C 89 20 FB 88 20 35 9A` | Starts the `$17` background load at source frame 4664 and resumes at `$806F` on frame 4690 after queue staging; then calls the sprite Y-offset, sprite-priority, and palette helpers. A dedicated silent trace reconstructs all 240 queued background packets and matches their ROM-derived bytes/order. |
| `$807A–$80A1` | `0x00008A–0x0000B1` | `A9 00 20 20 89 A9 00 85 90 A9 02 85 91 A5 1B 29 FE 85 1B A9 0A 85 ED A5 ED 85 E6 A9 22 85 E7 A0 01 A2 01 A9 7F 20 EA 98` | Clears title state, sets CHR selectors and the cursor address `$220A`, then queues tile `$7F` there. The local PPU capture confirms `$7F` beside `KICK OFF` and no marker beside `CONTINUE`. |
| `$80A2+` | `0x0000B2+` | `A9 01 20 A8 9F A5 1E 29 3C ...` | Waits for Select/Start/Up/Down input. The remaining code toggles the cursor between `$220A` and `$224A`; local Down-pulse capture confirms the move. |
| `$80E1–$80ED` | `0x0000F1–0x0000FD` | `50 03 4C 6A 82 20 A0 9B A9 01 20 64 84` | Branches from Start according to cursor: Continue jumps to `$826A`; Kick Off begins a new cutscene at `$80E6`. Activating either route is outside the current slice. |

The title background record is data in bank 87. Its ID `$17` pointer slot is
file `0x00E010 + 2*$17 = 0x00E03E`; the Turkish ROM bytes there are `73 A3`,
which resolve to CPU `$A373`. Bank 87's record begins at file `0x00E383` and
starts `7C 7E 81 06 08 08`; the existing ROM-only decoder records its full
bytes, CHR banks, palette, and metatile layout in
[`background_17_layout.json`](background_17_layout.json). The annotated
listing labels this entry as the main menu with logo. Its decoded data and
the observed title screen corroborate that label.

## What this establishes, and what it does not

This is useful reverse-engineering source: the opening entry, Start loop,
audio-stop request, title-background selection, cursor initialization, and
menu branches are backed by matching bytes and a local execution/PPU trace.
The online listing does not supply the Turkish opening script as a Godot-ready
scene, nor does this audit decode the full cutscene interpreter, per-frame
animation scheduling, raster-visible PPU timing, or APU music sequencing.
Those still need to be derived from the Turkish ROM and its local traces.
Godot's current presentation should therefore not be described as executing
this entire native code path yet.

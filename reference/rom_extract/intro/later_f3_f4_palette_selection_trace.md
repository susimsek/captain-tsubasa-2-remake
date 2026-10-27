# Later opening F3/F4 palette selection trace

## Scope and evidence

This trace covers the later opening scene changes at `$A090–$A205`, through
backgrounds `03`, `08`, `07`, `09`, `03`, `0A`, and `0B`. The canonical ROM
is `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Bank-0 addresses below are checked against that ROM using file offset
`$0010 + (CPU address - $8000)`. The active script order and source frames
come from `cold_start_observed_dispatch.json`; end-of-frame RAM samples come
from `opening_timing_capture_20261024_131316/ram_states/`. Its recorded MD5
`eaf2b3745263efa4b1afd2b400f68dae` matches the ROM payload without the 16-byte
iNES header.

## Selection path

* `F9` enters `$8814`, clears bit `$04` in `$5B`, then joins `$881F`;
  `FA` enters `$881B`, sets that bit, then joins the same path. The shared
  routine reads the background ID and calls `$8AF7`.
* `$8AF7` reads the background record. At `$8B49–$8B4C`, it masks record byte
  2 with `$3F` and stores the result in `$48`, the background palette index.
  The high two bits are also threaded through `$5B` at `$8B4E–$8B52`; their
  full mirroring/area meaning is not resolved here.
* `FB` calls `$9085`. The helper visits every listed animation ID, selects
  bank 9 for IDs below `$6D` or bank 10 for IDs `$6D` and above, reads the
  animation record's first byte, and stores it in `$49`. Each ID overwrites
  `$49`, so for a multi-ID list the last listed record supplies the sprite
  palette index for the next full palette build.
* `F3 00` at `$8682` calls `$9A35`. That routine switches to the palette bank,
  copies 16 background bytes selected by `$48` from the table based at ROM
  file `$00D010`, copies 16 sprite bytes selected by `$49` from the table
  based at `$00D310`, restores the prior bank, sets brightness `$4A/$4B` to
  `$0F`, and stages the 32-byte palette packet through `$9A71`.
* `F4 04/05` does not choose another palette record. Within the palette data,
  its helper changes only `$0631` (`$062A + 7`, background palette slot 7),
  rebuilds the 32-byte packet through `$9A71`, and yields four scheduler
  releases per value.

The supplied-ROM signatures agree with the mapped routines: `$8682` at file
`$0692` begins `C8 B1 4D D0 08 20 35 9A` and calls `$9A35`; `$8814/$881B` at
`$0824/$082B` begin `A5 5B 29 FB` / `A5 5B 09 04`; `$90FD` at `$110D` begins
`B1 92 85 49`; and `$9A35` at `$1A45` calls `$9B07`, `$9AB8`, and `$9ADA`.
F4 code at `$0706/$0723` begins `A9 04 ... BD B3 87 8D 31 06` /
`A9 00 ... BD B4 87 8D 31 06`, indexing the slot-7 fade table at `$87B4`
(file `$07C4`), whose bytes are `30 20 10 0F`. This direct byte check is the
basis for the sequence below; symbol names in the local disassembly are
labels, not independent evidence.

## Observed scene selections

Palette offsets below are ROM file offsets, including the iNES header. The
end-of-frame `$48/$49` values and the `$062A–$0649` 32-byte palette copy match
the selected source records in every listed F3 frame.

| Script commands | Background record byte 2 → index / source | FB list → record header bytes / final `$49` | F3 frame; following transition |
| --- | --- | --- | --- |
| `$A090 FA 03`; `$A092 FB 01 75`; `$A095 F3 00` | `03` record `$00E14F`: byte `04` → index `04` at `$00D050` | `75`: `01` → `01` | 819; `$A097 F4 05` |
| `$A0BD F9 08`; `$A0BF FB 02 C1 82`; `$A0C3 F3 00` | `08` record `$00E1B1`: byte `8E` → index `0E` at `$00D0F0` | `C1:02`, `82:02` → `02` (last ID `82`) | 1047; `$A0C5 F5 10` |
| `$A123 FA 07`; `$A125 FB 01 76`; `$A128 F3 00` | `07` record `$00E1A0`: byte `1B` → index `1B` at `$00D1C0` | `76`: `01` → `01` | 1534; `$A12A F4 05` |
| `$A150 F9 09`; `$A152 FB 01 84`; `$A155 F3 00` | `09` record `$00E1D9`: byte `03` → index `03` at `$00D040` | `84`: `00` → `00` | 1778; `$A157 F5 01` |
| `$A193 FA 03`; `$A195 FB 01 77`; `$A198 F3 00` | `03` record `$00E14F`: byte `04` → index `04` at `$00D050` | `77`: `06` → `06` | 2126; `$A19A F4 05` |
| `$A1BA F9 0A`; `$A1BC FB 03 C0 A2 7D`; `$A1C1 F3 00` | `0A` record `$00E201`: byte `00` → index `00` at `$00D010` | `C0:07`, `A2:07`, `7D:07` → `07` (last ID `7D`) | 2367; `$A1C3 ED 07` |
| `$A1FE FA 0B`; `$A200 FB 01 7C`; `$A203 F3 00` | `0B` record `$00E23A`: byte `05` → index `05` at `$00D060` | `7C`: `08` → `08` | 2694; `$A205 F4 05` |

Background records and palette bytes are independently preserved in
`background_03_layout.json`, `background_07_layout.json`,
`background_08_layout.json`, `background_09_layout.json`,
`background_0A_layout.json`, and `background_0B_layout.json`. The animation
header bytes above are at ROM offsets `$014196` (`75`), `$01419F` (`76`),
`$0141A9` (`77`), `$0141D1` (`7C`), `$0141DA` (`7D`), `$01426F` (`82`),
`$0142DB` (`84`), `$014760` (`C0`), `$014767` (`C1`), and `$01451E` (`A2`).

The unique background palette indices used here are `00`, `03`, `04`, `05`,
`0E`, and `1B`; the unique sprite indices are `00`, `01`, `02`, `06`, `07`,
and `08`. Their 16-byte records are respectively at `$00D010 + 16×index`
and `$00D310 + 16×index`. Per-frame RAM comparisons show exact byte equality
for all seven selected background/sprite palette pairs. These are telemetry
cross-checks only; no captured image or audio is used as a runtime asset.

The raw palette bytes checked at those table offsets are:

```text
BG 00 @D010  0F 1A 18 30 0F 36 25 30 0F 21 31 30 0F 2B 10 30
BG 03 @D040  0F 19 21 30 0F 36 25 30 0F 0F 00 30 0F 15 00 30
BG 04 @D050  0F 0F 10 30 0F 36 25 30 0F 21 30 31 0F 21 30 37
BG 05 @D060  0F 21 30 31 0F 36 25 30 0F 21 11 16 0F 21 11 30
BG 0E @D0F0  0F 15 25 30 0F 36 25 30 0F 21 3A 1A 0F 00 32 30
BG 1B @D1C0  0F 0F 0F 0F 0F 0F 0F 30 0F 21 10 00 0F 21 10 00
SP 00 @D310  0F 0F 0F 36 0F 0F 16 36 0F 0F 30 36 0F 0F 30 36
SP 01 @D320  0F 0F 36 27 0F 0F 36 30 0F 0F 30 27 0F 0F 30 36
SP 02 @D330  0F 0F 0F 36 0F 0F 00 36 0F 0F 0F 36 0F 0F 30 36
SP 06 @D370  0F 0F 36 27 0F 0F 07 27 0F 0F 36 30 0F 0F 07 36
SP 07 @D380  0F 0F 30 36 0F 0F 32 36 0F 0F 22 36 0F 0F 30 36
SP 08 @D390  0F 0F 36 27 0F 0F 30 27 0F 0F 30 31 0F 0F 30 36
```

## F4 ordering and limits

The verified F4 table at ROM file `$07C4` is `30 20 10 0F`. F4 05 starts at
index 0 and writes `$0631` as `30 → 20 → 10 → 0F`; F4 04 starts at table
index 3 and writes `0F → 10 → 20 → 30`. The recorded RAM agrees: for example,
F4 05 at `$A097` changes `$0631` at source frames 819/824/828/832; F4 04 at
`$A0B8` changes it at 874/878/882/886. `$A12A`, `$A147`, `$A19A`, `$A1B1`,
and `$A205` show the corresponding same sequences in the same capture.

Unresolved: the complete meaning of the background-record high flag bits and
all branches of F3 operands other than `00`; the exact PPU/NMI visibility edge
for these later palette packets; and any animation-time palette changes after
the F3 selection. Frame-end RAM proves the selected source bytes and F4 slot-7
values, not full raster or pixel timing.

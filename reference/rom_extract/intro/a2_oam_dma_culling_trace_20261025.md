# A2 sprite OAM DMA culling trace — 2026-10-25

## Result and confidence

The supplied Turkish ROM contains a byte-verified shared sprite-frame writer
and DMA-page copier that explain the A2 records' `$07` attributes and `$F8`
Y bytes. The copier checks attribute mask `$0C`; if either marker bit is set,
it substitutes `$F8` for the sprite Y coordinate in the DMA source, then still
copies tile, attribute, and X. This is consistent with the sampled A2 RAM
states.

The routine bytes and copy rule are verified against the target ROM. The
available capture has end-of-frame RAM snapshots, not PC-tagged CPU writes, so
the exact A2 call site and per-frame execution timing are **not yet
instruction-traced**. The mapping from A2's unsigned doubled Q8.8 origin and
descriptor offsets to the observed shadow/DMA tuples is now checked across
all 49 saved frames 2367–2415; see
[`a2_oam_culling_fix_20261025`](../../diagnostics/a2_oam_culling_fix_20261025/README.md).
Do not treat the tuple correspondence as proof of the exact intra-frame call
or `$4014` DMA edge.

## ROM and address mapping

Target ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

| Function | CPU address | PRG mapping / raw file offset | Evidence |
|---|---:|---:|---|
| Sprite descriptor writer | `$94D8–$96F1` | fixed bank 0; `$9541` at `0x001551` | Annotated disassembly bytes at the relevant instructions match the target ROM. |
| DMA-source copier | `$A8CE–$A8FD` | bank 2; `0x0048DE` | The full 48-byte routine at `0x0048DE–0x0048FD` matches the raw ROM. |
| Bank-2 trampoline | `$A215` | `0x004225` | Target bytes are `4C CE A8` (`JMP $A8CE`). |
| NMI DMA setup | `$A000` | `0x004010` | Target bytes begin `A9 00 8D 03 20 A9 02 8D 14 40` (`$2003=0`, `$4014=2`). |

The disassembly source is the public English-translation project pinned and
audited in [`disassembly_coverage_audit.md`](disassembly_coverage_audit.md).
Its bank-82 listing has three mismatches in the earlier `$A8B7` routine at raw
offsets `0x0048C7–0x0048C9`; the `$A8CE` copier starts later at `0x0048DE`, and
its bytes independently match the supplied Turkish ROM. The listing is a
navigation aid, not a revision-identical full disassembly.

## Source behavior

At `$9541`, the common descriptor writer reduces the computed Y high/overflow
state to bit 0 and shifts it into `$00EC`. At `$954D–$9555`, it combines the
computed X high/overflow bit and shifts the combined flags into attribute
bits 2 and 3. `$9557–$9569` combines those flags with the descriptor's base
attribute and stores the result at `$046A+X`. For this path, the generated
marker assignments are X in bit 2 (`$04`) and Y in bit 3 (`$08`).

The target bytes around those stores include:

```text
$9541  29 01 85 EB 0A 85 EC
$9548  A5 E8 9D 6B 04 A5 E9 29 01 05 EC 0A 0A 85 EC
$9557  A0 00 B1 E6 51 94 29 40 05 EC 85 EC
$9563  B1 E6 29 03 05 EC 9D 6A 04
```

The copier at `$A8CE` first calls `$9FA8` with `$01`, then starts at Y=0 and
steps through all 64 four-byte sprite records in page `$0468–$0567`:

```text
LDX $0468,Y        ; retain source Y in X
LDA $046A,Y        ; attribute
AND #$0C           ; X/Y overflow markers?
BEQ +2             ; no marker: keep the source Y in X
LDX #$F8           ; marker present: hide by moving Y off-screen
TXA
STA $0200,Y        ; DMA-source Y
LDA $0469,Y
STA $0201,Y        ; tile
LDA $046A,Y
STA $0202,Y        ; attribute
LDA $046B,Y
STA $0203,Y        ; X
INY / INY / INY / INY
BNE loop           ; 64 entries, until the 8-bit index wraps
RTS
```

The question mark in the comment emphasizes what the instruction establishes:
the copier tests bits `$04/$08`, without knowing their semantic names. Their
association with the writer's X/Y high-state flags follows from the checked
`$9541–$9569` instructions. Only the DMA Y byte is replaced; tile, attribute,
and X are copied for hidden entries as well. The source prepares a DMA from
page `$02` via `$2003=0` and `$4014=2`; `$0200–$02FF` is CPU RAM used as the DMA
source, while the PPU's internal OAM is the DMA destination. Thus
`$0240–$0263` is not itself hardware OAM: it is source RAM for OAM entries
16–24.

## A2 memory correspondence

A2 reserves OAM-shadow bytes `$04A8–$04CB`, nine descriptors at indices 16–24.
The corresponding DMA-source bytes are `$0240–$0263`. These values are read
from the capture's 2 KiB CPU-RAM snapshots in
[`opening_timing_capture_20261024_131726/ram_states`](../../opening_timing_capture_20261024_131726/ram_states).
Each tuple below is in NES Y/tile/attribute/X byte order. “Marked” counts
shadow attributes with `attr & $0C != 0`; every marked entry in these samples
has DMA Y `$F8`, while all four fields otherwise follow the copy rule.

| Source frame | Shadow attributes, slots 16–24 | Marked | DMA Y bytes, slots 16–24 | Full tuple bytes copied from shadow |
|---:|---|---:|---|---:|
| 2367 | `07 07 07 07 07 07 07 07 07` | 9 | `F8 F8 F8 F8 F8 F8 F8 F8 F8` | 9/9 except the substituted Y bytes |
| 2372 | `03 03 03 07 07 07 07 07 07` | 6 | `22 2A 32 F8 F8 F8 F8 F8 F8` | 3 visible tuples exact; hidden tuples copy T/A/X |
| 2376 | `03 03 03 03 03 03 07 07 07` | 3 | `26 2E 36 26 2E 36 F8 F8 F8` | 6 visible tuples exact; hidden tuples copy T/A/X |
| 2380 | `03 03 03 03 03 03 03 03 03` | 0 | `2A 32 3A 2A 32 3A 2A 32 3A` | 9/9 exact |
| 2415 | `07 07 07 07 07 07 07 07 07` | 9 | `F8 F8 F8 F8 F8 F8 F8 F8 F8` | 9/9 except the substituted Y bytes |

Examples from frame 2372 make the distinction explicit:

```text
slot 16 shadow 22 48 03 FF  -> DMA 22 48 03 FF  (unmarked)
slot 19 shadow 22 49 07 07  -> DMA F8 49 07 07  (marked; only Y differs)
```

The descriptor-to-coordinate mapping is now source-backed for this animation:
`unsigned_q8_8_position >> 7` gives the doubled pre-wrap OAM coordinate, the
decoded signed descriptor offset is added, and bit 8 becomes X marker `$04` or
Y marker `$08`; the stored OAM coordinate is the low byte. Applying that
mapping predicts all 9 shadow tuples and all 9 DMA-source tuples exactly in
each of the 49 saved A2 snapshots. The verifier output, including the
visibility transitions, is
[`a2_oam_model_check.csv`](../../diagnostics/a2_oam_culling_fix_20261025/a2_oam_model_check.csv).
The implementation and focused Godot/FCEUX capture are described in
[`a2_oam_culling_fix_20261025/README.md`](../../diagnostics/a2_oam_culling_fix_20261025/README.md).

Frame 2372's shadow X bytes include wrapped values such as `$FF` and `$07`;
this note does not infer the complete clipping geometry or the exact screen
edge from those bytes. It records only the flag generation, mask check, and
observed Y substitution. A2's motion descriptor allocation and frame anchors
are detailed in [`a2_motion_record_trace_20261025.md`](a2_motion_record_trace_20261025.md).

## Timing gap and next trace

`bus_events.csv` records PPU/MMC3 activity, not PC-tagged CPU writes to
`$04A8–$04CB` / `$0240–$0263`, and the saved RAM samples are end-of-frame
states. The `$A215 -> $A8CE` trampoline and `$A8CE`'s initial cooperative wait
are byte-verified, but neither establishes that this call path copied A2's
descriptors on every listed frame. The exact NMI `$4014` transfer edge within
those frames is likewise not logged.

To close this, replay the same cold-start input in a **silent, isolated**
FCEUX trace and record frame/cycle plus PC for execution at `$94D8`, `$A8CE`,
`$A8D8`, and `$A8E1`; writes to `$04A8–$04CB` and `$0240–$0263`; and `$4014`.
Correlate the trace with source frames 2367–2415 and record the active MMC3
PRG mapping at each hook. Existing
[`trace_opening_ram_oam_writes.lua`](../../../tools/diagnostics/trace_opening_ram_oam_writes.lua)
already logs RAM-write PC and timing for other windows (1534–1570 and
2694–2722); extend its frame window only when the emulator is available and
not being controlled by another task. Until then, the byte-level mechanism is
verified, while A2-specific call timing and actual `$4014` transfer timing
remain unresolved.

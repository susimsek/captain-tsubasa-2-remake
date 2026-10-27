# Cold-boot cutscene task installation trace

## Scope and ROM identity

This trace follows the supplied Turkish ROM from CPU `$801F` through the
cutscene dispatcher at `$8464`, task registration, and the first worker
dispatch observed at `$84E7`. It uses existing FCEUX captures only; no emulator
or shared UI was controlled for this report.

| Item | Value |
|---|---|
| ROM | `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes` |
| File size | 393,232 bytes |
| SHA-256 (whole iNES file) | `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097` |
| MD5 (whole iNES file) | `93d14fb7962c54062be9734642fbe7bd` |
| MD5 (payload after the 16-byte iNES header) | `eaf2b3745263efa4b1afd2b400f68dae` |
| Mapper / PRG / CHR | MMC3 mapper 4 / 256 KiB / 128 KiB |

All CPU addresses `$8000–$9FFF` below refer to the 8 KiB PRG bank-0 mapping;
file offset is `0x10 + (CPU address - $8000)`. When PRG bank 3 is mapped at
`$A000–$BFFF`, file offset is `0x6010 + (CPU address - $A000)`. Offsets include
the iNES header.

## Source path and task installation

The cold-start entry is at bank-0 CPU `$801F`, ROM file `0x00002F`:

```text
$801F  20 A0 9B       JSR $9BA0       ; fade out if needed; clear nametables/OAM
$8022  A9 00          LDA #$00        ; cutscene index 0
$8024  20 64 84       JSR $8464       ; choose script/bank and install worker
$8027  A9 01          LDA #$01
$8029  20 A8 9F       JSR $9FA8       ; caller's one-tick cooperative yield
$802C  A5 1E          LDA $1E         ; newly pressed controller buttons
$802E  29 10          AND #$10        ; Start
$8030  F0 F5          BEQ $8027       ; keep the intro running until Start
```

The local bytes are `20 A0 9B A9 00 20 64 84 A9 01 20 A8 9F A5 1E 29 10 F0 F5`.
The called `$9BA0` is `JSR $99F0; JSR $98A0; JMP $9B7F` at file
`0x001BB0`. `$99F0` immediately returns when both fade counters `$4A/$4B` are
zero; the power-on RAM snapshots show both zero in source frames 0–8. `$98A0`
clears nametable memory with PPU writes and contains no `$9FA8` wait. Thus this
observed cold-start path has no explicit eight-frame wait in `$9BA0`.

At `$8464` (file `0x000474`), the dispatcher chooses the scene bank from the
table at `$8AEE` (file `0x000AFE`). The local table starts `00 03 10 04 20 05`:
cutscene 0 selects bank 3 and pointer-table entry 0. Its script pointer is
`$A020`, bank-3 file `0x006030`, whose first commands are `E8 01 F9 00 FB 01 8D`.
The observed MMC3 trace confirms bank 3 is mapped into the `$A000` slot when
the worker reads the script.

The relevant dispatcher bytes at `$8494–$84A4` (file `0x0004A4–0x0004B4`) are:

```text
A2 05          LDX #$05
A9 C5 95 00    LDA #$C5 / STA $00,X
A9 84 95 01    LDA #$84 / STA $01,X
A0 50          LDY #$50
20 69 9F       JSR $9F69
```

`$9F69` is at file `0x001F79`, with local bytes
`95 02 B5 00 99 01 01 B5 01 99 02 01 94 01 A9 FF 95 00 60`. For X=`$05`, it
sets the worker's PRG-bank field at `$0007` to bank 0, copies the staged return
address `$84C5` into stack RAM `$0151/$0152`, stores the saved stack pointer
`$50` in `$0006`, and finally writes `$FF` to the worker delay/ready byte
`$0005`. Resuming that saved 6502 return reaches `$84C6`; the first worker
interpreter read is at `$84E7`.

`$FF` is a scheduler sentinel, not a duration. The local scheduler at
`$9EED` (file `0x001EFD`) starts scanning X=`$01` and advances by four through
`$01,$05,$09,$0D,$11,$15`. It skips zero, dispatches `$FF` immediately, and
otherwise decrements the counter and dispatches when it reaches zero. This is
also how the byte-verified pinned listing describes the control flow; the
relevant instruction bytes were checked against this ROM.

Once the worker resumes at `$84C6`, its setup begins:

```text
$84C6  A6 56 20 B9 C4    restore worker PRG bank
$84CB  A9 08 85 55       LDA #$08 / STA $55   ; initial text speed
$84CF  A9 49 85 4F       initial text-buffer PPU address
...
$84E7  A0 00 B1 4D       read current script byte through $4D/$4E
```

The `$08` at `$84CB` is explicitly stored to text-speed RAM `$55`; it is not
stored to task delay `$0005`. The pinned online listing has a contradictory
comment `LDA #$04` beside bytes `A9 08`; the supplied ROM bytes and capture's
`$55=08` resolve this as an annotation error. See the byte audit in
[`annotated_disassembly_opening_audit.md`](annotated_disassembly_opening_audit.md).

## First dispatch and frame evidence

The existing power-on replay uses the exact input timeline in
`reference/opening_reference_capture/input_timeline.csv`. Its frame convention
is important: source frame 0 drives the first `frameadvance`; the snapshot is
labelled by the emulator frame after that step. Therefore “source frame 8” is a
capture-relative power-on timestamp, not a ROM constant or an eight-tick
operand.

| Evidence | Observation |
|---|---|
| `cold_start_observed_dispatch.json`, event 1 | Source frame 8 dispatches `$E8` at script `$A020` (bank-3 file `0x006030`). |
| Same trace, event 2 | Source frame 8 dispatches `$F9` at `$A022`; same-frame multiple interpreter entries are observed. |
| `audio_scheduler_trace_20261024_135139/exec_counts.csv` | Frame 8 has three `$9FA8` hits and two `$84E7` dispatch hits. |
| `opening_timing_capture_20261024_125300/ram_states/ram_00008.bin` | Scheduler delay bytes `$0001,$0005,$0009,$000D,$0011,$0015` are `01 01 00 00 00 01`; `$0005` is 1, not 8. `$0055` is 8. |
| Silent PC/write trace, source frames 0–12 | Startup RAM clear advances `$0001` from `$00` through `$08` via `INC $01` at `$C675` (PC after increment `$C677`); setup clears the pointer at `$A231`. `$0001=$08` is the eighth 256-byte RAM-clear page, not a frame delay. The first worker dispatch is frame 8/cycle 224,570; the first NMI is frame 9/cycle 238,264, followed by ready-latch store `$A133` at 240,148 and scheduler scan at 241,107. See `reference/diagnostics/opening_first_nmi_anchor_audit_20261024.md` and raw records in `reference/diagnostics/cold_start_nmi_boot_20261025_192122/`. |

Frame 7's end snapshot has `$0005=00`; the transient `$FF` installed by
`$9F69` is not present in that sampled end state. By the end of source frame 8,
the worker has run and yielded, so `$0005=01`. The dispatch trace and RAM
snapshot are consistent with immediate dispatch of the `$FF` task followed by
a one-tick yield; they do not show an eight-tick delay in slot `$0005`.

## Finding on the “slot-5 delay of 8”

**The supplied ROM does not install an eight-tick delay in worker slot `$0005`**:

1. `$8464` selects X=`$05`, constructs the worker continuation, and calls
   `$9F69`.
2. `$9F69` writes `$FF` to `$0005`, which `$9EED` treats as immediately due.
3. Worker setup writes `$08` to `$0055` as text speed.
4. The observed frame-8 `$0005` snapshot is `$01`, and the observed `$08` is
   `$0055`. The separate frame-4/5 `$0001=08` value is not `$0005` and lacks a
   source-PC write trace.

So the exact first-dispatch timestamp at source frame 8 is **observed in the
power-on replay**, and the source explains that the newly registered `$FF`
worker runs when the cooperative scheduler next gets control. There is no
source literal or timer initialization that says “wait 8 frames before first
cutscene command.” Reproducing frame 8 requires matching the reset, startup,
NMI-ready, and first-yield phase; do not encode an artificial slot-5 delay of
8 to force that capture alignment.

The PC/write trace now resolves the meaning and producer of `$0001=$08`, and
hooks the first `$84E7` worker dispatch, first NMI, ready-latch store, and next
scheduler scan. The observed first command precedes the first NMI. Godot now
models a non-NMI initial ready scan at frame 8 and an NMI-ready release at
frame 9, matching that order; the main-task `$9FA8` yield is still represented
at the traced frame boundary rather than instruction by instruction. The trace
is not a complete reset-to-first-instruction 6502 execution and does not
measure a pixel-level PPU edge. This modeling limit does not change the
source-confirmed `$0005=$FF` worker registration behavior.

## Reference listing and limits

The code guide is the pinned
[`bank_80.asm` listing at commit `ec03cf06e6bdae0bcd232e3a423e9d259757dc64`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/blob/ec03cf06e6bdae0bcd232e3a423e9d259757dc64/bank_80.asm).
The project audit reports all 7,406 byte values annotated for this bank match
the supplied ROM. This validates the inspected listing bytes, not every
comment or the complete disassembly. The opening script bank itself is left
blank in that public project and is decoded from the supplied Turkish ROM.

Local evidence used here:

- `reference/rom_extract/intro/annotated_disassembly_opening_audit.md`
- `reference/rom_extract/intro/cold_start_scheduler_tick_trace.md`
- `reference/rom_extract/intro/cold_start_observed_dispatch.json`
- `reference/rom_extract/intro/cold_start_ppu_timing_trace.md`
- `reference/diagnostics/opening_dispatch_full_20261024_150016/metadata.txt`
- `reference/diagnostics/audio_scheduler_trace_20261024_135139/metadata.txt`
- `reference/opening_timing_capture_20261024_125300/metadata.txt`

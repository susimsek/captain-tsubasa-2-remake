# E9 palette fade-up trace

## Scope and ROM identity

This note traces the cold-opening `E9` handler, its fade-up helper at `$997E`,
the scheduler yield at `$9FA8`, and the palette packet's NMI commit. It uses the
supplied Turkish ROM and saved quiet FCEUX captures only; no emulator was
started for this analysis, and no captured image or audio is a runtime asset.

- Full ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- The capture metadata's `rom_md5=eaf2b3745263efa4b1afd2b400f68dae` is the MD5
  of the ROM payload with its 16-byte iNES header removed. The complete file's
  MD5, including that header, is `93d14fb7962c54062be9734642fbe7bd`.
- For bank 0 at CPU `$8000–$9FFF`, file offset is
  `0x10 + (CPU address - $8000)`. Bank 2 at CPU `$A000–$BFFF` maps to file
  `0x4010 + (CPU address - $A000)`.

The synchronized bus trace is
`reference/diagnostics/synchronized_cycle_order_20261024_134001/`; its
metadata says the source-frame input is
`reference/opening_reference_capture/input_timeline.csv` and that the PPU
scanline/dot getter was available. The per-frame PPU/RAM snapshots are in
`reference/diagnostics/synchronized_cycle_order_20261024_154547/`. Both captures
report the same input timeline and ROM-payload MD5. Their PPU and RAM snapshot
files are byte-identical for every source frame 9–27. Frame numbering follows
the capture metadata: `source_frame` is the emulator frame after each
`frameadvance()`.

## ROM path

The cold-open script is in PRG bank 3 at file `0x6030` / CPU `$A020`; its bytes
begin `E8 01 F9 00 FB 01 8D E9 DF ...`. The `E9` at file `0x6037` / CPU `$A027`
dispatches to bank-0 handler `$8580` (file `0x00590`). The local handler bytes
are:

```text
$8580  A9 02          LDA #$02
$8582  20 A8 9F       JSR $9FA8
$8585  20 7E 99       JSR $997E
```

Thus the handler first yields with delay argument `$02`, then calls the fade-up
routine. The opening dispatch trace records `$E9` at script pointer `$A027`,
handler PC `$8580`, on source frame 10. Its next script pointer is `$A028`
(`$DF`), reached on source frame 27.

The 48 bytes at `$997E–$99AD` are present at file `0x0198E–0x019BD`. Their
control flow is:

1. Call `$9B07`, `$9AB8`, and `$9ADA`; load `$E9` into X and call `$C4B9`.
   These setup/bank-helper calls are visible in the source; this note does not
   assign additional effects to them.
2. If `$4A < $0F`, increment `$4A`; if `$4B < $0F`, increment `$4B`.
3. Call `$9A71` to build a 32-byte palette packet.
4. Call `$9FA8` with A=`$01`.
5. Add `$4A+$4B`; repeat from step 2 while the sum is below `$1E`, otherwise
   return.

The branch and counter operations are directly decoded from the local bytes:
`$998C` checks/increments `$4A`, `$9994` checks/increments `$4B`, `$999C`
calls `$9A71`, `$999F–$99A1` yields with `$01`, and `$99A4–$99AD` loops while
the sum is less than `$1E`. In the observed cold start the two counters begin
at zero and stay equal, so this loop makes 15 palette-building passes, ending
at `$0F/$0F`.

The raw fade routine bytes, as read from the verified local bank-0 ROM, are:

```text
$997E  20 07 9B 20 B8 9A 20 DA 9A A6 E9 20 B9 C4
$998C  A5 4A C9 0F B0 02 E6 4A A5 4B C9 0F B0 02 E6 4B
$999C  20 71 9A A9 01 20 A8 9F A5 4A 18 65 4B C9 1E 90 DF 60
```

`$9FA8` is at bank-0 file `0x01FB8`; its first instruction is `STA $19`. The
cooperative-scheduler trace identifies this helper as recording a task delay,
saving the task state, and yielding. Its argument is a scheduler delay, not a
direct PPU write or a script-byte count. The `$02` call is before `$997E`; each
fade pass makes a separate `$01` call. Frame-end snapshots show `$4A/$4B=0`
through frame 11, then `$01/$01` at frame 12, consistent with the initial
delay before the first pass. The snapshots do not expose the precise CPU-cycle
phase at which either delay returns.

At bank-0 file `0x01A81`, `$9A71` opens a packet with count `$20`, address
`$3F00`, and then processes 32 source colors beginning at RAM `$062A`. It uses
`$4A` for the first 16 entries and `$4B` for the next 16. Each pass masks the
source color with `$30`, adds the corresponding counter, and calls `$9AA2`
(file `0x01AB2`). `$9AA2` indexes the 64-byte ROM lookup table at `$9EA2`
(file `0x01EB2`), combines that lookup result with the source color's low
nibble, and appends the result to the packet. The counters are fade inputs;
because the ROM lookup is discrete, they do not imply 15 distinct displayed
palette states.

## NMI transfer and observed frame sequence

During the opening's sampled NMI mode, `$C76E` routes through `$C421`, maps
bank 2, and calls `$A000` (bank-2 file `0x04010`). That consumer reads the
`$05E8` packet and writes its payload through `$2007`; its data loop at
`$A03C` is at file `0x0404C`. In the traced route the queue transfer precedes
the scheduler-ready bit at `$A12F` (file `0x0413F`). Therefore `$997E` stages
the next palette in RAM before yielding, while the NMI commits the previously
staged packet before releasing the cooperative scheduler.

For each source frame 13–27, the synchronized bus log records exactly 32
`$2007` writes from PC `$A03C`. The bytes match the preceding frame's
`$05E8` packet payload byte for byte, and the frame-end PPU snapshot at
`$3F00–$3F1F` matches that same payload. The uploads run during vblank on PPU
scanlines 246–250. On frame 13, for example, `$2001` is masked at cycle 608,
the PPU address is set to `$3F00`, the 32 bytes are written at cycles 649–1125,
and `$2001=$1E` is restored at scanline 251, dot 112. The same 32-byte
transfer and scanline range recur through frame 27; small cycle/dot offsets
vary across frames.

| Source frame(s) | End-frame `$4A/$4B` | Script pointer | Palette evidence |
|---|---:|---:|---|
| 9 | `$00/$00` | `$A022` | PPU palette is all `$0F`; the bus trace shows 32 `$0F` palette writes from `$A03C`. This is before the `E9` dispatch. |
| 10–11 | `$00/$00` | `$A027` | `E9` is active; PPU palette remains all `$0F`. |
| 12 | `$01/$01` | `$A027` | First `$20 00 3F` fade packet is staged in `$05E8`; the PPU palette is still all `$0F`. |
| 13–26 | `$02/$02` through `$0F/$0F` | `$A027` | PPU palette equals the previous frame's staged packet; each frame stages the next counter level. |
| 27 | `$0F/$0F` | `$A028` | PPU palette equals frame 26's final `$0F/$0F` packet; `E9` has returned and the script has advanced to `$DF`. |

The source-frame-13 PPU snapshot is the first non-`$0F` palette snapshot in
this interval. The byte-level checks establish a one-NMI delay from packet
staging to the PPU state. They do not by themselves specify the exact first
visible pixel or a complete raster rendering; see
`cold_start_visible_edge_audit.md` for the separate screenshot-aligned visible
edge observation.

## Evidence limits

- The call arguments, loop bounds, counter mutations, palette-builder inputs,
  lookup-table address, NMI consumer, and packet-to-snapshot transfer are
  source-byte or capture-backed.
- The two-release pre-wait is directly present as `LDA #$02; JSR $9FA8`; the
  frame snapshots bracket its effect but do not timestamp the exact scheduler
  return within a video frame.
- The setup helpers called at `$997E` are not fully decoded here.
- PPU/RAM captures and bus events are execution evidence only. Do not use them
  as packaged visual or audio assets.

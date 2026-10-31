# Mapper shadow `$0022` source audit — 31 Oct 2026

## Question

Can the live caller at `$80F7` use the reset-derived MMC3 select shadow value
`$0022=$00` after the ID-1 Select cleanup?

## ROM identity and mapping

- Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- iNES: 16-byte header, mapper 4, 16 × 16 KiB PRG, 16 × 8 KiB CHR, no trainer.
- The fixed PRG page used below is 8 KiB bank `$1E`, file base `0x03C010`,
  mapped at CPU `$C000-$DFFF`.

## ROM-backed facts

1. Reset reaches `$C64E` and clears internal RAM `$0000-$07FF` through the
   eight-page `$91 $00` indirect-indexed loop. The exact loop is already
   preserved and hash-checked in
   [`reset_ram_clear_C64E_C679.bin`](fresh_kickoff_entry_context/reset_ram_clear_C64E_C679.bin).
2. The reset tail then executes `$C6A0 LDA #$00; $C6A2 STA $0022`. The
   instruction bytes are `A9 00 8D 22 00`, file offset `0x03C6B0`, in bank
   `$1E`; `$C6A2` is at file offset `0x03C6B2`. The enclosing `$C69C-$C6A5`
   span is 9 bytes with SHA-256
   `ad02ea7c93b36c1dbd3b0d2c3052ade1f9e57a8960b2e3a31c31449fcf0c84a3`.
3. A second fixed-bank initialization entry at `$C400` includes
   `$C40F LDA #$00; $C411 STA $0022`. Its source span `$C400-$C421` is 33
   bytes at file offset `0x03C410`, SHA-256
   `fe252abf1bfbcad7f043990a2af986c603fcbdd29e6610b39ef4195f4f6f3169`.
   That entry continues through mapper setup and jumps to `$A200`; the startup
   trace below confirms it executes on this cold-start route at frame 6.
4. The NMI path at `$C421` reads `$0022` at `$C42E`, ORs `$07`, and writes the
   result to mapper register `$8000`. It does not write `$0022`. The checked
   `$C421-$C43E` source span is at file offset `0x03C431`, SHA-256
   `e93af59338786796d368a6073e0e9bb4ae8eb8f3a2f3f560b46f63ada58ea9f7`.
   Existing cold-start evidence describes this NMI path in
   [`cold_start_palette_nmi_commit_trace.md`](../intro/cold_start_palette_nmi_commit_trace.md).

## Writer sites and route evidence

The ROM-backed writers observed on cold start are:

| Source instruction | PRG mapping / file offset | Source operation | Trace observation |
| --- | --- | --- | --- |
| `$C670` | bank `$1E`, `0x03C680` | `STA ($00),Y` in the reset RAM clear; at this iteration the destination is `$0022` | Frame 4, callback PC `$C672`, `$01 -> $00` |
| `$C6A2` | bank `$1E`, `0x03C6B2` | `STA $0022` after `LDA #$00` | Frame 4, callback PC `$C6A5`, `$01 -> $00` |
| `$C411` | bank `$1E`, `0x03C421` | `STA $22` after `LDA #$00` in the `$C400` initializer | Frame 6, callback PC `$C413`, `$01 -> $00` |

The cold-start write rows are retained in the local, ignored validation output
`reference/diagnostics/kickoff_select_cleanup_counters_20261031_004228_utc/mapper_shadow_writes_startup.csv`.
For the exact muted route replay, the signature-checked checkpoint was loaded
at source frame 4692, then frames 4693–7300 were traced twice. Each pass
recorded zero writes to `$0022`; the pass hashes match. The relevant summary is
`validation.json` in that local output directory. The runner and instrumentation
are `tools/diagnostics/run_kickoff_select_cleanup_counter_trace.py` and
`tools/diagnostics/trace_kickoff_select_cleanup_counters.lua`; the ignored
output can be regenerated. These are observation-only records, not runtime
inputs or shipped assets.

A literal-operand scan also found raw `STA/STX/STY $22`-like byte patterns in
text/table/CHR data (for example file offsets `0x003C6E`, `0x01ABA5`,
`0x024CF7`, `0x045951`, and `0x0474D5`). They are not evidence of executable
stores. The exact-route trace covers writes made by direct, indexed, and
indirect CPU stores alike, but only for its recorded input and frame window.

## Conclusion and boundary

ROM execution establishes `$0022=$00` during reset. The two-pass trace
corroborates that `$0022` remains unchanged from checkpoint frame 4692 through
frame 7300 on this exact KICK OFF / ID-1 cleanup route. Therefore the bounded
route's mapper shadow is zero at the `$80F7` caller, without taking a value from
a RAM snapshot. This does not prove the value for other inputs or paths; a
general runtime must still carry the reset-owned state and model any reachable
writer before reusing it.

## Runtime consequence

For the current bounded route, `$0022` is no longer an unresolved seed: model it
as reset-owned zero, not as injected endpoint state or copied trace RAM. The
`$C400` initializer also writes zero at frame 6 on this cold-start route.
Other `$80F7->$C4B9` inputs still need their own source-path proof before the
same value can be reused.

## Godot route integration — 31 Oct 2026

The production route now builds `$0022` from the hash-checked reset zero-fill,
reset-tail store, and `$C400` initializer bytes. A logical JSR frame supplies
the `$80F7->$C4B9->$80FA` return path without copying a captured stack page or
inventing an absolute SP. The bounded mapper helper produces `$8000=$07` and
`$8001=$02`, then the source selector runs `$80FA->$A20F` through `$80FD` using
logical frames. Its 4,944-byte PRG-RAM copy and 11 match-zero roster writes are
checked by the focused integration verifier. The observation trace validates
the route-specific `$0022` invariant; it is not read by either runtime source
component.

The Godot route currently stops before caller setup/normalization at
`$80FD-$8112`. Physical stack placement, applying the mapper writes to the live
rendering state, ID-2 dispatch, field output, and exact CPU/NMI timing remain
unresolved. The selector's ROM-derived RAM projection does not by itself prove
visible same-input output.

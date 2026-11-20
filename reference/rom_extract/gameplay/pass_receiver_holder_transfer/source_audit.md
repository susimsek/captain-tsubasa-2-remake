# PASS Confirmation and Holder-Transfer Source Audit

## Claim and source identity

The recorded PASS confirmation reaches a ROM waiter at `$D70C`. After that waiter returns, the field update path later commits the selected receiver from `$05FC` to holder `$0441`, invokes the holder-coordinate copy, maps banks `$1A/$1B`, requests scenario `$1C`, resets the stack, and jumps to the field-entry routine at `$E0DF`. The extracted instructions establish this caller sequence; they do not by themselves explain the intervening movement or execute the complete route.

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- iNES mapper 4 / MMC3; 16 PRG 16-KiB units (32 switchable 8-KiB PRG banks).
- Observation: FCEUX 2.7.0, NTSC, NewPPU, muted. Frame labels are emulator frame advances, not physical NES timing.
- Trace source: `/tmp/ct2_first_pass_action_next_menu/events.csv` and `writes.csv`; the retained route summary is [`first_pass_action_trace_20261110.md`](../first_pass_action_trace_20261110.md). Temporary `/tmp` logs are not project runtime assets.

Run `python3 tools/gameplay/extract_pass_receiver_holder_transfer_sources.py` to re-extract and verify the ROM bytes and existing dependency hashes.

## Extracted code spans

| ROM location | File offset | Size | Role |
| --- | ---: | ---: | --- |
| Bank `$1E`, `$D70C-$D716` | `0x03D71C` | 11 bytes | Waiter call, `$062D` clear, stack unwind, and return |
| Bank `$1E`, `$DE6C-$DE95` | `0x03DE7C` | 42 bytes | Holder commit and scenario/field-entry caller, including branch target `$DE96` |
| Bank `$1A`, `$801E-$8020` | `0x03402E` | 3 bytes | Vector to `$8B4A` |
| Bank `$1A`, `$8B4A-$8B68` | `0x034B5A` | 31 bytes | Initial target prefix; full event routine is outside this extraction |

Hashes and exact bytes are recorded in [`manifest.json`](manifest.json). The `$D70C` span is in the observed `$C000-$DFFF` mapping of bank `$1E`; the `$801E` and `$8B4A` spans are in the observed `$8000-$9FFF` mapping of bank `$1A`.

## Trace-backed sequence

1. At frame 9076, event `$D852` precedes `$D70C` by 52 FCEUX-reported cycles. The `$D70C` event has `$SP=$4A`, `$A=$78`, `$05FC=$0A`, `$0638=$78`, `$062D=$81`, and holder `$0441=$06`.
2. `$D70C` is `JSR $CC46; LDA #$00; STA $062D; PLA; PLA; RTS`. The shared waiter source is already preserved at `field_entry_renderer_wrapper/fixed_shared_waiter_CC46_CCD2.bin`. The frame-9086 trace records `$D714` with `$SP=$4A` and `$062D=$00`; the next event in that frame is `$E709` with `$SP=$4C`. This is consistent with the waiter return, the two explicit pops, and the RTS returning into the field-update path. The temporary trace does not include stack-page bytes at these events, so it does not independently prove the popped return word.
3. Field-worker events then run at `$A103`. The write trace shows `$05FE` moving from `$77` to `$76`, `$75`, …, `$6C` on frames 9144–9154. At frame 9155, the writer callback reports `$05FE: $6C->$78` at `$E7AF`; the same frame reports `$0441: $06->$0A` at `$DE76`. In the ROM bytes, the `$0441` store is the instruction at `$DE73`, so the callback PC is the following instruction address. The `$DE76` event has `$A=$0A`, `$SP=$50`; the subsequent event is `$E708`.
4. Static ROM flow from `$DE76` is `JSR $E6EC` → set mapper shadows `$24/$25` to `$1A/$1B` and call `$CE2D` → `JSR $801E` (bank-$1A vector to `$8B4A`) → load `$1C` and `JSR $CBB0` → set `$SP=$50` → `JMP $E0DF`. Existing verified sources cover `$E6EC`, `$CD7C/$CDE2`, `$CE2D`, `$CBB0`, and the `$E0DF` entry. The first `$8B4A` instructions call `$8B9C` and `$C624`; this package does not decode those callees or the full bank-$1A routine.
5. The trace next observes holder `$0441=$0A` at the first `$D5EA` wait on frame 9600. The 445-frame interval between the `$DE76` event and this wait, including scenario `$1C`, its scheduler/renderer work, and field updates, is not proven by the spans in this package.

## Source dependencies

`manifest.json` lists and hash-checks these already extracted dependencies:

- `$CC46-$CCD1`: shared task/PPU waiter, which must complete before `$D70F` resumes.
- `$E6EC`, `$CD7C`, `$CDE2`: holder record lookup and coordinate-to-field-tile copy.
- `$CE2D`: mapper-bank write helper.
- `$CBB0`: scenario queue writer.
- `$E0DF`: field renderer entry.

The `$801E->$8B4A` vector dependency is extracted locally, but the target's `$8B9C` and `$C624` helpers and the entire routine return path remain unresolved here.

## Limits

- This is ROM source documentation, not a Godot implementation or proof that the live Godot route reaches these spans.
- The trace confirms the holder write and subsequent `$D5EA` wait, but the source path that updates `$05FE` between frames 9086 and 9155 is not decoded here. The source reason and full cadence of the longer 9155-to-9600 interval also remain unverified.
- FCEUX hook cycles and frame labels do not establish physical NES CPU/PPU sub-frame timing.
- No pixels, WAV, or emulator state are packaged as runtime content.

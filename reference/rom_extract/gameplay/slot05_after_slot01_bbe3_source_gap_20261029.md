# Slot-$05 Resume After Slot-$01 — $BBE3 Source Gap — 2026-10-29

> Historical checkpoint: the $BBE3 source gap was closed by adding the existing
> hash-checked row resource and replaying the live worker through $ED 01 $FC.
> The current stop is documented in
> [slot05_live_ed01_row_bbe3_20261029.md](slot05_live_ed01_row_bbe3_20261029.md).

## Result and stop

The production runner accepts slot $05's actual pre-dispatch record
00 46 18 19, selected after slot $01 returns. It restores the real
$8889 continuation and runs 222 source instructions, then stops at the first
ROM read not covered by the worker source manifest:

- instruction PC $89A0
- requested CPU address $BBE3
- active ROM bank $19
- stop reason: the byte is absent from the hash-checked source spans

The active slot-$05 RAM source pointer remains $003E/$003F=$BD9C. $BBE3
is the address requested by the source worker as it advances past the
preserved $BBE0 row; it was not written into RAM or supplied as a synthetic
pointer. No later row, task callback, or scenario enqueue was executed.

## Live dispatch state

The selected task record before dispatch was 00 46 18 19 at $CB0F.
The scheduler restored:

| State | Value |
| --- | --- |
| A / X / Y / SP | $0F / $0F / $03 / $4A |
| PC | $8889 |
| Mapper banks | $18 / $19 |
| MMC3 selector | $07 |
| Stack-page offsets $40-$4F | 00 81 8C B9 52 A8 89 03 0F 88 88 98 EF 1D 1C D0 |
| $003E-$003F | 9C BD — live pointer $BD9C |
| $003C | $B0 |
| $0629 | $00 |
| $0516 | $00 |
| $05F7-$05F8 | B4 00 |

The worker's attempted read of $BBE3 is a missing ROM-source byte, not a
failed slot-$05 dispatch. The worker returned no adopted writes
(memory_writes is empty); scheduler RAM remains byte-identical to the
worker's live input, including $0629=$00. No scenario $35 setup/enqueue was
requested or performed.

## Source contract

ROM SHA-256:
4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097.

The worker manifest is
[fresh_bank18_worker_prefix/manifest.json](fresh_bank18_worker_prefix/manifest.json),
SHA-256 afb902c0a8b3780f546ee61b2838e378b272ade79cb4023ac40d3419c165c4dc.
It contains descriptor row bytes $BBE0-$BBE2 (ED 00 FC) at file offset
0x033BF0, but that span ends exclusively at $BBE3. Its source file is
bank19_resumed_worker_descriptor01_row00_BBE0_BBE3.bin, SHA-256
47e95b03911de543f1f251f12b38d11389dfca4b50b97065336b5b070e2ac5b7.
The attempted next byte $BBE3 is therefore outside the current manifest.

The current exact stop is before any claim about the next row. Required
follow-up source evidence is the ROM-mapped bank-$19 data beginning at
$BBE3, sufficient to identify its row terminator/callback and the source
transition that consumes it. The present live $0629=$00 must remain an
input to that later caller analysis; it must not be replaced with scenario
$35 or an assumed branch.

## Verification

Focused verifier:
[verify_rom_slot01_resume_after_queue_nmi.gd](../../../tools/diagnostics/verify_rom_slot01_resume_after_queue_nmi.gd)

Command:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_rom_slot01_resume_after_queue_nmi.gd
```

Result: PASS on Godot 4.7.2. The verifier rebuilds the source route from
project-owned ROM extracts, consumes one caller-labeled NMI, executes the
source-selected slot-$01 cycle, then dispatches the selected slot $05.
It confirms the $89A0->$BBE3 stop, zero worker writes, and unchanged live
$0629. The NMI label is not a physical cadence measurement.

No runtime route, source manifest, or extracted-byte file was changed for
this transition.

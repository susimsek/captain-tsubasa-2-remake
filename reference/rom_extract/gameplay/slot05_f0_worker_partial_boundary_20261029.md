# Slot-$05 F0 worker yield boundary — 2026-10-29

## Scope and verification

This report supersedes the earlier stop at `$89A0->$BBDE`. It follows the
actual slot-$05 yielded dispatch selected after the second caller-supplied NMI,
adds the missing row-one bytes to the worker source package, completes the live
`$F0/$FC` row from ROM bytes, and stops at `$C515` before the task-save
trampoline.
No FCEUX session, trace RAM, emulator screenshot, or captured WAV was used.

Canonical Turkish ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

Focused verifier:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_slot05_f0_worker_boundary.gd
```

The verifier passed. It derives the route from the project context builder and
the live scheduler; the production route API recognizes the source `$C515`
yield boundary, asks the scheduler to replay the worker's source writes, and
returns before executing `$CB0F`.

## ROM source spans

Worker package manifest:
[`fresh_bank18_worker_prefix/manifest.json`](fresh_bank18_worker_prefix/manifest.json),
SHA-256 `bc26416684826e4e5831acbcd82ee973332a46d4fcf4e4cc0f330ffa8e8378e2`.

The supplied ROM yields these spans (file offsets are in the iNES image):

| Source | CPU range | File offset | SHA-256 | Use |
| --- | --- | --- | --- | --- |
| `bank19_resumed_worker_text_row01_BBDE_BBE0.bin` | bank `$19` `$BBDE-$BBDF` | `0x033BEE` | `c2b693b8213b7fb3d64338c576d60acbde3663432f4c433a8a0627194a3df5d9` | Row one `$F0,$FC` |
| `bank18_resumed_worker_vector_tail_89D7_89DC.bin` | bank `$18` `$89D7-$89DB` | `0x0309E7` | `55dadf4bb6f12bdc4978f2c6dd0733a68b52715a28f81e3c83aed1e1e788286e` | Inline vectors including `$F0->$8B8B` |
| `bank18_f0_match_clock_handler_8B8B_8BD5.bin` | bank `$18` `$8B8B-$8BD4` | `0x030B9B` | `90eca873b94249d9b8c6b70885e9383a118c6af988ce56bd88301b07e912eb2e` | Match-clock callback |
| `bank18_f0_decimal_formatter_8C55_8C85.bin` | bank `$18` `$8C55-$8C84` | `0x030C65` | `5e8434b7ea9df80165514fcbde32a3800ac76e8ddd3d12c13c5e2428dedf836b` | Decimal formatting prefix |
| `fixed_division_dispatch_C51E_C521.bin` | fixed bank `$1E` `$C51E-$C520` | `0x03C52E` | `7b0a50829c23361f1f95e0b52657262d62358c50623da017b3c721ba27ba81e1` | Jump vector to divider |
| `fixed_division_16bit_CD3C_CD77.bin` | fixed bank `$1E` `$CD3C-$CD76` | `0x03CD4C` | `2d996c8e5e587175f76672794f405945b4c1c981fa6775cf93b8971f1f39a008` | Divider body |

The row bytes are exactly `F0 FC`. The inline callback vector at `$89DA/$89DB`
is `8B 8B`. The added spans are checked against manifest size, byte content,
bank, CPU range, file offset, and SHA-256 before the worker runs.

## Live input and executed path

The source scheduler selected slot `$05` at `$8889` after the second external
NMI. The worker received CPU `A/X/Y=$04/$04/$03`, `SP=$4A`, mapped banks
`$18/$19`, and MMC3 selector `$07`. The live fresh-period result independently
provides `$0027=$00` and `$05F7/$05F8=$B4/$00`; descriptor `$00` has no unresolved
token inputs.

The worker read row one at `$89A0`, entered the inline dispatch via
`$89B4->$C509`, and executed the ROM `$8B8B` match-clock callback. That callback
used `$8C55`, `$C51E->$CD3C`, and the source formatter/divider path. The live
path exercised only the needed zero-page `ROL` (`$26`), `CMP` (`$C5`), and
`SBC` (`$E5`) operations; these now use 2A03 carry/zero/negative semantics and
ROM-produced operands. It then returned through row-one `$FC` at `$8C52` and
reached `$C515`.

The worker stopped at the `$C515` yield-trampoline entry with 1,152 executed
instructions, 23 JSR records, 277 ordered RAM writes, and zero mapper writes.
The four `$89A0` token reads and two `$8C52` callback entries establish both
`EF/FC` and `F0/FC` rows. No bytes after `$BBDF` were needed on this live branch.

## Worker boundary adoption

The scheduler replays the worker's ordered writes over the live RAM and stack
inputs, then adopts the resulting `A/X/Y/P`, known-P mask, `SP/PC`, and bank
pair at `$C515`. RAM SHA-256 changed from
`b8351bbe374d4964775f86df66d23e0a5ce289f0a2f82ef0a0aab3f4f45c1b37` to
`5a94d339a95af8e34bea2f8ecd965fcc1f23a2b2f5f1beb6ea0a9d1c53c9c044`; stack
SHA-256 changed from
`838620484f6d1bc9dfd324713285d1bf131bbe8ba5a5ab9bb840c2b53aac0835` to
`374a39f93fab2f9135d3b388e7844cc9776b84cbc17223bbfe0b0d7d4197c839`.
The output bytes `$04A5-$04B4` are
`07 61 22 AA 00 00 00 00 00 AB 07 81 22 AA 36 33`; they are ordered
worker-produced writes, not a packet copied from the descriptor builder.

At this report's boundary, the route API adopted this state at `$C515` and
stopped before executing the trampoline. The follow-up now applies the
ROM-checked `$CB0F` save and scheduler scan, then stops at slot `$09`'s yielded
pre-dispatch boundary. See
[`slot05_cb0f_scheduler_scan_20261029.md`](slot05_cb0f_scheduler_scan_20261029.md)
for the current route result and verifier evidence.

## Worker result contract

This worker result provides source-produced RAM, stack, `A/X/Y/P`, known-P mask,
`SP`, and mapper state at `$C515`. The descriptor packet decoder does not
provide these worker effects. The next runtime consumer begins from the
selected slot-$09 scheduler boundary documented in the follow-up report.

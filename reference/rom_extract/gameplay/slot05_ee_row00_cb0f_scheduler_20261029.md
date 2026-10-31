# Slot-$05 `$EE` Row to `$CB0F` Scheduler Boundary — 2026-10-29

## Result

Starting from the adopted live slot-$05 worker state at `$C515` after `$BD9C: EE 00 FC`, the route now applies the hash-checked `$CB0F` task-save semantics and continues the ROM-ordered scheduler scan. It stops at the next selected-task boundary before dispatching slot `$09`.

The save produces slot-$05 record `01 46 18 19`: delay `$01`, saved SP `$46`, banks `$18/$19`. The worker's live X/Y values (`$0F/$03`) and the preexisting `$8886 JSR $C515` frame (`$8888`) are preserved on the saved stack. The scheduler scans only slot `$09`, decrements its delay `$01->$00`, and selects its yielded `$CB0F` context. It does not dispatch slot `$09`, generate another NMI, or execute a task body.

## Source and route contracts

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Slot-$05 worker manifest: `reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json`, SHA-256 `afb902c0a8b3780f546ee61b2838e378b272ade79cb4023ac40d3419c165c4dc`.
- Scheduler manifest: `reference/rom_extract/gameplay/task_context/manifest.json`, SHA-256 `eee205ead0ebf8bca75fa760896fc8c0ea13f5e93176d3223795e5afbf28c719`.
- `$C515` is hash-bound as `4C 0F CB` (`JMP $CB0F`), CPU `$C515-$C517`, file offset `0x03C525`, SHA-256 `86545169e2c9775f9eb73d63e59343ec9fff70a55fb97b17b22b39ab2fcd1d1e`.
- `$CB0F` is hash-bound as `85 7F 8A 48 98 48 A6 00 A5 24 95 02 A5 25 95 03 A5 7F 95 00 8A A8 BA 96 01 A6 00 4C A5 CA`, CPU `$CB0F-$CB2C`, file offset `0x03CB1F`, SHA-256 `b6377644890b9cd6671e4e63f48da4dfe1bd4975870bb531cb684ee7aeda07fc`.
- `$CAA5` scan logic is part of the independently hash-checked source span `$CA97-$CAE6` in the scheduler manifest.

The route validates the live `$8886 JSR $C515` call record and `$8888` stack return word, then passes the worker's actual A/X/Y/SP and bank pair to `yield_at_verified_callsite()`. That scheduler method applies the documented `$CB0F` effects against the adopted task context. This is a bounded source-semantic save/scan model; it is not cycle-accurate instruction-by-instruction execution of the fixed-bank handler.

## Exact state at the stop

At `$C515` before the save, the live worker state is A=`$01`, X=`$0F`, Y=`$03`, P=`$20`, SP=`$48`, banks `$18/$19`. Its active worker result has ROM hash and manifest provenance checked by the continuation.

After `$CB0F`:

- Slot `$05` task record: `01 46 18 19`; saved PC boundary `$CB0F`; saved SP `$46`.
- `$007F=$01` from the live worker A value.
- Stack `$0147-$014A`: `03 0F 88 88` (saved Y, X, and the original JSR return word).
- Scan decision: `YIELDED_RESUME`; checked slots: `[$09]`; cursor: `$09`.
- Slot `$09` is selected with record `00 76 18 19`, ready delay zero, yielded phase, pending resume `YIELDED_TASK`, and PC `$CB0F`.
- Comparing scheduler RAM immediately before and after the scan, the only change is `$0009: 01 -> 00`.

## Verification

Focused verifier: `tools/diagnostics/verify_rom_slot05_ee_row00_cb0f_scheduler.gd`.

Run:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_rom_slot05_ee_row00_cb0f_scheduler.gd
```

It passed under Godot 4.7.2. The verifier rebuilds the route from its ROM-derived context, reaches the live `$EE` worker yield, applies the `$CB0F` save, and asserts the saved task record, stack bytes, exact scan slot/write, and undispatched slot-$09 boundary.

## Limits

The preceding `$EE` formatter leaves the live descriptor pointer at `$BD9C`; `$BBE3` remains only an address encoded in ROM descriptor metadata and was not forced into runtime RAM. This transition stops at slot `$09`'s pre-dispatch boundary. No new NMI was supplied, no slot-$09 worker was run, and no later row or visible match output is established.

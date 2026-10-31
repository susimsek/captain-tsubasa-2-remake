# Slot `$11` Actor Worker: First Yield

## Result

After the map-`$42` slot-`$15` task finishes at `$CAF7`, the scenario `$35`
actor worker is seeded through `$ED2A->$CAE7` with actor parameter `$73`.
The seed prepares slot `$11` with stack pointer `$C8` and bank `$18`. The
first `$CB0F` event at cycle 4875 is a preceding caller-side yield, not the
actor worker yield. The actor worker's first yield is at frame 8480 / cycle
5141, with registers matching the bank-`$18` source prefix ending at
`$8047 JSR $C515`. The existing trace does not directly log the executed
`$8047` caller or active task byte `$0000`; that final linkage remains a
source/register attribution, not an instruction-trace observation. This
report stops at the actor worker's first yield, before it resumes. It does not
establish later actor updates, OAM output, visible pose, or route behavior.

## ROM source

The supplied ROM is `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`,
SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The fixed PRG bank `$1E` maps CPU `$C000-$FFFF` to file offset `0x03C010+`.

| CPU span | File offset | Bytes / SHA-256 | Role |
|---|---:|---|---|
| `$ED15-$ED2C` | `0x03ED25` | `C9 FF F0 14 8D EA 05 A2 11 A9 C8 95 01 A9 18 95 02 A9 7F A0 FF 20 E7 CA`<br>`61ef48dd58901f95f2c20f7f4a8bc1bb850221cb403f6bfbd52a65a12e33f551` | With `$0529 != $FF`, stores the parameter at `$05EA`, sets slot `$11`'s stack pointer to `$C8` and bank to `$18`, then calls `$CAE7` at `$ED2A`. |
| `$8000-$8049` (bank `$18`) | `0x030010` | 74 bytes, SHA-256 `2187af6881ea2f4e7eb16c0c5550bb24ead076be918d429d8ab63564ed8fd46c` | Entry jumps to `$800F`; setup reads the parameter-selected pointer, clears worker fields, sets `$05E3=1`, then reaches `$8047 JSR $C515`. |
| `$9306-$9307` (bank `$18`) | `0x031316` | `42 9F`<br>`03f3c4278cc253614b622fa856993e8b325eb061a29e54685038771778377938` | Parameter `$73` selects pointer `$9F42` from the table based at `$9220`; the setup leaves `X=$42`, `Y=$E7`. |
| `$CAE7-$CAF6` | `0x03CAF7` | `48 98 B4 01 99 01 01 68 99 02 01 A9 FF 95 00 60`<br>`139a8a1b3241ae60cebf1057463d3947c20f219b728ab98e2429ee2a0f3e3a55` | Seeds the task: writes the caller's `$FF/$7F` words to the stack selected by `$C8`, marks `$0011=$FF`, and returns. |
| `$CB0F-$CB2C` | `0x03CB1F` | `85 7F 8A 48 98 48 A6 00 A5 24 95 02 A5 25 95 03 A5 7F 95 00 8A A8 BA 96 01 A6 00 4C A5 CA`<br>`b6377644890b9cd6671e4e63f48da4dfe1bd4975870bb531cb684ee7aeda07fc` | Saves a yielded task and returns to the fixed-bank scheduler. |

The scenario record is `02 3A 8F 73`: wait `$02`, callback `$3A`, actor
selector `$8F`, parameter `$73`. The existing scenario audit records this
actor launch in frame 8480 and documents the `$ED15-$ED2D` launch path
([scenario event and continuation audit](first_command_scenario_event_continuation_audit_20261028.md)).
The seed and yield spans are also recorded in the
[`task_context` manifest](task_context/manifest.json).

## FCEUX evidence

The muted FCEUX 2.7.0 NTSC/NewPPU trace starts from a signature-checked
frame-8399 checkpoint and repeats the route twice. These events match in both
passes; the event CSV records the PRG bank numerically (`30` = `$1E`).

| Pass-1 event | Frame / cycle from frame start | PC / bank | A/X/Y/P | Route state |
|---|---:|---|---|---|
| Slot `$15` finish | 8479 / 5034 | `$CAF7` / `$1E` | `$51/$40/$10/$20` | Scenario `$35`, callback `$3A`, animation `$8F`, parameter `$73`. |
| Slot `$11` seed entry | 8480 / 4421 | `$CAE7` / `$1E` | `$7F/$11/$FF/$A0` | Scenario `$35`, wait `$02`, callback `$3A`, command `$02`, animation `$8F`, parameter `$73`, stream index `$06`, script pointer `$B7D4`. |
| Caller-side yield after seed | 8480 / 4875 | `$CB0F` / `$1E` | `$01/$11/$C8/$20` | Precedes actor-worker dispatch. The hook omits active task byte `$0000` and CPU SP, so this event's exact task owner is unknown. |
| First actor-worker yield | 8480 / 5141 | `$CB0F` / `$1E` | `$01/$42/$E7/$20` | Registers match the `$800F->$8047` bank-`$18` setup for parameter `$73`; repeated identically in the second pass. |

The seed event is at absolute cycle `252513285`; the caller-side yield is at
`252513739`; the actor-worker yield is at absolute cycle `252514005`. The
trace hooks `$CAE7`, not `$ED2A`, and hooks `$CB0F` without logging active task
RAM `$0000` or CPU SP. Thus `$ED2A` and `$8047->$C515` are supported by the
hash-checked source bytes and matching live register states, but their exact
instruction-level execution is not directly captured.

Trace files: [`callback_events.csv`](../../diagnostics/first_command_callback_state_20261028_061906_utc/callback_events.csv),
[`callback_events_repeat.csv`](../../diagnostics/first_command_callback_state_20261028_061906_utc/callback_events_repeat.csv),
and [`metadata.txt`](../../diagnostics/first_command_callback_state_20261028_061906_utc/metadata.txt).

## Stop boundary

The source-supported actor-worker boundary is `$CB0F` at frame 8480, cycle
5141. The worker's resumed body is not executed here, and no visible actor
output is verified. A decisive next trace should add hooks at `$800F`, `$8047`,
`$C515`, and `$CB0F`, logging CPU SP, RAM `$0000`, and slot `$11` bytes.

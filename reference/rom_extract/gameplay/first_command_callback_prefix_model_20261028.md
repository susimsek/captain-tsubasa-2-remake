# First-command scenario/callback source prefix model — 2026-10-28

## Scope

This diagnostic-only model connects the preserved bank-$10 scenario `$44`
root continuation to the first bank-$0B callback dispatch at `$8327`. It tracks
the source byte cursors and the root continuation depth. It deliberately stops
at handler entry because the route must supply the incoming shared `$05CD` and
the cooperative callback task/worker state. It is not used by
`KickoffRouteRuntime` and is separate from the six-slot task-context model.

The model also checks the bounded `$F094` increment/stop loop inside the
bank-$1F `$F015` producer for an explicitly supplied initial A. This is a
separate source fact: the code proves how a caller-provided A advances; it does
not prove that the `$8327` callback directly calls `$F015` or establish the
route caller's initial A.

## Source-derived prefix

Supplied ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

1. Scenario `$44` is the five-byte bank-$10 stream at CPU `$B7D5`, file
   `0x0237E5`: `02 70 5C F0 FB` (SHA-256
   `22c0290ec8b82bd06eb69bd51a8d8617181cf2c5bbf52b790ea62102e0c71e0f`).
   The record occupies offsets 0–3, so its source cursor advances from 0 to 4.
   The root `$FB` is at offset 4; after it, the cursor is 5.
2. Fixed-bank `$EC2E` clears continuation depth `$0522` to zero while leaving
   `$051A–$0521` payload bytes untouched. The existing
   `Bank10ScenarioContinuationStack` applies this source rule. With depth zero,
   `$FB` takes the root terminator path `$80CF`; the outer CPU/task return is
   not modeled.
3. The scenario record's `$0524=$70` selects the bank-$0B callback pointer
   entry at `$87F6` (file `0x0168E6`), which resolves to `$8B38`. Its bounded
   stream, file `0x016B48`, is `06 00 56 02 00 80`; the next pointer `$72`
   resolves to `$8B3E`, bounding these six bytes.
4. At `$814C` (file `0x01615C`), the callback reader initializes `$3A=0`.
   The first byte at offset 0, `$06`, becomes `$0525`. The byte at offset 1,
   `$00`, selects inline vector index zero at `$81A7` (file `0x0161B7`), whose
   target is `$8327`. Handler `$8327` reads callback byte offset 2, `$56`, as
   the map selector. The diagnostic model records those three source offsets;
   it does not execute the handler or consume the callback tail.
5. `$8327` uses the caller-owned global `$05CD` to derive the `$05CE/$05CD`
   placement transition. The source formula exists in
   `FirstCommandFieldPacketProducer`, but this model refuses to run it without
   the live pre-handler `$05CD` value. That value depends on prior
   `$35/$36/$1E` callbacks and is not a callback argument or task-slot field.

The external trace is only an independent check. The muted two-pass replay in
`reference/diagnostics/first_command_callback_state_20261028_061906_utc/`
observed the `$44/$70` handler entry and later placement write. It does not
seed model state. The source chain does not provide the earlier callback
history, task continuation, bank/stack restoration, or map-worker yield state
needed to execute `$8327`.

## Bounded `$F015` A recurrence

Preserved code span:
`first_command_field/packet_producer/bank_1f_f015_f159_code.bin`, CPU `$F015`,
file `0x03F025`, length 325, SHA-256
`df7c650c952fb5dfc9a8a10de43f739c9fc4cbdef343bae7ba70c4921a281dc9`.
At CPU `$F094` / file `0x03F0A4`, it contains:

```text
68 18 69 01 C9 06 F0 03 4C 15 F0
```

This restores A, increments it, compares against `$06`, and jumps to `$F015`
while it has not reached six. Thus an explicit entry A of zero produces the
index sequence `0,1,2,3,4,5`; an explicit entry A of two produces `2,3,4,5`.
The model does not infer the caller's initial A. The retained muted
`field_producer_entries.csv` and `field_producer_entries_repeat.csv` each
independently record `$F015` entries with A=`$00..$05`. That validates the
route observation, but it does not source-prove the caller or connect this
producer causally to the `$8327` callback.

Trace hashes:

- `field_producer_entries.csv`: `c50ed17172f0ed351cc722d92439b271fd775dcf15bf9724746e799df5677aa5`
- `field_producer_entries_repeat.csv`: `d74adaf5c7b40e65c08326fe2a778effd11410303548e83662d4c3bd461c13fe`

## Implementation and verification

- Diagnostic model: `tools/diagnostics/rom_first_command_callback_prefix_model.gd`
- Focused verifier: `tools/diagnostics/verify_rom_first_command_callback_prefix_model.gd`
- Run: `godot --headless --path . --script res://tools/diagnostics/verify_rom_first_command_callback_prefix_model.gd`
- Result on Godot 4.7.2: PASS for scenario cursor `0→4→5`, root-depth stack
  termination with unchanged payload, callback offsets `0/1/2 → $06/$00/$56`
  and handler `$8327`, explicit missing `$05CD` refusal, and the source-byte
  `$F015` recurrence compared independently with both retained trace passes.

No route code, scheduler, emulator state, or capture-derived runtime input was
added. The next source-backed requirement is to derive the prior callback/task
and worker continuation that owns `$05CD`; the `$F015` caller and its route
entry A also remain separate gaps.

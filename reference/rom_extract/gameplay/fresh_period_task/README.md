# Fresh-period slot-$05 source slice

This package preserves and executes one narrowly bounded source path from the
supplied Turkish ROM (SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`). It
supports only the initial slot-$05 entry at `$D11E` with caller-derived fresh
period `$0027=0` and opponent ID `$002B=$03`, and stops at the verified jump to
`$DAAA`.

The instruction bytes occupy `$D11E–$D182` inclusive (101 bytes). The full
`JMP $DAAA` instruction needs its final operand byte at `$D182`; the older
`task_context/fixed_slot05_period_setup_D11E_D181.bin` stops one byte early.
This package keeps the complete instruction in its own hash-checked span and
does not change the existing task-context manifest. The indexed camera bytes
at `$D183–$D184` are preserved as a separate span.

For the supported caller state, the byte path clears `$063E`, `$0640`,
`$0641`, and `$0613`; writes the source period to `$0629`; derives table index
zero from period zero and opponent three; loads `$B4/$00` from `$D183/$D184`
into `$05F7/$05F8`; clears `$05F9`; sets SP from the ROM's `LDX #$50 / TXS`;
and reaches `$DAAA`. The focused verifier checks these transitions and rejects
unsupported period/opponent values or missing caller provenance.

The caller must supply the decoded slot, entry PC/SP, period, opponent ID, and
a `caller_owned_decoded_game_logic` source context. This helper does not infer
those values from emulator captures. It models only the opcodes actually
reached by this fresh-period route; it does not implement other periods, other
opponents, the task scheduler, bank switching, the `$DAAA` continuation, or a
general 6502 CPU.

Run the focused verifier with:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_fresh_period_task.gd
```

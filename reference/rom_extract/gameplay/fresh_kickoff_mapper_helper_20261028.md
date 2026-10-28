# Fixed-bank `$C4B9` mapper helper — 28 Oct 2026

## Source identity and scope

`RomFixedMapperSelectHelper` executes the 15 preserved bytes at fixed-bank
`$C4B9-$C4C7` from
[`fresh_kickoff_caller/fixed_mapper_select_C4B9_C4C7.bin`](fresh_kickoff_caller/fixed_mapper_select_C4B9_C4C7.bin).
The span is checked against ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, manifest
offset `0x03C4C9`, and source hash
`a87676276fdbfa7feeb8e1279d6e9cb220b436dd1edb788813801b2be1c48f12`.

The bounded instruction sequence is:

```text
$C4B9  STX $25
$C4BB  LDA #$07
$C4BD  ORA $22
$C4BF  STA $23
$C4C1  STA $8000
$C4C4  STX $8001
$C4C7  RTS
```

The component requires an explicit decoded call event at one of the five
checked fresh KICK OFF callsites (`$80F7`, `$810C`, `$8119`, `$813F`, `$8938`),
matching caller return PC, pre-JSR SP, 256-byte stack page, CPU registers, and `$0022` mapper
select-shadow. It validates the stacked RTS return word and produces source
register/RAM/mapper-bus effects. The helper body is 25 CPU cycles; that count
excludes the caller's JSR and is derived from the opcode cycle table.

It returns MMC3 writes to `$8000` and `$8001` as data; it does not mutate a
live mapper. It also does not produce the call event or invent its caller
register/stack state. It is not yet connected to
`RomFreshKickoffCallerContinuation` or `KickoffRouteRuntime`.

Focused verification:

```sh
godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_rom_fixed_mapper_select_helper.gd --quit-after 2
```

Godot 4.7.2 verifier result: PASS for all five callsites, the JSR/RTS stack
contract, returned registers/flags, the two MMC3 bus writes, and the 25-cycle
helper-body count. It does not establish that any callsite is reached in the
production route.

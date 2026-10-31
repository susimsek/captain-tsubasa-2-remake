# Bounded `$CA55->$E3CA` No-Direction Call

## Scope

This package executes the fresh-match, no-direction path of the root
slot-`$01` caller's second field-input call. Its input is the ROM-byte `$EE9F`
empty-actor result plus the actual `$CA55->$E3CA` request emitted by
`RomRootSlot01ContinuationRuntime`. It executes the caller JSR, the fresh-match
`$05FB == 0` gate, the `$001C & $0F == 0` branch, and the `$E406` RTS. It stops
at the returned caller PC `$CA58`.

The runtime executor is
`scripts/gameplay/rom_e3ca_no_direction_call_executor.gd`; the focused verifier
is `tools/diagnostics/verify_rom_e3ca_no_direction_call_executor.gd`. Both
consume project-owned, hash-checked source bytes. Runtime does not read the
`.nes` file, FCEUX memory, screenshots, or captured audio.

## ROM Source

The spans below are from ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097` (iNES
1.0, mapper 4, no trainer). `manifest.json` records the exact bytes and hashes.

| CPU range | Bank | PRG offset | Bytes | Purpose |
| --- | --- | ---: | --- | --- |
| `$E3CA-$E3D5` | `$1F` | `0x03E3DA` | 12 | Fresh-match gate, controller low-nibble test, BEQ to `$E406` |
| `$E406` | `$1F` | `0x03E416` | 1 | RTS for no-direction branch |

The measured FCEUX route report
[`first_command_e3ca_no_direction_trace_20261028.md`](../first_command_e3ca_no_direction_trace_20261028.md)
records `$05FB == 0` and `$001C & $0F == 0` for all 493 calls in both matching
passes. It identifies the `$E3CA->$E406` source branch; the runtime verifier
does not seed values from that trace. Instead it constructs the live fresh
route, executes the source-derived `$EE9F` call, and feeds that result to the
source caller and this executor.

## Return Contract

For the supported state, the executor returns to `$CA58` with SP restored to
`$2A`. A is zero after the source `AND #$0F`; X, Y, task-bank fields, and the
MMC3 bank state are preserved from `$EE9F`. It reports known processor flags
only where the incoming source contract provides them and the executed
instructions determine them. The only writes are the JSR return-address bytes
at `$012A=$CA` and `$0129=$57`; the matching RTS restores the stack pointer.
Field RAM such as `$0642/$0643` is unchanged.

The result uses the same fields as the `$EE9F` helper where applicable:
`status`, `entry`, `registers`, `mapper`, `ram_image`, `stack_page`, and
`memory_writes`. It is suitable for the route runner's next caller-continuation
step; it does not itself advance the scheduler.

## Stop Conditions and Limits

Execution rejects a mismatched ROM source package, `$EE9F` result, or caller
request. It stops before `$E3D6` when `$05FB` is nonzero or when `$001C & $0F`
is nonzero. It does not implement directional movement, the `$CE08` player
stat path, other `$E3CA` branches, later scheduler/NMI work, field drawing, PPU
timing, or audio. This bounded return is not proof of visible-output or timing
parity.

# Bounded `$CA52->$EE9F` Empty-Actor Execution

## Scope

This package supports one source-generated state: the fresh-kickoff route
runner's real slot-`$01` dispatch at `$CA52`, plus that dispatch's scheduler RAM
and stack snapshot. It executes the caller's `JSR $EE9F`, the ROM prologue and
mapper helper, the bank-`$14` `$800F` branch when `$053A == 0`, and the six-entry
actor-order loop only while each actor flag read from live RAM is inactive. It
then follows the ROM OAM-shadow clear and returns through the caller's real
stack to `$CA55`.

The runtime helper is
`scripts/gameplay/rom_ee9f_empty_actor_call_executor.gd`; the focused verifier
is `tools/diagnostics/verify_rom_ee9f_empty_actor_call_executor.gd`. Runtime
loads only the extracted, hash-checked source files in this directory; it does
not read the `.nes` file, emulator memory, screenshots, or captured audio.

## Source Spans

All spans are from ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097` (iNES 1.0,
mapper 4, no trainer). `manifest.json` records each byte sequence, CPU range,
mapper bank, PRG file offset, length, and SHA-256.

| File | CPU range | PRG offset | Length | SHA-256 |
| --- | --- | --- | ---: | --- |
| `fixed_actor_loop_EE9F_EF80.bin` | `$EE9F-$EF80` | `$03EEAF` | 226 | `f2bc95b5fc4ee2ad1c558e64c942be24f99ced8af4784f4bb0a51c423bb48bbd` |
| `bank14_actor_gate_8000_8083.bin` | `$8000-$8083`, bank `$14` | `$028010` | 132 | `bff58de8e06e64719aa1bab3af55e5e5348ede7ffe7812b6ec4f515ab0f787c9` |
| `fixed_mapper_helper_CE2D_CE49.bin` | `$CE2D-$CE49` | `$03CE3D` | 29 | `6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c` |

## Source-Derived Empty State and Result

The verifier obtains its input from `RomFreshKickoffSourceRouteRunner` after
one explicitly supplied frame-level NMI integration event. The event label is
only an API input; this work does not establish NMI cadence or physical PPU
timing. The route runner supplies the live dispatch, call request, 2 KiB RAM
image, and 256-byte stack page. RAM and stack-page mirrors are checked before
execution. No captured trace values are copied into the initial state.

For that source state, `$053A == 0`, `$053D == 0`, `$062D.7 == 0`, actor-order
bytes `$0543-$0545 == 01 23 45`, and the ROM pointer table selects records
`$0547,$055C,$0571,$0586,$059B,$05B0`. The executor reads each sign flag from
the provided RAM image and advances only while all six are inactive.

The bounded result is:

- CPU returns to `$CA55` with `A=$F8`, `X=$00`, `Y=$00`, and `SP=$2A`.
- Nested `JSR`, `RTS`, `PHA`, and `PLA` stack writes are applied to both the
  returned RAM image and stack page.
- MMC3 register-select ends at `$07`; PRG bank registers 6 and 7 are written
  with `$14` and `$15`. Scheduler task-bank fields remain those from dispatch.
- RAM counters end at `$3A=$06`, `$3B=$00`; actor pointer bytes end at
  `$3C-$3D = $B0 $05`; `$053F=$40`.
- The ROM's indexed clear writes `$F8` to the 64 Y-byte slots
  `$0200,$0204,...,$02FC` in the returned OAM shadow. The verified path records
  101 total CPU-RAM and MMC3 register writes, including stack writes.
- PPU bus events, raster timing, actor drawing, and audio effects are not
  modeled by this helper.

The initial processor status register is not part of the scheduler contract.
The result therefore omits the full status byte and reports only the flags
whose final values are determined by this path (`N,V,Z,C`, known value `$03`,
known mask `$C3`); the remaining status bits are unspecified.

## Stop Conditions and Limits

Execution rejects a non-source dispatch, mismatched call request, inconsistent
RAM/stack snapshot, wrong live source ordering, or unsupported ROM bytes. It
stops at the bank gate if `$053A` is nonzero, at the actor-count branch if
`$053D` is nonzero, at the first active actor immediately after its flag test
and before actor processing, or before the alternate post-loop actor-mode path
if `$062D.7` is set. Those paths are not implemented here.

This is a bounded route component, not a complete 6502 emulator or proof of
screen output. It does not establish PPU writes, per-pixel appearance, NMI
cadence, frame timing, audio, or the following `$E3CA` call. Its acceptance
claims are limited to the inspected source bytes and the focused verifier's
source-generated empty-actor execution.

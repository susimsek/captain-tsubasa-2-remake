# Fresh-start animation `$8F` first motion roots — 28 Oct 2026

## ROM source and decoded commands

The supplied Turkish ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. The
contiguous bank-$14 source span at file offset `0x02A733` is preserved as
[`fresh_actor_motion_roots_A723_A734.bin`](fresh_actor_motion_roots_A723_A734.bin)
and SHA-256 checked by the actor interpreter manifest:

```text
$A723: 01 EF 26 00 00 00 04 23 A7
$A72C: 01 A0 40 00 00 00 04 2C A7
```

The `$F1` records in animation `$8F` select `$A723` for `$055C/$0571` and
`$A72C` for `$0586/$059B`. Bank-$14 `$84DC` dispatches the first byte when
actor `+$11` is zero. Opcode `$01` is handled at `$85A9`: `$85E7` loads the
duration byte, then the handler copies two little-endian motion operands into
actor lanes `+$05/+07` (X) and `+$09/+0B` (Y). Thus `$A723` supplies timer
`$EF`, X velocity `$0026`, Y velocity `$0000`; `$A72C` supplies timer `$A0`, X
velocity `$0040`, Y velocity `$0000`.

When the timer reaches zero, opcode `$04` at `$A729/$A732` is handled at
`$858D`. The inline dispatch table at `$8583` maps `$01` to `$85A9` and `$04`
to `$858D`. The `$04` handler reads its little-endian target, resets the temporary stream index,
and dispatches again from `$A723/$A72C`; the `$01` command is therefore
reloaded in that same `$84DC` call. The root's `$01` handler advances the
stored cursor to `$A729/$A732`, and the shared `$852A/$85F2` integrator applies
the velocity on every active update.

The integrator's source fields are modeled directly: `+$05/+07` and `+$09/+0B`
are signed fixed-point deltas; `+$06/+08` and `+$0A/+0C` are fractional and
integer positions; low bits in `+$00` retain the extra coordinate carry. The
four verified route roots use positive X-only velocities. No screen coordinate
or sprite pose is substituted for this record arithmetic.

## Focused checks

[`verify_rom_fresh_actor_motion_roots.gd`](../../../../tools/diagnostics/verify_rom_fresh_actor_motion_roots.gd)
composes animation `$8F` decoding, the `$F1` constructor, appearance `$F7`, and
the motion interpreter. For all four actors it checks the first two source
ticks, then advances through the `$04` self-loop and checks the resulting
source-record bytes. It also compares each first-tick record against the
independent muted FCEUX writer trace at source frame 8482. The capture is used
only by this verifier as a behavioral cross-check; no captured state enters
the Godot component.

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_fresh_actor_motion_roots.gd
```

The check passes in Godot 4.7.2. The existing
`verify_rom_fresh_actor_appearance_roots.gd` remains the appearance-root
check; the new motion verifier does not alter its expected appearance result.

## Boundary and remaining gaps

This is an isolated `RomActorStateInterpreter` slice. It runs only the exact
`$01` and self-targeting `$04` commands in `$A723/$A72C`, selected from actual
decoded `$8F` `$F1` packets. It does not support arbitrary motion opcodes,
other animation roots, negative or mixed-axis route cases, or commands after
these loops. The separate `$A38A` one-step/hold slice remains supported.

The helper does not launch scenario `$35/$3A`, create or schedule the live
actor records, decide when `$EE9F` updates them, or derive that cadence from
the task/NMI graph. It is not called by `KickoffRouteRuntime` and must not be
inserted there using a frame delay or captured actor state. It also does not
apply shared CHR, mirroring, scrolling, clipping, sprite priority, or the OAM
renderer. These checks establish actor-record motion arithmetic only; they do
not establish actor appearance, OAM, visible-frame, or route parity.

# Bank-$14 actor state interpreter slice — 2026-10-28

## Scope and source provenance

`RomActorStateInterpreter` is a standalone, typed Godot component for a bounded
part of the Turkish ROM's actor update path. It loads no ROM file at runtime.
Its source spans were extracted from the supplied ROM with
[`extract_actor_state_interpreter_resources.py`](../../../../tools/gameplay/extract_actor_state_interpreter_resources.py)
and are SHA-256 checked against
[`manifest.json`](manifest.json) before an actor can be ticked. The extractor
also checks the ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097` before
writing any project resources.

| Bank-$14 source | ROM file span | Resource |
| --- | ---: | --- |
| `$83D9–$84DB` appearance interpreter | `0x0283E9`, 259 bytes | `appearance_interpreter_83D9_84DB.bin` |
| `$84DC–$8623` motion interpreter and local helpers | `0x0284EC`, 328 bytes | `motion_interpreter_84DC_8623.bin` |
| `$B026–$B030` timed appearance loop | `0x02B036`, 11 bytes | `appearance_loop_B026_B030.bin` |
| `$B5AC–$B5B3` held appearance commands | `0x02B5BC`, 8 bytes | `appearance_hold_B5AC_B5B3.bin` |
| `$B30E–$B313` fresh animation-$8F appearance roots | `0x02B31E`, 6 bytes | `fresh_actor_appearance_roots_B30E_B313.bin` |
| `$A38A–$A390` motion step and hold | `0x02A39A`, 7 bytes | `motion_step_A38A_A390.bin` |

The actor updater order follows the fixed-bank `$EE9F` source loop documented
in [`first_command_actor_state_producer_20261027.md`](../first_command_actor_state_producer_20261027.md):
appearance `$83D9`, then motion `$84DC`, before the renderer. The interpreter
accepts one 21-byte actor record with its source cursors in `+$03/+04` and
`+$01/+02`; it returns the updated record and source-addressed command notes.

## Implemented source behavior

- Appearance `$83D9` decrements a positive `+$10` timer once per call and
  leaves `$FF` held. When the timer is zero it executes a normal
  `duration, descriptor` pair, advances the stored cursor by two, follows the
  preserved `$F3` absolute redirect, or applies `$F7` and holds the
  descriptor. `$F0` also sets the appearance timer to `$FF`.
- The test stream at `$B026` contains four four-tick descriptor pairs followed
  by `$F3 $26 $B0`. The verifier confirms the initial pair, one decrement per
  actor tick, the second descriptor, and the redirect back to the first pair.
- The test stream at `$B5AC` begins with `$F7 $00`. The verifier confirms that
  this sets descriptor `$00` and holds it without advancing the source cursor.
- `tick_appearance_only()` also executes the first `$F7` command selected by
  each `$8F` `$F1` packet: roots `$B30E/$B310/$B312` set descriptors
  `$B8/$BA/$B9` and hold. The focused verifier composes the animation decoder,
  `$80AA` record constructor, and `$83D9` appearance interpreter for all five
  packets. It deliberately leaves motion cursors and coordinates unchanged;
  it does not claim that later actor ticks are complete.
- Motion `$84DC` recognizes the hash-pinned `$A38A` source packet
  `01 01 00 00 00 00 00`. The ROM `$85A9` handler calls `$85E7`, which loads
  the next source byte (`$01`) into actor `+$11`; the handler reads the four
  following zero bytes into motion lanes `+$05/$07/$09/$0B` and advances the
  stream cursor to `$A390`.
- The next actor update decrements `+$11` from `$01` to `$00` and dispatches
  the ROM `$852A` integrator. With those four ROM-provided deltas at zero, the
  visible X/Y coordinates remain unchanged. On the following update, source
  `$A390=$00` reaches `$85A0`, which sets `+$11=$FF` and holds. Later updates
  preserve that hold. Other/nonzero integrator inputs are rejected.
- The fresh animation-$8F roots `$A723/$A72C` are now a separate bounded
  motion path. Their `$01` duration/velocity packets and `$04` self-jumps are
  hash-pinned; `$852A/$85F2` fixed-point updates include the coordinate carry
  bits in actor `+$00`. Only those two positive-X loops are accepted. See
  [`fresh_actor_8f_motion_root_slice_20261028.md`](fresh_actor_8f_motion_root_slice_20261028.md)
  and its focused trace cross-check.

Run the focused source-only verifier with:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_rom_actor_state_interpreter.gd
```

The verifier uses constructed actor records and packaged ROM-derived bytes.
It does not read FCEUX RAM, OAM, screenshots, or trace rows.

The independent muted trace in
`reference/diagnostics/first_command_actor_oam_20261027_113609_utc/actor_draw_calls.csv`
records actor `$0547` with motion cursor `$A390` and timer values `$01/$00/$FF`
on source frames 8481/8482/8483, with visible coordinate bytes unchanged.
Those rows corroborate the three source updates; the Godot component and
verifier never load them.

## Limits

This is an interpreter slice, not a complete `$83D9/$84DC` implementation.
Appearance controls `$F1/$F2/$F4/$F5/$F6/$F8` and other unknown opcodes are
rejected. Motion accepts `$A38A–$A390` plus only the `$01/$04` loops at
`$A723/$A72C`; arbitrary motion timers, other roots/opcodes, the full
route-selected `$A1B4/$AC47` tables and script spans, shared
CHR/mirror/scroll/clip state, and OAM rendering remain outside this component.

The component is not called by `KickoffRouteRuntime`. It establishes that
selected actor-script state can be executed from hash-pinned ROM bytes, but it
does not provide the missing scenario/task launch state or the `$EE9F` source
tick cadence needed to advance live route actors. The animation-$8F motion
verifier reads a retained trace row for validation; no runtime code consumes
trace rows, captures, or RAM snapshots.

The additional `$8F` first-pose composition check is
[`verify_rom_fresh_actor_appearance_roots.gd`](../../../../tools/diagnostics/verify_rom_fresh_actor_appearance_roots.gd).
Its narrower boundary is documented in
[`fresh_actor_8f_appearance_root_slice_20261028.md`](fresh_actor_8f_appearance_root_slice_20261028.md).

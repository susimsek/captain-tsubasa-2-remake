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
| `$B537–$B538` frame-8663 timed appearance pair | `0x02B547`, 2 bytes | `appearance_pair_B537_B538.bin` |
| `$B539–$B5AB` route appearance continuation | `0x02B549`, 115 bytes | `appearance_sequence_B539_B5AB.bin` |
| `$B30E–$B313` fresh animation-$8F appearance roots | `0x02B31E`, 6 bytes | `fresh_actor_appearance_roots_B30E_B313.bin` |
| `$AF81–$AF93` animation-$66 appearance root | `0x02AF91`, 19 bytes | `animation_66_appearance_AF81_AF94.bin` |
| `$A38A–$A390` motion step and hold | `0x02A39A`, 7 bytes | `motion_step_A38A_A390.bin` |
| `$A692–$A698` animation-$66 motion step and hold | `0x02A6A2`, 7 bytes | `animation_66_motion_A692_A699.bin` |

The actor updater order follows the fixed-bank `$EE9F` source loop documented
in [`first_command_actor_state_producer_20261027.md`](../first_command_actor_state_producer_20261027.md):
appearance `$83D9`, then motion `$84DC`, before the renderer. The interpreter
accepts one 21-byte actor record with its source cursors in `+$03/+04` and
`+$01/+02`; it returns the updated record and source-addressed command notes.

## Implemented source behavior

- Appearance `$83D9` decrements a positive `+$10` timer once per call and
  leaves `$FF` held. When the timer is zero it executes a normal
  `duration, descriptor` pair, advances the stored cursor by two, or dispatches
  one of the preserved `$F0–$F8` commands. `$F0` holds; `$F1/$F2` set flip
  flags; `$F3` redirects to an absolute stream address; `$F4/$F5` establish and
  count down a loop using actor `+$0D–$0F`; `$F6` sets local offsets; `$F7`
  selects and holds a descriptor; `$F8` reports the shared selector write.
- The test stream at `$B026` contains four four-tick descriptor pairs followed
  by `$F3 $26 $B0`. The verifier confirms the initial pair, one decrement per
  actor tick, the second descriptor, and the redirect back to the first pair.
- The test stream at `$B5AC` begins with `$F7 $00`. The verifier confirms that
  this sets descriptor `$00` and holds it without advancing the source cursor.
- The frame-8663 route stream advances from `$B537` to `$B539`; the added
  `$B539–$B5AB` bytes cover the next timed descriptors and the route's `$F6`
  local-offset commands. `$F6` writes the two inline operands to actor
  `+$13/+14`, then continues parsing to the next timed pair. The verifier
  checks `$B545: F6 FE 01` followed by `$B548: 04 76`.
- `$F8` reads its inline selector and reports the source write to shared
  `$0546`; the `$EE9F` actor loop applies that write at `$84D8`. A focused
  constructed-record check verifies the `$B56A` path (`F8 01 F1 01 D2`) writes
  selector `$01` and continues into its source timed pair.
- `tick_appearance_only()` also executes the first `$F7` command selected by
  each `$8F` `$F1` packet: roots `$B30E/$B310/$B312` set descriptors
  `$B8/$BA/$B9` and hold. The focused verifier composes the animation decoder,
  `$80AA` record constructor, and `$83D9` appearance interpreter for all five
  packets. It deliberately leaves motion cursors and coordinates unchanged;
  it does not claim that later actor ticks are complete.
- The slot-$11 appearance stream `$B2E0–$B30D` is preserved as a SHA-256 checked
  bank-$14 resource. It includes the `$F4` loop setup, `$F5` loop end, timed
  pairs, and `$F7` descriptor hold used by this route. The related animation-
  `$8F` roots `$B30E–$B315` are also preserved. The focused interpreter check
  passes with these resources; the full recorded-input route now reaches frame
  8781 and then stops at unsupported motion pointer `$A865`.
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
- The first animation-$66 actor's appearance root `$AF81` executes `$F1` by
  ORing horizontal-flip bit `$20`, then reads the timed pair `$06,$9E`. Its
  selected motion root `$A692` loads duration `$3C` and signed fixed-point
  lanes `($FF:$DA,$FF:$ED)`, integrates the first source update, counts down
  through `$A698`, and accepts the following `$00` hold. Other appearance
  `$F1/$F2` usage and other motion roots are still rejected.

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
Appearance `$F0–$F8` is supported only where covered by the preserved roots and
source spans; other unknown controls remain outside the slice. Motion accepts
`$A38A–$A390`, `$A692–$A698`, and only the `$01/$04` loops at `$A723/$A72C`;
other roots/opcodes remain unsupported. Shared CHR/mirror/scroll/clip state and
full OAM rendering are handled by separate route components.

The source route invokes this bounded interpreter for the visible actor records.
The latest full recorded-input run reaches frame 8781 but stops when motion
pointer `$A865` is outside the preserved source spans; four timing/stack/NMI
route assertions also fail. The animation-$8F motion verifier reads a retained
trace row for validation; no runtime code consumes trace rows, captures, or RAM
snapshots.

The additional `$8F` first-pose composition check is
[`verify_rom_fresh_actor_appearance_roots.gd`](../../../../tools/diagnostics/verify_rom_fresh_actor_appearance_roots.gd).
Its narrower boundary is documented in
[`fresh_actor_8f_appearance_root_slice_20261028.md`](fresh_actor_8f_appearance_root_slice_20261028.md).

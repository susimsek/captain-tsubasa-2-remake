# Fresh-start animation `$8F` first appearance commands — 28 Oct 2026

## ROM-backed slice

The supplied ROM's bank-$14 appearance roots selected by animation `$8F` are
`$B30E`, `$B310`, and `$B312`. The project preserves the contiguous six-byte
span at ROM file `0x02B31E`:

```text
$B30E: F7 B8
$B310: F7 BA
$B312: F7 B9
```

The span SHA-256 is
`91f6198e377498f48b5bd9fd659fd6a7fbcd76f417abf679e2ef16bdee9228d2`.
The extractor checks the supplied ROM SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097` and
preserves the bytes under
[`manifest.json`](manifest.json). They are decoded as source data; emulator
captures are not read by the runtime component.

## Composed packet result

`verify_rom_fresh_actor_appearance_roots.gd` decodes animation `$8F`, applies
each `$F1` packet through `RomF1ActorRecordConstructor` and executes the first
appearance command with `RomActorStateInterpreter.tick_appearance_only()`.
The result for the five source packets is:

| `$F1` file offset | Actor record | Motion pointer | Appearance root | `$83D9` result |
| ---: | ---: | ---: | ---: | --- |
| `0x02989C` | `$0547` | `$A38A` | `$B30E` | descriptor `$B8`, hold timer `$FF` |
| `0x0298A2` | `$055C` | `$A723` | `$B310` | descriptor `$BA`, hold timer `$FF` |
| `0x0298A8` | `$0571` | `$A723` | `$B310` | descriptor `$BA`, hold timer `$FF` |
| `0x0298AE` | `$0586` | `$A72C` | `$B312` | descriptor `$B9`, hold timer `$FF` |
| `0x0298B4` | `$059B` | `$A72C` | `$B312` | descriptor `$B9`, hold timer `$FF` |

The target `$83D9` `$F7` handler sets record byte `+$12` to the operand and
`+$10` to `$FF`; it does not advance the appearance pointer. The composed
verifier also checks that the source `$F1` coordinates and motion cursor remain
unchanged by this appearance-only call. Focused verification passes in Godot
4.7.2:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_fresh_actor_appearance_roots.gd
```

## Limits

This validates only the first `$F7` appearance command for each `$8F` packet.
The separate
[`fresh_actor_8f_motion_root_slice_20261028.md`](fresh_actor_8f_motion_root_slice_20261028.md)
now advances the source `$A723/$A72C` motion loops in an isolated component;
that does not schedule actor ticks from the ROM task graph, run later
appearance commands, apply shared CHR/mirror/scroll/clip state, or build OAM.
Neither slice makes the actor pipeline or first-command route
production-integrated. FCEUX actor rows remain validation references only.

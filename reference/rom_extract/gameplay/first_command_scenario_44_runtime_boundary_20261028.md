# Scenario `$44` reader and first-command field boundary — 2026-10-28

## Source identification

This note distinguishes two different uses of ID `$44` in the Godot route:

- `KickoffCutsceneCommandVm.start_cutscene(0x44)` loads the bank-`$05`
  pre-match dialogue script in `assets/gameplay/rom_logic/`.
- Bank-`$10` gameplay scenario `$44` is the source stream rooted by pointer
  `$B7D5` at file offset `0x020A57`. The pointer-bounded span is five bytes at
  file offset `0x0237E5`, ending at the next greater scenario pointer `$B7DA`:

  ```text
  02 70 5C F0 FB
  ```

  SHA-256: `22c0290ec8b82bd06eb69bd51a8d8617181cf2c5bbf52b790ea62102e0c71e0f`.
  The first four bytes are a bank-`$10` scenario record; the final `$FB` is a
  return through the interpreter's continuation stack.

The extractor preserves this span as
`first_command_scenarios/scenario_44.bin`. `Bank10ScenarioBytecodeReader`
now parses its four record fields using the existing ROM-byte-verified rules:

| Source field | Runtime meaning | Decoded value |
|---|---|---:|
| `$0523` | callback delay | `$02` |
| `$0524` | bank-`$0B` event callback selector | `$70` |
| `$0528` | actor animation selector | `$5C` |
| `$0529` | transformed worker parameter | `$FF` from the inline `$F0` transformer |

The source reader now classifies `$FB` as `SOURCE_TERMINATED` only when the
caller supplies continuation depth zero and the stream is one of the four
exact hash-checked fresh-route streams. The stack helper models `$FA` pushes,
nested `$FB` pops, and root `$80CF` termination from preserved ROM bytes. It
does not model `$80CF` cleanup or the outer CPU/task return, and this remains a
byte-reader result rather than a live scheduled callback.

## What this establishes for candidate presentation

The event and actor fields are distinct ROM consumers. The bank-`$0B`
dispatcher `$814C` indexes `$87F6` using `$0524`; its `$70` callback record is
at `$8B38` / file `0x016B48`. The fixed-bank actor handoff separately consumes
`$0528/$0529`. The source record therefore supports resolving callback ID
`$70` and actor animation ID `$5C`; it does not by itself describe callback
execution, child worker cadence, or the complete PPU packet sequence.

The first-field candidate still cannot safely receive a final packet context
from this record alone:

1. The `$05CE` packet placement is produced by the background callback at
   bank-`$0B` `$8327` from the incoming `$05CD`, then `$05CD` changes. The
   repeated route trace observes earlier `$8327` state transitions at frames
   8479, 8605, 8619, 8647, 8681, 8734, 8803, and 8905. Those are diagnostic
   observations, not an event count or runtime schedule. Godot has a bounded
   bank-`$10` stack helper for source parsing, but no live continuation/task
   state, bank-`$0B` callback task, or
   earlier background-worker state model to derive the correct incoming
   `$05CD` value. Do not initialize it from the trace or supply `$05CE=$A0`.
2. The descriptor resolver correctly computes `$063D` from caller-owned
   `$0621/$0600`, and the supplied ROM bytes show the fresh-route writer path
   for those inputs. The live Godot route does not yet execute that source
   branch as gameplay state, so its UI stage cannot stand in for those RAM
   bytes.
3. `$F0B5` holder coordinates are a separate dynamic record-selection path
   and remain outside this note.

Therefore the scenario source can be decoded, but it is not yet correct to
wire its `$70` event directly to `present_first_match_field_candidate()` or
claim the callback is dispatched from source logic in Godot. The next required
runtime work is a ROM-backed scenario continuation plus cooperative callback
and background-worker transition that owns `$05CD`; the field renderer must
then receive that state and the live `$0621/$0600` values. The two-pass FCEUX
trace is used only to validate such a model after it exists.

## Verification

`tools/diagnostics/verify_bank10_scenario_bytecode_reader.gd` checks that the
preserved scenario `$44` bytes decode to `$0523=$02`, `$0524=$70`, `$0528=$5C`,
and `$0529=$FF`, with its exact depth-zero `$FB` classified as root source
termination. The continuation-stack verifier checks the exact source spans
and nested LIFO operations. These checks do not prove route timing, task
returns, callback scheduling, or produce a PPU frame.

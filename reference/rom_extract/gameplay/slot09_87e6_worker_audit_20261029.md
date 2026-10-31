# Slot-$09 bank-$18 worker `$87E6` audit — 2026-10-29

## Finding

The third bank-$18 worker in the resumed slot-$09 loop is a compact RAM-driven
timer/stream interpreter. Its zero-state branch writes `$00` to shared RAM
`$0538` and returns. Its active paths can load a script pointer, decrement a
timer, update `$0536-$0538`, and advance or replace the script cursor in
`$007D/$007E`. The worker makes no direct PPU/APU register writes and does not
call another routine.

The source map is now connected to a separate bounded executor. The focused
verifier obtains the actual `$8779` result from
`RomFreshKickoffSourceRouteRunner`, source-executes the intervening root caller,
and confirms live `$0536=$00` at `$87E6`. The worker takes `BEQ $8811`, writes
`$0538=$00`, and returns at `$EBD7`. This establishes that source transition;
it does not establish visible PPU output or the later command menu.

## Source identity and spans

The source is the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`, iNES
1.0, mapper 4, with a 16-byte header and no trainer. Bank `$18` occupies the
switchable `$8000-$9FFF` window; bank `$19` supplies the `$A000-$BFFF` pointer
table. All offsets below include the iNES header. The extracted bytes and
hashes are in [`slot09_87e6_worker/manifest.json`](slot09_87e6_worker/manifest.json).

| CPU span | Bank | ROM file offset | Length | SHA-256 | Use |
| --- | ---: | ---: | ---: | --- | --- |
| `$8009-$800B` | `$18` | `0x030019` | 3 | `ee600ed5f0ff7a46e0b9a1d41acb3615828d6c635eee42c16598839227a71e27` | Root-loop vector: `JMP $87E6` |
| `$87E6-$8850` | `$18` | `0x0307F6` | 107 | `879cfbc3684874aa7a857d9ee294755cbb773b616d5815335a2208d414799509` | Complete worker, including its final `JMP $8815`; the next routine begins at `$8851` |
| `$AD54-$AD5D` | `$19` | `0x032D64` | 10 | `8d1c08abdc6be570a1a0e8304738c995c09856b4081e0962f15db579cb95f7b5` | Five little-endian script pointers used by the `$0536` reset-marker path |
| `$EBC5-$EBD6` | `$1F` fixed | `0x03EBD5` | 18 | `75ff2ee06764439aecb4eae84c694e1f99b083d7b21a92c9ad5e41baa09b304e` | Root caller bridge through `$EBD4: JSR $8009` |
| `$CE2D-$CE49` | `$1E` fixed | `0x03CE3D` | 29 | `6a815aa4ebad9e014531c5590616d6ec5596be7aa1a31c1542057062f25eb64c` | MMC3 helper called by the root bridge |

The five pointer-table entries are `$AD5E`, `$AD61`, `$AD68`, `$AD6B`, and
`$AD6E`. The worker selects an entry using `2 * (($0536 & $7F) - 1)` after
seeing bit 7 set. The verified first-match route has `$0536=$00`, so it does
not select or read any pointer-table entry; the reset-marker routes remain
unsupported.

## Control flow and effects

The entry PC is `$87E6`; the worker is called by the root loop at `$EBD4` with
`JSR $8009`. Its `RTS` resumes at `$EBD7`. The caller's byte span and worker
order are documented in the
[slot-$09 continuation audit](slot09_eb8b_continuation_audit_20261029.md).

| Source path | Source behavior | Observable source effects |
| --- | --- | --- |
| `$0536 == 0` | `$87E6 LDA $0536; BEQ $8811`; store A to `$0538`; return at `$8814` | Writes `$0538=$00`; no other write on this path |
| `$0536` bit 7 clear, nonzero | Branch to `$8808`; if `$0537` is nonzero, decrement it and return; otherwise parse the existing `$7D/$7E` stream cursor | May write `$0537`; parser may also write `$0537/$0538` and advance `$7D/$7E` |
| `$0536` bit 7 set, low 7 bits zero | Clear `$0536`, then store zero to `$0538` and return | Writes `$0536=$00`, `$0538=$00` |
| `$0536` bit 7 set, low 7 bits nonzero | Decrement the low-7-bit value, select a pointer from `$AD54,X`, clear `$0537`, then parse that stream | Writes `$0536`, `$0537`, `$007D/$007E`; parser effects follow |
| Stream byte below `$F0` | Store it in `$0537`; read the next byte into `$0538`; advance the pointer by two and return | Writes timer/control `$0537`, shared scroll `$0538`, and `$007D/$007E` |
| Stream byte `$F0` | Clear `$0536` and return | Writes `$0536=$00` |
| Stream byte `$F1` | Read a little-endian replacement pointer from the next two bytes and loop at `$8815` | Replaces `$007D/$007E`; no PPU/APU operation |
| Other stream byte `$F2-$FF` | Skip one byte and continue scanning | No immediate RAM write |

`$0538` is also identified as shared horizontal actor-scroll state in the
[actor shared-render-state trace](first_command_actor_shared_render_state_trace_20261028.md).
That semantic label comes from the separate rendering/source audit; this
worker's bytes establish only how it writes the RAM byte. A later NMI/renderer
consumer is responsible for visible PPU effects.

## Existing route observations

No emulator was opened for this audit. Existing same-ROM evidence provides
useful validation, but not inputs for the Godot executor:

- The actor OAM trace's frame-8460 CPU-RAM snapshot has
  `$0536-$0538 = 00 00 00`; the snapshot file SHA-256 is
  `3b623d01f80c94a0c836749c2b4b4e14368c792cf3bafb9885c6ee93e15dc0b6`.
- The following frame's shared-state trace records PC `$8814` storing
  `$0538=$00`, with A=`$00`, on the matched post-title route. Its route-input
  timeline SHA-256 is
  `87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`.

The frame-end snapshot precedes the next slot-$09 worker call, and the `$8814`
store alone cannot distinguish `$0536=$00` from a bit-7 reset-marker path
whose low seven bits are zero. The Godot result below resolves that ambiguity
from source-produced RAM: the runner's actual `$8779` result preserves
`$0536=$00`, and no trace value is injected.

## Live source execution and stop condition

[`RomSlot09Worker87E6ZeroBranchExecutor`](../../../scripts/gameplay/rom_slot09_87e6_zero_branch_executor.gd)
consumes the actual `slot09_8779_worker_result` from
`RomFreshKickoffSourceRouteRunner`. It accepts only the matching ROM/hash,
`$8779` return at `$EBC5`, source CPU/RAM/stack state, and mapper context. It
then executes the caller's `$EBC5-$EBD4` bridge, including the fixed `$CE2D`
MMC3 helper, reaches the `$8009->$87E6` vector, and reads `$0536` from that
live result. Its supported branch is exactly `$0536=$00`:

- root caller writes `$0024=$18`, `$0025=$19`, and `$0023=$06,$07`; MMC3
  registers 6 and 7 are selected and set to `$18/$19`;
- the worker's live `$0536` load sets Z, `BEQ $8811` is taken, and the worker
  writes `$0538=$00`;
- `RTS` consumes the pending `$EBD6` return word and exits at `$EBD7`, with the
  caller stack restored.

The focused [`verify_rom_slot09_87e6_zero_branch_executor.gd`](../../../tools/diagnostics/verify_rom_slot09_87e6_zero_branch_executor.gd)
builds the route context, asks the production runner to process its externally
supplied NMI edge, and passes the runner's actual `$8779` result to the
executor. It verifies source-span hashes, the executed PC list, RAM and mapper
writes, stack operations, returned registers, and `$EBD7` stop boundary. The
route reaches `$87E6` with `$0536=$00`; the check does not inject RAM from the
FCEUX captures.

The verifier also mutates a copy of that result only for a negative contract
case. With `$0536=$01`, the executor rejects the unresolved branch immediately
after `$87E9` at `$87EB`, without reading the stream body; a mismatched stack
copy is rejected before execution. Neither mutation is used to produce the
successful route output.

The pointer table is hash-checked as source evidence but is not read on the
supported zero path. The executor makes no PPU/APU writes and stops before the
root's next state checks at `$EBD7`. It does not establish later scheduler
yield, visible PPU output, or command-menu pixels.

Focused command:

```text
godot --headless --path . --script tools/diagnostics/verify_rom_slot09_87e6_zero_branch_executor.gd
```

Result: all route, source-span, state-transition, rejection, and stop-boundary
checks passed on Godot 4.7.2. No FCEUX session, screenshot, or WAV was used.

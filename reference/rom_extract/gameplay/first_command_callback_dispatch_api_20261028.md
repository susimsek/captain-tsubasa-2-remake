# First-command callback dispatch API boundary — 2026-10-28

## ROM-owned path recovered

Target ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The new source bundle under
`reference/rom_extract/gameplay/first_command_field/callback_dispatch/`
preserves the exact byte spans and hashes used by
`RomFirstCommandCallbackDispatchApi`.

The fresh-command scenario record at bank `$10:$B7D5` / file `0x0237E5` is
`02 70 5C F0`; its exact hash-checked route stream ends in root `$FB`, which
the byte reader classifies as source termination at explicit depth zero. The
bounded helper does not execute the outer CPU/task return. The bank-`$0B`
pointer-table entry for callback `$70` is
at `$88D6` / file `0x0168E6`, bytes `38 8B`, resolving to `$8B38`. That
pointer-bounded callback stream ends at the next valid callback target `$8B3E`
and is six bytes:

```text
06 00 56 02 00 80
```

Bank `$0B:$814C` loads the pointer, stores the first stream byte to `$0525`,
then passes the next byte to the inline dispatch entry at `$81A7`. The first
inline target entry is `$8327`; `$8327` reads the third callback-stream byte
(`$56`) through `($52),Y` with `Y=2`. Thus the first callback operation is
byte-resolved as `$0525=$06`, dispatch subindex `$00` → `$8327`, map selector
`$56`. The remaining three bytes `02 00 80` are exposed as an opaque tail;
this API does not schedule or interpret them.

## How `$05CD` reaches the handler

The fixed-bank cooperative scheduler stores task readiness/delay, saved stack
pointer, and bank selectors in task slots, and uses `$001B.7` as its next-scan
latch. It selects which task executes and when. It does **not** pass `$05CD` as
a callback argument or save it in the task slot. `$05CD` is shared CPU RAM.
When the bank-`$0B:$8327` handler runs, it reads the current global byte at
`$832E`, calls the map expander, writes `$05CE` at `$8342`, and changes global
`$05CD` at `$8349`. The source-backed pure transition remains in
`FirstCommandFieldPacketProducer.advance_map_placement_state()`.

Therefore the correct input to the `$70` handler comes from whichever earlier
route callback last changed shared `$05CD`. In the observed fresh route, those
writers belong to preceding scenario/callback and background-worker activity
before `$44/$70`; the muted trace validates that route history, but its frames
and RAM values are not runtime logic. A generic runtime needs to execute the
scenario continuation stack, schedule the earlier callback tasks and their
background workers, and apply each source `$8327` invocation in scheduler
order. The `$44` parser alone cannot reconstruct the incoming global state.

## Bounded API and exact stop point

`scripts/gameplay/rom_first_command_callback_dispatch_api.gd` now:

- reads scenario `$44` through the existing bank-`$10` source reader;
- checks the byte-preserved `$70` pointer entry, `$81A7` dispatch vector, and
  six-byte callback stream;
- resolves only the first operation through `$81A7` to `$8327` and preserves
  the unexplored callback tail;
- requires an explicit caller-provided global `$05CD` value before calling the
  existing ROM-byte-checked placement transition.

It does not implement the task scheduler or outer return after root `$FB`,
execute the callback tail, or supply previous route `$05CD`. It deliberately
has no default `$05CD`, event count, frame schedule, or PPU endpoint input.
No route runtime or field packet producer was changed.

The focused Godot verifier is
`tools/diagnostics/verify_first_command_callback_dispatch_api.gd`. It checks
source pointer/handler resolution, raw callback bytes, refusal without
`$05CD`, and one arbitrary explicit-byte transition. Its transition fixture
does not represent the live fresh-route state or claim scheduler parity.

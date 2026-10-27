# Opening text cursor and glyph queue trace

## Identity and evidence

This trace uses the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
For bank 0, file offset is `0x10 + (CPU address - 0x8000)`. Live command
dispatches are from
`reference/diagnostics/opening_dispatch_full_20261024_150016/opcode_flow.csv`;
end-of-frame RAM snapshots and PPU-register writes are from
`reference/opening_reference_capture/`. They are separate observations and do
not tag every register write with the source instruction that caused it.

## Confirmed interpreter and cursor behavior

At `$84E3` (file `0x0004F3`), the interpreter copies `$51` to `$53` once when
entering the command loop. For a text tile `$00–$D7`, `$84EF–$84FC` loads
`X=$52`, `Y=$53`, calls `$88CA`, increments `$53`, then calls `$895D` only if
`$55` is nonzero. `$8879` increments the script pointer and returns to
`$84E7`, so consecutive glyphs keep the incremented `$53`; they do not reload
the cursor base on each character.

The PPU address base is the little-endian word `($52 << 8) | $51`. For the
first dialogue it is `$2249` (`$51=$49`, `$52=$22`). The glyph helper passes
`Y=$53` and `X=$52` to the queue builder, so its first two queued address bytes
are low then high. The NMI PPU writer consumes that packet and writes the PPU
address in the order required by `$2006`.

`F2` enters at `$8678` (file `0x000688`): it reads its operand into `$55` and
uses `$8879` to advance past the two-byte command. It changes text delay only;
it does not change `$51:$52` or reset `$53`. The code calls `$895D` once per
glyph when `$55 != 0`; the captured speed-5 and speed-1 intervals agree with
one next text byte per 5 or 1 source frames. Speed `00` skips that delay call.

`FC` enters at `$8837` (file `0x000847`) on this opening path. Its source bytes
call `$899A`, call `$9FA8` with `A=$04`, add `$0040` to the little-endian
`$51:$52` base, advance the script pointer by exactly one byte, then jump to
`$84E3`. That last jump reloads `$53=$51`. Thus FC is a line break in this
observed context: it moves the next cursor origin down two nametable tile rows
and resets the per-glyph cursor to the new origin. It has no payload; the next
script byte is independently dispatched. The handler and dispatch evidence
are also recorded in `fc_counted_block_trace.md`.

`FD` has a separate, now PC-tagged reset path. Its `$8855` handler clears from
`$4F/$50`, waits through `$9FA8(A=$04)`, then resumes at `$885D`; `$8887`
advances the script by one byte and jumps to `$84D7`. That routine copies the
FD clear origin `$4F/$50` into the active text base `$51/$52` and seeds `$53`
from `$51`. In the observed `$A22E` FD, the frame-2908 copy to `$2249` occurs
before F2 at `$A235`, E3 at `$A237`, and the first glyph at `$A238`. The
caller, slot, stack, ROM-byte, and write evidence is in
`reference/diagnostics/opening_runtime_full_1792924153/frame_2758_gap_audit.md`.
The Godot presenter now mirrors this reset from its decoded FD clear origin
when the modeled wait completes, without a frame-number special case.

The inline `$E0–$E7` path changes `$53` by 0–7 tiles backward (for example,
`$E3` subtracts three) without changing `$51:$52`. Its remaining column-limit
behavior is not required to explain the captured FC lines. In the `$A237` E3
after the frame-2908 FD reset, the signed cursor moves `$2249 → $2246`; the 12
glyphs then advance it through `$2251` and leave `$53=$52`. The Godot model now
retains this signed relative offset instead of clamping it at the base. The
source queue and corrected replay are compared in
`reference/diagnostics/text_cursor_reset_runtime_20261025_150000/e3_cursor_offset_audit.md`.

## Glyph packet layout

For the observed glyph IDs below `$A0`, `$88CA` uses header `$82` through
`$9B28`, writes the current address bytes, then appends data bytes `$00,<tile>`.
`$9B5E` appends a zero terminator and commits the queue cursor. The resulting
buffer record is five meaningful bytes plus its terminator:

```text
82 <address-low> <address-high> 00 <tile-id> 00
```

Header `$82` requests two PPUDATA writes with increment-by-32. The capture
confirms the first glyph packet `82 49 22 00 4B` for tile `$4B`: source frame
380 writes `$00` at `$2249` and `$4B` at `$2269` while `$2000=$84`. Later
frame-end RAM snapshots show the same packet form after FC, for example:

| FC script byte | Base before → after FC | Next text packet in RAM | Capture frame |
|---|---|---|---:|
| `$A054` | `$2249 → $2289` | `82 89 22 00 4F 00` | 483 |
| `$A069` | `$2289 → $22C9` | `82 C9 22 00 64 00` | 587 |
| `$A078` | `$22C9 → $2309` | `82 09 23 00 6F 00` | 661 |
| `$A087` | `$2309 → $2349` | next byte is `$DC` (pause), not a glyph | 735 |

The sample at `$A078` demonstrates the low-byte carry into `$52`. These later
records establish that the ROM stages the expected source-derived queue bytes;
the existing PPU trace does not prove their NMI commit frame or visible pixels
after FC. The initial `$2249` glyph's PPU bus pair is directly captured; the
other rows above are RAM-queue evidence only.

The helper has a second path for glyph values `$A0–$D7`: it uses a `$8A14`
lookup and a `$94/$95` header. That path is present in ROM, but the packet
consumer semantics for those mapped glyphs have not been traced here. The
captured text bytes around the first `F2 05` / four subsequent FC breaks use
the direct `$00–$9F` path.

## Captured F2/FC sequence

The live first-pass dispatcher records these text-speed operands:

| Script address | Command | Speed |
|---|---|---:|
| `$A03E` | `F2 05` | 5 |
| `$A099` | `F2 01` | 1 |
| `$A0D6` | `F2 05` | 5 |
| `$A12C` | `F2 02` | 2 |
| `$A15B` | `F2 05` | 5 |
| `$A19C` | `F2 02` | 2 |
| `$A1C5` | `F2 05` | 5 |
| `$A207` | `F2 01` | 1 |
| `$A235` | `F2 00` | 0 |

Every captured `FC` below advances by one script byte, applies the same
`$0040` base step, and returns through `$84E3`:

```text
$A054 $A069 $A078 $A087
$A0A4 $A0AA $A0B7
$A0E7 $A0F2 $A105 $A11A
$A138 $A146
$A16D $A17C
$A1A4 $A1B0
$A1D5 $A1E4 $A1F1
$A214 $A21D $A229
$A24E $A263 $A273 $A285 $A290 $A293
```

At scene/setup boundaries the captured base returns to `$2249` before later
F2 groups, but the exact command that writes `$51:$52` is not isolated for
every boundary. The script stream shows an FD before each later F2 group;
`$885D → $8887 → $84D7` copies the FD clear origin `$4F/$50` into `$51/$52`
and seeds `$53`, as directly confirmed for `$A22E`. For the earlier reset after
`$A087`, the capture brackets FD `$A08A` before the next text-speed command at
`$A099`; that reset is explained by the same FD handler path, not by F2. The
initial `$A03E` group starts from the worker's startup-initialized `$2249`
cursor. The Godot presenter no longer resets the cursor at a hard-coded list
of F2 script addresses; F2 only changes `$55`, while startup, FD, FC, and E3
update the cursor through their modeled ROM paths. This callsite-wide
interpretation follows the verified handler and script order; only the `$A22E`
callsite has the cited PC-tagged reset trace.

## Limits for the Godot model

- The first direct packet and its frame-380 PPU writes are confirmed.
- FC's one-byte consumption, `$0040` base increment, and `$84E3` cursor reset
  are source-confirmed and corroborated by the RAM samples above.
- The NMI commit frame and raster-visible result for post-FC packets are not
  proven by this trace. The current capture contains no per-write CPU-PC tag
  for those packets.
- `$A0–$D7` glyph remapping, all `$E0–$E7` column-limit behavior, other
  cursor-reset writers, and exact visible pixels remain open.

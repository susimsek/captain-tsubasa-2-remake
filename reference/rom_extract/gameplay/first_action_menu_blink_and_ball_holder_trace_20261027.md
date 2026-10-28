# First-action selection blink and fresh-match ball-holder trace

## Source identity and method

- Target ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- Whole-file SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- Fixed-bank CPU mapping: file offset `0x03C010 + (CPU address - $C000)`.
- Bank `$02` window mapping: file offset `0x004010 + (CPU address - $8000)`.
- ROM bytes, source windows and hashes: [`action_blink_source_audit.json`](menus/first_action_menu/action_blink_source_audit.json).
- Recreate the source-backed runtime exports with
  `python3 tools/gameplay/extract_first_action_menu_blink_data.py`.
- Focused packet check:
  `godot --headless --path . --script tools/diagnostics/verify_first_action_menu_blink_packets.gd`.

The extraction checks the whole-ROM hash before copying the map, pointers,
render streams and receiver offset table. No emulator screenshot or PPU dump is
used to construct the packets. The FCEUX PPU/RAM records below only validate
the unselected endpoint and the observed player slot.

## Selection state and blink phase

For the first left-team ground-possession context (`$0621=0`), the fixed-bank
handler at `$D5E0-$D679` starts by writing `$061E=0`. At `$D638-$D63B`, BPL
returns directly to the input poll when bit 7 is clear; therefore the fresh
state has no action overlay and does not blink a default command.

A new D-pad edge indexes `$D6E8` in Right, Left, Down, Up order and stores its
result in `$043B`. For context zero the action IDs are Shoot=0, Pass=1,
one-two pass=3 and Dribble=2. `$061E` bit 7 gates action selection; its low two
bits keep the direction index. Once selected, bit 5 marks the started timer,
bit 6 is the visible/blank phase, and `$061F` counts down. `$D63D-$D64C`
initializes the timer on first selection; `$D64F-$D679` decrements it and, when
zero, sets it to `$0D`, toggles bit 6, and redraws the selected label. Thus the
phase changes every 13 handler iterations. The code path is tied to the
`$CB0F` input/update call, but the number of handler iterations per displayed
frame and the same-input screen timing have not been measured.

At `$D66A-$D676`, action ID indexes the four-byte map at `$D6DE`:

| Action ID | Action | Renderer variant | ROM stream |
|---:|---|---:|---|
| 0 | Shoot | 2 | `$EA34` |
| 1 | Pass | 1 | `$EA29` |
| 2 | Dribble | 0 | `$EA1C` |
| 3 | One-two pass | 3 | `$EA3D` |

`$061E` bit 6 controls the high-bit suppression flag passed into `$E93D`.
When bit 6 is clear, the routine marks the stream hidden; `$E9AB-$E9C9` then
replaces every output tile with zero. When bit 6 is set, the ROM tiles are
copied. Each stream header carries PPU low/high and a packed shape byte: low
two bits are row count, high six bits are row width. All four records are two
rows by five tiles, starting at `$22AC`; the second row starts at `$22CC`.
`$FE` means zero-fill the rest of that row. `$E93D` queues only five-tile
nametable transfers at `$04A5` and advances the PPU address by `$20`; this
selected-label path does not write attribute-table bytes.

The ROM-only Godot API is
`FirstActionMenuPanel.build_action_selection_packets(action_id, blink_visible)`.
It reads the three preserved `.bin` exports, and
`FirstActionMenuPanel.set_action_selection(action_id, blink_visible)` makes
those two packets overlay the status panel's generated tilemap. Pass `-1` for
the unselected state. The caller owns the 13-iteration blink clock and supplies
the phase from its match/menu state; no cadence guess is embedded in the panel.

The frame-8953 capture has `$061E=0`, and the five-tile payload spans
`$22AC-$22B0` and `$22CC-$22D0` are zero. That agrees with the no-selection
path. No direction was pressed in the capture, so there is no same-input
selected-phase validation; these visible action packets are ROM-derived, not
claimed as capture-verified output.

## Fresh match 0: receiver index and `$0441`

The kickoff routine reads the current match state after its A/B wait. At fixed
bank `$DAEF-$DB19` it first writes the initial player as `$05FB + 8`, runs the
formation helper, then computes the receiver:

```text
A = $00E2 & $07
if A >= 5: A = A - 5
X = A
$05FC = $DC82[X] + $05FB
$0441 = $05FC
```

The five ROM offsets at `$DC82` are `05 06 07 09 0A`; the extraction preserves
these exact bytes as `first_match_receiver_offsets_DC82.bin`. Match index zero
sets opponent `$002B=3`; the kickoff branch therefore selects `$05FB=0`, and
the receiver candidates are player slots 5, 6, 7, 9 or 10. The reduction of
`$E2 & 7` maps input values 5, 6 and 7 to indexes 0, 1 and 2 respectively; it
is not a general modulo-five operation.

The supplied FCEUX route capture shows `$0441` changing from `$08` to `$06` at
frame 8782. Its RAM snapshot at that frame has `$00E2=$11`; the ROM formula
maps `$11 & 7 = 1` to `$DC82[1]=$06`, matching the captured slot. This is a
frame-boundary cross-check, not an instruction-cycle trace. The later menu
snapshot at frame 8953 still has `$0441=$06` but `$00E2=$33`, confirming that
the receiver must be derived when kickoff selects it rather than from the
later menu snapshot.

Bank `$02` CPU `$8117-$8127` updates the three-byte `$E1-$E3` state after the
controller-read loop: it adds `$83` to `$E1`, `$0D` plus carry to `$E2`, then
`$11` plus carry to `$E3`. The cold-start FCEUX RAM captures show `$E2=0` at
frames 0–8 and `$E2=$0D` at frame 9, consistent with the first observed update.
This establishes a ROM update path and a live receiver example. It does not
establish every seed write/poll through the title, story, match setup, and
kickoff wait, nor a same-input instruction-cycle value at the `$0441` store.
The Godot match state must continue to supply the actual player slot/ID/energy;
slot 6 is not a production default.

## Verification limits

The packet verifier checks all four ROM map entries, stream pointers, two PPU
addresses per action, visible tile rows, hidden zero rows, and the no-selection
case. It proves the parser and source bytes, not same-input emulator pixels,
timing, palette, or attribute behavior. A muted FCEUX direction replay is still
needed to compare the selected blink output and cadence. The initial `$E2`
state/update count through match startup remains unresolved, so the first
receiver cannot yet be predicted from cold boot in Godot without an explicit
RNG state model or source trace.

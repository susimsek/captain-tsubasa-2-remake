# Animation `$8F` early actor OAM descriptors

## Source mapping

The supplied ROM is SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
In bank `$16`, the actor renderer reads the descriptor at record offset
`+$12` and resolves its two-byte pointer through `$8280 + 2 * descriptor`.
The animation-`$8F` appearance roots in bank `$14` issue `$F7` holds for
descriptors `$B8`, `$BA`, and `$B9`:

| Descriptor | Pointer-table bytes | Stream pointer | Preserved stream |
|---:|---|---:|---|
| `$B8` | `$83F0: 21 BB` | `$BB21` | `$BB21–$BB61` |
| `$B9` | `$83F2: 62 BB` | `$BB62` | `$BB62–$BB6C` |
| `$BA` | `$83F4: 6D BB` | `$BB6D` | `$BB6D–$BB7B` |

All three streams use only source OAM-run opcode `$00` and end opcode `$01`;
they contain no selector branches or jumps. The existing bank-$16 X/Y offset
tables and CHR/palette compositor are reused. Exact source file offsets,
lengths, and hashes are in `manifest.json`; runtime does not read the ROM.

## Frame-8481 validation

The muted FCEUX actor-call log
`reference/diagnostics/first_command_actor_oam_20261027_113609_utc/actor_draw_calls.csv`
is validation evidence only. Its first five records are `$0547/$055C/$0571/
$0586/$059B`, with descriptors `$B8/$BA/$BA/$B9/$B9`, selector `$00`, and
visible sprite counts `25/5/0/4/0`. The source OAM cursor boundaries are
`0→100→120→120→136→136` bytes. The focused verifier
`tools/diagnostics/verify_ee9f_early_actor_oam.gd` builds from the ROM-derived
actor records and compares all 34 visible OAM tuples and per-actor cursor
boundaries against that trace.

The no-advance cursor behavior for the two actors whose X coordinates are
outside the visible range is visible in the call trace and follows the source
renderer path: it writes the hidden Y byte at the current OAM cursor while
retaining the cursor for the next candidate. The Godot builder now mirrors this
source behavior. This check covers the captured selector-zero actor boundary;
the live route still needs to supply actor records, shared transform/clip
state, and renderer calls from the production scheduler.

# First-field actor `$90` source boundary — 2026-10-28

## Finding

The intermediate lineup's first actor records and first appearance/motion pose
are reconstructible from ROM bytes. The frame-8822 trace independently agrees
with that decode, so its actor RAM/OAM values are not needed as inputs. A full
route-time actor producer is not source-ready: the event task/worker launch is
not integrated, `$F5 $80` still needs the current holder/player record to set
shared graphics and palette state, and the earlier mirror state is not carried
by the Godot route. The `$90` lineup is also not the first-menu endpoint: by
frame 8953, scenario `$44` animation `$5C` has replaced it.

No standalone actor producer or frozen pose was added. The existing
`FirstCommandActorSourcePresenter` remains an endpoint helper with explicit
caller inputs, not a live route state source.

## ROM-backed first pose

Target ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

Fresh-match scenario `$1E` selects the actor animation in record
`07 45 90 F0` at file `0x0237EF`; the animation selector is `$0528=$90`. The
bank-$14 pointer table at `$8968` resolves ID `$90` to CPU `$98AB`, file
`0x0298BB`. The pointer-bounded 26-byte stream has SHA-256
`34f5ad052c586a941c1541be51b06324608b5ad70ab38984b3b2467a9269a848` and is:

```text
F5 80
F4 08 09 0A 0B
F1 00 58 00 C3 09
F1 00 4B 00 C3 01
F1 00 4D 00 C3 05
F0
```

The three `$F1` packets supply the actor-record index, motion selector,
appearance selector and starting X/Y bytes. The record pointer table at
`$88E4` / file `0x0288F4` has the first three targets `$0547/$055C/$0571`.
Their exact source mapping is:

| `$F1` packet | Record | Appearance-table entry → root | Motion-table entry → root | First appearance pair |
| --- | --- | --- | --- | --- |
| `00 58 00 C3 09` | `$0571` (index 2) | `$AC47[$58]` → `$B09D` | `$A1B4[$00]` → `$A38A` | `$B09D`: `04 0A` → descriptor `$0A` |
| `00 4B 00 C3 01` | `$0547` (index 0) | `$AC47[$4B]` → `$B026` | `$A1B4[$00]` → `$A38A` | `$B026`: `04 00` → descriptor `$00` |
| `00 4D 00 C3 05` | `$055C` (index 1) | `$AC47[$4D]` → `$B040` | `$A1B4[$00]` → `$A38A` | `$B040`: `04 04` → descriptor `$04` |

Appearance pointer bytes are at file `0x02AD07` (`9D B0`), `0x02ACED`
(`26 B0`) and `0x02ACF1` (`40 B0`). The script bytes at file `0x02B0AD`,
`0x02B036` and `0x02B050` respectively begin `04 0A`, `04 00`, and `04 04`.
The first pair sets a four-update appearance timer and its descriptor; the
following pointer is `$B09F`, `$B028`, or `$B042`.

Motion-table entry `$A1B4[$00]` at file `0x02A1C4` is `8A A3`, selecting
`$A38A`. Its first seven bytes at file `0x02A39A` are `01 01 00 00 00 00
00`: one motion update with zero X/Y deltas. The update advances the actor
motion pointer to `$A390` and leaves the packet's coordinates `$00/$C3`
unchanged. Thus, after the first actor update, the source-derived records have
descriptors `$00/$04/$0A`, appearance cursors `$B028/$B042/$B09F`, motion
cursor `$A390`, and unchanged `$00/$C3` coordinates. This is the first-tick
ROM result, not an emulator record copied into the model.

## Independent live-trace check

The muted same-input FCEUX trace at
`reference/diagnostics/first_command_actor_oam_20261027_113609_utc/` observed
scenario `$1E`/event `$45` and the `$90` actor-worker launch around frames
8789–8821; its first per-actor draw rows are frame 8822. At that draw, records
`$0547/$055C/$0571` have the ROM-derived pointers, descriptors and coordinates
above, and the motion pointer has advanced to `$A390`. The same rows observe
`$0546=$08` and CHR selectors `$08,$09,$0A,$0B`. These are validation results;
they are not fed into the ROM decode.

Trace CSV SHA-256:
`actor_draw_calls.csv` —
`a8093fd87401c72d78173736a7a329498ccd106a70682df992d6762613f38519`.
The trace metadata records muted FCEUX, the supplied ROM identity, and the
input timeline hashes; no captured screen image is used by this audit.

At the frame-8953 first-menu endpoint, the active actors instead use scenario
`$44` / animation `$5C`: the draw trace shows main pointers `$B5AC/$B5AE/$B5B2`
and held descriptors `$00/$04/$0A`. Those roots and held poses are covered by
[`fresh_kickoff_actor_initialization_rom_audit_20261027.md`](fresh_kickoff_actor_initialization_rom_audit_20261027.md).
Do not carry the earlier `$90` lineup forward as the endpoint pose.

## Exact `$5C` endpoint inputs and remaining producer chain

Animation `$5C` and its three final actor records are byte-decodable. The
existing `FirstCommandActorSourcePresenter.configure_endpoint_pose()` API
still requires these caller arguments; they are separate from the `$5C`
packet bytes:

| Presenter input | Endpoint evidence / value | Source producer and status |
| --- | --- | --- |
| `player_id` | `$08` (endpoint trace oracle) | `$F5 $80` → bank-$14 `$81BA/$81CF` reads holder `$0441` and resolves the player record. The hash-bound RNG replay for the audited input timeline derives holder slot `$06` and player `$08`; the route does not yet produce `$0441` generically. Do not hardcode `$08`. |
| `palette_record_index` | `8` (same player record) | `$81BA` player-palette path; source table entry for ID `$08` is `$B834` (`15 0F 30 30 30`). The route must pass the selected player identity from its live holder state. |
| `mirror_mode` | `$40` (endpoint trace oracle) | Earlier scenario `$36` `$FD 00` derives this from `$0441`/player data and `$0638`; fixed-bank `$ED0C` copies `$052A` to `$0517`. This producer and state carry are not implemented in the route. |
| `universal_color` | Active background palette entry 0; no independent constant in the actor packet | The normal-player palette writer leaves slot 0 unchanged. The route must pass entry 0 from its source-derived active field palette. A captured PPU color is not a runtime source. |
| `scroll_x` | `$00` at endpoint (trace oracle) | Shared renderer state `$0538`; the actor presenter takes it explicitly. Its route-time producer/carry is not implemented. |
| `clip_y_min`, `clip_y_max` | `$00`, `$FF` from `$800F` initialization | ROM source initializes `$0540/$0541`; route-time worker/renderer state still has to supply those values to the presenter. |

Separately, the worker must execute the source handoff and cadence that produce
the rows consumed by the presenter: scenario wait `$0519`, task/NMI context
(`$0011`, `$001B`), actor-worker fields `$053A–$053D`, and the `$EE9F` actor
tick around `$F1`, `$83D9`, and `$84DC`. `$800F` also sets actor order/clip
state. The route does not yet execute this task/worker path, so static `$5C`
decode alone cannot establish when the endpoint pose exists.

The values marked “trace oracle” are comparison results, not source inputs.
The ROM source paths for holder selection, mirror calculation, background
palette ownership, scroll, and worker cadence must feed the presenter before
the final actors can be integrated. Endpoint RAM/OAM, screenshots, and frozen
actor arrays remain validation-only.

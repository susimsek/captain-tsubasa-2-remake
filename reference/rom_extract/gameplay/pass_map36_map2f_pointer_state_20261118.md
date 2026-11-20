# PASS Route Map-Worker Pointer Continuity

## Claim

During the first PASS route, zero-page `$0056-$0057` carries the tile-record pointer left by the most recently expanded metatile. Map `$36` leaves pointer `$B310` before the route enters scenario `$2E` / map `$2F`; each resumed map-$2F batch then replaces it with the pointer for that batch's last metatile. This RAM output is part of the ROM worker behavior, in addition to the PPU queue bytes.

## ROM evidence

- Source ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Bank `$0B` map worker `$85C2-$86D3`, file offset `0x0165D2`, SHA-256 `1aab318fd595b2cf9f82ed8176340dfe43d4fbdc792e9204ede31c2d21c79e15`.
- The worker stores the metatile ID at `$85C2`; its `$8654-$866D` path computes the selector/metatile tile-record pointer, finishes the low byte at `$8665`, and stores the high byte at `$866D`.
- The map-$2F extraction manifest pins selector `$01`, block map bytes `15 16 15 16 15 16 15 16 17 18 17 18 17 18 17 18 26 26 26 26 26 26 26 26 25 25 25 25 25 25 25 25`, and the formula `window=(selector<<12)+(metatile_id<<4)`, `CPU=$A000+(window&$1FFF)`. The first three IDs `$15,$16,$15` therefore leave `$B150` in `$0056-$0057`.
- The pinned map-$36 selector-$01 block map has `$31` at cells 24–31. Its final rows therefore leave `$B310` in `$0056-$0057` before map `$2F` begins.

## FCEUX observations

FCEUX 2.7.0, NTSC, NewPPU, audio muted; supplied ROM hash above. The trace replays the recorded opening, title, and PASS input prefix from an anonymous checkpoint at source frame 9042, then captures frames 9043–9485 twice. The two passes have the same normalized event hash: `681607ba0a2ef4cf3d613e474b4bf1d5d196bed7b5be4413192f620c91cae0b9`.

- At frame 9267, the map-$36 worker has advanced through cell 24 (metatile `$31`); `$0056-$0057=$10,$B3` and the pointer persists into the later scenario-$2E/map-$2F setup.
- At frame 9464, the map-$2F wait boundary still has `$10,$B3`. Its resumed three-cell batch expands `$15,$16,$15` and yields with `$50,$B1`.
- At subsequent map-$2F wait boundaries, `$0056-$0057` matches the tile-record pointer of the last previously expanded map cell. For example, frames 9465–9469 observe `$B150,$B160,$B170,$B180,$B170`.
- At frame 9475, `$EB8B` observes the exhausted map cursor `$05C7-$05D3 = 24 C0 00 01 01 2F A0 80 00 02 00 00`; map cell 31's metatile `$25` leaves `$0056-$0057=$50,$B2`. The same frame's source path changes `$0516` from `$41` to `$51` and dispatches the terminal callback.
- The repeated trace includes full CPU, stack, RAM, mapper, and PPU-RAM signatures through frame 9485. The pass and repeat are local ignored diagnostics at `reference/diagnostics/pass_receiver_waiter_boundaries_20261118_163552_utc/events.csv` and `events_repeat.csv`; they are validation evidence, not runtime resources.

## Godot consumer and verification

`RomSlot15MapBatchExecutor` now records the final `$0056/$0057` pointer writes for each expanded metatile from the ROM selector/metatile formula. `RomGameplayTaskScheduler` checks the ordered low/high pointer writes against each map call before adopting the batch. The slot-$09 scenario-$2E wait profile validates the inherited map-$36 pointer at map-$2F cell zero, then derives later expected pointers from the hash-checked map-$2F block map. Runtime state still comes only from the Godot source route; the FCEUX trace is not used to seed it.

The profile predicate passed against the FCEUX slot-$09 rows from frames 9464–9475, including terminal map index 32. The ordinary-input Godot route reached map index 32 and the source-selected slot-$15 terminal callback; a scheduler record accessor mismatch was found on that callback and is being corrected. The earlier frame-9475 route stop was still at map index 18, so the frame-by-frame worker/NMI cadence is not aligned. Pointer continuity and map batches are source-backed, but this report does not establish the eventual holder decision boundary.

## Limits

This report does not establish visible pixel parity, audio parity, exact CPU/PPU cycle timing, or physical NES timing. The logged PPU RAM hashes identify states only; they do not identify every pixel fetch. Same-input visual/audio comparison and the final PASS result boundary remain open.

# Slot-$15 map-$42 full-row runtime

## Result

The live Godot route now processes all 32 ROM map cells through slot `$15`'s
`$8572->$85C2` worker in eleven source-selected batches. It consumes each
generated queue through the route's normal-NMI abstraction and matches the
FCEUX queue snapshots 8–18 by SHA-256. Batches of three cells produce 96 queue
bytes and 51 `$2007` writes; the final two-cell batch produces 64 bytes and 34
writes. No map entry or queue state is injected.

The final batch follows the ROM's map-exhausted branch. After `$85C2` returns,
`DEC $05C9` reaches zero at `$85A4->$85A7`; the `BEQ $85B6` skips the remaining
per-batch calls and reaches the `$85BE JSR $C515` call site. The runtime now
preserves this terminal call site instead of treating it as the ordinary
`$856F` yield. After snapshot 18's queue is consumed, the route resumes slot
`$15` at `$85C1`, follows the callback's zero-placement return through
`$8334->$819C->$C512`, and reaches the verified `$CAF7` finish. The slot's
ready/delay bytes are cleared without advancing into later scenario work. See
the [terminal callback return report](slot15_map42_terminal_return_20261029.md).

## Source evidence

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`, SHA-256
  `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Bank `$0B` begins at file offset `$016010`; the worker span at CPU `$8572`
  begins at file offset `$016582` and has SHA-256
  `098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502`.
- Setup at `$8564-$8568` initializes `$05C9` to `$20`. The worker derives the
  map index as `$20-$05C9` at `$858B-$8592`. It allows at most three cells per
  batch, decrements `$05C9` at `$85A4`, and branches to the terminal yield when
  the count reaches zero.
- Selector `$01` resolves map `$42`. ROM-derived map bytes and metatile tile
  and attribute resources are size/hash checked by
  `rom_slot15_map42_first_batch_executor.gd` before expansion.
- FCEUX pass traces show the final two `$85C2` calls at source frame 8478 for
  map indices 30 and 31. Snapshot 18 at frame 8479 contains the resulting
  64-byte queue and 34 PPU data commits.

## Batch comparisons

| Batch | Map indices | Metatiles | Queue bytes | `$2007` writes | FCEUX queue SHA-256 |
| --- | --- | --- | ---: | ---: | --- |
| 1 | 0–2 | `$14,$14,$14` | 96 | 51 | `1af864cf8efad02dfc1f00baf08b8c7e037c5fe931ebc1a64b49ac92b2438d52` |
| 2 | 3–5 | `$14,$14,$14` | 96 | 51 | `0f0c448f8edac511fe7bf548ed2259a8bd4e581cdfc660221fac97a5912fdd1b` |
| 3 | 6–8 | `$14,$14,$33` | 96 | 51 | `85c7cc381b97e49c5227d6cc9a2bd5a54a96f43ebd97fff82422f9321bbcae1e` |
| 4 | 9–11 | `$33,$33,$33` | 96 | 51 | `5e473377dfa6cb10a9e3706885787a62791f28381c3ffb5d8b3c5610adf5e3ab` |
| 5 | 12–14 | `$33,$33,$33` | 96 | 51 | `a92be740e48050139c0a1ba3c4f1e2e0a60346d9b220d9973792c6675d77046e` |
| 6 | 15–17 | `$33,$15,$16` | 96 | 51 | `39ab0d71c08bb3320b40421aa3d174178e1006d05346114b16fde3efd2e54d6d` |
| 7 | 18–20 | `$15,$EA,$EB` | 96 | 51 | `cc0b05bd7e05b3ffe9b6027c7597e4bab9e7667cb55404d68420303685c209de` |
| 8 | 21–23 | `$16,$15,$16` | 96 | 51 | `10c9ebf55bd12442537d27734c3ed0558b59d22b9ce6fcb211fe8196844882d2` |
| 9 | 24–26 | `$14,$14,$14` | 96 | 51 | `5232a6f3022517566cdb4956390d8f4293c7b9883e8476dfdc15c558b35ad2b3` |
| 10 | 27–29 | `$14,$14,$14` | 96 | 51 | `1a11dd4a2b10b6f731bae110531aaf6740c40fae73daa53eee3a9b9b81e12b1e` |
| 11 | 30–31 | `$14,$14` | 64 | 34 | `247690436ccaeabef5785af9a596a5c0f768bfbba1d4aec05a4bae2a0e004bba` |

## Verification and limits

Focused command:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_slot05_live_ed01_row_bbe3.gd
```

It passes all eleven live batches, queue hashes, scheduler transitions,
observed `$2007` counts, and the terminal callback/task-finish boundary. It does
not render a visible field: the field's full
CHR/palette/scroll/raster context is not yet sourced or connected to the
renderer. Active actors, command-menu content and interaction, route audio,
physical cycle timing, and the scheduler continuation after the `$CAF7` finish
remain unresolved. Queue matches are not a claim of full-screen visual
equivalence.

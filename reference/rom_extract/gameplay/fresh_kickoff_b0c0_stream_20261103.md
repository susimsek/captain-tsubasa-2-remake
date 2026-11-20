# Fresh Kickoff `$B0C0` PPU Stream

## Result

The live Godot route now runs the checked `$B305-$B327` stream after the first
`$0D` clear and returns through `$B1BA` to `$A503` at source frame 7267. The
stream applies six ROM-parameterized fills and the ROM packet at `$B328` to the
existing PPU bus presenter. This is a partial match-setup result; `$A503` itself
has not executed, and the route does not yet reach the first in-match command
menu.

## ROM provenance and command decoding

The source image is `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`,
SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Under the current MMC3 setup, PRG bank `$01` maps at `$A000` and bank `$00`
maps at `$8000`. Run
`python3 tools/diagnostics/extract_fresh_match_b0c0_first_command.py` to
regenerate the source spans and manifest.

| Source span | File offset | Size | SHA-256 |
| --- | ---: | ---: | --- |
| `$B0C0-$B1C8` dispatcher | `0x0030D0` | 265 | `0a4c492d3977ff466d97e92106b83393028ad024d59c228ec601ab833cd0769e` |
| `$B305-$B327` command stream | `0x003315` | 35 | `3907025e26e2b3f305a682282af798b2d04dafd2498ab061741d49d6e7c40790` |
| `$B328-$B33C` packet data | `0x003338` | 21 | `7c0a9d06e6a511e8b5c099080e1bb21cbd56ca90f2a76907ad9e0d3a11990ca9` |
| `$B1C9-$B1D2` pointer helper | `0x0031D9` | 10 | `3b45c08a076cbeea84c1ea0f88c57d0dc7785301ef1455c30d800576af1dd8a7` |
| `$B1D3-$B1E7` argument helpers | `0x0031E3` | 21 | `494c973e66d6ef485a4a18aac9afe85339949bd6c4cd313a6d539fead5e25056` |
| `$98EA-$9979` PPU fill helper | `0x0018FA` | 144 | `32b8c92b5020a5e3ec416b2f421baae64ee1c49a2154eb8ca4550324e7f9c18a` |
| `$97B6-$9889` PPU packet reader | `0x0017C6` | 212 | `c534baeaa667d97b133b1fedb4eec77aed024bb056101f93237031fb6af7eab2` |

The ROM stream decodes as follows:

| PC | Bytes | Source behavior |
| --- | --- | --- |
| `$B305` | `0D` | `$B1A4->$98A0`: clear nametable `$2000-$27FF` (already integrated). |
| `$B306` | `05 45 21 16 89` | `$B13B->$98EA`: 22 horizontal bytes of `$89` at `$2145`. |
| `$B30B` | `05 A5 21 16 BA` | 22 horizontal bytes of `$BA` at `$21A5`. |
| `$B310` | `05 A5 22 16 89` | 22 horizontal bytes of `$89` at `$22A5`. |
| `$B315` | `04 64 21 0A 8A` | `$B12F->$98EA`: 10 vertical bytes of `$8A` from `$2164`, stride `$20`. |
| `$B31A` | `04 7B 21 0A 8A` | 10 vertical bytes of `$8A` from `$217B`, stride `$20`. |
| `$B31F` | `04 CF 21 07 BB` | 7 vertical bytes of `$BB` from `$21CF`, stride `$20`. |
| `$B324` | `00 28 B3` | `$B0F7->$97B6` reads the 21-byte ROM packet at `$B328`. |
| `$B327` | `0F` | `$B1BA RTS` returns to `$A503`. |

The packet records at `$B328` are
`01 44 21 88`, `01 5B 21 90`, `01 A4 22 8E`, `01 BB 22 93`, and
`42 33 22 91 8F`. The `$97B6` direct branch interprets the low six bits of each
record header as its payload count and bit 6 as the final-record flag, writes
the encoded PPU address through `$2006`, then writes the ROM payload through
`$2007`. The terminal record writes `$91,$8F` at `$2233-$2234`.

Both `$98EA` and `$97B6` choose a direct PPU path when `$004A | $004B == 0`.
The production input is sourced from the ROM `$C64E-$C679` reset RAM clear:
the route now records reset-proven zero writes for `$004A/$004B`, and the
executor rejects an unknown or conflicting source-ledger value. As an
independent behavioral check, both muted FCEUX passes have `$004A=$00` and
`$004B=$00` in the frame-7266 `$C421` and `$C449` RAM snapshots. Those snapshots
are not passed to the Godot executor. Because earlier interrupt effects remain
partially modeled, the reset proof plus the observed snapshot does not establish
that every possible intervening writer has been modeled.

## Godot integration and verification

`scripts/gameplay/rom_fresh_match_b0c0_stream_executor.gd` hash-checks the ROM
spans, validates the direct-branch inputs, decodes commands `$05/$04/$00/$0F`,
produces ordered `$2000/$2001/$2006/$2007` events, records source RAM writes,
and returns a pending `$A503` continuation. `kickoff_route_runtime.gd` applies
those events through the live PPU presenter. It applies 202 bus events and 99
nametable data writes. The live memory samples match the packet-derived expected
values at `$2144,$2145,$215A,$215B,$2164,$217B,$21CF,$2233,$2234,$2284,$228F,
$229B,$22A4,$22BB`; the PPU address ends at `$2235`, and the PPUCTRL shadow
returns to `$88`.

Focused verification:

```text
CT2_ROUTE_FINAL_FRAME=7300 godot --headless --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

Result: PASS on Godot 4.7.2. The production route ends at `$A503` on frame
7267; the same-input FCEUX trace also enters `$A503` on frame 7267. The verifier
checks the source call path, final CPU/RAM contract, 202 PPU events, 99 applied
nametable writes, expected PPU memory samples, and explicit timing limits.

FCEUX `$B0C6` callback deltas from `$B306` through `$B327`, followed by the
`$B1BA` and `$A503` hooks, match in both muted passes:
`443,443,443,743,743,581,691,29,2` cycles. A separate py65 execution from the
`$B306` boundary to `$A503` reports 4,121 CPU cycles; the FCEUX callback
timestamps span 4,118 cycles. The remaining three-cycle difference is at the
RTS callback boundary. These are software/emulator measurements, not physical
NES timing, and the Godot route does not use the measurements as a delay.

## Remaining gaps

- The B0C0 source-derived PPU bytes have not yet been compared with a same-input
  FCEUX PPU snapshot or rendered frame at `$A503`.
- The later `$A503` prefix is now implemented through its first `$9D27` call;
  see the [A503 entry report](fresh_kickoff_a503_entry_20261103.md). Decoder
  output, the rest of `$A503-$A610`, the `$811F` return, `$C572->$DB62` setup,
  field/menu rendering, and menu navigation are still open.
- Fourteen earlier interrupt effects and physical NES/MMC3/PPU subframe timing
  remain unresolved.
- Route audio parity, final screenshot/pixel parity, and packaged runtime
  independence from ROM/emulator files remain unverified.

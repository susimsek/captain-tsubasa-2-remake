# Slot-$05 `$EE` formatter `$003C` source

## Runtime status update

The live worker now executes the row loop through `$BBE0: ED 00 FC`. Its own
ROM instructions clear `$003C` at `$8954`, increment it to `1` at `$8960`, and
restore it to `1` after the `$ED` name-emission helper. The worker then stops
before `$BD9C: EE 00 FC`, so this verifies the formatter input producer but
does not execute the `$EE` formatter. See
[`slot05_descriptor01_ed_row00_runtime_20261029.md`](slot05_descriptor01_ed_row00_runtime_20261029.md).

## Finding

For descriptor `$01`, `$003C` is produced by the bank-$18 descriptor-row loop;
it is not an upstream caller input. The loop clears `$003C`, derives it from
the descriptor row's progress byte and the worker-owned `$05C5` counter, then
calls the `$8986` token parser. The live route has now executed this producer
for row `$BBE0` and verified `$003C=1` before its `$ED` handler. Later `$EE` and
`$ED 01` rows remain source-derived expectations, not executed route results.

The selected descriptor is `$B464`; its row progress bytes are `01,01,03,03`
for streams `$BBE0,$BD9C,$BBE3,$BD9F`. The second wrapper's worker setup writes
`$05C5=0` before its first `$C515` yield. Therefore the first descriptor pass
statically derives `$003C=1,1,3,3` for the four rows. The live route confirms
the first value during `$BBE0` execution and records `$003C=1` at the following
`$BD9C` boundary. Because `$EE 00` has not been entered, its value at the
handler remains unverified; `$EE 01` at `$BD9F` is static analysis only.

## Hash-bound source

Supplied ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Bank `$18` occupies the MMC3 low window `$8000-$9FFF`; its file base is
`0x030010`.

| Source | File offset | Length | SHA-256 | Effect |
| --- | ---: | ---: | --- | --- |
| `$8878-$8888` | `0x030888` | `0x11` | `ec49c740426c5c08e8020cba012b40c78f78e950bd0e0ae1c17ed9a06308f7fe` | Includes `$8881: STA $05C5` after `LDA #$00`; it runs in the common descriptor worker setup before the `$C515` yield. |
| `$8949-$8985` | `0x030959` | `0x3D` | `19b689ad3d838b32bb4745ba3a0ef1085bacd94528ba37b522d76eb897efc230` | For each descriptor row, clears `$003C` at `$8954`, compares the row progress against `$05C5`, decrements the progress and increments `$003C` at `$8960` until equal, then calls `$8986`. After the row batch, it publishes `$0515=$80` and increments `$05C5` at `$897E`. |
| `$8986-$89B9` parser | `0x030996` | `0x34` | `46ac5f0183f5e0d90c90f248768b6df75bae9c5300a679cc83dfc21efb53888e` | Consumes the selected descriptor text pointer and dispatches its control token. |
| `$89BA-$89DB` token vectors | `0x0309CA` | `0x22` | `74f4bd039c15b503a6b4d4a71652c4c957a179f05cf105c142c04eb740759ebe` | The `$EE` vector resolves to `$8B2F`. |
| `$8B2F-$8B47` `$EE` handler | `0x030B3F` | `0x19` | `ae8a2a4125cb75968151ad77665a895dc7718501a0203a198dc68eb283fc2c48` | Selects `$0028/$0029` by the row operand and enters `$8C55`; it does not write `$003C`. |
| `$8C55-$8C84` formatter | `0x030C65` | `0x30` | `5e8434b7ea9df80165514fcbde32a3800ac76e8ddd3d12c13c5e2428dedf836b` | Reads `$003C`; its first branch returns when `$003C==1`. |
| `$8C85-$8CA4` character writer | `0x030C95` | `0x20` | `2eddef720bfa62f995abd530c095e2953cc0555fd7aa8971bce35277e8ec97f7` | Uses `$3D` as the destination index and writes a character tile to `$04A8,X`; its temporary `$003C` decrement is restored. |
| `$C51E-$C520` divider vector | `0x03C52E` | `0x03` | `7b0a50829c23361f1f95e0b52657262d62358c50623da017b3c721ba27ba81e1` | Jumps to the fixed-bank divide routine used by `$8C55`. |
| `$CD3C-$CD76` divider | `0x03CD4C` | `0x3B` | `2d996c8e5e587175f76672794f405945b4c1c981fa6775cf93b8971f39a008` | For the zero input here, produces zero quotient and remainder. |

Descriptor `$B464`, row streams and their hashes are preserved in
[`field_entry_window_01/manifest.json`](field_entry_window_01/manifest.json)
and summarized in
[`slot05_second_descriptor_bbe0_static_audit_20261029.md`](slot05_second_descriptor_bbe0_static_audit_20261029.md).

## `$EE` branch inputs and result

The first worker pass starts with `$05C5=0`. The `$8949` row loop resets
`$003C=0`, then subtracts one from the row progress byte and increments
`$003C` until the byte equals `$05C5`. Thus the row values produce:

| Descriptor row | Progress | Token / operand | `$003C` at handler on first pass |
| --- | ---: | --- | ---: |
| `$BBE0` | 1 | `$ED 00` | 1 |
| `$BD9C` | 1 | `$EE 00` | 1 |
| `$BBE3` | 3 | `$ED 01` | 3 |
| `$BD9F` | 3 | `$EE 01` | 3 |

The `$EE` handler reads `$0028` for operand `0` and `$0029` for operand `1`;
these are NES internal-RAM mirrors of `$0628/$0629`. Fresh-match setup provides
zero for both bytes, and the fresh-period path provides `$0027=0`, selecting
the ordinary `$0028/$0029` read rather than the `$0027==4` alternate at
`$0610,X`.

For `$EE 00`, `$8C55` sees `$003C=1`, decrements it to zero, and returns before
formatting. For `$EE 01`, it sees `3` and enters formatting. The zero value
passes through `$C51E->$CD3C`, yielding zero quotient and remainder. The
formatter then calls `$8C7A`, which adds `$33`, and `$8C85` writes that tile to
`$04A8,X` (with `X=$3D`); the writer's `$003C` decrement is restored before
return. The later `$6F==0` branch ends the formatter after this zero tile.
Thus the ROM source predicts different first-pass outcomes: `$EE 00` returns
without a tile, while `$EE 01` writes one `$33` tile. Neither `$EE` path has
been executed by the current Godot route, so its exact output and destination
index remain unverified runtime state.

The generic worker text scanner also writes `$003C` at `$8641/$864E`, and the
character-buffer helper temporarily decrements/increments it at `$8C87/$8C9C`.
Those writes do not supply the `$EE` input: the descriptor-row loop resets and
derives `$003C` immediately before calling the token parser for each row.

## Runtime consumer contract and boundary

Do not expose `$003C` as an externally injected route input. The live slot-$05
worker now derives the row-0 value from descriptor progress and source-owned
`$05C5` at `$8949`, executes `$BBE0: ED 00 FC`, and adopts its CPU/RAM/stack
writes. It stops before `$BD9C: EE 00 FC`; the `$EE` formatter and later rows
are still pending. Continue from that source boundary through the real
queue/NMI yields; do not set the program counter or substitute packet-builder
output for a source return.

Static bytes resolve the `$003C` producer and formatter branches; the focused
runtime report records the first row's execution. No additional FCEUX hook is
required to identify the producer. The `$EE` rows and their formatter effects
still need live worker integration. This audit made no FCEUX, `GOALS.md`, or
`PLANS.md` changes and ran no tests.

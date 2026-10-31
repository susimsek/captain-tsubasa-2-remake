# `$0515` transfer-buffer writer cross-reference — 2026-10-29

## ROM and bank mapping

Supplied ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
Bank `$18` at CPU `$8000` uses file base `0x030010`; fixed bank `$1E` at CPU
`$C000` uses file base `0x03C010`.

## Relevant `$0515` state transitions

| Role | Bank / CPU | File offset | Bytes | Condition and effect |
|---|---|---:|---|---|
| Renderer reserves the buffer | `$18:$888E-$8892` | `0x03089E` | `A9 01 8D 15 05` | The `$8889` worker continuation reaches this only after `$0515` reads zero. It sets `$0515=1` before continuing to build another row. |
| Renderer publishes a completed packet | `$18:$8976-$897A` | `0x030986` | `A9 80 8D 15 05` | The bank-$18 `$88B9` row builder, called from `$88A6`, sets `$0515=$80` after writing its transfer packet in `$04A5`. |
| NMI transfer consumer clears the ready flag | `$1E:$C956-$C95A` | `0x03C966` | `A2 00 8E 15 05` | The consumer enters this instruction only when the normal NMI queue path reaches `$C951` and `$0515` is negative (bit 7 set). It writes zero, then copies packet bytes from `$04A5` to PPU `$2006/$2007`. |

The three byte spans are tied to the supplied ROM; SHA-256 values are,
respectively, `58e788abf713f937db82284caf45c23f13f3d444db9c676d69668bf2c2c6305f`,
`b039806fbb8e47e0810206e67c2f50cf9e444a943cfcc11ed48ea339b3c66aa2`, and
`445f13a3a22a1f98020215be070c70871d691c0fc22d1815ceff8c62c0d21f15`.

## Reachable NMI consumer path

The NMI handler's normal path calls `$C8FB` at `$C799`; the call instruction is
file `0x03C7A9`, bytes `20 FB C8`, SHA-256
`77d15140839e5c0213db71f8555d4e6d19b5a903c8bdbc85f39058c5baedce8a`. The
handler reaches this path when `$001B.6` is clear. The existing
[`first_command_root_task_bootstrap_and_nmi_20261028.md`](first_command_root_task_bootstrap_and_nmi_20261028.md)
maps that gate and shows that `$C7F0` sets the `$001B.7` scheduler-ready latch
after the `$C799` call returns.

At `$C8FB`, `AD 98 04 F0 51` reads `$0498` and branches to `$C951` only when
that primary transfer queue is empty. Otherwise it processes the queued
`$0499` records and returns without reaching the `$0515` consumer. The
`$C951-$C981` secondary-queue code is file `0x03C961`, length `0x31`, SHA-256
`85cca72362c564bc3b73c1fc8bb8c051dca00e975392963533330238037aebf9`:

```text
$C951: AD 15 05    LDA $0515
$C954: 10 2B       BPL $C981       ; return unless bit 7 is set
$C956: A2 00       LDX #$00
$C958: 8E 15 05    STX $0515      ; clear ready flag
$C95B: BD A5 04    LDA $04A5,X    ; begin secondary packet list
...
$C981: 60          RTS
```

The full `$C8FB-$C981` control-flow span is file `0x03C90B`, length `0x87`,
SHA-256 `7509e02000e7dde21037b3c3532265f784744e51fa0aa03ee5edeb778e2aecb7`.
It contains the `$0498` gate, primary-queue path, and the conditional `$C951`
secondary-queue path. These source bytes establish that the flag is cleared
before the secondary packet is copied during the normal NMI routine.

## Relationship to the `$8889` polling loop

This source path plausibly and directly drives the bank-$18 worker's wait:

1. The renderer waits for `$0515=0`, sets it to `1`, and builds a packet.
2. The row builder publishes the packet by setting `$0515=$80`.
3. A normal NMI calls `$C8FB`. Once `$0498=0`, `$C951` sees bit 7 set, clears
   `$0515` to zero, and copies the `$04A5` packet to the PPU.
4. The same NMI later sets `$001B.7`; the task scheduler can then resume the
   worker at `$8889`. It observes zero and starts the next row, or sees a
   still-nonzero value and yields again.

The cross-reference establishes the ROM-side producer/consumer conditions and
instruction order. It does not establish exact NMI/cycle timing or how many
wait iterations occur on a route. Other absolute `$0515` setters exist in
unrelated banked routines; this report classifies only the menu-renderer path
above and does not claim every indirect store to this RAM address has been
excluded.

## Godot component status

[`RomNormalNmiPpuQueueConsumer`](../../../scripts/gameplay/rom_normal_nmi_ppu_queue_consumer.gd)
loads only the preserved, hash-checked `$C8FB-$C981` and `$C799` source spans.
For a caller-owned normal-NMI event, it applies the `$0498==0` and `$0515.7`
gates, clears `$0515` before reading the secondary packet list, and returns the
ordered `$2002/$2006/$2007` bus operations. The caller still owns PPU register
side effects. `verify_rom_normal_nmi_ppu_queue_consumer.gd` passes on Godot
4.7.2, including the gate, packet format, source-byte provenance, and rejection
paths. This is component-level verification; `KickoffRouteRuntime` does not
yet call it, and the full task/NMI event chain remains unintegrated.

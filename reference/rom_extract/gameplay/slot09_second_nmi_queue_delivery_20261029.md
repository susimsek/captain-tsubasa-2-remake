# Second NMI queue delivery after slot-$09 save — 2026-10-29

## Result and boundary

A second caller-supplied NMI can now advance the production source runner from
the slot-$09 `$CB0F` save / `WAIT_FOR_NMI_READY` boundary. The runner first
checks that its pending `$001B/$0498/$0515/$04A5` state still equals the
source-owned snapshot captured after the packet producer. It then calls the
existing normal-NMI service, which validates the ROM-backed `$C799->$C8FB`
path and feeds that live RAM to the secondary-queue consumer.

The consumer returns 20 ordered PPU bus events for the two live packets. They
are returned in the route result and are not applied to a renderer. The NMI
sets the scheduler-ready latch; the source scan clears it and selects yielded
slot `$01` first. The runner stops before that task body, whose next saved
continuation is `$CA52`. It does not select or resume slot `$09` at `$EB8B` on
this NMI. The runner contains a conditional `$EB8B` dispatch only for the case
where the actual source scan selects slot `$09`; that branch was not exercised
in this run.

The NMI frame label in the focused verifier is supplied by the caller. This
establishes the source transition and event order, not physical NMI cadence or
an observed frame/dot timestamp.

## Source queue and hashes

Supplied ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

The menu worker source leaves `$0498=0`, `$0515=$80`, and these packets in
`$04A5`:

```text
07 21 22 00 00 00 00 00 00 00
07 41 22 9C A8 20 34 2E A8 9D
```

The normal queue consumer manifest is
[`normal_nmi_ppu_queue_transfer/manifest.json`](normal_nmi_ppu_queue_transfer/manifest.json).
It hash-checks fixed-bank `$C8FB-$C981` at file offset `0x03C90B`, 135 bytes,
SHA-256 `7509e02000e7dde21037b3c3532265f784744e51fa0aa03ee5edeb778e2aecb7`,
and the `$C799->$C8FB` JSR at offset `0x03C7A9`, 3 bytes, SHA-256
`77d15140839e5c0213db71f8555d4e6d19b5a903c8bdbc85f39058c5baedce8a`.

With live `$0498=0` and `$0515.7=1`, the source clears `$0515` before
reading packet bytes. For each packet, it reads `$2002`, writes high and low
address bytes to `$2006`, then payload bytes to `$2007`. The returned event
stream contains:

- Packet 1: destination `$2221`, seven zero-byte `$2007` writes.
- Packet 2: destination `$2241`, `$2007` values `9C A8 20 34 2E A8 9D`.

The route keeps these bus events as source output; it does not model
PPUSTATUS/PPUADDR latch effects, PPUDATA memory writes, or visible pixels.

## Verification

Focused verifier:
[`verify_rom_slot09_second_nmi_queue_resume.gd`](../../../tools/diagnostics/verify_rom_slot09_second_nmi_queue_resume.gd)

Command run:

```text
godot --headless --path . --script tools/diagnostics/verify_rom_slot09_second_nmi_queue_resume.gd
```

Result: PASS on Godot 4.7.2. It checks the preserved first wait boundary, live
two-packet queue, normal-NMI source route, all 20 ordered bus events, no PPU
application, and the actual scheduler selection of slot `$01` with saved
record `[00,26,00,01]`. A negative case changes the pending `$04A5` byte before
the second NMI; the route rejects it before servicing the edge.

## Next source boundary and limitations

The next selected task is root slot `$01`, with the yielded record now at
zero-delay and its saved continuation word resolving to `$CA52`. The existing
`$CA52->$EE9F` executor rejects the changed live actor/stack inputs on a
second pass. Stop there until that source state is mapped. The slot-$09
conditional dispatch path at `$EB8B` was not selected by this scan. Nonzero
`$0516/$05D2/$052E` branches, active field PPU state, PPU register side
 effects, visible rendering, and physical NMI timing remain unverified.

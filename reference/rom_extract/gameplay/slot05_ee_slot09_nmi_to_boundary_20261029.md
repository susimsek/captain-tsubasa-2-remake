# Live Slot-$09 Queue Delivery to the Next Task Boundary — 2026-10-29

## Result

At the slot-$09 `$CB0F` `WAIT_FOR_NMI_READY` boundary, the pending source queue was present and byte-for-byte unchanged from the scheduler's producer snapshot:

- `$001B=$00` (normal NMI mode), `$0498=$00` (primary queue empty), `$0515=$80` (secondary queue ready).
- `$04A5` starts with two 7-byte records:
  `07 C1 22 9C A8 A8 A8 A8 A8 9D` and
  `07 E1 22 AA 53 41 4F 00 33 AB`.
- The verifier compared the full live queue snapshot with the pending source snapshot before consuming one caller-supplied normal NMI.

The ROM-backed normal-NMI service returned 20 ordered `$2002/$2006/$2007` bus events. It cleared `$0515` from `$80` to `$00`; it did not apply those events to a visible PPU renderer. After the scheduler consumed its ready latch and rescanned, it selected yielded slot `$01` at PC `$CB0F`, record `00 26 00 01`, before dispatch. No task body ran.

## Exact event and scan sequence

The NMI used the caller-provided frame label `5`. That label is a sequencing value only; it is not a measured frame edge or cadence claim.

The ordered bus events followed the live packet bytes:

1. Read `$2002` at `$C96A`, then write `$2006=$22`, `$2006=$C1`; write seven packet bytes to `$2007`: `9C A8 A8 A8 A8 A8 9D`.
2. Read `$2002`, then write `$2006=$22`, `$2006=$E1`; write seven packet bytes to `$2007`: `AA 53 41 4F 00 33 AB`.

Each event's sequence index, source PC, register, operation, and payload was checked against the source queue. No `$2007` writes were applied to a nametable or visible renderer.

The scheduler scan then:

1. Cleared its NMI-ready latch and restarted from slot `$01` (`CLEAR_NMI_AND_RESCAN`).
2. Selected yielded slot `$01`, record `00 26 00 01`, PC `$CB0F` (`YIELDED_RESUME`).

The selected task remained undispatched with no active task body.

## Verification method and source boundary

Focused verifier: `tools/diagnostics/verify_rom_slot05_ee_slot09_nmi_to_boundary.gd`.

Run:

```sh
godot --headless --path . --script res://tools/diagnostics/verify_rom_slot05_ee_slot09_nmi_to_boundary.gd
```

It passed under Godot 4.7.2. It reconstructs the source route through the slot-$09 wait, verifies the live pending-queue snapshot, calls the existing scheduler's ROM-backed normal-NMI service exactly once, and scans to the selected task boundary without dispatching it.

The current higher-level `advance_on_external_nmi()` path may continue from the selected slot-$01 boundary into its bounded caller/worker route. To honor this stop boundary without adding runtime behavior, this focused verifier invokes the already configured scheduler service and scan components directly from the live route state. This is not an instruction-by-instruction PPU model. The normal-NMI source package and queue-transfer behavior are documented in [the existing queue-delivery evidence](slot09_second_nmi_queue_delivery_20261029.md) and hash-bound by `normal_nmi_ppu_queue_transfer/manifest.json`.

## Limits

The verifier models one caller-supplied normal-NMI event with a frame label; it does not establish physical NMI timing or cadence. Returned bus events remain unapplied, so this does not prove visible field pixels. The newly selected slot `$01` body, later queue changes, command-menu presentation, and audio parity remain outside this transition.

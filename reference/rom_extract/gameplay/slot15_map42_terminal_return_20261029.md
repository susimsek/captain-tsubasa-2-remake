# Slot-$15 map-$42 terminal callback return

## Result

After the eleventh queue is consumed, the live route now dispatches the
exhausted slot-$15 task at `$85C1`, follows its ROM return stack through the
callback and dispatcher, and reaches `$CAF7`. The scheduler then clears the
slot-$15 ready/delay bytes. It does not run the later scheduler or scenario
work.

The callback enters its placement tail at `$8334`. With the observed
`$05CD=$00`, `$833C BEQ` takes the `$8342` path: `$05CE` remains zero and the
handler writes `$05CD=$A0`; it also clears `$05DB-$05DD`. The handler RTS
returns to `$819C`, whose dispatcher tail sets bit `$10` in `$0516` and jumps
through fixed-bank `$C512->$CAF7`. From the live route input `$0516=$41`, the
result is `$51`.

## Source provenance

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Worker `$8572-$85C1`: `first_command_field/map_worker_8525/bank_0b_8572_85c2.bin`,
  SHA-256 `098a354cae578918bf54407b972e69b520327d030eb391ed3c2d476c4d337502`.
- Callback `$8327-$8360`:
  `first_command_field/packet_producer/bank_0b_8327_8360_map_placement_writer.bin`,
  SHA-256 `e3ed67bcd4a760f0f8324b4d46ca08100ef6d1b578af495da8475b7e66096853`.
- Dispatcher `$814C-$81A7`:
  `first_command_field/callback_dispatch/bank_0b_dispatcher_814c_81a6.bin`,
  SHA-256 `c648a228e5e90247ce604220a2aff2bb4b1c58af30546e71b543fec874b28df6`.
- Fixed finish trampoline `$C512-$C514`:
  `task_context/fixed_task_finish_trampoline_C512.bin`, SHA-256
  `bc85dc6c05fac84b9063f3cb28a3acbe16e2591ab2dff53b935530aa2a35940f`.
- Normal NMI return `$C810-$C820` restores PPUCTRL shadow `$20` and copies it
  to `$19`. The yielded-task dispatcher `$CAB9-$CAD3` rotates `$19` before
  restoring the task stack. Both bounded effects are now represented in the
  scheduler state used by the route.

## Validation

The focused route verifier is
`tools/diagnostics/verify_rom_slot05_live_ed01_row_bbe3.gd`. It passes the
eleven map batches against FCEUX queue snapshots 8–18, checks their ordered
`$2007` counts, and verifies the terminal `$CAF7` register/RAM result against
the frame-8479 `task_finish_CAF7` trace event: A/X/Y/P = `$51/$40/$10/$20`,
with `$05CD/$05CE=$A0/$00`. The ROM-derived route finishes slot `$15` by
clearing its first two record bytes.

The focused NMI verifier is
`tools/diagnostics/verify_rom_gameplay_scheduler_nmi_queue_service.gd`. It
checks the normal NMI return shadow state as well as ready, empty, and not-ready
queue branches.

## Limits and next transition

This is bounded source execution, not a general 6502 emulator. Caller-supplied
NMI edges remain frame-level abstractions; instruction/cycle timing, physical
PPU timing, temporary stack-write timing, field rendering, actors, route audio,
and command-menu output remain unresolved. After `$CAF7`, resume from the
source-cleared slot and trace the next task or callback that actually produces
the live field/menu state; do not infer another map cell.

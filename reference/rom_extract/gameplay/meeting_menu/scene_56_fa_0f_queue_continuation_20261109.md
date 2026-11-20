# Scene $56 FA $0F background queue continuation

## Scope and source identity

This note documents the ROM-derived capacity-wait model for scene $56's
`FA $0F` background event. It covers packet staging and the continuation after
the shared PPU queue is drained. It does not claim to model `$8AF7`'s complete
loader, the full NMI, CPU-cycle timing, or the entire scene transition.

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`.
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Scene event stream: `scene_56_execution.bin`, bank 5 `$BFBA`, file
  `0x00BFCA`; `FA 0F` is at CPU `$BFBC`, file `0x00BFCC`.
- Event manifest: `assets/gameplay/rom_logic/kickoff_meeting_scene_56_events.json`,
  event index 1, opcode `$FA`, operand `$0F`.
- Background record: bank 7 CPU `$A294`, file `0x00E2A4`; its preserved bytes
  are `64 66 9A 02 04 12 57 58 59 52 5A 5B 5C 56 00 A0`.
- Record manifest and block data:
  `reference/rom_extract/gameplay/backgrounds/background_0F_layout.json` and
  the ROM byte files it names.

## ROM rule implemented

The cutscene F9/FA handler shares the background loader at bank 0 `$8AF7`.
The target scene selects the bank-7 `$0F` record above; the record defines two
rows by four metatiles, giving eight 4x4 blocks. The packet builder decodes
these ROM records into ordered attribute and tile-row packets. It creates 40
PPU packets with 256 total encoded queue bytes.

The shared queue writer at bank 0 `$9B28` checks whether the current queue
cursor plus the requested payload size reaches `$3D`. On the full branch,
`$9B2E` loads one and `$9B30` calls `$9FA8`; the request is retried after the
queue release. The queued record itself consumes payload bytes plus its
three-byte address/length header. A saved JSR return word of `$9B32` resumes
at `$9B33`; the caller's saved word `$8F46` resumes at `$8F47`. These saved
return words are not the resume PCs.

The task derives packet segments from that rule and the live queue cursor
provided by the ROM-derived presenter. It does not read captured RAM to seed
the cursor. For an empty starting cursor, the focused verifier derives five
segments: four capacity waits containing 9 packets each (57 encoded bytes per
segment), followed by a final 4-packet segment (28 bytes). The last segment
does not yield; after it is staged, the source task returns.

The task advances only after an NMI queue-release receipt. A source-owned FA
segment receipt must identify the same event, background, segment, serialized
byte count, ordered PPU writes, queue cursor reset, and the checked
`$9B28->$9FA8` continuation. It requires the observed queued PPU writer
`$A03C`. An anonymous inherited-queue flush is accepted only when the pending
segment contains no FA packets; after that release, task-owned packet receipts
are required. `advance_source_tick()` explicitly refuses to advance FA `$0F`.

## Validation evidence and limits

The existing [`f9_task_timing_trace.md`](../../intro/f9_task_timing_trace.md)
records the shared `$9B28` capacity comparison, `$9B2E/$9B30` yield, nested
return words, and the queue cursor behavior. Its frame-9 `$0628=$39`,
`$0629=$04` sample validates that shared capacity branch for the traced F9
case; it is not FA `$0F` runtime input. The buffered cutscene writer `$A03C`
is documented in [`f1_01_graphics_gate_trace.md`](../../intro/f1_01_graphics_gate_trace.md)
and the title queue source trace. Those are behavioral references, not runtime
assets or seeded state.

Focused check:

```sh
godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_rom_cutscene_fa0f_queue_task.gd
```

Result: PASS on Godot 4.7.2. The verifier builds packets from the preserved
ROM-derived record and block bytes, checks queue segmentation and expected
PPU writes, rejects source-frame-only advancement, validates owned and
inherited drain receipts, and exercises receipt mismatch rejection. Its
monotonic frame labels are synthetic ordering fixtures; they do not assert
route frame timing or physical NES timing.

Still unproven: this verifier does not run FCEUX or replay the full route. The
exact `$8AF7` setup/release phase for this particular `$0F` event, subframe
timing of `$9FA8` versus the NMI edge, and exact route-level same-input timing
remain outside this check. The route/presenter must supply its actual live
queue cursor and stage each returned segment through the production PPU
consumer before this task can be considered integrated behavior.

# Fresh-route root tasks and NMI ready latch

ROM revision: SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

This diagnostic isolates the fresh-game scheduler bootstrap needed by the KICK OFF route. It preserves source bytes and derives the three root task records and their 6502 RTS continuations, then checks those results against the retained muted FCEUX trace. The trace is validation evidence only; it does not initialize the model. Nothing here is connected to the production route or predicts physical NMI timing.

## Source spans

The byte-exact spans and SHA-256 hashes are listed in `reference/rom_extract/gameplay/task_context/manifest.json`:

- Fixed RAM zero fill, `$C650–$C679` (file offset `0x03C660`), establishes the cold RAM precondition.
- Task-slot clear, `$C6BE–$C6E7` (`0x03C6CE`), clears ready and saved-SP fields for slots `$01/$05/$09/$0D/$11/$15`.
- Fresh-game bootstrap, `$C6E8–$C765` (`0x03C6F8`), clears `$001B`, initializes `$0020` to `$08`, seeds three root records, enables PPU NMI in the `$0020` shadow, and enters the scheduler at `$CA97`.
- NMI vector words, `$FFFA–$FFFF` (`0x04000A`), point to `$C500`; the three-byte `$C500` trampoline (`0x03C510`) jumps to `$C76E`.
- NMI gate and normal ready writer, `$C76E–$C7EF` (`0x03C77E`); normal return/re-enable path, `$C810–$C820` (`0x03C820`); special dispatch, `$C421–$C43C` (`0x03C431`); bank-$02 ready writer, `$A000–$A137` (`0x004010`).
- Shared `$CAE7` task-seed helper, also listed in the task-context manifest.

The three literal bootstrap seeds call `$CAE7` with these values:

| Slot | Record bytes | Saved SP | Stack continuation |
| --- | --- | --- | --- |
| `$01` | `FF 28 00 00` | `$28` | `$CA21` |
| `$05` | `FF 50 00 00` | `$50` | `$D11D` |
| `$09` | `FF 78 00 00` | `$78` | `$EB85` |

Each continuation is represented by its low/high bytes at stack-page indices `SP+1` and `SP+2`; the model keeps stack wrapping explicit. The `+3` bank-high bytes are not explicitly rewritten by these root seeds, so their modeled zero comes from the preserved cold-RAM-zero-fill precondition. The independent frame-8460 trace confirms the resulting record bytes and stack contents for this route.

## NMI ready-bit gate

`$C76E` tests `$001B` with `BIT`: bit 6 selects a special path through `$C421`, which maps bank `$02` at `$A000`; that path sets bit 7 at `$A12F` (write completes at PC `$A135`). With bit 6 clear, the fixed-bank path sets bit 7 at `$C7EA` (write completes at `$C7F0`). The normal handler clears `$2000.7` at `$C77E`, clears PPU vblank by reading `$2002` at `$C79C`, sets `$001B.7`, then restores `$2000.7` in its return path before `$C820 RTI`. The scheduler consumes the ready latch by clearing bit 7 at `$CAB4` (write completes at `$CAB6`). The PPU-control shadow is initialized to `$08`, then bit 7 is enabled, yielding `$88` before entering `$CA97`.

The retained two-pass trace under `reference/diagnostics/first_command_task_boundary_20261028_070655_utc/` independently confirms the route observations. In the mode-6 interval, frames 8400–8458 each show the special `$001B: $40→$C0` write at `$A135` and the separate `$C0→$40` mode restore at `$9F0C`. Frame 8459 has no `$001B` writer; frame 8460 clears `$40→$00` during fresh-game setup. In the normal field interval, every frame 8461–8953 has one `$C7F0` ready set, one `$CAB6` scheduler consume, and the source `$2000.7` clear/re-enable shadow writes at `$C783/$C816`. This supports a **state-gated frame-level edge contract for these observed intervals**, not an unconditional per-frame timer across the route. The `$C7F0` store varies from 1,217 to 2,677 CPU cycles from the trace's frame-advance origin; the set-to-consume gap varies from 94 to 317 cycles. Both normalized passes match and retain the verified frame-8399 checkpoint metadata.

The retained PPUCTRL-shadow writes narrow, but do not resolve, the frame-8459 gap. In both passes, `task_writes.csv` row/sequence 2674 records frame 8459 cycle 15563 (`$98D9`) changing `$0020` `$08→$88`; row 2715 records cycle 20739 (`$A2C1`) changing `$88→$08`. Neither pass has an `$001B` ready-writer row in frame 8459. The surrounding normal interval has the `$C7F0` ready write at frame 8461 cycle 1819 (row 2936) and `$CAB6` consume at cycle 1913 (row 2939), identically in the repeat file. This is consistent with NMI enable being toggled relative to a PPU vblank/NMI opportunity, but does not prove that explanation: these task logs timestamp CPU writes only and contain no PPU scanline/dot, vblank assertion, or NMI-pending edge field. In particular, the `$08→$88` shadow write cannot establish whether vblank was already active. An isolated source-clocked RP2C02 vblank/NMI component now exists, but no live route event runner supplies it with exact `$2000/$2001/$2002` access dots and CPU cycles; it is not called by `RomGameplayTaskScheduler` or `KickoffRouteRuntime`. The retained PPU/MMC3 trace also has no usable beam coordinates: all 92,992 `ppu_scanline`/`ppu_dot` bus-event values and all 554 frame-edge end-coordinate pairs are `-1`. Keep scheduler NMI delivery external, and do not infer cadence from observed frame numbers. See [`first_command_ntsc_ppu_vblank_nmi_clock_20261028.md`](first_command_ntsc_ppu_vblank_nmi_clock_20261028.md).

## Model boundary

`tools/diagnostics/rom_gameplay_root_task_bootstrap_model.gd` derives only these bounded source transitions. Its `resolve_source_nmi_service()` maps an externally supplied PPU NMI delivery plus `$2000.7` and `$001B.6` to the source ready writer; it does not generate NMI events or cycle timestamps. `tools/diagnostics/verify_rom_gameplay_root_task_bootstrap.gd` hash-checks the supplied ROM and preserved spans, derives model state without trace inputs, then compares the task state and complete NMI frame projections with both retained passes. The verifier passes with Godot 4.7.2.

The isolated PPU clock models vblank/NMI output edges, but not the CPU's NMI entry/service phase, the complete scheduler, worker/task bodies, or production runtime integration. The FCEUX trace timestamps ready-latch writes, not PPU NMI assertion. A frame-level NMI opportunity may be used only when the runtime's own PPU/NMI-enable state supplies it; do not synthesize a fixed-cycle edge or fill the frame-8459 gap with a timer. The trace confirms the observed intervals, not universal cadence or physical NES timing.

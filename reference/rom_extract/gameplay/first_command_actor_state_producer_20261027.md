# First-command actor state producer: ROM path and unresolved entry state

## Scope and source identity

This note follows actor state from the same-input fresh KICK OFF route into the
first in-match command panel. The supplied ROM SHA-256 is
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`. The
muted FCEUX replay and its inputs are diagnostics only; no captured pixels,
OAM, or audio are runtime assets.

The retained trace is
`reference/diagnostics/first_command_actor_oam_20261027_113609_utc/`. Its
`actor_draw_calls.csv` contains 1,414 per-actor snapshots from 473 source frames
(8481–8953), sampled immediately around the renderer call. It records each
actor's 21 bytes, script pointers, both timers, descriptor, `$0546` selector,
CHR selectors, mapper state, OAM allocation, and OAM changes. The replay used
the checked opening and post-title input timelines, started from power-on,
muted FCEUX audio, and stopped at the first command panel.

## Byte-checked update and draw chain

1. Fixed-bank `$EE9F` (ROM file `0x03EEAF`) reads the six order nibbles in
   `$0543–$0545`; fixed-bank pointer table `$EF73` (file `0x03EF83`) maps the
   ordered actors to records `$0547,$055C,$0571,$0586,$059B,$05B0`. A negative
   flag byte marks a record for actor processing/drawing.
2. For each active record, the loop switches to bank `$14` and calls its
   `$8006` entry, which dispatches to `$83D9` (file `0x0283E9`), then its `$8003`
   entry, which dispatches to `$84DC` (file `0x0284EC`). `$83D9` advances the
   timed appearance/descriptor stream. `$84DC` advances the secondary motion
   stream and its fixed-point motion state. These calls occur before drawing.
3. The loop switches to bank `$16` and calls `$8000` (file `0x02C010`). This
   reads the record's descriptor at `+$12`, applies actor origin, flip, shared
   selector, scroll and clip state, then interprets ROM run/jump/selector
   records into the `$0200–$02FF` OAM shadow. NMI copies that shadow to hardware
   OAM.

This confirms the producer chain is ROM scripts plus mutable actor records;
the captured OAM shadow is only a validation result.

## Actor state fields used by the source pipeline

| Input | Source use |
| --- | --- |
| Actor `+$00` | Active/sign and high-coordinate bits; actor flip inputs. |
| Actor `+$01/+02` | Pointer consumed by the bank-$14 secondary motion updater at `$84DC`. |
| Actor `+$03/+04` | Pointer consumed by the bank-$14 timed appearance/descriptor updater at `$83D9`. |
| Actor `+$05–+$0C` | Two fixed-point motion/position lanes updated by `$84DC`; the sprite renderer uses `+$08` for X and `+$0C` for Y, with sign/high bits from `+$00`. |
| Actor `+$10` | Appearance-script timer. `$FF` holds the current descriptor; a positive value counts down on actor updates. |
| Actor `+$11` | Secondary motion-script timer. `$FF` returns without advancing that stream; otherwise it counts down and dispatches the stream when due. |
| Actor `+$12` | ROM sprite-layout descriptor index. |
| Actor `+$13/+14` | Signed actor-local X/Y adjustments written by the appearance script's `$F6` control and consumed by the bank-$16 renderer. |
| `$0543–$0545` | Six ordered actor indexes used by `$EE9F`. |
| `$0546` | Shared sprite-variant selector. The route trace records its actual value at each draw. Player graphics lookup uses bank-$14 `$826A` and table `$88F0`; appearance control `$F8` also writes it at `$84D2`. |
| `$0493–$0497` | Sprite CHR selector bytes installed by the ROM and observed at each draw. |
| `$0517`, `$0538`, `$0540/$0541` | Shared mirror, horizontal scroll, and sprite Y clip state consumed by `$8000`. |

The coordinate-lane description above is limited to the fields demonstrated by
the `$84DC` integrator and `$8000` renderer. It does not infer player identity
from unrelated record bytes.

## Script timing and source commands

At `$83D9`, a nonzero `+$10` timer is decremented once per actor update; `$FF`
returns and holds the current pose. When it reaches zero, the updater resets
the local offsets, reads the stream pointer at `+$03/+04`, and consumes control
bytes until it schedules a timed pair or exits. A normal pair is
`duration, descriptor`; it writes `+$10` and `+$12`, then advances the stored
pointer. The target-ROM control dispatch at `$8438–$84D8` includes:

- `$F0`: end/hold by setting the timer to `$FF`;
- `$F1/$F2`: set horizontal/vertical flip flag bits;
- `$F3`: replace the stream pointer with its little-endian target;
- `$F4/$F5`: select and advance a secondary scripted segment;
- `$F6`: write two signed local offsets to `+$13/+14`;
- `$F7`: write a descriptor directly and hold it;
- `$F8`: set shared selector `$0546`.

At `$84DC`, `+$11` controls the secondary motion stream. The routine reads its
stream pointer from `+$01/+02` when due and advances the fixed-point motion
lanes before `$8000` consumes their screen-space bytes. Exact route entry
selection for these streams is not inferred from their later pointer values.

## Route states and decoded ROM stream evidence

The route trace now supplies per-draw state history, correcting the older
endpoint-only wording in `first_command_actor_pose_path_20261027.md`:

- At frame 8481, visible actor records use main streams `$B30E/$B310/$B312`
  and motion pointers `$A390/$A729/$A732`; their positions and descriptors then
  change over successive source frames.
- The shared `$0546` selector is written as `$02` at frame 8657. At frame
  8663 actor `$0547` is observed with main pointer `$B539`, motion pointer
  `$A974`, timer `$04`, and descriptor `$7D`. By frame 8708 it has transitioned
  to main pointer `$B440`, motion pointer `$A7A1`; at frame 8759 it is at
  `$B020/$A6D4`, while the shared selector is `$08`.
- At frames 8822–8906, the field lineup uses main pointers `$B028`, `$B042`,
  and `$B09F`. The target-ROM bytes at bank `$14` CPU `$B026` are
  `04 00 04 01 04 02 04 03 F3 26 B0`. Interpreted by `$83D9`, the first actor
  holds descriptors `00,01,02,03` for five actor updates each, then jumps back
  to `$B026`. The trace shows those descriptor changes at frames 8822, 8827,
  8832, 8837, and 8842, and the loop continues across the B press at frame
  8893. This is source-stream timing, not a hand-authored Godot animation rate.
- At frame 8907, the active records switch to main pointers `$B5AC`, `$B5AE`,
  and `$B5B2`; each stream begins with a direct `$F7` descriptor command.
  Target-ROM bytes at `$B5AC` begin `F7 00 F7 04 F7 06 F7 0A`; the live actors
  settle to descriptors `$00`, `$04`, and `$0A` with `+$10=$FF`. At frame 8953,
  those records occupy OAM slots 0–5, 6–18, and 19–40. Their motion timers are
  also `$FF`; the records' `+$01/+02` pointer is `$A390`, X/Y origin inputs are
  zero, and the shared draw selector is `$08`.

Bank `$14` is the 16-KiB source window with CPU `$8000` at ROM file `0x028010`.
Thus the observed script roots are ROM bytes, not labels inferred from a
screenshot: `$B026` is file `0x02B036`, `$B028` is `0x02B038`, `$B042` is
`0x02B052`, `$B09F` is `0x02B0AF`, and `$B5AC` is `0x02B5BC`. These offsets
are useful candidates for project-owned source spans if the complete route
state producer is later wired into runtime.

## What this closes and what remains unresolved

Closed for this route trace:

- actor update and draw call chain;
- the live per-draw actor records and `$0546` values from frame 8481 through
  the first panel endpoint;
- the descriptor and motion pointer values observed at each draw;
- the ROM command loop that produces the four-pose first actor cycle before
  the panel transition;
- the final three descriptor streams and their frozen timer state.

Still unresolved for a route-time Godot producer:

1. A repeated FCEUX writer trace records 7,523 actor-record and 139 field-
   state writes, with their PC, PRG bank, frame, cycle, and actor-record offset.
   Source bytes map the `$F1` constructor and the `$83D9/$84DC` writers. Observed
   root changes include `$B30E`, `$AF5F`, `$B539`, `$B440`, `$B020`, the lineup
   streams, and final `$B5AC/$B5AE/$B5B2`. A separate ROM-byte crosswalk now
   links these groups to scenarios `$35/$36/$1E/$44` and animation IDs
   `$8F/$4E/$66/$4C/$E6→$78/$90/$5C`; see
   [`first_command_actor_scenario_event_source_audit_20261027.md`](first_command_actor_scenario_event_source_audit_20261027.md).
   Event selection is source-mapped. The muted follow-up trace now measures
   the scheduler/NMI ready-latch handshake, `$0519` countdown, and one
   `$800F` animation-handler call per source actor-loop frame; the relative
   animation decoder consumes ROM event tokens and low-byte waits. These
   source events are not yet connected to the Godot route scheduler or actor
   state presenter.
2. The selected motion streams such as `$A390/$A729/$A974/$A7A1/$A6D4` are
   visible and some handler writes are mapped, but their complete route-time
   command walk and all selection conditions have not been converted into
   Godot state. The appearance-stream roots and selected event IDs are
   ROM-mapped; the trace measures cadence but the route still lacks the
   cooperative source task graph, full route-selected script spans, and live
   motion/appearance execution in Godot.
3. Player-record population, player identity selection, and other gameplay
   state writers remain distinct from actor-animation construction. Mirror
   `$0517` is source-generated earlier by scenario `$36` `$FD 00` from the
   selected player context, then copied from scenario `$052A` at fixed-bank
   `$ED0C`; the later scenario flag can reset while `$0517` remains set. Godot
   still does not execute that producer or preserve its state through the
   route. Scroll `$0538` and clip bounds `$0540/$0541` are independent renderer
   inputs: `$800F` initializes the clip bounds, while the endpoint trace only
   validates scroll `$00` and the carried mirror bit. Their route-time updates
   are not yet part of the actor presenter. A frozen endpoint pose cannot stand
   in for these source writers.

See the ROM-byte crosswalk and route-root table in
[`first_command_actor_writer_trace_source_map_20261027.md`](first_command_actor_writer_trace_source_map_20261027.md).

## Actor-writer trace tooling and attempt status

The replay tools are prepared:

- [`trace_first_command_actor_writers.lua`](../../../tools/diagnostics/trace_first_command_actor_writers.lua)
  replays the checked opening and post-title input timelines with audio muted.
  It attaches actor-memory hooks for `$0547–$05C4`, field-state hooks for
  `$053A–$053D`, and execute hooks at `$83D9/$84DC/$EE9F` only during source
  frames 8400–8953. It records byte transitions, CPU PC, cycle, mapped PRG
  bank, actor record index, and the relevant actor state at each routine call.
  Two minimal `$8000/$8001` mapper hooks remain active from reset solely to
  maintain correct PRG-bank labels for that later window.
- [`run_first_command_actor_writer_trace.py`](../../../tools/diagnostics/run_first_command_actor_writer_trace.py)
  checks the supplied ROM and both input-timeline hashes before launching
  muted FCEUX. It launched the successful checkpointed replay documented
  below.
- [`validate_first_command_actor_writer_trace.py`](../../../tools/diagnostics/validate_first_command_actor_writer_trace.py)
  contains the capture checks and replays every logged memory write from the
  captured start snapshot, requiring exact equality with the captured end
  snapshot. It accepts FCEUX `-11` only if the final `2:8953` marker and two
  checkpoint-verified, byte-identical passes are present, and reports the
  shutdown crash separately. The successful trace passes these content checks;
  see `actor_writer_trace_validation.json`. Captures remain diagnostic only.

The first launch attempt on 2026-10-27 did not produce trace data. Its output
directory is
`reference/diagnostics/first_command_actor_writer_trace_20261027_151623_utc/`.
FCEUX reported successful power-on and an available cycle counter, but no
`progress.txt` appeared; both trace CSVs stayed empty and the actor start/end
snapshots were never written. The FCEUX process remained near 100% CPU for
1:54 before it was terminated; the runner recorded exit code `-9` after
147.555 seconds. The output is incomplete and was not passed to the validator.
This does not establish that FCEUX Lua replay is unavailable in this
environment: the earlier actor/OAM trace completed with the same installed
FCEUX 2.7.0. The cause of this new replay stalling before source frame 0 is
unresolved. A static comparison found the same launch flags, cold power-on,
turbo mode, input parser, `joypad.set`/`emu.frameadvance` loop, and starting
route as the successful actor/OAM runner. The writer trace adds a per-frame
`debugger.getcyclescount()` sample and queries `movie.mode()` during startup;
both APIs are used by other project traces, so neither is an established hang
cause. Its many actor-address hooks are attached only at source frame 8400 and
therefore cannot explain a stall before the first progress write at frame 0.
The successful retry uses FCEUX's anonymous in-memory save-state API at frame
8399, then verifies the checkpoint and replays frames 8400–8953 twice. Both
passes produce 7,662 identical memory-write rows and 3,371 identical routine
call rows; the start/end actor snapshots also match byte-for-byte. The
checkpoint covers 2 KiB RAM, 16 KiB PPU memory, mapper signature, frame, and
CPU-cycle count. The replay and full ROM writer crosswalk are documented in
`reference/diagnostics/first_command_actor_writer_trace_20261027_170114_utc/`
and `first_command_actor_writer_trace_source_map_20261027.md`. FCEUX exited
`-11` after completion metadata was written; this remains a shutdown caveat.

Use the trace to identify and decode source writers, never as a runtime event
table. Until the route dispatcher/event conditions and actor updates are
reproduced from ROM data, keep `GameplayRomActorOamBuilder` as a separately
verified OAM builder; do not embed captured actor records or wire a fixed pose
into the field scene.

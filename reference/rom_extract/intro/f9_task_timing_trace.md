# F9 background loader: task waits before FB

## Scope and source identity

This report follows cutscene 00's `F9 00` command and the next `FB 01` using
the supplied Turkish ROM and existing same-input captures. No emulator UI was
controlled for this analysis.

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- CPU code in `$8000–$9FFF` is bank 0; file offset is `$10 + (CPU-$8000)`.
- Cutscene bank 3 maps at `$A000` from file offset `$6010`.
- Background bank 7 maps at `$A000` from file offset `$E010`.
- Frame/PC evidence: `reference/diagnostics/opening_dispatch_full_20261024_150016/`
  and `reference/diagnostics/audio_scheduler_trace_20261024_135139/`.
- RAM evidence: `reference/opening_timing_capture_20261024_125300/ram_states/`.
  These are end-of-source-frame snapshots; they do not timestamp individual
  CPU instructions or scheduler/NMI edges.

## Script and F9 handler

The script at CPU `$A020` (bank-3 file `$6030`) begins:

```text
E8 01 F9 00 FB 01 8D E9 ...
      ^^^^^
      $A022
```

F9 operand `00` selects background ID 0. Bank 7's background pointer table at
file `$E010` begins with `D4 A0`, resolving to record `$A0D4` (file `$E0E4`).

The ROM bytes at bank-0 file `$824` / CPU `$8814` are:

```text
A5 5B 29 FB 4C 1F 88 A5 5B 09 04 85 5B C8 B1 4D 20 F7 8A A6 56 20 B9
```

The F9 branch clears bit `$04` in `$5B`, then the shared F9/FA path reads its
operand and calls `$8AF7`. At `$8AF7` (file `$B07`) the background loader reads
record `$A0D4`. Its exact 11 bytes at file `$E0E4` are:

```text
7C 7E 81 01 03 1B 22 23 24 00 A0
```

For this record, the loader's `$5E < 9` path reaches `$8BAE`. The local bytes
starting at `$8BAE` (file `$BBE`) are `A9 01 20 A8 9F`: `LDA #$01; JSR $9FA8`.
The `JSR` itself is at `$8BB0`, so its stacked return address is `$8BB2`.
This is an explicit one-count cooperative yield in the F9 loader.

## A second yield on the PPU-buffer path

After resuming, the loader reaches the record's block IDs `22 23 24` and calls
the block decoder. At `$8F42` it sets `A=$04`; `$8F44` (file `$F54`) calls
`$9B28` to reserve four PPU-buffer bytes. `$9B28` (file `$1B38`) begins:

```text
48 2C 29 06 50 09 A9 01 20 A8 9F 68 4C 28 9B
29 3F 18 6D 28 06 C9 3D B0 ED ...
```

If the buffer index plus requested size is at least `$3D`, the `BCS` branch
reaches `$9B2E`, executes `LDA #$01; JSR $9FA8`, restores the request, and
retries `$9B28`. Thus a full buffer causes another one-count scheduler yield.
In the frame-9 RAM snapshot, `$0628=$39` and `$0629=$04`: the four-byte request
would make `$0628 + 4 = $3D`, taking that capacity-wait branch. `$0629` bit 6
is clear, so the earlier `$0629.V` retry path is not the reason for this
observed yield.

## Live timing and saved-task evidence

The existing dispatch trace reports:

| Source frame | Observed event |
|---:|---|
| 8 | F9 at script `$A022`, handler `$8814`; pointer remains `$A022` |
| 9 | No script dispatch; pointer remains `$A022` |
| 10 | F9 common advance `$8879`; next pointer `$A024`; then FB at `$A024` / `$8831` |

The task-context snapshots independently place the worker in each wait path:

| Frame | Script pointer | Task slot `$0005–$0008` | Buffer `$0628/$0629` | Relevant saved return bytes |
|---:|---|---|---|---|
| 8 | `$A022` | `01 42 00 07` | `23 20` | RAM `$014D–$014E = B2 8B` (`$8BB2`, return from first `$9FA8` call); `$014F–$0150 = 26 88` (`$8826`, return from F9's `$8AF7` call) |
| 9 | `$A022` | `01 3B 00 08` | `39 04` | RAM `$0146–$0147 = 32 9B` (`$9B32`, return from capacity wait); `$0149–$014A = 46 8F` (`$8F46`, return to four-byte reservation); `$014F–$0150 = 26 88` (outer F9 call) |
| 10 | `$A027` after FB/E9 | `02 44 00 03` | `27 04` | F9 has returned; the `$02` task delay belongs to the following E9 path, not F9 |

Task-context fields are reported as raw scheduler bytes; the stack return
addresses above are the key PCs. The frame-8 return at `$8BB2` places
the worker in its first loader wait. The frame-9 nested return addresses
`$9B32` and `$8F46`, together with `$0628/$0629=$39/$04`, place it in the
second wait while trying to reserve the four-byte block. At frame 10 the
worker has returned through F9 and the interpreter has advanced to FB.

The scheduler code at `$9EED` (file `$1EFD`) decrements nonzero task delays
and resumes due task contexts; `$9FA8` (file `$1FB8`) saves the current task
context and yields. Its one-count use is therefore a scheduler wait, not a
fixed number of direct script dispatches. The per-frame trace counts three
`$9FA8` entries in frame 8, three in frame 9, and four in frame 10 across all
tasks; those totals alone do not identify a task's release edge.

## Conclusion and remaining timing limit

The frame-8 F9 to frame-10 FB gap is no longer only an empirically calibrated
delay. Local ROM bytes show **two distinct one-count yields inside F9's
background work**: the loader's initial yield and the PPU-buffer-capacity
retry. The frame-8 and frame-9 saved stacks identify those exact suspended
call sites, while the dispatch trace shows F9 completing in frame 10. This
source and live-context evidence explains the two-release behavior.

The exact subframe phase remains open: available hooks do not timestamp the
entry/return of each `$9FA8`, each scheduler delay decrement, and the matching
NMI-ready edge on a cycle clock. Therefore retain frame 8/9/10 as observed
anchors, and model the two one-tick yields in the F9 path rather than adding an
unexplained fixed two-frame delay.

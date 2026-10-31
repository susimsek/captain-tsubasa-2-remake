# FCEUX Trace: C515 Worker to Scenario 35 Enqueue

## Scope

This diagnostic follows the selected kickoff route from the first `$EF7F` wrapper call through the second wrapper return and the call to `$CBB0` that enqueues scenario `$35`. It does not trace the rest of the first-match command menu. No title choice was confirmed and no soccer action or Continue flow was selected.

## Run contract and provenance

- ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`, SHA-256 `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Inputs: `reference/opening_reference_capture/input_timeline.csv` followed by `reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv`; both input-file hashes are recorded in the run metadata.
- Emulator: FCEUX 2.7.0, NTSC, NewPPU; audio muted with `--sound 0 --volume 0` and `SDL_AUDIODRIVER=dummy`.
- The prior frame-8399 state was session-local and unavailable; no FCEUX process or persistent state file existed at the start. The runner rebuilt the route from power-on, retained an in-memory frame-8399 state, and loaded that same state for both replays. It checked frame/cycle, 2 KiB RAM, 16 KiB PPU memory, MMC3 registers, and mapped PRG bytes after both loads.
- A first attempt timed out before advancing the warmup frame and produced no usable checkpoint; it is not part of the results. Its output is under `reference/diagnostics/first_command_daaa_transition_20261029_051621_utc/`.
- Command: `python3 tools/diagnostics/run_fresh_daaa_transition_trace.py`.
- Lua hooks and captured data are in `tools/diagnostics/trace_fresh_daaa_transition_from_8399.lua` and `reference/diagnostics/first_command_daaa_transition_20261029_051902_utc/`.

The FCEUX metadata API returned an empty ROM hash field. The saved metadata labels that field as unavailable; the runner independently hashed the ROM file and recorded its verified value as `source_rom_sha256`.

## Repeatability

Both replays cover frames 8400–8472 from the same frame-8399 checkpoint. Each has 193 selected CPU events and 4,008 watched writes. The normalized event hash is `d400883d9ded02f823841dd0bcb535b030b2dbbf2602a077c1843270b711a3af`; the normalized write hash is `2c89581743225b5756f68067006f502579ca1eea26841984c3b86effd90275c2`. Both hashes match between passes. The full raw CSV files include pass identifiers and therefore have different file hashes.

## Observed route and scheduler order

Cycle values below are offsets from the start of the stated frame. Hooks fire at the listed CPU address before its instruction. The sequence is identical in both passes.

| Frame / cycle | CPU event | State observed |
| --- | --- | --- |
| 8460 / 27377 | `$DAC9` first wrapper call | Current task base `$05`, record `FF 50 00 00`, SP `$50`. |
| 8460 / 27379 | `$EF7F` wrapper entry | SP `$4E`; mapper shadow `$1C/$1D`. |
| 8460 / 27543–27555 | `$8884` → `$8886` → `$C515` → `$CB0F` | Bank `$18` worker runs with mapper shadow `$18/$19`; SP falls `$4A` → `$48`. The scheduler then resumes task base `$09` at frame 8460 / cycle 27721, SP `$78`. |
| 8461 / 3950 | `$8889` flag poll | `$0515=$00`; task base `$05`, record `00 46 18 19`, SP `$4A`. |
| 8461 / 3958, 5089 | Writes to `$0515` | `$00→$01`, then `$01→$80`; the worker later yields through `$8884/$8886/$C515/$CB0F`. |
| 8462–8467 | Repeated poll / yield | `$8889` sees `$0515=$00` once in each frame. A write changes it `$00→$01`; another changes `$01→$80`. At the next frame start, the clear described below returns it to zero. |
| 8463 / 4373–4381 | `$DACC` return → `$DACE` second call → `$EF7F` | Caller SP is `$50`; wrapper entry SP `$4E`; worker/yield path follows at `$8884/$8886/$C515/$CB0F`. Scheduler again resumes task base `$09` after the yield. |
| 8467 / 4717 | `$DAD1` second wrapper return | Caller task base `$05`, record `00 46 18 19`, SP `$50`. |
| 8467 / 4723–4733 | `$DAD8` → `$DADA` → `$CBB0` | `$DAD8` loads `$35`; `$DADA` calls `$CBB0` with A=`$35`. SP changes `$50→$4E` at the call. `$CBB0` is the observed enqueue entry. |
| 8467 / 4755 onward | First enqueue yield and scheduler continuation | `$CB0F` yields with task base `$05`, SP `$4C`; scheduler next resumes task base `$09` at cycle 5926, then a task at base `$15` reaches `$C515` at cycle 6501. This is the last post-enqueue activity recorded here. |

The captured task-record and stack-page snapshots are in `task_events.csv`; this summary reports the observed task bases, record bytes, and stack-pointer sequence without assigning additional scheduler semantics.

## `$0515` source sites

The write hook reports the PC after the store. Matching those PCs to the supplied ROM bytes identifies these instructions:

- Bank `$18`, file offset `0x0308A0`, CPU `$8890`: `8D 15 05` — `STA $0515`, writing `$01`. The callback reports post-write PC `$8893`.
- Bank `$18`, file offset `0x030988`, CPU `$8978`: `8D 15 05` — `STA $0515`, writing `$80`. The callback reports post-write PC `$897B`.
- Fixed bank `$1E`, file offset `0x03C968`, CPU `$C958`: `8E 15 05` — `STX $0515`; the preceding code loads X with zero. The callback reports post-write PC `$C95B`, clearing `$80→$00` near the start of frames 8462–8467 (cycle 615 or 618).

Thus the frame pattern is dynamic ROM execution: poll at `$8889`, store `$01`, store `$80`, then fixed-bank `STX $0515` clears the flag at the next frame's early scheduler phase. It is not a guessed frame-delay constant.

## ROM mapping for the enqueue boundary

`reference/rom_extract/gameplay/scenario_task_runtime/manifest.json` records CPU `$DAD8` at file offset `0x03DAE8`, bytes `A9 35 20 B0 CB`. The trace confirms the live sequence `$DAD8` (`LDA #$35`) → `$DADA` (`JSR $CBB0`) → `$CBB0` with A=`$35`. `$DAD9` is the immediate operand byte, not an instruction entry.

## Exact limits

The capture ends at frame 8472, five frames after the `$CBB0` entry at frame 8467 / cycle 4733. It establishes the repeatable caller, wrapper, worker-poll, `$0515` write/clear, scheduler-yield, and scenario-enqueue sequence under the recorded emulator configuration and inputs. It does not establish hardware NES cycle timing, prove pixel/audio equality, or show arrival at the first in-match command menu. The trace is diagnostic evidence only; its emulator captures are not runtime assets.

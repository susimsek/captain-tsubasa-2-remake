# Cold-start opening timing capture (FCEUX)

`tools/capture_opening_timing.lua` makes a fresh, deterministic FCEUX power-on
capture for the intro/title calibration work. It records emulator state for
analysis only. It does not read or export ROM bytes, replace any existing
capture, or create runtime game assets.

## Run

1. Open the supplied NES ROM in FCEUX 2.7.0 (or a compatible recent build).
2. Enable **Mute Speaker Output** in FCEUX before starting the script. The Lua
   API documented for FCEUX does not expose this UI mute switch; the script
   cannot ensure the emulator is silent on its own.
3. Run `tools/capture_opening_timing.lua` from FCEUX's Lua Script window.
4. Find the new, timestamped folder at
   `reference/opening_timing_capture_<local timestamp>/`.

The script uses `emu.poweron()` and replays the exact per-frame controller
states from `reference/opening_reference_capture/input_timeline.csv` through
source emulator frame 4692. It does not synthesize a new A-button cadence or
replace gaps with automatic input. Source frame 0 supplies the first
`emu.frameadvance()` call, so `script_frame = source_frame + 1`; the target
endpoint is source frame 4692 / script frame 4693. The output records both
these indices and FCEUX's actual emulator frame count before and after each
advance. The replay ends at the title endpoint and does not confirm a menu
choice.

## PPU-dot diagnostic capture

FCEUX's stock Lua API does not expose the current PPU scanline or dot. For a
diagnostic capture with those values, `tools/capture_opening_timing_ppu_dot.lua`
expects a local FCEUX 2.7.0 build patched with
`tools/diagnostics/fceux-2.7.0-ppu-timing-getters.patch` and launched with
`--newppu 1`. Keep that emulator and its outputs outside the Godot runtime.
Use `--sound 0 --volume 0` and a silent SDL backend when running the capture;
the script still records only emulator state, never assets for runtime.

The successful run is `reference/opening_timing_capture_20261024_125300/`.
Its PPU state samples match legacy FCEUX for the sampled frames checked, all
4,693 frame/input mappings match the source timeline, and bus events include
the New PPU's scanline and dot (0–340). Frame-boundary state is scanline 240,
dot 0. This supplies the missing absolute raster coordinates for register
writes, though it does not by itself implement NES loopy `v/t` scrolling or
per-dot background/sprite fetch state in the diagnostic renderer.

## Files and interpretation

- `frames.csv`: one row per source frame and script frame, actual FCEUX frame
  count before/after advance, a flag for whether post-advance FCEUX frame count
  matches the source index, absolute CPU cycle count at the frame boundary,
  cycle delta, lag flag, all eight replayed button states, and raw snapshot
  names. Mapping mismatches are also written to `capture.log`.
- `bus_events.csv`: writes to PPUCTRL (`$2000`), PPUMASK (`$2001`),
  PPUSCROLL (`$2005`), PPUADDR (`$2006`), PPUDATA (`$2007`), MMC3 mapper
  registers (`$8000/$8001/$A000/$A001/$C000/$C001/$E000/$E001`), and reads
  from PPUSTATUS (`$2002`) when read-hook registration is available. Each event
  includes the callback's frame-relative CPU-cycle offset, absolute cycle
  count, observed value and CPU PC where the API provides them.
- `ppu_states/ppu_NNNNN.bin`: the FCEUX-mapped PPU address view `$0000–$3FFF`
  captured after that source frame. Pattern-table bytes reflect the current mapper
  mapping; this is a state snapshot, not a display raster.
- `ram_states/ram_NNNNN.bin`: CPU RAM `$0000–$07FF` captured after that source frame.
- `metadata.txt`, `capture.log`: run identity, ROM MD5 when available, API
  capability flags, assumptions, and progress/errors.

`debugger.getcyclescount()` gives a CPU-cycle baseline. The official FCEUX Lua
API documentation does not list a PPU scanline/dot getter, so these records do
not claim per-event pixel coordinates or sub-cycle PPU phase. Three PPU dots
per CPU cycle is a hardware relation, but frame parity, rendering details, and
callback phase still need separate validation before turning cycle offsets into
raster positions. The PPU read/write hooks watch the documented canonical
register addresses; accesses through mirrored `$2008–$3FFF` aliases may not be
reported by this narrow watcher.

FCEUX documents `memory.registerread` starting in 2.6.6. The script feature-
checks it at runtime and records `ppu_status_read_hook` in `metadata.txt`. If
the hook cannot be installed, PPUSTATUS read events are absent and that fact is
explicitly recorded; all requested write events remain enabled.

## Provenance

API behavior checked against the official [FCEUX Lua Functions List](https://fceux.com/web/help/LuaFunctionsList.html)
and [FCEUX 2.6.6 release notes](https://fceux.com/web/pressrelease-2.6.6.html).
The register callbacks observe CPU bus accesses during emulation. PPU/RAM files
are snapshots of emulator-visible memory after `emu.frameadvance()`. Neither
kind is a screenshot-derived runtime asset, and neither replaces extraction of
canonical graphics/audio bytes from the supplied ROM.

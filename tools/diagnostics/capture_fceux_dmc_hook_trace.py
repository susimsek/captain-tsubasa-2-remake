#!/usr/bin/env python3
"""Run a silent FCEUX replay and save the opt-in DMC CPU-hook trace."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
INPUTS = ROOT / "reference/opening_reference_capture/input_timeline.csv"
LUA = ROOT / "tools/diagnostics/trace_opening_dmc_hook.lua"
PINNED_FCEUX_REVISION = "a6d03e7968bd77a8156a7c9b628a673753f2f4c6"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/audio"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def cycle(value: str) -> int:
	return int(value, 0)


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--fceux", required=True, help="path to the locally built, patched FCEUX 2.7.0 executable")
	parser.add_argument("--start-cycle", required=True, type=cycle, help="inclusive absolute FCEUX CPU-cycle boundary (timestampbase + timestamp)")
	parser.add_argument("--end-cycle", required=True, type=cycle, help="inclusive absolute FCEUX CPU-cycle boundary (timestampbase + timestamp)")
	parser.add_argument("--compact", action="store_true", help="retain DMC fetches, DAC phase corrections, and frame-sequencer events while omitting per-opcode detail")
	parser.add_argument("--instructions", action="store_true", help="record bounded CPU-hook entry/exit rows with PC, opcode, mapped PRG bank, and instruction cycles")
	parser.add_argument("--output-dir", type=Path, default=None, help="diagnostic output directory")
	args = parser.parse_args()
	if args.compact and args.instructions:
		parser.error("--compact and --instructions are mutually exclusive")
	if args.start_cycle < 0 or args.end_cycle <= args.start_cycle:
		parser.error("cycle range must be nonnegative and end-cycle must exceed start-cycle")
	if not ROM.is_file() or not INPUTS.is_file():
		parser.error("supplied ROM or recorded cold-start input timeline is missing")
	rom_sha = sha256(ROM)
	if rom_sha != EXPECTED_ROM_SHA256:
		parser.error(f"ROM SHA-256 does not match the documented target: {rom_sha}")
	
	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output_dir = (args.output_dir or DEFAULT_OUTPUT / f"fceux_dmc_hook_trace_{run_id}").resolve()
	output_dir.mkdir(parents=True, exist_ok=False)
	trace_path = output_dir / "dmc_hook_trace.csv"
	env = os.environ.copy()
	# Keep the APU implementation running while routing all audio to a dummy sink
	# and setting master volume to zero. No PCM or WAV is recorded by this tool.
	env["SDL_AUDIODRIVER"] = "dummy"
	env["CT2_DMC_TRACE_OUTPUT_DIR"] = str(output_dir)
	env["FCEU_DMC_TRACE_PATH"] = str(trace_path)
	env["FCEU_DMC_TRACE_START_CYCLE"] = str(args.start_cycle)
	env["FCEU_DMC_TRACE_END_CYCLE"] = str(args.end_cycle)
	if args.compact:
		env["FCEU_DMC_TRACE_COMPACT"] = "1"
	if args.instructions:
		env["FCEU_DMC_TRACE_INSTRUCTIONS"] = "1"
	command = [
		args.fceux,
		"--sound", "1",
		"--volume", "0",
		"--no-config", "1",
		"--savestate", "10",
		"--loadlua", str(LUA),
		str(ROM),
	]
	completed = subprocess.run(command, env=env, text=True, capture_output=True)
	(output_dir / "fceux_stdout.txt").write_text(completed.stdout, encoding="utf-8")
	(output_dir / "fceux_stderr.txt").write_text(completed.stderr, encoding="utf-8")
	capture_text = (output_dir / "capture.txt").read_text(encoding="utf-8") if (output_dir / "capture.txt").is_file() else ""
	completed_frames_match = re.search(r"^done_source_frames=(\d+)$", capture_text, re.MULTILINE)
	replay_complete = completed_frames_match is not None and int(completed_frames_match.group(1)) == 4693
	support_files_present = all((output_dir / name).is_file() for name in ("apu_writes.csv", "frame_cycles.csv"))
	if (completed.returncode != 0 and not replay_complete) or not trace_path.is_file() or not support_files_present:
		raise RuntimeError(
			f"FCEUX DMC capture failed (exit={completed.returncode}); inspect {output_dir / 'fceux_stderr.txt'}"
		)
	with trace_path.open(newline="", encoding="utf-8") as trace_file:
		reader = csv.reader(trace_file)
		header = next(reader, [])
		expected_columns = {"prg_offset", "prg_bank_8k", "opcode", "absolute_cycle", "fhcnt"}
		missing_columns = sorted(expected_columns.difference(header))
		bad_rows = [(line_number, len(row)) for line_number, row in enumerate(reader, start=2) if len(row) != len(header)]
	if missing_columns:
		raise RuntimeError(f"trace is missing columns {missing_columns}; rebuild FCEUX with {ROOT / 'tools/diagnostics/fceux-2.7.0-dmc-hook-trace.patch'}")
	if not header or bad_rows:
		first_bad = bad_rows[0] if bad_rows else None
		raise RuntimeError(f"trace CSV is incomplete or malformed at {first_bad}; inspect {trace_path}")
	trace_row_count = sum(1 for _ in trace_path.open(encoding="utf-8")) - 1
	
	meta = {
		"purpose": "Diagnostic-only DMC/FCEUX sound-hook trace for a fresh replay of the captured opening inputs.",
		"fceux_pinned_revision": PINNED_FCEUX_REVISION,
		"fceux_executable": str(Path(args.fceux).resolve()),
		"command": command,
		"audio": {
			"apu_core_enabled": True,
			"master_volume": 0,
			"sdl_audio_driver": "dummy",
			"wav_or_pcm_capture": False,
		},
		"source_rom": {"path": ROM.relative_to(ROOT).as_posix(), "sha256": rom_sha},
		"input_timeline": {"path": INPUTS.relative_to(ROOT).as_posix(), "sha256": sha256(INPUTS), "frames": 4693},
		"cycle_window": {"domain": "cycles since debugger.resetcyclescount immediately after emu.poweron; source hook absolute cycle = timestampbase + timestamp", "start_inclusive": args.start_cycle, "end_inclusive": args.end_cycle},
		"trace_mode": "instruction-boundary" if args.instructions else ("compact" if args.compact else "detailed"),
		"fceux_process": {
			"returncode": completed.returncode,
			"lua_reported_all_source_frames_complete": replay_complete,
			"nonzero_exit_accepted_only_after_complete_replay": completed.returncode == 0 or replay_complete,
		},
		"dmc_trace": {"path": trace_path.name, "sha256": sha256(trace_path), "bytes": trace_path.stat().st_size, "rows": trace_row_count, "csv_integrity_checked": True},
		"supporting_traces": {
			"apu_writes": {"path": "apu_writes.csv", "sha256": sha256(output_dir / "apu_writes.csv")},
			"frame_cycles": {"path": "frame_cycles.csv", "sha256": sha256(output_dir / "frame_cycles.csv")},
		},
		"limitations": [
			"This trace describes the pinned FCEUX 2.7.0 model, not the physical NES APU.",
			*(["FCEUX exited nonzero after the Lua runner reported all 4693 source frames and closed its capture files; the trace is accepted only as a completed replay with a shutdown failure documented here."] if completed.returncode != 0 else []),
			"The chosen absolute CPU-cycle window must include enough pre-roll to see DMC register setup and first fetches.",
			"Compact mode records frame-sequencer events, DMC byte-fetch address/value pairs, active DMC bit-state edges, and PCM_SYNC_IN DAC phase corrections; it omits the per-opcode hook timeline and four redundant same-address DMR rows per byte.",
			*(["Instruction mode records HOOK_IN/HOOK_OUT at each bounded FCEU_SoundCPUHook call, plus frame-counter crossings/reloads and selected APU/DMC edges; the values describe FCEUX's instruction hook, not a physical NES bus trace."] if args.instructions else []),
			"The instrumentation writes diagnostic state only; it does not export or use PCM as input.",
		],
		"timestamp_utc": run_id,
	}
	(output_dir / "trace_meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
	print(output_dir)


if __name__ == "__main__":
	main()

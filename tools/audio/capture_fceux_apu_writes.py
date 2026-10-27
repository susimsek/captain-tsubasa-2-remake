#!/usr/bin/env python3
"""Run a fresh muted FCEUX replay and hash the CPU-cycle APU-write trace."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
INPUTS = ROOT / "reference/opening_reference_capture/input_timeline.csv"
LUA = ROOT / "tools/diagnostics/trace_opening_apu_writes.lua"
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/audio"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--fceux", default="/opt/homebrew/bin/fceux", help="FCEUX 2.7.0 executable")
	parser.add_argument("--output-dir", type=Path, default=None, help="Diagnostic output directory")
	args = parser.parse_args()
	if not ROM.is_file() or not INPUTS.is_file():
		parser.error("supplied ROM or recorded cold-start input timeline is missing")

	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output_dir = (args.output_dir or DEFAULT_OUTPUT / f"fceux_apu_write_trace_{run_id}").resolve()
	output_dir.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env["SDL_AUDIODRIVER"] = "dummy"
	env["CT2_APU_TRACE_OUTPUT_DIR"] = str(output_dir)
	command = [
		args.fceux,
		"--sound", "0",
		"--volume", "0",
		"--no-config", "1",
		"--savestate", "10",
		"--loadlua", str(LUA),
		str(ROM),
	]
	completed = subprocess.run(command, env=env, text=True, capture_output=True)
	(output_dir / "fceux_stdout.txt").write_text(completed.stdout, encoding="utf-8")
	(output_dir / "fceux_stderr.txt").write_text(completed.stderr, encoding="utf-8")
	trace_path = output_dir / "apu_writes.csv"
	frame_path = output_dir / "frame_cycles.csv"
	if completed.returncode != 0 or not trace_path.is_file() or not frame_path.is_file():
		raise RuntimeError(
			f"FCEUX capture failed (exit={completed.returncode}); inspect {output_dir / 'fceux_stderr.txt'}"
		)

	with trace_path.open(newline="", encoding="ascii") as stream:
		rows = list(csv.DictReader(stream))
	with frame_path.open(newline="", encoding="ascii") as stream:
		frame_rows = list(csv.DictReader(stream))
	addresses: dict[str, int] = {}
	for row in rows:
		addresses[row["address"]] = addresses.get(row["address"], 0) + 1

	version_text = completed.stdout + completed.stderr
	version_line = next((line.strip() for line in version_text.splitlines() if "Starting FCEUX" in line), "unknown")
	meta = {
		"purpose": "Fresh silent FCEUX replay capturing CPU-bus writes to $4000-$4017; observation/validation only.",
		"fceux_version": version_line,
		"fceux_executable": args.fceux,
		"command": command,
		"audio": {"enabled": False, "volume": 0, "sdl_audio_driver": "dummy", "wav_or_pcm_capture": False},
		"source_rom": {"path": ROM.relative_to(ROOT).as_posix(), "sha256": sha256(ROM)},
		"input_timeline": {"path": INPUTS.relative_to(ROOT).as_posix(), "sha256": sha256(INPUTS), "frames": 4693},
		"frame_cycles": {
			"path": "frame_cycles.csv",
			"sha256": sha256(frame_path),
			"rows": len(frame_rows),
			"first_elapsed_source_frame": next((row["source_frame"] for row in frame_rows if int(row["cycle_delta"]) > 0), None),
			"last_elapsed_cycle_end": int(frame_rows[-1]["cycle_end"]) if frame_rows else None,
		},
		"trace": {
			"path": "apu_writes.csv",
			"sha256": sha256(trace_path),
			"rows": len(rows),
			"fields": list(rows[0].keys()) if rows else [],
			"writes_by_address": addresses,
			"first_cycle": int(rows[0]["cpu_cycle"]) if rows else None,
			"last_cycle": int(rows[-1]["cpu_cycle"]) if rows else None,
		},
		"timestamp_utc": run_id,
		"cycle_origin": "FCEUX debugger cycle counter reset immediately after the scripted power-on; writes are timestamped inside memory.registerwrite callbacks.",
		"limitations": [
			"The observed event stream is from the complete cartridge CPU/APU path; compare timestamps after accounting for NSF init/reset phase and frame-counter alignment.",
			"FCEUX's callback reports CPU-bus write address/value and sampled PC/cycle; it is not an audio waveform capture.",
		],
	}
	(output_dir / "trace_meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
	print(output_dir)


if __name__ == "__main__":
	main()

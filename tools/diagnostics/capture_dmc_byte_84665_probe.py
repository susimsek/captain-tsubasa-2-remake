#!/usr/bin/env python3
"""Run a muted, bounded FCEUX trace for DMC output byte 84,665."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
BOOTSTRAP = ROOT / "reference/fceux_cold_start_capture/cold_start_opening_partial.fm2"
INPUTS = ROOT / "reference/opening_reference_capture/input_timeline.csv"
LUA = ROOT / "tools/diagnostics/trace_dmc_byte_84665_probe.lua"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
BOOTSTRAP_SHA256 = "d5665334ba68c11730bcbd65bc89fadfc9b0aaf371635dfbbcba44a8acbcadbc"
PINNED_REVISION = "a6d03e7968bd77a8156a7c9b628a673753f2f4c6"
TARGET_HOOK = 34141806
TARGET_CYCLE_START = 107214570
TARGET_CYCLE_END = 107214650
SOURCE_FRAMES = 4693


def digest(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def first_source_prefix(path: Path, count: int) -> bytes:
	with path.open("rb") as stream:
		header = stream.readline()
		if header.rstrip(b"\r\n") != b"frame,up,down,left,right,A,B,start,select":
			raise ValueError("unexpected input timeline header")
		rows = [header]
		for frame in range(count):
			row = stream.readline()
			if not row:
				raise ValueError(f"input timeline ends before frame {frame}")
			parts = row.decode("ascii").strip().split(",")
			if len(parts) != 9 or int(parts[0]) != frame or any(v not in {"0", "1"} for v in parts[1:]):
				raise ValueError(f"invalid or nonsequential timeline row {frame}: {row!r}")
			rows.append(row)
	return b"".join(rows)


def last_progress(path: Path) -> dict[str, int] | None:
	if not path.is_file():
		return None
	with path.open(newline="", encoding="utf-8") as stream:
		rows = list(csv.DictReader(stream))
	if not rows:
		return None
	return {key: int(value) for key, value in rows[-1].items()}


def active_fceux_processes(exclude_pid: int | None = None) -> list[str]:
	result = subprocess.run(["ps", "-axo", "pid=,command="], capture_output=True, text=True, check=True)
	active = []
	for line in result.stdout.splitlines():
		fields = line.strip().split(None, 1)
		if len(fields) != 2 or (exclude_pid is not None and int(fields[0]) == exclude_pid):
			continue
		if "fceux.app/Contents/MacOS/fceux" in fields[1] and "capture_dmc_byte_84665_probe.py" not in fields[1]:
			active.append(line.strip())
	return active


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--fceux", required=True, type=Path, help="separate pinned FCEUX executable with DMC trace patch")
	parser.add_argument("--output-dir", required=True, type=Path)
	parser.add_argument("--stall-seconds", type=int, default=90)
	parser.add_argument("--max-seconds", type=int, default=600)
	args = parser.parse_args()

	for path in (ROM, BOOTSTRAP, INPUTS, LUA, args.fceux):
		if not path.is_file():
			raise SystemExit(f"required capture input is missing: {path}")
	if digest(ROM) != ROM_SHA256:
		raise SystemExit("supplied ROM hash changed")
	if digest(BOOTSTRAP) != BOOTSTRAP_SHA256:
		raise SystemExit("bootstrap movie hash changed")
	if digest(INPUTS) != INPUT_SHA256:
		raise SystemExit("input timeline hash changed")
	expected_prefix = first_source_prefix(INPUTS, SOURCE_FRAMES)
	if args.output_dir.exists():
		raise SystemExit(f"output directory already exists: {args.output_dir}")
	args.output_dir.mkdir(parents=True)

	preexisting = active_fceux_processes()
	if preexisting:
		raise SystemExit("FCEUX is already active; not launching a second session: " + " | ".join(preexisting))

	trace = args.output_dir / "dmc_hook_trace.csv"
	progress = args.output_dir / "progress.csv"
	applied = args.output_dir / "applied_inputs.csv"
	stdout_path = args.output_dir / "fceux_stdout.txt"
	stderr_path = args.output_dir / "fceux_stderr.txt"
	command = [str(args.fceux.resolve()), "--sound", "1", "--volume", "0",
		"--playmov", str(BOOTSTRAP), "--no-config", "1", "--savestate", "10",
		"--loadlua", str(LUA), str(ROM)]
	env = os.environ.copy()
	env.update({
		"SDL_AUDIODRIVER": "dummy",
		"FCEUX_CT2_TRACE_ONLY": "1",
		"CT2_DMC_PROBE_OUTPUT_DIR": str(args.output_dir.resolve()),
		"CT2_DMC_PROBE_INPUT_CSV": str(INPUTS.resolve()),
		"CT2_DMC_PROBE_INPUT_SHA256": INPUT_SHA256,
		"FCEU_DMC_TRACE_PATH": str(trace.resolve()),
		"FCEU_DMC_TRACE_START_CYCLE": str(TARGET_CYCLE_START),
		"FCEU_DMC_TRACE_END_CYCLE": str(TARGET_CYCLE_END),
		"FCEU_DMC_TRACE_INSTRUCTIONS": "1",
		"FCEU_DMC_TRACE_TARGET_ONLY": "1",
	})
	manifest = {
		"status": "running",
		"purpose": "Muted validation-only capture of the DMR phases and enclosing FCEUX hook for ROM-derived DMC byte 84,665.",
		"fceux_revision": PINNED_REVISION,
		"fceux_executable": str(args.fceux.resolve()),
		"fceux_executable_sha256": digest(args.fceux),
		"command": command,
		"source_rom": {"path": str(ROM.relative_to(ROOT)), "sha256": ROM_SHA256},
		"bootstrap_movie": {"path": str(BOOTSTRAP.relative_to(ROOT)), "sha256": BOOTSTRAP_SHA256,
			"purpose": "explicit startup bootstrap; Lua must stop it before and after power-on"},
		"input_timeline": {"path": str(INPUTS.relative_to(ROOT)), "sha256": INPUT_SHA256,
			"rows_applied": SOURCE_FRAMES, "frame_range": [0, SOURCE_FRAMES - 1],
			"application_verification": "post-run applied_inputs.csv must byte-match the first 4,693 hashed timeline rows; no joypad.get readback"},
		"target": {"accepted_byte_index_zero_based": 84665, "address": "$C0C4", "value": "$F1",
			"source_frame": 3601, "expected_hook_sequence": TARGET_HOOK,
			"cycle_window_inclusive": [TARGET_CYCLE_START, TARGET_CYCLE_END],
			"retained_event_types": ["HOOK_IN", "DMR", "HOOK_OUT"]},
		"audio": {"apu_core_enabled": True, "master_volume": 0, "sdl_audio_driver": "dummy", "pcm_or_wav_output": False},
		"progress": {"stall_timeout_seconds": args.stall_seconds, "max_runtime_seconds": args.max_seconds},
	}
	manifest_path = args.output_dir / "capture_manifest.json"
	manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

	started = time.monotonic()
	last_advance = started
	last_frame = -1
	status = "running"
	return_code: int | None = None
	with stdout_path.open("w", encoding="utf-8") as stdout_file, stderr_path.open("w", encoding="utf-8") as stderr_file:
		process = subprocess.Popen(command, env=env, stdout=stdout_file, stderr=stderr_file, text=True)
		print(f"launched_fceux_pid={process.pid}", flush=True)
		while process.poll() is None:
			time.sleep(5)
			competing = active_fceux_processes(exclude_pid=process.pid)
			if competing:
				status = "aborted_competing_fceux"
				print("competing_fceux_detected=" + " | ".join(competing), flush=True)
				break
			progress_row = last_progress(progress)
			if progress_row is not None and progress_row["source_frame"] > last_frame:
				last_frame = progress_row["source_frame"]
				last_advance = time.monotonic()
				print(f"progress_source_frame={last_frame} cpu_cycle={progress_row['cpu_cycle_end']}", flush=True)
			elapsed = time.monotonic() - started
			if elapsed >= args.max_seconds:
				status = "aborted_max_runtime"
				break
			if time.monotonic() - last_advance >= args.stall_seconds:
				status = "aborted_stalled"
				break
		if process.poll() is None:
			process.terminate()
			try:
				return_code = process.wait(timeout=10)
			except subprocess.TimeoutExpired:
				process.kill()
				return_code = process.wait()
		else:
			return_code = process.returncode

	completed_text = (args.output_dir / "capture.txt").read_text(encoding="utf-8") if (args.output_dir / "capture.txt").is_file() else ""
	completed = "completed_source_frames=4693" in completed_text
	if completed:
		status = "completed" if status == "running" else status
		if applied.is_file():
			actual_prefix = applied.read_bytes()
			manifest["input_timeline"]["applied_prefix_byte_exact"] = actual_prefix == expected_prefix
			manifest["input_timeline"]["applied_rows"] = max(0, len(actual_prefix.splitlines()) - 1)
		else:
			manifest["input_timeline"]["applied_prefix_byte_exact"] = False
			manifest["input_timeline"]["applied_rows"] = 0

	manifest.update({
		"status": status,
		"return_code": return_code,
		"elapsed_seconds": round(time.monotonic() - started, 3),
		"last_progress_row": last_progress(progress),
		"completed_source_frames": completed,
		"trace_file_present": trace.is_file(),
		"trace_file_bytes": trace.stat().st_size if trace.is_file() else 0,
	})
	if trace.is_file():
		try:
			with trace.open(newline="", encoding="utf-8") as stream:
				trace_rows = list(csv.DictReader(stream))
		except Exception as exc:  # preserve diagnostics if interrupted during a write
			manifest["trace_parse_error"] = str(exc)
		else:
			manifest["trace_rows"] = len(trace_rows)
			manifest["trace_events"] = [row.get("event") for row in trace_rows]
			manifest["target_dmr_rows"] = [
				{key: row.get(key) for key in ("hook", "pc", "absolute_cycle", "hook_cycles", "detail_index", "detail_address", "detail_value", "detail_extra")}
				for row in trace_rows if row.get("event") == "DMR"
			]
		manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
		print(f"capture_status={status} last_source_frame={last_frame} trace_rows={manifest.get('trace_rows', 0)}", flush=True)
		return 0 if status == "completed" and manifest.get("input_timeline", {}).get("applied_prefix_byte_exact") else 1
	manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	print(f"capture_status={status} last_source_frame={last_frame} trace_rows=0", flush=True)
	return 1


if __name__ == "__main__":
	raise SystemExit(main())

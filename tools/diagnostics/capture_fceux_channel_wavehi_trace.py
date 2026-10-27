#!/usr/bin/env python3
"""Capture bounded per-channel WaveHi input from a muted pinned FCEUX replay."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import struct
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
INPUTS = ROOT / "reference/opening_reference_capture/input_timeline.csv"
LUA = ROOT / "tools/diagnostics/trace_opening_dmc_hook.lua"
PINNED_FCEUX_REVISION = "a6d03e7968bd77a8156a7c9b628a673753f2f4c6"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
RECORD_BYTES = 32


def sha256(path: Path) -> str:
	digest = hashlib.sha256()
	with path.open("rb") as file:
		for chunk in iter(lambda: file.read(1024 * 1024), b""):
			digest.update(chunk)
	return digest.hexdigest()


def parse_cycle(value: str) -> int:
	return int(value, 0)


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--fceux", required=True, help="path to the locally built instrumented FCEUX executable")
	parser.add_argument("--start-cycle", required=True, type=parse_cycle, help="inclusive absolute CPU-cycle boundary")
	parser.add_argument("--end-cycle", required=True, type=parse_cycle, help="exclusive absolute CPU-cycle boundary")
	parser.add_argument("--output-dir", required=True, type=Path, help="new diagnostic output directory")
	parser.add_argument("--triangle-state", action="store_true", help="also capture triangle phase/timer/length state events")
	parser.add_argument("--triangle-only", action="store_true", help="capture only triangle state events, avoiding the large per-cycle channel trace")
	args = parser.parse_args()
	if args.start_cycle < 0 or args.end_cycle <= args.start_cycle:
		parser.error("cycle window must be a nonempty, nonnegative half-open interval")
	if args.triangle_only and not args.triangle_state:
		parser.error("--triangle-only requires --triangle-state")
	if not ROM.is_file() or not INPUTS.is_file():
		parser.error("supplied ROM or recorded cold-start input timeline is missing")
	rom_hash = sha256(ROM)
	if rom_hash != EXPECTED_ROM_SHA256:
		parser.error(f"ROM SHA-256 does not match the documented target: {rom_hash}")
	output_dir = args.output_dir.resolve()
	output_dir.mkdir(parents=True, exist_ok=False)
	trace_path = output_dir / "channel_wavehi_raw.bin"
	env = os.environ.copy()
	env["SDL_AUDIODRIVER"] = "dummy"
	env["CT2_DMC_TRACE_OUTPUT_DIR"] = str(output_dir)
	for key in ("FCEU_CHANNEL_WAVEHI_TRACE_PATH", "FCEU_CHANNEL_WAVEHI_TRACE_START_CYCLE", "FCEU_CHANNEL_WAVEHI_TRACE_END_CYCLE"):
		env.pop(key, None)
	if not args.triangle_only:
		env["FCEU_CHANNEL_WAVEHI_TRACE_PATH"] = str(trace_path)
		env["FCEU_CHANNEL_WAVEHI_TRACE_START_CYCLE"] = str(args.start_cycle)
		env["FCEU_CHANNEL_WAVEHI_TRACE_END_CYCLE"] = str(args.end_cycle)
	triangle_trace_path = output_dir / "triangle_state_events.csv"
	if args.triangle_state:
		env["FCEU_TRIANGLE_STATE_TRACE_PATH"] = str(triangle_trace_path)
		env["FCEU_TRIANGLE_STATE_TRACE_START_CYCLE"] = str(args.start_cycle)
		env["FCEU_TRIANGLE_STATE_TRACE_END_CYCLE"] = str(args.end_cycle)
	command = [
		str(Path(args.fceux).resolve()), "--sound", "1", "--volume", "0", "--no-config", "1",
		"--savestate", "10", "--loadlua", str(LUA), str(ROM),
	]
	completed = subprocess.run(command, env=env, text=True, capture_output=True)
	(output_dir / "fceux_stdout.txt").write_text(completed.stdout, encoding="utf-8")
	(output_dir / "fceux_stderr.txt").write_text(completed.stderr, encoding="utf-8")
	capture_path = output_dir / "capture.txt"
	capture_text = capture_path.read_text(encoding="utf-8") if capture_path.is_file() else ""
	frame_match = re.search(r"^done_source_frames=(\d+)$", capture_text, re.MULTILINE)
	replay_complete = frame_match is not None and int(frame_match.group(1)) == 4693
	if not replay_complete or (not args.triangle_only and not trace_path.is_file()) or (args.triangle_state and not triangle_trace_path.is_file()):
		raise RuntimeError(f"channel WaveHi replay incomplete (exit={completed.returncode}); inspect {output_dir}")
	rows = None
	first_cycle = None
	last_cycle_exclusive = None
	if not args.triangle_only:
		if trace_path.stat().st_size % RECORD_BYTES:
			raise RuntimeError(f"channel WaveHi trace has a partial {RECORD_BYTES}-byte record")
		rows = trace_path.stat().st_size // RECORD_BYTES
		expected_cycle = args.start_cycle
		with trace_path.open("rb") as trace_file:
			while data := trace_file.read(RECORD_BYTES * 131072):
				for (cycle, *_) in struct.iter_unpack("<Q5iI", data):
					if first_cycle is None:
						first_cycle = cycle
					if cycle != expected_cycle:
						raise RuntimeError(f"channel WaveHi trace is not cycle-contiguous at {expected_cycle}; got {cycle}")
					expected_cycle += 1
		last_cycle_exclusive = expected_cycle
		if rows != args.end_cycle - args.start_cycle or first_cycle != args.start_cycle or last_cycle_exclusive != args.end_cycle:
			raise RuntimeError(f"channel WaveHi trace coverage differs from requested window: rows={rows}, expected={args.end_cycle-args.start_cycle}")
	meta = {
		"purpose": "Validation-only per-channel FCEUX WaveHi input capture; raw channel contributions before nonlinear mixer and filter.",
		"fceux_pinned_revision": PINNED_FCEUX_REVISION,
		"fceux_executable": str(Path(args.fceux).resolve()),
		"fceux_executable_sha256": sha256(Path(args.fceux).resolve()),
		"command": command,
		"audio": {"apu_core_enabled": True, "master_volume": 0, "sdl_audio_driver": "dummy", "wav_or_pcm_capture": False},
		"source_rom": {"path": ROM.relative_to(ROOT).as_posix(), "sha256": rom_hash},
		"input_timeline": {"path": INPUTS.relative_to(ROOT).as_posix(), "sha256": sha256(INPUTS), "source_frames": 4693},
		"cycle_window": {"domain": "FCEUX absolute CPU cycles since the Lua runner resetcyclescount after power-on", "start_inclusive": args.start_cycle, "end_exclusive": args.end_cycle},
		"trace": None if args.triangle_only else {
			"path": trace_path.name,
			"sha256": sha256(trace_path),
			"bytes": trace_path.stat().st_size,
			"rows": rows,
			"record_bytes": RECORD_BYTES,
			"record_fields": ["uint64 cycle", "int32 pulse1", "int32 pulse2", "int32 triangle", "int32 noise", "int32 DMC", "uint32 raw WaveHi before nonlinear mixing"],
			"byte_order": "little-endian",
			"first_cycle": first_cycle,
			"last_cycle_exclusive": last_cycle_exclusive,
		},
		"triangle_state_trace": None if not args.triangle_state else {
			"path": triangle_trace_path.name,
			"sha256": sha256(triangle_trace_path),
			"bytes": triangle_trace_path.stat().st_size,
			"rows": sum(1 for _ in triangle_trace_path.open(encoding="utf-8")) - 1,
			"fields": ["cycle", "event", "triangle step before/after", "timer before/after", "length count", "linear counter", "active flag", "$4008/$400A/$400B"],
			"event_types": ["flush", "step"],
		},
		"supporting_traces": {
			"apu_writes_sha256": sha256(output_dir / "apu_writes.csv"),
			"frame_cycles_sha256": sha256(output_dir / "frame_cycles.csv"),
		},
		"fceux_process": {"returncode": completed.returncode, "lua_reported_all_4693_source_frames": replay_complete},
		"limitations": [
			"This is the pinned FCEUX model, not physical NES APU hardware.",
			"The trace is validation-only and is not a source or scheduler input for ROM-only synthesis.",
			"The per-channel records describe additive WaveHi contributions before nonlinear mixing and filtering; they are not post-mixer PCM.",
		],
		"timestamp_utc": datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc"),
	}
	(output_dir / "trace_meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({"output_dir": str(output_dir), "rows": rows, "bytes": None if args.triangle_only else trace_path.stat().st_size}, indent=2))


if __name__ == "__main__":
	main()

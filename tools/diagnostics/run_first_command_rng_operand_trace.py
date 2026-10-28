#!/usr/bin/env python3
"""Run a muted, checkpointed FCEUX trace of first-command RNG operands."""

from __future__ import annotations

import csv
import hashlib
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
LUA = ROOT / "tools/diagnostics/trace_first_command_rng_operands.lua"
OPENING_INPUT = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE_INPUT = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_OPENING_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
EXPECTED_ROUTE_SHA256 = "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
CHECKPOINT_FRAME = 8399
LAST_FRAME = 8593


def digest(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def frames(path: Path, name: str) -> list[int]:
	with path.open(newline="", encoding="utf-8") as stream:
		return [int(row[name]) for row in csv.DictReader(stream)]


def validate_inputs() -> tuple[str, str, str]:
	for path in (ROM, LUA, OPENING_INPUT, ROUTE_INPUT):
		if not path.is_file():
			raise SystemExit(f"Required trace input is missing: {path}")
	rom_hash = digest(ROM)
	opening_hash = digest(OPENING_INPUT)
	route_hash = digest(ROUTE_INPUT)
	if rom_hash != EXPECTED_ROM_SHA256:
		raise SystemExit(f"Wrong target ROM: {rom_hash}")
	if opening_hash != EXPECTED_OPENING_SHA256:
		raise SystemExit(f"Opening input changed: {opening_hash}")
	if route_hash != EXPECTED_ROUTE_SHA256:
		raise SystemExit(f"Post-title input changed: {route_hash}")
	opening_frames = frames(OPENING_INPUT, "frame")
	route_frames = frames(ROUTE_INPUT, "source_frame")
	if opening_frames[:4693] != list(range(4693)):
		raise SystemExit("Opening input must cover source frames 0–4692.")
	if route_frames[: LAST_FRAME - 4693 + 1] != list(range(4693, LAST_FRAME + 1)):
		raise SystemExit("Post-title input must cover source frames 4693–8593.")
	return rom_hash, opening_hash, route_hash


def main() -> None:
	rom_hash, opening_hash, route_hash = validate_inputs()
	if not FCEUX.is_file():
		raise SystemExit(f"FCEUX is not installed at {FCEUX}")
	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output = ROOT / "reference/diagnostics" / f"first_command_rng_operand_trace_{run_id}"
	output.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env.update({
		"SDL_AUDIODRIVER": "dummy",
		"CT2_PROJECT_ROOT": str(ROOT),
		"CT2_RNG_OPERAND_TRACE_OUTPUT_DIR": str(output),
		"CT2_OPENING_INPUT_SHA256": opening_hash,
		"CT2_ROUTE_INPUT_SHA256": route_hash,
		"CT2_ROM_SHA256": rom_hash,
	})
	command = [
		str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
		"--newppu", "1", "--loadlua", str(LUA), str(ROM),
	]
	started = time.monotonic()
	with (output / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
			(output / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
		process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
		last_progress: str | None = None
		while process.poll() is None:
			progress_path = output / "progress.txt"
			if progress_path.is_file():
				progress = progress_path.read_text(encoding="ascii").strip()
				if progress and progress != last_progress:
					print(f"Muted C9C5 operand trace: {progress}", flush=True)
					last_progress = progress
			if time.monotonic() - started > 300:
				process.kill()
				process.wait()
				raise SystemExit(f"Trace exceeded five minutes; last progress={last_progress}; output={output}")
			time.sleep(0.5)

	metadata = output / "metadata.txt"
	complete_marker = (output / "progress.txt").read_text(encoding="ascii").strip() if (output / "progress.txt").is_file() else ""
	complete = complete_marker == "pass2:8593" and metadata.is_file() and "completion_marker=pass2:8593" in metadata.read_text(encoding="utf-8")
	with metadata.open("a", encoding="utf-8") as stream:
		stream.write("fceux_version=2.7.0\n")
		stream.write(f"fceux_executable={FCEUX}\n")
		stream.write(f"fceux_command={' '.join(command)}\n")
		stream.write(f"fceux_process_exit_code={process.returncode}\n")
		stream.write(f"elapsed_seconds={time.monotonic() - started:.3f}\n")
		stream.write(f"outputs_complete={str(complete).lower()}\n")
	if complete:
		for name in (
			"checkpoint_operand_cells.csv", "operand_writes_window.csv",
			"operand_writes_window_repeat.csv", "c9c5_calls_window.csv",
			"c9c5_calls_window_repeat.csv", "window_start.bin",
			"window_start_repeat.bin", "window_end.bin", "window_end_repeat.bin",
		):
			path = output / name
			if not path.is_file():
				raise SystemExit(f"Trace completion marker exists but output is missing: {path}")
			with metadata.open("a", encoding="utf-8") as stream:
				stream.write(f"sha256_{name}={digest(path)}\n")
		print(f"Trace outputs complete at {output}; FCEUX exit={process.returncode}")
		if process.returncode != 0:
			print("FCEUX returned a nonzero shutdown status after writing its completion marker; review stderr and the trace README.")
		return
	raise SystemExit(f"Trace did not complete; last progress={complete_marker}; output={output}; FCEUX exit={process.returncode}")


if __name__ == "__main__":
	main()

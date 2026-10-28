#!/usr/bin/env python3
"""Prepare and run the muted FCEUX actor-writer trace for frames 8400–8953."""

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
LUA = ROOT / "tools/diagnostics/trace_first_command_actor_writers.lua"
OPENING_INPUT = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE_INPUT = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_OPENING_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
EXPECTED_ROUTE_SHA256 = "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
FIRST_FRAME = 8400
LAST_FRAME = 8953


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def read_frames(path: Path, frame_column: str) -> list[int]:
	with path.open(newline="", encoding="utf-8") as stream:
		return [int(row[frame_column]) for row in csv.DictReader(stream)]


def validate_inputs() -> tuple[str, str]:
	for path in (ROM, LUA, OPENING_INPUT, ROUTE_INPUT):
		if not path.is_file():
			raise SystemExit(f"Required trace input is missing: {path}")
	rom_hash = sha256(ROM)
	opening_hash = sha256(OPENING_INPUT)
	route_hash = sha256(ROUTE_INPUT)
	if rom_hash != EXPECTED_ROM_SHA256:
		raise SystemExit(f"Wrong target ROM: {rom_hash}")
	if opening_hash != EXPECTED_OPENING_SHA256:
		raise SystemExit(f"Opening input timeline changed: {opening_hash}")
	if route_hash != EXPECTED_ROUTE_SHA256:
		raise SystemExit(f"Post-title input timeline changed: {route_hash}")
	opening_frames = read_frames(OPENING_INPUT, "frame")
	route_frames = read_frames(ROUTE_INPUT, "source_frame")
	if opening_frames[:4693] != list(range(4693)):
		raise SystemExit("Opening input timeline must contain the exact source-frame prefix 0–4692.")
	if route_frames[: LAST_FRAME - 4693 + 1] != list(range(4693, LAST_FRAME + 1)):
		raise SystemExit("Post-title input timeline must contain the exact source-frame prefix 4693–8953.")
	return opening_hash, route_hash


def main() -> None:
	opening_hash, route_hash = validate_inputs()
	if not FCEUX.is_file():
		raise SystemExit(f"FCEUX is not installed at the configured path: {FCEUX}")

	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output = ROOT / "reference/diagnostics" / f"first_command_actor_writer_trace_{run_id}"
	output.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env.update({
		"SDL_AUDIODRIVER": "dummy",
		"CT2_PROJECT_ROOT": str(ROOT),
		"CT2_ACTOR_WRITER_TRACE_OUTPUT_DIR": str(output),
		"CT2_OPENING_INPUT_SHA256": opening_hash,
		"CT2_ROUTE_INPUT_SHA256": route_hash,
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
					print(f"Muted actor-writer replay: source frame {progress}", flush=True)
					last_progress = progress
			if time.monotonic() - started > 300:
				process.kill()
				process.wait()
				raise SystemExit(f"Trace exceeded five minutes; last frame={last_progress}; output={output}")
			time.sleep(0.5)

	with (output / "metadata.txt").open("a", encoding="utf-8") as stream:
		stream.write(f"source_rom_sha256={sha256(ROM)}\n")
		stream.write(f"opening_input_sha256={opening_hash}\n")
		stream.write(f"route_input_sha256={route_hash}\n")
		stream.write(f"fceux_executable={FCEUX}\n")
		stream.write(f"fceux_command={' '.join(command)}\n")
		stream.write(f"exit_code={process.returncode}\n")
		stream.write(f"elapsed_seconds={time.monotonic() - started:.3f}\n")
	if process.returncode != 0:
		raise SystemExit(f"FCEUX trace exited with {process.returncode}; output={output}")
	print(output)


if __name__ == "__main__":
	main()

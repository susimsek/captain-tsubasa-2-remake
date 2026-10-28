#!/usr/bin/env python3
"""Run a muted same-input PPU/MMC3 bus trace from an anonymous FCEUX state."""

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
LUA = ROOT / "tools/diagnostics/trace_first_command_ppu_bus_from_8399.lua"
OPENING_INPUT = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE_INPUT = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_OPENING_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
EXPECTED_ROUTE_SHA256 = "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
LAST_TRACE_FRAME = 8953
TOTAL_TIMEOUT_SECONDS = 300
NO_PROGRESS_TIMEOUT_SECONDS = 60


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def read_frames(path: Path, frame_column: str) -> list[int]:
	with path.open(newline="", encoding="utf-8") as stream:
		return [int(row[frame_column]) for row in csv.DictReader(stream)]


def normalized_bus_hash(path: Path) -> str:
	"""Ignore the intentional pass-number column when comparing replay rows."""
	with path.open(newline="", encoding="utf-8") as stream:
		rows = list(csv.reader(stream))
	if not rows or "pass" not in rows[0]:
		raise SystemExit(f"Bus trace has no pass column: {path}")
	pass_index = rows[0].index("pass")
	for row in rows[1:]:
		if pass_index < len(row):
			del row[pass_index]
	payload = "\n".join(",".join(row) for row in rows).encode("utf-8")
	return hashlib.sha256(payload).hexdigest()


def validate_inputs() -> tuple[str, str]:
	for path in (ROM, LUA, OPENING_INPUT, ROUTE_INPUT):
		if not path.is_file():
			raise SystemExit(f"Required trace input is missing: {path}")
	rom_hash, opening_hash, route_hash = sha256(ROM), sha256(OPENING_INPUT), sha256(ROUTE_INPUT)
	if rom_hash != EXPECTED_ROM_SHA256:
		raise SystemExit(f"Wrong target ROM: {rom_hash}")
	if opening_hash != EXPECTED_OPENING_SHA256:
		raise SystemExit(f"Opening input timeline changed: {opening_hash}")
	if route_hash != EXPECTED_ROUTE_SHA256:
		raise SystemExit(f"Post-title input timeline changed: {route_hash}")
	opening_frames = read_frames(OPENING_INPUT, "frame")
	route_frames = read_frames(ROUTE_INPUT, "source_frame")
	if opening_frames[:4693] != list(range(4693)):
		raise SystemExit("Opening input timeline must contain source frames 0–4692.")
	if route_frames[: LAST_TRACE_FRAME - 4693 + 1] != list(range(4693, LAST_TRACE_FRAME + 1)):
		raise SystemExit("Post-title input timeline must contain source frames 4693–8953.")
	return opening_hash, route_hash


def main() -> None:
	opening_hash, route_hash = validate_inputs()
	if not FCEUX.is_file():
		raise SystemExit(f"FCEUX is not installed at {FCEUX}")
	stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output = ROOT / "reference/diagnostics" / f"first_command_ppu_bus_trace_{stamp}"
	output.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env.update({
		"SDL_AUDIODRIVER": "dummy",
		"CT2_PROJECT_ROOT": str(ROOT),
		"CT2_PPU_BUS_TRACE_OUTPUT_DIR": str(output),
		"CT2_OPENING_INPUT_SHA256": opening_hash,
		"CT2_ROUTE_INPUT_SHA256": route_hash,
	})
	command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
		"--newppu", "1", "--loadlua", str(LUA), str(ROM)]
	started = time.monotonic()
	last_progress: str | None = None
	last_progress_at = started
	with (output / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
			(output / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
		process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
		while process.poll() is None:
			progress_path = output / "progress.txt"
			if progress_path.is_file():
				progress = progress_path.read_text(encoding="ascii").strip()
				if progress and progress != last_progress:
					print(f"Muted PPU/MMC3 trace: {progress}", flush=True)
					last_progress = progress
					last_progress_at = time.monotonic()
				elapsed = time.monotonic() - started
				if elapsed > TOTAL_TIMEOUT_SECONDS:
					process.kill()
					process.wait()
					raise SystemExit(f"Trace exceeded 5 minutes; last progress={last_progress}; output={output}")
				if time.monotonic() - last_progress_at > NO_PROGRESS_TIMEOUT_SECONDS:
					process.kill()
					process.wait()
					raise SystemExit(f"Trace made no progress for 60 seconds; last progress={last_progress}; output={output}")
				time.sleep(0.25)

	elapsed = time.monotonic() - started
	metadata_path = output / "metadata.txt"
	with metadata_path.open("a", encoding="utf-8") as stream:
		stream.write(f"source_rom_sha256={sha256(ROM)}\n")
		stream.write(f"opening_input_sha256={opening_hash}\nroute_input_sha256={route_hash}\n")
		stream.write(f"fceux_executable={FCEUX}\nfceux_command={' '.join(command)}\n")
		stream.write(f"exit_code={process.returncode}\nelapsed_seconds={elapsed:.3f}\n")

	bus_a = output / "ppu_mmc3_bus_writes.csv"
	bus_b = output / "ppu_mmc3_bus_writes_repeat.csv"
	frames_a = output / "frame_edges.csv"
	frames_b = output / "frame_edges_repeat.csv"
	metadata_text = metadata_path.read_text(encoding="utf-8")
	if process.returncode not in (0, -11) or "complete=true" not in metadata_text:
		raise SystemExit(f"FCEUX trace incomplete (exit {process.returncode}); output={output}")
	if not all(path.is_file() for path in (bus_a, bus_b, frames_a, frames_b)):
		raise SystemExit(f"Trace outputs are missing; output={output}")
	if normalized_bus_hash(bus_a) != normalized_bus_hash(bus_b) or sha256(frames_a) != sha256(frames_b):
		raise SystemExit(f"The two save-state replay passes differ; output={output}")
	print(f"PASS: two checkpointed traces match after excluding the pass label; elapsed={elapsed:.2f}s; exit={process.returncode}")
	if process.returncode == -11:
		print("NOTE: FCEUX crashed during shutdown after writing complete trace outputs.")
	print(output)


if __name__ == "__main__":
	main()

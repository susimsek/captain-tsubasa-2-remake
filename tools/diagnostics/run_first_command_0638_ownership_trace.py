#!/usr/bin/env python3
"""Run and compare two muted cold-start FCEUX traces of RAM $0638 ownership."""

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
LUA = ROOT / "tools/diagnostics/trace_first_command_0638_ownership.lua"
OPENING = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED = {
	ROM: "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
	OPENING: "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3",
	ROUTE: "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e",
}
LAST_FRAME = 8953


def sha(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_inputs() -> None:
	for path, expected in EXPECTED.items():
		if not path.is_file() or sha(path) != expected:
			raise SystemExit(f"Missing or changed trace input: {path}")
	if not LUA.is_file() or not FCEUX.is_file():
		raise SystemExit("FCEUX or the diagnostic trace script is missing")
	with OPENING.open(newline="", encoding="utf-8") as stream:
		opening = [int(row["frame"]) for row in csv.DictReader(stream)]
	with ROUTE.open(newline="", encoding="utf-8") as stream:
		route = [int(row["source_frame"]) for row in csv.DictReader(stream)]
	if opening[:4693] != list(range(4693)):
		raise SystemExit("Opening input must cover source frames 0–4692")
	if route[: LAST_FRAME - 4693 + 1] != list(range(4693, LAST_FRAME + 1)):
		raise SystemExit("Post-title input must cover source frames 4693–8953")


def normalized_hash(path: Path) -> str:
	with path.open(newline="", encoding="utf-8") as stream:
		rows = list(csv.reader(stream))
	if not rows or "pass" not in rows[0]:
		raise SystemExit(f"Missing pass column: {path}")
	index = rows[0].index("pass")
	for row in rows[1:]:
		if index < len(row):
			del row[index]
	return hashlib.sha256("\n".join(",".join(row) for row in rows).encode()).hexdigest()


def main() -> None:
	validate_inputs()
	stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	out = ROOT / "reference/diagnostics" / f"first_command_0638_ownership_trace_{stamp}"
	out.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env.update({
		"SDL_AUDIODRIVER": "dummy",
		"CT2_PROJECT_ROOT": str(ROOT),
		"CT2_0638_TRACE_OUTPUT_DIR": str(out),
	})
	command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
		"--newppu", "1", "--loadlua", str(LUA), str(ROM)]
	started = time.monotonic()
	last_progress: str | None = None
	last_progress_at = started
	with (out / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
			(out / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
		process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
		while process.poll() is None:
			progress_path = out / "progress.txt"
			if progress_path.is_file():
				progress = progress_path.read_text(encoding="ascii").strip()
				if progress and progress != last_progress:
					print(f"Muted $0638 ownership trace: {progress}", flush=True)
					last_progress = progress
					last_progress_at = time.monotonic()
			if time.monotonic() - started > 360:
				process.kill(); process.wait()
				raise SystemExit(f"Trace exceeded 6 minutes; last={last_progress}; output={out}")
			if time.monotonic() - last_progress_at > 90:
				process.kill(); process.wait()
				raise SystemExit(f"Trace made no progress for 90 seconds; last={last_progress}; output={out}")
			time.sleep(0.25)

	elapsed = time.monotonic() - started
	metadata_path = out / "metadata.txt"
	with metadata_path.open("a", encoding="utf-8") as stream:
		for path, digest in EXPECTED.items():
			stream.write(f"sha256_{path.name}={digest}\n")
		stream.write(f"fceux_executable={FCEUX}\nfceux_command={' '.join(command)}\n")
		stream.write(f"exit_code={process.returncode}\nelapsed_seconds={elapsed:.3f}\n")
	metadata = metadata_path.read_text(encoding="utf-8")
	if process.returncode not in (0, -11) or "complete=true" not in metadata:
		raise SystemExit(f"Trace incomplete (exit {process.returncode}); output={out}")
	for first, second in (
		("ram_0638_writes.csv", "ram_0638_writes_repeat.csv"),
		("candidate_writer_execs.csv", "candidate_writer_execs_repeat.csv"),
		("coordinate_callee_execs.csv", "coordinate_callee_execs_repeat.csv"),
		("source_context.csv", "source_context_repeat.csv"),
		("frame_values.csv", "frame_values_repeat.csv"),
	):
		if normalized_hash(out / first) != normalized_hash(out / second):
			raise SystemExit(f"The two same-input traces differ in {first}; output={out}")
	for filename in ("start_state.bin", "start_state_repeat.bin", "end_state.bin", "end_state_repeat.bin"):
		if not (out / filename).is_file():
			raise SystemExit(f"Missing state signature artifact {filename}; output={out}")
	if sha(out / "start_state.bin") != sha(out / "start_state_repeat.bin"):
		raise SystemExit(f"Pass start RAM differs; output={out}")
	if sha(out / "end_state.bin") != sha(out / "end_state_repeat.bin"):
		raise SystemExit(f"Pass end RAM differs; output={out}")
	with (out / "ram_0638_writes.csv").open(newline="", encoding="utf-8") as stream:
		writes = list(csv.DictReader(stream))
	print(f"$0638 writes/pass={len(writes)}", flush=True)
	for row in writes:
		if row["old_value"] != row["new_value"]:
			print(f"transition frame={row['source_frame']} cycle={row['cycle_absolute']} pc={row['pc_after_write']} bank={row['pc_prg_bank']} {row['old_value']}->{row['new_value']}", flush=True)
	print(f"PASS: two cold-start checkpointed replays match; FCEUX exit {process.returncode}; elapsed={elapsed:.2f}s; output={out}")
	if process.returncode == -11:
		print("NOTE: FCEUX exited -11 after writing complete, matching trace files.", flush=True)


if __name__ == "__main__":
	main()

#!/usr/bin/env python3
"""Run and validate muted shared-state write traces for frames 8400–8953."""

from __future__ import annotations

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
LUA = ROOT / "tools/diagnostics/trace_first_command_actor_shared_state_from_8399.lua"
OPENING = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED = {
	ROM: "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
	OPENING: "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3",
	ROUTE: "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e",
}
LAST_FRAME = 8953


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def read_frames(path: Path, field: str) -> list[int]:
	with path.open(newline="", encoding="utf-8") as stream:
		return [int(row[field]) for row in csv.DictReader(stream)]


def normalized_hash(path: Path) -> str:
	with path.open(newline="", encoding="utf-8") as stream:
		rows = list(csv.reader(stream))
	if not rows:
		raise SystemExit(f"Trace output is empty: {path.name}")
	return hashlib.sha256("\n".join(",".join(row) for row in rows).encode()).hexdigest()


def main() -> None:
	for path, expected in EXPECTED.items():
		if not path.is_file() or sha256(path) != expected:
			raise SystemExit(f"Missing or changed trace input: {path.name}")
	if not LUA.is_file() or not FCEUX.is_file():
		raise SystemExit("FCEUX or the shared-state Lua trace is unavailable")
	opening_frames = read_frames(OPENING, "frame")
	route_frames = read_frames(ROUTE, "source_frame")
	if opening_frames[:4693] != list(range(4693)):
		raise SystemExit("Opening input is not the preserved 0–4692 timeline")
	if route_frames[: LAST_FRAME - 4693 + 1] != list(range(4693, LAST_FRAME + 1)):
		raise SystemExit("Post-title input is not the preserved 4693–8953 timeline")

	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	out = ROOT / "reference/diagnostics" / f"first_command_actor_shared_state_{run_id}"
	out.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env.update({
		"SDL_AUDIODRIVER": "dummy",
		"CT2_PROJECT_ROOT": str(ROOT),
		"CT2_ACTOR_SHARED_STATE_TRACE_OUTPUT_DIR": str(out),
		"CT2_OPENING_INPUT_SHA256": sha256(OPENING),
		"CT2_ROUTE_INPUT_SHA256": sha256(ROUTE),
	})
	command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
		"--newppu", "1", "--loadlua", str(LUA), str(ROM)]
	started = time.monotonic()
	last_progress = None
	last_progress_at = started
	with (out / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
			(out / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
		process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
		while process.poll() is None:
			progress_path = out / "progress.txt"
			if progress_path.is_file():
				progress = progress_path.read_text(encoding="ascii").strip()
				if progress and progress != last_progress:
					print(f"Muted shared-state replay: source frame {progress}", flush=True)
					last_progress, last_progress_at = progress, time.monotonic()
			if time.monotonic() - started > 300 or time.monotonic() - last_progress_at > 180:
				process.kill()
				process.wait()
				raise SystemExit(f"Trace timed out; last progress={last_progress}; output={out}")
			time.sleep(0.25)

	elapsed = time.monotonic() - started
	metadata = out / "metadata.txt"
	if not metadata.is_file():
		raise SystemExit(f"Trace did not produce metadata; output={out}")
	with metadata.open("a", encoding="utf-8") as stream:
		stream.write(f"source_rom_sha256={sha256(ROM)}\n")
		stream.write(f"opening_input_sha256={sha256(OPENING)}\nroute_input_sha256={sha256(ROUTE)}\n")
		stream.write(f"fceux_executable={FCEUX}\nfceux_command={' '.join(command)}\n")
		stream.write(f"fceux_exit_code={process.returncode}\nelapsed_seconds={elapsed:.3f}\n")
	metadata_text = metadata.read_text(encoding="utf-8")
	if process.returncode not in (0, -11) or "complete=true" not in metadata_text:
		raise SystemExit(f"FCEUX trace incomplete (exit {process.returncode}); output={out}")

	first_writes = out / "shared_state_writes.csv"
	repeat_writes = out / "shared_state_writes_repeat.csv"
	first_frames = out / "frame_state.csv"
	repeat_frames = out / "frame_state_repeat.csv"
	if not all(path.is_file() for path in (first_writes, repeat_writes, first_frames, repeat_frames)):
		raise SystemExit(f"One or more replay trace files are missing; output={out}")
	write_hash = normalized_hash(first_writes)
	repeat_write_hash = normalized_hash(repeat_writes)
	frame_hash = normalized_hash(first_frames)
	repeat_frame_hash = normalized_hash(repeat_frames)
	if write_hash != repeat_write_hash or frame_hash != repeat_frame_hash:
		raise SystemExit(f"Replay traces differ; output={out}")
	with first_writes.open(newline="", encoding="utf-8") as stream:
		write_rows = list(csv.DictReader(stream))
	address_counts = {address: sum(row["address"] == address for row in write_rows)
		for address in ("$0517", "$0538", "$0540", "$0541")}
	if len(write_rows) == 0 or len(read_frames(first_frames, "source_frame")) != 555:
		raise SystemExit(f"Trace row count is unexpected; output={out}")
	result = {
		"checkpoint_source_frame": 8399,
		"checkpoint_signature_verified_after_both_loads": True,
		"replay_source_frames": [8400, LAST_FRAME],
		"replay_passes": 2,
		"normalized_write_sha256": write_hash,
		"normalized_frame_state_sha256": frame_hash,
		"write_event_count": len(write_rows),
		"write_counts_by_address": address_counts,
		"frame_rows_per_replay": 555,
		"audio_muted": True,
		"numbered_save_slots_touched": False,
		"diagnostics_only": True,
		"fceux_exit_code": process.returncode,
		"elapsed_seconds": round(elapsed, 3),
	}
	(out / "validation.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(f"PASS: two shared-state trace replays match; {len(write_rows)} writes; output={out}")


if __name__ == "__main__":
	main()

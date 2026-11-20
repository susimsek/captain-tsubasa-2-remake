#!/usr/bin/env python3
"""Capture and validate only the ROM task/caller context needed for KICK OFF."""

from __future__ import annotations

import csv
import hashlib
import json
import os
import subprocess
import time
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OPENING = ROOT / "reference/opening_reference_capture/input_timeline.csv"
ROUTE = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
LUA = ROOT / "tools/diagnostics/trace_kickoff_task_context.lua"
FCEUX = Path("/opt/homebrew/bin/fceux")
EXPECTED = {
	ROM: "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
	OPENING: "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3",
	ROUTE: "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e",
}
FIXED_SCHEDULER_HOOKS = {
	"$C50F", "$C512", "$C515", "$CA22", "$CA97", "$CAE7", "$CB0F",
}


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized_hash(path: Path) -> tuple[str, int, Counter[str]]:
	with path.open(newline="", encoding="utf-8") as stream:
		reader = csv.DictReader(stream)
		fields = [field for field in (reader.fieldnames or []) if field != "pass"]
		if not fields:
			raise SystemExit(f"Missing CSV header in {path}")
		rows = []
		pcs: Counter[str] = Counter()
		for row in reader:
			rows.append(",".join(row[field] for field in fields))
			pcs[row["pc"]] += 1
	return hashlib.sha256("\n".join(rows).encode()).hexdigest(), len(rows), pcs


def main() -> None:
	for path, expected in EXPECTED.items():
		if not path.is_file() or sha256(path) != expected:
			raise SystemExit(f"Missing or changed trace input: {path.name}")
	if not FCEUX.is_file() or not LUA.is_file():
		raise SystemExit("FCEUX or the focused task-context Lua trace is unavailable")

	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output = ROOT / "reference/diagnostics" / f"kickoff_task_context_{run_id}"
	output.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env.update({"SDL_AUDIODRIVER": "dummy", "CT2_PROJECT_ROOT": str(ROOT),
		"CT2_TASK_CONTEXT_TRACE_OUTPUT_DIR": str(output)})
	command = [str(FCEUX), "--sound", "0", "--volume", "0", "--no-config", "1",
		"--newppu", "1", "--loadlua", str(LUA), str(ROM)]
	started = time.monotonic()
	last_progress, last_progress_at = None, started
	with (output / "fceux_stdout.txt").open("w", encoding="utf-8") as stdout, \
			(output / "fceux_stderr.txt").open("w", encoding="utf-8") as stderr:
		process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr)
		while process.poll() is None:
			progress_path = output / "progress.txt"
			if progress_path.is_file():
				progress = progress_path.read_text(encoding="ascii").strip()
				if progress and progress != last_progress:
					print(f"Muted task-context FCEUX trace: {progress}", flush=True)
					last_progress, last_progress_at = progress, time.monotonic()
			if time.monotonic() - started > 180 or time.monotonic() - last_progress_at > 45:
				process.kill()
				process.wait()
				raise SystemExit(f"Trace timed out; last progress={last_progress}; output={output}")
			time.sleep(0.25)

	metadata = output / "metadata.txt"
	metadata_text = metadata.read_text(encoding="utf-8") if metadata.is_file() else ""
	metadata_values = dict(line.split("=", 1) for line in metadata_text.splitlines() if "=" in line)
	if process.returncode not in (0, -11) or "complete=true" not in metadata_text:
		raise SystemExit(f"FCEUX trace incomplete (exit {process.returncode}); output={output}")

	pass_paths = [output / "task_context_hooks.csv", output / "task_context_hooks_repeat.csv"]
	pass_results = [normalized_hash(path) for path in pass_paths]
	if pass_results[0][0] != pass_results[1][0] or pass_results[0][1] != pass_results[1][1]:
		raise SystemExit(f"Task-context replay passes differ; output={output}")
	with pass_paths[0].open(newline="", encoding="utf-8") as stream:
		rows = list(csv.DictReader(stream))
	startup_path = output / "startup_old_task_create_hooks.csv"
	with startup_path.open(newline="", encoding="utf-8") as stream:
		startup_rows = list(csv.DictReader(stream))
	seed = next((row for row in startup_rows if row["source_frame"] == "7" and row["x"] == "$01"), None)
	if seed is None or seed["a"] != "$00" or seed["y"] != "$28" \
			or seed["sp"] != "$FD" or seed["stack_next_8"] != "91A2000000000000" \
			or not seed["ram_0000_001f"].startswith("001E8000"):
		raise SystemExit(f"Cold-start slot-$01 seed hook changed or is missing; output={output}")
	observed = {(row["pc"], int(row["source_frame"])) for row in rows}
	observed_pcs = {row["pc"] for row in rows}
	fixed_scheduler_events = sorted(FIXED_SCHEDULER_HOOKS & observed_pcs)
	if fixed_scheduler_events:
		raise SystemExit(f"Unexpected fixed-scheduler hooks in the old KICK OFF route: {fixed_scheduler_events}; output={output}")
	required = {("$80E6", 4693), ("$9FA8", 4693), ("$8494", 4708),
		("$9F69", 4708), ("$84C6", 4708), ("$82EC", 7258), ("$A15B", 7266)}
	missing = sorted(required - observed)
	if missing:
		raise SystemExit(f"Trace missed expected ROM source hooks {missing}; output={output}")

	validation = {
		"rom_sha256": sha256(ROM), "opening_input_sha256": sha256(OPENING),
		"route_input_sha256": sha256(ROUTE), "fceux_version": "2.7.0",
		"fceux_exit_code": process.returncode,
		"elapsed_seconds": round(time.monotonic() - started, 3),
		"checkpoint_source_frame": 4692, "trace_window": [4693, 7266],
		"muted": True, "anonymous_in_session_checkpoint": True,
		"signature_checked_after_both_loads": True,
		"pass_rows": pass_results[0][1], "normalized_pass_sha256": pass_results[0][0],
		"pc_event_counts": dict(pass_results[0][2]),
		"fixed_scheduler_hooks_expected_absent": sorted(FIXED_SCHEDULER_HOOKS),
		"startup_old_task_create_events": len(startup_rows),
		"slot01_seed_hook": {"source_frame": 7, "x": seed["x"], "y": seed["y"],
			"a": seed["a"], "sp": seed["sp"], "stack_next_8": seed["stack_next_8"],
			"ram_0000_001f_prefix": seed["ram_0000_001f"][:8]},
		"required_hooks_seen": [f"{pc}@{frame}" for pc, frame in sorted(required)],
		"diagnostics_only": True,
	}
	(output / "validation.json").write_text(json.dumps(validation, indent=2) + "\n", encoding="utf-8")
	with metadata.open("a", encoding="utf-8") as stream:
		stream.write(f"fceux_exit_code={process.returncode}\nelapsed_seconds={validation['elapsed_seconds']:.3f}\n")
	print(f"PASS: {pass_results[0][1]} identical task/caller hook events across muted in-session checkpoint replays; output={output}")


if __name__ == "__main__":
	main()

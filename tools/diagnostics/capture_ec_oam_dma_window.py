#!/usr/bin/env python3
"""Run a muted FCEUX replay and capture OAM page bytes at each DMA edge."""

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
INPUTS = ROOT / "reference/opening_reference_capture/input_timeline.csv"
LUA = ROOT / "tools/diagnostics/capture_ec_oam_dma_window.lua"
FCEUX = "/opt/homebrew/bin/fceux"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def entry4(page: bytes) -> str:
	return " ".join(f"{value:02X}" for value in page[0x10:0x14])


def main() -> None:
	if not ROM.is_file() or not INPUTS.is_file():
		raise SystemExit("missing supplied ROM or cold-start input timeline")
	run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_utc")
	output = ROOT / "reference/diagnostics" / f"ec_oam_dma_window_{run_id}"
	output.mkdir(parents=True, exist_ok=False)
	env = os.environ.copy()
	env["SDL_AUDIODRIVER"] = "dummy"
	env["CT2_OAM_TRACE_OUTPUT_DIR"] = str(output)
	command = [FCEUX, "--sound", "0", "--volume", "0", "--no-config", "1",
		"--savestate", "10", "--loadlua", str(LUA), str(ROM)]
	started = time.monotonic()
	process = subprocess.Popen(command, env=env, stdout=subprocess.PIPE,
		stderr=subprocess.PIPE, text=True)
	last_progress = None
	while process.poll() is None:
		progress_path = output / "progress.txt"
		if progress_path.is_file():
			lines = progress_path.read_text(encoding="ascii").splitlines()
			current = lines[-1] if lines else None
			if current != last_progress:
				print(f"FCEUX source frame {current}", flush=True)
				last_progress = current
		if time.monotonic() - started > 240:
			process.kill()
			stdout, stderr = process.communicate()
			(output / "fceux_stdout.txt").write_text(stdout, encoding="utf-8")
			(output / "fceux_stderr.txt").write_text(stderr, encoding="utf-8")
			raise SystemExit(f"FCEUX replay timed out; progress={last_progress}; output={output}")
		time.sleep(0.25)
	stdout, stderr = process.communicate()
	(output / "fceux_stdout.txt").write_text(stdout, encoding="utf-8")
	(output / "fceux_stderr.txt").write_text(stderr, encoding="utf-8")
	progress_text = (output / "progress.txt").read_text(encoding="ascii") if (output / "progress.txt").exists() else ""
	complete = f"complete 1529" in progress_text
	if process.returncode != 0 and not complete:
		raise SystemExit(f"FCEUX failed (exit={process.returncode}); output={output}")

	with (output / "oam_dma.csv").open(newline="", encoding="utf-8") as stream:
		dma_rows = list(csv.DictReader(stream))
	with (output / "frame_pages.csv").open(newline="", encoding="utf-8") as stream:
		frame_rows = list(csv.DictReader(stream))
	by_frame = {int(row["source_frame"]): row for row in frame_rows}
	prev_match = current_match = 0
	comparisons = []
	for row in dma_rows:
		frame = int(row["source_frame"])
		path = output / row["source_page_file"]
		page_at_dma = path.read_bytes() if path.is_file() else b""
		observed = entry4(page_at_dma) if len(page_at_dma) == 256 else ""
		prior = by_frame.get(frame - 1)
		current = by_frame.get(frame)
		prior_page = (output / prior["source_page_file"]).read_bytes() if prior else b""
		current_page = (output / current["source_page_file"]).read_bytes() if current else b""
		matches_prior = len(page_at_dma) == 256 and page_at_dma == prior_page
		matches_current = len(page_at_dma) == 256 and page_at_dma == current_page
		prev_match += int(matches_prior)
		current_match += int(matches_current)
		comparisons.append({
			"source_frame": frame,
			"pc": row["cpu_pc"],
			"page": row["page"],
			"oam4_at_dma": observed,
			"oam4_at_prior_frame_end": entry4(prior_page) if len(prior_page) == 256 else None,
			"oam4_at_current_frame_end": entry4(current_page) if len(current_page) == 256 else None,
			"dma_page_equals_prior_frame_end": matches_prior,
			"dma_page_equals_current_frame_end": matches_current,
		})
	analysis = {
		"source_rom_sha256": sha256(ROM),
		"input_timeline_sha256": sha256(INPUTS),
		"replay_complete_through_source_frame": 1529 if complete else None,
		"fceux_returncode": process.returncode,
		"dma_events": len(dma_rows),
		"dma_events_page_02": sum(row["page"] == "$02" for row in dma_rows),
		"dma_events_pc_a00a": sum(row["cpu_pc"] == "$A00A" for row in dma_rows),
		"dma_source_page_matches_prior_end_count": prev_match,
		"dma_source_page_matches_current_end_count": current_match,
		"dma_page_capture_method": "single $4014 CPU-write hook; source page bytes read synchronously at the DMA event, with frame-end page snapshots for comparison",
		"timing_note": "PPU scanline/dot values are model-specific; CPU cycles and emulator frame are recorded for event ordering.",
		"runtime_asset_use": False,
		"dma_comparisons": comparisons,
	}
	(output / "analysis.json").write_text(json.dumps(analysis, indent=2) + "\n", encoding="utf-8")
	print(output)
	print(json.dumps({k: v for k, v in analysis.items() if k != "dma_comparisons"}, indent=2))


if __name__ == "__main__":
	main()

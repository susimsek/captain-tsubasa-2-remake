#!/usr/bin/env python3
"""Build a diagnostic NSF that replays the ROM-derived cue history before BGM $55.

The source queue CSV in reference/rom_extract is produced by the ROM-only CPU
stepper. This wrapper runs the original sound driver once per NTSC frame and
queues those source events through the first-match $55 request. It deliberately
does not import FCEUX RAM captures or captured PCM as an event or audio source.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TRACE_DIR = ROOT / "reference/rom_extract/audio/first_match_bgm55_driver_trace_20261028"
QUEUE_HISTORY = TRACE_DIR / "route_queue_history.csv"
QUEUE_HISTORY_SHA256 = "a0f11662c1f89fddfe3cc2297dfc710a416859f801fde899fdaaa2ff438aa63e"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def load_source_events() -> list[dict]:
	if sha256(QUEUE_HISTORY) != QUEUE_HISTORY_SHA256:
		raise ValueError("ROM-derived queue-history CSV hash does not match")
	result: list[dict] = []
	with QUEUE_HISTORY.open(newline="", encoding="ascii") as stream:
		for row in csv.DictReader(stream):
			if row["address"] != "$0700":
				raise ValueError("Queue-history CSV contains a non-$0700 event")
			if not row["value"].startswith("$"):
				raise ValueError("Queue-history event is not in hexadecimal format")
			sound_id = int(row["value"][1:], 16)
			result.append({
				"frame": int(row["source_frame"]),
				"sound_id": sound_id,
				"command_source": "ROM-only CPU stepper queue-store event",
				"source_status": "ROM execution event; no emulator schedule input",
				"source_cycle": int(row["cycle"]),
				"post_store_pc": row["pc"],
			})
	if len(result) != 14 or result[-1]["frame"] != 4816 or result[-1]["sound_id"] != 0x55:
		raise ValueError("Expected the 14 source queue events ending at first BGM $55")
	if any(a["frame"] >= b["frame"] for a, b in zip(result, result[1:])):
		raise ValueError("Queue-history frames are not strictly increasing")
	return result


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--output", type=Path, required=True, help="Diagnostic NSF output path")
	args = parser.parse_args()

	# The timeline builder's default module import derives its default event list
	# from captured RAM. Replace that provider before importing the builder so this
	# source-only diagnostic never reads the capture-derived schedule.
	sys.path.insert(0, str(ROOT / "tools/audio"))
	import derive_opening_sound_events

	derive_opening_sound_events.derive_events = lambda: ([], {
		"mode": "capture-free import guard for first-match source-history NSF"
	})
	import build_opening_timeline_nsf as timeline

	rom_hash = hashlib.sha256(timeline.ROM.read_bytes()).hexdigest()
	if rom_hash != ROM_SHA256 or timeline.EXPECTED_SHA256 != ROM_SHA256:
		raise ValueError(f"Unexpected source ROM SHA-256: {rom_hash}")
	events = load_source_events()
	timeline.EVENT_DETAILS = events
	timeline.EVENT_DERIVATION = {
		"mode": "ROM-only source-stepper queue history through first-match BGM $55",
		"source_rom_sha256": ROM_SHA256,
		"source_queue_history_csv": QUEUE_HISTORY.relative_to(ROOT).as_posix(),
		"source_queue_history_csv_sha256": QUEUE_HISTORY_SHA256,
		"captured_ram_used_to_schedule": False,
		"captured_pcm_or_wav_used": False,
	}
	info = timeline.build(args.output.resolve())
	info["event_source"] = timeline.EVENT_DERIVATION
	info["captured_ram_used_to_schedule"] = False
	info["captured_pcm_or_wav_used"] = False
	info["runtime_dependency"] = False
	args.output.resolve().with_suffix(".json").write_text(
		json.dumps(info, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({
		"output": str(args.output.resolve()),
		"nsf_sha256": info["nsf_sha256"],
		"event_count": len(events),
		"last_event": events[-1],
		"captured_ram_used_to_schedule": False,
		"captured_pcm_or_wav_used": False,
	}, indent=2))


if __name__ == "__main__":
	main()

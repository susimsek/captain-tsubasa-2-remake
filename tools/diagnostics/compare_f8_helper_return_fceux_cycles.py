#!/usr/bin/env python3
"""Compare F8 helper-return FCEUX instruction cycles with ROM-only stepping."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
INPUT_PATH = ROOT / "reference/opening_reference_capture/input_timeline.csv"
EVENT_PATH = ROOT / "assets/opening/rom_logic/f8_helper_return_event.json"
SOURCE_CYCLES_PATH = ROOT / "reference/diagnostics/f8_return_source_trace_20261026/source_frame_cycles.csv"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
ROM_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"
INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def read_kv(path: Path) -> dict[str, str]:
	result: dict[str, str] = {}
	for line in path.read_text(encoding="utf-8").splitlines():
		if "=" in line:
			key, value = line.split("=", 1)
			result[key] = value
	return result


def read_rows(path: Path) -> list[dict[str, str]]:
	with path.open(newline="", encoding="utf-8") as stream:
		return list(csv.DictReader(stream))


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("trace_dir", type=Path, help="FCEUX output folder containing events.csv and metadata.txt")
	args = parser.parse_args()
	trace_dir = args.trace_dir.resolve()

	assert sha256(ROM_PATH) == ROM_SHA256, "Supplied ROM hash differs from the pinned target."
	assert hashlib.md5(ROM_PATH.read_bytes()[16:]).hexdigest() == ROM_MD5, "FCEUX PRG+CHR hash differs."
	assert sha256(INPUT_PATH) == INPUT_SHA256, "Recorded input route hash differs."
	event_doc = json.loads(EVENT_PATH.read_text(encoding="utf-8"))
	assert event_doc["source_rom_sha256"] == ROM_SHA256
	assert event_doc["input_timeline_sha256"] == INPUT_SHA256
	stepper_report = json.loads((ROOT / event_doc["stepper_report"]).read_text(encoding="utf-8"))
	assert sha256(SOURCE_CYCLES_PATH) == stepper_report["outputs"]["source_frame_cycles.csv"]

	metadata = read_kv(trace_dir / "metadata.txt")
	assert metadata.get("rom_md5") == ROM_MD5
	assert metadata.get("rom_sha256_expected") == ROM_SHA256
	assert metadata.get("input_timeline_expected_sha256") == INPUT_SHA256
	movie_stop = metadata.get("movie_stop", "")
	assert movie_stop == "no movie loaded" or movie_stop.startswith("true"), (
		"Configured startup movie was not stopped."
	)
	assert metadata.get("post_poweron_movie_mode") == "nil", "A movie was active after power-on."
	assert metadata.get("post_poweron_movie_active") == "false", "A movie was active after power-on."
	assert metadata.get("done_frames") == "3969", "FCEUX replay did not finish source frame 3968."
	assert metadata.get("input_timeline_applied_frames") == "3969", "Input timeline was not applied for every frame."
	assert metadata.get("audio", "").startswith("disabled"), "Trace was not muted."

	observed = read_rows(trace_dir / "events.csv")
	frame_rows = read_rows(trace_dir / "frame_cycles.csv")
	with INPUT_PATH.open(newline="", encoding="utf-8") as stream:
		timeline_rows = list(csv.DictReader(stream))
	timeline = {int(row["frame"]): row for row in timeline_rows}
	assert len(frame_rows) == 3969, f"Expected 3969 input/frame rows, got {len(frame_rows)}."
	input_field_map = {
		"input_up": "up", "input_down": "down", "input_left": "left", "input_right": "right",
		"input_a": "A", "input_b": "B", "input_start": "start", "input_select": "select",
	}
	for expected_frame, row in enumerate(frame_rows):
		assert int(row["source_frame"]) == expected_frame
		assert int(row["emulator_frame_after"]) == expected_frame
		for capture_field, input_field in input_field_map.items():
			assert int(row[capture_field]) == int(timeline[expected_frame][input_field]), (
				f"Input timeline mismatch at source frame {expected_frame}, {input_field}"
			)
	frame_starts = {int(r["source_frame"]): int(r["cycle_start"])
		for r in read_rows(SOURCE_CYCLES_PATH)}
	cursor = 0
	comparisons = []
	for source_event in event_doc["events"]:
		frame = int(source_event["source_frame"])
		pc = source_event["pc"]
		index = next((i for i in range(cursor, len(observed))
			if observed[i]["source_frame"] == str(frame) and observed[i]["cpu_pc"] == pc), None)
		assert index is not None, f"Missing ordered FCEUX hook at frame {frame} PC {pc}."
		row = observed[index]
		assert int(row["emulator_frame"]) == frame, (
			f"FCEUX frame mapping differs at {pc}: {row['emulator_frame']} vs source {frame}"
		)
		model_cycle = int(source_event["modeled_cycle"])
		model_offset = model_cycle - frame_starts[frame]
		fceux_offset = int(row["cycle_from_frame_start"])
		fceux_absolute = int(row["cycle_absolute"])
		model_bank = int(source_event["prg_bank_8k"])
		if int(pc[1:], 16) >= 0xA000:
			active_bank = int(row["mmc3_r7"].replace("$", ""), 16)
		else:
			select = int(row["mmc3_select"].replace("$", ""), 16)
			active_bank = 30 if select & 0x40 else int(row["mmc3_r6"].replace("$", ""), 16)
		assert active_bank == model_bank, (
			f"{pc} frame {frame} bank mismatch: FCEUX MMC3 bank {active_bank}, source {model_bank}"
		)
		comparisons.append({
			"source_frame": frame,
			"pc": pc,
			"fceux_cycle_from_frame_start": fceux_offset,
			"rom_stepper_cycle_from_frame_start": model_offset,
			"cycle_delta_fceux_minus_stepper": fceux_offset - model_offset,
			"fceux_cycle_absolute": fceux_absolute,
			"rom_stepper_cycle_absolute": model_cycle,
			"absolute_cycle_delta_fceux_minus_stepper": fceux_absolute - model_cycle,
			"fceux_mmc3_bank": active_bank,
			"rom_stepper_bank": model_bank,
			"a": row["a"], "x": row["x"], "y": row["y"],
		})
		cursor = index + 1

	cycle_deltas = [item["cycle_delta_fceux_minus_stepper"] for item in comparisons]
	report = {
		"result": "PASS_WITH_MEASURED_CYCLE_RESIDUALS",
		"fceux_version": "2.7.0",
		"rom_sha256": ROM_SHA256,
		"rom_md5": ROM_MD5,
		"input_timeline_sha256": INPUT_SHA256,
		"source_frames": [3967, 3968],
		"audio": "disabled",
		"startup_movie_stopped": True,
		"post_poweron_movie_mode": "nil",
		"all_input_timeline_rows_applied_and_compared": len(frame_rows),
		"comparison_basis": "ordered FCEUX registerexec PC-entry cycles vs ROM-only stepper cycle_start; measured offsets are reported, not assumed exact",
		"matched_pc_events": len(comparisons),
		"cycle_delta_min": min(cycle_deltas),
		"cycle_delta_max": max(cycle_deltas),
		"cycle_delta_histogram": {str(delta): cycle_deltas.count(delta) for delta in sorted(set(cycle_deltas))},
		"pc_events": comparisons,
		"physical_2A03_dma_timing_established": False,
		"scope_note": "This validates the pinned FCEUX software model and the recorded route; it does not measure physical NES bus timing or desktop scanout.",
	}
	output = trace_dir / "f8_helper_return_cycle_comparison.json"
	output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
	print(f"PASS: {len(comparisons)} ordered F8 helper-return PC hooks, input frames, and MMC3 bank states matched; cycle residuals {min(cycle_deltas)}..{max(cycle_deltas)} cycles; report={output}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())

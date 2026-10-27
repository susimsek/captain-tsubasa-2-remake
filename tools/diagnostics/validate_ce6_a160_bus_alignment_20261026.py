#!/usr/bin/env python3
"""Validate the CE6 A160 event candidate against the full same-input FCEUX bus capture."""

from __future__ import annotations

import csv
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BASELINE_PATH = ROOT / "reference/rom_extract/intro/rom_source_a160_ppu_write_timeline.json"
CANDIDATE_PATH = ROOT / "reference/diagnostics/audio/rom_stepper_opcode_ce6_full_4692_20261026/a160_visual_events_ce6_candidate.json"
INPUT_PATH = ROOT / "reference/opening_reference_capture/input_timeline.csv"
CAPTURE_ROOT = ROOT / "reference/opening_timing_capture_20261024_125300"
CAPTURE_FRAMES_PATH = CAPTURE_ROOT / "frames.csv"
BUS_EVENTS_PATH = CAPTURE_ROOT / "bus_events.csv"
CAPTURE_METADATA_PATH = CAPTURE_ROOT / "metadata.txt"
OUTPUT_PATH = ROOT / "reference/diagnostics/audio/rom_stepper_opcode_ce6_full_4692_20261026/a160_ce6_full_bus_validation.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
BUTTONS = ("up", "down", "left", "right", "A", "B", "start", "select")


def read_csv(path: Path) -> list[dict[str, str]]:
	with path.open(newline="", encoding="utf-8") as stream:
		return list(csv.DictReader(stream))


def histogram(values: list[int]) -> dict[str, int]:
	return {str(key): count for key, count in sorted(Counter(values).items())}


def load_events(path: Path) -> tuple[dict, list[dict]]:
	document = json.loads(path.read_text(encoding="utf-8"))
	return document, document["events"]


def compare_events(events: list[dict], fceux_pairs: dict[int, dict[str, dict[str, str]]],
				frames_to_check: list[int]) -> dict:
	by_frame = {int(event["source_frame"]): event for event in events}
	residuals: dict[str, list[int]] = {
		"cpu_cycle": [], "scanline": [], "dot": [], "value": [],
	}
	nonzero_frames: set[int] = set()
	for frame in frames_to_check:
		pair = fceux_pairs[frame]
		# The FCEUX write hook logs the PC after the completed STA instruction:
		# source $A175 appears as PC $A178, and source $A178 as PC $A17B.
		for index, fceux_pc in enumerate(("$A178", "$A17B")):
			predicted = by_frame[frame]["writes"][index]
			observed = pair[fceux_pc]
			residuals["cpu_cycle"].append(int(predicted["cpu_cycle"]) - int(observed["cycle_absolute"]))
			residuals["scanline"].append(int(predicted["scanline"]) - int(observed["ppu_scanline"]))
			residuals["dot"].append(int(predicted["dot"]) - int(observed["ppu_dot"]))
			predicted_value = int(predicted["value"])
			observed_value = int(observed["value"].removeprefix("$"), 16)
			residuals["value"].append(predicted_value - observed_value)
			if residuals["cpu_cycle"][-1] or residuals["scanline"][-1] \
					or residuals["dot"][-1] or residuals["value"][-1]:
				nonzero_frames.add(frame)
	return {
		"source_frames": len(frames_to_check),
		"event_rows": len(frames_to_check) * 2,
		"exact_counts": {name: sum(value == 0 for value in values)
			for name, values in residuals.items()},
		"nonzero_source_frames": sorted(nonzero_frames),
		"residuals": {
			name: {
				"min": min(values), "max": max(values),
				"histogram": histogram(values),
			}
			for name, values in residuals.items()
		},
	}


def main() -> None:
	input_bytes = INPUT_PATH.read_bytes()
	input_sha256 = hashlib.sha256(input_bytes).hexdigest()
	if input_sha256 != EXPECTED_INPUT_SHA256:
		raise SystemExit(f"Input timeline hash changed: {input_sha256}")

	baseline_doc, baseline_events = load_events(BASELINE_PATH)
	candidate_doc, candidate_events = load_events(CANDIDATE_PATH)
	if baseline_doc.get("rom_sha256") != EXPECTED_ROM_SHA256:
		raise SystemExit("Baseline timeline ROM identity mismatch")
	if candidate_doc.get("rom_sha256") != EXPECTED_ROM_SHA256:
		raise SystemExit("Candidate timeline ROM identity mismatch")
	if candidate_doc.get("input_timeline_sha256") != input_sha256:
		raise SystemExit("Candidate timeline input identity mismatch")

	baseline_by_frame = {int(event["source_frame"]): event for event in baseline_events}
	candidate_by_frame = {int(event["source_frame"]): event for event in candidate_events}
	if baseline_by_frame.keys() != candidate_by_frame.keys():
		raise SystemExit("Baseline and candidate source-frame sets differ")
	changed_frames = sorted(frame for frame in baseline_by_frame
		if baseline_by_frame[frame]["writes"] != candidate_by_frame[frame]["writes"])
	if len(changed_frames) != 301:
		raise SystemExit(f"Expected 301 changed frames; found {len(changed_frames)}")

	input_rows = {int(row["frame"]): row for row in read_csv(INPUT_PATH)}
	capture_rows = {int(row["source_frame"]): row for row in read_csv(CAPTURE_FRAMES_PATH)}
	if set(capture_rows) != set(range(4693)):
		raise SystemExit("FCEUX timing capture does not contain all 4,693 source frames")
	input_mismatches = []
	for frame in range(4693):
		for button in BUTTONS:
			if int(input_rows[frame][button]) != int(capture_rows[frame][button]):
				input_mismatches.append({"source_frame": frame, "button": button})
	if input_mismatches:
		raise SystemExit(f"FCEUX input capture differs at {input_mismatches[:5]}")
	if "source_input_csv=" not in CAPTURE_METADATA_PATH.read_text(encoding="utf-8"):
		raise SystemExit("FCEUX timing capture metadata is missing its input source")

	fceux_pairs: dict[int, dict[str, dict[str, str]]] = defaultdict(dict)
	for row in read_csv(BUS_EVENTS_PATH):
		frame = int(row["source_frame"])
		if frame in changed_frames and row["address"] == "$2006" \
				and row["cpu_pc"] in ("$A178", "$A17B"):
			if row["cpu_pc"] in fceux_pairs[frame]:
				raise SystemExit(f"Duplicate FCEUX A160 store in source frame {frame}")
			fceux_pairs[frame][row["cpu_pc"]] = row
	if set(fceux_pairs) != set(changed_frames) or any(
		set(pair) != {"$A178", "$A17B"} for pair in fceux_pairs.values()
	):
		raise SystemExit("Full FCEUX bus capture is missing a changed-frame A160 store")

	clusters: list[dict[str, int]] = []
	for frame in changed_frames:
		if not clusters or frame - clusters[-1]["last_source_frame"] > 60:
			clusters.append({"first_source_frame": frame, "last_source_frame": frame, "frame_count": 1})
		else:
			clusters[-1]["last_source_frame"] = frame
			clusters[-1]["frame_count"] += 1

	metadata = CAPTURE_METADATA_PATH.read_text(encoding="utf-8")
	all_event_frames = sorted(baseline_by_frame)
	all_fceux_pairs: dict[int, dict[str, dict[str, str]]] = defaultdict(dict)
	for row in read_csv(BUS_EVENTS_PATH):
		frame = int(row["source_frame"])
		if frame in baseline_by_frame and row["address"] == "$2006" \
				and row["cpu_pc"] in ("$A178", "$A17B"):
			if row["cpu_pc"] in all_fceux_pairs.setdefault(frame, {}):
				raise SystemExit(f"Duplicate FCEUX A160 store in source frame {frame}")
			all_fceux_pairs[frame][row["cpu_pc"]] = row
	if set(all_fceux_pairs) != set(all_event_frames) or any(
		set(pair) != {"$A178", "$A17B"} for pair in all_fceux_pairs.values()
	):
		raise SystemExit("Full FCEUX bus capture is missing a timeline A160 store")
	input_source = next((line.split("=", 1)[1] for line in metadata.splitlines()
		if line.startswith("source_input_csv=")), "")
	if not input_source.endswith("reference/opening_reference_capture/input_timeline.csv"):
		raise SystemExit("FCEUX timing capture does not identify the expected controller timeline")
	result = {
		"purpose": "same-input full-capture FCEUX bus validation for baseline and CE6 A160 timelines",
		"rom_sha256": EXPECTED_ROM_SHA256,
		"input_timeline_sha256": input_sha256,
		"fceux_capture": {
			"path": CAPTURE_ROOT.relative_to(ROOT).as_posix(),
			"source_frames": len(capture_rows),
			"button_mismatches": len(input_mismatches),
			"frame_mapping_matches_source": all(int(row["mapping_matches_source_frame"]) == 1
				for row in capture_rows.values()),
			"ppu_event_rows": sum(1 for _ in open(BUS_EVENTS_PATH, encoding="utf-8")) - 1,
			"metadata_rom_md5": next((line.split("=", 1)[1] for line in metadata.splitlines()
				if line.startswith("rom_md5=")), ""),
		},
		"changed_frames": {
			"count": len(changed_frames),
			"first": changed_frames[0],
			"last": changed_frames[-1],
			"clusters": clusters,
			"fceux_bus_pairs": len(fceux_pairs),
		},
		"full_timeline_event_frames_with_fceux_pairs": len(all_fceux_pairs),
		"baseline_changed_frame_validation": compare_events(baseline_events, fceux_pairs, changed_frames),
		"ce6_changed_frame_validation": compare_events(candidate_events, fceux_pairs, changed_frames),
		"baseline_full_timeline_validation": compare_events(baseline_events, all_fceux_pairs, all_event_frames),
		"ce6_full_timeline_validation": compare_events(candidate_events, all_fceux_pairs, all_event_frames),
		"mapping": {
			"predicted_first_store": "$A175",
			"fceux_post_store_pc_first": "$A178",
			"predicted_second_store": "$A178",
			"fceux_post_store_pc_second": "$A17B",
			"comparison_fields": ["absolute_cpu_cycle", "ppu_scanline", "ppu_dot", "write_value"],
		},
		"limitations": [
			"This is pinned FCEUX 2.7.0 bus-model evidence, not physical NES bus timing.",
			"This report validates A160 PPU store timing, not rendered RGB or audio PCM.",
		],
	}
	OUTPUT_PATH.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({
		"output": OUTPUT_PATH.relative_to(ROOT).as_posix(),
		"changed_frames": result["changed_frames"],
		"baseline_changed": result["baseline_changed_frame_validation"]["exact_counts"],
		"ce6_changed": result["ce6_changed_frame_validation"]["exact_counts"],
		"baseline_full": result["baseline_full_timeline_validation"]["exact_counts"],
		"ce6_full": result["ce6_full_timeline_validation"]["exact_counts"],
		"ce6_nonzero_frames": result["ce6_full_timeline_validation"]["nonzero_source_frames"],
	}, indent=2))


if __name__ == "__main__":
	main()

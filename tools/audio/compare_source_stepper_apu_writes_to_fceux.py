#!/usr/bin/env python3
"""Compare source-stepper APU writes with a retained same-input FCEUX log."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path


ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
APU_ADDRESSES = set(range(0x4000, 0x4014)) | {0x4015, 0x4017}


def sha256(path: Path) -> str:
	digest = hashlib.sha256()
	with path.open("rb") as stream:
		for chunk in iter(lambda: stream.read(1024 * 1024), b""):
			digest.update(chunk)
	return digest.hexdigest()


def byte_value(value: str) -> int:
	return int(value.strip().removeprefix("$"), 16)


def read_apu(path: Path, *, source_stepper: bool, first_source_frame: int | None) -> list[dict]:
	rows = []
	with path.open(newline="", encoding="utf-8") as stream:
		for row in csv.DictReader(stream):
			address = byte_value(row["address"])
			if address not in APU_ADDRESSES:
				continue
			frame = int(row["source_frame"])
			if first_source_frame is not None and frame < first_source_frame:
				continue
			rows.append({
				"frame": frame,
				"cycle": int(row["cycle"] if source_stepper else row["cycles"]),
				"pc": row["pc"].upper(),
				"address": address,
				"value": byte_value(row["value"]),
			})
	return rows


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--source-apu", type=Path, required=True)
	parser.add_argument("--fceux-apu", type=Path, required=True)
	parser.add_argument("--stepper-report", type=Path, required=True)
	parser.add_argument("--input-timeline", type=Path, required=True)
	parser.add_argument("--first-source-frame", type=int, default=None,
		help="optional shared input/trace start frame, e.g. 4817 for the post-title APU log")
	parser.add_argument("--output", type=Path, required=True)
	args = parser.parse_args()

	stepper_report = json.loads(args.stepper_report.read_text(encoding="utf-8"))
	if stepper_report.get("source_rom_sha256") != ROM_SHA256:
		raise SystemExit("source-stepper ROM hash is not the expected supplied ROM")
	input_sha = sha256(args.input_timeline)
	if stepper_report.get("input_timeline_sha256") != input_sha:
		raise SystemExit("input timeline hash differs from the source-stepper report")

	source = read_apu(args.source_apu, source_stepper=True, first_source_frame=args.first_source_frame)
	reference = read_apu(args.fceux_apu, source_stepper=False, first_source_frame=args.first_source_frame)
	common = min(len(source), len(reference))
	sequence_mismatches = [
		{"index": i, "source": source[i], "fceux": reference[i]}
		for i in range(common)
		if (source[i]["frame"], source[i]["address"], source[i]["value"])
		!= (reference[i]["frame"], reference[i]["address"], reference[i]["value"])
	]
	cycle_deltas = [source[i]["cycle"] - reference[i]["cycle"] for i in range(common)
		if (source[i]["frame"], source[i]["address"], source[i]["value"])
		== (reference[i]["frame"], reference[i]["address"], reference[i]["value"])]
	cycle_mismatches = [
		{"index": i, "source": source[i], "fceux": reference[i],
		 "source_minus_fceux_cycle": source[i]["cycle"] - reference[i]["cycle"]}
		for i in range(common)
		if (source[i]["frame"], source[i]["address"], source[i]["value"])
		== (reference[i]["frame"], reference[i]["address"], reference[i]["value"])
		and source[i]["cycle"] != reference[i]["cycle"]
	]
	pc_equal = sum(source[i]["pc"] == reference[i]["pc"] for i in range(common))
	result = {
		"purpose": "Post-run source event comparison only; FCEUX data is not synthesis or runtime input.",
		"source_rom_sha256": ROM_SHA256,
		"input_timeline_sha256": input_sha,
		"source_stepper": {
			"path": str(args.source_apu),
			"sha256": sha256(args.source_apu),
			"apu_writes": len(source),
		},
		"fceux_reference": {
			"path": str(args.fceux_apu),
			"sha256": sha256(args.fceux_apu),
			"apu_writes": len(reference),
			"role": "retained same-input register-write trace; validation only",
		},
		"comparison": {
			"filter": "$4000-$4013, $4015, $4017; exclude $4014 OAM DMA and $4016 controller strobe",
			"first_source_frame": args.first_source_frame,
			"compared_ordered_prefix": common,
			"address_value_frame_sequence_exact": len(source) == len(reference) and not sequence_mismatches,
			"sequence_mismatch_count_in_prefix": len(sequence_mismatches),
			"first_mismatches": sequence_mismatches[:10],
			"cycle_mismatch_events": cycle_mismatches,
			"source_minus_fceux_cycle_delta_counts": dict(sorted(Counter(cycle_deltas).items())),
			"cycle_exact_writes": sum(delta == 0 for delta in cycle_deltas),
			"cycle_mismatch_count": sum(delta != 0 for delta in cycle_deltas),
			"max_abs_cycle_delta": max((abs(delta) for delta in cycle_deltas), default=None),
			"pc_equal_in_prefix": pc_equal,
			"pc_comparison_note": "PC is reported as a supplementary field; the primary bus-event match is frame/address/value/cycle.",
		},
		"limitations": [
			"This compares the source-stepper's modeled CPU cycle labels to pinned FCEUX software execution, not physical NES bus timing.",
			"A matching APU register-write log does not establish DMC bus arbitration or rendered PCM equality.",
		],
	}
	args.output.parent.mkdir(parents=True, exist_ok=True)
	args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	comparison = result["comparison"]
	print(json.dumps({
		"first_source_frame": comparison["first_source_frame"],
		"compared_ordered_prefix": comparison["compared_ordered_prefix"],
		"address_value_frame_sequence_exact": comparison["address_value_frame_sequence_exact"],
		"sequence_mismatch_count_in_prefix": comparison["sequence_mismatch_count_in_prefix"],
		"pc_equal_in_prefix": comparison["pc_equal_in_prefix"],
		"cycle_exact_writes": comparison["cycle_exact_writes"],
		"cycle_mismatch_count": comparison["cycle_mismatch_count"],
		"source_minus_fceux_cycle_delta_counts": comparison["source_minus_fceux_cycle_delta_counts"],
		"max_abs_cycle_delta": comparison["max_abs_cycle_delta"],
	}, indent=2))
	print(args.output)


if __name__ == "__main__":
	main()

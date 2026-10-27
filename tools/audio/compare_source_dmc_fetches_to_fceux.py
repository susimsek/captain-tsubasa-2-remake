#!/usr/bin/env python3
"""Compare ROM/NSF-only DMC fetches with FCEUX fetch events after synthesis.

FCEUX traces are validation inputs only. This tool does not generate or alter
audio and never reads captured PCM.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MODEL = ROOT / "reference/diagnostics/audio/source_phase_seed1_wavehi_20261026/source_dmc_rom_fetches.csv"
DEFAULT_FCEUX = ROOT / "reference/diagnostics/audio/fceux_dmc_hook_trace_pcm_sync_sequence_ordered_merged_20261025/dmc_hook_trace.csv"
DEFAULT_SOURCE_APU = ROOT / "reference/diagnostics/audio/source_phase_seed1_candidate_20261025/apu_trace/apu_writes.csv"
DEFAULT_FCEUX_APU = ROOT / "reference/diagnostics/audio/fceux_apu_write_trace_20261024_184945_utc/apu_writes.csv"
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/audio/source_dmc_fceux_sequence_audit_20261026.json"
SAMPLE_INDICES = (0, 1, 10, 50, 100, 200, 300, 400, 475, 476, 477)


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def parse_hex(value: str) -> int:
	return int(value.strip().replace("$", "").replace("0x", ""), 16)


def load_source_fetches(path: Path) -> list[dict[str, int]]:
	rows: list[dict[str, int]] = []
	with path.open(newline="", encoding="utf-8") as stream:
		for row in csv.DictReader(stream):
			rows.append({
				"sequence": int(row["sequence"]),
				"cycle": int(row["source_cpu_cycle"]),
				"address": parse_hex(row["cpu_address"]) & 0xFFFF,
				"value": parse_hex(row["value"]) & 0xFF,
			})
	return rows


def load_fceux_fetches(path: Path) -> list[dict[str, int]]:
	rows: list[dict[str, int]] = []
	with path.open(newline="", encoding="utf-8") as stream:
		for row in csv.DictReader(stream):
			if row["event"] != "DMC_DMA_OUT":
				continue
			rows.append({
				"sequence": len(rows),
				"cycle": int(row["absolute_cycle"]),
				"address": int(row["detail_address"], 16) & 0xFFFF,
				"value": int(row["detail_value"]) & 0xFF,
				"source_frame": int(row["hook"]),
			})
	return rows


def load_apu_status_writes(path: Path, fceux: bool) -> list[dict[str, int]]:
	rows: list[dict[str, int]] = []
	with path.open(newline="", encoding="utf-8") as stream:
		for row in csv.DictReader(stream):
			address = parse_hex(row["address"])
			value = parse_hex(row["value"])
			if address != 0x4015 or value not in (0x0F, 0x1F):
				continue
			cycle = int(row["cpu_cycle"] if fceux else row["absolute_cpu_cycle"])
			if cycle < 8_000_000:
				continue
			item = {"cycle": cycle, "address": address, "value": value}
			if fceux:
				item["source_frame"] = int(row["source_frame"])
			rows.append(item)
	return rows


def format_event(event: dict[str, int]) -> dict[str, int | str]:
	result: dict[str, int | str] = {
		"sequence": event["sequence"],
		"cycle": event["cycle"],
		"address": f"${event['address']:04X}",
		"value": f"${event['value']:02X}",
	}
	if "source_frame" in event:
		result["source_frame"] = event["source_frame"]
	return result


def format_status_write(event: dict[str, int]) -> dict[str, int | str]:
	result: dict[str, int | str] = {
		"cycle": event["cycle"],
		"address": f"${event['address']:04X}",
		"value": f"${event['value']:02X}",
	}
	if "source_frame" in event:
		result["source_frame"] = event["source_frame"]
	return result


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--source-fetches", type=Path, default=DEFAULT_MODEL)
	parser.add_argument("--fceux-trace", type=Path, default=DEFAULT_FCEUX)
	parser.add_argument("--source-apu", type=Path, default=DEFAULT_SOURCE_APU)
	parser.add_argument("--fceux-apu", type=Path, default=DEFAULT_FCEUX_APU)
	parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
	args = parser.parse_args()

	model = load_source_fetches(args.source_fetches)
	fceux = load_fceux_fetches(args.fceux_trace)
	model_pairs = [(row["address"], row["value"]) for row in model]
	fceux_pairs = [(row["address"], row["value"]) for row in fceux]
	common_length = min(len(model_pairs), len(fceux_pairs))
	prefix_length = 0
	while prefix_length < common_length and model_pairs[prefix_length] == fceux_pairs[prefix_length]:
		prefix_length += 1
	first_mismatch = None
	if prefix_length < common_length:
		first_mismatch = {
			"index": prefix_length,
			"source_model": format_event(model[prefix_length]),
			"fceux": format_event(fceux[prefix_length]),
		}

	cycle_offsets = []
	for index in SAMPLE_INDICES:
		if index >= common_length:
			continue
		cycle_offsets.append({
			"index": index,
			"source_model_cycle": model[index]["cycle"],
			"fceux_cycle": fceux[index]["cycle"],
			"fceux_minus_source_model_cycles": fceux[index]["cycle"] - model[index]["cycle"],
			"address_value_equal": model_pairs[index] == fceux_pairs[index],
		})

	def event_context(rows: list[dict[str, int]], index: int) -> list[dict[str, int | str]]:
		return [format_event(row) for row in rows[max(0, index - 3):min(len(rows), index + 4)]]

	model_status = load_apu_status_writes(args.source_apu, fceux=False)
	fceux_status = load_apu_status_writes(args.fceux_apu, fceux=True)
	status_writes = {
		"source_nsf_seed1_first_eight_after_music_start": [format_status_write(row) for row in model_status[:8]],
		"fceux_same_input_first_eight_after_music_start": [format_status_write(row) for row in fceux_status[:8]],
		"note": "These APU writes are validation context only; no FCEUX cycle is used to synthesize audio.",
	}

	result = {
		"purpose": "Post-render ROM/NSF fetch-sequence validation against FCEUX DMC_DMA_OUT events; no PCM is read.",
		"synthesis_inputs_used": False,
		"inputs": {
			"source_fetches": {"path": str(args.source_fetches.relative_to(ROOT)), "sha256": sha256(args.source_fetches), "count": len(model)},
			"fceux_dmc_trace": {"path": str(args.fceux_trace.relative_to(ROOT)), "sha256": sha256(args.fceux_trace), "count": len(fceux), "role": "validation only"},
			"source_apu_writes": {"path": str(args.source_apu.relative_to(ROOT)), "sha256": sha256(args.source_apu)},
			"fceux_apu_writes": {"path": str(args.fceux_apu.relative_to(ROOT)), "sha256": sha256(args.fceux_apu), "role": "validation context only"},
		},
		"sequence": {
			"common_prefix_address_value_matches": prefix_length,
			"first_mismatch": first_mismatch,
			"sampled_cycle_offsets": cycle_offsets,
			"source_model_context_at_first_mismatch": event_context(model, prefix_length) if first_mismatch else [],
			"fceux_context_at_first_mismatch": event_context(fceux, prefix_length) if first_mismatch else [],
			"apu_4015_status_write_context": status_writes,
		},
		"limitations": [
			"FCEUX fetch cycles are used only to validate the source-only candidate; they are not waveform synthesis inputs.",
			"The candidate's per-cycle DMC fetch schedule is simplified and does not execute 6502 instruction-boundary DMA/stall ordering.",
			"This ordered fetch comparison does not prove DMC bit/shift/DAC waveform equality.",
		],
	}
	args.output.parent.mkdir(parents=True, exist_ok=True)
	args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({
		"output": str(args.output.relative_to(ROOT)),
		"source_fetches": len(model),
		"fceux_fetches": len(fceux),
		"common_prefix": prefix_length,
		"first_mismatch": first_mismatch,
	}, indent=2))
	return 0


if __name__ == "__main__":
	raise SystemExit(main())

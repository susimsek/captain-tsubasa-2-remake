#!/usr/bin/env python3
"""Compare FCEUX cartridge APU writes with the original-ROM NSF driver trace."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE_TRACE = ROOT / "reference/diagnostics/audio/rom_driver_apu_trace_20261024"
CANDIDATE_TRACE = ROOT / "reference/diagnostics/audio/rom_driver_apu_trace_cue_offset_plus2_20261024"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def read_csv(path: Path) -> list[dict[str, str]]:
	with path.open(newline="", encoding="ascii") as stream:
		return list(csv.DictReader(stream))


def is_apu_write(row: dict[str, str]) -> bool:
	address = int(row["address"][1:], 16)
	return 0x4000 <= address <= 0x4013 or address in (0x4015, 0x4017)


def pair(row: dict[str, str]) -> tuple[str, str]:
	return row["address"], row["value"]


def find_matching_start(reference: list[dict[str, str]], candidate: list[dict[str, str]]) -> int:
	pattern = [pair(row) for row in reference[:32]]
	matches = [
		index for index in range(len(candidate) - len(pattern) + 1)
		if [pair(row) for row in candidate[index:index + len(pattern)]] == pattern
	]
	if len(matches) != 1:
		raise ValueError(f"Expected a unique 32-write stream alignment, found {len(matches)}")
	return matches[0]


def summarize_trace(fceux_dir: Path, nsf_dir: Path, fceux_first_source_frame: int) -> dict:
	fceux_csv = fceux_dir / "apu_writes.csv"
	frame_csv = fceux_dir / "frame_cycles.csv"
	frames = read_csv(frame_csv)
	fceux_all = [row for row in read_csv(fceux_csv) if is_apu_write(row)]
	fceux = [row for row in fceux_all if int(row["source_frame"]) >= fceux_first_source_frame]
	nsf_meta = json.loads((nsf_dir / "trace_meta.json").read_text(encoding="utf-8"))
	nsf_all = [row for row in read_csv(nsf_dir / "apu_writes.csv") if row["origin"] == "cpu_bus" and is_apu_write(row)]
	start = find_matching_start(fceux, nsf_all)
	nsf = nsf_all[start:start + len(fceux)]
	if len(nsf) != len(fceux):
		raise ValueError("NSF trace does not cover the full FCEUX APU event slice")
	match_count = sum(pair(a) == pair(b) for a, b in zip(fceux, nsf))
	if match_count != len(fceux):
		first = next(i for i, (a, b) in enumerate(zip(fceux, nsf)) if pair(a) != pair(b))
		raise ValueError(f"APU register sequence differs at aligned write {first}: {fceux[first]} vs {nsf[first]}")

	elapsed_frames = [row for row in frames if int(row["cycle_delta"]) > 0]
	fceux_elapsed_cycles = sum(int(row["cycle_delta"]) for row in elapsed_frames)
	nsf_nominal_period = 29_780
	clock_scale = Fraction(fceux_elapsed_cycles, nsf_nominal_period * len(elapsed_frames))
	offsets = [Fraction(int(a["cpu_cycle"])) - clock_scale * int(b["absolute_cpu_cycle"]) for a, b in zip(fceux, nsf)]
	sorted_offsets = sorted(offsets)
	middle = len(sorted_offsets) // 2
	phase = (sorted_offsets[middle - 1] + sorted_offsets[middle]) / 2 if len(sorted_offsets) % 2 == 0 else sorted_offsets[middle]
	residuals = [offset - phase for offset in offsets]
	rms_cycles = math.sqrt(sum(float(value * value) for value in residuals) / len(residuals))
	dmc_fceux = [row for row in fceux if row["address"] in ("$4010", "$4012", "$4013")]
	dmc_nsf = [row for row in nsf if row["address"] in ("$4010", "$4012", "$4013")]
	if len(dmc_fceux) != len(dmc_nsf) or any(pair(a) != pair(b) for a, b in zip(dmc_fceux, dmc_nsf)):
		raise ValueError("DMC register writes differ in value/order")

	stop_rows_f = [row for row in fceux if int(row["source_frame"]) >= 4662]
	stop_rows_n = [row for row in nsf[-len(stop_rows_f):]] if stop_rows_f else []
	# The capture-anchored title-stop is source frame 4661; channel clears first
	# appear in the following source frame. Pairing here uses the already-proven
	# complete sequence alignment, then reports its ending records.
	first_stop_f = next((i for i, row in enumerate(fceux) if int(row["source_frame"]) >= 4662), None)
	first_stop_n = start + first_stop_f if first_stop_f is not None else None
	return {
		"source_fceux_dir": fceux_dir.relative_to(ROOT).as_posix(),
		"source_nsf_trace_dir": nsf_dir.relative_to(ROOT).as_posix(),
		"fceux_trace_sha256": sha256(fceux_csv),
		"fceux_frame_cycles_sha256": sha256(frame_csv),
		"nsf_apu_trace_sha256": nsf_meta["outputs"]["apu_writes_sha256"],
		"source_rom_sha256": nsf_meta["source_rom_sha256"],
		"input_timeline_sha256": json.loads((fceux_dir / "trace_meta.json").read_text(encoding="utf-8"))["input_timeline"]["sha256"],
		"fceux_write_filter": {"addresses": "$4000-$4013, $4015, $4017", "first_source_frame": fceux_first_source_frame, "excluded": ["$4014 OAM DMA", "$4016 controller strobe"]},
		"sequence_alignment": {
			"fceux_apu_writes": len(fceux),
			"nsf_apu_writes": len(nsf),
			"address_value_order_exact": True,
			"aligned_start_index_in_nsf_cpu_write_stream": start,
			"first_fceux_write": {"source_frame": int(fceux[0]["source_frame"]), "cycle": int(fceux[0]["cpu_cycle"]), "pc": fceux[0]["pc"], "address": fceux[0]["address"], "value": fceux[0]["value"]},
			"first_nsf_write": {"cycle": int(nsf[0]["absolute_cpu_cycle"]), "address": nsf[0]["address"], "value": nsf[0]["value"]},
			"last_fceux_write": {"source_frame": int(fceux[-1]["source_frame"]), "cycle": int(fceux[-1]["cpu_cycle"]), "pc": fceux[-1]["pc"], "address": fceux[-1]["address"], "value": fceux[-1]["value"]},
			"last_nsf_write": {"cycle": int(nsf[-1]["absolute_cpu_cycle"]), "address": nsf[-1]["address"], "value": nsf[-1]["value"]},
		},
		"clock_alignment": {
			"basis": "FCEUX's measured sum of positive cycle_delta frame intervals divided by libgme's exact 29,780-cycle NSF PLAY period; one rational scale, then one median phase offset across aligned register writes.",
			"fceux_elapsed_frames": len(elapsed_frames),
			"fceux_elapsed_cycles": fceux_elapsed_cycles,
			"nsf_nominal_cycles_per_frame": nsf_nominal_period,
			"scale_fceux_cycles_per_nsf_cycle": {"numerator": clock_scale.numerator, "denominator": clock_scale.denominator, "decimal": float(clock_scale)},
			"phase_offset_cycles": {"numerator": phase.numerator, "denominator": phase.denominator, "decimal": float(phase)},
			"residual_cycles_after_scale_and_phase": {"min": float(min(residuals)), "max": float(max(residuals)), "rms": rms_cycles, "max_abs_milliseconds_at_ntsc_clock": float(max(abs(value) for value in residuals)) * 1000.0 / 1_789_772.7272727273},
			"raw_first_pair_delta_cycles": int(fceux[0]["cpu_cycle"]) - int(nsf[0]["absolute_cpu_cycle"]),
			"raw_last_pair_delta_cycles": int(fceux[-1]["cpu_cycle"]) - int(nsf[-1]["absolute_cpu_cycle"]),
		},
		"dmc_registers": {
			"exact_order_and_values": True,
			"fceux_count": len(dmc_fceux),
			"nsf_count": len(dmc_nsf),
			"first_fceux": {"source_frame": int(dmc_fceux[0]["source_frame"]), "cycle": int(dmc_fceux[0]["cpu_cycle"]), "pc": dmc_fceux[0]["pc"], "address": dmc_fceux[0]["address"], "value": dmc_fceux[0]["value"]},
			"last_fceux": {"source_frame": int(dmc_fceux[-1]["source_frame"]), "cycle": int(dmc_fceux[-1]["cpu_cycle"]), "pc": dmc_fceux[-1]["pc"], "address": dmc_fceux[-1]["address"], "value": dmc_fceux[-1]["value"]},
			"first_nsf": {"cycle": int(dmc_nsf[0]["absolute_cpu_cycle"]), "address": dmc_nsf[0]["address"], "value": dmc_nsf[0]["value"]},
			"last_nsf": {"cycle": int(dmc_nsf[-1]["absolute_cpu_cycle"]), "address": dmc_nsf[-1]["address"], "value": dmc_nsf[-1]["value"]},
		},
		"title_stop": {
			"rom_event_source_frame": 4661,
			"first_channel_clear_source_frame": int(fceux[first_stop_f]["source_frame"]) if first_stop_f is not None else None,
			"first_fceux_clear": fceux[first_stop_f] if first_stop_f is not None else None,
			"first_nsf_clear": nsf[first_stop_f] if first_stop_f is not None else None,
			"last_fceux_clear": fceux[-1],
			"last_nsf_clear": nsf[-1],
			"ending_address_value_sequence_exact": all(pair(a) == pair(b) for a, b in zip(fceux[first_stop_f:], nsf[first_stop_f:])) if first_stop_f is not None else False,
		},
		"candidate_cue_frame_offset": nsf_meta.get("cue_frame_offset_experiment", {}).get("cue_frame_offset_ticks", 0),
		"runtime_audio_changed": False,
		"pcm_generated_or_used_as_input": False,
	}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--fceux-dir", type=Path, required=True)
	parser.add_argument("--nsf-dir", type=Path, default=CANDIDATE_TRACE)
	parser.add_argument("--first-source-frame", type=int, default=283)
	parser.add_argument("--output", type=Path, default=ROOT / "reference/diagnostics/audio/apu_write_timing_comparison_20261024.json")
	args = parser.parse_args()
	result = summarize_trace(args.fceux_dir.resolve(), args.nsf_dir.resolve(), args.first_source_frame)
	args.output.resolve().write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(args.output.resolve())


if __name__ == "__main__":
	main()

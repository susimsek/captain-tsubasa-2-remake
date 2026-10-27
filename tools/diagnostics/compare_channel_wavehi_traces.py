#!/usr/bin/env python3
"""Compare bounded raw per-channel WaveHi records from FCEUX and ROM renderer."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECORD = struct.Struct("<Q5iI")
CHANNELS = ("pulse1", "pulse2", "triangle", "noise", "dmc", "raw_wavehi")
WLOOKUP1 = [0] * 32
WLOOKUP2 = [0] * 203
for _value in range(1, 32):
	WLOOKUP1[_value] = int(16.0 * 16 * 16 * 4 * 95.52 / (8128.0 / _value + 100))
for _value in range(1, 203):
	WLOOKUP2[_value] = int(16.0 * 16 * 16 * 4 * 163.67 / (24329.0 / _value + 100))


def sha256(path: Path) -> str:
	digest = hashlib.sha256()
	with path.open("rb") as file:
		for chunk in iter(lambda: file.read(1024 * 1024), b""):
			digest.update(chunk)
	return digest.hexdigest()


def records(path: Path):
	with path.open("rb") as file:
		while chunk := file.read(RECORD.size * 65536):
			if len(chunk) % RECORD.size:
				raise ValueError(f"{path} has a partial trace record")
			yield from RECORD.iter_unpack(chunk)


def aggregate() -> dict:
	return {"exact": 0, "max_abs_diff": 0, "sum_abs_diff": 0, "sum_sq_diff": 0,
		"sum_x": 0, "sum_y": 0, "sum_xx": 0, "sum_yy": 0, "sum_xy": 0,
		"first_mismatch_cycle": None}


def summarize(item: dict, count: int) -> dict:
	var_x = count * item["sum_xx"] - item["sum_x"] ** 2
	var_y = count * item["sum_yy"] - item["sum_y"] ** 2
	cov = count * item["sum_xy"] - item["sum_x"] * item["sum_y"]
	denom = math.sqrt(var_x * var_y) if var_x > 0 and var_y > 0 else 0.0
	return {
		"exact_samples": item["exact"],
		"exact_fraction": item["exact"] / count if count else None,
		"max_absolute_difference": item["max_abs_diff"],
		"mean_absolute_difference": item["sum_abs_diff"] / count if count else None,
		"rmse": math.sqrt(item["sum_sq_diff"] / count) if count else None,
		"correlation": cov / denom if denom else None,
		"first_mismatch_cycle": item["first_mismatch_cycle"],
	}


def mixer(raw: int) -> int:
	return (raw & 0xffff) + WLOOKUP2[(raw >> 16) & 0xff] + WLOOKUP1[(raw >> 24) & 0xff]


def apply_channel_volumes(values: list[int], volumes: tuple[int, int, int, int, int]) -> list[int]:
	"""Apply FCEUX's integer per-channel gain before WaveHi accumulation."""
	result = []
	for index, (raw, volume) in enumerate(zip(values, volumes)):
		unsigned = raw & 0xffffffff
		if index < 2:
			level = (unsigned >> 24) & 0xff
			result.append(((level * volume) // 256) << 24)
		elif index == 2:
			level = (unsigned >> 16) & 0xff
			result.append(((level * volume) // 256) << 16)
		elif index == 3:
			level = (unsigned >> 16) & 0xffff
			if level & 1:
				raise ValueError("source noise contribution is not an even envelope level")
			result.append((((level // 2 * volume) // 256) * 2) << 16)
		else:
			level = (unsigned >> 16) & 0xffff
			result.append(((level * volume) // 256) << 16)
	return result


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--fceux-trace", type=Path, required=True)
	parser.add_argument("--source-trace", type=Path, required=True)
	parser.add_argument("--output", type=Path, required=True)
	parser.add_argument("--source-channel-volumes", default="256,256,256,256,256",
		help="optional FCEUX channel gains for candidate normalization: pulse1,pulse2,triangle,noise,DMC (0..256); use only when matching a documented config")
	args = parser.parse_args()
	try:
		volumes = tuple(int(value) for value in args.source_channel_volumes.split(","))
	except ValueError as exc:
		parser.error(f"invalid --source-channel-volumes: {exc}")
	if len(volumes) != 5 or any(value < 0 or value > 256 for value in volumes):
		parser.error("--source-channel-volumes must contain five integers in the range 0..256")
	fceux_path = args.fceux_trace.resolve()
	source_path = args.source_trace.resolve()
	if fceux_path.stat().st_size % RECORD.size or source_path.stat().st_size % RECORD.size:
		raise ValueError("a trace file contains a partial fixed-width record")
	if fceux_path.stat().st_size != source_path.stat().st_size:
		raise ValueError(f"trace sizes differ: FCEUX={fceux_path.stat().st_size}, source={source_path.stat().st_size}")
	count = fceux_path.stat().st_size // RECORD.size
	stats = {name: aggregate() for name in CHANNELS}
	channel_sum_mismatch_counts = {"fceux": 0, "source": 0}
	cycle_start = None
	cycle_end_exclusive = None
	for fceux_row, source_row in zip(records(fceux_path), records(source_path)):
		f_cycle, *f_values = fceux_row
		s_cycle, *s_values = source_row
		if f_cycle != s_cycle:
			raise ValueError(f"cycle misalignment: FCEUX={f_cycle}, source={s_cycle}")
		if cycle_start is None:
			cycle_start = f_cycle
		elif f_cycle != cycle_end_exclusive:
			raise ValueError(f"non-contiguous trace at expected cycle {cycle_end_exclusive}, got {f_cycle}")
		cycle_end_exclusive = f_cycle + 1
		f_channels = f_values[:5]
		s_channels = apply_channel_volumes(s_values[:5], volumes)
		f_raw = f_values[5] & 0xffffffff
		s_raw = sum(s_channels) & 0xffffffff
		if (sum(f_channels) & 0xffffffff) != f_raw:
			channel_sum_mismatch_counts["fceux"] += 1
		if (sum(s_channels) & 0xffffffff) != s_raw:
			channel_sum_mismatch_counts["source"] += 1
		f_values = [*f_channels, f_raw, mixer(f_raw)]
		s_values = [*s_channels, s_raw, mixer(s_raw)]
		for name, x, y in zip((*CHANNELS, "mixed_wavehi"), f_values, s_values):
			if name not in stats:
				stats[name] = aggregate()
			item = stats[name]
			diff = abs(x - y)
			item["exact"] += x == y
			item["max_abs_diff"] = max(item["max_abs_diff"], diff)
			item["sum_abs_diff"] += diff
			item["sum_sq_diff"] += diff * diff
			item["sum_x"] += x
			item["sum_y"] += y
			item["sum_xx"] += x * x
			item["sum_yy"] += y * y
			item["sum_xy"] += x * y
			if x != y and item["first_mismatch_cycle"] is None:
				item["first_mismatch_cycle"] = f_cycle
		if f_cycle + 1 != cycle_end_exclusive:
			raise AssertionError("trace cycle cursor failed to advance")
	result = {
		"purpose": "Validation-only raw channel contribution comparison before nonlinear mixing and filtering; FCEUX values are not synthesis inputs.",
		"source_channel_volume_normalization": {
			"values_pulse1_pulse2_triangle_noise_dmc": list(volumes),
			"formula": "FCEUX integer gain per channel before packing; pulse/noise envelope amp and DMC DAC use floor(level*volume/256); triangle's existing WaveHi formula is equivalent to floor(level*volume/256)",
			"basis": "explicitly supplied renderer option; does not alter source trace files",
		},
		"cycle_window_inclusive_start_exclusive_end": [cycle_start, cycle_end_exclusive],
		"rows": count,
		"record_bytes": RECORD.size,
		"channel_sum_matches_raw_wavehi_rows": channel_sum_mismatch_counts,
		"input_files": {
			"fceux": {"path": fceux_path.relative_to(ROOT).as_posix(), "sha256": sha256(fceux_path), "bytes": fceux_path.stat().st_size},
			"rom_only_source": {"path": source_path.relative_to(ROOT).as_posix(), "sha256": sha256(source_path), "bytes": source_path.stat().st_size},
		},
		"metrics": {name: summarize(item, count) for name, item in stats.items()},
		"interpretation": {
			"channel_contributions": "pulse, triangle, noise, and DMC component agreement is checked before nonlinear mixing and filtering",
			"mixed_wavehi": "recomputed from each trace's raw packed WaveHi with the pinned FCEUX nonlinear mixer lookup equations",
			"limits": "Differences identify the earliest diverging layer in this captured input; they do not establish physical NES silicon parity or runtime-audio identity.",
		},
	}
	output = args.output.resolve()
	output.parent.mkdir(parents=True, exist_ok=True)
	output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({"output": str(output), "rows": count, "cycle_window": result["cycle_window_inclusive_start_exclusive_end"]}, indent=2))


if __name__ == "__main__":
	main()

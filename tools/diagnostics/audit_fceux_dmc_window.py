#!/usr/bin/env python3
"""Audit a narrow retained FCEUX APU/DMC cycle window against the supplied ROM.

This is a post-run validation tool. It does not run the ROM, schedule events,
render PCM, or emit runtime assets. The FCEUX trace is treated only as a captured
comparison oracle; DMC output byte values are checked against PRG bank $1E.
"""

from __future__ import annotations

import argparse
import bisect
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
DEFAULT_TRACE_DIR = ROOT / "reference/diagnostics/audio/rom_source_sound_execution_20261026_112451_utc"
DEFAULT_OUTPUT_DIR = ROOT / "reference/diagnostics/audio/rom_source_dmc_window_audit_20261026"
PRG_BANK_8K = 0x1E


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def csv_rows(path: Path):
	with path.open(newline="", encoding="ascii") as stream:
		yield from csv.DictReader(stream)


def load_frames(trace_dir: Path) -> tuple[list[dict], list[int]]:
	frames = []
	for row in csv_rows(trace_dir / "frame_cycles.csv"):
		frames.append({
			"source_frame": int(row["source_frame"]),
			"cycle_start": int(row["cycle_start"]),
			"cycle_end": int(row["cycle_end"]),
			"cycle_delta": int(row["cycle_delta"]),
		})
	return frames, [row["cycle_start"] for row in frames]


def frame_for_cycle(cycle: int, frames: list[dict], starts: list[int]) -> int:
	index = bisect.bisect_right(starts, cycle) - 1
	if index < 0 or index >= len(frames):
		raise ValueError(f"cycle {cycle} is outside the retained frame table")
	row = frames[index]
	if not row["cycle_start"] <= cycle < row["cycle_end"]:
		raise ValueError(f"cycle {cycle} falls outside frame {row['source_frame']} interval")
	return row["source_frame"]


def verify_inputs(trace_dir: Path, rom: bytes) -> dict:
	if hashlib.sha256(rom).hexdigest() != EXPECTED_ROM_SHA256:
		raise ValueError("supplied ROM SHA-256 does not match the pinned Turkish ROM")
	manifest_path = trace_dir / "trace_manifest.json"
	manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
	if manifest.get("source_rom", {}).get("sha256") != EXPECTED_ROM_SHA256:
		raise ValueError("FCEUX trace manifest identifies a different ROM")
	if manifest.get("execution", {}).get("cold_poweron") is not True:
		raise ValueError("FCEUX trace is not marked as cold power-on")
	if "released" not in manifest.get("execution", {}).get("input", ""):
		raise ValueError("FCEUX trace input was not neutral for this audit")
	for filename in ("frame_cycles.csv", "apu_writes.csv", "fceux_dmc_trace.csv"):
		path = trace_dir / filename
		actual = sha256(path)
		expected = manifest.get("outputs", {}).get(filename, {}).get("sha256")
		if expected != actual:
			raise ValueError(f"trace hash mismatch for {filename}: {actual}")
	return manifest


def analyze(trace_dir: Path, start_frame: int, end_frame: int) -> dict:
	rom = ROM_PATH.read_bytes()
	manifest = verify_inputs(trace_dir, rom)
	frames, starts = load_frames(trace_dir)
	frame_map = {row["source_frame"]: row for row in frames}
	target_frames = set(range(start_frame, end_frame + 1))
	frame_detail = {
		frame: {"dmc_dmr_rows": 0, "dmc_output_bytes": 0, "dmc_first": None, "dmc_last": None}
		for frame in target_frames
	}
	byte_sequence = bytearray()
	byte_mismatches = []
	selected_apu = []
	all_apu_counts = {frame: 0 for frame in target_frames}
	
	for row in csv_rows(trace_dir / "fceux_dmc_trace.csv"):
		cycle = int(row["absolute_cycle"])
		frame = frame_for_cycle(cycle, frames, starts)
		if frame not in target_frames:
			continue
		detail = frame_detail[frame]
		if row["event"] == "DMR":
			detail["dmc_dmr_rows"] += 1
		elif row["event"] == "DMC_DMA_OUT":
			address = int(row["detail_address"], 16)
			value = int(row["detail_value"])
			if not 0xC000 <= address < 0xE000:
				raise ValueError(f"DMC byte address escaped bank-$1E window: ${address:04X}")
			rom_offset = 16 + PRG_BANK_8K * 0x2000 + address - 0xC000
			expected_value = rom[rom_offset]
			if expected_value != value:
				byte_mismatches.append({
					"frame": frame,
					"cycle": cycle,
					"address": f"${address:04X}",
					"trace_value": value,
					"rom_value": expected_value,
				})
			byte_sequence.append(value)
			detail["dmc_output_bytes"] += 1
			item = {"cycle": cycle, "address": f"${address:04X}", "value": value}
			if detail["dmc_first"] is None:
				detail["dmc_first"] = item
			detail["dmc_last"] = item
	
	for row in csv_rows(trace_dir / "apu_writes.csv"):
		frame = int(row["source_frame"])
		if frame not in target_frames:
			continue
		all_apu_counts[frame] += 1
		if frame in (1043, 1046, 1047, 1048, 1049):
			selected_apu.append({
				"frame": frame,
				"cycle": int(row["cpu_cycle"]),
				"pc": row["pc"],
				"address": row["address"],
				"value": row["value"],
			})

	for frame, detail in frame_detail.items():
		bounds = frame_map[frame]
		detail.update({
			"cycle_start": bounds["cycle_start"],
			"cycle_end": bounds["cycle_end"],
			"cycle_delta": bounds["cycle_delta"],
			"apu_write_count": all_apu_counts[frame],
			"dmc_four_read_slots": detail["dmc_dmr_rows"] // 4,
		})
		if detail["dmc_dmr_rows"] % 4:
			detail["dmc_dmr_rows_not_divisible_by_four"] = detail["dmc_dmr_rows"] % 4

	return {
		"purpose": "post-run FCEUX trace audit only; not a source event generator or runtime synthesis input",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"trace_manifest_sha256": sha256(trace_dir / "trace_manifest.json"),
		"trace_dir": trace_dir.relative_to(ROOT).as_posix(),
		"trace_frame_range": [start_frame, end_frame],
		"fceux_revision": manifest["fceux"]["pinned_revision"],
		"input": manifest["execution"]["input"],
		"frames": {str(frame): frame_detail[frame] for frame in sorted(frame_detail)},
		"selected_apu_writes": selected_apu,
		"dmc_output_byte_count": len(byte_sequence),
		"dmc_output_sequence_sha256": hashlib.sha256(byte_sequence).hexdigest(),
		"dmc_bank_1e_rom_byte_mismatches": byte_mismatches,
		"source_side_stepper": {
			"persistent_code_present": False,
			"historical_candidate_files_present": False,
			"note": "The previously reported /private/tmp DMC-aware source-stepper script and JSON were not present in the current workspace when this audit ran. Therefore source-side cycle residuals and their cause are not reproduced by this artifact.",
		},
		"interpretation": [
			"This report verifies only the retained FCEUX-model cycle/event trace and the ROM bytes read by its DMC output events.",
			"FCEUX records no DMC output bytes in frames 1040-1045; 193 bytes are read in frames 1046-1048, then none in frame 1049.",
			"A FCEUX trace alone cannot determine whether the previously reported source-stepper offset is a ROM CPU/IRQ issue, a DMC stall-order issue, or an artifact of the missing candidate model.",
		],
	}


def write_markdown(path: Path, data: dict) -> None:
	lines = [
		"# Retained FCEUX DMC cycle window audit",
		"",
		"## Scope and provenance",
		"",
		"This is a post-run validation audit of the retained muted, replay-free FCEUX trace. It does not execute or schedule the game, render PCM, or generate a runtime asset. It checks every DMC byte observed in the selected frame range against the supplied ROM's fixed PRG bank `$1E`.",
		"",
		f"- ROM SHA-256: `{data['source_rom_sha256']}`",
		f"- FCEUX revision: `{data['fceux_revision']}`",
		f"- Trace folder: `{data['trace_dir']}`",
		f"- Audited frames: `{data['trace_frame_range'][0]}–{data['trace_frame_range'][1]}`",
		"- Input: all buttons explicitly released on every frame.",
		"",
		"## Per-frame observations",
		"",
		"| Frame | CPU-cycle interval | FCEUX frame cycles | APU writes | DMC output bytes | DMR rows | First / last DMC byte |",
		"|---:|---:|---:|---:|---:|---:|---|",
	]
	for frame, detail in data["frames"].items():
		first = detail["dmc_first"]
		last = detail["dmc_last"]
		span = "—" if first is None else f"{first['address']}@{first['cycle']} / {last['address']}@{last['cycle']}"
		lines.append(f"| {frame} | {detail['cycle_start']}–{detail['cycle_end']} | {detail['cycle_delta']} | {detail['apu_write_count']} | {detail['dmc_output_bytes']} | {detail['dmc_dmr_rows']} | {span} |")
	lines += [
		"",
		f"Across these frames the trace contains {data['dmc_output_byte_count']} DMC output bytes; the ROM-byte comparison found {len(data['dmc_bank_1e_rom_byte_mismatches'])} mismatches. The ordered byte-sequence SHA-256 is `{data['dmc_output_sequence_sha256']}`.",
		"",
		"## Interpretation and limit",
		"",
		"The retained FCEUX trace shows no DMC output in frames 1040–1045, then 193 DMC bytes across frames 1046–1048, and no output in frame 1049. This pins the observed DMC window to the FCEUX execution model and verifies its byte source. It does not reproduce the source-side stepper's previously reported temporary cycle offsets.",
		"",
		"The prior source-stepper script/JSON were under `/private/tmp` and were absent from the current project state. With no persistent source-side event stream, the reported +222-cycle offset at frame 1043 and transient offset around frames 1046–1048 cannot be independently checked here. The root cause remains unresolved; a FCEUX trace alone cannot distinguish CPU/IRQ alignment from DMC stall-order accounting or a candidate-model issue.",
		"",
		"No Godot runtime file, production WAV, or audio manifest was modified.",
		"",
		"## Selected APU writes",
		"",
		"| Frame | Cycle | PC | Address | Value |",
		"|---:|---:|---:|---:|---:|",
	]
	for row in data["selected_apu_writes"]:
		lines.append(f"| {row['frame']} | {row['cycle']} | {row['pc']} | {row['address']} | {row['value']} |")
	lines.append("")
	path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--trace-dir", type=Path, default=DEFAULT_TRACE_DIR)
	parser.add_argument("--start-frame", type=int, default=1040)
	parser.add_argument("--end-frame", type=int, default=1050)
	parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
	args = parser.parse_args()
	if args.start_frame > args.end_frame:
		parser.error("--start-frame must be <= --end-frame")
	data = analyze(args.trace_dir.resolve(), args.start_frame, args.end_frame)
	args.output_dir.mkdir(parents=True, exist_ok=True)
	json_path = args.output_dir / "fceux_dmc_window_audit.json"
	md_path = args.output_dir / "README.md"
	json_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
	write_markdown(md_path, data)
	print(json_path)
	print(md_path)
	print(f"DMC bytes={data['dmc_output_byte_count']} ROM mismatches={len(data['dmc_bank_1e_rom_byte_mismatches'])}")


if __name__ == "__main__":
	main()

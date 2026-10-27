#!/usr/bin/env python3
"""Merge compact FCEUX DMC and PCM-sync events from cycle-windowed replays."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SEGMENTS = [
	ROOT / "reference/diagnostics/audio/fceux_dmc_pcm_sync_20261025_seg1/dmc_hook_trace.csv",
	ROOT / "reference/diagnostics/audio/fceux_dmc_pcm_sync_20261025_seg2/dmc_hook_trace.csv",
	ROOT / "reference/diagnostics/audio/fceux_dmc_pcm_sync_20261025_seg3/dmc_hook_trace.csv",
]
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/audio/fceux_dmc_hook_trace_pcm_sync_sequence_ordered_merged_20261025"
DEFAULT_FRAME_SOURCE = ROOT / "reference/diagnostics/audio/fceux_dmc_hook_trace_20261025_050301_utc/dmc_hook_trace.csv"
KEEP_EVENTS = {"DMC_DMA_OUT", "DMC_BIT_OUT", "PCM_SYNC_IN"}
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def merge(paths: list[Path], frame_source: Path, output_dir: Path) -> dict:
	rom_path = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
	rom = rom_path.read_bytes()
	rom_sha = hashlib.sha256(rom).hexdigest()
	if rom_sha != EXPECTED_ROM_SHA256:
		raise ValueError(f"supplied ROM hash changed: {rom_sha}")
	prg_start = 16 + (512 if rom[6] & 0x04 else 0)
	bank_1e = rom[prg_start + 0x1E * 0x2000:prg_start + 0x1F * 0x2000]
	if len(bank_1e) != 0x2000:
		raise ValueError("supplied ROM has no complete physical PRG bank $1E")

	merged: list[tuple[int, int, int, list[str]]] = []
	segment_reports = []
	header: list[str] | None = None
	for segment_index, path in enumerate(paths):
		path = path.resolve()
		counts: Counter[str] = Counter()
		invalid_rows = 0
		with path.open(newline="", encoding="utf-8") as stream:
			reader = csv.reader(stream)
			current_header = next(reader)
			if header is None:
				header = current_header
			elif current_header != header:
				raise ValueError(f"trace header mismatch: {path}")
			for row in reader:
				if len(row) != len(header):
					invalid_rows += 1
					continue
				event = row[1]
				if event not in KEEP_EVENTS:
					continue
				cycle = int(row[5])
				original_sequence = int(row[0])
				if event == "DMC_DMA_OUT":
					address = int(row[24], 16)
					value = int(row[25])
					if not 0xC000 <= address < 0xE000:
						raise ValueError(f"DMC fetch outside observed bank window: {address:#06x}")
					if bank_1e[address - 0xC000] != value:
						raise ValueError(f"DMC fetched byte does not match ROM bank $1E at {address:#06x}")
					counts["ROM-byte-verified-fetches"] += 1
				counts[event] += 1
				merged.append((cycle, segment_index, original_sequence, row))
		segment_reports.append({
			"path": path.relative_to(ROOT).as_posix(),
			"sha256": sha256(path),
			"counts": dict(counts),
			"incomplete_rows_ignored": invalid_rows,
		})

	frame_source = frame_source.resolve()
	frame_updates = 0
	with frame_source.open(newline="", encoding="utf-8") as stream:
		reader = csv.reader(stream)
		frame_header = next(reader)
		if header is not None and frame_header != header:
			raise ValueError(f"frame-event trace header mismatch: {frame_source}")
		for row in reader:
			if len(row) != len(frame_header):
				continue
			if row[1] != "FRAME_UPDATE_IN":
				continue
			merged.append((int(row[5]), -1, int(row[0]), row))
			frame_updates += 1

	if header is None or not merged:
		raise ValueError("no compact DMC events found")
	priority = {"FRAME_UPDATE_IN": 0}
	merged.sort(key=lambda item: (item[0], priority.get(item[3][1], 1), item[1], item[2]))
	output_dir.mkdir(parents=True, exist_ok=False)
	trace_path = output_dir / "dmc_hook_trace.csv"
	with trace_path.open("w", newline="", encoding="utf-8") as stream:
		writer = csv.writer(stream, lineterminator="\n")
		writer.writerow(header)
		for sequence, (_, _, _, row) in enumerate(merged):
			row[0] = str(sequence)
			writer.writerow(row)

	meta = {
		"purpose": "Compact DMC byte-fetch, bit-state, and PCM-sync events merged from same-input FCEUX 2.7.0 replays. Captured PCM is not used as renderer input.",
		"source_rom": {"path": rom_path.relative_to(ROOT).as_posix(), "sha256": rom_sha},
		"fceux_pinned_revision": "a6d03e7968bd77a8156a7c9b628a673753f2f4c6",
		"input_timeline": {"path": "reference/opening_reference_capture/input_timeline.csv", "sha256": sha256(ROOT / "reference/opening_reference_capture/input_timeline.csv"), "frames": 4693},
		"cycle_domain": "absolute FCEUX CPU cycles = timestampbase + timestamp; counter reset to zero immediately after emu.poweron",
		"included_events": sorted(KEEP_EVENTS | {"FRAME_UPDATE_IN"}),
		"included_frame_updates": {"path": frame_source.relative_to(ROOT).as_posix(), "sha256": sha256(frame_source), "count": frame_updates},
		"fetch_validation": "Every DMC_DMA_OUT address/value pair was compared with physical PRG bank $1E bytes in the supplied ROM.",
		"segments": segment_reports,
		"merged_trace": {"path": trace_path.name, "sha256": sha256(trace_path), "rows": len(merged), "bytes": trace_path.stat().st_size},
		"limitations": [
			"This is a trace of the pinned FCEUX model, not physical NES hardware.",
			"The final replay segment exited with signal 11 during FCEUX shutdown after its Lua capture reported all 4693 frames complete. One incomplete non-DMC row at the end was discarded; the last DMC fetch/bit event precedes it by more than one million CPU cycles.",
			"The merged trace is diagnostic reference data; the Godot runtime must still derive behavior from ROM bytes and its own implementation.",
		],
	}
	(output_dir / "trace_meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
	return meta


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--segments", nargs="+", type=Path, default=DEFAULT_SEGMENTS)
	parser.add_argument("--frame-source", type=Path, default=DEFAULT_FRAME_SOURCE)
	parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
	args = parser.parse_args()
	metadata = merge(args.segments, args.frame_source, args.output_dir.resolve())
	print(metadata["merged_trace"]["path"])


if __name__ == "__main__":
	main()

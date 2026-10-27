#!/usr/bin/env python3
"""Render a diagnostic CHR-bank fetch-cutoff candidate for three intro frames.

This is an offline hypothesis check. It shifts only the scanline-134 MMC3 R0/R1
select/data pairs to a predicted visible output boundary after the first full
post-write background pattern-plane pair. It does not alter production code.
"""

from __future__ import annotations

import argparse
import csv
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))


def load_module(name: str, path: Path):
	got = importlib.util.spec_from_file_location(name, path)
	if got is None or got.loader is None:
		raise RuntimeError(f"Cannot import {path}")
	module = importlib.util.module_from_spec(got)
	sys.modules[name] = module
	got.loader.exec_module(module)
	return module


# Candidate cutoff x values. Each is a hypothesis based on the pinned FCEUX
# BGData::Read plane schedule and two-tile-ahead output. We switch only once a
# complete low/high pair is fetched after the mapper write.
CUTOFFS = {
	380: {0: 160, 1: 208},
	382: {0: 176, 1: 232},
	394: {0: 160, 1: 216},
}


def shift_bank_pair(rows: list[dict[str, str]], frame: int, reg: int,
					cutoff_x: int) -> None:
	"""Move one 8000/8001 register pair together to its modeled pixel edge."""
	select_value = f"${reg:02X}"
	data_value = "$00" if reg == 0 else "$02"
	select_row = None
	for row in rows:
		if int(row["ppu_scanline"]) != 134:
			continue
		address = int(row["address"].removeprefix("$"), 16)
		if address == 0x8000 and row["value"] == select_value:
			select_row = row
		elif address == 0x8001 and row["value"] == data_value and select_row is not None:
			# The display loop applies an event when ppu_dot <= x + 1. Advancing
			# the pair to x+1 makes it take effect at the candidate cutoff pixel.
			modeled_dot = cutoff_x + 1
			select_row["ppu_dot"] = str(modeled_dot)
			row["ppu_dot"] = str(modeled_dot)
			return
		elif address == 0x8000:
			select_row = None
	raise ValueError(f"Frame {frame} missing scanline-134 MMC3 R{reg} pair")


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--rom", type=Path, required=True)
	parser.add_argument("--capture-dir", type=Path, required=True)
	parser.add_argument("--palette-file", type=Path, required=True)
	parser.add_argument("--screens-dir", type=Path, required=True)
	parser.add_argument("--output-dir", type=Path, required=True)
	parser.add_argument("--baseline-csv", type=Path, required=True)
	args = parser.parse_args()
	for key in ("rom", "capture_dir", "palette_file", "screens_dir", "output_dir", "baseline_csv"):
		value = getattr(args, key)
		if not value.is_absolute():
			setattr(args, key, ROOT / value)

	poc = load_module("loopy_frame_poc_candidate", ROOT / "tools/diagnostics/render_loopy_event_frame_poc.py")
	compare = load_module("intro_compare_candidate", ROOT / "tools/compare_rom_intro_frames.py")
	frames, source_events = poc.load_capture(args.capture_dir)
	chr_rom, _, _ = poc.extract_chr(args.rom)
	rom_sha256 = __import__("hashlib").sha256(args.rom.read_bytes()).hexdigest()
	palette = poc.read_palette_file(args.palette_file)
	baseline = {
		int(row["frame"]): float(row["exact_rgb_fraction"])
		for row in csv.DictReader(args.baseline_csv.open(newline="", encoding="utf-8"))
	}
	args.output_dir.mkdir(parents=True, exist_ok=True)
	results = []
	for frame, cutoffs in CUTOFFS.items():
		# POC mutates register state only while rendering, so isolate the rows per frame.
		events = {key: [dict(row) for row in value] for key, value in source_events.items()}
		for reg, cutoff_x in cutoffs.items():
			shift_bank_pair(events[frame], frame, reg, cutoff_x)
		meta = poc.render_frame(frame, args.capture_dir, frames, events, chr_rom,
							palette, args.output_dir, rom_sha256)
		png = Path(meta["output"])
		candidate_rgb = compare.png_rgb(png)
		reference_rgb = compare.gd_rgb(args.screens_dir / f"frame_{frame:06d}.gd")
		exact, foreground, union, compared, ignored = compare.compare(candidate_rgb, reference_rgb)
		results.append({
			"frame": frame,
			"cutoffs_x_hypothesis": {str(k): v for k, v in cutoffs.items()},
			"cutoff_rule": "first complete post-write BG low/high fetch pair; visible output x = low-plane fetch dot + 12 (hypothesis)",
			"exact_rgb_fraction": exact,
			"baseline_exact_rgb_fraction": baseline[frame],
			"delta_vs_baseline": exact - baseline[frame],
			"foreground_union_exact_fraction": foreground,
			"foreground_union_pixels": union,
			"compared_pixels": compared,
			"ignored_pixels": ignored,
			"candidate_png": str(png.relative_to(ROOT)),
		})
		print(f"frame={frame} exact={exact:.8f} baseline={baseline[frame]:.8f} delta={exact-baseline[frame]:+.8f}", flush=True)
	(args.output_dir / "candidate_metrics.json").write_text(json.dumps({
		"status": "diagnostic-only hypothesis; no runtime use",
		"model": "shift MMC3 R0/R1 select/data pairs to first complete post-write background low/high pattern fetch pair; output cutoff at low-fetch dot +12",
		"cutoff_hypotheses": CUTOFFS,
		"frames": results,
	}, indent=2) + "\n", encoding="utf-8")
	with (args.output_dir / "candidate_metrics.csv").open("w", newline="", encoding="utf-8") as stream:
		writer = csv.DictWriter(stream, fieldnames=list(results[0]))
		writer.writeheader()
		writer.writerows(results)


if __name__ == "__main__":
	main()

#!/usr/bin/env python3
"""Compare a full Godot opening capture with indexed FCEUX screens.

The FCEUX Power-on OSD mask is frame-specific and applies only to source
frames 1–180. Emulator screen data remains validation-only.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from compare_rom_intro_frames import HEIGHT, WIDTH, compare, gd_rgb, png_rgb


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_INDEX = PROJECT_ROOT / "reference/opening_full_frame_capture_20261025_101014/screen_index.csv"
VISIBLE_CROP_IGNORES = [(0, 0, WIDTH, 8), (0, 232, WIDTH, 8)]


def _reference_map(index_path: Path) -> dict[int, Path]:
	with index_path.open(newline="", encoding="utf-8") as stream:
		reader = csv.DictReader(stream)
		if not reader.fieldnames or not {"source_frame", "raw_screen_file"}.issubset(reader.fieldnames):
			raise ValueError(f"Invalid FCEUX screen index: {index_path}")
		result: dict[int, Path] = {}
		for row in reader:
			frame = int(row["source_frame"])
			name = row["raw_screen_file"]
			path = index_path.parent / name
			if not path.is_file():
				path = index_path.parent / "unique_screens" / name
			result[frame] = path
	if sorted(result) != list(range(4693)):
		raise ValueError("FCEUX index must cover source frames 0–4692 exactly")
	return result


def _write_metrics(path: Path, rows: list[tuple[int, float, float, int, int, int]]) -> None:
	with path.open("w", newline="", encoding="utf-8") as stream:
		writer = csv.writer(stream)
		writer.writerow(["frame", "exact_rgb_fraction", "foreground_union_exact_fraction",
			"foreground_union_pixels", "compared_pixels", "ignored_pixels"])
		writer.writerows(rows)


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--render-dir", type=Path, required=True)
	parser.add_argument("--screen-index", type=Path, default=DEFAULT_INDEX)
	parser.add_argument("--output-dir", type=Path, required=True)
	args = parser.parse_args()
	if not args.render_dir.is_absolute():
		args.render_dir = PROJECT_ROOT / args.render_dir
	if not args.screen_index.is_absolute():
		args.screen_index = PROJECT_ROOT / args.screen_index
	if not args.output_dir.is_absolute():
		args.output_dir = PROJECT_ROOT / args.output_dir
	args.output_dir.mkdir(parents=True, exist_ok=True)

	references = _reference_map(args.screen_index)
	variants: dict[str, list[tuple[int, float, float, int, int, int]]] = {
		"all_frame_metrics.csv": [],
		"visible_metrics.csv": [],
		"all_frame_metrics_osd_masked.csv": [],
		"visible_metrics_osd_masked.csv": [],
	}
	for frame in range(4693):
		candidate_path = args.render_dir / f"frame_{frame:06d}.png"
		if not candidate_path.is_file():
			raise FileNotFoundError(f"Missing Godot frame {frame}: {candidate_path}")
		candidate = png_rgb(candidate_path)
		reference_path = references[frame]
		if not reference_path.is_file():
			raise FileNotFoundError(f"Missing FCEUX reference for frame {frame}: {reference_path}")
		reference = gd_rgb(reference_path)
		variants["all_frame_metrics.csv"].append((frame, *compare(candidate, reference)))
		variants["visible_metrics.csv"].append((frame, *compare(
			candidate, reference, VISIBLE_CROP_IGNORES)))
		osd_ignores: list[tuple[int, int, int, int]] = []
		if 1 <= frame <= 8:
			osd_ignores = [(1, 211, 47, 11)]
		elif 9 <= frame <= 180:
			osd_ignores = [(2, 212, 45, 9)]
		variants["all_frame_metrics_osd_masked.csv"].append((frame, *compare(
			candidate, reference, osd_ignores)))
		variants["visible_metrics_osd_masked.csv"].append((frame, *compare(
			candidate, reference, VISIBLE_CROP_IGNORES + osd_ignores)))

	for name, rows in variants.items():
		_write_metrics(args.output_dir / name, rows)

	def summary(rows: list[tuple[int, float, float, int, int, int]]) -> dict[str, float | int]:
		return {
			"frames": len(rows),
			"mean_exact_rgb_fraction": sum(row[1] for row in rows) / len(rows),
			"mean_foreground_union_exact_fraction": sum(row[2] for row in rows) / len(rows),
			"fully_exact_frames": sum(row[1] == 1.0 for row in rows),
		}

	mask_summary = {
		"fceux_osd_mask": "frames 1-8: x=1,y=211,w=47,h=11; frames 9-180: x=2,y=212,w=45,h=9",
		"non_osd_residuals_frames_1_180": sum(
			row[1] < 1.0 for row in variants["all_frame_metrics_osd_masked.csv"][1:181]),
		"raw": summary(variants["all_frame_metrics_osd_masked.csv"]),
		"visible": summary(variants["visible_metrics_osd_masked.csv"]),
	}
	(args.output_dir / "osd_masked_summary.json").write_text(
		json.dumps(mask_summary, indent=2) + "\n", encoding="utf-8")
	print(json.dumps(mask_summary, indent=2))
	return 0


if __name__ == "__main__":
	raise SystemExit(main())

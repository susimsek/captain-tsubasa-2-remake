#!/usr/bin/env python3
"""Compare the four current F8 helper-return frames with same-input FCEUX screens."""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "tools"))
from compare_rom_intro_frames import compare, gd_rgb, png_rgb  # noqa: E402

FIRST_FRAME = 3966
LAST_FRAME = 3969
VISIBLE_224_IGNORES = [(0, 0, 256, 8), (0, 232, 256, 8)]


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument(
		"--render-dir", type=Path,
		default=PROJECT_ROOT / "reference/diagnostics/f8_helper_return_source_event_20261026",
	)
	parser.add_argument(
		"--screen-index", type=Path,
		default=PROJECT_ROOT / "reference/opening_full_frame_capture_20261025_101014/screen_index.csv",
	)
	parser.add_argument(
		"--output", type=Path,
		default=PROJECT_ROOT / "reference/diagnostics/f8_helper_return_source_event_20261026/fceux_visible_metrics.csv",
	)
	args = parser.parse_args()

	frame_to_path: dict[int, Path] = {}
	with args.screen_index.open(newline="", encoding="utf-8") as stream:
		for row in csv.DictReader(stream):
			frame = int(row["source_frame"])
			if FIRST_FRAME <= frame <= LAST_FRAME:
				path = args.screen_index.parent / row["raw_screen_file"]
				if not path.is_file():
					path = args.screen_index.parent / "unique_screens" / row["raw_screen_file"]
				if not path.is_file():
					raise FileNotFoundError(path)
				frame_to_path[frame] = path

	rows: list[tuple[int, float, float, int, int, int]] = []
	for frame in range(FIRST_FRAME, LAST_FRAME + 1):
		if frame not in frame_to_path:
			raise ValueError(f"FCEUX screen index is missing source frame {frame}")
		render = args.render_dir / f"frame_{frame:06d}.png"
		if not render.is_file():
			raise FileNotFoundError(render)
		rows.append((frame, *compare(
			png_rgb(render), gd_rgb(frame_to_path[frame]), VISIBLE_224_IGNORES
		)))

	args.output.parent.mkdir(parents=True, exist_ok=True)
	with args.output.open("w", newline="", encoding="utf-8") as stream:
		writer = csv.writer(stream)
		writer.writerow([
			"frame", "exact_rgb_fraction", "foreground_union_exact_fraction",
			"foreground_union_pixels", "compared_pixels", "ignored_pixels",
		])
		writer.writerows(rows)
	for frame, rgb, foreground, union, compared, ignored in rows:
		print(f"{frame}: rgb={rgb:.9f} foreground={foreground:.9f} "
			f"union={union} compared={compared} ignored={ignored}")
	print(f"Wrote {args.output}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())

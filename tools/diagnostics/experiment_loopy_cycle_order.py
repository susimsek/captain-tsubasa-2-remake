#!/usr/bin/env python3
"""Diagnostic-only experiment: preserve CPU-cycle event order at PPU dot wrap.

This renders a bounded source-frame range to a caller-provided diagnostic folder.
It does not touch runtime assets or select/publish candidate frames.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))


def load_module(name: str, path: Path):
	spec = importlib.util.spec_from_file_location(name, path)
	if spec is None or spec.loader is None:
		raise RuntimeError(f"Cannot import {path}")
	module = importlib.util.module_from_spec(spec)
	sys.modules[name] = module
	spec.loader.exec_module(module)
	return module


class CurrentFrameEventView:
	"""Avoid the POC's cumulative MMC3 rescan; its state is supplied by cache."""
	def __init__(self, events):
		self.events = events
		self.frame = -1

	def __iter__(self):
		return iter(())

	def get(self, key, default=None):
		return self.events.get(key, default) if key == self.frame else default


def normalize_same_scanline_dot_wrap(events: dict[int, list[dict[str, str]]],
									 first: int, last: int) -> list[dict[str, int]]:
	"""Move a dot counter wrap to the next scanline while retaining CPU order.

	The FCEUX getters are sampled after callbacks, so a callback at scanline end
	can report the old scanline with dot zero. We only repair that unambiguous
	same-line, large dot-decrease case; other coordinate ambiguities are logged.
	"""
	repairs = []
	for frame in range(first, last + 1):
		rows = events.get(frame, [])
		rows.sort(key=lambda row: (int(row["cycle_from_frame_start"]),
								 int(row["cycle_absolute"])))
		last_line = None
		last_dot = None
		for row in rows:
			line = int(row["ppu_scanline"])
			dot = int(row["ppu_dot"])
			if last_line == line and last_dot is not None and last_dot - dot >= 200:
				row["ppu_scanline"] = str(line + 1)
				repairs.append({"frame": frame, "cycle": int(row["cycle_from_frame_start"]),
					"old_scanline": line, "old_dot": dot,
					"new_scanline": line + 1, "new_dot": dot})
				line += 1
			last_line, last_dot = line, dot
	return repairs


def clone_mmc3(state, state_type):
	clone = state_type()
	clone.mmc3_select = state.mmc3_select
	clone.mmc3_banks = list(state.mmc3_banks)
	return clone


def png_rows_rgb(path: Path) -> list[bytes]:
	data = path.read_bytes()
	if data[:8] != b"\x89PNG\r\n\x1a\n":
		raise ValueError(f"Not a PNG: {path}")
	position = 8
	chunks = []
	while position < len(data):
		length = int.from_bytes(data[position:position + 4], "big")
		kind = data[position + 4:position + 8]
		if kind == b"IDAT":
			chunks.append(data[position + 8:position + 8 + length])
		position += length + 12
	decoded = __import__("zlib").decompress(b"".join(chunks))
	stride = 256 * 3 + 1
	if len(decoded) != 240 * stride or any(decoded[y * stride] != 0 for y in range(240)):
		raise ValueError(f"Expected RGB 256x240 PNG with filter 0: {path}")
	return [decoded[y * stride + 1:(y + 1) * stride] for y in range(240)]


def temporal_delta_exact(prev: list[bytes], curr: list[bytes],
						 prev_ref: list[bytes], curr_ref: list[bytes]) -> float:
	"""Fraction of pixels whose RGB change vector matches the reference."""
	equal = 0
	for y in range(240):
		for x in range(256):
			i = x * 3
			candidate = tuple(curr[y][i + c] - prev[y][i + c] for c in range(3))
			expected = tuple(curr_ref[y][i + c] - prev_ref[y][i + c] for c in range(3))
			equal += candidate == expected
	return equal / (256 * 240)


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--rom", type=Path, default=ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes")
	parser.add_argument("--capture-dir", type=Path, default=ROOT / "reference/opening_timing_capture_20261024_125300")
	parser.add_argument("--palette-file", type=Path, default=ROOT / "reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal")
	parser.add_argument("--screens-dir", type=Path, default=ROOT / "reference/opening_reference_capture/screens")
	parser.add_argument("--runtime-dir", type=Path, default=ROOT / "assets/opening/intro/captured")
	parser.add_argument("--output-dir", type=Path, required=True)
	parser.add_argument("--first", type=int, default=380)
	parser.add_argument("--last", type=int, default=809)
	args = parser.parse_args()
	for name in ("rom", "capture_dir", "palette_file", "screens_dir", "runtime_dir", "output_dir"):
		value = getattr(args, name)
		if not value.is_absolute():
			setattr(args, name, ROOT / value)

	poc = load_module("loopy_frame_poc_cycle_order", ROOT / "tools/diagnostics/render_loopy_event_frame_poc.py")
	compare = load_module("intro_compare_cycle_order", ROOT / "tools/compare_rom_intro_frames.py")
	frames, events = poc.load_capture(args.capture_dir)
	# Runtime/source images are sampled every other capture frame. Include the
	# nearest sampled neighbors so continuity across both range edges is scored.
	selected_frames = sorted(
		frame for frame in frames
		if args.first - 2 <= frame <= args.last + 1
		and (args.runtime_dir / f"frame_{frame:06d}.png").is_file()
		and (args.screens_dir / f"frame_{frame:06d}.gd").is_file()
	)
	repairs = normalize_same_scanline_dot_wrap(events, args.first - 2, args.last + 1)
	state_type = poc.Mmc3State
	state = state_type()
	state_at_frame = {}
	for frame in sorted(events):
		for event in events[frame]:
			address = int(event["address"].removeprefix("$"), 16)
			if address in (0x8000, 0x8001):
				value = int(event["value"].removeprefix("$"), 16)
				poc.apply_mmc3_write(state, address, value)
		if frame in selected_frames:
			state_at_frame[frame] = clone_mmc3(state, state_type)

	view = CurrentFrameEventView(events)
	active_frame = [-1]
	poc.Mmc3State = lambda: clone_mmc3(state_at_frame[active_frame[0]], state_type)
	chr_rom, _, _ = poc.extract_chr(args.rom)
	rom_sha = hashlib.sha256(args.rom.read_bytes()).hexdigest()
	palette = poc.read_palette_file(args.palette_file)
	args.output_dir.mkdir(parents=True, exist_ok=True)
	rows = []
	images = {}
	for frame in selected_frames:
		active_frame[0] = frame
		view.frame = frame
		meta = poc.render_frame(frame, args.capture_dir, frames, view, chr_rom, palette,
							args.output_dir, rom_sha)
		candidate_path = Path(meta["output"])
		reference_path = args.screens_dir / f"frame_{frame:06d}.gd"
		runtime_path = args.runtime_dir / f"frame_{frame:06d}.png"
		if not reference_path.is_file() or not runtime_path.is_file():
			continue
		candidate_rgb = compare.png_rgb(candidate_path)
		reference_rgb = compare.gd_rgb(reference_path)
		full, foreground, union = compare.compare(candidate_rgb, reference_rgb)
		# Restrict comparison to the lower 104 lines where the dialogue split is.
		bottom_bytes = b"".join(candidate_rgb[y * 256 * 3:(y + 1) * 256 * 3] for y in range(136, 240))
		ref_bytes = b"".join(reference_rgb[y * 256 * 3:(y + 1) * 256 * 3] for y in range(136, 240))
		bottom = sum(bottom_bytes[i:i + 3] == ref_bytes[i:i + 3]
					for i in range(0, len(bottom_bytes), 3)) / (256 * 104)
		baseline_rgb = compare.png_rgb(runtime_path)
		base_full = sum(candidate_rgb[i:i + 3] == reference_rgb[i:i + 3]
						for i in range(0, len(candidate_rgb), 3)) / (256 * 240)
		base_runtime = sum(baseline_rgb[i:i + 3] == reference_rgb[i:i + 3]
						   for i in range(0, len(baseline_rgb), 3)) / (256 * 240)
		rows.append({"frame": frame, "whole_exact": full, "foreground_exact": foreground,
			"bottom_y136_239_exact": bottom, "runtime_whole_exact": base_runtime,
			"foreground_pixels": union, "candidate_png": str(candidate_path)})
		images[frame] = (png_rows_rgb(candidate_path), png_rows_rgb(runtime_path),
						 [reference_rgb[y * 256 * 3:(y + 1) * 256 * 3] for y in range(240)])

	with (args.output_dir / "metrics.csv").open("w", newline="", encoding="utf-8") as stream:
		writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
		writer.writeheader()
		writer.writerows(rows)
	pairs = []	
	image_frames = sorted(images)
	for before, after in zip(image_frames, image_frames[1:]):
		cand_delta = temporal_delta_exact(images[before][0], images[after][0], images[before][2], images[after][2])
		runtime_delta = temporal_delta_exact(images[before][1], images[after][1], images[before][2], images[after][2])
		pairs.append({"from": before, "to": after, "candidate_delta_exact": cand_delta,
			"runtime_delta_exact": runtime_delta})
	(args.output_dir / "event_coordinate_repairs.json").write_text(json.dumps(repairs, indent=2) + "\n", encoding="utf-8")
	(args.output_dir / "adjacent_delta_metrics.json").write_text(json.dumps(pairs, indent=2) + "\n", encoding="utf-8")
	summary = {
		"status": "diagnostic-only; runtime untouched",
		"range": [args.first, args.last], "frame_count": len(rows),
		"coordinate_repairs": len(repairs), "repairs": repairs,
		"whole_exact_mean": sum(r["whole_exact"] for r in rows if args.first <= r["frame"] <= args.last) / sum(args.first <= r["frame"] <= args.last for r in rows),
		"bottom_y136_239_exact_mean": sum(r["bottom_y136_239_exact"] for r in rows if args.first <= r["frame"] <= args.last) / sum(args.first <= r["frame"] <= args.last for r in rows),
		"runtime_whole_exact_mean": sum(r["runtime_whole_exact"] for r in rows if args.first <= r["frame"] <= args.last) / sum(args.first <= r["frame"] <= args.last for r in rows),
		"adjacent_pair_count": len(pairs),
		"candidate_adjacent_delta_exact_mean": sum(r["candidate_delta_exact"] for r in pairs) / len(pairs),
		"runtime_adjacent_delta_exact_mean": sum(r["runtime_delta_exact"] for r in pairs) / len(pairs),
		"limitations": ["Only same-scanline dot wrap >=200 is normalized.",
			"The POC still models immediate per-pixel fetches and snapshot VRAM, not the full 2C02 pipeline.",
			"FCEUX screenshots and the --newppu timing trace are separate captures."],
	}
	(args.output_dir / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
	print(json.dumps(summary, indent=2))


if __name__ == "__main__":
	main()

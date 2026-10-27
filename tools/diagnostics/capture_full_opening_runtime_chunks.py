#!/usr/bin/env python3
"""Capture every opening source frame in short Godot runs to bound renderer memory."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path
import sys

try:
	import numpy as np
except ImportError:  # Keep the capture utility usable without optional NumPy.
	np = None


PROJECT_ROOT = Path(__file__).resolve().parents[2]
CAPTURE_SCRIPT = "tools/diagnostics/capture_full_opening_runtime_reference.gd"
DEFAULT_INDEX = "reference/opening_full_frame_capture_20261025_101014/screen_index.csv"
DEFAULT_COMPARE_DIR = "reference/diagnostics/opening_runtime_full_20261026_packed_rows"
sys.path.insert(0, str(PROJECT_ROOT / "tools"))
from compare_rom_intro_frames import png_rgb


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--index", type=Path, default=PROJECT_ROOT / DEFAULT_INDEX)
	parser.add_argument("--chunk-size", type=int, default=300)
	parser.add_argument("--godot", default=shutil.which("godot") or "godot")
	parser.add_argument("--gpu-diagnostic", action="store_true",
		help="Opt in to the diagnostic shader backend; never changes the production default")
	parser.add_argument("--compare-dir", type=Path,
		help=f"Compare captured RGB output against this Godot capture (default for GPU mode: {DEFAULT_COMPARE_DIR})")
	parser.add_argument("--output-dir", type=Path,
		help="Resume or write captures in an existing project-relative diagnostics folder")
	args = parser.parse_args()
	if args.chunk_size <= 0 or args.chunk_size > 350:
		parser.error("--chunk-size must be in the range 1–350; keep it below the per-process viewport readback limit")
	if not args.index.is_file():
		parser.error(f"FCEUX source-frame index does not exist: {args.index}")

	with args.index.open(newline="", encoding="utf-8") as stream:
		reader = csv.DictReader(stream)
		if not reader.fieldnames or "source_frame" not in reader.fieldnames:
			parser.error("FCEUX index needs a source_frame column")
		rows = list(reader)
	frames = [int(row["source_frame"]) for row in rows]
	if frames != list(range(4693)):
		parser.error("FCEUX index must contain the contiguous source-frame range 0–4692")

	timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
	if args.output_dir is None:
		mode_suffix = "gpu_diagnostic_" if args.gpu_diagnostic else "chunks_"
		output_relative = f"reference/diagnostics/opening_runtime_full_{mode_suffix}{timestamp}"
		output_dir = PROJECT_ROOT / output_relative
		output_dir.mkdir(parents=True, exist_ok=False)
	else:
		output_dir = args.output_dir if args.output_dir.is_absolute() else PROJECT_ROOT / args.output_dir
		output_dir = output_dir.resolve()
		try:
			output_relative = output_dir.relative_to(PROJECT_ROOT).as_posix()
		except ValueError:
			parser.error("--output-dir must stay inside the project")
		output_dir.mkdir(parents=True, exist_ok=True)
	if args.gpu_diagnostic and any(output_dir.glob("frame_*.png")):
		parser.error("--gpu-diagnostic will not overwrite or resume an existing frame capture; choose a new empty --output-dir")
	compare_dir: Path | None = None
	if args.gpu_diagnostic:
		compare_dir = args.compare_dir or Path(DEFAULT_COMPARE_DIR)
	elif args.compare_dir is not None:
		compare_dir = args.compare_dir
	if compare_dir is not None:
		if not compare_dir.is_absolute():
			compare_dir = PROJECT_ROOT / compare_dir
		missing_compare = [frame for frame in range(4693)
			if not (compare_dir / f"frame_{frame:06d}.png").is_file()]
		if missing_compare:
			parser.error(f"Comparison capture is incomplete; missing frames {missing_compare[:5]} in {compare_dir}")
	log_path = output_dir / "capture_chunks.log"
	chunk_count = (len(rows) + args.chunk_size - 1) // args.chunk_size
	started = time.monotonic()
	total_gpu_fallbacks = 0
	with tempfile.TemporaryDirectory(prefix="ct2_opening_frame_chunks_") as temp_root:
		for chunk_number, offset in enumerate(range(0, len(rows), args.chunk_size), start=1):
			chunk_rows = rows[offset:offset + args.chunk_size]
			chunk_start = int(chunk_rows[0]["source_frame"])
			chunk_end = int(chunk_rows[-1]["source_frame"])
			if all((output_dir / f"frame_{frame:06d}.png").is_file()
					for frame in range(chunk_start, chunk_end + 1)):
				print(f"CHUNK_SKIP {chunk_number}/{chunk_count} frames={chunk_start}-{chunk_end} already complete", flush=True)
				continue
			chunk_index = Path(temp_root) / f"index_{chunk_number:02d}.csv"
			with chunk_index.open("w", newline="", encoding="utf-8") as stream:
				writer = csv.DictWriter(stream, fieldnames=reader.fieldnames)
				writer.writeheader()
				writer.writerows(chunk_rows)
			command = [
				args.godot,
				"--audio-driver", "Dummy",
				"--path", str(PROJECT_ROOT),
				"--script", CAPTURE_SCRIPT,
				"--",
				f"--index={chunk_index}",
				f"--output-dir=res://{output_relative}",
				"--hide-window",
			]
			if args.gpu_diagnostic:
				command.append("--gpu-diagnostic")
			else:
				command.append("--force-software-renderer-diagnostics")
			chunk_started = time.monotonic()
			print(f"CHUNK_START {chunk_number}/{chunk_count} frames={chunk_start}-{chunk_end}", flush=True)
			completed = subprocess.run(command, cwd=PROJECT_ROOT, text=True,
				stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)
			match = re.search(r"Captured (\d+) opening reference frames through source frame (\d+):", completed.stdout)
			if completed.returncode != 0 or match is None:
				print(completed.stdout, end="", flush=True)
				with log_path.open("a", encoding="utf-8") as log:
					log.write(f"CHUNK_FAILED {chunk_number}/{chunk_count} exit={completed.returncode}\n")
					log.write(completed.stdout + "\n")
				return completed.returncode or 1
			captured = int(match.group(1))
			if captured != len(chunk_rows):
				print(completed.stdout, end="", flush=True)
				print(f"ERROR expected {len(chunk_rows)} screenshots, got {captured}", flush=True)
				return 1
			if args.gpu_diagnostic:
				gpu_summary = re.search(
					r"GPU_DIAGNOSTIC_SUMMARY fallback_count=(\d+) viewport_readbacks=(\d+) cached_image_reuses=(\d+)",
					completed.stdout,
				)
				if gpu_summary is None:
					print(completed.stdout, end="", flush=True)
					print("ERROR GPU diagnostic summary was missing from capture output", flush=True)
					return 1
				fallbacks, gpu_readbacks, gpu_reuses = map(int, gpu_summary.groups())
				total_gpu_fallbacks += fallbacks
				if fallbacks != 0 or gpu_readbacks != len(chunk_rows) or gpu_reuses != 0:
					print(completed.stdout, end="", flush=True)
					print("ERROR GPU capture invariant failed: "
						f"fallbacks={fallbacks} readbacks={gpu_readbacks}/{len(chunk_rows)} "
						f"cached_reuses={gpu_reuses}", flush=True)
					return 1
			missing = [frame for frame in range(chunk_start, chunk_end + 1)
				if not (output_dir / f"frame_{frame:06d}.png").is_file()]
			if missing:
				print(f"ERROR chunk {chunk_number} missing frames: {missing[:5]}", flush=True)
				return 1
			elapsed = time.monotonic() - chunk_started
			cache_match = re.search(r"viewport readbacks=(\d+), cached image reuses=(\d+)", completed.stdout)
			cache_summary = ""
			if cache_match is not None:
				cache_summary = f" viewport_readbacks={cache_match.group(1)} cached_image_reuses={cache_match.group(2)}"
			if args.gpu_diagnostic:
				cache_summary += f" gpu_fallbacks={fallbacks}"
			line = f"CHUNK_OK {chunk_number}/{chunk_count} frames={chunk_start}-{chunk_end} elapsed_seconds={elapsed:.1f}{cache_summary}"
			print(line, flush=True)
			with log_path.open("a", encoding="utf-8") as log:
				log.write(line + "\n")

	frame_files = list(output_dir.glob("frame_*.png"))
	frame_numbers = sorted(int(path.stem[6:]) for path in frame_files)
	complete = frame_numbers == list(range(4693))
	result = f"DONE frames={len(frame_files)} contiguous={complete} elapsed_seconds={time.monotonic() - started:.1f} output={output_relative}"
	print(result, flush=True)
	with log_path.open("a", encoding="utf-8") as log:
		log.write(result + "\n")
	if args.gpu_diagnostic:
		gpu_result = f"GPU_DIAGNOSTIC_TOTAL fallback_count={total_gpu_fallbacks} cached_image_reuses=0"
		print(gpu_result, flush=True)
		with log_path.open("a", encoding="utf-8") as log:
			log.write(gpu_result + "\n")
	if not complete:
		return 1
	if compare_dir is not None:
		parity = _compare_captures(output_dir, compare_dir)
		print(parity["summary"], flush=True)
		with log_path.open("a", encoding="utf-8") as log:
			log.write(parity["summary"] + "\n")
		return 0 if int(parity["exact_frames"]) == 4693 else 1
	return 0


def _compare_captures(candidate_dir: Path, reference_dir: Path) -> dict[str, object]:
	"""Compare all frames as decoded RGB pixels and save per-frame parity metrics."""
	metrics_path = candidate_dir / "pixel_parity.csv"
	rows: list[tuple[int, bool, int, int, str, str]] = []
	total_differing_pixels = 0
	total_differing_channels = 0
	first_mismatch = -1
	for frame in range(4693):
		candidate_path = candidate_dir / f"frame_{frame:06d}.png"
		reference_path = reference_dir / f"frame_{frame:06d}.png"
		candidate = png_rgb(candidate_path)
		reference = png_rgb(reference_path)
		if np is not None:
			candidate_array = np.frombuffer(candidate, dtype=np.uint8).reshape(240, 256, 3)
			reference_array = np.frombuffer(reference, dtype=np.uint8).reshape(240, 256, 3)
			channel_mask = candidate_array != reference_array
			channel_count = int(np.count_nonzero(channel_mask))
			pixel_count = int(np.count_nonzero(np.any(channel_mask, axis=2)))
		else:
			channel_count = sum(a != b for a, b in zip(candidate, reference))
			pixel_count = sum(candidate[i:i + 3] != reference[i:i + 3]
				for i in range(0, len(candidate), 3))
		is_exact = channel_count == 0
		if not is_exact and first_mismatch < 0:
			first_mismatch = frame
		total_differing_channels += channel_count
		total_differing_pixels += pixel_count
		rows.append((frame, is_exact, pixel_count, channel_count,
			hashlib.sha256(candidate).hexdigest(),
			hashlib.sha256(reference).hexdigest()))
	with metrics_path.open("w", newline="", encoding="utf-8") as stream:
		writer = csv.writer(stream)
		writer.writerow(["frame", "rgb_exact", "differing_pixels", "differing_rgb_channels",
			"candidate_rgb_sha256", "reference_rgb_sha256"])
		writer.writerows(rows)
	exact_frames = sum(row[1] for row in rows)
	summary_data = {
		"candidate_capture": str(candidate_dir),
		"reference_capture": str(reference_dir),
		"frames": len(rows),
		"exact_frames": exact_frames,
		"mismatched_frames": len(rows) - exact_frames,
		"total_differing_pixels": total_differing_pixels,
		"total_differing_rgb_channels": total_differing_channels,
		"mean_rgb_channel_exact_fraction": 1.0 - total_differing_channels / (4693 * 256 * 240 * 3),
		"first_mismatched_frame": first_mismatch,
		"metrics_csv": str(metrics_path),
	}
	(candidate_dir / "pixel_parity_summary.json").write_text(
		json.dumps(summary_data, indent=2) + "\n", encoding="utf-8")
	return {
		"exact_frames": exact_frames,
		"summary": "GPU_PIXEL_PARITY frames=%d exact=%d mismatched=%d differing_pixels=%d differing_rgb_channels=%d first_mismatch=%d" % (
			len(rows), exact_frames, len(rows) - exact_frames,
			total_differing_pixels, total_differing_channels, first_mismatch,
		),
	}


if __name__ == "__main__":
	raise SystemExit(main())

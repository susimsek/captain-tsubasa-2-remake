#!/usr/bin/env python3
"""Build a separate, ROM-source opening WAV candidate without touching runtime assets."""

from __future__ import annotations

import hashlib
import json
import wave
from pathlib import Path

from build_opening_timeline_nsf import build as build_nsf
from render_rom_driver_nsf import render

ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = ROOT / "reference/diagnostics/audio/rom_driver_rebuilt_candidate_20261025"
RUNTIME_WAV = ROOT / "assets/opening/audio/opening_timeline_rom_driver.wav"
SAMPLE_RATE = 44_100
FPS = 60.0988
TOTAL_FRAMES = 4662
ALIGNMENT_SHIFT_FRAMES = 3
RENDER_SECONDS = 79


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def build_candidate(output_dir: Path = OUTPUT_DIR) -> dict:
	output_dir = output_dir.resolve()
	if output_dir.exists():
		raise FileExistsError(f"Refusing to overwrite candidate artifacts: {output_dir}")
	output_dir.mkdir(parents=True)
	runtime_sha_before = sha256(RUNTIME_WAV)

	nsf_path = output_dir / "opening_timeline_rom_driver_candidate.nsf"
	unaligned_path = output_dir / "opening_timeline_candidate_unaligned.wav"
	candidate_path = output_dir / "opening_timeline_candidate.wav"
	nsf_meta = build_nsf(nsf_path)
	render(nsf_path, unaligned_path, RENDER_SECONDS, SAMPLE_RATE, preserve_initial_silence=True)

	with wave.open(str(unaligned_path), "rb") as source:
		format_tuple = (source.getnchannels(), source.getsampwidth(), source.getframerate())
		if format_tuple != (1, 2, SAMPLE_RATE):
			raise ValueError(f"Unexpected candidate intermediate format: {format_tuple}")
		pcm = source.readframes(source.getnframes())
		intermediate_samples = source.getnframes()

	shift_samples = round(ALIGNMENT_SHIFT_FRAMES * SAMPLE_RATE / FPS)
	output_samples = round(TOTAL_FRAMES * SAMPLE_RATE / FPS)
	start_byte = shift_samples * 2
	end_byte = (shift_samples + output_samples) * 2
	candidate_pcm = pcm[start_byte:end_byte]
	if len(candidate_pcm) != output_samples * 2:
		raise ValueError("ROM-source intermediate is too short for the candidate crop")

	with wave.open(str(candidate_path), "wb") as output:
		output.setnchannels(1)
		output.setsampwidth(2)
		output.setframerate(SAMPLE_RATE)
		output.writeframes(candidate_pcm)

	runtime_sha_after = sha256(RUNTIME_WAV)
	if runtime_sha_after != runtime_sha_before:
		raise RuntimeError("The protected Godot runtime WAV changed during candidate build")

	metadata = {
		"purpose": "Build-only ROM-source candidate for comparison; not a Godot runtime asset.",
		"source_rom_sha256": nsf_meta["source_rom_sha256"],
		"source_nsf_path": nsf_path.relative_to(ROOT).as_posix(),
		"source_nsf_sha256": nsf_meta["nsf_sha256"],
		"source_event_schedule": "Current ROM builder; cue IDs and absolute frames remain FCEUX RAM $0700 capture-anchored.",
		"intermediate_wav_path": unaligned_path.relative_to(ROOT).as_posix(),
		"intermediate_wav_sha256": sha256(unaligned_path),
		"intermediate_sample_count": intermediate_samples,
		"candidate_wav_path": candidate_path.relative_to(ROOT).as_posix(),
		"candidate_wav_sha256": sha256(candidate_path),
		"candidate_sample_count": output_samples,
		"sample_rate_hz": SAMPLE_RATE,
		"channels": 1,
		"bits_per_sample": 16,
		"video_frames": TOTAL_FRAMES,
		"renderer": "libgme 0.6.5 executing ROM-source NSF bytes",
		"crop": {
			"alignment_shift_frames": ALIGNMENT_SHIFT_FRAMES,
			"alignment_shift_samples": shift_samples,
			"frame_rate_hz": FPS,
		},
		"captured_pcm_used_as_input": False,
		"runtime_asset": False,
		"protected_runtime_wav": {
			"path": RUNTIME_WAV.relative_to(ROOT).as_posix(),
			"sha256_before": runtime_sha_before,
			"sha256_after": runtime_sha_after,
			"unchanged": runtime_sha_before == runtime_sha_after,
		},
	}
	metadata_path = output_dir / "candidate_build_manifest.json"
	metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
	return metadata


if __name__ == "__main__":
	print(json.dumps(build_candidate(), indent=2))

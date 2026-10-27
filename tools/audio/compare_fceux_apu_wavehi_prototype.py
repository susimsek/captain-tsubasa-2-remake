#!/usr/bin/env python3
"""Compare the ROM-source APU/WaveHi diagnostic render to validation-only FCEUX PCM."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import wave
from array import array
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FPS = 60.0988
CPU_HZ = 1_789_772.7272727273
SAMPLE_RATE = 44_100
DEFAULT_REFERENCE = ROOT / "reference/diagnostics/audio/fceux_cold_start_silent_pcm_precise_20261024.wav"
DEFAULT_CANDIDATE = ROOT / "reference/diagnostics/audio/rom_source_wavehi_channelbc_replay_20261025/source_dmc_channelbc_wavehi.wav"
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/audio/rom_source_wavehi_channelbc_replay_20261025/validation_comparison.json"
WINDOWS = {
	"first_cue_before_dmc": (283, 366),
	"dmc_first_music_window": (367, 450),
	"later_28_sequence": (1038, 1120),
	"later_02_sequence": (1500, 1525),
	"late_58_loop": (4460, 4510),
	"final_68_cue": (4568, 4600),
	"stop_and_filter_tail": (4655, 4685),
}


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def load_wav(path: Path) -> array:
	with wave.open(str(path), "rb") as wav:
		if wav.getnchannels() != 1 or wav.getsampwidth() != 2 or wav.getframerate() != SAMPLE_RATE:
			raise ValueError(f"expected 44.1 kHz mono signed 16-bit PCM: {path}")
		values = array("h")
		values.frombytes(wav.readframes(wav.getnframes()))
		return values


def pearson(left: list[float], right: list[float]) -> float | None:
	if len(left) != len(right) or len(left) < 2:
		return None
	mean_left = sum(left) / len(left)
	mean_right = sum(right) / len(right)
	denominator = math.sqrt(
		sum((value - mean_left) ** 2 for value in left)
		* sum((value - mean_right) ** 2 for value in right)
	)
	if not denominator:
		return None
	return sum((a - mean_left) * (b - mean_right) for a, b in zip(left, right)) / denominator


def frame_envelope(samples: array) -> list[float]:
	frame_count = math.ceil(len(samples) * FPS / SAMPLE_RATE)
	result = []
	for frame in range(frame_count):
		start = round(frame * SAMPLE_RATE / FPS)
		end = min(len(samples), round((frame + 1) * SAMPLE_RATE / FPS))
		part = samples[start:end]
		result.append(math.sqrt(sum(value * value for value in part) / len(part)) if part else 0.0)
	return result


def sample_metrics(reference: array, candidate: array, lo_frame: int, hi_frame: int) -> dict:
	lo = round(lo_frame * SAMPLE_RATE / FPS)
	hi = min(len(reference), len(candidate), round(hi_frame * SAMPLE_RATE / FPS))
	ref_all = reference[lo:hi]
	best = None
	for lag in range(-8, 9):
		candidate_lo = lo - lag
		candidate_hi = hi - lag
		if candidate_lo < 0 or candidate_hi > len(candidate):
			continue
		ref = list(ref_all)
		cand = list(candidate[candidate_lo:candidate_hi])
		correlation = pearson(ref, cand)
		if correlation is not None and (best is None or correlation > best["correlation"]):
			best = {"reference_minus_candidate_samples": lag, "correlation": correlation}
	
	ref = list(ref_all)
	cand = list(candidate[lo:hi])
	correlation = pearson(ref, cand)
	ref_energy = sum(value * value for value in ref)
	cand_energy = sum(value * value for value in cand)
	gain = sum(a * b for a, b in zip(ref, cand)) / cand_energy if cand_energy else None
	rmse = math.sqrt(sum((a - b) ** 2 for a, b in zip(ref, cand)) / len(ref)) if ref else 0.0
	ref_rms = math.sqrt(ref_energy / len(ref)) if ref else 0.0
	return {
		"sample_range": [lo, hi],
		"sample_count": len(ref),
		"same_index_correlation": correlation,
		"best_lag_within_plus_minus_8_samples": best,
		"candidate_over_reference_rms": math.sqrt(cand_energy / ref_energy) if ref_energy else None,
		"best_linear_candidate_gain_to_reference": gain,
		"same_index_normalized_rmse": rmse / ref_rms if ref_rms else None,
	}


def compare(reference_path: Path, candidate_path: Path) -> dict:
	reference = load_wav(reference_path)
	candidate = load_wav(candidate_path)
	if len(reference) != len(candidate):
		raise ValueError(f"sample count mismatch: FCEUX={len(reference)}, candidate={len(candidate)}")
	metadata_path = candidate_path.with_suffix(".json")
	candidate_metadata = json.loads(metadata_path.read_text(encoding="utf-8")) if metadata_path.exists() else {}
	ref_env = frame_envelope(reference)
	cand_env = frame_envelope(candidate)
	windows = {}
	for label, (lo, hi) in WINDOWS.items():
		windows[label] = {
			"range_frames_end_exclusive": [lo, hi],
			"frame_rms_correlation": pearson(ref_env[lo:hi], cand_env[lo:hi]),
			"candidate_over_reference_mean_frame_rms": (
				sum(cand_env[lo:hi]) / sum(ref_env[lo:hi]) if sum(ref_env[lo:hi]) else None
			),
			"sample_metrics": sample_metrics(reference, candidate, lo, hi),
		}
	return {
		"purpose": "Validation-only comparison. Captured FCEUX PCM is read here as a reference only; the ROM-source renderer does not read it.",
		"settings": {"sample_rate_hz": SAMPLE_RATE, "frame_rate_hz": FPS, "ntsc_cpu_hz": CPU_HZ},
		"input_files": {
			"fceux_pcm_reference": {
				"path": reference_path.relative_to(ROOT).as_posix(),
				"sha256": sha256(reference_path),
				"samples": len(reference),
				"role": "comparison only",
			},
			"rom_source_candidate": {
				"path": candidate_path.relative_to(ROOT).as_posix(),
				"sha256": sha256(candidate_path),
				"samples": len(candidate),
			"role": "diagnostic render from original-ROM-derived APU writes and bank-$1E DMC bytes with FCEUX-measured instruction-hook fetch times",
				"renderer_source_sha256": candidate_metadata.get("implementation", {}).get("source_sha256"),
			},
		},
		"timing_anchors": {
			"first_dmc_enable_source_cycle": 10_905_284,
			"first_dmc_enable_source_frame": 367,
			"dmc_enable_pcm_sample_position_unprimed": 10_905_284 * SAMPLE_RATE / CPU_HZ,
			"first_cue_window_end_source_frame": 367,
		},
		"windows": windows,
		"limits": [
			"DMC fetch/bit-state, PCM_SYNC_IN DAC phase corrections, and frame-update timestamps come from an instrumented replay of pinned FCEUX 2.7.0; the pulse/triangle/noise synthesis and filter pipeline remain separate source ports whose waveform fidelity is measured here.",
			"ChannelBC flush boundaries are ported from pinned sound.cpp call sites, but the renderer still replays frame-update/DMC timing from instrumented FCEUX and does not execute the original 6502 instruction/DMA opportunity loop; same-input correlation is evidence for this captured opening only.",
			"Envelope or waveform agreement on these windows does not prove arbitrary-input Godot audio equivalence; runtime assets remain untouched.",
		],
	}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--reference", type=Path, default=DEFAULT_REFERENCE)
	parser.add_argument("--candidate", type=Path, default=DEFAULT_CANDIDATE)
	parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
	args = parser.parse_args()
	output = args.output.resolve()
	output.parent.mkdir(parents=True, exist_ok=True)
	result = compare(args.reference.resolve(), args.candidate.resolve())
	output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(output)


if __name__ == "__main__":
	main()

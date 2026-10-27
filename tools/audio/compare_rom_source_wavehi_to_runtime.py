#!/usr/bin/env python3
"""Compare source WaveHi diagnostics and current runtime audio to FCEUX PCM."""

from __future__ import annotations

import argparse
from array import array
import hashlib
import json
import math
from pathlib import Path
import wave

ROOT = Path(__file__).resolve().parents[2]
FPS = 60.0988
SAMPLE_RATE = 44_100
REFERENCE = ROOT / "reference/diagnostics/audio/fceux_cold_start_silent_pcm_precise_20261024.wav"
RUNTIME = ROOT / "assets/opening/audio/opening_timeline_rom_driver.wav"
CANDIDATE = ROOT / "reference/diagnostics/audio/rom_source_wavehi_improvement_20261025/source_driver_wavehi.wav"
OUTPUT = ROOT / "reference/diagnostics/audio/rom_source_wavehi_improvement_20261025/head_to_head_comparison.json"
WINDOWS = {
	"first_music_before_dmc": (283, 366),
	"first_dmc_music": (367, 450),
	"later_28_cue_sequence": (1038, 1120),
	"late_58_loop": (4460, 4510),
	"final_68_cue": (4568, 4600),
	"last_shared_pre_stop": (4655, 4661),
}


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def read_wav(path: Path) -> array:
	with wave.open(str(path), "rb") as wav:
		if (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) != (1, 2, SAMPLE_RATE):
			raise ValueError(f"Expected 44.1-kHz mono 16-bit PCM: {path}")
		pcm = array("h")
		pcm.frombytes(wav.readframes(wav.getnframes()))
		return pcm


def pearson(left: list[int], right: list[int]) -> float | None:
	if len(left) != len(right) or len(left) < 2:
		return None
	mean_left = sum(left) / len(left)
	mean_right = sum(right) / len(right)
	var_left = sum((value - mean_left) ** 2 for value in left)
	var_right = sum((value - mean_right) ** 2 for value in right)
	denom = math.sqrt(var_left * var_right)
	if not denom:
		return None
	return sum((a - mean_left) * (b - mean_right) for a, b in zip(left, right)) / denom


def compare_window(reference: array, candidate: array, start_frame: int, end_frame: int) -> dict:
	lo = round(start_frame * SAMPLE_RATE / FPS)
	hi = round(end_frame * SAMPLE_RATE / FPS)
	if hi > min(len(reference), len(candidate)):
		raise ValueError("Window exceeds the common reference/candidate sample range")
	ref = list(reference[lo:hi])
	actual = list(candidate[lo:hi])
	best_lag = None
	for lag in range(-8, 9):
		candidate_lo = lo - lag
		candidate_hi = hi - lag
		if candidate_lo < 0 or candidate_hi > len(candidate):
			continue
		correlation = pearson(ref, list(candidate[candidate_lo:candidate_hi]))
		if correlation is not None and (best_lag is None or correlation > best_lag["correlation"]):
			best_lag = {"reference_minus_candidate_samples": lag, "correlation": correlation}
	ref_energy = sum(value * value for value in ref)
	candidate_energy = sum(value * value for value in actual)
	rmse = math.sqrt(sum((a - b) ** 2 for a, b in zip(ref, actual)) / len(ref))
	return {
		"sample_range": [lo, hi],
		"sample_count": len(ref),
		"same_index_correlation": pearson(ref, actual),
		"best_lag_within_plus_minus_8_samples": best_lag,
		"candidate_over_reference_rms": math.sqrt(candidate_energy / ref_energy) if ref_energy else None,
		"same_index_normalized_rmse": rmse / math.sqrt(ref_energy / len(ref)) if ref_energy else None,
	}


def build_report(reference_path: Path, runtime_path: Path, candidate_path: Path) -> dict:
	reference = read_wav(reference_path)
	runtime = read_wav(runtime_path)
	candidate = read_wav(candidate_path)
	if len(reference) != len(candidate):
		raise ValueError("The full source WaveHi diagnostic must cover the same sample horizon as FCEUX PCM")
	windows = {}
	for name, (start, end) in WINDOWS.items():
		windows[name] = {
			"range_frames_end_exclusive": [start, end],
			"runtime_vs_fceux": compare_window(reference, runtime, start, end),
			"rom_source_wavehi_vs_fceux": compare_window(reference, candidate, start, end),
		}
	return {
		"purpose": "Validation-only head-to-head. The FCEUX WAV is read only for metrics and was not used to synthesize either candidate.",
		"settings": {"sample_rate_hz": SAMPLE_RATE, "frame_rate_hz": FPS, "offset_search": "same-index metric is primary; +/-8 samples is diagnostic context only"},
		"inputs": {
			"fceux_pcm_reference": {"path": reference_path.relative_to(ROOT).as_posix(), "sha256": sha256(reference_path), "role": "comparison only"},
			"runtime_libgme_wav": {"path": runtime_path.relative_to(ROOT).as_posix(), "sha256": sha256(runtime_path), "role": "current Godot runtime asset; ROM-driver NSF/libgme render"},
			"rom_source_wavehi_candidate": {"path": candidate_path.relative_to(ROOT).as_posix(), "sha256": sha256(candidate_path), "metadata_sha256": sha256(candidate_path.with_suffix(".json")), "role": "diagnostic ROM-source APU/DPCM render; not a runtime asset"},
		},
		"windows": windows,
		"runtime_limits": {
			"runtime_sample_count": len(runtime),
			"reference_sample_count": len(reference),
			"runtime_ends_at_source_frame": 4661,
			"fceux_filter_tail_continues_through_source_frame": 4679,
			"tail_comparison": "No runtime PCM exists after the captured Start/stop frame; do not zero-pad it and call it matched.",
		},
		"promotion_status": "diagnostic_only; early no-DMC improvement does not offset post-DMC and later-cue failures",
	}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--reference", type=Path, default=REFERENCE)
	parser.add_argument("--runtime", type=Path, default=RUNTIME)
	parser.add_argument("--candidate", type=Path, default=CANDIDATE)
	parser.add_argument("--output", type=Path, default=OUTPUT)
	args = parser.parse_args()
	output = args.output.resolve()
	output.parent.mkdir(parents=True, exist_ok=True)
	report = build_report(args.reference.resolve(), args.runtime.resolve(), args.candidate.resolve())
	output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
	print(output.relative_to(ROOT).as_posix())


if __name__ == "__main__":
	main()

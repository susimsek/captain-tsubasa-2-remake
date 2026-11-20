#!/usr/bin/env python3
"""Compare a ROM-derived first-match audio render with a finalized FCEUX WAV.

The tool performs fixed same-index PCM comparisons without sample shifting,
resampling, gain fitting, or modification of runtime assets.
"""

from __future__ import annotations

from array import array
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import wave


FIRST_55_WINDOW = (3_534_072, 5_314_928)
RESTART_55_WINDOW = (5_437_549, 5_949_652)
DEFAULT_CANDIDATE = Path("/tmp/ct2_first_match_audio_ce6_20261109/wavehi/rom_stepper_wavehi_candidate.wav")
DEFAULT_REPORT = Path("/tmp/ct2_first_match_route_pcm_comparison.json")


def digest(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def read_fceux_reference(path: Path, sample_count: int) -> tuple[array, dict]:
	with wave.open(str(path), "rb") as source:
		if source.getnchannels() != 1 or source.getsampwidth() != 2 or source.getframerate() != 44_100:
			raise ValueError("Reference must be mono signed 16-bit PCM at 44.1 kHz")
		available_samples = source.getnframes()
		read_count = available_samples if sample_count <= 0 else sample_count
		if read_count > available_samples:
			raise ValueError(f"Reference has only {available_samples} samples; {read_count} required")
		payload = source.readframes(read_count)
	if len(payload) != read_count * 2:
		raise ValueError(f"Reference returned only {len(payload) // 2} samples; {read_count} required")
	values = array("h")
	values.frombytes(payload)
	if sys.byteorder != "little":
		values.byteswap()
	return values, {
		"path": str(path),
		"finalized_wav": True,
		"format": "mono s16le, 44100 Hz",
		"available_samples": available_samples,
		"samples_read": read_count,
		"read_pcm_sha256": digest(payload),
	}


def read_candidate(path: Path) -> tuple[array, dict]:
	with wave.open(str(path), "rb") as source:
		if source.getnchannels() != 1 or source.getsampwidth() != 2 or source.getframerate() != 44_100:
			raise ValueError("Candidate must be mono signed 16-bit PCM at 44.1 kHz")
		values = array("h")
		values.frombytes(source.readframes(source.getnframes()))
	if sys.byteorder != "little":
		values.byteswap()
	return values, {"path": str(path), "samples": len(values), "sha256": digest(path.read_bytes())}


def metrics(reference: array, candidate: array) -> dict:
	if len(reference) != len(candidate) or not reference:
		raise ValueError("Metric inputs must be nonempty and equal length")
	n = len(reference)
	sum_ref = sum_cand = sum_ref2 = sum_cand2 = sum_product = sum_diff2 = 0
	exact = 0
	for ref, cand in zip(reference, candidate):
		sum_ref += ref
		sum_cand += cand
		sum_ref2 += ref * ref
		sum_cand2 += cand * cand
		sum_product += ref * cand
		diff = ref - cand
		sum_diff2 += diff * diff
		exact += ref == cand
	center_ref = n * sum_ref2 - sum_ref * sum_ref
	center_cand = n * sum_cand2 - sum_cand * sum_cand
	denominator = math.sqrt(center_ref * center_cand)
	correlation = (n * sum_product - sum_ref * sum_cand) / denominator if denominator else None
	return {
		"samples": n,
		"pearson_r": correlation,
		"rmse": math.sqrt(sum_diff2 / n),
		"exact_samples": exact,
		"exact_fraction": exact / n,
		"reference_rms": math.sqrt(sum_ref2 / n),
		"candidate_rms": math.sqrt(sum_cand2 / n),
	}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--reference", type=Path, required=True, help="Finalized same-input FCEUX WAV.")
	parser.add_argument("--candidate", type=Path, default=DEFAULT_CANDIDATE)
	parser.add_argument("--reference-samples", type=int, default=0, help="Maximum reference samples to read; 0 uses the finalized WAV length.")
	parser.add_argument("--reference-start", type=int, default=0, help="Compare one fixed reference window when --sample-count is nonzero.")
	parser.add_argument("--candidate-start", type=int, default=0, help="Candidate sample index for the fixed-window mode.")
	parser.add_argument("--sample-count", type=int, default=0, help="If positive, compare only this fixed sample window and omit route windows.")
	parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
	args = parser.parse_args()

	reference, reference_info = read_fceux_reference(args.reference, args.reference_samples)
	candidate, candidate_info = read_candidate(args.candidate)
	common = min(len(reference), len(candidate))
	if args.sample_count > 0:
		ref_end = args.reference_start + args.sample_count
		candidate_end = args.candidate_start + args.sample_count
		if args.reference_start < 0 or args.candidate_start < 0 or ref_end > len(reference) or candidate_end > len(candidate):
			raise ValueError("Requested fixed comparison window exceeds the available sample range")
		results = {"fixed_window": {
			"reference_sample_window": [args.reference_start, ref_end],
			"candidate_sample_window": [args.candidate_start, candidate_end],
			**metrics(reference[args.reference_start:ref_end], candidate[args.candidate_start:candidate_end]),
		}}
	else:
		windows = {
			"first_55": FIRST_55_WINDOW,
			"restart_55": RESTART_55_WINDOW,
		}
		results = {"common_prefix": metrics(reference[:common], candidate[:common])}
		for name, (start, end) in windows.items():
			if end > common:
				raise ValueError(f"{name} window [{start},{end}) exceeds common sample range {common}")
			results[name] = {"sample_window": [start, end], **metrics(reference[start:end], candidate[start:end])}

	report = {
		"purpose": "Validation-only same-index PCM comparison; no captured audio is a synthesis input.",
		"comparison_policy": "Specified fixed indices only; no sample-shift fitting, resampling, gain fit, or signal processing.",
		"reference": reference_info,
		"candidate": candidate_info,
		"common_samples": common,
		"candidate_shorter_by_samples": None if args.sample_count > 0 else max(0, len(reference) - len(candidate)),
		"metrics": results,
		"limitations": [
			"This is a diagnostics-only comparison; no candidate or captured FCEUX PCM is a runtime asset or synthesis input.",
			"A mismatch alone does not identify whether the cause is source scheduling, DMC/APU emulation, or emulator output filtering.",
		],
	}
	args.report.parent.mkdir(parents=True, exist_ok=True)
	args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({"report": str(args.report), "metrics": results, "reference_pcm_sha256": reference_info["read_pcm_sha256"]}, indent=2))


if __name__ == "__main__":
	main()

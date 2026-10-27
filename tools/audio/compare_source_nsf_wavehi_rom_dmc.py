#!/usr/bin/env python3
"""Validation-only comparison for the ROM/NSF source-only WaveHi candidate."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
FPS = 60.0988
SAMPLE_RATE = 44_100
DEFAULT_REFERENCE = ROOT / "reference/diagnostics/audio/fceux_cold_start_silent_pcm_precise_20261024.wav"
DEFAULT_CANDIDATE = ROOT / "reference/diagnostics/audio/source_nsf_wavehi_rom_dmc_20261026/source_nsf_wavehi.wav"
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/audio/source_nsf_wavehi_rom_dmc_20261026/validation_comparison.json"
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


def load_pcm(path: Path) -> np.ndarray:
	with wave.open(str(path), "rb") as wav:
		if wav.getnchannels() != 1 or wav.getsampwidth() != 2 or wav.getframerate() != SAMPLE_RATE:
			raise ValueError(f"expected 44.1 kHz mono signed 16-bit PCM: {path}")
		return np.frombuffer(wav.readframes(wav.getnframes()), dtype="<i2").astype(np.float64)


def corr(a: np.ndarray, b: np.ndarray) -> float | None:
	if a.size != b.size or a.size < 2:
		return None
	a = a - a.mean()
	b = b - b.mean()
	den = np.sqrt(np.dot(a, a) * np.dot(b, b))
	return float(np.dot(a, b) / den) if den else None


def metric(ref: np.ndarray, cand: np.ndarray, lo: int, hi: int) -> dict:
	a = ref[lo:hi]
	b = cand[lo:hi]
	if a.size != b.size or not a.size:
		return {"sample_range": [lo, hi], "sample_count": int(a.size), "error": "empty or mismatched window"}
	arms = float(np.sqrt(np.mean(a * a)))
	brms = float(np.sqrt(np.mean(b * b)))
	rmse = float(np.sqrt(np.mean((a - b) ** 2)))
	best = None
	for lag in range(-8, 9):
		if lag < 0:
			ca, cb = a[-lag:], b[:b.size + lag]
		elif lag > 0:
			ca, cb = a[:a.size - lag], b[lag:]
		else:
			ca, cb = a, b
		value = corr(ca, cb)
		if value is not None and (best is None or value > best["correlation"]):
			best = {"reference_minus_candidate_samples": lag, "correlation": value}
	wide_best = None
	for lag in range(-2500, 2501):
		if lag < 0:
			wa, wb = a[:a.size + lag], b[-lag:]
		elif lag > 0:
			wa, wb = a[lag:], b[:b.size - lag]
		else:
			wa, wb = a, b
		value = corr(wa, wb)
		if value is not None and (wide_best is None or value > wide_best["correlation"]):
			wide_best = {"reference_minus_candidate_samples": lag, "correlation": value}
	return {
		"sample_range": [lo, hi],
		"sample_count": int(a.size),
		"same_index_correlation": corr(a, b),
		"best_lag_within_plus_minus_8_samples": best,
		"posthoc_best_lag_within_plus_minus_2500_samples": wide_best,
		"candidate_over_reference_rms": brms / arms if arms else None,
		"same_index_normalized_rmse": rmse / arms if arms else None,
		"exact_sample_fraction": float(np.mean(a == b)),
	}


def compare(reference_path: Path, candidate_path: Path) -> dict:
	ref = load_pcm(reference_path)
	cand = load_pcm(candidate_path)
	n = min(ref.size, cand.size)
	windows = {}
	for label, (frame_lo, frame_hi) in WINDOWS.items():
		lo = round(frame_lo * SAMPLE_RATE / FPS)
		hi = min(n, round(frame_hi * SAMPLE_RATE / FPS))
		windows[label] = {"frame_range_end_exclusive": [frame_lo, frame_hi], **metric(ref, cand, lo, hi)}
	manifest_path = candidate_path.with_suffix(".json")
	manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
	return {
		"purpose": "Validation only. Captured FCEUX PCM is read after synthesis and is not a candidate-generation input.",
		"sample_rate_hz": SAMPLE_RATE,
		"frame_rate_hz": FPS,
		"input_files": {
			"fceux_pcm_reference": {"path": reference_path.relative_to(ROOT).as_posix(), "sha256": sha256(reference_path),
				"samples": int(ref.size), "role": "comparison only"},
			"rom_nsf_wavehi_candidate": {"path": candidate_path.relative_to(ROOT).as_posix(), "sha256": sha256(candidate_path),
				"samples": int(cand.size), "role": "source-only diagnostic synthesis", "renderer_source_sha256": manifest.get("renderer", {}).get("source_sha256")},
		},
		"duration": {"candidate_minus_reference_samples": int(cand.size - ref.size),
			"candidate_minus_reference_seconds": (cand.size - ref.size) / SAMPLE_RATE,
			"overlap_samples": int(n),
			"overlap_same_index_correlation": corr(ref[:n], cand[:n]),
			"overlap_exact_sample_fraction": float(np.mean(ref[:n] == cand[:n]))},
		"windows": windows,
		"limits": [
			"Same-index metrics compare the candidate's source NSF clock to the captured cold-start PCM timeline; local +/-8-sample lag is reported only as a diagnostic and is not applied to the synthesis.",
			"The wider +/-2500-sample lag scan is also validation-only. It diagnoses absolute phase and drift; it is not used to shift or resynthesize the candidate.",
			"The source event export still retains documented startup/worker timing anchors, so this does not independently establish the cold-start absolute cue phase.",
			"The modeled DMC fetch stream matches NSF callback address/value order for only the first 478 fetches; at sequence 478, model $C0C0=$95 differs from callback $C29E=$AA. The cycle model does not reproduce NSF's restart/DMA opportunity semantics after this point.",
			"No capture-derived APU-write, DMC, frame-cycle, or PCM data was used to synthesize the candidate.",
		],
	}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--reference", type=Path, default=DEFAULT_REFERENCE)
	parser.add_argument("--candidate", type=Path, default=DEFAULT_CANDIDATE)
	parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
	args = parser.parse_args()
	args.output.parent.mkdir(parents=True, exist_ok=True)
	result = compare(args.reference.resolve(), args.candidate.resolve())
	args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(args.output)


if __name__ == "__main__":
	main()

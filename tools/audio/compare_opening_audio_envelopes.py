#!/usr/bin/env python3
"""Compare ROM-derived opening WAV envelope/stop timing to FCEUX validation PCM."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import wave
from array import array
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REFERENCE_WAV = ROOT / "reference/diagnostics/audio/fceux_cold_start_silent_pcm_precise_20261024.wav"
PRODUCTION_WAV = ROOT / "assets/opening/audio/opening_timeline_rom_driver.wav"
DEFAULT_CANDIDATE = ROOT / "reference/diagnostics/audio/rom_driver_apu_trace_cue_offset_plus2_20261024/rom_driver_candidate_raw.wav"
FPS = 60.0988
NTSC_CPU_HZ = 1_789_772.7272727273
STOP_FRAME = 4661


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def read_mono_pcm(path: Path) -> tuple[array, int, int]:
	with wave.open(str(path), "rb") as wav:
		channels, width, rate = wav.getnchannels(), wav.getsampwidth(), wav.getframerate()
		if channels != 1 or width != 2:
			raise ValueError(f"Expected mono 16-bit PCM WAV: {path}")
		frames = wav.readframes(wav.getnframes())
	values = array("h")
	values.frombytes(frames)
	return values, rate, len(values)


def frame_rms(samples: array, rate: int, frame: int) -> float:
	start = round(frame * rate / FPS)
	end = min(len(samples), round((frame + 1) * rate / FPS))
	if end <= start:
		return 0.0
	return math.sqrt(sum(value * value for value in samples[start:end]) / (end - start))


def pearson(left: list[float], right: list[float]) -> float | None:
	if len(left) < 2 or len(left) != len(right):
		return None
	mean_left = sum(left) / len(left)
	mean_right = sum(right) / len(right)
	delta_left = [value - mean_left for value in left]
	delta_right = [value - mean_right for value in right]
	denominator = math.sqrt(sum(value * value for value in delta_left) * sum(value * value for value in delta_right))
	if denominator == 0:
		return None
	return sum(a * b for a, b in zip(delta_left, delta_right)) / denominator


def compare_window(reference: list[float], candidate: list[float], lo: int, hi: int, max_offset: int) -> dict:
	scores = []
	for offset in range(-max_offset, max_offset + 1):
		ref_values = []
		cand_values = []
		for candidate_frame in range(max(0, lo - offset), min(len(candidate), hi - offset)):
			reference_frame = candidate_frame + offset
			if lo <= reference_frame < hi and reference_frame < len(reference):
				ref_values.append(reference[reference_frame])
				cand_values.append(candidate[candidate_frame])
		correlation = pearson(ref_values, cand_values)
		if correlation is not None:
			scores.append({"capture_minus_candidate_frames": offset, "correlation": correlation, "overlap_frames": len(ref_values)})
	best = max(scores, key=lambda result: result["correlation"]) if scores else None
	return {"range_in_capture_frames": [lo, hi], "best": best, "scores": scores}


def rms_window(values: list[float], start: int, end: int) -> float:
	valid = values[max(0, start):min(len(values), end)]
	if not valid:
		return 0.0
	return math.sqrt(sum(value * value for value in valid) / len(valid))


def compare(reference_path: Path, production_path: Path, candidate_path: Path, candidate_label: str, max_offset: int) -> dict:
	reference_pcm, reference_rate, reference_samples = read_mono_pcm(reference_path)
	production_pcm, production_rate, production_samples = read_mono_pcm(production_path)
	candidate_pcm, candidate_rate, candidate_samples = read_mono_pcm(candidate_path)
	if len({reference_rate, production_rate, candidate_rate}) != 1:
		raise ValueError("All WAVs must use the same sample rate")
	rate = reference_rate
	frame_count = math.ceil(reference_samples * FPS / rate)
	reference_env = [frame_rms(reference_pcm, rate, frame) for frame in range(frame_count)]
	production_env = [frame_rms(production_pcm, rate, frame) for frame in range(math.ceil(production_samples * FPS / rate))]
	candidate_env = [frame_rms(candidate_pcm, rate, frame) for frame in range(math.ceil(candidate_samples * FPS / rate))]

	windows = {
		"first_58_cue": (260, 330),
		"second_68_cue": (360, 410),
		"later_28_sequence": (1038, 1120),
		"later_02_sequence": (1500, 1525),
		"second_58_loop": (4460, 4510),
		"final_68_cue": (4568, 4600),
		"title_stop_and_filter_tail": (4655, 4685),
	}
	comparisons = {}
	for name, (lo, hi) in windows.items():
		comparisons[name] = {
			"production": compare_window(reference_env, production_env, lo, hi, max_offset),
			candidate_label: compare_window(reference_env, candidate_env, lo, hi, max_offset),
		}
	comparisons["overall"] = {
			"production": compare_window(reference_env, production_env, 0, min(4662, len(reference_env)), max_offset),
			candidate_label: compare_window(reference_env, candidate_env, 0, min(4693, len(reference_env)), max_offset),
	}

	stop_rms = {}
	for name, env in (("fceux_reference", reference_env), ("production_rom_driver", production_env), (candidate_label, candidate_env)):
		stop_rms[name] = {
			"per_frame_rms_4658_4685": {str(frame): env[frame] if frame < len(env) else None for frame in range(4658, 4686)},
			"last_frame_rms_above_1_lsb": max((frame for frame, value in enumerate(env) if value > 1.0), default=None),
			"rms_frame_4662": env[4662] if len(env) > 4662 else None,
			"rms_frame_4670": env[4670] if len(env) > 4670 else None,
			"rms_frame_4679": env[4679] if len(env) > 4679 else None,
		}

	return {
		"purpose": "Compare generated ROM-driver WAV envelopes against FCEUX PCM used as validation evidence only; no captured PCM is read by or included in the runtime renderer.",
		"sample_rate_hz": rate,
		"frame_rate_hz": FPS,
		"stop_event": {"title_stop_rom_event_frame": STOP_FRAME, "first_rom_apu_clear_frame": 4662, "fceux_filter_tail_expected_through_frame": 4679},
		"inputs": {
			"fceux_reference": {"path": reference_path.relative_to(ROOT).as_posix(), "sha256": sha256(reference_path), "samples": reference_samples, "frames": len(reference_env)},
			"production_rom_driver": {"path": production_path.relative_to(ROOT).as_posix(), "sha256": sha256(production_path), "samples": production_samples, "frames": len(production_env)},
			candidate_label: {"path": candidate_path.relative_to(ROOT).as_posix(), "sha256": sha256(candidate_path), "samples": candidate_samples, "frames": len(candidate_env), "source": "candidate NSF generated from original ROM driver/sequence bytes; rendered by libgme; diagnostic only"},
		},
		"alignment_method": "Per-frame RMS on 44.1 kHz PCM using 60.0988 Hz frame bins; search relative offsets across a bounded range. Offset convention: capture frame = candidate frame + offset.",
		"maximum_offset_search_frames": max_offset,
		"envelope_comparisons": comparisons,
		"stop_tail": stop_rms,
		"limitations": [
			"Envelope agreement does not establish sample identity, equal analog timbre, or per-sample APU fidelity.",
			"The candidate is still libgme output; it does not port FCEUX WaveHi, NeoFilterSound, or SexyFilter.",
			"This diagnostic comparison does not promote or replace the runtime WAV.",
		],
	}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--reference", type=Path, default=REFERENCE_WAV)
	parser.add_argument("--production", type=Path, default=PRODUCTION_WAV)
	parser.add_argument("--candidate", type=Path, default=DEFAULT_CANDIDATE)
	parser.add_argument("--output", type=Path, default=None)
	parser.add_argument("--max-offset", type=int, default=8)
	parser.add_argument("--candidate-label", default="candidate_plus2_raw")
	args = parser.parse_args()
	output = args.output or args.candidate.with_name("audio_envelope_comparison.json")
	result = compare(args.reference.resolve(), args.production.resolve(), args.candidate.resolve(), args.candidate_label, args.max_offset)
	output.resolve().write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(output.resolve())


if __name__ == "__main__":
	main()

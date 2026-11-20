#!/usr/bin/env python3
"""Compare a Godot AudioServer $55 capture to the retained same-input FCEUX PCM.

The FCEUX PCM is opened only as validation evidence. It is never used to build
or modify a runtime asset. Godot capture output belongs under ignored
reference/diagnostics/audio/ and must not be copied into project runtime assets.
"""

from __future__ import annotations

import argparse
from array import array
import hashlib
import json
import math
from pathlib import Path
import wave


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CAPTURE_DIR = ROOT / "reference/diagnostics/audio/godot_match_track_55_audio_server_20261028"
DEFAULT_CAPTURE_WAV = DEFAULT_CAPTURE_DIR / "godot_match_track_55_audio_server_first.wav"
DEFAULT_CAPTURE_MANIFEST = DEFAULT_CAPTURE_DIR / "godot_match_track_55_audio_server_first.json"
DEFAULT_OUTPUT = DEFAULT_CAPTURE_DIR / "comparison_to_same_input_fceux.json"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def read_wav(path: Path) -> tuple[array, int, int]:
	with wave.open(str(path), "rb") as source:
		channels = source.getnchannels()
		sample_width = source.getsampwidth()
		sample_rate = source.getframerate()
		if sample_width != 2 or channels not in (1, 2):
			raise ValueError(f"Expected mono/stereo signed 16-bit PCM WAV: {path}")
		frame_count = source.getnframes()
		raw = source.readframes(frame_count)
	values = array("h")
	values.frombytes(raw)
	if channels == 1:
		return values, sample_rate, channels
	mono = array("h")
	for index in range(0, len(values), 2):
		mono.append(round((values[index] + values[index + 1]) * 0.5))
	return mono, sample_rate, channels


def metrics(reference: array, candidate: array) -> dict:
	if len(reference) != len(candidate) or not reference:
		raise ValueError("Comparison arrays must be nonempty and have the same length")
	n = len(reference)
	sum_ref = sum_candidate = sum_ref_sq = sum_candidate_sq = sum_product = sum_diff_sq = 0.0
	exact = 0
	for ref, cand in zip(reference, candidate):
		sum_ref += ref
		sum_candidate += cand
		sum_ref_sq += ref * ref
		sum_candidate_sq += cand * cand
		sum_product += ref * cand
		difference = ref - cand
		sum_diff_sq += difference * difference
		exact += ref == cand
	centered_ref = n * sum_ref_sq - sum_ref * sum_ref
	centered_candidate = n * sum_candidate_sq - sum_candidate * sum_candidate
	covariance = n * sum_product - sum_ref * sum_candidate
	denominator = math.sqrt(centered_ref * centered_candidate)
	return {
		"samples": n,
		"pearson_r": covariance / denominator if denominator else None,
		"rmse": math.sqrt(sum_diff_sq / n),
		"mae": sum(abs(ref - cand) for ref, cand in zip(reference, candidate)) / n,
		"exact_samples": exact,
		"exact_fraction": exact / n,
		"reference_rms": math.sqrt(sum_ref_sq / n),
		"candidate_rms": math.sqrt(sum_candidate_sq / n),
		"candidate_over_reference_rms": math.sqrt(sum_candidate_sq / sum_ref_sq) if sum_ref_sq else None,
	}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--capture-wav", type=Path, default=DEFAULT_CAPTURE_WAV)
	parser.add_argument("--capture-manifest", type=Path, default=DEFAULT_CAPTURE_MANIFEST)
	parser.add_argument("--fceux-reference", type=Path, required=True,
		help="Finalized same-input FCEUX route WAV, opened read-only for validation")
	parser.add_argument("--fceux-reference-sha256", required=True,
		help="Expected SHA-256 of the finalized same-input FCEUX route WAV")
	parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
	args = parser.parse_args()

	capture_manifest = json.loads(args.capture_manifest.read_text(encoding="utf-8"))
	if capture_manifest.get("runtime_asset") is not False:
		raise ValueError("Godot output manifest does not mark this PCM as diagnostics-only")
	capture_info = capture_manifest.get("capture", {})
	if capture_info.get("fceux_capture_used") is not False:
		raise ValueError("Capture manifest does not establish FCEUX-independent synthesis")
	if sha256(args.capture_wav) != capture_info.get("output_wav_sha256"):
		raise ValueError("Godot capture WAV hash differs from its manifest")

	expected_reference_sha = args.fceux_reference_sha256
	actual_reference_sha = sha256(args.fceux_reference)
	if actual_reference_sha != expected_reference_sha:
		raise ValueError("FCEUX validation WAV hash differs from its explicitly verified SHA-256")

	candidate, candidate_rate, candidate_channels = read_wav(args.capture_wav)
	reference, reference_rate, reference_channels = read_wav(args.fceux_reference)
	source_path = ROOT / str(capture_manifest.get("source_wav", ""))
	if not source_path.is_file():
		raise ValueError("ROM-derived source WAV from the capture manifest is missing")
	if sha256(source_path) != capture_manifest.get("source_wav_sha256"):
		raise ValueError("ROM-derived source WAV hash differs from the Godot capture manifest")
	source, source_rate, source_channels = read_wav(source_path)
	timing_path = ROOT / str(capture_manifest.get("source_timing_manifest", ""))
	if not timing_path.is_file() or sha256(timing_path) != capture_manifest.get("source_timing_manifest_sha256"):
		raise ValueError("ROM-derived source timing manifest is missing or differs from its capture manifest")
	timing_manifest = json.loads(timing_path.read_text(encoding="utf-8"))
	if timing_manifest.get("schema") != "ct2-rom-cue-wavehi-occurrence-timing-v1" \
			or timing_manifest.get("source_rom_sha256") != capture_manifest.get("source_rom_sha256") \
			or timing_manifest.get("source_audio_path") != capture_manifest.get("source_wav") \
			or timing_manifest.get("source_audio_sha256") != capture_manifest.get("source_wav_sha256"):
		raise ValueError("Capture source timing and WaveHi asset provenance do not agree")
	if candidate_rate != reference_rate or candidate_rate != int(capture_info.get("audio_server_mix_rate_hz", 0)):
		raise ValueError("Capture and FCEUX WAV rates differ; this comparison intentionally does not resample")
	if candidate_rate != source_rate:
		raise ValueError("Godot capture and ROM-derived source WAV rates differ; no resampling is performed")
	playback_timing = capture_manifest.get("playback_timing", {})
	occurrence_index = int(playback_timing.get("occurrence_index", -1))
	timing_occurrences = timing_manifest.get("occurrences", [])
	if occurrence_index < 0 or occurrence_index >= len(timing_occurrences):
		raise ValueError("Godot capture does not identify a known $55 occurrence")
	timing_occurrence = timing_occurrences[occurrence_index]
	asset_window = playback_timing.get("asset_sample_window", [])
	route_window = playback_timing.get("renderer_global_sample_window", [])
	if not isinstance(asset_window, list) or len(asset_window) != 2 \
			or not isinstance(route_window, list) or len(route_window) != 2:
		raise ValueError("Godot capture is missing ROM-derived source sample windows")
	asset_start, asset_end = map(int, asset_window)
	ref_start, ref_end = map(int, route_window)
	if asset_window != timing_occurrence.get("asset_sample_window") \
			or route_window != timing_occurrence.get("renderer_global_sample_window") \
			or int(playback_timing.get("delay_samples", -1)) != int(timing_occurrence.get("delay_samples", -2)) \
			or int(capture_manifest.get("queue_source_frame", -1)) != int(timing_occurrence.get("queue_source_frame", -2)):
		raise ValueError("Godot capture timing differs from the verified ROM $55 occurrence metadata")
	if asset_start < 0 or asset_end <= asset_start or asset_end > len(source) \
			or ref_start < 0 or ref_end <= ref_start or ref_end > len(reference):
		raise ValueError("ROM-derived $55 segment exceeds source PCM or finalized FCEUX route PCM")
	segment = source[asset_start:asset_end]
	first_source_nonzero = next((i for i, sample in enumerate(segment) if sample != 0), -1)
	first_capture_nonzero = int(capture_info.get("first_nonzero_sample_from_capture_start", -1))
	capture_latency = first_capture_nonzero - first_source_nonzero
	if first_source_nonzero < 0 or capture_latency < 0 or capture_latency >= len(candidate):
		raise ValueError("Could not derive a nonnegative AudioServer capture start offset from matching PCM onsets")
	window_length = min(len(candidate) - capture_latency, len(segment), ref_end - ref_start)
	if window_length <= 0:
		raise ValueError("Godot capture contains no samples aligned to the source queue event")
	godot_segment = candidate[capture_latency:capture_latency + window_length]
	source_segment = segment[:window_length]
	fceux_segment = reference[ref_start:ref_start + window_length]
	queue_to_pulse = int(playback_timing.get("delay_samples", -1))
	if queue_to_pulse <= 0:
		raise ValueError("ROM-derived first pulse-register delay is missing from the capture manifest")
	source_to_godot = metrics(source_segment, godot_segment)
	fceux_to_godot = metrics(fceux_segment, godot_segment)
	wavehi_to_fceux = metrics(fceux_segment, source_segment)
	report = {
		"purpose": "Validation-only same-index comparison of the live Godot $55 occurrence against its ROM-derived WaveHi source segment and same-input FCEUX route PCM. Diagnostic captures and FCEUX WAV are not runtime assets or synthesis inputs.",
		"rom_derived_source_wav": {
			"path": source_path.resolve().as_posix(),
			"sha256": sha256(source_path),
			"sample_rate_hz": source_rate,
			"source_channels": source_channels,
			"samples": len(source),
			"comparison_role": "two cue-occurrence segments carved from the ROM CPU/APU/DMC-stepper WaveHi route render; opened read-only for provenance and comparison",
		},
		"godot_audio_server_capture": {
			"path": args.capture_wav.resolve().as_posix(),
			"sha256": sha256(args.capture_wav),
			"sample_rate_hz": candidate_rate,
			"source_channels": candidate_channels,
			"samples": len(candidate),
			"first_nonzero_sample_from_capture_start": first_capture_nonzero,
			"rom_derived_queue_to_first_pulse_register_write_samples": queue_to_pulse,
			"source_pcm_first_nonzero_sample": first_source_nonzero,
			"audio_server_capture_latency_samples": capture_latency,
		},
		"fceux_reference": {
			"path": args.fceux_reference.resolve().as_posix(),
			"sha256": actual_reference_sha,
			"expected_sha256": expected_reference_sha,
			"sample_rate_hz": reference_rate,
			"source_channels": reference_channels,
			"comparison_role": "retained same-input route PCM; read only for validation",
		},
		"compared_window": {
			"route_occurrence": "first $55 request" if occurrence_index == 0 else "restarted $55 request",
			"occurrence_index": occurrence_index,
			"queue_source_frame": int(timing_occurrence["queue_source_frame"]),
			"fceux_source_sample_start": ref_start,
			"fceux_source_sample_end_exclusive": ref_start + window_length,
			"rom_source_asset_sample_start": asset_start,
			"rom_source_asset_sample_end_exclusive": asset_start + window_length,
			"godot_capture_sample_start_after_audio_server_latency": capture_latency,
			"godot_capture_sample_end_exclusive": capture_latency + window_length,
			"samples_compared": window_length,
			"duration_seconds": window_length / candidate_rate,
			"alignment_rule": "Use the route-global ROM source sample window and one AudioServer capture startup offset derived from the first source/capture nonzero samples; no sample-rate conversion, gain fitting, or cross-correlation shift search is applied.",
		"rom_queue_to_first_pulse_register_write_samples": queue_to_pulse,
			"godot_first_nonzero_sample": first_capture_nonzero,
			"audio_server_capture_latency_samples": capture_latency,
		},
		"rom_wavehi_source_to_godot_audio_server_metrics": source_to_godot,
		"same_input_fceux_to_godot_audio_server_metrics": fceux_to_godot,
		"rom_wavehi_source_to_fceux_metrics": wavehi_to_fceux,
		"limitations": [
			f"The {capture_info.get('capture_source_seconds', 'recorded-duration')} second capture covers only the selected $55 occurrence window, not the complete route mix.",
			"The WaveHi candidate and Godot output are not byte-identical to the FCEUX capture; the report records exact fractions and RMSE.",
			"Godot Master-bus output is quantized to mono signed 16-bit PCM for comparison; the capture script records the active mix rate and rejects non-44.1-kHz runs.",
			"The capture uses a ROM-derived occurrence slice only; the FCEUX WAV is opened only by this comparison step.",
		],
	}
	args.output.parent.mkdir(parents=True, exist_ok=True)
	args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({
		"comparison": args.output.as_posix(),
		"rom_wavehi_source_to_godot_audio_server_metrics": source_to_godot,
		"same_input_fceux_to_godot_audio_server_metrics": fceux_to_godot,
		"rom_wavehi_source_to_fceux_metrics": wavehi_to_fceux,
		"audio_server_capture_latency_samples": capture_latency,
	}, indent=2))


if __name__ == "__main__":
	main()

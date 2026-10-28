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
DEFAULT_CAPTURE_WAV = DEFAULT_CAPTURE_DIR / "godot_match_track_55_audio_server.wav"
DEFAULT_CAPTURE_MANIFEST = DEFAULT_CAPTURE_DIR / "godot_match_track_55_audio_server.json"
ONSET_DIAGNOSTIC = ROOT / "reference/diagnostics/audio/route_cue55_onset_candidate_20261027/comparison.json"
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
	parser.add_argument("--fceux-reference", type=Path, default=None,
		help="same-input FCEUX PCM WAV; default is the path retained in the onset comparison JSON")
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

	onset = json.loads(ONSET_DIAGNOSTIC.read_text(encoding="utf-8"))
	if args.fceux_reference is None:
		args.fceux_reference = Path(onset["reference_wav"])
	expected_reference_sha = str(onset["reference_sha256"])
	if sha256(args.fceux_reference) != expected_reference_sha:
		raise ValueError("FCEUX validation WAV hash differs from the retained onset diagnostic")
	first = next(item for item in onset["scenarios"] if item["name"] == "first_request")
	ref_start = int(first["source_start_sample"])
	ref_end = int(first["mute_sample_end_exclusive"])
	queue_to_source_start = int(first["queue_to_source_start_samples"])

	candidate, candidate_rate, candidate_channels = read_wav(args.capture_wav)
	reference, reference_rate, reference_channels = read_wav(args.fceux_reference)
	source_path = ROOT / str(capture_manifest.get("source_wav", ""))
	if not source_path.is_file():
		raise ValueError("ROM-derived source WAV from the capture manifest is missing")
	if sha256(source_path) != capture_manifest.get("source_wav_sha256"):
		raise ValueError("ROM-derived source WAV hash differs from the Godot capture manifest")
	source, source_rate, source_channels = read_wav(source_path)
	if candidate_rate != reference_rate or candidate_rate != int(capture_info.get("audio_server_mix_rate_hz", 0)):
		raise ValueError("Capture and FCEUX WAV rates differ; this comparison intentionally does not resample")
	if candidate_rate != source_rate:
		raise ValueError("Godot capture and ROM-derived source WAV rates differ; no resampling is performed")
	if ref_start >= len(reference) or ref_end > len(reference):
		raise ValueError("FCEUX reference does not contain the first-request comparison window")
	first_nonzero = int(capture_info.get("first_nonzero_sample_from_capture_start", -1))
	playback_timing = capture_manifest.get("playback_timing", {})
	trimmed_leading_zeros = int(playback_timing.get("leading_zero_samples_removed", -1))
	if trimmed_leading_zeros < 0 or trimmed_leading_zeros >= len(source):
		raise ValueError("Capture manifest lacks a valid source-timing-derived zero-trim count")
	if first_nonzero < queue_to_source_start:
		raise ValueError("Godot onset precedes the ROM-derived queue-to-first-pulse delay")
	window_length = min(len(candidate) - queue_to_source_start, ref_end - ref_start)
	if window_length <= 0:
		raise ValueError("Godot capture contains no PCM after its ROM-derived first-pulse position")
	ref_segment = reference[ref_start : ref_start + window_length]
	queue_aligned_segment = candidate[queue_to_source_start : queue_to_source_start + window_length]
	queue_aligned = metrics(ref_segment, queue_aligned_segment)
	onset_length = min(len(candidate) - first_nonzero, ref_end - ref_start)
	if onset_length <= 0:
		raise ValueError("Godot capture contains no PCM after its first nonzero sample")
	onset_aligned = metrics(
		reference[ref_start : ref_start + onset_length],
		candidate[first_nonzero : first_nonzero + onset_length],
	)
	source_length = min(len(candidate) - first_nonzero, len(source) - trimmed_leading_zeros)
	if source_length <= 0:
		raise ValueError("Godot capture or source WAV has no PCM after its documented first cue sample")
	source_to_godot = metrics(
		source[trimmed_leading_zeros : trimmed_leading_zeros + source_length],
		candidate[first_nonzero : first_nonzero + source_length],
	)
	report = {
		"purpose": "Validation-only comparisons of actual Godot AudioServer output against both its ROM-derived source WAV and same-input FCEUX PCM. Diagnostic captures are not runtime assets or synthesis inputs.",
		"rom_derived_source_wav": {
			"path": source_path.resolve().as_posix(),
			"sha256": sha256(source_path),
			"sample_rate_hz": source_rate,
			"source_channels": source_channels,
			"samples": len(source),
			"comparison_role": "ROM-driver/libgme render played by the Godot runtime presenter; opened read-only for provenance and comparison",
		},
		"godot_audio_server_capture": {
			"path": args.capture_wav.resolve().as_posix(),
			"sha256": sha256(args.capture_wav),
			"sample_rate_hz": candidate_rate,
			"source_channels": candidate_channels,
			"samples": len(candidate),
			"first_nonzero_sample_from_capture_start": first_nonzero,
			"rom_derived_queue_to_first_pulse_samples": queue_to_source_start,
		},
		"fceux_reference": {
			"path": args.fceux_reference.resolve().as_posix(),
			"sha256": sha256(args.fceux_reference),
			"sample_rate_hz": reference_rate,
			"source_channels": reference_channels,
			"comparison_role": "retained same-input route PCM; read only for validation",
		},
		"compared_window": {
			"route_occurrence": "first $55 request (source frame 4816)",
			"fceux_source_sample_start": ref_start,
			"fceux_source_sample_end_exclusive": ref_start + window_length,
			"godot_capture_sample_start_at_rom_first_pulse": queue_to_source_start,
			"godot_capture_sample_end_exclusive": queue_to_source_start + window_length,
			"samples_compared": window_length,
			"duration_seconds": window_length / candidate_rate,
			"alignment_rule": "Align capture sample 807 (ROM-derived queue-to-first-pulse delay) to the FCEUX first-pulse sample; no resampling or capture-derived runtime timing is applied.",
			"godot_first_nonzero_sample": first_nonzero,
			"godot_onset_residual_after_rom_first_pulse_samples": first_nonzero - queue_to_source_start,
		},
		"queue_and_source_timing_aligned_metrics": queue_aligned,
		"rom_source_to_godot_audio_server_metrics": {
			"metrics": source_to_godot,
			"source_start_after_rom_timed_trim": trimmed_leading_zeros,
			"godot_capture_start_at_first_nonzero_sample": first_nonzero,
			"alignment_rule": "Compare the source WAV after the manifest-recorded 3,065-sample leading-zero trim to the Godot output beginning at its measured first nonzero sample; no time stretch, resampling, gain fit, or signal processing is used.",
			"limit": "This establishes whether Godot's AudioServer preserves the currently rendered source PCM; it does not establish that the libgme/NSF render matches the FCEUX/real NES APU waveform.",
		},
		"onset_aligned_metrics": {
			"metrics": onset_aligned,
			"candidate_capture_start": first_nonzero,
			"reference_start": ref_start,
			"limit": "Diagnostic waveform-only view after observed Godot onset; this alignment intentionally omits the queue-to-audible residual reported above.",
		},
		"limitations": [
			"This is a direct cue-presenter capture, not a full route or physical NES measurement.",
			"Godot Master-bus output is quantized to mono signed 16-bit PCM for comparison; the capture script records the active mix rate and rejects non-44.1-kHz runs.",
			"The capture was generated from ROM-derived cue PCM only; the FCEUX WAV is opened only by this comparison step.",
		],
	}
	args.output.parent.mkdir(parents=True, exist_ok=True)
	args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({
		"comparison": args.output.as_posix(),
		"rom_source_to_godot_audio_server_metrics": source_to_godot,
		"queue_and_source_timing_aligned_metrics": queue_aligned,
		"onset_aligned_metrics": onset_aligned,
		"godot_onset_residual_after_rom_first_pulse_samples": first_nonzero - queue_to_source_start,
	}, indent=2))


if __name__ == "__main__":
	main()

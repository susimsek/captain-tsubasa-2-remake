#!/usr/bin/env python3
"""Compare the shipped opening WAV to same-input FCEUX PCM for diagnostics only."""

from __future__ import annotations

import argparse
from array import array
import hashlib
import io
import json
import math
from pathlib import Path
import wave

ROOT = Path(__file__).resolve().parents[2]
FPS = 60.0988
SAMPLE_RATE = 44_100
RUNTIME = ROOT / "assets/opening/audio/opening_timeline_rom_driver.wav"
REFERENCE = ROOT / "reference/diagnostics/audio/fceux_cold_start_silent_pcm_precise_20261024.wav"
OUTPUT = ROOT / "reference/diagnostics/audio/runtime_wav_fceux_pcm_comparison_20261024.json"
WINDOWS = {
    "first_music_pre_dmc": (283, 366),
    "first_dmc_music": (367, 450),
    "later_28_sequence": (1038, 1120),
    "later_02_sequence": (1500, 1525),
    "late_58_loop": (4460, 4510),
    "final_68_cue": (4568, 4600),
    "last_shared_pre_stop": (4655, 4661),
}
ENVELOPE_WINDOWS = {
    "first_music": (260, 330),
    "second_cue": (360, 410),
    "28_cue_1": (1038, 1060),
    "28_cue_2": (1058, 1080),
    "28_cue_3": (1098, 1120),
    "02_cue": (1500, 1525),
    "0E_cue": (1770, 1795),
    "09_cue": (1830, 1855),
    "07_cue": (2360, 2390),
    "late_58_loop": (4460, 4510),
    "final_68_cue": (4568, 4600),
    "pre_stop": (4630, 4661),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_pcm(path: Path) -> array:
    with wave.open(str(path), "rb") as wav:
        if (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) != (1, 2, SAMPLE_RATE):
            raise ValueError(f"expected 44.1 kHz mono signed 16-bit PCM: {path}")
        values = array("h")
        values.frombytes(wav.readframes(wav.getnframes()))
        return values


def pearson(left: list[float], right: list[float]) -> float | None:
    if len(left) != len(right) or len(left) < 2:
        return None
    sum_left = sum_right = sum_left2 = sum_right2 = sum_product = 0.0
    for a, b in zip(left, right):
        sum_left += a
        sum_right += b
        sum_left2 += a * a
        sum_right2 += b * b
        sum_product += a * b
    n = len(left)
    covariance = n * sum_product - sum_left * sum_right
    variance_left = n * sum_left2 - sum_left * sum_left
    variance_right = n * sum_right2 - sum_right * sum_right
    denominator = math.sqrt(variance_left * variance_right)
    return covariance / denominator if denominator else None


def frame_rms(samples: array) -> list[float]:
    frame_count = math.ceil(len(samples) * FPS / SAMPLE_RATE)
    values = []
    for frame in range(frame_count):
        start = round(frame * SAMPLE_RATE / FPS)
        end = min(len(samples), round((frame + 1) * SAMPLE_RATE / FPS))
        part = samples[start:end]
        values.append(math.sqrt(sum(sample * sample for sample in part) / len(part)) if part else 0.0)
    return values


def compare_window(reference: array, runtime: array, name: str, frames: tuple[int, int]) -> dict:
    frame_start, frame_end = frames
    lo = round(frame_start * SAMPLE_RATE / FPS)
    hi = min(len(reference), len(runtime), round(frame_end * SAMPLE_RATE / FPS))
    if hi <= lo:
        raise ValueError(f"window has no common samples: {name}")
    reference_segment = list(reference[lo:hi])
    direct_runtime = list(runtime[lo:hi])

    sample_candidates = []
    for offset in range(-2, 3):
        candidate_start = lo - round(offset * SAMPLE_RATE / FPS)
        candidate_end = candidate_start + (hi - lo)
        if candidate_start < 0 or candidate_end > len(runtime):
            continue
        candidate = list(runtime[candidate_start:candidate_end])
        sample_candidates.append({
            "offset_frames": offset,
            "correlation": pearson(reference_segment, candidate),
        })
    best_sample = max(sample_candidates, key=lambda item: item["correlation"] or -2.0)

    sum_ref2 = sum(sample * sample for sample in reference_segment)
    sum_run2 = sum(sample * sample for sample in direct_runtime)
    sum_diff2 = sum((left - right) ** 2 for left, right in zip(reference_segment, direct_runtime))
    ref_rms_value = math.sqrt(sum_ref2 / len(reference_segment))
    return {
        "range_frames_end_exclusive": [frame_start, frame_end],
        "common_sample_range": [lo, hi],
        "sample_count": hi - lo,
        "same_index_sample_correlation": pearson(reference_segment, direct_runtime),
        "same_index_runtime_over_fceux_rms": math.sqrt(sum_run2 / sum_ref2) if sum_ref2 else None,
        "same_index_normalized_rmse": math.sqrt(sum_diff2 / len(reference_segment)) / ref_rms_value if ref_rms_value else None,
        "best_sample_correlation_over_integer_frame_offsets": best_sample,
        "sample_correlations_by_frame_offset": sample_candidates,
    }


def compare_envelope_window(reference_rms: list[float], runtime_rms: list[float],
                            frames: tuple[int, int]) -> dict:
    frame_start, frame_end = frames
    candidates = []
    for offset in range(-3, 4):
        fceux_values = []
        runtime_values = []
        for frame in range(frame_start, frame_end):
            runtime_frame = frame - offset
            if 0 <= frame < len(reference_rms) and 0 <= runtime_frame < len(runtime_rms):
                fceux_values.append(reference_rms[frame])
                runtime_values.append(runtime_rms[runtime_frame])
        candidates.append({"offset_frames": offset, "correlation": pearson(fceux_values, runtime_values)})
    best = max(candidates, key=lambda item: item["correlation"] or -2.0)
    return {
        "range_frames_end_exclusive": [frame_start, frame_end],
        "best_alignment": best,
        "correlations_by_offset": candidates,
    }


def source_provenance(runtime_path: Path) -> dict:
    manifest_path = runtime_path.with_suffix(".json")
    if not manifest_path.exists():
        return {"runtime_manifest_present": False}
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    relative_nsf = str(manifest.get("source_nsf", ""))
    nsf_path = ROOT / relative_nsf
    if not nsf_path.is_file():
        return {
            "runtime_manifest_present": True,
            "runtime_manifest_path": manifest_path.relative_to(ROOT).as_posix(),
            "runtime_manifest_sha256": sha256(manifest_path),
            "source_nsf_path": relative_nsf,
            "source_nsf_file_present": False,
        }
    nsf_sha = sha256(nsf_path)
    build_manifest_path = nsf_path.with_suffix(".json")
    build_manifest = json.loads(build_manifest_path.read_text(encoding="utf-8")) if build_manifest_path.exists() else {}
    runtime_events = sorted(
        (int(event["frame"]), int(str(event["sound_id"]), 16))
        for event in manifest.get("source_command_frames", [])
    )
    build_events = sorted(
        (int(event["frame"]), int(event["sound_id"]))
        for event in build_manifest.get("observed_events", [])
    )
    trace_nsf_path = ROOT / "reference/diagnostics/audio/rom_driver_apu_trace_20261024/opening_timeline_rom_driver.nsf"
    preserved_nsfs = sorted(ROOT.rglob("*.nsf"))
    manifest_nsf_hash = str(manifest.get("source_nsf_sha256", ""))
    matching_nsfs = [path.relative_to(ROOT).as_posix() for path in preserved_nsfs if sha256(path) == manifest_nsf_hash]
    intermediate_path = ROOT / "tools/audio/build/opening_timeline_unaligned.wav"
    intermediate_reproduction = {"present": intermediate_path.is_file()}
    if intermediate_path.is_file():
        with wave.open(str(intermediate_path), "rb") as source_wav:
            source_params = (source_wav.getnchannels(), source_wav.getsampwidth(), source_wav.getframerate())
            source_pcm = source_wav.readframes(source_wav.getnframes())
            source_sample_count = source_wav.getnframes()
        shift_frames = int(manifest.get("libgme_alignment_shift_frames", 0))
        shift_samples = round(shift_frames * SAMPLE_RATE / FPS)
        output_samples = int(manifest.get("audio_samples", 0))
        pcm_start = shift_samples * source_params[0] * source_params[1]
        pcm_end = (shift_samples + output_samples) * source_params[0] * source_params[1]
        cropped_pcm = source_pcm[pcm_start:pcm_end]
        candidate_buffer = io.BytesIO()
        with wave.open(candidate_buffer, "wb") as output_wav:
            output_wav.setnchannels(source_params[0])
            output_wav.setsampwidth(source_params[1])
            output_wav.setframerate(source_params[2])
            output_wav.writeframes(cropped_pcm)
        reconstructed_hash = hashlib.sha256(candidate_buffer.getvalue()).hexdigest()
        intermediate_reproduction = {
            "present": True,
            "path": intermediate_path.relative_to(ROOT).as_posix(),
            "sha256": sha256(intermediate_path),
            "sample_count": source_sample_count,
            "alignment_shift_frames": shift_frames,
            "alignment_shift_samples": shift_samples,
            "output_samples": output_samples,
            "reconstructed_wav_sha256": reconstructed_hash,
            "matches_shipped_runtime_asset": reconstructed_hash == sha256(runtime_path),
        }
    return {
        "runtime_manifest_present": True,
        "runtime_manifest_path": manifest_path.relative_to(ROOT).as_posix(),
        "runtime_manifest_sha256": sha256(manifest_path),
        "runtime_manifest_source_nsf_sha256": str(manifest.get("source_nsf_sha256", "")),
        "source_nsf_manifest_hash_found_in_preserved_candidates": bool(matching_nsfs),
        "matching_preserved_nsf_candidates": matching_nsfs,
        "source_nsf_path": relative_nsf,
        "current_source_nsf_sha256": nsf_sha,
        "runtime_manifest_source_nsf_hash_matches_current_file": str(manifest.get("source_nsf_sha256", "")) == nsf_sha,
        "current_source_nsf_matches_apu_trace_copy": trace_nsf_path.is_file() and sha256(trace_nsf_path) == nsf_sha,
        "current_build_manifest_nsf_sha256": str(build_manifest.get("nsf_sha256", "")),
        "runtime_event_schedule_matches_current_build_manifest": runtime_events == build_events,
        "runtime_event_schedule_count": len(runtime_events),
        "current_build_event_count": len(build_events),
        "runtime_events": [{"frame": frame, "sound_id": f"0x{sound_id:02X}"} for frame, sound_id in runtime_events],
        "preserved_intermediate_reproduction": intermediate_reproduction,
    }


def build_report(reference_path: Path, runtime_path: Path) -> dict:
    reference = read_pcm(reference_path)
    runtime = read_pcm(runtime_path)
    ref_rms = frame_rms(reference)
    run_rms = frame_rms(runtime)
    windows = {
        name: compare_window(reference, runtime, name, frames)
        for name, frames in WINDOWS.items()
    }
    envelope_windows = {
        name: compare_envelope_window(ref_rms, run_rms, frames)
        for name, frames in ENVELOPE_WINDOWS.items()
    }
    sample_delta = len(reference) - len(runtime)
    return {
        "purpose": "Validation-only comparison of the shipped ROM-driver WAV against same-input FCEUX PCM. Captured PCM is never used to generate or replace the runtime asset.",
        "source_rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
        "settings": {"sample_rate_hz": SAMPLE_RATE, "frame_rate_hz": FPS, "offset_convention": "FCEUX frame = runtime frame + relative offset; offset -1 means runtime envelope is one frame later"},
        "inputs": {
            "fceux_pcm_reference": {
                "path": reference_path.relative_to(ROOT).as_posix(),
                "sha256": sha256(reference_path),
                "samples": len(reference),
                "role": "comparison only; precise FCEUX 2.7.0 same-input capture",
            },
            "godot_runtime_wav": {
                "path": runtime_path.relative_to(ROOT).as_posix(),
                "sha256": sha256(runtime_path),
                "samples": len(runtime),
                "role": "shipped runtime asset; ROM-driver NSF/libgme render",
            },
        },
        "source_provenance": source_provenance(runtime_path),
        "duration_gap": {
            "reference_minus_runtime_samples": sample_delta,
            "milliseconds": sample_delta * 1000.0 / SAMPLE_RATE,
            "nes_frames": sample_delta * FPS / SAMPLE_RATE,
            "runtime_ends_at_source_frame": 4661,
            "fceux_reference_frame_capture_ends_at": 4692,
            "interpretation": "The runtime WAV stops on the captured Start/ROM stop frame and omits the filtered FCEUX tail; FCEUX PCM remains above 1-LSB peak through frame 4679, then includes additional silent capture frames.",
        },
        "sample_windows": windows,
        "cue_envelope_alignment": envelope_windows,
        "limits": [
            "Frame-envelope alignment is a measured replay comparison, not proof that the source-command VM timing is correct for arbitrary input.",
            "Sample correlations compare different renderer implementations (libgme runtime versus FCEUX APU/mixer/filter); they quantify the current waveform gap but do not alone identify which circuit or filter parameter causes it.",
            "The final window is clipped to the runtime asset's common range; it cannot measure the omitted FCEUX tail beyond frame 4661.",
        ],
        "runtime_asset_changed": False,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path, default=REFERENCE)
    parser.add_argument("--runtime", type=Path, default=RUNTIME)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    reference = args.reference.resolve()
    runtime = args.runtime.resolve()
    output = args.output.resolve()
    report = build_report(reference, runtime)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(output)
    for name, window in report["sample_windows"].items():
        best_sample = window["best_sample_correlation_over_integer_frame_offsets"]
        print(
            f"{name}: same-index sample r={window['same_index_sample_correlation']:.4f}; "
            f"best sample offset={best_sample['offset_frames']} r={best_sample['correlation']:.4f}"
        )
    for name, window in report["cue_envelope_alignment"].items():
        best = window["best_alignment"]
        print(f"{name}: envelope offset={best['offset_frames']} r={best['correlation']:.4f}")


if __name__ == "__main__":
    main()

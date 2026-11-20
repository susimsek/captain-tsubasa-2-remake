#!/usr/bin/env python3
"""Build the ROM-only audio context from the first $55 queue through the menu.

This packages the WaveHi renderer's uninterrupted route PCM. Later BGM/SFX
queue events remain live metadata in Godot, but their audio is already mixed
into this source-proven route segment. No captured emulator audio is read.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import wave


ROOT = Path(__file__).resolve().parents[2]
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_INPUT_SHA256 = "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
SAMPLE_RATE = 44_100
CPU_HZ = 1_789_773
DEFAULT_BASE = Path("/tmp/ct2_first_match_audio_nmi2_20261109")
OUT_DIR = ROOT / "assets/gameplay/audio"
WAV_NAME = "first_command_menu_route_wavehi_rom_generated.wav"
CUE_MANIFEST_NAME = "first_command_menu_route_wavehi_rom_generated.json"
TIMING_MANIFEST_NAME = "first_command_menu_route_wavehi_source_timing_rom_generated.json"


def digest_bytes(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def digest_file(path: Path) -> str:
	return digest_bytes(path.read_bytes())


def read_json(path: Path) -> dict:
	value = json.loads(path.read_text(encoding="utf-8"))
	if not isinstance(value, dict):
		raise ValueError(f"Expected a JSON object: {path}")
	return value


def sample_index(cycle: int, renderer_phase_samples: int) -> int:
	return round(cycle * SAMPLE_RATE / CPU_HZ) - renderer_phase_samples


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--base", type=Path, default=DEFAULT_BASE)
	parser.add_argument("--output-dir", type=Path, default=OUT_DIR)
	parser.add_argument("--renderer-phase-samples", type=int, default=25)
	args = parser.parse_args()
	base = args.base.resolve()
	stepper_dir = base / "stepper"
	candidate = base / "wavehi/rom_stepper_wavehi_candidate.wav"
	candidate_report_path = base / "wavehi/candidate_report.json"
	stepper_report_path = stepper_dir / "source_stepper_report.json"
	queue_path = stepper_dir / "source_sound_queue_nonzero_writes.csv"
	frame_path = stepper_dir / "source_frame_cycles.csv"
	candidate_report = read_json(candidate_report_path)
	stepper_report = read_json(stepper_report_path)
	if candidate_report.get("source", {}).get("rom_sha256") != EXPECTED_ROM_SHA256 \
			or stepper_report.get("source_rom_sha256") != EXPECTED_ROM_SHA256:
		raise ValueError("Candidate and stepper do not identify the checked ROM revision")
	if stepper_report.get("input_timeline_sha256") != EXPECTED_INPUT_SHA256 \
			or candidate_report.get("source", {}).get("explicit_controller_input_timeline", {}).get("sha256") != EXPECTED_INPUT_SHA256:
		raise ValueError("Candidate does not use the checked recorded route input")
	if candidate_report.get("candidate", {}).get("runtime_asset") is not False \
			or candidate_report.get("source", {}).get("fceux_trace_used_for_scheduling") is not False \
			or candidate_report.get("source", {}).get("captured_pcm_or_wav_used_as_synthesis_input") is not False \
			or candidate_report.get("source", {}).get("captured_fceux_pcm_or_wav_used_as_synthesis_input") is not False:
		raise ValueError("WaveHi source report does not exclude captures from synthesis")
	if candidate_report.get("candidate", {}).get("sha256") != digest_file(candidate):
		raise ValueError("WaveHi candidate differs from its report")
	queue_hash = digest_file(queue_path)
	if stepper_report.get("outputs", {}).get(queue_path.name) != queue_hash:
		raise ValueError("Queue-event CSV differs from the source-stepper report")
	for filename in ("source_apu_writes.csv", "source_dmc_dma_reads.csv", "source_frame_cycles.csv"):
		file_hash = digest_file(stepper_dir / filename)
		if stepper_report.get("outputs", {}).get(filename) != file_hash \
				or candidate_report.get("source", {}).get("stepper_output_sha256", {}).get(filename) != file_hash:
			raise ValueError(f"WaveHi candidate does not match stepper output {filename}")
	queue_events: list[dict[str, object]] = []
	with queue_path.open(newline="", encoding="utf-8") as queue_file:
		for row in csv.DictReader(queue_file):
			queue_events.append({
				"source_frame": int(row["source_frame"]),
				"source_cycle": int(row["cycle"]),
				"pc": row["pc"],
				"queue_id": int(row["value"].replace("$", "0x"), 16),
			})
	first_55 = [event for event in queue_events if event["queue_id"] == 0x55 and event["source_frame"] == 4816]
	if len(first_55) != 1:
		raise ValueError("Expected one ROM-derived first $55 event at frame 4816")
	start_event = first_55[0]
	frame_cycles: dict[int, dict[str, int]] = {}
	with frame_path.open(newline="", encoding="utf-8") as frame_file:
		for row in csv.DictReader(frame_file):
			frame_cycles[int(row["source_frame"])] = {"start": int(row["cycle_start"]), "end": int(row["cycle_end"])}
	if 8953 not in frame_cycles:
		raise ValueError("ROM source route lacks the first-command-menu endpoint frame")
	with wave.open(str(candidate), "rb") as source:
		if (source.getnchannels(), source.getsampwidth(), source.getframerate()) != (1, 2, SAMPLE_RATE):
			raise ValueError("WaveHi candidate must be mono s16 at 44.1 kHz")
		candidate_pcm = source.readframes(source.getnframes())
		candidate_samples = source.getnframes()
	start_sample = sample_index(int(start_event["source_cycle"]), args.renderer_phase_samples)
	verification_end_sample = sample_index(frame_cycles[8953]["end"], args.renderer_phase_samples)
	if start_sample < 0 or verification_end_sample <= start_sample or verification_end_sample > candidate_samples:
		raise ValueError("The queue-to-menu source PCM range is invalid")
	segment = candidate_pcm[start_sample * 2:]
	if len(segment) % 2 or not segment:
		raise ValueError("ROM source route segment is empty or malformed")
	stop_events = [event for event in queue_events if event["queue_id"] == 0x01 and 4816 < int(event["source_frame"]) <= 8953]
	bounds_aliases = [{
		"source_route_callback_frame": 8458,
		"stepper_queue_store_frame": 8460,
		"queue_id": "$01",
		"basis": "Live `$DAAA->$CBF1->$CC01` callback receipt uses route source frame 8458; ROM-only queue store lands on frame 8460.",
	}]
	embedded_bgm = [event for event in queue_events if event["queue_id"] in (0x55, 0x53, 0x3C) and int(event["source_frame"]) > 4816 and int(event["source_frame"]) <= 8953]
	embedded_sfx = [event for event in queue_events if event["queue_id"] in (0x66, 0x2B, 0x2C) and int(event["source_frame"]) <= 8953]
	args.output_dir.mkdir(parents=True, exist_ok=True)
	wav_path = args.output_dir / WAV_NAME
	with wave.open(str(wav_path), "wb") as output:
		output.setnchannels(1)
		output.setsampwidth(2)
		output.setframerate(SAMPLE_RATE)
		output.writeframes(segment)
	wav_hash = digest_file(wav_path)
	occurrence = {
		"occurrence_index": 0,
		"queue_id": "$55",
		"queue_source_frame": int(start_event["source_frame"]),
		"queue_source_cycle": int(start_event["source_cycle"]),
		"source_end": {"kind": "source_render_end", "source_frame": 9042, "sample_index": candidate_samples},
		"renderer_global_sample_window": [start_sample, candidate_samples],
		"asset_sample_window": [0, len(segment) // 2],
		"verification_global_sample_window": [start_sample, verification_end_sample],
		"verification_asset_sample_window": [0, verification_end_sample - start_sample],
		"verification_sample_count": verification_end_sample - start_sample,
		"stop_tail_source_frames": [int(event["source_frame"]) for event in stop_events] + [8458],
		"stop_tail_queue_events": [{"source_frame": int(event["source_frame"]), "source_cycle": int(event["source_cycle"]), "queue_id": "$01"} for event in stop_events],
		"runtime_stop_frame_aliases": bounds_aliases,
		"embedded_bgm_queue_events": [{"source_frame": int(event["source_frame"]), "source_cycle": int(event["source_cycle"]), "queue_id": f"${int(event['queue_id']):02X}"} for event in embedded_bgm],
		"embedded_queue_events": [{"source_frame": int(event["source_frame"]), "source_cycle": int(event["source_cycle"]), "queue_id": f"${int(event['queue_id']):02X}"} for event in embedded_sfx],
	}
	cue_manifest = {
		"schema": "ct2-rom-route-wavehi-context-v1",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"cue": "0x55",
		"cue_kind": "bgm",
		"source_input_timeline_sha256": EXPECTED_INPUT_SHA256,
		"source_candidate_sha256": candidate_report["candidate"]["sha256"],
		"source_candidate_report_sha256": digest_file(candidate_report_path),
		"source_stepper_report_sha256": digest_file(stepper_report_path),
		"source_queue_csv_sha256": queue_hash,
		"renderer": "ROM-only 6502/APU/DMC stepper rendered with pinned FCEUX 2.7.0 WaveHi/SexyFilter semantics; queue cycles and input come from the verified ROM source route",
		"wav": f"assets/gameplay/audio/{wav_path.name}",
		"wav_sha256": wav_hash,
		"sample_rate": SAMPLE_RATE,
		"channels": 1,
		"bits_per_sample": 16,
		"sample_count": len(segment) // 2,
		"capture_used": False,
		"captured_pcm_used": False,
		"captured_wav_used": False,
		"fceux_trace_used_for_scheduling": False,
		"runtime_needs_rom_or_emulator": False,
		"source_note": "Begins at the first ROM `$55` queue event and preserves the ROM-stepper mixed output, later BGM transitions, overlapping effects, and source tail. Later queue events remain visible to the presenter but are not played twice. Emulator captures are validation evidence only.",
	}
	cue_path = args.output_dir / CUE_MANIFEST_NAME
	cue_path.write_text(json.dumps(cue_manifest, indent=2) + "\n", encoding="utf-8")
	timing_manifest = {
		"schema": "ct2-rom-cue-wavehi-route-context-timing-v1",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"cue": "$55",
		"source_audio_path": cue_manifest["wav"],
		"source_audio_sha256": wav_hash,
		"source_input_timeline_sha256": EXPECTED_INPUT_SHA256,
		"source_candidate_sha256": candidate_report["candidate"]["sha256"],
		"source_candidate_report_sha256": digest_file(candidate_report_path),
		"source_queue_csv_sha256": queue_hash,
		"sample_rate_hz": SAMPLE_RATE,
		"channels": 1,
		"bits_per_sample": 16,
		"source_pcm_sample_count": len(segment) // 2,
		"ntsc_cpu_hz": CPU_HZ,
		"wavehi_renderer_phase_samples": args.renderer_phase_samples,
		"wavehi_sample_index_formula": f"round(source_cycle * 44100 / 1789773) - {args.renderer_phase_samples}",
		"captured_pcm_used": False,
		"captured_wav_used": False,
		"capture_used_as_event_input": False,
		"runtime_needs_rom_or_emulator": False,
		"occurrences": [occurrence],
	}
	timing_path = args.output_dir / TIMING_MANIFEST_NAME
	timing_path.write_text(json.dumps(timing_manifest, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({
		"wav": str(wav_path),
		"wav_sha256": wav_hash,
		"segment_samples": len(segment) // 2,
		"verification_samples": verification_end_sample - start_sample,
		"source_global_window": [start_sample, candidate_samples],
		"verification_source_global_window": [start_sample, verification_end_sample],
		"embedded_bgm_count": len(embedded_bgm),
		"embedded_sfx_count": len(embedded_sfx),
		"timing_manifest": str(timing_path),
		"captured_audio_used": False,
	}, indent=2))


if __name__ == "__main__":
	main()

#!/usr/bin/env python3
"""Package route-context music segments from the ROM-only WaveHi render.

The WaveHi candidate is generated from the ROM CPU/APU/DMC stepper. Queue
cycles identify segment boundaries; emulator captures are validation-only and
are never opened by this builder.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import wave


ROOT = Path(__file__).resolve().parents[2]
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
INPUT_SHA256 = "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
SAMPLE_RATE = 44_100
CPU_HZ = 1_789_773
DEFAULT_BASE = Path("/tmp/ct2_first_match_audio_nmi2_20261109")
OUT_DIR = ROOT / "assets/gameplay/audio"


def sha256_bytes(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
	return sha256_bytes(path.read_bytes())


def read_json(path: Path) -> dict:
	value = json.loads(path.read_text(encoding="utf-8"))
	if not isinstance(value, dict):
		raise ValueError(f"Expected a JSON object: {path}")
	return value


def sample_at_cycle(cycle: int, phase_samples: int) -> int:
	return round(cycle * SAMPLE_RATE / CPU_HZ) - phase_samples


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
	queue_csv = stepper_dir / "source_sound_queue_nonzero_writes.csv"
	candidate_report = read_json(candidate_report_path)
	stepper_report = read_json(stepper_report_path)
	if candidate_report.get("source", {}).get("rom_sha256") != ROM_SHA256 \
			or stepper_report.get("source_rom_sha256") != ROM_SHA256:
		raise ValueError("ROM-only candidate and stepper do not identify the expected ROM")
	if candidate_report.get("source", {}).get("captured_pcm_or_wav_used_as_synthesis_input") is not False \
			or candidate_report.get("source", {}).get("captured_fceux_pcm_or_wav_used_as_synthesis_input") is not False \
			or candidate_report.get("source", {}).get("fceux_trace_used_for_scheduling") is not False:
		raise ValueError("Candidate report does not exclude emulator captures from synthesis")
	if candidate_report.get("candidate", {}).get("runtime_asset") is not False:
		raise ValueError("Expected a diagnostic-only ROM-source WaveHi candidate")
	if stepper_report.get("input_timeline_sha256") != INPUT_SHA256 \
			or candidate_report.get("source", {}).get("explicit_controller_input_timeline", {}).get("sha256") != INPUT_SHA256:
		raise ValueError("Source candidate does not use the verified route input timeline")
	queue_digest = sha256_file(queue_csv)
	if stepper_report.get("outputs", {}).get(queue_csv.name) != queue_digest:
		raise ValueError("Queue CSV differs from the ROM-stepper output manifest")
	if candidate_report.get("candidate", {}).get("sha256") != sha256_file(candidate):
		raise ValueError("WaveHi bytes differ from their candidate report")
	for output_name in ("source_apu_writes.csv", "source_dmc_dma_reads.csv", "source_frame_cycles.csv"):
		actual = sha256_file(stepper_dir / output_name)
		if stepper_report.get("outputs", {}).get(output_name) != actual \
				or candidate_report.get("source", {}).get("stepper_output_sha256", {}).get(output_name) != actual:
			raise ValueError(f"Candidate differs from source-stepper output {output_name}")
	with wave.open(str(candidate), "rb") as source_wav:
		if (source_wav.getnchannels(), source_wav.getsampwidth(), source_wav.getframerate()) != (1, 2, SAMPLE_RATE):
			raise ValueError("WaveHi candidate must be mono signed-16-bit PCM at 44.1 kHz")
		candidate_pcm = source_wav.readframes(source_wav.getnframes())
		sample_count = source_wav.getnframes()
	queue_rows: list[dict[str, object]] = []
	with queue_csv.open(newline="", encoding="utf-8") as queue_file:
		for row in csv.DictReader(queue_file):
			queue_rows.append({
				"source_frame": int(row["source_frame"]),
				"source_cycle": int(row["cycle"]),
				"pc": row["pc"],
				"queue_id": int(row["value"].replace("$", "0x"), 16),
			})

	def unique_event(queue_id: int, source_frame: int) -> dict[str, object]:
		matches = [row for row in queue_rows if row["queue_id"] == queue_id and row["source_frame"] == source_frame]
		if len(matches) != 1:
			raise ValueError(f"Expected exactly one ROM queue ${queue_id:02X} at frame {source_frame}")
		return matches[0]

	start_53 = unique_event(0x53, 8271)
	stop_53_a = unique_event(0x01, 8443)
	stop_53_b = unique_event(0x01, 8460)
	start_3c = unique_event(0x3C, 8607)
	if not (int(start_53["source_cycle"]) < int(stop_53_a["source_cycle"]) < int(stop_53_b["source_cycle"]) < int(start_3c["source_cycle"])):
		raise ValueError("$53 source queue and stop order changed")
	phase = args.renderer_phase_samples
	s53_start = sample_at_cycle(int(start_53["source_cycle"]), phase)
	s3c_start = sample_at_cycle(int(start_3c["source_cycle"]), phase)
	frame_cycles: dict[int, dict[str, int]] = {}
	with (stepper_dir / "source_frame_cycles.csv").open(newline="", encoding="utf-8") as frame_file:
		for row in csv.DictReader(frame_file):
			frame_cycles[int(row["source_frame"])] = {
				"start": int(row["cycle_start"]),
				"end": int(row["cycle_end"]),
			}
	if 8953 not in frame_cycles:
		raise ValueError("The source stepper did not record the first command-menu endpoint frame")
	verification_end = sample_at_cycle(frame_cycles[8953]["end"], phase)
	if s53_start < 0 or s3c_start <= s53_start or s3c_start >= sample_count \
			or verification_end <= s3c_start or verification_end > sample_count:
		raise ValueError("ROM source queue cycle mapped outside the WaveHi render")

	assets = [
		{
			"queue_id": 0x53,
			"queue_event": start_53,
			"global_window": [s53_start, sample_count],
			"verification_global_window": [s53_start, verification_end],
			"source_end": {"kind": "source_render_end", "source_frame": 9042, "sample_index": sample_count},
			"tail_stop_events": [stop_53_a, stop_53_b],
			"embedded_bgm_events": [start_3c],
			"embedded_events": [unique_event(0x66, 8624), unique_event(0x2B, 8664), unique_event(0x2C, 8786)],
			"wav_name": "match_track_53_wavehi_route_context_rom_generated.wav",
			"cue_name": "match_track_53_wavehi_route_context_rom_generated.json",
			"timing_name": "match_track_53_wavehi_route_context_timing_rom_generated.json",
		},
		{
			"queue_id": 0x3C,
			"queue_event": start_3c,
			"global_window": [s3c_start, sample_count],
			"verification_global_window": [s3c_start, verification_end],
			"source_end": {"kind": "source_render_end", "source_frame": 9042, "sample_index": sample_count},
			"tail_stop_events": [],
			"embedded_events": [
				unique_event(0x66, 8624),
				unique_event(0x2B, 8664),
				unique_event(0x2C, 8786),
			],
			"wav_name": "match_track_3C_wavehi_route_context_rom_generated.wav",
			"cue_name": "match_track_3C_wavehi_route_context_rom_generated.json",
			"timing_name": "match_track_3C_wavehi_route_context_timing_rom_generated.json",
		},
	]
	args.output_dir.mkdir(parents=True, exist_ok=True)
	built: list[dict[str, object]] = []	
	for asset in assets:
		global_start, global_end = asset["global_window"]
		pcm = candidate_pcm[int(global_start) * 2:int(global_end) * 2]
		if len(pcm) != (int(global_end) - int(global_start)) * 2:
			raise ValueError(f"PCM slice for ${int(asset['queue_id']):02X} was truncated")
		wav_path = args.output_dir / str(asset["wav_name"])
		with wave.open(str(wav_path), "wb") as out:
			out.setnchannels(1)
			out.setsampwidth(2)
			out.setframerate(SAMPLE_RATE)
			out.writeframes(pcm)
		wav_hash = sha256_file(wav_path)
		queue_event = asset["queue_event"]
		occurrence = {
			"occurrence_index": 0,
			"queue_id": f"${int(asset['queue_id']):02X}",
			"queue_source_frame": int(queue_event["source_frame"]),
			"queue_source_cycle": int(queue_event["source_cycle"]),
			"source_end": asset["source_end"],
			"renderer_global_sample_window": [int(global_start), int(global_end)],
			"asset_sample_window": [0, int(global_end) - int(global_start)],
			"stop_tail_source_frames": [int(event["source_frame"]) for event in asset["tail_stop_events"]],
			"stop_tail_queue_events": [{"source_frame": int(event["source_frame"]), "source_cycle": int(event["source_cycle"]), "queue_id": "$01"} for event in asset["tail_stop_events"]],
			"embedded_queue_events": [{"source_frame": int(event["source_frame"]), "source_cycle": int(event["source_cycle"]), "queue_id": f"${int(event['queue_id']):02X}"} for event in asset["embedded_events"]],
			"embedded_bgm_queue_events": [{"source_frame": int(event["source_frame"]), "source_cycle": int(event["source_cycle"]), "queue_id": f"${int(event['queue_id']):02X}"} for event in asset.get("embedded_bgm_events", [])],
			"verification_global_sample_window": asset["verification_global_window"],
			"verification_sample_count": int(asset["verification_global_window"][1]) - int(asset["verification_global_window"][0]),
		}
		cue_manifest = {
			"schema": "ct2-rom-cue-wavehi-route-context-v1",
			"source_rom_sha256": ROM_SHA256,
			"cue": f"0x{int(asset['queue_id']):02X}",
			"cue_kind": "bgm",
			"source_input_timeline_sha256": INPUT_SHA256,
			"source_candidate_sha256": candidate_report["candidate"]["sha256"],
			"source_candidate_report_sha256": sha256_file(candidate_report_path),
			"source_stepper_report_sha256": sha256_file(stepper_report_path),
			"source_queue_csv_sha256": queue_digest,
			"renderer": "ROM-only CPU/APU/DMC stepper rendered with pinned FCEUX 2.7.0 WaveHi/SexyFilter semantics; source-derived cycles select this route-context window",
			"wav": f"assets/gameplay/audio/{wav_path.name}",
			"wav_sha256": wav_hash,
			"sample_rate": SAMPLE_RATE,
			"channels": 1,
			"bits_per_sample": 16,
			"sample_count": len(pcm) // 2,
			"capture_used": False,
			"captured_pcm_used": False,
			"captured_wav_used": False,
			"fceux_trace_used_for_scheduling": False,
			"runtime_needs_rom_or_emulator": False,
			"source_note": "A route-context slice of ROM-only WaveHi output. Emulator screenshots/WAVs are validation evidence only, never synthesis input.",
		}
		cue_path = args.output_dir / str(asset["cue_name"])
		cue_path.write_text(json.dumps(cue_manifest, indent=2) + "\n", encoding="utf-8")
		timing_manifest = {
			"schema": "ct2-rom-cue-wavehi-route-context-timing-v1",
			"source_rom_sha256": ROM_SHA256,
			"cue": f"${int(asset['queue_id']):02X}",
			"source_audio_path": cue_manifest["wav"],
			"source_audio_sha256": wav_hash,
			"source_input_timeline_sha256": INPUT_SHA256,
			"source_candidate_sha256": candidate_report["candidate"]["sha256"],
			"source_candidate_report_sha256": sha256_file(candidate_report_path),
			"source_queue_csv_sha256": queue_digest,
			"sample_rate_hz": SAMPLE_RATE,
			"channels": 1,
			"bits_per_sample": 16,
			"source_pcm_sample_count": len(pcm) // 2,
			"ntsc_cpu_hz": CPU_HZ,
			"wavehi_renderer_phase_samples": phase,
			"wavehi_sample_index_formula": f"round(source_cycle * 44100 / 1789773) - {phase}",
			"captured_pcm_used": False,
			"captured_wav_used": False,
			"capture_used_as_event_input": False,
			"runtime_needs_rom_or_emulator": False,
			"occurrences": [occurrence],
		}
		timing_path = args.output_dir / str(asset["timing_name"])
		timing_path.write_text(json.dumps(timing_manifest, indent=2) + "\n", encoding="utf-8")
		built.append({"cue": cue_manifest["cue"], "wav": wav_path.as_posix(), "sha256": wav_hash, "samples": len(pcm) // 2, "timing_manifest": timing_path.as_posix()})
	print(json.dumps({"built": built, "rom_sha256": ROM_SHA256, "candidate_sha256": candidate_report["candidate"]["sha256"], "capture_used": False}, indent=2))


if __name__ == "__main__":
	main()

#!/usr/bin/env python3
"""Pack ROM-stepper WaveHi PCM into input-driven $55 occurrence assets.

The source WAV must be rendered from the ROM-only CPU/APU stepper. This tool
uses ROM-derived queue/APU event cycles to carve the two $55 route occurrences;
it never reads FCEUX PCM, emulator screenshots, or captured video/audio.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import wave


ROOT = Path(__file__).resolve().parents[2]
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
SAMPLE_RATE = 44_100
CPU_HZ = 1_789_773
DEFAULT_CANDIDATE = Path("/tmp/ct2_first_match_audio_ce6_20261109/wavehi/rom_stepper_wavehi_candidate.wav")
DEFAULT_CANDIDATE_REPORT = Path("/tmp/ct2_first_match_audio_ce6_20261109/wavehi/candidate_report.json")
DEFAULT_STEPPER_DIR = Path("/tmp/ct2_first_match_audio_ce6_20261109/stepper")
SOURCE_TIMING = ROOT / "reference/rom_extract/gameplay/first_match_cue_timing_rom_stepper_20261027.json"
QUEUE_EVENTS = ROOT / "reference/rom_extract/gameplay/first_match_audio_queue_events_20261027.json"
OUT_DIR = ROOT / "assets/gameplay/audio"
WAV_NAME = "match_track_55_wavehi_occurrences_rom_generated.wav"
CUE_MANIFEST_NAME = "match_track_55_wavehi_rom_generated.json"
TIMING_MANIFEST_NAME = "match_track_55_wavehi_source_timing_rom_generated.json"


def sha256_bytes(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
	return sha256_bytes(path.read_bytes())


def sample_index(cycle: int, renderer_phase_samples: int) -> int:
	# WaveHi's source-cycle to 44.1-kHz sample phase is offset by 25 samples.
	# Keep that renderer phase explicit so the source queue/pulse delays remain
	# exact integer sample distances (807 and 1,239 samples for this ROM route).
	return round(cycle * SAMPLE_RATE / CPU_HZ) - renderer_phase_samples


def load_json(path: Path) -> dict:
	value = json.loads(path.read_text(encoding="utf-8"))
	if not isinstance(value, dict):
		raise ValueError(f"Expected a JSON object: {path}")
	return value


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--candidate", type=Path, default=DEFAULT_CANDIDATE)
	parser.add_argument("--candidate-report", type=Path, default=DEFAULT_CANDIDATE_REPORT)
	parser.add_argument("--stepper-dir", type=Path, default=DEFAULT_STEPPER_DIR)
	parser.add_argument("--renderer-phase-samples", type=int, default=25)
	parser.add_argument("--output-dir", type=Path, default=OUT_DIR)
	args = parser.parse_args()
	if args.renderer_phase_samples < 0:
		parser.error("--renderer-phase-samples must be nonnegative")

	candidate = args.candidate.resolve()
	report_path = args.candidate_report.resolve()
	stepper_dir = args.stepper_dir.resolve()
	candidate_report = load_json(report_path)
	stepper_report = load_json(stepper_dir / "source_stepper_report.json")
	source_timing = load_json(SOURCE_TIMING)
	queue_manifest = load_json(QUEUE_EVENTS)
	if candidate_report.get("source", {}).get("rom_sha256") != EXPECTED_ROM_SHA256 \
			or stepper_report.get("source_rom_sha256") != EXPECTED_ROM_SHA256:
		raise ValueError("WaveHi candidate and CPU stepper do not identify the supplied ROM revision")
	if candidate_report.get("candidate", {}).get("sha256") != sha256_file(candidate):
		raise ValueError("WaveHi candidate bytes differ from the candidate report")
	if candidate_report.get("source", {}).get("fceux_trace_used_for_scheduling") is not False \
			or candidate_report.get("source", {}).get("captured_pcm_or_wav_used_as_synthesis_input") is not False \
			or candidate_report.get("source", {}).get("captured_fceux_event_log_used_for_synthesis") is not False \
			or candidate_report.get("source", {}).get("captured_fceux_pcm_or_wav_used_as_synthesis_input") is not False:
		raise ValueError("Candidate report does not exclude FCEUX scheduling and captured audio inputs")
	input_hash = stepper_report.get("input_timeline_sha256", "")
	if not input_hash or input_hash != source_timing.get("source_input_timeline_sha256") \
			or input_hash != candidate_report.get("source", {}).get("explicit_controller_input_timeline", {}).get("sha256"):
		raise ValueError("Candidate route input timeline differs from the retained cue timing evidence")
	if queue_manifest.get("source_rom_sha256") != EXPECTED_ROM_SHA256 \
			or queue_manifest.get("source_input_timeline_sha256") != input_hash \
			or queue_manifest.get("captured_pcm_used") is not False \
			or queue_manifest.get("captured_wav_used") is not False:
		raise ValueError("ROM queue-event evidence has an unexpected ROM/input identity or captured-audio provenance")
	stepper_hashes = candidate_report.get("source", {}).get("stepper_output_sha256", {})
	for output_name in ("source_apu_writes.csv", "source_dmc_dma_reads.csv", "source_frame_cycles.csv"):
		actual_hash = sha256_file(stepper_dir / output_name)
		if stepper_hashes.get(output_name) != actual_hash \
				or stepper_report.get("outputs", {}).get(output_name) != actual_hash:
			raise ValueError(f"Candidate and APU source stepper differ at {output_name}")
	frame_updates_path = stepper_dir / "source_frame_updates.csv"
	dmc_state_path = stepper_dir / "source_apu_dmc_state_events.csv.gz"
	if candidate_report.get("source_events", {}).get("source_frame_update_events", {}).get("sha256") != sha256_file(frame_updates_path) \
			or candidate_report.get("source_events", {}).get("source_dmc_dac_edge_export", {}).get("sha256") != sha256_file(dmc_state_path):
		raise ValueError("Candidate frame/DMC timing events differ from the supplied ROM-stepper outputs")
	if candidate_report.get("candidate", {}).get("runtime_asset") is not False:
		raise ValueError("Expected a source-only diagnostic WaveHi input before segment packaging")

	with wave.open(str(candidate), "rb") as stream:
		if (stream.getnchannels(), stream.getsampwidth(), stream.getframerate()) != (1, 2, SAMPLE_RATE):
			raise ValueError("WaveHi candidate must be mono s16 PCM at 44.1 kHz")
		candidate_pcm = stream.readframes(stream.getnframes())
	candidate_samples = len(candidate_pcm) // 2

	queue_rows = queue_manifest.get("events", [])
	queue_occurrences = [
		(index, row) for index, row in enumerate(queue_rows)
		if row.get("queue_hex") == "$55"
	]
	if len(queue_occurrences) != len(source_timing.get("occurrences", [])) or len(queue_occurrences) != 2:
		raise ValueError("Expected exactly two source $55 events aligned with the cue-timing report")

	apus_path = stepper_dir / "source_apu_writes.csv"
	import csv
	with apus_path.open(newline="", encoding="utf-8") as source:
		apu_rows = list(csv.DictReader(source))
	if not apu_rows:
		raise ValueError("ROM-stepper APU write trace is empty")
	
	packed_pcm = bytearray()
	occurrences: list[dict] = []
	for occurrence_index, ((queue_index, queue_start), timing_occurrence) in enumerate(zip(queue_occurrences, source_timing["occurrences"])):
		queue_cycle = int(queue_start["source_cycle"])
		if int(timing_occurrence["queue_event"]["source_cycle"]) != queue_cycle:
			raise ValueError(f"Source cue timing and queue event differ for occurrence {occurrence_index}")
		stop_entries = []
		next_bgm_entry = None
		for row in queue_rows[queue_index + 1:]:
			if row.get("playback_effect") == "start_bgm":
				next_bgm_entry = row
				break
			if row.get("queue_hex") == "$01":
				stop_entries.append(row)
		if not stop_entries or next_bgm_entry is None:
			raise ValueError(f"No source $01 stop event follows $55 occurrence {occurrence_index}")
		stop_entry = stop_entries[0]
		stop_cycle = int(stop_entry["source_cycle"])
		mute_write = next((row for row in apu_rows
			if int(row["cycle"]) > stop_cycle and row["address"].upper() == "$4000" and row["value"].upper() == "$30"), None)
		if mute_write is None:
			raise ValueError(f"No ROM-derived pulse mute write follows stop for occurrence {occurrence_index}")
		mute_cycle = int(mute_write["cycle"])
		next_bgm_cycle = int(next_bgm_entry["source_cycle"])
		last_stop_cycle = int(stop_entries[-1]["source_cycle"])
		mute_channel_addresses = ("$4000", "$4004", "$4008", "$400C")
		muted_channel_writes = [row for row in apu_rows
			if last_stop_cycle < int(row["cycle"]) < next_bgm_cycle
			and row["address"].upper() in mute_channel_addresses
			and row["value"].upper() == "$30"]
		muted_channel_addresses = sorted({row["address"].upper() for row in muted_channel_writes})
		if muted_channel_addresses != ["$4000", "$4004", "$4008", "$400C"]:
			raise ValueError(f"ROM did not mute all four APU control registers after its stop requests: {muted_channel_addresses}")
		last_mute_write = muted_channel_writes[-1]
		start_sample = sample_index(queue_cycle, args.renderer_phase_samples)
		end_sample = sample_index(next_bgm_cycle, args.renderer_phase_samples)
		pulse_cycle = int(timing_occurrence["first_pulse1_register_write"]["source_cycle"])
		pulse_sample = sample_index(pulse_cycle, args.renderer_phase_samples)
		delay_samples = pulse_sample - start_sample
		expected_delay = round((pulse_cycle - queue_cycle) * SAMPLE_RATE / CPU_HZ)
		if delay_samples != expected_delay:
			raise ValueError(f"$55 occurrence {occurrence_index} queue-to-pulse delay is {delay_samples}; expected {expected_delay}")
		if start_sample < 0 or end_sample <= start_sample or end_sample > candidate_samples:
			raise ValueError(f"$55 occurrence {occurrence_index} PCM segment exceeds the source render")
		segment_start = len(packed_pcm) // 2
		segment = candidate_pcm[start_sample * 2:end_sample * 2]
		packed_pcm.extend(segment)
		segment_end = len(packed_pcm) // 2
		occurrences.append({
			"occurrence_index": occurrence_index,
			"queue_source_frame": int(queue_start["source_frame"]),
			"queue_source_cycle": queue_cycle,
			"first_pulse1_source_frame": int(timing_occurrence["first_pulse1_register_write"]["source_frame"]),
			"first_pulse1_source_cycle": pulse_cycle,
			"delay_cycles": pulse_cycle - queue_cycle,
			"delay_samples": delay_samples,
			"stop_queue_id": "$01",
			"stop_queue_source_frame": int(stop_entry["source_frame"]),
			"stop_queue_source_cycle": stop_cycle,
			"stop_queue_events": [{
				"source_frame": int(row["source_frame"]),
				"source_cycle": int(row["source_cycle"]),
				"queue_id": row["queue_hex"],
			} for row in stop_entries],
			"first_apu_mute_write": {
				"source_frame": int(mute_write["source_frame"]),
				"source_cycle": mute_cycle,
				"pc": mute_write["pc"],
				"address": mute_write["address"],
				"value": mute_write["value"],
			},
			"last_apu_mute_write": {
				"source_frame": int(last_mute_write["source_frame"]),
				"source_cycle": int(last_mute_write["cycle"]),
				"pc": last_mute_write["pc"],
				"address": last_mute_write["address"],
				"value": last_mute_write["value"],
			},
			"muted_channel_addresses": muted_channel_addresses,
			"next_bgm_queue_id": next_bgm_entry["queue_hex"],
			"next_bgm_queue_source_frame": int(next_bgm_entry["source_frame"]),
			"next_bgm_queue_source_cycle": next_bgm_cycle,
			"renderer_global_sample_window": [start_sample, end_sample],
			"asset_sample_window": [segment_start, segment_end],
		})

	args.output_dir.mkdir(parents=True, exist_ok=True)
	wav_path = args.output_dir / WAV_NAME
	with wave.open(str(wav_path), "wb") as output:
		output.setnchannels(1)
		output.setsampwidth(2)
		output.setframerate(SAMPLE_RATE)
		output.writeframes(bytes(packed_pcm))
	wav_hash = sha256_file(wav_path)
	cue_manifest = {
		"schema": "ct2-rom-cue-wavehi-occurrences-v1",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"cue": "0x55",
		"cue_kind": "bgm",
		"source_cpu_stepper": "tools/diagnostics/trace_rom_stepper_ce6_opcode_candidate_20261026.py",
		"source_input_timeline_sha256": input_hash,
		"source_candidate_sha256": candidate_report["candidate"]["sha256"],
		"source_candidate_report_sha256": sha256_file(report_path),
		"source_stepper_apu_writes_sha256": sha256_file(apus_path),
		"source_stepper_report_sha256": sha256_file(stepper_dir / "source_stepper_report.json"),
		"renderer": "ROM CPU/APU/DMC source-stepper events rendered through pinned FCEUX 2.7.0 WaveHi/SexyFilter semantics at captured channel and master SoundVolume 255",
		"wav": f"assets/gameplay/audio/{WAV_NAME}",
		"wav_sha256": wav_hash,
		"sample_rate": SAMPLE_RATE,
		"channels": 1,
		"bits_per_sample": 16,
		"sample_count": len(packed_pcm) // 2,
		"occurrence_count": len(occurrences),
		"capture_used": False,
		"captured_pcm_used": False,
		"captured_wav_used": False,
		"fceux_trace_used_for_scheduling": False,
		"runtime_needs_rom_or_emulator": False,
		"source_note": "This asset contains only the two live $55 occurrences on the checked route. Each segment starts at its ROM queue event and preserves the ROM-stepper WaveHi mix, APU mute/tail, and decay through the next ROM BGM queue event. Route inputs affect offline source CPU execution only; runtime still responds to live ROM-derived queue events.",
	}
	cue_path = args.output_dir / CUE_MANIFEST_NAME
	cue_path.write_text(json.dumps(cue_manifest, indent=2) + "\n", encoding="utf-8")
	timing_manifest = {
		"schema": "ct2-rom-cue-wavehi-occurrence-timing-v1",
		"purpose": "Live queue-driven $55 occurrence playback from ROM-stepper WaveHi PCM; clip boundaries use ROM queue and APU mute events.",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"cue": "$55",
		"source_timing_path": SOURCE_TIMING.relative_to(ROOT).as_posix(),
		"source_timing_sha256": sha256_file(SOURCE_TIMING),
		"source_queue_events_path": QUEUE_EVENTS.relative_to(ROOT).as_posix(),
		"source_queue_events_sha256": sha256_file(QUEUE_EVENTS),
		"source_audio_path": cue_manifest["wav"],
		"source_audio_sha256": wav_hash,
		"sample_rate_hz": SAMPLE_RATE,
		"channels": 1,
		"bits_per_sample": 16,
		"source_pcm_sample_count": len(packed_pcm) // 2,
		"ntsc_cpu_hz": CPU_HZ,
		"wavehi_renderer_phase_samples": args.renderer_phase_samples,
		"wavehi_sample_index_formula": f"round(source_cycle * 44100 / 1789773) - {args.renderer_phase_samples}",
		"source_input_timeline_sha256": input_hash,
		"captured_pcm_used": False,
		"captured_wav_used": False,
		"capture_used_as_event_input": False,
		"runtime_needs_rom_or_emulator": False,
		"occurrences": occurrences,
	}
	timing_path = args.output_dir / TIMING_MANIFEST_NAME
	timing_path.write_text(json.dumps(timing_manifest, indent=2) + "\n", encoding="utf-8")
	print(json.dumps({
		"wav": str(wav_path),
		"wav_sha256": wav_hash,
		"samples": len(packed_pcm) // 2,
		"occurrences": occurrences,
		"cue_manifest": str(cue_path),
		"timing_manifest": str(timing_path),
	}, indent=2))


if __name__ == "__main__":
	main()

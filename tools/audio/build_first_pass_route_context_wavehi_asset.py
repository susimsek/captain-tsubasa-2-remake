#!/usr/bin/env python3
"""Package the ROM-only WaveHi segment from `$3C` through first PASS boundary.

This creates a standalone PCM runtime candidate from ROM-stepper output. A
retained FCEUX CPU-write trace is accepted only to validate APU queue/register
events; it is never an audio or synthesis input.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
from pathlib import Path
import wave


ROOT = Path(__file__).resolve().parents[2]
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
INPUT_SHA256 = "92bd6e971ea5c59672fd2a7a4eece18d797c0fb006ea7f427f9b521dcbec42e0"
CPU_HZ = 1_789_773
SAMPLE_RATE = 44_100
RENDERER_PHASE_SAMPLES = 25
START_FRAME = 8607
PASS_START_FRAME = 9043
END_FRAME = 9600
START_QUEUE_ID = 0x3C
APU_ADDRESSES = set(range(0x4000, 0x4014)) | {0x4015, 0x4017}
DEFAULT_OUTPUT = ROOT / "assets/gameplay/audio/match_track_3C_first_pass_route_context_8607_9600_rom_generated.wav"


def sha256_bytes(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
	return sha256_bytes(path.read_bytes())


def load_json(path: Path) -> dict:
	value = json.loads(path.read_text(encoding="utf-8"))
	if not isinstance(value, dict):
		raise ValueError(f"Expected a JSON object: {path}")
	return value


def parse_hex(value: str) -> int:
	return int(value.strip().removeprefix("$"), 16)


def sample_at_cycle(cycle: int) -> int:
	return round(cycle * SAMPLE_RATE / CPU_HZ) - RENDERER_PHASE_SAMPLES


def trace_apu_csv_bytes(trace_path: Path) -> bytes:
	output = io.StringIO(newline="")
	writer = csv.DictWriter(output, fieldnames=("source_frame", "cycles", "pc", "address", "value"),
		lineterminator="\n")
	writer.writeheader()
	with trace_path.open(newline="", encoding="utf-8") as stream:
		for row in csv.DictReader(stream):
			frame = int(row["source_frame"])
			address = parse_hex(row["address"])
			if not PASS_START_FRAME <= frame <= END_FRAME or not 0x4000 <= address <= 0x4017:
				continue
			writer.writerow({"source_frame": frame, "cycles": row["cycle_absolute"],
				"pc": row["pc"], "address": row["address"], "value": row["new"]})
	return output.getvalue().encode("utf-8")


def build(stepper_dir: Path, wavehi_report_path: Path, apu_comparison_path: Path,
		fceux_trace_path: Path, output_path: Path) -> dict:
	stepper_dir = stepper_dir.resolve()
	wavehi_report_path = wavehi_report_path.resolve()
	apu_comparison_path = apu_comparison_path.resolve()
	fceux_trace_path = fceux_trace_path.resolve()
	output_path = output_path.resolve()
	if not output_path.is_relative_to(ROOT / "assets/gameplay/audio"):
		raise ValueError("Runtime candidate output must be under assets/gameplay/audio/")
	stepper_report_path = stepper_dir / "source_stepper_report.json"
	stepper_report = load_json(stepper_report_path)
	wavehi_report = load_json(wavehi_report_path)
	apu_comparison = load_json(apu_comparison_path)
	if stepper_report.get("source_rom_sha256") != ROM_SHA256 \
			or stepper_report.get("input_timeline_sha256") != INPUT_SHA256 \
			or stepper_report.get("source_frames_advanced") != END_FRAME:
		raise ValueError("Source stepper must use the pinned ROM/input timeline through frame 9600")
	for name in ("source_apu_writes.csv", "source_dmc_dma_reads.csv", "source_frame_cycles.csv",
			"source_title_stop_markers.csv", "source_sound_queue_nonzero_writes.csv"):
		if stepper_report.get("outputs", {}).get(name) != sha256_file(stepper_dir / name):
			raise ValueError(f"Source stepper output hash differs: {name}")
	if wavehi_report.get("source", {}).get("rom_sha256") != ROM_SHA256 \
			or wavehi_report.get("source", {}).get("explicit_controller_input_timeline", {}).get("sha256") != INPUT_SHA256 \
			or wavehi_report.get("source", {}).get("captured_pcm_or_wav_used_as_synthesis_input") is not False \
			or wavehi_report.get("source", {}).get("fceux_trace_used_for_scheduling") is not False \
			or wavehi_report.get("candidate", {}).get("runtime_asset") is not False:
		raise ValueError("WaveHi candidate is not the expected capture-free ROM-only diagnostic render")
	if wavehi_report.get("source_events", {}).get("rendered_through_source_frame") != END_FRAME:
		raise ValueError("WaveHi candidate does not reach the frame-9600 endpoint")
	wavehi_stepper_hashes = wavehi_report.get("source", {}).get("stepper_output_sha256", {})
	for name in ("source_apu_writes.csv", "source_dmc_dma_reads.csv", "source_frame_cycles.csv"):
		if wavehi_stepper_hashes.get(name) != stepper_report.get("outputs", {}).get(name):
			raise ValueError(f"WaveHi candidate was not rendered from this source stepper output: {name}")
	comparison = apu_comparison.get("comparison", {})
	if apu_comparison.get("source_rom_sha256") != ROM_SHA256 \
			or apu_comparison.get("input_timeline_sha256") != INPUT_SHA256 \
			or comparison.get("first_source_frame") != 9043 \
			or comparison.get("compared_ordered_prefix") != 6485 \
			or comparison.get("address_value_frame_sequence_exact") is not True \
			or comparison.get("sequence_mismatch_count_in_prefix") != 0 \
			or comparison.get("pc_equal_in_prefix") != 6485 \
			or comparison.get("cycle_exact_writes") != 5418 \
			or comparison.get("max_abs_cycle_delta") != 7:
		raise ValueError("APU validation report does not match the retained frame-9043–9600 results")
	trace_csv = trace_apu_csv_bytes(fceux_trace_path)
	if sha256_bytes(trace_csv) != apu_comparison.get("fceux_reference", {}).get("sha256"):
		raise ValueError("Retained FCEUX write trace differs from the APU comparison report")

	stepper_queue = stepper_dir / "source_sound_queue_nonzero_writes.csv"
	with stepper_queue.open(newline="", encoding="utf-8") as stream:
		queue_events = list(csv.DictReader(stream))
	start_matches = [row for row in queue_events if int(row["source_frame"]) == START_FRAME
		and parse_hex(row["value"]) == START_QUEUE_ID]
	if len(start_matches) != 1 or parse_hex(start_matches[0]["address"]) != 0x0700:
		raise ValueError("Expected one ROM-source `$3C` queue insertion at frame 8607")
	start_cycle = int(start_matches[0]["cycle"])
	embedded_events = [row for row in queue_events
		if START_FRAME < int(row["source_frame"]) <= END_FRAME]
	source_pass_queues = [{"frame": int(row["source_frame"]), "cycle": int(row["cycle"]),
		"queue_id": parse_hex(row["value"]), "pc": row["pc"]}
		for row in embedded_events if PASS_START_FRAME <= int(row["source_frame"]) <= END_FRAME
		and parse_hex(row["address"]) == 0x0700]
	retained_pass_queues = []
	with fceux_trace_path.open(newline="", encoding="utf-8") as stream:
		for row in csv.DictReader(stream):
			frame = int(row["source_frame"])
			if not PASS_START_FRAME <= frame <= END_FRAME or parse_hex(row["address"]) != 0x0700:
				continue
			queue_id = parse_hex(row["new"])
			if queue_id:
				retained_pass_queues.append({"frame": frame, "cycle": int(row["cycle_absolute"]),
					"queue_id": queue_id, "pc": row["pc"]})
		expected_queue_ids = [(9125, 0x2B), (9247, 0x2C)]
	if [(item["frame"], item["queue_id"]) for item in source_pass_queues] != expected_queue_ids \
			or [(item["frame"], item["queue_id"]) for item in retained_pass_queues] != expected_queue_ids:
		raise ValueError("Source and retained PASS-interval queue events differ from `$2B@9125,$2C@9247`")
	queue_validation = []
	for source_event, retained_event in zip(source_pass_queues, retained_pass_queues):
		queue_validation.append({
			"queue_id": f"${source_event['queue_id']:02X}",
			"frame": source_event["frame"],
			"source_cycle": source_event["cycle"],
			"fceux_cycle": retained_event["cycle"],
			"cycle_delta": source_event["cycle"] - retained_event["cycle"],
		})

	frame_cycles: dict[int, dict] = {}
	with (stepper_dir / "source_frame_cycles.csv").open(newline="", encoding="utf-8") as stream:
		for row in csv.DictReader(stream):
			frame_cycles[int(row["source_frame"])] = row
	if END_FRAME not in frame_cycles:
		raise ValueError("Source stepper has no frame-9600 cycle boundary")
	end_cycle = int(frame_cycles[END_FRAME]["cycle_end"])
	start_sample = sample_at_cycle(start_cycle)
	end_sample = sample_at_cycle(end_cycle)
	if start_sample < 0 or end_sample <= start_sample:
		raise ValueError("Source queue/boundary cycles produce an invalid audio sample window")

	wavehi_path = Path(wavehi_report["candidate"]["path"])
	if not wavehi_path.is_absolute():
		wavehi_path = ROOT / wavehi_path
	with wave.open(str(wavehi_path), "rb") as source:
		if (source.getnchannels(), source.getsampwidth(), source.getframerate()) != (1, 2, SAMPLE_RATE):
			raise ValueError("WaveHi source must be mono signed-16-bit PCM at 44.1 kHz")
		if source.getnframes() != wavehi_report["candidate"]["samples_44100_hz"]:
			raise ValueError("WaveHi source sample count differs from its candidate report")
		if end_sample > source.getnframes():
			raise ValueError("Frame-9600 sample boundary exceeds the WaveHi source")
		source.setpos(start_sample)
		pcm = source.readframes(end_sample - start_sample)
	if len(pcm) != (end_sample - start_sample) * 2:
		raise ValueError("WaveHi source ended before the selected route window")

	output_path.parent.mkdir(parents=True, exist_ok=True)
	with wave.open(str(output_path), "wb") as output:
		output.setnchannels(1)
		output.setsampwidth(2)
		output.setframerate(SAMPLE_RATE)
		output.writeframes(pcm)

	output_sha = sha256_file(output_path)
	queue_summary = [{
		"frame": int(row["source_frame"]), "cycle": int(row["cycle"]),
		"queue_id": f"${parse_hex(row['value']):02X}", "pc": row["pc"],
	} for row in embedded_events]
	trace_sha = sha256_file(fceux_trace_path)
	comparison_sha = sha256_file(apu_comparison_path)
	manifest = {
		"schema": "ct2-rom-wavehi-pass-route-context-v1",
		"asset": {
			"path": output_path.relative_to(ROOT).as_posix(),
			"sha256": output_sha,
			"sample_rate_hz": SAMPLE_RATE,
			"channels": 1,
			"bits_per_sample": 16,
			"sample_count": end_sample - start_sample,
			"sample_window_in_full_source_render": [start_sample, end_sample],
			"sample_index_formula": "round(source_cycle * 44100 / 1789773) - 25",
			"renderer_phase_samples": RENDERER_PHASE_SAMPLES,
			"runtime_candidate": True,
			"rom_or_emulator_required_at_runtime": False,
		},
		"source": {
			"rom_sha256": ROM_SHA256,
			"input_timeline_sha256": INPUT_SHA256,
			"input_timeline_role": "source CPU input only; not synthesis timing or PCM",
			"frame_range_inclusive": [START_FRAME, END_FRAME],
			"start_event": {"frame": START_FRAME, "cycle": start_cycle, "queue_id": "$3C"},
			"end_event": {"frame": END_FRAME, "cycle_end_exclusive": end_cycle,
				"kind": "first `$D5EA` input-wait boundary after PASS"},
			"embedded_queue_events": queue_summary,
			"stepper": {
				"engine": stepper_report.get("cpu_engine"),
				"pinned_fceux_semantics": stepper_report.get("pinned_fceux_semantics"),
				"stepper_script": "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py",
				"stepper_script_sha256": sha256_file(ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"),
				"source_frames_advanced": END_FRAME,
				"source_cpu_cycles": stepper_report.get("source_cpu_cycles"),
				"apu_writes": stepper_report.get("apu_write_count"),
				"dmc_dma_reads": stepper_report.get("dmc_dma_reads"),
				"dmc_output_bytes": stepper_report.get("dmc_dma_output_bytes"),
				"dmc_state_event_rows": stepper_report.get("source_dmc_state_event_export", {}).get("event_rows"),
				"dmc_state_events_sha256": stepper_report.get("source_dmc_state_event_export", {}).get("sha256"),
				"source_frame_update_events_sha256": wavehi_report.get("source_events", {}).get("source_frame_update_events", {}).get("sha256"),
				"output_sha256": stepper_report.get("outputs", {}),
				"source_stepper_report_sha256": sha256_file(stepper_dir / "source_stepper_report.json"),
			},
			"wavehi_renderer": {
				"implementation": wavehi_report.get("renderer", {}).get("source"),
				"implementation_sha256": wavehi_report.get("renderer", {}).get("source_sha256"),
				"filter_coefficients_sha256": wavehi_report.get("renderer", {}).get("pinned_filter_coefficients_sha256"),
				"candidate_sha256": wavehi_report.get("candidate", {}).get("sha256"),
				"captured_pcm_or_wav_used_as_synthesis_input": False,
				"fceux_trace_used_for_scheduling": False,
			},
		},
		"validation": {
			"reference": "retained muted FCEUX CPU-write trace; validation only",
			"fceux_trace_sha256": trace_sha,
			"apu_comparison_report_sha256": comparison_sha,
			"frame_range_inclusive": [PASS_START_FRAME, END_FRAME],
			"apu_writes_compared": comparison["compared_ordered_prefix"],
			"apu_frame_address_value_sequence_exact": comparison["address_value_frame_sequence_exact"],
			"apu_pc_equal": comparison["pc_equal_in_prefix"],
			"apu_cycle_exact_writes": comparison["cycle_exact_writes"],
			"apu_cycle_mismatch_count": comparison["cycle_mismatch_count"],
			"apu_max_abs_cycle_delta": comparison["max_abs_cycle_delta"],
			"queue_events": queue_validation,
			"fceux_wav_or_pcm_compared": False,
			"fceux_wav_or_pcm_used_as_synthesis_input": False,
		},
		"limits": [
			"APU register writes match the retained trace by ordered frame/address/value/PC, but 1,067 of 6,485 writes differ by up to 7 CPU cycles.",
			"The retained trace has no PCM samples through frame 9600; waveform parity is not established.",
			"The WaveHi DMC DMA arbitration remains diagnostic, not cycle-accurate hardware evidence.",
			"The asset includes its embedded `$66/$2B/$2C` queue events; do not layer the separate cue WAVs over this route-context clip.",
		],
	}
	manifest_path = output_path.with_suffix(".json")
	manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	return manifest


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--stepper-dir", type=Path, required=True)
	parser.add_argument("--wavehi-report", type=Path, required=True)
	parser.add_argument("--apu-comparison-report", type=Path, required=True)
	parser.add_argument("--fceux-write-trace", type=Path, required=True,
		help="retained muted CPU-write trace for validation only")
	parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
	args = parser.parse_args()
	manifest = build(args.stepper_dir, args.wavehi_report, args.apu_comparison_report,
		args.fceux_write_trace, args.output)
	print(json.dumps({
		"asset": manifest["asset"]["path"],
		"asset_sha256": manifest["asset"]["sha256"],
		"sample_count": manifest["asset"]["sample_count"],
		"manifest": str(args.output.with_suffix(".json")),
	}, indent=2))


if __name__ == "__main__":
	main()

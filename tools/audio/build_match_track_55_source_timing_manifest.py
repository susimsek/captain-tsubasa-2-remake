#!/usr/bin/env python3
"""Build route-only playback timing metadata from ROM-derived inputs.

This does not use captured emulator PCM, APU timestamps, screenshots, or the
ROM file. The timing source was produced by the ROM-only source CPU stepper;
the WAV is the checked ROM driver/sequence render. Captured FCEUX PCM is used
only by the separate validation report.
"""

from __future__ import annotations

import hashlib
import json
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TRACK_MANIFEST_PATH = ROOT / "assets/gameplay/audio/match_track_55_rom_generated.json"
SOURCE_TIMING_PATH = ROOT / "reference/rom_extract/gameplay/first_match_cue_timing_rom_stepper_20261027.json"
OUTPUT_PATH = ROOT / "assets/gameplay/audio/match_track_55_source_timing_rom_generated.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def main() -> int:
	track = json.loads(TRACK_MANIFEST_PATH.read_text(encoding="utf-8"))
	timing_bytes = SOURCE_TIMING_PATH.read_bytes()
	timing = json.loads(timing_bytes)
	if track.get("source_rom_sha256") != EXPECTED_ROM_SHA256:
		raise SystemExit("track manifest targets a different ROM")
	if timing.get("source_rom_sha256") != EXPECTED_ROM_SHA256:
		raise SystemExit("source timing targets a different ROM")
	if timing.get("capture_used_as_event_input") is not False or timing.get("captured_pcm_used") is not False:
		raise SystemExit("source timing is not capture-free")
	if timing.get("cue_rom_source", {}).get("queue_id") != "$55":
		raise SystemExit("source timing does not describe queue $55")

	wav_relative = track.get("wav", "")
	wav_path = ROOT / wav_relative
	wav_bytes = wav_path.read_bytes()
	if sha256(wav_bytes) != track.get("wav_sha256"):
		raise SystemExit("source cue WAV does not match its manifest checksum")
	with wave.open(str(wav_path), "rb") as source_wav:
		params = source_wav.getparams()
		pcm = source_wav.readframes(params.nframes)
	if (params.nchannels, params.sampwidth, params.framerate, params.comptype) != (1, 2, 44100, "NONE"):
		raise SystemExit(f"unexpected cue PCM format: {params}")
	if len(pcm) != params.nframes * 2:
		raise SystemExit("cue PCM frame count is inconsistent")
	leading_zero_samples = 0
	for offset in range(0, len(pcm), 2):
		if pcm[offset] != 0 or pcm[offset + 1] != 0:
			break
		leading_zero_samples += 1
	if leading_zero_samples != 3065:
		raise SystemExit(f"expected 3065 leading source zeros, got {leading_zero_samples}")

	clock_hz = int(timing.get("clock", {}).get("ntsc_cpu_hz", 0))
	if clock_hz <= 0:
		raise SystemExit("source timing has no valid NTSC CPU clock")
	occurrences = timing.get("occurrences", [])
	if len(occurrences) != 2:
		raise SystemExit("expected the two fresh-start route $55 occurrences")
	playback_occurrences = []
	for occurrence_index, occurrence in enumerate(occurrences):
		queue_event = occurrence.get("queue_event", {})
		apu_event = occurrence.get("first_pulse1_register_write", {})
		queue_cycle = int(queue_event.get("source_cycle", -1))
		apu_cycle = int(apu_event.get("source_cycle", -1))
		delay_cycles = apu_cycle - queue_cycle
		if queue_event.get("queue_id") != "$55" or delay_cycles <= 0:
			raise SystemExit(f"invalid source timing occurrence {occurrence_index}")
		delay_samples = int(delay_cycles * params.framerate / clock_hz + 0.5)
		playback_occurrences.append({
			"occurrence_index": occurrence_index,
			"queue_source_frame": int(queue_event["source_frame"]),
			"queue_source_cycle": queue_cycle,
			"first_pulse1_source_frame": int(apu_event["source_frame"]),
			"first_pulse1_source_cycle": apu_cycle,
			"first_pulse1_cpu_address": str(apu_event["address"]),
			"delay_cycles": delay_cycles,
			"delay_samples": delay_samples,
		})

	result = {
		"schema": "ct2-rom-cue-route-source-timing-v1",
		"purpose": "ROM-only queue-to-first-pulse timing; runtime removes only verified leading silence and prefixes the source-derived delay.",
		"source_rom_sha256": EXPECTED_ROM_SHA256,
		"cue": "$55",
		"source_timing_path": str(SOURCE_TIMING_PATH.relative_to(ROOT)),
		"source_timing_sha256": sha256(timing_bytes),
		"source_input_timeline_sha256": timing.get("source_input_timeline_sha256", ""),
		"source_audio_path": wav_relative,
		"source_audio_sha256": track["wav_sha256"],
		"sample_rate_hz": params.framerate,
		"channels": params.nchannels,
		"bits_per_sample": params.sampwidth * 8,
		"source_sample_count": params.nframes,
		"leading_zero_samples_removed": leading_zero_samples,
		"ntsc_cpu_hz": clock_hz,
		"occurrences": playback_occurrences,
		"captured_pcm_used": False,
		"capture_used_as_event_input": False,
		"runtime_needs_rom_or_emulator": False,
		"validation_note": "A diagnostics-only trim-plus-delay comparison against same-input FCEUX PCM lowers RMSE in both windows; it does not establish PCM identity. See reference/diagnostics/audio/route_cue55_asset_onset_audit_20261027.md.",
	}
	OUTPUT_PATH.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
	print(f"Wrote {OUTPUT_PATH.relative_to(ROOT)} ({len(playback_occurrences)} source-timed occurrences)")
	for item in playback_occurrences:
		print(f"  #{item['occurrence_index']}: frame {item['queue_source_frame']}, {item['delay_cycles']} cycles -> {item['delay_samples']} samples")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())

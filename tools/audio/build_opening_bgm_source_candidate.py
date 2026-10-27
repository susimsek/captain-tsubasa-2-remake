#!/usr/bin/env python3
"""Build a diagnostics-only standalone BGM candidate from ROM source bytes.

The candidate queues only the byte-verified opening sound ID $58 through the
original ROM sound driver. It does not use the captured opening WAV, captured
PCM, or the captured multi-cue frame schedule, and it never writes runtime
assets. The NSF and rendered WAV are kept together with their source hashes.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import wave

from build_intro_nsf import EXPECTED_SHA256, ROOT, ROM
from build_intro_nsf import build as build_nsf
from render_rom_driver_nsf import render

OUTPUT_DIR = ROOT / "reference/diagnostics/audio/opening_bgm_rom_source_candidate_20261025"
RUNTIME_WAV = ROOT / "assets/opening/audio/opening_timeline_rom_driver.wav"
TRACK_ID = 0x58
SAMPLE_RATE = 44_100
RENDER_SECONDS = 90


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def file_sha256(path: Path) -> str:
	return sha256(path.read_bytes())


def build_candidate(output_dir: Path = OUTPUT_DIR) -> dict:
	output_dir = output_dir.resolve()
	if output_dir.exists():
		raise FileExistsError(f"Refusing to overwrite diagnostics: {output_dir}")
	if not RUNTIME_WAV.is_file():
		raise FileNotFoundError(f"Protected runtime WAV is missing: {RUNTIME_WAV}")

	runtime_sha_before = file_sha256(RUNTIME_WAV)
	output_dir.mkdir(parents=True)
	nsf_path = output_dir / "opening_bgm_rom_driver.nsf"
	wav_path = output_dir / "opening_bgm_rom_driver.wav"

	build_info = build_nsf(TRACK_ID, nsf_path)
	if build_info["source_rom_sha256"] != EXPECTED_SHA256:
		raise ValueError("Candidate NSF was not built from the expected supplied ROM")
	if build_info["cue"] != "0x58" or build_info["music_prg_bank"] != "0x0F":
		raise ValueError("Candidate NSF did not resolve the opening cue to PRG bank $0F")
	rom_bytes = ROM.read_bytes()
	if rom_bytes[0x18C98:0x18C9A] != bytes.fromhex("AD B7"):
		raise ValueError("Runtime ID $58 no longer resolves through the verified $8BDA table entry")
	if rom_bytes[0x1F7BD:0x1F7BD + 13] != bytes.fromhex("04 BA B7 05 BD BA 06 5E BD 07 3F BF FF"):
		raise ValueError("The opening track header at ROM file offset 0x1F7BD changed")

	# Preserve any driver-start silence so playback can be aligned to the ROM's
	# ED $58 source command when this candidate is evaluated in Godot.
	render(nsf_path, wav_path, RENDER_SECONDS, SAMPLE_RATE, preserve_initial_silence=True)
	with wave.open(str(wav_path), "rb") as source:
		if (source.getnchannels(), source.getsampwidth(), source.getframerate()) != (1, 2, SAMPLE_RATE):
			raise ValueError("Unexpected candidate WAV format")
		wav_samples = source.getnframes()

	runtime_sha_after = file_sha256(RUNTIME_WAV)
	if runtime_sha_after != runtime_sha_before:
		raise RuntimeError("The protected Godot runtime WAV changed during candidate generation")

	manifest = {
		"purpose": "ROM-source BGM candidate for diagnostics; not a runtime asset.",
		"source_rom_sha256": build_info["source_rom_sha256"],
		"source_nsf_path": nsf_path.relative_to(ROOT).as_posix(),
		"source_nsf_sha256": build_info["nsf_sha256"],
		"source_nsf_build": build_info,
		"rom_music_path": {
			"runtime_sound_id": "0x58",
			"driver_pointer_table_cpu_address": "$8BDA",
			"driver_pointer_entry_file_offset": "0x18C98",
			"driver_pointer_entry_bytes": "AD B7",
			"driver_pointer_word": "$B7AD",
			"track_header_file_offset": "0x01F7BD",
			"track_header_cpu_address": "$B7AD",
			"music_prg_bank": "$0F",
			"music_bank_file_offset": "0x01E010",
			"driver_prg_bank": "$0C",
			"driver_entry_cpu_address": "$8000",
			"driver_file_offset": "0x018010",
			"dpcm_prg_bank": "$1E",
			"dpcm_file_offset": "0x03C010",
		},
		"event_schedule": "The NSF INIT queues only sound ID $58. No captured absolute frame schedule is used; the runtime should start this one-shot candidate on the source presenter's ROM $58 signal.",
		"wav_path": wav_path.relative_to(ROOT).as_posix(),
		"wav_sha256": file_sha256(wav_path),
		"sample_rate_hz": SAMPLE_RATE,
		"channels": 1,
		"bits_per_sample": 16,
		"render_seconds": RENDER_SECONDS,
		"wav_samples": wav_samples,
		"renderer": "libgme 0.6.5 executing an NSF built from the supplied ROM's sound driver, track bank, and DPCM bank",
		"captured_wav_used": False,
		"captured_pcm_used": False,
		"captured_cue_frames_used": False,
		"runtime_needs_rom_or_emulator": False,
		"runtime_asset": False,
		"omitted_or_unverified": [
			"This isolated candidate does not include the other opening sound IDs ($68, $28, $0E, $02, $09, and $07).",
			"The cue begins in NSF INIT, so its absolute cold-start frame and source scheduler timing are not reproduced.",
			"The candidate retains about four frames of libgme/NSF startup silence; it has not had the known three-frame timeline alignment trim applied or verified for this wrapper.",
			"The NSF wrapper initializes $4015 but does not reproduce the source cold-start $4010/$4017 writes or their exact phase relative to $58.",
			"libgme output has not been shown sample-identical to the original APU/mixer/filter path.",
		],
		"protected_runtime_wav": {
			"path": RUNTIME_WAV.relative_to(ROOT).as_posix(),
			"sha256_before": runtime_sha_before,
			"sha256_after": runtime_sha_after,
			"unchanged": runtime_sha_before == runtime_sha_after,
		},
	}
	manifest_path = output_dir / "candidate_manifest.json"
	manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	return manifest


if __name__ == "__main__":
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--output-dir", type=Path, default=OUTPUT_DIR)
	args = parser.parse_args()
	print(json.dumps(build_candidate(args.output_dir), indent=2))

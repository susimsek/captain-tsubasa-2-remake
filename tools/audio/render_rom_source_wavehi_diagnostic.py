#!/usr/bin/env python3
"""Re-render the ROM-source NSF APU trace through the build-only WaveHi model.

The source is the instrumented ROM-derived NSF write stream, mapped to the
captured FCEUX frame-cycle boundaries by the previously documented affine
clock fit. Captured FCEUX PCM is never passed to this renderer.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from types import SimpleNamespace

from render_fceux_apu_wavehi_prototype import DEFAULT_DMC_TRACE, run as render_wavehi

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
SOURCE_CANDIDATE_DIR = ROOT / "reference/diagnostics/audio/rom_driver_apu_wavehi_candidate_20261024"
SOURCE_MANIFEST = SOURCE_CANDIDATE_DIR / "source_driver_wavehi.json"
SOURCE_WRITES = ROOT / "reference/diagnostics/audio/rom_driver_apu_trace_cue_offset_plus2_20261024/apu_writes.csv"
SOURCE_TRACE_DIR = SOURCE_WRITES.parent
SOURCE_TRACE_MANIFEST = SOURCE_TRACE_DIR / "trace_meta.json"
SOURCE_NSF = SOURCE_TRACE_DIR / "opening_timeline_rom_driver.nsf"
MAPPED_WRITES = SOURCE_CANDIDATE_DIR / "source_driver_writes_mapped.csv"
FRAME_CYCLES = ROOT / "reference/diagnostics/audio/fceux_apu_write_trace_20261024_184945_utc/frame_cycles.csv"
DPCM_EXTRACT = ROOT / "reference/rom_extract/audio/dpcm_sample_blob.bin"
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/audio/rom_source_wavehi_improvement_20261025/source_driver_wavehi.wav"


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def file_hash(path: Path) -> str:
	return sha256(path.read_bytes())


def validate_source_inputs(rom_path: Path) -> tuple[dict, dict, dict]:
	rom = rom_path.read_bytes()
	if sha256(rom) != ROM_SHA256:
		raise ValueError("The supplied ROM does not match the preserved source-ROM identity.")
	prior = json.loads(SOURCE_MANIFEST.read_text(encoding="utf-8"))
	trace_manifest = json.loads(SOURCE_TRACE_MANIFEST.read_text(encoding="utf-8"))
	if trace_manifest["source_rom_sha256"] != ROM_SHA256:
		raise ValueError("The source APU trace was not built from the supplied ROM.")
	if trace_manifest["source_nsf_sha256"] != file_hash(SOURCE_NSF):
		raise ValueError("The traced NSF does not match the trace metadata hash.")
	if trace_manifest["cue_frame_offset_experiment"]["cue_frame_offset_ticks"] != 2:
		raise ValueError("Expected the documented diagnostic +2 NSF PLAY-tick schedule.")
	inputs = prior["inputs"]
	for key, path in (("rom_driver_nsf_apu_write_trace", SOURCE_WRITES),
			("mapped_register_events", MAPPED_WRITES),
			("fceux_frame_cycle_reference", FRAME_CYCLES)):
		record = inputs[key]
		if path.relative_to(ROOT).as_posix() != record["path"] or file_hash(path) != record["sha256"]:
			raise ValueError(f"Source WaveHi input changed since its evidence manifest: {path}")
	if inputs["cycle_mapping"]["type"] != "global_affine":
		raise ValueError("Expected the previously measured global-affine cycle mapping.")
	if prior["implementation"]["captured_pcm_used_as_input"]:
		raise ValueError("The prior renderer manifest unexpectedly uses captured PCM as input.")
	if prior["implementation"]["runtime_asset"]:
		raise ValueError("A diagnostic renderer must not declare itself a runtime asset.")
	bank_start = 16 + (512 if rom[6] & 0x04 else 0) + 0x1E * 0x2000
	if rom[bank_start:bank_start + DPCM_EXTRACT.stat().st_size] != DPCM_EXTRACT.read_bytes():
		raise ValueError("Preserved DPCM bytes do not match physical ROM bank $1E.")
	return prior, inputs, trace_manifest


def run(rom_path: Path, output_path: Path, source_frame_sequencer: bool = False) -> dict:
	prior, source_inputs, trace_manifest = validate_source_inputs(rom_path)
	# Reuse the byte-pinned WaveHi renderer. Its temporary generic manifest is
	# replaced below so this result accurately identifies the ROM-source writes.
	render_wavehi(SimpleNamespace(
		writes=MAPPED_WRITES,
		frame_cycles=FRAME_CYCLES,
		dmc_trace=DEFAULT_DMC_TRACE,
		rom=rom_path,
		output=output_path,
		source_frame_sequencer=source_frame_sequencer,
	))
	generic = json.loads(output_path.with_suffix(".json").read_text(encoding="utf-8"))
	manifest = {
		"purpose": "Diagnostic ROM-source APU-to-WaveHi synthesis. The renderer consumes ROM-driver NSF register writes and ROM DPCM bytes; captured PCM is comparison-only.",
		"source_rom": {"sha256": ROM_SHA256, "runtime_dependency": False},
		"source_nsf_apu_trace": {
			"path": source_inputs["rom_driver_nsf_apu_write_trace"]["path"],
			"sha256": source_inputs["rom_driver_nsf_apu_write_trace"]["sha256"],
			"provenance": "Instrumented libgme execution of the NSF rebuilt from the supplied ROM; APU address/value/order sequence was byte-order-checked against the cartridge replay.",
			"captured_pcm_used_as_input": False,
		},
		"nsf_intermediate": {
			"path": SOURCE_NSF.relative_to(ROOT).as_posix(),
			"sha256": trace_manifest["source_nsf_sha256"],
			"cue_frame_offset_ticks": 2,
			"pcm_generated_during_trace": False,
		},
		"nsf_event_schedule": {
			"variant": "diagnostic cue offset +2 NSF PLAY ticks",
			"source": "reference/diagnostics/audio/rom_driver_apu_trace_cue_offset_plus2_20261024/",
			"runtime_schedule": False,
			"reason": "This measured bus-alignment candidate is useful for the WaveHi experiment, but it is not promoted over the shipped cue schedule.",
		},
		"mapped_apu_events": {
			"path": source_inputs["mapped_register_events"]["path"],
			"sha256": source_inputs["mapped_register_events"]["sha256"],
			"cycle_mapping": source_inputs["cycle_mapping"],
		},
		"frame_cycle_reference": {
			"path": source_inputs["fceux_frame_cycle_reference"]["path"],
			"sha256": source_inputs["fceux_frame_cycle_reference"]["sha256"],
			"use": "timing/block-boundary evidence only; not PCM synthesis input",
		},
		"frame_sequencer": {
			"mode": "source_register_and_fixed_point_clock" if source_frame_sequencer else "measured_fceux_hook_trace",
			"source": "Pinned FCEUX sound.cpp `fhinc=14915*24`, per-hook `fhcnt -= cycles*48`, one FrameSoundUpdate when `fhcnt<=0`, `$4017` reset, and source sequence-counter state." if source_frame_sequencer else "Pinned FCEUX DMC hook trace FRAME_UPDATE_IN rows.",
			"captured_frame_update_events_used": not source_frame_sequencer,
			"cycle_boundary": "Renderer evaluates the fixed-point countdown once per CPU cycle. Original FCEUX evaluates it at 6502 instruction-hook boundaries; this leaves up to one-instruction phase uncertainty." if source_frame_sequencer else "Cycle-stamped FCEUX instruction-hook events.",
		},
		"dpcm_source": {
			"path": "reference/rom_extract/audio/dpcm_sample_blob.bin",
			"sha256": file_hash(DPCM_EXTRACT),
			"rom_bank": "$1E",
			"bytes_verified_against_rom": DPCM_EXTRACT.stat().st_size,
		},
		"renderer": generic["implementation"],
		"fceux_renderer_reference": generic["fceux_source"],
		"output": {
			"path": output_path.relative_to(ROOT).as_posix(),
			"sha256": file_hash(output_path),
			"samples": (output_path.stat().st_size - 44) // 2,
			"runtime_asset": False,
			"captured_pcm_used_as_input": False,
		},
		"validation_reference": {
			"path": "reference/diagnostics/audio/fceux_cold_start_silent_pcm_precise_20261024.wav",
			"role": "comparison-only same-input FCEUX PCM",
		},
		"limits": [
			"The NSF-to-FCEUX cycle map is a measured global affine fit; register write residuals reach 0.691 ms.",
			("DMC DMA, DMC bit, and PCM_SYNC_IN timing still use the measured FCEUX DMC trace; only frame-sequencer update events are derived from source `$4017` state and the FCEUX fixed-point timer." if source_frame_sequencer else "DMC DMA and frame-sequencer callbacks are cycle-granular rather than instruction-hook exact."),
			"Do not promote this single-input diagnostic render to runtime audio without broad-window and arbitrary-start validation.",
		],
	}
	output_path.with_suffix(".json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
	return manifest


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--rom", type=Path, default=ROM_PATH)
	parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
	parser.add_argument("--source-frame-sequencer", action="store_true",
		help="derive frame-sequencer updates from source `$4017` state instead of consuming FRAME_UPDATE_IN rows")
	args = parser.parse_args()
	manifest = run(args.rom.resolve(), args.output.resolve(), args.source_frame_sequencer)
	print(manifest["output"]["path"])


if __name__ == "__main__":
	main()

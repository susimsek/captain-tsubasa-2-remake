#!/usr/bin/env python3
"""Render a ROM-stepper route with the pinned WaveHi pipeline at FCEUX volume 255.

This creates an offline diagnostic candidate only. ROM-stepper events drive the
renderer; FCEUX traces and PCM are never synthesis inputs.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_DEFAULT = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
BUILDER_PATH = ROOT / "tools/audio/render_rom_stepper_wavehi_candidate.py"
RENDERER_SOURCE = ROOT / "tools/audio/fceux_apu_wavehi_prototype/apu_wavehi_renderer.cpp"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def load_builder():
	spec = importlib.util.spec_from_file_location("rom_stepper_wavehi_candidate_builder", BUILDER_PATH)
	if spec is None or spec.loader is None:
		raise RuntimeError(f"Unable to load renderer builder: {BUILDER_PATH}")
	builder = importlib.util.module_from_spec(spec)
	sys.modules[spec.name] = builder
	spec.loader.exec_module(builder)
	return builder


def make_volume255_renderer(output_dir: Path) -> Path:
	source = RENDERER_SOURCE.read_text(encoding="utf-8")
	replacements = {
		"// Build-only diagnostic reconstruction of the FCEUX 2.7.0 soundq>=1 APU\n"
		"// WaveHi source from cycle-stamped CPU-bus writes plus measured FCEUX\n"
		"// instruction-hook frame/DMC events. This is diagnostic output, not a runtime\n"
		"// asset or a complete emulator core.":
		"// Build-only source renderer using ROM-stepper APU/DMC/frame events,\n"
		"// pinned FCEUX 2.7.0 WaveHi mixer/filter semantics, and the recorded\n"
		"// per-channel gain profile. Diagnostic output, not a complete emulator.",
		'#include "../fceux_filter_prototype/filter_pipeline.cpp"':
		f'#define FCEUX_FILTER_MASTER_VOLUME 255\n#include "{ROOT / "tools/audio/fceux_filter_prototype/filter_pipeline.cpp"}"',
		"const std::uint32_t packed_amp = static_cast<std::uint32_t>(amp) << 24;":
		"const std::uint32_t packed_amp = static_cast<std::uint32_t>((amp * 255) / 256) << 24;",
		"const std::uint32_t contribution = static_cast<std::uint32_t>(triangle_output_level()) << 16;":
		"const std::uint32_t contribution = static_cast<std::uint32_t>((triangle_output_level() * 255) / 256) << 16;",
		"const std::uint32_t active_level = static_cast<std::uint32_t>(amp * 2) << 16;":
		"const std::uint32_t active_level = static_cast<std::uint32_t>(((amp * 255) / 256) * 2) << 16;",
		"const std::uint32_t packed_amp = static_cast<std::uint32_t>(raw_dac_) << 16;":
		"const std::uint32_t packed_amp = static_cast<std::uint32_t>((raw_dac_ * 255) / 256) << 16;",
	}
	for before, after in replacements.items():
		count = source.count(before)
		if count != 1:
			raise ValueError(f"Expected one renderer source match, found {count}: {before[:90]!r}")
		source = source.replace(before, after)
	path = output_dir / "apu_wavehi_renderer_volume255.cpp"
	path.write_text(source, encoding="utf-8")
	return path


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--rom", type=Path, default=ROM_DEFAULT)
	parser.add_argument("--stepper-dir", type=Path, required=True,
		help="ROM-only stepper output directory")
	parser.add_argument("--output-dir", type=Path, required=True,
		help="diagnostic output directory; may be under /tmp")
	parser.add_argument("--source-dmc-dac-events", type=Path, default=None,
		help="defaults to source_apu_dmc_state_events.csv.gz in --stepper-dir")
	parser.add_argument("--source-frame-update-events", type=Path, default=None,
		help="defaults to source_frame_updates.csv in --stepper-dir")
	parser.add_argument("--max-source-frame", type=int, default=None)
	parser.add_argument("--append-filter-tail-frames", type=int, default=0)
	args = parser.parse_args()

	rom = args.rom.resolve()
	stepper_dir = args.stepper_dir.resolve()
	output_dir = args.output_dir.resolve()
	output_dir.mkdir(parents=True, exist_ok=True)
	dmc_events = (args.source_dmc_dac_events or stepper_dir / "source_apu_dmc_state_events.csv.gz").resolve()
	frame_updates = (args.source_frame_update_events or stepper_dir / "source_frame_updates.csv").resolve()
	if not dmc_events.is_file() or not frame_updates.is_file():
		parser.error("stepper DMC-state and frame-update event files must exist")

	builder = load_builder()
	original_renderer = builder.RENDERER
	original_root = builder.ROOT
	variant = make_volume255_renderer(output_dir)
	builder.RENDERER = variant
	# The builder's event report uses paths relative to ROOT. Use filesystem root
	# so diagnostic artifacts under /tmp are accepted, then make those paths
	# explicit absolute paths in the report below.
	builder.ROOT = Path("/")
	try:
		report = builder.run(
			rom,
			output_dir,
			source_dmc_dac_events=dmc_events,
			max_source_frame=args.max_source_frame,
			append_tail_frames=args.append_filter_tail_frames,
			stepper_dir=stepper_dir,
			source_frame_update_events=frame_updates,
		)
	finally:
		builder.RENDERER = original_renderer
		builder.ROOT = original_root

	stepper_manifest = json.loads((stepper_dir / "source_stepper_report.json").read_text(encoding="utf-8"))
	report["source"]["stepper_report"] = str(stepper_dir / "source_stepper_report.json")
	report["source"]["explicit_controller_input_timeline"]["path"] = stepper_manifest.get("input_timeline_path")
	for key in ("source_frame_update_events", "source_dmc_dac_edge_export"):
		entry = report["source_events"].get(key)
		if entry:
			entry["path"] = str(frame_updates if key == "source_frame_update_events" else dmc_events)
	report["renderer"]["source"] = str(variant)
	report["renderer"]["profile_adjustment"] = "FCEUX per-channel volumes [255,255,255,255,255] before WaveHi mixing and master SoundVolume 255 in the pinned soundq=2 SexyFilter"
	report["renderer"]["master_sound_volume"] = 255
	report["source"]["captured_fceux_event_log_used_for_synthesis"] = False
	report["source"]["captured_fceux_pcm_or_wav_used_as_synthesis_input"] = False
	report["candidate"]["path"] = str(output_dir / "rom_stepper_wavehi_candidate.wav")
	report["channel_volume_profile"] = {
		"values": [255, 255, 255, 255, 255],
		"formula": "floor(level * volume / 256), applied per channel before WaveHi mixing",
		"basis": "Recorded local FCEUX 2.7.0 output profile; not ROM content.",
	}
	report["renderer"]["source_sha256"] = sha256(variant)
	report_path = output_dir / "candidate_report.json"
	report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
	(output_dir / "README.md").write_text(
		"# ROM-only route WaveHi candidate\n\n"
		"This offline candidate uses ROM-stepper APU writes, DMC events, CPU-frame cycles, and frame-sequencer events. It applies the pinned FCEUX WaveHi mixer/filter implementation with the captured 255 per-channel profile and master SoundVolume setting. FCEUX event logs and captured PCM/WAV are validation-only inputs and are not read by the renderer.\n\n"
		"The candidate is diagnostic; it is not a runtime asset or a claim about physical NES analog output. See `candidate_report.json` for hashes, counts, and limits.\n",
		encoding="utf-8",
	)
	print(json.dumps({
		"candidate": report["candidate"],
		"source_events": report["source_events"],
		"output_dir": str(output_dir),
	}, indent=2))


if __name__ == "__main__":
	main()

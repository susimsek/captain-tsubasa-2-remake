#!/usr/bin/env python3
"""Render a diagnostic pulse/triangle/noise WaveHi model from FCEUX write evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

from prototype_fceux_filter_pipeline import FCEUX_REVISION, ROOT, SOURCE_SHA256, fetch_coeffs

TRACE_DIR = ROOT / "reference/diagnostics/audio/fceux_dmc_pcm_sync_20261025_seg1"
DEFAULT_WRITES = TRACE_DIR / "apu_writes.csv"
DEFAULT_FRAMES = TRACE_DIR / "frame_cycles.csv"
DEFAULT_DMC_TRACE = ROOT / "reference/diagnostics/audio/fceux_dmc_hook_trace_pcm_sync_sequence_ordered_merged_20261025/dmc_hook_trace.csv"
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/audio/rom_source_wavehi_channelbc_replay_20261025/source_dmc_channelbc_wavehi.wav"
RENDERER = ROOT / "tools/audio/fceux_apu_wavehi_prototype/apu_wavehi_renderer.cpp"
DEFAULT_ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
DPCM_EXTRACT = ROOT / "reference/rom_extract/audio/dpcm_sample_blob.bin"
ROM_HASH = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def run(args: argparse.Namespace) -> dict:
	output = args.output.resolve()
	output.parent.mkdir(parents=True, exist_ok=True)
	rom_path = args.rom.resolve()
	rom_bytes = rom_path.read_bytes()
	if hashlib.sha256(rom_bytes).hexdigest() != ROM_HASH:
		raise ValueError("the input ROM hash does not match the supplied reference ROM")
	prg_start = 16 + (512 if rom_bytes[6] & 0x04 else 0)
	bank_1e_start = prg_start + 0x1e * 0x2000
	bank_1e = rom_bytes[bank_1e_start:bank_1e_start + 0x2000]
	if len(bank_1e) != 0x2000:
		raise ValueError("ROM has no complete physical PRG bank $1E")
	extracted_dpcm = DPCM_EXTRACT.read_bytes()
	if bank_1e[:len(extracted_dpcm)] != extracted_dpcm:
		raise ValueError("physical bank $1E bytes do not match the preserved DPCM source extract")
	with tempfile.TemporaryDirectory(prefix="ct2_fceux_apu_wavehi_") as temporary:
		work = Path(temporary)
		_, fetched_hashes = fetch_coeffs(work)
		binary = work / "fceux_apu_wavehi_renderer"
		subprocess.run([
			"clang++", "-std=c++17", "-O3", "-DNDEBUG", "-Wall", "-Wextra", "-Wno-unused-function",
			"-I", str(work), str(RENDERER), "-o", str(binary),
		], check=True)
		render_command = [
			str(binary), str(args.writes.resolve()), str(args.frame_cycles.resolve()), str(args.dmc_trace.resolve()), str(rom_path), str(output),
		]
		source_frame_sequencer = bool(getattr(args, "source_frame_sequencer", False))
		if source_frame_sequencer:
			render_command.append("--source-frame-sequencer")
		completed = subprocess.run(render_command, check=False, capture_output=True, text=True)
		if completed.returncode != 0:
			raise RuntimeError(f"WaveHi renderer failed (exit={completed.returncode}): {completed.stderr.strip()}")

	metadata = {
			"purpose": "Build-only diagnostic APU-to-WaveHi synthesis for source APU writes and compact DMC-state trace; captured PCM is validation-only and never renderer input.",
		"rom": {
			"filename": "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes",
			"sha256": ROM_HASH,
			"runtime_dependency": False,
			"dmc_source": {
				"file": "reference/rom_extract/audio/dpcm_sample_blob.bin",
				"sha256": sha256(DPCM_EXTRACT),
				"read_only_input": True,
				"source_bank": "$1E",
				"cpu_window_mapping": "$C000-$DFFF maps physical PRG bank $1E in the observed opening MMC3 state; cold_start_observed_dispatch.json records C000=$1E at the relevant source-handler entries.",
				"verified_prefix_bytes": len(extracted_dpcm),
			},
		},
		"fceux_source": {
			"repository": "https://github.com/TASEmulators/fceux",
			"revision": FCEUX_REVISION,
			"verified_source_sha256": {**SOURCE_SHA256, "fir/c44100ntsc.h": fetched_hashes["fir/c44100ntsc.h"]},
			"model": "soundq>=1, NTSC, 44.1 kHz, channel/master gains 256, low-pass disabled",
			"source_boundaries": "FCEUX 2.7.0 RDoSQ/RDoTriangle/RDoNoise/RDoPCM are flushed lazily at their channel-specific APU writes, FrameSoundStuff's four channel calls, StatusWrite's five channel calls, DMC PCM_SYNC_IN, and frame end; ChannelBC is translated to a frame-local coordinate with the soundq=2 overlap held by the filter pipeline.",
		},
		"inputs": {
			"fceux_cpu_bus_write_trace": {
				"path": args.writes.resolve().relative_to(ROOT).as_posix(),
				"sha256": sha256(args.writes.resolve()),
				"purpose": "CPU APU register writes and their source-cycle timestamps",
			},
			"fceux_dmc_hook_trace": {
				"path": args.dmc_trace.resolve().relative_to(ROOT).as_posix(),
				"sha256": sha256(args.dmc_trace.resolve()),
				"purpose": "Measured DMC byte fetches/bit edges and PCM_SYNC_IN DAC phase corrections" if source_frame_sequencer else "Measured FCEUX timing for frame-sequencer updates, DMC byte fetches/bit edges, and PCM_SYNC_IN DAC phase corrections",
			},
			"fceux_frame_cycles": {
				"path": args.frame_cycles.resolve().relative_to(ROOT).as_posix(),
				"sha256": sha256(args.frame_cycles.resolve()),
				"purpose": "cycle lengths for stateful filter blocks",
			},
		},
		"implementation": {
			"file": RENDERER.relative_to(ROOT).as_posix(),
			"source_sha256": sha256(RENDERER),
			"modeled_channels": ["pulse 1", "pulse 2", "triangle", "noise", "DMC"],
			"ported_behavior": [
				"FCEUX power/reset initial state and soundq>=1 WaveHi channel fixed-point contributions",
				"per-channel ChannelBC fill boundaries at PSG writes, frame-sequencer updates, status writes, DMC PCM sync, and frame end",
				"pulse timer, duty, length, envelope, sweep and frequency-mute checks",
				"triangle timer, linear counter, length and held DAC level",
				"noise timer, envelope, length gate, and 15-bit LFSR feedback",
				"DMC address/length/rate registers and bank-$1E byte reads reconstructed from ROM, synchronized to measured FCEUX fetch and bit-state events",
				"DMC DAC transitions scheduled from FCEUX PCM_SYNC_IN timestamps after applying the recorded fudge offset",
				"FCEUX nonlinear pulse/TND lookup mix followed by the pinned soundq=2 FIR/resampler and SexyFilter",
				"cycle-stamped register writes and frame-cycle blocks; oscillator/filter state persists across blocks",
			],
			"omitted_or_approximated": [
				("The frame sequencer runs from the source-derived `$4017` reset and fixed-point NTSC countdown, but its threshold is checked per CPU cycle rather than at the original 6502 instruction hook; DMC fetch/bit/DAC event times remain replayed from the pinned FCEUX trace." if source_frame_sequencer else "CPU-cycle frame-sequencer and DMC events remain pinned-FCEUX trace inputs; this does not reproduce the 6502 instruction loop or instruction/DMA opportunity phase. The boundary semantics are source-ported but exact output agreement is unproven.")
			],
			"frame_sequencer_mode": "source_register_and_fixed_point_clock" if source_frame_sequencer else "measured_fceux_hook_trace",
			"captured_pcm_used_as_input": False,
			"runtime_asset": False,
		},
		"render": {
			"path": output.relative_to(ROOT).as_posix(),
			"sha256": sha256(output),
			"samples": (output.stat().st_size - 44) // 2,
			"renderer_stdout": completed.stdout.strip(),
		},
		"validation_reference": {
			"path": "reference/diagnostics/audio/fceux_cold_start_silent_pcm_precise_20261024.wav",
			"role": "comparison only",
		},
		"interpretation": ("Diagnostic source APU renderer. Frame-sequencer updates are generated from the `$4017` register state and pinned FCEUX NTSC fixed-point countdown, without consuming `FRAME_UPDATE_IN` trace rows. DMC fetch/bit-state/DAC events still come from the pinned FCEUX replay; this is not a full instruction/DMA simulation or Godot runtime asset." if source_frame_sequencer else "Diagnostic ROM-source-driven renderer. DMC fetch bytes are checked against ROM bank $1E; DMC fetch/bit-state and frame-sequencer events are replayed from the pinned FCEUX trace; each DMC DAC change is scheduled at the PCM_SYNC_IN-adjusted WaveHi position; and ChannelBC-aware lazy channel fills follow the pinned FCEUX sound.cpp call boundaries. CPU-cycle event timing still comes from the instrumented FCEUX replay, so this is not an exact CPU/APU reconstruction or a Godot runtime asset."),
	}
	output.with_suffix(".json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
	return metadata


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--writes", type=Path, default=DEFAULT_WRITES)
	parser.add_argument("--frame-cycles", type=Path, default=DEFAULT_FRAMES)
	parser.add_argument("--dmc-trace", type=Path, default=DEFAULT_DMC_TRACE)
	parser.add_argument("--rom", type=Path, default=DEFAULT_ROM)
	parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
	parser.add_argument("--source-frame-sequencer", action="store_true",
		help="derive frame-sequencer updates from source $4017 state and the pinned fixed-point clock; DMC timing remains trace-driven")
	args = parser.parse_args()
	metadata = run(args)
	print(metadata["render"]["path"])


if __name__ == "__main__":
	main()

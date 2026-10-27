#!/usr/bin/env python3
"""Prototype pinned FCEUX soundq=2 filters over a ROM-derived signal surrogate."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path
from urllib.request import urlopen

from compare_opening_audio_envelopes import NTSC_CPU_HZ, ROOT

FCEUX_REVISION = "a6d03e7968bd77a8156a7c9b628a673753f2f4c6"
FCEUX_BASE = f"https://raw.githubusercontent.com/TASEmulators/fceux/{FCEUX_REVISION}/src"
SOURCE_SHA256 = {
	"filter.cpp": "ddde69adb6cdd940a54535f3a39f39ae3233b5d110624cae14a553be1a4ad4d4",
	"sound.cpp": "10e4223d666f87b27f319fcb7759b644c686d8728e0799a49935b845bbc80de5",
	"wave.cpp": "f5e02189dd9c3501017aa7bce833cf6cb97e3ffdbdf410bd5d2962653a04f379",
	"fcoeffs.h": "aac6289c43da2540bad1b2a321dc5afb00225a1504611d07a5ee147d09cefdcc",
	"fir/c44100ntsc.h": "47bbd5ec088344f3d83978796e617ec211dbdeee3b29a5584162428918160691",
	"x6502.h": "39fccaf76ee38c349f5e06c7b302712ecf24268076ca09aebb9ba887aa00e704",
}
PROTOTYPE_DIR = ROOT / "tools/audio/fceux_filter_prototype"
DEFAULT_SOURCE_WAV = ROOT / "reference/diagnostics/audio/rom_driver_apu_trace_cue_offset_plus2_20261024/rom_driver_candidate_raw.wav"
DEFAULT_FRAME_CYCLES = ROOT / "reference/diagnostics/audio/fceux_apu_write_trace_20261024_184945_utc/frame_cycles.csv"
DEFAULT_COMPARISON = ROOT / "reference/diagnostics/audio/apu_write_timing_comparison_20261024.json"
DEFAULT_OUTPUT = ROOT / "reference/diagnostics/audio/rom_driver_apu_trace_cue_offset_plus2_20261024/fceux_filter_on_libgme_source_signal.wav"


def sha256(data: bytes) -> str:
	return hashlib.sha256(data).hexdigest()


def fetch_coeffs(work: Path) -> tuple[list[int], dict[str, str]]:
	hashes: dict[str, str] = {}
	for relative, expected in SOURCE_SHA256.items():
		data = urlopen(f"{FCEUX_BASE}/{relative}", timeout=30).read()
		actual = sha256(data)
		if actual != expected:
			raise ValueError(f"Pinned FCEUX source hash mismatch for {relative}: {actual}")
		hashes[relative] = actual

	coeff_text = urlopen(f"{FCEUX_BASE}/fir/c44100ntsc.h", timeout=30).read().decode("ascii")
	coeffs = [int(value) for value in re.findall(r"-?\d+", coeff_text)]
	if len(coeffs) != 512:
		raise ValueError(f"Expected 512 FCEUX half-table coefficients, found {len(coeffs)}")
	mirrored = coeffs + list(reversed(coeffs))
	header = "#pragma once\n#include <cstdint>\nstatic constexpr std::int32_t kFceuxSq2Coefficients[1024] = {\n"
	for start in range(0, len(mirrored), 8):
		header += "\t" + ", ".join(str(value) for value in mirrored[start:start + 8]) + ",\n"
	header += "};\n"
	(work / "fceux_fir_coefficients.hpp").write_text(header, encoding="utf-8")
	return coeffs, hashes


def run(args: argparse.Namespace) -> dict:
	output_path = args.output.resolve()
	output_path.parent.mkdir(parents=True, exist_ok=True)
	comparison_path = args.comparison.resolve()
	comparison = json.loads(comparison_path.read_text(encoding="utf-8"))
	clock = comparison["clock_alignment"]
	scale = clock["scale_fceux_cycles_per_nsf_cycle"]
	phase = clock["phase_offset_cycles"]["decimal"]

	with tempfile.TemporaryDirectory(prefix="ct2_fceux_filter_") as temporary:
		work = Path(temporary)
		coeffs, source_hashes = fetch_coeffs(work)
		binary = work / "fceux_filter_pipeline"
		subprocess.run([
			"clang++", "-std=c++17", "-O3", "-DNDEBUG",
			"-I", str(work),
			str(PROTOTYPE_DIR / "filter_pipeline.cpp"),
			"-o", str(binary),
		], check=True)
		completed = subprocess.run([
			str(binary),
			str(args.source_wav.resolve()),
			str(args.frame_cycles.resolve()),
			str(output_path),
			str(scale["numerator"]),
			str(scale["denominator"]),
			str(phase),
		], check=True, capture_output=True, text=True)

	metadata = {
		"purpose": "Build-only port of the pinned FCEUX soundq=2 resampler and SexyFilter, tested over a clearly labeled ROM-derived surrogate input.",
		"source_signal": {
			"path": args.source_wav.resolve().relative_to(ROOT).as_posix(),
			"sha256": sha256(args.source_wav.resolve().read_bytes()),
			"domain": "libgme 44.1-kHz mono PCM rendered from the original-ROM NSF, sample-held at CPU-cycle positions",
			"is_fceux_wavehi": False,
			"captured_pcm_used_as_input": False,
		},
		"frame_cycle_map": {
			"path": args.frame_cycles.resolve().relative_to(ROOT).as_posix(),
			"sha256": sha256(args.frame_cycles.resolve().read_bytes()),
			"mapping": "FCEUX cycles to candidate NSF cycles by one rational scale and one phase from apu_write_timing_comparison_20261024.json",
			"fceux_cycles_per_nsf_cycle": scale,
			"phase_offset_cycles": phase,
		},
		"fceux_source": {
			"repository": "https://github.com/TASEmulators/fceux",
			"revision": FCEUX_REVISION,
			"verified_source_sha256": source_hashes,
			"quality": "soundq=2, NTSC, 44.1 kHz, low-pass disabled, SoundVolume=256",
			"fir_coefficients_half_table_count": len(coeffs),
		},
		"implementation": {
			"file": "tools/audio/fceux_filter_prototype/filter_pipeline.cpp",
			"ported_functions": ["NeoFilterSound (1024-tap FIR, 16.16 resampling phase, 1025-sample overlap)", "SexyFilter (fixed-point acc1/acc2 state, soundq=2 gain and clamp)"],
			"state": "FIR position, 1025-sample overlap and both SexyFilter accumulators persist across FCEUX frame-cycle blocks",
			"source_wavehi_mix_tables_applied": False,
		},
		"output": {
			"path": output_path.relative_to(ROOT).as_posix(),
			"sha256": sha256(output_path.read_bytes()),
			"sample_count": (output_path.stat().st_size - 44) // 2,
			"renderer_stdout": completed.stdout.strip(),
			"runtime_asset": False,
		},
		"validation_reference": {
			"fceux_pcm_path": "reference/diagnostics/audio/fceux_cold_start_silent_pcm_precise_20261024.wav",
			"role": "comparison only; not read by renderer",
		},
		"unresolved_upstream_synthesis": [
			"The input is already-resampled libgme PCM, not FCEUX WaveHi. The original FCEUX 2A03 pulse/triangle/noise/DMC oscillator states and nonlinear channel lookup mixing remain unimplemented.",
			"The sample-hold surrogate cannot validate the FCEUX FIR at its true per-cycle WaveHi input; comparisons can show whether the exact downstream filter stage changes envelopes/tail, not whether it reproduces original audio.",
			"The original game's DMC sample fetch memory reads and reset/frame-sequencer state are not emitted by the register trace; the DPCM ROM bytes are available but full DMC playback phase still needs a verified APU state model.",
		],
	}
	output_path.with_suffix(".json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
	return metadata


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--source-wav", type=Path, default=DEFAULT_SOURCE_WAV)
	parser.add_argument("--frame-cycles", type=Path, default=DEFAULT_FRAME_CYCLES)
	parser.add_argument("--comparison", type=Path, default=DEFAULT_COMPARISON)
	parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
	args = parser.parse_args()
	metadata = run(args)
	print(metadata["output"]["path"])


if __name__ == "__main__":
	main()

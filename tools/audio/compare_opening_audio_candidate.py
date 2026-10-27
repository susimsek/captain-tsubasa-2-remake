#!/usr/bin/env python3
"""Compare a build-only ROM-source WAV candidate with FCEUX and current runtime audio."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from compare_runtime_wav_to_fceux_pcm import (
	FPS,
	REFERENCE,
	RUNTIME,
	WINDOWS,
	compare_window,
	read_pcm,
)

ROOT = Path(__file__).resolve().parents[2]
CANDIDATE_DIR = ROOT / "reference/diagnostics/audio/rom_driver_rebuilt_candidate_20261025"
CANDIDATE = CANDIDATE_DIR / "opening_timeline_candidate.wav"
BUILD_MANIFEST = CANDIDATE_DIR / "candidate_build_manifest.json"
OUTPUT = CANDIDATE_DIR / "validation_comparison.json"
HISTORICAL_RUNTIME_NSF_SHA256 = "355c89601ce5c12c1f66451d9680fb34d5b33a8997d35807265f470d84a06aa1"


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def preserved_nsfs_matching(expected_sha256: str) -> list[str]:
	return [
		path.relative_to(ROOT).as_posix()
		for path in ROOT.rglob("*.nsf")
		if sha256(path) == expected_sha256
	]


def main() -> None:
	manifest = json.loads(BUILD_MANIFEST.read_text(encoding="utf-8"))
	reference_pcm = read_pcm(REFERENCE)
	runtime_pcm = read_pcm(RUNTIME)
	candidate_pcm = read_pcm(CANDIDATE)
	windows: dict[str, dict] = {}
	for name, frame_range in WINDOWS.items():
		windows[name] = {
			"candidate_vs_fceux": compare_window(reference_pcm, candidate_pcm, name, frame_range),
			"runtime_vs_fceux": compare_window(reference_pcm, runtime_pcm, name, frame_range),
			"candidate_vs_runtime": compare_window(runtime_pcm, candidate_pcm, name, frame_range),
		}
	comparison = {
		"purpose": "Validation-only comparison. FCEUX captured PCM is read solely as a reference; it is never a synthesis input.",
		"source_rom_sha256": manifest["source_rom_sha256"],
		"sample_rate_hz": 44_100,
		"frame_rate_hz": FPS,
		"artifacts": {
			"fceux_pcm_reference": {
				"path": REFERENCE.relative_to(ROOT).as_posix(),
				"sha256": sha256(REFERENCE),
				"sample_count": len(reference_pcm),
				"role": "comparison-only input",
			},
			"godot_runtime_wav": {
				"path": RUNTIME.relative_to(ROOT).as_posix(),
				"sha256": sha256(RUNTIME),
				"sample_count": len(runtime_pcm),
				"role": "existing runtime asset; unchanged by candidate build",
			},
			"rom_source_candidate": {
				"path": CANDIDATE.relative_to(ROOT).as_posix(),
				"sha256": sha256(CANDIDATE),
				"sample_count": len(candidate_pcm),
				"source_nsf_path": manifest["source_nsf_path"],
				"source_nsf_sha256": manifest["source_nsf_sha256"],
				"role": "build-only candidate; not a runtime asset",
			},
		},
		"historical_manifest_check": {
			"runtime_manifest_expected_nsf_sha256": HISTORICAL_RUNTIME_NSF_SHA256,
			"matching_preserved_nsf_files": preserved_nsfs_matching(HISTORICAL_RUNTIME_NSF_SHA256),
			"current_rom_builder_nsf_sha256": manifest["source_nsf_sha256"],
			"current_builder_candidate_wav_sha256": manifest["candidate_wav_sha256"],
			"current_builder_candidate_matches_shipped_runtime": manifest["candidate_wav_sha256"] == sha256(RUNTIME),
			"preserved_unaligned_intermediate_sha256": "89bd6b8ccafbb191f55df1c25353903872065449b26fddd0b388d29e17ff0fd6",
			"fresh_candidate_unaligned_intermediate_sha256": manifest["intermediate_wav_sha256"],
			"fresh_intermediate_matches_preserved_intermediate": manifest["intermediate_wav_sha256"] == "89bd6b8ccafbb191f55df1c25353903872065449b26fddd0b388d29e17ff0fd6",
		},
		"windows": windows,
		"limits": [
			"The runtime and candidate cue frames are derived from the same FCEUX RAM $0700 capture schedule.",
			"This compares the current builder against one captured input replay; it does not establish arbitrary-start timing or sample-exact equivalence.",
			"The candidate was synthesized from a ROM-derived NSF using libgme; FCEUX PCM was comparison-only.",
		],
	}
	OUTPUT.write_text(json.dumps(comparison, indent=2) + "\n", encoding="utf-8")
	print(OUTPUT.relative_to(ROOT).as_posix())


if __name__ == "__main__":
	main()

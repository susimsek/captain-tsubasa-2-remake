#!/usr/bin/env python3
"""Build source-only Godot WAV resources for verified first-match route cues.

Each output is rendered by the original ROM sound driver in an offline NSF
wrapper. No emulator PCM, captured WAV, or capture-derived event timestamps are
used as synthesis input. The JSON sidecar records source pointers and hashes.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "tools/audio/build"
ASSET_ROOT = ROOT / "assets/gameplay/audio"

CUES = {
    0x2B: {
        "kind": "sound_effect",
        "observed_route_queue": True,
        "sound_test_ordinal": 78,
        "source_pointer_file_offset": "0x018C3E",
        "source_pointer_cpu": "0x9453",
        "sequence_file_offset": "0x019463",
        "seconds": 3,
        "nsf_name": "first_match_sfx_2B.nsf",
        "wav_name": "match_sfx_2B_rom_generated.wav",
    },
    0x2C: {
        "kind": "sound_effect",
        "observed_route_queue": True,
        "sound_test_ordinal": 79,
        "source_pointer_file_offset": "0x018C40",
        "source_pointer_cpu": "0x9803",
        "sequence_file_offset": "0x019813",
        "seconds": 3,
        "nsf_name": "first_match_sfx_2C.nsf",
        "wav_name": "match_sfx_2C_rom_generated.wav",
    },
    0x30: {
        "kind": "sound_effect",
        "observed_route_queue": False,
        "sound_test_ordinal": 83,
        "source_pointer_file_offset": "0x018C48",
        "source_pointer_cpu": "0x9C13",
        "sequence_file_offset": "0x019C23",
        "seconds": 3,
        "nsf_name": "first_match_sfx_30.nsf",
        "wav_name": "match_sfx_30_rom_generated.wav",
    },
    0x31: {
        "kind": "sound_effect",
        "observed_route_queue": True,
        "sound_test_ordinal": None,
        "source_pointer_file_offset": "0x018C4A",
        "source_pointer_cpu": "0x9FFE",
        "sequence_file_offset": "0x01A00E",
        "seconds": 3,
        "nsf_name": "first_match_sfx_31.nsf",
        "wav_name": "match_sfx_31_rom_generated.wav",
        "empty_sequence": True,
    },
    0x35: {
        "kind": "bgm",
        "sound_test_ordinal": 34,
        "source_pointer_file_offset": "0x018C52",
        "source_pointer_cpu": "0xA5C6",
        "sequence_file_offset": "0x01A5D6",
        "seconds": 90,
        "nsf_name": "first_match_track_35.nsf",
        "wav_name": "match_track_35_rom_generated.wav",
        "observed_route_queue": False,
    },
    0x36: {
        "kind": "bgm",
        "sound_test_ordinal": 38,
        "source_pointer_file_offset": "0x018C54",
        "source_pointer_cpu": "0xB68D",
        "sequence_file_offset": "0x01B69D",
        "seconds": 90,
        "nsf_name": "first_match_track_36.nsf",
        "wav_name": "match_track_36_rom_generated.wav",
        "observed_route_queue": False,
    },
    0x3C: {
        "kind": "bgm",
        "observed_route_queue": True,
        "sound_test_ordinal": 27,
        "source_pointer_file_offset": "0x018C60",
        "source_pointer_cpu": "0xB514",
        "sequence_file_offset": "0x01B524",
        "seconds": 90,
        "nsf_name": "first_match_track_3C.nsf",
        "wav_name": "match_track_3C_rom_generated.wav",
    },
    0x53: {
        "kind": "bgm",
        "observed_route_queue": True,
        "sound_test_ordinal": 4,
        "source_pointer_file_offset": "0x018C8E",
        "source_pointer_cpu": "0xA5E0",
        "sequence_file_offset": "0x01E5F0",
        "seconds": 90,
        "nsf_name": "first_match_track_53.nsf",
        "wav_name": "match_track_53_rom_generated.wav",
    },
    0x45: {
        "kind": "bgm",
        "observed_route_queue": False,
        "sound_test_ordinal": 1,
        "source_pointer_file_offset": "0x018C72",
        "source_pointer_cpu": "0xA964",
        "sequence_file_offset": "0x01C974",
        "seconds": 90,
        "nsf_name": "first_match_track_45.nsf",
        "wav_name": "match_track_45_rom_generated.wav",
    },
    0x44: {
        "kind": "bgm",
        "observed_route_queue": False,
        "sound_test_ordinal": 21,
        "source_pointer_file_offset": "0x018C70",
        "source_pointer_cpu": "0x8CC0",
        "sequence_file_offset": "0x018CD0",
        "seconds": 90,
        "nsf_name": "first_match_track_44.nsf",
        "wav_name": "match_track_44_rom_generated.wav",
        "observed_route_queue": False,
    },
    0x51: {
        "kind": "bgm",
        "observed_route_queue": False,
        "sound_test_ordinal": 2,
        "source_pointer_file_offset": "0x018C8A",
        "source_pointer_cpu": "0xAAA8",
        "sequence_file_offset": "0x01EAB8",
        "seconds": 90,
        "nsf_name": "first_match_track_51.nsf",
        "wav_name": "match_track_51_rom_generated.wav",
    },
    0x55: {
        "kind": "bgm",
        "observed_route_queue": True,
        "sound_test_ordinal": 3,
        "source_pointer_file_offset": "0x018C92",
        "source_pointer_cpu": "0xA30F",
        "sequence_file_offset": "0x01E31F",
        "seconds": 90,
        "nsf_name": "first_match_track_55.nsf",
        "wav_name": "match_track_55_rom_generated.wav",
    },
    0x69: {
        "kind": "sound_effect",
        "observed_route_queue": False,
        "sound_test_ordinal": 93,
        "source_pointer_file_offset": "0x018CBA",
        "source_pointer_cpu": "0x9F9C",
        "sequence_file_offset": "0x019FAC",
        "seconds": 3,
        "nsf_name": "first_match_sfx_69.nsf",
        "wav_name": "match_sfx_69_rom_generated.wav",
    },
    0x66: {
        "kind": "sound_effect",
        "observed_route_queue": True,
        "sound_test_ordinal": 91,
        "source_pointer_file_offset": "0x018CB4",
        "source_pointer_cpu": "0x99FC",
        "sequence_file_offset": "0x019A0C",
        "seconds": 3,
        "nsf_name": "first_match_sfx_66.nsf",
        "wav_name": "match_sfx_66_rom_generated.wav",
    },
}


def load_module(name: str, relative_path: str):
    path = ROOT / relative_path
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load {relative_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    builder = load_module("route_nsf_builder", "tools/audio/build_intro_nsf.py")
    renderer = load_module("route_nsf_renderer", "tools/audio/render_rom_driver_nsf.py")
    for queue_id, source in CUES.items():
        nsf_path = BUILD / str(source["nsf_name"])
        wav_path = ASSET_ROOT / str(source["wav_name"])
        build_info = builder.build(queue_id, nsf_path)
        duration = int(source["seconds"])
        renderer.render(nsf_path, wav_path, duration, 44100, True)
        manifest = {
            "source_rom_sha256": build_info["source_rom_sha256"],
            "cue": f"0x{queue_id:02X}",
            "cue_kind": source["kind"],
            "runtime_pointer_table_file_offset": source["source_pointer_file_offset"],
            "runtime_pointer_cpu_address": source["source_pointer_cpu"],
            "sequence_file_offset": source["sequence_file_offset"],
            "sound_test_ordinal": source["sound_test_ordinal"],
            "empty_sequence": bool(source.get("empty_sequence", False)),
            "observed_route_queue": bool(source.get("observed_route_queue", False)),
            "sequence_prg_bank": build_info["music_prg_bank"],
            "sequence_bank_file_offset": build_info["music_source_file_offset"],
            "source_nsf": str(nsf_path.relative_to(ROOT)),
            "source_nsf_sha256": sha256(nsf_path.read_bytes()),
            "wav": str(wav_path.relative_to(ROOT)),
            "wav_sha256": sha256(wav_path.read_bytes()),
            "sample_rate": 44100,
            "channels": 1,
            "seconds": duration,
            "renderer": "libgme 0.6.5, offline NSF execution of supplied ROM sound driver and cue data",
            "captured_pcm_used": False,
            "capture_used": False,
            "runtime_needs_rom_or_emulator": False,
            "driver_mmc3_write_patches": build_info["driver_mmc3_write_patches"],
            "validation_status": (
                "ROM-only empty sequence; first byte is FF; renderer output is silence."
                if source.get("empty_sequence", False)
                else "ROM-only source render; not compared against reference PCM or independently verified for timing/timbre."
            ),
        }
        sidecar = wav_path.with_suffix(".json")
        sidecar.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        print(f"Built ROM cue ${queue_id:02X}: {wav_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

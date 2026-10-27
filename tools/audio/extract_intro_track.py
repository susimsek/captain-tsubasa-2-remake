#!/usr/bin/env python3
"""Extract the verified intro music sequence and driver-bank bytes from the supplied ROM.

This preserves original source bytes for analysis. It does not render audio and does
not use emulator output. All offsets below are absolute offsets in the iNES file.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT = ROOT / "reference" / "rom_extract" / "audio"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

# Disassembly labels checked against this ROM's bank mapping and stream headers.
TRACK_START = 0x01F7BD
TRACK_END_INCLUSIVE = 0x020001
CHANNELS = [
    {"id": "04", "start": 0x01F7CA, "end_inclusive": 0x01FACC},
    {"id": "05", "start": 0x01FACD, "end_inclusive": 0x01FD6D},
    {"id": "06", "start": 0x01FD6E, "end_inclusive": 0x01FF4E},
    {"id": "07", "start": 0x01FF4F, "end_inclusive": 0x020001},
]

# The original 6502 sound driver entry point is in switchable PRG bank $8C.
DRIVER_BANK_START = 0x018010
DRIVER_BANK_END_INCLUSIVE = 0x01A00F

# The sequence and all four channel streams are in switchable PRG bank $8F.
MUSIC_BANK_START = 0x01E010
MUSIC_BANK_END_INCLUSIVE = 0x02000F

# A byte-for-byte match against the disassembly repository's DPCM.bin identified
# this original sample blob in the supplied ROM. Keep it as source data only;
# the exact MMC3/DMC address mapping still needs runtime confirmation.
DPCM_BLOB_START = 0x03C010
DPCM_BLOB_SIZE = 1009


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write_bytes(name: str, data: bytes) -> dict[str, object]:
    path = OUT / name
    path.write_bytes(data)
    return {"path": str(path.relative_to(ROOT)), "size_bytes": len(data), "sha256": sha256(data)}


def main() -> None:
    data = ROM.read_bytes()
    digest = sha256(data)
    if digest != ROM_SHA256:
        raise SystemExit(f"Unexpected ROM SHA-256: {digest}")
    if data[:4] != b"NES\x1a":
        raise SystemExit("Input does not have a valid iNES header")

    OUT.mkdir(parents=True, exist_ok=True)
    track = data[TRACK_START : TRACK_END_INCLUSIVE + 1]
    driver = data[DRIVER_BANK_START : DRIVER_BANK_END_INCLUSIVE + 1]
    music_bank = data[MUSIC_BANK_START : MUSIC_BANK_END_INCLUSIVE + 1]
    dpcm_blob = data[DPCM_BLOB_START : DPCM_BLOB_START + DPCM_BLOB_SIZE]

    channel_metadata = []
    for channel in CHANNELS:
        raw = data[channel["start"] : channel["end_inclusive"] + 1]
        channel_metadata.append(
            {
                "id": channel["id"],
                "rom_file_start_inclusive": f"0x{channel['start']:06X}",
                "rom_file_end_inclusive": f"0x{channel['end_inclusive']:06X}",
                "size_bytes": len(raw),
                "sha256": sha256(raw),
            }
        )

    files = {
        "intro_track_58.bin": write_bytes("intro_track_58.bin", track),
        "bank_8c_sound_driver.bin": write_bytes("bank_8c_sound_driver.bin", driver),
        "bank_8f_music_data.bin": write_bytes("bank_8f_music_data.bin", music_bank),
        "dpcm_sample_blob.bin": write_bytes("dpcm_sample_blob.bin", dpcm_blob),
    }
    metadata = {
        "source_rom": ROM.name,
        "source_rom_sha256": digest,
        "format": "iNES 1.0; offsets are absolute file offsets including the 16-byte iNES header",
        "track": {
            "id": "0x58",
            "name": "intro/opening cue",
            "prg_bank": "0x0F / disassembly bank label 8F (CPU address $B7AD; the original machine code writes the selected bank through MMC3 register $8001)",
            "header_cpu_address": "$B7AD",
            "header_file_offset": f"0x{TRACK_START:06X}",
            "rom_file_start_inclusive": f"0x{TRACK_START:06X}",
            "rom_file_end_inclusive": f"0x{TRACK_END_INCLUSIVE:06X}",
            "channels": channel_metadata,
            "file": files["intro_track_58.bin"],
        },
        "driver": {
            "entry_cpu_address": "$8000",
            "entry_file_offset": "0x018010",
            "entry_symbol_from_byte_verified_disassembly": "sub_0x018010_sound_engine_update",
            "prg_bank": "0x0C (bank 8C)",
            "file": files["bank_8c_sound_driver.bin"],
            "note": "This is original 6502 driver code, not a standalone audio waveform. It requires the game's CPU/RAM/APU and MMC3 bank context to execute faithfully. The local disassembly renders the operand symbol as $5115, but the verified 6502 instruction bytes are 8C 01 80: STY $8001.",
        },
        "music_data_bank": {
            "prg_bank": "0x0F (bank 8F)",
            "rom_file_start_inclusive": f"0x{MUSIC_BANK_START:06X}",
            "rom_file_end_inclusive": f"0x{MUSIC_BANK_END_INCLUSIVE:06X}",
            "file": files["bank_8f_music_data.bin"],
        },
        "dpcm_sample_blob": {
            "rom_file_start_inclusive": f"0x{DPCM_BLOB_START:06X}",
            "rom_file_end_inclusive": f"0x{DPCM_BLOB_START + DPCM_BLOB_SIZE - 1:06X}",
            "size_bytes": DPCM_BLOB_SIZE,
            "byte_verified_lead": "Exact match to DPCM.bin in the local disassembly repository; the target ROM itself is the extraction source.",
            "file": files["dpcm_sample_blob.bin"],
            "mapping_note": "The F9/FA/FB driver handlers program DMC $4012/$4013. Their DMC-address-to-ROM-bank mapping on this mapper has not yet been traced, so this source blob is not assigned to those commands as a proven playback mapping.",
        },
        "nsf_banking_analysis": {
            "source_cartridge_mapper": 4,
            "source_prg_layout": "32 x 8 KiB banks; iNES header excluded from bank arithmetic",
            "nsf_page_size": "4 KiB",
            "known_page_pairs": [
                {"source_bank": "0x0C (bank label 8C)", "nsf_page_indices": [24, 25], "source_file_offsets": ["0x018010", "0x019010"], "original_cpu_windows": ["$8000-$8FFF", "$9000-$9FFF"]},
                {"source_bank": "0x0F (bank label 8F)", "nsf_page_indices": [30, 31], "source_file_offsets": ["0x01E010", "0x01F010"], "original_cpu_windows": ["$A000-$AFFF", "$B000-$BFFF"]},
                {"source_bank": "0x1E (DPCM blob's physical PRG bank)", "nsf_page_indices": [60, 61], "source_file_offsets": ["0x03C010", "0x03D010"], "original_cpu_windows": ["MMC3 mapping to be confirmed"]},
            ],
            "limitation": "The game driver expects MMC3 $8001 bank writes and original RAM/channel initialization. Standard NSF 4 KiB pages are not a drop-in replacement; no init/play wrapper or bank-write translation has been implemented.",
        },
        "extraction": {
            "method": "Copied exact byte ranges from the supplied ROM after validating its full-file SHA-256; no emulator capture, WAV, or screenshot is used.",
            "runtime_note": "These reference extracts are not runtime dependencies. A playback implementation still needs a byte-verified driver/sequence renderer or a pre-render generated from the original driver.",
        },
    }
    (OUT / "intro_track_58.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"track": files["intro_track_58.bin"], "driver": files["bank_8c_sound_driver.bin"], "music_bank": files["bank_8f_music_data.bin"], "dpcm_blob": files["dpcm_sample_blob.bin"], "metadata": str((OUT / 'intro_track_58.json').relative_to(ROOT))}, indent=2))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Preserve ROM data used by the fresh-start first-menu player state model."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT_DIR = ROOT / "reference/rom_extract/gameplay/first_match_player_state"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"


def fixed(cpu: int) -> int:
    return 0x03C010 + cpu - 0xC000


def bank1(cpu: int) -> int:
    return 0x002010 + cpu - 0xA000


def bank1c(cpu: int) -> int:
    return 0x038010 + cpu - 0x8000


def read(rom: bytes, offset: int, size: int) -> bytes:
    data = rom[offset : offset + size]
    if len(data) != size:
        raise ValueError(f"short source read at {offset:#x} for {size:#x} bytes")
    return data


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    actual_hash = sha256(rom)
    if actual_hash != EXPECTED_ROM_SHA256:
        raise SystemExit(f"target ROM SHA-256 mismatch: {actual_hash}")

    spans = {
        "match_00_home_roster.bin": {
            "file_offset": 0x004A57,
            "size_bytes": 12,
            "meaning": "match-00 home roster slots 0-10 plus terminator",
        },
        "stamina_profile_values_AE86_AFAE.bin": {
            "file_offset": bank1c(0xAE86),
            "size_bytes": 0x128,
            "cpu_start": "0xAE86",
            "cpu_end_exclusive": "0xAFAE",
            "prg_bank": "0x1C",
            "meaning": "37 records of eight stamina/special skill curve selectors",
        },
        "stamina_value_words_9F0E_9FCD.bin": {
            "file_offset": bank1c(0x9F0E),
            "size_bytes": 0xC0,
            "cpu_start": "0x9F0E",
            "cpu_end_exclusive": "0x9FCE",
            "prg_bank": "0x1C",
            "meaning": "96 little-endian 16-bit maximum-stamina values",
        },
    }

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    resource_rows: dict[str, dict[str, object]] = {}
    for name, span in spans.items():
        content = read(rom, int(span["file_offset"]), int(span["size_bytes"]))
        (OUT_DIR / name).write_bytes(content)
        resource_rows[name] = {
            **span,
            "sha256": sha256(content),
        }

    code_windows = [
        ("fixed", 0xDB62, 0xDB9E, fixed),
        ("fixed", 0xE0DF, 0xE349, fixed),
        ("fixed", 0xCE08, 0xCE2A, fixed),
        ("bank_1C", 0x802D, 0x813D, bank1c),
        ("bank_01", 0xA611, 0xA636, bank1),
    ]
    code_rows = []
    for bank_name, start, end, offset_fn in code_windows:
        code = read(rom, offset_fn(start), end - start)
        code_rows.append(
            {
                "prg_bank": bank_name,
                "cpu_start": f"0x{start:04X}",
                "cpu_end_exclusive": f"0x{end:04X}",
                "file_offset": f"0x{offset_fn(start):06X}",
                "size_bytes": len(code),
                "sha256": sha256(code),
            }
        )

    manifest = {
        "schema": "ct2-first-match-player-state-rom-resources-v1",
        "source_rom": {
            "name": ROM_PATH.name,
            "sha256": actual_hash,
        },
        "extractor": "tools/gameplay/extract_first_match_player_state_resources.py",
        "resources": resource_rows,
        "verified_code_windows": code_rows,
        "assumptions": [
            "The player profile selector at $95D6 is preserved in the existing first-action-menu table resource; the stamina evaluator uses its first byte to index the $AE86 table for skill selector X=0.",
            "The fresh-start level byte is zero because the cold reset clears volatile RAM; the pre-match $A611 path leaves it unchanged when experience resolves to level zero.",
            "The provider models the ROM run timer only when a caller reports reaching the $E14D check after the $E349 input handler; B can leave the loop before that check.",
            "The $E2BC stamina updater increments reset-zero byte $0618; only its wrap to zero skips teammate regeneration, and holder charging still runs.",
        ],
    }
    (OUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Extracted {len(resource_rows)} ROM-derived player-state spans.")
    for name, row in resource_rows.items():
        print(f"{name}: {row['size_bytes']} bytes sha256={row['sha256']}")
    print(f"Manifest: {OUT_DIR.relative_to(ROOT) / 'manifest.json'}")


if __name__ == "__main__":
    main()

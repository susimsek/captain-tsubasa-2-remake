#!/usr/bin/env python3
"""Extract and verify ROM spans for kickoff actor animation index $02."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT = ROOT / "reference/rom_extract/gameplay/animations/kickoff/slot11_animation_index_02"
MANIFEST_PATH = OUT / "manifest.json"

ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
MAPPER = 4
PRG_BANK_8K = 0x1B
PRG_BANK_FILE_BASE = 0x036010

# (filename, CPU start, CPU end inclusive, description)
SPANS = (
    (
        "bank1b_actor_animation_stream_02_A2E8_A2FC.bin",
        0xA2E8,
        0xA2FC,
        "ROM actor-animation index $02 stream at the traced $A21A continuation.",
    ),
    (
        "bank1b_actor_animation_packet_pointer_table_A42A_A439.bin",
        0xA42A,
        0xA439,
        "Eight little-endian packet pointers used by the $A21A animation command parser; extends the previously extracted five-entry prefix.",
    ),
    (
        "bank1b_actor_animation_packets_05_A4C3_A4E7.bin",
        0xA4C3,
        0xA4E7,
        "Packet row 5, bounded by the next pointer at $A4E8.",
    ),
    (
        "bank1b_actor_animation_packets_06_A4E8_A4EC.bin",
        0xA4E8,
        0xA4EC,
        "Packet row 6, bounded by the next pointer at $A4ED.",
    ),
    (
        "bank1b_actor_animation_packets_07_A4ED_A4F1.bin",
        0xA4ED,
        0xA4F1,
        "Packet row 7, including its zero terminator.",
    ),
)

EXPECTED_STREAM = bytes.fromhex(
    "04 05 04 06 04 07 04 06 04 07 04 06 04 07 04 06 04 05 FF E8 A2"
)
EXPECTED_POINTERS = bytes.fromhex(
    "6A A4 8F A4 94 A4 99 A4 9E A4 C3 A4 E8 A4 ED A4"
)
EXPECTED_PACKETS = (
    bytes.fromhex(
        "04 C8 22 00 B4 E4 E5 04 E8 22 00 B6 E6 E7 04 08 23 00 BC BD E8 "
        "04 28 23 00 BE BF EA 01 EA 23 50 01 F2 23 05 00"
    ),
    bytes.fromhex("01 EA 22 D9 00"),
    bytes.fromhex("01 EA 22 F2 00"),
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def cpu_to_file_offset(address: int) -> int:
    if not 0xA000 <= address <= 0xBFFF:
        raise ValueError(f"CPU address outside the mapped $A000-$BFFF bank window: ${address:04X}")
    return PRG_BANK_FILE_BASE + (address - 0xA000)


def validate_rom(rom: bytes) -> None:
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("Target ROM SHA-256 mismatch.")
    if len(rom) < 16 or rom[:4] != b"NES\x1a":
        raise SystemExit("Target is not an iNES ROM.")
    mapper = (rom[6] >> 4) | (rom[7] & 0xF0)
    prg_size = rom[4] * 0x4000
    has_trainer = bool(rom[6] & 0x04)
    is_nes_2 = (rom[7] & 0x0C) == 0x08
    if mapper != MAPPER or prg_size != 0x40000 or has_trainer or is_nes_2:
        raise SystemExit(f"Unexpected ROM layout: mapper={mapper}, PRG size=0x{prg_size:X}.")


def build_manifest(rom: bytes) -> dict[str, object]:
    entries: list[dict[str, object]] = []
    payloads: list[bytes] = []
    for filename, start, end, description in SPANS:
        offset = cpu_to_file_offset(start)
        length = end - start + 1
        data = rom[offset : offset + length]
        if len(data) != length:
            raise SystemExit(f"Truncated ROM span: {filename}")
        payloads.append(data)
        entries.append(
            {
                "file": filename,
                "bank": f"bank{PRG_BANK_8K:02x}",
                "cpu_start": f"0x{start:04X}",
                "cpu_end_inclusive": f"0x{end:04X}",
                "file_offset": f"0x{offset:06X}",
                "length": length,
                "sha256": sha256(data),
                "bytes_hex": data.hex(" ").upper(),
                "description": description,
            }
        )

    if payloads[0] != EXPECTED_STREAM:
        raise SystemExit("Animation-index $02 stream differs from the audited ROM bytes.")
    if payloads[1] != EXPECTED_POINTERS:
        raise SystemExit("Animation packet pointer table differs from the audited ROM bytes.")
    if tuple(payloads[2:]) != EXPECTED_PACKETS:
        raise SystemExit("Animation packet rows 5-7 differ from the audited ROM bytes.")

    pointers = [int.from_bytes(payloads[1][i : i + 2], "little") for i in range(0, 16, 2)]
    if pointers[5:] != [0xA4C3, 0xA4E8, 0xA4ED]:
        raise SystemExit("Pointer-table rows 5-7 do not target the extracted packet spans.")

    return {
        "schema_version": 1,
        "purpose": "ROM-derived source package for the traced slot-$11 animation-index-$02 continuation through the $A21A animation parser.",
        "rom_file": ROM_PATH.name,
        "rom_sha256": ROM_SHA256,
        "trace_state_included": False,
        "rom_layout": {
            "format": "iNES",
            "mapper": MAPPER,
            "prg_size_bytes": 0x40000,
            "cpu_window": "0xA000-0xBFFF",
            "prg_8k_bank": f"0x{PRG_BANK_8K:02X}",
            "cpu_to_file_mapping": "0x036010 + (CPU address - 0xA000); iNES header is 16 bytes.",
        },
        "spans": entries,
        "pointer_rows_5_to_7": [f"0x{pointer:04X}" for pointer in pointers[5:]],
        "runtime_rom_dependency": False,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify the existing extracted binaries and manifest without writing files.",
    )
    args = parser.parse_args()

    rom = ROM_PATH.read_bytes()
    validate_rom(rom)
    manifest = build_manifest(rom)

    if args.check:
        if not MANIFEST_PATH.is_file():
            raise SystemExit(f"Missing manifest: {MANIFEST_PATH}")
        existing = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        if existing != manifest:
            raise SystemExit("Extracted manifest differs from the current ROM-derived manifest.")
        for span in manifest["spans"]:
            path = OUT / str(span["file"])
            data = path.read_bytes()
            if sha256(data) != span["sha256"] or data.hex(" ").upper() != span["bytes_hex"]:
                raise SystemExit(f"Extracted binary does not match its manifest: {path}")
        print(f"Verified ROM SHA-256 and {len(SPANS)} extracted spans: {OUT.relative_to(ROOT)}")
        return

    OUT.mkdir(parents=True, exist_ok=True)
    for span in manifest["spans"]:
        (OUT / str(span["file"])).write_bytes(bytes.fromhex(str(span["bytes_hex"])))
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Extracted {len(SPANS)} ROM spans to {OUT.relative_to(ROOT)}")
    for span in manifest["spans"]:
        print(f"{span['file']}  {span['sha256']}")


if __name__ == "__main__":
    main()

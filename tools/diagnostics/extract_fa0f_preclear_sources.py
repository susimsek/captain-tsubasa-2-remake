#!/usr/bin/env python3
"""Preserve the checked ROM source spans for scene-$56 FA-$0F preclear."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
REFERENCE_DIR = ROOT / "reference/rom_extract/gameplay/meeting_menu"
RUNTIME_DIR = ROOT / "assets/gameplay/rom_logic"

# CPU address window and bank are explicit for every span; the ROM uses an
# MMC3-style 8 KiB bank mapping, so CPU addresses alone are not file offsets.
SPANS = [
    {
        "name": "fa_loader_selector",
        "bank": 0x00,
        "window_start": 0x8000,
        "cpu_start": 0x8AF7,
        "cpu_end_exclusive": 0x8BB3,
        "expected_hex": "85eda9008509850a850d850ea55b297f855ba5258577a20720b9c4a900a0f8995205c8d0faa5ed0aaaa9002aa88a18690085639869a08564a000b163aac8b16385648663a000b1638575c8b1638576c8b163aa293f85488a465b2a265bc8b163855ec8b163855fc8b16329f8855ca902855d065c265d065c265db1632907055c855c065c265d065c265da55d290cd00ca57b0a0a455b2904055d855da55ec90990062071904cab8ba55d2904d0062071904cae8b207690a90120a89f",
        "description": "Shared F9/FA loader selector; includes the branch to $9071/$9076 and the distinct post-helper $9FA8(A=$01) at $8BAE.",
    },
    {
        "name": "clear_helper_entrypoints",
        "bank": 0x00,
        "window_start": 0x8000,
        "cpu_start": 0x9071,
        "cpu_end_exclusive": 0x9085,
        "expected_hex": "a9204c7890a92485e7a90085e6a010a2204ce898",
        "description": "$9071 selects $2000; $9076 selects $2400; both configure 16 rows x 32 bytes and jump to $98E8.",
    },
    {
        "name": "clear_row_producer",
        "bank": 0x00,
        "window_start": 0x8000,
        "cpu_start": 0x98E8,
        "cpu_end_exclusive": 0x992C,
        "expected_hex": "a90085eba54a054bf03a84e886e9a5e9a4e6a6e720289ba4e9a5eb9de805e888d0f9205e9ba5e81005a90120a89fa5e618692085e6a5e7690085e7c6e8a5e8297fd0cb60",
        "description": "$98E8 selects buffered rows when $4A|$4B is nonzero, reserves each row via $9B28, appends 32 zero bytes, finalizes, and increments destination by $20.",
    },
    {
        "name": "queue_capacity_writer",
        "bank": 0x00,
        "window_start": 0x8000,
        "cpu_start": 0x9B28,
        "cpu_end_exclusive": 0x9B6F,
        "expected_hex": "482c29065009a90120a89f684c289b293f186d2806c93db0ed6809408d29068aae28069dea05989de905ad290629bf9de805e8e8e860a9009de8058e2806ad290629bf8d290660",
        "description": "$9B28 tests queue cursor $0628 plus payload size against $3D, yields through $9FA8(A=$01), then writes a 3-byte header and payload; $9B5E finalizes the queue cursor.",
    },
    {
        "name": "scene_56_fa_0f_event",
        "bank": 0x05,
        "window_start": 0xA000,
        "cpu_start": 0xBFBC,
        "cpu_end_exclusive": 0xBFBE,
        "expected_hex": "fa0f",
        "description": "Scene-$56 background event operand; event stream begins at $BFBA with F1 $02 followed by FA $0F.",
    },
    {
        "name": "background_0f_descriptor",
        "bank": 0x07,
        "window_start": 0xA000,
        "cpu_start": 0xA294,
        "cpu_end_exclusive": 0xA2A4,
        "expected_hex": "64669a020412575859525a5b5c5600a0",
        "description": "The bank-$07 descriptor selected by FA $0F; included as a source identity check, not used to invent a preclear destination.",
    },
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def extract(rom: bytes) -> tuple[bytes, list[dict[str, object]]]:
    if sha256(rom) != ROM_SHA256:
        raise ValueError("Supplied ROM hash does not match the checked Turkish revision")
    result = bytearray()
    entries: list[dict[str, object]] = []
    for span in SPANS:
        bank = int(span["bank"])
        window_start = int(span["window_start"])
        cpu_start = int(span["cpu_start"])
        cpu_end = int(span["cpu_end_exclusive"])
        if not window_start <= cpu_start < cpu_end <= window_start + 0x2000:
            raise ValueError(f"Invalid CPU window for {span['name']}")
        file_start = 0x10 + bank * 0x2000 + cpu_start - window_start
        raw = rom[file_start:file_start + cpu_end - cpu_start]
        if raw.hex() != str(span["expected_hex"]):
            raise ValueError(
                f"ROM bytes differ for {span['name']} at file 0x{file_start:06X}: "
                f"{raw.hex()}"
            )
        entries.append({
            "name": span["name"],
            "prg_bank": bank,
            "bank_cpu_window": f"${window_start:04X}-${window_start + 0x1FFF:04X}",
            "cpu_start": f"${cpu_start:04X}",
            "cpu_end_exclusive": f"${cpu_end:04X}",
            "file_start": f"0x{file_start:06X}",
            "file_end_exclusive": f"0x{file_start + len(raw):06X}",
            "combined_offset": len(result),
            "byte_length": len(raw),
            "sha256": sha256(raw),
            "bytes_hex": raw.hex(),
            "description": span["description"],
        })
        result.extend(raw)
    return bytes(result), entries


def write_outputs(rom_path: Path, blob: bytes, spans: list[dict[str, object]]) -> None:
    REFERENCE_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    reference_bin = REFERENCE_DIR / "fa_0f_preclear_sources.bin"
    runtime_bin = RUNTIME_DIR / "fa_0f_preclear_sources.bin"
    reference_bin.write_bytes(blob)
    runtime_bin.write_bytes(blob)
    manifest = {
        "schema": "ct2-scene-56-fa-0f-preclear-source-v1",
        "rom": {"file": rom_path.name, "sha256": ROM_SHA256},
        "source_spans": spans,
        "decoded_rules": {
            "buffered_branch": "$98E8 uses the buffered queue when ($4A | $4B) != 0; direct PPU writes are outside this task.",
            "helper_entrypoints": {
                "$9071": {"destination": "$2000", "rows": 16, "bytes_per_row": 32},
                "$9076": {"destination": "$2400", "rows": 16, "bytes_per_row": 32},
            },
            "queue_capacity": "Before each row, $9B28 yields when $0628 + payload_size >= $3D; payload_size is 32. The byte comparison excludes the 3-byte queue header.",
            "queue_serialization": "A successful row uses 3 queue header bytes plus 32 zero payload bytes; $9B5E records the cursor. A source-valid end cursor can therefore be as high as $3F.",
            "yield": "$9B2E loads $01 and $9B30 calls $9FA8; $9B32 is the saved return word and $9B33 the resumed PC.",
            "queue_release_consumer_pc": "$A03C (counted $05E8 queue writer loop); receipt PC must match exactly.",
            "post_helper_wait": "$8BAE's separate LDA #$01 / JSR $9FA8 is outside this row task.",
        },
        "resource": {
            "path": "assets/gameplay/rom_logic/fa_0f_preclear_sources.bin",
            "reference_path": "reference/rom_extract/gameplay/meeting_menu/fa_0f_preclear_sources.bin",
            "byte_length": len(blob),
            "sha256": sha256(blob),
            "byte_identity": "Concatenated unchanged ROM source spans in manifest order.",
        },
        "runtime_policy": {
            "runtime_uses_original_rom": False,
            "runtime_uses_emulator_capture": False,
            "trace_role": "Retained RAM frames validate route-level wait-state observations only; they do not seed runtime cursor, destination, or frame delays.",
        },
    }
    text = json.dumps(manifest, indent=2) + "\n"
    (REFERENCE_DIR / "fa_0f_preclear_sources.json").write_text(text, encoding="utf-8")
    (RUNTIME_DIR / "fa_0f_preclear_sources.json").write_text(text, encoding="utf-8")


def main() -> int:
    rom_path = ROM_PATH.resolve()
    blob, spans = extract(rom_path.read_bytes())
    write_outputs(rom_path, blob, spans)
    print(f"Extracted {len(spans)} checked ROM spans ({len(blob)} bytes) for FA $0F preclear.")
    print(f"SHA-256: {sha256(blob)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

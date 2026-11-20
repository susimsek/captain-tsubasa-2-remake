#!/usr/bin/env python3
"""Extract the ROM pointer and bounded actor stream selected by parameter $00."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK18_FILE_BASE = 0x030010
TABLE_CPU = 0x9220
EXPECTED_POINTER = 0x9400
EXPECTED_NEXT_POINTER = 0x9402
EXPECTED_STREAM = bytes.fromhex("F2 F0")

TASK_CONTEXT = ROOT / "reference/rom_extract/gameplay/task_context"
TASK_CONTEXT_MANIFEST = TASK_CONTEXT / "manifest.json"
RESUME = ROOT / "reference/rom_extract/gameplay/slot11_actor_worker_resume_wait"
RESUME_MANIFEST = RESUME / "manifest.json"

POINTER_NAME = "bank18_actor_parameter_00_pointer_9220.bin"
BOUNDARY_NAME = "bank18_actor_parameter_01_boundary_pointer_9222.bin"
STREAM_NAME = "bank18_actor_stream_parameter00_9400_9401.bin"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def source_span(directory: Path, filename: str, data: bytes) -> None:
    path = directory / filename
    if path.exists() and path.read_bytes() != data:
        raise SystemExit(f"Preserved source differs from the supplied ROM: {path}")
    path.write_bytes(data)


def add_span(manifest: dict[str, object], entry: dict[str, object]) -> None:
    spans = manifest.get("spans")
    if not isinstance(spans, list):
        raise SystemExit("Source manifest has no span list.")
    filename = str(entry["file"])
    for old in spans:
        if isinstance(old, dict) and old.get("file") == filename:
            if old != entry:
                raise SystemExit(f"Existing manifest span differs: {filename}")
            return
    spans.append(entry)


def load_manifest(path: Path) -> dict[str, object]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict) or value.get("rom_sha256") != ROM_SHA256:
        raise SystemExit(f"Source manifest is malformed or targets another ROM: {path}")
    return value


def check() -> tuple[bytes, bytes, bytes]:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256 or len(rom) != 393232:
        raise SystemExit("The supplied ROM identity or size does not match the pinned revision.")

    table_offset = BANK18_FILE_BASE + TABLE_CPU - 0x8000
    pointer_bytes = rom[table_offset : table_offset + 2]
    boundary_bytes = rom[table_offset + 2 : table_offset + 4]
    pointer = int.from_bytes(pointer_bytes, "little")
    next_pointer = int.from_bytes(boundary_bytes, "little")
    if pointer != EXPECTED_POINTER or next_pointer != EXPECTED_NEXT_POINTER:
        raise SystemExit("The actor-$00 pointer or adjacent end pointer changed.")
    stream_offset = BANK18_FILE_BASE + pointer - 0x8000
    stream = rom[stream_offset : stream_offset + next_pointer - pointer]
    if stream != EXPECTED_STREAM:
        raise SystemExit("The actor-$00 stream bytes differ from the reviewed source sequence.")
    return pointer_bytes, boundary_bytes, stream


def expected_entry(filename: str, cpu_address: int, file_offset: int,
                   data: bytes, description: str) -> dict[str, object]:
    return {
        "file": filename,
        "cpu_address": f"0x{cpu_address:04X}",
        "file_offset": f"0x{file_offset:06X}",
        "length": len(data),
        "sha256": sha256(data),
        "description": description,
        "bytes": data.hex(" "),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="verify extracted spans and manifests without writing")
    args = parser.parse_args()
    pointer_bytes, boundary_bytes, stream = check()
    table_offset = BANK18_FILE_BASE + TABLE_CPU - 0x8000
    pointer = int.from_bytes(pointer_bytes, "little")
    stream_offset = BANK18_FILE_BASE + pointer - 0x8000
    specs = [
        (TASK_CONTEXT, TASK_CONTEXT_MANIFEST, expected_entry(
            POINTER_NAME, TABLE_CPU, table_offset, pointer_bytes,
            "Bank-$18 actor parameter `$00` pointer-table entry at `$9220`; resolves to actor stream `$9400`.")),
        (RESUME, RESUME_MANIFEST, expected_entry(
            BOUNDARY_NAME, TABLE_CPU + 2, table_offset + 2, boundary_bytes,
            "Adjacent bank-$18 parameter `$01` pointer; bounds the parameter-$00 stream at `$9402`.")),
        (RESUME, RESUME_MANIFEST, expected_entry(
            STREAM_NAME, pointer, stream_offset, stream,
            "Bank-$18 actor stream selected by parameter `$00`, bounded by the next pointer at `$9222`; bytes `$F2 $F0`.")),
    ]
    if args.check:
        for directory, manifest_path, entry in specs:
            manifest = load_manifest(manifest_path)
            spans = manifest.get("spans", [])
            actual = next((span for span in spans if isinstance(span, dict)
                           and span.get("file") == entry["file"]), None)
            if actual != entry or (directory / str(entry["file"])).read_bytes() != check_span_bytes(entry):
                raise SystemExit(f"Manifest or extracted bytes differ: {entry['file']}")
    else:
        for directory, _, entry in specs:
            data = {POINTER_NAME: pointer_bytes, BOUNDARY_NAME: boundary_bytes,
                    STREAM_NAME: stream}[str(entry["file"])]
            source_span(directory, str(entry["file"]), data)
        for _, manifest_path, entry in specs:
            manifest = load_manifest(manifest_path)
            add_span(manifest, entry)
            manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
                                     encoding="utf-8")
    print(f"PASS: parameter $00 pointer ${pointer:04X}, boundary ${EXPECTED_NEXT_POINTER:04X}, and {len(stream)} stream bytes are ROM-verified.")
    print(f"pointer sha256={sha256(pointer_bytes)} boundary sha256={sha256(boundary_bytes)} stream sha256={sha256(stream)}")


def check_span_bytes(entry: dict[str, object]) -> bytes:
    name = str(entry["file"])
    if name == POINTER_NAME:
        return bytes.fromhex("00 94")
    if name == BOUNDARY_NAME:
        return bytes.fromhex("02 94")
    return EXPECTED_STREAM


if __name__ == "__main__":
    main()

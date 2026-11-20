#!/usr/bin/env python3
"""Extract the ROM pointer and bounded actor stream selected by parameter $58."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
ROM_SIZE = 393232
BANK18_FILE_BASE = 0x030010
TABLE_BASE = 0x9220
PARAMETER = 0x58
EXPECTED_POINTER = 0x9A62
EXPECTED_NEXT_POINTER = 0x9A70
EXPECTED_STREAM = bytes.fromhex("01 10 E4 FC 08 61 6C 69 79 6F 72 21 FC F0")

TASK_CONTEXT = ROOT / "reference/rom_extract/gameplay/task_context"
TASK_CONTEXT_MANIFEST = TASK_CONTEXT / "manifest.json"
RESUME = ROOT / "reference/rom_extract/gameplay/slot11_actor_worker_resume_wait"
RESUME_MANIFEST = RESUME / "manifest.json"

POINTER_NAME = "bank18_actor_parameter_58_pointer_92D0.bin"
BOUNDARY_NAME = "bank18_actor_parameter_59_boundary_pointer_92D2.bin"
STREAM_NAME = "bank18_actor_stream_parameter58_9A62_9A6F.bin"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_manifest(path: Path) -> dict[str, object]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict) or value.get("rom_sha256") != ROM_SHA256:
        raise SystemExit(f"Source manifest is malformed or targets another ROM: {path}")
    return value


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


def expected_entry(
    filename: str,
    cpu_address: int,
    file_offset: int,
    data: bytes,
    description: str,
) -> dict[str, object]:
    return {
        "file": filename,
        "cpu_address": f"0x{cpu_address:04X}",
        "file_offset": f"0x{file_offset:06X}",
        "length": len(data),
        "sha256": sha256(data),
        "description": description,
        "bytes": data.hex(" "),
    }


def extract() -> tuple[bytes, bytes, bytes, int, int]:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256 or len(rom) != ROM_SIZE:
        raise SystemExit("The supplied ROM identity or size does not match the pinned revision.")

    table_cpu = TABLE_BASE + 2 * PARAMETER
    table_offset = BANK18_FILE_BASE + table_cpu - 0x8000
    pointer_bytes = rom[table_offset : table_offset + 2]
    boundary_bytes = rom[table_offset + 2 : table_offset + 4]
    pointer = int.from_bytes(pointer_bytes, "little")
    next_pointer = int.from_bytes(boundary_bytes, "little")
    if table_cpu != 0x92D0 or pointer != EXPECTED_POINTER \
            or next_pointer != EXPECTED_NEXT_POINTER:
        raise SystemExit("The actor-$58 pointer or adjacent end pointer changed.")

    stream_offset = BANK18_FILE_BASE + pointer - 0x8000
    stream = rom[stream_offset : stream_offset + next_pointer - pointer]
    if stream != EXPECTED_STREAM:
        raise SystemExit("The actor-$58 stream bytes differ from the reviewed ROM sequence.")
    return pointer_bytes, boundary_bytes, stream, table_offset, stream_offset


def check_existing(
    directory: Path,
    manifest_path: Path,
    expected: dict[str, object],
) -> None:
    manifest = load_manifest(manifest_path)
    spans = manifest.get("spans", [])
    actual = next((span for span in spans if isinstance(span, dict)
                  and span.get("file") == expected["file"]), None)
    if actual != expected:
        raise SystemExit(f"Manifest span differs: {expected['file']}")
    data = (directory / str(expected["file"])).read_bytes()
    if data.hex(" ") != expected["bytes"] or sha256(data) != expected["sha256"]:
        raise SystemExit(f"Extracted bytes differ: {expected['file']}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check", action="store_true",
        help="verify extracted spans and manifests without writing",
    )
    args = parser.parse_args()
    pointer_bytes, boundary_bytes, stream, table_offset, stream_offset = extract()
    table_cpu = TABLE_BASE + 2 * PARAMETER
    pointer_entry = expected_entry(
        POINTER_NAME, table_cpu, table_offset, pointer_bytes,
        "Bank-$18 actor parameter `$58` pointer-table entry; `$800F` computes `$9220 + 2*$58` and resolves it to stream `$9A62`.",
    )
    boundary_entry = expected_entry(
        BOUNDARY_NAME, table_cpu + 2, table_offset + 2, boundary_bytes,
        "Adjacent bank-$18 parameter `$59` pointer; bounds the parameter-$58 stream at `$9A70`.",
    )
    stream_entry = expected_entry(
        STREAM_NAME, EXPECTED_POINTER, stream_offset, stream,
        "Bank-$18 actor stream selected by parameter `$58`, bounded by the adjacent pointer at `$92D2`; bytes `$01 $10 $E4 $FC $08`, then `$61 $6C $69 $79 $6F $72 $21`, then `$FC $F0`.",
    )

    # The selected pointer artifact was added to task_context separately because
    # the slot-$11 prefix executor loads its parameter table entries from there.
    check_existing(TASK_CONTEXT, TASK_CONTEXT_MANIFEST, pointer_entry)

    if args.check:
        check_existing(RESUME, RESUME_MANIFEST, boundary_entry)
        check_existing(RESUME, RESUME_MANIFEST, stream_entry)
    else:
        RESUME.mkdir(parents=True, exist_ok=True)
        for filename, data in [(BOUNDARY_NAME, boundary_bytes), (STREAM_NAME, stream)]:
            path = RESUME / filename
            if path.exists() and path.read_bytes() != data:
                raise SystemExit(f"Preserved source differs from the supplied ROM: {path}")
            path.write_bytes(data)
        manifest = load_manifest(RESUME_MANIFEST)
        add_span(manifest, boundary_entry)
        add_span(manifest, stream_entry)
        RESUME_MANIFEST.write_text(
            json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    print(f"PASS: parameter $58 pointer ${EXPECTED_POINTER:04X}; stream length {len(stream)}.")
    print(f"pointer sha256={sha256(pointer_bytes)}")
    print(f"boundary sha256={sha256(boundary_bytes)}")
    print(f"stream sha256={sha256(stream)}")


if __name__ == "__main__":
    main()

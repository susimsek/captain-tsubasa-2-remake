#!/usr/bin/env python3
"""Export the ROM-owned PASS receiver descriptor $1D and token source spans.

The extractor reads only the pinned supplied ROM. It emits raw byte spans for
the renderer presenter; no FCEUX state, screenshot, or captured audio is read.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT = ROOT / "reference/rom_extract/gameplay/menus/pass_receiver_down_menu"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
ROM_SIZE = 393232
BANK18_FILE_BASE = 0x030010
DESCRIPTOR_TABLE = 0xB3CF
DESCRIPTOR_ID = 0x1D
ROW_END = 0xFC


def bank18_offset(cpu: int) -> int:
    if not 0x8000 <= cpu < 0xC000:
        raise ValueError(f"${cpu:04X} is outside the bank-$18 window")
    return BANK18_FILE_BASE + cpu - 0x8000


def span(rom: bytes, name: str, resource: str, cpu: int, length: int) -> tuple[bytes, dict]:
    offset = bank18_offset(cpu)
    raw = rom[offset:offset + length]
    if len(raw) != length:
        raise ValueError(f"Truncated source span {name}")
    OUT.joinpath(resource).write_bytes(raw)
    return raw, {
        "name": name,
        "resource": resource,
        "cpu_address": f"0x{cpu:04X}",
        "file_offset": f"0x{offset:06X}",
        "length_bytes": length,
        "sha256": hashlib.sha256(raw).hexdigest(),
    }


def main() -> None:
    rom = ROM_PATH.read_bytes()
    digest = hashlib.sha256(rom).hexdigest()
    if len(rom) != ROM_SIZE or digest != ROM_SHA256 or rom[:4] != b"NES\x1a":
        raise SystemExit("The supplied iNES ROM does not match the pinned revision.")
    OUT.mkdir(parents=True, exist_ok=True)

    entry_cpu = DESCRIPTOR_TABLE + DESCRIPTOR_ID * 2
    pointer_bytes = rom[bank18_offset(entry_cpu):bank18_offset(entry_cpu) + 2]
    descriptor_cpu = int.from_bytes(pointer_bytes, "little")
    next_cpu = int.from_bytes(rom[bank18_offset(entry_cpu + 2):bank18_offset(entry_cpu + 2) + 2], "little")
    if descriptor_cpu != 0xB6C7 or next_cpu != 0xB6E4:
        raise SystemExit("Descriptor $1D pointer/next-pointer differs from the pinned ROM.")

    descriptor_head = rom[bank18_offset(descriptor_cpu):bank18_offset(descriptor_cpu) + 9]
    row_count = descriptor_head[8]
    descriptor_size = 9 + row_count * 4
    if descriptor_size != 29 or descriptor_cpu + descriptor_size != next_cpu:
        raise SystemExit("Descriptor $1D bounds do not match the following pointer.")
    descriptor = rom[bank18_offset(descriptor_cpu):bank18_offset(descriptor_cpu) + descriptor_size]
    if descriptor != bytes.fromhex(
        "32 22 0c 0a 00 01 0c 09 05 01 02 f9 bc 03 01 fb bc "
        "05 01 06 bd 07 01 11 bd 09 01 1c bd"
    ):
        raise SystemExit("Descriptor $1D bytes differ from the decoded shape.")

    OUT.joinpath("descriptor_pointer_entry_1D.bin").write_bytes(pointer_bytes)
    OUT.joinpath("descriptor_1D.bin").write_bytes(descriptor)
    spans = [{
        "name": "descriptor_pointer_entry_1D",
        "resource": "descriptor_pointer_entry_1D.bin",
        "cpu_address": f"0x{entry_cpu:04X}",
        "file_offset": f"0x{bank18_offset(entry_cpu):06X}",
        "length_bytes": 2,
        "sha256": hashlib.sha256(pointer_bytes).hexdigest(),
    }, {
        "name": "descriptor_1D",
        "resource": "descriptor_1D.bin",
        "cpu_address": f"0x{descriptor_cpu:04X}",
        "file_offset": f"0x{bank18_offset(descriptor_cpu):06X}",
        "length_bytes": descriptor_size,
        "sha256": hashlib.sha256(descriptor).hexdigest(),
    }]

    rows = []
    for index in range(row_count):
        off = 9 + index * 4
        coord, column = descriptor[off], descriptor[off + 1]
        text_cpu = int.from_bytes(descriptor[off + 2:off + 4], "little")
        text_off = bank18_offset(text_cpu)
        end = rom.find(bytes([ROW_END]), text_off, text_off + 0x100)
        if end < 0:
            raise ValueError(f"Row {index} at ${text_cpu:04X} has no $FC terminator")
        text = rom[text_off:end + 1]
        resource = f"row_{index:02d}.bin"
        OUT.joinpath(resource).write_bytes(text)
        spans.append({
            "name": f"row_{index:02d}",
            "resource": resource,
            "cpu_address": f"0x{text_cpu:04X}",
            "file_offset": f"0x{text_off:06X}",
            "length_bytes": len(text),
            "sha256": hashlib.sha256(text).hexdigest(),
        })
        rows.append({
            "index": index,
            "coordinate": coord,
            "column": column,
            "text_cpu_address": f"0x{text_cpu:04X}",
            "bytes_hex": text.hex(" "),
        })

    # Parser dispatch, E2/E3 vectors and handlers, plus the descriptor-style
    # source code/data are retained so runtime can pin the actual token mapping.
    code_spans = [
        ("token_dispatch_prefix", "token_dispatch_prefix_89B4.bin", 0x89B4, 6),
        ("token_vector_E0_E3", "token_vector_E0_E3_89BA.bin", 0x89BA, 8),
        ("token_handlers_E0_E3", "token_handlers_E0_E3_89FA.bin", 0x89FA, 24),
        ("descriptor_style_selector", "descriptor_style_selector_885E.bin", 0x885E, 24),
        ("descriptor_style_table_entry", "descriptor_style_table_entry_B3C4.bin", 0xB3C4, 1),
    ]
    for name, resource, cpu, length in code_spans:
        raw, row = span(rom, name, resource, cpu, length)
        spans.append(row)

    if [row["coordinate"] for row in rows] != [1, 3, 5, 7, 9] \
            or [row["column"] for row in rows] != [2, 1, 1, 1, 1] \
            or [row["bytes_hex"] for row in rows] != [
                "e2 fc", "45 6e 72 6a 00 00 00 00 e3 00 fc",
                "53 75 74 20 00 00 00 00 e3 01 fc",
                "43 61 6c 69 6d 20 20 00 e3 03 fc",
                "50 61 73 20 00 00 00 00 e3 02 fc",
            ]:
        raise SystemExit("Descriptor $1D row coordinates/streams differ from expected ROM parsing.")

    manifest = {
        "schema": "ct2-pass-receiver-descriptor-1d-source-v1",
        "source_rom_sha256": digest,
        "source_rom_size_bytes": len(rom),
        "bank_mapping": {
            "bank18_cpu_window": "0x8000-0xBFFF",
            "file_offset_formula": "0x030010 + (CPU - 0x8000)",
        },
        "descriptor": {
            "id": "0x1D",
            "pointer_table_cpu": f"0x{DESCRIPTOR_TABLE:04X}",
            "pointer_entry_cpu": f"0x{entry_cpu:04X}",
            "descriptor_cpu": f"0x{descriptor_cpu:04X}",
            "descriptor_length_bytes": descriptor_size,
            "next_descriptor_cpu": f"0x{next_cpu:04X}",
            "base_ppu_address": "0x2232",
            "packet_width_tiles": 12,
            "inclusive_final_progress": 10,
            "top_border_progress": 1,
            "bottom_border_offset": 9,
            "row_count": row_count,
            "rows": rows,
        },
        "dynamic_tokens": {
            "parser": "$8986 sends token values >= $E0 through the vector dispatch at $89BA",
            "E2": {"handler_cpu": "0x8A06", "operation": "LDA $05FC; JMP $8CDC", "semantic_alias": "$E0 player position/name resolver"},
            "E3": {"handler_cpu": "0x8A0C", "operation": "LDA $05FC; JMP $8CA5", "semantic_alias": "$E1 selector/value resolver"},
            "selected_slot_ram": "0x05FC",
        },
        "style": {
            "selector_code_cpu": "0x885E",
            "style_table_cpu": "0xB3BD",
            "table_entry_cpu": "0xB3C4",
            "descriptor_index": 7,
            "packed_selector": 1,
            "raw_style_byte": "0x02",
            "selected_frame_family": 0,
            "shared_frame_resource": "../first_action_menu/window_3x3_tile_ids.bin",
        },
        "spans": spans,
        "evidence_limits": [
            "This export preserves ROM bytes and the token/style dispatch inputs; it does not execute the 6502 $EF7F/$800C renderer wrapper.",
            "The presenter builds the first two ROM-defined queue packet candidates only; it does not run the asynchronous $C515 worker, scheduler, NMI, or PPU transfer.",
            "FCEUX captures are validation evidence only and are not read by this extractor or the runtime presenter.",
        ],
    }
    OUT.joinpath("manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Exported descriptor $1D and {len(rows)} ROM text rows to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

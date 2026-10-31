#!/usr/bin/env python3
"""Extract the ROM-owned field-entry descriptor $00 and its text rows.

The extractor reads only the supplied ROM and verifies the shared renderer
code windows before writing byte-preserved resources and their manifest.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUTPUT_DIR = ROOT / "reference/rom_extract/gameplay/field_entry_window_00"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
BANK18_FILE_BASE = 0x030010
FIXED_FILE_BASE = 0x03C010

# Half-open CPU ranges already verified against this ROM by the menu renderer
# audit. They bind the wrapper, descriptor dispatch, row producer, and parser.
CODE_WINDOWS = [
    {"bank": "$1F fixed", "cpu_start": 0xEF7F, "cpu_end_exclusive": 0xEFA0,
     "file_offset": 0x03EF8F,
     "sha256": "2b58982f5d1dd906d58eb693148f3a9ff511064fce6163432f7ff30b8512dca2"},
    {"bank": "$18", "cpu_start": 0x800C, "cpu_end_exclusive": 0x800F,
     "file_offset": 0x03001C,
     "sha256": "bfd10ca38c56f461f9d3a718da2b94402304fd864ca2c9976e33a34df2d20c9a"},
    {"bank": "$18", "cpu_start": 0x8852, "cpu_end_exclusive": 0x88B9,
     "file_offset": 0x030862,
     "sha256": "8d11372278149ca95c4915e95a8e1121b938348cf73ec83408d03f825b62b070"},
    {"bank": "$18", "cpu_start": 0x88B9, "cpu_end_exclusive": 0x8986,
     "file_offset": 0x0308C9,
     "sha256": "e9d2b95c91c49f329f0d9ffb45483c9ad19868c96cbf7e6161665e982ac24570"},
    {"bank": "$18", "cpu_start": 0x8986, "cpu_end_exclusive": 0x89BA,
     "file_offset": 0x030996,
     "sha256": "46ac5f0183f5e0d90c90f248768b6df75bae9c5300a679cc83dfc21efb53888e"},
    {"bank": "$18", "cpu_start": 0x89BA, "cpu_end_exclusive": 0x89DC,
     "file_offset": 0x0309CA,
     "sha256": "74f4bd039c15b503a6b4d4a71652c4c957a179f05cf105c142c04eb740759ebe"},
    {"bank": "$18", "cpu_start": 0x8B48, "cpu_end_exclusive": 0x8B77,
     "file_offset": 0x030B58,
     "sha256": "cdf517738c475cd7991746f6213fea50152fa0b1d3863d77f4d7e618d1d63af3"},
    {"bank": "$18", "cpu_start": 0x8B8B, "cpu_end_exclusive": 0x8BD5,
     "file_offset": 0x030B9B,
     "sha256": "90eca873b94249d9b8c6b70885e9383a118c6af988ce56bd88301b07e912eb2e"},
    {"bank": "$18", "cpu_start": 0x8C55, "cpu_end_exclusive": 0x8CA5,
     "file_offset": 0x030C65,
     "sha256": "f2b7c31fe7df259b3a72ce0b8a2fef86ad4a586d49a30df3d1d8cd272434a61e"},
    {"bank": "$1E fixed", "cpu_start": 0xC509, "cpu_end_exclusive": 0xC50C,
     "file_offset": 0x03C519,
     "sha256": "3b507ee4745afd5b11dda219b523c39c7e9a8881d856592d8908bf535fd63441"},
    {"bank": "$1E fixed", "cpu_start": 0xCB99, "cpu_end_exclusive": 0xCBB0,
     "file_offset": 0x03CBA9,
     "sha256": "1f8058f9fd70aeec319a32433feb0c102c72e0f5131571a0da8bf89ef84a2d54"},
    {"bank": "$1E fixed", "cpu_start": 0xC51E, "cpu_end_exclusive": 0xC521,
     "file_offset": 0x03C52E,
     "sha256": "7b0a50829c23361f1f95e0b52657262d62358c50623da017b3c721ba27ba81e1"},
    {"bank": "$1E fixed", "cpu_start": 0xCD3C, "cpu_end_exclusive": 0xCD77,
     "file_offset": 0x03CD4C,
     "sha256": "2d996c8e5e587175f76672794f405945b4c1c981fa6775cf93b8971f1f39a008"},
    {"bank": "$18", "cpu_start": 0xB3BD, "cpu_end_exclusive": 0xB3C1,
     "file_offset": 0x0333CD,
     "sha256": "df3f619804a92fdb4057192dc43dd748ea778adc52bc498ce80524c014b81119"},
    {"bank": "$18", "cpu_start": 0x8D9E, "cpu_end_exclusive": 0x8DA7,
     "file_offset": 0x030DAE,
     "sha256": "dcb1f10d1a9a0fa616fa2e065790ce038722b09968d265e7901770b3bf9133e0"},
]


def bank18_offset(cpu_address: int) -> int:
    return BANK18_FILE_BASE + cpu_address - 0x8000


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def resource_record(path: str, data: bytes, *, cpu_address: int,
                    file_offset: int, meaning: str) -> dict:
    out_path = OUTPUT_DIR / path
    out_path.write_bytes(data)
    return {
        "path": path,
        "cpu_address": f"0x{cpu_address:04X}",
        "file_offset": f"0x{file_offset:06X}",
        "size_bytes": len(data),
        "sha256": sha256(data),
        "meaning": meaning,
    }


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_sha = sha256(rom)
    require(rom_sha == EXPECTED_ROM_SHA256,
            f"unexpected target ROM SHA-256: {rom_sha}")
    require(len(rom) == 0x60010 and rom[:4] == b"NES\x1a",
            "unexpected iNES header or ROM size")

    for window in CODE_WINDOWS:
        if window["bank"] == "$18":
            start = bank18_offset(window["cpu_start"])
            end = bank18_offset(window["cpu_end_exclusive"])
        else:
            start = FIXED_FILE_BASE + window["cpu_start"] - 0xC000
            end = FIXED_FILE_BASE + window["cpu_end_exclusive"] - 0xC000
        actual = sha256(rom[start:end])
        require(actual == window["sha256"],
                f"code hash mismatch at ${window['cpu_start']:04X}: {actual}")

    pointer_cpu = 0xB3CF
    pointer_offset = bank18_offset(pointer_cpu)
    pointer = rom[pointer_offset:pointer_offset + 2]
    descriptor_cpu = int.from_bytes(pointer, "little")
    require(descriptor_cpu == 0xB453,
            f"descriptor $00 pointer changed: ${descriptor_cpu:04X}")
    descriptor_offset = bank18_offset(descriptor_cpu)
    header = rom[descriptor_offset:descriptor_offset + 9]
    require(len(header) == 9 and header[8] == 2,
            "descriptor $00 header or row count changed")
    descriptor_length = 9 + header[8] * 4
    descriptor = rom[descriptor_offset:descriptor_offset + descriptor_length]
    next_pointer = int.from_bytes(rom[pointer_offset + 2:pointer_offset + 4], "little")
    require(descriptor_cpu + descriptor_length == next_pointer == 0xB464,
            "descriptor $00 length no longer ends at descriptor $01")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    resources = [resource_record(
        "descriptor_00_pointer.bin", pointer,
        cpu_address=pointer_cpu, file_offset=pointer_offset,
        meaning="descriptor-$00 little-endian pointer-table entry"),
        resource_record(
            "descriptor_00.bin", descriptor,
            cpu_address=descriptor_cpu, file_offset=descriptor_offset,
            meaning="descriptor-$00 9-byte header and two 4-byte row records")]
    row_entries = []
    for row_index in range(header[8]):
        record_offset = 9 + row_index * 4
        text_cpu = int.from_bytes(descriptor[record_offset + 2:record_offset + 4], "little")
        text_offset = bank18_offset(text_cpu)
        end_offset = rom.find(b"\xFC", text_offset, text_offset + 0x100)
        require(end_offset >= 0, f"row {row_index} has no $FC terminator")
        row_data = rom[text_offset:end_offset + 1]
        row_entries.append(resource_record(
            f"descriptor_00_row_{row_index:02d}.bin", row_data,
            cpu_address=text_cpu, file_offset=text_offset,
            meaning=f"descriptor-$00 text row {row_index}, through its $FC terminator"))
    resources.extend(row_entries)

    handler_spans = [
        ("token_dispatch_vectors_EF_F0_89BA_89DC.bin", "$18", 0x89BA, 0x89DC,
         "ROM token-vector entries from $E0 through $F0; $EF->$8B48 and $F0->$8B8B"),
        ("ef_match_period_handler_8B48_8B77.bin", "$18", 0x8B48, 0x8B77,
         "$EF handler and five-byte ROM row; period zero selects the initial $FF terminator"),
        ("f0_match_clock_handler_8B8B_8BD5.bin", "$18", 0x8B8B, 0x8BD5,
         "$F0 handler, divisor-six conversion, $8C55 formatter call, and tile lookup table"),
        ("decimal_tile_formatter_8C55_8CA5.bin", "$18", 0x8C55, 0x8CA5,
         "ROM decimal digit emission and character-buffer writer"),
        ("fixed_text_dispatch_C509_C50C.bin", "$1E fixed", 0xC509, 0xC50C,
         "Fixed-bank inline-table dispatcher entry used by $89B4"),
        ("fixed_inline_dispatch_CB99_CBB0.bin", "$1E fixed", 0xCB99, 0xCBB0,
         "Fixed-bank post-JSR inline-pointer dispatch implementation"),
        ("fixed_division_dispatch_C51E_C521.bin", "$1E fixed", 0xC51E, 0xC521,
         "ROM jump-vector entry to the 16-bit divide routine used by $8C55"),
        ("fixed_division_16bit_CD3C_CD77.bin", "$1E fixed", 0xCD3C, 0xCD77,
         "ROM 16-bit division routine used to emit decimal digits"),
    ]
    for filename, bank, cpu_start, cpu_end, meaning in handler_spans:
        if bank == "$18":
            file_offset = bank18_offset(cpu_start)
        else:
            file_offset = FIXED_FILE_BASE + cpu_start - 0xC000
        data = rom[file_offset:file_offset + cpu_end - cpu_start]
        resources.append(resource_record(
            filename, data, cpu_address=cpu_start, file_offset=file_offset,
            meaning=meaning))

    frame_path = "reference/rom_extract/gameplay/menus/first_action_menu/window_3x3_tile_ids.bin"
    frame_offset = bank18_offset(0x8D9E)
    frame_bytes = rom[frame_offset:frame_offset + 9]
    require(sha256(frame_bytes) == CODE_WINDOWS[-1]["sha256"],
            "window-frame tile source hash mismatch")
    packed_family = rom[bank18_offset(0xB3BD)]
    frame_family_index = packed_family & 0x03
    require(frame_family_index == 0,
            f"descriptor $00 window family changed: {frame_family_index}")

    # JSON-safe copies without temporary integer-only code metadata.
    code_manifest = [{
        "bank": window["bank"],
        "cpu_start": f"0x{window['cpu_start']:04X}",
        "cpu_end_exclusive": f"0x{window['cpu_end_exclusive']:04X}",
        "file_offset": f"0x{window['file_offset']:06X}",
        "sha256": window["sha256"],
    } for window in CODE_WINDOWS]
    frame_manifest = {
        "path_from_project_root": frame_path,
        "cpu_address": "0x8D9E",
        "file_offset": f"0x{frame_offset:06X}",
        "size_bytes": 9,
        "sha256": sha256(frame_bytes),
        "raw_hex": frame_bytes.hex(" "),
    }
    manifest = {
        "schema": "ct2-field-entry-window-00-rom-sources-v1",
        "source_rom": {
            "name": ROM_PATH.name,
            "sha256": rom_sha,
            "size_bytes": len(rom),
            "runtime_dependency": False,
        },
        "bank_mapping": {
            "bank_18_cpu_8000_file_base": "0x030010",
            "fixed_cpu_e000_file_base": "0x03E010",
        },
        "resources": resources,
        "shared_frame_family": frame_manifest,
        "descriptor_frame_family_index": frame_family_index,
        "verified_code_windows": code_manifest,
        "packet_contract": {
            "builder": "FirstActionMenuRomLayout.build_packets",
            "record_bytes": "payload length, PPU address low, PPU address high, payload tiles",
            "ready_flag": "$0515 is set by route-owned renderer/task code; this data component does not set it",
            "supported_descriptor_id": "0x00",
            "source_control_tokens": {
                "0xEF": "$89BA vector -> $8B48; reads source period $0027; period zero hits the ROM $FF terminator and emits no tiles",
                "0xF0": "$89BA vector -> $8B8B; reads source clock $05F7/$05F8; divides by six, emits the fractional pair/separator, then ROM decimal digits",
            },
            "source_input_producer": "RomFreshPeriodTask at $D11E-$D182 derives $0027 and loads $05F7/$05F8 from $D183/$D184 before $DAAA",
            "descriptor_00_supported_inputs": {"$0027": "0x00", "$05F7": "0xB4", "$05F8": "0x00"},
            "descriptor_01": "not extracted: its $ED/$EE control tokens and operands are outside the supported contract",
        },
    }

    (OUTPUT_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Extracted descriptor $00 to {OUTPUT_DIR.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

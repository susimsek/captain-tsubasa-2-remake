#!/usr/bin/env python3
"""Extract ROM tables read by the first $A503 setup block."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUTPUT = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_a503"
PRG_OFFSET = 0x10
BANK_SIZE = 0x2000

SPANS = (
    {
        "file": "bank01_match_setup_copy_B33D_B371.bin",
        "bank": 1,
        "cpu_start": 0xB33D,
        "cpu_end_exclusive": 0xB371,
        "role": "Bytes selected by the $A50B LDA $B271,Y loop for Y=$CC..$FF; copied into RAM $0468-$049B.",
    },
    {
        "file": "bank01_match_index_descriptor_BCD1_BCD2.bin",
        "cpu_start": 0xBCD1,
        "cpu_end_exclusive": 0xBCD2,
        "role": "Fresh-match descriptor byte indexed by source RAM $0026=0.",
    },
    {
        "file": "bank01_match_descriptor_pointer_BCF3_BCF5.bin",
        "cpu_start": 0xBCF3,
        "cpu_end_exclusive": 0xBCF5,
        "role": "Little-endian table pointer selected by the high nibble of the fresh-match descriptor.",
    },
    {
        "file": "bank01_match_descriptor_data_BCFF_BD0C.bin",
        "cpu_start": 0xBCFF,
        "cpu_end_exclusive": 0xBD0C,
        "role": "The first fresh-match descriptor stream selected by the $BCFF pointer.",
    },
    {
        "file": "bank00_ppu_descriptor_decoder_9D27_9D50.bin",
        "cpu_start": 0x9D27,
        "cpu_end_exclusive": 0x9D50,
        "role": "ROM decoder that reads destination-addressed streams and stops on the $FF block terminator.",
    },
    {
        "file": "bank00_ppu_descriptor_inner_reader_9D58_9D73.bin",
        "cpu_start": 0x9D58,
        "cpu_end_exclusive": 0x9D73,
        "role": "ROM inner reader that sends payload bytes to the shared PPU queue writer until a $FC-$FF marker.",
    },
    {
        "file": "bank00_ppu_tile_write_helper_88CA_88FB.bin",
        "cpu_start": 0x88CA,
        "cpu_end_exclusive": 0x88FB,
        "role": "ROM helper that encodes low-valued PPU tile bytes into the shared $05E8 update queue.",
    },
    {
        "file": "bank00_ppu_text_reader_wrapper_9D50_9D58.bin",
        "cpu_start": 0x9D50,
        "cpu_end_exclusive": 0x9D58,
        "role": "ROM wrapper that initializes the source pointer and calls the $9D58 text/descriptor reader.",
    },
    {
        "file": "bank01_match_second_descriptor_pointer_table_BD64_BD68.bin",
        "cpu_start": 0xBD64,
        "cpu_end_exclusive": 0xBD68,
        "role": "Pointer entries selected by the low nibble of the fresh-match descriptor byte at $BCD1.",
    },
    {
        "file": "bank01_match_second_descriptor_text_BD7C_BD82.bin",
        "cpu_start": 0xBD7C,
        "cpu_end_exclusive": 0xBD82,
        "role": "ROM text bytes selected by descriptor pointer $BD7C and rendered at PPU address $2207.",
    },
    {
        "file": "bank01_match_text_pointer_table_BDA8_BDB0.bin",
        "cpu_start": 0xBDA8,
        "cpu_end_exclusive": 0xBDB0,
        "role": "Pointer entries read by $A63C for match participant text IDs 0 through 3.",
    },
    {
        "file": "bank01_match_text_id_00_BDF2_BDF9.bin",
        "cpu_start": 0xBDF2,
        "cpu_end_exclusive": 0xBDF9,
        "role": "Terminated ROM tile-text selected by match text ID $00.",
    },
    {
        "file": "bank01_match_text_id_03_BE09_BE11.bin",
        "cpu_start": 0xBE09,
        "cpu_end_exclusive": 0xBE11,
        "role": "Terminated ROM tile-text selected by match text ID $03.",
    },
    {
        "file": "bank01_match_text_pointer_resolver_A63C_A64C.bin",
        "bank": 1,
        "cpu_start": 0xA63C,
        "cpu_end_exclusive": 0xA64C,
        "role": "ROM helper that maps a match text ID through $BDA8 and tail-jumps to the $9D50 tile-text reader.",
    },
    {
        "file": "bank06_match_palette_ramp_source_B040_B050.bin",
        "bank": 6,
        "cpu_start": 0xB040,
        "cpu_end_exclusive": 0xB050,
        "role": "Sixteen source palette entries read by $9AB8 after the $9B07 mapper helper selects PRG bank $06 in the $A000-$BFFF window.",
    },
    {
        "file": "bank06_match_palette_ramp_source_B370_B380.bin",
        "bank": 6,
        "cpu_start": 0xB370,
        "cpu_end_exclusive": 0xB380,
        "role": "Sixteen source palette entries read by $9ADA after the $9B07 mapper helper selects PRG bank $06 in the $A000-$BFFF window.",
    },
    {
        "file": "bank00_match_palette_ramp_997A_99AE.bin",
        "bank": 0,
        "cpu_start": 0x997A,
        "cpu_end_exclusive": 0x99AE,
        "role": "The $A503 caller's bank-$00 palette ramp helper, including the paired-counter loop and $9FA8 yield.",
    },
    {
        "file": "bank00_match_palette_buffer_copy_9AB8_9B07.bin",
        "bank": 0,
        "cpu_start": 0x9AB8,
        "cpu_end_exclusive": 0x9B07,
        "role": "ROM routine that copies two bank-$06 16-byte palette tables into RAM $062A-$0649.",
    },
    {
        "file": "bank00_match_palette_bank_select_9B07_9B11.bin",
        "bank": 0,
        "cpu_start": 0x9B07,
        "cpu_end_exclusive": 0x9B11,
        "role": "ROM helper that saves the current PRG bank in $E9 and selects PRG bank $06 through $C4B9.",
    },
    {
        "file": "bank00_match_palette_transform_9A71_9AB8.bin",
        "bank": 0,
        "cpu_start": 0x9A71,
        "cpu_end_exclusive": 0x9AB8,
        "role": "ROM routine that transforms $062A-$0649 through the $9EA2 lookup and appends the 32-byte $3F00 palette payload.",
    },
    {
        "file": "bank00_match_palette_lookup_9EA2_9EE2.bin",
        "bank": 0,
        "cpu_start": 0x9EA2,
        "cpu_end_exclusive": 0x9EE2,
        "role": "The 64-byte ROM lookup used by $9AA2 when converting the paired match-palette values.",
    },
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    if sha256(rom) != ROM_SHA256:
        raise SystemExit("Input ROM does not match the pinned source revision.")
    if rom[:4] != b"NES\x1a" or len(rom) < PRG_OFFSET + 0x40000:
        raise SystemExit("Input is not the expected iNES image with 256 KiB PRG.")
    OUTPUT.mkdir(parents=True, exist_ok=True)

    entries = []
    for spec in SPANS:
        start = int(spec["cpu_start"])
        end = int(spec["cpu_end_exclusive"])
        selected_bank = int(spec.get("bank", 0 if start < 0xA000 else 1))
        if 0x8000 <= start < end <= 0xA000:
            file_offset = PRG_OFFSET + selected_bank * BANK_SIZE + (start - 0x8000)
        elif 0xA000 <= start < end <= 0xC000:
            file_offset = PRG_OFFSET + selected_bank * BANK_SIZE + (start - 0xA000)
        else:
            raise SystemExit(f"Span {spec['file']} crosses or falls outside the pinned PRG bank windows.")
        data = rom[file_offset : file_offset + end - start]
        if len(data) != end - start:
            raise SystemExit(f"Truncated source span for {spec['file']}.")
        (OUTPUT / str(spec["file"])).write_bytes(data)
        entries.append(
            {
                "file": spec["file"],
                "cpu_start": f"${start:04X}",
                "cpu_end_exclusive": f"${end:04X}",
                "file_offset": f"0x{file_offset:06X}",
                "bank": f"${selected_bank:02X}",
                "length": len(data),
                "sha256": sha256(data),
                "bytes": data.hex(),
                "role": spec["role"],
            }
        )

    manifest = {
        "schema": "ct2-fresh-match-a503-entry-v1",
        "rom": {"name": ROM_PATH.name, "sha256": ROM_SHA256},
        "mapping": "The iNES header is 16 bytes and each PRG bank is 0x2000 bytes. CPU $8000-$9FFF and $A000-$BFFF spans use the explicit bank field; for the upper window, file offset is 0x10 + bank*0x2000 + (CPU-$A000).",
        "spans": entries,
    }
    (OUTPUT / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Preserved {len(entries)} ROM spans for the $A503 entry and palette ramp.")
    for entry in entries:
        print(
            f"{entry['cpu_start']}-{entry['cpu_end_exclusive']}: "
            f"{entry['length']} bytes, SHA-256 {entry['sha256']}"
        )


if __name__ == "__main__":
    main()

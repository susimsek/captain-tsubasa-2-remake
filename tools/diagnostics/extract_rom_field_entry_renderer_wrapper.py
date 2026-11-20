#!/usr/bin/env python3
"""Extract the first fresh field-entry renderer call from the supplied ROM."""

from __future__ import annotations

import hashlib
import json
import pathlib
import sys


ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
OUT = pathlib.Path("reference/rom_extract/gameplay/field_entry_renderer_wrapper")
FILE_NAME = "fixed_field_entry_first_wrapper_E0DF_E0E4.bin"
CPU_START = 0xE0DF
CPU_END = 0xE0E4
FILE_OFFSET = 0x3E0EF
SECOND_FILE_NAME = "fixed_field_entry_descriptor01_call_E0E4_E0E9.bin"
SECOND_CPU_START = 0xE0E4
SECOND_CPU_END = 0xE0E9
SECOND_FILE_OFFSET = 0x3E0F4
THIRD_FILE_NAME = "fixed_field_entry_setup_E0E9_E349.bin"
THIRD_CPU_START = 0xE0E9
THIRD_CPU_END = 0xE349
THIRD_FILE_OFFSET = 0x3E0F9
MINIMAP_VECTOR_FILE = "bank1c_minimap_vector_8024_8027.bin"
MINIMAP_VECTOR_START = 0x8024
MINIMAP_VECTOR_END = 0x8027
MINIMAP_VECTOR_OFFSET = 0x38034
MINIMAP_CODE_FILE = "bank1c_minimap_loader_82ca_834a.bin"
MINIMAP_CODE_START = 0x82CA
MINIMAP_CODE_END = 0x834A
MINIMAP_CODE_OFFSET = 0x382DA
MINIMAP_VECTOR_SHA256 = "3fc1852a2f27a5e7edaa250c130b8897d38a4e534a44a03bdade64ce4a6fb4b0"
MINIMAP_CODE_SHA256 = "f703a26d854b60578d8174843a44689b39669e1100b659a187c793ede90c15b8"
MINIMAP_TILES_FILE = "bank1c_minimap_tiles_834a_846a.bin"
MINIMAP_TILES_START = 0x834A
MINIMAP_TILES_END = 0x846A
MINIMAP_TILES_OFFSET = 0x3835A
MINIMAP_TILES_SHA256 = "3b0901589a4bf451e4135e24001a9e3b710d513601294df614984d68acb66235"
SHARED_WAITER_FILE = "fixed_shared_waiter_CC46_CCD2.bin"
SHARED_WAITER_START = 0xCC46
SHARED_WAITER_END = 0xCCD2
SHARED_WAITER_OFFSET = 0x3CC56
SHARED_WAITER_SHA256 = "21a4cd33eb56fe3d4da516e0eff910ff375a8d7c3ff42bfa46dfb691a846d5cc"


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: extract_rom_field_entry_renderer_wrapper.py <supplied-rom.nes>", file=sys.stderr)
        return 2
    rom_path = pathlib.Path(sys.argv[1])
    rom = rom_path.read_bytes()
    if hashlib.sha256(rom).hexdigest() != ROM_SHA256:
        raise SystemExit("ROM hash mismatch")
    source = rom[FILE_OFFSET : FILE_OFFSET + CPU_END - CPU_START]
    if len(source) != CPU_END - CPU_START or source != bytes([0xA9, 0x00, 0x20, 0x7F, 0xEF]):
        raise SystemExit("Unexpected fixed-bank $E0DF source bytes")
    second_source = rom[SECOND_FILE_OFFSET : SECOND_FILE_OFFSET + SECOND_CPU_END - SECOND_CPU_START]
    if len(second_source) != SECOND_CPU_END - SECOND_CPU_START \
            or second_source != bytes([0xA9, 0x01, 0x20, 0x7F, 0xEF]):
        raise SystemExit("Unexpected fixed-bank $E0E4 descriptor-$01 source bytes")
    third_source = rom[THIRD_FILE_OFFSET : THIRD_FILE_OFFSET + THIRD_CPU_END - THIRD_CPU_START]
    if len(third_source) != THIRD_CPU_END - THIRD_CPU_START \
            or third_source[:3] != bytes([0x20, 0x33, 0xE2]):
        raise SystemExit("Unexpected fixed-bank $E0E9 field-entry source bytes")
    minimap_vector = rom[MINIMAP_VECTOR_OFFSET : MINIMAP_VECTOR_OFFSET + MINIMAP_VECTOR_END - MINIMAP_VECTOR_START]
    minimap_code = rom[MINIMAP_CODE_OFFSET : MINIMAP_CODE_OFFSET + MINIMAP_CODE_END - MINIMAP_CODE_START]
    if len(minimap_vector) != 3 or minimap_vector != bytes([0x4C, 0xCA, 0x82]) \
            or hashlib.sha256(minimap_vector).hexdigest() != MINIMAP_VECTOR_SHA256:
        raise SystemExit("Unexpected bank-$1C `$8024->$82CA` minimap vector")
    if len(minimap_code) != MINIMAP_CODE_END - MINIMAP_CODE_START \
            or hashlib.sha256(minimap_code).hexdigest() != MINIMAP_CODE_SHA256:
        raise SystemExit("Unexpected bank-$1C `$82CA-$834A` minimap loader bytes")
    minimap_tiles = rom[MINIMAP_TILES_OFFSET : MINIMAP_TILES_OFFSET + MINIMAP_TILES_END - MINIMAP_TILES_START]
    if len(minimap_tiles) != 12 * 24 or hashlib.sha256(minimap_tiles).hexdigest() != MINIMAP_TILES_SHA256:
        raise SystemExit("Unexpected bank-$1C `$834A-$846A` minimap tile table")
    shared_waiter = rom[SHARED_WAITER_OFFSET : SHARED_WAITER_OFFSET + SHARED_WAITER_END - SHARED_WAITER_START]
    if len(shared_waiter) != SHARED_WAITER_END - SHARED_WAITER_START \
            or hashlib.sha256(shared_waiter).hexdigest() != SHARED_WAITER_SHA256:
        raise SystemExit("Unexpected fixed-bank `$CC46-$CCD2` shared buffer waiter")
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / FILE_NAME).write_bytes(source)
    (OUT / SECOND_FILE_NAME).write_bytes(second_source)
    (OUT / THIRD_FILE_NAME).write_bytes(third_source)
    (OUT / MINIMAP_VECTOR_FILE).write_bytes(minimap_vector)
    (OUT / MINIMAP_CODE_FILE).write_bytes(minimap_code)
    (OUT / MINIMAP_TILES_FILE).write_bytes(minimap_tiles)
    (OUT / SHARED_WAITER_FILE).write_bytes(shared_waiter)
    spans = [
        {
            "file": FILE_NAME,
            "bank": "0x1F",
            "window": "fixed",
            "cpu_start": f"0x{CPU_START:04X}",
            "cpu_end_exclusive": f"0x{CPU_END:04X}",
            "file_offset": f"0x{FILE_OFFSET:06X}",
            "length": len(source),
            "sha256": hashlib.sha256(source).hexdigest(),
            "description": "ROM code: LDA #$00 selects descriptor $00, then JSR $EF7F enters the fixed renderer wrapper.",
            "bytes": source.hex(" "),
        },
        {
            "file": SECOND_FILE_NAME,
            "bank": "0x1F",
            "window": "fixed",
            "cpu_start": f"0x{SECOND_CPU_START:04X}",
            "cpu_end_exclusive": f"0x{SECOND_CPU_END:04X}",
            "file_offset": f"0x{SECOND_FILE_OFFSET:06X}",
            "length": len(second_source),
            "sha256": hashlib.sha256(second_source).hexdigest(),
            "description": "ROM code: after descriptor $00 returns, LDA #$01 selects descriptor $01 and JSR $EF7F enters the second renderer call.",
            "bytes": second_source.hex(" "),
        },
        {
            "file": THIRD_FILE_NAME,
            "bank": "0x1F",
            "window": "fixed",
            "cpu_start": f"0x{THIRD_CPU_START:04X}",
            "cpu_end_exclusive": f"0x{THIRD_CPU_END:04X}",
            "file_offset": f"0x{THIRD_FILE_OFFSET:06X}",
            "length": len(third_source),
            "sha256": hashlib.sha256(third_source).hexdigest(),
            "description": "Fixed-bank ROM source from the post-render `$E233` field-setup call through the `$E349` input-loop entry.",
            "bytes": third_source.hex(" "),
        },
        {
            "file": MINIMAP_VECTOR_FILE,
            "bank": "0x1C",
            "window": "switchable-$8000",
            "cpu_start": f"0x{MINIMAP_VECTOR_START:04X}",
            "cpu_end_exclusive": f"0x{MINIMAP_VECTOR_END:04X}",
            "file_offset": f"0x{MINIMAP_VECTOR_OFFSET:06X}",
            "length": len(minimap_vector),
            "sha256": hashlib.sha256(minimap_vector).hexdigest(),
            "description": "ROM jump vector selected by fixed-bank `$E247 JSR $8024`; routes to minimap loader `$82CA`.",
            "bytes": minimap_vector.hex(" "),
        },
        {
            "file": MINIMAP_CODE_FILE,
            "bank": "0x1C",
            "window": "switchable-$8000",
            "cpu_start": f"0x{MINIMAP_CODE_START:04X}",
            "cpu_end_exclusive": f"0x{MINIMAP_CODE_END:04X}",
            "file_offset": f"0x{MINIMAP_CODE_OFFSET:06X}",
            "length": len(minimap_code),
            "sha256": hashlib.sha256(minimap_code).hexdigest(),
            "description": "ROM code for the 12-row minimap setup, including `$C52D` wait helper, `$04A5` packet builder calls, `$0515` buffer handshake, and the `$834A` tile-table pointer.",
            "bytes": minimap_code.hex(" "),
        },
        {
            "file": MINIMAP_TILES_FILE,
            "bank": "0x1C",
            "window": "switchable-$8000",
            "cpu_start": f"0x{MINIMAP_TILES_START:04X}",
            "cpu_end_exclusive": f"0x{MINIMAP_TILES_END:04X}",
            "file_offset": f"0x{MINIMAP_TILES_OFFSET:06X}",
            "length": len(minimap_tiles),
            "sha256": hashlib.sha256(minimap_tiles).hexdigest(),
            "description": "ROM tile-ID table read by the minimap row producer: 12 rows × 24 tiles, before full-pitch drawing replaces the lower-screen area.",
            "bytes": minimap_tiles.hex(" "),
        },
        {
            "file": SHARED_WAITER_FILE,
            "bank": "0x1E",
            "window": "fixed",
            "cpu_start": f"0x{SHARED_WAITER_START:04X}",
            "cpu_end_exclusive": f"0x{SHARED_WAITER_END:04X}",
            "file_offset": f"0x{SHARED_WAITER_OFFSET:06X}",
            "length": len(shared_waiter),
            "sha256": hashlib.sha256(shared_waiter).hexdigest(),
            "description": "Shared ROM wait/PPU-packet helper reached by `$C52D`; covers `$CC50`, `$CCA0`, and `$CCCE` scheduler yields through the source `$CCD1 RTS`.",
            "bytes": shared_waiter.hex(" "),
        },
    ]
    manifest = {
        "schema": "ct2-field-entry-renderer-wrapper-source-v1",
        "rom_sha256": ROM_SHA256,
        "mapping": "iNES PRG starts at 0x0010; fixed bank $1F maps CPU $E000-$FFFF.",
        "scope": "The fresh field-entry descriptor-$00 call at `$E0DF`, descriptor-$01 call at `$E0E4`, fixed-bank field setup from `$E0E9` through `$E349`, and bank-$1C `$8024->$82CA` minimap source; asynchronous renderer workers, NMI, and PPU output remain separate source effects.",
        "spans": spans,
        "limitations": [
            "The packaged fixed-bank span ends at `$E349`, at field-loop input entry; it does not model the complete field loop, NMI cadence, or PPU output.",
            "The minimap's cooperative row execution and PPU/NMI transfer still require a connected runtime path.",
            "Emulator traces are comparison evidence only; runtime executes the extracted ROM bytes and decoded fixed wrapper.",
        ],
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Extracted {FILE_NAME}: {source.hex(' ')}")
    print(f"Extracted {SECOND_FILE_NAME}: {second_source.hex(' ')}")
    print(f"Extracted {THIRD_FILE_NAME}: {third_source.hex(' ')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

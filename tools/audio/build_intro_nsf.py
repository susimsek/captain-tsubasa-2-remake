#!/usr/bin/env python3
"""Build a standalone NSF from the supplied game's original sound-driver bytes.

The NSF is an intermediate offline rendering input, not a project runtime asset.
The only changed driver instructions are five MMC3 bank writes: its selected music
bank is mapped permanently into the NSF's $A000-$BFFF window for one cue.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
EXPECTED_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
DRIVER_FILE_OFFSET = 0x018010
DRIVER_CPU_ADDRESS = 0x8000
DRIVER_LENGTH = 0x2000
DPCM_FILE_OFFSET = 0x03C010
# Runtime queue IDs with ROM-verified source banks for the offline wrapper.
# $30/$31/$66/$69 are effects whose streams reside in the copied bank-$0C
# driver window. Runtime BGM ranges $32-$43, $44-$50, and $51-$5B select
# banks $0D, $0E, and $0F respectively.
MUSIC_BANKS = {
    0x2B: 0x0C,
    0x2C: 0x0C,
    0x30: 0x0C,
    0x31: 0x0C,
    0x35: 0x0D,
    0x36: 0x0D,
    0x3C: 0x0D,
    0x44: 0x0E,
    0x45: 0x0E,
    0x51: 0x0F,
    0x53: 0x0F,
    0x55: 0x0F,
    0x58: 0x0F,
    0x66: 0x0C,
    0x69: 0x0C,
}
MMC3_WRITE_CPU_ADDRESSES = (0x8011, 0x8022, 0x8036, 0x804A, 0x805B)


def make_wrapper(track: int) -> bytes:
    # $E000 INIT: clear CPU RAM, turn on four tonal APU voices, queue track.
    init = bytes(
        [
            0xA9, 0x00,       # LDA #$00
            0xAA,             # TAX
            0x9D, 0x00, 0x00, # STA $0000,X
            0x9D, 0x00, 0x01, # STA $0100,X
            0x9D, 0x00, 0x02, # STA $0200,X
            0x9D, 0x00, 0x03, # STA $0300,X
            0x9D, 0x00, 0x04, # STA $0400,X
            0x9D, 0x00, 0x05, # STA $0500,X
            0x9D, 0x00, 0x06, # STA $0600,X
            0x9D, 0x00, 0x07, # STA $0700,X
            0xE8,             # INX
            0xD0, 0xE5,       # BNE $E003
            0xA9, 0x0F,       # LDA #$0F
            0x8D, 0x15, 0x40, # STA $4015
            0xA9, track,      # LDA #cue
            0x8D, 0x00, 0x07, # STA $0700, driver's incoming sound queue
            0x60,             # RTS
        ]
    )
    # $E030 PLAY: invoke the original driver once per NTSC frame.
    if len(init) > 0x30:
        raise ValueError("init routine crossed PLAY address")
    play = bytes([0x20, 0x00, 0x80, 0x60])
    return init.ljust(0x30, b"\xEA") + play


def nsf_header(track: int) -> bytes:
    h = bytearray(128)
    h[0:5] = b"NESM\x1A"
    h[5] = 1
    h[6] = 1
    h[7] = 1
    h[8:14] = bytes([0x00, 0x80, 0x00, 0xE0, 0x30, 0xE0])
    h[14:46] = f"Captain Tsubasa 2 cue ${track:02X}".encode("ascii").ljust(32, b"\0")
    h[46:78] = b"Tecmo ROM sound driver".ljust(32, b"\0")
    h[78:110] = b"ROM-derived offline build".ljust(32, b"\0")
    h[110:112] = (16639).to_bytes(2, "little")
    h[120:122] = (19997).to_bytes(2, "little")
    h[122] = 0  # NTSC
    h[123] = 0  # stock NES APU
    return bytes(h)


def build(track: int, output: Path) -> dict:
    rom = ROM.read_bytes()
    digest = hashlib.sha256(rom).hexdigest()
    if digest != EXPECTED_SHA256:
        raise ValueError(f"Supplied ROM hash mismatch: {digest}")
    driver = bytearray(rom[DRIVER_FILE_OFFSET : DRIVER_FILE_OFFSET + DRIVER_LENGTH])
    verified_patches = []
    for address in MMC3_WRITE_CPU_ADDRESSES:
        offset = address - DRIVER_CPU_ADDRESS
        old = bytes(driver[offset : offset + 3])
        if old != bytes.fromhex("8C 01 80"):
            raise ValueError(f"Unexpected MMC3 write at ${address:04X}: {old.hex()}")
        driver[offset : offset + 3] = bytes.fromhex("EA EA EA")
        verified_patches.append({"cpu_address": f"0x{address:04X}", "rom_file_offset": f"0x{DRIVER_FILE_OFFSET + offset:06X}", "original": old.hex(), "nsf": "eaeaea"})

    bank = MUSIC_BANKS[track]
    music_offset = 16 + bank * 0x2000
    music = rom[music_offset : music_offset + 0x2000]
    # Source DPCM data is in PRG bank $1E, which the cartridge keeps at $C000.
    dpcm = rom[DPCM_FILE_OFFSET : DPCM_FILE_OFFSET + 0x2000]
    payload = bytes(driver) + music + dpcm + make_wrapper(track).ljust(0x2000, b"\0")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(nsf_header(track) + payload)
    return {
        "source_rom_sha256": digest,
        "cue": f"0x{track:02X}",
        "driver_source_file_offset": f"0x{DRIVER_FILE_OFFSET:06X}",
        "music_prg_bank": f"0x{bank:02X}",
        "music_source_file_offset": f"0x{music_offset:06X}",
        "dpcm_source_file_offset": f"0x{DPCM_FILE_OFFSET:06X}",
        "driver_mmc3_write_patches": verified_patches,
        "nsf_sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        "note": "Offline NSF wrapper containing the original ROM driver and track bank; the five MMC3 mapping writes become NOPs because the NSF memory map pins this cue's music bank at $A000-$BFFF. The wrapper queues the requested sound ID and invokes the original driver once per NTSC frame.",
    }


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--track", type=lambda s: int(s, 0), default=0x58, choices=MUSIC_BANKS)
    p.add_argument("--output", type=Path, default=ROOT / "tools/audio/build/intro_track_58_driver.nsf")
    args = p.parse_args()
    info = build(args.track, args.output)
    args.output.with_suffix(".json").write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
    print(args.output)


if __name__ == "__main__":
    main()

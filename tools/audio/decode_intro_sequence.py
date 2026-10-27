#!/usr/bin/env python3
"""Decode track #$58 into a bounded ROM-provenance event trace.

This is a sequencer analysis aid, not an audio renderer. It understands the
original driver's note/duration bytes and common stream-control commands, but
does not claim to reproduce the driver's APU writes, envelopes, or mix.
"""

from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
OUT_PATH = ROOT / "reference" / "rom_extract" / "audio" / "intro_track_58_events.json"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
MUSIC_BANK_FILE_OFFSET = 0x01E010  # disassembly bank 8F, CPU $A000-$BFFF
DRIVER_BANK_FILE_OFFSET = 0x018010  # disassembly bank 8C
DRIVER_NOTE_PERIODS_OFFSET = DRIVER_BANK_FILE_OFFSET + (0x870D - 0x8000)
DRIVER_DURATIONS_OFFSET = DRIVER_BANK_FILE_OFFSET + (0x8725 - 0x8000)
TRACK_FILE_OFFSET = 0x01F7BD
MAX_INSTRUCTIONS = 100_000
MAX_TICKS = 10_000


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    rom = ROM_PATH.read_bytes()
    rom_hash = digest(rom)
    if rom_hash != ROM_SHA256:
        raise SystemExit(f"ROM hash mismatch: {rom_hash}")
    if rom[:4] != b"NES\x1a":
        raise SystemExit("Invalid iNES file")

    # The original track directory has channel ID + little-endian CPU pointer
    # records, terminated by FF. All offsets are verified against the disassembly.
    channels: dict[int, int] = {}
    cursor = TRACK_FILE_OFFSET
    while rom[cursor] != 0xFF:
        channel = rom[cursor]
        addr = rom[cursor + 1] | (rom[cursor + 2] << 8)
        if channel not in (4, 5, 6, 7):
            raise SystemExit(f"Unexpected track channel ID {channel:02X}")
        channels[channel] = addr
        cursor += 3
    if set(channels) != {4, 5, 6, 7}:
        raise SystemExit(f"Unexpected channel table: {channels}")

    # The twelve 11-bit timer periods and note-length table are literal driver data.
    periods = [int.from_bytes(rom[DRIVER_NOTE_PERIODS_OFFSET + i * 2 : DRIVER_NOTE_PERIODS_OFFSET + i * 2 + 2], "little") for i in range(12)]
    durations = list(rom[DRIVER_DURATIONS_OFFSET : DRIVER_DURATIONS_OFFSET + 0x2F])
    channel_results = {}

    def file_offset(cpu_address: int) -> int:
        if not 0xA000 <= cpu_address <= 0xBFFF:
            raise ValueError(f"Music pointer {cpu_address:04X} outside bank-8F CPU window")
        return MUSIC_BANK_FILE_OFFSET + cpu_address - 0xA000

    for channel_id, start_addr in channels.items():
        pc = start_addr
        call_stack: list[int] = []
        notes = []
        trace_counts: Counter[int] = Counter()
        warnings: Counter[str] = Counter()
        tick = 0
        duration_code = 1
        steps = 0
        ended = False

        def read_byte() -> int:
            nonlocal pc
            off = file_offset(pc)
            value = rom[off]
            pc = (pc + 1) & 0xFFFF
            return value

        while steps < MAX_INSTRUCTIONS and tick < MAX_TICKS:
            steps += 1
            try:
                op_addr = pc
                op = read_byte()
            except (ValueError, IndexError):
                warnings["pointer_outside_bank"] += 1
                break
            trace_counts[op] += 1

            if op < 0x80:
                # Driver sub_83CB indexes the $870D period table by the low
                # nibble and shifts the period right by the high nibble.
                semitone = op & 0x0F
                octave_shift = op >> 4
                if semitone >= 12:
                    warnings[f"special_note_{op:02X}"] += 1
                    notes.append({"tick": tick, "byte": f"{op:02X}", "kind": "special_note_unresolved"})
                    tick += durations[duration_code] if duration_code < len(durations) else 1
                    continue
                timer = periods[semitone] >> octave_shift
                notes.append(
                    {
                        "tick": tick,
                        "duration_code": f"{duration_code:02X}",
                        "duration_ticks": durations[duration_code] if duration_code < len(durations) else None,
                        "note_byte": f"{op:02X}",
                        "semitone_index": semitone,
                        "octave_shift": octave_shift,
                        "apu_timer_period": timer,
                        "source_cpu_address": f"${op_addr:04X}",
                    }
                )
                tick += durations[duration_code] if duration_code < len(durations) else 1
                continue

            if 0x80 <= op <= 0xAF:
                duration_code = op & 0x3F
                continue
            if 0xB0 <= op <= 0xBF:
                _ = read_byte()  # driver skips one associated parameter byte
                continue

            if op == 0xE8:
                low, high = read_byte(), read_byte()
                pc = low | (high << 8)
            elif op == 0xE9:
                low, high = read_byte(), read_byte()
                call_stack.append(pc)
                pc = low | (high << 8)
                if len(call_stack) > 16:
                    warnings["call_depth_limit"] += 1
                    break
            elif op == 0xEA:
                if call_stack:
                    pc = call_stack.pop()
                else:
                    ended = True
                    break
            elif op in (0xE0, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xEB, 0xED, 0xFE):
                value = read_byte()
                if op == 0xE0:
                    warnings[f"envelope_or_patch_{value:02X}"] += 1
                elif op == 0xE3:
                    warnings[f"volume_command_{value:02X}"] += 1
                elif op == 0xED:
                    warnings[f"loop_mode_command_{value:02X}"] += 1
                else:
                    warnings[f"command_{op:02X}_parameter_{value:02X}"] += 1
            elif op == 0xEF:
                # Driver handler clears the current channel's control mode; no operand.
                warnings["EF_control_mode_reset"] += 1
            elif op == 0xEC:
                # EC uses the driver's nested loop frame. The loop frame is
                # initialized/maintained by ED and runtime RAM, not explicit
                # bytes here; fail closed instead of inventing a loop count.
                warnings["unsupported_nested_EC_loop"] += 1
                break
            elif op == 0xF0:
                read_byte(); read_byte()  # exact driver F0 handler advances Y twice
            elif op in (0xE1, 0xEE, 0xF1, 0xF5, 0xF6, 0xF7, 0xF8):
                read_byte()  # driver no-op table entries consume one byte
            elif op in (0xF2, 0xF3, 0xF4, 0xF9, 0xFA, 0xFB):
                # State/DMC operations have no inline operand; their effects
                # depend on driver RAM and original DPCM sample data.
                warnings[f"state_or_DMC_command_{op:02X}"] += 1
            elif op == 0xFF:
                ended = True
                break
            else:
                warnings[f"unsupported_command_{op:02X}"] += 1
                break

        if steps >= MAX_INSTRUCTIONS:
            warnings["instruction_limit"] += 1
        if tick >= MAX_TICKS:
            warnings["tick_limit"] += 1
        channel_results[f"{channel_id:02X}"] = {
            "entry_cpu_address": f"${start_addr:04X}",
            "decoded_note_count": len(notes),
            "decoded_until_tick": tick,
            "ended": ended,
            "commands_seen": {f"{key:02X}": value for key, value in sorted(trace_counts.items())},
            "warnings": dict(warnings),
            "notes": notes,
        }

    result = {
        "format": "ROM-provenance sequencer event trace; NOT rendered audio",
        "source_rom_sha256": rom_hash,
        "track_id": "0x58",
        "source_track_file_offset": "0x01F7BD",
        "byte_verified_dpcm_source_candidate": {
            "file": "reference/rom_extract/audio/dpcm_sample_blob.bin",
            "rom_file_start": "0x03C010",
            "size_bytes": 1009,
            "note": "Exact ROM bytes match the local disassembly's DPCM.bin, but their mapping to F9/FA/FB DMC addresses is not yet proven for this mapper.",
        },
        "verified_driver_file_range": ["0x018010", "0x01A00F"],
        "verified_driver_table_offsets": {
            "note_periods_tbl_870D": f"0x{DRIVER_NOTE_PERIODS_OFFSET:06X}",
            "durations_tbl_8725": f"0x{DRIVER_DURATIONS_OFFSET:06X}",
        },
        "timing_note": "Ticks are the literal lengths from the driver's table; their conversion to output sample time and channel scheduling depends on the driver's frame update cadence and is not asserted here.",
        "channel_mapping_note": "Sequencer source channels 04-07 are identified from the ROM track header; exact APU voice behavior and NES mixer output are not synthesized.",
        "channels": channel_results,
        "unsupported_driver_behavior": [
            "EC nested loops whose count/stack state lives in NES RAM",
            "E0 instrument/envelope macros from driver lookup tables",
            "E2/E4/E5 modulation and channel control semantics",
            "driver's frame-to-APU write cadence and register side effects",
            "DMC sample playback and DPCM data",
            "NES APU nonlinear mixer, pulse/triangle/noise phase and envelope behavior",
        ],
    }
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_PATH.relative_to(ROOT)}")
    for ch, details in channel_results.items():
        print(ch, details["decoded_note_count"], details["decoded_until_tick"], details["warnings"])


if __name__ == "__main__":
    main()

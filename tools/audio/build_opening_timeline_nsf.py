#!/usr/bin/env python3
"""Build an offline cold-start opening audio NSF from original ROM code/data.

By default FCEUX RAM snapshots supply observed cue IDs/frames at $0700. An
explicit presenter-JSON mode instead uses the ROM-command presenter for $ED
cues and separately byte-verifies the title Stop. Both modes retain the
capture list as an event validation oracle. Captured PCM is never an output
source; the NSF is not a Godot runtime dependency.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from build_intro_nsf import EXPECTED_SHA256, ROOT, ROM, make_wrapper
from derive_opening_sound_events import derive_events

ROM_PRG_START = 0x10
PRG_SIZE = 0x40000
DRIVER_ROM_OFFSET = 0x018010
WRAPPER_PAGE = PRG_SIZE // 0x1000
WRAPPER_CPU_START = 0xE000
PLAY_CPU_ADDRESS = 0xE040
BANK_TRAMPOLINE = 0xE100
EVENT_TABLE = 0xE200
NSF_STARTUP_PHASE_FRAMES = 3
ROM_DRIVER_BANK_WRITES = (0x8011, 0x8022, 0x8036, 0x804A, 0x805B)
APU_SETUP_EVENT = (5, 0xFE)  # Legacy-seed marker; the ROM has no FE cue.
APU_SETUP_PLAY_INDEX = APU_SETUP_EVENT[0] - NSF_STARTUP_PHASE_FRAMES
APU_SETUP_ROUTINE = 0xE300
APU_SETUP_ROM_BANK = 0x1E
APU_SETUP_ROM_CPU_START = 0xC685
APU_SETUP_ROM_BYTES = bytes.fromhex("A9 00 8D 10 40 A9 40 8D 17 40")
APU_SETUP_FCEUX_CYCLES = (111988, 111994)
APU_SETUP_NSF_CYCLES = (110854, 110860)  # Unadjusted NSF bus-write cycles.
# Frame-4 FCEUX bus hooks show the unadjusted NSF setup writes are 1,134 cycles early.
APU_SETUP_DEFAULT_EXTRA_DELAY_CYCLES = 1134

# Captured RAM $0700 supplies the cue schedule. The offline event manifest
# verifies every ED source against the live CPU/MMC3 trace and original ROM;
# the title stop is verified against the bank-0 store instruction.
EVENT_DETAILS, EVENT_DERIVATION = derive_events()
EVENTS = tuple((event["frame"], event["sound_id"]) for event in EVENT_DETAILS)
NSF_EVENTS = (APU_SETUP_EVENT,) + EVENTS


def _event_signature(events: list[dict]) -> list[tuple[int, int]]:
    return [(int(event["frame"]), int(event["sound_id"])) for event in events]


def _presenter_events_from_json(path: Path, stop_frame: int, rom: bytes) -> tuple[list[dict], dict]:
    """Validate ROM-presenter $ED events and add the separate $8048 title Stop."""
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict) or not payload.get("diagnostic"):
        raise ValueError("Presenter event input must be a diagnostic JSON object")
    if payload.get("capture_used_to_schedule_source_events") is not False:
        raise ValueError("Presenter event JSON does not declare capture-independent source scheduling")
    if payload.get("presenter_rom_sha256") != EXPECTED_SHA256:
        raise ValueError("Presenter event JSON ROM hash does not match the supplied ROM")
    if payload.get("source_slice_error"):
        raise ValueError(f"Presenter stopped with a source-slice error: {payload['source_slice_error']}")

    rows = payload.get("source_events")
    if not isinstance(rows, list) or not rows:
        raise ValueError("Presenter JSON contains no source $ED events")
    ed_events: list[dict] = []
    previous_frame = -1
    for ordinal, row in enumerate(rows, 1):
        if not isinstance(row, dict):
            raise ValueError(f"Presenter event {ordinal} is not an object")
        frame = int(row.get("source_frame", -1))
        sound_id = int(row.get("sound_id", -1))
        cpu_address = int(str(row.get("script_cpu", "0")).replace("$", ""), 16)
        file_offset = int(str(row.get("rom_file_offset", "0")), 16)
        if frame <= previous_frame or not 0 <= sound_id <= 0xFF:
            raise ValueError(f"Presenter event {ordinal} has invalid frame/order or sound ID")
        if not 0xA000 <= cpu_address <= 0xBFFF:
            raise ValueError(f"Presenter event {ordinal} is outside the bank-3 script window")
        expected_offset = 0x10 + 3 * 0x2000 + cpu_address - 0xA000
        if file_offset != expected_offset:
            raise ValueError(f"Presenter event {ordinal} CPU/file mapping disagrees: ${cpu_address:04X}")
        expected_bytes = bytes((0xED, sound_id))
        if rom[file_offset:file_offset + 2] != expected_bytes:
            raise ValueError(f"Presenter event {ordinal} bytes disagree with ROM at 0x{file_offset:06X}")
        if str(row.get("raw_bytes", "")).upper() != f"$ED ${sound_id:02X}":
            raise ValueError(f"Presenter event {ordinal} decoded bytes disagree with its sound ID")
        ed_events.append({
            "frame": frame,
            "sound_id": sound_id,
            "command_source": "ROM presenter $ED command; CPU mapping and source bytes verified",
            "source_status": "presenter_json_rom_byte_verified_timing_modelled",
            "cpu_address": f"0x{cpu_address:04X}",
            "rom_file_offset": f"0x{file_offset:06X}",
            "rom_raw_hex": expected_bytes.hex(" "),
            "presenter_ordinal": ordinal,
        })
        previous_frame = frame

    stop_offset = 0x0058
    stop_bytes = bytes.fromhex("A9 01 8D 00 07")
    if rom[stop_offset:stop_offset + len(stop_bytes)] != stop_bytes:
        raise ValueError("Bank-0 $8048 title Stop bytes no longer match the supplied ROM")
    if stop_frame <= previous_frame:
        raise ValueError("Title Stop frame must follow the final presenter $ED event")
    stop_event = {
        "frame": stop_frame,
        "sound_id": 0x01,
        "command_source": "ROM bank-0 title-entry Stop at $8048; opcode bytes verified",
        "source_status": "rom_byte_verified_explicit_input_frame",
        "cpu_address": "0x8048",
        "rom_file_offset": f"0x{stop_offset:06X}",
        "rom_raw_hex": stop_bytes.hex(" "),
    }
    events = ed_events + [stop_event]
    return events, {
        "mode": "rom_presenter_json_plus_verified_title_stop",
        "presenter_event_json": str(path),
        "presenter_ed_count": len(ed_events),
        "title_stop_frame": stop_frame,
        "title_stop_frame_basis": "explicit caller input; compared with capture oracle",
        "title_stop_rom_bytes_verified": True,
    }


def play_routine() -> bytes:
    """Check one script command, execute the original driver, count NTSC ticks."""
    # $6000-$6002 are NSF-only counters. The game's original $0000-$07FF RAM
    # remains exclusively controlled by the copied sound engine.
    code = bytearray.fromhex(
        "AE 02 60"       # LDX $6002 ; event-table byte index
        "AD 00 60"       # LDA $6000 ; frame low
        "DD 00 E2"       # CMP $E200,X
        "D0 00"          # BNE driver (patched below)
        "AD 01 60"       # LDA $6001 ; frame high
        "DD 01 E2"       # CMP $E201,X
        "D0 00"          # BNE driver (patched below)
        "BD 02 E2"       # LDA $E202,X ; sound ID
        "C9 FE"          # CMP #$FE ; NSF-only cold-start APU setup marker
        "D0 00"          # BNE queue_sound
        "8A 48"          # TXA; PHA (setup delay clobbers X)
        "20 00 E3"       # JSR $E300 ; original-byte setup sequence at ROM-aligned cycle
        "68 AA"          # PLA; TAX
        "4C 00 00"       # JMP event_consumed
        "8D 00 07"       # queue_sound: STA $0700 ; original incoming queue
        "8A 18 69 03"    # TXA; CLC; ADC #3
        "8D 02 60"       # STA $6002
        "20 00 80"       # driver: JSR $8000
        "EE 00 60"       # INC $6000
        "D0 03"          # BNE done
        "EE 01 60"       # INC $6001
        "60"             # done: RTS
    )
    # The non-setup path skips TXA/PHA/JSR/PLA/TAX/JMP (10 bytes); the
    # setup path jumps past the three-byte queue store.
    branch_positions = []
    branch_at = 0
    for _ in range(3):
        branch_at = code.index(bytes.fromhex("D0 00"), branch_at)
        branch_positions.append(branch_at)
        branch_at += 2
    queue_label = code.index(bytes.fromhex("8D 00 07"))
    driver_label = code.index(bytes.fromhex("20 00 80"))
    for position in branch_positions[:2]:
        code[position + 1] = driver_label - (position + 2)
    code[branch_positions[2] + 1] = queue_label - (branch_positions[2] + 2)
    jump_at = code.index(bytes.fromhex("4C 00 00"))
    event_consumed = queue_label + 3
    event_consumed_cpu = PLAY_CPU_ADDRESS + event_consumed
    code[jump_at + 1] = event_consumed_cpu & 0xFF
    code[jump_at + 2] = event_consumed_cpu >> 8
    return bytes(code)


def apu_setup_routine(extra_delay_cycles: int = 0) -> bytes:
    """Wait, apply source-cycle compensation, then execute the ROM setup bytes verbatim."""
    if extra_delay_cycles < 0 or extra_delay_cycles % 2:
        raise ValueError("APU setup extra delay must be a nonnegative even number of CPU cycles")
    # PLAY call 2 begins at NSF cycle 89,340. Its event-table dispatch prefix,
    # the JSR, and this 21,471-cycle delay place the first $4010 bus write at
    # cycle 110,854 before source-cycle compensation. The source trace measures
    # that write at 111,988; 567 two-cycle NOPs move both ROM writes by 1,134
    # cycles while leaving the copied setup bytes unchanged.
    # The loops consume 20,497 + 956 cycles; four BIT zp instructions add 12.
    delay = bytes.fromhex(
        "A0 10"          # LDY #16
        "A2 FF"          # outer: LDX #255
        "CA"             # inner: DEX
        "D0 FD"          # BNE inner
        "88"             # DEY
        "D0 F8"          # BNE outer
        "A2 BF"          # LDX #191
        "CA"             # fine: DEX
        "D0 FD"          # BNE fine
        "24 00 24 00 24 00 24 00"  # four BIT $00 (12 cycles)
    )
    # Two-cycle 6502 NOPs compensate the measured source-cycle offset without
    # changing the original setup bytes or any event-table frame/ID.
    return delay + (b"\xEA" * (extra_delay_cycles // 2)) + APU_SETUP_ROM_BYTES + b"\x60"


def bank_trampoline() -> bytes:
    """Replace MMC3 8 KiB bank switching with both NSF 4 KiB page writes."""
    # Original STY $8001 neither alters A nor status flags. Preserve both.
    return bytes.fromhex(
        "08 48"          # PHP; PHA
        "98 0A"          # TYA; ASL A (8 KiB source bank -> NSF 4 KiB page)
        "8D FA 5F"       # STA $5FFA ($A000-$AFFF)
        "18 69 01"       # CLC; ADC #1
        "8D FB 5F"       # STA $5FFB ($B000-$BFFF)
        "68 28 60"       # PLA; PLP; RTS
    )


def build(output: Path, presenter_event_json: Path | None = None,
          title_stop_frame: int | None = None,
          startup_phase_frames: int = NSF_STARTUP_PHASE_FRAMES,
          setup_extra_delay_cycles: int = APU_SETUP_DEFAULT_EXTRA_DELAY_CYCLES) -> dict:
    if not 0 <= startup_phase_frames <= 0xFF:
        raise ValueError("NSF startup phase must fit in one byte")
    if setup_extra_delay_cycles < 0 or setup_extra_delay_cycles % 2:
        raise ValueError("APU setup extra delay must be a nonnegative even number of CPU cycles")
    rom = ROM.read_bytes()
    digest = hashlib.sha256(rom).hexdigest()
    if digest != EXPECTED_SHA256:
        raise ValueError(f"Unexpected supplied ROM SHA-256: {digest}")
    if len(rom) < ROM_PRG_START + PRG_SIZE:
        raise ValueError("Supplied PRG is shorter than the expected 32 banks")

    event_details = EVENT_DETAILS
    event_derivation = EVENT_DERIVATION
    if presenter_event_json is not None:
        if title_stop_frame is None:
            raise ValueError("Presenter JSON mode requires an explicit title Stop frame")
        event_details, source_info = _presenter_events_from_json(
            presenter_event_json, title_stop_frame, rom)
        capture_signature = _event_signature(EVENT_DETAILS)
        source_signature = _event_signature(event_details)
        if source_signature != capture_signature:
            raise ValueError(
                "Presenter JSON plus title Stop does not match the capture oracle: "
                f"source={source_signature!r} capture={capture_signature!r}"
            )
        event_derivation = {
            **source_info,
            "capture_validation_oracle": "FCEUX RAM $0700 event list from derive_events()",
            "capture_validation_exact": True,
            "capture_validation_event_count": len(capture_signature),
            "capture_validation_limitation": (
                "The presenter still includes documented timing anchors; exact event-list agreement "
                "does not establish full source-scheduler independence."
            ),
        }
    events = [(int(event["frame"]), int(event["sound_id"])) for event in event_details]
    # Keep the synthetic ROM-byte APU initialization at the same NSF PLAY
    # index when testing a different cue counter seed. It is independent of
    # the ROM-presenter cue phase and must not drift with that experiment.
    apu_setup_event = (
        startup_phase_frames + APU_SETUP_PLAY_INDEX,
        APU_SETUP_EVENT[1],
    )
    nsf_events = (apu_setup_event,) + tuple(events)

    prg = bytearray(rom[ROM_PRG_START:ROM_PRG_START + PRG_SIZE])
    patch_record = []
    for cpu in ROM_DRIVER_BANK_WRITES:
        at = DRIVER_ROM_OFFSET - ROM_PRG_START + cpu - 0x8000
        old = bytes(prg[at:at + 3])
        if old != bytes.fromhex("8C 01 80"):
            raise ValueError(f"Unexpected original MMC3 bank write at ${cpu:04X}")
        prg[at:at + 3] = bytes([0x20, BANK_TRAMPOLINE & 0xFF, BANK_TRAMPOLINE >> 8])
        patch_record.append({
            "cpu_address": f"0x{cpu:04X}",
            "rom_file_offset": f"0x{ROM_PRG_START + at:06X}",
            "original_hex": old.hex(),
            "offline_nsf_hex": bytes(prg[at:at + 3]).hex(),
        })

    wrapper = bytearray(0x2000)
    init = bytearray(make_wrapper(0x00)[:0x28])
    # FCEUX enters NSF INIT through its NMI stub with a live 6502 return frame
    # on page $0100. The generic wrapper's blanket clear clobbers that frame,
    # returning into $0000 before the first scheduled cue. Keep the stack page
    # intact; the NSF loader already initializes its RAM and the original
    # driver itself owns its working memory.
    init[6:9] = b"\xEA\xEA\xEA"  # replace only STA $0100,X with three NOPs
    # Original make_wrapper clears the $0000-$07FF sound RAM, enables APU
    # channels, and queues its track. Here its queued zero means silence.
    # Keep the legacy cue-counter seed as the default; explicit diagnostic
    # builds can supply the ROM/NMI-derived seed 1. The separate synthetic
    # APU-setup marker below is shifted so its setup still runs on PLAY index 2.
    init += bytes([0xA9, startup_phase_frames]) + bytes.fromhex(
        "8D 00 60 A9 00 8D 01 60 A9 00 8D 02 60 60"
    )
    if len(init) > PLAY_CPU_ADDRESS - WRAPPER_CPU_START:
        raise ValueError("INIT overlaps PLAY")
    source_setup_offset = ROM_PRG_START + APU_SETUP_ROM_BANK * 0x2000 + (APU_SETUP_ROM_CPU_START - 0xC000)
    if rom[source_setup_offset:source_setup_offset + len(APU_SETUP_ROM_BYTES)] != APU_SETUP_ROM_BYTES:
        raise ValueError("Cold-start APU setup bytes no longer match the supplied ROM")
    wrapper[:len(init)] = init
    play = play_routine()
    wrapper[PLAY_CPU_ADDRESS - WRAPPER_CPU_START:PLAY_CPU_ADDRESS - WRAPPER_CPU_START + len(play)] = play
    setup = apu_setup_routine(setup_extra_delay_cycles)
    wrapper[APU_SETUP_ROUTINE - WRAPPER_CPU_START:APU_SETUP_ROUTINE - WRAPPER_CPU_START + len(setup)] = setup
    trampoline = bank_trampoline()
    wrapper[BANK_TRAMPOLINE - WRAPPER_CPU_START:BANK_TRAMPOLINE - WRAPPER_CPU_START + len(trampoline)] = trampoline
    at = EVENT_TABLE - WRAPPER_CPU_START
    for frame, sound_id in nsf_events:
        wrapper[at:at + 3] = bytes([frame & 0xFF, frame >> 8, sound_id])
        at += 3
    # Sentinel avoids an accidental second event after the final script cue.
    wrapper[at:at + 3] = bytes([0xFF, 0xFF, 0x00])

    header = bytearray(0x80)
    header[:5] = b"NESM\x1A"
    header[5:8] = bytes([1, 1, 1])
    header[8:14] = bytes([0x00, 0x80, 0x00, 0xE0, 0x40, 0xE0])
    header[14:46] = b"CT2 Turkish opening timeline".ljust(32, b"\0")
    header[46:78] = b"Original ROM sound driver".ljust(32, b"\0")
    header[78:110] = b"ROM bytes; observed cue timing".ljust(32, b"\0")
    header[110:112] = (16639).to_bytes(2, "little")
    header[112:120] = bytes([24, 25, 30, 31, 60, 61, WRAPPER_PAGE, WRAPPER_PAGE + 1])
    header[120:122] = (19997).to_bytes(2, "little")
    header[122] = 0  # NTSC

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(header + prg + wrapper)
    if startup_phase_frames == 1:
        startup_phase_basis = (
            "ROM-derived source-phase candidate: an $ED request dispatched in source frame F is "
            "consumed by the next NMI in F+1; the first source NMI frame 9 aligns with NSF PLAY "
            "index 7, so event F maps to PLAY index F-1. This phase is separate from the "
            "presenter event-frame model and the captured event-list validation oracle."
        )
    elif startup_phase_frames == NSF_STARTUP_PHASE_FRAMES:
        startup_phase_basis = (
            "Legacy default retained for comparison: seed event counter by +3. The ROM/NMI "
            "source-phase audit identifies seed 1 as the source-derived candidate."
        )
    else:
        startup_phase_basis = (
            "Explicit diagnostic counter seed supplied by the caller; no source-phase claim."
        )
    info = {
        "source_rom_sha256": digest,
        "prg_source_file_offset": "0x000010",
        "prg_size_bytes": PRG_SIZE,
        "driver_source_file_offset": "0x018010",
        "event_frame_basis": (
            "FCEUX RAM $0700 capture is the default event source; presenter JSON mode uses "
            "ROM-presenter $ED events plus a separately byte-verified $8048 Stop, then "
            "compares the ordered event list against the FCEUX list as a validation oracle."
        ),
        "event_derivation": event_derivation,
        "observed_events": event_details,
        "bank_switch_patches": patch_record,
        "bank_switch_note": "Original STY $8001 writes are replaced by JSR $E100. The wrapper maps the selected original 8 KiB PRG bank to two NSF 4 KiB slots at $A000 and $B000; A and processor flags are preserved. All source PRG bytes are otherwise copied unchanged.",
        "fixed_nsf_pages": {"$8000": [24, 25], "$C000": [60, 61], "$E000": [WRAPPER_PAGE, WRAPPER_PAGE + 1]},
        "nsf_sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        "runtime_dependency": False,
        "captured_audio_used": False,
        "nsf_startup_phase_frames": startup_phase_frames,
        "nsf_startup_phase_basis": startup_phase_basis,
        "cold_start_apu_setup": {
            "source_cpu_range": f"${APU_SETUP_ROM_CPU_START:04X}-${APU_SETUP_ROM_CPU_START + len(APU_SETUP_ROM_BYTES) - 1:04X}",
            "source_file_offset": f"0x{source_setup_offset:06X}",
            "source_prg_bank": f"${APU_SETUP_ROM_BANK:02X}",
            "rom_bytes": APU_SETUP_ROM_BYTES.hex(" ").upper(),
            "live_writes": [
                {"pc": "$C68A", "address": "$4010", "value": "$00", "fceux_cycle": APU_SETUP_FCEUX_CYCLES[0]},
                {"pc": "$C68F", "address": "$4017", "value": "$40", "fceux_cycle": APU_SETUP_FCEUX_CYCLES[1]},
            ],
            "nsf_unadjusted_cycles": list(APU_SETUP_NSF_CYCLES),
            "nsf_source_cycles": [cycle + setup_extra_delay_cycles for cycle in APU_SETUP_NSF_CYCLES],
            "source_fceux_callback_cycles": list(APU_SETUP_FCEUX_CYCLES),
            "extra_delay_cycles": setup_extra_delay_cycles,
            "extra_delay_encoding": f"{setup_extra_delay_cycles // 2} two-cycle 6502 NOP bytes ($EA) before the ROM setup sequence",
            "timing_basis": (
                "The ROM setup bytes at $C685 are scheduled in NSF PLAY call 2. "
                "A quiet FCEUX source-cycle trace records $4010/$4017 callbacks at "
                "111988/111994; the unadjusted NSF wrapper placed them at 110854/110860. "
                "The source-trace-verified 1134-cycle correction is 567 two-cycle NOPs "
                "before the byte-copied ROM sequence. A diagnostic candidate matched both "
                "callback cycles while the event list and all other APU/PLAY/DMC trace rows "
                "were unchanged. This does not verify PCM."
            ),
            "source_cycle_evidence": "reference/diagnostics/audio/apu_setup_cycle_alignment_20261026.md",
            "pcm_equivalence_verified": False,
            "wrapper_event_marker": {"frame": apu_setup_event[0], "id": f"0x{apu_setup_event[1]:02X}", "runtime_game_cue": False, "play_index": APU_SETUP_PLAY_INDEX},
        },
    }
    output.with_suffix(".json").write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
    return info


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="Output NSF path (use a diagnostic path for candidates).")
    parser.add_argument("--presenter-event-json", type=Path,
                        help="Use source-presenter JSON for $ED events; requires --title-stop-frame.")
    parser.add_argument("--title-stop-frame", type=int,
                        help="Explicit source frame for the separately byte-verified $8048 Stop.")
    parser.add_argument("--startup-phase-frames", type=int, default=NSF_STARTUP_PHASE_FRAMES,
                        help="NSF wrapper event-counter seed (diagnostic candidates can use 1 from the ROM/NMI phase derivation).")
    parser.add_argument("--setup-extra-delay-cycles", type=int, default=APU_SETUP_DEFAULT_EXTRA_DELAY_CYCLES,
                        help="Even CPU-cycle delay before ROM $C685 setup bytes (default 1,134 source-trace-verified cycles; set 0 for baseline diagnostics).")
    args = parser.parse_args()
    default_output = ROOT / "tools/audio/build/opening_timeline_rom_driver.nsf"
    if args.presenter_event_json is not None:
        if args.output is None or args.title_stop_frame is None:
            parser.error("presenter JSON mode requires --output and --title-stop-frame")
        if args.output.resolve() == default_output.resolve():
            parser.error("presenter JSON mode must write to a diagnostic candidate path")
    elif args.title_stop_frame is not None:
        parser.error("--title-stop-frame is only valid with --presenter-event-json")
    dest = args.output or default_output
    info = build(dest, args.presenter_event_json, args.title_stop_frame,
                 args.startup_phase_frames, args.setup_extra_delay_cycles)
    print(f"{dest} event_source={info['event_derivation'].get('mode', 'fceux_ram_0700_default')}")

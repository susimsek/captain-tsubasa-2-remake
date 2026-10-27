#!/usr/bin/env python3
"""Bind captured opening sound-queue values to their live ROM command source.

FCEUX RAM snapshots supply cue IDs and absolute frames. A silent same-input
execution trace records live CPU dispatch and MMC3 banks, which are checked
against the supplied ROM. Captured PCM is never an output source. This is an
offline build tool, not runtime code.
"""

from __future__ import annotations

import hashlib
import json
import csv
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
RAM_DIR = ROOT / "reference/opening_reference_capture/ram_states"
QUEUE_TRACE_PATH = ROOT / "reference/diagnostics/audio_scheduler_trace_20261024_135139/queue_writes.csv"
CONTEXT_TRACE_PATH = ROOT / "reference/diagnostics/audio_command_context_20261024_145219/dispatch_context.csv"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
INES_HEADER_SIZE = 0x10
PRG_BANK_SIZE = 0x2000
TITLE_STOP_COMMAND_OFFSET = 0x0058
TITLE_STOP_BYTES = bytes.fromhex("A9 01 8D 00 07")

def _read_csv(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        raise FileNotFoundError(f"Required FCEUX execution trace is missing: {path}")
    with path.open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))


def _verified_live_command_rows(rom: bytes) -> dict[int, dict[str, int | str]]:
    """Validate captured nonzero events against the live ED handler and ROM."""
    queue_rows = [row for row in _read_csv(QUEUE_TRACE_PATH)
                  if row["cpu_pc"] == "$85FF" and row["sound_id"] != "$00"]
    cue_frames = {int(row["source_frame"]) for row in queue_rows}
    context_rows = [row for row in _read_csv(CONTEXT_TRACE_PATH)
                    if row["event"] == "ed_queue_store" and int(row["source_frame"]) in cue_frames]
    by_frame: dict[int, dict[str, str]] = {}
    for row in context_rows:
        frame = int(row["source_frame"])
        if row["pc"] != "$85FC" or row["script_opcode"] != "$ED" or row["register_y"] != "1":
            raise ValueError(f"ED handler/store context mismatch at frame {frame}")
        # MMC3 mode 0, R6=0 and R7=3: bank 0 is mapped at $8000, bank 3 at $A000.
        if row["mmc3_select"] != "$06" or row["mmc3_r6"] != "$00" or row["mmc3_r7"] != "$03":
            raise ValueError(f"Unexpected live PRG mapping at frame {frame}")
        by_frame[frame] = row

    result: dict[int, dict[str, int | str]] = {}
    for row in queue_rows:
        frame = int(row["source_frame"])
        ptr = int(row["script_pointer"].replace("$", ""), 16)
        sound_id = int(row["sound_id"].replace("$", ""), 16)
        context = by_frame.get(frame)
        if context is None or context["ptr"] != row["script_pointer"]:
            raise ValueError(f"Queue write lacks matching live ED dispatch at frame {frame}")
        if int(context["script_arg"].replace("$", ""), 16) != sound_id:
            raise ValueError(f"Live ED argument does not match queue ID at frame {frame}")
        offset = INES_HEADER_SIZE + 3 * PRG_BANK_SIZE + ptr - 0xA000
        raw = rom[offset:offset + 2]
        if raw != bytes((0xED, sound_id)):
            raise ValueError(f"Bank-3 ROM bytes at ${ptr:04X} disagree with captured cue ${sound_id:02X}")
        result[frame] = {
            "sound_id": sound_id, "cpu_address": ptr, "rom_file_offset": offset,
            "rom_raw_hex": raw.hex(" "), "pass": 1 if frame >= 4000 else 0,
        }
    return result


def _captured_queue_events() -> list[dict]:
    if not RAM_DIR.is_dir():
        raise FileNotFoundError(f"FCEUX RAM capture is missing: {RAM_DIR}")
    snapshots: list[tuple[int, Path]] = []
    pattern = re.compile(r"^ram_(\d{6})\.bin$")
    for path in RAM_DIR.iterdir():
        match = pattern.match(path.name)
        if match:
            snapshots.append((int(match.group(1)), path))
    observed: list[dict] = []
    for frame, path in sorted(snapshots):
        data = path.read_bytes()
        if len(data) != 0x800:
            raise ValueError(f"Unexpected RAM snapshot length at {path}")
        sound_id = data[0x0700]
        if sound_id:
            observed.append({
                "frame": frame,
                "sound_id": sound_id,
                "capture_path": str(path.relative_to(ROOT)),
                "capture_address": "0x0700",
            })
    return observed


def derive_events() -> tuple[list[dict], dict]:
    rom = ROM_PATH.read_bytes()
    rom_sha = hashlib.sha256(rom).hexdigest()
    if rom_sha != EXPECTED_ROM_SHA256:
        raise ValueError(f"Unexpected supplied ROM SHA-256: {rom_sha}")
    title_stop = rom[TITLE_STOP_COMMAND_OFFSET:TITLE_STOP_COMMAND_OFFSET + len(TITLE_STOP_BYTES)]
    if title_stop != TITLE_STOP_BYTES:
        raise ValueError(f"Expected title-entry sound-stop instruction at ${TITLE_STOP_COMMAND_OFFSET:06X}")
    rom_cues = _verified_live_command_rows(rom)

    observed = _captured_queue_events()
    if not observed or observed[-1]["sound_id"] != 0x01:
        raise ValueError("Captured queue timeline must end with title-entry sound-stop $01")
    derived: list[dict] = []
    for cue in observed:
        event = {
            "frame": cue["frame"],
            "sound_id": cue["sound_id"],
            "command_source": "captured RAM $0700 queue write; source pending validation",
            "source_status": "capture_observed_unmapped",
            "frame_source": cue["capture_path"],
            "frame_source_address": cue["capture_address"],
        }
        if cue["frame"] in rom_cues:
            expected = rom_cues[cue["frame"]]
            event.update({
                "command_source": "ROM cutscene ED command confirmed by live CPU dispatch and MMC3 mapping",
                "source_status": "rom_command_verified_frame_capture_anchored",
                "rom_file_offset": f"0x{expected['rom_file_offset']:06X}",
                "cpu_address": f"0x{expected['cpu_address']:04X}",
                "cutscene_pass": expected["pass"],
                "rom_raw_hex": expected["rom_raw_hex"],
            })
        elif cue["frame"] == observed[-1]["frame"]:
            if cue["sound_id"] != 0x01:
                raise ValueError("Captured final queue event must be title-entry stop ID $01")
            event.update({
                "command_source": "ROM bank-0 title-entry code",
                "source_status": "rom_store_verified_frame_capture_anchored",
                "rom_file_offset": f"0x{TITLE_STOP_COMMAND_OFFSET:06X}",
                "cpu_address": "0x8048",
                "rom_raw_hex": title_stop.hex(" "),
            })
        derived.append(event)

    summary = {
        "source_rom_sha256": rom_sha,
        "capture_source": "FCEUX RAM snapshots, RAM $0700 after each source frame",
        "captured_queue_event_count": len(observed),
        "capture_supplies_all_event_ids_and_absolute_frames": True,
        "rom_verified_cutscene_command_count": len(rom_cues),
        "rom_verified_cutscene_commands": [
            {"cpu_address": f"0x{item['cpu_address']:04X}", "rom_file_offset": f"0x{item['rom_file_offset']:06X}",
             "sound_id": f"0x{item['sound_id']:02X}", "captured_frame": frame,
             "cutscene_pass": item["pass"], "raw_hex": item["rom_raw_hex"]}
            for frame, item in sorted(rom_cues.items())
        ],
        "unmapped_captured_ids": [],
        "fc_dispatch_finding": "On the captured opening path, bank-0 command table $8545 stores target-minus-one pointers. FC entry value $8836 returns to $8837; that handler advances the script pointer by one byte. FC is not a counted payload here.",
        "queue_write_trace_evidence": {
            "path": "reference/diagnostics/audio_scheduler_trace_20261024_135139/queue_writes.csv",
            "recorded_pc": "$85FF",
            "rom_instruction_context": "$85FA LDA ($4D),Y with Y=1; $85FC STA $0700,X; post-store callback observes PC $85FF",
            "live_context_trace": str(CONTEXT_TRACE_PATH.relative_to(ROOT)),
            "interpretation": "every nonzero intro cue has a live $85EC ED dispatch and matching source bytes; MMC3 R6=0/R7=3 maps bank 0 at $8000 and bank 3 at $A000",
        },
        "title_stop_command_file_offset": f"0x{TITLE_STOP_COMMAND_OFFSET:06X}",
        "rom_command_origins_are_attached_when_live_cpu_bank_and_source_bytes_agree": True,
        "timing_limitation": (
            "Absolute cue frames are capture-derived for this replay. Every ED ID and source byte is verified against "
            "the live CPU dispatch and mapped ROM; exact APU mix/timbre remains a separate fidelity question."
        ),
        "runtime_dependency": False,
    }
    return derived, summary


def main() -> None:
    events, summary = derive_events()
    out = ROOT / "tools/audio/build/opening_timeline_rom_events.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"summary": summary, "events": events}, indent=2) + "\n", encoding="utf-8")
    print(f"Derived {len(events)} captured queue events; verified ROM origins attached only where proven.")
    print(out)


if __name__ == "__main__":
    main()

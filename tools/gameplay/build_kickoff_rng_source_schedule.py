#!/usr/bin/env python3
"""Build the audited KICK OFF RNG replay schedule from the supplied ROM.

The input trace is an explicit behavioral route, not a RAM seed. The produced
schedule comes from executing ROM instructions in the existing source stepper;
retained FCEUX RAM dumps are intentionally not read by this builder.
"""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import io
import json
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OPENING_INPUT = ROOT / "reference/diagnostics/kickoff_select_test_20261027/opening_replay.csv"
POST_TITLE_INPUT = ROOT / "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
STEPPER_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
OUTPUT = ROOT / "assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_INPUT_SHA256 = "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
MAX_SOURCE_FRAME = 9042


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _load_stepper():
    spec = importlib.util.spec_from_file_location("ct2_source_stepper", STEPPER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot import source stepper: {STEPPER_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _read_route_inputs() -> tuple[list[dict[str, str]], bytes]:
    rows: list[dict[str, str]] = []
    for path in (OPENING_INPUT, POST_TITLE_INPUT):
        with path.open(newline="", encoding="utf-8") as stream:
            for source in csv.DictReader(stream):
                rows.append({
                    "frame": source["source_frame"],
                    "up": source.get("up", "0"),
                    "down": source.get("down", "0"),
                    "left": source.get("left", "0"),
                    "right": source.get("right", "0"),
                    "A": source["A"],
                    "B": source["B"],
                    "start": source["Start"],
                    "select": source.get("Select", "0"),
                })
    expected_frames = list(range(MAX_SOURCE_FRAME + 1))
    actual_frames = [int(row["frame"]) for row in rows]
    if actual_frames != expected_frames:
        raise RuntimeError("Retained input components are not one contiguous 0..9042 route.")

    stream = io.StringIO(newline="")
    writer = csv.DictWriter(
        stream,
        fieldnames=("frame", "up", "down", "left", "right", "A", "B", "start", "select"),
    )
    writer.writeheader()
    writer.writerows(rows)
    return rows, stream.getvalue().encode("utf-8")


def _compress_frames(frames: list[int]) -> list[list[int]]:
    runs: list[list[int]] = []
    for frame in frames:
        if not runs or frame > runs[-1][1] + 1:
            runs.append([frame, frame])
        else:
            runs[-1][1] = frame
    return runs


def main() -> None:
    stepper = _load_stepper()
    rom = stepper.ROM_PATH.read_bytes()
    if sha256(rom) != EXPECTED_ROM_SHA256:
        raise SystemExit("The supplied ROM hash differs from the audited Turkish revision.")

    input_rows, input_bytes = _read_route_inputs()
    input_sha = sha256(input_bytes)
    if input_sha != EXPECTED_INPUT_SHA256:
        raise SystemExit(f"Input route hash mismatch: {input_sha}")

    class RngTraceMachine(stepper.Machine):
        def __init__(self, *args, **kwargs):
            self.a117_updates: list[dict] = []
            self.c9c5_updates: list[dict] = []
            self.receiver_selection: dict | None = None
            super().__init__(*args, **kwargs)

        def __setitem__(self, addr: int, value: int) -> None:
            addr &= 0xFFFF
            value &= 0xFF
            pc = self.current_instruction_pc
            bank = self._prg_bank(pc)
            super().__setitem__(addr, value)

            if addr >= 0x2000:
                return
            ram_addr = addr & 0x7FF
            state = (self.ram[0xE1], self.ram[0xE2], self.ram[0xE3])
            if ram_addr == 0xE3 and pc == 0xA127 and bank == 2:
                self.a117_updates.append({
                    "source_frame": self.source_frame,
                    "source_cycle": self.cpu_cycles,
                    "state_after": list(state),
                })
            elif ram_addr == 0xE1 and pc == 0xC9E5 and bank == 30:
                self.c9c5_updates.append({
                    "source_frame": self.source_frame,
                    "source_cycle": self.cpu_cycles,
                    "state_after": list(state),
                })
            elif ram_addr == 0x05FC and pc == 0xDB08 and bank == 30:
                self.receiver_selection = {
                    "source_frame": self.source_frame,
                    "source_cycle": self.cpu_cycles,
                    "e1": state[0],
                    "e2": state[1],
                    "e3": state[2],
                    "slot": self.ram[0x05FC],
                }

    with tempfile.NamedTemporaryFile("w", newline="", encoding="utf-8") as input_stream:
        input_stream.write(input_bytes.decode("utf-8"))
        input_stream.flush()
        input_timeline = stepper.load_input_timeline(Path(input_stream.name))

    machine = RngTraceMachine(rom, input_timeline)
    for source_frame in range(1, MAX_SOURCE_FRAME + 1):
        machine.run_frame(source_frame)
        if machine.receiver_selection is not None:
            break
    if machine.receiver_selection is None:
        raise SystemExit("The source model did not reach the receiver store in this route.")

    a117_frames = [int(row["source_frame"]) for row in machine.a117_updates]
    c9_updates = machine.c9c5_updates
    receiver = machine.receiver_selection
    if len(a117_frames) != 8446 or len(c9_updates) != 133:
        raise SystemExit(
            f"Unexpected source update counts: A117={len(a117_frames)}, C9C5={len(c9_updates)}"
        )
    if (receiver["source_frame"], receiver["e2"], receiver["slot"]) != (8593, 0xBE, 0x06):
        raise SystemExit(f"Unexpected receiver selection from source execution: {receiver}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    document = {
        "schema": "ct2-kickoff-rom-rng-replay-v1",
        "route_identity": "turkish-fresh-kickoff-capture-20261027",
        "source_rom_sha256": EXPECTED_ROM_SHA256,
        "source_stepper_sha256": sha256(STEPPER_PATH.read_bytes()),
        "cold_reset_state": {
            "e1": 0,
            "e2": 0,
            "e3": 0,
            "basis": "ROM reset path $FFF0->$C503->$C64E clears $0000-$07FF",
        },
        "input_route": {
            "sha256": input_sha,
            "first_source_frame": 0,
            "last_source_frame": MAX_SOURCE_FRAME,
            "source_files": [
                OPENING_INPUT.relative_to(ROOT).as_posix(),
                POST_TITLE_INPUT.relative_to(ROOT).as_posix(),
            ],
            "meaning": "Recorded P1 input sequence used as the ROM-stepper route; runtime must bind this exact identity.",
        },
        "source_model": {
            "name": "ROM-only 6502/PPU/DMC source stepper",
            "stepper": STEPPER_PATH.relative_to(ROOT).as_posix(),
            "target_ram_dumps_used_as_inputs": False,
            "time_quantization": "Events are applied in source-frame order. Sub-frame cycles are preserved for audit but not used by the Godot helper.",
        },
        "updates": {
            "a117": {
                "count": len(a117_frames),
                "frame_runs_inclusive": _compress_frames(a117_frames),
                "operation": "E1+=83; E2+=0D+carry(E1); E3+=11+carry(E2), modulo 256",
                "source": "bank $02 $A117-$A128, reached via $C76E->$C421->$A000 when $001B bit 6 is set",
            },
            "c9c5": {
                "count": len(c9_updates),
                "source": "fixed-bank $C9C5-$C9E8, called directly from $C7E4",
                "state_after_each_call": [
                    [row["source_frame"], row["source_cycle"], *row["state_after"]]
                    for row in c9_updates
                ],
                "state_layout": "[source_frame, source_cpu_cycle, E1, E2, E3]",
                "limitation": "Per-call results are ROM-stepper-derived for this fixed input route; the routine's $0300/$0700/$0780 RAM operands are not generalized for arbitrary input histories.",
            },
        },
        "receiver_selection": {
            **receiver,
            "table": [0x05, 0x06, 0x07, 0x09, 0x0A],
            "formula": "i=E2&7; if i>=5 then i-=5; slot=table[i]+$05FB; current match base $05FB is zero",
        },
    }
    OUTPUT.write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")
    print(f"Input SHA-256: {input_sha}")
    print(f"Updates: A117={len(a117_frames)}, C9C5={len(c9_updates)}")
    print(
        "Receiver: frame %d cycle %d E2=$%02X slot=$%02X"
        % (receiver["source_frame"], receiver["source_cycle"], receiver["e2"], receiver["slot"])
    )


if __name__ == "__main__":
    main()

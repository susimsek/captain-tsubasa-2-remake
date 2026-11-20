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
FIRST_PASS_INPUT_EDGES = ROOT / "reference/diagnostics/first_pass_action_input_edges_20261110.csv"
STEPPER_PATH = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc.py"
OUTPUT = ROOT / "assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
PASS_EXTENSION_OUTPUT = ROOT / "assets/gameplay/rom_logic/kickoff_rng_pass_extension.json"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
EXPECTED_INPUT_SHA256 = "92bd6e971ea5c59672fd2a7a4eece18d797c0fb006ea7f427f9b521dcbec42e0"
EXPECTED_BASE_INPUT_SHA256 = "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
EXPECTED_FIRST_PASS_EDGES_SHA256 = "3e522de6924b0fb9ad40ffdd2271a9e4ea62cbe1bf76cc27c6b414b7e87bb6d2"
FIRST_PASS_INPUT_START_FRAME = 9043
BASE_SOURCE_FRAME = 9042
MAX_SOURCE_FRAME = 9600


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
    if [int(row["frame"]) for row in rows] != list(range(FIRST_PASS_INPUT_START_FRAME)):
        raise RuntimeError("Retained base input components are not one contiguous 0..9042 route.")

    edge_bytes = FIRST_PASS_INPUT_EDGES.read_bytes()
    if sha256(edge_bytes) != EXPECTED_FIRST_PASS_EDGES_SHA256:
        raise RuntimeError("First-pass input-edge trace differs from its pinned route evidence.")
    edge_rows: dict[int, dict[str, str]] = {}
    with FIRST_PASS_INPUT_EDGES.open(newline="", encoding="utf-8") as stream:
        for source in csv.DictReader(stream):
            edge_rows[int(source["source_frame"])] = source
    state = {key: rows[-1][key] for key in (
        "up", "down", "left", "right", "A", "B", "start", "select")}
    button_fields = {
        "Left": "left", "Right": "right", "Up": "up", "Down": "down",
        "A": "A", "B": "B", "Start": "start", "Select": "select",
    }
    for source_frame in range(FIRST_PASS_INPUT_START_FRAME, MAX_SOURCE_FRAME + 1):
        edge = edge_rows.get(source_frame)
        if edge is not None:
            button = edge["button"]
            if button not in button_fields:
                raise RuntimeError(f"Unsupported first-pass input button: {button}")
            state[button_fields[button]] = edge["pressed"]
        rows.append({"frame": str(source_frame), **state})

    expected_frames = list(range(MAX_SOURCE_FRAME + 1))
    actual_frames = [int(row["frame"]) for row in rows]
    if actual_frames != expected_frames:
        raise RuntimeError("Retained input components plus first-pass edges are not contiguous through frame 9600.")

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
        raise SystemExit(f"Extended input route hash mismatch: {input_sha}")
    base_input_stream = io.StringIO(newline="")
    base_writer = csv.DictWriter(
        base_input_stream,
        fieldnames=("frame", "up", "down", "left", "right", "A", "B", "start", "select"),
    )
    base_writer.writeheader()
    base_writer.writerows(input_rows[:BASE_SOURCE_FRAME + 1])
    base_input_sha = sha256(base_input_stream.getvalue().encode("utf-8"))
    if base_input_sha != EXPECTED_BASE_INPUT_SHA256:
        raise SystemExit(f"Base input route hash mismatch: {base_input_sha}")

    class RngTraceMachine(stepper.Machine):
        def __init__(self, *args, **kwargs):
            self.a117_updates: list[dict] = []
            self.c9c5_updates: list[dict] = []
            self.counter_003a_writes: list[dict] = []
            self.sound_queue_writer_stats: dict[tuple[int, int, int, int], dict] = {}
            self.mode_001b_writer_stats: dict[tuple[int, int, int], dict] = {}
            self.saved_bank_07fc_writer_stats: dict[tuple[int, int, int], dict] = {}
            self.sound_queue_source_boundary: dict | None = None
            self.current_c9c5_call: dict | None = None
            self.receiver_selection: dict | None = None
            super().__init__(*args, **kwargs)

        def __getitem__(self, addr: int) -> int:
            requested = addr & 0xFFFF
            value = super().__getitem__(addr)
            pc = self.current_instruction_pc
            if self.source_frame == 7266 and pc == 0xC421 and requested == 0xC421 \
                    and self.sound_queue_source_boundary is None:
                addresses = (0x0700, 0x0701, 0x0702, 0x0703,
                             0x0704, 0x0705, 0x0706, 0x07E9)
                self.sound_queue_source_boundary = {
                    "source_frame": self.source_frame,
                    "source_cycle": self.cpu_cycles,
                    "source_pc": pc,
                    "source_event_id": f"rom-source-nmi-{self.source_frame}-{self.cpu_cycles}",
                    "ram_sha256": sha256(bytes(self.ram)),
                    "mode_001b_value": self.ram[0x001B],
                    "saved_bank_07fc_value": self.ram[0x07FC],
                    "values": {f"{address:04X}": self.ram[address]
                               for address in addresses},
                }
            if pc == 0xC9C5 and requested == 0xC9C5:
                self.current_c9c5_call = {
                    "source_frame": self.source_frame,
                    "source_cycle": self.cpu_cycles,
                    "e1_before": self.ram[0x00E1],
                    "e2_before": self.ram[0x00E2],
                    "e3_before": self.ram[0x00E3],
                    "incoming_carry": self.cpu.p & 1,
                    "operands": {},
                }
            for instruction_pc, label in (
                (0xC9C8, "0300_x"),
                (0xC9CB, "0700_x"),
                (0xC9DC, "0780_x"),
            ):
                if pc == instruction_pc and self.current_c9c5_call is not None:
                    self.current_c9c5_call["operands"][label] = {
                        "x": self.cpu.x,
                        "cpu_address": requested,
                        "value": value,
                    }
            return value

        def __setitem__(self, addr: int, value: int) -> None:
            addr &= 0xFFFF
            value &= 0xFF
            pc = self.current_instruction_pc
            bank = self._prg_bank(pc)
            super().__setitem__(addr, value)

            if addr >= 0x2000:
                return
            ram_addr = addr & 0x7FF
            if ram_addr == 0x003A:
                self.counter_003a_writes.append({
                    "source_frame": self.source_frame,
                    "source_cycle": self.cpu_cycles,
                    "source_pc": pc,
                    "prg_bank": bank,
                    "address": ram_addr,
                    "value": self.ram[ram_addr],
                })
            if ram_addr == 0x001B and self.sound_queue_source_boundary is None:
                value_after_write = self.ram[ram_addr]
                key = (pc, bank, value_after_write)
                stats = self.mode_001b_writer_stats.get(key)
                if stats is None:
                    self.mode_001b_writer_stats[key] = {
                        "count": 1,
                        "first_source_frame": self.source_frame,
                        "first_source_cycle": self.cpu_cycles,
                        "last_source_frame": self.source_frame,
                        "last_source_cycle": self.cpu_cycles,
                    }
                else:
                    stats["count"] += 1
                    stats["last_source_frame"] = self.source_frame
                    stats["last_source_cycle"] = self.cpu_cycles
            if ram_addr == 0x07FC and self.sound_queue_source_boundary is None:
                value_after_write = self.ram[ram_addr]
                key = (pc, bank, value_after_write)
                stats = self.saved_bank_07fc_writer_stats.get(key)
                if stats is None:
                    self.saved_bank_07fc_writer_stats[key] = {
                        "count": 1,
                        "first_source_frame": self.source_frame,
                        "first_source_cycle": self.cpu_cycles,
                        "last_source_frame": self.source_frame,
                        "last_source_cycle": self.cpu_cycles,
                    }
                else:
                    stats["count"] += 1
                    stats["last_source_frame"] = self.source_frame
                    stats["last_source_cycle"] = self.cpu_cycles
            if ram_addr in (0x0700, 0x0701, 0x0702, 0x0703,
                            0x0704, 0x0705, 0x0706, 0x07E9):
                if self.sound_queue_source_boundary is None:
                    value_after_write = self.ram[ram_addr]
                    key = (ram_addr, pc, bank, value_after_write)
                    stats = self.sound_queue_writer_stats.get(key)
                    if stats is None:
                        self.sound_queue_writer_stats[key] = {
                            "count": 1,
                            "first_source_frame": self.source_frame,
                            "first_source_cycle": self.cpu_cycles,
                            "last_source_frame": self.source_frame,
                            "last_source_cycle": self.cpu_cycles,
                        }
                    else:
                        stats["count"] += 1
                        stats["last_source_frame"] = self.source_frame
                        stats["last_source_cycle"] = self.cpu_cycles
            state = (self.ram[0xE1], self.ram[0xE2], self.ram[0xE3])
            if ram_addr == 0xE3 and pc == 0xA127 and bank == 2:
                self.a117_updates.append({
                    "source_frame": self.source_frame,
                    "source_cycle": self.cpu_cycles,
                    "state_after": list(state),
                })
            elif ram_addr == 0xE1 and pc == 0xC9E5 and bank == 30:
                row = {
                    "source_frame": self.source_frame,
                    "source_cycle": self.cpu_cycles,
                    "state_after": list(state),
                }
                call = self.current_c9c5_call
                if call is None or len(call["operands"]) != 3:
                    raise RuntimeError("C9C5 source execution did not read all three indexed operands.")
                row["state_before"] = [
                    call["e1_before"], call["e2_before"], call["e3_before"]
                ]
                row["incoming_carry"] = call["incoming_carry"]
                row["operands"] = call["operands"]
                self.c9c5_updates.append(row)
                self.current_c9c5_call = None
            elif ram_addr == 0x05FC and pc == 0xDB08 and bank == 30:
                if self.receiver_selection is None:
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
    if machine.receiver_selection is None:
        raise SystemExit("The source model did not reach the receiver store in this route.")
    sound_queue_boundary = machine.sound_queue_source_boundary
    if sound_queue_boundary is None:
        raise SystemExit("The ROM source model did not reach selector NMI entry $C421.")
    expected_sound_queue_values = {
        "0700": 0, "0701": 0, "0702": 0, "0703": 0,
        "0704": 0, "0705": 0, "0706": 0, "07E9": 0,
    }
    if (int(sound_queue_boundary["source_frame"]) != 7266
            or int(sound_queue_boundary["source_pc"]) != 0xC421
            or sound_queue_boundary["ram_sha256"]
            != "aa95f576dfb1f741e55eb013acbbcb85f71c080550c3c90455cf098a6c59dde0"
            or int(sound_queue_boundary["mode_001b_value"]) != 0xC0
            or int(sound_queue_boundary["saved_bank_07fc_value"]) != 0x0F
            or sound_queue_boundary["values"] != expected_sound_queue_values):
        raise SystemExit(
            "ROM-stepper sound queue inputs at the first $C421 boundary diverged: "
            f"{sound_queue_boundary}"
        )
    sound_queue_writer_summary = [
        {
            "address": address,
            "source_pc": pc,
            "prg_bank": bank,
            "value": value,
            **stats,
        }
        for (address, pc, bank, value), stats in sorted(machine.sound_queue_writer_stats.items())
    ]
    mode_001b_writer_summary = [
        {
            "address": 0x001B,
            "source_pc": pc,
            "prg_bank": bank,
            "value": value,
            **stats,
        }
        for (pc, bank, value), stats in sorted(machine.mode_001b_writer_stats.items())
    ]
    saved_bank_07fc_writer_summary = [
        {
            "address": 0x07FC,
            "source_pc": pc,
            "prg_bank": bank,
            "value": value,
            **stats,
        }
        for (pc, bank, value), stats in sorted(machine.saved_bank_07fc_writer_stats.items())
    ]

    a117_frames = [int(row["source_frame"]) for row in machine.a117_updates]
    candidate_counter_frame = 7266
    pre_candidate_counter_writes = [
        row for row in machine.counter_003a_writes
        if int(row["source_frame"]) < candidate_counter_frame
    ]
    counter_initializers = [
        row for row in pre_candidate_counter_writes
        if (int(row["source_pc"]), int(row["prg_bank"]), int(row["value"]))
        in ((0xC670, 30, 0), (0xA238, 2, 0))
    ]
    counter_increments = [
        row for row in pre_candidate_counter_writes
        if int(row["source_pc"]) == 0xA135 and int(row["prg_bank"]) == 2
    ]
    unexpected_counter_writes = [
        row for row in pre_candidate_counter_writes
        if row not in counter_initializers and row not in counter_increments
    ]
    a117_pre_candidate_frames = [
        frame for frame in a117_frames if frame < candidate_counter_frame
    ]
    counter_increment_frames = [
        int(row["source_frame"]) for row in counter_increments
    ]
    c9_updates = machine.c9c5_updates
    receiver = machine.receiver_selection
    if len(a117_frames) != 8446 or len(c9_updates) < 133 \
            or [int(row["source_frame"]) for row in c9_updates[:133]] != list(range(8461, 8594)):
        raise SystemExit(
            f"Unexpected source update counts: A117={len(a117_frames)}, C9C5={len(c9_updates)}"
        )
    if (receiver["source_frame"], receiver["e2"], receiver["slot"]) != (8593, 0xBE, 0x06):
        raise SystemExit(f"Unexpected receiver selection from source execution: {receiver}")
    expected_initializers = [
        (4, 0xC670, 30, 0),
        (6, 0xA238, 2, 0),
    ]
    observed_initializers = [
        (int(row["source_frame"]), int(row["source_pc"]),
         int(row["prg_bank"]), int(row["value"]))
        for row in counter_initializers
    ]
    if observed_initializers != expected_initializers:
        raise SystemExit(
            f"Unexpected pre-candidate $003A initializers: {observed_initializers}"
        )
    if len(counter_increments) != 7255 \
            or counter_increment_frames != a117_pre_candidate_frames \
            or unexpected_counter_writes:
        raise SystemExit(
            "Pre-candidate $003A writer history did not match ROM A117/A135 execution: "
            f"INC count={len(counter_increments)}, A117 count={len(a117_pre_candidate_frames)}, "
            f"unexpected={unexpected_counter_writes[:4]}"
        )
    counter_value = (int(counter_initializers[-1]["value"]) + len(counter_increments)) & 0xFF

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    document = {
        "schema": "ct2-kickoff-rom-rng-replay-v6",
        "source_schedule_builder_sha256": sha256(Path(__file__).read_bytes()),
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
            "sha256": base_input_sha,
            "first_source_frame": 0,
            "last_source_frame": BASE_SOURCE_FRAME,
            "source_files": [
                OPENING_INPUT.relative_to(ROOT).as_posix(),
                POST_TITLE_INPUT.relative_to(ROOT).as_posix(),
            ],
            "meaning": "Recorded P1 input sequence through the first-match command menu; runtime must bind this exact identity.",
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
            "pre_candidate_counter_003a": {
                "candidate_source_frame": candidate_counter_frame,
                "initialization_writes": [
                    {
                        "source_frame": int(row["source_frame"]),
                        "source_cycle": int(row["source_cycle"]),
                        "source_pc": int(row["source_pc"]),
                        "prg_bank": int(row["prg_bank"]),
                        "address": int(row["address"]),
                        "value": int(row["value"]),
                    }
                    for row in counter_initializers
                ],
                "increment_source_pc": 0xA135,
                "increment_prg_bank": 2,
                "increment_count": len(counter_increments),
                "increment_frame_runs_inclusive": _compress_frames(counter_increment_frames),
                "unexpected_writer_count": len(unexpected_counter_writes),
                "derived_value": counter_value,
                "source": "ROM-stepper RAM writes: reset STA ($00),Y at $C670; bank-$02 zero-fill STA $FFE0,Y first writes $003A at $A238; each listed bank-$02 A117 path falls through to INC $003A at $A135",
            },
            "pre_candidate_sound_queue": {
                "candidate_source_frame": int(sound_queue_boundary["source_frame"]),
                "candidate_source_cycle": int(sound_queue_boundary["source_cycle"]),
                "candidate_source_pc": int(sound_queue_boundary["source_pc"]),
                "source_event_id": str(sound_queue_boundary["source_event_id"]),
                "source_ram_sha256": str(sound_queue_boundary["ram_sha256"]),
                "mode_001b_value": int(sound_queue_boundary["mode_001b_value"]),
                "mode_001b_write_count": sum(
                    int(row["count"]) for row in mode_001b_writer_summary),
                "mode_001b_writer_summary": mode_001b_writer_summary,
                "saved_bank_07fc_value": int(sound_queue_boundary["saved_bank_07fc_value"]),
                "saved_bank_07fc_write_count": sum(
                    int(row["count"]) for row in saved_bank_07fc_writer_summary),
                "saved_bank_07fc_writer_summary": saved_bank_07fc_writer_summary,
                "values": sound_queue_boundary["values"],
                "write_count": sum(int(row["count"]) for row in sound_queue_writer_summary),
                "writer_summary": sound_queue_writer_summary,
                "source": "Observed at the ROM-stepper opcode fetch for selector NMI entry $C421 after reset, route input, queued cutscene tasks, and the preceding sound-driver pass; write history is ROM execution output, not an emulator RAM seed",
            },
            "c9c5": {
                "count": 133,
                "source": "fixed-bank $C9C5-$C9E8, called directly from $C7E4",
                "state_after_each_call": [
                    [row["source_frame"], row["source_cycle"], *row["state_after"]]
                    for row in c9_updates[:133]
                ],
                "state_layout": "[source_frame, source_cpu_cycle, E1, E2, E3]",
                "source_operands_each_call": [
                    [
                        row["source_frame"], row["source_cycle"],
                        *row["state_before"], row["incoming_carry"],
                        row["operands"]["0300_x"]["x"],
                        row["operands"]["0300_x"]["cpu_address"],
                        row["operands"]["0300_x"]["value"],
                        row["operands"]["0700_x"]["x"],
                        row["operands"]["0700_x"]["cpu_address"],
                        row["operands"]["0700_x"]["value"],
                        row["operands"]["0780_x"]["x"],
                        row["operands"]["0780_x"]["cpu_address"],
                        row["operands"]["0780_x"]["value"],
                        *row["state_after"],
                    ]
                    for row in c9_updates[:133]
                ],
                "source_operands_layout": "[frame, commit_cycle, E1_before, E2_before, E3_before, incoming_carry, X0300, address0300, value0300, X0700, address0700, value0700, X0780, address0780, value0780, E1_after, E2_after, E3_after]",
                "source_operands_cycle_basis": "commit_cycle is the source-stepper CPU cycle at the $C9E5 E1 store; the diagnostic read trace separately records each operand-read cycle.",
                "limitation": "Operands and results are ROM-stepper-derived for this fingerprinted input route. The rows are not a generic substitute for live operand writers under arbitrary input histories.",
            },
        },
        "receiver_selection": {
            **receiver,
            "table": [0x05, 0x06, 0x07, 0x09, 0x0A],
            "formula": "i=E2&7; if i>=5 then i-=5; slot=table[i]+$05FB; current match base $05FB is zero",
        },
    }
    base_document_bytes = (json.dumps(document, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
    OUTPUT.write_bytes(base_document_bytes)

    receiver_frame = int(receiver["source_frame"])
    pass_c9_updates = [row for row in c9_updates
                       if int(row["source_frame"]) > receiver_frame]
    pass_a117_frames = [frame for frame in a117_frames if frame > receiver_frame]
    pass_state_after = [
        [row["source_frame"], row["source_cycle"], *row["state_after"]]
        for row in pass_c9_updates
    ]
    pass_operands = [
        [
            row["source_frame"], row["source_cycle"], *row["state_before"],
            row["incoming_carry"],
            row["operands"]["0300_x"]["x"], row["operands"]["0300_x"]["cpu_address"],
            row["operands"]["0300_x"]["value"],
            row["operands"]["0700_x"]["x"], row["operands"]["0700_x"]["cpu_address"],
            row["operands"]["0700_x"]["value"],
            row["operands"]["0780_x"]["x"], row["operands"]["0780_x"]["cpu_address"],
            row["operands"]["0780_x"]["value"], *row["state_after"],
        ]
        for row in pass_c9_updates
    ]
    extension = {
        "schema": "ct2-kickoff-rom-rng-pass-extension-v1",
        "source_schedule_builder_sha256": sha256(Path(__file__).read_bytes()),
        "source_rom_sha256": EXPECTED_ROM_SHA256,
        "source_stepper_sha256": sha256(STEPPER_PATH.read_bytes()),
        "route_identity": "turkish-fresh-kickoff-first-pass-route-20261110",
        "base_schedule_sha256": sha256(base_document_bytes),
        "base_receiver_event": receiver,
        "input_route": {
            "sha256": input_sha,
            "first_source_frame": 0,
            "last_source_frame": MAX_SOURCE_FRAME,
            "source_files": [
                OPENING_INPUT.relative_to(ROOT).as_posix(),
                POST_TITLE_INPUT.relative_to(ROOT).as_posix(),
                FIRST_PASS_INPUT_EDGES.relative_to(ROOT).as_posix(),
            ],
            "meaning": "Recorded P1 route through one PASS to the next command boundary; used only to generate this source-stepped RNG extension.",
        },
        "source_model": {
            "name": "ROM-only 6502/PPU/DMC source stepper",
            "stepper": STEPPER_PATH.relative_to(ROOT).as_posix(),
            "target_ram_dumps_used_as_inputs": False,
            "fceux_ram_or_captures_used_as_inputs": False,
        },
        "start_frame": receiver_frame,
        "start_state": {"e1": receiver["e1"], "e2": receiver["e2"], "e3": receiver["e3"]},
        "updates": {
            "a117_frames": pass_a117_frames,
            "c9c5_count": len(pass_c9_updates),
            "c9c5_state_after_each_call": pass_state_after,
            "c9c5_operands_each_call": pass_operands,
            "c9c5_state_layout": "[source_frame, source_cpu_cycle, E1, E2, E3]",
            "c9c5_operands_layout": "[frame, commit_cycle, E1_before, E2_before, E3_before, carry_in, X0300, address0300, value0300, X0700, address0700, value0700, X0780, address0780, value0780, E1_after, E2_after, E3_after]",
        },
    }
    PASS_EXTENSION_OUTPUT.write_text(
        json.dumps(extension, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")
    print(f"Wrote {PASS_EXTENSION_OUTPUT.relative_to(ROOT)}")
    print(f"Base input SHA-256: {base_input_sha}")
    print(f"Extended input SHA-256: {input_sha}")
    print(f"Updates: A117={len(a117_frames)}, base C9C5=133, pass-extension C9C5={len(pass_c9_updates)}")
    print(
        "Receiver: frame %d cycle %d E2=$%02X slot=$%02X"
        % (receiver["source_frame"], receiver["source_cycle"], receiver["e2"], receiver["slot"])
    )


if __name__ == "__main__":
    main()

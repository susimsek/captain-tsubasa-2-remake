#!/usr/bin/env python3
"""Build a ROM-only receipt for the fresh KICK OFF `$893B` IRQ wait.

The candidate machine runs the supplied ROM and the audited input sequence.
No FCEUX trace, RAM dump, save state, screenshot, or emulator output is loaded.
The output is a bounded event schedule for this one input route; it does not
claim complete PPU fetch or physical NES timing.
"""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
INPUT_SHA256 = "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
EXPECTED_FRAME = 7266
EXPECTED_RELEASE_CYCLE = 216372408
MAX_FRAME = 7300
SOURCE_STEPPER = ROOT / "tools/diagnostics/step_rom_source_cpu_ppu_dmc_mmc3_assert_candidate.py"
INPUT_BUILDER = ROOT / "tools/gameplay/build_kickoff_rng_source_schedule.py"
OUTPUT = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_893b_irq_candidate_schedule_20261031.json"
REQUIRED_IRQ_PATH = (0xC506, 0xC821, 0xC478, 0xC491, 0xA160, 0xA1C3, 0xC4AD)
WAIT_RAM = {0x001B: 0xC0, 0x0078: 0x04, 0x0079: 0x40, 0x003B: 0x55}
WAIT_RAM_LAST_WRITERS = {
    0x001B: {"source_pc": 0xA133, "prg_bank": 2, "value": 0xC0},
    0x0078: {"source_pc": 0xA0A6, "prg_bank": 2, "value": 0x04},
    0x0079: {"source_pc": 0x8943, "prg_bank": 0, "value": 0x40},
    0x003B: {"source_pc": 0xC46F, "prg_bank": 30, "value": 0x55},
}


class CaptureComplete(Exception):
    pass


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load source tool: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _ordered_path_contains(path: list[int], expected: tuple[int, ...]) -> bool:
    cursor = 0
    for address in path:
        if cursor < len(expected) and address == expected[cursor]:
            cursor += 1
    return cursor == len(expected)


def main() -> None:
    stepper = _load_module("ct2_irq_candidate", SOURCE_STEPPER)
    input_builder = _load_module("ct2_rng_schedule_builder", INPUT_BUILDER)
    rom = stepper.ROM_PATH.read_bytes()
    if _sha256(rom) != ROM_SHA256:
        raise SystemExit("The supplied ROM hash differs from the audited Turkish revision.")

    _rows, input_bytes = input_builder._read_route_inputs()
    input_sha = _sha256(input_bytes)
    if input_sha != INPUT_SHA256:
        raise SystemExit(f"The audited KICK OFF input-route hash differs: {input_sha}")

    with tempfile.NamedTemporaryFile("wb") as input_stream:
        input_stream.write(input_bytes)
        input_stream.flush()
        input_timeline = stepper.load_input_timeline(Path(input_stream.name))

    class WaitCaptureMachine(stepper.Machine):
        def __init__(self, *args, **kwargs):
            self.first_wait_state: dict | None = None
            self.irq_entry_state: dict | None = None
            self.irq_return_state: dict | None = None
            self.irq_path: list[int] = []
            self.ram_writes: list[dict] = []
            self.release_write: dict | None = None
            self.capture_active = False
            self.non_target_waits: list[dict] = []
            self.selector_call_entry: dict | None = None
            self.selector_call_return: dict | None = None
            self.selector_call_active = False
            self.selector_frame_intervals: list[dict] = []
            self.selector_interrupt_spans: list[dict] = []
            self.selector_interrupt_stack: list[dict] = []
            self.wait_ram_write_audit = {
                address: {"count": 0, "first": None, "recent": []}
                for address in WAIT_RAM
            }
            super().__init__(*args, **kwargs)

        def _wait_ram_write_provenance(self) -> dict:
            return {
                f"${address:04X}": {
                    "expected_wait_value": expected,
                    "write_count_before_first_wait": self.wait_ram_write_audit[address]["count"],
                    "first_write": self.wait_ram_write_audit[address]["first"],
                    "recent_writes": list(self.wait_ram_write_audit[address]["recent"]),
                }
                for address, expected in WAIT_RAM.items()
            }

        def _snapshot(self) -> dict:
            return {
                "source_frame": self.source_frame,
                "cpu_cycle": self.cpu_cycles,
                "cpu": {"pc": self.cpu.pc, "a": self.cpu.a, "x": self.cpu.x,
                        "y": self.cpu.y, "p": self.cpu.p, "prev_p": self.prev_p,
                        "sp": self.cpu.sp},
                "wait_ram": {address: self.ram[address] for address in WAIT_RAM},
                "ppu": {"line": self.ppu_line, "dot": self.ppu_dot,
                        "ctrl": self.ppu_regs[0], "mask": self.ppu_regs[1],
                        "status": self.ppu_status, "addr": self.ppu_addr,
                        "vram_addr": self.ppu_vram_addr},
                "mmc3": {"registers": list(self.mmc3_regs), "command": self.mmc3_cmd,
                         "latch": self.mmc3_latch, "counter": self.mmc3_count,
                         "reload_pending": self.mmc3_reload,
                         "irq_enabled": self.mmc3_enabled,
                         "irq_pending": self.irq_pending},
            }

        def _is_target_wait(self) -> bool:
            if any(self.ram[address] != expected for address, expected in WAIT_RAM.items()):
                return False
            stack_pointer = int(self.cpu.sp)
            return_low = self.ram[0x0100 | ((stack_pointer + 1) & 0xFF)]
            return_high = self.ram[0x0100 | ((stack_pointer + 2) & 0xFF)]
            return (return_low | (return_high << 8)) == 0x8116

        def _stack_return_word(self) -> int:
            stack_pointer = int(self.cpu.sp)
            return_low = self.ram[0x0100 | ((stack_pointer + 1) & 0xFF)]
            return_high = self.ram[0x0100 | ((stack_pointer + 2) & 0xFF)]
            return return_low | (return_high << 8)

        def _record_selector_frame_interval(self, frame: int,
                                            frame_cycle_start: int,
                                            frame_cycle_end: int) -> None:
            if self.selector_call_entry is None:
                return
            call_start = int(self.selector_call_entry["source_cycle"])
            call_end = (int(self.selector_call_return["source_cycle"])
                        if self.selector_call_return is not None else frame_cycle_end)
            active_start = max(frame_cycle_start, call_start)
            active_end = min(frame_cycle_end, call_end)
            if active_end <= active_start:
                return
            self.selector_frame_intervals.append({
                "source_frame": frame,
                "frame_cycle_start": frame_cycle_start,
                "frame_cycle_end": frame_cycle_end,
                "selector_active_cycle_start": active_start,
                "selector_active_cycle_end": active_end,
                "selector_elapsed_cpu_cycles": active_end - active_start,
            })

        def run_frame(self, frame: int) -> None:
            frame_cycle_start = self.cpu_cycles
            try:
                super().run_frame(frame)
            except CaptureComplete:
                self._record_selector_frame_interval(frame, frame_cycle_start,
                                                     self.cpu_cycles)
                raise
            self._record_selector_frame_interval(frame, frame_cycle_start,
                                                 self.cpu_cycles)

        def __setitem__(self, address: int, value: int) -> None:
            address &= 0xFFFF
            value &= 0xFF
            if address < 0x2000:
                ram_address = address & 0x07FF
                if ram_address in self.wait_ram_write_audit:
                    audit = self.wait_ram_write_audit[ram_address]
                    event = {
                        "source_pc": int(self.current_instruction_pc),
                        "prg_bank": int(self._prg_bank(self.current_instruction_pc))
                            if self.current_instruction_pc >= 0x8000 else -1,
                        "address": ram_address,
                        "before": int(self.ram[ram_address]),
                        "value": value,
                        "source_frame": int(self.source_frame),
                        "source_cycle": int(self.cpu_cycles),
                    }
                    audit["count"] += 1
                    if audit["first"] is None:
                        audit["first"] = event
                    recent: list[dict] = audit["recent"]
                    recent.append(event)
                    if len(recent) > 8:
                        del recent[0]
            if self.capture_active and address < 0x2000:
                ram_address = address & 0x07FF
                old_value = self.ram[ram_address]
                pc = int(self.current_instruction_pc)
                bank = int(self._prg_bank(pc))
                if pc == 0xA1C3 and ram_address == 0x0078:
                    self.release_write = {"source_pc": pc, "prg_bank": bank,
                                          "address": ram_address, "before": old_value,
                                          "value": value, "source_frame": self.source_frame,
                                          "source_cycle": self.cpu_cycles}
                self.ram_writes.append({"source_pc": pc, "prg_bank": bank,
                                        "address": ram_address, "before": old_value,
                                        "value": value, "source_frame": self.source_frame,
                                        "source_cycle": self.cpu_cycles})
            super().__setitem__(address, value)

        def _cpu_instruction(self) -> None:
            pc_before = int(self.cpu.pc)
            mapped_bank = int(self._prg_bank(pc_before)) if pc_before >= 0x8000 else -1
            stack_word_before = self._stack_return_word()
            if self.selector_call_entry is None and pc_before == 0xA20F \
                    and mapped_bank == 2 and stack_word_before == 0x80FC:
                self.selector_call_entry = {
                    "source_frame": self.source_frame,
                    "source_cycle": self.cpu_cycles,
                    "pc": "$A20F",
                    "prg_bank_8k": mapped_bank,
                    "cpu": {"a": int(self.cpu.a), "x": int(self.cpu.x),
                            "y": int(self.cpu.y), "p": int(self.cpu.p),
                            "sp": int(self.cpu.sp)},
                    "caller_return_word": "$80FC",
                }
                self.selector_call_active = True
            selector_rts = self.selector_call_active and pc_before == 0xA8B6 \
                and mapped_bank == 2 and stack_word_before == 0x80FC
            rti_instruction = int(self[pc_before]) == 0x40
            irq_will_be_accepted = pc_before == 0x893B and mapped_bank == 0 \
                and self.irq_pending and not (self.prev_p & 0x04) and not self.jammed
            target_irq = irq_will_be_accepted and self._is_target_wait()
            if pc_before == 0x893B and mapped_bank == 0 and self._is_target_wait():
                if self.first_wait_state is None:
                    self.first_wait_state = self._snapshot()
                    self.first_wait_state["wait_ram_write_provenance"] = self._wait_ram_write_provenance()
            if irq_will_be_accepted and not target_irq and len(self.non_target_waits) < 8:
                state = self._snapshot()
                stack_pointer = int(self.cpu.sp)
                state["caller_return_word"] = (
                    self.ram[0x0100 | ((stack_pointer + 1) & 0xFF)]
                    | (self.ram[0x0100 | ((stack_pointer + 2) & 0xFF)] << 8)
                )
                self.non_target_waits.append(state)
            if self.capture_active and not irq_will_be_accepted:
                if not self.irq_path or self.irq_path[-1] != pc_before:
                    self.irq_path.append(pc_before)

            interrupts_before = len(self.cpu_interrupt_events)
            if target_irq:
                self.irq_entry_state = self._snapshot()
                self.irq_entry_state["wait_ram_write_provenance"] = self._wait_ram_write_provenance()
                stack_pointer = int(self.cpu.sp)
                self.irq_entry_state["caller_return_word"] = (
                    self.ram[0x0100 | ((stack_pointer + 1) & 0xFF)]
                    | (self.ram[0x0100 | ((stack_pointer + 2) & 0xFF)] << 8)
                )
                self.capture_active = True
            super()._cpu_instruction()

            new_interrupts = self.cpu_interrupt_events[interrupts_before:]
            for interrupt in new_interrupts:
                if not self.selector_call_active:
                    continue
                vector = 0xFFFA if interrupt.get("kind") == "NMI" else 0xFFFE
                self.selector_interrupt_stack.append({
                    "kind": str(interrupt.get("kind", "unknown")),
                    "source_frame": int(interrupt["source_frame"]),
                    "acceptance_cycle": int(interrupt["cycle"]),
                    "pc_before": str(interrupt.get("pc_before", "")),
                    "mask_before": int(interrupt.get("mask_before", 0)),
                    "vector_pc": f"${(self[vector] | (self[vector + 1] << 8)):04X}",
                })
            if self.selector_call_active and rti_instruction \
                    and self.selector_interrupt_stack:
                interrupt_span = self.selector_interrupt_stack.pop()
                interrupt_span["return_source_frame"] = self.source_frame
                interrupt_span["return_cycle"] = self.cpu_cycles
                interrupt_span["return_pc"] = f"${int(self.cpu.pc):04X}"
                self.selector_interrupt_spans.append(interrupt_span)
            if selector_rts and int(self.cpu.pc) == 0x80FD:
                self.selector_call_return = {
                    "source_frame": self.source_frame,
                    "source_cycle": self.cpu_cycles,
                    "instruction_pc": "$A8B6",
                    "prg_bank_8k": mapped_bank,
                    "return_pc": f"${int(self.cpu.pc):04X}",
                    "cpu": {"a": int(self.cpu.a), "x": int(self.cpu.x),
                            "y": int(self.cpu.y), "p": int(self.cpu.p),
                            "sp": int(self.cpu.sp)},
                    "consumed_caller_return_word": "$80FC",
                }
                self.selector_call_active = False

            if target_irq:
                if len(self.cpu_interrupt_events) != interrupts_before + 1:
                    raise RuntimeError("The ROM model did not accept the pending `$893B` IRQ.")
                accepted = self.cpu_interrupt_events[-1]
                if accepted.get("kind") != "IRQ" or accepted.get("pc_before") != "$893B":
                    raise RuntimeError(f"Unexpected interrupt at the wait: {accepted}")
                vector_pc = self[0xFFFE] | (self[0xFFFF] << 8)
                self.irq_path.append(vector_pc)
                first_handler_pc = int(self.current_instruction_pc)
                if first_handler_pc != vector_pc:
                    raise RuntimeError("The interrupt vector's first ROM instruction was not executed.")
                return

            if self.capture_active and pc_before == 0xC4AD and self.cpu.pc == 0x893B:
                self.irq_return_state = self._snapshot()
                raise CaptureComplete

    machine = WaitCaptureMachine(rom, input_timeline)
    completed_frame = -1
    for frame in range(1, MAX_FRAME + 1):
        if frame % 1000 == 0:
            print(f"ROM-only interrupt replay: frame {frame}/{MAX_FRAME}", flush=True)
        try:
            machine.run_frame(frame)
        except CaptureComplete:
            completed_frame = frame
            break
    if completed_frame < 0 or machine.irq_entry_state is None or machine.irq_return_state is None:
        raise SystemExit("The ROM-only model did not complete the `$893B` IRQ/RTI route. "
                         f"Non-target waits: {machine.non_target_waits}")
    if machine.selector_call_entry is None or machine.selector_call_return is None \
            or machine.selector_interrupt_stack:
        raise SystemExit("The ROM-only model did not observe a complete bank-$02 `$A20F->$A8B6` call.")
    if completed_frame != EXPECTED_FRAME:
        raise SystemExit(f"Unexpected IRQ source frame: {completed_frame}")
    if machine.release_write is None \
            or int(machine.release_write["source_cycle"]) != EXPECTED_RELEASE_CYCLE:
        actual_cycle = None if machine.release_write is None else machine.release_write["source_cycle"]
        raise SystemExit(f"Unexpected `$A1C3` release-store cycle: {actual_cycle}")
    for address, expected in WAIT_RAM.items():
        actual = int(machine.irq_entry_state["wait_ram"][address])
        if actual != expected:
            raise SystemExit(f"ROM-derived wait RAM mismatch at `${address:04X}`: ${actual:02X}")
        provenance = machine.irq_entry_state["wait_ram_write_provenance"].get(f"${address:04X}", {})
        recent_writes = provenance.get("recent_writes", [])
        if not recent_writes:
            raise SystemExit(f"ROM-only write provenance is missing for `${address:04X}`.")
        last_write = recent_writes[-1]
        expected_writer = WAIT_RAM_LAST_WRITERS[address]
        if any(int(last_write.get(field, -1)) != expected_value
               for field, expected_value in expected_writer.items()) \
                or int(last_write.get("address", -1)) != address:
            raise SystemExit(f"Unexpected ROM-only last writer for `${address:04X}`: {last_write}")
    if not _ordered_path_contains(machine.irq_path, REQUIRED_IRQ_PATH):
        raise SystemExit(f"ROM-derived IRQ path is incomplete: {machine.irq_path}")
    if machine.release_write is None or machine.release_write["before"] != 4 \
            or machine.release_write["value"] != 0 or machine.release_write["prg_bank"] != 2:
        raise SystemExit(f"ROM-derived `$A1C3` release store is missing or invalid: {machine.release_write}")
    before_cpu = machine.irq_entry_state["cpu"]
    after_cpu = machine.irq_return_state["cpu"]
    if after_cpu["pc"] != 0x893B or after_cpu["sp"] != before_cpu["sp"] \
            or any(after_cpu[key] != before_cpu[key] for key in ("a", "x", "y", "p")):
        raise SystemExit("The ROM IRQ/RTI did not restore the interrupted `$893B` CPU state.")

    edge_candidates = [event for event in machine.mmc3_irq_events
                       if int(event.get("source_frame", -1)) <= completed_frame]
    if not edge_candidates:
        raise SystemExit("The ROM-only model accepted the IRQ without a recorded MMC3 assertion event.")
    irq_edge = edge_candidates[-1]
    release_event_id = f"fresh-kickoff-893b-irq-edge:{int(irq_edge['source_frame'])}:{int(irq_edge['cycle'])}"
    document = {
        "schema": "ct2-kickoff-preset-irq-source-schedule-v1",
        "source_rom_sha256": ROM_SHA256,
        "route_identity": "turkish-fresh-kickoff-capture-20261027",
        "input_route": {"sha256": input_sha, "first_source_frame": 0,
                        "last_source_frame": 9042,
                        "source_files": [
                            "reference/diagnostics/kickoff_select_test_20261027/opening_replay.csv",
                            "reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"],
                        "emulator_state_used": False},
        "source_model": {
            "script": SOURCE_STEPPER.relative_to(ROOT).as_posix(),
            "script_sha256": _sha256(SOURCE_STEPPER.read_bytes()),
            "cpu_engine": "Py65 1.2.0; diagnostics/build-time only",
            "fceux_trace_used_as_input": False,
            "ppu_model": "ROM-independent NTSC dot/frame model with simplified NewPPU MMC3 slot-2 scanline hook; not a complete PPU fetch pipeline",
            "physical_nes_timing_proven": False,
        },
        "selector_call_clock": {
            "entry": machine.selector_call_entry,
            "return": machine.selector_call_return,
            "elapsed_cpu_cycles": (int(machine.selector_call_return["source_cycle"])
                                    - int(machine.selector_call_entry["source_cycle"])),
            "per_frame_intervals": machine.selector_frame_intervals,
            "interrupt_accept_return_spans": machine.selector_interrupt_spans,
            "interrupt_spans_complete": True,
            "source_semantics": "ROM-only candidate CPU timing for the recorded input route; no FCEUX state or trace values used",
            "intermediate_ppu_fetch_parity": False,
        },
        "irq_wait_release": {
            "runtime_consumable_fields": ["irq_edge"],
            "runtime_must_execute_rom_irq_handlers": True,
            "source_event_id": release_event_id,
            "irq_edge": {"source_frame": int(irq_edge["source_frame"]),
                         "source_cycle": int(irq_edge["cycle"]),
                         "ppu_line": int(irq_edge["ppu_line"]),
                         "ppu_dot": int(irq_edge["ppu_dot"]),
                         "counter_before": int(irq_edge["count_before"]),
                         "counter_after": int(irq_edge["count_after"]),
                         "latch": int(irq_edge["latch"]),
                         "irq_enabled": int(irq_edge["irq_enabled"])},
            "candidate_execution_audit_only": {
                "wait_state": machine.irq_entry_state,
                "interrupt_acceptance": machine.cpu_interrupt_events[-1],
                "source_path": machine.irq_path,
                "release_write": machine.release_write,
                "return_state": machine.irq_return_state,
                "interrupt_stack_balanced": True,
            },
        },
        "validation": {"runtime_rom_dependency": False,
                       "runtime_emulator_dependency": False,
                       "complete_ppu_fetch_parity": False,
                       "same_input_cycle_match_to_fceux": False},
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(OUTPUT.relative_to(ROOT)),
                      "source_frame": completed_frame,
                      "source_cycle": release_event_id.split(":")[-1],
                      "irq_path": [f"${address:04X}" for address in machine.irq_path],
                      "rom_sha256": ROM_SHA256, "input_sha256": input_sha}, indent=2))


if __name__ == "__main__":
    main()

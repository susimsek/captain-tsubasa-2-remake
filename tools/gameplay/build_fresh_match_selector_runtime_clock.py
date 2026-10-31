#!/usr/bin/env python3
"""Convert the candidate selector call clock to a compact Godot runtime asset.

This converter copies only normalized cycle intervals and ordered interrupt
accept/return events. It does not package FCEUX state, ROM bytes, or write
receipts, and it rejects any source whose call boundaries or cycle totals have
drifted from the reviewed route.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "reference/rom_extract/gameplay/fresh_kickoff_893b_irq_candidate_schedule_20261031.json"
OUTPUT = ROOT / "assets/gameplay/rom_logic/fresh_match_selector_runtime_clock.json"

SOURCE_SCHEMA = "ct2-kickoff-preset-irq-source-schedule-v1"
RUNTIME_SCHEMA = "ct2-fresh-match-selector-runtime-clock-v1"
ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
INPUT_SHA256 = "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"
MODEL_SHA256 = "b0f528dfd73f79cf7148a5a2f6a9f0683cde22a03c1705deb8e5215864d888db"
ENTRY_PC = "$A20F"
RETURN_INSTRUCTION_PC = "$A8B6"
CALLER_RETURN = "$80FC"
EXPECTED_ENTRY_FRAME = 7258
EXPECTED_RETURN_FRAME = 7266
EXPECTED_ELAPSED = 223242
EXPECTED_INTERRUPT = 19909
EXPECTED_MAINLINE = 203333


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def _convert(source: dict[str, Any], source_sha256: str) -> dict[str, Any]:
    require(source.get("schema") == SOURCE_SCHEMA, "Unsupported source schedule schema.")
    require(source.get("source_rom_sha256") == ROM_SHA256, "Source schedule targets a different ROM.")
    route = source.get("input_route", {})
    require(route.get("sha256") == INPUT_SHA256, "Source schedule input hash differs from the reviewed route.")
    require(route.get("emulator_state_used") is False, "Candidate clock must not use an emulator state.")

    model = source.get("source_model", {})
    require(model.get("script_sha256") == MODEL_SHA256, "Candidate timing model hash is not the reviewed build.")
    require(model.get("fceux_trace_used_as_input") is False, "Candidate timing model must not consume FCEUX trace input.")
    require(model.get("physical_nes_timing_proven") is False, "Physical NES timing must remain explicitly unproven.")

    clock = source.get("selector_call_clock", {})
    entry = clock.get("entry", {})
    returned = clock.get("return", {})
    require(entry.get("pc") == ENTRY_PC and entry.get("prg_bank_8k") == 2,
            "Selector entry must be bank-$02 `$A20F`.")
    require(entry.get("source_frame") == EXPECTED_ENTRY_FRAME
            and entry.get("source_cycle") == 216143875
            and entry.get("caller_return_word") == CALLER_RETURN,
            "Selector entry call boundary differs from the reviewed capture.")
    entry_cpu = entry.get("cpu", {})
    entry_p = int(entry_cpu.get("p", -1))
    require(entry_p >= 0 and entry_p <= 0xFF and (entry_p & 0x04) == 0,
            "ROM-only candidate must derive interrupt-disable clear at `$A20F`.")
    require(returned.get("instruction_pc") == RETURN_INSTRUCTION_PC
            and returned.get("prg_bank_8k") == 2
            and returned.get("source_frame") == EXPECTED_RETURN_FRAME
            and returned.get("source_cycle") == 216367117
            and returned.get("return_pc") == "$80FD"
            and returned.get("consumed_caller_return_word") == CALLER_RETURN,
            "Selector return boundary differs from the reviewed capture.")
    require(clock.get("elapsed_cpu_cycles") == EXPECTED_ELAPSED,
            "Selector call elapsed cycles differ from the reviewed total.")
    require(clock.get("interrupt_spans_complete") is True,
            "Candidate schedule does not declare its interrupt spans complete.")
    require(clock.get("intermediate_ppu_fetch_parity") is False,
            "The candidate must not claim complete PPU-fetch parity.")

    raw_intervals = clock.get("per_frame_intervals", [])
    require(len(raw_intervals) == EXPECTED_RETURN_FRAME - EXPECTED_ENTRY_FRAME + 1,
            "Selector clock must contain nine contiguous source-frame intervals.")
    intervals: list[dict[str, int]] = []
    prior_source_frame: int | None = None
    prior_cycle_end: int | None = None
    for offset, row in enumerate(raw_intervals):
        require(isinstance(row, dict), "Malformed selector frame interval.")
        source_frame = int(row["source_frame"])
        active_start = int(row["selector_active_cycle_start"])
        active_end = int(row["selector_active_cycle_end"])
        frame_start = int(row["frame_cycle_start"])
        frame_end = int(row["frame_cycle_end"])
        require(source_frame == EXPECTED_ENTRY_FRAME + offset,
                "Selector frame labels are not contiguous from the entry frame.")
        require(active_start >= frame_start and active_end <= frame_end and active_end > active_start,
                "Selector active interval is outside its source frame bounds.")
        if offset == 0:
            require(active_start == int(entry["source_cycle"]),
                    "First active interval must begin at the `$A20F` entry.")
        if prior_source_frame is not None:
            require(source_frame == prior_source_frame + 1,
                    "Selector source-frame sequence is not contiguous.")
            require(active_start == prior_cycle_end,
                    "Selector active intervals have a cycle gap or overlap.")
            require(frame_start == int(raw_intervals[offset - 1]["frame_cycle_end"]),
                    "Source-frame cycle boundaries have a gap or overlap.")
        require(int(row["selector_elapsed_cpu_cycles"]) == active_end - active_start,
                "Recorded selector interval duration does not match its cycle boundaries.")
        intervals.append({
            "frame_offset": offset,
            "source_frame": source_frame,
            "elapsed_cycle_start": active_start - int(entry["source_cycle"]),
            "elapsed_cycle_end": active_end - int(entry["source_cycle"]),
        })
        prior_source_frame = source_frame
        prior_cycle_end = active_end

    require(intervals[0]["elapsed_cycle_start"] == 0
            and intervals[-1]["elapsed_cycle_end"] == EXPECTED_ELAPSED,
            "Normalized selector intervals do not span the complete call.")
    require(prior_cycle_end == int(returned["source_cycle"]),
            "Last active interval must end at the selector return.")

    raw_events = clock.get("interrupt_accept_return_spans", [])
    events: list[dict[str, Any]] = []
    previous_accept = -1
    previous_return = -1
    for raw in raw_events:
        require(isinstance(raw, dict), "Malformed interrupt span.")
        kind = raw.get("kind")
        require(kind in ("NMI", "IRQ"), "Unknown selector interrupt kind.")
        accept = int(raw["acceptance_cycle"])
        returned_cycle = int(raw["return_cycle"])
        source_frame = int(raw["source_frame"])
        require(accept < returned_cycle, "Interrupt return must follow acceptance.")
        require(accept > previous_accept and accept >= previous_return,
                "Interrupt spans must be ordered and non-overlapping.")
        require(EXPECTED_ENTRY_FRAME <= source_frame <= EXPECTED_RETURN_FRAME,
                "Interrupt source frame lies outside the selector call.")
        require(int(raw["return_source_frame"]) == source_frame,
                "Interrupt span crosses a source-frame boundary; route contract needs review.")
        offset = source_frame - EXPECTED_ENTRY_FRAME
        interval = intervals[offset]
        accept_offset = accept - int(entry["source_cycle"])
        return_offset = returned_cycle - int(entry["source_cycle"])
        require(int(interval["elapsed_cycle_start"]) <= accept_offset < return_offset
                <= int(interval["elapsed_cycle_end"]),
                "Interrupt span is outside its selector frame interval.")
        expected_vector = "$C500" if kind == "NMI" else "$C506"
        require(raw.get("vector_pc") == expected_vector and int(raw.get("mask_before", -1)) == 0,
                "Interrupt vector or enable-state contract is invalid.")
        require(raw.get("return_pc") == raw.get("pc_before"),
                "Interrupt return PC does not restore the interrupted PC.")
        events.append({
            "kind": kind,
            "frame_offset": offset,
            "elapsed_cycle": accept_offset,
            "return_cycle": return_offset,
            "pc_before": raw["pc_before"],
            "vector_pc": raw["vector_pc"],
            "return_pc": raw["return_pc"],
        })
        previous_accept = accept
        previous_return = returned_cycle

    require(len(events) == 15, "Expected eight NMIs and seven IRQs in the selector call.")
    require(sum(event["kind"] == "NMI" for event in events) == 8
            and sum(event["kind"] == "IRQ" for event in events) == 7,
            "Selector interrupt event counts changed.")
    interrupt_cycles = sum(event["return_cycle"] - event["elapsed_cycle"] for event in events)
    elapsed_cycles = intervals[-1]["elapsed_cycle_end"] - intervals[0]["elapsed_cycle_start"]
    require(interrupt_cycles == EXPECTED_INTERRUPT, "Interrupt span total is not 19,909 cycles.")
    require(elapsed_cycles - interrupt_cycles == EXPECTED_MAINLINE,
            "Derived mainline total is not 203,333 cycles.")

    return {
        "schema": RUNTIME_SCHEMA,
        "source_rom_sha256": ROM_SHA256,
        "input_route_sha256": INPUT_SHA256,
        "source_model_sha256": MODEL_SHA256,
        "source_artifact": {
            "path": "reference/rom_extract/gameplay/fresh_kickoff_893b_irq_candidate_schedule_20261031.json",
            "sha256": source_sha256,
        },
        "call_contract": {
            "entry_pc": ENTRY_PC,
            "entry_prg_bank_8k": 2,
            "entry_source_frame_provenance": EXPECTED_ENTRY_FRAME,
            "entry_source_cycle_provenance": int(entry["source_cycle"]),
            "caller_return_word": CALLER_RETURN,
            "return_instruction_pc": RETURN_INSTRUCTION_PC,
            "return_prg_bank_8k": 2,
            "return_source_frame_provenance": EXPECTED_RETURN_FRAME,
            "return_source_cycle_provenance": int(returned["source_cycle"]),
            "return_pc": returned["return_pc"],
            "consumed_caller_return_word": returned["consumed_caller_return_word"],
        },
        "entry_status_contract": {
            "flag": "I",
            "known_mask": 0x04,
            "known_value": 0,
            "candidate_p_byte": entry_p,
            "basis": "ROM-only source CPU candidate from reset with the hash-bound recorded input route",
            "source_model_sha256": MODEL_SHA256,
            "input_route_sha256": INPUT_SHA256,
            "physical_nes_timing_proven": False,
        },
        "cycle_totals": {
            "elapsed": EXPECTED_ELAPSED,
            "interrupt": EXPECTED_INTERRUPT,
            "mainline": EXPECTED_MAINLINE,
        },
        "source_limits": {
            "fceux_trace_used_as_input": False,
            "complete_ppu_fetch_parity": False,
            "physical_nes_timing_proven": False,
            "handler_writes_applied": False,
            "return_receipts_applied": False,
            "runtime_rom_dependency": False,
            "runtime_emulator_dependency": False,
        },
        "frame_intervals": intervals,
        "interrupt_events": events,
    }


def main() -> None:
    source_bytes = SOURCE.read_bytes()
    source = json.loads(source_bytes)
    runtime_asset = _convert(source, sha256(source_bytes))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(runtime_asset, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT.relative_to(ROOT)} ({len(runtime_asset['frame_intervals'])} frames, "
          f"{len(runtime_asset['interrupt_events'])} interrupt events).")
    print("Totals: 223242 elapsed = 19909 interrupt + 203333 mainline cycles.")


if __name__ == "__main__":
    main()

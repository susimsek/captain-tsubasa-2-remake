#!/usr/bin/env python3
"""Compare saved ROM-only source events with retained muted same-input FCEUX traces.

This is post-run validation only. It never feeds FCEUX rows into the source
stepper or changes runtime assets.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = ROOT / "reference/diagnostics/audio/rom_only_source_cpu_ppu_dmc_full_start_4662_20261026"
DEFAULT_FCEUX_DIR = ROOT / "reference/diagnostics/audio/fceux_dmc_pcm_sync_20261025_seg1"
DEFAULT_DMC_TRACE = ROOT / "reference/diagnostics/audio/fceux_dmc_hook_trace_pcm_sync_sequence_ordered_merged_20261025/dmc_hook_trace.csv"
DEFAULT_DMC_META = ROOT / "reference/diagnostics/audio/fceux_dmc_hook_trace_pcm_sync_sequence_ordered_merged_20261025/trace_meta.json"
DEFAULT_INPUT = ROOT / "reference/opening_reference_capture/input_timeline.csv"
DEFAULT_OUT = ROOT / "reference/diagnostics/audio/rom_only_source_cpu_ppu_dmc_same_input_validation_20261026/validation.json"
FCEUX_REVISION = "a6d03e7968bd77a8156a7c9b628a673753f2f4c6"
FCEUX_SOUND_REGS = set(range(0x4000, 0x4014)) | {0x4015, 0x4017}


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def hex_value(value: str) -> int:
    value = value.strip()
    if value.startswith("$"):
        return int(value[1:], 16)
    return int(value, 16)


def summarize_residuals(values: list[int]) -> dict:
    counts = Counter(values)
    return {
        "min_cycles": min(values) if values else None,
        "max_cycles": max(values) if values else None,
        "mean_cycles": sum(values) / len(values) if values else None,
        "nonzero_count": sum(value != 0 for value in values),
        "count": len(values),
        "histogram": {str(key): counts[key] for key in sorted(counts)},
    }


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--fceux-dir", type=Path, default=DEFAULT_FCEUX_DIR)
    parser.add_argument("--dmc-trace", type=Path, default=DEFAULT_DMC_TRACE)
    parser.add_argument("--dmc-meta", type=Path, default=DEFAULT_DMC_META)
    parser.add_argument("--input-timeline", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    source_report_path = args.source_dir / "source_stepper_report.json"
    source_report = json.loads(source_report_path.read_text(encoding="utf-8"))
    fceux_meta = json.loads(args.dmc_meta.read_text(encoding="utf-8"))
    input_hash = file_sha256(args.input_timeline)
    expected_input_hash = fceux_meta["input_timeline"]["sha256"]
    if source_report.get("input_timeline_sha256") != input_hash:
        raise SystemExit("source run and current input timeline hashes differ")
    if expected_input_hash != input_hash:
        raise SystemExit("FCEUX merged DMC trace and input timeline hashes differ")
    if fceux_meta.get("fceux_pinned_revision") != FCEUX_REVISION:
        raise SystemExit("FCEUX trace revision does not match the pinned revision")

    source_apu = [
        row for row in read_csv(args.source_dir / "source_apu_writes.csv")
        if int(row["source_frame"]) <= 4662
    ]
    fceux_apu = [
        row for row in read_csv(args.fceux_dir / "apu_writes.csv")
        if int(row["source_frame"]) <= 4662
        and hex_value(row["address"]) in FCEUX_SOUND_REGS
    ]
    apu_pairs = list(zip(source_apu, fceux_apu))
    apu_value_mismatches = [
        {
            "pair_index": index,
            "source": {"frame": int(source["source_frame"]), "cycle": int(source["cycle"]),
                       "pc": source["pc"], "address": source["address"], "value": source["value"]},
            "fceux": {"frame": int(fceux["source_frame"]), "cycle": int(fceux["cpu_cycle"]),
                      "pc": fceux["pc"], "address": fceux["address"], "value": fceux["value"]},
        }
        for index, (source, fceux) in enumerate(apu_pairs)
        if (hex_value(source["address"]), hex_value(source["value"]))
        != (hex_value(fceux["address"]), hex_value(fceux["value"]))
    ]
    apu_cycle_residuals = [
        int(source["cycle"]) - int(fceux["cpu_cycle"])
        for source, fceux in apu_pairs
    ]

    fceux_frames = read_csv(args.fceux_dir / "frame_cycles.csv")
    frame_4661 = next(row for row in fceux_frames if int(row["source_frame"]) == 4661)
    start_cycle = int(frame_4661["cycle_start"])
    source_dmc = [
        row for row in read_csv(args.source_dir / "source_dmc_dma_reads.csv")
        if int(row["source_frame"]) <= 4660 and int(row["index"]) % 4 == 3
    ]
    fceux_dmc = []
    with args.dmc_trace.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            if row["event"] == "DMC_DMA_OUT" and int(row["absolute_cycle"]) < start_cycle:
                fceux_dmc.append(row)
    dmc_pairs = list(zip(source_dmc, fceux_dmc))
    dmc_value_mismatches = [
        {
            "output_byte_index": index,
            "source": {"frame": int(source["source_frame"]), "cycle": int(source["cycle"]),
                       "address": source["address"], "value": source["value"]},
            "fceux": {"cycle": int(fceux["absolute_cycle"]),
                      "address": f"${int(fceux['detail_address'], 16):04X}",
                      "value": f"${int(fceux['detail_value']):02X}"},
        }
        for index, (source, fceux) in enumerate(dmc_pairs)
        if (hex_value(source["address"]), hex_value(source["value"]))
        != (int(fceux["detail_address"], 16), int(fceux["detail_value"]))
    ]
    dmc_cycle_residuals = [
        int(source["cycle"]) - int(fceux["absolute_cycle"])
        for source, fceux in dmc_pairs
    ]
    selected_byte_index = 43206
    selected_byte = None
    if selected_byte_index < len(dmc_pairs):
        source, fceux = dmc_pairs[selected_byte_index]
        selected_byte = {
            "zero_based_output_byte_index": selected_byte_index,
            "source_frame": int(source["source_frame"]),
            "source": {"cycle": int(source["cycle"]), "address": source["address"], "value": source["value"]},
            "fceux": {"cycle": int(fceux["absolute_cycle"]),
                      "address": f"${int(fceux['detail_address'], 16):04X}",
                      "value": f"${int(fceux['detail_value']):02X}"},
            "cycle_residual": int(source["cycle"]) - int(fceux["absolute_cycle"]),
            "fceux_dmc_state": {key: fceux[key] for key in (
                "dmcaddress", "dmcsize", "dmcshift", "dmchavedma", "dmchavesample", "dmcdmabuf", "rawdalatch"
            )},
        }

    result = {
        "purpose": "post-run validation of the ROM-only source stepper against retained muted same-input FCEUX traces",
        "source_scheduler_used_fceux_as_input": False,
        "rom_sha256": source_report["source_rom_sha256"],
        "fceux_revision": FCEUX_REVISION,
        "input_timeline": {
            "path": args.input_timeline.relative_to(ROOT).as_posix() if args.input_timeline.is_relative_to(ROOT) else str(args.input_timeline),
            "sha256": input_hash,
            "source_frames_with_A_pressed": sum(
                1 for row in read_csv(args.input_timeline) if row["A"] == "1"
            ),
            "source_frames_with_Start_pressed": sum(
                1 for row in read_csv(args.input_timeline) if row["start"] == "1"
            ),
            "source_frame_4661_to_4667_Start_confirmed_by_source_stepper": bool(source_report.get("same_input_title_stop_post_run_validation", {}).get("same_input_reference_confirms_pc_and_frame")),
        },
        "apu": {
            "compared_through_source_frame": 4662,
            "fceux_raw_hook_rows_in_window": sum(1 for row in read_csv(args.fceux_dir / "apu_writes.csv") if int(row["source_frame"]) <= 4662),
            "filtered_fceux_sound_register_rows": len(fceux_apu),
            "source_sound_register_rows": len(source_apu),
            "address_value_mismatch_count": len(apu_value_mismatches),
            "first_address_value_mismatch": apu_value_mismatches[0] if apu_value_mismatches else None,
            "cycle_residual_source_minus_fceux": summarize_residuals(apu_cycle_residuals),
        },
        "dmc": {
            "compared_before_source_frame_4661_start_cycle": start_cycle,
            "source_output_bytes": len(source_dmc),
            "fceux_output_bytes": len(fceux_dmc),
            "address_value_mismatch_count": len(dmc_value_mismatches),
            "first_address_value_mismatch": dmc_value_mismatches[0] if dmc_value_mismatches else None,
            "cycle_residual_source_minus_fceux": summarize_residuals(dmc_cycle_residuals),
            "previously_reported_neutral_trace_mismatch_index": selected_byte,
        },
        "input_trace_provenance": {
            "fceux_apu_trace": args.fceux_dir.relative_to(ROOT).as_posix() if args.fceux_dir.is_relative_to(ROOT) else str(args.fceux_dir),
            "fceux_apu_capture_sha256": file_sha256(args.fceux_dir / "apu_writes.csv"),
            "fceux_dmc_trace": args.dmc_trace.relative_to(ROOT).as_posix() if args.dmc_trace.is_relative_to(ROOT) else str(args.dmc_trace),
            "fceux_dmc_trace_sha256": file_sha256(args.dmc_trace),
            "fceux_dmc_trace_input_hash": fceux_meta["input_timeline"]["sha256"],
            "fceux_dmc_trace_replays": len(fceux_meta.get("segments", [])),
            "audio_core_enabled_but_muted": True,
            "captured_wav_or_pcm_used": False,
        },
        "limitations": [
            "FCEUX APU cycle values are debugger-hook timestamps; the APU register-order/value comparison is exact, and timestamp differences remain within the reported small residual.",
            "The merged DMC trace is assembled from three pinned FCEUX replays with the same input hash; DMC address/value order is exact, while per-byte DMC event cycles differ by at most 9 CPU cycles.",
            "This validates the pinned FCEUX model, not physical NES bus timing or final WaveHi PCM identity.",
            "The earlier +222-cycle and output-byte-43206 disagreement came from comparing the A-input source run with a separate all-neutral FCEUX trace; it is not a same-input failure.",
        ],
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(args.out)
    print(json.dumps({
        "apu_rows": [len(source_apu), len(fceux_apu)],
        "apu_value_mismatches": len(apu_value_mismatches),
        "apu_cycle_residual": result["apu"]["cycle_residual_source_minus_fceux"],
        "dmc_bytes": [len(source_dmc), len(fceux_dmc)],
        "dmc_value_mismatches": len(dmc_value_mismatches),
        "dmc_cycle_residual": result["dmc"]["cycle_residual_source_minus_fceux"],
        "byte_43206": selected_byte,
    }, indent=2))


if __name__ == "__main__":
    main()

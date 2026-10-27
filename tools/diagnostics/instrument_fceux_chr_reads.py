#!/usr/bin/env python3
"""Add an opt-in background CHR-read trace to the pinned FCEUX source tree.

This edits only src/ppu.cpp in the supplied FCEUX checkout. It creates a
one-time .pre_chr_trace.bak beside that file before writing the instrumented
source. The emitted trace is disabled unless FCEUX_CHR_READ_TRACE names an
output CSV path before FCEUX starts.
"""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


EXPECTED_COMMIT = "a6d03e7968bd77a8156a7c9b628a673753f2f4c6"

TRACE_HELPER = '''
// Opt-in diagnostic only. Set FCEUX_CHR_READ_TRACE to a writable CSV path.
// Keep the log limited to the raster region surrounding the observed split.
static void TraceCHRPlaneRead(uint32 address, uint8 value, int plane) {
\tstatic FILE *trace = nullptr;
\tstatic bool attempted_open = false;
\tif (!attempted_open) {
\t\tattempted_open = true;
\t\tconst char *path = std::getenv("FCEUX_CHR_READ_TRACE");
\t\tif (path && *path) {
\t\t\ttrace = std::fopen(path, "w");
\t\t\tif (trace) {
\t\t\t\tstd::fprintf(trace, "fceux_framectr,scanline,dot,plane,ppu_addr,ppu_data,chr_rom_offset,chr_1k_bank\\n");
\t\t\t\tstd::fflush(trace);
\t\t\t}
\t\t}
\t}
\tif (!trace || ppur.status.sl < 132 || ppur.status.sl > 135)
\t\treturn;
\taddress &= 0x1FFF;
\tconst int offset = static_cast<int>(&VPage[address >> 10][address] - CHRptr[0]);
\tstd::fprintf(trace, "%d,%d,%d,%d,$%04X,$%02X,%d,%d\\n",
\t\tframectr, ppur.status.sl, ppur.status.cycle, plane, address, value,
\t\toffset, offset >= 0 ? (offset >> 10) : -1);
\tstd::fflush(trace);
}
'''


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        raise RuntimeError(f"Expected exactly one {label} anchor, found {count}.")
    return source.replace(old, new, 1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fceux_source", type=Path, help="Pinned FCEUX source checkout root")
    args = parser.parse_args()

    source_root = args.fceux_source.expanduser().resolve()
    ppu_path = source_root / "src" / "ppu.cpp"
    if not ppu_path.is_file():
        raise SystemExit(f"FCEUX source file not found: {ppu_path}")
    try:
        commit = subprocess.check_output(
            ["git", "-C", str(source_root), "rev-parse", "HEAD"], text=True
        ).strip()
    except (OSError, subprocess.CalledProcessError) as exc:
        raise SystemExit(f"Could not identify the FCEUX source revision: {exc}") from exc
    if commit != EXPECTED_COMMIT:
        raise SystemExit(
            f"Refusing to edit FCEUX revision {commit}; expected {EXPECTED_COMMIT}."
        )

    source = ppu_path.read_text(encoding="utf-8")
    if "TraceCHRPlaneRead" in source:
        raise SystemExit("CHR-read instrumentation already appears in src/ppu.cpp.")

    source = replace_once(
        source,
        "static void CopySprites(uint8 *target);\n",
        "static void CopySprites(uint8 *target);\n"
        "static void TraceCHRPlaneRead(uint32 address, uint8 value, int plane);\n",
        "forward declaration",
    )

    read_calls = (
        ("pt[0] = CALL_PPUREAD(RefreshAddr | pecnt);", "TraceCHRPlaneRead(RefreshAddr | pecnt, pt[0], 0);"),
        ("pt[1] = CALL_PPUREAD(RefreshAddr | pecnt);", "TraceCHRPlaneRead(RefreshAddr | pecnt, pt[1], 1);"),
        ("pt[0] = *(CHRptr[0] + RefreshAddr);", "TraceCHRPlaneRead(RefreshAddr, pt[0], 0);"),
        ("pt[1] = *(CHRptr[0] + RefreshAddr);", "TraceCHRPlaneRead(RefreshAddr, pt[1], 1);"),
        ("pt[0] = CALL_PPUREAD(RefreshAddr);", "TraceCHRPlaneRead(RefreshAddr, pt[0], 0);"),
        ("pt[1] = CALL_PPUREAD(RefreshAddr);", "TraceCHRPlaneRead(RefreshAddr, pt[1], 1);"),
    )
    for call, trace_call in read_calls:
        source = replace_once(source, call, call + "\n\t\t\t\t" + trace_call, call)

    source = replace_once(
        source,
        "int framectr = 0;\nint FCEUX_PPU_Loop(int skip) {",
        "int framectr = 0;\n" + TRACE_HELPER + "\nint FCEUX_PPU_Loop(int skip) {",
        "frame-counter helper insertion",
    )

    backup_path = ppu_path.with_suffix(ppu_path.suffix + ".pre_chr_trace.bak")
    try:
        with backup_path.open("xb") as backup:
            backup.write(ppu_path.read_bytes())
    except FileExistsError as exc:
        raise SystemExit(f"Backup already exists; refusing to overwrite: {backup_path}") from exc
    ppu_path.write_text(source, encoding="utf-8")
    print(f"Instrumented: {ppu_path}")
    print(f"Original saved: {backup_path}")
    print("Enable the trace by setting FCEUX_CHR_READ_TRACE before launch.")


if __name__ == "__main__":
    main()

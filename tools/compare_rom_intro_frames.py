#!/usr/bin/env python3
"""Compare ROM-rendered frames with FCEUX GD observations (validation only)."""

from __future__ import annotations

import argparse
import csv
import struct
import zlib
from pathlib import Path

try:
    import numpy as np
except ImportError:  # NumPy is an optional speedup, not a project dependency.
    np = None

try:
    from PIL import Image as PILImage
except ImportError:  # Pillow keeps the PNG decoder self-contained when absent.
    PILImage = None

WIDTH = 256
HEIGHT = 240


def png_rgb(path: Path) -> bytes:
    if PILImage is not None:
        with PILImage.open(path) as image:
            return image.convert("RGB").tobytes()
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Not PNG: {path}")
    position = 8
    chunks = []
    width = height = bit_depth = color_type = interlace = None
    while position < len(data):
        length = struct.unpack(">I", data[position:position + 4])[0]
        kind = data[position + 4:position + 8]
        payload = data[position + 8:position + 8 + length]
        if kind == b"IHDR":
            width, height, bit_depth, color_type, compression, filter_method, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
            if compression != 0 or filter_method != 0:
                raise ValueError(f"Unsupported PNG compression/filter method: {path}")
        elif kind == b"IDAT":
            chunks.append(payload)
        position += length + 12
    if width != WIDTH or height != HEIGHT:
        raise ValueError(f"Unexpected PNG dimensions: {path}")
    if bit_depth != 8 or color_type not in (2, 6) or interlace != 0:
        raise ValueError(f"PNG must be noninterlaced 8-bit RGB/RGBA: {path}")
    bytes_per_pixel = 3 if color_type == 2 else 4
    decoded = zlib.decompress(b"".join(chunks))
    row_bytes = WIDTH * bytes_per_pixel
    row_length = row_bytes + 1
    if len(decoded) != HEIGHT * row_length:
        raise ValueError(f"Unexpected PNG size: {path}")

    if np is not None:
        encoded_rows = np.frombuffer(decoded, dtype=np.uint8).reshape(HEIGHT, row_length)
        reconstructed = np.empty((HEIGHT, row_bytes), dtype=np.uint8)
        prior = np.zeros(row_bytes, dtype=np.uint8)
        for row in range(HEIGHT):
            filter_type = int(encoded_rows[row, 0])
            filtered = encoded_rows[row, 1:]
            if filter_type == 0:
                current = filtered.copy()
            elif filter_type == 1:
                # PNG Sub predicts from the prior pixel, independently for
                # each channel. Cumulative sums reproduce byte-wise wraparound.
                channel_rows = filtered.reshape(WIDTH, bytes_per_pixel)
                current = (np.cumsum(channel_rows, axis=0, dtype=np.uint64) & 0xFF).astype(np.uint8).reshape(row_bytes)
            elif filter_type == 2:
                current = (filtered.astype(np.uint16) + prior.astype(np.uint16)).astype(np.uint8)
            elif filter_type in (3, 4):
                # Average and Paeth depend on the already reconstructed left
                # byte. Keep the exact reference implementation for these rows.
                current = np.frombuffer(_unfilter_png_row(
                    filtered.tobytes(), prior.tobytes(), bytes_per_pixel, filter_type
                ), dtype=np.uint8)
            else:
                raise ValueError(f"Unsupported PNG row filter {filter_type}: {path}")
            reconstructed[row] = current
            prior = current

        if color_type == 2:
            return reconstructed.tobytes()
        return reconstructed.reshape(HEIGHT, WIDTH, 4)[:, :, :3].tobytes()

    rgb = bytearray()
    prior = bytearray(row_bytes)
    for row in range(HEIGHT):
        start = row * row_length
        filter_type = decoded[start]
        filtered = decoded[start + 1:start + row_length]
        if filter_type not in (0, 1, 2, 3, 4):
            raise ValueError(f"Unsupported PNG row filter {filter_type}: {path}")
        current = _unfilter_png_row(filtered, prior, bytes_per_pixel, filter_type)
        if color_type == 2:
            rgb.extend(current)
        else:
            for index in range(0, row_bytes, 4):
                rgb.extend(current[index:index + 3])
        prior = current
    return bytes(rgb)


def _unfilter_png_row(filtered: bytes | bytearray, prior: bytes | bytearray,
                      bytes_per_pixel: int, filter_type: int) -> bytearray:
    """Apply one PNG row filter with the original byte-exact arithmetic."""
    current = bytearray(len(filtered))
    for index, filtered_value in enumerate(filtered):
        left = current[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
        up = prior[index]
        upper_left = prior[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
        if filter_type == 0:
            predictor = 0
        elif filter_type == 1:
            predictor = left
        elif filter_type == 2:
            predictor = up
        elif filter_type == 3:
            predictor = (left + up) // 2
        else:  # Paeth, filter type 4.
            estimate = left + up - upper_left
            distance_left = abs(estimate - left)
            distance_up = abs(estimate - up)
            distance_upper_left = abs(estimate - upper_left)
            if distance_left <= distance_up and distance_left <= distance_upper_left:
                predictor = left
            elif distance_up <= distance_upper_left:
                predictor = up
            else:
                predictor = upper_left
        current[index] = (filtered_value + predictor) & 0xFF
    return current


def gd_rgb(path: Path) -> bytes:
    data = path.read_bytes()
    if len(data) != 11 + WIDTH * HEIGHT * 4:
        raise ValueError(f"Unexpected FCEUX GD size: {path}")
    if np is not None:
        rgba = np.frombuffer(data, dtype=np.uint8, offset=11).reshape(HEIGHT, WIDTH, 4)
        return rgba[:, :, 1:4].tobytes()
    return b"".join(data[position + 1:position + 4]
                    for position in range(11, len(data), 4))


def compare(candidate: bytes, reference: bytes,
            ignore_rects: list[tuple[int, int, int, int]] | None = None
            ) -> tuple[float, float, int, int, int]:
    ignore_rects = ignore_rects or []
    if np is not None:
        candidate_rgb = np.frombuffer(candidate, dtype=np.uint8).reshape(HEIGHT, WIDTH, 3)
        reference_rgb = np.frombuffer(reference, dtype=np.uint8).reshape(HEIGHT, WIDTH, 3)
        compared_mask = np.ones((HEIGHT, WIDTH), dtype=np.bool_)
        for rect_x, rect_y, rect_width, rect_height in ignore_rects:
            compared_mask[rect_y:rect_y + rect_height, rect_x:rect_x + rect_width] = False
        exact_mask = np.all(candidate_rgb == reference_rgb, axis=2)
        foreground_mask = np.any(candidate_rgb != 0, axis=2) | np.any(reference_rgb != 0, axis=2)
        compared_pixels = int(np.count_nonzero(compared_mask))
        ignored_pixels = WIDTH * HEIGHT - compared_pixels
        exact = int(np.count_nonzero(exact_mask & compared_mask))
        foreground_union = int(np.count_nonzero(foreground_mask & compared_mask))
        foreground_exact = int(np.count_nonzero(exact_mask & foreground_mask & compared_mask))
        return (exact / compared_pixels if compared_pixels else 1.0,
                foreground_exact / foreground_union if foreground_union else 1.0,
                foreground_union, compared_pixels, ignored_pixels)

    exact = 0
    foreground_exact = 0
    foreground_union = 0
    compared_pixels = 0
    ignored_pixels = 0
    black = b"\x00\x00\x00"
    for position in range(0, len(candidate), 3):
        pixel = position // 3
        x, y = pixel % WIDTH, pixel // WIDTH
        if any(rect_x <= x < rect_x + rect_width
               and rect_y <= y < rect_y + rect_height
               for rect_x, rect_y, rect_width, rect_height in ignore_rects):
            ignored_pixels += 1
            continue
        actual = candidate[position:position + 3]
        expected = reference[position:position + 3]
        compared_pixels += 1
        matching = actual == expected
        exact += matching
        if actual != black or expected != black:
            foreground_union += 1
            foreground_exact += matching
    return (exact / compared_pixels if compared_pixels else 1.0,
            foreground_exact / foreground_union if foreground_union else 1.0,
            foreground_union, compared_pixels, ignored_pixels)


def parse_ignore_rect(value: str) -> tuple[int, int, int, int]:
    try:
        x, y, width, height = (int(part, 10) for part in value.split(","))
    except ValueError as exc:
        raise argparse.ArgumentTypeError("expected x,y,width,height") from exc
    if (width <= 0 or height <= 0 or x < 0 or y < 0
            or x + width > WIDTH or y + height > HEIGHT):
        raise argparse.ArgumentTypeError("rectangle must fit within the 256x240 frame")
    return x, y, width, height


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--render-dir", type=Path, required=True)
    reference_group = parser.add_mutually_exclusive_group(required=True)
    reference_group.add_argument(
        "--screens-dir", type=Path,
        help="Directory containing same-numbered frame_NNNNNN.gd references",
    )
    reference_group.add_argument(
        "--screen-index", type=Path,
        help="FCEUX screen_index.csv mapping every source frame to a deduplicated raw GD screen",
    )
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--ignore-rect", type=parse_ignore_rect, action="append", default=[],
                        metavar="X,Y,W,H",
                        help="Exclude a documented emulator overlay region from pixel metrics")
    args = parser.parse_args()
    frame_to_reference: dict[int, Path] = {}
    if args.screen_index is not None:
        with args.screen_index.open(newline="", encoding="utf-8") as stream:
            reader = csv.DictReader(stream)
            if not reader.fieldnames or "source_frame" not in reader.fieldnames:
                raise SystemExit(f"No source_frame column in {args.screen_index}")
            if "raw_screen_file" not in reader.fieldnames:
                raise SystemExit(f"No raw_screen_file column in {args.screen_index}")
            for row in reader:
                try:
                    frame = int(row["source_frame"])
                except (KeyError, TypeError, ValueError):
                    continue
                raw_name = row.get("raw_screen_file", "")
                if not raw_name:
                    continue
                raw_path = args.screen_index.parent / raw_name
                if not raw_path.is_file():
                    raw_path = args.screen_index.parent / "unique_screens" / raw_name
                frame_to_reference[frame] = raw_path
    rows = []
    for candidate in sorted(args.render_dir.glob("frame_*.png")):
        frame = int(candidate.stem.removeprefix("frame_"))
        if args.screen_index is not None:
            reference = frame_to_reference.get(frame)
            if reference is None:
                continue
        else:
            reference = args.screens_dir / f"frame_{frame:06d}.gd"
        if not reference.is_file():
            continue
        exact, foreground, union, compared, ignored = compare(
            png_rgb(candidate), gd_rgb(reference), args.ignore_rect
        )
        rows.append((frame, exact, foreground, union, compared, ignored))
    if not rows:
        raise SystemExit("No rendered frames matched a same-numbered FCEUX GD reference.")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(["frame", "exact_rgb_fraction", "foreground_union_exact_fraction",
                         "foreground_union_pixels", "compared_pixels", "ignored_pixels"])
        writer.writerows(rows)
    print(f"Compared {len(rows)} frames: RGB mean "
          f"{sum(row[1] for row in rows) / len(rows):.4f}; foreground mean "
          f"{sum(row[2] for row in rows) / len(rows):.4f}")
    print(f"Lowest RGB: {min(rows, key=lambda row: row[1])[:3]}; "
          f"lowest foreground: {min(rows, key=lambda row: row[2])[:3]}")


if __name__ == "__main__":
    main()

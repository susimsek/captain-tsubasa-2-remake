#!/usr/bin/env python3
"""Fetch only the Godot export-template archive members used by this release."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import stat
import struct
import tempfile
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path


EOCD_SIGNATURE = b"PK\x05\x06"
CENTRAL_SIGNATURE = b"PK\x01\x02"
LOCAL_SIGNATURE = b"PK\x03\x04"
MAX_EOCD_SEARCH = 22 + 65535
USER_AGENT = "captain-tsubasa-2-remake-ci"
REQUIRED_MEMBERS = {
    "templates/linux_release.x86_64": "linux_release.x86_64",
    "templates/windows_release_x86_64.exe": "windows_release_x86_64.exe",
    "templates/macos.zip": "macos.zip",
    "templates/version.txt": "version.txt",
}


def fetch_range(url: str, start: int, end: int, expected_total: int | None = None) -> tuple[bytes, int]:
    request = urllib.request.Request(
        url,
        headers={
            "Accept-Encoding": "identity",
            "Range": f"bytes={start}-{end}",
            "User-Agent": USER_AGENT,
        },
    )
    last_error: Exception | None = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                content_range = response.headers.get("Content-Range", "")
                match = re.fullmatch(r"bytes (\d+)-(\d+)/(\d+)", content_range)
                if response.status != 206 or match is None:
                    raise RuntimeError(
                        f"Godot release server did not honor byte range {start}-{end}: "
                        f"HTTP {response.status}, Content-Range={content_range!r}"
                    )
                actual_start, actual_end, total = map(int, match.groups())
                if (actual_start, actual_end) != (start, end):
                    raise RuntimeError(
                        f"Godot release server returned unexpected range "
                        f"{actual_start}-{actual_end}; expected {start}-{end}"
                    )
                if expected_total is not None and total != expected_total:
                    raise RuntimeError(
                        f"Godot template archive size changed during download: "
                        f"{total} bytes, expected {expected_total}"
                    )
                data = response.read()
                if len(data) != end - start + 1:
                    raise RuntimeError(
                        f"Incomplete Godot template range {start}-{end}: "
                        f"received {len(data)} bytes"
                    )
                return data, total
        except (OSError, urllib.error.URLError, RuntimeError) as error:
            last_error = error
            if attempt < 2:
                time.sleep(2**attempt)
    raise RuntimeError(f"Unable to fetch Godot template archive range: {last_error}") from last_error


def parse_central_directory(data: bytes, expected_entries: int) -> dict[str, tuple[int, int, int, int]]:
    entries: dict[str, tuple[int, int, int, int]] = {}
    cursor = 0
    seen_entries = 0
    while cursor < len(data):
        if cursor + 46 > len(data):
            raise RuntimeError("Truncated Godot template ZIP central directory")
        fields = struct.unpack_from("<4s6H3L5H2L", data, cursor)
        if fields[0] != CENTRAL_SIGNATURE:
            raise RuntimeError(f"Invalid Godot template ZIP central directory at byte {cursor}")

        flags = fields[3]
        compression = fields[4]
        compressed_size = fields[8]
        uncompressed_size = fields[9]
        name_length = fields[10]
        extra_length = fields[11]
        comment_length = fields[12]
        disk_number = fields[13]
        local_header_offset = fields[16]
        end = cursor + 46 + name_length + extra_length + comment_length
        if end > len(data):
            raise RuntimeError("Truncated Godot template ZIP directory entry")

        raw_name = data[cursor + 46 : cursor + 46 + name_length]
        name = raw_name.decode("utf-8" if flags & 0x800 else "cp437")
        if name in REQUIRED_MEMBERS:
            if disk_number != 0:
                raise RuntimeError(f"Godot template member is on an unsupported ZIP disk: {name}")
            if compressed_size == 0xFFFFFFFF or uncompressed_size == 0xFFFFFFFF or local_header_offset == 0xFFFFFFFF:
                raise RuntimeError(f"ZIP64 Godot template member is not supported by this downloader: {name}")
            if flags & 1:
                raise RuntimeError(f"Encrypted Godot template member is not supported: {name}")
            if compression not in (0, 8):
                raise RuntimeError(f"Unsupported compression method for Godot template member: {name}")
            if name in entries:
                raise RuntimeError(f"Duplicate Godot template archive member: {name}")
            entries[name] = (
                compressed_size,
                uncompressed_size,
                local_header_offset,
                compression,
            )

        cursor = end
        seen_entries += 1

    if cursor != len(data) or seen_entries != expected_entries:
        raise RuntimeError(
            f"Unexpected Godot template ZIP directory structure: "
            f"parsed {seen_entries} of {expected_entries} entries"
        )
    missing = REQUIRED_MEMBERS.keys() - entries.keys()
    if missing:
        raise RuntimeError(f"Godot template archive is missing required members: {', '.join(sorted(missing))}")
    return entries


def write_github_outputs(downloaded_bytes: int, archive_size: int) -> None:
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return
    with open(output_path, "a", encoding="utf-8") as output:
        output.write(f"range_downloaded_bytes={downloaded_bytes}\n")
        output.write(f"archive_size_bytes={archive_size}\n")


def download_templates(version: str, expected_archive_size: int, output_dir: Path) -> None:
    url = (
        f"https://github.com/godotengine/godot/releases/download/"
        f"{version}-stable/Godot_v{version}-stable_export_templates.tpz"
    )
    downloaded_bytes = 0

    probe, archive_size = fetch_range(url, 0, 0)
    downloaded_bytes += len(probe)
    if archive_size != expected_archive_size:
        raise RuntimeError(
            f"Godot {version} template archive is {archive_size} bytes; "
            f"update the pinned archive size from {expected_archive_size}"
        )

    tail_start = max(0, archive_size - MAX_EOCD_SEARCH)
    tail, _ = fetch_range(url, tail_start, archive_size - 1, archive_size)
    downloaded_bytes += len(tail)
    eocd_offset = tail.rfind(EOCD_SIGNATURE)
    if eocd_offset < 0 or eocd_offset + 22 > len(tail):
        raise RuntimeError("Could not locate the Godot template ZIP end-of-directory record")
    eocd = struct.unpack_from("<4s4H2LH", tail, eocd_offset)
    disk_number, central_disk = eocd[1], eocd[2]
    entries_on_disk, entry_count = eocd[3], eocd[4]
    central_size, central_offset, comment_length = eocd[5], eocd[6], eocd[7]
    if eocd_offset + 22 + comment_length != len(tail):
        raise RuntimeError("Godot template ZIP has an invalid end-of-directory record")
    if disk_number != 0 or central_disk != 0 or entries_on_disk != entry_count:
        raise RuntimeError("Multi-disk Godot template ZIP archives are not supported")
    if entry_count == 0xFFFF or central_size == 0xFFFFFFFF or central_offset == 0xFFFFFFFF:
        raise RuntimeError("ZIP64 Godot template archives are not supported by this downloader")
    if central_offset + central_size > archive_size:
        raise RuntimeError("Godot template ZIP central directory lies outside the archive")

    central_directory, _ = fetch_range(
        url,
        central_offset,
        central_offset + central_size - 1,
        archive_size,
    )
    downloaded_bytes += len(central_directory)
    entries = parse_central_directory(central_directory, entry_count)

    output_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        prefix=f"godot-{version}-templates-",
        suffix=".tpz",
        dir=os.environ.get("RUNNER_TEMP"),
    ) as archive:
        archive.truncate(archive_size)
        archive.seek(tail_start)
        archive.write(tail)
        archive.seek(central_offset)
        archive.write(central_directory)

        for member, (compressed_size, _uncompressed_size, local_offset, _compression) in entries.items():
            local_header, _ = fetch_range(url, local_offset, local_offset + 29, archive_size)
            downloaded_bytes += len(local_header)
            header = struct.unpack("<4s5H3L2H", local_header)
            if header[0] != LOCAL_SIGNATURE:
                raise RuntimeError(f"Invalid local ZIP header for Godot template member: {member}")
            local_name_length, local_extra_length = header[9], header[10]
            data_offset = local_offset + 30 + local_name_length + local_extra_length
            data_end = data_offset + compressed_size
            if data_end > archive_size:
                raise RuntimeError(f"Godot template member exceeds the archive bounds: {member}")
            payload, _ = fetch_range(url, local_offset + 30, data_end - 1, archive_size)
            downloaded_bytes += len(payload)
            archive.seek(local_offset)
            archive.write(local_header)
            archive.write(payload)
        archive.flush()

        with zipfile.ZipFile(archive.name) as templates:
            for member in REQUIRED_MEMBERS:
                info = templates.getinfo(member)
                unix_mode = info.external_attr >> 16
                if info.is_dir() or stat.S_ISLNK(unix_mode):
                    raise RuntimeError(f"Unexpected non-file Godot template member: {member}")

            version_text = templates.read("templates/version.txt").decode("ascii").strip()
            expected_version = f"{version}.stable"
            if version_text != expected_version:
                raise RuntimeError(
                    f"Godot template version mismatch: found {version_text!r}, expected {expected_version!r}"
                )

            with tempfile.TemporaryDirectory(prefix="godot-template-extract-", dir=output_dir.parent) as staging_name:
                staging_dir = Path(staging_name)
                for member, filename in REQUIRED_MEMBERS.items():
                    staged_path = staging_dir / filename
                    with templates.open(member) as source, staged_path.open("wb") as destination:
                        shutil.copyfileobj(source, destination, length=4 * 1024 * 1024)
                    expected_size = templates.getinfo(member).file_size
                    if staged_path.stat().st_size != expected_size:
                        raise RuntimeError(f"Unexpected extracted size for Godot template member: {member}")
                for filename in REQUIRED_MEMBERS.values():
                    os.replace(staging_dir / filename, output_dir / filename)

    write_github_outputs(downloaded_bytes, archive_size)
    saved_percent = (1 - downloaded_bytes / archive_size) * 100
    print(
        f"Fetched {downloaded_bytes:,} of {archive_size:,} archive bytes "
        f"({saved_percent:.1f}% less network data than downloading the full archive)."
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="Pinned Godot version, for example 4.7.2")
    parser.add_argument("--expected-archive-size", required=True, type=int)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        parser.error("--version must be a stable semantic version such as 4.7.2")
    if args.expected_archive_size <= 0:
        parser.error("--expected-archive-size must be a positive byte count")
    download_templates(args.version, args.expected_archive_size, args.output_dir)


if __name__ == "__main__":
    main()

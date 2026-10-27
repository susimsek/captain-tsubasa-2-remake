#!/usr/bin/env python3
"""Bounded ROM/PPU-event renderer for diagnostic intro frames.

This is deliberately not a NES PPU implementation. It replays captured
$2000/$2002/$2005/$2006/$2007 and MMC3 writes, tracks loopy v/t/x/w, renders
background pixels from original CHR-ROM, and uses the capture's PPU/RAM state
for layout and sprites. It approximates the background fetch pipeline and
sprite evaluation; output must remain diagnostic and must never be packaged as
a runtime asset without further validation.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sys
from dataclasses import dataclass
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS_DIR))

from render_emulator_ppu_frame import decode_tiles, encode_png, read_palette_file, render_sprites
from render_rom_frame import CHR_BANK, extract_chr
from render_timing_capture_raster_frame import ppu_snapshot_legacy_layout
from plan_rom_raster_bands import State as Mmc3State, apply_write as apply_mmc3_write

WIDTH, HEIGHT = 256, 240
RAM_FRAME_OFFSET = -1


@dataclass
class PpuRegisters:
	ctrl: int = 0
	mask: int = 0
	t: int = 0
	v: int = 0
	x: int = 0
	w: int = 0

	def write(self, address: int, value: int) -> None:
		if address == 0x2000:
			self.ctrl = value
			self.t = (self.t & ~0x0C00) | ((value & 0x03) << 10)
		elif address == 0x2001:
			self.mask = value
		elif address == 0x2002:
			self.w = 0
		elif address == 0x2005:
			if self.w == 0:
				self.x = value & 0x07
				self.t = (self.t & ~0x001F) | (value >> 3)
				self.w = 1
			else:
				self.t = (self.t & ~0x73E0) | ((value & 0x07) << 12) | ((value & 0xF8) << 2)
				self.w = 0
		elif address == 0x2006:
			if self.w == 0:
				self.t = (self.t & 0x00FF) | ((value & 0x3F) << 8)
				self.w = 1
			else:
				self.t = (self.t & 0x7F00) | value
				self.v = self.t
				self.w = 0


def load_capture(capture: Path) -> tuple[dict[int, dict[str, str]], dict[int, list[dict[str, str]]]]:
	frames: dict[int, dict[str, str]] = {}
	with (capture / "frames.csv").open(newline="", encoding="utf-8") as stream:
		for row in csv.DictReader(stream):
			frames[int(row["source_frame"])] = row
	events: dict[int, list[dict[str, str]]] = {}
	with (capture / "bus_events.csv").open(newline="", encoding="utf-8") as stream:
		for row in csv.DictReader(stream):
			frame = int(row["source_frame"])
			events.setdefault(frame, []).append(row)
	for rows in events.values():
		rows.sort(key=lambda row: (int(row["cycle_from_frame_start"]), int(row["cycle_absolute"])))
	return frames, events


def ppu_memory_write(memory: bytearray, address: int, value: int) -> None:
	address &= 0x3FFF
	if address < 0x3F00:
		# The normalized buffer retains the full 4 KiB nametable window.
		address &= 0x2FFF
		if address >= 0x3000:
			address -= 0x1000
		memory[address] = value
	else:
		index = address & 0x1F
		if index in (0x10, 0x14, 0x18, 0x1C):
			index -= 0x10
		memory[0x3000 + index] = value & 0x3F


def apply_ppudata(memory: bytearray, regs: PpuRegisters, value: int) -> None:
	ppu_memory_write(memory, regs.v, value)
	regs.v = (regs.v + (32 if regs.ctrl & 0x04 else 1)) & 0x7FFF


def banks_for_state(state: Mmc3State) -> list[int]:
	return state.chr_slots()


def chr_byte(chr_rom: bytes, slots: list[int], address: int) -> int:
	address &= 0x1FFF
	slot, offset = divmod(address, CHR_BANK)
	return chr_rom[slots[slot] * CHR_BANK + offset]


class PixelDecoder:
	def __init__(self, chr_rom: bytes, ppu_memory: bytearray, mmc3: Mmc3State,
				 regs: PpuRegisters):
		self.chr_rom = chr_rom
		self.ppu_memory = ppu_memory
		self.mmc3 = mmc3
		self.regs = regs
		self.cache: dict[tuple[tuple[int, ...], int, int], list[list[int]]] = {}

	def pixel(self, v: int, fine_x: int, screen_x: int) -> tuple[int, bool]:
		coarse_y = (v >> 5) & 0x1F
		nt_y = (v >> 11) & 1
		fine_y = (v >> 12) & 0x07
		world_x = (v & 0x1F) * 8 + fine_x + screen_x
		nt_x = (v >> 10) & 1
		coarse_x = (world_x // 8) & 0x1F
		page_x = (nt_x + world_x // 256) & 1
		page_offset = (page_x | (nt_y << 1)) * 0x400
		name_offset = page_offset + coarse_y * 32 + coarse_x
		tile = self.ppu_memory[0x2000 + name_offset]
		attribute_offset = page_offset + 960 + (coarse_y // 4) * 8 + (coarse_x // 4)
		attribute = self.ppu_memory[0x2000 + attribute_offset]
		shift = ((coarse_y & 2) << 1) | (coarse_x & 2)
		subpalette = (attribute >> shift) & 3
		fine_column = world_x & 7
		pattern_base = 0x1000 if self.regs.ctrl & 0x10 else 0
		bank_key = tuple(banks_for_state(self.mmc3))
		key = (bank_key, tile, pattern_base)
		decoded = self.cache.get(key)
		if decoded is None:
			start = pattern_base + tile * 16
			pixels: list[list[int]] = []
			for row in range(8):
				low = chr_byte(self.chr_rom, list(bank_key), start + row)
				high = chr_byte(self.chr_rom, list(bank_key), start + row + 8)
				pixels.append([
					((low >> (7 - col)) & 1) | (((high >> (7 - col)) & 1) << 1)
					for col in range(8)
				])
			decoded = pixels
			self.cache[key] = decoded
		color = decoded[fine_y][fine_column]
		if color == 0:
			return self.ppu_memory[0x3000] & 0x3F, False
		return self.ppu_memory[0x3000 + subpalette * 4 + color] & 0x3F, True


def increment_y(v: int) -> int:
	if ((v >> 12) & 7) != 7:
		return (v + 0x1000) & 0x7FFF
	v &= ~0x7000
	coarse_y = (v >> 5) & 0x1F
	if coarse_y == 29:
		coarse_y = 0
		v ^= 0x0800
	elif coarse_y == 31:
		coarse_y = 0
	else:
		coarse_y += 1
	v = (v & ~0x03E0) | (coarse_y << 5)
	return v


def apply_event(row: dict[str, str], regs: PpuRegisters, memory: bytearray,
				mmc3: Mmc3State) -> None:
	address = int(row["address"].removeprefix("$"), 16)
	value = int(row["value"].removeprefix("$"), 16)
	event = row["event"]
	if address in (0x2000, 0x2001, 0x2002, 0x2005, 0x2006):
		regs.write(address, value)
	elif address == 0x2007 and event == "PPUDATA_write":
		apply_ppudata(memory, regs, value)
	elif address in (0x8000, 0x8001):
		apply_mmc3_write(mmc3, address, value)


def render_frame(frame: int, capture: Path, frames: dict[int, dict[str, str]],
				 events: dict[int, list[dict[str, str]]], chr_rom: bytes,
				 palette: list[tuple[int, int, int]], output_dir: Path,
				 rom_sha256: str) -> dict[str, object]:
	if frame not in frames:
		raise ValueError(f"Missing capture frame {frame}")
	row = frames[frame]
	prev_frame = max(0, frame + RAM_FRAME_OFFSET)
	prev_row = frames[prev_frame]
	# Begin from the previous PPU memory snapshot and replay this frame's writes.
	previous_ppu = ppu_snapshot_legacy_layout(capture / "ppu_states" / prev_row["ppu_file"])
	ppu_memory = bytearray(previous_ppu)
	ram = (capture / "ram_states" / prev_row["ram_file"]).read_bytes()
	# MMC3 register values are reconstructed from all logged writes through this
	# frame. PPU and screenshot data are not used to select CHR banks.
	mmc3 = Mmc3State()
	for f in sorted(events):
		if f > frame:
			break
		for ev in events[f]:
			address = int(ev["address"].removeprefix("$"), 16)
			if address in (0x8000, 0x8001):
				apply_event(ev, PpuRegisters(), ppu_memory, mmc3)
	# Use captured game-authored nametable/palette state at the frame boundary as
	# the authoritative base; target-frame $2007 events are then replayed into it.
	frame_ppu = ppu_snapshot_legacy_layout(capture / "ppu_states" / row["ppu_file"])
	ppu_memory[0x2000:0x3000] = frame_ppu[0x2000:0x3000]
	ppu_memory[0x3000:0x3020] = frame_ppu[0x3000:0x3020]
	# Keep the original per-frame CHR memory only as a matching check/diagnostic;
	# displayed tile pixels always come from the supplied ROM's CHR banks.
	for slot, bank in enumerate(mmc3.chr_slots()):
		start = slot * CHR_BANK
		ppu_memory[start:start + CHR_BANK] = chr_rom[bank * CHR_BANK:(bank + 1) * CHR_BANK]
	regs = PpuRegisters()
	frame_events = events.get(frame, [])
	visible_events: dict[int, list[dict[str, str]]] = {}
	prerender_events: list[dict[str, str]] = []
	for ev in frame_events:
		line = int(ev["ppu_scanline"])
		if line >= 240:
			prerender_events.append(ev)
		elif 0 <= line < HEIGHT:
			visible_events.setdefault(line, []).append(ev)
	for ev in prerender_events:
		apply_event(ev, regs, ppu_memory, mmc3)
	# Approximate pre-render transfer of temporary loopy address to v.
	regs.v = regs.t
	decoder = PixelDecoder(chr_rom, ppu_memory, mmc3, regs)
	indices = [ppu_memory[0x3000] & 0x3F] * (WIDTH * HEIGHT)
	opaque = [False] * (WIDTH * HEIGHT)
	for y in range(HEIGHT):
		line_events = visible_events.get(y, [])
		line_events.sort(key=lambda ev: int(ev["ppu_dot"]))
		cursor = 0
		for x in range(WIDTH):
			# FCEUX reports the PPU dot at the CPU bus callback. Dot 1 maps to
			# visible x=0. Writes after dot 256 are deferred to next scanline.
			while cursor < len(line_events) and int(line_events[cursor]["ppu_dot"]) <= x + 1:
				apply_event(line_events[cursor], regs, ppu_memory, mmc3)
				cursor += 1
			if not (regs.mask & 0x08) or (x < 8 and not (regs.mask & 0x02)):
				color, nonzero = ppu_memory[0x3000] & 0x3F, False
			else:
				color, nonzero = decoder.pixel(regs.v, regs.x, x)
			indices[y * WIDTH + x] = color
			opaque[y * WIDTH + x] = nonzero
		# The PPU increments vertical scroll at dot 256 and copies horizontal
		# scroll at dot 257. Apply CPU bus writes later in hblank afterward, so a
		# $2006 write at dot 290 can set the starting address for the next row.
		regs.v = increment_y(regs.v)
		regs.v = (regs.v & ~0x041F) | (regs.t & 0x041F)
		while cursor < len(line_events):
			apply_event(line_events[cursor], regs, ppu_memory, mmc3)
			cursor += 1
	# Remap pattern bytes to the final traced MMC3 bank state for the sprite
	# pass. This still cannot represent a bank change already latched by the PPU
	# fetch pipeline during an individual sprite tile fetch.
	for slot, bank in enumerate(mmc3.chr_slots()):
		start = slot * CHR_BANK
		ppu_memory[start:start + CHR_BANK] = chr_rom[bank * CHR_BANK:(bank + 1) * CHR_BANK]
	# The sprite layer is composited from the preceding frame's OAM shadow. This
	# does not emulate per-scanline OAM evaluation or sprite-zero timing.
	indices = render_sprites(bytes(ppu_memory), ram, indices, opaque,
						 enabled=bool(regs.mask & 0x10), sprite_height=8,
						 pattern_base=0x1000 if regs.ctrl & 0x08 else 0,
						 y_offset=1)
	output_dir.mkdir(parents=True, exist_ok=True)
	image_path = output_dir / f"frame_{frame:06d}_loopy_poc.png"
	encode_png(image_path, (palette[index] for index in indices))
	metadata = {
		"status": "diagnostic-only bounded model; not runtime asset",
		"source_frame": frame,
		"emulator_frame_after": int(row["emulator_frame_after"]),
		"script_frame": int(row["script_frame"]),
		"rom_sha256": rom_sha256,
		"rom_chr_file_offset": "0x40010",
		"frame_ppu_source": row["ppu_file"],
		"base_ppu_memory_source_frame": prev_frame,
		"ram_source_frame": prev_frame,
		"palette_file_external_to_rom": "reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal",
		"render_input_screenshot_pixels": False,
		"model": "Replay target-frame $2000/$2002/$2005/$2006/$2007 and MMC3 register writes at captured scanline/dot; track loopy v/t/x/w; copy t to v at pre-render; use captured target-frame nametable/palette bytes and ROM CHR banks.",
		"remaining_gaps": [
			"Background fetch/shifter pipeline is approximated as immediate per-pixel tile lookup.",
			"Horizontal scroll is modeled with fine-X and line-end t-to-v copy, not the full 2C02 fetch/increment schedule.",
			"$2007 write address and PPUDATA increment are reconstructed from the bounded v model; target-frame captured nametable/palette is used as the base so mid-frame old/new memory contents are not distinguished.",
			"The CPU-RAM OAM shadow is from the preceding frame and sprite evaluation, sprite-zero hit, priority timing, and mid-frame OAM DMA are not modeled.",
			"MMC3 CHR bank timing is replayed at events, but pixel pipeline fetches may already have latched old bank bytes before a dot event."
		],
		"output": str(image_path)
	}
	(image_path.with_suffix(".json")).write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
	return metadata


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--rom", type=Path, required=True)
	parser.add_argument("--capture-dir", type=Path, required=True)
	parser.add_argument("--palette-file", type=Path, required=True)
	parser.add_argument("--output-dir", type=Path, required=True)
	parser.add_argument("--frames", type=int, nargs="+", default=[1108, 1510])
	args = parser.parse_args()
	frames, events = load_capture(args.capture_dir)
	chr_rom, _, _ = extract_chr(args.rom)
	rom_sha256 = hashlib.sha256(args.rom.read_bytes()).hexdigest()
	palette = read_palette_file(args.palette_file)
	for frame in args.frames:
		metadata = render_frame(frame, args.capture_dir, frames, events, chr_rom,
								palette, args.output_dir, rom_sha256)
		print(f"source_frame={frame} rendered={metadata['output']}")


if __name__ == "__main__":
	main()

#!/usr/bin/env python3
"""Execute the supplied ROM from reset with a ROM-only 6502/MMC3/DMC model.

This is a diagnostics-only source event generator. It does not read FCEUX traces
while running. FCEUX files are accepted only by the optional post-run compare.
Py65 1.2.0 is the pinned instruction engine; it is not a runtime dependency.
"""

from __future__ import annotations

import argparse
from bisect import bisect_right
import csv
import gzip
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ROM_PATH = ROOT / "Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
DEFAULT_OUT = ROOT / "reference/diagnostics/audio/rom_only_source_cpu_ppu_dmc_20261026"
FCEUX_TRACE = ROOT / "reference/diagnostics/audio/rom_source_sound_execution_20261026_112451_utc"
INPUT_TIMELINE = ROOT / "reference/opening_reference_capture/input_timeline.csv"
TITLE_PC_TRACE = ROOT / "reference/diagnostics/title_transition_pc_20261024_150231/pc_trace.csv"
TITLE_FRAME_STATE = ROOT / "reference/diagnostics/title_transition_pc_20261024_150231/frame_state.csv"
SOUND_EVENT_FIELDS = (
    "sequence", "event", "source_frame", "cycle", "edge_cycle", "hook_sequence",
    "hook_start_cycle", "hook_end_cycle", "hook_cycles", "pc", "opcode",
    "phase", "address", "value", "prg_bank_8k", "bit",
    "dmc_format", "dmc_period", "dmc_acc", "dmc_bit_count", "dmc_addr",
    "dmc_size", "dmc_shift", "dmc_have_dma", "dmc_have_sample", "dmc_dma_buf",
    "raw_dac", "dmc_acc_before", "dmc_bit_count_before", "dmc_shift_before",
    "dmc_have_dma_before", "dmc_have_sample_before", "dmc_dma_buf_before",
    "raw_dac_before", "dac_changed",
)

try:

    from py65.devices.mpu6502 import MPU
except ImportError as exc:
    raise SystemExit(
        "Py65 1.2.0 is required only for this diagnostic. Install it in a temporary "
        "environment: python3 -m venv /tmp/ct2_rom_stepper_venv && "
        "/tmp/ct2_rom_stepper_venv/bin/pip install py65==1.2.0"
    ) from exc


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_input_timeline(path: Path | None) -> dict[int, dict]:
    if path is None:
        return {}
    result = {}
    with path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            frame = int(row["frame"])
            result[frame] = {
                key: row[key] == "1"
                for key in ("up", "down", "left", "right", "A", "B", "start", "select")
            }
    return result


def load_event_cycle_windows(path: Path | None, radius: int) -> list[tuple[int, int]] | None:
    if path is None:
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    try:
        cycles = data["source_events"]["renderer_dmc_buffer_phase_conflicts"]["cycles"]
    except (KeyError, TypeError) as exc:
        raise ValueError("event-window JSON must contain source_events.renderer_dmc_buffer_phase_conflicts.cycles") from exc
    if not cycles or any(int(cycle) < 0 for cycle in cycles):
        raise ValueError("event-window cycle list must be nonempty and nonnegative")
    intervals = sorted((max(0, int(cycle) - radius), int(cycle) + radius) for cycle in cycles)
    merged: list[list[int]] = []
    for start, end in intervals:
        if merged and start <= merged[-1][1] + 1:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    return [(start, end) for start, end in merged]


class Machine:
    # Pinned FCEUX NTSC DMC period table (sound.cpp, revision in report).
    DMC_PERIODS = (428, 380, 340, 320, 286, 254, 226, 214, 190, 160, 142, 128, 106, 84, 72, 54)

    def __init__(self, rom: bytes, input_timeline: dict[int, dict] | None = None, sound_event_writer=None,
                 sound_event_cycle_windows: list[tuple[int, int]] | None = None, frame_update_writer=None,
                 cpu_instruction_writer=None, cpu_instruction_cycle_window: tuple[int, int] | None = None):
        self.rom = rom
        self.prg = rom[16:16 + 0x40000]
        if len(self.prg) != 0x40000:
            raise ValueError("expected 256 KiB PRG ROM")
        self.ram = bytearray((0, 0, 0, 0, 255, 255, 255, 255) * 256)
        self.prg_ram = bytearray((0, 0, 0, 0, 255, 255, 255, 255) * 1024)
        self.ppu_ram = bytearray(0x4000)
        self.oam = bytearray(256)
        self.ppu_regs = bytearray(8)
        self.ppu_status = 0
        self.ppu_latch = 0
        self.ppu_addr = 0
        self.ppu_vram_addr = 0
        self.ppu_w_toggle = 0
        self.vblank = False
        self.nmi_pending = False
        self.irq_pending = False
        self.mmc3_irq_events: list[dict] = []
        self.cpu_interrupt_events: list[dict] = []
        self.cpu_credit = 0
        self.cpu_cycles = 0
        self.hook_cycles = 0
        self.source_frame = 0
        self.frame_cycle_start = 0
        self.events: list[dict] = []
        self.dmc_events: list[dict] = []
        self.sound_event_writer = sound_event_writer
        self.sound_event_cycle_windows = sound_event_cycle_windows
        self.sound_event_window_starts = [start for start, _ in sound_event_cycle_windows] if sound_event_cycle_windows else []
        self.frame_update_writer = frame_update_writer
        self.cpu_instruction_writer = cpu_instruction_writer
        self.cpu_instruction_cycle_window = cpu_instruction_cycle_window
        self.cpu_instruction_sequence = 0
        self.deferred_instruction_events: list[dict] = []
        self.frame_update_sequence = 0
        self.frame_fhinc = 14915 * 24
        self.frame_fhcnt = self.frame_fhinc
        self.frame_counter = 0
        self.frame_mode = 0
        self.sound_event_sequence = 0
        self.sound_event_type_counts: dict[str, int] = {}
        self.sound_hook_sequence = 0
        self.current_sound_hook_context: dict | None = None
        self.current_sound_hook_buffer: list[dict] | None = None
        self.frame_stats: list[dict] = []
        self.dmc_format = 0
        self.dmc_addr_latch = 0
        self.dmc_size_latch = 0
        # FCEUSND_Power() reloads the NTSC period from DMCFormat after reset;
        # DMCFormat starts at 0, so the initial period is 428 CPU cycles.
        self.dmc_period = 428
        self.dmc_acc = 1
        self.dmc_bit_count = 0
        self.dmc_addr = 0
        self.dmc_size = 0
        self.dmc_shift = 0
        self.dmc_have_dma = False
        self.dmc_have_sample = False
        self.dmc_dma_buf = 0
        self.raw_dac = 0
        self.dmc_dma_index = 0
        self.mmc3_regs = [0, 2, 4, 5, 6, 7, 0, 1]
        self.mmc3_cmd = 0
        self.mmc3_latch = 0
        self.mmc3_count = 0
        self.mmc3_reload = False
        self.mmc3_enabled = False
        self.irq_sources = 0
        self.ppu_line = 261
        self.ppu_dot = 0
        self.idle_synch = 1
        self.dead_frames = 2
        self.oam_addr = 0
        self.controller_strobe = 0
        self.controller_shift = 0
        self.controller_state = 0
        self.input_timeline = input_timeline or {}
        self.stop_events: list[dict] = []
        self.queue_events: list[dict] = []

        self.cpu = MPU(memory=self)
        self.cpu.a = self.cpu.x = self.cpu.y = 0
        self.cpu.sp = 0xFD
        self.cpu.p = MPU.INTERRUPT | MPU.UNUSED
        self.cpu.processorCycles = 0
        self.reset_pending = True
        self.prev_p = self.cpu.p
        self.current_instruction_pc = 0
        self.current_instruction_len = 1
        self.current_instruction_opcode = 0
        self.jammed = False

    def _prg_bank(self, addr: int) -> int:
        slot = (addr - 0x8000) >> 13
        if slot == 0:
            return (30 if self.mmc3_cmd & 0x40 else self.mmc3_regs[6]) & 31
        if slot == 1:
            return self.mmc3_regs[7] & 31
        if slot == 2:
            return (self.mmc3_regs[6] if self.mmc3_cmd & 0x40 else 30) & 31
        return 31

    def _rom_read(self, addr: int) -> int:
        bank = self._prg_bank(addr)
        return self.prg[bank * 0x2000 + (addr & 0x1FFF)]

    def __getitem__(self, addr: int) -> int:
        addr &= 0xFFFF
        if addr < 0x2000:
            return self.ram[addr & 0x7FF]
        if addr < 0x4000:
            reg = 0x2000 | (addr & 7)
            if reg == 0x2002:
                value = self.ppu_status | (self.ppu_latch & 0x1F)
                self.ppu_status &= 0x7F
                self.vblank = False
                self.ppu_w_toggle = 0
                self.ppu_latch = value
                return value
            if reg == 0x2004:
                value = self.oam[self.oam_addr]
                self.ppu_latch = value
                return value
            if reg == 0x2007:
                value = self.ppu_ram[self.ppu_vram_addr & 0x3FFF]
                self.ppu_vram_addr = (self.ppu_vram_addr + (32 if self.ppu_regs[0] & 4 else 1)) & 0x7FFF
                self.ppu_latch = value
                return value
            return self.ppu_latch
        if addr == 0x4015:
            return (0x10 if self.dmc_size else 0) | (0x80 if self.irq_sources & 2 else 0) | (0x40 if self.irq_sources & 1 else 0)
        if addr == 0x4016:
            if self.controller_strobe:
                return 0x40 | (self.controller_state & 1)
            bit = self.controller_shift & 1
            self.controller_shift = (self.controller_shift >> 1) | 0x80
            return 0x40 | bit
        if addr == 0x4017:
            return 0x40
        if 0x6000 <= addr < 0x8000:
            return self.prg_ram[addr & 0x1FFF]
        if addr >= 0x8000:
            return self._rom_read(addr)
        return 0

    def _dmc_state(self) -> dict:
        return {
            "dmc_format": self.dmc_format,
            "dmc_period": self.dmc_period,
            "dmc_acc": self.dmc_acc,
            "dmc_bit_count": self.dmc_bit_count,
            "dmc_addr": self.dmc_addr,
            "dmc_size": self.dmc_size,
            "dmc_shift": self.dmc_shift,
            "dmc_have_dma": int(self.dmc_have_dma),
            "dmc_have_sample": int(self.dmc_have_sample),
            "dmc_dma_buf": self.dmc_dma_buf,
            "raw_dac": self.raw_dac,
        }

    def _sound_event_row(self, event: str, *, cycle: int | None = None,
                         edge_cycle: int | None = None, state: dict | None = None, **extra) -> dict:
        context = self.current_sound_hook_context or {}
        row = {
            "sequence": -1,
            "event": event,
            "source_frame": self.source_frame,
            "cycle": self.cpu_cycles if cycle is None else cycle,
            "edge_cycle": "" if edge_cycle is None else edge_cycle,
            "hook_sequence": context.get("hook_sequence", ""),
            "hook_start_cycle": context.get("hook_start_cycle", ""),
            "hook_end_cycle": context.get("hook_end_cycle", ""),
            "hook_cycles": context.get("hook_cycles", ""),
            "pc": context.get("pc", f"${self.current_instruction_pc:04X}"),
            "opcode": context.get("opcode", f"${self.current_instruction_opcode:02X}"),
            "phase": "",
            "address": "",
            "value": "",
            "prg_bank_8k": "",
            "bit": "",
            **(self._dmc_state() if state is None else state),
            "dmc_acc_before": "",
            "dmc_bit_count_before": "",
            "dmc_shift_before": "",
            "dmc_have_dma_before": "",
            "dmc_have_sample_before": "",
            "dmc_dma_buf_before": "",
            "raw_dac_before": "",
            "dac_changed": "",
        }
        row.update(extra)
        return row

    def _write_sound_event(self, row: dict) -> None:
        if self.sound_event_writer is None:
            return
        if not self._sound_event_in_window(row):
            return
        if self.current_sound_hook_buffer is not None:
            self.current_sound_hook_buffer.append(row)
        else:
            self._commit_sound_event(row)

    def _commit_sound_event(self, row: dict) -> None:
        row["sequence"] = self.sound_event_sequence
        self.sound_event_sequence += 1
        self.sound_event_writer.writerow(row)
        self.sound_event_type_counts[row["event"]] = self.sound_event_type_counts.get(row["event"], 0) + 1

    def _sound_event_in_window(self, row: dict) -> bool:
        if self.sound_event_cycle_windows is None:
            return True
        for key in ("cycle", "edge_cycle"):
            value = row.get(key)
            if value in (None, ""):
                continue
            cycle = int(value)
            index = bisect_right(self.sound_event_window_starts, cycle) - 1
            if index >= 0 and cycle <= self.sound_event_cycle_windows[index][1]:
                return True
        return False

    def _flush_sound_hook_events(self, context: dict, events: list[dict], pre_state: dict) -> None:
        if self.sound_event_writer is None or not events:
            return
        events = [row for row in events if self._sound_event_in_window(row)]
        if not events:
            return
        begin = self._sound_event_row(
            "SOUND_HOOK_BEGIN",
            cycle=context["hook_end_cycle"],
            state=pre_state,
            **context,
        )
        if self._sound_event_in_window(begin):
            self._commit_sound_event(begin)
        else:
            first_event = events[0]
            self._commit_sound_event(first_event)
            events = events[1:]
        for row in events:
            self._commit_sound_event(row)
        end = self._sound_event_row(
            "SOUND_HOOK_END",
            cycle=self.cpu_cycles,
            **context,
        )
        if self._sound_event_in_window(end):
            self._commit_sound_event(end)

    def __setitem__(self, addr: int, value: int) -> None:
        addr &= 0xFFFF
        value &= 0xFF
        dmc_state_before_write = self._dmc_state() if addr in (0x4010, 0x4011, 0x4012, 0x4013, 0x4015) else None
        if addr < 0x2000:
            self.ram[addr & 0x7FF] = value
            if (addr & 0x7FF) == 0x700 and value != 0:
                self.queue_events.append({
                    "source_frame": self.source_frame,
                    "cycle": self.cpu_cycles,
                    "pc": f"${(self.current_instruction_pc + self.current_instruction_len) & 0xFFFF:04X}",
                    "address": "$0700",
                    "value": f"${value:02X}",
                })
            return
        if addr < 0x4000:
            reg = 0x2000 | (addr & 7)
            self.ppu_latch = value
            if reg == 0x2000:
                old = self.ppu_regs[0]
                self.ppu_regs[0] = value
                if self.vblank and not (old & 0x80) and value & 0x80:
                    self.nmi_pending = True
            elif reg == 0x2001:
                self.ppu_regs[1] = value
            elif reg == 0x2003:
                self.oam_addr = value
            elif reg == 0x2004:
                self.oam[self.oam_addr] = value
                self.oam_addr = (self.oam_addr + 1) & 0xFF
            elif reg == 0x2005:
                self.ppu_w_toggle ^= 1
            elif reg == 0x2006:
                if not self.ppu_w_toggle:
                    self.ppu_addr = (value & 0x3F) << 8
                else:
                    self.ppu_addr = (self.ppu_addr & 0x3F00) | value
                    self.ppu_vram_addr = self.ppu_addr
                self.ppu_w_toggle ^= 1
            elif reg == 0x2007:
                self.ppu_ram[self.ppu_vram_addr & 0x3FFF] = value
                self.ppu_vram_addr = (self.ppu_vram_addr + (32 if self.ppu_regs[0] & 4 else 1)) & 0x7FFF
            return
        if addr == 0x4014:
            base = value << 8
            for i in range(256):
                self.oam[(self.oam_addr + i) & 0xFF] = self[base + i]
            self.oam_addr = (self.oam_addr + 256) & 0xFF
            self._charge(512)
            return
        if addr == 0x4010:
            self.dmc_format = value
            self.dmc_period = self.DMC_PERIODS[value & 15]
        elif addr == 0x4011:
            self.raw_dac = value & 0x7F
        elif addr == 0x4012:
            self.dmc_addr_latch = value
        elif addr == 0x4013:
            self.dmc_size_latch = value
        elif addr == 0x4015:
            if value & 0x10:
                if not self.dmc_size:
                    self.dmc_addr = 0x4000 + (self.dmc_addr_latch << 6)
                    self.dmc_size = (self.dmc_size_latch << 4) + 1
            else:
                self.dmc_size = 0
            self.irq_sources &= ~2
        elif addr == 0x4016:
            new_strobe = value & 1
            if new_strobe or self.controller_strobe:
                self.controller_shift = self.controller_state
            self.controller_strobe = new_strobe
        elif 0x6000 <= addr < 0x8000:
            self.prg_ram[addr & 0x1FFF] = value
            return
        elif addr >= 0x8000:
            even = addr & 0xE001
            if even == 0x8000:
                self.mmc3_cmd = value
            elif even == 0x8001:
                self.mmc3_regs[self.mmc3_cmd & 7] = value
            elif even == 0xC000:
                self.mmc3_latch = value
            elif even == 0xC001:
                self.mmc3_reload = True
            elif even == 0xE000:
                self.mmc3_enabled = False
                self.irq_pending = False
                self.irq_sources &= ~4
            elif even == 0xE001:
                self.mmc3_enabled = True

        if 0x4000 <= addr <= 0x4017 and addr not in (0x4014, 0x4016):
            self.events.append({
                "source_frame": self.source_frame,
                "cycle": self.cpu_cycles,
                "frame_cycle": self.cpu_cycles - self.frame_cycle_start,
                "pc": f"${(self.current_instruction_pc + self.current_instruction_len) & 0xFFFF:04X}",
                "address": f"${addr:04X}",
                "value": f"${value:02X}",
            })
            if self.sound_event_writer is not None:
                row = self._sound_event_row(
                    "APU_WRITE",
                    cycle=self.cpu_cycles,
                    address=f"${addr:04X}",
                    value=f"${value:02X}",
                    pc=f"${(self.current_instruction_pc + self.current_instruction_len) & 0xFFFF:04X}",
                    dmc_acc_before=dmc_state_before_write["dmc_acc"] if dmc_state_before_write else "",
                    dmc_bit_count_before=dmc_state_before_write["dmc_bit_count"] if dmc_state_before_write else "",
                    dmc_shift_before=dmc_state_before_write["dmc_shift"] if dmc_state_before_write else "",
                    dmc_have_dma_before=dmc_state_before_write["dmc_have_dma"] if dmc_state_before_write else "",
                    dmc_have_sample_before=dmc_state_before_write["dmc_have_sample"] if dmc_state_before_write else "",
                    dmc_dma_buf_before=dmc_state_before_write["dmc_dma_buf"] if dmc_state_before_write else "",
                    raw_dac_before=dmc_state_before_write["raw_dac"] if dmc_state_before_write else "",
                )
                self._write_sound_event(row)
            if addr == 0x4017:
                # ROM uses four-step mode ($40). Match FCEUX's write-side reset
                # so later source-hook updates use the same counter phase.
                self.frame_counter = 0
                self.frame_mode = (value & 0xC0) >> 6
                self.frame_fhcnt = self.frame_fhinc
                if self.frame_mode & 0x02:
                    # The supplied opening ROM never takes this five-step path;
                    # it is retained for completeness of the diagnostics model.
                    self.frame_counter = 1
                else:
                    self.frame_counter = 1

    def _charge(self, cycles: int) -> None:
        self.cpu_credit -= cycles * 48
        self.cpu_cycles += cycles
        self.hook_cycles += cycles

    def _dmc_read(self) -> int:
        addr = 0x8000 + self.dmc_addr
        phase = self.dmc_dma_index & 3
        bank = self._prg_bank(addr)
        value = self._rom_read(addr)
        self._charge(1)
        self.dmc_events.append({
            "source_frame": self.source_frame,
            "cycle": self.cpu_cycles,
            "address": f"${addr:04X}",
            "value": f"${value:02X}",
            "index": self.dmc_dma_index,
            "phase": phase,
            "prg_bank_8k": bank,
            "hook_sequence": self.current_sound_hook_context.get("hook_sequence", "") if self.current_sound_hook_context else "",
        })
        if self.sound_event_writer is not None:
            self._write_sound_event(self._sound_event_row(
                "DMC_DMR_PHASE",
                cycle=self.cpu_cycles,
                phase=phase,
                address=f"${addr:04X}",
                value=f"${value:02X}",
                prg_bank_8k=bank,
            ))
        self.dmc_dma_index += 1
        return value

    def _dmc_hook(self, cycles: int) -> None:
        hook_pre_state = self._dmc_state() if self.sound_event_writer is not None else None
        context = None
        hook_events: list[dict] | None = None
        if self.sound_event_writer is not None:
            context = {
                "hook_sequence": self.sound_hook_sequence,
                "hook_start_cycle": self.cpu_cycles - cycles,
                "hook_end_cycle": self.cpu_cycles,
                "hook_cycles": cycles,
                "pc": f"${self.current_instruction_pc:04X}",
                "opcode": f"${self.current_instruction_opcode:02X}",
            }
            self.sound_hook_sequence += 1
            self.current_sound_hook_context = context
            hook_events = []
        self.current_sound_hook_buffer = hook_events
        # Pinned FCEUX subtracts the completed instruction-hook cycle batch,
        # then applies FrameSoundUpdate once at this hook boundary. In
        # particular, an OAM DMA's 512 cycles can defer a pending update until
        # the next instruction hook; do not move it to the timer's crossing
        # cycle as the WaveHi per-cycle approximation does.
        self.frame_fhcnt -= cycles * 48
        if self.frame_fhcnt <= 0:
            fhcnt_before = self.frame_fhcnt
            counter_before = self.frame_counter
            if self.frame_counter == 3 and (self.frame_mode & 0x02):
                self.frame_fhcnt += self.frame_fhinc
            self.frame_counter = (self.frame_counter + 1) & 3
            self.frame_fhcnt += self.frame_fhinc
            frame_row = {
                "sequence": self.frame_update_sequence,
                "source_frame": self.source_frame,
                "cycle": self.cpu_cycles,
                "hook_cycles": cycles,
                "fhcnt_before_update": fhcnt_before,
                "fhcnt_after_update": self.frame_fhcnt,
                "frame_counter_before": counter_before,
                "frame_counter_after": self.frame_counter,
                "frame_mode": self.frame_mode,
            }
            self.frame_update_sequence += 1
            if self.frame_update_writer is not None:
                self.frame_update_writer.writerow(frame_row)
            if self.sound_event_writer is not None:
                self._write_sound_event(self._sound_event_row(
                    "SOURCE_FRAME_SOUND_UPDATE",
                    cycle=self.cpu_cycles,
                    hook_cycles=cycles,
                    phase=counter_before,
                    value=f"${self.frame_mode:02X}",
                ))
        # Source order: refill first, then decrement DMC timer by hook cycles.
        if self.dmc_size and not self.dmc_have_dma:
            before = self._dmc_state()
            self._dmc_read()
            self._dmc_read()
            self._dmc_read()
            self.dmc_dma_buf = self._dmc_read()
            self.dmc_have_dma = True
            self.dmc_addr = (self.dmc_addr + 1) & 0x7FFF
            self.dmc_size -= 1
            if self.sound_event_writer is not None:
                self._write_sound_event(self._sound_event_row(
                    "DMC_BUFFER_LOAD",
                    phase=3,
                    address=f"${(0x8000 + ((self.dmc_addr - 1) & 0x7FFF)):04X}",
                    value=f"${self.dmc_dma_buf:02X}",
                    prg_bank_8k=self._prg_bank(0x8000 + ((self.dmc_addr - 1) & 0x7FFF)),
                    dmc_acc_before=before["dmc_acc"],
                    dmc_bit_count_before=before["dmc_bit_count"],
                    dmc_shift_before=before["dmc_shift"],
                    dmc_have_dma_before=before["dmc_have_dma"],
                    dmc_have_sample_before=before["dmc_have_sample"],
                    dmc_dma_buf_before=before["dmc_dma_buf"],
                    raw_dac_before=before["raw_dac"],
                ))
        self.dmc_acc -= cycles
        while self.dmc_acc <= 0 and self.dmc_period:
            before_state = self._dmc_state()
            edge_cycle = self.cpu_cycles + self.dmc_acc
            bit = (self.dmc_shift & 1) if self.dmc_have_sample else ""
            raw_dac_before = self.raw_dac
            if self.dmc_have_sample:
                self.raw_dac += ((self.dmc_shift & 1) << 2) - 2
                if self.raw_dac & 0x80:
                    self.raw_dac = raw_dac_before
            raw_dac_after = self.raw_dac
            self.dmc_acc += self.dmc_period
            self.dmc_bit_count = (self.dmc_bit_count + 1) & 7
            self.dmc_shift >>= 1
            if self.dmc_bit_count == 0:
                if self.dmc_have_dma:
                    self.dmc_have_sample = True
                    self.dmc_shift = self.dmc_dma_buf
                    self.dmc_have_dma = False
                else:
                    self.dmc_have_sample = False
            if self.sound_event_writer is not None:
                self._write_sound_event(self._sound_event_row(
                    "DMC_BIT_EDGE",
                    cycle=self.cpu_cycles,
                    edge_cycle=edge_cycle,
                    bit=bit,
                    dmc_acc_before=before_state["dmc_acc"],
                    dmc_bit_count_before=before_state["dmc_bit_count"],
                    dmc_shift_before=before_state["dmc_shift"],
                    dmc_have_dma_before=before_state["dmc_have_dma"],
                    dmc_have_sample_before=before_state["dmc_have_sample"],
                    dmc_dma_buf_before=before_state["dmc_dma_buf"],
                    raw_dac_before=raw_dac_before,
                    dac_changed=int(raw_dac_after != raw_dac_before),
                ))
        self.current_sound_hook_buffer = None
        if hook_events is not None and context is not None and hook_pre_state is not None:
            self._flush_sound_hook_events(context, hook_events, hook_pre_state)

    def _irq_clock(self, source_ppu_line: int | None = None, source_ppu_dot: int | None = None) -> None:
        count = self.mmc3_count
        if count == 0 or self.mmc3_reload:
            self.mmc3_count = self.mmc3_latch
            self.mmc3_reload = False
        else:
            self.mmc3_count = (self.mmc3_count - 1) & 0xFF
        # MMC3 revision B behavior used by FCEUX's standard mapper-4 path.
        if (count != 0 or True) and self.mmc3_count == 0 and self.mmc3_enabled:
            if not self.irq_pending:
                reload_before = self.mmc3_reload
                irq_pending_before = self.irq_pending
                self.mmc3_irq_events.append({
                    "source_frame": self.source_frame,
                    "cycle": self.cpu_cycles,
                    "ppu_line": self.ppu_line if source_ppu_line is None else source_ppu_line,
                    "ppu_dot": self.ppu_dot if source_ppu_dot is None else source_ppu_dot,
                    "cpu_credit": self.cpu_credit,
                    "cpu_p": self.cpu.p,
                    "cpu_prev_p": self.prev_p,
                    "irq_pending_before": int(irq_pending_before),
                    "irq_pending_after": 1,
                    "count_before": count,
                    "count_after": self.mmc3_count,
                    "irq_enabled": int(self.mmc3_enabled),
                    "reload_before": int(reload_before),
                    "reload_after": int(self.mmc3_reload),
                    "latch": self.mmc3_latch,
                    "pc": f"${self.cpu.pc:04X}",
                })
            self.irq_pending = True
            self.irq_sources |= 4

    def _cpu_instruction(self) -> None:
        cpu = self.cpu
        if self.reset_pending:
            cpu.pc = self[0xFFFC] | (self[0xFFFD] << 8)
            cpu.p = MPU.INTERRUPT | MPU.UNUSED
            self.reset_pending = False

        if self.nmi_pending and not self.jammed:
            self.cpu_interrupt_events.append({"source_frame": self.source_frame, "cycle": self.cpu_cycles,
                                              "kind": "NMI", "pc_before": f"${cpu.pc:04X}",
                                              "mask_before": int(bool(cpu.p & MPU.INTERRUPT)),
                                              "irq_pending": int(self.irq_pending)})
            self._charge(7)
            self._hardware_interrupt(0xFFFA)
            self.nmi_pending = False
            if self.cpu_credit <= 0:
                return
        elif self.irq_pending and not (self.prev_p & MPU.INTERRUPT) and not self.jammed:
            self.cpu_interrupt_events.append({"source_frame": self.source_frame, "cycle": self.cpu_cycles,
                                              "kind": "IRQ", "pc_before": f"${cpu.pc:04X}",
                                              "mask_before": int(bool(self.prev_p & MPU.INTERRUPT)),
                                              "irq_pending": 1})
            self._charge(7)
            self._hardware_interrupt(0xFFFE)
            if self.cpu_credit <= 0:
                return

        self.prev_p = cpu.p
        self.current_instruction_pc = cpu.pc
        if cpu.pc == 0x8048 and self._prg_bank(0x8000) == 0:
            self.stop_events.append({
                "source_frame": self.source_frame,
                "cycle": self.cpu_cycles,
                "pc": "$8048",
                "mapped_prg_bank_8000": 0,
                "accumulator_before_instruction": f"${cpu.a:02X}",
                "opcode": f"${self[0x8048]:02X}",
                "immediate_stop_value": f"${self[0x8049]:02X}",
            })
        op = self[cpu.pc]
        self.current_instruction_opcode = op
        mode = MPU.disassemble[op][1]
        self.current_instruction_len = 1 if mode in ("imp", "acc") else 2 if mode in ("imm", "zpg", "zpx", "zpy", "rel", "inx", "iny") else 3
        base = cpu.cycletime[op]
        instruction_pc = cpu.pc
        instruction_bank = self._prg_bank(instruction_pc)
        cpu_credit_before_instruction = self.cpu_credit
        cpu.pc = (cpu.pc + 1) & 0xFFFF
        cpu.excycles = 0
        cpu.addcycles = cpu.extracycles[op]
        self._charge(base)
        cpu_credit_after_base_charge = self.cpu_credit
        hook_cycles = self.hook_cycles
        self.hook_cycles = 0
        hook_cycle_start = self.cpu_cycles - hook_cycles
        hook_cycle_end = self.cpu_cycles
        frame_update_sequence_before = self.frame_update_sequence
        frame_counter_before = self.frame_counter
        frame_fhcnt_before = self.frame_fhcnt
        dma_index_before = self.dmc_dma_index
        dmc_state_before = self._dmc_state() if self.cpu_instruction_writer is not None else None
        self._dmc_hook(hook_cycles)
        frame_update_sequence_after_hook = self.frame_update_sequence
        frame_counter_after_hook = self.frame_counter
        frame_fhcnt_after_hook = self.frame_fhcnt
        dmc_state_after_hook = self._dmc_state() if self.cpu_instruction_writer is not None else None
        dma_index_after_hook = self.dmc_dma_index
        cpu.instruct[op](cpu)
        cpu.pc &= 0xFFFF
        extra = cpu.excycles
        if extra:
            self._charge(extra)
        cpu.processorCycles += base + extra
        if self.cpu_instruction_writer is not None and self.cpu_instruction_cycle_window is not None:
            window_start, window_end = self.cpu_instruction_cycle_window
            if window_start <= hook_cycle_end < window_end:
                before = dmc_state_before or {}
                after = dmc_state_after_hook or {}
                self.cpu_instruction_writer.writerow({
                    "sequence": self.cpu_instruction_sequence,
                    "source_frame": self.source_frame,
                    "cycle_start": hook_cycle_start,
                    "cycle_at_sound_hook": hook_cycle_end,
                    "cycle_after_instruction": self.cpu_cycles,
                    "hook_cycles": hook_cycles,
                    "instruction_pc": f"${instruction_pc:04X}",
                    "opcode": f"${op:02X}",
                    "prg_bank_8k": instruction_bank,
                    "pc_after_instruction": f"${cpu.pc:04X}",
                    "base_cycles": base,
                    "extra_cycles": extra,
                    "cpu_credit_before_instruction": cpu_credit_before_instruction,
                    "cpu_credit_after_base_charge": cpu_credit_after_base_charge,
                    "cpu_credit_after_instruction": self.cpu_credit,
                    "frame_update_fired": int(frame_update_sequence_after_hook != frame_update_sequence_before),
                    "frame_counter_before": frame_counter_before,
                    "frame_counter_after_hook": frame_counter_after_hook,
                    "frame_fhcnt_before": frame_fhcnt_before,
                    "frame_fhcnt_after_hook": frame_fhcnt_after_hook,
                    "dmc_acc_before": before.get("dmc_acc", ""),
                    "dmc_acc_after_hook": after.get("dmc_acc", ""),
                    "dmc_period": after.get("dmc_period", ""),
                    "dmc_have_dma_after_hook": after.get("dmc_have_dma", ""),
                    "dmc_have_sample_after_hook": after.get("dmc_have_sample", ""),
                    "dmc_dma_reads_this_hook": dma_index_after_hook - dma_index_before,
                })
                self.cpu_instruction_sequence += 1

    def _hardware_interrupt(self, vector: int) -> None:
        c = self.cpu
        c.stPushWord(c.pc)
        c.stPush((c.p & ~MPU.BREAK) | MPU.UNUSED)
        c.p = (c.p | MPU.INTERRUPT | MPU.UNUSED) & ~MPU.BREAK
        c.pc = self[vector] | (self[vector + 1] << 8)

    def runppu(self, dots: int, defer_incomplete_instruction: bool = False) -> None:
        self.cpu_credit += dots * 16
        while self.cpu_credit > 0:
            if defer_incomplete_instruction:
                if self.nmi_pending and not self.jammed:
                    required_cycles = 7
                    instruction_pc = self.cpu.pc
                    opcode = None
                elif self.irq_pending and not (self.prev_p & MPU.INTERRUPT) and not self.jammed:
                    required_cycles = 7
                    instruction_pc = self.cpu.pc
                    opcode = None
                else:
                    instruction_pc = self.cpu.pc
                    opcode = self[instruction_pc]
                    required_cycles = self.cpu.cycletime[opcode]
                required_credit = required_cycles * 48
                if self.cpu_credit < required_credit:
                    self.deferred_instruction_events.append({
                        "source_frame": self.source_frame,
                        "cycle": self.cpu_cycles,
                        "cpu_credit": self.cpu_credit,
                        "instruction_pc": f"${instruction_pc:04X}",
                        "opcode": "INTERRUPT" if opcode is None else f"${opcode:02X}",
                        "required_base_cycles": required_cycles,
                        "required_credit": required_credit,
                        "ppu_segment_dots": dots,
                    })
                    break
            self._cpu_instruction()

    def run_frame(self, frame: int) -> None:
        self.source_frame = frame
        self.frame_cycle_start = self.cpu_cycles
        cycle_start = self.cpu_cycles
        controls = self.input_timeline.get(frame, {})
        self.controller_state = (
            (int(bool(controls.get("A"))) << 0)
            | (int(bool(controls.get("B"))) << 1)
            | (int(bool(controls.get("select"))) << 2)
            | (int(bool(controls.get("start"))) << 3)
            | (int(bool(controls.get("up"))) << 4)
            | (int(bool(controls.get("down"))) << 5)
            | (int(bool(controls.get("left"))) << 6)
            | (int(bool(controls.get("right"))) << 7)
        )
        if self.dead_frames:
            self.runppu(20 * 341)
            self.runppu(242 * 341)
            self.dead_frames -= 1
            self.frame_stats.append({"source_frame": frame, "cycle_start": cycle_start, "cycle_end": self.cpu_cycles, "cycle_delta": self.cpu_cycles - cycle_start})
            return

        self.vblank = True
        self.ppu_status |= 0x80
        self.ppu_line = 241
        self.runppu(20)
        if self.ppu_regs[0] & 0x80:
            self.nmi_pending = True
        self.runppu(20 * 341 - 20)
        self.ppu_status &= 0x7F
        self.vblank = False

        # NewPPU does not execute the legacy PPU loop's pre-render dummy line.
        # Its renderer clocks fetches in the 241-line loop below.
        short_first_line = bool(self.idle_synch and (self.ppu_regs[1] & 0x18))
        self.idle_synch ^= 1

        for line in range(241):
            self.ppu_line = line
            self.ppu_dot = 0
            line_len = 340 if line == 0 and short_first_line else 341
            if self.ppu_regs[1] & 0x18 and (self.ppu_regs[0] & 0x38) != 0x18:
                # FCEUX's standard MMC3 hook is called during sprite slot 2.
                self.runppu(274, defer_incomplete_instruction=True)
                self._irq_clock(line, 274)
                self.runppu(line_len - 274)
            else:
                self.runppu(line_len)
        self.runppu(341)  # FCEUX NewPPU's final idle line
        self.frame_stats.append({"source_frame": frame, "cycle_start": cycle_start, "cycle_end": self.cpu_cycles, "cycle_delta": self.cpu_cycles - cycle_start})

    def run(self, end_frame: int) -> None:
        for frame in range(1, end_frame + 1):
            self.run_frame(frame)


def compare_to_fceux(machine: Machine, trace_dir: Path, compare_through_frame: int | None = None) -> dict:
    compare_frame = machine.source_frame if compare_through_frame is None else min(compare_through_frame, machine.source_frame)
    source_frame_ends = {x["source_frame"]: x["cycle_end"] for x in machine.frame_stats}
    cutoff_cycle = source_frame_ends.get(compare_frame, machine.cpu_cycles)
    frames = []
    with (trace_dir / "frame_cycles.csv").open(newline="") as f:
        for row in csv.DictReader(f):
            if int(row["source_frame"]):
                frames.append({k: int(row[k]) for k in ("source_frame", "cycle_start", "cycle_end", "cycle_delta")})
    source_rows = machine.events
    fceux_rows = []
    with (trace_dir / "apu_writes.csv").open(newline="") as f:
        for row in csv.DictReader(f):
            if 0x4000 <= int(row["address"].replace("$", ""), 16) <= 0x4017 and int(row["address"].replace("$", ""), 16) != 0x4016:
                if int(row["source_frame"]) > compare_frame:
                    continue
                fceux_rows.append({
                    "frame": int(row["source_frame"]),
                    "cycle": int(row["cpu_cycle"]),
                    "pc": row["pc"],
                    "address": row["address"],
                    "value": row["value"],
                })
    source_apu_compared = [row for row in source_rows if row["source_frame"] <= compare_frame]
    fceux_apu_compared = [row for row in fceux_rows if row["frame"] <= compare_frame]
    mismatches = []
    common = min(len(source_apu_compared), len(fceux_apu_compared))
    apu_cycle_residuals = []
    for i in range(common):
        src, ref = source_apu_compared[i], fceux_apu_compared[i]
        if (src["address"], src["value"]) != (ref["address"], ref["value"]):
            mismatches.append({"index": i, "source": src, "fceux": ref, "reason": "ordered address/value mismatch"})
            break
        apu_cycle_residuals.append(src["cycle"] - ref["cycle"])
    selected = []
    for row in source_apu_compared:
        if int(row["source_frame"]) in (1043, 1046, 1047, 1048, 1049):
            selected.append(row)
    fceux_dmc = []
    with (trace_dir / "fceux_dmc_trace.csv").open(newline="") as f:
        for row in csv.DictReader(f):
            if row["event"] == "DMC_DMA_OUT":
                if int(row["absolute_cycle"]) <= cutoff_cycle:
                    fceux_dmc.append({"cycle": int(row["absolute_cycle"]), "address": f"${int(row['detail_address'], 16):04X}", "value": f"${int(row['detail_value']):02X}"})
    source_dma_out = [e for e in machine.dmc_events if int(e["index"]) % 4 == 3 and e["source_frame"] <= compare_frame]
    dmc_common = min(len(source_dma_out), len(fceux_dmc))
    dmc_mismatch = None
    dmc_residuals = []
    dmc_pairs = []
    for i in range(dmc_common):
        src, ref = source_dma_out[i], fceux_dmc[i]
        if (src["address"], src["value"]) != (ref["address"], ref["value"]):
            dmc_mismatch = {"index": i, "source": src, "fceux": ref}
            break
        dmc_residuals.append(src["cycle"] - ref["cycle"])
        dmc_pairs.append({
            "source_frame": src["source_frame"],
            "source_cycle": src["cycle"],
            "fceux_cycle": ref["cycle"],
            "cycle_residual": src["cycle"] - ref["cycle"],
            "address": src["address"],
            "value": src["value"],
        })
    dmc_by_frame: dict[int, list[dict]] = {}
    for pair in dmc_pairs:
        dmc_by_frame.setdefault(int(pair["source_frame"]), []).append(pair)
    ref_frame_map = {x["source_frame"]: x for x in frames if x["source_frame"] <= machine.source_frame}
    frame_comparison = []
    for src in machine.frame_stats:
        ref = ref_frame_map.get(src["source_frame"])
        if ref:
            frame_comparison.append({
                "source_frame": src["source_frame"],
                "source_cycle_delta": src["cycle_delta"],
                "fceux_cycle_delta": ref["cycle_delta"],
                "delta_residual": src["cycle_delta"] - ref["cycle_delta"],
                "source_cycle_end": src["cycle_end"],
                "fceux_cycle_end": ref["cycle_end"],
            })
    return {
        "fceux_trace_dir": trace_dir.relative_to(ROOT).as_posix(),
        "comparison_through_source_frame": compare_frame,
        "comparison_cycle_cutoff_exclusive": cutoff_cycle,
        "source_apu_write_count_total_run": len(source_rows),
        "fceux_apu_write_count_through_comparison_frame": len(fceux_apu_compared),
        "source_apu_write_count_compared": len(source_apu_compared),
        "fceux_apu_write_count_compared": len(fceux_apu_compared),
        "apu_ordered_address_value_prefix_matches": not mismatches,
        "apu_stream_complete_match_through_requested_frame": not mismatches and len(source_apu_compared) == len(fceux_apu_compared),
        "first_apu_order_mismatch": mismatches[0] if mismatches else None,
        "apu_cycle_residual_min_max_mean": {
            "min": min(apu_cycle_residuals) if apu_cycle_residuals else None,
            "max": max(apu_cycle_residuals) if apu_cycle_residuals else None,
            "mean": sum(apu_cycle_residuals) / len(apu_cycle_residuals) if apu_cycle_residuals else None,
        },
        "apu_cycle_residual_samples_1043_1049": [
            {"index": i, "source": source_apu_compared[i], "fceux": fceux_apu_compared[i], "residual": apu_cycle_residuals[i]}
            for i in range(common)
            if source_apu_compared[i]["source_frame"] in (1043, 1046, 1047, 1048, 1049)
        ],
        "source_dmc_dmr_count_compared_prefix": sum(1 for e in machine.dmc_events if e["source_frame"] <= compare_frame),
        "source_dmc_output_byte_count": len(source_dma_out),
        "fceux_dmc_dma_out_count": len(fceux_dmc),
        "first_dmc_address_value_mismatch": dmc_mismatch,
        "dmc_stream_complete_match_through_requested_cycle": dmc_mismatch is None and len(source_dma_out) == len(fceux_dmc),
        "dmc_cycle_residual_min_max_mean": {
            "min": min(dmc_residuals) if dmc_residuals else None,
            "max": max(dmc_residuals) if dmc_residuals else None,
            "mean": sum(dmc_residuals) / len(dmc_residuals) if dmc_residuals else None,
        },
        "dmc_cycle_residual_by_source_frame": {
            str(frame): {
                "output_bytes": len(rows),
                "min": min(row["cycle_residual"] for row in rows),
                "max": max(row["cycle_residual"] for row in rows),
                "first": rows[0],
                "last": rows[-1],
            }
            for frame, rows in sorted(dmc_by_frame.items())
        },
        "selected_dmc_output_cycle_pairs_frames_1043_1049": [
            pair for pair in dmc_pairs if pair["source_frame"] in (1043, 1046, 1047, 1048, 1049)
        ],
        "selected_source_apu_writes_frames_1043_1049": selected,
        "source_fceux_frame_cycle_comparison": frame_comparison,
    }


def validate_title_stop(machine: Machine, pc_trace: Path, frame_state_path: Path) -> dict:
    source_hits = [x for x in machine.stop_events if x["source_frame"] == 4661]
    fceux_hits = []
    with pc_trace.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            if row["source_frame"] == "4661" and row["pc"].upper() == "$8048":
                fceux_hits.append(row)
    fceux_start = None
    with frame_state_path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            if row["source_frame"] == "4661":
                fceux_start = row["input_start"]
                break
    expected = len(source_hits) == 1 and source_hits[0]["immediate_stop_value"] == "$01" and source_hits[0]["mapped_prg_bank_8000"] == 0
    return {
        "source_stop_marker": source_hits,
        "source_nonzero_sound_queue_writes_frame_4661": [x for x in machine.queue_events if x["source_frame"] == 4661],
        "fceux_pc_8048_hits_frame_4661": len(fceux_hits),
        "fceux_pc_8048_first_hit": fceux_hits[0] if fceux_hits else None,
        "fceux_start_pressed_at_frame_boundary": fceux_start == "1",
        "rom_opcode_at_8048": "$A9",
        "rom_immediate_byte_at_8049": "$01",
        "source_reaches_bank0_8048_lda_01_on_expected_frame": expected,
        "same_input_reference_confirms_pc_and_frame": len(fceux_hits) > 0 and fceux_start == "1",
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--end-frame", type=int, default=1109)
    ap.add_argument("--out-dir", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--compare-fceux", action="store_true")
    ap.add_argument("--fceux-trace", type=Path, default=FCEUX_TRACE)
    ap.add_argument("--compare-through-frame", type=int, default=None,
                    help="post-run FCEUX comparison cutoff; useful when supplied input changes after this frame")
    ap.add_argument("--input-timeline", type=Path, default=None,
                    help="optional explicit per-source-frame P1 input CSV; omitted means all buttons released")
    ap.add_argument("--export-dmc-state", action="store_true",
                    help="write a compressed ROM-only ordered APU/DMC state-edge event stream")
    ap.add_argument("--source-frame-updates-out", type=Path, default=None,
                    help="write ROM-only frame-sequencer updates at source CPU instruction-hook boundaries")
    ap.add_argument("--event-cycle-windows", type=Path, default=None,
                    help="post-run diagnostic filter JSON with renderer DMC conflict cycles; does not affect ROM execution")
    ap.add_argument("--event-cycle-window-radius", type=int, default=600,
                    help="radius in source CPU cycles around each diagnostic export-filter center (default: 600)")
    ap.add_argument("--event-windows-only", action="store_true",
                    help="omit full APU/DMC/stop/queue CSVs and retain only frame cycles plus the filtered event export")
    ap.add_argument("--cpu-instruction-trace-out", type=Path, default=None,
                    help="diagnostic CSV of source CPU instruction boundaries in a bounded cycle window")
    ap.add_argument("--cpu-cycle-start", type=int, default=None,
                    help="inclusive source CPU cycle start for --cpu-instruction-trace-out")
    ap.add_argument("--cpu-cycle-end", type=int, default=None,
                    help="exclusive source CPU cycle end for --cpu-instruction-trace-out")
    args = ap.parse_args()
    if args.end_frame < 1:
        ap.error("--end-frame must be positive")
    if args.event_cycle_window_radius < 0:
        ap.error("--event-cycle-window-radius must be nonnegative")
    if args.event_cycle_windows is not None and not args.export_dmc_state:
        ap.error("--event-cycle-windows requires --export-dmc-state")
    if args.event_windows_only and (not args.export_dmc_state or args.event_cycle_windows is None):
        ap.error("--event-windows-only requires --export-dmc-state and --event-cycle-windows")
    cpu_trace_values = (args.cpu_instruction_trace_out, args.cpu_cycle_start, args.cpu_cycle_end)
    if any(value is not None for value in cpu_trace_values) and not all(value is not None for value in cpu_trace_values):
        ap.error("--cpu-instruction-trace-out, --cpu-cycle-start, and --cpu-cycle-end must be supplied together")
    if args.cpu_cycle_start is not None and (args.cpu_cycle_start < 0 or args.cpu_cycle_end <= args.cpu_cycle_start):
        ap.error("CPU instruction trace cycle window must be nonnegative and end after start")
    rom = ROM_PATH.read_bytes()
    actual = sha256(rom)
    if actual != EXPECTED_ROM_SHA256:
        raise SystemExit(f"ROM identity mismatch: {actual}")
    input_rows = load_input_timeline(args.input_timeline)
    event_cycle_windows = load_event_cycle_windows(args.event_cycle_windows, args.event_cycle_window_radius)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    sound_event_path = args.out_dir / "source_apu_dmc_state_events.csv.gz"
    sound_event_stream = None
    sound_event_writer = None
    if args.export_dmc_state:
        sound_event_stream = gzip.open(sound_event_path, "wt", newline="", encoding="utf-8", compresslevel=1)
        sound_event_writer = csv.DictWriter(sound_event_stream, fieldnames=SOUND_EVENT_FIELDS, extrasaction="ignore")
        sound_event_writer.writeheader()
    frame_update_stream = None
    frame_update_writer = None
    if args.source_frame_updates_out is not None:
        args.source_frame_updates_out.parent.mkdir(parents=True, exist_ok=True)
        frame_update_stream = args.source_frame_updates_out.open("w", newline="", encoding="utf-8")
        frame_update_writer = csv.DictWriter(
            frame_update_stream,
            fieldnames=("sequence", "source_frame", "cycle", "hook_cycles", "fhcnt_before_update",
                        "fhcnt_after_update", "frame_counter_before", "frame_counter_after", "frame_mode"),
        )
        frame_update_writer.writeheader()
    cpu_instruction_stream = None
    cpu_instruction_writer = None
    cpu_instruction_fields = (
        "sequence", "source_frame", "cycle_start", "cycle_at_sound_hook", "cycle_after_instruction",
        "hook_cycles", "instruction_pc", "opcode", "prg_bank_8k", "pc_after_instruction",
        "base_cycles", "extra_cycles", "frame_update_fired", "frame_counter_before",
        "frame_counter_after_hook", "frame_fhcnt_before", "frame_fhcnt_after_hook",
        "dmc_acc_before", "dmc_acc_after_hook", "dmc_period", "dmc_have_dma_after_hook",
        "dmc_have_sample_after_hook", "dmc_dma_reads_this_hook", "cpu_credit_before_instruction",
        "cpu_credit_after_base_charge", "cpu_credit_after_instruction",
    )
    cpu_instruction_window = None
    if args.cpu_instruction_trace_out is not None:
        args.cpu_instruction_trace_out.parent.mkdir(parents=True, exist_ok=True)
        cpu_instruction_stream = args.cpu_instruction_trace_out.open("w", newline="", encoding="utf-8")
        cpu_instruction_writer = csv.DictWriter(cpu_instruction_stream, fieldnames=cpu_instruction_fields)
        cpu_instruction_writer.writeheader()
        cpu_instruction_window = (args.cpu_cycle_start, args.cpu_cycle_end)
    machine = Machine(rom, input_rows, sound_event_writer, event_cycle_windows, frame_update_writer,
                      cpu_instruction_writer, cpu_instruction_window)
    try:
        machine.run(args.end_frame)
    finally:
        if sound_event_stream is not None:
            sound_event_stream.close()
        if frame_update_stream is not None:
            frame_update_stream.close()
        if cpu_instruction_stream is not None:
            cpu_instruction_stream.close()
    if not args.event_windows_only:
        with (args.out_dir / "source_apu_writes.csv").open("w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=("source_frame", "cycle", "frame_cycle", "pc", "address", "value"))
            writer.writeheader(); writer.writerows(machine.events)
        with (args.out_dir / "source_dmc_dma_reads.csv").open("w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=("source_frame", "cycle", "address", "value", "index", "phase", "prg_bank_8k", "hook_sequence"))
            writer.writeheader(); writer.writerows(machine.dmc_events)
    with (args.out_dir / "source_frame_cycles.csv").open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=("source_frame", "cycle_start", "cycle_end", "cycle_delta"))
        writer.writeheader(); writer.writerows(machine.frame_stats)
    if not args.event_windows_only:
        with (args.out_dir / "source_title_stop_markers.csv").open("w", newline="") as f:
            fields = ("source_frame", "cycle", "pc", "mapped_prg_bank_8000", "accumulator_before_instruction", "opcode", "immediate_stop_value")
            writer = csv.DictWriter(f, fieldnames=fields)
            writer.writeheader(); writer.writerows(machine.stop_events)
        with (args.out_dir / "source_sound_queue_nonzero_writes.csv").open("w", newline="") as f:
            fields = ("source_frame", "cycle", "pc", "address", "value")
            writer = csv.DictWriter(f, fieldnames=fields)
            writer.writeheader(); writer.writerows(machine.queue_events)
    input_hash = sha256(args.input_timeline.read_bytes()) if args.input_timeline else None
    start_input_frames = [frame for frame, row in input_rows.items() if row.get("start")]
    report = {
        "purpose": "diagnostics-only ROM-derived CPU/PPU/MMC3/APU/DMC event generation; no FCEUX trace used as scheduler input",
        "source_rom_sha256": actual,
        "cpu_engine": "Py65 1.2.0, upstream tag v1.2.0; temporary diagnostic environment only",
        "pinned_fceux_semantics": "2.7.0 a6d03e7968bd77a8156a7c9b628a673753f2f4c6 CPU fixed-point 16/48 scheduler, sound hook ordering, MMC3 and DMC logic",
        "input": "all buttons released" if args.input_timeline is None else "explicit source-frame P1 input timeline",
        "input_timeline_path": args.input_timeline.relative_to(ROOT).as_posix() if args.input_timeline and args.input_timeline.is_relative_to(ROOT) else (str(args.input_timeline) if args.input_timeline else None),
        "input_timeline_sha256": input_hash,
        "start_pressed_source_frames_in_timeline": start_input_frames,
        "source_frames_advanced": args.end_frame,
        "source_cpu_cycles": machine.cpu_cycles,
        "diagnostic_irq_boundary_candidate": {
            "policy": "at each source line's runppu(274) before MMC3 clock only, defer the next whole opcode if its base cycles exceed remaining scaled PPU credit; no absolute cycle offset",
            "deferred_instruction_events": machine.deferred_instruction_events,
        },
        "apu_write_count": len(machine.events),
        "dmc_dma_reads": len(machine.dmc_events),
        "dmc_dma_output_bytes": sum(1 for e in machine.dmc_events if int(e["index"]) % 4 == 3),
        "title_stop_markers": machine.stop_events,
        "nonzero_sound_queue_writes": machine.queue_events,
        "frame_cycle_sum": sum(x["cycle_delta"] for x in machine.frame_stats),
        "outputs": {},
        "limitations": [
            "The runner does not render PPU pixels or emulate the complete 2C02 register pipeline.",
            "The PPU scheduler is a ROM-independent NTSC dot/frame model with NewPPU vblank and MMC3 slot-2 hook timing; exact intra-line background/sprite fetch scheduling and PPU register side effects are simplified.",
            "The model is diagnostics-only and cannot establish physical NES DMC bus arbitration or exact WaveHi PCM.",
        ],
    }
    report["outputs"] = {
        "source_frame_cycles.csv": sha256((args.out_dir / "source_frame_cycles.csv").read_bytes()),
    }
    if not args.event_windows_only:
        report["outputs"].update({
            "source_apu_writes.csv": sha256((args.out_dir / "source_apu_writes.csv").read_bytes()),
            "source_dmc_dma_reads.csv": sha256((args.out_dir / "source_dmc_dma_reads.csv").read_bytes()),
            "source_title_stop_markers.csv": sha256((args.out_dir / "source_title_stop_markers.csv").read_bytes()),
            "source_sound_queue_nonzero_writes.csv": sha256((args.out_dir / "source_sound_queue_nonzero_writes.csv").read_bytes()),
        })
    if args.export_dmc_state:
        report["source_dmc_state_event_export"] = {
            "path": sound_event_path.name,
            "sha256": sha256(sound_event_path.read_bytes()),
            "event_rows": machine.sound_event_sequence,
            "event_types": {
                **machine.sound_event_type_counts,
            },
            "captured_pcm_or_fceux_scheduler_input": False,
            "event_cycle_window_filter": None if args.event_cycle_windows is None else {
                "path": args.event_cycle_windows.relative_to(ROOT).as_posix() if args.event_cycle_windows.is_relative_to(ROOT) else str(args.event_cycle_windows),
                "sha256": sha256(args.event_cycle_windows.read_bytes()),
                "radius_cycles": args.event_cycle_window_radius,
                "window_count": len(event_cycle_windows or []),
                "used_only_for_post_run_event_export_filter": True,
            },
            "full_apu_dmc_csv_tables_omitted": args.event_windows_only,
        }
    if args.source_frame_updates_out is not None:
        report["source_frame_updates_export"] = {
            "path": str(args.source_frame_updates_out),
            "sha256": sha256(args.source_frame_updates_out.read_bytes()),
            "event_rows": machine.frame_update_sequence,
            "semantics": "source CPU-stepper events; subtract instruction-hook cycle batches and emit one frame update at the hook endpoint when the fixed-point counter expires",
            "used_fceux_timestamps_or_pcm_as_scheduler_input": False,
        }
    if args.cpu_instruction_trace_out is not None:
        cycle_start, cycle_end = cpu_instruction_window
        report["source_cpu_instruction_trace"] = {
            "path": str(args.cpu_instruction_trace_out),
            "sha256": sha256(args.cpu_instruction_trace_out.read_bytes()),
            "event_rows": machine.cpu_instruction_sequence,
            "cycle_window": {"start_inclusive": args.cpu_cycle_start, "end_exclusive": args.cpu_cycle_end},
            "semantics": "ROM-only Py65 instruction execution; DMC/frame state snapshots at the modeled FCEUX sound-hook boundary before instruction semantics",
            "used_fceux_timestamps_or_pcm_as_scheduler_input": False,
            "source_mmc3_irq_assertions_in_window": [event for event in machine.mmc3_irq_events if cycle_start <= event["cycle"] < cycle_end],
            "source_cpu_interrupt_accepts_in_window": [event for event in machine.cpu_interrupt_events if cycle_start <= event["cycle"] < cycle_end],
        }
    if args.compare_fceux:
        report["fceux_post_run_validation"] = compare_to_fceux(machine, args.fceux_trace.resolve(), args.compare_through_frame)
    if args.input_timeline is not None:
        report["same_input_title_stop_post_run_validation"] = validate_title_stop(machine, TITLE_PC_TRACE, TITLE_FRAME_STATE)
    (args.out_dir / "source_stepper_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    summary = ("source_frames_advanced", "source_cpu_cycles", "apu_write_count", "dmc_dma_reads", "dmc_dma_output_bytes")
    output_summary = {k: report[k] for k in summary}
    if args.export_dmc_state:
        output_summary["dmc_state_event_rows"] = machine.sound_event_sequence
        output_summary["dmc_state_event_path"] = str(sound_event_path)
    print(json.dumps(output_summary, indent=2))
    print(args.out_dir / "source_stepper_report.json")


if __name__ == "__main__":
    main()

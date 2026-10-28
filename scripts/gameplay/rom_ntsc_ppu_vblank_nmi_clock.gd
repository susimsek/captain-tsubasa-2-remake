extends RefCounted
class_name RomNtscPpuVblankNmiClock
## Isolated RP2C02 timing component for vblank status and the delayed NMI line.
## It does not execute a CPU, sample a CPU interrupt boundary, or drive the game
## scheduler. The caller must provide exact register accesses/cycle advancement.

const DOTS_PER_SCANLINE := 341
const SCANLINES_PER_FRAME := 262
const VBLANK_SCANLINE := 241
const PRE_RENDER_SCANLINE := 261
const PPUCTRL_NMI_ENABLE := 0x80
const PPUMASK_RENDER_BG := 0x08
const PPUMASK_RENDER_SPRITES := 0x10
const STATUS_OVERFLOW := 0x20
const STATUS_SPRITE_ZERO := 0x40
const STATUS_VBLANK := 0x80
const STATUS_FLAGS := 0xE0
const PPUMASK_WRITE_DELAY_DOTS := 3

var error_message := ""
var frame_index := 0
var scanline := 0
var dot := 0
var total_dots := 0
var ppuctrl := 0
var ppumask := 0
var _ppumask_pending := 0
var _ppumask_delay := 0
var status_flags := 0
var write_toggle_second := false
var suppress_vblank_set := false
var suppress_nmi := false
var nmi_delay := false
var nmi_out := false


## Reset to an explicit PPU state. This is useful for isolated boundary checks;
## it is not a trace import and does not infer state from a game frame number.
func reset(initial_state: Dictionary = {}) -> bool:
	error_message = ""
	frame_index = int(initial_state.get("frame", 0))
	scanline = int(initial_state.get("scanline", 0))
	dot = int(initial_state.get("dot", 0))
	total_dots = int(initial_state.get("total_dots", 0))
	ppuctrl = int(initial_state.get("ppuctrl", 0))
	ppumask = int(initial_state.get("ppumask", 0))
	_ppumask_pending = int(initial_state.get("ppumask_pending", ppumask))
	_ppumask_delay = int(initial_state.get("ppumask_delay", 0))
	status_flags = int(initial_state.get("status_flags", 0))
	write_toggle_second = bool(initial_state.get("write_toggle_second", false))
	suppress_vblank_set = bool(initial_state.get("suppress_vblank_set", false))
	suppress_nmi = bool(initial_state.get("suppress_nmi", false))
	nmi_delay = bool(initial_state.get("nmi_delay", false))
	nmi_out = bool(initial_state.get("nmi_out", false))
	if frame_index < 0 or scanline < 0 or scanline >= SCANLINES_PER_FRAME \
			or dot < 0 or dot >= DOTS_PER_SCANLINE or total_dots < 0:
		return _fail("Initial PPU position is outside NTSC frame geometry.")
	if ppuctrl < 0 or ppuctrl > 0xFF or ppumask < 0 or ppumask > 0xFF \
			or _ppumask_pending < 0 or _ppumask_pending > 0xFF \
			or _ppumask_delay < 0 or _ppumask_delay > PPUMASK_WRITE_DELAY_DOTS:
		return _fail("Initial PPU register state is outside byte/delay bounds.")
	if status_flags & ~STATUS_FLAGS != 0:
		return _fail("Initial status_flags may contain only PPUSTATUS bits 5–7.")
	return true


## Advance the PPU's actual NTSC dot clock. Each item describes a PPU line
## transition or a change on the delayed NMI output; no frame cadence is guessed.
func advance_ppu_dots(count: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if count < 0:
		_fail("PPU dot count cannot be negative.")
		return events
	for _step in range(count):
		_tick_one_dot(events)
	return events


## NTSC CPU and PPU clocks share a crystal: one CPU cycle advances exactly
## three PPU dots. CPU bus phases and instruction boundaries remain caller-owned.
func advance_cpu_cycles(count: int) -> Array[Dictionary]:
	if count < 0:
		_fail("CPU cycle count cannot be negative.")
		var empty_events: Array[Dictionary] = []
		return empty_events
	return advance_ppu_dots(count * 3)


## Apply a CPU-side write at the current PPU cursor. The delayed pipeline is
## advanced only by a subsequent call to advance_ppu_dots/advance_cpu_cycles.
func write_ppuctrl(value: int) -> void:
	ppuctrl = value & 0xFF


## Rendering-enable changes reach the PPU pipeline after three dots.
func write_ppumask(value: int) -> void:
	_ppumask_pending = value & 0xFF
	_ppumask_delay = PPUMASK_WRITE_DELAY_DOTS


## Supply the two non-vblank status bits only when a decoded source event owns
## them. The model does not fabricate sprite status from an absent renderer.
func set_sprite_status_flags(sprite_zero: bool, overflow: bool) -> void:
	status_flags &= STATUS_VBLANK
	if sprite_zero:
		status_flags |= STATUS_SPRITE_ZERO
	if overflow:
		status_flags |= STATUS_OVERFLOW


## Read $2002. The lower bus bits are intentionally supplied by the caller.
## The read clears vblank and the $2005/$2006 write toggle, with the documented
## vblank-set/NMI race handled at scanline 241 dots 1–3.
func read_ppustatus(open_bus_low: int = 0) -> int:
	var value := (status_flags & STATUS_FLAGS) | (open_bus_low & 0x1F)
	status_flags &= ~STATUS_VBLANK
	write_toggle_second = false
	if scanline == VBLANK_SCANLINE:
		match dot:
			1:
				suppress_vblank_set = true
				suppress_nmi = true
			2, 3:
				suppress_nmi = true
	return value


func get_state() -> Dictionary:
	return {
		"frame": frame_index,
		"scanline": scanline,
		"dot": dot,
		"total_dots": total_dots,
		"ppuctrl": ppuctrl,
		"ppumask": ppumask,
		"ppumask_pending": _ppumask_pending,
		"ppumask_delay": _ppumask_delay,
		"status_flags": status_flags,
		"write_toggle_second": write_toggle_second,
		"suppress_vblank_set": suppress_vblank_set,
		"suppress_nmi": suppress_nmi,
		"nmi_delay": nmi_delay,
		"nmi_out": nmi_out,
		"does_execute_cpu": false,
		"does_sample_cpu_interrupt_boundary": false,
	}


func _tick_one_dot(events: Array[Dictionary]) -> void:
	var executing_line := scanline
	var executing_dot := dot
	var executing_frame := frame_index
	var old_nmi_out := nmi_out
	# The PPU's NMI request is delayed by two dots before it is visible at the
	# CPU-facing output. Suppression masks a pending pulse during the $2002 race.
	nmi_out = nmi_delay and not suppress_nmi
	nmi_delay = _nmi_raw()
	if nmi_out != old_nmi_out:
		events.append(_event("nmi_asserted" if nmi_out else "nmi_deasserted",
			executing_frame, executing_line, executing_dot))

	if _ppumask_delay > 0:
		_ppumask_delay -= 1
		if _ppumask_delay == 0:
			ppumask = _ppumask_pending

	if executing_line == VBLANK_SCANLINE and executing_dot == 0:
		# This clears a previous frame's one-dot pre-vblank suppression.
		suppress_nmi = false
	if executing_line == VBLANK_SCANLINE and executing_dot == 1:
		if suppress_vblank_set:
			suppress_vblank_set = false
		else:
			status_flags |= STATUS_VBLANK
			events.append(_event("vblank_set", executing_frame, executing_line, executing_dot))
	if executing_line == PRE_RENDER_SCANLINE and executing_dot == 1:
		var prior_flags := status_flags
		status_flags &= ~STATUS_FLAGS
		suppress_nmi = false
		suppress_vblank_set = false
		write_toggle_second = false
		if prior_flags != status_flags:
			events.append(_event("status_flags_cleared", executing_frame,
				executing_line, executing_dot))

	_advance_position(executing_line, executing_dot)
	total_dots += 1


func _advance_position(executing_line: int, executing_dot: int) -> void:
	# On odd RP2C02 frames, rendering skips dot 340 on the pre-render line.
	# `ppumask` is the effective delayed mask, not the just-written value.
	var rendering := (ppumask & (PPUMASK_RENDER_BG | PPUMASK_RENDER_SPRITES)) != 0
	if executing_line == PRE_RENDER_SCANLINE and executing_dot == 339 \
			and (frame_index & 1) == 1 and rendering:
		scanline = 0
		dot = 0
		frame_index += 1
		return
	dot += 1
	if dot == DOTS_PER_SCANLINE:
		dot = 0
		scanline += 1
		if scanline == SCANLINES_PER_FRAME:
			scanline = 0
			frame_index += 1


func _nmi_raw() -> bool:
	return (status_flags & STATUS_VBLANK) != 0 \
			and (ppuctrl & PPUCTRL_NMI_ENABLE) != 0 \
			and not suppress_nmi


func _event(kind: String, event_frame: int, event_line: int, event_dot: int) -> Dictionary:
	return {
		"kind": kind,
		"frame": event_frame,
		"scanline": event_line,
		"dot": event_dot,
		"total_dot": total_dots,
	}


func _fail(message: String) -> bool:
	error_message = message
	return false

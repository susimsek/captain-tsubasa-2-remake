extends SceneTree

const CLOCK_SCRIPT := preload("res://scripts/gameplay/rom_ntsc_ppu_vblank_nmi_clock.gd")


func _initialize() -> void:
	if not _verify_cpu_to_ppu_ratio():
		quit(1)
		return
	if not _verify_vblank_and_nmi_pipeline():
		quit(1)
		return
	if not _verify_ppuctrl_gate_and_status_read():
		quit(1)
		return
	if not _verify_vblank_races():
		quit(1)
		return
	if not _verify_prerender_clear_and_render_delay():
		quit(1)
		return
	if not _verify_frame_geometry_and_odd_skip():
		quit(1)
		return
	print("PASS: isolated NTSC PPU clock covers vblank/NMI edges, $2002 races, status clear, PPUMASK delay, CPU:PPU ratio, and odd-frame skip.")
	print("LIMIT: no CPU interrupt sampling, ROM scheduler delivery, or KickoffRouteRuntime integration is modeled.")
	quit(0)


func _verify_cpu_to_ppu_ratio() -> bool:
	var clock = CLOCK_SCRIPT.new()
	if not clock.reset():
		return _fail(clock.error_message)
	clock.advance_cpu_cycles(1)
	var state: Dictionary = clock.get_state()
	if int(state["total_dots"]) != 3 or int(state["scanline"]) != 0 \
			or int(state["dot"]) != 3:
		return _fail("One NTSC CPU cycle did not advance exactly three PPU dots.")
	return true


func _verify_vblank_and_nmi_pipeline() -> bool:
	var clock = CLOCK_SCRIPT.new()
	if not clock.reset({"scanline": 241, "dot": 0, "ppuctrl": 0x80}):
		return _fail(clock.error_message)
	clock.advance_ppu_dots(1)
	if (int(clock.get_state()["status_flags"]) & 0x80) != 0:
		return _fail("Vblank asserted before scanline 241 dot 1.")
	var set_events: Array[Dictionary] = clock.advance_ppu_dots(1)
	if (int(clock.get_state()["status_flags"]) & 0x80) == 0 \
			or bool(clock.get_state()["nmi_out"]):
		return _fail("Vblank did not set at dot 241:1, or NMI escaped its delay.")
	if not _has_event(set_events, "vblank_set", 241, 1):
		return _fail("The vblank status edge did not report source position 241:1.")
	clock.advance_ppu_dots(1)
	if bool(clock.get_state()["nmi_out"]):
		return _fail("NMI asserted before the documented two-dot output delay.")
	var nmi_events: Array[Dictionary] = clock.advance_ppu_dots(1)
	if not bool(clock.get_state()["nmi_out"]) \
			or not _has_event(nmi_events, "nmi_asserted", 241, 3):
		return _fail("NMI output did not rise through PPUCTRL.7 two dots after vblank set.")
	return true


func _verify_ppuctrl_gate_and_status_read() -> bool:
	var clock = CLOCK_SCRIPT.new()
	if not clock.reset({"scanline": 241, "dot": 10, "status_flags": 0x80}):
		return _fail(clock.error_message)
	clock.write_ppuctrl(0x80)
	clock.advance_ppu_dots(1)
	if bool(clock.get_state()["nmi_out"]):
		return _fail("A newly enabled NMI output bypassed its two-dot delay.")
	clock.advance_ppu_dots(1)
	if not bool(clock.get_state()["nmi_out"]):
		return _fail("Enabling PPUCTRL.7 while vblank is set did not assert NMI.")
	clock.write_ppuctrl(0)
	clock.advance_ppu_dots(1)
	if not bool(clock.get_state()["nmi_out"]):
		return _fail("Disabling PPUCTRL.7 dropped the delayed output too early.")
	clock.advance_ppu_dots(1)
	if bool(clock.get_state()["nmi_out"]):
		return _fail("Disabling PPUCTRL.7 did not deassert NMI through the delay pipeline.")

	if not clock.reset({"scanline": 241, "dot": 2, "ppuctrl": 0x80,
			"status_flags": 0xE0, "write_toggle_second": true}):
		return _fail(clock.error_message)
	var status := clock.read_ppustatus(0x1F)
	var state: Dictionary = clock.get_state()
	if status != 0xFF or int(state["status_flags"]) != 0x60 \
			or bool(state["write_toggle_second"]):
		return _fail("$2002 must return supplied low bus bits, clear vblank, and reset the write toggle.")
	clock.advance_ppu_dots(4)
	if bool(clock.get_state()["nmi_out"]):
		return _fail("Reading $2002 in the vblank race window allowed a pending NMI pulse.")
	return true


func _verify_vblank_races() -> bool:
	# A read at dot 1 is one dot before the flag set and suppresses both flag/NMI.
	var before = CLOCK_SCRIPT.new()
	if not before.reset({"scanline": 241, "dot": 1, "ppuctrl": 0x80,
			"write_toggle_second": true}):
		return _fail(before.error_message)
	before.read_ppustatus(0x07)
	if bool(before.get_state()["write_toggle_second"]):
		return _fail("$2002 did not clear the scroll/address toggle before vblank.")
	before.advance_ppu_dots(4)
	if (int(before.get_state()["status_flags"]) & 0x80) != 0 \
			or bool(before.get_state()["nmi_out"]):
		return _fail("A dot-1 $2002 read failed to suppress this frame's vblank/NMI.")

	# A dot-3 read occurs after vblank set but before its delayed NMI reaches output.
	var after = CLOCK_SCRIPT.new()
	if not after.reset({"scanline": 241, "dot": 3, "ppuctrl": 0x80,
			"status_flags": 0x80, "nmi_delay": true}):
		return _fail(after.error_message)
	if (after.read_ppustatus(0) & 0x80) == 0:
		return _fail("A dot-3 $2002 read should observe vblank set before clearing it.")
	var race_events: Array[Dictionary] = after.advance_ppu_dots(1)
	if bool(after.get_state()["nmi_out"]) \
			or _has_event(race_events, "nmi_asserted", 241, 3):
		return _fail("A dot-3 $2002 race read did not suppress the pending NMI output.")

	# At dot 4 the suppression window has passed; the already-pending request is visible.
	var later = CLOCK_SCRIPT.new()
	if not later.reset({"scanline": 241, "dot": 4, "ppuctrl": 0x80,
			"status_flags": 0x80, "nmi_delay": true}):
		return _fail(later.error_message)
	later.read_ppustatus(0)
	later.advance_ppu_dots(1)
	if not bool(later.get_state()["nmi_out"]):
		return _fail("A post-race $2002 read incorrectly cancelled an already pending NMI.")
	return true


func _verify_prerender_clear_and_render_delay() -> bool:
	var clock = CLOCK_SCRIPT.new()
	if not clock.reset({"scanline": 261, "dot": 1, "status_flags": 0xE0,
			"write_toggle_second": true}):
		return _fail(clock.error_message)
	var events: Array[Dictionary] = clock.advance_ppu_dots(1)
	var state: Dictionary = clock.get_state()
	if int(state["status_flags"]) != 0 or bool(state["write_toggle_second"]) \
			or not _has_event(events, "status_flags_cleared", 261, 1):
		return _fail("Pre-render dot 1 did not clear status flags and the write toggle.")
	clock.reset()
	clock.write_ppumask(0x08)
	clock.advance_ppu_dots(2)
	if int(clock.get_state()["ppumask"]) != 0:
		return _fail("PPUMASK rendering change took effect before the three-dot delay.")
	clock.advance_ppu_dots(1)
	if int(clock.get_state()["ppumask"]) != 0x08:
		return _fail("PPUMASK rendering change did not apply after three PPU dots.")
	return true


func _verify_frame_geometry_and_odd_skip() -> bool:
	var clock = CLOCK_SCRIPT.new()
	if not clock.reset({"frame": 0}):
		return _fail(clock.error_message)
	clock.advance_ppu_dots(89342)
	if int(clock.get_state()["frame"]) != 1 \
			or int(clock.get_state()["scanline"]) != 0 \
			or int(clock.get_state()["dot"]) != 0:
		return _fail("Even NTSC frame did not contain 341×262 PPU dots.")
	if not clock.reset({"frame": 1, "ppumask": 0x08}):
		return _fail(clock.error_message)
	clock.advance_ppu_dots(89341)
	if int(clock.get_state()["frame"]) != 2 \
			or int(clock.get_state()["total_dots"]) != 89341:
		return _fail("Odd rendering-enabled NTSC frame did not skip dot 340.")
	if not clock.reset({"frame": 1, "ppumask": 0x10}):
		return _fail(clock.error_message)
	clock.advance_ppu_dots(89341)
	if int(clock.get_state()["frame"]) != 2:
		return _fail("Sprite-only rendering did not enable the odd-frame skip.")
	if not clock.reset({"frame": 1, "ppumask": 0}):
		return _fail(clock.error_message)
	clock.advance_ppu_dots(89342)
	if int(clock.get_state()["frame"]) != 2:
		return _fail("Odd frame without rendering incorrectly skipped a dot.")
	return true


func _has_event(events: Array[Dictionary], kind: String, line: int, at_dot: int) -> bool:
	for event: Dictionary in events:
		if String(event.get("kind", "")) == kind \
				and int(event.get("scanline", -1)) == line \
				and int(event.get("dot", -1)) == at_dot:
			return true
	return false


func _fail(message: String) -> bool:
	push_error(message)
	return false

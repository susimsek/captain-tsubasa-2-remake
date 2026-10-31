extends SceneTree

const VM_SCRIPT := preload("res://scripts/gameplay/kickoff_cutscene_command_vm.gd")
const VISUALS_SCENE := preload("res://scenes/kickoff_cutscene_visuals.tscn")
const FADE_MODEL := preload("res://scripts/opening/prototypes/ea_fade/ea_palette_fade_reference.gd")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var vm := VM_SCRIPT.new() as KickoffCutsceneCommandVm
	var visuals := VISUALS_SCENE.instantiate() as KickoffCutsceneVisuals
	root.add_child(vm)
	root.add_child(visuals)
	await process_frame
	visuals.bind_vm(vm)
	visuals._set_background(0x01, true)
	var source_palette: PackedByteArray = visuals.screen.get_source_background_palette_bytes()
	_check(source_palette.size() == 16, "background $01 exposes its ROM-derived unfaded palette")
	var input_palette := source_palette.duplicate()
	input_palette.append_array(source_palette)
	var screen_on_event := {"kind": "screen_on", "opcode": 0xE9, "event_index": 1, "cpu_address": 0xA2A1}
	for level in [1, 7, 15]:
		vm.screen_fade_palette_step_requested.emit(screen_on_event, level)
		visuals.advance_source_tick()
		var expected: PackedByteArray = FADE_MODEL.build_palette(input_palette, level, level).slice(0, 16)
		_check(visuals.screen.get_background_palette_bytes() == expected, "E9 stages ROM-derived background palette level %d" % level)
	var screen_off_event := {"kind": "screen_off_clear", "opcode": 0xEA, "event_index": 2, "cpu_address": 0xA2D0}
	for level in [14, 7, 0]:
		vm.screen_fade_palette_step_requested.emit(screen_off_event, level)
		visuals.advance_source_tick()
		var expected: PackedByteArray = FADE_MODEL.build_palette(input_palette, level, level).slice(0, 16)
		_check(visuals.screen.get_background_palette_bytes() == expected, "EA stages ROM-derived background palette level %d" % level)
	vm.screen_off_clear_completed.emit(screen_off_event)
	for address in FADE_MODEL.confirmed_ea_zero_fill_addresses():
		_check(int(visuals._ppu_memory.get(address, -1)) == 0, "EA zero-fill reaches PPU address $%04X" % address)
	if _failures == 0:
		print("PASS: E9/EA ROM palette steps and the EA nametable-clear presentation.")
		print("LIMIT: VM-to-palette step timing is checked separately; live gameplay palette source selection and PPU phase remain unresolved.")
	else:
		printerr("FAIL: %d KICK OFF palette presentation assertion(s)" % _failures)
	visuals.queue_free()
	vm.queue_free()
	await process_frame
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)

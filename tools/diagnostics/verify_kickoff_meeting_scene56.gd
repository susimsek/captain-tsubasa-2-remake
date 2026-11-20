extends SceneTree

const VM_SCRIPT := preload("res://scripts/gameplay/kickoff_cutscene_command_vm.gd")
const VISUALS_SCENE := preload("res://scenes/kickoff_cutscene_visuals.tscn")

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
	visuals.prepare_pre_match_meeting_scene()
	var events: Array[Dictionary] = []
	vm.presenter_event.connect(func(event: Dictionary) -> void:
		events.append(event.duplicate(true))
	)
	_check(vm.start_cutscene(0x56), "fresh-match menu selects source scene $56")
	_check(FileAccess.file_exists("res://reference/rom_extract/gameplay/backgrounds/background_0F_layout.json"),
		"scene $56 secondary-background layout is present as ROM-derived runtime data")
	_check(visuals._animations.size() == 1 and visuals._animations[0].animation_id == "0x0C",
		"scene $56 creates its ROM-derived animation $0C")
	var background_load_failed := false
	for gap_variant in visuals.presentation_gaps:
		var gap := str(gap_variant)
		if gap.contains("background $0F") or gap.contains("background 0F"):
			background_load_failed = true
	_check(not background_load_failed,
		"scene $56 secondary background $0F has no loader rejection")
	var budget := 1000
	while vm.is_running() and budget > 0:
		budget -= 1
		vm.advance_scheduler_tick(0)
	_check(budget > 0 and vm.state == VM_SCRIPT.RunState.FINISHED,
		"scene $56 reaches its ROM FF terminator")
	_check(events.size() == 17, "scene $56 emits all 17 byte-indexed ROM events")
	if events.size() == 17:
		_check(int(events[0].get("cpu_address", -1)) == 0xBFBA
			and str(events[0].get("kind", "")) == "dialog_window",
			"scene $56 begins at its ROM F1 command")
		_check(int(events[1].get("cpu_address", -1)) == 0xBFBC
			and int(events[1].get("id", -1)) == 0x0F,
			"scene $56 loads its source FA $0F background command")
		var animation_ids: Array = events[2].get("animation_ids", [])
		_check(int(events[2].get("cpu_address", -1)) == 0xBFBE
			and animation_ids.size() == 1 and int(animation_ids[0]) == 0x0C,
			"scene $56 selects source animation $0C")
		_check(int(events[3].get("target_cpu_address", -1)) == 0xBFD5
			and int(events[4].get("cpu_address", -1)) == 0xBFD5,
			"FE branch resolves into the preserved scene-$58 tail")
	_check(_sound_ids(events) == [0x31, 0x01],
		"scene $56 shared tail preserves both ROM sound commands")
	_check(vm.error_message.is_empty(),
		"scene $56 VM finishes without a manifest or source-byte error")
	if _failures == 0:
		print("PASS: scene $56 source pointer, FE target, 17 commands, and $31/$01 audio queue IDs")
		print("LIMIT: source layout/animation resources load; exact visual parity and task-context return timing remain unresolved")
	else:
		printerr("FAIL: %d scene-$56 assertion(s)" % _failures)
	vm.queue_free()
	visuals.queue_free()
	await process_frame
	quit(0 if _failures == 0 else 1)


func _sound_ids(events: Array[Dictionary]) -> Array[int]:
	var result: Array[int] = []
	for event in events:
		if str(event.get("kind", "")) == "sound_command":
			result.append(int(event.get("id", -1)))
	return result


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)

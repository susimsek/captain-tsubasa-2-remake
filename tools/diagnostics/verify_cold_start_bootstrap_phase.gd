extends SceneTree
## Verify the presenter consumes the ROM-only reset-stepper startup milestones.
## Run: godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_cold_start_bootstrap_phase.gd

const PRESENTER_SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(PRESENTER_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the source-command presenter scene.")
		return
	var presenter := packed.instantiate()
	get_root().add_child(presenter)
	await process_frame
	presenter.set_process(false)
	presenter.get_node("FieldScreen").set_rendering_enabled(false)
	if presenter.state.is_empty() or presenter._startup_phase.is_empty():
		_fail("Presenter did not load its validated ROM-only startup phase resource.")
		return
	if int(presenter._scheduler.get_task_delay(5)) != -1 \
			or bool(presenter._startup_worker_slot_registered):
		_fail("Worker slot $0005 was registered before ROM event `$9F69`.")
		return
	for expected_frame in range(1, 8):
		presenter._advance_source_frame()
		if int(presenter.state.get("source_frame", -1)) != expected_frame:
			_fail("Presenter did not advance through the expected cold-start source frame.")
			return
	if bool(presenter._startup_worker_slot_registered) \
			or int(presenter._scheduler.get_task_delay(5)) != -1:
		_fail("Worker slot became active before the derived frame-8 install event.")
		return
	presenter._advance_source_frame()
	if int(presenter.state.get("source_frame", -1)) != presenter._worker_ready_install_source_frame \
			or not bool(presenter._startup_worker_slot_registered):
		_fail("ROM-derived frame-8 worker install did not register slot $0005.")
		return
	if not bool(presenter.state.get("startup_dispatch_attribute_tail_seed_applied", false)):
		_fail("Startup worker scan did not run at the ROM-derived frame-8 edge.")
		return
	presenter._advance_source_frame()
	if int(presenter.state.get("source_frame", -1)) != presenter._first_nmi_release_source_frame \
			or int(presenter.state.get("scheduler_tick", -1)) != 1:
		_fail("The derived first NMI-ready release did not advance scheduler tick 1.")
		return
	print(JSON.stringify({
		"passed": true,
		"resource": presenter.COLD_START_BOOTSTRAP_PHASE_PATH,
		"source_rom_sha256": presenter.SOURCE_ROM_SHA256,
		"first_literal_scheduler_scan_frame": presenter._first_literal_scheduler_scan_source_frame,
		"worker_install_frame": presenter._worker_ready_install_source_frame,
		"first_ready_worker_scan_frame": presenter._first_ready_worker_scan_source_frame,
		"first_nmi_release_frame": presenter._first_nmi_release_source_frame,
		"scheduler_tick_after_frame_9": presenter._scheduler.scheduler_tick,
		"slot_installed_from_rom_event": presenter._startup_worker_slot_registered,
		"startup_attribute_seed_applied": presenter.state.get("startup_dispatch_attribute_tail_seed_applied", false),
	}))
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

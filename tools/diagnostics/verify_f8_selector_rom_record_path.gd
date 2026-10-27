extends SceneTree
## Verifies the ROM-record -> $75/$76 -> $8E/$8F -> $90/$91 F8 selector path.

const PRESENTER_SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"
const OUTPUT_PATH := "res://reference/diagnostics/f8_selector_source_writer_20261026/godot_selector_runtime_verification.json"
const RECORD_PATH := "res://reference/rom_extract/intro/background_17.bin"
const EXPECTED_RECORD_FILE_OFFSET := "0x00E383"
const EXPECTED_RECORD_CPU_ADDRESS := "0xA373"
const EXPECTED_SELECTOR_VALUES: Array[int] = [0x7C, 0x7E]
const SELECTOR_STAGE_FRAME := 3555
const SELECTOR_COPY_FRAME := 3597


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(PRESENTER_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the source-command presenter scene.")
		return
	var presenter := packed.instantiate() as ColdStartSourceCommandPresenter
	if presenter == null:
		_fail("Could not instantiate the source-command presenter.")
		return
	presenter.name = "F8SelectorRomRecordCheck"
	get_root().add_child(presenter)
	await process_frame
	presenter.propagate_call("set_process", [false])
	presenter.get_node("FieldScreen").set_rendering_enabled(false)
	presenter.set_render_updates_suppressed(true)

	while int(presenter.state.get("source_frame", 0)) < SELECTOR_STAGE_FRAME:
		presenter._advance_source_frame()
		if bool(presenter.state.get("slice_failed", false)):
			_fail("Source presenter failed before selector staging: %s" % str(presenter.state.get("slice_error", "unknown error")))
			return
	var loader_state: Dictionary = presenter.state.get("f8_00_service", {}).get("background_loader", {})
	var staged_selectors: Variant = loader_state.get("record_chr_selector_bytes", [])
	if str(loader_state.get("background_id", "")) != "23" \
			or str(loader_state.get("record_chr_selector_source", {}).get("record_cpu_address", "")) != EXPECTED_RECORD_CPU_ADDRESS \
			or str(loader_state.get("record_chr_selector_source", {}).get("record_file_offset", "")) != EXPECTED_RECORD_FILE_OFFSET \
			or not staged_selectors is Array \
			or staged_selectors.size() != 2 \
			or int(staged_selectors[0]) != EXPECTED_SELECTOR_VALUES[0] \
			or int(staged_selectors[1]) != EXPECTED_SELECTOR_VALUES[1] \
			or int(presenter.state.get("ram_0075_value", -1)) != EXPECTED_SELECTOR_VALUES[0] \
			or int(presenter.state.get("ram_0076_value", -1)) != EXPECTED_SELECTOR_VALUES[1]:
		_fail("Frame %d selector state mismatch: %s" % [SELECTOR_STAGE_FRAME, JSON.stringify({
			"source_frame": presenter.state.get("source_frame", -1),
			"background_id": loader_state.get("background_id", ""),
			"record_selector_source": loader_state.get("record_chr_selector_source", {}),
			"staged_selectors": staged_selectors,
			"ram_0075": presenter.state.get("ram_0075_value", -1),
			"ram_0076": presenter.state.get("ram_0076_value", -1),
		})])
		return

	var record := FileAccess.get_file_as_bytes(RECORD_PATH)
	if record.size() < 2 or int(record[0]) != EXPECTED_SELECTOR_VALUES[0] or int(record[1]) != EXPECTED_SELECTOR_VALUES[1]:
		_fail("The project-owned background-17 record bytes do not contain the expected selectors.")
		return

	while int(presenter.state.get("source_frame", 0)) < SELECTOR_COPY_FRAME:
		presenter._advance_source_frame()
		if bool(presenter.state.get("slice_failed", false)):
			_fail("Source presenter failed before selector copy: %s" % str(presenter.state.get("slice_error", "unknown error")))
			return
	var f8_state: Dictionary = presenter.state.get("f8_00_service", {})
	var selector_pair: Vector2i = presenter.state.get("ram_008E_008F", Vector2i(-1, -1))
	var cursor_pair: Vector2i = presenter.state.get("ram_0090_0091", Vector2i(-1, -1))
	var copy_metadata: Dictionary = f8_state.get("ram_0090_0091_copy", {})
	if selector_pair != Vector2i(EXPECTED_SELECTOR_VALUES[0], EXPECTED_SELECTOR_VALUES[1]) \
			or cursor_pair != selector_pair \
			or str(copy_metadata.get("source_values_basis", "")).find("project-owned background-$17 record bytes 0/1") < 0 \
			or int(copy_metadata.get("executed_source_frame", -1)) != SELECTOR_COPY_FRAME \
			or int(f8_state.get("active_profile_switch_source_frame", -1)) != SELECTOR_COPY_FRAME + 1:
		_fail("Frame %d did not copy the ROM selectors through $8E/$8F to $90/$91." % SELECTOR_COPY_FRAME)
		return

	var report := {
		"result": "PASS",
		"source_rom_sha256": presenter.state.get("rom_sha256", ""),
		"project_owned_record": RECORD_PATH,
		"record_cpu_address": EXPECTED_RECORD_CPU_ADDRESS,
		"record_file_offset": EXPECTED_RECORD_FILE_OFFSET,
		"selectors_hex": "7C 7E",
		"selector_stage_source_frame": SELECTOR_STAGE_FRAME,
		"selector_stage_ram": "$0075/$0076",
		"selector_copy_source_frame": SELECTOR_COPY_FRAME,
		"selector_copy_ram": "$0075/$0076 -> $008E/$008F -> $0090/$0091",
		"profile_switch_source_frame": SELECTOR_COPY_FRAME + 1,
		"cycle_timing_verified_against_fceux_pc_trace": false,
		"runtime_reads_rom_file": false,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var output_file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if output_file == null:
		_fail("Could not write the focused F8 selector verification result.")
		return
	output_file.store_string(JSON.stringify(report, "\t") + "\n")
	presenter.queue_free()
	await process_frame
	print("PASS: F8 ROM selector record path at frames 3555 and 3597.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

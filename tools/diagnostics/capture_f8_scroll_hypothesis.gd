extends SceneTree
## Diagnostic only: compare the current F8 title frame with source-evidenced
## $2005 scroll and $2006 raster inputs. These captures are never runtime assets.

const PRESENTER_SCENE_PATH := "res://scenes/prototypes/cold_start_source_command_presenter.tscn"
const TARGET_SOURCE_FRAME := 3640
const OUTPUT_ROOT := "res://reference/diagnostics/f8_scroll_hypothesis"
const STATE_CHECKPOINTS := [3208, 3209, 3212, 3213, 3214, 3448, 3449, 3452, 3453, 3460, 3461, 3464, 3465, 3468, 3469, 3470, 3473, 3475, 3476, 3477, 3558, 3559, 3596, 3597, 3600, 3640]


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var packed := load(PRESENTER_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load the standalone source presenter.")
		return
	var presenter := packed.instantiate() as ColdStartSourceCommandPresenter
	presenter.name = "F8ScrollHypothesisRuntime"
	get_root().size = Vector2i(256, 240)
	get_root().content_scale_size = Vector2i(256, 240)
	get_root().add_child(presenter)
	await process_frame
	presenter.set_process(false)
	var field_screen: RomPpuNametableScreenRenderer = presenter.get_node("FieldScreen")
	field_screen.set_rendering_enabled(false)
	var state_checkpoints: Array[Dictionary] = []
	var dispatch_trace: Array[Dictionary] = []
	var previous_dispatch_count := int(presenter.state.get("dispatch_count", 0))
	while int(presenter.state.get("source_frame", 0)) < TARGET_SOURCE_FRAME:
		var old_cursor := presenter._script_cursor
		var old_dispatch_count := int(presenter.state.get("dispatch_count", 0))
		presenter._advance_source_frame()
		if bool(presenter.state.get("slice_failed", false)):
			_fail("Source presenter failed before F8 frame %d." % TARGET_SOURCE_FRAME)
			return
		var advanced_frame := int(presenter.state.get("source_frame", 0))
		var current_dispatch_count := int(presenter.state.get("dispatch_count", 0))
		if current_dispatch_count != old_dispatch_count and advanced_frame >= 2600:
			dispatch_trace.append({
				"dispatch_count": current_dispatch_count,
				"source_frame": int(presenter.state.get("source_frame_of_last_dispatch", advanced_frame)),
				"pc": str(presenter.state.get("cutscene_cpu_pointer", "")),
				"bytes": str(presenter.state.get("last_rom_bytes", "")),
				"handler": str(presenter.state.get("last_handler_entry", "")),
				"cursor_before": old_cursor,
				"cursor_after": presenter._script_cursor,
				"pending_handler": presenter._pending_handler,
				"pending_phase": presenter._pending_handler_phase,
				"scheduler_tick": int(presenter.state.get("scheduler_tick", -1)),
				"delay_slot_0005": presenter._scheduler.get_task_delay(5),
			})
		previous_dispatch_count = current_dispatch_count
		if STATE_CHECKPOINTS.has(advanced_frame):
			state_checkpoints.append(_snapshot_source_state(presenter, advanced_frame))
	field_screen.set_rendering_enabled(true)
	await process_frame
	var report := {
		"capture_kind": "diagnostic renderer variants; not runtime assets",
		"source_frame": TARGET_SOURCE_FRAME,
		"state_checkpoints": state_checkpoints,
		"dispatch_trace_from_frame_3300": dispatch_trace,
		"slice_error": str(presenter.state.get("slice_error", "")),
		"unresolved_command": presenter.state.get("unresolved_command", {}).duplicate(true),
		"stopped_before_unmodeled_command": bool(presenter.state.get("stopped_before_unmodeled_command", false)),
		"source_ram_0044": int(presenter.state.get("ram_0044_value", -1)),
		"source_ram_0079": int(presenter.state.get("ram_0079_value", -1)),
		"source_ram_007c": int(presenter.state.get("ram_007C_value", -1)),
		"background_id": int(presenter.state.get("background_id", -1)),
		"visual_preset": int(presenter.state.get("visual_preset", -1)),
		"animation_ids": presenter.state.get("animation_ids", []),
		"renderer_chr_banks": field_screen._chr_banks,
		"renderer_scroll_y": field_screen._scroll_y,
		"renderer_raster_events": field_screen._source_raster_events,
		"renderer_source_mmc3_chr_writes_active": field_screen._source_mmc3_chr_writes_active,
		"f8_title_scroll_y": int(presenter.state.get("f8_title_scroll_y", -1)),
		"f8_title_raster_model": presenter.state.get("f8_title_raster_model", {}).duplicate(true),
		"f8_service": presenter.state.get("f8_00_service", {}).duplicate(true),
		"generic_background_loader": presenter.state.get("generic_background_loader", {}).duplicate(true),
		"background_queue": {
			"pending_packets": presenter._background_01_queue_packets.size(),
			"cursor_0628": presenter._background_01_queue_cursor,
			"generic_committed_packets": presenter._generic_background_committed_packets,
			"generic_committed_writes": presenter._generic_background_committed_writes,
			"background_01_committed_packets": presenter._background_01_committed_packets,
			"background_01_committed_writes": presenter._background_01_committed_writes,
		},
		"title_ppu_sample": {
			"$208e": int(presenter._background_01_ppu_memory.get(0x208E, 0)),
			"$208f": int(presenter._background_01_ppu_memory.get(0x208F, 0)),
			"$20a6": int(presenter._background_01_ppu_memory.get(0x20A6, 0)),
			"$20a7": int(presenter._background_01_ppu_memory.get(0x20A7, 0)),
			"$20a8": int(presenter._background_01_ppu_memory.get(0x20A8, 0)),
			"$20a9": int(presenter._background_01_ppu_memory.get(0x20A9, 0)),
			"$20aa": int(presenter._background_01_ppu_memory.get(0x20AA, 0)),
			"$20ac": int(presenter._background_01_ppu_memory.get(0x20AC, 0)),
			"$23c0": int(presenter._background_01_ppu_memory.get(0x23C0, 0)),
		},
		"source_rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"viewport_variants": [],
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
	var ppu_dump := PackedByteArray()
	ppu_dump.resize(0x4000)
	for address in range(ppu_dump.size()):
		ppu_dump[address] = int(presenter._background_01_ppu_memory.get(address, 0)) & 0xFF
	var ppu_dump_file := FileAccess.open(OUTPUT_ROOT + "/runtime_ppu_03640.bin", FileAccess.WRITE)
	if ppu_dump_file == null:
		_fail("Could not write the runtime PPU memory dump.")
		return
	ppu_dump_file.store_buffer(ppu_dump)
	var runtime_palette_file := FileAccess.open(OUTPUT_ROOT + "/runtime_palette_03640.bin", FileAccess.WRITE)
	if runtime_palette_file == null or presenter._committed_palette.size() != 32:
		_fail("Could not write the runtime committed palette.")
		return
	runtime_palette_file.store_buffer(presenter._committed_palette)
	var runtime_viewport := get_root().get_texture().get_image()
	if runtime_viewport == null or runtime_viewport.get_size() != Vector2i(256, 240):
		_fail("Could not capture the F8 renderer using its source-derived state.")
		return
	var runtime_candidate_path := "%s/frame_%06d.png" % [OUTPUT_ROOT, TARGET_SOURCE_FRAME]
	if runtime_viewport.save_png(runtime_candidate_path) != OK:
		_fail("Could not save the source-derived F8 runtime viewport.")
		return
	report["runtime_viewport_candidate"] = runtime_candidate_path
	var variants := [
		{"name": "current_no_scroll_no_split", "scroll_y": 0, "split": false},
		{"name": "vblank_scroll_1b", "scroll_y": 0x1B, "split": false},
		{"name": "raster_split_only", "scroll_y": 0, "split": true},
		{"name": "vblank_scroll_1b_and_21c0_split", "scroll_y": 0x1B, "split": true},
	]
	for variant in variants:
		field_screen.set_source_raster_events([])
		field_screen.set_scroll_pixels(0, int(variant["scroll_y"]))
		if bool(variant["split"]):
			field_screen.set_source_raster_events([{
				"kind": "ppu_address",
				"scanline": 139,
				"address": 0x21C0,
			}])
		await process_frame
		var viewport_image := get_root().get_texture().get_image()
		if viewport_image == null or viewport_image.get_size() != Vector2i(256, 240):
			_fail("Could not capture the F8 renderer variant %s." % variant["name"])
			return
		var filename := "%s/%s.png" % [OUTPUT_ROOT, variant["name"]]
		if viewport_image.save_png(filename) != OK:
			_fail("Could not save the F8 renderer variant %s." % variant["name"])
			return
		report["viewport_variants"].append({
			"name": variant["name"],
			"scroll_y": variant["scroll_y"],
			"ppu_address_split_21c0_at_scanline_139": variant["split"],
			"candidate": filename,
		})
	var report_file := FileAccess.open(OUTPUT_ROOT + "/variants.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write the F8 scroll hypothesis report.")
		return
	report_file.store_string(JSON.stringify(report, "\t") + "\n")
	get_root().remove_child(presenter)
	presenter.free()
	await process_frame
	print("Captured source-evidenced F8 scroll variants: %s" % OUTPUT_ROOT)
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _snapshot_source_state(presenter: ColdStartSourceCommandPresenter, source_frame: int) -> Dictionary:
	var command_bytes := ""
	if presenter._script_cursor >= 0 and presenter._script_cursor < presenter._script_bytes.size():
		var opcode := int(presenter._script_bytes[presenter._script_cursor])
		command_bytes = "$%02X" % opcode
		if presenter._script_cursor + 1 < presenter._script_bytes.size():
			command_bytes += " $%02X" % int(presenter._script_bytes[presenter._script_cursor + 1])
	return {
		"source_frame": source_frame,
		"background_id": int(presenter.state.get("background_id", -1)),
		"visual_preset": int(presenter.state.get("visual_preset", -1)),
		"ram_0044": int(presenter.state.get("ram_0044_value", -1)),
		"ram_0079": int(presenter.state.get("ram_0079_value", -1)),
		"ram_007c": int(presenter.state.get("ram_007C_value", -1)),
		"dispatch_count": int(presenter.state.get("dispatch_count", -1)),
		"last_dispatch_frame": int(presenter.state.get("source_frame_of_last_dispatch", -1)),
		"last_dispatch_pc": str(presenter.state.get("cutscene_cpu_pointer", "")),
		"last_dispatch_bytes": str(presenter.state.get("last_rom_bytes", "")),
		"scheduler_tick": int(presenter.state.get("scheduler_tick", -1)),
		"delay_slot_0005": presenter._scheduler.get_task_delay(5),
		"script_cursor": presenter._script_cursor,
		"script_command_at_cursor": command_bytes,
		"pending_handler": presenter._pending_handler,
		"pending_handler_phase": presenter._pending_handler_phase,
		"f8_service": presenter.state.get("f8_00_service", {}).duplicate(true),
		"f8_title_scroll_y": int(presenter.state.get("f8_title_scroll_y", -1)),
		"f8_title_raster_model": presenter.state.get("f8_title_raster_model", {}).duplicate(true),
		"f8_loader_packet_index": presenter._f8_title_loader_packet_index,
		"f8_committed_packets": presenter._generic_background_committed_packets,
		"f8_committed_writes": presenter._generic_background_committed_writes,
		"queue_packet_count": presenter._background_01_queue_packets.size(),
		"queue_cursor": presenter._background_01_queue_cursor,
		"ppu_208e": int(presenter._background_01_ppu_memory.get(0x208E, 0)),
		"ppu_20a6": int(presenter._background_01_ppu_memory.get(0x20A6, 0)),
	}

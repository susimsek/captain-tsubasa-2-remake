extends SceneTree
## Capture the ROM-derived C1/82 OAM shadow around the 55-of-56 pose.
## Compare each binary output with reference/opening_capture/ram_states at the
## same source-frame index; runtime outputs are validation data only.

const COMPOSER_SCRIPT := preload("res://scripts/opening/rom_bg08_sprite_oam_composer.gd")
const START_SOURCE_FRAME := 1047
const FIRST_CAPTURE_FRAME := 1150
const LAST_CAPTURE_FRAME := 1159
const OUTPUT_ROOT := "res://reference/diagnostics/bg08_hidden_tail_source_runtime_20261026"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var absolute_root := ProjectSettings.globalize_path(OUTPUT_ROOT)
	if DirAccess.make_dir_recursive_absolute(absolute_root) != OK:
		push_error("Could not create hidden-tail diagnostic directory.")
		quit(1)
		return
	var composer: RomBg08SpriteOamComposer = COMPOSER_SCRIPT.new()
	composer.name = "HiddenTailOamTrace"
	get_root().add_child(composer)
	composer.set_render_updates_suppressed(true)
	if not composer.configure([0xC1, 0x82], START_SOURCE_FRAME):
		push_error("Could not initialize ROM-derived C1/82 OAM compositor: %s" % composer.last_error)
		quit(1)
		return
	var records: Array[Dictionary] = []
	for source_frame in range(START_SOURCE_FRAME, LAST_CAPTURE_FRAME + 1):
		if not composer.advance_to_source_frame(source_frame):
			push_error("Could not advance hidden-tail OAM compositor to %d." % source_frame)
			quit(1)
			return
		if source_frame < FIRST_CAPTURE_FRAME:
			continue
		var oam := composer.oam_bytes()
		var file_path := "%s/shadow_%05d.bin" % [absolute_root, source_frame]
		var output := FileAccess.open(file_path, FileAccess.WRITE)
		if output == null:
			push_error("Could not write OAM shadow capture: %s" % file_path)
			quit(1)
			return
		output.store_buffer(oam)
		output.close()
		var snapshot := composer.debug_snapshot()
		records.append({
			"source_frame": source_frame,
			"slot_5_hex": oam.slice(5 * 4, 6 * 4).hex_encode().to_upper(),
			"animation_82_record_hex": str(snapshot["tracks"][1]["record_bytes_hex"]),
			"animation_82_frame": str(snapshot["tracks"][1]["frame_address"]),
			"animation_82_position_y_q8_8": str(snapshot["tracks"][1]["position_y_q8_8"]),
			"shadow_path": "shadow_%05d.bin" % source_frame,
		})
	var report := {
		"rom_sha256": "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097",
		"capture_kind": "Godot ROM-derived OAM shadow; validation only",
		"ram_reference_pattern": "reference/opening_capture/ram_states/ram_%05d.bin, bytes $0468-$0567",
		"records": records,
	}
	var report_file := FileAccess.open("%s/runtime_oam.json" % OUTPUT_ROOT, FileAccess.WRITE)
	if report_file == null:
		push_error("Could not write hidden-tail OAM report.")
		quit(1)
		return
	report_file.store_string(JSON.stringify(report, "\t") + "\n")
	print("Captured ROM-derived hidden-tail OAM frames %d-%d." % [
		FIRST_CAPTURE_FRAME, LAST_CAPTURE_FRAME,
	])
	quit(0)

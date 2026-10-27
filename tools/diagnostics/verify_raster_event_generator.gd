extends SceneTree
## Focused table comparison for the ROM-derived raster generator.
## Usage: godot --headless --path . --script tools/diagnostics/verify_raster_event_generator.gd

const GENERATOR_SCRIPT := preload("res://scripts/opening/rom_raster_event_generator.gd")
const CAPTURE_TABLE := "res://reference/diagnostics/raster_table_writes_20261024_213332/table_state.csv"


func _initialize() -> void:
	var generator = GENERATOR_SCRIPT.new()
	var output_root := "res://reference/diagnostics/raster_event_generator_compare_%d" % int(Time.get_unix_time_from_system())
	var absolute_root := ProjectSettings.globalize_path(output_root)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	var comparison := FileAccess.open(output_root + "/comparison.csv", FileAccess.WRITE)
	comparison.store_line("source_frame,match,expected_ram_0078_008d,generated_ram_0078_008d,expected_ed,generated_fraction_accumulators")
	if not generator.configure(378):
		_fail(comparison, output_root, generator.last_error)
		return
	var capture := FileAccess.open(CAPTURE_TABLE, FileAccess.READ)
	if capture == null:
		_fail(comparison, output_root, "Could not open the existing same-input RAM table capture.")
		return
	var header := capture.get_line()
	var expected_by_frame: Dictionary = {}
	while not capture.eof_reached():
		var fields := capture.get_line().strip_edges().split(",")
		if fields.size() != 6:
			continue
		var frame := int(fields[0])
		if frame < 378 or frame > 400:
			continue
		var bytes := PackedByteArray()
		for token in fields[5].split(" ", false):
			bytes.append(token.hex_to_int())
		expected_by_frame[frame] = {"bytes": bytes, "ed": fields[4]}
	var all_match := true
	for frame in range(378, 401):
		if not generator.advance_to_source_frame(frame):
			_fail(comparison, output_root, generator.last_error)
			return
		var expected: Dictionary = expected_by_frame.get(frame, {})
		var expected_bytes: PackedByteArray = expected.get("bytes", PackedByteArray())
		var generated_bytes: PackedByteArray = generator.frame_end_table_bytes()
		var same: bool = expected_bytes == generated_bytes
		all_match = all_match and same
		comparison.store_line(",".join([
			str(frame), "MATCH" if same else "MISMATCH",
			_hex_bytes(expected_bytes), _hex_bytes(generated_bytes),
			str(expected.get("ed", "")), _hex_bytes(PackedByteArray(generator.debug_snapshot()["fractional_accumulators"])),
		]))
	comparison.close()
	print("Raster event table comparison: %s (23 frames, 378–400)." % ("PASS" if all_match else "FAIL"))
	print("Details: %s/comparison.csv" % output_root)
	quit(0 if all_match else 1)


func _fail(file: FileAccess, output_root: String, message: String) -> void:
	file.store_line("ERROR," + message.replace(",", ";"))
	file.close()
	push_error(message)
	print("Details: %s/comparison.csv" % output_root)
	quit(1)


func _hex_bytes(bytes: PackedByteArray) -> String:
	var parts: PackedStringArray = []
	for value in bytes:
		parts.append("%02X" % int(value))
	return " ".join(parts)

extends SceneTree
## Diagnostic-only endpoint image comparison. The FCEUX GD screenshot is a
## validation reference only; no screenshot pixels are loaded by game runtime.

const WIDTH := 256
const HEIGHT := 240
const GD_HEADER_BYTES := 11
const REFERENCE_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/screens/route_frame_008953.gd"
const INPUT_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
const INPUT_SHA256 := "87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e"
const GODOT_CAPTURE_PATH := "/tmp/ct2_godot_first_action_menu_recorded_input_8953.png"
const DIFF_PATH := "/tmp/ct2_first_menu_visible_output_diff_8953.png"
const REFERENCE_SHA256 := "cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var input_bytes := FileAccess.get_file_as_bytes(INPUT_PATH)
	if input_bytes.is_empty() or _sha256(input_bytes) != INPUT_SHA256:
		_fail("The same-input route CSV is missing or its hash changed.")
		return
	var reference := FileAccess.get_file_as_bytes(REFERENCE_PATH)
	if reference.size() != GD_HEADER_BYTES + WIDTH * HEIGHT * 4:
		_fail("The FCEUX validation screenshot does not have the expected 256x240 GD layout.")
		return
	if _sha256(reference) != REFERENCE_SHA256:
		_fail("The retained FCEUX endpoint screenshot hash changed.")
		return
	var reference_width := (int(reference[2]) << 8) | int(reference[3])
	var reference_height := (int(reference[4]) << 8) | int(reference[5])
	if reference_width != WIDTH or reference_height != HEIGHT:
		_fail("The FCEUX GD header dimensions differ from 256x240.")
		return
	var godot_image := Image.load_from_file(GODOT_CAPTURE_PATH)
	if godot_image == null or godot_image.is_empty():
		_fail("Run verify_kickoff_recorded_input_path.gd first to produce the Godot background capture.")
		return
	if godot_image.get_width() != WIDTH or godot_image.get_height() != HEIGHT:
		_fail("The Godot capture dimensions differ from the same-input FCEUX screenshot.")
		return
	if godot_image.get_format() != Image.FORMAT_RGBA8:
		godot_image.convert(Image.FORMAT_RGBA8)

	var diff_image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	var exact_pixels := 0
	var total_absolute_channel_error := 0
	var differing_pixels := 0
	for y in HEIGHT:
		for x in WIDTH:
			var index := GD_HEADER_BYTES + (y * WIDTH + x) * 4
			# FCEUX GD stores A,R,G,B; alpha is ignored for the visible RGB comparison.
			var reference_r := int(reference[index + 1])
			var reference_g := int(reference[index + 2])
			var reference_b := int(reference[index + 3])
			var godot_color := godot_image.get_pixel(x, y)
			var godot_r := roundi(godot_color.r * 255.0)
			var godot_g := roundi(godot_color.g * 255.0)
			var godot_b := roundi(godot_color.b * 255.0)
			var matches := godot_r == reference_r and godot_g == reference_g and godot_b == reference_b
			if matches:
				exact_pixels += 1
				diff_image.set_pixel(x, y, Color.BLACK)
			else:
				differing_pixels += 1
				diff_image.set_pixel(x, y, Color.RED)
			total_absolute_channel_error += abs(godot_r - reference_r)
			total_absolute_channel_error += abs(godot_g - reference_g)
			total_absolute_channel_error += abs(godot_b - reference_b)

	var save_error := diff_image.save_png(DIFF_PATH)
	if save_error != OK:
		_fail("Could not save the diagnostic difference image.")
		return
	var total_pixels := WIDTH * HEIGHT
	var exact_percent := 100.0 * float(exact_pixels) / float(total_pixels)
	var mean_channel_error := float(total_absolute_channel_error) / float(total_pixels * 3)
	print("Same-input frame 8953 RGB comparison (%dx%d): %d/%d exact pixels (%.3f%%); %d differ; mean absolute channel error %.4f." % [
		WIDTH, HEIGHT, exact_pixels, total_pixels, exact_percent, differing_pixels, mean_channel_error])
	print("Input CSV SHA-256: " + INPUT_SHA256)
	print("FCEUX screenshot SHA-256: " + REFERENCE_SHA256)
	print("Godot background PNG SHA-256: " + _sha256(FileAccess.get_file_as_bytes(GODOT_CAPTURE_PATH)))
	print("Diagnostic diff image: " + DIFF_PATH)
	print("LIMIT: Godot capture is the background layer only; the FCEUX reference includes the field actors, score/status overlays, and first command menu.")
	quit(0)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)

extends SceneTree
## Validation-only RGB comparison for same-input FCEUX and Godot captures.
## The FCEUX screenshot remains evidence only; no screenshot pixels are used by runtime.
##
## Usage:
## godot --headless --path . --script tools/diagnostics/compare_first_pass_visible_output.gd -- \
##   <fceux-screen.gd> <godot-full-viewport.png> [diff.png]
## Add --require-exact after `--` to return a failure when any visible RGB pixel differs.
##
## The FCEUX GD capture must be 256x240 with its 11-byte header and A/R/G/B pixels.
## The Godot image must be a 256x224 viewport or an integer uniform scale of it.
## This tool does not verify that the captures used identical inputs or frame timing.

const WIDTH := 256
const RAW_HEIGHT := 240
const VIEWPORT_HEIGHT := 224
const VISIBLE_FIRST_ROW := 8
const GD_HEADER_BYTES := 11


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var user_args := OS.get_cmdline_user_args()
	var args: Array[String] = []
	var require_exact := false
	for argument_variant: Variant in user_args:
		var argument := String(argument_variant)
		if argument == "--require-exact":
			if require_exact:
				_fail("--require-exact may be specified only once.")
				return
			require_exact = true
		elif argument.begins_with("--"):
			_fail("Unknown option: " + argument)
			return
		else:
			args.append(argument)
	if args.size() not in [2, 3]:
		_fail("Usage: --script compare_first_pass_visible_output.gd -- [--require-exact] <fceux-screen.gd> <godot-full-viewport.png> [diff.png]")
		return

	var reference_path := String(args[0])
	var godot_path := String(args[1])
	var diff_path := String(args[2]) if args.size() == 3 else ""
	var reference := FileAccess.get_file_as_bytes(reference_path)
	if reference.size() != GD_HEADER_BYTES + WIDTH * RAW_HEIGHT * 4:
		_fail("FCEUX GD file must contain an 11-byte header and exactly 256x240 A/R/G/B pixels: " + reference_path)
		return
	var reference_width := (int(reference[2]) << 8) | int(reference[3])
	var reference_height := (int(reference[4]) << 8) | int(reference[5])
	if reference_width != WIDTH or reference_height != RAW_HEIGHT:
		_fail("FCEUX GD header dimensions are %dx%d; expected 256x240." % [reference_width, reference_height])
		return

	var godot_image := Image.load_from_file(godot_path)
	if godot_image == null or godot_image.is_empty():
		_fail("Could not load Godot viewport PNG: " + godot_path)
		return
	var source_width := godot_image.get_width()
	var source_height := godot_image.get_height()
	if source_width % WIDTH != 0 or source_height % VIEWPORT_HEIGHT != 0:
		_fail("Godot PNG dimensions must be an integer uniform scale of 256x224; got %dx%d." % [
			source_width, source_height,
		])
		return
	var scale_x := source_width / WIDTH
	var scale_y := source_height / VIEWPORT_HEIGHT
	if scale_x != scale_y or scale_x < 1:
		_fail("Godot PNG is not an integer uniform scale of the 256x224 viewport: %dx%d." % [
			source_width, source_height,
		])
		return
	if godot_image.get_format() != Image.FORMAT_RGBA8:
		godot_image.convert(Image.FORMAT_RGBA8)
	if scale_x != 1:
		godot_image.resize(WIDTH, VIEWPORT_HEIGHT, Image.INTERPOLATE_NEAREST)

	var diff_image := Image.create(WIDTH, VIEWPORT_HEIGHT, false, Image.FORMAT_RGBA8) \
		if not diff_path.is_empty() else null
	var exact_pixels := 0
	var total_absolute_channel_error := 0
	var differing_pixels := 0
	var first_diff := Vector2i(-1, -1)
	var first_reference_rgb := ""
	var first_godot_rgb := ""
	for y in VIEWPORT_HEIGHT:
		for x in WIDTH:
			var reference_index := GD_HEADER_BYTES + ((y + VISIBLE_FIRST_ROW) * WIDTH + x) * 4
			# FCEUX GD pixels are A,R,G,B; compare RGB and ignore alpha.
			var reference_r := int(reference[reference_index + 1])
			var reference_g := int(reference[reference_index + 2])
			var reference_b := int(reference[reference_index + 3])
			var godot_color := godot_image.get_pixel(x, y)
			var godot_r := roundi(godot_color.r * 255.0)
			var godot_g := roundi(godot_color.g * 255.0)
			var godot_b := roundi(godot_color.b * 255.0)
			var matches := godot_r == reference_r and godot_g == reference_g and godot_b == reference_b
			if matches:
				exact_pixels += 1
				if diff_image != null:
					diff_image.set_pixel(x, y, Color.BLACK)
			else:
				differing_pixels += 1
				if first_diff.x < 0:
					first_diff = Vector2i(x, y)
					first_reference_rgb = _rgb_hex(reference_r, reference_g, reference_b)
					first_godot_rgb = _rgb_hex(godot_r, godot_g, godot_b)
				if diff_image != null:
					diff_image.set_pixel(x, y, Color.RED)
			total_absolute_channel_error += abs(godot_r - reference_r)
			total_absolute_channel_error += abs(godot_g - reference_g)
			total_absolute_channel_error += abs(godot_b - reference_b)

	if diff_image != null:
		var save_error := diff_image.save_png(diff_path)
		if save_error != OK:
			_fail("Could not save diff PNG: " + diff_path)
			return

	var total_pixels := WIDTH * VIEWPORT_HEIGHT
	var exact_percent := 100.0 * float(exact_pixels) / float(total_pixels)
	var mean_channel_error := float(total_absolute_channel_error) / float(total_pixels * 3)
	print("Visible RGB comparison (%dx%d): %d/%d exact pixels (%.3f%%); %d differ; mean absolute channel error %.4f." % [
		WIDTH, VIEWPORT_HEIGHT, exact_pixels, total_pixels, exact_percent,
		differing_pixels, mean_channel_error,
	])
	print("FCEUX raw rows %d..%d were compared after the established 8-row crop; Godot image scale was %dx." % [
		VISIBLE_FIRST_ROW, VISIBLE_FIRST_ROW + VIEWPORT_HEIGHT - 1, scale_x,
	])
	print("FCEUX screenshot SHA-256: " + _sha256(reference))
	print("Godot viewport PNG SHA-256: " + _sha256(FileAccess.get_file_as_bytes(godot_path)))
	print("First differing pixel in 256x224 viewport coordinates: %s; FCEUX RGB=%s; Godot RGB=%s." % [
		str(first_diff) if first_diff.x >= 0 else "none",
		first_reference_rgb if first_diff.x >= 0 else "none",
		first_godot_rgb if first_diff.x >= 0 else "none",
	])
	if not diff_path.is_empty():
		print("Diagnostic diff PNG: " + diff_path)
	print("LIMIT: this tool does not establish same-input provenance, frame/subframe alignment, raster state, or audio parity.")
	if require_exact and differing_pixels > 0:
		printerr("FAIL: --require-exact requested, but %d visible RGB pixels differ." % differing_pixels)
		quit(1)
		return
	if require_exact:
		print("PASS: --require-exact found no differing visible RGB pixels.")
	quit(0)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _rgb_hex(red: int, green: int, blue: int) -> String:
	return "#%02X%02X%02X" % [red, green, blue]


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)

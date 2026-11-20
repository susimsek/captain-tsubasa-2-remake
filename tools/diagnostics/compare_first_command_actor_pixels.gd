extends SceneTree
## Compares the ROM-built first-command actor layer against one retained FCEUX
## frame. The FCEUX image is validation-only and is never used by runtime.

const PRESENTER_SCRIPT := preload("res://scripts/gameplay/first_command_actor_source_presenter.gd")
const REFERENCE_PATH := "res://reference/diagnostics/kickoff_select_test_20261027/screens/route_frame_008953.gd"
const REFERENCE_SHA256 := "cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559"
const WIDTH := 256
const RAW_HEIGHT := 240
const HEADER_BYTES := 11
const VISIBLE_TOP := 8

# The route's shared presentation applies the raw-to-visible crop. The actor
# OAM layer must remain at local origin so it receives that crop exactly once.
const ROUTE_ROOT_Y := -8


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var reference := FileAccess.get_file_as_bytes(REFERENCE_PATH)
	if reference.size() != HEADER_BYTES + WIDTH * RAW_HEIGHT * 4 \
			or _sha256(reference) != REFERENCE_SHA256:
		_fail("The frame-8953 FCEUX validation image is missing, malformed, or has changed.")
		return
	if int(reference[2]) * 256 + int(reference[3]) != WIDTH \
			or int(reference[4]) * 256 + int(reference[5]) != RAW_HEIGHT:
		_fail("The FCEUX validation image is not 256x240.")
		return

	var presenter: Variant = PRESENTER_SCRIPT.new()
	presenter.name = "ActorPixelComparisonPresenter"
	root.add_child(presenter)
	await process_frame
	# These are the route's source-derived endpoint inputs. The presenter itself
	# builds actor records, OAM, palette, and CHR exclusively from hashed ROM data.
	if not presenter.configure_endpoint_pose(0x08, 0x08, 0x40, 0x0F):
		_fail("ROM-derived actor presentation failed: " + str(presenter.last_error))
		return
	if presenter.last_sprite_chr_banks != [0x08, 0x09, 0x0A, 0x0B]:
		_fail("The ROM actor packet did not select the audited CHR bank sequence.")
		return
	var oam_layer: Variant = presenter.get_node_or_null("FirstCommandRomActorOam")
	if oam_layer == null:
		_fail("The presenter did not create its ROM OAM renderer.")
		return
	if not is_equal_approx(float(oam_layer.position.y), 0.0):
		_fail("The actor layer adds an extra vertical offset on top of the shared crop.")
		return
	var actor_image: Image = oam_layer.rendered_image()
	if actor_image == null or actor_image.get_width() != WIDTH \
			or actor_image.get_height() != RAW_HEIGHT:
		_fail("The ROM actor renderer did not produce a 256x240 layer.")
		return

	var opaque_count := 0
	for y in RAW_HEIGHT:
		for x in WIDTH:
			if actor_image.get_pixel(x, y).a > 0.5:
				opaque_count += 1
	if opaque_count == 0:
		_fail("The ROM-derived actor layer contains no opaque sprite pixels.")
		return

	var current := _compare_actor_pixels(actor_image, reference, ROUTE_ROOT_Y)
	if current.is_empty():
		_fail("Actor pixels fall outside the sampled 224-line comparison window.")
		return
	print("ROM-derived actor-only comparison at frame 8953: %d opaque pixels; current composed Y=%d: %s." % [
		opaque_count, ROUTE_ROOT_Y, _format_metrics(current)])
	print("ROM actor CHR banks: %s; generated sprites: %d; palette bytes: %d." % [
		str(presenter.last_sprite_chr_banks),
		int(presenter.last_build_result.get("sprites_written", 0)),
		presenter.last_sprite_palette.size()])
	print("LIMIT: samples RGB only where the ROM renderer emits an opaque pixel; it does not count reference-only pixels, reproduce the background, or prove full-frame/scanline timing parity.")
	quit(0)


func _compare_actor_pixels(actor_image: Image, reference: PackedByteArray,
		display_offset_y: int) -> Dictionary:
	var sampled := 0
	var exact := 0
	var absolute_error := 0
	for y in RAW_HEIGHT:
		var visible_y := y + display_offset_y
		var reference_y := visible_y + VISIBLE_TOP
		if reference_y < 0 or reference_y >= RAW_HEIGHT:
			continue
		for x in WIDTH:
			var actor_color := actor_image.get_pixel(x, y)
			if actor_color.a <= 0.5:
				continue
			var byte_index := HEADER_BYTES + (reference_y * WIDTH + x) * 4
			# FCEUX .gd image pixels are stored as A,R,G,B; alpha is ignored.
			var red := roundi(actor_color.r * 255.0)
			var green := roundi(actor_color.g * 255.0)
			var blue := roundi(actor_color.b * 255.0)
			var ref_red := int(reference[byte_index + 1])
			var ref_green := int(reference[byte_index + 2])
			var ref_blue := int(reference[byte_index + 3])
			sampled += 1
			if red == ref_red and green == ref_green and blue == ref_blue:
				exact += 1
			absolute_error += abs(red - ref_red) + abs(green - ref_green) + abs(blue - ref_blue)
	if sampled == 0:
		return {}
	return {"sampled": sampled, "exact": exact, "error": absolute_error}


func _format_metrics(metrics: Dictionary) -> String:
	var sampled := int(metrics["sampled"])
	return "%d/%d exact (%.3f%%), mean absolute RGB-channel error %.4f" % [
		int(metrics["exact"]), sampled,
		100.0 * float(metrics["exact"]) / float(sampled),
		float(metrics["error"]) / float(sampled * 3)]


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)

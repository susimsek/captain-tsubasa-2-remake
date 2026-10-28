extends SceneTree
## Verifies the ROM-byte input derivation and renderer path for F015 packets.
## It intentionally supplies no endpoint PPU/RAM capture to the runtime presenter.

const PRESENTER_SCRIPT := preload("res://scripts/gameplay/first_match_field_candidate_presenter.gd")
const PRODUCER_SCRIPT := preload("res://scripts/gameplay/first_command_field_packet_producer.gd")
const SCREEN_SCRIPT := preload("res://scripts/opening/rom_ppu_nametable_screen_renderer.gd")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen := SCREEN_SCRIPT.new() as RomPpuNametableScreenRenderer
	root.add_child(screen)
	await process_frame

	# This is a source-logic vector only: initialize the placement byte at the
	# fresh-route clear state and execute seven verified $8327 transitions. The
	# eighth callback is then represented by the explicit callback PC below.
	var producer: RefCounted = PRODUCER_SCRIPT.new()
	var previous_05cd := 0
	for callback_index in 7:
		var transition: Dictionary = producer.call("advance_map_placement_state", previous_05cd)
		_check(bool(transition.get("ok", false)), "ROM $8327 transition %d decodes" % (callback_index + 1))
		previous_05cd = int(transition.get("next_05cd", -1))

	var source_state := {
		"menu_context_0621": 0,
		"defender_count_0600": 0,
		"previous_05cd": previous_05cd,
		"callback_handler_pc": 0x8327,
	}
	var presenter: RefCounted = PRESENTER_SCRIPT.new()
	var presented: bool = presenter.call("build_and_apply", screen, source_state)
	_check(presented, "field candidate accepts source state and applies ROM-generated data")
	if presented:
		var status: Dictionary = presenter.get("status")
		var packet_status: Dictionary = status.get("residual_packet_producer", {})
		_check(bool(packet_status.get("applied", false)), "$F015 packet layer is applied")
		_check(str(packet_status.get("status", "")) == "rom_source_packets_applied",
			"packet layer reports source-derived application")
		_check(int(packet_status.get("descriptor_id", -1)) == 0x02,
			"$063D is derived from ROM selector inputs $0621=$00/$0600=$00")
		_check(int(packet_status.get("placement_05ce", -1)) == 0xA0,
			"$05CE is produced by the ROM $8327 placement transition")
		_check(int(packet_status.get("tile_write_count", -1)) == 60
			and int(packet_status.get("attribute_write_count", -1)) == 6,
			"all 60 tile and six attribute writes are generated from preserved ROM streams")
		_check(str(packet_status.get("holder_overlay", "")) == "awaiting_source_holder_coordinates",
			"the separate holder overlay remains withheld without live $0635/$0637 source state")
		_check(str(packet_status.get("source_derivation", {}).get("descriptor_source_pc", ""))
			== "$EFFC/$EFF9/$F00F-$F012",
			"descriptor derivation records its ROM routine")
		_check(str(packet_status.get("source_derivation", {}).get("placement_source_pc", ""))
			== "$8327/$8342-$8349",
			"placement derivation records its ROM routine")

	var missing_state_presenter: RefCounted = PRESENTER_SCRIPT.new()
	var missing_state_ok: bool = missing_state_presenter.call("build_and_apply", screen, {})
	_check(missing_state_ok, "candidate still renders when route state is not yet available")
	if missing_state_ok:
		var missing_status: Dictionary = missing_state_presenter.get("status").get("residual_packet_producer", {})
		_check(not bool(missing_status.get("applied", true))
			and str(missing_status.get("status", "")) == "awaiting_route_source_state",
			"no endpoint or default values are substituted when source context is missing")
	var constants_presenter: RefCounted = PRESENTER_SCRIPT.new()
	var constants_only_ok: bool = constants_presenter.call("build_and_apply", screen, {
		"descriptor_id": 0x02,
		"placement_05ce": 0xA0,
	})
	_check(constants_only_ok, "candidate remains available when only caller constants are supplied")
	if constants_only_ok:
		var constants_status: Dictionary = constants_presenter.get("status").get("residual_packet_producer", {})
		_check(not bool(constants_status.get("applied", true))
			and str(constants_status.get("status", "")) == "awaiting_route_source_state",
			"pre-resolved descriptor and placement constants cannot bypass ROM source-state derivation")

	screen.queue_free()
	await process_frame
	if _failures == 0:
		print("PASS: source-derived $063D/$05CE values drive all six F015 batches and the field candidate renderer; no PPU/RAM oracle is passed to runtime.")
		print("LIMIT: the route still must produce the actual $8327 callback inputs and live holder coordinates before this path can be wired into play.")
	else:
		printerr("FAIL: %d source-context assertion(s)" % _failures)
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)
	else:
		print("PASS: " + label)

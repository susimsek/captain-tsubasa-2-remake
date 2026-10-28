extends SceneTree

const Resolver := preload("res://scripts/gameplay/rom_first_command_field_descriptor_resolver.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var resolver = Resolver.new()
	assert(resolver.configure(), "ROM-derived $EFFC source spans must load and match their hashes.")
	var source_status: Dictionary = resolver.get_source_status()
	assert(bool(source_status.get("configured", false)), "Resolver source status should report configured.")

	# Fresh route: the ROM B/menu path clears $0600 and $803C sets $0621=0.
	var fresh_route: Dictionary = resolver.resolve_descriptor(0x00, 0x00)
	assert(bool(fresh_route.get("ok", false)), "Fresh-route selector inputs must be accepted.")
	assert(int(fresh_route.get("descriptor_id", -1)) == 0x02,
		"$0621=0 and $0600=0 must select field-packet descriptor $02.")

	# Adjacent context follows the indexed source byte and skips the context-zero override.
	var adjacent_context: Dictionary = resolver.resolve_descriptor(0x01, 0x00)
	assert(bool(adjacent_context.get("ok", false)), "Adjacent source context must be accepted.")
	assert(int(adjacent_context.get("descriptor_id", -1)) == 0x00,
		"Context $01 must use lookup byte $F010=$00, not the fresh-route override.")

	# The zero-context override is conditional on the defender-count input.
	var defenders_present: Dictionary = resolver.resolve_descriptor(0x00, 0x01)
	assert(bool(defenders_present.get("ok", false)), "A byte-sized defender count must be accepted.")
	assert(int(defenders_present.get("descriptor_id", -1)) == 0x00,
		"Context $00 with nonzero $0600 must retain lookup byte $F00F=$00.")

	var unsupported_context: Dictionary = resolver.resolve_descriptor(0x04, 0x00)
	assert(not bool(unsupported_context.get("ok", true)),
		"Contexts outside the preserved four-byte lookup span must fail explicitly.")
	print("ROM $EFFC descriptor resolver verified: fresh route=$02; context $01=$00; nonzero defender count=$00.")
	quit(0)

extends SceneTree

const RESOLVER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_position_context_resolver.gd")


func _initialize() -> void:
	var resolver = RESOLVER_SCRIPT.new()
	if not resolver.configure():
		_fail("Source configuration failed: " + resolver.error_message)
		return
	var caller_context := {
		"kind": "caller_owned_decoded_game_logic",
		"label": "fresh KICK OFF route state supplied by route owner",
	}
	var result: Dictionary = resolver.resolve_fresh_match_context(0, 0, caller_context)
	if not bool(result.get("ok", false)):
		_fail("Fresh match-zero resolution failed: " + str(result.get("error", "")))
		return
	if int(result.get("formation_002c", -1)) != 0 \
			or int(result.get("formation_002e", -1)) != 0 \
			or int(result.get("possession_side_05fb", -1)) != 0:
		_fail("Match-zero source values were not ($002C,$002E,$05FB)=(0,0,0).")
		return
	if int(result.get("home_team_id", -1)) != 0 \
			or int(result.get("opponent_id", -1)) != 3 \
			or int(result.get("kickoff_branch_address", -1)) != 0xDB34 \
			or int(result.get("opponent_record_address", -1)) != 0xBAF6:
		_fail("Match-zero team/opponent/branch provenance did not resolve as expected.")
		return
	var source_hashes: Dictionary = result.get("source_hashes", {})
	if source_hashes.size() != 12:
		_fail("The resolved result did not return all 12 preserved source hashes.")
		return
	if bool(resolver.resolve_fresh_match_context(1, 0, caller_context).get("ok", false)):
		_fail("The resolver accepted an unsupported match index.")
		return
	if bool(resolver.resolve_fresh_match_context(0, 1, caller_context).get("ok", false)):
		_fail("The resolver accepted an unsupported kickoff selector.")
		return
	var capture_context := {"kind": "emulator_endpoint_ram", "label": "forbidden"}
	if bool(resolver.resolve_fresh_match_context(0, 0, capture_context).get("ok", false)):
		_fail("The resolver accepted capture-derived state as its caller context.")
		return
	print("PASS ROM fresh kickoff context: match 0 → opponent 3, formations $00/$00, selector 0 → $DB34, $05FB=$00; 12 source-span hashes checked; unsupported selectors, matches and capture contexts rejected.")
	print("LIMIT: the route owner must supply decoded match_index=0 and kickoff selector $0629=0; the resolver does not infer the selector from cold-reset RAM or endpoint captures.")
	quit(0)


func _fail(message: String) -> void:
	push_error("Fresh kickoff position-context source check failed: " + message)
	quit(1)

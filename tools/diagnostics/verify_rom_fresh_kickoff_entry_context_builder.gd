extends SceneTree

const BUILDER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_entry_context_builder.gd")
const TRACE_VALIDATION_PATH := "res://reference/diagnostics/fresh_kickoff_entry_context_20261028_134613_utc/validation.json"


func _init() -> void:
	if not _verify():
		quit(1)
		return
	print("PASS: reset/KICK OFF/selector bytes and scheduler derive match 0, period 0, opponent 3, slot-$05 `$D11E` SP `$52`; trace is comparison-only.")
	quit(0)


func _verify() -> bool:
	var builder: Variant = BUILDER_SCRIPT.new()
	if not builder.configure_from_project_sources():
		return _fail("Could not configure hash-checked ROM context sources: " + builder.error_message)
	var context: Variant = builder.call("build_fresh_kickoff_context")
	if context == null:
		return _fail("ROM-source context derivation failed: " + builder.error_message)
	var derived: Dictionary = context.to_dictionary()
	if int(derived.get("match_index", -1)) != 0 \
			or int(derived.get("period_0027", -1)) != 0 \
			or int(derived.get("opponent_id_002b", -1)) != 3 \
			or int(derived.get("task_slot_base", -1)) != 0x05 \
			or int(derived.get("entry_pc", -1)) != 0xD11E \
			or int(derived.get("entry_sp", -1)) != 0x52:
		return _fail("Source-derived context disagrees with the bounded match-zero/task entry contract.")
	var period_inputs: Dictionary = context.to_period_task_inputs()
	var provenance: Dictionary = period_inputs.get("source_context", {})
	if String(provenance.get("kind", "")) != "caller_owned_decoded_game_logic" \
			or String(provenance.get("label", "")).is_empty() \
			or String(provenance.get("source_event", "")).is_empty():
		return _fail("The typed context did not provide source-owned provenance for its consumer.")
	if not FileAccess.file_exists(TRACE_VALIDATION_PATH):
		return _fail("The two-pass trace validation reference is unavailable.")
	var trace_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRACE_VALIDATION_PATH))
	if not trace_variant is Dictionary:
		return _fail("The trace validation reference is malformed.")
	var trace: Dictionary = trace_variant
	if int(trace.get("replays", 0)) != 2 \
			or not bool(trace.get("signature_verified_after_both_loads", false)) \
			or not bool(trace.get("diagnostics_only", false)) \
			or bool(trace.get("trace_or_capture_ram_used_as_runtime_input", true)) \
			or bool(trace.get("numbered_slots_used", true)) \
			or not bool(trace.get("match_index_unchanged_within_captured_interval", false)):
		return _fail("The behavioral trace is not a valid diagnostic-only two-pass comparison.")
	var write_counts: Dictionary = trace.get("match_index_write_counts_by_pass", {})
	if int(write_counts.get("1", -1)) != 0 or int(write_counts.get("2", -1)) != 0:
		return _fail("A trace pass rewrote `$0026` inside its captured interval.")
	var observed: Dictionary = trace.get("observed", {})
	if int(observed.get("match_index_0026", -1)) != int(derived["match_index"]) \
			or int(observed.get("period_0027_at_D11E", -1)) != int(derived["period_0027"]) \
			or int(observed.get("opponent_002B_at_D11E", -1)) != int(derived["opponent_id_002b"]) \
			or String(observed.get("slot05_entry_pc", "")) != "$D11E" \
			or String(observed.get("slot05_entry_sp", "")) != "$52":
		return _fail("ROM-derived builder values differ from the trace-only behavioral comparison.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false

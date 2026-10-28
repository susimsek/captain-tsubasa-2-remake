extends SceneTree

const RNG_REPLAY_SCRIPT := preload("res://scripts/gameplay/rom_kickoff_rng_source_replay.gd")
const SCHEDULE_PATH := "res://assets/gameplay/rom_logic/kickoff_rng_source_schedule.json"
const RAM_CAPTURE_DIR := "res://reference/diagnostics/kickoff_select_test_20261027/ram"
const AUDITED_INPUT_SHA256 := "6cae92ff2b6a77fcc05c34c57c734bbff47930ada172633cb4a4b830cc3e77dc"


func _initialize() -> void:
	var wrong_route = RNG_REPLAY_SCRIPT.new()
	if wrong_route.configure(SCHEDULE_PATH, "0".repeat(64)):
		_fail("RNG replay accepted a different input route identity.")
		return
	var replay = RNG_REPLAY_SCRIPT.new()
	if not replay.configure(SCHEDULE_PATH, AUDITED_INPUT_SHA256):
		_fail(replay.error_message)
		return
	var directory := DirAccess.open(RAM_CAPTURE_DIR)
	if directory == null:
		_fail("Could not open retained route RAM validation directory.")
		return
	var capture_names: Array[String] = []
	for file_name in directory.get_files():
		if file_name.begins_with("route_frame_") and file_name.ends_with(".bin"):
			capture_names.append(file_name)
	capture_names.sort_custom(func(a: String, b: String) -> bool:
		return _source_frame_from_name(a) < _source_frame_from_name(b)
	)
	var compared := 0
	var receiver_ram_checked := false
	for file_name in capture_names:
		var source_frame := _source_frame_from_name(file_name)
		if source_frame > replay.receiver_source_frame:
			break
		if not replay.advance_to_source_frame(source_frame):
			_fail(replay.error_message)
			return
		var ram := FileAccess.get_file_as_bytes(RAM_CAPTURE_DIR.path_join(file_name))
		if ram.size() != 0x800:
			_fail("RAM capture has an unexpected size: %s" % file_name)
			return
		if replay.e1 != ram[0xE1] or replay.e2 != ram[0xE2] or replay.e3 != ram[0xE3]:
			_fail(
				"RNG mismatch at frame %d: model=$%02X/$%02X/$%02X capture=$%02X/$%02X/$%02X"
				% [source_frame, replay.e1, replay.e2, replay.e3,
					ram[0xE1], ram[0xE2], ram[0xE3]]
			)
			return
		if source_frame == replay.receiver_source_frame:
			receiver_ram_checked = true
			if replay.get_receiver_slot() != ram[0x05FC]:
				_fail(
					"Receiver slot mismatch at frame %d: model=$%02X capture=$%02X"
					% [source_frame, replay.get_receiver_slot(), ram[0x05FC]]
				)
				return
		compared += 1
	if not receiver_ram_checked:
		_fail("No retained RAM dump exists at the receiver-selection frame.")
		return
	if replay.a117_update_count != 8446 or replay.c9c5_update_count != 133:
		_fail("The replay update counts differ from the audited route schedule.")
		return
	var summary := (
		"KICKOFF RNG source schedule parity: %d RAM dumps matched E1/E2/E3; "
		+ "frame %d receiver slot $%02X; A117=%d, C9C5=%d; route SHA-256=%s"
	) % [compared, replay.receiver_source_frame, replay.get_receiver_slot(),
		replay.a117_update_count, replay.c9c5_update_count, replay.input_timeline_sha256]
	print(summary)
	quit(0)


func _source_frame_from_name(file_name: String) -> int:
	var stem := file_name.trim_suffix(".bin")
	return int(stem.get_slice("_", stem.get_slice_count("_") - 1))


func _fail(message: String) -> void:
	printerr("KICKOFF RNG source schedule parity failed: " + message)
	quit(1)

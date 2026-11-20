extends SceneTree
## Runs from an exported PCK to verify runtime source data and audio are present
## while local ROM, emulator, and captured-reference files are absent.

const PASS_HANDLER_EXECUTOR := preload("res://scripts/gameplay/rom_pass_handler_body_executor.gd")
const SCENARIO38_QUEUE_EXECUTOR := preload("res://scripts/gameplay/rom_scenario38_queue_consumer_executor.gd")
const FRESH_BANK18_WORKER := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")
const PASS_RECEIVER_MENU_PANEL := preload("res://scripts/gameplay/pass_receiver_menu_panel.gd")

const SOURCE_ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SOURCE_ROM_SIZE_BYTES := 393232
const GAMEPLAY_AUDIO_ROOT := "res://assets/gameplay/audio"
const OPENING_AUDIO_MANIFEST := "res://assets/opening/audio/opening_timeline_rom_driver.json"
const OPENING_AUDIO_PATH := "res://assets/opening/audio/opening_timeline_rom_driver.wav"
const MATCH_AUDIO_MANIFEST := "res://assets/gameplay/audio/first_command_menu_route_wavehi_rom_generated.json"
const MATCH_AUDIO_TIMING_MANIFEST := "res://assets/gameplay/audio/first_command_menu_route_wavehi_source_timing_rom_generated.json"
const ROUTE_CONTEXT_AUDIO_MANIFESTS := [
	"match_track_53_wavehi_route_context_rom_generated.json",
	"match_track_3C_wavehi_route_context_rom_generated.json",
]
const ROUTE_CONTEXT_TIMING_MANIFESTS := [
	"match_track_53_wavehi_route_context_timing_rom_generated.json",
	"match_track_3C_wavehi_route_context_timing_rom_generated.json",
]
const REQUIRED_GAMEPLAY_AUDIO_MANIFESTS := [
	"match_sfx_2B_rom_generated.json",
	"match_sfx_2C_rom_generated.json",
	"match_sfx_30_rom_generated.json",
	"match_sfx_31_rom_generated.json",
	"match_track_35_rom_generated.json",
	"match_track_36_rom_generated.json",
	"match_track_3C_rom_generated.json",
	"match_track_44_rom_generated.json",
	"match_track_45_rom_generated.json",
	"match_track_51_rom_generated.json",
	"match_track_53_rom_generated.json",
	"match_track_55_wavehi_rom_generated.json",
	"first_command_menu_route_wavehi_rom_generated.json",
	ROUTE_CONTEXT_AUDIO_MANIFESTS[0],
	ROUTE_CONTEXT_AUDIO_MANIFESTS[1],
	"match_sfx_66_rom_generated.json",
	"match_sfx_69_rom_generated.json",
]
const REQUIRED_RUNTIME_SOURCE_PATHS := [
	"res://reference/rom_extract/chr_rom.2bpp",
	"res://reference/rom_extract/intro/background_17_layout.json",
	"res://reference/rom_extract/intro/animation_0D_sprite_palette.bin",
	"res://reference/rom_extract/gameplay/first_command_scenarios/manifest.json",
	"res://reference/rom_extract/gameplay/menus/first_action_menu/menu_descriptor_03.bin",
	"res://reference/rom_extract/gameplay/first_action_menu_input/pass_receiver_handler_D7E8_D8F6.bin",
	"res://reference/rom_extract/gameplay/scenario_task_runtime/fixed_scenario_queue_CBB0_CBC1.bin",
	"res://reference/rom_extract/gameplay/first_command_scenarios/scenario_38.bin",
	"res://reference/rom_extract/gameplay/slot09_eb8b_continuation/bank10_event_reader_803F_8096.bin",
	"res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/manifest.json",
	"res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank19_pass_receiver_descriptor_pointer_B3ED_B3EF.bin",
	"res://reference/rom_extract/gameplay/fresh_bank18_worker_prefix/bank19_pass_receiver_descriptor_0F_B58D_B5A2.bin",
	"res://reference/rom_extract/gameplay/menus/pass_receiver_menu/manifest.json",
	"res://reference/rom_extract/gameplay/menus/pass_receiver_menu/descriptor_0F.bin",
	"res://reference/rom_extract/gameplay/menus/pass_receiver_menu/row_00.bin",
	"res://reference/rom_extract/gameplay/menus/pass_receiver_menu/row_01.bin",
	"res://reference/rom_extract/gameplay/menus/pass_receiver_menu/row_02.bin",
	"res://reference/rom_extract/gameplay/menus/first_action_menu/window_3x3_tile_ids.bin",
	"res://reference/palettes/FCEUX_internal_default_2.7.0_rgb.pal",
]
const OMITTED_REFERENCE_MEDIA_EXTENSIONS := [
	"wav", "ogg", "mp3", "flac", "mp4", "mov", "avi",
	"png", "jpg", "jpeg", "bmp", "webp", "gif", "apng", "tif", "tiff",
]
const OMITTED_EMULATOR_EXTENSIONS := [
	"nes", "nsf", "unf", "unif", "fds", "fm2", "fcm",
	"fc0", "fc1", "fc2", "fc3", "fc4", "fc5", "fc6", "fc7", "fc8", "fc9",
	"sav", "srm", "state", "sta", "mss", "dsv", "ips", "bps", "ups",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for path: String in REQUIRED_RUNTIME_SOURCE_PATHS:
		_check(FileAccess.file_exists(path), "required ROM-derived runtime resource exists: %s" % path)
	_check_pass_route_sources()
	_check_opening_audio()
	_check_match_audio()
	_check_omissions()
	if _failures.is_empty():
		print("PASS: exported pack contains required ROM-derived source data and all ROM-only opening/gameplay audio resources; ROM, emulator, and captured reference files are absent.")
		quit(0)
		return
	for failure: String in _failures:
		printerr("FAIL: " + failure)
	quit(1)


func _check_pass_route_sources() -> void:
	var pass_handler: RefCounted = PASS_HANDLER_EXECUTOR.new()
	var pass_handler_ok := bool(pass_handler.call("configure_from_project_sources"))
	_check(pass_handler_ok,
		"PCK PASS handler, queue helper, scenario-$38 manifest, and byte hashes validate: "
		+ String(pass_handler.get("error_message")))

	var scenario38_queue: RefCounted = SCENARIO38_QUEUE_EXECUTOR.new()
	var scenario38_queue_ok := bool(scenario38_queue.call("configure_from_project_sources"))
	_check(scenario38_queue_ok,
		"PCK scenario-$38 queue consumer manifests and ROM-span hashes validate: "
		+ String(scenario38_queue.get("error_message")))

	var bank18_worker: RefCounted = FRESH_BANK18_WORKER.new()
	var bank18_worker_ok := bool(bank18_worker.call("configure_from_project_sources"))
	_check(bank18_worker_ok,
		"PCK descriptor-$0F worker manifest and ROM-span hashes validate: "
		+ String(bank18_worker.get("error_message")))

	var receiver_panel: RefCounted = PASS_RECEIVER_MENU_PANEL.new()
	var receiver_panel_ok := bool(receiver_panel.call("rebuild"))
	_check(receiver_panel_ok,
		"PCK descriptor-$0F receiver menu manifest, descriptor, text rows, and shared window validate: "
		+ String(receiver_panel.get("error_message")))


func _check_opening_audio() -> void:
	var manifest := _read_json(OPENING_AUDIO_MANIFEST)
	if manifest.is_empty():
		return
	_check(String(manifest.get("source_rom_sha256", "")) == SOURCE_ROM_SHA256,
		"opening audio manifest names the audited ROM")
	_check(not bool(manifest.get("captured_pcm_used", true)) \
			and not bool(manifest.get("runtime_needs_rom_or_emulator", true)),
		"opening audio manifest identifies a standalone ROM-derived render")
	var wav_path := "res://" + String(manifest.get("audio_path", ""))
	_check_audio_file(wav_path, String(manifest.get("audio_sha256", "")),
		"opening audio")
	_check(wav_path == OPENING_AUDIO_PATH,
		"opening audio manifest resolves to its expected runtime WAV path")


func _check_match_audio() -> void:
	var audio_directory := DirAccess.open(GAMEPLAY_AUDIO_ROOT)
	if audio_directory == null:
		_failures.append("gameplay audio directory is absent from the exported pack")
		return
	for manifest_name: String in REQUIRED_GAMEPLAY_AUDIO_MANIFESTS:
		_check(FileAccess.file_exists(GAMEPLAY_AUDIO_ROOT.path_join(manifest_name)),
			"runtime cue manifest is present: %s" % manifest_name)
	for timing_name: String in ROUTE_CONTEXT_TIMING_MANIFESTS:
		_check(FileAccess.file_exists(GAMEPLAY_AUDIO_ROOT.path_join(timing_name)),
			"runtime route timing manifest is present: %s" % timing_name)
	var cue_manifest_count := 0
	audio_directory.list_dir_begin()
	var entry := audio_directory.get_next()
	while not entry.is_empty():
		if not audio_directory.current_is_dir() and entry.get_extension().to_lower() == "json" \
				and entry != "match_track_55_source_timing_rom_generated.json" \
				and entry != "match_track_55_rom_generated.json":
			var manifest_path := GAMEPLAY_AUDIO_ROOT.path_join(entry)
			var manifest := _read_json(manifest_path)
			if not manifest.is_empty() and manifest.has("wav"):
				cue_manifest_count += 1
				_check(String(manifest.get("source_rom_sha256", "")) == SOURCE_ROM_SHA256,
					"cue manifest names the audited ROM: %s" % entry)
				_check(not bool(manifest.get("captured_pcm_used", true)) \
						and not bool(manifest.get("captured_wav_used", false)) \
						and not bool(manifest.get("capture_used", true)) \
						and not bool(manifest.get("runtime_needs_rom_or_emulator", true)),
					"cue manifest identifies capture-free standalone audio: %s" % entry)
				var relative_wav_path := String(manifest.get("wav", ""))
				_check(relative_wav_path.begins_with("assets/gameplay/audio/") \
						and not relative_wav_path.contains(".."),
					"cue WAV path stays in the runtime gameplay audio directory: %s" % entry)
				if relative_wav_path.begins_with("assets/gameplay/audio/") \
						and not relative_wav_path.contains(".."):
					_check_audio_file("res://" + relative_wav_path,
						String(manifest.get("wav_sha256", "")), "cue $%s" % String(manifest.get("cue", "?")))
		entry = audio_directory.get_next()
	audio_directory.list_dir_end()
	_check(cue_manifest_count == 17,
		"all seventeen ROM-derived gameplay audio manifests are present (found %d)" % cue_manifest_count)

	_check_route_timing_manifest(MATCH_AUDIO_TIMING_MANIFEST, MATCH_AUDIO_MANIFEST)
	_check_route_timing_manifest(
		GAMEPLAY_AUDIO_ROOT.path_join(ROUTE_CONTEXT_TIMING_MANIFESTS[0]),
		GAMEPLAY_AUDIO_ROOT.path_join(ROUTE_CONTEXT_AUDIO_MANIFESTS[0]))
	_check_route_timing_manifest(
		GAMEPLAY_AUDIO_ROOT.path_join(ROUTE_CONTEXT_TIMING_MANIFESTS[1]),
		GAMEPLAY_AUDIO_ROOT.path_join(ROUTE_CONTEXT_AUDIO_MANIFESTS[1]))


func _check_route_timing_manifest(timing_path: String, cue_path: String) -> void:
	var timing_manifest := _read_json(timing_path)
	var cue_manifest := _read_json(cue_path)
	if timing_manifest.is_empty() or cue_manifest.is_empty():
		return
	_check(String(timing_manifest.get("source_rom_sha256", "")) == SOURCE_ROM_SHA256 \
			and not bool(timing_manifest.get("captured_pcm_used", true)) \
			and not bool(timing_manifest.get("captured_wav_used", true)) \
			and not bool(timing_manifest.get("runtime_needs_rom_or_emulator", true)),
		"route-context timing manifest is ROM-derived and standalone: %s" % timing_path.get_file())
	var source_audio_path := String(timing_manifest.get("source_audio_path", ""))
	var relative_wav_path := String(cue_manifest.get("wav", ""))
	_check(source_audio_path == relative_wav_path \
			and String(timing_manifest.get("source_audio_sha256", "")) \
			== String(cue_manifest.get("wav_sha256", "")),
		"route-context WAV path/hash agree between timing and cue manifests: %s" % cue_path.get_file())


func _check_audio_file(path: String, expected_sha256: String, label: String) -> void:
	if not FileAccess.file_exists(path):
		_failures.append("%s WAV is absent from the exported pack: %s" % [label, path])
		return
	var audio_bytes := FileAccess.get_file_as_bytes(path)
	_check(not expected_sha256.is_empty() and _sha256_hex(audio_bytes) == expected_sha256,
		"%s raw WAV bytes match their manifest hash" % label)
	_check(load(path) is AudioStreamWAV,
		"%s WAV loads as AudioStreamWAV from the exported pack" % label)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_failures.append("required runtime JSON is absent from the exported pack: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_failures.append("runtime JSON is invalid in the exported pack: %s" % path)
		return {}
	return parsed


func _check_omissions() -> void:
	var exported_paths: Array[String] = []
	_collect_paths("res://", exported_paths)
	_check(not exported_paths.is_empty(), "exported pack file tree can be enumerated")
	_check_source_rom_bytes_absent(exported_paths)
	for path: String in exported_paths:
		var normalized_path := path.to_lower().replace("\\", "/")
		var extension := normalized_path.get_extension()
		var forbidden := extension in OMITTED_EMULATOR_EXTENSIONS \
				or _is_fceux_state_extension(extension)
		if normalized_path.begins_with("res://reference/diagnostics/") \
				or normalized_path.begins_with("res://reference/rom_extract/audio/first_match_bgm55_driver_trace_20261028/") \
				or normalized_path.begins_with("res://tools/audio/build/"):
			forbidden = true
		if normalized_path.begins_with("res://reference/") \
				and extension in OMITTED_REFERENCE_MEDIA_EXTENSIONS:
			forbidden = true
		if _is_reference_capture_directory(normalized_path):
			forbidden = true
		_check(not forbidden, "ROM/emulator/capture artifact is omitted: %s" % path)


func _check_source_rom_bytes_absent(exported_paths: Array[String]) -> void:
	var matching_rom_paths: Array[String] = []
	for path: String in exported_paths:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		if file.get_length() != SOURCE_ROM_SIZE_BYTES:
			file.close()
			continue
		var rom_candidate := file.get_buffer(SOURCE_ROM_SIZE_BYTES)
		file.close()
		if _sha256_hex(rom_candidate) == SOURCE_ROM_SHA256:
			matching_rom_paths.append(path)
	var rom_absence_message := "the supplied ROM payload is absent regardless of filename or extension"
	if not matching_rom_paths.is_empty():
		rom_absence_message += ": " + ", ".join(matching_rom_paths)
	_check(matching_rom_paths.is_empty(), rom_absence_message)


func _collect_paths(directory_path: String, paths: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var entry_path := directory_path.path_join(entry)
			if directory.current_is_dir():
				_collect_paths(entry_path, paths)
			else:
				paths.append(entry_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _is_reference_capture_directory(normalized_path: String) -> bool:
	var relative_path := normalized_path.trim_prefix("res://")
	if not relative_path.begins_with("reference/"):
		return false
	var path_parts := relative_path.split("/")
	if path_parts.size() < 3:
		return false
	var reference_directory := String(path_parts[1])
	return reference_directory.contains("capture") \
		or reference_directory.contains("probe") \
		or reference_directory.contains("progress")


func _is_fceux_state_extension(extension: String) -> bool:
	return extension.length() == 3 and extension.begins_with("fc") \
		and extension.substr(2, 1).is_valid_int()


func _sha256_hex(bytes: PackedByteArray) -> String:
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	hash_context.update(bytes)
	return hash_context.finish().hex_encode()


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)

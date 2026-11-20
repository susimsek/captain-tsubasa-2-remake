@tool
extends EditorExportPlugin

const ROM_DATA_ROOT := "res://reference/rom_extract"
const PALETTE_ROOT := "res://reference/palettes"
const OPENING_LOGIC_ROOT := "res://assets/opening/rom_logic"
const OPENING_AUDIO_METADATA_PATH := "res://assets/opening/audio/opening_timeline_rom_driver.json"
const RAW_AUDIO_PATH := "res://assets/opening/audio/opening_timeline_rom_driver.wav"
const GAMEPLAY_AUDIO_ROOT := "res://assets/gameplay/audio"
const GAMEPLAY_AUDIO_EXTENSIONS := ["json", "wav"]
const UPDATE_HELPER_PATHS := [
	"res://scripts/updater/apply_update_macos.sh",
	"res://scripts/updater/apply_update_windows.ps1",
	"res://scripts/updater/apply_update_linux.sh",
]
const EXPORTED_RUNTIME_EXTENSIONS := ["bin", "json", "2bpp", "pal"]
const EXCLUDED_RUNTIME_DIRECTORY_PREFIXES := [
	"res://reference/diagnostics/",
	"res://reference/rom_extract/audio/first_match_bgm55_driver_trace_20261028/",
	"res://tools/audio/build/",
]
const EXCLUDED_EMULATOR_EXTENSIONS := ["nes", "nsf", "fm2", "fcm", "sav", "srm", "state"]
const EXCLUDED_REFERENCE_MEDIA_EXTENSIONS := [
	"wav", "ogg", "mp3", "flac", "mp4", "mov", "avi",
	"png", "jpg", "jpeg", "bmp", "webp", "gif", "apng", "tif", "tiff",
]


func _get_name() -> String:
	return "RuntimeSourceDataExport"


func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	_add_runtime_directory(ROM_DATA_ROOT)
	_add_runtime_directory(PALETTE_ROOT)
	# The presenter reads byte-preserved ROM tables and JSON manifests with
	# FileAccess at runtime, so the standalone package must include them directly.
	_add_runtime_directory(OPENING_LOGIC_ROOT)
	_add_runtime_file(OPENING_AUDIO_METADATA_PATH, OPENING_AUDIO_METADATA_PATH)
	_add_runtime_file(RAW_AUDIO_PATH, RAW_AUDIO_PATH)
	# Gameplay audio is loaded from paths discovered in JSON manifests. Preserve
	# both source WAV bytes (for the runtime hash check) and manifest JSON at the
	# exact paths the presenter opens with FileAccess/load().
	_add_runtime_directory(GAMEPLAY_AUDIO_ROOT, GAMEPLAY_AUDIO_EXTENSIONS)
	for helper_path in UPDATE_HELPER_PATHS:
		_add_runtime_file(helper_path, helper_path)


func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	# Export presets use all_resources. Git ignore rules do not filter files from
	# that export, so exclude local ROMs, emulator state, and retained comparison
	# captures here while keeping the extracted ROM-derived runtime sources.
	if _should_skip_export_path(path):
		skip()


func _should_skip_export_path(path: String) -> bool:
	var normalized_path := path.replace("\\", "/").to_lower()
	if not normalized_path.begins_with("res://"):
		normalized_path = "res://" + normalized_path.trim_prefix("/")

	for excluded_prefix in EXCLUDED_RUNTIME_DIRECTORY_PREFIXES:
		if normalized_path.begins_with(String(excluded_prefix)):
			return true

	var extension := normalized_path.get_extension()
	if extension in EXCLUDED_EMULATOR_EXTENSIONS:
		return true
	if extension.length() == 3 and extension.begins_with("fc") \
			and extension.substr(2, 1).is_valid_int():
		return true
	if normalized_path.begins_with("res://reference/") \
			and extension in EXCLUDED_REFERENCE_MEDIA_EXTENSIONS:
		return true
	return _is_excluded_reference_artifact_directory(normalized_path)


func _is_excluded_reference_artifact_directory(normalized_path: String) -> bool:
	var relative_path := normalized_path.trim_prefix("res://")
	if not relative_path.begins_with("reference/"):
		return false
	var path_parts := relative_path.split("/")
	# Match the local reference/*capture*/, *probe*, and *progress* ignore
	# directories without excluding similarly named standalone report files.
	if path_parts.size() < 3:
		return false
	var reference_directory := String(path_parts[1])
	return reference_directory.contains("capture") \
		or reference_directory.contains("probe") \
		or reference_directory.contains("progress")


func _add_runtime_directory(directory_path: String,
		allowed_extensions: Array = EXPORTED_RUNTIME_EXTENSIONS) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("Runtime export data directory is missing: %s" % directory_path)
		return
	_add_directory_contents(directory_path, allowed_extensions)


func _add_directory_contents(directory_path: String, allowed_extensions: Array) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("Runtime export data directory cannot be opened: %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != ".." and not entry.begins_with("."):
			var entry_path := directory_path.path_join(entry)
			if directory.current_is_dir():
				if not _should_skip_export_path(entry_path):
					_add_directory_contents(entry_path, allowed_extensions)
			elif entry.get_extension().to_lower() in allowed_extensions \
					and not _should_skip_export_path(entry_path):
				_add_runtime_file(entry_path, entry_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _add_runtime_file(source_path: String, exported_path: String) -> void:
	if _should_skip_export_path(source_path):
		return
	var file_bytes := FileAccess.get_file_as_bytes(source_path)
	if file_bytes.is_empty():
		push_error("Runtime export data file is missing or empty: %s" % source_path)
		return
	add_file(exported_path, file_bytes, false)

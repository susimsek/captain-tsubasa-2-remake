@tool
extends EditorExportPlugin

const ROM_DATA_ROOT := "res://reference/rom_extract"
const PALETTE_ROOT := "res://reference/palettes"
const OPENING_LOGIC_ROOT := "res://assets/opening/rom_logic"
const RAW_AUDIO_PATH := "res://assets/opening/audio/opening_timeline_rom_driver.wav"
const UPDATE_HELPER_PATHS := [
	"res://scripts/updater/apply_update_macos.sh",
	"res://scripts/updater/apply_update_windows.ps1",
	"res://scripts/updater/apply_update_linux.sh",
]
const EXPORTED_RUNTIME_EXTENSIONS := ["bin", "json", "2bpp", "pal"]


func _get_name() -> String:
	return "RuntimeSourceDataExport"


func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	_add_runtime_directory(ROM_DATA_ROOT)
	_add_runtime_directory(PALETTE_ROOT)
	# The presenter reads byte-preserved ROM tables and JSON manifests with
	# FileAccess at runtime, so the standalone package must include them directly.
	_add_runtime_directory(OPENING_LOGIC_ROOT)
	_add_runtime_file(RAW_AUDIO_PATH, RAW_AUDIO_PATH)
	for helper_path in UPDATE_HELPER_PATHS:
		_add_runtime_file(helper_path, helper_path)


func _add_runtime_directory(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("Runtime export data directory is missing: %s" % directory_path)
		return
	_add_directory_contents(directory_path)


func _add_directory_contents(directory_path: String) -> void:
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
				_add_directory_contents(entry_path)
			elif entry.get_extension().to_lower() in EXPORTED_RUNTIME_EXTENSIONS:
				_add_runtime_file(entry_path, entry_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _add_runtime_file(source_path: String, exported_path: String) -> void:
	var file_bytes := FileAccess.get_file_as_bytes(source_path)
	if file_bytes.is_empty():
		push_error("Runtime export data file is missing or empty: %s" % source_path)
		return
	add_file(exported_path, file_bytes, false)

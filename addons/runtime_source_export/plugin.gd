@tool
extends EditorPlugin

const RuntimeDataExporter = preload("runtime_data_export.gd")

var _exporter: EditorExportPlugin


func _enter_tree() -> void:
	_exporter = RuntimeDataExporter.new()
	add_export_plugin(_exporter)


func _exit_tree() -> void:
	remove_export_plugin(_exporter)

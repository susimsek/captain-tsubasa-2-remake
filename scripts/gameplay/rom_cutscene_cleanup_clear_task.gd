extends RefCounted
class_name RomCutsceneCleanupClearTask
## Applies the decoded PPU and OAM effects after the ROM $99F0 fade returns.
## This is a bounded helper model, not a 6502/PPU-cycle emulator.

const ROOT := "res://reference/rom_extract/gameplay/cutscene_cleanup_helpers/"
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
const SPANS := {
	"bank00_cutscene_cleanup_98A0_98DB.bin": {
		"start": 0x98A0, "end_exclusive": 0x98DC, "file_offset": 0x18B0,
		"length": 60, "sha256": "e06d0e6831e6b42ff97d91bf052b8ba0384a4a61d149d62148bd2ddda5936d1a",
	},
	"bank00_cutscene_cleanup_9B7F_9B9F.bin": {
		"start": 0x9B7F, "end_exclusive": 0x9BA0, "file_offset": 0x1B8F,
		"length": 33, "sha256": "3d8b1ba05b37b8f4813ee4f312b94d3e69742c7b83748903b5e54e55a706882b",
	},
	"bank00_cutscene_cleanup_9BA0_9BA8.bin": {
		"start": 0x9BA0, "end_exclusive": 0x9BA9, "file_offset": 0x1BB0,
		"length": 9, "sha256": "be5348cfdc524a04e586ed4e8fcb2d36446e6885d9acfc6c3b4447d6f3b2ae34",
	},
}
const OAM_SHADOW_START := 0x0468
const OAM_DMA_START := 0x0200
const OAM_BYTES := 0x100
const PPU_NAMETABLE_BYTES := 0x800
const OAM_HIDDEN_Y := 0xF8
const MOTION_RECORD_STARTS := [0x0568, 0x0588, 0x05A8, 0x05C8]

var error_message := ""
var _configured := false
var _direct_oam_source := PackedByteArray()


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	_direct_oam_source = PackedByteArray()
	var manifest_file := FileAccess.open(ROOT + "manifest.json", FileAccess.READ)
	if manifest_file == null:
		return _fail("Cutscene cleanup source manifest is unavailable.")
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary or String(parsed.get("rom_sha256", "")) != ROM_SHA256:
		return _fail("Cutscene cleanup manifest is malformed or targets another ROM.")
	var entries: Dictionary = {}
	for entry_variant in parsed.get("spans", []):
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			entries[String(entry.get("file", ""))] = entry
	for file_name: String in SPANS:
		var spec: Dictionary = SPANS[file_name]
		if not entries.has(file_name):
			return _fail("Cleanup manifest omits %s." % file_name)
		var entry: Dictionary = entries[file_name]
		if int(entry.get("start", -1)) != int(spec["start"]) \
				or int(entry.get("end_exclusive", -1)) != int(spec["end_exclusive"]) \
				or int(entry.get("file_offset", -1)) != int(spec["file_offset"]) \
				or int(entry.get("length", -1)) != int(spec["length"]) \
				or String(entry.get("sha256", "")) != String(spec["sha256"]):
			return _fail("Cleanup manifest span differs for %s." % file_name)
		var source := FileAccess.get_file_as_bytes(ROOT + file_name)
		if source.size() != int(spec["length"]) or _sha256(source) != String(spec["sha256"]):
			return _fail("Packaged ROM helper failed its size/hash check: %s." % file_name)
		if file_name == "bank00_cutscene_cleanup_9B7F_9B9F.bin":
			_direct_oam_source = source
	_configured = true
	return true


## Applies only the direct $9B7F->$9B9F OAM/motion-record helper called from
## match setup. It deliberately does not apply the separate $98A0 PPU clear.
func execute_direct_9b7f_oam_clear(registers_before: Dictionary,
		return_source_pc: int = 0xA4FC) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return {"ok": false, "status": "source_rejected", "error": error_message}
	if _direct_oam_source.size() != 33 \
			or _direct_oam_source.slice(0, 6) != PackedByteArray([0xA2, 0x00, 0xA9, 0xF8, 0x9D, 0x68]) \
			or int(_direct_oam_source[0x20]) != 0x60:
		return {"ok": false, "status": "source_rejected", "error": "Direct $9B7F OAM-clear bytes failed validation."}
	for name: String in ["a", "x", "y", "p_known_mask", "p_known_value"]:
		var value := int(registers_before.get(name, -1))
		if value < 0 or value > 0xFF:
			return {"ok": false, "status": "source_state_rejected", "error": "Direct $9B7F input %s must be a known byte." % name}
	var writes: Array[Dictionary] = []
	for offset in OAM_BYTES:
		writes.append({"source_pc": 0x9B83, "address": OAM_SHADOW_START + offset, "value": OAM_HIDDEN_Y})
	for offset in OAM_BYTES:
		writes.append({"source_pc": 0x9B8B, "address": OAM_DMA_START + offset, "value": OAM_HIDDEN_Y})
	for index in MOTION_RECORD_STARTS.size():
		writes.append({"source_pc": 0x9B93 + index * 3, "address": MOTION_RECORD_STARTS[index], "value": 0})
	var next_registers := registers_before.duplicate(true)
	next_registers["a"] = 0
	next_registers["x"] = 0
	next_registers["p_known_mask"] = int(next_registers["p_known_mask"]) | 0x82
	var old_mask := int(next_registers["p_known_mask"])
	next_registers["p_known_value"] = (int(next_registers["p_known_value"]) & old_mask & 0x7D) | 0x02
	return {
		"ok": true,
		"status": "returned_from_direct_9b7f",
		"source_rom_sha256": ROM_SHA256,
		"source_path": [0x9B7F, 0x9B81, 0x9B83, 0x9B86, 0x9B87, 0x9B89,
			0x9B8B, 0x9B8E, 0x9B8F, 0x9B91, 0x9B93, 0x9B96, 0x9B99, 0x9B9C, 0x9B9F],
		"return_source_pc": return_source_pc,
		"cpu_cycles": 5148,
		"registers_after": next_registers,
		"ram_writes": writes,
		"ppu_effects": [],
		"executes_6502": false,
		"trace_state_used": false,
		"emulator_data_used": false,
	}


## Execute only the caller's `$98A0` PPU clear. The separate `$9B7F` OAM clear
## is intentionally not run because the fresh-match caller continues directly
## from `$A580` into `$A583`.
func execute_98a0_ppu_clear_only(presenter: Node,
		ppu_shadow_input: Dictionary, call_source_pc: int = 0xA580,
		return_source_pc: int = 0xA583) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return {"ok": false, "status": "source_rejected", "error": error_message}
	if presenter == null or not presenter.has_method("apply_source_ppu_clear_events"):
		return {"ok": false, "status": "presentation_rejected",
			"error": "The live renderer lacks the source `$98A0` PPU-clear consumer."}
	var ctrl := int(ppu_shadow_input.get("ctrl_shadow", -1))
	var mask := int(ppu_shadow_input.get("mask_shadow", -1))
	if not bool(ppu_shadow_input.get("ok", false)) \
			or ctrl < 0 or ctrl > 0xFF or mask < 0 or mask > 0xFF:
		return {"ok": false, "status": "source_state_rejected",
			"error": "The `$98A0` caller needs known `$0020/$0021` source PPU shadows."}
	var masked_ctrl := ctrl & 0x7F
	var masked_mask := mask & 0xE7
	if (masked_ctrl & 0x04) != 0:
		return {"ok": false, "status": "source_state_rejected",
			"error": "The `$98A0` source path does not support a 32-byte PPU increment."}
	var restored_mask := masked_mask | 0x18
	var restored_ctrl := masked_ctrl | 0x80
	var events: Array[Dictionary] = [
		{"source_pc": 0x98A4, "operation": "write", "ppu_register": 0x2000, "value": masked_ctrl},
		{"source_pc": 0x98AD, "operation": "write", "ppu_register": 0x2001, "value": masked_mask},
		{"source_pc": 0x98B4, "operation": "write", "ppu_register": 0x2006, "value": 0x20},
		{"source_pc": 0x98B9, "operation": "write", "ppu_register": 0x2006, "value": 0x00},
	]
	for offset in PPU_NAMETABLE_BYTES:
		events.append({"source_pc": 0x98C1, "operation": "write",
			"ppu_register": 0x2007, "ppu_address": 0x2000 + offset, "value": 0x00})
	events.append_array([
		{"source_pc": 0x98CE, "operation": "write", "ppu_register": 0x2001, "value": restored_mask},
		{"source_pc": 0x98D9, "operation": "write", "ppu_register": 0x2000, "value": restored_ctrl},
	])
	var render_result: Dictionary = presenter.call("apply_source_ppu_clear_events", events, ctrl)
	if not bool(render_result.get("ok", false)):
		return {"ok": false, "status": "presentation_rejected",
			"error": String(render_result.get("error", "The live renderer rejected `$98A0`."))}
	if events.size() != 0x806 or int(render_result.get("nametable_writes_applied", -1)) != 0x800:
		return {"ok": false, "status": "source_state_rejected",
			"error": "The ROM `$98A0` clear did not produce 2,048 ordered nametable writes."}
	var ram_writes: Array[Dictionary] = [
		{"source_pc": 0x98A7, "address": 0x0020, "value": masked_ctrl},
		{"source_pc": 0x98B0, "address": 0x0021, "value": masked_mask},
		{"source_pc": 0x98D1, "address": 0x0021, "value": restored_mask},
		{"source_pc": 0x98D7, "address": 0x0020, "value": restored_ctrl},
	]
	var source_path: Array[int] = [call_source_pc, 0x98A0, 0x98A4, 0x98A7, 0x98A9, 0x98AB, 0x98AD,
		0x98B0, 0x98B2, 0x98B4, 0x98B7, 0x98B9, 0x98BC, 0x98BE, 0x98C0,
		0x98C1, 0x98C4, 0x98C5, 0x98C7, 0x98C8, 0x98CA, 0x98CC, 0x98CE,
		0x98D1, 0x98D3, 0x98D5, 0x98D7, 0x98D9, 0x98DC, return_source_pc]
	return {"ok": true, "status": "returned_from_98a0_to_%04x" % return_source_pc,
		"source_rom_sha256": ROM_SHA256, "rom_sha256": ROM_SHA256,
		"source_path": source_path,
		"ppu_clear": {"start": 0x2000, "end_exclusive": 0x2800,
			"value": 0x00, "write_count": 0x800},
		"ppu_bus_events": events, "ppu_render_result": render_result,
		"ppu_shadow_before": {"ctrl_shadow": ctrl, "mask_shadow": mask},
		"ppu_shadow_after": {"ctrl_shadow": restored_ctrl, "mask_shadow": restored_mask},
		"ram_writes": ram_writes,
		"cpu_output_contract": {"pc": return_source_pc, "a": restored_ctrl, "x": 0x00, "y": 0x00,
			"p_known_mask": 0x82, "p_known_value": 0x00},
		"trace_state_used": false, "emulator_data_used": false,
		"physical_nes_timing_proven": false}


## Apply the two decoded helper bodies to the current presentation and return
## only the RAM bytes whose writes are independently identified in the ROM.
func execute(presenter: Node, ppu_shadow_input: Dictionary = {}) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return {"ok": false, "status": "source_rejected", "error": error_message}
	var register_writes: Array[Dictionary] = []
	var shadow_ram_writes: Array[Dictionary] = []
	var shadow_before := {}
	var shadow_after := {}
	if not ppu_shadow_input.is_empty():
		var ctrl := int(ppu_shadow_input.get("ctrl_shadow", -1))
		var mask := int(ppu_shadow_input.get("mask_shadow", -1))
		if ctrl < 0 or ctrl > 0xFF or mask < 0 or mask > 0xFF:
			return {"ok": false, "status": "source_state_rejected", "error": "PPU shadow input must contain source-known byte values for RAM $0020 and $0021."}
		var masked_ctrl := ctrl & 0x7F
		var masked_mask := mask & 0xE7
		var restored_mask := masked_mask | 0x18
		var restored_ctrl := masked_ctrl | 0x80
		register_writes = [
			{"source_pc": 0x98A4, "ppu_register": 0x2000, "value": masked_ctrl},
			{"source_pc": 0x98AD, "ppu_register": 0x2001, "value": masked_mask},
			{"source_pc": 0x98CE, "ppu_register": 0x2001, "value": restored_mask},
			{"source_pc": 0x98D9, "ppu_register": 0x2000, "value": restored_ctrl},
		]
		shadow_ram_writes = [
			{"source_pc": 0x98A7, "address": 0x0020, "value": masked_ctrl},
			{"source_pc": 0x98B0, "address": 0x0021, "value": masked_mask},
			{"source_pc": 0x98D1, "address": 0x0021, "value": restored_mask},
			{"source_pc": 0x98D7, "address": 0x0020, "value": restored_ctrl},
		]
		shadow_before = {"ctrl_shadow": ctrl, "mask_shadow": mask}
		shadow_after = {"ctrl_shadow": restored_ctrl, "mask_shadow": restored_mask}
	if presenter == null or not presenter.has_method("apply_rom_cutscene_cleanup_clear") \
			or not bool(presenter.call("apply_rom_cutscene_cleanup_clear")):
		return {"ok": false, "status": "presentation_rejected", "error": "The live ROM PPU/OAM presenter refused cleanup."}
	if not register_writes.is_empty():
		if not presenter.has_method("apply_source_ppu_register_writes") \
				or not bool(presenter.call("apply_source_ppu_register_writes", register_writes)):
			return {"ok": false, "status": "presentation_rejected", "error": "The live presenter refused ROM-source PPU register writes."}
	var ram_writes: Array[Dictionary] = []
	for index in OAM_BYTES:
		ram_writes.append({"source_pc": 0x9B83, "address": OAM_SHADOW_START + index, "value": OAM_HIDDEN_Y})
	for index in OAM_BYTES:
		ram_writes.append({"source_pc": 0x9B8B, "address": OAM_DMA_START + index, "value": OAM_HIDDEN_Y})
	for address in MOTION_RECORD_STARTS:
		var motion_index := MOTION_RECORD_STARTS.find(address)
		ram_writes.append({"source_pc": 0x9B93 + motion_index * 3, "address": address, "value": 0})
	ram_writes.append_array(shadow_ram_writes)
	return {
		"ok": true,
		"status": "returned_from_9ba0",
		"source_path": [0x9BA3, 0x98A0, 0x98DB, 0x9BA6, 0x9B7F, 0x9B9F],
		"return_source_pc": 0x82E2,
		"ppu_clear": {"source_pc": 0x98C1, "start": 0x2000, "end_exclusive": 0x2800, "value": 0, "write_count": 0x800},
		"ppu_register_shadow": "ROM-byte-derived $0020/$0021 values and ordered $2000/$2001 writes are recorded by the Godot presenters; scanline gating and sub-frame timing remain unmodeled.",
		"oam_shadow_fill": {"source_pc": 0x9B83, "start": OAM_SHADOW_START, "end_exclusive": OAM_SHADOW_START + OAM_BYTES, "value": OAM_HIDDEN_Y, "write_count": OAM_BYTES},
		"oam_dma_fill": {"source_pc": 0x9B8B, "start": OAM_DMA_START, "end_exclusive": OAM_DMA_START + OAM_BYTES, "value": OAM_HIDDEN_Y, "write_count": OAM_BYTES},
		"motion_record_clear": {"source_pc": 0x9B93, "addresses": MOTION_RECORD_STARTS.duplicate(), "value": 0},
		"ppu_shadow_before": shadow_before,
		"ppu_shadow_after": shadow_after,
		"ppu_register_writes": register_writes,
		"ram_writes": ram_writes,
		"cpu_output_contract": {
			"return_pc": 0x82E2,
			"a": 0x00,
			"x": 0x00,
			"y": 0x00,
			"p_known_mask": 0x82,
			"p_known_value": 0x02,
			"p_other_bits": "preserved from the cleanup caller context",
			"sp_delta": 0,
			"provenance": "ROM $98A0->$9B7F leaves A/X/Y=0; final LDA #$00 sets N/Z and RTS preserves status",
		},
		"rom_sha256": ROM_SHA256,
		"executes_6502": false,
	}


func get_status() -> Dictionary:
	return {"configured": _configured, "error": error_message, "rom_sha256": ROM_SHA256, "executes_6502": false}


func _fail(message: String) -> bool:
	error_message = message
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()

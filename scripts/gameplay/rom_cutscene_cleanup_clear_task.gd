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
const OAM_HIDDEN_Y := 0xF8
const MOTION_RECORD_STARTS := [0x0568, 0x0588, 0x05A8, 0x05C8]

var error_message := ""
var _configured := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
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
	_configured = true
	return true


## Apply the two decoded helper bodies to the current presentation and return
## only the RAM bytes whose writes are independently identified in the ROM.
func execute(visuals: KickoffCutsceneVisuals) -> Dictionary:
	if not _configured and not configure_from_project_sources():
		return {"ok": false, "status": "source_rejected", "error": error_message}
	if visuals == null or not visuals.apply_rom_cutscene_cleanup_clear():
		return {"ok": false, "status": "presentation_rejected", "error": "The live cutscene PPU/OAM presenter refused cleanup."}
	var ram_writes: Array[Dictionary] = []
	for index in OAM_BYTES:
		ram_writes.append({"source_pc": 0x9B83, "address": OAM_SHADOW_START + index, "value": OAM_HIDDEN_Y})
	for index in OAM_BYTES:
		ram_writes.append({"source_pc": 0x9B8B, "address": OAM_DMA_START + index, "value": OAM_HIDDEN_Y})
	for address in MOTION_RECORD_STARTS:
		var motion_index := MOTION_RECORD_STARTS.find(address)
		ram_writes.append({"source_pc": 0x9B93 + motion_index * 3, "address": address, "value": 0})
	return {
		"ok": true,
		"status": "returned_from_9ba0",
		"source_path": [0x9BA3, 0x98A0, 0x98DB, 0x9BA6, 0x9B7F, 0x9B9F],
		"return_source_pc": 0x82E2,
		"ppu_clear": {"source_pc": 0x98C1, "start": 0x2000, "end_exclusive": 0x2800, "value": 0, "write_count": 0x800},
		"ppu_register_shadow": "ROM masks/restores $0020/$0021 and $2000/$2001; runtime register shadows are not implemented.",
		"oam_shadow_fill": {"source_pc": 0x9B83, "start": OAM_SHADOW_START, "end_exclusive": OAM_SHADOW_START + OAM_BYTES, "value": OAM_HIDDEN_Y, "write_count": OAM_BYTES},
		"oam_dma_fill": {"source_pc": 0x9B8B, "start": OAM_DMA_START, "end_exclusive": OAM_DMA_START + OAM_BYTES, "value": OAM_HIDDEN_Y, "write_count": OAM_BYTES},
		"motion_record_clear": {"source_pc": 0x9B93, "addresses": MOTION_RECORD_STARTS.duplicate(), "value": 0},
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

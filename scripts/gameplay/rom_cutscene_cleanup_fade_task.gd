extends RefCounted
class_name RomCutsceneCleanupFadeTask
## Cooperative model of the paired-counter loop called from ROM $9BA0.
## Each step decrements nonzero counters, builds the source palette packet,
## then yields through $9FA8. It does not model CPU-cycle or PPU bus timing.

const FADE_MODEL := preload("res://scripts/opening/prototypes/ea_fade/ea_palette_fade_reference.gd")
const SOURCE_PATH := "res://reference/rom_extract/intro/ea_fade/fade_down_99F0.bin"
const SOURCE_SHA256 := "373756a59c9212c3b25cbd26561e9402466c74982603adf725c6904b8fc9246a"
const LOOKUP_PATH := "res://reference/rom_extract/intro/ea_fade/palette_lut_9EA2.bin"
const LOOKUP_SHA256 := "8b6a7afaf8ffbffa5f9a87f297bcd0f2d9308cce31a1704639f6148ec834cb4b"
const EXPECTED_SOURCE_PREFIX := [
	0xA5, 0x4A, 0x05, 0x4B, 0xF0, 0x16, # LDA $4A / ORA $4B / BEQ $9A0C
	0xAA, 0xF0, 0x02, 0xC6, 0x4A, # TAX / skip or DEC $4A
	0xA5, 0x4B, 0xF0, 0x02, 0xC6, 0x4B, # LDA $4B / skip or DEC $4B
	0x20, 0x71, 0x9A, 0xA9, 0x01, 0x20, 0xA8, 0x9F, # build packet / yield
	0x4C, 0xF0, 0x99, 0x60, # repeat / return
]

enum State { UNCONFIGURED, READY, WAITING_FOR_YIELD, RETURNED, FAILED }

var state := State.UNCONFIGURED
var error_message := ""
var source_frame := -1
var counter_a := 0
var counter_b := 0
var yield_count := 0
var source_pc := 0x99F0
var last_palette_packet := PackedByteArray()

var _base_palette := PackedByteArray()
var _configured := false


func configure_from_project_sources() -> bool:
	error_message = ""
	_configured = false
	var source := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if source.size() != 65 or _sha256(source) != SOURCE_SHA256:
		return _fail("ROM $99F0 helper failed its size/hash check.")
	if source.slice(0, EXPECTED_SOURCE_PREFIX.size()) != PackedByteArray(EXPECTED_SOURCE_PREFIX):
		return _fail("ROM $99F0 loop bytes differ from the supported paired-counter path.")
	var lookup := FileAccess.get_file_as_bytes(LOOKUP_PATH)
	if lookup.size() != 0x40 or _sha256(lookup) != LOOKUP_SHA256:
		return _fail("ROM $9EA2 palette lookup failed its size/hash check.")
	_configured = true
	state = State.READY
	return true


## Starts with the current VM-modeled fade counters and ROM-derived 32-byte
## background/sprite palette. No capture values are accepted as runtime seeds.
func begin(fade_a: int, fade_b: int, base_palette: PackedByteArray) -> bool:
	if not _configured and not configure_from_project_sources():
		return false
	if fade_a < 0 or fade_a > 0x0F or fade_b < 0 or fade_b > 0x0F:
		return _fail("ROM $99F0 counters must be bytes in the source range $00-$0F.")
	if FADE_MODEL.has_fade_work(fade_a, fade_b) and base_palette.size() != 0x20:
		return _fail("ROM $9A71 needs the current 32-byte background/sprite palette.")
	counter_a = fade_a
	counter_b = fade_b
	_base_palette = base_palette.duplicate()
	yield_count = 0
	source_frame = -1
	source_pc = 0x99F0
	last_palette_packet.clear()
	state = State.READY
	return true


## Execute one source-selected $99F0 pass. The first call starts the helper;
## subsequent calls resume after one $9FA8(A=$01) cooperative yield.
func advance_source_tick(at_source_frame: int) -> Dictionary:
	if state == State.UNCONFIGURED or state == State.FAILED:
		return _refused("not_configured")
	if state == State.RETURNED:
		return _refused("already_returned")
	if state == State.WAITING_FOR_YIELD:
		state = State.READY
		source_pc = 0x99F0
	if not FADE_MODEL.has_fade_work(counter_a, counter_b):
		state = State.RETURNED
		source_pc = 0x9A0C
		source_frame = at_source_frame
		return get_status().merged({"ok": true, "status": "returned_zero_counters"})
	var next_counters: Vector2i = FADE_MODEL.fade_down_tick(counter_a, counter_b)
	counter_a = next_counters.x
	counter_b = next_counters.y
	var palette: PackedByteArray = FADE_MODEL.build_palette(_base_palette, counter_a, counter_b)
	last_palette_packet = PackedByteArray([0x20, 0x00, 0x3F])
	last_palette_packet.append_array(palette)
	yield_count += 1
	source_frame = at_source_frame
	source_pc = 0x9A06
	state = State.WAITING_FOR_YIELD
	return get_status().merged({
		"ok": true,
		"status": "yielded_after_palette_step",
		"palette_packet": last_palette_packet.duplicate(),
	})


func get_status() -> Dictionary:
	return {
		"state": State.keys()[state].to_lower(),
		"configured": _configured,
		"counter_a": counter_a,
		"counter_b": counter_b,
		"yield_count": yield_count,
		"source_pc": source_pc,
		"source_frame": source_frame,
		"last_palette_packet_hex": last_palette_packet.hex_encode(),
		"rom_helper_sha256": SOURCE_SHA256,
	}


func _refused(status: String) -> Dictionary:
	return {"ok": false, "status": status, "error": error_message, "source_pc": source_pc}


func _fail(message: String) -> bool:
	error_message = message
	state = State.FAILED
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()

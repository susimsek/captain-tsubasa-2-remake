extends SceneTree
## Verifies that the descriptor-$1D CPU spans needed by the shared renderer
## are loaded from the pinned ROM-derived resource manifest. This does not run
## the live renderer worker or claim route/PPU behavior.

const WORKER_SCRIPT := preload("res://scripts/gameplay/rom_fresh_bank18_worker_prefix.gd")
const EXPECTED := {
	"descriptor_pointer_entry_1D": [0xB409, 2, "db6d9052b576d973196363e11163d492f50926c2f1d1efd67b3d999817b0d04d"],
	"descriptor_1D": [0xB6C7, 29, "d9f63c7bd60735f2aadd35e03766525073acbc0aa12922692655fb70eb7a26a7"],
	"row_00": [0xBCF9, 2, "b2200f9f0de90684fe6b2c52aae2fc73fe369ae9a820da1c1da11fab3833732e"],
	"row_01": [0xBCFB, 11, "e873faaa4b707a650bf30811c5da2aa528c9fe56c8e4679e80852f8bed27beb5"],
	"row_02": [0xBD06, 11, "3a8fcf9d45c2df247d357bb5ba3ea246918b37e34f510b5fbf41b97d7d926ac8"],
	"row_03": [0xBD11, 11, "ca6c46cf2300173c749e8b60dabf5558e777141a8540f5abd965b5af6a92c742"],
	"row_04": [0xBD1C, 11, "70bddc4d619fa603c4c6f142aceb09e608b04a58b2f02c1565c6354d862182a8"],
}


func _initialize() -> void:
	var worker = WORKER_SCRIPT.new()
	if not worker.configure_from_project_sources():
		_fail("Worker source configuration failed: " + worker.error_message)
		return
	var spans_variant: Variant = worker.get("_pass_receiver_descriptor_1d_spans")
	if not spans_variant is Array or spans_variant.size() != EXPECTED.size():
		_fail("The shared worker did not load the exact seven descriptor-$1D spans.")
		return
	var observed: Dictionary = {}
	for span_variant: Variant in spans_variant:
		if not span_variant is Dictionary:
			_fail("Descriptor-$1D span loader returned a malformed record.")
			return
		var span: Dictionary = span_variant
		var name := String(span.get("name", ""))
		if not EXPECTED.has(name):
			_fail("Descriptor-$1D loader returned an unexpected source: " + name)
			return
		var expected: Array = EXPECTED[name]
		var bytes: PackedByteArray = span.get("bytes", PackedByteArray())
		if int(span.get("bank", -1)) != 0x19 \
				or int(span.get("start", -1)) != int(expected[0]) \
				or bytes.size() != int(expected[1]) \
				or FileAccess.get_sha256(String(span.get("resource", ""))) != String(expected[2]):
			_fail("Descriptor-$1D source span failed bank/address/length/hash verification: " + name)
			return
		observed[name] = true
	for name: String in EXPECTED:
		if not observed.has(name):
			_fail("Descriptor-$1D loader omitted source span: " + name)
			return
	print("PASS: shared worker loads all seven hash-checked descriptor-$1D pointer, header, and row spans from ROM-derived resources.")
	print("LIMIT: this verifies source loading only; it does not execute the live `$EF7F->$C515` worker, scheduler, NMI, queue consumer, or PPU transfer.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

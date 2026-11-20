extends SceneTree

const PRODUCER_SCRIPT := preload("res://scripts/gameplay/rom_cutscene_chr_selector_shadow_producer.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var producer: Variant = PRODUCER_SCRIPT.new()
	if not producer.configure_from_project_sources():
		_fail("ROM CHR-shadow producer did not configure: " + producer.error_message)
		_quit()
		return
	var event := {
		"kind": "background_1", "opcode": 0xF9, "id": 0x5E,
		"arguments": [0x5E], "event_index": 50, "cpu_address": 0xA386,
	}
	var load_receipt := {
		"ok": true, "source_rom_sha256": ROM_SHA256,
		"event_index": 50, "background_id": 0x5E,
		"capacity_batch_count": 7, "replace_primary": true,
	}
	var selector_pair: Array[int] = [0x3C, 0x3E]
	var pair_receipt: Dictionary = producer.build_background_pair_receipt(
		event, 7112, load_receipt, selector_pair)
	if not bool(pair_receipt.get("ok", false)):
		_fail("ROM `$AE37->$0075/$0076` source task failed: " + String(pair_receipt.get("error", "unknown error")))
		_quit()
		return
	var pair_writes: Array = pair_receipt.get("ram_writes", [])
	if pair_writes.size() != 2 \
			or not _has_write(pair_writes, 0x8B3F, 0x0075, 0x3C) \
			or not _has_write(pair_writes, 0x8B44, 0x0076, 0x3E) \
			or bool(pair_receipt.get("emulator_data_used", true)):
		_fail("ROM `$8B39-$8B44` did not produce the checked `$75/$76` pair.")
		_quit()
		return
	var task_status := {
		"state": "completed", "event_index": 50,
		"background_id": 0x5E, "return_scan_source_frame": 7119,
	}
	var copy_receipt: Dictionary = producer.build_nmi_shadow_copy_receipt(
		pair_receipt, task_status, 7119, selector_pair)
	if not bool(copy_receipt.get("ok", false)):
		_fail("ROM NMI `$8CA7-$8CAC` source task failed: " + String(copy_receipt.get("error", "unknown error")))
		_quit()
		return
	var copy_writes: Array = copy_receipt.get("ram_writes", [])
	if copy_writes.size() != 2 \
			or not _has_write(copy_writes, 0x8CA7, 0x008E, 0x3C) \
			or not _has_write(copy_writes, 0x8CAB, 0x008F, 0x3E) \
			or bool(copy_receipt.get("trace_state_used", true)):
		_fail("ROM NMI copy did not produce the checked `$8E/$8F` pair.")
		_quit()
		return
	var bad_pair: Array[int] = [0x3C, 0x3F]
	var rejected: Dictionary = producer.build_background_pair_receipt(
		event, 7112, load_receipt, bad_pair)
	if bool(rejected.get("ok", true)):
		_fail("Producer accepted a PPU selector pair that differs from the ROM table record.")
		_quit()
		return
	print("PASS: ROM `$AE37` derives `$0075/$0076`; the completed F9 `$5E` task feeds `$008E/$008F` through checked NMI stores.")
	print("LIMIT: the receipts align to source-frame task edges; intra-frame NMI/PPU timing is not proven.")
	_quit()


func _has_write(writes: Array, source_pc: int, address: int, value: int) -> bool:
	for item_variant in writes:
		if not item_variant is Dictionary:
			continue
		var item: Dictionary = item_variant
		if int(item.get("source_pc", -1)) == source_pc \
				and int(item.get("address", -1)) == address \
				and int(item.get("value", -1)) == value:
			return true
	return false


func _fail(message: String) -> void:
	_failed = true
	push_error(message)


func _quit() -> void:
	quit(1 if _failed else 0)

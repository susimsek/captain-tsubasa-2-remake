extends SceneTree
## Verifies the ROM-derived slot-$05 task seed and `$84C6` restore boundary.

const SEED_SCRIPT := preload("res://scripts/gameplay/rom_fresh_kickoff_cutscene_worker_seed.gd")
const ROM_SHA256 := "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var producer: Variant = SEED_SCRIPT.new()
	var configured: bool = producer.configure_from_project_sources()
	_check(configured, "task seed ROM spans and manifest hashes configure: " + String(producer.error_message))
	if _failures > 0:
		quit(1)
		return
	var handoff := {
		"ok": true,
		"source_rom_sha256": ROM_SHA256,
		"selected_option": "KICK OFF",
		"trace_state_used": false,
		"emulator_data_used": false,
	}
	var receipt: Dictionary = producer.build_title_cutscene1_seed(handoff)
	_check(bool(receipt.get("ok", false)), "live title handoff produces a slot-$05 worker seed")
	_check(int(receipt.get("slot_offset", -1)) == 0x05
		and int(receipt.get("ready_value", -1)) == 0xFF,
		"ROM installs the cutscene worker at slot $05 with the ready sentinel")
	_check(int(receipt.get("saved_sp", -1)) == 0x4E
		and int(receipt.get("resume_sp", -1)) == 0x50,
		"two source DEYs save SP $4E and RTS resumes with SP $50")
	_check(int(receipt.get("stack_return_address", -1)) == 0x84C5
		and int(receipt.get("resume_pc", -1)) == 0x84C6,
		"scheduler RTS resumes at the worker entry `$84C6`")
	_check(int(receipt.get("bank_low", -1)) == 0x00,
		"`$8494` passes bank-low `$00` into the worker record")
	var cpu: Dictionary = receipt.get("worker_entry_cpu", {})
	_check(int(cpu.get("pc", -1)) == 0x84C6
		and int(cpu.get("a", -1)) == 0x4E
		and int(cpu.get("x", -1)) == 0x4E
		and int(cpu.get("y", -1)) == 0x4E
		and int(cpu.get("sp", -1)) == 0x50,
		"`$9F52` restores the ROM-derived `$84C6` worker CPU entry context")
	var entry_stack: Array = receipt.get("worker_entry_stack_bytes", [])
	_check(entry_stack.size() == 2
		and int(entry_stack[0].get("address", -1)) == 0x014F
		and int(entry_stack[0].get("value", -1)) == 0xC5
		and int(entry_stack[1].get("address", -1)) == 0x0150
		and int(entry_stack[1].get("value", -1)) == 0x84,
		"worker entry carries only the two source-known RTS bytes, without inventing the rest of stack RAM")
	_check(not bool(receipt.get("scheduler_dispatch_executed", true))
		and bool(receipt.get("cutscene_vm_uses_source_worker_seed", false)),
		"receipt gates the VM without claiming a live scheduler tick")
	var writes: Array = receipt.get("task_record_writes", [])
	_check(writes.size() == 5, "seed receipt lists all source-owned writes")
	if writes.size() == 5:
		_check(int(writes[1].get("address", -1)) == 0x014F
			and int(writes[2].get("address", -1)) == 0x0150,
			"ROM stack return bytes are written at `$014F/$0150`")
		_check(int(writes[3].get("address", -1)) == 0x0006
			and int(writes[3].get("value", -1)) == 0x4E,
			"slot-$05 stores the decremented saved SP")
	_check(not bool(receipt.get("trace_state_used", true))
		and not bool(receipt.get("emulator_data_used", true))
		and not bool(receipt.get("physical_nes_timing_proven", true)),
		"receipt is ROM-only and makes no timing claim")
	var wrong_option := handoff.duplicate(true)
	wrong_option["selected_option"] = "CONTINUE"
	_check(not bool(producer.build_title_cutscene1_seed(wrong_option).get("ok", false)),
		"worker seed refuses the Continue title route")
	var trace_handoff := handoff.duplicate(true)
	trace_handoff["trace_state_used"] = true
	_check(not bool(producer.build_title_cutscene1_seed(trace_handoff).get("ok", false)),
		"worker seed refuses trace-derived runtime inputs")
	if _failures > 0:
		quit(1)
		return
	print("PASS: ROM task seed saves SP `$4E`, restores at `$84C6` with SP `$50`, and gates the KICK OFF cutscene runtime.")
	quit(0)


func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("FAIL: " + label)

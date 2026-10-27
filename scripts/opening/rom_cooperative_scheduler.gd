extends RefCounted
class_name RomCooperativeScheduler
## Small, source-derived model of the opening's cooperative task scheduler.
##
## This is a scheduler contract for a later cutscene VM, not a 6502 emulator.
## The host owns task-local script/stack state. When step() returns
## TASK_RESUME_REQUIRED, run that task synchronously until it calls
## yield_current() or finish_current_task(), then call step() again. This
## preserves the ROM's one-at-a-time, slot-ordered wake behavior.
##
## ROM evidence: supplied Turkish ROM SHA-256
## 4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097;
## `$9EED` is file offset 0x01EFD and `$9FA8` is 0x01FB8. The former starts
## `A2 01 B5 00 F0 08 C9 FF ... D6 00 F0 14`, scans X=1,5,...,21, and
## decrements nonzero finite counters, while an installed `$FF` task byte is
## immediately ready. `$9F69` installs the cold-open worker with that `$FF`
## value. `$9FA8` stores A at `$19`, saves task context, rewrites a yielded
## A=`$FF` as `$FE`, stores the finite delay at `$00,X`, and jumps back into
## the scheduler. Task-install bytes and frame-anchor evidence are documented
## in `reference/rom_extract/intro/cutscene_boot_task_install_trace.md`.
##
## Unmodeled: 6502 stack/register/mapper restoration, empty-task detection,
## instruction/cycle timing, NMI route and controller scan, `$05E8` PPU packet
## writes, and within-frame raster effects.

signal nmi_release_consumed(scheduler_tick: int)
signal task_resume_requested(slot_offset: int, scheduler_tick: int)
signal pass_completed(scheduler_tick: int, resumed_task_count: int)

## `$9EED` starts X at 1 and advances by four through the six task records.
const TASK_SLOT_OFFSETS: Array[int] = [1, 5, 9, 13, 17, 21]
const NMI_READY_BIT: int = 0x80
const READY_TASK_DELAY_SENTINEL: int = 0xFF
const MAX_FINITE_DELAY: int = 0xFE

enum StepOutcome {
	WAITING_FOR_NMI,
	TASK_RESUME_REQUIRED,
	WAITING_FOR_TASK_OUTCOME,
	PASS_COMPLETED,
}

var scheduler_tick: int = 0
var current_task_slot_offset: int = -1
var nmi_ready_latched: bool = false
var coalesced_nmi_release_count: int = 0
var last_pass_resumed_task_count: int = 0

var _registered: PackedByteArray = PackedByteArray()
var _delay_remaining: PackedInt32Array = PackedInt32Array()
var _scan_index: int = 0
var _pass_active: bool = false
var _resumed_this_pass: int = 0


func _init() -> void:
	_registered.resize(TASK_SLOT_OFFSETS.size())
	_registered.fill(0)
	_delay_remaining.resize(TASK_SLOT_OFFSETS.size())
	_delay_remaining.fill(0)


## Attach a host-owned task context to one of the ROM's six task offsets.
## `initial_delay` is the source task-byte value, not a video-frame count.
## `$FF` means ready on the next scheduler scan (as installed by `$9F69`);
## zero leaves the context parked until the host schedules it again.
func register_task(slot_offset: int, initial_delay: int = 0) -> bool:
	var index := _slot_index(slot_offset)
	if index < 0 or _registered[index] != 0:
		return false
	if initial_delay < 0 or initial_delay > READY_TASK_DELAY_SENTINEL:
		return false
	_registered[index] = 1
	_delay_remaining[index] = initial_delay
	return true


## Set a saved task byte for an attached task that is not currently running.
## Setting `$FF` makes it ready on the next scheduler scan.
func set_task_delay(slot_offset: int, delay_byte: int) -> bool:
	var index := _slot_index(slot_offset)
	if index < 0 or _registered[index] == 0 or current_task_slot_offset == slot_offset:
		return false
	if delay_byte < 0 or delay_byte > READY_TASK_DELAY_SENTINEL:
		return false
	_delay_remaining[index] = delay_byte
	return true


## Called by the NMI owner only after any source-ordered PPU queue work has
## committed. `$001B.7` is a one-bit latch, so multiple releases before the
## scheduler consumes it coalesce rather than becoming a counted backlog.
func notify_nmi_ready() -> void:
	if nmi_ready_latched:
		coalesced_nmi_release_count += 1
	else:
		nmi_ready_latched = true


## Begin the one observed startup scan entered by the main task's first
## `$9FA8` yield. The ROM dispatches its ready `$0005=$FF` worker before the
## first NMI; this scan must not consume or synthesize an NMI-ready latch and
## does not increment `scheduler_tick`.
func begin_initial_ready_scan() -> bool:
	if _pass_active or current_task_slot_offset >= 0 or nmi_ready_latched:
		return false
	_pass_active = true
	_scan_index = 0
	_resumed_this_pass = 0
	return true


## Advance the scheduler until one task is due, the pass completes, or input
## from the host task is required. A task resume pauses scanning; the host must
## call yield_current() or finish_current_task() before advancing again.
func step() -> StepOutcome:
	if current_task_slot_offset >= 0:
		return StepOutcome.WAITING_FOR_TASK_OUTCOME

	if not _pass_active:
		if not nmi_ready_latched:
			return StepOutcome.WAITING_FOR_NMI
		nmi_ready_latched = false
		scheduler_tick += 1
		_scan_index = 0
		_resumed_this_pass = 0
		_pass_active = true
		nmi_release_consumed.emit(scheduler_tick)

	while _scan_index < TASK_SLOT_OFFSETS.size():
		var index := _scan_index
		_scan_index += 1 # `$9EED` resumes at the following slot after a yield.
		if _registered[index] == 0:
			continue
		var remaining := int(_delay_remaining[index])
		if remaining == 0:
			continue
		if remaining != READY_TASK_DELAY_SENTINEL:
			remaining -= 1
			_delay_remaining[index] = remaining
			if remaining > 0:
				continue
		current_task_slot_offset = TASK_SLOT_OFFSETS[index]
		_resumed_this_pass += 1
		task_resume_requested.emit(current_task_slot_offset, scheduler_tick)
		return StepOutcome.TASK_RESUME_REQUIRED

	_pass_active = false
	last_pass_resumed_task_count = _resumed_this_pass
	pass_completed.emit(scheduler_tick, last_pass_resumed_task_count)
	return StepOutcome.PASS_COMPLETED


## Model `$9FA8(A=n)`: save/yield the currently resumed task and have
## `$9EED` continue scanning the next task slot. Normally the delay decrements
## on later NMI-ready passes. `current_release_already_elapsed` is a source
## phase observation: an NMI release was already latched during the caller's
## work, so the next full slot scan counts that release immediately after the
## yield. A yielded `$FF` is rewritten to `$FE`; `$9F69` can install `$FF`
## directly. Exact 6502 interrupt/cycle timing is not modeled.
func yield_current(delay_argument: int, current_release_already_elapsed: bool = false) -> bool:
	if current_task_slot_offset < 0 or delay_argument < 0 or delay_argument > 0xFF:
		return false
	var index := _slot_index(current_task_slot_offset)
	if index < 0:
		return false
	var stored_delay := MAX_FINITE_DELAY if delay_argument == READY_TASK_DELAY_SENTINEL else delay_argument
	if current_release_already_elapsed and stored_delay > 0 and stored_delay < READY_TASK_DELAY_SENTINEL:
		stored_delay -= 1
	_delay_remaining[index] = stored_delay
	current_task_slot_offset = -1
	return true


## End a host task context while retaining its table slot as a zero-delay
## entry. The source scheduler skips zero counters and continues scanning.
func finish_current_task() -> bool:
	if current_task_slot_offset < 0:
		return false
	var index := _slot_index(current_task_slot_offset)
	if index < 0:
		return false
	_delay_remaining[index] = 0
	_registered[index] = 0
	current_task_slot_offset = -1
	return true


func get_task_delay(slot_offset: int) -> int:
	var index := _slot_index(slot_offset)
	return int(_delay_remaining[index]) if index >= 0 and _registered[index] != 0 else -1


func is_pass_active() -> bool:
	return _pass_active


func _slot_index(slot_offset: int) -> int:
	return TASK_SLOT_OFFSETS.find(slot_offset)

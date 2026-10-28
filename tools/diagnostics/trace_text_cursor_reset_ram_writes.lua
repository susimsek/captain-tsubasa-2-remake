-- PC-tag text cursor/base RAM writes during the same-input 2904-2908 window.
-- Run in a separate FCEUX instance with --sound 0 --volume 0; no UI/audio
-- capture is used. Output is source evidence only, never a runtime asset.

local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local ROM_PATH = PROJECT_ROOT .. "/Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local EXPECTED_ROM_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"
local EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
local LAST_SOURCE_FRAME = 2908
local WRITE_FIRST_FRAME, WRITE_LAST_FRAME = 2904, 2908
local SNAP_FIRST_FRAME, SNAP_LAST_FRAME = 2903, 2909
local run_id = os.date("%Y%m%d_%H%M%S")
local output_dir = PROJECT_ROOT .. "/reference/diagnostics/text_cursor_reset_ram_writes_" .. run_id
os.execute("mkdir -p " .. string.format("%q", output_dir))

local function open_output(name, header)
	local file = assert(io.open(output_dir .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end

local function byte(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return value or 0
end

local function read_inputs()
	local inputs = {}
	local file = assert(io.open(INPUT_CSV, "r"), "missing source input timeline")
	for line in file:lines() do
		line = line:gsub("\r$", "")
		local frame, up, down, left, right, a, b, start, select = line:match(
			"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
		if frame then
			inputs[tonumber(frame)] = {
				up=up == "1", down=down == "1", left=left == "1", right=right == "1",
				A=a == "1", B=b == "1", start=start == "1", select=select == "1",
			}
		end
	end
	file:close()
	for frame=0,LAST_SOURCE_FRAME do
		assert(inputs[frame], "input timeline is missing source frame " .. frame)
	end
	return inputs
end

local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return value or -1
end

local function hex(value, digits)
	if value == nil or value < 0 then return "" end
	return string.format("$%0" .. digits .. "X", value)
end

local function bytes_hex(first, last)
	local values = {}
	for address=first,last do values[#values+1] = string.format("%02X", byte(address)) end
	return table.concat(values, " ")
end

local function cycles_now()
	local value = -1
	if type(debugger) == "table" and type(debugger.getcyclescount) == "function" then
		pcall(function() value = debugger.getcyclescount() end)
	end
	return value or -1
end

local function ppu_position()
	local line, dot = -1, -1
	if type(ppu) == "table" then
		pcall(function() line = ppu.getscanline() end)
		pcall(function() dot = ppu.getdot() end)
	end
	return line or -1, dot or -1
end

local full_select = 0
local mmc3 = {0,0,0,0,0,0,0,0}
local mmc3_known = {false,false,false,false,false,false,false,false}
local function prg_map()
	local last, second = 31, 30
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(full_select / 64) % 2 == 0 then return r6, r7, second, last end
	return second, r7, r6, last
end

local function pc_bank(pc)
	if pc < 0x8000 then return -1 end
	local r0, r1, r2, r3 = prg_map()
	if pc < 0xA000 then return r0 end
	if pc < 0xC000 then return r1 end
	if pc < 0xE000 then return r2 end
	return r3
end

local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
if md5 ~= EXPECTED_ROM_MD5 then
	error("wrong ROM identity: expected MD5 " .. EXPECTED_ROM_MD5 .. ", got " .. tostring(md5))
end
if type(memory) ~= "table" or type(memory.registerwrite) ~= "function"
		or type(memory.registerexec) ~= "function" then
	error("FCEUX memory.registerwrite/registerexec APIs are required")
end

local writes = open_output("cursor_ram_writes.csv",
	"source_frame,emulator_frame,cycle_absolute,cycle_from_frame_start,ppu_scanline,ppu_dot,cpu_pc,pc_prg_bank,cpu_a,cpu_x,cpu_y,cpu_p,cpu_sp,address,old_value,new_value,script_ptr_004d_004e,cursor_ram_004f_0055,task_0001_0018,scheduler_slot_0000,task_context_0140_0150,stack_from_sp_0100,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000")
local execution = open_output("cursor_setup_exec.csv",
	"source_frame,emulator_frame,cycle_absolute,cycle_from_frame_start,ppu_scanline,ppu_dot,event,cpu_pc,pc_prg_bank,cpu_a,cpu_x,cpu_y,cpu_p,cpu_sp,script_ptr_004d_004e,cursor_ram_004f_0055,task_0001_0018,scheduler_slot_0000,task_context_0140_0150,stack_from_sp_0100,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000")
local frames = open_output("frame_state.csv",
	"source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,script_ptr_004d_004e,cursor_ram_004f_0055,queue_cursor_0628,task_0001_0018,scheduler_slot_0000,task_context_0140_0150,pc_after_frame,pc_prg_bank,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000")
local metadata = open_output("metadata.txt")
metadata:write("rom_path=" .. ROM_PATH .. "\n")
metadata:write("rom_md5_observed=" .. tostring(md5) .. "\n")
metadata:write("rom_sha256_expected=" .. EXPECTED_ROM_SHA256 .. "\n")
metadata:write("input_timeline=" .. INPUT_CSV .. "\n")
metadata:write("source_frames_replayed=0-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("source_frames_with_ram_write_hooks=" .. WRITE_FIRST_FRAME .. "-" .. WRITE_LAST_FRAME .. "\n")
metadata:write("frame_snapshots=" .. SNAP_FIRST_FRAME .. "-" .. SNAP_LAST_FRAME .. "\n")
metadata:write("audio=FCEUX launch flags --sound 0 --volume 0; SDL_AUDIODRIVER=dummy; no captured audio\n")
metadata:write("hooks=CPU RAM writes to $004F-$0055; execution entries at $84C0/$84CB/$84CD/$84E3/$84E7/$8520/$8678/$881B/$8855/$88B1/$8879/$899A/$9B28/$9B5E/$9EED/$9FA8\n")
metadata:write("caller_trace=execution hooks at every PC $84C0-$84FF, FD resume/advance $885A/$885D/$8887, scheduler select $9F11, and banked task callsite/return $80DE/$80E1\n")
metadata:write("write_callbacks=PC, registers, stack bytes, task context, script pointer, and MMC3 PRG bank map are captured at each write\n")
metadata:write("frame_convention=source frame N sets the captured input before one emu.frameadvance; emulator frame after is recorded\n")
metadata:write("purpose=identify the ROM PC/task writer of the $0051/$0052 text-origin reset before glyph $A238\n")
metadata:flush()

local inputs = read_inputs()
local current_source_frame = -1
local frame_cycle_start = -1
local last_value = {}
local function active_write_window()
	return current_source_frame >= WRITE_FIRST_FRAME and current_source_frame <= WRITE_LAST_FRAME
end

local function context_csv_fields()
	local cycle = cycles_now()
	local relative = cycle >= 0 and frame_cycle_start >= 0 and cycle - frame_cycle_start or -1
	local line, dot = ppu_position()
	local pc = reg("pc")
	local sp = reg("s")
	local r0, r1, r2, r3 = prg_map()
	local stack_start = sp >= 0 and (0x0100 + ((sp + 1) % 0x100)) or 0x0100
	local stack_end = sp >= 0 and (0x0100 + ((sp + 8) % 0x100)) or 0x0107
	return {
		tostring(current_source_frame), tostring(emu.framecount()), tostring(cycle), tostring(relative),
		tostring(line), tostring(dot), hex(pc,4), tostring(pc_bank(pc)),
		hex(reg("a"),2), hex(reg("x"),2), hex(reg("y"),2), hex(reg("p"),2), hex(sp,2),
		hex(byte(0x004D) + byte(0x004E) * 0x100,4), bytes_hex(0x004F,0x0055),
		bytes_hex(0x0001,0x0018), hex(byte(0x0000),2), bytes_hex(0x0140,0x0150), bytes_hex(stack_start,stack_end),
		hex(full_select,2), hex(r0,2), hex(r1,2), hex(r2,2), hex(r3,2),
	}
end

local function log_cursor_related_write(address, value)
	if not active_write_window() then
		last_value[address] = value or byte(address)
		return
	end
	local fields = context_csv_fields()
	table.insert(fields, 14, hex(address,4))
	table.insert(fields, 15, hex(last_value[address],2))
	table.insert(fields, 16, hex(value or 0,2))
	writes:write(table.concat(fields, ",") .. "\n")
	last_value[address] = value or 0
end

for address=0x004F,0x0055 do
	local watched_address = address
	last_value[watched_address] = byte(watched_address)
	memory.registerwrite(watched_address, 1, function(_, _, value)
		log_cursor_related_write(watched_address, value)
	end)
end
last_value[0x0000] = byte(0x0000)
memory.registerwrite(0x0000, 1, function(_, _, value)
	log_cursor_related_write(0x0000, value)
end)

for address=0x8000,0x8001 do
	local watched_address = address
	memory.registerwrite(watched_address, 1, function(_, _, value)
		if watched_address == 0x8000 then
			full_select = value or 0
		else
			local index = full_select % 8 + 1
			mmc3[index] = value or 0
			mmc3_known[index] = true
		end
	end)
end

local exec_hooks = {
	[0x84C0]="text_setup_entry_84C0", [0x84CB]="text_setup_speed_84CB",
	[0x84CD]="text_setup_origin_84CD", [0x84E3]="cursor_copy_84E3",
	[0x84E7]="interpreter_84E7", [0x8520]="inline_E0_E7_8520",
	[0x8678]="F2_handler_8678", [0x881B]="FA_handler_881B",
	[0x8855]="FD_handler_8855", [0x8879]="common_advance_8879",
	[0x88B1]="FD_fill_helper_88B1", [0x899A]="cursor_or_pause_helper_899A",
	[0x885A]="FD_wait_jsr_885A", [0x885D]="FD_after_wait_885D",
	[0x8887]="FD_pointer_advance_8887", [0x9F11]="scheduler_slot_select_9F11",
	[0x9B28]="queue_reserve_9B28", [0x9B5E]="queue_commit_9B5E",
	[0x9EED]="scheduler_9EED", [0x9FA8]="cooperative_yield_9FA8",
}
-- Capture every instruction address in the cursor-copy routine's ROM window
-- and its likely inline caller. The write callback PC is post-instruction;
-- these exec hooks preserve entry registers/stack at the actual instruction.
for address=0x84C0,0x84FF do
	exec_hooks[address] = string.format("cursor_routine_%04X", address)
end
exec_hooks[0x80DE] = "banked_task_callsite_80DE"
exec_hooks[0x80E1] = "banked_task_return_80E1"
for address, name in pairs(exec_hooks) do
	local watched_pc, event_name = address, name
	memory.registerexec(watched_pc, function()
		if not active_write_window() then return end
		local fields = context_csv_fields()
		table.insert(fields, 7, event_name)
		execution:write(table.concat(fields, ",") .. "\n")
	end)
end

local power_ok, power_error = pcall(emu.poweron)
metadata:write("poweron_success=" .. tostring(power_ok) .. "\n")
metadata:write("poweron_error=" .. tostring(power_error or "") .. "\n")
local cycle_counter_reset = -1
if type(debugger) == "table" and type(debugger.resetcyclescount) == "function" then
	pcall(debugger.resetcyclescount)
	cycle_counter_reset = cycles_now()
end
metadata:write("cycle_counter_after_reset=" .. tostring(cycle_counter_reset) .. "\n")
metadata:write("mapper_registers_known_after_poweron=false; map values remain tentative until written\n")
metadata:flush()
pcall(emu.speedmode, "turbo")

for source_frame=0,LAST_SOURCE_FRAME do
	current_source_frame = source_frame
	for address=0x004F,0x0055 do last_value[address] = byte(address) end
	last_value[0x0000] = byte(0x0000)
	local emulator_frame_before = emu.framecount()
	local cycle_start = cycles_now()
	joypad.set(1, inputs[source_frame])
	frame_cycle_start = cycle_start
	emu.frameadvance()
	local cycle_end = cycles_now()
	local emulator_frame_after = emu.framecount()
	if source_frame >= SNAP_FIRST_FRAME and source_frame <= SNAP_LAST_FRAME then
		local pc = reg("pc")
		local r0, r1, r2, r3 = prg_map()
		frames:write(table.concat({
			tostring(source_frame), tostring(emulator_frame_before), tostring(emulator_frame_after),
			tostring(cycle_start), tostring(cycle_end),
			tostring(cycle_start >= 0 and cycle_end >= cycle_start and cycle_end - cycle_start or -1),
			hex(byte(0x004D) + byte(0x004E) * 0x100,4), bytes_hex(0x004F,0x0055), hex(byte(0x0628),2),
			bytes_hex(0x0001,0x0018), hex(byte(0x0000),2), bytes_hex(0x0140,0x0150), hex(pc,4), tostring(pc_bank(pc)),
			hex(full_select,2), hex(r0,2), hex(r1,2), hex(r2,2), hex(r3,2),
		}, ",") .. "\n")
	end
	if source_frame % 120 == 0 then
		writes:flush(); execution:flush(); frames:flush(); metadata:flush()
	end
end

pcall(emu.speedmode, "normal")
metadata:write("completed_source_frames=" .. tostring(LAST_SOURCE_FRAME + 1) .. "\n")
metadata:write("execution_hook_mapper_registers_known_mask=")
local mask = 0
for i=1,8 do if mmc3_known[i] then mask = mask + 2^(i-1) end end
metadata:write(string.format("%02X\n",mask))
metadata:flush()

for address=0x004F,0x0055 do pcall(memory.registerwrite,address,1,nil) end
pcall(memory.registerwrite,0x0000,1,nil)
for address=0x8000,0x8001 do pcall(memory.registerwrite,address,1,nil) end
for address in pairs(exec_hooks) do pcall(memory.registerexec,address,nil) end
writes:close(); execution:close(); frames:close(); metadata:close()
os.exit()

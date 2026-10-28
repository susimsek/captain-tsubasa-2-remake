-- Same-input, muted FCEUX trace for first-match RNG operand writers from frame 7394.
-- Output is diagnostic evidence only; it is never used as runtime game data.

local PROJECT_ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = PROJECT_ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_RNG_OPERAND_TRACE_OUTPUT_DIR"), "missing output directory")
local CHECKPOINT_FRAME = 7393
local FIRST_WINDOW_FRAME = 7394
local LAST_WINDOW_FRAME = 8593
local LAST_SOURCE_FRAME = LAST_WINDOW_FRAME
os.execute("mkdir -p " .. string.format("%q", OUT))

local function read_inputs(path, route_format)
	local result = {}
	local file = assert(io.open(path, "r"), "missing input file " .. path)
	local first = true
	for line in file:lines() do
		line = line:gsub("\r$", "")
		if first then
			first = false
		else
			local values = {}
			for value in (line .. ","):gmatch("(.-),") do values[#values + 1] = value end
			local frame = tonumber(values[1])
			if frame then
				local offset = route_format and 3 or 2
				result[frame] = {
					up=values[offset] == "1", down=values[offset + 1] == "1",
					left=values[offset + 2] == "1", right=values[offset + 3] == "1",
					A=values[offset + 4] == "1", B=values[offset + 5] == "1",
					start=values[offset + 6] == "1", select=values[offset + 7] == "1",
				}
			end
		end
	end
	file:close()
	return result
end

local inputs = read_inputs(OPENING_INPUT, false)
for frame, state in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = state end
for frame = 0, LAST_SOURCE_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local function output(name, header)
	local file = assert(io.open(OUT .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end

local function byte(address)
	local value = 0
	local ok = pcall(function() value = memory.readbyte(address) end)
	if not ok or type(value) ~= "number" then return 0 end
	return value
end

local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return type(value) == "number" and value or -1
end

local function hex(value, digits)
	if type(value) ~= "number" or value < 0 then return "" end
	return digits == 2 and string.format("$%02X", value) or string.format("$%04X", value)
end

local function csv(values)
	local fields = {}
	for index, value in ipairs(values) do
		fields[index] = tostring(value == nil and "" or value):gsub(",", ";")
	end
	return table.concat(fields, ",")
end

local function physical_ram(address)
	if address >= 0 and address < 0x2000 then return address % 0x0800 end
	return address
end

local metadata = output("metadata.txt")
local rom_md5 = "unavailable"
pcall(function() rom_md5 = rom.gethash("md5") end)
assert(rom_md5 == "eaf2b3745263efa4b1afd2b400f68dae", "wrong ROM: " .. tostring(rom_md5))
metadata:write("purpose=trace live C9C5 operands and CPU-RAM writers for first-match receiver selection\n")
metadata:write("source_frames=0-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("instrumented_writes=exact RAM cells read by C9C5 for X=$FA-$FF,$00-$7E plus $001B,$00E1-$00E3,$0441,$05FC; hooks attach only after frame-7393 state load\n")
metadata:write("c9c5_hooks=entry $C9C5; operand opcodes $C9C8/$C9CB/$C9DC; return $C9E8\n")
metadata:write("audio=disabled by FCEUX --sound 0 --volume 0 with SDL_AUDIODRIVER=dummy; no audio files are recorded\n")
metadata:write("runtime_policy=diagnostic RAM/PC/cycle evidence only; no captured values are runtime data\n")
metadata:flush()

local function read_inputs_hash_metadata()
	metadata:write("opening_input_sha256=" .. tostring(os.getenv("CT2_OPENING_INPUT_SHA256") or "") .. "\n")
	metadata:write("route_input_sha256=" .. tostring(os.getenv("CT2_ROUTE_INPUT_SHA256") or "") .. "\n")
	metadata:write("state_index_sha256=" .. tostring(os.getenv("CT2_STATE_INDEX_SHA256") or "") .. "\n")
	metadata:write("source_rom_sha256=" .. tostring(os.getenv("CT2_ROM_SHA256") or "") .. "\n")
end
read_inputs_hash_metadata()

local mmc3_select = 0
local mmc3 = {0, 2, 4, 5, 6, 7, 0, 1}
local function prg_map()
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(mmc3_select / 64) % 2 == 0 then return r6, r7, 30, 31 end
	return 30, r7, r6, 31
end
local function pc_bank(pc)
	if pc >= 0xE000 then return select(4, prg_map()) end
	if pc >= 0xC000 then return select(3, prg_map()) end
	if pc >= 0xA000 then return select(2, prg_map()) end
	if pc >= 0x8000 then return select(1, prg_map()) end
	return -1
end

local source_frame = -1
local frame_cycle_start = -1
local function timing()
	local absolute = -1
	pcall(function() absolute = debugger.getcyclescount() end)
	local emulator_frame = -1
	pcall(function() emulator_frame = emu.framecount() end)
	return emulator_frame, absolute >= 0 and absolute - frame_cycle_start or -1, absolute
end

local function bytes_at(address, count)
	local result = {}
	for i = 0, count - 1 do result[#result + 1] = string.char(byte(address + i)) end
	return table.concat(result)
end

local function snapshot_signature()
	local ram_ok, ram = pcall(function() return memory.readbyterange(0x0000, 0x0800) end)
	local ppu_ok, ppu_mem = pcall(function() return ppu.readbyterange(0x0000, 0x4000) end)
	assert(ram_ok and type(ram) == "string" and #ram == 0x800, "could not capture CPU RAM signature")
	assert(ppu_ok and type(ppu_mem) == "string" and #ppu_mem == 0x4000, "could not capture PPU memory signature")
	local banks = {prg_map()}
	return {
		frame=emu.framecount(), cycles=debugger.getcyclescount(), ram=ram, ppu=ppu_mem,
		select=mmc3_select,
		registers={mmc3[1], mmc3[2], mmc3[3], mmc3[4], mmc3[5], mmc3[6], mmc3[7], mmc3[8]}, banks=banks,
		mapped_bytes={byte(0x8000), byte(0xA000), byte(0xC000), byte(0xE000)},
	}
end

local function restore_mmc3(state)
	mmc3_select = state.select
	for i = 1, 8 do mmc3[i] = state.registers[i] end
end

local function verify_signature(expected, label)
	local observed = snapshot_signature()
	assert(observed.frame == expected.frame, label .. " frame mismatch")
	assert(observed.cycles == expected.cycles, label .. " cycle mismatch")
	assert(observed.ram == expected.ram, label .. " CPU RAM mismatch")
	assert(observed.ppu == expected.ppu, label .. " PPU memory mismatch")
	assert(observed.select == expected.select, label .. " MMC3 select mismatch")
	for i = 1, 8 do assert(observed.registers[i] == expected.registers[i], label .. " MMC3 register mismatch") end
	for i = 1, 4 do
		assert(observed.banks[i] == expected.banks[i], label .. " PRG bank mapping mismatch")
		assert(observed.mapped_bytes[i] == expected.mapped_bytes[i], label .. " mapped PRG byte mismatch")
	end
	return observed
end

local watched = {}
local function add_watch(address, label)
	if watched[address] == nil then watched[address] = label end
end
for x = 0, 0x7E do
	add_watch(0x0300 + x, "operand_0300")
	add_watch(0x0700 + x, "operand_0700")
	add_watch(0x0780 + x, "operand_0780")
end
for x = 0xFA, 0xFF do
	add_watch(0x0300 + x, "operand_0300")
	add_watch(0x0700 + x, "operand_0700")
	local address = 0x0780 + x
	add_watch(address, "operand_0780_virtual")
	add_watch(physical_ram(address), "operand_0780_mirror")
end
for _, address in ipairs({0x001B, 0x00E1, 0x00E2, 0x00E3, 0x0441, 0x05FC}) do
	add_watch(address, "rng_route_context")
end

local write_window = nil
local write_repeat = nil
local target_pass = 0
local writes_count_by_pass = {0, 0}
local write_sequence = 0
local seen_callback = {}
local known_ram = {}

local function write_file()
	if target_pass == 1 and write_window ~= nil then return write_window end
	if target_pass == 2 and write_repeat ~= nil then return write_repeat end
	return nil
end

local function on_ram_write(address, _, new_value)
	local pc = 0
	pcall(function() pc = memory.getregister("pc") end)
	local value = type(new_value) == "number" and new_value or byte(address)
	local physical = physical_ram(address)
	local old_value = known_ram[physical]
	local emulator_frame, relative, absolute = timing()
	local key = tostring(absolute) .. ":" .. tostring(pc) .. ":" .. tostring(physical) .. ":" .. tostring(value)
	if seen_callback[key] then return end
	seen_callback[key] = true
	local r0, r1, r2, r3 = prg_map()
	local writer = write_file()
	assert(writer ~= nil, "operand write hook fired outside a repeated trace window")
	writer:write(csv({write_sequence, source_frame, emulator_frame, relative, absolute,
		hex(pc, 4), pc_bank(pc), hex(address, 4), hex(physical, 4),
		hex(old_value or -1, 2), hex(value, 2), watched[address] or "alias"}) .. "\n")
	write_sequence = write_sequence + 1
	known_ram[physical] = value
	writes_count_by_pass[target_pass] = writes_count_by_pass[target_pass] + 1
end

local CALLS_HEADER = "sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,cpu_pc,pc_prg_bank,p_incoming,carry_in,mode_001b,e1_before,e2_before,e3_before,x_after_ldx,addr_0300,ram_0300,tracked_0300,addr_0700,ram_0700,tracked_0700,addr_0780_virtual,addr_0780_physical,ram_0780_virtual,ram_0780_physical,ram_0780_tracked,e1_after,e2_after,e3_after"
local calls_all = output("c9c5_calls.csv", CALLS_HEADER)
local calls_window = nil
local calls_repeat = nil
local call_sequence = 0
local window_call_count = 0
local current_call = nil
local target_hooks_attached = false

local function active_calls_file()
	if target_pass == 0 then return calls_all end
	if target_pass == 1 then return calls_window end
	return calls_repeat
end

local function begin_c9c5_call()
	local e1, e2, e3 = byte(0x00E1), byte(0x00E2), byte(0x00E3)
	local p = reg("p")
	local emulator_frame, relative, absolute = timing()
	current_call = {
		sequence=call_sequence, frame=source_frame, emulator_frame=emulator_frame,
		cycle=absolute, relative=relative, e1=e1, e2=e2, e3=e3,
		p=p, mode=byte(0x001B), x=-1,
		addr0300=-1, value0300=-1, tracked0300=-1,
		addr0700=-1, value0700=-1, tracked0700=-1,
		addr0780v=-1, addr0780p=-1, value0780v=-1, value0780p=-1, tracked0780=-1,
	}
end

local function record_operand(address)
	if current_call == nil then return end
	local x = reg("x")
	local value = byte(address)
	local physical = physical_ram(address)
	local tracked = known_ram[physical]
	if address == 0x0300 + current_call.e1 then
		current_call.x = x
		current_call.addr0300 = address
		current_call.value0300 = value
		current_call.tracked0300 = tracked or -1
	elseif address == 0x0700 + current_call.e1 then
		current_call.addr0700 = address
		current_call.value0700 = value
		current_call.tracked0700 = tracked or -1
	elseif address == 0x0780 + current_call.e1 then
		current_call.addr0780v = address
		current_call.addr0780p = physical
		current_call.value0780v = value
		current_call.value0780p = byte(physical)
		current_call.tracked0780 = known_ram[physical] or -1
	end
end

local function finish_c9c5_call()
	if current_call == nil then return end
	current_call.e1_after = byte(0x00E1)
	current_call.e2_after = byte(0x00E2)
	current_call.e3_after = byte(0x00E3)
	local writer = active_calls_file()
	writer:write(csv({current_call.sequence, current_call.frame, current_call.emulator_frame,
		current_call.relative, current_call.cycle, "$C9C5", 30, hex(current_call.p, 2),
		current_call.p >= 0 and current_call.p % 2 or -1, hex(current_call.mode, 2),
		hex(current_call.e1, 2), hex(current_call.e2, 2), hex(current_call.e3, 2),
		hex(current_call.x, 2), hex(current_call.addr0300, 4), hex(current_call.value0300, 2),
		hex(current_call.tracked0300, 2), hex(current_call.addr0700, 4), hex(current_call.value0700, 2),
		hex(current_call.tracked0700, 2), hex(current_call.addr0780v, 4), hex(current_call.addr0780p, 4),
		hex(current_call.value0780v, 2), hex(current_call.value0780p, 2), hex(current_call.tracked0780, 2),
		hex(current_call.e1_after, 2), hex(current_call.e2_after, 2), hex(current_call.e3_after, 2)}) .. "\n")
	call_sequence = call_sequence + 1
	if target_pass ~= 0 then window_call_count = window_call_count + 1 end
	current_call = nil
end

local function progress(label)
	if write_window ~= nil then write_window:flush() end
	if write_repeat ~= nil then write_repeat:flush() end
	if calls_all ~= nil then calls_all:flush() end
	if calls_window ~= nil then calls_window:flush() end
	if calls_repeat ~= nil then calls_repeat:flush() end
	metadata:flush()
	local file = assert(io.open(OUT .. "/progress.txt", "w"))
	file:write(label .. "\n")
	file:close()
end

local function log_entry()
	begin_c9c5_call()
	local emulator_frame, relative, absolute = timing()
	current_call.emulator_frame = emulator_frame
	current_call.relative = relative
	current_call.cycle = absolute
end

local startup_movie_mode = "unavailable"
pcall(function() startup_movie_mode = tostring(movie.mode()) end)
if startup_movie_mode ~= "nil" then pcall(movie.stop) end
assert(tostring(movie.mode()) == "nil", "could not stop FCEUX startup movie before replay")
local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "FCEUX power-on failed: " .. tostring(power_error))
assert(tostring(movie.mode()) == "nil", "movie playback reactivated after power-on")
assert(type(debugger) == "table" and type(debugger.getcyclescount) == "function", "FCEUX cycle counter unavailable")
if type(debugger.resetcyclescount) == "function" then pcall(debugger.resetcyclescount) end
metadata:write("startup_movie_mode=" .. startup_movie_mode .. "\n")
metadata:write("cycle_counter_available=true\npoweron_success=true\n")
metadata:write("checkpoint_frame=" .. CHECKPOINT_FRAME .. "\ncheckpoint_kind=anonymous in-memory save-state\n")
metadata:write("checkpoint_signature=frame/cycles + all 2 KiB CPU RAM + all 16 KiB PPU memory + seeded MMC3 map + mapped PRG bytes\n")
metadata:write("pre_checkpoint_operand_writers=not traced before frame 7394; checkpoint operand bytes are snapshotted\n")
metadata:flush()

pcall(emu.speedmode, "turbo")
local function refresh_known_values()
	for address in pairs(watched) do
		local physical = physical_ram(address)
		known_ram[physical] = byte(physical)
	end
end

progress("warmup:starting")
for frame = 0, CHECKPOINT_FRAME do
	source_frame = frame
	joypad.set(1, inputs[frame])
	frame_cycle_start = debugger.getcyclescount()
	emu.frameadvance()
	if frame % 600 == 0 or frame == CHECKPOINT_FRAME then progress("warmup:" .. tostring(frame)) end
end

-- The same-route state_index.csv at frame 7393 records select $07 and R0-R7
-- = 00 2E EA 6B 7A 7B 00 02. Seed the Lua mirror from that independent
-- end-of-frame snapshot; validate the PRG windows with mapped bytes.
mmc3_select = 0x07
mmc3[1], mmc3[2], mmc3[3], mmc3[4] = 0x00, 0x2E, 0xEA, 0x6B
mmc3[5], mmc3[6], mmc3[7], mmc3[8] = 0x7A, 0x7B, 0x00, 0x02
local checkpoint = snapshot_signature()
assert(checkpoint.banks[1] == 0 and checkpoint.banks[2] == 2 and checkpoint.banks[3] == 30 and checkpoint.banks[4] == 31,
	"frame-7393 PRG map differs from same-route state index")
assert(checkpoint.mapped_bytes[1] == 165 and checkpoint.mapped_bytes[2] == 169 and checkpoint.mapped_bytes[3] == 170 and checkpoint.mapped_bytes[4] == 255,
	"frame-7393 mapped PRG bytes differ from same-route PRG map")
local save_state = savestate.create()
assert(save_state ~= nil, "FCEUX could not create anonymous in-memory state")
local save_ok, save_error = pcall(savestate.save, save_state)
assert(save_ok, "FCEUX failed to save in-memory checkpoint: " .. tostring(save_error))
local persist_ok, persist_error = pcall(savestate.persist, save_state)
assert(persist_ok, "FCEUX failed to keep in-memory checkpoint for repeated loads: " .. tostring(persist_error))
assert(checkpoint.frame == CHECKPOINT_FRAME, "checkpoint frame counter does not match requested source frame")
metadata:write("checkpoint_source_frame=" .. CHECKPOINT_FRAME .. "\n")
metadata:write("checkpoint_emulator_frame=" .. checkpoint.frame .. "\ncheckpoint_cpu_cycles=" .. checkpoint.cycles .. "\n")
metadata:write("checkpoint_mmc3_select=$" .. string.format("%02X", checkpoint.select) .. "\n")
metadata:write("checkpoint_prg_banks=" .. table.concat(checkpoint.banks, ",") .. "\n")
metadata:write("checkpoint_prg_bytes=" .. table.concat(checkpoint.mapped_bytes, ",") .. "\n")
metadata:write("checkpoint_mmc3_seed=select $07 and R0-R7 00 2E EA 6B 7A 7B 00 02 from same-route state_index frame 7393; full CPU/PPU state signatures checked after each load\n")
metadata:write("checkpoint_ram_sha256=not emitted by Lua; full RAM bytes are compared in memory after both loads\n")
metadata:write("checkpoint_ppu_sha256=not emitted by Lua; full PPU memory bytes are compared in memory after both loads\n")
metadata:flush()
refresh_known_values()
local checkpoint_cells = output("checkpoint_operand_cells.csv", "x,ram_001b,e1,e2,e3,operand_name,requested_cpu_address,physical_ram_address,requested_value,physical_value")
for x = 0xFA, 0xFF do
	for _, operand in ipairs({{"ram_0300", 0x0300 + x}, {"ram_0700", 0x0700 + x}, {"ram_0780", 0x0780 + x}}) do
		local requested, physical = operand[2], physical_ram(operand[2])
		checkpoint_cells:write(csv({hex(x, 2), hex(byte(0x001B), 2), hex(byte(0x00E1), 2),
			hex(byte(0x00E2), 2), hex(byte(0x00E3), 2), operand[1], hex(requested, 4),
			hex(physical, 4), hex(byte(requested), 2), hex(byte(physical), 2)}) .. "\n")
	end
end
for x = 0, 0x7E do
	for _, operand in ipairs({{"ram_0300", 0x0300 + x}, {"ram_0700", 0x0700 + x}, {"ram_0780", 0x0780 + x}}) do
		local requested, physical = operand[2], physical_ram(operand[2])
		checkpoint_cells:write(csv({hex(x, 2), hex(byte(0x001B), 2), hex(byte(0x00E1), 2),
			hex(byte(0x00E2), 2), hex(byte(0x00E3), 2), operand[1], hex(requested, 4),
			hex(physical, 4), hex(byte(requested), 2), hex(byte(physical), 2)}) .. "\n")
	end
end
checkpoint_cells:flush(); checkpoint_cells:close()

local function attach_target_hooks()
	if target_hooks_attached then return end
	memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
	memory.registerwrite(0x8001, 1, function(_, _, value)
		mmc3[(mmc3_select % 8) + 1] = value or 0
	end)
	for address in pairs(watched) do
		local physical = physical_ram(address)
		known_ram[physical] = byte(physical)
		local target = address
		memory.registerwrite(target, 1, function(a, b, value) on_ram_write(a or target, b, value) end)
	end
	memory.registerexec(0xC9C5, log_entry)
	memory.registerexec(0xC9C8, function()
		if current_call == nil then return end
		local x = reg("x")
		current_call.x = x
		if x ~= current_call.e1 then current_call.x_mismatch = true end
		record_operand(0x0300 + current_call.e1)
	end)
	memory.registerexec(0xC9CB, function()
		if current_call ~= nil then record_operand(0x0700 + current_call.e1) end
	end)
	memory.registerexec(0xC9DC, function()
		if current_call ~= nil then record_operand(0x0780 + current_call.e1) end
	end)
	memory.registerexec(0xC9E8, finish_c9c5_call)
	target_hooks_attached = true
end

local function detach_target_hooks()
	if not target_hooks_attached then return end
	pcall(memory.registerwrite, 0x8000, 1, nil)
	pcall(memory.registerwrite, 0x8001, 1, nil)
	for address in pairs(watched) do pcall(memory.registerwrite, address, 1, nil) end
	for _, address in ipairs({0xC9C5, 0xC9C8, 0xC9CB, 0xC9DC, 0xC9E8}) do pcall(memory.registerexec, address, nil) end
	target_hooks_attached = false
end

local function restore_known_values()
	refresh_known_values()
end

local function close_window_files()
	if write_window then write_window:flush(); write_window:close(); write_window = nil end
	if write_repeat then write_repeat:flush(); write_repeat:close(); write_repeat = nil end
	if calls_window then calls_window:flush(); calls_window:close(); calls_window = nil end
	if calls_repeat then calls_repeat:flush(); calls_repeat:close(); calls_repeat = nil end
end

local function run_window(pass_index)
	local load_ok, load_error = pcall(savestate.load, save_state)
	assert(load_ok, "FCEUX failed to load checkpoint for pass " .. pass_index .. ": " .. tostring(load_error))
	restore_mmc3(checkpoint)
	verify_signature(checkpoint, "pass " .. pass_index)
	restore_known_values()
	seen_callback = {}
	call_sequence = 0
	window_call_count = 0
	write_sequence = 0
	target_pass = pass_index
	writes_count_by_pass[pass_index] = 0
	attach_target_hooks()
	local suffix = pass_index == 1 and "" or "_repeat"
	if pass_index == 1 then
		write_window = output("operand_writes_window.csv", "sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,cpu_pc,pc_prg_bank,cpu_address,physical_ram_address,old_value,new_value,region")
		calls_window = output("c9c5_calls_window.csv", CALLS_HEADER)
	else
		write_repeat = output("operand_writes_window_repeat.csv", "sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,cpu_pc,pc_prg_bank,cpu_address,physical_ram_address,old_value,new_value,region")
		calls_repeat = output("c9c5_calls_window_repeat.csv", CALLS_HEADER)
	end
	local start_snapshot = output("window_start" .. suffix .. ".bin")
	start_snapshot:write(checkpoint.ram:sub(1, #checkpoint.ram))
	start_snapshot:close()
	for frame = FIRST_WINDOW_FRAME, LAST_WINDOW_FRAME do
		source_frame = frame
		joypad.set(1, inputs[frame])
		frame_cycle_start = debugger.getcyclescount()
		emu.frameadvance()
		if frame % 30 == 0 or frame == LAST_WINDOW_FRAME then progress("pass" .. pass_index .. ":" .. tostring(frame)) end
	end
	assert(current_call == nil, "C9C5 trace ended mid-call")
	local final = snapshot_signature()
	local end_snapshot = output("window_end" .. suffix .. ".bin")
	end_snapshot:write(final.ram)
	end_snapshot:close()
	metadata:write("pass_" .. pass_index .. "_checkpoint_verified=true\n")
	metadata:write("pass_" .. pass_index .. "_c9c5_call_count=" .. window_call_count .. "\n")
	metadata:write("pass_" .. pass_index .. "_operand_write_count=" .. writes_count_by_pass[pass_index] .. "\n")
	metadata:write("pass_" .. pass_index .. "_end_frame=" .. final.frame .. "\npass_" .. pass_index .. "_end_cycles=" .. final.cycles .. "\n")
	assert(window_call_count == 133, "pass " .. pass_index .. " expected 133 C9C5 calls, got " .. window_call_count)
	metadata:flush()
	close_window_files()
	detach_target_hooks()
	return final
end

local final_pass_1 = run_window(1)
local final_pass_2 = run_window(2)
assert(final_pass_1.frame == final_pass_2.frame and final_pass_1.cycles == final_pass_2.cycles, "repeated window frame/cycle mismatch")
assert(final_pass_1.ram == final_pass_2.ram and final_pass_1.ppu == final_pass_2.ppu, "repeated window RAM/PPU mismatch")
assert(final_pass_1.select == final_pass_2.select, "repeated window MMC3 select mismatch")
for i = 1, 8 do assert(final_pass_1.registers[i] == final_pass_2.registers[i], "repeated window MMC3 register mismatch") end
for i = 1, 4 do assert(final_pass_1.banks[i] == final_pass_2.banks[i], "repeated window PRG mapping mismatch") end
for i = 1, 4 do assert(final_pass_1.mapped_bytes[i] == final_pass_2.mapped_bytes[i], "repeated window mapped PRG byte mismatch") end

metadata:write("pass_1_and_2_final_signatures_match=true\n")
metadata:write("replay_passes=2\n")
metadata:write("expected_c9c5_count=133\n")
metadata:write("total_c9c5_calls_logged=" .. call_sequence .. " (pass 2 counter)\n")
metadata:write("pre_checkpoint_operand_writers=not_traced_before_frame_7394; checkpoint_operand_cells=399\n")
metadata:write("pass_1_operand_writes=" .. writes_count_by_pass[1] .. "\n")
metadata:write("pass_2_operand_writes=" .. writes_count_by_pass[2] .. "\n")
metadata:write("completion_marker=pass2:8593\n")
metadata:flush()
progress("pass2:8593")
metadata:close(); metadata = nil
calls_all:flush(); calls_all:close(); calls_all = nil

pcall(memory.registerwrite, 0x8000, 1, nil)
pcall(memory.registerwrite, 0x8001, 1, nil)
pcall(os.exit)

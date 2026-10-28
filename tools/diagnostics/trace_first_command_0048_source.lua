-- Muted, two-pass trace of the route source that selects record row $06 at $0048.
-- Diagnostic only. The checkpoint is produced by replaying the pinned input prefix.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OUT = assert(os.getenv("CT2_0048_TRACE_OUTPUT_DIR"), "missing output directory")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local CHECKPOINT_FRAME, FIRST_TRACE_FRAME, LAST_FRAME = 8100, 8101, 8135

os.execute("mkdir -p " .. string.format("%q", OUT))

local function read_inputs(path, route_format)
	local result, first = {}, true
	local file = assert(io.open(path, "r"), "missing input file " .. path)
	for line in file:lines() do
		line = line:gsub("\r$", "")
		if first then first = false else
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
for frame, value in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = value end
for frame = 0, LAST_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local function output(name, header)
	local file = assert(io.open(OUT .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end

local function byte(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return type(value) == "number" and value or 0
end

local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return type(value) == "number" and value or -1
end

local function cycles()
	local value = -1
	pcall(function() value = debugger.getcyclescount() end)
	return type(value) == "number" and value or -1
end

local function hx(value, width)
	if type(value) ~= "number" or value < 0 then return "" end
	return string.format(width == 2 and "$%02X" or "$%04X", value)
end

local function csv(values)
	local fields = {}
	for index, value in ipairs(values) do fields[index] = tostring(value == nil and "" or value):gsub(",", ";") end
	return table.concat(fields, ",")
end

local function memory_range(first, length)
	local data = nil
	local ok = pcall(function() data = memory.readbyterange(first, length) end)
	if ok and type(data) == "string" and #data == length then return data end
	local values = {}
	for address = first, first + length - 1 do values[#values + 1] = string.char(byte(address)) end
	return table.concat(values)
end

local mmc3_select = 0
local mmc3 = {0, 2, 4, 5, 6, 7, 0, 1}
local mmc3_mirroring, mmc3_ram_control = -1, -1
local mmc3_irq_latch, mmc3_irq_enable, mmc3_irq_reload_pending = -1, 0, 0

local function copy_array(values)
	local result = {}
	for index, value in ipairs(values) do result[index] = value end
	return result
end

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

local function capture_signature()
	local ppu_mem = ppu.readbyterange(0x0000, 0x4000)
	assert(type(ppu_mem) == "string" and #ppu_mem == 0x4000, "could not read all PPU memory")
	local banks = {prg_map()}
	return {
		frame=emu.framecount(), cycles=cycles(), pc=reg("pc"), ram=memory_range(0, 0x800), ppu=ppu_mem,
		select=mmc3_select, registers=copy_array(mmc3), mirroring=mmc3_mirroring,
		ram_control=mmc3_ram_control, irq_latch=mmc3_irq_latch, irq_enable=mmc3_irq_enable,
		irq_reload_pending=mmc3_irq_reload_pending, banks=banks,
		mapped_bytes={byte(0x8000),byte(0xA000),byte(0xC000),byte(0xE000)},
	}
end

local function restore_mapper(signature)
	mmc3_select = signature.select
	mmc3 = copy_array(signature.registers)
	mmc3_mirroring = signature.mirroring
	mmc3_ram_control = signature.ram_control
	mmc3_irq_latch = signature.irq_latch
	mmc3_irq_enable = signature.irq_enable
	mmc3_irq_reload_pending = signature.irq_reload_pending
end

local function verify_signature(expected, label)
	local actual = capture_signature()
	assert(actual.frame == expected.frame, label .. " frame mismatch")
	assert(actual.cycles == expected.cycles, label .. " cycle mismatch")
	assert(actual.pc == expected.pc, label .. " PC mismatch")
	assert(actual.ram == expected.ram, label .. " RAM mismatch")
	assert(actual.ppu == expected.ppu, label .. " PPU-memory mismatch")
	assert(actual.select == expected.select, label .. " MMC3 select mismatch")
	for index = 1, 8 do assert(actual.registers[index] == expected.registers[index], label .. " MMC3 register mismatch") end
	for index = 1, 4 do
		assert(actual.banks[index] == expected.banks[index], label .. " PRG map mismatch")
		assert(actual.mapped_bytes[index] == expected.mapped_bytes[index], label .. " mapped PRG byte mismatch")
	end
end

local metadata = output("metadata.txt")
local startup_mode = "unavailable"
pcall(function() startup_mode = tostring(movie.mode()); if movie.mode() ~= nil then pcall(movie.stop) end end)
if type(movie.active) == "function" then local active = false; pcall(function() active = movie.active() end); if active then pcall(movie.stop) end end
assert(tostring(movie.mode()) == "nil", "could not disable FCEUX startup movie")
assert(type(debugger) == "table" and type(debugger.getcyclescount) == "function", "CPU cycle counter unavailable")
assert(type(memory.registerwrite) == "function", "FCEUX RAM write hooks unavailable")

metadata:write("purpose=trace source writer of zero-page $0048=$06 before the $B060-to-$0638 row copy\n")
metadata:write("input_prefix=exact opening plus fresh KICK OFF post-title timeline\n")
metadata:write("checkpoint=anonymous in-memory state at source frame 8100; expected $0048=$1A and $0638=$26\n")
metadata:write("instrumented_frames=" .. FIRST_TRACE_FRAME .. "-" .. LAST_FRAME .. "; audio muted; no numbered slots or runtime edits\n")
metadata:flush()

memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value) mmc3[(mmc3_select % 8) + 1] = value or 0 end)
memory.registerwrite(0xA000, 1, function(_, _, value) mmc3_mirroring = value or -1 end)
memory.registerwrite(0xA001, 1, function(_, _, value) mmc3_ram_control = value or -1 end)
memory.registerwrite(0xC000, 1, function(_, _, value) mmc3_irq_latch = value or -1 end)
memory.registerwrite(0xC001, 1, function() mmc3_irq_reload_pending = 1 end)
memory.registerwrite(0xE000, 1, function() mmc3_irq_enable = 0 end)
memory.registerwrite(0xE001, 1, function() mmc3_irq_enable = 1 end)

local current_source_frame, frame_cycle_start, active_pass = -1, -1, 0
local current_input, writes, frames = {}, nil, nil
local last_0048 = byte(0x0048)
local function button_string(pad)
	local names = {"up","down","left","right","A","B","start","select"}
	local values = {}
	for _, name in ipairs(names) do if pad[name] then values[#values + 1] = name end end
	return #values == 0 and "none" or table.concat(values, "+")
end
local function stack_window(sp)
	local values = {}
	for offset = 1, 12 do values[#values + 1] = string.format("%02X", byte(0x0100 + ((sp + offset) % 0x100))) end
	return table.concat(values, " ")
end

local context_addresses = {0x0048,0x0049,0x004A,0x004B,0x0025,0x00E6,0x00E7,0x00E2,0x001B,
	0x0516,0x0517,0x0518,0x0519,0x052A,0x05FB,0x05FC,0x0629,0x0638,0x0639,
	0x0001,0x0005,0x0009,0x0011,0x0015}
local function context_string()
	local values = {}
	for _, address in ipairs(context_addresses) do values[#values + 1] = string.format("%04X:%02X", address, byte(address)) end
	return table.concat(values, " ")
end

local function write_hook(_, _, new_value)
	if current_source_frame < 0 or writes == nil then last_0048 = type(new_value) == "number" and new_value or byte(0x0048); return end
	local pc, sp = reg("pc"), reg("s")
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local lo = byte(0x0100 + ((sp + 1) % 0x100))
	local hi = byte(0x0100 + ((sp + 2) % 0x100))
	local value = type(new_value) == "number" and new_value or byte(0x0048)
	local banks = {prg_map()}
	writes:write(csv({active_pass,current_source_frame,emu.framecount(),relative,absolute,hx(pc,4),hx(pc_bank(pc),2),
		table.concat(banks,":"),hx(last_0048,2),hx(value,2),hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(sp,2),hx(lo + hi * 256,4),button_string(current_input),context_string(),stack_window(sp)}) .. "\n")
	last_0048 = value
end

local function make_pass_files(pass_index)
	active_pass = pass_index
	local suffix = pass_index == 1 and "" or "_repeat"
	writes = output("ram_0048_writes" .. suffix .. ".csv", "pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc_after_write,pc_prg_bank,prg_banks,old_value,new_value,a,x,y,p,sp,stack_return,input,ram_context,stack_window")
	frames = output("frame_context" .. suffix .. ".csv", "pass,source_frame,cycle_end,ram_0048,ram_0049,ram_0638,ram_0025,ram_00e2,ram_05fc")
	last_0048 = byte(0x0048)
end

local function close_pass(pass_index)
	writes:flush(); frames:flush(); writes:close(); frames:close(); writes, frames = nil, nil
	local signature = capture_signature()
	local suffix = pass_index == 1 and "" or "_repeat"
	local file = assert(io.open(OUT .. "/end_state" .. suffix .. ".bin", "wb")); file:write(signature.ram); file:close()
	return signature
end

local function run_pass(pass_index, checkpoint, save_state)
	local ok, err = pcall(savestate.load, save_state)
	assert(ok, "anonymous checkpoint load failed: " .. tostring(err))
	restore_mapper(checkpoint)
	verify_signature(checkpoint, "pass " .. pass_index .. " checkpoint")
	make_pass_files(pass_index)
	local file = assert(io.open(OUT .. "/start_state" .. (pass_index == 1 and "" or "_repeat") .. ".bin", "wb")); file:write(memory_range(0,0x800)); file:close()
	for frame = FIRST_TRACE_FRAME, LAST_FRAME do
		current_source_frame = frame
		current_input = inputs[frame]
		joypad.set(1, current_input)
		frame_cycle_start = cycles()
		emu.frameadvance()
		frames:write(csv({pass_index,frame,cycles(),hx(byte(0x0048),2),hx(byte(0x0049),2),hx(byte(0x0638),2),hx(byte(0x0025),2),hx(byte(0x00E2),2),hx(byte(0x05FC),2)}) .. "\n")
		writes:flush(); frames:flush()
		local progress = assert(io.open(OUT .. "/progress.txt", "w")); progress:write(pass_index .. ":" .. frame .. "\n"); progress:close()
	end
	return close_pass(pass_index)
end

local powered, power_error = pcall(emu.poweron)
assert(powered, "FCEUX power-on failed: " .. tostring(power_error))
pcall(debugger.resetcyclescount)
pcall(emu.speedmode, "turbo")
for frame = 0, CHECKPOINT_FRAME do
	current_source_frame = frame
	joypad.set(1, inputs[frame])
	frame_cycle_start = cycles()
	emu.frameadvance()
	if frame % 600 == 0 or frame == CHECKPOINT_FRAME then
		local progress = assert(io.open(OUT .. "/progress.txt", "w")); progress:write("warmup:" .. frame .. "\n"); progress:close()
	end
end
current_source_frame = -1
local checkpoint = capture_signature()
assert(checkpoint.frame == CHECKPOINT_FRAME, "checkpoint source frame mismatch")
assert(byte(0x0048) == 0x1A, "frame-8100 checkpoint does not retain $0048=$1A")
assert(byte(0x0638) == 0x26, "frame-8100 checkpoint does not retain $0638=$26")
local save_state = savestate.create()
assert(save_state ~= nil, "could not allocate anonymous in-memory checkpoint")
local saved, save_error = pcall(savestate.save, save_state)
assert(saved, "anonymous checkpoint save failed: " .. tostring(save_error))
local persist_ok, persist_error = pcall(savestate.persist, save_state)
assert(persist_ok, "could not keep anonymous checkpoint for repeated loads: " .. tostring(persist_error))
metadata:write("startup_movie_mode=" .. startup_mode .. "\n")
metadata:write("checkpoint_frame=" .. checkpoint.frame .. "\ncheckpoint_cycles=" .. checkpoint.cycles .. "\ncheckpoint_pc=" .. hx(checkpoint.pc,4) .. "\n")
metadata:write("checkpoint_0048=" .. hx(byte(0x0048),2) .. "\ncheckpoint_0049=" .. hx(byte(0x0049),2) .. "\ncheckpoint_0638=" .. hx(byte(0x0638),2) .. "\n")
metadata:write("checkpoint_mmc3_select=" .. hx(checkpoint.select,2) .. "\ncheckpoint_prg_banks=" .. table.concat(checkpoint.banks,",") .. "\n")
metadata:write("replays=2; each pass loads this in-memory checkpoint and applies frames " .. FIRST_TRACE_FRAME .. "-" .. LAST_FRAME .. "\n")
metadata:flush()

memory.registerwrite(0x0048, 1, write_hook)
local final1 = run_pass(1, checkpoint, save_state)
local final2 = run_pass(2, checkpoint, save_state)
assert(final1.frame == final2.frame and final1.cycles == final2.cycles, "final frame/cycle mismatch")
assert(final1.ram == final2.ram and final1.ppu == final2.ppu, "final RAM/PPU mismatch")
assert(final1.select == final2.select, "final MMC3 select mismatch")
for index = 1, 8 do assert(final1.registers[index] == final2.registers[index], "final MMC3 register mismatch") end
for index = 1, 4 do assert(final1.banks[index] == final2.banks[index], "final PRG bank mismatch") end
metadata:write("complete=true\nfinal_frame=" .. final1.frame .. "\nfinal_cycles=" .. final1.cycles .. "\npass_1_and_2_final_signatures_match=true\n")
metadata:flush(); metadata:close()
os.exit()

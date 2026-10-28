-- Muted, two-pass cold-start trace for the first-command $0638 producer.
-- Diagnostic only. Replays the pinned opening and post-title input timelines.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OUT = assert(os.getenv("CT2_0638_TRACE_OUTPUT_DIR"), "missing output directory")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local CHECKPOINT_FRAME, FIRST_TRACE_FRAME, LAST_FRAME = 8220, 8221, 8280

os.execute("mkdir -p " .. string.format("%q", OUT))

local function read_inputs(path, route_format)
	local result, first = {}, true
	local file = assert(io.open(path, "r"), "missing input file " .. path)
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
	for index, value in ipairs(values) do
		fields[index] = tostring(value == nil and "" or value):gsub(",", ";")
	end
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
		ram_control=mmc3_ram_control, irq_latch=mmc3_irq_latch,
		irq_enable=mmc3_irq_enable, irq_reload_pending=mmc3_irq_reload_pending,
		banks=banks, mapped_bytes={byte(0x8000),byte(0xA000),byte(0xC000),byte(0xE000)},
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
local rom_md5 = "unavailable through FCEUX Lua"
pcall(function() rom_md5 = rom.gethash("md5") or rom_md5 end)
assert(type(debugger) == "table" and type(debugger.getcyclescount) == "function", "CPU cycle counter unavailable")
assert(type(memory.registerwrite) == "function" and type(memory.registerexec) == "function", "FCEUX memory hooks unavailable")
metadata:write("purpose=muted ROM-source ownership trace for the $0638 transition before first-command scenario $36 FD 00\n")
metadata:write("source_inputs=0-" .. LAST_FRAME .. "; exact opening plus post-title input timelines\n")
metadata:write("instrumented_frames=" .. FIRST_TRACE_FRAME .. "-" .. LAST_FRAME .. "; warmup uses same input through the verified frame-8220 boundary\n")
metadata:write("rom_md5=" .. tostring(rom_md5) .. "; SHA-256 checked by Python runner\n")
metadata:write("candidate_writer_pcs=fixed:$D8D5,$DA34,$DD69,$DD7C; bank-$1A:$91BC; bank-$1C:$8A1C; bank-$1F:$E070,$E6C1\n")
metadata:write("capture=RAM writes, candidate execute/callee hooks, and focused record-copy source context after checkpoint; audio muted; no screenshots, numbered slots, or runtime edits\n")
metadata:write("state=anonymous FCEUX checkpoint at source frame 8220; the 60-frame transition interval is replayed twice\n")
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
local writes, candidates, callees, frames, contexts = nil, nil, nil, nil, nil
local last_0638 = byte(0x0638)
local write_sequence, exec_sequence = 0, 0

local function stack_window(sp)
	local values = {}
	for offset = 1, 12 do values[#values + 1] = string.format("%02X", byte(0x0100 + ((sp + offset) % 0x100))) end
	return table.concat(values, " ")
end

local function state_context()
	return {
		byte(0x0624),byte(0x05FC),byte(0x0635),byte(0x0637),byte(0x0441),
		byte(0x05FB),byte(0x00E2),byte(0x052A),byte(0x0517),byte(0x0518),byte(0x005D),
		byte(0x005E),byte(0x003A),byte(0x0034),byte(0x0035),
	}
end

local writer_specs = {
	{0xD8D5,30,"fixed_D8D5"},{0xDA34,30,"fixed_DA34"},{0xDD69,30,"fixed_DD69"},
	{0xDD7C,30,"fixed_DD7C"},{0x91BC,0x1A,"bank1A_91BC"},{0x8A1C,0x1C,"bank1C_8A1C"},
	{0xE070,0x1F,"bank1F_E070"},{0xE6C1,0x1F,"bank1F_E6C1"},
}

local function log_candidate(spec)
	if current_source_frame < 0 or candidates == nil then return end
	local pc = reg("pc")
	local bank = pc_bank(pc)
	if bank ~= spec[2] then return end
	local sp = reg("s")
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local lo = byte(0x0100 + ((sp + 1) % 0x100))
	local hi = byte(0x0100 + ((sp + 2) % 0x100))
	local values = {write_sequence,active_pass,current_source_frame,emu.framecount(),relative,absolute,
		spec[3],hx(pc,4),hx(bank,2),hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(sp,2),
		hx(lo + hi * 256,4),stack_window(sp)}
	for _, value in ipairs(state_context()) do values[#values + 1] = hx(value,2) end
	candidates:write(csv(values) .. "\n")
	exec_sequence = exec_sequence + 1
end

local function log_callee(label)
	if current_source_frame < 0 or callees == nil then return end
	local pc = reg("pc")
	local sp = reg("s")
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local lo = byte(0x0100 + ((sp + 1) % 0x100))
	local hi = byte(0x0100 + ((sp + 2) % 0x100))
	local values = {exec_sequence,active_pass,current_source_frame,emu.framecount(),relative,absolute,label,hx(pc,4),hx(pc_bank(pc),2),hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(sp,2),hx(lo + hi * 256,4),stack_window(sp)}
	for _, value in ipairs(state_context()) do values[#values + 1] = hx(value,2) end
	callees:write(csv(values) .. "\n")
	exec_sequence = exec_sequence + 1
end

local function log_context(label)
	if current_source_frame < 0 or contexts == nil then return end
	local pc, sp = reg("pc"), reg("s")
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local lo = byte(0x0100 + ((sp + 1) % 0x100))
	local hi = byte(0x0100 + ((sp + 2) % 0x100))
	local banks = {prg_map()}
	local bytes, table_data = {}, {}
	for address = 0x062A, 0x0639 do bytes[#bytes + 1] = hx(byte(address),2) end
	local table_ptr = 0xB000 + byte(0x0048) * 16
	for offset = 0, 15 do table_data[#table_data + 1] = hx(byte(table_ptr + offset),2) end
	contexts:write(csv({active_pass,current_source_frame,emu.framecount(),relative,absolute,label,hx(pc,4),hx(pc_bank(pc),2),
		hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(sp,2),hx(lo + hi * 256,4),
		table.concat(banks,":"),hx(mmc3_select,2),table.concat({hx(byte(0x0048),2),hx(byte(0x0049),2),hx(byte(0x00E6),2),hx(byte(0x00E7),2),hx(byte(0x0025),2),hx(byte(0x0624),2),hx(byte(0x0629),2),hx(byte(0x0441),2),hx(byte(0x05FB),2),hx(byte(0x0638),2),hx(byte(0x0639),2)}," "),
		table.concat(bytes," "),table.concat(table_data," ")}) .. "\n")
end

memory.registerwrite(0x0638, 1, function(_, _, new_value)
	if current_source_frame < 0 or writes == nil then last_0638 = type(new_value) == "number" and new_value or byte(0x0638); return end
	local value = type(new_value) == "number" and new_value or byte(0x0638)
	local pc, absolute = reg("pc"), cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local bank = pc_bank(pc)
	local context = {}
	for _, item in ipairs(state_context()) do context[#context + 1] = hx(item,2) end
	local sp = reg("s")
	writes:write(csv({write_sequence,active_pass,current_source_frame,emu.framecount(),relative,absolute,
		hx(pc,4),hx(bank,2),hx(last_0638,2),hx(value,2),hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),
		hx(reg("p"),2),hx(sp,2),table.concat(context," "),stack_window(sp)}) .. "\n")
	last_0638 = value
	write_sequence = write_sequence + 1
end)

for _, spec in ipairs(writer_specs) do
	local candidate = spec
	memory.registerexec(candidate[1], function() log_candidate(candidate) end)
end
for address, label in pairs({[0xCD7C]="$CD7C",[0xCDC9]="$CDC9",[0xCDE2]="$CDE2",[0xE6EC]="$E6EC"}) do
	memory.registerexec(address, function() log_callee(label) end)
end
local function pass_files(pass_index)
	active_pass = pass_index
	local suffix = pass_index == 1 and "" or "_repeat"
	writes = output("ram_0638_writes" .. suffix .. ".csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc_after_write,pc_prg_bank,old_value,new_value,a,x,y,p,sp,state_0624_05fc_0635_0637_0441_05fb_e2_052a_0517_0518_005d_005e_003a_0034_0035,stack_window")
	candidates = output("candidate_writer_execs" .. suffix .. ".csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,candidate,pc,prg_bank,a,x,y,p,sp,stack_return,stack_window,state_0624_05fc_0635_0637_0441_05fb_e2_052a_0517_0518_005d_005e_003a_0034_0035")
	callees = output("coordinate_callee_execs" .. suffix .. ".csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,callee,pc,prg_bank,a,x,y,p,sp,stack_return,stack_window,state_0624_05fc_0635_0637_0441_05fb_e2_052a_0517_0518_005d_005e_003a_0034_0035")
	frames = output("frame_values" .. suffix .. ".csv", "pass,source_frame,emulator_frame,cycle_end,ram_0638,ram_0624,ram_05fc,ram_0635,ram_0637,ram_0441,ram_05fb,ram_e2")
	contexts = output("source_context" .. suffix .. ".csv", "pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,event,pc,pc_prg_bank,a,x,y,p,sp,stack_return,prg_banks,mmc3_select,ram_0048_0049_e6_e7_0025_0624_0629_0441_05fb_0638_0639,ram_062a_0639,table_row_B000_plus_48_times_16")
	write_sequence, exec_sequence = 0, 0
	last_0638 = byte(0x0638)
end

local function close_files()
	writes:flush(); candidates:flush(); callees:flush(); frames:flush(); contexts:flush()
	writes:close(); candidates:close(); callees:close(); frames:close(); contexts:close()
	writes, candidates, callees, frames, contexts = nil, nil, nil, nil, nil
	return capture_signature()
end

local function close_pass(pass_index)
	local sig = close_files()
	local file = assert(io.open(OUT .. "/end_state" .. (pass_index == 1 and "" or "_repeat") .. ".bin", "wb"))
	file:write(sig.ram); file:close()
	return sig
end

local function run_pass(pass_index, checkpoint, save_state)
	local ok, err = pcall(savestate.load, save_state)
	assert(ok, "load anonymous checkpoint failed: " .. tostring(err))
	restore_mapper(checkpoint)
	verify_signature(checkpoint, "pass " .. pass_index .. " checkpoint")
	pass_files(pass_index)
	local start_ram = memory_range(0, 0x800)
	local start_file = assert(io.open(OUT .. "/start_state" .. (pass_index == 1 and "" or "_repeat") .. ".bin", "wb"))
	start_file:write(start_ram); start_file:close()
	for frame = FIRST_TRACE_FRAME, LAST_FRAME do
		current_source_frame = frame
		joypad.set(1, inputs[frame])
		frame_cycle_start = cycles()
		emu.frameadvance()
		if frame % 15 == 0 or frame == LAST_FRAME then
			local absolute = cycles()
			frames:write(csv({pass_index,frame,emu.framecount(),absolute,hx(byte(0x0638),2),hx(byte(0x0624),2),hx(byte(0x05FC),2),hx(byte(0x0635),2),hx(byte(0x0637),2),hx(byte(0x0441),2),hx(byte(0x05FB),2),hx(byte(0x00E2),2)}) .. "\n")
		end
		if frame % 15 == 0 or frame == LAST_FRAME then
			writes:flush(); candidates:flush(); callees:flush(); frames:flush()
			local progress = assert(io.open(OUT .. "/progress.txt", "w"))
			progress:write(tostring(pass_index) .. ":" .. tostring(frame) .. "\n"); progress:close()
		end
	end
	return close_pass(pass_index)
end

local startup_mode = "unavailable"
pcall(function() startup_mode = tostring(movie.mode()); if movie.mode() ~= nil then pcall(movie.stop) end end)
if type(movie.active) == "function" then
	local active = false; pcall(function() active = movie.active() end)
	if active then pcall(movie.stop) end
end
assert(tostring(movie.mode()) == "nil", "could not disable FCEUX startup movie")
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
		local progress = assert(io.open(OUT .. "/progress.txt", "w"))
		progress:write("warmup:" .. tostring(frame) .. "\n"); progress:close()
	end
end
current_source_frame = -1
local checkpoint = capture_signature()
assert(checkpoint.frame == CHECKPOINT_FRAME, "checkpoint frame differs from source frame 8220")
assert(byte(0x0638) == 0x26, "frame-8220 checkpoint does not retain $0638=$26")
local save_state = savestate.create()
assert(save_state ~= nil, "FCEUX could not allocate anonymous in-memory checkpoint")
local saved, save_error = pcall(savestate.save, save_state)
assert(saved, "FCEUX failed to save anonymous checkpoint: " .. tostring(save_error))
local persist_ok, persist_error = pcall(savestate.persist, save_state)
assert(persist_ok, "could not keep anonymous checkpoint for repeated loads: " .. tostring(persist_error))
metadata:write("startup_movie_mode=" .. startup_mode .. "\n")
metadata:write("checkpoint_source_frame=" .. CHECKPOINT_FRAME .. "\ncheckpoint_emulator_frame=" .. checkpoint.frame .. "\ncheckpoint_cycles=" .. checkpoint.cycles .. "\n")
metadata:write("checkpoint_pc=" .. hx(checkpoint.pc,4) .. "\ncheckpoint_ram_0638=" .. hx(byte(0x0638),2) .. "\n")
metadata:write("checkpoint_mmc3_select=" .. hx(checkpoint.select,2) .. "\ncheckpoint_prg_banks=" .. table.concat(checkpoint.banks,",") .. "\n")
metadata:write("checkpoint_0638=$26\nreplays=2; each pass loads and verifies the same anonymous checkpoint, then applies frames " .. FIRST_TRACE_FRAME .. "-" .. LAST_FRAME .. "\n")
metadata:flush()

-- Install the detailed copy-chain hooks only after the long deterministic warmup.
for address, label in pairs({[0x997A]="$997A record-selector caller",[0x997E]="$997E record-loader call",[0x9981]="$9981 table-copy call",[0x9AB8]="$9AB8 record-row loader",[0x9AFD]="$9AFD STA $062A,X",[0x9B07]="$9B07 selector helper"}) do
	local event_label = label
	memory.registerexec(address, function() log_context(event_label) end)
end

local final1 = run_pass(1,checkpoint,save_state)
local final2 = run_pass(2,checkpoint,save_state)
assert(final1.frame == final2.frame and final1.cycles == final2.cycles, "final frame/cycle differs between passes")
assert(final1.ram == final2.ram and final1.ppu == final2.ppu, "final RAM/PPU differs between passes")
assert(final1.select == final2.select, "final MMC3 select differs between passes")
for index = 1, 8 do assert(final1.registers[index] == final2.registers[index], "final MMC3 register differs between passes") end
for index = 1, 4 do
	assert(final1.banks[index] == final2.banks[index], "final PRG bank differs between passes")
	assert(final1.mapped_bytes[index] == final2.mapped_bytes[index], "final PRG byte differs between passes")
end
metadata:write("complete=true\npass_1_and_2_final_signatures_match=true\n")
metadata:write("final_frame=" .. final1.frame .. "\nfinal_cycles=" .. final1.cycles .. "\n")
metadata:flush(); metadata:close()
os.exit()

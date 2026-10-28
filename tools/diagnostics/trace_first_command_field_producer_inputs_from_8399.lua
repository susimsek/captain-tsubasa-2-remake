-- Muted source-RAM writer/caller trace for the first-command field packet producer.
-- Run only via run_first_command_field_producer_input_trace.py. Diagnostic only.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_FIELD_INPUT_TRACE_OUTPUT_DIR"), "missing output directory")
local FIRST_TRACE_FRAME, LAST_TRACE_FRAME = 8400, 8953
local CHECKPOINT_FRAME = FIRST_TRACE_FRAME - 1
local RAM_FIRST, RAM_LAST = 0x04A5, 0x0515
local INPUT_STATE = {
	{address=0x0034, name="$0034"},
	{address=0x0035, name="$0035"},
	{address=0x034E, name="$034E"},
	{address=0x0350, name="$0350"},
	{address=0x0366, name="$0366"},
	{address=0x0368, name="$0368"},
	{address=0x0441, name="$0441"},
	{address=0x05FB, name="$05FB"},
	{address=0x05CD, name="$05CD"},
	{address=0x05CE, name="$05CE"},
	{address=0x063D, name="$063D"},
	{address=0x0635, name="$0635"},
	{address=0x0637, name="$0637"},
	{address=0x06CE, name="$06CE"},
}
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
for frame, value in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = value end
for frame = 0, LAST_TRACE_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

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

local function bytes_hex(data)
	if type(data) ~= "string" then return "" end
	local values = {}
	for index = 1, #data do values[index] = string.format("%02X", string.byte(data, index)) end
	return table.concat(values, " ")
end

local function memory_range(first, length)
	local data = nil
	local ok = pcall(function() data = memory.readbyterange(first, length) end)
	if ok and type(data) == "string" and #data == length then return data end
	local values = {}
	for address = first, first + length - 1 do values[#values + 1] = string.char(byte(address)) end
	return table.concat(values)
end

-- Arithmetic bit helpers keep the script compatible with FCEUX's LuaJIT/Lua 5.1.
local function band(left, right)
	local result, place = 0, 1
	left, right = math.floor(left), math.floor(right)
	while left > 0 or right > 0 do
		if (left % 2) == 1 and (right % 2) == 1 then result = result + place end
		left = math.floor(left / 2)
		right = math.floor(right / 2)
		place = place * 2
	end
	return result
end

local metadata = output("metadata.txt")
local rom_md5 = "unavailable through FCEUX Lua"
pcall(function() rom_md5 = rom.gethash("md5") or rom_md5 end)
assert(type(debugger) == "table" and type(debugger.getcyclescount) == "function",
	"FCEUX CPU cycle counter unavailable")
assert(type(memory.registerwrite) == "function", "FCEUX memory write hooks unavailable")
metadata:write("purpose=muted target-ROM source writes to PPU packet RAM $04A5-$0515\n")
metadata:write("secondary_purpose=RAM writers of coordinate pointers/record bytes/$0441/$05FB/$05CE/$063D/$0635/$0637 and entries to $DB00/$DC29/$E6F2/$E6FA/$E701/$F015/$F0B5/$F114/$F159\n")
metadata:write("source_frames=" .. FIRST_TRACE_FRAME .. "-" .. LAST_TRACE_FRAME .. "\n")
metadata:write("rom_md5=" .. tostring(rom_md5) .. "\nrom_hash_verification=Python runner\n")
metadata:write("checkpoint=anonymous in-memory FCEUX save state at source frame " .. CHECKPOINT_FRAME .. "; loaded twice and signature-checked\n")
metadata:write("capture=CPU RAM writes only; no screenshots, audio, PPU dumps, numbered slots or runtime inputs\n")
metadata:write("range=$04A5-$0515 inclusive; $0515 is the packet-ready flag\n")
metadata:write("watched_input_state=$0034,$0035,$034E,$0350,$0366,$0368,$0441,$05FB,$05CD,$05CE,$063D,$0635,$0637\n")
metadata:flush()

local current_source_frame = -1
local frame_cycle_start = -1
local active_pass = 0
local writes, flags, queue_entries, frame_file = nil, nil, nil, nil
local source_writes, producer_entries, table_entries, pointer_codepath = nil, nil, nil, nil
local early_source_writes = nil
local write_sequence = 0
local last_value = {}
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

local function capture_checkpoint_signature()
	local cpu_ram = memory_range(0x0000, 0x0800)
	local ppu_mem = ppu.readbyterange(0x0000, 0x4000)
	assert(type(ppu_mem) == "string" and #ppu_mem == 0x4000, "could not read all PPU memory")
	local r0, r1, r2, r3 = prg_map()
	return {
		frame=emu.framecount(), cycles=cycles(), cpu_ram=cpu_ram, ppu_mem=ppu_mem,
		mmc3_select=mmc3_select, mmc3=copy_array(mmc3), mmc3_mirroring=mmc3_mirroring,
		mmc3_ram_control=mmc3_ram_control, mmc3_irq_latch=mmc3_irq_latch,
		mmc3_irq_enable=mmc3_irq_enable, mmc3_irq_reload_pending=mmc3_irq_reload_pending,
		prg_banks={r0,r1,r2,r3}, prg_bytes={byte(0x8000),byte(0xA000),byte(0xC000),byte(0xE000)},
	}
end

local function restore_mapper(signature)
	mmc3_select = signature.mmc3_select
	mmc3 = copy_array(signature.mmc3)
	mmc3_mirroring = signature.mmc3_mirroring
	mmc3_ram_control = signature.mmc3_ram_control
	mmc3_irq_latch = signature.mmc3_irq_latch
	mmc3_irq_enable = signature.mmc3_irq_enable
	mmc3_irq_reload_pending = signature.mmc3_irq_reload_pending
end

local function verify_checkpoint(signature, label)
	local observed = capture_checkpoint_signature()
	assert(observed.frame == signature.frame, label .. " frame mismatch")
	assert(observed.cycles == signature.cycles, label .. " cycle mismatch")
	assert(observed.cpu_ram == signature.cpu_ram, label .. " CPU-RAM signature mismatch")
	assert(observed.ppu_mem == signature.ppu_mem, label .. " PPU-memory signature mismatch")
	assert(observed.mmc3_select == signature.mmc3_select, label .. " MMC3 select mismatch")
	for index = 1, 8 do assert(observed.mmc3[index] == signature.mmc3[index], label .. " MMC3 register mirror mismatch") end
	for index = 1, 4 do
		assert(observed.prg_banks[index] == signature.prg_banks[index], label .. " PRG map mismatch")
		assert(observed.prg_bytes[index] == signature.prg_bytes[index], label .. " mapped PRG byte mismatch")
	end
end

local function buffer_snapshot(path)
	local file = assert(io.open(OUT .. "/" .. path, "wb"))
	file:write(memory_range(RAM_FIRST, RAM_LAST - RAM_FIRST + 1))
	file:close()
end

local write_header = table.concat({
	"sequence","pass","source_frame","emulator_frame","cycle_from_frame_start","cycle_absolute",
	"event","cpu_pc_after_write","pc_prg_bank","cpu_address","old_value","new_value",
	"cpu_a","cpu_x","cpu_y","cpu_p","mmc3_select","prg_8000","prg_a000","prg_c000","prg_e000"
}, ",")

local source_write_header = table.concat({
	"sequence","pass","source_frame","emulator_frame","cycle_from_frame_start","cycle_absolute",
	"cpu_pc_after_write","pc_prg_bank","cpu_address","old_value","new_value",
	"cpu_a","cpu_x","cpu_y","cpu_p","mmc3_select","prg_8000","prg_a000","prg_c000","prg_e000"
}, ",")
local producer_entry_header = table.concat({
	"sequence","pass","source_frame","emulator_frame","cycle_from_frame_start","cycle_absolute",
	"entry_pc","entry_prg_bank","return_address","cpu_s","cpu_a","cpu_x","cpu_y","cpu_p",
	"ram_0034","ram_0035","record_034E","record_0350","record_0366","record_0368","ram_0441","ram_05FB","ram_05CD","ram_05CE","ram_063D","ram_0635","ram_0637","ram_003A","ram_003B","ram_003C","ram_003D",
	"ram_003E","ram_004A","ram_004B","ram_0546","mmc3_select","prg_8000","prg_a000","prg_c000","prg_e000"
}, ",")

local function log_ram_write(address, new_value)
	if current_source_frame < FIRST_TRACE_FRAME or current_source_frame > LAST_TRACE_FRAME or writes == nil then return end
	local old = last_value[address]
	local value = type(new_value) == "number" and new_value or byte(address)
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local emu_frame = -1
	pcall(function() emu_frame = emu.framecount() end)
	local pc = reg("pc")
	local r0, r1, r2, r3 = prg_map()
	local event = address == 0x0515 and "PPU_PACKET_READY_FLAG" or "PPU_PACKET_BUFFER_WRITE"
	writes:write(csv({write_sequence,active_pass,current_source_frame,emu_frame,relative,absolute,
		event,hx(pc,4),pc_bank(pc),hx(address,4),old ~= nil and hx(old,2) or "",hx(value,2),
		hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(mmc3_select,2),
		hx(r0,2),hx(r1,2),hx(r2,2),hx(r3,2)}) .. "\n")
	write_sequence = write_sequence + 1
	last_value[address] = value
	if address == 0x0515 then
		local snapshot = memory_range(RAM_FIRST, RAM_LAST - RAM_FIRST + 1)
		flags:write(csv({active_pass,current_source_frame,emu_frame,relative,absolute,hx(pc,4),pc_bank(pc),
			hx(old or -1,2),hx(value,2),bytes_hex(snapshot)}) .. "\n")
	end
end

local function log_queue_consumer()
	if current_source_frame < FIRST_TRACE_FRAME or current_source_frame > LAST_TRACE_FRAME or queue_entries == nil then return end
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local emu_frame = -1
	pcall(function() emu_frame = emu.framecount() end)
	local pc = reg("pc")
	local snapshot = memory_range(RAM_FIRST, RAM_LAST - RAM_FIRST + 1)
	local packet_length = string.byte(snapshot, 1) or 0
	local packet_size = math.min(3 + packet_length, #snapshot)
	local packet_data = {}
	for index = 1, packet_size do packet_data[index] = string.format("%02X", string.byte(snapshot, index)) end
	local r0, r1, r2, r3 = prg_map()
	queue_entries:write(csv({active_pass,current_source_frame,emu_frame,relative,absolute,hx(pc,4),pc_bank(pc),
		hx(byte(0x0515),2),hx(packet_length,2),hx(byte(0x04A6),2),hx(byte(0x04A7),2),
		table.concat(packet_data," "),bytes_hex(snapshot),hx(mmc3_select,2),hx(r0,2),hx(r1,2),hx(r2,2),hx(r3,2)}) .. "\n")
end

local source_write_sequence = 0
local producer_entry_sequence = 0

local function log_source_state_write(address, new_value)
	local old = last_value[address]
	local value = type(new_value) == "number" and new_value or byte(address)
	if current_source_frame >= 0 and current_source_frame < FIRST_TRACE_FRAME and early_source_writes ~= nil
			and (address == 0x05CD or address == 0x05CE or address == 0x063D) then
		local absolute = cycles()
		local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
		local emu_frame = -1
		pcall(function() emu_frame = emu.framecount() end)
		local pc = reg("pc")
		local r0, r1, r2, r3 = prg_map()
		early_source_writes:write(csv({"warmup",current_source_frame,emu_frame,relative,absolute,
			hx(pc,4),pc_bank(pc),hx(address,4),old ~= nil and hx(old,2) or "",hx(value,2),
			hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(mmc3_select,2),
			hx(r0,2),hx(r1,2),hx(r2,2),hx(r3,2)}) .. "\n")
	end
	if current_source_frame >= FIRST_TRACE_FRAME and current_source_frame <= LAST_TRACE_FRAME and source_writes ~= nil then
		local absolute = cycles()
		local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
		local emu_frame = -1
		pcall(function() emu_frame = emu.framecount() end)
		local pc = reg("pc")
		local r0, r1, r2, r3 = prg_map()
		source_writes:write(csv({source_write_sequence,active_pass,current_source_frame,emu_frame,relative,absolute,
			hx(pc,4),pc_bank(pc),hx(address,4),old ~= nil and hx(old,2) or "",hx(value,2),
			hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(mmc3_select,2),
			hx(r0,2),hx(r1,2),hx(r2,2),hx(r3,2)}) .. "\n")
		source_write_sequence = source_write_sequence + 1
	end
	last_value[address] = value
end

local function log_producer_entry(entry_name)
	if current_source_frame < FIRST_TRACE_FRAME or current_source_frame > LAST_TRACE_FRAME or producer_entries == nil then return end
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local emu_frame = -1
	pcall(function() emu_frame = emu.framecount() end)
	local pc = reg("pc")
	local sp = reg("s")
	local stack_low = byte(0x0100 + ((sp + 1) % 0x100))
	local stack_high = byte(0x0100 + ((sp + 2) % 0x100))
	local return_address = stack_low + stack_high * 0x100
	local r0, r1, r2, r3 = prg_map()
	producer_entries:write(csv({producer_entry_sequence,active_pass,current_source_frame,emu_frame,relative,absolute,
		entry_name,hx(pc_bank(pc),2),hx(return_address,4),hx(sp,2),hx(reg("a"),2),hx(reg("x"),2),
		hx(reg("y"),2),hx(reg("p"),2),hx(byte(0x0034),2),hx(byte(0x0035),2),hx(byte(0x034E),2),hx(byte(0x0350),2),hx(byte(0x0366),2),hx(byte(0x0368),2),hx(byte(0x0441),2),hx(byte(0x05FB),2),hx(byte(0x05CD),2),hx(byte(0x05CE),2),hx(byte(0x063D),2),hx(byte(0x0635),2),hx(byte(0x0637),2),
		hx(byte(0x003A),2),hx(byte(0x003B),2),hx(byte(0x003C),2),hx(byte(0x003D),2),
		hx(byte(0x003E),2),hx(byte(0x004A),2),hx(byte(0x004B),2),hx(byte(0x0546),2),hx(mmc3_select,2),
		hx(r0,2),hx(r1,2),hx(r2,2),hx(r3,2)}) .. "\n")
	producer_entry_sequence = producer_entry_sequence + 1
end

local function log_coordinate_pointer_table_entry()
	if current_source_frame < FIRST_TRACE_FRAME or current_source_frame > LAST_TRACE_FRAME or table_entries == nil then return end
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local emu_frame = -1
	pcall(function() emu_frame = emu.framecount() end)
	local y = reg("y")
	local low_address = (0xCD89 + y) % 0x10000
	local high_address = (0xCD8A + y) % 0x10000
	local r0, r1, r2, r3 = prg_map()
	table_entries:write(csv({active_pass,current_source_frame,emu_frame,relative,absolute,hx(reg("pc"),4),
		hx(pc_bank(reg("pc")),2),hx(reg("a"),2),hx(reg("x"),2),hx(y,2),hx(byte(0x05FB),2),
		hx(byte(0x0034),2),hx(byte(0x0035),2),hx(low_address,4),hx(byte(low_address),2),
		hx(high_address,4),hx(byte(high_address),2),hx(r0,2),hx(r1,2),hx(r2,2),hx(r3,2)}) .. "\n")
end

local function log_coordinate_pointer_codepath()
	if current_source_frame < FIRST_TRACE_FRAME or current_source_frame > LAST_TRACE_FRAME or pointer_codepath == nil then return end
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local emu_frame = -1
	pcall(function() emu_frame = emu.framecount() end)
	local pc = reg("pc")
	local r0, r1, r2, r3 = prg_map()
	local code = {}
	for address = 0xCD74, 0xCD88 do code[#code + 1] = string.format("%02X", byte(address)) end
	pointer_codepath:write(csv({active_pass,current_source_frame,emu_frame,relative,absolute,hx(pc,4),hx(pc_bank(pc),2),
		hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(byte(0x0034),2),hx(byte(0x0035),2),
		table.concat(code," "),hx(r0,2),hx(r1,2),hx(r2,2),hx(r3,2)}) .. "\n")
end

memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value) mmc3[(mmc3_select % 8) + 1] = value or 0 end)
memory.registerwrite(0xA000, 1, function(_, _, value) mmc3_mirroring = value or -1 end)
memory.registerwrite(0xA001, 1, function(_, _, value) mmc3_ram_control = value or -1 end)
memory.registerwrite(0xC000, 1, function(_, _, value) mmc3_irq_latch = value or -1 end)
memory.registerwrite(0xC001, 1, function() mmc3_irq_reload_pending = 1 end)
memory.registerwrite(0xE000, 1, function() mmc3_irq_enable = 0 end)
memory.registerwrite(0xE001, 1, function() mmc3_irq_enable = 1 end)
assert(type(memory.registerexec) == "function", "FCEUX execute hooks unavailable")

local ram_hooks_attached = false
local function attach_ram_hooks()
	if ram_hooks_attached then return end
	memory.registerwrite(RAM_FIRST, RAM_LAST - RAM_FIRST + 1, function(address, _, value)
		local watched = type(address) == "number" and address or RAM_FIRST
		if watched < RAM_FIRST or watched > RAM_LAST then return end
		log_ram_write(watched, value)
		if current_source_frame < FIRST_TRACE_FRAME or writes == nil then
			last_value[watched] = type(value) == "number" and value or byte(watched)
		end
	end)
	memory.registerexec(0xC951, log_queue_consumer)
	for _, input_state in ipairs(INPUT_STATE) do
		local address = input_state.address
		memory.registerwrite(address, 1, function(_, _, value)
			log_source_state_write(address, value)
		end)
	end
	for address, label in pairs({[0xDB00]="$DB00",[0xDC29]="$DC29",
			[0xE6F2]="$E6F2",[0xE6FA]="$E6FA",[0xE701]="$E701",
			[0xF015]="$F015",[0xF0B5]="$F0B5",[0xF114]="$F114",[0xF159]="$F159"}) do
		memory.registerexec(address, function() log_producer_entry(label) end)
	end
	memory.registerexec(0xCD7C, log_coordinate_pointer_table_entry)
	for _, address in ipairs({0xCD74,0xCD7B,0xCD7E,0xCD80,0xCD83,0xCD86,0xCD88}) do
		memory.registerexec(address, log_coordinate_pointer_codepath)
	end
	ram_hooks_attached = true
end

local function write_pass_files(pass_index)
	local suffix = pass_index == 1 and "" or "_repeat"
	writes = output("ppu_packet_ram_writes" .. suffix .. ".csv", write_header)
	source_writes = output("field_producer_input_writes" .. suffix .. ".csv", source_write_header)
	producer_entries = output("field_producer_entries" .. suffix .. ".csv", producer_entry_header)
	table_entries = output("coordinate_pointer_table_entries" .. suffix .. ".csv",
		"pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,entry_pc,entry_prg_bank,cpu_a,cpu_x,cpu_y,ram_05FB,ram_0034,ram_0035,table_low_address,table_low,table_high_address,table_high,prg_8000,prg_a000,prg_c000,prg_e000")
	pointer_codepath = output("coordinate_pointer_codepath" .. suffix .. ".csv",
		"pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,entry_pc,entry_prg_bank,cpu_a,cpu_x,cpu_y,ram_0034,ram_0035,bytes_cd74_cd88,prg_8000,prg_a000,prg_c000,prg_e000")
	flags = output("ppu_packet_ready_events" .. suffix .. ".csv",
		"pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,cpu_pc_after_write,pc_prg_bank,old_value,new_value,buffer_04a5_0515_hex")
	queue_entries = output("queue_consumer_entries" .. suffix .. ".csv",
		"pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,cpu_pc,pc_prg_bank,flag_0515,packet_length,header_byte_1,header_byte_2,packet_hex,buffer_04a5_0515_hex,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000")
	frame_file = output("frame_edges" .. suffix .. ".csv",
		"source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,input_bits")
	write_sequence = 0
	source_write_sequence = 0
	producer_entry_sequence = 0
	for address = RAM_FIRST, RAM_LAST do last_value[address] = byte(address) end
	for _, input_state in ipairs(INPUT_STATE) do last_value[input_state.address] = byte(input_state.address) end
	local snapshot_name = pass_index == 1 and "buffer_start.bin" or "buffer_start_repeat.bin"
	buffer_snapshot(snapshot_name)
end

local function close_pass_files(pass_index, event_count)
	writes:flush(); flags:flush(); queue_entries:flush(); frame_file:flush()
	source_writes:flush(); producer_entries:flush(); table_entries:flush(); pointer_codepath:flush()
	writes:close(); flags:close(); queue_entries:close(); frame_file:close()
	source_writes:close(); producer_entries:close(); table_entries:close(); pointer_codepath:close()
	writes, flags, queue_entries, frame_file = nil, nil, nil, nil
	source_writes, producer_entries, table_entries, pointer_codepath = nil, nil, nil, nil
	local snapshot_name = pass_index == 1 and "buffer_end.bin" or "buffer_end_repeat.bin"
	buffer_snapshot(snapshot_name)
	metadata:write("pass_" .. pass_index .. "_ram_write_events=" .. event_count .. "\n")
	metadata:flush()
end

local function run_pass(pass_index)
	active_pass = pass_index
	write_pass_files(pass_index)
	local event_start = write_sequence
	for frame = FIRST_TRACE_FRAME, LAST_TRACE_FRAME do
		current_source_frame = frame
		joypad.set(1, inputs[frame])
		frame_cycle_start = cycles()
		local frame_before = emu.framecount()
		emu.frameadvance()
		local frame_after = emu.framecount()
		local cycle_end = cycles()
		local bits = {}
		for _, key in ipairs({"up","down","left","right","A","B","start","select"}) do bits[#bits + 1] = inputs[frame][key] and "1" or "0" end
		frame_file:write(table.concat({frame,frame_before,frame_after,frame_cycle_start,cycle_end,
			cycle_end-frame_cycle_start,table.concat(bits,"")}, ",") .. "\n")
		if frame % 15 == 0 or frame == LAST_TRACE_FRAME then
			writes:flush(); flags:flush(); queue_entries:flush(); frame_file:flush()
			source_writes:flush(); producer_entries:flush(); table_entries:flush(); pointer_codepath:flush(); metadata:flush()
			local progress = assert(io.open(OUT .. "/progress.txt", "w"))
			progress:write(tostring(pass_index) .. ":" .. tostring(frame) .. "\n")
			progress:close()
		end
	end
	close_pass_files(pass_index, write_sequence - event_start)
end

local startup_movie_mode = "unavailable"
pcall(function()
	startup_movie_mode = tostring(movie.mode())
	if movie.mode() ~= nil then pcall(movie.stop) end
end)
if type(movie.active) == "function" then
	local active = false
	pcall(function() active = movie.active() end)
	if active then pcall(movie.stop) end
end
assert(tostring(movie.mode()) == "nil", "could not disable FCEUX startup movie")
local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "FCEUX power-on failed: " .. tostring(power_error))
pcall(debugger.resetcyclescount)
metadata:write("startup_movie_mode=" .. startup_movie_mode .. "\npoweron_success=true\n")
metadata:flush()
pcall(emu.speedmode, "turbo")
early_source_writes = output("pre_checkpoint_source_writes.csv",
	"phase,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,cpu_pc_after_write,pc_prg_bank,cpu_address,old_value,new_value,cpu_a,cpu_x,cpu_y,cpu_p,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000")
attach_ram_hooks()
local initial_progress = assert(io.open(OUT .. "/progress.txt", "w"))
initial_progress:write("warmup:starting:0\n")
initial_progress:close()

for frame = 0, CHECKPOINT_FRAME do
	current_source_frame = frame
	joypad.set(1, inputs[frame])
	frame_cycle_start = cycles()
	emu.frameadvance()
	if frame % 300 == 0 or frame == CHECKPOINT_FRAME then
		local progress = assert(io.open(OUT .. "/progress.txt", "w"))
		progress:write("warmup:" .. tostring(frame) .. "\n")
		progress:close()
	end
end

local checkpoint = savestate.create()
assert(checkpoint ~= nil, "could not create anonymous in-memory save state")
local signature = capture_checkpoint_signature()
early_source_writes:flush()
early_source_writes:close()
early_source_writes = nil
local save_ok, save_error = pcall(savestate.save, checkpoint)
assert(save_ok, "could not save in-memory checkpoint: " .. tostring(save_error))
local persist_ok, persist_error = pcall(savestate.persist, checkpoint)
assert(persist_ok, "could not persist in-memory checkpoint: " .. tostring(persist_error))
metadata:write("checkpoint_source_frame=" .. CHECKPOINT_FRAME .. "\ncheckpoint_emulator_frame=" .. signature.frame .. "\n")
metadata:write("checkpoint_cycle_count=" .. signature.cycles .. "\ncheckpoint_cpu_ram_bytes=" .. #signature.cpu_ram
	.. "\ncheckpoint_ppu_memory_bytes=" .. #signature.ppu_mem .. "\n")
metadata:write("checkpoint_mmc3_select=$" .. string.format("%02X", signature.mmc3_select) .. "\n")
metadata:write("checkpoint_prg_banks=" .. table.concat(signature.prg_banks, ",") .. "\ncheckpoint_prg_bytes="
	.. table.concat(signature.prg_bytes, ",") .. "\n")
metadata:write("checkpoint_signature=frame/cycle, 2KiB CPU RAM, 16KiB PPU memory, MMC3 mirror and mapped PRG bytes\n")
metadata:flush()

for pass = 1, 2 do
	current_source_frame = CHECKPOINT_FRAME
	local load_ok, load_error = pcall(savestate.load, checkpoint)
	assert(load_ok, "save-state load failed for pass " .. pass .. ": " .. tostring(load_error))
	restore_mapper(signature)
	verify_checkpoint(signature, "pass " .. pass)
	metadata:write("pass_" .. pass .. "_checkpoint_verified=true\n")
	metadata:flush()
	run_pass(pass)
end

metadata:write("complete=true\nreplay_passes=2\ncompleted_source_frames=" .. LAST_TRACE_FRAME .. "\n")
metadata:write("caveat=pre-checkpoint writer capture is limited to $05CD/$05CE/$063D; all other watched source-state writers are recorded only for frames 8400-8953\n")
metadata:flush()
metadata:close()
pcall(memory.registerwrite, RAM_FIRST, RAM_LAST - RAM_FIRST + 1, nil)
pcall(memory.registerexec, 0xC951, nil)
for _, input_state in ipairs(INPUT_STATE) do pcall(memory.registerwrite, input_state.address, 1, nil) end
for _, address in ipairs({0xDB00,0xDC29,0xE6F2,0xE6FA,0xE701,0xF015,0xF0B5,0xF114,0xF159}) do pcall(memory.registerexec, address, nil) end
pcall(memory.registerexec, 0xCD7C, nil)
for _, address in ipairs({0xCD74,0xCD7B,0xCD7E,0xCD80,0xCD83,0xCD86,0xCD88}) do pcall(memory.registerexec, address, nil) end
for _, address in ipairs({0x8000,0x8001,0xA000,0xA001,0xC000,0xC001,0xE000,0xE001}) do
	pcall(memory.registerwrite, address, 1, nil)
end
os.exit()

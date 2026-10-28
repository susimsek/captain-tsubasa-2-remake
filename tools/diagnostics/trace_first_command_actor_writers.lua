-- Same-input, muted FCEUX trace for the first-command actor state producer.
-- Run through run_first_command_actor_writer_trace.py. Output is diagnostic only.

local PROJECT_ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = PROJECT_ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local FIRST_TRACE_FRAME = 8400
local LAST_TRACE_FRAME = 8953
local CHECKPOINT_FRAME = FIRST_TRACE_FRAME - 1
local LAST_SOURCE_FRAME = 8953
local ACTOR_FIRST = 0x0547
local ACTOR_LAST = 0x05C4
local ACTOR_STRIDE = 0x15
local OUT = assert(os.getenv("CT2_ACTOR_WRITER_TRACE_OUTPUT_DIR"), "missing output directory")
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

local function word(address) return byte(address) + byte(address + 1) * 256 end

local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
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

local function actor_index_for_address(address)
	if address < ACTOR_FIRST or address > ACTOR_LAST then return -1, -1 end
	local index = math.floor((address - ACTOR_FIRST) / ACTOR_STRIDE)
	return index, ACTOR_FIRST + index * ACTOR_STRIDE
end

local function actor_index_for_pointer(address)
	if address < ACTOR_FIRST or address > ACTOR_LAST then return -1, -1 end
	local index, base = actor_index_for_address(address)
	if address ~= base then return index, base end
	return index, base
end

local function source_addresses()
	local addresses = {}
	for address = ACTOR_FIRST, ACTOR_LAST do addresses[#addresses + 1] = address end
	for address = 0x053A, 0x053D do addresses[#addresses + 1] = address end
	return addresses
end

local watched_addresses = source_addresses()
local address_index = {}
for index, address in ipairs(watched_addresses) do address_index[address] = index end
local pass_suffix = ""

local function write_snapshot(name)
	local stem, extension = name:match("^(.*)(%.[^.]*)$")
	local suffix_name = stem and (stem .. pass_suffix .. extension) or (name .. pass_suffix)
	local file = assert(io.open(OUT .. "/" .. suffix_name, "wb"))
	local values = {}
	for _, address in ipairs(watched_addresses) do values[#values + 1] = string.char(byte(address)) end
	file:write(table.concat(values))
	file:close()
end

local WRITES_HEADER =
	"sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,event,cpu_pc,pc_prg_bank,address,old_value,new_value,actor_record_index,actor_record,record_offset,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000"
local EVENTS_HEADER =
	"sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,event,cpu_pc,pc_prg_bank,actor_order_index,actor_record_index,actor_record,actor_record_21_bytes,main_stream_ptr,motion_stream_ptr,main_timer,motion_timer,descriptor,selector_0546,chr_0493_0497,actor_pointer_003c,field_053a_053d,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000"
local writes = nil
local events = nil
local metadata = output("metadata.txt")

local rom_sha256, rom_md5 = "unavailable", "unavailable"
pcall(function() rom_sha256 = rom.gethash("sha256") end)
pcall(function() rom_md5 = rom.gethash("md5") end)
metadata:write("rom_sha256=" .. tostring(rom_sha256) .. "\nrom_md5=" .. tostring(rom_md5) .. "\n")
metadata:write("opening_input=" .. OPENING_INPUT .. "\nroute_input=" .. ROUTE_INPUT .. "\n")
metadata:write("opening_input_sha256=" .. tostring(os.getenv("CT2_OPENING_INPUT_SHA256") or "") .. "\n")
metadata:write("route_input_sha256=" .. tostring(os.getenv("CT2_ROUTE_INPUT_SHA256") or "") .. "\n")
metadata:write("source_frames=0-" .. LAST_SOURCE_FRAME .. "\ninstrumented_source_frames=" .. FIRST_TRACE_FRAME .. "-" .. LAST_TRACE_FRAME .. "\n")
metadata:write("audio=disabled by FCEUX --sound 0 --volume 0 with SDL_AUDIODRIVER=dummy; no audio files are recorded\n")
metadata:write("target_hooks=actor RAM $0547-$05C4, globals $053A-$053D, execute $83D9/$84DC/$EE9F; attached only inside the requested frame window\n")
metadata:write("mapper_tracking=only $8000/$8001 callbacks remain active from power-on so PC PRG bank annotations are known at the target window\n")
metadata:write("snapshot_layout=actor_start.bin and actor_end.bin (plus _repeat variants) each contain $0547-$05C4 followed by $053A-$053D\n")
metadata:write("purpose=identify source writers and update timing; captures are diagnostic evidence, never runtime assets\n")
metadata:write("checkpoint=anonymous in-memory FCEUX state at source frame " .. CHECKPOINT_FRAME .. "; target window replayed twice from the same verified state\n")
metadata:flush()

local current_source_frame = -1
local frame_cycle_start = -1
local write_sequence, call_sequence = 0, 0
local mmc3_select = 0
local mmc3 = {0, 2, 4, 5, 6, 7, 0, 1}
local last_value = {}
local target_hooks_attached = false

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

local function timing()
	local cycle_absolute = -1
	if type(debugger) == "table" and type(debugger.getcyclescount) == "function" then
		pcall(function() cycle_absolute = debugger.getcyclescount() end)
	end
	local relative = -1
	if cycle_absolute >= 0 and frame_cycle_start >= 0 then relative = cycle_absolute - frame_cycle_start end
	local emu_frame = -1
	pcall(function() emu_frame = emu.framecount() end)
	return emu_frame, relative, cycle_absolute
end

local function bytes_hex(first, count)
	local values = {}
	for offset = 0, count - 1 do values[#values + 1] = string.format("%02X", byte(first + offset)) end
	return table.concat(values, " ")
end

local function log_write(address, _, new_value)
	local old_value = last_value[address]
	local value = type(new_value) == "number" and new_value or byte(address)
	local pc = reg("pc")
	local r0, r1, r2, r3 = prg_map()
	local actor_index, actor_base = actor_index_for_address(address)
	local record_offset = actor_index >= 0 and address - actor_base or -1
	local emu_frame, relative, absolute = timing()
	writes:write(csv({write_sequence, current_source_frame, emu_frame, relative, absolute,
		actor_index >= 0 and "actor_record_write" or "field_state_write", hx(pc, 4), pc_bank(pc),
		hx(address, 4), old_value ~= nil and hx(old_value, 2) or "", hx(value, 2),
		actor_index >= 0 and actor_index or "", actor_base >= 0 and hx(actor_base, 4) or "",
		actor_index >= 0 and hx(record_offset, 2) or "", hx(mmc3_select, 2),
		hx(r0, 2), hx(r1, 2), hx(r2, 2), hx(r3, 2)}) .. "\n")
	write_sequence = write_sequence + 1
	last_value[address] = value
end

local function log_call(name, address)
	local pc = reg("pc")
	local record = word(0x003C)
	local index, base = actor_index_for_pointer(record)
	local r0, r1, r2, r3 = prg_map()
	local emu_frame, relative, absolute = timing()
	local valid_record = index >= 0 and record == base
	local fields = {call_sequence, current_source_frame, emu_frame, relative, absolute,
		name, hx(pc, 4), pc_bank(pc), byte(0x003A), valid_record and index or "",
		valid_record and hx(record, 4) or "", valid_record and bytes_hex(record, 21) or "",
		valid_record and hx(word(record + 3), 4) or "", valid_record and hx(word(record + 1), 4) or "",
		valid_record and hx(byte(record + 0x10), 2) or "", valid_record and hx(byte(record + 0x11), 2) or "",
		valid_record and hx(byte(record + 0x12), 2) or "", hx(byte(0x0546), 2),
		bytes_hex(0x0493, 5), hx(record, 4), bytes_hex(0x053A, 4), hx(mmc3_select, 2),
		hx(r0, 2), hx(r1, 2), hx(r2, 2), hx(r3, 2)}
	events:write(csv(fields) .. "\n")
	call_sequence = call_sequence + 1
end

local routine_hooks = {
	[0x83D9] = "appearance_update_83D9",
	[0x84DC] = "motion_update_84DC",
	[0xEE9F] = "actor_draw_loop_EE9F",
}

local function attach_target_hooks()
	if target_hooks_attached then return end
	for _, address in ipairs(watched_addresses) do last_value[address] = byte(address) end
	write_snapshot("actor_start.bin")
	for _, address in ipairs(watched_addresses) do
		local watched = address
		memory.registerwrite(watched, 1, function(a, b, value) log_write(watched, b, value) end)
	end
	for address, name in pairs(routine_hooks) do
		local hook_address, hook_name = address, name
		memory.registerexec(hook_address, function() log_call(hook_name, hook_address) end)
	end
	target_hooks_attached = true
	metadata:write("target_hooks_attached_source_frame=" .. current_source_frame .. "\n")
	metadata:flush()
end

local detach_target_hooks

local function begin_trace_pass(pass_index)
	pass_suffix = pass_index == 1 and "" or "_repeat"
	writes = output("actor_memory_writes" .. pass_suffix .. ".csv", WRITES_HEADER)
	events = output("actor_routine_calls" .. pass_suffix .. ".csv", EVENTS_HEADER)
	write_sequence, call_sequence = 0, 0
	last_value = {}
	current_source_frame = CHECKPOINT_FRAME
	target_hooks_attached = false
	metadata:write("pass_" .. pass_index .. "_source_range=" .. FIRST_TRACE_FRAME .. "-" .. LAST_TRACE_FRAME .. "\n")
	metadata:flush()
end

local function run_trace_pass(pass_index)
	begin_trace_pass(pass_index)
	for frame = FIRST_TRACE_FRAME, LAST_TRACE_FRAME do
		current_source_frame = frame
		if frame == FIRST_TRACE_FRAME then attach_target_hooks() end
		joypad.set(1, inputs[frame])
		frame_cycle_start = debugger.getcyclescount()
		emu.frameadvance()
		if target_hooks_attached and frame == LAST_TRACE_FRAME then
			write_snapshot("actor_end.bin")
			detach_target_hooks()
		end
		if frame % 30 == 0 or frame == LAST_TRACE_FRAME then
			if writes ~= nil then writes:flush(); events:flush() end
			metadata:flush()
			local progress = assert(io.open(OUT .. "/progress.txt", "w"))
			progress:write(tostring(pass_index) .. ":" .. tostring(frame) .. "\n")
			progress:close()
		end
	end
	metadata:write("pass_" .. pass_index .. "_actor_write_events=" .. write_sequence .. "\n")
	metadata:write("pass_" .. pass_index .. "_routine_calls=" .. call_sequence .. "\n")
	metadata:flush()
end

detach_target_hooks = function()
	if not target_hooks_attached then return end
	for _, address in ipairs(watched_addresses) do pcall(memory.registerwrite, address, 1, nil) end
	for address in pairs(routine_hooks) do pcall(memory.registerexec, address, nil) end
	target_hooks_attached = false
	writes:flush(); events:flush()
	writes:close(); events:close()
    writes = nil; events = nil
end

local function copy_mmc3(values)
	local result = {}
	for index, value in ipairs(values) do result[index] = value end
	return result
end

local function read_checkpoint_signature()
	local cpu_ram_ok, cpu_ram = pcall(function() return memory.readbyterange(0x0000, 0x0800) end)
	local ppu_mem_ok, ppu_mem = pcall(function() return ppu.readbyterange(0x0000, 0x4000) end)
	assert(cpu_ram_ok and type(cpu_ram) == "string" and #cpu_ram == 0x0800, "could not read checkpoint CPU RAM")
	assert(ppu_mem_ok and type(ppu_mem) == "string" and #ppu_mem == 0x4000, "could not read checkpoint PPU memory")
	local r0, r1, r2, r3 = prg_map()
	return {
		frame = emu.framecount(),
		cycles = debugger.getcyclescount(),
		cpu_ram = cpu_ram,
		ppu_mem = ppu_mem,
		mmc3_select = mmc3_select,
		mmc3 = copy_mmc3(mmc3),
		prg_banks = {r0, r1, r2, r3},
		prg_bytes = {byte(0x8000), byte(0xA000), byte(0xC000), byte(0xE000)},
	}
end

local function restore_checkpoint_mmc3(signature)
	mmc3_select = signature.mmc3_select
	mmc3 = copy_mmc3(signature.mmc3)
end

local function verify_checkpoint(signature, label)
	local observed = read_checkpoint_signature()
	assert(observed.frame == signature.frame, label .. " frame-count mismatch")
	assert(observed.cycles == signature.cycles, label .. " cycle-count mismatch")
	assert(observed.cpu_ram == signature.cpu_ram, label .. " CPU-RAM signature mismatch")
	assert(observed.ppu_mem == signature.ppu_mem, label .. " PPU-memory signature mismatch")
	assert(observed.mmc3_select == signature.mmc3_select, label .. " MMC3 select signature mismatch")
	for index = 1, 8 do assert(observed.mmc3[index] == signature.mmc3[index], label .. " MMC3 bank-register mismatch") end
	for index = 1, 4 do
		assert(observed.prg_banks[index] == signature.prg_banks[index], label .. " PRG mapping mismatch")
		assert(observed.prg_bytes[index] == signature.prg_bytes[index], label .. " mapped PRG byte mismatch")
	end
	return observed
end

-- Minimal mapper-state hooks run from reset so the actor callbacks can report
-- the bank mapped at each PC without keeping the RAM/exec trace active all run.
memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value)
	mmc3[(mmc3_select % 8) + 1] = value or 0
end)

local startup_movie_mode, startup_movie_name = "unavailable", "none"
pcall(function()
	startup_movie_mode = tostring(movie.mode())
	if movie.mode() ~= nil then
		startup_movie_name = tostring(movie.getname())
		pcall(movie.stop)
	end
end)
if type(movie.active) == "function" then
	local active = false
	pcall(function() active = movie.active() end)
	if active then pcall(movie.stop) end
end
local movie_mode_after_stop = "unavailable"
pcall(function() movie_mode_after_stop = tostring(movie.mode()) end)
assert(movie_mode_after_stop == "nil", "could not stop FCEUX startup movie before replay")

local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "FCEUX poweron failed: " .. tostring(power_error))
local post_power_movie_mode = "unavailable"
pcall(function() post_power_movie_mode = tostring(movie.mode()) end)
if post_power_movie_mode ~= "nil" then pcall(movie.stop) end
assert(tostring(movie.mode()) == "nil", "FCEUX movie restarted after power-on")
if type(debugger) == "table" and type(debugger.resetcyclescount) == "function" then
	pcall(debugger.resetcyclescount)
end
metadata:write("startup_movie_mode=" .. startup_movie_mode .. "\nstartup_movie_name=" .. startup_movie_name .. "\n")
metadata:write("movie_mode_after_poweron=" .. tostring(movie.mode()) .. "\n")
metadata:write("cycle_counter_available=" .. tostring(type(debugger) == "table" and type(debugger.getcyclescount) == "function") .. "\n")
metadata:write("poweron_success=true\n")
metadata:flush()
pcall(emu.speedmode, "turbo")

for frame = 0, CHECKPOINT_FRAME do
	current_source_frame = frame
	joypad.set(1, inputs[frame])
	frame_cycle_start = debugger.getcyclescount()
	emu.frameadvance()
	if frame % 600 == 0 or frame == CHECKPOINT_FRAME then
		local progress = assert(io.open(OUT .. "/progress.txt", "w"))
		progress:write("warmup:" .. tostring(frame) .. "\n")
		progress:close()
	end
end

local checkpoint_state = savestate.create()
assert(checkpoint_state ~= nil, "FCEUX could not create an anonymous in-memory save state")
local checkpoint_signature = read_checkpoint_signature()
local save_ok, save_error = pcall(savestate.save, checkpoint_state)
assert(save_ok, "FCEUX save-state save failed: " .. tostring(save_error))
local persist_ok, persist_error = pcall(savestate.persist, checkpoint_state)
assert(persist_ok, "FCEUX save-state persist failed: " .. tostring(persist_error))
metadata:write("checkpoint_source_frame=" .. CHECKPOINT_FRAME .. "\n")
metadata:write("checkpoint_fceux_frame=" .. checkpoint_signature.frame .. "\n")
metadata:write("checkpoint_cpu_cycles=" .. checkpoint_signature.cycles .. "\n")
metadata:write("checkpoint_mmc3_select=$" .. string.format("%02X", checkpoint_signature.mmc3_select) .. "\n")
metadata:write("checkpoint_prg_banks=" .. table.concat(checkpoint_signature.prg_banks, ",") .. "\n")
metadata:write("checkpoint_prg_bytes=" .. table.concat(checkpoint_signature.prg_bytes, ",") .. "\n")
metadata:write("checkpoint_signature=full CPU RAM 2KiB + PPU memory 16KiB + MMC3 mirror/mapped bytes + frame/cycle\n")
metadata:write("save_state_kind=anonymous in-memory; no numbered slot written\n")
metadata:flush()

for pass_index = 1, 2 do
	local load_ok, load_error = pcall(savestate.load, checkpoint_state)
	assert(load_ok, "FCEUX save-state load failed before pass " .. pass_index .. ": " .. tostring(load_error))
	restore_checkpoint_mmc3(checkpoint_signature)
	verify_checkpoint(checkpoint_signature, "pass " .. pass_index .. " checkpoint")
	metadata:write("pass_" .. pass_index .. "_checkpoint_verified=true\n")
	metadata:flush()
	run_trace_pass(pass_index)
end

metadata:write("completed_source_frames=" .. (LAST_SOURCE_FRAME + 1) .. "\n")
metadata:write("target_hook_frame_count=" .. (LAST_TRACE_FRAME - FIRST_TRACE_FRAME + 1) .. "\n")
metadata:write("replay_passes=2 from the same verified in-memory checkpoint\n")
metadata:flush()
metadata:close()
pcall(memory.registerwrite, 0x8000, 1, nil)
pcall(memory.registerwrite, 0x8001, 1, nil)
os.exit()

-- Muted, source-input FCEUX trace for actor renderer shared RAM state.
-- This trace is validation evidence only and never supplies runtime values.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_ACTOR_SHARED_STATE_TRACE_OUTPUT_DIR"), "missing output directory")
local CHECKPOINT_FRAME, FIRST_FRAME, LAST_FRAME = 8399, 8400, 8953
os.execute("mkdir -p " .. string.format("%q", OUT))

local function read_inputs(path, route_format)
	local result = {}
	local file = assert(io.open(path, "r"), "missing input file " .. path)
	local first = true
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
for frame, input in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = input end
for frame = 0, LAST_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

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

local current_source_frame = -1
local frame_cycle_start = -1
local writes, frames, metadata
local write_sequence = 0
local suffix = ""
local last_values = {}

local function timing()
	local absolute = -1
	if type(debugger) == "table" and type(debugger.getcyclescount) == "function" then
		pcall(function() absolute = debugger.getcyclescount() end)
	end
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local emu_frame = -1
	pcall(function() emu_frame = emu.framecount() end)
	return emu_frame, relative, absolute
end

local function source_context()
	local player_ptr = word(0x0348)
	return {
		hx(byte(0x0517), 2), hx(byte(0x0538), 2), hx(byte(0x0540), 2), hx(byte(0x0541), 2),
		hx(byte(0x0441), 2), hx(word(0x0348), 4), hx(byte(player_ptr), 2),
		hx(byte(0x052A), 2), hx(byte(0x0638), 2), hx(byte(0x0621), 2), hx(byte(0x0600), 2),
		hx(byte(0x05CD), 2), hx(byte(0x05CE), 2), hx(byte(0x05FB), 2),
		hx(byte(0x053A), 2), hx(byte(0x053B), 2), hx(byte(0x053C), 2), hx(byte(0x053D), 2),
		hx(byte(0x0543), 2), hx(byte(0x0544), 2), hx(byte(0x0545), 2), hx(byte(0x0546), 2),
		hx(byte(0x004A), 2), hx(byte(0x004B), 2), hx(byte(0x001B), 2), hx(byte(0x003C), 4),
		hx(byte(0x0048), 2), hx(byte(0x002A), 2), hx(byte(0x05FC), 2),
		hx(byte(0x0635), 2), hx(byte(0x0637), 2)
	}
end

local CONTEXT_HEADER = "mirror_0517,scroll_0538,clip_min_0540,clip_max_0541,holder_0441,player_ptr_0348,player_id,scenario_052A,target_0638,route_0621,route_0600,stream_05CD,stream_05CE,possession_05FB,actor_053A,actor_tick_053B,actor_param_053C,actor_param_053D,order_0543,order_0544,order_0545,selector_0546,scroll_004A,scroll_004B,task_001B,record_ptr_003C,scene_0048,selector_002A,random_05FC,field_0635,field_0637"
local function write_state_row(phase)
	local emu_frame, relative, absolute = timing()
	local context = source_context()
	local values = {current_source_frame, emu_frame, phase, relative, absolute}
	for _, value in ipairs(context) do values[#values + 1] = value end
	frames:write(csv(values) .. "\n")
end

local function log_write(address, new_value)
	local pc = reg("pc")
	local r0, r1, r2, r3 = prg_map()
	local emu_frame, relative, absolute = timing()
	local old_value = last_values[address]
	local written_value = type(new_value) == "number" and new_value or byte(address)
	local values = {write_sequence, current_source_frame, emu_frame, relative, absolute,
		"$" .. string.format("%04X", pc), pc_bank(pc), "$" .. string.format("%04X", address),
		type(old_value) == "number" and hx(old_value, 2) or "", hx(written_value, 2),
		hx(reg("a"), 2), hx(reg("x"), 2), hx(reg("y"), 2), hx(reg("p"), 2), hx(reg("s"), 2),
		hx(mmc3_select, 2), hx(r0, 2), hx(r1, 2), hx(r2, 2), hx(r3, 2)}
	for _, value in ipairs(source_context()) do values[#values + 1] = value end
	writes:write(csv(values) .. "\n")
	write_sequence = write_sequence + 1
	last_values[address] = written_value
end

local target_addresses = {0x0517, 0x0538, 0x0540, 0x0541}
local function attach()
	local context_header = "sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,cpu_pc,pc_prg_bank,address,old_value,new_value,a,x,y,p,sp,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000," .. CONTEXT_HEADER
	writes = output("shared_state_writes" .. suffix .. ".csv", context_header)
	frames = output("frame_state" .. suffix .. ".csv", "source_frame,emulator_frame,phase,cycle_from_frame_start,cycle_absolute," .. CONTEXT_HEADER)
	for _, address in ipairs(target_addresses) do
		local watched = address
		last_values[watched] = byte(watched)
		memory.registerwrite(watched, 1, function(_, _, value) log_write(watched, value) end)
	end
end
local function detach()
	for _, address in ipairs(target_addresses) do pcall(memory.registerwrite, address, 1, nil) end
	if writes then writes:flush(); writes:close(); writes = nil end
	if frames then frames:flush(); frames:close(); frames = nil end
end

metadata = output("metadata.txt")
local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
metadata:write("rom_md5=" .. tostring(md5) .. "\n")
metadata:write("opening_input=" .. OPENING_INPUT .. "\nroute_input=" .. ROUTE_INPUT .. "\n")
metadata:write("opening_input_sha256=" .. tostring(os.getenv("CT2_OPENING_INPUT_SHA256") or "") .. "\n")
metadata:write("route_input_sha256=" .. tostring(os.getenv("CT2_ROUTE_INPUT_SHA256") or "") .. "\n")
metadata:write("source_frames=0-" .. LAST_FRAME .. "\ninstrumented_source_frames=" .. FIRST_FRAME .. "-" .. LAST_FRAME .. "\n")
metadata:write("audio=muted with FCEUX --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy; no audio recorded\n")
metadata:write("watched_writes=$0517,$0538,$0540,$0541; caller context includes holder, player pointer, $052A/$0638, route flags, actor state, task selector, scroll, mapper\n")
metadata:write("checkpoint=anonymous in-memory state saved at source frame 8399; both replay passes verify full CPU RAM/PPU memory, MMC3 mapping, mapped bytes, frame and cycle; no numbered slot\n")
metadata:write("trace_files=shared_state_writes.csv, frame_state.csv and _repeat counterparts; diagnostic validation only\n")
metadata:flush()

local mmc3_copy = function(values)
	local copied = {}; for index, value in ipairs(values) do copied[index] = value end; return copied
end
memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value) mmc3[(mmc3_select % 8) + 1] = value or 0 end)

local startup_movie_mode = "unavailable"
pcall(function()
	startup_movie_mode = tostring(movie.mode())
	if movie.mode() ~= nil then pcall(movie.stop) end
end)
if type(movie.active) == "function" then
	local active = false; pcall(function() active = movie.active() end)
	if active then pcall(movie.stop) end
end
assert(tostring(movie.mode()) == "nil", "could not stop FCEUX startup movie")
assert(pcall(emu.poweron), "FCEUX poweron failed")
if type(debugger) == "table" and type(debugger.resetcyclescount) == "function" then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode, "turbo")
metadata:write("startup_movie_mode=" .. startup_movie_mode .. "\npoweron_success=true\n")
metadata:flush()
local function write_progress(value)
	local progress = assert(io.open(OUT .. "/progress.txt", "w"))
	progress:write(value)
	progress:close()
end
write_progress("warmup:0")

for frame = 0, CHECKPOINT_FRAME do
	current_source_frame = frame
	joypad.set(1, inputs[frame])
	frame_cycle_start = debugger.getcyclescount()
	emu.frameadvance()
	if frame % 120 == 0 or frame == CHECKPOINT_FRAME then write_progress("warmup:" .. frame) end
end

local checkpoint = savestate.create()
assert(checkpoint ~= nil, "FCEUX could not create anonymous in-memory state")
local function signature()
	local ram_ok, ram = pcall(function() return memory.readbyterange(0, 0x0800) end)
	local ppu_ok, ppu_mem = pcall(function() return ppu.readbyterange(0, 0x4000) end)
	assert(ram_ok and type(ram) == "string" and #ram == 0x0800, "could not capture full CPU RAM signature")
	assert(ppu_ok and type(ppu_mem) == "string" and #ppu_mem == 0x4000, "could not capture PPU memory signature")
	local r0, r1, r2, r3 = prg_map()
	return {frame=emu.framecount(), cycles=debugger.getcyclescount(), ram=ram, ppu=ppu_mem,
		select=mmc3_select, banks=mmc3_copy(mmc3), prg={r0, r1, r2, r3},
		mapped={byte(0x8000), byte(0xA000), byte(0xC000), byte(0xE000)}}
end
local saved_signature = signature()
assert(saved_signature.frame == CHECKPOINT_FRAME, "checkpoint is not at source/FCEUX frame 8399")
assert(pcall(savestate.save, checkpoint), "could not save anonymous in-memory checkpoint")
assert(pcall(savestate.persist, checkpoint), "could not keep anonymous checkpoint for repeated loads")
metadata:write("checkpoint_frame=" .. saved_signature.frame .. "\ncheckpoint_cycles=" .. saved_signature.cycles .. "\n")
metadata:write("checkpoint_mmc3_select=$" .. string.format("%02X", saved_signature.select) .. "\ncheckpoint_prg_banks=" .. table.concat(saved_signature.prg, ",") .. "\n")
metadata:write("checkpoint_signature=full 2KiB CPU RAM + 16KiB PPU memory + MMC3 registers/mapping/mapped bytes + frame/cycle\n")
metadata:flush()

local function verify_checkpoint(pass)
	local observed = signature()
	assert(observed.frame == saved_signature.frame and observed.cycles == saved_signature.cycles, "pass " .. pass .. " frame/cycle mismatch")
	assert(observed.ram == saved_signature.ram and observed.ppu == saved_signature.ppu, "pass " .. pass .. " full RAM/PPU signature mismatch")
	assert(observed.select == saved_signature.select, "pass " .. pass .. " MMC3 select mismatch")
	for index = 1, 8 do assert(observed.banks[index] == saved_signature.banks[index], "pass " .. pass .. " MMC3 bank mismatch") end
	for index = 1, 4 do assert(observed.prg[index] == saved_signature.prg[index] and observed.mapped[index] == saved_signature.mapped[index], "pass " .. pass .. " mapped PRG mismatch") end
end

for pass = 1, 2 do
	assert(pcall(savestate.load, checkpoint), "could not load anonymous checkpoint for pass " .. pass)
	mmc3_select = saved_signature.select
	mmc3 = mmc3_copy(saved_signature.banks)
	verify_checkpoint(pass)
	metadata:write("pass_" .. pass .. "_checkpoint_verified=true\n")
	suffix = pass == 1 and "" or "_repeat"
	write_sequence = 0
	last_values = {}
	attach()
	for frame = FIRST_FRAME, LAST_FRAME do
		current_source_frame = frame
		frame_cycle_start = debugger.getcyclescount()
		write_state_row("pre_frame")
		joypad.set(1, inputs[frame])
		emu.frameadvance()
		if frame == LAST_FRAME then
			current_source_frame = frame
			write_state_row("post_frame")
		end
		if frame % 30 == 0 or frame == LAST_FRAME then
			writes:flush(); frames:flush()
			write_progress(pass .. ":" .. frame)
		end
	end
	detach()
	metadata:write("pass_" .. pass .. "_write_count=" .. write_sequence .. "\n")
	metadata:flush()
end

metadata:write("complete=true\nreplay_passes=2 from same verified anonymous frame-8399 checkpoint\n")
metadata:write("completed_source_frames=" .. (LAST_FRAME + 1) .. "\n")
metadata:close()
pcall(memory.registerwrite, 0x8000, 1, nil)
pcall(memory.registerwrite, 0x8001, 1, nil)
os.exit()

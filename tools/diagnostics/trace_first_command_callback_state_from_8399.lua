-- Muted, bounded callback/scheduler trace for the fresh-start command route.
-- The script cold-replays only to a signature-checked anonymous state at
-- source frame 8399, then captures frames 8400-8953 twice. It never writes a
-- numbered FCEUX slot and emits diagnostic evidence only.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_CALLBACK_STATE_OUTPUT_DIR"), "missing output directory")
local LAST_FRAME = tonumber(os.getenv("CT2_CALLBACK_TRACE_LAST_FRAME")) or 8953
local CHECKPOINT_FRAME = tonumber(os.getenv("CT2_CALLBACK_TRACE_CHECKPOINT_FRAME")) or 8399
os.execute("mkdir -p " .. string.format("%q", OUT))

local function read_inputs(path, route_format)
	local result, first = {}, true
	local file = assert(io.open(path, "r"), "missing input file " .. path)
	for line in file:lines() do
		line = line:gsub("\r$", "")
		if first then first = false else
			local v = {}
			for value in (line .. ","):gmatch("(.-),") do v[#v + 1] = value end
			local frame = tonumber(v[1])
			if frame then
				local i = route_format and 3 or 2
				result[frame] = {up=v[i]=="1", down=v[i+1]=="1", left=v[i+2]=="1", right=v[i+3]=="1",
					A=v[i+4]=="1", B=v[i+5]=="1", start=v[i+6]=="1", select=v[i+7]=="1"}
			end
		end
	end
	file:close()
	return result
end

local inputs = read_inputs(OPENING_INPUT, false)
for frame, value in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = value end
for frame = 0, LAST_FRAME do assert(inputs[frame], "missing source input frame " .. frame) end

local function output(name, header)
	local f = assert(io.open(OUT .. "/" .. name, "w"))
	if header then f:write(header .. "\n") end
	return f
end
local function b(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return type(value) == "number" and value or 0
end
local function w(address) return b(address) + b(address + 1) * 256 end
local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return type(value) == "number" and value or -1
end
local function hx(value, digits)
	if type(value) ~= "number" or value < 0 then return "" end
	return string.format(digits == 2 and "$%02X" or "$%04X", value)
end
local function csv(fields)
	local values = {}
	for i, value in ipairs(fields) do values[i] = tostring(value == nil and "" or value):gsub(",", ";") end
	return table.concat(values, ",")
end

local mmc3_select, mmc3 = 0, {0,2,4,5,6,7,0,1}
local function prg_map()
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(mmc3_select / 64) % 2 == 0 then return r6, r7, 30, 31 end
	return 30, r7, r6, 31
end
local function bank(pc)
	if pc >= 0xE000 then return 31 elseif pc >= 0xC000 then return 30 end
	local r0, r1 = prg_map()
	if pc >= 0xA000 then return r1 elseif pc >= 0x8000 then return r0 end
	return -1
end

local metadata = output("metadata.txt")
metadata:write("source_frames=0-" .. LAST_FRAME .. "\ninstrumented_frames=8400-" .. LAST_FRAME .. "\n")
local rom_hash = "unavailable"
pcall(function() rom_hash = rom.gethash("sha256") or rom_hash end)
metadata:write("rom_sha256=" .. tostring(rom_hash) .. "\n")
metadata:write("emulator=FCEUX 2.7.0; NTSC; NewPPU; audio muted\n")
metadata:write("hooks=$CBB0/$C50F/$CAE7/$CA97/$CB0F/$CAF7/$814C/$81A7/$81BC/$8327; writes $05CC/$05CD/$05CE/$0524/$0525/$003A and task slots\n")
metadata:write("save_state=anonymous in-memory at source frame 8399, signature checked after both loads; no numbered slots\n")
metadata:flush()

local event_header = "sequence,pass,frame,emulator_frame,cycle_from_frame_start,cycle_absolute,kind,pc,prg_bank,a,x,y,p,scenario_0518,wait_0519,callback_0524,command_0525,animation_0528,parameter_0529,callback_ptr_0052,callback_ptr_0053,stream_index_003a,stream_bytes_0_2,global_05cc_05cd_05ce,scenario_pc_005d_005e,continuation_depth_0522,continuation_words_051a_0521,task_slots_0015_002c,sp,ready_latch_001b"
local write_header = "sequence,pass,frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc_after_write,prg_bank,address,old,new,a,x,y,p,scenario_0518,callback_0524,command_0525,stream_index_003a,global_05cc_05cd_05ce,task_slots_0015_002c,ready_latch_001b"

local frame_now, frame_cycle_start, pass_name, seq_event, seq_write = -1, -1, "", 0, 0
local events, writes
local function task_slots()
	local parts = {}
	for base = 0x15, 0x29, 4 do
		parts[#parts + 1] = string.format("%02X:%02X%02X%02X%02X", base,
			b(base), b(base + 1), b(base + 2), b(base + 3))
	end
	return table.concat(parts, "|")
end
local function continuation_words()
	local parts = {}
	for address = 0x051A, 0x0521 do parts[#parts + 1] = hx(b(address), 2) end
	return table.concat(parts, " ")
end
local function stream_bytes()
	local pointer = w(0x0052)
	if pointer < 0x8000 or pointer > 0xBFFD then return "" end
	local values = {}
	for offset = 0, 2 do values[#values + 1] = hx(b(pointer + offset), 2) end
	return table.concat(values, " ")
end
local function log_event(kind)
	local pc, a, x, y, p = reg("pc"), reg("a"), reg("x"), reg("y"), reg("p")
	local cycles, emu_frame = -1, -1
	pcall(function() cycles = debugger.getcyclescount() end)
	pcall(function() emu_frame = emu.framecount() end)
	local fields = {
		seq_event, pass_name, frame_now, emu_frame, cycles - frame_cycle_start, cycles,
		kind, hx(pc, 4), bank(pc), hx(a, 2), hx(x, 2), hx(y, 2), hx(p, 2),
		hx(b(0x0518), 2), hx(b(0x0519), 2), hx(b(0x0524), 2), hx(b(0x0525), 2),
		hx(b(0x0528), 2), hx(b(0x0529), 2), hx(b(0x0052), 2), hx(b(0x0053), 2),
		hx(b(0x003A), 2), stream_bytes(), hx(b(0x05CC), 2) .. " " .. hx(b(0x05CD), 2) .. " " .. hx(b(0x05CE), 2),
		hx(b(0x005D), 2) .. " " .. hx(b(0x005E), 2), hx(b(0x0522), 2), continuation_words(),
		task_slots(), hx(b(0x0100), 2), hx(b(0x001B), 2),
	}
	events:write(csv(fields) .. "\n")
	seq_event = seq_event + 1
end

local last_value = {}
local function log_write(address, new_value)
	local pc, a, x, y, p = reg("pc"), reg("a"), reg("x"), reg("y"), reg("p")
	local cycles, emu_frame = -1, -1
	pcall(function() cycles = debugger.getcyclescount() end)
	pcall(function() emu_frame = emu.framecount() end)
	local r0 = prg_map()
	writes:write(csv({seq_write, pass_name, frame_now, emu_frame,
		cycles - frame_cycle_start, cycles, hx(pc, 4), bank(pc), hx(address, 4),
		hx(last_value[address], 2), hx(new_value, 2), hx(a, 2), hx(x, 2), hx(y, 2), hx(p, 2),
		hx(b(0x0518), 2), hx(b(0x0524), 2), hx(b(0x0525), 2), hx(b(0x003A), 2),
		hx(b(0x05CC), 2) .. " " .. hx(b(0x05CD), 2) .. " " .. hx(b(0x05CE), 2),
		task_slots(), hx(b(0x001B), 2)}) .. "\n")
	seq_write = seq_write + 1
	last_value[address] = new_value
end

local pcs = {
	[0xCBB0] = "scenario_start_CBB0", [0xC50F] = "task_create_C50F",
	[0xCAE7] = "task_seed_CAE7", [0xCA97] = "scheduler_scan_CA97",
	[0xCB0F] = "task_yield_CB0F", [0xCAF7] = "task_finish_CAF7",
	[0x814C] = "callback_interpreter_814C", [0x81A7] = "callback_vector_81A7",
	[0x81BC] = "callback_control_81BC", [0x8327] = "map_placement_handler_8327",
}
local watched = {0x05CC, 0x05CD, 0x05CE, 0x0524, 0x0525, 0x003A,
	0x0015,0x0016,0x0017,0x0018, 0x0019,0x001A,0x001B,0x001C,
	0x001D,0x001E,0x001F,0x0020, 0x0021,0x0022,0x0023,0x0024,
	0x0025,0x0026,0x0027,0x0028, 0x0029,0x002A,0x002B,0x002C}
local function attach()
	for _, address in ipairs(watched) do
		local aa = address
		last_value[aa] = b(aa)
		memory.registerwrite(aa, 1, function(_, _, new_value) log_write(aa, new_value) end)
	end
	for address, name in pairs(pcs) do
		local aa, nn = address, name
		memory.registerexec(aa, function()
			local scenario = b(0x0518)
			if scenario == 0x35 or scenario == 0x36 or scenario == 0x1E or scenario == 0x44 then
				log_event(nn)
			end
		end)
	end
end
local function detach()
	for _, address in ipairs(watched) do pcall(memory.registerwrite, address, 1, nil) end
	for address in pairs(pcs) do pcall(memory.registerexec, address, nil) end
end

local function signature()
	local ram = memory.readbyterange(0, 0x800)
	local ppu_mem = ppu.readbyterange(0, 0x4000)
	local r0, r1 = prg_map()
	local banks = {}
	for i = 1, 8 do banks[i] = mmc3[i] end
	return {frame=emu.framecount(), cycles=debugger.getcyclescount(), ram=ram, ppu=ppu_mem,
		select=mmc3_select, banks=banks, prg={r0,r1,30,31},
		mapped={b(0x8000),b(0xA000),b(0xC000),b(0xE000)}}
end
local function verify(saved, label)
	local current = signature()
	assert(current.frame == saved.frame and current.cycles == saved.cycles, label .. " frame/cycle mismatch")
	assert(current.ram == saved.ram and current.ppu == saved.ppu, label .. " RAM/PPU mismatch")
	assert(current.select == saved.select, label .. " MMC3 selector mismatch")
	for i = 1, 8 do assert(current.banks[i] == saved.banks[i], label .. " MMC3 bank mismatch") end
	for i = 1, 4 do assert(current.prg[i] == saved.prg[i] and current.mapped[i] == saved.mapped[i], label .. " PRG map mismatch") end
end

local startup = "nil"
pcall(function() startup = tostring(movie.mode()); if movie.mode() ~= nil then pcall(movie.stop) end end)
if type(movie.active) == "function" then local active=false; pcall(function() active=movie.active() end); if active then pcall(movie.stop) end end
assert(tostring(movie.mode()) == "nil", "could not stop startup movie")
memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value) mmc3[(mmc3_select % 8) + 1] = value or 0 end)
assert(pcall(emu.poweron), "emu.poweron failed")
if debugger.resetcyclescount then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode, "turbo")
metadata:write("startup_movie_mode=" .. startup .. "\n")
metadata:flush()

local warmup_progress = assert(io.open(OUT .. "/progress.txt", "w"))
warmup_progress:write("before_warmup")
warmup_progress:close()
for frame = 0, CHECKPOINT_FRAME do
	joypad.set(1, inputs[frame])
	emu.frameadvance()
	if frame % 100 == 0 or frame == CHECKPOINT_FRAME then
		local progress = assert(io.open(OUT .. "/progress.txt", "w")); progress:write("warmup:" .. frame); progress:close()
	end
end
local checkpoint = savestate.create()
assert(checkpoint, "savestate.create failed")
local checkpoint_sig = signature()
assert(pcall(savestate.save, checkpoint), "savestate.save failed")
assert(pcall(savestate.persist, checkpoint), "savestate.persist failed")
metadata:write("checkpoint_frame=" .. checkpoint_sig.frame .. "\ncheckpoint_cycles=" .. checkpoint_sig.cycles .. "\ncheckpoint_signature=frame/cycle, RAM2KiB, PPU16KiB, MMC3 registers and mapped PRG bytes\n")
metadata:flush()

for pass = 1, 2 do
	assert(pcall(savestate.load, checkpoint), "savestate.load failed")
	mmc3_select = checkpoint_sig.select
	for i = 1, 8 do mmc3[i] = checkpoint_sig.banks[i] end
	verify(checkpoint_sig, "pass " .. pass)
	pass_name, seq_event, seq_write = tostring(pass), 0, 0
	events = output("callback_events" .. (pass == 1 and "" or "_repeat") .. ".csv", event_header)
	writes = output("callback_writes" .. (pass == 1 and "" or "_repeat") .. ".csv", write_header)
	attach()
	for frame = 8400, LAST_FRAME do
		frame_now = frame
		joypad.set(1, inputs[frame])
		frame_cycle_start = debugger.getcyclescount()
		emu.frameadvance()
		if frame % 50 == 0 or frame == LAST_FRAME then
			events:flush(); writes:flush()
			local progress = assert(io.open(OUT .. "/progress.txt", "w")); progress:write(pass .. ":" .. frame); progress:close()
		end
	end
	detach(); events:close(); writes:close()
	metadata:write("pass_" .. pass .. "_events=" .. seq_event .. "\npass_" .. pass .. "_writes=" .. seq_write .. "\n")
	metadata:flush()
end

metadata:write("complete=true\nreplays=2, same anonymous frame-8399 checkpoint\n")
metadata:close()
pcall(memory.registerwrite, 0x8000, 1, nil)
pcall(memory.registerwrite, 0x8001, 1, nil)
os.exit()

-- Muted same-input FCEUX PC/cycle trace for the F8 $00 helper-return route.
-- Run in FCEUX 2.7.0 with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy.

local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
local EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
local EXPECTED_ROM_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"
local LAST_SOURCE_FRAME = tonumber(os.getenv("CT2_LAST_SOURCE_FRAME")) or 3968
local run_id = os.date("%Y%m%d_%H%M%S")
local OUTPUT_DIR = PROJECT_ROOT .. "/reference/diagnostics/f8_helper_return_pc_cycle_audit_20261027/fceux_" .. run_id
os.execute("mkdir -p " .. string.format("%q", OUTPUT_DIR))

local inputs = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "missing source input timeline")
for line in input_file:lines() do
	line = line:gsub("\r$", "")
	local frame, up, down, left, right, a, b, start, select = line:match(
		"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if frame then
		inputs[tonumber(frame)] = {up=up=="1", down=down=="1", left=left=="1", right=right=="1",
			A=a=="1", B=b=="1", start=start=="1", select=select=="1"}
	end
end
input_file:close()
for frame=0,LAST_SOURCE_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local trace = assert(io.open(OUTPUT_DIR .. "/events.csv", "w"))
trace:write("sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,event,cpu_pc,opcode,a,x,y,sp,p,script_pointer,task_slot,mmc3_select,mmc3_r6,mmc3_r7,input_start\n")
local frames = assert(io.open(OUTPUT_DIR .. "/frame_cycles.csv", "w"))
frames:write("source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,input_up,input_down,input_left,input_right,input_a,input_b,input_start,input_select\n")
frames:flush()
local meta = assert(io.open(OUTPUT_DIR .. "/metadata.txt", "w"))

local rom_md5 = "unavailable"
pcall(function() rom_md5 = rom.gethash("md5") end)
assert(rom_md5 == EXPECTED_ROM_MD5, "wrong ROM MD5: " .. tostring(rom_md5))
local initial_movie_mode, initial_movie_name, movie_stop_result = "nil", "none", "no movie loaded"
pcall(function()
	initial_movie_mode = tostring(movie.mode())
	if movie.mode() ~= nil then
		initial_movie_name = tostring(movie.getname())
		local ok, err = pcall(movie.stop)
		movie_stop_result = tostring(ok) .. ":" .. tostring(err or "")
	end
end)
local pre_poweron_movie_mode = "unavailable"
pcall(function() pre_poweron_movie_mode = tostring(movie.mode()) end)
if pre_poweron_movie_mode ~= "nil" then
	local ok, err = pcall(movie.stop)
	movie_stop_result = tostring(ok) .. ":" .. tostring(err or "")
	pre_poweron_movie_mode = tostring(movie.mode())
end
assert(pre_poweron_movie_mode == "nil", "could not stop the FCEUX startup movie before power-on")
meta:write("rom_md5=" .. tostring(rom_md5) .. "\nrom_sha256_expected=" .. EXPECTED_ROM_SHA256 .. "\n")
meta:write("rom_path=" .. tostring(rom.getfilename()) .. "\ninput_timeline=" .. INPUT_CSV .. "\n")
meta:write("input_timeline_expected_sha256=" .. EXPECTED_INPUT_SHA256 .. "\nsource_frames=0-" .. LAST_SOURCE_FRAME .. "\n")
meta:write("startup_movie_mode=" .. initial_movie_mode .. "\nstartup_movie_name=" .. initial_movie_name .. "\nmovie_stop=" .. movie_stop_result .. "\n")
meta:write("audio=disabled with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy\n")
meta:write("hooks=$A53E,$98DC,$A54F,$895C,$A559,$880D,$8811,$8879,$84E7,$8508,$8514,$9FA8; MMC3 bank writes tracked\n")
meta:write("cycle_source=debugger.getcyclescount() at execute hooks and frame boundaries\noutput_dir=" .. OUTPUT_DIR .. "\n")
meta:flush()

local current_source_frame, cycle_start, sequence = -1, -1, 0
local mmc3_select, mmc3_regs = 0, {[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0}

local function reg(name)
	local ok, value = pcall(memory.getregister, name)
	if ok and type(value) == "number" then return value end
	return -1
end

local function byte(address)
	local ok, value = pcall(memory.readbyte, address)
	if ok and type(value) == "number" then return value end
	return -1
end

local function hex(value, digits)
	if value == nil or value < 0 then return "" end
	return string.format("$%0" .. digits .. "X", value % (2 ^ (digits * 4)))
end

local function record(pc)
	if current_source_frame < 0 then return end
	local cycle_abs = debugger.getcyclescount()
	local slot = byte(0x001E)
	local pointer = byte(0x004D) + 256 * byte(0x004E)
	local fields = {
		sequence, current_source_frame, emu.framecount(), cycle_abs-cycle_start, cycle_abs,
		"execute", hex(pc,4), hex(byte(pc),2), hex(reg("a"),2), hex(reg("x"),2),
		hex(reg("y"),2), hex(reg("s"),2), hex(reg("p"),2), hex(pointer,4),
		hex(slot,2), hex(mmc3_select,2), hex(mmc3_regs[6],2), hex(mmc3_regs[7],2),
		(inputs[current_source_frame] and inputs[current_source_frame].start) and 1 or 0,
	}
	trace:write(table.concat(fields, ",") .. "\n")
	sequence = sequence + 1
end

local watched_pcs = {0xA53E,0x98DC,0xA54F,0x895C,0xA559,0x880D,0x8811,0x8879,0x84E7,0x8508,0x8514,0x9FA8}
for _, address in ipairs(watched_pcs) do
	local hook_address = address
	memory.registerexec(hook_address, 1, function() record(hook_address) end)
end
memory.registerwrite(0x8000, 1, function(_, _, value)
	mmc3_select = value or 0
end)
memory.registerwrite(0x8001, 1, function(_, _, value)
	mmc3_regs[mmc3_select % 8] = value or 0
end)

local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "FCEUX poweron failed: " .. tostring(power_error))
local post_poweron_movie_mode, post_poweron_movie_stop = "unavailable", "no movie restarted"
local post_poweron_movie_active = false
pcall(function()
	post_poweron_movie_mode = tostring(movie.mode())
	if type(movie.active) == "function" then post_poweron_movie_active = movie.active() end
	if post_poweron_movie_mode ~= "nil" or post_poweron_movie_active then
		local ok, err = pcall(movie.stop)
		post_poweron_movie_stop = tostring(ok) .. ":" .. tostring(err or "")
		post_poweron_movie_mode = tostring(movie.mode())
		if type(movie.active) == "function" then post_poweron_movie_active = movie.active() end
	end
end)
assert(post_poweron_movie_mode == "nil" and not post_poweron_movie_active,
	"FCEUX movie restarted after power-on; refusing to measure cycles")
if type(debugger.resetcyclescount) == "function" then debugger.resetcyclescount() end
meta:write("poweron=true\npre_poweron_movie_mode=" .. pre_poweron_movie_mode .. "\n")
meta:write("post_poweron_movie_mode=" .. post_poweron_movie_mode .. "\npost_poweron_movie_stop=" .. post_poweron_movie_stop .. "\n")
meta:write("post_poweron_movie_active=" .. tostring(post_poweron_movie_active) .. "\n")
meta:write("cycle_counter_available=" .. tostring(type(debugger.getcyclescount)=="function") .. "\n")
meta:flush()
pcall(emu.speedmode, "maximum")

local input_timeline_applied_frames = 0
for frame=0,LAST_SOURCE_FRAME do
	current_source_frame = frame
	joypad.set(1, inputs[frame])
	-- Poll the input bridge each frame, but don't treat this as injection
	-- readback: joypad.get() reports physical controller state in this build.
	local _physical_pad = joypad.get(1)
	input_timeline_applied_frames = input_timeline_applied_frames + 1
	cycle_start = debugger.getcyclescount()
	local emu_before = emu.framecount()
	emu.frameadvance()
	local cycle_end = debugger.getcyclescount()
	local emu_after = emu.framecount()
	frames:write(table.concat({frame, emu_before, emu_after, cycle_start, cycle_end,
		cycle_end-cycle_start, inputs[frame].up and 1 or 0, inputs[frame].down and 1 or 0,
		inputs[frame].left and 1 or 0, inputs[frame].right and 1 or 0, inputs[frame].A and 1 or 0,
		inputs[frame].B and 1 or 0, inputs[frame].start and 1 or 0, inputs[frame].select and 1 or 0}, ",") .. "\n")
	if frame % 120 == 0 or frame == LAST_SOURCE_FRAME then
		trace:flush(); frames:flush()
		meta:write("progress_source_frame=" .. frame .. " emulator_frame=" .. emu_after ..
			" input_timeline_applied_frames=" .. input_timeline_applied_frames .. "\n")
		meta:flush()
	end
end

pcall(emu.speedmode, "normal")
meta:write("done_frames=" .. (LAST_SOURCE_FRAME+1) .. "\nevent_count=" .. sequence .. "\n")
meta:write("input_timeline_applied_frames=" .. input_timeline_applied_frames ..
	"\njoypad_get_polled=true\njoypad_get_used_for_button_readback=false\n")
trace:close(); frames:close(); meta:close()
for _, address in ipairs(watched_pcs) do pcall(memory.registerexec, address, 1, nil) end
pcall(memory.registerwrite, 0x8000, 1, nil)
pcall(memory.registerwrite, 0x8001, 1, nil)
os.exit()

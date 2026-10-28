-- Muted same-input FCEUX PC-cycle trace for all FD clear calls.
-- Run only when no other FCEUX/user session is active. No screenshots or audio.

local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
local EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
local EXPECTED_ROM_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"
local LAST_SOURCE_FRAME = 3476
local TARGET_FRAMES = {
	[810]=true, [1025]=true, [1525]=true, [1756]=true, [2117]=true,
	[2336]=true, [2685]=true, [2904]=true, [3469]=true,
	[3470]=true, [3471]=true, [3472]=true, [3473]=true, [3476]=true,
}
local EXEC_HOOKS = {
	[0x8855]="FD_handler", [0x88B1]="FD_fill_parameters",
	[0x885A]="FD_wait_call", [0x9FA8]="cooperative_yield",
	[0x885D]="FD_wait_resume", [0x8887]="FD_script_advance",
	[0x98E8]="fill_dispatch_entry", [0x98EC]="fade_gate_test",
	[0x992C]="direct_fill_entry", [0x9935]="rendering_off_store",
	[0x9942]="row_address_high_store", [0x9947]="row_address_low_store",
	[0x994C]="direct_fill_data_store", [0x9953]="direct_fill_loop_index",
	[0x996B]="rendering_restore_store",
	[0x98FC]="queued_row_reserve_call", [0x9909]="queued_fill_commit_call",
	[0x9B28]="queued_row_reserve", [0x9B5E]="queued_fill_commit",
	[0xA03C]="NMI_queue_consumer",
}

local run_id = os.date("%Y%m%d_%H%M%S")
local OUTPUT_DIR = PROJECT_ROOT .. "/reference/diagnostics/fd_scene_clear_fceux_cycles_" .. run_id
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
trace:write("sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,event,cpu_pc,a,x,y,script_pointer,fd_state,queue_count,input_start,ppu_scanline,ppu_dot\n")
local frames = assert(io.open(OUTPUT_DIR .. "/frame_cycles.csv", "w"))
frames:write("source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,input_start\n")
local meta = assert(io.open(OUTPUT_DIR .. "/metadata.txt", "w"))

local rom_md5 = "unavailable"
pcall(function() rom_md5 = rom.gethash("md5") end)
assert(rom_md5 == EXPECTED_ROM_MD5, "wrong ROM MD5: " .. tostring(rom_md5))
local startup_movie_mode, startup_movie_name, movie_stop_result = "nil", "none", "no movie loaded"
pcall(function()
	startup_movie_mode = tostring(movie.mode())
	if movie.mode() ~= nil then
		startup_movie_name = tostring(movie.getname())
		local ok, err = pcall(movie.stop)
		movie_stop_result = tostring(ok) .. ":" .. tostring(err or "")
	end
end)
meta:write("rom_md5=" .. tostring(rom_md5) .. "\nrom_sha256_expected=" .. EXPECTED_ROM_SHA256 .. "\n")
meta:write("rom_path=" .. tostring(rom.getfilename()) .. "\ninput_timeline=" .. INPUT_CSV .. "\ninput_timeline_expected_sha256=" .. EXPECTED_INPUT_SHA256 .. "\n")
meta:write("source_frames=0-" .. LAST_SOURCE_FRAME .. "\ntarget_frames=810,1025,1525,1756,2117,2336,2685,2904,3469-3473,3476\n")
meta:write("startup_movie_mode=" .. startup_movie_mode .. "\nstartup_movie_name=" .. startup_movie_name .. "\nmovie_stop=" .. movie_stop_result .. "\n")
meta:write("audio=disabled with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy\n")
meta:write("execution_hooks=" .. table.concat((function() local a={} for pc,name in pairs(EXEC_HOOKS) do a[#a+1]=string.format("$%04X:%s",pc,name) end table.sort(a) return a end)(), ",") .. "\n")
meta:write("cycle_source=debugger.getcyclescount() sampled in execution hooks and frame boundaries\noutput_dir=" .. OUTPUT_DIR .. "\n")
meta:flush()

local current_source_frame, cycle_start, sequence = -1, -1, 0
local function reg(name)
	local ok, value = pcall(memory.getregister, name)
	if ok and type(value) == "number" then return value end
	return -1
end
local function ppu_position()
	local line, dot = -1, -1
	pcall(function() line = ppu.getscanline() end)
	pcall(function() dot = ppu.getdot() end)
	return line or -1, dot or -1
end
local function record(kind, address)
	if not TARGET_FRAMES[current_source_frame] then return end
	local cycle_abs = debugger.getcyclescount()
	local line, dot = ppu_position()
	local script_pointer = memory.readbyte(0x004D) + memory.readbyte(0x004E) * 256
	local fields = {
		sequence, current_source_frame, emu.framecount(), cycle_abs-cycle_start, cycle_abs, kind,
		string.format("$%04X", reg("pc")), string.format("$%02X", reg("a") % 256),
		string.format("$%02X", reg("x") % 256), string.format("$%02X", reg("y") % 256),
		string.format("$%04X", script_pointer),
		string.format("$%02X/%02X/%02X/%02X/%02X/%02X/%02X", memory.readbyte(0x004F), memory.readbyte(0x0050),
			memory.readbyte(0x0054), memory.readbyte(0x004A), memory.readbyte(0x004B), memory.readbyte(0x00E6), memory.readbyte(0x00E7)),
		string.format("$%02X", memory.readbyte(0x0628)),
		(current_source_frame >= 0 and inputs[current_source_frame] and inputs[current_source_frame].start) and 1 or 0,
		line, dot,
	}
	trace:write(table.concat(fields, ",") .. "\n")
	sequence = sequence + 1
end

for address, name in pairs(EXEC_HOOKS) do
	local hook_address, event_name = address, name
	memory.registerexec(hook_address, function() record(event_name, hook_address) end)
end

local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "FCEUX poweron failed: " .. tostring(power_error))
local post_poweron_movie_mode = "nil"
local post_poweron_movie_stop = "no movie loaded"
pcall(function()
	post_poweron_movie_mode = tostring(movie.mode())
	if movie.mode() ~= nil then
		local ok, err = pcall(movie.stop)
		post_poweron_movie_stop = tostring(ok) .. ":" .. tostring(err or "")
	end
end)
if type(debugger.resetcyclescount) == "function" then debugger.resetcyclescount() end
meta:write("poweron=true\npost_poweron_movie_mode=" .. post_poweron_movie_mode .. "\npost_poweron_movie_stop=" .. post_poweron_movie_stop .. "\n")
meta:write("cycle_counter_available=" .. tostring(type(debugger.getcyclescount)=="function") .. "\n")
meta:flush()
pcall(emu.speedmode, "turbo")

for frame=0,LAST_SOURCE_FRAME do
	current_source_frame = frame
	joypad.set(1, inputs[frame])
	-- Readback pumps FCEUX's scripted-input bridge; the CSV hash and ordered
	-- emulator frame mapping remain the input provenance checks.
	pcall(joypad.get, 1)
	cycle_start = debugger.getcyclescount()
	local emu_before = emu.framecount()
	emu.frameadvance()
	local cycle_end = debugger.getcyclescount()
	local emu_after = emu.framecount()
	frames:write(table.concat({frame, emu_before, emu_after, cycle_start, cycle_end,
		cycle_end-cycle_start, inputs[frame].start and 1 or 0}, ",") .. "\n")
	if frame % 120 == 0 or frame == LAST_SOURCE_FRAME then
		trace:flush(); frames:flush()
		meta:write("progress_source_frame=" .. frame .. " emulator_frame=" .. emu_after .. "\n")
		meta:flush()
	end
end

pcall(emu.speedmode, "normal")
meta:write("done_frames=" .. (LAST_SOURCE_FRAME+1) .. "\nevent_count=" .. sequence .. "\n")
trace:close(); frames:close(); meta:close()
for address in pairs(EXEC_HOOKS) do pcall(memory.registerexec, address, nil) end
os.exit()

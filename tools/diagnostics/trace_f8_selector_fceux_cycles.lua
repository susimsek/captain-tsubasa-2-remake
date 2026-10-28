-- Muted same-input FCEUX trace for the F8 selector staging/copy instructions.
-- Run with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy.

local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
local EXPECTED_ROM_SHA256 = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
local EXPECTED_ROM_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"
local LAST_SOURCE_FRAME = tonumber(os.getenv("CT2_LAST_SOURCE_FRAME")) or 3597
local run_id = os.date("%Y%m%d_%H%M%S")
local OUTPUT_DIR = PROJECT_ROOT .. "/reference/diagnostics/f8_selector_fceux_cycles_" .. run_id
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
trace:write("sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,event,cpu_pc,a,x,y,ram_address,ram_value,input_start\n")
local frames = assert(io.open(OUTPUT_DIR .. "/frame_cycles.csv", "w"))
frames:write("source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,input_start\n")
frames:flush()
local meta = assert(io.open(OUTPUT_DIR .. "/metadata.txt", "w"))

local rom_md5 = "unavailable"
pcall(function() rom_md5 = rom.gethash("md5") end)
assert(rom_md5 == EXPECTED_ROM_MD5, "wrong ROM MD5: " .. tostring(rom_md5))
local initial_movie_mode = "nil"
local initial_movie_name = "none"
local movie_stop_result = "no movie loaded"
pcall(function()
	initial_movie_mode = tostring(movie.mode())
	if movie.mode() ~= nil then
		initial_movie_name = tostring(movie.getname())
		local ok, err = pcall(movie.stop)
		movie_stop_result = tostring(ok) .. ":" .. tostring(err or "")
	end
end)
meta:write("rom_md5=" .. tostring(rom_md5) .. "\nrom_sha256_expected=" .. EXPECTED_ROM_SHA256 .. "\n")
meta:write("rom_path=" .. tostring(rom.getfilename()) .. "\n")
meta:write("input_timeline=" .. INPUT_CSV .. "\ninput_timeline_expected_sha256=" .. EXPECTED_INPUT_SHA256 .. "\n")
meta:write("source_frames=0-" .. LAST_SOURCE_FRAME .. "\n")
meta:write("startup_movie_mode=" .. initial_movie_mode .. "\nstartup_movie_name=" .. initial_movie_name .. "\nmovie_stop=" .. movie_stop_result .. "\n")
meta:write("audio=disabled with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy\n")
meta:write("pc_hooks=$8B3F,$8B44,$8CA7,$8CAB; RAM writes=$75,$76,$8E,$8F,$90,$91\n")
meta:write("cycle_source=debugger.getcyclescount() sampled in execute/write hooks and at frame boundaries\n")
meta:write("output_dir=" .. OUTPUT_DIR .. "\n")
meta:flush()

local current_source_frame = -1
local cycle_start = -1
local sequence = 0

local function reg(name)
	local ok, value = pcall(memory.getregister, name)
	if ok and type(value) == "number" then return value end
	return -1
end

local function record(kind, address, value)
	local cycle_abs = debugger.getcyclescount()
	local pc = reg("pc")
	local ram_value = value
	if ram_value == nil then ram_value = memory.readbyte(address) end
	local fields = {
		sequence, current_source_frame, emu.framecount(), cycle_abs-cycle_start, cycle_abs, kind,
		string.format("$%04X", pc), string.format("$%02X", reg("a") % 256),
		string.format("$%02X", reg("x") % 256), string.format("$%02X", reg("y") % 256),
		string.format("$%04X", address), string.format("$%02X", (ram_value or 0) % 256),
		(current_source_frame >= 0 and inputs[current_source_frame] and inputs[current_source_frame].start) and 1 or 0,
	}
	trace:write(table.concat(fields, ",") .. "\n")
	sequence = sequence + 1
end

for _, address in ipairs({0x8B3F, 0x8B44, 0x8CA7, 0x8CAB}) do
	local hook_address = address
	memory.registerexec(hook_address, function() record("execute", hook_address) end)
end
for _, address in ipairs({0x0075, 0x0076, 0x008E, 0x008F, 0x0090, 0x0091}) do
	local watch_address = address
	memory.registerwrite(watch_address, 1, function(_, _, value)
		record("write", watch_address, value)
	end)
end

local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "FCEUX poweron failed: " .. tostring(power_error))
if type(debugger.resetcyclescount) == "function" then debugger.resetcyclescount() end
meta:write("poweron=true\ncycle_counter_available=" .. tostring(type(debugger.getcyclescount)=="function") .. "\n")
meta:flush()
pcall(emu.speedmode, "turbo")

for frame=0,LAST_SOURCE_FRAME do
	current_source_frame = frame
	joypad.set(1, inputs[frame])
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
for _, address in ipairs({0x8B3F, 0x8B44, 0x8CA7, 0x8CAB}) do pcall(memory.registerexec, address, 1, nil) end
for _, address in ipairs({0x0075, 0x0076, 0x008E, 0x008F, 0x0090, 0x0091}) do pcall(memory.registerwrite, address, 1, nil) end
os.exit()

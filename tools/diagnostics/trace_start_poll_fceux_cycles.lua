-- Muted FCEUX replay: cycle-tag the ROM Start poll/stop path in the saved input.
-- Launch in a separate FCEUX process with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy.

local PROJECT_ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local EXPECTED_INPUT_SHA256 = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
local LAST_SOURCE_FRAME = tonumber(os.getenv("CT2_LAST_SOURCE_FRAME")) or 4692
local run_id = os.date("%Y%m%d_%H%M%S")
local OUTPUT_DIR = PROJECT_ROOT .. "/reference/diagnostics/start_poll_fceux_cycles_" .. run_id
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
trace:write("sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,event,cpu_pc,a,x,y,ram_001e,ram_000d,ram_0700,input_start\n")
local frames = assert(io.open(OUTPUT_DIR .. "/frame_cycles.csv", "w"))
frames:write("source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,input_start\n")
frames:flush()
local meta = assert(io.open(OUTPUT_DIR .. "/metadata.txt", "w"))

local rom_md5 = "unavailable"
pcall(function() rom_md5 = rom.gethash("md5") end)
local initial_movie_mode = "nil"
local initial_movie_name = "none"
local movie_stop_result = "no movie loaded"
pcall(function()
	initial_movie_mode = tostring(movie.mode())
	if movie.mode() ~= nil then initial_movie_name = tostring(movie.getname()) end
	if movie.mode() ~= nil then
		local ok, err = pcall(movie.stop)
		movie_stop_result = tostring(ok) .. ":" .. tostring(err or "")
	end
end)
meta:write("rom_md5=" .. tostring(rom_md5) .. "\n")
meta:write("rom_path=" .. tostring(rom.getfilename()) .. "\n")
meta:write("input_timeline=" .. INPUT_CSV .. "\nsource_frames=0-" .. LAST_SOURCE_FRAME .. "\n")
meta:write("input_timeline_expected_sha256=" .. EXPECTED_INPUT_SHA256 .. "\n")
meta:write("startup_movie_mode=" .. initial_movie_mode .. "\nstartup_movie_name=" .. initial_movie_name .. "\nmovie_stop=" .. movie_stop_result .. "\n")
meta:write("audio=disabled with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy\n")
meta:write("hooks=PC execute $802C,$8030,$8032,$8048; RAM write $0700\n")
meta:write("cycle_source=debugger.getcyclescount() sampled inside hook and at each frame boundary\n")
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

local function record(kind, address)
	local cycle_abs = debugger.getcyclescount()
	local frame = emu.framecount()
	local pc = reg("pc")
	local values = {
		sequence, current_source_frame, frame, cycle_abs-cycle_start, cycle_abs, kind,
		string.format("$%04X", address), string.format("$%02X", reg("a") % 256),
		string.format("$%02X", reg("x") % 256), string.format("$%02X", reg("y") % 256),
		string.format("$%02X", memory.readbyte(0x001E)), string.format("$%02X", memory.readbyte(0x000D)),
		string.format("$%02X", memory.readbyte(0x0700)),
		(current_source_frame >= 0 and inputs[current_source_frame] and inputs[current_source_frame].start) and 1 or 0,
	}
	trace:write(table.concat(values, ",") .. "\n")
	sequence = sequence + 1
end

local pc_hooks = {0x802C, 0x8030, 0x8032, 0x8048}
for _, address in ipairs(pc_hooks) do
	local hook_address = address
	memory.registerexec(hook_address, function() record("execute", hook_address) end)
end
memory.registerwrite(0x0700, 1, function(address, _, value)
	record(string.format("write_%04X_%02X", address, value or 0), address)
end)

local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "FCEUX poweron failed: " .. tostring(power_error))
if type(debugger.resetcyclescount) == "function" then debugger.resetcyclescount() end
meta:write("poweron=true\ncycle_counter_available=" .. tostring(type(debugger.getcyclescount)=="function") .. "\n")
meta:flush()
pcall(emu.speedmode, "turbo")
meta:write("frame_loop_started=true\n")
meta:flush()

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
for _, address in ipairs(pc_hooks) do pcall(memory.registerexec, address, 1, nil) end
pcall(memory.registerwrite, 0x0700, 1, nil)
os.exit()

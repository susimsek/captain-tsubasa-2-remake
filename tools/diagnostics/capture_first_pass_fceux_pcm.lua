-- One-pass FCEUX PCM validation capture for the recorded route through frame 9600.
-- Launch with sound enabled, --soundrecord, and SDL_AUDIODRIVER=dummy. This
-- writes only trace metadata; FCEUX WAV output is validation evidence, never a
-- Godot runtime asset.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OUT = assert(os.getenv("CT2_FIRST_PASS_PCM_OUTPUT_DIR"), "missing output directory")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local ACTION_EDGES = ROOT .. "/reference/diagnostics/first_pass_action_input_edges_20261110.csv"
local FIRST_PASS_SOURCE_FRAME, LAST_SOURCE_FRAME = 9043, 9600
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
				local index = route_format and 3 or 2
				result[frame] = {
					up = values[index] == "1", down = values[index + 1] == "1",
					left = values[index + 2] == "1", right = values[index + 3] == "1",
					A = values[index + 4] == "1", B = values[index + 5] == "1",
					start = values[index + 6] == "1", select = values[index + 7] == "1",
				}
			end
		end
	end
	file:close()
	return result
end

local inputs = read_inputs(OPENING_INPUT, false)
for frame, pad in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = pad end
for frame = 0, 9042 do assert(inputs[frame], "missing source input frame " .. frame) end

local edges = {}
do
	local file = assert(io.open(ACTION_EDGES, "r"), "missing first-PASS action edge file")
	local first = true
	for line in file:lines() do
		line = line:gsub("\r$", "")
		if first then first = false else
			local values = {}
			for value in (line .. ","):gmatch("(.-),") do values[#values + 1] = value end
			local frame, button, pressed = tonumber(values[1]), values[2], values[3]
			assert(frame and button and (pressed == "0" or pressed == "1"), "malformed action edge")
			edges[frame] = edges[frame] or {}
			edges[frame][button] = pressed == "1"
		end
	end
	file:close()
end

local button_keys = {
	Up = "up", Down = "down", Left = "left", Right = "right",
	A = "A", B = "B", Start = "start", Select = "select",
}
local function copy_pad(pad)
	local copy = {}
	for key, value in pairs(pad) do copy[key] = value end
	return copy
end
local carried = copy_pad(inputs[9042])
for frame = FIRST_PASS_SOURCE_FRAME, LAST_SOURCE_FRAME do
	for button, pressed in pairs(edges[frame] or {}) do
		local key = assert(button_keys[button], "unknown button in action edges: " .. button)
		carried[key] = pressed
	end
	inputs[frame] = copy_pad(carried)
end
for frame in pairs(edges) do assert(frame <= LAST_SOURCE_FRAME, "unexpected edge beyond frame 9600") end

local frames = assert(io.open(OUT .. "/frame_cycles.csv", "w"))
frames:write("source_frame,script_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,lagged,up,down,left,right,A,B,start,select\n")
local metadata = assert(io.open(OUT .. "/fceux_trace.txt", "w"))
local progress = assert(io.open(OUT .. "/progress.txt", "w"))
local function set_progress(value)
	progress:close()
	progress = assert(io.open(OUT .. "/progress.txt", "w"))
	progress:write(value .. "\n")
	progress:flush()
end
local function bit(value) return value and "1" or "0" end

local startup_movie = "nil"
pcall(function()
	startup_movie = tostring(movie.mode())
	if movie.mode() ~= nil then pcall(movie.stop) end
end)
if type(movie.active) == "function" then
	local active = false
	pcall(function() active = movie.active() end)
	if active then pcall(movie.stop) end
end
assert(tostring(movie.mode()) == "nil", "could not stop an auto-loaded startup movie")
assert(type(debugger) == "table" and type(debugger.getcyclescount) == "function",
	"FCEUX cycle counter API is unavailable")
local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "emu.poweron failed: " .. tostring(power_error))
pcall(debugger.resetcyclescount)
local cycle_origin = debugger.getcyclescount()
local initial_frame = emu.framecount()
local rom_md5 = "unavailable"
pcall(function() rom_md5 = rom.gethash("md5") end)
metadata:write("emulator=FCEUX 2.7.0\nrom_md5=" .. tostring(rom_md5)
	.. "\nstartup_movie_mode=" .. startup_movie
	.. "\nsource_frames=0-9600 inclusive\nsource_frame_zero_drives_first_frameadvance=true"
	.. "\ninitial_emulator_frame=" .. tostring(initial_frame)
	.. "\ncycle_counter_reset_immediately_after_poweron=true"
	.. "\ncycle_counter_origin=" .. tostring(cycle_origin)
	.. "\ninput_sources=opening_reference_capture/input_timeline.csv; kickoff_select_test_20261027/post_title_inputs.csv; first_pass_action_input_edges_20261110.csv"
	.. "\ninput_frame_mapping=source frame N is supplied before Nth frameadvance; edge inputs are carried forward through 9600"
	.. "\naudio=FCEUX --sound 1 --volume 256 --soundrate 44100 --soundq 2 --soundrecord; SDL_AUDIODRIVER=dummy"
	.. "\nroute=replayed once from power-on; no savestate, checkpoint, second replay, screenshot, or WAV extraction"
	.. "\npcm_origin=must be reconciled from finalized WAV sample count and these cycle boundaries; no fixed startup offset is assumed"
	.. "\nvalidation_only=true\nruntime_asset=false\n")
metadata:flush()

-- Do not use turbo: FCEUX may bypass sound processing in turbo mode. The dummy
-- SDL device keeps normal-speed output inaudible while --soundrecord remains on.
pcall(emu.speedmode, "normal")
local mapping_mismatches, frame_rows = 0, 0
local first_cycle, last_cycle = nil, nil
for source_frame = 0, LAST_SOURCE_FRAME do
	local script_frame = source_frame + 1
	local pad = inputs[source_frame]
	assert(pad, "missing replay input for source frame " .. source_frame)
	joypad.set(1, pad)
	local cycle_start = debugger.getcyclescount()
	local frame_before = emu.framecount()
	emu.frameadvance()
	local cycle_end = debugger.getcyclescount()
	local frame_after = emu.framecount()
	local lagged = false
	pcall(function() lagged = emu.lagged() end)
	local mapping_matches = frame_after == source_frame
	if not mapping_matches then mapping_mismatches = mapping_mismatches + 1 end
	if first_cycle == nil then first_cycle = cycle_start end
	last_cycle = cycle_end
	frames:write(table.concat({
		tostring(source_frame), tostring(script_frame), tostring(frame_before), tostring(frame_after),
		tostring(cycle_start), tostring(cycle_end), tostring(cycle_end - cycle_start), bit(lagged),
		bit(pad.up), bit(pad.down), bit(pad.left), bit(pad.right), bit(pad.A), bit(pad.B),
		bit(pad.start), bit(pad.select),
	}, ",") .. "\n")
	frame_rows = frame_rows + 1
	if source_frame % 100 == 0 or source_frame == LAST_SOURCE_FRAME then
		frames:flush()
		set_progress(string.format("source_frame=%d emulator_frame=%d cycles=%d", source_frame, frame_after, cycle_end))
	end
end

local complete = frame_rows == LAST_SOURCE_FRAME + 1 and mapping_mismatches == 0
metadata:write("frame_rows=" .. tostring(frame_rows)
	.. "\nframe_mapping_mismatches=" .. tostring(mapping_mismatches)
	.. "\nfirst_frame_cycle_start=" .. tostring(first_cycle)
	.. "\nlast_frame_cycle_end=" .. tostring(last_cycle)
	.. "\nelapsed_cycles=" .. tostring((last_cycle or 0) - (first_cycle or 0))
	.. "\ncomplete=" .. tostring(complete) .. "\nendpoint_source_frame=" .. tostring(LAST_SOURCE_FRAME)
	.. "\n")
metadata:flush()
frames:close()
metadata:close()
progress:close()
if not complete then
	emu.exit()
	return
end
emu.exit()

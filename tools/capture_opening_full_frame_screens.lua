-- Full-frame FCEUX screen reference for validation only.
-- Run with --sound 0 --volume 0 and the supplied Turkish ROM. This never
-- copies captured pixels into the Godot runtime.

local PROJECT_ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local LAST_SOURCE_FRAME = 4692

local run_id = os.date("%Y%m%d_%H%M%S")
local root = PROJECT_ROOT .. "/reference/opening_full_frame_capture_" .. run_id
local screens = root .. "/unique_screens"
os.execute("mkdir -p " .. string.format("%q", screens))

local function open_output(name, header)
	local file = assert(io.open(root .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	file:flush()
	return file
end

local function write_binary(path, bytes)
	local file, err = io.open(path, "wb")
	if not file then error("cannot write " .. path .. ": " .. tostring(err)) end
	file:write(bytes)
	file:close()
end

local input_timeline = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "cannot open recorded input timeline")
input_file:read("*l")
for line in input_file:lines() do
	line = line:gsub("\r$", "")
	local frame, up, down, left, right, a, b, start, select = line:match(
		"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if frame then
		input_timeline[tonumber(frame)] = {
			up = tonumber(up) == 1, down = tonumber(down) == 1,
			left = tonumber(left) == 1, right = tonumber(right) == 1,
			A = tonumber(a) == 1, B = tonumber(b) == 1,
			start = tonumber(start) == 1, select = tonumber(select) == 1,
		}
	end
end
input_file:close()
for source_frame = 0, LAST_SOURCE_FRAME do
	assert(input_timeline[source_frame] ~= nil,
		"input timeline is missing source frame " .. source_frame)
end

local index = open_output("screen_index.csv",
	"source_frame,emulator_frame_after,mapping_matches_source_frame,raw_screen_file,changed")
local log = open_output("capture.log")
local power_ok, power_error = pcall(emu.poweron)
log:write("START clean_power_cycle=" .. tostring(power_ok)
	.. " max_source_frame=" .. LAST_SOURCE_FRAME .. " sound=disabled_by_command_line\n")
if not power_ok then log:write("POWER_ERROR " .. tostring(power_error) .. "\n") end
log:flush()
pcall(emu.speedmode, "turbo")

local previous_screen = nil
local previous_file = ""
local saved_unique = 0
for source_frame = 0, LAST_SOURCE_FRAME do
	joypad.set(1, input_timeline[source_frame])
	emu.frameadvance()
	local emulator_frame_after = emu.framecount()
	local mapping_matches = emulator_frame_after == source_frame
	local raw_screen = gui.gdscreenshot()
	if type(raw_screen) ~= "string" then
		log:write("ERROR source_frame=" .. source_frame .. " screenshot unavailable\n")
		log:flush()
		break
	end
	local changed = raw_screen ~= previous_screen
	if changed then
		previous_file = string.format("frame_%06d.gd", source_frame)
		write_binary(screens .. "/" .. previous_file, raw_screen)
		previous_screen = raw_screen
		saved_unique = saved_unique + 1
	end
	index:write(table.concat({source_frame, emulator_frame_after,
		mapping_matches and 1 or 0, previous_file, changed and 1 or 0}, ",") .. "\n")
	if not mapping_matches then
		log:write(string.format("FRAME_MAPPING_MISMATCH source=%d emulator_after=%d\n",
			source_frame, emulator_frame_after))
	end
	if source_frame % 120 == 0 then
		index:flush(); log:flush()
		log:write(string.format("CAPTURED source_frame=%d unique_screens=%d\n",
			source_frame, saved_unique))
	end
end

pcall(emu.speedmode, "normal")
log:write(string.format("DONE source_frames=%d unique_screens=%d\n",
	LAST_SOURCE_FRAME + 1, saved_unique))
log:flush(); index:flush(); log:close(); index:close()
os.exit(0)

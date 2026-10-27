-- Probe title-menu controls through FCEUX's emulator-native Lua joypad API.
-- Run this only when the game is sitting on the title menu. This script does
-- not read ROM bytes and records the exact synthetic input it applies.

local root = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe/reference/title_input_probe"
local ppu_dir, ram_dir, screens = root .. "/ppu_states", root .. "/ram_states", root .. "/screens"
os.execute("mkdir -p " .. string.format("%q", ppu_dir) .. " " .. string.format("%q", ram_dir) .. " " .. string.format("%q", screens))

local function output(name, header)
	local file = assert(io.open(root .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	file:flush()
	return file
end

local function save_binary(folder, name, bytes)
	local file, err = io.open(folder .. "/" .. name, "wb")
	if not file then error(err) end
	file:write(bytes)
	file:close()
end

local function applied_button(frame)
	-- Give each candidate button a 12-frame press, separated by 48 released frames.
	local groups = {
		{first = 1, last = 12, button = "start"},
		{first = 61, last = 72, button = "A"},
		{first = 121, last = 132, button = "B"},
		{first = 181, last = 192, button = "start"},
	}
	for _, group in ipairs(groups) do
		if frame >= group.first and frame <= group.last then return group.button end
	end
	return ""
end

local function pad_for(button)
	return {
		up = false, down = false, left = false, right = false,
		A = button == "A", B = button == "B",
		start = button == "start", select = false,
	}
end

local inputs = output("input_timeline.csv", "script_frame,emulator_frame,synthetic_button")
local ppu_index = output("ppu_index.csv", "emulator_frame,raw_file,bytes")
local ram_index = output("ram_index.csv", "emulator_frame,raw_file,bytes")
local screen_index = output("screen_index.csv", "emulator_frame,raw_file")
local log = output("capture.log")
local previous_ppu, previous_ram, previous_screen
local ppu_count, ram_count, screen_count = 0, 0, 0

for frame = 1, 300 do
	local button = applied_button(frame)
	joypad.set(1, pad_for(button))
	emu.frameadvance()
	local emulator_frame = emu.framecount()
	inputs:write(table.concat({frame, emulator_frame, button}, ",") .. "\n")

	local ppu_bytes = ppu.readbyterange(0x0000, 0x2000)
		.. ppu.readbyterange(0x2000, 0x1000)
		.. ppu.readbyterange(0x3F00, 0x20)
	if ppu_bytes ~= previous_ppu then
		previous_ppu = ppu_bytes
		ppu_count = ppu_count + 1
		local name = string.format("ppu_%05d.bin", ppu_count)
		save_binary(ppu_dir, name, ppu_bytes)
		ppu_index:write(table.concat({emulator_frame, name, #ppu_bytes}, ",") .. "\n")
	end

	local ram_bytes = memory.readbyterange(0, 0x0800)
	if ram_bytes ~= previous_ram then
		previous_ram = ram_bytes
		ram_count = ram_count + 1
		local name = string.format("ram_%05d.bin", ram_count)
		save_binary(ram_dir, name, ram_bytes)
		ram_index:write(table.concat({emulator_frame, name, #ram_bytes}, ",") .. "\n")
	end

	local gd = gui.gdscreenshot()
	if gd and gd ~= previous_screen then
		previous_screen = gd
		screen_count = screen_count + 1
		local name = string.format("frame_%05d.gd", emulator_frame)
		save_binary(screens, name, gd)
		screen_index:write(emulator_frame .. "," .. name .. "\n")
	end
	if frame % 30 == 0 then
		log:write(string.format("script_frame=%d emulator_frame=%d input=%s ppu_states=%d ram_states=%d screenshots=%d\n", frame, emulator_frame, button, ppu_count, ram_count, screen_count))
		log:flush(); inputs:flush(); ppu_index:flush(); ram_index:flush(); screen_index:flush()
	end
end

log:write(string.format("DONE emulator_frame=%d ppu_states=%d ram_states=%d screenshots=%d\n", emu.framecount(), ppu_count, ram_count, screen_count))
log:flush()
log:close(); inputs:close(); ppu_index:close(); ram_index:close(); screen_index:close()

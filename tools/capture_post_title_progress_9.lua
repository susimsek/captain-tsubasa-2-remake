-- Continue the current post-KICKOFF story sequence and record controller
-- presses plus emulator-native visual/memory observations for 900 frames.
-- Run only with the game at the story/dialogue screen. No ROM bytes are read.

local root = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe/reference/post_title_progress_9"
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

local function pulse(frame)
	-- One 12-frame A press every 150 frames to advance story pages without
	-- holding through several screens. This cadence is explicitly logged.
	local phase = (frame - 1) % 150
	return phase < 12
end
local function input_for_a(is_down)
	return {
		up = false, down = false, left = false, right = false,
		A = is_down, B = false, start = false, select = false,
	}
end

local input_log = output("input_timeline.csv", "script_frame,emulator_frame,A")
local ppu_index = output("ppu_index.csv", "emulator_frame,raw_file,bytes")
local ram_index = output("ram_index.csv", "emulator_frame,raw_file,bytes")
local screen_index = output("screen_index.csv", "emulator_frame,raw_file")
local log = output("capture.log")
local first = emu.framecount()
log:write("START emulator_frame=" .. tostring(first) .. " cadence=12_on_150_off\n")
pcall(function() emu.speedmode("maximum") end)

local previous_ppu, previous_ram, previous_screen
local ppu_count, ram_count, screen_count = 0, 0, 0
for frame = 1, 1800 do
	local a_down = pulse(frame)
	joypad.set(1, input_for_a(a_down))
	emu.frameadvance()
	local emulator_frame = emu.framecount()
	input_log:write(table.concat({frame, emulator_frame, a_down and 1 or 0}, ",") .. "\n")
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
	if frame % 3 == 0 or a_down then
		local gd = gui.gdscreenshot()
		if gd and gd ~= previous_screen then
			previous_screen = gd
			local name = string.format("frame_%06d.gd", emulator_frame)
			save_binary(screens, name, gd)
			screen_index:write(emulator_frame .. "," .. name .. "\n")
			screen_count = screen_count + 1
		end
	end
	if frame % 150 == 0 then
		log:write(string.format("script_frame=%d emulator_frame=%d A=%s ppu=%d ram=%d screens=%d\n", frame, emulator_frame, tostring(a_down), ppu_count, ram_count, screen_count))
		log:flush(); input_log:flush(); ppu_index:flush(); ram_index:flush(); screen_index:flush()
	end
end
pcall(function() emu.speedmode("normal") end)
log:write(string.format("DONE emulator_frame=%d ppu=%d ram=%d screens=%d\n", emu.framecount(), ppu_count, ram_count, screen_count))
log:flush()
log:close(); input_log:close(); ppu_index:close(); ram_index:close(); screen_index:close()

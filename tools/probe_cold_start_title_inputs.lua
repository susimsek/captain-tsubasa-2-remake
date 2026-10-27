-- Cold-start to the observed title frame, then test NES Start/A/B controls.
-- Based on prior emulator observation, the title is present by frame 4692.
-- PPU/RAM/screens are FCEUX-side observations; no ROM bytes are read.

local root = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe/reference/cold_start_title_input_probe"
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

local function active_button(frame)
	local phases = {
		{start = 4700, stop = 4711, button = "start"},
		{start = 4760, stop = 4771, button = "A"},
		{start = 4820, stop = 4831, button = "B"},
		{start = 4880, stop = 4891, button = "start"},
	}
	for _, phase in ipairs(phases) do
		if frame >= phase.start and frame <= phase.stop then return phase.button end
	end
	return ""
end
local function input_for(button)
	return {
		up = false, down = false, left = false, right = false,
		A = button == "A", B = button == "B",
		start = button == "start", select = false,
	}
end

local inputs = output("input_timeline.csv", "frame,synthetic_button")
local ppu_index = output("ppu_index.csv", "frame,raw_file,bytes")
local ram_index = output("ram_index.csv", "frame,raw_file,bytes")
local screen_index = output("screen_index.csv", "frame,raw_file")
local log = output("capture.log")
local ok, err = pcall(emu.poweron)
log:write("POWER_ON success=" .. tostring(ok) .. (err and (" error=" .. tostring(err)) or "") .. "\n")
log:flush()
local previous_ppu, previous_ram, previous_screen
local ppu_count, ram_count, screen_count = 0, 0, 0

for frame = 1, 4920 do
	local button = active_button(frame)
	joypad.set(1, input_for(button))
	emu.frameadvance()
	if frame >= 4500 then
		inputs:write(frame .. "," .. button .. "\n")
		local ppu_bytes = ppu.readbyterange(0x0000, 0x2000)
			.. ppu.readbyterange(0x2000, 0x1000)
			.. ppu.readbyterange(0x3F00, 0x20)
		if ppu_bytes ~= previous_ppu then
			previous_ppu = ppu_bytes
			ppu_count = ppu_count + 1
			local name = string.format("ppu_%05d.bin", ppu_count)
			save_binary(ppu_dir, name, ppu_bytes)
			ppu_index:write(table.concat({frame, name, #ppu_bytes}, ",") .. "\n")
		end
		local ram_bytes = memory.readbyterange(0, 0x0800)
		if ram_bytes ~= previous_ram then
			previous_ram = ram_bytes
			ram_count = ram_count + 1
			local name = string.format("ram_%05d.bin", ram_count)
			save_binary(ram_dir, name, ram_bytes)
			ram_index:write(table.concat({frame, name, #ram_bytes}, ",") .. "\n")
		end
		local gd = gui.gdscreenshot()
		if gd and gd ~= previous_screen then
			previous_screen = gd
			local name = string.format("frame_%05d.gd", frame)
			save_binary(screens, name, gd)
			screen_index:write(frame .. "," .. name .. "\n")
			screen_count = screen_count + 1
		end
	end
	if frame % 120 == 0 then
		log:write(string.format("frame=%d button=%s ppu_states=%d ram_states=%d screens=%d\n", frame, button, ppu_count, ram_count, screen_count))
		log:flush(); inputs:flush(); ppu_index:flush(); ram_index:flush(); screen_index:flush()
	end
end
log:write(string.format("DONE frame=%d ppu_states=%d ram_states=%d screens=%d\n", emu.framecount(), ppu_count, ram_count, screen_count))
log:flush(); log:close(); inputs:close(); ppu_index:close(); ram_index:close(); screen_index:close()

-- Capture the title-to-selection transition from the current FCEUX state.
-- The first frame presses the original NES A button once; later input is released.
-- No ROM bytes are inspected or copied. Exact PPU and CPU RAM dumps stay untouched.

local root = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe/reference/title_selection_capture"
local states = root .. "/ppu_states"
local ram_states = root .. "/ram_states"
local screens = root .. "/screens"
os.execute("mkdir -p " .. string.format("%q", states) .. " " .. string.format("%q", ram_states) .. " " .. string.format("%q", screens))

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

local ppu_index = output("ppu_index.csv", "frame,raw_file,bytes")
local ram_index = output("ram_index.csv", "frame,raw_file,bytes")
local screen_index = output("screen_index.csv", "frame,raw_file")
local input_log = output("input_timeline.csv", "frame,up,down,left,right,A,B,start,select")
local log = output("capture.log")

local function bit(pad, key)
	return pad and pad[key] and 1 or 0
end

local previous_ppu
local previous_ram
local previous_screen
local ppu_count = 0
local frame_count = 0

for frame = 1, 1800 do
	if frame == 1 then
		joypad.set(1, {A = true})
	else
		joypad.set(1, {A = false})
	end
	emu.frameadvance()
	frame_count = emu.framecount()
	local pad = joypad.read(1)
	input_log:write(table.concat({frame_count, bit(pad, "up"), bit(pad, "down"), bit(pad, "left"), bit(pad, "right"), bit(pad, "A"), bit(pad, "B"), bit(pad, "start"), bit(pad, "select")}, ",") .. "\n")

	local ppu_bytes = ppu.readbyterange(0x0000, 0x2000)
		.. ppu.readbyterange(0x2000, 0x1000)
		.. ppu.readbyterange(0x3F00, 0x20)
	if ppu_bytes ~= previous_ppu then
		previous_ppu = ppu_bytes
		ppu_count = ppu_count + 1
		local name = string.format("ppu_%05d.bin", ppu_count)
		save_binary(states, name, ppu_bytes)
		ppu_index:write(table.concat({frame_count, name, #ppu_bytes}, ",") .. "\n")
	end

	local ram_bytes = memory.readbyterange(0, 0x0800)
	if ram_bytes ~= previous_ram then
		previous_ram = ram_bytes
		local name = string.format("ram_%05d.bin", frame_count)
		save_binary(ram_states, name, ram_bytes)
		ram_index:write(table.concat({frame_count, name, #ram_bytes}, ",") .. "\n")
	end

	if frame % 2 == 0 then
		local gd = gui.gdscreenshot()
		if gd and gd ~= previous_screen then
			previous_screen = gd
			local name = string.format("frame_%05d.gd", frame_count)
			save_binary(screens, name, gd)
			screen_index:write(frame_count .. "," .. name .. "\n")
		end
	end

	if frame % 120 == 0 then
		log:write("CAPTURED frames=" .. frame .. " ppu_states=" .. ppu_count .. "\n")
		log:flush(); ppu_index:flush(); ram_index:flush(); screen_index:flush(); input_log:flush()
	end
end

log:write("DONE frame=" .. tostring(frame_count) .. " ppu_states=" .. ppu_count .. "\n")
log:flush()
log:close(); ppu_index:close(); ram_index:close(); screen_index:close(); input_log:close()

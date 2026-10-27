-- Clean, manually controlled reference capture from an emulator power cycle.
-- All original data is written as exact FCEUX-side dumps. No ROM parsing.
-- Keep FCEUX's speaker output muted while this script is running.

local root = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe/reference/opening_reference_capture"
local screens = root .. "/screens"
local ppu_dir = root .. "/ppu_states"
local ram_dir = root .. "/ram_states"
os.execute("mkdir -p " .. string.format("%q", screens) .. " " .. string.format("%q", ppu_dir) .. " " .. string.format("%q", ram_dir))

local function output(name, header)
	local file = assert(io.open(root .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	file:flush()
	return file
end

local function write_binary(folder, name, bytes)
	local file, err = io.open(folder .. "/" .. name, "wb")
	if not file then error(err) end
	file:write(bytes)
	file:close()
end

local function button(pad, name)
	return pad and pad[name] and 1 or 0
end

local log = output("capture.log")
local ppu_index = output("ppu_index.csv", "frame,raw_file,bytes")
local ram_index = output("ram_index.csv", "frame,raw_file,bytes")
local screen_index = output("screen_index.csv", "frame,raw_file")
local inputs = output("input_timeline.csv", "frame,up,down,left,right,A,B,start,select")
local apu = output("apu_channels.csv", "frame,channel,volume,frequency,midikey,duty,short,dmcaddress,dmcsize,dmcloop,dmcseed,register_frequency")

local function value(object, key)
	local result = object and object[key]
	return result == nil and "" or tostring(result)
end

local function capture_apu(frame)
	local ok, data = pcall(function() return sound.get().rp2a03 end)
	if not ok or not data then return end
	for _, name in ipairs({"square1", "square2", "triangle", "noise", "dpcm"}) do
		local channel = data[name]
		apu:write(table.concat({frame, name, value(channel, "volume"), value(channel, "frequency"), value(channel, "midikey"), value(channel, "duty"), value(channel, "short"), value(channel, "dmcaddress"), value(channel, "dmcsize"), value(channel, "dmcloop"), value(channel, "dmcseed"), value(channel and channel.regs, "frequency")}, ",") .. "\n")
	end
end

-- This is a real emulator power cycle, followed by no synthetic button presses.
local ok, err = pcall(emu.poweron)
log:write("START clean_power_cycle=" .. tostring(ok) .. " max_frames=10800 input=manual\n")
if not ok then log:write("POWER_ERROR " .. tostring(err) .. "\n") end
log:flush()

local previous_ppu
local previous_ram
local previous_screen
local max_frames = 10800 -- 180 seconds; stop the script manually if the target screens are reached earlier.

for _ = 1, max_frames do
	emu.frameadvance()
	local frame = emu.framecount()

	local pad = joypad.get(1)
	inputs:write(table.concat({frame, button(pad, "up"), button(pad, "down"), button(pad, "left"), button(pad, "right"), button(pad, "A"), button(pad, "B"), button(pad, "start"), button(pad, "select")}, ",") .. "\n")
	capture_apu(frame)

	local ppu_bytes = ppu.readbyterange(0x0000, 0x2000)
		.. ppu.readbyterange(0x2000, 0x1000)
		.. ppu.readbyterange(0x3F00, 0x20)
	if ppu_bytes ~= previous_ppu then
		previous_ppu = ppu_bytes
		local name = string.format("ppu_%06d.bin", frame)
		write_binary(ppu_dir, name, ppu_bytes)
		ppu_index:write(table.concat({frame, name, #ppu_bytes}, ",") .. "\n")
	end

	local ram_bytes = memory.readbyterange(0x0000, 0x0800)
	if ram_bytes ~= previous_ram then
		previous_ram = ram_bytes
		local name = string.format("ram_%06d.bin", frame)
		write_binary(ram_dir, name, ram_bytes)
		ram_index:write(table.concat({frame, name, #ram_bytes}, ",") .. "\n")
	end

	if frame % 2 == 0 then
		local gd = gui.gdscreenshot()
		if gd and gd ~= previous_screen then
			previous_screen = gd
			local name = string.format("frame_%06d.gd", frame)
			write_binary(screens, name, gd)
			screen_index:write(frame .. "," .. name .. "\n")
		end
	end

	if frame % 120 == 0 then
		log:write("CAPTURED frame=" .. frame .. " ppu_states=" .. ppu_index:seek("end") .. "\n")
		log:flush(); ppu_index:flush(); ram_index:flush(); screen_index:flush(); inputs:flush(); apu:flush()
	end
end

log:write("DONE frame=" .. emu.framecount() .. "\n")
log:flush()
log:close(); ppu_index:close(); ram_index:close(); screen_index:close(); inputs:close(); apu:close()

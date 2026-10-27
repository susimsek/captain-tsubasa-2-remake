-- Compare Start handling at early/mid opening frames. Muted FCEUX only.
-- This records emulator state for observation; no captured media becomes runtime assets.
local root = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe/reference/diagnostics/start_timing_probe_20261024"
os.execute("mkdir -p " .. string.format("%q", root))

local function write(path, data)
	local f = assert(io.open(path, "wb"))
	f:write(data)
	f:close()
end

local function scenario(start_frame, label)
	local dir = root .. "/" .. label
	os.execute("mkdir -p " .. string.format("%q", dir .. "/screens") .. " " .. string.format("%q", dir .. "/ram"))
	local log = assert(io.open(dir .. "/timeline.csv", "w"))
	log:write("frame,start,ram_0700,ram_0710,ram_0711,ram_0720,ram_0721,ram_0722,ram_0723,ram_0724,ram_0725,ram_0726,ram_0727,ram_0728,ram_0729,apu_s1,apu_s2,apu_tri,apu_noise,apu_dpcm\n")
	local input_log = assert(io.open(dir .. "/inputs.csv", "w"))
	input_log:write("frame,start\n")
	local ok, err = pcall(emu.poweron)
	local meta = assert(io.open(dir .. "/metadata.txt", "w"))
	meta:write("scenario=" .. label .. "\nrequested_start_frame=" .. start_frame .. "\npoweron=" .. tostring(ok) .. "\nerror=" .. tostring(err or "") .. "\n")
	meta:close()
	pcall(emu.speedmode, "maximum")
	local max_frame = start_frame + 90
	for frame = 1, max_frame do
		local press = frame == start_frame
		joypad.set(1, {up=false, down=false, left=false, right=false, A=false, B=false, start=press, select=false})
		emu.frameadvance()
		local actual = emu.framecount()
		if frame >= start_frame - 3 then
			local ram = memory.readbyterange(0x0000, 0x0800)
			local apu = sound.get().rp2a03
			local function volume(channel) return channel and tostring(channel.volume or "") or "" end
			log:write(table.concat({actual, press and 1 or 0,
				string.format("%02X", ram:byte(0x0701)),
				string.format("%02X", ram:byte(0x0711)),
				string.format("%02X", ram:byte(0x0712)),
				string.format("%02X", ram:byte(0x0721)),
				string.format("%02X", ram:byte(0x0722)),
				string.format("%02X", ram:byte(0x0723)),
				string.format("%02X", ram:byte(0x0724)),
				string.format("%02X", ram:byte(0x0725)),
				string.format("%02X", ram:byte(0x0726)),
				string.format("%02X", ram:byte(0x0727)),
				string.format("%02X", ram:byte(0x0728)),
				string.format("%02X", ram:byte(0x0729)),
				string.format("%02X", ram:byte(0x072A)),
				volume(apu.square1), volume(apu.square2), volume(apu.triangle), volume(apu.noise), volume(apu.dpcm)}, ",") .. "\n")
			input_log:write(actual .. "," .. (press and "1" or "0") .. "\n")
			write(string.format("%s/ram/ram_%06d.bin", dir, actual), ram)
			local gd = gui.gdscreenshot()
			if gd then write(string.format("%s/screens/frame_%06d.gd", dir, actual), gd) end
		end
	end
	log:close()
	input_log:close()
	pcall(emu.speedmode, "normal")
end

scenario(400, "early_frame_400")
scenario(2200, "mid_frame_2200")
emu.pause()

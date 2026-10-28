-- Capture source OAM DMA pages during the F8 handoff residual window.
-- Observation only: this writes emulator state to diagnostics, not game assets.

local ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local ROM_PATH = ROOT .. "/Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
local INPUT_CSV = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local OUTPUT_DIR = os.getenv("CT2_OAM_TRACE_OUTPUT_DIR")
assert(OUTPUT_DIR and #OUTPUT_DIR > 0, "set CT2_OAM_TRACE_OUTPUT_DIR")
local FIRST_SOURCE_FRAME, LAST_SOURCE_FRAME = 3518, 3604

os.execute("mkdir -p " .. string.format("%q", OUTPUT_DIR))

local inputs = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "missing input timeline")
for line in input_file:lines() do
	local frame, up, down, left, right, a, b, start, select = line:gsub("\r$", ""):match(
		"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if frame then
		inputs[tonumber(frame)] = {
			up=up=="1", down=down=="1", left=left=="1", right=right=="1",
			A=a=="1", B=b=="1", start=start=="1", select=select=="1",
		}
	end
end
input_file:close()
for frame=0,LAST_SOURCE_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local function out(name, header)
	local file = assert(io.open(OUTPUT_DIR .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end
local function binary(name, bytes)
	local file = assert(io.open(OUTPUT_DIR .. "/" .. name, "wb"))
	file:write(bytes)
	file:close()
end
local function csv(values)
	local fields = {}
	for i, value in ipairs(values) do fields[i] = tostring(value or "") end
	return table.concat(fields, ",")
end
local function byte(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return value or 0
end
local function hex(value, width)
	return string.format(width == 2 and "$%02X" or "$%04X", value or 0)
end
local function pc_text()
	local pc = -1
	pcall(function() pc = memory.getregister("pc") end)
	return pc, hex(pc)
end
local function frame_timing(frame_start)
	local cycles, line, dot, emu_frame = -1, -1, -1, -1
	pcall(function() cycles = debugger.getcyclescount() end)
	if type(ppu) == "table" then
		pcall(function() line = ppu.getscanline() end)
		pcall(function() dot = ppu.getdot() end)
	end
	pcall(function() emu_frame = emu.framecount() end)
	return emu_frame, cycles >= 0 and frame_start >= 0 and cycles - frame_start or -1,
		cycles, line, dot
end

local dma = out("oam_dma.csv",
	"source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,ppu_scanline,ppu_dot,cpu_pc,page,source_address,oam4_at_dma_hex,shadow4_at_dma_hex,source_page_file")
local frames = out("frame_pages.csv",
	"source_frame,emulator_frame,cycle_start,cycle_end,cycle_delta,dma_page_oam4_hex,shadow_oam4_hex,source_page_file,shadow_page_file")
local progress = out("progress.txt")
local metadata = out("metadata.txt")

local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
metadata:write("rom_path=" .. ROM_PATH .. "\nrom_md5=" .. tostring(md5) .. "\n")
metadata:write("input_timeline=" .. INPUT_CSV .. "\nsource_frames=0-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("capture_window=" .. FIRST_SOURCE_FRAME .. "-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("audio=disabled by --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy; no PCM/WAV saved\n")
metadata:write("oam_dma=CPU write hook on $4014; read and save 256-byte source page synchronously inside the callback\n")
metadata:write("extra_cpu_hooks=none; source routine addresses are recorded in the existing ROM trace documents\n")
metadata:write("ppu_timing_getters=" .. tostring(type(ppu) == "table" and type(ppu.getscanline) == "function" and type(ppu.getdot) == "function") .. "\n")
metadata:flush()

local current_source_frame, frame_cycle_start = -1, -1
local in_window = false

memory.registerwrite(0x4014, 1, function(_, _, value)
	if not in_window then return end
	local frame, relative, absolute, line, dot = frame_timing(frame_cycle_start)
	local _, pc = pc_text()
	local page = value or 0
	local source = memory.readbyterange(page * 0x100, 0x100)
	local source_file = string.format("dma_source_%05d_%06d.bin", current_source_frame, absolute)
	local oam4 = ""
	if type(source) == "string" and #source == 0x100 then
		binary(source_file, source)
		oam4 = source:sub(0x11,0x14):gsub(".", function(c) return string.format("%02X", string.byte(c)) end)
	else
		source_file = ""
	end
	dma:write(csv({current_source_frame,frame,relative,absolute,line,dot,pc,
		hex(page,2),hex(page * 0x100,4),oam4,
		string.format("%02X %02X %02X %02X", byte(0x0478),byte(0x0479),byte(0x047A),byte(0x047B)),source_file}) .. "\n")
	if current_source_frame % 8 == 0 then dma:flush() end
end)

local ok, err = pcall(emu.poweron)
assert(ok, "FCEUX poweron failed: " .. tostring(err))
pcall(debugger.resetcyclescount)
pcall(emu.speedmode, "turbo")

for source_frame=0,LAST_SOURCE_FRAME do
	current_source_frame = source_frame
	in_window = source_frame >= FIRST_SOURCE_FRAME and source_frame <= LAST_SOURCE_FRAME
	joypad.set(1, inputs[source_frame])
	frame_cycle_start = -1
	pcall(function() frame_cycle_start = debugger.getcyclescount() end)
	emu.frameadvance()
	local cycle_end = -1
	pcall(function() cycle_end = debugger.getcyclescount() end)
	if in_window then
		local page = memory.readbyterange(0x0200, 0x100)
		local shadow = memory.readbyterange(0x0468, 0x100)
		local page_file = string.format("page_end_%05d.bin", source_frame)
		local shadow_file = string.format("shadow_end_%05d.bin", source_frame)
		binary(page_file, page)
		binary(shadow_file, shadow)
		local frame = emu.framecount()
		frames:write(csv({source_frame,frame,frame_cycle_start,cycle_end,
			cycle_end - frame_cycle_start,
			string.format("%02X %02X %02X %02X",string.byte(page,0x11,0x14)),
			string.format("%02X %02X %02X %02X",string.byte(shadow,0x11,0x14)),page_file,shadow_file}) .. "\n")
	end
	if source_frame % 60 == 0 then
		progress:write(tostring(source_frame) .. "\n"); progress:flush()
		dma:flush(); frames:flush(); metadata:flush()
	end
end

pcall(emu.speedmode, "normal")
progress:write("complete " .. LAST_SOURCE_FRAME .. "\n")
progress:flush()
metadata:write("completed_source_frame=" .. LAST_SOURCE_FRAME .. "\n")
metadata:flush()
dma:close(); frames:close(); progress:close(); metadata:close()
pcall(memory.registerwrite,0x4014,1,nil)
os.exit()

-- Muted, same-input trace of the first-command gameplay IRQ/PPU viewport.
-- PPU/RAM/video/audio captures are not produced or used as runtime assets.
local ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local LAST_FRAME = 8953
local TRACE_START = 8750
local OUT = assert(os.getenv("CT2_IRQ_TRACE_OUTPUT_DIR"), "missing output directory")
os.execute("mkdir -p " .. string.format("%q", OUT))

local inputs = {}
local function read_inputs(path, route_format)
	local file = assert(io.open(path, "r"), "missing input file " .. path)
	file:read("*l")
	for line in file:lines() do
		line = line:gsub("\r$", "")
		local values = {}
		for value in (line .. ","):gmatch("(.-),") do values[#values + 1] = value end
		local offset = route_format and 3 or 2
		local frame = tonumber(values[1])
		if frame and #values >= offset + 7 then
			inputs[frame] = {
				A=values[offset + 4]=="1",B=values[offset + 5]=="1",start=values[offset + 6]=="1",
				select=values[offset + 7]=="1"}
			inputs[frame].up = values[offset] == "1"
			inputs[frame].down = values[offset + 1] == "1"
			inputs[frame].left = values[offset + 2] == "1"
			inputs[frame].right = values[offset + 3] == "1"
		end
	end
	file:close()
end
read_inputs(OPENING_INPUT, false)
read_inputs(ROUTE_INPUT, true)
for frame = 0, LAST_FRAME do assert(inputs[frame], "missing source-frame input " .. frame) end

local function byte(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return value or 0
end
local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return value or -1
end
local function cycles()
	local value = -1
	pcall(function() value = debugger.getcyclescount() end)
	return value or -1
end
local function ppu_pos()
	local line, dot = -1, -1
	pcall(function() line = ppu.getscanline() end)
	pcall(function() dot = ppu.getdot() end)
	return line or -1, dot or -1
end
local function hex(value, digits)
	if value == nil or value < 0 then return "" end
	return string.format("$%0" .. digits .. "X", value)
end

local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
assert(md5 == "eaf2b3745263efa4b1afd2b400f68dae", "wrong ROM MD5: " .. tostring(md5))
assert(type(memory) == "table" and type(memory.registerexec) == "function", "FCEUX exec hooks unavailable")
assert(type(debugger) == "table" and type(debugger.getcyclescount) == "function", "FCEUX cycle counter unavailable")

local events = assert(io.open(OUT .. "/irq_viewport_events.csv", "w"))
events:write("source_frame,emulator_frame,cycle_abs,cycle_from_frame_start,kind,pc,address,value,a,x,y,s,p,ppu_scanline,ppu_dot,ram_001b,ram_0020,ram_004a,ram_004b,ram_008e,ram_0469,ram_0538,ram_05f8,irq_index,mmc3_select,mmc3_latch,mmc3_enable\n")
local frames = assert(io.open(OUT .. "/frame_edges.csv", "w"))
frames:write("source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,ppu_scanline_end,ppu_dot_end\n")
local progress = assert(io.open(OUT .. "/progress.txt", "w"))
local metadata = assert(io.open(OUT .. "/metadata.txt", "w"))
metadata:write("purpose=muted same-input first-command screen IRQ/PPU viewport trace\n")
metadata:write("rom_md5=" .. tostring(md5) .. "\nsource_frames=0-" .. LAST_FRAME .. "; detailed hooks=" .. TRACE_START .. "-" .. LAST_FRAME .. "\n")
metadata:write("audio=disabled with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy\n")
metadata:write("hooks=IRQ $C821/$C852/$C87C, PPU $2000/$2005/$2006, MMC3 IRQ and CHR writes\n")
metadata:write("all output is diagnostic only; no screenshot, WAV, PCM or runtime asset\n")
metadata:flush()

local source_frame = -1
local frame_cycle_start = 0
local mmc3_select = -1
local mmc3_latch = -1
local mmc3_enable = -1
local function log(kind, address, value, hook_pc)
	if source_frame < TRACE_START or source_frame > LAST_FRAME then return end
	local absolute = cycles()
	local line, dot = ppu_pos()
	events:write(table.concat({source_frame, emu.framecount(), absolute,
	absolute >= 0 and absolute - frame_cycle_start or -1, kind,
		hex(hook_pc or reg("pc"), 4), hex(address or 0, 4), hex(value or 0, 2),
		hex(reg("a"), 2), hex(reg("x"), 2), hex(reg("y"), 2), hex(reg("s"), 2), hex(reg("p"), 2),
		line, dot, hex(byte(0x001B), 2), hex(byte(0x0020), 2), hex(byte(0x004A), 2),
		hex(byte(0x004B), 2), hex(byte(0x008E), 2), hex(byte(0x0469), 2),
		hex(byte(0x0538), 2), hex(byte(0x05F8), 2), hex(byte(0x00EC), 2),
		hex(mmc3_select, 2), hex(mmc3_latch, 2), hex(mmc3_enable, 2)}, ",") .. "\n")
end

for _, address in ipairs({0xC821, 0xC852, 0xC87C}) do
	local pc = address
	memory.registerexec(pc, 1, function() log("exec", pc, nil, pc) end)
end
for address, name in pairs({[0x2000]="PPUCTRL", [0x2005]="PPUSCROLL", [0x2006]="PPUADDR",
	[0xC000]="MMC3_IRQ_LATCH", [0xC001]="MMC3_IRQ_RELOAD", [0xE000]="MMC3_IRQ_DISABLE_ACK",
	[0xE001]="MMC3_IRQ_ENABLE", [0x8001]="MMC3_BANK_DATA"}) do
	local target, label = address, name
	memory.registerwrite(target, 1, function(addr, _, value)
		if target == 0xC000 then mmc3_latch = value or -1 end
		if target == 0xE001 then mmc3_enable = 1 end
		if target == 0xE000 then mmc3_enable = 0 end
		log(label, addr, value)
	end)
end
memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or -1 end)

assert(type(movie) == "table" and type(movie.active) == "function" and type(movie.stop) == "function",
	"FCEUX movie API unavailable; cannot guarantee joypad.set input control")
local active = false
pcall(function() active = movie.active() end)
if active then movie.stop() end
assert(not movie.active(), "movie playback remained active before power-on")
local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "FCEUX power-on failed: " .. tostring(power_error))
assert(not movie.active(), "movie playback reactivated after power-on")
debugger.resetcyclescount()
emu.speedmode("turbo")
for frame = 0, LAST_FRAME do
	source_frame = frame
	local before = emu.framecount()
	frame_cycle_start = cycles()
	joypad.set(1, inputs[frame])
	emu.frameadvance()
	local after, finish = emu.framecount(), cycles()
	local line, dot = ppu_pos()
	if frame >= TRACE_START then
		frames:write(table.concat({frame, before, after, frame_cycle_start, finish,
			finish-frame_cycle_start, line, dot}, ",") .. "\n")
		events:flush(); frames:flush(); metadata:flush()
	end
	if frame % 60 == 0 or frame == LAST_FRAME then
		progress:write(frame .. ",advance_complete\n")
		progress:flush()
	end
end
emu.speedmode("normal")
metadata:write("complete=true\n")
events:close(); frames:close(); progress:close(); metadata:close()
os.exit()

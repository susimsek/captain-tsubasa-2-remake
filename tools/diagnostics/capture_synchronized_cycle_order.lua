-- Synchronized same-core screenshots + PPU timing event capture for cycle-order diagnostics.
-- Run in FCEUX with Mute Speaker Output enabled. This script never reads ROM
-- bytes, extracts assets, or writes to any pre-existing capture directory.

local PROJECT_ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local FIRST_SCREEN_FRAME = 378
local LAST_SOURCE_FRAME = 811
local SCRIPT_FRAME_COUNT = LAST_SOURCE_FRAME + 1 -- source frame 0 is first advance.

local run_id = os.date("%Y%m%d_%H%M%S")
local root = PROJECT_ROOT .. "/reference/diagnostics/synchronized_cycle_order_" .. run_id
local ppu_dir, ram_dir, screen_dir = root .. "/ppu_states", root .. "/ram_states", root .. "/screens"
os.execute("mkdir -p " .. string.format("%q", ppu_dir) .. " " .. string.format("%q", ram_dir) .. " " .. string.format("%q", screen_dir))

local function open_output(name, header)
	local file = assert(io.open(root .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	file:flush()
	return file
end

local function save_binary(folder, name, bytes)
	local file, err = io.open(folder .. "/" .. name, "wb")
	if not file then error("cannot write " .. name .. ": " .. tostring(err)) end
	file:write(bytes)
	file:close()
end

-- Replay the already captured input timeline exactly. Source frame 0 supplies
-- input for script frame 1; therefore script_frame = source_frame + 1.
local input_timeline = {}
local timeline_file = assert(io.open(INPUT_CSV, "r"), "cannot open source input timeline: " .. INPUT_CSV)
for line in timeline_file:lines() do
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
timeline_file:close()
for source_frame = 0, LAST_SOURCE_FRAME do
	assert(input_timeline[source_frame] ~= nil,
		"source input timeline is missing source frame " .. source_frame)
end

local function hex(value)
	return string.format("$%04X", value)
end

local frames = open_output("frames.csv",
	"source_frame,script_frame,emulator_frame_before,emulator_frame_after,mapping_matches_source_frame,cycle_start,cycle_end,cycle_delta,lagged,up,down,left,right,A,B,start,select,ppu_file,ram_file,ppu_scanline_start,ppu_dot_start,ppu_scanline_end,ppu_dot_end")
local events = open_output("bus_events.csv",
	"source_frame,script_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,event,address,value,cpu_pc,ppu_scanline,ppu_dot")
local screens = open_output("screen_index.csv", "source_frame,script_frame,file,bytes")
local log = open_output("capture.log")
local metadata = open_output("metadata.txt")

local rom_md5 = "unavailable"
pcall(function() rom_md5 = rom.gethash("md5") end)
metadata:write("capture_id=" .. run_id .. "\n")
metadata:write("rom_md5=" .. tostring(rom_md5) .. "\n")
metadata:write("source_input_csv=" .. INPUT_CSV .. "\n")
metadata:write("last_source_frame=" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("script_frame_count=" .. SCRIPT_FRAME_COUNT .. "\n")
metadata:write("frame_mapping=source_frame = emulator_frame_after; script_frame = source_frame + 1; source frame 0 drives the first frameadvance\n")
metadata:write("input=exact per-frame P1 buttons replayed from source input CSV\n")
metadata:write("snapshot=per-frame PPU $0000-$3FFF mapped view; CPU RAM $0000-$07FF\n")
metadata:write("screenshots=gui.gdscreenshot after frameadvance for source frames 378-811, same FCEUX core run as event trace\n")
metadata:write("screenshot_range=" .. FIRST_SCREEN_FRAME .. "-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("cycles=debugger.getcyclescount absolute count plus per-frame start/end baselines; event offset is CPU cycles from frame start\n")
metadata:write("ppu_timing=diagnostic FCEUX 2.7.0 build exposes ppu.getscanline/getdot; launch with --newppu 1 for hardware scanline/dot values\n")
metadata:flush()

local current_script_frame = 0
local current_source_frame = 0
local frame_cycle_start = 0
local cycle_counter_available = type(debugger) == "table" and type(debugger.getcyclescount) == "function"
local registerread_available = type(memory) == "table" and type(memory.registerread) == "function"
local ppu_status_read_hook = false
local event_error = nil

local function cycles_now()
	if not cycle_counter_available then return -1 end
	local ok, value = pcall(debugger.getcyclescount)
	if ok and type(value) == "number" then return value end
	cycle_counter_available = false
	return -1
end

local ppu_timing_available = type(ppu) == "table" and type(ppu.getscanline) == "function" and type(ppu.getdot) == "function"

local function ppu_position()
	if not ppu_timing_available then return -1, -1 end
	local ok_line, line = pcall(ppu.getscanline)
	local ok_dot, dot = pcall(ppu.getdot)
	if ok_line and ok_dot and type(line) == "number" and type(dot) == "number" then return line, dot end
	ppu_timing_available = false
	return -1, -1
end

local function cpu_pc()
	local ok, value = pcall(memory.getregister, "pc")
	if ok and type(value) == "number" then return string.format("$%04X", value) end
	return ""
end

local function event_callback(kind)
	return function(address, _size, value)
		local ppu_scanline, ppu_dot = ppu_position()
		local cycle_absolute = cycles_now()
		local cycle_relative = -1
		if cycle_absolute >= 0 and frame_cycle_start >= 0 then
			cycle_relative = cycle_absolute - frame_cycle_start
		end
		local emulator_frame = -1
		pcall(function() emulator_frame = emu.framecount() end)
		local ok, err = pcall(function()
			events:write(table.concat({
				tostring(current_source_frame), tostring(current_script_frame), tostring(emulator_frame),
				tostring(cycle_relative), tostring(cycle_absolute), kind,
				hex(address), string.format("$%02X", value or 0), cpu_pc(), tostring(ppu_scanline), tostring(ppu_dot)
			}, ",") .. "\n")
		end)
		if not ok and not event_error then event_error = tostring(err) end
	end
end

local watched_ppu_writes = {
	[0x2000] = "PPUCTRL_write",
	[0x2001] = "PPUMASK_write",
	[0x2005] = "PPUSCROLL_write",
	[0x2006] = "PPUADDR_write",
	[0x2007] = "PPUDATA_write",
}
for address, name in pairs(watched_ppu_writes) do
	memory.registerwrite(address, 1, event_callback(name))
end

-- FCEUX 2.6.6+ documents memory.registerread. Keep it optional so older
-- builds still capture writes and report that PPUSTATUS reads were not hooked.
if registerread_available then
	local ok = pcall(function()
		memory.registerread(0x2002, 1, event_callback("PPUSTATUS_read"))
	end)
	ppu_status_read_hook = ok
end

local mmc3_registers = {
	[0x8000] = "MMC3_bank_select",
	[0x8001] = "MMC3_bank_data",
	[0xA000] = "MMC3_mirroring",
	[0xA001] = "MMC3_ram_control",
	[0xC000] = "MMC3_irq_latch",
	[0xC001] = "MMC3_irq_reload",
	[0xE000] = "MMC3_irq_disable_ack",
	[0xE001] = "MMC3_irq_enable",
}
for address, name in pairs(mmc3_registers) do
	memory.registerwrite(address, 1, event_callback(name))
end

-- Explicitly start a clean power cycle before any recorded frame.
local power_ok, power_error = pcall(emu.poweron)
if cycle_counter_available then pcall(debugger.resetcyclescount) end
local cycle_counter_reset = cycles_now()
local emulator_frame_after_poweron = -1
pcall(function() emulator_frame_after_poweron = emu.framecount() end)
metadata:write("poweron_success=" .. tostring(power_ok) .. "\n")
metadata:write("poweron_error=" .. (power_error and tostring(power_error) or "") .. "\n")
metadata:write("emulator_frame_after_poweron=" .. tostring(emulator_frame_after_poweron) .. "\n")
metadata:write("cycle_counter_available=" .. tostring(cycle_counter_available) .. "\n")
metadata:write("cycle_counter_after_reset=" .. tostring(cycle_counter_reset) .. "\n")
metadata:write("registerread_available=" .. tostring(registerread_available) .. "\n")
metadata:write("ppu_status_read_hook=" .. tostring(ppu_status_read_hook) .. "\n")
metadata:write("ppu_timing_getter_available=" .. tostring(ppu_timing_available) .. "\n")
metadata:flush()

log:write("START source_frames=0-" .. LAST_SOURCE_FRAME .. " script_frame_count=" .. SCRIPT_FRAME_COUNT .. " root=" .. root .. "\n")
log:write("Silent capture requested with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy.\n")
log:flush()
pcall(emu.speedmode, "turbo")

local function input_csv(pad)
	local function bit(key) return pad[key] and 1 or 0 end
	return table.concat({bit("up"), bit("down"), bit("left"), bit("right"),
		bit("A"), bit("B"), bit("start"), bit("select")}, ",")
end

local ppu_count, ram_count = 0, 0
for source_frame = 0, LAST_SOURCE_FRAME do
	local script_frame = source_frame + 1
	current_source_frame = source_frame
	current_script_frame = script_frame
	local pad = input_timeline[source_frame]
	joypad.set(1, pad)
	frame_cycle_start = cycles_now()
	local ppu_scanline_start, ppu_dot_start = ppu_position()
	local emulator_frame_before = emu.framecount()
	emu.frameadvance()
	local cycle_end = cycles_now()
	local ppu_scanline_end, ppu_dot_end = ppu_position()
	local cycle_delta = -1
	if frame_cycle_start >= 0 and cycle_end >= 0 then cycle_delta = cycle_end - frame_cycle_start end
	local emulator_frame_after = emu.framecount()
	local mapping_matches_source_frame = emulator_frame_after == source_frame
	local lagged = false
	pcall(function() lagged = emu.lagged() end)

	local ppu_file = string.format("ppu_%05d.bin", source_frame)
	local ram_file = string.format("ram_%05d.bin", source_frame)
	local ppu_ok, ppu_bytes = pcall(function()
		return ppu.readbyterange(0x0000, 0x4000)
	end)
	if ppu_ok and type(ppu_bytes) == "string" and #ppu_bytes == 0x4000 then
		save_binary(ppu_dir, ppu_file, ppu_bytes)
		ppu_count = ppu_count + 1
	else
		ppu_file = ""
		log:write(string.format("ERROR source_frame=%d script_frame=%d ppu_snapshot=%s\n", source_frame, script_frame, tostring(ppu_bytes)))
	end

	if source_frame >= FIRST_SCREEN_FRAME then
		local screen_ok, screen_bytes = pcall(gui.gdscreenshot)
		if screen_ok and type(screen_bytes) == "string" and #screen_bytes > 0 then
			local screen_file = string.format("frame_%06d.gd", source_frame)
			save_binary(screen_dir, screen_file, screen_bytes)
			screens:write(table.concat({source_frame, script_frame, screen_file, #screen_bytes}, ",") .. "\n")
		else
			log:write(string.format("ERROR source_frame=%d screenshot=%s\n", source_frame, tostring(screen_bytes)))
		end
	end

	local ram_ok, ram_bytes = pcall(function() return memory.readbyterange(0x0000, 0x0800) end)
	if ram_ok and type(ram_bytes) == "string" and #ram_bytes == 0x0800 then
		save_binary(ram_dir, ram_file, ram_bytes)
		ram_count = ram_count + 1
	else
		ram_file = ""
		log:write(string.format("ERROR source_frame=%d script_frame=%d ram_snapshot=%s\n", source_frame, script_frame, tostring(ram_bytes)))
	end

	frames:write(table.concat({source_frame, script_frame, emulator_frame_before, emulator_frame_after,
		mapping_matches_source_frame and 1 or 0, frame_cycle_start, cycle_end,
		cycle_delta, lagged and 1 or 0, input_csv(pad), ppu_file, ram_file,
		tostring(ppu_scanline_start), tostring(ppu_dot_start), tostring(ppu_scanline_end), tostring(ppu_dot_end)}, ",") .. "\n")
	if not mapping_matches_source_frame then
		log:write(string.format("FRAME_MAPPING_MISMATCH source=%d script=%d emulator_after=%d\n",
			source_frame, script_frame, emulator_frame_after))
	end
	if script_frame % 120 == 0 then
		frames:flush(); events:flush(); screens:flush(); log:flush()
		log:write(string.format("CAPTURED source_frame=%d script_frame=%d emulator_before=%d emulator_after=%d ppu=%d ram=%d\n",
			source_frame, script_frame, emulator_frame_before, emulator_frame_after, ppu_count, ram_count))
	end
end

pcall(emu.speedmode, "normal")
log:write(string.format("DONE frames=%d ppu_snapshots=%d ram_snapshots=%d ppu_status_read_hook=%s\n",
	SCRIPT_FRAME_COUNT, ppu_count, ram_count, tostring(ppu_status_read_hook)))
if event_error then log:write("EVENT_WRITE_ERROR " .. event_error .. "\n") end
log:flush(); frames:flush(); events:flush(); screens:flush()

for address in pairs(watched_ppu_writes) do pcall(memory.registerwrite, address, 1, nil) end
if ppu_status_read_hook then pcall(memory.registerread, 0x2002, 1, nil) end
for address in pairs(mmc3_registers) do pcall(memory.registerwrite, address, 1, nil) end
frames:close(); events:close(); screens:close(); log:close(); metadata:close()
os.exit()

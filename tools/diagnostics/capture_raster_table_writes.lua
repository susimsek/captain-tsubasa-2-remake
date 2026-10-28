-- Capture the source replay's writes to the opening raster-event workspace.
-- Run with FCEUX --sound 0 --volume 0 --newppu 1. This is diagnostic-only.

local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local FIRST_CAPTURE_FRAME = 378
local LAST_SOURCE_FRAME = 400

local run_id = os.date("%Y%m%d_%H%M%S")
local root = PROJECT_ROOT .. "/reference/diagnostics/raster_table_writes_" .. run_id
os.execute("mkdir -p " .. string.format("%q", root))

local function open_output(name, header)
	local file = assert(io.open(root .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	file:flush()
	return file
end

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

local function hex(value, digits)
	return string.format("$%0" .. tostring(digits) .. "X", value)
end

local writes = open_output("ram_writes.csv",
	"source_frame,script_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,ppu_scanline,ppu_dot,address,value,cpu_pc,kind,mmc3_select,mmc3_r7")
local states = open_output("table_state.csv",
	"source_frame,script_frame,emulator_frame,value_0057,value_00ED,bytes_0078_008D")
local frames = open_output("frames.csv",
	"source_frame,script_frame,emulator_frame_before,emulator_frame_after,mapping_matches_source_frame,cycle_start,cycle_end,cycle_delta,lagged,up,down,left,right,A,B,start,select")
local metadata = open_output("metadata.txt")
local log = open_output("capture.log")

local rom_md5 = "unavailable"
pcall(function() rom_md5 = rom.gethash("md5") end)
metadata:write("capture_id=" .. run_id .. "\n")
metadata:write("rom_md5=" .. tostring(rom_md5) .. "\n")
metadata:write("source_input_csv=" .. INPUT_CSV .. "\n")
metadata:write("source_frame_range=" .. FIRST_CAPTURE_FRAME .. "-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("replay_starts_at_poweron=true\n")
metadata:write("frame_mapping=source_frame = emulator_frame_after; script_frame = source_frame + 1; source frame 0 drives the first frameadvance\n")
metadata:write("watched_cpu_ram=$0057,$00ED on frames 0-400; $0078-$008D on frames 378-400\n")
metadata:write("cycles=debugger.getcyclescount absolute count plus per-frame start baseline\n")
metadata:write("ppu_timing=FCEUX ppu.getscanline/getdot; launch with --newppu 1\n")
metadata:write("audio=disabled by --sound 0 --volume 0; SDL_AUDIODRIVER=dummy\n")
metadata:write("use=same-input replay and RAM write origin only; no runtime asset output\n")
metadata:flush()

local current_source_frame = 0
local current_script_frame = 0
local frame_cycle_start = 0
local cycle_counter_available = type(debugger) == "table" and type(debugger.getcyclescount) == "function"
local ppu_timing_available = type(ppu) == "table" and type(ppu.getscanline) == "function" and type(ppu.getdot) == "function"
local event_error = nil
local mmc3_select = 0
local mmc3_registers = {0, 0, 0, 0, 0, 0, 0, 0}

local function cycles_now()
	if not cycle_counter_available then return -1 end
	local ok, value = pcall(debugger.getcyclescount)
	if ok and type(value) == "number" then return value end
	cycle_counter_available = false
	return -1
end

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
	if ok and type(value) == "number" then return hex(value, 4) end
	return ""
end

local function in_capture_range(address)
	if address == 0x0057 or address == 0x00ED then
		return current_source_frame >= 0 and current_source_frame <= LAST_SOURCE_FRAME
	end
	return address >= 0x0078 and address <= 0x008D
		and current_source_frame >= FIRST_CAPTURE_FRAME
		and current_source_frame <= LAST_SOURCE_FRAME
end

local function log_write(address, value, kind)
	if not in_capture_range(address) then return end
	local line, dot = ppu_position()
	local cycle_absolute = cycles_now()
	local cycle_relative = -1
	if cycle_absolute >= 0 and frame_cycle_start >= 0 then cycle_relative = cycle_absolute - frame_cycle_start end
	local emulator_frame = -1
	pcall(function() emulator_frame = emu.framecount() end)
	local ok, err = pcall(function()
		writes:write(table.concat({
			tostring(current_source_frame), tostring(current_script_frame), tostring(emulator_frame),
			tostring(cycle_relative), tostring(cycle_absolute), tostring(line), tostring(dot),
			hex(address, 4), hex(value or 0, 2), cpu_pc(), kind or "RAM",
			hex(mmc3_select, 2), hex(mmc3_registers[7] or 0, 2)
		}, ",") .. "\n")
	end)
	if not ok and not event_error then event_error = tostring(err) end
end

local function write_callback(address, _size, value)
	log_write(address, value, "RAM")
end

memory.registerwrite(0x0057, 1, write_callback)
memory.registerwrite(0x00ED, 1, write_callback)
for address = 0x0078, 0x008D do
	memory.registerwrite(address, 1, write_callback)
end
memory.registerwrite(0x8000, 1, function(_, _, value)
	mmc3_select = value or 0
	log_write(0x8000, value, "MMC3_SELECT")
end)
memory.registerwrite(0x8001, 1, function(_, _, value)
	local index = (mmc3_select % 8) + 1
	mmc3_registers[index] = value or 0
	log_write(0x8001, value, "MMC3_DATA")
end)

local power_ok, power_error = pcall(emu.poweron)
if cycle_counter_available then pcall(debugger.resetcyclescount) end
metadata:write("poweron_success=" .. tostring(power_ok) .. "\n")
metadata:write("poweron_error=" .. (power_error and tostring(power_error) or "") .. "\n")
metadata:write("cycle_counter_available=" .. tostring(cycle_counter_available) .. "\n")
metadata:write("ppu_timing_getter_available=" .. tostring(ppu_timing_available) .. "\n")
metadata:flush()

log:write("START source_frames=" .. FIRST_CAPTURE_FRAME .. "-" .. LAST_SOURCE_FRAME .. " replay_from_poweron=true root=" .. root .. "\n")
log:flush()
pcall(emu.speedmode, "turbo")

local function input_csv(pad)
	local function bit(key) return pad[key] and 1 or 0 end
	return table.concat({bit("up"), bit("down"), bit("left"), bit("right"),
		bit("A"), bit("B"), bit("start"), bit("select")}, ",")
end

for source_frame = 0, LAST_SOURCE_FRAME do
	current_source_frame = source_frame
	current_script_frame = source_frame + 1
	joypad.set(1, input_timeline[source_frame])
	frame_cycle_start = cycles_now()
	local emulator_frame_before = emu.framecount()
	local cycle_start = frame_cycle_start
	emu.frameadvance()
	local cycle_end = cycles_now()
	local emulator_frame_after = emu.framecount()
	local cycle_delta = -1
	if cycle_start >= 0 and cycle_end >= 0 then cycle_delta = cycle_end - cycle_start end
	local lagged = false
	pcall(function() lagged = emu.lagged() end)
	local matches = emulator_frame_after == source_frame
	frames:write(table.concat({source_frame, current_script_frame, emulator_frame_before,
		emulator_frame_after, matches and 1 or 0, cycle_start, cycle_end, cycle_delta,
		lagged and 1 or 0, input_csv(input_timeline[source_frame])}, ",") .. "\n")
	if source_frame >= FIRST_CAPTURE_FRAME then
		local bytes = memory.readbyterange(0x0078, 0x0016)
		local values = {}
		for i = 1, #bytes do values[#values + 1] = string.format("%02X", bytes:byte(i)) end
		states:write(table.concat({source_frame, current_script_frame, emulator_frame_after,
			hex(memory.readbyte(0x0057) or 0, 2), hex(memory.readbyte(0x00ED) or 0, 2),
			table.concat(values, " ")}, ",") .. "\n")
	end
	if not matches then
		log:write(string.format("FRAME_MAPPING_MISMATCH source=%d script=%d emulator_after=%d\n",
			source_frame, current_script_frame, emulator_frame_after))
	end
	if source_frame == FIRST_CAPTURE_FRAME or source_frame == LAST_SOURCE_FRAME or source_frame % 100 == 0 then
		writes:flush(); states:flush(); frames:flush(); log:flush()
		log:write(string.format("CAPTURED source_frame=%d emulator_frame=%d\n", source_frame, emulator_frame_after))
	end
end

pcall(emu.speedmode, "normal")
log:write("DONE\n")
if event_error then log:write("EVENT_WRITE_ERROR " .. event_error .. "\n") end
log:flush(); writes:flush(); states:flush(); frames:flush()
memory.registerwrite(0x0057, 1, nil)
memory.registerwrite(0x00ED, 1, nil)
for address = 0x0078, 0x008D do pcall(memory.registerwrite, address, 1, nil) end
memory.registerwrite(0x8000, 1, nil)
memory.registerwrite(0x8001, 1, nil)
writes:close(); states:close(); frames:close(); metadata:close(); log:close()
os.exit()

-- Capture the ROM's cold boot through its first observed worker dispatch.
-- Evidence only: this does not extract ROM assets or write runtime resources.
-- Run with FCEUX sound disabled; see the paired diagnostic note for invocation.

local PROJECT_ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
-- FCEUX rom.gethash("md5") returns the PRG+CHR payload digest without the
-- 16-byte iNES header. The whole-file MD5 is 93d14fb7962c54062be9734642fbe7bd.
local ROM_MD5_EXPECTED = "eaf2b3745263efa4b1afd2b400f68dae"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local LAST_SOURCE_FRAME = 12
local run_id = os.date("%Y%m%d_%H%M%S")
local out_dir = PROJECT_ROOT .. "/reference/diagnostics/cold_start_nmi_boot_" .. run_id
os.execute("mkdir -p " .. string.format("%q", out_dir))

local function output(name, header)
	local file = assert(io.open(out_dir .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end

local function read_inputs()
	local inputs = {}
	local file = assert(io.open(INPUT_CSV, "r"), "missing opening input timeline")
	for line in file:lines() do
		line = line:gsub("\r$", "")
		local frame, up, down, left, right, a, b, start, select = line:match(
			"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
		if frame then
			inputs[tonumber(frame)] = {
				up=up == "1", down=down == "1", left=left == "1", right=right == "1",
				A=a == "1", B=b == "1", start=start == "1", select=select == "1",
			}
		end
	end
	file:close()
	for frame=0,LAST_SOURCE_FRAME do
		assert(inputs[frame], "input timeline is missing source frame " .. frame)
	end
	return inputs
end

local function byte(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return value or 0
end

local function register(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return value or -1
end

local function cycles_now()
	local value = -1
	pcall(function() value = debugger.getcyclescount() end)
	return value or -1
end

local function hex(value, digits)
	if value == nil or value < 0 then return "" end
	return string.format("$%0" .. digits .. "X", value)
end

local function task_bytes()
	local result = {}
	for address=0x0001,0x0018 do
		result[#result + 1] = string.format("%02X", byte(address))
	end
	return table.concat(result, " ")
end

local inputs = read_inputs()
local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
if md5 ~= ROM_MD5_EXPECTED then
	error("wrong ROM identity: expected MD5 " .. ROM_MD5_EXPECTED .. ", got " .. tostring(md5))
end
if type(memory) ~= "table" or type(memory.registerexec) ~= "function"
		or type(memory.registerwrite) ~= "function" then
	error("FCEUX memory.registerexec/registerwrite APIs are required")
end

local events = output("events.csv",
	"source_frame,emulator_frame,cycle_absolute,cycle_from_frame_start,event,pc,a,x,y,s,p,ram_001b,task_0001_0018,ram_004d_004e,ram_0055,ram_0700")
local writes = output("writes.csv",
	"source_frame,emulator_frame,cycle_absolute,cycle_from_frame_start,address,value,pc,ram_001b,task_0001_0018")
local frames = output("frames.csv",
	"source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,ram_001b,task_0001_0018,script_pointer,text_speed,sound_queue,start_latch,controller_bits")
local metadata = output("metadata.txt")

metadata:write("rom_md5=" .. tostring(md5) .. "\n")
metadata:write("fceux_rom_md5_scope=PRG+CHR payload; iNES header excluded\n")
metadata:write("source_rom_sha256=4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097\n")
metadata:write("source_inputs=" .. INPUT_CSV .. "\nsource_frame_range=0-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("replay=emu.poweron then exact controller frames 0-" .. LAST_SOURCE_FRAME .. " from the established input timeline\n")
metadata:write("audio=must be disabled at launch with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy; the Lua API does not guarantee speaker mute\n")
metadata:write("hooks=CPU execution at $801F/$8024/$8464/$8494/$9F69/$84C6/$84E7/$9EED/$9FA8/$C500/$C76E/$C421/$C775/$A000/$A12F/$C7EE/$A133; writes to $0001-$0018,$001B,$004D,$004E,$0055,$0700\n")
metadata:write("cycles=debugger.getcyclescount absolute count; frame-relative offsets are derived from the preceding frame boundary\n")
metadata:write("frame_convention=source frame 0 supplies input to the first emu.frameadvance; each row records the emulator frame before and after that call\n")
metadata:write("purpose=observe reset/task install/first NMI readiness and first script worker dispatch; no captured pixels or audio are read\n")
metadata:flush()

local current_source_frame = -1
local frame_cycle_start = 0

local function log_event(name)
	local absolute = cycles_now()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	events:write(table.concat({
		tostring(current_source_frame), tostring(emu.framecount()), tostring(absolute), tostring(relative), name,
		hex(register("pc"),4), hex(register("a"),2), hex(register("x"),2), hex(register("y"),2),
		hex(register("s"),2), hex(register("p"),2), hex(byte(0x001B),2), task_bytes(),
		hex(byte(0x004D) + byte(0x004E) * 256,4), hex(byte(0x0055),2), hex(byte(0x0700),2),
	}, ",") .. "\n")
end

local execution_hooks = {
	[0x801F] = "cold_start_entry",
	[0x8024] = "cutscene_dispatch_call",
	[0x8464] = "cutscene_dispatch",
	[0x8494] = "worker_context_install",
	[0x9F69] = "worker_task_ready_ff",
	[0x84C6] = "worker_context_resume",
	[0x84E7] = "cutscene_interpreter",
	[0x9EED] = "cooperative_scheduler_scan",
	[0x9FA8] = "cooperative_yield",
	[0xC500] = "nmi_fixed_entry",
	[0xC76E] = "nmi_route",
	[0xC421] = "nmi_special_route",
	[0xC775] = "nmi_normal_route",
	[0xA000] = "bank2_nmi_consumer",
	[0xA12F] = "bank2_scheduler_ready_check",
	[0xC7EE] = "normal_nmi_ready_latch_store",
	[0xA133] = "special_nmi_ready_latch_store",
}
for address, name in pairs(execution_hooks) do
	local pc, event_name = address, name
	memory.registerexec(pc, function() log_event(event_name) end)
end

local function log_write(address, _, value)
	local absolute = cycles_now()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	writes:write(table.concat({
		tostring(current_source_frame), tostring(emu.framecount()), tostring(absolute), tostring(relative),
		hex(address,4), hex(value or 0,2), hex(register("pc"),4), hex(byte(0x001B),2), task_bytes(),
	}, ",") .. "\n")
end
for address=0x0001,0x0018 do memory.registerwrite(address, 1, log_write) end
for _, address in ipairs({0x001B,0x004D,0x004E,0x0055,0x0700}) do
	memory.registerwrite(address, 1, log_write)
end

local power_ok, power_error = pcall(emu.poweron)
if not power_ok then error("emu.poweron failed: " .. tostring(power_error)) end
pcall(debugger.resetcyclescount)
frame_cycle_start = cycles_now()
metadata:write("poweron_success=true\ncycle_counter_after_poweron=" .. tostring(frame_cycle_start) .. "\n")
metadata:flush()
pcall(emu.speedmode, "turbo")

for source_frame=0,LAST_SOURCE_FRAME do
	current_source_frame = source_frame
	local before_frame = emu.framecount()
	local cycle_start = cycles_now()
	local input = inputs[source_frame]
	joypad.set(1, input)
	emu.frameadvance()
	local after_frame = emu.framecount()
	local cycle_end = cycles_now()
	local input_bits = {}
	for _, key in ipairs({"up","down","left","right","A","B","start","select"}) do
		input_bits[#input_bits + 1] = input[key] and "1" or "0"
	end
	frames:write(table.concat({
		source_frame, before_frame, after_frame, cycle_start, cycle_end,
		cycle_start >= 0 and cycle_end >= cycle_start and cycle_end - cycle_start or -1,
		hex(byte(0x001B),2), task_bytes(),
		hex(byte(0x004D) + byte(0x004E) * 256,4), hex(byte(0x0055),2), hex(byte(0x0700),2),
		hex(byte(0x001E),2), table.concat(input_bits, ""),
	}, ",") .. "\n")
	frame_cycle_start = cycle_end
	events:flush(); writes:flush(); frames:flush(); metadata:flush()
end

metadata:write("completed_source_frames=" .. (LAST_SOURCE_FRAME + 1) .. "\n")
events:close(); writes:close(); frames:close(); metadata:close()
for address in pairs(execution_hooks) do pcall(memory.registerexec, address, 1, nil) end
for address=0x0001,0x0018 do pcall(memory.registerwrite, address, 1, nil) end
for _, address in ipairs({0x001B,0x004D,0x004E,0x0055,0x0700}) do
	pcall(memory.registerwrite, address, 1, nil)
end
os.exit()

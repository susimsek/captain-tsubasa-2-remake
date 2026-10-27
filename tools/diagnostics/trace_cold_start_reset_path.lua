-- Trace cold reset through the first cutscene command on a separate, muted
-- FCEUX process. This is observation/validation only; it does not read or
-- write screenshots, audio, or runtime resources.

local PROJECT_ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
local ROM_MD5_EXPECTED = "eaf2b3745263efa4b1afd2b400f68dae"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local LAST_SOURCE_FRAME = 12
local run_id = os.date("%Y%m%d_%H%M%S")
local out_dir = PROJECT_ROOT .. "/reference/diagnostics/cold_start_reset_path_" .. run_id
os.execute("mkdir -p " .. string.format("%q", out_dir))

local function output(name, header)
	local f = assert(io.open(out_dir .. "/" .. name, "w"))
	if header then f:write(header .. "\n") end
	return f
end

local function read_inputs()
	local inputs = {}
	local f = assert(io.open(INPUT_CSV, "r"), "missing saved input timeline")
	for line in f:lines() do
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
	f:close()
	for frame=0,LAST_SOURCE_FRAME do assert(inputs[frame], "missing source input frame " .. frame) end
	return inputs
end

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
local function hex(value, digits)
	if value == nil or value < 0 then return "" end
	return string.format("$%0" .. digits .. "X", value)
end
local function ppu_position()
	local line, dot = -1, -1
	if type(ppu) == "table" then
		pcall(function() line = ppu.getscanline() end)
		pcall(function() dot = ppu.getdot() end)
	end
	return line or -1, dot or -1
end
local function task_bytes()
	local values = {}
	for address=0x0001,0x0018 do values[#values+1] = string.format("%02X", byte(address)) end
	return table.concat(values, " ")
end

local inputs = read_inputs()
local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
assert(md5 == ROM_MD5_EXPECTED, "wrong ROM payload MD5: " .. tostring(md5))
assert(type(memory) == "table" and type(memory.registerexec) == "function", "FCEUX registerexec unavailable")

local events = output("events.csv",
	"source_frame,emulator_frame,cycle_absolute,cycle_from_frame_start,event,pc,a,x,y,s,p,ppu_scanline,ppu_dot,ram_001b,task_0001_0018,script_ptr_004d_004e,ram_0055,ram_0700,byte_a020")
local bus = output("ppu_bus.csv",
	"source_frame,emulator_frame,cycle_absolute,cycle_from_frame_start,event,address,value,cpu_pc,ppu_scanline,ppu_dot,a,x,y,p")
local frames = output("frames.csv",
	"source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,ppu_line_end,ppu_dot_end,ram_001b,task_0001_0018,script_ptr_004d_004e,controller_bits")
local metadata = output("metadata.txt")
metadata:write("run_id=" .. run_id .. "\nrom_md5_payload=" .. tostring(md5) .. "\n")
metadata:write("source_rom_sha256=4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097\n")
metadata:write("input_timeline=" .. INPUT_CSV .. "\nsource_frames=0-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("launch_requirements=separate FCEUX process; SDL_AUDIODRIVER=dummy; --sound 0 --volume 0 --no-config 1; never attach to or control the user's FCEUX process\n")
metadata:write("hooks=all CPU PCs $C500-$C700 plus $FFF0,$801F,$8024,$8464,$8494,$9F69,$84C6,$84E7,$9EED,$9FA8,$C7EE,$A133\n")
metadata:write("bus_hooks=CPU reads $2002 and writes $2000/$2001/$2005/$2006/$2007; values include callback value and available PPU scanline/dot\n")
metadata:write("cycle_counter=debugger.getcyclescount reset after emu.poweron; PPU getters recorded when available in this core\n")
metadata:write("first_script_step=worker setup at $8494 records $004D/$004E and current mapped byte $A020; $84E7 hooks record interpreter dispatch state\n")
metadata:flush()

local source_frame = -1
local frame_cycle_start = 0
local function log_event(name, address)
	local absolute = cycles()
	local line, dot = ppu_position()
	local ptr = byte(0x004D) + byte(0x004E) * 256
	events:write(table.concat({
		tostring(source_frame), tostring(emu.framecount()), tostring(absolute),
		tostring(absolute >= 0 and frame_cycle_start >= 0 and absolute-frame_cycle_start or -1),
		name, hex(address or reg("pc"),4), hex(reg("a"),2), hex(reg("x"),2), hex(reg("y"),2),
		hex(reg("s"),2), hex(reg("p"),2), tostring(line), tostring(dot), hex(byte(0x001B),2),
		task_bytes(), hex(ptr,4), hex(byte(0x0055),2), hex(byte(0x0700),2), hex(byte(0xA020),2),
	}, ",") .. "\n")
end

local named = {
	[0xFFF0]="reset_stub_FFF0", [0xC503]="reset_c503", [0xC64E]="ppu_setup_c64e",
	[0xC675]="ram_clear_inc_page", [0xC677]="ram_clear_loop_after_inc",
	[0x801F]="cold_start_entry", [0x8024]="cutscene_dispatch_call",
	[0x8464]="cutscene_dispatch", [0x8494]="worker_context_install_A020",
	[0x9F69]="worker_task_ready_ff", [0x84C6]="worker_context_resume",
	[0x84E7]="cutscene_interpreter_step", [0x9EED]="cooperative_scheduler_scan",
	[0x9FA8]="cooperative_yield", [0xC500]="nmi_fixed_entry",
	[0xC76E]="nmi_route", [0xC421]="nmi_special_route",
	[0xC775]="nmi_normal_route", [0xA000]="bank2_nmi_consumer",
	[0xA12F]="bank2_scheduler_ready_check", [0xC7EE]="normal_nmi_ready_latch_store",
	[0xA133]="special_nmi_ready_latch_store",
}
local execution_hooks = {}
for address=0xC500,0xC700 do execution_hooks[address] = true end
for address in pairs(named) do execution_hooks[address] = true end
for address in pairs(execution_hooks) do
	local pc = address
	memory.registerexec(pc, function()
		log_event(named[pc] or "startup_rom_instruction", pc)
	end)
end

local function log_bus(event, address, value)
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute-frame_cycle_start or -1
	local line, dot = ppu_position()
	bus:write(table.concat({
		tostring(source_frame), tostring(emu.framecount()), tostring(absolute), tostring(relative), event,
		hex(address,4), hex(value or 0,2), hex(reg("pc"),4), tostring(line), tostring(dot),
		hex(reg("a"),2), hex(reg("x"),2), hex(reg("y"),2), hex(reg("p"),2),
	}, ",") .. "\n")
end
for _, address in ipairs({0x2000,0x2001,0x2005,0x2006,0x2007}) do
	local watched = address
	memory.registerwrite(watched, 1, function(addr, _, value) log_bus("ppu_write", addr, value) end)
end
local status_read_hook = false
if type(memory.registerread) == "function" then
	status_read_hook = pcall(function()
		memory.registerread(0x2002, 1, function(addr, _, value) log_bus("ppustatus_read", addr, value) end)
	end)
end
metadata:write("ppu_timing_getters_available=" .. tostring(type(ppu) == "table" and type(ppu.getscanline) == "function" and type(ppu.getdot) == "function") .. "\n")
metadata:write("ppustatus_read_hook_registered=" .. tostring(status_read_hook) .. "\n")
metadata:flush()

-- Some FCEUX builds restore a previously opened movie even with --no-config.
-- Record and stop that playback so the saved CSV timeline below is the input.
local startup_movie_active, startup_movie_name, startup_movie_mode = false, "", ""
pcall(function() startup_movie_active = movie.active() end)
pcall(function() startup_movie_name = movie.getname() end)
pcall(function() startup_movie_mode = movie.mode() end)
metadata:write("startup_movie_active=" .. tostring(startup_movie_active) .. "\n")
metadata:write("startup_movie_name=" .. tostring(startup_movie_name) .. "\n")
metadata:write("startup_movie_mode=" .. tostring(startup_movie_mode) .. "\n")
if startup_movie_active then
	local stop_ok, stop_error = pcall(movie.stop)
	metadata:write("startup_movie_stopped=" .. tostring(stop_ok) .. " error=" .. tostring(stop_error or "") .. "\n")
end
local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "emu.poweron failed: " .. tostring(power_error))
pcall(debugger.resetcyclescount)
frame_cycle_start = cycles()
metadata:write("poweron_success=true\ncycle_counter_after_poweron=" .. tostring(frame_cycle_start) .. "\nemulator_frame_after_poweron=" .. tostring(emu.framecount()) .. "\n")
metadata:flush()
pcall(emu.speedmode, "turbo")

for frame=0,LAST_SOURCE_FRAME do
	source_frame = frame
	local before = emu.framecount()
	local cycle_start = cycles()
	local input = inputs[frame]
	joypad.set(1, input)
	emu.frameadvance()
	local after = emu.framecount()
	local cycle_end = cycles()
	local line, dot = ppu_position()
	local bits = {}
	for _, key in ipairs({"up","down","left","right","A","B","start","select"}) do bits[#bits+1] = input[key] and "1" or "0" end
	local ptr = byte(0x004D) + byte(0x004E) * 256
	frames:write(table.concat({frame,before,after,cycle_start,cycle_end,
		cycle_start >= 0 and cycle_end >= cycle_start and cycle_end-cycle_start or -1,
		line,dot,hex(byte(0x001B),2),task_bytes(),hex(ptr,4),table.concat(bits)}, ",") .. "\n")
	frame_cycle_start = cycle_end
	events:flush(); bus:flush(); frames:flush(); metadata:flush()
end
metadata:write("completed_source_frames=" .. (LAST_SOURCE_FRAME+1) .. "\n")
events:close(); bus:close(); frames:close(); metadata:close()
for address in pairs(execution_hooks) do pcall(memory.registerexec, address, 1, nil) end
for _, address in ipairs({0x2000,0x2001,0x2005,0x2006,0x2007}) do pcall(memory.registerwrite, address, 1, nil) end
if status_read_hook then pcall(memory.registerread, 0x2002, 1, nil) end
os.exit()

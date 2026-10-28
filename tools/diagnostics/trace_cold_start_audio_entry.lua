-- Trace the cold-start NMI-to-sound-driver path in a silent FCEUX replay.
-- Evidence only: no captured audio or emulator image is read or exported.

local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local ROM_MD5_EXPECTED = "eaf2b3745263efa4b1afd2b400f68dae" -- PRG+CHR payload, excluding iNES header
local ROM_SHA256_EXPECTED = "4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local INPUT_SHA256_EXPECTED = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
local LAST_SOURCE_FRAME = 283

local run_id = os.date("%Y%m%d_%H%M%S")
local output_root = PROJECT_ROOT .. "/reference/diagnostics/cold_start_audio_entry_trace_20261026"
local output_dir = output_root .. "/run_" .. run_id
os.execute("mkdir -p " .. string.format("%q", output_dir))

local function output(name, header)
	local file = assert(io.open(output_dir .. "/" .. name, "w"))
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
	local value = -1
	pcall(function() value = memory.readbyte(address) end)
	return value or -1
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

local inputs = read_inputs()
local rom_md5 = "unavailable"
pcall(function() rom_md5 = rom.gethash("md5") end)
if rom_md5 ~= ROM_MD5_EXPECTED then
	error("wrong ROM payload: expected MD5 " .. ROM_MD5_EXPECTED .. ", got " .. tostring(rom_md5))
end
if type(memory) ~= "table" or type(memory.registerexec) ~= "function"
		or type(memory.registerwrite) ~= "function" then
	error("FCEUX memory.registerexec/registerwrite APIs are required")
end

local events = output("events.csv",
	"source_frame,emulator_frame,cycle_absolute,cycle_from_frame_start,event_kind,hook_or_address,address,value,callback_pc,a,x,y,s,p,ram_003b,ram_0022,mmc3_select,r0,r1,r2,r3,r4,r5,r6,r7,prg_8000,prg_a000,prg_c000,prg_e000")
local metadata = output("metadata.txt")
metadata:write("rom_path=" .. tostring(rom.getfilename()) .. "\n")
metadata:write("rom_sha256_expected=" .. ROM_SHA256_EXPECTED .. "\n")
metadata:write("rom_gethash_md5_payload=" .. tostring(rom_md5) .. "\n")
metadata:write("rom_md5_payload_expected=" .. ROM_MD5_EXPECTED .. "\n")
metadata:write("input_timeline=" .. INPUT_CSV .. "\n")
metadata:write("input_timeline_sha256_expected=" .. INPUT_SHA256_EXPECTED .. "\n")
metadata:write("input_timeline_sha256_checked_by_lua=false; frames 0-283 are required and parsed\n")
metadata:write("source_frame_range=0-" .. LAST_SOURCE_FRAME .. " inclusive\n")
local startup_movie_active, startup_movie_name, startup_movie_mode = false, "", ""
pcall(function() startup_movie_active = movie.active() end)
pcall(function() startup_movie_name = movie.getname() end)
pcall(function() startup_movie_mode = movie.mode() end)
metadata:write("startup_movie_active=" .. tostring(startup_movie_active) .. "\n")
metadata:write("startup_movie_name=" .. tostring(startup_movie_name) .. "\n")
metadata:write("startup_movie_mode=" .. tostring(startup_movie_mode) .. "\n")
metadata:write("replay=stop any auto-loaded movie, emu.poweron, then exact P1 inputs from input_timeline.csv\n")
metadata:write("audio=must launch FCEUX with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy; Lua mute is not relied on\n")
metadata:write("execution_hooks=$C421,$C449,$8000,$C44C,$C685,$C687,$C68A,$C68C,$C68F,$8366\n")
metadata:write("write_hooks=RAM $003B; MMC3 $8000/$8001; bus writes $4010-$4017\n")
metadata:write("cycle_source=debugger.getcyclescount(); reset immediately after emu.poweron; frame-relative cycle uses the start of each frameadvance\n")
metadata:write("callback_pc_semantics=registerexec rows identify the hooked instruction address; registerwrite callback PC is sampled synchronously after the write and usually points at the next instruction (for example, STA $4010 at $C687 reports $C68A)\n")
metadata:write("bank_semantics=R6/R7 are reconstructed from observed MMC3 $8000/$8001 writes; PRG $C000/$E000 fixed banks are recorded as $1E/$1F\n")
metadata:write("purpose=source timing and state evidence only; no runtime assets/audio are created\n")
metadata:flush()

local current_source_frame = -1
local frame_cycle_start = -1
local mmc3_select = -1
local mmc3_registers = {}
for index=0,7 do mmc3_registers[index] = -1 end

local function mapped_prg_banks()
	if mmc3_select < 0 then return -1, -1 end
	local mode = math.floor(mmc3_select / 64) % 2
	local bank_8000 = mode == 0 and mmc3_registers[6] or mmc3_registers[7]
	local bank_a000 = mode == 0 and mmc3_registers[7] or mmc3_registers[6]
	return bank_8000, bank_a000
end

local function log_event(kind, label, address, value)
	local absolute = cycles_now()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local bank_8000, bank_a000 = mapped_prg_banks()
	events:write(table.concat({
		tostring(current_source_frame), tostring(emu.framecount()), tostring(absolute), tostring(relative),
		kind, label or "", hex(address or -1,4), hex(value or -1,2), hex(register("pc"),4),
		hex(register("a"),2), hex(register("x"),2), hex(register("y"),2),
		hex(register("s"),2), hex(register("p"),2), hex(byte(0x003B),2), hex(byte(0x0022),2),
		hex(mmc3_select,2), hex(mmc3_registers[0],2), hex(mmc3_registers[1],2),
		hex(mmc3_registers[2],2), hex(mmc3_registers[3],2), hex(mmc3_registers[4],2),
		hex(mmc3_registers[5],2), hex(mmc3_registers[6],2), hex(mmc3_registers[7],2),
		hex(bank_8000,2), hex(bank_a000,2), "$1E", "$1F",
	}, ",") .. "\n")
end

for address, label in pairs({
	[0xC421] = "nmi_special_entry_before_BIT_3B",
	[0xC449] = "sound_driver_jsr_site",
	[0x8000] = "mapped_sound_driver_entry_candidate",
	[0xC44C] = "sound_driver_return_site",
	[0xC685] = "cold_start_apu_setup_instruction",
	[0xC687] = "cold_start_store_4010_opcode",
	[0xC68A] = "cold_start_after_4010_store",
	[0xC68C] = "cold_start_store_4017_opcode",
	[0xC68F] = "cold_start_after_4017_store",
	[0x8366] = "sound_driver_store_4015_opcode",
}) do
	local hook_address, hook_label = address, label
	memory.registerexec(hook_address, function()
		log_event("cpu_exec", hook_label, hook_address, -1)
	end)
end

memory.registerwrite(0x003B, 1, function(address, _, value)
	log_event("ram_write", "$003B_write", address, value)
end)

memory.registerwrite(0x8000, 1, function(address, _, value)
	mmc3_select = value or -1
	log_event("mmc3_write", "$8000_select", address, value)
end)
memory.registerwrite(0x8001, 1, function(address, _, value)
	if mmc3_select >= 0 then
		mmc3_registers[mmc3_select % 8] = value or -1
	end
	log_event("mmc3_write", "$8001_data", address, value)
end)

memory.registerwrite(0x4010, 0x08, function(address, _, value)
	log_event("bus_write", "APU_window_or_IO", address, value)
end)

if startup_movie_active then
	local stop_ok, stop_error = pcall(movie.stop)
	metadata:write("startup_movie_stop_ok=" .. tostring(stop_ok) .. " error=" .. tostring(stop_error or "") .. "\n")
	metadata:flush()
end
local power_ok, power_error = pcall(emu.poweron)
if not power_ok then error("emu.poweron failed: " .. tostring(power_error)) end
pcall(debugger.resetcyclescount)
frame_cycle_start = cycles_now()
metadata:write("poweron_success=true\n")
metadata:write("cycle_counter_after_poweron=" .. tostring(frame_cycle_start) .. "\n")
metadata:flush()
pcall(emu.speedmode, "turbo")

for source_frame=0,LAST_SOURCE_FRAME do
	current_source_frame = source_frame
	joypad.set(1, inputs[source_frame])
	frame_cycle_start = cycles_now()
	emu.frameadvance()
	if source_frame % 30 == 0 then events:flush(); metadata:flush() end
end

pcall(emu.speedmode, "normal")
metadata:write("completed_source_frame=" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("events_csv=events.csv\n")
events:close()
metadata:close()
pcall(memory.registerexec, 0xC421, nil)
pcall(memory.registerexec, 0xC449, nil)
pcall(memory.registerexec, 0x8000, nil)
pcall(memory.registerexec, 0xC44C, nil)
pcall(memory.registerexec, 0xC685, nil)
pcall(memory.registerexec, 0xC687, nil)
pcall(memory.registerexec, 0xC68A, nil)
pcall(memory.registerexec, 0xC68C, nil)
pcall(memory.registerexec, 0xC68F, nil)
pcall(memory.registerexec, 0x8366, nil)
pcall(memory.registerwrite, 0x003B, 1, nil)
pcall(memory.registerwrite, 0x8000, 1, nil)
pcall(memory.registerwrite, 0x8001, 1, nil)
pcall(memory.registerwrite, 0x4010, 0x08, nil)
os.exit()

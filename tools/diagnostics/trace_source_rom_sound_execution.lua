-- Execute the supplied cartridge from a fresh power-on with no buttons held.
-- This is a source-execution diagnostic only: it does not read capture files,
-- write PCM, or feed emulator timestamps to a runtime/synthesis build.

local EXPECTED_ROM_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"
local OUTPUT_DIR = os.getenv("CT2_SOURCE_SOUND_TRACE_OUTPUT_DIR")
local FRAME_LIMIT = tonumber(os.getenv("CT2_SOURCE_SOUND_TRACE_FRAMES") or "300")
local START_FRAME = tonumber(os.getenv("CT2_SOURCE_SOUND_TRACE_START_FRAME") or "-1")
assert(OUTPUT_DIR and #OUTPUT_DIR > 0, "set CT2_SOURCE_SOUND_TRACE_OUTPUT_DIR")
assert(FRAME_LIMIT and FRAME_LIMIT > 0 and FRAME_LIMIT <= 5000, "frame limit must be 1..5000")
assert(START_FRAME and START_FRAME >= -1 and START_FRAME < FRAME_LIMIT, "start frame must be -1 or within the run")
os.execute("mkdir -p " .. string.format("%q", OUTPUT_DIR))

local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
assert(md5 == EXPECTED_ROM_MD5,
	"wrong ROM payload MD5: expected " .. EXPECTED_ROM_MD5 .. ", got " .. tostring(md5))
assert(type(memory.registerexec) == "function" and type(memory.registerwrite) == "function",
	"FCEUX memory execution/write hooks are required")

local events = assert(io.open(OUTPUT_DIR .. "/rom_execution_events.csv", "w"))
events:write("sequence,source_frame,emulator_frame,cpu_cycle,event,pc,a,x,y,s,p,script_pointer,script_opcode,script_arg,sound_queue_0700_0704\n")
local apu = assert(io.open(OUTPUT_DIR .. "/apu_writes.csv", "w"))
apu:write("sequence,source_frame,emulator_frame,cpu_cycle,pc,address,value\n")
local sound_queue = assert(io.open(OUTPUT_DIR .. "/sound_queue_writes.csv", "w"))
sound_queue:write("sequence,source_frame,emulator_frame,cpu_cycle,pc,address,value,queue_0700_0704\n")
local frames = assert(io.open(OUTPUT_DIR .. "/frame_cycles.csv", "w"))
frames:write("source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta\n")
local progress = assert(io.open(OUTPUT_DIR .. "/progress.csv", "w"))
progress:write("last_completed_source_frame,emulator_frame,cpu_cycle,rom_exec_rows,apu_rows\n")
local event_rows, apu_rows, queue_rows, frame_rows = {}, {}, {}, {}
local metadata = assert(io.open(OUTPUT_DIR .. "/source_execution.txt", "w"))
metadata:write("rom_payload_md5=" .. tostring(md5) .. "\n")
metadata:write("rom_file=" .. tostring(rom.getfilename()) .. "\n")
metadata:write("input=all buttons false except Start on source frame " .. START_FRAME .. " (-1 means none)\n")
metadata:write("capture_timeline_read=false\n")
metadata:write("captured_pcm_read_or_written=false\n")
metadata:write("cycle_origin=debugger cycle counter reset immediately after scripted emu.poweron\n")
metadata:write("apu_hook=CPU-bus writes to $4000-$4013,$4015,$4017; excludes controller $4016 and OAM DMA $4014\n")
metadata:write("execution_hooks=$C449 NMI sound-driver JSR; $C44C return; $C471 RTI; $C685/$C687/$C68C setup; $8000 driver entry; $9EED foreground scheduler scan; $9FA8 cooperative yield; $84E7 interpreter; $A02A script PC; $85FC ED queue store; $8366 APU status store\n")
metadata:write("sound_queue_hook=CPU-bus writes to $0700-$0704; records the ROM producer and queued byte\n")
metadata:write("dmc_trace=separate opt-in pinned FCEUX sound.cpp hook trace via FCEU_DMC_TRACE_PATH; no PCM capture\n")
metadata:write("rendering=FCEUX maximum-speed mode skips frame presentation; CPU/ROM execution still advances each requested frame\n")
metadata:write("frame_limit=" .. FRAME_LIMIT .. "\n")
metadata:flush()

-- FCEUX may auto-open a movie remembered in its user configuration even when
-- this launch does not pass --playmov. Stop it before the scripted cold power-on
-- so it cannot supply input to the source execution trace.
local startup_movie_active, startup_movie_name, startup_movie_mode = false, "", ""
pcall(function() startup_movie_active = movie.active() end)
pcall(function() startup_movie_mode = movie.mode() end)
if startup_movie_active then
	pcall(function() startup_movie_name = movie.getname() end)
	local stop_ok, stop_error = pcall(movie.stop)
	metadata:write("startup_movie_stop_ok=" .. tostring(stop_ok) .. " error=" .. tostring(stop_error or "") .. "\n")
end
local pre_power_movie_active, pre_power_movie_mode = true, "unavailable"
pcall(function() pre_power_movie_active = movie.active() end)
pcall(function() pre_power_movie_mode = movie.mode() end)
metadata:write("startup_movie_active=" .. tostring(startup_movie_active) .. "\n")
metadata:write("startup_movie_name=" .. tostring(startup_movie_name) .. "\n")
metadata:write("startup_movie_mode=" .. tostring(startup_movie_mode) .. "\n")
metadata:write("pre_power_movie_active=" .. tostring(pre_power_movie_active) .. "\n")
metadata:write("pre_power_movie_mode=" .. tostring(pre_power_movie_mode) .. "\n")
metadata:write("pre_power_input_policy=explicitly set every P1 control false before each frame advance\n")
assert(not pre_power_movie_active, "movie playback/recording remains active before emu.poweron")
metadata:flush()

local current_source_frame = -1
local event_sequence = 0
local apu_sequence = 0
local sound_queue_sequence = 0
local function cycles_now()
	local value = -1
	pcall(function() value = debugger.getcyclescount() end)
	return value or -1
end
local function hex(value, digits)
	if value == nil or value < 0 then return "" end
	return string.format("$%0" .. digits .. "X", value)
end
local function byte(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return value or 0
end
local function queue_string()
	local values = {}
	for address=0x0700,0x0704 do values[#values + 1] = string.format("%02X", byte(address)) end
	return table.concat(values, " ")
end
local function regs()
	return memory.getregister("pc"), memory.getregister("a"), memory.getregister("x"),
		memory.getregister("y"), memory.getregister("s"), memory.getregister("p")
end
local function log_exec(name)
	local pc, a, x, y, s, p = regs()
	local script_pointer = byte(0x004D) + byte(0x004E) * 256
	event_rows[#event_rows + 1] = table.concat({event_sequence, current_source_frame, emu.framecount(), cycles_now(), name,
		hex(pc,4), hex(a,2), hex(x,2), hex(y,2), hex(s,2), hex(p,2), hex(script_pointer,4),
		hex(byte(script_pointer),2), hex(byte(script_pointer + 1),2), queue_string()}, ",") .. "\n"
	event_sequence = event_sequence + 1
end

local exec_points = {
	[0xC449] = "nmi_sound_driver_jsr",
	[0xC44C] = "nmi_sound_driver_return",
	[0xC471] = "nmi_rti",
	[0xC503] = "nmi_fixed_entry",
	[0xC685] = "sound_setup_entry",
	[0xC687] = "sound_setup_after_store",
	[0xC68C] = "sound_setup_apu_write_path",
	[0x8000] = "mapped_sound_driver_entry",
	[0x9EED] = "foreground_scheduler_scan",
	[0x9FA8] = "cooperative_scheduler_yield",
	[0x84E7] = "cutscene_worker_interpreter",
	[0xA02A] = "script_pc_a02a",
	[0x85FC] = "ed_sound_queue_store_instruction",
	[0x8366] = "sound_driver_4015_store_instruction",
}
for address, name in pairs(exec_points) do
	local pc, event_name = address, name
	memory.registerexec(pc, function() log_exec(event_name) end)
end
local function log_apu(address, _, value)
	local pc = memory.getregister("pc")
	apu_rows[#apu_rows + 1] = table.concat({apu_sequence, current_source_frame, emu.framecount(), cycles_now(),
		hex(pc,4), hex(address,4), hex(value or 0,2)}, ",") .. "\n"
	apu_sequence = apu_sequence + 1
end
local function log_sound_queue(address, _, value)
	local pc = memory.getregister("pc")
	queue_rows[#queue_rows + 1] = table.concat({sound_queue_sequence, current_source_frame, emu.framecount(), cycles_now(),
		hex(pc,4), hex(address,4), hex(value or 0,2), queue_string()}, ",") .. "\n"
	sound_queue_sequence = sound_queue_sequence + 1
end
memory.registerwrite(0x4000, 0x14, log_apu)
memory.registerwrite(0x4015, 1, log_apu)
memory.registerwrite(0x4017, 1, log_apu)
memory.registerwrite(0x0700, 5, log_sound_queue)

local ok, err = pcall(emu.poweron)
metadata:write("poweron_success=" .. tostring(ok) .. " error=" .. tostring(err or "") .. "\n")
metadata:flush()
assert(ok, "FCEUX emu.poweron failed: " .. tostring(err))
local post_power_movie_active, post_power_movie_mode = true, "unavailable"
pcall(function() post_power_movie_active = movie.active() end)
pcall(function() post_power_movie_mode = movie.mode() end)
metadata:write("post_power_movie_active=" .. tostring(post_power_movie_active) .. "\n")
metadata:write("post_power_movie_mode=" .. tostring(post_power_movie_mode) .. "\n")
assert(not post_power_movie_active, "movie became active again after emu.poweron")
metadata:flush()
pcall(debugger.resetcyclescount)
pcall(emu.speedmode, "maximum")
pcall(function() io.stdout:setvbuf("line") end)

for source_frame=0,FRAME_LIMIT-1 do
	current_source_frame = source_frame
	local before = emu.framecount()
	local cycle_start = cycles_now()
	joypad.set(1, {up=false, down=false, left=false, right=false, A=false, B=false,
		start=source_frame == START_FRAME, select=false})
	if source_frame == 0 then
		local actual = joypad.get(1)
		assert(actual.up == false and actual.down == false and actual.left == false and actual.right == false
			and actual.A == false and actual.B == false and actual.start == (START_FRAME == 0)
			and actual.select == false, "P1 input is not the requested controlled state before source frame 0")
		metadata:write("frame0_input_confirmed=up,down,left,right,A,B,select=false; start=" .. tostring(START_FRAME == 0) .. "\n")
		metadata:flush()
	end
	emu.frameadvance()
	local after = emu.framecount()
	local cycle_end = cycles_now()
	frame_rows[#frame_rows + 1] = table.concat({source_frame, before, after, cycle_start, cycle_end,
		cycle_end >= cycle_start and cycle_end - cycle_start or -1}, ",") .. "\n"
	if source_frame % 250 == 0 then
		progress:write(table.concat({source_frame, after, cycle_end, event_sequence, apu_sequence}, ",") .. "\n")
		progress:flush()
		print("CT2_SOURCE_TRACE_PROGRESS frame=" .. source_frame)
	end
end

pcall(emu.speedmode, "normal")
events:write(table.concat(event_rows)); apu:write(table.concat(apu_rows))
sound_queue:write(table.concat(queue_rows)); frames:write(table.concat(frame_rows))
progress:write(table.concat({FRAME_LIMIT - 1, emu.framecount(), cycles_now(), event_sequence, apu_sequence}, ",") .. "\n")
metadata:write("completed_source_frames=" .. FRAME_LIMIT .. "\n")
metadata:write("rom_exec_event_count=" .. event_sequence .. "\n")
metadata:write("apu_write_count=" .. apu_sequence .. "\n")
metadata:write("buffered_event_rows_written_at_exit=true\n")
events:close(); apu:close(); sound_queue:close(); frames:close(); progress:close(); metadata:close()
for address in pairs(exec_points) do pcall(memory.registerexec, address, 1, nil) end
pcall(memory.registerwrite, 0x4000, 0x14, nil)
pcall(memory.registerwrite, 0x4015, 1, nil)
pcall(memory.registerwrite, 0x4017, 1, nil)
pcall(memory.registerwrite, 0x0700, 5, nil)
os.exit()

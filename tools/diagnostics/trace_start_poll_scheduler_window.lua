-- Muted same-input FCEUX capture of scheduler/NMI edges around the two Start-poll outliers.
-- FCEUX is only a post-run validation oracle; this script does not feed the ROM-only model.

local PROJECT_ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local INPUT_SHA256_EXPECTED = "195743d71b36da01b5148e46e14733988d3e5d21cf308ab09eaa735daf83d2d3"
local FIRST_SOURCE_FRAME = 3596
local LAST_SOURCE_FRAME = 3603
local OUTPUT_DIR = PROJECT_ROOT .. "/reference/diagnostics/start_poll_rom_source_timing_20261027/fceux_scheduler_window_with_irq"
os.execute("mkdir -p " .. string.format("%q", OUTPUT_DIR))

local inputs = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "missing input timeline")
for line in input_file:lines() do
	line = line:gsub("\r$", "")
	local frame, up, down, left, right, a, b, start, select = line:match(
		"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if frame then
		inputs[tonumber(frame)] = {up=up=="1", down=down=="1", left=left=="1", right=right=="1",
			A=a=="1", B=b=="1", start=start=="1", select=select=="1"}
	end
end
input_file:close()
for frame=0,LAST_SOURCE_FRAME do assert(inputs[frame], "missing source input frame " .. frame) end

local events = assert(io.open(OUTPUT_DIR .. "/events.csv", "w"))
events:write("sequence,source_frame,emulator_frame,cycle_absolute,cycle_from_frame_start,ppu_scanline,ppu_dot,event,hook_pc,a,x,y,sp,p,task_slot,task_delay,script_pointer,ram_001b,ram_001c,ram_001e,ram_0700,stack_lo,stack_hi,caller_pc,input_start\n")
local frames = assert(io.open(OUTPUT_DIR .. "/frame_cycles.csv", "w"))
frames:write("source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,input_start\n")
local metadata = assert(io.open(OUTPUT_DIR .. "/metadata.txt", "w"))
local md5="unavailable"; pcall(function() md5=rom.gethash("md5") end)
metadata:write("rom_md5=" .. tostring(md5) .. "\n")
metadata:write("input_timeline=" .. INPUT_CSV .. "\nsource_frame_range=0-" .. LAST_SOURCE_FRAME .. " inclusive\n")
metadata:write("input_timeline_sha256_expected=" .. INPUT_SHA256_EXPECTED .. "; independently verify before relying on trace\n")
metadata:write("focused_output_frames=" .. FIRST_SOURCE_FRAME .. "-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("audio=disabled at launch with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy; no PCM/WAV\n")
metadata:write("hooks=$9EED scheduler scan entry; $9FA8 cooperative yield; $802C Start poll; $C500 NMI vector and $C506 IRQ vector entries; dynamic JSR-$9FA8 continuation PCs\n")
metadata:write("cycle_source=debugger.getcyclescount() inside execution hooks; frame-relative values use frameadvance boundary samples\n")
metadata:write("task_resume_semantics=continuation PC reconstructed from the stacked JSR return address at $9FA8 entry; hook only reports later execution at that ROM PC\n")
metadata:flush()

local source_frame=-1
local frame_cycle_start=0
local sequence=0
local resume_pcs={}
local function reg(name)
	local ok,v=pcall(memory.getregister,name)
	if ok and type(v)=="number" then return v end
	return -1
end
local function byte(address)
	local ok,v=pcall(memory.readbyte,address)
	if ok and type(v)=="number" then return v end
	return -1
end
local function hex(value)
	if value == nil or value < 0 then return "" end
	return string.format("$%04X", value)
end
local function record(kind, hook_address, caller_pc)
	if source_frame < FIRST_SOURCE_FRAME or source_frame > LAST_SOURCE_FRAME then return end
	local cycle=debugger.getcyclescount()
	local line,dot=-1,-1
	pcall(function() line=ppu.getscanline(); dot=ppu.getdot() end)
	local sp=reg("s")
	local ptr=byte(0x004D)+256*byte(0x004E)
	local fields={sequence,source_frame,emu.framecount(),cycle,cycle-frame_cycle_start,line,dot,kind,
		hex(hook_address),string.format("$%02X",reg("a")%256),string.format("$%02X",reg("x")%256),
		string.format("$%02X",reg("y")%256),string.format("$%02X",sp%256),string.format("$%02X",reg("p")%256),
		string.format("$%02X",byte(0x0000)),string.format("$%02X",byte(0x0001)),hex(ptr),
		string.format("$%02X",byte(0x001B)),string.format("$%02X",byte(0x001C)),
		string.format("$%02X",byte(0x001E)),string.format("$%02X",byte(0x0700)),
		string.format("$%02X",byte(0x0100+((sp+1)%256))),string.format("$%02X",byte(0x0100+((sp+2)%256))),
		hex(caller_pc),inputs[source_frame].start and 1 or 0}
	events:write(table.concat(fields,",") .. "\n")
	sequence=sequence+1
end

local function install(address, event_name)
	local hook_address=address
	memory.registerexec(hook_address,function() record(event_name,hook_address,nil) end)
end

local function install_window_hooks()
	install(0x9EED,"scheduler_scan")
	install(0x802C,"start_poll")
	install(0xC500,"nmi_vector_entry")
	install(0xC506,"irq_vector_entry")
	memory.registerexec(0x9FA8,function()
		local sp=reg("s")
		local stacked=byte(0x0100+((sp+1)%256))+256*byte(0x0100+((sp+2)%256))
		local continuation=(stacked+1)%65536
		if not resume_pcs[continuation] then
			resume_pcs[continuation]=true
			memory.registerexec(continuation,function() record("task_resume",continuation,continuation) end)
		end
		record("cooperative_yield",0x9FA8,continuation)
	end)
end

local ok,err=pcall(emu.poweron)
metadata:write("poweron=" .. tostring(ok) .. " error=" .. tostring(err or "") .. "\n")
metadata:write("cycle_counter_available=" .. tostring(type(debugger.getcyclescount)=="function") .. "\n")
local movie_mode="nil"
pcall(function() movie_mode=tostring(movie.mode()) end)
metadata:write("startup_movie_mode_after_poweron=" .. movie_mode .. "\n")
assert(movie_mode == "nil", "FCEUX unexpectedly loaded a movie; aborting rather than accepting contaminated inputs")
metadata:flush()
pcall(emu.speedmode,"turbo")
for frame=0,LAST_SOURCE_FRAME do
	source_frame=frame
	if frame==FIRST_SOURCE_FRAME then
		install_window_hooks()
		metadata:write("hooks_installed_before_source_frame=" .. frame .. "\n")
		metadata:flush()
	end
	joypad.set(1,inputs[frame])
	frame_cycle_start=debugger.getcyclescount()
	local before=emu.framecount()
	emu.frameadvance()
	local ending=debugger.getcyclescount()
	local after=emu.framecount()
	frames:write(table.concat({frame,before,after,frame_cycle_start,ending,ending-frame_cycle_start,inputs[frame].start and 1 or 0},",") .. "\n")
	if frame%120==0 or frame==LAST_SOURCE_FRAME then events:flush(); frames:flush(); metadata:flush() end
end
pcall(emu.speedmode,"normal")
metadata:write("done_source_frames=" .. (LAST_SOURCE_FRAME+1) .. "\nevent_count=" .. sequence .. "\nresume_pc_count=" .. tostring((function() local n=0; for _ in pairs(resume_pcs) do n=n+1 end; return n end)()) .. "\n")
events:close(); frames:close(); metadata:close()
os.exit()

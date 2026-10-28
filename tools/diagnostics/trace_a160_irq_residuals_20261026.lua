-- Focused, muted FCEUX trace for A160 raster IRQ residuals at source frames
-- 1029, 1760, and 2121. Diagnostic only: no screenshots, WAV, or PCM.
local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local LAST_SOURCE_FRAME = 2121
local TARGETS = {[1029]=true, [1760]=true, [2121]=true}
local run_id = os.date("%Y%m%d_%H%M%S")
local OUT = PROJECT_ROOT .. "/reference/diagnostics/a160_irq_residual_trace_20261026_" .. run_id
os.execute("mkdir -p " .. string.format("%q", OUT))

local inputs = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "cannot read recorded input route")
input_file:read("*l")
for line in input_file:lines() do
	line = line:gsub("\r$", "")
	local f,u,d,l,r,a,b,s,sel = line:match("^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if f then
		inputs[tonumber(f)] = {up=u=="1",down=d=="1",left=l=="1",right=r=="1",
			A=a=="1",B=b=="1",start=s=="1",select=sel=="1"}
	end
end
input_file:close()
for f=0,LAST_SOURCE_FRAME do assert(inputs[f], "missing source frame " .. f) end

local function byte(addr)
	local value=0
	pcall(function() value=memory.readbyte(addr) end)
	return value or 0
end
local function reg(name)
	local value=-1
	pcall(function() value=memory.getregister(name) end)
	return value or -1
end
local function cycles()
	local value=-1
	pcall(function() value=debugger.getcyclescount() end)
	return value or -1
end
local function pos()
	local line,dot=-1,-1
	if type(ppu)=="table" then
		pcall(function() line=ppu.getscanline() end)
		pcall(function() dot=ppu.getdot() end)
	end
	return line or -1,dot or -1
end
local function hex(value,digits)
	if value == nil or value < 0 then return "" end
	return string.format("$%0" .. digits .. "X", value)
end

local md5="unavailable"
pcall(function() md5=rom.gethash("md5") end)
assert(md5 == "eaf2b3745263efa4b1afd2b400f68dae", "wrong supplied ROM MD5: " .. tostring(md5))
assert(type(memory)=="table" and type(memory.registerexec)=="function", "registerexec unavailable")
assert(type(debugger)=="table" and type(debugger.getcyclescount)=="function", "cycle counter unavailable")

local instructions=assert(io.open(OUT .. "/handler_instructions.csv","w"))
instructions:write("source_frame,emulator_frame,cycle_abs,cycle_from_frame_start,event,hook_pc,opcode,a,x,y,s,p,ppu_scanline,ppu_dot,ram_00ec,ram_00ed,bank_select\n")
local writes=assert(io.open(OUT .. "/bus_events.csv","w"))
writes:write("source_frame,emulator_frame,cycle_abs,cycle_from_frame_start,event,address,value,post_store_pc,a,x,y,s,p,ppu_scanline,ppu_dot\n")
local frames=assert(io.open(OUT .. "/frame_cycles.csv","w"))
local progress=assert(io.open(OUT .. "/progress.txt","w"))
local errors=assert(io.open(OUT .. "/callback_errors.csv","w"))
frames:write("source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,ppu_scanline_end,ppu_dot_end\n")
progress:write("source_frame,phase,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end\n")
errors:write("source_frame,emulator_frame,callback,error\n")
local meta=assert(io.open(OUT .. "/metadata.txt","w"))
meta:write("purpose=source-only muted FCEUX opcode/IRQ-boundary trace for A160 residuals\n")
meta:write("rom_md5=" .. tostring(md5) .. "\ninput=" .. INPUT_CSV .. "\nsource_frames=0-" .. LAST_SOURCE_FRAME .. "\n")
meta:write("audio=disabled by --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy\n")
meta:write("hooks=selected instruction boundaries $A160,$A175,$A178,$A17B,$A182,$A187; writes $2000/$2005/$2006 and MMC3 IRQ registers\n")
meta:write("no screenshots, WAV, or PCM are recorded\n")
meta:write("frame_progress=advance-start and advance-complete rows are flushed for every source frame\n")
meta:write("frameadvance=called directly; FCEUX Lua yields inside frameadvance so pcall/xpcall is unsupported; callback errors are trapped in callback_errors.csv, while an unfinished advance is identified by the final advance_started progress row\n")
meta:flush()

local source_frame=-1
local frame_cycle_start=0
local bank_select=0
local function guarded_callback(label, callback)
	return function(...)
		local ok,err=pcall(callback,...)
		if not ok then
			local message=tostring(err):gsub("[\r\n,]"," ")
			errors:write(table.concat({source_frame,emu.framecount(),label,message},",").."\n")
			errors:flush()
		end
	end
end
local function log_instruction(pc)
	if not TARGETS[source_frame] then return end
	local cyc=cycles(); local line,dot=pos()
	instructions:write(table.concat({source_frame,emu.framecount(),cyc,
		cyc>=0 and cyc-frame_cycle_start or -1,"instruction",hex(pc,4),
		hex(byte(pc),2),hex(reg("a"),2),hex(reg("x"),2),hex(reg("y"),2),
		hex(reg("s"),2),hex(reg("p"),2),line,dot,hex(byte(0x00EC),2),
		hex(byte(0x00ED),2),hex(bank_select,2)},",") .. "\n")
end

-- Hook only known raster-handler boundaries. The previous broad range caused
-- callbacks throughout every scanline; these exact entry/store PCs keep the
-- muted replay bounded while retaining actual FCEUX opcode-entry cycles.
for _,pc in ipairs({0xA160,0xA175,0xA178,0xA17B,0xA182,0xA187}) do
	local hook_pc=pc
	memory.registerexec(hook_pc,1,guarded_callback("exec_"..hex(hook_pc,4),function() log_instruction(hook_pc) end))
end

local function log_write(event)
	return function(address,_size,value)
		if not TARGETS[source_frame] then return end
		local cyc=cycles(); local line,dot=pos()
		writes:write(table.concat({source_frame,emu.framecount(),cyc,
			cyc>=0 and cyc-frame_cycle_start or -1,event,hex(address,4),
			hex(value or 0,2),hex(reg("pc"),4),hex(reg("a"),2),
			hex(reg("x"),2),hex(reg("y"),2),hex(reg("s"),2),
			hex(reg("p"),2),line,dot},",") .. "\n")
	end
end
for addr,name in pairs({[0x2000]="PPUCTRL",[0x2005]="PPUSCROLL",[0x2006]="PPUADDR",
	[0xC000]="MMC3_IRQ_LATCH",[0xC001]="MMC3_IRQ_RELOAD",
	[0xE000]="MMC3_IRQ_DISABLE_ACK",[0xE001]="MMC3_IRQ_ENABLE"}) do
	memory.registerwrite(addr,1,guarded_callback("write_"..name,log_write(name)))
end
memory.registerwrite(0x8000,1,guarded_callback("write_MMC3_BANK_SELECT",function(_,_,value) bank_select=value or 0 end))

-- This FCEUX build may restore the last movie even with --no-config 1. Stop it
-- before reset so the saved CSV is the only input source, then assert the state.
assert(type(movie)=="table" and type(movie.active)=="function" and type(movie.stop)=="function",
	"FCEUX movie API unavailable; cannot guarantee the recorded input route")
local startup_movie_active, startup_movie_name, startup_movie_mode = false, "", ""
pcall(function() startup_movie_active = movie.active() end)
pcall(function() startup_movie_name = movie.getname() end)
pcall(function() startup_movie_mode = movie.mode() end)
meta:write("startup_movie_active="..tostring(startup_movie_active).."\n")
meta:write("startup_movie_name="..tostring(startup_movie_name).."\n")
meta:write("startup_movie_mode="..tostring(startup_movie_mode).."\n")
if startup_movie_active then
	local stop_ok, stop_error = pcall(movie.stop)
	meta:write("startup_movie_stop_ok="..tostring(stop_ok).." error="..tostring(stop_error or "").."\n")
end
local movie_check_ok, movie_active_after_stop = pcall(movie.active)
assert(movie_check_ok and not movie_active_after_stop,
	"movie playback/recording remains active before emu.poweron")
meta:write("movie_active_before_poweron="..tostring(movie_active_after_stop).."\n")
meta:flush()

local power_ok,power_err=pcall(emu.poweron)
assert(power_ok,"emu.poweron failed: " .. tostring(power_err))
local movie_active_after_power = true
local post_power_movie_check_ok = pcall(function() movie_active_after_power=movie.active() end)
assert(post_power_movie_check_ok and not movie_active_after_power,
	"movie playback/recording became active after emu.poweron")
pcall(debugger.resetcyclescount)
pcall(emu.speedmode,"turbo")
meta:write("poweron_success=true\nmovie_active_after_poweron=false\n")
meta:flush()
local completed_source_frames=0
for f=0,LAST_SOURCE_FRAME do
	source_frame=f
	local before=emu.framecount()
	frame_cycle_start=cycles()
	joypad.set(1,inputs[f])
	progress:write(table.concat({f,"advance_started",before,"",frame_cycle_start,""},",").."\n")
	progress:flush()
	-- Do not pcall/xpcall this: FCEUX yields across the Lua/C boundary here.
	emu.frameadvance()
	local after=emu.framecount(); local cycle_end=cycles(); local line,dot=pos()
	if TARGETS[f] then
		frames:write(table.concat({f,before,after,frame_cycle_start,cycle_end,
			cycle_end-frame_cycle_start,line,dot},",") .. "\n")
		instructions:flush(); writes:flush(); frames:flush(); meta:flush()
	end
	completed_source_frames=completed_source_frames+1
	progress:write(table.concat({f,"advance_complete",before,after,frame_cycle_start,cycle_end},",").."\n")
	progress:flush()
end
pcall(emu.speedmode,"normal")
meta:write("completed_source_frames=" .. completed_source_frames .. "\n")
meta:write("trace_complete="..tostring(completed_source_frames==LAST_SOURCE_FRAME+1).."\n")
instructions:close(); writes:close(); frames:close(); meta:close(); progress:close(); errors:close()
os.exit()

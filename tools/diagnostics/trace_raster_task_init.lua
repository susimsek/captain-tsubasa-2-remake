-- Trace raster task initialization, preset calls, and saved phase around the
-- field-runner interval. Diagnostic only; no runtime assets are generated.
local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local FIRST_FRAME, LAST_FRAME = 342, 400
local run_id = os.date("%Y%m%d_%H%M%S")
local out = PROJECT_ROOT .. "/reference/diagnostics/raster_task_init_" .. run_id
os.execute("mkdir -p " .. string.format("%q", out))

local inputs = {}
for line in assert(io.open(INPUT_CSV, "r")):lines() do
	local f,u,d,l,r,a,b,s,sel = line:gsub("\r$", ""):match("^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if f then inputs[tonumber(f)] = {up=u=="1",down=d=="1",left=l=="1",right=r=="1",A=a=="1",B=b=="1",start=s=="1",select=sel=="1"} end
end
for f=0,LAST_FRAME do assert(inputs[f], "missing input frame " .. f) end

local trace = assert(io.open(out .. "/events.csv", "w"))
trace:write("source_frame,emulator_frame,cycle_abs,event,pc,a,x,y,s,p,caller,task_0d,stack_0194_01a4,ed,ec,ram_0078_008d,mmc3_select,r6,r7\n")
local writes = assert(io.open(out .. "/writes.csv", "w"))
writes:write("source_frame,emulator_frame,cycle_abs,address,value,pc,task_0d,stack_0194_01a4,ed,ec\n")
local meta = assert(io.open(out .. "/metadata.txt", "w"))
local md5 = "unavailable"; pcall(function() md5 = rom.gethash("md5") end)
meta:write("rom_md5=" .. tostring(md5) .. "\ninputs=" .. INPUT_CSV .. "\nsource_frames=" .. FIRST_FRAME .. "-" .. LAST_FRAME .. "\nreplay=poweron with exact input timeline\naudio=disabled with --sound 0 --volume 0 and SDL dummy output\nfocus=bank-2 A2E8 raster task, bank-0 $8895/$8920 preset/task setup, task slot $0D, scheduler restore\n")

local source_frame = 0
local select_reg = 0
local mmc3 = {0,0,0,0,0,0,0,0}
local function b(addr) local v=0; pcall(function() v=memory.readbyte(addr) end); return v or 0 end
local function reg(name) local v=-1; pcall(function() v=memory.getregister(name) end); return v or -1 end
local function word(addr) return b(addr) + b(addr+1)*256 end
local function hex(v, n) return string.format("$%0" .. n .. "X", v or 0) end
local function stack_snapshot()
	local x={}
	for a=0x0194,0x01A4 do x[#x+1]=string.format("%02X", b(a)) end
	return table.concat(x, " ")
end
local function task_snapshot()
	return string.format("%02X %02X %02X %02X %02X", b(0x000C),b(0x000D),b(0x000E),b(0x000F),b(0x0010))
end
local function caller_pc()
	local s=reg("s")
	if s < 0 then return "" end
	local lo=b(0x0100 + ((s+1)%256))
	local hi=b(0x0100 + ((s+2)%256))
	return hex(((hi*256+lo+1-3)%65536),4)
end
local function log_event(name)
	if source_frame < FIRST_FRAME or source_frame > LAST_FRAME then return end
	local cyc=-1; pcall(function() cyc=debugger.getcyclescount() end)
	local bytes={}; for a=0x0078,0x008D do bytes[#bytes+1]=string.format("%02X",b(a)) end
	trace:write(table.concat({source_frame,emu.framecount(),cyc,name,hex(reg("pc"),4),hex(reg("a"),2),hex(reg("x"),2),hex(reg("y"),2),hex(reg("s"),2),hex(reg("p"),2),caller_pc(),task_snapshot(),stack_snapshot(),hex(b(0x00ED),2),hex(b(0x00EC),2),table.concat(bytes," "),hex(select_reg,2),hex(mmc3[7],2),hex(mmc3[8],2)}, ",") .. "\n")
end
for address,name in pairs({
	[0x8895]="task_install_helper", [0x8920]="preset_loader", [0x8946]="preset_write_79",
	[0xA206]="bank2_service_dispatch", [0xA2E8]="raster_task_entry", [0xA2F8]="raster_task_yield",
	[0xA2FD]="raster_task_resume", [0xA308]="raster_delta_loop", [0xA319]="raster_scroll_low_store",
	[0xA328]="raster_scroll_high_store", [0xA33A]="raster_delta_loop_end",
	[0xA5E8]="candidate_preset5_caller", [0xA5EB]="candidate_task_install_call",
	[0xA5EF]="candidate_preset5_call", [0xA5FF]="candidate_preset6_caller",
	[0xA617]="candidate_preset8_caller", [0xA62D]="candidate_preset7_caller",
	[0x9FA8]="scheduler_yield", [0x9F4D]="scheduler_ram_restore", [0x9EED]="scheduler_scan",
	[0xA160]="raster_irq_handler"
}) do
	local pc=address
	memory.registerexec(pc, function() log_event(name) end)
end
memory.registerwrite(0x8000,1,function(_,_,v) select_reg=v or 0 end)
memory.registerwrite(0x8001,1,function(_,_,v) mmc3[(select_reg%8)+1]=v or 0 end)
local function log_write(address,_,value)
	if source_frame < FIRST_FRAME or source_frame > LAST_FRAME then return end
	local cyc=-1; pcall(function() cyc=debugger.getcyclescount() end)
	writes:write(table.concat({source_frame,emu.framecount(),cyc,hex(address,4),hex(value,2),hex(reg("pc"),4),task_snapshot(),stack_snapshot(),hex(b(0x00ED),2),hex(b(0x00EC),2)},",").."\n")
end
for _,address in ipairs({0x0057,0x00ED,0x00EC,0x000D,0x000E,0x000F,0x0010,0x0078,0x0079,0x007A,0x007B,0x007C,0x007D,0x007E,0x007F,0x0080,0x0081,0x0082,0x0083,0x0084,0x0085,0x0086,0x0087,0x0088,0x0089,0x008A,0x008B,0x008C,0x008D,0x019C}) do
	memory.registerwrite(address,1,log_write)
end

local ok,err=pcall(emu.poweron)
meta:write("poweron="..tostring(ok).." error="..tostring(err or "").."\n")
meta:flush(); pcall(emu.speedmode,"turbo")
for f=0,LAST_FRAME do
	source_frame=f; joypad.set(1,inputs[f]); emu.frameadvance()
	if f%60==0 then trace:flush(); writes:flush(); meta:flush() end
end
meta:write("completed_source_frames="..(LAST_FRAME+1).."\n")
trace:close(); writes:close(); meta:close(); os.exit()

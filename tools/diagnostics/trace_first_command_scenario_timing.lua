-- Muted same-input source timing trace for bank-$10 scenario workers and
-- actor-event release. Run only through the paired Python runner.
-- Output is diagnostic evidence; no capture data is used as runtime input.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_SCENARIO_TIMING_OUTPUT_DIR"), "missing output directory")
local FIRST_FRAME, LAST_FRAME, CHECKPOINT_FRAME = 8400, 8953, 8399
os.execute("mkdir -p " .. string.format("%q", OUT))

local function read_inputs(path, route_format)
	local result, first = {}, true
	local file = assert(io.open(path, "r"), "missing input file " .. path)
	for line in file:lines() do
		line = line:gsub("\r$", "")
		if first then first = false else
			local v = {}
			for value in (line .. ","):gmatch("(.-),") do v[#v + 1] = value end
			local frame = tonumber(v[1])
			if frame then
				local i = route_format and 3 or 2
				result[frame] = {up=v[i]=="1", down=v[i+1]=="1", left=v[i+2]=="1", right=v[i+3]=="1",
					A=v[i+4]=="1", B=v[i+5]=="1", start=v[i+6]=="1", select=v[i+7]=="1"}
			end
		end
	end
	file:close()
	return result
end

local inputs = read_inputs(OPENING_INPUT, false)
for frame, value in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = value end
for frame = 0, LAST_FRAME do assert(inputs[frame], "missing source input frame " .. frame) end

local function output(name, header)
	local f = assert(io.open(OUT .. "/" .. name, "w"))
	if header then f:write(header .. "\n") end
	return f
end
local function b(a)
	local n = 0
	pcall(function() n = memory.readbyte(a) end)
	return type(n)=="number" and n or 0
end
local function w(a) return b(a) + b(a+1)*256 end
local function reg(name)
	local n = -1
	pcall(function() n = memory.getregister(name) end)
	return type(n)=="number" and n or -1
end
local function hx(n, digits)
	if type(n)~="number" or n<0 then return "" end
	return string.format(digits==2 and "$%02X" or "$%04X", n)
end
local function csv(fields)
	local out = {}
	for i,v in ipairs(fields) do out[i] = tostring(v==nil and "" or v):gsub(",", ";") end
	return table.concat(out, ",")
end

local mmc3_select, mmc3 = 0, {0,2,4,5,6,7,0,1}
local function prg_map()
	local r6,r7 = mmc3[7]%32,mmc3[8]%32
	if math.floor(mmc3_select/64)%2==0 then return r6,r7,30,31 end
	return 30,r7,r6,31
end
local function bank(pc)
	if pc>=0xE000 then return 31 elseif pc>=0xC000 then return 30 end
	local r0,r1 = prg_map()
	if pc>=0xA000 then return r1 elseif pc>=0x8000 then return r0 end
	return -1
end

local metadata = output("metadata.txt")
local event_header = "sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,kind,cpu_pc,prg_bank,a,x,y,p,task_slot_0015,task_delay_0016,task_bank_0017,scenario_0518,wait_0519,event_0524,animation_0528,parameter_0529,scenario_cursor_003A,worker_053A_053D,ready_latch_001B,stack_pointer_0100,mapper_select,prg_8000,prg_A000,prg_C000,prg_E000"
local write_header = "sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,kind,cpu_pc,prg_bank,address,old_value,new_value,a,x,y,p,task_slot_0015,task_delay_0016,task_bank_0017,scenario_0518,wait_0519,event_0524,animation_0528,parameter_0529,ready_latch_001B"
local rom_hash="unavailable"; pcall(function() rom_hash=rom.gethash("sha256") or rom_hash end)
metadata:write("source_rom_sha256=" .. tostring(rom_hash) .. "\n")
metadata:write("source_frames=0-" .. LAST_FRAME .. "\ninstrumented_frames=" .. FIRST_FRAME .. "-" .. LAST_FRAME .. "\n")
metadata:write("hooks=task scheduler scan $CA97 and yield $CB0F, scenario entry/dispatch $CBB0/$C50F/$CAE7/$814C/$EC94/$ED5B/$ED5F, actor constructor $80AA/$EE9F, RAM writes $001B/$0015-$0017/$0518-$0519/$0522-$0529/$053A-$053D\n")
metadata:write("scheduler_spin=busy-wait PC $CAAE intentionally omitted; NMI-ready writes to $001B and completed scheduler scans at $CA97 are retained\n")
metadata:write("audio=muted; outputs are source/capture diagnostics only\nsave_state=anonymous in-memory at frame 8399, verified on each load; no numbered slot\n")
metadata:flush()

local frame_now, frame_cycle_start, pass_name, seq_e, seq_w = -1,-1,"",0,0
local events, writes
local function log_event(kind)
	local pc,a,x,y,p = reg("pc"),reg("a"),reg("x"),reg("y"),reg("p")
	local r0,r1,r2,r3=prg_map()
	local cyc=-1; pcall(function() cyc=debugger.getcyclescount() end)
	local emu_frame=-1; pcall(function() emu_frame=emu.framecount() end)
	events:write(csv({seq_e,pass_name,frame_now,emu_frame,cyc-frame_cycle_start,cyc,kind,hx(pc,4),bank(pc),hx(a,2),hx(x,2),hx(y,2),hx(p,2),hx(b(0x0015),2),hx(b(0x0016),2),hx(b(0x0017),2),hx(b(0x0518),2),hx(b(0x0519),2),hx(b(0x0524),2),hx(b(0x0528),2),hx(b(0x0529),2),hx(b(0x003A),2),hx(b(0x053A),2).." "..hx(b(0x053B),2).." "..hx(b(0x053C),2).." "..hx(b(0x053D),2),hx(b(0x001B),2),hx(b(0x0100),2),hx(mmc3_select,2),hx(r0,2),hx(r1,2),hx(r2,2),hx(r3,2)}).."\n")
	seq_e=seq_e+1
end
local last_ram_value = {}
local function log_write(address, new_value)
	local pc,a,x,y,p=reg("pc"),reg("a"),reg("x"),reg("y"),reg("p")
	local cyc=-1; pcall(function() cyc=debugger.getcyclescount() end)
	local emu_frame=-1; pcall(function() emu_frame=emu.framecount() end)
	local old_value=last_ram_value[address]
	writes:write(csv({seq_w,pass_name,frame_now,emu_frame,cyc-frame_cycle_start,cyc,"ram_write",hx(pc,4),bank(pc),hx(address,4),hx(old_value,2),hx(new_value,2),hx(a,2),hx(x,2),hx(y,2),hx(p,2),hx(b(0x0015),2),hx(b(0x0016),2),hx(b(0x0017),2),hx(b(0x0518),2),hx(b(0x0519),2),hx(b(0x0524),2),hx(b(0x0528),2),hx(b(0x0529),2),hx(b(0x001B),2)}).."\n")
	seq_w=seq_w+1
	last_ram_value[address]=new_value
end

local pcs = {
	[0xCA97]="scheduler_scan_CA97",
	[0xCB0F]="task_yield_CB0F", [0xCBB0]="scenario_start_CBB0", [0xC50F]="task_create_C50F",
	[0xCAE7]="task_seed_CAE7", [0x814C]="scenario_event_dispatch_814C", [0xEC94]="scenario_wait_load_EC94",
	[0xED5B]="scenario_wait_decrement_ED5B", [0xED5F]="scenario_wait_compare_ED5F",
	[0xC7EE]="nmi_ready_latch_C7EE", [0x80AA]="actor_F1_constructor_80AA", [0xEE9F]="actor_update_draw_EE9F",
	[0x800F]="animation_worker_entry_800F", [0xC821]="field_irq_C821"
}
local watched = {0x0015,0x0016,0x0017,0x001B,0x0518,0x0519,0x0522,0x0523,0x0524,0x0528,0x0529,0x052A,0x052B,0x052C,0x052D,0x053A,0x053B,0x053C,0x053D,0x0517}
local function attach()
	for _,addr in ipairs(watched) do
		local aa=addr
		last_ram_value[aa]=b(aa)
		memory.registerwrite(aa,1,function(_,_,newv) log_write(aa,newv) end)
	end
	for addr,name in pairs(pcs) do local aa,nn=addr,name; memory.registerexec(aa,function() log_event(nn) end) end
end
local function detach()
	for _,addr in ipairs(watched) do pcall(memory.registerwrite,addr,1,nil) end
	for addr in pairs(pcs) do pcall(memory.registerexec,addr,nil) end
end

local function signature()
	local ram=memory.readbyterange(0,0x800)
	local ppu_mem=ppu.readbyterange(0,0x4000)
	local r0,r1,r2,r3=prg_map()
	local banks={}; for i=1,8 do banks[i]=mmc3[i] end
	return {frame=emu.framecount(),cycles=debugger.getcyclescount(),ram=ram,ppu=ppu_mem,select=mmc3_select,
		banks=banks,prg={r0,r1,r2,r3},mapped={b(0x8000),b(0xA000),b(0xC000),b(0xE000)}}
end
local function verify(s,label)
	local o=signature()
	assert(o.frame==s.frame and o.cycles==s.cycles and o.ram==s.ram and o.ppu==s.ppu and o.select==s.select,label.." state mismatch")
	for i=1,8 do assert(o.banks[i]==s.banks[i],label.." MMC3 mismatch") end
	for i=1,4 do assert(o.prg[i]==s.prg[i] and o.mapped[i]==s.mapped[i],label.." PRG mapping mismatch") end
end

local startup="nil"; pcall(function() startup=tostring(movie.mode()); if movie.mode()~=nil then pcall(movie.stop) end end)
if type(movie.active)=="function" then local active=false; pcall(function() active=movie.active() end); if active then pcall(movie.stop) end end
assert(tostring(movie.mode())=="nil","could not stop startup movie")
memory.registerwrite(0x8000,1,function(_,_,v) mmc3_select=v or 0 end)
memory.registerwrite(0x8001,1,function(_,_,v) mmc3[(mmc3_select%8)+1]=v or 0 end)
assert(pcall(emu.poweron),"emu.poweron failed")
if debugger.resetcyclescount then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode,"turbo")
metadata:write("startup_movie_mode="..startup.."\n")

for frame=0,CHECKPOINT_FRAME do
	frame_now=frame; joypad.set(1,inputs[frame]); frame_cycle_start=debugger.getcyclescount(); emu.frameadvance()
	if frame%600==0 or frame==CHECKPOINT_FRAME then local f=assert(io.open(OUT.."/progress.txt","w")); f:write("warmup:"..frame); f:close() end
end
local checkpoint=savestate.create(); assert(checkpoint,"savestate.create failed")
local sig=signature(); assert(pcall(savestate.save,checkpoint),"savestate.save failed")
assert(pcall(savestate.persist,checkpoint),"savestate.persist failed")
metadata:write("checkpoint_frame="..CHECKPOINT_FRAME.."\ncheckpoint_cycles="..sig.cycles.."\ncheckpoint_signature=RAM2KiB,PPU16KiB,MMC3 banks,PRG map,frame/cycles\n")
metadata:flush()

for pass=1,2 do
	assert(pcall(savestate.load,checkpoint),"savestate.load failed")
	mmc3_select=sig.select; for i=1,8 do mmc3[i]=sig.banks[i] end; verify(sig,"pass"..pass)
	pass_name=tostring(pass); seq_e,seq_w=0,0
	events=output("scheduler_events"..(pass==1 and "" or "_repeat")..".csv",event_header)
	writes=output("scheduler_writes"..(pass==1 and "" or "_repeat")..".csv",write_header)
	attach()
	for frame=FIRST_FRAME,LAST_FRAME do
		frame_now=frame; joypad.set(1,inputs[frame]); frame_cycle_start=debugger.getcyclescount(); emu.frameadvance()
		if frame%30==0 or frame==LAST_FRAME then
			events:flush(); writes:flush(); local f=assert(io.open(OUT.."/progress.txt","w")); f:write(pass..":"..frame); f:close()
		end
	end
	detach(); events:close(); writes:close()
	metadata:write("pass_"..pass.."_events="..seq_e.."\npass_"..pass.."_writes="..seq_w.."\n")
	metadata:flush()
end
metadata:write("complete=true\nreplays=2, same anonymous checkpoint\n")
metadata:close()
pcall(memory.registerwrite,0x8000,1,nil); pcall(memory.registerwrite,0x8001,1,nil)
os.exit()

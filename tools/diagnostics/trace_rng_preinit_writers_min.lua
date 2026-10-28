-- Minimal same-input FCEUX trace for RNG operand writers from frame 7394.
-- Reuses the known-good C9C5 probe's cold replay and the actor trace's anonymous-state pattern.
local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"))
local OUT = assert(os.getenv("CT2_RNG_OPERAND_TRACE_OUTPUT_DIR"))
local OPENING = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local CHECKPOINT_FRAME, FIRST_FRAME, LAST_FRAME = 7393, 7394, 8593
os.execute("mkdir -p " .. string.format("%q", OUT))

local function read_inputs(path, route)
	local result, first = {}, true
	local f = assert(io.open(path, "r"))
	for line in f:lines() do
		if first then first = false else
			local c = {}; for value in (line .. ","):gmatch("(.-),") do c[#c + 1] = value end
			local frame = tonumber(c[1])
			if frame then
				local k = route and 3 or 2
				result[frame] = {up=c[k]=="1", down=c[k+1]=="1", left=c[k+2]=="1", right=c[k+3]=="1",
					A=c[k+4]=="1", B=c[k+5]=="1", start=c[k+6]=="1", select=c[k+7]=="1"}
			end
		end
	end
	f:close(); return result
end
local inputs = read_inputs(OPENING, false)
for frame, value in pairs(read_inputs(ROUTE, true)) do inputs[frame] = value end
for frame = 0, LAST_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local function out(name, header)
	local f = assert(io.open(OUT .. "/" .. name, "w"))
	if header then f:write(header .. "\n") end
	return f
end
local function byte(address) return memory.readbyte(address) or 0 end
local function reg(name)
	local value = -1; pcall(function() value = memory.getregister(name) end); return value
end
local function hex(value, width)
	if type(value) ~= "number" or value < 0 then return "" end
	return width == 2 and string.format("$%02X", value) or string.format("$%04X", value)
end
local function csv(values)
	local fields = {}; for i, value in ipairs(values) do fields[i] = tostring(value == nil and "" or value):gsub(",", ";") end
	return table.concat(fields, ",")
end
local function physical(address) return address >= 0 and address < 0x2000 and address % 0x800 or address end

local meta = out("metadata.txt")
local md5 = rom.gethash("md5")
assert(md5 == "eaf2b3745263efa4b1afd2b400f68dae", "wrong ROM MD5: " .. tostring(md5))
meta:write("purpose=trace pre-frame-8400 RNG operand writers and live C9C5 reads\n")
meta:write("rom_md5=" .. tostring(md5) .. "\nrom_sha256=" .. tostring(os.getenv("CT2_ROM_SHA256") or "") .. "\n")
meta:write("opening_input_sha256=" .. tostring(os.getenv("CT2_OPENING_INPUT_SHA256") or "") .. "\n")
meta:write("route_input_sha256=" .. tostring(os.getenv("CT2_ROUTE_INPUT_SHA256") or "") .. "\n")
meta:write("state_index_sha256=" .. tostring(os.getenv("CT2_STATE_INDEX_SHA256") or "") .. "\n")
meta:write("audio=muted via FCEUX --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy\n")
meta:write("checkpoint=anonymous in-memory FCEUX state at source frame 7393; no numbered slot used\n")
meta:write("pre_checkpoint_writers=not traced before frame 7394; checkpoint bytes are snapshotted\n")
meta:flush()

local frame = -1
local frame_cycle_start = -1
local mmc3_select = 0x07
local mmc3 = {0x00, 0x2E, 0xEA, 0x6B, 0x7A, 0x7B, 0x00, 0x02}
local function banks()
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(mmc3_select / 64) % 2 == 0 then return r6, r7, 30, 31 end
	return 30, r7, r6, 31
end
local function bank_for(pc)
	if pc >= 0xE000 then return select(4, banks()) end
	if pc >= 0xC000 then return select(3, banks()) end
	if pc >= 0xA000 then return select(2, banks()) end
	if pc >= 0x8000 then return select(1, banks()) end
	return -1
end
local function signature()
	local rok, ram = pcall(function() return memory.readbyterange(0, 0x800) end)
	local pok, ppu_mem = pcall(function() return ppu.readbyterange(0, 0x4000) end)
	assert(rok and type(ram)=="string" and #ram==0x800, "CPU RAM read failed")
	assert(pok and type(ppu_mem)=="string" and #ppu_mem==0x4000, "PPU memory read failed")
	local mapped = {byte(0x8000), byte(0xA000), byte(0xC000), byte(0xE000)}
	local b = {banks()}
	return {frame=emu.framecount(), cycles=debugger.getcyclescount(), ram=ram, ppu=ppu_mem,
		select=mmc3_select, regs={mmc3[1],mmc3[2],mmc3[3],mmc3[4],mmc3[5],mmc3[6],mmc3[7],mmc3[8]},
		banks=b, mapped=mapped}
end
local function restore_map(s)
	mmc3_select = s.select; for i=1,8 do mmc3[i]=s.regs[i] end
end
local function verify(s, tag)
	local o=signature()
	assert(o.frame==s.frame,tag.." frame mismatch"); assert(o.cycles==s.cycles,tag.." cycles mismatch")
	assert(o.ram==s.ram,tag.." RAM mismatch"); assert(o.ppu==s.ppu,tag.." PPU mismatch")
	assert(o.select==s.select,tag.." MMC3 select mismatch")
	for i=1,8 do assert(o.regs[i]==s.regs[i],tag.." MMC3 register mirror mismatch") end
	for i=1,4 do assert(o.banks[i]==s.banks[i],tag.." PRG bank mismatch"); assert(o.mapped[i]==s.mapped[i],tag.." mapped byte mismatch") end
	return o
end

local watched = {}
local function watch(a, label) if watched[a] == nil then watched[a]=label end end
for x=0,0x7E do watch(0x300+x,"operand_0300"); watch(0x700+x,"operand_0700"); watch(0x780+x,"operand_0780") end
for x=0xFA,0xFF do watch(0x300+x,"operand_0300"); watch(0x700+x,"operand_0700"); watch(0x780+x,"operand_0780_virtual"); watch(physical(0x780+x),"operand_0780_mirror") end
for _,a in ipairs({0x1B,0xE1,0xE2,0xE3,0x441,0x5FC}) do watch(a,"rng_route_context") end

local startup_mode = tostring(movie.mode())
if startup_mode ~= "nil" then pcall(movie.stop) end
assert(tostring(movie.mode())=="nil", "startup movie remains active")
local ok,err=pcall(emu.poweron); assert(ok,tostring(err))
if type(debugger.resetcyclescount)=="function" then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode,"turbo")
local function progress(s)
	local f=assert(io.open(OUT.."/progress.txt","w")); f:write(s.."\n"); f:close()
end
progress("warmup:starting")
for f=0,CHECKPOINT_FRAME do
	frame=f; joypad.set(1,inputs[f]); frame_cycle_start=debugger.getcyclescount(); emu.frameadvance()
	if f%600==0 or f==CHECKPOINT_FRAME then progress("warmup:"..f) end
end

local checkpoint=signature()
assert(checkpoint.frame==CHECKPOINT_FRAME,"frame-7393 checkpoint frame mismatch")
assert(checkpoint.select==0x07,"frame-7393 MMC3 select mismatch")
local want_regs={0x00,0x2E,0xEA,0x6B,0x7A,0x7B,0x00,0x02}
for i=1,8 do assert(checkpoint.regs[i]==want_regs[i],"frame-7393 MMC3 register mismatch") end
assert(checkpoint.banks[1]==0 and checkpoint.banks[2]==2 and checkpoint.banks[3]==30 and checkpoint.banks[4]==31,"frame-7393 PRG windows mismatch")
assert(checkpoint.mapped[1]==165 and checkpoint.mapped[2]==169 and checkpoint.mapped[3]==170 and checkpoint.mapped[4]==255,"frame-7393 mapped-byte mismatch")
local state=savestate.create(); assert(state~=nil,"anonymous save state creation failed")
local saved,save_err=pcall(savestate.save,state); assert(saved,"save state save failed: "..tostring(save_err))
local persisted,persist_err=pcall(savestate.persist,state); assert(persisted,"save state persist failed: "..tostring(persist_err))
meta:write("checkpoint_frame="..checkpoint.frame.."\ncheckpoint_cycles="..checkpoint.cycles.."\n")
meta:write("checkpoint_mmc3_select=$07\ncheckpoint_mmc3_r0_r7=00 2E EA 6B 7A 7B 00 02 (state_index frame 7393)\n")
meta:write("checkpoint_prg_banks=0,2,30,31\ncheckpoint_mapped_bytes=165,169,170,255\n")
meta:write("checkpoint_ram_ppu_signature=full 2 KiB CPU RAM and 16 KiB PPU memory compared after each load\n")
meta:flush()
local cells=out("checkpoint_operand_cells.csv","x,ram_001b,e1,e2,e3,operand_name,requested_cpu_address,physical_ram_address,requested_value,physical_value")
for x=0xFA,0xFF do for _,v in ipairs({{"$0300+X",0x300+x},{"$0700+X",0x700+x},{"$0780+X",0x780+x}}) do
	local p=physical(v[2]); cells:write(csv({hex(x,2),hex(byte(0x1B),2),hex(byte(0xE1),2),hex(byte(0xE2),2),hex(byte(0xE3),2),v[1],hex(v[2],4),hex(p,4),hex(byte(v[2]),2),hex(byte(p),2)}).."\n")
end end
for x=0,0x7E do for _,v in ipairs({{"$0300+X",0x300+x},{"$0700+X",0x700+x},{"$0780+X",0x780+x}}) do
	local p=physical(v[2]); cells:write(csv({hex(x,2),hex(byte(0x1B),2),hex(byte(0xE1),2),hex(byte(0xE2),2),hex(byte(0xE3),2),v[1],hex(v[2],4),hex(p,4),hex(byte(v[2]),2),hex(byte(p),2)}).."\n")
end end
cells:close()

local call_header="sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,cpu_pc,pc_prg_bank,p_incoming,carry_in,mode_001b,e1_before,e2_before,e3_before,x_after_ldx,addr_0300,ram_0300,tracked_0300,addr_0700,ram_0700,tracked_0700,addr_0780_virtual,addr_0780_physical,ram_0780_virtual,ram_0780_physical,ram_0780_tracked,e1_after,e2_after,e3_after"
local active_pass, current_call, known, dedup, write_seq, call_seq, call_count = 0,nil,{}, {},0,0,0
local write_file, call_file
local function on_write(address,_,new_value)
	local pc=reg("pc"); local p=physical(address); local value=type(new_value)=="number" and new_value or byte(address)
	local cycle=debugger.getcyclescount(); local key=tostring(cycle)..":"..tostring(pc)..":"..tostring(p)..":"..tostring(value)
	if dedup[key] then return end; dedup[key]=true
	local old=known[p]; write_file:write(csv({write_seq,frame,emu.framecount(),cycle-frame_cycle_start,cycle,hex(pc,4),bank_for(pc),hex(address,4),hex(p,4),hex(old or -1,2),hex(value,2),watched[address] or "alias"}).."\n")
	write_seq=write_seq+1; known[p]=value
end
local function begin_call()
	current_call={seq=call_seq,frame=frame,emu_frame=emu.framecount(),cycle=debugger.getcyclescount(),relative=debugger.getcyclescount()-frame_cycle_start,
		p=reg("p"),mode=byte(0x1B),e1=byte(0xE1),e2=byte(0xE2),e3=byte(0xE3),x=-1,a={},v={}}
end
local function read_operand(base)
	if current_call==nil then return end
	local x=current_call.e1; local addr=base+x; local phys=physical(addr)
	current_call.a[base]=addr; current_call.v[base]=byte(addr); current_call["physical_"..base]=phys
end
local function finish_call()
	if current_call==nil then return end
	current_call.e1_after=byte(0xE1); current_call.e2_after=byte(0xE2); current_call.e3_after=byte(0xE3)
	call_file:write(csv({current_call.seq,current_call.frame,current_call.emu_frame,current_call.relative,current_call.cycle,"$C9C5",30,
		hex(current_call.p,2),current_call.p%2,hex(current_call.mode,2),hex(current_call.e1,2),hex(current_call.e2,2),hex(current_call.e3,2),hex(current_call.x,2),
		hex(current_call.a[0x300],4),hex(current_call.v[0x300],2),hex(known[physical(current_call.a[0x300])] or -1,2),
		hex(current_call.a[0x700],4),hex(current_call.v[0x700],2),hex(known[physical(current_call.a[0x700])] or -1,2),
		hex(current_call.a[0x780],4),hex(current_call.physical_1920,4),hex(current_call.v[0x780],2),hex(byte(current_call.physical_1920),2),
		hex(known[current_call.physical_1920] or -1,2),hex(current_call.e1_after,2),hex(current_call.e2_after,2),hex(current_call.e3_after,2)}).."\n")
	call_seq=call_seq+1; call_count=call_count+1; current_call=nil
end
local function attach()
	memory.registerwrite(0x8000,1,function(_,_,v) mmc3_select=v or 0 end)
	memory.registerwrite(0x8001,1,function(_,_,v) mmc3[(mmc3_select%8)+1]=v or 0 end)
	known={}; for a in pairs(watched) do known[physical(a)]=byte(physical(a)) end
	for a in pairs(watched) do local target=a; memory.registerwrite(target,1,function(x,y,v) on_write(x or target,y,v) end) end
	memory.registerexec(0xC9C5,begin_call)
	memory.registerexec(0xC9C8,function() if current_call then current_call.x=reg("x"); read_operand(0x300) end end)
	memory.registerexec(0xC9CB,function() read_operand(0x700) end)
	memory.registerexec(0xC9DC,function() read_operand(0x780) end)
	memory.registerexec(0xC9E8,finish_call)
end
local function detach()
	pcall(memory.registerwrite,0x8000,1,nil); pcall(memory.registerwrite,0x8001,1,nil)
	for a in pairs(watched) do pcall(memory.registerwrite,a,1,nil) end
	for _,a in ipairs({0xC9C5,0xC9C8,0xC9CB,0xC9DC,0xC9E8}) do pcall(memory.registerexec,a,nil) end
end
local function same_signature(a,b)
	assert(a.frame==b.frame and a.cycles==b.cycles and a.ram==b.ram and a.ppu==b.ppu,"repeated final RAM/PPU/timing mismatch")
	assert(a.select==b.select,"repeated final mapper select mismatch")
	for i=1,8 do assert(a.regs[i]==b.regs[i],"repeated final mapper mirror mismatch") end
	for i=1,4 do assert(a.banks[i]==b.banks[i] and a.mapped[i]==b.mapped[i],"repeated final PRG mapping mismatch") end
end
local finals={}
for pass=1,2 do
	local load_ok,load_err=pcall(savestate.load,state); assert(load_ok,"load checkpoint failed: "..tostring(load_err))
	restore_map(checkpoint); verify(checkpoint,"pass "..pass)
	frame=CHECKPOINT_FRAME; active_pass=pass; dedup={}; write_seq=0; call_seq=0; call_count=0; current_call=nil
	local suffix=pass==1 and "" or "_repeat"
	write_file=out("operand_writes_window"..suffix..".csv","sequence,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,cpu_pc,pc_prg_bank,cpu_address,physical_ram_address,old_value,new_value,region")
	call_file=out("c9c5_calls_window"..suffix..".csv",call_header)
	local start_ram=out("window_start"..suffix..".bin"); start_ram:write(checkpoint.ram); start_ram:close()
	attach()
	for f=FIRST_FRAME,LAST_FRAME do
		frame=f; joypad.set(1,inputs[f]); frame_cycle_start=debugger.getcyclescount(); emu.frameadvance()
		if f%30==0 or f==LAST_FRAME then progress("pass"..pass..":"..f) end
	end
	assert(current_call==nil,"trace ended in C9C5 call")
	finals[pass]=signature()
	local end_ram=out("window_end"..suffix..".bin"); end_ram:write(finals[pass].ram); end_ram:close()
	assert(call_count==133,"expected 133 C9C5 calls, got "..call_count)
	meta:write("pass_"..pass.."_checkpoint_verified=true\npass_"..pass.."_c9c5_calls="..call_count.."\npass_"..pass.."_operand_writes="..write_seq.."\n")
	meta:write("pass_"..pass.."_end_frame="..finals[pass].frame.."\npass_"..pass.."_end_cycles="..finals[pass].cycles.."\n")
	meta:flush(); write_file:close(); call_file:close(); detach()
end
same_signature(finals[1],finals[2])
local function read_all(path) local f=assert(io.open(OUT.."/"..path,"rb")); local s=f:read("*a"); f:close(); return s end
for _,name in ipairs({"operand_writes_window.csv","c9c5_calls_window.csv","window_start.bin","window_end.bin"}) do
	local repeat_name=name:gsub("%.csv$","_repeat.csv"):gsub("window_start.bin$","window_start_repeat.bin"):gsub("window_end.bin$","window_end_repeat.bin")
	assert(read_all(name)==read_all(repeat_name),"repeated output differs: "..name)
end
meta:write("pass_1_and_2_final_signatures_match=true\nreplay_passes=2\ncompletion_marker=pass2:8593\n")
meta:close(); progress("pass2:8593"); pcall(os.exit)

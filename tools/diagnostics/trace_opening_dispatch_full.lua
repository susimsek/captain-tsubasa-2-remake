-- Full silent dispatcher trace for the cold-start opening through title endpoint.
-- Replays the established per-frame input capture; records execution evidence only.
local PROJECT_ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
local ROM_PATH = PROJECT_ROOT .. "/Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local LAST_SOURCE_FRAME = 4692
local run_id = os.date("%Y%m%d_%H%M%S")
local out_dir = PROJECT_ROOT .. "/reference/diagnostics/opening_dispatch_full_" .. run_id
os.execute("mkdir -p " .. string.format("%q", out_dir))

local inputs = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "missing source input timeline")
for line in input_file:lines() do
	local frame, up, down, left, right, a, b, start, select = line:gsub("\r$", ""):match(
		"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if frame then inputs[tonumber(frame)] = {up=up=="1",down=down=="1",left=left=="1",right=right=="1",A=a=="1",B=b=="1",start=start=="1",select=select=="1"} end
end
input_file:close()
for f=0,LAST_SOURCE_FRAME do assert(inputs[f], "missing input frame " .. f) end

local function output(name, header)
	local f = assert(io.open(out_dir .. "/" .. name, "w"))
	if header then f:write(header .. "\n") end
	return f
end
local dispatch = output("dispatch.csv", "seq,source_frame,emulator_frame,event,pc,script_ptr,opcode,arg,expected_handler_pc,register_a,register_x,register_y,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000,r0,r1,r2,r3,r4,r5,r6,r7,next_ptr,next_opcode,next_frame")
local map_events = output("mmc3_writes.csv", "source_frame,emulator_frame,pc,script_ptr,address,value,select,r0,r1,r2,r3,r4,r5,r6,r7,prg_8000,prg_a000,prg_c000,prg_e000")
local meta = output("metadata.txt")
local md5 = "unavailable"; pcall(function() md5 = rom.gethash("md5") end)
meta:write("rom_md5=" .. tostring(md5) .. "\nrom_path=" .. ROM_PATH .. "\ninput=" .. INPUT_CSV .. "\nsource_frames=0-" .. LAST_SOURCE_FRAME .. "\nsource_frame_0_drives_first_frameadvance=true\naudio=disabled by launch flags --sound 0 --volume 0; SDL_AUDIODRIVER=dummy\n")
meta:write("capture=power-on replay of existing 4,693-frame input timeline; source frame 4661 starts title input; endpoint source frame 4692 is the established title-menu reference frame; no menu choice is confirmed\n")
meta:write("hooks=interpreter PC $84E7; all unique E8-FF handler entries computed from bank-0 vector words at $8545/$8546 with RTS +1; common advance $8879; MMC3 writes $8000/$8001\n")

local function reg(name)
	local v; pcall(function() v=memory.getregister(name) end); return v or -1
end
local function b(addr) local v; pcall(function() v=memory.readbyte(addr) end); return v or 0 end
local function word(addr) return b(addr)+256*b(addr+1) end
local function hex4(v) return string.format("$%04X", v or 0) end
local function hex2(v) return string.format("$%02X", v or 0) end
local function csv(values)
	local out={}
	for i,v in ipairs(values) do out[i]=tostring(v or "") end
	return table.concat(out,",")
end
local current_source_frame, current_dispatch = 0, nil
local seq, full_select = 0, 0
local mmc3 = {0,0,0,0,0,0,0,0}
local known = {false,false,false,false,false,false,false,false}
local function prg_map()
	local last, second = 31, 30 -- supplied ROM has 32 physical 8-KiB PRG banks
	local r6, r7 = (mmc3[7] or 0) % 32, (mmc3[8] or 0) % 32
	if math.floor(full_select / 64) % 2 == 0 then return r6,r7,second,last end
	return second,r7,r6,last
end
local function map_string()
	local a,c,d,e = prg_map()
	return hex2(a),hex2(c),hex2(d),hex2(e)
end
local function ptr() return word(0x004d) end
local function command_at(p)
	if p < 0xa000 or p > 0xbffe then return 0,0 end
	return b(p),b(p+1)
end
local function common_fields()
	local p=ptr(); local op,arg=command_at(p); local a,c,d,e=prg_map()
	return p,op,arg,a,c,d,e
end
local function log_dispatch(event, handler_pc)
	local p,op,arg,a,c,d,e=common_fields()
	local nextptr,nextop,nextframe="",""
	if event=="interpreter" and current_dispatch then
		nextptr=hex4(p); nextop=hex2(op); nextframe=tostring(current_source_frame)
		dispatch:write(csv({current_dispatch.seq,current_dispatch.source_frame,current_dispatch.emulator_frame,"continuation",current_dispatch.pc,current_dispatch.ptr,current_dispatch.opcode,current_dispatch.arg,current_dispatch.handler_pc,current_dispatch.a,current_dispatch.x,current_dispatch.y,current_dispatch.select,current_dispatch.b8000,current_dispatch.ba000,current_dispatch.bc000,current_dispatch.be000,current_dispatch.r[1],current_dispatch.r[2],current_dispatch.r[3],current_dispatch.r[4],current_dispatch.r[5],current_dispatch.r[6],current_dispatch.r[7],current_dispatch.r[8],nextptr,nextop,nextframe}).."\n")
		current_dispatch=nil
	end
	if event=="interpreter" then
		seq=seq+1
		local expected = (op>=0xe8 and op<=0xff and handler_by_opcode[op]) or ((op>=0xd8 and op<=0xdf) and 0x8508) or ((op>=0xe0 and op<=0xe7) and 0x8520) or nil
		current_dispatch={seq=seq,source_frame=current_source_frame,emulator_frame=emu.framecount(),pc=hex4(reg("pc")),ptr=hex4(p),opcode=hex2(op),arg=hex2(arg),handler_pc=expected and hex4(expected) or "",a=reg("a"),x=reg("x"),y=reg("y"),select=hex2(full_select),b8000=hex2(a),ba000=hex2(c),bc000=hex2(d),be000=hex2(e),r={}}
		for i=1,8 do current_dispatch.r[i]=hex2(mmc3[i]) end
		dispatch:write(csv({seq,current_source_frame,emu.framecount(),"interpreter",hex4(reg("pc")),hex4(p),hex2(op),hex2(arg),current_dispatch.handler_pc,reg("a"),reg("x"),reg("y"),hex2(full_select),hex2(a),hex2(c),hex2(d),hex2(e),current_dispatch.r[1],current_dispatch.r[2],current_dispatch.r[3],current_dispatch.r[4],current_dispatch.r[5],current_dispatch.r[6],current_dispatch.r[7],current_dispatch.r[8],"","",""}).."\n")
	elseif event=="handler" then
		local drec=current_dispatch
		dispatch:write(csv({drec and drec.seq or "",current_source_frame,emu.framecount(),"handler",hex4(reg("pc")),hex4(p),hex2(op),hex2(arg),handler_pc,reg("a"),reg("x"),reg("y"),hex2(full_select),hex2(a),hex2(c),hex2(d),hex2(e),hex2(mmc3[1]),hex2(mmc3[2]),hex2(mmc3[3]),hex2(mmc3[4]),hex2(mmc3[5]),hex2(mmc3[6]),hex2(mmc3[7]),hex2(mmc3[8]),"","",""}).."\n")
	else
		dispatch:write(csv({current_dispatch and current_dispatch.seq or "",current_source_frame,emu.framecount(),event,hex4(reg("pc")),hex4(p),hex2(op),hex2(arg),"",reg("a"),reg("x"),reg("y"),hex2(full_select),hex2(a),hex2(c),hex2(d),hex2(e),hex2(mmc3[1]),hex2(mmc3[2]),hex2(mmc3[3]),hex2(mmc3[4]),hex2(mmc3[5]),hex2(mmc3[6]),hex2(mmc3[7]),hex2(mmc3[8]),"","",""}).."\n")
	end
end

-- The vector table holds RTS return addresses. RTS resumes at stored word + 1.
handler_by_opcode = {}
local hooked = {}
for opcode=0xe8,0xff do
	local i=opcode-0xe8
	local low=b(0x8545+2*i)
	local high=b(0x8546+2*i)
	local entry=low+256*high+1
	handler_by_opcode[opcode]=entry
	if not hooked[entry] then
		hooked[entry]=true
		memory.registerexec(entry,function() log_dispatch("handler",hex4(entry)) end)
	end
	meta:write(string.format("vector_%02X_return_word=%04X entry_pc=%04X\n",opcode,low+256*high,entry))
end

memory.registerexec(0x84e7,function() log_dispatch("interpreter") end)
memory.registerexec(0x8508,function() log_dispatch("inline_D8_DF") end)
memory.registerexec(0x8520,function() log_dispatch("inline_E0_E7") end)
memory.registerexec(0x8879,function() log_dispatch("common_advance") end)
memory.registerwrite(0x8000,1,function(_,_,value)
	full_select=value or 0
	local p=ptr(); local a,c,d,e=prg_map()
	map_events:write(csv({current_source_frame,emu.framecount(),hex4(reg("pc")),hex4(p),"$8000",hex2(value),hex2(full_select),hex2(mmc3[1]),hex2(mmc3[2]),hex2(mmc3[3]),hex2(mmc3[4]),hex2(mmc3[5]),hex2(mmc3[6]),hex2(mmc3[7]),hex2(mmc3[8]),hex2(a),hex2(c),hex2(d),hex2(e)}).."\n")
end)
memory.registerwrite(0x8001,1,function(_,_,value)
	local index=full_select%8+1; mmc3[index]=value or 0; known[index]=true
	local p=ptr(); local a,c,d,e=prg_map()
	map_events:write(csv({current_source_frame,emu.framecount(),hex4(reg("pc")),hex4(p),"$8001",hex2(value),hex2(full_select),hex2(mmc3[1]),hex2(mmc3[2]),hex2(mmc3[3]),hex2(mmc3[4]),hex2(mmc3[5]),hex2(mmc3[6]),hex2(mmc3[7]),hex2(mmc3[8]),hex2(a),hex2(c),hex2(d),hex2(e)}).."\n")
end)

local ok,err=pcall(emu.poweron)
meta:write("poweron_success="..tostring(ok).." error="..tostring(err or "").."\n")
meta:flush()
pcall(emu.speedmode,"turbo")
for f=0,LAST_SOURCE_FRAME do
	current_source_frame=f
	joypad.set(1,inputs[f])
	emu.frameadvance()
	if f%120==0 then dispatch:flush(); map_events:flush(); meta:flush() end
end
if current_dispatch then
	local p=ptr(); local op,arg=command_at(p); local a,c,d,e=prg_map()
	dispatch:write(csv({current_dispatch.seq,current_dispatch.source_frame,current_dispatch.emulator_frame,"endpoint_no_next_dispatch",current_dispatch.pc,current_dispatch.ptr,current_dispatch.opcode,current_dispatch.arg,current_dispatch.handler_pc,current_dispatch.a,current_dispatch.x,current_dispatch.y,current_dispatch.select,current_dispatch.b8000,current_dispatch.ba000,current_dispatch.bc000,current_dispatch.be000,current_dispatch.r[1],current_dispatch.r[2],current_dispatch.r[3],current_dispatch.r[4],current_dispatch.r[5],current_dispatch.r[6],current_dispatch.r[7],current_dispatch.r[8],hex4(p),hex2(op),tostring(current_source_frame)}).."\n")
end
meta:write("completed_source_frames="..(LAST_SOURCE_FRAME+1).."\n")
meta:write("mapper_known_register_mask=")
local mask=0; for i=1,8 do if known[i] then mask=mask+2^(i-1) end end
meta:write(string.format("%02X\n",mask))
meta:flush(); dispatch:close(); map_events:close(); meta:close()
for address in pairs(hooked) do pcall(memory.registerexec,address,1,nil) end
pcall(memory.registerexec,0x84e7,1,nil); pcall(memory.registerexec,0x8508,1,nil); pcall(memory.registerexec,0x8520,1,nil); pcall(memory.registerexec,0x8879,1,nil)
pcall(memory.registerwrite,0x8000,1,nil); pcall(memory.registerwrite,0x8001,1,nil)
os.exit()

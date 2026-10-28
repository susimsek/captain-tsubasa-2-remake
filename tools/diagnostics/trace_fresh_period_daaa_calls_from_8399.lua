-- Muted, two-pass trace of the fresh slot-$05 setup from $DAAA through $DAD8.
-- Diagnostic only; save state and all captured values stay out of game runtime.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_DAAA_TRACE_OUTPUT_DIR"), "missing output directory")
local CHECKPOINT_FRAME = 8399
local FIRST_FRAME = 8400
local MAX_FRAME = 8500
os.execute("mkdir -p " .. string.format("%q", OUT))

local function read_inputs(path, route_format)
	local result, first = {}, true
	local file = assert(io.open(path, "r"), "missing input file " .. path)
	for line in file:lines() do
		line = line:gsub("\r$", "")
		if first then first = false else
			local values = {}
			for value in (line .. ","):gmatch("(.-),") do values[#values + 1] = value end
			local frame = tonumber(values[1])
			if frame then
				local i = route_format and 3 or 2
				result[frame] = {up=values[i]=="1",down=values[i+1]=="1",left=values[i+2]=="1",right=values[i+3]=="1",
					A=values[i+4]=="1",B=values[i+5]=="1",start=values[i+6]=="1",select=values[i+7]=="1"}
			end
		end
	end
	file:close()
	return result
end

local inputs = read_inputs(OPENING_INPUT, false)
for frame, input in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = input end
for frame = 0, MAX_FRAME do assert(inputs[frame], "missing recorded input frame " .. frame) end

local function output(name, header)
	local file = assert(io.open(OUT .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end
local function byte(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return type(value) == "number" and value or 0
end
local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return type(value) == "number" and value or -1
end
local function hex(value, digits)
	if type(value) ~= "number" or value < 0 then return "" end
	return string.format(digits == 2 and "$%02X" or "$%04X", value)
end
local function csv(fields)
	local result = {}
	for index, value in ipairs(fields) do result[index] = tostring(value == nil and "" or value):gsub(",", ";") end
	return table.concat(result, ",")
end
local function byte_range(first, count)
	local values = {}
	for offset = 0, count - 1 do values[#values + 1] = string.format("%02X", byte(first + offset)) end
	return table.concat(values, " ")
end
local function progress(value)
	local file = assert(io.open(OUT .. "/progress.txt", "w"))
	file:write(value .. "\n"); file:close()
end

local mmc3_select, mmc3 = 0, {0,2,4,5,6,7,0,1}
local function copy_mmc3()
	local copy = {}
	for i = 1, 8 do copy[i] = mmc3[i] end
	return copy
end
local function prg_map()
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(mmc3_select / 64) % 2 == 0 then return r6, r7, 30, 31 end
	return 30, r7, r6, 31
end
local function bank(pc)
	if pc >= 0xE000 then return select(4, prg_map()) end
	if pc >= 0xC000 then return select(3, prg_map()) end
	local r0, r1 = prg_map()
	if pc >= 0xA000 then return r1 elseif pc >= 0x8000 then return r0 end
	return -1
end
local function map_text()
	local a,b,c,d = prg_map()
	return string.format("%02X/%02X/%02X/%02X", a,b,c,d)
end
local function stack_top()
	local sp = reg("s")
	local values = {}
	if sp < 0 then return "" end
	for offset = 1, 8 do values[#values + 1] = string.format("%02X", byte(0x0100 + ((sp + offset) % 0x100))) end
	return table.concat(values, " ")
end
local function state_contract()
	return table.concat({
		byte_range(0x0022, 4), byte_range(0x0034, 4), byte_range(0x0700, 5),
		byte_range(0x0015, 0x18), byte_range(0x0515, 5), byte_range(0x05FB, 1),
	}, " | ")
end

local metadata = output("metadata.txt")
local rom_sha256 = "unavailable"
pcall(function() rom_sha256 = tostring(rom.gethash("sha256") or rom_sha256) end)
metadata:write("rom_sha256=" .. rom_sha256 .. "\n")
metadata:write("emulator=FCEUX 2.7.0; NTSC; NewPPU; audio muted\n")
metadata:write("scope=first slot-$05 fresh setup; begin at first source $DAAA and stop on source $DAD8\n")
metadata:write("call_hooks=$DAAA/$CBF1/$DAAF/$CF4F/$CF55/$DAB2/$CE2D/$DAC0/$8039/$DAC4/$DB24/$DB34/$DB42/$8003/$DB46/$DAC7/$EF7F/$EF92/$EF95/$EF96/$800C/$EF99/$DACC/$DACE/$DAD1/$DAD8\n")
metadata:write("ram_writes=all CPU internal RAM writes from $DAAA through first $DAD8, including stack page; this is trace evidence only\n")
metadata:write("save_state=anonymous in-memory at source frame 8399; savestate.persist called; signature checked after both loads; no numbered slot\n")
metadata:flush()

local call_header = "sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,event,pc,prg_bank,a,x,y,p,sp,prg_map,mmc3_select,ram_0022_0025,ram_0034_0037,queue_0700_0704,task_state_0015_002c,wait_state_0515_0519,side_05fb,stack_top_sp_plus_1_to_8"
local write_header = "sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc,prg_bank,address,old,new,a,x,y,p,sp,prg_map,mmc3_select"
local frame_now, frame_cycle_start, pass_name = -1, -1, ""
local active = false
local reached_dad8 = false
local calls, writes
local call_sequence, write_sequence = 0, 0
local old_ram = {}
local function cycle_now()
	local cycles = -1
	pcall(function() cycles = debugger.getcyclescount() end)
	return cycles
end
local function log_call(name)
	local pc, a, x, y, p, sp = reg("pc"), reg("a"), reg("x"), reg("y"), reg("p"), reg("s")
	local cycles, emu_frame = cycle_now(), emu.framecount()
	calls:write(csv({call_sequence, pass_name, frame_now, emu_frame, cycles-frame_cycle_start, cycles,
		name, hex(pc,4), bank(pc), hex(a,2), hex(x,2), hex(y,2), hex(p,2), hex(sp,2), map_text(),
		hex(mmc3_select,2), byte_range(0x0022,4), byte_range(0x0034,4), byte_range(0x0700,5),
		byte_range(0x0015,0x18), byte_range(0x0515,5), hex(byte(0x05FB),2), stack_top()}) .. "\n")
	call_sequence = call_sequence + 1
	if pc == 0xDAD8 then reached_dad8 = true end
end
local function log_write(address, old_value, new_value)
	if not active or reached_dad8 then return end
	local pc, a, x, y, p, sp = reg("pc"), reg("a"), reg("x"), reg("y"), reg("p"), reg("s")
	local cycles, emu_frame = cycle_now(), emu.framecount()
	writes:write(csv({write_sequence, pass_name, frame_now, emu_frame, cycles-frame_cycle_start, cycles,
		hex(pc,4), bank(pc), hex(address,4), hex(old_value,2), hex(new_value,2), hex(a,2), hex(x,2),
		hex(y,2), hex(p,2), hex(sp,2), map_text(), hex(mmc3_select,2)}) .. "\n")
	write_sequence = write_sequence + 1
	old_ram[address] = new_value
end

local hooks = {
	[0xDAAA]={"fresh_period_DAAA",30}, [0xCBF1]={"sound_queue_CBF1",30}, [0xDAAF]={"return_CBF1_DAAF",30},
	[0xCF4F]={"fresh_record_setup_CF4F",30}, [0xCF52]={"record_pointer_call_CD7C",30},
	[0xCD7C]={"record_pointer_CD7C",30}, [0xCF55]={"return_CD7C_CF55",30}, [0xCF71]={"return_CF4F_CF71",30},
	[0xDAB2]={"return_CF4F_DAB2",30}, [0xDABD]={"map_banks_1a_1b_call_CE2D",30}, [0xCE2D]={"mapper_helper_CE2D",30},
	[0xDAC0]={"return_CE2D_DAC0",30}, [0xDAC1]={"bank1a_setup_call_8039",30}, [0x8039]={"bank1a_entry_8039",0x1A},
	[0xDAC4]={"return_bank1a_8039_DAC4",30}, [0xDB24]={"fresh_match_dispatch_DB24",30}, [0xDB34]={"fresh_opponent_branch_DB34",30},
	[0xDB42]={"return_CE2D_DB42",30}, [0x8003]={"bank1c_entry_8003",0x1C}, [0xDB46]={"return_bank1c_8003_DB46",30},
	[0xDAC7]={"return_DB24_DAC7",30}, [0xDAC9]={"fade_call_1_EF7F",30}, [0xEF7F]={"bank18_wrapper_EF7F",31},
	[0xEF92]={"wrapper_map_call_CE2D",31}, [0xEF95]={"return_wrapper_map_EF95",31}, [0xEF96]={"bank18_call_800C",31},
	[0x800C]={"bank18_entry_800C",0x18}, [0xEF99]={"return_bank18_800C_EF99",31}, [0xDACC]={"return_EF7F_DACC",30},
	[0xDACE]={"fade_call_2_EF7F",30}, [0xDAD1]={"return_EF7F_DAD1",30}, [0xDAD4]={"selector_branch_test_DAD4",30},
	[0xDAD6]={"selector_branch_DAD6",30}, [0xDAD8]={"scenario35_caller_DAD8",30},
}

local function attach_pass()
	memory.registerwrite(0x0000, 0x0800, function(address, old_value, new_value)
		if active then log_write(address, old_value, new_value) end
	end)
	for address, descriptor in pairs(hooks) do
		local hook_pc, name, expected_bank = address, descriptor[1], descriptor[2]
		memory.registerexec(hook_pc, function()
			if bank(reg("pc")) ~= expected_bank then return end
			if hook_pc == 0xDAAA then active = true end
			if active then log_call(name) end
		end)
	end
	memory.registerwrite(0x8000,1,function(_,_,value) mmc3_select=value or 0 end)
	memory.registerwrite(0x8001,1,function(_,_,value) mmc3[(mmc3_select%8)+1]=value or 0 end)
end
local function detach_pass()
	pcall(memory.registerwrite, 0x0000, 0x0800, nil)
	for address in pairs(hooks) do pcall(memory.registerexec, address, nil) end
	pcall(memory.registerwrite,0x8000,1,nil); pcall(memory.registerwrite,0x8001,1,nil)
end

local function signature()
	local ram_ok, ram = pcall(function() return memory.readbyterange(0,0x0800) end)
	local ppu_ok, ppu_mem = pcall(function() return ppu.readbyterange(0,0x4000) end)
	assert(ram_ok and type(ram)=="string" and #ram==0x0800, "CPU RAM signature unavailable")
	assert(ppu_ok and type(ppu_mem)=="string" and #ppu_mem==0x4000, "PPU memory signature unavailable")
	local r0,r1,r2,r3=prg_map()
	return {frame=emu.framecount(),cycles=debugger.getcyclescount(),ram=ram,ppu=ppu_mem,select=mmc3_select,banks=copy_mmc3(),
		map={r0,r1,r2,r3},mapped={byte(0x8000),byte(0xA000),byte(0xC000),byte(0xE000)}}
end
local function restore_map(saved)
	mmc3_select=saved.select
	for i=1,8 do mmc3[i]=saved.banks[i] end
end
local function verify_signature(saved, label)
	local current=signature()
	assert(current.frame==saved.frame and current.cycles==saved.cycles,label.." frame/cycle mismatch")
	assert(current.ram==saved.ram and current.ppu==saved.ppu,label.." RAM/PPU mismatch")
	assert(current.select==saved.select,label.." MMC3 selector mismatch")
	for i=1,8 do assert(current.banks[i]==saved.banks[i],label.." MMC3 bank mismatch") end
	for i=1,4 do assert(current.map[i]==saved.map[i] and current.mapped[i]==saved.mapped[i],label.." PRG mapping mismatch") end
end

local startup = "nil"
pcall(function() startup=tostring(movie.mode()); if movie.mode()~=nil then pcall(movie.stop) end end)
if type(movie.active)=="function" then local active_movie=false; pcall(function() active_movie=movie.active() end); if active_movie then pcall(movie.stop) end end
assert(tostring(movie.mode())=="nil", "could not stop FCEUX startup movie")
memory.registerwrite(0x8000,1,function(_,_,value) mmc3_select=value or 0 end)
memory.registerwrite(0x8001,1,function(_,_,value) mmc3[(mmc3_select%8)+1]=value or 0 end)
assert(pcall(emu.poweron), "emu.poweron failed")
if debugger.resetcyclescount then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode,"turbo")
metadata:write("startup_movie_mode="..startup.."\n")
progress("after_poweron")
for frame=0,CHECKPOINT_FRAME do
	joypad.set(1,inputs[frame]); emu.frameadvance()
	if frame%100==0 or frame==CHECKPOINT_FRAME then progress("warmup:"..frame) end
end
local checkpoint=assert(savestate.create(),"savestate.create failed")
local saved=signature()
assert(pcall(savestate.save,checkpoint),"savestate.save failed")
assert(pcall(savestate.persist,checkpoint),"savestate.persist failed")
metadata:write("checkpoint_frame="..saved.frame.."\ncheckpoint_cycles="..saved.cycles.."\ncheckpoint_signature=2KiB CPU RAM, 16KiB PPU, MMC3 registers/map/mapped bytes/frame/cycles\n")
metadata:write("checkpoint_mmc3_select=$"..string.format("%02X",saved.select).."\ncheckpoint_prg_map="..table.concat(saved.map,",").."\n")
metadata:write("save_state_kind=anonymous in-memory; no numbered slot\n")
metadata:flush()

for pass=1,2 do
	assert(pcall(savestate.load,checkpoint),"savestate.load failed for pass "..pass)
	restore_map(saved); verify_signature(saved,"pass "..pass)
	pass_name=tostring(pass); frame_now=FIRST_FRAME-1; frame_cycle_start=-1
	active=false; reached_dad8=false; call_sequence=0; write_sequence=0
	local suffix=pass==1 and "" or "_repeat"
	calls=output("call_boundaries"..suffix..".csv",call_header)
	writes=output("ram_writes"..suffix..".csv",write_header)
	attach_pass()
	metadata:write("pass_"..pass.."_checkpoint_verified=true\n")
	for frame=FIRST_FRAME,MAX_FRAME do
		frame_now=frame; joypad.set(1,inputs[frame]); frame_cycle_start=debugger.getcyclescount(); emu.frameadvance()
		if frame%10==0 or reached_dad8 then
			calls:flush(); writes:flush(); progress(pass..":"..frame..(reached_dad8 and ":DAD8" or ""))
		end
		if reached_dad8 then break end
	end
	detach_pass(); calls:close(); writes:close()
	metadata:write("pass_"..pass.."_reached_dad8="..tostring(reached_dad8).."\npass_"..pass.."_call_events="..call_sequence.."\npass_"..pass.."_ram_writes="..write_sequence.."\n")
	metadata:flush()
end
metadata:write("complete=true\nreplay_passes=2 from the same verified anonymous frame-8399 checkpoint\n")
metadata:close()
os.exit()

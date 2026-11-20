-- Trace the source-owned RAM text buffer at the parameter-$47 actor packet.
-- The run is muted, uses an anonymous FCEUX checkpoint at source frame 8399,
-- and never uses the captured RAM as Godot runtime state.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OUT = assert(os.getenv("CT2_SLOT11_TEXT_TRACE_OUTPUT_DIR"), "missing output directory")
local OPENING = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local TITLE = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local ACTION_EDGES = ROOT .. "/reference/diagnostics/first_pass_action_input_edges_20261110.csv"
local CHECKPOINT_RAM = ROOT .. "/reference/diagnostics/local_checkpoints/first_command_packet_join_20261029/checkpoint_ram.bin"
local CHECKPOINT_PPU = ROOT .. "/reference/diagnostics/local_checkpoints/first_command_packet_join_20261029/checkpoint_ppu.bin"
local CHECKPOINT_FRAME = 8399
local LAST_FRAME = 9143
local PASSES = tonumber(os.getenv("CT2_SLOT11_TEXT_TRACE_PASSES") or "2")
os.execute("mkdir -p " .. string.format("%q", OUT))

local function read_inputs(path, route_format)
	local result, first = {}, true
	local file = assert(io.open(path, "r"), "missing input file " .. path)
	for line in file:lines() do
		line = line:gsub("\r$", "")
		if first then first = false else
			local fields = {}
			for value in (line .. ","):gmatch("(.-),") do fields[#fields + 1] = value end
			local frame = tonumber(fields[1])
			if frame then
				local i = route_format and 3 or 2
				result[frame] = {up=fields[i]=="1", down=fields[i+1]=="1",
					left=fields[i+2]=="1", right=fields[i+3]=="1",
					A=fields[i+4]=="1", B=fields[i+5]=="1",
					start=fields[i+6]=="1", select=fields[i+7]=="1"}
			end
		end
	end
	file:close()
	return result
end

local inputs = read_inputs(OPENING, false)
for frame, state in pairs(read_inputs(TITLE, true)) do inputs[frame] = state end
for frame = CHECKPOINT_FRAME + 1, LAST_FRAME do
	if not inputs[frame] then
		inputs[frame] = {up=false,down=false,left=false,right=false,A=false,B=false,start=false,select=false}
	end
end
local edge_file = assert(io.open(ACTION_EDGES, "r"), "missing first-pass input edges")
local first_edge = true
local button_map = {Up="up",Down="down",Left="left",Right="right",A="A",B="B",Start="start",Select="select"}
for line in edge_file:lines() do
	if first_edge then first_edge = false else
		local frame, button, pressed = line:match("^(%d+),([^,]+),(%d+)$")
		if frame then
			local state = inputs[tonumber(frame)]
			state[assert(button_map[button], "unknown input button " .. button)] = pressed == "1"
		end
	end
end
edge_file:close()
for frame = 0, CHECKPOINT_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local function b(address) return memory.readbyte(address) or 0 end
local function w(address) return b(address) + 256 * b(address + 1) end
local function hx(value, digits)
	if type(value)~="number" or value<0 then return "" end
	return string.format(digits == 2 and "%02X" or "%04X", value)
end
local function hex_range(first, count)
	local values = {}
	for i=0,count-1 do values[#values+1]=hx(b(first+i),2) end
	return table.concat(values)
end
local function register(name)
	local value=-1
	pcall(function() value=memory.getregister(name) end)
	return type(value)=="number" and value or -1
end
local function progress(label)
	local file=assert(io.open(OUT.."/progress.txt","w")); file:write(label.."\n"); file:close()
	print("slot11 trace: "..label)
end
local function csv(values)
	for i,value in ipairs(values) do values[i]=tostring(value or ""):gsub(",", ";") end
	return table.concat(values, ",")
end

local mmc3_select, mmc3 = 0, {0,2,4,5,6,7,0,1}
memory.registerwrite(0x8000,1,function(_,_,value) mmc3_select=value or 0 end)
memory.registerwrite(0x8001,1,function(_,_,value) mmc3[(mmc3_select%8)+1]=value or 0 end)
local function current_bank(pc)
	if pc >= 0xE000 then return 31 elseif pc >= 0xC000 then return 30 end
	local a,breg=mmc3[7]%32,mmc3[8]%32
	if math.floor(mmc3_select/64)%2==0 then
		if pc >= 0xA000 then return breg elseif pc >= 0x8000 then return a end
	else
		if pc >= 0xA000 then return breg elseif pc >= 0x8000 then return 30 end
	end
	return -1
end

local function save_raw(path, data)
	local file=assert(io.open(path,"wb")); file:write(data); file:close()
end
local function read_raw(path)
	local file=assert(io.open(path,"rb"),"missing checkpoint bytes "..path)
	local data=file:read("*a"); file:close(); return data
end
local function signature()
	local banks={}; for i=1,8 do banks[i]=mmc3[i] end
	return {frame=emu.framecount(),cycles=debugger.getcyclescount(),ram=memory.readbyterange(0,0x800),
		ppu=ppu.readbyterange(0,0x4000),select=mmc3_select,banks=banks,
		registers={pc=register("pc"),a=register("a"),x=register("x"),y=register("y"),
			p=register("p"),s=register("s")}}
end
local function first_difference(a, b)
	local limit=math.min(#a,#b)
	for i=1,limit do if a:byte(i)~=b:byte(i) then return i-1 end end
	return #a==#b and -1 or limit
end
local md5="unavailable"; pcall(function() md5=rom.gethash("md5") or md5 end)
assert(md5=="eaf2b3745263efa4b1afd2b400f68dae","wrong ROM payload MD5")
local metadata=assert(io.open(OUT.."/metadata.txt","w"))
metadata:write("rom_sha256=4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097\nrom_payload_md5="..md5.."\nemulator=FCEUX 2.7.0; NTSC/NewPPU; sound=0; volume=0\ncheckpoint=disk slot 0 frame 8399 loaded under unique ROM alias; RAM exact, PPU exact outside palette space; MMC3/PRG signatures checked; each pass count is controlled by CT2_SLOT11_TEXT_TRACE_PASSES\ninputs=opening_reference_capture/input_timeline.csv + kickoff_select_test_20261027/post_title_inputs.csv + first_pass_action_input_edges_20261110.csv\n")
metadata:close()

assert(emu.framecount()==CHECKPOINT_FRAME,"disk-loaded checkpoint is not frame 8399")
assert(debugger.getcyclescount()==250126423,"disk-loaded checkpoint cycle mismatch")
mmc3_select=0x07; mmc3={0x00,0x02,0xE8,0x69,0x6A,0x6B,0x00,0x02}
local checkpoint_ram=read_raw(CHECKPOINT_RAM)
local checkpoint_ppu=read_raw(CHECKPOINT_PPU)
local loaded_signature=signature()
assert(loaded_signature.ram==checkpoint_ram,"disk-loaded checkpoint RAM differs from the route oracle")
assert(#loaded_signature.ppu==0x4000 and #checkpoint_ppu==0x4000,"checkpoint PPU size mismatch")
assert(loaded_signature.ppu:sub(1,0x3F00)==checkpoint_ppu:sub(1,0x3F00),"disk-loaded checkpoint differs outside palette space")
assert(b(0x8000)==0xA5 and b(0xA000)==0xA9 and b(0xC000)==0xAA and b(0xE000)==0xFF,"disk-loaded checkpoint mapped PRG signature mismatch")
metadata=assert(io.open(OUT.."/metadata.txt","a")); metadata:write("checkpoint_cpu_registers=PC/"..hx(loaded_signature.registers.pc).." A/"..hx(loaded_signature.registers.a,2).." X/"..hx(loaded_signature.registers.x,2).." Y/"..hx(loaded_signature.registers.y,2).." P/"..hx(loaded_signature.registers.p,2).." S/"..hx(loaded_signature.registers.s,2).."\n"); metadata:close()
progress("disk-checkpoint-verified")
pcall(emu.speedmode,"turbo")
local checkpoint=assert(savestate.create(),"savestate.create failed")
local saved=signature(); assert(pcall(savestate.save,checkpoint),"savestate.save failed"); pcall(savestate.persist,checkpoint)
progress("anonymous-checkpoint-saved")

local watched={0x0000,0x0003,0x0011,0x0012,0x0013,0x0014,0x005F,0x0060,0x0063,0x0064,0x0404,0x0405}
for address=0x0516,0x0519 do watched[#watched+1]=address end
for _,address in ipairs({0x0528,0x0529,0x05CE,0x05EA}) do watched[#watched+1]=address end
for address=0x05E8,0x05F2 do watched[#watched+1]=address end
local pcs={
	[0x800F]="slot11_prefix_entry",[0x8030]="slot11_prefix_lookup",
	[0x80E0]="slot11_prefix_parameter_write",[0x80E2]="slot11_prefix_return",
	[0x82F7]="packet_resume_entry",[0x8047]="slot11_yield",
	[0xEB8B]="slot09_actor_seed_prefix",[0xED15]="slot09_actor_seed_caller",
	[0xED2A]="slot09_actor_seed_call",[0xED2D]="slot09_actor_seed_return",
	[0xCAE7]="task_seed_helper",[0xCA97]="scheduler_scan",
	[0xE081]="pass_waiter_field_caller",[0xE0AB]="pass_waiter_external_call",
	[0xE0DE]="pass_waiter_function_return",[0x80F0]="pass_waiter_return_target",
	[0xCBB0]="scenario_queue_write",[0xCBBE]="scenario_queue_yield_call",
	[0x8629]="text_helper_call",
	[0x8633]="text_tile_loop",[0x863B]="text_tile_return",
	[0xC524]="text_helper_vector",[0xC718]="indirect_text_dispatch",
	[0xC71A]="ram_text_buffer_initializer",[0xC71F]="ram_text_buffer_store",
	[0xC724]="ram_text_buffer_initializer_tail",[0xF30F]="text_pointer_lookup",
}
local expected={}
for pc in pairs(pcs) do
	if pc>=0xF000 then expected[pc]=31 elseif pc>=0xC000 then expected[pc]=30
	elseif pc>=0x8000 and pc<0xC000 then expected[pc]=nil end
end

for pass=1,PASSES do
	progress("pass-"..pass.."-loading-checkpoint")
	assert(pcall(savestate.load,checkpoint),"checkpoint load failed")
	mmc3_select=saved.select; for i=1,8 do mmc3[i]=saved.banks[i] end
	local restored=signature()
	local mismatch={}
	if restored.frame~=saved.frame then mismatch[#mismatch+1]="frame="..restored.frame.."/"..saved.frame end
	if restored.cycles~=saved.cycles then mismatch[#mismatch+1]="cycles="..restored.cycles.."/"..saved.cycles end
	for name,value in pairs(saved.registers) do
		if restored.registers[name]~=value then mismatch[#mismatch+1]=name.."="..restored.registers[name].."/"..value end
	end
	if restored.ram~=saved.ram then mismatch[#mismatch+1]="ram_diff="..first_difference(restored.ram,saved.ram) end
	if restored.ppu:sub(1,0x3F00)~=saved.ppu:sub(1,0x3F00) then mismatch[#mismatch+1]="ppu_diff="..first_difference(restored.ppu:sub(1,0x3F00),saved.ppu:sub(1,0x3F00)) end
	if restored.select~=saved.select then mismatch[#mismatch+1]="select="..restored.select.."/"..saved.select end
	assert(#mismatch==0,"checkpoint signature mismatch: "..table.concat(mismatch,";"))
	for i=1,8 do assert(restored.banks[i]==saved.banks[i],"checkpoint MMC3 mismatch") end
	progress("pass-"..pass.."-checkpoint-verified")
	local suffix=pass==1 and "" or "_repeat"
	local events=assert(io.open(OUT.."/events"..suffix..".csv","w"))
	local writes=assert(io.open(OUT.."/writes"..suffix..".csv","w"))
	events:write("pass,source_frame,emu_frame,cycle_from_frame_start,cycle_absolute,kind,pc,bank,a,x,y,p,sp,return_address,ptr_0404,buffer_05E8_05F5,actor_record_0011_0014,task_record_0000_0003,stack_C0_D0,stream_pointer_005F_0060,scenario_0516_0519,mapper_18_19\n")
	writes:write("pass,source_frame,emu_frame,cycle_from_frame_start,cycle_absolute,pc,bank,address,value,a,x,y,p,sp,ptr_0404,buffer_05E8_05F5,mapper_18_19\n")
	local seq=0
	local function log_event(kind, pc)
		local bank=current_bank(pc)
		if expected[pc]~=nil and bank~=expected[pc] then return end
		local regs={"a","x","y","p","s"}; local r={}; for _,name in ipairs(regs) do r[#r+1]=hx(register(name),2) end
		local sp=register("s")
		local return_word=b(0x0100+((sp+1)%0x100))+256*b(0x0100+((sp+2)%0x100))
		local values={pass,frame_now or -1,emu.framecount(),debugger.getcyclescount()-frame_cycle_start,debugger.getcyclescount(),kind,hx(pc),hx(bank,2)}
		for _,v in ipairs(r) do values[#values+1]=v end
		values[#values+1]=hx(return_word)
		values[#values+1]=hx(w(0x0404)); values[#values+1]=hex_range(0x05E8,14)
		values[#values+1]=hex_range(0x0011,4); values[#values+1]=hex_range(0x0000,4)
		values[#values+1]=hex_range(0x01C0,16); values[#values+1]=hx(w(0x005F))
		values[#values+1]=hex_range(0x0516,4); values[#values+1]=hx(mmc3[7],2).."/"..hx(mmc3[8],2)
		events:write(csv(values).."\n"); seq=seq+1
	end
	for address in pairs(pcs) do
		local target=address; memory.registerexec(target,function() log_event(pcs[target],target) end)
	end
	for _,address in ipairs(watched) do
		local target=address
		memory.registerwrite(target,1,function(_,_,value)
			local pc=register("pc"); local values={pass,frame_now or -1,emu.framecount(),debugger.getcyclescount()-frame_cycle_start,debugger.getcyclescount(),hx(pc),hx(current_bank(pc),2),hx(target),hx(value or b(target),2),hx(register("a"),2),hx(register("x"),2),hx(register("y"),2),hx(register("p"),2),hx(register("s"),2),hx(w(0x0404)),hex_range(0x05E8,14),hx(mmc3[7],2).."/"..hx(mmc3[8],2)}
			writes:write(csv(values).."\n")
		end)
	end
	for frame=CHECKPOINT_FRAME+1,LAST_FRAME do
		frame_now=frame; frame_cycle_start=debugger.getcyclescount(); joypad.set(1,inputs[frame]); emu.frameadvance()
		if frame%8==0 or frame==LAST_FRAME then events:flush(); writes:flush(); progress("pass-"..pass.."-frame-"..frame) end
	end
	for pc in pairs(pcs) do pcall(memory.registerexec,pc,nil) end
	for _,address in ipairs(watched) do pcall(memory.registerwrite,address,1,nil) end
	events:close(); writes:close()
	save_raw(OUT.."/ram_frame_"..LAST_FRAME..suffix..".bin",memory.readbyterange(0,0x800))
	local result=signature()
	metadata=assert(io.open(OUT.."/metadata.txt","a")); metadata:write("pass_"..pass.."_events="..seq.."\npass_"..pass.."_frame="..result.frame.."\npass_"..pass.."_buffer_05EB_05F2="..hex_range(0x05EB,8).."\npass_"..pass.."_indirect_target_0404="..hx(w(0x0404)).."\n"); metadata:close()
	progress("pass-"..pass.."-complete")
end

pcall(memory.registerwrite,0x8000,1,nil); pcall(memory.registerwrite,0x8001,1,nil)
os.exit()

-- Muted two-pass source trace from the title screen immediately before the
-- recorded fresh KICK OFF input. The anonymous checkpoint is persisted and
-- signature-checked; no numbered slot or RAM injection is used.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_FRESH_ENTRY_TRACE_OUTPUT_DIR"), "missing output directory")
local CHECKPOINT_FRAME, FIRST_REPLAY_FRAME, LAST_FRAME = 4692, 4693, 8953
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
				local index = route_format and 3 or 2
				result[frame] = {up=values[index]=="1", down=values[index+1]=="1",
					left=values[index+2]=="1", right=values[index+3]=="1",
					A=values[index+4]=="1", B=values[index+5]=="1",
					start=values[index+6]=="1", select=values[index+7]=="1"}
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
	local file = assert(io.open(OUT .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end
local function b(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return type(value) == "number" and value or 0
end
local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return type(value) == "number" and value or -1
end
local function hx(value, word)
	if type(value) ~= "number" or value < 0 then return "" end
	return string.format(word and "$%04X" or "$%02X", value)
end
local function csv(fields)
	local values = {}
	for index, value in ipairs(fields) do
		values[index] = tostring(value == nil and "" or value):gsub(",", ";")
	end
	return table.concat(values, ",")
end
local function progress(value)
	local file = assert(io.open(OUT .. "/progress.txt", "w"))
	file:write(value .. "\n"); file:close()
end
local function stack_window(sp)
	local bytes = {}
	for offset = -8, 15 do
		bytes[#bytes + 1] = string.format("%02X", b(0x0100 + ((sp + offset) % 0x100)))
	end
	return string.format("SP%02X:%s", sp, table.concat(bytes, ""))
end
local task_bases = {0x01,0x05,0x09,0x11,0x15,0x19,0x1D,0x21,0x25,0x29}
local function task_records()
	local values = {}
	for _, base in ipairs(task_bases) do
		values[#values + 1] = string.format("%02X:%02X%02X%02X%02X", base,
			b(base), b(base + 1), b(base + 2), b(base + 3))
	end
	return table.concat(values, "|")
end
local function stack_for_slot05()
	local sp = b(0x0006)
	return string.format("slot05_saved_sp=%02X:%s", sp, stack_window(sp))
end

local mmc3_select, mmc3 = 0, {0,2,4,5,6,7,0,1}
local function prg_map()
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(mmc3_select / 64) % 2 == 0 then return r6, r7, 30, 31 end
	return 30, r7, r6, 31
end
local function bank(pc)
	if pc >= 0xE000 then return 31 elseif pc >= 0xC000 then return 30 end
	local _, r1 = prg_map()
	if pc >= 0xA000 then return r1 elseif pc >= 0x8000 then return prg_map() end
	return -1
end

local metadata = output("metadata.txt")
metadata:write("source_frames=0-" .. LAST_FRAME .. "\n")
metadata:write("checkpoint_frame=" .. CHECKPOINT_FRAME .. "\nreplay_start_frame=" .. FIRST_REPLAY_FRAME .. "\n")
metadata:write("emulator=FCEUX 2.7.0; NTSC; NewPPU; audio muted\n")
metadata:write("checkpoint=anonymous in-memory state immediately before the source-frame-4693 KICK OFF input; savestate.persist called before replay loads\n")
metadata:write("slots=no numbered slots; ram_injection=none; capture_ram_used_as_input=false\n")
metadata:write("hooks=bank-$00 $80E6; bank-$02 $A20F/$A86E/$A8AF; fixed $C557/$C6BE/$C6E8/$CA97/$CAD4/$D11E; reads/writes $0026/$0027/$002B; task records and stack snapshots\n")
metadata:flush()

local event_header = "sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,kind,pc,bank,a,x,y,p,sp,ram_0026,ram_0027,ram_002b,current_task_base,task_records,slot05_saved_sp_stack,stack_at_cpu_sp,mapper_shadow_0024_0025,mapper_select,prg_map"
local access_header = "sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,kind,pc,bank,address,value,a,x,y,p,sp,ram_0026,ram_0027,ram_002b,current_task_base,task_records,slot05_saved_sp_stack,stack_at_cpu_sp"
local frame_now, frame_cycle_start, pass_name = -1, -1, ""
local events, accesses
local event_sequence, access_sequence, checkpoint_error = 0, 0, false
local callback_active, read_hook_active = false, false
local reached_slot05 = false

local function log_event(kind)
	local pc, sp = reg("pc"), reg("s")
	local cycles, emulator_frame = -1, -1
	pcall(function() cycles = debugger.getcyclescount() end)
	pcall(function() emulator_frame = emu.framecount() end)
	local r0, r1, r2, r3 = prg_map()
	events:write(csv({event_sequence,pass_name,frame_now,emulator_frame,cycles-frame_cycle_start,cycles,
		kind,hx(pc,true),bank(pc),hx(reg("a")),hx(reg("x")),hx(reg("y")),hx(reg("p")),hx(sp),
		hx(b(0x0026)),hx(b(0x0027)),hx(b(0x002B)),hx(b(0x0000)),task_records(),stack_for_slot05(),
		stack_window(sp),hx(b(0x0024)).." "..hx(b(0x0025)),hx(mmc3_select),
		string.format("%02X/%02X/%02X/%02X",r0,r1,r2,r3)}).."\n")
	event_sequence = event_sequence + 1
end

local function log_access(kind, address, value)
	local pc, sp = reg("pc"), reg("s")
	local cycles, emulator_frame = -1, -1
	pcall(function() cycles = debugger.getcyclescount() end)
	pcall(function() emulator_frame = emu.framecount() end)
	accesses:write(csv({access_sequence,pass_name,frame_now,emulator_frame,cycles-frame_cycle_start,cycles,
		kind,hx(pc,true),bank(pc),hx(address,true),hx(value),hx(reg("a")),hx(reg("x")),hx(reg("y")),
		hx(reg("p")),hx(sp),hx(b(0x0026)),hx(b(0x0027)),hx(b(0x002B)),hx(b(0x0000)),
		task_records(),stack_for_slot05(),stack_window(sp)}).."\n")
	access_sequence = access_sequence + 1
end

local last_written = {}
local function attach(pass)
	pass_name, event_sequence, access_sequence = tostring(pass), 0, 0
	events = output("events" .. (pass == 1 and "" or "_repeat") .. ".csv", event_header)
	accesses = output("accesses" .. (pass == 1 and "" or "_repeat") .. ".csv", access_header)
	for _, address in ipairs({0x0026,0x0027,0x002B,0x0000,0x0001,0x0005,0x0006,0x0009,0x000A,0x0015,0x0016,0x0017,0x0018}) do
		last_written[address] = b(address)
		local aa = address
		memory.registerwrite(aa, 1, function(_, _, new_value)
			if callback_active then return end
			callback_active = true
			log_access("write",aa,new_value)
			last_written[aa] = new_value
			callback_active = false
		end)
	end
	if type(memory.registerread) == "function" then
		for _, address in ipairs({0x0026,0x0027,0x002B}) do
			local aa = address
			memory.registerread(aa, 1, function(_, _, value)
				if read_hook_active or callback_active then return end
				read_hook_active = true
				log_access("read",aa,value)
				read_hook_active = false
			end)
		end
	end
	local hooks = {
		[0x80E6]="kickoff_title_branch_80E6", [0xA20F]="match_selector_vector_A20F",
		[0xA86E]="match_selector_A86E_entry", [0xA8AF]="opponent_formula_A8AF",
		[0xC557]="scheduler_handoff_C557", [0xC6BE]="task_setup_C6BE",
		[0xC6E8]="task_bootstrap_C6E8", [0xCA97]="scheduler_scan_CA97",
		[0xCAD4]="scheduler_dispatch_CAD4", [0xD11E]="slot05_entry_D11E",
	}
	for address, kind in pairs(hooks) do
		local aa, label = address, kind
		memory.registerexec(aa, function()
			if callback_active then return end
			local current_bank = bank(reg("pc"))
			local expected = (aa == 0xA20F or aa == 0xA86E or aa == 0xA8AF) and 2
				or ((aa >= 0xC000) and 30) or 0
			if current_bank ~= expected then return end
			callback_active = true
			log_event(label)
			if aa == 0xD11E then reached_slot05 = true end
			callback_active = false
		end)
	end
end

local function detach()
	for _, address in ipairs({0x0026,0x0027,0x002B,0x0000,0x0001,0x0005,0x0006,0x0009,0x000A,0x0015,0x0016,0x0017,0x0018}) do
		pcall(memory.registerwrite,address,1,nil)
	end
	if type(memory.registerread) == "function" then
		for _, address in ipairs({0x0026,0x0027,0x002B}) do pcall(memory.registerread,address,1,nil) end
	end
	for address in pairs({[0x80E6]=true,[0xA20F]=true,[0xA86E]=true,[0xA8AF]=true,
		[0xC557]=true,[0xC6BE]=true,[0xC6E8]=true,[0xCA97]=true,[0xCAD4]=true,[0xD11E]=true}) do
		pcall(memory.registerexec,address,nil)
	end
end

local function signature()
	local ram = memory.readbyterange(0, 0x800)
	local ppu_memory = ppu.readbyterange(0, 0x4000)
	local r0,r1 = prg_map()
	local banks = {}; for index=1,8 do banks[index]=mmc3[index] end
	return {frame=emu.framecount(),cycles=debugger.getcyclescount(),ram=ram,ppu=ppu_memory,
		select=mmc3_select,banks=banks,prg={r0,r1,30,31},
		mapped={b(0x8000),b(0xA000),b(0xC000),b(0xE000)}}
end
local function verify(saved,label)
	local current=signature()
	assert(current.frame==saved.frame and current.cycles==saved.cycles,label.." frame/cycle mismatch")
	assert(current.ram==saved.ram and current.ppu==saved.ppu,label.." RAM/PPU mismatch")
	assert(current.select==saved.select,label.." MMC3 selector mismatch")
	for i=1,8 do assert(current.banks[i]==saved.banks[i],label.." MMC3 bank mismatch") end
	for i=1,4 do assert(current.prg[i]==saved.prg[i] and current.mapped[i]==saved.mapped[i],label.." PRG mapping mismatch") end
end

local startup_mode = "nil"
pcall(function() startup_mode=tostring(movie.mode()); if movie.mode()~=nil then pcall(movie.stop) end end)
if type(movie.active)=="function" then local active=false; pcall(function() active=movie.active() end); if active then pcall(movie.stop) end end
assert(tostring(movie.mode())=="nil","could not stop startup movie")
memory.registerwrite(0x8000,1,function(_,_,value) mmc3_select=value or 0 end)
memory.registerwrite(0x8001,1,function(_,_,value) mmc3[(mmc3_select%8)+1]=value or 0 end)
assert(pcall(emu.poweron),"emu.poweron failed")
if debugger.resetcyclescount then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode,"turbo")

progress("warmup_before:"..CHECKPOINT_FRAME)
for frame=0,CHECKPOINT_FRAME do
	joypad.set(1,inputs[frame]); emu.frameadvance()
	if frame%100==0 or frame==CHECKPOINT_FRAME then progress("warmup:"..frame) end
end
local checkpoint = assert(savestate.create(),"savestate.create failed")
local checkpoint_signature = signature()
assert(checkpoint_signature.frame==CHECKPOINT_FRAME,"checkpoint source frame mismatch")
assert(pcall(savestate.save,checkpoint),"savestate.save failed")
assert(pcall(savestate.persist,checkpoint),"savestate.persist failed")
metadata:write("checkpoint_cycles="..checkpoint_signature.cycles.."\n")
metadata:write("checkpoint_signature=frame/cycle, RAM2KiB, PPU16KiB, MMC3 registers and mapped PRG bytes\n")
metadata:write("savestate_persist=success\n")
metadata:flush()

for pass=1,2 do
	progress("restore:"..pass)
	assert(pcall(savestate.load,checkpoint),"savestate.load failed")
	mmc3_select=checkpoint_signature.select
	for i=1,8 do mmc3[i]=checkpoint_signature.banks[i] end
	verify(checkpoint_signature,"pass "..pass)
	reached_slot05=false
	attach(pass)
	for frame=FIRST_REPLAY_FRAME,LAST_FRAME do
		frame_now=frame; joypad.set(1,inputs[frame]); frame_cycle_start=debugger.getcyclescount()
		emu.frameadvance()
		if frame%50==0 then
			events:flush(); accesses:flush(); progress("pass"..pass..":"..frame)
		end
		if reached_slot05 then
			progress("pass"..pass..":slot05_D11E:"..frame)
			break
		end
	end
	assert(reached_slot05,"replay did not reach slot-$05 $D11E")
	detach(); events:flush(); accesses:flush(); events:close(); accesses:close()
	metadata:write("pass_"..pass.."_slot05_reached=true\n")
	metadata:flush()
end

metadata:write("complete=true\nreplays=2 from same signature-checked anonymous frame-4692 checkpoint\n")
metadata:close()
pcall(memory.registerwrite,0x8000,1,nil); pcall(memory.registerwrite,0x8001,1,nil)
os.exit()

-- Muted, two-pass trace for the slot-$11 actor stream dispatch and the
-- subsequent slot-$15 map-worker cursor/queue state.
-- Rebuild the verified frame-8399 prefix once, then replay from one
-- signature-checked anonymous checkpoint. No numbered user state is used.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_SLOT11_TRACE_OUTPUT_DIR"), "missing output directory")
local CHECKPOINT_FRAME = 8399
local LAST_FRAME = tonumber(os.getenv("CT2_SLOT11_TRACE_LAST_FRAME")) or 8953
assert(CHECKPOINT_FRAME < LAST_FRAME, "last frame must follow the checkpoint")
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

local inputs = read_inputs(OPENING_INPUT, false)
for frame, state in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = state end
for frame = 0, LAST_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local function out(name, header)
	local file = assert(io.open(OUT .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end
local function b(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return type(value) == "number" and value or 0
end
local function w(address) return b(address) + 256 * b(address + 1) end
local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return type(value) == "number" and value or -1
end
local function hx(value, digits)
	if type(value) ~= "number" or value < 0 then return "" end
	return string.format(digits == 2 and "%02X" or "%04X", value)
end
local function hex_range(first, count)
	local values = {}
	for i = 0, count - 1 do values[#values + 1] = string.format("%02X", b(first + i)) end
	return table.concat(values, "")
end
local function csv(values)
	for i, value in ipairs(values) do values[i] = tostring(value or ""):gsub(",", ";") end
	return table.concat(values, ",")
end
local function progress(value)
	local file = assert(io.open(OUT .. "/progress.txt", "w")); file:write(value .. "\n"); file:close()
end

local mmc3_select, mmc3 = 0, {0,2,4,5,6,7,0,1}
local function prg_map()
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(mmc3_select / 64) % 2 == 0 then return r6, r7, 30, 31 end
	return 30, r7, r6, 31
end
local function bank(pc)
	if pc >= 0xE000 then return 31 elseif pc >= 0xC000 then return 30 end
	local r0, r1 = prg_map()
	return pc >= 0xA000 and r1 or pc >= 0x8000 and r0 or -1
end
local mmc3_writes = {}
memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value) mmc3[(mmc3_select % 8) + 1] = value or 0 end)

local pcs = {
	[0x8047]="actor_yield_8047", [0x804A]="actor_resume_804A", [0x804D]="actor_wrapper_804D",
	[0x8065]="stream_dispatch_8065", [0x8218]="event_dispatch_8218", [0x821F]="event_compare_821F",
	[0x8221]="event_low_type_8221", [0x822E]="event_high_type_822E",
	[0x8234]="event_payload_read_8234", [0x8237]="event_nibble_shift_8237",
	[0x823A]="event_type_to_x_823A", [0x823B]="event_lookup_823B",
	[0x823E]="event_value_store_823E", [0x8241]="event_pointer_index_8241",
	[0x8244]="event_pointer_to_x_8244", [0x8245]="event_pointer_low_8245",
	[0x8248]="event_pointer_store_low_8248", [0x824A]="event_pointer_high_824A",
	[0x824D]="event_pointer_store_high_824D", [0x824F]="event_payload_y0_824F",
	[0x8251]="event_payload_first_8251", [0x8254]="event_payload_y1_8254",
	[0x8255]="event_payload_second_8255", [0x8258]="event_payload_y2_8258",
	[0x8259]="event_payload_third_8259", [0x825B]="event_payload_store_825B",
	[0x825E]="event_payload_y3_825E", [0x825F]="event_delay_load_825F",
	[0x8261]="event_delay_store_8261", [0x8264]="event_queue_value_8264",
	[0x8266]="event_queue_call_8266", [0x8269]="event_queue_poll_8269",
	[0x826C]="event_queue_wait_826C", [0x8270]="event_queue_ready_store_8270",
	[0xC515]="event_queue_helper_C515", [0xC52D]="event_helper_C52D",
	[0x856F]="map_worker_yield_callsite_856F", [0x8572]="map_worker_resume_entry_8572",
	[0x85C2]="map_metatile_expand_85C2",
	[0x81D1]="short_event_81D1", [0x81E3]="short_event_return_81E3",
	[0x8087]="stream_command_8087",
	[0xF610]="possible_stream_consumer_F610", [0xA217]="animation_gate_yield_A217",
	[0xA21A]="animation_packet_A21A", [0xCB0F]="task_yield_CB0F",
}
local expected_banks = {
	[0x8047]=24,[0x804A]=24,[0x804D]=24,[0x8065]=24,[0x8218]=24,[0x821F]=24,
	[0x8221]=24,[0x822E]=24,[0x8234]=24,[0x8237]=24,[0x823A]=24,[0x823B]=24,[0x823E]=24,
	[0x8241]=24,[0x8244]=24,[0x8245]=24,[0x8248]=24,[0x824A]=24,[0x824D]=24,
	[0x824F]=24,[0x8251]=24,[0x8254]=24,[0x8255]=24,[0x8258]=24,[0x8259]=24,
	[0x825B]=24,[0x825E]=24,[0x825F]=24,[0x8261]=24,[0x8264]=24,[0x8266]=24,
	[0x8269]=24,[0x826C]=24,[0x8270]=24,[0xC515]=30,[0xC52D]=30,
	[0x856F]=0x0B,[0x8572]=0x0B,[0x85C2]=0x0B,
	[0x81D1]=24,[0x81E3]=24,[0x8087]=24,[0xC509]=30,[0xCB99]=30,[0xF610]=31,
	[0xA217]=27,[0xA21A]=27,[0xCB0F]=30,
}
local header = "sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,kind,pc,bank,a,x,y,p,sp,record11,stack_C0_D0,stream_index_05e4_05e5,delay_05e9,animation_05f3_05f5,event_state_05e6_05e8,stream_pointer_005f_0060,event_byte_at_pointer_plus_index,queue_0515,mapper,stream_ram_0050_006f,caller_pc,return_word,map_cursor_05c7_05cd,map_queue_04a5_01a4"
local seq, frame_now, frame_cycle_start, pass_name = 0, -1, -1, ""
local events, writes, seq_write
local watched_writes = {0x005F,0x0060,0x05E4,0x05E5,0x05E6,0x05E7,0x05E8,0x05E9}
local write_header = "sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc,bank,address,value,a,x,y,p,sp,stream_pointer_005f_0060,stream_index_05e4_05e5,delay_05e9,stack_C0_D0,record11,mapper"
local function log_event(kind)
	local pc, cycles, emu_frame = reg("pc"), debugger.getcyclescount(), emu.framecount()
	local stack_pointer = reg("s")
	local return_word = b(0x0100 + ((stack_pointer + 1) % 0x100)) + 256 * b(0x0100 + ((stack_pointer + 2) % 0x100))
	local caller_pc = (return_word - 2) % 0x10000
	local base = b(0x005F) + 256 * b(0x0060)
	local ix = b(0x05E5)
	local r0,r1,r2,r3 = prg_map()
	local map_cursor, map_queue = "", ""
	if pc == 0x856F or pc == 0x8572 or pc == 0x85C2 or (pc == 0xC515 and caller_pc == 0x856F) then
		map_cursor = hex_range(0x05C7, 7)
		if pc == 0xC515 and caller_pc == 0x856F then map_queue = hex_range(0x04A5, 0x100) end
	end
	local fields = {seq,pass_name,frame_now,emu_frame,cycles-frame_cycle_start,cycles,kind,hx(pc),bank(pc),
		hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(reg("s"),2),
		hex_range(0x0011,4),hex_range(0x01C0,16),hex_range(0x05E4,2),hx(b(0x05E9),2),
		hex_range(0x05F3,3),hex_range(0x05E6,3),hx(b(0x005F),2).." "..hx(b(0x0060),2),
		string.format("%02X",b(base+ix)),hx(b(0x0515),2),string.format("%02X/%02X/%02X/%02X",r0,r1,r2,r3),hex_range(0x0050,32),
		hx(caller_pc),hx(return_word),map_cursor,map_queue}
	events:write(csv(fields) .. "\n"); seq=seq+1
end
local function log_write(address, value)
	local pc, cycles, emu_frame = reg("pc"), debugger.getcyclescount(), emu.framecount()
	local r0,r1,r2,r3 = prg_map()
	local fields = {seq_write,pass_name,frame_now,emu_frame,cycles-frame_cycle_start,cycles,
		hx(pc),bank(pc),hx(address),hx(value,2),hx(reg("a"),2),hx(reg("x"),2),
		hx(reg("y"),2),hx(reg("p"),2),hx(reg("s"),2),
		hx(b(0x005F),2).." "..hx(b(0x0060),2),hex_range(0x05E4,2),hx(b(0x05E9),2),
		hex_range(0x01C0,16),hex_range(0x0011,4),
		string.format("%02X/%02X/%02X/%02X",r0,r1,r2,r3)}
	writes:write(csv(fields).."\n"); seq_write=seq_write+1
end
local function attach()
	for _, address in ipairs(watched_writes) do
		local target = address
		memory.registerwrite(target,1,function(_,_,value) log_write(target,value or b(target)) end)
	end
	for address, name in pairs(pcs) do
		local aa, nn, expected = address, name, expected_banks[address]
		memory.registerexec(aa, function() if bank(reg("pc")) == expected then log_event(nn) end end)
	end
end
local function detach()
	for address in pairs(pcs) do pcall(memory.registerexec,address,nil) end
	for _, address in ipairs(watched_writes) do pcall(memory.registerwrite,address,1,nil) end
end
local function signature()
	local registers = {}
	for _, name in ipairs({"pc","a","x","y","p","s"}) do registers[name]=reg(name) end
	local bank_values={}; for i=1,8 do bank_values[i]=mmc3[i] end
	local r0,r1=prg_map()
	return {frame=emu.framecount(),cycles=debugger.getcyclescount(),ram=memory.readbyterange(0,0x800),
		ppu=ppu.readbyterange(0,0x4000),select=mmc3_select,banks=bank_values,prg={r0,r1,30,31},registers=registers}
end
local function verify(saved,label)
	local current=signature()
	assert(current.frame==saved.frame and current.cycles==saved.cycles,label.." frame/cycle mismatch")
	assert(current.ram==saved.ram and current.ppu==saved.ppu,label.." RAM/PPU mismatch")
	assert(current.select==saved.select,label.." MMC3 selector mismatch")
	for i=1,8 do assert(current.banks[i]==saved.banks[i],label.." MMC3 bank mismatch") end
	for i=1,2 do assert(current.prg[i]==saved.prg[i],label.." PRG map mismatch") end
end

local md5 = "unavailable"; pcall(function() md5=rom.gethash("md5") or md5 end)
assert(md5=="eaf2b3745263efa4b1afd2b400f68dae","wrong ROM payload MD5: "..tostring(md5))
local metadata=out("metadata.txt")
metadata:write("rom_sha256=4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097\nrom_payload_md5="..md5.."\nemulator=FCEUX 2.7.0; NTSC/NewPPU; sound=0; volume=0\ncheckpoint=anonymous in-memory frame 8399; verified RAM/PPU/MMC3 signature after both restores\ninput_prefix=opening_reference_capture/input_timeline.csv + kickoff_select_test_20261027/post_title_inputs.csv\nhooks=8218,821F,8221,822E,8234,8237,823A,823B,823E,8241,8244,8245,8248,824A,824D,824F,8251,8254,8255,8258,8259,825B,825E,825F,8261,8264,8266,8269,826C,8270,856F,8572,85C2,C515,C52D,CB0F\nwatches=005F-0060,05E4-05E9; map-worker snapshots=$05C7-$05CD and queue $04A5-$05A4 at $C515->$856F\n")
metadata:close()
assert(pcall(emu.poweron),"emu.poweron failed")
if debugger.resetcyclescount then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode,"turbo")
for frame=0,CHECKPOINT_FRAME do
	joypad.set(1,inputs[frame]); emu.frameadvance()
	if frame%500==0 then progress("warmup:"..frame) end
end
local checkpoint=savestate.create(); assert(checkpoint,"savestate.create failed")
local saved=signature(); assert(pcall(savestate.save,checkpoint),"savestate.save failed"); pcall(savestate.persist,checkpoint)
for pass=1,2 do
	assert(pcall(savestate.load,checkpoint),"savestate.load failed"); mmc3_select=saved.select
	for i=1,8 do mmc3[i]=saved.banks[i] end; verify(saved,"pass "..pass)
	pass_name=tostring(pass); seq=0; seq_write=0
	events=out("events"..(pass==1 and "" or "_repeat")..".csv",header)
	writes=out("writes"..(pass==1 and "" or "_repeat")..".csv",write_header)
	attach()
	for frame=CHECKPOINT_FRAME+1,LAST_FRAME do
		frame_now=frame; joypad.set(1,inputs[frame]); frame_cycle_start=debugger.getcyclescount(); emu.frameadvance()
		if frame%50==0 or frame==LAST_FRAME then events:flush(); writes:flush(); progress(pass..":"..frame) end
	end
	detach(); events:close(); writes:close(); metadata=io.open(OUT.."/metadata.txt","a")
	metadata:write("pass_"..pass.."_events="..seq.."\npass_"..pass.."_writes="..seq_write.."\n"); metadata:close()
end
progress("complete")
metadata=io.open(OUT.."/metadata.txt","a"); metadata:write("complete=true\n"); metadata:close()
pcall(memory.registerwrite,0x8000,1,nil); pcall(memory.registerwrite,0x8001,1,nil)
os.exit()

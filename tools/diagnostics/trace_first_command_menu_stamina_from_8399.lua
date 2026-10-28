-- Combined muted scheduler/scenario/actor trace for the fresh KICK OFF route.
-- The script warms once to frame 8399, saves an anonymous in-memory state,
-- then validates and replays frames 8400-8953 twice. Output is diagnostic only.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_MENU_STAMINA_TRACE_OUTPUT_DIR"), "missing output directory")
local CHECKPOINT_FRAME, FIRST_FRAME, LAST_FRAME = 8399, 8400, 8953
local ACTOR_FIRST, ACTOR_LAST, ACTOR_STRIDE = 0x0547, 0x05C4, 0x15
os.execute("mkdir -p " .. string.format("%q", OUT))
local function progress(value)
	local file = assert(io.open(OUT .. "/progress.txt", "w"))
	file:write(value .. "\n")
	file:close()
end
progress("lua_started")

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
	local file = assert(io.open(OUT .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end
local function b(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return type(value) == "number" and value or 0
end
local function w(address) return b(address) + b(address + 1) * 256 end
local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return type(value) == "number" and value or -1
end
local function hx(value, width)
	if type(value) ~= "number" or value < 0 then return "" end
	return string.format(width == 2 and "$%02X" or "$%04X", value)
end
local function csv(values)
	local fields = {}
	for i, value in ipairs(values) do fields[i] = tostring(value == nil and "" or value):gsub(",", ";") end
	return table.concat(fields, ",")
end
local function bytes_hex(first, count)
	local values = {}
	for offset = 0, count - 1 do values[#values + 1] = string.format("%02X", b(first + offset)) end
	return table.concat(values, " ")
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
	if pc >= 0xA000 then return r1 elseif pc >= 0x8000 then return r0 end
	return -1
end
local function task_slots()
	local parts = {}
	for base = 0x15, 0x29, 4 do
		parts[#parts + 1] = string.format("%02X:%02X%02X%02X%02X", base,
			b(base), b(base + 1), b(base + 2), b(base + 3))
	end
	return table.concat(parts, "|")
end
local function actor_record_for(address)
	if address < ACTOR_FIRST or address > ACTOR_LAST then return -1, -1 end
	local index = math.floor((address - ACTOR_FIRST) / ACTOR_STRIDE)
	return index, ACTOR_FIRST + index * ACTOR_STRIDE
end
local function actor_for_pointer(pointer)
	local index, base = actor_record_for(pointer)
	if index < 0 or pointer ~= base then return -1, -1 end
	return index, base
end
local function current_actor_state()
	local pointer = w(0x003C)
	local index, base = actor_for_pointer(pointer)
	if index < 0 then return hx(pointer, 4), "", "" end
	return hx(pointer, 4), bytes_hex(base, 21),
		hx(w(base + 3), 4) .. "/" .. hx(w(base + 1), 4) .. "/" ..
		hx(b(base + 0x10), 2) .. "/" .. hx(b(base + 0x11), 2) .. "/" .. hx(b(base + 0x12), 2)
end
local function continuation_payload()
	return bytes_hex(0x051A, 8)
end
local function worker_state()
	return bytes_hex(0x053A, 4)
end
local function context_state()
	return "scenario=" .. hx(b(0x0518), 2) .. ";wait=" .. hx(b(0x0519), 2) ..
		";event=" .. hx(b(0x0524), 2) .. ";anim=" .. hx(b(0x0528), 2) ..
		";param=" .. hx(b(0x0529), 2) .. ";cursor=" .. hx(b(0x003A), 2) ..
		";ptr=" .. hx(w(0x005D), 4) .. ";depth=" .. hx(b(0x0522), 2) ..
		";ret=" .. continuation_payload() .. ";menu_state=" .. hx(b(0x0515), 2) .. "/" ..
		hx(b(0x05C5), 2) .. "/" .. hx(b(0x05C6), 2) .. ";stamina=" ..
		hx(b(0x0614), 2) .. "/" .. hx(b(0x0618), 2)
end
local function queue_bytes() return bytes_hex(0x04A5, 0x70) end
local function queue_context_kind(kind)
	return kind == "menu_wait_D575" or kind == "menu_queue_D5C3" or
		kind == "bank18_worker_8852" or kind == "bank18_worker_88B9" or
		kind == "field_loop_E145" or kind == "eligible_field_loop_E14D" or
		kind == "stamina_helper_E1F7" or kind == "stamina_helper_E2BC"
end

local metadata = output("metadata.txt")
local rom_hash = "unavailable"; pcall(function() rom_hash = rom.gethash("sha256") or rom_hash end)
metadata:write("source_rom_sha256=" .. tostring(rom_hash) .. "\nsource_frames=0-" .. LAST_FRAME .. "\ninstrumented_frames=" .. FIRST_FRAME .. "-" .. LAST_FRAME .. "\n")
metadata:write("emulator=FCEUX 2.7.0; NTSC; NewPPU; audio muted\n")
metadata:write("hooks=task/callback $CBB0/$C50F/$CAE7/$CA97/$CB0F/$CAF7/$814C/$81A7/$81BC/$8327; scenario $8837/$883F/$80CF/$80EB; worker $EC94/$ECF8/$ED0C/$ED5B/$ED5F/$C7EE/$18:$8852/$18:$88B9; actor $EE9F/$800F/$80AA/$83D9/$84DC; menu $D575/$D5C3; field/stamina $E145/$E14D/$E1F7/$E2BC\n")
metadata:write("writes=task $0015-$002C; scenario pointers/state; menu $0515/$05C5/$05C6; stamina $0614/$0618; queue $04A5-$0514; actor records $0547-$05C4; context/background RAM\n")
metadata:write("queue_snapshot=112 bytes at selected menu, bank-18, and field/stamina PC hooks; queue writes logged byte-by-byte with PC/bank/frame/cycle/register/task context\n")
metadata:write("checkpoint=anonymous in-memory state at source frame 8399, saved and restored in this Lua process; no numbered slot\naudio=muted; trace files are diagnostics only\n")
metadata:flush()

local event_header = "sequence,pass,source_frame,emulator_frame,cycle_frame,cycle_absolute,kind,pc,prg_bank,a,x,y,p,sp,task_slots_0015_002c,scenario_cursor_003a,scenario_pointer_005d_005e,continuation_depth_0522,continuation_words_051a_0521,context_0518_053d,callback_pointer_0052_0053,worker_053a_053d,actor_pointer_003c,actor_bytes_21,actor_script_state,shared_0543_0547,chr_0493_0497,ready_latch_001b,mapper_select,prg_8000,prg_a000,prg_c000,prg_e000,queue_bytes_04a5_0514"
local write_header = "sequence,pass,source_frame,emulator_frame,cycle_frame,cycle_absolute,kind,pc,prg_bank,address,old_value,new_value,a,x,y,p,sp,task_slots_0015_002c,scenario_cursor_003a,scenario_pointer_005d_005e,continuation_depth_0522,continuation_words_051a_0521,context_0518_053d,actor_record_index,actor_record_base,actor_record_after_write,worker_053a_053d,shared_0543_0547,ready_latch_001b"
local frame_now, frame_cycle_start, pass_name, seq_event, seq_write = -1, -1, "", 0, 0
local events, writes
local function log_event(kind)
	local pc, a, x, y, p, sp = reg("pc"), reg("a"), reg("x"), reg("y"), reg("p"), reg("s")
	local cycles, emu_frame = -1, -1
	pcall(function() cycles = debugger.getcyclescount() end)
	pcall(function() emu_frame = emu.framecount() end)
	local actor_pointer, actor_bytes, actor_script_state = current_actor_state()
	local r0, r1, r2, r3 = prg_map()
	events:write(csv({seq_event, pass_name, frame_now, emu_frame, cycles-frame_cycle_start, cycles,
		kind, hx(pc,4), bank(pc), hx(a,2), hx(x,2), hx(y,2), hx(p,2), hx(sp,2),
		task_slots(), hx(b(0x003A),2), hx(w(0x005D),4), hx(b(0x0522),2), continuation_payload(),
		context_state(), hx(w(0x0052),4), worker_state(), actor_pointer, actor_bytes, actor_script_state,
		bytes_hex(0x0543,4), bytes_hex(0x0493,5), hx(b(0x001B),2), hx(mmc3_select,2),
		hx(r0,2), hx(r1,2), hx(r2,2), hx(r3,2), queue_context_kind(kind) and queue_bytes() or ""}) .. "\n")
	seq_event = seq_event + 1
end
local last_values = {}
local function log_write(address, new_value)
	local pc, a, x, y, p, sp = reg("pc"), reg("a"), reg("x"), reg("y"), reg("p"), reg("s")
	local cycles, emu_frame = -1, -1
	pcall(function() cycles = debugger.getcyclescount() end)
	pcall(function() emu_frame = emu.framecount() end)
	local index, base = actor_record_for(address)
	local rbytes = index >= 0 and bytes_hex(base, ACTOR_STRIDE) or ""
	writes:write(csv({seq_write, pass_name, frame_now, emu_frame, cycles-frame_cycle_start, cycles,
		index >= 0 and "actor_record_write" or "state_write", hx(pc,4), bank(pc), hx(address,4),
		hx(last_values[address],2), hx(new_value,2), hx(a,2), hx(x,2), hx(y,2), hx(p,2), hx(sp,2),
		task_slots(), hx(b(0x003A),2), hx(w(0x005D),4), hx(b(0x0522),2), continuation_payload(), context_state(),
		index >= 0 and index or "", base >= 0 and hx(base,4) or "", rbytes, worker_state(), bytes_hex(0x0543,4), hx(b(0x001B),2)}) .. "\n")
	seq_write = seq_write + 1
	last_values[address] = new_value
end

local pcs = {
	[0xCBB0]="scenario_start_CBB0", [0xC50F]="task_create_C50F", [0xCAE7]="task_seed_CAE7",
	[0xCA97]="scheduler_scan_CA97", [0xCB0F]="task_yield_CB0F", [0xCAF7]="task_finish_CAF7",
	[0x814C]="callback_dispatch_814C", [0x81A7]="callback_vector_81A7", [0x81BC]="callback_control_81BC",
	[0x8327]="map_placement_8327", [0xEC94]="scenario_wait_load_EC94", [0xECF8]="animation_worker_handoff_ECF8",
	[0xED0C]="mirror_handoff_ED0C", [0xED5B]="scenario_wait_decrement_ED5B", [0xED5F]="scenario_wait_compare_ED5F",
	[0xC7EE]="nmi_ready_latch_C7EE", [0xEE9F]="actor_loop_EE9F", [0x800F]="animation_worker_800F",
	[0x80AA]="actor_packet_constructor_80AA", [0x83D9]="appearance_interpreter_83D9", [0x84DC]="motion_interpreter_84DC",
	[0x8837]="scenario_FB_handler_8837", [0x883F]="scenario_FB_underflow_883F",
	[0x80CF]="scenario_root_terminal_80CF", [0x80EB]="scenario_depth_clear_80EB",
	[0x8852]="bank18_worker_8852", [0x88B9]="bank18_worker_88B9",
	[0xD575]="menu_wait_D575", [0xD5C3]="menu_queue_D5C3",
	[0xE145]="field_loop_E145", [0xE14D]="eligible_field_loop_E14D",
	[0xE1F7]="stamina_helper_E1F7", [0xE2BC]="stamina_helper_E2BC",
}
local expected_banks = {
	[0xCBB0]=30,[0xC50F]=30,[0xCAE7]=30,[0xCA97]=30,[0xCB0F]=30,[0xCAF7]=30,
	[0x814C]=11,[0x81A7]=11,[0x81BC]=11,[0x8327]=11,
	[0xEC94]=31,[0xECF8]=31,[0xED0C]=31,[0xED5B]=31,[0xED5F]=31,[0xC7EE]=30,[0xEE9F]=31,
	[0x800F]=20,[0x80AA]=20,[0x83D9]=20,[0x84DC]=20,
	[0x8837]=16,[0x883F]=16,[0x80CF]=16,[0x80EB]=16,
	[0x8852]=24,[0x88B9]=24,
	[0xD575]=30,[0xD5C3]=30,[0xE145]=31,[0xE14D]=31,[0xE1F7]=31,[0xE2BC]=31,
}
local watched = {}
local function watch_range(first, last)
	for address = first, last do watched[address] = true end
end
watch_range(0x0015, 0x002C)
watch_range(0x003A, 0x003A)
watch_range(0x0052, 0x0053)
watch_range(0x005D, 0x005E)
watch_range(0x0516, 0x053D)
watch_range(0x0543, 0x0546)
watch_range(ACTOR_FIRST, ACTOR_LAST)
watch_range(0x05CC, 0x05E2)
watch_range(0x0515, 0x0515)
watch_range(0x05C5, 0x05C6)
watch_range(0x0614, 0x0614)
watch_range(0x0618, 0x0618)
watch_range(0x04A5, 0x0514)
local attached_addresses = {}
for address in pairs(watched) do attached_addresses[#attached_addresses + 1] = address end
table.sort(attached_addresses)
local function attach()
	for _, address in ipairs(attached_addresses) do
		last_values[address] = b(address)
		local aa = address
		memory.registerwrite(aa, 1, function(_, _, value) log_write(aa, type(value)=="number" and value or b(aa)) end)
	end
	for address, name in pairs(pcs) do
		local aa, nn = address, name
		local expected_bank = expected_banks[aa]
		memory.registerexec(aa, function()
			local pc = reg("pc")
			if expected_bank == nil or bank(pc) == expected_bank then log_event(nn) end
		end)
	end
end
local function detach()
	for _, address in ipairs(attached_addresses) do pcall(memory.registerwrite, address, 1, nil) end
	for address in pairs(pcs) do pcall(memory.registerexec, address, nil) end
end

local function signature()
	local ram, ppu_mem = memory.readbyterange(0,0x800), ppu.readbyterange(0,0x4000)
	local r0,r1,r2,r3 = prg_map()
	local bank_regs = {}; for i=1,8 do bank_regs[i]=mmc3[i] end
	return {frame=emu.framecount(), cycles=debugger.getcyclescount(), ram=ram, ppu=ppu_mem,
		select=mmc3_select, banks=bank_regs, prg={r0,r1,r2,r3},
		mapped={b(0x8000),b(0xA000),b(0xC000),b(0xE000)}}
end
local function verify(saved, label)
	local now = signature()
	assert(now.frame==saved.frame and now.cycles==saved.cycles, label .. " frame/cycle mismatch")
	assert(now.ram==saved.ram and now.ppu==saved.ppu, label .. " full RAM/PPU mismatch")
	assert(now.select==saved.select, label .. " MMC3 selector mismatch")
	for i=1,8 do assert(now.banks[i]==saved.banks[i], label .. " MMC3 register mismatch") end
	for i=1,4 do assert(now.prg[i]==saved.prg[i] and now.mapped[i]==saved.mapped[i], label .. " PRG mapping mismatch") end
end

local startup = "nil"; pcall(function() startup=tostring(movie.mode()); if movie.mode()~=nil then pcall(movie.stop) end end)
if type(movie.active)=="function" then local active=false; pcall(function() active=movie.active() end); if active then pcall(movie.stop) end end
assert(tostring(movie.mode())=="nil", "could not stop startup movie")
progress("before_poweron")
memory.registerwrite(0x8000, 1, function(_,_,value) mmc3_select=value or 0 end)
memory.registerwrite(0x8001, 1, function(_,_,value) mmc3[(mmc3_select%8)+1]=value or 0 end)
assert(pcall(emu.poweron), "emu.poweron failed")
progress("after_poweron")
if debugger.resetcyclescount then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode, "turbo")
progress("after_speedmode")
metadata:write("startup_movie_mode=" .. startup .. "\n")
metadata:flush()
for frame=0,CHECKPOINT_FRAME do
	if frame%100==0 then progress("warmup_before:"..frame) end
	joypad.set(1,inputs[frame]); emu.frameadvance()
	if frame%100==0 or frame==CHECKPOINT_FRAME then progress("warmup:"..frame) end
end
local checkpoint=savestate.create(); assert(checkpoint, "could not allocate anonymous checkpoint")
local checkpoint_sig=signature()
assert(checkpoint_sig.frame==CHECKPOINT_FRAME, "checkpoint source frame mismatch")
assert(pcall(savestate.save,checkpoint), "could not save anonymous checkpoint")
assert(pcall(savestate.persist,checkpoint), "could not keep anonymous checkpoint for repeated loads")
metadata:write("checkpoint_frame="..checkpoint_sig.frame.."\ncheckpoint_cycles="..checkpoint_sig.cycles.."\ncheckpoint_signature=RAM2KiB,PPU16KiB,MMC3 registers,PRG map and mapped bytes\n")
metadata:flush()

for pass=1,2 do
	assert(pcall(savestate.load,checkpoint), "could not load anonymous checkpoint")
	mmc3_select=checkpoint_sig.select; for i=1,8 do mmc3[i]=checkpoint_sig.banks[i] end
	verify(checkpoint_sig, "pass"..pass)
	pass_name=tostring(pass); seq_event,seq_write=0,0; last_values={}
	events=output("menu_stamina_events"..(pass==1 and "" or "_repeat")..".csv",event_header)
	writes=output("menu_stamina_writes"..(pass==1 and "" or "_repeat")..".csv",write_header)
	local queue_start = assert(io.open(OUT .. "/queue_start" .. (pass==1 and "" or "_repeat") .. ".bin", "wb"))
	local queue_start_bytes = {}
	for address=0x04A5,0x0514 do queue_start_bytes[#queue_start_bytes+1]=string.char(b(address)) end
	queue_start:write(table.concat(queue_start_bytes)); queue_start:close()
	attach()
	for frame=FIRST_FRAME,LAST_FRAME do
		frame_now=frame; joypad.set(1,inputs[frame]); frame_cycle_start=debugger.getcyclescount(); emu.frameadvance()
		if frame%30==0 or frame==LAST_FRAME then
			events:flush(); writes:flush()
			progress(pass..":"..frame)
		end
	end
	detach(); events:close(); writes:close()
	local queue_end = assert(io.open(OUT .. "/queue_end" .. (pass==1 and "" or "_repeat") .. ".bin", "wb"))
	local queue_end_bytes = {}
	for address=0x04A5,0x0514 do queue_end_bytes[#queue_end_bytes+1]=string.char(b(address)) end
	queue_end:write(table.concat(queue_end_bytes)); queue_end:close()
	metadata:write("pass_"..pass.."_events="..seq_event.."\npass_"..pass.."_writes="..seq_write.."\n")
	metadata:flush()
end
metadata:write("complete=true\nreplays=2, same anonymous frame-8399 checkpoint\n")
metadata:close()
pcall(memory.registerwrite,0x8000,1,nil); pcall(memory.registerwrite,0x8001,1,nil)
os.exit()

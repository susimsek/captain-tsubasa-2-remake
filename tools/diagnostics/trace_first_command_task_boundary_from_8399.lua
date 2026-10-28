-- Muted, bounded task-boundary trace for the fresh-start command route.
-- Warm from power-on once, save a signature-checked anonymous state at frame
-- 8399, then capture frames 8400-8953 twice. No numbered slot is used.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_TASK_BOUNDARY_TRACE_OUTPUT_DIR"), "missing output directory")
local LAST_FRAME = 8953
local CHECKPOINT_FRAME = 8399
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
local function hx(value, digits)
	if type(value) ~= "number" or value < 0 then return "" end
	return string.format(digits == 2 and "$%02X" or "$%04X", value)
end
local function csv(fields)
	local values = {}
	for i, value in ipairs(fields) do values[i] = tostring(value == nil and "" or value):gsub(",", ";") end
	return table.concat(values, ",")
end
local function bytes_hex(first, count)
	local values = {}
	for offset=0,count-1 do values[#values+1]=string.format("%02X",b(first+offset)) end
	return table.concat(values," ")
end
local function progress(value)
	local f=assert(io.open(OUT .. "/progress.txt","w")); f:write(value .. "\n"); f:close()
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

local metadata = output("metadata.txt")
metadata:write("source_frames=0-" .. LAST_FRAME .. "\ninstrumented_frames=8400-" .. LAST_FRAME .. "\n")
local rom_hash = "unavailable"
pcall(function() rom_hash = rom.gethash("sha256") or rom_hash end)
metadata:write("rom_sha256=" .. tostring(rom_hash) .. "\n")
metadata:write("emulator=FCEUX 2.7.0; NTSC; NewPPU; audio muted\n")
metadata:write("hooks=handoff $C557/$C6BE/$C6E8/$A2AF/$AA06; task $CBB0/$C50F/$CAE7/$CA97/$CAB6/$CAB9/$CAD4/$CB0F/$CAF7; scenario $10:$803F/$8097 and $0523-$0529; callback $0B:$814C/$81A7/$81BC/$8327/$8525; workers $EC94/$EC9A/$ECF8/$ECFA/$ED01/$ED06/$ED0F/$ED15/$ED2D/$ED5B/$ED5F; actor entry $14:$800F/$80AA; bank18 $8852/$88B9; no $CAAE idle-spin hook\n")
metadata:write("task_snapshot=slot $0011 plus seven 4-byte records $0015-$002C; all 256 stack-page bytes and each record's saved-SP window at every selected event; mapper shadows $0024/$0025; X/Y/A/P/SP and mapped PRG banks\n")
metadata:write("save_state=anonymous in-memory at source frame 8399, signature checked after both loads; no numbered slots\n")
metadata:flush()

local event_header = "sequence,pass,frame,emulator_frame,cycle_from_frame_start,cycle_absolute,kind,pc,prg_bank,a,x,y,p,sp,current_task_base_0000,current_task_record_0000_0003,task_slots_0011_002c,task_stack_windows_by_saved_sp,stack_page_0100_01ff,mapper_shadow_0024_0025,mapper_select,prg_map,ready_latch_001b,scenario_0516_0518,wait_0519,record_fields_0523_0529,callback_ptr_0052_0053,stream_index_003a,stream_bytes_0_2,scenario_pc_005d_005e,continuation_depth_0522,continuation_words_051a_0521,worker_053a_053d,animation_ptr_004c_004d,shared_05cc_05ce,actor_worker_0011_0014"
local write_header = "sequence,pass,frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc_after_write,prg_bank,address,old,new,a,x,y,p,sp,current_task_base_0000,task_slots_0011_002c,mapper_shadow_0024_0025,ready_latch_001b,scenario_0516_0518,callback_0524,stream_index_003a,scenario_pc_005d_005e,worker_053a_053d"

local frame_now, frame_cycle_start, pass_name, seq_event, seq_write = -1, -1, "", 0, 0
local events, writes
local task_bases = {0x11,0x15,0x19,0x1D,0x21,0x25,0x29}
local function task_slots()
	local parts = {}
	for _, base in ipairs(task_bases) do
		parts[#parts + 1] = string.format("%02X:%02X%02X%02X%02X", base,
			b(base), b(base + 1), b(base + 2), b(base + 3))
	end
	return table.concat(parts, "|")
end
local function task_stack_pages()
	local parts = {}
	for _, base in ipairs(task_bases) do
		local sp = b(base + 1)
		local bytes = {}
		for i = 1, 16 do bytes[#bytes + 1] = string.format("%02X", b(0x0100 + ((sp + i) % 0x100))) end
		parts[#parts + 1] = string.format("%02X:%02X:%s", base, sp, table.concat(bytes, ""))
	end
	return table.concat(parts, "|")
end
local function stack_page()
	local values = {}
	for address = 0x0100, 0x01FF do values[#values + 1] = string.format("%02X", b(address)) end
	return table.concat(values, "")
end
local function continuation_words()
	local parts = {}
	for address = 0x051A, 0x0521 do parts[#parts + 1] = hx(b(address), 2) end
	return table.concat(parts, " ")
end
local function stream_bytes()
	local pointer = w(0x0052)
	if pointer < 0x8000 or pointer > 0xBFFD then return "" end
	local values = {}
	for offset = 0, 2 do values[#values + 1] = hx(b(pointer + offset), 2) end
	return table.concat(values, " ")
end
local function record_fields()
	local values = {}
	for address = 0x0523, 0x0529 do values[#values + 1] = hx(b(address), 2) end
	return table.concat(values, " ")
end
local function prg_description()
	local r0,r1,r2,r3 = prg_map()
	return string.format("%02X/%02X/%02X/%02X",r0,r1,r2,r3)
end
local function log_event(kind)
	local pc, a, x, y, p, sp = reg("pc"), reg("a"), reg("x"), reg("y"), reg("p"), reg("s")
	local cycles, emu_frame = -1, -1
	pcall(function() cycles = debugger.getcyclescount() end)
	pcall(function() emu_frame = emu.framecount() end)
	local base = b(0x0000)
	local current_record = bytes_hex(base, 4)
	local fields = {
		seq_event, pass_name, frame_now, emu_frame, cycles - frame_cycle_start, cycles,
		kind, hx(pc, 4), bank(pc), hx(a, 2), hx(x, 2), hx(y, 2), hx(p, 2), hx(sp, 2),
		hx(base, 2), current_record, task_slots(), task_stack_pages(), stack_page(),
		hx(b(0x0024), 2) .. " " .. hx(b(0x0025), 2), hx(mmc3_select, 2), prg_description(), hx(b(0x001B), 2),
		hx(b(0x0516), 2) .. " " .. hx(b(0x0518), 2), hx(b(0x0519), 2), record_fields(),
		hx(b(0x0052), 2) .. " " .. hx(b(0x0053), 2), hx(b(0x003A), 2), stream_bytes(),
		hx(b(0x005D), 2) .. " " .. hx(b(0x005E), 2), hx(b(0x0522), 2), continuation_words(),
		bytes_hex(0x053A, 4), hx(b(0x004C), 2) .. " " .. hx(b(0x004D), 2),
		hx(b(0x05CC), 2) .. " " .. hx(b(0x05CD), 2) .. " " .. hx(b(0x05CE), 2), bytes_hex(0x0011, 4),
	}
	events:write(csv(fields) .. "\n")
	seq_event = seq_event + 1
end

local last_value = {}
local function log_write(address, new_value)
	local pc, a, x, y, p = reg("pc"), reg("a"), reg("x"), reg("y"), reg("p")
	local cycles, emu_frame = -1, -1
	pcall(function() cycles = debugger.getcyclescount() end)
	pcall(function() emu_frame = emu.framecount() end)
	local r0 = prg_map()
	writes:write(csv({seq_write, pass_name, frame_now, emu_frame,
		cycles - frame_cycle_start, cycles, hx(pc, 4), bank(pc), hx(address, 4),
		hx(last_value[address], 2), hx(new_value, 2), hx(a, 2), hx(x, 2), hx(y, 2), hx(p, 2), hx(reg("s"), 2),
		hx(b(0x0000), 2), task_slots(), hx(b(0x0024), 2) .. " " .. hx(b(0x0025), 2), hx(b(0x001B), 2),
		hx(b(0x0516), 2) .. " " .. hx(b(0x0518), 2), hx(b(0x0524), 2), hx(b(0x003A), 2),
		hx(b(0x005D), 2) .. " " .. hx(b(0x005E), 2), bytes_hex(0x053A, 4)}) .. "\n")
	seq_write = seq_write + 1
	last_value[address] = new_value
end

local pcs = {
	[0xA2AF]="fresh_match_handoff_A2AF", [0xAA06]="fresh_game_ram_clear_AA06",
	[0xC557]="fresh_scheduler_jump_C557", [0xC6BE]="fresh_task_slot_setup_C6BE",
	[0xC6E8]="fresh_root_task_bootstrap_C6E8",
	[0xCBB0]="scenario_start_CBB0", [0xC50F]="task_create_C50F", [0xCAE7]="task_seed_CAE7",
	[0xCA97]="scheduler_scan_CA97", [0xCAB6]="scheduler_latch_clear_CAB6", [0xCAB9]="task_resume_CAB9",
	[0xCAD4]="task_first_dispatch_CAD4", [0xCB0F]="task_yield_save_CB0F", [0xCAF7]="task_finish_CAF7",
	[0xC515]="task_yield_trampoline_C515", [0x803F]="scenario_record_read_803F", [0x8097]="scenario_task_setup_8097",
	[0x814C]="callback_read_814C", [0x81A7]="callback_vector_81A7", [0x81BC]="callback_control_81BC",
	[0x8327]="callback_handler_8327", [0x8525]="map_worker_8525",
	[0xEC94]="scenario_wait_load_EC94", [0xEC9A]="scenario_wait_cont_EC9A", [0xECF8]="animation_worker_handoff_ECF8",
	[0xECFA]="animation_worker_setup_ECFA", [0xED01]="animation_worker_pointer_ED01", [0xED06]="animation_worker_ready_ED06",
	[0xED0F]="worker_param_copy_ED0F", [0xED15]="worker_slot11_seed_ED15", [0xED2D]="worker_launch_tail_ED2D",
	[0xED5B]="scenario_wait_tick_ED5B", [0xED5F]="scenario_wait_compare_ED5F",
	[0x800F]="bank14_actor_worker_800F", [0x80AA]="bank14_actor_constructor_80AA",
	[0x8852]="bank18_worker_8852", [0x88B9]="bank18_worker_88B9",
}
local expected_banks = {
	[0xA2AF]=2,[0xAA06]=2,[0xC557]=30,[0xC6BE]=30,[0xC6E8]=30,
	[0xCBB0]=30,[0xC50F]=30,[0xCAE7]=30,[0xCA97]=30,[0xCAB6]=30,[0xCAB9]=30,[0xCAD4]=30,[0xCB0F]=30,[0xCAF7]=30,[0xC515]=30,
	[0x803F]=16,[0x8097]=16,[0x814C]=11,[0x81A7]=11,[0x81BC]=11,[0x8327]=11,[0x8525]=11,
	[0xEC94]=31,[0xEC9A]=31,[0xECF8]=31,[0xECFA]=31,[0xED01]=31,[0xED06]=31,[0xED0F]=31,[0xED15]=31,[0xED2D]=31,[0xED5B]=31,[0xED5F]=31,
	[0x800F]=20,[0x80AA]=20,[0x8852]=24,[0x88B9]=24,
}
local watched_set, watched = {}, {}
local function watch(first,last) for address=first,last do watched_set[address]=true end end
watch(0x0000,0x0003); watch(0x0005,0x0005); watch(0x0011,0x002C); watch(0x0024,0x0025)
watch(0x003A,0x003A); watch(0x004C,0x0053); watch(0x005D,0x005E); watch(0x007F,0x007F)
watch(0x0516,0x053D); watch(0x05CC,0x05E2)
for address in pairs(watched_set) do watched[#watched+1]=address end
table.sort(watched)
local function attach()
	for _, address in ipairs(watched) do
		local aa = address
		last_value[aa] = b(aa)
		memory.registerwrite(aa, 1, function(_, _, new_value) log_write(aa, new_value) end)
	end
	for address, name in pairs(pcs) do
		local aa, nn, expected = address, name, expected_banks[address]
		memory.registerexec(aa, function() if bank(reg("pc")) == expected then log_event(nn) end end)
	end
end
local function detach()
	for _, address in ipairs(watched) do pcall(memory.registerwrite, address, 1, nil) end
	for address in pairs(pcs) do pcall(memory.registerexec, address, nil) end
end

local function signature()
	local ram = memory.readbyterange(0, 0x800)
	local ppu_mem = ppu.readbyterange(0, 0x4000)
	local r0, r1 = prg_map()
	local banks = {}
	for i = 1, 8 do banks[i] = mmc3[i] end
	return {frame=emu.framecount(), cycles=debugger.getcyclescount(), ram=ram, ppu=ppu_mem,
		select=mmc3_select, banks=banks, prg={r0,r1,30,31},
		mapped={b(0x8000),b(0xA000),b(0xC000),b(0xE000)}}
end
local function verify(saved, label)
	local current = signature()
	assert(current.frame == saved.frame and current.cycles == saved.cycles, label .. " frame/cycle mismatch")
	assert(current.ram == saved.ram and current.ppu == saved.ppu, label .. " RAM/PPU mismatch")
	assert(current.select == saved.select, label .. " MMC3 selector mismatch")
	for i = 1, 8 do assert(current.banks[i] == saved.banks[i], label .. " MMC3 bank mismatch") end
	for i = 1, 4 do assert(current.prg[i] == saved.prg[i] and current.mapped[i] == saved.mapped[i], label .. " PRG map mismatch") end
end

local startup = "nil"
pcall(function() startup = tostring(movie.mode()); if movie.mode() ~= nil then pcall(movie.stop) end end)
if type(movie.active) == "function" then local active=false; pcall(function() active=movie.active() end); if active then pcall(movie.stop) end end
assert(tostring(movie.mode()) == "nil", "could not stop startup movie")
memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value) mmc3[(mmc3_select % 8) + 1] = value or 0 end)
assert(pcall(emu.poweron), "emu.poweron failed")
progress("after_poweron")
if debugger.resetcyclescount then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode, "turbo")
progress("after_speedmode")
metadata:write("startup_movie_mode=" .. startup .. "\n")
metadata:flush()

progress("before_warmup")
for frame = 0, CHECKPOINT_FRAME do
	if frame == 0 or frame % 100 == 0 then progress("warmup_before:" .. frame) end
	joypad.set(1, inputs[frame])
	emu.frameadvance()
	if frame % 100 == 0 or frame == CHECKPOINT_FRAME then progress("warmup:" .. frame) end
end
local checkpoint = savestate.create()
assert(checkpoint, "savestate.create failed")
local checkpoint_sig = signature()
assert(pcall(savestate.save, checkpoint), "savestate.save failed")
assert(pcall(savestate.persist, checkpoint), "savestate.persist failed")
metadata:write("checkpoint_frame=" .. checkpoint_sig.frame .. "\ncheckpoint_cycles=" .. checkpoint_sig.cycles .. "\ncheckpoint_signature=frame/cycle, RAM2KiB, PPU16KiB, MMC3 registers and mapped PRG bytes\n")
metadata:flush()

for pass = 1, 2 do
	progress("before_restore:" .. pass)
	assert(pcall(savestate.load, checkpoint), "savestate.load failed")
	mmc3_select = checkpoint_sig.select
	for i = 1, 8 do mmc3[i] = checkpoint_sig.banks[i] end
	verify(checkpoint_sig, "pass " .. pass)
	pass_name, seq_event, seq_write = tostring(pass), 0, 0
	events = output("task_events" .. (pass == 1 and "" or "_repeat") .. ".csv", event_header)
	writes = output("task_writes" .. (pass == 1 and "" or "_repeat") .. ".csv", write_header)
	attach()
	for frame = 8400, LAST_FRAME do
		frame_now = frame
		joypad.set(1, inputs[frame])
		frame_cycle_start = debugger.getcyclescount()
		emu.frameadvance()
		if frame % 50 == 0 or frame == LAST_FRAME then
			events:flush(); writes:flush()
			progress(pass .. ":" .. frame)
		end
	end
	detach(); events:close(); writes:close()
	metadata:write("pass_" .. pass .. "_events=" .. seq_event .. "\npass_" .. pass .. "_writes=" .. seq_write .. "\n")
	metadata:flush()
end

metadata:write("complete=true\nreplays=2, same anonymous frame-8399 checkpoint\n")
metadata:close()
pcall(memory.registerwrite, 0x8000, 1, nil)
pcall(memory.registerwrite, 0x8001, 1, nil)
os.exit()

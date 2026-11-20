-- Muted, bounded trace of the ROM's PASS confirmation waiter and return path.
-- Warm from power-on once, save an anonymous signature-checked checkpoint at
-- frame 9042, then capture frames 9043-9600 twice. No numbered slot is used.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local ACTION_EDGES = ROOT .. "/reference/diagnostics/first_pass_action_input_edges_20261110.csv"
local OUT = assert(os.getenv("CT2_PASS_WAITER_TRACE_OUTPUT_DIR"), "missing output directory")
local CHECKPOINT_FRAME, FIRST_REPLAY_FRAME, LAST_FRAME = 9042, 9043, 9600
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
for frame = 0, CHECKPOINT_FRAME do assert(inputs[frame], "missing source input frame " .. frame) end

local edge_events = {}
do
	local file = assert(io.open(ACTION_EDGES, "r"), "missing first-action edge file")
	local first = true
	for line in file:lines() do
		line = line:gsub("\r$", "")
		if first then first = false else
			local values = {}
			for value in (line .. ","):gmatch("(.-),") do values[#values + 1] = value end
			local frame, button, pressed = tonumber(values[1]), values[2], values[3]
			assert(frame and button and pressed, "malformed action input edge")
			edge_events[frame] = edge_events[frame] or {}
			edge_events[frame][button] = pressed == "1"
		end
	end
	file:close()
end

local function copy_buttons(source)
	local result = {}
	for key, value in pairs(source) do result[key] = value end
	return result
end

local input_key = {Up="up", Down="down", Left="left", Right="right",
	A="A", B="B", Start="start", Select="select"}
local carried = copy_buttons(inputs[CHECKPOINT_FRAME])
for frame = FIRST_REPLAY_FRAME, LAST_FRAME do
	for button, pressed in pairs(edge_events[frame] or {}) do
		local key = input_key[button]
		assert(key, "unknown controller button in edge file: " .. button)
		assert(carried[key] ~= nil, "unknown controller button in edge file: " .. button)
		carried[key] = pressed
	end
	inputs[frame] = copy_buttons(carried)
end

local function output(name, header)
	local file = assert(io.open(OUT .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end
local function write_binary(name, bytes)
	local file = assert(io.open(OUT .. "/" .. name, "wb"))
	assert(file:write(bytes), "failed to write " .. name)
	file:close()
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
local function hx(value, digits)
	if type(value) ~= "number" or value < 0 then return "" end
	return string.format(digits == 2 and "$%02X" or "$%04X", value)
end
local function csv(fields)
	local values = {}
	for i, value in ipairs(fields) do
		local text = tostring(value == nil and "" or value)
		if text:find('[,\"\r\n]') then text = '"' .. text:gsub('"', '""') .. '"' end
		values[i] = text
	end
	return table.concat(values, ",")
end
local function bytes_hex(first, count)
	local values = {}
	for offset=0,count-1 do values[#values+1]=string.format("%02X",b(first+offset)) end
	return table.concat(values, "")
end
local function progress(value)
	local file=assert(io.open(OUT .. "/progress.txt","w")); file:write(value .. "\n"); file:close()
end
local function hash_bytes(bytes)
	local hash = 0
	for index=1,#bytes do hash = (hash * 131 + string.byte(bytes, index)) % 4294967291 end
	return string.format("%08X", hash)
end
local function ppu_ram_hash()
	local bytes = ppu.readbyterange(0, 0x4000)
	assert(type(bytes) == "string" and #bytes == 0x4000, "PPU RAM read range is unavailable")
	return hash_bytes(bytes)
end
local function full_ram_hex()
	local values = {}
	for address=0,0x7FF do values[#values+1]=string.format("%02X", b(address)) end
	return table.concat(values, "")
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
local function mmc3_fields()
	local values = {}
	for index=1,8 do values[#values+1]=string.format("%02X",mmc3[index]) end
	return table.concat(values, "")
end
local function queue_signature()
	return "046F=" .. bytes_hex(0x046F, 0x11)
		.. ";0498=" .. bytes_hex(0x0498, 0x10)
		.. ";0515=" .. bytes_hex(0x0515, 5)
end

local metadata = output("metadata.txt")
metadata:write("source_frames=0-" .. LAST_FRAME .. "\ninstrumented_frames=" .. FIRST_REPLAY_FRAME .. "-" .. LAST_FRAME .. "\n")
local rom_hash = "unavailable"
pcall(function() rom_hash = rom.gethash("sha256") or rom_hash end)
metadata:write("rom_sha256=" .. tostring(rom_hash) .. "\n")
metadata:write("emulator=FCEUX 2.7.0; NTSC; NewPPU; audio muted\n")
metadata:write("hooks=$0005 write,$0498 write,$0063/$0064 write,$0518 write,$062D write,$D70C,$CC50,$CC53,$CCA0,$CCA3,$CCCE,$CCD1,$D70F,$D714,$D715,$D716,$D568,$CE2D,$8047,$A103,$E07E,$E709,$EB8B,$EB9E,$EE9F,$EEB1,$EBB3,$86F8,$8722,$CBBE,$CB0F,$CAA5,$814C,$8327,$8525,$856F,$C515,$A21A,$804A,$8003,$8021,$803F,$8837,$80CF; route capture=" .. FIRST_REPLAY_FRAME .. "-" .. LAST_FRAME .. "\n")
metadata:write("event_snapshot=full CPU A/X/Y/P/SP, 2 KiB RAM including stack page, MMC3 select and eight registers, PRG map/readback, 16 KiB PPU RAM hash, RAM queue signature\n")
metadata:write("input_prefix=opening_reference_capture/input_timeline.csv 0-4692 + kickoff_select_test_20261027/post_title_inputs.csv 4693-9042 + first_pass_action_input_edges_20261110.csv; A press at 9076 and release at 9077 are both applied\n")
metadata:write("save_state=anonymous in-memory at source frame 9042, full RAM/PPU/cycle/MMC3/PRG signature checked after both loads; no numbered slots\n")
metadata:flush()

local event_header = "sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,event,pc,prg_bank,a,x,y,p,sp,task_slot_0000,scenario_0516_0519,holder_0441,receiver_05fc,wait_flag_062d,queue_signature,ppu_ram_hash_16k,mmc3_select,mmc3_registers_0_7,prg_map_8000_a000_c000_e000,prg_bytes_at_8000_a000_c000_e000,ram_0000_07ff"
local target_pcs = {
	[0xEE9F] = {"EE9F_actor_init_entry", -1},
	[0xEEB1] = {"EEB1_actor_init_return", -1},
	[0xEB8B] = {"EB8B_scenario_root", -1},
	[0xEB9E] = {"EB9E_scenario_return", -1},
	[0xEBB3] = {"EBB3_worker_return", -1},
	[0x86F8] = {"86F8_worker_entry", -1},
	[0x8722] = {"8722_worker_rts", -1},
	[0xCBBE] = {"CBBE_scheduler_save", -1},
	[0xCB0F] = {"CB0F_scheduler_save", -1},
	[0xCAA5] = {"CAA5_scheduler_select", -1},
	[0x814C] = {"814C_callback_dispatcher", 0x0B},
	[0x8327] = {"8327_callback_handler", -1},
	[0x8525] = {"8525_map_worker", -1},
	[0x856F] = {"856F_map_worker_yield", -1},
	[0xC515] = {"C515_nmi_wait", -1},
	[0xA21A] = {"A21A_actor_animation_gate", 0x1B},
	[0x804A] = {"804A_slot11_actor_dispatch", 0x18},
	[0x8003] = {"bank10_8003_entry", 0x10},
	[0x8021] = {"bank10_8021_reader", 0x10},
	[0x803F] = {"bank10_803F_opcode", 0x10},
	[0x8837] = {"bank10_FB_handler", 0x10},
	[0x80CF] = {"bank10_F0_terminal", 0x10},
	[0xD70C] = {"D70C_action_cleanup", 30},
	[0xCC50] = {"CC50_waiter_yield", 30},
	[0xCC53] = {"CC53_waiter_resume", 30},
	[0xCCA0] = {"CCA0_waiter_yield", 30},
	[0xCCA3] = {"CCA3_waiter_resume", 30},
	[0xCCCE] = {"CCCE_waiter_yield", 30},
	[0xCCD1] = {"CCD1_waiter_resume", 30},
	[0xD70F] = {"D70F_action_return", 30},
	[0xD714] = {"D714_action_return", 30},
	[0xD715] = {"D715_action_return", 30},
	[0xD716] = {"D716_action_return", 30},
	[0xD568] = {"D568_post_wait_return", 30},
	[0xCE2D] = {"CE2D_post_wait_mapper", 30},
	[0x8047] = {"8047_field_bank_entry", 26},
	[0xA103] = {"A103_field_worker", 27},
	[0xE07E] = {"E07E_field_update_caller", 31},
	[0xE709] = {"E709_field_update", 31},
	[0xE247] = {"E247_slot05_waitflag_check", 31},
	[0xE267] = {"E267_slot05_waitflag_return", 31},
	[0xE252] = {"E252_slot05_waitflag_set", 31},
	[0x8024] = {"8024_source", -1},
	[0x82CA] = {"82CA_source", -1},
	[0xC52D] = {"bank30_C52D_source", 30},
	[0xCC46] = {"CC46_scenario1e_waiter", 30},
	[0x82E3] = {"82E3_source", -1},
}

local frame_now, frame_cycle_start, pass_name, sequence = -1, -1, "", 0
local events
local primary_queue_writes
local primary_queue_write_sequence = 0
local animation_pointer_writes
local animation_pointer_write_sequence = 0
local wait_flag_writes
local wait_flag_write_sequence = 0
local task05_record_writes
local task05_record_write_sequence = 0
local task05_record_previous_value = 0
local scenario0518_writes
local scenario0518_write_sequence = 0
local scenario0518_previous_value = 0
local scenario0519_writes
local scenario0519_write_sequence = 0
local scenario0519_previous_value = 0
local scenario0523_writes
local scenario0523_write_sequence = 0
local scenario0523_previous_value = 0
local scenario_ec94_reads
local scenario_ec94_read_sequence = 0
local scenario_timeline
local function capture_route_event()
	return frame_now >= FIRST_REPLAY_FRAME and (
		b(0x043B) == 0x01 and b(0x0441) == 0x06 and b(0x05FC) == 0x0A
		or b(0x0518) == 0x2E
		or b(0x0518) == 0x1E
		or (frame_now >= 9191 and frame_now <= 9256 and b(0x0518) == 0x1C))
end
local post_wait_path = "not_started"
local a103_logged = false
local function log_event(address, name)
	local pc, a, x, y, p, sp = reg("pc"), reg("a"), reg("x"), reg("y"), reg("p"), reg("s")
	local cycles, emulator_frame = -1, -1
	pcall(function() cycles = debugger.getcyclescount() end)
	pcall(function() emulator_frame = emu.framecount() end)
	local r0,r1,r2,r3 = prg_map()
	events:write(csv({sequence, pass_name, frame_now, emulator_frame,
		cycles - frame_cycle_start, cycles, name, hx(pc,4), bank(pc), hx(a,2), hx(x,2), hx(y,2), hx(p,2), hx(sp,2),
		hx(b(0x0000),2), bytes_hex(0x0516,4), hx(b(0x0441),2), hx(b(0x05FC),2), hx(b(0x062D),2),
		queue_signature(), ppu_ram_hash(), hx(mmc3_select,2), mmc3_fields(),
		string.format("%02X/%02X/%02X/%02X",r0,r1,r2,r3),
		bytes_hex(0x8000,1) .. "/" .. bytes_hex(0xA000,1) .. "/" .. bytes_hex(0xC000,1) .. "/" .. bytes_hex(0xE000,1),
		full_ram_hex()}) .. "\n")
	sequence = sequence + 1
end

local function signature()
	local ram = memory.readbyterange(0, 0x800)
	local ppu_mem = ppu.readbyterange(0, 0x4000)
	local r0, r1 = prg_map()
	local banks = {}
	for i = 1, 8 do banks[i] = mmc3[i] end
	local cpu = {pc=reg("pc"), a=reg("a"), x=reg("x"), y=reg("y"),
		p=reg("p"), sp=reg("s")}
	return {frame=emu.framecount(), cycles=debugger.getcyclescount(), ram=ram, ppu=ppu_mem,
		select=mmc3_select, banks=banks, prg={r0,r1,30,31},
		mapped={b(0x8000),b(0xA000),b(0xC000),b(0xE000)}, cpu=cpu}
end
local function verify(saved, label)
	local current = signature()
	assert(current.frame == saved.frame and current.cycles == saved.cycles, label .. " frame/cycle mismatch")
	assert(current.ram == saved.ram and current.ppu == saved.ppu, label .. " RAM/PPU mismatch")
	for name, value in pairs(saved.cpu) do
		assert(current.cpu[name] == value, label .. " CPU " .. name .. " mismatch")
	end
	assert(current.select == saved.select, label .. " MMC3 selector mismatch")
	for i=1,8 do assert(current.banks[i] == saved.banks[i], label .. " MMC3 register mismatch") end
	for i=1,4 do assert(current.prg[i] == saved.prg[i] and current.mapped[i] == saved.mapped[i], label .. " PRG map/readback mismatch") end
end
local function attach()
	task05_record_previous_value = b(0x0005)
	scenario0518_previous_value = b(0x0518)
	scenario0519_previous_value = b(0x0519)
	scenario0523_previous_value = b(0x0523)
	memory.registerwrite(0x0523, 1, function(_, write_size, new_value)
		if scenario0523_writes == nil then return end
		local previous_value = scenario0523_previous_value
		local written_value = type(new_value) == "number" and new_value or b(0x0523)
		scenario0523_previous_value = written_value
		if frame_now < 9043 or frame_now > 9235 then return end
		local pc = reg("pc")
		local cycles = -1
		pcall(function() cycles = debugger.getcyclescount() end)
		local emulator_frame = -1
		pcall(function() emulator_frame = emu.framecount() end)
		scenario0523_writes:write(csv({scenario0523_write_sequence, pass_name,
			frame_now, emulator_frame, cycles - frame_cycle_start, cycles,
			hx(pc, 4), bank(pc), hx(previous_value, 2), hx(write_size, 2),
			hx(written_value, 2), hx(b(0x0000), 2), bytes_hex(0x0001, 3),
			bytes_hex(0x0005, 4), bytes_hex(0x0009, 4), bytes_hex(0x0011, 4),
			bytes_hex(0x0015, 4), bytes_hex(0x0516, 4), bytes_hex(0x0523, 8),
			hx(reg("a"), 2), hx(reg("x"), 2), hx(reg("y"), 2), hx(reg("s"), 2)}) .. "\n")
		scenario0523_write_sequence = scenario0523_write_sequence + 1
	end)
	memory.registerexec(0xEC94, function()
		if frame_now < 9043 or frame_now > 9235 or scenario_ec94_reads == nil or b(0x0518) ~= 0x1C then return end
		local cycles = -1
		pcall(function() cycles = debugger.getcyclescount() end)
		local emulator_frame = -1
		pcall(function() emulator_frame = emu.framecount() end)
		scenario_ec94_reads:write(csv({scenario_ec94_read_sequence, pass_name,
			frame_now, emulator_frame, cycles - frame_cycle_start, cycles,
			hx(reg("pc"), 4), bank(reg("pc")), hx(b(0x0000), 2),
			bytes_hex(0x0001, 3), bytes_hex(0x0005, 4), bytes_hex(0x0009, 4),
			bytes_hex(0x0011, 4), bytes_hex(0x0015, 4), bytes_hex(0x0516, 4),
			bytes_hex(0x0523, 8), hx(reg("a"), 2), hx(reg("x"), 2),
			hx(reg("y"), 2), hx(reg("s"), 2)}) .. "\n")
		scenario_ec94_read_sequence = scenario_ec94_read_sequence + 1
	end)
	memory.registerwrite(0x0519, 1, function(_, write_size, new_value)
		if scenario0519_writes == nil then return end
		local previous_value = scenario0519_previous_value
		local written_value = type(new_value) == "number" and new_value or b(0x0519)
		scenario0519_previous_value = written_value
		if frame_now < 9043 or frame_now > 9235 then return end
		local pc = reg("pc")
		local cycles = -1
		pcall(function() cycles = debugger.getcyclescount() end)
		local emulator_frame = -1
		pcall(function() emulator_frame = emu.framecount() end)
		scenario0519_writes:write(csv({scenario0519_write_sequence, pass_name,
			frame_now, emulator_frame, cycles - frame_cycle_start, cycles,
			hx(pc, 4), bank(pc), hx(previous_value, 2), hx(write_size, 2),
			hx(written_value, 2), hx(b(0x0000), 2), bytes_hex(0x0001, 3),
			bytes_hex(0x0005, 4), bytes_hex(0x0009, 4), bytes_hex(0x0011, 4),
			bytes_hex(0x0015, 4), bytes_hex(0x0516, 4), hx(reg("a"), 2),
			hx(reg("x"), 2), hx(reg("y"), 2), hx(reg("s"), 2)}) .. "\n")
		scenario0519_write_sequence = scenario0519_write_sequence + 1
	end)
	memory.registerwrite(0x0518, 1, function(_, write_size, new_value)
		if scenario0518_writes == nil then return end
		local previous_value = scenario0518_previous_value
		local written_value = type(new_value) == "number" and new_value or b(0x0518)
		scenario0518_previous_value = written_value
		if frame_now < 9238 or frame_now > 9256 then return end
		local pc = reg("pc")
		local cycles = -1
		pcall(function() cycles = debugger.getcyclescount() end)
		local emulator_frame = -1
		pcall(function() emulator_frame = emu.framecount() end)
		scenario0518_writes:write(csv({scenario0518_write_sequence, pass_name,
			frame_now, emulator_frame, cycles - frame_cycle_start, cycles,
			hx(pc, 4), bank(pc), hx(previous_value, 2), hx(write_size, 2),
			hx(written_value, 2), hx(b(0x0000), 2), bytes_hex(0x0001, 3),
			bytes_hex(0x0005, 4), bytes_hex(0x0009, 4), bytes_hex(0x0011, 4),
			bytes_hex(0x0015, 4), bytes_hex(0x0516, 4), hx(reg("a"), 2),
			hx(reg("x"), 2), hx(reg("y"), 2), hx(reg("s"), 2)}) .. "\n")
		scenario0518_write_sequence = scenario0518_write_sequence + 1
	end)
	memory.registerwrite(0x0005, 1, function(_, write_size, new_value)
		if frame_now < FIRST_REPLAY_FRAME or task05_record_writes == nil then return end
		local written_value = type(new_value) == "number" and new_value or b(0x0005)
		local pc = reg("pc")
		local cycles = -1
		pcall(function() cycles = debugger.getcyclescount() end)
		local emulator_frame = -1
		pcall(function() emulator_frame = emu.framecount() end)
		task05_record_writes:write(csv({task05_record_write_sequence, pass_name,
			frame_now, emulator_frame, cycles - frame_cycle_start, cycles,
			hx(pc, 4), bank(pc), hx(task05_record_previous_value, 2), hx(write_size, 2),
			hx(written_value, 2), hx(b(0x0000), 2), bytes_hex(0x0001, 3),
			bytes_hex(0x0005, 4), bytes_hex(0x0009, 4), bytes_hex(0x0011, 4),
			bytes_hex(0x0015, 4), bytes_hex(0x0516, 4), hx(reg("a"), 2),
			hx(reg("x"), 2), hx(reg("y"), 2), hx(reg("s"), 2)}) .. "\n")
		task05_record_write_sequence = task05_record_write_sequence + 1
		task05_record_previous_value = written_value
	end)
	-- FCEUX write callbacks receive (address, size, value), not old/new values.
	-- Reconstruct the previous byte from the checkpoint plus each observed write.
	wait_flag_previous_value = b(0x062D)
	memory.registerwrite(0x062D, 1, function(_, write_size, new_value)
		if frame_now < FIRST_REPLAY_FRAME or wait_flag_writes == nil then return end
		local previous_value = wait_flag_previous_value
		local written_value = type(new_value) == "number" and new_value or b(0x062D)
		local pc = reg("pc")
		local cycles = -1
		pcall(function() cycles = debugger.getcyclescount() end)
		local emulator_frame = -1
		pcall(function() emulator_frame = emu.framecount() end)
		wait_flag_writes:write(csv({wait_flag_write_sequence, pass_name,
			frame_now, emulator_frame, cycles - frame_cycle_start, cycles,
			hx(pc, 4), bank(pc), hx(previous_value, 2), hx(write_size, 2),
			hx(written_value, 2),
			hx(reg("a"), 2), hx(reg("x"), 2), hx(reg("y"), 2), hx(reg("p"), 2), hx(reg("s"), 2),
			hx(b(0x0000), 2), bytes_hex(0x0001, 3), bytes_hex(0x0005, 4),
			bytes_hex(0x0009, 4), bytes_hex(0x0011, 4), bytes_hex(0x0015, 4),
			bytes_hex(0x001B, 1), bytes_hex(0x0515, 5), bytes_hex(0x0516, 4),
			bytes_hex(0x05C7, 8), bytes_hex(0x0628, 6)}) .. "\n")
		wait_flag_write_sequence = wait_flag_write_sequence + 1
		wait_flag_previous_value = written_value
	end)
	for _, address in ipairs({0x0063, 0x0064}) do
		memory.registerwrite(address, 1, function(_, old_value, new_value)
			if frame_now < 9475 or animation_pointer_writes == nil then return end
			local pc = reg("pc")
			local cycles = -1
			pcall(function() cycles = debugger.getcyclescount() end)
			local emulator_frame = -1
			pcall(function() emulator_frame = emu.framecount() end)
			animation_pointer_writes:write(csv({animation_pointer_write_sequence, pass_name,
				frame_now, emulator_frame, cycles - frame_cycle_start, cycles, hx(address, 4),
				hx(pc, 4), bank(pc), hx(old_value, 2),
				hx(type(new_value) == "number" and new_value or b(address), 2),
				hx(reg("a"), 2), hx(reg("x"), 2), hx(reg("y"), 2), hx(reg("p"), 2), hx(reg("s"), 2),
				hx(b(0x0000), 2), hx(b(0x003A), 2), bytes_hex(0x0516, 4),
				bytes_hex(0x05E3, 8), bytes_hex(0x05F3, 3), bytes_hex(0x005F, 2),
				bytes_hex(0x0063, 2), bytes_hex(0x00C7, 4)}) .. "\n")
			animation_pointer_write_sequence = animation_pointer_write_sequence + 1
		end)
	end
	memory.registerwrite(0x0498, 1, function(_, old_value, new_value)
		if frame_now < FIRST_REPLAY_FRAME or primary_queue_writes == nil then return end
		local pc = reg("pc")
		local cycles = -1
		pcall(function() cycles = debugger.getcyclescount() end)
		local emulator_frame = -1
		pcall(function() emulator_frame = emu.framecount() end)
		local actor = b(0x003C) + (b(0x003D) * 0x100)
		primary_queue_writes:write(csv({primary_queue_write_sequence, pass_name,
			frame_now, emulator_frame, cycles - frame_cycle_start, cycles,
			hx(pc, 4), bank(pc), hx(old_value, 2),
			hx(type(new_value) == "number" and new_value or b(0x0498), 2),
			hx(reg("a"), 2), hx(reg("x"), 2), hx(reg("y"), 2), hx(reg("p"), 2), hx(reg("s"), 2),
			hx(b(0x0000), 2), bytes_hex(0x0015, 3), bytes_hex(0x0516, 4),
			hx(b(0x003A), 2), hx(actor, 4), hx(b(actor), 2),
			bytes_hex(0x053A, 4), bytes_hex(0x0498, 4)}) .. "\n")
		primary_queue_write_sequence = primary_queue_write_sequence + 1
	end)
	for address, spec in pairs(target_pcs) do
		local aa, name, expected = address, spec[1], spec[2]
		memory.registerexec(aa, function()
			if (expected >= 0 and bank(reg("pc")) ~= expected) or not capture_route_event() then return end
			if name == "D716_action_return" then
				log_event(aa, name)
				post_wait_path = "after_d716"
			elseif name == "D568_post_wait_return" and post_wait_path == "after_d716" then
				log_event(aa, name)
				post_wait_path = "after_d568"
			elseif name == "CE2D_post_wait_mapper" and post_wait_path == "after_d568" then
				log_event(aa, name)
				post_wait_path = "after_post_wait_ce2d"
			elseif name == "8047_field_bank_entry" and post_wait_path == "after_post_wait_ce2d" then
				log_event(aa, name)
				post_wait_path = "after_8047"
			elseif name == "E07E_field_update_caller" and post_wait_path == "after_8047" then
				log_event(aa, name)
				post_wait_path = "after_e07e"
			elseif name == "E709_field_update" and post_wait_path == "after_e07e" then
				log_event(aa, name)
				post_wait_path = "complete"
			elseif name == "A103_field_worker" and post_wait_path == "complete" and not a103_logged then
				log_event(aa, name)
				a103_logged = true
			elseif name ~= "D716_action_return" and name ~= "D568_post_wait_return"
					and name ~= "CE2D_post_wait_mapper" and name ~= "8047_field_bank_entry"
					and name ~= "E07E_field_update_caller" and name ~= "E709_field_update"
					and name ~= "A103_field_worker" then
				log_event(aa, name)
			end
		end)
	end
end
local function detach()
	pcall(memory.registerwrite, 0x0005, 1, nil)
	pcall(memory.registerwrite, 0x0518, 1, nil)
	pcall(memory.registerwrite, 0x0519, 1, nil)
	pcall(memory.registerwrite, 0x0523, 1, nil)
	pcall(memory.registerwrite, 0x0498, 1, nil)
	pcall(memory.registerexec, 0xEC94, nil)
	for _, address in ipairs({0x0063, 0x0064, 0x062D}) do pcall(memory.registerwrite, address, 1, nil) end
	for address in pairs(target_pcs) do pcall(memory.registerexec, address, nil) end
end

local startup = "nil"
pcall(function() startup = tostring(movie.mode()); if movie.mode() ~= nil then pcall(movie.stop) end end)
if type(movie.active) == "function" then local active=false; pcall(function() active=movie.active() end); if active then pcall(movie.stop) end end
assert(tostring(movie.mode()) == "nil", "could not stop startup movie")
memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value) mmc3[(mmc3_select % 8) + 1] = value or 0 end)
assert(pcall(emu.poweron), "emu.poweron failed")
if debugger.resetcyclescount then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode, "turbo")
metadata:write("startup_movie_mode=" .. startup .. "\n")
metadata:flush()

progress("warmup_before:0")
for frame=0,CHECKPOINT_FRAME do
	joypad.set(1, inputs[frame])
	if frame < 3 then progress("warmup_advance_before:" .. frame) end
	emu.frameadvance()
	if frame < 3 or frame % 100 == 0 or frame == CHECKPOINT_FRAME then progress("warmup:" .. frame) end
end
local checkpoint = savestate.create()
assert(checkpoint, "savestate.create failed")
local checkpoint_sig = signature()
write_binary("checkpoint_ram.bin", checkpoint_sig.ram)
write_binary("checkpoint_ppu.bin", checkpoint_sig.ppu)
assert(pcall(savestate.save, checkpoint), "savestate.save failed")
assert(pcall(savestate.persist, checkpoint), "savestate.persist failed")
metadata:write("checkpoint_frame=" .. checkpoint_sig.frame .. "\ncheckpoint_cycles=" .. checkpoint_sig.cycles
	.. "\ncheckpoint_ram_hash=" .. hash_bytes(checkpoint_sig.ram)
	.. "\ncheckpoint_ppu_ram_hash=" .. hash_bytes(checkpoint_sig.ppu)
	.. "\ncheckpoint_mmc3_select=" .. string.format("%02X",checkpoint_sig.select)
	.. "\ncheckpoint_mmc3_registers=" .. mmc3_fields()
	.. "\ncheckpoint_prg_map=" .. string.format("%02X/%02X/%02X/%02X",checkpoint_sig.prg[1],checkpoint_sig.prg[2],checkpoint_sig.prg[3],checkpoint_sig.prg[4])
	.. "\ncheckpoint_mapped_prg_bytes=" .. string.format("%02X/%02X/%02X/%02X",checkpoint_sig.mapped[1],checkpoint_sig.mapped[2],checkpoint_sig.mapped[3],checkpoint_sig.mapped[4])
	.. "\ncheckpoint_cpu_registers=" .. string.format("PC=%04X A=%02X X=%02X Y=%02X P=%02X SP=%02X",
		checkpoint_sig.cpu.pc, checkpoint_sig.cpu.a, checkpoint_sig.cpu.x,
		checkpoint_sig.cpu.y, checkpoint_sig.cpu.p, checkpoint_sig.cpu.sp)
	.. "\ncheckpoint_ram_file=checkpoint_ram.bin\ncheckpoint_ppu_file=checkpoint_ppu.bin"
	.. "\ncheckpoint_signature=frame/cycle, CPU registers, RAM2KiB, PPU16KiB, MMC3 registers and mapped PRG bytes\n")
metadata:flush()

local endpoint_screenshot_hashes = {}
for pass=1,2 do
	progress("before_restore:" .. pass)
	assert(pcall(savestate.load, checkpoint), "savestate.load failed")
	mmc3_select = checkpoint_sig.select
	for i=1,8 do mmc3[i] = checkpoint_sig.banks[i] end
	verify(checkpoint_sig, "pass " .. pass)
	pass_name, sequence = tostring(pass), 0
	post_wait_path, a103_logged = "not_started", false
	events = output(pass == 1 and "events.csv" or "events_repeat.csv", event_header)
	primary_queue_writes = output(pass == 1 and "primary_queue_writes.csv" or "primary_queue_writes_repeat.csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc_after_write,prg_bank,old_value,new_value,a,x,y,p,sp,active_task_slot,task_slots_0015_0017,scenario_0516_0519,stream_index_003a,actor_record,actor_flag,worker_053a_053d,queue_0498_049b")
	primary_queue_write_sequence = 0
	wait_flag_writes = output(pass == 1 and "waitflag_062d_writes.csv" or "waitflag_062d_writes_repeat.csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc_after_write,prg_bank,previous_value,write_size,new_value,a,x,y,p,sp,active_task_slot,task_slots_0001_0003,slot05_record,slot09_record,slot11_record,slot15_record,nmi_latch_001b,ppu_queue_0515_0519,scenario_0516_0519,map_worker_05c7_05ce,field_wait_0628_062d")
	wait_flag_write_sequence = 0
	task05_record_writes = output(pass == 1 and "task05_record_writes.csv" or "task05_record_writes_repeat.csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc_after_write,prg_bank,previous_value,write_size,new_value,active_task_slot,task01_record,task05_record,task09_record,task11_record,task15_record,scenario_0516_0519,a,x,y,sp")
	task05_record_write_sequence = 0
	scenario0518_writes = output(pass == 1 and "scenario0518_writes.csv" or "scenario0518_writes_repeat.csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc_after_write,prg_bank,previous_value,write_size,new_value,active_task_slot,task01_record,task05_record,task09_record,task11_record,task15_record,scenario_0516_0519,a,x,y,sp")
	scenario0518_write_sequence = 0
	scenario0519_writes = output(pass == 1 and "scenario0519_writes.csv" or "scenario0519_writes_repeat.csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc_after_write,prg_bank,previous_value,write_size,new_value,active_task_slot,task01_record,task05_record,task09_record,task11_record,task15_record,scenario_0516_0519,a,x,y,sp")
	scenario0519_write_sequence = 0
	scenario0523_writes = output(pass == 1 and "scenario0523_writes.csv" or "scenario0523_writes_repeat.csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc_after_write,prg_bank,previous_value,write_size,new_value,active_task_slot,task01_record,task05_record,task09_record,task11_record,task15_record,scenario_0516_0519,ram_0523_052A,a,x,y,sp")
	scenario0523_write_sequence = 0
	scenario_ec94_reads = output(pass == 1 and "scenario_ec94_reads.csv" or "scenario_ec94_reads_repeat.csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,pc,prg_bank,active_task_slot,task01_record,task05_record,task09_record,task11_record,task15_record,scenario_0516_0519,ram_0523_052A,a,x,y,sp")
	scenario_ec94_read_sequence = 0
	scenario_timeline = output(pass == 1 and "scenario_timeline.csv" or "scenario_timeline_repeat.csv",
		"pass,source_frame,emulator_frame,cycle_from_frame_end,pc,prg_bank,active_task_slot,scenario_0516_0519,task01_record,task05_record,task09_record,task11_record,task15_record,ppu_queue_0515_0519,queue_0498_049b")
	animation_pointer_writes = output(pass == 1 and "animation_pointer_writes.csv" or "animation_pointer_writes_repeat.csv",
		"sequence,pass,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,address,pc_after_write,prg_bank,old_value,new_value,a,x,y,p,sp,active_task_slot,stream_index_003a,scenario_0516_0519,animation_counters_05e3_05ea,wait_counters_05f3_05f5,stream_pointer_005f_0060,animation_pointer_0063_0064,stack_c7_ca")
	animation_pointer_write_sequence = 0
	attach()
	for frame=FIRST_REPLAY_FRAME,LAST_FRAME do
		frame_now = frame
		joypad.set(1, inputs[frame])
		frame_cycle_start = debugger.getcyclescount()
		emu.frameadvance()
		if frame == LAST_FRAME then
			local screen_ok, screen_bytes = pcall(gui.gdscreenshot)
			assert(screen_ok and type(screen_bytes) == "string" and #screen_bytes > 0,
				"FCEUX endpoint screenshot capture failed: " .. tostring(screen_bytes))
			local screen_name = string.format("frame_%06d_pass%d.gd", frame, pass)
			write_binary(screen_name, screen_bytes)
			endpoint_screenshot_hashes[pass] = hash_bytes(screen_bytes)
			metadata:write(string.format("pass_%d_endpoint_screenshot=%s\npass_%d_endpoint_screenshot_bytes=%d\npass_%d_endpoint_screenshot_sha256=%s\n",
				pass, screen_name, pass, #screen_bytes, pass, endpoint_screenshot_hashes[pass]))
		end
		if frame >= 9043 and frame <= 9261 then
			local cycles = debugger.getcyclescount()
			local pc = reg("pc")
			scenario_timeline:write(csv({pass_name, frame, emu.framecount(),
				cycles - frame_cycle_start, hx(pc, 4), bank(pc), hx(b(0x0000), 2),
				bytes_hex(0x0516, 4), bytes_hex(0x0001, 4), bytes_hex(0x0005, 4),
				bytes_hex(0x0009, 4), bytes_hex(0x0011, 4), bytes_hex(0x0015, 4),
				bytes_hex(0x0515, 5), bytes_hex(0x0498, 4)}) .. "\n")
		end
		if frame % 10 == 0 or frame == LAST_FRAME then
			events:flush()
			progress(pass .. ":" .. frame)
		end
	end
	detach(); events:close(); primary_queue_writes:close(); primary_queue_writes = nil
	animation_pointer_writes:close(); animation_pointer_writes = nil
	wait_flag_writes:close(); wait_flag_writes = nil
	task05_record_writes:close(); task05_record_writes = nil
	scenario0518_writes:close(); scenario0518_writes = nil
	scenario0519_writes:close(); scenario0519_writes = nil
	scenario0523_writes:close(); scenario0523_writes = nil
	scenario_ec94_reads:close(); scenario_ec94_reads = nil
	scenario_timeline:close(); scenario_timeline = nil
	metadata:write("pass_" .. pass .. "_events=" .. sequence .. "\n")
	metadata:flush()
end

assert(endpoint_screenshot_hashes[1] ~= nil and endpoint_screenshot_hashes[1] == endpoint_screenshot_hashes[2],
	"the same-input frame-9600 FCEUX screenshots differ across checkpoint replays")
metadata:write("endpoint_screenshots_identical=true\ncomplete=true\nreplays=2, same anonymous frame-9042 checkpoint\n")
metadata:close()
pcall(memory.registerwrite, 0x8000, 1, nil)
pcall(memory.registerwrite, 0x8001, 1, nil)
pcall(memory.registerwrite, 0x0005, 1, nil)
pcall(memory.registerwrite, 0x0518, 1, nil)
pcall(memory.registerwrite, 0x0519, 1, nil)
pcall(memory.registerwrite, 0x0523, 1, nil)
pcall(memory.registerwrite, 0x0498, 1, nil)
pcall(memory.registerwrite, 0x062D, 1, nil)
pcall(memory.registerexec, 0xEC94, nil)
os.exit()

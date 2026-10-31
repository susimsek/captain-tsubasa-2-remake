-- Muted two-pass trace of the live $004A/$004B source around ID-1 Select cleanup.
-- Replays the captured prefix once, checkpoints frame 4692 in memory, then
-- repeats frames 4693-9042 from that signature-checked state.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_SELECT_CLEANUP_TRACE_OUTPUT_DIR"), "missing output directory")
local CHECKPOINT_FRAME, FIRST_FRAME, LAST_FRAME = 4692, 4693, 9042
local CALLER_HOOK_FIRST_FRAME, CALLER_HOOK_LAST_FRAME = 7257, 9042
local CALLER_HOOKS = {
	[0x80DF]="$80DF", [0x80E1]="$80E1", [0x80E6]="$80E6", [0x80E9]="$80E9", [0x80EB]="$80EB", [0x80EE]="$80EE",
	[0x82B5]="$82B5", [0x82C6]="$82C6", [0x82DA]="$82DA", [0x82DC]="$82DC", [0x82DF]="$82DF",
	[0x82E2]="$82E2", [0x82E4]="$82E4", [0x82E6]="$82E6", [0x82E8]="$82E8", [0x82EA]="$82EA", [0x82EC]="$82EC",
	[0x80F1]="$80F1", [0x80F3]="$80F3", [0x80F5]="$80F5", [0x80F7]="$80F7", [0x80FA]="$80FA", [0x80FD]="$80FD",
	[0x80FF]="$80FF", [0x8101]="$8101", [0x8103]="$8103", [0x8105]="$8105", [0x8107]="$8107", [0x810A]="$810A",
	[0x810C]="$810C", [0x810F]="$810F", [0x8112]="$8112", [0x8114]="$8114", [0x8117]="$8117", [0x8119]="$8119",
	[0x811C]="$811C", [0x811F]="$811F", [0x8122]="$8122", [0x8124]="$8124", [0x8126]="$8126", [0x8128]="$8128",
	[0x812A]="$812A", [0x812C]="$812C", [0x812F]="$812F", [0x8131]="$8131", [0x8134]="$8134", [0x8137]="$8137",
	[0x813A]="$813A", [0x813D]="$813D", [0x813F]="$813F", [0x8142]="$8142", [0x8145]="$8145", [0x8147]="$8147",
	[0x814F]="$814F", [0x8152]="$8152", [0x8155]="$8155", [0x8157]="$8157", [0x815A]="$815A",
	[0xC4B9]="$C4B9", [0xC4C7]="$C4C7", [0xA20F]="$A20F", [0xA86E]="$A86E", [0xA8B6]="$A8B6",
	[0xA20C]="$A20C", [0xA138]="$A138", [0xA14A]="$A14A", [0xA1E4]="$A1E4", [0xA1EB]="$A1EB",
	[0xA87E]="$A87E", [0xA881]="$A881", [0xA8A3]="$A8A3", [0xA8B7]="$A8B7", [0xA8BB]="$A8BB", [0xA8CD]="$A8CD",
	[0x80FD]="$80FD", [0x8920]="$8920", [0x9DEE]="$9DEE", [0x8925]="$8925", [0x8938]="$8938", [0x893B]="$893B",
	[0xA006]="$A006", [0xC572]="$C572", [0xA009]="$A009", [0xA14A]="$A14A",
	[0xC421]="$C421", [0xC449]="$C449", [0xC472]="$C472", [0x8000]="$8000", [0x8061]="$8061",
	[0xA4EB]="$A4EB", [0xA500]="$A500", [0xA503]="$A503", [0xA50B]="$A50B",
	[0xA526]="$A526", [0xA539]="$A539", [0xA56C]="$A56C", [0xA571]="$A571",
	[0xA57D]="$A57D", [0xA580]="$A580", [0xA58B]="$A58B", [0xA59A]="$A59A",
	[0xA5A3]="$A5A3", [0xA5A9]="$A5A9", [0xA5B1]="$A5B1", [0xA5BD]="$A5BD",
	[0xA5C6]="$A5C6", [0xA5E0]="$A5E0", [0xA5E8]="$A5E8", [0xA5F1]="$A5F1",
	[0xA5FC]="$A5FC", [0xA603]="$A603", [0xA60A]="$A60A", [0xA610]="$A610",
	[0x8122]="$8122", [0x8124]="$8124", [0x812C]="$812C", [0x812F]="$812F",
	[0x813F]="$813F", [0x8142]="$8142", [0x8145]="$8145", [0x814F]="$814F",
	[0x8157]="$8157", [0x815A]="$815A", [0x8163]="$8163", [0xA009]="$A009",
	[0xA203]="$A203", [0xA2AF]="$A2AF", [0xAA06]="$AA06", [0xC557]="$C557",
	[0xC6BE]="$C6BE", [0xDB62]="$DB62", [0xDB9D]="$DB9D",
	[0xB0C0]="$B0C0", [0xB0C6]="$B0C6", [0xB0F7]="$B0F7", [0xB1BA]="$B1BA",
	[0x97B6]="$97B6", [0x9889]="$9889", [0xC572]="$C572",
}

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
				result[frame] = {up=values[i]=="1", down=values[i+1]=="1", left=values[i+2]=="1",
					right=values[i+3]=="1", A=values[i+4]=="1", B=values[i+5]=="1",
					start=values[i+6]=="1", select=values[i+7]=="1"}
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
local function output_binary(name, bytes)
	local file = assert(io.open(OUT .. "/" .. name, "wb"))
	file:write(bytes)
	file:close()
end
local function progress(value)
	local file = assert(io.open(OUT .. "/progress.txt", "w"))
	file:write(value .. "\n"); file:close()
end
local function b(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return type(value) == "number" and value or 0
end
local function packed_hex(bytes)
	local values = {}
	for i = 1, #bytes do values[i] = string.format("%02X", bytes:byte(i)) end
	return table.concat(values)
end
local function ram_hex(address, count)
	return packed_hex(memory.readbyterange(address, count))
end
local function ppu_hex(address, count)
	return packed_hex(ppu.readbyterange(address, count))
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
	for i, value in ipairs(fields) do values[i] = tostring(value == nil and "" or value):gsub(",", ";") end
	return table.concat(values, ",")
end

local mmc3_select, mmc3 = 0, {0,2,4,5,6,7,0,1}
local function prg_map()
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(mmc3_select / 64) % 2 == 0 then return r6, r7, 30, 31 end
	return 30, r7, r6, 31
end
local function mapped_bank(pc)
	if pc >= 0xE000 then return 31 elseif pc >= 0xC000 then return 30 end
	local r0, r1 = prg_map()
	if pc >= 0xA000 then return r1 elseif pc >= 0x8000 then return r0 end
	return -1
end
local mapper_shadow_header = "phase,pass,sequence,source_frame,emulator_frame,cycle,pc_callback,bank,old_value,new_value,a,x,y,p,sp,ram_0022,ram_0023,ram_0024,ram_0025,mapper_select,mapper_r6,mapper_r7,code_context"
local sound_queue_header = "sequence,pass,source_frame,emulator_frame,cycle,pc,bank,address,old_value,new_value,a,x,y,p,sp,ram_0700,ram_0701,ram_0702,ram_0703,ram_0704,ram_0705,ram_07fc,mapper_select,mapper_r6,mapper_r7"
local stream_buffer_header = "sequence,phase,pass,source_frame,emulator_frame,cycle,pc,bank,address,old_value,new_value,a,x,y,p,sp,ram_05b0,ram_05b1,ram_05b2,ram_05b3,ram_05b4,ram_05b5,ram_05b6,ram_05b7,ram_05b8,ram_05b9,ram_05ba,ram_05bb,ram_05bc,ram_05bd,ram_05be,ram_05bf,mapper_select,mapper_r6,mapper_r7"
local mapper_shadow_output = nil
local mapper_trace_phase, mapper_trace_pass, mapper_trace_frame = "startup", 0, -1
local mapper_shadow_sequence, mapper_shadow_write_count = 0, 0
local function attach_mapper_shadow_writer()
	memory.registerwrite(0x0022, 1, function(_, old_value, new_value)
		if mapper_shadow_output == nil then return end
		mapper_shadow_sequence = mapper_shadow_sequence + 1
		mapper_shadow_write_count = mapper_shadow_write_count + 1
		local pc = reg("pc")
		local context = {}
		for offset = -3, 2 do context[#context + 1] = string.format("%02X", b(pc + offset)) end
		local r0, r1 = prg_map()
		mapper_shadow_output:write(csv({mapper_trace_phase,mapper_trace_pass,mapper_shadow_sequence,
			mapper_trace_frame,emu.framecount(),debugger.getcyclescount(),hx(pc),hx(mapped_bank(pc),2),
			hx(old_value,2),hx(type(new_value)=="number" and new_value or b(0x0022),2),
			hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(reg("s"),2),
			hx(b(0x0022),2),hx(b(0x0023),2),hx(b(0x0024),2),hx(b(0x0025),2),
			hx(mmc3_select,2),hx(r0,2),hx(r1,2),table.concat(context," ")}) .. "\n")
	end)
end
local startup_sound_queue_output = nil
local startup_sound_queue_sequence = 0
local function attach_startup_sound_queue_writer(address)
	memory.registerwrite(address, 1, function(_, old_value, new_value)
		if startup_sound_queue_output == nil or mapper_trace_frame > CHECKPOINT_FRAME then return end
		startup_sound_queue_sequence = startup_sound_queue_sequence + 1
		local pc = reg("pc")
		local r0, r1 = prg_map()
		startup_sound_queue_output:write(csv({startup_sound_queue_sequence,"startup",mapper_trace_frame,
			emu.framecount(),debugger.getcyclescount(),hx(pc),hx(mapped_bank(pc),2),hx(address),
			hx(old_value,2),hx(type(new_value)=="number" and new_value or b(address),2),hx(reg("a"),2),
			hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(reg("s"),2),hx(b(0x0700),2),
			hx(b(0x0701),2),hx(b(0x0702),2),hx(b(0x0703),2),hx(b(0x0704),2),hx(b(0x0705),2),
			hx(b(0x07FC),2),hx(mmc3_select,2),hx(r0,2),hx(r1,2)}) .. "\n")
	end)
end
local function attach_stream_buffer_writers(file, sequence, phase, pass)
	for address = 0x05B0, 0x05BF do
		local hook_address = address
		memory.registerwrite(hook_address, 1, function(_, old_value, new_value)
			local frame = mapper_trace_frame
			if phase == "route" and (frame < FIRST_FRAME or frame > LAST_FRAME) then return end
			sequence.value = sequence.value + 1
			local pc = reg("pc")
			local r0, r1 = prg_map()
			local fields = {sequence.value,phase,pass,frame,emu.framecount(),debugger.getcyclescount(),
				hx(pc),hx(mapped_bank(pc),2),hx(hook_address),hx(old_value,2),
				hx(type(new_value)=="number" and new_value or b(hook_address),2),hx(reg("a"),2),
				hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(reg("s"),2)}
			for ram_address = 0x05B0, 0x05BF do fields[#fields + 1] = hx(b(ram_address),2) end
			fields[#fields + 1] = hx(mmc3_select,2); fields[#fields + 1] = hx(r0,2); fields[#fields + 1] = hx(r1,2)
			file:write(csv(fields) .. "\n")
		end)
	end
end
local function signature()
	local r0, r1 = prg_map()
	local banks = {}; for i = 1, 8 do banks[i] = mmc3[i] end
	return {frame=emu.framecount(), cycles=debugger.getcyclescount(),
		ram=memory.readbyterange(0, 0x800), ppu_mem=ppu.readbyterange(0, 0x4000),
		select=mmc3_select, banks=banks, prg={r0,r1,30,31},
		mapped={b(0x8000),b(0xA000),b(0xC000),b(0xE000)}}
end
local function verify(saved, label)
	local current = signature()
	assert(current.frame == saved.frame and current.cycles == saved.cycles, label .. " frame/cycle mismatch")
	assert(current.ram == saved.ram and current.ppu_mem == saved.ppu_mem, label .. " RAM/PPU mismatch")
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
mapper_shadow_output = output("mapper_shadow_writes_startup.csv", mapper_shadow_header)
attach_mapper_shadow_writer()
startup_sound_queue_output = output("sound_queue_writes_startup.csv", sound_queue_header)
for address = 0x0700, 0x0705 do attach_startup_sound_queue_writer(address) end
attach_startup_sound_queue_writer(0x07FC)
local startup_stream_buffer_output = output("stream_buffer_writes_startup.csv", stream_buffer_header)
local startup_stream_buffer_sequence = {value=0}
attach_stream_buffer_writers(startup_stream_buffer_output, startup_stream_buffer_sequence, "startup", 0)
assert(pcall(emu.poweron), "emu.poweron failed")
if debugger.resetcyclescount then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode, "turbo")

progress("warmup_before:0")
for frame = 0, CHECKPOINT_FRAME do
	mapper_trace_frame = frame
	joypad.set(1, inputs[frame]); emu.frameadvance()
	if frame % 250 == 0 or frame == CHECKPOINT_FRAME then progress("warmup:" .. frame) end
end
local checkpoint = assert(savestate.create(), "savestate.create failed")
local checkpoint_sig = signature()
assert(pcall(savestate.save, checkpoint), "savestate.save failed")
assert(pcall(savestate.persist, checkpoint), "savestate.persist failed")
mapper_shadow_output:flush(); mapper_shadow_output:close(); mapper_shadow_output = nil
startup_sound_queue_output:flush(); startup_sound_queue_output:close(); startup_sound_queue_output = nil
for address = 0x0700, 0x0705 do pcall(memory.registerwrite, address, 1, nil) end
pcall(memory.registerwrite, 0x07FC, 1, nil)
startup_stream_buffer_output:flush(); startup_stream_buffer_output:close()
for address = 0x05B0, 0x05BF do pcall(memory.registerwrite, address, 1, nil) end
local metadata = output("metadata.txt")
local rom_hash = "unavailable"; pcall(function() rom_hash = rom.gethash("sha256") or rom_hash end)
metadata:write("rom_sha256=" .. tostring(rom_hash) .. "\nfceux=2.7.0; NTSC; NewPPU; muted\n")
metadata:write("checkpoint_source_frame=" .. CHECKPOINT_FRAME .. "\ncheckpoint_emulator_frame=" .. checkpoint_sig.frame .. "\ncheckpoint_cycles=" .. checkpoint_sig.cycles .. "\n")
metadata:write("checkpoint_sound_queue_bytes=" .. ram_hex(0x0700, 6) .. "\ncheckpoint_saved_bank_07fc=" .. hx(b(0x07FC),2) .. "\n")
metadata:write("checkpoint_signature=frame/cycle, RAM2KiB, PPU16KiB, MMC3 registers and mapped PRG bytes\nstartup_movie_mode=" .. startup .. "\n")
metadata:write("trace_window=" .. FIRST_FRAME .. "-" .. LAST_FRAME .. "; replayed twice from the same anonymous checkpoint\n")
metadata:write("caller_hook_window=" .. CALLER_HOOK_FIRST_FRAME .. "-" .. CALLER_HOOK_LAST_FRAME .. "; selected ROM PCs only\n")
metadata:write("sound_queue_write_window=" .. FIRST_FRAME .. "-" .. LAST_FRAME .. "; six ID slots and saved-bank writes\n")
metadata:flush()

local write_header = "sequence,pass,source_frame,emulator_frame,cycle,pc_callback,bank,address,new_value,a,x,y,p,sp,ram_0000,ram_001e,ram_004d,ram_004e,ram_00e0,mapper_select,mapper_r6,mapper_r7,code_context"
local snapshot_header = "pass,source_frame,emulator_frame,cycle,ram_004a,ram_004b,ram_001e,ram_004d,ram_004e,ram_00e0,ram_062a_0649,ram_05e8_060a,ppu_3f00_3f1f,pc"
local caller_hook_header = "sequence,pass,source_frame,emulator_frame,cycle,pc,name,bank,a,x,y,p,sp,stack_return_low,stack_return_high,ram_001e,ram_0022,ram_0023,ram_0025,ram_0026,ram_0044,ram_0045,ram_004d,ram_004e,ram_0078,ram_007a,ram_007b,ram_00e0,ram_00ec,ram_00ed,dispatch_ptr,dispatch_byte,ram_05b3,ram_05b4,ram_05b5,ram_0700,ram_0701,ram_0702,ram_0703,ram_0704,ram_0705,ram_07fc,mapper_select,mapper_r6,mapper_r7,ppu_scanline,ppu_dot"
local word_wait_header = "sequence,pass,source_frame,emulator_frame,cycle,pc,bank,address,old_value,new_value,a,x,y,p,sp,ram_004d,ram_004e,ram_0078,mapper_select,mapper_r6,mapper_r7"
local write_count = {}
metadata:write("mapper_shadow_startup_writes=" .. mapper_shadow_write_count .. "\n")

for pass = 1, 2 do
	progress("before_restore:" .. pass)
	assert(pcall(savestate.load, checkpoint), "savestate.load failed")
	mmc3_select = checkpoint_sig.select; for i = 1, 8 do mmc3[i] = checkpoint_sig.banks[i] end
	verify(checkpoint_sig, "pass " .. pass)
	mapper_trace_phase, mapper_trace_pass, mapper_trace_frame = "post_checkpoint", pass, FIRST_FRAME - 1
	mapper_shadow_sequence, mapper_shadow_write_count = 0, 0
	mapper_shadow_output = output("mapper_shadow_writes_pass" .. pass .. ".csv", mapper_shadow_header)
	attach_mapper_shadow_writer()
	local writes = output("counter_writes" .. (pass == 1 and "" or "_repeat") .. ".csv", write_header)
	local snapshots = output("frame_snapshots" .. (pass == 1 and "" or "_repeat") .. ".csv", snapshot_header)
	local caller_hooks = output("caller_hooks" .. (pass == 1 and "" or "_repeat") .. ".csv", caller_hook_header)
	local word_wait_writes = output("word_wait_writes" .. (pass == 1 and "" or "_repeat") .. ".csv", word_wait_header)
	local sound_queue_writes = output("sound_queue_writes" .. (pass == 1 and "" or "_repeat") .. ".csv", sound_queue_header)
	local stream_buffer_writes = output("stream_buffer_writes" .. (pass == 1 and "" or "_repeat") .. ".csv", stream_buffer_header)
	local count, seq, frame_now = 0, 0, FIRST_FRAME - 1
	local caller_hook_seq, caller_hook_counts = 0, {}
	local word_wait_seq = 0
	local sound_queue_seq = 0
	local stream_buffer_sequence = {value=0}
	attach_stream_buffer_writers(stream_buffer_writes, stream_buffer_sequence, "route", pass)
	local nmi_snapshot_done = {}
	local selector_return_frame = -1
	local function attach(address)
		memory.registerwrite(address, 1, function(_, _, new_value)
			if frame_now < FIRST_FRAME or frame_now > LAST_FRAME then return end
			seq = seq + 1; count = count + 1
			local pc = reg("pc")
			local context = {}
			for offset = -3, 2 do context[#context + 1] = string.format("%02X", b(pc + offset)) end
			local r0, r1 = prg_map()
			writes:write(csv({seq,pass,frame_now,emu.framecount(),debugger.getcyclescount(),hx(pc),hx(mapped_bank(pc),2),hx(address,2),hx(type(new_value)=="number" and new_value or b(address),2),hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(reg("s"),2),hx(b(0x0000),2),hx(b(0x001e),2),hx(b(0x004d),2),hx(b(0x004e),2),hx(b(0x00e0),2),hx(mmc3_select,2),hx(r0,2),hx(r1,2),table.concat(context," ")}) .. "\n")
		end)
	end
	attach(0x004A); attach(0x004B)
	memory.registerwrite(0x0078, 1, function(_, old_value, new_value)
		if frame_now < CALLER_HOOK_FIRST_FRAME or frame_now > CALLER_HOOK_LAST_FRAME then return end
		word_wait_seq = word_wait_seq + 1
		local pc = reg("pc")
		local r0, r1 = prg_map()
		word_wait_writes:write(csv({word_wait_seq,pass,frame_now,emu.framecount(),debugger.getcyclescount(),hx(pc),hx(mapped_bank(pc),2),hx(0x0078,2),hx(old_value,2),hx(new_value,2),hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(reg("s"),2),hx(b(0x004d),2),hx(b(0x004e),2),hx(b(0x0078),2),hx(mmc3_select,2),hx(r0,2),hx(r1,2)}) .. "\n")
	end)
	local function attach_sound_queue_writer(address)
		memory.registerwrite(address, 1, function(_, old_value, new_value)
			if frame_now < FIRST_FRAME or frame_now > LAST_FRAME then return end
			sound_queue_seq = sound_queue_seq + 1
			local pc = reg("pc")
			local r0, r1 = prg_map()
			sound_queue_writes:write(csv({sound_queue_seq,pass,frame_now,emu.framecount(),debugger.getcyclescount(),hx(pc),hx(mapped_bank(pc),2),hx(address),hx(old_value,2),hx(type(new_value)=="number" and new_value or b(address),2),hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(reg("s"),2),hx(b(0x0700),2),hx(b(0x0701),2),hx(b(0x0702),2),hx(b(0x0703),2),hx(b(0x0704),2),hx(b(0x0705),2),hx(b(0x07FC),2),hx(mmc3_select,2),hx(r0,2),hx(r1,2)}) .. "\n")
		end)
	end
	for address = 0x0700, 0x0705 do attach_sound_queue_writer(address) end
	attach_sound_queue_writer(0x07FC)
	for address, name in pairs(CALLER_HOOKS) do
		local hook_address, hook_name = address, name
		memory.registerexec(hook_address, function()
			if frame_now < CALLER_HOOK_FIRST_FRAME or frame_now > CALLER_HOOK_LAST_FRAME then return end
			local sp = reg("s")
			local nmi_hook = hook_address == 0xC421 or hook_address == 0xC449 or hook_address == 0xC472
			local sound_bank_hook = (hook_address == 0x8000 or hook_address == 0x8061) and mapped_bank(hook_address) == 0x0C
			if not nmi_hook and not sound_bank_hook and (sp < 0 or sp > 0x40) then return end -- isolate the shallow caller stack, but retain NMI/audio state
			if hook_address == 0x893B and b(0x0078) ~= 0 then return end -- retain the ROM wait-loop exit, skip its hot spin
			local count_key = tostring(hook_address) .. ":" .. tostring(frame_now)
			caller_hook_counts[count_key] = (caller_hook_counts[count_key] or 0) + 1
			if caller_hook_counts[count_key] > 32 then return end
			if hook_address == 0x80FD and selector_return_frame < 0 then selector_return_frame = frame_now end
			if frame_now == 7266 and (hook_address == 0xC421 or hook_address == 0xC449) then
				local label = hook_address == 0xC421 and "C421" or "C449"
				if not nmi_snapshot_done[label] then
					nmi_snapshot_done[label] = true
					output_binary("frame_7266_" .. label .. "_ram_pass" .. pass .. ".bin", memory.readbyterange(0, 0x800))
					output_binary("frame_7266_" .. label .. "_ppu_pass" .. pass .. ".bin", ppu.readbyterange(0, 0x4000))
				end
			end
			caller_hook_seq = caller_hook_seq + 1
			local pc = reg("pc")
			local line, dot = -1, -1
			pcall(function() line = ppu.getscanline() end)
			pcall(function() dot = ppu.getdot() end)
			local r0, r1 = prg_map()
			local stack_low = sp >= 0 and b(0x0100 + ((sp + 1) % 0x100)) or 0
			local stack_high = sp >= 0 and b(0x0100 + ((sp + 2) % 0x100)) or 0
			local dispatch_ptr = b(0x00EC) + b(0x00ED) * 0x100
			local dispatch_byte = b(dispatch_ptr + reg("y"))
			caller_hooks:write(csv({caller_hook_seq,pass,frame_now,emu.framecount(),debugger.getcyclescount(),hx(pc),hook_name,hx(mapped_bank(pc),2),hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(sp,2),hx(stack_low,2),hx(stack_high,2),hx(b(0x001e),2),hx(b(0x0022),2),hx(b(0x0023),2),hx(b(0x0025),2),hx(b(0x0026),2),hx(b(0x0044),2),hx(b(0x0045),2),hx(b(0x004d),2),hx(b(0x004e),2),hx(b(0x0078),2),hx(b(0x007a),2),hx(b(0x007b),2),hx(b(0x00e0),2),hx(b(0x00ec),2),hx(b(0x00ed),2),hx(dispatch_ptr),hx(dispatch_byte,2),hx(b(0x05B3),2),hx(b(0x05B4),2),hx(b(0x05B5),2),hx(b(0x0700),2),hx(b(0x0701),2),hx(b(0x0702),2),hx(b(0x0703),2),hx(b(0x0704),2),hx(b(0x0705),2),hx(b(0x07FC),2),hx(mmc3_select,2),hx(r0,2),hx(r1,2),line,dot}) .. "\n")
		end)
	end
	for frame = FIRST_FRAME, LAST_FRAME do
		mapper_trace_frame = frame
		frame_now = frame; joypad.set(1, inputs[frame]); emu.frameadvance()
		if frame == 7258 then
			output_binary("frame_7258_ppu_pass" .. pass .. ".bin", ppu.readbyterange(0, 0x4000))
			output_binary("frame_7258_ram_pass" .. pass .. ".bin", memory.readbyterange(0, 0x800))
		end
		if selector_return_frame == frame then
			output_binary("selector_copy_frame_" .. pass .. ".bin", memory.readbyterange(0x6000, 0x1350))
			output_binary("selector_ram_frame_" .. pass .. ".bin", memory.readbyterange(0, 0x800))
		end
		if frame >= 7238 and frame <= 7260 then
			snapshots:write(csv({pass,frame,emu.framecount(),debugger.getcyclescount(),hx(b(0x004A),2),hx(b(0x004B),2),hx(b(0x001E),2),hx(b(0x004D),2),hx(b(0x004E),2),hx(b(0x00E0),2),ram_hex(0x062A,0x20),ram_hex(0x05E8,0x23),ppu_hex(0x3F00,0x20),hx(reg("pc"))}) .. "\n")
		end
		if frame % 500 == 0 or frame == LAST_FRAME then writes:flush(); snapshots:flush(); caller_hooks:flush(); word_wait_writes:flush(); sound_queue_writes:flush(); stream_buffer_writes:flush(); progress("pass" .. pass .. ":" .. frame) end
	end
	mapper_shadow_output:flush(); mapper_shadow_output:close(); mapper_shadow_output = nil
	pcall(memory.registerwrite, 0x004A, 1, nil); pcall(memory.registerwrite, 0x004B, 1, nil)
	pcall(memory.registerwrite, 0x0078, 1, nil)
	for address = 0x0700, 0x0705 do pcall(memory.registerwrite, address, 1, nil) end
	pcall(memory.registerwrite, 0x07FC, 1, nil)
	for address = 0x05B0, 0x05BF do pcall(memory.registerwrite, address, 1, nil) end
	for address in pairs(CALLER_HOOKS) do pcall(memory.registerexec, address, nil) end
	writes:close(); snapshots:close(); caller_hooks:close(); word_wait_writes:close(); sound_queue_writes:close(); stream_buffer_writes:close()
	write_count[pass] = count
	metadata:write("pass_" .. pass .. "_counter_writes=" .. count .. "\n")
	metadata:write("pass_" .. pass .. "_mapper_shadow_writes=" .. mapper_shadow_write_count .. "\n")
	metadata:flush()
end

metadata:write("complete=true\nreplays=2; checkpoint_signature_verified_after_both_loads=true\n")
metadata:close()
os.exit()

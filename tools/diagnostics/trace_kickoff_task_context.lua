-- Muted, bounded trace of the old scheduler and KICK OFF caller context.
-- One cold-start pass creates an anonymous frame-4692 checkpoint; two route
-- passes replay frames 4693-7266 from that same in-session state.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OUT = assert(os.getenv("CT2_TASK_CONTEXT_TRACE_OUTPUT_DIR"), "missing output directory")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local CHECKPOINT_FRAME, FIRST_FRAME, LAST_FRAME = 4692, 4693, 7266
local HOOKS = {
	[0x80E6]="$80E6", [0x80EE]="$80EE", [0x80F1]="$80F1", [0x80FA]="$80FA",
	[0x82B5]="$82B5", [0x82E2]="$82E2", [0x82EC]="$82EC",
	[0x8494]="$8494", [0x84C6]="$84C6", [0x84E7]="$84E7",
	[0xC50F]="$C50F", [0xC512]="$C512", [0xC515]="$C515",
	[0xCA22]="$CA22", [0xCA97]="$CA97", [0xCAE7]="$CAE7", [0xCB0F]="$CB0F",
	[0x9EED]="$9EED", [0x9F04]="$9F04", [0x9F0C]="$9F0C",
	[0x9F52]="$9F52", [0x9F69]="$9F69", [0x9FA8]="$9FA8",
	[0xA20F]="$A20F", [0xA15B]="$A15B",
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

local function csv(values)
	local fields = {}
	for i, value in ipairs(values) do fields[i] = tostring(value == nil and "" or value):gsub(",", ";") end
	return table.concat(fields, ",")
end
local function b(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return type(value) == "number" and value or 0
end
local function hx(value, digits)
	if type(value) ~= "number" or value < 0 then return "" end
	return string.format(digits == 2 and "$%02X" or "$%04X", value)
end
local function packed_hex(bytes)
	local values = {}
	for i = 1, #bytes do values[i] = string.format("%02X", bytes:byte(i)) end
	return table.concat(values)
end
local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return type(value) == "number" and value or -1
end

local mmc3_select, mmc3 = 0, {0,2,4,5,6,7,0,1}
local function prg_map()
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(mmc3_select / 64) % 2 == 0 then return r6, r7, 30, 31 end
	return 30, r7, r6, 31
end
local function mapped_bank(pc)
	if pc >= 0xE000 then return 31 elseif pc >= 0xC000 then return 30 end
	local r0, r1, r2, r3 = prg_map()
	if pc < 0xA000 then return r0 elseif pc < 0xC000 then return r1
	elseif pc < 0xE000 then return r2 else return r3 end
end
local function signature()
	local banks = {}; for i = 1, 8 do banks[i] = mmc3[i] end
	local r0, r1, r2, r3 = prg_map()
	return {frame=emu.framecount(), cycles=debugger.getcyclescount(), ram=memory.readbyterange(0,0x800),
		ppu_mem=ppu.readbyterange(0,0x4000), select=mmc3_select, banks=banks, map={r0,r1,r2,r3},
		mapped={b(0x8000),b(0xA000),b(0xC000),b(0xE000)},
		cpu={reg("pc"),reg("a"),reg("x"),reg("y"),reg("p"),reg("s")}}
end
local function verify(saved, label)
	local now = signature()
	assert(now.frame == saved.frame and now.cycles == saved.cycles, label .. " frame/cycle mismatch")
	assert(now.ram == saved.ram and now.ppu_mem == saved.ppu_mem, label .. " RAM/PPU mismatch")
	assert(now.select == saved.select, label .. " MMC3 selector mismatch")
	for i = 1, 8 do assert(now.banks[i] == saved.banks[i], label .. " MMC3 bank mismatch") end
	for i = 1, 4 do assert(now.map[i] == saved.map[i] and now.mapped[i] == saved.mapped[i], label .. " PRG mapping mismatch") end
	for i = 1, 6 do assert(now.cpu[i] == saved.cpu[i], label .. " CPU register mismatch") end
end

local inputs = read_inputs(OPENING_INPUT, false)
for frame, value in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = value end
for frame = 0, LAST_FRAME do assert(inputs[frame], "missing source input frame " .. frame) end

local startup_create_file = assert(io.open(OUT .. "/startup_old_task_create_hooks.csv", "w"))
startup_create_file:write("sequence,source_frame,cycle,a,x,y,p,sp,stack_next_8,ram_0000_001f\n")
local startup_create_sequence, warmup_frame = 0, 0
memory.registerexec(0x9F69, function()
	startup_create_sequence = startup_create_sequence + 1
	local sp, stack = reg("s"), {}
	for index = 1, 8 do stack[index] = string.format("%02X", b(0x0100 + ((sp + index) % 0x100))) end
	startup_create_file:write(csv({startup_create_sequence, warmup_frame,
		debugger.getcyclescount(), hx(reg("a"),2), hx(reg("x"),2), hx(reg("y"),2),
		hx(reg("p"),2), hx(sp,2), table.concat(stack),
		packed_hex(memory.readbyterange(0,0x20))}) .. "\n")
end)

local startup = "nil"
pcall(function() startup = tostring(movie.mode()); if movie.mode() ~= nil then pcall(movie.stop) end end)
if type(movie.active) == "function" then local active=false; pcall(function() active=movie.active() end); if active then pcall(movie.stop) end end
assert(tostring(movie.mode()) == "nil", "could not stop startup movie")
memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value) mmc3[(mmc3_select % 8) + 1] = value or 0 end)
assert(pcall(emu.poweron), "emu.poweron failed")
if debugger.resetcyclescount then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode, "turbo")

local progress = assert(io.open(OUT .. "/progress.txt", "w"))
local function report_progress(value)
	progress:close(); progress = assert(io.open(OUT .. "/progress.txt", "w")); progress:write(value .. "\n"); progress:flush()
end
report_progress("warmup:0")
for frame = 0, CHECKPOINT_FRAME do
	warmup_frame = frame
	joypad.set(1, inputs[frame]); emu.frameadvance()
	if frame % 500 == 0 or frame == CHECKPOINT_FRAME then report_progress("warmup:" .. frame) end
end
memory.registerexec(0x9F69, nil)
startup_create_file:close()
local checkpoint = assert(savestate.create(), "savestate.create failed")
local checkpoint_sig = signature()
assert(pcall(savestate.save, checkpoint), "savestate.save failed")
assert(pcall(savestate.persist, checkpoint), "savestate.persist failed")

local metadata = assert(io.open(OUT .. "/metadata.txt", "w"))
local rom_hash = "unavailable"; pcall(function() rom_hash = rom.gethash("sha256") or rom_hash end)
metadata:write("rom_sha256=" .. tostring(rom_hash) .. "\nfceux=2.7.0; NTSC; NewPPU; muted\n")
metadata:write("checkpoint_source_frame=" .. CHECKPOINT_FRAME .. "\ncheckpoint_emulator_frame=" .. checkpoint_sig.frame .. "\ncheckpoint_cycles=" .. checkpoint_sig.cycles .. "\n")
metadata:write("checkpoint_signature=frame/cycle,CPU registers,RAM2KiB,PPU16KiB,MMC3 registers and mapped PRG bytes\n")
metadata:write("trace_window=" .. FIRST_FRAME .. "-" .. LAST_FRAME .. "; two passes from one anonymous in-session checkpoint\n")
metadata:write("task_context_hooks=selected title caller,legacy scheduler,task creation and yield PCs; observations only\n")
metadata:write("startup_old_task_create_events=" .. startup_create_sequence .. "; frames 0-" .. CHECKPOINT_FRAME .. " at $9F69; diagnostics only\n")

local header = "sequence,pass,source_frame,emulator_frame,cycle,pc,name,bank,a,x,y,p,sp,stack_next_8,ram_0000_001f,ram_004d,ram_004e,ram_004a,ram_004b,ram_0078,ram_0079,ram_00ec,ram_00ed,ram_00e0,ram_0700_0705,ram_07fc,mapper_select,mapper_r6,mapper_r7"
local pass_counts = {}
for pass = 1, 2 do
	report_progress("before_restore:" .. pass)
	assert(pcall(savestate.load, checkpoint), "savestate.load failed")
	mmc3_select = checkpoint_sig.select; for i = 1, 8 do mmc3[i] = checkpoint_sig.banks[i] end
	verify(checkpoint_sig, "pass " .. pass)
	local suffix = pass == 1 and "" or "_repeat"
	local file = assert(io.open(OUT .. "/task_context_hooks" .. suffix .. ".csv", "w"))
	file:write(header .. "\n")
	local sequence, frame_now, counts = 0, FIRST_FRAME - 1, {}
	for address, name in pairs(HOOKS) do
		local hook_address, hook_name = address, name
		memory.registerexec(hook_address, function()
			if frame_now < FIRST_FRAME or frame_now > LAST_FRAME then return end
			local count_key = tostring(hook_address) .. ":" .. tostring(frame_now)
			counts[count_key] = (counts[count_key] or 0) + 1
			local limit = hook_address == 0x9F04 and 1 or 8
			if counts[count_key] > limit then return end
			sequence = sequence + 1
			local pc, sp = reg("pc"), reg("s")
			local stack = {}
			for index = 1, 8 do stack[index] = string.format("%02X", b(0x0100 + ((sp + index) % 0x100))) end
			local r0, r1 = prg_map()
			file:write(csv({sequence,pass,frame_now,emu.framecount(),debugger.getcyclescount(),hx(pc),hook_name,
				hx(mapped_bank(pc),2),hx(reg("a"),2),hx(reg("x"),2),hx(reg("y"),2),hx(reg("p"),2),hx(sp,2),
				table.concat(stack),packed_hex(memory.readbyterange(0,0x20)),hx(b(0x004d),2),hx(b(0x004e),2),
				hx(b(0x004a),2),hx(b(0x004b),2),hx(b(0x0078),2),hx(b(0x0079),2),hx(b(0x00ec),2),
				hx(b(0x00ed),2),hx(b(0x00e0),2),packed_hex(memory.readbyterange(0x0700,6)),hx(b(0x07FC),2),
				hx(mmc3_select,2),hx(r0,2),hx(r1,2)}) .. "\n")
		end)
	end
	for frame = FIRST_FRAME, LAST_FRAME do
		frame_now = frame; joypad.set(1, inputs[frame]); emu.frameadvance()
		if frame % 500 == 0 or frame == LAST_FRAME then file:flush(); report_progress("pass" .. pass .. ":" .. frame) end
	end
	for address in pairs(HOOKS) do pcall(memory.registerexec, address, nil) end
	file:close(); pass_counts[pass] = sequence
	metadata:write("pass_" .. pass .. "_hook_events=" .. sequence .. "\n")
	metadata:flush()
end
metadata:write("complete=true\nreplays=2; checkpoint_signature_verified_after_both_loads=true\n")
metadata:close(); progress:close()
os.exit()

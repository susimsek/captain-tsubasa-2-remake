-- Muted source-bus trace for the first-command field transition.
-- Run only via run_first_command_ppu_bus_trace.py. Outputs are diagnostic.

local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"), "missing project root")
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local OUT = assert(os.getenv("CT2_PPU_BUS_TRACE_OUTPUT_DIR"), "missing output directory")
local FIRST_TRACE_FRAME, LAST_TRACE_FRAME = 8400, 8953
local CHECKPOINT_FRAME = FIRST_TRACE_FRAME - 1
os.execute("mkdir -p " .. string.format("%q", OUT))

local function read_inputs(path, route_format)
	local result = {}
	local file = assert(io.open(path, "r"), "missing input file " .. path)
	local first = true
	for line in file:lines() do
		line = line:gsub("\r$", "")
		if first then
			first = false
		else
			local values = {}
			for value in (line .. ","):gmatch("(.-),") do values[#values + 1] = value end
			local frame = tonumber(values[1])
			if frame then
				local offset = route_format and 3 or 2
				result[frame] = {
					up=values[offset] == "1", down=values[offset + 1] == "1",
					left=values[offset + 2] == "1", right=values[offset + 3] == "1",
					A=values[offset + 4] == "1", B=values[offset + 5] == "1",
					start=values[offset + 6] == "1", select=values[offset + 7] == "1",
				}
			end
		end
	end
	file:close()
	return result
end

local inputs = read_inputs(OPENING_INPUT, false)
for frame, value in pairs(read_inputs(ROUTE_INPUT, true)) do inputs[frame] = value end
for frame = 0, LAST_TRACE_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local function output(name, header)
	local file = assert(io.open(OUT .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end

local function byte(address)
	local value = 0
	local ok = pcall(function() value = memory.readbyte(address) end)
	if not ok or type(value) ~= "number" then return 0 end
	return value
end

local function word(address) return byte(address) + byte(address + 1) * 256 end

local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return type(value) == "number" and value or -1
end

local function cycles()
	local value = -1
	pcall(function() value = debugger.getcyclescount() end)
	return type(value) == "number" and value or -1
end

local function ppu_position()
	local line, dot = -1, -1
	pcall(function() line = ppu.getscanline() end)
	pcall(function() dot = ppu.getdot() end)
	return type(line) == "number" and line or -1, type(dot) == "number" and dot or -1
end

local function hx(value, width)
	if type(value) ~= "number" or value < 0 then return "" end
	return string.format(width == 2 and "$%02X" or "$%04X", value)
end

-- FCEUX 2.7.0 embeds LuaJIT's Lua 5.1 syntax; use arithmetic bit helpers
-- rather than Lua 5.3's native &, |, and shift operators.
local function band(left, right)
	local result, place = 0, 1
	left, right = math.floor(left), math.floor(right)
	while left > 0 or right > 0 do
		if (left % 2) == 1 and (right % 2) == 1 then result = result + place end
		left = math.floor(left / 2)
		right = math.floor(right / 2)
		place = place * 2
	end
	return result
end

local function bor(left, right) return left + right - band(left, right) end
local function lshift(value, count) return value * (2 ^ count) end
local function rshift(value, count) return math.floor(value / (2 ^ count)) end

local function csv(values)
	local fields = {}
	for index, value in ipairs(values) do
		fields[index] = tostring(value == nil and "" or value):gsub(",", ";")
	end
	return table.concat(fields, ",")
end

local metadata = output("metadata.txt")
local rom_sha256, rom_md5 = "unavailable through FCEUX Lua", "unavailable through FCEUX Lua"
pcall(function() rom_sha256 = rom.gethash("sha256") or rom_sha256 end)
pcall(function() rom_md5 = rom.gethash("md5") or rom_md5 end)
assert(type(debugger) == "table" and type(debugger.getcyclescount) == "function",
	"FCEUX CPU cycle counter unavailable")
assert(type(memory.registerwrite) == "function", "FCEUX memory write hooks unavailable")
local status_read_available = type(memory.registerread) == "function"
assert(status_read_available, "FCEUX PPUSTATUS read hook unavailable; exact $2005/$2006 toggle model would be incomplete")

metadata:write("purpose=muted ROM-source CPU bus trace for first-command field/map/IRQ investigation\n")
metadata:write("rom_sha256=" .. tostring(rom_sha256) .. "\nrom_md5=" .. tostring(rom_md5) .. "\n")
metadata:write("rom_hash_verification=performed by Python runner before FCEUX launch\n")
metadata:write("source_frames=" .. FIRST_TRACE_FRAME .. "-" .. LAST_TRACE_FRAME .. "\n")
metadata:write("warmup=power-on same-input replay through source frame " .. CHECKPOINT_FRAME .. "; target window replayed twice from one anonymous in-memory state\n")
metadata:write("bus_hooks=CPU writes to $2000/$2001/$2005/$2006/$2007; MMC3 $8000/$8001/$A000/$A001/$C000/$C001/$E000/$E001; reads of $2002 reset the write toggle model\n")
metadata:write("ppu_data_address=modeled from PPUCTRL/SCROLL/ADDR writes and PPUSTATUS read toggle; $2007 current v-address plus increment are logged; no screenshot, audio, PPU dump or runtime input is produced\n")
metadata:write("save_state=anonymous FCEUX Lua state; persisted only until this script exits; no numbered slot\n")
metadata:write("registerread_available=" .. tostring(status_read_available) .. "\n")
metadata:flush()

local current_source_frame = -1
local frame_cycle_start = -1
local mmc3_select = 0
local mmc3 = {0, 2, 4, 5, 6, 7, 0, 1}
local mmc3_mirroring, mmc3_ram_control = -1, -1
local mmc3_irq_latch, mmc3_irq_enable, mmc3_irq_reload_pending = -1, 0, 0

-- Minimal 2C02 CPU-port state model. PPUSTATUS reads reset the shared $2005/$2006 write toggle.
local ppu_model = {v=0, t=0, fine_x=0, w=0, ctrl=0, mask=0, address_known=false}

local function copy_array(values)
	local result = {}
	for index, value in ipairs(values) do result[index] = value end
	return result
end

local function prg_map()
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(mmc3_select / 64) % 2 == 0 then return r6, r7, 30, 31 end
	return 30, r7, r6, 31
end

local function pc_bank(pc)
	if pc >= 0xE000 then return select(4, prg_map()) end
	if pc >= 0xC000 then return select(3, prg_map()) end
	if pc >= 0xA000 then return select(2, prg_map()) end
	if pc >= 0x8000 then return select(1, prg_map()) end
	return -1
end

local function bytes_hex(first, count)
	local values = {}
	for offset = 0, count - 1 do values[#values + 1] = string.format("%02X", byte(first + offset)) end
	return table.concat(values, " ")
end

local function update_ppu_model(address, value)
	value = (value or 0) % 0x100
	if address == 0x2000 then
		ppu_model.ctrl = value
		ppu_model.t = bor(band(ppu_model.t, 0xF3FF), lshift(band(value, 0x03), 10))
	elseif address == 0x2001 then
		ppu_model.mask = value
	elseif address == 0x2005 then
		if ppu_model.w == 0 then
			ppu_model.fine_x = band(value, 0x07)
			ppu_model.t = bor(band(ppu_model.t, 0x7FE0), rshift(value, 3))
			ppu_model.w = 1
		else
			ppu_model.t = bor(band(ppu_model.t, 0x0C1F),
				bor(lshift(band(value, 0xF8), 2), lshift(band(value, 0x07), 12)))
			ppu_model.w = 0
		end
	elseif address == 0x2006 then
		if ppu_model.w == 0 then
			ppu_model.t = bor(band(ppu_model.t, 0x00FF), lshift(band(value, 0x3F), 8))
			ppu_model.w = 1
		else
			ppu_model.t = bor(band(ppu_model.t, 0x7F00), value)
			ppu_model.v = ppu_model.t
			ppu_model.address_known = true
			ppu_model.w = 0
		end
	elseif address == 0x2007 then
		local increment = band(ppu_model.ctrl, 0x04) ~= 0 and 32 or 1
		ppu_model.v = (ppu_model.v + increment) % 0x8000
	end
end

local function ppu_effective_address(raw_address)
	if raw_address == nil or raw_address < 0 then return -1 end
	local address = band(raw_address, 0x3FFF)
	if address >= 0x3000 and address < 0x3F00 then address = address - 0x1000 end
	if address >= 0x3F20 and address < 0x4000 then address = bor(0x3F00, band(address, 0x1F)) end
	return address
end

local bus_header = table.concat({
	"sequence", "pass", "source_frame", "emulator_frame", "cycle_from_frame_start", "cycle_absolute",
	"ppu_scanline", "ppu_dot", "event", "cpu_pc_after_store", "pc_prg_bank", "cpu_address", "value",
	"ppu_address_before", "ppu_effective_address", "ppu_address_after", "ppu_address_known", "ppu_v_after", "ppu_t_after",
	"ppu_fine_x", "ppu_write_toggle", "ppu_ctrl", "ppu_mask", "cpu_a", "cpu_x", "cpu_y", "cpu_p",
	"mmc3_select_before", "mmc3_select_after", "mmc3_r0", "mmc3_r1", "mmc3_r2", "mmc3_r3",
	"mmc3_r4", "mmc3_r5", "mmc3_r6", "mmc3_r7", "mmc3_mirroring", "mmc3_ram_control",
	"mmc3_irq_latch", "mmc3_irq_reload_pending", "mmc3_irq_enabled"
}, ",")

local bus_file, frame_file = nil, nil
local event_sequence, frame_sequence = 0, 0
local active_pass = 0
local irq_names = {
	[0x8000]="MMC3_BANK_SELECT", [0x8001]="MMC3_BANK_DATA",
	[0xA000]="MMC3_MIRRORING", [0xA001]="MMC3_RAM_CONTROL",
	[0xC000]="MMC3_IRQ_LATCH", [0xC001]="MMC3_IRQ_RELOAD",
	[0xE000]="MMC3_IRQ_DISABLE_ACK", [0xE001]="MMC3_IRQ_ENABLE",
}

local function log_bus(event_name, address, value, ppu_address_before, mmc3_select_after)
	if current_source_frame < FIRST_TRACE_FRAME or current_source_frame > LAST_TRACE_FRAME or bus_file == nil then return end
	local absolute = cycles()
	local relative = absolute >= 0 and frame_cycle_start >= 0 and absolute - frame_cycle_start or -1
	local emu_frame = -1
	pcall(function() emu_frame = emu.framecount() end)
	local line, dot = ppu_position()
	local pc = reg("pc")
	local r0, r1, r2, r3 = prg_map()
	local effective_before = ppu_address_before and ppu_effective_address(ppu_address_before) or -1
	local values = {
		event_sequence, active_pass, current_source_frame, emu_frame, relative, absolute, line, dot,
		event_name, hx(pc, 4), pc_bank(pc), hx(address, 4), hx(value or 0, 2),
		address == 0x2007 and hx(ppu_address_before or -1, 4) or "",
		address == 0x2007 and hx(effective_before, 4) or "",
		address == 0x2007 and hx(band(ppu_model.v, 0x3FFF), 4) or "",
		tostring(ppu_model.address_known), hx(ppu_model.v, 4), hx(ppu_model.t, 4), hx(ppu_model.fine_x, 2),
		tostring(ppu_model.w), hx(ppu_model.ctrl, 2), hx(ppu_model.mask, 2),
		hx(reg("a"), 2), hx(reg("x"), 2), hx(reg("y"), 2), hx(reg("p"), 2),
		hx(mmc3_select, 2), hx(mmc3_select_after == nil and mmc3_select or mmc3_select_after, 2),
		hx(r0, 2), hx(r1, 2), hx(r2, 2), hx(r3, 2),
		hx(mmc3[5], 2), hx(mmc3[6], 2), hx(mmc3[7], 2), hx(mmc3[8], 2),
		hx(mmc3_mirroring, 2), hx(mmc3_ram_control, 2), hx(mmc3_irq_latch, 2),
		tostring(mmc3_irq_reload_pending), tostring(mmc3_irq_enable)
	}
	bus_file:write(csv(values) .. "\n")
	event_sequence = event_sequence + 1
end

local ppu_writes = { [0x2000]="PPUCTRL", [0x2001]="PPUMASK", [0x2005]="PPUSCROLL", [0x2006]="PPUADDR", [0x2007]="PPUDATA" }
for address, name in pairs(ppu_writes) do
	local watched, label = address, name
	memory.registerwrite(watched, 1, function(addr, _, value)
		local address_before = -1
		if watched == 0x2007 and ppu_model.address_known then
			address_before = band(ppu_model.v, 0x3FFF)
		end
		update_ppu_model(watched, value)
		log_bus(label, addr, value, address_before)
	end)
end

local status_read_ok = pcall(function()
	memory.registerread(0x2002, 1, function(addr, _, value)
		ppu_model.w = 0
		log_bus("PPUSTATUS_READ_TOGGLE_RESET", addr, value)
	end)
end)
assert(status_read_ok, "could not attach PPUSTATUS read hook")

for address, name in pairs(irq_names) do
	local watched, label = address, name
	memory.registerwrite(watched, 1, function(addr, _, value)
		local select_after = watched == 0x8000 and (value or 0) or nil
		log_bus(label, addr, value, nil, select_after)
		if watched == 0x8000 then
			mmc3_select = value or 0
		elseif watched == 0x8001 then
			mmc3[(mmc3_select % 8) + 1] = value or 0
		elseif watched == 0xA000 then
			mmc3_mirroring = value or -1
		elseif watched == 0xA001 then
			mmc3_ram_control = value or -1
		elseif watched == 0xC000 then
			mmc3_irq_latch = value or -1
		elseif watched == 0xC001 then
			mmc3_irq_reload_pending = 1
		elseif watched == 0xE000 then
			mmc3_irq_enable = 0
		elseif watched == 0xE001 then
			mmc3_irq_enable = 1
		end
		if watched == 0x8000 then
			-- Retain old/new selection explicitly; the row's bank is the executing-store context.
			mmc3_select = value or 0
		end
	end)
end

local function write_snapshot(name)
	local file = assert(io.open(OUT .. "/" .. name, "wb"))
	file:write(memory.readbyterange(0x0000, 0x0800))
	file:close()
end

local function read_checkpoint_signature()
	local cpu_ram = memory.readbyterange(0x0000, 0x0800)
	local ppu_mem = ppu.readbyterange(0x0000, 0x4000)
	assert(type(cpu_ram) == "string" and #cpu_ram == 0x0800, "could not read all CPU RAM")
	assert(type(ppu_mem) == "string" and #ppu_mem == 0x4000, "could not read all PPU memory")
	local r0, r1, r2, r3 = prg_map()
	return {
		frame=emu.framecount(), cycles=cycles(), cpu_ram=cpu_ram, ppu_mem=ppu_mem,
		mmc3_select=mmc3_select, mmc3=copy_array(mmc3),
		mmc3_mirroring=mmc3_mirroring, mmc3_ram_control=mmc3_ram_control,
		mmc3_irq_latch=mmc3_irq_latch, mmc3_irq_enable=mmc3_irq_enable,
		mmc3_irq_reload_pending=mmc3_irq_reload_pending, prg_banks={r0, r1, r2, r3},
		prg_bytes={byte(0x8000), byte(0xA000), byte(0xC000), byte(0xE000)},
		ppu_model={v=ppu_model.v, t=ppu_model.t, fine_x=ppu_model.fine_x, w=ppu_model.w,
			ctrl=ppu_model.ctrl, mask=ppu_model.mask, address_known=ppu_model.address_known},
	}
end

local function restore_checkpoint_state(signature)
	mmc3_select = signature.mmc3_select
	mmc3 = copy_array(signature.mmc3)
	mmc3_mirroring = signature.mmc3_mirroring
	mmc3_ram_control = signature.mmc3_ram_control
	mmc3_irq_latch = signature.mmc3_irq_latch
	mmc3_irq_enable = signature.mmc3_irq_enable
	mmc3_irq_reload_pending = signature.mmc3_irq_reload_pending
	for key, value in pairs(signature.ppu_model) do ppu_model[key] = value end
end

local function verify_checkpoint(signature, label)
	local observed = read_checkpoint_signature()
	assert(observed.frame == signature.frame, label .. " frame mismatch")
	assert(observed.cycles == signature.cycles, label .. " cycle mismatch")
	assert(observed.cpu_ram == signature.cpu_ram, label .. " CPU-RAM signature mismatch")
	assert(observed.ppu_mem == signature.ppu_mem, label .. " PPU-memory signature mismatch")
	assert(observed.mmc3_select == signature.mmc3_select, label .. " MMC3 select mismatch")
	for index = 1, 8 do assert(observed.mmc3[index] == signature.mmc3[index], label .. " MMC3 register mirror mismatch") end
	for index = 1, 4 do
		assert(observed.prg_banks[index] == signature.prg_banks[index], label .. " PRG map mismatch")
		assert(observed.prg_bytes[index] == signature.prg_bytes[index], label .. " mapped PRG byte mismatch")
	end
	assert(observed.ppu_model.v == signature.ppu_model.v and observed.ppu_model.t == signature.ppu_model.t
		and observed.ppu_model.w == signature.ppu_model.w and observed.ppu_model.fine_x == signature.ppu_model.fine_x
		and observed.ppu_model.ctrl == signature.ppu_model.ctrl and observed.ppu_model.mask == signature.ppu_model.mask,
		label .. " modeled PPU CPU-port state mismatch")
end

local function detach_hooks()
	for address in pairs(ppu_writes) do pcall(memory.registerwrite, address, 1, nil) end
	for address in pairs(irq_names) do pcall(memory.registerwrite, address, 1, nil) end
	pcall(memory.registerread, 0x2002, 1, nil)
end

local function begin_pass(pass_index)
	active_pass = pass_index
	event_sequence = 0
	local suffix = pass_index == 1 and "" or "_repeat"
	bus_file = output("ppu_mmc3_bus_writes" .. suffix .. ".csv", bus_header)
	frame_file = output("frame_edges" .. suffix .. ".csv",
		"source_frame,emulator_frame_before,emulator_frame_after,cycle_start,cycle_end,cycle_delta,ppu_scanline_end,ppu_dot_end,input_bits")
	metadata:write("pass_" .. pass_index .. "_range=" .. FIRST_TRACE_FRAME .. "-" .. LAST_TRACE_FRAME .. "\n")
	metadata:flush()
end

local function run_pass(pass_index)
	begin_pass(pass_index)
	for frame = FIRST_TRACE_FRAME, LAST_TRACE_FRAME do
		current_source_frame = frame
		joypad.set(1, inputs[frame])
		frame_cycle_start = cycles()
		local frame_before = emu.framecount()
		emu.frameadvance()
		local frame_after = emu.framecount()
		local cycle_end = cycles()
		local line, dot = ppu_position()
		local bits = {}
		for _, key in ipairs({"up", "down", "left", "right", "A", "B", "start", "select"}) do bits[#bits + 1] = inputs[frame][key] and "1" or "0" end
		frame_file:write(table.concat({frame, frame_before, frame_after, frame_cycle_start, cycle_end,
			cycle_end - frame_cycle_start, line, dot, table.concat(bits, "")}, ",") .. "\n")
		if frame % 15 == 0 or frame == LAST_TRACE_FRAME then
			bus_file:flush(); frame_file:flush(); metadata:flush()
			local progress = assert(io.open(OUT .. "/progress.txt", "w"))
			progress:write(tostring(pass_index) .. ":" .. tostring(frame) .. "\n")
			progress:close()
		end
	end
	bus_file:flush(); frame_file:flush()
	metadata:write("pass_" .. pass_index .. "_bus_events=" .. event_sequence .. "\n")
	metadata:flush()
	bus_file:close(); frame_file:close()
	bus_file, frame_file = nil, nil
end

local startup_movie_mode, startup_movie_name = "unavailable", "none"
pcall(function()
	startup_movie_mode = tostring(movie.mode())
	if movie.mode() ~= nil then startup_movie_name = tostring(movie.getname()); pcall(movie.stop) end
end)
if type(movie.active) == "function" then
	local active = false
	pcall(function() active = movie.active() end)
	if active then pcall(movie.stop) end
end
assert(tostring(movie.mode()) == "nil", "could not disable FCEUX startup movie")
local power_ok, power_error = pcall(emu.poweron)
assert(power_ok, "FCEUX power-on failed: " .. tostring(power_error))
pcall(debugger.resetcyclescount)
metadata:write("startup_movie_mode=" .. startup_movie_mode .. "\nstartup_movie_name=" .. startup_movie_name .. "\n")
metadata:write("poweron_success=true\nppu_status_read_hook=" .. tostring(status_read_ok) .. "\n")
metadata:write("initial_input_identity=validated by Python runner\n")
metadata:flush()
pcall(emu.speedmode, "turbo")

for frame = 0, CHECKPOINT_FRAME do
	current_source_frame = frame
	joypad.set(1, inputs[frame])
	frame_cycle_start = cycles()
	emu.frameadvance()
	if frame % 300 == 0 or frame == CHECKPOINT_FRAME then
		local progress = assert(io.open(OUT .. "/progress.txt", "w"))
		progress:write("warmup:" .. tostring(frame) .. "\n")
		progress:close()
	end
end

local checkpoint = savestate.create()
assert(checkpoint ~= nil, "could not create anonymous in-memory save state")
local signature = read_checkpoint_signature()
local save_ok, save_err = pcall(savestate.save, checkpoint)
assert(save_ok, "could not save anonymous in-memory checkpoint: " .. tostring(save_err))
local persist_ok, persist_err = pcall(savestate.persist, checkpoint)
assert(persist_ok, "could not keep anonymous checkpoint for repeated loads: " .. tostring(persist_err))
metadata:write("checkpoint_source_frame=" .. CHECKPOINT_FRAME .. "\ncheckpoint_emulator_frame=" .. signature.frame .. "\n")
metadata:write("checkpoint_cycle_count=" .. signature.cycles .. "\n")
metadata:write("checkpoint_cpu_ram_bytes=" .. #signature.cpu_ram .. "\ncheckpoint_ppu_memory_bytes=" .. #signature.ppu_mem .. "\n")
metadata:write("checkpoint_mmc3_select=$" .. string.format("%02X", signature.mmc3_select) .. "\n")
metadata:write("checkpoint_prg_banks=" .. table.concat(signature.prg_banks, ",") .. "\ncheckpoint_prg_bytes=" .. table.concat(signature.prg_bytes, ",") .. "\n")
metadata:write("checkpoint_ppu_model=v:$" .. string.format("%04X", signature.ppu_model.v)
	.. ",t:$" .. string.format("%04X", signature.ppu_model.t) .. ",fine_x:$"
	.. string.format("%02X", signature.ppu_model.fine_x) .. ",w:" .. tostring(signature.ppu_model.w)
	.. ",ctrl:$" .. string.format("%02X", signature.ppu_model.ctrl) .. ",mask:$"
	.. string.format("%02X", signature.ppu_model.mask) .. "\n")
metadata:write("checkpoint_signature=2KiB CPU RAM, 16KiB PPU memory, frame/cycle, MMC3 mirror and mapped PRG bytes, modeled PPU CPU-port state\n")
metadata:flush()

for pass = 1, 2 do
	local load_ok, load_err = pcall(savestate.load, checkpoint)
	assert(load_ok, "save-state load failed for pass " .. pass .. ": " .. tostring(load_err))
	restore_checkpoint_state(signature)
	verify_checkpoint(signature, "pass " .. pass)
	metadata:write("pass_" .. pass .. "_checkpoint_verified=true\n")
	metadata:flush()
	run_pass(pass)
end

metadata:write("complete=true\nreplay_passes=2\ncompleted_source_frames=" .. LAST_TRACE_FRAME .. "\n")
metadata:write("caveat=Lua cannot independently read hidden 2C02 v/t/w registers after savestate load; modeled CPU-port state is restored from the saved pre-load signature and direct CPU RAM/PPU memory/frame/cycle/mapper signatures are compared.\n")
metadata:flush()
metadata:close()
detach_hooks()
os.exit()

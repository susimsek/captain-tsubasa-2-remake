-- Muted, source-input replay tracing actor animation state and OAM generation.
-- Captured bytes are validation evidence only; they are never runtime assets.

local ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local LAST_FRAME = 8953
local TRACE_START = 8000
local ENDPOINT_FRAME = 8953
local OUT = assert(os.getenv("CT2_ACTOR_TRACE_OUTPUT_DIR"), "missing output directory")
os.execute("mkdir -p " .. string.format("%q", OUT))

local inputs = {}
local function read_inputs(path, route_format)
	local file = assert(io.open(path, "r"), "missing input file " .. path)
	local header = true
	for line in file:lines() do
		if header then
			header = false
		else
			line = line:gsub("\r$", "")
			local values = {}
			for value in (line .. ","):gmatch("(.-),") do values[#values + 1] = value end
			local frame = tonumber(values[1])
			if frame then
				local offset = route_format and 3 or 2
				inputs[frame] = {
					up=values[offset] == "1", down=values[offset + 1] == "1",
					left=values[offset + 2] == "1", right=values[offset + 3] == "1",
					A=values[offset + 4] == "1", B=values[offset + 5] == "1",
					start=values[offset + 6] == "1", select=values[offset + 7] == "1",
				}
			end
		end
	end
	file:close()
end

read_inputs(OPENING_INPUT, false)
read_inputs(ROUTE_INPUT, true)
for frame = 0, LAST_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local function out_file(name, header)
	local file = assert(io.open(OUT .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end

local function binary_file(name, contents)
	local file = assert(io.open(OUT .. "/" .. name, "wb"))
	file:write(contents)
	file:close()
end

local function byte(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return value or 0
end

local function word(address) return byte(address) + byte(address + 1) * 256 end

local function reg(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return value or -1
end

local function hx(value, width)
	return string.format(width == 2 and "%02X" or "%04X", value or 0)
end

local function bytes_hex(first, count)
	local values = {}
	for offset = 0, count - 1 do values[#values + 1] = hx(byte(first + offset), 2) end
	return table.concat(values, " ")
end

local function csv(values)
	local fields = {}
	for index, value in ipairs(values) do
		fields[index] = tostring(value or "")
		fields[index] = fields[index]:gsub(",", ";")
	end
	return table.concat(fields, ",")
end

local function read_oam()
	local result = {}
	for offset = 0, 255 do result[offset + 1] = byte(0x0200 + offset) end
	return result
end

local draw_file = out_file("actor_draw_calls.csv",
	"source_frame,emu_frame,actor_order_index,actor_record,actor_record_21_bytes,flag,timer,script_ptr,descriptor,x_lo,y_lo,x_hi,y_hi,graphic_selector_0546,chr_selectors_0493_0497,ppu_ctrl,ppu_mask,mmc3_select,r0,r1,r2,r3,r4,r5,r6,r7,oam_index_before,oam_index_after,sprite_count_after,changed_slots,changed_oam_entries")
local state_file = out_file("frame_state.csv",
	"source_frame,emu_frame,order_0543_0545,selector_0546,chr_0493_0497,ppu_ctrl,ppu_mask,scroll_x_0538,scroll_004a,scroll_004b,ball_player_0441,player_ptr_0348,player_id,graphic_selector_0546,mmc3_select,r0,r1,r2,r3,r4,r5,r6,r7,actor_records_hex,ppu_file,ram_file")
local write_file = out_file("actor_state_writes.csv",
	"source_frame,emu_frame,cpu_pc,address,old_value,new_value,actor_order_index,actor_record,graphic_selector_0546,script_pointer")
local metadata = out_file("metadata.txt")

local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
metadata:write("rom_md5=" .. tostring(md5) .. "\n")
metadata:write("opening_input=" .. OPENING_INPUT .. "\nroute_input=" .. ROUTE_INPUT .. "\n")
metadata:write("source_frames=0-" .. LAST_FRAME .. "; instrumented actor draw hooks=" .. TRACE_START .. "-" .. LAST_FRAME .. "\n")
metadata:write("audio=disabled at process launch with --sound 0 --volume 0; SDL_AUDIODRIVER=dummy; no WAV/PCM recorded\n")
metadata:write("purpose=trace ROM animation state and actor-to-OAM writes; all captured bytes are diagnostic references, not runtime assets\n")
metadata:write("hooks=fixed-bank $EF35 before bank-$16 sprite engine; $EF38 after return; writes to $0546 and $0493-$0497\n")
metadata:flush()

local current_frame = 0
local mmc3_select = 0
local mmc3 = {0, 0, 0, 0, 0, 0, 0, 0}
local current_draw = nil

local function actor_record_address()
	return word(0x003C)
end

local function mmc_values()
	local values = {}
	for i = 1, 8 do values[i] = hx(mmc3[i], 2) end
	return values
end

local function log_draw_return()
	if current_draw == nil then return end
	local after = read_oam()
	local changed_slots = {}
	local changed_entries = {}
	for slot = 0, 63 do
		local offset = slot * 4
		local changed = false
		for j = 0, 3 do
			if current_draw.oam_before[offset + j + 1] ~= after[offset + j + 1] then changed = true end
		end
		if changed then
			changed_slots[#changed_slots + 1] = tostring(slot)
			changed_entries[#changed_entries + 1] = string.format("%02X:%02X/%02X/%02X/%02X",
				slot, after[offset + 1], after[offset + 2], after[offset + 3], after[offset + 4])
		end
	end
	local v = current_draw
	local fields = {current_frame, emu.framecount(), v.order, string.format("$%04X", v.record), v.record_hex,
		hx(v.flag, 2), hx(v.timer, 2), string.format("$%04X", v.script_ptr), hx(v.descriptor, 2),
		hx(v.x_lo, 2), hx(v.y_lo, 2), hx(v.x_hi, 2), hx(v.y_hi, 2), hx(v.selector, 2), v.chr,
		hx(v.ppu_ctrl, 2), hx(v.ppu_mask, 2), hx(v.mmc3_select, 2)}
	for _, value in ipairs(v.mmc3) do fields[#fields + 1] = "$" .. value end
	fields[#fields + 1] = v.oam_before_index
	fields[#fields + 1] = byte(0x003B)
	fields[#fields + 1] = byte(0x0048)
	fields[#fields + 1] = table.concat(changed_slots, "|")
	fields[#fields + 1] = table.concat(changed_entries, "|")
	draw_file:write(csv(fields) .. "\n")
	current_draw = nil
end

memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value)
	local index = (mmc3_select % 8) + 1
	mmc3[index] = value or 0
end)

for address = 0x0493, 0x0497 do
	local watched = address
	memory.registerwrite(watched, 1, function(_, _, value)
		if current_frame < TRACE_START then return end
		local record = actor_record_address()
		write_file:write(csv({current_frame, emu.framecount(), string.format("$%04X", reg("pc")),
			string.format("$%04X", watched), hx(byte(watched), 2), hx(value, 2), byte(0x003A),
			string.format("$%04X", record), hx(byte(0x0546), 2), string.format("$%04X", word(record + 3))}) .. "\n")
	end)
end
memory.registerwrite(0x0546, 1, function(_, _, value)
	if current_frame < TRACE_START then return end
	local record = actor_record_address()
	write_file:write(csv({current_frame, emu.framecount(), string.format("$%04X", reg("pc")), "$0546",
		hx(byte(0x0546), 2), hx(value, 2), byte(0x003A), string.format("$%04X", record),
		hx(value, 2), string.format("$%04X", word(record + 3))}) .. "\n")
end)

memory.registerexec(0xEF35, function()
	if current_frame < TRACE_START or current_frame > LAST_FRAME then return end
	local record = actor_record_address()
	local mmc = mmc_values()
	current_draw = {
		order = byte(0x003A), record = record, record_hex = bytes_hex(record, 21),
		flag = byte(record), timer = byte(record + 0x10), script_ptr = word(record + 3),
		descriptor = byte(record + 0x12), x_lo = byte(record + 8), y_lo = byte(record + 6),
		x_hi = byte(record + 9), y_hi = byte(record + 7), selector = byte(0x0546),
		chr = bytes_hex(0x0493, 5), ppu_ctrl = byte(0x2000), ppu_mask = byte(0x2001),
		mmc3_select = mmc3_select, mmc3 = mmc, oam_before_index = byte(0x003B), oam_before = read_oam(),
	}
end)
memory.registerexec(0xEF38, function()
	if current_frame < TRACE_START or current_frame > LAST_FRAME then return end
	log_draw_return()
end)

local sparse_state_frames = {}
for frame = 8100, LAST_FRAME, 60 do sparse_state_frames[frame] = true end
sparse_state_frames[7392] = true
sparse_state_frames[7393] = true
sparse_state_frames[7394] = true
sparse_state_frames[7395] = true
sparse_state_frames[7396] = true
sparse_state_frames[7397] = true
sparse_state_frames[7398] = true
sparse_state_frames[7443] = true
sparse_state_frames[7543] = true
sparse_state_frames[7693] = true
sparse_state_frames[7843] = true
sparse_state_frames[7993] = true
sparse_state_frames[8143] = true
sparse_state_frames[8443] = true
sparse_state_frames[8593] = true
sparse_state_frames[8743] = true
sparse_state_frames[8893] = true
sparse_state_frames[8953] = true

local function write_state(frame)
	local actor_blob = {}
	for _, record in ipairs({0x0547, 0x055C, 0x0571, 0x0586, 0x059B, 0x05B0}) do
		actor_blob[#actor_blob + 1] = string.format("%04X:%s", record, bytes_hex(record, 21))
	end
	local player_ptr = word(0x0348)
	local ppu_file = string.format("ppu_memory_frame_%06d.bin", frame)
	local ram_file = string.format("cpu_ram_frame_%06d.bin", frame)
	local ppu_ok, ppu_bytes = pcall(function() return ppu.readbyterange(0x0000, 0x4000) end)
	local ram_ok, ram_bytes = pcall(function() return memory.readbyterange(0x0000, 0x0800) end)
	if ppu_ok and type(ppu_bytes) == "string" and #ppu_bytes == 0x4000 then
		binary_file(ppu_file, ppu_bytes)
	else
		ppu_file = ""
	end
	if ram_ok and type(ram_bytes) == "string" and #ram_bytes == 0x0800 then
		binary_file(ram_file, ram_bytes)
	else
		ram_file = ""
	end
	local fields = {frame, emu.framecount(), bytes_hex(0x0543, 3), hx(byte(0x0546), 2),
		bytes_hex(0x0493, 5), hx(byte(0x2000), 2), hx(byte(0x2001), 2), hx(byte(0x0538), 2),
		hx(byte(0x004A), 2), hx(byte(0x004B), 2), hx(byte(0x0441), 2),
		string.format("$%04X", player_ptr), hx(byte(player_ptr), 2), hx(byte(0x0546), 2),
		hx(mmc3_select, 2)}
	for _, value in ipairs(mmc_values()) do fields[#fields + 1] = "$" .. value end
	fields[#fields + 1] = table.concat(actor_blob, "|")
	fields[#fields + 1] = ppu_file
	fields[#fields + 1] = ram_file
	state_file:write(csv(fields) .. "\n")
end

assert(type(movie) == "table" and type(movie.active) == "function" and type(movie.stop) == "function",
	"FCEUX movie API unavailable; cannot guarantee that joypad.set controls the route")
local startup_movie_active, startup_movie_name = false, ""
pcall(function() startup_movie_active = movie.active() end)
pcall(function() startup_movie_name = movie.getname() end)
metadata:write("startup_movie_active=" .. tostring(startup_movie_active) .. "\n")
metadata:write("startup_movie_name=" .. tostring(startup_movie_name) .. "\n")
if startup_movie_active then
	local stop_ok, stop_error = pcall(movie.stop)
	metadata:write("startup_movie_stop_ok=" .. tostring(stop_ok) .. " error=" .. tostring(stop_error or "") .. "\n")
end
local movie_ok, movie_active = pcall(movie.active)
assert(movie_ok and not movie_active, "movie playback remains active before emu.poweron")
metadata:write("movie_active_before_poweron=false\n")
metadata:flush()

local ok, err = pcall(emu.poweron)
metadata:write("poweron=" .. tostring(ok) .. " error=" .. tostring(err or "") .. "\n")
local post_power_movie = true
local post_power_ok = pcall(function() post_power_movie = movie.active() end)
assert(post_power_ok and not post_power_movie, "movie playback reactivated after emu.poweron")
metadata:write("movie_active_after_poweron=false\n")
metadata:flush()
pcall(emu.speedmode, "turbo")
for frame = 0, LAST_FRAME do
	current_frame = frame
	joypad.set(1, inputs[frame])
	emu.frameadvance()
	if sparse_state_frames[frame] then write_state(frame) end
	if frame % 120 == 0 then
		draw_file:flush(); state_file:flush(); write_file:flush()
		local progress = assert(io.open(OUT .. "/progress.txt", "w"))
		progress:write(tostring(frame) .. "\n"); progress:close()
	end
	if frame == ENDPOINT_FRAME then
		local ram = assert(io.open(OUT .. "/cpu_ram_0000_07ff_frame_008953.bin", "wb"))
		local bytes = {}
		for address = 0, 0x07FF do bytes[#bytes + 1] = string.char(byte(address)) end
		ram:write(table.concat(bytes)); ram:close()
	end
end

draw_file:flush(); state_file:flush(); write_file:flush()
metadata:write("completed_source_frames=" .. (LAST_FRAME + 1) .. "\n")
metadata:flush()
draw_file:close(); state_file:close(); write_file:close(); metadata:close()
os.exit()

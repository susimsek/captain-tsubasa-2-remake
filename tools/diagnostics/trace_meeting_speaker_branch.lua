-- Muted same-input trace of the scene-$44 $99 speaker state and $FA frame choice.
-- All output is validation evidence; no screenshots, audio, or runtime assets are made.

local ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local OPENING_INPUT = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local ROUTE_INPUT = ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv"
local LAST_FRAME = 8953
local OUT = assert(os.getenv("CT2_SPEAKER_TRACE_OUTPUT_DIR"), "missing output directory")
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

local output = assert(io.open(OUT .. "/speaker_branch_events.csv", "w"))
output:write("source_frame,emu_frame,event,pc,prg_5114_shadow,prg_5115_shadow,old_0099,new_0099,selected_frame_ptr,animation_record_ptr,animation_script_ptr,scene_script_ptr,text_speed,actor_state_flags,sprite_palette_index,rom_palette_file_offset,sprite_palette_ram_buffer,ppu_sprite_palette\n")
local metadata = assert(io.open(OUT .. "/metadata.txt", "w"))
local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
metadata:write("rom_md5=" .. tostring(md5) .. "\n")
metadata:write("input=opening_reference_capture/input_timeline.csv + kickoff_select_test_20261027/post_title_inputs.csv\n")
metadata:write("source_frames=0-" .. LAST_FRAME .. "\naudio=disabled at launch; no WAV/PCM recorded\n")
metadata:write("events=RAM $0099 writes; bank-qualified hooks $8618, $895D, and $946D (the $FA selected-frame JSR); palette index/buffer/PPU bytes recorded at each event\n")
metadata:write("bank_context=RAM $0024/$0025 (5114/5115 shadows for the $8000/$A000 windows) are recorded at every event to reject CPU-address aliases from other banks\n")
metadata:write("movie=any auto-restored movie is stopped before power-on and asserted inactive after power-on\n")

local current_frame = 0
local function byte(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return value or 0
end
local function word(address) return byte(address) + byte(address + 1) * 256 end
local function hx(value, width) return string.format(width == 2 and "%02X" or "%04X", value or 0) end
local function palette_ppu_hex()
	local ok, bytes = pcall(function() return ppu.readbyterange(0x3F10, 0x10) end)
	if not ok or type(bytes) ~= "string" or #bytes ~= 0x10 then return "" end
	local values = {}
	for i = 1, #bytes do values[i] = hx(bytes:byte(i), 2) end
	return table.concat(values, " ")
end
local function palette_ram_hex()
	local values = {}
	for address = 0x063A, 0x0649 do values[#values + 1] = hx(byte(address), 2) end
	return table.concat(values, " ")
end
local function csv(values)
	local fields = {}
	for i, value in ipairs(values) do
		fields[i] = tostring(value or ""):gsub(",", ";")
	end
	return table.concat(fields, ",")
end
local function log_event(kind, pc, old_value, new_value, ptr)
	output:write(csv({current_frame, emu.framecount(), kind, string.format("$%04X", pc or 0),
		hx(byte(0x0024), 2), hx(byte(0x0025), 2), hx(old_value or byte(0x0099), 2), hx(new_value or byte(0x0099), 2),
		ptr and string.format("$%04X", ptr) or "",
		string.format("$%04X", word(0x0094)), string.format("$%04X", word(0x0092)),
		string.format("$%04X", word(0x004D)), hx(byte(0x0055), 2),
		hx(byte(word(0x0094)), 2), hx(byte(0x0049), 2), string.format("$%04X", 0xD310 + 16 * byte(0x0049)),
		palette_ram_hex(), palette_ppu_hex()}) .. "\n")
end

local tracked_0099 = 0
memory.registerwrite(0x0099, 1, function(_, _, new_value)
	local pc = 0
	pcall(function() pc = memory.getregister("pc") end)
	local next_value = new_value or byte(0x0099)
	log_event("write_0099", pc, tracked_0099, next_value)
	tracked_0099 = next_value
end)
memory.registerexec(0x8618, function() log_event("EF_toggle_mouth_8618", 0x8618) end)
memory.registerexec(0x895D, function() log_event("text_speed_895D", 0x895D) end)
memory.registerexec(0x946D, function()
	local selected = word(0x00E6)
	log_event("FA_selected_frame_946D", 0x946D, byte(0x0099), byte(0x0099), selected)
end)

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
local power_ok, power_error = pcall(emu.poweron)
metadata:write("poweron=" .. tostring(power_ok) .. " error=" .. tostring(power_error or "") .. "\n")
tracked_0099 = byte(0x0099)
local post_power_movie = true
local post_power_ok = pcall(function() post_power_movie = movie.active() end)
assert(post_power_ok and not post_power_movie, "movie playback reactivated after emu.poweron")
pcall(emu.speedmode, "turbo")

for frame = 0, LAST_FRAME do
	current_frame = frame
	joypad.set(1, inputs[frame])
	emu.frameadvance()
	if frame % 120 == 0 then
		output:flush()
		local progress = assert(io.open(OUT .. "/progress.txt", "w"))
		progress:write(tostring(frame) .. "\n")
		progress:close()
	end
end

output:flush()
metadata:write("completed_source_frames=" .. (LAST_FRAME + 1) .. "\n")
metadata:close()
output:close()
os.exit()

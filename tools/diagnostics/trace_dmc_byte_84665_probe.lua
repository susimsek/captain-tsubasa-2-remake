-- Muted, target-only FCEUX validation for DMC byte 84,665.
-- Explicitly loads then stops the known cold-start bootstrap movie, power-cycles,
-- and applies only the first 4,693 rows of the SHA-checked input timeline.

local OUTPUT_DIR = assert(os.getenv("CT2_DMC_PROBE_OUTPUT_DIR"), "missing output directory")
local INPUT_CSV = assert(os.getenv("CT2_DMC_PROBE_INPUT_CSV"), "missing hashed input timeline")
local EXPECTED_ROM_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"
local EXPECTED_BOOTSTRAP_BASENAME = "cold_start_opening_partial.fm2"
local LAST_SOURCE_FRAME = 4692

os.execute("mkdir -p " .. string.format("%q", OUTPUT_DIR))

local metadata = assert(io.open(OUTPUT_DIR .. "/capture.txt", "w"))
local progress = assert(io.open(OUTPUT_DIR .. "/progress.csv", "w"))
local applied = assert(io.open(OUTPUT_DIR .. "/applied_inputs.csv", "w"))
metadata:write("rom_md5=" .. tostring(rom.gethash("md5")) .. "\n")
metadata:write("input_timeline=" .. INPUT_CSV .. "\n")
metadata:write("input_timeline_sha256=" .. tostring(os.getenv("CT2_DMC_PROBE_INPUT_SHA256")) .. "\n")
metadata:write("source_frames=0-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("audio=sound core enabled; --volume 0; SDL_AUDIODRIVER=dummy; no PCM/WAV output\n")
metadata:write("trace=only DMR and HOOK_IN/HOOK_OUT for target hook and bounded cycle window\n")
metadata:flush()
assert(rom.gethash("md5") == EXPECTED_ROM_MD5, "unexpected ROM payload")

local startup_active = movie.active()
local startup_mode = tostring(movie.mode())
local startup_name = ""
pcall(function() startup_name = movie.getname() or "" end)
metadata:write("bootstrap_active_at_lua_start=" .. tostring(startup_active) .. "\n")
metadata:write("bootstrap_mode_at_lua_start=" .. startup_mode .. "\n")
metadata:write("bootstrap_name_at_lua_start=" .. tostring(startup_name) .. "\n")
assert(startup_active, "explicit bootstrap movie was not active before Lua")
assert(startup_mode == "playback", "bootstrap must be in playback mode")
assert(string.find(startup_name, EXPECTED_BOOTSTRAP_BASENAME, 1, true), "wrong bootstrap movie loaded")

movie.stop()
local stopped_before_poweron = not movie.active()
metadata:write("bootstrap_stopped_before_poweron=" .. tostring(stopped_before_poweron) .. "\n")
assert(stopped_before_poweron, "bootstrap movie remained active before power-on")

local inputs = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "failed to open hashed input timeline")
local header = input_file:read("*l")
assert(header == "frame,up,down,left,right,A,B,start,select", "unexpected input timeline header")
for line in input_file:lines() do
	local frame, up, down, left, right, a, b, start, select = line:gsub("\r$", ""):match(
		"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if frame then
		frame = tonumber(frame)
		if frame <= LAST_SOURCE_FRAME then
			assert(frame == #inputs, "nonsequential source frame in input timeline")
			inputs[#inputs + 1] = {
				up=up, down=down, left=left, right=right,
				A=a, B=b, start=start, select=select,
			}
		end
	end
end
input_file:close()
assert(#inputs == LAST_SOURCE_FRAME + 1, "input timeline does not contain frames 0..4692")

local poweron_ok, poweron_error = pcall(emu.poweron)
metadata:write("poweron_success=" .. tostring(poweron_ok) .. " error=" .. tostring(poweron_error or "") .. "\n")
local stopped_after_poweron = not movie.active()
metadata:write("bootstrap_stopped_after_poweron=" .. tostring(stopped_after_poweron) .. "\n")
assert(poweron_ok, "emu.poweron failed after bootstrap stop: " .. tostring(poweron_error))
assert(stopped_after_poweron, "bootstrap/movie playback reactivated after power-on")

debugger.resetcyclescount()
pcall(emu.speedmode, "maximum")
progress:write("source_frame,emulator_frame_before,emulator_frame_after,cpu_cycle_end\n")
applied:write(header .. "\n")
metadata:write("input_application=joypad.set(P1) from parsed SHA-checked CSV; no joypad.get readback\n")
metadata:write("input_rows_to_apply=" .. #inputs .. "\n")
metadata:flush()

local function bool(value)
	return value == "1"
end

for source_frame=0,LAST_SOURCE_FRAME do
	local row = inputs[source_frame + 1]
	local emulator_frame_before = emu.framecount()
	local controller = {
		up=bool(row.up), down=bool(row.down), left=bool(row.left), right=bool(row.right),
		A=bool(row.A), B=bool(row.B), start=bool(row.start), select=bool(row.select),
	}
	joypad.set(1, controller)
	applied:write(table.concat({source_frame, row.up, row.down, row.left, row.right,
		row.A, row.B, row.start, row.select}, ",") .. "\n")
	emu.frameadvance()
	if source_frame == 0 or source_frame == 3600 or source_frame == 3601 or source_frame == LAST_SOURCE_FRAME or source_frame % 60 == 59 then
		progress:write(table.concat({source_frame, emulator_frame_before, emu.framecount(), debugger.getcyclescount()}, ",") .. "\n")
		progress:flush()
		applied:flush()
	end
end

progress:write(table.concat({LAST_SOURCE_FRAME, emu.framecount(), emu.framecount(), debugger.getcyclescount()}, ",") .. "\n")
metadata:write("completed_source_frames=" .. (LAST_SOURCE_FRAME + 1) .. "\n")
metadata:write("applied_input_rows=" .. #inputs .. "\n")
metadata:write("final_cycle=" .. debugger.getcyclescount() .. "\n")
metadata:flush()
progress:close()
applied:close()
metadata:close()
os.exit()

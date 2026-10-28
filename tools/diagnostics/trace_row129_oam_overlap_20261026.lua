-- Muted same-input FCEUX trace for the current 5-pixel sprite row residual.
-- Run in a separate FCEUX process with the matching ROM, New PPU, and the
-- environment-gated sprite read/composition traces enabled.

local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local OUT_DIR = PROJECT_ROOT .. "/reference/diagnostics/oam_row129_cluster_trace_20261026"
local TARGET_SOURCE_FRAME = 3594
local EXPECTED_ROM_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"

os.execute("mkdir -p " .. string.format("%q", OUT_DIR))

local timeline = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "missing source input timeline")
for line in input_file:lines() do
	line = line:gsub("\r$", "")
	local frame, up, down, left, right, a, b, start, select = line:match(
		"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if frame then
		timeline[tonumber(frame)] = {
			up = up == "1", down = down == "1", left = left == "1", right = right == "1",
			A = a == "1", B = b == "1", start = start == "1", select = select == "1",
		}
	end
end
input_file:close()
for frame = 0, TARGET_SOURCE_FRAME do
	assert(timeline[frame], "missing input for source frame " .. frame)
end

local actual_md5 = "unavailable"
pcall(function() actual_md5 = rom.gethash("md5") end)
assert(actual_md5 == EXPECTED_ROM_MD5, "wrong ROM payload MD5: " .. tostring(actual_md5))

local metadata = assert(io.open(OUT_DIR .. "/metadata.txt", "w"))
metadata:write("source_rom_md5_payload=" .. actual_md5 .. "\n")
metadata:write("source_rom_sha256=4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097\n")
metadata:write("fceux_source_revision=a6d03e7968bd77a8156a7c9b628a673753f2f4c6\n")
metadata:write("source_input_timeline=" .. INPUT_CSV .. "\n")
metadata:write("source_frame_range=0-" .. TARGET_SOURCE_FRAME .. "\n")
metadata:write("active_ppu=New PPU; enforced with --newppu 1\n")
metadata:write("audio=muted with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy\n")
metadata:write("traces=FCEUX modeled sprite plane reads, final per-pixel composition, and same-run $2006 write/address state; validation only\n")
metadata:flush()

if movie.active() then movie.stop() end
local power_ok, power_err = pcall(emu.poweron)
assert(power_ok, "emu.poweron failed: " .. tostring(power_err))
pcall(debugger.resetcyclescount)
pcall(emu.speedmode, "turbo")

local cycle_start = -1
local frame_log = assert(io.open(OUT_DIR .. "/frame_edges.csv", "w"))
frame_log:write("source_frame,emulator_frame_after,cycle_start,cycle_end,ppu_line_end,ppu_dot_end\n")
for source_frame = 0, TARGET_SOURCE_FRAME do
	joypad.set(1, timeline[source_frame])
	cycle_start = -1
	pcall(function() cycle_start = debugger.getcyclescount() end)
	emu.frameadvance()
	if source_frame == TARGET_SOURCE_FRAME then
		local cycle_end, line, dot = -1, -1, -1
		pcall(function() cycle_end = debugger.getcyclescount() end)
	pcall(function() line = ppu.getscanline() end)
		pcall(function() dot = ppu.getdot() end)
		frame_log:write(table.concat({source_frame, emu.framecount(), cycle_start, cycle_end, line, dot}, ",") .. "\n")
	end
end
frame_log:close()
metadata:write("completed_source_frame=" .. TARGET_SOURCE_FRAME .. "\n")
metadata:close()
os.exit()

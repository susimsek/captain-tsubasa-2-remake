local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local OUT_DIR = PROJECT_ROOT .. "/reference/diagnostics/oam_all_residual_trace_20261026"
local TARGET_SOURCE_FRAME = 3649
local EXPECTED_ROM_MD5 = "eaf2b3745263efa4b1afd2b400f68dae"

os.execute("mkdir -p " .. string.format("%q", OUT_DIR))
local timeline = {}
local input_file = assert(io.open(INPUT_CSV, "r"))
for line in input_file:lines() do
    local frame, up, down, left, right, a, b, start, select = line:gsub("\r$", ""):match(
        "^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
    if frame then
        timeline[tonumber(frame)] = {up=up=="1", down=down=="1", left=left=="1", right=right=="1",
            A=a=="1", B=b=="1", start=start=="1", select=select=="1"}
    end
end
input_file:close()
for frame = 0, TARGET_SOURCE_FRAME do assert(timeline[frame], "missing input frame " .. frame) end

local hash = "unavailable"
pcall(function() hash = rom.gethash("md5") end)
assert(hash == EXPECTED_ROM_MD5, "wrong ROM MD5 " .. tostring(hash))
if movie.active() then movie.stop() end
local power_ok, power_err = pcall(emu.poweron)
assert(power_ok, "emu.poweron failed: " .. tostring(power_err))
emu.speedmode("turbo")

local progress = assert(io.open(OUT_DIR .. "/progress.txt", "w"))
progress:write("rom_md5=" .. hash .. "\nsource_range=0-" .. TARGET_SOURCE_FRAME .. "\n")
progress:flush()
for frame = 0, TARGET_SOURCE_FRAME do
    joypad.set(1, timeline[frame])
    emu.frameadvance()
    if frame % 250 == 0 or frame == TARGET_SOURCE_FRAME then
        progress:write("source_input_frame=" .. frame .. " emulator_frame=" .. emu.framecount() .. "\n")
        progress:flush()
    end
end
progress:write("completed=true\n")
progress:close()
os.exit()

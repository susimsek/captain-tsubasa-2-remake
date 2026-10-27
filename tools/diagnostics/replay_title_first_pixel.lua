-- Replays the supplied opening input timeline into a diagnostics-only FCEUX
-- build with its PPU output-pixel trace enabled. No movie or screenshot is
-- used as a runtime asset.
local input_path = assert(os.getenv("CT2_INPUT_TIMELINE"), "CT2_INPUT_TIMELINE is required")
local run_log_path = assert(os.getenv("CT2_TITLE_PIXEL_RUNLOG"), "CT2_TITLE_PIXEL_RUNLOG is required")
local last_source_frame = 4692
local inputs = {}
local file = assert(io.open(input_path, "r"), "missing source input timeline")
for line in file:lines() do
  local frame, up, down, left, right, a, b, start, select = line:gsub("\r$", ""):match("^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
  if frame then
    inputs[tonumber(frame)] = {up=up=="1", down=down=="1", left=left=="1", right=right=="1", A=a=="1", B=b=="1", start=start=="1", select=select=="1"}
  end
end
file:close()
for frame=0,last_source_frame do assert(inputs[frame], "missing source input frame " .. frame) end

local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
local meta = assert(io.open(run_log_path, "w"))
meta:write("rom_md5=" .. tostring(md5) .. "\nsource_frames=0-" .. last_source_frame .. "\ninput=" .. input_path .. "\naudio=disabled at process launch\n")
meta:flush()
local ok, err = pcall(emu.poweron)
meta:write("poweron_success=" .. tostring(ok) .. " error=" .. tostring(err or "") .. "\n")
meta:flush()
pcall(emu.speedmode, "turbo")
for frame=0,last_source_frame do
  joypad.set(1, inputs[frame])
  emu.frameadvance()
  if frame % 300 == 0 then
    meta:write("advanced_source_frame=" .. frame .. " emulator_frame=" .. tostring(emu.framecount()) .. "\n")
    meta:flush()
  end
end
meta:write("done_source_frame=" .. last_source_frame .. " emulator_frame=" .. tostring(emu.framecount()) .. "\n")
meta:flush()
meta:close()
pcall(emu.speedmode, "normal")
FCEU.pause()
os.exit()

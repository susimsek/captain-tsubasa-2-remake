-- Replay the exact captured opening inputs for the patched FCEUX DMC trace.
-- The APU core remains enabled, but the runner uses volume 0 and SDL's dummy
-- audio backend. No WAV/PCM output is recorded or used as a game asset.

local PROJECT_ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local OUTPUT_DIR = os.getenv("CT2_DMC_TRACE_OUTPUT_DIR")
assert(OUTPUT_DIR and #OUTPUT_DIR > 0, "set CT2_DMC_TRACE_OUTPUT_DIR via the Python runner")
local LAST_SOURCE_FRAME = 4692
os.execute("mkdir -p " .. string.format("%q", OUTPUT_DIR))

local inputs = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "missing opening input timeline")
for line in input_file:lines() do
	local frame, up, down, left, right, a, b, start, select = line:gsub("\r$", ""):match(
		"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if frame then
		inputs[tonumber(frame)] = {
			up=up=="1", down=down=="1", left=left=="1", right=right=="1",
			A=a=="1", B=b=="1", start=start=="1", select=select=="1",
		}
	end
end
input_file:close()
for frame=0,LAST_SOURCE_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local writes = assert(io.open(OUTPUT_DIR .. "/apu_writes.csv", "w"))
writes:write("sequence,source_frame,emulator_frame,cpu_cycle,pc,address,value\n")
local frames = assert(io.open(OUTPUT_DIR .. "/frame_cycles.csv", "w"))
frames:write("source_frame,emulator_frame_after,cycle_start,cycle_end,cycle_delta\n")
local meta = assert(io.open(OUTPUT_DIR .. "/capture.txt", "w"))
local rom_md5 = "unavailable"
pcall(function() rom_md5 = rom.gethash("md5") end)
meta:write("rom_filename=" .. tostring(rom.getfilename()) .. "\n")
meta:write("rom_md5=" .. tostring(rom_md5) .. "\n")
meta:write("input_timeline=" .. INPUT_CSV .. "\n")
meta:write("source_frames=0-" .. LAST_SOURCE_FRAME .. "\n")
meta:write("sound_core=enabled; output muted with --volume 0 and SDL_AUDIODRIVER=dummy\n")
meta:write("wav_or_pcm_capture=false\n")
meta:write("write_hook=memory.registerwrite($4000, size $18), CPU-bus writes only\n")
meta:write("cycle_hook=debugger.getcyclescount(), cycles since power-on or explicit reset\n")
meta:write("pc_hook=memory.getregister('pc') sampled synchronously in write callback\n")
meta:write("dmc_hook_trace=FCEU_SoundCPUHook instrumentation in pinned FCEUX 2.7.0 source\n")
meta:flush()

local current_source_frame = -1
local sequence = 0
memory.registerwrite(0x4000, 0x18, function(address, _, value)
	local cycles = debugger.getcyclescount()
	local pc = memory.getregister("pc")
	writes:write(table.concat({sequence, current_source_frame, emu.framecount(), cycles,
		string.format("$%04X", pc), string.format("$%04X", address),
		string.format("$%02X", value or 0)}, ",") .. "\n")
	sequence = sequence + 1
end)

local ok, err = pcall(emu.poweron)
meta:write("poweron=" .. tostring(ok) .. " error=" .. tostring(err or "") .. "\n")
meta:flush()
assert(ok, "FCEUX failed to power cycle: " .. tostring(err))
debugger.resetcyclescount()
pcall(emu.speedmode, "turbo")
for frame=0,LAST_SOURCE_FRAME do
	current_source_frame = frame
	joypad.set(1, inputs[frame])
	local cycle_start = debugger.getcyclescount()
	emu.frameadvance()
	local cycle_end = debugger.getcyclescount()
	frames:write(table.concat({frame, emu.framecount(), cycle_start, cycle_end, cycle_end - cycle_start}, ",") .. "\n")
	if frame % 120 == 0 then writes:flush(); frames:flush(); meta:flush() end
end
pcall(emu.speedmode, "normal")
meta:write("done_source_frames=" .. (LAST_SOURCE_FRAME + 1) .. "\n")
meta:write("apu_write_count=" .. sequence .. "\n")
writes:close()
frames:close()
meta:close()
pcall(memory.registerwrite, 0x4000, 0x18, nil)
os.exit()

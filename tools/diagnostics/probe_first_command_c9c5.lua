-- Minimal same-input FCEUX probe: one C9C5 execution hook, no RAM watches.
-- Temporary isolation aid for diagnosing first-frame trace stalls.
local ROOT = assert(os.getenv("CT2_PROJECT_ROOT"))
local OUT = assert(os.getenv("CT2_C9C5_PROBE_OUTPUT"))
local function read(path, route)
	local result, first = {}, true
	local f = assert(io.open(path, "r"))
	for line in f:lines() do
		if first then first = false else
			local c = {}; for value in (line .. ","):gmatch("(.-),") do c[#c + 1] = value end
			local frame = tonumber(c[1])
			if frame then
				local k = route and 3 or 2
				result[frame] = {up=c[k]=="1", down=c[k+1]=="1", left=c[k+2]=="1", right=c[k+3]=="1",
					A=c[k+4]=="1", B=c[k+5]=="1", start=c[k+6]=="1", select=c[k+7]=="1"}
			end
		end
	end
	f:close(); return result
end
local inputs = read(ROOT .. "/reference/opening_reference_capture/input_timeline.csv", false)
for frame, value in pairs(read(ROOT .. "/reference/diagnostics/kickoff_select_test_20261027/post_title_inputs.csv", true)) do inputs[frame] = value end
local f = assert(io.open(OUT, "w")); f:write("source_frame,emu_frame,cycle,pc,x,p\n"); f:flush()
local count = 0
local mmc3_select = 0
local mmc3_banks = {0, 2, 4, 5, 6, 7, 0, 1}
memory.registerexec(0xC9C5, function()
	count = count + 1
	f:write(tostring(source_frame) .. "," .. tostring(emu.framecount()) .. "," .. tostring(debugger.getcyclescount()) .. "," ..
		tostring(memory.getregister("pc")) .. "," .. tostring(memory.getregister("x")) .. "," .. tostring(memory.getregister("p")) .. "\n")
	f:flush()
end)
local startup_mode = "unavailable"; pcall(function() startup_mode = tostring(movie.mode()) end)
if startup_mode ~= "nil" then pcall(movie.stop) end
assert(tostring(movie.mode()) == "nil", "startup movie active")
local powered, power_error = pcall(emu.poweron)
assert(powered, tostring(power_error))
if type(debugger.resetcyclescount) == "function" then pcall(debugger.resetcyclescount) end
pcall(emu.speedmode, "turbo")
source_frame = -1
for frame = 0, 8399 do
	source_frame = frame
	joypad.set(1, assert(inputs[frame], "missing input " .. frame))
	emu.frameadvance()
	if frame % 600 == 0 or frame == 8593 then
		local p = assert(io.open(OUT .. ".progress", "w")); p:write(tostring(frame) .. ":" .. tostring(count) .. "\n"); p:close()
	end
end
memory.registerwrite(0x8000, 1, function(_, _, value) mmc3_select = value or 0 end)
memory.registerwrite(0x8001, 1, function(_, _, value)
	mmc3_banks[(mmc3_select % 8) + 1] = value or 0
end)
for frame = 8400, 8593 do
	source_frame = frame
	joypad.set(1, assert(inputs[frame], "missing input " .. frame))
	emu.frameadvance()
	if frame % 30 == 0 or frame == 8593 then
		local p = assert(io.open(OUT .. ".progress", "w")); p:write(tostring(frame) .. ":" .. tostring(count) .. "\n"); p:close()
	end
end
f:close()
pcall(memory.registerexec, 0xC9C5, nil)
os.exit()

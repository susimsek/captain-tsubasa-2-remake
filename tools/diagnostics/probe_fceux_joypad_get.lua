-- Minimal muted probe: determine whether joypad.get(1) stalls before frame 0.
local OUT = "/tmp/ct2_f8_joypad_probe.txt"
local log = assert(io.open(OUT, "w"))
local function write(line)
	log:write(line .. "\n")
	log:flush()
end
local mode_before = "unavailable"
pcall(function() mode_before = tostring(movie.mode()) end)
if mode_before ~= "nil" then pcall(movie.stop) end
write("pre_poweron_movie_mode=" .. mode_before)
assert(rom.gethash("md5") == "eaf2b3745263efa4b1afd2b400f68dae")
local ok, err = pcall(emu.poweron)
assert(ok, tostring(err))
local mode_after = "unavailable"
pcall(function()
	mode_after = tostring(movie.mode())
	if movie.mode() ~= nil then pcall(movie.stop); mode_after = tostring(movie.mode()) end
end)
write("post_poweron_movie_mode=" .. mode_after)
assert(mode_after == "nil")
write("before_joypad_set")
joypad.set(1, {up=false,down=false,left=false,right=false,A=true,B=false,start=false,select=false})
write("after_joypad_set")
local actual = joypad.get(1)
write("after_joypad_get:" .. tostring(actual ~= nil))
for _, key in ipairs({"up","down","left","right","A","B","start","select"}) do
	write(key .. "=" .. tostring(actual and actual[key]))
end
pcall(emu.speedmode, "maximum")
write("before_frameadvance")
emu.frameadvance()
write("after_frameadvance frame=" .. tostring(emu.framecount()))
pcall(emu.speedmode, "normal")
log:close()
os.exit()

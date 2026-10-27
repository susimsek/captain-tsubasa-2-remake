-- Capture the opening from a power-on through the first title/menu sequence.
-- Run in FCEUX 2.7 with speaker output muted. The ROM itself is never modified.

local root = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe/reference/opening_capture"
local screens = root .. "/screens"
local ppu_dir = root .. "/ppu_states"
local ram_dir = root .. "/ram_states"
os.execute("mkdir -p " .. string.format("%q", screens) .. " " .. string.format("%q", ppu_dir) .. " " .. string.format("%q", ram_dir))

local function open_output(name, header)
    local f = assert(io.open(root .. "/" .. name, "w"))
    if header then f:write(header .. "\n") end
    f:flush()
    return f
end

local progress = open_output("capture.log")
local screen_index = open_output("screen_timeline.csv", "frame,raw_gd_file")
local ppu_index = open_output("ppu_state_index.csv", "frame,raw_file,bytes")
local ram_index = open_output("ram_state_index.csv", "frame,raw_file,bytes")
local apu = open_output("apu_channels.csv", "frame,channel,volume,frequency,midikey,duty,short,dmcaddress,dmcsize,dmcloop,dmcseed,register_frequency")
local input = open_output("input_timeline.csv", "frame,up,down,left,right,A,B,start,select")

local function write_error(where, err)
    progress:write("ERROR at " .. tostring(where) .. ": " .. tostring(err) .. "\n")
    progress:flush()
end

local function write_binary(folder, filename, bytes)
    local f, err = io.open(folder .. "/" .. filename, "wb")
    if not f then write_error(filename, err); return false end
    f:write(bytes)
    f:close()
    return true
end

local function truth(v) return v and 1 or 0 end
local function value(obj, key)
    local v = obj and obj[key]
    return v == nil and "" or tostring(v)
end

local previous_screen
local previous_ppu
local previous_ram

local function log_apu(frame)
    local ok, data = pcall(function() return sound.get().rp2a03 end)
    if not ok or not data then
        if frame == 1 then write_error("sound.get", data) end
        return
    end
    for _, name in ipairs({"square1", "square2", "triangle", "noise", "dpcm"}) do
        local c = data[name]
        apu:write(table.concat({frame, name, value(c, "volume"), value(c, "frequency"), value(c, "midikey"), value(c, "duty"), value(c, "short"), value(c, "dmcaddress"), value(c, "dmcsize"), value(c, "dmcloop"), value(c, "dmcseed"), value(c and c.regs, "frequency")}, ",") .. "\n")
    end
end

local function log_input(frame)
    local ok, pad = pcall(function() return joypad.read(1) end)
    if not ok or not pad then return end
    input:write(table.concat({frame, truth(pad.up), truth(pad.down), truth(pad.left), truth(pad.right), truth(pad.A), truth(pad.B), truth(pad.start), truth(pad.select)}, ",") .. "\n")
end

local function snapshot_screen(frame)
    local ok, gd = pcall(gui.gdscreenshot)
    if not ok or type(gd) ~= "string" or #gd < 12 then
        if frame == 1 then write_error("gui.gdscreenshot", gd) end
        return
    end
    -- Sample at 30 fps and only retain frames that differ from the previous sample.
    if frame % 2 ~= 0 or gd == previous_screen then return end
    previous_screen = gd
    local name = string.format("frame_%05d.gd", frame)
    if write_binary(screens, name, gd) then
        screen_index:write(frame .. "," .. name .. "\n")
    end
end

local function snapshot_state(frame)
    local ok_ppu, ppu_bytes = pcall(function()
        return ppu.readbyterange(0x2000, 0x1000) .. ppu.readbyterange(0x3F00, 0x20)
    end)
    if ok_ppu and type(ppu_bytes) == "string" and ppu_bytes ~= previous_ppu then
        previous_ppu = ppu_bytes
        local name = string.format("ppu_%05d.bin", frame)
        if write_binary(ppu_dir, name, ppu_bytes) then ppu_index:write(frame .. "," .. name .. "," .. #ppu_bytes .. "\n") end
    elseif not ok_ppu and frame == 1 then write_error("ppu.readbyterange", ppu_bytes) end

    local ok_ram, ram_bytes = pcall(function() return memory.readbyterange(0x0000, 0x0800) end)
    if ok_ram and type(ram_bytes) == "string" and ram_bytes ~= previous_ram then
        previous_ram = ram_bytes
        local name = string.format("ram_%05d.bin", frame)
        if write_binary(ram_dir, name, ram_bytes) then ram_index:write(frame .. "," .. name .. "," .. #ram_bytes .. "\n") end
    elseif not ok_ram and frame == 1 then write_error("memory.readbyterange", ram_bytes) end
end

-- Start at the same state on every run.
local ok, err = pcall(FCEU.poweron)
if not ok then write_error("FCEU.poweron", err) end

local max_frames = 2400 -- 40 seconds at NTSC rate.
local last_confirm = -1000
progress:write("START frames=" .. max_frames .. "\n")
progress:flush()

for frame = 1, max_frames do
    -- Advance dialogue screens gently; keep a brief gap between one-frame taps.
    if frame >= 90 and frame - last_confirm >= 150 then
        joypad.set(1, {A = true})
        last_confirm = frame
    else
        joypad.set(1, {A = false})
    end

    emu.frameadvance()
    local actual = emu.framecount()
    log_input(actual)
    log_apu(actual)
    snapshot_screen(actual)
    snapshot_state(actual)

    if frame % 120 == 0 then
        progress:write("CAPTURED " .. frame .. " frames; emulator=" .. actual .. "\n")
        progress:flush(); apu:flush(); input:flush(); screen_index:flush(); ppu_index:flush(); ram_index:flush()
    end
end

progress:write("DONE\n"); progress:flush()
progress:close(); screen_index:close(); ppu_index:close(); ram_index:close(); apu:close(); input:close()

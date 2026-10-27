-- Exact emulator-side dumps of the mapped PPU pattern tables, nametables, and palettes.
-- This samples the live MMC3 mapping; it does not parse or copy the ROM file.
-- Run in FCEUX with Mute Speaker Output enabled.

local root = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe/reference/opening_capture/emulator_ppu"
local states = root .. "/states"
os.execute("mkdir -p " .. string.format("%q", states))
local index = assert(io.open(root .. "/index.csv", "w"))
local log = assert(io.open(root .. "/capture.log", "w"))
index:write("frame,raw_file,pattern_bytes,nametable_palette_bytes\n")
index:flush()

local previous
local state_number = 0
local errors = 0
local function write_error(where, err)
    errors = errors + 1
    log:write("ERROR " .. tostring(where) .. ": " .. tostring(err) .. "\n")
    log:flush()
end

pcall(FCEU.poweron)
log:write("START frames=2400\n")
log:flush()

local last_confirm = -1000
for frame = 1, 2400 do
    if frame >= 90 and frame - last_confirm >= 150 then
        joypad.set(1, {A = true})
        last_confirm = frame
    else
        joypad.set(1, {A = false})
    end

    emu.frameadvance()
    local frame_number = emu.framecount()
    local ok, pattern_and_vram = pcall(function()
        return ppu.readbyterange(0x0000, 0x2000)
            .. ppu.readbyterange(0x2000, 0x1000)
            .. ppu.readbyterange(0x3F00, 0x20)
    end)
    if ok and type(pattern_and_vram) == "string" and pattern_and_vram ~= previous then
        previous = pattern_and_vram
        state_number = state_number + 1
        local filename = string.format("ppu_%05d.bin", state_number)
        local state = assert(io.open(states .. "/" .. filename, "wb"))
        state:write(pattern_and_vram)
        state:close()
        index:write(table.concat({frame_number, filename, 8192, #pattern_and_vram - 8192}, ",") .. "\n")
    elseif not ok and frame == 1 then
        write_error("ppu.readbyterange", pattern_and_vram)
    end

    if frame % 120 == 0 then
        log:write("CAPTURED " .. frame .. " frames, " .. state_number .. " states\n")
        log:flush(); index:flush()
    end
end

log:write("DONE states=" .. state_number .. " errors=" .. errors .. "\n")
log:close()
index:close()

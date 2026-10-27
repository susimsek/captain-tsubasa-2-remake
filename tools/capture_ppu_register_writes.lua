-- Diagnostic capture of CPU writes that control PPU scrolling and MMC3 CHR banks.
-- FCEUX speaker output must remain muted. This logs reference state only; Godot
-- runtime graphics still come from the supplied ROM's CHR bytes.

local root = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe/reference/opening_reference_capture"
local events = assert(io.open(root .. "/ppu_register_writes.csv", "w"))
events:write("frame,cpu_cycles,address,value\n")
events:flush()

local function hex(value)
	return string.format("0x%04X", value)
end

local function log_write(address, _size, value)
	local frame = emu.framecount()
	local ok, cycles = pcall(debugger.getcyclescount)
	if not ok then cycles = -1 end
	events:write(string.format("%d,%d,%s,0x%02X\n", frame, cycles, hex(address), value))
end

-- Capture control/mask and scroll/address/data ports. OAM bytes are already
-- preserved in the RAM snapshots, so skip the high-volume $2004 stream.
memory.registerwrite(0x2000, 2, log_write)
memory.registerwrite(0x2005, 3, log_write)

-- MMC3 bank select/data, mirroring/RAM control, IRQ latch/reload, IRQ disable/enable.
for _, address in ipairs({0x8000, 0x8001, 0xA000, 0xA001, 0xC000, 0xC001, 0xE000, 0xE001}) do
	memory.registerwrite(address, log_write)
end

emu.speedmode("turbo")
emu.poweron()
-- Existing captures place the title menu at about frame 4,692. Stop shortly
-- after it so this diagnostic run covers only cold boot through title.
for frame = 1, 5000 do
	emu.frameadvance()
	if frame % 120 == 0 then events:flush() end
end

memory.registerwrite(0x2000, 2, nil)
memory.registerwrite(0x2005, 3, nil)
for _, address in ipairs({0x8000, 0x8001, 0xA000, 0xA001, 0xC000, 0xC001, 0xE000, 0xE001}) do
	memory.registerwrite(address, 1, nil)
end

events:flush()
events:close()

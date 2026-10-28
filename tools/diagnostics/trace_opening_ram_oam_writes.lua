-- Trace source-timed RAM/OAM and PPU/mapper writes around two known visual gaps.
-- Evidence capture only: no ROM data is exported as a runtime asset.

local PROJECT_ROOT = os.getenv("CT2_PROJECT_ROOT") or "."
local ROM_PATH = PROJECT_ROOT .. "/Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local LAST_SOURCE_FRAME = 2722
local WINDOWS = {
	{first = 1534, last = 1570, name = "portrait_76"},
	{first = 2694, last = 2722, name = "bg0a_animation_7c"},
}
local SNAPSHOT_FRAMES = {
	[1534] = true, [1537] = true, [1549] = true, [1550] = true,
	[1559] = true, [1570] = true, [2694] = true, [2695] = true,
	[2700] = true, [2710] = true, [2715] = true, [2720] = true,
	[2722] = true,
}
local run_id = os.date("%Y%m%d_%H%M%S")
local out_dir = PROJECT_ROOT .. "/reference/diagnostics/ram_oam_write_trace_" .. run_id
os.execute("mkdir -p " .. string.format("%q", out_dir))

local inputs = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "missing source input timeline")
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

local function output(name, header)
	local file = assert(io.open(out_dir .. "/" .. name, "w"))
	if header then file:write(header .. "\n") end
	return file
end
local unpack_values = table.unpack or unpack
local function binary_output(name, bytes)
	local file = assert(io.open(out_dir .. "/" .. name, "wb"))
	file:write(bytes)
	file:close()
end
local function csv(values)
	local fields = {}
	for i, value in ipairs(values) do fields[i] = tostring(value or "") end
	return table.concat(fields, ",")
end
local function byte(address)
	local value = 0
	pcall(function() value = memory.readbyte(address) end)
	return value or 0
end
local function hex(value, width)
	return string.format(width == 2 and "$%02X" or "$%04X", value or 0)
end
local function register(name)
	local value = -1
	pcall(function() value = memory.getregister(name) end)
	return value or -1
end
local function cpu_pc()
	local pc = register("pc")
	return pc, hex(pc)
end

local inputs_out = output("ram_oam_writes.csv",
	"window,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,ppu_scanline,ppu_dot,cpu_pc,pc_prg_bank,address,old_value,new_value,region,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000")
local io_out = output("ppu_mmc3_writes.csv",
	"window,source_frame,emulator_frame,cycle_from_frame_start,cycle_absolute,ppu_scanline,ppu_dot,cpu_pc,address,new_value,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000")
local frames_out = output("frame_state.csv",
	"source_frame,emulator_frame,ram_0079,ram_007a,ram_007b,ram_007c,ram_007d,ram_0468_047f_hex,oam_shadow_0200_02ff_file,ppu_scanline,ppu_dot,mmc3_select,prg_8000,prg_a000,prg_c000,prg_e000")
local metadata = output("metadata.txt")

local md5, sha256 = "unavailable", "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
pcall(function() sha256 = rom.gethash("sha256") end)
metadata:write("rom_path=" .. ROM_PATH .. "\nrom_md5=" .. tostring(md5) .. "\nrom_sha256=" .. tostring(sha256) .. "\n")
metadata:write("input_timeline=" .. INPUT_CSV .. "\nsource_frames=0-" .. LAST_SOURCE_FRAME .. "\n")
metadata:write("trace_windows=1534-1570 portrait 0x76; 2694-2722 BG0A animation 0x7C\n")
metadata:write("audio=disabled by FCEUX launch flags --sound 0 --volume 0; SDL_AUDIODRIVER=dummy\n")
metadata:write("memory=CPU RAM writes to $0200-$02FF, $0460-$047F, and selected zero-page fields; PPU/MMC3 writes include PC/cycle/scanline/dot where available\n")
metadata:write("pc_prg_bank=derived from observed MMC3 R6/R7 writes and $8000 mode; verify early boot mapping against bank trace\n")
metadata:flush()

local current_source_frame = 0
local current_window = ""
local frame_cycle_start = -1
local mmc3 = {0,0,0,0,0,0,0,0}
local full_select = 0
local known = {false,false,false,false,false,false,false,false}
local function prg_map()
	local last, second = 31, 30
	local r6, r7 = mmc3[7] % 32, mmc3[8] % 32
	if math.floor(full_select / 64) % 2 == 0 then return r6, r7, second, last end
	return second, r7, r6, last
end
local function pc_bank(pc)
	local slot
	if pc >= 0xE000 then slot = 4
	elseif pc >= 0xC000 then slot = 3
	elseif pc >= 0xA000 then slot = 2
	elseif pc >= 0x8000 then slot = 1
	else return -1 end
	local r0, r1, r2, r3 = prg_map()
	if slot == 1 then return r0 end
	if slot == 2 then return r1 end
	if slot == 3 then return r2 end
	return r3
end
local function timing()
	local scanline, dot, cycles = -1, -1, -1
	if type(ppu) == "table" then
		pcall(function() scanline = ppu.getscanline() end)
		pcall(function() dot = ppu.getdot() end)
	end
	if type(debugger) == "table" and type(debugger.getcyclescount) == "function" then
		pcall(function() cycles = debugger.getcyclescount() end)
	end
	local relative = -1
	if cycles >= 0 and frame_cycle_start >= 0 then relative = cycles - frame_cycle_start end
	local frame = -1
	pcall(function() frame = emu.framecount() end)
	return frame, relative, cycles, scanline, dot
end
local function active()
	return current_window ~= ""
end

local watch = {}
local function add_watch(address, region)
	watch[address] = region
end
for address=0x0200,0x02FF do add_watch(address, "oam_shadow") end
for address=0x0460,0x047F do add_watch(address, "object_0460") end
for _, address in ipairs({0x0046,0x0047,0x004D,0x004E,0x0051,0x0052,0x0053,
	0x0057,0x0079,0x007A,0x007B,0x007C,0x007D,0x008E,0x008F,0x0090,0x0091,
	0x0094,0x0095,0x00ED}) do
	add_watch(address, "zero_page")
end
local last_value = {}
for address, region in pairs(watch) do
	local watched_address, watched_region = address, region
	memory.registerwrite(watched_address, 1, function(_, _, value)
		if not active() then return end
		local old_value = last_value[watched_address]
		local frame, relative, absolute, scanline, dot = timing()
		local pc, pc_text = cpu_pc()
		local r0, r1, r2, r3 = prg_map()
		inputs_out:write(csv({current_window,current_source_frame,frame,relative,absolute,
			scanline,dot,pc_text,pc_bank(pc),hex(watched_address,4),
			type(old_value)=="number" and hex(old_value,2) or "",hex(value or 0,2),watched_region,
			hex(full_select,2),hex(r0,2),hex(r1,2),hex(r2,2),hex(r3,2)}) .. "\n")
		last_value[watched_address] = value or 0
	end)
end

local io_names = {
	[0x2000]="PPUCTRL", [0x2001]="PPUMASK", [0x2005]="PPUSCROLL",
	[0x2006]="PPUADDR", [0x2007]="PPUDATA", [0x4014]="OAMDMA",
	[0x8000]="MMC3_SELECT", [0x8001]="MMC3_DATA", [0xA000]="MMC3_MIRROR",
	[0xA001]="MMC3_RAM", [0xC000]="MMC3_IRQ_LATCH", [0xC001]="MMC3_IRQ_RELOAD",
	[0xE000]="MMC3_IRQ_DISABLE", [0xE001]="MMC3_IRQ_ENABLE",
}
for address, name in pairs(io_names) do
	local watched_address, event_name = address, name
	memory.registerwrite(watched_address, 1, function(_, _, value)
		if watched_address == 0x8000 then
			full_select = value or 0
		elseif watched_address == 0x8001 then
			local index = full_select % 8 + 1
			mmc3[index] = value or 0
			known[index] = true
		end
		if not active() then return end
		local frame, relative, absolute, scanline, dot = timing()
		local pc, pc_text = cpu_pc()
		local r0, r1, r2, r3 = prg_map()
		io_out:write(csv({current_window,current_source_frame,frame,relative,absolute,
			scanline,dot,pc_text,hex(watched_address,4),hex(value or 0,2),hex(full_select,2),
			hex(r0,2),hex(r1,2),hex(r2,2),hex(r3,2)}) .. "\n")
	end)
end

local power_ok, power_error = pcall(emu.poweron)
if type(debugger) == "table" and type(debugger.resetcyclescount) == "function" then
	pcall(debugger.resetcyclescount)
end
metadata:write("poweron_success=" .. tostring(power_ok) .. "\npoweron_error=" .. tostring(power_error or "") .. "\n")
pcall(emu.speedmode, "turbo")

for source_frame=0,LAST_SOURCE_FRAME do
	current_source_frame = source_frame
	current_window = ""
	for _, window in ipairs(WINDOWS) do
		if source_frame >= window.first and source_frame <= window.last then
			current_window = window.name
			break
		end
	end
	if active() then
		for address in pairs(watch) do last_value[address] = byte(address) end
	end
	joypad.set(1, inputs[source_frame])
	frame_cycle_start = -1
	if type(debugger) == "table" and type(debugger.getcyclescount) == "function" then
		pcall(function() frame_cycle_start = debugger.getcyclescount() end)
	end
	emu.frameadvance()
	if SNAPSHOT_FRAMES[source_frame] then
		local frame = emu.framecount()
		local r0, r1, r2, r3 = prg_map()
		local object = {}
		for address=0x0468,0x047F do object[#object+1] = string.format("%02X", byte(address)) end
		local oam = {}
		for address=0x0200,0x02FF do oam[#oam+1] = string.char(byte(address)) end
		local oam_file = string.format("oam_shadow_%05d.bin", source_frame)
		binary_output(oam_file, table.concat(oam))
		local scanline, dot = -1, -1
		if type(ppu) == "table" then
			pcall(function() scanline = ppu.getscanline() end)
			pcall(function() dot = ppu.getdot() end)
		end
		frames_out:write(csv({source_frame,frame,hex(byte(0x0079),2),hex(byte(0x007A),2),
			hex(byte(0x007B),2),hex(byte(0x007C),2),hex(byte(0x007D),2),
			table.concat(object," "),oam_file,scanline,dot,hex(full_select,2),
			hex(r0,2),hex(r1,2),hex(r2,2),hex(r3,2)}) .. "\n")
	end
	if source_frame % 120 == 0 then
		inputs_out:flush(); io_out:flush(); frames_out:flush(); metadata:flush()
	end
end

local mask = 0
for i=1,8 do if known[i] then mask = mask + 2^(i-1) end end
metadata:write("completed_source_frames=" .. (LAST_SOURCE_FRAME + 1) .. "\n")
metadata:write(string.format("mapper_known_register_mask=%02X\n", mask))
inputs_out:close(); io_out:close(); frames_out:close(); metadata:close()
for address in pairs(watch) do pcall(memory.registerwrite,address,1,nil) end
for address in pairs(io_names) do pcall(memory.registerwrite,address,1,nil) end
os.exit()

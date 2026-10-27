-- Short, silent API smoke check for the installed FCEUX 2.7.0 Lua build.
-- Launch with --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy.
local OUTPUT_PATH = "/tmp/ct2_fceux_lua_instruction_api_probe.txt"
local PROBE_PC = 0xC68A
local output = assert(io.open(OUTPUT_PATH, "w"))

local function api_type(value)
	return type(value)
end

local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
output:write("fceux=2.7.0 installed Homebrew build\n")
output:write("rom_md5=" .. tostring(md5) .. "\n")
output:write("memory.registerexec=" .. api_type(memory.registerexec) .. "\n")
output:write("memory.getregister=" .. api_type(memory.getregister) .. "\n")
output:write("debugger.getcyclescount=" .. api_type(debugger.getcyclescount) .. "\n")
output:write("debugger.getinstructionscount=" .. api_type(debugger.getinstructionscount) .. "\n")

local hits = 0
if api_type(memory.registerexec) == "function" then
	memory.registerexec(PROBE_PC, 1, function()
		hits = hits + 1
		local pc_ok, pc = pcall(memory.getregister, "pc")
		local cycle_ok, cycles = pcall(debugger.getcyclescount)
		local instruction_ok, instructions = pcall(debugger.getinstructionscount)
		local opcode = memory.readbyte(PROBE_PC)
		output:write(string.format(
			"exec_hit=%d pc_ok=%s pc=$%04X cycle_ok=%s cycles=%s instruction_ok=%s instructions=%s opcode=$%02X\n",
			hits, tostring(pc_ok), tonumber(pc) or 0, tostring(cycle_ok), tostring(cycles),
			tostring(instruction_ok), tostring(instructions), opcode))
	end)
end

local power_ok, power_error = pcall(emu.poweron)
output:write("poweron_ok=" .. tostring(power_ok) .. " error=" .. tostring(power_error or "") .. "\n")
if type(debugger.resetcyclescount) == "function" then
	local reset_ok, reset_error = pcall(debugger.resetcyclescount)
	output:write("resetcycles_ok=" .. tostring(reset_ok) .. " error=" .. tostring(reset_error or "") .. "\n")
end
pcall(emu.speedmode, "turbo")
for _frame = 1, 10 do emu.frameadvance() end
pcall(emu.speedmode, "normal")
output:write("probe_pc=$" .. string.format("%04X", PROBE_PC) .. " hits=" .. tostring(hits) .. "\n")
output:close()
pcall(memory.registerexec, PROBE_PC, 1, nil)
os.exit()

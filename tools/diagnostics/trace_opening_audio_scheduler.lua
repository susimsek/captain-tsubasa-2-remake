-- Silent diagnostic: trace the supplied ROM's cutscene scheduler and Start poll.
-- Requires FCEUX 2.7.0 Lua memory.registerexec and a muted/dummy-audio launch.
local PROJECT_ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local LAST_SOURCE_FRAME = 4692
local run_id = os.date("%Y%m%d_%H%M%S")
local root = PROJECT_ROOT .. "/reference/diagnostics/audio_scheduler_trace_" .. run_id
os.execute("mkdir -p " .. string.format("%q", root))

local inputs = {}
local source = assert(io.open(INPUT_CSV, "r"), "missing source input timeline")
for line in source:lines() do
	local frame, up, down, left, right, a, b, start, select = line:gsub("\r$", ""):match(
		"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if frame then
		inputs[tonumber(frame)] = {up=up=="1",down=down=="1",left=left=="1",right=right=="1",
			A=a=="1",B=b=="1",start=start=="1",select=select=="1"}
	end
end
source:close()
for frame=0,LAST_SOURCE_FRAME do assert(inputs[frame], "missing input frame " .. frame) end

local frames = assert(io.open(root .. "/frame_state.csv", "w"))
frames:write("source_frame,emulator_frame_after,up,down,left,right,A,B,start,select,script_pointer,text_speed,sound_queue,start_latch,controller_bits,visual_delay\n")
local hits_file = assert(io.open(root .. "/exec_counts.csv", "w"))
hits_file:write("source_frame,emulator_frame,name,cpu_address,hits,script_pointer,text_speed,sound_queue,start_latch,controller_bits\n")
local queue = assert(io.open(root .. "/queue_writes.csv", "w"))
queue:write("source_frame,emulator_frame,cpu_pc,sound_id,script_pointer,text_speed,start_latch,controller_bits\n")
local meta = assert(io.open(root .. "/metadata.txt", "w"))
local md5 = "unavailable"; pcall(function() md5 = rom.gethash("md5") end)
meta:write("rom_md5=" .. tostring(md5) .. "\nsource_inputs=" .. INPUT_CSV .. "\nsource_frame_range=0-" .. LAST_SOURCE_FRAME .. "\n")
meta:write("sound_output=disabled with --sound 0 --volume 0; SDL_AUDIODRIVER=dummy\n")
meta:write("exec_hooks=$8027 Start poll loop entry; $802C Start RAM load; $8030 Start branch; $8032 Start-set continuation; $8048 title-entry sound-stop store; $84E7 cutscene bytecode dispatch; $895D text-speed wait; $899A compact-pause wait; $9FA8 cooperative scheduler yield\n")
meta:write("interpretation=CPU addresses are checked against the supplied ROM; frame/input/replay association is recorded per source frame; no runtime assets are read or modified\n")
meta:flush()

local current_source_frame = 0
local names = {
	[0x8027]="start_poll_loop_entry", [0x802C]="start_ram_load", [0x8030]="start_poll_branch",
	[0x8032]="start_set_continuation", [0x8048]="title_stop_store", [0x84E7]="cutscene_dispatch",
	[0x895D]="text_speed_wait", [0x899A]="compact_pause_wait", [0x9FA8]="cooperative_yield",
}
local hit_counts = {}
local function state()
	local lo=memory.readbyte(0x004D); local hi=memory.readbyte(0x004E)
	return string.format("$%04X", lo + hi*256), memory.readbyte(0x0055), memory.readbyte(0x0700),
		memory.readbyte(0x001B), memory.readbyte(0x001E), memory.readbyte(0x000D)
end
for address,name in pairs(names) do
	memory.registerexec(address, function()
		local f=emu.framecount()
		local key=tostring(current_source_frame)..":"..name
		hit_counts[key]=(hit_counts[key] or 0)+1
	end)
end
memory.registerwrite(0x0700, 1, function(_,_,value)
	local ptr,speed,_,start_latch,buttons=state()
	local pc=""; pcall(function() pc=string.format("$%04X", memory.getregister("pc")) end)
	queue:write(table.concat({current_source_frame,tostring(emu.framecount()),pc,string.format("$%02X",value or 0),ptr,speed,start_latch,buttons},",").."\n")
end)

local ok,err=pcall(emu.poweron)
meta:write("poweron="..tostring(ok).." error="..tostring(err or "").."\n")
meta:flush()
pcall(emu.speedmode,"turbo")
for frame=0,LAST_SOURCE_FRAME do
	current_source_frame=frame
	local pad=inputs[frame]
	joypad.set(1,pad)
	emu.frameadvance()
	local ef=emu.framecount()
	local ptr,speed,sound,start_latch,buttons,visual_delay=state()
	local bits={pad.up,pad.down,pad.left,pad.right,pad.A,pad.B,pad.start,pad.select}
	for i=1,#bits do bits[i]=bits[i] and "1" or "0" end
	frames:write(table.concat({frame,ef,table.concat(bits,","),ptr,speed,string.format("$%02X",sound),start_latch,buttons,visual_delay},",").."\n")
	for address,name in pairs(names) do
		local key=tostring(frame)..":"..name
		local count=hit_counts[key] or 0
		if count>0 then
			hits_file:write(table.concat({frame,ef,name,string.format("$%04X",address),count,ptr,speed,string.format("$%02X",sound),start_latch,buttons},",").."\n")
			hit_counts[key]=nil
		end
	end
	if frame%120==0 then frames:flush(); hits_file:flush(); queue:flush(); meta:flush() end
end
pcall(emu.speedmode,"normal")
meta:write("done_frames="..(LAST_SOURCE_FRAME+1).."\n")
frames:close(); hits_file:close(); queue:close(); meta:close()
for address in pairs(names) do pcall(memory.registerexec,address,1,nil) end
pcall(memory.registerwrite,0x0700,1,nil)
os.exit()

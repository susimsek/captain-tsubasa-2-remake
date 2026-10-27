-- Silent source-provenance trace for cutscene ED/FC dispatch and MMC3 banks.
-- No ROM bytes are written and no captured media is used as a runtime asset.
local PROJECT_ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
local INPUT_CSV = PROJECT_ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local LAST_SOURCE_FRAME = 4692
local run_id = os.date("%Y%m%d_%H%M%S")
local out_dir = PROJECT_ROOT .. "/reference/diagnostics/audio_command_context_" .. run_id
os.execute("mkdir -p " .. string.format("%q", out_dir))

local inputs = {}
local input_file = assert(io.open(INPUT_CSV, "r"), "missing input timeline")
for line in input_file:lines() do
	local frame, up, down, left, right, a, b, start, select = line:gsub("\r$", ""):match(
		"^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if frame then inputs[tonumber(frame)] = {up=up=="1",down=down=="1",left=left=="1",right=right=="1",A=a=="1",B=b=="1",start=start=="1",select=select=="1"} end
end
input_file:close()
for f=0,LAST_SOURCE_FRAME do assert(inputs[f], "missing input frame " .. f) end

local log = assert(io.open(out_dir .. "/dispatch_context.csv", "w"))
log:write("source_frame,emulator_frame,event,pc,ptr,script_opcode,script_arg,live_a000,live_a0c7,live_a0ca,live_a11c,live_a159,live_a1c3,live_8836,live_8837,live_85eb,live_85ec,register_a,register_x,register_y,mmc3_select,mmc3_r0,mmc3_r1,mmc3_r2,mmc3_r3,mmc3_r4,mmc3_r5,mmc3_r6,mmc3_r7\n")
local meta = assert(io.open(out_dir .. "/metadata.txt", "w"))
local md5 = "unavailable"; pcall(function() md5 = rom.gethash("md5") end)
meta:write("rom_md5=" .. tostring(md5) .. "\ninput=" .. INPUT_CSV .. "\nframes=0-" .. LAST_SOURCE_FRAME .. "\naudio=disabled (--sound 0 --volume 0; SDL_AUDIODRIVER=dummy)\n")
meta:write("Hooks: $84E7 interpreter dispatch; $8837 FC vector target (table value $8836, RTS +1); $85EC ED vector target (table value $85EB, RTS +1); $85FA ED argument load; $85FC queue STA; $8879 common pointer-advance path. MMC3 $8000/$8001 writes recorded.\n")

local current_source_frame=0
local mmc3_select=0
local mmc3={0,0,0,0,0,0,0,0}
local function reg(name)
	local v; pcall(function() v=memory.getregister(name) end); return v or -1
end
local function b(addr) local v; pcall(function() v=memory.readbyte(addr) end); return v or 0 end
local function word(addr) return b(addr)+256*b(addr+1) end
local function log_event(kind)
	local ptr=word(0x004d)
	local opcode,arg=0,0
	if ptr>=0xa000 and ptr<=0xbffe then opcode=b(ptr); arg=b(ptr+1) end
	local vals={current_source_frame,emu.framecount(),kind,string.format("$%04X",reg("pc")),string.format("$%04X",ptr),string.format("$%02X",opcode),string.format("$%02X",arg),string.format("$%02X",b(0xa000)),string.format("$%02X",b(0xa0c7)),string.format("$%02X",b(0xa0ca)),string.format("$%02X",b(0xa11c)),string.format("$%02X",b(0xa159)),string.format("$%02X",b(0xa1c3)),string.format("$%02X",b(0x8836)),string.format("$%02X",b(0x8837)),string.format("$%02X",b(0x85eb)),string.format("$%02X",b(0x85ec)),reg("a"),reg("x"),reg("y"),string.format("$%02X",mmc3_select)}
	for i=1,8 do vals[#vals+1]=string.format("$%02X",mmc3[i]) end
	log:write(table.concat(vals,",").."\n")
end

for address,kind in pairs({[0x84e7]="dispatch",[0x8837]="fc_target",[0x85ec]="ed_target",[0x85fa]="ed_load_arg",[0x85fc]="ed_queue_store",[0x8879]="common_advance"}) do
	memory.registerexec(address,function() log_event(kind) end)
end
memory.registerwrite(0x8000,1,function(_,_,value) mmc3_select=(value or 0)%8 end)
memory.registerwrite(0x8001,1,function(_,_,value) mmc3[mmc3_select+1]=value or 0 end)

local ok,err=pcall(emu.poweron)
meta:write("poweron="..tostring(ok).." error="..tostring(err or "").."\n")
meta:flush()
pcall(emu.speedmode,"turbo")
for f=0,LAST_SOURCE_FRAME do
	current_source_frame=f
	joypad.set(1,inputs[f])
	emu.frameadvance()
	if f%120==0 then log:flush(); meta:flush() end
end
pcall(emu.speedmode,"normal")
meta:write("done_frames="..(LAST_SOURCE_FRAME+1).."\n")
log:close(); meta:close()
for address in pairs({[0x84e7]=true,[0x8837]=true,[0x85ec]=true,[0x85fa]=true,[0x85fc]=true,[0x8879]=true}) do pcall(memory.registerexec,address,1,nil) end
pcall(memory.registerwrite,0x8000,1,nil); pcall(memory.registerwrite,0x8001,1,nil)
os.exit()

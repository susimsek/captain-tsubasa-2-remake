-- Silent bounded CPU-PC trace around the captured Start-to-title handoff.
-- Replays original captured inputs from power-on; PC hooks are installed only
-- after source frame 4660 to keep the instrumentation window small.
local ROOT = "/Users/T097315/Documents/Captain Tsubasa 2 Super Striker Türkçe"
local INPUT_CSV = ROOT .. "/reference/opening_reference_capture/input_timeline.csv"
local LAST_FRAME = 4692
local TRACE_START = 4661
local TRACE_END = 4692
local out = ROOT .. "/reference/diagnostics/title_transition_pc_" .. os.date("%Y%m%d_%H%M%S")
os.execute("mkdir -p " .. string.format("%q", out))
local inputs={}
for line in assert(io.open(INPUT_CSV,"r")):lines() do
 local f,u,d,l,r,a,b,s,sel=line:gsub("\r$",""):match("^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
 if f then inputs[tonumber(f)]={up=u=="1",down=d=="1",left=l=="1",right=r=="1",A=a=="1",B=b=="1",start=s=="1",select=sel=="1"} end
end
for f=0,LAST_FRAME do assert(inputs[f],"missing input frame "..f) end
local trace=assert(io.open(out.."/pc_trace.csv","w"))
trace:write("source_frame,emulator_frame,pc,script_ptr,script_byte,script_arg,a,x,y,s,p,mmc3_select,r6,r7,prg_8000,prg_a000,prg_c000,prg_e000\n")
local frames=assert(io.open(out.."/frame_state.csv","w"))
frames:write("source_frame,emulator_frame,script_ptr,input_start,pc_at_boundary\n")
local meta=assert(io.open(out.."/metadata.txt","w"))
local md5="unavailable"; pcall(function() md5=rom.gethash("md5") end)
meta:write("rom_md5="..md5.."\ninputs="..INPUT_CSV.."\nreplay=poweron, source frames 0-4692\naudio=disabled by --sound 0 --volume 0 and SDL_AUDIODRIVER=dummy\ntrace_window="..TRACE_START.."-"..TRACE_END.."; all CPU ROM PCs $8000-$FFFF hooked only after frame 4660\n")
local source=0; local select=0; local regs={0,0,0,0,0,0,0,0}; local registered=false
local function b(a) local v=0; pcall(function() v=memory.readbyte(a) end); return v or 0 end
local function word(a) return b(a)+256*b(a+1) end
local function reg(n) local v=-1; pcall(function() v=memory.getregister(n) end); return v or -1 end
local function mapped()
 local r6,r7=regs[7]%32,regs[8]%32
 if math.floor(select/64)%2==0 then return r6,r7,30,31 else return 30,r7,r6,31 end
end
local function csv(t) local x={}; for i,v in ipairs(t) do x[i]=tostring(v or "") end; return table.concat(x,",") end
local function install()
 if registered then return end; registered=true
 for address=0x8000,0xffff do
  local pc_address=address
  memory.registerexec(pc_address,function()
   if source<TRACE_START or source>TRACE_END then return end
   local a,c,d,e=mapped(); local p=word(0x004d)
   local op,arg=0,0; if p>=0xa000 and p<=0xbffe then op=b(p);arg=b(p+1) end
   trace:write(csv({source,emu.framecount(),string.format("$%04X",reg("pc")),string.format("$%04X",p),string.format("$%02X",op),string.format("$%02X",arg),reg("a"),reg("x"),reg("y"),reg("s"),reg("p"),string.format("$%02X",select),string.format("$%02X",regs[7]),string.format("$%02X",regs[8]),string.format("$%02X",a),string.format("$%02X",c),string.format("$%02X",d),string.format("$%02X",e)}).."\n")
  end)
 end
end
memory.registerwrite(0x8000,1,function(_,_,v) select=v or 0 end)
memory.registerwrite(0x8001,1,function(_,_,v) regs[select%8+1]=v or 0 end)
pcall(emu.poweron); pcall(emu.speedmode,"turbo")
for f=0,LAST_FRAME do
 source=f
 if f==4660 then install(); meta:write("pc_hooks_installed_after_source_frame=4660\n");meta:flush() end
 joypad.set(1,inputs[f]); emu.frameadvance()
 local p=word(0x004d)
 frames:write(csv({f,emu.framecount(),string.format("$%04X",p),inputs[f].start and 1 or 0,string.format("$%04X",reg("pc"))}).."\n")
 if f%120==0 then trace:flush();frames:flush() end
end
meta:write("completed_source_frames="..(LAST_FRAME+1).."\n");meta:flush();trace:close();frames:close();meta:close();os.exit()

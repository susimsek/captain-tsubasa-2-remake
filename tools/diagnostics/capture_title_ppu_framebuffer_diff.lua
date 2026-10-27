-- Captures only the FCEUX emulator framebuffer at source-frame indices 4691
-- and 4692, then reports the first RGB change/nonblack pixel. It replays the
-- supplied per-frame input timeline; audio is disabled by the launch command.
local input_path = assert(os.getenv("CT2_INPUT_TIMELINE"), "CT2_INPUT_TIMELINE is required")
local output_path = assert(os.getenv("CT2_TITLE_FRAMEBUFFER_DIFF_OUT"), "CT2_TITLE_FRAMEBUFFER_DIFF_OUT is required")
local last_source_frame = 4692
local inputs = {}
local file = assert(io.open(input_path, "r"), "missing source input timeline")
for line in file:lines() do
  local frame, up, down, left, right, a, b, start, select = line:gsub("\r$", ""):match("^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
  if frame then
    inputs[tonumber(frame)] = {up=up=="1", down=down=="1", left=left=="1", right=right=="1", A=a=="1", B=b=="1", start=start=="1", select=select=="1"}
  end
end
file:close()
for frame=0,last_source_frame do assert(inputs[frame], "missing source input frame " .. frame) end

local function capture_framebuffer()
  local chunks = {}
  for y=0,239 do
    for x=0,255 do
      local r, g, b, palette = emu.getscreenpixel(x, y, true)
      if palette == 254 then error("emu.getscreenpixel failed at " .. x .. "," .. y) end
      chunks[#chunks + 1] = string.char(r, g, b, palette)
    end
  end
  return table.concat(chunks)
end

local md5 = "unavailable"
pcall(function() md5 = rom.gethash("md5") end)
local out = assert(io.open(output_path, "w"))
out:write("rom_md5=" .. tostring(md5) .. "\nsource_frames=0-4692\naudio=disabled at process launch\n")
local ok, err = pcall(emu.poweron)
out:write("poweron_success=" .. tostring(ok) .. " error=" .. tostring(err or "") .. "\n")
pcall(emu.speedmode, "turbo")
local previous = nil
local previous_emulator_frame = nil
local current = nil
local current_emulator_frame = nil
for frame=0,last_source_frame do
  joypad.set(1, inputs[frame])
  emu.frameadvance()
  if frame == 4691 then
    previous = capture_framebuffer()
    previous_emulator_frame = emu.framecount()
  elseif frame == 4692 then
    current = capture_framebuffer()
    current_emulator_frame = emu.framecount()
  end
end
assert(previous and current, "did not capture both requested frames")
out:write("frame_4691_emulator_frame=" .. tostring(previous_emulator_frame) .. "\n")
out:write("frame_4692_emulator_frame=" .. tostring(current_emulator_frame) .. "\n")

local first_change = nil
local first_nonblack = nil
local first_visible_change = nil
local first_visible_nonblack = nil
local changed_rgb = 0
local visible_changed_rgb = 0
local previous_black_count = 0
local current_black_count = 0
local previous_visible_black_count = 0
local current_visible_black_count = 0
for i=1,#current,4 do
  local r0, g0, b0, p0 = string.byte(previous, i, i + 3)
  local r1, g1, b1, p1 = string.byte(current, i, i + 3)
  local pixel_index = (i - 1) / 4
  local x = pixel_index % 256
  local y = math.floor(pixel_index / 256)
  if r0 == 0 and g0 == 0 and b0 == 0 then previous_black_count = previous_black_count + 1 end
  if r1 == 0 and g1 == 0 and b1 == 0 then current_black_count = current_black_count + 1 end
  local in_ntsc_visible_crop = y >= 8 and y <= 231
  if in_ntsc_visible_crop then
    if r0 == 0 and g0 == 0 and b0 == 0 then previous_visible_black_count = previous_visible_black_count + 1 end
    if r1 == 0 and g1 == 0 and b1 == 0 then current_visible_black_count = current_visible_black_count + 1 end
  end
  if r0 ~= r1 or g0 ~= g1 or b0 ~= b1 then
    changed_rgb = changed_rgb + 1
    if not first_change then first_change = {x=x, y=y, dot=x + 1, before_palette=p0, after_palette=p1, before_rgb={r0,g0,b0}, after_rgb={r1,g1,b1}} end
    if in_ntsc_visible_crop then
      visible_changed_rgb = visible_changed_rgb + 1
      if not first_visible_change then first_visible_change = {x=x, y=y, dot=x + 1, before_palette=p0, after_palette=p1, before_rgb={r0,g0,b0}, after_rgb={r1,g1,b1}} end
    end
  end
  if not first_nonblack and (r1 ~= 0 or g1 ~= 0 or b1 ~= 0) then
    first_nonblack = {x=x, y=y, dot=x + 1, palette=p1, rgb={r1,g1,b1}}
  end
  if in_ntsc_visible_crop and not first_visible_nonblack and (r1 ~= 0 or g1 ~= 0 or b1 ~= 0) then
    first_visible_nonblack = {x=x, y=y, dot=x + 1, palette=p1, rgb={r1,g1,b1}}
  end
end
local function write_pixel(name, p)
  if not p then out:write(name .. "=none\n"); return end
  local rgb = p.rgb or p.after_rgb
  out:write(string.format("%s=x%d,y%d,mapped_dot%d,palette=$%02X,rgb=%d/%d/%d\n", name, p.x, p.y, p.dot, p.palette or p.after_palette, rgb[1], rgb[2], rgb[3]))
end
out:write("frame_4691_black_pixels=" .. tostring(previous_black_count) .. "/61440\n")
out:write("frame_4692_black_pixels=" .. tostring(current_black_count) .. "/61440\n")
out:write("changed_rgb_pixel_count=" .. tostring(changed_rgb) .. "/61440\n")
out:write("frame_4691_visible_crop_black_pixels=" .. tostring(previous_visible_black_count) .. "/57344\n")
out:write("frame_4692_visible_crop_black_pixels=" .. tostring(current_visible_black_count) .. "/57344\n")
out:write("visible_crop_changed_rgb_pixel_count=" .. tostring(visible_changed_rgb) .. "/57344\n")
write_pixel("first_rgb_change_4691_to_4692", first_change)
write_pixel("first_nonblack_4692", first_nonblack)
write_pixel("first_rgb_change_4691_to_4692_visible_crop_y8_231", first_visible_change)
write_pixel("first_nonblack_4692_visible_crop_y8_231", first_visible_nonblack)
out:flush()
out:close()
pcall(emu.speedmode, "normal")
FCEU.pause()
os.exit()

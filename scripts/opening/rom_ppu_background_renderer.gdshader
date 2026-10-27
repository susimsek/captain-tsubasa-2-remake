shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D chr_atlas : filter_nearest;
uniform sampler2D ppu_bytes : filter_nearest;
uniform sampler2D palette_rgba : filter_nearest;
uniform sampler2D scanline_state : filter_nearest;
uniform vec2 initial_mmc3_selectors = vec2(0.0);
uniform vec4 mmc3_writes[8];
uniform int mmc3_write_count = 0;
uniform bool mmc3_writes_active = false;
uniform int raster_split_scanline = -1;
uniform vec4 upper_chr_banks = vec4(0.0);
uniform vec4 lower_chr_banks = vec4(0.0);

int byte_at(sampler2D source, int x, int y, ivec2 dimensions) {
	vec2 uv = (vec2(float(x), float(y)) + vec2(0.5)) / vec2(dimensions);
	return int(floor(textureLod(source, uv, 0.0).r * 255.0 + 0.5));
}

int chr_pixel(int bank, int tile_id, int pixel_x, int pixel_y) {
	int tile = bank * 64 + (tile_id & 63);
	int tx = (tile & 31) * 8 + pixel_x;
	int ty = (tile >> 5) * 8 + pixel_y;
	return byte_at(chr_atlas, tx, ty, ivec2(256, 2048));
}

int vector_component(vec4 banks, int index) {
	// Godot receives these uniforms as raw 1 KiB bank numbers, not normalized
	// byte samples. Preserve the integer value written by the CPU presenter.
	if (index == 0) {
		return int(floor(banks.r + 0.5));
	}
	if (index == 1) {
		return int(floor(banks.g + 0.5));
	}
	if (index == 2) {
		return int(floor(banks.b + 0.5));
	}
	return int(floor(banks.a + 0.5));
}

ivec2 selectors_at(int scanline, int dot) {
	int r0 = int(floor(initial_mmc3_selectors.x + 0.5));
	int r1 = int(floor(initial_mmc3_selectors.y + 0.5));
	for (int i = 0; i < 8; i++) {
		if (i >= mmc3_write_count) {
			break;
		}
		vec4 event = mmc3_writes[i];
		int event_line = int(floor(event.x + 0.5));
		int event_dot = int(floor(event.y + 0.5));
		if (event_line > scanline || (event_line == scanline && event_dot > dot)) {
			break;
		}
		if (int(floor(event.z + 0.5)) == 0) {
			r0 = int(floor(event.w + 0.5));
		} else {
			r1 = int(floor(event.w + 0.5));
		}
	}
	return ivec2(r0, r1);
}

int bank_from_selectors(ivec2 selectors, int slot) {
	if (slot < 2) {
		return (selectors.x & 254) + (slot & 1);
	}
	return (selectors.y & 254) + (slot & 1);
}

void fragment() {
	int screen_x = clamp(int(floor(UV.x * 256.0)), 0, 255);
	int screen_y = clamp(int(floor(UV.y * 240.0)), 0, 239);
	vec4 line = textureLod(scanline_state,
		vec2(0.5, (float(screen_y) + 0.5) / 240.0), 0.0);
	int world_x = (int(floor(line.r + 0.5)) + screen_x) & 511;
	int tile_y = int(floor(line.g + 0.5)) & 31;
	int pixel_y = int(floor(line.b + 0.5)) & 7;
	int line_state = int(floor(line.a + 0.5));
	int vertical_nt = line_state >> 3;
	int fine_x = line_state & 7;
	int local_x = world_x & 255;
	int tile_x = local_x >> 3;
	int pixel_x = local_x & 7;
	int nametable_base = (vertical_nt << 11) + ((world_x >> 8) << 10);
	int tile_offset = (nametable_base + (tile_y << 5) + tile_x) & 4095;
	int tile_id = byte_at(ppu_bytes, tile_offset & 63, tile_offset >> 6,
		ivec2(64, 64));
	int attribute_offset = (nametable_base + 0x3c0 + ((tile_y >> 2) << 3)
		+ (tile_x >> 2)) & 4095;
	int attribute = byte_at(ppu_bytes, attribute_offset & 63,
		attribute_offset >> 6, ivec2(64, 64));
	int quadrant_x = (tile_x & 3) >> 1;
	int quadrant_y = (tile_y & 3) >> 1;
	int palette_shift = (quadrant_y * 2 + quadrant_x) * 2;
	int subpalette = (attribute >> palette_shift) & 3;
	int record_slot = clamp((screen_x + fine_x) >> 3, 0, 32);
	int bank_slot = tile_id >> 6;
	int fetch_line = screen_y + (record_slot < 2 ? 0 : 1);
	int low_dot = record_slot < 2 ? 324 + record_slot * 8
		: 4 + (record_slot - 2) * 8;
	int low_bank = 0;
	int high_bank = 0;
	if (mmc3_writes_active) {
		ivec2 low_selectors = selectors_at(fetch_line, low_dot);
		ivec2 high_selectors = selectors_at(fetch_line, low_dot + 2);
		low_bank = bank_from_selectors(low_selectors, bank_slot);
		high_bank = bank_from_selectors(high_selectors, bank_slot);
	} else {
		vec4 banks = upper_chr_banks;
		if (raster_split_scanline >= 0 && screen_y >= raster_split_scanline) {
			banks = lower_chr_banks;
		}
		low_bank = vector_component(banks, bank_slot);
		high_bank = low_bank;
	}
	int low_pixel = chr_pixel(low_bank, tile_id, pixel_x, pixel_y);
	int high_pixel = chr_pixel(high_bank, tile_id, pixel_x, pixel_y);
	int color_index = (low_pixel & 1) | (high_pixel & 2);
	int palette_slot = color_index == 0 ? 0 : subpalette * 4 + color_index;
	vec4 color = textureLod(palette_rgba,
		vec2((float(palette_slot) + 0.5) / 16.0, 0.5), 0.0);
	COLOR = color;
}

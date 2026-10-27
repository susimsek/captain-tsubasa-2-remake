extends RefCounted
class_name F8TitleIrqTimingModel
## Computes the title split from the bank-2 MMC3 IRQ path and the PPU frame
## phase. This is a source model with a small capture-calibrated startup phase;
## it does not read emulator captures or use captured pixels as runtime data.

const NES_PPU_SCANLINES_PER_FRAME := 262
const FIRST_RASTER_HANDLER_SCANLINE_BIAS := -1
const FIRST_PALETTE_UPLOAD_RESTART_SCANLINES := 7
const FIRST_LOOP_DECREMENT_SCANLINE := 16
const SECOND_LOOP_DECREMENT_SCANLINE := 18
const IRQ_HANDLER_TO_ADDRESS_WRITE_CPU_CYCLES := 56


static func calculate(
		ram_0079_after_tick: int,
		ram_007C_after_tick: int,
		motion_steps: int,
		palette_upload_committed_this_frame: bool
) -> Dictionary:
	# ROM `$A4FE` increments `$79` and decrements `$7C` twice, as separate
	# instructions. `$A19E` is the first split's PPUCTRL write; the next line is
	# where `$A1BF` reloads MMC3 from the doubled `$7C` marker.
	var first_irq_scanline := (2 * ram_0079_after_tick + FIRST_RASTER_HANDLER_SCANLINE_BIAS) \
			% NES_PPU_SCANLINES_PER_FRAME
	var restart_phase_scanlines := FIRST_PALETTE_UPLOAD_RESTART_SCANLINES \
			if palette_upload_committed_this_frame else 0
	first_irq_scanline = (first_irq_scanline + restart_phase_scanlines) \
			% NES_PPU_SCANLINES_PER_FRAME
	var counter_reload_scanline := (first_irq_scanline + 1) \
			% NES_PPU_SCANLINES_PER_FRAME

	var completed_loop_decrements := 0
	var marker_before_loop_tick := ram_007C_after_tick
	if motion_steps > 0:
		# Undo the two writes that have completed by the frame-end RAM sample.
		# The live IRQ can land between these separate ROM DEC instructions as
		# the `$79`-derived first split moves down the display.
		marker_before_loop_tick = (marker_before_loop_tick + 2) & 0xFF
		if not palette_upload_committed_this_frame:
			if counter_reload_scanline >= FIRST_LOOP_DECREMENT_SCANLINE:
				completed_loop_decrements += 1
			if counter_reload_scanline >= SECOND_LOOP_DECREMENT_SCANLINE:
				completed_loop_decrements += 1
	marker_before_loop_tick = (marker_before_loop_tick - completed_loop_decrements) & 0xFF
	var counter_latch := (marker_before_loop_tick << 1) & 0xFF

	# MMC3 reloads its 8-bit counter at `$C001`, then asserts on the scanline
	# after the counter's final clock. `$A160` reaches the `$21C0` writes 56 CPU
	# cycles after IRQ acknowledgement; the captured path stays on that line.
	var irq_scanline := (counter_reload_scanline + counter_latch + 1) \
			% NES_PPU_SCANLINES_PER_FRAME
	return {
		"first_irq_scanline": first_irq_scanline,
		"counter_reload_scanline": counter_reload_scanline,
		"counter_marker_before_loop_tick": marker_before_loop_tick,
		"counter_latch": counter_latch,
		"completed_loop_decrements_before_reload": completed_loop_decrements,
		"palette_upload_restart_phase_scanlines": restart_phase_scanlines,
		"ppu_address_write_scanline": irq_scanline,
		"irq_handler_to_address_write_cpu_cycles": IRQ_HANDLER_TO_ADDRESS_WRITE_CPU_CYCLES,
		"irq_to_write_dot_phase_verified": false,
		"initial_irq_phase_verified": not (motion_steps == 0),
		"model_basis": "ROM $A4FE/$A1A8-$A1BF plus MMC3 reload/count scanline timing",
	}

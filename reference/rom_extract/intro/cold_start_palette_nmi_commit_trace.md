# Cold-start palette packet and NMI commit

## ROM path

Source is the supplied Turkish ROM, SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
The bank-0 palette builder `$9A71` (file `0x001A81`) calls `$9B28`
(`0x001B38`) to append a packet header at `$05E8+X`. For the observed palette
upload, its arguments establish a 32-byte transfer to PPU `$3F00`: packet
bytes begin `20 00 3F` (count, low address, high address). `$9AA2`
(`0x001AB2`) generates each palette byte from `$062A+Y`, using the `$4A/$4B`
high bits and the ROM lookup at `$9EA2`, then stores it after the three-byte
header. `$9B5E` (`0x001B6E`) writes a zero terminator and records the packet
length in `$0628`. Thus `$05E8` is the queue start; the 32-byte payload extends
past `$05F7`.

The NMI vector bytes at file `0x04000A–0x04000F` are `00 C5 F0 FF 06 C5`;
NMI enters fixed-bank `$C500` (file `0x03C510`), whose first jump leads to
`$C76E` (file `0x03C77E`). `$C76E` executes `BIT $1B; BVC +3; JMP $C421`.
During source frame 13 `$1B=$40`, so V is set and the NMI takes `$C421` (file
`0x03C431`). Its mapper setup is followed by `JSR $A000` at `$C43A` (file
`0x03C44A`), entering the bank-2 routine at `$A000` (file `0x004010`). This
proves the observed `$05E8` consumer runs from the NMI path, not from the
cooperative `$9FA8` scheduler.

At `$A000`, the routine checks `$0628`, reads the count/flags from `$05E8,X`,
sets `$2000` to `$80` (PPUDATA increment +1) for this packet, writes address
high `$05EA,X` then low `$05E9,X` to `$2006`, and sends the counted bytes from
`$05EB,X` to `$2007`. It advances to the next packet until the zero header,
clears `$0628`, resets the PPU address to `$3F00`, and restores `$21` to
`$2001`. The generic NMI queue at `$C8FB` is separate: it consumes `$0498` /
`$0499–$049B` and `$04A5`, not this `$05E8` packet.

## Frame-13 capture correlation

`reference/opening_timing_capture_20261024_131316/ram_states/ram_00013.bin`
contains the packet prefix at `$05E8`: `20 00 3F 0F 06 00 ...`. In
`bus_events.csv`, source frame 13 records `$2001=$00` at cycle 608 (PC
`$A019`), `$2000=$80` at 623, `$2006=$3F/$00` at 633/641, 32 `$2007` writes
at cycles 649–1125 (PC `$A03C`), address reset writes at 1156–1170, and
`$2001=$1E` at cycle 1177 (PC `$A062`). The frame-end PPU palette changes
from black `$0F` in frame 12 to nonblack values in frame 13.

The capture records CPU cycles but not PPU dot or scanline. The existing
21-scanline vblank estimate places cycle 1177 before visible scanline 0, so
scanline 0 of source frame 13 is the earliest plausible colored output edge.
That estimate does not prove the exact scanline or first lit pixel. A later
synchronized capture confirms the palette writes and mask restore occur during
vblank, but the source-frame 13–14 first-visible bracket remains until a
per-pixel raster capture resolves the display edge.

## Exact packet layout and synchronized replay

The staging buffer is larger than `$05E8–$05F7`. For this 32-color packet,
offsets from `$05E8` are: header/count `$00`, address low `$01`, address high
`$02`, 32 palette bytes `$03–$22`, and zero terminator `$23`. Thus the packet
spans `$05E8–$060B`, and `$0628` holds the end cursor `$23`. `$0629=$20` in
the sampled frame-end snapshots, so the producer's busy bit 6 is clear and
the consumer can process the packet.

The later synchronized replay at
`reference/diagnostics/synchronized_cycle_order_20261024_134001/` adds PPU
scanline/dot coordinates. Its frame-12 RAM packet is the exact 32-byte payload
written by `$A03C` to `$2007` during source frame 13; the frame-13 PPU palette
snapshot matches those bytes. Frame 13's staged packet is written during
source frame 14, and the frame-14 PPU palette matches it. This proves a
one-NMI transfer delay for these sampled fade packets.

The synchronized trace puts the frame-13 `$2001=$00` write at cycle 608 and
the 32 palette writes at cycles 649–1125 on PPU scanlines 246–251. It restores
`$2001=$1E` at cycle 1177, also during vblank. This narrows the update to the
blanking interval. The next visible scanline can use the new palette, but the
exact first colored pixel remains unproven because no per-pixel raster capture
is synchronized to these writes.

## Conditional NMI route and task-delay calls

`$C421` begins with `BIT $3B; BMI ...`; the sampled `$3B=$55` is positive, so
it continues to map bank 2 and call `$A000`. The same frame-end snapshots show
`$1B=$40`, matching `$C76E`'s bit-6 route into `$C421`. The complete producer
of this mode bit and alternate interrupt branches remain outside this trace.

Bank-0 `$9FA8` (file `0x001FB8`) stores A as a task delay byte, preserves the
task CPU state, and returns to the cooperative task scheduler. The scheduler
scans task slots, decrements nonzero delay counters, and waits for bit 7 of
`$1B` before advancing its synchronized pass. The `$C775` interrupt branch
sets bit 7; `$C76E` selects the separate `$C421` branch when bit 6 is set, so
the interaction of the delay counter with that alternate mode is not fully
reconstructed. Reached calls use A=`$01` for each palette fade step, A=`$02`
in E9 before fade-up, and A=`$04` in FC/FD. These are source-confirmed delay
counts; total visible command duration still depends on the caller's entry
phase and surrounding work.

E9's `$997E` fade-up stages a palette packet with `$9A71` and yields one
scheduler tick per step. EA's `$99F0` fade-down also stages a packet and yields
one tick per step until both fade counters are zero, then proceeds to the
screen clear. The full visual meaning of FC/FD's A=`$04` delay remains open.

# ROM EC stream player model

`RomEcStreamPlayer` reads the hash-checked bank-6 stream extract, stages its
three four-byte PPU packets, and applies them to the presenter's PPU memory at
the next NMI boundary. It does not run a 6502 core or implement the complete
NMI routine.

## ROM call path and timing

The supplied ROM's text handler calls `$895D` only for a glyph when `$55` is
nonzero (`$84FC`). `$895D` loops `$55` times; each loop yields through
`$9FA8(A=$01)`, then calls `$89FF`. `$89FF` checks the active flag at `$0652`,
decrements `$0653`, and reaches the stream reader `$8A0F` when the counter
expires. The `$8A0F` reader consumes the stream byte and loads the next delay
from the following byte's low three bits. A byte scan finds `$896D` as the only
`$89FF` callsite and `$84FC` as the only `$895D` callsite in the supplied ROM.

The presenter mirrors this order: `start(pointer_table_index)` sets the ROM
state, and `advance_consumer_tick(source_frame)` is called only during a
positive-speed glyph wait, once per source tick. The presenter's per-frame
order commits pending PPU packets first, then models the waiting task's
`$89FF` call, then advances the scheduler. A wait with `$55=0` never calls
`$895D`, and pause, loader, FC, EA, and FD work do not advance `$0653` unless
execution is inside a glyph speed wait.

This derives the observed first-record frames from decoded script work and the
ROM call path: selectors `$00/$05/$02/$04` first stage at frames
`380/1120/1780/2369`; the repeated `$00` loop first stages at frame `4579`.
Those frame numbers are validation results, not runtime inputs. In particular,
the `$02` stream's `$0652/$0653=$84/$01` state holds through its `$DB` pause at
frames `1800–1839` because no text-delay ticks call `$89FF` during that wait.

## Stream data and PPU behavior

The 12-byte graphics records are shared among six pointer-table entries, while
the captured selectors choose different group sequences. `$0653` receives the
next stream byte's low three bits. `$FE` restarts at the selected base pointer;
`EC FF` clears `$0652` while preserving the delay and base pointer. The queue
stages packets for `$2302`, `$2303`, and `$2304`; `$2000=$84` writes four bytes
at each address with +32 stepping. A staged group commits at the following
NMI boundary.

## Verification and limits

`tools/diagnostics/verify_ec_rom_callsite_ticks_20261026.gd` compares the
presenter's RAM `$0652–$0655` with same-input FCEUX RAM snapshots across five
EC windows. The result is 1,377/1,377 frames exact, with the five first-record
frames listed above; the `$02` pause adds zero consumer ticks and retains
`$84/$01` through frame 1839. Capture files are read by this diagnostic only.

The exact `$89FF` CPU cycle and sub-frame ordering relative to NMI and other
ready tasks remain unmodeled. The next narrow trace for sub-frame parity should
record PC, SP, cycle, and NMI state around `$9FA8` return and `$89FF` entry, plus
writes to `$0652–$0655` and `$2000/$2006/$2007`, for the first text wait after
each EC selector. This does not invalidate the frame-level RAM match, but it
means within-frame PPU visibility is not yet proven exact.

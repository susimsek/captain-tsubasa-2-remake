# Fresh field PPU route trace

## Scope and result

This muted FCEUX 2.7.0 NTSC/NewPPU trace reused the signature-checked frame-4692
checkpoint and the recorded post-title inputs (`sound=0`, `volume=0`,
`SDL_AUDIODRIVER=dummy`). It observed the route through emulator frame 8953 and
captured ordered `$2006/$2007`, palette, MMC3, and selected PC events. No
screenshot or WAV was captured; no runtime, ROM, or user save slot was changed.

The field-reaching pass records a complete 1-KiB PPU nametable region at
`$2800–$2BFF`, including its attribute table, written by the shared PPU commit
routine at `$C97B`. All 1,024 distinct addresses had been written by emulator
frame 8619. This identifies the earliest observed complete field-sized PPU
payload, but **does not identify the source routine, queue record, or ROM data
descriptor that supplied those bytes**. The route therefore still lacks a
source-attributed full-field producer.

The repeated pass did not agree on route timing. Both restores matched the
checkpoint's RAM, PPU, frame, cycle, and CPU registers byte-for-byte, but pass 1
missed the first Start input and ended at frame 8952 without entering field
setup. Pass 2 reached the field route and ended at frame 8953. The checkpoint
cycle is 139,730,109, approximately three cycles after `4692 × 29,780.5`; this
is consistent with an input/frame phase boundary issue, but the exact cause is
not established. Do not use this capture as same-input repeat verification.

## Route events

In the field-reaching pass, the seven `$8AF7` entries were all before the fresh
field entry at `$DAAA` (emulator frames 4708, 5762, 6512, 7112, 7410, 8006, and
8125). There was no `$8AF7` entry after `$DAAA` through frame 8953. The observed
`$0048` values at those seven entries were `$01,$1E,$1F,$20,$04,$00,$1A`;
these samples do not identify a full-field record.

The relevant route hooks were:

| Hook | Emulator frame | Cycle | Observed state |
| --- | ---: | ---: | --- |
| `$DAAA` | 8460 | 251,937,919 | Raw bank `$1E`; `$05CD=$00`, `$0020=$88`, `$0021=$1E`, `$0048=$00` |
| `$E0DF` | 8782 | 261,513,813 | Raw bank `$1F`; `$05CD=$80`, `$0020=$8A`, `$0021=$1E`, `$0048=$29` |
| `$E233` | 8789 | 261,723,732 | Raw bank `$1F`; scenario setup with `$0020=$8A`, `$0048=$29` |
| First `$E145` | 8844 | 263,371,185 | Raw bank `$1F`; `$05CD=$A0`, `$0020=$88`, `$0048=$3D` |
| First `$E349` | 8845 | 263,399,645 | Input polling begins; 44 `$E349` entries were logged through frame 8893 |

The route-window trace from frames 8460–8953 contains 7,191 `$2007` writes,
2,958 `$2006` high writes and 2,958 low writes, 896 palette writes to `$3Fxx`,
28,889 `$8000` mapper-select writes, 4,930 CHR-register `$8001` writes, and
22,909 PRG-register `$8001` writes. All 7,191 `$2007` events have a synchronized
PPU address in the trace. The `$2800–$2BFF` block received 2,528 writes in total
from frames 8595–8734; its 1,024-address coverage was complete by frame 8619.
The other nametable region `$2000–$23FF` received writes to 1,003 distinct
addresses, leaving 21 addresses unwritten in this observed route window.

At the final observed frame, the PPU state writes set `$2000=$8A`, `$2001=$1E`,
and `$2005=$00,$00`; the final CPU sample was PC `$CAB0` at cycle 266,624,820.
The route's final RAM was `$05CD=$80`, `$0020=$8A`, `$0021=$1E`, `$0048=$29`.
These state values are consistent with field setup, but without a screen capture
they do not prove that the first command panel was visibly rendered at frame
8953.

## Provenance and repeat boundary

| Input | SHA-256 |
| --- | --- |
| ROM | `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097` |
| Frame-4692 checkpoint [`frame_004692_fullprefix_slot0.fc0`](../../diagnostics/local_checkpoints/fresh_kickoff_1b6_persistence_20261029/frame_004692_fullprefix_slot0.fc0) | `e5f88f9e3b284fd80f69a29bfafe6cd7aaf1c53f426448074bc541320c5e4d84` |
| Recorded post-title input file [`post_title_inputs.csv`](../../diagnostics/kickoff_select_test_20261027/post_title_inputs.csv) | `87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e` |
| Filtered pass-2 event trace | `89f4f8ddfb6c318d1099296bb615b4b064f4ba19da3495745cce8e4913187e9c` |

The checkpoint loaded at frame 4692, cycle 139,730,109, PC `$9F04`, with
`A/X/Y/P/SP=$40/$19/$00/$21/$E0`. The route input file was requested for
source frames 4693–8953 in both passes.

Each reload of the anonymous in-memory state matched the checkpoint RAM, PPU,
frame/cycle, and CPU registers. However, pass 1 ended at emulator frame 8952
with `$05CD=$00`, `$0020=$88`, `$0048=$01`, while pass 2 ended at frame 8953
with `$05CD=$80`, `$0020=$8A`, `$0048=$29`. The first pass therefore failed to
replay the route at the recorded frame alignment. The controller latch and
sub-frame scheduling were not included in the byte-exact restore comparison;
their role is a hypothesis, not a demonstrated cause.

The filtered ordered event stream is
[`field_pass2_ordered_events.csv.gz`](../../diagnostics/first_command_field_ppu_trace_20261029/field_pass2_ordered_events.csv.gz).
It retains all `$2006/$2007`, `$3Fxx`, PPU control/scroll, MMC3 `$8000/$8001`,
and route-hook rows needed to inspect the field-reaching pass.

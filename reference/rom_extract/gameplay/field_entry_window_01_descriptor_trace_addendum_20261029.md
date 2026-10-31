# Descriptor `$01` Route Trace Addendum

The muted FCEUX 2.7.0 NTSC/NewPPU replay loaded the recorded frame-4692
checkpoint and used route-input SHA-256
`87c204c5e513d1aa4b60fa348350a15a4be006d84ef885b7f1b95c4e3a9f229e`. It
requested source frames 4693–8953; replay metadata reports emulator frame 8952
at completion. Audio and volume were zero. No screenshot or WAV was captured.

The first bank-filtered hook pass was insufficient to interpret bank labels.
The follow-up used unfiltered three-argument FCEUX execution hooks at `$8B2F`
and `$8C55`, plus a `$C4C7` calibration hook. The calibration hook fired
8,520 times with bytes `60 C9 23 B0 27 A8`, confirming hook delivery. Neither
descriptor PC fired; no runtime bytes at those two addresses were captured.

The reused route mapper log contains 208,740 writes, including 59,640 records
with raw `$0C` in a PRG window. These raw mapper values should not be read as
project bank labels. Direct ROM-offset comparison shows that the descriptor
resources' manifest bytes at `$8B2F/$8C55` match raw 8-KiB PRG bank `$18`; the
bytes at the same CPU offsets in raw bank `$0C` do not match. The corrected
unfiltered hooks still recorded zero descriptor calls in this route window.

The replay recorded 4,260 writes of `$40` to `$003C`, all reported at `$C42A`
in fixed bank `$1E`, with old and new value both `$40`. Because neither
descriptor handler ran, these writes do not establish `$003C` at a formatter
call and do not resolve the packet input.

The exact last logged execution event was the `$C4C7` calibration at source
frame 8953, emulator frame 8952, cycle 266572414, raw bank `$1E`, with bytes
`60 C9 23 B0 27 A8`. At that sample the MMC3 selector was `$07`, shadows
`R0–R7=7C/7E/FC/7D/7E/7F/00/02`, raw PRG map `00/02/1E/1F`, and RAM was
`$003C=$40, $0628=$00, $0629=$01`. The final CPU PC and cycle after the replay
loop were not captured. No screen was captured, so this trace does not
establish that the first command panel was reached or visible.

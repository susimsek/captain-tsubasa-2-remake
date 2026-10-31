# Slot-$05 second-NMI worker boundary audit — 2026-10-29

This earlier report stops at `$89A0->$BBDE`. That boundary was subsequently
extended through the ROM `$F0` callback to `$CD52`; see the current
[F0 worker boundary report](slot05_f0_worker_partial_boundary_20261029.md).

## Scope

This report covers the live scheduler-selected slot-$05 resume after the second
caller-supplied NMI. It uses the supplied ROM-derived route, hash-checked worker
bytes, and the independent descriptor-$00 packet contract. No FCEUX session,
screenshot, captured audio, or injected trace RAM was used.

Source ROM SHA-256:
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.

Focused check on Godot 4.7.2:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_slot05_second_nmi_worker_resume.gd
```

The check passed at the first unsupported live descriptor-row read.

## Live dispatch and preserved state

The second-NMI route first selected root slot `$01`, followed its six inactive
actor records through `$EE9F`, returned through `$E3CA`, saved at `$CA4F->$CB0F`,
and then selected slot `$05`. The new route dispatched that actual saved slot at
`$8889`; it did not assume a later slot selection.

The worker input was:

- CPU: `PC=$8889`, `A=$04`, `X=$04`, `Y=$03`, `SP=$4A`.
- Mapper: banks `$18/$19`, register selector `$07` from the live `$E3CA` result.
- Live RAM: `$0515=$00`; `$0050/$0051=$B453`.
- Stack bytes at `$014B-$0152`: `98 EF 1D 1C CB DA 1D D1`.

The live input RAM SHA-256 was
`b8351bbe374d4964775f86df66d23e0a5ce289f0a2f82ef0a0aab3f4f45c1b37`; the
input stack-page SHA-256 was
`838620484f6d1bc9dfd324713285d1bf131bbe8ba5a5ab9bb840c2b53aac0835`.

The worker executed 206 supported instructions, two JSRs, 62 RAM writes, and
no mapper writes. Its source-produced writes were replayed over the live
scheduler state. The adopted RAM SHA-256 is
`cc380a6b73bbe321918d8ab4ac5f5673d3f40a40e14a07130d34ba5bf4add1b1`; the
adopted stack-page SHA-256 is
`a831998a53010153906573879acd19124faed2a4854c0629efacd3ac3cd717b3`. The
stack bytes at `$014B-$0152` remained `98 EF 1D 1C CB DA 1D D1`.

The scheduler now holds active slot `$05` at `$89A0`, with RAM and stack equal
to the worker's partial source output. No `$CB0F` save was applied, no
post-worker scheduler scan was run, no later task body ran, and no NMI cadence
was generated.

## Descriptor contract and stop reason

The worker's hash-checked manifest is
[`fresh_bank18_worker_prefix/manifest.json`](fresh_bank18_worker_prefix/manifest.json),
SHA-256 `97508e68056732b45ce15352fa7f7b0279dfd7be9209801e7ccac6740fba93eb`.
Its resumed text span covers `$BBDC-$BBDD` only: `EF FC`. The live route's
source-produced fresh-period result independently satisfies the descriptor-$00
contract: `$0027=$00`, `$05F7=$B4`, `$05F8=$00`. The descriptor-$00 manifest is
[`field_entry_window_00/manifest.json`](field_entry_window_00/manifest.json),
SHA-256 `fe9d47fff258a2ee092969b2a5c64d0bce24a99193e89f63954408fc3407dd00`.
It identifies row zero `EF FC` at `$BBDC` and row one `F0 FC` at `$BBDE`. Its
ROM-derived `$F0` result is `36 33 77 33 33`, and all five descriptor packets
are complete for those source inputs.

The worker nevertheless stops while its `$89A0` indirect read requests `$BBDE`
in bank `$19`. Exact result:

```text
instruction_pc = $89A0
requested_address = $BBDE
bank = $19
reason = ROM byte is not present in the hash-checked source manifest.
```

The two row-one bytes are preserved separately as
[`descriptor_00_row_01.bin`](field_entry_window_00/descriptor_00_row_01.bin),
SHA-256 `c2b693b8213b7fb3d64338c576d60acbde3663432f4c433a8a0627194a3df5d9`,
but that span is not part of the resumed worker's source map. The descriptor
packet component validates and decodes `$F0`; it does not provide the CPU
register, flags, stack, and return-state effects needed to continue this worker.
No `$8B48` or `$8B8B` callback was executed in this run.

The partial queue head at `$04A5-$04C4` is
`076122aa0000000000ab00000000000000000000000000000000000000000000`.
The verifier confirms that the descriptor's second-row `$F0` packet is not
present in the worker queue. The descriptor contract's output is evidence for
the ROM input/output mapping, not a runtime queue write by this worker.

## Boundary and remaining source work

The live route is verified through slot-$05 `$8889` and stops at the first
unsupported descriptor-row read at `$89A0->$BBDE`. The remaining source work is
to connect the preserved `$F0/$FC` row and `$8B8B` clock handler to a checked
CPU continuation contract that supplies the actual caller return and worker
state. Until then, do not infer a `$C515->$CB0F` save, a second-row packet write,
or a later scheduler selection from the descriptor builder alone.

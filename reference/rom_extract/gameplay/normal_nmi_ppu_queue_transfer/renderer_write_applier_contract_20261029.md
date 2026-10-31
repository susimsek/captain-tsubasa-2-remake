# Renderer-side PPU nametable write applier

## Scope

`RomPpuNametableWriteApplier` consumes the ordered `bus_events` returned by
`RomNormalNmiPpuQueueConsumer`. It models only the side effects needed to apply
the secondary queue's `$2002` reads and `$2006/$2007` writes to the dictionary
accepted by `RomPpuNametableScreenRenderer.set_ppu_memory()`.

The caller supplies the current `$2000` control byte, 15-bit current (`v`) and
temporary (`t`) PPU addresses, and the shared `$2005/$2006` write toggle. A
`$2002` read resets the toggle. `$2006` high/low writes update `t` and then
copy it to `v`; `$2007` writes update one renderer nametable byte and increment
`v` by 1 or 32 according to `$2000.2`. `$3000-$3EFF` is canonicalized to its
`$2000-$2EFF` mirror because that alias is supported by the renderer's
nametable reader.

The applier rejects malformed/out-of-order events, unsupported PPU registers,
CHR addresses, palette addresses, and PPU-memory dictionaries containing keys
outside `$2000-$2FFF`. It returns updated copies of memory and PPU state; it
does not mutate caller-owned inputs.

## ROM-derived fixture

The focused verifier uses the source-executed first two slot-`$05` menu-worker
packets, also checked by `verify_rom_fresh_bank18_worker_resume.gd`:

```text
07 21 22 00 00 00 00 00 00 00
07 41 22 9C A8 20 34 2E A8 9D
```

With PPUCTRL `$88`, these produce zero bytes at `$2221-$2227` and
`9C A8 20 34 2E A8 9D` at `$2241-$2247`. The final modeled current address is
`$2248`. The verifier also checks the `$2000` increment-by-32 branch and
rejection of a palette address.

## Limitations

This is an isolated renderer-side component. It is not wired into
`KickoffRouteRuntime` or `KickoffCutsceneVisuals`; integration still needs the
source-derived active field CHR, palette, and nametable context before applying
the returned `ppu_memory` with `set_ppu_memory()`.
It does not implement PPU status values, rendering-time effects, hardware
mirroring configuration beyond the `$3000-$3EFF` address alias, CHR writes,
palette writes, OAM, mapper changes, PPU beam/cycle timing, or first-visible-
pixel timing. Passing this verifier establishes only the modeled register
side effects and the stated two-packet nametable result.

Focused command:

```sh
godot --headless --path . --script tools/diagnostics/verify_rom_ppu_nametable_write_applier.gd
```

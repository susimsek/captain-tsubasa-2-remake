# EB post-input dialog clear

## ROM source

The supplied Turkish ROM is identified by SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
`manifest.json` pins the extracted bank-0 instruction spans for the EB handler
at `$85C3`, geometry helper `$88B1`, queue branch `$98E8`, and packet writer
`$9B28`.

The EB handler calls the input helper, waits for the fresh-A condition, and
calls `$88B1` before advancing the script pointer. `$88B1` derives eight rows
and a row width of `(~$54 + $1F) mod 256`. With the dialog geometry observed
at the two first-cutscene waits (`$4F/$50/$54 = $49/$22/$09`), it clears 21
bytes at `$2249,$2269,...,$2329`. The nonzero fade counters select `$98E8`'s
queued path.

`$9B28` reserves each row's three-byte queue header plus its payload. Before
reserving the next row, `$98E8` tests `$0628 + width >= $3D`; the check yields
through `$9FA8` when the limit is reached. For eight 21-byte rows, that
produces four two-row batches, each 48 queue bytes, with three one-tick
capacity waits between batches.

## Godot route model

`scripts/gameplay/rom_cutscene_eb_post_wait_source_task.gd` verifies the pinned
ROM-derived byte spans and calculates the row geometry, destinations, queue
records, and capacity waits. `kickoff_route_runtime.gd` starts it only when the
recorded route has a fresh A edge at an active EB command. The presenter stages
the zero-fill records through the shared `$0628` accounting and applies them
on the next modeled source tick. Captured RAM is read only by the verifier.

The recorded-input verifier checks both EB occurrences against the FCEUX
frame-end RAM captures:

| FCEUX frame | Script PC | `$0628` | Godot source event |
|---:|---:|---:|---|
| 5443 | `$A2E1` | `$30` | First two-row clear batch queued |
| 5446 | `$A2E2` | `$35` | Clear batch completed; first next text glyph queued |
| 5743 | `$A2F8` | `$30` | Second two-row clear batch queued |
| 5746 | `$A2F9` | `$30` | Second clear helper returns with final batch queued |
| 5800 | `$A301` | `$00` | Queue has drained after the helper |

The Godot replay records the corresponding batches on frames 5443–5446 and
5743–5746. This validates the source-frame scheduler and queue-cursor model
against the saved same-input replay. It does not claim exact PPU bus-cycle,
NMI phase, or pixel timing; the capture is frame-end RAM, not an instruction-
cycle snapshot. The clear origin is taken from the ROM-derived dialog layout
used by the presenter; broader runtime writers of `$4F/$50/$54` remain outside
this task model.

## Verification

Run the focused VM/source-task check:

```sh
godot --headless --path . --script tools/diagnostics/verify_kickoff_cutscene_command_vm.gd
```

Run the recorded route through the later cutscene boundary (this verifier also
reports unrelated open match-setup assertions until the full route is closed):

```sh
CT2_ROUTE_FINAL_FRAME=5800 godot --headless --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

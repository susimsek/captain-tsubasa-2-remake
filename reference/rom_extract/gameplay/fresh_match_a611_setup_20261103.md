# Fresh Match `$A611` Level-Update Pass

## Result

The production route executes the fresh match-index-zero branch from `$A58B`
through `$A611` and the `$A583` caller return at `$A610`, then follows
`$811F->$C572->$DB62` through all eleven home-player stamina writes and returns
at `$8122`. The caller then performs the direct `$8122-$812F` BGM queue store;
the held route endpoint is `$812F`. The ROM checks all eleven home-player records. Reset experience and
level bytes are zero, so `$A611` leaves every level unchanged and produces an
empty level-up list. The `$A611` executor remains limited to this verified
fresh-start state; it does not calculate arbitrary nonzero experience or level
updates. The stamina pass is documented separately in the [stamina initializer
report](fresh_match_stamina_initializer_20261103.md).

## ROM evidence

- ROM SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`.
- Bank `$01` caller body `$A583-$A610`, file offset `0x002593`, 142 bytes,
  SHA-256 `2933f0764b9660a2c9987cb531d3c78d3ba6359bc20cdec9ad1528f865e043e2`.
- Bank `$01` level routine `$A611-$A63B`, file offset `0x002621`, 43 bytes,
  SHA-256 `46e66749b1b1335162245f59c65ccf68189d8e4fcfa55e67c0b2d9493181ed14`.
- Bank `$01` level helpers `$B013-$B039`, file offset `0x003023`, 39 bytes,
  SHA-256 `9305de9d5c70c8fc48fea82f89c68cbf2a55edddc47cdf402f0d4d1604c57317`.
- Fixed vector `$C50C-$C50E` to `$CD7C`, file offset `0x03C51C`, 3 bytes,
  SHA-256 `71f4bb6ccdc5573bcfceef2422fe8636bc1dd1068675da3d860282d577e78b44`.
- Fixed resolver `$CD7C-$CD88`, file offset `0x03CD8C`, 13 bytes,
  SHA-256 `8d7d8153252420175055aa5ef041e0e9dd85f99bb9dae8e24200e9549487ed24`.
- Fixed level thresholds `$BA90-$BB0F`, file offset `0x003AA0`, 128 bytes,
  SHA-256 `26a7e191432e7174737ec3ac353710e2aad6d9c60241745b06cde7754540c67c`.

The `$A611` loop dispatches through `$C50C->$CD7C` to resolve player-record
pointers and calls the bank `$01` level helpers at `$B013` and `$B02E`. It
checks each home slot and exits without a level write when the source-derived
experience and current level are both zero. The extracted bytes and provenance
are listed in
[`first_match_player_state/manifest.json`](first_match_player_state/manifest.json).

## FCEUX comparison and limits

The muted same-ROM trace reaches `$A58B` in frame 7408 at cycle 220605739 with
`A=$0B`, `X=$00`, `Y=$00`, `P=$20`, and `SP=$26`; `$0026`, `$00EC`, and `$00ED`
are zero at that hook. FCEUX reaches `$811F` in frame 7409. The frame-7409 RAM
observation shows `$00EB=$00`, `$00EC=$00`, `$00ED=$0B`, eleven unchanged
home-level bytes, and a zeroed level-up list. Those are validation observations,
not runtime inputs.

The frame-end RAM dump for frame 7408 was captured before the `$A58B` hook and
contains `$00ED=$05`; it is not a valid same-PC input snapshot. The independent
py65 source run therefore used that earlier RAM baseline while taking `$EC`
and `$ED` from the matching-PC hook. It reached `$811F` in 5,391 instructions
and agreed with the relevant frame-7409 FCEUX outputs. This hybrid comparison
does not establish full machine-state or cycle-level equivalence.

## Godot integration and verification

`rom_fresh_match_a611_setup_executor.gd` checks the extracted source hashes and
accepts only the live source RAM image for a fresh match-00 run with known-zero
experience and level bytes. It produces source RAM write receipts and the
`$811F` return contract. `rom_fresh_match_stamina_initializer.gd` then checks
the fixed-bank vector, both evaluator paths, live roster/level inputs, and ROM
curve resources before producing the `$8122` return contract and 22 energy
byte writes. `KickoffRouteRuntime` merges those receipts into its live ledger;
the runtime does not read FCEUX state, screenshots, or captured audio.

Command:

```sh
CT2_ROUTE_FINAL_FRAME=7410 godot --headless --audio-driver Dummy --path . --script tools/diagnostics/verify_kickoff_recorded_input_path.gd
```

Result: PASS on Godot 4.7.2. The verifier checks the recorded route through
`$A611->$811F->$C572->$DB62->$8122`, the earlier `$A571` input edge and fade
packets, the frame-7408 palette/nametable clear, and frame-7409 level-loop RAM
against the corresponding FCEUX observations. FCEUX frame-7409 confirms stamina
input roster IDs and levels, but no available post-call RAM capture directly
verifies all 22 energy writes; those writes are checked against the decoded ROM
profile and value tables.

## Remaining boundary

The stamina executor returns at `$8122`; the production route now executes the
direct BGM store and stops at `$812F`. The remaining `$812F-$815C` caller setup,
field rendering, first command menu, route audio parity, and ROM/emulator-free
packaging remain incomplete. Physical NES
subframe timing is not proven by the frame-level and bounded source checks.

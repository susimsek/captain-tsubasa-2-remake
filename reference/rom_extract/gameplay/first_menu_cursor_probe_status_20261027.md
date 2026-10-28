# First in-match action cursor probe status

## Verified endpoint

The reference is the supplied Turkish ROM, whole-file SHA-256
`4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097` and
PRG+CHR MD5 `eaf2b3745263efa4b1afd2b400f68dae`. The successful muted FCEUX route
capture is preserved in
`reference/diagnostics/kickoff_select_test_20261027/`.

That route presses B at source frame 8893, observes the full panel by frame
8953, then supplies no further input through the stable frame-9042 endpoint.
The `post_title_inputs.csv` rows 9033–9042 contain no direction, A, B, Start, or
Select input. The 8953 and 9042 screen and PPU hashes are identical:

| Capture | Screen SHA-256 | PPU SHA-256 | RAM SHA-256 |
|---|---|---|---|
| Frame 8953 | `cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559` | `da56b2c2dbe44a5864be61068bb23fe46f434cc2bc73a10489a471e4bfa2350e` | `a8d4cae0ed26fa6fbc01dcdcae6f076c94c33b0c295b95eca6cdbf64270a2971` |
| Frame 9042 | `cc30a78af0f1e4d5d6ceb1a78d023caec0782afcbef43539b4d1607902130559` | `da56b2c2dbe44a5864be61068bb23fe46f434cc2bc73a10489a471e4bfa2350e` | `e78c0ff79c879d02168d95c6ac6dc93057226b0241ff37dc3f6e4e0f28129577` |

The capture shows no visible action-row arrow/highlight. Since no direction pulse
was recorded, it does not establish whether an action is internally selected,
which action is selected, or how selection changes. Do not initialize a Godot
cursor from an assumed default.

## Follow-up attempt

On 2026-10-27 a second muted FCEUX run used a copy of the known `route4.lua`
protocol, with output redirected to a new diagnostic folder and separate input
flags. FCEUX reported the expected ROM MD5, disabled audio, stopped the
bootstrap movie, and powered on successfully. It remained in the 0–4692 manual
opening replay loop for over ten minutes without reaching the title checkpoint.
The process was stopped before any post-title route input; no Down/Up pulse was
sent and no cursor evidence was produced. The incomplete retry output was
discarded. The successful `kickoff_select_test_20261027` capture was not changed.

## Conclusion

The initial action cursor and its RAM/OAM representation remain **unmeasured**.
The only verified initial state is the visible panel without an on-screen
highlight at frame 8953/9042. A later probe must reach the existing 9042
checkpoint, send only isolated one-frame directions, and compare the resulting
PPU/RAM/OAM state before drawing a selection conclusion.

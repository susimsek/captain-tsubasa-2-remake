# First in-match action menu: ROM input and selection trace

## Scope and source identity

This is a static trace of the fresh-start first in-match action menu. The ROM
analysis does not enter or confirm an action. A separate Godot input-state
component is documented at the end of this note; it does not resolve an action.

- Target ROM: `Captain Tsubasa 2-Super Striker(By TsubasaTR.Net).nes`
- Whole-file SHA-256: `4f1f74d495e86025a5ad17fec2c171f37a94541a7d8ff7034c580d7d5111a097`
- PRG+CHR MD5, excluding the 16-byte iNES header:
  `eaf2b3745263efa4b1afd2b400f68dae`
- The related English-translation disassembly at pinned commit
  [`ec03cf06e6bdae0bcd232e3a423e9d259757dc64`](https://github.com/cyneprepou4uk/Captain-Tsubasa-2-English-Translation/tree/ec03cf06e6bdae0bcd232e3a423e9d259757dc64)
  supplied routine labels and table comments only. The code paths below were
  checked against the target ROM's bytes; English text and descriptor data were
  not copied as Turkish-ROM facts.

## Static caller chain

The first visible command prompt follows the standard left-team possession
path:

1. The field loop at fixed-bank `$E145` calls `$E349` once per game loop. At
   `$E349` (file offset `0x03E359`), the code checks `$05FB` (team in
   possession). If it is zero, it checks held B (`$001C & $40`). The fresh
   route capture has `$05FB=$00`, and the documented B press opens the menu on
   this branch. The B path clears defender count `$0600` and flag `$0615`, records
   scenario `$44`, switches to banks `$1A/$1B`, then jumps through the bank
   entry at `$8003` to the handler at CPU `$803C` (ROM file address
   `0x03404C`). In the target ROM, the caller's jump is at file offset
   `0x03E3B0` (`4C 03 80`) and the bank-$1A entry stub at `0x034013` is
   `4C 3C 80`.
2. Bank `$1A`, `$803C` (file offset `0x03404C`) sets ball height `$044E=0` and
   menu context `$0621=0`, then calls fixed-bank `$D575`. The bytes at the
   caller are `A9 00 8D 4E 04 8D 21 06 20 00 C6`.
3. The fixed-bank helper reaches `$D5C3`. For the left-team path it indexes
   `tbl_D706_action_window` with `$0621`, then indexes `tbl_D700_stats` with
   the same context. Context zero therefore draws menu descriptor `$02`
   (`Action`) and descriptor `$03` (the current player and status panel).
   Both draws call `$EF7F`, the bank-switch wrapper for the shared bank-$18
   renderer at `$8852` (file offset `0x030862`).
4. `$D5E0` clears `$061E`, then `$D5E5` enters the input loop. This is the
   caller/input path for the panel recorded at frame 8953 in
   [`kickoff_first_command_menu_trace_20261027.md`](kickoff_first_command_menu_trace_20261027.md).

Relevant target-ROM code windows were checked at fixed-bank file offsets
`0x03E359` (`$E349`), `0x03D5D3` (`$D5C3`), `0x03D6F8` (`$D6E8`),
`0x03D710` (`$D700`), `0x03D716` (`$D706`), and bank-$1A file offsets
`0x034013` (entry stub) and `0x03404C` (`$803C`). In the target file, the six context bytes at `$D700` are
`03 04 05 03 03 03` and those at `$D706` are `02 02 02 02 02 2C`; their first
entries confirm the descriptor IDs above. The shared-renderer wrapper begins
at fixed bank `$EF7F` / file offset `0x03EF8F`; bank `$18` renderer bytes and the
Turkish descriptor mapping are recorded in
[`first_command_panel_rom_mapping.md`](first_command_panel_rom_mapping.md).

## Selection state and controls

There is **no initial row cursor; the action is unselected**. On entry, `$061E`
is explicitly written as zero. The input handler treats bit 7 of `$061E` as the “a direction
has selected an action” gate: A confirms only when that bit is set. Thus the
frame-8953 panel's lack of a visible arrow is consistent with the ROM path; it
is not evidence of a hidden default row. `$043B` stores the selected attack
action, while `$061E` stores the direction/selection and display state; they
are separate from the renderer progress bytes `$05C5/$05C6`.

The menu reads newly pressed input from `$001E` (`ram_btn_press` in the
byte-matched listing), not the held-D-pad field. It scans the low four bits in
order, producing direction indexes Right=0, Left=1, Down=2, Up=3. With the
first-match context `$0621=0`, the target table at `$D6E8` / file offset
`0x03D6F8` contains `00 01 03 02`. The byte-matched table labels identify
action IDs 0=shoot, 1=pass, 2=dribble, 3=one-two pass. Therefore:

| Newly pressed direction | Table index | Selected action ID | Action label from the byte-matched listing |
|---|---:|---:|---|
| Right | 0 | 0 | Shoot |
| Left | 1 | 1 | Pass |
| Down | 2 | 3 | One-two pass |
| Up | 3 | 2 | Dribble |

Up and Down do **not** move a vertical cursor through the displayed Çalım, Pas,
and Şut status lines. They directly choose different actions from the context
table. In this first context, Down selects one-two pass and Up selects
dribble. The status panel is ROM descriptor `$03`; the action prompt is
descriptor `$02`. After a direction is pressed, the handler stores the mapped
action in `$043B`, saves the direction index in `$061E`, and sets its bit 7.
Pressing A then passes the selected action to the action handler. The selected
action label is blinked by toggling bit 6 of `$061E` on the `$061F` timer; this
visual blink path does not change the selected action. The handler does not
provide a separate row-navigation cursor.

The mapping is contextual: `$0621` indexes four-entry direction tables, so
these Right/Left/Down/Up meanings apply to the fresh-start ground-possession
context zero. Other situations use different rows in the same table, including
penalty aiming. This note stops at the first command menu and does not trace
those later contexts.

## Evidence boundary and remaining checks

- The ROM hash and relevant instruction/table bytes are directly checked
  against the supplied Turkish file. The external disassembly provides helpful
  labels; the target bytes remain the implementation authority.
- The live route capture at frame 8953 contains no post-open D-pad or A input.
  It therefore cannot independently show the selected label or a changed
  `$061E/$043B` value. The static code resolves the initial state and mapping,
  while the new Godot packet builder reads the selected-label streams directly
  from the ROM. A same-input FCEUX direction probe is still needed to validate
  the live PPU output and blink cadence end to end.
- The text/action semantic names in the table use comments from the pinned
  disassembly, whose machine-code paths match the target at the listed windows.
  The raw selected-label byte streams and PPU addresses are now preserved under
  `menus/first_action_menu/`; the final rendered Turkish spelling still
  depends on the target's ROM character tiles and has not been checked against
  a same-input selected screen.
- This does not establish exact PPU packet timing, first visible cursor-label
  pixel, or frame-accurate Godot presentation.

## Godot input-state component

`scripts/gameplay/first_action_menu_input.gd` implements the confirmed context-0
selection rules independently of drawing and match-action resolution. The
component starts with `ActionId.NONE`, maps the four newly pressed directions
to the ROM action IDs, and emits `action_confirmed(action_id)` only after a
direction has selected an action. It does not enter a later action flow. If
multiple direction edges are queued for one Godot input poll, it resolves them
in the ROM scan order Right, Left, Down, Up.

Keyboard arrow keys and gamepad D-pad buttons provide direction input. Z/Space
and gamepad A are convenience mappings to the NES A-confirm input; these
physical host bindings are project choices, not claims about the original
controller's hardware layout. `KickoffRouteRuntime.install_first_action_menu()`
now installs the component after the ROM-derived panel is built, and forwards
selection changes to its ROM action-label renderer. The route advances the
label's 13-iteration blink period on source ticks. The focused Godot 4.7.2 check
`godot --headless --path . --script tools/diagnostics/verify_first_action_menu_input.gd`
passed initial unselected state, keyboard/gamepad mappings, confirmation gating,
and simultaneous-direction priority. A route integration check uses the
frame-8953 RAM snapshot only as a test fixture, then verifies the unselected
panel, Right=Shoot, and two 13-tick blink transitions without confirming the
action. This does not prove same-input FCEUX PPU output or that 13 handler
iterations equal 13 displayed frames; the real match route still does not call
`install_first_action_menu()` automatically.

# Desktop UI and release workflow

Use these rules when changing About, desktop update dialogs, packaging, or the
release workflow. Keep the root `AGENTS.md` concise; this focused reference is
loaded only for relevant Godot/release work.

## Product UI

- Use `scripts/desktop_ui_theme.gd` as the shared source for desktop utility
  colors, typography, spacing, button states, and dialog surfaces. Do not add
  per-dialog copies of shared styles. Use the native window frame as the only
  outer frame and keep the content surface flat and borderless.
- The shared palette follows Bootstrap 5.3's default base hues, 100–900 shades,
  grays, white, and black. Semantic aliases are `primary`, `secondary`,
  `success`, `info`, `warning`, and `danger`. Bootstrap's `light` and `dark`
  button variants are intentionally omitted. This is a palette and component
  pattern only; do not add Bootstrap as a runtime dependency.
- Style every desktop `Button` with `DesktopUITheme.apply_button_style()` and a
  semantic variant. Use one filled `primary` action and a visibly distinct
  `secondary` action for deferral or cancellation. Use `danger` only for
  destructive actions; reserve `success`, `warning`, and `info` for actions
  whose meaning matches those roles. Outline variants are available for lower
  emphasis actions when a filled secondary action is not appropriate.
- Keep button geometry and states consistent: shared minimum height, padding,
  corner radius, normal/hover/pressed/disabled states, and a visible keyboard
  focus ring. Do not initially focus install actions. Maintain readable text
  contrast and never use color alone to communicate action meaning.
- Apply this system to desktop utility windows and menus such as About and
  updates. Preserve the separate ROM-derived pixel-art style for in-game menus.
- Use a compact hierarchy: app icon, clear state heading, one explanatory line,
  subdued version/original-release metadata, progress when needed, and aligned
  actions. Prevent clipping and excessive empty space.
- Keep keyboard navigation clear; do not initially focus Install and Relaunch,
  and do not let Return unexpectedly install an update.
- Keep utility copy in concise English to match the product. Show accurate
  states for checking, current, available, downloading, ready, installing,
  unavailable, and failure. Translate helper failures into useful messages.
- Windows/Linux use separate `Help → About…` and
  `Help → Check for Updates…` commands. macOS uses its native application menu.
  Shortcuts are additional entry points, never the only ones. Desktop chrome
  must remain outside the 256×224 game viewport.
- Automatic checks may report an update, but downloading and installation
  require explicit player actions. Persist the preference. Match the package to
  the running install type, preflight the install/staging paths, and explain
  where the package will install. Never claim an update can be applied when its
  destination is not writable.
- Show download progress while the game is open. Do not show an in-game install
  progress bar: the game closes before the helper replaces its files.
- Do not gate release checks on local install write permission. If a newer
  release exists but the destination is not writable, tell the player which
  version is available and explain the permission issue without offering a
  download/install action. Automatic notices must respect that version's
  remind-later and skip preferences.
- An available update offers `Download Update`, `Remind Me Later`, and
  `Skip This Version`. Remind-later snoozes the automatic prompt for 24 hours
  for that release; skipping suppresses its automatic prompt until a newer
  release appears. A player can still use the manual update command to check
  explicitly. Neither choice downloads or installs anything.
- Once a player downloads and verifies an update, keep the staged package and
  its version, asset, package type, size, and SHA-256 metadata across launches.
  Revalidate the package and install type before restoring `Ready to Install`;
  when automatic checks are enabled, compare it with the latest release and
  discard it if superseded. A network failure must leave a valid cached package
  usable. After an install failure, offer a retry from a still-valid cached
  package. Deferring an update must not trigger a second download or an
  automatic install.
- A Linux tarball update must refresh every shipped package file, including the
  launcher icon and desktop-entry scripts. Keep its update file list in sync
  with the release archive; back up replaced files and restore them if any
  installation step fails. Do not replace unrelated user files.
- Use the configured original game release date, not a GitHub publication
  timestamp. About/update screens must not change gameplay state.
- Review every dialog state at native desktop size, including long text,
  progress, focus, defer/close actions, and download-to-install transitions.
  Report which states were actually inspected.

## CI and release workflow

- Preserve the CI/release workflow's cache keys: runner OS, pinned Godot
  version, official export-template archive identity, and relevant import inputs.
  When updating Godot, update the archive SHA-256 identity and expected size.
- On a cold template cache, fetch only required official archive entries with
  HTTP Range requests; validate ranges, ZIP directory, extracted-entry CRCs,
  and template version. Partial range downloads do not prove the whole archive
  SHA-256.
- Run Godot resource import on cache misses. An exact input-key hit may skip
  repeated import, but runtime export and launch checks still run. Summaries
  should distinguish cache hit/miss, transferred bytes, and timed build stages;
  claim a speedup only against an uncached baseline.

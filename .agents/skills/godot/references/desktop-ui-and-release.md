# Desktop UI and release workflow

Use these rules when changing About, desktop update dialogs, packaging, or the
release workflow. Keep the root `AGENTS.md` concise; this focused reference is
loaded only for relevant Godot/release work.

## Product UI

- Centralize shared colors, typography, spacing, button states, progress bars,
  and dialog surfaces. Use the native window frame as the only outer frame and
  keep the content surface flat and borderless.
- Use a compact hierarchy: app icon, clear state heading, one explanatory line,
  subdued version/original-release metadata, progress when needed, and aligned
  actions. Prevent clipping and excessive empty space.
- Use one filled primary action and a quiet secondary action. Keep keyboard
  navigation clear; do not initially focus Install and Relaunch, and do not let
  Return unexpectedly install an update.
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

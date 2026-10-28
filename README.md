<p align="left">
  <a href="assets/readme/captain-tsubasa-2-poster.jpg">
    <img src="assets/readme/captain-tsubasa-2-poster.jpg" alt="Captain Tsubasa II: Super Striker original promotional poster" width="640">
  </a>
</p>

<p align="left">
  <a href="https://github.com/susimsek/captain-tsubasa-2-remake/releases/latest"><img src="https://img.shields.io/github/v/release/susimsek/captain-tsubasa-2-remake?display_name=tag&amp;label=Version" alt="Latest release version"></a>
  <a href="https://github.com/susimsek/captain-tsubasa-2-remake/actions/workflows/ci.yml"><img src="https://github.com/susimsek/captain-tsubasa-2-remake/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI status"></a>
  <img src="https://img.shields.io/badge/Engine-Godot%204.7.2-478cbf" alt="Engine: Godot 4.7.2">
  <img src="https://img.shields.io/badge/Language-GDScript-355570?logo=godotengine&amp;logoColor=white" alt="Language: GDScript">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&amp;logoColor=white" alt="Platform: Windows">
  <img src="https://img.shields.io/badge/Platform-Linux-FCC624?logo=linux&amp;logoColor=black" alt="Platform: Linux">
  <img src="https://img.shields.io/badge/Platform-macOS-303030?logo=apple&amp;logoColor=white" alt="Platform: macOS">
  <a href="https://en.wikipedia.org/wiki/Role-playing_video_game"><img src="https://img.shields.io/badge/Genre-RPG-7B61A8" alt="Genre: RPG"></a>
  <a href="https://en.wikipedia.org/wiki/Sports_game"><img src="https://img.shields.io/badge/Genre-Sports-2E8B57" alt="Genre: Sports"></a>
  <img src="https://img.shields.io/badge/Original%20release-1990--07--20-6c757d" alt="Original game release date: 1990-07-20">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache--2.0-blue.svg" alt="Apache-2.0"></a>
</p>

# Captain Tsubasa 2 Remake

A Godot remake of *Captain Tsubasa 2: Super Striker* for Windows, macOS, and Linux. It is being developed as a standalone desktop game and does not require an external ROM or emulator.

## Table of Contents

1. [Current build](#current-build)
2. [Highlights](#highlights)
3. [Download](#download)
4. [System requirements](#system-requirements)
5. [Run from source](#run-from-source)
6. [Controls](#controls)
7. [Project structure](#project-structure)
8. [Development notes](#development-notes)
9. [CI and releases](#ci-and-releases)
10. [Contributing](#contributing)
11. [License and credits](#license-and-credits)

## Current build

The current release recreates the opening sequence and soundtrack, then presents the initial title screen. **KICK OFF** and **CONTINUE** are displayed, but match and story flows are not part of this release. Additional interface languages are planned and are not available yet.

## Highlights

- Opening presentation with original graphics, animation, text timing, and sound cues.
- Original opening soundtrack reproduced in a standalone Godot audio resource.
- Initial title screen with keyboard and controller cursor navigation.
- Built-in desktop updates download the matching platform package, verify its SHA-256 checksum, and offer **Install and Relaunch**.
- Windows and Linux provide separate **Help → About…** and **Help → Check for Updates…** commands. macOS keeps both in its native application menu. **F1** opens About; **F2** checks for updates. About shows the installed version and original release date; the update check uses a separate dialog.

## Download

Download the latest desktop release from [GitHub Releases](https://github.com/susimsek/captain-tsubasa-2-remake/releases/latest). Choose the package for your operating system. The exported game runs without Godot, a ROM file, or an emulator.

macOS releases are ad-hoc signed but not notarized, so Gatekeeper may ask you to approve the app the first time it opens. Windows releases are not Authenticode-signed and may show a SmartScreen warning.

## System requirements

- **Playing:** Windows x86_64, Linux x86_64, or macOS Universal.
- **Building from source:** Godot 4.7.2.

## Run from source

Open the project in Godot 4.7.2 and run the main scene, or launch it from a terminal:

    godot --path . scenes/main.tscn

## Controls

- Up / Down: move the title cursor.
- Tab / controller Back: switch the title selection.
- Enter / controller Start: trigger the opening's Start handoff. This does not select a title option.

## Project structure

- `scenes/` — main scene, opening runtime, and title screen.
- `scripts/` — presentation, rendering, input, and audio systems.
- `assets/opening/` — runtime audio and event data.
- `reference/rom_extract/` — source bytes, decoded records, and provenance for project resources.
- `reference/palettes/` — palette data used for NES-color comparisons.
- `docs/` — architecture and behavior notes.
- `tools/` — development and diagnostic utilities; these are not runtime dependencies.

## Development notes

The opening has been validated against FCEUX: all 4,693 frames in the visible 256×224 crop match the reference, and the generated soundtrack matches the captured PCM sample-for-sample. This validates the emulator reference; it does not establish original hardware sub-frame timing or analog audio output.

## CI and releases

Every branch push and pull request targeting **main** runs a clean Godot import, exports and launches a runtime pack, and performs a short headless startup check. Version tags trigger desktop exports for Linux x86_64, Windows x86_64, and macOS Universal. Each release includes those desktop packages, source archives, a SHA-256 manifest, and its Sigstore signature bundle. Desktop packages also include `THIRD_PARTY_NOTICES.txt` for required engine notices.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for commit and pull request conventions. Bugs and proposals can use the repository issue forms.

## License and credits

Project code is licensed under [Apache-2.0](LICENSE). Original game content is separate from the project code and is not covered by that license; the ROM is not included. Poster artwork source: [LaunchBox](https://images.launchbox-app.com/78127ee0-f18d-4a8d-87d1-eb8afdb3ca0a.jpg).

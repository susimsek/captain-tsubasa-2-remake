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
- Release builds check for updates after launch by default. The check only reports availability; downloading starts when you choose **Download Update**. You can turn automatic checks off in **Check for Updates…**.
- The built-in updater verifies the matching platform package before offering **Install and Relaunch**. Windows uses the per-user setup package for protected or temporary installs and the portable ZIP for writable installs.
- Windows and Linux provide separate **Help → About…** and **Help → Check for Updates…** commands. macOS keeps both in its native application menu. **F1** opens About; **F2** checks for updates. About shows the installed version and original release date; the update check uses a separate dialog.

## Download

Download the latest version from [GitHub Releases](https://github.com/susimsek/captain-tsubasa-2-remake/releases/latest). Choose the asset for your platform:

| Platform | Release asset | First launch |
| --- | --- | --- |
| Windows x86_64 | `captain-tsubasa-2-remake-vX.Y.Z-windows-x86_64-setup.exe` or `captain-tsubasa-2-remake-vX.Y.Z-windows-x86_64.zip` | The setup installs to your user account without administrator access. The ZIP is portable: extract it and open `captain-tsubasa-2-remake.exe`. |
| Linux x86_64 | `captain-tsubasa-2-remake-vX.Y.Z-x86_64.AppImage` or `captain-tsubasa-2-remake-vX.Y.Z-linux-x86_64.tar.gz` | For AppImage, make the file executable and launch it. For the tarball, extract and run `./captain-tsubasa-2-remake.x86_64`; `./install-desktop-entry.sh` adds a user-level menu launcher for that folder. |
| macOS Universal | `captain-tsubasa-2-remake-vX.Y.Z-macos-universal.zip` | Extract and open `Captain Tsubasa 2 Remake.app`. |

The in-game updater uses the Windows ZIP for writable portable installs and the per-user setup package when the current copy is in a protected or temporary folder. Linux updates use the package format matching the running install (AppImage or tarball); macOS updates replace the app bundle in place. Automatic checks never download or install an update on their own. If FUSE is unavailable, launch the AppImage with `--appimage-extract-and-run` or use the tarball instead. The game runs without Godot, a ROM file, or an emulator. macOS builds are ad-hoc signed but not notarized, so Gatekeeper may ask you to approve the app on first launch. Windows builds are not Authenticode-signed and may show a SmartScreen warning. Release assets include a SHA-256 manifest and Sigstore signature bundle.

## System requirements

- **Windows:** Windows 10 or later, x86_64.
- **Linux:** x86_64; a distribution released after 2018.
- **macOS:** Universal build for Intel and Apple silicon; Godot 4.7's baseline is macOS 11 or later on Intel and macOS 13 or later on Apple silicon.
- **Building from source:** Godot 4.7.2.

The operating system baselines follow [Godot 4.7's exported-project requirements](https://docs.godotengine.org/en/4.7/about/system_requirements.html).

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

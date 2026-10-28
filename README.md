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

A Godot remake of *Captain Tsubasa 2: Super Striker* for Windows, macOS, and Linux. The current build recreates the original opening and music, ending at the initial title screen with **KICK OFF** and **CONTINUE** visible. Match and story modes are not included in this build. Multilingual support is planned for a later stage of development.

The game runs without an external ROM or emulator. Project resources derived from the supplied ROM, along with their provenance, are documented under **reference/rom_extract/**.

The poster above is the original promotional artwork stored at `assets/readme/captain-tsubasa-2-poster.jpg`; the desktop application icons use the same image. It is separate from the ROM-derived game visuals. Source: [LaunchBox](https://images.launchbox-app.com/78127ee0-f18d-4a8d-87d1-eb8afdb3ca0a.jpg). The artwork remains the property of its respective rights holders.

## Table of Contents

1. [Highlights](#highlights)
2. [Current build](#current-build)
3. [Download](#download)
4. [System requirements](#system-requirements)
5. [Build and run locally](#build-and-run-locally)
6. [Controls](#controls)
7. [Project layout](#project-layout)
8. [Technical notes](#technical-notes)
9. [CI and releases](#ci-and-releases)
10. [Contributing](#contributing)
11. [License and original game content](#license-and-original-game-content)

## Highlights

- Reconstructed opening presentation with original sprite animation, text timing, and sound cues.
- Original opening soundtrack rendered from game data.
- Title-screen arrival with **KICK OFF** and **CONTINUE** visible.
- Standalone desktop builds for Windows, Linux, and macOS; no ROM or emulator is needed to play the current build.
- Built-in desktop update checks download the matching platform package, verify its SHA-256 digest, and offer **Install and Relaunch**.
- Windows and Linux provide separate **Help → About…** and **Help → Check for Updates…** commands. macOS keeps both commands in its native application menu. About shows version and original-release information; update checks open a separate dialog. F1 and F2 are keyboard shortcuts for those actions.

## Current build

This build covers the opening from a cold start through the initial title screen. The title choices are displayed, but selecting **KICK OFF** or **CONTINUE** does not enter a match or story flow. Multilingual support is planned and is not available in the current build.

The project is developed from documented game behavior and source data. Emulator recordings are used for comparison, not as runtime assets.

## Download

Download the latest desktop build from the [GitHub Releases page](https://github.com/susimsek/captain-tsubasa-2-remake/releases/latest). Choose the package for Windows, macOS, or Linux.

## System requirements

- Godot 4.7.2
- Desktop keyboard or gamepad

## Build and run locally

Open this folder in Godot 4.7.2 and run the main scene. From a terminal with Godot available:

    godot --path . scenes/main.tscn

## Controls

- Up / Down: move the title cursor.
- Tab / controller Back: switch the title selection.
- Enter / controller Start: trigger the opening's Start handoff. The title options themselves remain unconfirmed in this milestone.

## Project layout

- **scenes/**: main scene, opening runtime, and title menu.
- **scripts/**: ROM-derived presenter, renderers, input, and audio code.
- **assets/opening/**: project-owned runtime audio and event data.
- **reference/rom_extract/**: source bytes, decoded records, and provenance for runtime resources.
- **reference/palettes/**: the documented external palette used for NES-color comparison.
- **docs/**: focused architecture and behavior notes.
- **tools/**: extraction and diagnostic utilities; these are not runtime dependencies.

## Technical notes

The project's latest same-input comparison reports a full match for the visible 256×224 NTSC crop across 4,693 opening frames. Raw 256×240 PPU comparisons preserve the overscan rows and can show a small y=0 difference. This does not establish physical 2C02 sub-frame timing.

The active soundtrack is generated from ROM-derived CPU/APU/DMC events and the pinned FCEUX audio filter implementation. Its PCM matches the recorded FCEUX filtered reference; that comparison is not a claim about analog NES output.

## CI and releases

Every branch push and pull request targeting **main** runs a clean Godot import and a short headless main-scene launch. Version tags use the release workflow, which checks the project, exports Linux x86_64, Windows x86_64, and macOS Universal desktop packages, and publishes those with source ZIP/TAR.GZ archives, a SHA-256 manifest, and a verified Sigstore signature bundle. Desktop packages include `THIRD_PARTY_NOTICES.txt` for required engine notices; this does not add engine branding to the game's menus. The macOS app has a valid built-in ad-hoc signature but is not notarized, so Gatekeeper may still require a one-time approval; a Developer ID signature and notarization are needed to avoid that prompt. The Windows executable is not Authenticode-signed and may show a SmartScreen unknown-publisher warning. The Linux archive preserves the executable permission. If the RELEASE_GPG_PRIVATE_KEY Actions secret is configured, the manifest also receives a detached GPG signature; RELEASE_GPG_PASSPHRASE is optional for an unencrypted key.

Sonar badges and quality gates are intentionally absent: Sonar's documented supported-language list does not include GDScript, so it would not analyze the game's main code.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for commit and pull request conventions. Bugs and proposals can use the repository issue forms.

## License and original game content

The project license is [Apache-2.0](LICENSE) for work that the project contributors are entitled to license. The original game's ROM, graphics, music, text, characters, and marks are not relicensed by this file. The ROM itself is not part of this repository.

The poster file is not covered by the Apache-2.0 license.

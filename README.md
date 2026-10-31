<div align="center">

<img src="docs/assets/branding/sagrada-space.png" alt="Sagrada Space — cosmic stained-glass windows inspired by Sagrada Família" width="200" height="200">

# Sagrada Space

### Celestial light. Structured space.

A keyboard-first tiling window manager for macOS.<br>
The power of AeroSpace, with native dwindle splits and a quieter menu bar.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111827?style=flat-square&logo=apple&logoColor=white)
![Native Swift](https://img.shields.io/badge/Native-Swift-F05138?style=flat-square&logo=swift&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-8B5CF6?style=flat-square)](LICENSE.txt)

[Get started](#get-started) · [How it tiles](#how-it-tiles) · [Configuration](#make-it-yours) · [Keybindings](#at-your-fingertips) · [Upstream docs](https://nikitabobko.github.io/AeroSpace/guide)

</div>

---

## Your next window, already in place

Open a terminal. Add an editor. Bring in a browser. **Dwindle splits the tile you were working in**, keeping the rest of your layout intact. No separate tiling script. No manual rearranging after every launch.

This is a personal fork of [AeroSpace](https://github.com/nikitabobko/AeroSpace), not an official upstream release. It keeps AeroSpace’s tree-based controls and adds an opinionated insertion policy, ordered workspace indicators, and a minimal menu.

| A focused fork | What you get |
| :--- | :--- |
| **Native dwindle** | New tiled windows split the most recently focused tile equally, alternating split directions. |
| **Your layout stays yours** | Existing outer split sizes survive. Focus, move, resize, join, and layout commands still work on the same tree. |
| **A quieter menu bar** | Ordered i3-style indicators for occupied/visible workspaces on macOS 14+, with essential menu actions. Saved appearance preferences are respected. |
| **Keyboard-first control** | Fast workspace switching, a scriptable CLI, and plain-text TOML configuration. |
| **Built for multiple displays** | AeroSpace’s virtual workspaces and i3-like multi-monitor model, without disabling SIP. |
| **An easy off switch** | Set `enable-dwindle = false` to restore upstream sibling insertion. |

## How it tiles

With a horizontal root and each newly opened window focused, the layout grows like this:

```text
       One window                  Two windows                 Three windows
┌─────────────────────┐     ┌──────────┬──────────┐     ┌──────────┬──────────┐
│                     │     │          │          │     │          │    2     │
│          1          │  →  │    1     │    2     │  →  │    1     ├──────────┤
│                     │     │          │          │     │          │    3     │
└─────────────────────┘     └──────────┴──────────┘     └──────────┴──────────┘

                                                            Four windows
                                                       ┌──────────┬──────────┐
                                                       │          │    2     │
                                                    →  │    1     ├─────┬────┤
                                                       │          │  3  │ 4  │
                                                       └──────────┴─────┴────┘
```

**Focus decides where the next split happens.** Return to window 1 before opening another window, and that tile splits instead. The first pair follows the workspace orientation; subsequent splits alternate vertically and horizontally.

Dwindle is an **insertion policy, not a forced reflow**. Manually edited layouts remain yours. Floating windows and accordion containers keep their existing behavior.

## Get started

> [!IMPORTANT]
> **Build this repository to get Sagrada Space.** Upstream Homebrew binaries do not include Dwindle or the menu changes. The app and CLI retain the names `AeroSpace.app` and `aerospace`; do not run them alongside another AeroSpace instance.

### 1 · Build a release app

The app targets **macOS 13+**; workspace indicators require **macOS 14+**. SwiftPM declares Swift **6.2+**, but release tooling can require a newer toolchain. Follow the [development prerequisites](dev-docs/development.md) and the repository’s [Swift version](.swift-version).

For a release build, install full Xcode, accept its license, set up the documented build dependencies (including docs and shell completions), and create a code-signing certificate named `aerospace-codesign-certificate`.

```sh
git clone https://github.com/sebastianstoecklin/Sagrada-Space.git
cd Sagrada-Space
./build-release.sh
```

The output is **`.release/AeroSpace.app`** and **`.release/aerospace`**. Use this release app for daily use: debug executables ignore `start-at-login` and can depend on this checkout.

### 2 · Install the app and CLI

Quit any running AeroSpace instance and disable its old login item under **System Settings → General → Login Items**. If you installed upstream through Homebrew, uninstall that cask first to avoid launching or updating the wrong app:

```sh
# Only if the upstream cask is installed:
brew uninstall --cask aerospace
```

Move any existing `/Applications/AeroSpace.app` aside, then install:

```sh
sudo ditto .release/AeroSpace.app /Applications/AeroSpace.app
mkdir -p "$HOME/.local/bin"
install -m 755 .release/aerospace "$HOME/.local/bin/aerospace"
```

Add the following to `~/.zprofile` (or your shell’s equivalent), open a new terminal, and check `command -v aerospace` resolves to your new CLI rather than an old Homebrew binary:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

### 3 · Launch and grant permission

```sh
open /Applications/AeroSpace.app
```

Grant **AeroSpace** access in **System Settings → Privacy & Security → Accessibility**. If a previous entry no longer works after replacement, remove it, add the installed app again, and relaunch.

To launch automatically, put this at the top level of your active `~/.aerospace.toml`, **before any table headers**, and run `aerospace reload-config`:

```toml
start-at-login = true
```

Allow the login item if macOS asks. The installed release app runs independently of this checkout.

## Make it yours

### Keep your existing setup

Existing user configs take precedence; building does **not** overwrite them. Dwindle is enabled by default in this fork. To make the choice explicit, add this before any `[table]` headers:

```toml
enable-dwindle = true
```

Set it to `false` to restore upstream insertion, then run `aerospace reload-config`.

> [!WARNING]
> Remove the old `dwindle.sh` window-detection callback if you used one. Native Dwindle runs synchronously in the engine; do not run both implementations together.

### Adopt the bundled setup

The [bundled config](docs/config-examples/default-config.toml) is deliberately personal: Cmd-based navigation, 10-point gaps, app launch shortcuts, workspace 5 assigned to the secondary display, and a JankyBorders startup hook. **Review it before copying**—its shortcuts can override familiar macOS/app shortcuts.

```sh
# Preserve your current config, if one exists.
if [ -f "$HOME/.aerospace.toml" ]; then
    cp "$HOME/.aerospace.toml" "$HOME/.aerospace.toml.backup-$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$HOME/.config/aerospace"
cp script/workspace-layout.sh "$HOME/.config/aerospace/"
cp docs/config-examples/default-config.toml "$HOME/.aerospace.toml"
aerospace reload-config
```

- **Workspace floating:** the helper provides the workspace-wide floating toggle and stores state in `~/.local/state/aerospace/workspace-layout`. It needs this fork’s CLI on `PATH`. Remove its callback and shortcut if you do not use it.
- **Borders and launchers:** install or adjust the machine-specific `~/.config/borders/bordersrc` startup command and app launch bindings (including Ghostty, Zen, and Obsidian).
- **A simpler starting point:** the [preserved upstream config](docs/config-examples/upstream-default-config.toml) is available for reference; Dwindle remains enabled unless explicitly disabled.

## At your fingertips

These shortcuts belong to the **bundled config**, not upstream defaults.

| Shortcut | Action |
| :--- | :--- |
| `⌘` + arrow keys | Focus a window |
| `⌘ ⇧` + arrow keys | Move a window |
| `⌘` + `1`–`9` | Switch workspace |
| `⌘ ⇧` + `1`–`9` | Move a window to a workspace |
| `⌥ Tab` | Return to the previous workspace |
| `⌥ ⇧ Tab` | Move the workspace to the next monitor |
| `⌘ ⇧ -` / `⌘ ⇧ =` | Shrink / grow a tile |
| `⌘ ⌥ F` | Toggle the focused window between floating and tiling |
| `⌘ ⌥ ⇧ F` | Toggle floating for the workspace (helper required) |
| `⌘ Return` | Open Ghostty (must be installed) |

Prefer a terminal? The same controls are scriptable:

```sh
aerospace focus left
aerospace workspace 2
aerospace move-node-to-workspace 3
aerospace reload-config
```

Find the full command surface in the [AeroSpace command reference](https://nikitabobko.github.io/AeroSpace/commands).

## Development & maintenance

<details>
<summary><strong>Quick development build and tests</strong></summary>

With a compatible Swift toolchain and full Xcode for XCTest, a direct SwiftPM build avoids the release scripts’ docs/completion dependencies:

```sh
swift build --build-tests
swift test --skip-build
bin_dir="$(swift build --show-bin-path)"
mkdir -p .debug
cp "$bin_dir/AeroSpaceApp" "$bin_dir/aerospace" .debug/
```

Run `.debug/AeroSpaceApp` from a terminal with Accessibility permission; use `.debug/aerospace` for commands. Do not run another instance at the same time.

On macOS 27 beta Command Line Tools, missing `SwiftUIMacros` or XCTest may require the full Xcode toolchain. See the [development notes](dev-docs/development.md) for toolchain selection and workarounds.

Dwindle-specific tests cover alternating splits, focus selection, weight preservation, floating/accordion behavior, close/reinsert, and opting out.

</details>

<details>
<summary><strong>Update or uninstall</strong></summary>

**Update:** quit AeroSpace, rebuild, and repeat the release app/CLI installation steps. Keep the same signing certificate to reduce Accessibility permission resets. This fork does not receive upstream Homebrew updates automatically.

**Uninstall:** set `start-at-login = false`, reload, and quit. Remove `/Applications/AeroSpace.app` and `~/.local/bin/aerospace`, then remove any remaining login item in System Settings. Keep or remove your config and helper state as desired.

</details>

<details>
<summary><strong>App icon and branding</strong></summary>

The Sagrada Space icon combines Sagrada Família-inspired stained glass, branching geometry, and nebula light with recursive window splits. The README and macOS app share the same [master artwork](docs/assets/branding/sagrada-space.png); the app asset catalog includes all standard macOS icon sizes.

See [branding notes](docs/assets/branding/README.md) for the image-generation prompt and regeneration instructions.

</details>

## Built on AeroSpace

This fork exists thanks to **[Nikita Bobko](https://github.com/nikitabobko) and the AeroSpace contributors**. The underlying window manager, workspace model, CLI, and documentation are their work. This fork focuses on Dwindle insertion and its own default experience; it is not affiliated with Apple.

- [Upstream project](https://github.com/nikitabobko/AeroSpace) · [User guide](https://nikitabobko.github.io/AeroSpace/guide) · [Configuration goodies](https://nikitabobko.github.io/AeroSpace/goodies)
- [91-second upstream demo](https://www.youtube.com/watch?v=UOl7ErqWbrk) · [Video guide by Josean Martinez](https://www.youtube.com/watch?v=-FoWClVHG5g) — these showcase upstream, not the fork-specific changes.
- [Contributing guidelines](CONTRIBUTING.md) · [Upstream discussions](https://github.com/nikitabobko/AeroSpace/discussions) — reproduce fork-specific problems on upstream before reporting them there.
- [Sponsor upstream development](https://github.com/sponsors/nikitabobko)

Released under the [MIT License](LICENSE.txt). Original copyright and third-party notices are retained in [legal/](legal).

---

<div align="center">

**Keep your hands on the keyboard. Let your windows fall into place.**

</div>

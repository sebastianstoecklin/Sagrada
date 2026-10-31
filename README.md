<div align="center">

<img src="docs/assets/branding/sagradaspace.png" alt="SagradaSpace — cosmic stained-glass windows inspired by Sagrada Família" width="200" height="200">

# SagradaSpace

### Celestial light. Structured space.

A keyboard-first tiling window manager for macOS.<br>
The power of AeroSpace, with native dwindle splits and a quieter menu bar.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111827?style=flat-square&logo=apple&logoColor=white)
![Native Swift](https://img.shields.io/badge/Native-Swift-F05138?style=flat-square&logo=swift&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-8B5CF6?style=flat-square)](LICENSE.txt)

[Download](https://github.com/sebastianstoecklin/SagradaSpace/releases/latest) · [Get started](#get-started) · [How it tiles](#how-it-tiles) · [Configuration](#make-it-yours) · [Keybindings](#at-your-fingertips) · [Upstream docs](https://nikitabobko.github.io/AeroSpace/guide)

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
> **Download SagradaSpace from this repository’s [GitHub Releases](https://github.com/sebastianstoecklin/SagradaSpace/releases/latest).** Upstream Homebrew binaries do not include Dwindle or the menu changes. This fork installs as `SagradaSpace.app` with the `sagradaspace` CLI. Do not run it alongside AeroSpace or another tiling window manager.

### 1 · Download the release

Download **[SagradaSpace-v0.1.0.zip](https://github.com/sebastianstoecklin/SagradaSpace/releases/download/v0.1.0/SagradaSpace-v0.1.0.zip)** and extract it. The app and CLI are universal binaries for **Apple Silicon and Intel**, targeting **macOS 13+**; workspace indicators require **macOS 14+**. No Xcode or source checkout is required.

Optionally download the accompanying `.zip.sha256` file into the same directory and verify the archive before extracting:

```sh
cd ~/Downloads
shasum -a 256 -c SagradaSpace-v0.1.0.zip.sha256
unzip SagradaSpace-v0.1.0.zip
cd SagradaSpace-v0.1.0
```

The package contains `SagradaSpace.app`, `bin/sagradaspace`, optional configuration examples and the workspace helper in `config/`, and license notices. Generated man pages and shell completions are not included in v0.1.0.

> [!WARNING]
> **v0.1.0 is ad-hoc signed, not Developer ID signed or notarized.** macOS may block the downloaded app or CLI. Only if you trust this repository and have verified the download, try opening the app, then use **System Settings → Privacy & Security → Open Anyway** and confirm. The CLI may need the same approval. Do not disable Gatekeeper globally.

<details>
<summary><strong>Prefer building from source?</strong></summary>

SwiftPM declares Swift **6.2+**, but release tooling can require a newer toolchain. Follow the [development prerequisites](dev-docs/development.md) and the repository’s [Swift version](.swift-version). Install full Xcode, accept its license, and set up the documented dependencies (including docs and shell completions).

```sh
git clone https://github.com/sebastianstoecklin/SagradaSpace.git
cd SagradaSpace
./build-release.sh --codesign-identity -
```

This creates a local ad-hoc signed **`.release/SagradaSpace.app`** and **`.release/sagradaspace`**. Alternatively, create a certificate named `sagradaspace-codesign-certificate` and omit `--codesign-identity -`. For the installation commands below, use `.release/SagradaSpace.app` and `.release/sagradaspace` instead of the downloaded package paths.

Use a release app for daily use: debug executables ignore `start-at-login` and can depend on the checkout.

</details>

### 2 · Install the app and CLI

Quit any running SagradaSpace or AeroSpace instance and disable its old login item under **System Settings → General → Login Items**. If you installed upstream through Homebrew, uninstall that cask first to avoid launching or updating the wrong app:

```sh
# Only if the upstream cask is installed:
brew uninstall --cask aerospace
```

Move any existing `/Applications/SagradaSpace.app` aside, then install:

```sh
# Run from the extracted SagradaSpace-v0.1.0 directory:
sudo ditto SagradaSpace.app /Applications/SagradaSpace.app
mkdir -p "$HOME/.local/bin"
install -m 755 bin/sagradaspace "$HOME/.local/bin/sagradaspace"
```

Add the following to `~/.zprofile` (or your shell’s equivalent), open a new terminal, and check `command -v sagradaspace` resolves to your new CLI rather than an old Homebrew binary:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

### 3 · Launch and grant permission

```sh
open /Applications/SagradaSpace.app
```

Grant **SagradaSpace** access in **System Settings → Privacy & Security → Accessibility**. If a previous entry no longer works after replacement, remove it, add the installed app again, and relaunch.

To launch automatically, put this at the top level of your active `~/.aerospace.toml`, **before any table headers**, and run `sagradaspace reload-config`:

```toml
start-at-login = true
```

Allow the login item if macOS asks. The installed release app runs independently of this checkout.

### Migrating from the AeroSpace-named build

SagradaSpace has its own bundle identifier (`com.sebastianstoecklin.sagradaspace`), Accessibility permission, login item, and CLI. Disable the old login item and quit the old app before launching it. Replace `aerospace` with `sagradaspace` in your own scripts and shell aliases; no compatibility CLI is installed automatically.

For configuration compatibility, `~/.aerospace.toml`, `${XDG_CONFIG_HOME:-~/.config}/aerospace/aerospace.toml`, `AEROSPACE_*` callback variables, and the workspace helper's existing paths remain unchanged. Your configuration is not copied or overwritten. The inherited documentation under `docs/` describes upstream AeroSpace; substitute `sagradaspace` for its `aerospace` commands when using this fork.

## Make it yours

### Keep your existing setup

Existing user configs take precedence; building does **not** overwrite them. Dwindle is enabled by default in this fork. To make the choice explicit, add this before any `[table]` headers:

```toml
enable-dwindle = true
```

Set it to `false` to restore upstream insertion, then run `sagradaspace reload-config`.

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
sagradaspace reload-config
```

When using the downloaded release instead of a source checkout, substitute `config/workspace-layout.sh` and `config/default-config.toml` for the two source paths above.

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
sagradaspace focus left
sagradaspace workspace 2
sagradaspace move-node-to-workspace 3
sagradaspace reload-config
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
cp "$bin_dir/SagradaSpaceApp" "$bin_dir/sagradaspace" .debug/
```

Run `.debug/SagradaSpaceApp` from a terminal with Accessibility permission; use `.debug/sagradaspace` for commands. Do not run another instance at the same time.

On macOS 27 beta Command Line Tools, missing `SwiftUIMacros` or XCTest may require the full Xcode toolchain. See the [development notes](dev-docs/development.md) for toolchain selection and workarounds.

Dwindle-specific tests cover alternating splits, focus selection, weight preservation, floating/accordion behavior, close/reinsert, and opting out.

</details>

<details>
<summary><strong>Update or uninstall</strong></summary>

**Update:** quit SagradaSpace, download the latest [release](https://github.com/sebastianstoecklin/SagradaSpace/releases/latest) (or rebuild), and repeat the release app/CLI installation steps. Keep the same signing certificate to reduce Accessibility permission resets. This fork does not receive upstream Homebrew updates automatically.

**Uninstall:** set `start-at-login = false`, reload, and quit. Remove `/Applications/SagradaSpace.app` and `~/.local/bin/sagradaspace`, then remove any remaining login item in System Settings. Keep or remove your config and helper state as desired.

</details>

<details>
<summary><strong>App icon and branding</strong></summary>

The SagradaSpace icon combines Sagrada Família-inspired stained glass, branching geometry, and nebula light with recursive window splits. The README and macOS app share the same [master artwork](docs/assets/branding/sagradaspace.png); the app asset catalog includes all standard macOS icon sizes.

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

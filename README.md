<div align="center">

<img src="docs/assets/branding/sagrada.png" alt="Sagrada — cosmic stained-glass windows inspired by Sagrada Família" width="200" height="200">

# Sagrada

### Celestial light. Structured space.

A keyboard-first tiling window manager for macOS.<br>
The power of AeroSpace, with native dwindle splits, integrated window borders, and a quieter menu bar.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111827?style=flat-square&logo=apple&logoColor=white)
![Native Swift](https://img.shields.io/badge/Native-Swift-F05138?style=flat-square&logo=swift&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-8B5CF6?style=flat-square)](LICENSE.txt)

[Download](https://github.com/sebastianstoecklin/Sagrada/releases/latest) · [Get started](#get-started) · [How it tiles](#how-it-tiles) · [Configuration](#make-it-yours) · [Keybindings](#at-your-fingertips) · [Upstream docs](https://nikitabobko.github.io/AeroSpace/guide)

</div>

---

## Sagrada 0.4.0

**[Download Sagrada 0.4.0](https://github.com/sebastianstoecklin/Sagrada/releases/download/v0.4.0/Sagrada-v0.4.0.zip)** · [Release notes](https://github.com/sebastianstoecklin/Sagrada/releases/tag/v0.4.0) · [SHA-256 checksum](https://github.com/sebastianstoecklin/Sagrada/releases/download/v0.4.0/Sagrada-v0.4.0.zip.sha256)

One universal download for **Apple Silicon and Intel**, with native Dwindle splits, bundled **JankyBorders 1.9.0**, and **Caffeinate** controls. Version 0.4.0 adds an opt-in **[Scroll Reverser](#scroll-reverser-opt-in)** for classic mouse wheels, with independent axis controls and unchanged continuous trackpad/Magic Mouse scrolling.

## Your next window, already in place

Open a terminal. Add an editor. Bring in a browser. **Dwindle splits the tile you were working in**, keeping the rest of your layout intact. No separate tiling script. No manual rearranging after every launch.

This is a personal fork of [AeroSpace](https://github.com/nikitabobko/AeroSpace), not an official upstream release. It keeps AeroSpace’s tree-based controls and adds an opinionated insertion policy, ordered workspace indicators, and a minimal menu.

| A focused fork | What you get |
| :--- | :--- |
| **Native dwindle** | New tiled windows split the most recently focused tile equally, alternating split directions. |
| **Your layout stays yours** | Existing outer split sizes survive. Focus, move, resize, join, and layout commands still work on the same tree. |
| **A quieter menu bar** | Ordered i3-style indicators for occupied/visible workspaces on macOS 14+, with essential menu actions. Saved appearance preferences are respected. |
| **Integrated borders** | Bundled JankyBorders, configured in TOML and managed with the app (macOS 14+). |
| **Stay awake when needed** | Caffeinate modes for normal idle-sleep prevention or keeping the display awake. |
| **Mouse-wheel scrolling, your way** | Optional scroll reversal for discrete wheel events, with separate vertical/horizontal controls and gesture passthrough. |
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

**Omarchy-style rearranging:** `⌘ ⇧` + arrow keys swaps the focused window with a neighboring tile, keeping the split tree and tile sizes intact. This mirrors Omarchy's `SUPER SHIFT` + arrows (`swapwindow`), with Cmd replacing SUPER. AeroSpace's `move` command instead edits the tree and can turn two columns into three; it remains available through the CLI.

## Get started

Download the app for **Apple Silicon or Intel**, running **macOS 13+**. Workspace indicators and integrated JankyBorders require **macOS 14+**. No Xcode or Terminal needed.

### Install the app

1. Download the ZIP from **[GitHub Releases](https://github.com/sebastianstoecklin/Sagrada/releases/latest)** and double-click it to extract it.
2. Quit any other tiling window manager before opening Sagrada.
3. Drag **Sagrada.app** into your **Applications** folder.
4. Open Sagrada and grant access in **System Settings → Privacy & Security → Accessibility**.

That’s it. You can ignore the other files in the download.

> [!NOTE]
> The current release is not notarized by Apple, so macOS may block it. If you trust the download, try opening the app, then go to **System Settings → Privacy & Security → Open Anyway** and confirm. Do not disable Gatekeeper.

Sagrada needs Accessibility permission to manage windows. User configuration files are not overwritten.

### Start at login (optional)

Add this at the top of your `~/.sagrada.toml`, before any section headers:

```toml
start-at-login = true
```

Choose **Reload config** from the Sagrada menu and allow the login item if macOS asks.

## Build from source

For a local release app, install full **Xcode**, accept its license, and follow the [build prerequisites](dev-docs/development.md#1-install-dependencies), including the docs and shell-completion dependencies. Use the toolchain specified in [`.swift-version`](.swift-version).

```sh
git clone https://github.com/sebastianstoecklin/Sagrada.git
cd Sagrada
./build-release.sh --codesign-identity -
open .release
```

Drag **Sagrada.app** from the folder that opens into **Applications**, then open it and grant Accessibility access as above. This is an ad-hoc signed release build; no Apple Developer membership or custom signing certificate is required. Once installed, the app does not depend on the checkout.

## Make it yours

### Configure Sagrada

Use `~/.sagrada.toml` or `$XDG_CONFIG_HOME/sagrada/sagrada.toml`. Building does **not** overwrite your configuration. Dwindle is enabled by default. To make the choice explicit, add this before any `[table]` headers:

```toml
enable-dwindle = true
```

Set it to `false` to restore upstream insertion, then choose **Reload config** from the Sagrada menu.

### Adopt the bundled setup

The [bundled config](docs/config-examples/default-config.toml) is deliberately personal: Cmd-based navigation, 10-point gaps, app launch shortcuts, workspace 5 assigned to the secondary display, and integrated JankyBorders. **Review it before copying**—its shortcuts can override familiar macOS/app shortcuts.

```sh
# Preserve your current config, if one exists.
if [ -f "$HOME/.sagrada.toml" ]; then
    cp "$HOME/.sagrada.toml" "$HOME/.sagrada.toml.backup-$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$HOME/.config/aerospace"
cp script/workspace-layout.sh "$HOME/.config/aerospace/"
cp docs/config-examples/default-config.toml "$HOME/.sagrada.toml"
```

Choose **Reload config** from the Sagrada menu.

**Existing configs:** to adopt only Omarchy-style rearranging, replace the four `cmd-shift-<arrow> = 'move <direction>'` bindings in your config with:

```toml
# Inside [mode.main.binding]
cmd-shift-left = 'swap left'
cmd-shift-down = 'swap down'
cmd-shift-up = 'swap up'
cmd-shift-right = 'swap right'
```

For `⌘ ⇧` + `1`–`9` to follow the window to its destination as in Omarchy, add `--focus-follows-window` to each numbered binding, for example:

```toml
cmd-shift-1 = 'move-node-to-workspace --focus-follows-window 1'
# Repeat for 2–9 with the corresponding workspace number.
```

Then reload the config. No app rebuild is needed for these binding changes; the commands are already supported.

When using the downloaded release instead of a source checkout, substitute `config/workspace-layout.sh` and `config/default-config.toml` for the two source paths above.

- **Workspace floating:** the helper provides the workspace-wide floating toggle and stores state in `~/.local/state/aerospace/workspace-layout`. It needs this fork’s CLI on `PATH`. Remove its callback and shortcut if you do not use it.
- **Borders:** JankyBorders 1.9.0 is bundled (macOS 14+). Configure `[borders]` in TOML: `enabled`, `width` (0–100 whole points), `style` (`round`, `square`, `uniform`), `active-color`, `inactive-color`, `background-color` (`0xAARRGGBB`), `hidpi`, `ax-focus`, `blacklist` and `whitelist` (comma-separated app names). Reload applies changes; disabling or quitting stops the helper. Enable borders with `enabled = true` inside `[borders]`. Run only the bundled helper to avoid duplicate borders.
- **Caffeinate:** the menu bar submenu offers **Off**, **Keep Awake** (standard idle-sleep prevention), and **Keep Screen Awake** (also keeps the display on). The active option uses the same native selection indicator as Appearance. Starts off; quitting stops it. It also releases assertions if Sagrada exits unexpectedly.
- **Launchers:** adjust app launch bindings (including Ghostty, Zen, and Obsidian) to your setup.

### Scroll Reverser (opt-in)

Available in **0.4.0 and later**, and disabled by default in both new and existing configurations. No external helper is required.

Choose **Scroll Reverser → Enabled** in the menu bar to reverse classic mouse-wheel scrolling without changing macOS's Natural Scrolling preference. **Reverse Vertical** and **Reverse Horizontal** can be toggled independently. The defaults are off overall, vertical reversal on, horizontal reversal off.

To persist your choice, add this top-level table to `~/.sagrada.toml` and reload the config:

```toml
[scroll-reverser]
enabled = true
reverse-vertical = true
reverse-horizontal = false
```

Menu changes are session-only: a config reload or app restart restores the TOML settings. If both axes are off, no scroll filter is installed. Disabling the feature or quitting Sagrada removes the filter.

**Permissions:** Sagrada uses a macOS event tap. If it cannot start, the submenu shows an error and offers **Grant Permissions / Retry** and a link to Input Monitoring settings. Check **System Settings → Privacy & Security → Accessibility** and, if requested by macOS, **Input Monitoring** for Sagrada. After granting access, retry or restart the app. The feature does not explicitly request permissions while disabled; permission prompts are initiated through the retry button.

**Device limitations:** this first version filters **discrete wheel events**, not a physical-device whitelist. Continuous scrolling, gesture phases, and momentum events from trackpads and Magic Mouse pass through unchanged. Some smooth-scrolling mice/drivers also emit continuous events and therefore will not be reversed; software that converts touch gestures into discrete wheel events cannot be distinguished reliably. Do not enable another scroll-reversal tool at the same time, as the two can cancel each other out.

## At your fingertips

All active shortcuts in the [bundled config](docs/config-examples/default-config.toml) are listed below, including service mode. Your own config may differ; installing or updating Sagrada does not overwrite it.

**Notation:** `⌘` = Cmd, `⌥` = Option/Alt, `⇧` = Shift, `⌃` = Control. Omarchy's `SUPER` is typically the Windows/Linux-logo key. Directions and number ranges represent each individual key. Punctuation names refer to the configured keys (`slash`, `comma`, `minus`, `equal`, `semicolon`), not necessarily the printed character on every keyboard layout.

**Comparison baseline:** [Omarchy v3.0.0 tiling bindings](https://github.com/omacom/omarchy/blob/v3.0.0/default/hypr/bindings/tiling.conf), [application bindings](https://github.com/omacom/omarchy/blob/v3.0.0/config/hypr/bindings.conf), and [media bindings](https://github.com/omacom/omarchy/blob/v3.0.0/default/hypr/bindings/media.conf). Omarchy defaults can change between versions. “Similar” means a related action, not identical behavior; “—” means no direct default equivalent in that baseline. These are comparisons, not additional bindings installed by Sagrada.

### Focus, workspaces, and window placement

| Sagrada shortcut | Action | Omarchy equivalent |
| :--- | :--- | :--- |
| `⌘` + `←` / `↓` / `↑` / `→` | Focus a window in that direction | `SUPER` + corresponding arrow |
| `⌘ ⇧` + `←` / `↓` / `↑` / `→` | Swap with a neighboring tile; preserve splits and sizes | `SUPER SHIFT` + corresponding arrow (`swapwindow`) |
| `⌘` + `1`–`9` | Switch to workspace 1–9 | `SUPER` + `1`–`9` |
| `⌘ ⇧` + `1`–`9` | Move the window to workspace 1–9 and follow it | `SUPER SHIFT` + `1`–`9` (`movetoworkspace`) |
| `⌥ Tab` | Return to the previously focused workspace | `SUPER CTRL Tab`; Omarchy's `ALT Tab` cycles windows instead |
| `⌥ ⇧ Tab` | Move the current workspace to the next monitor, wrapping around | — |
| `⌘ ⇧ -` | Shrink a tile by 50 points on its smart axis | Similar: `SUPER -` shrinks horizontally; `SUPER SHIFT -` shrinks vertically, in 100-pixel steps |
| `⌘ ⇧ =` | Grow a tile by 50 points on its smart axis | Similar: `SUPER =` grows horizontally; `SUPER SHIFT =` grows vertically, in 100-pixel steps |

### Layout controls

| Sagrada shortcut | Action | Omarchy equivalent |
| :--- | :--- | :--- |
| `⌘ ⇧ /` | Select tiles layout; cycle horizontal/vertical orientation | Similar: `SUPER J` toggles the Dwindle split direction; not a tiles/accordion selector |
| `⌘ ⇧ ,` | Select accordion layout; cycle horizontal/vertical orientation | — (no direct accordion equivalent) |
| `⌘ ⌥ F` | Toggle the focused window between floating and tiling | `SUPER V` |
| `⌘ ⌥ ⇧ F` | Toggle floating for the entire workspace | —; Sagrada requires the [workspace-layout helper](script/workspace-layout.sh) |
| `⌘ ⌃ ←` / `⌘ ⌃ →` | Join the focused window with the nearest node on that side under a common split container | — (not the same as Hyprland window groups) |
| `⌘ ⇧ ;` | Enter service mode (see below) | — |

### Application launchers

Apps must be installed. Omarchy equivalents below match the **purpose**, not necessarily the application or launch/focus behavior.

| Sagrada shortcut | Opens | Omarchy equivalent |
| :--- | :--- | :--- |
| `⌘ Return` | A new Ghostty instance | `SUPER Return` — configured terminal |
| `⌘ ⇧ F` | Finder | `SUPER F` — file manager (Nautilus) |
| `⌘ ⇧ C` | Visual Studio Code | `SUPER N` — configured editor |
| `⌘ ⇧ M` | Mail | `SUPER E` — email (HEY web app) |
| `⌘ ⇧ K` | Calendar | `SUPER C` — calendar (HEY web app) |
| `⌘ ⇧ W` | Microsoft Word | — |
| `⌘ ⇧ B` | Zen | `SUPER B` — configured browser; Omarchy's `SUPER SHIFT B` opens a **private** browser window |
| `⌘ ⇧ O` | Obsidian | `SUPER O` — launch or focus Obsidian |
| `⌘ ⇧ P` | Strongbox | `SUPER /` — password manager (1Password) |

### Service mode

First press `⌘ ⇧ ;`, then use one of these bindings. All actions below return to main mode **except** plain `↑` and `↓`, which keep service mode active. Main-mode bindings do not apply while in service mode.

| Key in service mode | Action | Omarchy equivalent |
| :--- | :--- | :--- |
| `Esc` | Reload configuration and return to main mode | No matching binding; Hyprland normally reloads its config automatically |
| `R` | Flatten the workspace tree and return to main mode | — |
| `F` | Toggle the focused window between floating and tiling; return to main mode | `SUPER V` (no service mode required) |
| `Backspace` | Close all windows on the current workspace except the focused one; return to main mode | —; Omarchy's `CTRL ALT Delete` closes **all** windows, not “all but current” |
| `⌘ ⇧ H` | Join with the node to the left; return to main mode | — |
| `⌘ ⇧ J` | Join with the node below; return to main mode | — |
| `⌘ ⇧ K` | Join with the node above; return to main mode | — |
| `⌘ ⇧ L` | Join with the node to the right; return to main mode | — |
| `↓` | Lower volume; remain in service mode | Volume-down media key (no service mode required) |
| `↑` | Raise volume; remain in service mode | Volume-up media key (no service mode required) |
| `⇧ ↓` | Set volume to zero and return to main mode | Similar: mute media key **toggles mute** rather than setting volume to zero |

`⌘ Backspace` is deliberately **not bound**, leaving Finder's Move to Trash shortcut free. The commented-out sticky binding is not active or supported.

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
cp "$bin_dir/SagradaApp" "$bin_dir/sagrada" .debug/
```

Run `.debug/SagradaApp` from a terminal with Accessibility permission; use `.debug/sagrada` for commands. Do not run another instance at the same time.

On macOS 27 beta Command Line Tools, missing `SwiftUIMacros` or XCTest may require the full Xcode toolchain. See the [development notes](dev-docs/development.md) for toolchain selection and workarounds.

Dwindle-specific tests cover alternating splits, focus selection, weight preservation, floating/accordion behavior, close/reinsert, and opting out.

</details>

<details>
<summary><strong>Update or uninstall</strong></summary>

**Update:** quit Sagrada, download the latest [release](https://github.com/sebastianstoecklin/Sagrada/releases/latest) (or rebuild), and replace the app in Applications and reopen it. Keep the same signing certificate to reduce Accessibility permission resets. This fork does not receive upstream Homebrew updates automatically.

**Uninstall:** set `start-at-login = false`, choose **Reload config** from the menu, and quit. Move Sagrada from Applications to the Trash, then remove any remaining login item in System Settings. Keep or remove your config and helper state as desired.

</details>

<details>
<summary><strong>App icon and branding</strong></summary>

The Sagrada icon combines Sagrada Família-inspired stained glass, branching geometry, and nebula light with recursive window splits. The README and macOS app share the same [master artwork](docs/assets/branding/sagrada.png); the app asset catalog includes all standard macOS icon sizes.

See [branding notes](docs/assets/branding/README.md) for the image-generation prompt and regeneration instructions.

</details>

## Built on AeroSpace

This fork exists thanks to **[Nikita Bobko](https://github.com/nikitabobko) and the AeroSpace contributors**. The underlying window manager, workspace model, CLI, and documentation are their work. This fork focuses on Dwindle insertion and its own default experience; it is not affiliated with Apple.

- [Upstream project](https://github.com/nikitabobko/AeroSpace) · [User guide](https://nikitabobko.github.io/AeroSpace/guide) · [Configuration goodies](https://nikitabobko.github.io/AeroSpace/goodies)
- [91-second upstream demo](https://www.youtube.com/watch?v=UOl7ErqWbrk) · [Video guide by Josean Martinez](https://www.youtube.com/watch?v=-FoWClVHG5g) — these showcase upstream, not the fork-specific changes.
- [Contributing guidelines](CONTRIBUTING.md) · [Upstream discussions](https://github.com/nikitabobko/AeroSpace/discussions) — reproduce fork-specific problems on upstream before reporting them there.
- [Sponsor upstream development](https://github.com/sponsors/nikitabobko)

Sagrada is released under the [MIT License](LICENSE.txt). Original copyright and third-party notices are retained in [legal/](legal). The separately bundled [JankyBorders](https://github.com/FelixKratz/JankyBorders) helper is licensed under [GNU GPL v3](vendor/JankyBorders/LICENSE); its corresponding source and build script are included under `source/` in the release ZIP and in [vendor/JankyBorders/](vendor/JankyBorders/).

---

<div align="center">

**Keep your hands on the keyboard. Let your windows fall into place.**

</div>

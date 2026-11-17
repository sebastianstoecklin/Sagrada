<div align="center">

<img src="docs/assets/branding/sagrada.png" alt="Sagrada — stained-glass windows inspired by Sagrada Família" width="200" height="200">

# Sagrada

A keyboard-first tiling window manager for macOS that builds your layout around your focus.
New windows split the active tile instead of reshuffling your workspace, with integrated borders and compact workspace controls.
Built on [AeroSpace](https://github.com/nikitabobko/AeroSpace).

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111827?style=flat-square&logo=apple&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-8B5CF6?style=flat-square)](LICENSE.txt)

[Download](https://github.com/sebastianstoecklin/Sagrada/releases/latest) · [Configuration](#configuration) · [Keybindings](#keybindings) · [Development](dev-docs/development.md)

</div>

![Sagrada desktop with tiled windows, integrated borders, and workspace indicators](docs/assets/screenshots/sagrada-desktop.png)

## Features

- **Native dwindle:** new tiled windows split the most recently focused tile equally, alternating split directions. Existing outer split sizes and manually edited layouts stay intact; floating windows and accordion containers keep their behavior.
- **Workspace indicators:** Circled Numbers with a circle for active Floating, a lightly rounded rectangle for active Tiling, and bold numbers for occupied workspaces (macOS 14+).
- **Integrated borders:** bundled JankyBorders, configured in TOML and managed with the app (macOS 14+).
- **Screenshots:** Option–Shift–3/4/5 and a Screenshots menu keep macOS capture tools available without triggering the bundled Command-based workspace shortcuts.
- **Keep awake:** menu controls to prevent idle sleep or keep the display awake. Off by default; quitting releases the sleep assertions.
- **Reverse scrolling:** optional mouse-wheel reversal with independent axis controls and continuous gesture passthrough.
- **AeroSpace controls:** virtual workspaces, multiple displays, a scriptable CLI, and plain-text configuration without disabling SIP.

This is a personal fork, not an official AeroSpace release.

## Install

Requires **macOS 13+** on **Apple Silicon or Intel**. No Xcode is needed for the download.

1. Download and extract the ZIP from [GitHub Releases](https://github.com/sebastianstoecklin/Sagrada/releases/latest). Release notes and checksums are available there.
2. Quit any other tiling window manager.
3. Drag **Sagrada.app** into **Applications**, then open it.
4. Grant access in **System Settings → Privacy & Security → Accessibility**.

> [!NOTE]
> The app is not notarized by Apple. If macOS blocks it and you trust the download, try opening it, then choose **System Settings → Privacy & Security → Open Anyway**. Do not disable Gatekeeper.

**Update:** quit Sagrada, replace the app with the new download, and reopen it. Your configuration is not overwritten. This fork does not receive upstream Homebrew updates.

**Uninstall:** disable `start-at-login` in your config, reload, and quit. Move the app to the Trash and remove any remaining login item in System Settings. Keep or remove your configuration and helper state as desired.

## New in 0.5.6

- Compact Circled Numbers: bold occupied workspaces, light empty workspaces, with a 19-point circle (Floating) or rounded rectangle (Tiling) around the active workspace. Stroke width is 1.5 points.
- Left-click to select a workspace; click the active workspace to toggle Tiling / Floating. Right-click opens the native Sagrada dropdown. Interactive indicators require macOS 14.4+.
- **Workspaces → workspace → Tiling / Floating** controls each workspace independently, including inactive/empty workspaces. Choices persist; new workspaces default to Tiling.
- Workspaces 1–5 are persistent defaults and visible when empty. Explicit `persistent-workspaces` lists remain supported.
- Native CLI toggle: `sagrada layout --root floating tiling`. Replace the legacy helper callback/shortcut as described in the release notes.
- See [0.5.6 release notes](docs/release-notes/0.5.6.md).

## Local development build 0.5.5

- Compact-strip clicks now go through the native status button, not child views ignored by the macOS menu-bar host.
- Workspace selection uses screen mouse coordinates converted into the button’s actual image rectangle, accounting for padding/scaling. Left-click misses do nothing.
- No separate logo: right-click the workspace strip for the dropdown. New workspaces default to Tiling; saved layout choices are retained.
- See [0.5.5 release notes](docs/release-notes/0.5.5.md).

## Local development build 0.5.4

- Compact workspace buttons share one menu-bar host: 22-point cells with 3-point spacing, without system gaps between individual status items.
- A separate Sagrada app logo opens the dropdown with a normal click. Workspace right-clicks no longer open menus.
- No five-workspace default: only occupied, visible or focused workspaces appear. Empty persistent placeholders are hidden, even when explicitly configured.
- Each workspace remains a real button with its own target/action; no event-coordinate hit testing is reintroduced. Existing startup and multi-click protections remain.

See [0.5.4 release notes](docs/release-notes/0.5.4.md).

## Local development build 0.5.3

- Fix automatic termination after startup when replacing status-item host windows. Sagrada now explicitly stays running after the last window closes.
- Replace the crashing `NSHostingMenu` integration with a plain AppKit dropdown, retaining all workspace/config/helper actions.
- See [0.5.3 release notes](docs/release-notes/0.5.3.md) for the debugger-confirmed causes.

## Local development build 0.5.2

- Each workspace now has its own native status button. Target/action identifies the workspace without relying on coordinates forwarded from the system menu-bar host.
- Rapid/double clicks cannot overlap workspace operations or queue unexpected layout toggles. Click errors are handled without terminating the app.
- Right-click uses native status-item menu tracking/placement instead of manually positioning a popup. Left-clicking a workspace never falls through to the dropdown.

See [0.5.2 release notes](docs/release-notes/0.5.2.md).

## Local development build 0.5.1

- Left-click a workspace to select it; clicking the focused workspace toggles Tiling / Floating.
- Right-click any workspace (or Control-click) to open the full Sagrada dropdown. Interactive indicators require macOS 14.4+; older macOS versions retain the menu-only fallback.
- Workspaces 1–5 are now persistent by default for version-2 configs. An explicit `persistent-workspaces` list still overrides this default.
- Numbers are centered using their visible glyph bounds rather than the font’s ascender/descender box, with pixel-level tests for both font weights.

See [0.5.1 release notes](docs/release-notes/0.5.1.md).

## Local development build 0.5.0

- **Circled Numbers** workspace indicators follow the [refined design study](http://mini-server.local/designstudien/workspace-status/circled-numbers/): only the focused workspace has an outline; occupancy controls font weight. Nonexistent workspaces leave no gaps.
- **Workspaces → workspace → Tiling / Floating** switches all its managed windows, including on inactive and empty workspaces. Settings persist by workspace name across restarts; new windows inherit the mode. Native minimized/fullscreen/hidden windows are left alone until restored.
- `sagrada layout --root floating tiling` toggles the focused workspace, or use `--workspace NAME --root tiling|floating`. Normal Tiling still supports dialog windows and explicit per-window floating.
- The old helper is now a compatibility wrapper. Remove its `on-window-detected` callback and replace its toggle binding with `layout --root floating tiling`, or install the updated helper. Its old marker files are no longer used.

See [0.5.0 release notes](docs/release-notes/0.5.0.md). Ad-hoc signed builds may require renewed Accessibility approval.

## New in 0.4.5

- The dropdown header now shows **Sagrada + version**, with shorter menu and submenu entries.
- **Keep awake** offers Off, System, and System & display; **Reverse scrolling** offers independent axis controls.
- A desktop screenshot now showcases the tiled layout, borders, and workspace indicators above.

No configuration migration is required. See the [0.4.5 release notes](docs/release-notes/0.4.5.md). The app is ad-hoc signed; macOS may require renewed Accessibility approval after updating.

## Configuration

Use `~/.sagrada.toml` or `$XDG_CONFIG_HOME/sagrada/sagrada.toml`, then choose **Config → Reload** from the menu. See the [bundled config](docs/config-examples/default-config.toml) and [upstream guide](https://nikitabobko.github.io/AeroSpace/guide) for the full settings.

Top-level options belong before any `[table]` headers:

```toml
start-at-login = true
# Enabled by default; set false to restore upstream sibling insertion.
enable-dwindle = true
```

### Bundled setup

The bundled config is deliberately personal: Cmd-based navigation, app launch shortcuts, 10-point gaps, workspace 5 on the secondary display, and integrated borders. **Review it before copying**: shortcuts can override familiar macOS and app actions, and launchers require the corresponding apps.

From a source checkout:

```sh
if [ -f "$HOME/.sagrada.toml" ]; then
    cp "$HOME/.sagrada.toml" "$HOME/.sagrada.toml.backup-$(date +%Y%m%d-%H%M%S)"
fi
cp docs/config-examples/default-config.toml "$HOME/.sagrada.toml"
```

Workspace-wide floating is native; no helper or detection callback is required. Layout choices are stored in Sagrada’s user preferences, not the config file. Reload the configuration after changing shortcuts.

### Screenshots

While Sagrada runs, screenshot shortcuts move to **Option–Shift–3** (entire screen), **Option–Shift–4** (selection/window), and **Option–Shift–5** (screenshot and recording controls). The **Screenshots** menu offers the same actions without memorizing shortcuts. Captures use macOS's configured destination.

This frees Command–Shift–3/4/5 for moving windows without also taking screenshots. Sagrada temporarily disables the corresponding macOS screenshot hotkeys (including the clipboard variants) and restores their previous enabled states on normal quit; it does not edit your saved keyboard preferences. Touch Bar capture is unchanged. Option–Shift–3/4/5 will not type their usual special characters while Sagrada is running.

The temporary override uses a dynamically loaded private macOS API. If unavailable, the menu reports the failure and the original macOS shortcuts remain active. Force-quitting or a crash can skip cleanup; logging out and back in restores the saved system configuration.

### Borders

Configure `[borders]` in TOML; set `enabled = true` to enable. Options include `width` (0–100 whole points), `style` (`round`, `square`, `uniform`), `active-color`, `inactive-color`, `background-color` (`0xAARRGGBB`), `hidpi`, `ax-focus`, and comma-separated app `blacklist`/`whitelist` values. Reload applies changes; disabling borders or quitting stops the helper. Do not run another JankyBorders instance alongside it.

### Reverse scrolling

Disabled by default. Choose **Reverse scrolling → Enabled** in the menu to reverse classic mouse-wheel scrolling without changing macOS’s Natural Scrolling preference. Menu changes last until a config reload or app restart. To persist them:

```toml
[scroll-reverser]
enabled = true
reverse-vertical = true
reverse-horizontal = false
```

Continuous scrolling, gesture phases, and momentum from trackpads and Magic Mouse pass through. This filters discrete events, not physical devices: smooth-scrolling mouse drivers may also pass through. Do not run another scroll-reversal tool at the same time.

If the event tap cannot start, use **Retry** in the submenu. Check Accessibility and, if requested, Input Monitoring in System Settings, then retry or restart. Disabling the feature, turning off both axes, or quitting removes the filter.

## Keybindings

These are the main shortcuts in the [bundled config](docs/config-examples/default-config.toml); your configuration may differ. `⌘` = Cmd, `⌥` = Option, `⇧` = Shift, `⌃` = Control.

| Shortcut | Action |
| :--- | :--- |
| `⌘` + arrow | Focus a window |
| `⌘ ⇧` + arrow | Swap with a neighboring tile, preserving splits and sizes |
| `⌘` + `1`–`9` | Switch workspace |
| `⌘ ⇧` + `1`–`9` | Move a window to a workspace and follow it |
| `⌥ Tab` | Return to the previous workspace |
| `⌥ ⇧ Tab` | Move the workspace to the next monitor |
| `⌘ ⌥ -` / `⌘ ⇧ =` | Shrink / grow a tile |
| `⌘ ⇧ -` | Select tiles layout; cycle orientation |
| `⌘ ⇧ ,` | Select accordion layout; cycle orientation |
| `⌘ ⌥ F` | Toggle floating for the focused window |
| `⌘ ⌥ ⇧ F` | Toggle native Tiling / Floating for the workspace |
| `⌘ ⌃ ←` / `⌘ ⌃ →` | Join with the nearest node on that side |
| `⌘ ⇧ ;` | Enter service mode |

In service mode, `Esc` reloads config, `R` flattens the tree, `F` toggles floating, and `Backspace` closes all other windows. These return to main mode. See the config for launchers, join commands, and volume controls. `⌘ Backspace` is deliberately unbound to preserve Finder’s Move to Trash shortcut.

Swapping preserves the layout; AeroSpace’s `move` command instead edits the tree. Existing configs can adopt this behavior by changing `cmd-shift-<arrow>` bindings from `move <direction>` to `swap <direction>` and adding `--focus-follows-window` to numbered `move-node-to-workspace` bindings.

## Build from source

Install full Xcode, accept its license, and follow the [build prerequisites](dev-docs/development.md#1-install-dependencies), including docs and shell-completion dependencies. The Swift toolchain is specified in [`.swift-version`](.swift-version).

```sh
git clone https://github.com/sebastianstoecklin/Sagrada.git
cd Sagrada
./build-release.sh --codesign-identity -
open .release
```

Copy **Sagrada.app** to Applications. This produces an ad-hoc signed local build; no Apple Developer membership is required.

For development and testing, see [development notes](dev-docs/development.md), [architecture](dev-docs/architecture.md), and [contributing](CONTRIBUTING.md). Artwork regeneration is documented in the [branding notes](docs/assets/branding/README.md).

## Credits and license

Thanks to **[Nikita Bobko](https://github.com/nikitabobko) and the AeroSpace contributors** for the underlying window manager, workspace model, CLI, and documentation.

- [Upstream guide](https://nikitabobko.github.io/AeroSpace/guide) · [Command reference](https://nikitabobko.github.io/AeroSpace/commands) · [Sponsor upstream](https://github.com/sponsors/nikitabobko)
- Report fork-specific problems [here](https://github.com/sebastianstoecklin/Sagrada/issues). Only report upstream after reproducing on an upstream build.

Sagrada is [MIT-licensed](LICENSE.txt); original notices are retained in [legal/](legal). The separately bundled [JankyBorders](https://github.com/FelixKratz/JankyBorders) helper is [GPLv3-licensed](vendor/JankyBorders/LICENSE). Its corresponding source and build script are included under `source/` in release ZIPs and in [vendor/JankyBorders/](vendor/JankyBorders/).

# Bundled shortcuts that overlap with macOS

Scope: active bindings in [`default-config.toml`](config-examples/default-config.toml), compared with standard macOS shortcuts and built-in apps. “Commands” here means keyboard shortcuts, not shell commands. This is a static review of the bundled config, not an audit of your personal macOS settings.

Sagrada registers global hotkeys. An overlap can replace an app action, or a system-reserved shortcut can prevent Sagrada from receiving it. Exact behavior depends on macOS version, keyboard layout, and enabled system shortcuts. No system preferences were changed for this review.

Notation: `cmd` = Command, `alt` = Option, `ctrl` = Control, `shift` = Shift.

## System-wide screenshot shortcuts (remapped while Sagrada runs)

| Binding | Sagrada command | macOS action and parallel behavior |
| --- | --- | --- |
| `cmd-shift-3` | `move-node-to-workspace --focus-follows-window 3` | Moves the window only when the temporary override succeeds. Entire-screen screenshot moves to **`alt-shift-3`**, also available in **Screenshots → Capture Entire Screen**. Without the override, both actions can run. |
| `cmd-shift-4` | `move-node-to-workspace --focus-follows-window 4` | Moves the window only when the temporary override succeeds. Selection/window screenshot moves to **`alt-shift-4`**, also available in **Screenshots → Capture Selection or Window…**. Without the override, both actions can run. |
| `cmd-shift-5` | `move-node-to-workspace --focus-follows-window 5` | Moves the window only when the temporary override succeeds. Screenshot/recording controls move to **`alt-shift-5`**, also available in **Screenshots → Screenshot and Recording Controls…**. Without the override, both actions can run. |
| `cmd-shift-6` | `move-node-to-workspace --focus-follows-window 6` | Moves the window to workspace 6; macOS also assigns this to Touch Bar capture on equipped Macs. **Parallel behavior not verified.** |

Sagrada temporarily disables the original screenshot hotkeys, including clipboard variants, and provides Option–Shift–3/4/5 globally in both binding modes. Normal quit restores the original enabled states; saved macOS preferences are not edited. The Screenshots menu reports override failures. Without the override, screenshot actions can run in parallel with workspace moves, as observed in this setup. Touch Bar capture is not remapped.

## Standard editing, navigation, and Help

These are app-level shortcuts, often available across many macOS apps rather than reserved by the OS.

| Binding | Sagrada command | Familiar macOS/app action displaced |
| --- | --- | --- |
| `cmd-left`, `cmd-right` | `focus left`, `focus right` | Move to the beginning/end of a line in text; back/forward in Finder and some browsers. |
| `cmd-up`, `cmd-down` | `focus up`, `focus down` | Move to the beginning/end of a document; in Finder, open the enclosing folder/open the selected item. |
| `cmd-shift-left`, `cmd-shift-right` | `swap left`, `swap right` | Extend text selection to the beginning/end of the line. |
| `cmd-shift-up`, `cmd-shift-down` | `swap up`, `swap down` | Extend text selection to the beginning/end of the document. |
| `cmd-shift-slash` | `layout tiles horizontal vertical` | Open Help (`cmd-?` on a US keyboard). Layout-dependent. |
| `cmd-alt-f` | `layout floating tiling` | Move focus to an app's search field, where supported, such as Safari. |
| `cmd-shift-minus` | `resize smart -50` | Decrease text size in apps that use `cmd-shift-minus` (often shown as `cmd-_`). App/layout-dependent. |
| `cmd-shift-equal` | `resize smart +50` | Increase text size in apps that use `cmd-+`, including TextEdit. App/layout-dependent. |

## Finder and other built-in apps

| Binding | Sagrada command | Standard app overlap |
| --- | --- | --- |
| `cmd-1`–`cmd-4` | `workspace 1`–`workspace 4` | Finder: icon, list, column, and gallery views. |
| `cmd-1`–`cmd-9` | `workspace 1`–`workspace 9` | Safari: numbered tab selection, with `cmd-9` selecting the last tab (depending on Safari settings). Other apps also use numbered view/tab shortcuts. |
| `cmd-shift-f` | `exec-and-forget open -a Finder` | Finder: open Recents. Other apps commonly use this for broader search. |
| `cmd-shift-c` | `exec-and-forget open -a "Visual Studio Code"` | Finder: open Computer; TextEdit: show Colors. |
| `cmd-shift-m` | `exec-and-forget open -a "Mail"` | Music: switch to/from MiniPlayer. |
| `cmd-shift-k` | `exec-and-forget open -a "Calendar"` | Finder: open Network. |
| `cmd-shift-w` | `exec-and-forget open -a "Microsoft Word"` | Safari: close the current window; other apps also use this to close a window or multiple documents. |
| `cmd-shift-b` | `exec-and-forget open /Applications/Zen.app` | Safari: show/hide the Favorites bar. |
| `cmd-shift-o` | `exec-and-forget open /Applications/Obsidian.app` | Finder: open Documents. |
| `cmd-shift-p` | `exec-and-forget open /Applications/Strongbox.app` | Page Setup in apps that provide it. |
| `cmd-enter` | `exec-and-forget open -na Ghostty` | Safari: open the address/search in a new tab from the Smart Search field. Context-dependent. |

## Service-mode-only overlaps

These bindings apply only after `cmd-shift-semicolon` enters service mode, not during normal main-mode use.

| Binding | Sagrada command | Standard action displaced while in service mode |
| --- | --- | --- |
| `esc` | `reload-config`, then `mode main` | Cancel/dismiss the current operation or dialog. |
| `r` | `flatten-workspace-tree`, then `mode main` | Type `r`. |
| `f` | `layout floating tiling`, then `mode main` | Type `f`. |
| `backspace` | `close-all-windows-but-current`, then `mode main` | Delete the preceding character. **Potentially destructive: closes other windows instead.** |
| `cmd-shift-h` | `join-with left`, then `mode main` | Finder: open the Home folder. |
| `cmd-shift-j` | `join-with down`, then `mode main` | Finder: open Downloads. |
| `cmd-shift-k` | `join-with up`, then `mode main` | Finder: open Network. |
| `cmd-shift-l` | `join-with right`, then `mode main` | Safari: show/hide the sidebar. |
| `down`, `up` | `volume down`, `volume up` | Move the caret, selection, or scroll position. |
| `shift-down` | `volume set 0`, then `mode main` | Extend selection downwards. |

## No clear default macOS collision identified

The following main-mode bindings have no broadly established default macOS conflict identified here; individual apps or customized system shortcuts may still overlap:

- `cmd-ctrl-left` / `cmd-ctrl-right`: `join-with left` / `join-with right`. These are **not** the standard `ctrl-left` / `ctrl-right` Space-switching shortcuts.
- `alt-tab`: `workspace-back-and-forth`. The standard macOS app switcher is **`cmd-tab`**, not `alt-tab`.
- `alt-shift-tab`: `move-workspace-to-monitor --wrap-around next`.
- `cmd-alt-shift-f`: workspace-wide floating helper.
- `cmd-shift-comma`: `layout accordion horizontal vertical`. Standard app Preferences/Settings uses **`cmd-comma`**, without Shift.
- `cmd-shift-semicolon`: `mode service`.
- `cmd-shift-1`, `cmd-shift-2`, `cmd-shift-7`–`cmd-shift-9`: move a window to the numbered workspace and follow it. App-specific overlaps remain possible.

`cmd-backspace` is deliberately **unbound**, preserving Finder's Move to Trash. The config also leaves `cmd-h` alone (`automatically-unhide-macos-hidden-apps = false`), and the commented Terminal launcher is not an additional active binding.

## Which shortcuts actually reach each app?

With Sagrada enabled in **main mode**, successfully registered Sagrada bindings are handled globally, not forwarded to the foreground app. This does **not** mean macOS cannot also act on the same key combination: screenshot actions have been reported to run in parallel with Sagrada in this setup. Launching an app with a binding does **not** send that shortcut to the launched app. This follows the global `HotKey` registration in [`HotkeyBinding.swift`](../Sources/AppBundle/config/HotkeyBinding.swift).

The following are representative standard shortcuts, not exhaustive app shortcut inventories. “Reaches app” means **not bound by the bundled Sagrada main mode**; macOS, other utilities, or app settings can still intercept them.

| Foreground app | Shortcuts that can still reach the app | Shortcuts intercepted by Sagrada instead |
| --- | --- | --- |
| Finder | `cmd-n` (new window), `cmd-shift-n` (new folder), `cmd-o` (open), `cmd-i` (Get Info), `cmd-f` (search), `cmd-backspace` (Move to Trash), `cmd-comma` (Settings) | `cmd-1`–`cmd-4` (views), Command-arrows (navigation), `cmd-shift-f` (Recents), `cmd-shift-c` (Computer), `cmd-shift-k` (Network), `cmd-shift-o` (Documents). |
| Safari | `cmd-t` (new tab), `cmd-w` (close tab), `cmd-l` (address field), `cmd-r` (reload), `cmd-f` (find), `cmd-shift-t` (reopen closed tab), `cmd-comma` (Settings) | `cmd-1`–`cmd-9` (tab selection), `cmd-alt-f` (search field), `cmd-shift-b` (Favorites bar), `cmd-shift-w` (close window), `cmd-enter` (open address/search in new tab), Command-arrow text/navigation actions. |
| TextEdit | `cmd-n` (new), `cmd-o` (open), `cmd-s` (save), `cmd-a` (select all), `cmd-c` / `cmd-x` / `cmd-v` (copy/cut/paste), `cmd-z` (undo), `cmd-f` (find), `cmd-b` / `cmd-i` / `cmd-u` (formatting) | Command-arrows and Command-Shift-arrows (caret movement/selection), `cmd-shift-c` (Colors), bound text-size shortcuts. |
| Mail | `cmd-n` (new message), `cmd-r` (reply), `cmd-shift-r` (reply all), `cmd-shift-d` (send), `cmd-f` (find) | Command-arrow and Command-Shift-arrow editing actions; all other main-mode bindings, including `cmd-shift-m`, which launches Mail rather than being delivered to it. |
| Music | `cmd-f` (search), `cmd-l` (current song), `space` (play/pause when applicable) | `cmd-shift-m` (MiniPlayer); all other main-mode bindings. |
| Calendar | `cmd-n` (new event), `cmd-t` (today), `cmd-f` (search), `cmd-comma` (Settings) | `cmd-1`–`cmd-4` (calendar views); `cmd-shift-k` launches Calendar rather than being delivered to it. |
| Terminal | `cmd-n` (new window), `cmd-t` (new tab), `cmd-w` (close), `cmd-k` (clear), `ctrl-c` (interrupt), `ctrl-d` (EOF), `ctrl-r` (shell history search, shell-dependent) | All main-mode bindings, including Command-arrows and `cmd-1`–`cmd-9`; these cannot be relied on for terminal navigation/window selection. |
| Visual Studio Code, Ghostty, Word, Zen, Obsidian, Strongbox | Any app shortcut not bound in the active Sagrada mode and not intercepted elsewhere; exact actions depend on the app/version/settings. | All main-mode bindings, including the launch shortcut for that app. Launch shortcuts do not become app-local shortcuts when the app is focused. |

Common unbound shortcuts such as `cmd-q`, `cmd-h`, `cmd-tab`, and `cmd-space` retain their normal app/system routing. `cmd-space` normally goes to Spotlight and `cmd-tab` to the macOS app switcher, **not** to the foreground app.

In **service mode**, only that mode's configurable bindings are registered (the separate Option–Shift screenshot hotkeys remain active): its `esc`, `r`, `f`, `backspace`, arrows, and join shortcuts are intercepted. Main-mode bindings are no longer registered, so they can resume normal app/system routing until main mode returns. For example, Finder can receive `cmd-shift-o` in service mode, but not `cmd-shift-h` or `cmd-shift-j`.

System handling is distinct from delivery to the foreground app: screenshots can execute alongside Sagrada's command, as reported for this setup. Other system shortcut interactions have not been verified. The app table describes expected routing from the source/config, not runtime-tested delivery.

## Recommended priority

1. Use `alt-shift-3`–`alt-shift-5` or the Screenshots menu while Sagrada runs. Check the menu for override errors if screenshots still fire alongside workspace moves. Touch Bar capture remains unchanged.
2. Reconsider Command-arrow and Command-Shift-arrow bindings if you rely on standard text navigation and selection.
3. Reconsider `cmd-1`–`cmd-9` and the application launchers if you rely on Finder/Safari shortcuts.
4. Use service mode deliberately: its unmodified Backspace closes other windows.

Changing Sagrada bindings is preferable to disabling familiar system shortcuts globally. Verify any replacement against **System Settings → Keyboard → Keyboard Shortcuts** and the menus of your frequently used apps.

import AppKit
import Common

/// Plain AppKit menu: no NSHostingMenu/AttributeGraph lifecycle to invalidate.
@MainActor
final class NativeTrayMenu: NSMenu {
    private var actions: [() -> Void] = []

    init(model: TrayMenuModel) {
        super.init(title: "Sagrada")
        autoenablesItems = false
        addItem(withTitle: "Sagrada \(aeroSpaceAppVersion)", action: nil, keyEquivalent: "").isEnabled = false
        addItem(.separator())
        if model.axPermissionStatus == .granted {
            add(model.isEnabled ? "Disable" : "Enable", to: self) {
                Self.session {
                    _ = await EnableCommand(args: EnableCmdArgs(rawArgs: [], targetState: .toggle)).run(.defaultEnv, .emptyStdin)
                }
            }
            if model.lastReloadConfigContainedWarnings {
                add("Config warnings…", to: self) { Self.reload(warningsAsErrors: true) }
            }
            let workspaces = submenu("Workspaces", enabled: model.isEnabled)
            for workspace in model.workspaces {
                let sub = NSMenu(title: workspace.name)
                sub.autoenablesItems = false
                let row = NSMenuItem(title: "\(workspace.name) — \(workspace.windowMode.title)\(workspace.suffix)", action: nil, keyEquivalent: "")
                row.state = workspace.isFocused ? .on : .off
                row.submenu = sub
                workspaces.addItem(row)
                add("Switch to Workspace", to: sub) {
                    Self.session { _ = Workspace.get(byName: workspace.name).focusWorkspace() }
                }
                sub.addItem(.separator())
                for mode in WorkspaceWindowMode.allCases {
                    add(mode.title, to: sub, checked: workspace.windowMode == mode) {
                        Self.session { try await Workspace.get(byName: workspace.name).setWindowMode(mode) }
                    }
                }
            }
            let configMenu = submenu("Config")
            add("Open…", to: configMenu) {
                let fallback = FileManager.default.homeDirectoryForCurrentUser.appending(path: configDotfileName)
                let url: URL
                switch findCustomConfigUrl() {
                    case .file(let existing): url = existing
                    case .noCustomConfigExists:
                        _ = try? FileManager.default.copyItem(at: defaultConfigUrl, to: fallback)
                        url = fallback
                    case .ambiguousConfigError: url = fallback
                }
                url.open(with: getTextEditorToOpenConfig())
            }
            add("Reload", to: configMenu) { Self.reload(warningsAsErrors: false) }
        } else {
            add("Grant Accessibility…", to: self) { model.axPermissionStatus = .waitingWithPrompt }
        }
        let screenshots = submenu("Screenshots")
        for capture in Screenshots.Capture.allCases {
            add("\(capture.rawValue)    \(capture.shortcut)", to: screenshots) {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    Screenshots.shared.capture(capture)
                }
            }
        }
        if let error = Screenshots.shared.errorMessage {
            screenshots.addItem(withTitle: error, action: nil, keyEquivalent: "").isEnabled = false
            add("Retry", to: screenshots) { Screenshots.shared.start() }
        }
        let awake = submenu("Keep awake")
        for mode in DesktopHelpers.CaffeinateMode.allCases {
            add(mode.rawValue, to: awake, checked: DesktopHelpers.shared.caffeinateMode == mode) {
                DesktopHelpers.shared.setCaffeinate(mode)
            }
        }
        if let error = DesktopHelpers.shared.errorMessage {
            awake.addItem(withTitle: error, action: nil, keyEquivalent: "").isEnabled = false
        }
        let scroll = submenu("Reverse scrolling")
        let reverser = ScrollReverser.shared
        for (title, key) in [("Enabled", \ScrollReverserConfig.enabled), ("Vertical", \.reverseVertical), ("Horizontal", \.reverseHorizontal)] {
            add(title, to: scroll, checked: reverser.settings[keyPath: key]) {
                var settings = reverser.settings
                settings[keyPath: key].toggle()
                reverser.apply(settings)
            }
        }
        scroll.addItem(.separator())
        scroll.addItem(withTitle: "Mouse wheels only", action: nil, keyEquivalent: "").isEnabled = false
        if let error = reverser.errorMessage {
            scroll.addItem(withTitle: error, action: nil, keyEquivalent: "").isEnabled = false
            add("Retry", to: scroll) { reverser.requestPermissionsAndRetry() }
            add("Permissions…", to: scroll) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        addItem(.separator())
        add("Quit", to: self) {
            terminationHandler?.beforeTermination()
            terminateApp()
        }
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func submenu(_ title: String, enabled: Bool = true) -> NSMenu {
        let menu = NSMenu(title: title)
        menu.autoenablesItems = false
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        item.isEnabled = enabled
        addItem(item)
        return menu
    }

    private func add(_ title: String, to menu: NSMenu, checked: Bool = false, action: @escaping () -> Void) {
        let item = NSMenuItem(title: title, action: #selector(invoke(_:)), keyEquivalent: "")
        item.target = self
        item.tag = actions.count
        item.state = checked ? .on : .off
        actions.append(action)
        menu.addItem(item)
    }

    @objc private func invoke(_ sender: NSMenuItem) {
        guard actions.indices.contains(sender.tag) else { return }
        actions[sender.tag]()
    }

    private static func session(_ action: @escaping @MainActor () async throws -> Void) {
        Task { @MainActor in
            do { try await runLightSession(.menuBarButton, .forceRun, body: action) }
            catch is CancellationError { }
            catch { NSLog("Sagrada menu action failed: %@", String(describing: error)) }
        }
    }

    private static func reload(warningsAsErrors: Bool) {
        session {
            let args = ReloadConfigCmdArgs(rawArgs: []).copy(\.warningsAsErrors, warningsAsErrors)
            _ = await reloadConfig_nonCancellable(args: args)
        }
    }
}

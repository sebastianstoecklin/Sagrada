import Common
import Foundation
import SwiftUI

@MainActor
struct TrayMenuContent: View {
    @ObservedObject var viewModel: TrayMenuModel

    var body: some View {
        Text("Sagrada \(aeroSpaceAppVersion)")
        Divider()

        if viewModel.axPermissionStatus == .granted {
            if let token: RunSessionGuard = .isServerEnabled, viewModel.lastReloadConfigContainedWarnings {
                Button {
                    Task.startUnstructured {
                        try await runLightSession(.menuBarButton, token) {
                            let args: ReloadConfigCmdArgs = ReloadConfigCmdArgs(rawArgs: []).copy(\.warningsAsErrors, true)
                            _ = await reloadConfig_nonCancellable(args: args)
                        }
                    }
                } label: {
                    Label("Config warnings…", systemImage: "exclamationmark.triangle.fill")
                }
                Divider()
            }
            Button(viewModel.isEnabled ? "Disable" : "Enable") {
                Task.startUnstructured {
                    try await runLightSession(.menuBarButton, .forceRun) {
                        _ = await EnableCommand(args: EnableCmdArgs(rawArgs: [], targetState: .toggle))
                            .run(.defaultEnv, .emptyStdin)
                    }
                }
            }.keyboardShortcut("E", modifiers: .command)
            Menu("Workspaces") {
                ForEach(viewModel.workspaces, id: \.name) { workspace in
                    Menu("\(workspace.name)\(workspace.isFocused ? " ✓" : "") — \(workspace.windowMode.title)\(workspace.suffix)") {
                        Button("Switch to Workspace") {
                            guard let token: RunSessionGuard = .isServerEnabled else { return }
                            Task.startUnstructured {
                                try await runLightSession(.menuBarButton, token) {
                                    _ = Workspace.get(byName: workspace.name).focusWorkspace()
                                }
                            }
                        }
                        Divider()
                        ForEach(WorkspaceWindowMode.allCases, id: \.self) { mode in
                            Toggle(mode.title, isOn: Binding(
                                get: { workspace.windowMode == mode },
                                set: { selected in
                                    guard selected, let token: RunSessionGuard = .isServerEnabled else { return }
                                    Task.startUnstructured {
                                        try await runLightSession(.menuBarButton, token) {
                                            try await Workspace.get(byName: workspace.name).setWindowMode(mode)
                                        }
                                    }
                                },
                            ))
                        }
                    }
                }
            }.disabled(!viewModel.isEnabled)
            Menu("Config") {
                openConfigButton()
                reloadConfigButton(warningsAsErrors: false)
            }
        } else {
            Button("Grant Accessibility…") {
                viewModel.axPermissionStatus = .waitingWithPrompt
            }
        }
        ScreenshotsMenu()
        CaffeinateMenu()
        ScrollReverserMenu()
        Divider()
        Button("Quit") {
            Task.startUnstructured {
                terminationHandler?.beforeTermination()
                terminateApp()
            }
        }.keyboardShortcut("Q", modifiers: .command)
    }
}

@MainActor
public func menuBar(viewModel: TrayMenuModel) -> some Scene {
    MenuBarExtra(isInserted: .constant(!interactiveWorkspaceIndicatorsAvailable)) {
        TrayMenuContent(viewModel: viewModel)
    } label: {
        switch (viewModel.axPermissionStatus, viewModel.isEnabled) {
            case (.granted, true):
                MenuBarLabel().environmentObject(viewModel)
            case (.granted, false):
                Image(systemName: "pause.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case (_, _):
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
        }
    }
}

@MainActor @ViewBuilder
func openConfigButton(showShortcutGroup: Bool = false) -> some View {
    let editor = getTextEditorToOpenConfig()
    let button = Button("Open…") {
        let fallbackConfig: URL = FileManager.default.homeDirectoryForCurrentUser.appending(path: configDotfileName)
        switch findCustomConfigUrl() {
            case .file(let url):
                url.open(with: editor)
            case .noCustomConfigExists:
                _ = try? FileManager.default.copyItem(atPath: defaultConfigUrl.path, toPath: fallbackConfig.path)
                fallbackConfig.open(with: editor)
            case .ambiguousConfigError:
                fallbackConfig.open(with: editor)
        }
    }.keyboardShortcut(",", modifiers: .command)
    switch showShortcutGroup {
        case true: shortcutGroup(label: Text("⌘ ,"), content: button)
        case false: button
    }
}

@MainActor @ViewBuilder
func reloadConfigButton(showShortcutGroup: Bool = false, warningsAsErrors: Bool) -> some View {
    if let token: RunSessionGuard = .isServerEnabled {
        let button = Button("Reload") {
            Task.startUnstructured {
                try await runLightSession(.menuBarButton, token) {
                    let args: ReloadConfigCmdArgs = ReloadConfigCmdArgs(rawArgs: []).copy(\.warningsAsErrors, warningsAsErrors)
                    _ = await reloadConfig_nonCancellable(args: args)
                }
            }
        }.keyboardShortcut("R", modifiers: .command)
        switch showShortcutGroup {
            case true: shortcutGroup(label: Text("⌘ R"), content: button)
            case false: button
        }
    }
}

func shortcutGroup(label: some View, content: some View) -> some View {
    GroupBox {
        VStack(alignment: .trailing, spacing: 6) {
            label
                .foregroundStyle(Color.secondary)
            content
        }
    }
}

func getTextEditorToOpenConfig() -> URL {
    NSWorkspace.shared.urlForApplication(toOpen: findCustomConfigUrl().urlOrNil ?? defaultConfigUrl)?
        .takeIf { $0.lastPathComponent != "Xcode.app" } // Blacklist Xcode. It is too heavy to open plain text files
        ?? URL(filePath: "/System/Applications/TextEdit.app")
}

import AppKit
import Common

/// Workspace policy, independent of the tiling tree's orientation/layout.
enum WorkspaceWindowMode: String, CaseIterable, Hashable {
    case tiling
    case floating

    var title: String { rawValue.capitalized }
}

extension Workspace {
    @MainActor
    func setWindowMode(_ mode: WorkspaceWindowMode) async throws {
        windowMode = mode
        if !isUnitTest {
            var modes = UserDefaults.standard.dictionary(forKey: "workspaceWindowModes") as? [String: String] ?? [:]
            modes[name] = mode.rawValue
            UserDefaults.standard.set(modes, forKey: "workspaceWindowModes")
        }
        switch mode {
            case .floating:
                floatTiledWindows()
            case .tiling:
                for window in floatingWindowsContainer.allLeafWindowsRecursive {
                    window.lastFloatingSize = (try? await window.getAxSize(.nonCancellable)) ?? window.lastFloatingSize
                    try await window.relayoutWindow(on: self, .nonCancellable, forceTile: true)
                }
        }
    }

    /// Also covers windows moved here, restored from native states, or tiled by callbacks.
    @MainActor
    func floatTiledWindows() {
        guard windowMode == .floating else { return }
        for window in rootTilingContainer.allLeafWindowsRecursive {
            window.isFullscreen = false
            window.bindAsFloatingWindow(to: self)
            if let size = window.lastFloatingSize { window.setAxFrame(nil, size) }
        }
    }
}

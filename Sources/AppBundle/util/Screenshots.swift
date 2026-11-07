import AppKit
import Common
import HotKey
import PrivateApi
import SwiftUI

@MainActor
final class Screenshots: ObservableObject {
    static let shared = Screenshots()

    enum Capture: String, CaseIterable, Identifiable {
        case screen = "Entire screen"
        case selection = "Selection / window…"
        case controls = "Capture / record…"
        var id: Self { self }

        var key: Key {
            switch self {
                case .screen: .three
                case .selection: .four
                case .controls: .five
            }
        }

        var shortcut: String {
            switch self {
                case .screen: "⌥⇧3"
                case .selection: "⌥⇧4"
                case .controls: "⌥⇧5"
            }
        }

        var arguments: [String] {
            switch self {
                case .screen: ["-p", "-u"]
                case .selection: ["-i", "-p", "-u"]
                case .controls: ["-i", "-U", "-p"]
            }
        }
    }

    @Published private(set) var errorMessage: String?
    private var hotkeys: [HotKey] = []
    private var captureProcess: Process?

    func start() {
        guard !isUnitTest, hotkeys.isEmpty else { return }
        guard sagradaSuspendScreenshotHotkeys() else {
            errorMessage = "Could not remap macOS screenshot shortcuts. Original shortcuts remain active."
            return
        }
        hotkeys = Capture.allCases.map { capture in
            HotKey(key: capture.key, modifiers: [.option, .shift], keyDownHandler: {
                Screenshots.shared.capture(capture)
            })
        }
        errorMessage = nil
    }

    func capture(_ capture: Capture) {
        guard captureProcess?.isRunning != true else { return }
        let process = Process()
        process.executableURL = URL(filePath: "/usr/sbin/screencapture")
        process.arguments = capture.arguments
        do {
            try process.run()
            captureProcess = process
            errorMessage = nil
        } catch {
            errorMessage = "Screenshot: \(error.localizedDescription)"
        }
    }

    func shutdown() {
        for hotkey in hotkeys { hotkey.isPaused = true }
        hotkeys = []
        sagradaRestoreScreenshotHotkeys()
    }
}

struct ScreenshotsMenu: View {
    @ObservedObject private var screenshots = Screenshots.shared

    var body: some View {
        Menu("Screenshots") {
            ForEach(Screenshots.Capture.allCases) { capture in
                Button("\(capture.rawValue)    \(capture.shortcut)") {
                    // Let the status menu close before capturing the screen.
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(250))
                        screenshots.capture(capture)
                    }
                }
            }
            if let error = screenshots.errorMessage {
                Divider()
                Text(error)
                Button("Retry") { screenshots.start() }
            }
        }
    }
}

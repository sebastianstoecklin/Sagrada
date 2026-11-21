import AppKit
import Common
import HotKey
import SwiftUI

@MainActor
final class Screenshots: ObservableObject {
    static let shared = Screenshots()

    enum Capture: String, CaseIterable, Identifiable {
        case screen = "Entire screen"
        case selection = "Selection / window…"
        case controls = "Capture / record…"
        var id: Self { self }

        var symbolicHotkeyID: String {
            switch self {
                case .screen: "28"
                case .selection: "30"
                case .controls: "184"
            }
        }

        var defaultKeyCode: CGKeyCode {
            switch self {
                case .screen: 20 // ANSI 3
                case .selection: 21 // ANSI 4
                case .controls: 23 // ANSI 5
            }
        }

        func shortcut(in settings: [String: Any]) -> Shortcut? {
            guard let value = settings[symbolicHotkeyID] else {
                return Shortcut(keyCode: defaultKeyCode, flags: [.maskCommand, .maskShift])
            }
            guard let entry = value as? [String: Any], entry["enabled"] as? Bool == true,
                  let definition = entry["value"] as? [String: Any], definition["type"] as? String == "standard",
                  let parameters = definition["parameters"] as? [Int], parameters.count == 3,
                  let keyCode = CGKeyCode(exactly: parameters[1]), keyCode < 128,
                  let modifiers = UInt64(exactly: parameters[2]) else { return nil }
            return Shortcut(keyCode: keyCode, flags: CGEventFlags(rawValue: modifiers))
        }
    }

    struct Shortcut: Equatable {
        let keyCode: CGKeyCode
        let flags: CGEventFlags
    }

    @Published private(set) var errorMessage: String?
    private var aliases: [CGKeyCode: HotKey] = [:]
    private static let aliasFlags: CGEventFlags = [.maskAlternate, .maskShift]

    private func systemSettings() -> [String: Any] {
        let domain = "com.apple.symbolichotkeys" as CFString
        _ = CFPreferencesAppSynchronize(domain)
        return CFPreferencesCopyAppValue("AppleSymbolicHotKeys" as CFString, domain) as? [String: Any] ?? [:]
    }

    func start() {
        guard !isUnitTest, aliases.isEmpty else { return }
        let settings = systemSettings()
        let native = Capture.allCases.compactMap { $0.shortcut(in: settings) }
        for (key, capture) in zip([Key.three, .four, .five], Capture.allCases) {
            let code = capture.defaultKeyCode
            guard !native.contains(Shortcut(keyCode: code, flags: Self.aliasFlags)) else { continue }
            aliases[code] = HotKey(key: key, modifiers: [.option, .shift], keyDownHandler: {
                Screenshots.shared.capture(capture)
            })
        }
    }

    func shutdown() {
        for hotkey in aliases.values { hotkey.isPaused = true }
        aliases.removeAll()
    }

    func capture(_ capture: Capture) {
        guard let shortcut = capture.shortcut(in: systemSettings()) else {
            errorMessage = "Enable this shortcut in System Settings → Keyboard → Keyboard Shortcuts → Screenshots."
            return
        }
        guard CGPreflightPostEventAccess() else {
            errorMessage = "Allow Sagrada in System Settings → Privacy & Security → Accessibility to trigger shortcuts from the menu."
            return
        }
        guard let source = CGEventSource(stateID: .hidSystemState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: false) else {
            errorMessage = "Could not trigger the macOS screenshot shortcut."
            return
        }
        // If macOS was configured to use an alias after app startup, don't
        // intercept the synthetic event and trigger this handler recursively.
        if shortcut.flags == Self.aliasFlags {
            aliases.removeValue(forKey: shortcut.keyCode)?.isPaused = true
        }
        down.flags = shortcut.flags
        up.flags = shortcut.flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        errorMessage = nil
    }

    func captureAfterMenuCloses(_ capture: Capture) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            self.capture(capture)
        }
    }
}

struct ScreenshotsMenu: View {
    @ObservedObject private var screenshots = Screenshots.shared

    var body: some View {
        Menu("Screenshots") {
            ForEach(Screenshots.Capture.allCases) { capture in
                Button(capture.rawValue) { screenshots.captureAfterMenuCloses(capture) }
            }
            if let error = screenshots.errorMessage {
                Divider()
                Text(error)
            }
        }
    }
}

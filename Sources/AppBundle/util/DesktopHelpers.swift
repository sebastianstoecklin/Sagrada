import Common
import Foundation
import SwiftUI

@MainActor
final class DesktopHelpers: ObservableObject {
    static let shared = DesktopHelpers()

    enum CaffeinateMode: String, CaseIterable, Identifiable {
        case off = "Aus"
        case awake = "Wach halten"
        case screen = "Bildschirm wach halten"
        var id: Self { self }

        var arguments: [String]? {
            switch self {
                case .off: nil
                case .awake: ["-i"] // caffeinate's default assertion
                case .screen: ["-i", "-d"]
            }
        }
    }

    @Published private(set) var caffeinateMode: CaffeinateMode = .off
    @Published private(set) var errorMessage: String?
    private var caffeinate: Process?
    private var borders: Process?
    private var appliedBorders: BordersConfig?

    func setCaffeinate(_ mode: CaffeinateMode) {
        stop(caffeinate)
        caffeinate = nil
        caffeinateMode = .off
        guard let arguments = mode.arguments else { return }
        do {
            caffeinate = try launch(URL(filePath: "/usr/bin/caffeinate"), arguments + ["-w", String(ProcessInfo.processInfo.processIdentifier)])
            caffeinateMode = mode
            errorMessage = nil
        } catch {
            errorMessage = "Caffeinate: \(error.localizedDescription)"
        }
    }

    func syncBorders(_ settings: BordersConfig) {
        guard !isUnitTest else { return }
        if appliedBorders == settings && (borders?.isRunning == true || !settings.enabled) { return }
        stop(borders)
        borders = nil
        appliedBorders = nil
        guard settings.enabled else { appliedBorders = settings; return }
        guard #available(macOS 14, *) else {
            errorMessage = "JankyBorders benötigt macOS 14 oder neuer."
            return
        }
        guard let executable = Bundle.main.url(forResource: "sagrada-borders", withExtension: nil) else {
            errorMessage = "JankyBorders-Helper fehlt. Bitte den App-Bundle-Build verwenden."
            return
        }
        do {
            borders = try launch(executable, settings.arguments)
            appliedBorders = settings
            errorMessage = nil
        } catch {
            errorMessage = "JankyBorders: \(error.localizedDescription)"
        }
    }

    func shutdown() {
        stop(caffeinate)
        stop(borders)
        caffeinate = nil
        borders = nil
        caffeinateMode = .off
    }

    private func launch(_ executable: URL, _ arguments: [String]) throws -> Process {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        try process.run()
        return process
    }

    private func stop(_ process: Process?) {
        guard let process, process.isRunning else { return }
        process.terminate()
        process.waitUntilExit()
    }
}

struct CaffeinateMenu: View {
    @ObservedObject private var helpers = DesktopHelpers.shared

    var body: some View {
        Menu("Caffeinate") {
            ForEach(DesktopHelpers.CaffeinateMode.allCases) { mode in
                Button {
                    helpers.setCaffeinate(mode)
                } label: {
                    if helpers.caffeinateMode == mode {
                        Label(mode.rawValue, systemImage: "checkmark")
                    } else {
                        Text(mode.rawValue)
                    }
                }
            }
        }
        if let error = helpers.errorMessage {
            Text(error)
        }
    }
}

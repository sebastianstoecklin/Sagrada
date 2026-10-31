import Common
import Foundation

let configDotfileName = ".sagrada.toml"
func findCustomConfigUrl() -> ConfigFile {
    let xdgConfigHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"].map { URL(filePath: $0) }
        ?? FileManager.default.homeDirectoryForCurrentUser.appending(path: ".config/")
    let candidates: [URL] = switch serverArgs.configLocation {
        case let configLocation?: [URL(filePath: configLocation)]
        case nil:
            [
                FileManager.default.homeDirectoryForCurrentUser.appending(path: configDotfileName),
                xdgConfigHome.appending(path: "sagrada").appending(path: "sagrada.toml"),
            ]
    }
    var existingCandidates: [URL] = candidates.filter { (candidate: URL) in FileManager.default.fileExists(atPath: candidate.path) }
    if existingCandidates.isEmpty && serverArgs.configLocation == nil {
        let legacy = [
            FileManager.default.homeDirectoryForCurrentUser.appending(path: ".sagradaspace.toml"),
            xdgConfigHome.appending(path: "sagradaspace/sagradaspace.toml"),
            FileManager.default.homeDirectoryForCurrentUser.appending(path: ".aerospace.toml"),
            xdgConfigHome.appending(path: "aerospace/aerospace.toml"),
        ]
        existingCandidates = legacy.filter { FileManager.default.fileExists(atPath: $0.path) }
    }
    let count = existingCandidates.count
    return switch count {
        case 0: .noCustomConfigExists
        case 1: .file(existingCandidates.first.orDie())
        default: .ambiguousConfigError(existingCandidates)
    }
}

enum ConfigFile {
    case file(URL), ambiguousConfigError(_ candidates: [URL]), noCustomConfigExists

    var urlOrNil: URL? {
        return switch self {
            case .file(let url): url
            case .ambiguousConfigError, .noCustomConfigExists: nil
        }
    }
}

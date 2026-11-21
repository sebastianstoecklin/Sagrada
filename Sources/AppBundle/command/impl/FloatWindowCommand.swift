import AppKit
import Common

struct FloatWindowCommand: Command {
    let args: FloatWindowCmdArgs
    let shouldResetClosedWindowsCache = true

    @MainActor
    func run(_ env: CmdEnv, _ io: CmdIo) async -> BinaryExitCode {
        guard focus.workspace.windowMode == .floating,
              let window = focus.windowOrNil, window.isFloating,
              let current = try? await window.getAxRect(.cancellable) else {
            return .fail(io.err("float-window requires a focused window in a Floating workspace"))
        }
        let bounds = focus.workspace.workspaceMonitor.visibleRectPaddedByOuterGaps
        let frame = floatingWindowFrame(args.action.val, current: current, bounds: bounds)
        window.isFullscreen = false
        window.lastFloatingSize = CGSize(width: frame.width, height: frame.height)
        window.setAxFrame(frame.topLeftCorner, window.lastFloatingSize)
        return .succ
    }
}

func floatingWindowFrame(_ action: FloatWindowAction, current: Rect, bounds: Rect) -> Rect {
    var x: CGFloat = 0, y: CGFloat = 0, w: CGFloat = 1, h: CGFloat = 1
    switch action {
        case .topLeft: w = 0.5; h = 0.5
        case .topRight: x = 0.5; w = 0.5; h = 0.5
        case .bottomLeft: y = 0.5; w = 0.5; h = 0.5
        case .bottomRight: x = 0.5; y = 0.5; w = 0.5; h = 0.5
        case .left: w = 0.5
        case .right: x = 0.5; w = 0.5
        case .top: h = 0.5
        case .bottom: y = 0.5; h = 0.5
        case .thirdLeft: w = 1 / 3
        case .thirdCenter: x = 1 / 3; w = 1 / 3
        case .thirdRight: x = 2 / 3; w = 1 / 3
        case .maximize: break
        case .center, .grow, .shrink:
            let delta: CGFloat = action == .grow ? 40 : action == .shrink ? -40 : 0
            let width = min(bounds.width, max(100, current.width + delta))
            let height = min(bounds.height, max(100, current.height + delta))
            return Rect(topLeftX: bounds.topLeftX + (bounds.width - width) / 2, topLeftY: bounds.topLeftY + (bounds.height - height) / 2, width: width, height: height)
    }
    return Rect(topLeftX: bounds.topLeftX + bounds.width * x, topLeftY: bounds.topLeftY + bounds.height * y, width: bounds.width * w, height: bounds.height * h)
}

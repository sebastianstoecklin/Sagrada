public enum FloatWindowAction: String, CaseIterable, Sendable {
    case topLeft = "top-left", topRight = "top-right"
    case bottomLeft = "bottom-left", bottomRight = "bottom-right"
    case left, right, top, bottom
    case thirdLeft = "third-left", thirdCenter = "third-center", thirdRight = "third-right"
    case maximize, center, grow, shrink
}

public struct FloatWindowCmdArgs: CmdArgs {
    public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { commonState = .init(rawArgs) }
    public var action: Lateinit<FloatWindowAction> = .uninitialized
    public static let parser: CmdParser<Self> = .init(
        kind: .floatWindow,
        help: "Usage: sagrada float-window <action>\nArrange the focused window in a Floating workspace. Actions: top-left, top-right, bottom-left, bottom-right, left, right, top, bottom, third-left, third-center, third-right, maximize, center, grow, shrink.",
        flags: [:],
        posArgs: [newMandatoryPosArgParser(\.action, { i in
            .init(parseEnum(i.arg, FloatWindowAction.self), advanceBy: 1)
        }, placeholder: "<action>")]
    )
}

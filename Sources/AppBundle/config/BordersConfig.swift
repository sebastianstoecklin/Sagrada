import Common

struct BordersConfig: ConvenienceMutable, Equatable {
    var enabled = false
    var width = 5
    var style = "round"
    var activeColor = "0xffe2e2e3"
    var inactiveColor = "0xff414550"
    var backgroundColor = "0x00000000"
    var hidpi = true
    var axFocus = false
    var blacklist = ""
    var whitelist = ""

    var arguments: [String] {
        ["width=\(width)", "style=\(style)", "active_color=\(activeColor)",
         "inactive_color=\(inactiveColor)", "background_color=\(backgroundColor)",
         "hidpi=\(hidpi ? "on" : "off")", "ax_focus=\(axFocus ? "on" : "off")",
         "blacklist=\(blacklist)", "whitelist=\(whitelist)"]
    }
}

private let bordersParser: [String: any ParserProtocol<BordersConfig>] = [
    "enabled": Parser(\.enabled, parseBool),
    "width": Parser(\.width, { raw, trace in
        parseInt(raw, trace).flatMap {
            $0 >= 0 && $0 <= 100 ? .success($0) : .failure(.init(trace, "width must be in [0, 100] points"))
        }
    }),
    "style": Parser(\.style, { raw, trace in
        parseString(raw, trace).flatMap {
            ["round", "square", "uniform"].contains($0) ? .success($0) : .failure(.init(trace, "Expected round, square or uniform"))
        }
    }),
    "active-color": Parser(\.activeColor, parseBorderColor),
    "inactive-color": Parser(\.inactiveColor, parseBorderColor),
    "background-color": Parser(\.backgroundColor, parseBorderColor),
    "hidpi": Parser(\.hidpi, parseBool),
    "ax-focus": Parser(\.axFocus, parseBool),
    "blacklist": Parser(\.blacklist, parseString),
    "whitelist": Parser(\.whitelist, parseString),
]

private func parseBorderColor(_ raw: OrderedJson, _ trace: ConfigBacktrace) -> ResOrConfigParseDiagnostic<String> {
    parseString(raw, trace).flatMap { value in
        let digits = value.dropFirst(2)
        return value.hasPrefix("0x") && digits.count == 8 && digits.allSatisfy(\.isHexDigit)
            ? .success(value) : .failure(.init(trace, "Expected color in 0xAARRGGBB format"))
    }
}

func parseBorders(_ raw: OrderedJson, _ trace: ConfigBacktrace, _ context: inout ConfigParserContext) -> BordersConfig {
    parseTable(raw, BordersConfig(), bordersParser, trace, &context)
}

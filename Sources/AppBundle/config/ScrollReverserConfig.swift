import Common

struct ScrollReverserConfig: ConvenienceMutable, Equatable {
    var enabled = false
    var reverseVertical = true
    var reverseHorizontal = false
}

private let scrollReverserParser: [String: any ParserProtocol<ScrollReverserConfig>] = [
    "enabled": Parser(\.enabled, parseBool),
    "reverse-vertical": Parser(\.reverseVertical, parseBool),
    "reverse-horizontal": Parser(\.reverseHorizontal, parseBool),
]

func parseScrollReverser(_ raw: OrderedJson, _ trace: ConfigBacktrace, _ context: inout ConfigParserContext) -> ScrollReverserConfig {
    parseTable(raw, ScrollReverserConfig(), scrollReverserParser, trace, &context)
}

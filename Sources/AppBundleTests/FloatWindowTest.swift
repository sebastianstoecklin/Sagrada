@testable import AppBundle
import Common
import XCTest

final class FloatWindowTest: XCTestCase {
    let bounds = Rect(topLeftX: -1200, topLeftY: 40, width: 1200, height: 800)
    let current = Rect(topLeftX: -1000, topLeftY: 100, width: 600, height: 400)

    func testQuadrantsAndThirds() {
        let cases: [(FloatWindowAction, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (.topLeft, -1200, 40, 600, 400), (.topRight, -600, 40, 600, 400),
            (.bottomLeft, -1200, 440, 600, 400), (.bottomRight, -600, 440, 600, 400),
            (.thirdLeft, -1200, 40, 400, 800), (.thirdCenter, -800, 40, 400, 800),
            (.thirdRight, -400, 40, 400, 800), (.left, -1200, 40, 600, 800),
            (.right, -600, 40, 600, 800), (.top, -1200, 40, 1200, 400),
            (.bottom, -1200, 440, 1200, 400), (.maximize, -1200, 40, 1200, 800),
        ]
        for (action, x, y, w, h) in cases {
            let frame = floatingWindowFrame(action, current: current, bounds: bounds)
            XCTAssertEqual(frame.topLeftX, x, accuracy: 0.001)
            XCTAssertEqual(frame.topLeftY, y, accuracy: 0.001)
            XCTAssertEqual(frame.width, w, accuracy: 0.001)
            XCTAssertEqual(frame.height, h, accuracy: 0.001)
        }
    }

    func testCenterAndResizeBounds() {
        for action in [FloatWindowAction.center, .grow, .shrink] {
            let frame = floatingWindowFrame(action, current: current, bounds: bounds)
            XCTAssertEqual(frame.center, bounds.center)
        }
        XCTAssertEqual(floatingWindowFrame(.grow, current: bounds, bounds: bounds).width, bounds.width)
        let tiny = Rect(topLeftX: 0, topLeftY: 0, width: 100, height: 100)
        XCTAssertEqual(floatingWindowFrame(.shrink, current: tiny, bounds: bounds).width, 100)
        XCTAssertEqual(floatingWindowFrame(.grow, current: current, bounds: bounds).width, 640)
        XCTAssertEqual(floatingWindowFrame(.shrink, current: current, bounds: bounds).height, 360)
    }

    @MainActor func testBundledConfigAndActions() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let text = try String(contentsOf: root.appendingPathComponent("docs/config-examples/default-config.toml"), encoding: .utf8)
        XCTAssertTrue(parseConfig(text).errors.isEmpty, "\(parseConfig(text).errors)")
        for direction in ["left", "right", "up", "down"] {
            XCTAssertTrue(text.contains("cmd-alt-\(direction) = 'join-with \(direction)'"))
            XCTAssertTrue(text.contains("cmd-shift-\(direction) = 'swap \(direction)'"))
        }
        for action in FloatWindowAction.allCases {
            XCTAssertTrue(text.contains("float-window \(action.rawValue)"))
        }
    }
}

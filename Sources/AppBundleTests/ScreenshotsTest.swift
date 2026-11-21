@testable import AppBundle
import CoreGraphics
import XCTest

final class ScreenshotsTest: XCTestCase {
    @MainActor func testDefaultSystemShortcuts() {
        XCTAssertEqual(Screenshots.Capture.allCases.map(\.symbolicHotkeyID), ["28", "30", "184"])
        XCTAssertEqual(Screenshots.Capture.allCases.compactMap { $0.shortcut(in: [:])?.keyCode }, [20, 21, 23])
        XCTAssertEqual(Screenshots.Capture.screen.shortcut(in: [:])?.flags, [.maskCommand, .maskShift])
    }

    @MainActor func testCustomShortcut() {
        let settings: [String: Any] = ["28": [
            "enabled": true,
            "value": ["type": "standard", "parameters": [50, 19, 262144]],
        ]]
        XCTAssertEqual(Screenshots.Capture.screen.shortcut(in: settings), .init(keyCode: 19, flags: .maskControl))
    }

    @MainActor func testDisabledOrMalformedShortcutDoesNotFallBack() {
        XCTAssertNil(Screenshots.Capture.screen.shortcut(in: ["28": ["enabled": false]]))
        XCTAssertNil(Screenshots.Capture.controls.shortcut(in: ["184": ["enabled": true]]))
    }
}

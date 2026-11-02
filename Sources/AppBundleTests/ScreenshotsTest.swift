@testable import AppBundle
import XCTest

final class ScreenshotsTest: XCTestCase {
    @MainActor
    func testCaptureActionsUseStandardScreenshotDestinations() {
        XCTAssertEqual(Screenshots.Capture.screen.arguments, ["-p", "-u"])
        XCTAssertEqual(Screenshots.Capture.selection.arguments, ["-i", "-p", "-u"])
        XCTAssertEqual(Screenshots.Capture.controls.arguments, ["-i", "-U", "-p"])
    }

    @MainActor
    func testOnlyNonTouchBarActionsAreRemapped() {
        XCTAssertEqual(Screenshots.Capture.allCases.map(\.shortcut), ["⌥⇧3", "⌥⇧4", "⌥⇧5"])
        XCTAssertEqual(Screenshots.Capture.allCases.map(\.key), [.three, .four, .five])
    }

    @MainActor
    func testStartingInTestsDoesNotRemapSystemShortcuts() {
        Screenshots.shared.start()
        XCTAssertNil(Screenshots.shared.errorMessage)
        Screenshots.shared.shutdown()
    }
}

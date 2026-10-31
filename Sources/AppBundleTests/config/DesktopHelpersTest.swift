@testable import AppBundle
import XCTest

@MainActor
final class DesktopHelpersTest: XCTestCase {
    func testBordersConfiguration() {
        let result = parseConfig("""
        config-version = 2
        [borders]
        enabled = true
        width = 6
        style = 'square'
        active-color = '0xffabcdef'
        inactive-color = '0x00000000'
        background-color = '0x11000000'
        hidpi = false
        ax-focus = true
        blacklist = 'Finder,Preview'
        whitelist = ''
        """)
        XCTAssertTrue(result.errors.isEmpty)
        let borders = result.config.borders
        XCTAssertTrue(borders.enabled)
        XCTAssertEqual(borders.width, 6)
        XCTAssertTrue(borders.arguments.contains("active_color=0xffabcdef"))
        XCTAssertTrue(borders.arguments.contains("ax_focus=on"))
        XCTAssertTrue(borders.arguments.contains("hidpi=off"))
        XCTAssertTrue(borders.arguments.contains("blacklist=Finder,Preview"))
    }

    func testInvalidBordersSettings() {
        for setting in ["width = -1", "width = 101", "style = 'triangle'", "active-color = 'red'", "enabled = 'yes'", "unknown = true"] {
            let result = parseConfig("config-version = 2\n[borders]\n\(setting)")
            XCTAssertFalse(result.errors.isEmpty, setting)
        }
    }

    func testBordersAreOptInForExistingConfigs() {
        let result = parseConfig("config-version = 2")
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertFalse(result.config.borders.enabled)
    }

    func testCaffeinateModes() {
        XCTAssertNil(DesktopHelpers.CaffeinateMode.off.arguments)
        XCTAssertEqual(DesktopHelpers.CaffeinateMode.awake.arguments, ["-i"])
        XCTAssertEqual(DesktopHelpers.CaffeinateMode.screen.arguments, ["-i", "-d"])
    }
}

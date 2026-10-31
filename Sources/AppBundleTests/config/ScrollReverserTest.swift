@testable import AppBundle
import CoreGraphics
import XCTest

@MainActor
final class ScrollReverserTest: XCTestCase {
    private let vertical: [CGEventField] = [.scrollWheelEventDeltaAxis1, .scrollWheelEventPointDeltaAxis1]
    private let horizontal: [CGEventField] = [.scrollWheelEventDeltaAxis2, .scrollWheelEventPointDeltaAxis2]

    private func event() -> CGEvent {
        let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: 3, wheel2: -4, wheel3: 0)!
        for field in vertical { event.setIntegerValueField(field, value: 3) }
        for field in horizontal { event.setIntegerValueField(field, value: -4) }
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 1.5)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -2.25)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis3, value: 7)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 0)
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: 0)
        event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
        return event
    }

    func testDefaultsAreOptIn() {
        for toml in ["config-version = 2", "config-version = 2\n[scroll-reverser]"] {
            let result = parseConfig(toml)
            XCTAssertTrue(result.errors.isEmpty)
            XCTAssertTrue(result.warnings.isEmpty)
            XCTAssertEqual(result.config.scrollReverser, ScrollReverserConfig())
            XCTAssertFalse(result.config.scrollReverser.enabled)
            XCTAssertTrue(result.config.scrollReverser.reverseVertical)
            XCTAssertFalse(result.config.scrollReverser.reverseHorizontal)
        }
    }

    func testConfiguration() {
        let result = parseConfig("""
        config-version = 2
        [scroll-reverser]
        enabled = true
        reverse-vertical = false
        reverse-horizontal = true
        """)
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertTrue(result.warnings.isEmpty)
        XCTAssertEqual(result.config.scrollReverser, ScrollReverserConfig(enabled: true, reverseVertical: false, reverseHorizontal: true))
    }

    func testInvalidConfiguration() {
        for setting in ["enabled = 'yes'", "reverse-vertical = 1", "reverse-horizontal = []", "unknown = true"] {
            XCTAssertFalse(parseConfig("config-version = 2\n[scroll-reverser]\n\(setting)").errors.isEmpty, setting)
        }
        XCTAssertFalse(parseConfig("config-version = 2\nscroll-reverser = true").errors.isEmpty)
    }

    func testVerticalOnlyPreservesHorizontalAndOtherFields() {
        let event = event()
        event.flags = [.maskShift, .maskControl]
        let timestamp = event.timestamp
        reverseDiscreteScroll(event, settings: ScrollReverserConfig(enabled: true))
        for field in vertical { XCTAssertEqual(event.getIntegerValueField(field), -3) }
        for field in horizontal { XCTAssertEqual(event.getIntegerValueField(field), -4) }
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1), -1.5)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2), -2.25)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis3), 7)
        XCTAssertEqual(event.flags, [.maskShift, .maskControl])
        XCTAssertEqual(event.timestamp, timestamp)
    }

    func testHorizontalOnly() {
        let event = event()
        reverseDiscreteScroll(event, settings: ScrollReverserConfig(enabled: true, reverseVertical: false, reverseHorizontal: true))
        for field in vertical { XCTAssertEqual(event.getIntegerValueField(field), 3) }
        for field in horizontal { XCTAssertEqual(event.getIntegerValueField(field), 4) }
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1), 1.5)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2), 2.25)
    }

    func testBothAxesAndRepeatedReversal() {
        let event = event()
        let settings = ScrollReverserConfig(enabled: true, reverseHorizontal: true)
        reverseDiscreteScroll(event, settings: settings)
        for field in vertical { XCTAssertEqual(event.getIntegerValueField(field), -3) }
        for field in horizontal { XCTAssertEqual(event.getIntegerValueField(field), 4) }
        reverseDiscreteScroll(event, settings: settings)
        for field in vertical { XCTAssertEqual(event.getIntegerValueField(field), 3) }
        for field in horizontal { XCTAssertEqual(event.getIntegerValueField(field), -4) }
    }

    func testDisabledAndNoAxesAreUnchanged() {
        for settings in [ScrollReverserConfig(), ScrollReverserConfig(enabled: true, reverseVertical: false)] {
            let event = event()
            reverseDiscreteScroll(event, settings: settings)
            for field in vertical { XCTAssertEqual(event.getIntegerValueField(field), 3) }
            for field in horizontal { XCTAssertEqual(event.getIntegerValueField(field), -4) }
        }
    }

    func testContinuousAndGestureEventsAreUntouched() {
        for field: CGEventField in [.scrollWheelEventIsContinuous, .scrollWheelEventScrollPhase, .scrollWheelEventMomentumPhase] {
            let event = event()
            event.setIntegerValueField(field, value: 1)
            reverseDiscreteScroll(event, settings: ScrollReverserConfig(enabled: true, reverseHorizontal: true))
            for field in vertical { XCTAssertEqual(event.getIntegerValueField(field), 3) }
            for field in horizontal { XCTAssertEqual(event.getIntegerValueField(field), -4) }
            XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1), 1.5)
            XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2), -2.25)
        }
    }

    func testNonScrollEventIsUntouched() {
        let event = event()
        event.type = .mouseMoved
        let delta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        reverseDiscreteScroll(event, settings: ScrollReverserConfig(enabled: true))
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), delta)
    }

    func testExtremeDeltaDoesNotOverflow() {
        let event = event()
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: Int64.min)
        // CoreGraphics can clamp a value to its underlying field's range.
        let delta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        reverseDiscreteScroll(event, settings: ScrollReverserConfig(enabled: true))
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), delta == Int64.min ? delta : -delta)
    }

    func testApplyAndShutdownDoNotInstallTapDuringTests() {
        let reverser = ScrollReverser()
        reverser.apply(ScrollReverserConfig(enabled: true))
        XCTAssertTrue(reverser.settings.enabled)
        XCTAssertFalse(reverser.isActive)
        XCTAssertNil(reverser.errorMessage)
        reverser.shutdown()
        reverser.apply(ScrollReverserConfig())
        XCTAssertFalse(reverser.isActive)
        XCTAssertFalse(reverser.settings.enabled)
    }
}

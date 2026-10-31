import AppKit
import Common
import CoreGraphics
import SwiftUI

// This deliberately classifies events, not hardware: public CGEvent APIs do not
// reliably identify a scroll event's physical device. Continuous/gesture input
// (trackpads, Magic Mouse, and some smooth-scrolling mouse drivers) is untouched.
func reverseDiscreteScroll(_ event: CGEvent, settings: ScrollReverserConfig) {
    guard settings.enabled,
          event.type == .scrollWheel,
          event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0,
          event.getIntegerValueField(.scrollWheelEventScrollPhase) == 0,
          event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0 else { return }

    func reverseAxis(_ delta: CGEventField, _ fixed: CGEventField, _ point: CGEventField) {
        // CoreGraphics may update related representations when setting a field.
        // Snapshot all three before writing any of them.
        let deltaValue = event.getIntegerValueField(delta)
        let pointValue = event.getIntegerValueField(point)
        let fixedValue = event.getDoubleValueField(fixed)
        // An unrepresentable negation must not crash the event callback.
        guard deltaValue != Int64.min, pointValue != Int64.min else { return }
        event.setIntegerValueField(delta, value: -deltaValue)
        event.setIntegerValueField(point, value: -pointValue)
        event.setDoubleValueField(fixed, value: -fixedValue)
    }
    if settings.reverseVertical {
        reverseAxis(.scrollWheelEventDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventPointDeltaAxis1)
    }
    if settings.reverseHorizontal {
        reverseAxis(.scrollWheelEventDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2, .scrollWheelEventPointDeltaAxis2)
    }
}

@MainActor
final class ScrollReverser: ObservableObject {
    static let shared = ScrollReverser()

    @Published private(set) var settings = ScrollReverserConfig()
    @Published private(set) var isActive = false
    @Published private(set) var errorMessage: String?
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    func apply(_ settings: ScrollReverserConfig) {
        self.settings = settings
        errorMessage = nil
        guard settings.enabled && (settings.reverseVertical || settings.reverseHorizontal) else {
            stop()
            return
        }
        // Unit tests must never install a global input filter or request TCC access.
        guard !isUnitTest else { return }
        if let tap, CFMachPortIsValid(tap) {
            CGEvent.tapEnable(tap: tap, enable: true)
            isActive = true
            return
        }
        stop()
        // No userInfo pointer is retained; CoreGraphics owns each callback event.
        guard let tap = unsafe CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1) << CGEventType.scrollWheel.rawValue,
            callback: { _, type, event, _ in
                // The tap's source is scheduled exclusively on the main run loop.
                MainActor.assumeIsolated {
                    ScrollReverser.shared.handle(type, event)
                }
                return unsafe Unmanaged.passUnretained(event)
            },
            userInfo: nil,
        ) else {
            errorMessage = "Could not start. Check Accessibility and Input Monitoring permissions, then retry."
            return
        }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            errorMessage = "Could not create the scroll event source. Try again."
            return
        }
        self.tap = tap
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isActive = true
    }

    func requestPermissionsAndRetry() {
        // Only an explicit menu action may display system permission prompts.
        _ = CGRequestListenEventAccess()
        _ = CGRequestPostEventAccess()
        apply(settings)
    }

    func shutdown() {
        stop()
        errorMessage = nil
    }

    private func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        source = nil
        tap = nil
        isActive = false
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) {
        switch type {
            case .tapDisabledByTimeout:
                if let tap, settings.enabled {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            case .tapDisabledByUserInput:
                stop()
                errorMessage = "Scroll filtering was disabled by macOS. Retry to resume."
            case .scrollWheel:
                reverseDiscreteScroll(event, settings: settings)
            default:
                break
        }
    }
}

struct ScrollReverserMenu: View {
    @ObservedObject private var reverser = ScrollReverser.shared

    var body: some View {
        Menu("Scroll Reverser") {
            Toggle("Enabled", isOn: setting(\.enabled))
            Toggle("Reverse Vertical", isOn: setting(\.reverseVertical))
            Toggle("Reverse Horizontal", isOn: setting(\.reverseHorizontal))
            Divider()
            Text("Classic mouse wheels only; gestures are unchanged.")
            Text(reverser.isActive ? "Active" : "Inactive")
            if let error = reverser.errorMessage {
                Text(error)
                Button("Grant Permissions / Retry") {
                    reverser.requestPermissionsAndRetry()
                }
                Button("Open Input Monitoring Settings…") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }

    private func setting(_ keyPath: WritableKeyPath<ScrollReverserConfig, Bool>) -> Binding<Bool> {
        Binding(
            get: { reverser.settings[keyPath: keyPath] },
            set: { value in
                var settings = reverser.settings
                settings[keyPath: keyPath] = value
                reverser.apply(settings)
            },
        )
    }
}

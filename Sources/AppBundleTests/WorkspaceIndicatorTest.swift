@testable import AppBundle
import AppKit
import CoreText
import XCTest

@MainActor
final class WorkspaceIndicatorTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    private func item(_ name: String, occupied: Bool = false, active: Bool = false) -> WorkspaceViewModel {
        WorkspaceViewModel(name: name, suffix: "", isFocused: active, isEffectivelyEmpty: !occupied,
                           isPersistent: true, isVisible: active, hasFullscreenWindows: false,
                           windowMode: .floating, hasWindows: occupied)
    }

    func testFiveDefaultWorkspacesAndExplicitOverride() {
        XCTAssertEqual(Array(parseConfig("config-version = 2").config.persistentWorkspaces), ["1", "2", "3", "4", "5"])
        XCTAssertEqual(Array(parseConfig("config-version = 2\npersistent-workspaces = ['2', '7']").config.persistentWorkspaces), ["2", "7"])
    }

    func testSmallerThickerOutlinePreservesCellAndDigitCenter() {
        let cell = CGRect(x: 0, y: 0, width: 22, height: 22)
        let outline = WorkspaceIndicatorStrip.outlineRect(in: cell)
        XCTAssertEqual(WorkspaceIndicatorStrip.outlineWidth, 1.5)
        XCTAssertEqual(outline.width + WorkspaceIndicatorStrip.outlineWidth, 19)
        XCTAssertEqual(outline.height + WorkspaceIndicatorStrip.outlineWidth, 19)
        XCTAssertEqual(outline.midX, cell.midX)
        XCTAssertEqual(outline.midY, cell.midY)
    }

    func testDefaultWorkspacesSurviveGarbageCollectionWhileEmpty() {
        config.persistentWorkspaces = ["1", "2", "3", "4", "5"]
        Workspace.garbageCollectUnusedWorkspaces()
        updateTrayText()
        for name in ["1", "2", "3", "4", "5"] {
            let workspace = TrayMenuModel.shared.workspaces.first { $0.name == name }
            XCTAssertEqual(workspace?.isPersistent, true)
            XCTAssertEqual(workspace?.hasWindows, false)
        }
    }

    func testDrawingHasNoPlaceholderGaps() {
        let strip = WorkspaceIndicatorStrip(workspaces: [item("1"), item("3"), item("7")])
        XCTAssertEqual(strip.cells.map(\.width), [22, 22, 22])
        XCTAssertEqual(strip.cells.map(\.midX), [11, 36, 61])
    }

    func testClickMappingAccountsForImagePaddingAndScaling() {
        let strip = WorkspaceIndicatorStrip(workspaces: [item("1"), item("3"), item("7")])
        for scale: CGFloat in [1, 1.5, 2] {
            let rect = CGRect(x: 8, y: 5, width: 72 * scale, height: 22 * scale)
            for (index, name) in ["1", "3", "7"].enumerated() {
                let point = CGPoint(x: 8 + CGFloat(index * 25 + 11) * scale, y: rect.midY)
                XCTAssertEqual(strip.workspace(at: point, imageRect: rect)?.name, name)
            }
            XCTAssertNil(strip.workspace(at: CGPoint(x: 7, y: rect.midY), imageRect: rect))
            XCTAssertNil(strip.workspace(at: CGPoint(x: 8 + 23 * scale, y: rect.midY), imageRect: rect))
            XCTAssertNil(strip.workspace(at: CGPoint(x: rect.maxX + 1, y: rect.midY), imageRect: rect))
        }
    }

    func testScreenPointConversionUsesDestinationWindowNotForwardedEventWindow() throws {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: -1600, y: 700, width: 140, height: 33),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let button = NSButton(frame: NSRect(x: 8, y: 5, width: 122, height: 22))
        window.contentView?.addSubview(button)
        let strip = WorkspaceIndicatorStrip(workspaces: [item("1"), item("2"), item("3"), item("4"), item("5")])
        button.image = strip.image
        button.title = ""
        button.imagePosition = .imageOnly
        let rect = try XCTUnwrap(button.cell).imageRect(forBounds: button.bounds)
        for index in 0..<5 {
            let local = CGPoint(x: rect.minX + CGFloat(index * 25 + 11) / 122 * rect.width, y: rect.midY)
            let screen = window.convertPoint(toScreen: button.convert(local, to: nil))
            let converted = button.convert(window.convertPoint(fromScreen: screen), from: nil)
            XCTAssertEqual(strip.workspace(at: converted, imageRect: rect)?.name, String(index + 1))
        }
    }

    func testRapidClicksAreDroppedRatherThanOverlappingOrQueuingToggles() {
        var gate = WorkspaceIndicatorClickGate()
        XCTAssertTrue(gate.begin(at: 10, clickCount: 1, interval: 0.5))
        for index in 1...100 {
            XCTAssertFalse(gate.begin(at: 10 + Double(index), clickCount: 1, interval: 0.5))
        }
        gate.finish()
        XCTAssertFalse(gate.begin(at: 10.1, clickCount: 1, interval: 0.5))
        XCTAssertFalse(gate.begin(at: 11, clickCount: 2, interval: 0.5))
        XCTAssertFalse(gate.begin(at: 12, clickCount: 3, interval: 0.5))
        XCTAssertTrue(gate.begin(at: 13, clickCount: 1, interval: 0.5))
        gate.finish()
        XCTAssertFalse(gate.isBusy)
    }

    func testNativeMenuCanBeRebuiltRepeatedlyAcrossPermissionStates() {
        let model = TrayMenuModel.shared
        let previous = model.axPermissionStatus
        defer { model.axPermissionStatus = previous }
        for index in 0..<100 {
            model.axPermissionStatus = index % 2 == 0 ? .granted : .waiting
            updateTrayText()
            let menu = NativeTrayMenu(model: model)
            XCTAssertEqual(menu.items.last?.title, "Quit")
            XCTAssertNotNil(menu.items.first { $0.title == "Screenshots" }?.submenu)
            XCTAssertEqual(menu.items.contains { $0.title == "Grant Accessibility…" }, index % 2 != 0)
            if index % 2 == 0 {
                XCTAssertNotNil(menu.items.first { $0.title == "Workspaces" }?.submenu)
            }
        }
    }

    func testClickSelectsThenTogglesOnlyActiveWorkspace() async throws {
        let first = Workspace.get(byName: "1")
        let second = Workspace.get(byName: "2")
        _ = first.focusWorkspace()
        try await activateWorkspaceIndicator(named: "2")
        XCTAssertTrue(focus.workspace === second)
        XCTAssertEqual(second.windowMode, .tiling)
        try await activateWorkspaceIndicator(named: "2")
        XCTAssertEqual(second.windowMode, .floating)
        XCTAssertEqual(first.windowMode, .tiling)
        try await activateWorkspaceIndicator(named: "2")
        XCTAssertEqual(second.windowMode, .tiling)
    }

    func testVisibleDigitInkIsCenteredForBothFontWeights() throws {
        for occupied in [false, true] {
            for digit in 1...9 {
                let workspace = item(String(digit), occupied: occupied)
                let strip = WorkspaceIndicatorStrip(workspaces: [workspace])
                let cell = try XCTUnwrap(strip.cells.first)
                let ink = CTLineGetImageBounds(WorkspaceIndicatorStrip.line(for: workspace), nil)
                let origin = WorkspaceIndicatorStrip.textOrigin(inkBounds: ink, cell: cell)
                XCTAssertEqual(ink.midX + origin.x, cell.midX, accuracy: 0.001)
                XCTAssertEqual(ink.midY + origin.y, cell.midY, accuracy: 0.001)
                let cg = try XCTUnwrap(unsafe strip.image.cgImage(forProposedRect: nil, context: nil, hints: nil))
                let bitmap = NSBitmapImageRep(cgImage: cg)
                var xs: [Int] = []
                var ys: [Int] = []
                for y in 0..<bitmap.pixelsHigh {
                    for x in 0..<bitmap.pixelsWide where (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.2 {
                        xs.append(x); ys.append(y)
                    }
                }
                let centerX = CGFloat(try XCTUnwrap(xs.min()) + XCTUnwrap(xs.max()) + 1) / 2
                let centerY = CGFloat(try XCTUnwrap(ys.min()) + XCTUnwrap(ys.max()) + 1) / 2
                XCTAssertEqual(centerX, CGFloat(bitmap.pixelsWide) / 2, accuracy: 1)
                XCTAssertEqual(centerY, CGFloat(bitmap.pixelsHigh) / 2, accuracy: 1)
            }
        }
    }

    func testRenderPreview() throws {
        guard let path = ProcessInfo.processInfo.environment["SAGRADA_INDICATOR_PREVIEW"] else { return }
        var workspaces: [WorkspaceViewModel] = []
        for digit in 1...5 {
            workspaces.append(item(String(digit), occupied: digit % 2 == 1, active: digit == 3))
        }
        let strip = WorkspaceIndicatorStrip(workspaces: workspaces)
        let cg = try XCTUnwrap(unsafe strip.image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let data = try XCTUnwrap(NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]))
        try data.write(to: URL(fileURLWithPath: path))
    }
}

import AppKit
import Combine
import Common
import CoreText
import SwiftUI

var interactiveWorkspaceIndicatorsAvailable: Bool {
    if #available(macOS 14.4, *) { return true }
    return false
}

/// Shared drawing geometry, in menu-bar points (not Retina pixels).
@MainActor
struct WorkspaceIndicatorStrip {
    static let height: CGFloat = 22
    static let spacing: CGFloat = 3
    static let outlineWidth: CGFloat = 1.5

    /// 19 pt outer outline inside a 22 pt cell; the stroke is centered on the path.
    static func outlineRect(in cell: CGRect) -> CGRect {
        cell.insetBy(dx: 1.5 + outlineWidth / 2, dy: 1.5 + outlineWidth / 2)
    }
    let workspaces: [WorkspaceViewModel]

    static func font(occupied: Bool) -> NSFont {
        .monospacedDigitSystemFont(ofSize: 13, weight: occupied ? .heavy : .light)
    }

    static func line(for workspace: WorkspaceViewModel) -> CTLine {
        CTLineCreateWithAttributedString(NSAttributedString(string: workspace.name, attributes: [
            .font: font(occupied: workspace.hasWindows),
            .foregroundColor: NSColor.black,
        ]))
    }

    /// Center the visible glyph, not the font's asymmetric ascender/descender box.
    static func textOrigin(inkBounds: CGRect, cell: CGRect) -> CGPoint {
        CGPoint(x: cell.midX - inkBounds.midX, y: cell.midY - inkBounds.midY)
    }

    var cells: [CGRect] {
        var x: CGFloat = 0
        return workspaces.map { workspace in
            let ink = CTLineGetImageBounds(Self.line(for: workspace), nil)
            let width = max(Self.height, ceil(ink.width) + 12)
            defer { x += width + Self.spacing }
            return CGRect(x: x, y: 0, width: width, height: Self.height)
        }
    }

    /// Normalize to the drawn image, including AppKit padding/scaling. A miss is a
    /// no-op, never a fallback to opening a menu.
    func workspace(at point: CGPoint, imageRect: CGRect) -> WorkspaceViewModel? {
        guard imageRect.width > 0, imageRect.height > 0, imageRect.contains(point),
              let width = cells.last?.maxX else { return nil }
        let x = (point.x - imageRect.minX) / imageRect.width * width
        return zip(workspaces, cells).first { x >= $0.1.minX && x < $0.1.maxX }?.0
    }

    var image: NSImage {
        let cells = cells
        let workspaces = workspaces
        let image = NSImage(size: NSSize(width: cells.last?.maxX ?? 0, height: Self.height), flipped: false) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            for (workspace, cell) in zip(workspaces, cells) {
                if workspace.isFocused {
                    let frame = Self.outlineRect(in: cell)
                    let path = workspace.windowMode == .floating
                        ? NSBezierPath(ovalIn: frame)
                        : NSBezierPath(roundedRect: frame, xRadius: 3, yRadius: 3)
                    NSColor.black.setStroke()
                    path.lineWidth = Self.outlineWidth
                    path.stroke()
                }
                let line = Self.line(for: workspace)
                context.textMatrix = .identity
                context.textPosition = .zero
                let ink = CTLineGetImageBounds(line, context)
                context.textPosition = Self.textOrigin(inkBounds: ink, cell: cell)
                CTLineDraw(line, context)
            }
            return true
        }
        image.isTemplate = true // Let AppKit handle light/dark and highlighted menu-bar appearance.
        return image
    }
}

@MainActor
func activateWorkspaceIndicator(named name: String) async throws {
    let workspace = Workspace.get(byName: name)
    if focus.workspace == workspace {
        try await workspace.setWindowMode(workspace.windowMode == .tiling ? .floating : .tiling)
    } else {
        _ = workspace.focusWorkspace()
    }
}

/// Drop overlapping operations and the follow-up clicks of a double/multiple click.
/// Do not queue toggles which could unexpectedly run after the user has stopped clicking.
struct WorkspaceIndicatorClickGate {
    private(set) var isBusy = false
    private var lastStart: TimeInterval = -.infinity

    mutating func begin(at time: TimeInterval, clickCount: Int, interval: TimeInterval) -> Bool {
        guard !isBusy, clickCount <= 1, time - lastStart >= interval else { return false }
        isBusy = true
        lastStart = time
        return true
    }

    mutating func finish() { isBusy = false }
}

/// The native status button receives clicks; macOS's remote menu-bar host does
/// not reliably forward events to custom subviews. Resolve screen coordinates in
/// the button's own window, never NSEvent.locationInWindow from a forwarding host.
@available(macOS 14.4, *)
@MainActor
final class WorkspaceStatusItem: NSObject, NSMenuDelegate {
    static let shared = WorkspaceStatusItem()
    private let model = TrayMenuModel.shared
    private var strip = WorkspaceIndicatorStrip(workspaces: [])
    private var observation: AnyCancellable?
    private var clickGate = WorkspaceIndicatorClickGate()
    private let stripItem = NSStatusBar.system.statusItem(withLength: 0)
    private var menuIsOpen = false
    private var activeMenu: NativeTrayMenu?

    private override init() {
        super.init()
        if let host = stripItem.button {
            host.title = ""
            host.target = self
            host.action = #selector(stripClicked(_:))
            host.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        observation = model.objectWillChange.sink { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        refresh()
    }

    private func refresh() {
        guard !menuIsOpen, let host = stripItem.button else { return }
        // Persistent workspaces remain selectable even while empty.
        let workspaces = model.axPermissionStatus == .granted && model.isEnabled
            ? model.workspaces.filter { !$0.isEffectivelyEmpty || $0.isVisible || $0.isFocused || $0.isPersistent } : []
        strip = WorkspaceIndicatorStrip(workspaces: workspaces)
        stripItem.length = NSStatusItem.variableLength
        guard !workspaces.isEmpty else {
            // Keep Enable/permission controls reachable, without a second logo item.
            let symbol = model.axPermissionStatus == .granted ? "pause.circle" : "exclamationmark.triangle"
            host.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Sagrada menu")
            host.toolTip = "Sagrada menu"
            host.setAccessibilityLabel("Sagrada menu")
            return
        }
        host.image = strip.image
        host.toolTip = "Click: select workspace or toggle its layout. Right-click: Sagrada menu."
        host.setAccessibilityLabel(workspaces.map { "Workspace \($0.name), \($0.windowMode.title)\($0.isFocused ? ", active" : "")" }.joined(separator: ". "))
    }

    @objc private func stripClicked(_ sender: NSStatusBarButton) {
        guard !menuIsOpen else { return }
        let event = NSApp.currentEvent
        if strip.workspaces.isEmpty || event?.type == .rightMouseUp || event?.type == .rightMouseDown || event?.modifierFlags.contains(.control) == true {
            openMenu()
            return
        }
        guard let window = sender.window, let cell = sender.cell else { return }
        let screenPoint = NSEvent.mouseLocation
        let localPoint = sender.convert(window.convertPoint(fromScreen: screenPoint), from: nil)
        let imageRect = cell.imageRect(forBounds: sender.bounds)
        let name = strip.workspace(at: localPoint, imageRect: imageRect)?.name
        clicked(name: name, event: event)
    }

    private func clicked(name: String?, event: NSEvent?) {
        guard !menuIsOpen else { return }
        if event?.type == .rightMouseUp || event?.type == .rightMouseDown || event?.modifierFlags.contains(.control) == true { return }
        guard let name, model.axPermissionStatus == .granted, model.isEnabled,
              let token: RunSessionGuard = .isServerEnabled else { return }
        // Status-item actions may be forwarded as non-mouse events. Never ask those
        // events for mouse-only properties (AppKit may raise an Objective-C exception).
        let clickCount: Int
        switch event?.type {
            case .leftMouseDown?, .leftMouseUp?: clickCount = event?.clickCount ?? 1
            default: clickCount = 1
        }
        guard clickGate.begin(at: ProcessInfo.processInfo.systemUptime, clickCount: clickCount,
                              interval: NSEvent.doubleClickInterval) else { return }
        Task { @MainActor in
            defer { clickGate.finish() }
            do {
                try await runLightSession(.menuBarButton, token) {
                    try await activateWorkspaceIndicator(named: name)
                }
            } catch is CancellationError {
                // Another refresh may supersede a click; it is not a fatal error.
            } catch {
                NSLog("Sagrada workspace click failed: %@", String(describing: error))
            }
        }
    }

    @objc private func openMenu() {
        guard !menuIsOpen else { return }
        menuIsOpen = true
        let menu = NativeTrayMenu(model: model)
        activeMenu = menu
        menu.delegate = self
        // Let AppKit position/track this as a real status-item menu. A manual popup
        // with forwarded coordinates can place menu actions beneath the original click.
        stripItem.menu = menu
        stripItem.button?.performClick(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        // Menu actions can be dispatched after menuDidClose. Retain their targets until
        // tracking and action delivery have completely unwound.
        Task { @MainActor [weak self] in
            guard let self else { return }
            stripItem.menu = nil
            menuIsOpen = false
            refresh()
        }
    }
}

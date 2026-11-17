@testable import AppBundle
import Common
import XCTest

@MainActor
final class WorkspaceWindowModeTest: XCTestCase {
    override func setUp() async throws {
        setUpWorkspacesForTests()
    }

    func testNewWorkspaceDefaultsToTilingEvenWhenCurrentWorkspaceFloats() async throws {
        try await focus.workspace.setWindowMode(.floating)
        let workspace = Workspace.get(byName: name)
        XCTAssertEqual(workspace.windowMode, .tiling)
        let binding = unbindAndGetBindingDataForNewTilingWindow(workspace, window: nil)
        XCTAssertTrue(binding.parent === workspace.rootTilingContainer)
    }

    func testSwitchConvertsAllWindowsAndKeepsOtherWorkspaceUntouched() async throws {
        let workspace = Workspace.get(byName: name)
        let other = Workspace.get(byName: name + "-other")
        let first = TestWindow.new(id: 1, parent: workspace.rootTilingContainer)
        let second = TestWindow.new(id: 2, parent: workspace.rootTilingContainer)
        let third = TestWindow.new(id: 3, parent: other.rootTilingContainer)

        try await workspace.setWindowMode(.floating)
        XCTAssertTrue(first.isFloating)
        XCTAssertTrue(second.isFloating)
        XCTAssertFalse(third.isFloating)
        XCTAssertEqual(other.windowMode, .tiling)

        try await workspace.setWindowMode(.tiling)
        XCTAssertFalse(first.isFloating)
        XCTAssertFalse(second.isFloating)
        XCTAssertEqual(workspace.rootTilingContainer.allLeafWindowsRecursive.count, 2)
    }

    func testEmptyWorkspaceModeControlsNewWindows() async throws {
        let workspace = Workspace.get(byName: name)
        try await workspace.setWindowMode(.floating)
        let data = unbindAndGetBindingDataForNewTilingWindow(workspace, window: nil)
        XCTAssertTrue(data.parent === workspace.floatingWindowsContainer)
        try await workspace.setWindowMode(.tiling)
        let tiled = unbindAndGetBindingDataForNewTilingWindow(workspace, window: nil)
        XCTAssertTrue(tiled.parent === workspace.rootTilingContainer)
    }

    func testMovedOrRestoredTiledWindowsFollowFloatingPolicy() async throws {
        let workspace = Workspace.get(byName: name)
        try await workspace.setWindowMode(.floating)
        let window = TestWindow.new(id: 1, parent: workspace.rootTilingContainer)
        workspace.floatTiledWindows()
        XCTAssertTrue(window.isFloating)
        XCTAssertTrue(window.nodeWorkspace === workspace)
        workspace.floatTiledWindows()
        XCTAssertEqual(workspace.floatingWindowsContainer.allLeafWindowsRecursive.count, 1)
    }

    func testNativeFullscreenAndHiddenWindowsAreNotRebound() async throws {
        let workspace = Workspace.get(byName: name)
        let fullscreen = TestWindow.new(id: 1, parent: workspace.macOsNativeFullscreenWindowsContainer)
        let hidden = TestWindow.new(id: 2, parent: workspace.macOsNativeHiddenAppsWindowsContainer)
        try await workspace.setWindowMode(.floating)
        XCTAssertTrue(fullscreen.parent === workspace.macOsNativeFullscreenWindowsContainer)
        XCTAssertTrue(hidden.parent === workspace.macOsNativeHiddenAppsWindowsContainer)
    }

    func testRootLayoutCommandTogglesEmptyWorkspaceAndRejectsNoop() async throws {
        let workspace = Workspace.get(byName: name)
        _ = workspace.focusWorkspace()
        _ = await parseCommand("layout --root floating tiling").cmdOrDie.run(.defaultEnv, .emptyStdin)
        XCTAssertEqual(workspace.windowMode, .floating)
        _ = await parseCommand("layout --root floating tiling").cmdOrDie.run(.defaultEnv, .emptyStdin)
        XCTAssertEqual(workspace.windowMode, .tiling)
        let result = await parseCommand("layout --root --fail-if-noop tiling").cmdOrDie.run(.defaultEnv, .emptyStdin)
        XCTAssertEqual(result.exitCode.rawValue, 2)
    }

    func testTraySeparatesOccupancyFocusAndWindowMode() async throws {
        let workspace = Workspace.get(byName: name)
        _ = workspace.focusWorkspace()
        try await workspace.setWindowMode(.floating)
        updateTrayText()
        let empty = try XCTUnwrap(TrayMenuModel.shared.workspaces.first { $0.name == workspace.name })
        XCTAssertFalse(empty.hasWindows)
        XCTAssertTrue(empty.isFocused)
        XCTAssertEqual(empty.windowMode, .floating)

        _ = TestWindow.new(id: 1, parent: workspace.floatingWindowsContainer)
        updateTrayText()
        let occupied = try XCTUnwrap(TrayMenuModel.shared.workspaces.first { $0.name == workspace.name })
        XCTAssertTrue(occupied.hasWindows)
        XCTAssertEqual(occupied.windowMode, .floating)
    }
}

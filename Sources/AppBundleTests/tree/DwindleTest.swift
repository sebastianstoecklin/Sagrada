@testable import AppBundle
import XCTest

@MainActor
final class DwindleTest: XCTestCase {
    override func setUp() async throws {
        setUpWorkspacesForTests()
        config.enableDwindle = true
    }

    private func insert(_ id: UInt32, into workspace: Workspace) -> TestWindow {
        let data = unbindAndGetBindingDataForNewTilingWindow(workspace, window: nil)
        let window = TestWindow.new(id: id, parent: data.parent, adaptiveWeight: data.adaptiveWeight)
        window.bind(to: data.parent, adaptiveWeight: data.adaptiveWeight, index: data.index)
        return window
    }

    func testAlternatingBinarySplits() {
        let workspace = Workspace.get(byName: name)
        for id in UInt32(1)...4 { _ = insert(id, into: workspace) }
        assertEquals(workspace.rootTilingContainer.layoutDescription, .h_tiles([
            .window(1), .v_tiles([.window(2), .h_tiles([.window(3), .window(4)])]),
        ]))
        config.enableNormalizationFlattenContainers = true
        config.enableNormalizationOppositeOrientationForNestedContainers = true
        workspace.normalizeContainers()
        assertEquals(workspace.rootTilingContainer.layoutDescription, .h_tiles([
            .window(1), .v_tiles([.window(2), .h_tiles([.window(3), .window(4)])]),
        ]))
    }

    func testSplitsFocusedTileAndPreservesOuterWeight() {
        let workspace = Workspace.get(byName: name)
        let first = insert(1, into: workspace)
        _ = insert(2, into: workspace)
        first.setWeight(.h, 3)
        first.markAsMostRecentChild()
        _ = insert(3, into: workspace)
        assertEquals(workspace.rootTilingContainer.layoutDescription, .h_tiles([
            .v_tiles([.window(1), .window(3)]), .window(2),
        ]))
        assertEquals(workspace.rootTilingContainer.children[0].getWeight(.h), 3)
        assertEquals(first.getWeight(.v), 1)
    }

    func testFloatingFocusDoesNotPreventTilingSplit() {
        let workspace = Workspace.get(byName: name)
        _ = insert(1, into: workspace)
        _ = insert(2, into: workspace)
        _ = TestWindow.new(id: 9, parent: workspace.floatingWindowsContainer)
        _ = insert(3, into: workspace)
        assertEquals(workspace.rootTilingContainer.layoutDescription, .h_tiles([
            .window(1), .v_tiles([.window(2), .window(3)]),
        ]))
        assertEquals(workspace.floatingWindows.map(\.windowId), [9])
    }

    func testAccordionAndOptOutKeepSiblingInsertion() {
        let workspace = Workspace.get(byName: name)
        workspace.rootTilingContainer.layout = .accordion
        for id in UInt32(1)...3 { _ = insert(id, into: workspace) }
        assertEquals(workspace.rootTilingContainer.layoutDescription, .h_accordion([
            .window(1), .window(2), .window(3),
        ]))
        config.enableDwindle = false
        workspace.rootTilingContainer.layout = .tiles
        _ = insert(4, into: workspace)
        assertEquals(workspace.rootTilingContainer.children.count, 4)
    }

    func testReusesSingleChildAfterClose() {
        let workspace = Workspace.get(byName: name)
        _ = insert(1, into: workspace)
        let second = insert(2, into: workspace)
        _ = insert(3, into: workspace)
        second.unbindFromParent()
        _ = insert(4, into: workspace)
        assertEquals(workspace.rootTilingContainer.layoutDescription, .h_tiles([
            .window(1), .v_tiles([.window(3), .window(4)]),
        ]))
    }

    func testConfigDefaultAndOptOut() {
        XCTAssertTrue(Config().enableDwindle)
        let result = parseConfig("config-version = 2\nenable-dwindle = false")
        assertEquals(result.errors, [])
        assertEquals(result.warnings, [])
        XCTAssertFalse(result.config.enableDwindle)
    }
}

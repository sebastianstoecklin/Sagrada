@testable import AppBundle
import Common
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

    func testBundledOmarchyBindingsPreserveSplitsAndWeights() async throws {
        let toml = try String(contentsOf: projectRoot.appending(component: "docs/config-examples/default-config.toml"), encoding: .utf8)
        let result = parseConfig(toml)
        assertEquals(result.errors, [])
        config = result.config

        let workspace = Workspace.get(byName: name)
        let first = insert(1, into: workspace)
        let second = insert(2, into: workspace)
        let third = insert(3, into: workspace)
        let root = workspace.rootTilingContainer
        let split = second.parent as! TilingContainer
        first.setWeight(.h, 3)
        split.setWeight(.h, 7)
        second.setWeight(.v, 2)
        third.setWeight(.v, 5)
        assertEquals(second.focusWindow(), true)
        assertEquals(first.focusWindow(), true)

        // Cross the outer split, then swap within the inner split and back.
        for (direction, left, top, bottom) in [
            ("right", UInt32(2), UInt32(1), UInt32(3)),
            ("down", 2, 3, 1),
            ("up", 2, 1, 3),
            ("left", 1, 2, 3),
        ] {
            _ = await parseCommand("trigger-binding cmd-shift-\(direction) --mode main").cmdOrDie.run(.defaultEnv, .emptyStdin)
            workspace.normalizeContainers()
            assertEquals(root.layoutDescription, .h_tiles([
                .window(left), .v_tiles([.window(top), .window(bottom)]),
            ]))
            assertEquals(root.children[0].getWeight(.h), 3)
            assertEquals(split.getWeight(.h), 7)
            assertEquals(split.children[0].getWeight(.v), 2)
            assertEquals(split.children[1].getWeight(.v), 5)
            assertEquals(focus.windowOrNil?.windowId, 1)
            assertEquals(root.mostRecentWindowRecursive?.windowId, 1)
        }
    }

    func testSwapAtWorkspaceEdgeDoesNotCreateSplitOrWrap() async {
        let workspace = Workspace.get(byName: name)
        let first = insert(1, into: workspace)
        _ = insert(2, into: workspace)
        _ = insert(3, into: workspace)
        assertEquals(first.focusWindow(), true)
        for direction in ["left", "up", "down"] {
            _ = await parseCommand("swap \(direction)").cmdOrDie.run(.defaultEnv, .emptyStdin)
            workspace.normalizeContainers()
            assertEquals(workspace.rootTilingContainer.layoutDescription, .h_tiles([
                .window(1), .v_tiles([.window(2), .window(3)]),
            ]))
            assertEquals(focus.windowOrNil?.windowId, 1)
        }
    }

    func testConfigDefaultAndOptOut() {
        XCTAssertTrue(Config().enableDwindle)
        let result = parseConfig("config-version = 2\nenable-dwindle = false")
        assertEquals(result.errors, [])
        assertEquals(result.warnings, [])
        XCTAssertFalse(result.config.enableDwindle)
    }
}

package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class CursorVersionSource <: CjguiComposableUiTreeDataSource & CjguiComposableUiTreeContentUpdateSource {
    public var reads: Int64 = 0
    public var since: Int64 = -1
    public func childCount(parentKey: String): Int64 { return if (parentKey == "") { 1 } else { 0 } }
    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        return CjguiComposableUiTreeNode("row", "captured six", 1, false)
    }
    public func contentVersion(): Int64 { reads += 1; return 7 }
    public func contentUpdates(sinceVersion: Int64): ?ArrayList<CjguiComposableUiTreeContentUpdate> {
        since = sinceVersion
        return if (sinceVersion == 6) {
            Some(ArrayList<CjguiComposableUiTreeContentUpdate>([CjguiComposableUiTreeContentUpdate("row", "live seven")]))
        } else { None }
    }
}

@Test
func cursorVersionExplicitMarkUsesCapturedContextWithoutReadingProvider(): Unit {
    let source = CursorVersionSource()
    let projection = CjguiComposableUiTreeProjection(source)
    projection.attachContentUpdateSource(source)
    projection.markSourceIndexCurrent(6)
    @Assert(source.reads, 0)
    @Assert(projection.refreshContentOnly(), true)
    @Assert(source.reads, 1)
    @Assert(source.since, 6)
    @Assert(projection.rowAt(0).label, "live seven")
    @Assert(projection.lastContentPatchedRows(), 1)
}

@Test
func cursorVersionLegacyMarkRetainsItsLiveReadBehavior(): Unit {
    let source = CursorVersionSource()
    let projection = CjguiComposableUiTreeProjection(source)
    projection.attachContentUpdateSource(source)
    projection.markSourceIndexCurrent()
    @Assert(source.reads, 1)
    @Assert(projection.refreshContentOnly(), true)
    @Assert(source.reads, 2)
    @Assert(source.since, -1)
    @Assert(projection.rowAt(0).label, "captured six")
}

@Test
func cursorVersionUnknownCapturedContextDoesNotArmContentFastPath(): Unit {
    let source = CursorVersionSource()
    let projection = CjguiComposableUiTreeProjection(source)
    projection.attachContentUpdateSource(source)
    projection.markSourceIndexCurrent(-1)
    @Assert(projection.refreshContentOnly(), false)
    @Assert(source.reads, 0)
    @Assert(source.since, -1)
}

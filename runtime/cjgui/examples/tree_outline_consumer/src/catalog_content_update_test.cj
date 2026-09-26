// The public UI-only tree consumer also serves the framework's content-only
// update path: renaming one existing catalog row patches that row by stable key,
// while a change the owner cannot describe as content-only still forces the
// caller to rebuild.
package cjgui_ui_only_starter

import cjgui.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

/// Builds the layout node the window would hand to the controller for one
/// projected leaf row: the same action name/resource pair the row builder
/// declares, so the dispatch below is the real consumer path.
private func catalogLeafNode(controller: CatalogController, resourceId: Int64): CjguiComposableUiLayoutNode {
    let _ = controller
    let bounds = CjguiComposableUiRect(0, 0, 200, 26)
    return CjguiComposableUiLayoutNode(
        cjguiComposableButton(0, "catalog-vleaf-test", "条目", "CATALOG_LEAF_TOGGLE", resourceId,
            CjguiComposableUiStyle(fixedHeight: 26)),
        bounds, bounds)
}

@Test
func catalogRenamePatchesByKeyAndStructuralChangeRebuilds(): Unit {
    let source = CatalogSource(ArrayList<String>(["领域甲", "领域乙"]), 2, 2)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.attachContentUpdateSource(source)
    projection.markSourceIndexCurrent()
    let _ = projection.setExpandedBatch(projection.groupKeys(), true)
    @Assert(projection.rowCount() > 0, true)

    let key = "domain-0-topic-0-entry-0"
    let index = projection.indexForKey(key)
    @Assert(index >= 0, true)
    let before = projection.rowAt(index).label
    // Owner-side rename, then the content-only refresh: the row is patched, not
    // the whole logical tree.
    @Assert(source.renameEntry(key, "改名后的条目"), true)
    @Assert(projection.refreshContentOnly(), true)
    @Assert(projection.lastContentPatchedRows(), 1)
    @Assert(projection.contentRefreshCount(), 1)
    let patched = projection.rowAt(projection.indexForKey(key)).label
    @Assert(patched, "改名后的条目")
    @Assert(patched != before, true)
    // Every other row and the stable key index are untouched.
    @Assert(projection.indexForKey(key), index)

    // A change the owner cannot prove to be content-only must not be patched.
    source.markStructuralChange()
    @Assert(projection.refreshContentOnly(), false)
    let _ = projection.rebuild()
    @Assert(projection.rowAt(projection.indexForKey(key)).label, "改名后的条目")

    // The owner refuses an unknown key instead of inventing a row.
    @Assert(source.renameEntry("domain-9-topic-9-entry-9", "不存在"), false)
    @Assert(source.renameEntry(key, ""), false)
}

/// Key identity is the CANONICAL rebuilt key, not "the digit runs look
/// plausible": near-miss keys must be refused without touching data, version or
/// notification, so no bogus patch can ever be emitted.
@Test
func catalogRenameRefusesNonCanonicalKeysWithoutSideEffects(): Unit {
    let source = CatalogSource(ArrayList<String>(["领域甲"]), 2, 2)
    let projection = CjguiComposableUiTreeProjection(source)
    projection.attachContentUpdateSource(source)
    projection.markSourceIndexCurrent()
    let _ = projection.setExpandedBatch(projection.groupKeys(), true)
    let versionBefore = source.contentVersion()
    let labelBefore = projection.rowAt(projection.indexForKey("domain-0-topic-0-entry-0")).label
    let stateBefore = projection.refreshContentOnly()
    @Assert(stateBefore, true)
    let refreshesBefore = projection.contentRefreshCount()

    // Each of these parses to plausible numbers but is not the canonical key.
    let nearMisses = ArrayList<String>([
        "domain-0garbage",
        "domain-0-topic-1-junk",
        "domain-0-topic-1-entry-1x",
        "domain-0-topic--1-entry-1",
        "domain-00",
        "domain-0-topic-01-entry-1"
    ])
    var index: Int64 = 0
    while (index < nearMisses.size) {
        let key = nearMisses[index]
        @Assert(source.renameEntry(key, "不该写入"), false)
        @Assert(source.contentVersion(), versionBefore)
        index += 1
    }
    // A refused key produces no new refresh and no row content change.
    @Assert(projection.refreshContentOnly(), true)
    @Assert(projection.contentRefreshCount(), refreshesBefore)
    @Assert(projection.rowAt(projection.indexForKey("domain-0-topic-0-entry-0")).label, labelBefore)
    // The canonical forms still work, one owner change per refresh step.
    @Assert(source.renameEntry("domain-0", "组改名"), true)
    @Assert(projection.refreshContentOnly(), true)
    @Assert(source.renameEntry("domain-0-topic-1", "主题改名"), true)
    @Assert(projection.refreshContentOnly(), true)
    @Assert(source.renameEntry("domain-0-topic-1-entry-1", "条目改名"), true)
    @Assert(projection.refreshContentOnly(), true)
    @Assert(projection.rowAt(projection.indexForKey("domain-0")).label, "组改名")
    @Assert(projection.rowAt(projection.indexForKey("domain-0-topic-1")).label, "主题改名")
    @Assert(projection.rowAt(projection.indexForKey("domain-0-topic-1-entry-1")).label, "条目改名")
    // A renamed group is still a non-selectable container.
    @Assert(projection.rowAt(projection.indexForKey("domain-0")).selectable, false)
    @Assert(projection.rowAt(projection.indexForKey("domain-0")).isGroup, true)
}

/// The mounted controller follows the same path: a rename through the controller
/// is a content-only refresh that keeps the multi-selection, the focus and the
/// visible row count, and keeps the scene revision moving.
@Test
func catalogControllerRenameIsContentOnlyAndKeepsSelection(): Unit {
    let source = CatalogSource(ArrayList<String>(["领域甲"]), 3, 3)
    let controller = CatalogController(source)
    let _ = controller.buildUi()
    controller.expandAll()
    // 1 domain + 3 topics + 9 entries.
    @Assert(controller.visibleRowCount(), 13)

    // Two real leaf toggles through the ordinary dispatch path, the second with
    // the command modifier so it adds to the selection instead of replacing it.
    let firstLeaf = catalogLeafNode(controller, 311)
    let secondLeaf = catalogLeafNode(controller, 322)
    @Assert(controller.applyUiEvent(
        CjguiComposableUiEvent(firstLeaf, 27, "", 0, 0, 1)).didApply, true)
    @Assert(controller.applyUiEvent(
        CjguiComposableUiEvent(secondLeaf, 27, "", 0, 0, 1,
            modifierFlags: 1 << 20)).didApply, true)
    @Assert(controller.selectedCount(), 2)
    let selectedBefore = controller.selectedKeys()
    @Assert(selectedBefore.size, 2)
    let focusBefore = controller.focusKey()
    let versionBefore = controller.uiSceneVersion()

    // A content-only rename through the controller keeps every identity.
    @Assert(controller.renameEntry("domain-0-topic-1-entry-1", "控制器改名"), true)
    @Assert(controller.uiSceneVersion() > versionBefore, true)
    @Assert(controller.selectedCount(), 2)
    let selectedAfter = controller.selectedKeys()
    @Assert(selectedAfter.size, 2)
    @Assert(selectedAfter[0], selectedBefore[0])
    @Assert(selectedAfter[1], selectedBefore[1])
    @Assert(controller.focusKey(), focusBefore)
    // Content-only: no row appeared or disappeared, and the section still builds.
    @Assert(controller.visibleRowCount(), 13)
    let rebuilt = controller.buildUi()
    @Assert(rebuilt.children().size > 0, true)
    @Assert(controller.visibleRowCount(), 13)

    // An unknown key through the controller is refused without bumping anything.
    let versionAfterRefusal = controller.uiSceneVersion()
    @Assert(controller.renameEntry("domain-0-topic-9-entry-9", "越界"), false)
    @Assert(controller.uiSceneVersion(), versionAfterRefusal)
    @Assert(controller.selectedCount(), 2)
}

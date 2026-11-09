// Counterexamples for the tree content-only update contract
// (composable_ui_tree.cj):
//
//   * a content update replaces DISPLAYED CONTENT only - a non-selectable group
//     renamed by the fast path stays non-selectable, and keeps its resource,
//     depth, kind and expansion;
//   * a declared selectability that disagrees with the live row is not a
//     content-only change: the WHOLE batch is refused before any write, and the
//     caller's rebuild + selection correction restores the real semantics;
//   * an unknown key, an un-armed caller index and a version regression never
//     take the fast path;
//   * a selected leaf that stops being selectable does not leave an unusable
//     selection or anchor behind.
//
// Pure host code: no window, no native module.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

/// Owner-like source whose labels and selectability can really change, and which
/// can declare the changed keys - or deliberately misdeclare one.
class TreeContentUpdateSource <: CjguiComposableUiTreeDataSource &
    CjguiComposableUiTreeContentUpdateSource {
    // -1 = do not declare, 0 = declare false, 1 = declare true.
    static let DECLARE_NONE: Int64 = -1
    private let labels: HashMap<String, String> = HashMap<String, String>()
    private let disabled: HashSet<String> = HashSet<String>()
    private var contentVersionValue: Int64 = 0
    private var reportedVersion: Int64 = -1
    private var lastKeys: ArrayList<String> = ArrayList<String>()
    private var lastLabels: ArrayList<String> = ArrayList<String>()
    private var lastDeclared: ArrayList<Int64> = ArrayList<Int64>()
    private var describable: Bool = true

    public init() {}

    // --- data source ---------------------------------------------------------

    public func childCount(parentKey: String): Int64 {
        if (parentKey.isEmpty()) {
            return 2
        }
        if (parentKey.startsWith("group-")) {
            return 2
        }
        return 0
    }

    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        if (parentKey.isEmpty()) {
            let key = "group-${index}"
            // Groups are structural containers: never selectable, always a group.
            return CjguiComposableUiTreeNode(key, labelFor(key, "组 ${index}"), 100 + index, true,
                selectable: false)
        }
        let key = "${parentKey}-leaf-${index}"
        return CjguiComposableUiTreeNode(key, labelFor(key, "叶 ${index}"), 200 + index, false,
            selectable: !disabled.contains(key))
    }

    private func labelFor(key: String, fallback: String): String {
        if (let Some(value) <- labels.get(key)) {
            return value
        }
        return fallback
    }

    // --- content-only capability --------------------------------------------

    public func contentVersion(): Int64 {
        if (reportedVersion >= 0) {
            return reportedVersion
        }
        return contentVersionValue
    }

    public func contentUpdates(sinceVersion: Int64): ?ArrayList<CjguiComposableUiTreeContentUpdate> {
        if (!describable) {
            return None
        }
        if (sinceVersion != contentVersionValue - 1) {
            return None
        }
        let updates = ArrayList<CjguiComposableUiTreeContentUpdate>()
        var index: Int64 = 0
        while (index < lastKeys.size) {
            let code = lastDeclared[index]
            let declared: ?Bool = if (code < 0) {
                None
            } else {
                Some(code == 1)
            }
            updates.add(CjguiComposableUiTreeContentUpdate(lastKeys[index], lastLabels[index],
                selectable: declared))
            index += 1
        }
        return Some(updates)
    }

    // --- owner-side changes --------------------------------------------------

    /// One owner content change, optionally declaring a new selectability.
    public func rename(key: String, label: String, declare!: Int64 = -1): Unit {
        renameBatch(ArrayList<String>([key]), ArrayList<String>([label]), ArrayList<Int64>([declare]))
    }

    /// A batch of owner content changes in one version step.
    public func renameBatch(keys: ArrayList<String>, newLabels: ArrayList<String>,
                            declares: ArrayList<Int64>): Unit {
        var index: Int64 = 0
        while (index < keys.size) {
            labels.add(keys[index], newLabels[index])
            index += 1
        }
        lastKeys = ArrayList<String>(keys)
        lastLabels = ArrayList<String>(newLabels)
        lastDeclared = ArrayList<Int64>(declares)
        describable = true
        contentVersionValue += 1
    }

    /// The owner really made a leaf unselectable (a structural/selection-domain
    /// change) and declares it.
    public func makeUnselectable(key: String): Unit {
        disabled.add(key)
        lastKeys = ArrayList<String>([key])
        lastLabels = ArrayList<String>([labelFor(key, "叶")])
        lastDeclared = ArrayList<Int64>([0])
        describable = true
        contentVersionValue += 1
    }

    /// An owner change it cannot describe as content-only.
    public func makeUndescribable(): Unit {
        lastKeys = ArrayList<String>()
        lastLabels = ArrayList<String>()
        lastDeclared = ArrayList<Int64>()
        describable = false
        contentVersionValue += 1
    }

    /// Simulates a source that reports a wrong (older) version.
    public func reportVersion(version: Int64): Unit {
        reportedVersion = version
    }
}

private func contentUpdateProjection(source: TreeContentUpdateSource): CjguiComposableUiTreeProjection {
    let projection = CjguiComposableUiTreeProjection(source)
    projection.attachContentUpdateSource(source)
    // The caller just built its index from the source's current state.
    projection.markSourceIndexCurrent()
    let _ = projection.setExpanded("group-0", true)
    return projection
}

@Test
func treeContentUpdatePreservesRowIdentityAndSelectability(): Unit {
    let source = TreeContentUpdateSource()
    let projection = contentUpdateProjection(source)
    let rowsBefore = projection.rowCount()
    let groupIndex = projection.indexForKey("group-0")
    @Assert(groupIndex >= 0, true)
    let groupBefore = projection.rowAt(groupIndex)
    // The group is a non-selectable container.
    @Assert(groupBefore.selectable, false)
    @Assert(groupBefore.isGroup, true)

    source.rename("group-0", "改名后的组")
    @Assert(projection.refreshContentOnly(), true)
    @Assert(projection.lastContentPatchedRows(), 1)
    let groupAfter = projection.rowAt(projection.indexForKey("group-0"))
    @Assert(groupAfter.label, "改名后的组")
    // The counterexample: a group rename must NOT make the container selectable.
    @Assert(groupAfter.selectable, false)
    // Identity/resource/structure are the live row's own, not the update's.
    @Assert(groupAfter.resourceId, groupBefore.resourceId)
    @Assert(groupAfter.depth, groupBefore.depth)
    @Assert(groupAfter.isGroup, groupBefore.isGroup)
    @Assert(groupAfter.expanded, groupBefore.expanded)
    @Assert(projection.rowCount(), rowsBefore)

    // A selectable leaf keeps being selectable through the same path.
    let leafKey = "group-0-leaf-0"
    @Assert(projection.rowAt(projection.indexForKey(leafKey)).selectable, true)
    source.rename(leafKey, "改名叶")
    @Assert(projection.refreshContentOnly(), true)
    let leafAfter = projection.rowAt(projection.indexForKey(leafKey))
    @Assert(leafAfter.label, "改名叶")
    @Assert(leafAfter.selectable, true)
}

@Test
func treeContentUpdateDeclaredSelectabilityMismatchRefusesWholeBatch(): Unit {
    let source = TreeContentUpdateSource()
    let projection = contentUpdateProjection(source)
    let leafKey = "group-0-leaf-0"
    let leafBefore = projection.rowAt(projection.indexForKey(leafKey)).label

    // One honest content change plus one declaration that would change the
    // group's interaction semantics. The whole batch must be refused before the
    // honest change is written.
    source.renameBatch(
        ArrayList<String>([leafKey, "group-0"]),
        ArrayList<String>(["乐观写入", "组变可选"]),
        ArrayList<Int64>([TreeContentUpdateSource.DECLARE_NONE, 1]))
    @Assert(projection.refreshContentOnly(), false)
    @Assert(projection.contentRefreshCount(), 0)
    @Assert(projection.rowAt(projection.indexForKey(leafKey)).label, leafBefore)
    @Assert(projection.rowAt(projection.indexForKey("group-0")).selectable, false)

    // The caller falls back to a rebuild, which is how the real semantics and
    // the honest content change both arrive.
    @Assert(projection.rebuild(), true)
    projection.markSourceIndexCurrent()
    @Assert(projection.rowAt(projection.indexForKey(leafKey)).label, "乐观写入")
    let groupAfter = projection.rowAt(projection.indexForKey("group-0"))
    @Assert(groupAfter.label, "组变可选")
    @Assert(groupAfter.selectable, false)
}

@Test
func treeContentUpdateRefusesUnknownKeyAndUnarmedOrRegressedVersion(): Unit {
    let source = TreeContentUpdateSource()
    let projection = contentUpdateProjection(source)
    let before = projection.rowAt(projection.indexForKey("group-0-leaf-0")).label

    // An unknown key is not a content update: nothing is patched.
    source.rename("group-9-leaf-9", "越界")
    @Assert(projection.refreshContentOnly(), false)
    @Assert(projection.contentRefreshCount(), 0)
    @Assert(projection.rowAt(projection.indexForKey("group-0-leaf-0")).label, before)
    let _ = projection.rebuild()
    projection.markSourceIndexCurrent()

    // A source that reports an OLDER version than the applied one cannot
    // describe the difference: refuse instead of regressing the applied version.
    let applied = source.contentVersion()
    source.reportVersion(applied - 1)
    source.rename("group-0-leaf-1", "倒退写入")
    @Assert(projection.refreshContentOnly(), false)
    @Assert(projection.contentRefreshCount(), 0)
    source.reportVersion(-1)
    let _ = projection.rebuild()
    projection.markSourceIndexCurrent()

    // A provider that cannot prove content-only returns None: rebuild.
    source.makeUndescribable()
    @Assert(projection.refreshContentOnly(), false)

    // Without an armed caller index there is no base version to patch from.
    let fresh = TreeContentUpdateSource()
    let unarmed = CjguiComposableUiTreeProjection(fresh)
    unarmed.attachContentUpdateSource(fresh)
    let _ = unarmed.setExpanded("group-0", true)
    fresh.rename("group-0-leaf-0", "未武装")
    @Assert(unarmed.refreshContentOnly(), false)
    @Assert(unarmed.contentRefreshCount(), 0)
}

@Test
func treeSelectedLeafBecomingUnselectablePrunesSelectionAndAnchor(): Unit {
    let source = TreeContentUpdateSource()
    let projection = contentUpdateProjection(source)
    let selection = CjguiComposableUiTreeSelection(projection)
    let leafKey = "group-0-leaf-0"
    selection.click(leafKey, false, false)
    @Assert(selection.isSelected(leafKey), true)
    @Assert(selection.selectedCount(), 1)
    @Assert(selection.anchor(), leafKey)
    @Assert(selection.focus(), leafKey)

    // The owner really takes selectability away. The projection refuses the
    // fast path (declared value disagrees with the live row), so the caller
    // rebuilds and runs the selectability-aware correction.
    source.makeUnselectable(leafKey)
    @Assert(projection.refreshContentOnly(), false)
    @Assert(projection.rebuild(), true)
    projection.markSourceIndexCurrent()
    @Assert(projection.rowAt(projection.indexForKey(leafKey)).selectable, false)
    selection.pruneSelectionToSelectable()
    @Assert(selection.isSelected(leafKey), false)
    @Assert(selection.selectedCount(), 0)
    @Assert(selection.anchor(), "")
    // The row still projects, so the user's row position (focus) is kept: a
    // non-selectable row is a legitimate focus target for expand/collapse.
    @Assert(projection.indexForKey(leafKey) >= 0, true)
    @Assert(selection.focus(), leafKey)
}

// Public collection-workspace contracts (DS51 §12 B2/B3): the existing view
// snapshot through ONE entry, command identity derived from the canonical scope,
// and reveal addressed to ONE accepted mount. No application, native module or
// window is used.
package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class WorkspaceTestSource <: CjguiComposableUiVariableHeightListSource {
    private let items: Array<CjguiComposableUiVariableHeightListItem>

    init(items: Array<CjguiComposableUiVariableHeightListItem>) {
        this.items = items
    }

    public func itemCount(): Int64 {
        return items.size
    }

    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= items.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        return items[index]
    }

    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < items.size) {
            if (items[index].key == key) {
                return index
            }
            index += 1
        }
        return -1
    }

    public func measurementGeneration(): Int64 {
        return 0
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(980000, "workspace-test-row", item.title,
            CjguiComposableUiStyle(fixedHeight: 30),
            identity: Some(CjguiComposableUiIdentityScope("workspace-local-list").child(item.key).local("row")))
    }
}

private func workspaceRows(): Array<CjguiComposableUiVariableHeightListItem> {
    let items = ArrayList<CjguiComposableUiVariableHeightListItem>()
    var index: Int64 = 0
    while (index < 6) {
        items.add(CjguiComposableUiVariableHeightListItem("row_${index}", index, "规则 ${index}", 0,
            estimatedHeight: 30))
        index += 1
    }
    return items.toArray()
}

private func workspaceColumn(key: String, title: String, width: Int64): CjguiComposableUiTableColumn {
    return CjguiComposableUiTableColumn(key, title, key, width, "SORT_${key}",
        { item => item.title }, { a, b => 0 }, minWidth: 56, maxWidth: 480)
}

private func workspaceTableStyle(): CjguiComposableUiTableStyle {
    return CjguiComposableUiTableStyle(30, 30, 6, 11.5, "PingFang SC",
        CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0), CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0),
        CjguiComposableUiColor(0.96, 0.96, 0.96, 1.0), CjguiComposableUiColor(0.8, 0.8, 0.8, 1.0),
        CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0), CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
        CjguiComposableUiColor(0.4, 0.4, 0.4, 1.0), CjguiComposableUiColor(0.2, 0.4, 0.8, 1.0))
}

private func workspaceCollection(columns: Array<CjguiComposableUiTableColumn>,
    key: String): CjguiGeneratedUiCollection {
    let source = WorkspaceTestSource(workspaceRows())
    let filtered = CjguiComposableUiFilteredListSource(source, { item => item.title })
    let table = CjguiComposableUiTableSource(filtered, key, columns, workspaceTableStyle())
    return CjguiGeneratedUiCollection("workspaceRows", "workspaceRowList", source, table,
        CjguiComposableUiCollectionSelection())
}

private func workspaceStandardColumns(): Array<CjguiComposableUiTableColumn> {
    return [workspaceColumn("name", "名称", 0), workspaceColumn("status", "状态", 68),
        workspaceColumn("detail", "详情", 96)]
}

private func workspaceMount(collection: CjguiGeneratedUiCollection,
    scope: CjguiComposableUiIdentityScope, instanceKey: String): CjguiComposableUiNode {
    let elements = ArrayList<CjguiCompositeElementBinding>()
    elements.add(CjguiCompositeElementBinding("viewport", CJGUI_COMPOSITE_ELEMENT_CONTAINER,
        930001, "${instanceKey}-viewport", "视口", instanceKey: instanceKey, instanceIncarnation: 1))
    elements.add(CjguiCompositeElementBinding("content", CJGUI_COMPOSITE_ELEMENT_CONTAINER,
        930002, "${instanceKey}-content", "内容", instanceKey: instanceKey, instanceIncarnation: 1))
    let properties = HashMap<String, String>()
    properties.add("collection", collection.key)
    properties.add("presentation", "table")
    let keys = HashSet<String>()
    keys.add(instanceKey)
    return collection.buildComposite(CjguiCompositeBuildContext(instanceKey, properties, elements,
        holderScope: Some(scope), instanceIncarnation: 1, acceptedBuild: true, acceptedSceneKeys: keys))
}

@Test
func collectionWorkspaceSaveModifyRestoreUsesThePublicSnapshot(): Unit {
    let collection = workspaceCollection(workspaceStandardColumns(), "workspace-view-table")
    let view = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let modes = HashMap<String, String>()
    modes.add("list", "list")
    modes.add("table", "table")
    let workspace = CjguiCollectionWorkspace(collection, view,
        CjguiComposableUiIdentityScope("workspace-a"), title: "测试集合", modePresentations: modes)
    @Assert(workspace.setMode("table"), true)
    @Assert(workspace.presentationForMode(workspace.viewState().mode()), "table")
    @Assert(workspace.toggleSort("status"), true)
    @Assert(workspace.projectBusinessQuery("规则 1"), true)
    @Assert(workspace.setColumnWidth("status", 90), true)
    @Assert(workspace.setColumnVisible("detail", false), true)
    let saved = workspace.encodedSnapshot()
    @Assert(saved.size > 0, true)

    // Change every section, then restore the saved text through the SAME entry.
    @Assert(workspace.projectBusinessQuery("规则 2"), true)
    @Assert(workspace.toggleSort("name"), true)
    @Assert(workspace.setColumnWidth("status", 120), true)
    @Assert(workspace.setColumnVisible("detail", true), true)
    let restored = workspace.restoreEncoded(saved)
    @Assert(restored.applied, true)
    @Assert(restored.reason, "view_restored")
    @Assert(workspace.viewState().query(), "规则 1")
    @Assert(workspace.viewState().sortColumnKey(), "status")
    @Assert(workspace.viewState().mode(), "table")
    @Assert(workspace.viewState().tableLayout().width("status"), 90)
    @Assert(workspace.viewState().tableLayout().isVisible("detail"), false)
    @Assert(workspace.status().size > 0, true)
    @Assert(workspace.encodedSnapshot(), saved)
}

@Test
func collectionWorkspaceInvalidSnapshotKeepsTheCurrentView(): Unit {
    let collection = workspaceCollection(workspaceStandardColumns(), "workspace-invalid-table")
    let view = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let workspace = CjguiCollectionWorkspace(collection, view,
        CjguiComposableUiIdentityScope("workspace-b"))
    @Assert(workspace.projectBusinessQuery("alpha"), true)
    let before = workspace.encodedSnapshot()
    let failed = workspace.restoreEncoded("CJGUI_COLLECTION_VIEW 9 | MODE 6C697374")
    @Assert(failed.applied, false)
    @Assert(failed.reason, "unsupported_view_version")
    @Assert(workspace.encodedSnapshot(), before)
    // Reset still goes through the ONE validated restore.
    let reset = workspace.resetView()
    @Assert(reset.applied, true)
    @Assert(workspace.viewState().query(), "")
}

@Test
func collectionWorkspaceColumnsSurviveADeclarationChange(): Unit {
    let sourceColumns = ArrayList<CjguiComposableUiTableColumn>()
    sourceColumns.add(workspaceColumn("name", "名称", 0))
    sourceColumns.add(workspaceColumn("legacy", "旧列", 90))
    let source = workspaceCollection(sourceColumns.toArray(), "workspace-old-columns")
    let sourceView = CjguiComposableUiCollectionViewState(source.table, ["list", "table"], "list")
    let sourceWorkspace = CjguiCollectionWorkspace(source, sourceView,
        CjguiComposableUiIdentityScope("workspace-c"))
    @Assert(sourceWorkspace.setColumnWidth("legacy", 120), true)
    @Assert(sourceWorkspace.toggleSort("legacy"), true)
    let saved = sourceWorkspace.encodedSnapshot()

    let target = workspaceCollection(workspaceStandardColumns(), "workspace-new-columns")
    let targetView = CjguiComposableUiCollectionViewState(target.table, ["list", "table"], "list")
    let targetWorkspace = CjguiCollectionWorkspace(target, targetView,
        CjguiComposableUiIdentityScope("workspace-d"))
    let restored = targetWorkspace.restoreEncoded(saved)
    @Assert(restored.applied, true)
    @Assert(targetView.tableLayout().columnKeys(), ArrayList<String>(["name", "status", "detail"]))
    @Assert(targetView.sortColumnKey(), "")
    @Assert(targetWorkspace.status().contains("忽略"), true)
}

@Test
func collectionWorkspaceCommandIdentityAndAvailabilityAreReal(): Unit {
    let collection = workspaceCollection(workspaceStandardColumns(), "workspace-command-table")
    let view = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let first = CjguiCollectionWorkspace(collection, view,
        CjguiComposableUiIdentityScope("workspace-command-a"))
    let second = CjguiCollectionWorkspace(collection, view,
        CjguiComposableUiIdentityScope("workspace-command-b"))
    let saveId = first.commandId(CJGUI_COLLECTION_ACTION_SAVE_VIEW)
    @Assert(first.ownsCommand(saveId), true)
    @Assert(second.ownsCommand(saveId), false)
    @Assert(second.commandId(CJGUI_COLLECTION_ACTION_SAVE_VIEW) != saveId, true)
    // Restore is disabled until the application really has a snapshot.
    let none = first.commandDeclarations("")
    @Assert(none.size, 3)
    for (command in none) {
        if (command.id == first.commandId(CJGUI_COLLECTION_ACTION_RESTORE_VIEW)) {
            @Assert(command.isEnabled, false)
        }
    }
    let saved = first.encodedSnapshot()
    let withSnapshot = first.commandDeclarations(saved)
    for (command in withSnapshot) {
        if (command.id == first.commandId(CJGUI_COLLECTION_ACTION_RESTORE_VIEW)) {
            @Assert(command.isEnabled, true)
        }
    }
}

@Test
func collectionWorkspaceRevealsOnlyTheNamedAcceptedMount(): Unit {
    let collection = workspaceCollection(workspaceStandardColumns(), "workspace-reveal-table")
    let view = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let scope = CjguiComposableUiIdentityScope("workspace-reveal-region")
    let workspace = CjguiCollectionWorkspace(collection, view, scope)
    let node = workspaceMount(collection, scope, "table")
    let accepted = collection.acceptedView(scope, "table").getOrThrow()
    let rows = match (node.variableHeightListSource()) {
        case Some(source) => (source as CjguiGeneratedCollectionRows).getOrThrow()
        case None => throw Exception("workspace mount lost its rows")
    }
    accepted.listState().updateVariableMaterializedRange(rows, 30, 0, 60, 2)
    accepted.viewport.stageExtents(210, 60, 0)
    accepted.viewport.commitStagedExtents()
    // The workspace addresses the accepted mount by region scope + instance key.
    @Assert(workspace.revealIn(scope, "table", "row_4"), true)
    @Assert(accepted.scrollOffset(), 150)
    // A missing instance refuses instead of moving the named one.
    @Assert(workspace.revealIn(scope, "ghost", "row_1"), false)
    @Assert(accepted.scrollOffset(), 150)
}

private class WorkspaceTestStore {
    public var value: String = ""
    public func save(snapshot: String): Bool {
        value = snapshot
        return true
    }
    public func load(): String {
        return value
    }
}

private func workspaceLayoutEvent(node: CjguiComposableUiNode, kind: Int64,
    text: String): CjguiComposableUiEvent {
    let rect = CjguiComposableUiRect(0, 0, 120, 28)
    let layout = CjguiComposableUiLayoutNode(node, rect, rect)
    return CjguiComposableUiEvent(layout, kind, text, 0, 0, 1)
}

private func workspaceChildWithAction(node: CjguiComposableUiNode,
    action: String): ?CjguiComposableUiNode {
    for (child in node.children()) {
        if (child.actionName == action || child.semanticId.endsWith(action)) { return Some(child) }
    }
    return None
}

private func workspaceChildWithSemantic(node: CjguiComposableUiNode,
    suffix: String): ?CjguiComposableUiNode {
    for (child in node.children()) {
        if (child.semanticId.endsWith(suffix)) { return Some(child) }
    }
    return None
}

@Test
func collectionWorkspaceCommandBarAndColumnEditorAreReusableAndScoped(): Unit {
    let collection = workspaceCollection(workspaceStandardColumns(), "workspace-entry-table")
    let view = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let modes = HashMap<String, String>()
    modes.add("table", "table")
    let workspaceA = CjguiCollectionWorkspace(collection, view,
        CjguiComposableUiIdentityScope("workspace-actions-a"), title: "A", modePresentations: modes)
    let workspaceB = CjguiCollectionWorkspace(collection, view,
        CjguiComposableUiIdentityScope("workspace-actions-b"), title: "B", modePresentations: modes)
    let bar = workspaceA.buildActionBar(960000, CjguiComposableUiStyle(gap: 4),
        "", CjguiComposableUiStyle(fixedHeight: 28))
    @Assert(bar.children().size, 3)
    let saveNode = bar.children()[0]
    let saveEvent = workspaceLayoutEvent(saveNode, 27, "")
    @Assert(workspaceA.actionForEvent(saveEvent), Some(CJGUI_COLLECTION_ACTION_SAVE_VIEW))
    // Another workspace in the same window cannot claim this bar.
    @Assert(workspaceB.actionForEvent(saveEvent).isNone(), true)

    let store = WorkspaceTestStore()
    let saved = workspaceA.executeAction(CJGUI_COLLECTION_ACTION_SAVE_VIEW,
        { value => store.save(value) }, { => store.load() })
    @Assert(saved.applied, true)
    @Assert(store.value.size > 0, true)
    @Assert(workspaceA.executeAction(CJGUI_COLLECTION_ACTION_RESTORE_VIEW,
        { _ => false }, { => "" }).reason, "view_not_saved")

    // Column controls operate on the SAME layout the header/content use.
    let layout = view.tableLayout()
    let editor = workspaceA.buildColumnEditor(970000, CjguiComposableUiStyle(gap: 2),
        CjguiComposableUiStyle(fixedHeight: 26))
    @Assert(layout.isVisible("status"), true)
    let toggle = match (workspaceChildWithAction(editor, "COLLECTION_COLUMN_TOGGLE")) {
        case Some(value) => value
        case None => throw Exception("column toggle missing")
    }
    // The first toggle names the first declared column; verify through its key.
    let firstKey = layout.declaredKeys()[0]
    @Assert(toggle.semanticId, "${workspaceA.semanticPrefix()}-column-toggle-${firstKey}")
    @Assert(workspaceA.applyColumnEvent(workspaceLayoutEvent(toggle, 27, "")), Some(true))
    @Assert(layout.isVisible(firstKey), false)
    @Assert(workspaceA.applyColumnEvent(workspaceLayoutEvent(toggle, 27, "")), Some(true))
    @Assert(layout.isVisible(firstKey), true)

    // Width nudging needs a real declared width; the first column is auto-sized.
    let statusKey = layout.declaredKeys()[1]
    let beforeWidth = layout.width(statusKey)
    let wide = match (workspaceChildWithSemantic(editor, "-column-wide-${statusKey}")) {
        case Some(value) => value
        case None => throw Exception("column wide missing")
    }
    @Assert(workspaceA.applyColumnEvent(workspaceLayoutEvent(wide, 27, "")), Some(true))
    @Assert(layout.width(statusKey) > beforeWidth, true)
    let reset = match (workspaceChildWithAction(editor, "COLLECTION_COLUMN_RESET")) {
        case Some(value) => value
        case None => throw Exception("column reset missing")
    }
    @Assert(workspaceA.applyColumnEvent(workspaceLayoutEvent(reset, 27, "")), Some(true))
    @Assert(layout.width(statusKey), beforeWidth)
    // A different workspace's column event is not ours.
    @Assert(workspaceB.applyColumnEvent(workspaceLayoutEvent(toggle, 27, "")).isNone(), true)
}

private class WorkspaceSaveStore {
    public var calls: Int64 = 0
    public var value: String = ""
    public func save(snapshot: String): Bool {
        calls += 1
        value = snapshot
        return true
    }
    public func load(): String {
        return value
    }
}

private class WorkspaceAuthorityState {
    public var query: String = ""
    public var sortKey: String = ""
    public var ascending: Bool = true
    public var reject: Bool = false
    public var applies: Int64 = 0
    public func apply(q: String, key: String, asc: Bool): Bool {
        applies += 1
        if (reject) { return false }
        query = q; sortKey = key; ascending = asc
        return true
    }
}

private func workspaceEvent(node: CjguiComposableUiNode, kind: Int64): CjguiComposableUiEvent {
    let rect = CjguiComposableUiRect(0, 0, 120, 28)
    return CjguiComposableUiEvent(CjguiComposableUiLayoutNode(node, rect, rect), kind, "", 0, 0, 1)
}

private func workspaceFind(node: CjguiComposableUiNode, semantic: String): ?CjguiComposableUiNode {
    if (node.semanticId == semantic) { return Some(node) }
    for (child in node.children()) {
        if (let Some(found) <- workspaceFind(child, semantic)) { return Some(found) }
    }
    return None
}

@Test
func workspaceActionsNeedActivationAndRunExactlyOnce(): Unit {
    let collection = workspaceCollection(workspaceStandardColumns(), "workspace-once-table")
    let view = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let modes = HashMap<String, String>()
    modes.add("table", "table")
    let workspace = CjguiCollectionWorkspace(collection, view,
        CjguiComposableUiIdentityScope("workspace-once"), modePresentations: modes)
    let bar = workspace.buildActionBar(980000, CjguiComposableUiStyle(gap: 4), "saved",
        CjguiComposableUiStyle(fixedHeight: 28))
    let saveNode = bar.children()[0]
    let activate = workspaceEvent(saveNode, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE)
    // FOCUS/scroll/hover on the SAME node do not execute anything.
    @Assert(workspace.actionForEvent(workspaceEvent(saveNode, 31)).isNone(), true)
    @Assert(workspace.actionForEvent(workspaceEvent(saveNode, 30)).isNone(), true)
    @Assert(workspace.actionForEvent(workspaceEvent(saveNode, 43)).isNone(), true)
    @Assert(workspace.actionForEvent(activate), Some(CJGUI_COLLECTION_ACTION_SAVE_VIEW))
    let store = WorkspaceSaveStore()
    for (_ in 0..2) {
        let action = workspace.actionForEvent(activate).getOrThrow()
        let outcome = workspace.executeAction(action, { value => store.save(value) },
            { => store.load() })
        @Assert(outcome.applied, true)
    }
    // Two real activations execute twice; the shared entry never time-debounces.
    @Assert(store.calls, 2)

    let editor = workspace.buildColumnEditor(981000, CjguiComposableUiStyle(gap: 2),
        CjguiComposableUiStyle(fixedHeight: 26))
    let wide = match (workspaceFind(editor, "${workspace.semanticPrefix()}-column-wide-status")) {
        case Some(value) => value
        case None => throw Exception("wide control missing")
    }
    let layout = view.tableLayout()
    let start = layout.width("status")
    @Assert(workspace.applyColumnEvent(workspaceEvent(wide, 31)).isNone(), true)
    @Assert(layout.width("status"), start)
    let wideActivate = workspaceEvent(wide, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE)
    @Assert(workspace.applyColumnEvent(wideActivate), Some(true))
    @Assert(layout.width("status"), start + 16)
    @Assert(workspace.applyColumnEvent(wideActivate), Some(true))
    @Assert(layout.width("status"), start + 32)
}

@Test
func workspaceNestedScopesAndUnknownNodesDoNotCrossWrite(): Unit {
    let collection = workspaceCollection(workspaceStandardColumns(), "workspace-nested-table")
    let view = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let parentWorkspace = CjguiCollectionWorkspace(collection, view,
        CjguiComposableUiIdentityScope("a"))
    let childScope = CjguiComposableUiIdentityScope("a").child("b")
    let childView = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let childWorkspace = CjguiCollectionWorkspace(collection, childView, childScope)
    // The child's semantic prefix contains the parent's machine prefix; the
    // accepted node identity must still keep them apart.
    @Assert(childWorkspace.semanticPrefix().startsWith(parentWorkspace.semanticPrefix()), true)
    let parentBar = parentWorkspace.buildActionBar(982000, CjguiComposableUiStyle(gap: 2),
        "saved", CjguiComposableUiStyle(fixedHeight: 26))
    let childBar = childWorkspace.buildActionBar(983000, CjguiComposableUiStyle(gap: 2),
        "saved", CjguiComposableUiStyle(fixedHeight: 26))
    let childSave = workspaceEvent(childBar.children()[0], CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE)
    @Assert(parentWorkspace.actionForEvent(childSave).isNone(), true)
    @Assert(childWorkspace.actionForEvent(childSave), Some(CJGUI_COLLECTION_ACTION_SAVE_VIEW))
    let parentSave = workspaceEvent(parentBar.children()[0], CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE)
    @Assert(childWorkspace.actionForEvent(parentSave).isNone(), true)
    // A foreign node that copies both the prefix and action name has no built
    // identity and is rejected with zero state change.
    let copiedNode = cjguiComposableButton(984000,
        "${parentWorkspace.semanticPrefix()}-save-view-copy", "冒充", CJGUI_COLLECTION_ACTION_SAVE_VIEW,
        -1, CjguiComposableUiStyle(fixedHeight: 26))
    @Assert(parentWorkspace.actionForEvent(workspaceEvent(copiedNode, 27)).isNone(), true)
    // Unknown column action name on an unknown node cannot reach a column move.
    let editor = parentWorkspace.buildColumnEditor(985000, CjguiComposableUiStyle(gap: 1),
        CjguiComposableUiStyle(fixedHeight: 26))
    let copiedColumn = cjguiComposableButton(986000,
        "${parentWorkspace.semanticPrefix()}-column-toggle-name-extra", "未知",
        CJGUI_COLLECTION_COLUMN_ACTION_TOGGLE + "junk", 1, CjguiComposableUiStyle(fixedHeight: 26))
    @Assert(parentWorkspace.applyColumnEvent(workspaceEvent(copiedColumn, 27)).isNone(), true)
    let layout = view.tableLayout()
    let beforeWidth = layout.width("status")
    @Assert(parentWorkspace.applyColumnEvent(workspaceEvent(copiedColumn, 27)).isNone(), true)
    @Assert(layout.width("status"), beforeWidth)
    @Assert(parentWorkspace.applyColumnEvent(workspaceEvent(editor.children()[0], 27)).isSome(), true)
}

@Test
func workspaceRestoreUsesOwnerAuthorityAndRejectsBeforeMutation(): Unit {
    let collection = workspaceCollection(workspaceStandardColumns(), "workspace-authority-table")
    let view = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let owner = WorkspaceAuthorityState()
    let modes = HashMap<String, String>()
    modes.add("list", "list")
    modes.add("table", "table")
    let workspace = CjguiCollectionWorkspace(collection, view,
        CjguiComposableUiIdentityScope("workspace-authority"), modePresentations: modes,
        viewAuthority: { query, key, asc => owner.apply(query, key, asc) })
    @Assert(workspace.setMode("table"), true)
    @Assert(workspace.toggleSort("status"), true)
    @Assert(workspace.projectBusinessQuery("规则 1"), true)
    let saved = workspace.encodedSnapshot()
    // Change BOTH the owner and the projection; restore must return to the
    // saved authority values, not just the view copy.
    @Assert(workspace.projectBusinessQuery("规则 2"), true)
    @Assert(workspace.toggleSort("name"), true)
    let restore = workspace.executeAction(CJGUI_COLLECTION_ACTION_RESTORE_VIEW,
        { _ => true }, { => saved })
    @Assert(restore.applied, true)
    @Assert(owner.applies, 1)
    @Assert(owner.query, "规则 1")
    @Assert(owner.sortKey, "status")
    @Assert(view.query(), "规则 1")
    @Assert(view.sortColumnKey(), "status")
    // A subsequent ordinary projection from the owner keeps the restored value.
    @Assert(workspace.projectBusinessQuery(owner.query), false)
    // A refused authority leaves owner, view, mode and columns untouched.
    let beforeQuery = view.query()
    owner.reject = true
    let refused = workspace.executeAction(CJGUI_COLLECTION_ACTION_RESTORE_VIEW,
        { _ => true }, { => saved })
    @Assert(refused.applied, false)
    @Assert(refused.reason, "view_authority_rejected")
    @Assert(view.query(), beforeQuery)
    @Assert(owner.query, beforeQuery)
    owner.reject = false
    // Reset goes through the same owner gate and restores the declared defaults.
    let reset = workspace.executeAction(CJGUI_COLLECTION_ACTION_RESET_VIEW,
        { _ => true }, { => "" })
    @Assert(reset.applied, true)
    @Assert(owner.query, "")
    @Assert(owner.sortKey, "")
    @Assert(view.query(), "")
}

@Test
func workspaceCommandReferencesResolveToBuiltActionNodes(): Unit {
    let collection = workspaceCollection(workspaceStandardColumns(), "workspace-command-table")
    let view = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let scope = CjguiComposableUiIdentityScope("cmd-root")
    let workspace = CjguiCollectionWorkspace(collection, view, scope)
    let bar = workspace.buildActionBar(990000, CjguiComposableUiStyle(gap: 2), "saved",
        CjguiComposableUiStyle(fixedHeight: 26))
    var index: Int64 = 0
    for (entry in CjguiCollectionWorkspace.entries()) {
        let node = bar.children()[index]
        let built = match (node.scopedIdentity()) {
            case Some(value) => value.canonicalKey()
            case None => throw Exception("action node has no scoped identity")
        }
        let reference = match (workspace.nodeReference(entry.action).scopedIdentity()) {
            case Some(value) => value.canonicalKey()
            case None => throw Exception("command reference has no scoped identity")
        }
        @Assert(built, reference)
        @Assert(node.semanticId, "${workspace.semanticPrefix()}-${entry.suffix}")
        index += 1
    }
    // A nested legal scope resolves to a different identity even though its
    // semantic prefix contains the parent's.
    let childView = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let child = CjguiCollectionWorkspace(collection, childView, scope.child("b"))
    @Assert(child.semanticPrefix().startsWith(workspace.semanticPrefix()), true)
    let parentRef = workspace.nodeReference(CJGUI_COLLECTION_ACTION_SAVE_VIEW).scopedIdentity().getOrThrow()
    let childRef = child.nodeReference(CJGUI_COLLECTION_ACTION_SAVE_VIEW).scopedIdentity().getOrThrow()
    @Assert(parentRef.canonicalKey() != childRef.canonicalKey(), true)
}

@Test
func workspaceDisabledCommandsAndColumnReasonsRefuseWithoutWriting(): Unit {
    let collection = workspaceCollection(workspaceStandardColumns(), "workspace-disabled-table")
    let view = CjguiComposableUiCollectionViewState(collection.table, ["list", "table"], "list")
    let workspace = CjguiCollectionWorkspace(collection, view,
        CjguiComposableUiIdentityScope("workspace-disabled"))
    // No stored snapshot: restore's command/button is disabled from the SAME fact.
    let declarations = workspace.commandDeclarations("")
    var restoreEnabled = true
    for (command in declarations) {
        if (command.id == workspace.commandId(CJGUI_COLLECTION_ACTION_RESTORE_VIEW)) {
            restoreEnabled = command.isEnabled
        }
    }
    @Assert(restoreEnabled, false)
    let bar = workspace.buildActionBar(991000, CjguiComposableUiStyle(gap: 2), "",
        CjguiComposableUiStyle(fixedHeight: 26))
    let restoreNode = bar.children()[1]
    @Assert(workspace.actionForEvent(workspaceEvent(restoreNode,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE)).isNone(), true)
    let outcome = workspace.executeAction(CJGUI_COLLECTION_ACTION_RESTORE_VIEW,
        { _ => true }, { => "" })
    @Assert(outcome.applied, false)
    @Assert(outcome.reason, "view_not_saved")

    // Column reasons come from the live layout: an auto-width column cannot be
    // nudged, and the last visible column cannot be hidden.
    let layout = view.tableLayout()
    @Assert(layout.width("name"), 0)
    let editor = workspace.buildColumnEditor(992000, CjguiComposableUiStyle(gap: 1),
        CjguiComposableUiStyle(fixedHeight: 26))
    let narrowAuto = match (workspaceFind(editor,
        "${workspace.semanticPrefix()}-column-narrow-name")) {
        case Some(value) => value
        case None => throw Exception("narrow control missing")
    }
    let narrowRect = CjguiComposableUiRect(0, 0, 120, 26)
    @Assert(CjguiComposableUiLayoutNode(narrowAuto, narrowRect, narrowRect).isEnabled, false)
    @Assert(workspace.applyColumnEvent(workspaceEvent(narrowAuto,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE)).isNone(), true)
    @Assert(workspace.setColumnVisible("status", false), true)
    @Assert(workspace.setColumnVisible("detail", false), true)
    let editor2 = workspace.buildColumnEditor(993000, CjguiComposableUiStyle(gap: 1),
        CjguiComposableUiStyle(fixedHeight: 26))
    let toggleName = match (workspaceFind(editor2,
        "${workspace.semanticPrefix()}-column-toggle-name")) {
        case Some(value) => value
        case None => throw Exception("toggle control missing")
    }
    let toggleRect = CjguiComposableUiRect(0, 0, 120, 26)
    @Assert(CjguiComposableUiLayoutNode(toggleName, toggleRect, toggleRect).isEnabled, false)
    @Assert(workspace.applyColumnEvent(workspaceEvent(toggleName,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE)).isNone(), true)
    @Assert(layout.isVisible("name"), true)
}

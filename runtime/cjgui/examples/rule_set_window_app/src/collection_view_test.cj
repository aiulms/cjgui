// Collection-view preset acceptance: human save/switch, external switch,
// owner draft and stable-key selection retention, and preference reload in a
// new controller over the same document/preference files.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

private func presetCreateRule(domain: CjguiRuleSetEditingDomain, label: String,
    retention: Int64, requestId: String): Int64 {
    let result = domain.executeFromExternal(CjguiRuleSetInvocationFactory.create(domain.snapshot().version,
        label, true, retention, "cache", requestId))
    if (!result.applied) {
        throw IllegalArgumentException("preset test rule create failed: ${result.reason}")
    }
    return domain.selectedRecordId()
}

private func presetScene(controller: CjguiRuleSetComposableController,
    version: Int64): CjguiComposableUiScene {
    let root = controller.buildUi()
    let rect = CjguiComposableUiRect(0, 0, 980, 620)
    let registry = CjguiComposableUiIdentityRegistry()
    if (!registry.beginCandidate()) {
        return CjguiComposableUiLayoutEngine.layout(root, rect, version)
    }
    let _ = registry.resolveCandidate(root)
    let _ = registry.replaceCandidateRoot(root)
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, rect, version,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry)).scene
    let _ = registry.prepareCandidate()
    return scene
}

private func presetClick(controller: CjguiRuleSetComposableController,
    node: CjguiComposableUiLayoutNode, modifiers!: Int64 = 0): Bool {
    return controller.applyUiEvent(CjguiComposableUiEvent(node, 27, "", 0, 0,
        controller.uiSceneVersion(), modifierFlags: modifiers)).didApply
}

private func presetText(controller: CjguiRuleSetComposableController,
    node: CjguiComposableUiLayoutNode, text: String): Bool {
    return controller.applyUiEvent(CjguiComposableUiEvent(node, 28, text, 0, 0,
        controller.uiSceneVersion())).didApply
}

private func presetTestSnapshot(query: String): CjguiComposableUiCollectionViewSnapshot {
    return CjguiComposableUiCollectionViewSnapshot("list", query, "", true,
        ArrayList<CjguiComposableUiTableColumnState>([
            CjguiComposableUiTableColumnState("name", 0, true)
        ]))
}

private func presetLargeQuery(byteCount: Int64): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < byteCount) {
        builder.append("q")
        index += 1
    }
    return builder.toString()
}

private func presetNodeById(scene: CjguiComposableUiScene,
    nodeId: Int64): CjguiComposableUiLayoutNode {
    let node = scene.nodeForId(nodeId)
    if (node.nodeId != nodeId) {
        throw IllegalArgumentException("preset test node ${nodeId} missing")
    }
    return node
}

private func presetNodeByAction(scene: CjguiComposableUiScene,
    actionName: String): ?CjguiComposableUiLayoutNode {
    for (node in scene.nodes()) {
        if (node.actionName == actionName) {
            return Some(node)
        }
    }
    return None
}

private func presetNodeBySemantic(scene: CjguiComposableUiScene,
    semanticId: String): ?CjguiComposableUiLayoutNode {
    for (node in scene.nodes()) {
        if (node.semanticId == semanticId) {
            return Some(node)
        }
    }
    return None
}

private func presetHasAction(scene: CjguiComposableUiScene, actionName: String): Bool {
    match (presetNodeByAction(scene, actionName)) {
        case Some(_) => true
        case None => false
    }
}

private func presetSaveAs(controller: CjguiRuleSetComposableController,
    version: Int64, name: String): Bool {
    var scene = presetScene(controller, version)
    if (!presetClick(controller, presetNodeById(scene, 205))) {
        return false
    }
    scene = presetScene(controller, version + 1)
    if (!presetText(controller, presetNodeById(scene, 591), name)) {
        return false
    }
    scene = presetScene(controller, version + 2)
    return presetClick(controller, presetNodeById(scene, 592))
}

private func presetSelect(controller: CjguiRuleSetComposableController,
    version: Int64, index: Int64): Bool {
    var scene = presetScene(controller, version)
    if (!presetHasAction(scene, "SELECT_COLLECTION_VIEW")) {
        if (!presetClick(controller, presetNodeById(scene, 205))) {
            return false
        }
        scene = presetScene(controller, version + 1)
    }
    if (let Some(node) <- presetNodeBySemantic(scene, "view-preset-${index}")) {
        return presetClick(controller, node)
    }
    return false
}

private func presetSavePreferences(controller: CjguiRuleSetComposableController,
    version: Int64): Bool {
    var scene = presetScene(controller, version)
    if (!presetHasAction(scene, "SAVE_COLLECTION_VIEW_PREFERENCES")) {
        if (!presetClick(controller, presetNodeById(scene, 205))) {
            return false
        }
        scene = presetScene(controller, version + 1)
    }
    return presetClick(controller, presetNodeById(scene, 594))
}

private func presetContextField(domain: CjguiRuleSetEditingDomain, name: String): String {
    for (resource in domain.contextSnapshot().resources) {
        if (resource.id == CjguiRuleSetEditingDomain.ruleSetResourceId) {
            for (field in resource.fields) {
                if (field.name == name) {
                    return field.value.displayText()
                }
            }
        }
    }
    return ""
}

@Test
func collectionViewPresetsSwitchWithoutTouchingDraftOrSelection(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    presetCreateRule(domain, "Alpha", 10, "preset-rule-1")
    let selectedId = presetCreateRule(domain, "Beta", 20, "preset-rule-2")
    presetCreateRule(domain, "Gamma", 30, "preset-rule-3")
    @Assert(domain.selectCollectionItemFromHuman(selectedId).applied, true)
    @Assert(domain.editSelectedLabelFromHuman("草稿 Beta", 0, 0).applied, true)
    let controller = CjguiRuleSetComposableController(domain)
    let view = controller.collectionViewState()
    let layout = controller.tableColumnLayout()

    // View A: table mode, filter "a", retention descending, fixed width,
    // excluded hidden. These are the same public objects the menus mutate.
    var scene = presetScene(controller, 1)
    @Assert(presetClick(controller, presetNodeById(scene, 200)), true)
    scene = presetScene(controller, 2)
    // Click the selected record's table cell once: this populates the shared
    // collection selection, which later preset switches must not clear.
    if (let Some(rowNode) <- presetNodeBySemantic(scene,
        "rule-set-table-cell-rule_${selectedId}-name")) {
        @Assert(presetClick(controller, rowNode), true)
    }
    @Assert(controller.collectionSelectionSnapshot().keys.size, 1)
    scene = presetScene(controller, 3)
    @Assert(presetText(controller, presetNodeById(scene, 24), "a"), true)
    scene = presetScene(controller, 3)
    if (let Some(sortNode) <- presetNodeByAction(scene, CjguiRuleSetTableColumns.sortRetentionAction)) {
        @Assert(presetClick(controller, sortNode), true)
        scene = presetScene(controller, 4)
        if (let Some(sortNodeAgain) <- presetNodeByAction(scene,
            CjguiRuleSetTableColumns.sortRetentionAction)) {
            @Assert(presetClick(controller, sortNodeAgain), true)
        }
    }
    @Assert(view.sortColumnKey(), "retention")
    @Assert(view.sortAscending(), false)
    @Assert(layout.setWidth("retention", 120), true)
    @Assert(layout.setVisible("excluded", false), true)
    @Assert(presetSaveAs(controller, 5, "A"), true)
    @Assert(controller.viewPreferencesStore().names(), ArrayList<String>(["A"]))
    let snapshotA = view.encodedSnapshot()

    // View B: list mode, filter "Beta", no sort, excluded visible.
    scene = presetScene(controller, 8)
    @Assert(presetClick(controller, presetNodeById(scene, 200)), true)
    @Assert(view.clearSort(), true)
    scene = presetScene(controller, 9)
    @Assert(presetText(controller, presetNodeById(scene, 24), "Beta"), true)
    @Assert(layout.setVisible("excluded", true), true)
    @Assert(layout.setWidth("retention", 90), true)
    @Assert(presetSaveAs(controller, 10, "B"), true)
    @Assert(controller.viewPreferencesStore().names(), ArrayList<String>(["A", "B"]))
    @Assert(controller.viewPreferencesStore().activeName(), "B")

    // Switch back to A: the exact saved target state is restored, while the
    // owner's unapplied draft and selected stable key are untouched.
    @Assert(presetSelect(controller, 13, 0), true)
    @Assert(view.mode(), "table")
    @Assert(view.query(), "a")
    @Assert(view.sortColumnKey(), "retention")
    @Assert(view.sortAscending(), false)
    @Assert(layout.width("retention"), 120)
    @Assert(layout.isVisible("excluded"), false)
    @Assert(view.encodedSnapshot(), snapshotA)
    @Assert(domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "草稿 Beta")
    @Assert(domain.selectedRecordId(), selectedId)
    @Assert(controller.collectionSelectionSnapshot().keys.size, 1)

    // Switch to B: list mode/filter are restored without a business Apply or
    // Cancel, and the selected key stays selected.
    @Assert(presetSelect(controller, 16, 1), true)
    @Assert(view.mode(), "list")
    @Assert(view.query(), "Beta")
    @Assert(view.sortColumnKey(), "")
    @Assert(layout.width("retention"), 90)
    @Assert(layout.isVisible("excluded"), true)
    @Assert(domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "草稿 Beta")
    @Assert(domain.selectedRecordId(), selectedId)
    let selectedKeys = controller.collectionSelectionSnapshot().keys
    @Assert(selectedKeys.size, 1)
    @Assert(selectedKeys[0], "rule_${selectedId}")

    // A filter that hides the selected row keeps the key and reports the
    // existing hiddenCount semantics; the draft is still unapplied.
    scene = presetScene(controller, 19)
    @Assert(presetText(controller, presetNodeById(scene, 24), "Gamma"), true)
    @Assert(controller.collectionHiddenCount(), 1)
    @Assert(controller.collectionSelectionSnapshot().keys.size, 1)
    @Assert(domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "草稿 Beta")

    // External switch enters the same host and changes the same view state.
    let external = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SELECT_COLLECTION_VIEW", view.revision(),
        ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("name", CjguiSharedOperationValue.string("A"))
        ])))
    @Assert(external.applied, true)
    @Assert(external.reason, "view_selected")
    @Assert(view.mode(), "table")
    @Assert(view.query(), "a")
    @Assert(domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "草稿 Beta")
    @Assert(controller.collectionSelectionSnapshot().keys.size, 1)
    // Human continues after the external switch: a new filter and sort still
    // use the same view object.
    scene = presetScene(controller, 21)
    @Assert(presetText(controller, presetNodeById(scene, 24), "Beta"), true)
    @Assert(controller.collectionViewState().query(), "Beta")

    // Published read-back comes from the same host, not a mirror.
    let catalog = presetContextField(domain, "collectionViews")
    @Assert(catalog.contains("NAME"), true)
    let current = presetContextField(domain, "collectionView")
    @Assert(current.startsWith("CJGUI_COLLECTION_VIEW 1"), true)
    @Assert(presetContextField(domain, "collectionViewRevision").size > 0, true)

    // Reset through the same host entry: default mode/query/sort/columns, the
    // active preset name is cleared, and saved presets remain available.
    let reset = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "RESET_COLLECTION_VIEW", view.revision(),
        ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
        ArrayList<CjguiSharedOperationActionArgument>()))
    @Assert(reset.applied, true)
    @Assert(reset.reason, "view_reset")
    @Assert(view.mode(), "list")
    @Assert(view.query(), "")
    @Assert(view.sortColumnKey(), "")
    @Assert(controller.viewPreferencesStore().activeName(), "")
    @Assert(controller.viewPreferencesStore().names(), ArrayList<String>(["A", "B"]))
    @Assert(domain.formSnapshot().fieldForResourceId(
        CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "草稿 Beta")
}

@Test
func collectionViewPreferencesReloadInNewController(): Unit {
    let directory = Directory.createTemp("/tmp")
    let documentPath = directory.join("rules.json").toString()
    let preferencePath = directory.join("views.cjgui-views").toString()
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    presetCreateRule(domain, "Alpha", 10, "reload-rule-1")
    presetCreateRule(domain, "Beta", 20, "reload-rule-2")
    @Assert(domain.saveAsFromHuman(documentPath).applied, true)

    let first = CjguiRuleSetComposableController(domain,
        viewPreferencesPath: preferencePath)
    let firstView = first.collectionViewState()
    let firstLayout = first.tableColumnLayout()
    var scene = presetScene(first, 1)
    @Assert(presetClick(first, presetNodeById(scene, 200)), true)
    @Assert(firstView.setSortState("retention", true), true)
    @Assert(firstLayout.setWidth("retention", 140), true)
    @Assert(firstLayout.setVisible("excluded", false), true)
    @Assert(presetSaveAs(first, 2, "A"), true)
    // B differs in mode and query.
    @Assert(firstView.setMode("list"), true)
    @Assert(firstView.setQuery("Beta"), true)
    @Assert(firstView.clearSort(), true)
    @Assert(firstLayout.setVisible("excluded", true), true)
    @Assert(presetSaveAs(first, 5, "B"), true)
    @Assert(presetSelect(first, 8, 0), true)
    @Assert(presetSavePreferences(first, 11), true)
    @Assert(first.viewPreferencesStore().isDirty(), false)
    @Assert(exists(preferencePath), true)
    // Preferences are a separate file from the rule document.
    @Assert(String.fromUtf8(File.readFrom(preferencePath)).startsWith("CJGUI_RULE_SET_VIEWS 1"), true)
    @Assert(String.fromUtf8(File.readFrom(documentPath)).startsWith("CJGUI_RULE_SET 1"), true)

    // A new instance reads the same document and preference file.
    let reopened = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(reopened.openFromHuman(documentPath).applied, true)
    let second = CjguiRuleSetComposableController(reopened,
        viewPreferencesPath: preferencePath)
    let secondView = second.collectionViewState()
    let secondLayout = second.tableColumnLayout()
    @Assert(second.viewPreferencesStore().activeName(), "A")
    @Assert(secondView.mode(), "table")
    @Assert(secondView.query(), "")
    @Assert(secondView.sortColumnKey(), "retention")
    @Assert(secondView.sortAscending(), true)
    @Assert(secondLayout.width("retention"), 140)
    @Assert(secondLayout.isVisible("excluded"), false)
    @Assert(second.viewPreferencesStore().names(), ArrayList<String>(["A", "B"]))
    // Public read-back after reopen reports the restored snapshot.
    @Assert(presetContextField(reopened, "collectionView").contains("CJGUI_COLLECTION_VIEW 1"), true)
    let reopenedScene = presetScene(second, 1)
    @Assert(presetNodeById(reopenedScene, 205).actionName, "OPEN_VIEW_MENU")
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func collectionViewPreferencesRejectInvalidFileAndKeepOldCatalog(): Unit {
    let directory = Directory.createTemp("/tmp")
    let preferencePath = directory.join("views.cjgui-views").toString()
    let store = CjguiRuleSetViewPreferences()
    let snapshot = CjguiComposableUiCollectionViewSnapshot("list", "q", "", true,
        ArrayList<CjguiComposableUiTableColumnState>([
            CjguiComposableUiTableColumnState("name", 0, true)
        ]))
    @Assert(store.upsert("Keep", snapshot), true)
    let beforeNames = store.names()
    let beforeRevision = store.revision()
    // An unsupported version is rejected as a whole and the old catalog stays.
    File.writeTo(preferencePath, "CJGUI_RULE_SET_VIEWS 2\nACTIVE -\nEND\n".toArray())
    let unsupported = store.load(preferencePath)
    @Assert(unsupported.applied, false)
    @Assert(unsupported.reason, "unsupported_view_preferences_version")
    @Assert(store.names(), beforeNames)
    @Assert(store.revision(), beforeRevision)
    // Malformed snapshot payload is rejected too.
    File.writeTo(preferencePath,
        "CJGUI_RULE_SET_VIEWS 1\nACTIVE -\nVIEW 41 434A4755495F434F4C4C454354494F4E5F564945572032\nEND\n".toArray())
    let malformed = store.load(preferencePath)
    @Assert(malformed.applied, false)
    @Assert(malformed.reason, "invalid_view_snapshot")
    @Assert(store.names(), beforeNames)
    // A dangling active name is tolerated as no active preset, not as a
    // reason to discard valid saved views.
    File.writeTo(preferencePath,
        "CJGUI_RULE_SET_VIEWS 1\nACTIVE 5A\nVIEW 41 434A4755495F434F4C4C454354494F4E5F564945572031207C204D4F4445203643363937333734207C205155455259202D207C20534F5254204E4F4E45207C20434F4C20364536313644363520302031\nEND\n".toArray())
    let loaded = store.load(preferencePath)
    @Assert(loaded.applied, true)
    @Assert(store.activeName(), "")
    @Assert(store.names(), ArrayList<String>(["A"]))
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func viewPreferenceSaveRejectsPayloadBeyondReadContract(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("views.cjgui-views").toString()
    let store = CjguiRuleSetViewPreferences()
    let smallSnapshot = presetTestSnapshot("")
    @Assert(store.upsert("Small", smallSnapshot), true)
    @Assert(store.save(path, ArrayList<String>()).applied, true)
    let beforeBytes = String.fromUtf8(File.readFrom(path))

    // 16 presets with a 4096-byte query exceed the 262144-byte read bound once
    // the snapshot text and preference hex encoding are applied.
    let bigSnapshot = presetTestSnapshot(presetLargeQuery(4096))
    var index: Int64 = 0
    while (index < 16) {
        @Assert(store.upsert("V${index}", bigSnapshot), true)
        index += 1
    }
    @Assert(store.names().size, 17)
    // The public encoder applies the decoder's per-snapshot bounds: a query
    // beyond 8192 bytes is refused, so no preset can be stored unreadably.
    let oversizedQuery = presetTestSnapshot(presetLargeQuery(8193))
    let oversizedEncoding = CjguiComposableUiCollectionViewCodec.encodeChecked(oversizedQuery)
    @Assert(oversizedEncoding.isValid(), false)
    @Assert(oversizedEncoding.reason, "view_query_too_large")
    @Assert(store.upsert("TooBigQuery", oversizedQuery), false)
    @Assert(store.lastReason(), "invalid_view_snapshot")
    @Assert(store.names().size, 17)
    @Assert(store.encode().size > 262144, true)
    let rejected = store.save(path, ArrayList<String>())
    @Assert(rejected.applied, false)
    @Assert(rejected.reason, "view_preferences_too_large")
    @Assert(String.fromUtf8(File.readFrom(path)), beforeBytes)
    @Assert(store.isDirty(), true)

    // A legal payload saves and reopens successfully.
    let legalPath = directory.join("legal.cjgui-views").toString()
    let legalStore = CjguiRuleSetViewPreferences()
    @Assert(legalStore.upsert("A", smallSnapshot), true)
    @Assert(legalStore.save(legalPath, ArrayList<String>()).applied, true)
    let reopened = CjguiRuleSetViewPreferences()
    let loaded = reopened.load(legalPath)
    @Assert(loaded.applied, true)
    @Assert(reopened.activeName(), "A")
    @Assert(reopened.names(), ArrayList<String>(["A"]))
    let restored = reopened.snapshot("A")
    match (restored) {
        case Some(snapshot) => @Assert(snapshot.query, "")
        case None => @Assert(false, true)
    }
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func viewPreferenceSaveRejectsBusinessDocumentTarget(): Unit {
    let directory = Directory.createTemp(".")
    let businessPath = directory.join("rules.json").toString()
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    presetCreateRule(domain, "Business", 10, "preference-path-business")
    @Assert(domain.saveAsFromHuman(businessPath).applied, true)
    let businessBefore = String.fromUtf8(File.readFrom(businessPath))

    // A separate valid preference file exists before the conflicting attempts;
    // it must also stay byte-identical.
    let originalPrefsPath = directory.join("original.cjgui-views").toString()
    let originalStore = CjguiRuleSetViewPreferences()
    @Assert(originalStore.upsert("A", presetTestSnapshot("")), true)
    @Assert(originalStore.save(originalPrefsPath, ArrayList<String>([businessPath])).applied, true)
    let originalPrefsBefore = String.fromUtf8(File.readFrom(originalPrefsPath))

    let controller = CjguiRuleSetComposableController(domain)
    let preferences = controller.viewPreferencesStore()
    @Assert(preferences.upsert("A", controller.collectionViewState().snapshot()), true)
    preferences.setFilePath(businessPath)
    let currentDocumentConflict = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SAVE_COLLECTION_VIEW_PREFERENCES", preferences.revision(),
        ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
        ArrayList<CjguiSharedOperationActionArgument>()))
    @Assert(currentDocumentConflict.applied, false)
    @Assert(currentDocumentConflict.reason, "view_preferences_conflicts_with_document")
    @Assert(String.fromUtf8(File.readFrom(businessPath)), businessBefore)
    @Assert(String.fromUtf8(File.readFrom(originalPrefsPath)), originalPrefsBefore)
    @Assert(preferences.isDirty(), true)

    // The same existing document through a relative path is equivalent.
    let cwd = canonicalize(Path(".")).toString()
    let parts = businessPath.split(cwd + "/")
    @Assert(parts.size, 2)
    let relative = parts[1]
    let relativeConflict = preferences.save(relative, ArrayList<String>([businessPath]))
    @Assert(relativeConflict.applied, false)
    @Assert(relativeConflict.reason, "view_preferences_conflicts_with_document")
    @Assert(String.fromUtf8(File.readFrom(businessPath)), businessBefore)
    @Assert(String.fromUtf8(File.readFrom(originalPrefsPath)), originalPrefsBefore)

    // A pending save-as target is also protected, and both files stay intact.
    let pendingPath = directory.join("pending-rules.json").toString()
    File.writeTo(pendingPath, "pending-business-bytes".toArray())
    let pendingBefore = String.fromUtf8(File.readFrom(pendingPath))
    let pendingConflict = preferences.save(pendingPath,
        ArrayList<String>([businessPath, pendingPath]))
    @Assert(pendingConflict.applied, false)
    @Assert(pendingConflict.reason, "view_preferences_conflicts_with_document")
    @Assert(String.fromUtf8(File.readFrom(pendingPath)), pendingBefore)
    @Assert(String.fromUtf8(File.readFrom(businessPath)), businessBefore)
    @Assert(String.fromUtf8(File.readFrom(originalPrefsPath)), originalPrefsBefore)

    // A different target still saves.
    let differentPath = directory.join("views.cjgui-views").toString()
    preferences.setFilePath(differentPath)
    let saved = preferences.save(differentPath, ArrayList<String>([businessPath]))
    @Assert(saved.applied, true)
    @Assert(exists(differentPath), true)
    @Assert(String.fromUtf8(File.readFrom(businessPath)), businessBefore)
    let _ = removeIfExists(directory, recursive: true)
}

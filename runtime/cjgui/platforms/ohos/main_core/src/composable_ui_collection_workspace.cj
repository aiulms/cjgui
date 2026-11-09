// One thin public collection workspace (DS51 §12).
//
// It joins facts that ALREADY exist and were repeated by normal consumers:
//   * CjguiComposableUiTableSource filtering/sorting/column layout,
//   * CjguiComposableUiCollectionViewState mode/query/sort/columns and its
//     validated snapshot text,
//   * the accepted mount lookup of CjguiGeneratedUiCollection (reveal one
//     business key in ONE named mount).
//
// What it is NOT: another registry, draft, selection or view state. It never
// writes business data, never keeps a hidden presentation mode and never
// invents a second schema: a mode token is only a TOKEN; mapping it to a real
// declaration stays the application's declared candidate change.
package cjgui

import std.collection.*

public let CJGUI_COLLECTION_ACTION_SAVE_VIEW = "COLLECTION_VIEW_SAVE"
public let CJGUI_COLLECTION_ACTION_RESTORE_VIEW = "COLLECTION_VIEW_RESTORE"
public let CJGUI_COLLECTION_ACTION_RESET_VIEW = "COLLECTION_VIEW_RESET"
public let CJGUI_COLLECTION_COLUMN_ACTION_TOGGLE = "COLLECTION_COLUMN_TOGGLE"
public let CJGUI_COLLECTION_COLUMN_ACTION_NARROW = "COLLECTION_COLUMN_NARROW"
public let CJGUI_COLLECTION_COLUMN_ACTION_WIDE = "COLLECTION_COLUMN_WIDE"
public let CJGUI_COLLECTION_COLUMN_ACTION_MOVE_LEFT = "COLLECTION_COLUMN_MOVE_LEFT"
public let CJGUI_COLLECTION_COLUMN_ACTION_MOVE_RIGHT = "COLLECTION_COLUMN_MOVE_RIGHT"
public let CJGUI_COLLECTION_COLUMN_ACTION_RESET = "COLLECTION_COLUMN_RESET"

/// One common command fact. `suffix` is both the scoped node suffix and the
/// command id suffix below the workspace's canonical scope path.
public class CjguiCollectionWorkspaceEntry {
    public let action: String
    public let label: String
    public let suffix: String

    public init(action: String, label: String, suffix: String) {
        this.action = action
        this.label = label
        this.suffix = suffix
    }
}

/// Result of one workspace action. It never carries business data; `status` is
/// the short text a status row presents.
public class CjguiCollectionWorkspaceOutcome {
    public let action: String
    public let applied: Bool
    public let reason: String
    public let status: String

    public init(action: String, applied: Bool, reason: String, status: String) {
        this.action = action
        this.applied = applied
        this.reason = reason
        this.status = status
    }
}

public class CjguiCollectionWorkspace {
    private let viewStateValue: CjguiComposableUiCollectionViewState
    private let collectionValue: CjguiGeneratedUiCollection
    private let scopeValue: CjguiComposableUiIdentityScope
    private let commandPrefixValue: String
    private let semanticPrefixValue: String
    private let titleValue: String
    // Mode token -> the presentation this application DECLARES for it. The
    // mapping is supplied by the application; the workspace never guesses or
    // mutates the accepted declaration behind the caller's back.
    private let modePresentationsValue: HashMap<String, String>
    // Optional OWNER authority for query/sort. A workspace whose consumer owns
    // those facts (mixed cards) passes this; a workspace that owns them in the
    // public view state (rules) leaves it None and keeps the direct path.
    private let viewAuthorityValue: ?((String, String, Bool) -> Bool)
    // Exact node identity of the controls THIS workspace built. Event ownership
    // is by accepted node id, not by a semantic prefix: a nested scope can make
    // one prefix contain another.
    private let actionSemantics = HashMap<String, String>()
    private let actionEnabled = HashMap<String, Bool>()
    private let columnSemantics = HashMap<String, String>()
    private let columnIndexes = HashMap<String, Int64>()
    private let columnEnabled = HashMap<String, Bool>()
    private var statusValue: String

    public init(collection: CjguiGeneratedUiCollection, viewState: CjguiComposableUiCollectionViewState,
        scope: CjguiComposableUiIdentityScope, title!: String = "集合",
        modePresentations!: HashMap<String, String> = HashMap<String, String>(),
        viewAuthority!: ?((String, String, Bool) -> Bool) = None) {
        this.collectionValue = collection
        this.viewStateValue = viewState
        this.scopeValue = scope
        this.commandPrefixValue = CjguiCollectionWorkspace.scopedCommandPrefix(scope)
        this.semanticPrefixValue = CjguiCollectionWorkspace.scopedSemanticPrefix(scope)
        this.titleValue = title
        this.modePresentationsValue = modePresentations
        this.viewAuthorityValue = viewAuthority
        this.statusValue = ""

    }

    /// Machine command prefix derived from the canonical scope path with an
    /// injective per-character transform, so two mounted workspaces never share
    /// a command id (the same rule the UI-document workspace uses).
    static func scopedCommandPrefix(scope: CjguiComposableUiIdentityScope): String {
        return "collection." + scope.canonicalPath().replace(":", "-").replace("/", ".")
    }

    static func scopedSemanticPrefix(scope: CjguiComposableUiIdentityScope): String {
        return cjguiCommandToolbarKey(CjguiCollectionWorkspace.scopedCommandPrefix(scope))
    }

    public func title(): String {
        return titleValue
    }

    public func semanticPrefix(): String {
        return semanticPrefixValue
    }

    public func viewState(): CjguiComposableUiCollectionViewState {
        return viewStateValue
    }

    public func collection(): CjguiGeneratedUiCollection {
        return collectionValue
    }

    public func status(): String {
        return statusValue
    }

    public func noteStatus(text: String): Unit {
        statusValue = text
    }

    /// The DECLARED presentation an application maps a view mode token to.
    /// Empty means this application does not present that mode right now.
    public func presentationForMode(mode: String): String {
        return match (modePresentationsValue.get(mode)) {
            case Some(value) => value
            case None => ""
        }
    }

    /// Applies the ONE business filter fact to the shared table. Two entries
    /// that describe the same fact converge here; the caller that owns the
    /// business value decides when it changes.
    public func projectBusinessQuery(value: String): Bool {
        return viewStateValue.setQuery(value)
    }

    /// Applies the ONE business sort fact to the shared table (explicit target,
    /// never a repeated toggle).
    public func projectBusinessSort(columnKey: String, ascending: Bool): Bool {
        if (columnKey.isEmpty()) {
            return viewStateValue.clearSort()
        }
        if (viewStateValue.sortColumnKey() == columnKey && viewStateValue.sortAscending() == ascending) {
            return false
        }
        return viewStateValue.setSortState(columnKey, ascending)
    }

    /// Header-click behaviour for a real column: a new column starts ascending
    /// and the active column flips. It only moves the shared table fact.
    public func toggleSort(columnKey: String): Bool {
        return viewStateValue.toggleSort(columnKey)
    }

    /// Sets the view mode TOKEN. The application still decides how a mode is
    /// declared: `presentationForMode` names it and the ordinary candidate path
    /// submits the structure. No hidden mode is written.
    public func setMode(mode: String): Bool {
        if (!viewStateValue.setMode(mode)) {
            return false
        }
        statusValue = "视图模式：${mode}"
        return true
    }

    public func setColumnVisible(key: String, visible: Bool): Bool {
        return viewStateValue.tableLayout().setVisible(key, visible)
    }

    public func setColumnWidth(key: String, width: Int64): Bool {
        return viewStateValue.tableLayout().setWidth(key, width)
    }

    /// Saves the current presentation as the public snapshot TEXT. It contains
    /// mode/query/sort/columns only: never business records, pointer capture,
    /// temporary focus or an uncommitted candidate.
    public func encodedSnapshot(): String {
        return viewStateValue.encodedSnapshot()
    }

    /// Restores a snapshot through the EXISTING validated, all-or-nothing
    /// restore. An invalid snapshot leaves the current view untouched.
    public func restoreEncoded(value: String): CjguiCollectionWorkspaceOutcome {
        let restored = viewStateValue.restoreEncoded(value)
        if (!restored.applied) {
            statusValue = "视图恢复失败：${restored.reason}"
            return CjguiCollectionWorkspaceOutcome(CJGUI_COLLECTION_ACTION_RESTORE_VIEW, false,
                restored.reason, statusValue)
        }
        statusValue = "视图已恢复（忽略 ${restored.ignoredColumnKeys.size} 列，新增 " +
            "${restored.addedColumnKeys.size} 列）"
        return CjguiCollectionWorkspaceOutcome(CJGUI_COLLECTION_ACTION_RESTORE_VIEW, true,
            restored.reason, statusValue)
    }

    public func resetView(): CjguiCollectionWorkspaceOutcome {
        let reset = viewStateValue.resetToDefault()
        statusValue = if (reset.applied) { "视图已重置" } else { "视图重置失败：${reset.reason}" }
        return CjguiCollectionWorkspaceOutcome(CJGUI_COLLECTION_ACTION_RESET_VIEW, reset.applied,
            reset.reason, statusValue)
    }

    /// Reveals one business key in ONE named accepted mount below the
    /// workspace's own scope. A missing or retired mount refuses; it never
    /// falls back to the last built mount.
    public func reveal(instanceKey: String, key: String): Bool {
        return collectionValue.revealItem(key, scopeValue, instanceKey)
    }

    /// Reveals in one named accepted mount below an EXPLICIT region scope. One
    /// application view can be presented by several regions; the caller names
    /// the region it wants moved instead of sharing a hidden "current" mount.
    public func revealIn(scope: CjguiComposableUiIdentityScope, instanceKey: String,
        key: String): Bool {
        return collectionValue.revealItem(key, scope, instanceKey)
    }

    public static func entries(): ArrayList<CjguiCollectionWorkspaceEntry> {
        let result = ArrayList<CjguiCollectionWorkspaceEntry>()
        result.add(CjguiCollectionWorkspaceEntry(CJGUI_COLLECTION_ACTION_SAVE_VIEW, "保存视图", "save-view"))
        result.add(CjguiCollectionWorkspaceEntry(CJGUI_COLLECTION_ACTION_RESTORE_VIEW, "恢复视图", "restore-view"))
        result.add(CjguiCollectionWorkspaceEntry(CJGUI_COLLECTION_ACTION_RESET_VIEW, "重置视图", "reset-view"))
        return result
    }

    public func commandId(action: String): String {
        for (entry in CjguiCollectionWorkspace.entries()) {
            if (entry.action == action) {
                return "${commandPrefixValue}.${entry.suffix}"
            }
        }
        return commandPrefixValue
    }

    public func nodeReference(action: String): CjguiComposableUiNodeReference {
        for (entry in CjguiCollectionWorkspace.entries()) {
            if (entry.action == action) {
                return CjguiComposableUiNodeReference.scoped(scopeValue, entry.suffix)
            }
        }
        return CjguiComposableUiNodeReference.scoped(scopeValue, "root")
    }

    public func ownsCommand(commandId: String): Bool {
        for (entry in CjguiCollectionWorkspace.entries()) {
            if (commandId == "${commandPrefixValue}.${entry.suffix}") { return true }
        }
        return false
    }

    /// Common command projection. `savedSnapshot` is the application's stored
    /// snapshot text (empty when it has none yet): availability is a REAL fact,
    /// not a placeholder.
    public func commandDeclarations(savedSnapshot: String): ArrayList<CjguiComposableUiCommand> {
        let result = ArrayList<CjguiComposableUiCommand>()
        for (entry in CjguiCollectionWorkspace.entries()) {
            let enabled = if (entry.action == CJGUI_COLLECTION_ACTION_RESTORE_VIEW) {
                savedSnapshot.size > 0
            } else {
                true
            }
            result.add(CjguiComposableUiCommand(commandId(entry.action), nodeReference(entry.action),
                entry.label, "View", 0, enabled, false))
        }
        return result
    }

    /// Presentation metadata matching `commandDeclarations`, so a toolbar/menu
    /// shows the same label and disabled reason as the real button.
    public func commandMetadata(resourceId: Int64, savedSnapshot: String): ArrayList<CjguiCommandToolbarMetadata> {
        let result = ArrayList<CjguiCommandToolbarMetadata>()
        for (entry in CjguiCollectionWorkspace.entries()) {
            let reason = if (entry.action == CJGUI_COLLECTION_ACTION_RESTORE_VIEW && savedSnapshot.size == 0) {
                "尚未保存视图"
            } else {
                ""
            }
            result.add(CjguiCommandToolbarMetadata(commandId(entry.action), entry.action, resourceId,
                detail: entry.label, disabledReason: reason))
        }
        return result
    }

    /// A THIN normal-entry action row reused by both consumers. Labels, node
    /// identity, action names and the restore availability all come from the
    /// same command facts; the caller only mounts it and routes the action back
    /// to `executeAction` with its own persistence callbacks.
    public func buildActionBar(idBase: Int64, style: CjguiComposableUiStyle,
        savedSnapshot: String, buttonStyle: CjguiComposableUiStyle): CjguiComposableUiNode {
        let row = cjguiComposableWrap(idBase, "${semanticPrefixValue}-actions", style)
        var offset: Int64 = 1
        for (entry in CjguiCollectionWorkspace.entries()) {
            let enabled = if (entry.action == CJGUI_COLLECTION_ACTION_RESTORE_VIEW) {
                savedSnapshot.size > 0
            } else {
                true
            }
            let nodeId = idBase + offset
            row.add(cjguiComposableButton(nodeId, "${semanticPrefixValue}-${entry.suffix}",
                entry.label, entry.action, -1, buttonStyle, enabled: enabled,
                identity: Some(scopeValue.local(entry.suffix))))
            actionSemantics.add("${semanticPrefixValue}-${entry.suffix}", entry.action)
            actionEnabled.add("${semanticPrefixValue}-${entry.suffix}", enabled)
            offset += 1
        }
        return row
    }

    /// The action this event requests from THIS workspace, or None for another
    /// scope/component. Presentation and dispatch therefore share one fact.
    public func actionForEvent(event: CjguiComposableUiEvent): ?String {
        // Only a real ACTIVATION may execute. FOCUS/blur/hover/scroll/navigation
        // carry the same node id but are NOT the operation.
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) { return None }
        let action = match (actionSemantics.get(event.node.semanticId)) {
            case Some(value) => value
            case None => return None
        }
        // The semantic identity is exact AND the declared action must match it:
        // a foreign/copied node cannot select a different operation by name.
        if (event.node.actionName != action) { return None }
        let enabled = match (actionEnabled.get(event.node.semanticId)) {
            case Some(value) => value
            case None => false
        }
        if (!enabled) { return None }
        return Some(action)
    }

    /// The command this event requests when it arrived through the window's
    /// command route (`event.text` is the scoped command id). This is the SAME
    /// execution entry as the button, with the same disabled guard.
    public func commandForEvent(event: CjguiComposableUiEvent): ?String {
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) { return None }
        for (entry in CjguiCollectionWorkspace.entries()) {
            if (event.text == commandId(entry.action)) { return Some(entry.action) }
        }
        return None
    }

    /// Executes one workspace action, delegating ONLY persistence to the
    /// application. `save` receives the encoded view snapshot and returns
    /// whether its store accepted it; `load` returns the stored snapshot (empty
    /// when none). Nothing is faked: an empty load keeps restore unavailable.
    public func executeAction(action: String, save: (String) -> Bool,
        load: () -> String): CjguiCollectionWorkspaceOutcome {
        if (action == CJGUI_COLLECTION_ACTION_SAVE_VIEW) {
            let encoded = encodedSnapshot()
            if (!save(encoded)) {
                statusValue = "视图快照没有保存"
                return CjguiCollectionWorkspaceOutcome(action, false, "workspace_save_refused", statusValue)
            }
            statusValue = "视图快照已保存（${encoded.size} 字节）"
            return CjguiCollectionWorkspaceOutcome(action, true, "saved", statusValue)
        }
        if (action == CJGUI_COLLECTION_ACTION_RESTORE_VIEW) {
            let saved = load()
            if (saved.size == 0) {
                statusValue = "尚未保存视图"
                return CjguiCollectionWorkspaceOutcome(action, false, "view_not_saved", statusValue)
            }
            let restored = match (viewAuthorityValue) {
                case Some(gate) => viewStateValue.restoreEncodedWithAuthority(saved, gate)
                case None => viewStateValue.restoreEncoded(saved)
            }
            return noteRestore(restored)
        }
        if (action == CJGUI_COLLECTION_ACTION_RESET_VIEW) {
            let reset = match (viewAuthorityValue) {
                case Some(gate) => viewStateValue.resetToDefaultWithAuthority(gate)
                case None => viewStateValue.resetToDefault()
            }
            return noteRestore(reset)
        }
        statusValue = "未知视图操作"
        return CjguiCollectionWorkspaceOutcome(action, false, "unknown_action", statusValue)
    }

    /// Reusable column controls over the ONE TableColumnLayout: visibility,
    /// width nudge and order move, plus reset. The app mounts the row and calls
    /// `applyColumnEvent`; header/content/paint keep reading the same layout.
    public func buildColumnEditor(idBase: Int64, style: CjguiComposableUiStyle,
        buttonStyle: CjguiComposableUiStyle): CjguiComposableUiNode {
        let row = cjguiComposableWrap(idBase, "${semanticPrefixValue}-columns", style)
        let keys = viewStateValue.tableLayout().declaredKeys()
        var offset: Int64 = 1
        var columnIndex: Int64 = 0
        func addColumnButton(key: String, action: String, suffix: String): Unit {
            let nodeId = idBase + offset
            var verb = ""
            var enabled = true
            if (action == CJGUI_COLLECTION_COLUMN_ACTION_TOGGLE) {
                verb = if (viewStateValue.tableLayout().isVisible(key)) { "隐藏" } else { "显示" }
                enabled = !(viewStateValue.tableLayout().isVisible(key) &&
                    viewStateValue.tableLayout().visibleCount() <= 1)
            } else if (action == CJGUI_COLLECTION_COLUMN_ACTION_NARROW) {
                verb = "窄"
                enabled = viewStateValue.tableLayout().width(key) > 0 &&
                    viewStateValue.tableLayout().width(key) >
                        viewStateValue.tableLayout().minWidth(key)
            } else if (action == CJGUI_COLLECTION_COLUMN_ACTION_WIDE) {
                verb = "宽"
                enabled = viewStateValue.tableLayout().width(key) > 0 &&
                    viewStateValue.tableLayout().width(key) <
                        viewStateValue.tableLayout().maxWidth(key)
            } else if (action == CJGUI_COLLECTION_COLUMN_ACTION_MOVE_LEFT) {
                verb = "左移"
                enabled = viewStateValue.tableLayout().columnKeys()[0] != key
            } else {
                verb = "右移"
                let keys = viewStateValue.tableLayout().columnKeys()
                enabled = keys[keys.size - 1] != key
            }
            row.add(cjguiComposableButton(nodeId, "${semanticPrefixValue}-${suffix}-${key}",
                "${verb} ${key}", action, columnIndex, buttonStyle, enabled: enabled,
                identity: Some(scopeValue.child("column").local("${suffix}-${key}"))))
            let semantic = "${semanticPrefixValue}-${suffix}-${key}"
            columnSemantics.add(semantic, action)
            columnIndexes.add(semantic, columnIndex)
            columnEnabled.add(semantic, enabled)
            offset += 1
        }
        for (key in keys) {
            addColumnButton(key, CJGUI_COLLECTION_COLUMN_ACTION_TOGGLE, "column-toggle")
            addColumnButton(key, CJGUI_COLLECTION_COLUMN_ACTION_NARROW, "column-narrow")
            addColumnButton(key, CJGUI_COLLECTION_COLUMN_ACTION_WIDE, "column-wide")
            addColumnButton(key, CJGUI_COLLECTION_COLUMN_ACTION_MOVE_LEFT, "column-left")
            addColumnButton(key, CJGUI_COLLECTION_COLUMN_ACTION_MOVE_RIGHT, "column-right")
            columnIndex += 1
        }
        row.add(cjguiComposableButton(idBase + offset, "${semanticPrefixValue}-columns-reset",
            "重置列", CJGUI_COLLECTION_COLUMN_ACTION_RESET, -1, buttonStyle,
            identity: Some(scopeValue.child("column").local("reset"))))
        let resetSemantic = "${semanticPrefixValue}-columns-reset"
        columnSemantics.add(resetSemantic, CJGUI_COLLECTION_COLUMN_ACTION_RESET)
        columnIndexes.add(resetSemantic, -1)
        columnEnabled.add(resetSemantic, true)
        return row
    }

    /// Applies a column-intent event to the shared layout. Returns None when the
    /// event is not this workspace's column control, so scopes cannot borrow
    /// each other's buttons.
    public func applyColumnEvent(event: CjguiComposableUiEvent): ?Bool {
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) { return None }
        let action = match (columnSemantics.get(event.node.semanticId)) {
            case Some(value) => value
            case None => return None
        }
        if (event.node.actionName != action) { return None }
        let enabled = match (columnEnabled.get(event.node.semanticId)) {
            case Some(value) => value
            case None => false
        }
        if (!enabled) { return None }
        let layout = viewStateValue.tableLayout()
        if (action == CJGUI_COLLECTION_COLUMN_ACTION_RESET) {
            let applied = layout.reset()
            statusValue = if (applied) { "列设置已重置" } else { "列设置已是默认" }
            return Some(applied)
        }
        let index = match (columnIndexes.get(event.node.semanticId)) {
            case Some(value) => value
            case None => -1
        }
        let keys = layout.declaredKeys()
        if (index < 0 || index >= keys.size) { return Some(false) }
        let key = keys[index]
        if (action == CJGUI_COLLECTION_COLUMN_ACTION_TOGGLE) {
            let nowVisible = layout.isVisible(key)
            let applied = layout.toggleVisible(key)
            let nextAction = if (nowVisible) { "隐藏" } else { "显示" }
            statusValue = if (applied) { "列 ${key}：${nextAction}" } else { "列 ${key} 已是唯一可见列" }
            return Some(applied)
        }
        if (action == CJGUI_COLLECTION_COLUMN_ACTION_NARROW) {
            let applied = layout.nudgeWidth(key, -16)
            statusValue = if (applied) { "列 ${key} 宽 ${layout.width(key)}" } else { "列 ${key} 已到最小宽度" }
            return Some(applied)
        }
        if (action == CJGUI_COLLECTION_COLUMN_ACTION_WIDE) {
            let applied = layout.nudgeWidth(key, 16)
            statusValue = if (applied) { "列 ${key} 宽 ${layout.width(key)}" } else { "列 ${key} 已到最大宽度" }
            return Some(applied)
        }
        if (action == CJGUI_COLLECTION_COLUMN_ACTION_MOVE_LEFT) {
            let applied = layout.move(key, -1)
            statusValue = if (applied) { "列 ${key} 已左移" } else { "列 ${key} 已在最左" }
            return Some(applied)
        }
        if (action == CJGUI_COLLECTION_COLUMN_ACTION_MOVE_RIGHT) {
            let applied = layout.move(key, 1)
            statusValue = if (applied) { "列 ${key} 已右移" } else { "列 ${key} 已在最右" }
            return Some(applied)
        }
        return None
    }

    private func noteRestore(
        restored: CjguiComposableUiCollectionViewRestoreResult): CjguiCollectionWorkspaceOutcome {
        if (!restored.applied) {
            statusValue = "视图操作失败：${restored.reason}"
            return CjguiCollectionWorkspaceOutcome(CJGUI_COLLECTION_ACTION_RESTORE_VIEW, false,
                restored.reason, statusValue)
        }
        let action = if (restored.reason == "view_reset") {
            CJGUI_COLLECTION_ACTION_RESET_VIEW
        } else {
            CJGUI_COLLECTION_ACTION_RESTORE_VIEW
        }
        statusValue = "视图已恢复（忽略 ${restored.ignoredColumnKeys.size} 列，新增 " +
            "${restored.addedColumnKeys.size} 列）"
        return CjguiCollectionWorkspaceOutcome(action, true, restored.reason, statusValue)
    }

    /// One ordinary status row for the workspace's short feedback text. It is a
    /// projection only; the text is owned by the last workspace operation.
    public func buildStatusLine(nodeId: Int64): CjguiComposableUiNode {
        return cjguiComposableText(nodeId, "${semanticPrefixValue}-status", statusValue,
            CjguiComposableUiStyle(textColor: CjguiComposableUiColor(0.55, 0.60, 0.70, 1.0),
                textMaxLines: 2))
    }
}

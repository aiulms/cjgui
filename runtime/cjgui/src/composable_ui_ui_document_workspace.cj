// Optional public composition for the UI-document workflow: command facts,
// the ordinary save/preview/confirm/cancel/restore actions, and a narrow
// status/preview projection. Applications keep their navigation, business
// owner, theme and close policy; they supply only the session, surface and one
// explicit identity scope. No file watcher, background pump or extra
// control is created when a consumer does not mount this workspace.
package cjgui

import std.collection.*
import std.sync.*
import cjgui_shared_operation_core.*

public let CJGUI_UI_DOCUMENT_ACTION_SAVE = "UI_DOC_SAVE"
public let CJGUI_UI_DOCUMENT_ACTION_PREVIEW = "UI_DOC_PREVIEW"
public let CJGUI_UI_DOCUMENT_ACTION_CONFIRM = "UI_DOC_CONFIRM"
public let CJGUI_UI_DOCUMENT_ACTION_CANCEL = "UI_DOC_CANCEL"
public let CJGUI_UI_DOCUMENT_ACTION_RESTORE = "UI_DOC_RESTORE"
public let CJGUI_UI_DOCUMENT_ACTION_OPEN = "UI_DOC_OPEN"
public let CJGUI_UI_DOCUMENT_ACTION_SAVE_AS = "UI_DOC_SAVE_AS"
public let CJGUI_UI_DOCUMENT_ACTION_UNDO = "UI_DOC_UNDO"
public let CJGUI_UI_DOCUMENT_ACTION_REDO = "UI_DOC_REDO"

/// One stable command/node fact. `nodeOffset` is relative to a MANUAL
/// workspace's container id; scoped workspaces do not use it (their nodes
// carry scoped identities instead).
public class CjguiUiDocumentWorkspaceEntry {
    public let action: String
    public let label: String
    public let suffix: String
    public let nodeOffset: Int64

    public init(action: String, label: String, suffix: String, nodeOffset: Int64) {
        this.action = action
        this.label = label
        this.suffix = suffix
        this.nodeOffset = nodeOffset
    }
}

public class CjguiUiDocumentWorkspace {
    private let sessionValue: CjguiGeneratedUiDocumentSession
    private let surfaceValue: CjguiUiDocumentSurface
    private let commandPrefixValue: String
    /// MANUAL constructor only: the caller-reserved numeric node base. A
    /// scoped workspace has no numeric base; its nodes carry scoped
    /// identities and receive real node ids only when the accepted scene
    /// resolves them.
    private let nodeBaseValue: Int64
    private let semanticPrefixValue: String
    private let titleValue: String
    private let scopedValue: ?CjguiComposableUiIdentityScope

    public init(session: CjguiGeneratedUiDocumentSession, surface: CjguiUiDocumentSurface, commandPrefix: String,
        nodeBase: Int64, semanticPrefix: String, title!: String = "界面文档") {
        this.sessionValue = session
        this.surfaceValue = surface
        this.commandPrefixValue = commandPrefix
        this.nodeBaseValue = nodeBase
        this.semanticPrefixValue = semanticPrefix
        this.titleValue = title
        this.scopedValue = None
        if (session.historyEnabled()) {
            let issue = surface.attachUiDocumentWorkspace(this)
            if (issue.size > 0) { throw IllegalArgumentException(issue) }
        }
    }

    /// Normal scoped mount: the caller supplies ONE identity scope; command
    /// ids, semantic ids and node identities are derived from its CANONICAL
    /// path (length-prefixed segments), never from the diagnostic text. Two
    /// scopes with equal diagnostic text but different canonical paths
    /// (`a--b` vs `a.child("b")`) therefore never collide, and rebuilding a
    /// workspace does not depend on construction order or a reserved number
    /// pool. The manual constructor stays available for old consumers.
    public init(scope: CjguiComposableUiIdentityScope, localKey: String, session: CjguiGeneratedUiDocumentSession,
        surface: CjguiUiDocumentSurface, title!: String = "界面文档") {
        let child = scope.child(localKey)
        this.sessionValue = session
        this.surfaceValue = surface
        this.commandPrefixValue = CjguiUiDocumentWorkspace.scopedCommandPrefix(child)
        this.nodeBaseValue = -1
        this.semanticPrefixValue = CjguiUiDocumentWorkspace.scopedSemanticPrefix(child)
        this.titleValue = title
        this.scopedValue = Some(child)
        if (session.historyEnabled()) {
            let issue = surface.attachUiDocumentWorkspace(this)
            if (issue.size > 0) { throw IllegalArgumentException(issue) }
        }
    }

    /// Machine command prefix from the canonical scope path. The transform
    /// (`:` -> `-`, `/` -> `.`) is per-character injective over the canonical
    /// alphabet (segment names never contain `:` or `/`), stays inside the
    /// safe presentation charset, and is bounded by the scope path limit.
    static func scopedCommandPrefix(scope: CjguiComposableUiIdentityScope): String {
        return "uidoc." + scope.canonicalPath().replace(":", "-").replace("/", ".")
    }

    /// Presentation (semantic-id) prefix, derived through the same public
    /// key helper the command toolbar uses, so no second schema exists.
    static func scopedSemanticPrefix(scope: CjguiComposableUiIdentityScope): String {
        return cjguiCommandToolbarKey(CjguiUiDocumentWorkspace.scopedCommandPrefix(scope))
    }

    public func session(): CjguiGeneratedUiDocumentSession {
        return sessionValue
    }

    public func surface(): CjguiUiDocumentSurface {
        return surfaceValue
    }

    public func title(): String {
        return titleValue
    }

    /// The workspace's public semantic-id prefix. Consumers use it only to
    /// match their own mounted nodes (for example the path field below).
    public func semanticPrefix(): String {
        return semanticPrefixValue
    }

    /// The semantic id of the path field `buildPathRow` declares, so a
    /// consumer can route TEXT_CHANGED events for its own path string.
    public func pathFieldSemanticId(): String {
        return "${semanticPrefixValue}-path"
    }

    /// MANUAL constructor only: the numeric node base. A scoped workspace
    /// resolves its nodes through scoped identities in the accepted scene and
    /// must not fabricate a numeric base.
    public func nodeBase(): Int64 {
        return nodeBaseValue
    }

    public func isScoped(): Bool {
        return scopedValue.isSome()
    }

    public func hasPath(): Bool {
        return sessionValue.path().size > 0
    }

    public static func entries(): ArrayList<CjguiUiDocumentWorkspaceEntry> {
        let result = ArrayList<CjguiUiDocumentWorkspaceEntry>()
        result.add(CjguiUiDocumentWorkspaceEntry(CJGUI_UI_DOCUMENT_ACTION_SAVE, "保存界面", "save", 3))
        result.add(CjguiUiDocumentWorkspaceEntry(CJGUI_UI_DOCUMENT_ACTION_PREVIEW, "预览载入", "preview", 4))
        result.add(CjguiUiDocumentWorkspaceEntry(CJGUI_UI_DOCUMENT_ACTION_CONFIRM, "确认载入", "confirm", 5))
        result.add(CjguiUiDocumentWorkspaceEntry(CJGUI_UI_DOCUMENT_ACTION_CANCEL, "取消预览", "cancel", 6))
        result.add(CjguiUiDocumentWorkspaceEntry(CJGUI_UI_DOCUMENT_ACTION_RESTORE, "恢复已存界面", "restore", 7))
        return result
    }

    private static func addressableEntries(): ArrayList<CjguiUiDocumentWorkspaceEntry> {
        let result = CjguiUiDocumentWorkspace.entries()
        result.add(CjguiUiDocumentWorkspaceEntry(CJGUI_UI_DOCUMENT_ACTION_UNDO, "撤销界面改动", "undo", 14))
        result.add(CjguiUiDocumentWorkspaceEntry(CJGUI_UI_DOCUMENT_ACTION_REDO, "重做界面改动", "redo", 15))
        return result
    }

    // Disabled legacy workspaces retain their original five visible actions.
    private func mountedEntries(): ArrayList<CjguiUiDocumentWorkspaceEntry> {
        return if (sessionValue.historyEnabled()) { CjguiUiDocumentWorkspace.addressableEntries() }
            else { CjguiUiDocumentWorkspace.entries() }
    }

    public func historyState(): CjguiUiDocumentHistoryState { return sessionValue.historyState(surfaceValue) }

    /// Public facts and human action availability share this session snapshot.
    public func historyPayload(): String {
        let state = historyState()
        let undo = if (state.undoReason.size == 0) { "-" } else {
            CjguiSharedOperationFrame.encodeUtf8Hex(state.undoReason) }
        let redo = if (state.redoReason.size == 0) { "-" } else {
            CjguiSharedOperationFrame.encodeUtf8Hex(state.redoReason) }
        let boundary = if (state.boundaryReason.size == 0) { "-" } else {
            CjguiSharedOperationFrame.encodeUtf8Hex(state.boundaryReason) }
        return "UI_DOCUMENT_HISTORY 1\nSUPPORTED 1\nENABLED ${state.enabled}\n" +
            "SURFACE_ID ${state.surfaceIdentity}\nACCEPTED_VERSION ${state.acceptedVersion}\n" +
            "ACCEPTED_DIGEST ${if (state.acceptedDigest.size > 0) { state.acceptedDigest } else { "-" }}\n" +
            "HISTORY_EPOCH ${state.epoch}\nHEAD_VERSION ${state.headVersion}\n" +
            "CAN_UNDO ${state.canUndo}\nCAN_REDO ${state.canRedo}\n" +
            "UNDO_DEPTH ${state.undoDepth}\nREDO_DEPTH ${state.redoDepth}\n" +
            "RETAINED_BYTES ${state.retainedSerializedBytes}\nTRANSACTION_LIMIT ${state.maximumTransactions}\n" +
            "BYTE_LIMIT ${state.maximumSerializedBytes}\nPENDING_TOKEN ${state.pendingToken}\n" +
            "PENDING_ACTION ${if (state.pendingAction.size > 0) { state.pendingAction } else { "none" }}\n" +
            "UNDO_REASON_HEX ${undo}\nREDO_REASON_HEX ${redo}\nBOUNDARY_REASON_HEX ${boundary}\nEND"
    }

    public func handleHistoryAction(action: String, expectedVersion: Int64,
        expectedDigest: String, expectedEpoch!: Int64 = -1): CjguiUiDocumentSessionResult {
        return sessionValue.historyAction(surfaceValue, action, expectedVersion, expectedDigest,
            expectedEpoch: expectedEpoch)
    }

    public func resetHistory(expectedVersion: Int64, expectedDigest: String): CjguiUiDocumentSessionResult {
        return sessionValue.resetHistory(surfaceValue, expectedVersion, expectedDigest)
    }

    public func closeHistory(): Unit {
        sessionValue.closeHistory(surfaceValue)
        surfaceValue.detachUiDocumentWorkspace(this)
    }

    public func commandId(action: String): String {
        for (entry in CjguiUiDocumentWorkspace.addressableEntries()) {
            if (entry.action == action) {
                return "${commandPrefixValue}.${entry.suffix}"
            }
        }
        if (action == CJGUI_UI_DOCUMENT_ACTION_OPEN) {
            return pathCommandId()
        }
        if (action == CJGUI_UI_DOCUMENT_ACTION_SAVE_AS) {
            return pathCommandId(open: false)
        }
        return commandPrefixValue
    }

    /// MANUAL constructor only: numeric button node id. A scoped workspace
    /// has no numeric id before the accepted scene resolves its identities.
    public func nodeId(action: String): Int64 {
        for (entry in CjguiUiDocumentWorkspace.addressableEntries()) {
            if (entry.action == action) {
                return nodeBaseValue + entry.nodeOffset
            }
        }
        if (action == CJGUI_UI_DOCUMENT_ACTION_OPEN) {
            return nodeBaseValue + 12
        }
        if (action == CJGUI_UI_DOCUMENT_ACTION_SAVE_AS) {
            return nodeBaseValue + 13
        }
        return nodeBaseValue
    }

    /// The command target for one action: a scoped reference below the
    /// workspace scope for scoped mounts, the manual numeric id otherwise.
    public func nodeReference(action: String): CjguiComposableUiNodeReference {
        match (scopedValue) {
            case Some(scope) =>
                for (entry in CjguiUiDocumentWorkspace.addressableEntries()) {
                    if (entry.action == action) {
                        return CjguiComposableUiNodeReference.scoped(scope, entry.suffix)
                    }
                }
                if (action == CJGUI_UI_DOCUMENT_ACTION_OPEN) {
                    return CjguiComposableUiNodeReference.scoped(scope, "open")
                }
                if (action == CJGUI_UI_DOCUMENT_ACTION_SAVE_AS) {
                    return CjguiComposableUiNodeReference.scoped(scope, "save-as")
                }
                return CjguiComposableUiNodeReference.scoped(scope, "root")
            case None => return CjguiComposableUiNodeReference.manual(nodeId(action))
        }
    }

    /// Exact command routing over derived command ids. Two mounted workspaces
    /// never answer the same command id, and a bare action token
    /// (`UI_DOC_SAVE`) is not a command id for either branch.
    public func ownsCommand(commandId: String): Bool {
        for (suffix in ["save", "preview", "confirm", "cancel", "restore", "open", "save-as", "undo", "redo"]) {
            if (commandId == "${commandPrefixValue}.${suffix}") {
                return true
            }
        }
        return false
    }

    public func handleCommand(commandId: String): ?CjguiUiDocumentSessionResult {
        for (entry in CjguiUiDocumentWorkspace.addressableEntries()) {
            if (commandId == "${commandPrefixValue}.${entry.suffix}") {
                return handleAction(entry.action)
            }
        }
        return None
    }

    /// The command id of the path-row actions (open / save-as).
    public func pathCommandId(open!: Bool = true): String {
        return if (open) {
            "${commandPrefixValue}.open"
        } else {
            "${commandPrefixValue}.save-as"
        }
    }

    /// Executes a path-row command with the consumer's CURRENT path string.
    /// Open previews the file as one merge operation; save-as writes through
    /// the same protected write path as an ordinary save.
    public func handlePathCommand(commandId: String, path: String): ?CjguiUiDocumentSessionResult {
        if (commandId == pathCommandId()) {
            return Some(sessionValue.previewReloadPath(surfaceValue, path, policy: CJGUI_UI_DOCUMENT_POLICY_MERGE))
        }
        if (commandId == pathCommandId(open: false)) {
            return Some(sessionValue.saveAs(surfaceValue, path))
        }
        return None
    }

    /// The common command projection, derived from the REAL session action
    /// states: enabled/disabled facts and their reasons come from the same
    /// source the built buttons read. Toolbars, palettes, menus and ordinary
    /// buttons consume this one declaration set instead of each consumer
    /// re-deriving entries -> commands.
    public func commandDeclarations(menuGroup!: String = "File"): ArrayList<CjguiComposableUiCommand> {
        let result = ArrayList<CjguiComposableUiCommand>()
        for (entry in mountedEntries()) {
            let state = actionState(entry.action)
            let enabled = match (state) {
                case Some(value) => value.enabled
                case None => false
            }
            result.add(
                CjguiComposableUiCommand(commandId(entry.action), nodeReference(entry.action), entry.label, menuGroup, 0,
                    enabled, false))
        }
        // The always-available file entries belong to the same projection;
        // their targets are the real path-row buttons, so a menu/palette
        // invocation reaches the SAME workspace and path entry as a click.
        result.add(
            CjguiComposableUiCommand(commandId(CJGUI_UI_DOCUMENT_ACTION_OPEN),
                nodeReference(CJGUI_UI_DOCUMENT_ACTION_OPEN), "打开界面", menuGroup, 1, true, false))
        result.add(
            CjguiComposableUiCommand(commandId(CJGUI_UI_DOCUMENT_ACTION_SAVE_AS),
                nodeReference(CJGUI_UI_DOCUMENT_ACTION_SAVE_AS), "界面另存", menuGroup, 2, true, false))
        return result
    }

    /// Presentation metadata matching `commandDeclarations`. The action token
    /// stays the public action name; the command id is the routing key.
    public func commandMetadata(resourceId: Int64): ArrayList<CjguiCommandToolbarMetadata> {
        let result = ArrayList<CjguiCommandToolbarMetadata>()
        for (entry in mountedEntries()) {
            let state = actionState(entry.action)
            let reason = match (state) {
                case Some(value) => value.disabledReason
                case None => "界面会话不可用"
            }
            result.add(
                CjguiCommandToolbarMetadata(commandId(entry.action), entry.action, resourceId, detail: entry.label,
                    disabledReason: reason))
        }
        result.add(
            CjguiCommandToolbarMetadata(commandId(CJGUI_UI_DOCUMENT_ACTION_OPEN), CJGUI_UI_DOCUMENT_ACTION_OPEN,
                resourceId, detail: "打开界面"))
        result.add(
            CjguiCommandToolbarMetadata(commandId(CJGUI_UI_DOCUMENT_ACTION_SAVE_AS), CJGUI_UI_DOCUMENT_ACTION_SAVE_AS,
                resourceId, detail: "界面另存"))
        return result
    }

    public func open(path: String, policy!: String = CJGUI_UI_DOCUMENT_POLICY_MERGE): CjguiUiDocumentSessionResult {
        return sessionValue.previewReloadPath(surfaceValue, path, policy: policy)
    }

    /// One ordinary startup file operation. The session owns its Surface,
    /// preview, real file observation and exact ticket; no extra pump is made.
    public func beginStartup(path: String, policy!: String = CJGUI_UI_DOCUMENT_POLICY_REPLACE): CjguiUiDocumentSessionResult {
        return sessionValue.beginStartup(surfaceValue, path, policy: policy)
    }

    public func startupPending(): Bool {
        return sessionValue.startupPending(surfaceValue)
    }

    /// Retains the startup outcome even when closeGuard.finish consumed it
    /// before the next ordinary turn. It never adopts a baseline a second time.
    public func startupResult(): CjguiUiDocumentSessionResult {
        return sessionValue.startupResult(surfaceValue)
    }

    public func saveAs(path: String): CjguiUiDocumentSessionResult {
        return sessionValue.saveAs(surfaceValue, path)
    }

    public func closeDecision(): CjguiUiDocumentCloseDecision {
        return sessionValue.closeDecision(surfaceValue)
    }

    public func actionState(action: String): ?CjguiUiDocumentActionState {
        for (state in sessionValue.actionStates(surfaceValue)) {
            if (state.action == action) {
                return Some(state)
            }
        }
        return None
    }

    /// MANUAL-constructor convenience: recognizes the bare action token the
    /// manual build() puts on buttons. Scoped buttons carry the
    /// `CJGUICOMMAND:` activation action instead and route through
    /// `ownsCommand`/`handleCommand`.
    public func isAction(actionName: String): Bool {
        for (entry in CjguiUiDocumentWorkspace.addressableEntries()) {
            if (entry.action == actionName) {
                return true
            }
        }
        return false
    }

    /// Maps one public action to the session. Restore is an explicit REPLACE
    /// preview followed by the ordinary confirm; it never silently reports a
    /// merge as a full restore.
    public func handleAction(actionName: String): ?CjguiUiDocumentSessionResult {
        if (actionName == CJGUI_UI_DOCUMENT_ACTION_UNDO || actionName == CJGUI_UI_DOCUMENT_ACTION_REDO) {
            return Some(sessionValue.performHistoryAction(surfaceValue, actionName))
        }
        if (actionName == CJGUI_UI_DOCUMENT_ACTION_SAVE) {
            return Some(sessionValue.save(surfaceValue))
        }
        if (actionName == CJGUI_UI_DOCUMENT_ACTION_PREVIEW) {
            return Some(sessionValue.previewReload(surfaceValue, policy: CJGUI_UI_DOCUMENT_POLICY_MERGE))
        }
        if (actionName == CJGUI_UI_DOCUMENT_ACTION_CONFIRM) {
            return Some(sessionValue.confirmReload(surfaceValue))
        }
        if (actionName == CJGUI_UI_DOCUMENT_ACTION_CANCEL) {
            return Some(sessionValue.cancelPreview())
        }
        if (actionName == CJGUI_UI_DOCUMENT_ACTION_RESTORE) {
            let preview = sessionValue.previewReload(surfaceValue, policy: CJGUI_UI_DOCUMENT_POLICY_REPLACE)
            if (!preview.applied) {
                return Some(preview)
            }
            return Some(sessionValue.confirmReload(surfaceValue))
        }
        return None
    }

    /// One normal-turn query. Returns the REAL settlement; consumers log
    /// `accepted` only when `accepted` is true, not for every terminal change.
    public func finish(): CjguiUiDocumentSessionResult {
        return sessionValue.finishReload(surfaceValue)
    }

    public func statusText(): String {
        return sessionValue.statusTextFor(surfaceValue)
    }

    public func previewText(): String {
        return sessionValue.previewText()
    }

    /// Builds the ordinary text/button composition. The caller owns layout,
    /// theme, business owner id and navigation. A MANUAL workspace allocates
    /// only the numeric node ids it was given; a SCOPED workspace gives every
    /// node `identity: scope.local(...)` (node id -1 until the accepted scene
    /// resolves it) and each button carries the public
    /// `CJGUICOMMAND:<commandId>` activation action, so the actual built
    /// button routes into THIS workspace instead of a bare global action.
    public func build(nodeStyle: CjguiComposableUiStyle, titleStyle: CjguiComposableUiStyle,
        bodyStyle: CjguiComposableUiStyle, buttonStyle: CjguiComposableUiStyle,
        interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
        ownerResourceId!: Int64 = -1): CjguiComposableUiNode {
        match (scopedValue) {
            case Some(scope) => return buildScoped(scope, nodeStyle, titleStyle, bodyStyle, buttonStyle,
                interactionStyle: interactionStyle, ownerResourceId: ownerResourceId)
            case None => return buildManual(nodeStyle, titleStyle, bodyStyle, buttonStyle,
                interactionStyle: interactionStyle, ownerResourceId: ownerResourceId)
        }
    }

    private func buildScoped(scope: CjguiComposableUiIdentityScope, nodeStyle: CjguiComposableUiStyle,
        titleStyle: CjguiComposableUiStyle, bodyStyle: CjguiComposableUiStyle, buttonStyle: CjguiComposableUiStyle,
        interactionStyle!: CjguiComposableUiInteractionStyle, ownerResourceId!: Int64): CjguiComposableUiNode {
        let container = CjguiComposableUiNode(-1, semanticPrefixValue, CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1,
            CjguiComposableUiStyle(gap: 6, padding: 10, growX: 1, border: nodeStyle.border,
                borderWidth: nodeStyle.borderWidth, cornerRadius: nodeStyle.cornerRadius,
                background: nodeStyle.background), identity: Some(scope.local("root")))
        container.add(
            cjguiComposableText(-1, "${semanticPrefixValue}-title", titleValue, titleStyle,
                identity: Some(scope.local("title"))))
        let bar = CjguiComposableUiNode(-1, "${semanticPrefixValue}-actions", CJGUI_COMPOSABLE_UI_HORIZONTAL, "", "", "",
            -1, CjguiComposableUiStyle(gap: 6),
            layoutSpec: Some(CjguiComposableUiLayoutSpec(CJGUI_COMPOSABLE_UI_LAYOUT_WRAP, rowGap: 4)),
            identity: Some(scope.local("actions")))
        for (entry in mountedEntries()) {
            let state = actionState(entry.action)
            let enabled = match (state) {
                case Some(value) => value.enabled
                case None => false
            }
            let help = match (state) {
                case Some(value) => value.disabledReason
                case None => ""
            }
            // The REAL built button asks for THIS workspace's command; the
            // consumer routes the activation through the window command entry
            // (or directly when the command is not declared), then the
            // arrival executes the owner action below the same scope.
            bar.add(
                cjguiComposableButton(-1, "${semanticPrefixValue}-${entry.suffix}", entry.label,
                    cjguiCommandToolbarActivationAction(commandId(entry.action)), ownerResourceId, buttonStyle,
                    enabled: enabled, interactionStyle: interactionStyle, semanticHelp: help,
                    identity: Some(scope.local(entry.suffix))))
        }
        container.add(bar)
        // Status and preview are ordinary wrapped text in the same scrollable
        // content, so a long path, reason or diff stays readable in a narrow
        // window instead of being clipped into one line.
        container.add(
            cjguiComposableText(-1, "${semanticPrefixValue}-status", statusText(),
                CjguiComposableUiStyle(fontSize: 12.5, textColor: bodyStyle.textColor, lineHeight: 18.0),
                identity: Some(scope.local("status"))))
        let preview = previewText()
        if (preview.size > 0) {
            // The action button already owns local key "preview"; the preview
            // body is a different node with its own stable identity.
            container.add(
                cjguiComposableText(-1, "${semanticPrefixValue}-preview-text", preview,
                    CjguiComposableUiStyle(fontSize: 12.5, textColor: bodyStyle.textColor, lineHeight: 18.0),
                    identity: Some(scope.local("preview-text"))))
        }
        return container
    }

    private func buildManual(nodeStyle: CjguiComposableUiStyle, titleStyle: CjguiComposableUiStyle,
        bodyStyle: CjguiComposableUiStyle, buttonStyle: CjguiComposableUiStyle,
        interactionStyle!: CjguiComposableUiInteractionStyle, ownerResourceId!: Int64): CjguiComposableUiNode {
        let container = cjguiComposableVertical(nodeBaseValue, semanticPrefixValue,
            CjguiComposableUiStyle(gap: 6, padding: 10, growX: 1, border: nodeStyle.border,
                borderWidth: nodeStyle.borderWidth, cornerRadius: nodeStyle.cornerRadius,
                background: nodeStyle.background))
        container.add(cjguiComposableText(nodeBaseValue + 1, "${semanticPrefixValue}-title", titleValue, titleStyle))
        let bar = cjguiComposableWrap(nodeBaseValue + 2, "${semanticPrefixValue}-actions",
            CjguiComposableUiStyle(gap: 6), rowGap: 4)
        for (entry in mountedEntries()) {
            let state = actionState(entry.action)
            let enabled = match (state) {
                case Some(value) => value.enabled
                case None => false
            }
            let help = match (state) {
                case Some(value) => value.disabledReason
                case None => ""
            }
            bar.add(
                cjguiComposableButton(nodeBaseValue + entry.nodeOffset, "${semanticPrefixValue}-${entry.action}",
                    entry.label, entry.action, ownerResourceId, buttonStyle, enabled: enabled,
                    interactionStyle: interactionStyle, semanticHelp: help))
        }
        container.add(bar)
        container.add(
            cjguiComposableText(nodeBaseValue + 8, "${semanticPrefixValue}-status", statusText(),
                CjguiComposableUiStyle(fontSize: 12.5, textColor: bodyStyle.textColor, lineHeight: 18.0)))
        let preview = previewText()
        if (preview.size > 0) {
            container.add(
                cjguiComposableText(nodeBaseValue + 9, "${semanticPrefixValue}-preview", preview,
                    CjguiComposableUiStyle(fontSize: 12.5, textColor: bodyStyle.textColor, lineHeight: 18.0)))
        }
        return container
    }

    /// The ordinary path row for open / save-as: one text field plus two
    /// buttons, all with the same scoped identity discipline as the main
    /// panel. The path STRING stays application-owned: the consumer reads
    /// TEXT_CHANGED from `pathFieldSemanticId()` and passes its current value
    /// when a path command arrives. No hidden default path is invented here.
    public func buildPathRow(pathValue: String, inputStyle: CjguiComposableUiStyle, buttonStyle: CjguiComposableUiStyle,
        interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
        ownerResourceId!: Int64 = -1,
        inputInteractionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle()): CjguiComposableUiNode {
        match (scopedValue) {
            case Some(scope) =>
                let row = CjguiComposableUiNode(-1, "${semanticPrefixValue}-path-row", CJGUI_COMPOSABLE_UI_HORIZONTAL,
                    "", "", "", -1, CjguiComposableUiStyle(fixedHeight: 34, gap: 8),
                    identity: Some(scope.local("path-row")))
                row.add(
                    CjguiComposableUiNode(-1, "${semanticPrefixValue}-path", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
                        "界面文件路径", pathValue, "EDIT_TEXT", -1, inputStyle, fieldId: "ui-document-path",
                        displayValueRole: "draft", interactionStyle: inputInteractionStyle,
                        identity: Some(scope.local("path"))))
                row.add(
                    cjguiComposableButton(-1, "${semanticPrefixValue}-open", "打开界面",
                        cjguiCommandToolbarActivationAction(pathCommandId()), ownerResourceId, buttonStyle,
                        interactionStyle: interactionStyle, identity: Some(scope.local("open"))))
                row.add(
                    cjguiComposableButton(-1, "${semanticPrefixValue}-save-as", "界面另存",
                        cjguiCommandToolbarActivationAction(pathCommandId(open: false)), ownerResourceId, buttonStyle,
                        interactionStyle: interactionStyle, identity: Some(scope.local("save-as"))))
                return row
            case None =>
                let row = cjguiComposableHorizontal(nodeBaseValue + 10, "${semanticPrefixValue}-path-row",
                    CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
                row.add(
                    cjguiComposableTextInput(nodeBaseValue + 11, "${semanticPrefixValue}-path", "界面文件路径",
                        pathValue, -1, inputStyle, displayValueRole: "draft", interactionStyle: inputInteractionStyle))
                row.add(
                    cjguiComposableButton(nodeBaseValue + 12, "${semanticPrefixValue}-open", "打开界面",
                        CJGUI_UI_DOCUMENT_ACTION_OPEN, ownerResourceId, buttonStyle, interactionStyle: interactionStyle))
                row.add(
                    cjguiComposableButton(nodeBaseValue + 13, "${semanticPrefixValue}-save-as", "界面另存",
                        CJGUI_UI_DOCUMENT_ACTION_SAVE_AS, ownerResourceId, buttonStyle,
                        interactionStyle: interactionStyle))
                return row
        }
    }
}

/// Shared close coordination for every document workspace mounted in one
/// window. The application keeps the final business decision and the actual
/// window close; this guard only settles document facts honestly and offers
/// the ordinary save / discard / cancel actions. It never writes business
/// data, never applies a business draft, and never invents a path.
public class CjguiUiDocumentCloseGuard {
    private let workspaces = ArrayList<CjguiUiDocumentWorkspace>()
    /// ONE-SHOT: the user chose "discard UI changes and close". Unsaved UI
    /// facts stop blocking that close attempt, but any pending ticket still
    /// refuses; the flag is consumed by the next report so a later close after
    /// a cancelled business policy cannot silently discard again.
    private var discardUnsavedOnce = false

    public init() {}

    public func add(workspace: CjguiUiDocumentWorkspace): Unit {
        workspaces.add(workspace)
    }

    public func workspaceCount(): Int64 {
        return workspaces.size
    }

    public func discardUnsaved(): Unit {
        discardUnsavedOnce = true
    }

    /// Settles submitted tickets through their own surfaces, cancels
    /// uncommitted previews, then reports whether UI-document facts still
    /// block closing. Returns "" when every workspace is clean; otherwise one
    /// visible summary naming the first blocking fact. A ticket with no
    /// visible settlement is an explicit refusal to leave, never a silent
    /// rollback.
    public func settleAndReport(): String {
        let discardUnsaved = discardUnsavedOnce
        discardUnsavedOnce = false
        for (workspace in workspaces) {
            let state = workspace.session().stateFor(workspace.surface())
            if (state.mode == "submitted") {
                let settled = workspace.finish()
                if (settled.reason == "ui_document_pending" || settled.reason == "ui_document_ticket_mismatch") {
                    return "${workspace.title()}：界面载入仍在结算" +
                        "（${settled.reason}），请稍后重试或取消关闭"
                }
            }
        }
        for (workspace in workspaces) {
            let state = workspace.session().stateFor(workspace.surface())
            if (state.mode == "preview") {
                let _ = workspace.session().cancelPreview()
            }
        }
        for (workspace in workspaces) {
            let state = workspace.session().stateFor(workspace.surface())
            if (state.mode == "mismatch") {
                return "${workspace.title()}：界面会话与区域身份不符（ui_document_surface_mismatch）"
            }
        }
        if (discardUnsaved) {
            return ""
        }
        for (workspace in workspaces) {
            let decision = workspace.closeDecision()
            if (!decision.canClose) {
                if (decision.reason == "ui_document_unsaved") {
                    return "${workspace.title()}：有未保存界面变更"
                }
                return "${workspace.title()}：${decision.reason}"
            }
        }
        return ""
    }

    /// The "save UI" action: saves every unsaved workspace through the SAME
    /// protected write path as an ordinary save. A workspace without a path
    /// association uses `pathFor` (the consumer's path entry); an empty
    /// answer is a refusal asking the user to type a path, never a hidden
    /// default. Returns "" when every save settled.
    public func saveUnsaved(pathFor: (CjguiUiDocumentWorkspace) -> String): String {
        for (workspace in workspaces) {
            let state = workspace.session().stateFor(workspace.surface())
            if (state.mode == "preview") {
                let _ = workspace.session().cancelPreview()
            }
        }
        for (workspace in workspaces) {
            let state = workspace.session().stateFor(workspace.surface())
            if (!state.unsaved) {
                continue
            }
            let result = if (state.path.size > 0) {
                workspace.session().save(workspace.surface())
            } else {
                let path = pathFor(workspace)
                if (path.size == 0) {
                    return "ui_document_path_empty"
                }
                workspace.session().saveAs(workspace.surface(), path)
            }
            if (!result.applied) {
                return result.reason
            }
        }
        return ""
    }
}

/// Experimental provider adapter for an existing UI-document workspace.
/// Custom/handwritten consumers and the standard generated region share this
/// mount and protocol projection. The workspace/session remains the sole
/// history owner; this adapter has no history, candidate queue or writer.
public class CjguiUiDocumentHistoryAccess {
    private let surfaceValue: CjguiUiDocumentSurface
    private let lock = Mutex()
    private var workspaceValue: ?CjguiUiDocumentWorkspace = None

    public init(surface: CjguiUiDocumentSurface) { surfaceValue = surface }

    public static func capabilitiesPayload(described: String): String {
        return described[0..described.size - 3] +
            "UI_DOCUMENT_HISTORY version=1 supported=1 stability=experimental scope=session\nEND"
    }

    public func attach(workspace: CjguiUiDocumentWorkspace): String {
        if (workspace.surface().uiDocumentSurfaceIdentity() != surfaceValue.uiDocumentSurfaceIdentity()) {
            return "ui_document_surface_mismatch"
        }
        if (!workspace.historyState().enabled) { return "ui_document_history_disabled" }
        return synchronized(lock) {
            if (let Some(previous) <- workspaceValue) {
                if (refEq(previous.session(), workspace.session()) &&
                    previous.semanticPrefix() == workspace.semanticPrefix()) { return "" }
                return "ui_document_workspace_already_attached"
            }
            workspaceValue = Some(workspace)
            ""
        }
    }

    public func detach(workspace: CjguiUiDocumentWorkspace): Unit {
        synchronized(lock) {
            if (let Some(previous) <- workspaceValue) {
                if (refEq(previous.session(), workspace.session())) { workspaceValue = None }
            }
        }
    }

    public func payload(): String {
        let workspace = synchronized(lock) { workspaceValue }
        if (let Some(value) <- workspace) { return value.historyPayload() }
        let reason = CjguiSharedOperationFrame.encodeUtf8Hex("ui_document_history_disabled")
        return "UI_DOCUMENT_HISTORY 1\nSUPPORTED 1\nENABLED false\n" +
            "SURFACE_ID ${surfaceValue.uiDocumentSurfaceIdentity()}\nCAN_UNDO false\nCAN_REDO false\n" +
            "UNDO_REASON_HEX ${reason}\nREDO_REASON_HEX ${reason}\nEND"
    }

    public func submit(action: String, expectedVersion: Int64, expectedDigest: String,
        surfaceIdentity: Int64, historyEpoch: Int64): CjguiSharedOperationGeneratedUiSubmit {
        let before = surfaceValue.acceptedUiDocumentVersion()
        if (surfaceIdentity != surfaceValue.uiDocumentSurfaceIdentity()) {
            return CjguiSharedOperationGeneratedUiSubmit(false, "ui_document_surface_mismatch", "", before, before)
        }
        let workspace = synchronized(lock) { workspaceValue }
        let value = match (workspace) {
            case Some(mounted) => mounted
            case None => return CjguiSharedOperationGeneratedUiSubmit(false, "ui_document_history_disabled", "", before, before)
        }
        let result = value.handleHistoryAction(action, expectedVersion, expectedDigest, expectedEpoch: historyEpoch)
        return CjguiSharedOperationGeneratedUiSubmit(result.submitted, result.reason, "", before,
            surfaceValue.acceptedUiDocumentVersion(), sceneAccepted: false,
            // The submitted plan owns this version. A later candidate cannot
            // lend its current version to this operation's receipt.
            candidateVersion: if (result.submitted) { result.version } else { 0 },
            candidateToken: result.token,
            receipt: if (result.token > 0) { CjguiGeneratedUiStructureHolder.receiptForToken(result.token) } else { "none" })
    }
}

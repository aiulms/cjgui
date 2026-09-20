// First runtime-generated-UI consumer: the rule window keeps its handwritten
// navigation and adds one generated region. The application registers the
// components/fields/actions it exposes; external clients query capabilities,
// read the accepted structure and submit candidates over the existing
// connection, and the generated fields stay bound to the existing rule owner
// (drafts, validation, CAS and apply/cancel are unchanged).
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.sync.*
import std.env.*

public class CjguiRuleSetGeneratedRegion <: CjguiGeneratedUiBindingProvider &
    CjguiSharedOperationGeneratedUiProvider {
    private let domain: CjguiRuleSetEditingDomain
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    private let holder: CjguiGeneratedUiStructureHolder
    private let lock: Mutex
    private var lastOutcome: String
    private var observedStructureVersion: Int64
    private var revisionValue: Int64

    public init(domain: CjguiRuleSetEditingDomain) {
        this.domain = domain
        this.lock = Mutex()
        this.catalog = CjguiRuleSetGeneratedRegion.buildCatalog(domain)
        this.holder = CjguiGeneratedUiStructureHolder(catalog,
            rootScope: CjguiComposableUiIdentityScope("rule-generated"))
        this.lastOutcome = "尚未提交生成结构"
        this.observedStructureVersion = 0
        this.revisionValue = 1
    }

    /// The generated capability catalog is derived from the application's own
    /// definitions: the components/actions this window actually presents, and
    /// the field list from the *existing shared form binding* the handwritten
    /// form already uses. There is no second, hand-maintained field list, so a
    /// field cannot be named "retention" in one place and "retentionCount" in
    /// another.
    static func buildCatalog(domain: CjguiRuleSetEditingDomain): CjguiGeneratedUiCapabilityCatalog {
        let catalog = CjguiGeneratedUiCapabilityCatalog()
        let containerProperties = ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32),
            CjguiGeneratedUiPropertySpec("padding", "INTEGER", minimum: 0, maximum: 32)
        ])
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical", containerProperties, true, childLimit: 64))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("horizontal", containerProperties, true, childLimit: 64))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 200)
        ]), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput", ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 100)
        ]), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("integerInput", ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 100)
        ]), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("booleanInput", ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 100)
        ]), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action", ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60),
            CjguiGeneratedUiPropertySpec("action", "STRING", maxLength: 60)
        ]), false))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("APPLY_DRAFT", "应用草稿"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("CANCEL_DRAFT", "取消草稿"))
        // One definition: the domain's shared form binding (the same object the
        // handwritten form field list and the external field read come from).
        let _ = catalog.registerFields(CjguiGeneratedUiFieldSpec.fromFormBinding(domain.formBinding()))
        return catalog
    }

    public func revision(): Int64 {
        return synchronized(lock) { revisionValue }
    }

    public func statusText(): String {
        return synchronized(lock) { lastOutcome }
    }

    /// Field metadata comes from the single derived field definition; there is
    /// no per-field if-chain here.
    private func fieldSpec(fieldId: String): ?CjguiGeneratedUiFieldSpec {
        return catalog.fieldFor(fieldId)
    }

    private func resourceIdForField(fieldId: String): Int64 {
        if (let Some(spec) <- fieldSpec(fieldId)) {
            return spec.resourceId
        }
        return -1
    }

    // --- binding provider: live field reads and real action execution -------

    public func fieldResourceId(fieldId: String): Int64 {
        return resourceIdForField(fieldId)
    }

    /// The generated field edits the record currently selected in the domain
    /// at projection time; the accepted node carries this target so a late
    /// event writes the record it was rendered for, never a later selection.
    public func fieldOperationResourceId(fieldId: String): Int64 {
        if (resourceIdForField(fieldId) < 0) { return -1 }
        return domain.selectedRecordId()
    }

    public func draftText(fieldId: String): String {
        let resourceId = resourceIdForField(fieldId)
        if (resourceId < 0) { return "" }
        return domain.formSnapshot().fieldForResourceId(resourceId).draftText
    }

    public func appliedText(fieldId: String): String {
        let resourceId = resourceIdForField(fieldId)
        if (resourceId < 0) { return "" }
        let field = domain.formSnapshot().fieldForResourceId(resourceId)
        return field.appliedValue.stringValue
    }

    public func draftBoolean(fieldId: String): ?Bool {
        let resourceId = resourceIdForField(fieldId)
        if (resourceId < 0) { return None }
        let field = domain.formSnapshot().fieldForResourceId(resourceId)
        if (field.appliedValue.valueType == "BOOLEAN") {
            // A boolean field reads its live draft from the domain projection:
            // the form snapshot exposes the applied value and the draft text.
            return Some(field.draftText == "true" || (field.draftText.size == 0 && field.appliedValue.booleanValue))
        }
        return None
    }

    public func actionAvailable(actionName: String): Bool {
        if (actionName == "APPLY_DRAFT" || actionName == "CANCEL_DRAFT") {
            return domain.selectedRecordId() >= 0
        }
        return false
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        let selected = domain.selectedRecordId()
        if (selected < 0) {
            return CjguiGeneratedUiActionResult(false, "no_selected_record")
        }
        let version = domain.formSnapshot().appliedConfigVersion
        let draftVersion = domain.selectedDraftVersion()
        let arguments = ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("expectedDraftVersion",
                CjguiSharedOperationValue.integer(draftVersion))
        ])
        let invocation = CjguiSharedOperationActionInvocation(actionName, version,
            ArrayList<Int64>([selected]), arguments)
        let result = domain.executeFromHuman(invocation)
        let outcome = if (result.applied) {
            "${actionName} 已应用 → v${result.versionAfter}"
        } else {
            "${actionName} 被拒：${result.reason}"
        }
        synchronized(lock) {
            lastOutcome = outcome
            revisionValue += 1
        }
        return CjguiGeneratedUiActionResult(result.applied, result.reason)
    }

    // --- external structure provider ---------------------------------------

    public func capabilitiesPayload(): String {
        return CjguiGeneratedUiEncoding.describe(catalog)
    }

    /// Live field projections from the same shared form binding the
    /// handwritten form uses: draft text, applied value, validation, focus and
    /// selection. Hex encoding keeps arbitrary text on one protocol line.
    public func fieldsPayload(): String {
        let form = domain.formSnapshot()
        let builder = StringBuilder()
        // The published field order is the catalog's own order, derived from the
        // application form binding - not a second hand-written list.
        for (fieldId in catalog.fieldIds()) {
            let resourceId = resourceIdForField(fieldId)
            if (resourceId < 0) { continue }
            let field = form.fieldForResourceId(resourceId)
            // One encoding for every value kind, from the shared definition:
            // a boolean published through `stringValue` was empty to an
            // external reader even when the business value was set.
            builder.append("FIELD ${fieldId} ${resourceId} DRAFT_HEX ${hexEncode(field.draftText)} " +
                "APPLIED_HEX ${hexEncode(field.appliedValue.displayText())} " +
                "ERROR ${if (field.validationError.size > 0) { field.validationError } else { "none" }} " +
                "FOCUS ${if (field.isFocused) { 1 } else { 0 }} " +
                "SELECTION ${field.selectionStart} ${field.selectionEnd} " +
                "VERSION ${field.draftFieldVersion}\n")
        }
        builder.append("END")
        return builder.toString()
    }

    private func hexEncode(text: String): String {
        if (text.size == 0) { return "-" }
        let digits = "0123456789ABCDEF"
        let builder = StringBuilder()
        for (byte in text.toArray()) {
            let value = Int64(byte)
            builder.append(digits[(value / 16)..(value / 16 + 1)])
            builder.append(digits[(value % 16)..(value % 16 + 1)])
        }
        return builder.toString()
    }

    public func acceptedStructurePayload(): String {
        return synchronized(lock) {
            CjguiGeneratedUiEncoding.encode(holder.acceptedStructure(), holder.structureVersion())
        }
    }

    public func acceptedStructureVersion(): Int64 {
        return synchronized(lock) { holder.structureVersion() }
    }

    /// Node identity of an accepted generated key (negative when that key is
    /// not part of the accepted structure). This application's own tests use it
    /// to address the accepted editor exactly as a delivered input event would;
    /// it allocates nothing and changes no state.
    public func acceptedNodeIdForKey(key: String): Int64 {
        return synchronized(lock) { holder.nodeIdForKey(key) }
    }

    /// Version the received-but-uncommitted candidate would install once the
    /// window's scene transaction accepts it.
    public func candidateStructureVersion(): Int64 {
        return synchronized(lock) { holder.candidateStructureVersion() }
    }

    /// Scene acceptance state of the last candidate, so an external reader can
    /// distinguish "candidate received" from "interface displayed".
    public func sceneState(): String {
        return synchronized(lock) { holder.lastSceneOutcome() }
    }

    public func submitStructure(candidatePayload: String, expectedVersion: Int64):
        CjguiSharedOperationGeneratedUiSubmit {
        let decoded = CjguiGeneratedUiEncoding.decode(candidatePayload)
        if (!decoded.ok) {
            return CjguiSharedOperationGeneratedUiSubmit(false, decoded.reason, "", expectedVersion, expectedVersion)
        }
        let root = match (decoded.root) {
            case Some(value) => value
            case None => return CjguiSharedOperationGeneratedUiSubmit(false, "empty_structure", "", expectedVersion,
                expectedVersion)
        }
        return synchronized(lock) {
            // Structure CAS: a candidate built against another structure
            // version is rejected; the accepted interface stays in place.
            let current = holder.structureVersion()
            if (expectedVersion != current) {
                lastOutcome = "结构版本冲突：期望 ${expectedVersion}，当前 ${current}"
                return CjguiSharedOperationGeneratedUiSubmit(false, "structure_version_conflict", "",
                    current, current)
            }
            let result = holder.submit(root, this)
            if (!result.candidateAccepted) {
                lastOutcome = "结构被拒：${result.reason} @${result.path}"
            } else {
                // The candidate is received but NOT yet the accepted interface:
                // the window must accept the scene before the external read
                // advances, and that refresh is requested here.
                lastOutcome = "候选已接收 v${result.candidateVersion}，等待场景接受"
                revisionValue += 1
            }
            return CjguiSharedOperationGeneratedUiSubmit(result.candidateAccepted, result.reason,
                result.path, result.structureVersionBefore, result.structureVersionAfter,
                sceneAccepted: result.sceneAccepted, candidateVersion: result.candidateVersion)
        }
    }

    // --- window scene-refresh transaction ----------------------------------
    // The generated candidate, its component identities and its binding table
    // take effect together with the window's accepted scene. Until the commit
    // hook runs, the public accepted structure/version and the event routing
    // table are exactly what they were.

    public func beginSceneRefresh(): Bool {
        return synchronized(lock) { holder.beginCandidateRefresh() }
    }

    public func prepareSceneRefresh(): Bool {
        return synchronized(lock) { holder.prepareCandidateRefresh() }
    }

    public func commitSceneRefresh(): Unit {
        synchronized(lock) {
            // An ordinary refresh has no candidate: it must not advance this
            // region's revision, or the window would keep rebuilding itself.
            if (!holder.hasPendingCandidate()) {
                return
            }
            if (holder.commitCandidateRefresh()) {
                lastOutcome = "结构已接受：v${holder.structureVersion()}"
            } else {
                lastOutcome = "场景拒绝：${holder.lastSceneOutcome()}"
            }
            revisionValue += 1
        }
    }

    public func rollbackSceneRefresh(): Unit {
        synchronized(lock) {
            if (!holder.hasPendingCandidate()) {
                return
            }
            holder.rollbackCandidateRefresh()
            lastOutcome = "场景拒绝：${holder.lastSceneOutcome()}"
            revisionValue += 1
        }
    }

    // --- window section + event routing ------------------------------------

    public func buildSection(theme: CjguiComposableUiTheme, bodyStyle: CjguiComposableUiStyle): CjguiComposableUiNode {
        let section = cjguiComposableVertical(700200, "rule-generated-section",
            CjguiComposableUiStyle(padding: 8, gap: 6,
                background: theme.card.background, border: theme.card.border))
        section.add(cjguiComposableText(700201, "rule-generated-title",
            "生成区域 · 结构 v${holder.structureVersion()}", CjguiComposableUiStyle(fontSize: 14.0)))
        // Inside a refresh transaction this builds the pending candidate;
        // outside one it builds the accepted structure.
        section.add(synchronized(lock) { holder.buildRefreshNode(this) })
        section.add(cjguiComposableText(700202, "rule-generated-status", statusText(),
            CjguiComposableUiStyle(fontSize: 11.0)))
        return section
    }

    private func finishGeneratedEdit(result: CjguiSharedOperationActionResult,
                                     label: String): CjguiComposableUiDispatchResult {
        synchronized(lock) {
            lastOutcome = if (result.applied) {
                "${label} 已应用 → v${result.versionAfter}"
            } else {
                "${label} 被拒：${result.reason}"
            }
            if (result.applied) {
                revisionValue += 1
            }
        }
        return CjguiComposableUiDispatchResult(result.applied)
    }

    public func handleEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // Generated field edits: the operation name the accepted node carries
        // comes from the field's own definition (CjguiGeneratedUiFieldSpec), so
        // this routing never hardcodes EDIT_DRAFT_TEXT/EDIT_DRAFT_BOOLEAN and a
        // field whose owner uses a different writer would still route correctly.
        let operation = event.node.operationActionName
        if (operation.size > 0) {
            let key = holder.keyForNodeId(event.node.nodeId)
            if (key.isEmpty()) {
                return CjguiComposableUiDispatchResult(false)
            }
            let spec = match (holder.acceptedNodeForKey(key)) {
                case Some(value) => value
                case None => return CjguiComposableUiDispatchResult(false)
            }
            if (spec.fieldId.isEmpty()) {
                return CjguiComposableUiDispatchResult(false)
            }
            let field = match (fieldSpec(spec.fieldId)) {
                case Some(value) => value
                case None => return CjguiComposableUiDispatchResult(false)
            }
            // The event is only valid for the accepted generation of this
            // field: same field, same declared writer, same shared resource.
            if (field.writeActionName != operation || event.node.fieldId != spec.fieldId) {
                return CjguiComposableUiDispatchResult(false)
            }
            let sharedResource = field.resourceId
            if (sharedResource < 0 || event.node.resourceId != sharedResource) {
                return CjguiComposableUiDispatchResult(false)
            }
            let target = event.node.operationResourceId
            if (target < 0) {
                // No owner binding was accepted for this node: reject instead
                // of guessing a target.
                return CjguiComposableUiDispatchResult(false)
            }
            // Which kind carries a change is part of the field definition, so a
            // focus/scroll/activation event on an editor can never be turned
            // into a write, and a real boolean press (reported as a boolean
            // change) is never filtered out.
            if (!field.acceptsChangeEventKind(event.eventKind)) {
                return CjguiComposableUiDispatchResult(false)
            }
            if (field.editorKind == "BOOLEAN") {
                let next = if (event.text == "true" || event.text == "false") {
                    event.text == "true"
                } else {
                    let current = draftBoolean(spec.fieldId) ?? false
                    !current
                }
                let result = domain.editBooleanForCollectionItemFromHuman(target, sharedResource, next)
                return finishGeneratedEdit(result, "布尔草稿")
            }
            if (field.editorKind != "TEXT" && field.editorKind != "INTEGER") {
                return CjguiComposableUiDispatchResult(false)
            }
            let result = domain.editTextForCollectionItemFromHuman(target, sharedResource, event.text,
                event.selectionStart, event.selectionEnd)
            return finishGeneratedEdit(result, "文本草稿")
        }
        if (event.node.actionName != "GENERATED_ACTION") {
            return CjguiComposableUiDispatchResult(false)
        }
        // Events resolve through the accepted structure's own identity map, so
        // a stale key can never execute a different object's action.
        let key = holder.keyForNodeId(event.node.nodeId)
        if (key.isEmpty()) {
            return CjguiComposableUiDispatchResult(false)
        }
        let actionName = holder.actionNameForKey(key)
        if (actionName.isEmpty()) {
            return CjguiComposableUiDispatchResult(false)
        }
        let result = executeAction(actionName, key)
        return CjguiComposableUiDispatchResult(result.applied)
    }
}

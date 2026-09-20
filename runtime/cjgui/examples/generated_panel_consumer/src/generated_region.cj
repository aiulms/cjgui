// Second runtime-generated-UI consumer: the collaboration task board keeps its
// handwritten panes and adds one generated region. It reuses the existing
// shared-operation list domain (a different domain from the rule set) through
// the same public generated-UI entry points; no interpreter or rule-private
// branch is copied.
//
// This domain writes immediately on every accepted change (there is no draft
// layer), so the generated editors call the domain's own human owner entries.
// The field list, their editor kinds, binding resource ids and writer
// operations come from ONE local definition (CjguiTaskFields), which is also
// what the handwritten title input and the external field read use.
package cjgui_collaboration_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.sync.*
import std.unicode.*

/// One authored definition of a task field: the stable key, its business type,
/// the shared resource, the owner operation that performs a write, that
/// operation's argument name, and the rule that decides acceptance. The
/// handwritten pane, the generated editor/catalog and an external capability
/// query all derive from this object; nothing restates a writer, an argument
/// name or a rule per entry point.
public class CjguiTaskFieldDefinition {
    public let fieldId: String
    public let label: String
    public let editorKind: String
    public let resourceId: Int64
    public let writer: String        // owner operation, "" when none
    public let argument: String      // the writer's own argument name
    public let required: Bool
    /// 0 = no declared limit. Unit: Unicode scalar values (Rune), not bytes.
    public let maximumLength: Int64
    private let condition: ?CjguiSharedFieldWriteCondition

    public init(fieldId: String, label: String, editorKind: String, resourceId: Int64,
                writer: String, argument: String, required!: Bool = false, maximumLength!: Int64 = 0,
                condition!: ?CjguiSharedFieldWriteCondition = None) {
        this.fieldId = fieldId
        this.label = label
        this.editorKind = editorKind
        this.resourceId = resourceId
        this.writer = writer
        this.argument = argument
        this.required = required
        this.maximumLength = maximumLength
        this.condition = condition
    }

    /// The owner-facing rule of this field for one target resource. The
    /// handwritten pane, the generated editor and an external invocation all
    /// hand this same object to the owner entry, which enforces it inside its
    /// own transaction.
    public func rule(targetResourceId: Int64): CjguiSharedFieldRule {
        return CjguiSharedFieldRule(fieldId, editorKind, targetResourceId, writer, argument,
            required: required, maximumLength: maximumLength, condition: condition)
    }

    /// Immediate feedback for a pane: it evaluates the declared constraint
    /// through the very rule object the owner enforces, so the length unit and
    /// the boundary cannot drift between the pane and the owner. The owner
    /// stays authoritative - this never writes.
    public func rejectionFor(value: String): String {
        return rule(0).declaredTextRejection(value)
    }
}

/// The application's own business condition of the title field: once the task
/// has been submitted, its title is frozen. This is a business condition, not a
/// version conflict - the request can be legal in form and still be refused
/// until the task is reopened.
private class CjguiTaskTitleFrozenWhenSubmitted <: CjguiSharedFieldWriteCondition {
    public func rejectionFor(request: CjguiSharedFieldWriteRequest): String {
        if (request.currentMarked) {
            return "title_frozen_after_submit"
        }
        return ""
    }
}

/// The single field definition of this consumer: printed by the handwritten
/// pane, the generated catalog and the external field readbacks, and installed
/// into the owner as the rules every write is checked against.
public class CjguiTaskFields {
    public static let titleResourceId: Int64 = 8101
    public static let markedResourceId: Int64 = 8102
    public static let notesResourceId: Int64 = 8103

    /// The authored definition list. A new field is declared here once and is
    /// then visible to the handwritten pane, the generated catalog and the
    /// external query, and enforced by the owner - with no generation-specific
    /// switch and no second validation copy.
    public static func definitions(): ArrayList<CjguiTaskFieldDefinition> {
        return ArrayList<CjguiTaskFieldDefinition>([
            CjguiTaskFieldDefinition("title", "当前任务", "TEXT", titleResourceId, "SET_TITLE", "title",
                required: true, maximumLength: 120, condition: Some(CjguiTaskTitleFrozenWhenSubmitted())),
            CjguiTaskFieldDefinition("marked", "提交状态", "BOOLEAN", markedResourceId, "SET_MARKED", "isMarked"),
            CjguiTaskFieldDefinition("notes", "备注", "TEXT", notesResourceId, "SET_NOTES", "notes",
                maximumLength: 200)
        ])
    }

    public static func definition(fieldId: String): CjguiTaskFieldDefinition {
        for (field in definitions()) {
            if (field.fieldId == fieldId) {
                return field
            }
        }
        return CjguiTaskFieldDefinition("", "", "", -1, "", "")
    }

    /// Declared fields of one editor kind, in declaration order. The handwritten
    /// pane builds its inputs from this, so adding a field does not require a
    /// pane edit.
    public static func definitionsOfKind(editorKind: String): ArrayList<CjguiTaskFieldDefinition> {
        let result = ArrayList<CjguiTaskFieldDefinition>()
        for (field in definitions()) {
            if (field.editorKind == editorKind) {
                result.add(field)
            }
        }
        return result
    }

    /// Installs every declared rule for EVERY record the application exposes.
    /// The owner only applies a field rule for a (writer, target) pair that was
    /// really installed - it never invents one for an un-installed target - so a
    /// multi-record consumer must wire each exposed record, not just the first.
    public static func installIntoEveryRecord(domain: CjguiSharedOperationList): Bool {
        for (record in domain.snapshot().records) {
            if (!installInto(domain, record.id)) {
                return false
            }
        }
        return true
    }

    /// Installs every declared rule on the owner that holds the data. After
    /// this, the external SET_TITLE/SET_NOTES invocations, the generated editors
    /// and the handwritten pane all pass through the same owner rule.
    public static func installInto(domain: CjguiSharedOperationList, targetResourceId: Int64): Bool {
        for (field in definitions()) {
            if (field.writer.size == 0) {
                continue
            }
            if (!domain.installFieldRule(field.rule(targetResourceId))) {
                return false
            }
        }
        return true
    }

    /// The shared form binding the handwritten pane and the external field read
    /// use, derived from the same definition list.
    public static func definition(): CjguiSharedFormBinding {
        let descriptors = ArrayList<CjguiSharedFormFieldDescriptor>()
        for (field in definitions()) {
            descriptors.add(CjguiSharedFormFieldDescriptor(field.resourceId, field.fieldId, field.label,
                field.editorKind, required: field.required, maximumLength: field.maximumLength))
        }
        return CjguiSharedFormBinding(descriptors)
    }

    /// Generation-side specs derived from the same definition list: the writer
    /// operation and the declared constraint come from the field definition, so
    /// the generated editor cannot drift to a different owner operation than
    /// the handwritten pane uses.
    public static func generatedSpecs(): ArrayList<CjguiGeneratedUiFieldSpec> {
        let specs = ArrayList<CjguiGeneratedUiFieldSpec>()
        for (field in definitions()) {
            specs.add(CjguiGeneratedUiFieldSpec(field.fieldId, field.label, field.editorKind,
                field.resourceId, writeActionName: field.writer, required: field.required,
                maximumLength: field.maximumLength))
        }
        return specs
    }
}

public class CjguiTaskGeneratedRegion <: CjguiGeneratedUiBindingProvider &
    CjguiSharedOperationGeneratedUiProvider {
    private let domain: CjguiSharedOperationList
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    private let holder: CjguiGeneratedUiStructureHolder
    private let lock: Mutex
    private var lastOutcome: String
    private var revisionValue: Int64
    private let resourceId: Int64

    public init(domain: CjguiSharedOperationList, resourceId: Int64) {
        this.domain = domain
        this.resourceId = resourceId
        this.lock = Mutex()
        this.catalog = CjguiTaskGeneratedRegion.buildCatalog()
        this.holder = CjguiGeneratedUiStructureHolder(catalog,
            rootScope: CjguiComposableUiIdentityScope("task-generated"))
        this.lastOutcome = "尚未提交生成结构"
        this.revisionValue = 1
    }

    /// Components/actions this window presents, plus the fields derived from
    /// CjguiTaskFields - one definition, not a second hand-written list.
    static func buildCatalog(): CjguiGeneratedUiCapabilityCatalog {
        let catalog = CjguiGeneratedUiCapabilityCatalog(maxDepth: 8, maxNodes: 128,
            maxPropertiesPerNode: 6, maxStringLength: 160)
        let containerProperties = ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 24)
        ])
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical", containerProperties, true, childLimit: 32))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("horizontal", containerProperties, true, childLimit: 32))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 160)
        ]), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput", ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60)
        ]), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("booleanInput", ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60)
        ]), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action", ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 40),
            CjguiGeneratedUiPropertySpec("action", "STRING", maxLength: 40)
        ]), false))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("SET_TITLE", "写回任务标题"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("TOGGLE_MARKED", "切换提交状态"))
        let _ = catalog.registerFields(CjguiTaskFields.generatedSpecs())
        // The application's own composite card. Registering a second component
        // kind changes this registration call and that component's file only:
        // no framework dispatch or kind switch is touched.
        let _ = CjguiTaskEditCardComposite.registerInto(catalog)
        return catalog
    }

    public func revision(): Int64 {
        return synchronized(lock) { revisionValue }
    }

    public func statusText(): String {
        return synchronized(lock) { lastOutcome }
    }

    private func selectedRecordId(): Int64 {
        let snapshot = domain.snapshot()
        if (snapshot.selectedRecordId >= 0) {
            return snapshot.selectedRecordId
        }
        if (snapshot.records.size > 0) {
            return snapshot.recordAt(0).id
        }
        return -1
    }

    private func titleOf(recordId: Int64): String {
        let snapshot = domain.snapshot()
        for (record in snapshot.records) {
            if (record.id == recordId) {
                return record.title
            }
        }
        return ""
    }

    private func markedOf(recordId: Int64): Bool {
        let snapshot = domain.snapshot()
        for (record in snapshot.records) {
            if (record.id == recordId) {
                return record.isMarked
            }
        }
        return false
    }

    private func fieldSpec(fieldId: String): ?CjguiGeneratedUiFieldSpec {
        return catalog.fieldFor(fieldId)
    }

    // --- binding provider ---------------------------------------------------

    public func fieldResourceId(fieldId: String): Int64 {
        if (let Some(spec) <- fieldSpec(fieldId)) {
            return spec.resourceId
        }
        return -1
    }

    public func fieldOperationResourceId(fieldId: String): Int64 {
        if (let None <- fieldSpec(fieldId)) { return -1 }
        return selectedRecordId()
    }

    /// The generated editor presents the live owner value of ITS OWN field. This
    /// domain applies immediately, so there is no separate draft to prefer.
    /// Answering the title for every text field made the notes editor show (and
    /// the external field read publish) the title's value.
    public func draftText(fieldId: String): String {
        return fieldTextValue(fieldId, selectedRecordId())
    }

    /// The owner's current value of one declared text field.
    private func fieldTextValue(fieldId: String, recordId: Int64): String {
        for (record in domain.snapshot().records) {
            if (record.id != recordId) { continue }
            if (fieldId == "title") { return record.title }
            if (fieldId == "notes") { return record.notes }
            return ""
        }
        return ""
    }

    public func appliedText(fieldId: String): String {
        return draftText(fieldId)
    }

    /// Field-keyed boolean read: only the boolean field answers, and it answers
    /// its own record's state. (The earlier version checked the text field's id
    /// here, so the generated boolean editor showed the wrong field.)
    public func draftBoolean(fieldId: String): ?Bool {
        if (fieldId != "marked") { return None }
        return Some(markedOf(selectedRecordId()))
    }

    public func actionAvailable(actionName: String): Bool {
        if (actionName == "SET_TITLE") { return selectedRecordId() >= 0 }
        if (actionName == "TOGGLE_MARKED") { return selectedRecordId() >= 0 }
        return false
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        let recordId = selectedRecordId()
        if (recordId < 0) {
            return CjguiGeneratedUiActionResult(false, "no_selected_record")
        }
        let result = if (actionName == "TOGGLE_MARKED") {
            domain.setMarkedFromHuman(recordId, !markedOf(recordId))
        } else if (actionName == "SET_TITLE") {
            domain.setTitleFromHuman(recordId, "${titleOf(recordId)} ·")
        } else {
            CjguiSharedOperationResult(false, false, 0, 0, "unknown_action")
        }
        let outcome = if (result.applied) {
            "${actionName} 已应用 → v${domain.version()}"
        } else {
            "${actionName} 被拒：${result.reason}"
        }
        synchronized(lock) {
            lastOutcome = outcome
            revisionValue += 1
        }
        return CjguiGeneratedUiActionResult(result.applied, result.reason)
    }

    // --- external structure provider ----------------------------------------

    public func capabilitiesPayload(): String {
        return CjguiGeneratedUiEncoding.describe(catalog)
    }

    /// Field readback for exactly the fields this consumer registered, using
    /// their own resource ids and editor kinds from the single definition.
    public func fieldsPayload(): String {
        let recordId = selectedRecordId()
        let builder = StringBuilder()
        for (fieldId in catalog.fieldIds()) {
            let spec = match (fieldSpec(fieldId)) {
                case Some(value) => value
                case None => continue
            }
            if (spec.editorKind == "BOOLEAN") {
                // The boolean's canonical text form comes from the shared value
                // definition, so a reader sees the same encoding the rule
                // consumer publishes.
                let value = CjguiSharedOperationValue.boolean(markedOf(recordId))
                let hex = encodeHex(value.displayText())
                builder.append("FIELD ${fieldId} ${spec.resourceId} DRAFT_HEX ${hex} APPLIED_HEX ${hex} " +
                    "ERROR none FOCUS 0 SELECTION 0 0 VERSION ${domain.version()}\n")
            } else {
                // Each field publishes ITS OWN value: a reader that resolves a
                // field id must not receive another field's content.
                let value = fieldTextValue(fieldId, recordId)
                builder.append("FIELD ${fieldId} ${spec.resourceId} DRAFT_HEX ${encodeHex(value)} " +
                    "APPLIED_HEX ${encodeHex(value)} ERROR none FOCUS 1 SELECTION 0 0 " +
                    "VERSION ${domain.version()}\n")
            }
        }
        builder.append("END")
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
    /// not part of the accepted structure). Exposed so this application's own
    /// tests can address the accepted editor exactly as a delivered input event
    /// would; it allocates nothing and changes no state.
    public func acceptedNodeIdForKey(key: String): Int64 {
        return synchronized(lock) { holder.nodeIdForKey(key) }
    }

    public func candidateStructureVersion(): Int64 {
        return synchronized(lock) { holder.candidateStructureVersion() }
    }

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
            case None => return CjguiSharedOperationGeneratedUiSubmit(false, "empty_structure", "",
                expectedVersion, expectedVersion)
        }
        return synchronized(lock) {
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
                lastOutcome = "候选已接收 v${result.candidateVersion}，等待场景接受"
                revisionValue += 1
            }
            return CjguiSharedOperationGeneratedUiSubmit(result.candidateAccepted, result.reason,
                result.path, result.structureVersionBefore, result.structureVersionAfter,
                sceneAccepted: result.sceneAccepted, candidateVersion: result.candidateVersion)
        }
    }

    // --- window scene-refresh transaction ----------------------------------

    public func beginSceneRefresh(): Bool {
        return synchronized(lock) { holder.beginCandidateRefresh() }
    }

    public func prepareSceneRefresh(): Bool {
        return synchronized(lock) { holder.prepareCandidateRefresh() }
    }

    public func commitSceneRefresh(): Unit {
        synchronized(lock) {
            // An ordinary refresh has no candidate and must not advance this
            // region's revision.
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

    // --- section + events ---------------------------------------------------

    public func buildSection(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let section = cjguiComposableVertical(900, "task-generated-section",
            CjguiComposableUiStyle(padding: 10, gap: 6,
                background: CjguiComposableUiColor(0.10, 0.16, 0.26, 0.9),
                border: CjguiComposableUiColor(0.26, 0.40, 0.62, 0.9)))
        section.add(cjguiComposableText(901, "task-generated-title",
            "生成区域 · 结构 v${holder.structureVersion()}", theme.heading))
        section.add(synchronized(lock) { holder.buildRefreshNode(this) })
        section.add(cjguiComposableText(902, "task-generated-status", statusText(), theme.body))
        return section
    }

    public func handleEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // One public adapter resolves the raw control event into a field edit
        // (with the fingerprint owner binding the accepted node carried) or a
        // declared action. It also serves COMPOSITE elements: a card field is not
        // distinguishable by control type, and the adapter never gates on the
        // field's editor kind, so a composite editor is not dropped.
        let intent = holder.resolveIntent(event.node, event.eventKind, event.text)
        if (intent.isFieldEdit()) {
            let definition = CjguiTaskFields.definition(intent.fieldId)
            if (definition.fieldId.size == 0 || definition.writer.size == 0) {
                return finishEdit(CjguiSharedOperationResult(false, false, 0, 0, "unknown_writer"),
                    intent.fieldId)
            }
            if (intent.ownerTargetResourceId < 0) {
                return CjguiComposableUiDispatchResult(false)
            }
            // A boolean control whose driver sent no projected next value toggles
            // the owner's current value; that read is domain behaviour, not a
            // generation-specific branch.
            let value = if (definition.editorKind == "BOOLEAN" && event.text != "true" &&
                event.text != "false") {
                CjguiSharedOperationValue.boolean(!markedOf(intent.ownerTargetResourceId))
            } else {
                intent.value
            }
            // The same owner entry and the same declared rule the handwritten
            // pane and an external invocation use.
            let result = domain.writeDeclaredFieldFromHuman(definition.rule(this.resourceId),
                intent.ownerTargetResourceId, value)
            return finishEdit(result, definition.label)
        }
        if (intent.isAction()) {
            return CjguiComposableUiDispatchResult(executeAction(intent.actionName, intent.nodeKey).applied)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    /// Accepted composite element node id for one instance key, so a consumer or
    /// a verification script can address a card element without knowing its id.
    public func acceptedCompositeElementNodeId(instanceKey: String, elementKey: String): Int64 {
        for (binding in holder.compositeElementNodeIdsForKey(instanceKey)) {
            if (binding.elementKey == elementKey) {
                return binding.nodeId
            }
        }
        return -1
    }

    /// Resolved binding of one accepted composite element ("label|fieldId|writer|
    /// role"), so an external reader can see which declared field and owner
    /// writer the framework resolved for that element.
    public func acceptedCompositeElementSummary(instanceKey: String, elementKey: String): String {
        for (binding in holder.compositeElementNodeIdsForKey(instanceKey)) {
            if (binding.elementKey == elementKey) {
                return "${binding.label}|${binding.fieldId}|${binding.writerOperation}|${binding.role}"
            }
        }
        return ""
    }

    private func finishEdit(result: CjguiSharedOperationResult, label: String): CjguiComposableUiDispatchResult {
        synchronized(lock) {
            lastOutcome = if (result.applied) {
                "${label} 已即时写入 → v${result.versionAfter}"
            } else {
                "${label} 被拒：${result.reason}"
            }
            if (result.applied) {
                revisionValue += 1
            }
        }
        return CjguiComposableUiDispatchResult(result.applied)
    }

    private func encodeHex(text: String): String {
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
}

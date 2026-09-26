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

    /// The SAME verdict from STATE alone, so an editor's enabled projection and a
    /// refused write share one reason source instead of being handed a fabricated
    /// candidate value.
    public func stateRejectionFor(state: CjguiSharedFieldState): String {
        if (state.currentMarked) {
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
    /// operation, the writer's own ARGUMENT name and the declared constraint come
    /// from the field definition, so the generated editor cannot drift to a
    /// different owner operation than the handwritten pane uses, and the public
    /// capability description carries the real argument.
    public static func generatedSpecs(): ArrayList<CjguiGeneratedUiFieldSpec> {
        let specs = ArrayList<CjguiGeneratedUiFieldSpec>()
        for (field in definitions()) {
            specs.add(CjguiGeneratedUiFieldSpec(field.fieldId, field.label, field.editorKind,
                field.resourceId, writeActionName: field.writer, required: field.required,
                maximumLength: field.maximumLength, argumentName: field.argument))
        }
        return specs
    }

    /// The declared ARGUMENT names of one write action, taken from the field
    /// definitions whose writer is that action. The generated capability
    /// description publishes them, so an external caller never restates the
    /// owner's argument list.
    public static func writerArgumentNames(writer: String): ArrayList<String> {
        let names = ArrayList<String>()
        let seen = HashSet<String>()
        for (field in definitions()) {
            if (field.writer == writer && field.argument.size > 0 && !seen.contains(field.argument)) {
                seen.add(field.argument)
                names.add(field.argument)
            }
        }
        return names
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
    /// The window whose accepted scene carries this region's generated nodes.
    private var attachedWindow: ?CjguiComposableUiWindow = None
    /// ONE bounded change cursor over this region's real state.
    private let tracker: CjguiGeneratedUiObservationTracker
    /// ONE application image declaration, shared by the handwritten pane and by
    /// the registered task card's icon.
    private var beaconResourceValue: CjguiGeneratedUiImageResourceSpec
    // Owner projection stamp (revisions only) captured at the scene-build
    // boundary and promoted when the window accepts that scene.
    private var acceptedOwnerStamp: Int64
    private var pendingOwnerStamp: Int64
    // Test-only work counters (see the rule consumer for the same seam).
    private var fieldsSerializationsValue: Int64
    private var structureSerializationsValue: Int64
    private var instancesSerializationsValue: Int64
    private var acceptedInstanceSamplesValue: Int64

    public init(domain: CjguiSharedOperationList, resourceId: Int64) {
        this.domain = domain
        this.resourceId = resourceId
        this.lock = Mutex()
        this.catalog = CjguiTaskGeneratedRegion.buildCatalog()
        this.holder = CjguiGeneratedUiStructureHolder(catalog,
            rootScope: CjguiComposableUiIdentityScope("task-generated"))
        this.lastOutcome = "尚未提交生成结构"
        this.revisionValue = 1
        this.tracker = CjguiGeneratedUiObservationTracker()
        this.beaconResourceValue = CjguiTaskGeneratedRegion.imageResource()
        this.acceptedOwnerStamp = 0
        this.pendingOwnerStamp = 0
        this.fieldsSerializationsValue = 0
        this.structureSerializationsValue = 0
        this.instancesSerializationsValue = 0
        this.acceptedInstanceSamplesValue = 0
    }

    /// The application's resolved beacon declaration (the catalog builder and
    /// the region must agree on exactly one).
    public static func imageResource(): CjguiGeneratedUiImageResourceSpec {
        return CjguiGeneratedUiImageResourceSpec("collaboration-beacon", "PNG", 1,
            "任务面板图标", "composable-beacon.png")
    }

    /// The application's ONE named paint role (paint only, own geometry stays in
    /// the helpers), so a theme or accent change never moves layout.
    public static func primaryActionStyle(): CjguiComposableUiNamedStyle {
        let theme = CjguiComposableUiTheme.paperLight()
        return CjguiComposableUiNamedStyle("collaboration_primary_action",
            CjguiComposableUiStyle(background: theme.primaryAction.background,
                border: theme.primaryAction.border, textColor: theme.primaryAction.textColor,
                borderWidth: theme.primaryAction.borderWidth),
            interaction: theme.primaryActionInteraction, purpose: "任务面板主操作")
    }

    /// The generated tab pages' title role: declared once here, referenced by
    /// the tabs declaration's `titleStyle`, consumed by the SAME public tab
    /// container the handwritten pages use.
    public static func panelTabTitleStyle(): CjguiComposableUiNamedStyle {
        // The task panel is a DARK surface: the title role uses the dark
        // theme's heading paint, or the page titles render dark-on-dark.
        let theme = CjguiComposableUiTheme.beaconDark()
        return CjguiComposableUiNamedStyle("panel_tab_title",
            CjguiComposableUiStyle(textColor: theme.heading.textColor,
                fontWeight: theme.heading.fontWeight),
            interaction: CjguiComposableUiInteractionStyle(
                normal: CjguiComposableUiPaintStyle(textColor: Some(theme.heading.textColor))),
            purpose: "任务面板页签标题")
    }

    /// Withdraws a named style declaration. Instances already accepted keep the
    /// resolution they were accepted with; discovery and the STYLES section stop
    /// publishing the name, and a NEW candidate referencing it is refused.
    public func withdrawNamedStyle(name: String): Bool {
        return synchronized(lock) {
            if (!catalog.namedStyles().remove(name)) {
                return false
            }
            revisionValue += 1
            return true
        }
    }

    /// The application's named style, as the handwritten helper and tests read it.
    public func namedStyle(name: String): ?CjguiComposableUiNamedStyle {
        return synchronized(lock) { catalog.namedStyles().forName(name) }
    }

    public func beaconResource(): CjguiGeneratedUiImageResourceSpec {
        return synchronized(lock) { beaconResourceValue }
    }

    /// Components/actions this window presents, plus the fields derived from
    /// CjguiTaskFields - one definition, not a second hand-written list.
    /// Content properties plus the framework's shared style vocabulary, in one
    /// list: registration validates both, so a published property is never
    /// silently ignored by the renderer.
    static func taskWithStyle(content: ArrayList<CjguiGeneratedUiPropertySpec>):
        ArrayList<CjguiGeneratedUiPropertySpec> {
        let combined = ArrayList<CjguiGeneratedUiPropertySpec>()
        for (property in content) {
            combined.add(property)
        }
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            combined.add(property)
        }
        return combined
    }

    static func buildCatalog(): CjguiGeneratedUiCapabilityCatalog {
        let catalog = CjguiGeneratedUiCapabilityCatalog(maxDepth: 8, maxNodes: 128,
            maxPropertiesPerNode: 6, maxStringLength: 160)
        // The style vocabulary comes from the framework's ONE shared definition
        // (size constraints, growth, alignment, font); only the content
        // properties are this application's own.
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
            CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 32))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("horizontal",
            CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 32))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
            taskWithStyle(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 160)
            ])), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
            taskWithStyle(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60)
            ])), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("booleanInput",
            taskWithStyle(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60)
            ])), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action",
            taskWithStyle(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 40),
                CjguiGeneratedUiPropertySpec("action", "STRING", maxLength: 40)
            ])), false))
        let imageProperties = CjguiGeneratedUiPresentation.imageContentProperties()
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            imageProperties.add(property)
        }
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("image", imageProperties, false))
        // The generated scroll container: the framework's own public viewport,
        // declared with the ONE property it consumes and exactly one child.
        let scrollProperties = CjguiGeneratedUiPresentation.scrollContentProperties()
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            scrollProperties.add(property)
        }
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("scrollArea", scrollProperties, true,
            childLimit: 1))
        // The generated split container: the framework's scoped split view, with
        // the three properties it consumes and exactly two children.
        let splitProperties = CjguiGeneratedUiPresentation.splitContentProperties()
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            splitProperties.add(property)
        }
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("split", splitProperties, true,
            childLimit: 2))
        // The generated PAGE container: the same public tab component the rule
        // window builds by hand, declared here with its own page vocabulary. The
        // pages are "任务" and "备注", so a long panel becomes a workspace instead
        // of one ever-growing column.
        let tabPageProperties = CjguiGeneratedUiPresentation.tabPageContentProperties()
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            tabPageProperties.add(property)
        }
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("tabPage", tabPageProperties, true,
            childLimit: 1))
        let tabsProperties = CjguiGeneratedUiPresentation.tabsContentProperties()
        for (property in CjguiGeneratedUiPresentation.containerStyleProperties()) {
            tabsProperties.add(property)
        }
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("tabs", tabsProperties, true,
            childLimit: 3))

        // The ONE image declaration, registered with the catalog that publishes it.
        let _ = catalog.registerImageResource(CjguiTaskGeneratedRegion.imageResource())
        // ONE named paint role for this domain, resolved by the framework and
        // consumed by the handwritten helper and the registered composite alike.
        let _ = catalog.namedStyles().register(CjguiTaskGeneratedRegion.primaryActionStyle())
        // The generated tab pages consume this title role through the tabs
        // declaration's `titleStyle` reference: base paint and interaction
        // states arrive together from this ONE definition.
        let _ = catalog.namedStyles().register(CjguiTaskGeneratedRegion.panelTabTitleStyle())
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("SET_TITLE", "写回任务标题",
            parameterNames: CjguiTaskFields.writerArgumentNames("SET_TITLE")))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("TOGGLE_MARKED", "切换提交状态"))
        // D3 step4j: the theme operation the consumer chain drives to prove a
        // title-role update reaches the ACCEPTED tabs titles through the one
        // named-style transaction (effective normal override, not just base).
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("TOGGLE_TITLE_ACCENT", "切换标题强调色"))
        let _ = catalog.registerFields(CjguiTaskFields.generatedSpecs())
        // The application's own composite card. Registering a second component
        // kind changes this registration call and that component's file only:
        // no framework dispatch or kind switch is touched.
        let _ = CjguiTaskEditCardComposite.registerInto(catalog, CjguiTaskGeneratedRegion.imageResource())
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

    /// CURRENT availability of one field, evaluated through the SAME rule object
    /// the owner enforces on write. Only state-related facts are consulted: the
    /// declared length/required constraint is value-dependent and is checked
    /// against the REAL candidate when a write arrives, so a legally empty
    /// required title stays editable while a submitted (frozen) title reports
    /// blocked with the owner's own reason. This is a read: it writes nothing and
    /// authorizes nothing (the owner re-checks in its transaction).
    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        let definition = CjguiTaskFields.definition(fieldId)
        if (definition.fieldId.size == 0) {
            return CjguiSharedAvailability.unknown()
        }
        let recordId = selectedRecordId()
        return definition.rule(recordId).availabilityFor(
            fieldTextValue(fieldId, recordId), markedOf(recordId), recordId, domain.version())
    }

    /// The action that writes the title is exactly as available as the title
    /// field itself: one condition, one answer, no second judgment.
    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        if (actionName == "SET_TITLE") {
            return fieldAvailability("title")
        }
        if (actionName == "TOGGLE_MARKED") {
            return fieldAvailability("marked")
        }
        if (actionName == "TOGGLE_TITLE_ACCENT") {
            if (let Some(_) <- catalog.namedStyles().forName("panel_tab_title")) {
                return CjguiSharedAvailability.allowed(resourceId, revision())
            }
            return CjguiSharedAvailability.blocked("title_role_missing", resourceId, revision())
        }
        return CjguiSharedAvailability.unknown()
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
        // Theme actions address the named-style catalog, not a selected record.
        // Keep the generated control enabled even when the data list is empty.
        if (actionName == "TOGGLE_TITLE_ACCENT") {
            return catalog.namedStyles().forName("panel_tab_title").isSome()
        }
        return false
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        // The title-accent toggle is a THEME operation on the named-style
        // catalog: it does not address a business record, so it runs before
        // the record-selection guard the data actions require.
        if (actionName == "TOGGLE_TITLE_ACCENT") {
            let current = catalog.namedStyles().forName("panel_tab_title")
            let flipped = match (current) {
                case Some(role) =>
                    let accentBlue = CjguiComposableUiColor(0.10, 0.30, 0.85, 1.0)
                    let accentPlum = CjguiComposableUiColor(0.55, 0.15, 0.60, 1.0)
                    let target = match (role.interaction.normal.textColor) {
                        // The two declared states are exact palette values. A
                        // broad channel threshold made both blue and plum fall
                        // into the same branch, so the action stopped toggling.
                        case Some(color) => if (color.red == accentBlue.red &&
                            color.green == accentBlue.green && color.blue == accentBlue.blue &&
                            color.alpha == accentBlue.alpha) { accentPlum } else { accentBlue }
                        case None => accentBlue
                    }
                    let applied = catalog.namedStyles().update(CjguiComposableUiNamedStyle(role.name, role.base,
                        interaction: CjguiComposableUiInteractionStyle(
                            normal: CjguiComposableUiPaintStyle(textColor: Some(target)),
                            hover: role.interaction.hover,
                            pressed: role.interaction.pressed,
                            focused: role.interaction.focused,
                            disabled: role.interaction.disabled,
                            selected: role.interaction.selected,
                            checked: role.interaction.checked),
                        purpose: role.purpose))
                    synchronized(lock) {
                        lastOutcome = if (applied) { "标题强调色已切换" } else { "标题角色缺失" }
                        revisionValue += 1
                    }
                    return CjguiGeneratedUiActionResult(applied, if (applied) { "none" } else { "title_role_missing" })
                case None =>
                    synchronized(lock) { revisionValue += 1 }
                    return CjguiGeneratedUiActionResult(false, "title_role_missing")
            }
        }
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

    /// The window this region's accepted instances belong to. The transport
    /// provider has no window argument, so the application attaches it once at
    /// startup - the same wiring the rule consumer uses.
    public func attachWindow(window: CjguiComposableUiWindow): Unit {
        attachedWindow = Some(window)
    }

    /// Accepted generated instances addressed by DECLARED key, with the accepted
    /// geometry, so an external caller never locates a generated control by its
    /// display caption. Empty before a window is attached or before acceptance.
    public func acceptedInstancesPayload(): String {
        instancesSerializationsValue += 1
        match (attachedWindow) {
            case Some(window) => return CjguiGeneratedUiEncoding.acceptedInstancesPayload(
                cjguiGeneratedUiAcceptedInstances(window, holder))
            case None => return ""
        }
    }

    /// The window's OWN interaction projection, or None when this consumer has no
    /// attached window. Focus and selection are never derived from the field
    /// list, the field name or the control kind.
    private func windowFocusFacts(): ?CjguiSharedOperationWindowProgress {
        return match (attachedWindow) {
            case Some(window) => Some(window.windowProgress())
            case None => None
        }
    }

    /// Whether the window's LIVE accepted focus IS this field's own editor
    /// instance. The association comes from the accepted instance table
    /// (semanticId + fieldId), so a second control of the same field is a
    /// different instance and cannot be mistaken for this one.
    private func fieldHoldsFocusedInstance(fieldId: String, semanticId: String): Bool {
        if (semanticId.size == 0 || semanticId == "none") {
            return false
        }
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return false
        }
        for (instance in cjguiGeneratedUiAcceptedInstances(window, holder)) {
            if (instance.semanticId == semanticId && instance.fieldId == fieldId) {
                return true
            }
        }
        return false
    }

    /// The focus/selection tokens for one field, taken from the window's live
    /// projection. Three DIFFERENT outcomes: confirmed focus of THIS field's
    /// instance (with its real selection), confirmed not-focused, and UNKNOWN
    /// when the window cannot confirm a live identity — an unconfirmed fact is
    /// published as `unknown` rather than as a fabricated 0/1.
    private func fieldFocusToken(fieldId: String): String {
        var state = CJGUI_WINDOW_FOCUS_STATE_UNKNOWN
        var focusedControl = "none"
        var hasSelection = false
        var selectionStart: Int64 = 0
        var selectionEnd: Int64 = 0
        if (let Some(value) <- windowFocusFacts()) {
            state = value.focusState
            focusedControl = value.focusedControlId
            hasSelection = value.hasTextSelection
            selectionStart = value.selectionStart
            selectionEnd = value.selectionEnd
        }
        if (state == CJGUI_WINDOW_FOCUS_STATE_UNKNOWN) {
            return "FOCUS unknown"
        }
        if (state == CJGUI_WINDOW_FOCUS_STATE_VALID &&
            fieldHoldsFocusedInstance(fieldId, focusedControl)) {
            if (hasSelection) {
                return "FOCUS 1 SELECTION ${selectionStart} ${selectionEnd}"
            }
            return "FOCUS 1 SELECTION 0 0"
        }
        return "FOCUS 0 SELECTION 0 0"
    }

    /// Field readback for exactly the fields this consumer registered, using
    /// their own resource ids and editor kinds from the single definition.
    public func fieldsPayload(): String {
        fieldsSerializationsValue += 1
        let recordId = selectedRecordId()
        let builder = StringBuilder()
        for (fieldId in catalog.fieldIds()) {
            let spec = match (fieldSpec(fieldId)) {
                case Some(value) => value
                case None => continue
            }
            let focus = fieldFocusToken(fieldId)
            // The SAME availability the editor's enabled state projects, so an
            // external reader never has to infer it from the draft value or from
            // an attempted write. `unknown` is published as unknown.
            let availability = fieldAvailability(fieldId)
            let availabilityToken = if (!availability.known) {
                "AVAILABLE unknown REASON_HEX -"
            } else if (availability.isAvailable) {
                "AVAILABLE 1 REASON_HEX -"
            } else {
                "AVAILABLE 0 REASON_HEX ${encodeHex(availability.reason)}"
            }
            let availabilityDetail = "${availabilityToken} TARGET ${availability.ownerResourceId} " +
                "STATE_VERSION ${availability.stateVersion}"
            if (spec.editorKind == "BOOLEAN") {
                // The boolean's canonical text form comes from the shared value
                // definition, so a reader sees the same encoding the rule
                // consumer publishes.
                let value = CjguiSharedOperationValue.boolean(markedOf(recordId))
                let hex = encodeHex(value.displayText())
                builder.append("FIELD ${fieldId} ${spec.resourceId} DRAFT_HEX ${hex} APPLIED_HEX ${hex} " +
                    "ERROR none ${focus} ${availabilityDetail} VERSION ${domain.version()}\n")
            } else {
                // Each field publishes ITS OWN value: a reader that resolves a
                // field id must not receive another field's content.
                let value = fieldTextValue(fieldId, recordId)
                builder.append("FIELD ${fieldId} ${spec.resourceId} DRAFT_HEX ${encodeHex(value)} " +
                    "APPLIED_HEX ${encodeHex(value)} ERROR none ${focus} ${availabilityDetail} " +
                    "VERSION ${domain.version()}\n")
            }
        }
        builder.append("END")
        return builder.toString()
    }

    public func acceptedStructurePayload(): String {
        structureSerializationsValue += 1
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

    /// The ACTIVE page of the generated workspace ("任务" / "备注"). Which page is
    /// presented is window VIEW state: the declaration's `initialPage` only seeds a
    /// NEW instance, so re-submitting the same structure can never move a person
    /// back, and switching pages never writes a business value.
    public func workspacePage(): String {
        return synchronized(lock) { holder.tabsStateForInstance("board", "task").activeKey() }
    }

    /// The application's own entry to move the workspace page (a menu item, a
    /// keyboard shortcut, an external observer or a test). Returns true when the
    /// active page really moved.
    public func selectWorkspacePage(pageKey: String): Bool {
        return synchronized(lock) {
            let changed = holder.tabsStateForInstance("board", "task").select(pageKey)
            if (changed) {
                revisionValue += 1
            }
            changed
        }
    }

    public func candidateStructureVersion(): Int64 {
        return synchronized(lock) { holder.candidateStructureVersion() }
    }

    public func sceneState(): String {
        return synchronized(lock) { holder.lastSceneOutcome() }
    }

    /// Terminal read for ONE submission attempt (the bounded ticket table lives
    /// in the holder, which is the only owner of the asynchronous scene commit).
    public func candidateTicketPayload(token: Int64): String {
        return synchronized(lock) { holder.candidateTicketPayload(token) }
    }

    /// Samples this application's real observation source. This domain applies
    /// immediately, so there is no separate draft revision; what changes the
    /// projected field values without a business write is WHICH record the
    /// region is editing, which is published as the draft revision.
    /// Revision pair of the owner projection this region presents.
    private func ownerStamp(): Int64 {
        return domain.snapshot().version * 1000003 + selectedRecordId()
    }

    private func observationSource(): CjguiGeneratedUiObservationSource {
        var identity = ""
        var sceneVersion: Int64 = 0
        var interactionRevision: Int64 = 0
        var instances = ArrayList<CjguiGeneratedUiAcceptedInstance>()
        match (attachedWindow) {
            case Some(window) =>
                acceptedInstanceSamplesValue += 1
                instances = cjguiGeneratedUiAcceptedInstances(window, holder)
                let progress = window.windowProgress()
                identity = progress.sessionIdentity
                sceneVersion = progress.acceptedSceneVersion
                interactionRevision = progress.interactionVersion
            case None => identity = ""
        }
        return CjguiGeneratedUiObservationSource(identity, domain.snapshot().version,
            selectedRecordId(), cjguiGeneratedUiBindingRevision(instances), holder.structureVersion(),
            holder.latestCandidateToken(), holder.lastSceneOutcome(), sceneVersion,
            cjguiGeneratedUiGeometryRevision(instances), interactionRevision,
            cjguiGeneratedUiInstanceRevision(instances),
            acceptedOwnerStamp == 0 || ownerStamp() != acceptedOwnerStamp,
            resourceRevision: catalog.imageResourceRevision(),
            imageStateRevision: holder.imageResourceStateRevision(),
            styleRevision: catalog.namedStyles().revision(),
            structureCandidatePending: holder.hasPendingCandidate())
    }

    /// ONE atomic snapshot: every section is sampled inside this single call.
    public func snapshotPayload(): String {
        return synchronized(lock) {
            let source = observationSource()
            let _ = tracker.observeSource(source)
            return cjguiGeneratedUiSnapshotPayload(tracker, source, fieldsPayload(),
                acceptedStructurePayload(), acceptedInstancesPayload(),
                stylesPayload: CjguiGeneratedUiEncoding.stylesPayload(catalog))
        }
    }

    /// Bounded change read: categories and cursors only, no tree/fields/geometry.
    public func changesPayload(streamEpoch: Int64, cursor: Int64): String {
        return synchronized(lock) {
            let _ = tracker.observeSource(observationSource())
            return tracker.changesPayload(streamEpoch, cursor)
        }
    }

    /// Test-only real work counters (see the rule consumer).
    public func testWorkCounts(): String {
        return synchronized(lock) {
            "counts=fields:${fieldsSerializationsValue} structure:${structureSerializationsValue} " +
                "instances:${instancesSerializationsValue} samples:${acceptedInstanceSamplesValue}"
        }
    }

    public func testResetWorkCounts(): Unit {
        synchronized(lock) {
            fieldsSerializationsValue = 0
            structureSerializationsValue = 0
            instancesSerializationsValue = 0
            acceptedInstanceSamplesValue = 0
        }
    }

    /// ONE section at the cursor the caller's snapshot belongs to. If anything
    /// moved in between, no section content is published and the caller takes a
    /// fresh snapshot instead of stitching sections.
    public func sectionPayload(section: String, expectedCursor: Int64): String {
        return synchronized(lock) {
            let source = observationSource()
            let _ = tracker.observeSource(source)
            // Guard the cursor first and serialize only the requested section.
            if (tracker.currentCursor() != expectedCursor) {
                return cjguiGeneratedUiSectionPayload(tracker, section, expectedCursor, "")
            }
            let payload = if (section == "FIELDS") {
                fieldsPayload()
            } else if (section == "STRUCTURE") {
                acceptedStructurePayload()
            } else if (section == "INSTANCES") {
                acceptedInstancesPayload()
            } else if (section == "STYLES") {
                // The style DEFINITIONS are a section of their own: a client that
                // saw a STYLES change re-reads the directory (add/update/removal)
                // without pulling a tree. It is the same encoder the capability
                // text uses, so there is no second style table.
                CjguiGeneratedUiEncoding.stylesPayload(catalog)
            } else {
                ""
            }
            return cjguiGeneratedUiSectionPayload(tracker, section, expectedCursor, payload)
        }
    }

    public func submitStructure(candidatePayload: String, expectedVersion: Int64):
        CjguiSharedOperationGeneratedUiSubmit {
        // Allocated before decoding: a rejected payload still belongs to exactly
        // one attempt, and two submitters sharing a base version stay distinct.
        let token = synchronized(lock) { holder.allocateCandidateAttempt() }
        let decoded = CjguiGeneratedUiEncoding.decode(candidatePayload)
        if (!decoded.ok) {
            synchronized(lock) { holder.rejectCandidateAttempt(token, decoded.reason, "") }
            return CjguiSharedOperationGeneratedUiSubmit(false, decoded.reason, "", expectedVersion, expectedVersion,
                candidateToken: token, receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
        }
        let root = match (decoded.root) {
            case Some(value) => value
            case None =>
                synchronized(lock) { holder.rejectCandidateAttempt(token, "empty_structure", "") }
                return CjguiSharedOperationGeneratedUiSubmit(false, "empty_structure", "",
                    expectedVersion, expectedVersion, candidateToken: token,
                    receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
        }
        return synchronized(lock) {
            let current = holder.structureVersion()
            if (expectedVersion != current) {
                holder.rejectCandidateAttempt(token, "structure_version_conflict", "")
                lastOutcome = "结构版本冲突：期望 ${expectedVersion}，当前 ${current}"
                return CjguiSharedOperationGeneratedUiSubmit(false, "structure_version_conflict", "",
                    current, current, candidateToken: token,
                    receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
            }
            let result = holder.submit(root, this, attemptToken: token)
            if (!result.candidateAccepted) {
                lastOutcome = "结构被拒：${result.reason} @${result.path}"
            } else {
                lastOutcome = "候选已接收 v${result.candidateVersion}，等待场景接受"
                revisionValue += 1
            }
            return CjguiSharedOperationGeneratedUiSubmit(result.candidateAccepted, result.reason,
                result.path, result.structureVersionBefore, result.structureVersionAfter,
                sceneAccepted: result.sceneAccepted, candidateVersion: result.candidateVersion,
                candidateToken: result.candidateToken, receipt: result.receipt)
        }
    }

    // --- window scene-refresh transaction ----------------------------------

    public func beginSceneRefresh(): Bool {
        return synchronized(lock) {
            // Style resolutions belong to the scene built from here on.
            holder.beginStyleRefresh()
            return holder.beginCandidateRefresh()
        }
    }

    public func prepareSceneRefresh(): Bool {
        return synchronized(lock) { holder.prepareCandidateRefresh() }
    }

    public func commitSceneRefresh(): Unit {
        synchronized(lock) {
            // The accepted scene consumed the owner projection it was built from,
            // ordinary refresh or not.
            acceptedOwnerStamp = pendingOwnerStamp
            // Promote the style resolutions this accepted scene used, and drop
            // records no longer referenced by the accepted structure.
            holder.commitStyleRefresh()
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

    /// How many shared-catalog image identities this window still holds.
    public func liveImageIdentityHoldCount(): Int64 {
        return holder.liveImageIdentityHoldCount()
    }

    /// Releases this window's holds on the SHARED resource catalog from the
    /// window dispose path.
    public func releaseImageIdentities(): Unit {
        holder.releaseAcceptedImageIdentities()
    }

    public func rollbackSceneRefresh(): Unit {
        synchronized(lock) {
            holder.rollbackStyleRefresh()
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
            CjguiComposableUiStyle(padding: 10, gap: 6, growX: 1,
                background: CjguiComposableUiColor(0.10, 0.16, 0.26, 0.9),
                border: CjguiComposableUiColor(0.26, 0.40, 0.62, 0.9)))
        section.add(cjguiComposableText(901, "task-generated-title",
            "生成区域 · 结构 v${holder.structureVersion()}", theme.heading))
        section.add(synchronized(lock) {
            pendingOwnerStamp = ownerStamp()
            // Sample the native preparation state of the ACCEPTED image bindings
            // here: this build already runs on the window's own thread, so the
            // public read path never calls native itself.
            match (attachedWindow) {
                case Some(window) => holder.sampleImageResourceStates(window)
                case None => ()
            }
            holder.buildRefreshNode(this)
        })
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
            // The framework carries the writer's declared argument with the
            // intent. A mismatch means the event's binding is not the one this
            // definition writes, so it is refused instead of being routed to the
            // operation's default argument.
            if (intent.argumentName.size > 0 && intent.argumentName != definition.argument) {
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

    /// The accepted binding of one card element: its identity plus the resolved
    /// writer/owner target. A consumer that rebuilds a layout node for an event
    /// (as the tests do) must carry these, because the adapter verifies the node
    /// against the accepted binding.
    public func acceptedCompositeElement(instanceKey: String, elementKey: String):
        ?CjguiCompositeElementBinding {
        for (binding in holder.compositeElementNodeIdsForKey(instanceKey)) {
            if (binding.elementKey == elementKey) {
                return Some(binding)
            }
        }
        return None
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

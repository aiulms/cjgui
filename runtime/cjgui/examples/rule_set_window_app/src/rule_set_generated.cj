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
import std.convert.*
import std.sync.*
import std.env.*

public class CjguiRuleSetGeneratedRegion <: CjguiGeneratedUiRegionBinding &
    CjguiSharedOperationGeneratedUiProvider &
    CjguiUiDocumentSurface {
    private let documentSurfaceIdentityValue: Int64 = cjguiNextUiDocumentSurfaceIdentity()
    private let domain: CjguiRuleSetEditingDomain
    private let ownerWriteObservation = RuleSetOwnerWriteObservation()
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    /// ONE option declaration for the enabled field. The handwritten Select and
    /// a generated composite select read the same option list; the generated
    /// per-instance row writes through the accepted element owner, never this
    /// single-owner commit closure.
    private let enabledSelectValue: CjguiSelectFieldBinding
    private let holder: CjguiGeneratedUiStructureHolder
    private let lock: Mutex
    /// The SAME preset the registered integer-edit composite carries, so the
    /// handwritten region reads one configuration instead of a second copy.
    private let compositePreset: CjguiRetentionPreset
    private var lastOutcome: String
    private var observedStructureVersion: Int64
    private var revisionValue: Int64
    // DS51 §12 C2: the candidate token THIS scene was built against (0 when the
    // scene renders the accepted structure). Defining a candidate submitted
    // AFTER this scene began belongs to a later scene.
    private var sceneCandidateToken: Int64 = 0
    /// The window whose accepted scene carries this region's generated nodes; the
    /// transport instance query has no window argument, so it is attached once.
    private var attachedWindow: ?CjguiComposableUiWindow = None
    /// ONE bounded change cursor over this region's real state. The snapshot and
    /// the change read both sample through it, so "the draft changed but the
    /// structure did not" and "the window was resized" are observable.
    private let tracker: CjguiGeneratedUiObservationTracker
    /// ONE shared multi-object adapter over the selected/default rule and the
    /// per-record object bindings. Created lazily because it holds `this` as its
    /// fallback; every submission/build reads the SAME instance.
    private var multiObjectValue: ?CjguiGeneratedUiRegionBinding = None
    private let bindingLock = Mutex()
    /// ONE application image declaration, shared by the handwritten beacon node
    /// and by any external generated reference. The version is part of the
    /// declaration: swapping the raster replaces it with the next version.
    private var beaconResourceValue: CjguiGeneratedUiImageResourceSpec
    // The owner projection the ACCEPTED scene was built from. Only revisions are
    // stored (never a business value): the pending stamp is captured at the
    // scene-build boundary, promoted when the window accepts that scene, and
    // discarded on rollback.
    private var acceptedOwnerStamp: Int64
    private var pendingOwnerStamp: Int64
    // Test-only WORK counters: how many times each section was really
    // serialized, and how many times the observation source enumerated the
    // accepted instances (the O(n) fingerprint pass). They exist so a lazy
    // section read can be reported as actual work, not only as fewer bytes.
    private var fieldsSerializationsValue: Int64
    private var structureSerializationsValue: Int64
    private var instancesSerializationsValue: Int64
    private var acceptedInstanceSamplesValue: Int64

    /// `observationHistoryLimit` bounds how many change entries the observation
    /// tracker retains; older cursors then require a resync. It defaults to the
    /// framework bound and exists so a test can exercise truncation on the real
    /// application instead of only on the tracker in isolation.
    public init(domain: CjguiRuleSetEditingDomain, presetOverride!: String = "",
                observationHistoryLimit!: Int64 = 128) {
        this.domain = domain
        this.lock = Mutex()
        let built = CjguiRuleSetGeneratedRegion.buildCatalog(domain, presetOverride: presetOverride)
        this.catalog = built[0]
        this.compositePreset = built[1].primary()
        this.enabledSelectValue = CjguiSelectFieldBinding("enabled", "rule-enabled-select",
            "rule-enabled",
            ArrayList<CjguiSelectOption>([
                CjguiSelectOption("enabled", "已启用", "true"),
                CjguiSelectOption("disabled", "已停用", "false")]),
            commit: { option =>
                domain.editBooleanFromHuman(CjguiRuleSetEditingDomain.formEnabledResourceId,
                    option.value == "true").applied
            })
        let _ = this.catalog.bindChoiceOptions("enabled", this.enabledSelectValue)
        this.holder = CjguiGeneratedUiStructureHolder(catalog,
            rootScope: CjguiComposableUiIdentityScope("rule-generated"))
        this.lastOutcome = "尚未提交生成结构"
        this.observedStructureVersion = 0
        this.revisionValue = 1
        this.tracker = CjguiGeneratedUiObservationTracker(historyLimit: observationHistoryLimit)
        // The declaration lives with the catalog that publishes it.
        this.beaconResourceValue = CjguiRuleSetGeneratedRegion.defaultBeacon()
        this.acceptedOwnerStamp = 0
        this.pendingOwnerStamp = 0
        this.fieldsSerializationsValue = 0
        this.structureSerializationsValue = 0
        this.instancesSerializationsValue = 0
        this.acceptedInstanceSamplesValue = 0
    }

    /// The application's ONE named paint role. It carries paint only, so the
    /// handwritten helper keeps its own size and a theme switch cannot move
    /// layout or re-measure text.
    public static func accentStyle(dark: Bool): CjguiComposableUiNamedStyle {
        let theme = if (dark) {
            CjguiComposableUiTheme.beaconDark()
        } else {
            CjguiComposableUiTheme.paperLight()
        }
        return CjguiComposableUiNamedStyle("rule_primary_action",
            CjguiComposableUiStyle(background: theme.primaryAction.background,
                border: theme.primaryAction.border, textColor: theme.primaryAction.textColor,
                borderWidth: theme.primaryAction.borderWidth),
            interaction: theme.primaryActionInteraction, purpose: "规则面板主操作")
    }

    /// The secondary counterpart from the SAME theme: low-frequency commands
    /// resolve this one named role instead of a neutral base style painted
    /// over by the primary interaction's `normal` state.
    public static func secondaryStyle(dark: Bool): CjguiComposableUiNamedStyle {
        let theme = if (dark) {
            CjguiComposableUiTheme.beaconDark()
        } else {
            CjguiComposableUiTheme.paperLight()
        }
        return CjguiComposableUiNamedStyle("rule_secondary_action",
            CjguiComposableUiStyle(background: theme.secondaryAction.background,
                border: theme.secondaryAction.border, textColor: theme.secondaryAction.textColor,
                borderWidth: theme.secondaryAction.borderWidth),
            interaction: theme.secondaryActionInteraction, purpose: "规则面板次要操作")
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

    /// The application's own appearance switch retargets the named roles. The
    /// new paint is published with the next accepted scene transaction; a removal
    /// would degrade paint only, never remove the controls.
    public func setAccentAppearance(dark: Bool): Bool {
        return synchronized(lock) {
            var result = catalog.namedStyles().update(CjguiRuleSetGeneratedRegion.accentStyle(dark))
            if (!catalog.namedStyles().update(CjguiRuleSetGeneratedRegion.secondaryStyle(dark))) {
                result = false
            }
            if (result) {
                revisionValue += 1
            }
            return result
        }
    }

    /// The default declaration the catalog builder registers (version 1).
    public static func defaultBeacon(): CjguiGeneratedUiImageResourceSpec {
        return CjguiGeneratedUiImageResourceSpec("rule-set-beacon", "PNG", 1,
            "规则面板图标", "composable-beacon.png")
    }

    /// The application's resolved beacon resource; the handwritten node and the
    /// generated reference both take path/key/version from here.
    public func beaconResource(): CjguiGeneratedUiImageResourceSpec {
        return synchronized(lock) { beaconResourceValue }
    }

    /// Swaps the beacon raster by declaring the NEXT version of the same key.
    /// The old version stops resolving, so a candidate that still references it
    /// is refused instead of silently showing the new image.
    public func setBeaconVersion(version: Int64): Bool {
        return synchronized(lock) {
            let path = if (version == 2) { "composable-beacon-coral.png" } else { "composable-beacon.png" }
            let spec = CjguiGeneratedUiImageResourceSpec("rule-set-beacon", "PNG", version,
                "规则面板图标", path)
            if (!catalog.updateImageResource(spec)) {
                return false
            }
            beaconResourceValue = spec
            revisionValue += 1
            return true
        }
    }

    /// The preset the handwritten region must use as well: the same value the
    /// registered composite writes.
    public func retentionPreset(): CjguiRetentionPreset {
        return compositePreset
    }

    /// The generated capability catalog is derived from the application's own
    /// definitions: the components/actions this window actually presents, and
    /// the field list from the *existing shared form binding* the handwritten
    /// form already uses. There is no second, hand-maintained field list, so a
    /// field cannot be named "retention" in one place and "retentionCount" in
    /// another.
    /// Content properties first, the framework's shared style vocabulary after,
    /// in one list. Registration validates both through the same checks, so a
    /// property cannot be published for a kind that ignores it.
    static func withStyleProperties(content: ArrayList<CjguiGeneratedUiPropertySpec>,
                                    style: ArrayList<CjguiGeneratedUiPropertySpec>):
        ArrayList<CjguiGeneratedUiPropertySpec> {
        let combined = ArrayList<CjguiGeneratedUiPropertySpec>()
        for (property in content) {
            combined.add(property)
        }
        for (property in style) {
            combined.add(property)
        }
        return combined
    }

    static func buildCatalog(domain: CjguiRuleSetEditingDomain,
                             presetOverride!: String = ""): (CjguiGeneratedUiCapabilityCatalog, CjguiRetentionPresetConfig) {
        let catalog = CjguiGeneratedUiCapabilityCatalog()
        // The style vocabulary comes from the framework's ONE shared definition
        // (size constraints, growth, alignment, font), so this application does
        // not hand-maintain a second subset that could drift from the mapping.
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
            CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 64))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("horizontal",
            CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 64))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
            withStyleProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 200)
            ]), CjguiGeneratedUiPresentation.leafStyleProperties()), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
            withStyleProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 100)
            ]), CjguiGeneratedUiPresentation.leafStyleProperties()), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("integerInput",
            withStyleProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 100)
            ]), CjguiGeneratedUiPresentation.leafStyleProperties()), false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("booleanInput",
            withStyleProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 100)
            ]), CjguiGeneratedUiPresentation.leafStyleProperties()), false))
        // The optional workspace set: Tabs/tabPage, ScrollArea, Split and the
        // built-in Image, all from the framework's ONE presentation vocabulary.
        // This is the same registration the mixed consumer uses; the application
        // no longer hand-copies their property lists.
        let workspaceIssue = CjguiGeneratedUiWorkspaceCatalog.registerInto(catalog,
            includeImage: true)
        if (workspaceIssue.size > 0) {
            throw Exception(workspaceIssue)
        }
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("stack",
            CjguiGeneratedUiPresentation.stackStyleProperties(), true, childLimit: 64))
        let wrapProperties = CjguiGeneratedUiPresentation.wrapContentProperties()
        for (property in CjguiGeneratedUiPresentation.containerStyleProperties()) {
            wrapProperties.add(property)
        }
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("wrap", wrapProperties, true,
            childLimit: 64))
        let aspectProperties = CjguiGeneratedUiPresentation.aspectRatioContentProperties()
        for (property in CjguiGeneratedUiPresentation.boxProperties()) {
            aspectProperties.add(property)
        }
        aspectProperties.add(CjguiGeneratedUiPropertySpec("padding", "INTEGER", minimum: 0, maximum: 32,
            defaultValue: "0"))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("aspectRatio", aspectProperties, true,
            childLimit: 1))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("spacer",
            CjguiGeneratedUiPresentation.spacerContentProperties(), false))

        // The ONE image declaration, registered where the catalog is built so the
        // published capability text and the region always agree.
        let _ = catalog.registerImageResource(CjguiRuleSetGeneratedRegion.defaultBeacon())
        // ONE named paint role shared by the handwritten helper, generated action
        // nodes and the registered composite. The application owns the values; the
        // framework resolves, validates and publishes them. The secondary role is
        // the SAME kind of declaration for low-frequency commands.
        let _ = catalog.namedStyles().register(CjguiRuleSetGeneratedRegion.accentStyle(false))
        let _ = catalog.namedStyles().register(CjguiRuleSetGeneratedRegion.secondaryStyle(false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action",
            withStyleProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60),
                CjguiGeneratedUiPropertySpec("action", "STRING", maxLength: 60)
            ]), CjguiGeneratedUiPresentation.leafStyleProperties()), false))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("APPLY_DRAFT", "应用草稿",
            parameterNames: domain.actionArgumentNames("APPLY_DRAFT")))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("CANCEL_DRAFT", "取消草稿",
            parameterNames: domain.actionArgumentNames("CANCEL_DRAFT")))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("SET_DETAIL_LAYOUT_STANDARD", "标准布局"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("SET_DETAIL_LAYOUT_COMPACT", "紧凑布局"))
        // One definition: the domain's shared form binding (the same object the
        // handwritten form field list and the external field read come from),
        // plus the writer operations' own argument names from that same domain, so
        // the published field carries the real argument for either editor kind.
        let _ = catalog.registerFields(CjguiGeneratedUiFieldSpec.fromFormBinding(domain.formBinding(),
            textArgument: domain.draftTextArgumentName(),
            booleanArgument: domain.draftBooleanArgumentName()))
        // The reusable integer-edit composite (numeric input + preset button),
        // registered with presets derived from the field's OWN declared bounds so
        // the application keeps no second copy of the business limit. A dedicated
        // negative-control launch may configure an out-of-range preset instead;
        // the owner's rule then refuses it rather than the widget clamping it.
        let retention = catalog.fieldFor("retentionCount")
        // A dedicated negative-control launch may configure an explicit
        // (deliberately out-of-range) preset; a normal launch derives them from
        // the field's own declared bounds.
        let presetConfig = if (presetOverride.size > 0) {
            CjguiRetentionPresetConfig.explicit(presetOverride)
        } else {
            match (retention) {
                case Some(field) => CjguiRetentionPresetConfig.fromDeclaredBounds(field.minimum, field.maximum)
                case None => CjguiRetentionPresetConfig.explicit("30")
            }
        }
        let _ = CjguiRetentionIntegerEditComposite.registerInto(catalog, presetConfig,
            domain.draftTextArgumentName())
        let _ = CjguiRuleSetFeedbackComposites.registerInto(catalog)
        return (catalog, presetConfig)
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

    public func ownerRevision(): Int64 {
        return domain.version()
    }

    /// The owner target an instance key resolves to RIGHT NOW. Kept public so
    /// the shared object wrapper can prove its own identity; a retired key is -1.
    public func ownerForKey(instanceKey: String): Int64 {
        return ownerForInstanceKey(instanceKey)
    }

    /// The ONE shared adapter every generated read/action/field-intent uses.
    private func binding(): CjguiGeneratedUiRegionBinding {
        return synchronized(bindingLock) {
            if (let Some(value) <- multiObjectValue) {
                return value
            }
            let created = CjguiGeneratedUiMultiObjectBinding(this,
                { key => key.startsWith("rule") && key.size > 4 },
                { key => ruleSetObjectBinding(this, key) },
                ownerBlockedReason: { => "" })
            multiObjectValue = Some(created)
            return created
        }
    }

    public func fieldResourceId(fieldId: String): Int64 {
        return resourceIdForField(fieldId)
    }

    /// The ONE enabled option declaration, shared with the handwritten Select.
    public func enabledSelectBinding(): CjguiSelectFieldBinding {
        return enabledSelectValue
    }

    /// A generated composite element resolves its option set here; the actual
    /// write still resolves through that element's accepted owner target.
    public func generatedSelectBinding(fieldId: String): ?CjguiSelectFieldBinding {
        if (fieldId == "enabled") { return Some(enabledSelectValue) }
        return None
    }

    /// The generated field edits the record currently selected in the domain
    /// at projection time; the accepted node carries this target so a late
    /// event writes the record it was rendered for, never a later selection.
    public func fieldOperationResourceId(fieldId: String): Int64 {
        if (resourceIdForField(fieldId) < 0) { return -1 }
        return domain.selectedRecordId()
    }

    /// A declared instance key may NAME its owner (`rule<recordId>`): that is an
    /// app-owned instance identity, not a fabricated object. Any other key keeps
    /// the normal single-owner meaning (the selected record).
    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        if (resourceIdForField(fieldId) < 0) { return -1 }
        return ownerForInstanceKey(instanceKey)
    }

    public func actionOperationResourceId(actionName: String, instanceKey: String): Int64 {
        // Global layout actions belong to the RULE SET owner, never to whatever
        // record happens to be selected or named by the instance key.
        if (actionName == "SET_DETAIL_LAYOUT_STANDARD" || actionName == "SET_DETAIL_LAYOUT_COMPACT") {
            return CjguiRuleSetEditingDomain.ruleSetResourceId
        }
        return ownerForInstanceKey(instanceKey)
    }

    private func ownerForInstanceKey(instanceKey: String): Int64 {
        if (instanceKey.startsWith("rule") && instanceKey.size > 4) {
            if (let Some(id) <- Int64.tryParse(instanceKey[4..])) {
                return if (domain.hasRecord(id)) { id } else { -1 }
            }
            return -1
        }
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
        if (actionName == "SET_DETAIL_LAYOUT_STANDARD" || actionName == "SET_DETAIL_LAYOUT_COMPACT") {
            return true
        }
        if (actionName == "APPLY_DRAFT" || actionName == "CANCEL_DRAFT" ||
            actionName == CjguiRetentionIntegerEditComposite.STEP_DOWN_ACTION ||
            actionName == CjguiRetentionIntegerEditComposite.STEP_UP_ACTION) {
            return domain.selectedRecordId() >= 0
        }
        return false
    }

    /// The rule domain's OWN dynamic condition, expressed through the same shared
    /// adapter the task domain uses (`CjguiSharedAvailability`). It is deliberately
    /// NOT the task's immediate-write model: this domain edits a DRAFT, so a field
    /// stays editable while a rule is selected, and only the APPLY action is
    /// additionally gated by the domain's own `canApply` condition. It is a read:
    /// nothing is written and nothing is authorized.
    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        if (resourceIdForField(fieldId) < 0) {
            return CjguiSharedAvailability.unknown()
        }
        let recordId = domain.selectedRecordId()
        if (recordId < 0) {
            return CjguiSharedAvailability.blocked("rule_not_selected", recordId, domain.version())
        }
        return CjguiSharedAvailability.allowed(recordId, domain.version())
    }

    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        if (actionName == "SET_DETAIL_LAYOUT_STANDARD" || actionName == "SET_DETAIL_LAYOUT_COMPACT") {
            return CjguiSharedAvailability.allowed(CjguiRuleSetEditingDomain.ruleSetResourceId, domain.version())
        }
        if (actionName != "APPLY_DRAFT" && actionName != "CANCEL_DRAFT" &&
            actionName != CjguiRetentionIntegerEditComposite.STEP_DOWN_ACTION &&
            actionName != CjguiRetentionIntegerEditComposite.STEP_UP_ACTION) {
            return CjguiSharedAvailability.unknown()
        }
        let recordId = domain.selectedRecordId()
        if (recordId < 0) {
            return CjguiSharedAvailability.blocked("rule_not_selected", recordId, domain.version())
        }
        if (actionName == "APPLY_DRAFT" && !domain.formSnapshot().canApply) {
            let status = domain.formSnapshot().statusMessage
            let reason = if (status.size > 0) { status } else { "rule_apply_blocked" }
            return CjguiSharedAvailability.blocked(reason, recordId, domain.version())
        }
        return CjguiSharedAvailability.allowed(recordId, domain.version())
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        if (actionName == "SET_DETAIL_LAYOUT_STANDARD" || actionName == "SET_DETAIL_LAYOUT_COMPACT") {
            let invocation = CjguiSharedOperationActionInvocation(actionName, 0,
                ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]),
                ArrayList<CjguiSharedOperationActionArgument>())
            let result = domain.executeFromHuman(invocation)
            synchronized(lock) {
                lastOutcome = if (result.applied) { "字段布局已切换" } else { "字段布局切换被拒：${result.reason}" }
                revisionValue += 1
            }
            return CjguiGeneratedUiActionResult(result.applied, result.reason)
        }
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

    // --- instance-scoped owner projection ------------------------------------
    // A declared instance key NAMES its owner (`rule<recordId>`); every other
    // key keeps the single-owner meaning (the selected record). Values,
    // availability and action transactions below all read the SAME per-owner
    // snapshot, so one instance can never display, promise or write another
    // object just because the selection moved.

    /// The snapshot of the owner an instance key resolves to RIGHT NOW, or None
    /// when that owner is gone. A missing owner has no projection: its
    /// instance facts are unknown, never another record's.
    private func instanceSnapshot(instanceKey: String): ?CjguiSharedFormSnapshot {
        if (instanceKey.startsWith("rule") && instanceKey.size > 4) {
            if (let Some(id) <- Int64.tryParse(instanceKey[4..])) {
                return domain.formSnapshotForRecord(id)
            }
            return None
        }
        let selected = domain.selectedRecordId()
        if (selected < 0) {
            return None
        }
        return domain.formSnapshotForRecord(selected)
    }

    public func draftText(fieldId: String, instanceKey: String): String {
        let resourceId = resourceIdForField(fieldId)
        if (resourceId < 0) {
            return ""
        }
        return match (instanceSnapshot(instanceKey)) {
            case Some(snapshot) => snapshot.fieldForResourceId(resourceId).draftText
            case None => ""
        }
    }

    public func draftBoolean(fieldId: String, instanceKey: String): ?Bool {
        let resourceId = resourceIdForField(fieldId)
        if (resourceId < 0) {
            return None
        }
        let snapshot = match (instanceSnapshot(instanceKey)) {
            case Some(value) => value
            case None => return None
        }
        let field = snapshot.fieldForResourceId(resourceId)
        if (field.appliedValue.valueType != "BOOLEAN") {
            return None
        }
        return Some(field.draftText == "true" ||
            (field.draftText.size == 0 && field.appliedValue.booleanValue))
    }

    public func fieldAvailability(fieldId: String, instanceKey: String): CjguiSharedAvailability {
        if (resourceIdForField(fieldId) < 0) {
            return CjguiSharedAvailability.unknown()
        }
        return match (instanceSnapshot(instanceKey)) {
            case Some(snapshot) =>
                CjguiSharedAvailability.allowed(ownerForInstanceKey(instanceKey), snapshot.contextVersion)
            case None => CjguiSharedAvailability.blocked("owner_unknown", -1, domain.version())
        }
    }

    public func actionAvailability(actionName: String, instanceKey: String): CjguiSharedAvailability {
        if (actionName == "SET_DETAIL_LAYOUT_STANDARD" || actionName == "SET_DETAIL_LAYOUT_COMPACT") {
            return CjguiSharedAvailability.allowed(CjguiRuleSetEditingDomain.ruleSetResourceId, domain.version())
        }
        if (actionName != "APPLY_DRAFT" && actionName != "CANCEL_DRAFT" &&
            actionName != CjguiRetentionIntegerEditComposite.STEP_DOWN_ACTION &&
            actionName != CjguiRetentionIntegerEditComposite.STEP_UP_ACTION) {
            return CjguiSharedAvailability.unknown()
        }
        let snapshot = match (instanceSnapshot(instanceKey)) {
            case Some(value) => value
            case None => return CjguiSharedAvailability.blocked("owner_unknown", -1, domain.version())
        }
        let owner = ownerForInstanceKey(instanceKey)
        if (actionName == "APPLY_DRAFT") {
            // The SAME conditions the owner's apply transaction enforces,
            // evaluated against the SAME declared descriptors the draft
            // validator uses: an out-of-bounds or missing draft is refused
            // with invalid_draft, and a clean draft has nothing to apply. The
            // enabled state never promises a write the owner will refuse.
            let draftIssue = draftValidationIssueForSnapshot(snapshot)
            if (draftIssue.size > 0) {
                return CjguiSharedAvailability.blocked(draftIssue, owner, snapshot.contextVersion)
            }
            if (!snapshot.canApply) {
                let status = snapshot.statusMessage
                let reason = if (status.size > 0) { status } else { "rule_apply_blocked" }
                return CjguiSharedAvailability.blocked(reason, owner, snapshot.contextVersion)
            }
        }
        return CjguiSharedAvailability.allowed(owner, snapshot.contextVersion)
    }

    /// Evaluates the owner's declared draft rules (required text, INTEGER
    /// bounds, declared length) against one owner's own snapshot. The
    /// descriptors are the same `formBinding()` entries `validateDraftUnlocked`
    /// enforces; this is a read, the owner still re-checks inside its
    /// transaction.
    private func draftValidationIssueForSnapshot(snapshot: CjguiSharedFormSnapshot): String {
        let descriptors = domain.formBinding().allFields()
        for (field in snapshot.allFields()) {
            if (field.appliedValue.valueType == "BOOLEAN") {
                continue
            }
            var declared: ?CjguiSharedFormFieldDescriptor = None
            for (descriptor in descriptors) {
                if (descriptor.fieldId == field.fieldId) {
                    declared = Some(descriptor)
                    break
                }
            }
            let text = field.draftText
            if (text.size == 0) {
                if (declared.isSome() && declared.getOrThrow().required) {
                    return "${field.fieldId}_required"
                }
                continue
            }
            if (declared.isNone()) {
                continue
            }
            let descriptor = declared.getOrThrow()
            if (descriptor.editorKind == "INTEGER") {
                if (let Some(value) <- Int64.tryParse(text)) {
                    if (descriptor.minimum != 0 || descriptor.maximum != 0) {
                        if (value < descriptor.minimum || value > descriptor.maximum) {
                            return "${field.fieldId}_out_of_range"
                        }
                    }
                } else {
                    return "${field.fieldId}_invalid"
                }
            }
            if (descriptor.editorKind == "TEXT" && descriptor.maximumLength > 0) {
                if (text.toRuneArray().size > descriptor.maximumLength) {
                    return "${field.fieldId}_too_long"
                }
            }
        }
        return ""
    }

    public func formFeedback(instanceKey: String): ?CjguiGeneratedUiFormFeedback {
        let owner = ownerForInstanceKey(instanceKey)
        let snapshot = match (instanceSnapshot(instanceKey)) {
            case Some(value) => value
            case None => return None
        }
        // ONE snapshot of THIS owner answers every fact the card shows.
        let fieldStates = HashMap<String, CjguiSharedAvailability>()
        for (field in domain.formBinding().allFields()) {
            fieldStates.add(field.fieldId, fieldAvailability(field.fieldId, instanceKey))
        }
        let actionStates = HashMap<String, CjguiSharedAvailability>()
        for (action in domain.actionDescriptors()) {
            actionStates.add(action.name, actionAvailability(action.name, instanceKey))
        }
        return Some(CjguiGeneratedUiFormFeedback(snapshot, domain.formBinding(), owner,
            fieldStates, actionStates))
    }

    /// Instance action with the ORIGINAL accepted owner target and generation.
    /// A key that no longer resolves to that exact record is a retired binding:
    /// refused by name, never executed on the record now behind the key (or the
    /// selected one). The transaction carries the target's own draft version.
    public func executeAction(actionName: String, nodeKey: String, instanceKey: String,
        ownerTargetResourceId: Int64, instanceIncarnation: Int64): CjguiGeneratedUiActionResult {
        let _ = instanceIncarnation
        let resolved = ownerForInstanceKey(instanceKey)
        if (resolved < 0 || resolved != ownerTargetResourceId) {
            return CjguiGeneratedUiActionResult(false, "owner_target_retired")
        }
        return executeActionForInstance(actionName, nodeKey, instanceKey)
    }

    /// The object wrapper's action entry: the adapter has already proved the
    /// accepted target, and this re-resolves the key to that owner's CURRENT
    /// snapshot. A deleted key writes nothing instead of using the selection.
    public func executeActionForInstance(actionName: String, nodeKey: String,
        instanceKey: String): CjguiGeneratedUiActionResult {
        let _ = nodeKey
        let resolved = ownerForInstanceKey(instanceKey)
        if (resolved < 0) {
            return CjguiGeneratedUiActionResult(false, "owner_target_retired")
        }
        let snapshot = match (instanceSnapshot(instanceKey)) {
            case Some(value) => value
            case None => return CjguiGeneratedUiActionResult(false, "owner_target_retired")
        }
        let arguments = ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("expectedDraftVersion",
                CjguiSharedOperationValue.integer(snapshot.draftVersion))
        ])
        let invocation = CjguiSharedOperationActionInvocation(actionName, snapshot.appliedConfigVersion,
            ArrayList<Int64>([resolved]), arguments)
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

    /// This provider keeps the whole-value owner writer and never binds an
    /// owned range session, so the range transaction is refused by name.
    public func applyTextEdit(fieldId: String, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        let _ = fieldId
        let _ = expectedVersion
        let _ = newText
        return CjguiRangeTextEditOutcome.rejected(-1, "text_edit_unsupported")
    }

    public func applyTextEdit(fieldId: String, expectedVersion: Int64, newText: String,
        instanceKey: String): CjguiRangeTextEditOutcome {
        let _ = instanceKey
        return applyTextEdit(fieldId, expectedVersion, newText)
    }

    /// ONE field-intent route for the default form and every per-record object.
    /// The event's ORIGINAL owner target must still be the key's owner; the
    /// domain transaction then applies the whole value to THAT record.
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        if (!intent.isFieldEdit()) {
            return CjguiComposableUiDispatchResult(false)
        }
        let field = match (fieldSpec(intent.fieldId)) {
            case Some(value) => value
            case None => return CjguiComposableUiDispatchResult(false)
        }
        if (intent.ownerTargetResourceId < 0) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (intent.instanceKey.size > 0 &&
            ownerForInstanceKey(intent.instanceKey) != intent.ownerTargetResourceId) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (field.editorKind == "BOOLEAN") {
            let result = domain.editBooleanForCollectionItemFromHuman(intent.ownerTargetResourceId,
                field.resourceId, intent.value.booleanValue)
            return finishGeneratedEdit(result, "布尔草稿")
        }
        let result = domain.editTextForCollectionItemFromHuman(intent.ownerTargetResourceId,
            field.resourceId, intent.value.stringValue, intent.selectionStart, intent.selectionEnd)
        return finishGeneratedEdit(result, "文本草稿")
    }

    // --- external structure provider ---------------------------------------

    private var documentHistoryAccessValue: ?CjguiUiDocumentHistoryAccess = None
    private func documentHistoryAccess(): CjguiUiDocumentHistoryAccess {
        return synchronized(lock) {
            if (let Some(value) <- documentHistoryAccessValue) { return value }
            let value = CjguiUiDocumentHistoryAccess(this)
            documentHistoryAccessValue = Some(value)
            value
        }
    }
    public func capabilitiesPayload(): String {
        return CjguiUiDocumentHistoryAccess.capabilitiesPayload(CjguiGeneratedUiEncoding.describe(catalog))
    }
    public func acceptedUiDocumentVersion(): Int64 { return acceptedStructureVersion() }
    public func attachUiDocumentWorkspace(workspace: CjguiUiDocumentWorkspace): String {
        return documentHistoryAccess().attach(workspace)
    }
    public func detachUiDocumentWorkspace(workspace: CjguiUiDocumentWorkspace): Unit {
        let access = synchronized(lock) { documentHistoryAccessValue }
        if (let Some(value) <- access) { value.detach(workspace) }
    }
    public func uiDocumentHistoryPayload(): String { return documentHistoryAccess().payload() }
    public func submitUiDocumentHistory(action: String, expectedVersion: Int64, expectedDigest: String,
        surfaceIdentity: Int64, historyEpoch: Int64): CjguiSharedOperationGeneratedUiSubmit {
        return documentHistoryAccess().submit(action, expectedVersion, expectedDigest, surfaceIdentity, historyEpoch)
    }

    /// The window this region's accepted instances belong to. The transport
    /// provider has no window argument, so the application attaches it once at
    /// startup - the same wiring the tree selection provider already uses.
    public func attachWindow(window: CjguiComposableUiWindow): Unit {
        attachedWindow = Some(window)
    }

    /// Accepted generated instances addressed by DECLARED key, with the accepted
    /// geometry: an external caller can therefore address a generated control by
    /// identity instead of by a display caption. Empty before a window is
    /// attached or before anything is accepted - never guessed.
    public func acceptedInstancesPayload(): String {
        instancesSerializationsValue += 1
        match (attachedWindow) {
            case Some(window) => return CjguiGeneratedUiEncoding.acceptedInstancesPayload(
                cjguiGeneratedUiAcceptedInstances(window, holder))
            case None => return ""
        }
    }

    /// Live field projections from the same shared form binding the
    /// handwritten form uses: draft text, applied value, validation, focus and
    /// selection. Hex encoding keeps arbitrary text on one protocol line.
    /// ONE owner's field projection from that owner's OWN draft facts: the same
    /// projection the selected record publishes, built without changing the
    /// selection, the focused field or the business version. An unknown or
    /// deleted owner stays empty (the transport turns that into a named refusal)
    /// and is never answered with another record's fields.
    private func fieldsPayloadForProjectedOwner(ownerResourceId: Int64): String {
        if (ownerResourceId < 0) { return "" }
        let form = match (domain.formSnapshotForRecord(ownerResourceId)) {
            case Some(snapshot) => snapshot
            case None => return ""
        }
        fieldsSerializationsValue += 1
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

    /// The SAME projection for ONE accepted generated instance. The accepted
    /// instance table (not a provider map) decides whether the key exists and
    /// which owner it binds; an unknown, retired or differently-owned instance
    /// is refused here rather than answered with the unscoped record.
    public func fieldsPayload(instanceKey: String): String {
        if (instanceKey.isEmpty() || !holder.isAcceptedCompositeInstanceKey(instanceKey)) {
            return ""
        }
        return fieldsPayloadForProjectedOwner(holder.compositeOwnerTargetForInstance(instanceKey))
    }

    /// The same projection addressed by the instance's accepted owner id. The
    /// holder must bind exactly ONE accepted instance to this owner; ambiguous
    /// or unbound owners stay empty.
    public func fieldsPayloadForOwner(ownerResourceId: Int64): String {
        if (ownerResourceId < 0) {
            return ""
        }
        if (holder.compositeInstanceKeyForOwnerTarget(ownerResourceId).isEmpty()) {
            return ""
        }
        return fieldsPayloadForProjectedOwner(ownerResourceId)
    }

    /// Accepted owner target bound to one instance key, or -1 when the key has
    /// no accepted composite element. The transport uses it to authorize a
    /// per-instance read; an unscoped answer never stands in for it.
    public func instanceOwnerResourceId(instanceKey: String): Int64 {
        if (instanceKey.isEmpty()) {
            return -1
        }
        return holder.compositeOwnerTargetForInstance(instanceKey)
    }

    public func fieldsPayload(): String {
        return fieldsPayloadForProjectedOwner(domain.selectedRecordId())
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

    /// Registers the controller's public collection declaration in THIS
    /// region's catalog so a generated structure may mount it as a normal
    /// composite. The collection's data/selection stay application-owned.
    public func registerCollection(collection: CjguiGeneratedUiCollection): Bool {
        return synchronized(lock) { collection.register(catalog) }
    }

    /// The accepted generated collection mount this event's EXACT viewport
    /// belongs to, restricted to this region's holder. Stale/foreign events
    /// resolve to None.
    public func acceptedCollectionViewForEvent(collection: CjguiGeneratedUiCollection,
        event: CjguiComposableUiEvent): ?CjguiGeneratedCollectionView {
        return synchronized(lock) {
            let viewport = match (event.node.scrollViewport) {
                case Some(value) => value
                case None => return None
            }
            let view = match (collection.acceptedViewForViewport(viewport)) {
                case Some(value) => value
                case None => return None
            }
            return if (view.holderIdentity() == holder.holderIdentity()) { Some(view) } else { None }
        }
    }

    public func acceptedStructurePayload(): String {
        structureSerializationsValue += 1
        return synchronized(lock) {
            CjguiGeneratedUiEncoding.encode(holder.acceptedStructure(), holder.structureVersion(),
                definitions: catalog.acceptedCompositionPayload())
        }
    }

    public func acceptedStructureVersion(): Int64 {
        return synchronized(lock) { holder.structureVersion() }
    }

    private func acceptedUiDocumentUnlocked(): CjguiGeneratedUiAcceptedDocument {
        let definitions = catalog.acceptedCompositionPayload()
        let formatVersion = if (definitions.size > 0) { 2 } else { 1 }
        let text = CjguiGeneratedUiEncoding.encodeCandidate(holder.acceptedStructure(),
            formatVersion, definitions: definitions)
        return CjguiGeneratedUiAcceptedDocument(text, holder.structureVersion(),
            cjguiUiDocumentDigest(text))
    }

    /// ONE consistent accepted document fact for the shared document session:
    /// the portable candidate text, its accepted version and its digest.
    public func acceptedUiDocument(): CjguiGeneratedUiAcceptedDocument {
        return synchronized(lock) { acceptedUiDocumentUnlocked() }
    }

    public func uiDocumentSurfaceIdentity(): Int64 {
        return documentSurfaceIdentityValue
    }

    /// The document session's ONLY settlement source: the holder's real ticket
    /// plus the accepted document taken under the same region lock.
    public func uiDocumentTicket(token: Int64): CjguiUiDocumentTicket {
        return synchronized(lock) {
            let accepted = acceptedUiDocumentUnlocked()
            let record = match (holder.candidateRecord(token)) {
                case Some(value) => value
                case None => return CjguiUiDocumentTicket(token, false, "UNKNOWN",
                    "none", "", 0, accepted.version, accepted.digest)
            }
            return CjguiUiDocumentTicket(token, true, record.terminalState(),
                if (record.sceneState().size > 0) { record.sceneState() } else { "none" },
                record.reason(), record.acceptedVersion(), accepted.version, accepted.digest)
        }
    }

    public func submitUiDocument(candidate: String,
        expectedVersion: Int64): CjguiUiDocumentSubmit {
        let submitted = submitStructure(candidate, expectedVersion)
        return CjguiUiDocumentSubmit(submitted.candidateAccepted, submitted.reason,
            submitted.candidateToken)
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

    /// Terminal read for ONE submission attempt. An unknown token answers
    /// `TERMINAL_STATE UNKNOWN` (the holder's ticket table is bounded), which is
    /// deliberately not an error and not another attempt's state.
    public func candidateTicketPayload(token: Int64): String {
        return synchronized(lock) { holder.candidateTicketPayload(token) }
    }

    /// DS51 §12 C2 seam diagnostic: the pending (or latest) attempt's ticket,
    /// naming the real rejection reason/path instead of the window's generic
    /// internal_error. Read-only; it never settles or publishes the candidate.
    public func candidateTicketForDiagnosis(): String {
        return synchronized(lock) {
            let token = if (holder.pendingCandidateToken() > 0) {
                holder.pendingCandidateToken()
            } else {
                holder.latestCandidateToken()
            }
            holder.candidateTicketPayload(token)
        }
    }

    /// Samples this application's real observation source: owner business and
    /// draft revisions from the shared form binding, holder structure/candidate
    /// state, and the attached window's accepted scene / geometry / interaction
    /// revisions. Building it performs no build, layout or submit.
    /// The owner draft revision the fields projection is derived from.
    private func draftRevisionValue(): Int64 {
        let form = domain.formSnapshot()
        var draftRevision: Int64 = 0
        for (fieldId in catalog.fieldIds()) {
            let resourceId = resourceIdForField(fieldId)
            if (resourceId < 0) { continue }
            let field = form.fieldForResourceId(resourceId)
            draftRevision = draftRevision * 31 + field.draftFieldVersion
        }
        return draftRevision
    }

    /// Revision pair of the owner projection the generated region presents. It
    /// is a comparison key only; it never becomes a second business version.
    private func ownerStamp(): Int64 {
        return domain.version() * 1000003 + draftRevisionValue()
    }

    private func observationSource(): CjguiGeneratedUiObservationSource {
        let draftRevision = draftRevisionValue()
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
        return CjguiGeneratedUiObservationSource(identity, domain.version(), draftRevision,
            cjguiGeneratedUiBindingRevision(instances), holder.structureVersion(),
            holder.latestCandidateToken(), holder.lastSceneOutcome(), sceneVersion,
            cjguiGeneratedUiGeometryRevision(instances), interactionRevision,
            cjguiGeneratedUiInstanceRevision(instances),
            // owner progress is a real association, not the structure candidate
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

    /// Test-only: real serialization work per section plus how many observation
    /// samples enumerated the accepted instances. `counts=fields:x structure:y
    /// instances:z samples:s`.
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
            // Guard the cursor FIRST: an invalid cursor must not serialize any
            // section, and a valid one serializes ONLY the requested section.
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
        // The token is allocated BEFORE the payload is decoded: a malformed
        // candidate or a structure-version conflict is still an attempt the
        // caller can ask about, and it must not be attributed to another
        // submitter that happens to share the base version.
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
                return CjguiSharedOperationGeneratedUiSubmit(false, "empty_structure", "", expectedVersion,
                    expectedVersion, candidateToken: token,
                    receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
        }
        return synchronized(lock) {
            // Structure CAS: a candidate built against another structure
            // version is rejected; the accepted interface stays in place.
            let current = holder.structureVersion()
            if (expectedVersion != current) {
                holder.rejectCandidateAttempt(token, "structure_version_conflict", "")
                lastOutcome = "结构版本冲突：期望 ${expectedVersion}，当前 ${current}"
                return CjguiSharedOperationGeneratedUiSubmit(false, "structure_version_conflict", "",
                    current, current, candidateToken: token,
                    receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
            }
            // A definition, its deletions and its instances travel in this same
            // candidate ticket. A rejected B restores the pending A's overlay.
            let previousOverlay = catalog.snapshotStagedComposites()
            catalog.rollbackStagedComposites()
            let definitionIssue = cjguiStageRuntimeCompositions(catalog, decoded.definitions)
            if (definitionIssue.size > 0) {
                catalog.restoreStagedComposites(previousOverlay)
                holder.rejectCandidateAttempt(token, definitionIssue, "")
                lastOutcome = "结构被拒：${definitionIssue}"
                return CjguiSharedOperationGeneratedUiSubmit(false, definitionIssue, "",
                    current, current, candidateToken: token,
                    receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
            }
            for (removed in decoded.removals) {
                let removalIssue = catalog.stageCompositionRemoval(removed)
                if (removalIssue.size > 0) {
                    catalog.restoreStagedComposites(previousOverlay)
                    holder.rejectCandidateAttempt(token, removalIssue, "")
                    lastOutcome = "结构被拒：${removalIssue}"
                    return CjguiSharedOperationGeneratedUiSubmit(false, removalIssue, "",
                        current, current, candidateToken: token,
                        receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
                }
                if (cjguiCompositionReferences(root, removed)) {
                    catalog.restoreStagedComposites(previousOverlay)
                    let issue = "composition_remove_still_referenced:${removed}"
                    holder.rejectCandidateAttempt(token, issue, "")
                    lastOutcome = "结构被拒：${issue}"
                    return CjguiSharedOperationGeneratedUiSubmit(false, issue, "",
                        current, current, candidateToken: token,
                        receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
                }
            }
            let result = holder.submit(root, binding(), attemptToken: token)
            if (!result.candidateAccepted) {
                catalog.restoreStagedComposites(previousOverlay)
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
                sceneAccepted: result.sceneAccepted, candidateVersion: result.candidateVersion,
                candidateToken: result.candidateToken, receipt: result.receipt)
        }
    }

    // --- window scene-refresh transaction ----------------------------------
    // The generated candidate, its component identities and its binding table
    // take effect together with the window's accepted scene. Until the commit
    // hook runs, the public accepted structure/version and the event routing
    // table are exactly what they were.

    public func beginSceneRefresh(): Bool {
        return synchronized(lock) {
            // Style resolutions belong to the scene being built from here on.
            holder.beginStyleRefresh()
            sceneCandidateToken = holder.pendingCandidateToken()
            getStdOut().writeln("CJGUIRULE_SCENE_BEGIN candidateToken=${sceneCandidateToken} " +
                "pending=${holder.hasPendingCandidate()} accepted=${holder.structureVersion()}")
            getStdOut().flush()
            return holder.beginCandidateRefresh()
        }
    }

    public func prepareSceneRefresh(): Bool {
        return synchronized(lock) { holder.prepareCandidateRefresh() }
    }

    public func commitSceneRefresh(): Unit {
        synchronized(lock) {
            // The window accepted THIS scene: promote the owner projection it was
            // built from, so a later owner write is the only thing pending. This
            // happens for an ORDINARY refresh too - a normal business write has
            // no structure candidate, and its accepted projection must still
            // clear the pending flag.
            acceptedOwnerStamp = pendingOwnerStamp
            // The scene this build produced is being accepted: promote the style
            // resolutions it used. Runs for an ordinary refresh too, where no
            // candidate exists.
            holder.commitStyleRefresh()
            let sceneToken = sceneCandidateToken
            sceneCandidateToken = 0
            let pendingNow = holder.pendingCandidateToken()
            let superseded = sceneToken > 0 && pendingNow != sceneToken
            getStdOut().writeln("CJGUIRULE_SCENE_COMMIT sceneToken=${sceneToken} pending=${pendingNow} " +
                "superseded=${superseded} staged=${catalog.hasStagedComposites()} " +
                "accepted=${holder.structureVersion()}")
            getStdOut().flush()
            // An ordinary refresh - or a scene whose candidate was superseded
            // before it built - has NO candidate to settle and must never touch
            // the definition overlay: it may belong to the newer candidate.
            if (sceneToken <= 0 || superseded) {
                // An ordinary/superseded scene is still a REAL accepted render:
                // the mounts it built belong to the accepted structure, so their
                // view state must be settled here (the framework window region
                // does the same). Leaving the transaction open would build the
                // scene but never publish its accepted collection mounts.
                holder.settleAcceptedRenderViewState()
                holder.discardSceneViewState()
                return
            }
            if (holder.commitCandidateRefresh()) {
                // The definition directory publishes in the SAME acceptance
                // step as the instances it expands.
                catalog.commitStagedComposites()
                lastOutcome = "结构已接受：v${holder.structureVersion()}"
            } else {
                // The scene's own candidate could not be published: settle it as
                // rejected instead of leaving it pending with dropped
                // definitions (a later build would then fail on a missing kind).
                holder.rollbackCandidateRefresh(holder.lastSceneOutcome())
                catalog.rollbackStagedComposites()
                lastOutcome = "场景拒绝：${holder.lastSceneOutcome()}"
            }
            revisionValue += 1
        }
    }

    /// How many shared-catalog image identities this window still holds.
    public func liveImageIdentityHoldCount(): Int64 {
        return holder.liveImageIdentityHoldCount()
    }

    /// Releases this window's holds on the SHARED resource catalog. Called from
     /// the window's dispose path (normal close or startup/native failure), never
     /// by the caller of an ordinary refresh.
    public func releaseImageIdentities(): Unit {
        synchronized(lock) {
            // Closing settles the SAME ticket the submit allocated: a pending
            // definition must not survive the window that owns it.
            if (holder.hasPendingCandidate()) {
                holder.rejectCandidateAttempt(holder.pendingCandidateToken(), "window_closed", "")
                holder.rollbackCandidateRefresh()
                revisionValue += 1
            }
            catalog.rollbackStagedComposites()
            holder.releaseAcceptedImageIdentities()
        }
    }

    public func rollbackSceneRefresh(): Unit {
        rollbackSceneRefresh("")
    }

    public func rollbackSceneRefresh(reason: String): Unit {
        synchronized(lock) {
            holder.rollbackStyleRefresh()
            let sceneToken = sceneCandidateToken
            sceneCandidateToken = 0
            let pendingNow = holder.pendingCandidateToken()
            let superseded = sceneToken > 0 && pendingNow != sceneToken
            getStdOut().writeln("CJGUIRULE_SCENE_ROLLBACK sceneToken=${sceneToken} pending=${pendingNow} " +
                "superseded=${superseded} staged=${catalog.hasStagedComposites()} reason=${reason}")
            getStdOut().flush()
            // This scene carried no candidate (or its candidate was superseded):
            // the definition overlay belongs to the newer candidate and stays.
            if (sceneToken <= 0 || superseded) {
                holder.discardSceneViewState()
                return
            }
            holder.rollbackCandidateRefresh(reason)
            // A rejected candidate never leaves its definitions installed.
            // A transport supersession keeps the candidate pending: the staged
            // overlay belongs to the still-pending candidate and must survive
            // for the re-carrying scene transaction.
            if (holder.hasPendingCandidate() && holder.pendingCandidateToken() == sceneToken) {
                lastOutcome = "场景重载：${reason}，候选 ${sceneToken} 仍待接受"
            } else {
                catalog.rollbackStagedComposites()
                lastOutcome = "场景拒绝：${holder.lastSceneOutcome()}"
            }
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
        // This is the boundary where the scene is built from the CURRENT owner
        // projection: capture the revision pair it represents, so the accepted
        // scene can later prove which owner state it consumed.
        section.add(synchronized(lock) {
            pendingOwnerStamp = ownerStamp()
            // Sample the native preparation state of the ACCEPTED image bindings
            // here: this build already runs on the window's own thread, so the
            // public read path never calls native itself.
            match (attachedWindow) {
                case Some(window) => holder.sampleImageResourceStates(window)
                case None => ()
            }
            holder.buildRefreshNode(binding())
        })
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

    // This is the same post-resolution entry used by the real raw event.
    internal func dispatchResolvedFieldIntent(intent: CjguiGeneratedUiIntent,
        event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let resource = fieldResourceId(intent.fieldId)
        let observation = ownerWriteObservation.begin(domain, intent.ownerTargetResourceId, resource)
        // Keep the original multi-object default/unknown/retired/rebind guards.
        let result = binding().applyFieldIntent(intent)
        ownerWriteObservation.finishBinding(observation, event, intent.ownerTargetResourceId, resource, result, domain)
        return result
    }

    public func handleEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // One public adapter resolves the raw control event into either a field
        // edit (with the fingerprinted owner binding) or a declared action. It is
        // also what makes a COMPOSITE element work: a preset button activates
        // rather than "changes text", and the adapter resolves it from the
        // element's declared role instead of gating on the field's editor kind,
        // so a preset on an INTEGER field is never swallowed.
        let intent = holder.resolveIntent(event.node, event.eventKind, event.text,
            selectionStart: event.selectionStart, selectionEnd: event.selectionEnd)
        if (intent.isFieldEdit()) {
            return dispatchResolvedFieldIntent(intent, event)
        }
        if (intent.isAction()) {
            // The SAME dispatch route the public generated region uses: an
            // instance-scoped intent must still be the accepted element
            // (node, key, ORIGINAL owner target, generation) and then executes
            // with exactly those identities through the shared multi-object
            // adapter. A retired or re-bound target writes nothing.
            return holder.dispatchActionIntent(intent, binding())
        }
        return CjguiComposableUiDispatchResult(false)
    }

    /// Accepted composite element node id for one instance key, so a consumer (or
    /// a verification script) can address the element without knowing its id.
    public func acceptedCompositeElementNodeId(instanceKey: String, elementKey: String): Int64 {
        for (binding in holder.compositeElementNodeIdsForKey(instanceKey)) {
            if (binding.elementKey == elementKey) {
                return binding.nodeId
            }
        }
        return -1
    }

    /// The accepted binding of one composite element: its identity plus the
    /// resolved writer/owner target the framework allocated. A consumer that
    /// rebuilds a layout node for an event (as the tests do) must carry these,
    /// because the adapter verifies the node against the accepted binding.
    public func acceptedCompositeElement(instanceKey: String, elementKey: String):
        ?CjguiCompositeElementBinding {
        for (binding in holder.compositeElementNodeIdsForKey(instanceKey)) {
            if (binding.elementKey == elementKey) {
                return Some(binding)
            }
        }
        return None
    }

}

/// ONE rule record addressed by its declared `rule<id>` instance key. The
/// accepted owner target and every draft/action fact stay on the domain; this
/// wrapper only presents that owner through the shared object contract.
class CjguiRuleSetObjectBinding <: CjguiGeneratedUiObjectBinding {
    private let region: CjguiRuleSetGeneratedRegion
    private let key: String

    init(region: CjguiRuleSetGeneratedRegion, key: String) {
        this.region = region
        this.key = key
    }

    public func ownerTargetResourceId(): Int64 {
        return region.ownerForKey(key)
    }

    public func formFeedback(): ?CjguiGeneratedUiFormFeedback {
        return region.formFeedback(key)
    }

    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        return region.fieldAvailability(fieldId, key)
    }

    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        return region.actionAvailability(actionName, key)
    }

    public func draftText(fieldId: String): String {
        return region.draftText(fieldId, key)
    }

    public func draftBoolean(fieldId: String): ?Bool {
        return region.draftBoolean(fieldId, key)
    }

    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return region.applyFieldIntent(intent)
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return region.executeActionForInstance(actionName, nodeKey, key)
    }
}

/// Resolve one DECLARED record key to a live object. A deleted record resolves
/// to None but keeps its name, so the adapter refuses it as retired instead of
/// falling back to the selected record.
func ruleSetObjectBinding(region: CjguiRuleSetGeneratedRegion,
    key: String): ?CjguiGeneratedUiObjectBinding {
    if (region.ownerForKey(key) < 0) {
        return None
    }
    return Some(CjguiRuleSetObjectBinding(region, key))
}

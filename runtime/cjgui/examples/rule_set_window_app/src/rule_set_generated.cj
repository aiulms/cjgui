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
    /// The SAME preset the registered integer-edit composite carries, so the
    /// handwritten region reads one configuration instead of a second copy.
    private let compositePreset: CjguiRetentionPreset
    private var lastOutcome: String
    private var observedStructureVersion: Int64
    private var revisionValue: Int64
    /// The window whose accepted scene carries this region's generated nodes; the
    /// transport instance query has no window argument, so it is attached once.
    private var attachedWindow: ?CjguiComposableUiWindow = None
    /// ONE bounded change cursor over this region's real state. The snapshot and
    /// the change read both sample through it, so "the draft changed but the
    /// structure did not" and "the window was resized" are observable.
    private let tracker: CjguiGeneratedUiObservationTracker
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

    /// The application's own appearance switch retargets the ONE named style. The
    /// new paint is published with the next accepted scene transaction; a removal
    /// would degrade paint only, never remove the controls.
    public func setAccentAppearance(dark: Bool): Bool {
        return synchronized(lock) {
            let result = catalog.namedStyles().update(CjguiRuleSetGeneratedRegion.accentStyle(dark))
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
        // The built-in image kind: the shared content properties plus the shared
        // leaf style vocabulary, so a description can size/grow/align it exactly
        // like the handwritten image node.
        let imageProperties = CjguiGeneratedUiPresentation.imageContentProperties()
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            imageProperties.add(property)
        }
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("image", imageProperties, false))
        // The generated scroll container: the framework's public viewport, with
        // the ONE property it consumes and exactly one content child.
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

        // The ONE image declaration, registered where the catalog is built so the
        // published capability text and the region always agree.
        let _ = catalog.registerImageResource(CjguiRuleSetGeneratedRegion.defaultBeacon())
        // ONE named paint role shared by the handwritten helper, generated action
        // nodes and the registered composite. The application owns the values; the
        // framework resolves, validates and publishes them.
        let _ = catalog.namedStyles().register(CjguiRuleSetGeneratedRegion.accentStyle(false))
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action",
            withStyleProperties(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 60),
                CjguiGeneratedUiPropertySpec("action", "STRING", maxLength: 60)
            ]), CjguiGeneratedUiPresentation.leafStyleProperties()), false))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("APPLY_DRAFT", "应用草稿",
            parameterNames: domain.actionArgumentNames("APPLY_DRAFT")))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("CANCEL_DRAFT", "取消草稿",
            parameterNames: domain.actionArgumentNames("CANCEL_DRAFT")))
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
        if (actionName != "APPLY_DRAFT" && actionName != "CANCEL_DRAFT") {
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
    public func fieldsPayload(): String {
        fieldsSerializationsValue += 1
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
        structureSerializationsValue += 1
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

    /// Terminal read for ONE submission attempt. An unknown token answers
    /// `TERMINAL_STATE UNKNOWN` (the holder's ticket table is bounded), which is
    /// deliberately not an error and not another attempt's state.
    public func candidateTicketPayload(token: Int64): String {
        return synchronized(lock) { holder.candidateTicketPayload(token) }
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
            let result = holder.submit(root, this, attemptToken: token)
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

    /// How many shared-catalog image identities this window still holds.
    public func liveImageIdentityHoldCount(): Int64 {
        return holder.liveImageIdentityHoldCount()
    }

    /// Releases this window's holds on the SHARED resource catalog. Called from
     /// the window's dispose path (normal close or startup/native failure), never
     /// by the caller of an ordinary refresh.
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
            holder.buildRefreshNode(this)
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

    public func handleEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // One public adapter resolves the raw control event into either a field
        // edit (with the fingerprinted owner binding) or a declared action. It is
        // also what makes a COMPOSITE element work: a preset button activates
        // rather than "changes text", and the adapter resolves it from the
        // element's declared role instead of gating on the field's editor kind,
        // so a preset on an INTEGER field is never swallowed.
        let intent = holder.resolveIntent(event.node, event.eventKind, event.text)
        if (intent.isFieldEdit()) {
            let field = match (fieldSpec(intent.fieldId)) {
                case Some(value) => value
                case None => return CjguiComposableUiDispatchResult(false)
            }
            if (intent.ownerTargetResourceId < 0) {
                return CjguiComposableUiDispatchResult(false)
            }
            if (field.editorKind == "BOOLEAN") {
                let result = domain.editBooleanForCollectionItemFromHuman(intent.ownerTargetResourceId,
                    field.resourceId, intent.value.booleanValue)
                return finishGeneratedEdit(result, "布尔草稿")
            }
            let result = domain.editTextForCollectionItemFromHuman(intent.ownerTargetResourceId,
                field.resourceId, intent.value.stringValue, event.selectionStart, event.selectionEnd)
            return finishGeneratedEdit(result, "文本草稿")
        }
        if (intent.isAction()) {
            // The key comes from the accepted identity map, so a stale key can
            // never execute a different object's action.
            let result = executeAction(intent.actionName, intent.nodeKey)
            return CjguiComposableUiDispatchResult(result.applied)
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

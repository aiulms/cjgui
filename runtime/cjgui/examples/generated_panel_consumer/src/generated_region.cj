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
import std.env.*
import std.sync.*
import std.time.*
import std.unicode.*

/// P2: the generated key whose paint alpha this consumer animates, and the
/// two targets the interactive control alternates between.
private let GENERATED_OPACITY_KEY: String = "effectAnimate"
private let GENERATED_OPACITY_HIGH: Float64 = 1.0
private let GENERATED_OPACITY_LOW: Float64 = 0.3
private let GENERATED_POSITION_RULE_KEY: String = "positionAnimate"
private let GENERATED_POSITION_TARGET_KEY: String = "translatedSplit"

// B2: the app registers the shared bounded rule into its generated capability
// catalog. The actual `effectAnimate` candidate references that rule, and the
// action handler uses the holder's scene-accepted key→rule binding.

/// A structured read of the generated node's current paint-alpha projection. The
/// consumer and its self-verification read the SAME numbers the framework holds
/// (no per-frame broadcast, no string parsing on the consumer side).
public struct CjguiGeneratedAnimationSnapshot {
    public let identity: String
    public let presented: Float64
    public let target: Float64
    public let active: Int64
    public let bindings: Int64

    public init(identity: String, presented: Float64, target: Float64, active: Int64, bindings: Int64) {
        this.identity = identity
        this.presented = presented
        this.target = target
        this.active = active
        this.bindings = bindings
    }
}

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

private class CjguiTaskGeneratedTransferCandidate {
    public var targetKey: String = ""
    public var sourceKey: String = ""
    public var targetFormat: String = ""
    public var targetLocalPngFileAllowed: Bool = false
    public var targetActionName: String = ""
    public var reason: String = ""
    public var path: String = ""
}

/// Transfer declarations frozen from one exact generated build. The public
/// endpoint array is copied at the boundary; candidate metadata and receiver
/// generation are promoted only by the matching scene commit.
private class CjguiTaskGeneratedTransferSnapshot {
    public let candidate: CjguiTaskGeneratedTransferCandidate
    public let endpoints: ArrayList<CjguiTaskGeneratedTransferEndpoint>
    public let receiverIncarnation: Int64

    public init(candidate: CjguiTaskGeneratedTransferCandidate,
        endpoints: ArrayList<CjguiTaskGeneratedTransferEndpoint>, receiverIncarnation: Int64) {
        this.candidate = candidate
        this.endpoints = endpoints
        this.receiverIncarnation = receiverIncarnation
    }
}

/// One transfer endpoint declared by an accepted generated action. The semantic
/// identity is resolved from the committed window scene, so a pending candidate
/// can never become a native pasteboard receiver or drag source.
public class CjguiTaskGeneratedTransferEndpoint {
    public let declaredKey: String
    public let role: String
    public let format: String
    public let nodeId: Int64
    public let semanticId: String
    public let receiverIncarnation: Int64
    public let localPngFileAllowed: Bool

    public init(declaredKey: String, role: String, format: String, nodeId: Int64, semanticId: String,
        receiverIncarnation: Int64, localPngFileAllowed!: Bool = false) {
        this.declaredKey = declaredKey
        this.role = role
        this.format = format
        this.nodeId = nodeId
        this.semanticId = semanticId
        this.receiverIncarnation = receiverIncarnation
        this.localPngFileAllowed = localPngFileAllowed
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
    // P4 generated effect-group consumption: which group composition variant
    // the generated structure currently declares, and whether the effects are
    // present. Every
    // transition re-submits a whole generated description through the SAME
    // public submit entry, so the effect is always a generated declaration and
    // never something this consumer paints itself.
    private var effectVariantValue: Int64
    private var effectVisibleValue: Bool
    private var generatedTreeExpandedValue: Bool = true
    private var generatedTreeSelectedValue: Bool = false
    private var generatedControlActionCountValue: Int64 = 0
    // The generated root owns this declaration. An empty value means the
    // property is omitted and therefore resolves to the framework's opaque
    // default when the candidate is accepted.
    private var windowBackgroundValue: String = CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA
    // The first frame uses the dark palette, matching the controller default
    // until the platform supplies its initial effective scheme.
    private var appliedPlatformColorSchemeValue: String = "dark"
    private var platformAccentColorValue: ?CjguiComposableUiColor = None
    private var platformAccentTokenValue: String = ""
    private var platformAccentSourceValue: String = ""
    // P2 paint-alpha animation of a GENERATED node. The animated key is the
    // declared generated key, resolved to the accepted identity at drive time,
    // so a rejected candidate or a removed/replaced node cannot keep the old
    // animation alive on a new instance.
    private var opacityHighValue: Bool = false
    private var positionHighValue: Bool = false
    private var lastAnimationSummary: String = "尚未驱动动效"
    // Transfer declarations are promoted only by the same scene commit that
    // promotes the generated structure. A candidate or rejected refresh never
    // changes these accepted endpoint keys.
    private var acceptedTransferTargetKey: String = ""
    private var acceptedTransferSourceKey: String = ""
    private var acceptedTransferTargetFormat: String = ""
    private var acceptedTransferTargetActionName: String = ""
    private var transferReceiverIncarnation: Int64 = 0
    // A successful structure submission owns this validated metadata until its
    // holder token is committed or rolled back. It is never inferred from an
    // unaccepted display tree during provider reads.
    private var pendingTransferCandidate: ?CjguiTaskGeneratedTransferCandidate = None
    private var pendingTransferToken: Int64 = 0
    // Refresh is pinned from begin through native settlement. A second
    // candidate cannot supersede the holder while its identities are staged.
    private var refreshInFlight: Bool = false
    private var refreshCandidateToken: Int64 = 0
    private var refreshCandidateMetadata: ?CjguiTaskGeneratedTransferCandidate = None
    private var acceptedTransferSnapshot: CjguiTaskGeneratedTransferSnapshot =
        CjguiTaskGeneratedTransferSnapshot(CjguiTaskGeneratedTransferCandidate(),
            ArrayList<CjguiTaskGeneratedTransferEndpoint>(), 0)
    private var refreshTransferSnapshot: ?CjguiTaskGeneratedTransferSnapshot = None

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
        this.effectVariantValue = 0
        this.effectVisibleValue = true
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
        return primaryActionStyleFor(CjguiComposableUiColorScheme.Dark)
    }

    private static func themeFor(scheme: CjguiComposableUiColorScheme): CjguiComposableUiTheme {
        return match (scheme) {
            case Light => CjguiComposableUiTheme.paperLight()
            case Dark => CjguiComposableUiTheme.beaconDark()
        }
    }

    private static func primaryActionStyleFor(scheme: CjguiComposableUiColorScheme,
        accent!: ?CjguiComposableUiColor = None): CjguiComposableUiNamedStyle {
        let theme = CjguiTaskGeneratedRegion.themeFor(scheme)
        let border = match (accent) {
            case Some(value) => value
            case None => theme.primaryAction.border
        }
        return CjguiComposableUiNamedStyle("collaboration_primary_action",
            CjguiComposableUiStyle(background: theme.primaryAction.background,
                border: border, textColor: theme.primaryAction.textColor,
                borderWidth: if (accent.isSome()) { 2 } else { theme.primaryAction.borderWidth }),
            interaction: theme.primaryActionInteraction, purpose: "任务面板主操作")
    }

    /// The generated tab pages' title role: declared once here, referenced by
    /// the tabs declaration's `titleStyle`, consumed by the SAME public tab
    /// container the handwritten pages use.
    public static func panelTabTitleStyle(): CjguiComposableUiNamedStyle {
        return panelTabTitleStyleFor(CjguiComposableUiColorScheme.Dark)
    }

    private static func panelTabTitleStyleFor(scheme: CjguiComposableUiColorScheme,
        accent!: ?CjguiComposableUiColor = None): CjguiComposableUiNamedStyle {
        let theme = CjguiTaskGeneratedRegion.themeFor(scheme)
        let selectedColor = match (accent) {
            case Some(value) => value
            case None => theme.heading.textColor
        }
        return CjguiComposableUiNamedStyle("panel_tab_title",
            CjguiComposableUiStyle(textColor: theme.heading.textColor,
                fontWeight: theme.heading.fontWeight),
            interaction: CjguiComposableUiInteractionStyle(
                normal: CjguiComposableUiPaintStyle(textColor: Some(theme.heading.textColor)),
                selected: CjguiComposableUiPaintStyle(textColor: Some(selectedColor)),
                focused: CjguiComposableUiPaintStyle(border: Some(selectedColor), borderWidth: Some(2))),
            purpose: "任务面板页签标题")
    }

    /// Updates both generated named paint roles from one shared theme factory.
    /// The catalog is desired state; ordinary scene acceptance is what makes
    /// the resolved palette visible in the window.
    public func applyPlatformColorScheme(scheme: CjguiComposableUiColorScheme): Bool {
        let schemeToken = CjguiComposableUiPlatformStateCodec.colorSchemeToken(scheme)
        return synchronized(lock) {
            if (schemeToken == appliedPlatformColorSchemeValue) {
                return false
            }
            let styles = catalog.namedStyles()
            let previousAction = styles.forName("collaboration_primary_action")
            let previousTitle = styles.forName("panel_tab_title")
            if (previousAction.isNone() || previousTitle.isNone()) {
                return false
            }
            let oldAction = match (previousAction) {
                case Some(value) => value
                case None => CjguiTaskGeneratedRegion.primaryActionStyle()
            }
            let oldTitle = match (previousTitle) {
                case Some(value) => value
                case None => CjguiTaskGeneratedRegion.panelTabTitleStyle()
            }
            if (!styles.update(CjguiTaskGeneratedRegion.primaryActionStyleFor(scheme,
                accent: platformAccentColorValue))) {
                return false
            }
            if (!styles.update(CjguiTaskGeneratedRegion.panelTabTitleStyleFor(scheme,
                accent: platformAccentColorValue))) {
                // Preserve the prior two-role palette if later style admission
                // rules make the second update refuse.
                let _ = styles.update(oldAction)
                let _ = styles.update(oldTitle)
                return false
            }
            appliedPlatformColorSchemeValue = schemeToken
            revisionValue += 1
            lastOutcome = "系统主题已应用 ${schemeToken}；等待 accepted scene"
            return true
        }
    }

    public func applyPlatformAccentColor(color: CjguiComposableUiColor, source: String): Bool {
        let token = cjguiComposableUiColorToken(color)
        return synchronized(lock) {
            if (token == platformAccentTokenValue && source == platformAccentSourceValue) { return false }
            let scheme = if (appliedPlatformColorSchemeValue == "light") {
                CjguiComposableUiColorScheme.Light
            } else {
                CjguiComposableUiColorScheme.Dark
            }
            let styles = catalog.namedStyles()
            let oldAction = styles.forName("collaboration_primary_action")
            let oldTitle = styles.forName("panel_tab_title")
            if (oldAction.isNone() || oldTitle.isNone()) { return false }
            if (!styles.update(CjguiTaskGeneratedRegion.primaryActionStyleFor(scheme, accent: Some(color)))) {
                return false
            }
            if (!styles.update(CjguiTaskGeneratedRegion.panelTabTitleStyleFor(scheme, accent: Some(color)))) {
                if (let Some(previous) <- oldAction) { let _ = styles.update(previous) }
                if (let Some(previous) <- oldTitle) { let _ = styles.update(previous) }
                return false
            }
            platformAccentColorValue = Some(color)
            platformAccentTokenValue = token
            platformAccentSourceValue = source
            revisionValue += 1
            lastOutcome = "系统强调色 ${source} ${token}；等待 accepted scene"
            return true
        }
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
            maxPropertiesPerNode: 8, maxStringLength: CJGUI_GENERATED_UI_DECODE_MAX_STRING_LENGTH)
        catalog.enableWindowBackground()
        let _ = catalog.registerMotionRule(CjguiGeneratedMotionRegistry.opacityTransitionRule())
        let _ = catalog.registerMotionRule(CjguiGeneratedMotionRegistry.positionTransitionRule())
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
        // A separate bounded content kind keeps ordinary labels small while a
        // generated scroll may declare one genuinely long visible text owner.
        let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("longLabel",
            taskWithStyle(ArrayList<CjguiGeneratedUiPropertySpec>([
                CjguiGeneratedUiPropertySpec("text", "STRING", required: true,
                    maxLength: CJGUI_GENERATED_UI_DECODE_MAX_STRING_LENGTH)
            ])), false, presentation: CJGUI_GENERATED_PRESENTATION_LABEL))
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
                CjguiGeneratedUiPropertySpec("action", "STRING", maxLength: 40),
                CjguiGeneratedUiPropertySpec("transferRole", "STRING", maxLength: 6,
                    values: ArrayList<String>(["TARGET", "SOURCE"]), stability: "experimental"),
                CjguiGeneratedUiPropertySpec("transferFormat", "STRING", maxLength: 9,
                    values: ArrayList<String>(["image/png"]), stability: "experimental"),
                CjguiGeneratedUiPropertySpec("transferFileSource", "STRING", maxLength: 14,
                    values: ArrayList<String>(["none", "local_file_url"]), stability: "experimental")
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
        // P4 effect-group transitions. Each one re-submits the generated
        // description with a different declared effectGroup, so the only way the effect
        // changes is through the public generated submit entry.
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("CYCLE_GENERATED_EFFECT", "切换生成效果组"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("REMOVE_GENERATED_EFFECT", "清除生成效果组"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("RESTORE_GENERATED_EFFECT", "恢复生成效果组"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("SUBMIT_INVALID_EFFECT", "提交非法效果组候选"))
        // P2: a value transition on a GENERATED node. The action only requests a
        // new target; the framework window owns the current visual value.
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("ANIMATE_GENERATED_OPACITY", "生成节点透明度过渡"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("ANIMATE_GENERATED_POSITION", "生成分栏连续平移"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("CLEAR_GENERATED_POSITION", "清除生成分栏平移"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("TOGGLE_WINDOW_BACKGROUND", "切换系统窗口材质"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("CLEAR_WINDOW_BACKGROUND", "清除系统窗口材质"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("CONTROL_TREE_GROUP", "展开或折叠生成树"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("CONTROL_TREE_LEAF", "选择生成树条目"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("CONTROL_BUTTON", "激活生成按钮"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("CONTROL_ACCENT", "切换窗口强调色策略"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("PNG_TRANSFER_ENDPOINT", "声明 PNG 端点元数据"))
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

    // --- P4 generated effect-group declarations ------------------------------

    /// The generated description's declared shadow token for one variant, in the
    /// framework's public wire encoding (logical points + strict #RRGGBBAA).
    private static func shadowTokenFor(variant: Int64): String {
        if (variant == 0) {
            return "0,3,10,0,#00000073"
        }
        if (variant == 1) {
            return "0,8,24,3,#0000008c"
        }
        return "-6,8,30,0,#0f1f40b3"
    }

    private static func gradientTokenFor(variant: Int64): String {
        if (variant == 0) {
            return "0,0,100,0,0:#1c4f92ff|100:#3fa9f5ff"
        }
        if (variant == 1) {
            return "0,0,0,100,0:#3b1c85ff|100:#ae4ff0ff"
        }
        return "0,0,100,100,0:#0d7a66ff|100:#ffd166ff"
    }

    /// Shared effect-group encoding: opacity percentage, blend mode, and a
    /// group-local linear alpha mask. Coordinates, stop positions, and alpha
    /// values use integer percentages.
    private static func effectGroupTokenFor(variant: Int64): String {
        if (variant == 0) {
            // The ordinary task editor lives inside this group. Its previous
            // 50% opacity plus a mask starting at alpha zero made the left
            // text field almost unreadable; keep the initial workspace clear.
            return "90,normal,none"
        }
        if (variant == 1) {
            return "70,multiply,0,0,0,100,0:0|100:100;blur=8,unblurred"
        }
        return "85,normal,0,0,100,100,0:100|100:0"
    }

    /// A complete generated description with one effect group containing the
    /// shadowed card, gradient surface, generated controls, and registered
    /// task-edit composite. `visible=false` uses the explicit `none` clear form.
    /// The consumer never paints the effect itself: the ONLY source is this
    /// textual declaration.
    public static func effectStructure(variant: Int64, visible: Bool,
        windowBackground!: String = CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA,
        treeExpanded!: Bool = true, treeSelected!: Bool = false,
        translationVariant!: Int64 = 0): String {
        let shadow = if (visible) { CjguiTaskGeneratedRegion.shadowTokenFor(variant) } else { "none" }
        let gradient = if (visible) { CjguiTaskGeneratedRegion.gradientTokenFor(variant) } else { "none" }
        let group = if (visible) { CjguiTaskGeneratedRegion.effectGroupTokenFor(variant) } else { "none" }
        let groupTranslateX = if (translationVariant == 2) { "0" } else if (translationVariant == 1) { "30.25" } else { "0.25" }
        let groupTranslateY = if (translationVariant == 2) { "0" } else if (translationVariant == 1) { "12.5" } else { "0.5" }
        let childTranslateX = if (translationVariant == 2) { "0" } else { "-0.75" }
        let childTranslateY = if (translationVariant == 2) { "0" } else { "0.25" }
        let compositeTranslateX = if (translationVariant == 2) { "0" } else { "0.125" }
        let compositeTranslateY = if (translationVariant == 2) { "0" } else { "-0.25" }
        let windowBackgroundProperty = if (windowBackground.isEmpty()) { "" } else {
            "PROPERTY 0 board windowBackground ${windowBackground}\n"
        }
        let treeLeaf = if (treeExpanded) {
            "NODE 5 controlLeaf action action=CONTROL_TREE_LEAF\n" +
            "PROPERTY 5 controlLeaf label 生成树条目\n" +
            "PROPERTY 5 controlLeaf semanticRole row\n" +
            "PROPERTY 5 controlLeaf semanticRowKey generated-leaf\n" +
            "PROPERTY 5 controlLeaf semanticParentKey generated-group\n" +
            "PROPERTY 5 controlLeaf semanticLevel 1\n" +
            "PROPERTY 5 controlLeaf semanticSelected ${if (treeSelected) { "true" } else { "false" }}\n" +
            "PROPERTY 5 controlLeaf style collaboration_primary_action\n"
        } else { "" }
        var longBody = ""
        var row = 0
        while (row < 100) {
            longBody += "中文长文🙂 第${row}段·"
            row += 1
        }
        return "GENERATED_UI_STRUCTURE 1\n" +
            "NODE 0 board vertical\n" +
            "PROPERTY 0 board gap 6\n" +
            "PROPERTY 0 board padding 8\n" +
            windowBackgroundProperty +
            // Keep the actual generated transfer controls in the visible
            // portion of the normal panel. They bind through this candidate's
            // accepted identity, not through the hand-written PNG row.
            "NODE 1 generatedPngTarget action action=PNG_TRANSFER_ENDPOINT\n" +
            "PROPERTY 1 generatedPngTarget label 生成 PNG 粘贴 / 拖入\n" +
            "PROPERTY 1 generatedPngTarget transferRole TARGET\n" +
            "PROPERTY 1 generatedPngTarget transferFormat image/png\n" +
            "PROPERTY 1 generatedPngTarget transferFileSource local_file_url\n" +
            "PROPERTY 1 generatedPngTarget style collaboration_primary_action\n" +
            "NODE 1 generatedPngSource action action=PNG_TRANSFER_ENDPOINT\n" +
            "PROPERTY 1 generatedPngSource label 生成 PNG 拖出\n" +
            "PROPERTY 1 generatedPngSource transferRole SOURCE\n" +
            "PROPERTY 1 generatedPngSource transferFormat image/png\n" +
            "PROPERTY 1 generatedPngSource style collaboration_primary_action\n" +
            "NODE 1 translatedSplit split\n" +
            "PROPERTY 1 translatedSplit fixedHeight 180\n" +
            "PROPERTY 1 translatedSplit firstSize 340\n" +
            "PROPERTY 1 translatedSplit firstMinimum 150\n" +
            "PROPERTY 1 translatedSplit secondMinimum 150\n" +
            "PROPERTY 1 translatedSplit translateX ${groupTranslateX}\n" +
            "PROPERTY 1 translatedSplit translateY ${groupTranslateY}\n" +
            "NODE 2 translatedScroll scrollArea\n" +
            "PROPERTY 2 translatedScroll fixedHeight 174\n" +
            "NODE 3 translatedContent vertical\n" +
            "NODE 4 translatedLongText longLabel\n" +
            "PROPERTY 4 translatedLongText text ${longBody}\n" +
            "PROPERTY 4 translatedLongText fixedHeight 4096\n" +
            "PROPERTY 4 translatedLongText fontSize 20\n" +
            "PROPERTY 4 translatedLongText textColor #eaf2ffff\n" +
            "NODE 4 translatedOffscreenNotes textInput field=notes\n" +
            "PROPERTY 4 translatedOffscreenNotes label 屏外备注（同一任务）\n" +
            "PROPERTY 4 translatedOffscreenNotes fixedHeight 44\n" +
            "PROPERTY 4 translatedOffscreenNotes background #eaf2ffff\n" +
            "PROPERTY 4 translatedOffscreenNotes textColor #142438ff\n" +
            "PROPERTY 4 translatedOffscreenNotes border #759bd0ff\n" +
            "NODE 4 translatedTail action action=CONTROL_BUTTON\n" +
            "PROPERTY 4 translatedTail label 长文末尾动作\n" +
            "PROPERTY 4 translatedTail style collaboration_primary_action\n" +
            "NODE 2 translatedOwner vertical\n" +
            "NODE 3 translatedOwnerTitle label\n" +
            "PROPERTY 3 translatedOwnerTitle text 生成平移分栏 · 同一任务 owner\n" +
            "PROPERTY 3 translatedOwnerTitle textColor #eaf2ffff\n" +
            "NODE 3 translatedOwnerNotes textInput field=notes\n" +
            "PROPERTY 3 translatedOwnerNotes label 生成移动备注\n" +
            "PROPERTY 3 translatedOwnerNotes fixedHeight 42\n" +
            "PROPERTY 3 translatedOwnerNotes background #eaf2ffff\n" +
            "PROPERTY 3 translatedOwnerNotes textColor #142438ff\n" +
            "PROPERTY 3 translatedOwnerNotes border #759bd0ff\n" +
            "NODE 3 translatedOwnerAction action action=CONTROL_BUTTON\n" +
            "PROPERTY 3 translatedOwnerAction label 更新同一任务\n" +
            "PROPERTY 3 translatedOwnerAction style collaboration_primary_action\n" +
            "NODE 1 effectGroup vertical\n" +
            "PROPERTY 1 effectGroup effectGroup ${group}\n" +
            "PROPERTY 1 effectGroup gap 6\n" +
            "PROPERTY 1 effectGroup translateX ${groupTranslateX}\n" +
            "PROPERTY 1 effectGroup translateY ${groupTranslateY}\n" +
            "NODE 2 shadowCard label\n" +
            "PROPERTY 2 shadowCard text 生成阴影卡片 v${variant}\n" +
            "PROPERTY 2 shadowCard shadow ${shadow}\n" +
            "PROPERTY 2 shadowCard background #1c2942ff\n" +
            "PROPERTY 2 shadowCard border #3a5a8cff\n" +
            "PROPERTY 2 shadowCard textColor #f2f6ffff\n" +
            "PROPERTY 2 shadowCard fixedWidth 260\n" +
            "PROPERTY 2 shadowCard fixedHeight 44\n" +
            "NODE 2 gradientCard vertical\n" +
            "PROPERTY 2 gradientCard gradient ${gradient}\n" +
            "PROPERTY 2 gradientCard padding 8\n" +
            "NODE 3 gradientTitle label\n" +
            "PROPERTY 3 gradientTitle text 生成渐变面板 v${variant}\n" +
            "PROPERTY 3 gradientTitle textColor #f2f6ffff\n" +
            "PROPERTY 3 gradientTitle translateX ${childTranslateX}\n" +
            "PROPERTY 3 gradientTitle translateY ${childTranslateY}\n" +
            "NODE 2 taskCard taskEditCard\n" +
            "PROPERTY 2 taskCard caption 效果组内的任务编辑组合组件\n" +
            "PROPERTY 2 taskCard gap 4\n" +
            "PROPERTY 2 taskCard textColor #f2f6ffff\n" +
            "PROPERTY 2 taskCard translateX ${compositeTranslateX}\n" +
            "PROPERTY 2 taskCard translateY ${compositeTranslateY}\n" +
            "NODE 2 effectToggle action action=CYCLE_GENERATED_EFFECT\n" +
            "PROPERTY 2 effectToggle label 切换生成效果组\n" +
            "PROPERTY 2 effectToggle style collaboration_primary_action\n" +
            "NODE 2 effectRemove action action=REMOVE_GENERATED_EFFECT\n" +
            "PROPERTY 2 effectRemove label 清除生成效果组\n" +
            "PROPERTY 2 effectRemove style collaboration_primary_action\n" +
            "NODE 2 effectInvalid action action=SUBMIT_INVALID_EFFECT\n" +
            "PROPERTY 2 effectInvalid label 提交非法效果组候选\n" +
            "PROPERTY 2 effectInvalid style collaboration_primary_action\n" +
            "NODE 2 effectRestore action action=RESTORE_GENERATED_EFFECT\n" +
            "PROPERTY 2 effectRestore label 恢复生成效果组\n" +
            "PROPERTY 2 effectRestore style collaboration_primary_action\n" +
            "NODE 2 effectAnimate action action=ANIMATE_GENERATED_OPACITY\n" +
            "PROPERTY 2 effectAnimate label 透明度过渡\n" +
            "PROPERTY 2 effectAnimate style collaboration_primary_action\n" +
            "PROPERTY 2 effectAnimate motion " + CjguiGeneratedMotionRegistry.OPACITY_TRANSITION + "\n" +
            "NODE 2 positionAnimate action action=ANIMATE_GENERATED_POSITION\n" +
            "PROPERTY 2 positionAnimate label 生成分栏连续平移\n" +
            "PROPERTY 2 positionAnimate style collaboration_primary_action\n" +
            "PROPERTY 2 positionAnimate motion " + CjguiGeneratedMotionRegistry.POSITION_TRANSITION + "\n" +
            "NODE 2 positionClear action action=CLEAR_GENERATED_POSITION\n" +
            "PROPERTY 2 positionClear label 清除生成分栏平移\n" +
            "PROPERTY 2 positionClear style collaboration_primary_action\n" +
            "NODE 2 windowBackgroundToggle action action=TOGGLE_WINDOW_BACKGROUND\n" +
            "PROPERTY 2 windowBackgroundToggle label 切换系统窗口材质\n" +
            "PROPERTY 2 windowBackgroundToggle style collaboration_primary_action\n" +
            "NODE 2 windowBackgroundClear action action=CLEAR_WINDOW_BACKGROUND\n" +
            "PROPERTY 2 windowBackgroundClear label 清除系统窗口材质\n" +
            "PROPERTY 2 windowBackgroundClear style collaboration_primary_action\n" +
            "NODE 1 controlTabs tabs\n" +
            "PROPERTY 1 controlTabs initialPage outline\n" +
            "PROPERTY 1 controlTabs titleStyle panel_tab_title\n" +
            "PROPERTY 1 controlTabs fixedHeight 134\n" +
            "NODE 2 outlinePage tabPage\n" +
            "PROPERTY 2 outlinePage pageKey outline\n" +
            "PROPERTY 2 outlinePage pageTitle 树与滚动\n" +
            "NODE 3 controlOutline scrollArea\n" +
            "PROPERTY 3 controlOutline semanticRole outline\n" +
            "PROPERTY 3 controlOutline semanticLabel 生成控件树\n" +
            "PROPERTY 3 controlOutline fixedHeight 96\n" +
            "NODE 4 controlRows vertical\n" +
            "NODE 5 controlGroup action action=CONTROL_TREE_GROUP\n" +
            "PROPERTY 5 controlGroup label ${if (treeExpanded) { "▾" } else { "▸" }} 生成树分组\n" +
            "PROPERTY 5 controlGroup semanticRole row\n" +
            "PROPERTY 5 controlGroup semanticRowKey generated-group\n" +
            "PROPERTY 5 controlGroup semanticExpandable true\n" +
            "PROPERTY 5 controlGroup semanticExpanded ${if (treeExpanded) { "true" } else { "false" }}\n" +
            "PROPERTY 5 controlGroup style collaboration_primary_action\n" +
            treeLeaf +
            "NODE 5 controlDisabled action action=CONTROL_TREE_LEAF\n" +
            "PROPERTY 5 controlDisabled label 禁用生成条目\n" +
            "PROPERTY 5 controlDisabled semanticRole row\n" +
            "PROPERTY 5 controlDisabled semanticRowKey generated-disabled\n" +
            "PROPERTY 5 controlDisabled disabled true\n" +
            "PROPERTY 5 controlDisabled style collaboration_primary_action\n" +
            "NODE 2 controlActionsPage tabPage\n" +
            "PROPERTY 2 controlActionsPage pageKey actions\n" +
            "PROPERTY 2 controlActionsPage pageTitle 操作\n" +
            "NODE 3 controlActions vertical\n" +
            "NODE 4 controlButton action action=CONTROL_BUTTON\n" +
            "PROPERTY 4 controlButton label 生成按钮\n" +
            "PROPERTY 4 controlButton style collaboration_primary_action\n" +
            "NODE 4 controlAccent action action=CONTROL_ACCENT\n" +
            "PROPERTY 4 controlAccent label 固定或跟随系统强调色\n" +
            "PROPERTY 4 controlAccent style collaboration_primary_action\n" +
            "NODE 4 controlCheckbox booleanInput field=marked\n" +
            "PROPERTY 4 controlCheckbox label 任务标记\n" +
            "END"
    }

    /// The initial description the normal window starts from: an elevated
    /// generated card and a gradient generated surface, both declared textually
    /// and submitted through the public generated entry by `main`.
    public func initialEffectStructure(): String {
        return CjguiTaskGeneratedRegion.effectStructure(effectVariantValue, effectVisibleValue,
            windowBackground: windowBackgroundValue, treeExpanded: generatedTreeExpandedValue,
            treeSelected: generatedTreeSelectedValue)
    }

    /// Window host read: pending candidate during scene preparation, otherwise
    /// the accepted root policy. The holder normalizes omission to opaque.
    public func candidateWindowBackground(): String {
        return holder.candidateWindowBackground()
    }

    public func acceptedWindowBackground(): String {
        return holder.acceptedWindowBackground()
    }

    // A public client may replace the accepted declaration between two owner
    // actions. Derive the next toggle from that accepted structure, so a later
    // pointer/keyboard/AX action never starts from this consumer's old cache.
    private func acceptedTreeFlags(): (Bool, Bool) {
        return synchronized(lock) {
            let expanded = match (holder.acceptedNodeForKey("controlGroup")) {
                case Some(node) => node.property("semanticExpanded") == "true"
                case None => generatedTreeExpandedValue
            }
            let selected = match (holder.acceptedNodeForKey("controlLeaf")) {
                case Some(node) => node.property("semanticSelected") == "true"
                case None => generatedTreeSelectedValue
            }
            (expanded, selected)
        }
    }


    /// Readable note of the last NON-FATAL declaration advisory (a malformed
    /// encoded effect that was ignored while the scene stayed accepted).
    public func lastDeclarationAdvisory(): String {
        return synchronized(lock) { holder.lastDeclarationAdvisory() }
    }

    /// Submits a whole generated description carrying the current effect group
    /// through the public submit entry. Returns whether the candidate was accepted.
    private func submitEffectStructure(variant: Int64, visible: Bool): Bool {
        let (treeExpanded, treeSelected) = acceptedTreeFlags()
        let result = submitStructure(CjguiTaskGeneratedRegion.effectStructure(variant, visible,
            windowBackground: windowBackgroundValue, treeExpanded: treeExpanded,
            treeSelected: treeSelected), acceptedStructureVersion())
        return result.candidateAccepted
    }

    private func submitWindowBackground(value: String): Bool {
        let (treeExpanded, treeSelected) = acceptedTreeFlags()
        let result = submitStructure(CjguiTaskGeneratedRegion.effectStructure(effectVariantValue, effectVisibleValue,
            windowBackground: value, treeExpanded: treeExpanded,
            treeSelected: treeSelected), acceptedStructureVersion())
        return result.candidateAccepted
    }


    /// One stable, greppable line per generated effect transition: the anchor a
    /// verification script correlates with the accepted generated scene.
    private func emitGeneratedEffectState(action: String, applied: Bool): Unit {
        let outcome = synchronized(lock) { lastOutcome }
        let declaration = if (effectVisibleValue) {
            CjguiTaskGeneratedRegion.effectGroupTokenFor(effectVariantValue)
        } else { "none" }
        getStdOut().writeln("CJGUI_GENERATED_EFFECT_STATE action=${action} " +
            "visible=${if (effectVisibleValue) { 1 } else { 0 }} variant=${effectVariantValue} " +
            "effectGroup=${declaration} applied=${if (applied) { 1 } else { 0 }} outcome=${outcome}")
        getStdOut().flush()
    }

    /// Candidate attempts through the SAME public entry, proving the current
    /// whole-candidate contract:
    ///  (a) a syntactically complete description whose shadow text is malformed
    ///      is refused WHOLE with the stable reason `shadow_value_invalid`;
    ///  (b) a gradient coordinate outside the declared domain is refused whole
    ///      with `gradient_value_invalid`;
    ///  (c) the accepted structure version, the old control's identity and the
    ///      declared shadow style are read back BEFORE any recovery, separating
    ///      "candidate refused" from "scene replaced";
    /// Only then does the application re-submit the legal effect through the same
    /// entry so it keeps operating.
    private func submitInvalidEffectCandidates(): String {
        let versionBefore = acceptedStructureVersion()
        let badShadowStructure = "GENERATED_UI_STRUCTURE 1\n" +
            "NODE 0 board vertical\n" +
            "NODE 1 badShadowCard label\n" +
            "PROPERTY 1 badShadowCard text 非法效果编码卡片\n" +
            "PROPERTY 1 badShadowCard shadow 12,oops,8,0,#000000\n" +
            "END"
        let shadowResult = submitStructure(badShadowStructure, versionBefore)
        let badGradientStructure = "GENERATED_UI_STRUCTURE 1\n" +
            "NODE 0 board vertical\n" +
            "NODE 1 badGradientCard vertical\n" +
            "PROPERTY 1 badGradientCard gradient 0,0,140,0,0:#112233ff|100:#445566ff\n" +
            "END"
        let gradientResult = submitStructure(badGradientStructure, versionBefore)
        // Read the accepted state back BEFORE recovering: a refused candidate
        // must not have moved the structure version, the old control identity or
        // its declared sampling style.
        let versionAfter = acceptedStructureVersion()
        let oldControlNodeId = acceptedNodeIdForKey(GENERATED_OPACITY_KEY)
        let shadowReadback = generatedShadowReadback()
        let restored = submitEffectStructure(effectVariantValue, true)
        effectVisibleValue = true
        return "非法阴影 accepted=${shadowResult.candidateAccepted} reason=${shadowResult.reason} " +
            "path=${shadowResult.path} | 非法渐变 accepted=${gradientResult.candidateAccepted} " +
            "reason=${gradientResult.reason} path=${gradientResult.path} | 提交后读回 versionBefore=${versionBefore} " +
            "versionAfter=${versionAfter} oldControlNode=${oldControlNodeId} ${shadowReadback} | " +
            "合法效果恢复=${restored}"
    }

    /// Read back the declared shadow of the accepted generated sampling card.
    /// It is a public-geometry read from the window's accepted scene, so it can
    /// only show the state the framework really accepted.
    private func generatedShadowReadback(): String {
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return "shadowReadback=window_none"
        }
        let declaredNodeId = synchronized(lock) { holder.nodeIdForKey("shadowCard") }
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == declaredNodeId) {
                let hasShadow = node.declaredStyle.shadow.isSome()
                return "shadowCardShadow=${if (hasShadow) { 1 } else { 0 }}"
            }
        }
        return "shadowCardShadow=absent"
    }

    /// Drive the framework paint-alpha animation on an accepted GENERATED node.
    /// The key is resolved against the window's accepted scene right now, so a
    /// removed/replaced node has no identity and the drive is refused instead of
    /// landing the old animation on a new instance. A rejected candidate never
    /// changes the accepted scene, therefore it cannot disturb a running binding.
    private func animateGeneratedOpacity(key: String, target: Float64, phase: String): Bool {
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return false
        }
        var identity = ""
        var nodeId: Int64 = -1
        let declaredNodeId = synchronized(lock) { holder.nodeIdForKey(key) }
        if (declaredNodeId < 0) {
            return false
        }
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == declaredNodeId) {
                identity = node.identityKey
                nodeId = node.nodeId
            }
        }
        if (identity.size == 0) {
            return false
        }
        // The rule comes from the accepted generated description for this key.
        // Candidate and catalog state cannot substitute for the value the window
        // actually committed, and an omitted/unknown reference has no fallback.
        let motionRule = match (synchronized(lock) { holder.acceptedMotionRuleForKey(key) }) {
            case Some(value) => value
            case None =>
                getStdOut().writeln("CJGUI_GENERATED_MOTION_REJECTED " +
                    "key=${key} reason=motion_reference_not_accepted")
                getStdOut().flush()
                return false
        }
        let ruleRejection = motionRule.rejectionReason()
        if (ruleRejection.size != 0) {
            getStdOut().writeln("CJGUI_GENERATED_MOTION_REJECTED rule=${motionRule.name} reason=${ruleRejection}")
            getStdOut().flush()
            return false
        }
        let motionSpec = match (motionRule.spec()) {
            case Some(value) => value
            case None => return false
        }
        let started = window.animateNodeOpacity(identity, target, spec: motionSpec, atTime: MonoTime.now())
        let presented = match (window.animatedNodeOpacity(identity)) {
            case Some(value) => value
            case None => -1.0
        }
        lastAnimationSummary = "phase=${phase} target=${target} presented=${presented}"
        getStdOut().writeln("CJGUI_GENERATED_ANIMATION_STATE key=${key} identity=${identity} node=${nodeId} " +
            "phase=${phase} started=${if (started) { 1 } else { 0 }} target=${target} presented=${presented} " +
            "rule=${motionRule.name} duration=${motionRule.durationMs} easing=${motionRule.easingToken} " +
            "active=${window.activeAnimationCount()} bindings=${window.animationBindingCount()}")
        getStdOut().flush()
        return started
    }

    /// Resolve both target and rule from one accepted generated description.
    /// The button's accepted motion reference supplies the common tween spec;
    /// a rejected candidate cannot replace either identity or rule.
    private func animateGeneratedPosition(high: Bool): Bool {
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return false
        }
        let targetId = synchronized(lock) { holder.nodeIdForKey(GENERATED_POSITION_TARGET_KEY) }
        var identity = ""
        var baseX = 0.0
        var baseY = 0.0
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == targetId) {
                identity = node.identityKey
                baseX = node.declaredStyle.translateX
                baseY = node.declaredStyle.translateY
            }
        }
        if (identity.size == 0) { return false }
        let rule = match (synchronized(lock) { holder.acceptedMotionRuleForKey(GENERATED_POSITION_RULE_KEY) }) {
            case Some(value) => value
            case None => return false
        }
        let spec = match (rule.spec()) {
            case Some(value) => value
            case None => return false
        }
        let targetX = baseX + (if (high) { 24.0 } else { 0.0 })
        let targetY = baseY + (if (high) { 12.0 } else { 0.0 })
        let started = window.animateNodeTranslation(identity, targetX, targetY, spec: spec,
            atTime: MonoTime.now())
        let status = window.animatedNodeTranslation(identity)
        let acceptedToken = match (status) {
            case Some(value) => "${value.presented.x},${value.presented.y}"
            case None => "none"
        }
        getStdOut().writeln("CJGUI_GENERATED_POSITION_STATE identity=${identity} " +
            "started=${if (started) { 1 } else { 0 }} target=${targetX},${targetY} " +
            "accepted=${acceptedToken} rule=${rule.name} owner_version=${domain.version()}")
        getStdOut().flush()
        return started
    }

    /// Cancel this region's animation binding on close, so a stopped window
    /// requests no further animation frames and the old completion cannot land
    /// after teardown.
    private func cancelGeneratedAnimation(): Unit {
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return
        }
        let declaredNodeId = synchronized(lock) { holder.nodeIdForKey(GENERATED_OPACITY_KEY) }
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == declaredNodeId) {
                let cancelled = window.cancelNodeOpacityAnimation(node.identityKey)
                getStdOut().writeln("CJGUI_GENERATED_ANIMATION_CANCELLED identity=${node.identityKey} " +
                    "cancelled=${if (cancelled) { 1 } else { 0 }} active=${window.activeAnimationCount()}")
                getStdOut().flush()
            }
        }
        let positionNodeId = synchronized(lock) { holder.nodeIdForKey(GENERATED_POSITION_TARGET_KEY) }
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == positionNodeId) {
                let _ = window.cancelNodeTranslationAnimation(node.identityKey)
            }
        }
    }

    /// Close-time hook: cancel this region's animation bindings so a closing
    /// window drops its bindings deterministically (the window's own teardown
    /// also cancels, this makes the consumer-side fact explicit and greppable).
    public func prepareWindowClose(): Unit {
        cancelGeneratedAnimation()
    }

    /// Drive the generated node's paint alpha through the public window entry.
    /// Used by the consumer's own `--verify-animation` check and by the button
    /// action; both call the SAME private implementation, so there is no second
    /// animation path.
    public func driveGeneratedOpacity(target: Float64, phase: String): Bool {
        return animateGeneratedOpacity(GENERATED_OPACITY_KEY, target, phase)
    }

    /// Read the current target/presented alpha and activity for the generated
    /// node, so a consumer or a verification script observes the same facts the
    /// framework holds without a per-frame broadcast.
    public func animationObservation(): String {
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return "window=none"
        }
        var identity = ""
        let declaredNodeId = synchronized(lock) { holder.nodeIdForKey(GENERATED_OPACITY_KEY) }
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == declaredNodeId) {
                identity = node.identityKey
            }
        }
        if (identity.size == 0) {
            return "identity=absent"
        }
        let presented = match (window.animatedNodeOpacity(identity)) {
            case Some(value) => value
            case None => -1.0
        }
        let target = match (window.animatedNodeOpacityTarget(identity)) {
            case Some(value) => value
            case None => -1.0
        }
        return "identity=${identity} presented=${presented} target=${target} " +
            "active=${window.activeAnimationCount()} bindings=${window.animationBindingCount()}"
    }

    /// Structured read of the SAME projection, for a caller that asserts exact
    /// values instead of parsing a display string. Returns identity="" when the
    /// generated node is absent from the accepted scene.
    public func animationSnapshot(): CjguiGeneratedAnimationSnapshot {
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return CjguiGeneratedAnimationSnapshot("", -1.0, -1.0, -1, -1)
        }
        var identity = ""
        let declaredNodeId = synchronized(lock) { holder.nodeIdForKey(GENERATED_OPACITY_KEY) }
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == declaredNodeId) {
                identity = node.identityKey
            }
        }
        if (identity.size == 0) {
            return CjguiGeneratedAnimationSnapshot("", -1.0, -1.0, window.activeAnimationCount(),
                window.animationBindingCount())
        }
        let presented = match (window.animatedNodeOpacity(identity)) {
            case Some(value) => value
            case None => -1.0
        }
        let target = match (window.animatedNodeOpacityTarget(identity)) {
            case Some(value) => value
            case None => -1.0
        }
        return CjguiGeneratedAnimationSnapshot(identity, presented, target,
            window.activeAnimationCount(), window.animationBindingCount())
    }

    public func positionMotionStatus(): ?CjguiComposableUiPositionStatus {
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return None
        }
        let targetId = synchronized(lock) { holder.nodeIdForKey(GENERATED_POSITION_TARGET_KEY) }
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == targetId) { return window.animatedNodeTranslation(node.identityKey) }
        }
        return None
    }

    /// Whether the accepted scene currently carries the generated node this
    /// region animates. A self-verification reads this before driving anything.
    public func generatedAnimationNodeReady(): Bool {
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return false
        }
        let declaredNodeId = synchronized(lock) { holder.nodeIdForKey(GENERATED_OPACITY_KEY) }
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeId == declaredNodeId) {
                return true
            }
        }
        return false
    }

    /// The published motion-rule capability line, re-exported so the consumer
    /// entry can announce it on stdout.
    public func motionCapabilityLine(): String {
        return CjguiGeneratedMotionRegistry.capabilityLine()
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
        // Effect transitions address the generated description itself, not a
        // business record, so they are available whenever the region is live.
        if (actionName == "CYCLE_GENERATED_EFFECT" || actionName == "REMOVE_GENERATED_EFFECT" ||
            actionName == "RESTORE_GENERATED_EFFECT" || actionName == "SUBMIT_INVALID_EFFECT" ||
            actionName == "ANIMATE_GENERATED_OPACITY" || actionName == "ANIMATE_GENERATED_POSITION" ||
            actionName == "CLEAR_GENERATED_POSITION" ||
            actionName == "TOGGLE_WINDOW_BACKGROUND" ||
            actionName == "CLEAR_WINDOW_BACKGROUND" || actionName == "CONTROL_TREE_GROUP" ||
            actionName == "CONTROL_TREE_LEAF" || actionName == "CONTROL_BUTTON" ||
            actionName == "CONTROL_ACCENT" || actionName == "PNG_TRANSFER_ENDPOINT") {
            return CjguiSharedAvailability.allowed(resourceId, revision())
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
        // Effect transitions address the generated description, not a record.
        if (actionName == "CYCLE_GENERATED_EFFECT" || actionName == "REMOVE_GENERATED_EFFECT" ||
            actionName == "RESTORE_GENERATED_EFFECT" || actionName == "SUBMIT_INVALID_EFFECT" ||
            actionName == "ANIMATE_GENERATED_OPACITY" || actionName == "ANIMATE_GENERATED_POSITION" ||
            actionName == "CLEAR_GENERATED_POSITION" ||
            actionName == "TOGGLE_WINDOW_BACKGROUND" ||
            actionName == "CLEAR_WINDOW_BACKGROUND" || actionName == "CONTROL_TREE_GROUP" ||
            actionName == "CONTROL_TREE_LEAF" || actionName == "CONTROL_BUTTON" ||
            actionName == "CONTROL_ACCENT") {
            return true
        }
        // Theme actions address the named-style catalog, not a selected record.
        // Keep the generated control enabled even when the data list is empty.
        if (actionName == "TOGGLE_TITLE_ACCENT") {
            return catalog.namedStyles().forName("panel_tab_title").isSome()
        }
        return false
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        if (actionName == "PNG_TRANSFER_ENDPOINT") {
            return CjguiGeneratedUiActionResult(false, "transfer_requires_clipboard_or_drag")
        }
        if (actionName == "CONTROL_ACCENT") {
            let window = match (attachedWindow) {
                case Some(value) => value
                case None => return CjguiGeneratedUiActionResult(false, "window_unavailable")
            }
            let next = if (window.platformAccentStatus().preference == "system") { "#b02088ff" }
                else { "system" }
            let applied = window.selectAccentPreference(next)
            if (applied) { generatedControlActionCountValue += 1 }
            getStdOut().writeln("CJGUI_GENERATED_CONTROL action=accent preference=${next} " +
                "applied=${applied} count=${generatedControlActionCountValue}")
            return CjguiGeneratedUiActionResult(applied, if (applied) { "none" } else { "accent_unchanged" })
        }
        if (actionName == "CONTROL_BUTTON") {
            generatedControlActionCountValue += 1
            synchronized(lock) {
                lastOutcome = "生成按钮 owner 激活 ${generatedControlActionCountValue} 次"
                revisionValue += 1
            }
            getStdOut().writeln("CJGUI_GENERATED_CONTROL action=button count=${generatedControlActionCountValue}")
            return CjguiGeneratedUiActionResult(true, "none")
        }
        if (actionName == "CONTROL_TREE_GROUP" || actionName == "CONTROL_TREE_LEAF") {
            let (acceptedExpanded, acceptedSelected) = acceptedTreeFlags()
            let nextExpanded = if (actionName == "CONTROL_TREE_GROUP") { !acceptedExpanded }
                else { acceptedExpanded }
            let nextSelected = if (actionName == "CONTROL_TREE_LEAF") { !acceptedSelected }
                else { acceptedSelected }
            let proposed = CjguiTaskGeneratedRegion.effectStructure(effectVariantValue, effectVisibleValue,
                windowBackground: windowBackgroundValue, treeExpanded: nextExpanded, treeSelected: nextSelected)
            let submitted = submitStructure(proposed, acceptedStructureVersion()).candidateAccepted
            if (submitted) {
                generatedTreeExpandedValue = nextExpanded
                generatedTreeSelectedValue = nextSelected
                generatedControlActionCountValue += 1
            }
            synchronized(lock) {
                lastOutcome = if (submitted) { "生成树 owner 状态等待 accepted scene" }
                    else { "生成树候选被拒" }
                revisionValue += 1
            }
            getStdOut().writeln("CJGUI_GENERATED_CONTROL action=${actionName} accepted=${submitted} " +
                "expanded=${generatedTreeExpandedValue} selected=${generatedTreeSelectedValue} " +
                "count=${generatedControlActionCountValue}")
            return CjguiGeneratedUiActionResult(submitted, if (submitted) { "none" } else { "control_candidate_rejected" })
        }
        if (actionName == "TOGGLE_WINDOW_BACKGROUND") {
            let nextValue = if (windowBackgroundValue == CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA) {
                CjguiWindowBackgroundPolicy.OPAQUE
            } else {
                CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA
            }
            let submitted = submitWindowBackground(nextValue)
            if (submitted) {
                windowBackgroundValue = nextValue
            }
            synchronized(lock) {
                lastOutcome = if (submitted) {
                    "生成根窗口材质已切换为 ${nextValue}，等待 accepted scene"
                } else {
                    "生成根窗口材质切换被拒"
                }
            }
            return CjguiGeneratedUiActionResult(submitted,
                if (submitted) { "none" } else { "window_background_structure_rejected" })
        }
        if (actionName == "CLEAR_WINDOW_BACKGROUND") {
            let submitted = submitWindowBackground("")
            if (submitted) {
                windowBackgroundValue = ""
            }
            synchronized(lock) {
                lastOutcome = if (submitted) {
                    "生成根窗口材质属性已省略，默认 opaque，等待 accepted scene"
                } else {
                    "生成根窗口材质清除被拒"
                }
            }
            return CjguiGeneratedUiActionResult(submitted,
                if (submitted) { "none" } else { "window_background_structure_rejected" })
        }
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
        // P4 effect-group transitions: each re-submits a whole generated
        // description carrying a different declared effectGroup. The effect therefore
        // always originates in the generated declaration, never in consumer
        // paint code.
        if (actionName == "CYCLE_GENERATED_EFFECT") {
            let nextVariant = (effectVariantValue + 1) % 3
            let submitted = submitEffectStructure(nextVariant, true)
            if (submitted) {
                effectVariantValue = nextVariant
                effectVisibleValue = true
            }
            synchronized(lock) {
                lastOutcome = if (submitted) {
                    "生成效果组已切换 → v${effectVariantValue}（经生成提交入口）"
                } else {
                    "生成效果切换被拒"
                }
            }
            emitGeneratedEffectState("CYCLE_GENERATED_EFFECT", submitted)
            return CjguiGeneratedUiActionResult(submitted, if (submitted) { "none" } else { "effect_structure_rejected" })
        }
        if (actionName == "REMOVE_GENERATED_EFFECT") {
            let submitted = submitEffectStructure(effectVariantValue, false)
            if (submitted) { effectVisibleValue = false }
            synchronized(lock) {
                lastOutcome = if (submitted) {
                    "生成效果组已清除（effectGroup=none，经生成提交入口）"
                } else {
                    "生成效果组清除被拒"
                }
            }
            emitGeneratedEffectState("REMOVE_GENERATED_EFFECT", submitted)
            return CjguiGeneratedUiActionResult(submitted, if (submitted) { "none" } else { "effect_structure_rejected" })
        }
        if (actionName == "RESTORE_GENERATED_EFFECT") {
            let submitted = submitEffectStructure(0, true)
            if (submitted) {
                effectVariantValue = 0
                effectVisibleValue = true
            }
            synchronized(lock) {
                lastOutcome = if (submitted) {
                    "生成效果组已恢复（经生成提交入口）"
                } else {
                    "生成效果组恢复被拒"
                }
            }
            emitGeneratedEffectState("RESTORE_GENERATED_EFFECT", submitted)
            return CjguiGeneratedUiActionResult(submitted, if (submitted) { "none" } else { "effect_structure_rejected" })
        }
        if (actionName == "SUBMIT_INVALID_EFFECT") {
            let summary = submitInvalidEffectCandidates()
            synchronized(lock) { lastOutcome = summary }
            emitGeneratedEffectState("SUBMIT_INVALID_EFFECT", true)
            return CjguiGeneratedUiActionResult(true, "none")
        }
        if (actionName == "ANIMATE_GENERATED_OPACITY") {
            // A value transition on the generated node. Repeating it fast, or
            // reversing mid-flight, is a retarget on the same accepted identity:
            // the framework keeps the current visual value and continues from it.
            opacityHighValue = !opacityHighValue
            let target = if (opacityHighValue) { GENERATED_OPACITY_HIGH } else { GENERATED_OPACITY_LOW }
            let started = animateGeneratedOpacity(GENERATED_OPACITY_KEY, target,
                if (opacityHighValue) { "high" } else { "low" })
            synchronized(lock) {
                lastOutcome = if (started) {
                    "生成节点透明度目标 → ${target}（同一定义身份）"
                } else {
                    "生成节点透明度未驱动：accepted 场景暂无 ${GENERATED_OPACITY_KEY}"
                }
            }
            return CjguiGeneratedUiActionResult(started, if (started) { "none" } else { "animation_identity_missing" })
        }
        if (actionName == "ANIMATE_GENERATED_POSITION") {
            let nextHigh = !positionHighValue
            let started = animateGeneratedPosition(nextHigh)
            if (started) { positionHighValue = nextHigh }
            synchronized(lock) {
                lastOutcome = if (started) { "生成分栏平移目标已接受" } else { "生成分栏平移被拒" }
            }
            return CjguiGeneratedUiActionResult(started,
                if (started) { "none" } else { "position_motion_rejected" })
        }
        if (actionName == "CLEAR_GENERATED_POSITION") {
            let window = match (attachedWindow) {
                case Some(value) => value
                case None => return CjguiGeneratedUiActionResult(false, "window_unavailable")
            }
            let targetId = synchronized(lock) { holder.nodeIdForKey(GENERATED_POSITION_TARGET_KEY) }
            for (node in window.acceptedSceneNodes()) {
                if (node.nodeId == targetId) {
                    let cleared = window.cancelNodeTranslationAnimation(node.identityKey)
                    if (cleared) { positionHighValue = false }
                    getStdOut().writeln("CJGUI_GENERATED_POSITION_CLEAR identity=${node.identityKey} " +
                        "cleared=${if (cleared) { 1 } else { 0 }} owner_version=${domain.version()}")
                    getStdOut().flush()
                    return CjguiGeneratedUiActionResult(cleared,
                        if (cleared) { "none" } else { "position_motion_absent" })
                }
            }
            return CjguiGeneratedUiActionResult(false, "position_identity_missing")
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
        // Generated actions resolve into the normal window transfer provider
        // from the same build identity snapshot. The owner remains application
        // code; declarations are installed only with their accepted scene.
        let png = CjguiComposableUiPngTransferCapability()
        return CjguiGeneratedUiEncoding.describe(catalog) +
            "\nTRANSFER_ENDPOINT_METADATA ${png.mimeFormat} roles=TARGET,SOURCE " +
            "binding=accepted_generated_scene_snapshot status=provider_connected " +
            "backend=${png.backend} system_format=${png.systemFormat} " +
            "file_url_format=${png.localFileSystemFormat} file_source_order=${png.optInSourceOrder} " +
            "image_class=${png.imageClass} bit_depths=${png.supportedBitDepths} " +
            "color_types=${png.supportedColorTypes} interlace=${png.supportedInterlaceModes} " +
            "max_bytes=${png.maximumEncodedItemBytes} max_pixels=${png.maximumPixels} " +
            "max_width=${png.maximumWidth} max_height=${png.maximumHeight} " +
            "queue_bytes=${png.maximumQueuedBinaryBytes} decoded_bytes=${png.maximumDecodedTextureBytes} " +
            "encoded_resource_bytes=${png.maximumRetainedEncodedResourceBytes} " +
            "resource_records=${png.maximumResourceRecords} " +
            "pending_events_per_window=${png.maximumPendingEventsPerWindow} " +
            "system_fetch_preflight_bounded=${png.systemFetchPreflightBounded} " +
            "owner=application_provider"
    }

    /// Accepted generated endpoints are the immutable identity snapshot promoted
    /// with the exact scene transaction. No join against a later holder build is
    /// performed here.
    public func acceptedTransferEndpoints(): ArrayList<CjguiTaskGeneratedTransferEndpoint> {
        return synchronized(lock) {
            let result = ArrayList<CjguiTaskGeneratedTransferEndpoint>()
            for (endpoint in acceptedTransferSnapshot.endpoints) {
                result.add(endpoint)
            }
            result
        }
    }

    /// Endpoints corresponding to the current scene build. The window calls
    /// this from its transfer provider while staging declarations for that same
    /// scene. Before the region has completed a build in this transaction the
    /// result is empty, which prevents stale or unaccepted identities escaping.
    public func refreshTransferEndpoints(): ArrayList<CjguiTaskGeneratedTransferEndpoint> {
        return synchronized(lock) {
            let result = ArrayList<CjguiTaskGeneratedTransferEndpoint>()
            if (let Some(snapshot) <- refreshTransferSnapshot) {
                for (endpoint in snapshot.endpoints) {
                    result.add(endpoint)
                }
            }
            result
        }
    }

    /// Protocol readback of only scene-accepted generated endpoint identities.
    public func acceptedTransferEndpointsPayload(): String {
        let endpoints = acceptedTransferEndpoints()
        let builder = StringBuilder()
        builder.append("TRANSFER_ENDPOINTS ${endpoints.size}\n")
        for (endpoint in endpoints) {
            builder.append("TRANSFER_ENDPOINT ${endpoint.declaredKey} ${endpoint.role} ${endpoint.format} " +
                "node=${endpoint.nodeId} " +
                "semantic=${endpoint.semanticId} incarnation=${endpoint.receiverIncarnation} " +
                "file_source=${if (endpoint.localPngFileAllowed) { "local_file_url" } else { "none" }}\n")
        }
        return builder.toString()
    }

    /// Accepted-key metadata can be inspected without a native window. This is
    /// deliberately separate from the binding list: application code must still
    /// pass these keys through its data-transfer provider before OS input is read.
    public func acceptedTransferMetadataPayload(): String {
        return synchronized(lock) {
            let fileSource = if (acceptedTransferSnapshot.candidate.targetLocalPngFileAllowed) {
                "local_file_url"
            } else {
                "none"
            }
            "TRANSFER_METADATA version=${holder.structureVersion()} " +
                "target=${if (acceptedTransferTargetKey.size > 0) { acceptedTransferTargetKey } else { "none" }} " +
                "source=${if (acceptedTransferSourceKey.size > 0) { acceptedTransferSourceKey } else { "none" }} " +
                "format=${if (acceptedTransferTargetFormat.size > 0) { acceptedTransferTargetFormat } else { "none" }} " +
                "file_source=${fileSource} " +
                "target_action=${if (acceptedTransferTargetActionName.size > 0) { acceptedTransferTargetActionName } else { "none" }} " +
                "receiver_incarnation=${transferReceiverIncarnation}\n"
        }
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
        var effectFacts = ""
        var platformFacts = ""
        var instances = ArrayList<CjguiGeneratedUiAcceptedInstance>()
        match (attachedWindow) {
            case Some(window) =>
                acceptedInstanceSamplesValue += 1
                instances = cjguiGeneratedUiAcceptedInstances(window, holder)
                let progress = window.windowProgress()
                identity = progress.sessionIdentity
                sceneVersion = progress.acceptedSceneVersion
                interactionRevision = progress.interactionVersion
                effectFacts = progress.effectFactsPayload()
                platformFacts = window.platformAccentStatus().describe() + "\n" +
                    progress.geometryFactsPayload()
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
            structureCandidatePending: holder.hasPendingCandidate(),
            effectFacts: effectFacts, platformFacts: platformFacts)
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
            } else if (section == "EFFECTS") {
                source.effectFacts
            } else if (section == "PLATFORM") {
                source.platformFacts
            } else {
                ""
            }
            return cjguiGeneratedUiSectionPayload(tracker, section, expectedCursor, payload)
        }
    }

    private func collectTransferCandidate(node: CjguiGeneratedUiNodeSpec, path: String,
        candidate: CjguiTaskGeneratedTransferCandidate): Unit {
        if (candidate.reason.size == 0) {
            let role = node.property("transferRole")
            let format = node.property("transferFormat")
            let fileSource = node.property("transferFileSource")
            if (role.size > 0 || format.size > 0) {
                if (node.kind != "action") {
                    candidate.reason = "transfer_endpoint_must_be_action"
                    candidate.path = "${path}/${node.key}"
                } else if (role.size == 0) {
                    candidate.reason = "transfer_role_required"
                    candidate.path = "${path}/${node.key}/transferRole"
                } else if (format != "image/png") {
                    candidate.reason = "transfer_format_unsupported"
                    candidate.path = "${path}/${node.key}/transferFormat"
                } else if (fileSource.size > 0 && fileSource != "none" && fileSource != "local_file_url") {
                    candidate.reason = "transfer_file_source_unsupported"
                    candidate.path = "${path}/${node.key}/transferFileSource"
                } else if (role != "TARGET" && fileSource == "local_file_url") {
                    candidate.reason = "transfer_file_source_requires_target"
                    candidate.path = "${path}/${node.key}/transferFileSource"
                } else if (role == "TARGET") {
                    if (candidate.targetKey.size > 0) {
                        candidate.reason = "duplicate_transfer_target"
                        candidate.path = "${path}/${node.key}/transferRole"
                    } else {
                        candidate.targetKey = node.key
                        candidate.targetFormat = format
                        candidate.targetLocalPngFileAllowed = fileSource == "local_file_url"
                        candidate.targetActionName = node.actionName
                    }
                } else if (role == "SOURCE") {
                    if (candidate.sourceKey.size > 0) {
                        candidate.reason = "duplicate_transfer_source"
                        candidate.path = "${path}/${node.key}/transferRole"
                    } else {
                        candidate.sourceKey = node.key
                    }
                } else {
                    candidate.reason = "transfer_role_invalid"
                    candidate.path = "${path}/${node.key}/transferRole"
                }
            }
        }
        var childIndex: Int64 = 0
        while (childIndex < node.children.size && candidate.reason.size == 0) {
            collectTransferCandidate(node.children[childIndex], "${path}/${node.key}", candidate)
            childIndex += 1
        }
    }

    private func transferCandidateFor(root: CjguiGeneratedUiNodeSpec): CjguiTaskGeneratedTransferCandidate {
        let candidate = CjguiTaskGeneratedTransferCandidate()
        collectTransferCandidate(root, "root", candidate)
        return candidate
    }

    private func acceptedTransferCandidate(): CjguiTaskGeneratedTransferCandidate {
        let candidate = CjguiTaskGeneratedTransferCandidate()
        if (let Some(root) <- holder.acceptedStructure()) {
            collectTransferCandidate(root, "root", candidate)
        }
        return candidate
    }

    private func copyTransferCandidate(source: CjguiTaskGeneratedTransferCandidate): CjguiTaskGeneratedTransferCandidate {
        let copy = CjguiTaskGeneratedTransferCandidate()
        copy.targetKey = source.targetKey
        copy.sourceKey = source.sourceKey
        copy.targetFormat = source.targetFormat
        copy.targetLocalPngFileAllowed = source.targetLocalPngFileAllowed
        copy.targetActionName = source.targetActionName
        copy.reason = source.reason
        copy.path = source.path
        return copy
    }

    private func makeRefreshTransferSnapshot(): ?CjguiTaskGeneratedTransferSnapshot {
        let isCandidateBuild = holder.hasPendingCandidate() && refreshCandidateToken > 0 &&
            holder.pendingCandidateToken() == refreshCandidateToken
        let candidate = if (isCandidateBuild) {
            match (refreshCandidateMetadata) {
                case Some(value) => copyTransferCandidate(value)
                case None => copyTransferCandidate(acceptedTransferSnapshot.candidate)
            }
        } else {
            copyTransferCandidate(acceptedTransferSnapshot.candidate)
        }
        let nextIncarnation = if (candidate.targetKey == acceptedTransferSnapshot.candidate.targetKey &&
            candidate.targetFormat == acceptedTransferSnapshot.candidate.targetFormat &&
            candidate.targetLocalPngFileAllowed == acceptedTransferSnapshot.candidate.targetLocalPngFileAllowed &&
            candidate.targetActionName == acceptedTransferSnapshot.candidate.targetActionName) {
            acceptedTransferSnapshot.receiverIncarnation
        } else {
            if (acceptedTransferSnapshot.receiverIncarnation >= 0x7FFFFFFFFFFFFFFE) {
                lastOutcome = "PNG 接收端代次耗尽，拒绝场景提交"
                return None
            }
            acceptedTransferSnapshot.receiverIncarnation + 1
        }
        let endpoints = ArrayList<CjguiTaskGeneratedTransferEndpoint>()
        var targetAdded = candidate.targetKey.size == 0
        var sourceAdded = candidate.sourceKey.size == 0
        if (candidate.targetKey.size > 0) {
            if (let Some(identity) <- holder.refreshIdentityForKey(candidate.targetKey)) {
                if (identity.nodeId > 0 && identity.semanticId.size > 0) {
                    endpoints.add(CjguiTaskGeneratedTransferEndpoint(candidate.targetKey, "TARGET",
                        candidate.targetFormat, identity.nodeId, identity.semanticId, nextIncarnation,
                        localPngFileAllowed: candidate.targetLocalPngFileAllowed))
                    targetAdded = true
                }
            }
        }
        if (candidate.sourceKey.size > 0) {
            if (let Some(identity) <- holder.refreshIdentityForKey(candidate.sourceKey)) {
                if (identity.nodeId > 0 && identity.semanticId.size > 0) {
                    endpoints.add(CjguiTaskGeneratedTransferEndpoint(candidate.sourceKey, "SOURCE",
                        "image/png", identity.nodeId, identity.semanticId, 0))
                    sourceAdded = true
                }
            }
        }
        // A declared key that failed to resolve against this exact build is a
        // stale provider contract. Fail preparation instead of allowing the
        // window to bind a previous semantic identity.
        if (!targetAdded || !sourceAdded) {
            lastOutcome = "PNG 端点身份未出现在本轮生成构建中"
            return None
        }
        return Some(CjguiTaskGeneratedTransferSnapshot(candidate, endpoints, nextIncarnation))
    }

    private func updateAcceptedTransferMetadata(candidate: CjguiTaskGeneratedTransferCandidate): Unit {
        acceptedTransferTargetKey = candidate.targetKey
        acceptedTransferSourceKey = candidate.sourceKey
        acceptedTransferTargetFormat = candidate.targetFormat
        acceptedTransferTargetActionName = candidate.targetActionName
        transferReceiverIncarnation = acceptedTransferSnapshot.receiverIncarnation
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
            if (refreshInFlight) {
                holder.rejectCandidateAttempt(token, "scene_refresh_busy", "")
                lastOutcome = "生成结构提交拒绝：场景刷新仍在途"
                let current = holder.structureVersion()
                return CjguiSharedOperationGeneratedUiSubmit(false, "scene_refresh_busy", "",
                    current, current, candidateToken: token,
                    receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
            }
            let current = holder.structureVersion()
            if (expectedVersion != current) {
                holder.rejectCandidateAttempt(token, "structure_version_conflict", "")
                lastOutcome = "结构版本冲突：期望 ${expectedVersion}，当前 ${current}"
                return CjguiSharedOperationGeneratedUiSubmit(false, "structure_version_conflict", "",
                    current, current, candidateToken: token,
                    receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
            }
            let transferCandidate = transferCandidateFor(root)
            if (transferCandidate.reason.size > 0) {
                holder.rejectCandidateAttempt(token, transferCandidate.reason, transferCandidate.path)
                lastOutcome = "PNG 端点候选被拒：${transferCandidate.reason} @${transferCandidate.path}"
                return CjguiSharedOperationGeneratedUiSubmit(false, transferCandidate.reason,
                    transferCandidate.path, current, current, candidateToken: token,
                    receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
            }
            let result = holder.submit(root, this, attemptToken: token)
            if (!result.candidateAccepted) {
                lastOutcome = "结构被拒：${result.reason} @${result.path}"
            } else {
                pendingTransferCandidate = Some(copyTransferCandidate(transferCandidate))
                pendingTransferToken = result.candidateToken
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
            if (refreshInFlight) {
                return false
            }
            // Style resolutions belong to the scene built from here on.
            holder.beginStyleRefresh()
            if (!holder.beginCandidateRefresh()) {
                holder.rollbackStyleRefresh()
                return false
            }
            refreshInFlight = true
            refreshCandidateToken = if (holder.hasPendingCandidate()) { holder.pendingCandidateToken() } else { 0 }
            refreshCandidateMetadata = if (refreshCandidateToken > 0 && refreshCandidateToken == pendingTransferToken) {
                pendingTransferCandidate
            } else {
                None
            }
            refreshTransferSnapshot = None
            return true
        }
    }

    public func prepareSceneRefresh(): Bool {
        return synchronized(lock) {
            if (!refreshInFlight || !holder.prepareCandidateRefresh()) {
                return false
            }
            match (makeRefreshTransferSnapshot()) {
                case Some(snapshot) =>
                    refreshTransferSnapshot = Some(snapshot)
                    return true
                case None =>
                    return false
            }
        }
    }

    public func commitSceneRefresh(): Unit {
        synchronized(lock) {
            if (!refreshInFlight) { return }
            // The accepted scene consumed the owner projection it was built from,
            // ordinary refresh or not.
            acceptedOwnerStamp = pendingOwnerStamp
            // Promote the style resolutions this accepted scene used, and drop
            // records no longer referenced by the accepted structure.
            holder.commitStyleRefresh()
            let hadCandidate = holder.hasPendingCandidate()
            let candidateToken = refreshCandidateToken
            let candidateCommitted = if (hadCandidate) { holder.commitCandidateRefresh() } else { true }
            if (candidateCommitted) {
                if (let Some(snapshot) <- refreshTransferSnapshot) {
                    acceptedTransferSnapshot = snapshot
                    updateAcceptedTransferMetadata(snapshot.candidate)
                }
                if (hadCandidate) {
                    // A startup refresh can commit before the first generated
                    // structure is submitted. Keep its intended initial window
                    // declaration until an actual candidate is accepted.
                    windowBackgroundValue = holder.acceptedWindowBackground()
                    lastOutcome = "结构已接受：v${holder.structureVersion()}"
                    revisionValue += 1
                }
            } else if (hadCandidate) {
                lastOutcome = "场景拒绝：${holder.lastSceneOutcome()}"
                revisionValue += 1
            }
            if (candidateToken > 0 && candidateToken == pendingTransferToken) {
                pendingTransferCandidate = None
                pendingTransferToken = 0
            }
            refreshInFlight = false
            refreshCandidateToken = 0
            refreshCandidateMetadata = None
            refreshTransferSnapshot = None
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
            if (!refreshInFlight) { return }
            holder.rollbackStyleRefresh()
            if (holder.hasPendingCandidate()) {
                holder.rollbackCandidateRefresh()
                windowBackgroundValue = holder.acceptedWindowBackground()
                lastOutcome = "场景拒绝：${holder.lastSceneOutcome()}"
                revisionValue += 1
            }
            if (refreshCandidateToken > 0 && refreshCandidateToken == pendingTransferToken) {
                pendingTransferCandidate = None
                pendingTransferToken = 0
            }
            refreshInFlight = false
            refreshCandidateToken = 0
            refreshCandidateMetadata = None
            refreshTransferSnapshot = None
        }
    }

    // --- section + events ---------------------------------------------------

    public func buildSection(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        // This section owns a fixed dark surface even when the surrounding
        // window follows the light system theme. Its own labels therefore use
        // the surface foreground rather than the outer page's dark text.
        let sectionHeading = CjguiComposableUiStyle(
            textColor: CjguiComposableUiColor(0.94, 0.97, 1.0, 1.0),
            fontSize: theme.heading.fontSize, fontWeight: theme.heading.fontWeight)
        let sectionBody = CjguiComposableUiStyle(
            textColor: CjguiComposableUiColor(0.80, 0.88, 0.97, 1.0),
            fontSize: theme.body.fontSize, fontWeight: theme.body.fontWeight)
        let section = cjguiComposableVertical(900, "task-generated-section",
            CjguiComposableUiStyle(padding: 10, gap: 6, growX: 1,
                background: CjguiComposableUiColor(0.10, 0.16, 0.26, 0.9),
                border: CjguiComposableUiColor(0.26, 0.40, 0.62, 0.9)))
        section.add(cjguiComposableText(901, "task-generated-title",
            "生成区域 · 结构 v${holder.structureVersion()}", sectionHeading))
        section.add(synchronized(lock) {
            pendingOwnerStamp = ownerStamp()
            // Sample the native preparation state of the ACCEPTED image bindings
            // here: this build already runs on the window's own thread, so the
            // public read path never calls native itself.
            match (attachedWindow) {
                case Some(window) => holder.sampleImageResourceStates(window)
                case None => ()
            }
            let node = holder.buildRefreshNode(this)
            refreshTransferSnapshot = makeRefreshTransferSnapshot()
            node
        })
        section.add(cjguiComposableText(902, "task-generated-status", statusText(), sectionBody))
        return section
    }

    /// Navigate the accepted generated outline. The common scroll-area key
    /// channel brings the directional intent here; every target is read from
    /// accepted instances, so a public replacement or rejected candidate never
    /// makes an old row key address a new control. Expansion still enters the
    /// same owner action as pointer and AX activation.
    private func navigateAcceptedControlTree(direction: String): CjguiComposableUiDispatchResult {
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return CjguiComposableUiDispatchResult(false)
        }
        var groupSemantic = ""
        var leafSemantic = ""
        var groupExpanded = false
        for (instance in cjguiGeneratedUiAcceptedInstances(window, holder)) {
            if (instance.key == "controlGroup" && instance.controlRole == "row" && instance.controlEnabled) {
                groupSemantic = instance.semanticId
                groupExpanded = instance.controlExpanded
            } else if (instance.key == "controlLeaf" && instance.controlRole == "row" &&
                instance.controlEnabled) {
                leafSemantic = instance.semanticId
            }
        }
        if (groupSemantic.size == 0) { return CjguiComposableUiDispatchResult(false) }
        let focused = window.windowProgress().focusedControlId
        if (direction == "right" && focused == groupSemantic && !groupExpanded) {
            return CjguiComposableUiDispatchResult(executeAction("CONTROL_TREE_GROUP", "controlGroup").applied)
        }
        if (direction == "left" && focused == groupSemantic && groupExpanded) {
            return CjguiComposableUiDispatchResult(executeAction("CONTROL_TREE_GROUP", "controlGroup").applied)
        }
        let target = if (direction == "up" || direction == "home" || direction == "page_up" ||
            (direction == "left" && focused == leafSemantic)) {
            groupSemantic
        } else if (direction == "down" || direction == "end" || direction == "page_down" ||
            (direction == "right" && focused == groupSemantic && groupExpanded)) {
            if (groupExpanded && leafSemantic.size > 0) { leafSemantic } else { groupSemantic }
        } else {
            ""
        }
        if (target.size == 0 || target == focused) { return CjguiComposableUiDispatchResult(false) }
        return CjguiComposableUiDispatchResult(window.focusAcceptedSemanticNode(target))
    }

    public func handleEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 35 && event.node.nodeId == holder.nodeIdForKey("controlOutline")) {
            return navigateAcceptedControlTree(event.text)
        }
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

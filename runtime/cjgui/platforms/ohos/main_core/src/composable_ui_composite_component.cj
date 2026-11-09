// Public EXPERIMENTAL seam that lets an application register its own COMPILED
// Cangjie composite implementation, so the same implementation is used by a
// handwritten region and by the runtime-generated region.
//
// What this is NOT: a plugin system, a dynamic source interpreter, an Agent
// runtime or a downloaded-component registry. The factory is a Cangjie object
// the application constructs in its own code; an external description can only
// reference the kind it registered - it can never submit executable callbacks,
// owner targets or writer operations.
//
// Ownership rules enforced here and by the holder:
//   * the framework allocates the scoped instance and every element's identity
//     (node id + semantic id); the factory only wires the ids it is handed, so a
//     custom component cannot invent an id that collides with the window's;
//   * the framework resolves field/action bindings from the registered field and
//     action definitions; the factory receives resolved targets and never
//     derives an owner or a writer;
//   * building a composite only produces a projection - it never performs a
//     business write, and a rebuild/reorder cannot write either;
//   * the expanded subtree the factory returns is validated against the declared
//     node/depth budget and against the allocated element ids, so one custom
//     declaration cannot expand past the framework's capacity limits.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

/// Element roles a composite declares. A `field` element is an editable control
/// bound to a shared field; a `preset` element is a button that writes a
/// DECLARED constant through the same field's owner writer; an `action` element
/// dispatches a declared business action; a `container` element only lays out.
///
/// The real controls a factory mounts must carry the resolved binding, not just
/// the element identity: a `field` editor carries field id, writer and owner
/// target (with its own binding resource), and a `preset` button carries the
/// resolved writer and owner target plus its binding resource. The expansion
/// audit enforces that, so a same-key rebind to another owner target cannot be
/// answered with the old object's control.
public let CJGUI_COMPOSITE_ELEMENT_CONTAINER: String = "container"
public let CJGUI_COMPOSITE_ELEMENT_FIELD: String = "field"
public let CJGUI_COMPOSITE_ELEMENT_PRESET: String = "preset"
public let CJGUI_COMPOSITE_ELEMENT_ACTION: String = "action"
/// A read-only TEXT projection of the SAME frozen owner snapshot the other
/// elements are resolved from. It exists because a factory cannot mount its OWN
/// text node (every node needs a framework-allocated identity) and owner-provided
/// text - a field's validation error, an owner's blocking reason, the owner's
/// status line - must stay readable WITHOUT re-submitting the structure. The
/// framework resolves the string from the instance's one snapshot; the factory
/// only chooses where to place it and how to paint it. A projection never
/// writes business state and never carries a writer.
public let CJGUI_COMPOSITE_ELEMENT_PROJECTION: String = "projection"

/// Projection sources. Each names ONE owner fact that is already part of the
/// instance's frozen snapshot; none of them invents business wording.
/// `field_error`: the field's own validation error.
public let CJGUI_COMPOSITE_PROJECTION_FIELD_ERROR: String = "field_error"
/// `field_reason`: why the owner currently blocks editing that field.
public let CJGUI_COMPOSITE_PROJECTION_FIELD_REASON: String = "field_reason"
/// `action_reason`: why the owner currently blocks that action.
public let CJGUI_COMPOSITE_PROJECTION_ACTION_REASON: String = "action_reason"
/// `owner_status`: the owner snapshot's own status message.
public let CJGUI_COMPOSITE_PROJECTION_OWNER_STATUS: String = "owner_status"

/// Whether a node kind is an EDITABLE field control (it accepts a human edit)
/// rather than a read-only copy of a value. The composite audit uses this to
/// check the one thing a factory may not paint over: an editor the owner has
/// blocked must not still look editable. A read-only rendering of the same value
/// is deliberately not an editable control, so it is never forced disabled.
public func CjguiCompositeElementIsEditableFieldControl(nodeKind: Int64): Bool {
    return nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT || nodeKind == CJGUI_COMPOSABLE_UI_INTEGER_INPUT ||
        nodeKind == CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT || nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT
}

/// Intent kinds the public binding adapter resolves a control event into.
public let CJGUI_GENERATED_INTENT_NONE: String = "none"
public let CJGUI_GENERATED_INTENT_FIELD_EDIT: String = "field_edit"
public let CJGUI_GENERATED_INTENT_ACTION: String = "action"

/// Presentation name of an application composite. It is implemented only
/// together with a registered factory, so registering it cannot loosen the
/// built-in unknown-kind rejection.
public let CJGUI_GENERATED_PRESENTATION_COMPOSITE: String = "COMPOSITE"

/// One declared element of a composite. Every element gets a framework-allocated
/// identity, and `elementKey` is scoped to its instance, so the same kind can be
/// instantiated many times without sharing identities.
public class CjguiCompositeElementSpec {
    public let elementKey: String
    public let role: String
    /// role == field/preset: the shared field this element writes.
    public let fieldId: String
    /// role == field/preset: the declared argument name the field's writer takes.
    public let argumentName: String
    /// role == preset: the constant written on press. Declared as typed config by
    /// the application - never re-derived from a business limit inside the
    /// framework - so an out-of-range preset reaches the owner's rule instead of
    /// being clamped here.
    public let presetValue: String
    /// role == action: the declared business action this element requests.
    public let actionName: String
    /// role == projection: the owner fact this read-only text presents. It is a
    /// declaration, not a business value: the framework resolves the string from
    /// the instance's frozen snapshot on every build, so a value/error/lock
    /// update reaches the text without submitting a new structure.
    public let source: String
    /// Declared caption (empty = the action's own label / the field's label).
    public let label: String
    /// Parent element key ("" = the instance root).
    public let parentKey: String

    public init(elementKey: String, role: String, fieldId!: String = "", argumentName!: String = "",
                presetValue!: String = "", actionName!: String = "", label!: String = "",
                parentKey!: String = "", source!: String = "") {
        this.elementKey = elementKey
        this.role = role
        this.fieldId = fieldId
        this.argumentName = argumentName
        this.presetValue = presetValue
        this.actionName = actionName
        this.source = source
        this.label = label
        this.parentKey = parentKey
    }
}

/// One application composite kind: its declared properties (the ONLY properties
/// an external description may submit), its expanded-subtree ceiling, and its
/// elements. The framework validates a candidate against exactly this
/// declaration; anything else is an unknown property/kind rejection.
public class CjguiCompositeComponentSpec {
    public let kind: String
    public let properties: ArrayList<CjguiGeneratedUiPropertySpec>
    public let elements: ArrayList<CjguiCompositeElementSpec>
    /// Child rule: whether the description may nest generated children under an
    /// instance of this kind, and how many. Enforced by the ordinary validator
    /// through the derived component spec, not by the factory.
    public let allowsChildren: Bool
    public let childLimit: Int64
    /// Maximum number of composable nodes ONE instance may expand into. The
    /// holder checks the factory's real subtree against this and against the
    /// catalog's global node/depth budget.
    public let expandedNodeLimit: Int64
    public let expandedDepthLimit: Int64

    public init(kind: String, properties: ArrayList<CjguiGeneratedUiPropertySpec>,
                elements: ArrayList<CjguiCompositeElementSpec>,
                allowsChildren!: Bool = false, childLimit!: Int64 = 0,
                expandedNodeLimit!: Int64 = 16, expandedDepthLimit!: Int64 = 4) {
        this.kind = kind
        this.properties = properties
        this.elements = elements
        this.allowsChildren = allowsChildren
        this.childLimit = childLimit
        this.expandedNodeLimit = expandedNodeLimit
        this.expandedDepthLimit = expandedDepthLimit
    }

    public func elementFor(elementKey: String): ?CjguiCompositeElementSpec {
        for (element in elements) {
            if (element.elementKey == elementKey) {
                return Some(element)
            }
        }
        return None
    }
}

/// One framework-resolved element: the allocated identity plus the resolved
/// bindings. The factory uses these values; it cannot fabricate them.
public class CjguiCompositeElementBinding {
    /// The accepted object this element belongs to (the composite instance's
    /// stable key). A binding is only valid for that key's accepted node, so a
    /// late event can never be routed through another instance's binding.
    public let instanceKey: String
    /// Framework-assigned generation for this accepted composite instance. It
    /// survives a pure reorder and changes when the key is rebound or removed
    /// and re-added, so a held range/action session can prove it still belongs
    /// to the object it was accepted for.
    public let instanceIncarnation: Int64
    public let elementKey: String
    public let role: String
    public let nodeId: Int64
    public let semanticId: String
    public let label: String
    /// role field/preset: the shared field and the resolved owner writer.
    public let fieldId: String
    /// The writer's own ARGUMENT name, carried from the application's single
    /// field definition. A consumer hands this to the owner instead of guessing
    /// which argument the operation takes.
    public let argumentName: String
    public let writerOperation: String
    public let ownerTargetResourceId: Int64
    /// The owner target of the WHOLE instance, resolved once from the same
    /// field/action targeting the elements use. Every element of one instance
    /// carries it, so the instance identity and the per-element routes cannot
    /// disagree about which object the instance binds.
    public let instanceOwnerTargetResourceId: Int64
    public let bindingResourceId: Int64
    public let editorKind: String
    public let presetValue: String
    /// role action: the declared action and whether the owner currently allows it.
    public let actionName: String
    public let actionEnabled: Bool
    /// role field/preset: whether the owner CURRENTLY allows editing this field,
    /// projected from the same owner condition the write path enforces. A blocked
    /// field stays readable and carries the owner's reason; its target and draft
    /// are untouched.
    public let ownerAvailable: Bool
    public let blockedReason: String
    /// Live declared value, read through the provider exactly like the
    /// handwritten form (a legally empty draft stays an empty draft).
    public let draftText: String
    public let draftBoolean: Bool
    /// role field: the provider's ONE declared select binding for this field,
    /// when the application declared one. A runtime composition may therefore
    /// mount a select/radio/segmented presentation without creating a second
    /// controller or losing the shared option/query state.
    public let selectBinding: ?CjguiSelectFieldBinding
    /// role field: the field's CURRENT declared option set, frozen with the
    /// accepted binding. A runtime instance renders radio/segmented rows from
    /// this same fact and resolves an activation back into the instance's own
    /// field writer, so a second per-instance Select controller (and its
    /// single-owner commit closure) is never introduced.
    public let choiceOptions: ArrayList<CjguiSelectOption>
    /// role projection: the owner text this element presents, resolved from the
    /// instance's ONE frozen snapshot (a field's validation error, a field's or
    /// action's blocking reason, or the owner's status message). Empty means the
    /// owner publishes no such text right now - never an absent answer replaced
    /// by invented copy.
    public let projectionText: String
    /// role projection: the declared source the text was resolved from, carried
    /// so a data refresh can resolve the SAME fact again instead of guessing it
    /// from the element key.
    public let projectionSource: String

    public init(elementKey: String, role: String, nodeId: Int64, semanticId: String, label: String,
                instanceKey!: String = "", instanceIncarnation!: Int64 = 0, fieldId!: String = "",
                argumentName!: String = "",
                writerOperation!: String = "", ownerTargetResourceId!: Int64 = -1,
                instanceOwnerTargetResourceId!: Int64 = -1,
                bindingResourceId!: Int64 = -1, editorKind!: String = "", presetValue!: String = "",
                actionName!: String = "", actionEnabled!: Bool = false, draftText!: String = "",
                draftBoolean!: Bool = false, ownerAvailable!: Bool = true,
                blockedReason!: String = "", projectionText!: String = "",
                projectionSource!: String = "", selectBinding!: ?CjguiSelectFieldBinding = None,
                choiceOptions!: ArrayList<CjguiSelectOption> = ArrayList<CjguiSelectOption>()) {
        this.instanceKey = instanceKey
        this.instanceIncarnation = instanceIncarnation
        this.elementKey = elementKey
        this.role = role
        this.nodeId = nodeId
        this.semanticId = semanticId
        this.label = label
        this.fieldId = fieldId
        this.argumentName = argumentName
        this.writerOperation = writerOperation
        this.ownerTargetResourceId = ownerTargetResourceId
        this.instanceOwnerTargetResourceId = instanceOwnerTargetResourceId
        this.bindingResourceId = bindingResourceId
        this.editorKind = editorKind
        this.presetValue = presetValue
        this.actionName = actionName
        this.actionEnabled = actionEnabled
        this.ownerAvailable = ownerAvailable
        this.blockedReason = blockedReason
        this.draftText = draftText
        this.draftBoolean = draftBoolean
        this.projectionText = projectionText
        this.projectionSource = projectionSource
        this.selectBinding = selectBinding
        this.choiceOptions = ArrayList<CjguiSelectOption>(choiceOptions)
    }

    public func isFieldLike(): Bool {
        return role == CJGUI_COMPOSITE_ELEMENT_FIELD || role == CJGUI_COMPOSITE_ELEMENT_PRESET
    }
}

/// One framework-allocated identity for a template node that is not itself a
/// declared element. It is still an allocated instance slot: the expansion
/// audit accepts it, and a rebuild/reorder maps the SAME template key to the
/// SAME identity.
public class CjguiCompositeAllocatedIdentity {
    public let nodeId: Int64
    public let semanticId: String

    public init(nodeId: Int64, semanticId: String) {
        this.nodeId = nodeId
        this.semanticId = semanticId
    }
}

public interface CjguiCompositeIdentityAllocator {
    func allocate(slot: String): CjguiCompositeAllocatedIdentity
}

/// Everything a factory is allowed to work with. It carries no catalog, no
/// owner and no writer lookup: only resolved values and framework identities.
public class CjguiCompositeBuildContext {
    public let instanceKey: String
    public let properties: HashMap<String, String>
    public let elements: ArrayList<CjguiCompositeElementBinding>
    /// Generated children declared under this instance (empty unless the spec
    /// allows children). They are ordinary rendered nodes; the factory places
    /// them, it does not re-render or re-identify them.
    public let children: ArrayList<CjguiComposableUiNode>
    /// The declared style properties of THIS instance, resolved by the framework
    /// through the same mapping the built-in generated nodes use (size
    /// constraints, growth, alignment, font). A factory applies what it needs to
    /// its own subtree instead of re-parsing the declared strings.
    public let resolvedStyle: CjguiComposableUiStyle
    /// The interaction paint of the SAME named style, resolved by the framework.
    /// A factory that needs hover/pressed/focus paint takes it from here instead
    /// of switching on a theme name or inventing its own state machine.
    public let resolvedInteraction: CjguiComposableUiInteractionStyle
    /// The accepted owner projection for THIS instance, sampled once when the
    /// composite was built. Draft/applied values, field errors, dirty/canApply
    /// and action availability all belong to one owner snapshot; the factory
    /// renders them instead of issuing a second per-field owner read.
    private let ownerFeedback: ?CjguiGeneratedUiFormFeedback
    /// The SAME named-style directory the built-in generated nodes resolve
    /// through. A runtime composition may name a style and receive its current
    /// base/interaction pair without a second style table.
    private let namedStylesValue: ?CjguiComposableUiNamedStyleCatalog
    /// Element bindings keyed by their OCCURRENCE slot (reference path plus
    /// element key), not only by element key. A legal template may reference
    /// one composition twice; each reference needs its own presentation
    /// identity while both keep the same business owner binding.
    private let scopedElementsValue: ?HashMap<String, CjguiCompositeElementBinding>
    /// Allocates one instance-scoped identity for a structural template node.
    /// A factory cannot invent an id; this is the same registry the element
    /// identities come from, and the expansion audit sees the ids.
    private let identityAllocatorValue: ?CjguiCompositeIdentityAllocator
    /// The scope of the REGION this instance is mounted in. A factory that
    /// materialises data-dependent rows must place their caller-declared
    /// identities below it, so the same source can be mounted twice in one
    /// window without sharing an identity table entry.
    private let holderScopeValue: ?CjguiComposableUiIdentityScope
    /// Accepted instance generation for this build. Removed/re-added
    /// instances receive a new generation; a factory uses it only as part of
    /// its own per-mount view-state key, never as a business identity.
    private let instanceIncarnationValue: Int64
    /// True when this build publishes the accepted scene, false for a
    /// candidate. A factory may retire stale mount state only on this signal;
    /// a rejected candidate must leave the accepted mount state untouched.
    private let acceptedBuildValue: Bool
    /// Every composite instance key the accepted structure declares for this
    /// region. A factory that keeps per-mount view state needs the WHOLE set
    /// on an accepted build: an instance that disappeared has no replacement
    /// to build, so only the scene can tell the factory its mount is gone.
    /// None means the caller has no accepted-scene information and the
    /// factory must not retire anything.
    private let acceptedSceneKeysValue: ?HashSet<String>
    /// Stability: experimental (DS51 §12). Identity of the REAL structure holder
    /// this instance is mounted under. A factory that keeps holder-scoped view
    /// state (a collection viewport, virtual-list geometry or reveal target) keys
    /// it with this value: a canonical scope string alone cannot say which
    /// holder a mount belongs to. 0 means the caller built without a holder.
    private let holderIdentityValue: Int64
    /// Stability: experimental (DS51 §12). The holder's OPEN view-state
    /// transaction this build belongs to (0 for a caller that builds without
    /// one). A factory must PREPARE mounts for a nonzero transaction and let the
    /// holder publish/roll them back with the scene it accepts; only a build
    /// outside every transaction may publish immediately (handwritten/direct).
    private let viewStateTransactionValue: Int64

    public init(instanceKey: String, properties: HashMap<String, String>,
                elements: ArrayList<CjguiCompositeElementBinding>,
                children!: ArrayList<CjguiComposableUiNode> = ArrayList<CjguiComposableUiNode>(),
                resolvedStyle!: CjguiComposableUiStyle = CjguiComposableUiStyle(),
                resolvedInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
                ownerFeedback!: ?CjguiGeneratedUiFormFeedback = None,
                namedStyles!: ?CjguiComposableUiNamedStyleCatalog = None,
                scopedElements!: ?HashMap<String, CjguiCompositeElementBinding> = None,
                identityAllocator!: ?CjguiCompositeIdentityAllocator = None,
                holderScope!: ?CjguiComposableUiIdentityScope = None,
                instanceIncarnation!: Int64 = 0, acceptedBuild!: Bool = true,
                acceptedSceneKeys!: ?HashSet<String> = None,
                holderIdentity!: Int64 = 0, viewStateTransaction!: Int64 = 0) {
        this.instanceKey = instanceKey
        this.properties = properties
        this.elements = elements
        this.children = children
        this.resolvedStyle = resolvedStyle
        this.resolvedInteraction = resolvedInteraction
        this.ownerFeedback = ownerFeedback
        this.namedStylesValue = namedStyles
        this.scopedElementsValue = scopedElements
        this.identityAllocatorValue = identityAllocator
        this.holderScopeValue = holderScope
        this.instanceIncarnationValue = instanceIncarnation
        this.acceptedBuildValue = acceptedBuild
        this.acceptedSceneKeysValue = acceptedSceneKeys
        this.holderIdentityValue = holderIdentity
        this.viewStateTransactionValue = viewStateTransaction
    }

    /// Stability: experimental (DS51 §12). The real holder this instance is
    /// mounted under (0 = no holder). See the class field.
    public func holderIdentity(): Int64 {
        return holderIdentityValue
    }

    /// Stability: experimental (DS51 §12). The holder's open view-state
    /// transaction (0 = this build publishes outside a transaction). A factory
    /// must not publish or retire holder-scoped mounts for a nonzero value.
    public func viewStateTransaction(): Int64 {
        return viewStateTransactionValue
    }

    /// Accepted lifecycle generation of THIS instance. A factory that keeps
    /// per-mount view state keys it with this value together with its own
    /// accepted instance key; a re-added instance is a new mount.
    public func instanceIncarnation(): Int64 {
        return instanceIncarnationValue
    }

    /// Whether this build is publishing the accepted scene (false = candidate).
    public func acceptedBuild(): Bool {
        return acceptedBuildValue
    }

    /// Composite instance keys the accepted structure declares for this region.
    /// Only an accepted build carries them; a candidate (or a caller with no
    /// scene) sees None and must not treat absence as removal.
    public func acceptedSceneKeys(): ?HashSet<String> {
        return acceptedSceneKeysValue
    }

    public func holderScope(): ?CjguiComposableUiIdentityScope {
        return holderScopeValue
    }

    public func allocate(slot: String): CjguiCompositeAllocatedIdentity {
        return match (identityAllocatorValue) {
            case Some(allocator) => allocator.allocate(slot)
            case None => CjguiCompositeAllocatedIdentity(-1, "")
        }
    }

    public func namedStyle(name: String): ?CjguiComposableUiNamedStyle {
        if (name.size == 0) { return None }
        return match (namedStylesValue) {
            case Some(catalog) => catalog.forName(name)
            case None => None
        }
    }

    /// This instance's own snapshot, or None when the provider does not
    /// publish per-instance feedback (legacy single owner keeps its separate
    /// formFeedback() projection).
    public func formFeedback(): ?CjguiGeneratedUiFormFeedback {
        return ownerFeedback
    }

    public func property(name: String): String {
        if (let Some(value) <- properties.get(name)) {
            return value
        }
        return ""
    }

    /// Declared INTEGER property, parsed by the framework with the same strict
    /// parser the validator uses, so a builder never re-implements property
    /// parsing (and never quietly accepts a non-numeric value).
    public func propertyInteger(name: String, fallback!: Int64 = 0): Int64 {
        return match (parseGeneratedInteger(property(name))) {
            case Some(value) => value
            case None => fallback
        }
    }

    public func element(elementKey: String): ?CjguiCompositeElementBinding {
        for (element in elements) {
            if (element.elementKey == elementKey) {
                return Some(element)
            }
        }
        return None
    }

    public func elementByRole(role: String): ?CjguiCompositeElementBinding {
        for (element in elements) {
            if (element.role == role) {
                return Some(element)
            }
        }
        return None
    }

    /// The element binding for ONE occurrence (reference path + element key).
    /// The plain `element(key)` stays the single-occurrence accessor; a factory
    /// expanding a nested reference uses this one so two references to the same
    /// declaration mount distinct presentation identities while keeping the SAME
    /// owner/field/writer binding.
    public func elementAt(path: String, elementKey: String): ?CjguiCompositeElementBinding {
        if (let Some(table) <- scopedElementsValue) {
            if (let Some(value) <- table.get(cjguiCompositionElementSlotKey(path, elementKey))) {
                return Some(value)
            }
        }
        return element(elementKey)
    }
}

/// The application's compiled composite implementation. `buildComposite` returns
/// ordinary composable nodes built from the context's allocated identities. It
/// must be total (no business writes, no id invention); the holder validates the
/// returned subtree and fails the candidate closed otherwise.
public interface CjguiCompositeComponentFactory {
    func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode
}

/// Mutable accumulator for the expanded-subtree audit. Kept as a small class
/// because Cangjie has no by-reference scalar parameters.
class CjguiCompositeExpansionAudit {
    var count: Int64 = 0
    var maxDepth: Int64 = 0
    var issue: String = ""
    let seen: HashSet<Int64> = HashSet<Int64>()
    /// The nodes the factory really built, by identity, so the audit can check
    /// that an element's node carries the binding the framework resolved for it.
    let nodesById: HashMap<Int64, CjguiComposableUiNode> = HashMap<Int64, CjguiComposableUiNode>()
    /// Caller-provided children these composites placed: their identities belong
    /// to other instances, so they are legitimate but still budgeted and counted.
    let placedChildren: HashSet<Int64> = HashSet<Int64>()
}

/// Unreachable fallback used only to keep a `match` arm total; `nodeFor` fails
/// closed before ever calling it.
class CjguiCompositeMissingFactory <: CjguiCompositeComponentFactory {
    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
    }
}

/// A control event resolved into a typed intent by the public binding adapter.
/// Consumers dispatch this instead of re-implementing "is this a field change or
/// an action?" per control type, which is what silently dropped a preset button
/// whose field happened to be an INTEGER.
public class CjguiGeneratedUiIntent {
    public let kind: String
    public let nodeKey: String
    public let reason: String
    public let fieldId: String
    public let writerOperation: String
    public let ownerTargetResourceId: Int64
    public let argumentName: String
    public let value: CjguiSharedOperationValue
    public let actionName: String
    /// Accepted composite instance that produced this edit; empty for an
    /// ordinary generated or handwritten field. The owner route uses this
    /// identity instead of a global "current object" switch.
    public let instanceKey: String
    /// Accepted element identity the event was resolved through. The action
    /// dispatcher re-checks this full binding before the owner transaction,
    /// then hands the ORIGINAL target and generation to the provider. It is
    /// never re-resolved from the mutable instance-key mapping at execution.
    public let nodeId: Int64
    public let instanceIncarnation: Int64
    /// Caret/selection carried by the original field-change event. -1 means the
    /// producer did not publish one; a whole-value owner write then applies the
    /// text without claiming a caret position.
    public let selectionStart: Int64
    public let selectionEnd: Int64

    public init(kind: String, nodeKey: String, reason: String, fieldId!: String = "",
                writerOperation!: String = "", ownerTargetResourceId!: Int64 = -1,
                argumentName!: String = "", value!: CjguiSharedOperationValue =
                    CjguiSharedOperationValue.string(""), actionName!: String = "",
                instanceKey!: String = "", nodeId!: Int64 = -1, instanceIncarnation!: Int64 = 0,
                selectionStart!: Int64 = -1, selectionEnd!: Int64 = -1) {
        this.kind = kind
        this.nodeKey = nodeKey
        this.reason = reason
        this.fieldId = fieldId
        this.writerOperation = writerOperation
        this.ownerTargetResourceId = ownerTargetResourceId
        this.argumentName = argumentName
        this.value = value
        this.actionName = actionName
        this.instanceKey = instanceKey
        this.nodeId = nodeId
        this.instanceIncarnation = instanceIncarnation
        this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd
    }

    public static func none(reason: String): CjguiGeneratedUiIntent {
        return CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_NONE, "", reason)
    }

    public func isFieldEdit(): Bool {
        return kind == CJGUI_GENERATED_INTENT_FIELD_EDIT
    }

    public func isAction(): Bool {
        return kind == CJGUI_GENERATED_INTENT_ACTION
    }
}

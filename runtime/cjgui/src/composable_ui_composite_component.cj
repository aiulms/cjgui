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
public let CJGUI_COMPOSITE_ELEMENT_CONTAINER: String = "container"
public let CJGUI_COMPOSITE_ELEMENT_FIELD: String = "field"
public let CJGUI_COMPOSITE_ELEMENT_PRESET: String = "preset"
public let CJGUI_COMPOSITE_ELEMENT_ACTION: String = "action"

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
    /// Declared caption (empty = the action's own label / the field's label).
    public let label: String
    /// Parent element key ("" = the instance root).
    public let parentKey: String

    public init(elementKey: String, role: String, fieldId!: String = "", argumentName!: String = "",
                presetValue!: String = "", actionName!: String = "", label!: String = "",
                parentKey!: String = "") {
        this.elementKey = elementKey
        this.role = role
        this.fieldId = fieldId
        this.argumentName = argumentName
        this.presetValue = presetValue
        this.actionName = actionName
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
    public let elementKey: String
    public let role: String
    public let nodeId: Int64
    public let semanticId: String
    public let label: String
    /// role field/preset: the shared field and the resolved owner writer.
    public let fieldId: String
    public let writerOperation: String
    public let ownerTargetResourceId: Int64
    public let bindingResourceId: Int64
    public let editorKind: String
    public let presetValue: String
    /// role action: the declared action and whether the owner currently allows it.
    public let actionName: String
    public let actionEnabled: Bool
    /// Live declared value, read through the provider exactly like the
    /// handwritten form (a legally empty draft stays an empty draft).
    public let draftText: String
    public let draftBoolean: Bool

    public init(elementKey: String, role: String, nodeId: Int64, semanticId: String, label: String,
                fieldId!: String = "", writerOperation!: String = "", ownerTargetResourceId!: Int64 = -1,
                bindingResourceId!: Int64 = -1, editorKind!: String = "", presetValue!: String = "",
                actionName!: String = "", actionEnabled!: Bool = false, draftText!: String = "",
                draftBoolean!: Bool = false) {
        this.elementKey = elementKey
        this.role = role
        this.nodeId = nodeId
        this.semanticId = semanticId
        this.label = label
        this.fieldId = fieldId
        this.writerOperation = writerOperation
        this.ownerTargetResourceId = ownerTargetResourceId
        this.bindingResourceId = bindingResourceId
        this.editorKind = editorKind
        this.presetValue = presetValue
        this.actionName = actionName
        this.actionEnabled = actionEnabled
        this.draftText = draftText
        this.draftBoolean = draftBoolean
    }

    public func isFieldLike(): Bool {
        return role == CJGUI_COMPOSITE_ELEMENT_FIELD || role == CJGUI_COMPOSITE_ELEMENT_PRESET
    }
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

    public init(instanceKey: String, properties: HashMap<String, String>,
                elements: ArrayList<CjguiCompositeElementBinding>,
                children!: ArrayList<CjguiComposableUiNode> = ArrayList<CjguiComposableUiNode>()) {
        this.instanceKey = instanceKey
        this.properties = properties
        this.elements = elements
        this.children = children
    }

    public func property(name: String): String {
        if (let Some(value) <- properties.get(name)) {
            return value
        }
        return ""
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

    public init(kind: String, nodeKey: String, reason: String, fieldId!: String = "",
                writerOperation!: String = "", ownerTargetResourceId!: Int64 = -1,
                argumentName!: String = "", value!: CjguiSharedOperationValue =
                    CjguiSharedOperationValue.string(""), actionName!: String = "") {
        this.kind = kind
        this.nodeKey = nodeKey
        this.reason = reason
        this.fieldId = fieldId
        this.writerOperation = writerOperation
        this.ownerTargetResourceId = ownerTargetResourceId
        this.argumentName = argumentName
        this.value = value
        this.actionName = actionName
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

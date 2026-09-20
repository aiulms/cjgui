// Experimental runtime-generated UI: a typed capability catalog, a validated
// structure value model, a single structure holder and an expansion path that
// reuses the ordinary component/layout/scene acceptance chain.
//
// Ownership: the application owns business fields, drafts and actions and
// exposes them through CjguiGeneratedUiBindingProvider; this module owns only
// the accepted structure description, its version and the node identity
// allocation for accepted keys. Generated descriptions never carry writable
// business data, source code, native handles or new permissions.
package cjgui

import std.env.*

import std.collection.*
import cjgui_shared_operation_core.*

/// One application field as seen by generated UI. It is *derived* from the
/// application's existing shared form binding, so the handwritten form, the
/// public description and the generated editor all read one definition
/// instead of three hand-maintained lists. `writeActionName` is the framework
/// operation a generated editor must use for this field; it is derived here,
/// in one place, from the form editor kind - consumers never switch on field
/// names or hardcode `EDIT_DRAFT_TEXT`/`EDIT_DRAFT_BOOLEAN`.
public class CjguiGeneratedUiFieldSpec {
    public let fieldId: String
    public let label: String
    public let editorKind: String       // "TEXT" | "INTEGER" | "BOOLEAN"
    public let resourceId: Int64
    public let writeActionName: String  // "" when the framework has no writer
    public let minimum: Int64
    public let maximum: Int64
    public let required: Bool           // declared by the application's binding

    /// `writeActionName` may be given explicitly by an application whose owner
    /// writes immediately (for example SET_TITLE) instead of through the
    /// shared draft operations. It is still a single declared value, so no
    /// consumer re-derives the writer from a field name.
    public init(fieldId: String, label: String, editorKind: String, resourceId: Int64,
                minimum!: Int64 = 0, maximum!: Int64 = 0, writeActionName!: String = "",
                required!: Bool = false) {
        this.fieldId = fieldId
        this.label = label
        this.editorKind = editorKind
        this.resourceId = resourceId
        this.writeActionName = if (writeActionName.size > 0) {
            writeActionName
        } else {
            CjguiGeneratedUiFieldSpec.writeActionForEditorKind(editorKind)
        }
        this.minimum = minimum
        this.maximum = maximum
        this.required = required
    }

    /// The single place that maps a shared-form editor kind to the framework
    /// draft write operation. An unknown kind has no writer, and an editor
    /// bound to it is rejected instead of silently writing the wrong field.
    public static func writeActionForEditorKind(editorKind: String): String {
        if (editorKind == "BOOLEAN") {
            return "EDIT_DRAFT_BOOLEAN"
        }
        if (editorKind == "TEXT" || editorKind == "INTEGER") {
            return "EDIT_DRAFT_TEXT"
        }
        return ""
    }

    /// The generated input kind that presents this editor kind.
    public func inputKind(): String {
        if (editorKind == "BOOLEAN") {
            return "booleanInput"
        }
        if (editorKind == "INTEGER") {
            return "integerInput"
        }
        if (editorKind == "TEXT") {
            return "textInput"
        }
        return ""
    }

    public func isWritable(): Bool {
        return writeActionName.size > 0
    }

    /// The human event kind that carries a change for this editor kind. The
    /// native bridge reports a toggled boolean as a *boolean change* (kind 29,
    /// with the projected next value in `text`) and an edited text/integer
    /// projection as a text change (kind 28) - never as a bare activation.
    /// Publishing this beside `writeActionForEditorKind` keeps the contract in
    /// one definition: a consumer asks its field what a change looks like
    /// instead of hardcoding kinds and silently dropping real input when the
    /// framework reports a different one.
    public func changeEventKind(): Int64 {
        if (editorKind == "BOOLEAN") {
            return CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED
        }
        return CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED
    }

    /// Whether `eventKind` is a change for this editor kind. Anything else
    /// (focus, scroll, activation) must not be turned into a field write.
    public func acceptsChangeEventKind(eventKind: Int64): Bool {
        return eventKind == changeEventKind()
    }

    /// Derives the generation-side field definition from the application's
    /// shared form binding. The binding stays the only authored definition.
    public static func fromFormBinding(binding: CjguiSharedFormBinding): ArrayList<CjguiGeneratedUiFieldSpec> {
        let result = ArrayList<CjguiGeneratedUiFieldSpec>()
        for (descriptor in binding.allFields()) {
            // The declared business constraints travel with the field: the
            // generated spec (and therefore the validator and the external
            // capability description) enforces and publishes exactly what the
            // application declared in its one binding.
            result.add(CjguiGeneratedUiFieldSpec(descriptor.fieldId, descriptor.label,
                descriptor.editorKind, descriptor.resourceId, minimum: descriptor.minimum,
                maximum: descriptor.maximum, required: descriptor.required))
        }
        return result
    }
}

/// Hard upper bound on the number of component instances one generated
/// structure may mount. It is a real framework limit (the per-controller
/// component registry), so the validator enforces it as an explicit rejection
/// instead of letting the render fail later with an internal capacity issue.
public let CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY: Int64 = 64

/// One property an application-registered component accepts.
public class CjguiGeneratedUiPropertySpec {
    public let name: String
    public let valueType: String      // "STRING" | "INTEGER" | "BOOLEAN"
    public let required: Bool
    public let minimum: Int64
    public let maximum: Int64
    public let maxLength: Int64

    public init(name: String, valueType: String, required!: Bool = false,
                minimum!: Int64 = 0, maximum!: Int64 = 0, maxLength!: Int64 = 0) {
        this.name = name
        this.valueType = valueType
        this.required = required
        this.minimum = minimum
        this.maximum = maximum
        this.maxLength = maxLength
    }
}

/// Typed presentation an application-registered component kind maps onto. The
/// framework implements exactly these presentations with existing components
/// and layout; a kind that declares anything else is rejected when it is
/// registered, so a registered-but-unimplemented component can never silently
/// degrade into a label.
public let CJGUI_GENERATED_PRESENTATION_VERTICAL: String = "CONTAINER_VERTICAL"
public let CJGUI_GENERATED_PRESENTATION_HORIZONTAL: String = "CONTAINER_HORIZONTAL"
public let CJGUI_GENERATED_PRESENTATION_LABEL: String = "LABEL"
public let CJGUI_GENERATED_PRESENTATION_ACTION: String = "ACTION_BUTTON"

public class CjguiGeneratedUiPresentation {
    public static func isImplemented(presentation: String): Bool {
        return presentation == CJGUI_GENERATED_PRESENTATION_VERTICAL ||
            presentation == CJGUI_GENERATED_PRESENTATION_HORIZONTAL ||
            presentation == CJGUI_GENERATED_PRESENTATION_LABEL ||
            presentation == CJGUI_GENERATED_PRESENTATION_ACTION ||
            presentation == "FIELD_TEXT" || presentation == "FIELD_INTEGER" ||
            presentation == "FIELD_BOOLEAN"
    }

    /// Presentation inferred from a built-in kind. An application kind must
    /// declare its presentation explicitly.
    public static func forBuiltInKind(kind: String): String {
        if (kind == "vertical") {
            return CJGUI_GENERATED_PRESENTATION_VERTICAL
        }
        if (kind == "horizontal") {
            return CJGUI_GENERATED_PRESENTATION_HORIZONTAL
        }
        if (kind == "label") {
            return CJGUI_GENERATED_PRESENTATION_LABEL
        }
        if (kind == "action") {
            return CJGUI_GENERATED_PRESENTATION_ACTION
        }
        if (kind == "textInput") {
            return "FIELD_TEXT"
        }
        if (kind == "integerInput") {
            return "FIELD_INTEGER"
        }
        if (kind == "booleanInput") {
            return "FIELD_BOOLEAN"
        }
        return ""
    }

    /// The properties each presentation actually reads. A registered property
    /// that no presentation consumes is rejected, so a declared attribute
    /// cannot pass validation and then be ignored by the renderer.
    public static func isPropertyImplemented(presentation: String, name: String, valueType: String): Bool {
        if (presentation == CJGUI_GENERATED_PRESENTATION_VERTICAL ||
            presentation == CJGUI_GENERATED_PRESENTATION_HORIZONTAL) {
            return (name == "gap" || name == "padding") && valueType == "INTEGER"
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_LABEL) {
            return name == "text" && valueType == "STRING"
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_ACTION) {
            // `label` is the button caption; `action` is the declared action
            // name the validator checks against the node's own binding.
            return (name == "label" || name == "action") && valueType == "STRING"
        }
        if (presentation == "FIELD_TEXT" || presentation == "FIELD_INTEGER" ||
            presentation == "FIELD_BOOLEAN") {
            return name == "label" && valueType == "STRING"
        }
        return false
    }

    /// The field editor kind a field presentation requires ("TEXT", "INTEGER",
    /// "BOOLEAN"), or "" when the presentation is not a field presentation.
    public static func requiredEditorKind(presentation: String): String {
        if (presentation == "FIELD_TEXT") {
            return "TEXT"
        }
        if (presentation == "FIELD_INTEGER") {
            return "INTEGER"
        }
        if (presentation == "FIELD_BOOLEAN") {
            return "BOOLEAN"
        }
        return ""
    }
}

/// One component kind the current application registers as generatable.
public class CjguiGeneratedUiComponentSpec {
    public let kind: String
    public let properties: ArrayList<CjguiGeneratedUiPropertySpec>
    public let allowsChildren: Bool
    public let childLimit: Int64
    /// Typed presentation this kind is drawn with. Empty for an unknown custom
    /// kind (which registration rejects).
    public let presentation: String

    public init(kind: String, properties: ArrayList<CjguiGeneratedUiPropertySpec>,
                allowsChildren: Bool, childLimit!: Int64 = 0, presentation!: String = "") {
        this.kind = kind
        this.properties = properties
        this.allowsChildren = allowsChildren
        this.childLimit = childLimit
        let declared = if (presentation.size > 0) {
            presentation
        } else {
            CjguiGeneratedUiPresentation.forBuiltInKind(kind)
        }
        this.presentation = declared
    }

    public func isImplemented(): Bool {
        return CjguiGeneratedUiPresentation.isImplemented(presentation)
    }
}

/// One business action the application exposes to generated buttons.
public class CjguiGeneratedUiActionSpec {
    public let name: String
    public let label: String
    public let parameterNames: ArrayList<String>

    public init(name: String, label: String, parameterNames!: ArrayList<String> = ArrayList<String>()) {
        this.name = name
        this.label = label
        this.parameterNames = parameterNames
    }
}

/// Typed capability catalog. The application registers what generated
/// structures may use; the query result is what an external client reads
/// before submitting a candidate.
public class CjguiGeneratedUiCapabilityCatalog {
    private let components: ArrayList<CjguiGeneratedUiComponentSpec>
    private let actions: ArrayList<CjguiGeneratedUiActionSpec>
    private let fields: ArrayList<CjguiGeneratedUiFieldSpec>
    public let maxDepth: Int64
    public let maxNodes: Int64
    public let maxPropertiesPerNode: Int64
    public let maxStringLength: Int64

    public init(maxDepth!: Int64 = 12, maxNodes!: Int64 = 512, maxPropertiesPerNode!: Int64 = 8,
                maxStringLength!: Int64 = 256) {
        this.components = ArrayList<CjguiGeneratedUiComponentSpec>()
        this.actions = ArrayList<CjguiGeneratedUiActionSpec>()
        this.fields = ArrayList<CjguiGeneratedUiFieldSpec>()
        this.maxDepth = maxDepth
        // The declared node bound can never exceed what the framework can
        // actually mount: one component instance per node, capped by the
        // per-controller registry. Reporting a larger bound would advertise a
        // structure size that can only fail later.
        this.maxNodes = if (maxNodes > CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY) {
            CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY
        } else {
            maxNodes
        }
        this.maxPropertiesPerNode = maxPropertiesPerNode
        this.maxStringLength = maxStringLength
    }

    /// Registers one component kind. A kind whose presentation is not
    /// implemented, or whose declared layout properties do not map onto a real
    /// layout attribute, is rejected here - registration itself is the
    /// guarantee that a generated node can actually be presented.
    public func registerComponent(spec: CjguiGeneratedUiComponentSpec): Bool {
        if (spec.kind.size == 0 || !spec.isImplemented()) {
            lastRegistrationIssue = "component_presentation_not_implemented:${spec.kind}"
            return false
        }
        if (let Some(_) <- componentFor(spec.kind)) {
            lastRegistrationIssue = "duplicate_component_kind:${spec.kind}"
            return false
        }
        if (!spec.allowsChildren && spec.childLimit > 0) {
            lastRegistrationIssue = "child_limit_without_children:${spec.kind}"
            return false
        }
        for (property in spec.properties) {
            if (property.valueType != "STRING" && property.valueType != "INTEGER" &&
                property.valueType != "BOOLEAN") {
                lastRegistrationIssue = "unknown_property_type:${spec.kind}:${property.name}"
                return false
            }
            if (!CjguiGeneratedUiPresentation.isPropertyImplemented(spec.presentation, property.name,
                property.valueType)) {
                lastRegistrationIssue = "property_not_implemented:${spec.kind}:${property.name}"
                return false
            }
        }
        components.add(spec)
        lastRegistrationIssue = ""
        return true
    }

    public func registerAction(spec: CjguiGeneratedUiActionSpec): Bool {
        if (spec.name.size == 0) {
            lastRegistrationIssue = "empty_action_name"
            return false
        }
        if (let Some(_) <- actionFor(spec.name)) {
            lastRegistrationIssue = "duplicate_action:${spec.name}"
            return false
        }
        actions.add(spec)
        lastRegistrationIssue = ""
        return true
    }

    /// Registers one application field from its derived definition. Callers
    /// build these from their existing form binding
    /// (CjguiGeneratedUiFieldSpec.fromFormBinding), so there is exactly one
    /// authored field list.
    public func registerField(spec: CjguiGeneratedUiFieldSpec): Bool {
        let existing = fieldFor(spec.fieldId)
        if (let Some(_) <- existing) {
            lastRegistrationIssue = "duplicate_field:${spec.fieldId}"
            return false
        }
        if (spec.resourceId <= 0) {
            lastRegistrationIssue = "field_without_resource:${spec.fieldId}"
            return false
        }
        fields.add(spec)
        lastRegistrationIssue = ""
        return true
    }

    /// Registers several derived field definitions at once (one definition per
    /// application form binding).
    public func registerFields(specs: ArrayList<CjguiGeneratedUiFieldSpec>): Bool {
        for (spec in specs) {
            if (!registerField(spec)) {
                return false
            }
        }
        return true
    }

    private var lastRegistrationIssue: String = ""

    /// Reason text of the most recent rejected registration ("" when the last
    /// registration succeeded).
    public func lastRegistrationRejection(): String {
        return lastRegistrationIssue
    }

    public func componentFor(kind: String): ?CjguiGeneratedUiComponentSpec {
        for (spec in components) {
            if (spec.kind == kind) {
                return Some(spec)
            }
        }
        return None
    }

    public func actionFor(name: String): ?CjguiGeneratedUiActionSpec {
        for (spec in actions) {
            if (spec.name == name) {
                return Some(spec)
            }
        }
        return None
    }

    public func fieldFor(fieldId: String): ?CjguiGeneratedUiFieldSpec {
        for (field in fields) {
            if (field.fieldId == fieldId) {
                return Some(field)
            }
        }
        return None
    }

    public func hasField(fieldId: String): Bool {
        return fieldFor(fieldId).isSome()
    }

    public func componentKinds(): ArrayList<String> {
        let result = ArrayList<String>()
        for (spec in components) {
            result.add(spec.kind)
        }
        return result
    }

    public func actionNames(): ArrayList<String> {
        let result = ArrayList<String>()
        for (spec in actions) {
            result.add(spec.name)
        }
        return result
    }

    public func fieldIds(): ArrayList<String> {
        let result = ArrayList<String>()
        for (field in fields) {
            result.add(field.fieldId)
        }
        return result
    }

    public func fieldSpecs(): ArrayList<CjguiGeneratedUiFieldSpec> {
        return ArrayList<CjguiGeneratedUiFieldSpec>(fields)
    }
}

/// Structure value model: one node of a candidate description.
public class CjguiGeneratedUiNodeSpec {
    public let key: String
    public let kind: String
    public let properties: HashMap<String, String>
    public let fieldId: String
    public let actionName: String
    public let children: ArrayList<CjguiGeneratedUiNodeSpec>

    public init(key: String, kind: String,
                properties!: HashMap<String, String> = HashMap<String, String>(),
                fieldId!: String = "", actionName!: String = "",
                children!: ArrayList<CjguiGeneratedUiNodeSpec> = ArrayList<CjguiGeneratedUiNodeSpec>()) {
        this.key = key
        this.kind = kind
        this.properties = properties
        this.fieldId = fieldId
        this.actionName = actionName
        this.children = children
    }

    public func property(name: String): String {
        if (let Some(value) <- properties.get(name)) {
            return value
        }
        return ""
    }
}

/// Validation outcome with the specific position and reason.
public class CjguiGeneratedUiValidation {
    public let accepted: Bool
    public let reason: String
    public let path: String

    public init(accepted: Bool, reason: String, path: String) {
        this.accepted = accepted
        this.reason = reason
        this.path = path
    }

    public static func ok(): CjguiGeneratedUiValidation {
        return CjguiGeneratedUiValidation(true, "", "")
    }

    public static func reject(reason: String, path: String): CjguiGeneratedUiValidation {
        return CjguiGeneratedUiValidation(false, reason, path)
    }
}

/// Validates a candidate description against the catalog and the size bounds.
public class CjguiGeneratedUiValidator {
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    // Nodes visited in the current validation walk. The counter lives on the
    // validator (reset per validate call) because the tree walk must count
    // every node once, not only the current path.
    private var nodesSeen: Int64

    public init(catalog: CjguiGeneratedUiCapabilityCatalog) {
        this.catalog = catalog
        this.nodesSeen = 0
    }

    public func validate(root: CjguiGeneratedUiNodeSpec): CjguiGeneratedUiValidation {
        let seen = HashSet<String>()
        nodesSeen = 0
        return validateNode(root, "root", 0, seen)
    }

    private func validateNode(node: CjguiGeneratedUiNodeSpec, path: String, depth: Int64,
                              seen: HashSet<String>): CjguiGeneratedUiValidation {
        if (depth > catalog.maxDepth) {
            return CjguiGeneratedUiValidation.reject("max_depth_exceeded", path)
        }
        nodesSeen += 1
        if (nodesSeen > catalog.maxNodes) {
            return CjguiGeneratedUiValidation.reject("max_nodes_exceeded", path)
        }
        if (nodesSeen > CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY) {
            // The framework's component registry caps one generated structure
            // at this many live instances; declaring it here keeps the failure
            // at validation time with a specific reason.
            return CjguiGeneratedUiValidation.reject("component_instance_capacity", path)
        }
        if (node.key.size == 0) {
            return CjguiGeneratedUiValidation.reject("empty_key", path)
        }
        if (seen.contains(node.key)) {
            return CjguiGeneratedUiValidation.reject("duplicate_key", "${path}/${node.key}")
        }
        seen.add(node.key)
        if (let Some(spec) <- catalog.componentFor(node.kind)) {
            if (!spec.isImplemented()) {
                return CjguiGeneratedUiValidation.reject("component_not_implemented", "${path}/${node.key}")
            }
            if (node.properties.size > catalog.maxPropertiesPerNode) {
                return CjguiGeneratedUiValidation.reject("too_many_properties", "${path}/${node.key}")
            }
            for ((name, value) in node.properties) {
                if (let Some(property) <- propertySpec(spec, name)) {
                    let rejected = validatePropertyValue(property, value, "${path}/${node.key}/${name}")
                    if (let Some(reason) <- rejected) {
                        return CjguiGeneratedUiValidation.reject(reason, "${path}/${node.key}/${name}")
                    }
                } else {
                    return CjguiGeneratedUiValidation.reject("unknown_property", "${path}/${node.key}/${name}")
                }
            }
            // Required properties must actually be present; an omitted required
            // attribute is not the same as an empty value.
            for (property in spec.properties) {
                if (property.required && !node.properties.contains(property.name)) {
                    return CjguiGeneratedUiValidation.reject("missing_required_property",
                        "${path}/${node.key}/${property.name}")
                }
            }
            let bindingIssue = validateBinding(node, spec, path)
            if (let Some(reason) <- bindingIssue) {
                return CjguiGeneratedUiValidation.reject(reason, "${path}/${node.key}")
            }
            if (!spec.allowsChildren && node.children.size > 0) {
                return CjguiGeneratedUiValidation.reject("children_not_allowed", "${path}/${node.key}")
            }
            if (spec.childLimit > 0 && node.children.size > spec.childLimit) {
                return CjguiGeneratedUiValidation.reject("child_limit_exceeded", "${path}/${node.key}")
            }
        } else {
            return CjguiGeneratedUiValidation.reject("unknown_component", "${path}/${node.key}")
        }
        var index: Int64 = 0
        while (index < node.children.size) {
            let result = validateNode(node.children[index], "${path}/${node.key}", depth + 1, seen)
            if (!result.accepted) {
                return result
            }
            index += 1
        }
        return CjguiGeneratedUiValidation.ok()
    }

    private func propertySpec(spec: CjguiGeneratedUiComponentSpec,
                              name: String): ?CjguiGeneratedUiPropertySpec {
        for (property in spec.properties) {
            if (property.name == name) {
                return Some(property)
            }
        }
        return None
    }

    /// Enforces the declared property value type and numeric range. A declared
    /// type is a contract: a non-numeric value for an INTEGER property or an
    /// out-of-range number is rejected with its own reason instead of being
    /// forwarded to the renderer as text.
    private func validatePropertyValue(property: CjguiGeneratedUiPropertySpec, value: String,
                                       path: String): ?String {
        if (property.valueType == "STRING") {
            if (property.maxLength > 0 && value.size > property.maxLength) {
                return "property_too_long"
            }
            return None
        }
        if (property.valueType == "BOOLEAN") {
            if (value != "true" && value != "false") {
                return "property_not_boolean"
            }
            return None
        }
        if (property.valueType == "INTEGER") {
            let parsed = parseGeneratedInteger(value)
            if (let None <- parsed) {
                return "property_not_integer"
            }
            let number = match (parsed) {
                case Some(number) => number
                case None => 0
            }
            if (property.maximum > property.minimum) {
                if (number < property.minimum || number > property.maximum) {
                    return "property_out_of_range"
                }
            }
            return None
        }
        return "unknown_property_type"
    }

    /// Field/control compatibility: a field presentation is only valid with a
    /// registered field of the matching editor kind, an action node must
    /// reference a registered action, and a structural node must not carry a
    /// field or action binding at all.
    private func validateBinding(node: CjguiGeneratedUiNodeSpec, spec: CjguiGeneratedUiComponentSpec,
                                 path: String): ?String {
        let requiredEditor = CjguiGeneratedUiPresentation.requiredEditorKind(spec.presentation)
        if (requiredEditor.size > 0) {
            if (node.fieldId.isEmpty()) {
                return "field_binding_required"
            }
            let field = match (catalog.fieldFor(node.fieldId)) {
                case Some(value) => value
                case None => return "unknown_field"
            }
            if (field.editorKind != requiredEditor) {
                return "field_editor_kind_mismatch"
            }
            return None
        }
        if (spec.presentation == CJGUI_GENERATED_PRESENTATION_ACTION) {
            if (node.actionName.isEmpty()) {
                return "action_binding_required"
            }
            if (let None <- catalog.actionFor(node.actionName)) {
                return "unknown_action"
            }
            let declared = node.property("action")
            if (declared.size > 0 && declared != node.actionName) {
                return "action_property_mismatch"
            }
            return None
        }
        if (!node.fieldId.isEmpty()) {
            return "field_not_allowed"
        }
        if (!node.actionName.isEmpty()) {
            return "action_not_allowed"
        }
        return None
    }
}

/// Parses one generation-side integer property value. Returns None for
/// anything that is not a plain optionally-signed decimal integer, so a
/// declared INTEGER contract is enforced instead of silently becoming text.
func parseGeneratedInteger(value: String): ?Int64 {
    if (value.size == 0) {
        return None
    }
    var result: Int64 = 0
    var negative = false
    var index = 0
    for (byte in value.toArray()) {
        if (index == 0 && byte == 45) {
            negative = true
            index += 1
            continue
        }
        if (byte < 48 || byte > 57) {
            return None
        }
        result = result * 10 + Int64(byte - 48)
        index += 1
    }
    return Some(if (negative) { -result } else { result })
}

/// Application-owned bindings for generated fields and actions. Implementors
/// read live business state; the generated description never stores values.
public interface CjguiGeneratedUiBindingProvider {
    /// The shared field resource id for a field id, so a generated input
    /// references exactly the same field the handwritten form binds. Returns
    /// a negative value when the field is unknown.
    func fieldResourceId(fieldId: String): Int64
    /// The business owner target the field currently edits (for example the
    /// selected record id). A negative value means the field is not editable
    /// right now, and the generated input must not accept text.
    func fieldOperationResourceId(fieldId: String): Int64
    /// Draft text for a field ("", when the field has no text value).
    func draftText(fieldId: String): String
    /// Applied text for a field.
    func appliedText(fieldId: String): String
    /// Draft boolean value and whether the field is a boolean field.
    func draftBoolean(fieldId: String): ?Bool
    /// Executes an application action; returns the human-readable outcome and
    /// whether the domain applied it.
    func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult
    /// Whether the action is currently executable.
    func actionAvailable(actionName: String): Bool
}

public class CjguiGeneratedUiActionResult {
    public let applied: Bool
    public let reason: String

    public init(applied: Bool, reason: String) {
        this.applied = applied
        this.reason = reason
    }
}

/// Public submission outcome. Candidate acceptance is deliberately separate
/// from scene acceptance: a candidate may be validated, rendered and prepared
/// while the window has not yet accepted the scene that contains it. The
/// accepted structure version only advances when the scene is accepted, and
/// the caller can distinguish the two states.
public class CjguiGeneratedUiSubmitResult {
    public let candidateAccepted: Bool
    public let sceneAccepted: Bool
    public let reason: String
    public let path: String
    public let structureVersionBefore: Int64
    public let structureVersionAfter: Int64
    public let candidateVersion: Int64

    public init(candidateAccepted: Bool, sceneAccepted: Bool, reason: String, path: String,
                structureVersionBefore: Int64, structureVersionAfter: Int64,
                candidateVersion!: Int64 = 0) {
        this.candidateAccepted = candidateAccepted
        this.sceneAccepted = sceneAccepted
        this.reason = reason
        this.path = path
        this.structureVersionBefore = structureVersionBefore
        this.structureVersionAfter = structureVersionAfter
        this.candidateVersion = candidateVersion
    }
}

/// Render outcome for one candidate expansion.
class CjguiGeneratedUiRendered {
    let ok: Bool
    let reason: String
    let path: String
    let node: CjguiComposableUiNode

    init(ok: Bool, reason: String, path: String, node: CjguiComposableUiNode) {
        this.ok = ok
        this.reason = reason
        this.path = path
        this.node = node
    }
}

/// The single structure holder:/// owns the accepted description and its
/// version, allocates stable node identities per accepted key, and renders the
/// accepted structure through ordinary component builders. Business fields and
/// drafts remain with the application provider.
public class CjguiGeneratedUiStructureHolder {
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    private let validator: CjguiGeneratedUiValidator
    private let registry: CjguiComposableUiComponentRegistry
    private let rootScope: CjguiComposableUiIdentityScope
    // Accepted (scene-committed) structure and identity table. Only the
    // commit hook below advances these.
    private var accepted: ?CjguiGeneratedUiNodeSpec
    private var acceptedVersion: Int64
    // Candidate received from an external submission, prepared but not yet
    // scene-accepted. It never becomes visible through the accepted reads.
    private var candidate: ?CjguiGeneratedUiNodeSpec
    private var candidateVersion: Int64
    private var candidatePrepared: Bool
    private var lastReason: String
    private var lastSceneOutcomeValue: String
    private var renderFailureReason: String
    private var renderFailurePath: String
    // Node identity -> accepted stable key, rebuilt on every expansion so an
    // event can only resolve to the currently accepted object.
    private var nodeIdToKey: HashMap<Int64, String>
    // Candidate identity table, published only by the commit hook.
    private var candidateNodeIdToKey: HashMap<Int64, String>

    public init(catalog: CjguiGeneratedUiCapabilityCatalog,
                rootScope!: CjguiComposableUiIdentityScope = CjguiComposableUiIdentityScope("generated-root")) {
        this.catalog = catalog
        this.validator = CjguiGeneratedUiValidator(catalog)
        this.registry = CjguiComposableUiComponentRegistry()
        this.rootScope = rootScope
        this.accepted = None
        this.acceptedVersion = 0
        this.candidate = None
        this.candidateVersion = 0
        this.candidatePrepared = false
        this.lastReason = ""
        this.lastSceneOutcomeValue = ""
        this.renderFailureReason = ""
        this.renderFailurePath = ""
        this.nodeIdToKey = HashMap<Int64, String>()
        this.candidateNodeIdToKey = HashMap<Int64, String>()
    }

    /// Scene-accepted structure version. It advances only when the window
    /// committed the candidate, so an external reader can never observe a
    /// structure that the scene has not accepted.
    public func structureVersion(): Int64 {
        return acceptedVersion
    }

    public func acceptedStructure(): ?CjguiGeneratedUiNodeSpec {
        return accepted
    }

    /// Version the pending candidate would install (0 when none is pending).
    public func candidateStructureVersion(): Int64 {
        return candidateVersion
    }

    /// True while a validated candidate is prepared and waiting for the
    /// window's scene acceptance.
    public func hasPendingCandidate(): Bool {
        return !candidate.isNone()
    }

    /// "scene_accepted", "scene_rejected:<reason>", or "" before any commit.
    public func lastSceneOutcome(): String {
        return lastSceneOutcomeValue
    }

    public func lastRejection(): String {
        return lastReason
    }

    /// Reason text of the most recent rejected candidate ("" when the last
    /// submission was accepted).
    public func rejectedReason(): String {
        return lastReason
    }

    /// Registry issue text from the last expansion (test/diagnostic surface).
    public func lastIssue(): String {
        return registry.lastIssue()
    }

    /// Validates the candidate and records it as pending, but does NOT publish
    /// it: the accepted structure, its version and the event identity table
    /// stay exactly as they were until the window commits the candidate in the
    /// same transaction that accepts the scene. Rendering happens inside that
    /// transaction, so a candidate that cannot be built is rejected at scene
    /// time without ever destroying an accepted instance.
    public func submit(candidate: CjguiGeneratedUiNodeSpec,
                       provider: CjguiGeneratedUiBindingProvider): CjguiGeneratedUiSubmitResult {
        let before = acceptedVersion
        let validation = validator.validate(candidate)
        if (!validation.accepted) {
            lastReason = validation.reason
            return CjguiGeneratedUiSubmitResult(false, false, validation.reason, validation.path, before, before,
                candidateVersion: candidateVersion)
        }
        // Superseding an uncommitted candidate is legal: the previous one was
        // never published, so only its (unaccepted) identities are dropped.
        if (!this.candidate.isNone()) {
            registry.rollbackTransaction()
        }
        this.candidate = Some(candidate)
        this.candidateVersion = before + 1
        this.candidatePrepared = false
        this.lastReason = ""
        return CjguiGeneratedUiSubmitResult(true, false, "", "", before, before,
            candidateVersion: candidateVersion)
    }

    /// Opens the component-identity transaction for the pending candidate.
    /// Called from the window's begin-scene-refresh hook, before the scene is
    /// built; it publishes nothing.
    public func beginCandidateRefresh(): Bool {
        if (candidate.isNone()) {
            return true
        }
        if (!registry.beginTransaction()) {
            lastSceneOutcomeValue = "scene_rejected:${registry.lastIssue()}"
            return false
        }
        candidatePrepared = false
        lastSceneOutcomeValue = "scene_pending"
        return true
    }

    /// Builds the tree for the refresh currently in flight: the pending
    /// candidate while its identity transaction is open, otherwise the accepted
    /// structure. The candidate's identities are used for the scene, but the
    /// accepted identity table is only replaced by `commitCandidateRefresh`.
    public func buildRefreshNode(provider: CjguiGeneratedUiBindingProvider): CjguiComposableUiNode {
        if (let Some(structure) <- candidate) {
            let rendered = renderIntoCandidate(structure, provider)
            if (!rendered.ok) {
                // A candidate that cannot be built must not take the scene down
                // with it: roll its identity transaction back and keep the
                // accepted interface operable.
                registry.rollbackTransaction()
                candidatePrepared = false
                lastSceneOutcomeValue = "scene_rejected:${rendered.reason}"
                return buildAccepted(provider)
            }
            candidatePrepared = true
            return rendered.node
        }
        return buildAccepted(provider)
    }

    /// Completes the candidate declaration before layout/native submission, so
    /// a duplicate/capacity fault fails while the old interface is untouched.
    public func prepareCandidateRefresh(): Bool {
        if (candidate.isNone()) {
            return true
        }
        if (!candidatePrepared) {
            lastSceneOutcomeValue = "scene_rejected:candidate_not_prepared"
            return false
        }
        if (!registry.prepareTransaction()) {
            lastSceneOutcomeValue = "scene_rejected:${registry.lastIssue()}"
            return false
        }
        return true
    }

    /// Publishes the prepared candidate as the accepted structure. Called only
    /// after the window accepted the scene that contains it; the candidate's
    /// component identities are promoted in the same step, and only then are
    /// the instances it dropped destroyed.
    public func commitCandidateRefresh(): Bool {
        let pending = candidate
        if (let Some(structure) <- pending) {
            if (!candidatePrepared) {
                lastSceneOutcomeValue = "scene_rejected:candidate_not_prepared"
                return false
            }
            registry.commitTransaction()
            accepted = Some(structure)
            acceptedVersion = candidateVersion
            nodeIdToKey = candidateNodeIdToKey
            candidate = None
            candidatePrepared = false
            // No candidate is pending any more: the public candidate read must
            // not keep reporting the version that is now the accepted one.
            candidateVersion = 0
            lastSceneOutcomeValue = "scene_accepted"
            return true
        }
        lastSceneOutcomeValue = "scene_accepted"
        return true
    }

    /// Discards a candidate whose scene was rejected. The previous accepted
    /// structure, version, identity table and component instances are
    /// untouched, so the old interface stays addressable and editable.
    public func rollbackCandidateRefresh(): Unit {
        if (!candidate.isNone()) {
            if (lastSceneOutcomeValue.isEmpty() || lastSceneOutcomeValue == "scene_pending") {
                lastSceneOutcomeValue = "scene_rejected:layout_or_native"
            }
            registry.rollbackTransaction()
            candidate = None
            candidatePrepared = false
            candidateVersion = 0
        }
    }

    /// Renders the currently accepted structure (empty group when none was
    /// accepted yet).
    public func buildAccepted(provider: CjguiGeneratedUiBindingProvider): CjguiComposableUiNode {
        if (let Some(structure) <- accepted) {
            let rendered = renderInto(structure, provider, true)
            if (rendered.ok) {
                return rendered.node
            }
            // The accepted structure was built successfully when it was
            // committed; a later provider-driven build failure keeps the
            // placeholder so the rest of the window scene still commits.
            return cjguiComposableVertical(900001, "generated-empty", CjguiComposableUiStyle(gap: 4))
        }
        // A dedicated placeholder id: node id 1 belongs to the window's own
        // layer host, and a duplicate id rejects the whole scene commit.
        return cjguiComposableVertical(900001, "generated-empty", CjguiComposableUiStyle(gap: 4))
    }

    /// Renders the accepted structure through the immediate composition path
    /// (begin/finish). Used outside a refresh transaction only.
    private func renderInto(structure: CjguiGeneratedUiNodeSpec,
                            provider: CjguiGeneratedUiBindingProvider,
                            intoAcceptedTable: Bool): CjguiGeneratedUiRendered {
        nodeIdToKey = HashMap<Int64, String>()
        renderFailureReason = ""
        renderFailurePath = ""
        if (!registry.begin()) {
            return CjguiGeneratedUiRendered(false, "component_composition_failed", "",
                cjguiComposableVertical(900001, "generated-empty", CjguiComposableUiStyle(gap: 4)))
        }
        let node = nodeFor(structure, provider, intoAcceptedTable)
        if (!registry.finish()) {
            return CjguiGeneratedUiRendered(false, "component_composition_commit_failed", "", node)
        }
        if (!renderFailureReason.isEmpty()) {
            return CjguiGeneratedUiRendered(false, renderFailureReason, renderFailurePath, node)
        }
        return CjguiGeneratedUiRendered(true, "", "", node)
    }

    /// Renders the pending candidate inside the identity transaction already
    /// opened by `beginCandidateRefresh`. It never commits and never destroys
    /// an accepted instance.
    private func renderIntoCandidate(structure: CjguiGeneratedUiNodeSpec,
                                     provider: CjguiGeneratedUiBindingProvider): CjguiGeneratedUiRendered {
        candidateNodeIdToKey = HashMap<Int64, String>()
        renderFailureReason = ""
        renderFailurePath = ""
        let node = nodeFor(structure, provider, false)
        if (!renderFailureReason.isEmpty()) {
            return CjguiGeneratedUiRendered(false, renderFailureReason, renderFailurePath, node)
        }
        if (!registry.lastIssue().isEmpty()) {
            return CjguiGeneratedUiRendered(false, registry.lastIssue(), "", node)
        }
        return CjguiGeneratedUiRendered(true, "", "", node)
    }

    /// Node identity currently bound to an accepted stable key (negative when
    /// the key is not part of the accepted expansion). Consumers use it to
    /// prove that a structure update kept the same identity for a surviving
    /// key, which is what lets focus/selection/drafts continue.
    public func nodeIdForKey(key: String): Int64 {
        for ((nodeId, mappedKey) in nodeIdToKey) {
            if (mappedKey == key) {
                return nodeId
            }
        }
        return -1
    }

    /// Accepted stable key for a generated node identity. Events resolve their
    /// target through this mapping, never by re-deriving a key from text.
    public func keyForNodeId(nodeId: Int64): String {
        if (let Some(key) <- nodeIdToKey.get(nodeId)) {
            return key
        }
        return ""
    }

    /// Expands one node into ordinary components through the presentation its
    /// registered kind declares. An unregistered or unimplemented kind is an
    /// explicit render failure - it never degrades into a label. `nodeIdToKey`
    /// is updated for whichever table this render targets (accepted or
    /// candidate), so a candidate never mutates the accepted identity table.
    private func nodeFor(spec: CjguiGeneratedUiNodeSpec,
                         provider: CjguiGeneratedUiBindingProvider,
                         intoAcceptedTable: Bool): CjguiComposableUiNode {
        let declared = match (catalog.componentFor(spec.kind)) {
            case Some(value) => value
            case None => CjguiGeneratedUiComponentSpec("__unregistered__",
                ArrayList<CjguiGeneratedUiPropertySpec>(), false)
        }
        if (!declared.isImplemented()) {
            noteRenderFailure("component_not_implemented", spec.key)
            return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
        }
        // Identity: the stable key maps to a deterministic identity slot in the
        // accepted expansion. Slots are allocated once per accepted key and
        // reused across re-orders, so an event still resolves to the same
        // object while the node id never overlaps the window's manual ids.
        let instance = registry.use("generated-${spec.key}")
        let registryNodeId = instance.nodeId("node")
        let nodeId = if (registryNodeId > 0) { 800000 + registryNodeId } else { -1 }
        let semanticId = instance.semanticId("node")
        if (intoAcceptedTable) {
            nodeIdToKey.add(nodeId, spec.key)
        } else {
            candidateNodeIdToKey.add(nodeId, spec.key)
        }
        let style = styleFor(spec)
        let presentation = declared.presentation
        if (presentation == CJGUI_GENERATED_PRESENTATION_VERTICAL ||
            presentation == CJGUI_GENERATED_PRESENTATION_HORIZONTAL) {
            let group = if (presentation == CJGUI_GENERATED_PRESENTATION_VERTICAL) {
                cjguiComposableVertical(nodeId, semanticId, style)
            } else {
                cjguiComposableHorizontal(nodeId, semanticId, style)
            }
            for (child in spec.children) {
                group.add(nodeFor(child, provider, intoAcceptedTable))
            }
            return group
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_LABEL) {
            return cjguiComposableText(nodeId, semanticId, spec.property("text"), style)
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_ACTION) {
            let label = if (spec.property("label").size > 0) {
                spec.property("label")
            } else if (let Some(action) <- catalog.actionFor(spec.actionName)) {
                action.label
            } else {
                spec.actionName
            }
            return cjguiComposableButton(nodeId, semanticId, label, "GENERATED_ACTION", nodeId, style,
                enabled: provider.actionAvailable(spec.actionName))
        }
        let fieldOption = catalog.fieldFor(spec.fieldId)
        if (let None <- fieldOption) {
            noteRenderFailure("field_not_registered", spec.key)
            return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
        }
        let field = match (fieldOption) {
            case Some(value) => value
            case None => CjguiGeneratedUiFieldSpec("", "", "", -1)
        }
        if (field.writeActionName.isEmpty()) {
            noteRenderFailure("field_has_no_write_operation", spec.key)
            return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
        }
        // The shared field resource and the owner target come from the field
        // definition plus the live provider, never from a kind-name switch.
        let bindingResourceId = if (field.resourceId > 0) { field.resourceId } else { nodeId }
        let ownerTarget = provider.fieldOperationResourceId(spec.fieldId)
        // The declared field value comes from the application's live draft,
        // exactly like the handwritten form: a legally empty draft is a draft
        // and must not be replaced by the applied value.
        if (presentation == "FIELD_BOOLEAN") {
            let draft = provider.draftBoolean(spec.fieldId) ?? false
            return cjguiComposableBooleanInput(nodeId, semanticId, spec.property("label"), draft,
                bindingResourceId, style, enabled: ownerTarget >= 0, fieldId: spec.fieldId,
                operationActionName: field.writeActionName, operationResourceId: ownerTarget,
                displayValueRole: "draft")
        }
        let value = provider.draftText(spec.fieldId)
        if (presentation == "FIELD_INTEGER") {
            return cjguiComposableIntegerInput(nodeId, semanticId, spec.property("label"), value,
                bindingResourceId, style, enabled: ownerTarget >= 0, fieldId: spec.fieldId,
                operationActionName: field.writeActionName, operationResourceId: ownerTarget,
                displayValueRole: "draft")
        }
        return cjguiComposableTextInput(nodeId, semanticId, spec.property("label"), value,
            bindingResourceId, style, enabled: ownerTarget >= 0, fieldId: spec.fieldId,
            operationActionName: field.writeActionName, operationResourceId: ownerTarget,
            displayValueRole: "draft")
    }

    private func noteRenderFailure(reason: String, key: String): Unit {
        if (renderFailureReason.isEmpty()) {
            renderFailureReason = reason
            renderFailurePath = key
        }
    }

    /// Layout properties a registered presentation declares are applied here
    /// (gap/padding on containers), so a declared attribute is never silently
    /// ignored by the renderer.
    private func styleFor(spec: CjguiGeneratedUiNodeSpec): CjguiComposableUiStyle {
        var gap: Int64 = 4
        var padding: Int64 = 0
        let declaredGap = parseGeneratedInteger(spec.property("gap"))
        if (let Some(value) <- declaredGap) {
            gap = value
        }
        let declaredPadding = parseGeneratedInteger(spec.property("padding"))
        if (let Some(value) <- declaredPadding) {
            padding = value
        }
        return if (padding > 0) {
            CjguiComposableUiStyle(gap: gap, padding: padding)
        } else {
            CjguiComposableUiStyle(gap: gap)
        }
    }

    /// The accepted spec for a stable key, or None when that key is not part
    /// of the currently accepted structure. Event routing uses this to verify
    /// kind/field/binding before touching the business owner.
    public func acceptedNodeForKey(key: String): ?CjguiGeneratedUiNodeSpec {
        if (let Some(structure) <- accepted) {
            return findNode(structure, key)
        }
        return None
    }

    private func findNode(spec: CjguiGeneratedUiNodeSpec, key: String): ?CjguiGeneratedUiNodeSpec {
        if (spec.key == key) {
            return Some(spec)
        }
        for (child in spec.children) {
            if (let Some(found) <- findNode(child, key)) {
                return Some(found)
            }
        }
        return None
    }

    /// Resolves the accepted action for a generated node key (used by the
    /// consumer's event routing so a stale key never maps to another action).
    public func actionNameForKey(key: String): String {
        if (let Some(structure) <- accepted) {
            return actionNameIn(structure, key)
        }
        return ""
    }

    private func actionNameIn(spec: CjguiGeneratedUiNodeSpec, key: String): String {
        if (spec.key == key) {
            return spec.actionName
        }
        for (child in spec.children) {
            let found = actionNameIn(child, key)
            if (!found.isEmpty()) {
                return found
            }
        }
        return ""
    }
}

/// One decoded candidate (or a specific decode failure).
public class CjguiGeneratedUiDecoded {
    public let ok: Bool
    public let reason: String
    public let root: ?CjguiGeneratedUiNodeSpec

    public init(ok: Bool, reason: String, root: ?CjguiGeneratedUiNodeSpec) {
        this.ok = ok
        this.reason = reason
        this.root = root
    }
}

/// Replaceable line-based encoding for capability descriptions, accepted
/// structures and candidates. The value model above is the core contract; a
/// JSON or S-expression adapter may replace this text format without changing
/// validation, expansion or state-continuation behavior.
public class CjguiGeneratedUiEncoding {
    public static func describe(catalog: CjguiGeneratedUiCapabilityCatalog): String {
        let builder = StringBuilder()
        builder.append("GENERATED_UI 1\n")
        builder.append("BOUNDS ${catalog.maxDepth} ${catalog.maxNodes} ${catalog.maxPropertiesPerNode} " +
            "${catalog.maxStringLength}\n")
        for (kind in catalog.componentKinds()) {
            if (let Some(spec) <- catalog.componentFor(kind)) {
                builder.append("COMPONENT ${spec.kind} ${if (spec.allowsChildren) { 1 } else { 0 }} " +
                    "${spec.childLimit}\n")
                for (property in spec.properties) {
                    builder.append("PROPERTY ${spec.kind} ${property.name} ${property.valueType} " +
                        "${if (property.required) { 1 } else { 0 }} ${property.minimum} ${property.maximum} " +
                        "${property.maxLength}\n")
                }
            }
        }
        for (name in catalog.actionNames()) {
            if (let Some(spec) <- catalog.actionFor(name)) {
                builder.append("ACTION ${spec.name} ${spec.label}\n")
            }
        }
        // One line per declared field, carrying everything an external caller
        // needs to use it: the business type (editor kind), the shared resource
        // it binds, the declared constraints, the owner operation that performs
        // a write, and whether that write is currently callable. The first two
        // tokens stay `FIELD <id>` so existing readers keep working; the added
        // tokens replace nothing.
        for (fieldId in catalog.fieldIds()) {
            if (let Some(field) <- catalog.fieldFor(fieldId)) {
                builder.append("FIELD ${field.fieldId} ${field.editorKind} resource=${field.resourceId} " +
                    "writer=${if (field.writeActionName.size > 0) { field.writeActionName } else { "none" }} " +
                    "required=${if (field.required) { 1 } else { 0 }} " +
                    "min=${field.minimum} max=${field.maximum} " +
                    "callable=${if (field.isWritable()) { 1 } else { 0 }}\n")
            } else {
                builder.append("FIELD ${fieldId} unknown writer=none required=0 min=0 max=0 callable=0\n")
            }
        }
        builder.append("END")
        return builder.toString()
    }

    public static func encode(structure: ?CjguiGeneratedUiNodeSpec, version: Int64): String {
        let builder = StringBuilder()
        builder.append("STRUCTURE ${version}\n")
        if (let Some(root) <- structure) {
            encodeNode(root, 0, builder)
        }
        builder.append("END")
        return builder.toString()
    }

    private static func encodeNode(node: CjguiGeneratedUiNodeSpec, depth: Int64,
                                   builder: StringBuilder): Unit {
        builder.append("NODE ${depth} ${node.key} ${node.kind}")
        if (node.fieldId.size > 0) {
            builder.append(" field=${node.fieldId}")
        }
        if (node.actionName.size > 0) {
            builder.append(" action=${node.actionName}")
        }
        builder.append("\n")
        for ((name, value) in node.properties) {
            builder.append("PROPERTY ${depth} ${node.key} ${name} ${value}\n")
        }
        for (child in node.children) {
            encodeNode(child, depth + 1, builder)
        }
    }

    public static func decode(candidate: String): CjguiGeneratedUiDecoded {
        let lines = candidate.split("\n")
        if (lines.size < 2 || lines[0] != "GENERATED_UI_STRUCTURE 1") {
            return CjguiGeneratedUiDecoded(false, "invalid_header", None)
        }
        // Pending nodes per depth keep parent/child relationships without a
        // second pass; the root is the depth-0 node.
        let stack = ArrayList<ArrayList<CjguiGeneratedUiNodeSpec>>()
        var root: ?CjguiGeneratedUiNodeSpec = None
        var index: Int64 = 1
        while (index < lines.size) {
            let line = lines[index]
            if (line == "END") {
                break
            }
            if (line.size == 0) {
                index += 1
                continue
            }
            let fields = line.split(" ")
            if (fields[0] == "NODE") {
                if (fields.size < 4) {
                    return CjguiGeneratedUiDecoded(false, "malformed_node:${index}", None)
                }
                // NODE <depth> <key> <kind> field=<id> action=<name>
                let depth = parseInt64OrZeroEncoding(fields[1])
                let key = fields[2]
                let kind = fields[3]
                var fieldId = ""
                var actionName = ""
                var fieldIndex: Int64 = 4
                while (fieldIndex < fields.size) {
                    if (fields[fieldIndex].startsWith("field=") && fields[fieldIndex].size > 6) {
                        fieldId = fields[fieldIndex][6..fields[fieldIndex].size]
                    } else if (fields[fieldIndex].startsWith("action=") && fields[fieldIndex].size > 7) {
                        actionName = fields[fieldIndex][7..fields[fieldIndex].size]
                    }
                    fieldIndex += 1
                }
                let node = CjguiGeneratedUiNodeSpec(key, kind, fieldId: fieldId, actionName: actionName)
                while (stack.size <= depth) {
                    stack.add(ArrayList<CjguiGeneratedUiNodeSpec>())
                }
                if (depth > 0) {
                    if (stack[Int64(depth) - 1].size == 0) {
                        return CjguiGeneratedUiDecoded(false, "orphan_node:${index}", None)
                    }
                    stack[Int64(depth) - 1][stack[Int64(depth) - 1].size - 1].children.add(node)
                } else if (root.isSome()) {
                    return CjguiGeneratedUiDecoded(false, "multiple_roots:${index}", None)
                } else {
                    root = Some(node)
                }
                stack[depth].add(node)
            } else if (fields[0] == "PROPERTY") {
                if (fields.size < 5) {
                    return CjguiGeneratedUiDecoded(false, "malformed_property:${index}", None)
                }
                let depth = parseInt64OrZeroEncoding(fields[1])
                let key = fields[2]
                let name = fields[3]
                if (depth >= stack.size || stack[depth].size == 0) {
                    return CjguiGeneratedUiDecoded(false, "orphan_property:${index}", None)
                }
                let target = stack[depth][stack[depth].size - 1]
                if (target.key != key) {
                    return CjguiGeneratedUiDecoded(false, "property_key_mismatch:${index}", None)
                }
                // Values may contain spaces: take everything after the fourth
                // space (PROPERTY depth key name value...).
                var spacesSeen = 0
                var scan: Int64 = 0
                var value = ""
                while (scan < line.size) {
                    if (line[scan] == 32) {
                        spacesSeen += 1
                        if (spacesSeen == 4) {
                            value = line[scan + 1..line.size]
                            break
                        }
                    }
                    scan += 1
                }
                target.properties.add(name, value)
            } else {
                return CjguiGeneratedUiDecoded(false, "unknown_line:${index}", None)
            }
            index += 1
        }
        return CjguiGeneratedUiDecoded(true, "", root)
    }
}

private func parseInt64OrZeroEncoding(value: String): Int64 {
    var result: Int64 = 0
    var negative = false
    var index = 0
    for (byte in value.toArray()) {
        if (index == 0 && byte == 45) {
            negative = true
            index += 1
            continue
        }
        if (byte < 48 || byte > 57) {
            return 0
        }
        result = result * 10 + Int64(byte - 48)
        index += 1
    }
    return if (negative) { -result } else { result }
}

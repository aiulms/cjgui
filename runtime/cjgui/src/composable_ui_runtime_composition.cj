// Runtime composition definitions: an application (or an external caller
// through the structure payload) declares a named, bounded tree of EXISTING
// component kinds plus field/action references, and the framework expands it
// generically. This is deliberately NOT the compiled-factory seam in
// `composable_ui_composite_component.cj`: no application Cangjie code is
// registered or executed here. It is also not a plugin system, a script
// interpreter or a second submission channel: definitions travel in the SAME
// structure candidate as their instances, are validated against the ordinary
// catalog, and are installed only when the candidate's scene is accepted.
//
// Boundaries of the first version:
//   * no recursion: a definition template may only name built-in structural
//     kinds and the definition's own elements, never another composition;
//   * typed parameters only (STRING/INTEGER/BOOLEAN) with declared bounds;
//   * field/action references resolve through the ordinary catalog and the
//     ordinary provider (per-instance owner targets keep working);
//   * a failed definition update leaves the accepted definition, every accepted
//     instance and the owner data untouched.
package cjgui

import std.collection.*
import std.env.*
import cjgui_shared_operation_core.*

public let CJGUI_COMPOSITION_NODE_VERTICAL: String = "vertical"
public let CJGUI_COMPOSITION_NODE_HORIZONTAL: String = "horizontal"
public let CJGUI_COMPOSITION_NODE_WRAP: String = "wrap"
public let CJGUI_COMPOSITION_NODE_LABEL: String = "label"
public let CJGUI_COMPOSITION_NODE_SPACER: String = "spacer"
public let CJGUI_COMPOSITION_NODE_SPLIT: String = "split"
public let CJGUI_COMPOSITION_NODE_ELEMENT: String = "element"
public let CJGUI_COMPOSITION_NODE_COMPOSE: String = "composition"
public let CJGUI_COMPOSITION_NODE_CHILDREN: String = "children"

public let CJGUI_COMPOSITION_PRESENTATION_TEXT: String = "text"
public let CJGUI_COMPOSITION_PRESENTATION_SELECT: String = "select"
public let CJGUI_COMPOSITION_PRESENTATION_RADIO: String = "radio"
public let CJGUI_COMPOSITION_PRESENTATION_SEGMENTED: String = "segmented"

public let CJGUI_COMPOSITION_MAX_PARAMETERS: Int64 = 8
public let CJGUI_COMPOSITION_MAX_ELEMENTS: Int64 = 24
public let CJGUI_COMPOSITION_MAX_TEMPLATE_NODES: Int64 = 64
public let CJGUI_COMPOSITION_MAX_TEMPLATE_DEPTH: Int64 = 8
// Candidate-wide budgets. Per-definition limits alone would let a payload of
// many legal definitions drive an unbounded aggregate allocation, so the total
// is bounded too and published as the same public fact the decoder enforces.
public let CJGUI_COMPOSITION_CANDIDATE_MAX_DEFINITIONS: Int64 = 8
public let CJGUI_COMPOSITION_CANDIDATE_MAX_ELEMENTS: Int64 = 96
public let CJGUI_COMPOSITION_CANDIDATE_MAX_TEMPLATE_NODES: Int64 = 256
public let CJGUI_COMPOSITION_CANDIDATE_MAX_BYTES: Int64 = 262144
/// A small declaration may legally reference one composition many times. The
/// expanded total therefore reuses the candidate byte budget as its cap and is
/// checked BEFORE the factory allocates the tree: the post-expansion audit is
/// a consistency check, not the only bound on repeated-reference fan-out.
public let CJGUI_COMPOSITION_EXPANSION_MAX_BYTES: Int64 = CJGUI_COMPOSITION_CANDIDATE_MAX_BYTES

/// One declared typed parameter. The value is a plain declaration default; an
/// instance may override it with a value of the same type, validated by the
/// ordinary component-property checks.
public class CjguiCompositionParameter {
    public let name: String
    public let valueType: String
    public let required: Bool
    public let maxLength: Int64
    public let minimum: Int64
    public let maximum: Int64
    public let defaultValue: String

    public init(name: String, valueType: String, required!: Bool = false, maxLength!: Int64 = 80,
        minimum!: Int64 = 0, maximum!: Int64 = 1000000, defaultValue!: String = "") {
        this.name = name
        this.valueType = valueType
        this.required = required
        this.maxLength = maxLength
        this.minimum = minimum
        this.maximum = maximum
        this.defaultValue = defaultValue
    }
}

/// One template node. `kind` names an EXISTING structural presentation; an
/// `element` node mounts one declared element at the identity the framework
/// allocated for it. Parameters are substituted only in text/label strings.
public class CjguiCompositionTemplateNode {
    public let key: String
    public let kind: String
    /// §16: when non-empty, this node EXPANDS the named composition inside
    /// this instance (bounded acyclic reference). `kind` then carries the
    /// referenced composition's name; `composeName` keeps the same fact as an
    /// explicit declared token so the reference survives round-trips even when
    /// the kind equals a builtin name.
    public let composeName: String
    public let elementKey: String
    public let presentation: String
    public let text: String
    public let styleName: String
    public let gap: Int64
    public let padding: Int64
    public let fixedHeight: Int64
    public let growX: Int64
    public let axis: String
    public let firstSize: Int64
    public let minFirst: Int64
    public let minSecond: Int64
    public let children: ArrayList<CjguiCompositionTemplateNode>

    public init(key: String, kind: String, elementKey!: String = "", presentation!: String = "",
        text!: String = "", styleName!: String = "", gap!: Int64 = -1, padding!: Int64 = -1,
        fixedHeight!: Int64 = -1, growX!: Int64 = -1, axis!: String = "horizontal",
        firstSize!: Int64 = 240, minFirst!: Int64 = 120, minSecond!: Int64 = 120,
        composeName!: String = "",
        children!: ArrayList<CjguiCompositionTemplateNode> = ArrayList<CjguiCompositionTemplateNode>()) {
        this.key = key
        this.kind = kind
        this.composeName = composeName
        this.elementKey = elementKey
        this.presentation = presentation
        this.text = text
        this.styleName = styleName
        this.gap = gap
        this.padding = padding
        this.fixedHeight = fixedHeight
        this.growX = growX
        this.axis = axis
        this.firstSize = firstSize
        this.minFirst = minFirst
        this.minSecond = minSecond
        this.children = children
    }

    public func child(key: String): ?CjguiCompositionTemplateNode {
        for (node in children) {
            if (node.key == key) { return Some(node) }
        }
        return None
    }
}

/// One element OCCURRENCE in a definition's expanded tree: the reference path
/// that reached it plus the declaration itself. Two legal references to the
/// same composition yield two occurrences (two presentation identities) while
/// both carry the SAME declaration and therefore the same owner/field/writer.
public class CjguiCompositionElementOccurrence {
    /// Encoded reference path ("" at the definition root). Each segment is
    /// length-prefixed, so keys containing separators cannot collide.
    public let path: String
    public let presentation: String
    public let element: CjguiCompositeElementSpec

    public init(path: String, presentation: String, element: CjguiCompositeElementSpec) {
        this.path = path
        this.presentation = presentation
        this.element = element
    }

    public func slotKey(): String {
        return cjguiCompositionElementSlotKey(path, element.elementKey)
    }
}

/// Pre-expansion cost of one instance's tree. The factory is allowed to run
/// only after this plan fits the SAME node/depth limits the audit uses; bytes
/// reuse the candidate declaration budget. `issue` is a stable machine reason.
public class CjguiCompositionExpansionPlan {
    public let occurrences: ArrayList<CjguiCompositionElementOccurrence>
    public var nodes: Int64
    public var maxDepth: Int64
    public var bytes: Int64
    public var issue: String

    public init() {
        this.occurrences = ArrayList<CjguiCompositionElementOccurrence>()
        this.nodes = 0
        this.maxDepth = 0
        this.bytes = 0
        this.issue = ""
    }
}

/// A complete runtime definition. The framework derives the composite component
/// spec (parameters become ordinary properties, elements become the ordinary
/// composite element declarations) and registers one generic factory; the
/// definition never supplies executable code.
public class CjguiRuntimeCompositionDefinition {
    public let name: String
    public let parameters: ArrayList<CjguiCompositionParameter>
    public let elements: ArrayList<CjguiCompositeElementSpec>
    public let template: CjguiCompositionTemplateNode
    public let expandedNodeLimit: Int64
    public let expandedDepthLimit: Int64
    public let note: String

    public init(name: String, parameters: ArrayList<CjguiCompositionParameter>,
        elements: ArrayList<CjguiCompositeElementSpec>, template: CjguiCompositionTemplateNode,
        expandedNodeLimit!: Int64 = 64, expandedDepthLimit!: Int64 = 6, note!: String = "") {
        this.name = name
        this.parameters = parameters
        this.elements = elements
        this.template = template
        this.expandedNodeLimit = expandedNodeLimit
        this.expandedDepthLimit = expandedDepthLimit
        this.note = note
    }

    public func elementFor(key: String): ?CjguiCompositeElementSpec {
        for (element in elements) {
            if (element.elementKey == key) { return Some(element) }
        }
        return None
    }

    public func propertySpecs(): ArrayList<CjguiGeneratedUiPropertySpec> {
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        for (parameter in parameters) {
            properties.add(CjguiGeneratedUiPropertySpec(parameter.name, parameter.valueType,
                required: parameter.required, minimum: parameter.minimum, maximum: parameter.maximum,
                maxLength: parameter.maxLength, defaultValue: parameter.defaultValue))
        }
        return properties
    }

    public func componentSpec(): CjguiCompositeComponentSpec {
        return CjguiCompositeComponentSpec(name, propertySpecs(), elements,
            expandedNodeLimit: expandedNodeLimit, expandedDepthLimit: expandedDepthLimit)
    }
}

/// Validates one definition against the SAME catalog its instances will use.
/// Empty string means acceptable. Every refusal is a stable machine reason.
/// True when `value` survives the ONE positional token a CPARAM default owns.
/// The wire grammar has no escape for a space, so whitespace/control content is
/// refused by the producer and the decoder instead of being truncated.
func cjguiCompositionSingleToken(value: String): Bool {
    for (index in 0..value.size) {
        let byte = value[index]
        if (byte <= 32 || byte == 127) { return false }
    }
    return true
}

public func cjguiRuntimeCompositionIssue(definition: CjguiRuntimeCompositionDefinition,
    catalog: CjguiGeneratedUiCapabilityCatalog): String {
    if (!CjguiComposableUiNamedStyleCatalog.isValidName(definition.name)) {
        return "composition_name_invalid"
    }
    if (CjguiGeneratedUiPresentation.forBuiltInKind(definition.name).size > 0) {
        return "composition_name_is_builtin:${definition.name}"
    }
    if (definition.parameters.size > CJGUI_COMPOSITION_MAX_PARAMETERS) {
        return "composition_parameter_budget:${definition.name}"
    }
    let parameterNames = HashSet<String>()
    for (parameter in definition.parameters) {
        if (!CjguiComposableUiNamedStyleCatalog.isValidName(parameter.name) ||
            parameterNames.contains(parameter.name)) {
            return "composition_parameter_name:${parameter.name}"
        }
        parameterNames.add(parameter.name)
        if (parameter.valueType != "STRING" && parameter.valueType != "INTEGER" &&
            parameter.valueType != "BOOLEAN") {
            return "composition_parameter_type:${parameter.name}"
        }
        if (parameter.valueType == "STRING" && parameter.maxLength <= 0) {
            return "composition_parameter_length:${parameter.name}"
        }
        if (parameter.valueType == "INTEGER" && parameter.minimum > parameter.maximum) {
            return "composition_parameter_range:${parameter.name}"
        }
        // CPARAM carries the default in ONE positional token. A space or a
        // control character cannot be represented there (there is no escape
        // escape in this grammar), so refusing here is the only alternative to
        // letting the producer emit a line its own decoder must truncate.
        if (!cjguiCompositionSingleToken(parameter.defaultValue)) {
            return "composition_parameter_default_not_single:${parameter.name}"
        }
    }
    if (definition.elements.size == 0 || definition.elements.size > CJGUI_COMPOSITION_MAX_ELEMENTS) {
        return "composition_element_budget:${definition.name}"
    }
    let elementKeys = HashSet<String>()
    for (element in definition.elements) {
        if (element.elementKey.size == 0 || elementKeys.contains(element.elementKey)) {
            return "composition_element_key:${element.elementKey}"
        }
        elementKeys.add(element.elementKey)
        if (element.role == CJGUI_COMPOSITE_ELEMENT_FIELD || element.role == CJGUI_COMPOSITE_ELEMENT_PRESET) {
            if (let None <- catalog.fieldFor(element.fieldId)) {
                return "composition_unknown_field:${element.fieldId}"
            }
        }
        if (element.role == CJGUI_COMPOSITE_ELEMENT_PROJECTION) {
            // Same partition the catalog's own composite validation uses: the
            // field_error/field_reason projections name a field; the action
            // reason names an action; owner_status is field-less.
            if (element.source == CJGUI_COMPOSITE_PROJECTION_FIELD_ERROR ||
                element.source == CJGUI_COMPOSITE_PROJECTION_FIELD_REASON) {
                if (let None <- catalog.fieldFor(element.fieldId)) {
                    return "composition_unknown_field:${element.fieldId}"
                }
            } else if (element.source == CJGUI_COMPOSITE_PROJECTION_ACTION_REASON) {
                if (let None <- catalog.actionFor(element.actionName)) {
                    return "composition_unknown_action:${element.actionName}"
                }
            } else if (element.source != CJGUI_COMPOSITE_PROJECTION_OWNER_STATUS) {
                return "composition_unknown_projection_source:${definition.name}:${element.source}"
            }
        }
        if (element.role == CJGUI_COMPOSITE_ELEMENT_ACTION &&
            (let None <- catalog.actionFor(element.actionName))) {
            return "composition_unknown_action:${element.actionName}"
        }
    }
    if (definition.expandedNodeLimit <= 0 || definition.expandedNodeLimit > catalog.maxNodes) {
        return "composition_node_limit:${definition.name}"
    }
    if (definition.expandedDepthLimit <= 0 || definition.expandedDepthLimit > catalog.maxDepth) {
        return "composition_depth_limit:${definition.name}"
    }
    return cjguiCompositionTemplateIssue(definition.template, definition, elementKeys, 0, parameterNames, catalog)
}

private func cjguiCompositionTemplateIssue(node: CjguiCompositionTemplateNode,
    definition: CjguiRuntimeCompositionDefinition, elementKeys: HashSet<String>, depth: Int64,
    parameterNames: HashSet<String>, catalog: CjguiGeneratedUiCapabilityCatalog): String {
    if (depth > definition.expandedDepthLimit || depth > CJGUI_COMPOSITION_MAX_TEMPLATE_DEPTH) {
        return "composition_template_depth:${node.key}"
    }
    let kind = node.kind
    let structural = kind == CJGUI_COMPOSITION_NODE_VERTICAL || kind == CJGUI_COMPOSITION_NODE_HORIZONTAL ||
        kind == CJGUI_COMPOSITION_NODE_WRAP || kind == CJGUI_COMPOSITION_NODE_LABEL ||
        kind == CJGUI_COMPOSITION_NODE_SPACER || kind == CJGUI_COMPOSITION_NODE_SPLIT ||
        kind == CJGUI_COMPOSITION_NODE_ELEMENT || kind == CJGUI_COMPOSITION_NODE_CHILDREN ||
        kind == CJGUI_COMPOSITION_NODE_COMPOSE
    if (!structural) {
        // §16: a `compose=<name>` node EXPANDS the named declared composition
        // inside this instance; the wire kind for it is the literal
        // `composition`. A kind that is neither structural nor this literal
        // stays the named refusal it has always been. Existence and acyclicity
        // of the target are the candidate-wide graph check in
        // cjguiStageRuntimeCompositions, which sees the whole effective set.
        return "composition_unknown_template_kind:${kind}"
    }
    if (kind == CJGUI_COMPOSITION_NODE_COMPOSE) {
        if (node.composeName.size == 0) { return "composition_compose_missing:${node.key}" }
        if (!CjguiComposableUiNamedStyleCatalog.isValidName(node.composeName)) {
            return "composition_compose_name:${node.composeName}"
        }
        if (node.children.size > 0) { return "composition_leaf_children:${node.key}" }
    }
    if (kind == CJGUI_COMPOSITION_NODE_ELEMENT) {
        if (!elementKeys.contains(node.elementKey)) {
            return "composition_unknown_element:${node.elementKey}"
        }
        let presentation = node.presentation
        if (presentation != CJGUI_COMPOSITION_PRESENTATION_TEXT &&
            presentation != CJGUI_COMPOSITION_PRESENTATION_SELECT &&
            presentation != CJGUI_COMPOSITION_PRESENTATION_RADIO &&
            presentation != CJGUI_COMPOSITION_PRESENTATION_SEGMENTED) {
            return "composition_unknown_presentation:${presentation}"
        }
        // Every dropdown/radio/segmented presentation resolves through the
        // element's own accepted writer. A per-instance Select controller owns
        // only popup/query/highlight state; it never borrows the single-owner
        // commit closure, and it still requires a declared option source.
        if (presentation == CJGUI_COMPOSITION_PRESENTATION_SELECT ||
            presentation == CJGUI_COMPOSITION_PRESENTATION_RADIO ||
            presentation == CJGUI_COMPOSITION_PRESENTATION_SEGMENTED) {
            let element = match (definition.elementFor(node.elementKey)) {
                case Some(value) => value
                case None => return "composition_unknown_element:${node.elementKey}"
            }
            if (element.role != CJGUI_COMPOSITE_ELEMENT_FIELD) {
                return "composition_choice_requires_field:${node.elementKey}"
            }
            if (let None <- catalog.choiceOptionsFor(element.fieldId)) {
                return "composition_choice_binding_missing:${element.fieldId}"
            }
        }
    }
    if (node.styleName.size > 0) {
        // The template names ONE registered named style for this node; an
        // unknown reference is a definition error, not a silently unpainted
        // node. The style is resolved again on every build from the SAME
        // directory, so a style replacement reaches an accepted instance.
        if (let None <- catalog.namedStyles().forName(node.styleName)) {
            return "composition_unknown_named_style:${node.styleName}"
        }
    }
    // Exactly two regions: the factory mounts first/second and would silently
    // discard a third child. A leaf or a `children` slot has no template
    // children at all; declaring one would also be dropped.
    if (kind == CJGUI_COMPOSITION_NODE_SPLIT && node.children.size != 2) {
        return "composition_split_children:${node.key}"
    }
    if ((kind == CJGUI_COMPOSITION_NODE_ELEMENT || kind == CJGUI_COMPOSITION_NODE_LABEL ||
        kind == CJGUI_COMPOSITION_NODE_SPACER || kind == CJGUI_COMPOSITION_NODE_CHILDREN ||
        kind == CJGUI_COMPOSITION_NODE_COMPOSE) && node.children.size > 0) {
        return "composition_leaf_children:${node.key}"
    }
    let placeholderIssue = cjguiCompositionTextIssue(node.text, parameterNames)
    if (placeholderIssue.size > 0) { return placeholderIssue }
    for (child in node.children) {
        let issue = cjguiCompositionTemplateIssue(child, definition, elementKeys, depth + 1, parameterNames,
            catalog)
        if (issue.size > 0) { return issue }
    }
    return ""
}

/// Validates and stages ONE definition for the candidate that will carry its
/// instances. The caller owns the structure candidate/version transaction; this
/// helper only guarantees the catalog overlay is all-or-nothing. An empty
/// result means staged; otherwise the accepted catalog is untouched and the
/// reason is a stable machine token. Both region implementations call this, so
/// the rules and mixed consumers share one definition transaction.
public func cjguiStageRuntimeComposition(catalog: CjguiGeneratedUiCapabilityCatalog,
    definition: CjguiRuntimeCompositionDefinition): String {
    let issue = cjguiRuntimeCompositionIssue(definition, catalog)
    if (issue.size > 0) {
        // The caller owns the previous candidate's overlay. A rejected B must
        // not clear a still-pending A; only an ACCEPTED replacement retires it.
        return "composition_rejected:${issue}"
    }
    if (!catalog.stageComposite(definition.componentSpec(),
        CjguiRuntimeCompositionFactory(definition, catalog: catalog))) {
        return "composition_stage:${catalog.registrationIssue()}"
    }
    return ""
}

/// Stages EVERY definition of one ticket. The caller owns the overlay snapshot
/// and restores it on failure; an issue at any position leaves the catalog in
/// the state the caller restores, never with a partly staged batch.
///
/// §16: after the per-definition checks, the WHOLE effective set (this batch
/// plus the accepted definitions minus the accepted ones this batch replaces)
/// is checked as ONE reference graph: an unknown compose target, a direct or
/// indirect cycle and a self-reference are refused here before anything is
/// committed, and the caller's snapshot restore keeps the old interface.
public func cjguiStageRuntimeCompositions(catalog: CjguiGeneratedUiCapabilityCatalog,
    payloads: ArrayList<CjguiCompositionPayload>): String {
    for (payload in payloads) {
        let issue = cjguiStageRuntimeComposition(catalog, payload.definition)
        if (issue.size > 0) { return issue }
    }
    // The effective view a `compose=` reference may name: THIS batch (forward
    // references are legal) plus every accepted definition this batch does not
    // replace.
    let effective = ArrayList<CjguiRuntimeCompositionDefinition>()
    for (payload in payloads) { effective.add(payload.definition) }
    for (accepted in catalog.acceptedRuntimeCompositionDefinitions()) {
        var replaced = false
        for (payload in payloads) {
            if (payload.definition.name == accepted.name) { replaced = true; break }
        }
        if (!replaced) { effective.add(accepted) }
    }
    let graphIssue = cjguiCompositionReferenceGraphIssue(effective)
    if (graphIssue.size > 0) { return graphIssue }
    // One instance context is keyed by element key. Two DIFFERENT declarations
    // sharing a key anywhere in a definition's reachable set would make one
    // shadow the other, so the whole batch is refused while the old interface
    // stays accepted.
    for (definition in effective) {
        let conflict = cjguiCompositionElementKeyConflict(catalog, definition)
        if (conflict.size > 0) { return conflict }
    }
    return ""
}

/// §16 named graph refusals over the effective definition set: every
/// `compose=` target must exist; the reference relation must be acyclic.
/// Depth is NOT bounded here per-definition (each definition's own depth limit
/// still applies at decode time); the aggregate EXPANSION size is bounded by
/// the ordinary per-instance expansion audit at build time and the candidate
/// template-node budget at decode time.
public func cjguiCompositionReferenceGraphIssue(
    effective: ArrayList<CjguiRuntimeCompositionDefinition>): String {
    var byName = HashMap<String, CjguiRuntimeCompositionDefinition>()
    for (definition in effective) { byName.add(definition.name, definition) }
    // Unknown target check.
    for (definition in effective) {
        var stack = ArrayList<CjguiCompositionTemplateNode>()
        stack.add(definition.template)
        while (stack.size > 0) {
            let node = stack.remove(at: stack.size - 1)
            if (node.composeName.size > 0 && !byName.contains(node.composeName)) {
                return "composition_rejected:composition_compose_unknown:${node.composeName}"
            }
            for (child in node.children) { stack.add(child) }
        }
    }
    // Cycle check: iterative color DFS. The stack carries (name, phase):
    // phase 0 = enter, phase 1 = leave. Entering a name that is currently on
    // the stack is a cycle; a finished name never revisits.
    let visiting = HashSet<String>()
    let done = HashSet<String>()
    for (definition in effective) {
        if (done.contains(definition.name)) { continue }
        let stack = ArrayList<(String, Int64)>()
        stack.add((definition.name, 0))
        while (stack.size > 0) {
            // Read the owned values before ArrayList clears the last slot.
            // The affected OHOS core's remove-returned tuple lost its fields;
            // keep the same DFS and do not consume that returned tuple.
            let last = stack.size - 1
            let name: String = stack[last][0]
            let phase: Int64 = stack[last][1]
            let _ = stack.remove(at: last)
            if (phase == 1) {
                let _ = visiting.remove(name)
                done.add(name)
                continue
            }
            if (done.contains(name)) { continue }
            if (visiting.contains(name)) {
                return "composition_rejected:composition_compose_cycle:${name}"
            }
            visiting.add(name)
            stack.add((name, 1))
            let node = byName.get(name)
            if (let Some(value) <- node) {
                var refs = ArrayList<CjguiCompositionTemplateNode>()
                refs.add(value.template)
                while (refs.size > 0) {
                    let template = refs.remove(at: refs.size - 1)
                    if (template.composeName.size > 0) { stack.add((template.composeName, 0)) }
                    for (child in template.children) { refs.add(child) }
                }
            }
        }
    }
    return ""
}

/// Per-instance Select state for runtime compositions. ONE CjguiSelect per
/// (instanceKey, elementKey) owns only popup/query/highlight state; the write
/// resolves through the SAME accepted element binding radio rows use. The
/// controller is never given the handwritten single-owner commit closure, so
/// opening card B can never write card A's owner.
public class CjguiCompositionSelectHost {
    private let holder: CjguiGeneratedUiStructureHolder
    private let states: HashMap<String, CjguiCompositionSelectState>

    public init(holder: CjguiGeneratedUiStructureHolder) {
        this.holder = holder
        this.states = HashMap<String, CjguiCompositionSelectState>()
    }

    private func stateKey(instanceKey: String, elementKey: String): String {
        return "${instanceKey}/${elementKey}"
    }

    private func currentText(element: CjguiCompositeElementBinding): String {
        return if (element.editorKind == "BOOLEAN") {
            if (element.draftBoolean) { "true" } else { "false" }
        } else {
            element.draftText
        }
    }

    private func sync(state: CjguiCompositionSelectState, element: CjguiCompositeElementBinding): Unit {
        state.ownerTargetResourceId = element.ownerTargetResourceId
        state.nodeId = element.nodeId
        state.instanceIncarnation = element.instanceIncarnation
        state.select.update(element.choiceOptions, currentText(element), enabled: element.ownerAvailable,
            placeholder: element.label, searchable: true, error: element.blockedReason)
    }

    private func matchingStateOf(element: CjguiCompositeElementBinding): CjguiCompositionSelectState {
        let key = stateKey(element.instanceKey, element.elementKey)
        if (let Some(existing) <- states.get(key)) {
            existing.select.close()
            states.remove(key)
        }
        let state = CjguiCompositionSelectState(key, element.instanceKey, element.elementKey, element.nodeId,
            element.ownerTargetResourceId, element.instanceIncarnation,
            CjguiSelect("composition-select-${element.instanceKey}-${element.elementKey}",
                "${element.semanticId}-select"))
        states.add(key, state)
        return state
    }

    /// Routes an activation/text/key intent. Closed controls and unrelated
    /// nodes return None so the region's ordinary route continues.
    public func handleEvent(event: CjguiComposableUiEvent,
        binding: CjguiGeneratedUiRegionBinding): ?CjguiComposableUiDispatchResult {
        for ((_, state) in states) {
            if (!state.select.isOpen()) { continue }
            if (let Some(result) <- state.select.applyUiEvent(event)) {
                if (let Some(option) <- state.select.takeConfirmed()) {
                    let intent = holder.compositionSelectIntent(state.instanceKey, state.elementKey, option.key,
                        state.ownerTargetResourceId, state.nodeId, state.instanceIncarnation)
                    let applied = if (intent.isFieldEdit()) {
                        binding.applyFieldIntent(intent).didApply
                    } else {
                        false
                    }
                    if (!applied) {
                        getStdOut().writeln("CJGUI_COMPOSITION_SELECT phase=refused " +
                            "instance=${state.instanceKey} element=${state.elementKey} reason=${intent.reason}")
                        getStdOut().flush()
                    }
                    return Some(CjguiComposableUiDispatchResult(applied))
                }
                return Some(result)
            }
        }
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) { return None }
        let element = match (holder.compositeElementForNodeId(event.node.nodeId)) {
            case Some(value) => value
            case None => return None
        }
        if (element.role != CJGUI_COMPOSITE_ELEMENT_FIELD || element.choiceOptions.size == 0 ||
            event.node.actionName != "${element.semanticId}-select-toggle") {
            return None
        }
        // One popup owns the pointer/focus at a time. A sibling card's popup is
        // closed, never reused for another owner.
        for ((_, other) in states) {
            if (other.select.isOpen()) { other.select.close() }
        }
        let state = matchingStateOf(element)
        sync(state, element)
        return state.select.applyUiEvent(event)
    }

    private func sceneHasAction(node: CjguiComposableUiNode, action: String): Bool {
        if (node.actionName == action) { return true }
        for (child in node.children()) {
            if (sceneHasAction(child, action)) { return true }
        }
        return false
    }

    /// Adds every OPEN instance popup above the accepted scene. A popup whose
    /// accepted element disappeared or changed owner/generation is dropped
    /// BEFORE it can render rows that would target a different object.
    public func attach(root: CjguiComposableUiNode): CjguiComposableUiNode {
        var scene = root
        let stale = ArrayList<String>()
        for ((key, state) in states) {
            if (!state.select.isOpen()) { continue }
            let element = match (holder.acceptedCompositeElementFor(state.instanceKey, state.elementKey)) {
                case Some(value) => value
                case None =>
                    stale.add(key)
                    continue
            }
            if (element.ownerTargetResourceId != state.ownerTargetResourceId ||
                element.instanceIncarnation != state.instanceIncarnation) {
                stale.add(key)
                continue
            }
            // The candidate being built may already have retired the trigger
            // (definition/instance removal). Attaching then would publish a
            // layer anchor that cannot resolve in THIS scene and reject the
            // whole candidate; close the popup before it renders.
            if (!sceneHasAction(root, "${element.semanticId}-select-toggle")) {
                stale.add(key)
                continue
            }
            sync(state, element)
            if (!state.select.isOpen()) { continue }
            scene = state.select.attachTo(scene)
        }
        for (key in stale) {
            if (let Some(state) <- states.get(key)) { state.select.close() }
            states.remove(key)
        }
        return scene
    }

    /// Settles open popups against the accepted directory AFTER a candidate
    /// commit. Only an element that still binds the same owner generation may
    /// stay open; a removal/rebind/disable closes it.
    public func reconcile(): Unit {
        let stale = ArrayList<String>()
        for ((key, state) in states) {
            if (!state.select.isOpen()) { continue }
            let element = match (holder.acceptedCompositeElementFor(state.instanceKey, state.elementKey)) {
                case Some(value) => value
                case None =>
                    stale.add(key)
                    continue
            }
            if (element.ownerTargetResourceId != state.ownerTargetResourceId ||
                element.instanceIncarnation != state.instanceIncarnation) {
                stale.add(key)
                continue
            }
            sync(state, element)
        }
        for (key in stale) {
            if (let Some(state) <- states.get(key)) { state.select.close() }
            states.remove(key)
        }
    }

    /// Keyboard declarations of every OPEN instance popup. The region merges
    /// these into the next candidate scene; each command keeps the popup's
    /// own scope, highlighted-row target and owner writer. No second keyboard
    /// state machine is created here.
    public func commands(): ArrayList<CjguiComposableUiCommand> {
        let result = ArrayList<CjguiComposableUiCommand>()
        for ((_, state) in states) {
            if (!state.select.isOpen()) { continue }
            for (command in state.select.commands()) { result.add(command) }
        }
        return result
    }

    public func closeAll(): Unit {
        for ((_, state) in states) { state.select.close() }
        states.clear()
    }

    /// Test/diagnostic probe: one instance's popup state, never another's.
    public func openQuery(instanceKey: String, elementKey: String): String {
        return match (states.get(stateKey(instanceKey, elementKey))) {
            case Some(state) => if (state.select.isOpen()) { state.select.query() } else { "" }
            case None => ""
        }
    }

    public func highlightedKey(instanceKey: String, elementKey: String): String {
        return match (states.get(stateKey(instanceKey, elementKey))) {
            case Some(state) => if (state.select.isOpen()) { state.select.highlightedKey() } else { "" }
            case None => ""
        }
    }

    public func isOpen(instanceKey: String, elementKey: String): Bool {
        return match (states.get(stateKey(instanceKey, elementKey))) {
            case Some(state) => state.select.isOpen()
            case None => false
        }
    }
}

class CjguiCompositionSelectState {
    let key: String
    let instanceKey: String
    let elementKey: String
    var nodeId: Int64
    var ownerTargetResourceId: Int64
    var instanceIncarnation: Int64
    let select: CjguiSelect

    init(key: String, instanceKey: String, elementKey: String, nodeId: Int64,
        ownerTargetResourceId: Int64, instanceIncarnation: Int64, select: CjguiSelect) {
        this.key = key
        this.instanceKey = instanceKey
        this.elementKey = elementKey
        this.nodeId = nodeId
        this.ownerTargetResourceId = ownerTargetResourceId
        this.instanceIncarnation = instanceIncarnation
        this.select = select
    }
}

/// True when the candidate tree still names `kind`. A definition deletion and
/// the instances that reference it must be settled in the SAME candidate, so a
/// removed definition can never leave a dangling accepted instance.
/// §16: true when a definition REMAINING in the effective set (the staged
/// batch plus accepted definitions, minus every removed or replaced name)
/// references `name` through a `compose=` node. The instance-structure check
/// (`cjguiCompositionReferences`) covers instances; this covers definitions.
public func cjguiCompositionReferencedByDefinitions(catalog: CjguiGeneratedUiCapabilityCatalog,
    batch: ArrayList<CjguiCompositionPayload>, name: String): Bool {
    for (payload in batch) {
        let definition = payload.definition
        if (definition.name == name) { continue }
        var stack = ArrayList<CjguiCompositionTemplateNode>()
        stack.add(definition.template)
        while (stack.size > 0) {
            let node = stack.remove(at: stack.size - 1)
            if (node.composeName == name) { return true }
            for (child in node.children) { stack.add(child) }
        }
    }
    for (definition in catalog.acceptedRuntimeCompositionDefinitions()) {
        if (definition.name == name) { continue }
        var skip = false
        for (batchPayload in batch) {
            if (batchPayload.definition.name == definition.name) { skip = true; break }
        }
        if (skip) { continue }
        var stack = ArrayList<CjguiCompositionTemplateNode>()
        stack.add(definition.template)
        while (stack.size > 0) {
            let node = stack.remove(at: stack.size - 1)
            if (node.composeName == name) { return true }
            for (child in node.children) { stack.add(child) }
        }
    }
    return false
}

public func cjguiCompositionReferences(root: CjguiGeneratedUiNodeSpec, kind: String): Bool {
    if (root.kind == kind) { return true }
    for (child in root.children) {
        if (cjguiCompositionReferences(child, kind)) { return true }
    }
    return false
}

/// Serializes ONE accepted runtime definition in the SAME grammar a candidate
/// submits. The caller (public atomic structure snapshot) publishes these lines
/// beside the nodes/instances accepted with them; an omitted definition simply
/// keeps this text unchanged in the next accepted snapshot.
public func cjguiCompositionDefinitionPayload(definition: CjguiRuntimeCompositionDefinition): String {
    let builder = StringBuilder()
    builder.append("COMPOSITION ${definition.name} ${definition.expandedNodeLimit} " +
        "${definition.expandedDepthLimit}\n")
    for (parameter in definition.parameters) {
        builder.append("CPARAM ${parameter.name} ${parameter.valueType} " +
            "${if (parameter.required) { 1 } else { 0 }} ${parameter.minimum} ${parameter.maximum} " +
            "${parameter.maxLength} ${CjguiGeneratedUiEncoding.encodePropertyValue(parameter.defaultValue)}\n")
    }
    for (element in definition.elements) {
        builder.append("CELEMENT ${element.elementKey} ${element.role}")
        if (element.fieldId.size > 0) { builder.append(" field=${element.fieldId}") }
        if (element.argumentName.size > 0) { builder.append(" argument=${element.argumentName}") }
        if (element.presetValue.size > 0) { builder.append(" preset=${element.presetValue}") }
        if (element.actionName.size > 0) { builder.append(" action=${element.actionName}") }
        if (element.source.size > 0) { builder.append(" source=${element.source}") }
        builder.append(" label=${element.label}\n")
    }
    cjguiCompositionTemplatePayload(definition.template, 0, builder)
    builder.append("COMPOSITION_END ${definition.name}\n")
    return builder.toString()
}

private func cjguiCompositionTemplatePayload(node: CjguiCompositionTemplateNode, depth: Int64,
    builder: StringBuilder): Unit {
    builder.append("CTEMPLATE ${depth} ${node.key} ${node.kind}")
    if (node.kind == CJGUI_COMPOSITION_NODE_COMPOSE && node.composeName.size > 0) {
        builder.append(" compose=${node.composeName}")
    }
    if (node.elementKey.size > 0) { builder.append(" element=${node.elementKey}") }
    if (node.presentation.size > 0) { builder.append(" presentation=${node.presentation}") }
    if (node.styleName.size > 0) { builder.append(" style=${node.styleName}") }
    if (node.gap >= 0) { builder.append(" gap=${node.gap}") }
    if (node.padding >= 0) { builder.append(" padding=${node.padding}") }
    if (node.fixedHeight >= 0) { builder.append(" height=${node.fixedHeight}") }
    if (node.growX >= 0) { builder.append(" grow=${node.growX}") }
    builder.append(" axis=${node.axis} first=${node.firstSize} minfirst=${node.minFirst} " +
        "minsecond=${node.minSecond}")
    if (node.text.size > 0) { builder.append(" text=${node.text}") }
    builder.append("\n")
    for (child in node.children) {
        cjguiCompositionTemplatePayload(child, depth + 1, builder)
    }
}

/// Checks every `${name}` placeholder against the declared parameters. Free
/// text outside placeholders is allowed; an unknown placeholder is a refusal.
private func cjguiCompositionTextIssue(text: String, parameterNames: HashSet<String>): String {
    var index: Int64 = 0
    while (index + 1 < text.size) {
        if (text[index] == 36 && text[index + 1] == 123) {
            var end = index + 2
            while (end < text.size && text[end] != 125) { end += 1 }
            if (end >= text.size) { return "composition_placeholder_unterminated" }
            let name = text[index + 2..end]
            if (!parameterNames.contains(name)) {
                return "composition_unknown_parameter:${name}"
            }
            index = end + 1
        } else {
            index += 1
        }
    }
    return ""
}

private func cjguiCompositionExpandedText(text: String, context: CjguiCompositeBuildContext): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < text.size) {
        if (index + 1 < text.size && text[index] == 36 && text[index + 1] == 123) {
            var end = index + 2
            while (end < text.size && text[end] != 125) { end += 1 }
            if (end < text.size) {
                let name = text[index + 2..end]
                builder.append(context.property(name))
                index = end + 1
                continue
            }
        }
        // Copy one whole UTF-8 rune so substitution can never split a label.
        var next = index + 1
        while (next < text.size && (Int64(text[next]) & 0xC0) == 0x80) { next += 1 }
        builder.append(text[index..next])
        index = next
    }
    return builder.toString()
}

private func cjguiCompositionTemplateStyle(node: CjguiCompositionTemplateNode,
    context: CjguiCompositeBuildContext): CjguiComposableUiStyle {
    let base = match (context.namedStyle(node.styleName)) {
        case Some(style) => style.base
        case None => CjguiComposableUiStyle()
    }
    return CjguiComposableUiStyle(
        background: base.background, border: base.border, textColor: base.textColor,
        padding: if (node.padding >= 0) { node.padding } else { base.padding },
        gap: if (node.gap >= 0) { node.gap } else { base.gap },
        fixedWidth: base.fixedWidth,
        fixedHeight: if (node.fixedHeight >= 0) { node.fixedHeight } else { base.fixedHeight },
        growX: if (node.growX >= 0) { node.growX } else { base.growX },
        growY: base.growY, borderWidth: base.borderWidth, cornerRadius: base.cornerRadius,
        fontSize: base.fontSize, fontWeight: base.fontWeight, minWidth: base.minWidth,
        maxWidth: base.maxWidth, minHeight: base.minHeight, maxHeight: base.maxHeight,
        alignX: base.alignX, alignY: base.alignY, fontFamily: base.fontFamily)
}

private func cjguiCompositionTemplateInteraction(node: CjguiCompositionTemplateNode,
    context: CjguiCompositeBuildContext): CjguiComposableUiInteractionStyle {
    return match (context.namedStyle(node.styleName)) {
        case Some(style) => style.interaction
        case None => CjguiComposableUiInteractionStyle()
    }
}

/// One reference segment appended to an encoded reference path. Both the path
/// and the appended key are length-prefixed, so a key containing ':' or '-' can
/// never produce the same path as a different nesting.
public func cjguiCompositionScopePath(base: String, referenceKey: String): String {
    return "${base.size}:${base}${referenceKey.size}:${referenceKey}"
}

/// Presentation slot of ONE element occurrence. The root keeps the element key
/// alone (single-layer instances preserve their existing slot identities); a
/// nested occurrence carries its unambiguous reference path. 'e:'/'p:' keep
/// element slots disjoint from structural 't:' slots.
public func cjguiCompositionElementSlotKey(path: String, elementKey: String): String {
    if (path.size == 0) { return "e:${elementKey.size}:${elementKey}" }
    return "p:${path}e:${elementKey.size}:${elementKey}"
}

public func cjguiCompositionStructuralSlotKey(path: String, key: String): String {
    if (path.size == 0) { return "t:${key.size}:${key}" }
    return "p:${path}t:${key.size}:${key}"
}

private func cjguiRuntimeDefinitionFor(catalog: CjguiGeneratedUiCapabilityCatalog,
    kind: String): ?CjguiRuntimeCompositionDefinition {
    let factory = match (catalog.compositeFactoryFor(kind)) {
        case Some(value) => value
        case None => return None
    }
    if (let Some(runtime) <- (factory as CjguiRuntimeCompositionFactory)) {
        return Some(runtime.runtimeDefinition())
    }
    return None
}

private func cjguiSafeCompositionAdd(value: Int64, increment: Int64): Int64 {
    if (increment <= 0) { return value }
    if (value > Int64.Max - increment) { return Int64.Max }
    return value + increment
}

private func cjguiCompositionTemplateNodeCost(template: CjguiCompositionTemplateNode): Int64 {
    // A split allocates its own identity and one handle identity.
    if (template.kind == CJGUI_COMPOSITION_NODE_SPLIT) { return 2 }
    return 1
}

private func cjguiCompositionTemplateByteEstimate(template: CjguiCompositionTemplateNode): Int64 {
    return Int64(template.key.size) + Int64(template.elementKey.size) + Int64(template.styleName.size) +
        Int64(template.composeName.size) + Int64(template.text.size)
}

/// Plans one instance's expansion BEFORE the factory allocates anything. The
/// walk follows the SAME runtime references the expander will follow; a
/// compiled (non-runtime) `compose=` target contributes its container only and
/// is left to the post-expansion audit. Counting stops at the first exceeded
/// limit, so an acyclic but wide fan-out cannot drive unbounded planning work.
public func cjguiCompositionExpansionPlan(catalog: CjguiGeneratedUiCapabilityCatalog, kind: String,
    nodeLimit: Int64, depthLimit: Int64): CjguiCompositionExpansionPlan {
    let plan = CjguiCompositionExpansionPlan()
    let definition = match (cjguiRuntimeDefinitionFor(catalog, kind)) {
        case Some(value) => value
        case None =>
            if (catalog.compositeFor(kind).isNone() || catalog.compositeFactoryFor(kind).isNone()) {
                plan.issue = "composite_not_registered"
                return plan
            }
            // A compiled factory has no runtime template to expand. Charge its
            // root exactly as a nested compiled reference does; the existing
            // post-build audit still checks its real subtree and bindings.
            plan.nodes = 1
            plan.maxDepth = 1
            plan.bytes = Int64(kind.size)
            if (nodeLimit < 1) {
                plan.issue = "composite_expansion_node_limit"
            } else if (catalog.maxNodes < 1) {
                plan.issue = "composite_expansion_catalog_limit"
            } else if (depthLimit < 1) {
                plan.issue = "composite_expansion_depth_limit"
            }
            if (plan.issue.isEmpty()) {
                for (element in catalog.compositeFor(kind).getOrThrow().elements) {
                    plan.occurrences.add(CjguiCompositionElementOccurrence("",
                        CJGUI_COMPOSITION_PRESENTATION_TEXT, element))
                }
            }
            return plan
    }
    let chain = HashSet<String>()
    let _ = chain.add(kind)
    cjguiPlanCompositionTemplate(definition, definition.template, "", 1, catalog, nodeLimit, depthLimit,
        plan, chain)
    return plan
}

private func cjguiPlanCompositionTemplate(definition: CjguiRuntimeCompositionDefinition,
    template: CjguiCompositionTemplateNode, path: String, depth: Int64,
    catalog: CjguiGeneratedUiCapabilityCatalog, nodeLimit: Int64, depthLimit: Int64,
    plan: CjguiCompositionExpansionPlan, chain: HashSet<String>): Unit {
    if (plan.issue.size > 0) { return }
    if (template.kind == CJGUI_COMPOSITION_NODE_COMPOSE) {
        let targetName = if (template.composeName.size > 0) { template.composeName } else { template.kind }
        let nestedPath = cjguiCompositionScopePath(path, template.key)
        let nested = cjguiRuntimeDefinitionFor(catalog, targetName)
        if (let Some(target) <- nested) {
            if (!chain.add(targetName)) {
                plan.issue = "composition_reference_cycle:${targetName}"
                return
            }
            // The nested root replaces the reference node in the built tree.
            cjguiPlanCompositionTemplate(target, target.template, nestedPath, depth, catalog, nodeLimit,
                depthLimit, plan, chain)
            let _ = chain.remove(targetName)
            return
        }
        // A compiled factory contributes one container here; its own subtree is
        // still audited after the build, which this pre-check cannot see.
    }
    plan.nodes = cjguiSafeCompositionAdd(plan.nodes, cjguiCompositionTemplateNodeCost(template))
    if (plan.nodes > nodeLimit) {
        plan.issue = "composite_expansion_node_limit"
        return
    }
    if (plan.nodes > catalog.maxNodes) {
        plan.issue = "composite_expansion_catalog_limit"
        return
    }
    if (depth > depthLimit) {
        plan.issue = "composite_expansion_depth_limit"
        return
    }
    if (depth > plan.maxDepth) { plan.maxDepth = depth }
    plan.bytes = cjguiSafeCompositionAdd(plan.bytes, cjguiCompositionTemplateByteEstimate(template))
    if (plan.bytes > CJGUI_COMPOSITION_EXPANSION_MAX_BYTES) {
        plan.issue = "composite_expansion_byte_limit"
        return
    }
    if (template.kind == CJGUI_COMPOSITION_NODE_ELEMENT) {
        let element = match (definition.elementFor(template.elementKey)) {
            case Some(value) => value
            case None =>
                plan.issue = "composition_unknown_element:${template.elementKey}"
                return
        }
        plan.bytes = cjguiSafeCompositionAdd(plan.bytes,
            Int64(element.label.size) + Int64(element.source.size) + Int64(element.presetValue.size))
        if (plan.bytes > CJGUI_COMPOSITION_EXPANSION_MAX_BYTES) {
            plan.issue = "composite_expansion_byte_limit"
            return
        }
        plan.occurrences.add(CjguiCompositionElementOccurrence(path, template.presentation, element))
        return
    }
    for (child in template.children) {
        cjguiPlanCompositionTemplate(definition, child, path, depth + 1, catalog, nodeLimit, depthLimit,
            plan, chain)
    }
}

/// The generic expander. It mounts the definition's tree with the framework's
/// allocated element identities; every structural node has no independent
/// identity, exactly like the existing application factories.
class CjguiRuntimeCompositionFactory <: CjguiCompositeComponentFactory {
    private let definition: CjguiRuntimeCompositionDefinition
    /// The catalog this definition was staged into. A `compose=` node expands
    /// the CURRENT accepted/staged factory of the named composition from the
    /// SAME directory, so a definition update reaches nested instances too.
    private let catalog: CjguiGeneratedUiCapabilityCatalog

    init(definition: CjguiRuntimeCompositionDefinition, catalog!: CjguiGeneratedUiCapabilityCatalog) {
        this.definition = definition
        this.catalog = catalog
    }

    /// The declaration this factory expands. The catalog publishes it in the
    /// same accepted snapshot as the instances; no second registry is created.
    public func runtimeDefinition(): CjguiRuntimeCompositionDefinition {
        return definition
    }

    /// A nested definition expands inside the SAME outer instance, so its
    /// template keys need the reference path as well: without it panel→card→
    /// fieldGroup all allocate an outer-instance `root` slot and the scene
    /// rejects the expansion as `composite_duplicate_node_id`.
    private func compositionSlot(semanticBase: String, key: String): String {
        return cjguiCompositionStructuralSlotKey(semanticBase, key)
    }

    private func mount(template: CjguiCompositionTemplateNode, context: CjguiCompositeBuildContext,
        semanticBase: String): CjguiComposableUiNode {
        let kind = template.kind
        if (kind == CJGUI_COMPOSITION_NODE_ELEMENT) {
            return mountElement(template, context, semanticBase)
        }
        if (kind == CJGUI_COMPOSITION_NODE_COMPOSE) {
            return mountCompositionReference(template, context, semanticBase)
        }
        // Every structural node gets a framework-allocated instance identity;
        // the factory never invents one, and the audit counts it.
        let identity = context.allocate(compositionSlot(semanticBase, template.key))
        let style = cjguiCompositionTemplateStyle(template, context)
        if (kind == CJGUI_COMPOSITION_NODE_LABEL) {
            return cjguiComposableText(identity.nodeId, identity.semanticId,
                cjguiCompositionExpandedText(template.text, context), style)
        }
        if (kind == CJGUI_COMPOSITION_NODE_SPACER) {
            return cjguiComposableSpacer(identity.nodeId, identity.semanticId,
                grow: if (template.growX > 0) { template.growX } else { 1 })
        }
        if (kind == CJGUI_COMPOSITION_NODE_CHILDREN) {
            let holder = cjguiComposableVertical(identity.nodeId, identity.semanticId, style)
            for (child in context.children) { holder.add(child) }
            return holder
        }
        if (kind == CJGUI_COMPOSITION_NODE_SPLIT) {
            let first = if (template.children.size > 0) {
                mount(template.children[0], context, semanticBase)
            } else {
                let empty = context.allocate(compositionSlot(semanticBase, "${template.key}-empty"))
                cjguiComposableSpacer(empty.nodeId, empty.semanticId)
            }
            let second = if (template.children.size > 1) {
                mount(template.children[1], context, semanticBase)
            } else {
                let empty = context.allocate(compositionSlot(semanticBase, "${template.key}-empty2"))
                cjguiComposableSpacer(empty.nodeId, empty.semanticId)
            }
            let axis = if (template.axis == "vertical") {
                CjguiComposableUiSplitAxis.VERTICAL
            } else {
                CjguiComposableUiSplitAxis.HORIZONTAL
            }
            // The numeric split builder derives its handle id as nodeId + 2,
            // which can collide with ANOTHER allocated slot of this instance.
            // Every template node receives its own allocated identity, so the
            // handle is allocated the same way instead of claiming a range.
            let handle = context.allocate(compositionSlot(semanticBase, "${template.key}-handle"))
            return cjguiComposableSplitView(identity.nodeId, identity.semanticId, first, second, axis,
                template.firstSize, template.minFirst, template.minSecond, style, handleNodeId: handle.nodeId)
        }
        let container = if (kind == CJGUI_COMPOSITION_NODE_HORIZONTAL) {
            cjguiComposableHorizontal(identity.nodeId, identity.semanticId, style)
        } else if (kind == CJGUI_COMPOSITION_NODE_WRAP) {
            cjguiComposableWrap(identity.nodeId, identity.semanticId, style)
        } else {
            cjguiComposableVertical(identity.nodeId, identity.semanticId, style)
        }
        for (child in template.children) {
            container.add(mount(child, context, semanticBase))
        }
        return container
    }

    /// The value a choice presentation must compare against its option set.
    /// BOOLEAN fields keep their draft in `draftBoolean`; their `draftText` is
    /// empty for a provider that publishes no string projection, so reading only
    /// `draftText` made every boolean trigger read "请选择" and highlighted no
    /// radio row even when the owner value was already set.
    private func elementDraftValue(element: CjguiCompositeElementBinding): String {
        if (element.editorKind == "BOOLEAN") {
            return if (element.draftBoolean) { "true" } else { "false" }
        }
        return element.draftText
    }

    /// §16: expands a `compose=<name>` node through the named composition's
    /// CURRENT factory from the SAME catalog, under THIS instance's context.
    /// The nested expansion therefore resolves fields/actions/owners through
    /// the ordinary element bindings of the outer instance: two instances of
    /// the referencing definition keep separate owners, drafts and identities
    /// because every allocated identity and element binding still belongs to
    /// the outer (instanceKey) scope. The referenced factory itself enforces
    /// its own node/depth budget for its subtree.
    private func mountCompositionReference(template: CjguiCompositionTemplateNode,
        context: CjguiCompositeBuildContext, semanticBase: String): CjguiComposableUiNode {
        let targetName = if (template.composeName.size > 0) { template.composeName } else { template.kind }
        let factory = match (catalog.compositeFactoryFor(targetName)) {
            case Some(value) => value
            case None =>
                let missing = context.allocate(compositionSlot(semanticBase, "${template.key}-compose-missing"))
                return cjguiComposableSpacer(missing.nodeId, missing.semanticId)
        }
        // The reference path uses the SAME encoding the pre-expansion plan
        // records for element occurrences. A structural SLOT key is not a path:
        // using it here made every nested lookup miss and fall back to the
        // definition's first element, so two references could not allocate
        // distinct presentation identities.
        let nestedBase = cjguiCompositionScopePath(semanticBase, template.key)
        let runtime = factory as CjguiRuntimeCompositionFactory
        if (let Some(value) <- runtime) {
            // Same-catalog runtime definitions expand inline so the nested
            // tree keeps allocating from THIS instance's allocator/identity
            // scope (no second component instance, no separate element table).
            return value.mount(value.definition.template, context, nestedBase)
        }
        let identity = context.allocate(nestedBase)
        let style = cjguiCompositionTemplateStyle(template, context)
        let nested = factory.buildComposite(context)
        let container = cjguiComposableVertical(identity.nodeId, identity.semanticId, style)
        container.add(nested)
        return container
    }

    private func mountElement(template: CjguiCompositionTemplateNode,
        context: CjguiCompositeBuildContext, semanticBase: String): CjguiComposableUiNode {
        // Occurrence-scoped lookup: two legal references to the same declaration
        // mount two presentation identities bound to the SAME owner element.
        let element = match (context.elementAt(semanticBase, template.elementKey)) {
            case Some(value) => value
            case None => return cjguiComposableSpacer(-1, "${semanticBase}-${template.key}-missing")
        }
        let style = cjguiCompositionTemplateStyle(template, context)
        let interaction = cjguiCompositionTemplateInteraction(template, context)
        if (element.role == CJGUI_COMPOSITE_ELEMENT_PROJECTION) {
            return cjguiComposableText(element.nodeId, element.semanticId, element.projectionText, style)
        }
        if (element.role == CJGUI_COMPOSITE_ELEMENT_ACTION) {
            return cjguiComposableButton(element.nodeId, element.semanticId,
                if (template.text.size > 0) { cjguiCompositionExpandedText(template.text, context) } else { element.label },
                "GENERATED_ACTION", element.bindingResourceId, style, enabled: element.actionEnabled,
                operationResourceId: element.ownerTargetResourceId, interactionStyle: interaction,
                semanticHelp: if (element.actionEnabled) { "" } else { element.blockedReason })
        }
        if (element.role == CJGUI_COMPOSITE_ELEMENT_PRESET) {
            return cjguiComposableButton(element.nodeId, element.semanticId, element.label,
                "GENERATED_ACTION", element.bindingResourceId, style, enabled: element.ownerAvailable,
                operationActionName: element.writerOperation,
                operationResourceId: element.ownerTargetResourceId, interactionStyle: interaction,
                semanticHelp: if (element.ownerAvailable) { "" } else { element.blockedReason })
        }
        if (element.role != CJGUI_COMPOSITE_ELEMENT_FIELD) {
            return cjguiComposableVertical(element.nodeId, element.semanticId, style)
        }
        // Choice presentations render from the element's OWN accepted option
        // set and selected value. They never borrow the single-owner Select
        // controller: its commit closure belongs to one owner, so reusing it
        // for an instance would write the wrong object. An activation resolves
        // back through the holder into THIS element's accepted writer instead.
        let presentation = template.presentation
        if (presentation == CJGUI_COMPOSITION_PRESENTATION_RADIO ||
            presentation == CJGUI_COMPOSITION_PRESENTATION_SEGMENTED) {
            // The ELEMENT node itself must carry the accepted field binding: the
            // composite audit checks every declared element node against the
            // resolved field/writer/target/resource. The rows below are dynamic
            // children, and the holder resolves their activation through this
            // same accepted element binding.
            let container = CjguiComposableUiNode(element.nodeId, element.semanticId, CJGUI_COMPOSABLE_UI_VERTICAL,
                "", "", "", element.bindingResourceId, CjguiComposableUiStyle(gap: 4, growX: 1),
                enabled: element.ownerAvailable, fieldId: element.fieldId,
                operationActionName: element.writerOperation, operationResourceId: element.ownerTargetResourceId,
                displayValueRole: "draft", interactionStyle: interaction)
            let label = context.allocate(compositionSlot(semanticBase, "${template.key}-label"))
            container.add(cjguiComposableText(label.nodeId, "${element.semanticId}-label", element.label,
                CjguiComposableUiStyle(fixedHeight: 18, fontSize: 11.5, textColor: style.textColor)))
            if (element.choiceOptions.size == 0) {
                let empty = context.allocate(compositionSlot(semanticBase, "${template.key}-empty"))
                container.add(cjguiComposableText(empty.nodeId, "${element.semanticId}-empty", "没有可选项",
                    CjguiComposableUiStyle(fixedHeight: 26, growX: 1, textColor: style.textColor)))
                return container
            }
            let optionsRow = context.allocate(compositionSlot(semanticBase, "${template.key}-options"))
            let unmatched = context.allocate(compositionSlot(semanticBase, "${template.key}-unmatched"))
            let group = context.allocate(compositionSlot(semanticBase, "${template.key}-group"))
            let options = ArrayList<CjguiChoiceOption>()
            for (option in element.choiceOptions) {
                let rowIdentity = context.allocate(compositionSlot(semanticBase,
                    "${template.key}-option-${option.key}"))
                options.add(CjguiChoiceOption(option.key, rowIdentity.nodeId, option.label, option.value,
                    "${element.semanticId}${CJGUI_SELECT_CHOOSE_SUFFIX}${option.key}",
                    semanticId: "${element.semanticId}-option-${option.key}",
                    enabled: option.enabled && element.ownerAvailable,
                    disabledReason: if (!element.ownerAvailable) { element.blockedReason } else {
                        option.disabledReason
                    }))
            }
            let choiceStyle: ?CjguiChoiceGroupStyle = if (template.styleName.size > 0 ||
                template.padding >= 0 || template.fixedHeight > 0) {
                Some(CjguiChoiceGroupStyleTheme.fromResolvedStyle(style, interaction: interaction))
            } else {
                None
            }
            let resolvedChoiceStyle = match (choiceStyle) {
                case Some(value) => value
                case None => CjguiChoiceGroupStyle()
            }
            container.add(CjguiChoiceGroup.build(group.nodeId, "${element.semanticId}-group", optionsRow.nodeId,
                options, elementDraftValue(element), unmatched.nodeId, style: resolvedChoiceStyle, radioSemantics: true,
                verticalRows: presentation == CJGUI_COMPOSITION_PRESENTATION_RADIO))
            return container
        }
        if (presentation == CJGUI_COMPOSITION_PRESENTATION_SELECT) {
            // The trigger is ordinary presentation. Popup/query/highlight live
            // in the per-instance host (CjguiCompositionSelectHost); the write
            // resolves through this element's accepted binding, never through
            // the handwritten single-owner commit closure.
            var selected = elementDraftValue(element)
            for (option in element.choiceOptions) {
                if (option.value == selected) {
                    selected = option.label
                    break
                }
            }
            let label = "${element.label}：${if (selected.size > 0) { selected } else { "请选择" }}  ▾"
            return CjguiComposableUiNode(element.nodeId, element.semanticId, CJGUI_COMPOSABLE_UI_BUTTON,
                label, label, "${element.semanticId}-select-toggle", element.bindingResourceId, style,
                enabled: element.ownerAvailable, fieldId: element.fieldId,
                operationActionName: element.writerOperation, operationResourceId: element.ownerTargetResourceId,
                displayValueRole: "draft", interactionStyle: interaction,
                semanticRole: CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON, semanticLabel: label,
                semanticHelp: if (element.ownerAvailable) { "" } else { element.blockedReason },
                semanticExpandable: true)
        }
        if (element.editorKind == "BOOLEAN") {
            return cjguiComposableBooleanInput(element.nodeId, element.semanticId, element.label,
                element.draftBoolean, element.bindingResourceId, style, enabled: element.ownerAvailable,
                fieldId: element.fieldId, operationActionName: element.writerOperation,
                operationResourceId: element.ownerTargetResourceId, displayValueRole: "draft",
                interactionStyle: interaction)
        }
        if (element.editorKind == "INTEGER") {
            return cjguiComposableIntegerInput(element.nodeId, element.semanticId, element.label,
                element.draftText, element.bindingResourceId, style, enabled: element.ownerAvailable,
                fieldId: element.fieldId, operationActionName: element.writerOperation,
                operationResourceId: element.ownerTargetResourceId, displayValueRole: "draft",
                interactionStyle: interaction)
        }
        return cjguiComposableTextInput(element.nodeId, element.semanticId, element.label, element.draftText,
            element.bindingResourceId, style, enabled: element.ownerAvailable, fieldId: element.fieldId,
            operationActionName: element.writerOperation, operationResourceId: element.ownerTargetResourceId,
            displayValueRole: "draft", interactionStyle: interaction)
    }

    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        // The reference path is relative to the definition root; the instance
        // allocator already scopes identities per instance.
        return mount(definition.template, context, "")
    }
}

/// One decoded definition, ready to be staged by the region.
public class CjguiCompositionPayload {
    public let definition: CjguiRuntimeCompositionDefinition

    public init(definition: CjguiRuntimeCompositionDefinition) {
        this.definition = definition
    }
}

/// Every element declaration an INSTANCE of `kind` can mount, in expansion
/// order: the kind's own elements first, then each `compose=` target's, depth
/// first. An inline nested composition binds its fields/actions through the
/// OUTER instance context, so the outer instance must allocate those element
/// identities too. Without this union a nested `element=` node had no
/// allocated identity and the expansion was refused as
/// `composite_unidentified_node`.
///
/// Keys are deduplicated: the same declaration reached through several
/// references is ONE binding of this instance. cjguiStageRuntimeCompositions
/// refuses two DIFFERENT declarations sharing a key, so a duplicate here can
/// never silently pick one meaning over another.
public func cjguiEffectiveCompositeElements(catalog: CjguiGeneratedUiCapabilityCatalog,
    kind: String): ArrayList<CjguiCompositeElementSpec> {
    let result = ArrayList<CjguiCompositeElementSpec>()
    let seen = HashSet<String>()
    let visited = HashSet<String>()
    cjguiCollectCompositeElements(catalog, kind, result, seen, visited)
    return result
}

private func cjguiCollectCompositeElements(catalog: CjguiGeneratedUiCapabilityCatalog, kind: String,
    result: ArrayList<CjguiCompositeElementSpec>, seen: HashSet<String>, visited: HashSet<String>): Unit {
    if (!visited.add(kind)) { return }
    let spec = match (catalog.compositeFor(kind)) {
        case Some(value) => value
        case None => return
    }
    for (element in spec.elements) {
        if (seen.add(element.elementKey)) { result.add(element) }
    }
    let factory = match (catalog.compositeFactoryFor(kind)) {
        case Some(value) => value
        case None => return
    }
    let runtime = factory as CjguiRuntimeCompositionFactory
    if (let Some(value) <- runtime) {
        cjguiCollectTemplateElements(value.runtimeDefinition().template, catalog, result, seen, visited)
    }
}

private func cjguiCollectTemplateElements(template: CjguiCompositionTemplateNode,
    catalog: CjguiGeneratedUiCapabilityCatalog, result: ArrayList<CjguiCompositeElementSpec>,
    seen: HashSet<String>, visited: HashSet<String>): Unit {
    if (template.composeName.size > 0) {
        cjguiCollectCompositeElements(catalog, template.composeName, result, seen, visited)
    }
    for (child in template.children) {
        cjguiCollectTemplateElements(child, catalog, result, seen, visited)
    }
}

/// Refuses two DIFFERENT declarations that share one element key anywhere in a
/// definition's reachable set. The outer instance context is keyed by element
/// key, so such a pair would make one declaration shadow the other; the
/// candidate is refused instead. The same declaration reached twice (two
/// references to one composition) is legal.
public func cjguiCompositionElementKeyConflict(catalog: CjguiGeneratedUiCapabilityCatalog,
    definition: CjguiRuntimeCompositionDefinition): String {
    let byKey = HashMap<String, CjguiCompositeElementSpec>()
    let visited = HashSet<String>()
    var stack = ArrayList<String>()
    stack.add(definition.name)
    while (stack.size > 0) {
        let kind = stack.remove(at: stack.size - 1)
        if (!visited.add(kind)) { continue }
        let spec = match (catalog.compositeFor(kind)) {
            case Some(value) => value
            case None => continue
        }
        for (element in spec.elements) {
            if (let Some(existing) <- byKey.get(element.elementKey)) {
                if (!cjguiSameCompositeElement(existing, element)) {
                    return "composition_rejected:composition_element_key_conflict:${definition.name}:" +
                        element.elementKey
                }
            } else {
                byKey.add(element.elementKey, element)
            }
        }
        let factory = match (catalog.compositeFactoryFor(kind)) {
            case Some(value) => value
            case None => continue
        }
        let runtime = factory as CjguiRuntimeCompositionFactory
        if (let Some(value) <- runtime) {
            var refs = ArrayList<CjguiCompositionTemplateNode>()
            refs.add(value.runtimeDefinition().template)
            while (refs.size > 0) {
                let template = refs.remove(at: refs.size - 1)
                if (template.composeName.size > 0) { stack.add(template.composeName) }
                for (child in template.children) { refs.add(child) }
            }
        }
    }
    return ""
}

private func cjguiSameCompositeElement(left: CjguiCompositeElementSpec,
    right: CjguiCompositeElementSpec): Bool {
    return left.elementKey == right.elementKey && left.role == right.role &&
        left.fieldId == right.fieldId && left.argumentName == right.argumentName &&
        left.presetValue == right.presetValue && left.actionName == right.actionName &&
        left.source == right.source && left.label == right.label &&
        left.parentKey == right.parentKey
}

/// One parsed definition section from a structure payload. A payload without
/// a `COMPOSITION` line is still a legal ordinary structure submission.
public class CjguiCompositionDecodeResult {
    public let ok: Bool
    public let reason: String
    /// Single-definition view kept for the legacy no-END spelling. It is set
    /// only when the payload carried exactly one definition; a multi-definition
    /// payload must be consumed through `definitions`.
    public let definition: ?CjguiRuntimeCompositionDefinition
    /// Every definition section of ONE candidate, in submission order.
    public let definitions: ArrayList<CjguiRuntimeCompositionDefinition>
    /// Explicit deletions submitted with this candidate. They are applied to
    /// the accepted directory only when the same candidate is accepted.
    public let removals: ArrayList<String>

    public init(ok: Bool, reason: String, definition: ?CjguiRuntimeCompositionDefinition,
        removals!: ArrayList<String> = ArrayList<String>(),
        definitions!: ArrayList<CjguiRuntimeCompositionDefinition> =
            ArrayList<CjguiRuntimeCompositionDefinition>()) {
        this.ok = ok
        this.reason = reason
        this.definition = definition
        this.definitions = if (definitions.size > 0) {
            definitions
        } else if (let Some(value) <- definition) {
            let single = ArrayList<CjguiRuntimeCompositionDefinition>()
            single.add(value)
            single
        } else {
            ArrayList<CjguiRuntimeCompositionDefinition>()
        }
        this.removals = removals
    }
}

private func cjguiCompositionTokenValue(tokens: ArrayList<String>, prefix: String): String {
    for (token in tokens) {
        if (token.startsWith(prefix)) { return token[prefix.size..token.size] }
    }
    return ""
}

private func cjguiCompositionHasToken(tokens: ArrayList<String>, prefix: String): Bool {
    for (token in tokens) {
        if (token.startsWith(prefix)) { return true }
    }
    return false
}

/// Present-and-invalid is NOT the same as absent: an explicit `gap=x` must be
/// refused instead of silently becoming "inherit". Absent returns (false, -1).
private func cjguiCompositionOptionalInteger(tokens: ArrayList<String>, prefix: String): (Bool, Int64) {
    for (token in tokens) {
        if (token.startsWith(prefix)) {
            let text = token[prefix.size..token.size]
            if (text.size == 0) { return (true, -1) }
            return (true, cjguiCompositionStrictInteger(text) ?? -1)
        }
    }
    return (false, -1)
}

private func cjguiCompositionTrailingValue(line: String, token: String): String {
    let marker = " " + token
    let index = line.indexOf(marker)
    if (let Some(start) <- index) {
        return line[start + marker.size..line.size]
    }
    return ""
}

private func cjguiCompositionStrictInteger(value: String): ?Int64 {
    return parseGeneratedInteger(value)
}

private func cjguiCompositionTemplateNodeCount(node: CjguiCompositionTemplateNode): Int64 {
    var count: Int64 = 1
    for (child in node.children) { count += cjguiCompositionTemplateNodeCount(child) }
    return count
}

/// Parses the optional definition section of `GENERATED_UI_STRUCTURE 2`.
///
/// A candidate may carry SEVERAL complete definition sections in one ticket.
/// Sections are split on `COMPOSITION`; every section but the final legacy
/// single-definition spelling must be closed by `COMPOSITION_END`. Duplicate
/// names, a name defined and removed in the same ticket, and the aggregate
/// budgets are refused before anything is staged, so no prefix of a batch can
/// become accepted on its own.
public func cjguiRuntimeCompositionDecode(lines: ArrayList<String>): CjguiCompositionDecodeResult {
    let sections = ArrayList<ArrayList<String>>()
    let removals = ArrayList<String>()
    var current = ArrayList<String>()
    var currentName = ""
    var currentClosed = false
    for (line in lines) {
        if (line.size == 0) { continue }
        let fields = ArrayList<String>(line.split(" "))
        if (fields[0] == "COMPOSITION") {
            if (current.size > 0) {
                if (!currentClosed) {
                    return CjguiCompositionDecodeResult(false, "composition_end_missing:${currentName}", None)
                }
                sections.add(current)
                current = ArrayList<String>()
                currentClosed = false
            }
            current.add(line)
            currentName = if (fields.size >= 2) { fields[1] } else { "" }
            continue
        }
        if (fields[0] == "COMPOSITION_REMOVE") {
            if (current.size > 0 && !currentClosed) {
                return CjguiCompositionDecodeResult(false, "composition_end_missing:${currentName}", None)
            }
            if (current.size > 0) {
                sections.add(current)
                current = ArrayList<String>()
                currentClosed = false
            }
            if (fields.size != 2 || fields[1].size == 0) {
                return CjguiCompositionDecodeResult(false, "malformed_composition_remove", None)
            }
            for (existing in removals) {
                if (existing == fields[1]) {
                    return CjguiCompositionDecodeResult(false, "composition_remove_duplicate", None)
                }
            }
            removals.add(fields[1])
            continue
        }
        if (fields[0] == "CPARAM" || fields[0] == "CELEMENT" || fields[0] == "CTEMPLATE" ||
            fields[0] == "COMPOSITION_END") {
            current.add(line)
            if (fields[0] == "COMPOSITION_END") { currentClosed = true }
            continue
        }
        // NODE/PROPERTY/END belong to the structure decoder; they are neither
        // definition content nor a supported definition line here.
    }
    if (current.size > 0) {
        // Only the very first section may use the legacy no-END spelling.
        if (!currentClosed && sections.size > 0) {
            return CjguiCompositionDecodeResult(false, "composition_end_missing:${currentName}", None)
        }
        sections.add(current)
    }
    if (sections.size > CJGUI_COMPOSITION_CANDIDATE_MAX_DEFINITIONS) {
        return CjguiCompositionDecodeResult(false, "composition_definition_budget", None)
    }
    let definitions = ArrayList<CjguiRuntimeCompositionDefinition>()
    let names = HashSet<String>()
    var totalElements: Int64 = 0
    var totalNodes: Int64 = 0
    for (section in sections) {
        let decoded = cjguiRuntimeCompositionDecodeSection(section)
        if (!decoded.ok) { return decoded }
        let definition = match (decoded.definition) {
            case Some(value) => value
            case None => return CjguiCompositionDecodeResult(false, "composition_missing_template", None)
        }
        if (!names.add(definition.name)) {
            return CjguiCompositionDecodeResult(false, "composition_duplicate_name:${definition.name}", None)
        }
        totalElements += definition.elements.size
        totalNodes += cjguiCompositionTemplateNodeCount(definition.template)
        if (totalElements > CJGUI_COMPOSITION_CANDIDATE_MAX_ELEMENTS) {
            return CjguiCompositionDecodeResult(false, "composition_element_budget:candidate", None)
        }
        if (totalNodes > CJGUI_COMPOSITION_CANDIDATE_MAX_TEMPLATE_NODES) {
            return CjguiCompositionDecodeResult(false, "composition_template_node_budget:candidate", None)
        }
        definitions.add(definition)
    }
    for (removed in removals) {
        for (definition in definitions) {
            if (definition.name == removed) {
                return CjguiCompositionDecodeResult(false, "composition_remove_and_define:${removed}", None)
            }
        }
    }
    let single: ?CjguiRuntimeCompositionDefinition = if (definitions.size == 1) {
        Some(definitions[0])
    } else {
        None
    }
    return CjguiCompositionDecodeResult(true, "", single, removals: removals,
        definitions: definitions)
}

/// One definition section. Every count, depth, reference and value type is
/// checked while parsing, so a malformed definition never yields a partial tree.
private func cjguiRuntimeCompositionDecodeSection(lines: ArrayList<String>): CjguiCompositionDecodeResult {
    var name = ""
    var nodeLimit: Int64 = 64
    var depthLimit: Int64 = 6
    var headerSeen = false
    var endSeen = false
    let parameters = ArrayList<CjguiCompositionParameter>()
    let elements = ArrayList<CjguiCompositeElementSpec>()
    let removals = ArrayList<String>()
    let templateRoots = ArrayList<ArrayList<CjguiCompositionTemplateNode>>()
    let templateNodes = ArrayList<(Int64, CjguiCompositionTemplateNode)>()
    for (line in lines) {
        if (line.size == 0) { continue }
        let fields = ArrayList<String>(line.split(" "))
        if (fields[0] == "COMPOSITION") {
            if (headerSeen) { return CjguiCompositionDecodeResult(false, "duplicate_composition", None) }
            if (fields.size < 4) { return CjguiCompositionDecodeResult(false, "malformed_composition", None) }
            headerSeen = true
            endSeen = false
            name = fields[1]
            nodeLimit = cjguiCompositionStrictInteger(fields[2]) ?? -1
            depthLimit = cjguiCompositionStrictInteger(fields[3]) ?? -1
            if (name.size == 0 || nodeLimit <= 0 || depthLimit <= 0) {
                return CjguiCompositionDecodeResult(false, "malformed_composition", None)
            }
        } else if (fields[0] == "COMPOSITION_REMOVE") {
            if (fields.size != 2 || fields[1].size == 0) {
                return CjguiCompositionDecodeResult(false, "malformed_composition_remove", None)
            }
            for (existing in removals) {
                if (existing == fields[1]) {
                    return CjguiCompositionDecodeResult(false, "composition_remove_duplicate", None)
                }
            }
            removals.add(fields[1])
        } else if (fields[0] == "COMPOSITION_END") {
            // Old candidates may omit END; an accepted snapshot always emits
            // it. When present it must close THIS definition exactly once and
            // nothing in the definition may follow it. A marker with the wrong
            // name is not a boundary for the definition being decoded.
            if (!headerSeen) {
                return CjguiCompositionDecodeResult(false, "composition_end_without_header", None)
            }
            if (fields.size != 2 || fields[1].size == 0) {
                return CjguiCompositionDecodeResult(false, "malformed_composition_end", None)
            }
            if (endSeen) {
                return CjguiCompositionDecodeResult(false, "duplicate_composition_end", None)
            }
            if (fields[1] != name) {
                return CjguiCompositionDecodeResult(false, "composition_end_name_mismatch:${fields[1]}", None)
            }
            endSeen = true
        } else if (fields[0] == "CPARAM") {
            if (!headerSeen) { return CjguiCompositionDecodeResult(false, "composition_param_without_header", None) }
            if (endSeen) {
                return CjguiCompositionDecodeResult(false, "composition_content_after_end", None)
            }
            if (parameters.size >= CJGUI_COMPOSITION_MAX_PARAMETERS) {
                return CjguiCompositionDecodeResult(false, "composition_parameter_budget", None)
            }
            if (fields.size < 8) { return CjguiCompositionDecodeResult(false, "malformed_composition_param", None) }
            // A default with a space splits into more fields. Extra content
            // has the same wire shape. Neither may be truncated to fields[7].
            if (fields.size != 8) {
                return CjguiCompositionDecodeResult(false,
                    "composition_parameter_extra_tokens:${fields[1]}", None)
            }
            if (fields[1].size == 0 || !cjguiCompositionSingleToken(fields[1])) {
                return CjguiCompositionDecodeResult(false, "malformed_composition_param", None)
            }
            if (fields[3] != "0" && fields[3] != "1") {
                return CjguiCompositionDecodeResult(false, "malformed_composition_param", None)
            }
            let required = fields[3] == "1"
            let minimum = cjguiCompositionStrictInteger(fields[4]) ?? -1
            let maximum = cjguiCompositionStrictInteger(fields[5]) ?? -1
            let maxLength = cjguiCompositionStrictInteger(fields[6]) ?? -1
            if (minimum < 0 || maximum < minimum || maxLength <= 0) {
                return CjguiCompositionDecodeResult(false, "malformed_composition_param", None)
            }
            let defaultToken = fields[7]
            let defaultValue = CjguiGeneratedUiEncoding.decodePropertyValue(defaultToken)
            // Only tokens the shared property encoder can reproduce are
            // accepted. A lone backslash is the concrete case: it decodes to
            // empty and would re-encode as `\e`, so it is not representable.
            if (CjguiGeneratedUiEncoding.encodePropertyValue(defaultValue) != defaultToken) {
                return CjguiCompositionDecodeResult(false,
                    "composition_parameter_default_not_representable:${fields[1]}", None)
            }
            parameters.add(CjguiCompositionParameter(fields[1], fields[2], required: required,
                maxLength: maxLength, minimum: minimum, maximum: maximum,
                defaultValue: defaultValue))
        } else if (fields[0] == "CELEMENT") {
            if (!headerSeen) { return CjguiCompositionDecodeResult(false, "composition_element_without_header", None) }
            if (endSeen) {
                return CjguiCompositionDecodeResult(false, "composition_content_after_end", None)
            }
            if (elements.size >= CJGUI_COMPOSITION_MAX_ELEMENTS) {
                return CjguiCompositionDecodeResult(false, "composition_element_budget", None)
            }
            if (fields.size < 3) { return CjguiCompositionDecodeResult(false, "malformed_composition_element", None) }
            elements.add(CjguiCompositeElementSpec(fields[1], fields[2],
                fieldId: cjguiCompositionTokenValue(fields, "field="),
                argumentName: cjguiCompositionTokenValue(fields, "argument="),
                presetValue: cjguiCompositionTokenValue(fields, "preset="),
                actionName: cjguiCompositionTokenValue(fields, "action="),
                source: cjguiCompositionTokenValue(fields, "source="),
                label: cjguiCompositionTrailingValue(line, "label=")))
        } else if (fields[0] == "CTEMPLATE") {
            if (!headerSeen) { return CjguiCompositionDecodeResult(false, "composition_template_without_header", None) }
            if (endSeen) {
                return CjguiCompositionDecodeResult(false, "composition_content_after_end", None)
            }
            if (fields.size < 4) { return CjguiCompositionDecodeResult(false, "malformed_composition_template", None) }
            let depth = cjguiCompositionStrictInteger(fields[1]) ?? -1
            if (depth < 0 || depth > CJGUI_COMPOSITION_MAX_TEMPLATE_DEPTH) {
                return CjguiCompositionDecodeResult(false, "composition_template_depth", None)
            }
            // A present property is validated as written. Silent defaults for
            // a malformed gap/axis/size would let an invalid declaration look
            // like a legal one and change the expanded layout behind the
            // caller's back.
            let (gapSeen, gapValue) = cjguiCompositionOptionalInteger(fields, "gap=")
            let (paddingSeen, paddingValue) = cjguiCompositionOptionalInteger(fields, "padding=")
            let (heightSeen, heightValue) = cjguiCompositionOptionalInteger(fields, "height=")
            let (growSeen, growValue) = cjguiCompositionOptionalInteger(fields, "grow=")
            let (firstSeen, firstValue) = cjguiCompositionOptionalInteger(fields, "first=")
            let (minFirstSeen, minFirstValue) = cjguiCompositionOptionalInteger(fields, "minfirst=")
            let (minSecondSeen, minSecondValue) = cjguiCompositionOptionalInteger(fields, "minsecond=")
            if ((gapSeen && gapValue < 0) || (paddingSeen && paddingValue < 0) ||
                (heightSeen && heightValue < 0) || (growSeen && growValue < 0) ||
                (firstSeen && firstValue < 0) || (minFirstSeen && minFirstValue < 0) ||
                (minSecondSeen && minSecondValue < 0)) {
                return CjguiCompositionDecodeResult(false, "malformed_composition_template_value", None)
            }
            let axis = if (cjguiCompositionHasToken(fields, "axis=")) {
                cjguiCompositionTokenValue(fields, "axis=")
            } else {
                "horizontal"
            }
            if (axis != "horizontal" && axis != "vertical") {
                return CjguiCompositionDecodeResult(false, "composition_template_axis", None)
            }
            let presentation = cjguiCompositionTokenValue(fields, "presentation=")
            if (cjguiCompositionHasToken(fields, "presentation=") && presentation.size == 0) {
                return CjguiCompositionDecodeResult(false, "composition_template_presentation", None)
            }
            let styleName = cjguiCompositionTokenValue(fields, "style=")
            if (cjguiCompositionHasToken(fields, "style=") && styleName.size == 0) {
                return CjguiCompositionDecodeResult(false, "composition_template_style", None)
            }
            var composeName = cjguiCompositionTokenValue(fields, "compose=")
            if (fields[3] == CJGUI_COMPOSITION_NODE_COMPOSE) {
                // The wire form for a nested reference: kind `composition` MUST
                // carry compose=<name>. The name equals the kind token by
                // grammar; a literal `compose=` token keeps the same fact.
                if (composeName.size == 0) { composeName = fields[3] }
                if (!CjguiComposableUiNamedStyleCatalog.isValidName(composeName)) {
                    return CjguiCompositionDecodeResult(false,
                        "composition_compose_name:${composeName}", None)
                }
                if (composeName == name) {
                    return CjguiCompositionDecodeResult(false,
                        "composition_compose_cycle:${composeName}", None)
                }
            } else if (cjguiCompositionHasToken(fields, "compose=") && composeName.size == 0) {
                return CjguiCompositionDecodeResult(false, "composition_template_compose", None)
            }
            let elementKey = cjguiCompositionTokenValue(fields, "element=")
            if (composeName.size > 0 && elementKey.size > 0) {
                return CjguiCompositionDecodeResult(false,
                    "composition_compose_and_element:${fields[2]}", None)
            }
            let node = CjguiCompositionTemplateNode(fields[2], fields[3],
                elementKey: elementKey,
                presentation: presentation,
                text: cjguiCompositionTrailingValue(line, "text="),
                styleName: styleName,
                gap: if (gapSeen) { gapValue } else { -1 },
                padding: if (paddingSeen) { paddingValue } else { -1 },
                fixedHeight: if (heightSeen) { heightValue } else { -1 },
                growX: if (growSeen) { growValue } else { -1 },
                axis: axis,
                firstSize: if (firstSeen) { firstValue } else { 240 },
                minFirst: if (minFirstSeen) { minFirstValue } else { 120 },
                minSecond: if (minSecondSeen) { minSecondValue } else { 120 },
                composeName: composeName)
            templateNodes.add((depth, node))
        }
    }
    if (!headerSeen) {
        return CjguiCompositionDecodeResult(true, "", None, removals: removals)
    }
    if (elements.size == 0) {
        return CjguiCompositionDecodeResult(false, "composition_has_no_elements", None)
    }
    for (removed in removals) {
        if (removed == name) {
            return CjguiCompositionDecodeResult(false, "composition_remove_and_define", None)
        }
    }
    // Build the template tree with the same depth-stack discipline the node
    // decoder uses: a skipped level or a second root is a refusal.
    var root: ?CjguiCompositionTemplateNode = None
    let stack = ArrayList<ArrayList<CjguiCompositionTemplateNode>>()
    var count: Int64 = 0
    for ((depth, node) in templateNodes) {
        count += 1
        if (count > nodeLimit || count > CJGUI_COMPOSITION_MAX_TEMPLATE_NODES) {
            return CjguiCompositionDecodeResult(false, "composition_template_node_budget", None)
        }
        while (stack.size > depth + 1) { let _ = stack.remove(at: stack.size - 1) }
        while (stack.size <= depth) { stack.add(ArrayList<CjguiCompositionTemplateNode>()) }
        if (depth > 0) {
            if (stack[depth - 1].size == 0) {
                return CjguiCompositionDecodeResult(false, "composition_template_orphan", None)
            }
            stack[depth - 1][stack[depth - 1].size - 1].children.add(node)
        } else if (root.isSome()) {
            return CjguiCompositionDecodeResult(false, "composition_multiple_roots", None)
        } else {
            root = Some(node)
        }
        stack[depth].add(node)
    }
    let template = match (root) {
        case Some(value) => value
        case None => return CjguiCompositionDecodeResult(false, "composition_missing_template", None)
    }
    return CjguiCompositionDecodeResult(true, "",
        Some(CjguiRuntimeCompositionDefinition(name, parameters, elements, template,
            expandedNodeLimit: nodeLimit, expandedDepthLimit: depthLimit)), removals: removals)
}

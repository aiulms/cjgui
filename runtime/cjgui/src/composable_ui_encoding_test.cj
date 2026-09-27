// Tests for the public capability description and the strict candidate decoder
// (composable_ui_generated.cj).
//
// What is pinned here:
//   * `describe` publishes everything an external caller needs WITHOUT reading
//     application source: component kinds and properties, composite declarations
//     with their elements (role, parent, field, writer ARGUMENT, preset value,
//     action, label), actions with their declared argument names, and fields with
//     their label, resource/writer, constraints, generated input kind and writer
//     argument;
//   * `decode` is strict and bounded: a negative or overflowing depth, a depth
//     above the framework ceiling, a missing END, non-empty content after END, a
//     skipped depth level, a repeated property, a property targeting another
//     node, an unknown line, an over-long value and a candidate above the byte
//     ceiling are all rejected with an explicit reason, and no rejection returns a
//     partial root;
//   * the rejection does not disturb the previously accepted structure or its
//     accepted routes, and a legal candidate submitted afterwards still works.
//
// Pure host tests: no window and no native module.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

class EncodingTestFactory <: CjguiCompositeComponentFactory {
    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = match (context.element("root")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        return cjguiComposableVertical(root.nodeId, root.semanticId, CjguiComposableUiStyle(gap: 4))
    }
}

/// A catalog with everything the description must publish: a container kind, a
/// field editor kind, an action WITH declared argument names, one field that
/// declares its writer argument and label, and a composite using all of them.
func encodingTestCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32)
        ]), true, childLimit: 8))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("integerInput",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 64)
        ]), false))
    let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("APPLY_DRAFT", "应用草稿",
        parameterNames: ArrayList<String>(["fieldId", "draftVersion"])))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("retentionCount", "保留天数", "INTEGER", 81003,
        minimum: 1, maximum: 90, required: true, argumentName: "text"))
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    properties.add(CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32))
    let elements = ArrayList<CjguiCompositeElementSpec>()
    elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
    elements.add(CjguiCompositeElementSpec("edit", CJGUI_COMPOSITE_ELEMENT_FIELD,
        fieldId: "retentionCount", argumentName: "text", parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("preset", CJGUI_COMPOSITE_ELEMENT_PRESET,
        fieldId: "retentionCount", argumentName: "text", presetValue: "90", label: "设为 90", parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("apply", CJGUI_COMPOSITE_ELEMENT_ACTION,
        actionName: "APPLY_DRAFT", label: "应用草稿", parentKey: "root"))
    let _ = catalog.registerComposite(CjguiCompositeComponentSpec("retentionEdit", properties, elements,
        allowsChildren: true, childLimit: 3, expandedNodeLimit: 12, expandedDepthLimit: 3),
        EncodingTestFactory())
    return catalog
}

@Test
func generatedDescribePublishesCompositesFieldsAndArguments(): Unit {
    let catalog = encodingTestCatalog()
    let text = CjguiGeneratedUiEncoding.describe(catalog)
    // Component and property discovery is unchanged and stays line-addressable.
    @Assert(text.contains("COMPONENT vertical 1 8\n"), true)
    @Assert(text.contains("PROPERTY vertical gap INTEGER 0 0 32 0\n"), true)
    // The composite is published as its own declaration beside the derived
    // COMPONENT line, with the framework bounds an external caller must respect.
    @Assert(text.contains("COMPONENT retentionEdit 1 3\n"), true)
    @Assert(text.contains("COMPOSITE retentionEdit children=1 child_limit=3 expanded_nodes=12 expanded_depth=3\n"),
        true)
    @Assert(text.contains(
        "ELEMENT retentionEdit root container parent=root field=none argument=none preset=none action=none label=\n"),
        true)
    // The field element publishes the writer ARGUMENT, so a caller never guesses
    // which argument the owner operation takes.
    @Assert(text.contains(
        "ELEMENT retentionEdit edit field parent=root field=retentionCount argument=text preset=none action=none label=\n"),
        true)
    // The preset publishes the declared constant and its caption (label last,
    // because captions may contain spaces).
    @Assert(text.contains(
        "ELEMENT retentionEdit preset preset parent=root field=retentionCount argument=text preset=90 action=none label=设为 90\n"),
        true)
    @Assert(text.contains(
        "ELEMENT retentionEdit apply action parent=root field=none argument=none preset=none action=APPLY_DRAFT label=应用草稿\n"),
        true)
    // The action publishes its declared argument names before its label.
    @Assert(text.contains("ACTION APPLY_DRAFT argument=fieldId,draftVersion 应用草稿\n"), true)
    // The field publishes its label, writer argument and generated input kind.
    @Assert(text.contains(
        "FIELD retentionCount INTEGER resource=81003 writer=EDIT_DRAFT_TEXT required=1 min=1 max=90 maxlen=0 " +
        "callable=1 argument=text input=integerInput label=保留天数\n"), true)
}

@Test
func generatedDecodeIsStrictAboutBoundsEndAndTrailingInput(): Unit {
    // Positive control: a complete, well-formed candidate still decodes, so the
    // strictness below is a rejection of bad input, not of the format.
    let accepted = CjguiGeneratedUiEncoding.decode(
        "GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nPROPERTY 0 panel gap 4\n" +
        "NODE 1 edit integerInput field=retentionCount\nPROPERTY 1 edit label 保留天数\nEND")
    @Assert(accepted.ok, true)
    @Assert(accepted.root.isSome(), true)

    let cases = ArrayList<(String, String)>()
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE -1 panel vertical\nEND", "malformed_node_depth"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 99999999999999999999 panel vertical\nEND", "malformed_node_depth"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nNODE 1 child vertical\nPROPERTY 1 child gap 4\n" +
        "PROPERTY -2 child gap 4\nEND", "malformed_property_depth"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 33 panel vertical\nEND", "depth_budget_exceeded"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 2 deep vertical\nEND", "orphan_node"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical", "missing_end"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nEND\nNODE 1 late label", "trailing_content"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nPROPERTY 0 panel gap 4\nPROPERTY 0 panel gap 6\nEND",
        "duplicate_property"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nBOGUS 0 panel gap 4\nEND", "unknown_line"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nPROPERTY 1 panel gap 4\nEND", "orphan_property"))
    cases.add(("NOT_A_STRUCTURE 1\nEND", "invalid_header"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nNODE 0 second vertical\nEND", "multiple_roots"))
    // The NODE grammar is exact: an extra token is not a comment, and a
    // repeated or empty binding must not be silently dropped or overwritten.
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical bogus=1\nEND", "unknown_node_token"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel textInput field=label field=enabled\nEND",
        "duplicate_node_field"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel textInput field=\nEND", "empty_node_field"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel action action=APPLY_DRAFT action=CANCEL_DRAFT\nEND",
        "duplicate_node_action"))
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel action action=\nEND", "empty_node_action"))
    let longValue = StringBuilder()
    var longIndex: Int64 = 0
    while (longIndex <= CJGUI_GENERATED_UI_DECODE_MAX_STRING_LENGTH) {
        longValue.append("x")
        longIndex += 1
    }
    cases.add(("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nPROPERTY 0 panel gap ${longValue.toString()}\nEND",
        "string_budget_exceeded"))
    for ((candidate, expected) in cases) {
        let decoded = CjguiGeneratedUiEncoding.decode(candidate)
        @Assert(decoded.ok, false)
        @Assert(decoded.reason.startsWith(expected), true)
        // A rejected candidate never yields a partial structure.
        @Assert(decoded.root.isNone(), true)
    }

    // The byte ceiling is checked before any parsing or allocation.
    let oversized = StringBuilder()
    var byteIndex: Int64 = 0
    while (byteIndex <= CJGUI_GENERATED_UI_DECODE_MAX_BYTES) {
        oversized.append("x")
        byteIndex += 1
    }
    let tooLarge = CjguiGeneratedUiEncoding.decode(oversized.toString())
    @Assert(tooLarge.ok, false)
    @Assert(tooLarge.reason, "candidate_too_large")

    // The node ceiling is checked before the offending node is added, and it is
    // reached by a shape the parser would otherwise accept one node at a time.
    let manyNodes = StringBuilder()
    manyNodes.append("GENERATED_UI_STRUCTURE 1\nNODE 0 root vertical\n")
    var nodeIndex: Int64 = 0
    while (nodeIndex <= CJGUI_GENERATED_UI_DECODE_MAX_NODES) {
        manyNodes.append("NODE 1 c${nodeIndex} vertical\n")
        nodeIndex += 1
    }
    manyNodes.append("END")
    let tooManyNodes = CjguiGeneratedUiEncoding.decode(manyNodes.toString())
    @Assert(tooManyNodes.ok, false)
    @Assert(tooManyNodes.reason.startsWith("node_budget_exceeded"), true)
}

@Test
func generatedDecodeRejectionKeepsAcceptedStructureAndRoutes(): Unit {
    let catalog = encodingTestCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let leaves = ArrayList<CjguiGeneratedUiNodeSpec>()
    leaves.add(CjguiGeneratedUiNodeSpec("edit", "integerInput", fieldId: "retentionCount"))
    let root = CjguiGeneratedUiNodeSpec("panel", "vertical", children: leaves)
    @Assert(holder.submit(root, provider).candidateAccepted, true)
    // Candidate acceptance is not scene acceptance: only the commit transaction
    // publishes the accepted structure and its node identities.
    @Assert(generatedCommit(holder, provider), true)
    let acceptedVersion = holder.structureVersion()
    @Assert(acceptedVersion, 1)
    @Assert(holder.acceptedNodeForKey("edit").isSome(), true)
    let acceptedNodeId = holder.nodeIdForKey("edit")
    @Assert(acceptedNodeId > 0, true)
    @Assert(holder.keyForNodeId(acceptedNodeId), "edit")

    // Every malformed candidate is refused at the decode boundary with an
    // explicit reason, so nothing reaches the accepted structure.
    let rejects = ArrayList<String>()
    rejects.add("GENERATED_UI_STRUCTURE 1\nNODE -1 panel vertical\nEND")
    rejects.add("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical")
    rejects.add("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nEND\nNODE 1 late label")
    rejects.add("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\nPROPERTY 0 panel gap 4\n" +
        "PROPERTY 0 panel gap 5\nEND")
    // The newly strict NODE grammar is part of the same "no partial write"
    // boundary: a malformed binding token never reaches the holder.
    rejects.add("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical bogus=1\nEND")
    rejects.add("GENERATED_UI_STRUCTURE 1\nNODE 0 panel textInput field=label field=enabled\nEND")
    rejects.add("GENERATED_UI_STRUCTURE 1\nNODE 0 panel action action=\nEND")
    for (candidate in rejects) {
        let decoded = CjguiGeneratedUiEncoding.decode(candidate)
        @Assert(decoded.ok, false)
        @Assert(decoded.reason.size > 0, true)
        @Assert(decoded.root.isNone(), true)
    }
    // The accepted structure, its version and its accepted route are untouched.
    @Assert(holder.structureVersion(), acceptedVersion)
    @Assert(holder.nodeIdForKey("edit"), acceptedNodeId)
    @Assert(holder.acceptedNodeForKey("edit").isSome(), true)
    @Assert(holder.keyForNodeId(acceptedNodeId), "edit")

    // A legal candidate after the rejections still submits, commits and routes.
    @Assert(holder.submit(CjguiGeneratedUiNodeSpec("panel", "vertical", children: leaves), provider)
        .candidateAccepted, true)
    @Assert(generatedCommit(holder, provider), true)
    @Assert(holder.structureVersion(), acceptedVersion + 1)
    @Assert(holder.acceptedNodeForKey("edit").isSome(), true)
    @Assert(holder.keyForNodeId(holder.nodeIdForKey("edit")), "edit")
}
@Test
func generatedEmptyPropertyValueRidesTheProtocolAsAnExplicitToken(): Unit {
    // Empty is published as an explicit token, NEVER as a trailing space the
    // transport would reject as "response field is malformed".
    @Assert(CjguiGeneratedUiEncoding.encodePropertyValue(""), "\\e")
    @Assert(CjguiGeneratedUiEncoding.decodePropertyValue("\\e"), "")
    // `none`, the empty string and a legal token stay three DISTINCT states.
    @Assert(CjguiGeneratedUiEncoding.encodePropertyValue("none"), "none")
    @Assert(CjguiGeneratedUiEncoding.decodePropertyValue("none"), "none")
    // A value that already begins with a backslash round-trips losslessly.
    @Assert(CjguiGeneratedUiEncoding.encodePropertyValue("\\shadow"), "\\\\shadow")
    @Assert(CjguiGeneratedUiEncoding.decodePropertyValue("\\\\shadow"), "\\shadow")

    // The accepted payload carries the explicit token (no empty field leaves the
    // encoder), and the strict candidate decoder reads it back as "".
    let properties = HashMap<String, String>()
    properties.add("shadow", "")
    let root = CjguiGeneratedUiNodeSpec("card", "label", properties: properties)
    let payload = CjguiGeneratedUiEncoding.encode(Some(root), 4)
    @Assert(payload.contains("PROPERTY 0 card shadow \\e\n"), true)
    let decoded = CjguiGeneratedUiEncoding.decode(
        "GENERATED_UI_STRUCTURE 1\nNODE 0 card label\nPROPERTY 0 card shadow \\e\nEND")
    @Assert(decoded.ok, true)
    @Assert(decoded.root.getOrThrow().property("shadow"), "")

    // A value that would still begin/end with a space cannot be framed
    // unambiguously, so it is refused instead of being silently trimmed.
    let edge = CjguiGeneratedUiEncoding.decode(
        "GENERATED_UI_STRUCTURE 1\nNODE 0 card label\nPROPERTY 0 card shadow  x\nEND")
    @Assert(edge.ok, false)
    @Assert(edge.reason.startsWith("property_value_edge_space"), true)
}

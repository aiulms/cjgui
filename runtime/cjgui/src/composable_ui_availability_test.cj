// Dynamic availability projection: a generated editor's `enabled` state is the
// projection of the OWNER's CURRENT condition (the same condition the write path
// enforces), never of "a target exists". A field that becomes unavailable keeps
// its identity and its draft: freezing must not silently move the edit to another
// object or discard what was typed.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

private func availabilityCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 8))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("APPLY_DRAFT", "应用草稿"))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "名称", "TEXT", 7001,
        writeActionName: "SET_LABEL"))
    return catalog
}

private class AvailabilityProbeProvider <: CjguiGeneratedUiBindingProvider {
    private let fieldFact: CjguiSharedAvailability
    private let actionFact: CjguiSharedAvailability

    public init(fieldFact: CjguiSharedAvailability, actionFact: CjguiSharedAvailability) {
        this.fieldFact = fieldFact
        this.actionFact = actionFact
    }

    public func fieldResourceId(fieldId: String): Int64 { return 7001 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 42 }
    public func draftText(fieldId: String): String { return "草稿" }
    public func appliedText(fieldId: String): String { return "已应用" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
    public func fieldAvailability(fieldId: String): CjguiSharedAvailability { return fieldFact }
    public func actionAvailability(actionName: String): CjguiSharedAvailability { return actionFact }
}

private func availabilityFind(node: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (node.nodeId == nodeId) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- availabilityFind(child, nodeId)) {
            return Some(found)
        }
    }
    return None
}

private func availabilityBuild(catalog: CjguiGeneratedUiCapabilityCatalog,
                               provider: CjguiGeneratedUiBindingProvider):
    (CjguiGeneratedUiStructureHolder, CjguiComposableUiNode) {
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let leaves = ArrayList<CjguiGeneratedUiNodeSpec>()
    leaves.add(CjguiGeneratedUiNodeSpec("fieldA", "textInput", fieldId: "label"))
    leaves.add(CjguiGeneratedUiNodeSpec("btnA", "action", actionName: "APPLY_DRAFT"))
    let root = CjguiGeneratedUiNodeSpec("panelA", "vertical", children: leaves)
    let submitted = holder.submit(root, provider)
    if (!submitted.candidateAccepted) {
        return (holder, cjguiComposableText(-1, "rejected:${submitted.reason}", "",
            CjguiComposableUiStyle()))
    }
    let _ = holder.beginCandidateRefresh()
    let node = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    let _ = holder.commitCandidateRefresh()
    return (holder, node)
}

@Test
func generatedEditorEnabledIsTheOwnerAvailabilityProjection(): Unit {
    let catalog = availabilityCatalog()

    // The owner reports blocked with ITS OWN reason: the editor is disabled, yet
    // it is the SAME node (identity kept) and still carries the live draft.
    let blockedProvider = AvailabilityProbeProvider(
        CjguiSharedAvailability.blocked("title_frozen_after_submit", 42, 7),
        CjguiSharedAvailability.allowed(42, 7))
    let (blockedHolder, blockedRoot) = availabilityBuild(catalog, blockedProvider)
    let fieldNodeId = blockedHolder.nodeIdForKey("fieldA")
    @Assert(fieldNodeId > 0, true)
    let blockedNode = match (availabilityFind(blockedRoot, fieldNodeId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(blockedNode.nodeId, fieldNodeId)
    @Assert(blockedNode.isEnabled, false)

    // The same provider but available: the editor is editable again, so the flag
    // really follows the owner's answer rather than the field's mere presence.
    let allowedProvider = AvailabilityProbeProvider(
        CjguiSharedAvailability.allowed(42, 7), CjguiSharedAvailability.allowed(42, 7))
    let (allowedHolder, allowedRoot) = availabilityBuild(catalog, allowedProvider)
    let allowedNode = match (availabilityFind(allowedRoot, allowedHolder.nodeIdForKey("fieldA"))) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(allowedNode.isEnabled, true)

    // A provider that cannot evaluate the condition claims neither verdict: the
    // framework keeps the legacy "a target exists" projection instead of
    // inventing a decision.
    let unknownProvider = AvailabilityProbeProvider(CjguiSharedAvailability.unknown(),
        CjguiSharedAvailability.unknown())
    let (unknownHolder, unknownRoot) = availabilityBuild(catalog, unknownProvider)
    let unknownNode = match (availabilityFind(unknownRoot, unknownHolder.nodeIdForKey("fieldA"))) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(unknownNode.isEnabled, true)

    // An action the owner currently blocks is disabled; one it allows stays
    // enabled. Both come from the same availability answer.
    let actionProvider = AvailabilityProbeProvider(CjguiSharedAvailability.allowed(42, 7),
        CjguiSharedAvailability.blocked("no_selection", 42, 7))
    let (actionHolder, actionRoot) = availabilityBuild(catalog, actionProvider)
    let actionNode = match (availabilityFind(actionRoot, actionHolder.nodeIdForKey("btnA"))) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(actionNode.isEnabled, false)
}

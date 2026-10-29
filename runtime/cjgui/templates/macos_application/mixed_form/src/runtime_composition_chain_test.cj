// One continuous window session over the runtime composition entry: a
// definition and its A/B instances are submitted together, both real card
// owners are edited, an EXTERNAL change reaches A, the definition is updated
// (layout + named style + presentation) without restarting, a human keeps
// editing, refused updates keep the accepted definition/scene/data, readback
// is exact, and the window closes normally.
package cjgui_mixed_form_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private func runtimeChainToken(line: String, prefix: String): String {
    for (token in line.split(" ")) {
        if (token.startsWith(prefix)) {
            return token[prefix.size..token.size]
        }
    }
    return ""
}

private func runtimeChainInstanceLine(payload: String, key: String, element: String): String {
    for (line in payload.split("\n")) {
        if (line.startsWith("INSTANCE ${key} ")) {
            if (runtimeChainToken(line, "element=") == element) {
                return line
            }
        }
    }
    return ""
}

private func runtimeChainInstanceNodeId(payload: String, key: String, element: String): Int64 {
    let line = runtimeChainInstanceLine(payload, key, element)
    if (line.size == 0) {
        return -1
    }
    let idText = runtimeChainToken(line, "id=")
    if (idText.size == 0) {
        return -1
    }
    try {
        return Int64.parse(idText)
    } catch (_: Exception) {
        return -1
    }
}

private func runtimeChainElementSemantic(payload: String, key: String, element: String): String {
    return runtimeChainToken(runtimeChainInstanceLine(payload, key, element), "semantic=")
}

private func runtimeChainLayoutNode(window: CjguiComposableUiWindow,
    nodeId: Int64): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            return node
        }
    }
    throw IllegalStateException("runtime chain target is not accepted: ${nodeId}")
}

private func runtimeChainHasAction(window: CjguiComposableUiWindow, action: String): Bool {
    for (node in window.acceptedSceneNodes()) {
        if (node.actionName == action) { return true }
    }
    return false
}

private func runtimeChainNodeBySemantic(window: CjguiComposableUiWindow,
    semantic: String): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semantic) { return node }
    }
    throw IllegalStateException("runtime chain semantic is not accepted: ${semantic}")
}

private func runtimeChainPayload(axis: String, titleStyle: String, duplexPresentation: String,
    includeHint: Bool, ghostField: Bool, thirdSplitChild: Bool): String {
    let builder = StringBuilder()
    builder.append("GENERATED_UI_STRUCTURE 2\n")
    builder.append("COMPOSITION runtimePresetCard 64 8\n")
    builder.append("CPARAM title STRING 0 0 40 40 \\e\n")
    builder.append("CELEMENT name field field=${if (ghostField) { "ghostField" } else { "jobName" }} argument=text\n")
    builder.append("CELEMENT copies field field=copies argument=text\n")
    builder.append("CELEMENT duplex field field=duplex argument=value\n")
    builder.append("CELEMENT apply action action=APPLY_DRAFT label=应用\n")
    builder.append("CELEMENT cancel action action=CANCEL_DRAFT label=取消\n")
    builder.append("CELEMENT nameError projection field=jobName source=field_error\n")
    let presentation = duplexPresentation
    builder.append("CTEMPLATE 0 root split axis=${axis} first=380 minfirst=220 minsecond=150 gap=8 padding=8\n")
    builder.append("CTEMPLATE 1 fields vertical gap=4\n")
    if (thirdSplitChild) {
        builder.append("CTEMPLATE 1 extra vertical\n")
    }
    builder.append(
        "CTEMPLATE 2 title label style=${titleStyle} text=" + "$" + "{title}\n")
    builder.append("CTEMPLATE 2 name element element=name presentation=text\n")
    builder.append("CTEMPLATE 2 copies element element=copies presentation=text\n")
    builder.append("CTEMPLATE 2 duplex element element=duplex presentation=${presentation} " +
        "style=preset-card-field-label gap=6\n")
    builder.append("CTEMPLATE 2 nameError element element=nameError presentation=text\n")
    if (includeHint) {
        builder.append("CTEMPLATE 2 hint label style=preset-card-note text=布局已更新\n")
    }
    builder.append("CTEMPLATE 1 side vertical gap=6 grow=1\n")
    builder.append("CTEMPLATE 2 apply element element=apply presentation=text\n")
    builder.append("CTEMPLATE 2 cancel element element=cancel presentation=text\n")
    builder.append("NODE 0 board vertical\n")
    builder.append("NODE 1 deck horizontal\n")
    builder.append("NODE 2 cardA runtimePresetCard\n")
    builder.append("PROPERTY 2 cardA title 卡片 A\n")
    builder.append("NODE 2 cardB runtimePresetCard\n")
    builder.append("PROPERTY 2 cardB title 卡片 B\n")
    builder.append("NODE 1 footer label\n")
    builder.append("PROPERTY 1 footer text 运行时组合 · A/B\n")
    builder.append("END")
    return builder.toString()
}

private func runtimeChainRemovalPayload(): String {
    return "GENERATED_UI_STRUCTURE 2\n" +
        "COMPOSITION_REMOVE runtimePresetCard\n" +
        "NODE 0 board vertical\n" +
        "NODE 1 footer label\n" +
        "PROPERTY 1 footer text 定义已移除\n" +
        "END"
}

private func runtimeChainPump(host: CjguiMacosApplicationHost, window: CjguiComposableUiWindow,
    targetVersion: Int64, region: CjguiGeneratedUiWindowRegion): Int64 {
    let started = MonoTime.now()
    let _ = window.refresh()
    for (_ in 0..96) {
        if (region.acceptedStructureVersion() == targetVersion) {
            break
        }
        let _ = host.pumpOneTurn()
    }
    return (MonoTime.now() - started).toMilliseconds()
}

@Test
func runtimeCompositionContinuousMixedChain(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    controller.collaborationOpened(true)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Runtime composition chain", 1180u32, 760u32,
            rangeTextEditDeltaDelivery: true))
    let window = host.window()
    controller.attachWindow(window)
    @Assert(host.start(), true)
    try {
        for (_ in 0..96) {
            if (window.windowProgress().acceptedSceneVersion > 0) { break }
            let _ = host.pumpOneTurn()
        }
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)

        // 1. Runtime definition + its two real instances arrive in ONE candidate.
        let submitStarted = MonoTime.now()
        let v1 = controller.region.submitStructure(
            runtimeChainPayload("horizontal", "preset-card-title", "text", false, false, false), 0)
        @Assert(v1.candidateAccepted, true)
        @Assert(v1.reason, "")
        // Public discovery is ACCEPTED-only while A is still pending.
        @Assert(!controller.region.capabilitiesPayload().contains("COMPOSITE runtimePresetCard"), true)
        // An invalid B in a later ticket must not clear pending A's definition.
        // A still has to be accepted by the scene below, with its definition.
        let invalidBPending = controller.region.submitStructure(
            runtimeChainPayload("horizontal", "preset-card-title", "text", false, true, false), 0)
        @Assert(!invalidBPending.candidateAccepted, true)
        @Assert(invalidBPending.reason.startsWith("composition_rejected:composition_unknown_field:ghostField"), true)
        let acceptMs = runtimeChainPump(host, window, 1, controller.region)
        getStdOut().writeln("RUNTIME_CHAIN v1 accepted=${v1.candidateAccepted} structure=${controller.region.acceptedStructureVersion()} " +
            "pump_ms=${acceptMs} submit_ms=${(MonoTime.now() - submitStarted).toMilliseconds()}")
        getStdOut().flush()
        @Assert(controller.region.acceptedStructureVersion(), 1)
        @Assert(controller.region.capabilitiesPayload().contains("COMPOSITE runtimePresetCard"), true)
        getStdOut().writeln("RUNTIME_CHAIN capabilities_begin")
        getStdOut().writeln(controller.region.capabilitiesPayload())
        getStdOut().writeln("RUNTIME_CHAIN capabilities_end")
        let acceptedStructure = controller.region.acceptedStructurePayload()
        @Assert(acceptedStructure.contains("COMPOSITION runtimePresetCard 64 8"), true)
        @Assert(acceptedStructure.contains("COMPOSITION_END runtimePresetCard"), true)
        getStdOut().writeln("RUNTIME_CHAIN ticket accepted=${v1.candidateAccepted} scene=${v1.sceneAccepted} " +
            "reason=${v1.reason} path=${v1.path} before=${v1.versionBefore} after=${v1.versionAfter} " +
            "candidate_version=${v1.candidateVersion} token=${v1.candidateToken} receipt=${v1.receipt}")
        getStdOut().writeln("RUNTIME_CHAIN rejected_ticket accepted=${invalidBPending.candidateAccepted} " +
            "scene=${invalidBPending.sceneAccepted} reason=${invalidBPending.reason} " +
            "before=${invalidBPending.versionBefore} after=${invalidBPending.versionAfter} " +
            "candidate_version=${invalidBPending.candidateVersion} token=${invalidBPending.candidateToken} " +
            "receipt=${invalidBPending.receipt}")
        getStdOut().writeln("RUNTIME_CHAIN accepted_structure_begin")
        getStdOut().writeln(acceptedStructure)
        getStdOut().writeln("RUNTIME_CHAIN accepted_structure_end")
        let cardA = controller.region.acceptedNodeIdForKey("cardA")
        let cardB = controller.region.acceptedNodeIdForKey("cardB")
        @Assert(cardA > 0, true)
        @Assert(cardB > 0, true)
        var payload = controller.region.acceptedInstancesPayload()
        getStdOut().writeln("RUNTIME_CHAIN instances_begin")
        getStdOut().writeln(payload)
        getStdOut().writeln("RUNTIME_CHAIN instances_end")
        @Assert(runtimeChainInstanceLine(payload, "cardA", "name").contains("owner=6301"), true)
        @Assert(runtimeChainInstanceLine(payload, "cardB", "name").contains("owner=6302"), true)
        @Assert(runtimeChainInstanceLine(payload, "cardA", "apply").contains("owner=6301"), true)
        @Assert(runtimeChainInstanceLine(payload, "cardB", "apply").contains("owner=6302"), true)
        let copiesA = runtimeChainInstanceNodeId(payload, "cardA", "copies")
        let copiesB = runtimeChainInstanceNodeId(payload, "cardB", "copies")
        let duplexA = runtimeChainInstanceNodeId(payload, "cardA", "duplex")
        let duplexB = runtimeChainInstanceNodeId(payload, "cardB", "duplex")
        let applyA = runtimeChainInstanceNodeId(payload, "cardA", "apply")
        @Assert(copiesA > 0, true)
        @Assert(copiesB > 0, true)
        @Assert(duplexA > 0, true)
        @Assert(duplexB > 0, true)
        @Assert(applyA > 0, true)

        // 2. A and B are edited independently (whole-value INTEGER controls).
        let editA = controller.region.handleEvent(CjguiComposableUiEvent(
            runtimeChainLayoutNode(window, copiesA), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "6", 1, 1,
            window.windowProgress().acceptedSceneVersion))
        @Assert(editA.didApply, true)
        let editB = controller.region.handleEvent(CjguiComposableUiEvent(
            runtimeChainLayoutNode(window, copiesB), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "3", 1, 1,
            window.windowProgress().acceptedSceneVersion))
        @Assert(editB.didApply, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(domain.cards.card("cardA").getOrThrow().draftText("copies"), "6")
        @Assert(domain.cards.card("cardB").getOrThrow().draftText("copies"), "3")
        @Assert(runtimeChainLayoutNode(window, copiesA).value, "6")
        @Assert(runtimeChainLayoutNode(window, copiesB).value, "3")

        // 3. EXTERNAL change on A: the owner transaction, not a UI-only field.
        let cardArtifact = domain.cards.card("cardA").getOrThrow()
        let external = domain.executeFromHuman(CjguiSharedOperationActionInvocation("EDIT_DRAFT_TEXT",
            domain.formSnapshot().contextVersion, ArrayList<Int64>([6301]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("fieldId", CjguiSharedOperationValue.string("jobName")),
                CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string("外部改 A")),
                CjguiSharedOperationActionArgument("expectedDraftVersion",
                    CjguiSharedOperationValue.integer(cardArtifact.draftVersionValue()))
            ])))
        getStdOut().writeln("RUNTIME_CHAIN external applied=${external.applied} reason=${external.reason} " +
            "context=${domain.formSnapshot().contextVersion} draft=${cardArtifact.draftVersionValue()}")
        getStdOut().flush()
        @Assert(external.applied, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        let nameA = runtimeChainInstanceNodeId(controller.region.acceptedInstancesPayload(), "cardA", "name")
        @Assert(runtimeChainLayoutNode(window, nameA).value, "外部改 A")
        @Assert(domain.cards.card("cardB").getOrThrow().draftText("jobName"), "资料 B")

        // 4. Same-name definition update: split direction, named style and the
        //    duplex presentation change without a restart; identities survive.
        let v2 = controller.region.submitStructure(
            runtimeChainPayload("vertical", "preset-card-note", "select", true, false, false), 1)
        @Assert(v2.candidateAccepted, true)
        let updateMs = runtimeChainPump(host, window, 2, controller.region)
        getStdOut().writeln("RUNTIME_CHAIN v2 accepted=${v2.candidateAccepted} structure=${controller.region.acceptedStructureVersion()} " +
            "pump_ms=${updateMs} scene=${controller.region.sceneState()}")
        getStdOut().flush()
        @Assert(controller.region.acceptedStructureVersion(), 2)
        @Assert(controller.region.acceptedNodeIdForKey("cardA"), cardA)
        @Assert(controller.region.acceptedNodeIdForKey("cardB"), cardB)
        payload = controller.region.acceptedInstancesPayload()
        @Assert(runtimeChainInstanceNodeId(payload, "cardA", "copies"), copiesA)
        @Assert(runtimeChainInstanceNodeId(payload, "cardA", "duplex"), duplexA)
        @Assert(runtimeChainLayoutNode(window, copiesA).value, "6")
        @Assert(runtimeChainLayoutNode(window, nameA).value, "外部改 A")
        // The split really changed direction: actions sat beside the fields and
        // now stack below them.
        @Assert(runtimeChainLayoutNode(window, applyA).bounds.y > runtimeChainLayoutNode(window, duplexA).bounds.y, true)
        let duplexASemantic = runtimeChainElementSemantic(payload, "cardA", "duplex")
        let duplexBSemantic = runtimeChainElementSemantic(payload, "cardB", "duplex")
        @Assert(duplexASemantic.size > 0, true)
        // 5. Per-instance searchable Select: A and B own separate popups,
        //    queries, highlights and owner writes. The handwritten preset's
        //    duplex field (owner 6200) must not move.
        let handwrittenDuplexBefore = domain.formSnapshot().fieldForResourceId(6203).draftText
        let humanStarted = MonoTime.now()
        // The instance popup's own commands are now published through the
        // region/window declaration path; arrows/Enter/Esc are the production
        // command ids, not a directly injected event kind.
        let openA = controller.region.handleEvent(CjguiComposableUiEvent(
            runtimeChainLayoutNode(window, duplexA), CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            "", 0, 0, window.windowProgress().acceptedSceneVersion))
        @Assert(openA.didApply, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        // Arrow navigation and confirmation go through the declared commands
        // of the OPEN instance popup. The command carries the same
        // `shortcut:<key>` text a native key event does; no event kind is
        // injected and the owner write stays with the popup's own writer.
        @Assert(window.invokeShortcut("shortcut:down"), true)
        @Assert(window.invokeShortcut("shortcut:enter"), true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(domain.cards.card("cardA").getOrThrow().draftBoolean("duplex"), true)
        // cardB is seeded with 双面; A's own write left it untouched.
        @Assert(domain.cards.card("cardB").getOrThrow().draftBoolean("duplex"), true)

        // Reopen A: search narrows the rows and Escape closes without writing.
        let reopenAForSearch = controller.region.handleEvent(CjguiComposableUiEvent(
            runtimeChainLayoutNode(window, duplexA), CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            "", 0, 0, window.windowProgress().acceptedSceneVersion))
        @Assert(reopenAForSearch.didApply, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        let searchA = runtimeChainNodeBySemantic(window, "${duplexASemantic}-select-search")
        let queryA = controller.region.handleEvent(CjguiComposableUiEvent(searchA,
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "单", 1, 1,
            window.windowProgress().acceptedSceneVersion))
        @Assert(queryA.didApply, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(runtimeChainHasAction(window, "${duplexASemantic}-select-choose:single"), true)
        @Assert(!runtimeChainHasAction(window, "${duplexASemantic}-select-choose:double"), true)
        @Assert(window.invokeShortcut("shortcut:escape"), true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(!runtimeChainHasAction(window, "${duplexASemantic}-select-search"), true)
        @Assert(domain.cards.card("cardA").getOrThrow().draftBoolean("duplex"), true)

        // Opening B retires A's popup, not A's owner value; B starts with its
        // own query and unfiltered rows.
        let openB = controller.region.handleEvent(CjguiComposableUiEvent(
            runtimeChainLayoutNode(window, duplexB), CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            "", 0, 0, window.windowProgress().acceptedSceneVersion))
        @Assert(openB.didApply, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(!runtimeChainHasAction(window, "${duplexASemantic}-select-search"), true)
        let searchB = runtimeChainNodeBySemantic(window, "${duplexBSemantic}-select-search")
        @Assert(runtimeChainHasAction(window, "${duplexBSemantic}-select-choose:single"), true)
        @Assert(runtimeChainHasAction(window, "${duplexBSemantic}-select-choose:double"), true)
        let queryB = controller.region.handleEvent(CjguiComposableUiEvent(searchB,
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "双", 1, 1,
            window.windowProgress().acceptedSceneVersion))
        @Assert(queryB.didApply, true)
        @Assert(window.invokeShortcut("shortcut:enter"), true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(domain.cards.card("cardB").getOrThrow().draftBoolean("duplex"), true)
        @Assert(domain.cards.card("cardA").getOrThrow().draftBoolean("duplex"), true)

        // A picks 双面 through its own popup. B's write never touches A, and A
        // is reopened with a cleared query, not the one it used earlier.
        let reopenA = controller.region.handleEvent(CjguiComposableUiEvent(
            runtimeChainLayoutNode(window, duplexA), CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            "", 0, 0, window.windowProgress().acceptedSceneVersion))
        @Assert(reopenA.didApply, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        let searchA2 = runtimeChainNodeBySemantic(window, "${duplexASemantic}-select-search")
        @Assert(runtimeChainHasAction(window, "${duplexASemantic}-select-choose:single"), true)
        @Assert(runtimeChainHasAction(window, "${duplexASemantic}-select-choose:double"), true)
        let queryA2 = controller.region.handleEvent(CjguiComposableUiEvent(searchA2,
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "双", 1, 1,
            window.windowProgress().acceptedSceneVersion))
        @Assert(queryA2.didApply, true)
        @Assert(window.invokeShortcut("shortcut:enter"), true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        getStdOut().writeln("RUNTIME_CHAIN select A=${domain.cards.card("cardA").getOrThrow().draftBoolean("duplex")} " +
            "B=${domain.cards.card("cardB").getOrThrow().draftBoolean("duplex")} " +
            "handwritten=${domain.formSnapshot().fieldForResourceId(6203).draftText} " +
            "usable_ms=${(MonoTime.now() - humanStarted).toMilliseconds()}")
        getStdOut().flush()
        @Assert(domain.cards.card("cardA").getOrThrow().draftBoolean("duplex"), true)
        @Assert(domain.cards.card("cardB").getOrThrow().draftBoolean("duplex"), true)
        @Assert(domain.formSnapshot().fieldForResourceId(6203).draftText, handwrittenDuplexBefore)

        // 6. The human continues on the card that was just updated.
        let humanEdit = controller.region.handleEvent(CjguiComposableUiEvent(
            runtimeChainLayoutNode(window, copiesA), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "8", 1, 1,
            window.windowProgress().acceptedSceneVersion))
        @Assert(humanEdit.didApply, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(domain.cards.card("cardA").getOrThrow().draftText("copies"), "8")

        // 7. A refused update keeps the accepted definition, scene and data.
        let ghost = controller.region.submitStructure(
            runtimeChainPayload("vertical", "preset-card-note", "radio", true, true, false), 2)
        @Assert(!ghost.candidateAccepted, true)
        getStdOut().writeln("RUNTIME_CHAIN ghost reason=${ghost.reason}")
        getStdOut().flush()
        @Assert(ghost.reason.startsWith("composition_rejected:composition_unknown_field:ghostField"), true)
        let splitRefusal = controller.region.submitStructure(
            runtimeChainPayload("vertical", "preset-card-note", "select", true, false, true), 2)
        @Assert(!splitRefusal.candidateAccepted, true)
        getStdOut().writeln("RUNTIME_CHAIN split reason=${splitRefusal.reason}")
        getStdOut().flush()
        @Assert(splitRefusal.reason.startsWith("composition_rejected:composition_split_children:root"), true)
        @Assert(controller.region.acceptedStructureVersion(), 2)
        @Assert(controller.region.acceptedNodeIdForKey("cardA"), cardA)
        @Assert(runtimeChainInstanceNodeId(controller.region.acceptedInstancesPayload(), "cardA", "copies"), copiesA)
        @Assert(domain.cards.card("cardA").getOrThrow().draftText("copies"), "8")
        @Assert(runtimeChainLayoutNode(window, copiesA).value, "8")

        // 8. After the refusals the accepted presentation still operates: A is
        //    reopened through its own trigger and commits 单面.
        let afterRefusal = controller.region.handleEvent(CjguiComposableUiEvent(
            runtimeChainLayoutNode(window, duplexA), CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            "", 0, 0, window.windowProgress().acceptedSceneVersion))
        @Assert(afterRefusal.didApply, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        let searchAfter = runtimeChainNodeBySemantic(window, "${duplexASemantic}-select-search")
        let queryAfter = controller.region.handleEvent(CjguiComposableUiEvent(searchAfter,
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "单", 1, 1,
            window.windowProgress().acceptedSceneVersion))
        @Assert(queryAfter.didApply, true)
        @Assert(window.invokeShortcut("shortcut:enter"), true)
        @Assert(domain.cards.card("cardA").getOrThrow().draftBoolean("duplex"), false)
        @Assert(domain.cards.card("cardB").getOrThrow().draftBoolean("duplex"), true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }

        // 9. Exact readback of both owners and the accepted instance rows.
        payload = controller.region.acceptedInstancesPayload()
        @Assert(runtimeChainInstanceLine(payload, "cardA", "duplex").contains("owner=6301"), true)
        @Assert(runtimeChainInstanceLine(payload, "cardB", "duplex").contains("owner=6302"), true)
        @Assert(domain.cards.card("cardA").getOrThrow().draftText("jobName"), "外部改 A")
        @Assert(domain.cards.card("cardB").getOrThrow().draftText("jobName"), "资料 B")
        @Assert(domain.cards.card("cardA").getOrThrow().draftText("copies"), "8")
        @Assert(domain.cards.card("cardB").getOrThrow().draftText("copies"), "3")
        // 10. Apply through the generated action row: only A's owner commits.
        let applyEvent = controller.region.handleEvent(CjguiComposableUiEvent(
            runtimeChainLayoutNode(window, applyA), CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            "", 0, 0, window.windowProgress().acceptedSceneVersion))
        @Assert(applyEvent.didApply, true)
        @Assert(domain.cards.card("cardA").getOrThrow().appliedText("jobName"), "外部改 A")
        @Assert(domain.cards.card("cardA").getOrThrow().appliedText("copies"), "8")
        @Assert(domain.cards.card("cardB").getOrThrow().appliedText("jobName"), "资料 B")
        getStdOut().writeln("RUNTIME_CHAIN apply A=${domain.cards.card("cardA").getOrThrow().appliedText("copies")} " +
            "B=${domain.cards.card("cardB").getOrThrow().appliedText("copies")}")
        getStdOut().flush()
        getStdOut().writeln("RUNTIME_CHAIN counts ${controller.region.testWorkCounts()} " +
            "scene=${controller.region.sceneState()}")
        getStdOut().flush()
    } finally {
        host.close()
    }
    getStdOut().writeln("RUNTIME_CHAIN close=ok")
    getStdOut().flush()
}

@Test
func runtimeCompositionStaleSelectCannotWriteAfterRemoval(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    controller.collaborationOpened(true)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Runtime composition stale select", 1180u32, 760u32,
            rangeTextEditDeltaDelivery: true))
    let window = host.window()
    controller.attachWindow(window)
    @Assert(host.start(), true)
    try {
        for (_ in 0..96) {
            if (window.windowProgress().acceptedSceneVersion > 0) { break }
            let _ = host.pumpOneTurn()
        }
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        let v1 = controller.region.submitStructure(
            runtimeChainPayload("horizontal", "preset-card-title", "select", false, false, false), 0)
        @Assert(v1.candidateAccepted, true)
        let acceptMs = runtimeChainPump(host, window, 1, controller.region)
        getStdOut().writeln("RUNTIME_CHAIN removal stage=v1 structure=${controller.region.acceptedStructureVersion()} " +
            "scene=${controller.region.sceneState()}")
        getStdOut().flush()
        @Assert(controller.region.acceptedStructureVersion(), 1)
        let payload = controller.region.acceptedInstancesPayload()
        let duplexA = runtimeChainInstanceNodeId(payload, "cardA", "duplex")
        let semantic = runtimeChainElementSemantic(payload, "cardA", "duplex")
        @Assert(duplexA > 0, true)
        @Assert(semantic.size > 0, true)

        try {
            let openLayout = runtimeChainLayoutNode(window, duplexA)
            getStdOut().writeln("RUNTIME_CHAIN removal stage=trigger duplex=${duplexA} node=${openLayout.nodeId} " +
                "action=${openLayout.actionName} semantic=${openLayout.semanticId}")
            getStdOut().flush()
            let open = controller.region.handleEvent(CjguiComposableUiEvent(openLayout,
                CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, window.windowProgress().acceptedSceneVersion))
            getStdOut().writeln("RUNTIME_CHAIN removal stage=opened applied=${open.didApply}")
            getStdOut().flush()
            @Assert(open.didApply, true)
            let _ = window.refresh()
            for (_ in 0..32) { let _ = host.pumpOneTurn() }
        } catch (error: Exception) {
            getStdOut().writeln("RUNTIME_CHAIN removal caught=${error}")
            getStdOut().flush()
            throw error
        }
        let stalePopupRow = runtimeChainNodeBySemantic(window, "${semantic}-select-search")
        @Assert(runtimeChainHasAction(window, "${semantic}-select-choose:double"), true)
        getStdOut().writeln("RUNTIME_CHAIN removal stage=popup_open semantic=${semantic} duplex=${duplexA}")
        getStdOut().flush()

        // The definition and both instances are retired explicitly in one
        // candidate. The open popup must not survive as a writer for the
        // removed owner.
        let removeStarted = MonoTime.now()
        let removal = controller.region.submitStructure(runtimeChainRemovalPayload(), 1)
        @Assert(removal.candidateAccepted, true)
        @Assert(removal.reason, "")
        let removalMs = runtimeChainPump(host, window, 2, controller.region)
        getStdOut().writeln("RUNTIME_CHAIN removal candidate=${removal.candidateAccepted} " +
            "structure=${controller.region.acceptedStructureVersion()} scene=${controller.region.sceneState()} " +
            "pump_ms=${removalMs}")
        getStdOut().flush()
        @Assert(controller.region.acceptedStructureVersion(), 2)
        @Assert(!controller.region.capabilitiesPayload().contains("COMPOSITE runtimePresetCard"), true)
        @Assert(!controller.region.acceptedStructurePayload().contains("COMPOSITION runtimePresetCard"), true)
        @Assert(!runtimeChainHasAction(window, "${semantic}-select-search"), true)
        let stale = controller.region.handleEvent(CjguiComposableUiEvent(stalePopupRow, 35, "enter", 0, 0,
            window.windowProgress().acceptedSceneVersion))
        @Assert(!stale.didApply, true)
        @Assert(domain.cards.card("cardA").getOrThrow().draftBoolean("duplex"), false)
        getStdOut().writeln("RUNTIME_CHAIN removal accept_ms=${acceptMs} removal_ms=${removalMs} " +
            "structure=${controller.region.acceptedStructureVersion()} stale_applied=${stale.didApply} " +
            "scene=${controller.region.sceneState()}")
        getStdOut().flush()
    } finally {
        host.close()
    }
    getStdOut().writeln("RUNTIME_CHAIN removal_close=ok")
    getStdOut().flush()
}

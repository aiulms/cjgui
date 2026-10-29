// Second business consumer of the runtime composition definition: the rules
// window submits a definition and two instances bound to two REAL rule records
// through its ordinary generated region. It reuses the framework decoder,
// validator, expander and candidate transaction; no rule-specific composition
// factory or second interpreter exists in this application.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private class CjguiRuleCompositionSceneController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    private let region: CjguiRuleSetGeneratedRegion
    private var versionValue: Int64 = 1

    public init(domain: CjguiRuleSetEditingDomain) {
        this.region = CjguiRuleSetGeneratedRegion(domain)
    }

    public func generatedRegion(): CjguiRuleSetGeneratedRegion {
        return region
    }

    public func uiSceneVersion(): Int64 {
        return versionValue + region.revision()
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "rule-composition-root",
            CjguiComposableUiStyle(gap: 4))
        root.add(region.buildSection(CjguiComposableUiTheme.beaconDark(), CjguiComposableUiStyle()))
        return root
    }

    public func beginSceneRefresh(): Bool { return region.beginSceneRefresh() }
    public func prepareSceneRefresh(): Bool { return region.prepareSceneRefresh() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit { return region.commitSceneRefresh() }
    public func rollbackSceneRefresh(): Unit { return region.rollbackSceneRefresh() }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return region.handleEvent(event)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func rulesCompositionToken(line: String, prefix: String): String {
    for (token in line.split(" ")) {
        if (token.startsWith(prefix)) {
            return token[prefix.size..token.size]
        }
    }
    return ""
}

private func rulesCompositionInstanceNodeId(payload: String, key: String, element: String): Int64 {
    for (line in payload.split("\n")) {
        if (!line.startsWith("INSTANCE ${key} ") || rulesCompositionToken(line, "element=") != element) {
            continue
        }
        let idText = rulesCompositionToken(line, "id=")
        if (idText.size == 0) { return -1 }
        try {
            return Int64.parse(idText)
        } catch (_: Exception) {
            return -1
        }
    }
    return -1
}

private func rulesCompositionLayoutNode(window: CjguiComposableUiWindow,
    nodeId: Int64): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) { return node }
    }
    throw IllegalStateException("rules composition target is not accepted: ${nodeId}")
}

private func rulesCompositionPump(host: CjguiMacosApplicationHost, window: CjguiComposableUiWindow,
    region: CjguiRuleSetGeneratedRegion, targetVersion: Int64): Int64 {
    let started = MonoTime.now()
    let _ = window.refresh()
    for (_ in 0..96) {
        if (region.acceptedStructureVersion() == targetVersion) { break }
        let _ = host.pumpOneTurn()
    }
    return (MonoTime.now() - started).toMilliseconds()
}

private func rulesCompositionNodes(footer: String): String {
    let builder = StringBuilder()
    builder.append("NODE 0 board vertical\n")
    builder.append("NODE 1 deck horizontal\n")
    builder.append("NODE 2 rule1 runtimeRuleCard\n")
    builder.append("PROPERTY 2 rule1 title 规则一\n")
    builder.append("NODE 2 rule2 runtimeRuleCard\n")
    builder.append("PROPERTY 2 rule2 title 规则二\n")
    builder.append("NODE 1 footer label\n")
    builder.append("PROPERTY 1 footer text ${footer}\n")
    builder.append("END\n")
    return builder.toString()
}

private func rulesCompositionPayload(titleDefault: String, includeNote: Bool, ghostField: Bool): String {
    let builder = StringBuilder()
    builder.append("GENERATED_UI_STRUCTURE 2\n")
    builder.append("COMPOSITION runtimeRuleCard 64 8\n")
    builder.append("CPARAM title STRING 0 0 40 40 ${titleDefault}\n")
    builder.append("CELEMENT name field field=${if (ghostField) { "ghostLabel" } else { "label" }} argument=text\n")
    builder.append("CELEMENT retention field field=retentionCount argument=text\n")
    builder.append("CELEMENT apply action action=APPLY_DRAFT label=应用\n")
    builder.append("CTEMPLATE 0 root vertical gap=4\n")
    builder.append("CTEMPLATE 1 title label text=" + "$" + "{title}\n")
    builder.append("CTEMPLATE 1 name element element=name presentation=text\n")
    builder.append("CTEMPLATE 1 retention element element=retention presentation=text\n")
    builder.append("CTEMPLATE 1 apply element element=apply presentation=text\n")
    if (includeNote) {
        builder.append("CTEMPLATE 1 note label text=布局已更新\n")
    }
    builder.append(rulesCompositionNodes("运行时组合"))
    return builder.toString()
}

private func rulesCompositionLayoutOnlyPayload(): String {
    return "GENERATED_UI_STRUCTURE 2\n" + rulesCompositionNodes("普通布局刷新")
}

@Test
func runtimeCompositionDrivesTwoRealRuleRecords(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    @Assert(domain.createRecordFromHuman("规则一", true, 7, "cache", "rules-composition-a").applied, true)
    @Assert(domain.createRecordFromHuman("规则二", true, 9, "cache", "rules-composition-b").applied, true)
    let initial = domain.snapshot()
    @Assert(initial.records.size, 2)
    let recordA = initial.records[0].id
    let recordB = initial.records[1].id
    @Assert(domain.selectRecordFromHuman(recordA).applied, true)

    let controller = CjguiRuleCompositionSceneController(domain)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Rules runtime composition", 900u32, 640u32,
            rangeTextEditDeltaDelivery: true))
    let window = host.window()
    let region = controller.generatedRegion()
    region.attachWindow(window)
    @Assert(host.start(), true)
    try {
        for (_ in 0..96) {
            if (window.windowProgress().acceptedSceneVersion > 0) { break }
            let _ = host.pumpOneTurn()
        }
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)

        // Definition + two instances in ONE candidate against the rules catalog.
        let submitted = region.submitStructure(rulesCompositionPayload("规则", false, false), 0)
        @Assert(submitted.candidateAccepted, true)
        @Assert(submitted.reason, "")
        let acceptMs = rulesCompositionPump(host, window, region, 1)
        @Assert(region.acceptedStructureVersion(), 1)
        let payload = region.acceptedInstancesPayload()
        let nameA = rulesCompositionInstanceNodeId(payload, "rule1", "name")
        let nameB = rulesCompositionInstanceNodeId(payload, "rule2", "name")
        let applyA = rulesCompositionInstanceNodeId(payload, "rule1", "apply")
        @Assert(nameA > 0, true)
        @Assert(nameB > 0, true)
        @Assert(applyA > 0, true)
        @Assert(payload.contains("INSTANCE rule1 element=name") && payload.contains("owner=${recordA}"), true)
        @Assert(payload.contains("INSTANCE rule2 element=name") && payload.contains("owner=${recordB}"), true)

        // Each instance edits its own record's draft.
        let editA = region.handleEvent(CjguiComposableUiEvent(
            rulesCompositionLayoutNode(window, nameA), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED,
            "规则一改", 0, 0, window.windowProgress().acceptedSceneVersion))
        @Assert(editA.didApply, true)
        let editB = region.handleEvent(CjguiComposableUiEvent(
            rulesCompositionLayoutNode(window, nameB), CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED,
            "规则二改", 0, 0, window.windowProgress().acceptedSceneVersion))
        @Assert(editB.didApply, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(domain.formSnapshotForRecord(recordA).getOrThrow()
            .fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "规则一改")
        @Assert(domain.formSnapshotForRecord(recordB).getOrThrow()
            .fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "规则二改")
        @Assert(domain.snapshot().recordById(recordA).label, "规则一")
        @Assert(domain.snapshot().recordById(recordB).label, "规则二")

        // The per-instance action applies exactly the record it was rendered for.
        let applied = region.handleEvent(CjguiComposableUiEvent(
            rulesCompositionLayoutNode(window, applyA), CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            "", 0, 0, window.windowProgress().acceptedSceneVersion))
        @Assert(applied.didApply, true)
        @Assert(domain.snapshot().recordById(recordA).label, "规则一改")
        @Assert(domain.snapshot().recordById(recordB).label, "规则二")
        @Assert(domain.formSnapshotForRecord(recordB).getOrThrow()
            .fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "规则二改")
        // A later ordinary layout candidate that OMITS the definition keeps the
        // accepted definition: the same instances still expand and edit.
        let layoutOnly = region.submitStructure(rulesCompositionLayoutOnlyPayload(), 1)
        @Assert(layoutOnly.candidateAccepted, true)
        @Assert(layoutOnly.reason, "")
        let layoutMs = rulesCompositionPump(host, window, region, 2)
        @Assert(region.acceptedStructureVersion(), 2)
        @Assert(region.capabilitiesPayload().contains("COMPOSITE runtimeRuleCard"), true)
        let afterLayout = region.acceptedStructurePayload()
        @Assert(afterLayout.contains("COMPOSITION runtimeRuleCard 64 8"), true)
        @Assert(afterLayout.contains("COMPOSITION_END runtimeRuleCard"), true)
        let layoutPayload = region.acceptedInstancesPayload()
        @Assert(rulesCompositionInstanceNodeId(layoutPayload, "rule1", "name"), nameA)
        @Assert(rulesCompositionInstanceNodeId(layoutPayload, "rule2", "name"), nameB)
        @Assert(domain.formSnapshotForRecord(recordA).getOrThrow()
            .fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "规则一改")

        // A same-name definition update applies through the SAME candidate
        // path; identities, drafts and the other record survive.
        let ruleOneBefore = region.acceptedNodeIdForKey("rule1")
        let updatedDefinition = region.submitStructure(rulesCompositionPayload("规则*", true, false), 2)
        @Assert(updatedDefinition.candidateAccepted, true)
        let updateMs = rulesCompositionPump(host, window, region, 3)
        @Assert(region.acceptedStructureVersion(), 3)
        let updatedStructure = region.acceptedStructurePayload()
        @Assert(updatedStructure.contains("CPARAM title STRING 0 0 40 40 规则*"), true)
        @Assert(updatedStructure.contains("CTEMPLATE 1 note label "), true)
        @Assert(updatedStructure.contains("text=布局已更新"), true)
        @Assert(region.acceptedNodeIdForKey("rule1"), ruleOneBefore)
        @Assert(domain.formSnapshotForRecord(recordA).getOrThrow()
            .fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "规则一改")
        @Assert(domain.formSnapshotForRecord(recordB).getOrThrow()
            .fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText, "规则二改")

        // A refused update keeps the accepted definition and readback.
        let refused = region.submitStructure(rulesCompositionPayload("坏定义", true, true), 3)
        @Assert(!refused.candidateAccepted, true)
        @Assert(refused.reason.startsWith("composition_rejected:composition_unknown_field:ghostLabel"), true)
        @Assert(region.acceptedStructureVersion(), 3)
        @Assert(region.acceptedStructurePayload().contains("CPARAM title STRING 0 0 40 40 规则*"), true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(region.sceneState().startsWith("scene_accepted"), true)
        getStdOut().writeln("RULES_COMPOSITION accepted=true structure=${region.acceptedStructureVersion()} " +
            "accept_ms=${acceptMs} layout_ms=${layoutMs} update_ms=${updateMs} " +
            "scene=${region.sceneState()} records=${recordA},${recordB}")
        getStdOut().flush()
    } finally {
        window.close()
    }
    getStdOut().writeln("RULES_COMPOSITION close=ok")
    getStdOut().flush()
}

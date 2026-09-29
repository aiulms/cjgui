package cjgui_settings_counter_application

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func generatedNameWrite(domain: CjguiSettingsCounterDomain, text: String): CjguiSharedOperationActionResult {
    return domain.executeFromHuman(CjguiSharedOperationActionInvocation("EDIT_NAME",
        domain.counterSnapshot().version, ArrayList<Int64>([CjguiSettingsCounterDomain.resourceId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(text))
        ])))
}

@Test
func settingsNameLimitUsesPublishedUnicodeScalarUnit(): Unit {
    let domain = CjguiSettingsCounterDomain()
    // Eleven scalars are below the published 32-scalar name limit even though
    // their UTF-8 representation occupies 33 bytes.
    let result = generatedNameWrite(domain, "汉汉汉汉汉汉汉汉汉汉汉")
    @Assert(result.applied, true)
    @Assert(domain.counterSnapshot().name, "汉汉汉汉汉汉汉汉汉汉汉")
}

@Test
func settingsGeneratedUiIsAuthorizedAndWindowTransactionOwned(): Unit {
    let authorization = settingsCounterAuthorization()
    @Assert(authorization.permitsAction("GET_GENERATED_UI"), true)
    @Assert(authorization.permitsAction("GET_WINDOW_INTERACTION"), true)
    @Assert(authorization.permitsAction("SUBMIT_GENERATED_UI"), true)
    let controller = CjguiSettingsCounterController(CjguiSettingsCounterDomain())
    @Assert((controller as CjguiComposableUiSceneRefreshParticipant).isSome(), true)
    @Assert(controller.beginSceneRefresh(), true)
    let _ = controller.buildUi()
    @Assert(controller.prepareSceneRefresh(), true)
    controller.commitSceneRefresh()
    @Assert(controller.generatedUiRegion().sceneState(), "")
    @Assert(controller.generatedUiRegion().snapshotPayload().contains("OWNER_PENDING_SCENE 0"), true)
}

private let SETTINGS_GENERATED_PANEL = """
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
PROPERTY 0 board gap 6
NODE 1 title label
PROPERTY 1 title text 设置生成区
NODE 1 editors horizontal
NODE 2 nameEditor textInput field=name
PROPERTY 2 nameEditor label 名称
NODE 2 aliasEditor textInput field=alias
PROPERTY 2 aliasEditor label 别名
NODE 1 add action action=INCREMENT
PROPERTY 1 add label 生成增加
END"""

private func acceptSettingsPanel(controller: CjguiSettingsCounterController): Int64 {
    let region = controller.generatedUiRegion()
    let result = region.submitStructure(SETTINGS_GENERATED_PANEL, region.acceptedStructureVersion())
    @Assert(result.candidateAccepted, true)
    @Assert(result.sceneAccepted, false)
    @Assert(region.acceptedStructureVersion(), 0)
    @Assert(controller.beginSceneRefresh(), true)
    let _ = controller.buildUi()
    @Assert(controller.prepareSceneRefresh(), true)
    controller.commitSceneRefresh()
    @Assert(region.acceptedStructureVersion(), 1)
    return result.candidateToken
}

private func generatedSettingsEditor(region: CjguiGeneratedUiWindowRegion, key: String,
    fieldId: String, writer: String): CjguiComposableUiLayoutNode {
    let id = region.acceptedNodeIdForKey(key)
    let bounds = CjguiComposableUiRect(0, 0, 200, 40)
    let node = cjguiComposableTextInput(id, "generated-${key}", fieldId, "",
        CjguiSettingsCounterDomain.resourceId, CjguiComposableUiStyle(fixedHeight: 40),
        fieldId: fieldId, operationActionName: writer,
        operationResourceId: CjguiSettingsCounterDomain.resourceId, displayValueRole: "draft")
    return CjguiComposableUiLayoutNode(node, bounds, bounds)
}

private func settingsNodeById(root: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (root.nodeId == nodeId) { return Some(root) }
    for (child in root.children()) {
        if (let Some(found) <- settingsNodeById(child, nodeId)) { return Some(found) }
    }
    return None
}

private func generatedSettingsAction(controller: CjguiSettingsCounterController,
    region: CjguiGeneratedUiWindowRegion, key: String): CjguiComposableUiLayoutNode {
    let id = region.acceptedNodeIdForKey(key)
    let bounds = CjguiComposableUiRect(0, 0, 200, 40)
    let node = match (settingsNodeById(controller.buildUi(), id)) {
        case Some(value) => value
        case None => throw IllegalArgumentException("accepted_generated_action_missing")
    }
    return CjguiComposableUiLayoutNode(node, bounds, bounds)
}

@Test
func settingsGeneratedCandidateUsesSceneCommitAndOwnerEventRoute(): Unit {
    let domain = CjguiSettingsCounterDomain()
    let controller = CjguiSettingsCounterController(domain)
    let token = acceptSettingsPanel(controller)
    let region = controller.generatedUiRegion()
    @Assert(region.candidateTicketPayload(token).contains("TERMINAL_STATE ACCEPTED"), true)
    @Assert(region.snapshotPayload().contains("OWNER_PENDING_SCENE 0"), true)
    let editor = generatedSettingsEditor(region, "nameEditor", "name", "EDIT_NAME")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(editor, 28, "生成姓名", 0, 0, 1)).didApply, true)
    @Assert(domain.counterSnapshot().name, "生成姓名")
    @Assert(domain.counterSnapshot().version, 1)
    let action = generatedSettingsAction(controller, region, "add")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(action, 27, "", 0, 0, 2)).didApply, true)
    @Assert(domain.counterSnapshot().count, 11)
    @Assert(domain.counterSnapshot().version, 2)
    // Ordinary owner input/scene refresh must not parse or validate the
    // generated structure again.
    @Assert(region.testWorkCounts().contains("decodes=1 validations=1"), true)
}

@Test
func settingsOldGeneratedActionCannotRouteAfterSameKeyRebind(): Unit {
    let domain = CjguiSettingsCounterDomain()
    let controller = CjguiSettingsCounterController(domain)
    let _ = acceptSettingsPanel(controller)
    let region = controller.generatedUiRegion()
    let oldAction = generatedSettingsAction(controller, region, "add")
    let rebound = SETTINGS_GENERATED_PANEL.replace("NODE 1 add action action=INCREMENT",
        "NODE 1 add action action=DECREMENT")
    let candidate = region.submitStructure(rebound, 1)
    @Assert(candidate.candidateAccepted, true)
    @Assert(controller.beginSceneRefresh(), true)
    let _ = controller.buildUi()
    @Assert(controller.prepareSceneRefresh(), true)
    controller.commitSceneRefresh()
    @Assert(region.acceptedStructureVersion(), 2)
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(oldAction, 27, "", 0, 0, 2)).didApply, false)
    @Assert(domain.counterSnapshot().count, 10)
    @Assert(domain.counterSnapshot().version, 0)
    let newAction = generatedSettingsAction(controller, region, "add")
    @Assert(controller.applyUiEvent(CjguiComposableUiEvent(newAction, 27, "", 0, 0, 2)).didApply, true)
    @Assert(domain.counterSnapshot().count, 9)
    @Assert(domain.counterSnapshot().version, 1)
}

@Test
func settingsRejectedAndRolledBackCandidatesPreserveAcceptedPanel(): Unit {
    let domain = CjguiSettingsCounterDomain()
    let controller = CjguiSettingsCounterController(domain)
    let _ = acceptSettingsPanel(controller)
    let region = controller.generatedUiRegion()
    let nameId = region.acceptedNodeIdForKey("nameEditor")
    let invalid = region.submitStructure("GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\n" +
        "NODE 1 foreign unknownControl\nEND", 1)
    @Assert(invalid.candidateAccepted, false)
    @Assert(invalid.reason, "unknown_component")
    let stale = region.submitStructure(SETTINGS_GENERATED_PANEL, 0)
    @Assert(stale.candidateAccepted, false)
    @Assert(stale.reason, "structure_version_conflict")
    let pending = region.submitStructure(SETTINGS_GENERATED_PANEL, 1)
    @Assert(pending.candidateAccepted, true)
    @Assert(controller.beginSceneRefresh(), true)
    let _ = controller.buildUi()
    @Assert(controller.prepareSceneRefresh(), true)
    controller.rollbackSceneRefresh()
    @Assert(region.candidateTicketPayload(pending.candidateToken).contains("TERMINAL_STATE REJECTED"), true)
    @Assert(region.acceptedStructureVersion(), 1)
    @Assert(region.acceptedNodeIdForKey("nameEditor"), nameId)
    @Assert(domain.counterSnapshot().version, 0)
}

@Test
func settingsInFlightCandidateCannotBeSuperseded(): Unit {
    let controller = CjguiSettingsCounterController(CjguiSettingsCounterDomain())
    let region = controller.generatedUiRegion()
    let a = region.submitStructure(SETTINGS_GENERATED_PANEL, 0)
    @Assert(a.candidateAccepted, true)
    @Assert(controller.beginSceneRefresh(), true)
    let _ = controller.buildUi()
    @Assert(controller.prepareSceneRefresh(), true)
    let b = region.submitStructure(SETTINGS_GENERATED_PANEL, 0)
    @Assert(b.candidateAccepted, false)
    @Assert(b.reason, "scene_transaction_busy")
    @Assert(region.candidateTicketPayload(a.candidateToken).contains("TERMINAL_STATE PENDING"), true)
    controller.commitSceneRefresh()
    @Assert(region.candidateTicketPayload(a.candidateToken).contains("TERMINAL_STATE ACCEPTED"), true)
    @Assert(region.acceptedStructureVersion(), 1)
}

@Test
func settingsPreSurfaceCloseSettlesPendingTicket(): Unit {
    let controller = CjguiSettingsCounterController(CjguiSettingsCounterDomain())
    let region = controller.generatedUiRegion()
    let submit = region.submitStructure(SETTINGS_GENERATED_PANEL, 0)
    @Assert(submit.candidateAccepted, true)
    region.rejectPendingOnClose()
    @Assert(region.candidateTicketPayload(submit.candidateToken).contains("TERMINAL_STATE REJECTED"), true)
    @Assert(region.candidateTicketPayload(submit.candidateToken).contains("REASON window_closed"), true)
    @Assert(region.sceneState(), "scene_rejected:window_closed")
    @Assert(region.acceptedStructureVersion(), 0)
}

private func settingsImagePanel(version: Int64): String {
    return "GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\n" +
        "NODE 1 icon image\nPROPERTY 1 icon resource settings-beacon\n" +
        "PROPERTY 1 icon resourceVersion ${version}\nPROPERTY 1 icon contentMode fill\n" +
        "PROPERTY 1 icon fixedWidth 160\nPROPERTY 1 icon fixedHeight 72\n" +
        "NODE 1 editor textInput field=name\nPROPERTY 1 editor label 名称\nEND"
}

@Test
func settingsImageVersionUsesOneDeclarationForHandwrittenAndGeneratedNodes(): Unit {
    let domain = CjguiSettingsCounterDomain()
    let controller = CjguiSettingsCounterController(domain)
    let region = controller.generatedUiRegion()
    let v1 = domain.imageResourceSpec()
    @Assert(v1.key, "settings-beacon")
    @Assert(v1.version, 1)
    @Assert(v1.rasterPath, "/data/storage/el2/base/files/cjgui_image_v1.png")
    let hand1 = match (settingsNodeById(controller.buildUi(), CjguiSettingsCounterController.nodeIdImage)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("settings_handwritten_image_missing")
    }
    @Assert(hand1.imageResourceId, v1.key)
    @Assert(hand1.imageResourcePath, v1.rasterPath)
    @Assert(hand1.imageResourceVersion, v1.version)
    @Assert(region.capabilitiesPayload().contains("IMAGE_RESOURCE settings-beacon PNG 1"), true)

    let first = region.submitStructure(settingsImagePanel(1), 0)
    @Assert(first.candidateAccepted, true)
    @Assert(controller.beginSceneRefresh(), true)
    let _ = controller.buildUi()
    @Assert(controller.prepareSceneRefresh(), true)
    controller.commitSceneRefresh()
    let generatedId = region.acceptedNodeIdForKey("icon")
    let generated1 = match (settingsNodeById(controller.buildUi(), generatedId)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("settings_generated_image_missing")
    }
    @Assert(generated1.imageResourceId, v1.key)
    @Assert(generated1.imageResourcePath, v1.rasterPath)
    @Assert(generated1.imageResourceVersion, v1.version)

    let switched = domain.executeFromHuman(CjguiSharedOperationActionInvocation("SWITCH_IMAGE",
        domain.counterSnapshot().version, ArrayList<Int64>([CjguiSettingsCounterDomain.resourceId]),
        ArrayList<CjguiSharedOperationActionArgument>()))
    @Assert(switched.applied, true)
    let v2 = domain.imageResourceSpec()
    @Assert(v2.version, 2)
    @Assert(v2.rasterPath, "/data/storage/el2/base/files/cjgui_image_v2.png")
    let hand2 = match (settingsNodeById(controller.buildUi(), CjguiSettingsCounterController.nodeIdImage)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("settings_handwritten_image_missing_after_switch")
    }
    @Assert(hand2.imageResourceVersion, 2)
    // The already accepted generated image keeps its exact v1 binding while
    // the directory rejects any newly proposed v1 reference.
    let acceptedOld = match (settingsNodeById(controller.buildUi(), generatedId)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("settings_accepted_image_lost")
    }
    @Assert(acceptedOld.imageResourcePath, v1.rasterPath)
    @Assert(acceptedOld.imageResourceVersion, 1)
    let stale = region.submitStructure(settingsImagePanel(1), 1)
    @Assert(stale.candidateAccepted, false)
    @Assert(stale.reason, "image_resource_version_mismatch")
    @Assert(region.acceptedStructureVersion(), 1)
    @Assert(region.capabilitiesPayload().contains("IMAGE_RESOURCE settings-beacon PNG 2"), true)
    let second = region.submitStructure(settingsImagePanel(2), 1)
    @Assert(second.candidateAccepted, true)
    @Assert(controller.beginSceneRefresh(), true)
    let _ = controller.buildUi()
    @Assert(controller.prepareSceneRefresh(), true)
    controller.commitSceneRefresh()
    let generated2 = match (settingsNodeById(controller.buildUi(), generatedId)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("settings_generated_image_v2_missing")
    }
    @Assert(generated2.imageResourcePath, v2.rasterPath)
    @Assert(generated2.imageResourceVersion, 2)
}

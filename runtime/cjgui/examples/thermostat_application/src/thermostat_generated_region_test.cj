package cjgui_thermostat_application

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func thermostatNoteLimitUsesPublishedUnicodeScalarUnit(): Unit {
    let domain = CjguiThermostatDomain()
    // 22 Han scalars are inside the declared 64-scalar limit; their UTF-8
    // encoding occupies 66 bytes and exposes the old byte-count mismatch.
    let note = "汉汉汉汉汉汉汉汉汉汉汉汉汉汉汉汉汉汉汉汉汉汉"
    let result = domain.executeFromHuman(CjguiSharedOperationActionInvocation("SET_NOTE",
        domain.thermostatSnapshot().version, ArrayList<Int64>([CjguiThermostatDomain.resourceId]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(note))
        ])))
    @Assert(result.applied, true)
    @Assert(domain.thermostatSnapshot().note, note)
}

@Test
func thermostatGeneratedUiIsAuthorizedAndWindowTransactionOwned(): Unit {
    let authorization = thermostatAuthorization()
    @Assert(authorization.permitsAction("GET_GENERATED_UI"), true)
    @Assert(authorization.permitsAction("GET_WINDOW_INTERACTION"), true)
    @Assert(authorization.permitsAction("SUBMIT_GENERATED_UI"), true)
    let controller = CjguiThermostatController(CjguiThermostatDomain())
    @Assert((controller as CjguiComposableUiSceneRefreshParticipant).isSome(), true)
}

private func thermoImageNodeById(root: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (root.nodeId == nodeId) { return Some(root) }
    for (child in root.children()) {
        if (let Some(found) <- thermoImageNodeById(child, nodeId)) { return Some(found) }
    }
    return None
}

private func thermoImagePanel(version: Int64): String {
    return "GENERATED_UI_STRUCTURE 1\nNODE 0 board vertical\n" +
        "NODE 1 icon image\nPROPERTY 1 icon resource thermo-heat-map\n" +
        "PROPERTY 1 icon resourceVersion ${version}\nPROPERTY 1 icon contentMode fit\n" +
        "PROPERTY 1 icon fixedWidth 160\nPROPERTY 1 icon fixedHeight 72\n" +
        "NODE 1 editor textInput field=note\nPROPERTY 1 editor label 备注\nEND"
}

@Test
func thermostatImageButtonSwitchKeepsAcceptedGeneratedVersionUntilReplaced(): Unit {
    let domain = CjguiThermostatDomain()
    let controller = CjguiThermostatController(domain)
    let region = controller.generatedUiRegion()
    let v1 = domain.imageResourceSpec()
    @Assert(v1.key, "thermo-heat-map")
    @Assert(v1.version, 1)
    @Assert(v1.rasterPath, "/data/storage/el2/base/files/cjgui_image_v1.png")
    let hand1 = match (thermoImageNodeById(controller.buildUi(), CjguiThermostatController.nodeIdImage)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("thermo_handwritten_image_missing")
    }
    @Assert(hand1.imageResourceId, v1.key)
    @Assert(hand1.imageResourcePath, v1.rasterPath)
    @Assert(region.capabilitiesPayload().contains("IMAGE_RESOURCE thermo-heat-map PNG 1"), true)
    let first = region.submitStructure(thermoImagePanel(1), 0)
    @Assert(first.candidateAccepted, true)
    @Assert(controller.beginSceneRefresh(), true)
    let _ = controller.buildUi()
    @Assert(controller.prepareSceneRefresh(), true)
    controller.commitSceneRefresh()
    let generatedId = region.acceptedNodeIdForKey("icon")
    let generated1 = match (thermoImageNodeById(controller.buildUi(), generatedId)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("thermo_generated_image_missing")
    }
    @Assert(generated1.imageResourcePath, v1.rasterPath)

    let button = match (thermoImageNodeById(controller.buildUi(), CjguiThermostatController.nodeIdImageSwitch)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("thermo_image_switch_missing")
    }
    let bounds = CjguiComposableUiRect(0, 0, 180, 56)
    let event = CjguiComposableUiEvent(CjguiComposableUiLayoutNode(button, bounds, bounds), 27, "", 0, 0, 1)
    @Assert(controller.applyUiEvent(event).didApply, true)
    let v2 = domain.imageResourceSpec()
    @Assert(v2.version, 2)
    @Assert(v2.rasterPath, "/data/storage/el2/base/files/cjgui_image_v2.png")
    let hand2 = match (thermoImageNodeById(controller.buildUi(), CjguiThermostatController.nodeIdImage)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("thermo_handwritten_v2_missing")
    }
    @Assert(hand2.imageResourceVersion, 2)
    let acceptedOld = match (thermoImageNodeById(controller.buildUi(), generatedId)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("thermo_accepted_v1_lost")
    }
    @Assert(acceptedOld.imageResourceVersion, 1)
    @Assert(acceptedOld.imageResourcePath, v1.rasterPath)
    let stale = region.submitStructure(thermoImagePanel(1), 1)
    @Assert(stale.candidateAccepted, false)
    @Assert(stale.reason, "image_resource_version_mismatch")
    @Assert(region.acceptedStructureVersion(), 1)
    @Assert(region.capabilitiesPayload().contains("IMAGE_RESOURCE thermo-heat-map PNG 2"), true)
    let next = region.submitStructure(thermoImagePanel(2), 1)
    @Assert(next.candidateAccepted, true)
    @Assert(controller.beginSceneRefresh(), true)
    let _ = controller.buildUi()
    @Assert(controller.prepareSceneRefresh(), true)
    controller.commitSceneRefresh()
    let generated2 = match (thermoImageNodeById(controller.buildUi(), generatedId)) {
        case Some(node) => node
        case None => throw IllegalArgumentException("thermo_generated_v2_missing")
    }
    @Assert(generated2.imageResourceVersion, 2)
    @Assert(generated2.imageResourcePath, v2.rasterPath)
}

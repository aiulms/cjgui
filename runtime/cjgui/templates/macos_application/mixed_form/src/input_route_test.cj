package cjgui_mixed_form_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private func mixedRouteNode(window: CjguiComposableUiWindow, id: Int64): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == id) { return node }
    }
    throw IllegalStateException("mixed route node not accepted: ${id}")
}

private func mixedRouteComplete(window: CjguiComposableUiWindow, after: Int64): Unit {
    let began = MonoTime.now()
    while (window.windowProgress().acceptedSceneVersion <= after &&
        (MonoTime.now() - began).toNanoseconds() < 5000000000) {
        let _ = window.refreshIfNeeded()
        let _ = window.pump(0u32)
    }
    @Assert(window.windowProgress().acceptedSceneVersion > after, true)
}

private func mixedRouteSelect(domain: PrintPresetDomain, window: CjguiComposableUiWindow, key: String): Unit {
    let before = window.windowProgress().acceptedSceneVersion
    let call = CjguiSharedOperationActionInvocation("SELECT_CARD", domain.formSnapshot().contextVersion,
        ArrayList<Int64>([PrintPresetDomain.ownerId]), ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("cardKey", CjguiSharedOperationValue.string(key))]))
    @Assert(domain.executeFromHuman(call).applied, true)
    window.requestRefresh()
    mixedRouteComplete(window, before)
}

private func mixedRouteWindow(range: Bool,
    body: (PrintPresetDomain, MixedFormController, CjguiComposableUiWindow) -> Unit): Unit {
    cjguiMacosOwnerTest({ =>
        let domain = PrintPresetDomain()
        let controller = MixedFormController(domain)
        let window = CjguiComposableUiWindow(controller, configuration:
            CjguiMacosApplicationWindowConfiguration("DS18 mixed route contract", 1000u32, 680u32,
                rangeTextEditDeltaDelivery: range))
        controller.attachWindow(window)
        try {
            @Assert(window.start(), true)
            mixedRouteComplete(window, 0)
            body(domain, controller, window)
        } finally { window.close() }
    })
}

@Test
func mixedRouteOwnedWholeIsObservationAndRangeWritesOnce(): Unit {
    mixedRouteWindow(true, { domain, controller, window =>
        let a = domain.cards.card("cardA").getOrThrow()
        let b = domain.cards.card("cardB").getOrThrow()
        let untouchedB = b.draftText("jobName")
        let node = mixedRouteNode(window, 910)
        @Assert(node.operationResourceId, a.ownerId)
        @Assert(window.focusAcceptedNodeById(node.nodeId), true)
        @Assert(window.ownedTextSessionBoundNodeId(), node.nodeId)
        let session = window.textSession().getOrThrow()
        let aliasHolder = CjguiGeneratedUiStructureHolder(
            CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId).capabilityCatalog())
        aliasHolder.beginHandwrittenInstanceAliasRefresh()
        aliasHolder.declareHandwrittenInstanceAlias(node.nodeId, "cardA")
        aliasHolder.commitHandwrittenInstanceAliasRefresh(acceptedNodes: Some(window.acceptedSceneNodes()))
        let aliasIntent = aliasHolder.resolveIntent(node, CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "A-route-once")
        println("MIXED_ROUTE_ALIAS accepted_alias=${aliasHolder.compositeInstanceKeyForNodeId(node.nodeId)} " +
            "generated_key=[${aliasHolder.keyForNodeId(node.nodeId)}] field_intent=${aliasIntent.isFieldEdit()}")
        let before = a.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion
        let old = a.draftText("jobName")
        let whole = controller.applyUiEvent(CjguiComposableUiEvent(node,
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "A-route-once", 12, 12,
            window.windowProgress().acceptedSceneVersion))
        let afterWhole = a.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion
        let delta = session.replaceRange16(0, cjguiUtf16Length(old), "A-route-once")
        println("MIXED_ROUTE_OWNED key=cardA before=${before} whole=${whole.didApply} " +
            "afterWhole=${afterWhole} range=${delta.accepted} reason=${delta.reason} " +
            "after=${a.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion} body=[${a.draftText("jobName")}]")
        @Assert(aliasIntent.isFieldEdit(), true)
        @Assert(whole.didApply, false)
        @Assert(afterWhole, before)
        @Assert(delta.accepted, true)
        @Assert(session.awaitingCalibration(), false)
        @Assert(a.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion, before + 1)
        @Assert(a.draftText("jobName"), "A-route-once")
        @Assert(b.draftText("jobName"), untouchedB)

        mixedRouteSelect(domain, window, "cardB")
        let current = mixedRouteNode(window, 910)
        @Assert(current.operationResourceId, b.ownerId)
        @Assert(window.focusAcceptedNodeById(current.nodeId), true)
        let bSession = window.textSession().getOrThrow()
        let bBefore = b.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion
        let bOld = b.draftText("jobName")
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(current,
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "B-route-once", 12, 12,
            window.windowProgress().acceptedSceneVersion)).didApply, false)
        @Assert(b.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion, bBefore)
        @Assert(bSession.replaceRange16(0, cjguiUtf16Length(bOld), "B-route-once").accepted, true)
        @Assert(b.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion, bBefore + 1)
        @Assert(b.draftText("jobName"), "B-route-once")
        @Assert(a.draftText("jobName"), "A-route-once")
        @Assert(session.replaceRange16(0, 0, "retired-A").accepted, false)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(node,
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "late-A", 6, 6,
            window.windowProgress().acceptedSceneVersion)).didApply, false)
        @Assert(a.draftText("jobName"), "A-route-once")
        @Assert(b.draftText("jobName"), "B-route-once")
    })
}

@Test
func mixedRouteWholeValueBooleanAndRefusalsKeepOriginalOwner(): Unit {
    mixedRouteWindow(false, { domain, controller, window =>
        let a = domain.cards.card("cardA").getOrThrow()
        let b = domain.cards.card("cardB").getOrThrow()
        let untouchedB = b.draftText("jobName")
        let aNode = mixedRouteNode(window, 910)
        @Assert(window.ownedTextSessionBoundNodeId(), -1)
        let before = a.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(aNode, 28, "whole-A", 7, 7,
            window.windowProgress().acceptedSceneVersion)).didApply, true)
        @Assert(a.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion, before + 1)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(aNode, 28, "whole-A", 7, 7,
            window.windowProgress().acceptedSceneVersion)).didApply, true)
        @Assert(a.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion, before + 1)
        let boolean = mixedRouteNode(window, 930)
        let boolVersion = a.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6203).draftFieldVersion
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(boolean, 29, "true", 0, 0,
            window.windowProgress().acceptedSceneVersion)).didApply, true)
        @Assert(a.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6203).draftFieldVersion, boolVersion + 1)
        @Assert(a.draftBoolean("duplex"), Some(true))
        @Assert(b.draftText("jobName"), untouchedB)
        a.setLocked(true)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(aNode, 28, "locked-A", 8, 8,
            window.windowProgress().acceptedSceneVersion)).didApply, false)
        @Assert(a.draftText("jobName"), "whole-A")

        mixedRouteSelect(domain, window, "cardB")
        let bNode = mixedRouteNode(window, 910)
        let bBefore = b.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion
        let late = controller.applyUiEvent(CjguiComposableUiEvent(aNode, 28, "must-not-hit-B", 15, 15,
            window.windowProgress().acceptedSceneVersion))
        println("MIXED_ROUTE_LATE applied=${late.didApply} bBefore=${bBefore} " +
            "bAfter=${b.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion} body=[${b.draftText("jobName")}]")
        @Assert(late.didApply, false)
        @Assert(b.draftText("jobName"), untouchedB)
        @Assert(b.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion, bBefore)
        let malformed = cjguiComposableTextInput(bNode.nodeId, bNode.semanticId, "wrong writer", "bad", 6201,
            CjguiComposableUiStyle(), fieldId: "jobName", operationActionName: "WRONG_WRITER",
            operationResourceId: b.ownerId)
        malformed.semanticIncarnation = bNode.semanticIncarnation
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(
            CjguiComposableUiLayoutNode(malformed, bNode.bounds, bNode.clip), 28, "bad", 3, 3,
            window.windowProgress().acceptedSceneVersion)).didApply, false)
        @Assert(b.snapshot(domain.formSnapshot().contextVersion).fieldForResourceId(6201).draftFieldVersion, bBefore)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(bNode, 28, "whole-B", 7, 7,
            window.windowProgress().acceptedSceneVersion)).didApply, true)
        @Assert(b.draftText("jobName"), "whole-B")
        let accepted = window.windowProgress().acceptedSceneVersion
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(mixedRouteNode(window, 904),
            CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, accepted)).didApply, true)
        window.requestRefresh()
        mixedRouteComplete(window, accepted)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(bNode, 28, "retired-B", 9, 9,
            window.windowProgress().acceptedSceneVersion)).didApply, false)
        @Assert(b.draftText("jobName"), "whole-B")
        @Assert(a.draftText("jobName"), "whole-A")
    })
}

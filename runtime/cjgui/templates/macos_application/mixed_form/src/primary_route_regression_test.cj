package cjgui_mixed_form_starter

import cjgui.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private func primaryRouteNode(window: CjguiComposableUiWindow, id: Int64): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == id) { return node }
    }
    throw IllegalStateException("mixed route node not accepted: ${id}")
}

private func primaryRouteComplete(window: CjguiComposableUiWindow, after: Int64): Unit {
    let began = MonoTime.now()
    while (window.windowProgress().acceptedSceneVersion <= after &&
        (MonoTime.now() - began).toNanoseconds() < 5000000000) {
        let _ = window.refreshIfNeeded()
        let _ = window.pump(0u32)
    }
    @Assert(window.windowProgress().acceptedSceneVersion > after, true)
}

private func primaryRouteWindow(range: Bool,
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
            primaryRouteComplete(window, 0)
            body(domain, controller, window)
        } finally { window.close() }
    })
}

@Test
func mixedRoutePrimaryWholeValueUsesAcceptedFormTarget(): Unit {
    primaryRouteWindow(false, { domain, controller, window =>
        let a = domain.cards.card("cardA").getOrThrow().draftText("jobName")
        let b = domain.cards.card("cardB").getOrThrow().draftText("jobName")
        let beforeScene = window.windowProgress().acceptedSceneVersion
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(primaryRouteNode(window, 1904),
            CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, beforeScene)).didApply, true)
        window.requestRefresh()
        primaryRouteComplete(window, beforeScene)
        let field = primaryRouteNode(window, 101)
        @Assert(field.operationResourceId, PrintPresetDomain.ownerId)
        let before = domain.formSnapshot().fieldForResourceId(6201).draftFieldVersion
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(field,
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "primary-whole", 13, 13,
            window.windowProgress().acceptedSceneVersion)).didApply, true)
        @Assert(domain.formSnapshot().fieldForResourceId(6201).draftText, "primary-whole")
        @Assert(domain.formSnapshot().fieldForResourceId(6201).draftFieldVersion, before + 1)
        let malformed = cjguiComposableTextInput(field.nodeId, field.semanticId, "Name", "bad", 6201,
            CjguiComposableUiStyle(), fieldId: field.fieldId, operationActionName: "WRONG_WRITER",
            operationResourceId: PrintPresetDomain.ownerId)
        malformed.semanticIncarnation = field.semanticIncarnation
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(
            CjguiComposableUiLayoutNode(malformed, field.bounds, field.clip),
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "bad", 3, 3,
            window.windowProgress().acceptedSceneVersion)).didApply, false)
        @Assert(domain.formSnapshot().fieldForResourceId(6201).draftText, "primary-whole")
        @Assert(domain.formSnapshot().fieldForResourceId(6201).draftFieldVersion, before + 1)
        @Assert(domain.cards.card("cardA").getOrThrow().draftText("jobName"), a)
        @Assert(domain.cards.card("cardB").getOrThrow().draftText("jobName"), b)
        println("MIXED_ROUTE_PRIMARY accepted=true rejected_wrong_writer=true version=${before + 1}")
    })
}

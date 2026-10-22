package cjgui_mixed_form_starter

import cjgui.*
import std.env.*
import std.unittest.*
import std.unittest.testmacro.*

private func printAcceptedNode(window: CjguiComposableUiWindow, nodeId: Int64): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            return node
        }
    }
    throw IllegalStateException("print fixture target not accepted")
}

@Test
func printWindowOwnedWholePreviewDoesNotCompete(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    controller.collaborationOpened(true)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Print binding check", 1000u32, 680u32,
            rangeTextEditDeltaDelivery: true))
    let window = host.window()
    controller.attachWindow(window)
    @Assert(host.start(), true)
    try {
        for (_ in 0..64) {
            if (window.windowProgress().acceptedSceneVersion > 0) {
                break
            }
            let _ = host.pumpOneTurn()
        }
        @Assert(window.windowProgress().acceptedSceneVersion > 0, true)
        let candidate = "GENERATED_UI_STRUCTURE 1\nNODE 0 form vertical\n" +
            "NODE 1 job textInput field=jobName\nPROPERTY 1 job fixedHeight 40\n" +
            "NODE 1 number integerInput field=copies\nPROPERTY 1 number fixedHeight 40\nEND"
        let submitted = controller.region.submitStructure(candidate, 0)
        println("PRINT_CANDIDATE accepted=${submitted.candidateAccepted} reason=${submitted.reason}")
        getStdOut().flush()
        @Assert(submitted.candidateAccepted, true)
        let _ = window.refresh()
        for (_ in 0..64) {
            if (controller.region.acceptedStructureVersion() == 1) {
                break
            }
            let _ = host.pumpOneTurn()
        }
        @Assert(controller.region.acceptedStructureVersion(), 1)
        @Assert(window.ownedTextSessionBoundNodeId(), -1)
        let jobId = controller.region.acceptedNodeIdForKey("job")
        let numberId = controller.region.acceptedNodeIdForKey("number")
        let job = printAcceptedNode(window, jobId)
        let number = printAcceptedNode(window, numberId)
        // The unowned TEXT and ordinary INTEGER routes remain real writes.
        @Assert(controller.region.handleEvent(CjguiComposableUiEvent(job,
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "unowned", 7, 7, window.displayedSceneVersion())).didApply, true)
        @Assert(controller.region.handleEvent(CjguiComposableUiEvent(number,
            CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "6", 1, 1, window.displayedSceneVersion())).didApply, true)
        let _ = window.refresh()
        for (_ in 0..32) {
            let _ = host.pumpOneTurn()
        }
        @Assert(window.isTextRangeEditDeltaDeliveryEnabled(), true)
        @Assert(window.focusAcceptedNodeById(101), true)
        @Assert(window.ownedTextSessionBoundNodeId(), 101)
        @Assert(window.focusAcceptedNodeById(jobId), true)
        @Assert(window.ownedTextSessionBoundNodeId(), jobId)
        let before = domain.formSnapshot().draftVersion
        let owned = printAcceptedNode(window, jobId)
        let preview = controller
            .region
            .handleEvent(
                CjguiComposableUiEvent(owned, CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "duplicate-preview", 17, 17,
                    window.displayedSceneVersion()))
        println(
            "PRINT_ROUTE_CHECK preview_applied=${preview.didApply} owner_before=${before} owner_after=${domain.formSnapshot().draftVersion}")
        getStdOut().flush()
        @Assert(preview.didApply, false)
        @Assert(domain.formSnapshot().draftVersion, before)
        @Assert(domain.formSnapshot().fieldForResourceId(6201).draftText, "unowned")
        @Assert(domain.formSnapshot().fieldForResourceId(6202).draftText, "6")
        @Assert(domain.editTextFromHuman(6202, "0", 1, 1).applied, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        var errors: Int64 = 0
        for (node in window.acceptedSceneNodes()) {
            if (node.fieldId == "copies" && node.displayValueRole == "validation") {
                @Assert(node.value, domain.formSnapshot().fieldForResourceId(6202).validationError)
                errors += 1
            }
            if (node.actionName == "APPLY_DRAFT") { @Assert(node.isEnabled, false) }
        }
        @Assert(errors, 2)
        @Assert(controller.region.acceptedNodeIdForKey("job"), jobId)
        @Assert(domain.editTextFromHuman(6202, "6", 1, 1).applied, true)
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        for (node in window.acceptedSceneNodes()) {
            @Assert(node.fieldId != "copies" || node.displayValueRole != "validation", true)
            if (node.actionName == "APPLY_DRAFT") { @Assert(node.isEnabled, true) }
        }
        @Assert(window.ownedTextSessionBoundNodeId(), jobId)
    } finally {
        host.close()
    }
}

@Test
func printWindowPrimaryFieldUsesOneWriterForWholePreviewAndRange(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Print primary writer check", 1000u32, 680u32,
            rangeTextEditDeltaDelivery: true))
    let window = host.window()
    controller.attachWindow(window)
    @Assert(host.start(), true)
    try {
        for (_ in 0..64) {
            if (window.windowProgress().acceptedSceneVersion > 0) { break }
            let _ = host.pumpOneTurn()
        }
        let node = printAcceptedNode(window, 101)
        let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
        let provider = MixedPresetProvider(form, domain.cards, domain)
        let bridge = CjguiGeneratedFieldRangeSession(provider, "jobName", ownerTarget: PrintPresetDomain.ownerId)
        let session = window.bindRangeTextSession(101, node.semanticId, bridge, bridge, 6201,
            CJGUI_COMPOSABLE_UI_TEXT_INPUT)
        let whole = controller.applyUiEvent(CjguiComposableUiEvent(node, CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED,
            "资料N", 3, 3, window.windowProgress().acceptedSceneVersion))
        let range = session.replaceRange16(2, 2, "N")
        getStdOut().writeln("MIXED_PRIMARY_WRITER whole=${whole.didApply} delta=${range.accepted} " +
            "reason=[${range.reason}] calibration=${session.awaitingCalibration()} " +
            "body=[${domain.formSnapshot().fieldForResourceId(6201).draftText}]")
        getStdOut().flush()
        @Assert(whole.didApply, false)
        @Assert(range.accepted, true)
        @Assert(session.awaitingCalibration(), false)
        @Assert(domain.formSnapshot().fieldForResourceId(6201).draftText, "资料N")
        @Assert(domain.formSnapshot().draftVersion, 1)
    } finally {
        host.close()
    }
}

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

// --- Offline help-layer wiring (no window pump: Sol owns the foreground in
// this package; the wiring under test is exactly the no-window/no-focus path
// located in the 2026-10-26 event chain) -------------------------------

private func helpEvent(nodeId: Int64, semanticId: String, actionName: String, kind!: Int64 =
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE): CjguiComposableUiEvent {
    let button = cjguiComposableButton(nodeId, semanticId, actionName, actionName,
        PrintPresetDomain.ownerId, CjguiComposableUiStyle())
    return CjguiComposableUiEvent(
        CjguiComposableUiLayoutNode(button, CjguiComposableUiRect(0, 0, 96, 34),
            CjguiComposableUiRect(0, 0, 96, 34)), kind, "", 0, 0, 1)
}

private func sceneNodeBounds(scene: CjguiComposableUiScene, nodeId: Int64): ?CjguiComposableUiRect {
    for (node in scene.nodes()) {
        if (node.nodeId == nodeId) {
            return Some(node.bounds)
        }
    }
    return None
}

/// Canonical layout with the identity registry the collection's scoped rows
/// require (same shape as the rule-set layout probe).
private func probeScene(controller: MixedFormController, width: Int64, height: Int64,
    version: Int64): CjguiComposableUiScene {
    let root = controller.buildUi()
    let rect = CjguiComposableUiRect(0, 0, width, height)
    let registry = CjguiComposableUiIdentityRegistry()
    if (!registry.beginCandidate()) {
        return CjguiComposableUiLayoutEngine.layout(root, rect, version)
    }
    let _ = registry.resolveCandidate(root)
    let _ = registry.replaceCandidateRoot(root)
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, rect, version,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry)).scene
    let _ = registry.prepareCandidate()
    return scene
}

/// The RED scenario from the located event chain: the developer fold is NOT
/// mounted (default state) and there is NO text focus, yet opening the help
/// must present the dialog. The old wiring kept the initial anchor manual(101)
/// - a node that only mounts inside the developer fold - and the framework
/// rejected the whole candidate scene (identity_reference_invalid), so the
/// help never presented. The anchor must instead fall back to the help
/// trigger itself (node 73), which is mounted on every first screen.
@Test
func helpOpensWithoutFocusThroughPersistentTriggerFallback(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    // Default state IS the scenario: developerInfoVisible=false, no attached
    // window, no text session anywhere.
    let dispatched = controller.applyUiEvent(helpEvent(73, "preset-help", "OPEN_HELP"))
    @Assert(dispatched.didApply, true)
    @Assert(controller.isHelpLayerVisible(), true)
    @Assert(controller.lastHelpReturnSelection(), "manual-73")
    // The dialog is part of the built scene: its 返回编辑 button (node 84) and
    // the layer (81) exist, so a candidate carrying this tree can present.
    let scene = probeScene(controller, 1000, 680, 1)
    @Assert(sceneNodeBounds(scene, 81).isSome(), true)
    @Assert(sceneNodeBounds(scene, 84).isSome(), true)
    @Assert(scene.layoutError(), "")
}

/// Present -> close -> reopen with the draft preserved: the dialog cycle must
/// not touch the owner's draft, and each phase builds a scene that agrees with
/// the controller's own flag.
@Test
func helpCyclePresentCloseReopenKeepsDraft(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    @Assert(domain.editTextFromHuman(6201, "帮助前正文", 5, 5).applied, true)
    let draftBefore = domain.formSnapshot().draftVersion
    // Present.
    @Assert(controller.applyUiEvent(helpEvent(73, "preset-help", "OPEN_HELP")).didApply, true)
    @Assert(controller.isHelpLayerVisible(), true)
    let openScene = probeScene(controller, 1000, 680, 1)
    @Assert(sceneNodeBounds(openScene, 84).isSome(), true)
    // Close through the dialog's own button.
    @Assert(controller.applyUiEvent(helpEvent(84, "preset-help-close", "CLOSE_HELP")).didApply, true)
    @Assert(controller.isHelpLayerVisible(), false)
    let closedScene = probeScene(controller, 1000, 680, 1)
    @Assert(sceneNodeBounds(closedScene, 84).isNone(), true)
    // Reopen: the SAME no-focus fallback applies again - the previous anchor
    // is never reused.
    @Assert(controller.applyUiEvent(helpEvent(73, "preset-help", "OPEN_HELP")).didApply, true)
    @Assert(controller.isHelpLayerVisible(), true)
    @Assert(controller.lastHelpReturnSelection(), "manual-73")
    // The draft survived the whole cycle untouched.
    @Assert(domain.formSnapshot().fieldForResourceId(6201).draftText, "帮助前正文")
    @Assert(domain.formSnapshot().draftVersion, draftBefore)
}

/// A rejected candidate leaves no accepted dialog: rollback restores the
/// pre-intent visibility so the controller never believes the dialog is open
/// while the screen shows none - and the user can simply press again. The
/// rejection itself stays the framework's own fact.
@Test
func helpRollbackRestoresStateMatchingRejectedScene(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    @Assert(controller.applyUiEvent(helpEvent(73, "preset-help", "OPEN_HELP")).didApply, true)
    @Assert(controller.isHelpLayerVisible(), true)
    controller.rollbackSceneRefresh("identity_reference_invalid")
    @Assert(controller.isHelpLayerVisible(), false)
    // Retry after the rejection works through the same path.
    @Assert(controller.applyUiEvent(helpEvent(73, "preset-help", "OPEN_HELP")).didApply, true)
    @Assert(controller.isHelpLayerVisible(), true)
    controller.commitSceneRefresh()
    // An accepted open survives an unrelated later rollback: only the IN-FLIGHT
    // change is undone, never the settled one.
    controller.rollbackSceneRefresh("unrelated")
    @Assert(controller.isHelpLayerVisible(), true)
    // The close direction is symmetric.
    @Assert(controller.applyUiEvent(helpEvent(84, "preset-help-close", "CLOSE_HELP")).didApply, true)
    controller.rollbackSceneRefresh("identity_reference_invalid")
    @Assert(controller.isHelpLayerVisible(), true)
    controller.commitSceneRefresh()
    @Assert(controller.isHelpLayerVisible(), true)
}

/// The --commands first frame must not be rejected: the collection workspace's
/// scoped commands are only declared while their action-bar controls are
/// mounted (the "视图 / 列" fold). Collapsed fold - no scoped view commands;
/// expanded fold - they return with their live targets.
@Test
func commandsModeDeclarationsFollowMountedViewTools(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain, commandSurfaces: true)
    func workspaceViewCommandCount(): Int64 {
        var count: Int64 = 0
        for (command in controller.candidateSceneCommands()) {
            if (command.id.contains("preset-card-workspace")) { count += 1 }
        }
        return count
    }
    @Assert(controller.isHelpLayerVisible(), false)
    @Assert(workspaceViewCommandCount(), 0)
    @Assert(controller.applyUiEvent(helpEvent(1807, "preset-view-tools-toggle", "TOGGLE_VIEW_TOOLS")).didApply, true)
    @Assert(workspaceViewCommandCount(), 3)
}

/// The narrow business layout is an EXPLICIT vertical stack: the detail first,
/// the collection BELOW it at the full usable width. The old Wrap variant kept
/// detail+list on one line at 620 logical points and squeezed the list into a
/// right-side strip.
@Test
func narrowBusinessStacksDetailAboveFullWidthList(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    controller.setBusinessWidthOverrideForVerification(width: Some(620))
    let narrow = probeScene(controller, 620, 720, 1)
    @Assert(narrow.layoutError(), "")
    let detail = sceneNodeBounds(narrow, 900).getOrThrow()
    let list = sceneNodeBounds(narrow, 3004).getOrThrow()
    @Assert(detail.y < list.y, true)
    @Assert(detail.width > 500, true)
    @Assert(list.width > 500, true)
    // Wide control: the public split keeps the collection as a bounded column
    // BESIDE the detail, not below it.
    controller.setBusinessWidthOverrideForVerification(width: Some(980))
    let wide = probeScene(controller, 980, 680, 1)
    @Assert(wide.layoutError(), "")
    let wideDetail = sceneNodeBounds(wide, 900).getOrThrow()
    let wideList = sceneNodeBounds(wide, 3004).getOrThrow()
    @Assert(wideList.x > wideDetail.x + 200, true)
    @Assert(wideList.width < 400, true)
    @Assert(wideDetail.width > 500, true)
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
        getStdOut().writeln("HR step=submit"); getStdOut().flush()
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

/// The help layer returns through the framework's own completion: the return
/// target is the OPEN-TIME editing-focus reference (the generated B editor),
/// never the "last typed numeric id" (the manual A editor). An external
/// whole-value change made while the help is open becomes the body the first
/// write continues from, and that first write lands exactly once. Esc closes
/// through the same path.
@Test
func helpReturnRestoresOpenTimeFocusNotLastTypedNode(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    controller.collaborationOpened(true)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Print help return check", 1000u32, 680u32,
            rangeTextEditDeltaDelivery: true))
    let window = host.window()
    controller.attachWindow(window)
    @Assert(host.start(), true)
    try {
        for (_ in 0..64) {
            if (window.windowProgress().acceptedSceneVersion > 0) { break }
            let _ = host.pumpOneTurn()
        }
        // A second TEXT editor comes from the generated side, so the window
        // really has two session-eligible fields (manual A, generated B).
        let candidate = "GENERATED_UI_STRUCTURE 1\nNODE 0 form vertical\n" +
            "NODE 1 job textInput field=jobName\nPROPERTY 1 job fixedHeight 40\nEND"
        @Assert(controller.region.submitStructure(candidate, 0).candidateAccepted, true)
        let _ = window.refresh()
        for (_ in 0..64) {
            if (controller.region.acceptedStructureVersion() == 1) { break }
            let _ = host.pumpOneTurn()
        }
        getStdOut().writeln("HR step=accepted-struct"); getStdOut().flush()
        let bId = controller.region.acceptedNodeIdForKey("job")
        @Assert(bId > 0, true)
        // 1. Type into A (the manual jobName editor). The removed parallel
        //    authority would have remembered THIS node as the return target.
        // 1. Focus A and type into it - the real human order. The removed
        //    parallel authority would have remembered A as the return target.
        let aNode = printAcceptedNode(window, 101)
        @Assert(window.focusAcceptedNodeById(101), true)
        @Assert(window.ownedTextSessionBoundNodeId(), 101)
        let _ = aNode
        @Assert(domain.editTextFromHuman(6201, "帮助前正文", 5, 5).applied, true)
        // 2. Then ONLY focus B (the generated editor): no typing into B.
        getStdOut().writeln("HR step=typed-A"); getStdOut().flush()
        @Assert(window.focusAcceptedNodeById(bId), true)
        @Assert(window.ownedTextSessionBoundNodeId(), bId)
        getStdOut().writeln("HR step=focusB-done"); getStdOut().flush()
        // 3. Open the help layer; the captured anchor is B.
        getStdOut().writeln("HR step=typed-A"); getStdOut().flush()
        let helpButton = printAcceptedNode(window, 73)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(helpButton, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            "", 0, 0, window.windowProgress().acceptedSceneVersion)).didApply, true)
        let _ = window.refresh()
        for (_ in 0..64) {
            if (printAcceptedNode(window, 84).nodeId == 84) { break }
            let _ = host.pumpOneTurn()
        }
        getStdOut().writeln("HR step=help-open-pumped"); getStdOut().flush()
        @Assert(printAcceptedNode(window, 84).nodeId, 84)
        // 4. An external whole-value change on the shared field while the help
        //    is open (the same owner both editors bind).
        getStdOut().writeln("HR step=layer-present"); getStdOut().flush()
        @Assert(domain.editTextFromHuman(6201, "外改正文", 4, 4).applied, true)
        // 5. Close through the button; the framework completes the layer
        //    return with the anchor the dialog declared.
        let closeButton = printAcceptedNode(window, 84)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(closeButton, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            "", 0, 0, window.windowProgress().acceptedSceneVersion)).didApply, true)
        let _ = window.refresh()
        for (_ in 0..64) {
            if (printAcceptedNode(window, 84).nodeId != 84) { break }
            let _ = host.pumpOneTurn()
        }
        getStdOut().writeln("HR step=closed-pumped"); getStdOut().flush()
        @Assert(printAcceptedNode(window, 84).nodeId != 84, true)
        // 6. The return restored B - the OPEN-TIME focus - not the last-typed A.
        @Assert(window.ownedTextSessionBoundNodeId(), bId)
        // 7. The first write after the return continues from the external body
        //    and lands exactly once.
        let before = domain.formSnapshot().draftVersion
        let bNode = printAcceptedNode(window, bId)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(bNode, CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED,
            "外改正文Q", 5, 5, window.windowProgress().acceptedSceneVersion)).didApply, true)
        @Assert(domain.formSnapshot().fieldForResourceId(6201).draftText, "外改正文Q")
        @Assert(domain.formSnapshot().draftVersion, before + 1)
        // 8. Esc shares the same completion path: reopen on B, close with the
        //    dismiss event, and the anchor still restores B.
        @Assert(window.focusAcceptedNodeById(bId), true)
        let helpAgain = printAcceptedNode(window, 73)
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(helpAgain, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
            "", 0, 0, window.windowProgress().acceptedSceneVersion)).didApply, true)
        let _ = window.refresh()
        for (_ in 0..64) {
            if (printAcceptedNode(window, 84).nodeId == 84) { break }
            let _ = host.pumpOneTurn()
        }
        @Assert(controller.applyUiEvent(CjguiComposableUiEvent(printAcceptedNode(window, 84), 36,
            "escape", 0, 0, window.windowProgress().acceptedSceneVersion)).didApply, true)
        let _ = window.refresh()
        for (_ in 0..64) {
            if (printAcceptedNode(window, 84).nodeId != 84) { break }
            let _ = host.pumpOneTurn()
        }
        @Assert(printAcceptedNode(window, 84).nodeId != 84, true)
        @Assert(window.ownedTextSessionBoundNodeId(), bId)
    } finally {
        host.close()
    }
}

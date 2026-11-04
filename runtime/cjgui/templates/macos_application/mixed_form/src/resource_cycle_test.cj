package cjgui_mixed_form_starter

import cjgui.*
import std.env.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private let MIXED_RESOURCE_CYCLE_TEST_TIMEOUT_SECONDS: Int64 = 5

/// Wait for the same accepted structure, actual generated nodes, and a settled
/// frame. A refresh call only requests work; the owner fixture and app turn
/// pump deliver its asynchronous acceptance/completion.
private func mixedResourceCycleTestAwaitAccepted(application: CjguiMacosApplication, controller: MixedFormController,
    window: CjguiComposableUiWindow, targetStructureVersion: Int64, sceneBefore: Int64, frameBefore: Int64): Bool {
    let deadline = MonoTime.now() + MIXED_RESOURCE_CYCLE_TEST_TIMEOUT_SECONDS * Duration.second
    while (MonoTime.now() < deadline) {
        let (generatedCount, effectGroupCount) = mixedResourceCycleCountAcceptedNodesByKey(window, controller.region)
        let progress = window.windowProgress()
        let diagnostic = window.diagnosticSnapshot(maximumNodes: 128)
        if (controller.region.acceptedStructureVersion() == targetStructureVersion && controller.region.sceneState() ==
            "scene_accepted" && progress.acceptedSceneVersion > sceneBefore && generatedCount == 12 &&
            effectGroupCount == 1 && diagnostic.submittedFrameIndex > frameBefore && diagnostic.submittedFrameIndex == diagnostic
            .completedFrameIndex) {
            println(
                "MIXED_RESOURCE_CYCLE_TEST_ACCEPTED structure=${targetStructureVersion} " +
                    "scene=${progress.acceptedSceneVersion} frame=${diagnostic.submittedFrameIndex} " +
                    "generated=${generatedCount} effects=${effectGroupCount}")
            return true
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) {
            break
        }
    }
    let (generatedCount, effectGroupCount) = mixedResourceCycleCountAcceptedNodesByKey(window, controller.region)
    let progress = window.windowProgress()
    let diagnostic = window.diagnosticSnapshot(maximumNodes: 128)
    println(
        "MIXED_RESOURCE_CYCLE_TEST_TIMEOUT target_structure=${targetStructureVersion} " +
            "accepted_structure=${controller.region.acceptedStructureVersion()} " +
            "region_scene=[${controller.region.sceneState()}] accepted_scene=${progress.acceptedSceneVersion} " +
            "frame=${diagnostic.submittedFrameIndex}/${diagnostic.completedFrameIndex} " +
            "generated=${generatedCount} effects=${effectGroupCount} open=${window.isOpen()}")
    return false
}

@When[os == "macOS"]
@Test
func mixedResourceCycleRunsTenAcceptedWindowCyclesAndDrains(): Unit {
    cjguiMacosOwnerTest(
        {
            =>
                let domain = PrintPresetDomain()
                let anchorController = MixedFormController(domain, commandSurfaces: true)
                let application = CjguiMacosApplication(maximumWindowCount: 2)
                try {
                    let opened = application.openWindow(anchorController,
                        configuration: CjguiMacosApplicationWindowConfiguration("打印预设 · 公共组合", 1000u32, 680u32,
                            rangeTextEditDeltaDelivery: true))
                    @Assert(opened.didOpen, true)
                    let anchorId = match (opened.identifier) {
                        case Some(value) => value
                        case None => throw Exception("resource_cycle_anchor_identity_missing")
                    }
                    anchorController.attachWindow(application.window(anchorId).getOrThrow())
                    let (ok, report) = mixedRunResourceCycleWorkload(application, domain, anchorId, anchorController)
                    getStdOut().writeln(report)
                    getStdOut().flush()
                    @Assert(report.contains("CJGUI_RESOURCE_CYCLE_RESULT status=ok"), true)
                    let (closed, reason) = mixedResourceCycleDiscardUiAndClose(application, anchorController, anchorId)
                    @Assert(closed, true)
                    @Assert(reason, "closed")
                    @Assert(ok, true)
                } finally {
                    application.close()
                    anchorController.closeResources()
                }
        }
    )
}

/// Generated semantic ids intentionally hide business keys. Count the exact
/// keys accepted by the mixed region and match them back to the accepted
/// window nodes through the region's stable key-to-node-id reader.
@When[os == "macOS"]
@Test
func mixedResourceCycleGeneratedKeysMatchAcceptedNodeIds(): Unit {
    cjguiMacosOwnerTest(
        {
            =>
                let domain = PrintPresetDomain()
                let controller = MixedFormController(domain, commandSurfaces: true)
                let application = CjguiMacosApplication(maximumWindowCount: 2)
                try {
                    let opened = application.openWindow(controller,
                        configuration: CjguiMacosApplicationWindowConfiguration("打印预设 · 公共组合", 1000u32, 680u32,
                            rangeTextEditDeltaDelivery: true))
                    @Assert(opened.didOpen, true)
                    let identifier = opened.identifier.getOrThrow()
                    let window = application.window(identifier).getOrThrow()
                    controller.attachWindow(window)

                    let beforeStructureVersion = controller.region.acceptedStructureVersion()
                    let beforeSceneVersion = window.windowProgress().acceptedSceneVersion
                    let beforeFrame = window.diagnosticSnapshot(maximumNodes: 128).submittedFrameIndex
                    let submitted = controller
                        .region
                        .submitStructure(mixedResourceCycleStructure(0, false), beforeStructureVersion)
                    @Assert(submitted.candidateAccepted, true)
                    let targetStructureVersion = beforeStructureVersion + 1
                    let _ = window.refresh()
                    let accepted = mixedResourceCycleTestAwaitAccepted(application, controller, window,
                        targetStructureVersion, beforeSceneVersion, beforeFrame)
                    @Assert(accepted, true)
                    @Assert(controller.region.acceptedStructureVersion(), targetStructureVersion)
                    @Assert(controller.region.sceneState(), "scene_accepted")

                    let (generatedCount, effectGroupCount) = mixedResourceCycleCountAcceptedNodesByKey(window,
                        controller.region)
                    @Assert(generatedCount, 12)
                    @Assert(effectGroupCount, 1)

                    // The generated key is not the published semantic id. Resolve the
                    // actual built-in scrollArea node through the accepted key map.
                    let scrollNodeId = controller.region.acceptedNodeIdForKey("cycle-scroll")
                    @Assert(scrollNodeId > 0, true)
                    var scrollNodeFound = false
                    var scrollSemantic = ""
                    var scrollHasViewport = false
                    var legacyKeySemanticFound = false
                    for (node in window.acceptedSceneNodes()) {
                        if (node.nodeId == scrollNodeId) {
                            scrollNodeFound = true
                            scrollSemantic = node.semanticId
                            scrollHasViewport = node.scrollViewport.isSome()
                        }
                        if (node.semanticId == "cycle-scroll") {
                            legacyKeySemanticFound = true
                        }
                    }
                    @Assert(scrollNodeFound, true)
                    @Assert(scrollSemantic.startsWith("component-"), true)
                    @Assert(scrollHasViewport, true)
                    @Assert(legacyKeySemanticFound, false)

                    var outerScrollFound = false
                    var outerScrollHasViewport = false
                    for (node in window.acceptedSceneNodes()) {
                        if (node.semanticId == "preset-scroll") {
                            outerScrollFound = true
                            outerScrollHasViewport = node.scrollViewport.isSome()
                        }
                    }
                    @Assert(outerScrollFound, true)
                    @Assert(outerScrollHasViewport, true)

                    let effectNodeId = controller.region.acceptedNodeIdForKey("cycle-card")
                    @Assert(effectNodeId > 0, true)
                    var effectNodeFound = false
                    for (node in window.acceptedSceneNodes()) {
                        if (node.nodeId == effectNodeId) {
                            effectNodeFound = true
                            @Assert(node.style.effectGroup.isSome(), true)
                            @Assert(node.semanticId.startsWith("component-"), true)
                        }
                    }
                    @Assert(effectNodeFound, true)
                } finally {
                    application.close()
                    controller.closeResources()
                }
        }
    )
}

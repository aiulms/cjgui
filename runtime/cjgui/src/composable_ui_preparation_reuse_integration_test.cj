package cjgui

private class PreparationReuseViewportController <: CjguiComposableUiController {
    let viewport: CjguiComposableUiScrollViewport
    var builds: Int64 = 0
    var revision: Int64 = 1
    var stringMutation: Int64 = 0

    init(viewport: CjguiComposableUiScrollViewport) { this.viewport = viewport }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        builds += 1
        let root = cjguiComposableVertical(48099, "reuse-root", CjguiComposableUiStyle())
        let scroll = cjguiComposableScrollArea(48100, "reuse-scroll", viewport,
            CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: 96))
        let content = cjguiComposableVertical(48101, "reuse-content", CjguiComposableUiStyle(gap: 2))
        for (index in 0..12) {
            if (index == 4) {
                let changed = stringMutation
                let semanticId = if (changed == 3) { "reuse-row-4-semantic" } else { "reuse-row-4" }
                let label = if (changed == 1) { "changed label" } else { "stable label" }
                let value = if (changed == 2) { "changed value" } else { "stable value" }
                let fieldId = if (changed == 4) { "reuse-field-next" } else { "reuse-field" }
                let semanticKey = if (changed == 5) { "reuse-row-key-next" } else { "reuse-row-key" }
                let parentKey = if (changed == 6) { "reuse-parent-next" } else { "reuse-parent" }
                let semanticLabel = if (changed == 7) { "Changed accessible row" } else { "Stable accessible row" }
                let runs = if (changed == 8) {
                    [CjguiComposableUiTextStyleRun(0, 1, 13.0, 700, "system", 0.8, 0.1, 0.2, 1.0)]
                } else {
                    [CjguiComposableUiTextStyleRun(0, 1, 13.0, 400, "system", 0.1, 0.2, 0.3, 1.0)]
                }
                let target = CjguiComposableUiNode(48114, semanticId, CJGUI_COMPOSABLE_UI_TEXT,
                    label, value, "", -1, CjguiComposableUiStyle(fixedHeight: 24, fontSize: 13.0),
                    textStyleRuns: runs, fieldId: fieldId, semanticLabel: semanticLabel,
                    semanticKey: semanticKey, semanticParentKey: parentKey)
                content.add(target)
            } else {
                content.add(cjguiComposableText(48110 + index, "reuse-row-${index}",
                    "stable row ${index}", CjguiComposableUiStyle(fixedHeight: 24, fontSize: 13.0)))
            }
        }
        scroll.add(content)
        root.add(scroll)
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func acceptReuseMutation(window: CjguiComposableUiWindow,
    controller: PreparationReuseViewportController, budget: CjguiOwnerTurnBudget,
    mutation: Int64, acceptedSemanticId: String, expectedText: String): Unit {
    let previousSceneVersion = window.displayedSceneVersion()
    controller.stringMutation = mutation
    controller.revision += 1
    window.requestRefresh()
    var accepted = false
    var turn: Int64 = 0
    while (turn < 48 && !accepted) {
        @Assert(budget.begin(), true)
        accepted = window.refreshIfNeeded()
        let _ = window.pump(0u32)
        budget.end()
        turn += 1
    }
    @Assert(accepted, true)
    @Assert(window.displayedSceneVersion() > previousSceneVersion, true)
    let acceptedText = window.acceptedNodeText(acceptedSemanticId)
    if (acceptedText.isNone()) {
        println("PREPARATION_REUSE_ACCEPTED_SCENE_MISSING semantic=${acceptedSemanticId} " +
            "dump=${window.acceptedSceneDump()}")
    }
    @Assert(acceptedText.isSome(), true)
    @Assert(acceptedText.getOrThrow(), expectedText)
    if (mutation == 3) {
        @Assert(window.acceptedNodeText("reuse-row-4").isNone(), true)
    }
    if (mutation == 4) {
        @Assert(window.acceptedSceneDump().contains("reuse-field-next"), true)
    }
    let nodes = window.acceptedSceneNodes()
    var targetFound = false
    for (node in nodes) {
        if (node.semanticId == acceptedSemanticId) {
            targetFound = true
            if (mutation == 5) { @Assert(node.semanticKey, "reuse-row-key-next") }
            if (mutation == 6) { @Assert(node.semanticParentKey, "reuse-parent-next") }
            if (mutation == 7) { @Assert(node.semanticLabel, "Changed accessible row") }
            if (mutation == 8) { @Assert(node.textStyleRuns.size, 1); @Assert(node.textStyleRuns[0].fontWeight, 700) }
        }
    }
    @Assert(targetFound, true)
    println("PREPARATION_REUSE_STRING_CASE mutation=${mutation} version=${controller.revision} " +
        "semantic=${acceptedSemanticId} text=${expectedText} turns=${turn}")
}

@Test
func cangjieWindowViewportRefreshRunsThePreparedReuseBridge(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    let controller = PreparationReuseViewportController(viewport)
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    try {
        window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(viewport.acceptedOffset(), 0)
        @Assert(controller.builds, 1)
        let contentExtent = viewport.contentExtent()
        let viewportExtent = viewport.viewportExtent()
        let maximumOffset = viewport.maximumOffset()
        @Assert(contentExtent > viewportExtent, true)
        @Assert(maximumOffset >= 28, true)
        println("PREPARATION_REUSE_VIEWPORT_FIXTURE content=${contentExtent} " +
            "viewport=${viewportExtent} maximum=${maximumOffset}")
        let before = window.acceptedNodeBounds("reuse-row-4").getOrThrow()
        let step = 28
        @Assert(viewport.requestOffset(step), true)
        window.requestRefresh()

        var accepted = false
        var turn: Int64 = 0
        while (turn < 48 && !accepted) {
            @Assert(budget.begin(), true)
            accepted = window.refreshIfNeeded()
            let _ = window.pump(0u32)
            budget.end()
            turn += 1
        }
        @Assert(accepted, true)
        @Assert(viewport.acceptedOffset(), step)
        let after = window.acceptedNodeBounds("reuse-row-4").getOrThrow()
        @Assert(after.y, before.y - step)
        @Assert(window.acceptedNodeValue("reuse-row-4") ?? "", "stable value")
        @Assert(controller.builds, 2)
        println("PREPARATION_REUSE_CJ_WINDOW accepted=${viewport.acceptedOffset()} " +
            "rowY=${before.y}:${after.y} turns=${turn}")

        // Retain a real prepared candidate at Ready, then cancel it through
        // the ordinary refresh invalidation. A's accepted scene must remain
        // byte-for-byte the same while the native candidate is discarded.
        let acceptedBeforeCancel = window.acceptedSceneDump()
        let sceneBeforeCancel = window.displayedSceneVersion()
        budget.testUseClock({ =>
            let actual = Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })
            return if (window.testPreparedCandidateReady()) { actual + 10000000 } else { actual }
        })
        controller.stringMutation = 1
        controller.revision += 1
        window.requestRefresh()
        var cancelReady = false
        var cancelTurns: Int64 = 0
        while (!cancelReady && cancelTurns < 48) {
            @Assert(budget.begin(), true)
            @Assert(window.refreshIfNeeded(), false)
            let _ = window.pump(0u32)
            budget.end()
            cancelReady = window.testPreparedCandidateReady()
            cancelTurns += 1
        }
        @Assert(cancelReady, true)
        @Assert(window.displayedSceneVersion(), sceneBeforeCancel)
        @Assert(window.acceptedSceneDump(), acceptedBeforeCancel)
        controller.stringMutation = 0
        controller.revision += 1
        window.requestRefresh()
        @Assert(window.displayedSceneVersion(), sceneBeforeCancel)
        @Assert(window.acceptedSceneDump(), acceptedBeforeCancel)
        budget.testUseClock({ => Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() }) })
        println("PREPARATION_REUSE_CANCEL_READY turns=${cancelTurns} accepted_scene_preserved=true")

        // Exercise each of the eight packet strings through the normal window
        // candidate bridge. Each accepted scene is read back from this window.
        acceptReuseMutation(window, controller, budget, 1, "reuse-row-4", "changed label")
        acceptReuseMutation(window, controller, budget, 2, "reuse-row-4", "stable label")
        @Assert(window.acceptedNodeValue("reuse-row-4").getOrThrow(), "changed value")
        acceptReuseMutation(window, controller, budget, 3, "reuse-row-4-semantic", "stable label")
        acceptReuseMutation(window, controller, budget, 4, "reuse-row-4", "stable label")
        acceptReuseMutation(window, controller, budget, 5, "reuse-row-4", "stable label")
        acceptReuseMutation(window, controller, budget, 6, "reuse-row-4", "stable label")
        acceptReuseMutation(window, controller, budget, 7, "reuse-row-4", "stable label")
        acceptReuseMutation(window, controller, budget, 8, "reuse-row-4", "stable label")
    } finally { budget.end(); window.close() }
}

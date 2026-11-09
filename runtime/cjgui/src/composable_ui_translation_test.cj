package cjgui

import std.collection.*
import std.time.*

@Test
func f11NestedTranslationKeepsIntegerLayoutAndClipOwners(): Unit {
    let root = cjguiComposableVertical(9900, "f11-root",
        CjguiComposableUiStyle(gap: 0, padding: 0, translateX: 0.25, translateY: 0.5,
            clipsContent: true, fixedWidth: 100, fixedHeight: 40))
    root.add(cjguiComposableButton(9901, "f11-child", "Go", "go", -1,
        CjguiComposableUiStyle(fixedWidth: 20, fixedHeight: 20, offsetX: 2,
            translateX: -0.75, translateY: 0.25)))
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 100, 40), 1)
    @Assert(scene.isValid(), true)
    let child = scene.nodeForId(9901)
    @Assert(child.bounds.x, 2)
    let visual = scene.visualBoundsForId(9901)
    if (let Some(bounds) <- visual) {
        @Assert(bounds.x, 1.5)
        @Assert(bounds.y, 0.75)
        @Assert(bounds.width, 20.0)
    } else {
        @Assert(false)
    }
    let nodes = scene.nodes()
    let childGeometry = scene.visualGeometryAt(1)
    @Assert(childGeometry.translateX, -0.5)
    @Assert(childGeometry.translateY, 0.75)
    let clips = nodes[1].clipConstraints()
    @Assert(clips.size, 2)
    // Window clip stays at zero; the root-created clip follows only the root.
    @Assert(childGeometry.clipTranslateX(0), 0.0)
    @Assert(childGeometry.clipTranslateX(1), 0.25)
    @Assert(childGeometry.clipTranslateY(1), 0.5)
    @Assert(childGeometry.containsClips(clips, 2.0, 1.0), true)
    @Assert(scene.hitTestVisual(1.49, 1.0).nodeId != 9901, true)
    @Assert(scene.hitTestVisual(1.5, 1.0).nodeId, 9901)
    @Assert(scene.hitTestVisual(21.5, 1.0).nodeId != 9901, true)
}

@Test
func f11RejectsExcessiveTranslationBeforeAcceptance(): Unit {
    let root = cjguiComposableVertical(9910, "f11-invalid",
        CjguiComposableUiStyle(translateX: 1025.0))
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 100, 40), 2)
    @Assert(scene.isValid(), false)
    @Assert(scene.layoutError(), "translation_value_invalid")
}

@Test
func f11TranslationNamedPaintAndGeneratedAdmission(): Unit {
    let named = CjguiComposableUiNamedStyle("f11_move",
        CjguiComposableUiStyle(translateX: 0.25, translateY: 0.5, offsetX: 2))
    let bound = named.boundStyle(translateX: Some(-0.75))
    @Assert(bound.style.translateX, -0.75)
    @Assert(bound.style.translateY, 0.5)
    @Assert(bound.style.offsetX, 2)
    let painted = cjguiComposableUiStyleWithPaint(bound.style,
        CjguiComposableUiColor(0.3, 0.4, 0.5, 1.0), bound.style.border, bound.style.textColor,
        bound.style.borderWidth, bound.style.shadow, bound.style.gradient, bound.style.effectGroup)
    @Assert(painted.translateX, -0.75)
    @Assert(painted.translateY, 0.5)
    @Assert(painted.offsetX, 2)
    @Assert(cjguiComposableUiParseTranslationScalar("-0.75"), Some(-0.75))
    @Assert(cjguiComposableUiParseTranslationScalar("0.25"), Some(0.25))
    @Assert(cjguiComposableUiParseTranslationScalar("NaN").isNone(), true)
    @Assert(cjguiComposableUiParseTranslationScalar("1024.001").isNone(), true)
    @Assert(cjguiComposableUiParseTranslationScalar("0.0001").isNone(), true)

    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 4))
    let leafProperties = ArrayList<CjguiGeneratedUiPropertySpec>([
        CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 20)
    ])
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) { leafProperties.add(property) }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", leafProperties, false))
    @Assert(catalog.namedStyles().register(named), true)
    let values = HashMap<String, String>()
    values.add("style", "f11_move")
    values.add("text", "translated")
    values.add("translateX", "-0.75")
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("label", "label", properties: values))
    let candidate = CjguiGeneratedUiNodeSpec("root", "vertical", children: children)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let accepted = holder.submit(candidate, provider)
    @Assert(accepted.candidateAccepted, true)
    let _ = holder.beginCandidateRefresh()
    let built = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    @Assert(holder.commitCandidateRefresh(), true)
    @Assert(built.children()[0].style.translateX, -0.75)
    @Assert(built.children()[0].style.translateY, 0.5)
    @Assert(built.children()[0].style.offsetX, 2)
    let priorVersion = holder.structureVersion()
    let invalidValues = HashMap<String, String>()
    invalidValues.add("style", "f11_move")
    invalidValues.add("text", "rejected")
    invalidValues.add("translateX", "NaN")
    let invalidChildren = ArrayList<CjguiGeneratedUiNodeSpec>()
    invalidChildren.add(CjguiGeneratedUiNodeSpec("label", "label", properties: invalidValues))
    let invalid = holder.submit(CjguiGeneratedUiNodeSpec("root", "vertical", children: invalidChildren), provider)
    @Assert(invalid.candidateAccepted, false)
    @Assert(invalid.reason, "translation_value_invalid")
    @Assert(holder.structureVersion(), priorVersion)
}

@Test
func translatedVerticalSplitPointerUsesAcceptedTrackLocalPointOnce(): Unit {
    // 纵向分隔条的 Y 等价映射：与横向同一“接受轨道局部点 + 一次量化”规则。
    let visual = CjguiComposableUiVisualGeometry(0.0, 100.25,
        ArrayList<Float64>(), ArrayList<Float64>())
    let handle = CjguiComposableUiRect(0, 200, 40, 8)
    let acceptedFirst: Int64 = 200
    let same = visual.windowToSplitTrackPointY(handle, acceptedFirst, 303.25, 3.0)
    @Assert(CjguiComposableUiSplitGeometry.firstSizeForPointer(same, 0, 400, 8, 40, 40), 200)
    let moved = visual.windowToSplitTrackPointY(handle, acceptedFirst, 320.25, 3.0)
    @Assert(CjguiComposableUiSplitGeometry.firstSizeForPointer(moved, 0, 400, 8, 40, 40), 217)
    let restored = visual.windowToSplitTrackPointY(handle, acceptedFirst, 303.25, 3.0)
    @Assert(restored, same)
}

@Test
func translatedSplitPointerUsesAcceptedTrackLocalPointOnce(): Unit {
    let visual = CjguiComposableUiVisualGeometry(100.25, 0.0,
        ArrayList<Float64>(), ArrayList<Float64>())
    let handle = CjguiComposableUiRect(200, 0, 8, 40)
    let acceptedFirst: Int64 = 200
    let same = visual.windowToSplitTrackPointX(handle, acceptedFirst, 303.25, 3.0)
    @Assert(CjguiComposableUiSplitGeometry.firstSizeForPointer(same, 0, 400, 8, 40, 40), 200)
    let moved = visual.windowToSplitTrackPointX(handle, acceptedFirst, 320.25, 3.0)
    @Assert(CjguiComposableUiSplitGeometry.firstSizeForPointer(moved, 0, 400, 8, 40, 40), 217)
    let restored = visual.windowToSplitTrackPointX(handle, acceptedFirst, 303.25, 3.0)
    @Assert(restored, same)
}

@Test
func translatedSplitCaptureRevisionDistinguishesOwnDragFromIndependentWrite(): Unit {
    let state = CjguiComposableUiSplitState(200, 40, 40)
    @Assert(state.claimOwner(91), true)
    state.acceptSplitTrack(400, 8, 200)
    let beginRevision = state.captureRevision()
    @Assert(state.applyCapturedFirstSize(beginRevision, 217, 400, 8), Some(beginRevision + 1))
    let ownRevision = state.captureRevision()
    // Accepted geometry publication is derived from this gesture, not a new
    // owner write. A second move may use the returned revision.
    state.acceptSplitTrack(400, 8, 217)
    @Assert(state.applyCapturedFirstSize(ownRevision, 230, 400, 8), Some(ownRevision + 1))
    // An accepted same-value write still revokes the old gesture's CAS token.
    state.setFirstSize(230)
    @Assert(state.applyCapturedFirstSize(ownRevision + 1, 240, 400, 8), None)
    @Assert(state.firstSize(), 230)
    let beforeCandidate = state.captureRevision()
    state.stageBoundsDeclaration(80, 40)
    state.discardStagedBoundsDeclaration()
    @Assert(state.captureRevision(), beforeCandidate)
    @Assert(state.firstMinimum(), 40)
    state.stageBoundsDeclaration(80, 40)
    state.commitStagedBoundsDeclaration()
    @Assert(state.captureRevision(), beforeCandidate + 1)
    @Assert(state.applyCapturedFirstSize(beforeCandidate, 240, 400, 8), None)
}

@Test
func translatedRevealSolvesAllRealClipOwnersBeforeRequesting(): Unit {
    // Child-only motion leaves the scroll clip fixed; the integer offset must
    // round toward guaranteed visibility, including the fractional edge.
    let target = CjguiComposableUiVisualRect(0.0, 120.25, 30.0, 20.0)
    let clips = ArrayList<CjguiComposableUiRevealClip>([
        CjguiComposableUiRevealClip(CjguiComposableUiVisualRect(0.0, 0.0, 100.0, 100.0), 0)
    ])
    let offsets = ArrayList<Int64>([0])
    let maximums = ArrayList<Int64>([200])
    let moved = CjguiComposableUiRevealPlanner.plan(target, clips, offsets, maximums)
    @Assert(moved.reason, "reveal_requested")
    @Assert(moved.offsets[0], 41)
    // Parent and child move together, preserving their relative demand.
    let both = ArrayList<CjguiComposableUiRevealClip>([
        CjguiComposableUiRevealClip(CjguiComposableUiVisualRect(0.0, 100.25, 100.0, 100.0), 0)
    ])
    let common = CjguiComposableUiRevealPlanner.plan(
        CjguiComposableUiVisualRect(0.0, 220.5, 30.0, 20.0), both, offsets, maximums)
    @Assert(common.offsets[0], 41)
    // The inner target fits its own clip but not the outer fixed clip. Only
    // the inner viewport can move; a greedy inner-only visibility check fails.
    let nested = ArrayList<CjguiComposableUiRevealClip>([
        CjguiComposableUiRevealClip(CjguiComposableUiVisualRect(0.0, 0.0, 100.0, 50.0), 1),
        CjguiComposableUiRevealClip(CjguiComposableUiVisualRect(0.0, 0.0, 100.0, 100.0), 0)
    ])
    let nestedPlan = CjguiComposableUiRevealPlanner.plan(
        CjguiComposableUiVisualRect(0.0, 80.0, 30.0, 10.0), nested,
        ArrayList<Int64>([0, 0]), ArrayList<Int64>([40, 0]))
    @Assert(nestedPlan.reason, "reveal_requested")
    @Assert(nestedPlan.offsets[0], 40)
    @Assert(nestedPlan.offsets[1], 0)
    let impossible = CjguiComposableUiRevealPlanner.plan(
        CjguiComposableUiVisualRect(0.0, 80.0, 30.0, 10.0), nested,
        ArrayList<Int64>([0, 0]), ArrayList<Int64>([0, 0]))
    @Assert(impossible.reason, "reveal_unreachable")
    @Assert(impossible.offsets.size, 0)
}

// The accepted window, rather than a hand-built planner input, must map a
// viewport's OWN clip to the offset of that viewport. Otherwise a single
// offscreen button is misclassified as impossible to reveal.
private class F11SingleViewportRevealController <: CjguiComposableUiController {
    let viewport = CjguiComposableUiScrollViewport()
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9940, "f11-reveal-root", CjguiComposableUiStyle())
        let scroll = cjguiComposableScrollArea(9941, "f11-reveal-scroll", viewport,
            CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: 100))
        let content = cjguiComposableVertical(9942, "f11-reveal-content", CjguiComposableUiStyle())
        content.add(cjguiComposableButton(9945, "f11-visible-target", "Visible at rest", "GO", -1,
            CjguiComposableUiStyle(fixedHeight: 36)))
        content.add(cjguiComposableVertical(9943, "f11-reveal-spacer",
            CjguiComposableUiStyle(fixedHeight: 300)))
        content.add(cjguiComposableButton(9944, "f11-reveal-target", "Visible after reveal", "GO", -1,
            CjguiComposableUiStyle(fixedHeight: 36)))
        scroll.add(content)
        root.add(scroll)
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

@Test
func translatedRevealSingleViewportOwnClipActuallyScrolls(): Unit {
    let controller = F11SingleViewportRevealController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    @Assert(controller.viewport.acceptedOffset(), 0)
    @Assert(controller.viewport.maximumOffset() > 0, true)
    let _ = window.focusAcceptedSemanticNode("f11-reveal-target")
    @Assert(controller.viewport.offset() > 0, true)
    @Assert(window.refresh(), true)
    @Assert(controller.viewport.acceptedOffset() > 0, true)
    window.close()
}

@Test
func translatedRevealCancelsPendingRequestThatWouldHideFocusedTarget(): Unit {
    let controller = F11SingleViewportRevealController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    @Assert(controller.viewport.acceptedOffset(), 0)
    @Assert(controller.viewport.requestOffset(100), true)
    @Assert(controller.viewport.offset(), 100)
    let _ = window.focusAcceptedSemanticNode("f11-visible-target")
    // The target is visible in the accepted scene; preserving the incompatible
    // pending offset would hide it on the next accepted scene.
    @Assert(controller.viewport.offset(), 0)
    @Assert(controller.viewport.hasPendingRequest(), false)
    window.close()
}

private class FPositionFocusController <: CjguiComposableUiController {
    public var declaredY: Int64 = 120
    public var visualY: Float64 = -100.0
    public var visualX: Float64 = 0.0
    public var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9950, "f-position-focus-root", CjguiComposableUiStyle())
        let clipped = cjguiComposableVertical(9952, "f-position-focus-clip",
            CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 100, clipsContent: true))
        clipped.add(cjguiComposableButton(9951, "f-position-focus-target", "Focus", "focus", -1,
            CjguiComposableUiStyle(fixedWidth: 20, fixedHeight: 20, offsetY: declaredY,
                translateX: visualX, translateY: visualY)))
        root.add(clipped)
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

@Test
func fPositionFocusUsesFinalAcceptedVisualClipOnBothAxes(): Unit {
    let controller = FPositionFocusController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    window.setFocusNativeStatusesForTest(ArrayList<Int32>([CJGUI_INTERNAL_RENDERER_OK]))
    // Layout is below the clip, yet its accepted visual rectangle is inside.
    @Assert(window.focusAcceptedSemanticNode("f-position-focus-target"), true)
    @Assert(window.focusedNodeIdForTest(), 9951)
    @Assert(window.focusNativeCallsForTest(), 1)
    // A layout-visible target translated outside the Y clip must never call native focus.
    controller.declaredY = 20
    controller.visualY = 100.0
    controller.revision += 1
    @Assert(window.refresh(), true)
    if (let Some(bounds) <- window.acceptedNodeVisualBounds("f-position-focus-target")) {
        @Assert(bounds.y, 120.0)
    } else { @Assert(false) }
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == 9951) {
            let clips = node.clipConstraints()
            @Assert(clips.size, 2)
            @Assert(clips[1].rect.height, 100)
        }
    }
    @Assert(window.focusAcceptedSemanticNode("f-position-focus-target"), false)
    @Assert(window.focusNativeCallsForTest(), 1)
    // The same rule applies to X; a one-axis Y-only check is insufficient.
    controller.visualY = 0.0
    controller.visualX = 110.0
    controller.revision += 1
    @Assert(window.refresh(), true)
    if (let Some(bounds) <- window.acceptedNodeVisualBounds("f-position-focus-target")) {
        @Assert(bounds.x, 110.0)
    } else { @Assert(false) }
    @Assert(window.focusAcceptedSemanticNode("f-position-focus-target"), false)
    @Assert(window.focusNativeCallsForTest(), 1)
    window.close()
}

// The normal window start/refresh is asynchronous and consumes owner turns.
// Match the established collection test fixture: wait for accepted progression,
// not the immediate return value of a single compatibility refresh attempt.
private func fPositionAwaitAccepted(window: CjguiComposableUiWindow, budget: CjguiOwnerTurnBudget): Bool {
    let before = window.windowProgress().acceptedSceneVersion
    window.requestRefresh()
    let deadline = MonoTime.now() + 5 * Duration.second
    var turns: Int64 = 0
    while (window.isOpen() && window.windowProgress().acceptedSceneVersion <= before &&
        turns < 240 && MonoTime.now() < deadline) {
        @Assert(budget.begin(), true)
        try {
            let _ = window.refreshIfNeeded()
            let _ = window.pump(0u32)
            let _ = budget.finishScheduling()
        } finally { budget.end() }
        turns += 1
    }
    return window.windowProgress().acceptedSceneVersion > before
}

private class FPositionSplitController <: CjguiComposableUiController {
    public let split = CjguiComposableUiSplitState(100, 40, 40)
    public var revision: Int64 = 1
    public var ancestorTranslateX: Float64 = 0.0
    public var ancestorTranslateY: Float64 = 0.0
    public var axis: Int64 = CjguiComposableUiSplitAxis.HORIZONTAL
    public var containerWidth: Int64 = 300
    public var containerHeight: Int64 = 80
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9960, "f-position-split-root",
            CjguiComposableUiStyle(translateX: ancestorTranslateX, translateY: ancestorTranslateY))
        let left = cjguiComposableVertical(9961, "f-position-split-left", CjguiComposableUiStyle())
        let right = cjguiComposableVertical(9962, "f-position-split-right", CjguiComposableUiStyle())
        root.add(cjguiComposableScopedSplitView(CjguiComposableUiIdentityScope("f-position-split"),
            "f-position-split", left, right, axis,
            split.firstSize(), 40, 40,
            CjguiComposableUiStyle(fixedWidth: containerWidth, fixedHeight: containerHeight),
            splitState: split))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func fPositionLegacySplitEvent(kind: Int64, nodeId: Int64, version: Int64,
    pointX: Float64): InternalRendererPumpResult {
    return fPositionSplitEventAt(kind, nodeId, version, pointX, 10.0)
}

private func fPositionSplitEventAt(kind: Int64, nodeId: Int64, version: Int64,
    pointX: Float64, pointY: Float64): InternalRendererPumpResult {
    return InternalRendererPumpResult(CJGUI_INTERNAL_RENDERER_OK, UInt32(kind), 0u32, 0u32, 0u32,
        UInt64(nodeId), UInt64(version), -1, UInt32(CJGUI_COMPOSABLE_UI_SPLIT_HANDLE), Int64(pointX), Int64(pointY),
        pointX, pointY, 0.0, 0.0, true, 0, 0u32, -1, 0, -1, 0,
        0u64, 77u64, 0u64, 0u64, 0u64, 0u64, -1, 0u64, 0u64)
}

@Test
func fPositionLegacySplitQueuedUpdateAndEndSurviveOwnAcceptedRedraw(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = FPositionSplitController()
        let window = CjguiComposableUiWindow(controller)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        @Assert(fPositionAwaitAccepted(window, budget), true)
        var handle = CjguiComposableUiLayoutNode.missing()
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE) { handle = node }
        }
        @Assert(handle.nodeId >= 0, true)
        let oldVersion = window.windowProgress().acceptedSceneVersion
        let start = Float64(handle.bounds.x) + 4.0
        @Assert(window.dispatchPointerEventForTest(fPositionLegacySplitEvent(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, handle.nodeId, oldVersion, start)).didApply, true)
        @Assert(window.dispatchPointerEventForTest(fPositionLegacySplitEvent(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, start + 10.0)).didApply, true)
        let firstSize = controller.split.firstSize()
        @Assert(firstSize > 100, true)
        controller.revision += 1
        @Assert(fPositionAwaitAccepted(window, budget), true)
        @Assert(window.windowProgress().acceptedSceneVersion > oldVersion, true)
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(window.pointerCaptureSplitStartVersionForTest(), oldVersion)
        @Assert(window.pointerCaptureSplitContinuousVersionForTest(), window.windowProgress().acceptedSceneVersion)
        // Both are already in the native FIFO under N. N+1 is this capture's own redraw.
        @Assert(window.dispatchPointerEventForTest(fPositionLegacySplitEvent(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, start + 20.0)).didApply, true)
        @Assert(controller.split.firstSize() > firstSize, true)
        let _ = window.dispatchPointerEventForTest(fPositionLegacySplitEvent(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_END, handle.nodeId, oldVersion, start + 20.0))
        let settled = controller.split.firstSize()
        @Assert(window.dispatchPointerEventForTest(fPositionLegacySplitEvent(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, start + 30.0)).didApply, false)
        @Assert(controller.split.firstSize(), settled)
        } finally { budget.end(); window.close() }
    })
}

@Test
func fPositionSplitCaptureCancelsAfterIndependentAncestorMotion(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = FPositionSplitController()
        let window = CjguiComposableUiWindow(controller)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        @Assert(fPositionAwaitAccepted(window, budget), true)
        var handle = CjguiComposableUiLayoutNode.missing()
        for (node in window.acceptedSceneNodes()) {
            if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE) { handle = node }
        }
        @Assert(handle.nodeId >= 0, true)
        let oldVersion = window.windowProgress().acceptedSceneVersion
        let start = Float64(handle.bounds.x) + 4.0
        @Assert(window.dispatchPointerEventForTest(fPositionLegacySplitEvent(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, handle.nodeId, oldVersion, start)).didApply, true)
        @Assert(window.pointerCaptureActiveForTest(), true)
        let originalSize = controller.split.firstSize()
        controller.ancestorTranslateX = 16.0
        controller.revision += 1
        @Assert(fPositionAwaitAccepted(window, budget), true)
        @Assert(window.windowProgress().acceptedSceneVersion > oldVersion, true)
        @Assert(window.pointerCaptureActiveForTest(), false)
        @Assert(window.dispatchPointerEventForTest(fPositionLegacySplitEvent(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, start + 24.0)).didApply, false)
        @Assert(controller.split.firstSize(), originalSize)
        } finally { budget.end(); window.close() }
    })
}

// ——— 纵向 splitState 拖动（axis=VERTICAL 的主轴 Y 路径） ———

private func fPositionVerticalSplitHandle(window: CjguiComposableUiWindow): CjguiComposableUiLayoutNode {
    var handle = CjguiComposableUiLayoutNode.missing()
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE) { handle = node }
    }
    return handle
}

@Test
func fPositionVerticalSplitPointerDragFollowsPointerY(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = FPositionSplitController()
        controller.axis = CjguiComposableUiSplitAxis.VERTICAL
        controller.containerWidth = 80
        controller.containerHeight = 300
        let window = CjguiComposableUiWindow(controller)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        @Assert(fPositionAwaitAccepted(window, budget), true)
        let handle = fPositionVerticalSplitHandle(window)
        @Assert(handle.nodeId >= 0, true)
        // The accepted solve keeps the declared 100 on the real 300-track.
        @Assert(controller.split.firstSize(), 100)
        @Assert(handle.bounds.y, 100)
        let oldVersion = window.windowProgress().acceptedSceneVersion
        let startX = Float64(handle.bounds.x) + 40.0
        let startY = Float64(handle.bounds.y) + 4.0
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, handle.nodeId, oldVersion, startX, startY)).didApply, true)
        // Drag DOWN along Y with X unchanged: a vertical divider must follow.
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, startX, startY + 30.0)).didApply, true)
        @Assert(controller.split.firstSize(), 130)
        let _ = window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_END, handle.nodeId, oldVersion, startX, startY + 30.0))
        let settled = controller.split.firstSize()
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, startX, startY + 40.0)).didApply, false)
        @Assert(controller.split.firstSize(), settled)
        } finally { budget.end(); window.close() }
    })
}

@Test
func fPositionVerticalSplitPressAtDifferentGrabPointDoesNotJumpOnRelease(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = FPositionSplitController()
        controller.axis = CjguiComposableUiSplitAxis.VERTICAL
        controller.containerWidth = 80
        controller.containerHeight = 300
        let window = CjguiComposableUiWindow(controller)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        @Assert(fPositionAwaitAccepted(window, budget), true)
        let handle = fPositionVerticalSplitHandle(window)
        @Assert(handle.nodeId >= 0, true)
        let oldVersion = window.windowProgress().acceptedSceneVersion
        let originalSize = controller.split.firstSize()
        // Press near the divider's far edge and release at the SAME point: the
        // grab offset must cancel the track mapping, not jump the divider.
        let startX = Float64(handle.bounds.x) + 10.0
        let pressY = Float64(handle.bounds.y) + 6.0
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, handle.nodeId, oldVersion, startX, pressY)).didApply, true)
        let _ = window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_END, handle.nodeId, oldVersion, startX, pressY))
        @Assert(controller.split.firstSize(), originalSize)
        } finally { budget.end(); window.close() }
    })
}

@Test
func fPositionVerticalSplitClampsAtMinimumsThenRecovers(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = FPositionSplitController()
        controller.axis = CjguiComposableUiSplitAxis.VERTICAL
        controller.containerWidth = 80
        controller.containerHeight = 300
        let window = CjguiComposableUiWindow(controller)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        @Assert(fPositionAwaitAccepted(window, budget), true)
        let handle = fPositionVerticalSplitHandle(window)
        @Assert(handle.nodeId >= 0, true)
        let oldVersion = window.windowProgress().acceptedSceneVersion
        let startX = Float64(handle.bounds.x) + 40.0
        let startY = Float64(handle.bounds.y) + 4.0
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, handle.nodeId, oldVersion, startX, startY)).didApply, true)
        // Far above the track: the framework's one rule clamps to minFirst=40.
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, startX, startY - 400.0)).didApply, true)
        @Assert(controller.split.firstSize(), 40)
        // Dragging back into the legal range moves again.
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, startX, startY + 40.0)).didApply, true)
        @Assert(controller.split.firstSize(), 140)
        let _ = window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_END, handle.nodeId, oldVersion, startX, startY + 40.0))
        } finally { budget.end(); window.close() }
    })
}

@Test
func fPositionVerticalSplitMapsThroughAncestorTranslate(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = FPositionSplitController()
        controller.axis = CjguiComposableUiSplitAxis.VERTICAL
        controller.containerWidth = 80
        controller.containerHeight = 300
        controller.ancestorTranslateY = 20.0
        let window = CjguiComposableUiWindow(controller)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        @Assert(fPositionAwaitAccepted(window, budget), true)
        let handle = fPositionVerticalSplitHandle(window)
        @Assert(handle.nodeId >= 0, true)
        // The accepted visual position includes the ancestor translate; the drag
        // must map window Y back through the SAME accepted geometry.
        if (let Some(bounds) <- window.acceptedNodeVisualBounds("f-position-split-handle")) {
            @Assert(bounds.y, 120.0)
        } else { @Assert(false) }
        let oldVersion = window.windowProgress().acceptedSceneVersion
        let startX = Float64(handle.bounds.x) + 40.0
        let visualStartY = 124.0
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, handle.nodeId, oldVersion, startX, visualStartY)).didApply, true)
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, startX, visualStartY + 30.0)).didApply, true)
        @Assert(controller.split.firstSize(), 130)
        let _ = window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_END, handle.nodeId, oldVersion, startX, visualStartY + 30.0))
        } finally { budget.end(); window.close() }
    })
}

@Test
func fPositionVerticalSplitQueuedUpdateAndEndSurviveOwnAcceptedRedraw(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = FPositionSplitController()
        controller.axis = CjguiComposableUiSplitAxis.VERTICAL
        controller.containerWidth = 80
        controller.containerHeight = 300
        let window = CjguiComposableUiWindow(controller)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        @Assert(fPositionAwaitAccepted(window, budget), true)
        let handle = fPositionVerticalSplitHandle(window)
        @Assert(handle.nodeId >= 0, true)
        let oldVersion = window.windowProgress().acceptedSceneVersion
        let startX = Float64(handle.bounds.x) + 40.0
        let startY = Float64(handle.bounds.y) + 4.0
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, handle.nodeId, oldVersion, startX, startY)).didApply, true)
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, startX, startY + 10.0)).didApply, true)
        let firstSize = controller.split.firstSize()
        @Assert(firstSize > 100, true)
        controller.revision += 1
        @Assert(fPositionAwaitAccepted(window, budget), true)
        @Assert(window.windowProgress().acceptedSceneVersion > oldVersion, true)
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(window.pointerCaptureSplitStartVersionForTest(), oldVersion)
        @Assert(window.pointerCaptureSplitContinuousVersionForTest(), window.windowProgress().acceptedSceneVersion)
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, startX, startY + 20.0)).didApply, true)
        @Assert(controller.split.firstSize() > firstSize, true)
        let _ = window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_END, handle.nodeId, oldVersion, startX, startY + 20.0))
        let settled = controller.split.firstSize()
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, startX, startY + 30.0)).didApply, false)
        @Assert(controller.split.firstSize(), settled)
        } finally { budget.end(); window.close() }
    })
}

@Test
func fPositionVerticalSplitCaptureCancelsAfterIndependentAncestorMotion(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = FPositionSplitController()
        controller.axis = CjguiComposableUiSplitAxis.VERTICAL
        controller.containerWidth = 80
        controller.containerHeight = 300
        let window = CjguiComposableUiWindow(controller)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
        @Assert(window.start(), true)
        @Assert(fPositionAwaitAccepted(window, budget), true)
        let handle = fPositionVerticalSplitHandle(window)
        @Assert(handle.nodeId >= 0, true)
        let oldVersion = window.windowProgress().acceptedSceneVersion
        let startX = Float64(handle.bounds.x) + 40.0
        let startY = Float64(handle.bounds.y) + 4.0
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN, handle.nodeId, oldVersion, startX, startY)).didApply, true)
        @Assert(window.pointerCaptureActiveForTest(), true)
        let originalSize = controller.split.firstSize()
        controller.ancestorTranslateY = 16.0
        controller.revision += 1
        @Assert(fPositionAwaitAccepted(window, budget), true)
        @Assert(window.windowProgress().acceptedSceneVersion > oldVersion, true)
        @Assert(window.pointerCaptureActiveForTest(), false)
        @Assert(window.dispatchPointerEventForTest(fPositionSplitEventAt(
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE, handle.nodeId, oldVersion, startX, startY + 24.0)).didApply, false)
        @Assert(controller.split.firstSize(), originalSize)
        } finally { budget.end(); window.close() }
    })
}

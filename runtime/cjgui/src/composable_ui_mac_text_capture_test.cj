package cjgui

import std.collection.*

private class MacTextCaptureController <: CjguiComposableUiController & CjguiComposableUiPointerCaptureVersionProvider {
    var revision: Int64 = 1
    var scrollFixture: Bool = false
    var scrollHeight: Int64 = 140
    var viewport = CjguiComposableUiScrollViewport()
    var ownerRevision: Int64 = 1
    var sourceRevision: Int64 = 0
    var translateX: Float64 = 0.0
    var fieldId: String = "original-source-span"
    var incarnation: Int64 = 1
    var label: String = "caret 0"
    var duplicate: Bool = false
    var selectionDecoration: Bool = false
    var fontSize: Float64 = 18.0
    let phases = ArrayList<Int64>()
    let deliveredVersions = ArrayList<Int64>()
    let runs = [CjguiComposableUiTextStyleRun(0, 5, 18.0, 0, "system", 0.1, 0.1, 0.1, 1.0)]
    public func uiSceneVersion(): Int64 { return revision }
    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        return ownerRevision + sourceRevision * 1000000
    }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(7770, "mac-capture-root",
            CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: 180, clipsContent: true))
        let displayedRuns = ArrayList<CjguiComposableUiTextStyleRun>(runs)
        if (selectionDecoration) { displayedRuns.add(CjguiComposableUiTextStyleRun.selectionBackground(1, 3,
            CjguiComposableUiColor(0.2, 0.3, 0.8, 0.55))) }
        let text = cjguiComposableText(7771, "mac-capture-body", "ABCDE🙂",
            CjguiComposableUiStyle(fixedWidth: 250, fixedHeight: 55, pointerInteractive: true,
                translateX: translateX, fontSize: fontSize), fieldId: fieldId, textStyleRuns: displayedRuns.toArray())
        text.semanticIncarnation = incarnation
        if (scrollFixture) {
            let scroll = cjguiComposableScrollArea(7780, "mac-capture-scroll", viewport,
                CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: scrollHeight, clipsContent: true))
            let content = cjguiComposableVertical(7781, "mac-capture-content",
                CjguiComposableUiStyle(fixedWidth: 300, fixedHeight: 500))
            content.add(text)
            content.add(cjguiComposableVertical(7782, "mac-capture-spacer",
                CjguiComposableUiStyle(fixedHeight: 300)))
            content.add(cjguiComposableText(7773, "mac-capture-next-body", "FGHIJ",
                CjguiComposableUiStyle(fixedWidth: 250, fixedHeight: 55, pointerInteractive: true)))
            scroll.add(content)
            root.add(scroll)
        } else { root.add(text) }
        root.add(cjguiComposableText(7772, "mac-capture-caret-output", label,
            CjguiComposableUiStyle(fixedHeight: 30)))
        if (duplicate) { root.add(cjguiComposableText(7771, "rejected-duplicate", "bad", CjguiComposableUiStyle())) }
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind < 37 || event.eventKind > 40) { return CjguiComposableUiDispatchResult(false) }
        phases.add(event.eventKind)
        deliveredVersions.add(event.projectionVersion)
        label = "caret ${phases.size}"
        revision += 1
        return CjguiComposableUiDispatchResult(true)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func macTextPointer(kind: Int64, scene: Int64, epoch!: UInt64 = 901u64,
    x!: Float64 = 20.0): InternalRendererPumpResult {
    return InternalRendererPumpResult(CJGUI_INTERNAL_RENDERER_OK, UInt32(kind), 0u32, 0u32, 0u32,
        7771u64, UInt64(scene), -1, UInt32(CJGUI_COMPOSABLE_UI_TEXT), Int64(x), 20,
        x, 20.0, 0.0, 0.0, true, 0, 0u32, -1, 0, -1, 0,
        0u64, epoch, 0u64, 0u64, 0u64, 0u64, -1, 0u64, 0u64)
}

// Explicit synthetic unit origin; production has no fallback to this read.
private func macTextDispatch(window: CjguiComposableUiWindow,
    event: InternalRendererPumpResult): CjguiComposableUiDispatchResult {
    let (generation, coordinate) = window.macTextCoordinateLifetimeForTest()
    return window.dispatchPointerEventWithCoordinateForTest(event, generation, coordinate)
}

@Test
func macTextQueuedOldSceneSurvivesAcceptedCaretRedraw(): Unit {
    let controller = MacTextCaptureController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let beginScene = window.windowProgress().acceptedSceneVersion
        @Assert(macTextDispatch(window, macTextPointer(37, beginScene)).didApply, true)
        @Assert(window.refresh(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > beginScene, true)
        @Assert(macTextDispatch(window, macTextPointer(38, beginScene, x: 65.0)).didApply, true)
        @Assert(window.refresh(), true)
        @Assert(macTextDispatch(window, macTextPointer(39, beginScene, x: 65.0)).didApply, true)
        @Assert(controller.ownerRevision, 1)
        @Assert(controller.phases.toArray(), [37, 38, 39])
        @Assert(controller.deliveredVersions.toArray(), [beginScene, beginScene, beginScene])
        @Assert(window.pointerCaptureActiveForTest(), false)
    } finally { window.close() }
}

@Test
func macTextCaptureRejectsOwnerChangeBeforeAnyNewFrame(): Unit {
    let controller = MacTextCaptureController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let scene = window.windowProgress().acceptedSceneVersion
        @Assert(macTextDispatch(window, macTextPointer(37, scene)).didApply, true)
        controller.ownerRevision += 1
        let _ = macTextDispatch(window, macTextPointer(38, scene))
        @Assert(controller.phases.toArray(), [37, 40])
        @Assert(window.pointerCaptureActiveForTest(), false)
    } finally { window.close() }
}

@Test
func macTextCaptureFractionalMotionAndBindingAbaRemainRevoked(): Unit {
    for (change in 0..3) {
        let controller = MacTextCaptureController()
        let window = CjguiComposableUiWindow(controller)
        try {
            @Assert(window.start(), true)
            @Assert(window.refresh(), true)
            let scene = window.windowProgress().acceptedSceneVersion
            @Assert(macTextDispatch(window, macTextPointer(37, scene)).didApply, true)
            if (change == 0) { controller.translateX = 0.25 }
            if (change == 1) { controller.fieldId = "same-text-other-source-span" }
            if (change == 2) { controller.incarnation += 1 }
            controller.revision += 1
            @Assert(window.refresh(), true)
            controller.translateX = 0.0
            controller.fieldId = "original-source-span"
            controller.incarnation = 1
            controller.revision += 1
            @Assert(window.refresh(), true)
            let _ = macTextDispatch(window, macTextPointer(38, scene))
            @Assert(controller.phases.toArray(), [37, 40])
            @Assert(window.pointerCaptureActiveForTest(), false)
        } finally { window.close() }
    }
}

@Test
func macTextCaptureFreezesMutableRunContainerBeforeBegin(): Unit {
    let controller = MacTextCaptureController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let scene = window.windowProgress().acceptedSceneVersion
        @Assert(macTextDispatch(window, macTextPointer(37, scene)).didApply, true)
        controller.runs[0] = CjguiComposableUiTextStyleRun(0, 5, 18.0, 600, "system", 0.1, 0.1, 0.1, 1.0)
        @Assert(window.refresh(), true)
        let _ = macTextDispatch(window, macTextPointer(38, scene))
        @Assert(controller.phases.toArray(), [37, 40])
    } finally { window.close() }
}

@Test
func macTextCaptureLateForeignTerminalDoesNotEndNewGesture(): Unit {
    let controller = MacTextCaptureController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let scene = window.windowProgress().acceptedSceneVersion
        @Assert(macTextDispatch(window, macTextPointer(37, scene)).didApply, true)
        @Assert(macTextDispatch(window, macTextPointer(37, scene, epoch: 902u64)).didApply, true)
        let _ = macTextDispatch(window, macTextPointer(40, scene))
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(macTextDispatch(window, macTextPointer(39, scene, epoch: 902u64)).didApply, true)
        @Assert(controller.phases.toArray(), [37, 40, 37, 39])
    } finally { window.close() }
}

@Test
func macTextCaptureSelectionBackgroundCanAppearAndClear(): Unit {
    let controller = MacTextCaptureController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let scene = window.windowProgress().acceptedSceneVersion
        @Assert(macTextDispatch(window, macTextPointer(37, scene)).didApply, true)
        controller.selectionDecoration = true
        controller.revision += 1
        @Assert(window.refresh(), true)
        @Assert(macTextDispatch(window, macTextPointer(38, scene)).didApply, true)
        controller.selectionDecoration = false
        controller.revision += 1
        @Assert(window.refresh(), true)
        @Assert(macTextDispatch(window, macTextPointer(39, scene)).didApply, true)
        @Assert(controller.phases.toArray(), [37, 38, 39])
    } finally { window.close() }
}

@Test
func macTextCaptureUnknownOrChangedQueuedCoordinateIsRefused(): Unit {
    let controller = MacTextCaptureController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let scene = window.windowProgress().acceptedSceneVersion
        @Assert(window.dispatchPointerEventWithCoordinateForTest(macTextPointer(37, scene), 0u64, 0u64).didApply, false)
        @Assert(controller.phases.size, 0)
        let (generation, coordinate) = window.macTextCoordinateLifetimeForTest()
        @Assert(window.dispatchPointerEventWithCoordinateForTest(macTextPointer(37, scene), generation, coordinate).didApply, true)
        let _ = window.dispatchPointerEventWithCoordinateForTest(macTextPointer(38, scene), generation, coordinate + 1u64)
        @Assert(controller.phases.toArray(), [37, 40])
        @Assert(window.pointerCaptureActiveForTest(), false)
    } finally { window.close() }
}

@Test
func macTextCaptureUncertifiedSceneIsRefused(): Unit {
    let controller = MacTextCaptureController()
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let scene = window.windowProgress().acceptedSceneVersion
        @Assert(macTextDispatch(window, macTextPointer(37, scene)).didApply, true)
        let _ = macTextDispatch(window, macTextPointer(38, scene + 100))
        @Assert(controller.phases.toArray(), [37, 40])
    } finally { window.close() }
}

@Test
func selectionBackgroundEncodingAndBoundaryValidation(): Unit {
    let ordinary = CjguiComposableUiTextStyleRun(0, 1, 18.0, 0, "system", 0.1, 0.2, 0.3, 1.0)
    @Assert(ordinary.encoded().split(":").size, 14)
    let color = CjguiComposableUiColor(0.1, 0.2, 0.3, 0.55)
    let valid = CjguiComposableUiTextStyleRun.selectionBackground(1, 5, color)
    @Assert(valid.encoded().split(":").size, 15)
    @Assert(cjguiSelectionBackgroundRunsRejection("A🙂Z", [ordinary, valid]).isNone(), true)
    for ((start, end) in [(2, 5), (1, 3), (5, 5), (-1, 1), (0, 8)]) {
        @Assert(cjguiSelectionBackgroundRunsRejection("A🙂Z", [
            CjguiComposableUiTextStyleRun.selectionBackground(start, end, color)]).isSome(), true)
    }
    @Assert(cjguiSelectionBackgroundRunsRejection("A", [CjguiComposableUiTextStyleRun.selectionBackground(0, 1,
        CjguiComposableUiColor(0.0, 0.0, 0.0, 1.1))]).isSome(), true)
}

@Test
func macTextCapturedScrollAcceptedYOffsetPreservesOriginalGesture(): Unit {
    let controller = MacTextCaptureController()
    controller.scrollFixture = true
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let scene = window.windowProgress().acceptedSceneVersion
        @Assert(macTextDispatch(window, macTextPointer(37, scene)).didApply, true)
        @Assert(controller.viewport.requestOffset(32), true)
        controller.revision += 1
        @Assert(window.refresh(), true)
        @Assert(controller.viewport.acceptedOffset(), 32)
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(macTextDispatch(window, macTextPointer(38, scene)).didApply, true)
        @Assert(macTextDispatch(window, macTextPointer(39, scene)).didApply, true)
        @Assert(controller.phases.toArray(), [37, 38, 39])
    } finally { window.close() }
}

@Test
func macTextCapturedScrollStillRejectsRebindingExtentAndFractionalChanges(): Unit {
    for (change in 0..4) {
        let controller = MacTextCaptureController()
        controller.scrollFixture = true
        let window = CjguiComposableUiWindow(controller)
        try {
            @Assert(window.start(), true)
            @Assert(window.refresh(), true)
            let scene = window.windowProgress().acceptedSceneVersion
            @Assert(macTextDispatch(window, macTextPointer(37, scene)).didApply, true)
            let _ = controller.viewport.requestOffset(32)
            if (change == 0) { controller.viewport = CjguiComposableUiScrollViewport() }
            if (change == 1) { controller.scrollHeight = 130 }
            if (change == 2) { controller.translateX = 0.25 }
            if (change == 3) { controller.ownerRevision += 1 }
            controller.revision += 1
            @Assert(window.refresh(), true)
            let _ = macTextDispatch(window, macTextPointer(38, scene))
            @Assert(controller.phases.toArray(), [37, 40])
            @Assert(window.pointerCaptureActiveForTest(), false)
        } finally { window.close() }
    }
}

@Test
func acceptedTextNearestPointUsesVisibleIntersectionAfterScroll(): Unit {
    let controller = MacTextCaptureController()
    controller.scrollFixture = true
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(window.nearestVisibleTextNodeAtAcceptedPoint([7771, 7773], 20.0, 200.0), Some(7771))
        let _ = controller.viewport.requestOffset(350)
        controller.revision += 1
        @Assert(window.refresh(), true)
        @Assert(window.nearestVisibleTextNodeAtAcceptedPoint([7771, 7773], 20.0, 200.0), Some(7773))
        @Assert(window.nearestVisibleTextNodeAtAcceptedPoint([7771], 20.0, 200.0).isNone(), true)
        @Assert(window.nearestVisibleTextNodeAtAcceptedPoint([7772], 20.0, 200.0).isNone(), true)
    } finally { window.close() }
}

foreign {
    func cjgui_internal_renderer_test_begin_composable_pointer(session: UInt64, nodeId: UInt64,
        x: Float64, y: Float64): Int32
    func cjgui_internal_renderer_test_active_pointer_epoch(session: UInt64): UInt64
    func cjgui_internal_renderer_test_captured_pointer_phase(session: UInt64, phase: UInt32,
        x: Float64, y: Float64): Int32
    func cjgui_internal_renderer_test_pointer_edge_active(session: UInt64): Int32
}

private func macTextNativeBegin(window: CjguiComposableUiWindow): Int32 {
    unsafe { return cjgui_internal_renderer_test_begin_composable_pointer(window.testSessionToken(),
        7771u64, 20.0, 20.0) }
}
private func macTextNativeEpoch(window: CjguiComposableUiWindow): UInt64 {
    unsafe { return cjgui_internal_renderer_test_active_pointer_epoch(window.testSessionToken()) }
}
private func macTextNativePhase(window: CjguiComposableUiWindow, phase: UInt32,
    y!: Float64 = 20.0): Int32 {
    unsafe { return cjgui_internal_renderer_test_captured_pointer_phase(window.testSessionToken(),
        phase, 25.0, y) }
}
private func macTextNativeEdgeActive(window: CjguiComposableUiWindow): Int32 {
    unsafe { return cjgui_internal_renderer_test_pointer_edge_active(window.testSessionToken()) }
}
private func macTextPumpUntilBegin(window: CjguiComposableUiWindow, controller: MacTextCaptureController): Unit {
    for (_ in 0..8) {
        if (controller.phases.size > 0) { return }
        let _ = window.pump(0u32)
    }
}
private func macTextPublishUntilAccepted(window: CjguiComposableUiWindow, previous: Int64): Unit {
    for (_ in 0..64) {
        if (window.windowProgress().acceptedSceneVersion > previous) { return }
        let _ = window.refreshIfNeeded()
    }
    @Assert(window.windowProgress().acceptedSceneVersion > previous, true)
}

@Test
func macTextBeginQueuedBeforeSameSourceRedrawKeepsOriginalOneShot(): Unit {
    let controller = MacTextCaptureController()
    controller.scrollFixture = true
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let original = window.windowProgress().acceptedSceneVersion
        @Assert(macTextNativeBegin(window), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(macTextNativeEpoch(window) > 0u64, true)
        let epoch = macTextNativeEpoch(window)
        controller.label = "unrelated redraw before BEGIN consumption"
        controller.revision += 1
        @Assert(window.refresh(), true)
        @Assert(window.windowProgress().acceptedSceneVersion > original, true)
        macTextPumpUntilBegin(window, controller)
        @Assert(controller.phases.toArray(), [CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN])
        @Assert(controller.deliveredVersions.toArray(), [original])
        @Assert(window.pointerCaptureActiveForTest(), true)
        @Assert(internalRendererConsumePointerBeginOrigin(window.testSessionToken(), epoch).isNone(), true)
        println("MAC_TEXT_BEGIN_ORIGIN same_source_original_once=true scene=${original}")
    } finally { window.close() }
}

@Test
func macTextBeginOwnerChangeRejectsAndStopsMatchingNativeCapture(): Unit {
    let controller = MacTextCaptureController()
    controller.scrollFixture = true
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(macTextNativeBegin(window), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(macTextNativeEpoch(window) > 0u64, true)
        @Assert(macTextNativePhase(window, 2u32, y: 160.0), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(macTextNativeEdgeActive(window), 1)
        controller.ownerRevision += 1
        controller.revision += 1
        @Assert(window.refresh(), true)
        for (_ in 0..8) { let _ = window.pump(0u32) }
        @Assert(controller.phases.size, 0)
        @Assert(macTextNativeEpoch(window), 0u64)
        @Assert(macTextNativeEdgeActive(window), 0)
        @Assert(window.pointerCaptureActiveForTest(), false)
    } finally { window.close() }
}

@Test
func macTextBeginQueuedIntermediateUpdatesKeepEveryAcceptedOriginalScene(): Unit {
    let controller = MacTextCaptureController()
    controller.scrollFixture = true
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        let first = window.windowProgress().acceptedSceneVersion
        @Assert(macTextNativeBegin(window), CJGUI_INTERNAL_RENDERER_OK)
        controller.label = "first intervening accepted redraw"
        controller.revision += 1
        @Assert(window.refresh(), true)
        let second = window.windowProgress().acceptedSceneVersion
        @Assert(macTextNativePhase(window, 2u32), CJGUI_INTERNAL_RENDERER_OK)
        controller.label = "second intervening accepted redraw"
        controller.revision += 1
        @Assert(window.refresh(), true)
        let third = window.windowProgress().acceptedSceneVersion
        @Assert(macTextNativePhase(window, 2u32), CJGUI_INTERNAL_RENDERER_OK)
        for (_ in 0..12) { let _ = window.pump(0u32) }
        @Assert(controller.phases.toArray(), [37, 38, 38])
        @Assert(controller.deliveredVersions.toArray(), [first, second, third])
        @Assert(window.pointerCaptureActiveForTest(), true)
    } finally { window.close() }
}

@Test
func macTextBeginChangedOriginRejectsBindingMapGeometryAndAba(): Unit {
    for (change in 0..7) {
        let controller = MacTextCaptureController()
        controller.scrollFixture = true
        let window = CjguiComposableUiWindow(controller)
        try {
            @Assert(window.start(), true)
            @Assert(window.refresh(), true)
            @Assert(macTextNativeBegin(window), CJGUI_INTERNAL_RENDERER_OK)
            if (change == 0) { controller.fieldId = "replaced-source-span" }
            if (change == 1) { controller.incarnation += 1 }
            if (change == 2) { controller.translateX = 0.25 }
            if (change == 3) { controller.scrollHeight = 130 }
            if (change == 4) { controller.sourceRevision += 1 }
            if (change == 5) { controller.fontSize = 19.0 }
            if (change == 6) {
                controller.fieldId = "temporarily-replaced-source-span"
                controller.sourceRevision += 1
                controller.label = "accepted replacement"
            }
            let before = window.windowProgress().acceptedSceneVersion
            controller.revision += 1
            @Assert(window.refresh(), true)
            if (change == 6) {
                macTextPublishUntilAccepted(window, before)
                let changed = window.windowProgress().acceptedSceneVersion
                controller.fieldId = "original-source-span"
                controller.sourceRevision += 1
                controller.label = "accepted return with a new source identity"
                controller.revision += 1
                @Assert(window.refresh(), true)
                macTextPublishUntilAccepted(window, changed)
            }
            for (_ in 0..8) { let _ = window.pump(0u32) }
            println("MAC_TEXT_BEGIN_CHANGED change=${change} phases=${controller.phases.toArray()} " +
                "native_epoch=${macTextNativeEpoch(window)} scene=${window.windowProgress().acceptedSceneVersion}")
            @Assert(controller.phases.size, 0)
            @Assert(macTextNativeEpoch(window), 0u64)
            @Assert(window.pointerCaptureActiveForTest(), false)
        } finally { window.close() }
    }
}

@Test
func macTextBeginOldQueuedRejectionAndUpCannotStopNewNativeEpoch(): Unit {
    let controller = MacTextCaptureController()
    controller.scrollFixture = true
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        @Assert(macTextNativeBegin(window), CJGUI_INTERNAL_RENDERER_OK)
        let old = macTextNativeEpoch(window)
        @Assert(macTextNativePhase(window, 3u32), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(macTextNativeBegin(window), CJGUI_INTERNAL_RENDERER_OK)
        let successor = macTextNativeEpoch(window)
        @Assert(successor > old, true)
        for (_ in 0..12) { let _ = window.pump(0u32) }
        @Assert(controller.phases.toArray(), [37])
        @Assert(macTextNativeEpoch(window), successor)
        @Assert(window.pointerCaptureActiveForTest(), true)
        let _ = internalRendererCancelComposablePointerCaptureEpoch(window.testSessionToken(), old)
        @Assert(macTextNativeEpoch(window), successor)
        let scene = window.windowProgress().acceptedSceneVersion
        // Explicit adversarial late envelope after the actual old UP FIFO;
        // it cannot become a successor's event or cancel its native capture.
        @Assert(macTextDispatch(window, macTextPointer(39, scene, epoch: old)).didApply, false)
        @Assert(macTextNativeEpoch(window), successor)
        @Assert(window.pointerCaptureActiveForTest(), true)
    } finally { window.close() }
}

@Test
func macTextBeginNewMapPublicationUnderSameNativeSceneOwnsNewDown(): Unit {
    let controller = MacTextCaptureController()
    controller.scrollFixture = true
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        for (_ in 0..4) { let _ = window.pump(0u32) }
        let original = window.inputSceneVersion()
        controller.sourceRevision += 1
        controller.revision += 1
        @Assert(window.refresh(), true)
        @Assert(window.inputSceneVersion(), original)
        @Assert(macTextNativeBegin(window), CJGUI_INTERNAL_RENDERER_OK)
        macTextPumpUntilBegin(window, controller)
        @Assert(controller.phases.toArray(), [37])
        @Assert(window.pointerCaptureActiveForTest(), true)
    } finally { window.close() }
}

@Test
func macTextBeginOldAndNewDownSeparateSameSceneSourcePublications(): Unit {
    let controller = MacTextCaptureController()
    controller.scrollFixture = true
    let window = CjguiComposableUiWindow(controller)
    try {
        @Assert(window.start(), true)
        @Assert(window.refresh(), true)
        for (_ in 0..4) { let _ = window.pump(0u32) }
        let original = window.inputSceneVersion()
        @Assert(macTextNativeBegin(window), CJGUI_INTERNAL_RENDERER_OK)
        let old = macTextNativeEpoch(window)
        controller.sourceRevision += 1
        controller.revision += 1
        @Assert(window.refresh(), true)
        @Assert(window.inputSceneVersion(), original)
        @Assert(macTextNativeBegin(window), CJGUI_INTERNAL_RENDERER_OK)
        let successor = macTextNativeEpoch(window)
        @Assert(successor > old, true)
        for (_ in 0..12) { let _ = window.pump(0u32) }
        @Assert(controller.phases.toArray(), [37])
        @Assert(macTextNativeEpoch(window), successor)
        @Assert(window.pointerCaptureActiveForTest(), true)
    } finally { window.close() }
}

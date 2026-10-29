package cjgui

import std.collection.*
import std.sync.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

// Native declarations are shared with composable_ui_source_handoff_test.cj.

// Ordinary whole-value owner, without a range session or external revision
// provider. No private owner/native generations are forced by this fixture.
private class OwnerPaintFrontierController <: CjguiComposableUiController {
    var body = "B-history-18"
    var version: Int64 = 12
    var writes: Int64 = 0
    var builds: Int64 = 0
    var resource: Int64 = 6201

    public func uiSceneVersion(): Int64 { return version }
    public func buildUi(): CjguiComposableUiNode {
        builds += 1
        let root = cjguiComposableVertical(1, "owner-paint-root", CjguiComposableUiStyle(gap: 8, padding: 12))
        root.add(cjguiComposableTextInput(910, "owner-paint-text", "任务", body, resource,
            CjguiComposableUiStyle(fixedWidth: 400, fixedHeight: 32, fontSize: 14.0)))
        root.add(cjguiComposableButton(911, "owner-paint-button", "普通绘制目标", "NOOP", 6302,
            CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 32,
                background: CjguiComposableUiColor(0.2, 0.3, 0.4, 1.0))))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.node.nodeId == 910 && event.eventKind == 28) {
            body = event.text
            version += 1
            writes += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func ownerPaintTextIndex(window: CjguiComposableUiWindow): UInt32 {
    var index: UInt32 = 0u32
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == 910) { return index }
        index += 1u32
    }
    throw Exception("owner_paint_text_not_accepted")
}

private func ownerPaintInsert(window: CjguiComposableUiWindow, index: UInt32, text: String): Int32 {
    let native = unsafe { LibC.mallocCString(text) }
    var status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (value = native.asResource()) {
        status = unsafe { cjgui_internal_renderer_test_insert_composable_text(
            window.testSessionToken(), index, value.value) }
    }
    return status
}

private func ownerPaintDrain(window: CjguiComposableUiWindow,
    controller: OwnerPaintFrontierController, expected: String): Unit {
    let deadline = MonoTime.now() + 3 * Duration.second
    while (MonoTime.now() < deadline && (controller.body != expected ||
        internalRendererOwnerPumpHasUnconsumedInput(window.testSessionToken()))) {
        let _ = window.pumpEventsWithoutRefresh(1u32)
    }
    println("OWNER_PAINT_BODY owner=[${controller.body}] bytes=${controller.body.size} " +
        "expected=[${expected}] owner_version=${controller.version} writes=${controller.writes}")
    @Assert(controller.body, expected)
    @Assert(internalRendererOwnerPumpHasUnconsumedInput(window.testSessionToken()), false)
}

private func ownerPaintSettleOrdinaryTurn(window: CjguiComposableUiWindow): Unit {
    let deadline = MonoTime.now() + 3 * Duration.second
    while ((window.displayedSceneVersion() <= 0 || window.hasDeferredEventWork()) &&
        MonoTime.now() < deadline) {
        let _ = window.pumpEventsWithoutRefresh(1u32)
        let _ = window.refreshAfterDeferredPump()
    }
    println("OWNER_PAINT ordinary_turn " + window.schedulingObservation())
    @Assert(window.displayedSceneVersion() > 0, true)
    @Assert(window.hasDeferredEventWork(), false)
}

private func ownerPaintAcquireDrawable(window: CjguiComposableUiWindow, projection: Int64): Unit {
    let deadline = MonoTime.now() + 3 * Duration.second
    var ready = false
    while (!ready && MonoTime.now() < deadline) {
        let (status, actualReady) = internalRendererReserveComposableDrawable(
            window.testSessionToken(), 0u64, UInt64(projection))
        @Assert(status, CJGUI_INTERNAL_RENDERER_OK)
        ready = actualReady
        if (!ready) { sleep(Duration.Zero) }
    }
    @Assert(ready, true)
    println("OWNER_PAINT actual_drawable_ready projection=${projection}")
}

// Replays the actual legal gap: original owner data has changed through real
// TextKit/FIFO dispatch, full refresh is deferred, then an interaction repaint
// tries to reuse the previously accepted body. A further original key must
// still address the new proxy body, not the older visual snapshot.
@When[os == "macOS"]
@Test
func ownerPaintDoesNotReinstallOldBodyBetweenOriginalKeys(): Unit {
    cjguiMacosOwnerTest({ => ownerPaintOriginalKeysBody() })
}

private func ownerPaintOriginalKeysBody(): Unit {
    let controller = OwnerPaintFrontierController()
    let window = CjguiComposableUiWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration(
            "CJGUI owner paint deterministic regression", 640u32, 480u32,
            rangeTextEditDeltaDelivery: false))
    @Assert(window.start(), true)
    try {
        ownerPaintSettleOrdinaryTurn(window)
        @Assert(window.focusAcceptedNodeById(910), true)
        ownerPaintSettleOrdinaryTurn(window)
        @Assert(window.focusedNodeReference().isSome(), true)
        let index = ownerPaintTextIndex(window)
        @Assert(unsafe { cjgui_internal_renderer_test_set_composable_selection(
            window.testSessionToken(), index, 12u32, 12u32) }, CJGUI_INTERNAL_RENDERER_OK)
        let _ = window.pumpEventsWithoutRefresh(1u32)
        let baseScene = window.displayedSceneVersion()
        for (key in ["-", "n", "e", "x", "t"]) {
            @Assert(ownerPaintInsert(window, index, key), CJGUI_INTERNAL_RENDERER_OK)
        }
        ownerPaintDrain(window, controller, "B-history-18-next")
        println("OWNER_PAINT owner_changed " + window.schedulingObservation())
        @Assert(window.acceptedSceneNodes()[Int64(index)].value, "B-history-18")
        @Assert(window.schedulingObservation().contains("refresh=true"), true)

        // The normal paint opportunity requires an actual Metal drawable.
        // Establish that existing resource seam without refreshing semantic
        // data; an unserviced pending reservation is not an old-frame RED.
        ownerPaintAcquireDrawable(window, baseScene + 1)

        // Zero-duration normal animation uses the production interaction
        // paint path immediately; no timer, sleep or fabricated frame state.
        @Assert(window.animateNodeOpacity("semantic:owner-paint-button", 0.5,
            spec: CjguiComposableUiAnimationSpec.tween(durationMs: 0), atTime: MonoTime.now()), true)
        let pendingDeadline = MonoTime.now() + 3 * Duration.second
        while ((window.hasRetainedSceneContinuation() || window.nativeStatus() ==
            CJGUI_INTERNAL_RENDERER_PRESENT_PENDING) && MonoTime.now() < pendingDeadline) {
            let pendingPaint = !window.hasRetainedSceneContinuation()
            let _ = window.pumpEventsWithoutRefresh(1u32)
            if (pendingPaint) { let _ = window.testRefreshInteractionPaint() }
        }
        @Assert(window.hasRetainedSceneContinuation(), false)
        @Assert(window.nativeStatus(), CJGUI_INTERNAL_RENDERER_OK)
        let afterPaintScene = window.displayedSceneVersion()
        println("OWNER_PAINT after_paint " + window.schedulingObservation())

        // This key occupies the actual 94-to-95 gap. A correct owner input
        // result is the independent original sequence followed by x.
        @Assert(ownerPaintInsert(window, index, "x"), CJGUI_INTERNAL_RENDERER_OK)
        ownerPaintDrain(window, controller, "B-history-18-nextx")
        @Assert(afterPaintScene, baseScene)
    } finally {
        window.close()
    }
}


private func ownerPaintResolvePendingOnly(window: CjguiComposableUiWindow): Unit {
    let deadline = MonoTime.now() + 3 * Duration.second
    while ((window.hasRetainedSceneContinuation() || window.nativeStatus() ==
        CJGUI_INTERNAL_RENDERER_PRESENT_PENDING) && MonoTime.now() < deadline) {
        let pendingPaint = !window.hasRetainedSceneContinuation()
        let _ = window.pumpEventsWithoutRefresh(1u32)
        if (pendingPaint) { let _ = window.testRefreshInteractionPaint() }
    }
    @Assert(window.hasRetainedSceneContinuation(), false)
    @Assert(window.nativeStatus(), CJGUI_INTERNAL_RENDERER_OK)
}

// A non-visual business revision may move while the UI declaration remains
// valid. The paint must not acknowledge that newer owner using the old base;
// it must establish an ordinary refresh demand, not a deferred self-loop.
private class OwnerRevisionPaintController <: CjguiComposableUiController &
    CjguiComposableUiBusinessOwnerRevisionProvider {
    let delegate = OwnerPaintFrontierController()
    var ownerRevision: Int64 = 12
    public func uiSceneVersion(): Int64 { return delegate.uiSceneVersion() }
    public func uiBusinessOwnerRevision(): Int64 { return ownerRevision }
    public func buildUi(): CjguiComposableUiNode { return delegate.buildUi() }
    public func applyUiEvent(e: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return delegate.applyUiEvent(e)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        return delegate.rejectUiEvent(kind, node)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return delegate.requestWindowClose()
    }
}

@When[os == "macOS"]
@Test
func ownerPaintUnchangedOwnerKeepsPaintFastPath(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = OwnerPaintFrontierController()
        let window = CjguiComposableUiWindow(controller,
            configuration: CjguiMacosApplicationWindowConfiguration(
                "CJGUI stable owner paint control", 640u32, 480u32))
        @Assert(window.start(), true)
        try {
            ownerPaintSettleOrdinaryTurn(window)
            let builds = controller.builds
            let base = window.displayedSceneVersion()
            ownerPaintAcquireDrawable(window, base + 1)
            @Assert(window.animateNodeOpacity("semantic:owner-paint-button", 0.5,
                spec: CjguiComposableUiAnimationSpec.tween(durationMs: 0), atTime: MonoTime.now()), true)
            ownerPaintResolvePendingOnly(window)
            let _ = window.refreshAfterDeferredPump()
            ownerPaintSettleOrdinaryTurn(window)
            @Assert(controller.builds, builds)
            @Assert(window.acceptedSceneNodes()[2].style.background.alpha, 0.5)
            @Assert(window.hasDeferredEventWork(), false)
        } finally { window.close() }
    })
}

@When[os == "macOS"]
@Test
func ownerPaintFullContinuationAndExternalRebindNeedNoExtraInput(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = OwnerPaintFrontierController()
        let window = CjguiComposableUiWindow(controller,
            configuration: CjguiMacosApplicationWindowConfiguration(
                "CJGUI external rebind paint control", 640u32, 480u32))
        @Assert(window.start(), true)
        try {
            ownerPaintSettleOrdinaryTurn(window)
            let base = window.displayedSceneVersion()
            controller.body = "replacement"
            controller.resource = 6202
            controller.version += 1
            window.requestRefresh()
            ownerPaintAcquireDrawable(window, base + 1)
            @Assert(window.animateNodeOpacity("semantic:owner-paint-button", 0.5,
                spec: CjguiComposableUiAnimationSpec.tween(durationMs: 0), atTime: MonoTime.now()), true)
            ownerPaintResolvePendingOnly(window)
            @Assert(window.displayedSceneVersion(), base)
            let _ = window.refreshAfterDeferredPump()
            ownerPaintSettleOrdinaryTurn(window)
            let index = ownerPaintTextIndex(window)
            @Assert(window.acceptedSceneNodes()[Int64(index)].value, "replacement")
            @Assert(window.acceptedSceneNodes()[Int64(index)].resourceId, 6202)
            @Assert(window.hasDeferredEventWork(), false)
            // Only after the replacement has accepted without another input,
            // verify that the real current proxy accepts the subsequent key.
            @Assert(window.focusAcceptedNodeById(910), true)
            ownerPaintSettleOrdinaryTurn(window)
            @Assert(unsafe { cjgui_internal_renderer_test_set_composable_selection(
                window.testSessionToken(), index, 11u32, 11u32) }, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(ownerPaintInsert(window, index, "!"), CJGUI_INTERNAL_RENDERER_OK)
            ownerPaintDrain(window, controller, "replacement!")
        } finally { window.close() }
    })
}

@When[os == "macOS"]
@Test
func ownerPaintOwnerRevisionOnlyCreatesFiniteFullDemand(): Unit {
    cjguiMacosOwnerTest({ =>
        let controller = OwnerRevisionPaintController()
        let window = CjguiComposableUiWindow(controller,
            configuration: CjguiMacosApplicationWindowConfiguration(
                "CJGUI owner revision paint control", 640u32, 480u32))
        @Assert(window.start(), true)
        try {
            ownerPaintSettleOrdinaryTurn(window)
            let builds = controller.delegate.builds
            let base = window.displayedSceneVersion()
            controller.ownerRevision += 1
            ownerPaintAcquireDrawable(window, base + 1)
            @Assert(window.animateNodeOpacity("semantic:owner-paint-button", 0.5,
                spec: CjguiComposableUiAnimationSpec.tween(durationMs: 0), atTime: MonoTime.now()), true)
            ownerPaintResolvePendingOnly(window)
            @Assert(window.displayedSceneVersion(), base)
            @Assert(window.schedulingObservation().contains("refresh=true"), true)
            let _ = window.refreshAfterDeferredPump()
            ownerPaintSettleOrdinaryTurn(window)
            @Assert(controller.delegate.builds > builds, true)
            @Assert(window.hasDeferredEventWork(), false)
        } finally { window.close() }
    })
}

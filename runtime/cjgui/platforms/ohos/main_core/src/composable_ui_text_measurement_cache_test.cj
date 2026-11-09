package cjgui

import std.collection.*

foreign {
    func cjgui_internal_renderer_test_set_composable_measurement_failures(
        session: UInt64, failureCount: UInt32): Int32
}

private class MeasurementCacheTestController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableText(9799, "cache-fixture", "Real AppKit measurement",
            CjguiComposableUiStyle(fixedWidth: 220, fixedHeight: 40))
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

private func measurementProbeLongParagraph(): String {
    let builder = StringBuilder()
    for (_ in 0..1638) { builder.append("0123456789") }
    builder.append("abcd")
    return builder.toString()
}

private func measurementProbeManyLines(): String {
    let builder = StringBuilder()
    for (_ in 0..3276) { builder.append("line\n") }
    builder.append("tail")
    return builder.toString()
}

private class LongMultilineStartupTestController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9900, "measurement-startup-root", CjguiComposableUiStyle())
        root.add(cjguiComposableMultilineTextInput(9901, "measurement-long-paragraph", "Paragraph",
            measurementProbeLongParagraph(), 9901, CjguiComposableUiStyle(fixedWidth: 540)))
        root.add(cjguiComposableMultilineTextInput(9902, "measurement-many-lines", "Lines",
            measurementProbeManyLines(), 9902, CjguiComposableUiStyle(fixedWidth: 540)))
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
func coldLongMultilineStartupOriginalRouteSynchronouslyMeasuresBothControls(): Unit {
    let window = CjguiComposableUiWindow(LongMultilineStartupTestController())
    try {
        let outcome = window.startWithOutcome()
        let failed = match (outcome) {
            case StartFailed => true
            case _ => false
        }
        @Assert(failed, false)
        // One 16 KiB unbroken paragraph and a same-byte-count newline control
        // both traverse the actual AppKit multiline natural-height FFI when no
        // prepared candidate owns the call.
        @Assert(window.testNativeMeasurementCallCount() >= 2, true)
    } finally { window.close() }
}

@Test
func coldLongMultilineStartupMustYieldIntoPreparedCandidate(): Unit {
    let window = CjguiComposableUiWindow(LongMultilineStartupTestController())
    let budget = CjguiOwnerTurnBudget()
    window.useOwnerTurnBudget(budget)
    try {
        // RED before the startup turn is routed through the existing candidate:
        // `startWithOutcome` currently runs with an inactive shared budget and
        // reaches the synchronous TextKit call above.
        let outcome = window.startWithOutcome()
        let preparing = match (outcome) {
            case StartPreparing => true
            case _ => false
        }
        @Assert(preparing, true)
        @Assert(window.testNativeMeasurementCallCount(), 0)
        @Assert(window.isStartingPreparing(), true)
        @Assert(window.windowProgress().presentationState, "unavailable")
        // Renderer/bootstrap startup may consume the full 16 ms allowance
        // before projection admission. Keep that initial surface explicitly
        // Preparing, then let the ordinary next owner turns advance it.
        var turn: Int64 = 0
        while (window.testStaticLayoutWorkerStartCount() == 0 && turn < 4) {
            @Assert(budget.begin(), true)
            try {
                let _ = window.refreshIfNeeded()
            } finally {
                budget.end()
            }
            turn += 1
        }
        @Assert(window.testStaticLayoutWorkerStartCount() > 0, true)
        @Assert(window.testNativeMeasurementCallCount(), 0)
    } finally { budget.end(); window.close() }
}

@Test
func preparedStaticOrdinaryTextColdParagraphMustYieldBeforeNativeMeasurement(): Unit {
    let window = CjguiComposableUiWindow(MeasurementCacheTestController())
    let budget = CjguiOwnerTurnBudget()
    try {
        @Assert(window.start(), true)
        let base = CjguiInternalRendererTextMeasurer(window.testSessionToken())
        let prepared = CjguiPreparedStaticTextMeasurer(base, budget)
        let text = measurementProbeLongParagraph()
        @Assert(text.size, 16384)
        let style = CjguiComposableUiStyle(fontSize: 14.0)
        @Assert(budget.begin(), true)
        base.beginMeasurementPass()
        var yielded = false
        try { let _ = prepared.measure(text, style, 320) }
        catch (_: CjguiLayoutMeasurementNeedWorker) { yielded = true }
        // A cold ordinary TEXT request must leave through the private worker
        // admission path before CString conversion or synchronous AppKit FFI.
        @Assert(base.measurementPassNativeCallCount(), 0)
        @Assert(yielded, true)
        prepared.release()
    } finally { budget.end(); window.close() }
}

@Test
func preparedStaticOrdinaryTextColdNewlineControlMustYieldBeforeNativeMeasurement(): Unit {
    let window = CjguiComposableUiWindow(MeasurementCacheTestController())
    let budget = CjguiOwnerTurnBudget()
    try {
        @Assert(window.start(), true)
        let base = CjguiInternalRendererTextMeasurer(window.testSessionToken())
        let prepared = CjguiPreparedStaticTextMeasurer(base, budget)
        let text = measurementProbeManyLines()
        @Assert(text.size, 16384)
        @Assert(text.size, measurementProbeLongParagraph().size)
        let style = CjguiComposableUiStyle(fontSize: 14.0)
        @Assert(budget.begin(), true)
        base.beginMeasurementPass()
        var yielded = false
        try { let _ = prepared.measure(text, style, 320) }
        catch (_: CjguiLayoutMeasurementNeedWorker) { yielded = true }
        @Assert(base.measurementPassNativeCallCount(), 0)
        @Assert(yielded, true)
        prepared.release()
    } finally { budget.end(); window.close() }
}

@Test
func asyncMultilineJobIdentityAndCancellationAreBounded(): Unit {
    let style = CjguiComposableUiStyle(fontSize: 14.0)
    let changedStyle = CjguiComposableUiStyle(fontSize: 15.0)
    let (status, maybeJob) = beginCjguiAsyncMultilineHeight(
        measurementProbeLongParagraph(), style, 540)
    @Assert(status, CJGUI_ASYNC_MEASURE_STARTED)
    @Assert(maybeJob.isSome(), true)
    let job = match (maybeJob) {
        case Some(value) => value
        case None => return
    }
    @Assert(job.matches(measurementProbeLongParagraph(), style, 540), true)
    @Assert(job.matches(measurementProbeLongParagraph(), changedStyle, 540), false)
    @Assert(job.matches(measurementProbeLongParagraph(), style, 539), false)
    // Releasing the candidate-owned handle cancels adoption and makes this
    // Cangjie identity unusable immediately. Native tests separately verify
    // that the slot and retained resources live until worker cleanup.
    job.release(false)
    let (releasedStatus, _, _) = job.poll()
    @Assert(releasedStatus, CJGUI_ASYNC_MEASURE_STALE_HANDLE)
    job.release(true)
    let (stillReleasedStatus, _, _) = job.poll()
    @Assert(stillReleasedStatus, CJGUI_ASYNC_MEASURE_STALE_HANDLE)
}

@Test
func asyncTextMetricsJobIdentityAndCancellationAreBounded(): Unit {
    let style = CjguiComposableUiStyle(fontSize: 14.0)
    let changedStyle = CjguiComposableUiStyle(fontSize: 15.0)
    let value = measurementProbeLongParagraph()
    let (status, maybeJob) = beginCjguiAsyncTextMetrics(value, style, 320)
    @Assert(status, CJGUI_ASYNC_MEASURE_STARTED)
    @Assert(maybeJob.isSome(), true)
    let job = match (maybeJob) {
        case Some(value) => value
        case None => return
    }
    @Assert(job.matches(value, style, 320), true)
    @Assert(job.matches(value, changedStyle, 320), false)
    @Assert(job.matches(value, style, 319), false)
    @Assert(job.matches(value + "x", style, 320), false)
    job.release(false)
    let (releasedStatus, _, _) = job.poll()
    @Assert(releasedStatus, CJGUI_ASYNC_MEASURE_STALE_HANDLE)
    job.release(true)
    let (stillReleasedStatus, _, _) = job.poll()
    @Assert(stillReleasedStatus, CJGUI_ASYNC_MEASURE_STALE_HANDLE)
}

@Test
func preparedTextMetricsReusesACompletedCandidateOnlyInItsEnvironment(): Unit {
    let window = CjguiComposableUiWindow(MeasurementCacheTestController())
    let budget = CjguiOwnerTurnBudget()
    try {
        @Assert(window.start(), true)
        let base = CjguiInternalRendererTextMeasurer(window.testSessionToken())
        let style = CjguiComposableUiStyle(fontSize: 14.0)
        let value = measurementProbeLongParagraph()
        let originalEnvironment = base.layoutMeasurementEnvironmentKey()
        let firstCandidate = CjguiPreparedStaticTextMeasurer(base, budget)
        @Assert(budget.begin(), true)
        base.beginMeasurementPass()
        var yielded = false
        try { let _ = firstCandidate.measure(value, style, 320) }
        catch (_: CjguiLayoutMeasurementNeedWorker) { yielded = true }
        @Assert(yielded, true)
        @Assert(firstCandidate.workerStartCount(), 1)
        @Assert(base.measurementPassNativeCallCount(), 0)

        var ready = false
        var pollCount: Int64 = 0
        while (!ready && pollCount < 100000) {
            ready = firstCandidate.pollPendingMultiline()
            pollCount += 1
        }
        @Assert(ready, true)
        let firstResult = firstCandidate.measure(value, style, 320)
        @Assert(firstCandidate.pinCount(), 1)
        @Assert(base.measurementPassNativeCallCount(), 0)

        // A fresh selection/layout candidate in the same font/viewport
        // environment receives the exact four-scalar LRU result. It does not
        // submit another job or re-enter synchronous AppKit measurement.
        let nextCandidate = CjguiPreparedStaticTextMeasurer(base, budget)
        base.beginMeasurementPass()
        let nextResult = nextCandidate.measure(value, style, 320)
        @Assert(nextCandidate.workerStartCount(), 0)
        @Assert(base.measurementPassNativeCallCount(), 0)
        @Assert(nextResult.width, firstResult.width)
        @Assert(nextResult.height, firstResult.height)
        @Assert(nextResult.lineHeight, firstResult.lineHeight)
        @Assert(nextResult.baseline, firstResult.baseline)

        base.useMeasurementEnvironment(7u64)
        @Assert(base.layoutMeasurementEnvironmentKey() == originalEnvironment, false)
        @Assert(base.retainPreparedMeasurement(value, style, 320, 0, firstResult, originalEnvironment), false)
        @Assert(base.measurementCacheEntryCount(), 0)
        let changedEnvironmentCandidate = CjguiPreparedStaticTextMeasurer(base, budget)
        base.beginMeasurementPass()
        yielded = false
        try { let _ = changedEnvironmentCandidate.measure(value, style, 320) }
        catch (_: CjguiLayoutMeasurementNeedWorker) { yielded = true }
        @Assert(yielded, true)
        @Assert(changedEnvironmentCandidate.workerStartCount(), 1)
        @Assert(base.measurementPassNativeCallCount(), 0)
        changedEnvironmentCandidate.release()
        firstCandidate.release()
        nextCandidate.release()
    } finally { budget.end(); window.close() }
}

@Test
func asyncMultilineOversizeJobStopsBeforeNativeCapacity(): Unit {
    let builder = StringBuilder()
    for (_ in 0..13107) { builder.append("0123456789") }
    builder.append("xyz")
    let oversize = builder.toString()
    @Assert(oversize.size, 131073)
    let style = CjguiComposableUiStyle(fontSize: 14.0)
    let (status, job) = beginCjguiAsyncMultilineHeight(oversize, style, 540)
    @Assert(status, CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT)
    @Assert(job.isNone(), true)
}

@Test
func measurementCacheOverflowKeepsRecentlyUsedRealMetrics(): Unit {
    let window = CjguiComposableUiWindow(MeasurementCacheTestController())
    try {
        @Assert(window.start(), true)
        let measurer = CjguiInternalRendererTextMeasurer(window.testSessionToken())
        let style = CjguiComposableUiStyle(fontSize: 14.0)
        let body = "Recent 🙂 仓颉 cache entry"
        let original = measurer.measure(body, style, 160)
        for (index in 0..127) {
            let _ = measurer.measure("unique metric ${index}", style, 160)
        }
        // Exactly 128 distinct successful queries, then make the earliest
        // entry hot before adding the one query that exceeds the fixed cap.
        let _ = measurer.measure(body, style, 160)
        let _ = measurer.measure("one overflow query", style, 160)
        measurer.beginMeasurementPass()
        let reused = measurer.measure(body, style, 160)
        @Assert(reused.width, original.width)
        @Assert(reused.height, original.height)
        @Assert(reused.lineHeight, original.lineHeight)
        @Assert(reused.baseline, original.baseline)
        @Assert(measurer.measurementStatus(), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(measurer.measurementPassNativeCallCount(), 0)
    } finally { window.close() }
}

@Test
func measurementCacheInputsAndFailedQueryRemainDistinct(): Unit {
    let window = CjguiComposableUiWindow(MeasurementCacheTestController())
    try {
        @Assert(window.start(), true)
        let measurer = CjguiInternalRendererTextMeasurer(window.testSessionToken())
        let style = CjguiComposableUiStyle(fontSize: 14.0)
        let body = "Real 🙂 仓颉 measured text"
        let _ = measurer.measure(body, style, 160)
        measurer.beginMeasurementPass()
        let _ = measurer.measure(body, style, 160)
        @Assert(measurer.measurementPassNativeCallCount(), 0)
        let _ = measurer.measure(body, style, 80)
        let _ = measurer.measure(body, CjguiComposableUiStyle(fontSize: 15.0), 160)
        let _ = measurer.measure(body, CjguiComposableUiStyle(fontSize: 14.0, fontWeight: 700), 160)
        let _ = measurer.measure(body, CjguiComposableUiStyle(fontSize: 14.0, fontFamily: "monospaced"), 160)
        let natural = measurer.multilineNaturalContentHeight(body, style, 160)
        @Assert(natural.isSome(), true)
        @Assert(measurer.measurementPassNativeCallCount(), 5)
        let actualSecondMeasurer = CjguiInternalRendererTextMeasurer(window.testSessionToken())
        let _ = actualSecondMeasurer.measure(body, style, 160)
        @Assert(actualSecondMeasurer.measurementPassNativeCallCount(), 1)
        @Assert(unsafe { cjgui_internal_renderer_test_set_composable_measurement_failures(
            window.testSessionToken(), 1u32) }, CJGUI_INTERNAL_RENDERER_OK)
        let _ = measurer.measure("uncached failure query", style, 160)
        @Assert(measurer.measurementStatus() != CJGUI_INTERNAL_RENDERER_OK, true)
        measurer.beginMeasurementPass()
        let _ = measurer.measure("uncached failure query", style, 160)
        @Assert(measurer.measurementStatus(), CJGUI_INTERNAL_RENDERER_OK)
        @Assert(measurer.measurementPassNativeCallCount(), 1)
        measurer.beginMeasurementPass()
        let _ = measurer.measure("uncached failure query", style, 160)
        @Assert(measurer.measurementPassNativeCallCount(), 0)
    } finally { window.close() }
}

@Test
func measurementCacheStaysBoundedAndColdOverflowIsMeasured(): Unit {
    let window = CjguiComposableUiWindow(MeasurementCacheTestController())
    try {
        @Assert(window.start(), true)
        let measurer = CjguiInternalRendererTextMeasurer(window.testSessionToken())
        let style = CjguiComposableUiStyle(fontSize: 14.0)
        for (index in 0..500) {
            let _ = measurer.measure("bounded actual metric ${index}", style, 160)
            @Assert(measurer.measurementCacheEntryCount() <= 128, true)
        }
        @Assert(measurer.measurementCacheEntryCount(), 128)
        measurer.beginMeasurementPass()
        for (index in 372..500) { let _ = measurer.measure("bounded actual metric ${index}", style, 160) }
        @Assert(measurer.measurementPassNativeCallCount(), 0)
        @Assert(measurer.measurementPassCacheHitCount(), 128)
        // A genuinely new key still performs real native work, and admits
        // one eviction. Reusing LRU is not a proof that cold work is free.
        let _ = measurer.measure("genuinely cold next metric", style, 160)
        @Assert(measurer.measurementPassNativeCallCount(), 1)
        @Assert(measurer.measurementPassCacheEvictionCount(), 1)
        @Assert(measurer.measurementCacheEntryCount(), 128)
    } finally { window.close() }
}

@Test
func measurementPinsKeepOldLruHitsAndStickyRealFailure(): Unit {
    let window = CjguiComposableUiWindow(MeasurementCacheTestController())
    let budget = CjguiOwnerTurnBudget()
    try {
        @Assert(window.start(), true)
        let base = CjguiInternalRendererTextMeasurer(window.testSessionToken())
        let style = CjguiComposableUiStyle(fontSize: 14.0)
        let text = "previous successful LRU result 🙂"
        let original = base.measure(text, style, 160)
        let pins = CjguiPreparedStaticTextMeasurer(base, budget)
        base.beginMeasurementPass()
        let cached = pins.measure(text, style, 160)
        @Assert(base.measurementPassNativeCallCount(), 0)
        @Assert(pins.pinCount(), 1)
        for (index in 0..140) { let _ = pins.measure("pin-pressure-${index}", style, 160) }
        @Assert(pins.pinCount(), 141)
        base.beginMeasurementPass()
        let reused = pins.measure(text, style, 160)
        @Assert(base.measurementPassNativeCallCount(), 0)
        @Assert(reused.width, original.width)
        @Assert(reused.height, cached.height)
        @Assert(reused.lineHeight, original.lineHeight)
        @Assert(reused.baseline, original.baseline)
        @Assert(unsafe { cjgui_internal_renderer_test_set_composable_measurement_failures(
            window.testSessionToken(), 1u32) }, CJGUI_INTERNAL_RENDERER_OK)
        var failed = false
        try { let _ = pins.measure("actual native failure", style, 160) }
        catch (error: CjguiLayoutPreparationFailure) {
            failed = true
            @Assert(error.message, "layout_native_measurement_failed")
        }
        @Assert(failed, true)
        @Assert(pins.pinCount(), 141)
        base.beginMeasurementPass()
        failed = false
        try { let _ = pins.measure(text, style, 160) }
        catch (_: CjguiLayoutPreparationFailure) { failed = true }
        @Assert(failed, true)
        @Assert(base.measurementPassNativeCallCount(), 0)
        pins.release()
        @Assert(pins.pinCount(), 0)
        @Assert(pins.retainedKeyBytes(), 0)
    } finally { budget.end(); window.close() }
}

@Test
func measurementPinsHaveBoundedKeysAndRetireChangedEnvironment(): Unit {
    let window = CjguiComposableUiWindow(MeasurementCacheTestController())
    let budget = CjguiOwnerTurnBudget()
    try {
        @Assert(window.start(), true)
        let base = CjguiInternalRendererTextMeasurer(window.testSessionToken())
        let style = CjguiComposableUiStyle(fontSize: 14.0)
        let bounded = CjguiPreparedStaticTextMeasurer(base, budget, maximumEntries: 2, maximumBytes: 512)
        let _ = bounded.measure("first actual result", style, 160)
        let _ = bounded.measure("second actual result", style, 160)
        var failed = false
        try { let _ = bounded.measure("third actual key", style, 160) }
        catch (error: CjguiLayoutPreparationFailure) {
            failed = true
            @Assert(error.message, "layout_measurement_pin_capacity")
        }
        @Assert(failed, true)
        @Assert(bounded.pinCount(), 2)
        @Assert(bounded.retainedKeyBytes() <= 512, true)
        let environment = CjguiPreparedStaticTextMeasurer(base, budget)
        let _ = environment.measure("environment-bound real result", style, 160)
        // Controlled generation change tests private invalidation transport;
        // normal windows supply only the actual native viewport generation.
        base.useMeasurementEnvironment(7u64)
        base.beginMeasurementPass()
        failed = false
        try { let _ = environment.measure("environment-bound real result", style, 160) }
        catch (error: CjguiLayoutPreparationFailure) {
            failed = true
            @Assert(error.message, "layout_measurement_environment_changed")
        }
        @Assert(failed, true)
        @Assert(base.measurementPassNativeCallCount(), 0)
    } finally { budget.end(); window.close() }
}

private class StaticSliceClock { var base: Int64 = 0; var spent: Bool = false }

private class YieldAfterViewportMeasurer <: CjguiComposableUiTextMeasurer &
    CjguiComposableUiMultilineNaturalHeightMeasurer & CjguiComposableUiLayoutMeasurementEnvironment &
    CjguiComposableUiLayoutPacer {
    let pins: CjguiPreparedStaticTextMeasurer
    let viewport: CjguiComposableUiScrollViewport
    let clock: StaticSliceClock
    var trigger: Bool = true
    init(pins: CjguiPreparedStaticTextMeasurer, viewport: CjguiComposableUiScrollViewport, clock: StaticSliceClock) {
        this.pins = pins; this.viewport = viewport; this.clock = clock
    }
    public func layoutMeasurementEnvironmentKey(): String { return pins.layoutMeasurementEnvironmentKey() }
    public func checkpointLayoutSlice(): Unit {
        if (trigger && viewport.hasStagedExtents()) { clock.spent = true }
        pins.checkpointLayoutSlice()
    }
    public func measure(value: String, style: CjguiComposableUiStyle, width: Int64): CjguiComposableUiTextMeasurement {
        checkpointLayoutSlice(); return pins.measure(value, style, width)
    }
    public func multilineNaturalContentHeight(value: String, style: CjguiComposableUiStyle, width: Int64): ?Int64 {
        checkpointLayoutSlice(); return pins.multilineNaturalContentHeight(value, style, width)
    }
}

@Test
func measurementSliceYieldDiscardsOnlyTouchedViewportAndMatchesCanonicalGeometry(): Unit {
    let window = CjguiComposableUiWindow(MeasurementCacheTestController())
    let budget = CjguiOwnerTurnBudget()
    let first = CjguiComposableUiScrollViewport()
    let second = CjguiComposableUiScrollViewport()
    try {
        @Assert(window.start(), true)
        let base = CjguiInternalRendererTextMeasurer(window.testSessionToken())
        let root = cjguiComposableVertical(9780, "slice-root", CjguiComposableUiStyle())
        for ((node, state) in [(9781, first), (9783, second)]) {
            let scroll = cjguiComposableScrollArea(node, "slice-scroll-${node}", state,
                CjguiComposableUiStyle(fixedWidth: 260, fixedHeight: 40, padding: 2, clipsContent: true))
            scroll.add(cjguiComposableText(node + 1, "slice-text-${node}", "one 🙂\ntwo 仓颉\nthree\nfour",
                CjguiComposableUiStyle(fontSize: 14.0, offsetX: 3)))
            root.add(scroll)
        }
        let bounds = CjguiComposableUiRect(0, 0, 280, 140)
        let baseline = CjguiComposableUiLayoutEngine.layoutWithMetrics(root.cloneForWindowCandidate(), bounds, 1, base)
        for (view in baseline.viewports) { view.commitStagedExtents() }
        let extent = first.contentExtent()
        let acceptedOffset = first.acceptedOffset()
        let _ = first.requestOffset(5)
        let generation = first.requestGeneration()
        let clock = StaticSliceClock()
        clock.base = Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })
        budget.testUseClock({ => clock.base + if (clock.spent) { 15500000 } else { 0 } })
        let pins = CjguiPreparedStaticTextMeasurer(base, budget)
        let sliced = YieldAfterViewportMeasurer(pins, first, clock)
        let reuse = CjguiComposableUiLayoutReuseCache()
        @Assert(budget.begin(), true)
        var yielded = false
        try {
            let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(root.cloneForWindowCandidate(), bounds, 2,
                sliced, reuseCache: reuse, commitReusePass: false)
        } catch (_: CjguiLayoutMeasurementNeedBudget) { yielded = true }
        budget.end()
        @Assert(yielded, true)
        @Assert(first.hasStagedExtents(), false)
        @Assert(second.hasStagedExtents(), false)
        @Assert(first.contentExtent(), extent)
        @Assert(first.acceptedOffset(), acceptedOffset)
        @Assert(first.requestGeneration(), generation)
        sliced.trigger = false
        budget.testUseClock({ => Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() }) })
        @Assert(budget.begin(), true)
        let resumed = CjguiComposableUiLayoutEngine.layoutWithMetrics(root.cloneForWindowCandidate(), bounds, 2,
            sliced, reuseCache: reuse, commitReusePass: false)
        budget.end()
        let reference = CjguiComposableUiLayoutEngine.layoutWithMetrics(root.cloneForWindowCandidate(), bounds, 2,
            CjguiInternalRendererTextMeasurer(window.testSessionToken()), reuseMeasurements: false)
        @Assert(resumed.scene.isValid(), true)
        @Assert(reference.scene.isValid(), true)
        let actualNodes = resumed.scene.nodes()
        let expectedNodes = reference.scene.nodes()
        @Assert(actualNodes.size, expectedNodes.size)
        for (index in 0..actualNodes.size) {
            let a = actualNodes[index]; let b = expectedNodes[index]
            @Assert(a.nodeId, b.nodeId); @Assert(a.semanticId, b.semanticId); @Assert(a.value, b.value)
            @Assert(a.bounds.x, b.bounds.x); @Assert(a.bounds.y, b.bounds.y)
            @Assert(a.bounds.width, b.bounds.width); @Assert(a.bounds.height, b.bounds.height)
            @Assert(a.clip.x, b.clip.x); @Assert(a.clip.y, b.clip.y)
            @Assert(a.clip.width, b.clip.width); @Assert(a.clip.height, b.clip.height)
        }
    } finally {
        budget.end(); first.discardStagedExtents(); second.discardStagedExtents(); window.close()
    }
}

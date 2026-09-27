// Two-window workload probe (stage B2).
//
// Fair double-window response evidence: B's edit is enqueued through the real
// TextKit input pipeline BEFORE A's heavy turn starts, and the probe records
// monotonic enqueue/owner/accepted timestamps for every sample. Twenty raw
// samples per workload feed nearest-rank p50/p95/max against the stage budget
// (queue->owner p95 <= 100ms, queue->accepted p95 <= 150ms). Marked head/mid/
// tail sentinels in the long body verify scrolled content correctness beyond
// non-zero alpha.
package cjgui

import std.collection.*
import std.time.*

foreign {
    func cjgui_internal_renderer_test_composable_text_resource_stats(
        session: UInt64, nodeIndex: UInt32, outByteCount: CPointer<UInt64>,
        outX: CPointer<Float32>, outY: CPointer<Float32>,
        outWidth: CPointer<Float32>, outHeight: CPointer<Float32>
    ): Int32
    func cjgui_internal_renderer_test_edit_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString
    ): Int32
    func cjgui_internal_renderer_test_activate_composable_point(
        session: UInt64, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_scroll_composable_multiline(
        session: UInt64, deltaY: Float32, outScrollOffset: CPointer<Float32>,
        outVisibleGlyphCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_composable_multiline_viewport(
        session: UInt64, marker: CString, outScrollOffset: CPointer<Float32>,
        outMaximumOffset: CPointer<Float32>, outVisibleCharacterStart: CPointer<UInt32>,
        outVisibleCharacterLength: CPointer<UInt32>, outProjectionVersion: CPointer<UInt64>,
        outMarkerFullyVisible: CPointer<Int32>
    ): Int32
    func cjgui_internal_renderer_test_resize_composable_window(
        session: UInt64, outResizeVersion: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_work_stats(
        session: UInt64, outRasterCount: CPointer<UInt64>, outRasterBytes: CPointer<UInt64>,
        outRasterMicros: CPointer<UInt64>, outUploadCount: CPointer<UInt64>,
        outUploadBytes: CPointer<UInt64>, outUploadMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_projection_timing_stats(
        session: UInt64, outAccessibilityMicros: CPointer<UInt64>,
        outInputMicros: CPointer<UInt64>, outRefreshMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_substage_stats(
        session: UInt64, outDecorationsMicros: CPointer<UInt64>,
        outKeyConstructionMicros: CPointer<UInt64>, outPreparationMicros: CPointer<UInt64>,
        outFallbackMicros: CPointer<UInt64>, outFallbackApplyCount: CPointer<UInt64>,
        outFallbackCharacters: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_tile_alpha_pixels(
        session: UInt64, nodeIndex: UInt32, tileIndex: UInt32,
        outNonzeroAlphaPixels: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_tile_stats(
        session: UInt64, nodeIndex: UInt32, tileIndex: UInt32,
        outTileCount: CPointer<UInt32>, outTileBytes: CPointer<UInt64>,
        outX: CPointer<Float32>, outY: CPointer<Float32>,
        outWidth: CPointer<Float32>, outHeight: CPointer<Float32>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_content_size(
        session: UInt64, width: UInt32, height: UInt32,
        outActualWidth: CPointer<UInt32>, outActualHeight: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_arm_midwork_composable_event(
        sourceSession: UInt64, targetSession: UInt64, targetNodeIndex: UInt32,
        eventKind: UInt32, text: CString, delayMicros: UInt32
    ): Int32
    func cjgui_internal_renderer_test_midwork_composable_event_timing(
        sourceSession: UInt64, outAStartMicros: CPointer<UInt64>, outAEndMicros: CPointer<UInt64>,
        outProducerReadyMicros: CPointer<UInt64>, outProducerPostMicros: CPointer<UInt64>,
        outNativeEnqueueMicros: CPointer<UInt64>, outEnqueueStatus: CPointer<Int32>
    ): Int32
    func cjgui_internal_renderer_test_monotonic_micros(outMicros: CPointer<UInt64>): Int32
}

/// A long body with unique, findable markers at head/mid/tail so scrolled
/// content can be checked for real content identity, not just glyph counts.
private func markedLongText(lines: Int64): String {
    var builder = StringBuilder()
    var index: Int64 = 0
    let row = "负载正文行 观微 😀 0123456789 "
    let mid = lines / 2
    while (index < lines) {
        builder.append(row)
        if (index == 0) { builder.append("头部标记XYZ") }
        if (index == mid) { builder.append("中部标记ABC") }
        if (index == lines - 1) { builder.append("尾部标记QWE") }
        builder.append("\n")
        index += 1
    }
    return builder.toString()
}

private func utf16Units(value: String): Int64 {
    var count: Int64 = 0
    for (scalar in value.runes()) {
        count += if (UInt32(scalar) > 0xffffu32) { 2 } else { 1 }
    }
    return count
}

private class MarkedViewportSample {
    let status: Int32
    let offset: Float32
    let maximum: Float32
    let characterStart: UInt32
    let characterLength: UInt32
    let projectionVersion: UInt64
    let markerVisible: Bool
    init(status: Int32, offset: Float32, maximum: Float32, characterStart: UInt32,
        characterLength: UInt32, projectionVersion: UInt64, markerVisible: Bool) {
        this.status = status
        this.offset = offset
        this.maximum = maximum
        this.characterStart = characterStart
        this.characterLength = characterLength
        this.projectionVersion = projectionVersion
        this.markerVisible = markerVisible
    }
}

private func readMarkedViewport(window: CjguiComposableUiWindow, marker: String): MarkedViewportSample {
    var offset: Float32 = 0.0f32
    var maximum: Float32 = -1.0f32
    var start: UInt32 = 0u32
    var length: UInt32 = 0u32
    var version: UInt64 = 0u64
    var visible: Int32 = 0
    var status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    let nativeMarker = unsafe { LibC.mallocCString(marker) }
    try (markerResource = nativeMarker.asResource()) {
        status = unsafe { cjgui_internal_renderer_test_composable_multiline_viewport(
            window.testSessionToken(), markerResource.value, inout offset, inout maximum,
            inout start, inout length, inout version, inout visible) }
    }
    return MarkedViewportSample(status, offset, maximum, start, length, version, visible != 0)
}

/// Window A: the heavy long-text workload. `updateText` changes the body so a
/// hot content turn must really re-prepare the (now smaller) visible work.
private class HeavyMarkedController <: CjguiComposableUiController {
    var text: String = markedLongText(3000)
    var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableMultilineTextInput(61, "heavy-marked", "", text, 61,
            CjguiComposableUiStyle(growX: 1, growY: 1,
                textColor: CjguiComposableUiColor(0.92, 0.95, 1.0, 1.0)))
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 61) {
            text = event.text
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
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
    public func updateText(): Unit {
        text = markedLongText(3000) + "变体${revision}"
        revision += 1
    }
}

/// Window B: a small responsive input. The controller records the monotonic
/// time its applyUiEvent really consumed each unique value (t_owner): the
/// hook fires at the actual application point inside the controller, not at a
/// coarse probe poll, so owner latency is a direct measurement. External
/// observation remains an upper bound only for the accepted-scene sample.
private class ResponsiveMarkedController <: CjguiComposableUiController {
    var value: String = "B初始"
    var revision: Int64 = 1
    // Raw MonoTime.now() at the moment the unique sample was really applied;
    // 0 means "not applied yet". The probe converts it against its own clock.
    var ownerHooked: Bool = false
    var lastOwnerRawMono: MonoTime = MonoTime.now()
    var lastOwnerText: String = ""
    var lastOwnerNativeMicros: UInt64 = 0u64
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableTextInput(71, "responsive-marked", "B字段", value, 71,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 38,
                textColor: CjguiComposableUiColor(0.92, 0.95, 1.0, 1.0)))
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 71) {
            value = event.text
            revision += 1
            ownerHooked = true
            lastOwnerRawMono = MonoTime.now()
            var ownerNativeMicros: UInt64 = 0u64
            let _ = unsafe { cjgui_internal_renderer_test_monotonic_micros(inout ownerNativeMicros) }
            lastOwnerNativeMicros = ownerNativeMicros
            lastOwnerText = event.text
            return CjguiComposableUiDispatchResult(true)
        }
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
    public func ownerValue(): String { return value }
    public func resetOwnerHook(): Unit {
        ownerHooked = false
        lastOwnerText = ""
        lastOwnerNativeMicros = 0u64
    }
}

private func editB(window: CjguiComposableUiWindow, text: String): Int32 {
    let nativeText = unsafe { LibC.mallocCString(text) }
    var status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeText.asResource()) {
        status = unsafe { cjgui_internal_renderer_test_edit_composable_text(
            window.testSessionToken(), 0u32, textResource.value) }
    }
    return status
}

private func sortedCopy(values: ArrayList<Int64>): Array<Int64> {
    let copy = values.toArray()
    // Insertion sort: twenty values, no dependency needed.
    var index: Int64 = 1
    while (index < copy.size) {
        var probe: Int64 = index
        while (probe > 0 && copy[probe - 1] > copy[probe]) {
            let temp = copy[probe - 1]
            copy[probe - 1] = copy[probe]
            copy[probe] = temp
            probe -= 1
        }
        index += 1
    }
    return copy
}

private func percentile(sorted: Array<Int64>, rank: Int64): Int64 {
    if (sorted.size == 0) { return 0 }
    var index = rank - 1
    if (index < 0) { index = 0 }
    if (index >= sorted.size) { index = sorted.size - 1 }
    return sorted[index]
}

private func runWorkload(windowA: CjguiComposableUiWindow, windowB: CjguiComposableUiWindow,
    heavy: HeavyMarkedController, responsive: ResponsiveMarkedController,
    application: CjguiMacosApplication, samples: Int64, ordinal: Int64, permissive: Bool,
    enforceBudget: Bool): Bool {
    let enqueueMillis = ArrayList<Int64>()
    let ownerMillis = ArrayList<Int64>()
    let acceptedMillis = ArrayList<Int64>()
    var allApplied = true
    var sample: Int64 = 0
    while (sample < samples) {
        let unique = "B样本${ordinal}-${sample} 😀"
        var ownerAt: Int64 = -1
        var acceptedAt: Int64 = -1
        var ownerTurn: Int64 = -1
        var acceptedTurn: Int64 = -1
        responsive.resetOwnerHook()
        // t_enqueue: the edit enters B's real input pipeline first.
        let enqueueStarted = MonoTime.now()
        let enqueueStatus = editB(windowB, unique)
        let enqueueDone = MonoTime.now()
        let enqueueMs = (enqueueDone - enqueueStarted).toMilliseconds()
        // Owner hook may have fired synchronously inside the edit itself.
        if (responsive.ownerHooked && responsive.lastOwnerText == unique) {
            ownerAt = (responsive.lastOwnerRawMono - enqueueDone).toMilliseconds()
            ownerTurn = 0
        }
        var turn: Int64 = 0
        // Sample accepted immediately after every pump return so a first-turn
        // completion is never attributed to later work.
        func sampleAfterPump(): Unit {
            let now = (MonoTime.now() - enqueueDone).toMilliseconds()
            if (ownerAt < 0 && responsive.ownerHooked &&
                responsive.lastOwnerText == unique) {
                ownerAt = (responsive.lastOwnerRawMono - enqueueDone).toMilliseconds()
                ownerTurn = turn
            }
            if (acceptedAt < 0 && windowB.acceptedSceneNodes().size > 0 &&
                windowB.acceptedSceneNodes()[0].value == unique) {
                acceptedAt = now
                acceptedTurn = turn
            }
        }
        // Heavy workload on A starts AFTER B is enqueued. Permissive turns
        // mirror a real application: ONE heavy operation per event-loop turn,
        // so B's queued edit is served at the next real turn boundary. Strict
        // mode runs all three back-to-back and reports the worst case.
        let heavyStarted = MonoTime.now()
        var resizeVersion: UInt64 = 0u64
        let resizeStatus = unsafe { cjgui_internal_renderer_test_resize_composable_window(
            windowA.testSessionToken(), inout resizeVersion) }
        let resizeDone = MonoTime.now()
        let syncRefreshStarted = MonoTime.now()
        let _ = windowA.refresh()
        let syncRefreshDone = MonoTime.now()
        if (permissive) {
            turn += 1
            let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
            sampleAfterPump()
        }
        var offset: Float32 = 0.0f32
        var glyphs: UInt32 = 0u32
        let scrollStarted = MonoTime.now()
        let scrollStatus = unsafe { cjgui_internal_renderer_test_scroll_composable_multiline(
            windowA.testSessionToken(), -160.0f32, inout offset, inout glyphs) }
        let scrollDone = MonoTime.now()
        if (permissive) {
            turn += 1
            let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
            sampleAfterPump()
        }
        let ownerRefreshStarted = MonoTime.now()
        heavy.updateText()
        let _ = windowA.refresh()
        let ownerRefreshDone = MonoTime.now()
        if (permissive) {
            turn += 1
            let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
            sampleAfterPump()
        }
        let heavyEnded = MonoTime.now()
        // Serve the normal application loop until B's owner and accepted
        // scene both show the unique value; the hook keeps owner at its real
        // application point while accepted sampling stays per-pump.
        while (turn < 200) {
            turn += 1
            let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
            sampleAfterPump()
            if (ownerAt >= 0 && acceptedAt >= 0) { break }
        }
        let heavyMs = (heavyEnded - heavyStarted).toMilliseconds()
        if (enqueueStatus != CJGUI_INTERNAL_RENDERER_OK || resizeStatus != CJGUI_INTERNAL_RENDERER_OK ||
            scrollStatus != CJGUI_INTERNAL_RENDERER_OK || ownerAt < 0 || acceptedAt < 0) {
            allApplied = false
            println("CJGUI_TWO_WINDOW_WORKLOAD sample_failed ordinal=${ordinal} sample=${sample} " +
                "enqueue=${enqueueStatus} resize=${resizeStatus} scroll=${scrollStatus} " +
                "owner_at=${ownerAt} accepted_at=${acceptedAt}")
        }
        // Per-sample raw row: enqueue cost, heavy span, and the calibrated
        // owner (hook = actual application point) plus accepted (immediate
        // post-pump sample; an upper bound at pump granularity) with the turn
        // each landed in. All statistics derive from these raw rows.
        println("CJGUI_TWO_WINDOW_SAMPLE ordinal=${ordinal} sample=${sample} " +
            "enqueue_ms=${enqueueMs} heavy_ms=${heavyMs} " +
            "resize_ms=${(resizeDone - heavyStarted).toMilliseconds()} " +
            "sync_refresh_ms=${(syncRefreshDone - syncRefreshStarted).toMilliseconds()} " +
            "native_scroll_ms=${(scrollDone - scrollStarted).toMilliseconds()} " +
            "owner_refresh_ms=${(ownerRefreshDone - ownerRefreshStarted).toMilliseconds()} " +
            "owner_ms=${ownerAt + enqueueMs} accepted_ms=${acceptedAt + enqueueMs} " +
            "owner_turn=${ownerTurn} accepted_turn=${acceptedTurn} " +
            "owner_source=hook accepted_source=post_pump_upper_bound")
        enqueueMillis.add(enqueueMs)
        ownerMillis.add(ownerAt + enqueueMs)
        acceptedMillis.add(acceptedAt + enqueueMs)
        sample += 1
    }
    let sortedOwner = sortedCopy(ownerMillis)
    let sortedAccepted = sortedCopy(acceptedMillis)
    let p50Owner = percentile(sortedOwner, 10)
    let p95Owner = percentile(sortedOwner, 19)
    let maxOwner = sortedOwner[sortedOwner.size - 1]
    let p50Accepted = percentile(sortedAccepted, 10)
    let p95Accepted = percentile(sortedAccepted, 19)
    let maxAccepted = sortedAccepted[sortedAccepted.size - 1]
    let budgetOk = p95Owner <= 100 && p95Accepted <= 150
    let ok = allApplied && (budgetOk || !enforceBudget)
    println("CJGUI_TWO_WINDOW_WORKLOAD ordinal=${ordinal} samples=${samples} all_applied=${allApplied} " +
        "owner_ms p50=${p50Owner} p95=${p95Owner} max=${maxOwner} " +
        "accepted_ms p50=${p50Accepted} p95=${p95Accepted} max=${maxAccepted} budget_ok=${budgetOk} ok=${ok}")
    return ok
}

// Both windows enter through the ordinary application turn. A's owner marks
// a new long-text scene, B's TextKit adapter queues its edit before the turn,
// and no caller performs a synchronous A refresh before host dispatch.
private func runHostWorkload(windowA: CjguiComposableUiWindow, windowB: CjguiComposableUiWindow,
    heavy: HeavyMarkedController, responsive: ResponsiveMarkedController,
    application: CjguiMacosApplication, resizeBeforeHost: Bool): Bool {
    let owners = ArrayList<Int64>()
    let accepted = ArrayList<Int64>()
    var allApplied = true
    var sample: Int64 = 0
    while (sample < 20) {
        let unique = "B-host-${sample} 😀"
        responsive.resetOwnerHook()
        let ready = MonoTime.now()
        let enqueueStatus = editB(windowB, unique)
        let enqueueDone = MonoTime.now()
        var resizeVersion: UInt64 = 0u64
        let resizeStatus = if (resizeBeforeHost) {
            unsafe { cjgui_internal_renderer_test_resize_composable_window(
                windowA.testSessionToken(), inout resizeVersion) }
        } else { CJGUI_INTERNAL_RENDERER_OK }
        heavy.updateText()
        windowA.requestRefresh()
        let hostStart = MonoTime.now()
        let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
        let hostEnd = MonoTime.now()
        var turn: Int64 = 1
        while (turn < 8 && (!responsive.ownerHooked || windowB.acceptedSceneNodes().size == 0 ||
            windowB.acceptedSceneNodes()[0].value != unique)) {
            let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
            turn += 1
        }
        let ownerOk = responsive.ownerHooked && responsive.lastOwnerText == unique
        let acceptedOk = windowB.acceptedSceneNodes().size > 0 && windowB.acceptedSceneNodes()[0].value == unique
        let ownerMs = if (ownerOk) { (responsive.lastOwnerRawMono - ready).toMilliseconds() } else { -1 }
        let acceptedMs = (MonoTime.now() - ready).toMilliseconds()
        println("CJGUI_TWO_WINDOW_HOST_SAMPLE mode=${if (resizeBeforeHost) { "resize" } else { "tail" }} sample=${sample} " +
            "rows=3000 utf16_units=${utf16Units(heavy.text)} utf8_bytes=${heavy.text.size} " +
            "enqueue_ms=${(enqueueDone - ready).toMilliseconds()} " +
            "prehost_ms=${(hostStart - enqueueDone).toMilliseconds()} " +
            "first_host_ms=${(hostEnd - hostStart).toMilliseconds()} " +
            "owner_ms=${ownerMs} accepted_upper_ms=${acceptedMs} turns=${turn} " +
            "owner_ok=${ownerOk} accepted_ok=${acceptedOk} enqueue_status=${enqueueStatus} resize_status=${resizeStatus}")
        if (enqueueStatus != CJGUI_INTERNAL_RENDERER_OK || resizeStatus != CJGUI_INTERNAL_RENDERER_OK ||
            !ownerOk || !acceptedOk) { allApplied = false }
        // Once B's accepted scene is observable, the next ordinary turn must
        // advance A's deferred expensive preparation. This checks fairness
        // without charging unrelated A work to B's post-pump upper bound.
        let aPendingBeforeSettle = windowA.acceptedSceneNodes().size == 0 ||
            windowA.acceptedSceneNodes()[0].value != heavy.text
        var projectionAXBefore: UInt64 = 0u64; var projectionInputBefore: UInt64 = 0u64
        var projectionRefreshBefore: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_projection_timing_stats(
            windowA.testSessionToken(), inout projectionAXBefore, inout projectionInputBefore,
            inout projectionRefreshBefore) }
        var decorationsBefore: UInt64 = 0u64; var keyBefore: UInt64 = 0u64; var preparationBefore: UInt64 = 0u64
        var fallbackBefore: UInt64 = 0u64; var fallbackCountBefore: UInt64 = 0u64; var fallbackCharsBefore: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_text_substage_stats(
            windowA.testSessionToken(), inout decorationsBefore, inout keyBefore, inout preparationBefore,
            inout fallbackBefore, inout fallbackCountBefore, inout fallbackCharsBefore) }
        var rasterBefore: UInt64 = 0u64; var rasterBytesBefore: UInt64 = 0u64; var rasterMicrosBefore: UInt64 = 0u64
        var uploadBefore: UInt64 = 0u64; var uploadBytesBefore: UInt64 = 0u64; var uploadMicrosBefore: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
            windowA.testSessionToken(), inout rasterBefore, inout rasterBytesBefore, inout rasterMicrosBefore,
            inout uploadBefore, inout uploadBytesBefore, inout uploadMicrosBefore) }
        let settleStarted = MonoTime.now()
        let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
        var projectionAXAfter: UInt64 = 0u64; var projectionInputAfter: UInt64 = 0u64
        var projectionRefreshAfter: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_projection_timing_stats(
            windowA.testSessionToken(), inout projectionAXAfter, inout projectionInputAfter,
            inout projectionRefreshAfter) }
        var decorationsAfter: UInt64 = 0u64; var keyAfter: UInt64 = 0u64; var preparationAfter: UInt64 = 0u64
        var fallbackAfter: UInt64 = 0u64; var fallbackCountAfter: UInt64 = 0u64; var fallbackCharsAfter: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_text_substage_stats(
            windowA.testSessionToken(), inout decorationsAfter, inout keyAfter, inout preparationAfter,
            inout fallbackAfter, inout fallbackCountAfter, inout fallbackCharsAfter) }
        var rasterAfter: UInt64 = 0u64; var rasterBytesAfter: UInt64 = 0u64; var rasterMicrosAfter: UInt64 = 0u64
        var uploadAfter: UInt64 = 0u64; var uploadBytesAfter: UInt64 = 0u64; var uploadMicrosAfter: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
            windowA.testSessionToken(), inout rasterAfter, inout rasterBytesAfter, inout rasterMicrosAfter,
            inout uploadAfter, inout uploadBytesAfter, inout uploadMicrosAfter) }
        let stageTiming = windowA.testRefreshTiming()
        let aAdvanced = windowA.acceptedSceneNodes().size > 0 &&
            windowA.acceptedSceneNodes()[0].value == heavy.text
        let bStable = windowB.acceptedSceneNodes().size > 0 &&
            windowB.acceptedSceneNodes()[0].value == unique
        println("CJGUI_TWO_WINDOW_HOST_SETTLE mode=${if (resizeBeforeHost) { "resize" } else { "tail" }} " +
            "sample=${sample} a_pending_before=${aPendingBeforeSettle} a_advanced=${aAdvanced} " +
            "b_stable=${bStable} settle_ms=${(MonoTime.now() - settleStarted).toMilliseconds()}")
        println("CJGUI_TWO_WINDOW_A_PREP mode=${if (resizeBeforeHost) { "resize" } else { "tail" }} sample=${sample} " +
            "build_ms=${stageTiming.buildNanoseconds / 1000000} layout_ms=${stageTiming.layoutNanoseconds / 1000000} " +
            "native_stage_ms=${stageTiming.nativeStageAndSubmitNanoseconds / 1000000} " +
            "projection_ax_us=${projectionAXAfter - projectionAXBefore} " +
            "projection_input_us=${projectionInputAfter - projectionInputBefore} " +
            "projection_refresh_us=${projectionRefreshAfter - projectionRefreshBefore} " +
            "decorations_us=${decorationsAfter - decorationsBefore} " +
            "preparation_us=${preparationAfter - preparationBefore} fallback_us=${fallbackAfter - fallbackBefore} " +
            "fallback_chars=${fallbackCharsAfter - fallbackCharsBefore} " +
            "raster_count=${rasterAfter - rasterBefore} raster_us=${rasterMicrosAfter - rasterMicrosBefore} " +
            "upload_count=${uploadAfter - uploadBefore} upload_us=${uploadMicrosAfter - uploadMicrosBefore}")
        if (!aAdvanced || !bStable) { allApplied = false }
        owners.add(ownerMs)
        accepted.add(acceptedMs)
        sample += 1
    }
    let ownerSorted = sortedCopy(owners)
    let acceptedSorted = sortedCopy(accepted)
    let ownerP95 = percentile(ownerSorted, 19)
    let acceptedP95 = percentile(acceptedSorted, 19)
    let passed = allApplied && ownerP95 <= 100 && acceptedP95 <= 150
    println("CJGUI_TWO_WINDOW_HOST mode=${if (resizeBeforeHost) { "resize" } else { "tail" }} rows=3000 " +
        "owner_p95_ms=${ownerP95} accepted_upper_p95_ms=${acceptedP95} " +
        "all_applied=${allApplied} passed=${passed}")
    return passed
}

private func activeRasterCount(window: CjguiComposableUiWindow): UInt64 {
    var raster: UInt64 = 0u64; var rasterBytes: UInt64 = 0u64; var rasterMicros: UInt64 = 0u64
    var upload: UInt64 = 0u64; var uploadBytes: UInt64 = 0u64; var uploadMicros: UInt64 = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
        window.testSessionToken(), inout raster, inout rasterBytes, inout rasterMicros,
        inout upload, inout uploadBytes, inout uploadMicros) }
    return raster
}

// A TESTING-only independent producer is armed before the host turn but starts
// its timer only when A actually enters active multiline preparation. It posts
// B from a background queue during that work; main-thread admission uses the
// ordinary native FIFO once A yields. Latency starts at producer post, not at
// the later enqueue or at the next application turn.
private func runMidworkArrival(windowA: CjguiComposableUiWindow, windowB: CjguiComposableUiWindow,
    heavy: HeavyMarkedController, responsive: ResponsiveMarkedController,
    application: CjguiMacosApplication): Bool {
    let owners = ArrayList<Int64>()
    let accepted = ArrayList<Int64>()
    var allApplied = true
    var maximumA: Int64 = 0
    var attempt: Int64 = 0
    var inFlightSamples: Int64 = 0
    var missedStage: Int64 = 0
    // The previous 9/15 ms delayed arms landed after a 6-9 ms A stage and
    // were incorrectly counted as in-flight failures. Keep the raw old FAIL;
    // here collect twenty ACTUAL in-flight arrivals without delaying A or
    // relaxing the original owner/accepted latency budgets. A bounded retry
    // counts misses separately and cannot pass without twenty stage matches.
    while (attempt < 40 && inFlightSamples < 20) {
        let unique = "B-midwork-${attempt} 😀"
        responsive.resetOwnerHook()
        var actualWidth: UInt32 = 0u32; var actualHeight: UInt32 = 0u32
        let width = UInt32(900 + attempt * 13)
        let resize = unsafe { cjgui_internal_renderer_test_set_composable_content_size(
            windowA.testSessionToken(), width, 620u32, inout actualWidth, inout actualHeight) }
        heavy.updateText()
        windowA.requestRefresh()
        let rasterBefore = activeRasterCount(windowA)
        let delay = 1000u32
        let nativeText = unsafe { LibC.mallocCString(unique) }
        var arm = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        try (textResource = nativeText.asResource()) {
            arm = unsafe { cjgui_internal_renderer_test_arm_midwork_composable_event(
                windowA.testSessionToken(), windowB.testSessionToken(), 0u32, 28u32,
                textResource.value, delay) }
        }
        let hostStarted = MonoTime.now()
        let _ = application.pumpOneTurn(turnBudgetMs: 0u32)
        let hostElapsed = (MonoTime.now() - hostStarted).toMilliseconds()
        var aStart: UInt64 = 0u64; var aEnd: UInt64 = 0u64; var producerReady: UInt64 = 0u64
        var producerPost: UInt64 = 0u64; var nativeEnqueue: UInt64 = 0u64
        var enqueueStatus: Int32 = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        var turn: Int64 = 1
        while (turn < 10) {
            let _ = unsafe { cjgui_internal_renderer_test_midwork_composable_event_timing(
                windowA.testSessionToken(), inout aStart, inout aEnd, inout producerReady,
                inout producerPost, inout nativeEnqueue, inout enqueueStatus) }
            if (nativeEnqueue > 0 && responsive.ownerHooked &&
                windowB.acceptedSceneNodes().size > 0 && windowB.acceptedSceneNodes()[0].value == unique) { break }
            let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
            turn += 1
        }
        var acceptedAt: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_monotonic_micros(inout acceptedAt) }
        let rasterDelta = activeRasterCount(windowA) - rasterBefore
        let ownerOk = responsive.ownerHooked && responsive.lastOwnerText == unique &&
            responsive.lastOwnerNativeMicros >= producerPost && producerPost > 0
        let acceptedOk = windowB.acceptedSceneNodes().size > 0 &&
            windowB.acceptedSceneNodes()[0].value == unique && acceptedAt >= producerPost && producerPost > 0
        let postDuringA = aStart > 0 && aEnd > aStart && producerPost >= aStart && producerPost < aEnd
        let aAdvanced = windowA.acceptedSceneNodes().size > 0 &&
            windowA.acceptedSceneNodes()[0].value == heavy.text
        let ownerMs = if (ownerOk) { Int64((responsive.lastOwnerNativeMicros - producerPost) / 1000u64) } else { -1 }
        let acceptedMs = if (acceptedOk) { Int64((acceptedAt - producerPost) / 1000u64) } else { -1 }
        let aMs = if (aEnd > aStart) { Int64((aEnd - aStart) / 1000u64) } else { -1 }
        if (aMs > maximumA) { maximumA = aMs }
        let deliveryOk = resize == CJGUI_INTERNAL_RENDERER_OK && arm == CJGUI_INTERNAL_RENDERER_OK &&
            enqueueStatus == CJGUI_INTERNAL_RENDERER_OK && ownerOk && acceptedOk &&
            aAdvanced && rasterDelta >= 2u64 && actualWidth == width
        let sampleOk = deliveryOk && postDuringA
        println("CJGUI_TWO_WINDOW_MIDWORK_SAMPLE attempt=${attempt} qualifying=${inFlightSamples} " +
            "width=${actualWidth} delay_us=${delay} producer_ready=${producerReady} producer_post=${producerPost} " +
            "native_enqueue=${nativeEnqueue} a_start=${aStart} a_end=${aEnd} " +
            "post_during_a=${postDuringA} post_to_enqueue_ms=${if (nativeEnqueue >= producerPost && producerPost > 0) { Int64((nativeEnqueue - producerPost) / 1000u64) } else { -1 }} " +
            "owner_ms=${ownerMs} accepted_upper_ms=${acceptedMs} a_ms=${aMs} host_ms=${hostElapsed} " +
            "raster_delta=${rasterDelta} turns=${turn} owner_ok=${ownerOk} accepted_ok=${acceptedOk} " +
            "a_advanced=${aAdvanced} delivery_ok=${deliveryOk} stage_match=${postDuringA} passed=${sampleOk}")
        if (!deliveryOk) { allApplied = false }
        if (postDuringA) {
            inFlightSamples += 1
            owners.add(ownerMs)
            accepted.add(acceptedMs)
        } else {
            missedStage += 1
        }
        attempt += 1
    }
    let ownerSorted = sortedCopy(owners)
    let acceptedSorted = sortedCopy(accepted)
    let ownerP95 = percentile(ownerSorted, 19)
    let acceptedP95 = percentile(acceptedSorted, 19)
    let passed = allApplied && inFlightSamples == 20 && ownerP95 >= 0 && ownerP95 <= 100 &&
        acceptedP95 >= 0 && acceptedP95 <= 150
    println("CJGUI_TWO_WINDOW_MIDWORK attempts=${attempt} in_flight_samples=${inFlightSamples} " +
        "missed_stage=${missedStage} owner_p95_ms=${ownerP95} " +
        "accepted_upper_p95_ms=${acceptedP95} maximum_a_ms=${maximumA} " +
        "all_applied=${allApplied} passed=${passed}")
    return passed
}

/// Timing negative control: B's edit completes on the FIRST pump, and A's
/// subsequent heavy workload must not move B's completion time. The recorded
/// first-completion evidence is captured before the heavy work and compared
/// after it — a scheduler that let A's work delay B would surface here as a
/// moved owner/accepted observation.
private func runNegativeControl(windowA: CjguiComposableUiWindow, windowB: CjguiComposableUiWindow,
    heavy: HeavyMarkedController, responsive: ResponsiveMarkedController,
    application: CjguiMacosApplication): Bool {
    let unique = "负对照-${heavy.revision} 😀"
    responsive.resetOwnerHook()
    let enqueueStarted = MonoTime.now()
    let enqueueStatus = editB(windowB, unique)
    let enqueueDone = MonoTime.now()
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    // First-completion evidence, captured before A works again. The owner
    // hook fires at the real application point inside the controller.
    let firstOwnerOk = responsive.ownerHooked && responsive.lastOwnerText == unique
    var firstAcceptedOk = false
    if (windowB.acceptedSceneNodes().size > 0) {
        firstAcceptedOk = windowB.acceptedSceneNodes()[0].value == unique
    }
    let firstOwnerMs = if (firstOwnerOk) {
        (responsive.lastOwnerRawMono - enqueueDone).toMilliseconds() +
            (enqueueDone - enqueueStarted).toMilliseconds()
    } else { -1 }
    // Heavy workload on A AFTER B has completed.
    var resizeVersion: UInt64 = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_resize_composable_window(
        windowA.testSessionToken(), inout resizeVersion) }
    let _ = windowA.refresh()
    var offset: Float32 = 0.0f32
    var glyphs: UInt32 = 0u32
    let _ = unsafe { cjgui_internal_renderer_test_scroll_composable_multiline(
        windowA.testSessionToken(), -160.0f32, inout offset, inout glyphs) }
    heavy.updateText()
    let _ = windowA.refresh()
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    // B's completion must still be the FIRST one: the hook is unchanged and
    // the accepted scene still carries the same unique value.
    let ownerStable = responsive.ownerHooked && responsive.lastOwnerText == unique &&
        responsive.ownerValue() == unique
    let acceptedStable = windowB.acceptedSceneNodes().size > 0 &&
        windowB.acceptedSceneNodes()[0].value == unique
    let ok = enqueueStatus == CJGUI_INTERNAL_RENDERER_OK && firstOwnerOk && firstAcceptedOk &&
        ownerStable && acceptedStable && firstOwnerMs >= 0
    println("CJGUI_TWO_WINDOW_NEGATIVE_CONTROL enqueue_status=${enqueueStatus} " +
        "first_owner=${firstOwnerOk} first_accepted=${firstAcceptedOk} " +
        "first_owner_ms=${firstOwnerMs} owner_stable=${ownerStable} " +
        "accepted_stable=${acceptedStable} ok=${ok}")
    return ok
}

/// Start from a known head viewport and follow the production scroll path.
/// The previous check began after many workload scrolls (often at the bottom),
/// then treated any nonzero tile alpha as proof that a particular marker was
/// visible. Neither fact established the visible content of a step.
private func runMarkedContent(windowA: CjguiComposableUiWindow): Bool {
    let value = windowA.acceptedSceneNodes()[0].value
    let headOk = value.contains("头部标记XYZ") && value.startsWith("负载正文行")
    let midOk = value.contains("中部标记ABC")
    let tailOk = value.contains("尾部标记QWE")
    var tiles: UInt32 = 0u32
    var tileBytes: UInt64 = 0u64
    var x: Float32 = 0.0f32
    var y: Float32 = 0.0f32
    var w: Float32 = 0.0f32
    var h: Float32 = 0.0f32
    let tileStatus = unsafe { cjgui_internal_renderer_test_composable_text_tile_stats(
        windowA.testSessionToken(), 0u32, 0u32, inout tiles, inout tileBytes,
        inout x, inout y, inout w, inout h) }
    var offset: Float32 = 0.0f32
    var glyphs: UInt32 = 0u32
    let resetStatus = unsafe { cjgui_internal_renderer_test_scroll_composable_multiline(
        windowA.testSessionToken(), 1000000.0f32, inout offset, inout glyphs) }
    let head = readMarkedViewport(windowA, "头部标记XYZ")
    println("CJGUI_MARKED_HEAD reset_status=${resetStatus} offset=${offset} glyphs=${glyphs} " +
        "viewport_status=${head.status} max=${head.maximum} visible_start=${head.characterStart} " +
        "visible_length=${head.characterLength} native_version=${head.projectionVersion} " +
        "accepted_version=${windowA.windowProjection().acceptedSceneVersion} marker_visible=${head.markerVisible}")
    var midSeen = false
    var tailSeen = false
    var midAlpha: UInt64 = 0u64
    var tailAlpha: UInt64 = 0u64
    var monotonic = true
    var scrolls = 0
    while (scrolls < 180 && !tailSeen) {
        let before = readMarkedViewport(windowA, "中部标记ABC")
        let status = unsafe { cjgui_internal_renderer_test_scroll_composable_multiline(
            windowA.testSessionToken(), -300.0f32, inout offset, inout glyphs) }
        let middle = readMarkedViewport(windowA, "中部标记ABC")
        let tail = readMarkedViewport(windowA, "尾部标记QWE")
        let acceptedVersion = windowA.windowProjection().acceptedSceneVersion
        let atKnownEnd = middle.maximum >= 0.0f32 && before.offset >= middle.maximum - 0.5f32
        let stepOk = status == CJGUI_INTERNAL_RENDERER_OK && middle.status == CJGUI_INTERNAL_RENDERER_OK &&
            tail.status == CJGUI_INTERNAL_RENDERER_OK && offset >= before.offset &&
            (offset > before.offset || atKnownEnd) &&
            middle.projectionVersion == UInt64(acceptedVersion) &&
            tail.projectionVersion == middle.projectionVersion
        println("CJGUI_MARKED_SCROLL step=${scrolls} before=${before.offset} after=${offset} " +
            "max=${middle.maximum} api_status=${status} viewport_status=${middle.status} " +
            "glyphs=${glyphs} visible_start=${middle.characterStart} visible_length=${middle.characterLength} " +
            "mid_visible=${middle.markerVisible} tail_visible=${tail.markerVisible} " +
            "accepted_version=${acceptedVersion} native_version=${middle.projectionVersion} " +
            "at_known_end=${atKnownEnd} step_ok=${stepOk}")
        if (!stepOk) { monotonic = false }
        if (middle.markerVisible && !midSeen) {
            midSeen = true
            let _ = unsafe { cjgui_internal_renderer_test_composable_text_tile_alpha_pixels(
                windowA.testSessionToken(), 0u32, 0u32, inout midAlpha) }
        }
        if (tail.markerVisible && !tailSeen) {
            tailSeen = true
            let _ = unsafe { cjgui_internal_renderer_test_composable_text_tile_alpha_pixels(
                windowA.testSessionToken(), 0u32, 0u32, inout tailAlpha) }
        }
        if (atKnownEnd && !tailSeen) { break }
        scrolls += 1
    }
    // A separate end control distinguishes a legal clamp from a stuck scroll.
    // It is excluded from the head/middle/tail traversal above.
    var endOffset: Float32 = 0.0f32
    var endGlyphs: UInt32 = 0u32
    let endStatus = unsafe { cjgui_internal_renderer_test_scroll_composable_multiline(
        windowA.testSessionToken(), -1000000.0f32, inout endOffset, inout endGlyphs) }
    let end = readMarkedViewport(windowA, "尾部标记QWE")
    var clampedOffset: Float32 = 0.0f32
    var clampedGlyphs: UInt32 = 0u32
    let clampStatus = unsafe { cjgui_internal_renderer_test_scroll_composable_multiline(
        windowA.testSessionToken(), -300.0f32, inout clampedOffset, inout clampedGlyphs) }
    let legalEnd = endStatus == CJGUI_INTERNAL_RENDERER_OK && clampStatus == CJGUI_INTERNAL_RENDERER_OK &&
        end.status == CJGUI_INTERNAL_RENDERER_OK && end.maximum >= 0.0f32 &&
        endOffset == end.maximum && clampedOffset == endOffset && end.markerVisible
    println("CJGUI_MARKED_BOUNDARY after_jump=${endOffset} max=${end.maximum} clamp_after=${clampedOffset} " +
        "jump_status=${endStatus} clamp_status=${clampStatus} tail_visible=${end.markerVisible} " +
        "accepted_version=${windowA.windowProjection().acceptedSceneVersion} " +
        "native_version=${end.projectionVersion} legal_end=${legalEnd}")
    let scrolled = resetStatus == CJGUI_INTERNAL_RENDERER_OK && head.status == CJGUI_INTERNAL_RENDERER_OK &&
        head.offset == 0.0f32 && head.markerVisible && monotonic && midSeen && tailSeen &&
        offset > 0.0f32 && glyphs > 0u32 && midAlpha > 0u64 && tailAlpha > 0u64 &&
        tileStatus == CJGUI_INTERNAL_RENDERER_OK && tiles >= 1u32 && legalEnd
    println("CJGUI_MARKED_CONTENT head=${headOk} mid=${midOk} tail=${tailOk} " +
        "tiles=${tiles} tile_bytes=${tileBytes} mid_alpha=${midAlpha} tail_alpha=${tailAlpha} " +
        "offset=${offset} visible_glyphs=${glyphs} scrolls=${scrolls} mid_seen=${midSeen} " +
        "tail_seen=${tailSeen} monotonic=${monotonic} scrolled_ok=${scrolled}")
    return headOk && midOk && tailOk && scrolled
}

main(): Int64 {
    let heavy = HeavyMarkedController()
    let responsive = ResponsiveMarkedController()
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let openedA = application.openWindow(heavy,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Workload A", 980u32, 620u32))
    let openedB = application.openWindow(responsive,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Workload B", 320u32, 240u32))
    if (!openedA.didOpen || !openedB.didOpen) { application.close(); return 1 }
    let identifierA = if (let Some(value) <- openedA.identifier) { value } else { application.close(); return 1 }
    let identifierB = if (let Some(value) <- openedB.identifier) { value } else { application.close(); return 1 }
    let windowA = if (let Some(value) <- application.window(identifierA)) { value } else {
        application.close(); return 1
    }
    let windowB = if (let Some(value) <- application.window(identifierB)) { value } else {
        application.close(); return 1
    }
    // Focus A's input BEFORE the warm-up: a warm-up scroll on an unfocused
    // multiline returns 99, which used to fail the warm-up round and poison
    // the probe result. With focus first, the warm-up itself is valid.
    let focusStatus = unsafe { cjgui_internal_renderer_test_activate_composable_point(
        windowA.testSessionToken(), 20.0f32, 20.0f32) }
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    // Warm-up: one full workload round settles caches. Not part of the
    // official statistics; its validity is reported separately.
    let warmupOk = runWorkload(windowA, windowB, heavy, responsive, application, 1, 0, false, false)
    println("CJGUI_TWO_WINDOW_WARMUP ok=${warmupOk} focus=${focusStatus}")
    var ok = warmupOk
    // Synchronous resize/refresh/scroll is a pressure control; its time is
    // reported separately and cannot be credited to the host scheduler.
    ok = runWorkload(windowA, windowB, heavy, responsive, application, 20, 1, true, false) && ok
    // Worst-case barrier mode: three heavy ops back-to-back without a pump.
    // Recorded for attribution; the stage budget is defined on real
    // event-loop turns, which the permissive mode models.
    ok = runWorkload(windowA, windowB, heavy, responsive, application, 20, 2, false, false) && ok
    ok = runHostWorkload(windowA, windowB, heavy, responsive, application, false) && ok
    ok = runHostWorkload(windowA, windowB, heavy, responsive, application, true) && ok
    ok = runMidworkArrival(windowA, windowB, heavy, responsive, application) && ok
    // Timing negative control: B completes on the first pump and its
    // completion time must not move while A keeps working.
    ok = runNegativeControl(windowA, windowB, heavy, responsive, application) && ok
    let contentOk = runMarkedContent(windowA)
    // After the workload stops, an idle turn must not raster anything.
    var rasterBefore: UInt64 = 0u64
    var rasterBytesBefore: UInt64 = 0u64
    var rasterMicrosBefore: UInt64 = 0u64
    var uploadBefore: UInt64 = 0u64
    var uploadBytesBefore: UInt64 = 0u64
    var uploadMicrosBefore: UInt64 = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
        windowA.testSessionToken(), inout rasterBefore, inout rasterBytesBefore, inout rasterMicrosBefore,
        inout uploadBefore, inout uploadBytesBefore, inout uploadMicrosBefore) }
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    var rasterAfter: UInt64 = 0u64
    var rasterBytesAfter: UInt64 = 0u64
    var rasterMicrosAfter: UInt64 = 0u64
    var uploadAfter: UInt64 = 0u64
    var uploadBytesAfter: UInt64 = 0u64
    var uploadMicrosAfter: UInt64 = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
        windowA.testSessionToken(), inout rasterAfter, inout rasterBytesAfter, inout rasterMicrosAfter,
        inout uploadAfter, inout uploadBytesAfter, inout uploadMicrosAfter) }
    let idleClean = rasterBefore == rasterAfter && uploadBefore == uploadAfter
    println("CJGUI_TWO_WINDOW_IDLE raster=${rasterBefore}->${rasterAfter} upload=${uploadBefore}->${uploadAfter} " +
        "idle_clean=${idleClean} focus=${focusStatus}")
    ok = idleClean && contentOk && ok
    println("CJGUI_TWO_WINDOW_WORKLOAD_PROBE passed=${ok}")
    application.close()
    return if (ok) { 0 } else { 1 }
}

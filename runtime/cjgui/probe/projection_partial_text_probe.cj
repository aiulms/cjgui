// Projection partial-text comparison probe (stage C1/C3).
//
// The SAME external owner change — a small tail append on a focused multiline
// document — runs through BOTH projection paths:
//   local : same component identity + unchanged font style, so
//           `CjguiExternalReplacementRange` qualifies and only the tail span
//           is replaced in the derived NSTextStorage (fallback invalidation
//           scoped to the composed-aligned affected range);
//   full  : a TESTING-only one-shot switch selects the complete replacement
//           algorithm with identical owner text, style, width and focus.
// Twenty samples per arm feed projection-refresh and texture-prep deltas plus
// per-sample rows; content identity is asserted every sample.
package cjgui

import std.collection.*
import std.convert.*
import std.env.*
import std.time.*

foreign {
    func cjgui_internal_renderer_test_activate_composable_point(
        session: UInt64, pointX: Float32, pointY: Float32
    ): Int32
    func cjgui_internal_renderer_test_composable_projection_timing_stats(
        session: UInt64, outAccessibilityMicros: CPointer<UInt64>,
        outInputMicros: CPointer<UInt64>, outRefreshMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_work_stats(
        session: UInt64, outRasterCount: CPointer<UInt64>, outRasterBytes: CPointer<UInt64>,
        outRasterMicros: CPointer<UInt64>, outUploadCount: CPointer<UInt64>,
        outUploadBytes: CPointer<UInt64>, outUploadMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_composable_text_substage_stats(
        session: UInt64, outDecorationsMicros: CPointer<UInt64>,
        outKeyConstructionMicros: CPointer<UInt64>, outPreparationMicros: CPointer<UInt64>,
        outFallbackMicros: CPointer<UInt64>, outFallbackApplyCount: CPointer<UInt64>,
        outFallbackCharacters: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_selection(
        session: UInt64, nodeIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_selection(
        session: UInt64, outSelectionStart: CPointer<UInt32>, outSelectionEnd: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_force_full_projection_replacement_once(session: UInt64): Int32
    func cjgui_internal_renderer_test_composable_text_matches(session: UInt64, expected: CString): Int32
    func cjgui_internal_renderer_test_composable_multiline_fallback_runs(
        session: UInt64, outExpectedFallbackRuns: CPointer<UInt32>,
        outMismatchedRuns: CPointer<UInt32>
    ): Int32
}

private func longBodyRange(first: Int64, limit: Int64, separator: String): String {
    let builder = StringBuilder()
    let row = "负载正文行 观微 😀 0123456789 "
    var index = first
    while (index < limit) {
        builder.append(row)
        builder.append("${index}${separator}")
        index += 1
    }
    return builder.toString()
}

private func longBody(lines: Int64, separator: String): String { return longBodyRange(0, lines, separator) }

private func utf16Units(value: String): Int64 {
    var count: Int64 = 0
    for (scalar in value.runes()) {
        count += if (UInt32(scalar) > 0xffffu32) { 2 } else { 1 }
    }
    return count
}

/// One window whose multiline document is application truth. Each `applyTail`
/// is an EXTERNAL owner projection change: the app's value grows by a small
/// tail and the whole interface is re-projected.
private class PartialTextController <: CjguiComposableUiController {
    var value: String
    var inserted: String = ""
    var fontSize: Float64
    var revision: Int64 = 1
    public init(value: String, fontSize: Float64) {
        this.value = value
        this.fontSize = fontSize
    }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableMultilineTextInput(31, "partial-doc", "文档", value, 31,
            CjguiComposableUiStyle(growX: 1, growY: 1, fontSize: fontSize,
                textColor: CjguiComposableUiColor(0.92, 0.95, 1.0, 1.0)))
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
    public func applyInsert(tail: String, prefix: String, suffix: String): String {
        inserted = inserted + tail
        value = prefix + inserted + suffix
        revision += 1
        return value
    }
}

private func sortedCopy(values: ArrayList<Int64>): Array<Int64> {
    let copy = values.toArray()
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

private func projectionRefreshMicros(window: CjguiComposableUiWindow): Int64 {
    var accessibilityMicros: UInt64 = 0u64
    var inputMicros: UInt64 = 0u64
    var refreshMicros: UInt64 = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_composable_projection_timing_stats(
        window.testSessionToken(), inout accessibilityMicros, inout inputMicros,
        inout refreshMicros) }
    return Int64(refreshMicros)
}

private func rasterCount(window: CjguiComposableUiWindow): Int64 {
    var rasterCount: UInt64 = 0u64
    var rasterBytes: UInt64 = 0u64
    var rasterMicros: UInt64 = 0u64
    var uploadCount: UInt64 = 0u64
    var uploadBytes: UInt64 = 0u64
    var uploadMicros: UInt64 = 0u64
    let _ = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
        window.testSessionToken(), inout rasterCount, inout rasterBytes, inout rasterMicros,
        inout uploadCount, inout uploadBytes, inout uploadMicros) }
    return Int64(rasterCount)
}

// Runs one arm. Returns false if any sample failed its content identity check.
private func runArm(window: CjguiComposableUiWindow, controller: PartialTextController,
    application: CjguiMacosApplication, samples: Int64, ordinal: Int64,
    forceFull: Bool, baselineLength: Int64, position: String, prefix: String, suffix: String,
    requireNoRaster: Bool): Bool {
    let refreshMillis = ArrayList<Int64>()
    let rasterDelta = ArrayList<Int64>()
    var allApplied = true
    var sample: Int64 = 0
    while (sample < samples) {
        let tail = "增量${sample} 中文😀"
        let expected = prefix + controller.inserted + tail + suffix
        var refreshBefore: UInt64 = 0u64
        var inputMicros: UInt64 = 0u64
        var accessMicros: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_projection_timing_stats(
            window.testSessionToken(), inout accessMicros, inout inputMicros, inout refreshBefore) }
        var rasterBefore: UInt64 = 0u64
        var rb: UInt64 = 0u64
        var rm: UInt64 = 0u64
        var uc: UInt64 = 0u64
        var ub: UInt64 = 0u64
        var um: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
            window.testSessionToken(), inout rasterBefore, inout rb, inout rm,
            inout uc, inout ub, inout um) }
        let started = MonoTime.now()
        var decoA: UInt64 = 0u64; var keyA: UInt64 = 0u64; var prepA: UInt64 = 0u64
        var fbA: UInt64 = 0u64; var fbCountA: UInt64 = 0u64; var fbCharsA: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_text_substage_stats(
            window.testSessionToken(), inout decoA, inout keyA, inout prepA,
            inout fbA, inout fbCountA, inout fbCharsA) }
        let ownerValue = controller.applyInsert(tail, prefix, suffix)
        let forceStatus = if (forceFull) {
            unsafe { cjgui_internal_renderer_test_force_full_projection_replacement_once(window.testSessionToken()) }
        } else { CJGUI_INTERNAL_RENDERER_OK }
        let _ = window.refresh()
        let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
        var decoB: UInt64 = 0u64; var keyB: UInt64 = 0u64; var prepB: UInt64 = 0u64
        var fbB: UInt64 = 0u64; var fbCountB: UInt64 = 0u64; var fbCharsB: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_text_substage_stats(
            window.testSessionToken(), inout decoB, inout keyB, inout prepB,
            inout fbB, inout fbCountB, inout fbCharsB) }
        let ended = MonoTime.now()
        var refreshAfter: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_projection_timing_stats(
            window.testSessionToken(), inout accessMicros, inout inputMicros, inout refreshAfter) }
        var rasterAfter: UInt64 = 0u64
        let _ = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
            window.testSessionToken(), inout rasterAfter, inout rb, inout rm,
            inout uc, inout ub, inout um) }
        // Content identity: the accepted scene must carry the exact expected
        // document after either path.
        var contentOk = false
        if (window.acceptedSceneNodes().size > 0) {
            let accepted = window.acceptedSceneNodes()[0].value
            contentOk = accepted == expected && accepted.size == expected.size
        }
        let refreshDeltaMillis = Int64(refreshAfter - refreshBefore) / 1000
        let rasterDeltaCount = Int64(rasterAfter - rasterBefore)
        let localBounded = forceFull || (fbCharsB - fbCharsA <= 100u64 &&
            (!requireNoRaster || rasterDeltaCount == 0))
        println("CJGUI_PARTIAL_SAMPLE position=${position} ordinal=${ordinal} sample=${sample} path=${if (forceFull) { "full" } else { "local" }} " +
            "refresh_ms=${refreshDeltaMillis} wall_ms=${(ended - started).toMilliseconds()} " +
            "raster_delta=${rasterDeltaCount} owner_utf16_units=${utf16Units(ownerValue)} " +
            "owner_utf8_bytes=${ownerValue.size} " +
            "baseline_len=${baselineLength} content_ok=${contentOk} local_bounded=${localBounded} " +
            "sub_decorations_us=${Int64(decoB - decoA)} sub_key_us=${Int64(keyB - keyA)} " +
            "sub_preparation_us=${Int64(prepB - prepA)} sub_fallback_us=${Int64(fbB - fbA)} " +
            "fallback_applies=${Int64(fbCountB - fbCountA)} fallback_chars=${Int64(fbCharsB - fbCharsA)}")
        if (!contentOk || !localBounded || forceStatus != CJGUI_INTERNAL_RENDERER_OK) { allApplied = false }
        refreshMillis.add(refreshDeltaMillis)
        rasterDelta.add(rasterDeltaCount)
        sample += 1
    }
    let sortedRefresh = sortedCopy(refreshMillis)
    let p50 = percentile(sortedRefresh, samples / 2)
    let p95 = percentile(sortedRefresh, samples * 95 / 100)
    let maxRefresh = sortedRefresh[sortedRefresh.size - 1]
    var rasterSum: Int64 = 0
    for (value in rasterDelta) {
        rasterSum += value
    }
    println("CJGUI_PARTIAL_ARM position=${position} ordinal=${ordinal} path=${if (forceFull) { "full" } else { "local" }} " +
        "samples=${samples} all_applied=${allApplied} " +
        "refresh_ms p50=${p50} p95=${p95} max=${maxRefresh} " +
        "raster_delta_sum=${rasterSum}")
    var expectedFallbackRuns: UInt32 = 0u32
    var mismatchedRuns: UInt32 = 0u32
    let fontStatus = unsafe { cjgui_internal_renderer_test_composable_multiline_fallback_runs(
        window.testSessionToken(), inout expectedFallbackRuns, inout mismatchedRuns) }
    let nativeExpected = unsafe { LibC.mallocCString(controller.value) }
    var textStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
    try (textResource = nativeExpected.asResource()) {
        textStatus = unsafe { cjgui_internal_renderer_test_composable_text_matches(
            window.testSessionToken(), textResource.value) }
    }
    let adapterOk = fontStatus == CJGUI_INTERNAL_RENDERER_OK && mismatchedRuns == 0u32 &&
        textStatus == CJGUI_INTERNAL_RENDERER_OK
    println("CJGUI_PARTIAL_ADAPTER position=${position} path=${if (forceFull) { "full" } else { "local" }} " +
        "expected_fallback_runs=${expectedFallbackRuns} mismatched_runs=${mismatchedRuns} " +
        "font_status=${fontStatus} text_status=${textStatus} passed=${adapterOk}")
    return allApplied && adapterOk
}

private func runSelectionReplacementRegression(): Bool {
    let controller = PartialTextController("0123456789ABCDEFGHIJklmnopqrst", 12.0)
    let application = CjguiMacosApplication(maximumWindowCount: 1)
    let opened = application.openWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Selection Map", 420u32, 200u32))
    if (!opened.didOpen) { application.close(); return false }
    let identifier = if (let Some(value) <- opened.identifier) { value } else { application.close(); return false }
    let window = if (let Some(value) <- application.window(identifier)) { value } else {
        application.close(); return false
    }
    let focus = unsafe { cjgui_internal_renderer_test_activate_composable_point(
        window.testSessionToken(), 30.0f32, 30.0f32) }
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    func check(label: String, before: String, after: String, oldStart: UInt32, oldEnd: UInt32,
        expectedStart: UInt32, expectedEnd: UInt32): Bool {
        controller.value = before
        controller.revision += 1
        let baselineReady = window.refresh()
        let set = unsafe { cjgui_internal_renderer_test_set_composable_selection(
            window.testSessionToken(), 0u32, oldStart, oldEnd) }
        controller.value = after
        controller.revision += 1
        let refreshed = window.refresh()
        var start: UInt32 = 0u32
        var end: UInt32 = 0u32
        let read = unsafe { cjgui_internal_renderer_test_composable_selection(
            window.testSessionToken(), inout start, inout end) }
        let passed = baselineReady && set == CJGUI_INTERNAL_RENDERER_OK && refreshed &&
            read == CJGUI_INTERNAL_RENDERER_OK && start == expectedStart && end == expectedEnd
        println("CJGUI_PARTIAL_SELECTION case=${label} old=${oldStart}:${oldEnd} " +
            "expected=${expectedStart}:${expectedEnd} actual=${start}:${end} passed=${passed}")
        return passed
    }
    let before = "0123456789ABCDEFGHIJklmnopqrst"
    let after = "0123456789xyklmnopqrst"
    let afterTail = check("after_shorter", before, after, 25u32, 25u32, 17u32, 17u32)
    let inside = check("inside_shorter", before, after, 15u32, 15u32, 12u32, 12u32)
    let cross = check("cross_shorter", before, after, 5u32, 25u32, 5u32, 17u32)
    let emoji = check("emoji_zwj", "0123456789👩‍💻abcdefghij", "0123456789🙂abcdefghij",
        17u32, 17u32, 14u32, 14u32)
    let passed = focus == CJGUI_INTERNAL_RENDERER_OK && afterTail && inside && cross && emoji
    application.close()
    return passed
}

private func runVisibleTileReuseRegression(): Bool {
    let suffix = " stable first paragraph 0123456789\n" + longBody(700, "\n")
    let controller = PartialTextController("A" + suffix, 12.0)
    let application = CjguiMacosApplication(maximumWindowCount: 1)
    let opened = application.openWindow(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Visible Tile Edit", 980u32, 620u32))
    if (!opened.didOpen) { application.close(); return false }
    let identifier = if (let Some(value) <- opened.identifier) { value } else { application.close(); return false }
    let window = if (let Some(value) <- application.window(identifier)) { value } else {
        application.close(); return false
    }
    let focus = unsafe { cjgui_internal_renderer_test_activate_composable_point(
        window.testSessionToken(), 30.0f32, 30.0f32) }
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    var allApplied = focus == CJGUI_INTERNAL_RENDERER_OK
    var sample: Int64 = 0
    while (sample < 20) {
        let next = if (sample % 2 == 0) { "B" } else { "A" }
        let expected = next + suffix
        let before = rasterCount(window)
        controller.value = expected
        controller.revision += 1
        let refreshed = window.refresh()
        let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
        let rasterDelta = rasterCount(window) - before
        let contentOk = window.acceptedSceneNodes().size > 0 &&
            window.acceptedSceneNodes()[0].value == expected
        let passed = refreshed && contentOk && rasterDelta == 1
        println("CJGUI_PARTIAL_VISIBLE_TILE sample=${sample} raster_delta=${rasterDelta} " +
            "content_ok=${contentOk} passed=${passed}")
        if (!passed) { allApplied = false }
        sample += 1
    }
    application.close()
    return allApplied
}

private func runComparison(lines: Int64, fullFirst: Bool, position: String, singleParagraph: Bool): Bool {
    let separator = if (singleParagraph) { " " } else { "\n" }
    let baseline = longBody(lines, separator)
    let prefix = if (position == "head") { "" } else if (position == "mid") {
        longBodyRange(0, lines / 2, separator)
    } else { baseline }
    let suffix = if (position == "head") { baseline } else if (position == "mid") {
        longBodyRange(lines / 2, lines, separator)
    } else { "" }
    let requireNoRaster = position == "tail" && lines >= 700 && !singleParagraph
    let local = PartialTextController(baseline, 12.0)
    let full = PartialTextController(baseline, 12.0)
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let firstColdStarted = MonoTime.now()
    let firstOpened = if (fullFirst) {
        application.openWindow(full,
            configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Partial Full", 980u32, 620u32))
    } else {
        application.openWindow(local,
            configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Partial Local", 980u32, 620u32))
    }
    let firstColdElapsed = (MonoTime.now() - firstColdStarted).toMilliseconds()
    let secondColdStarted = MonoTime.now()
    let secondOpened = if (fullFirst) {
        application.openWindow(local,
            configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Partial Local", 980u32, 620u32))
    } else {
        application.openWindow(full,
            configuration: CjguiMacosApplicationWindowConfiguration("CJGUI Partial Full", 980u32, 620u32))
    }
    let secondColdElapsed = (MonoTime.now() - secondColdStarted).toMilliseconds()
    let openedLocal = if (fullFirst) { secondOpened } else { firstOpened }
    let openedFull = if (fullFirst) { firstOpened } else { secondOpened }
    let localColdElapsed = if (fullFirst) { secondColdElapsed } else { firstColdElapsed }
    let fullColdElapsed = if (fullFirst) { firstColdElapsed } else { secondColdElapsed }
    if (!openedLocal.didOpen || !openedFull.didOpen) { application.close(); return false }
    let localId = if (let Some(value) <- openedLocal.identifier) { value } else { application.close(); return false }
    let fullId = if (let Some(value) <- openedFull.identifier) { value } else { application.close(); return false }
    let localWindow = if (let Some(value) <- application.window(localId)) { value } else {
        application.close(); return false
    }
    let fullWindow = if (let Some(value) <- application.window(fullId)) { value } else {
        application.close(); return false
    }
    if (localWindow.acceptedSceneNodes().size == 0 || fullWindow.acceptedSceneNodes().size == 0) {
        application.close(); return false
    }
    let localInk = localWindow.acceptedSceneNodes()[0].style.textColor
    let fullInk = fullWindow.acceptedSceneNodes()[0].style.textColor
    let readableStyle = localInk.red > 0.85 && localInk.green > 0.85 &&
        fullInk.red > 0.85 && fullInk.green > 0.85
    let focusLocal = unsafe { cjgui_internal_renderer_test_activate_composable_point(
        localWindow.testSessionToken(), 30.0f32, 30.0f32) }
    let focusFull = unsafe { cjgui_internal_renderer_test_activate_composable_point(
        fullWindow.testSessionToken(), 30.0f32, 30.0f32) }
    let _ = application.pumpOneTurn(turnBudgetMs: 16u32)
    let baselineLength = Int64(baseline.size)
    println("CJGUI_PARTIAL_COLD position=${position} lines=${lines} order=${if (fullFirst) { "full_local" } else { "local_full" }} " +
        "local_open_to_first_accepted_ms=${localColdElapsed} " +
        "full_open_to_first_accepted_ms=${fullColdElapsed} " +
        "local_first_raster_count=${rasterCount(localWindow)} full_first_raster_count=${rasterCount(fullWindow)}")
    println("CJGUI_PARTIAL_PAIR position=${position} single_paragraph=${singleParagraph} lines=${lines} utf16_units=${utf16Units(baseline)} utf8_bytes=${baselineLength} order=${if (fullFirst) { "full_local" } else { "local_full" }} " +
        "same_initial=${local.value == full.value} same_font=${local.fontSize == full.fontSize} " +
        "focus_local=${focusLocal} focus_full=${focusFull} readable_style=${readableStyle}")
    var warmupLocal = false
    var warmupFull = false
    var localOk = false
    var fullOk = false
    if (fullFirst) {
        warmupFull = runArm(fullWindow, full, application, 1, 0, true, baselineLength, position, prefix, suffix, requireNoRaster)
        warmupLocal = runArm(localWindow, local, application, 1, 0, false, baselineLength, position, prefix, suffix, requireNoRaster)
        fullOk = runArm(fullWindow, full, application, 20, 2, true, baselineLength, position, prefix, suffix, requireNoRaster)
        localOk = runArm(localWindow, local, application, 20, 1, false, baselineLength, position, prefix, suffix, requireNoRaster)
    } else {
        warmupLocal = runArm(localWindow, local, application, 1, 0, false, baselineLength, position, prefix, suffix, requireNoRaster)
        warmupFull = runArm(fullWindow, full, application, 1, 0, true, baselineLength, position, prefix, suffix, requireNoRaster)
        localOk = runArm(localWindow, local, application, 20, 1, false, baselineLength, position, prefix, suffix, requireNoRaster)
        fullOk = runArm(fullWindow, full, application, 20, 2, true, baselineLength, position, prefix, suffix, requireNoRaster)
    }
    let sameFinal = local.value == full.value && local.fontSize == full.fontSize
    let passed = warmupLocal && warmupFull && localOk && fullOk && sameFinal &&
        readableStyle &&
        focusLocal == CJGUI_INTERNAL_RENDERER_OK && focusFull == CJGUI_INTERNAL_RENDERER_OK
    println("CJGUI_PARTIAL_PAIR_RESULT position=${position} order=${if (fullFirst) { "full_local" } else { "local_full" }} " +
        "same_final=${sameFinal} passed=${passed}")
    application.close()
    return passed
}

main(): Int64 {
    let lines: Int64 = match (getVariable("CJGUI_PARTIAL_LINES")) {
        case Some(raw) =>
            let parsed = match (Int64.tryParse(raw)) {
                case Some(value) => value
                case None => 700
            }
            if (parsed < 10) { 700 } else { parsed }
        case None => 700
    }
    let position = match (getVariable("CJGUI_PARTIAL_POSITION")) {
        case Some(raw) => if (raw == "head" || raw == "mid") { raw } else { "tail" }
        case None => "tail"
    }
    let singleParagraph = match (getVariable("CJGUI_PARTIAL_SINGLE_PARAGRAPH")) {
        case Some(raw) => raw == "1"
        case None => false
    }
    let localFirst = runComparison(lines, false, position, singleParagraph)
    let fullFirst = runComparison(lines, true, position, singleParagraph)
    let selectionOk = runSelectionReplacementRegression()
    let visibleTileOk = runVisibleTileReuseRegression()
    let ok = localFirst && fullFirst && selectionOk && visibleTileOk
    println("CJGUI_PARTIAL_PROBE passed=${ok}")
    return if (ok) { 0 } else { 1 }
}

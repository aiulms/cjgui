package cjgui

import std.env.*

private class PositionReviewStore <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    public let text = "abc Supercalifragilisticexpialidocious abcdefghijklmnopqrstuvwxyz"
    public var version: Int64 = 1
    public func rangeTextVersion(): Int64 { return version }
    public func rangeTextByteLength(): Int64 { return Int64(text.toArray().size) }
    public func confirmRangeTextVersion(v: Int64, f: () -> Bool): Bool { return v == version && f() }
    public func rebaseRangeTextSelection(v: Int64, a: Int64, b: Int64): ?(Int64, Int64, Int64) {
        return if (v <= version) { Some((version, a, b)) } else { None }
    }
    public func readRangeText(start: Int64, count: Int64): CjguiRangeTextSlice {
        let bytes = text.toArray()
        let end = if (start + count < Int64(bytes.size)) { start + count } else { Int64(bytes.size) }
        return CjguiRangeTextSlice(start, start, String.fromUtf8(bytes[start..end]), version,
            Int64(bytes.size), end == Int64(bytes.size), "")
    }
    public func applyRangeTextEdit(v: Int64, a: Int64, b: Int64, s: String): CjguiRangeTextEditOutcome {
        return CjguiRangeTextEditOutcome(false, false, 1, 1, "read_only_probe")
    }
}

private class PositionReviewController <: CjguiComposableUiController {
    public let store = PositionReviewStore()
    public var restored: Int64 = 0
    public var supersededRestored: Int64 = 0
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "position-review-root", CjguiComposableUiStyle(fixedWidth: 230, fixedHeight: 600))
        root.add(cjguiComposableMultilineTextInput(4, "position-review-body", "", store.text,
            102, CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 270, fontSize: 16.0)))
        root.add(cjguiComposableText(5, "position-review-visual", store.text,
            CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 270, fontSize: 16.0,
                pointerInteractive: true), resourceId: 103))
        return root
    }
    public func applyUiEvent(e: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(k: Int64, n: Int64): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
}

main(): Int64 {
    let c = PositionReviewController()
    let w = CjguiComposableUiWindow(c)
    let s = w.bindRangeTextSession(4, "position-review-body", c.store, c.store, 102, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    if (!w.start()) { return 2 }
    let _ = w.pump(4u32)
    if (let Some(onlyRestoreInterleave) <- getVariable("CJGUI_POSITION_REVIEW_ONLY_RESTORE_INTERLEAVE")) {
        if (onlyRestoreInterleave == "1") {
            // Keep this focused entry independent from the already-green
            // geometry checks below. It runs against the same accepted node,
            // session, and selection-restore machinery as the full probe.
            setVariable("CJGUI_SELECTION_RESTORE_REFUSE_ONCE", "0")
            let _ = w.focusAcceptedNodeById(4)
            let _ = w.refresh()
            let _ = w.pump(4u32)

            s.setSelection16(7, 10)
            let mappedTicket = w.freezeAcceptedSelection(5).getOrThrow()
            let mappedId = w.requestAcceptedSelectionRestore(mappedTicket, 7, 10, 7, 10,
                { => c.restored += 1 })
            let sameTicketGenericId = w.requestTextSelectionRestore(5, 103,
                CJGUI_COMPOSABLE_UI_TEXT, c.store.text, 7, 10)
            let staleProxyGenericId = w.requestTextSelectionRestore(5, 103,
                CJGUI_COMPOSABLE_UI_TEXT, c.store.text, 2, 2)
            let coalescedPending = mappedId >= 0 && sameTicketGenericId == mappedId &&
                staleProxyGenericId == mappedId && w.selectionRestoreState(mappedId) == "pending" &&
                s.selection16() == (7,10) && c.restored == 0
            w.pumpPendingSelectionRestore()
            let mappedInstalled = w.selectionRestoreState(mappedId) == "installed" &&
                s.selection16() == (7,10) && c.restored == 1
            w.pumpPendingSelectionRestore()
            let mappedExactlyOnce = c.restored == 1
            let mappedPass = coalescedPending && mappedInstalled && mappedExactlyOnce
            println("POSITION_REVIEW restore_interleave_same_ticket pass=${mappedPass} mapped_id=${mappedId} same_ticket_id=${sameTicketGenericId} stale_proxy_id=${staleProxyGenericId} state=${w.selectionRestoreState(mappedId)} selection=${s.selection16()[0]}:${s.selection16()[1]} callbacks=${c.restored} pending=${coalescedPending} installed=${mappedInstalled} exactly_once=${mappedExactlyOnce}")

            s.setSelection16(7, 10)
            let supersededTicket = w.freezeAcceptedSelection(5).getOrThrow()
            let supersededId = w.requestAcceptedSelectionRestore(supersededTicket, 7, 10, 7, 10,
                { => c.supersededRestored += 1 })
            s.setSelection16(2, 2)
            let currentSelectionId = w.requestTextSelectionRestore(5, 103,
                CJGUI_COMPOSABLE_UI_TEXT, c.store.text, 2, 2)
            let newerRequest = currentSelectionId >= 0 && currentSelectionId != supersededId &&
                w.selectionRestoreState(supersededId) == "superseded" && c.supersededRestored == 0
            w.pumpPendingSelectionRestore()
            let currentInstalled = w.selectionRestoreState(currentSelectionId) == "installed" &&
                s.selection16() == (2,2) && c.supersededRestored == 0 && c.restored == 1
            w.pumpPendingSelectionRestore()
            let newerExactlyOnce = c.supersededRestored == 0 && c.restored == 1
            let newerPass = newerRequest && currentInstalled && newerExactlyOnce
            println("POSITION_REVIEW restore_interleave_new_selection pass=${newerPass} old_id=${supersededId} new_id=${currentSelectionId} old_state=${w.selectionRestoreState(supersededId)} new_state=${w.selectionRestoreState(currentSelectionId)} selection=${s.selection16()[0]}:${s.selection16()[1]} callbacks=${c.restored} old_callbacks=${c.supersededRestored} superseded=${newerRequest} installed=${currentInstalled} exactly_once=${newerExactlyOnce}")
            let allPass = mappedPass && newerPass
            println("POSITION_REVIEW restore_interleave_only pass=${allPass} scenarios=2")
            w.close()
            return if (allPass) { 0 } else { 97 }
        }
    }
    let _ = w.focusAcceptedNodeById(4)
    let _ = w.refresh()
    let firstAcceptedCounts = w.positionWorkCounts()
    var boundary: Int64 = -1
    var oldY = -1.0
    var firstY = 0.0
    for (b in 0..Int64(c.store.text.toArray().size)) {
        let g = w.declareTextInteraction(4, b, b, w.contentVersionForGeometry(), w.layoutVersionForGeometry(), 1.0)
        if (g.available) {
            if (b == 0) { firstY = g.yPt }
            if (oldY >= 0.0 && g.yPt > oldY + 1.0) { boundary = b; break }
            oldY = g.yPt
        }
    }
    if (boundary < 0) { w.close(); return 3 }
    let firstQueryCounts = w.positionWorkCounts()
    let firstPrepared = firstAcceptedCounts[0] > 0 &&
        firstQueryCounts[2] > firstAcceptedCounts[2]
    println("POSITION_REVIEW first_accepted_prepare pass=${firstPrepared} scene=${w.windowProjection().acceptedSceneVersion} prepares=${firstAcceptedCounts[0]} queries=${firstAcceptedCounts[1]}:${firstQueryCounts[1]} line_builds=${firstAcceptedCounts[2]}:${firstQueryCounts[2]} cache_hits=${firstAcceptedCounts[3]}:${firstQueryCounts[3]} counter_scope=process timings=unavailable")
    let a = w.declareTextInteraction(4, boundary, boundary, w.contentVersionForGeometry(), w.layoutVersionForGeometry(), 1.0, affinity: 0u32)
    let b = w.declareTextInteraction(4, boundary, boundary, w.contentVersionForGeometry(), w.layoutVersionForGeometry(), 1.0, affinity: 1u32)
    // B's right-side preferred column lies beyond the short A's end. Up must
    // reach A's end, even when both stops project to the same source byte.
    let up = w.verticalMoveOnAcceptedLayout(4, boundary, false, preferredX: b.xPt + 120.0, expectedText: c.store.text, caretAffinity: 1u32)
    var sameByteUp = false
    match (up) {
        case Ready(byte, _, side) => sameByteUp = byte == boundary && side == 0u32
        case _ => ()
    }
    println("POSITION_REVIEW short_wrap_up pass=${sameByteUp} boundary=${boundary} a_y=${a.yPt} b_y=${b.yPt} first_y=${firstY}")
    // Establish an upstream stop by Left, then install a person's selection
    // at B start. The next Right must match a direct click at the same place.
    s.setSelection16(boundary, boundary)
    let _ = w.handlePlainHorizontalIntent(true, false)
    s.setSelection16(boundary, boundary)
    let _ = w.handlePlainHorizontalIntent(false, false)
    let historical = s.selection16()
    w.invalidatePlainPositionBranch()
    s.setSelection16(boundary, boundary)
    let _ = w.handlePlainHorizontalIntent(false, false)
    let direct = s.selection16()
    let historyIndependent = historical == direct && direct[0] > boundary
    println("POSITION_REVIEW click_after_left pass=${historyIndependent} historical=${historical[0]}:${historical[1]} direct=${direct[0]}:${direct[1]}")
    let countsBefore = w.positionWorkCounts()
    for (_ in 0..100) {
        let _ = w.verticalMoveOnAcceptedLayout(4, boundary, false,
            preferredX: b.xPt + 120.0, expectedText: c.store.text, caretAffinity: 1u32)
    }
    let countsAfter = w.positionWorkCounts()
    let reused = countsAfter[0] == countsBefore[0] && countsAfter[2] == countsBefore[2] &&
        countsAfter[1] > countsBefore[1] && countsAfter[3] > countsBefore[3]
    println("POSITION_REVIEW repeated_accepted_queries pass=${reused} prepares=${countsBefore[0]}:${countsAfter[0]} queries=${countsBefore[1]}:${countsAfter[1]} line_builds=${countsBefore[2]}:${countsAfter[2]} cache_hits=${countsBefore[3]}:${countsAfter[3]} timings=unavailable")

    // The first native installation fails before changing selection; a later
    // host turn must complete the exact same pending request exactly once.
    s.setSelection16(7, 10)
    let ticket = w.freezeAcceptedSelection(5).getOrThrow()
    setVariable("CJGUI_SELECTION_RESTORE_REFUSE_ONCE", "1")
    let request = w.requestAcceptedSelectionRestore(ticket, 7, 10, 7, 10, { => c.restored += 1 })
    w.pumpPendingSelectionRestore()
    let kept = w.selectionRestoreState(request) == "pending" && c.restored == 0 && s.selection16() == (7,10)
    w.pumpPendingSelectionRestore()
    let installed = w.selectionRestoreState(request) == "installed" && c.restored == 1 && s.selection16() == (7,10)
    w.pumpPendingSelectionRestore()
    let exactlyOnce = c.restored == 1
    println("POSITION_REVIEW restore_native_refusal pass=${kept && installed && exactlyOnce} retained=${kept} installed=${installed} callbacks=${c.restored}")

    // An old request cannot overwrite a newer same-value selection (ABA).
    let newTicket = w.freezeAcceptedSelection(5).getOrThrow()
    let oldRequest = w.requestAcceptedSelectionRestore(newTicket, 7, 10, 7, 10, { => c.restored += 100 })
    s.setSelection16(2, 2)
    s.setSelection16(7, 10)
    w.pumpPendingSelectionRestore()
    let aba = w.selectionRestoreState(oldRequest) == "identity_superseded" && c.restored == 1 && s.selection16() == (7,10)
    println("POSITION_REVIEW restore_old_choice pass=${aba} state=${w.selectionRestoreState(oldRequest)} callbacks=${c.restored}")

    let bindingTicket = w.freezeAcceptedSelection(5).getOrThrow()
    let bindingRequest = w.requestAcceptedSelectionRestore(bindingTicket, 7, 10, 7, 10, { => c.restored += 100 })
    let replacement = PositionReviewStore()
    let newSession = w.bindRangeTextSession(4, "position-review-body", replacement, replacement, 102, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
    newSession.setSelection16(1, 1)
    w.pumpPendingSelectionRestore()
    let rebound = w.selectionRestoreState(bindingRequest) == "identity_superseded" && c.restored == 1 && newSession.selection16() == (1,1)
    println("POSITION_REVIEW restore_same_node_rebind pass=${rebound} state=${w.selectionRestoreState(bindingRequest)} callbacks=${c.restored}")
    // A same-value external owner write advances the mirror ticket without
    // changing any scene bytes. Recovery must still complete on the host pump.
    let _ = w.focusAcceptedNodeById(4)
    replacement.version += 1
    let _ = newSession.refreshMirror()
    let needsRestore = newSession.needsNativeSelectionRestore()
    let sceneBefore = w.windowProjection().acceptedSceneVersion
    let _ = w.pump(4u32)
    let restoredUnchanged = needsRestore && !newSession.needsNativeSelectionRestore() &&
        newSession.selection16() == (1,1) && w.windowProjection().acceptedSceneVersion == sceneBefore
    println("POSITION_REVIEW restore_same_value_owner pass=${restoredUnchanged} pending_before=${needsRestore} pending_after=${newSession.needsNativeSelectionRestore()} scene=${sceneBefore}:${w.windowProjection().acceptedSceneVersion}")
    w.close()
    return if (firstPrepared && sameByteUp && historyIndependent && reused && kept && installed && exactlyOnce && aba && rebound && restoredUnchanged) { 0 } else { 97 }
}

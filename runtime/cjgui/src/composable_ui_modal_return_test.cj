package cjgui

import std.collection.ArrayList

import std.unittest.*
import std.unittest.testmacro.*

// Source/sink used around a closing modal. It exposes the same owner
// selection seam the native text session uses, so a preparation-time write
// would be visible as an extra setSourceSelection.
private class ModalReturnRejectingOwner <: CjguiRangeTextSource & CjguiRangeTextEditSink &
    CjguiRangeTextSelectionOwner {
    var textValue: String
    var versionValue: Int64 = 1
    var selectionVersionValue: Int64 = 1
    var revisionValue: Int64 = 1
    var anchorValue: Int64 = 2
    var focusValue: Int64 = 4
    var selectionWrites: Int64 = 0

    init(text: String) {
        this.textValue = text
    }

    public func rangeTextVersion(): Int64 { return this.versionValue }
    public func confirmRangeTextVersion(expectedVersion: Int64, action: () -> Bool): Bool {
        if (this.versionValue != expectedVersion) { return false }
        return action()
    }
    public func rebaseRangeTextSelection(fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        return None
    }
    public func rangeTextByteLength(): Int64 {
        return Int64(this.textValue.toArray().size)
    }
    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        let bytes = this.textValue.toArray()
        var start = if (startByte < 0) { 0 } else { startByte }
        if (start > bytes.size) { start = bytes.size }
        let cap = Int64(bytes.size - start)
        let take = if (maxBytes < cap) { maxBytes } else { cap }
        return CjguiRangeTextSlice(startByte, start, String.fromUtf8(bytes.slice(start, take)),
            this.versionValue, Int64(bytes.size), true, "")
    }
    public func applyRangeTextEdit(baseVersion: Int64, startByte: Int64, endByte: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        return CjguiRangeTextEditOutcome.rejected(baseVersion, "test_fixture")
    }
    public func sourceSelectionSnapshot(): CjguiSourceSelectionSnapshot {
        return CjguiSourceSelectionSnapshot(this.selectionVersionValue, this.revisionValue,
            this.anchorValue, this.focusValue)
    }
    public func setSourceSelection(version: Int64, anchorByte: Int64, focusByte: Int64): Bool {
        this.selectionWrites += 1
        let total = Int64(this.textValue.toArray().size)
        if (version != this.versionValue || anchorByte < 0 || focusByte < 0 ||
            anchorByte > total || focusByte > total) { return false }
        this.anchorValue = anchorByte
        this.focusValue = focusByte
        this.selectionVersionValue = version
        this.revisionValue += 1
        return true
    }
    public func reserveSourceSelection(version: Int64, expectedRevision: Int64,
        anchorByte: Int64, focusByte: Int64, decision: CjguiSelectionDecision): Int64 {
        return -1
    }
    public func settleSourceSelection(revision: Int64): Unit {}

    /// Owner-side whole replacement; the owner selection intentionally stays on
    /// the old version so no valid mapping exists for the closed candidate.
    public func externalWholeValue(text: String): Unit {
        this.textValue = text
        this.versionValue += 1
    }
}

// Ownerless adapter policy mirroring `CjguiGeneratedFieldRangeSession`: a
// whole-value replacement names the end; another field's version move keeps
// the existing byte range.
private class ModalReturnAdapterPolicySource <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    var textValue: String
    var versionValue: Int64 = 1
    let publishedBodies: ArrayList<(Int64, String)> = ArrayList<(Int64, String)>()

    init(text: String) {
        this.textValue = text
    }

    public func rangeTextVersion(): Int64 { return this.versionValue }
    public func confirmRangeTextVersion(expectedVersion: Int64, action: () -> Bool): Bool {
        if (this.versionValue != expectedVersion) { return false }
        return action()
    }
    public func rangeTextByteLength(): Int64 {
        return Int64(this.textValue.toArray().size)
    }
    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        let bytes = this.textValue.toArray()
        this.rememberBody(this.versionValue, this.textValue)
        var start = if (startByte < 0) { 0 } else { startByte }
        if (start > bytes.size) { start = bytes.size }
        let cap = Int64(bytes.size - start)
        let take = if (maxBytes < cap) { maxBytes } else { cap }
        return CjguiRangeTextSlice(startByte, start, String.fromUtf8(bytes.slice(start, take)),
            this.versionValue, Int64(bytes.size), true, "")
    }
    public func rebaseRangeTextSelection(fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        if (this.versionValue == fromVersion) {
            return Some((fromVersion, startByte, endByte))
        }
        if (this.versionValue < fromVersion) { return None }
        var previous: ?String = None
        for (entry in this.publishedBodies) {
            if (entry[0] == fromVersion) { previous = Some(entry[1]) }
        }
        if (let Some(old) <- previous) {
            let currentBytes = Int64(this.textValue.toArray().size)
            if (this.textValue != old) {
                return Some((this.versionValue, currentBytes, currentBytes))
            }
            if (startByte >= 0 && endByte >= startByte && endByte <= currentBytes) {
                return Some((this.versionValue, startByte, endByte))
            }
        }
        return None
    }
    public func applyRangeTextEdit(baseVersion: Int64, startByte: Int64, endByte: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        return CjguiRangeTextEditOutcome.rejected(baseVersion, "test_fixture")
    }
    public func externalWholeValue(text: String): Unit {
        this.textValue = text
        this.versionValue += 1
    }

    private func rememberBody(version: Int64, body: String): Unit {
        var index: Int64 = 0
        while (index < this.publishedBodies.size) {
            if (this.publishedBodies[index][0] == version) {
                this.publishedBodies[index] = (version, body)
                return
            }
            index += 1
        }
        this.publishedBodies.add((version, body))
        while (this.publishedBodies.size > 4) {
            let _ = this.publishedBodies.remove(at: 0)
        }
    }
}

private func modalReturnOwnedRoot(): CjguiComposableUiNode {
    return cjguiComposableVertical(1, "return-root", CjguiComposableUiStyle(fixedWidth: 400, fixedHeight: 200))
}

private func modalReturnOwnedScene(value: String, resourceId!: Int64 = 9123,
    readOnly!: Bool = false): CjguiComposableUiScene {
    let nodes = ArrayList<CjguiComposableUiLayoutNode>()
    let input = cjguiComposableTextInput(9901, "return-body", "Endpoint", value, resourceId,
        CjguiComposableUiStyle(fixedWidth: 320, fixedHeight: 32), readOnly: readOnly)
    nodes.add(CjguiComposableUiLayoutNode(input, CjguiComposableUiRect(10, 10, 320, 32),
        CjguiComposableUiRect(0, 0, 400, 200)))
    return CjguiComposableUiScene(2, CjguiComposableUiRect(0, 0, 400, 200), nodes)
}

@Test
func ownedModalReturnCoordinatesTheAdapterChoiceBeforeItsBasis(): Unit {
    let window = CjguiComposableUiWindow(ModalReturnCarrierTestController())
    let source = ModalReturnAdapterPolicySource("https://api.example.com/v")
    let session = window.bindRangeTextSession(9901, "return-body", source, source, 9123,
        CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    session.setSelection16(12, 14)
    let oldScene = modalReturnOwnedScene("https://api.example.com/v")
    let newScene = modalReturnOwnedScene("https://api.example.com/v2")
    source.externalWholeValue("https://api.example.com/v2")
    let facts = window.testOwnedModalReturnRejectedCandidateFacts(modalReturnOwnedRoot(),
        oldScene, newScene, 9901)
    @Assert(facts.size, 8)
    @Assert(facts[0], "true")
    @Assert(facts[1], "26:26")
    @Assert(facts[2], "true")
    @Assert(facts[3], "26:26")
    @Assert(facts[4], "")
    @Assert(facts[5], "true")
    @Assert(facts[6], "true")
    @Assert(facts[7], "test_candidate_rejected")
}

@Test
func ownedModalReturnRejectedCandidateDoesNotWriteOwnerSelection(): Unit {
    let window = CjguiComposableUiWindow(ModalReturnCarrierTestController())
    let owner = ModalReturnRejectingOwner("abcdef")
    let session = window.bindRangeTextSession(9901, "return-body", owner, owner, 9123,
        CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    // Baseline choice from the normal owner seam, not from candidate preparation.
    session.setSelection16(2, 4)
    @Assert(owner.selectionWrites, 1)
    @Assert(owner.anchorValue, 2)
    @Assert(owner.focusValue, 4)
    owner.externalWholeValue("abcdefgh")
    let facts = window.testOwnedModalReturnRejectedCandidateFacts(modalReturnOwnedRoot(),
        modalReturnOwnedScene("abcdef"), modalReturnOwnedScene("abcdefgh"), 9901)
    @Assert(facts.size, 8)
    @Assert(facts[0], "true")
    @Assert(facts[2], "false")
    @Assert(facts[3], "none")
    @Assert(facts[4], "no_intent")
    @Assert(facts[5], "false")
    // The candidate's own rejection path must not invalidate the basis that was
    // frozen before preparation either.
    @Assert(facts[6], "true")
    @Assert(facts[7], "owned_selection_unavailable")
    @Assert(owner.selectionWrites, 1)
    @Assert(owner.anchorValue, 2)
    @Assert(owner.focusValue, 4)
    @Assert(owner.selectionVersionValue, 1)
    @Assert(owner.textValue, "abcdefgh")
}

@Test
func ownedModalReturnTargetRejectionKeepsTheValidBasisAndOwnerSelection(): Unit {
    let window = CjguiComposableUiWindow(ModalReturnCarrierTestController())
    let owner = ModalReturnRejectingOwner("abcdef")
    let session = window.bindRangeTextSession(9901, "return-body", owner, owner, 9123,
        CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    session.setSelection16(2, 4)
    @Assert(owner.selectionWrites, 1)
    let facts = window.testOwnedModalReturnRejectedCandidateFacts(modalReturnOwnedRoot(),
        modalReturnOwnedScene("abcdef"), modalReturnOwnedScene("abcdef", readOnly: true), 9901)
    @Assert(facts.size, 8)
    @Assert(facts[0], "true")
    @Assert(facts[1], "2:4")
    @Assert(facts[2], "true")
    @Assert(facts[3], "none")
    @Assert(facts[4], "no_intent")
    @Assert(facts[5], "false")
    @Assert(facts[6], "true")
    @Assert(facts[7], "target_changed")
    @Assert(owner.selectionWrites, 1)
    @Assert(owner.anchorValue, 2)
    @Assert(owner.focusValue, 4)
}

private class ModalReturnCarrierTestController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 0 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableVertical(1, "modal-return-test", CjguiComposableUiStyle())
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false, shouldClose: true)
    }
}

@Test
func ordinaryModalReturnWithoutBookmarkDoesNotBlockClosingSceneOrInventSelection(): Unit {
    let window = CjguiComposableUiWindow(ModalReturnCarrierTestController())
    let facts = window.testOrdinaryModalReturnWithoutBookmark()
    @Assert(facts.size, 7)
    @Assert(facts[0], "none")
    @Assert(facts[1], "none")
    @Assert(facts[2], "bookmark_unavailable")
    @Assert(facts[3], "false")
    @Assert(facts[4], "-1")
    @Assert(facts[5], "3:5")
    @Assert(facts[6], "bookmark_unavailable")
}

@Test
func ordinaryModalReturnMissingBookmarkCannotHideChangedOwner(): Unit {
    let window = CjguiComposableUiWindow(ModalReturnCarrierTestController())
    let facts = window.testOrdinaryModalReturnWithoutBookmark(targetChanged: true)
    @Assert(facts.size, 7)
    @Assert(facts[0], "present")
    @Assert(facts[1], "target_changed")
    @Assert(facts[2], "pending")
    @Assert(facts[3], "true")
    @Assert(facts[5], "3:5")
    @Assert(facts[6], "target_changed")
}

@Test
func modalReturnKeepsOneRequestAcrossUnsubmittedInputRebuildsAndRefusesRebind(): Unit {
    let window = CjguiComposableUiWindow(ModalReturnCarrierTestController())
    let facts = window.testModalReturnCarrierRebuild()
    @Assert(facts.size, 8)
    @Assert(facts[0], "true")
    @Assert(facts[1], "0:2")
    @Assert(facts[2], "pending")
    @Assert(facts[3], "true")
    @Assert(facts[4], "0:2")
    @Assert(facts[5], "pending")
    @Assert(facts[6], "binding_changed")
    @Assert(facts[7], "binding_changed")
}

@Test
func modalReturnOldCarrierReceiptCannotCompleteReplacementOrOverwriteInstalled(): Unit {
    let window = CjguiComposableUiWindow(ModalReturnCarrierTestController())
    let facts = window.testModalReturnCarrierRebuild(rebind: false)
    @Assert(facts.size, 12)
    @Assert(facts[2], "pending")
    @Assert(facts[3], "true")
    @Assert(facts[5], "pending")
    @Assert(facts[6], "false")
    @Assert(facts[7], "pending")
    @Assert(facts[8], "true")
    @Assert(facts[9], "false")
    @Assert(facts[10], "installed")
    @Assert(facts[11], "0:2")
}

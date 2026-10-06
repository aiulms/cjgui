package cjgui
import std.unittest.*
import std.unittest.testmacro.*

@Test
func acceptedRangeRecordsExactOwnerMirrorInsteadOfInsertedFragment(): Unit {
    let w = RangeWindowHarness()
    let first = InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32)
    @Assert(w.commit(first, ""))
    @Assert(w.owner.text(), "a Z")
    @Assert(w.owner.writeCalls, 1)
    @Assert(w.pendingLocalTextNodeId, 107)
    @Assert(w.pendingLocalTextValue, "a Z")
    @Assert(w.pendingLocalTextOwnerRevision, 2)
}

@Test
func queuedOldProjectionRangeContinuesOnlyOwnerAcceptedChain(): Unit {
    let w = RangeWindowHarness()
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    w.nativeInputScene = HarnessScene(2, "a Z")
    let next = w.resolveLocalTextContinuation(51, 107, 77,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "l", 1, selectionRange: (1, 1))
    @Assert(next.nodeId, 107)
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 1u32), "l"))
    @Assert(w.owner.text(), "al Z")
    @Assert(w.owner.writeCalls, 2)
}

@Test
func actualSessionRejectsExternalOwnerBetweenQueuedRangeEvents(): Unit {
    let w = RangeWindowHarness()
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    w.nativeInputScene = HarnessScene(2, "a Z")
    w.owner.bumpVersionOnly()
    let next = w.resolveLocalTextContinuation(51, 107, 77,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "l", 1, selectionRange: (1, 1))
    @Assert(next.nodeId, -1)
    @Assert(!w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 1u32), "l"))
    @Assert(w.owner.text(), "a Z")
    @Assert(w.owner.ver, 3)
    @Assert(w.textSessionAcceptedEdits, 1)
    @Assert(w.textSessionRefusedEdits, 1)
}

@Test
func rangeInsertedFragmentEqualToWholeMirrorIsStillARealDelta(): Unit {
    let w = RangeWindowHarness(text: "aaa")
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 2u32), ""))
    @Assert(w.owner.text(), "aa")
    w.nativeInputScene = HarnessScene(2, "aa")
    let next = w.resolveLocalTextContinuation(51, 107, 77,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "aa", 1, selectionRange: (2, 2))
    @Assert(next.nodeId, 107)
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 1u32), "aa"))
    @Assert(w.owner.text(), "aaaa")
    @Assert(w.owner.writeCalls, 2)
}

@Test
func bindingMismatchDoesNotWriteOwnerOrCountAccepted(): Unit {
    let w = RangeWindowHarness()
    @Assert(!w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32, epoch: 2u64), ""))
    @Assert(w.owner.text(), "alpha Z")
    @Assert(w.owner.writeCalls, 0)
    @Assert(w.textSessionAcceptedEdits, 0)
    @Assert(w.textSessionRefusedEdits, 1)
}

@Test
func blurCancelsTheLocalContinuationCredential(): Unit {
    let w = RangeWindowHarness()
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    w.nativeInputScene = HarnessScene(2, "a Z")
    w.clearLocalTextContinuation()
    let next = w.resolveLocalTextContinuation(51, 107, 77,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "l", 1, selectionRange: (1, 1))
    @Assert(next.nodeId, -1)
}

@Test
func severalAcceptedScenesRetainTheSameQueuedRangeOrigin(): Unit {
    let w = RangeWindowHarness()
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    w.nativeInputScene = HarnessScene(2, "a Z")
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 1u32), "l"))
    w.nativeInputScene = HarnessScene(3, "al Z")
    let next = w.resolveLocalTextContinuation(51, 107, 77,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "p", 1, selectionRange: (2, 2))
    @Assert(next.nodeId, 107)
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 2u32, 2u32), "p"))
    @Assert(w.owner.text(), "alp Z")
    @Assert(w.owner.writeCalls, 3)
}

@Test
func firstRefusalDoesNotEstablishLocalContinuationOrAcceptRemainder(): Unit {
    let w = RangeWindowHarness()
    w.owner.rejectAll = true
    @Assert(!w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    @Assert(w.ownedRangeLocalContinuation.isNone())
    @Assert(!w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 1u32), "l"))
    @Assert(w.owner.text(), "alpha Z")
    @Assert(w.owner.writeCalls, 1)
    @Assert(w.textSessionAcceptedEdits, 0)
    @Assert(w.textSessionRefusedEdits, 2)
}

@Test
func externalDifferentValueRevokesTheSameQueuedRangeOrigin(): Unit {
    let w = RangeWindowHarness()
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    w.nativeInputScene = HarnessScene(2, "a Z")
    w.owner.externalWrite(0, 0, "Agent:")
    let next = w.resolveLocalTextContinuation(51, 107, 77,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "l", 1, selectionRange: (1, 1))
    @Assert(next.nodeId, -1)
    @Assert(!w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 1u32), "l"))
    @Assert(w.owner.text(), "Agent:a Z")
    @Assert(w.owner.ver, 3)
}

@Test
func newLocalOriginCannotAdmitEarlierOrFutureProjection(): Unit {
    let w = RangeWindowHarness()
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    w.clearLocalTextContinuation()
    w.nativeInputScene = HarnessScene(10, "a Z")
    @Assert(w.commit(InternalRendererPumpResult(51u32, 10u64, 1u32, 1u32), "l"))
    w.nativeInputScene = HarnessScene(11, "al Z")
    let old = w.resolveLocalTextContinuation(51, 107, 77,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "p", 1, selectionRange: (2, 2))
    let future = w.resolveLocalTextContinuation(51, 107, 77,
        CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, "p", 12, selectionRange: (2, 2))
    @Assert(old.nodeId, -1)
    @Assert(future.nodeId, -1)
}

@Test
func ownerNormalizationMustReconcileInsteadOfPreservingNativeFragment(): Unit {
    let w = RangeWindowHarness()
    w.owner.normalizeNext = true
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 0u32, 5u32), "local"))
    @Assert(w.owner.text(), "normalized Z")
    @Assert(w.ownedRangeLocalContinuation.isNone())
    @Assert(w.pendingLocalTextNodeId, -1)
}

@Test
func actualSelectionAfterQueuedEditMustReachTheWindowLedger(): Unit {
    let w = RangeWindowHarness()
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    w.nativeInputScene = HarnessScene(2, "a Z")
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 1u32), "l"))
    w.nativeInputScene = HarnessScene(3, "al Z")
    let before = w.owner.ver
    @Assert(w.select(InternalRendererPumpResult(33u32, 2u64, 2u32, 2u32), "al Z"))
    @Assert(w.observedStart, 2)
    @Assert(w.observedEnd, 2)
    @Assert(w.owner.ver, before)
    @Assert(w.owner.writeCalls, 2)
}

@Test
func oldNativeContextWithSameBindingAndProjectionCannotSelect(): Unit {
    let w = RangeWindowHarness()
    @Assert(!w.select(InternalRendererPumpResult(33u32, 1u64, 2u32, 2u32, status: 1u32), "alpha Z"))
    @Assert(w.observedStart, 0)
    @Assert(w.owner.writeCalls, 0)
}

@Test
func selectionForEarlierPostimageCannotOverrideCurrentMirror(): Unit {
    let w = RangeWindowHarness()
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    w.nativeInputScene = HarnessScene(2, "a Z")
    @Assert(!w.select(InternalRendererPumpResult(33u32, 2u64, 2u32, 2u32), "alpha Z"))
    @Assert(w.observedStart, 0)
    @Assert(w.owner.text(), "a Z")
}

@Test
func actualSelectionDoesNotUseAmbiguousDiffEndpoint(): Unit {
    let w = RangeWindowHarness(text: "aaa")
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 3u32, 3u32), "a"))
    w.nativeInputScene = HarnessScene(2, "aaaa")
    @Assert(w.select(InternalRendererPumpResult(33u32, 1u64, 1u32, 1u32), "aaaa"))
    @Assert(w.observedStart, 1)
    let (a, b) = w.ownedTextSession.getOrThrow().selection16()
    @Assert(a, 1)
    @Assert(b, 1)
    @Assert(w.owner.ver, 2)
}

@Test
func sameTextExternalOwnerVersionCannotAuthorizeSelection(): Unit {
    let w = RangeWindowHarness()
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    w.nativeInputScene = HarnessScene(2, "a Z")
    w.owner.bumpVersionOnly()
    @Assert(!w.select(InternalRendererPumpResult(33u32, 1u64, 2u32, 2u32), "a Z"))
    @Assert(w.observedStart, 0)
    @Assert(w.owner.ver, 3)
}

@Test
func outOfBoundsSelectionCannotBeClampedIntoAuthority(): Unit {
    let w = RangeWindowHarness()
    @Assert(!w.select(InternalRendererPumpResult(33u32, 1u64, 0u32, 30u32), "alpha Z"))
    @Assert(w.observedStart, 0)
    @Assert(w.owner.writeCalls, 0)
}

@Test
func selectionContinuationRequiresUnrevokedLocalOrigin(): Unit {
    let w = RangeWindowHarness()
    @Assert(w.commit(InternalRendererPumpResult(51u32, 1u64, 1u32, 5u32), ""))
    w.nativeInputScene = HarnessScene(2, "a Z")
    // 现行契约（owned 锚点同权）：身份与当前 accepted 场景严格相符的选区回声
    // 不经本地续写凭据——正控先证该回声可被严格路径解析。
    @Assert(w.select(InternalRendererPumpResult(33u32, 1u64, 2u32, 2u32), "a Z"))
    w.nativeInputScene = HarnessScene(2, "a Z")
    w.clearLocalTextContinuation()
    // 非严格事件（落后一代，只能走本地续写）：凭据已撤 ⇒ 必须拒绝。
    @Assert(!w.select(InternalRendererPumpResult(33u32, 1u64, 2u32, 1u32), "a Z"))
}

package cjgui
import std.unittest.*
import std.unittest.testmacro.*

@Test
func verifiedOldProxyPostimageContinuesAfterCrossWindowReplacement(): Unit {
    let w=RangeWindowHarness(wide: true)
    let s=w.ownedTextSession.getOrThrow()
    @Assert(s.mirrorText(), ":TAIL")
    let basis=s.ohosInputSourceBasis()
    testInputOrigin=Some(CjguiOhosInputTicketFact(71,0,"mount",basis,":TAIL","中:TAIL","body",choiceBasis:basis,observation:17,node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:0,end16:0,inserted:"中"))
    @Assert(w.commit(InternalRendererPumpResult(51u32,1u64,0u32,0u32),"中"))
    @Assert(w.owner.text(),"HEAD:中:TAIL")
    @Assert(w.lastAcceptedOhosPostOrigin,5)
    @Assert(s.mirrorText() != "中:TAIL")
    testInputOrigin=Some(CjguiOhosInputTicketFact(72,71,"mount",basis,"中:TAIL","中续:TAIL","body",choiceBasis:basis,observation:17,node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:1,end16:1,inserted:"续"))
    @Assert(w.commit(InternalRendererPumpResult(51u32,1u64,1u32,1u32),"续"))
    @Assert(w.owner.text(),"HEAD:中续:TAIL")
    @Assert(w.owner.writeCalls,2)
    @Assert(w.owner.maxReadBytes<=32)
}

@Test
func normalizedOwnerPostimageCannotAcquireSuccessorMapping(): Unit {
    let w=RangeWindowHarness(wide:true)
    let s=w.ownedTextSession.getOrThrow();let basis=s.ohosInputSourceBasis()
    w.owner.normalizeNext=true
    testInputOrigin=Some(CjguiOhosInputTicketFact(71,0,"mount",basis,":TAIL","中:TAIL","body",choiceBasis:basis,observation:17,node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:0,end16:0,inserted:"中"))
    @Assert(w.commit(InternalRendererPumpResult(51u32,1u64,0u32,0u32),"中"))
    @Assert(w.lastAcceptedOhosPostOrigin,-1)
    testInputOrigin=Some(CjguiOhosInputTicketFact(72,71,"mount",basis,"中:TAIL","中续:TAIL","body",choiceBasis:basis,observation:17,node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:1,end16:1,inserted:"续"))
    @Assert(!w.commit(InternalRendererPumpResult(51u32,1u64,1u32,1u32),"续"))
    @Assert(w.owner.writeCalls,1)
}

@Test
func resolvedObservationCannotBorrowAnotherChoiceOrExternalVersion(): Unit {
    let w=RangeWindowHarness();let s=w.ownedTextSession.getOrThrow();let basis=s.ohosInputSourceBasis()
    testInputOrigin=Some(CjguiOhosInputTicketFact(1,0,"mount",basis,"alpha Z","a Z","body",observation:17,node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:1,end16:5,inserted:""))
    @Assert(!w.commit(InternalRendererPumpResult(51u32,1u64,1u32,5u32),""))
    @Assert(w.owner.writeCalls,0)
    testInputOrigin=Some(CjguiOhosInputTicketFact(2,0,"mount",basis,"alpha Z","a Z","body",choiceBasis:basis,observation:18,node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:1,end16:5,inserted:""))
    @Assert(w.commit(InternalRendererPumpResult(51u32,1u64,1u32,5u32),""))
    w.owner.bumpVersionOnly()
    testInputOrigin=Some(CjguiOhosInputTicketFact(3,2,"mount",basis,"a Z","ax Z","body",choiceBasis:basis,observation:18,node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:1,end16:1,inserted:"x"))
    @Assert(!w.commit(InternalRendererPumpResult(51u32,1u64,1u32,1u32),"x"))
    @Assert(w.owner.writeCalls,1)
}

@Test
func frozenInputUsesActualRangeAndOneOwnerChain(): Unit {
    let w = RangeWindowHarness(text: "ABABAB")
    let session = w.ownedTextSession.getOrThrow()
    let basis = session.ohosInputSourceBasis()
    testInputOrigin = Some(CjguiOhosInputTicketFact(1,0,"exact-mount",basis,"ABABAB","ABABABAB","body",node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:0,end16:6,inserted:"ABABABAB"))
    @Assert(w.commit(InternalRendererPumpResult(51u32,1u64,0u32,6u32),"ABABABAB"))
    @Assert(w.owner.text(),"ABABABAB")
    @Assert(w.owner.writeCalls,1)
    testInputOrigin = Some(CjguiOhosInputTicketFact(2,1,"exact-mount",basis,"ABABABAB","ABABABABX","body",node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:8,end16:8,inserted:"X"))
    @Assert(w.commit(InternalRendererPumpResult(51u32,1u64,8u32,8u32),"X"))
    @Assert(w.owner.text(),"ABABABABX")
    @Assert(w.owner.writeCalls,2)
}

@Test
func identicalBytesNewOwnerVersionCannotReviveFrozenInput(): Unit {
    let w = RangeWindowHarness()
    let basis = w.ownedTextSession.getOrThrow().ohosInputSourceBasis()
    testInputOrigin = Some(CjguiOhosInputTicketFact(1,0,"exact-mount",basis,"alpha Z","a Z","body",node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:1,end16:5,inserted:""))
    w.owner.ver += 1
    @Assert(!w.commit(InternalRendererPumpResult(51u32,1u64,1u32,5u32),""))
    @Assert(w.owner.writeCalls,0)
    @Assert(w.lastTextSessionDecision.getOrThrow().reason,"input_source_ticket_stale")
}

@Test
func choiceRevisionChangeCannotReuseSameTextInputCoordinates(): Unit {
    let w = RangeWindowHarness()
    let session = w.ownedTextSession.getOrThrow()
    let basis = session.ohosInputSourceBasis()
    testInputOrigin = Some(CjguiOhosInputTicketFact(1,0,"exact-mount",basis,"alpha Z","a Z","body",node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:1,end16:5,inserted:""))
    session.setSelection16(1,1)
    @Assert(!w.commit(InternalRendererPumpResult(51u32,1u64,1u32,5u32),""))
    @Assert(w.owner.writeCalls,0)
}

@Test
func oldMountFactAndRepeatedTicketHaveNoSecondOwnerWrite(): Unit {
    let w = RangeWindowHarness()
    let basis = w.ownedTextSession.getOrThrow().ohosInputSourceBasis()
    testInputOrigin = Some(CjguiOhosInputTicketFact(1,0,"exact-mount",basis,"alpha Z","a Z","body",node:107,resource:77,nodeKind:CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT,ownerBinding:3u64,acceptedBinding:3u64,projection:1u64,start16:1,end16:5,inserted:""))
    @Assert(!w.commit(InternalRendererPumpResult(51u32,1u64,1u32,5u32,status:1u32),""))
    @Assert(w.owner.writeCalls,0)
    @Assert(w.commit(InternalRendererPumpResult(51u32,1u64,1u32,5u32),""))
    @Assert(!w.commit(InternalRendererPumpResult(51u32,1u64,1u32,5u32),""))
    @Assert(w.owner.writeCalls,1)
}

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

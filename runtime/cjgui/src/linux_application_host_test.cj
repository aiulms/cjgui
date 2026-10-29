package cjgui

/// Minimal controller surface for lifecycle-only host tests. It never draws
/// and never starts a native session; the host's inert seam models the one
/// fact under test (a close that has not settled yet).
private class LinuxHostGroupTestController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableVertical(1, "linux-host-group-test", CjguiComposableUiStyle())
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

/// Escaping factories cannot capture mutable locals; they capture this holder
/// and update its fields instead.
@When[os == "Linux"]
private class LinuxHostGroupTestFacts {
    public var factoryCalls: Int64 = 0
    public var childCalls: Int64 = 0
    public var request: ?CjguiLinuxWindowRequest = None
    public var childRequest: ?CjguiLinuxWindowRequest = None
    public var pumpResult: Bool = false
}

@When[os == "Linux"]
private func linuxTestHost(): CjguiLinuxApplicationHost {
    let host = CjguiLinuxApplicationHost(LinuxHostGroupTestController())
    host.startInertForTest()
    return host
}

@When[os == "Linux"]
private func linuxTestRequestStatus(request: CjguiLinuxWindowRequest, expected: CjguiLinuxWindowRequestStatus): Bool {
    match (request.status()) {
        case CjguiLinuxWindowRequestStatus.Pending =>
            return match (expected) {
                case CjguiLinuxWindowRequestStatus.Pending => true
                case _ => false
            }
        case CjguiLinuxWindowRequestStatus.Applied =>
            return match (expected) {
                case CjguiLinuxWindowRequestStatus.Applied => true
                case _ => false
            }
        case CjguiLinuxWindowRequestStatus.Failed =>
            return match (expected) {
                case CjguiLinuxWindowRequestStatus.Failed => true
                case _ => false
            }
        case CjguiLinuxWindowRequestStatus.Superseded =>
            return match (expected) {
                case CjguiLinuxWindowRequestStatus.Superseded => true
                case _ => false
            }
    }
}

@When[os == "Linux"]
@Test
func testLinuxGroupRetainsPendingCloseUntilItSettles(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let facts = LinuxHostGroupTestFacts()
    let open = group.requestOpen("pending", { _ =>
        facts.factoryCalls += 1
        let host = linuxTestHost()
        host.holdInertCloseForTest()
        host
    })
    @Assert(linuxTestRequestStatus(open, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(group.count(), 1)
    let windowId = open.windowId
    let close = group.requestClose(windowId)
    @Assert(linuxTestRequestStatus(close, CjguiLinuxWindowRequestStatus.Pending), true)
    let duplicateClose = group.requestClose(windowId)
    @Assert(linuxTestRequestStatus(duplicateClose, CjguiLinuxWindowRequestStatus.Pending), true)
    @Assert(duplicateClose.message(), "close_queued")
    // A retained close keeps the host/controller/region and does not release
    // anything; the request stays Pending across owner turns.
    for (_ in 0..3) {
        let _ = group.pumpOneTurn(maximumIdleWaitMs: 0u32)
        @Assert(group.count(), 1)
        @Assert(linuxTestRequestStatus(close, CjguiLinuxWindowRequestStatus.Pending), true)
    }
    // The settlement finally completes; exactly one host leaves the group and
    // the request becomes Applied once.
    match (group.windowById(windowId)) {
        case Some(host) => host.releaseInertCloseForTest()
        case None => @Fail("pending close host was dropped before settlement")
    }
    let _ = group.pumpOneTurn(maximumIdleWaitMs: 0u32)
    @Assert(linuxTestRequestStatus(close, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(linuxTestRequestStatus(duplicateClose, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(group.count(), 0)
    @Assert(facts.factoryCalls, 1)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}

@When[os == "Linux"]
@Test
func testLinuxGroupRetainsFailedStartUntilItsCloseSettles(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let facts = LinuxHostGroupTestFacts()
    let failed = group.requestOpen("failing", { _ =>
        facts.factoryCalls += 1
        let host = CjguiLinuxApplicationHost(LinuxHostGroupTestController())
        host.startInertFailureForTest()
        host
    })
    @Assert(linuxTestRequestStatus(failed, CjguiLinuxWindowRequestStatus.Failed), true)
    @Assert(failed.message(), "start_failed")
    @Assert(facts.factoryCalls, 1)
    // The window existed before start failed; its common close is retained, so
    // the slot (and any controller/font lease) stays until it really closes.
    @Assert(group.count(), 1)
    for (_ in 0..2) {
        let _ = group.pumpOneTurn(maximumIdleWaitMs: 0u32)
        @Assert(group.count(), 1)
    }
    match (group.windowById(failed.windowId)) {
        case Some(host) => host.releaseInertCloseForTest()
        case None => @Fail("failed start host was dropped before its close settled")
    }
    let _ = group.pumpOneTurn(maximumIdleWaitMs: 0u32)
    @Assert(group.count(), 0)
    // A later open is legal and receives a fresh identity.
    let reopened = group.requestOpen("failing", { _ => linuxTestHost() })
    @Assert(linuxTestRequestStatus(reopened, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(reopened.windowId != failed.windowId, true)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}

@When[os == "Linux"]
@Test
func testLinuxGroupRejectsDuplicateAndStaleRequests(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let open = group.requestOpen("duplicate", { _ => linuxTestHost() })
    @Assert(linuxTestRequestStatus(open, CjguiLinuxWindowRequestStatus.Applied), true)
    let duplicate = group.requestOpen("duplicate", { _ => linuxTestHost() })
    @Assert(linuxTestRequestStatus(duplicate, CjguiLinuxWindowRequestStatus.Failed), true)
    @Assert(duplicate.message(), "window_already_open")
    let stale = group.requestClose(open.windowId + 1000)
    @Assert(linuxTestRequestStatus(stale, CjguiLinuxWindowRequestStatus.Failed), true)
    @Assert(stale.message(), "stale_window")
    // The old identity cannot close a later generation either.
    let close = group.requestClose(open.windowId)
    @Assert(linuxTestRequestStatus(close, CjguiLinuxWindowRequestStatus.Applied), true)
    let reopened = group.requestOpen("duplicate", { _ => linuxTestHost() })
    @Assert(linuxTestRequestStatus(reopened, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(reopened.windowId != open.windowId, true)
    let oldAgain = group.requestClose(open.windowId)
    @Assert(linuxTestRequestStatus(oldAgain, CjguiLinuxWindowRequestStatus.Failed), true)
    @Assert(group.count(), 1)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}

@When[os == "Linux"]
@Test
func testLinuxGroupSameTurnOpenThenCloseCancelsBeforeCreation(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let facts = LinuxHostGroupTestFacts()
    let parent = group.requestOpen("parent", { _ =>
        // Executed at the host's boundary, where a controller action would be
        // queued. The immediately following close must cancel the queued open.
        facts.request = Some(group.requestOpen("child", { _ =>
            facts.factoryCalls += 1
            linuxTestHost()
        }))
        let close = group.requestCloseKey("child")
        @Assert(linuxTestRequestStatus(close, CjguiLinuxWindowRequestStatus.Applied), true)
        @Assert(close.message(), "cancelled_pending_open")
        linuxTestHost()
    })
    @Assert(linuxTestRequestStatus(parent, CjguiLinuxWindowRequestStatus.Applied), true)
    match (facts.request) {
        case Some(request) =>
            @Assert(linuxTestRequestStatus(request, CjguiLinuxWindowRequestStatus.Superseded), true)
        case None => @Fail("child open request was never issued")
    }
    @Assert(facts.factoryCalls, 0)
    @Assert(group.window("child").isNone(), true)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}

@When[os == "Linux"]
@Test
func testLinuxGroupCloseThenOpenSameTurnQueuesBehindTheClose(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let first = group.requestOpen("editor", { _ => linuxTestHost() })
    @Assert(linuxTestRequestStatus(first, CjguiLinuxWindowRequestStatus.Applied), true)
    let facts = LinuxHostGroupTestFacts()
    // Runs inside an apply boundary, exactly where a controller dispatch would
    // ask to close and immediately open the same key.
    let parent = group.requestOpen("parent", { _ =>
        let close = group.requestCloseKey("editor")
        @Assert(linuxTestRequestStatus(close, CjguiLinuxWindowRequestStatus.Pending), true)
        facts.request = Some(group.requestOpen("editor", { _ => linuxTestHost() }))
        linuxTestHost()
    })
    @Assert(linuxTestRequestStatus(parent, CjguiLinuxWindowRequestStatus.Applied), true)
    match (facts.request) {
        case Some(request) =>
            // Queued behind the not-yet-executed close, not refused as still open.
            @Assert(linuxTestRequestStatus(request, CjguiLinuxWindowRequestStatus.Pending), true)
            let _ = group.pumpOneTurn(maximumIdleWaitMs: 0u32)
            @Assert(linuxTestRequestStatus(request, CjguiLinuxWindowRequestStatus.Applied), true)
            @Assert(request.windowId != first.windowId, true)
        case None => @Fail("same-turn reopen was never issued")
    }
    @Assert(group.isWindowOpen("editor"), true)
    @Assert(group.isWindowOpen("parent"), true)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}

@When[os == "Linux"]
@Test
func testLinuxGroupExitSettlesEveryWindowOnce(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let first = group.requestOpen("first", { _ => linuxTestHost() })
    let second = group.requestOpen("second", { _ => linuxTestHost() })
    @Assert(linuxTestRequestStatus(first, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(linuxTestRequestStatus(second, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(group.count(), 2)
    let exit = group.requestExit()
    @Assert(group.closeAll(maximumWaitMs: 100), true)
    @Assert(linuxTestRequestStatus(exit, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(group.count(), 0)
    @Assert(group.isOpen(), false)
    // A repeated exit returns the settled request rather than starting a
    // second teardown.
    let repeated = group.requestExit()
    @Assert(linuxTestRequestStatus(repeated, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}


@When[os == "Linux"]
@Test
func testLinuxLegacyAddExitClosesRegisteredWindow(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let host = linuxTestHost()
    @Assert(group.add(host), true)
    @Assert(group.count(), 1)
    // Legacy add still gets an executable close identity; exit must really
    // close it rather than merely marking a ticket.
    let exit = group.requestExit()
    @Assert(linuxTestRequestStatus(exit, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(group.count(), 0)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}

@When[os == "Linux"]
@Test
func testLinuxRemoveRefusesOpenAndPendingClose(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let open = group.requestOpen("remove", { _ =>
        let host = linuxTestHost()
        host.holdInertCloseForTest()
        host
    })
    @Assert(linuxTestRequestStatus(open, CjguiLinuxWindowRequestStatus.Applied), true)
    let host = match (group.windowById(open.windowId)) {
        case Some(value) => value
        case None => @Fail("remove test lost its host"); linuxTestHost()
    }
    @Assert(group.remove(host), false)
    @Assert(group.count(), 1)
    let close = group.requestClose(open.windowId)
    @Assert(linuxTestRequestStatus(close, CjguiLinuxWindowRequestStatus.Pending), true)
    @Assert(group.remove(host), false)
    @Assert(group.count(), 1)
    host.releaseInertCloseForTest()
    let _ = group.pumpOneTurn(maximumIdleWaitMs: 0u32)
    @Assert(linuxTestRequestStatus(close, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(group.count(), 0)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}

@When[os == "Linux"]
@Test
func testLinuxLegacyAddRemoveAfterRealClose(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let host = linuxTestHost()
    @Assert(group.add(host), true)
    host.close()
    @Assert(host.windowIsOpen(), false)
    @Assert(group.remove(host), true)
    @Assert(group.count(), 0)
}

@When[os == "Linux"]
@Test
func testLinuxOccupiedQueuedOpenDoesNotRunItsFactory(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let facts = LinuxHostGroupTestFacts()
    let outer = group.requestOpen("same", { _ =>
        facts.childRequest = Some(group.requestOpen("same", { _ =>
            facts.childCalls += 1
            linuxTestHost()
        }))
        linuxTestHost()
    })
    @Assert(linuxTestRequestStatus(outer, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(facts.childCalls, 0)
    let child = match (facts.childRequest) {
        case Some(value) => value
        case None => @Fail("same-key child request was never queued"); outer
    }
    let _ = group.pumpOneTurn(maximumIdleWaitMs: 0u32)
    @Assert(linuxTestRequestStatus(child, CjguiLinuxWindowRequestStatus.Failed), true)
    @Assert(child.message(), "window_already_open")
    @Assert(facts.childCalls, 0)
    @Assert(group.count(), 1)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}

@When[os == "Linux"]
@Test
func testLinuxPumpInsideFactoryKeepsTheActiveGuard(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let facts = LinuxHostGroupTestFacts()
    let outer = group.requestOpen("outer", { _ =>
        facts.childRequest = Some(group.requestOpen("child", { _ =>
            facts.childCalls += 1
            linuxTestHost()
        }))
        // A factory re-entering the owner must not clear the active lifecycle
        // guard and run a nested boundary.
        facts.pumpResult = group.pumpOneTurn(maximumIdleWaitMs: 0u32)
        linuxTestHost()
    })
    @Assert(linuxTestRequestStatus(outer, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(facts.childCalls, 0)
    let child = match (facts.childRequest) {
        case Some(value) => value
        case None => @Fail("child request was never queued"); outer
    }
    @Assert(linuxTestRequestStatus(child, CjguiLinuxWindowRequestStatus.Pending), true)
    let _ = group.pumpOneTurn(maximumIdleWaitMs: 0u32)
    @Assert(linuxTestRequestStatus(child, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(facts.childCalls, 1)
    @Assert(group.count(), 2)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}

@When[os == "Linux"]
@Test
func testLinuxFactoryExceptionKeepsQueuedSiblingAndLaterOpen(): Unit {
    let group = CjguiLinuxApplicationHostGroup()
    let facts = LinuxHostGroupTestFacts()
    let boom = group.requestOpen("boom", { _ =>
        facts.childRequest = Some(group.requestOpen("sibling", { _ =>
            facts.factoryCalls += 1
            linuxTestHost()
        }))
        throw Exception("factory boom")
    })
    @Assert(linuxTestRequestStatus(boom, CjguiLinuxWindowRequestStatus.Failed), true)
    @Assert(boom.message(), "factory_exception")
    let sibling = match (facts.childRequest) {
        case Some(value) => value
        case None => @Fail("sibling request was lost after factory exception"); boom
    }
    @Assert(linuxTestRequestStatus(sibling, CjguiLinuxWindowRequestStatus.Pending), true)
    let _ = group.pumpOneTurn(maximumIdleWaitMs: 0u32)
    @Assert(linuxTestRequestStatus(sibling, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(facts.factoryCalls, 1)
    let later = group.requestOpen("later", { _ => linuxTestHost() })
    @Assert(linuxTestRequestStatus(later, CjguiLinuxWindowRequestStatus.Applied), true)
    @Assert(group.count(), 2)
    @Assert(group.closeAll(maximumWaitMs: 100), true)
}

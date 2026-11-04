package cjgui

import std.unittest.*
import std.unittest.testmacro.*
import std.time.*

// The testing hook enters real TextKit and the ordinary FIFO. It does not
// claim physical HID delivery.
private class ExitBoundaryController <: CjguiComposableUiController {
    let quitOnInput: Bool
    var app: ?CjguiMacosApplication = None
    var observedOwner: ?ExitBoundaryController = None
    var text: String = ""
    var revision: Int64 = 1
    var writes: Int64 = 0
    var quitCalls: Int64 = 0
    var received: Int64 = 0
    var rejected: Int64 = 0
    var lastEventKind: Int64 = -1
    var lastEventNode: Int64 = -1
    var quitAccepted = false
    var ownerTextAtQuit = "unobserved"
    var ownerWritesAtQuit: Int64 = -1
    init(quitOnInput: Bool) { this.quitOnInput = quitOnInput }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "exit-boundary-root", CjguiComposableUiStyle())
        root.add(cjguiComposableTextInput(2, "exit-boundary-note", "Note", text, 10,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 36)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        received += 1
        lastEventKind = event.eventKind
        lastEventNode = event.node.nodeId
        if (event.eventKind == 28 && event.node.nodeId == 2) {
            if (quitOnInput) {
                quitCalls += 1
                if (let Some(owner) <- observedOwner) {
                    ownerTextAtQuit = owner.text
                    ownerWritesAtQuit = owner.writes
                }
                if (let Some(application) <- app) { quitAccepted = application.requestApplicationExit() }
                return CjguiComposableUiDispatchResult(true)
            }
            text = event.text
            revision += 1
            writes += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        rejected += 1
        lastEventKind = kind
        lastEventNode = node
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(text.size == 0, shouldClose: text.size == 0)
    }
}

private class ExitBoundaryDecision <: CjguiMacosApplicationExitDecisionProvider {
    let owner: ExitBoundaryController
    var calls: Int64 = 0
    var injectionWindow: ?CjguiComposableUiWindow = None
    var injected = false
    var before = "unobserved"
    var traceStatus: Int32 = -1
    var pending: UInt32 = 0u32
    var enqueuedKind: UInt32 = 0u32
    var enqueuedNode: UInt64 = 0u64
    init(owner: ExitBoundaryController) { this.owner = owner }
    public func requestApplicationExit(): Bool {
        calls += 1
        before = owner.text
        if (!injected && owner.text.size == 0) {
            if (let Some(window) <- injectionWindow) {
                injected = true
                exitBoundaryInsert(window, "new")
                var pendingCount: UInt32 = 0u32
                var queuedKind: UInt32 = 0u32
                var queuedNode: UInt64 = 0u64
                var projection: UInt64 = 0u64
                var pumpedKind: UInt32 = 0u32
                var pumpedNode: UInt64 = 0u64
                var pumpedProjection: UInt64 = 0u64
                traceStatus = unsafe { cjgui_internal_renderer_test_composable_interaction_trace(
                    window.testSessionToken(), inout pendingCount, inout queuedKind, inout queuedNode,
                    inout projection, inout pumpedKind, inout pumpedNode, inout pumpedProjection) }
                pending = pendingCount
                enqueuedKind = queuedKind
                enqueuedNode = queuedNode
            }
        }
        return owner.text.size == 0
    }
}

private func exitBoundaryInsert(window: CjguiComposableUiWindow, input: String): Unit {
    var index: UInt32 = 0u32
    var found = false
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == 2) { found = true; break }
        index += 1u32
    }
    @Assert(found, true)
    let text = unsafe { LibC.mallocCString(input) }
    try (value = text.asResource()) {
        @Assert(unsafe { cjgui_internal_renderer_test_insert_composable_text(
            window.testSessionToken(), index, value.value) }, CJGUI_INTERNAL_RENDERER_OK)
    }
}

private func exitBoundarySettle(app: CjguiMacosApplication,
    window: CjguiComposableUiWindow): Unit {
    let deadline = MonoTime.now() + 3 * Duration.second
    while (app.isOpen() && (window.displayedSceneVersion() <= 0 || window.hasDeferredEventWork()) &&
        MonoTime.now() < deadline) {
        let _ = app.pumpOneTurn()
    }
    @Assert(window.displayedSceneVersion() > 0, true)
    @Assert(window.hasDeferredEventWork(), false)
}

private func exitBoundaryDrainUntilQuit(app: CjguiMacosApplication,
    owner: ExitBoundaryController): Unit {
    let deadline = MonoTime.now() + 3 * Duration.second
    while (app.isOpen() && owner.quitCalls == 0 && MonoTime.now() < deadline) {
        let _ = app.pumpOneTurn()
    }
    println("EXIT_BOUNDARY_ROUTE quit=${owner.quitCalls} received=${owner.received} " +
        "rejected=${owner.rejected} last=${owner.lastEventKind}:${owner.lastEventNode}")
}

private func exitBoundaryTwoWindows(injectDuringDecision: Bool): Unit {
    cjguiMacosOwnerTest({ =>
        let firstOwner = ExitBoundaryController(true)
        let secondOwner = ExitBoundaryController(false)
        let decision = ExitBoundaryDecision(secondOwner)
        let app = CjguiMacosApplication(maximumWindowCount: 2, exitDecisionProvider: Some(decision))
        firstOwner.app = Some(app)
        let first = app.openWindow(firstOwner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI exit boundary A", 400u32, 300u32))
        let second = app.openWindow(secondOwner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI exit boundary B", 400u32, 300u32))
        @Assert(first.didOpen && second.didOpen, true)
        let a = app.window(first.identifier.getOrThrow()).getOrThrow()
        let b = app.window(second.identifier.getOrThrow()).getOrThrow()
        try {
            let deadline = MonoTime.now() + 3 * Duration.second
            while ((a.displayedSceneVersion() <= 0 || b.displayedSceneVersion() <= 0) &&
                MonoTime.now() < deadline) {
                let _ = app.pumpOneTurn()
            }
            @Assert(a.displayedSceneVersion() > 0 && b.displayedSceneVersion() > 0, true)
            exitBoundarySettle(app, a)
            exitBoundarySettle(app, b)
            @Assert(b.focusAcceptedNodeById(2), true)
            exitBoundarySettle(app, b)
            @Assert(b.focusedNodeReference().isSome(), true)
            @Assert(a.focusAcceptedNodeById(2), true)
            exitBoundarySettle(app, a)
            @Assert(a.focusedNodeReference().isSome(), true)
            @Assert(secondOwner.text, "")
            @Assert(firstOwner.quitCalls, 0)
            firstOwner.observedOwner = Some(secondOwner)
            if (injectDuringDecision) {
                decision.injectionWindow = Some(b)
            } else {
                // Independent regression for B input accepted before exit.
                exitBoundaryInsert(b, "new")
            }
            @Assert(secondOwner.text, "")
            exitBoundaryInsert(a, "q")
            exitBoundaryDrainUntilQuit(app, firstOwner)
            let decisionDeadline = MonoTime.now() + 3 * Duration.second
            while (app.isOpen() && decision.calls == 0 && MonoTime.now() < decisionDeadline) {
                let _ = app.pumpOneTurn()
            }
            println("EXIT_BOUNDARY quit=${firstOwner.quitCalls} accepted=${firstOwner.quitAccepted} " +
                "before=[${firstOwner.ownerTextAtQuit}]:${firstOwner.ownerWritesAtQuit} " +
                "after=[${secondOwner.text}]:${secondOwner.writes} " +
                "open=${app.isOpen()}:${a.isOpen()}:${b.isOpen()}")
            @Assert(firstOwner.quitCalls, 1)
            if (injectDuringDecision) {
                @Assert(firstOwner.ownerTextAtQuit, "")
                @Assert(firstOwner.ownerWritesAtQuit, 0)
                @Assert(firstOwner.quitAccepted, true)
                @Assert(decision.before, "")
                @Assert(decision.injected, true)
                @Assert(decision.traceStatus, CJGUI_INTERNAL_RENDERER_OK)
                @Assert(decision.pending > 0u32, true)
                @Assert(decision.enqueuedKind, 28u32)
                @Assert(decision.enqueuedNode, 2u64)
            }
            // A closed app here is already a loss even if B never got an
            // owner turn; the trace above proves its actual pending input.
            @Assert(app.isOpen() && a.isOpen() && b.isOpen(), true)
            let drainDeadline = MonoTime.now() + 3 * Duration.second
            while (app.isOpen() && secondOwner.text != "new" && MonoTime.now() < drainDeadline) {
                let _ = app.pumpOneTurn()
            }
            @Assert(app.isOpen() && a.isOpen() && b.isOpen(), true)
            @Assert(secondOwner.text, "new")
            @Assert(secondOwner.writes, 1)
            for (_ in 0..4) {
                let _ = app.pumpOneTurn()
                @Assert(app.isOpen() && a.isOpen() && b.isOpen(), true)
                @Assert(secondOwner.text, "new")
                @Assert(secondOwner.writes, 1)
            }
        } finally { app.close() }
    })
}

@When[os == "macOS"]
@Test
func applicationExitRechecksWorkAcceptedAfterDecision(): Unit {
    exitBoundaryTwoWindows(true)
}

@When[os == "macOS"]
@Test
func applicationExitProtectsWorkAlreadyQueued(): Unit {
    exitBoundaryTwoWindows(false)
}

@When[os == "macOS"]
@Test
func applicationExitWithoutNewWorkClosesNormally(): Unit {
    cjguiMacosOwnerTest({ =>
        let owner = ExitBoundaryController(true)
        let clean = ExitBoundaryController(false)
        let decision = ExitBoundaryDecision(clean)
        let app = CjguiMacosApplication(exitDecisionProvider: Some(decision))
        owner.app = Some(app)
        let opened = app.openWindow(owner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI exit boundary control", 400u32, 300u32))
        @Assert(opened.didOpen, true)
        let window = app.window(opened.identifier.getOrThrow()).getOrThrow()
        try {
            let deadline = MonoTime.now() + 3 * Duration.second
            while (window.displayedSceneVersion() <= 0 && MonoTime.now() < deadline) {
                let _ = app.pumpOneTurn()
            }
            @Assert(window.displayedSceneVersion() > 0, true)
            exitBoundarySettle(app, window)
            @Assert(window.focusAcceptedNodeById(2), true)
            exitBoundarySettle(app, window)
            @Assert(window.focusedNodeReference().isSome(), true)
            @Assert(owner.quitCalls, 0)
            exitBoundaryInsert(window, "q")
            exitBoundaryDrainUntilQuit(app, owner)
            @Assert(owner.quitCalls, 1)
            @Assert(owner.quitAccepted, true)
            let closeDeadline = MonoTime.now() + 3 * Duration.second
            while (app.isOpen() && MonoTime.now() < closeDeadline) {
                let _ = app.pumpOneTurn()
            }
            @Assert(!app.isOpen() && !window.isOpen(), true)
        } finally { app.close() }
    })
}

@When[os == "macOS"]
@Test
func applicationExitBatchRefusesPendingInputWithoutClosingSibling(): Unit {
    cjguiMacosOwnerTest({ =>
        let firstOwner = ExitBoundaryController(false)
        let secondOwner = ExitBoundaryController(false)
        let app = CjguiMacosApplication(maximumWindowCount: 2)
        let first = app.openWindow(firstOwner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI exit batch A", 400u32, 300u32))
        let second = app.openWindow(secondOwner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI exit batch B", 400u32, 300u32))
        @Assert(first.didOpen && second.didOpen, true)
        let a = app.window(first.identifier.getOrThrow()).getOrThrow()
        let b = app.window(second.identifier.getOrThrow()).getOrThrow()
        try {
            exitBoundarySettle(app, a)
            exitBoundarySettle(app, b)
            @Assert(b.focusAcceptedNodeById(2), true)
            exitBoundarySettle(app, b)
            let (aStatus, aGeneration) = internalRendererExitPreflight(a.testSessionToken())
            let (bStatus, bGeneration) = internalRendererExitPreflight(b.testSessionToken())
            @Assert(aStatus, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(bStatus, CJGUI_INTERNAL_RENDERER_OK)
            let tokens = [a.testSessionToken(), b.testSessionToken()]
            @Assert(internalRendererExitCommit(tokens, [aGeneration, bGeneration + 1u64]),
                CJGUI_INTERNAL_RENDERER_INVALID_SESSION)
            @Assert(a.isOpen() && b.isOpen(), true)
            exitBoundaryInsert(b, "new")
            let generations = [aGeneration, bGeneration]
            @Assert(internalRendererExitCommit(tokens, generations),
                CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED)
            @Assert(a.isOpen() && b.isOpen(), true)
            let deadline = MonoTime.now() + 3 * Duration.second
            while (secondOwner.text != "new" && MonoTime.now() < deadline) {
                let _ = app.pumpOneTurn()
            }
            @Assert(secondOwner.text, "new")
            @Assert(secondOwner.writes, 1)
            @Assert(a.isOpen() && b.isOpen(), true)
        } finally { app.close() }
    })
}

@When[os == "macOS"]
@Test
func applicationExitBatchMarksAllBeforeReentrantWindowClose(): Unit {
    cjguiMacosOwnerTest({ =>
        let app = CjguiMacosApplication(maximumWindowCount: 2)
        let first = app.openWindow(ExitBoundaryController(false), configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI exit reentry A", 400u32, 300u32))
        let second = app.openWindow(ExitBoundaryController(false), configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI exit reentry B", 400u32, 300u32))
        @Assert(first.didOpen && second.didOpen, true)
        let a = app.window(first.identifier.getOrThrow()).getOrThrow()
        let b = app.window(second.identifier.getOrThrow()).getOrThrow()
        try {
            exitBoundarySettle(app, a)
            exitBoundarySettle(app, b)
            var index: UInt32 = 0u32
            var found = false
            for (node in b.acceptedSceneNodes()) {
                if (node.nodeId == 2) { found = true; break }
                index += 1u32
            }
            @Assert(found, true)
            let aToken = a.testSessionToken()
            let bToken = b.testSessionToken()
            let (aStatus, aGeneration) = internalRendererExitPreflight(aToken)
            let (bStatus, bGeneration) = internalRendererExitPreflight(bToken)
            @Assert(aStatus, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(bStatus, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(unsafe { cjgui_internal_renderer_test_arm_exit_close_reentry(aToken, bToken, index) },
                CJGUI_INTERNAL_RENDERER_OK)
            @Assert(internalRendererExitCommit([aToken, bToken], [aGeneration, bGeneration]),
                CJGUI_INTERNAL_RENDERER_OK)
            var observed: UInt32 = 0u32
            var terminal: UInt32 = 0u32
            var accepted: UInt32 = 0u32
            @Assert(unsafe { cjgui_internal_renderer_test_read_exit_close_reentry(
                inout observed, inout terminal, inout accepted) }, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(observed, 1u32)
            @Assert(terminal, 1u32)
            @Assert(accepted, 0u32)
            @Assert(a.retireCommittedApplicationExit(aToken), true)
            @Assert(b.retireCommittedApplicationExit(bToken), true)
            @Assert(a.isOpen() || b.isOpen(), false)
        } finally {
            var ignoredObserved: UInt32 = 0u32
            var ignoredTerminal: UInt32 = 0u32
            var ignoredAccepted: UInt32 = 0u32
            let _ = unsafe { cjgui_internal_renderer_test_read_exit_close_reentry(
                inout ignoredObserved, inout ignoredTerminal, inout ignoredAccepted) }
            app.close()
        }
    })
}

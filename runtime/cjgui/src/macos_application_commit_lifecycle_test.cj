package cjgui

import std.collection.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private class CommitLifecycleOwner <: CjguiComposableUiController & CjguiComposableUiWindowCloseLifecycle &
    CjguiComposableUiSceneRefreshParticipant {
    let throwOnCommit: Bool
    var closeCallbacks: Int64 = 0
    var disposals: Int64 = 0
    init(throwOnCommit!: Bool = false) { this.throwOnCommit = throwOnCommit }
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "commit-lifecycle-root", CjguiComposableUiStyle())
        root.add(cjguiComposableTextInput(2, "commit-lifecycle-field", "Value", "", 0,
            CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 32)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func windowCloseDidCommit(): Unit {
        closeCallbacks += 1
        if (throwOnCommit) { throw Exception("window_close_lifecycle_test_failure") }
    }
    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> { return ArrayList<CjguiComposableUiCommand>() }
    public func commitSceneRefresh(): Unit { }
    public func rollbackSceneRefresh(): Unit { }
    public func disposeSceneRefreshResources(): Unit { disposals += 1 }
}

private class CommitLifecycleDecision <: CjguiMacosApplicationExitDecisionProvider &
    CjguiMacosApplicationExitDecisionLifecycle {
    let mode: Int64
    var app: ?CjguiMacosApplication = None
    var decisions: Int64 = 0
    var commits: Int64 = 0
    var attemptedOpen = false
    var openedDuringCommit = false
    var firstWindow: ?CjguiComposableUiWindow = None
    var secondWindow: ?CjguiComposableUiWindow = None
    var allWindowsClosedAtCommit = false
    var restartedWindowDuringCommit = false
    init(mode: Int64) { this.mode = mode }
    public func requestApplicationExit(): Bool { decisions += 1; return true }
    public func applicationExitDidCommit(): Unit {
        commits += 1
        if (let Some(first) <- firstWindow) {
            if (let Some(second) <- secondWindow) { allWindowsClosedAtCommit = !first.isOpen() && !second.isOpen() }
        }
        if (mode == 0) {
            attemptedOpen = true
            if (let Some(first) <- firstWindow) { restartedWindowDuringCommit = first.start() }
            if (let Some(application) <- app) {
                let opened = application.openWindow(CommitLifecycleOwner(), configuration:
                    CjguiMacosApplicationWindowConfiguration("CJGUI forbidden late window", 400u32, 300u32))
                openedDuringCommit = opened.didOpen
            }
        }
        if (mode == 1) { throw Exception("application_exit_lifecycle_test_failure") }
    }
    public func applicationExitDidCancel(): Unit { }
}

private func runCommitLifecycle(mode: Int64): Unit {
    cjguiMacosOwnerTest({ =>
        let provider = CommitLifecycleDecision(mode)
        let app = CjguiMacosApplication(maximumWindowCount: 4, exitDecisionProvider: Some(provider))
        provider.app = Some(app)
        let aOwner = CommitLifecycleOwner(throwOnCommit: mode == 2)
        let bOwner = CommitLifecycleOwner()
        let aResult = app.openWindow(aOwner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI commit A", 400u32, 300u32))
        let bResult = app.openWindow(bOwner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI commit B", 400u32, 300u32))
        @Assert(aResult.didOpen && bResult.didOpen, true)
        let a = app.window(aResult.identifier.getOrThrow()).getOrThrow()
        let b = app.window(bResult.identifier.getOrThrow()).getOrThrow()
        provider.firstWindow = Some(a); provider.secondWindow = Some(b)
        try {
            let deadline = MonoTime.now() + 5 * Duration.second
            while ((a.displayedSceneVersion() <= 0 || b.displayedSceneVersion() <= 0 ||
                a.hasDeferredEventWork() || b.hasDeferredEventWork() ||
                a.applicationExitPreflight().isNone() || b.applicationExitPreflight().isNone()) &&
                MonoTime.now() < deadline) { let _ = app.pumpOneTurn() }
            @Assert(a.applicationExitPreflight().isSome() && b.applicationExitPreflight().isSome(), true)
            // The call is deliberately outside a host turn. No second exit
            // request or synthetic callback is used to complete it.
            try { let _ = app.requestApplicationExit() } catch (_: Exception) { }
            @Assert(provider.decisions, 1)
            @Assert(provider.commits, 1)
            @Assert(provider.allWindowsClosedAtCommit, true)
            if (mode == 0) {
                @Assert(provider.attemptedOpen, true)
                @Assert(provider.openedDuringCommit, false)
                @Assert(provider.restartedWindowDuringCommit, false)
            }
            @Assert(app.isOpen(), false)
            @Assert(a.isOpen() || b.isOpen(), false)
            @Assert(aOwner.closeCallbacks, 1)
            @Assert(bOwner.closeCallbacks, 1)
            @Assert(aOwner.disposals, 1)
            @Assert(bOwner.disposals, 1)
            if (mode == 1) { @Assert(app.testApplicationCloseTrace().contains("application_exit_lifecycle_exception"), true) }
            if (mode == 2) { @Assert(a.testCloseTrace().contains("window_close_lifecycle_exception"), true) }
        } finally { if (app.isOpen()) { app.close() } }
    })
}

@When[os == "macOS"]
@Test
func commitLifecycleRejectsNewWindowAfterNativeCommit(): Unit { runCommitLifecycle(0) }

@When[os == "macOS"]
@Test
func commitLifecycleApplicationCallbackFailureStillRetiresAll(): Unit { runCommitLifecycle(1) }

@When[os == "macOS"]
@Test
func commitLifecycleWindowCallbackFailureStillRetiresAll(): Unit { runCommitLifecycle(2) }

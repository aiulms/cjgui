package cjgui

import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

foreign {
    func cjgui_internal_renderer_test_invoke_standard_quit_menu_item(): Int32
    func cjgui_internal_renderer_test_set_application_hidden(hidden: UInt8, noKey: CPointer<UInt32>): Int32
    func cjgui_internal_renderer_test_observe_current_composable_command_menu(
        readiness: CPointer<UInt32>): Int32
    func cjgui_internal_renderer_test_prepare_composable_command_menu(
        session: UInt64, readiness: CPointer<UInt32>): Int32
    func cjgui_internal_renderer_test_prepare_composable_command_menu_window(
        title: CString, readiness: CPointer<UInt32>): Int32
}

private class HostStandardQuitOwner <: CjguiComposableUiController {
    var closeDecisions: Int64 = 0
    var textAtClose = "unobserved"
    var text: String = ""
    var revision: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "host-standard-quit-root", CjguiComposableUiStyle())
        root.add(cjguiComposableTextInput(2, "host-standard-quit-field", "Text", text, 0,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 36)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 2) {
            text = event.text
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        closeDecisions += 1
        textAtClose = text
        return CjguiComposableUiDispatchResult(false)
    }
}

// Controlled AppKit responder + native FIFO, not physical keyboard delivery.
// Legacy single-window hosts leave the original process Quit to the
// application through the public window seam, without inventing a decision.
@When[os == "macOS"]
@Test
func singleWindowLegacyStandardQuitRemainsConsumerOwned(): Unit {
    cjguiMacosOwnerTest({ =>
        let title = "CJGUI single host standard quit"
        let owner = HostStandardQuitOwner()
        let host = CjguiMacosApplicationHost(owner, configuration:
            CjguiMacosApplicationWindowConfiguration(title, 400u32, 300u32))
        @Assert(host.start(), true)
        let window = host.window()
        try {
            let startupDeadline = MonoTime.now() + 5 * Duration.second
            while ((window.displayedSceneVersion() <= 0 || window.hasDeferredEventWork() ||
                window.applicationExitPreflight().isNone()) && MonoTime.now() < startupDeadline) {
                let _ = host.pumpOneTurn()
            }
            @Assert(window.displayedSceneVersion() > 0 && window.applicationExitPreflight().isSome(), true)
            var readiness: UInt32 = 0u32
            let titleBytes = unsafe { LibC.mallocCString(title) }
            try (value = titleBytes.asResource()) {
                @Assert(unsafe { cjgui_internal_renderer_test_prepare_composable_command_menu_window(
                    value.value, inout readiness) }, CJGUI_INTERNAL_RENDERER_OK)
            }
            let keyDeadline = MonoTime.now() + 5 * Duration.second
            var pending: UInt32 = 0u32
            var enqueuedKind: UInt32 = 0u32
            var enqueuedNode: UInt64 = 0u64
            var enqueuedScene: UInt64 = 0u64
            var pumpedKind: UInt32 = 0u32
            var pumpedNode: UInt64 = 0u64
            var pumpedScene: UInt64 = 0u64
            // makeKeyAndOrderFront is asynchronous. Observe an actual key
            // window through the ordinary host scheduler before asking the
            // session-qualified helper to prove it is THIS exact window.
            var currentKeyStatus = unsafe {
                cjgui_internal_renderer_test_observe_current_composable_command_menu(inout readiness)
            }
            while (host.isOpen() && currentKeyStatus != CJGUI_INTERNAL_RENDERER_OK &&
                MonoTime.now() < keyDeadline) {
                let _ = host.pumpOneTurn()
                currentKeyStatus = unsafe {
                    cjgui_internal_renderer_test_observe_current_composable_command_menu(inout readiness)
                }
            }
            @Assert(currentKeyStatus, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(unsafe { cjgui_internal_renderer_test_prepare_composable_command_menu(
                window.testSessionToken(), inout readiness) }, CJGUI_INTERNAL_RENDERER_OK)
            @Assert((readiness & 128u32) != 0u32, true)
            @Assert(unsafe { cjgui_internal_renderer_test_invoke_standard_quit_menu_item() }, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(unsafe { cjgui_internal_renderer_test_composable_interaction_trace(window.testSessionToken(),
                inout pending, inout enqueuedKind, inout enqueuedNode, inout enqueuedScene,
                inout pumpedKind, inout pumpedNode, inout pumpedScene) }, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(pending > 0u32 && enqueuedKind == 42u32, true)
            let quitDeadline = MonoTime.now() + 5 * Duration.second
            while (host.isOpen() && pumpedKind != 42u32 && MonoTime.now() < quitDeadline) {
                let _ = host.pumpOneTurn()
                @Assert(unsafe { cjgui_internal_renderer_test_composable_interaction_trace(window.testSessionToken(),
                    inout pending, inout enqueuedKind, inout enqueuedNode, inout enqueuedScene,
                    inout pumpedKind, inout pumpedNode, inout pumpedScene) }, CJGUI_INTERNAL_RENDERER_OK)
            }
            @Assert(pumpedKind, 42u32)
            @Assert(host.isOpen(), true)
            @Assert(owner.closeDecisions, 0)
            // The original process intent stays with a legacy consumer such
            // as Rules; the first read acknowledges it and the second is empty.
            @Assert(window.consumeApplicationExitRequest(), true)
            @Assert(window.consumeApplicationExitRequest(), false)
        } finally {
            let _ = window.consumeApplicationExitRequest()
            host.close()
        }
    })
}

private class HostStandardQuitPolicy <: CjguiMacosApplicationExitDecisionProvider & CjguiMacosApplicationExitDecisionLifecycle {
    let owner: HostStandardQuitOwner
    var calls: Int64 = 0
    var ownerAtDecision = "unobserved"
    var commits: Int64 = 0
    var cancellations: Int64 = 0
    var reenterOnAllow = false
    var hostDuringDecision: ?CjguiMacosApplicationHost = None
    var wasOpenAfterReentry = false
    var allowed = false
    init(owner: HostStandardQuitOwner) { this.owner = owner }
    public func requestApplicationExit(): Bool {
        calls += 1
        ownerAtDecision = owner.text
        if (allowed && reenterOnAllow) {
            reenterOnAllow = false
            if (let Some(host) <- hostDuringDecision) {
                let _ = host.requestApplicationExit()
                wasOpenAfterReentry = host.isOpen()
            }
        }
        return allowed
    }
    public func applicationExitDidCommit(): Unit { commits += 1 }
    public func applicationExitDidCancel(): Unit { cancellations += 1 }
}

// The testing text hook creates the original TextKit/FIFO edit; the standard
// Quit hook invokes AppKit's real menu responder exactly once, without a pump
// between the two. This tests ordering, not physical keyboard delivery.
@When[os == "macOS"]
@Test
func singleWindowOptInQuitSettlesLastTextBeforePolicyAndRejectsSafely(): Unit {
    cjguiMacosOwnerTest({ =>
        let owner = HostStandardQuitOwner()
        let policy = HostStandardQuitPolicy(owner)
        let host = CjguiMacosApplicationHost(owner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI opt in quit", 400u32, 300u32),
            exitDecisionProvider: Some(policy))
        @Assert(host.start(), true)
        let window = host.window()
        try {
            let deadline = MonoTime.now() + 5 * Duration.second
            while ((window.displayedSceneVersion() <= 0 || window.hasDeferredEventWork() ||
                window.applicationExitPreflight().isNone()) && MonoTime.now() < deadline) {
                let _ = host.pumpOneTurn()
            }
            @Assert(window.displayedSceneVersion() > 0 && window.applicationExitPreflight().isSome(), true)
            @Assert(window.activateWindow(), true)
            @Assert(window.focusAcceptedNodeById(2), true)
            let focusedDeadline = MonoTime.now() + 5 * Duration.second
            while ((window.hasDeferredEventWork() || window.applicationExitPreflight().isNone()) &&
                MonoTime.now() < focusedDeadline) { let _ = host.pumpOneTurn() }
            @Assert(window.applicationExitPreflight().isSome(), true)
            var readiness: UInt32 = 0u32
            let keyDeadline = MonoTime.now() + 5 * Duration.second
            var keyStatus = unsafe { cjgui_internal_renderer_test_observe_current_composable_command_menu(inout readiness) }
            while (host.isOpen() && keyStatus != CJGUI_INTERNAL_RENDERER_OK && MonoTime.now() < keyDeadline) {
                let _ = host.pumpOneTurn()
                keyStatus = unsafe { cjgui_internal_renderer_test_observe_current_composable_command_menu(inout readiness) }
            }
            @Assert(keyStatus, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(unsafe { cjgui_internal_renderer_test_prepare_composable_command_menu(
                window.testSessionToken(), inout readiness) }, CJGUI_INTERNAL_RENDERER_OK)
            @Assert((readiness & 128u32) != 0u32, true)
            var nodeIndex: UInt32 = 0u32
            var found = false
            for (node in window.acceptedSceneNodes()) {
                if (node.nodeId == 2) { found = true; break }
                nodeIndex += 1u32
            }
            @Assert(found, true)
            let value = unsafe { LibC.mallocCString("last") }
            try (text = value.asResource()) {
                @Assert(unsafe { cjgui_internal_renderer_test_insert_composable_text(
                    window.testSessionToken(), nodeIndex, text.value) }, CJGUI_INTERNAL_RENDERER_OK)
            }
            @Assert(unsafe { cjgui_internal_renderer_test_invoke_standard_quit_menu_item() }, CJGUI_INTERNAL_RENDERER_OK)
            let decisionDeadline = MonoTime.now() + 5 * Duration.second
            while (host.isOpen() && policy.calls == 0 && MonoTime.now() < decisionDeadline) {
                let _ = host.pumpOneTurn()
            }
            @Assert(policy.calls, 1)
            @Assert(policy.ownerAtDecision, "last")
            @Assert(owner.text, "last")
            @Assert(host.isOpen(), true)
            @Assert(window.consumeApplicationExitRequest(), false)
            // Simulates the consumer's explicit successful save/confirmation
            // continuing the existing intent, not a second AppKit Quit.
            policy.allowed = true
            policy.hostDuringDecision = Some(host)
            policy.reenterOnAllow = true
            @Assert(host.requestApplicationExit(), true)
            let closeDeadline = MonoTime.now() + 5 * Duration.second
            while (host.isOpen() && MonoTime.now() < closeDeadline) { let _ = host.pumpOneTurn() }
            @Assert(host.isOpen(), false)
            @Assert(policy.calls, 2)
            @Assert(policy.wasOpenAfterReentry, true)
            @Assert(policy.commits, 1)
            policy.hostDuringDecision = None
        } finally {
            let _ = window.consumeApplicationExitRequest()
            host.close()
        }
    })
}

// This exercises the public programmatic request with the real TextKit FIFO;
// it deliberately makes no assertion about AppKit menu or physical key routing.
@When[os == "macOS"]
@Test
func singleWindowProgrammaticExitSettlesTextBeforePolicyAndPreservesReentry(): Unit {
    cjguiMacosOwnerTest({ =>
        let owner = HostStandardQuitOwner()
        let policy = HostStandardQuitPolicy(owner)
        let host = CjguiMacosApplicationHost(owner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI opt in quit", 400u32, 300u32),
            exitDecisionProvider: Some(policy))
        @Assert(host.start(), true)
        let window = host.window()
        try {
            let deadline = MonoTime.now() + 5 * Duration.second
            while ((window.displayedSceneVersion() <= 0 || window.hasDeferredEventWork() ||
                window.applicationExitPreflight().isNone()) && MonoTime.now() < deadline) {
                let _ = host.pumpOneTurn()
            }
            @Assert(window.displayedSceneVersion() > 0 && window.applicationExitPreflight().isSome(), true)
            @Assert(window.activateWindow(), true)
            @Assert(window.focusAcceptedNodeById(2), true)
            let focusedDeadline = MonoTime.now() + 5 * Duration.second
            while ((window.hasDeferredEventWork() || window.applicationExitPreflight().isNone()) &&
                MonoTime.now() < focusedDeadline) { let _ = host.pumpOneTurn() }
            @Assert(window.applicationExitPreflight().isSome(), true)
            var nodeIndex: UInt32 = 0u32
            var found = false
            for (node in window.acceptedSceneNodes()) {
                if (node.nodeId == 2) { found = true; break }
                nodeIndex += 1u32
            }
            @Assert(found, true)
            let value = unsafe { LibC.mallocCString("last") }
            try (text = value.asResource()) {
                @Assert(unsafe { cjgui_internal_renderer_test_insert_composable_text(
                    window.testSessionToken(), nodeIndex, text.value) }, CJGUI_INTERNAL_RENDERER_OK)
            }
            @Assert(host.requestApplicationExit(), true)
            let decisionDeadline = MonoTime.now() + 5 * Duration.second
            while (host.isOpen() && policy.calls == 0 && MonoTime.now() < decisionDeadline) {
                let _ = host.pumpOneTurn()
            }
            @Assert(policy.calls, 1)
            @Assert(policy.ownerAtDecision, "last")
            @Assert(owner.text, "last")
            @Assert(host.isOpen(), true)
            // Simulates the consumer's explicit successful save/confirmation
            // continuing the existing intent, not a second AppKit Quit.
            policy.allowed = true
            policy.hostDuringDecision = Some(host)
            policy.reenterOnAllow = true
            @Assert(host.requestApplicationExit(), true)
            let closeDeadline = MonoTime.now() + 5 * Duration.second
            while (host.isOpen() && MonoTime.now() < closeDeadline) { let _ = host.pumpOneTurn() }
            @Assert(host.isOpen(), false)
            @Assert(policy.calls, 2)
            @Assert(policy.wasOpenAfterReentry, true)
            @Assert(policy.commits, 1)
            policy.hostDuringDecision = None
        } finally {
            let _ = window.consumeApplicationExitRequest()
            host.close()
        }
    })
}

@When[os == "macOS"]
@Test
func singleWindowOptInLocalCloseSettlesTextBeforeWindowPolicy(): Unit {
    cjguiMacosOwnerTest({ =>
        let owner = HostStandardQuitOwner()
        let policy = HostStandardQuitPolicy(owner)
        let host = CjguiMacosApplicationHost(owner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI local close ordering", 400u32, 300u32),
            exitDecisionProvider: Some(policy))
        @Assert(host.start(), true)
        let window = host.window()
        try {
            let deadline = MonoTime.now() + 5 * Duration.second
            while ((window.displayedSceneVersion() <= 0 || window.hasDeferredEventWork() ||
                window.applicationExitPreflight().isNone()) && MonoTime.now() < deadline) {
                let _ = host.pumpOneTurn()
            }
            @Assert(window.applicationExitPreflight().isSome(), true)
            @Assert(window.focusAcceptedNodeById(2), true)
            let focusDeadline = MonoTime.now() + 5 * Duration.second
            while ((window.hasDeferredEventWork() || window.applicationExitPreflight().isNone()) &&
                MonoTime.now() < focusDeadline) { let _ = host.pumpOneTurn() }
            @Assert(window.applicationExitPreflight().isSome(), true)
            var nodeIndex: UInt32 = 0u32
            var found = false
            for (node in window.acceptedSceneNodes()) {
                if (node.nodeId == 2) { found = true; break }
                nodeIndex += 1u32
            }
            @Assert(found, true)
            let value = unsafe { LibC.mallocCString("last-local") }
            try (text = value.asResource()) {
                @Assert(unsafe { cjgui_internal_renderer_test_insert_composable_text(
                    window.testSessionToken(), nodeIndex, text.value) }, CJGUI_INTERNAL_RENDERER_OK)
            }
            @Assert(host.requestClose(), true)
            @Assert(owner.closeDecisions, 0)
            let closeDeadline = MonoTime.now() + 5 * Duration.second
            while (host.isOpen() && owner.closeDecisions == 0 && MonoTime.now() < closeDeadline) {
                let _ = host.pumpOneTurn()
            }
            @Assert(owner.closeDecisions, 1)
            @Assert(owner.textAtClose, "last-local")
            @Assert(owner.text, "last-local")
            @Assert(policy.calls, 0)
            @Assert(policy.commits, 0)
            @Assert(host.isOpen(), true)
        } finally { host.close() }
    })
}

@When[os == "macOS"]
@Test
func singleWindowUnkeyedQuitDoesNotBorrowLegacySiblingOwner(): Unit {
    cjguiMacosOwnerTest({ =>
        let legacy = CjguiMacosApplicationHost(HostStandardQuitOwner(), configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI legacy sibling", 400u32, 300u32))
        let owner = HostStandardQuitOwner()
        let policy = HostStandardQuitPolicy(owner)
        let opted = CjguiMacosApplicationHost(owner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI opt in sibling", 400u32, 300u32),
            exitDecisionProvider: Some(policy))
        @Assert(legacy.start(), true)
        @Assert(opted.start(), true)
        var noKey: UInt32 = 0u32
        try {
            let deadline = MonoTime.now() + 5 * Duration.second
            while ((legacy.window().displayedSceneVersion() <= 0 || opted.window().displayedSceneVersion() <= 0 ||
                legacy.window().applicationExitPreflight().isNone() || opted.window().applicationExitPreflight().isNone()) &&
                MonoTime.now() < deadline) {
                let _ = legacy.pumpOneTurn()
                let _ = opted.pumpOneTurn()
            }
            @Assert(legacy.window().applicationExitPreflight().isSome(), true)
            @Assert(opted.window().applicationExitPreflight().isSome(), true)
            @Assert(unsafe { cjgui_internal_renderer_test_set_application_hidden(1u8, inout noKey) },
                CJGUI_INTERNAL_RENDERER_OK)
            let hideDeadline = MonoTime.now() + 5 * Duration.second
            var readiness: UInt32 = 0u32
            var keyStatus = unsafe { cjgui_internal_renderer_test_observe_current_composable_command_menu(inout readiness) }
            while (keyStatus == CJGUI_INTERNAL_RENDERER_OK && MonoTime.now() < hideDeadline) {
                let _ = opted.pumpOneTurn()
                keyStatus = unsafe { cjgui_internal_renderer_test_observe_current_composable_command_menu(inout readiness) }
            }
            @Assert(keyStatus != CJGUI_INTERNAL_RENDERER_OK && (readiness & 128u32) == 0u32, true)
            @Assert(unsafe { cjgui_internal_renderer_test_invoke_standard_quit_menu_item() }, CJGUI_INTERNAL_RENDERER_OK)
            let _ = opted.pumpOneTurn()
            @Assert(policy.calls, 0)
            @Assert(opted.isOpen() && legacy.isOpen(), true)
            legacy.close()
            @Assert(legacy.isOpen(), false)
            let decisionDeadline = MonoTime.now() + 5 * Duration.second
            while (opted.isOpen() && policy.calls == 0 && MonoTime.now() < decisionDeadline) {
                let _ = opted.pumpOneTurn()
            }
            @Assert(policy.calls, 1)
            @Assert(opted.isOpen(), true)
        } finally {
            internalRendererCompleteApplicationExitRequest()
            let _ = unsafe { cjgui_internal_renderer_test_set_application_hidden(0u8, inout noKey) }
            legacy.close()
            opted.close()
        }
    })
}

@When[os == "macOS"]
@Test
func singleWindowFailedStartAndRepeatCloseKeepSiblingLifecycle(): Unit {
    cjguiMacosOwnerTest({ =>
        let liveOwner = HostStandardQuitOwner()
        let livePolicy = HostStandardQuitPolicy(liveOwner)
        let live = CjguiMacosApplicationHost(liveOwner, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI live sibling", 400u32, 300u32),
            exitDecisionProvider: Some(livePolicy))
        let failedPolicy = HostStandardQuitPolicy(HostStandardQuitOwner())
        let failed = CjguiMacosApplicationHost(HostStandardQuitOwner(), configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI invalid", 0u32, 300u32),
            exitDecisionProvider: Some(failedPolicy))
        @Assert(live.start(), true)
        try {
            @Assert(failed.start(), false)
            failed.close(); failed.close()
            @Assert(failedPolicy.commits, 0)
            @Assert(live.isOpen(), true)
            let ready = MonoTime.now() + 5 * Duration.second
            while (live.window().applicationExitPreflight().isNone() && MonoTime.now() < ready) {
                let _ = live.pumpOneTurn()
            }
            @Assert(live.window().applicationExitPreflight().isSome(), true)
            let _ = live.requestApplicationExit()
            @Assert(livePolicy.calls, 1)
            @Assert(live.isOpen(), true)
            @Assert(livePolicy.commits, 0)
        } finally { failed.close(); live.close() }
    })
}

package cjgui

import std.collection.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

foreign {
    func cjgui_internal_renderer_test_dispatch_session_composable_key_equivalent(
        session: UInt64, keyCode: UInt16, modifiers: UInt64, characters: CString,
        routeFlags: CPointer<UInt32>): Int32
}

private class ShortcutOwnerFreshnessController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant &
    CjguiComposableUiCurrentCommandAvailabilityProvider {
    var draft = ""
    let applied = ""
    var revision: Int64 = 1
    var cancellations: Int64 = 0
    var targetOwner: Int64 = 101
    var locked = false
    public func currentCommandAvailability(commandId: String, target: CjguiComposableUiLayoutNode): ?Bool {
        if (commandId != "fresh.cancel") { return None }
        return Some(target.nodeId == 3 && target.actionName == "CANCEL" &&
            target.resourceId == targetOwner && !locked && draft != applied)
    }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "shortcut-owner-root", CjguiComposableUiStyle())
        root.add(cjguiComposableTextInput(2, "shortcut-owner-text", "Note", draft, 10,
            CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 32)))
        root.add(cjguiComposableButton(3, "shortcut-owner-cancel", "Cancel", "CANCEL", targetOwner,
            CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 32), enabled: draft != applied))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 28 && event.node.nodeId == 2) {
            draft = event.text; revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.nodeId == 3 &&
            event.node.resourceId == targetOwner && draft != applied) {
            draft = applied; revision += 1; cancellations += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func beginSceneRefresh(): Bool { return true }
    public func prepareSceneRefresh(): Bool { return true }
    public func commitSceneRefresh(): Unit { }
    public func rollbackSceneRefresh(): Unit { }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>([
            CjguiComposableUiCommand("fresh.cancel", CjguiComposableUiNodeReference.manual(3),
                "Cancel", CjguiComposableUiShortcut("r"), "Edit", 0, draft != applied, false)])
    }
}

private func shortcutFreshnessSendR(window: CjguiComposableUiWindow): Int32 {
    let r = unsafe { LibC.mallocCString("r") }
    var status: Int32 = -1
    var routeFlags: UInt32 = 0
    try (value = r.asResource()) {
        status = unsafe { cjgui_internal_renderer_test_dispatch_session_composable_key_equivalent(
            window.testSessionToken(), 15u16, 1048576u64, value.value, inout routeFlags) }
    }
    println("SHORTCUT_OWNER_KEY status=${status} route_flags=${routeFlags}")
    return status
}

private func runShortcutOwnerFreshness(mode: Int64): Unit {
    cjguiMacosOwnerTest({ =>
        let owner = ShortcutOwnerFreshnessController()
        if (mode == 3) { owner.draft = "8" }
        let window = CjguiComposableUiWindow(owner,
            configuration: CjguiMacosApplicationWindowConfiguration("CJGUI shortcut owner freshness", 400u32, 300u32))
        @Assert(window.start(), true)
        try {
            let settle = MonoTime.now() + 3 * Duration.second
            while ((window.displayedSceneVersion() <= 0 || window.hasDeferredEventWork()) && MonoTime.now() < settle) {
                let _ = window.pumpEventsWithoutRefresh(1u32)
                let _ = window.refreshAfterDeferredPump()
            }
            @Assert(window.displayedSceneVersion() > 0, true)
            @Assert(window.hasDeferredEventWork(), false)
            @Assert(window.activateWindow(), true)
            @Assert(window.focusAcceptedNodeById(2), true)
            let _ = window.pumpEventsWithoutRefresh(1u32)
            let scene = window.displayedSceneVersion()
            var index: UInt32 = 0u32
            var found = false
            for (node in window.acceptedSceneNodes()) {
                if (node.nodeId == 2) { found = true; break }
                index += 1u32
            }
            @Assert(found, true)
            if (mode == 0 || mode == 1) {
                let text = unsafe { LibC.mallocCString("8") }
                try (value = text.asResource()) {
                    @Assert(unsafe { cjgui_internal_renderer_test_insert_composable_text(
                        window.testSessionToken(), index, value.value) }, CJGUI_INTERNAL_RENDERER_OK)
                }
                let written = MonoTime.now() + 3 * Duration.second
                while (owner.draft != "8" && MonoTime.now() < written) {
                    let _ = window.pumpEventsWithoutRefresh(1u32)
                }
                @Assert(owner.draft, "8")
            }
            if (mode == 1) { owner.targetOwner = 102; owner.revision += 1 }
            if (mode == 3) { owner.locked = true; owner.revision += 1 }
            @Assert(window.displayedSceneVersion(), scene)
            @Assert(shortcutFreshnessSendR(window), CJGUI_INTERNAL_RENDERER_OK)
            var pending: UInt32 = 0
            var enqueuedKind: UInt32 = 0
            var enqueuedNode: UInt64 = 0
            var enqueuedScene: UInt64 = 0
            var pumpedKind: UInt32 = 0
            var pumpedNode: UInt64 = 0
            var pumpedScene: UInt64 = 0
            @Assert(unsafe { cjgui_internal_renderer_test_composable_interaction_trace(window.testSessionToken(),
                inout pending, inout enqueuedKind, inout enqueuedNode, inout enqueuedScene,
                inout pumpedKind, inout pumpedNode, inout pumpedScene) }, CJGUI_INTERNAL_RENDERER_OK)
            @Assert(pending > 0 && enqueuedKind == 34u32, true)
            let deadline = MonoTime.now() + 3 * Duration.second
            while (pumpedKind != 34u32 && MonoTime.now() < deadline) {
                let _ = window.pumpEventsWithoutRefresh(1u32)
                @Assert(unsafe { cjgui_internal_renderer_test_composable_interaction_trace(window.testSessionToken(),
                    inout pending, inout enqueuedKind, inout enqueuedNode, inout enqueuedScene,
                    inout pumpedKind, inout pumpedNode, inout pumpedScene) }, CJGUI_INTERNAL_RENDERER_OK)
            }
            @Assert(pumpedKind, 34u32)
            @Assert(owner.cancellations, if (mode == 0) { 1 } else { 0 })
            @Assert(owner.draft, if (mode == 1 || mode == 3) { "8" } else { "" })
        } finally { window.close() }
    })
}

@When[os == "macOS"]
@Test
func originalShortcutUsesCurrentOwnerAfterEarlierTextBeforeSceneAcceptance(): Unit {
    runShortcutOwnerFreshness(0)
}

@When[os == "macOS"]
@Test
func originalShortcutRejectsReboundOwnerBeforeSceneAcceptance(): Unit {
    runShortcutOwnerFreshness(1)
}

@When[os == "macOS"]
@Test
func originalShortcutRemainsDisabledForCleanOwner(): Unit {
    runShortcutOwnerFreshness(2)
}

@When[os == "macOS"]
@Test
func originalShortcutRejectsOwnerThatBecameLockedAfterAcceptedScene(): Unit {
    runShortcutOwnerFreshness(3)
}

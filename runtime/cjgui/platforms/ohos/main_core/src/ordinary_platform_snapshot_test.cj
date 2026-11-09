package cjgui

import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

@When[os == "macOS"]
foreign { func cjgui_macos_test_legacy_window_queries(reset: UInt32): UInt64 }

private class OrdinaryPlatformSnapshotController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableText(99301, "platform-snapshot-label", "published facts", CjguiComposableUiStyle())
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
}

@When[os == "macOS"]
@Test
func ordinaryPlatformVisibilityConsumesPublishedFactsInBothHosts(): Unit {
    cjguiMacosOwnerTest({ =>
        let app = CjguiMacosApplication()
        try {
            let opened = app.openWindow(OrdinaryPlatformSnapshotController(), configuration:
                CjguiMacosApplicationWindowConfiguration("published platform facts", 400u32, 300u32))
            @Assert(opened.didOpen, true)
            let id = opened.identifier.getOrThrow()
            let window = app.window(id).getOrThrow()
            let deadline = MonoTime.now() + Duration.second * 3
            while (MonoTime.now() < deadline && window.acceptedNodeText("platform-snapshot-label").isNone()) {
                let _ = app.pumpOneTurn()
            }
            let actual = app.windowState(id).getOrThrow()
            @Assert(actual.isVisible, true)
            @Assert(actual.isMinimized, false)
            unsafe { let _ = cjgui_macos_test_legacy_window_queries(1u32) }
            let _ = app.pumpUntilWork(timeoutMs: 16u32)
            let queries = unsafe { cjgui_macos_test_legacy_window_queries(0u32) }
            println("ORDINARY_PLATFORM application_legacy_queries=${queries}")
            @Assert(queries, 0u64)
        } finally { app.close() }
        let host = CjguiMacosApplicationHost(OrdinaryPlatformSnapshotController())
        try {
            @Assert(host.start(), true)
            let deadline = MonoTime.now() + Duration.second * 3
            while (MonoTime.now() < deadline && host.window().acceptedNodeText("platform-snapshot-label").isNone()) {
                let _ = host.pumpOneTurn()
            }
            unsafe { let _ = cjgui_macos_test_legacy_window_queries(1u32) }
            let _ = host.pumpUntilWork(timeoutMs: 16u32)
            @Assert(unsafe { cjgui_macos_test_legacy_window_queries(0u32) }, 0u64)
        } finally { host.close() }
    })
}

package cjgui

import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private class OrdinaryPeerReadyController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableButton(98701,"peer-ready","peer ready 中文","ACT",1,
            CjguiComposableUiStyle(fixedWidth:200,fixedHeight:50),
            interactionStyle:CjguiComposableUiInteractionStyle(hover:CjguiComposableUiPaintStyle(
                background:Some(CjguiComposableUiColor(0.8,0.1,0.1,1.0)))))
    }
    public func applyUiEvent(event:CjguiComposableUiEvent):CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func rejectUiEvent(kind:Int64,node:Int64):CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func requestWindowClose():CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true,shouldClose:true) }
}

@When[os=="macOS"]
@Test
func ordinaryPeerReadyUsesSharedWaitTailWithoutNextCallerTurn():Unit {
    cjguiMacosOwnerTest({ => ordinaryPeerReadyUsesSharedWaitTailWithoutNextCallerTurnBody() })
}

private func ordinaryPeerReadyUsesSharedWaitTailWithoutNextCallerTurnBody(): Unit {
    let app=CjguiMacosApplication()
    try {
        let a=app.openWindow(OrdinaryPeerReadyController(),configuration:CjguiMacosApplicationWindowConfiguration("peer ready A",400u32,300u32))
        let b=app.openWindow(OrdinaryPeerReadyController(),configuration:CjguiMacosApplicationWindowConfiguration("peer ready B",400u32,300u32))
        @Assert(a.didOpen && b.didOpen,true)
        let wa=app.window(a.identifier.getOrThrow()).getOrThrow()
        let wb=app.window(b.identifier.getOrThrow()).getOrThrow()
        for (_ in 0..360) {
            if (wa.windowProjection().submittedFrameIndex>0 && wb.windowProjection().submittedFrameIndex>0 &&
                wa.ownerIdleWaitAllowance(UInt32.Max)==UInt32.Max && wb.ownerIdleWaitAllowance(UInt32.Max)==UInt32.Max) { break }
            let _=app.pumpOneTurn()
        }
        @Assert(wa.windowProjection().submittedFrameIndex>0 && wb.windowProjection().submittedFrameIndex>0,true)
        let previous=app.pumpUntilWork(turnBudgetMs:100u32,timeoutMs:10u32).waitedWindow.getOrThrow()
        // Rotation chooses the OTHER window next; only this peer has work.
        let peer=if (previous.value==a.identifier.getOrThrow().value) { wa } else { wb }
        let _=peer.setReduceMotionEnabled(true)
        @Assert(peer.testApplyInteractionIntent(43u32,98701),true)
        unsafe { cjgui_internal_renderer_test_drawable_gate_close() }
        @Assert(peer.testRefreshInteractionPaint(),false)
        let started=MonoTime.now()
        while (unsafe { cjgui_internal_renderer_test_drawable_gate_entries() }==0u64 &&
            (MonoTime.now()-started).toNanoseconds()<200000000) {}
        @Assert(unsafe { cjgui_internal_renderer_test_drawable_gate_entries() },1u64)
        let before=peer.windowProjection().submittedFrameIndex
        unsafe { cjgui_internal_renderer_test_drawable_gate_open_on_owner_wait() }
        // Logical ordering probe: keep unrelated fixture/FFI cold costs
        // outside its deadline. Normal consumer performance stays at 16/32ms.
        let result=app.pumpUntilWork(turnBudgetMs:100u32,timeoutMs:200u32)
        let after=peer.windowProjection().submittedFrameIndex
        println("ORDINARY_PEER_READY peer=${previous.value} waited=${result.waitedWindow.getOrThrow().value} before=${before} after=${after} wait_ms=${result.eventWaitBudgetMs} work_ms=${result.elapsedBeforeEventWaitMs} waits=${unsafe { cjgui_internal_renderer_test_drawable_gate_owner_wait_opens() }} caller_turns=1")
        @Assert(result.waitedWindow.getOrThrow().value!=previous.value,true)
        @Assert(unsafe { cjgui_internal_renderer_test_drawable_gate_owner_wait_opens() },1u64)
        @Assert(after>before,true)
    } finally { unsafe { cjgui_internal_renderer_test_drawable_gate_open() };app.close() }
}

package cjgui

import std.time.*

@C
struct ActualPairState {
    var generation: UInt64 = 0
    var nonce: UInt64 = 0
    var origin: UInt64 = 0
    var accepted: UInt64 = 0
    var holdHits: UInt64 = 0
    var dequeues: UInt64 = 0
    var decision: UInt64 = 0
    var originalAtHead: UInt64 = 0
}

foreign {
    func cjgui_internal_renderer_test_actual_activation_pair(session: UInt64, nodeId: UInt64): Int32
    func cjgui_internal_renderer_test_actual_pair_snapshot(session: UInt64,
        values: CPointer<ActualPairState>, count: UInt32): Int32
    func cjgui_internal_renderer_test_actual_pair_release(session: UInt64,
        generation: UInt64, nonce: UInt64): Int32
    func cjgui_internal_renderer_test_actual_pair_refresh_decision(session: UInt64,
        decision: UInt64): Unit
    func cjgui_internal_renderer_test_actual_pair_owner_marker(session: UInt64, kind: UInt64,
        revision: UInt64, scene: UInt64, node: UInt64): Unit
}

func fixtureActualPairRefreshDecision(session: UInt64, decision: UInt64): Unit {
    unsafe { cjgui_internal_renderer_test_actual_pair_refresh_decision(session, decision) }
}

private func actualPairState(session: UInt64): ActualPairState {
    var state = ActualPairState()
    if (unsafe { cjgui_internal_renderer_test_actual_pair_snapshot(session, inout state, 8u32) } !=
        CJGUI_INTERNAL_RENDERER_OK) { throw Exception("pair_snapshot_unknown") }
    return state
}

private class ActualPairFixtureController <: CjguiComposableUiController {
    var nativeSession: UInt64 = 0
    var revision: Int64 = 1
    var focuses: Int64 = 0
    var activations: Int64 = 0
    var refused: Int64 = 0
    public func uiSceneVersion(): Int64 { revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(8100, "actual-pair-fixture", CjguiComposableUiStyle())
        root.add(cjguiComposableButton(8101, "actual-pair-button", "Pair", "pair",
            -1, CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 40)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 31) { focuses += 1; revision += 1 }
        if (event.eventKind == 27) { activations += 1; revision += 1 }
        unsafe { cjgui_internal_renderer_test_actual_pair_owner_marker(nativeSession,
            UInt64(event.eventKind), UInt64(revision), UInt64(event.projectionVersion), UInt64(event.node.nodeId)) }
        return CjguiComposableUiDispatchResult(true)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        if (eventKind == 27) { refused += 1 }
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

main(): Int64 {
    let controller = ActualPairFixtureController()
    let window = CjguiComposableUiWindow(controller)
    let budget = CjguiOwnerTurnBudget()
    var result: Int64 = 1
    try {
        if (!window.start() || !window.refresh()) { throw Exception("fixture_start_failed") }
        let origin = window.windowProgress().acceptedSceneVersion
        controller.nativeSession = window.testSessionToken()
        window.useOwnerTurnBudget(budget)
        if (unsafe { cjgui_internal_renderer_test_actual_activation_pair(window.testSessionToken(), 8101u64) } !=
            CJGUI_INTERNAL_RENDERER_OK) { throw Exception("actual_producer_pair_missing") }
        var turn: Int64 = 0
        let until = MonoTime.now() + Duration.second * 3
        var firstOnlyScene: Int64 = -1
        var released = false
        var barrierEstablished = false
        var preReleaseDecision: UInt64 = 0
        while (turn < 150 && MonoTime.now() < until) {
            turn += 1
            let _ = budget.begin()
            let turnSpan = window.beginOwnerTraceTurn(turn)
            let _ = window.pump(0u32)
            let _ = window.refreshIfNeeded()
            if (controller.focuses == 1 && controller.activations == 0 && controller.refused == 0) {
                firstOnlyScene = window.windowProgress().acceptedSceneVersion
            }
            window.endOwnerTraceTurn(turn, turnSpan)
            budget.end()
            let state = actualPairState(window.testSessionToken())
            if (!released && controller.focuses == 1 && controller.activations == 0 &&
                controller.refused == 0 && state.holdHits > 0u64 && state.dequeues == 0u64 &&
                state.originalAtHead == 1u64 &&
                ((state.decision == 1u64 && state.accepted > state.origin) ||
                 (state.decision == 2u64 && state.accepted == state.origin))) {
                barrierEstablished = true
                preReleaseDecision = state.decision
                println("ACTUAL_PAIR_PRE_RELEASE generation=${state.generation} nonce=${state.nonce} " +
                    "origin=${state.origin} accepted=${state.accepted} decision=${state.decision} " +
                    "hold_hits=${state.holdHits} second_dequeues=${state.dequeues} original_head=1 turn=${turn}")
                if (unsafe { cjgui_internal_renderer_test_actual_pair_release(window.testSessionToken(),
                    state.generation, state.nonce) } != CJGUI_INTERNAL_RENDERER_OK) {
                    throw Exception("pair_release_identity_changed")
                }
                released = true
            }
            if (controller.refused != 0 ||
                (controller.activations == 1 && window.windowProgress().acceptedSceneVersion > origin)) { break }
            // Test driver pacing, outside owner work. No production wait is added.
            sleep(Duration.millisecond)
        }
        let accepted = window.windowProgress().acceptedSceneVersion
        let finalState = actualPairState(window.testSessionToken())
        let ok = controller.focuses == 1 && controller.activations == 1 && controller.refused == 0 &&
            firstOnlyScene == origin && accepted > origin && barrierEstablished &&
            preReleaseDecision == 2u64 && finalState.dequeues == 1u64
        println("ACTUAL_PAIR_FIXTURE result=${ok} synthetic_native_producer=true physical_input=false " +
            "origin=${origin} first_only_scene=${firstOnlyScene} accepted=${accepted} " +
            "focuses=${controller.focuses} activations=${controller.activations} refused=${controller.refused} turns=${turn} " +
            "barrier_established=${barrierEstablished} pre_release_decision=${preReleaseDecision} second_dequeues=${finalState.dequeues}")
        result = if (ok) { 0 } else { 1 }
    } catch (e: Exception) {
        println("ACTUAL_PAIR_FIXTURE error=${e.message}")
    } finally {
        window.close()
        CjguiMacosApplicationHost.stopApplicationLoop()
    }
    return result
}

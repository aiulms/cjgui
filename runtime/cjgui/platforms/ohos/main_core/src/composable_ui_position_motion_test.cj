package cjgui

import std.collection.*
import std.math.*
import std.time.*
import cjgui_shared_operation_core.*


private class FPositionMotionController <: CjguiComposableUiController {
    var revision: Int64 = 1
    var resourceId: Int64 = 1
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9850, "position-root", CjguiComposableUiStyle())
        let parent = CjguiComposableUiNode(9851, "position-parent", CJGUI_COMPOSABLE_UI_VERTICAL,
            "", "", "", resourceId,
            CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 80, translateX: 5.0, translateY: 7.0))
        parent.add(CjguiComposableUiNode(9852, "position-child", CJGUI_COMPOSABLE_UI_BUTTON,
            "Move", "", "MOVE", 1,
            CjguiComposableUiStyle(fixedWidth: 90, fixedHeight: 32, translateX: 2.0, translateY: 3.0)))
        root.add(parent)
        return root
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

@Test
func fPositionDriverKeepsRejectedSampleOutOfAcceptedCheckpoint(): Unit {
    let driver = CjguiComposableUiAnimationDriver(501)
    let binding = CjguiComposableUiAnimationBinding(9851, windowInstanceToken: 501,
        acceptedBindingEpoch: 1)
    let initial = CjguiComposableUiPositionValue(5.0, 7.0)
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 1000)
    @Assert(driver.animatePosition("semantic:position-parent", binding, initial,
        CjguiComposableUiPositionValue(105.0, 7.0), slow, 0.0), true)
    let first = driver.positionSampleFor("semantic:position-parent", binding) ??
        CjguiComposableUiPositionSample("", binding, initial, initial, 0)
    @Assert(first.value.x, 5.0)
    let staged = HashMap<String, CjguiComposableUiPositionSample>()
    staged.add("semantic:position-parent", first)
    let stagedRevision = driver.positionRevision()
    @Assert(driver.advance(500.0), true)
    // No native acceptance: the speculative midpoint cannot become a
    // retarget start or public presented position.
    @Assert((driver.positionAcceptedFor("semantic:position-parent") ?? initial).x, 5.0)
    @Assert(driver.animatePosition("semantic:position-parent", binding, initial,
        CjguiComposableUiPositionValue(-45.0, 7.0), slow, 500.0), true)
    let retry = driver.positionSampleFor("semantic:position-parent", binding) ?? first
    @Assert(retry.value.x, 5.0)
    // An older ticket can still accept its own immutable sample; it must not
    // erase the newer target or its pending revision.
    driver.markPositionSamplesAccepted(staged, stagedRevision)
    @Assert((driver.positionAcceptedFor("semantic:position-parent") ?? initial).x, 5.0)
    @Assert((driver.positionTargetFor("semantic:position-parent") ?? initial).x, -45.0)
    @Assert(driver.hasPendingPresentation(), true)
    @Assert(driver.advance(750.0), true)
    let accepted = HashMap<String, CjguiComposableUiPositionSample>()
    accepted.add("semantic:position-parent", driver.positionSampleFor("semantic:position-parent", binding) ?? first)
    driver.markPositionSamplesAccepted(accepted, driver.positionRevision())
    @Assert((driver.positionAcceptedFor("semantic:position-parent") ?? initial).x < 5.0, true)
    @Assert(driver.hasPendingPresentation(), true) // paint flag has not been acknowledged
    driver.markPresentationCommitted()
    @Assert(driver.hasPendingPresentation(), false)
}

@Test
func fPositionWindowZeroDurationPublishesOneAcceptedGeometryAndStops(): Unit {
    let controller = FPositionMotionController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:position-parent"
    let childBefore = window.acceptedNodeVisualBounds("position-child") ??
        CjguiComposableUiVisualRect(0.0, 0.0, 0.0, 0.0)
    let before = window.windowProgress()
    let token = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(window.animateNodeTranslation(key, 25.0, 17.0, spec: zero, atTime: MonoTime.now(),
        acceptedToken: Some(token)), true)
    let childAfter = window.acceptedNodeVisualBounds("position-child") ??
        CjguiComposableUiVisualRect(0.0, 0.0, 0.0, 0.0)
    @Assert(childAfter.x - childBefore.x, 20.0)
    @Assert(childAfter.y - childBefore.y, 10.0)
    let status = window.animatedNodeTranslation(key) ?? CjguiComposableUiPositionStatus(
        CjguiComposableUiPositionValue(0.0, 0.0), CjguiComposableUiPositionValue(0.0, 0.0), token,
        "", 0, 0, false)
    @Assert(status.target.x, 25.0)
    @Assert(status.presented.x, 25.0)
    @Assert(status.acceptedSceneVersion > before.acceptedSceneVersion, true)
    @Assert(status.active, false)
    @Assert(window.needsAnimationTick(), false)
    let settledVersion = status.acceptedSceneVersion
    @Assert(window.animateNodeTranslation(key, Float64.NaN, 1.0, spec: zero, atTime: MonoTime.now()), false)
    @Assert(window.windowProgress().acceptedSceneVersion, settledVersion)
    @Assert((window.animatedNodeTranslation(key) ?? status).target.x, 25.0)
    controller.resourceId = 2
    controller.revision += 1
    @Assert(window.refresh(), true)
    @Assert(window.animatedNodeTranslation(key).isNone(), true)
    @Assert(window.animateNodeTranslation(key, 0.0, 0.0, spec: zero, atTime: MonoTime.now(),
        acceptedToken: Some(token)), false)
    window.close()
}

@Test
func fPositionNativePresentFailureKeepsOldVisualThenRetriesTerminal(): Unit {
    let window = CjguiComposableUiWindow(FPositionMotionController())
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:position-parent"
    let before = window.windowProgress()
    let original = window.acceptedNodeVisualBounds("position-child") ??
        CjguiComposableUiVisualRect(0.0, 0.0, 0.0, 0.0)
    window.testRejectNextPositionPresentation()
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(window.animateNodeTranslation(key, 25.0, 17.0, spec: zero, atTime: MonoTime.now()), true)
    let refused = window.animatedNodeTranslation(key) ?? CjguiComposableUiPositionStatus(
        CjguiComposableUiPositionValue(0.0, 0.0), CjguiComposableUiPositionValue(0.0, 0.0),
        CjguiComposableUiAnimationBinding(-1), "", 0, 0, false)
    @Assert(refused.target.x, 25.0)
    @Assert(refused.presented.x, 5.0)
    @Assert(window.windowProgress().acceptedSceneVersion, before.acceptedSceneVersion)
    let held = window.acceptedNodeVisualBounds("position-child") ?? original
    @Assert(held.x, original.x)
    @Assert(held.y, original.y)
    @Assert(window.needsAnimationTick(), true)
    let _ = window.advanceAnimations(atTime: MonoTime.now())
    let recovered = window.animatedNodeTranslation(key) ?? refused
    let moved = window.acceptedNodeVisualBounds("position-child") ?? original
    @Assert(recovered.presented.x, 25.0)
    @Assert(recovered.presented.y, 17.0)
    @Assert(moved.x - original.x, 20.0)
    @Assert(moved.y - original.y, 10.0)
    @Assert(window.needsAnimationTick(), false)
    let settled = window.windowProgress().acceptedSceneVersion
    let _ = window.advanceAnimations(atTime: MonoTime.now())
    @Assert(window.windowProgress().acceptedSceneVersion, settled)
    window.close()
}

@Test
func fPositionPublicTargetRequiresAcceptedIdentityAndTracksFailedPresentation(): Unit {
    let controller = FPositionMotionController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    @Assert(window.positionMotionTargets().size, 0)
    @Assert(window.exposeAcceptedPositionMotionTarget("semantic:missing"), false)
    @Assert(window.exposeAcceptedPositionMotionTarget("semantic:position-parent"), true)
    @Assert(window.positionMotionTargets().size, 1)
    let nodeId = window.positionMotionTargets()[0]
    let initial = window.positionMotionRead(nodeId) ??
        CjguiSharedOperationPositionMotionFact(-1, -1, "", "", "", 0, 0, "", 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0, 0, false, false, "")
    @Assert(initial.presentedX, 5.0)
    @Assert(initial.requestRevision, initial.acceptedRequestRevision)
    let invalid = window.positionMotionSet(nodeId, initial.casToken, Float64.NaN, 17.0,
        CjguiGeneratedMotionRegistry.POSITION_TRANSITION)
    @Assert(invalid.admitted, false)
    @Assert((window.positionMotionRead(nodeId) ?? initial).casToken, initial.casToken)
    let _ = window.setReduceMotionEnabled(true)
    window.testRejectNextPositionPresentation()
    let requested = window.positionMotionSet(nodeId, initial.casToken, 25.0, 17.0,
        CjguiGeneratedMotionRegistry.POSITION_TRANSITION)
    @Assert(requested.admitted, true)
    let refused = window.positionMotionRead(nodeId) ?? initial
    @Assert(refused.requestedX, 25.0)
    @Assert(refused.presentedX, 5.0)
    @Assert(refused.requestRevision > refused.acceptedRequestRevision, true)
    @Assert(window.positionMotionSet(nodeId, initial.casToken, 30.0, 17.0,
        CjguiGeneratedMotionRegistry.POSITION_TRANSITION).reason, "version_conflict")
    let _ = window.advanceAnimations(atTime: MonoTime.now())
    let recovered = window.positionMotionRead(nodeId) ?? initial
    @Assert(recovered.presentedX, 25.0)
    @Assert(recovered.requestRevision, recovered.acceptedRequestRevision)
    @Assert(recovered.lastFailure, "none")
    @Assert(window.positionMotionClear(nodeId, initial.casToken).reason, "version_conflict")
    @Assert(window.positionMotionClear(nodeId, recovered.casToken).admitted, true)
    let cleared = window.positionMotionRead(nodeId) ?? initial
    @Assert(cleared.presentedX, 5.0)
    controller.resourceId = 2
    controller.revision += 1
    @Assert(window.refresh(), true)
    @Assert(window.positionMotionRead(nodeId).isNone(), true)
    window.close()
}

@Test
func fPositionPublicReadKeepsFailedIntermediateFramePendingAfterRequestAccepted(): Unit {
    let window = CjguiComposableUiWindow(FPositionMotionController())
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:position-parent"
    @Assert(window.exposeAcceptedPositionMotionTarget(key), true)
    let nodeId = window.positionMotionTargets()[0]
    let start = MonoTime.now()
    @Assert(window.animateNodeTranslation(key, 45.0, 17.0,
        spec: CjguiComposableUiAnimationSpec.tween(durationMs: 1000), atTime: start), true)
    let _ = window.advanceAnimations(atTime: start + Duration.millisecond * 100)
    let first = window.positionMotionRead(nodeId) ??
        CjguiSharedOperationPositionMotionFact(-1, -1, "", "", "", 0, 0, "", 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0, 0, false, false, "")
    @Assert(first.requestRevision, first.acceptedRequestRevision)
    @Assert(first.presentedX > 5.0, true)
    window.testRejectNextPositionPresentation()
    let _ = window.advanceAnimations(atTime: start + Duration.millisecond * 200)
    let rejected = window.positionMotionRead(nodeId) ?? first
    @Assert(rejected.presentedX, first.presentedX)
    @Assert(rejected.requestRevision, rejected.acceptedRequestRevision)
    @Assert(rejected.pending, true)
    @Assert(rejected.lastFailure, "internal_error")
    let _ = window.advanceAnimations(atTime: start + Duration.millisecond * 300)
    let recovered = window.positionMotionRead(nodeId) ?? first
    @Assert(recovered.presentedX > first.presentedX, true)
    @Assert(recovered.lastFailure, "none")
    window.testRejectNextPositionPresentation()
    let _ = window.advanceAnimations(atTime: start + Duration.millisecond * 1000)
    let terminalRejected = window.positionMotionRead(nodeId) ?? first
    @Assert(terminalRejected.presentedX, recovered.presentedX)
    @Assert(terminalRejected.active, false)
    @Assert(terminalRejected.pending, true)
    @Assert(terminalRejected.lastFailure, "internal_error")
    let _ = window.advanceAnimations(atTime: start + Duration.millisecond * 1100)
    let terminal = window.positionMotionRead(nodeId) ?? first
    @Assert(terminal.presentedX, 45.0)
    @Assert(terminal.presentedY, 17.0)
    @Assert(terminal.pending, false)
    @Assert(terminal.lastFailure, "none")
    window.close()
}

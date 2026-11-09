package cjgui

import std.collection.*
import std.time.*

private class FPositionReviewChainController <: CjguiComposableUiController {
    var revision: Int64 = 1
    var secondDeclaredX: Float64 = 800.0
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9900, "position-review-root", CjguiComposableUiStyle())
        var parent = root
        var index: Int64 = 0
        while (index < 5) {
            let child = CjguiComposableUiNode(9901 + index, "position-review-${index}",
                CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1,
                CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 40,
                    translateX: if (index == 1) { secondDeclaredX } else { 800.0 }))
            parent.add(child)
            parent = child
            index += 1
        }
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

private class FPositionReviewIdentityController <: CjguiComposableUiController {
    var revision: Int64 = 1
    var incarnation: Int64 = 1
    var index: Int64 = 0
    var resourceId: Int64 = 1
    var invalidCandidate: Bool = false
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(9920, "position-review-identity-root", CjguiComposableUiStyle())
        root.add(CjguiComposableUiNode(9921 + index, "position-review-identity-${index}",
            CJGUI_COMPOSABLE_UI_BUTTON, "Move", "", "MOVE", resourceId,
            CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 40,
                translateX: if (invalidCandidate) { 2048.0 } else { 0.0 }),
            semanticIncarnation: incarnation))
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
func fPositionReviewOldChannelSampleMustRebaseRebuiltChannel(): Unit {
    let driver = CjguiComposableUiAnimationDriver(778)
    let binding = CjguiComposableUiAnimationBinding(9921, windowInstanceToken: 778,
        acceptedBindingEpoch: 1)
    let initial = CjguiComposableUiPositionValue(0.0, 0.0)
    let spec = CjguiComposableUiAnimationSpec.tween(durationMs: 1000)
    let key = "semantic:position-review-identity-0"
    @Assert(driver.animatePosition(key, binding, initial, CjguiComposableUiPositionValue(100.0, 0.0),
        spec, 0.0), true)
    @Assert(driver.advance(500.0), true)
    let pendingSample = driver.positionSampleFor(key, binding) ??
        CjguiComposableUiPositionSample(key, binding, initial, initial, 0)
    @Assert(pendingSample.value.x > 0.0, true)
    let staged = HashMap<String, CjguiComposableUiPositionSample>()
    staged.add(key, pendingSample)
    let stagedRevision = driver.positionRevision()
    @Assert(driver.cancelPosition(key), true)
    @Assert(driver.animatePosition(key, binding, initial, CjguiComposableUiPositionValue(200.0, 0.0),
        spec, 500.0), true)
    driver.markPositionSamplesAccepted(staged, stagedRevision)
    @Assert((driver.positionAcceptedFor(key) ?? initial).x, pendingSample.value.x)
    @Assert((driver.positionTargetFor(key) ?? initial).x, 200.0)
    @Assert(driver.advance(600.0), true)
    let after = driver.positionSampleFor(key, binding) ?? pendingSample
    @Assert(after.value.x >= pendingSample.value.x, true)
}

@Test
func fPositionReviewOldPaintReceiptCannotAcknowledgeLaterTerminalValue(): Unit {
    let driver = CjguiComposableUiAnimationDriver(778)
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    let key = "semantic:position-review-paint"
    @Assert(driver.animateOpacity(key, 9921, 1.0, spec: zero, nowMs: 0.0), true)
    let olderReceipt = driver.presentationRevision()
    @Assert(driver.animateOpacity(key, 9921, 0.0, spec: zero, nowMs: 0.0), true)
    driver.markPresentationCommitted(revision: olderReceipt)
    @Assert(driver.hasPendingPresentation(), true)
    @Assert(driver.alphaMultiplierFor(key, 9921), 0.0)
    driver.markPresentationCommitted(revision: driver.presentationRevision())
    @Assert(driver.hasPendingPresentation(), false)
    @Assert(driver.needsTick(), false)

    @Assert(driver.animateEffectGroupOpacity(key, 9921, 0.4, 0.2, spec: zero, nowMs: 0.0), true)
    let groupReceipt = driver.presentationRevision()
    @Assert(driver.animateEffectGroupOpacity(key, 9921, 0.4, 1.0, spec: zero, nowMs: 0.0), true)
    driver.markPresentationCommitted(revision: groupReceipt)
    @Assert(driver.hasPendingPresentation(), true)
    @Assert(driver.effectGroupOpacityPresented(key) ?? 0.0, 1.0)
    driver.markPresentationCommitted(revision: driver.presentationRevision())
    @Assert(driver.needsTick(), false)
}

@Test
func fPositionPendingReviewOldTicketKeepsNewTerminalWorkAndRebasesRecreatedChannel(): Unit {
    let controller = FPositionReviewIdentityController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    // A normal macOS sidecar is synchronous. The testing sidecar alone holds
    // the real staged native commit until explicit test resolution.
    if (!window.testHoldNextComposablePresent()) {
        window.close()
        return
    }
    let key = "semantic:position-review-identity-0"
    let start = MonoTime.now()
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 1000,
        easing: CjguiComposableUiAnimationEasing.LINEAR)
    @Assert(window.animateNodeTranslation(key, 100.0, 0.0, spec: slow, atTime: start), true)
    let _ = window.advanceAnimations(atTime: start + Duration.millisecond * 500)
    let oldFrame = window.windowProgress().acceptedSceneVersion
    @Assert((window.animatedNodeTranslation(key) ?? CjguiComposableUiPositionStatus(
        CjguiComposableUiPositionValue(-1.0, 0.0), CjguiComposableUiPositionValue(-1.0, 0.0),
        CjguiComposableUiAnimationBinding(-1), "", 0, 0, false)).presented.x, 0.0)
    @Assert(window.cancelNodeTranslationAnimation(key), true)
    @Assert(window.animateNodeTranslation(key, 200.0, 0.0, spec: slow,
        atTime: start + Duration.millisecond * 500), true)
    @Assert(window.windowProgress().acceptedSceneVersion, oldFrame)
    @Assert(window.testResolvePendingComposablePresent(), true)
    // This call settles the old ticket. It must publish x=50 before the new
    // channel projects; the recreated channel keeps target 200.
    let _ = window.refreshIfNeeded()
    let afterOld = window.animatedNodeTranslation(key) ?? CjguiComposableUiPositionStatus(
        CjguiComposableUiPositionValue(-1.0, 0.0), CjguiComposableUiPositionValue(-1.0, 0.0),
        CjguiComposableUiAnimationBinding(-1), "", 0, 0, false)
    @Assert(afterOld.presented.x > 45.0 && afterOld.presented.x < 55.0, true)
    @Assert(afterOld.target.x, 200.0)
    let _ = window.advanceAnimations(atTime: start + Duration.millisecond * 600)
    let advanced = window.animatedNodeTranslation(key) ?? afterOld
    @Assert(advanced.presented.x >= afterOld.presented.x, true)
    @Assert(advanced.presented.x < 200.0, true)
    window.close()

    let alphaWindow = CjguiComposableUiWindow(FPositionReviewIdentityController())
    @Assert(alphaWindow.start(), true)
    @Assert(alphaWindow.refresh(), true)
    @Assert(alphaWindow.testHoldNextComposablePresent(), true)
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(alphaWindow.animateNodeTranslation(key, 30.0, 0.0, spec: zero,
        atTime: MonoTime.now()), true)
    let alphaOldFrame = alphaWindow.windowProgress().acceptedSceneVersion
    @Assert(alphaWindow.animateNodeOpacity(key, 0.0, spec: zero, atTime: MonoTime.now()), true)
    @Assert(alphaWindow.windowProgress().acceptedSceneVersion, alphaOldFrame)
    @Assert(alphaWindow.testResolvePendingComposablePresent(), true)
    let _ = alphaWindow.refreshIfNeeded()
    @Assert(alphaWindow.needsAnimationTick(), true)
    let _ = alphaWindow.advanceAnimations(atTime: MonoTime.now())
    @Assert(alphaWindow.animatedNodeOpacity(key) ?? 1.0, 0.0)
    @Assert(alphaWindow.needsAnimationTick(), false)
    alphaWindow.close()
}

@Test
func fPositionReviewJointTargetsAndClearMustPreflightWholeChain(): Unit {
    let window = CjguiComposableUiWindow(FPositionReviewChainController())
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let first = "semantic:position-review-0"
    let second = "semantic:position-review-1"
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 1000)
    let now = MonoTime.now()
    @Assert(window.animateNodeTranslation(first, 880.0, 0.0, spec: slow, atTime: now), true)
    // Each target alone makes 4080; their union makes 4160 and must be refused.
    @Assert(window.animateNodeTranslation(second, 880.0, 0.0, spec: slow, atTime: now), false)
    @Assert(window.animatedNodeTranslation(second).isNone(), true)
    window.close()

    let clearWindow = CjguiComposableUiWindow(FPositionReviewChainController())
    @Assert(clearWindow.start(), true)
    @Assert(clearWindow.refresh(), true)
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(clearWindow.animateNodeTranslation(first, 0.0, 0.0, spec: zero, atTime: MonoTime.now()), true)
    @Assert(clearWindow.animateNodeTranslation(second, 1024.0, 0.0, spec: zero, atTime: MonoTime.now()), true)
    // Restoring first's declaration (800) would make 4224.
    @Assert(clearWindow.cancelNodeTranslationAnimation(first), false)
    let held = clearWindow.animatedNodeTranslation(first) ?? CjguiComposableUiPositionStatus(
        CjguiComposableUiPositionValue(-1.0, -1.0), CjguiComposableUiPositionValue(-1.0, -1.0),
        CjguiComposableUiAnimationBinding(-1), "", 0, 0, false)
    @Assert(held.target.x, 0.0)
    clearWindow.close()
}

@Test
func fPositionReviewAcceptedDeclarationMustPreflightSurvivingMotionTargets(): Unit {
    let controller = FPositionReviewChainController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let first = "semantic:position-review-0"
    let slow = CjguiComposableUiAnimationSpec.tween(durationMs: 1000)
    @Assert(window.animateNodeTranslation(first, 880.0, 0.0, spec: slow,
        atTime: MonoTime.now()), true)
    let acceptedVersion = window.windowProgress().acceptedSceneVersion
    // The declaration itself totals 4050, but its union with the surviving
    // 880 target totals 4130. The candidate must not replace the old scene.
    controller.secondDeclaredX = 850.0
    controller.revision += 1
    @Assert(window.refresh(), false)
    @Assert(window.windowProgress().acceptedSceneVersion, acceptedVersion)
    @Assert((window.animatedNodeTranslation(first) ?? CjguiComposableUiPositionStatus(
        CjguiComposableUiPositionValue(-1.0, -1.0), CjguiComposableUiPositionValue(-1.0, -1.0),
        CjguiComposableUiAnimationBinding(-1), "", 0, 0, false)).target.x, 880.0)
    controller.secondDeclaredX = 810.0
    controller.revision += 1
    @Assert(window.refresh(), true)
    window.close()
}

@Test
func fPositionReviewIncarnationRetiresAnimationAndPublicExposure(): Unit {
    let controller = FPositionReviewIdentityController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let key = "semantic:position-review-identity-0"
    @Assert(window.exposeAcceptedPositionMotionTarget(key), true)
    let oldToken = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    let zero = CjguiComposableUiAnimationSpec.tween(durationMs: 0)
    @Assert(window.animateNodeTranslation(key, 20.0, 0.0, spec: zero, atTime: MonoTime.now(),
        acceptedToken: Some(oldToken)), true)
    controller.revision += 1
    @Assert(window.refresh(), true)
    @Assert((window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1))
        .matches(oldToken), true)
    @Assert(window.positionMotionTargets().size, 1)
    controller.invalidCandidate = true
    controller.incarnation = 2
    controller.revision += 1
    @Assert(window.refresh(), false)
    @Assert((window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1))
        .matches(oldToken), true)
    @Assert(window.positionMotionTargets().size, 1)
    controller.invalidCandidate = false
    controller.incarnation = 2
    controller.revision += 1
    @Assert(window.refresh(), true)
    let newToken = window.acceptedAnimationBindingToken(key) ?? CjguiComposableUiAnimationBinding(-1)
    @Assert(newToken.matches(oldToken), false)
    @Assert(window.animatedNodeTranslation(key).isNone(), true)
    @Assert(window.positionMotionTargets().size, 0)
    @Assert(window.animateNodeTranslation(key, 30.0, 0.0, spec: zero, atTime: MonoTime.now(),
        acceptedToken: Some(oldToken)), false)
    @Assert(window.exposeAcceptedPositionMotionTarget(key), true)
    @Assert(window.positionMotionTargets().size, 1)
    controller.resourceId = 2
    controller.revision += 1
    @Assert(window.refresh(), true)
    @Assert(window.positionMotionTargets().size, 0)
    window.close()
}

@Test
func fPositionReviewExposureCapacityReclaimsAcceptedRetirements(): Unit {
    let controller = FPositionReviewIdentityController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    var index: Int64 = 0
    while (index < 33) {
        let key = "semantic:position-review-identity-${index}"
        @Assert(window.exposeAcceptedPositionMotionTarget(key), true)
        @Assert(window.positionMotionTargets().size, 1)
        if (index < 32) {
            controller.index += 1
            controller.revision += 1
            @Assert(window.refresh(), true)
            @Assert(window.positionMotionTargets().size, 0)
        }
        index += 1
    }
    window.close()
}

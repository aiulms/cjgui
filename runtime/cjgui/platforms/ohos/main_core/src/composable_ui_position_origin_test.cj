package cjgui

import std.collection.*
import std.math.*

@Test
func fPositionOriginOldOrdinaryReceiptAfterRebaseKeepsRecreatedChannelTarget(): Unit {
    let driver = CjguiComposableUiAnimationDriver(861)
    let key = "semantic:origin-recreated-pending"
    let binding = CjguiComposableUiAnimationBinding(8611, windowInstanceToken: 861, acceptedBindingEpoch: 1)
    let zero = CjguiComposableUiPositionValue(0.0, 0.0)
    let spec = CjguiComposableUiAnimationSpec.tween(durationMs: 1000,
        easing: CjguiComposableUiAnimationEasing.LINEAR)
    @Assert(driver.animatePosition(key, binding, zero, CjguiComposableUiPositionValue(0.0, 100.0), spec, 0.0), true)
    let initial = driver.positionSampleFor(key, binding) ?? CjguiComposableUiPositionSample(key, binding, zero, zero, 0)
    let rebase = CjguiComposableUiPositionOriginRebase(originTestTicket(driver, key, binding),
        CjguiComposableUiPositionValue(0.0, 58.0))
    let shifted = driver.rebasePositionSample(initial, rebase) ?? initial
    driver.markPositionSamplesAccepted(originTestSampleMap(shifted), driver.positionRevision(),
        originRebases: originTestRebaseMap(key, rebase))
    @Assert(driver.advance(500.0), true)
    let oldPending = driver.positionSampleFor(key, binding) ?? shifted
    let stagedRevision = driver.positionRevision()
    @Assert(oldPending.value.y, 108.0)
    @Assert(driver.cancelPosition(key), true)
    @Assert(driver.animatePosition(key, binding, shifted.value, CjguiComposableUiPositionValue(0.0, 300.0),
        spec, 500.0), true)
    // This ordinary native receipt predates channel recreation, but its
    // accepted layout already uses the rebased origin. It still owns pixels.
    driver.markPositionSamplesAccepted(originTestSampleMap(oldPending), stagedRevision)
    @Assert((driver.positionAcceptedFor(key) ?? shifted.value).y, oldPending.value.y)
    @Assert((driver.positionTargetFor(key) ?? zero).y, 300.0)
}

@Test
func fPositionOriginScalarStartMustPreflightBeforeCandidateAcceptance(): Unit {
    let driver = CjguiComposableUiAnimationDriver(851)
    let key = "semantic:origin-start-boundary"
    let binding = CjguiComposableUiAnimationBinding(8511, windowInstanceToken: 851, acceptedBindingEpoch: 1)
    let initial = CjguiComposableUiPositionValue(0.0, 1000.0)
    let zero = CjguiComposableUiPositionValue(0.0, 0.0)
    @Assert(driver.animatePosition(key, binding, initial, zero,
        CjguiComposableUiAnimationSpec.tween(durationMs: 1000,
            easing: CjguiComposableUiAnimationEasing.LINEAR), 0.0), true)
    @Assert(driver.advance(500.0), true)
    let sample = driver.positionSampleFor(key, binding) ?? CjguiComposableUiPositionSample(key, binding, initial, zero, 0)
    driver.markPositionSamplesAccepted(originTestSampleMap(sample), driver.positionRevision())
    // Current/accepted 500 + 58 and target 0 + 58 fit, but the live tween
    // still owns start=1000. Native must never accept an uncommittable rebase.
    let rebase = CjguiComposableUiPositionOriginRebase(originTestTicket(driver, key, binding),
        CjguiComposableUiPositionValue(0.0, 58.0))
    @Assert(driver.rebasePositionSample(sample, rebase).isNone(), true)
    @Assert((driver.positionAcceptedFor(key) ?? initial).y, 500.0)
    @Assert((driver.positionTargetFor(key) ?? initial).y, 0.0)
}

private func originTestNear(actual: Float64, expected: Float64, tolerance!: Float64 = 1.0e-8): Bool {
    return abs(actual - expected) <= tolerance
}

private func originTestTicket(driver: CjguiComposableUiAnimationDriver, identityKey: String,
    binding: CjguiComposableUiAnimationBinding, requestRevision!: Int64 = 1): CjguiComposableUiPositionOriginTicket {
    let state = driver.positionOriginStateFor(identityKey, binding) ?? CjguiComposableUiPositionOriginState(-1, -1)
    return CjguiComposableUiPositionOriginTicket(identityKey, binding, "origin-test-session", 41, 7,
        state.channelGeneration, state.originRevision, requestRevision)
}

private func originTestSampleMap(sample: CjguiComposableUiPositionSample): HashMap<String,
    CjguiComposableUiPositionSample> {
    let result = HashMap<String, CjguiComposableUiPositionSample>()
    result.add(sample.identityKey, sample)
    return result
}

private func originTestRebaseMap(identityKey: String, rebase: CjguiComposableUiPositionOriginRebase): HashMap<String,
    CjguiComposableUiPositionOriginRebase> {
    let result = HashMap<String, CjguiComposableUiPositionOriginRebase>()
    result.add(identityKey, rebase)
    return result
}

@Test
func fPositionOriginSpringRebasePreservesSampleAndVelocitySequence(): Unit {
    let original = CjguiComposableUiAnimationDriver(801)
    let shifted = CjguiComposableUiAnimationDriver(802)
    let key = "semantic:origin-spring"
    let originalBinding = CjguiComposableUiAnimationBinding(8011, windowInstanceToken: 801, acceptedBindingEpoch: 1)
    let shiftedBinding = CjguiComposableUiAnimationBinding(8011, windowInstanceToken: 802, acceptedBindingEpoch: 1)
    let initial = CjguiComposableUiPositionValue(-80.0, 30.0)
    let target = CjguiComposableUiPositionValue(160.0, -40.0)
    let spring = CjguiComposableUiAnimationSpec.spring()
    @Assert(original.animatePosition(key, originalBinding, initial, target, spring, 0.0), true)
    @Assert(shifted.animatePosition(key, shiftedBinding, initial, target, spring, 0.0), true)
    @Assert(original.advance(300.0), true)
    @Assert(shifted.advance(300.0), true)

    let originalAt300 = original.positionSampleFor(key, originalBinding) ?? CjguiComposableUiPositionSample(key,
        originalBinding, initial, initial, 0)
    let shiftedAt300 = shifted.positionSampleFor(key, shiftedBinding) ?? CjguiComposableUiPositionSample(key,
        shiftedBinding, initial, initial, 0)
    original.markPositionSamplesAccepted(originTestSampleMap(originalAt300), original.positionRevision())
    let ticket = originTestTicket(shifted, key, shiftedBinding)
    let rebase = CjguiComposableUiPositionOriginRebase(ticket, CjguiComposableUiPositionValue(58.0, -17.0))
    let rebasedAt300 = shifted.rebasePositionSample(shiftedAt300, rebase) ?? shiftedAt300
    shifted.markPositionSamplesAccepted(originTestSampleMap(rebasedAt300), shifted.positionRevision(),
        originRebases: originTestRebaseMap(key, rebase))

    @Assert((shifted.positionOriginStateFor(key, shiftedBinding) ??
        CjguiComposableUiPositionOriginState(-1, -1)).originRevision, 1)
    @Assert(originTestNear(rebasedAt300.value.x, originalAt300.value.x + 58.0), true)
    @Assert(originTestNear(rebasedAt300.value.y, originalAt300.value.y - 17.0), true)
    @Assert(originTestNear(rebasedAt300.velocity.x, originalAt300.velocity.x), true)
    @Assert(originTestNear(rebasedAt300.velocity.y, originalAt300.velocity.y), true)

    for (time in [308.0, 344.0, 416.0, 552.0]) {
        @Assert(original.advance(time), true)
        @Assert(shifted.advance(time), true)
        let originalSample = original.positionSampleFor(key, originalBinding) ?? originalAt300
        let shiftedSample = shifted.positionSampleFor(key, shiftedBinding) ?? rebasedAt300
        @Assert(originTestNear(shiftedSample.value.x - 58.0, originalSample.value.x), true)
        @Assert(originTestNear(shiftedSample.value.y + 17.0, originalSample.value.y), true)
        @Assert(originTestNear(shiftedSample.velocity.x, originalSample.velocity.x), true)
        @Assert(originTestNear(shiftedSample.velocity.y, originalSample.velocity.y), true)
        original.markPositionSamplesAccepted(originTestSampleMap(originalSample), original.positionRevision())
        shifted.markPositionSamplesAccepted(originTestSampleMap(shiftedSample), shifted.positionRevision())
    }
    @Assert(originTestNear((shifted.positionTargetFor(key) ?? target).x - 58.0, target.x), true)
    @Assert(originTestNear((shifted.positionTargetFor(key) ?? target).y + 17.0, target.y), true)
}

@Test
func fPositionOriginTweenRebaseKeepsOriginalDeadline(): Unit {
    let original = CjguiComposableUiAnimationDriver(811)
    let shifted = CjguiComposableUiAnimationDriver(812)
    let key = "semantic:origin-tween"
    let originalBinding = CjguiComposableUiAnimationBinding(8111, windowInstanceToken: 811, acceptedBindingEpoch: 1)
    let shiftedBinding = CjguiComposableUiAnimationBinding(8111, windowInstanceToken: 812, acceptedBindingEpoch: 1)
    let initial = CjguiComposableUiPositionValue(0.0, -70.0)
    let target = CjguiComposableUiPositionValue(0.0, 100.0)
    let tween = CjguiComposableUiAnimationSpec.tween(durationMs: 1000)
    @Assert(original.animatePosition(key, originalBinding, initial, target, tween, 0.0), true)
    @Assert(shifted.animatePosition(key, shiftedBinding, initial, target, tween, 0.0), true)
    @Assert(original.advance(400.0), true)
    @Assert(shifted.advance(400.0), true)

    let originalAt400 = original.positionSampleFor(key, originalBinding) ?? CjguiComposableUiPositionSample(key,
        originalBinding, initial, initial, 0)
    let shiftedAt400 = shifted.positionSampleFor(key, shiftedBinding) ?? CjguiComposableUiPositionSample(key,
        shiftedBinding, initial, initial, 0)
    original.markPositionSamplesAccepted(originTestSampleMap(originalAt400), original.positionRevision())
    let rebase = CjguiComposableUiPositionOriginRebase(originTestTicket(shifted, key, shiftedBinding),
        CjguiComposableUiPositionValue(0.0, 58.0))
    let rebasedAt400 = shifted.rebasePositionSample(shiftedAt400, rebase) ?? shiftedAt400
    shifted.markPositionSamplesAccepted(originTestSampleMap(rebasedAt400), shifted.positionRevision(),
        originRebases: originTestRebaseMap(key, rebase))

    @Assert(original.advance(999.0), true)
    @Assert(shifted.advance(999.0), true)
    let beforeDeadline = original.positionSampleFor(key, originalBinding) ?? originalAt400
    let shiftedBeforeDeadline = shifted.positionSampleFor(key, shiftedBinding) ?? rebasedAt400
    @Assert(originTestNear(shiftedBeforeDeadline.value.y - 58.0, beforeDeadline.value.y), true)
    @Assert(shiftedBeforeDeadline.value.y < 158.0, true)
    @Assert(original.advance(1000.0), true)
    @Assert(shifted.advance(1000.0), true)
    let originalDone = original.positionSampleFor(key, originalBinding) ?? beforeDeadline
    let shiftedDone = shifted.positionSampleFor(key, shiftedBinding) ?? shiftedBeforeDeadline
    @Assert(originalDone.value.y, 100.0)
    @Assert(shiftedDone.value.y, 158.0)
    @Assert(originalDone.velocity.y, 0.0)
    @Assert(shiftedDone.velocity.y, 0.0)
    @Assert(original.isPositionActiveFor(key), false)
    @Assert(shifted.isPositionActiveFor(key), false)
}

@Test
func fPositionOriginPendingReverseRetargetShiftsLatestTargetAndAcceptsFrozenSample(): Unit {
    let driver = CjguiComposableUiAnimationDriver(821)
    let key = "semantic:origin-pending-reverse"
    let binding = CjguiComposableUiAnimationBinding(8211, windowInstanceToken: 821, acceptedBindingEpoch: 1)
    let initial = CjguiComposableUiPositionValue(0.0, -70.0)
    let firstTarget = CjguiComposableUiPositionValue(0.0, -174.0)
    let spring = CjguiComposableUiAnimationSpec.spring()
    @Assert(driver.animatePosition(key, binding, initial, firstTarget, spring, 0.0), true)
    @Assert(driver.advance(120.0), true)
    let frozen = driver.positionSampleFor(key, binding) ?? CjguiComposableUiPositionSample(key, binding, initial,
        initial, 0)
    let ticket = originTestTicket(driver, key, binding, requestRevision: 9)
    let rebase = CjguiComposableUiPositionOriginRebase(ticket, CjguiComposableUiPositionValue(0.0, 58.0))
    let frozenAfterRebase = driver.rebasePositionSample(frozen, rebase) ?? frozen
    let stagedRevision = driver.positionRevision()

    // This retarget arrives after staging and remains in the old origin until
    // the accepted candidate atomically commits the ticket's compensation.
    let reverseTarget = CjguiComposableUiPositionValue(0.0, 140.0)
    @Assert(driver.animatePosition(key, binding, initial, reverseTarget, spring, 120.0), true)
    driver.markPositionSamplesAccepted(originTestSampleMap(frozenAfterRebase), stagedRevision,
        originRebases: originTestRebaseMap(key, rebase))
    let state = driver.positionOriginStateFor(key, binding) ?? CjguiComposableUiPositionOriginState(-1, -1)
    let accepted = driver.positionAcceptedFor(key) ?? initial
    let latestTarget = driver.positionTargetFor(key) ?? initial
    @Assert(state.originRevision, ticket.originRevision + 1)
    @Assert(originTestNear(accepted.y, frozen.value.y + 58.0), true)
    @Assert(originTestNear(latestTarget.y, reverseTarget.y + 58.0), true)
    @Assert(driver.hasPendingPresentation(), true)
}

@Test
func fPositionOriginRejectsStaleChannelAndOriginAndAcceptsTicketOnlyOnce(): Unit {
    let driver = CjguiComposableUiAnimationDriver(831)
    let key = "semantic:origin-stale"
    let binding = CjguiComposableUiAnimationBinding(8311, windowInstanceToken: 831, acceptedBindingEpoch: 1)
    let initial = CjguiComposableUiPositionValue(0.0, 0.0)
    let target = CjguiComposableUiPositionValue(0.0, 100.0)
    let spring = CjguiComposableUiAnimationSpec.spring()
    @Assert(driver.animatePosition(key, binding, initial, target, spring, 0.0), true)
    let sample = driver.positionSampleFor(key, binding) ?? CjguiComposableUiPositionSample(key, binding, initial,
        initial, 0)
    let ticket = originTestTicket(driver, key, binding)
    let rebase = CjguiComposableUiPositionOriginRebase(ticket, CjguiComposableUiPositionValue(0.0, 58.0))
    let rebased = driver.rebasePositionSample(sample, rebase) ?? sample
    let wrongChannel = CjguiComposableUiPositionSample(key, binding, rebased.value, rebased.velocity, rebased.revision,
        channelGeneration: ticket.channelGeneration + 1, originRevision: ticket.originRevision + 1)
    let revision = driver.positionRevision()
    driver.markPositionSamplesAccepted(originTestSampleMap(wrongChannel), revision,
        originRebases: originTestRebaseMap(key, rebase))
    @Assert((driver.positionOriginStateFor(key, binding) ??
        CjguiComposableUiPositionOriginState(-1, -1)).originRevision, 0)
    @Assert((driver.positionAcceptedFor(key) ?? initial).y, 0.0)
    @Assert((driver.positionTargetFor(key) ?? initial).y, 100.0)

    let validMap = originTestSampleMap(rebased)
    let rebaseMap = originTestRebaseMap(key, rebase)
    driver.markPositionSamplesAccepted(validMap, revision, originRebases: rebaseMap)
    @Assert((driver.positionOriginStateFor(key, binding) ??
        CjguiComposableUiPositionOriginState(-1, -1)).originRevision, 1)
    let onceTarget = (driver.positionTargetFor(key) ?? initial).y
    driver.markPositionSamplesAccepted(validMap, revision, originRebases: rebaseMap)
    @Assert((driver.positionOriginStateFor(key, binding) ??
        CjguiComposableUiPositionOriginState(-1, -1)).originRevision, 1)
    @Assert((driver.positionTargetFor(key) ?? initial).y, onceTarget)

    @Assert(driver.cancelPosition(key), true)
    let recreatedTarget = CjguiComposableUiPositionValue(0.0, -40.0)
    @Assert(driver.animatePosition(key, binding, initial, recreatedTarget, spring, 1.0), true)
    let recreatedState = driver.positionOriginStateFor(key, binding) ?? CjguiComposableUiPositionOriginState(-1, -1)
    @Assert(recreatedState.channelGeneration != ticket.channelGeneration, true)
    @Assert(driver.rebasePositionSample(sample, rebase).isNone(), true)
    driver.markPositionSamplesAccepted(validMap, driver.positionRevision(), originRebases: rebaseMap)
    @Assert((driver.positionOriginStateFor(key, binding) ??
        CjguiComposableUiPositionOriginState(-1, -1)).originRevision, 0)
    @Assert((driver.positionTargetFor(key) ?? initial).y, -40.0)
}

@Test
func fPositionOriginRebaseIdentityIncludesWindowRequestAndCompensation(): Unit {
    let driver = CjguiComposableUiAnimationDriver(841)
    let key = "semantic:origin-match"
    let binding = CjguiComposableUiAnimationBinding(8411, windowInstanceToken: 841, acceptedBindingEpoch: 1)
    let zero = CjguiComposableUiPositionValue(0.0, 0.0)
    @Assert(driver.animatePosition(key, binding, zero, zero,
        CjguiComposableUiAnimationSpec.spring(), 0.0), true)
    let firstTicket = originTestTicket(driver, key, binding, requestRevision: 5)
    let sameTicket = originTestTicket(driver, key, binding, requestRevision: 5)
    let nextRequestTicket = originTestTicket(driver, key, binding, requestRevision: 6)
    let first = CjguiComposableUiPositionOriginRebase(firstTicket, CjguiComposableUiPositionValue(0.0, 58.0))
    let same = CjguiComposableUiPositionOriginRebase(sameTicket, CjguiComposableUiPositionValue(0.0, 58.0))
    let differentDelta = CjguiComposableUiPositionOriginRebase(firstTicket, CjguiComposableUiPositionValue(0.0, 57.0))
    let differentRequest = CjguiComposableUiPositionOriginRebase(nextRequestTicket,
        CjguiComposableUiPositionValue(0.0, 58.0))
    @Assert(first.matches(same), true)
    @Assert(first.matches(differentDelta), false)
    @Assert(first.matches(differentRequest), false)
}

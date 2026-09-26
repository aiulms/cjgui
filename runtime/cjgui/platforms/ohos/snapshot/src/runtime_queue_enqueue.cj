package cjgui

// Internal Queue Enqueue Dry-Run owner:
// - 本文件只消费 QueueStagingReadiness。
// - Truth 是 future enqueue dry-run plan / shadow candidate / readiness 的内部 value facts。
// - Stop-line: 不写 queue storage、不 enqueue、不 drain、不执行 action、不接 event loop /
//   scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Queue enqueue dry-run plan 只是描述 staged candidate 将如何进入 future enqueue boundary；
// 它不是实际 queue item storage、enqueue record 或 enqueue side effect。
struct CjguiInternalQueueEnqueueDryRunPlan {
    let stagingReadiness: CjguiInternalQueueStagingReadiness
    let didPrepareQueueEnqueueDryRunPlan: Bool
    let shouldDeferQueueEnqueueDryRunPlan: Bool
    let shouldReportQueueEnqueueDryRunBlocked: Bool
    let didPreserveQueueStagingReadiness: Bool

    init(
        stagingReadiness: CjguiInternalQueueStagingReadiness,
        didPrepareQueueEnqueueDryRunPlan: Bool,
        shouldDeferQueueEnqueueDryRunPlan: Bool,
        shouldReportQueueEnqueueDryRunBlocked: Bool,
        didPreserveQueueStagingReadiness: Bool
    ) {
        this.stagingReadiness = stagingReadiness
        this.didPrepareQueueEnqueueDryRunPlan = didPrepareQueueEnqueueDryRunPlan
        this.shouldDeferQueueEnqueueDryRunPlan = shouldDeferQueueEnqueueDryRunPlan
        this.shouldReportQueueEnqueueDryRunBlocked = shouldReportQueueEnqueueDryRunBlocked
        this.didPreserveQueueStagingReadiness = didPreserveQueueStagingReadiness
    }
}

// Queue enqueue shadow candidate 只把 dry-run plan 投影为内部 shadow candidate；
// shadow candidate 不是 queue storage write，也不会触发 drain 或 scheduler。
struct CjguiInternalQueueEnqueueShadowCandidate {
    let dryRunPlan: CjguiInternalQueueEnqueueDryRunPlan
    let isQueueEnqueueShadowCandidateReady: Bool
    let shouldDeferQueueEnqueueShadowCandidate: Bool
    let shouldReportQueueEnqueueShadowCandidateBlocked: Bool
    let didPreserveQueueEnqueueDryRunPlan: Bool

    init(
        dryRunPlan: CjguiInternalQueueEnqueueDryRunPlan,
        isQueueEnqueueShadowCandidateReady: Bool,
        shouldDeferQueueEnqueueShadowCandidate: Bool,
        shouldReportQueueEnqueueShadowCandidateBlocked: Bool,
        didPreserveQueueEnqueueDryRunPlan: Bool
    ) {
        this.dryRunPlan = dryRunPlan
        this.isQueueEnqueueShadowCandidateReady = isQueueEnqueueShadowCandidateReady
        this.shouldDeferQueueEnqueueShadowCandidate = shouldDeferQueueEnqueueShadowCandidate
        this.shouldReportQueueEnqueueShadowCandidateBlocked = shouldReportQueueEnqueueShadowCandidateBlocked
        this.didPreserveQueueEnqueueDryRunPlan = didPreserveQueueEnqueueDryRunPlan
    }
}

// Queue enqueue dry-run readiness 是本轮 canonical endpoint；
// ready 只表示 dry-run facts 已形成，不是实际 enqueue 或 queue mutation。
struct CjguiInternalQueueEnqueueDryRunReadiness {
    let shadowCandidate: CjguiInternalQueueEnqueueShadowCandidate
    let isQueueEnqueueDryRunReady: Bool
    let shouldDeferQueueEnqueueDryRunReadiness: Bool
    let shouldReportQueueEnqueueDryRunReadinessBlocked: Bool
    let didPreserveQueueEnqueueShadowCandidate: Bool

    init(
        shadowCandidate: CjguiInternalQueueEnqueueShadowCandidate,
        isQueueEnqueueDryRunReady: Bool,
        shouldDeferQueueEnqueueDryRunReadiness: Bool,
        shouldReportQueueEnqueueDryRunReadinessBlocked: Bool,
        didPreserveQueueEnqueueShadowCandidate: Bool
    ) {
        this.shadowCandidate = shadowCandidate
        this.isQueueEnqueueDryRunReady = isQueueEnqueueDryRunReady
        this.shouldDeferQueueEnqueueDryRunReadiness = shouldDeferQueueEnqueueDryRunReadiness
        this.shouldReportQueueEnqueueDryRunReadinessBlocked = shouldReportQueueEnqueueDryRunReadinessBlocked
        this.didPreserveQueueEnqueueShadowCandidate = didPreserveQueueEnqueueShadowCandidate
    }
}

func cjguiInternalBuildQueueEnqueueDryRunPlan(
    stagingReadiness: CjguiInternalQueueStagingReadiness
): CjguiInternalQueueEnqueueDryRunPlan {
    let stagingReady = stagingReadiness.isQueueStagingReady &&
        stagingReadiness.didPreserveQueueStagingCandidate &&
        stagingReadiness.shouldDeferQueueStagingReadiness == false &&
        stagingReadiness.shouldReportQueueStagingReadinessBlocked == false
    let stagingDeferred = stagingReadiness.isQueueStagingReady == false &&
        stagingReadiness.didPreserveQueueStagingCandidate == false &&
        stagingReadiness.shouldDeferQueueStagingReadiness &&
        stagingReadiness.shouldReportQueueStagingReadinessBlocked == false
    let stagingInconsistent = (
        stagingReadiness.isQueueStagingReady &&
            (stagingReadiness.shouldDeferQueueStagingReadiness ||
                stagingReadiness.shouldReportQueueStagingReadinessBlocked)
        ) ||
        (stagingReadiness.didPreserveQueueStagingCandidate &&
            stagingReadiness.isQueueStagingReady == false) ||
        (stagingReadiness.didPreserveQueueStagingCandidate == false &&
            stagingReadiness.isQueueStagingReady) ||
        (stagingReadiness.shouldDeferQueueStagingReadiness &&
            stagingReadiness.shouldReportQueueStagingReadinessBlocked)

    // staging readiness facts 不一致时必须 fail-closed，避免被误当成真实 enqueue 许可。
    if (
        stagingReadiness.shouldReportQueueStagingReadinessBlocked ||
        stagingInconsistent
    ) {
        return CjguiInternalQueueEnqueueDryRunPlan(stagingReadiness, false, false, true, false)
    }

    if (stagingReady) {
        return CjguiInternalQueueEnqueueDryRunPlan(stagingReadiness, true, false, false, true)
    }

    if (stagingDeferred) {
        return CjguiInternalQueueEnqueueDryRunPlan(stagingReadiness, false, true, false, false)
    }

    return CjguiInternalQueueEnqueueDryRunPlan(stagingReadiness, false, false, true, false)
}

func cjguiInternalBuildQueueEnqueueShadowCandidate(
    dryRunPlan: CjguiInternalQueueEnqueueDryRunPlan
): CjguiInternalQueueEnqueueShadowCandidate {
    let planReady = dryRunPlan.didPrepareQueueEnqueueDryRunPlan &&
        dryRunPlan.didPreserveQueueStagingReadiness &&
        dryRunPlan.shouldDeferQueueEnqueueDryRunPlan == false &&
        dryRunPlan.shouldReportQueueEnqueueDryRunBlocked == false
    let planDeferred = dryRunPlan.didPrepareQueueEnqueueDryRunPlan == false &&
        dryRunPlan.didPreserveQueueStagingReadiness == false &&
        dryRunPlan.shouldDeferQueueEnqueueDryRunPlan &&
        dryRunPlan.shouldReportQueueEnqueueDryRunBlocked == false
    let planInconsistent = (
        dryRunPlan.didPrepareQueueEnqueueDryRunPlan &&
            (dryRunPlan.shouldDeferQueueEnqueueDryRunPlan ||
                dryRunPlan.shouldReportQueueEnqueueDryRunBlocked)
        ) ||
        (dryRunPlan.didPreserveQueueStagingReadiness &&
            dryRunPlan.didPrepareQueueEnqueueDryRunPlan == false) ||
        (dryRunPlan.didPreserveQueueStagingReadiness == false &&
            dryRunPlan.didPrepareQueueEnqueueDryRunPlan) ||
        (dryRunPlan.shouldDeferQueueEnqueueDryRunPlan &&
            dryRunPlan.shouldReportQueueEnqueueDryRunBlocked)

    // dry-run plan facts 不一致时必须 fail-closed，shadow candidate 不能伪造成 queue item。
    if (dryRunPlan.shouldReportQueueEnqueueDryRunBlocked || planInconsistent) {
        return CjguiInternalQueueEnqueueShadowCandidate(dryRunPlan, false, false, true, false)
    }

    if (planReady) {
        return CjguiInternalQueueEnqueueShadowCandidate(dryRunPlan, true, false, false, true)
    }

    if (planDeferred) {
        return CjguiInternalQueueEnqueueShadowCandidate(dryRunPlan, false, true, false, false)
    }

    return CjguiInternalQueueEnqueueShadowCandidate(dryRunPlan, false, false, true, false)
}

func cjguiInternalBuildQueueEnqueueDryRunReadiness(
    shadowCandidate: CjguiInternalQueueEnqueueShadowCandidate
): CjguiInternalQueueEnqueueDryRunReadiness {
    let candidateReady = shadowCandidate.isQueueEnqueueShadowCandidateReady &&
        shadowCandidate.didPreserveQueueEnqueueDryRunPlan &&
        shadowCandidate.shouldDeferQueueEnqueueShadowCandidate == false &&
        shadowCandidate.shouldReportQueueEnqueueShadowCandidateBlocked == false
    let candidateDeferred = shadowCandidate.isQueueEnqueueShadowCandidateReady == false &&
        shadowCandidate.didPreserveQueueEnqueueDryRunPlan == false &&
        shadowCandidate.shouldDeferQueueEnqueueShadowCandidate &&
        shadowCandidate.shouldReportQueueEnqueueShadowCandidateBlocked == false
    let candidateInconsistent = (
        shadowCandidate.isQueueEnqueueShadowCandidateReady &&
            (shadowCandidate.shouldDeferQueueEnqueueShadowCandidate ||
                shadowCandidate.shouldReportQueueEnqueueShadowCandidateBlocked)
        ) ||
        (shadowCandidate.didPreserveQueueEnqueueDryRunPlan &&
            shadowCandidate.isQueueEnqueueShadowCandidateReady == false) ||
        (shadowCandidate.didPreserveQueueEnqueueDryRunPlan == false &&
            shadowCandidate.isQueueEnqueueShadowCandidateReady) ||
        (shadowCandidate.shouldDeferQueueEnqueueShadowCandidate &&
            shadowCandidate.shouldReportQueueEnqueueShadowCandidateBlocked)

    // shadow candidate facts 不一致时必须 fail-closed，readiness 不能伪造成 enqueue side effect。
    if (
        shadowCandidate.shouldReportQueueEnqueueShadowCandidateBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalQueueEnqueueDryRunReadiness(shadowCandidate, false, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalQueueEnqueueDryRunReadiness(shadowCandidate, true, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalQueueEnqueueDryRunReadiness(shadowCandidate, false, true, false, false)
    }

    return CjguiInternalQueueEnqueueDryRunReadiness(shadowCandidate, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueueEnqueueDryRunDraft(): CjguiInternalQueueEnqueueDryRunReadiness {
    // 默认 draft 只串联 enqueue dry-run value pipeline，不写 queue、不 enqueue、不 drain。
    let stagingReadiness = cjguiInternalExecuteDefaultQueueStagingDraft()
    let dryRunPlan = cjguiInternalBuildQueueEnqueueDryRunPlan(stagingReadiness)
    let shadowCandidate = cjguiInternalBuildQueueEnqueueShadowCandidate(dryRunPlan)
    return cjguiInternalBuildQueueEnqueueDryRunReadiness(shadowCandidate)
}

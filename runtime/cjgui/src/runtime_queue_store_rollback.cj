package cjgui

// Internal Queue Write Failure / Rollback owner:
// - 本文件只消费 QueueImmutableCommitPublicationCandidate。
// - Truth 是 write failure policy / rollback plan / rollback result 的内部 value facts。
// - Stop-line: 不写真实 process-wide queue storage、不创建 global mutable queue、不 enqueue、不 drain、
//   不执行真实 rollback side effect、不接 event loop / scheduler / platform callback、不调用 runtime cycle。

// Queue write failure policy 只判断 immutable commit publication candidate 是否需要 failure / rollback 语义；
// 它不是实际写入失败回调，也不会恢复全局状态。
struct CjguiInternalQueueWriteFailurePolicy {
    let publicationCandidate: CjguiInternalQueueImmutableCommitPublicationCandidate
    let didDetectQueueWriteFailure: Bool
    let shouldDeferQueueWriteFailurePolicy: Bool
    let shouldReportQueueWriteFailurePolicyBlocked: Bool
    let didPreserveImmutableCommitPublicationCandidate: Bool

    init(
        publicationCandidate: CjguiInternalQueueImmutableCommitPublicationCandidate,
        didDetectQueueWriteFailure: Bool,
        shouldDeferQueueWriteFailurePolicy: Bool,
        shouldReportQueueWriteFailurePolicyBlocked: Bool,
        didPreserveImmutableCommitPublicationCandidate: Bool
    ) {
        this.publicationCandidate = publicationCandidate
        this.didDetectQueueWriteFailure = didDetectQueueWriteFailure
        this.shouldDeferQueueWriteFailurePolicy = shouldDeferQueueWriteFailurePolicy
        this.shouldReportQueueWriteFailurePolicyBlocked = shouldReportQueueWriteFailurePolicyBlocked
        this.didPreserveImmutableCommitPublicationCandidate = didPreserveImmutableCommitPublicationCandidate
    }
}

// Queue write rollback plan 只携带 previous snapshot fallback 与是否需要 rollback 的 value facts；
// 它不是实际 rollback side effect，也不会写回 process-wide queue storage。
struct CjguiInternalQueueWriteRollbackPlan {
    let policy: CjguiInternalQueueWriteFailurePolicy
    let previousSnapshotFallback: CjguiInternalQueueStoreSnapshot
    let requiresQueueWriteRollback: Bool
    let shouldDeferQueueWriteRollbackPlan: Bool
    let shouldReportQueueWriteRollbackPlanBlocked: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool
    let didPreserveQueueWriteFailurePolicy: Bool

    init(
        policy: CjguiInternalQueueWriteFailurePolicy,
        previousSnapshotFallback: CjguiInternalQueueStoreSnapshot,
        requiresQueueWriteRollback: Bool,
        shouldDeferQueueWriteRollbackPlan: Bool,
        shouldReportQueueWriteRollbackPlanBlocked: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool,
        didPreserveQueueWriteFailurePolicy: Bool
    ) {
        this.policy = policy
        this.previousSnapshotFallback = previousSnapshotFallback
        this.requiresQueueWriteRollback = requiresQueueWriteRollback
        this.shouldDeferQueueWriteRollbackPlan = shouldDeferQueueWriteRollbackPlan
        this.shouldReportQueueWriteRollbackPlanBlocked = shouldReportQueueWriteRollbackPlanBlocked
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
        this.didPreserveQueueWriteFailurePolicy = didPreserveQueueWriteFailurePolicy
    }
}

// Queue write rollback result 是本轮 canonical endpoint；
// ready 只表示 rollback model facts 已收束，不代表真实 rollback、真实 storage restore 或 enqueue。
struct CjguiInternalQueueWriteRollbackResult {
    let rollbackPlan: CjguiInternalQueueWriteRollbackPlan
    let isQueueWriteRollbackModelReady: Bool
    let didRequireQueueWriteRollback: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool
    let shouldDeferQueueWriteRollbackResult: Bool
    let shouldReportQueueWriteRollbackResultBlocked: Bool
    let didPreserveQueueWriteRollbackPlan: Bool

    init(
        rollbackPlan: CjguiInternalQueueWriteRollbackPlan,
        isQueueWriteRollbackModelReady: Bool,
        didRequireQueueWriteRollback: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool,
        shouldDeferQueueWriteRollbackResult: Bool,
        shouldReportQueueWriteRollbackResultBlocked: Bool,
        didPreserveQueueWriteRollbackPlan: Bool
    ) {
        this.rollbackPlan = rollbackPlan
        this.isQueueWriteRollbackModelReady = isQueueWriteRollbackModelReady
        this.didRequireQueueWriteRollback = didRequireQueueWriteRollback
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
        this.shouldDeferQueueWriteRollbackResult = shouldDeferQueueWriteRollbackResult
        this.shouldReportQueueWriteRollbackResultBlocked = shouldReportQueueWriteRollbackResultBlocked
        this.didPreserveQueueWriteRollbackPlan = didPreserveQueueWriteRollbackPlan
    }
}

func cjguiInternalBuildQueueWriteFailurePolicy(
    publicationCandidate: CjguiInternalQueueImmutableCommitPublicationCandidate
): CjguiInternalQueueWriteFailurePolicy {
    let candidateReady = publicationCandidate.isImmutableQueueStoreCommitPublicationCandidateReady &&
        publicationCandidate.didPreserveImmutableWriteCommitResult &&
        publicationCandidate.shouldDeferImmutableQueueStoreCommitPublication == false &&
        publicationCandidate.shouldReportImmutableQueueStoreCommitPublicationBlocked == false
    let candidateDeferred = publicationCandidate.isImmutableQueueStoreCommitPublicationCandidateReady == false &&
        publicationCandidate.didPreserveImmutableWriteCommitResult == false &&
        publicationCandidate.shouldDeferImmutableQueueStoreCommitPublication &&
        publicationCandidate.shouldReportImmutableQueueStoreCommitPublicationBlocked == false
    let candidateInconsistent = (
        publicationCandidate.isImmutableQueueStoreCommitPublicationCandidateReady &&
            (publicationCandidate.shouldDeferImmutableQueueStoreCommitPublication ||
                publicationCandidate.shouldReportImmutableQueueStoreCommitPublicationBlocked)
        ) ||
        (publicationCandidate.didPreserveImmutableWriteCommitResult &&
            publicationCandidate.isImmutableQueueStoreCommitPublicationCandidateReady == false) ||
        (publicationCandidate.didPreserveImmutableWriteCommitResult == false &&
            publicationCandidate.isImmutableQueueStoreCommitPublicationCandidateReady) ||
        (publicationCandidate.shouldDeferImmutableQueueStoreCommitPublication &&
            publicationCandidate.shouldReportImmutableQueueStoreCommitPublicationBlocked)

    // commit publication facts 不一致时必须 fail-closed，并进入 rollback-required value path。
    if (
        publicationCandidate.shouldReportImmutableQueueStoreCommitPublicationBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalQueueWriteFailurePolicy(publicationCandidate, true, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalQueueWriteFailurePolicy(publicationCandidate, false, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalQueueWriteFailurePolicy(publicationCandidate, false, true, false, false)
    }

    return CjguiInternalQueueWriteFailurePolicy(publicationCandidate, true, false, true, false)
}

func cjguiInternalBuildQueueWriteRollbackPlan(
    policy: CjguiInternalQueueWriteFailurePolicy
): CjguiInternalQueueWriteRollbackPlan {
    let previousSnapshot =
        policy.publicationCandidate.result.committedStore.writeCommit.writeReadiness.admission.policy
            .storeCommitCandidate.transition.previousSnapshot
    let policyReady = policy.didDetectQueueWriteFailure == false &&
        policy.didPreserveImmutableCommitPublicationCandidate &&
        policy.shouldDeferQueueWriteFailurePolicy == false &&
        policy.shouldReportQueueWriteFailurePolicyBlocked == false
    let policyDeferred = policy.didDetectQueueWriteFailure == false &&
        policy.didPreserveImmutableCommitPublicationCandidate == false &&
        policy.shouldDeferQueueWriteFailurePolicy &&
        policy.shouldReportQueueWriteFailurePolicyBlocked == false
    let policyBlocked = policy.didDetectQueueWriteFailure &&
        policy.didPreserveImmutableCommitPublicationCandidate == false &&
        policy.shouldDeferQueueWriteFailurePolicy == false &&
        policy.shouldReportQueueWriteFailurePolicyBlocked
    let policyInconsistent = (
        policy.didDetectQueueWriteFailure &&
            (policy.didPreserveImmutableCommitPublicationCandidate || policy.shouldDeferQueueWriteFailurePolicy)
        ) ||
        (policy.didDetectQueueWriteFailure == false && policy.shouldReportQueueWriteFailurePolicyBlocked) ||
        (policy.didPreserveImmutableCommitPublicationCandidate && policy.shouldReportQueueWriteFailurePolicyBlocked) ||
        (policy.shouldDeferQueueWriteFailurePolicy && policy.shouldReportQueueWriteFailurePolicyBlocked)

    // failure policy facts 不一致时必须 fail-closed，但 rollback plan 仍携带 previous snapshot fallback。
    if (
        policy.shouldReportQueueWriteFailurePolicyBlocked ||
        policyInconsistent ||
        policyBlocked
    ) {
        return CjguiInternalQueueWriteRollbackPlan(policy, previousSnapshot, true, false, true, true, false)
    }

    if (policyReady) {
        return CjguiInternalQueueWriteRollbackPlan(policy, previousSnapshot, false, false, false, true, true)
    }

    if (policyDeferred) {
        return CjguiInternalQueueWriteRollbackPlan(policy, previousSnapshot, false, true, false, true, false)
    }

    return CjguiInternalQueueWriteRollbackPlan(policy, previousSnapshot, true, false, true, true, false)
}

func cjguiInternalBuildQueueWriteRollbackResult(
    rollbackPlan: CjguiInternalQueueWriteRollbackPlan
): CjguiInternalQueueWriteRollbackResult {
    let planReady = rollbackPlan.requiresQueueWriteRollback == false &&
        rollbackPlan.didPreservePreviousQueueStoreSnapshot &&
        rollbackPlan.didPreserveQueueWriteFailurePolicy &&
        rollbackPlan.shouldDeferQueueWriteRollbackPlan == false &&
        rollbackPlan.shouldReportQueueWriteRollbackPlanBlocked == false
    let planDeferred = rollbackPlan.requiresQueueWriteRollback == false &&
        rollbackPlan.didPreservePreviousQueueStoreSnapshot &&
        rollbackPlan.didPreserveQueueWriteFailurePolicy == false &&
        rollbackPlan.shouldDeferQueueWriteRollbackPlan &&
        rollbackPlan.shouldReportQueueWriteRollbackPlanBlocked == false
    let planBlocked = rollbackPlan.requiresQueueWriteRollback &&
        rollbackPlan.didPreservePreviousQueueStoreSnapshot &&
        rollbackPlan.didPreserveQueueWriteFailurePolicy == false &&
        rollbackPlan.shouldDeferQueueWriteRollbackPlan == false &&
        rollbackPlan.shouldReportQueueWriteRollbackPlanBlocked
    let planInconsistent = (
        rollbackPlan.requiresQueueWriteRollback &&
            (rollbackPlan.didPreserveQueueWriteFailurePolicy || rollbackPlan.shouldDeferQueueWriteRollbackPlan)
        ) ||
        (rollbackPlan.didPreservePreviousQueueStoreSnapshot == false) ||
        (rollbackPlan.didPreserveQueueWriteFailurePolicy &&
            rollbackPlan.shouldReportQueueWriteRollbackPlanBlocked) ||
        (rollbackPlan.shouldDeferQueueWriteRollbackPlan && rollbackPlan.shouldReportQueueWriteRollbackPlanBlocked)

    // rollback plan facts 不一致时必须 fail-closed；result 保留 previous snapshot facts 但不执行回滚。
    if (
        rollbackPlan.shouldReportQueueWriteRollbackPlanBlocked ||
        planInconsistent ||
        planBlocked
    ) {
        return CjguiInternalQueueWriteRollbackResult(rollbackPlan, false, true, true, false, true, false)
    }

    if (planReady) {
        return CjguiInternalQueueWriteRollbackResult(rollbackPlan, true, false, true, false, false, true)
    }

    if (planDeferred) {
        return CjguiInternalQueueWriteRollbackResult(rollbackPlan, false, false, true, true, false, false)
    }

    return CjguiInternalQueueWriteRollbackResult(rollbackPlan, false, true, true, false, true, false)
}

func cjguiInternalExecuteDefaultQueueWriteRollbackDraft(): CjguiInternalQueueWriteRollbackResult {
    // 默认 draft 只串联 failure / rollback value pipeline，不写真实 storage、不执行 rollback、不 enqueue、不 drain。
    let publicationCandidate = cjguiInternalExecuteDefaultQueueImmutableStoreWriteCommitDraft()
    let policy = cjguiInternalBuildQueueWriteFailurePolicy(publicationCandidate)
    let rollbackPlan = cjguiInternalBuildQueueWriteRollbackPlan(policy)
    return cjguiInternalBuildQueueWriteRollbackResult(rollbackPlan)
}

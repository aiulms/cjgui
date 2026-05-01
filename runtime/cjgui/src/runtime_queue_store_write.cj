package cjgui

// Internal Queue Store Write Admission owner:
// - 本文件只消费 QueueStoreCommitCandidate。
// - Truth 是 storage-write 前的 write policy / admission / readiness 内部 value facts。
// - Stop-line: 不写真实 queue storage、不创建 global mutable queue、不 enqueue、不 drain、
//   不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Queue store write policy 只判断 store commit candidate 是否允许进入 future write boundary；
// 它不是实际写入许可副作用，也不会创建全局可变队列。
struct CjguiInternalQueueStoreWritePolicy {
    let storeCommitCandidate: CjguiInternalQueueStoreCommitCandidate
    let allowsQueueStoreWriteBoundary: Bool
    let shouldDeferQueueStoreWritePolicy: Bool
    let shouldReportQueueStoreWritePolicyBlocked: Bool
    let didPreserveQueueStoreCommitCandidate: Bool

    init(
        storeCommitCandidate: CjguiInternalQueueStoreCommitCandidate,
        allowsQueueStoreWriteBoundary: Bool,
        shouldDeferQueueStoreWritePolicy: Bool,
        shouldReportQueueStoreWritePolicyBlocked: Bool,
        didPreserveQueueStoreCommitCandidate: Bool
    ) {
        this.storeCommitCandidate = storeCommitCandidate
        this.allowsQueueStoreWriteBoundary = allowsQueueStoreWriteBoundary
        this.shouldDeferQueueStoreWritePolicy = shouldDeferQueueStoreWritePolicy
        this.shouldReportQueueStoreWritePolicyBlocked = shouldReportQueueStoreWritePolicyBlocked
        this.didPreserveQueueStoreCommitCandidate = didPreserveQueueStoreCommitCandidate
    }
}

// Queue store write admission 只把 policy facts 投影成 write gate facts；
// admission open 仍不是 queue storage write、enqueue record 或 runtime global state mutation。
struct CjguiInternalQueueStoreWriteAdmission {
    let policy: CjguiInternalQueueStoreWritePolicy
    let isQueueStoreWriteAdmissionOpen: Bool
    let shouldDeferQueueStoreWriteAdmission: Bool
    let shouldReportQueueStoreWriteAdmissionBlocked: Bool
    let didPreserveQueueStoreWritePolicy: Bool

    init(
        policy: CjguiInternalQueueStoreWritePolicy,
        isQueueStoreWriteAdmissionOpen: Bool,
        shouldDeferQueueStoreWriteAdmission: Bool,
        shouldReportQueueStoreWriteAdmissionBlocked: Bool,
        didPreserveQueueStoreWritePolicy: Bool
    ) {
        this.policy = policy
        this.isQueueStoreWriteAdmissionOpen = isQueueStoreWriteAdmissionOpen
        this.shouldDeferQueueStoreWriteAdmission = shouldDeferQueueStoreWriteAdmission
        this.shouldReportQueueStoreWriteAdmissionBlocked = shouldReportQueueStoreWriteAdmissionBlocked
        this.didPreserveQueueStoreWritePolicy = didPreserveQueueStoreWritePolicy
    }
}

// Queue store write readiness 是本轮 canonical endpoint；
// ready 只表示 write admission facts 已收束，不会写真实 storage。
struct CjguiInternalQueueStoreWriteReadiness {
    let admission: CjguiInternalQueueStoreWriteAdmission
    let isQueueStoreWriteReady: Bool
    let shouldDeferQueueStoreWriteReadiness: Bool
    let shouldReportQueueStoreWriteReadinessBlocked: Bool
    let didPreserveQueueStoreWriteAdmission: Bool

    init(
        admission: CjguiInternalQueueStoreWriteAdmission,
        isQueueStoreWriteReady: Bool,
        shouldDeferQueueStoreWriteReadiness: Bool,
        shouldReportQueueStoreWriteReadinessBlocked: Bool,
        didPreserveQueueStoreWriteAdmission: Bool
    ) {
        this.admission = admission
        this.isQueueStoreWriteReady = isQueueStoreWriteReady
        this.shouldDeferQueueStoreWriteReadiness = shouldDeferQueueStoreWriteReadiness
        this.shouldReportQueueStoreWriteReadinessBlocked = shouldReportQueueStoreWriteReadinessBlocked
        this.didPreserveQueueStoreWriteAdmission = didPreserveQueueStoreWriteAdmission
    }
}

func cjguiInternalBuildQueueStoreWritePolicy(
    storeCommitCandidate: CjguiInternalQueueStoreCommitCandidate
): CjguiInternalQueueStoreWritePolicy {
    let candidateReady = storeCommitCandidate.canCommitQueueStoreValue &&
        storeCommitCandidate.didPreserveQueueStoreTransition &&
        storeCommitCandidate.shouldDeferQueueStoreCommit == false &&
        storeCommitCandidate.shouldReportQueueStoreCommitBlocked == false
    let candidateDeferred = storeCommitCandidate.canCommitQueueStoreValue == false &&
        storeCommitCandidate.didPreserveQueueStoreTransition == false &&
        storeCommitCandidate.shouldDeferQueueStoreCommit &&
        storeCommitCandidate.shouldReportQueueStoreCommitBlocked == false
    let candidateInconsistent = (
        storeCommitCandidate.canCommitQueueStoreValue &&
            (storeCommitCandidate.shouldDeferQueueStoreCommit ||
                storeCommitCandidate.shouldReportQueueStoreCommitBlocked)
        ) ||
        (storeCommitCandidate.didPreserveQueueStoreTransition &&
            storeCommitCandidate.canCommitQueueStoreValue == false) ||
        (storeCommitCandidate.didPreserveQueueStoreTransition == false &&
            storeCommitCandidate.canCommitQueueStoreValue) ||
        (storeCommitCandidate.shouldDeferQueueStoreCommit &&
            storeCommitCandidate.shouldReportQueueStoreCommitBlocked)

    // store commit candidate facts 不一致时必须 fail-closed，避免被误当成真实 queue write 许可。
    if (
        storeCommitCandidate.shouldReportQueueStoreCommitBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalQueueStoreWritePolicy(storeCommitCandidate, false, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalQueueStoreWritePolicy(storeCommitCandidate, true, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalQueueStoreWritePolicy(storeCommitCandidate, false, true, false, false)
    }

    return CjguiInternalQueueStoreWritePolicy(storeCommitCandidate, false, false, true, false)
}

func cjguiInternalBuildQueueStoreWriteAdmission(
    policy: CjguiInternalQueueStoreWritePolicy
): CjguiInternalQueueStoreWriteAdmission {
    let policyReady = policy.allowsQueueStoreWriteBoundary &&
        policy.didPreserveQueueStoreCommitCandidate &&
        policy.shouldDeferQueueStoreWritePolicy == false &&
        policy.shouldReportQueueStoreWritePolicyBlocked == false
    let policyDeferred = policy.allowsQueueStoreWriteBoundary == false &&
        policy.didPreserveQueueStoreCommitCandidate == false &&
        policy.shouldDeferQueueStoreWritePolicy &&
        policy.shouldReportQueueStoreWritePolicyBlocked == false
    let policyInconsistent = (
        policy.allowsQueueStoreWriteBoundary &&
            (policy.shouldDeferQueueStoreWritePolicy ||
                policy.shouldReportQueueStoreWritePolicyBlocked)
        ) ||
        (policy.didPreserveQueueStoreCommitCandidate &&
            policy.allowsQueueStoreWriteBoundary == false) ||
        (policy.didPreserveQueueStoreCommitCandidate == false &&
            policy.allowsQueueStoreWriteBoundary) ||
        (policy.shouldDeferQueueStoreWritePolicy &&
            policy.shouldReportQueueStoreWritePolicyBlocked)

    // write policy facts 不一致时必须 fail-closed，admission 不能伪造成真实写入授权。
    if (policy.shouldReportQueueStoreWritePolicyBlocked || policyInconsistent) {
        return CjguiInternalQueueStoreWriteAdmission(policy, false, false, true, false)
    }

    if (policyReady) {
        return CjguiInternalQueueStoreWriteAdmission(policy, true, false, false, true)
    }

    if (policyDeferred) {
        return CjguiInternalQueueStoreWriteAdmission(policy, false, true, false, false)
    }

    return CjguiInternalQueueStoreWriteAdmission(policy, false, false, true, false)
}

func cjguiInternalBuildQueueStoreWriteReadiness(
    admission: CjguiInternalQueueStoreWriteAdmission
): CjguiInternalQueueStoreWriteReadiness {
    let admissionReady = admission.isQueueStoreWriteAdmissionOpen &&
        admission.didPreserveQueueStoreWritePolicy &&
        admission.shouldDeferQueueStoreWriteAdmission == false &&
        admission.shouldReportQueueStoreWriteAdmissionBlocked == false
    let admissionDeferred = admission.isQueueStoreWriteAdmissionOpen == false &&
        admission.didPreserveQueueStoreWritePolicy == false &&
        admission.shouldDeferQueueStoreWriteAdmission &&
        admission.shouldReportQueueStoreWriteAdmissionBlocked == false
    let admissionInconsistent = (
        admission.isQueueStoreWriteAdmissionOpen &&
            (admission.shouldDeferQueueStoreWriteAdmission ||
                admission.shouldReportQueueStoreWriteAdmissionBlocked)
        ) ||
        (admission.didPreserveQueueStoreWritePolicy &&
            admission.isQueueStoreWriteAdmissionOpen == false) ||
        (admission.didPreserveQueueStoreWritePolicy == false &&
            admission.isQueueStoreWriteAdmissionOpen) ||
        (admission.shouldDeferQueueStoreWriteAdmission &&
            admission.shouldReportQueueStoreWriteAdmissionBlocked)

    // write admission facts 不一致时必须 fail-closed，readiness 仍不能写真实 queue storage。
    if (
        admission.shouldReportQueueStoreWriteAdmissionBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalQueueStoreWriteReadiness(admission, false, false, true, false)
    }

    if (admissionReady) {
        return CjguiInternalQueueStoreWriteReadiness(admission, true, false, false, true)
    }

    if (admissionDeferred) {
        return CjguiInternalQueueStoreWriteReadiness(admission, false, true, false, false)
    }

    return CjguiInternalQueueStoreWriteReadiness(admission, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueueStoreWriteDraft(): CjguiInternalQueueStoreWriteReadiness {
    // 默认 draft 只串联 queue store write-admission value pipeline，不写真实 storage、不 enqueue、不 drain。
    let storeCommitCandidate = cjguiInternalExecuteDefaultQueueStoreDraft()
    let policy = cjguiInternalBuildQueueStoreWritePolicy(storeCommitCandidate)
    let admission = cjguiInternalBuildQueueStoreWriteAdmission(policy)
    return cjguiInternalBuildQueueStoreWriteReadiness(admission)
}

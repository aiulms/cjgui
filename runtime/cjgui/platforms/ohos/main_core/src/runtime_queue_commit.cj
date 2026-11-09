package cjgui

// Internal Queue Storage Commit Gate owner:
// - 本文件只消费 QueueStorageCommitCandidate。
// - Truth 是 storage commit gate / commit readiness / finalization candidate 的内部 value facts。
// - Stop-line: 不写真实 queue storage、不创建 global mutable queue、不 enqueue、不 drain、
//   不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Queue storage commit gate 只是判断 storage commit candidate 是否可进入 future commit boundary；
// 它不是实际 queue storage commit、enqueue record 或 global mutable queue。
struct CjguiInternalQueueStorageCommitGate {
    let storageCommitCandidate: CjguiInternalQueueStorageCommitCandidate
    let isQueueStorageCommitGateOpen: Bool
    let shouldDeferQueueStorageCommitGate: Bool
    let shouldReportQueueStorageCommitGateBlocked: Bool
    let didPreserveQueueStorageCommitCandidate: Bool

    init(
        storageCommitCandidate: CjguiInternalQueueStorageCommitCandidate,
        isQueueStorageCommitGateOpen: Bool,
        shouldDeferQueueStorageCommitGate: Bool,
        shouldReportQueueStorageCommitGateBlocked: Bool,
        didPreserveQueueStorageCommitCandidate: Bool
    ) {
        this.storageCommitCandidate = storageCommitCandidate
        this.isQueueStorageCommitGateOpen = isQueueStorageCommitGateOpen
        this.shouldDeferQueueStorageCommitGate = shouldDeferQueueStorageCommitGate
        this.shouldReportQueueStorageCommitGateBlocked = shouldReportQueueStorageCommitGateBlocked
        this.didPreserveQueueStorageCommitCandidate = didPreserveQueueStorageCommitCandidate
    }
}

// Queue storage commit readiness 只把 commit gate 投影为内部 readiness；
// readiness 不写队列，也不会触发 enqueue / drain。
struct CjguiInternalQueueStorageCommitReadiness {
    let commitGate: CjguiInternalQueueStorageCommitGate
    let isQueueStorageCommitReady: Bool
    let shouldDeferQueueStorageCommitReadiness: Bool
    let shouldReportQueueStorageCommitReadinessBlocked: Bool
    let didPreserveQueueStorageCommitGate: Bool

    init(
        commitGate: CjguiInternalQueueStorageCommitGate,
        isQueueStorageCommitReady: Bool,
        shouldDeferQueueStorageCommitReadiness: Bool,
        shouldReportQueueStorageCommitReadinessBlocked: Bool,
        didPreserveQueueStorageCommitGate: Bool
    ) {
        this.commitGate = commitGate
        this.isQueueStorageCommitReady = isQueueStorageCommitReady
        this.shouldDeferQueueStorageCommitReadiness = shouldDeferQueueStorageCommitReadiness
        this.shouldReportQueueStorageCommitReadinessBlocked = shouldReportQueueStorageCommitReadinessBlocked
        this.didPreserveQueueStorageCommitGate = didPreserveQueueStorageCommitGate
    }
}

// Queue storage commit finalization candidate 是本轮 canonical endpoint；
// finalization candidate 只表示 commit gate facts 已收束，不是真实 queue finalization。
struct CjguiInternalQueueStorageCommitFinalizationCandidate {
    let readiness: CjguiInternalQueueStorageCommitReadiness
    let isQueueStorageCommitFinalizationCandidateReady: Bool
    let shouldDeferQueueStorageCommitFinalization: Bool
    let shouldReportQueueStorageCommitFinalizationBlocked: Bool
    let didPreserveQueueStorageCommitReadiness: Bool

    init(
        readiness: CjguiInternalQueueStorageCommitReadiness,
        isQueueStorageCommitFinalizationCandidateReady: Bool,
        shouldDeferQueueStorageCommitFinalization: Bool,
        shouldReportQueueStorageCommitFinalizationBlocked: Bool,
        didPreserveQueueStorageCommitReadiness: Bool
    ) {
        this.readiness = readiness
        this.isQueueStorageCommitFinalizationCandidateReady = isQueueStorageCommitFinalizationCandidateReady
        this.shouldDeferQueueStorageCommitFinalization = shouldDeferQueueStorageCommitFinalization
        this.shouldReportQueueStorageCommitFinalizationBlocked = shouldReportQueueStorageCommitFinalizationBlocked
        this.didPreserveQueueStorageCommitReadiness = didPreserveQueueStorageCommitReadiness
    }
}

func cjguiInternalBuildQueueStorageCommitGate(
    storageCommitCandidate: CjguiInternalQueueStorageCommitCandidate
): CjguiInternalQueueStorageCommitGate {
    let candidateReady = storageCommitCandidate.canCommitQueueStorageCandidate &&
        storageCommitCandidate.didPreserveQueueStorageCandidate &&
        storageCommitCandidate.shouldDeferQueueStorageCommit == false &&
        storageCommitCandidate.shouldReportQueueStorageCommitBlocked == false
    let candidateDeferred = storageCommitCandidate.canCommitQueueStorageCandidate == false &&
        storageCommitCandidate.didPreserveQueueStorageCandidate == false &&
        storageCommitCandidate.shouldDeferQueueStorageCommit &&
        storageCommitCandidate.shouldReportQueueStorageCommitBlocked == false
    let candidateInconsistent = (
        storageCommitCandidate.canCommitQueueStorageCandidate &&
            (storageCommitCandidate.shouldDeferQueueStorageCommit ||
                storageCommitCandidate.shouldReportQueueStorageCommitBlocked)
        ) ||
        (storageCommitCandidate.didPreserveQueueStorageCandidate &&
            storageCommitCandidate.canCommitQueueStorageCandidate == false) ||
        (storageCommitCandidate.didPreserveQueueStorageCandidate == false &&
            storageCommitCandidate.canCommitQueueStorageCandidate) ||
        (storageCommitCandidate.shouldDeferQueueStorageCommit &&
            storageCommitCandidate.shouldReportQueueStorageCommitBlocked)

    // storage commit candidate facts 不一致时必须 fail-closed，避免被误当作真实 queue commit 许可。
    if (
        storageCommitCandidate.shouldReportQueueStorageCommitBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalQueueStorageCommitGate(storageCommitCandidate, false, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalQueueStorageCommitGate(storageCommitCandidate, true, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalQueueStorageCommitGate(storageCommitCandidate, false, true, false, false)
    }

    return CjguiInternalQueueStorageCommitGate(storageCommitCandidate, false, false, true, false)
}

func cjguiInternalBuildQueueStorageCommitReadiness(
    commitGate: CjguiInternalQueueStorageCommitGate
): CjguiInternalQueueStorageCommitReadiness {
    let gateReady = commitGate.isQueueStorageCommitGateOpen &&
        commitGate.didPreserveQueueStorageCommitCandidate &&
        commitGate.shouldDeferQueueStorageCommitGate == false &&
        commitGate.shouldReportQueueStorageCommitGateBlocked == false
    let gateDeferred = commitGate.isQueueStorageCommitGateOpen == false &&
        commitGate.didPreserveQueueStorageCommitCandidate == false &&
        commitGate.shouldDeferQueueStorageCommitGate &&
        commitGate.shouldReportQueueStorageCommitGateBlocked == false
    let gateInconsistent = (
        commitGate.isQueueStorageCommitGateOpen &&
            (commitGate.shouldDeferQueueStorageCommitGate ||
                commitGate.shouldReportQueueStorageCommitGateBlocked)
        ) ||
        (commitGate.didPreserveQueueStorageCommitCandidate &&
            commitGate.isQueueStorageCommitGateOpen == false) ||
        (commitGate.didPreserveQueueStorageCommitCandidate == false &&
            commitGate.isQueueStorageCommitGateOpen) ||
        (commitGate.shouldDeferQueueStorageCommitGate &&
            commitGate.shouldReportQueueStorageCommitGateBlocked)

    // commit gate facts 不一致时必须 fail-closed，readiness 不能伪造成真实 storage commit。
    if (commitGate.shouldReportQueueStorageCommitGateBlocked || gateInconsistent) {
        return CjguiInternalQueueStorageCommitReadiness(commitGate, false, false, true, false)
    }

    if (gateReady) {
        return CjguiInternalQueueStorageCommitReadiness(commitGate, true, false, false, true)
    }

    if (gateDeferred) {
        return CjguiInternalQueueStorageCommitReadiness(commitGate, false, true, false, false)
    }

    return CjguiInternalQueueStorageCommitReadiness(commitGate, false, false, true, false)
}

func cjguiInternalBuildQueueStorageCommitFinalizationCandidate(
    readiness: CjguiInternalQueueStorageCommitReadiness
): CjguiInternalQueueStorageCommitFinalizationCandidate {
    let readinessReady = readiness.isQueueStorageCommitReady &&
        readiness.didPreserveQueueStorageCommitGate &&
        readiness.shouldDeferQueueStorageCommitReadiness == false &&
        readiness.shouldReportQueueStorageCommitReadinessBlocked == false
    let readinessDeferred = readiness.isQueueStorageCommitReady == false &&
        readiness.didPreserveQueueStorageCommitGate == false &&
        readiness.shouldDeferQueueStorageCommitReadiness &&
        readiness.shouldReportQueueStorageCommitReadinessBlocked == false
    let readinessInconsistent = (
        readiness.isQueueStorageCommitReady &&
            (readiness.shouldDeferQueueStorageCommitReadiness ||
                readiness.shouldReportQueueStorageCommitReadinessBlocked)
        ) ||
        (readiness.didPreserveQueueStorageCommitGate &&
            readiness.isQueueStorageCommitReady == false) ||
        (readiness.didPreserveQueueStorageCommitGate == false &&
            readiness.isQueueStorageCommitReady) ||
        (readiness.shouldDeferQueueStorageCommitReadiness &&
            readiness.shouldReportQueueStorageCommitReadinessBlocked)

    // commit readiness facts 不一致时必须 fail-closed，finalization candidate 不能伪造成 queue finalization。
    if (
        readiness.shouldReportQueueStorageCommitReadinessBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalQueueStorageCommitFinalizationCandidate(readiness, false, false, true, false)
    }

    if (readinessReady) {
        return CjguiInternalQueueStorageCommitFinalizationCandidate(readiness, true, false, false, true)
    }

    if (readinessDeferred) {
        return CjguiInternalQueueStorageCommitFinalizationCandidate(readiness, false, true, false, false)
    }

    return CjguiInternalQueueStorageCommitFinalizationCandidate(readiness, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueueStorageCommitDraft(): CjguiInternalQueueStorageCommitFinalizationCandidate {
    // 默认 draft 只串联 queue commit gate value pipeline，不写 queue、不创建全局队列、不 enqueue。
    let storageCommitCandidate = cjguiInternalExecuteDefaultQueueStorageDraft()
    let commitGate = cjguiInternalBuildQueueStorageCommitGate(storageCommitCandidate)
    let readiness = cjguiInternalBuildQueueStorageCommitReadiness(commitGate)
    return cjguiInternalBuildQueueStorageCommitFinalizationCandidate(readiness)
}

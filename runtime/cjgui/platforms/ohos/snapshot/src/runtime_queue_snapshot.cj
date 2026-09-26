package cjgui

// Internal Queue Committed Snapshot owner:
// - 本文件只消费 QueueStorageCommitFinalizationCandidate。
// - Truth 是 committed snapshot / committed state candidate / snapshot publication candidate 的内部 value facts。
// - Stop-line: 不写真实 queue storage、不创建 global mutable queue、不 enqueue、不 drain、
//   不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Queue committed snapshot 只是 commit finalization candidate 后形成的 committed value fact；
// 它不是实际 queue storage、global state、enqueue record 或 public audit log。
struct CjguiInternalQueueCommittedSnapshot {
    let commitFinalizationCandidate: CjguiInternalQueueStorageCommitFinalizationCandidate
    let didPrepareQueueCommittedSnapshot: Bool
    let shouldDeferQueueCommittedSnapshot: Bool
    let shouldReportQueueCommittedSnapshotBlocked: Bool
    let didPreserveQueueStorageCommitFinalizationCandidate: Bool

    init(
        commitFinalizationCandidate: CjguiInternalQueueStorageCommitFinalizationCandidate,
        didPrepareQueueCommittedSnapshot: Bool,
        shouldDeferQueueCommittedSnapshot: Bool,
        shouldReportQueueCommittedSnapshotBlocked: Bool,
        didPreserveQueueStorageCommitFinalizationCandidate: Bool
    ) {
        this.commitFinalizationCandidate = commitFinalizationCandidate
        this.didPrepareQueueCommittedSnapshot = didPrepareQueueCommittedSnapshot
        this.shouldDeferQueueCommittedSnapshot = shouldDeferQueueCommittedSnapshot
        this.shouldReportQueueCommittedSnapshotBlocked = shouldReportQueueCommittedSnapshotBlocked
        this.didPreserveQueueStorageCommitFinalizationCandidate =
            didPreserveQueueStorageCommitFinalizationCandidate
    }
}

// Queue committed state candidate 只把 snapshot 投影为内部 committed-state candidate；
// candidate 不写 runtime global state，也不会创建全局可变队列。
struct CjguiInternalQueueCommittedStateCandidate {
    let snapshot: CjguiInternalQueueCommittedSnapshot
    let isQueueCommittedStateCandidateReady: Bool
    let shouldDeferQueueCommittedStateCandidate: Bool
    let shouldReportQueueCommittedStateCandidateBlocked: Bool
    let didPreserveQueueCommittedSnapshot: Bool

    init(
        snapshot: CjguiInternalQueueCommittedSnapshot,
        isQueueCommittedStateCandidateReady: Bool,
        shouldDeferQueueCommittedStateCandidate: Bool,
        shouldReportQueueCommittedStateCandidateBlocked: Bool,
        didPreserveQueueCommittedSnapshot: Bool
    ) {
        this.snapshot = snapshot
        this.isQueueCommittedStateCandidateReady = isQueueCommittedStateCandidateReady
        this.shouldDeferQueueCommittedStateCandidate = shouldDeferQueueCommittedStateCandidate
        this.shouldReportQueueCommittedStateCandidateBlocked = shouldReportQueueCommittedStateCandidateBlocked
        this.didPreserveQueueCommittedSnapshot = didPreserveQueueCommittedSnapshot
    }
}

// Queue snapshot publication candidate 是本轮 canonical endpoint；
// publication candidate 只表示 committed value facts 可供未来边界读取，不是 public publication。
struct CjguiInternalQueueSnapshotPublicationCandidate {
    let stateCandidate: CjguiInternalQueueCommittedStateCandidate
    let isQueueSnapshotPublicationCandidateReady: Bool
    let shouldDeferQueueSnapshotPublication: Bool
    let shouldReportQueueSnapshotPublicationBlocked: Bool
    let didPreserveQueueCommittedStateCandidate: Bool

    init(
        stateCandidate: CjguiInternalQueueCommittedStateCandidate,
        isQueueSnapshotPublicationCandidateReady: Bool,
        shouldDeferQueueSnapshotPublication: Bool,
        shouldReportQueueSnapshotPublicationBlocked: Bool,
        didPreserveQueueCommittedStateCandidate: Bool
    ) {
        this.stateCandidate = stateCandidate
        this.isQueueSnapshotPublicationCandidateReady = isQueueSnapshotPublicationCandidateReady
        this.shouldDeferQueueSnapshotPublication = shouldDeferQueueSnapshotPublication
        this.shouldReportQueueSnapshotPublicationBlocked = shouldReportQueueSnapshotPublicationBlocked
        this.didPreserveQueueCommittedStateCandidate = didPreserveQueueCommittedStateCandidate
    }
}

func cjguiInternalBuildQueueCommittedSnapshot(
    commitFinalizationCandidate: CjguiInternalQueueStorageCommitFinalizationCandidate
): CjguiInternalQueueCommittedSnapshot {
    let finalizationReady = commitFinalizationCandidate.isQueueStorageCommitFinalizationCandidateReady &&
        commitFinalizationCandidate.didPreserveQueueStorageCommitReadiness &&
        commitFinalizationCandidate.shouldDeferQueueStorageCommitFinalization == false &&
        commitFinalizationCandidate.shouldReportQueueStorageCommitFinalizationBlocked == false
    let finalizationDeferred =
        commitFinalizationCandidate.isQueueStorageCommitFinalizationCandidateReady == false &&
        commitFinalizationCandidate.didPreserveQueueStorageCommitReadiness == false &&
        commitFinalizationCandidate.shouldDeferQueueStorageCommitFinalization &&
        commitFinalizationCandidate.shouldReportQueueStorageCommitFinalizationBlocked == false
    let finalizationInconsistent = (
        commitFinalizationCandidate.isQueueStorageCommitFinalizationCandidateReady &&
            (commitFinalizationCandidate.shouldDeferQueueStorageCommitFinalization ||
                commitFinalizationCandidate.shouldReportQueueStorageCommitFinalizationBlocked)
        ) ||
        (commitFinalizationCandidate.didPreserveQueueStorageCommitReadiness &&
            commitFinalizationCandidate.isQueueStorageCommitFinalizationCandidateReady == false) ||
        (commitFinalizationCandidate.didPreserveQueueStorageCommitReadiness == false &&
            commitFinalizationCandidate.isQueueStorageCommitFinalizationCandidateReady) ||
        (commitFinalizationCandidate.shouldDeferQueueStorageCommitFinalization &&
            commitFinalizationCandidate.shouldReportQueueStorageCommitFinalizationBlocked)

    // commit finalization facts 不一致时必须 fail-closed，避免被误当作真实 committed queue state。
    if (
        commitFinalizationCandidate.shouldReportQueueStorageCommitFinalizationBlocked ||
        finalizationInconsistent
    ) {
        return CjguiInternalQueueCommittedSnapshot(commitFinalizationCandidate, false, false, true, false)
    }

    if (finalizationReady) {
        return CjguiInternalQueueCommittedSnapshot(commitFinalizationCandidate, true, false, false, true)
    }

    if (finalizationDeferred) {
        return CjguiInternalQueueCommittedSnapshot(commitFinalizationCandidate, false, true, false, false)
    }

    return CjguiInternalQueueCommittedSnapshot(commitFinalizationCandidate, false, false, true, false)
}

func cjguiInternalBuildQueueCommittedStateCandidate(
    snapshot: CjguiInternalQueueCommittedSnapshot
): CjguiInternalQueueCommittedStateCandidate {
    let snapshotReady = snapshot.didPrepareQueueCommittedSnapshot &&
        snapshot.didPreserveQueueStorageCommitFinalizationCandidate &&
        snapshot.shouldDeferQueueCommittedSnapshot == false &&
        snapshot.shouldReportQueueCommittedSnapshotBlocked == false
    let snapshotDeferred = snapshot.didPrepareQueueCommittedSnapshot == false &&
        snapshot.didPreserveQueueStorageCommitFinalizationCandidate == false &&
        snapshot.shouldDeferQueueCommittedSnapshot &&
        snapshot.shouldReportQueueCommittedSnapshotBlocked == false
    let snapshotInconsistent = (
        snapshot.didPrepareQueueCommittedSnapshot &&
            (snapshot.shouldDeferQueueCommittedSnapshot ||
                snapshot.shouldReportQueueCommittedSnapshotBlocked)
        ) ||
        (snapshot.didPreserveQueueStorageCommitFinalizationCandidate &&
            snapshot.didPrepareQueueCommittedSnapshot == false) ||
        (snapshot.didPreserveQueueStorageCommitFinalizationCandidate == false &&
            snapshot.didPrepareQueueCommittedSnapshot) ||
        (snapshot.shouldDeferQueueCommittedSnapshot &&
            snapshot.shouldReportQueueCommittedSnapshotBlocked)

    // committed snapshot facts 不一致时必须 fail-closed，state candidate 不能伪造成全局队列状态。
    if (snapshot.shouldReportQueueCommittedSnapshotBlocked || snapshotInconsistent) {
        return CjguiInternalQueueCommittedStateCandidate(snapshot, false, false, true, false)
    }

    if (snapshotReady) {
        return CjguiInternalQueueCommittedStateCandidate(snapshot, true, false, false, true)
    }

    if (snapshotDeferred) {
        return CjguiInternalQueueCommittedStateCandidate(snapshot, false, true, false, false)
    }

    return CjguiInternalQueueCommittedStateCandidate(snapshot, false, false, true, false)
}

func cjguiInternalBuildQueueSnapshotPublicationCandidate(
    stateCandidate: CjguiInternalQueueCommittedStateCandidate
): CjguiInternalQueueSnapshotPublicationCandidate {
    let candidateReady = stateCandidate.isQueueCommittedStateCandidateReady &&
        stateCandidate.didPreserveQueueCommittedSnapshot &&
        stateCandidate.shouldDeferQueueCommittedStateCandidate == false &&
        stateCandidate.shouldReportQueueCommittedStateCandidateBlocked == false
    let candidateDeferred = stateCandidate.isQueueCommittedStateCandidateReady == false &&
        stateCandidate.didPreserveQueueCommittedSnapshot == false &&
        stateCandidate.shouldDeferQueueCommittedStateCandidate &&
        stateCandidate.shouldReportQueueCommittedStateCandidateBlocked == false
    let candidateInconsistent = (
        stateCandidate.isQueueCommittedStateCandidateReady &&
            (stateCandidate.shouldDeferQueueCommittedStateCandidate ||
                stateCandidate.shouldReportQueueCommittedStateCandidateBlocked)
        ) ||
        (stateCandidate.didPreserveQueueCommittedSnapshot &&
            stateCandidate.isQueueCommittedStateCandidateReady == false) ||
        (stateCandidate.didPreserveQueueCommittedSnapshot == false &&
            stateCandidate.isQueueCommittedStateCandidateReady) ||
        (stateCandidate.shouldDeferQueueCommittedStateCandidate &&
            stateCandidate.shouldReportQueueCommittedStateCandidateBlocked)

    // committed state facts 不一致时必须 fail-closed，publication candidate 不能伪造成 public publication。
    if (
        stateCandidate.shouldReportQueueCommittedStateCandidateBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalQueueSnapshotPublicationCandidate(stateCandidate, false, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalQueueSnapshotPublicationCandidate(stateCandidate, true, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalQueueSnapshotPublicationCandidate(stateCandidate, false, true, false, false)
    }

    return CjguiInternalQueueSnapshotPublicationCandidate(stateCandidate, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueueCommittedSnapshotDraft(): CjguiInternalQueueSnapshotPublicationCandidate {
    // 默认 draft 只串联 committed snapshot value pipeline，不写 queue、不创建全局队列、不 enqueue。
    let commitFinalizationCandidate = cjguiInternalExecuteDefaultQueueStorageCommitDraft()
    let snapshot = cjguiInternalBuildQueueCommittedSnapshot(commitFinalizationCandidate)
    let stateCandidate = cjguiInternalBuildQueueCommittedStateCandidate(snapshot)
    return cjguiInternalBuildQueueSnapshotPublicationCandidate(stateCandidate)
}

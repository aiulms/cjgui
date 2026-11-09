package cjgui

// Internal Queue Real Storage Owner Shell:
// - 本文件只消费 QueueSnapshotPublicationCandidate。
// - Truth 是 immutable queue store owner shell / snapshot / version / transition 的内部 value facts。
// - Stop-line: 不写真实 queue storage、不创建 global mutable queue、不 enqueue、不 drain、
//   不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Queue store version 只是不可变 value-store shell 的版本标记；
// 它不是进程级全局计数器，也不会写入真实 queue storage。
struct CjguiInternalQueueStoreVersion {
    let value: Int64

    init(value: Int64) {
        this.value = value
    }
}

// Queue store snapshot 是第一刀 real storage runway 的不可变 owner shell；
// snapshot 只保存 value facts，不代表真实全局队列或 enqueue side effect。
struct CjguiInternalQueueStoreSnapshot {
    let publicationCandidate: CjguiInternalQueueSnapshotPublicationCandidate
    let version: CjguiInternalQueueStoreVersion
    let didPrepareQueueStoreSnapshot: Bool
    let shouldDeferQueueStoreSnapshot: Bool
    let shouldReportQueueStoreSnapshotBlocked: Bool
    let didPreserveQueueSnapshotPublicationCandidate: Bool

    init(
        publicationCandidate: CjguiInternalQueueSnapshotPublicationCandidate,
        version: CjguiInternalQueueStoreVersion,
        didPrepareQueueStoreSnapshot: Bool,
        shouldDeferQueueStoreSnapshot: Bool,
        shouldReportQueueStoreSnapshotBlocked: Bool,
        didPreserveQueueSnapshotPublicationCandidate: Bool
    ) {
        this.publicationCandidate = publicationCandidate
        this.version = version
        this.didPrepareQueueStoreSnapshot = didPrepareQueueStoreSnapshot
        this.shouldDeferQueueStoreSnapshot = shouldDeferQueueStoreSnapshot
        this.shouldReportQueueStoreSnapshotBlocked = shouldReportQueueStoreSnapshotBlocked
        this.didPreserveQueueSnapshotPublicationCandidate = didPreserveQueueSnapshotPublicationCandidate
    }
}

// Queue store transition 只表达 previous -> next immutable snapshot 的 value transition；
// 它不是 storage write，也不会创建或替换全局 mutable queue。
struct CjguiInternalQueueStoreTransition {
    let previousSnapshot: CjguiInternalQueueStoreSnapshot
    let nextSnapshot: CjguiInternalQueueStoreSnapshot
    let didTransitionQueueStoreSnapshot: Bool
    let shouldDeferQueueStoreTransition: Bool
    let shouldReportQueueStoreTransitionBlocked: Bool
    let didPreserveQueueStoreSnapshot: Bool

    init(
        previousSnapshot: CjguiInternalQueueStoreSnapshot,
        nextSnapshot: CjguiInternalQueueStoreSnapshot,
        didTransitionQueueStoreSnapshot: Bool,
        shouldDeferQueueStoreTransition: Bool,
        shouldReportQueueStoreTransitionBlocked: Bool,
        didPreserveQueueStoreSnapshot: Bool
    ) {
        this.previousSnapshot = previousSnapshot
        this.nextSnapshot = nextSnapshot
        this.didTransitionQueueStoreSnapshot = didTransitionQueueStoreSnapshot
        this.shouldDeferQueueStoreTransition = shouldDeferQueueStoreTransition
        this.shouldReportQueueStoreTransitionBlocked = shouldReportQueueStoreTransitionBlocked
        this.didPreserveQueueStoreSnapshot = didPreserveQueueStoreSnapshot
    }
}

// Queue store commit candidate 是本轮 canonical endpoint；
// 它只表示 immutable store transition 可作为未来 commit candidate，不是真实 queue commit。
struct CjguiInternalQueueStoreCommitCandidate {
    let transition: CjguiInternalQueueStoreTransition
    let canCommitQueueStoreValue: Bool
    let shouldDeferQueueStoreCommit: Bool
    let shouldReportQueueStoreCommitBlocked: Bool
    let didPreserveQueueStoreTransition: Bool

    init(
        transition: CjguiInternalQueueStoreTransition,
        canCommitQueueStoreValue: Bool,
        shouldDeferQueueStoreCommit: Bool,
        shouldReportQueueStoreCommitBlocked: Bool,
        didPreserveQueueStoreTransition: Bool
    ) {
        this.transition = transition
        this.canCommitQueueStoreValue = canCommitQueueStoreValue
        this.shouldDeferQueueStoreCommit = shouldDeferQueueStoreCommit
        this.shouldReportQueueStoreCommitBlocked = shouldReportQueueStoreCommitBlocked
        this.didPreserveQueueStoreTransition = didPreserveQueueStoreTransition
    }
}

func cjguiInternalBuildInitialQueueStoreSnapshot(
    publicationCandidate: CjguiInternalQueueSnapshotPublicationCandidate
): CjguiInternalQueueStoreSnapshot {
    return CjguiInternalQueueStoreSnapshot(
        publicationCandidate,
        CjguiInternalQueueStoreVersion(0),
        false,
        false,
        false,
        false
    )
}

func cjguiInternalBuildNextQueueStoreSnapshot(
    publicationCandidate: CjguiInternalQueueSnapshotPublicationCandidate,
    previousSnapshot: CjguiInternalQueueStoreSnapshot
): CjguiInternalQueueStoreSnapshot {
    let candidateReady = publicationCandidate.isQueueSnapshotPublicationCandidateReady &&
        publicationCandidate.didPreserveQueueCommittedStateCandidate &&
        publicationCandidate.shouldDeferQueueSnapshotPublication == false &&
        publicationCandidate.shouldReportQueueSnapshotPublicationBlocked == false
    let candidateDeferred = publicationCandidate.isQueueSnapshotPublicationCandidateReady == false &&
        publicationCandidate.didPreserveQueueCommittedStateCandidate == false &&
        publicationCandidate.shouldDeferQueueSnapshotPublication &&
        publicationCandidate.shouldReportQueueSnapshotPublicationBlocked == false
    let candidateInconsistent = (
        publicationCandidate.isQueueSnapshotPublicationCandidateReady &&
            (publicationCandidate.shouldDeferQueueSnapshotPublication ||
                publicationCandidate.shouldReportQueueSnapshotPublicationBlocked)
        ) ||
        (publicationCandidate.didPreserveQueueCommittedStateCandidate &&
            publicationCandidate.isQueueSnapshotPublicationCandidateReady == false) ||
        (publicationCandidate.didPreserveQueueCommittedStateCandidate == false &&
            publicationCandidate.isQueueSnapshotPublicationCandidateReady) ||
        (publicationCandidate.shouldDeferQueueSnapshotPublication &&
            publicationCandidate.shouldReportQueueSnapshotPublicationBlocked)

    // snapshot publication facts 不一致时必须 fail-closed，避免被误当成真实 queue storage 写入。
    if (
        publicationCandidate.shouldReportQueueSnapshotPublicationBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalQueueStoreSnapshot(
            publicationCandidate,
            previousSnapshot.version,
            false,
            false,
            true,
            false
        )
    }

    if (candidateReady) {
        return CjguiInternalQueueStoreSnapshot(
            publicationCandidate,
            CjguiInternalQueueStoreVersion(previousSnapshot.version.value + 1),
            true,
            false,
            false,
            true
        )
    }

    if (candidateDeferred) {
        return CjguiInternalQueueStoreSnapshot(
            publicationCandidate,
            previousSnapshot.version,
            false,
            true,
            false,
            false
        )
    }

    return CjguiInternalQueueStoreSnapshot(
        publicationCandidate,
        previousSnapshot.version,
        false,
        false,
        true,
        false
    )
}

func cjguiInternalBuildQueueStoreTransition(
    previousSnapshot: CjguiInternalQueueStoreSnapshot,
    nextSnapshot: CjguiInternalQueueStoreSnapshot
): CjguiInternalQueueStoreTransition {
    let snapshotReady = nextSnapshot.didPrepareQueueStoreSnapshot &&
        nextSnapshot.didPreserveQueueSnapshotPublicationCandidate &&
        nextSnapshot.shouldDeferQueueStoreSnapshot == false &&
        nextSnapshot.shouldReportQueueStoreSnapshotBlocked == false
    let snapshotDeferred = nextSnapshot.didPrepareQueueStoreSnapshot == false &&
        nextSnapshot.didPreserveQueueSnapshotPublicationCandidate == false &&
        nextSnapshot.shouldDeferQueueStoreSnapshot &&
        nextSnapshot.shouldReportQueueStoreSnapshotBlocked == false
    let snapshotInconsistent = (
        nextSnapshot.didPrepareQueueStoreSnapshot &&
            (nextSnapshot.shouldDeferQueueStoreSnapshot ||
                nextSnapshot.shouldReportQueueStoreSnapshotBlocked)
        ) ||
        (nextSnapshot.didPreserveQueueSnapshotPublicationCandidate &&
            nextSnapshot.didPrepareQueueStoreSnapshot == false) ||
        (nextSnapshot.didPreserveQueueSnapshotPublicationCandidate == false &&
            nextSnapshot.didPrepareQueueStoreSnapshot) ||
        (nextSnapshot.shouldDeferQueueStoreSnapshot &&
            nextSnapshot.shouldReportQueueStoreSnapshotBlocked)

    // store snapshot facts 不一致时必须 fail-closed，transition 不能伪造成真实队列提交。
    if (nextSnapshot.shouldReportQueueStoreSnapshotBlocked || snapshotInconsistent) {
        return CjguiInternalQueueStoreTransition(previousSnapshot, nextSnapshot, false, false, true, false)
    }

    if (snapshotReady) {
        return CjguiInternalQueueStoreTransition(previousSnapshot, nextSnapshot, true, false, false, true)
    }

    if (snapshotDeferred) {
        return CjguiInternalQueueStoreTransition(previousSnapshot, nextSnapshot, false, true, false, false)
    }

    return CjguiInternalQueueStoreTransition(previousSnapshot, nextSnapshot, false, false, true, false)
}

func cjguiInternalBuildQueueStoreCommitCandidate(
    transition: CjguiInternalQueueStoreTransition
): CjguiInternalQueueStoreCommitCandidate {
    let transitionReady = transition.didTransitionQueueStoreSnapshot &&
        transition.didPreserveQueueStoreSnapshot &&
        transition.shouldDeferQueueStoreTransition == false &&
        transition.shouldReportQueueStoreTransitionBlocked == false
    let transitionDeferred = transition.didTransitionQueueStoreSnapshot == false &&
        transition.didPreserveQueueStoreSnapshot == false &&
        transition.shouldDeferQueueStoreTransition &&
        transition.shouldReportQueueStoreTransitionBlocked == false
    let transitionInconsistent = (
        transition.didTransitionQueueStoreSnapshot &&
            (transition.shouldDeferQueueStoreTransition ||
                transition.shouldReportQueueStoreTransitionBlocked)
        ) ||
        (transition.didPreserveQueueStoreSnapshot &&
            transition.didTransitionQueueStoreSnapshot == false) ||
        (transition.didPreserveQueueStoreSnapshot == false &&
            transition.didTransitionQueueStoreSnapshot) ||
        (transition.shouldDeferQueueStoreTransition &&
            transition.shouldReportQueueStoreTransitionBlocked)

    // store transition facts 不一致时必须 fail-closed，commit candidate 仍不能写真实 queue storage。
    if (
        transition.shouldReportQueueStoreTransitionBlocked ||
        transitionInconsistent
    ) {
        return CjguiInternalQueueStoreCommitCandidate(transition, false, false, true, false)
    }

    if (transitionReady) {
        return CjguiInternalQueueStoreCommitCandidate(transition, true, false, false, true)
    }

    if (transitionDeferred) {
        return CjguiInternalQueueStoreCommitCandidate(transition, false, true, false, false)
    }

    return CjguiInternalQueueStoreCommitCandidate(transition, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueueStoreDraft(): CjguiInternalQueueStoreCommitCandidate {
    // 默认 draft 只串联 immutable value-store pipeline，不写全局队列、不 enqueue、不 drain。
    let publicationCandidate = cjguiInternalExecuteDefaultQueueCommittedSnapshotDraft()
    let previousSnapshot = cjguiInternalBuildInitialQueueStoreSnapshot(publicationCandidate)
    let nextSnapshot = cjguiInternalBuildNextQueueStoreSnapshot(publicationCandidate, previousSnapshot)
    let transition = cjguiInternalBuildQueueStoreTransition(previousSnapshot, nextSnapshot)
    return cjguiInternalBuildQueueStoreCommitCandidate(transition)
}

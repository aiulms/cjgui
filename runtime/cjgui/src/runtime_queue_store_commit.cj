package cjgui

// Internal Queue Immutable Store Write Commit owner:
// - 本文件只消费 QueueStoreWriteReadiness。
// - Truth 是 immutable write commit / committed store / commit result / publication candidate 内部 value facts。
// - Stop-line: 不写真实 process-wide queue storage、不创建 global mutable queue、不 enqueue、不 drain、
//   不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Immutable write commit 只说明 write readiness 可被收束为不可变提交意图；
// 它不是真实全局 queue 写入，也不会创建 singleton 或触发 enqueue。
struct CjguiInternalQueueImmutableWriteCommit {
    let writeReadiness: CjguiInternalQueueStoreWriteReadiness
    let didCommitImmutableQueueStoreWrite: Bool
    let shouldDeferImmutableQueueStoreWriteCommit: Bool
    let shouldReportImmutableQueueStoreWriteCommitBlocked: Bool
    let didPreserveQueueStoreWriteReadiness: Bool

    init(
        writeReadiness: CjguiInternalQueueStoreWriteReadiness,
        didCommitImmutableQueueStoreWrite: Bool,
        shouldDeferImmutableQueueStoreWriteCommit: Bool,
        shouldReportImmutableQueueStoreWriteCommitBlocked: Bool,
        didPreserveQueueStoreWriteReadiness: Bool
    ) {
        this.writeReadiness = writeReadiness
        this.didCommitImmutableQueueStoreWrite = didCommitImmutableQueueStoreWrite
        this.shouldDeferImmutableQueueStoreWriteCommit = shouldDeferImmutableQueueStoreWriteCommit
        this.shouldReportImmutableQueueStoreWriteCommitBlocked = shouldReportImmutableQueueStoreWriteCommitBlocked
        this.didPreserveQueueStoreWriteReadiness = didPreserveQueueStoreWriteReadiness
    }
}

// Immutable committed store 是从 write readiness 派生出的新 value；
// committedSnapshot 只是不可变值，不是进程级全局队列或 runtime global state。
struct CjguiInternalQueueImmutableCommittedStore {
    let writeCommit: CjguiInternalQueueImmutableWriteCommit
    let committedSnapshot: CjguiInternalQueueStoreSnapshot
    let didPrepareImmutableCommittedStore: Bool
    let shouldDeferImmutableCommittedStore: Bool
    let shouldReportImmutableCommittedStoreBlocked: Bool
    let didPreserveImmutableWriteCommit: Bool

    init(
        writeCommit: CjguiInternalQueueImmutableWriteCommit,
        committedSnapshot: CjguiInternalQueueStoreSnapshot,
        didPrepareImmutableCommittedStore: Bool,
        shouldDeferImmutableCommittedStore: Bool,
        shouldReportImmutableCommittedStoreBlocked: Bool,
        didPreserveImmutableWriteCommit: Bool
    ) {
        this.writeCommit = writeCommit
        this.committedSnapshot = committedSnapshot
        this.didPrepareImmutableCommittedStore = didPrepareImmutableCommittedStore
        this.shouldDeferImmutableCommittedStore = shouldDeferImmutableCommittedStore
        this.shouldReportImmutableCommittedStoreBlocked = shouldReportImmutableCommittedStoreBlocked
        this.didPreserveImmutableWriteCommit = didPreserveImmutableWriteCommit
    }
}

// Immutable write commit result 只汇总 committed store value facts；
// result ready 不是 enqueue record、drain plan、public audit log 或真实 storage write。
struct CjguiInternalQueueImmutableWriteCommitResult {
    let committedStore: CjguiInternalQueueImmutableCommittedStore
    let isImmutableQueueStoreWriteCommitResultReady: Bool
    let shouldDeferImmutableQueueStoreWriteCommitResult: Bool
    let shouldReportImmutableQueueStoreWriteCommitResultBlocked: Bool
    let didPreserveImmutableCommittedStore: Bool

    init(
        committedStore: CjguiInternalQueueImmutableCommittedStore,
        isImmutableQueueStoreWriteCommitResultReady: Bool,
        shouldDeferImmutableQueueStoreWriteCommitResult: Bool,
        shouldReportImmutableQueueStoreWriteCommitResultBlocked: Bool,
        didPreserveImmutableCommittedStore: Bool
    ) {
        this.committedStore = committedStore
        this.isImmutableQueueStoreWriteCommitResultReady = isImmutableQueueStoreWriteCommitResultReady
        this.shouldDeferImmutableQueueStoreWriteCommitResult = shouldDeferImmutableQueueStoreWriteCommitResult
        this.shouldReportImmutableQueueStoreWriteCommitResultBlocked =
            shouldReportImmutableQueueStoreWriteCommitResultBlocked
        this.didPreserveImmutableCommittedStore = didPreserveImmutableCommittedStore
    }
}

// Immutable commit publication candidate 是本轮 canonical endpoint；
// publication candidate 只是内部 handoff-ready value，不是 public publication 或 observer callback。
struct CjguiInternalQueueImmutableCommitPublicationCandidate {
    let result: CjguiInternalQueueImmutableWriteCommitResult
    let isImmutableQueueStoreCommitPublicationCandidateReady: Bool
    let shouldDeferImmutableQueueStoreCommitPublication: Bool
    let shouldReportImmutableQueueStoreCommitPublicationBlocked: Bool
    let didPreserveImmutableWriteCommitResult: Bool

    init(
        result: CjguiInternalQueueImmutableWriteCommitResult,
        isImmutableQueueStoreCommitPublicationCandidateReady: Bool,
        shouldDeferImmutableQueueStoreCommitPublication: Bool,
        shouldReportImmutableQueueStoreCommitPublicationBlocked: Bool,
        didPreserveImmutableWriteCommitResult: Bool
    ) {
        this.result = result
        this.isImmutableQueueStoreCommitPublicationCandidateReady =
            isImmutableQueueStoreCommitPublicationCandidateReady
        this.shouldDeferImmutableQueueStoreCommitPublication = shouldDeferImmutableQueueStoreCommitPublication
        this.shouldReportImmutableQueueStoreCommitPublicationBlocked =
            shouldReportImmutableQueueStoreCommitPublicationBlocked
        this.didPreserveImmutableWriteCommitResult = didPreserveImmutableWriteCommitResult
    }
}

func cjguiInternalBuildQueueImmutableWriteCommit(
    writeReadiness: CjguiInternalQueueStoreWriteReadiness
): CjguiInternalQueueImmutableWriteCommit {
    let readinessReady = writeReadiness.isQueueStoreWriteReady &&
        writeReadiness.didPreserveQueueStoreWriteAdmission &&
        writeReadiness.shouldDeferQueueStoreWriteReadiness == false &&
        writeReadiness.shouldReportQueueStoreWriteReadinessBlocked == false
    let readinessDeferred = writeReadiness.isQueueStoreWriteReady == false &&
        writeReadiness.didPreserveQueueStoreWriteAdmission == false &&
        writeReadiness.shouldDeferQueueStoreWriteReadiness &&
        writeReadiness.shouldReportQueueStoreWriteReadinessBlocked == false
    let readinessInconsistent = (
        writeReadiness.isQueueStoreWriteReady &&
            (writeReadiness.shouldDeferQueueStoreWriteReadiness ||
                writeReadiness.shouldReportQueueStoreWriteReadinessBlocked)
        ) ||
        (writeReadiness.didPreserveQueueStoreWriteAdmission &&
            writeReadiness.isQueueStoreWriteReady == false) ||
        (writeReadiness.didPreserveQueueStoreWriteAdmission == false &&
            writeReadiness.isQueueStoreWriteReady) ||
        (writeReadiness.shouldDeferQueueStoreWriteReadiness &&
            writeReadiness.shouldReportQueueStoreWriteReadinessBlocked)

    // write readiness facts 不一致时必须 fail-closed，避免被误当成真实 queue storage 写入。
    if (
        writeReadiness.shouldReportQueueStoreWriteReadinessBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalQueueImmutableWriteCommit(writeReadiness, false, false, true, false)
    }

    if (readinessReady) {
        return CjguiInternalQueueImmutableWriteCommit(writeReadiness, true, false, false, true)
    }

    if (readinessDeferred) {
        return CjguiInternalQueueImmutableWriteCommit(writeReadiness, false, true, false, false)
    }

    return CjguiInternalQueueImmutableWriteCommit(writeReadiness, false, false, true, false)
}

func cjguiInternalBuildQueueImmutableCommittedStore(
    writeCommit: CjguiInternalQueueImmutableWriteCommit
): CjguiInternalQueueImmutableCommittedStore {
    let previousSnapshot = writeCommit.writeReadiness.admission.policy.storeCommitCandidate.transition.previousSnapshot
    let nextSnapshot = writeCommit.writeReadiness.admission.policy.storeCommitCandidate.transition.nextSnapshot
    let commitReady = writeCommit.didCommitImmutableQueueStoreWrite &&
        writeCommit.didPreserveQueueStoreWriteReadiness &&
        writeCommit.shouldDeferImmutableQueueStoreWriteCommit == false &&
        writeCommit.shouldReportImmutableQueueStoreWriteCommitBlocked == false
    let commitDeferred = writeCommit.didCommitImmutableQueueStoreWrite == false &&
        writeCommit.didPreserveQueueStoreWriteReadiness == false &&
        writeCommit.shouldDeferImmutableQueueStoreWriteCommit &&
        writeCommit.shouldReportImmutableQueueStoreWriteCommitBlocked == false
    let commitInconsistent = (
        writeCommit.didCommitImmutableQueueStoreWrite &&
            (writeCommit.shouldDeferImmutableQueueStoreWriteCommit ||
                writeCommit.shouldReportImmutableQueueStoreWriteCommitBlocked)
        ) ||
        (writeCommit.didPreserveQueueStoreWriteReadiness &&
            writeCommit.didCommitImmutableQueueStoreWrite == false) ||
        (writeCommit.didPreserveQueueStoreWriteReadiness == false &&
            writeCommit.didCommitImmutableQueueStoreWrite) ||
        (writeCommit.shouldDeferImmutableQueueStoreWriteCommit &&
            writeCommit.shouldReportImmutableQueueStoreWriteCommitBlocked)

    // write commit facts 不一致时必须 fail-closed，并保留 previous snapshot 不变。
    if (
        writeCommit.shouldReportImmutableQueueStoreWriteCommitBlocked ||
        commitInconsistent
    ) {
        return CjguiInternalQueueImmutableCommittedStore(writeCommit, previousSnapshot, false, false, true, false)
    }

    if (commitReady) {
        return CjguiInternalQueueImmutableCommittedStore(writeCommit, nextSnapshot, true, false, false, true)
    }

    if (commitDeferred) {
        return CjguiInternalQueueImmutableCommittedStore(writeCommit, previousSnapshot, false, true, false, false)
    }

    return CjguiInternalQueueImmutableCommittedStore(writeCommit, previousSnapshot, false, false, true, false)
}

func cjguiInternalBuildQueueImmutableWriteCommitResult(
    committedStore: CjguiInternalQueueImmutableCommittedStore
): CjguiInternalQueueImmutableWriteCommitResult {
    let storeReady = committedStore.didPrepareImmutableCommittedStore &&
        committedStore.didPreserveImmutableWriteCommit &&
        committedStore.shouldDeferImmutableCommittedStore == false &&
        committedStore.shouldReportImmutableCommittedStoreBlocked == false
    let storeDeferred = committedStore.didPrepareImmutableCommittedStore == false &&
        committedStore.didPreserveImmutableWriteCommit == false &&
        committedStore.shouldDeferImmutableCommittedStore &&
        committedStore.shouldReportImmutableCommittedStoreBlocked == false
    let storeInconsistent = (
        committedStore.didPrepareImmutableCommittedStore &&
            (committedStore.shouldDeferImmutableCommittedStore ||
                committedStore.shouldReportImmutableCommittedStoreBlocked)
        ) ||
        (committedStore.didPreserveImmutableWriteCommit &&
            committedStore.didPrepareImmutableCommittedStore == false) ||
        (committedStore.didPreserveImmutableWriteCommit == false &&
            committedStore.didPrepareImmutableCommittedStore) ||
        (committedStore.shouldDeferImmutableCommittedStore &&
            committedStore.shouldReportImmutableCommittedStoreBlocked)

    // committed store facts 不一致时必须 fail-closed，result 不能伪造成真实 queue write。
    if (
        committedStore.shouldReportImmutableCommittedStoreBlocked ||
        storeInconsistent
    ) {
        return CjguiInternalQueueImmutableWriteCommitResult(committedStore, false, false, true, false)
    }

    if (storeReady) {
        return CjguiInternalQueueImmutableWriteCommitResult(committedStore, true, false, false, true)
    }

    if (storeDeferred) {
        return CjguiInternalQueueImmutableWriteCommitResult(committedStore, false, true, false, false)
    }

    return CjguiInternalQueueImmutableWriteCommitResult(committedStore, false, false, true, false)
}

func cjguiInternalBuildQueueImmutableCommitPublicationCandidate(
    result: CjguiInternalQueueImmutableWriteCommitResult
): CjguiInternalQueueImmutableCommitPublicationCandidate {
    let resultReady = result.isImmutableQueueStoreWriteCommitResultReady &&
        result.didPreserveImmutableCommittedStore &&
        result.shouldDeferImmutableQueueStoreWriteCommitResult == false &&
        result.shouldReportImmutableQueueStoreWriteCommitResultBlocked == false
    let resultDeferred = result.isImmutableQueueStoreWriteCommitResultReady == false &&
        result.didPreserveImmutableCommittedStore == false &&
        result.shouldDeferImmutableQueueStoreWriteCommitResult &&
        result.shouldReportImmutableQueueStoreWriteCommitResultBlocked == false
    let resultInconsistent = (
        result.isImmutableQueueStoreWriteCommitResultReady &&
            (result.shouldDeferImmutableQueueStoreWriteCommitResult ||
                result.shouldReportImmutableQueueStoreWriteCommitResultBlocked)
        ) ||
        (result.didPreserveImmutableCommittedStore &&
            result.isImmutableQueueStoreWriteCommitResultReady == false) ||
        (result.didPreserveImmutableCommittedStore == false &&
            result.isImmutableQueueStoreWriteCommitResultReady) ||
        (result.shouldDeferImmutableQueueStoreWriteCommitResult &&
            result.shouldReportImmutableQueueStoreWriteCommitResultBlocked)

    // commit result facts 不一致时必须 fail-closed，publication candidate 仍不是 public publication。
    if (
        result.shouldReportImmutableQueueStoreWriteCommitResultBlocked ||
        resultInconsistent
    ) {
        return CjguiInternalQueueImmutableCommitPublicationCandidate(result, false, false, true, false)
    }

    if (resultReady) {
        return CjguiInternalQueueImmutableCommitPublicationCandidate(result, true, false, false, true)
    }

    if (resultDeferred) {
        return CjguiInternalQueueImmutableCommitPublicationCandidate(result, false, true, false, false)
    }

    return CjguiInternalQueueImmutableCommitPublicationCandidate(result, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueueImmutableStoreWriteCommitDraft(
): CjguiInternalQueueImmutableCommitPublicationCandidate {
    // 默认 draft 只串联 immutable write-commit value pipeline，不写全局队列、不 enqueue、不 drain。
    let writeReadiness = cjguiInternalExecuteDefaultQueueStoreWriteDraft()
    let writeCommit = cjguiInternalBuildQueueImmutableWriteCommit(writeReadiness)
    let committedStore = cjguiInternalBuildQueueImmutableCommittedStore(writeCommit)
    let result = cjguiInternalBuildQueueImmutableWriteCommitResult(committedStore)
    return cjguiInternalBuildQueueImmutableCommitPublicationCandidate(result)
}

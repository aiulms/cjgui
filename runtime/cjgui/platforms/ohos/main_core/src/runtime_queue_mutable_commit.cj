package cjgui

// Internal Queue Owner-Local Mutable Write Commit owner:
// - 本文件只消费 QueueMutableWriteReadiness。
// - Truth 是 owner-local mutable write commit / post-write holder / commit result 的内部 value facts。
// - Stop-line: 不做真实 item collection mutation、不写 process-wide queue storage、不创建 global mutable queue / singleton、
//   不公开 mutable API、不 enqueue、不 drain、不接 event loop / scheduler / platform callback、不调用 runtime cycle，
//   也不回塞 critical runtime_state.cj。

// Mutable write commit 只说明 write readiness 是否可被收束为 owner-local commit facts；
// 它不是实际 queue storage write，也不会创建 public enqueue 或跨 owner mutable reference。
struct CjguiInternalQueueMutableWriteCommit {
    let readiness: CjguiInternalQueueMutableWriteReadiness
    let didCommitOwnerLocalMutableWrite: Bool
    let shouldDeferQueueMutableWriteCommit: Bool
    let shouldReportQueueMutableWriteCommitBlocked: Bool
    let didPreserveQueueMutableWriteReadiness: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        readiness: CjguiInternalQueueMutableWriteReadiness,
        didCommitOwnerLocalMutableWrite: Bool,
        shouldDeferQueueMutableWriteCommit: Bool,
        shouldReportQueueMutableWriteCommitBlocked: Bool,
        didPreserveQueueMutableWriteReadiness: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.readiness = readiness
        this.didCommitOwnerLocalMutableWrite = didCommitOwnerLocalMutableWrite
        this.shouldDeferQueueMutableWriteCommit = shouldDeferQueueMutableWriteCommit
        this.shouldReportQueueMutableWriteCommitBlocked = shouldReportQueueMutableWriteCommitBlocked
        this.didPreserveQueueMutableWriteReadiness = didPreserveQueueMutableWriteReadiness
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Post-write holder 只携带 commit 后选择的 snapshot / version value；
// 它不是可逃逸的 mutable holder，也不会修改真实 item collection。
struct CjguiInternalQueueMutablePostWriteHolder {
    let commit: CjguiInternalQueueMutableWriteCommit
    let postWriteSnapshot: CjguiInternalQueueStoreSnapshot
    let previousSnapshotFallback: CjguiInternalQueueStoreSnapshot
    let committedVersion: CjguiInternalQueueStoreVersion
    let didPrepareQueueMutablePostWriteHolder: Bool
    let shouldDeferQueueMutablePostWriteHolder: Bool
    let shouldReportQueueMutablePostWriteHolderBlocked: Bool
    let didPreserveQueueMutableWriteCommit: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        commit: CjguiInternalQueueMutableWriteCommit,
        postWriteSnapshot: CjguiInternalQueueStoreSnapshot,
        previousSnapshotFallback: CjguiInternalQueueStoreSnapshot,
        committedVersion: CjguiInternalQueueStoreVersion,
        didPrepareQueueMutablePostWriteHolder: Bool,
        shouldDeferQueueMutablePostWriteHolder: Bool,
        shouldReportQueueMutablePostWriteHolderBlocked: Bool,
        didPreserveQueueMutableWriteCommit: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.commit = commit
        this.postWriteSnapshot = postWriteSnapshot
        this.previousSnapshotFallback = previousSnapshotFallback
        this.committedVersion = committedVersion
        this.didPrepareQueueMutablePostWriteHolder = didPrepareQueueMutablePostWriteHolder
        this.shouldDeferQueueMutablePostWriteHolder = shouldDeferQueueMutablePostWriteHolder
        this.shouldReportQueueMutablePostWriteHolderBlocked = shouldReportQueueMutablePostWriteHolderBlocked
        this.didPreserveQueueMutableWriteCommit = didPreserveQueueMutableWriteCommit
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Mutable write commit result 是本轮 canonical endpoint；
// ready 只表示 owner-local commit facts 已收束，不是真实全局队列写入结果。
struct CjguiInternalQueueMutableWriteCommitResult {
    let postWriteHolder: CjguiInternalQueueMutablePostWriteHolder
    let isQueueMutableWriteCommitResultReady: Bool
    let didCommitOwnerLocalMutableWrite: Bool
    let shouldDeferQueueMutableWriteCommitResult: Bool
    let shouldReportQueueMutableWriteCommitResultBlocked: Bool
    let didPreserveQueueMutablePostWriteHolder: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        postWriteHolder: CjguiInternalQueueMutablePostWriteHolder,
        isQueueMutableWriteCommitResultReady: Bool,
        didCommitOwnerLocalMutableWrite: Bool,
        shouldDeferQueueMutableWriteCommitResult: Bool,
        shouldReportQueueMutableWriteCommitResultBlocked: Bool,
        didPreserveQueueMutablePostWriteHolder: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.postWriteHolder = postWriteHolder
        this.isQueueMutableWriteCommitResultReady = isQueueMutableWriteCommitResultReady
        this.didCommitOwnerLocalMutableWrite = didCommitOwnerLocalMutableWrite
        this.shouldDeferQueueMutableWriteCommitResult = shouldDeferQueueMutableWriteCommitResult
        this.shouldReportQueueMutableWriteCommitResultBlocked = shouldReportQueueMutableWriteCommitResultBlocked
        this.didPreserveQueueMutablePostWriteHolder = didPreserveQueueMutablePostWriteHolder
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueueMutableWriteCommit(
    readiness: CjguiInternalQueueMutableWriteReadiness
): CjguiInternalQueueMutableWriteCommit {
    let admission = readiness.admission
    let versionCheck = admission.versionCheck
    let policy = versionCheck.policy
    let shell = policy.shell
    let versionMatches = versionCheck.expectedVersion.value == versionCheck.observedVersion.value
    let readinessReady = readiness.isQueueMutableWriteReady &&
        readiness.didPreserveQueueMutableWriteAdmission &&
        readiness.shouldDeferQueueMutableWriteReadiness == false &&
        readiness.shouldReportQueueMutableWriteReadinessBlocked == false &&
        admission.isQueueMutableWriteAdmissionOpen &&
        admission.didPreserveQueueMutableWriteVersionCheck &&
        admission.shouldDeferQueueMutableWriteAdmission == false &&
        admission.shouldReportQueueMutableWriteAdmissionBlocked == false &&
        versionCheck.didPassQueueMutableWriteVersionCheck &&
        versionCheck.didPreserveQueueMutableWritePolicy &&
        versionCheck.shouldDeferQueueMutableWriteVersionCheck == false &&
        versionCheck.shouldReportQueueMutableWriteVersionCheckBlocked == false &&
        policy.allowsOwnerLocalMutableWrite &&
        policy.didPreserveQueueMutableStoreShell &&
        policy.didRequireQueueMutableWriteVersionCheck &&
        policy.shouldDeferQueueMutableWritePolicy == false &&
        policy.shouldReportQueueMutableWritePolicyBlocked == false &&
        shell.isQueueMutableStoreShellReady &&
        shell.didKeepQueueMutableStoreOwnerLocal
    let readinessDeferred = readiness.isQueueMutableWriteReady == false &&
        readiness.didPreserveQueueMutableWriteAdmission == false &&
        readiness.shouldDeferQueueMutableWriteReadiness &&
        readiness.shouldReportQueueMutableWriteReadinessBlocked == false
    let readinessInconsistent = (
        readiness.isQueueMutableWriteReady &&
            (
                readiness.shouldDeferQueueMutableWriteReadiness ||
                readiness.shouldReportQueueMutableWriteReadinessBlocked
            )
        ) ||
        (readiness.didPreserveQueueMutableWriteAdmission &&
            readiness.isQueueMutableWriteReady == false) ||
        (readiness.didPreserveQueueMutableWriteAdmission == false &&
            readiness.isQueueMutableWriteReady) ||
        (readiness.shouldDeferQueueMutableWriteReadiness &&
            readiness.shouldReportQueueMutableWriteReadinessBlocked) ||
        (readiness.isQueueMutableWriteReady && admission.isQueueMutableWriteAdmissionOpen == false) ||
        (admission.isQueueMutableWriteAdmissionOpen && versionCheck.didPassQueueMutableWriteVersionCheck == false) ||
        (versionCheck.didPassQueueMutableWriteVersionCheck && versionMatches == false) ||
        (policy.allowsOwnerLocalMutableWrite && shell.didKeepQueueMutableStoreOwnerLocal == false)

    // readiness / admission / version facts 不一致时必须 fail-closed，避免伪造 owner-local commit 成功。
    if (
        readiness.shouldReportQueueMutableWriteReadinessBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalQueueMutableWriteCommit(readiness, false, false, true, false, true)
    }

    if (readinessReady && versionMatches) {
        return CjguiInternalQueueMutableWriteCommit(readiness, true, false, false, true, true)
    }

    if (readinessDeferred) {
        return CjguiInternalQueueMutableWriteCommit(readiness, false, true, false, false, true)
    }

    return CjguiInternalQueueMutableWriteCommit(readiness, false, false, true, false, true)
}

func cjguiInternalBuildQueueMutablePostWriteHolder(
    commit: CjguiInternalQueueMutableWriteCommit
): CjguiInternalQueueMutablePostWriteHolder {
    let sourceHolder = commit.readiness.admission.versionCheck.policy.shell.versionMarker.holder
    let currentSnapshot = sourceHolder.currentSnapshot
    let previousSnapshot = sourceHolder.previousSnapshotFallback
    let commitReady = commit.didCommitOwnerLocalMutableWrite &&
        commit.didPreserveQueueMutableWriteReadiness &&
        commit.didPreservePreviousQueueStoreSnapshot &&
        commit.shouldDeferQueueMutableWriteCommit == false &&
        commit.shouldReportQueueMutableWriteCommitBlocked == false
    let commitDeferred = commit.didCommitOwnerLocalMutableWrite == false &&
        commit.didPreserveQueueMutableWriteReadiness == false &&
        commit.didPreservePreviousQueueStoreSnapshot &&
        commit.shouldDeferQueueMutableWriteCommit &&
        commit.shouldReportQueueMutableWriteCommitBlocked == false
    let commitInconsistent = (
        commit.didCommitOwnerLocalMutableWrite &&
            (commit.shouldDeferQueueMutableWriteCommit || commit.shouldReportQueueMutableWriteCommitBlocked)
        ) ||
        (commit.didPreserveQueueMutableWriteReadiness &&
            commit.didCommitOwnerLocalMutableWrite == false) ||
        (commit.didPreserveQueueMutableWriteReadiness == false &&
            commit.didCommitOwnerLocalMutableWrite) ||
        (commit.didPreservePreviousQueueStoreSnapshot == false) ||
        (commit.shouldDeferQueueMutableWriteCommit && commit.shouldReportQueueMutableWriteCommitBlocked)

    // commit facts 不一致时必须 fail-closed，post-write holder 保留 previous snapshot fallback。
    if (
        commit.shouldReportQueueMutableWriteCommitBlocked ||
        commitInconsistent
    ) {
        return CjguiInternalQueueMutablePostWriteHolder(
            commit,
            previousSnapshot,
            previousSnapshot,
            previousSnapshot.version,
            false,
            false,
            true,
            false,
            commit.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (commitReady) {
        return CjguiInternalQueueMutablePostWriteHolder(
            commit,
            currentSnapshot,
            previousSnapshot,
            currentSnapshot.version,
            true,
            false,
            false,
            true,
            true
        )
    }

    if (commitDeferred) {
        return CjguiInternalQueueMutablePostWriteHolder(
            commit,
            previousSnapshot,
            previousSnapshot,
            previousSnapshot.version,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueMutablePostWriteHolder(
        commit,
        previousSnapshot,
        previousSnapshot,
        previousSnapshot.version,
        false,
        false,
        true,
        false,
        commit.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueMutableWriteCommitResult(
    postWriteHolder: CjguiInternalQueueMutablePostWriteHolder
): CjguiInternalQueueMutableWriteCommitResult {
    let holderReady = postWriteHolder.didPrepareQueueMutablePostWriteHolder &&
        postWriteHolder.didPreserveQueueMutableWriteCommit &&
        postWriteHolder.didPreservePreviousQueueStoreSnapshot &&
        postWriteHolder.shouldDeferQueueMutablePostWriteHolder == false &&
        postWriteHolder.shouldReportQueueMutablePostWriteHolderBlocked == false
    let holderDeferred = postWriteHolder.didPrepareQueueMutablePostWriteHolder == false &&
        postWriteHolder.didPreserveQueueMutableWriteCommit == false &&
        postWriteHolder.didPreservePreviousQueueStoreSnapshot &&
        postWriteHolder.shouldDeferQueueMutablePostWriteHolder &&
        postWriteHolder.shouldReportQueueMutablePostWriteHolderBlocked == false
    let holderInconsistent = (
        postWriteHolder.didPrepareQueueMutablePostWriteHolder &&
            (
                postWriteHolder.shouldDeferQueueMutablePostWriteHolder ||
                postWriteHolder.shouldReportQueueMutablePostWriteHolderBlocked
            )
        ) ||
        (postWriteHolder.didPreserveQueueMutableWriteCommit &&
            postWriteHolder.didPrepareQueueMutablePostWriteHolder == false) ||
        (postWriteHolder.didPreserveQueueMutableWriteCommit == false &&
            postWriteHolder.didPrepareQueueMutablePostWriteHolder) ||
        (postWriteHolder.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            postWriteHolder.shouldDeferQueueMutablePostWriteHolder &&
            postWriteHolder.shouldReportQueueMutablePostWriteHolderBlocked
        )

    // post-write holder facts 不一致时必须 fail-closed，commit result 不代表真实全局队列写入。
    if (
        postWriteHolder.shouldReportQueueMutablePostWriteHolderBlocked ||
        holderInconsistent
    ) {
        return CjguiInternalQueueMutableWriteCommitResult(
            postWriteHolder,
            false,
            false,
            false,
            true,
            false,
            postWriteHolder.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (holderReady) {
        return CjguiInternalQueueMutableWriteCommitResult(
            postWriteHolder,
            true,
            true,
            false,
            false,
            true,
            true
        )
    }

    if (holderDeferred) {
        return CjguiInternalQueueMutableWriteCommitResult(
            postWriteHolder,
            false,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueMutableWriteCommitResult(
        postWriteHolder,
        false,
        false,
        false,
        true,
        false,
        postWriteHolder.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueueMutableWriteCommitDraft(): CjguiInternalQueueMutableWriteCommitResult {
    // 默认 draft 只串联 owner-local mutable write commit value pipeline，不写真实队列、不 enqueue、不 drain。
    let readiness = cjguiInternalExecuteDefaultQueueMutableWriteAdmissionDraft()
    let commit = cjguiInternalBuildQueueMutableWriteCommit(readiness)
    let postWriteHolder = cjguiInternalBuildQueueMutablePostWriteHolder(commit)
    return cjguiInternalBuildQueueMutableWriteCommitResult(postWriteHolder)
}

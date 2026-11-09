package cjgui

// Internal Queue Owner-Local Write Realization owner:
// - 本文件只消费 QueueProcessLocalWritePreflight。
// - Truth 是 owner-local write realization / post-realization holder / write result 的内部 value facts。
// - Stop-line: 不做 public enqueue、不写 process-wide queue storage、不创建 global mutable queue / singleton、
//   不公开 public mutable API / C ABI、不产生 cross-owner mutable reference、不 drain、
//   不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不触碰 critical runtime_state.cj。

// Owner-local write realization 只说明 preflight facts 可被收束为 owner-local realization；
// 它不是 process-wide storage write，也不会把 mutable reference 暴露给其他 owner。
struct CjguiInternalQueueOwnerLocalWriteRealization {
    let preflight: CjguiInternalQueueProcessLocalWritePreflight
    let didRealizeQueueOwnerLocalWrite: Bool
    let didKeepQueueOwnerLocalWriteScoped: Bool
    let shouldDeferQueueOwnerLocalWriteRealization: Bool
    let shouldReportQueueOwnerLocalWriteRealizationBlocked: Bool
    let didPreserveQueueProcessLocalWritePreflight: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        preflight: CjguiInternalQueueProcessLocalWritePreflight,
        didRealizeQueueOwnerLocalWrite: Bool,
        didKeepQueueOwnerLocalWriteScoped: Bool,
        shouldDeferQueueOwnerLocalWriteRealization: Bool,
        shouldReportQueueOwnerLocalWriteRealizationBlocked: Bool,
        didPreserveQueueProcessLocalWritePreflight: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.preflight = preflight
        this.didRealizeQueueOwnerLocalWrite = didRealizeQueueOwnerLocalWrite
        this.didKeepQueueOwnerLocalWriteScoped = didKeepQueueOwnerLocalWriteScoped
        this.shouldDeferQueueOwnerLocalWriteRealization = shouldDeferQueueOwnerLocalWriteRealization
        this.shouldReportQueueOwnerLocalWriteRealizationBlocked = shouldReportQueueOwnerLocalWriteRealizationBlocked
        this.didPreserveQueueProcessLocalWritePreflight = didPreserveQueueProcessLocalWritePreflight
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Post-realization holder 只携带 realization 后选择的 immutable snapshot / version facts；
// holder 本身是 value，不是可逃逸的 mutable queue，也不修改真实 item collection。
struct CjguiInternalQueueOwnerLocalPostWriteHolder {
    let realization: CjguiInternalQueueOwnerLocalWriteRealization
    let realizedSnapshot: CjguiInternalQueueStoreSnapshot
    let previousSnapshotFallback: CjguiInternalQueueStoreSnapshot
    let realizedVersion: CjguiInternalQueueStoreVersion
    let didPrepareQueueOwnerLocalPostWriteHolder: Bool
    let shouldDeferQueueOwnerLocalPostWriteHolder: Bool
    let shouldReportQueueOwnerLocalPostWriteHolderBlocked: Bool
    let didPreserveQueueOwnerLocalWriteRealization: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        realization: CjguiInternalQueueOwnerLocalWriteRealization,
        realizedSnapshot: CjguiInternalQueueStoreSnapshot,
        previousSnapshotFallback: CjguiInternalQueueStoreSnapshot,
        realizedVersion: CjguiInternalQueueStoreVersion,
        didPrepareQueueOwnerLocalPostWriteHolder: Bool,
        shouldDeferQueueOwnerLocalPostWriteHolder: Bool,
        shouldReportQueueOwnerLocalPostWriteHolderBlocked: Bool,
        didPreserveQueueOwnerLocalWriteRealization: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.realization = realization
        this.realizedSnapshot = realizedSnapshot
        this.previousSnapshotFallback = previousSnapshotFallback
        this.realizedVersion = realizedVersion
        this.didPrepareQueueOwnerLocalPostWriteHolder = didPrepareQueueOwnerLocalPostWriteHolder
        this.shouldDeferQueueOwnerLocalPostWriteHolder = shouldDeferQueueOwnerLocalPostWriteHolder
        this.shouldReportQueueOwnerLocalPostWriteHolderBlocked = shouldReportQueueOwnerLocalPostWriteHolderBlocked
        this.didPreserveQueueOwnerLocalWriteRealization = didPreserveQueueOwnerLocalWriteRealization
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Owner-local write result 是本轮 canonical endpoint；
// ready 只表示 owner-local realization facts 已收束，不是 public enqueue 或 process-wide storage write。
struct CjguiInternalQueueOwnerLocalWriteResult {
    let postWriteHolder: CjguiInternalQueueOwnerLocalPostWriteHolder
    let isQueueOwnerLocalWriteResultReady: Bool
    let didRealizeQueueOwnerLocalWrite: Bool
    let shouldDeferQueueOwnerLocalWriteResult: Bool
    let shouldReportQueueOwnerLocalWriteResultBlocked: Bool
    let didPreserveQueueOwnerLocalPostWriteHolder: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        postWriteHolder: CjguiInternalQueueOwnerLocalPostWriteHolder,
        isQueueOwnerLocalWriteResultReady: Bool,
        didRealizeQueueOwnerLocalWrite: Bool,
        shouldDeferQueueOwnerLocalWriteResult: Bool,
        shouldReportQueueOwnerLocalWriteResultBlocked: Bool,
        didPreserveQueueOwnerLocalPostWriteHolder: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.postWriteHolder = postWriteHolder
        this.isQueueOwnerLocalWriteResultReady = isQueueOwnerLocalWriteResultReady
        this.didRealizeQueueOwnerLocalWrite = didRealizeQueueOwnerLocalWrite
        this.shouldDeferQueueOwnerLocalWriteResult = shouldDeferQueueOwnerLocalWriteResult
        this.shouldReportQueueOwnerLocalWriteResultBlocked = shouldReportQueueOwnerLocalWriteResultBlocked
        this.didPreserveQueueOwnerLocalPostWriteHolder = didPreserveQueueOwnerLocalPostWriteHolder
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueueOwnerLocalWriteRealization(
    preflight: CjguiInternalQueueProcessLocalWritePreflight
): CjguiInternalQueueOwnerLocalWriteRealization {
    let rollbackAvailability = preflight.rollbackAvailability
    let lifecycle = rollbackAvailability.lifecycle
    let scope = lifecycle.scope
    let preflightReady = preflight.isQueueProcessLocalWritePreflightReady &&
        preflight.hasQueueProcessLocalWriteRealizationCandidate &&
        preflight.didPreserveQueueProcessLocalWriteRollbackAvailability &&
        preflight.didPreservePreviousQueueStoreSnapshot &&
        preflight.shouldDeferQueueProcessLocalWritePreflight == false &&
        preflight.shouldReportQueueProcessLocalWritePreflightBlocked == false &&
        rollbackAvailability.hasQueueProcessLocalWriteRollbackAvailability &&
        rollbackAvailability.didPreserveQueueProcessLocalWriteLifecycle &&
        rollbackAvailability.shouldDeferQueueProcessLocalWriteRollbackAvailability == false &&
        rollbackAvailability.shouldReportQueueProcessLocalWriteRollbackAvailabilityBlocked == false &&
        lifecycle.isQueueProcessLocalWriteLifecycleOpen &&
        lifecycle.didPreserveQueueProcessLocalWriteScope &&
        lifecycle.shouldDeferQueueProcessLocalWriteLifecycle == false &&
        lifecycle.shouldReportQueueProcessLocalWriteLifecycleBlocked == false &&
        scope.isQueueProcessLocalWriteScopeOpen &&
        scope.didPreserveQueueMutableWriteHandoffReceipt &&
        scope.shouldDeferQueueProcessLocalWriteScope == false &&
        scope.shouldReportQueueProcessLocalWriteScopeBlocked == false
    let preflightDeferred = preflight.isQueueProcessLocalWritePreflightReady == false &&
        preflight.hasQueueProcessLocalWriteRealizationCandidate == false &&
        preflight.didPreserveQueueProcessLocalWriteRollbackAvailability == false &&
        preflight.didPreservePreviousQueueStoreSnapshot &&
        preflight.shouldDeferQueueProcessLocalWritePreflight &&
        preflight.shouldReportQueueProcessLocalWritePreflightBlocked == false
    let preflightInconsistent = (
        preflight.isQueueProcessLocalWritePreflightReady &&
            (
                preflight.shouldDeferQueueProcessLocalWritePreflight ||
                preflight.shouldReportQueueProcessLocalWritePreflightBlocked
            )
        ) ||
        (preflight.hasQueueProcessLocalWriteRealizationCandidate &&
            preflight.isQueueProcessLocalWritePreflightReady == false) ||
        (preflight.hasQueueProcessLocalWriteRealizationCandidate == false &&
            preflight.isQueueProcessLocalWritePreflightReady) ||
        (preflight.didPreserveQueueProcessLocalWriteRollbackAvailability &&
            preflight.isQueueProcessLocalWritePreflightReady == false) ||
        (preflight.didPreserveQueueProcessLocalWriteRollbackAvailability == false &&
            preflight.isQueueProcessLocalWritePreflightReady) ||
        (preflight.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            preflight.shouldDeferQueueProcessLocalWritePreflight &&
            preflight.shouldReportQueueProcessLocalWritePreflightBlocked
        ) ||
        (
            preflight.isQueueProcessLocalWritePreflightReady &&
            (
                rollbackAvailability.hasQueueProcessLocalWriteRollbackAvailability == false ||
                lifecycle.isQueueProcessLocalWriteLifecycleOpen == false ||
                scope.isQueueProcessLocalWriteScopeOpen == false
            )
        )

    // preflight / scope / lifecycle / rollback facts 不一致时必须 fail-closed，避免把 preflight 误升级成真实写入。
    if (
        preflight.shouldReportQueueProcessLocalWritePreflightBlocked ||
        preflightInconsistent
    ) {
        return CjguiInternalQueueOwnerLocalWriteRealization(
            preflight,
            false,
            false,
            false,
            true,
            false,
            preflight.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (preflightReady) {
        return CjguiInternalQueueOwnerLocalWriteRealization(preflight, true, true, false, false, true, true)
    }

    if (preflightDeferred) {
        return CjguiInternalQueueOwnerLocalWriteRealization(
            preflight,
            false,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueOwnerLocalWriteRealization(
        preflight,
        false,
        false,
        false,
        true,
        false,
        preflight.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueOwnerLocalPostWriteHolder(
    realization: CjguiInternalQueueOwnerLocalWriteRealization
): CjguiInternalQueueOwnerLocalPostWriteHolder {
    let sourceHolder = realization.preflight.rollbackAvailability.lifecycle.scope.receipt.acceptance.consumer
        .result.postWriteHolder
    let readySnapshot = sourceHolder.postWriteSnapshot
    let fallbackSnapshot = sourceHolder.previousSnapshotFallback
    let realizationReady = realization.didRealizeQueueOwnerLocalWrite &&
        realization.didKeepQueueOwnerLocalWriteScoped &&
        realization.didPreserveQueueProcessLocalWritePreflight &&
        realization.didPreservePreviousQueueStoreSnapshot &&
        realization.shouldDeferQueueOwnerLocalWriteRealization == false &&
        realization.shouldReportQueueOwnerLocalWriteRealizationBlocked == false
    let realizationDeferred = realization.didRealizeQueueOwnerLocalWrite == false &&
        realization.didKeepQueueOwnerLocalWriteScoped == false &&
        realization.didPreserveQueueProcessLocalWritePreflight == false &&
        realization.didPreservePreviousQueueStoreSnapshot &&
        realization.shouldDeferQueueOwnerLocalWriteRealization &&
        realization.shouldReportQueueOwnerLocalWriteRealizationBlocked == false
    let realizationInconsistent = (
        realization.didRealizeQueueOwnerLocalWrite &&
            (
                realization.shouldDeferQueueOwnerLocalWriteRealization ||
                realization.shouldReportQueueOwnerLocalWriteRealizationBlocked
            )
        ) ||
        (realization.didKeepQueueOwnerLocalWriteScoped &&
            realization.didRealizeQueueOwnerLocalWrite == false) ||
        (realization.didKeepQueueOwnerLocalWriteScoped == false &&
            realization.didRealizeQueueOwnerLocalWrite) ||
        (realization.didPreserveQueueProcessLocalWritePreflight &&
            realization.didRealizeQueueOwnerLocalWrite == false) ||
        (realization.didPreserveQueueProcessLocalWritePreflight == false &&
            realization.didRealizeQueueOwnerLocalWrite) ||
        (realization.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            realization.shouldDeferQueueOwnerLocalWriteRealization &&
            realization.shouldReportQueueOwnerLocalWriteRealizationBlocked
        )

    // realization facts 不一致时必须 fail-closed，post-realization holder 只保留 fallback snapshot facts。
    if (
        realization.shouldReportQueueOwnerLocalWriteRealizationBlocked ||
        realizationInconsistent
    ) {
        return CjguiInternalQueueOwnerLocalPostWriteHolder(
            realization,
            fallbackSnapshot,
            fallbackSnapshot,
            fallbackSnapshot.version,
            false,
            false,
            true,
            false,
            realization.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (realizationReady) {
        return CjguiInternalQueueOwnerLocalPostWriteHolder(
            realization,
            readySnapshot,
            fallbackSnapshot,
            readySnapshot.version,
            true,
            false,
            false,
            true,
            true
        )
    }

    if (realizationDeferred) {
        return CjguiInternalQueueOwnerLocalPostWriteHolder(
            realization,
            fallbackSnapshot,
            fallbackSnapshot,
            fallbackSnapshot.version,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueOwnerLocalPostWriteHolder(
        realization,
        fallbackSnapshot,
        fallbackSnapshot,
        fallbackSnapshot.version,
        false,
        false,
        true,
        false,
        realization.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueOwnerLocalWriteResult(
    postWriteHolder: CjguiInternalQueueOwnerLocalPostWriteHolder
): CjguiInternalQueueOwnerLocalWriteResult {
    let holderReady = postWriteHolder.didPrepareQueueOwnerLocalPostWriteHolder &&
        postWriteHolder.didPreserveQueueOwnerLocalWriteRealization &&
        postWriteHolder.didPreservePreviousQueueStoreSnapshot &&
        postWriteHolder.shouldDeferQueueOwnerLocalPostWriteHolder == false &&
        postWriteHolder.shouldReportQueueOwnerLocalPostWriteHolderBlocked == false
    let holderDeferred = postWriteHolder.didPrepareQueueOwnerLocalPostWriteHolder == false &&
        postWriteHolder.didPreserveQueueOwnerLocalWriteRealization == false &&
        postWriteHolder.didPreservePreviousQueueStoreSnapshot &&
        postWriteHolder.shouldDeferQueueOwnerLocalPostWriteHolder &&
        postWriteHolder.shouldReportQueueOwnerLocalPostWriteHolderBlocked == false
    let holderInconsistent = (
        postWriteHolder.didPrepareQueueOwnerLocalPostWriteHolder &&
            (
                postWriteHolder.shouldDeferQueueOwnerLocalPostWriteHolder ||
                postWriteHolder.shouldReportQueueOwnerLocalPostWriteHolderBlocked
            )
        ) ||
        (postWriteHolder.didPreserveQueueOwnerLocalWriteRealization &&
            postWriteHolder.didPrepareQueueOwnerLocalPostWriteHolder == false) ||
        (postWriteHolder.didPreserveQueueOwnerLocalWriteRealization == false &&
            postWriteHolder.didPrepareQueueOwnerLocalPostWriteHolder) ||
        (postWriteHolder.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            postWriteHolder.shouldDeferQueueOwnerLocalPostWriteHolder &&
            postWriteHolder.shouldReportQueueOwnerLocalPostWriteHolderBlocked
        )

    // post-realization holder facts 不一致时必须 fail-closed，write result 不能代表 process-wide storage write。
    if (
        postWriteHolder.shouldReportQueueOwnerLocalPostWriteHolderBlocked ||
        holderInconsistent
    ) {
        return CjguiInternalQueueOwnerLocalWriteResult(
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
        return CjguiInternalQueueOwnerLocalWriteResult(
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
        return CjguiInternalQueueOwnerLocalWriteResult(
            postWriteHolder,
            false,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueOwnerLocalWriteResult(
        postWriteHolder,
        false,
        false,
        false,
        true,
        false,
        postWriteHolder.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueueOwnerLocalWriteDraft(): CjguiInternalQueueOwnerLocalWriteResult {
    // 默认 draft 只串联 owner-local write realization value pipeline，不做 public enqueue 或 process-wide storage write。
    let preflight = cjguiInternalExecuteDefaultQueueProcessLocalWritePreflightDraft()
    let realization = cjguiInternalBuildQueueOwnerLocalWriteRealization(preflight)
    let postWriteHolder = cjguiInternalBuildQueueOwnerLocalPostWriteHolder(realization)
    return cjguiInternalBuildQueueOwnerLocalWriteResult(postWriteHolder)
}

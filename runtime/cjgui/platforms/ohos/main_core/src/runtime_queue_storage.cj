package cjgui

// Internal Queue Storage Model owner:
// - 本文件只消费 QueueEnqueueDryRunReadiness。
// - Truth 是 pending store / storage candidate / commit candidate 的内部 value facts。
// - Stop-line: 不写真实 queue storage、不创建 global mutable queue、不 enqueue、不 drain、
//   不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Queue pending store 只是 dry-run readiness 后形成的 storage-adjacent value fact；
// 它不是实际 queue storage write、enqueue record 或 global mutable queue。
struct CjguiInternalQueuePendingStore {
    let enqueueReadiness: CjguiInternalQueueEnqueueDryRunReadiness
    let didPrepareQueuePendingStore: Bool
    let shouldDeferQueuePendingStore: Bool
    let shouldReportQueuePendingStoreBlocked: Bool
    let didPreserveQueueEnqueueDryRunReadiness: Bool

    init(
        enqueueReadiness: CjguiInternalQueueEnqueueDryRunReadiness,
        didPrepareQueuePendingStore: Bool,
        shouldDeferQueuePendingStore: Bool,
        shouldReportQueuePendingStoreBlocked: Bool,
        didPreserveQueueEnqueueDryRunReadiness: Bool
    ) {
        this.enqueueReadiness = enqueueReadiness
        this.didPrepareQueuePendingStore = didPrepareQueuePendingStore
        this.shouldDeferQueuePendingStore = shouldDeferQueuePendingStore
        this.shouldReportQueuePendingStoreBlocked = shouldReportQueuePendingStoreBlocked
        this.didPreserveQueueEnqueueDryRunReadiness = didPreserveQueueEnqueueDryRunReadiness
    }
}

// Queue storage candidate 只把 pending store 投影为内部 storage candidate；
// candidate 不分配队列存储，也不会触发 enqueue / drain。
struct CjguiInternalQueueStorageCandidate {
    let pendingStore: CjguiInternalQueuePendingStore
    let isQueueStorageCandidateReady: Bool
    let shouldDeferQueueStorageCandidate: Bool
    let shouldReportQueueStorageCandidateBlocked: Bool
    let didPreserveQueuePendingStore: Bool

    init(
        pendingStore: CjguiInternalQueuePendingStore,
        isQueueStorageCandidateReady: Bool,
        shouldDeferQueueStorageCandidate: Bool,
        shouldReportQueueStorageCandidateBlocked: Bool,
        didPreserveQueuePendingStore: Bool
    ) {
        this.pendingStore = pendingStore
        this.isQueueStorageCandidateReady = isQueueStorageCandidateReady
        this.shouldDeferQueueStorageCandidate = shouldDeferQueueStorageCandidate
        this.shouldReportQueueStorageCandidateBlocked = shouldReportQueueStorageCandidateBlocked
        this.didPreserveQueuePendingStore = didPreserveQueuePendingStore
    }
}

// Queue storage commit candidate 是本轮 canonical endpoint；
// commit candidate 只表示 value-style storage facts 已收束，不是真实 queue commit。
struct CjguiInternalQueueStorageCommitCandidate {
    let storageCandidate: CjguiInternalQueueStorageCandidate
    let canCommitQueueStorageCandidate: Bool
    let shouldDeferQueueStorageCommit: Bool
    let shouldReportQueueStorageCommitBlocked: Bool
    let didPreserveQueueStorageCandidate: Bool

    init(
        storageCandidate: CjguiInternalQueueStorageCandidate,
        canCommitQueueStorageCandidate: Bool,
        shouldDeferQueueStorageCommit: Bool,
        shouldReportQueueStorageCommitBlocked: Bool,
        didPreserveQueueStorageCandidate: Bool
    ) {
        this.storageCandidate = storageCandidate
        this.canCommitQueueStorageCandidate = canCommitQueueStorageCandidate
        this.shouldDeferQueueStorageCommit = shouldDeferQueueStorageCommit
        this.shouldReportQueueStorageCommitBlocked = shouldReportQueueStorageCommitBlocked
        this.didPreserveQueueStorageCandidate = didPreserveQueueStorageCandidate
    }
}

func cjguiInternalBuildQueuePendingStore(
    enqueueReadiness: CjguiInternalQueueEnqueueDryRunReadiness
): CjguiInternalQueuePendingStore {
    let dryRunReady = enqueueReadiness.isQueueEnqueueDryRunReady &&
        enqueueReadiness.didPreserveQueueEnqueueShadowCandidate &&
        enqueueReadiness.shouldDeferQueueEnqueueDryRunReadiness == false &&
        enqueueReadiness.shouldReportQueueEnqueueDryRunReadinessBlocked == false
    let dryRunDeferred = enqueueReadiness.isQueueEnqueueDryRunReady == false &&
        enqueueReadiness.didPreserveQueueEnqueueShadowCandidate == false &&
        enqueueReadiness.shouldDeferQueueEnqueueDryRunReadiness &&
        enqueueReadiness.shouldReportQueueEnqueueDryRunReadinessBlocked == false
    let dryRunInconsistent = (
        enqueueReadiness.isQueueEnqueueDryRunReady &&
            (enqueueReadiness.shouldDeferQueueEnqueueDryRunReadiness ||
                enqueueReadiness.shouldReportQueueEnqueueDryRunReadinessBlocked)
        ) ||
        (enqueueReadiness.didPreserveQueueEnqueueShadowCandidate &&
            enqueueReadiness.isQueueEnqueueDryRunReady == false) ||
        (enqueueReadiness.didPreserveQueueEnqueueShadowCandidate == false &&
            enqueueReadiness.isQueueEnqueueDryRunReady) ||
        (enqueueReadiness.shouldDeferQueueEnqueueDryRunReadiness &&
            enqueueReadiness.shouldReportQueueEnqueueDryRunReadinessBlocked)

    // dry-run readiness facts 不一致时必须 fail-closed，避免被误当作真实 queue storage 许可。
    if (
        enqueueReadiness.shouldReportQueueEnqueueDryRunReadinessBlocked ||
        dryRunInconsistent
    ) {
        return CjguiInternalQueuePendingStore(enqueueReadiness, false, false, true, false)
    }

    if (dryRunReady) {
        return CjguiInternalQueuePendingStore(enqueueReadiness, true, false, false, true)
    }

    if (dryRunDeferred) {
        return CjguiInternalQueuePendingStore(enqueueReadiness, false, true, false, false)
    }

    return CjguiInternalQueuePendingStore(enqueueReadiness, false, false, true, false)
}

func cjguiInternalBuildQueueStorageCandidate(
    pendingStore: CjguiInternalQueuePendingStore
): CjguiInternalQueueStorageCandidate {
    let pendingStoreReady = pendingStore.didPrepareQueuePendingStore &&
        pendingStore.didPreserveQueueEnqueueDryRunReadiness &&
        pendingStore.shouldDeferQueuePendingStore == false &&
        pendingStore.shouldReportQueuePendingStoreBlocked == false
    let pendingStoreDeferred = pendingStore.didPrepareQueuePendingStore == false &&
        pendingStore.didPreserveQueueEnqueueDryRunReadiness == false &&
        pendingStore.shouldDeferQueuePendingStore &&
        pendingStore.shouldReportQueuePendingStoreBlocked == false
    let pendingStoreInconsistent = (
        pendingStore.didPrepareQueuePendingStore &&
            (pendingStore.shouldDeferQueuePendingStore ||
                pendingStore.shouldReportQueuePendingStoreBlocked)
        ) ||
        (pendingStore.didPreserveQueueEnqueueDryRunReadiness &&
            pendingStore.didPrepareQueuePendingStore == false) ||
        (pendingStore.didPreserveQueueEnqueueDryRunReadiness == false &&
            pendingStore.didPrepareQueuePendingStore) ||
        (pendingStore.shouldDeferQueuePendingStore &&
            pendingStore.shouldReportQueuePendingStoreBlocked)

    // pending store facts 不一致时必须 fail-closed，candidate 不能伪造成实际 queue storage。
    if (pendingStore.shouldReportQueuePendingStoreBlocked || pendingStoreInconsistent) {
        return CjguiInternalQueueStorageCandidate(pendingStore, false, false, true, false)
    }

    if (pendingStoreReady) {
        return CjguiInternalQueueStorageCandidate(pendingStore, true, false, false, true)
    }

    if (pendingStoreDeferred) {
        return CjguiInternalQueueStorageCandidate(pendingStore, false, true, false, false)
    }

    return CjguiInternalQueueStorageCandidate(pendingStore, false, false, true, false)
}

func cjguiInternalBuildQueueStorageCommitCandidate(
    storageCandidate: CjguiInternalQueueStorageCandidate
): CjguiInternalQueueStorageCommitCandidate {
    let candidateReady = storageCandidate.isQueueStorageCandidateReady &&
        storageCandidate.didPreserveQueuePendingStore &&
        storageCandidate.shouldDeferQueueStorageCandidate == false &&
        storageCandidate.shouldReportQueueStorageCandidateBlocked == false
    let candidateDeferred = storageCandidate.isQueueStorageCandidateReady == false &&
        storageCandidate.didPreserveQueuePendingStore == false &&
        storageCandidate.shouldDeferQueueStorageCandidate &&
        storageCandidate.shouldReportQueueStorageCandidateBlocked == false
    let candidateInconsistent = (
        storageCandidate.isQueueStorageCandidateReady &&
            (storageCandidate.shouldDeferQueueStorageCandidate ||
                storageCandidate.shouldReportQueueStorageCandidateBlocked)
        ) ||
        (storageCandidate.didPreserveQueuePendingStore &&
            storageCandidate.isQueueStorageCandidateReady == false) ||
        (storageCandidate.didPreserveQueuePendingStore == false &&
            storageCandidate.isQueueStorageCandidateReady) ||
        (storageCandidate.shouldDeferQueueStorageCandidate &&
            storageCandidate.shouldReportQueueStorageCandidateBlocked)

    // storage candidate facts 不一致时必须 fail-closed，commit candidate 不能伪造成 queue commit。
    if (
        storageCandidate.shouldReportQueueStorageCandidateBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalQueueStorageCommitCandidate(storageCandidate, false, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalQueueStorageCommitCandidate(storageCandidate, true, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalQueueStorageCommitCandidate(storageCandidate, false, true, false, false)
    }

    return CjguiInternalQueueStorageCommitCandidate(storageCandidate, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueueStorageDraft(): CjguiInternalQueueStorageCommitCandidate {
    // 默认 draft 只串联 storage model value pipeline，不写 queue、不创建全局队列、不 enqueue。
    let enqueueReadiness = cjguiInternalExecuteDefaultQueueEnqueueDryRunDraft()
    let pendingStore = cjguiInternalBuildQueuePendingStore(enqueueReadiness)
    let storageCandidate = cjguiInternalBuildQueueStorageCandidate(pendingStore)
    return cjguiInternalBuildQueueStorageCommitCandidate(storageCandidate)
}

package cjgui

// Internal Queue Mutable Store Shell owner:
// - 本文件只消费 QueueWriteRollbackResult。
// - Truth 是 owner-local mutable store shell / holder / lifecycle / version marker 的内部 value facts。
// - Stop-line: 不写 process-wide queue storage、不创建 global mutable queue / singleton、不 enqueue、不 drain、
//   不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Mutable store lifecycle 只说明 rollback result 是否允许进入 owner-local mutable shell；
// 它不是全局队列生命周期，也不会公开 mutable storage API。
struct CjguiInternalQueueMutableStoreLifecycle {
    let rollbackResult: CjguiInternalQueueWriteRollbackResult
    let isQueueMutableStoreLifecycleOpen: Bool
    let shouldDeferQueueMutableStoreLifecycle: Bool
    let shouldReportQueueMutableStoreLifecycleBlocked: Bool
    let didPreserveQueueWriteRollbackResult: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        rollbackResult: CjguiInternalQueueWriteRollbackResult,
        isQueueMutableStoreLifecycleOpen: Bool,
        shouldDeferQueueMutableStoreLifecycle: Bool,
        shouldReportQueueMutableStoreLifecycleBlocked: Bool,
        didPreserveQueueWriteRollbackResult: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.rollbackResult = rollbackResult
        this.isQueueMutableStoreLifecycleOpen = isQueueMutableStoreLifecycleOpen
        this.shouldDeferQueueMutableStoreLifecycle = shouldDeferQueueMutableStoreLifecycle
        this.shouldReportQueueMutableStoreLifecycleBlocked = shouldReportQueueMutableStoreLifecycleBlocked
        this.didPreserveQueueWriteRollbackResult = didPreserveQueueWriteRollbackResult
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Mutable store holder 只在 owner 内携带 current / fallback snapshot value；
// holder 不是真实 queue item collection，也不会作为跨 owner mutable reference 逃逸。
struct CjguiInternalQueueMutableStoreHolder {
    let lifecycle: CjguiInternalQueueMutableStoreLifecycle
    let currentSnapshot: CjguiInternalQueueStoreSnapshot
    let previousSnapshotFallback: CjguiInternalQueueStoreSnapshot
    let didPrepareOwnerLocalMutableHolder: Bool
    let shouldDeferQueueMutableStoreHolder: Bool
    let shouldReportQueueMutableStoreHolderBlocked: Bool
    let didPreserveQueueMutableStoreLifecycle: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        lifecycle: CjguiInternalQueueMutableStoreLifecycle,
        currentSnapshot: CjguiInternalQueueStoreSnapshot,
        previousSnapshotFallback: CjguiInternalQueueStoreSnapshot,
        didPrepareOwnerLocalMutableHolder: Bool,
        shouldDeferQueueMutableStoreHolder: Bool,
        shouldReportQueueMutableStoreHolderBlocked: Bool,
        didPreserveQueueMutableStoreLifecycle: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.lifecycle = lifecycle
        this.currentSnapshot = currentSnapshot
        this.previousSnapshotFallback = previousSnapshotFallback
        this.didPrepareOwnerLocalMutableHolder = didPrepareOwnerLocalMutableHolder
        this.shouldDeferQueueMutableStoreHolder = shouldDeferQueueMutableStoreHolder
        this.shouldReportQueueMutableStoreHolderBlocked = shouldReportQueueMutableStoreHolderBlocked
        this.didPreserveQueueMutableStoreLifecycle = didPreserveQueueMutableStoreLifecycle
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Mutable store version marker 只记录 shell construction 选中的 immutable version value；
// 它不是全局计数器，也不会写入 process-wide queue storage。
struct CjguiInternalQueueMutableStoreVersionMarker {
    let holder: CjguiInternalQueueMutableStoreHolder
    let version: CjguiInternalQueueStoreVersion
    let isQueueMutableStoreVersionMarkerReady: Bool
    let shouldDeferQueueMutableStoreVersionMarker: Bool
    let shouldReportQueueMutableStoreVersionMarkerBlocked: Bool
    let didPreserveQueueMutableStoreHolder: Bool

    init(
        holder: CjguiInternalQueueMutableStoreHolder,
        version: CjguiInternalQueueStoreVersion,
        isQueueMutableStoreVersionMarkerReady: Bool,
        shouldDeferQueueMutableStoreVersionMarker: Bool,
        shouldReportQueueMutableStoreVersionMarkerBlocked: Bool,
        didPreserveQueueMutableStoreHolder: Bool
    ) {
        this.holder = holder
        this.version = version
        this.isQueueMutableStoreVersionMarkerReady = isQueueMutableStoreVersionMarkerReady
        this.shouldDeferQueueMutableStoreVersionMarker = shouldDeferQueueMutableStoreVersionMarker
        this.shouldReportQueueMutableStoreVersionMarkerBlocked = shouldReportQueueMutableStoreVersionMarkerBlocked
        this.didPreserveQueueMutableStoreHolder = didPreserveQueueMutableStoreHolder
    }
}

// Mutable store shell 是本轮 canonical endpoint；
// ready 只表示 owner-local mutable shell facts 已形成，不是真实全局 queue 或 enqueue 结果。
struct CjguiInternalQueueMutableStoreShell {
    let versionMarker: CjguiInternalQueueMutableStoreVersionMarker
    let isQueueMutableStoreShellReady: Bool
    let shouldDeferQueueMutableStoreShell: Bool
    let shouldReportQueueMutableStoreShellBlocked: Bool
    let didPreserveQueueMutableStoreVersionMarker: Bool
    let didKeepQueueMutableStoreOwnerLocal: Bool

    init(
        versionMarker: CjguiInternalQueueMutableStoreVersionMarker,
        isQueueMutableStoreShellReady: Bool,
        shouldDeferQueueMutableStoreShell: Bool,
        shouldReportQueueMutableStoreShellBlocked: Bool,
        didPreserveQueueMutableStoreVersionMarker: Bool,
        didKeepQueueMutableStoreOwnerLocal: Bool
    ) {
        this.versionMarker = versionMarker
        this.isQueueMutableStoreShellReady = isQueueMutableStoreShellReady
        this.shouldDeferQueueMutableStoreShell = shouldDeferQueueMutableStoreShell
        this.shouldReportQueueMutableStoreShellBlocked = shouldReportQueueMutableStoreShellBlocked
        this.didPreserveQueueMutableStoreVersionMarker = didPreserveQueueMutableStoreVersionMarker
        this.didKeepQueueMutableStoreOwnerLocal = didKeepQueueMutableStoreOwnerLocal
    }
}

func cjguiInternalBuildQueueMutableStoreLifecycle(
    rollbackResult: CjguiInternalQueueWriteRollbackResult
): CjguiInternalQueueMutableStoreLifecycle {
    let resultReady = rollbackResult.isQueueWriteRollbackModelReady &&
        rollbackResult.didRequireQueueWriteRollback == false &&
        rollbackResult.didPreservePreviousQueueStoreSnapshot &&
        rollbackResult.shouldDeferQueueWriteRollbackResult == false &&
        rollbackResult.shouldReportQueueWriteRollbackResultBlocked == false &&
        rollbackResult.didPreserveQueueWriteRollbackPlan
    let resultDeferred = rollbackResult.isQueueWriteRollbackModelReady == false &&
        rollbackResult.didRequireQueueWriteRollback == false &&
        rollbackResult.didPreservePreviousQueueStoreSnapshot &&
        rollbackResult.shouldDeferQueueWriteRollbackResult &&
        rollbackResult.shouldReportQueueWriteRollbackResultBlocked == false &&
        rollbackResult.didPreserveQueueWriteRollbackPlan == false
    let resultInconsistent = (
        rollbackResult.isQueueWriteRollbackModelReady &&
            (rollbackResult.didRequireQueueWriteRollback ||
                rollbackResult.shouldDeferQueueWriteRollbackResult ||
                rollbackResult.shouldReportQueueWriteRollbackResultBlocked)
        ) ||
        (rollbackResult.didPreservePreviousQueueStoreSnapshot == false) ||
        (rollbackResult.didPreserveQueueWriteRollbackPlan &&
            rollbackResult.isQueueWriteRollbackModelReady == false) ||
        (rollbackResult.didPreserveQueueWriteRollbackPlan == false &&
            rollbackResult.isQueueWriteRollbackModelReady) ||
        (rollbackResult.shouldDeferQueueWriteRollbackResult &&
            rollbackResult.shouldReportQueueWriteRollbackResultBlocked)

    // rollback result facts 不一致时必须 fail-closed，避免把 rollback-required path 误当成可写 shell。
    if (
        rollbackResult.shouldReportQueueWriteRollbackResultBlocked ||
        rollbackResult.didRequireQueueWriteRollback ||
        resultInconsistent
    ) {
        return CjguiInternalQueueMutableStoreLifecycle(
            rollbackResult,
            false,
            false,
            true,
            false,
            rollbackResult.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (resultReady) {
        return CjguiInternalQueueMutableStoreLifecycle(rollbackResult, true, false, false, true, true)
    }

    if (resultDeferred) {
        return CjguiInternalQueueMutableStoreLifecycle(rollbackResult, false, true, false, false, true)
    }

    return CjguiInternalQueueMutableStoreLifecycle(
        rollbackResult,
        false,
        false,
        true,
        false,
        rollbackResult.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueMutableStoreHolder(
    lifecycle: CjguiInternalQueueMutableStoreLifecycle
): CjguiInternalQueueMutableStoreHolder {
    let previousSnapshot = lifecycle.rollbackResult.rollbackPlan.previousSnapshotFallback
    let committedSnapshot = lifecycle.rollbackResult.rollbackPlan.policy.publicationCandidate.result.committedStore
        .committedSnapshot
    // 这里的 var 只在 builder 栈帧内选择 holder snapshot，不会逃逸为 module-level/global mutable queue。
    var selectedSnapshot = previousSnapshot
    var didPrepareHolder = false
    let lifecycleReady = lifecycle.isQueueMutableStoreLifecycleOpen &&
        lifecycle.didPreserveQueueWriteRollbackResult &&
        lifecycle.didPreservePreviousQueueStoreSnapshot &&
        lifecycle.shouldDeferQueueMutableStoreLifecycle == false &&
        lifecycle.shouldReportQueueMutableStoreLifecycleBlocked == false
    let lifecycleDeferred = lifecycle.isQueueMutableStoreLifecycleOpen == false &&
        lifecycle.didPreserveQueueWriteRollbackResult == false &&
        lifecycle.didPreservePreviousQueueStoreSnapshot &&
        lifecycle.shouldDeferQueueMutableStoreLifecycle &&
        lifecycle.shouldReportQueueMutableStoreLifecycleBlocked == false
    let lifecycleInconsistent = (
        lifecycle.isQueueMutableStoreLifecycleOpen &&
            (lifecycle.shouldDeferQueueMutableStoreLifecycle ||
                lifecycle.shouldReportQueueMutableStoreLifecycleBlocked)
        ) ||
        (lifecycle.didPreserveQueueWriteRollbackResult &&
            lifecycle.isQueueMutableStoreLifecycleOpen == false) ||
        (lifecycle.didPreserveQueueWriteRollbackResult == false &&
            lifecycle.isQueueMutableStoreLifecycleOpen) ||
        (lifecycle.didPreservePreviousQueueStoreSnapshot == false) ||
        (lifecycle.shouldDeferQueueMutableStoreLifecycle &&
            lifecycle.shouldReportQueueMutableStoreLifecycleBlocked)

    // lifecycle facts 不一致时必须 fail-closed，holder 保留 previous snapshot fallback 而不形成 ready shell。
    if (
        lifecycle.shouldReportQueueMutableStoreLifecycleBlocked ||
        lifecycleInconsistent
    ) {
        return CjguiInternalQueueMutableStoreHolder(
            lifecycle,
            selectedSnapshot,
            previousSnapshot,
            didPrepareHolder,
            false,
            true,
            false,
            lifecycle.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (lifecycleReady) {
        selectedSnapshot = committedSnapshot
        didPrepareHolder = true
        return CjguiInternalQueueMutableStoreHolder(
            lifecycle,
            selectedSnapshot,
            previousSnapshot,
            didPrepareHolder,
            false,
            false,
            true,
            true
        )
    }

    if (lifecycleDeferred) {
        return CjguiInternalQueueMutableStoreHolder(
            lifecycle,
            selectedSnapshot,
            previousSnapshot,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueMutableStoreHolder(
        lifecycle,
        selectedSnapshot,
        previousSnapshot,
        false,
        false,
        true,
        false,
        lifecycle.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueMutableStoreVersionMarker(
    holder: CjguiInternalQueueMutableStoreHolder
): CjguiInternalQueueMutableStoreVersionMarker {
    // 这里的 var 只在 builder 内选择 version marker；版本值随返回的 value 复制，不形成全局计数器。
    var selectedVersion = holder.previousSnapshotFallback.version
    let holderReady = holder.didPrepareOwnerLocalMutableHolder &&
        holder.didPreserveQueueMutableStoreLifecycle &&
        holder.didPreservePreviousQueueStoreSnapshot &&
        holder.shouldDeferQueueMutableStoreHolder == false &&
        holder.shouldReportQueueMutableStoreHolderBlocked == false
    let holderDeferred = holder.didPrepareOwnerLocalMutableHolder == false &&
        holder.didPreserveQueueMutableStoreLifecycle == false &&
        holder.didPreservePreviousQueueStoreSnapshot &&
        holder.shouldDeferQueueMutableStoreHolder &&
        holder.shouldReportQueueMutableStoreHolderBlocked == false
    let holderInconsistent = (
        holder.didPrepareOwnerLocalMutableHolder &&
            (holder.shouldDeferQueueMutableStoreHolder ||
                holder.shouldReportQueueMutableStoreHolderBlocked)
        ) ||
        (holder.didPreserveQueueMutableStoreLifecycle &&
            holder.didPrepareOwnerLocalMutableHolder == false) ||
        (holder.didPreserveQueueMutableStoreLifecycle == false &&
            holder.didPrepareOwnerLocalMutableHolder) ||
        (holder.didPreservePreviousQueueStoreSnapshot == false) ||
        (holder.shouldDeferQueueMutableStoreHolder && holder.shouldReportQueueMutableStoreHolderBlocked)

    // holder facts 不一致时必须 fail-closed，version marker 不能伪造成真实 mutable store 写入。
    if (
        holder.shouldReportQueueMutableStoreHolderBlocked ||
        holderInconsistent
    ) {
        return CjguiInternalQueueMutableStoreVersionMarker(holder, selectedVersion, false, false, true, false)
    }

    if (holderReady) {
        selectedVersion = holder.currentSnapshot.version
        return CjguiInternalQueueMutableStoreVersionMarker(holder, selectedVersion, true, false, false, true)
    }

    if (holderDeferred) {
        return CjguiInternalQueueMutableStoreVersionMarker(holder, selectedVersion, false, true, false, false)
    }

    return CjguiInternalQueueMutableStoreVersionMarker(holder, selectedVersion, false, false, true, false)
}

func cjguiInternalBuildQueueMutableStoreShell(
    versionMarker: CjguiInternalQueueMutableStoreVersionMarker
): CjguiInternalQueueMutableStoreShell {
    let markerReady = versionMarker.isQueueMutableStoreVersionMarkerReady &&
        versionMarker.didPreserveQueueMutableStoreHolder &&
        versionMarker.shouldDeferQueueMutableStoreVersionMarker == false &&
        versionMarker.shouldReportQueueMutableStoreVersionMarkerBlocked == false
    let markerDeferred = versionMarker.isQueueMutableStoreVersionMarkerReady == false &&
        versionMarker.didPreserveQueueMutableStoreHolder == false &&
        versionMarker.shouldDeferQueueMutableStoreVersionMarker &&
        versionMarker.shouldReportQueueMutableStoreVersionMarkerBlocked == false
    let markerInconsistent = (
        versionMarker.isQueueMutableStoreVersionMarkerReady &&
            (versionMarker.shouldDeferQueueMutableStoreVersionMarker ||
                versionMarker.shouldReportQueueMutableStoreVersionMarkerBlocked)
        ) ||
        (versionMarker.didPreserveQueueMutableStoreHolder &&
            versionMarker.isQueueMutableStoreVersionMarkerReady == false) ||
        (versionMarker.didPreserveQueueMutableStoreHolder == false &&
            versionMarker.isQueueMutableStoreVersionMarkerReady) ||
        (versionMarker.shouldDeferQueueMutableStoreVersionMarker &&
            versionMarker.shouldReportQueueMutableStoreVersionMarkerBlocked)

    // version marker facts 不一致时必须 fail-closed，shell 仍保持 owner-local 且不执行真实 storage write。
    if (
        versionMarker.shouldReportQueueMutableStoreVersionMarkerBlocked ||
        markerInconsistent
    ) {
        return CjguiInternalQueueMutableStoreShell(versionMarker, false, false, true, false, true)
    }

    if (markerReady) {
        return CjguiInternalQueueMutableStoreShell(versionMarker, true, false, false, true, true)
    }

    if (markerDeferred) {
        return CjguiInternalQueueMutableStoreShell(versionMarker, false, true, false, false, true)
    }

    return CjguiInternalQueueMutableStoreShell(versionMarker, false, false, true, false, true)
}

func cjguiInternalExecuteDefaultQueueMutableStoreShellDraft(): CjguiInternalQueueMutableStoreShell {
    // 默认 draft 只串联 rollback -> mutable store shell value pipeline，不写全局队列、不 enqueue、不 drain。
    let rollbackResult = cjguiInternalExecuteDefaultQueueWriteRollbackDraft()
    let lifecycle = cjguiInternalBuildQueueMutableStoreLifecycle(rollbackResult)
    let holder = cjguiInternalBuildQueueMutableStoreHolder(lifecycle)
    let versionMarker = cjguiInternalBuildQueueMutableStoreVersionMarker(holder)
    return cjguiInternalBuildQueueMutableStoreShell(versionMarker)
}

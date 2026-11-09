package cjgui

// Internal Queue Process-Local Write Preflight owner:
// - 本文件只消费 QueueMutableWriteHandoffReceipt。
// - Truth 是 process-local write scope / lifecycle / rollback availability / preflight 的内部 value facts。
// - Stop-line: 不做真实 queue item collection mutation、不写 process-wide queue storage、不创建 global mutable queue / singleton、
//   不公开 public API / C ABI、不 enqueue、不 drain、不接 event loop / scheduler / platform callback、不调用 runtime cycle，
//   也不触碰 critical runtime_state.cj。

// Process-local write scope 只描述未来 owner-local 写入可被审计的作用域；
// 它不是实际 mutable write，也不是跨 owner 的可变引用。
struct CjguiInternalQueueProcessLocalWriteScope {
    let receipt: CjguiInternalQueueMutableWriteHandoffReceipt
    let isQueueProcessLocalWriteScopeOpen: Bool
    let shouldDeferQueueProcessLocalWriteScope: Bool
    let shouldReportQueueProcessLocalWriteScopeBlocked: Bool
    let didPreserveQueueMutableWriteHandoffReceipt: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        receipt: CjguiInternalQueueMutableWriteHandoffReceipt,
        isQueueProcessLocalWriteScopeOpen: Bool,
        shouldDeferQueueProcessLocalWriteScope: Bool,
        shouldReportQueueProcessLocalWriteScopeBlocked: Bool,
        didPreserveQueueMutableWriteHandoffReceipt: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.receipt = receipt
        this.isQueueProcessLocalWriteScopeOpen = isQueueProcessLocalWriteScopeOpen
        this.shouldDeferQueueProcessLocalWriteScope = shouldDeferQueueProcessLocalWriteScope
        this.shouldReportQueueProcessLocalWriteScopeBlocked = shouldReportQueueProcessLocalWriteScopeBlocked
        this.didPreserveQueueMutableWriteHandoffReceipt = didPreserveQueueMutableWriteHandoffReceipt
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Process-local write lifecycle 只固定 preflight 阶段的 owner-local 生命周期事实；
// 它不启动 runtime cycle，也不创建 process-wide queue lifecycle。
struct CjguiInternalQueueProcessLocalWriteLifecycle {
    let scope: CjguiInternalQueueProcessLocalWriteScope
    let isQueueProcessLocalWriteLifecycleOpen: Bool
    let shouldDeferQueueProcessLocalWriteLifecycle: Bool
    let shouldReportQueueProcessLocalWriteLifecycleBlocked: Bool
    let didPreserveQueueProcessLocalWriteScope: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        scope: CjguiInternalQueueProcessLocalWriteScope,
        isQueueProcessLocalWriteLifecycleOpen: Bool,
        shouldDeferQueueProcessLocalWriteLifecycle: Bool,
        shouldReportQueueProcessLocalWriteLifecycleBlocked: Bool,
        didPreserveQueueProcessLocalWriteScope: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.scope = scope
        this.isQueueProcessLocalWriteLifecycleOpen = isQueueProcessLocalWriteLifecycleOpen
        this.shouldDeferQueueProcessLocalWriteLifecycle = shouldDeferQueueProcessLocalWriteLifecycle
        this.shouldReportQueueProcessLocalWriteLifecycleBlocked = shouldReportQueueProcessLocalWriteLifecycleBlocked
        this.didPreserveQueueProcessLocalWriteScope = didPreserveQueueProcessLocalWriteScope
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Rollback availability 只表达未来 process-local write 具备 rollback facts；
// 它不是实际回滚副作用，也不恢复 runtime global state。
struct CjguiInternalQueueProcessLocalWriteRollbackAvailability {
    let lifecycle: CjguiInternalQueueProcessLocalWriteLifecycle
    let hasQueueProcessLocalWriteRollbackAvailability: Bool
    let shouldDeferQueueProcessLocalWriteRollbackAvailability: Bool
    let shouldReportQueueProcessLocalWriteRollbackAvailabilityBlocked: Bool
    let didPreserveQueueProcessLocalWriteLifecycle: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        lifecycle: CjguiInternalQueueProcessLocalWriteLifecycle,
        hasQueueProcessLocalWriteRollbackAvailability: Bool,
        shouldDeferQueueProcessLocalWriteRollbackAvailability: Bool,
        shouldReportQueueProcessLocalWriteRollbackAvailabilityBlocked: Bool,
        didPreserveQueueProcessLocalWriteLifecycle: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.lifecycle = lifecycle
        this.hasQueueProcessLocalWriteRollbackAvailability = hasQueueProcessLocalWriteRollbackAvailability
        this.shouldDeferQueueProcessLocalWriteRollbackAvailability =
            shouldDeferQueueProcessLocalWriteRollbackAvailability
        this.shouldReportQueueProcessLocalWriteRollbackAvailabilityBlocked =
            shouldReportQueueProcessLocalWriteRollbackAvailabilityBlocked
        this.didPreserveQueueProcessLocalWriteLifecycle = didPreserveQueueProcessLocalWriteLifecycle
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Process-local write preflight 是本轮 canonical endpoint；
// realization candidate 仍只是 value fact，不是真实 item collection mutation 或 process-wide storage write。
struct CjguiInternalQueueProcessLocalWritePreflight {
    let rollbackAvailability: CjguiInternalQueueProcessLocalWriteRollbackAvailability
    let isQueueProcessLocalWritePreflightReady: Bool
    let hasQueueProcessLocalWriteRealizationCandidate: Bool
    let shouldDeferQueueProcessLocalWritePreflight: Bool
    let shouldReportQueueProcessLocalWritePreflightBlocked: Bool
    let didPreserveQueueProcessLocalWriteRollbackAvailability: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        rollbackAvailability: CjguiInternalQueueProcessLocalWriteRollbackAvailability,
        isQueueProcessLocalWritePreflightReady: Bool,
        hasQueueProcessLocalWriteRealizationCandidate: Bool,
        shouldDeferQueueProcessLocalWritePreflight: Bool,
        shouldReportQueueProcessLocalWritePreflightBlocked: Bool,
        didPreserveQueueProcessLocalWriteRollbackAvailability: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.rollbackAvailability = rollbackAvailability
        this.isQueueProcessLocalWritePreflightReady = isQueueProcessLocalWritePreflightReady
        this.hasQueueProcessLocalWriteRealizationCandidate = hasQueueProcessLocalWriteRealizationCandidate
        this.shouldDeferQueueProcessLocalWritePreflight = shouldDeferQueueProcessLocalWritePreflight
        this.shouldReportQueueProcessLocalWritePreflightBlocked = shouldReportQueueProcessLocalWritePreflightBlocked
        this.didPreserveQueueProcessLocalWriteRollbackAvailability =
            didPreserveQueueProcessLocalWriteRollbackAvailability
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueueProcessLocalWriteScope(
    receipt: CjguiInternalQueueMutableWriteHandoffReceipt
): CjguiInternalQueueProcessLocalWriteScope {
    let receiptReady = receipt.didRecordQueueMutableWriteHandoffReceipt &&
        receipt.didPreserveQueueMutableWriteHandoffAcceptance &&
        receipt.didPreservePreviousQueueStoreSnapshot &&
        receipt.shouldDeferQueueMutableWriteHandoffReceipt == false &&
        receipt.shouldReportQueueMutableWriteHandoffReceiptBlocked == false
    let receiptDeferred = receipt.didRecordQueueMutableWriteHandoffReceipt == false &&
        receipt.didPreserveQueueMutableWriteHandoffAcceptance == false &&
        receipt.didPreservePreviousQueueStoreSnapshot &&
        receipt.shouldDeferQueueMutableWriteHandoffReceipt &&
        receipt.shouldReportQueueMutableWriteHandoffReceiptBlocked == false
    let receiptInconsistent = (
        receipt.didRecordQueueMutableWriteHandoffReceipt &&
            (
                receipt.shouldDeferQueueMutableWriteHandoffReceipt ||
                receipt.shouldReportQueueMutableWriteHandoffReceiptBlocked
            )
        ) ||
        (receipt.didPreserveQueueMutableWriteHandoffAcceptance &&
            receipt.didRecordQueueMutableWriteHandoffReceipt == false) ||
        (receipt.didPreserveQueueMutableWriteHandoffAcceptance == false &&
            receipt.didRecordQueueMutableWriteHandoffReceipt) ||
        (receipt.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            receipt.shouldDeferQueueMutableWriteHandoffReceipt &&
            receipt.shouldReportQueueMutableWriteHandoffReceiptBlocked
        )

    // handoff receipt 不一致时必须 fail-closed，避免把内部 receipt 误升级成可写作用域。
    if (
        receipt.shouldReportQueueMutableWriteHandoffReceiptBlocked ||
        receiptInconsistent
    ) {
        return CjguiInternalQueueProcessLocalWriteScope(
            receipt,
            false,
            false,
            true,
            false,
            receipt.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (receiptReady) {
        return CjguiInternalQueueProcessLocalWriteScope(receipt, true, false, false, true, true)
    }

    if (receiptDeferred) {
        return CjguiInternalQueueProcessLocalWriteScope(
            receipt,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueProcessLocalWriteScope(
        receipt,
        false,
        false,
        true,
        false,
        receipt.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueProcessLocalWriteLifecycle(
    scope: CjguiInternalQueueProcessLocalWriteScope
): CjguiInternalQueueProcessLocalWriteLifecycle {
    let scopeReady = scope.isQueueProcessLocalWriteScopeOpen &&
        scope.didPreserveQueueMutableWriteHandoffReceipt &&
        scope.didPreservePreviousQueueStoreSnapshot &&
        scope.shouldDeferQueueProcessLocalWriteScope == false &&
        scope.shouldReportQueueProcessLocalWriteScopeBlocked == false
    let scopeDeferred = scope.isQueueProcessLocalWriteScopeOpen == false &&
        scope.didPreserveQueueMutableWriteHandoffReceipt == false &&
        scope.didPreservePreviousQueueStoreSnapshot &&
        scope.shouldDeferQueueProcessLocalWriteScope &&
        scope.shouldReportQueueProcessLocalWriteScopeBlocked == false
    let scopeInconsistent = (
        scope.isQueueProcessLocalWriteScopeOpen &&
            (
                scope.shouldDeferQueueProcessLocalWriteScope ||
                scope.shouldReportQueueProcessLocalWriteScopeBlocked
            )
        ) ||
        (scope.didPreserveQueueMutableWriteHandoffReceipt &&
            scope.isQueueProcessLocalWriteScopeOpen == false) ||
        (scope.didPreserveQueueMutableWriteHandoffReceipt == false &&
            scope.isQueueProcessLocalWriteScopeOpen) ||
        (scope.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            scope.shouldDeferQueueProcessLocalWriteScope &&
            scope.shouldReportQueueProcessLocalWriteScopeBlocked
        )

    // scope facts 不一致时必须 fail-closed，lifecycle 不能成为真实 runtime lifecycle 入口。
    if (
        scope.shouldReportQueueProcessLocalWriteScopeBlocked ||
        scopeInconsistent
    ) {
        return CjguiInternalQueueProcessLocalWriteLifecycle(
            scope,
            false,
            false,
            true,
            false,
            scope.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (scopeReady) {
        return CjguiInternalQueueProcessLocalWriteLifecycle(scope, true, false, false, true, true)
    }

    if (scopeDeferred) {
        return CjguiInternalQueueProcessLocalWriteLifecycle(
            scope,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueProcessLocalWriteLifecycle(
        scope,
        false,
        false,
        true,
        false,
        scope.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueProcessLocalWriteRollbackAvailability(
    lifecycle: CjguiInternalQueueProcessLocalWriteLifecycle
): CjguiInternalQueueProcessLocalWriteRollbackAvailability {
    let lifecycleReady = lifecycle.isQueueProcessLocalWriteLifecycleOpen &&
        lifecycle.didPreserveQueueProcessLocalWriteScope &&
        lifecycle.didPreservePreviousQueueStoreSnapshot &&
        lifecycle.shouldDeferQueueProcessLocalWriteLifecycle == false &&
        lifecycle.shouldReportQueueProcessLocalWriteLifecycleBlocked == false
    let lifecycleDeferred = lifecycle.isQueueProcessLocalWriteLifecycleOpen == false &&
        lifecycle.didPreserveQueueProcessLocalWriteScope == false &&
        lifecycle.didPreservePreviousQueueStoreSnapshot &&
        lifecycle.shouldDeferQueueProcessLocalWriteLifecycle &&
        lifecycle.shouldReportQueueProcessLocalWriteLifecycleBlocked == false
    let lifecycleInconsistent = (
        lifecycle.isQueueProcessLocalWriteLifecycleOpen &&
            (
                lifecycle.shouldDeferQueueProcessLocalWriteLifecycle ||
                lifecycle.shouldReportQueueProcessLocalWriteLifecycleBlocked
            )
        ) ||
        (lifecycle.didPreserveQueueProcessLocalWriteScope &&
            lifecycle.isQueueProcessLocalWriteLifecycleOpen == false) ||
        (lifecycle.didPreserveQueueProcessLocalWriteScope == false &&
            lifecycle.isQueueProcessLocalWriteLifecycleOpen) ||
        (lifecycle.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            lifecycle.shouldDeferQueueProcessLocalWriteLifecycle &&
            lifecycle.shouldReportQueueProcessLocalWriteLifecycleBlocked
        )

    // lifecycle facts 不一致时必须 fail-closed，rollback availability 不能伪造成可执行恢复能力。
    if (
        lifecycle.shouldReportQueueProcessLocalWriteLifecycleBlocked ||
        lifecycleInconsistent
    ) {
        return CjguiInternalQueueProcessLocalWriteRollbackAvailability(
            lifecycle,
            false,
            false,
            true,
            false,
            lifecycle.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (lifecycleReady) {
        return CjguiInternalQueueProcessLocalWriteRollbackAvailability(
            lifecycle,
            true,
            false,
            false,
            true,
            true
        )
    }

    if (lifecycleDeferred) {
        return CjguiInternalQueueProcessLocalWriteRollbackAvailability(
            lifecycle,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueProcessLocalWriteRollbackAvailability(
        lifecycle,
        false,
        false,
        true,
        false,
        lifecycle.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueProcessLocalWritePreflight(
    rollbackAvailability: CjguiInternalQueueProcessLocalWriteRollbackAvailability
): CjguiInternalQueueProcessLocalWritePreflight {
    let rollbackReady = rollbackAvailability.hasQueueProcessLocalWriteRollbackAvailability &&
        rollbackAvailability.didPreserveQueueProcessLocalWriteLifecycle &&
        rollbackAvailability.didPreservePreviousQueueStoreSnapshot &&
        rollbackAvailability.shouldDeferQueueProcessLocalWriteRollbackAvailability == false &&
        rollbackAvailability.shouldReportQueueProcessLocalWriteRollbackAvailabilityBlocked == false
    let rollbackDeferred = rollbackAvailability.hasQueueProcessLocalWriteRollbackAvailability == false &&
        rollbackAvailability.didPreserveQueueProcessLocalWriteLifecycle == false &&
        rollbackAvailability.didPreservePreviousQueueStoreSnapshot &&
        rollbackAvailability.shouldDeferQueueProcessLocalWriteRollbackAvailability &&
        rollbackAvailability.shouldReportQueueProcessLocalWriteRollbackAvailabilityBlocked == false
    let rollbackInconsistent = (
        rollbackAvailability.hasQueueProcessLocalWriteRollbackAvailability &&
            (
                rollbackAvailability.shouldDeferQueueProcessLocalWriteRollbackAvailability ||
                rollbackAvailability.shouldReportQueueProcessLocalWriteRollbackAvailabilityBlocked
            )
        ) ||
        (rollbackAvailability.didPreserveQueueProcessLocalWriteLifecycle &&
            rollbackAvailability.hasQueueProcessLocalWriteRollbackAvailability == false) ||
        (rollbackAvailability.didPreserveQueueProcessLocalWriteLifecycle == false &&
            rollbackAvailability.hasQueueProcessLocalWriteRollbackAvailability) ||
        (rollbackAvailability.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            rollbackAvailability.shouldDeferQueueProcessLocalWriteRollbackAvailability &&
            rollbackAvailability.shouldReportQueueProcessLocalWriteRollbackAvailabilityBlocked
        )

    // rollback availability 不一致时必须 fail-closed，preflight 不能越权形成真实写入候选。
    if (
        rollbackAvailability.shouldReportQueueProcessLocalWriteRollbackAvailabilityBlocked ||
        rollbackInconsistent
    ) {
        return CjguiInternalQueueProcessLocalWritePreflight(
            rollbackAvailability,
            false,
            false,
            false,
            true,
            false,
            rollbackAvailability.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (rollbackReady) {
        return CjguiInternalQueueProcessLocalWritePreflight(
            rollbackAvailability,
            true,
            true,
            false,
            false,
            true,
            true
        )
    }

    if (rollbackDeferred) {
        return CjguiInternalQueueProcessLocalWritePreflight(
            rollbackAvailability,
            false,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueProcessLocalWritePreflight(
        rollbackAvailability,
        false,
        false,
        false,
        true,
        false,
        rollbackAvailability.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueueProcessLocalWritePreflightDraft(): CjguiInternalQueueProcessLocalWritePreflight {
    // 默认 draft 只串联 process-local write preflight value pipeline，不做真实队列写入或 item collection mutation。
    let receipt = cjguiInternalExecuteDefaultQueueMutableWriteHandoffDraft()
    let scope = cjguiInternalBuildQueueProcessLocalWriteScope(receipt)
    let lifecycle = cjguiInternalBuildQueueProcessLocalWriteLifecycle(scope)
    let rollbackAvailability = cjguiInternalBuildQueueProcessLocalWriteRollbackAvailability(lifecycle)
    return cjguiInternalBuildQueueProcessLocalWritePreflight(rollbackAvailability)
}

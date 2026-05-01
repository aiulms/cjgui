package cjgui

// Internal Queue Staging owner:
// - 本文件只消费 QueuePermissionReadiness。
// - Truth 是 staged queue item / staging candidate / staging readiness 的内部 value facts。
// - Stop-line: 不写 queue storage、不 enqueue、不 drain、不执行 action、不接 event loop /
//   scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Queue staged item 只是 permission readiness 后形成的 staged value fact；
// 它不是实际 queue item storage、enqueue record 或 drain plan。
struct CjguiInternalQueueStagedItem {
    let permissionReadiness: CjguiInternalQueuePermissionReadiness
    let isQueueStagedItemPresent: Bool
    let shouldDeferQueueStagedItem: Bool
    let shouldReportQueueStagedItemBlocked: Bool
    let didPreserveQueuePermissionReadiness: Bool

    init(
        permissionReadiness: CjguiInternalQueuePermissionReadiness,
        isQueueStagedItemPresent: Bool,
        shouldDeferQueueStagedItem: Bool,
        shouldReportQueueStagedItemBlocked: Bool,
        didPreserveQueuePermissionReadiness: Bool
    ) {
        this.permissionReadiness = permissionReadiness
        this.isQueueStagedItemPresent = isQueueStagedItemPresent
        this.shouldDeferQueueStagedItem = shouldDeferQueueStagedItem
        this.shouldReportQueueStagedItemBlocked = shouldReportQueueStagedItemBlocked
        this.didPreserveQueuePermissionReadiness = didPreserveQueuePermissionReadiness
    }
}

// Queue staging candidate 只确认 staged item 可作为内部 staging candidate；
// 它不写入 queue，也不表示 enqueue side effect 已发生。
struct CjguiInternalQueueStagingCandidate {
    let stagedItem: CjguiInternalQueueStagedItem
    let isQueueStagingCandidateReady: Bool
    let shouldDeferQueueStagingCandidate: Bool
    let shouldReportQueueStagingCandidateBlocked: Bool
    let didPreserveQueueStagedItem: Bool

    init(
        stagedItem: CjguiInternalQueueStagedItem,
        isQueueStagingCandidateReady: Bool,
        shouldDeferQueueStagingCandidate: Bool,
        shouldReportQueueStagingCandidateBlocked: Bool,
        didPreserveQueueStagedItem: Bool
    ) {
        this.stagedItem = stagedItem
        this.isQueueStagingCandidateReady = isQueueStagingCandidateReady
        this.shouldDeferQueueStagingCandidate = shouldDeferQueueStagingCandidate
        this.shouldReportQueueStagingCandidateBlocked = shouldReportQueueStagingCandidateBlocked
        this.didPreserveQueueStagedItem = didPreserveQueueStagedItem
    }
}

// Queue staging readiness 是本轮 canonical endpoint；
// ready 只表示 staging value facts 已形成，不是 queue storage 或 enqueue。
struct CjguiInternalQueueStagingReadiness {
    let candidate: CjguiInternalQueueStagingCandidate
    let isQueueStagingReady: Bool
    let shouldDeferQueueStagingReadiness: Bool
    let shouldReportQueueStagingReadinessBlocked: Bool
    let didPreserveQueueStagingCandidate: Bool

    init(
        candidate: CjguiInternalQueueStagingCandidate,
        isQueueStagingReady: Bool,
        shouldDeferQueueStagingReadiness: Bool,
        shouldReportQueueStagingReadinessBlocked: Bool,
        didPreserveQueueStagingCandidate: Bool
    ) {
        this.candidate = candidate
        this.isQueueStagingReady = isQueueStagingReady
        this.shouldDeferQueueStagingReadiness = shouldDeferQueueStagingReadiness
        this.shouldReportQueueStagingReadinessBlocked = shouldReportQueueStagingReadinessBlocked
        this.didPreserveQueueStagingCandidate = didPreserveQueueStagingCandidate
    }
}

func cjguiInternalBuildQueueStagedItem(
    permissionReadiness: CjguiInternalQueuePermissionReadiness
): CjguiInternalQueueStagedItem {
    let permissionReady = permissionReadiness.isQueuePermissionReady &&
        permissionReadiness.didPreserveQueuePermissionGate &&
        permissionReadiness.shouldDeferQueuePermissionReadiness == false &&
        permissionReadiness.shouldReportQueuePermissionReadinessBlocked == false
    let permissionDeferred = permissionReadiness.isQueuePermissionReady == false &&
        permissionReadiness.didPreserveQueuePermissionGate == false &&
        permissionReadiness.shouldDeferQueuePermissionReadiness &&
        permissionReadiness.shouldReportQueuePermissionReadinessBlocked == false
    let permissionInconsistent = (
        permissionReadiness.isQueuePermissionReady &&
            (permissionReadiness.shouldDeferQueuePermissionReadiness ||
                permissionReadiness.shouldReportQueuePermissionReadinessBlocked)
        ) ||
        (permissionReadiness.didPreserveQueuePermissionGate &&
            permissionReadiness.isQueuePermissionReady == false) ||
        (permissionReadiness.didPreserveQueuePermissionGate == false &&
            permissionReadiness.isQueuePermissionReady) ||
        (permissionReadiness.shouldDeferQueuePermissionReadiness &&
            permissionReadiness.shouldReportQueuePermissionReadinessBlocked)

    // permission readiness facts 不一致时必须 fail-closed，避免把 readiness 误当作 staged queue item。
    if (
        permissionReadiness.shouldReportQueuePermissionReadinessBlocked ||
        permissionInconsistent
    ) {
        return CjguiInternalQueueStagedItem(permissionReadiness, false, false, true, false)
    }

    if (permissionReady) {
        return CjguiInternalQueueStagedItem(permissionReadiness, true, false, false, true)
    }

    if (permissionDeferred) {
        return CjguiInternalQueueStagedItem(permissionReadiness, false, true, false, false)
    }

    return CjguiInternalQueueStagedItem(permissionReadiness, false, false, true, false)
}

func cjguiInternalBuildQueueStagingCandidate(
    stagedItem: CjguiInternalQueueStagedItem
): CjguiInternalQueueStagingCandidate {
    let stagedItemReady = stagedItem.isQueueStagedItemPresent &&
        stagedItem.didPreserveQueuePermissionReadiness &&
        stagedItem.shouldDeferQueueStagedItem == false &&
        stagedItem.shouldReportQueueStagedItemBlocked == false
    let stagedItemDeferred = stagedItem.isQueueStagedItemPresent == false &&
        stagedItem.didPreserveQueuePermissionReadiness == false &&
        stagedItem.shouldDeferQueueStagedItem &&
        stagedItem.shouldReportQueueStagedItemBlocked == false
    let stagedItemInconsistent = (
        stagedItem.isQueueStagedItemPresent &&
            (stagedItem.shouldDeferQueueStagedItem ||
                stagedItem.shouldReportQueueStagedItemBlocked)
        ) ||
        (stagedItem.didPreserveQueuePermissionReadiness &&
            stagedItem.isQueueStagedItemPresent == false) ||
        (stagedItem.didPreserveQueuePermissionReadiness == false &&
            stagedItem.isQueueStagedItemPresent) ||
        (stagedItem.shouldDeferQueueStagedItem &&
            stagedItem.shouldReportQueueStagedItemBlocked)

    // staged item facts 不一致时必须 fail-closed，candidate 不能被误读为实际 queue item。
    if (stagedItem.shouldReportQueueStagedItemBlocked || stagedItemInconsistent) {
        return CjguiInternalQueueStagingCandidate(stagedItem, false, false, true, false)
    }

    if (stagedItemReady) {
        return CjguiInternalQueueStagingCandidate(stagedItem, true, false, false, true)
    }

    if (stagedItemDeferred) {
        return CjguiInternalQueueStagingCandidate(stagedItem, false, true, false, false)
    }

    return CjguiInternalQueueStagingCandidate(stagedItem, false, false, true, false)
}

func cjguiInternalBuildQueueStagingReadiness(
    candidate: CjguiInternalQueueStagingCandidate
): CjguiInternalQueueStagingReadiness {
    let candidateReady = candidate.isQueueStagingCandidateReady &&
        candidate.didPreserveQueueStagedItem &&
        candidate.shouldDeferQueueStagingCandidate == false &&
        candidate.shouldReportQueueStagingCandidateBlocked == false
    let candidateDeferred = candidate.isQueueStagingCandidateReady == false &&
        candidate.didPreserveQueueStagedItem == false &&
        candidate.shouldDeferQueueStagingCandidate &&
        candidate.shouldReportQueueStagingCandidateBlocked == false
    let candidateInconsistent = (
        candidate.isQueueStagingCandidateReady &&
            (candidate.shouldDeferQueueStagingCandidate ||
                candidate.shouldReportQueueStagingCandidateBlocked)
        ) ||
        (candidate.didPreserveQueueStagedItem &&
            candidate.isQueueStagingCandidateReady == false) ||
        (candidate.didPreserveQueueStagedItem == false &&
            candidate.isQueueStagingCandidateReady) ||
        (candidate.shouldDeferQueueStagingCandidate &&
            candidate.shouldReportQueueStagingCandidateBlocked)

    // staging candidate facts 不一致时必须 fail-closed，readiness 不能伪造成 enqueue readiness。
    if (candidate.shouldReportQueueStagingCandidateBlocked || candidateInconsistent) {
        return CjguiInternalQueueStagingReadiness(candidate, false, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalQueueStagingReadiness(candidate, true, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalQueueStagingReadiness(candidate, false, true, false, false)
    }

    return CjguiInternalQueueStagingReadiness(candidate, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueueStagingDraft(): CjguiInternalQueueStagingReadiness {
    // 默认 draft 只串联 queue staging value pipeline，不写 queue、不 enqueue、不 drain。
    let permissionReadiness = cjguiInternalExecuteDefaultQueuePermissionDraft()
    let stagedItem = cjguiInternalBuildQueueStagedItem(permissionReadiness)
    let candidate = cjguiInternalBuildQueueStagingCandidate(stagedItem)
    return cjguiInternalBuildQueueStagingReadiness(candidate)
}

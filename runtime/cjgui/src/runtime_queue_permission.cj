package cjgui

// Internal Queue Permission owner:
// - 本文件只消费 QueueHandoffGate。
// - Truth 是 enqueue 前 permission / policy / readiness 的内部 value facts。
// - Stop-line: 不写 queue storage、不 enqueue、不 drain、不执行 action、不接 event loop /
//   scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Queue permission policy 只是 enqueue 前的本地 policy fact；
// 它不是 queue config、enqueue 授权 side effect 或 scheduler 配置。
struct CjguiInternalQueuePermissionPolicy {
    let allowsQueuePermission: Bool
    let allowsDeferredQueuePermission: Bool

    init(allowsQueuePermission: Bool, allowsDeferredQueuePermission: Bool) {
        this.allowsQueuePermission = allowsQueuePermission
        this.allowsDeferredQueuePermission = allowsDeferredQueuePermission
    }
}

// Queue permission gate 只把 queue handoff gate 投影为 enqueue 前 permission facts；
// gate open 不是 queue storage write，也不是 enqueue side effect。
struct CjguiInternalQueuePermissionGate {
    let handoffGate: CjguiInternalQueueHandoffGate
    let policy: CjguiInternalQueuePermissionPolicy
    let canEnterQueuePermissionGate: Bool
    let shouldDeferQueuePermissionGate: Bool
    let shouldReportQueuePermissionBlocked: Bool
    let didPreserveQueueHandoffGate: Bool

    init(
        handoffGate: CjguiInternalQueueHandoffGate,
        policy: CjguiInternalQueuePermissionPolicy,
        canEnterQueuePermissionGate: Bool,
        shouldDeferQueuePermissionGate: Bool,
        shouldReportQueuePermissionBlocked: Bool,
        didPreserveQueueHandoffGate: Bool
    ) {
        this.handoffGate = handoffGate
        this.policy = policy
        this.canEnterQueuePermissionGate = canEnterQueuePermissionGate
        this.shouldDeferQueuePermissionGate = shouldDeferQueuePermissionGate
        this.shouldReportQueuePermissionBlocked = shouldReportQueuePermissionBlocked
        this.didPreserveQueueHandoffGate = didPreserveQueueHandoffGate
    }
}

// Queue permission readiness 是本轮 canonical endpoint；
// ready 只表示 enqueue 前 permission facts 已形成，不是实际 enqueue。
struct CjguiInternalQueuePermissionReadiness {
    let permissionGate: CjguiInternalQueuePermissionGate
    let isQueuePermissionReady: Bool
    let shouldDeferQueuePermissionReadiness: Bool
    let shouldReportQueuePermissionReadinessBlocked: Bool
    let didPreserveQueuePermissionGate: Bool

    init(
        permissionGate: CjguiInternalQueuePermissionGate,
        isQueuePermissionReady: Bool,
        shouldDeferQueuePermissionReadiness: Bool,
        shouldReportQueuePermissionReadinessBlocked: Bool,
        didPreserveQueuePermissionGate: Bool
    ) {
        this.permissionGate = permissionGate
        this.isQueuePermissionReady = isQueuePermissionReady
        this.shouldDeferQueuePermissionReadiness = shouldDeferQueuePermissionReadiness
        this.shouldReportQueuePermissionReadinessBlocked = shouldReportQueuePermissionReadinessBlocked
        this.didPreserveQueuePermissionGate = didPreserveQueuePermissionGate
    }
}

func cjguiInternalDefaultQueuePermissionPolicy(): CjguiInternalQueuePermissionPolicy {
    return CjguiInternalQueuePermissionPolicy(true, true)
}

func cjguiInternalBuildQueuePermissionGate(
    handoffGate: CjguiInternalQueueHandoffGate,
    policy: CjguiInternalQueuePermissionPolicy
): CjguiInternalQueuePermissionGate {
    let handoffGateReady = handoffGate.isQueueHandoffGateOpen &&
        handoffGate.didPreserveQueueHandoffAcceptance &&
        handoffGate.shouldDeferQueueHandoffGate == false &&
        handoffGate.shouldReportQueueHandoffGateBlocked == false
    let handoffGateDeferred = handoffGate.isQueueHandoffGateOpen == false &&
        handoffGate.didPreserveQueueHandoffAcceptance == false &&
        handoffGate.shouldDeferQueueHandoffGate &&
        handoffGate.shouldReportQueueHandoffGateBlocked == false
    let handoffGateInconsistent = (
        handoffGate.isQueueHandoffGateOpen &&
            (handoffGate.shouldDeferQueueHandoffGate ||
                handoffGate.shouldReportQueueHandoffGateBlocked)
        ) ||
        (handoffGate.didPreserveQueueHandoffAcceptance &&
            handoffGate.isQueueHandoffGateOpen == false) ||
        (handoffGate.didPreserveQueueHandoffAcceptance == false &&
            handoffGate.isQueueHandoffGateOpen) ||
        (handoffGate.shouldDeferQueueHandoffGate &&
            handoffGate.shouldReportQueueHandoffGateBlocked)
    let policyAllowsReady = policy.allowsQueuePermission
    let policyAllowsDefer = policy.allowsDeferredQueuePermission

    // handoff gate facts 不一致时必须 fail-closed，避免把 gate open 误当作 enqueue permission。
    if (
        handoffGate.shouldReportQueueHandoffGateBlocked ||
        handoffGateInconsistent
    ) {
        return CjguiInternalQueuePermissionGate(handoffGate, policy, false, false, true, false)
    }

    if (handoffGateReady && policyAllowsReady) {
        return CjguiInternalQueuePermissionGate(handoffGate, policy, true, false, false, true)
    }

    if (handoffGateDeferred && policyAllowsDefer) {
        return CjguiInternalQueuePermissionGate(handoffGate, policy, false, true, false, false)
    }

    return CjguiInternalQueuePermissionGate(handoffGate, policy, false, false, true, false)
}

func cjguiInternalBuildQueuePermissionReadiness(
    permissionGate: CjguiInternalQueuePermissionGate
): CjguiInternalQueuePermissionReadiness {
    let permissionGateReady = permissionGate.canEnterQueuePermissionGate &&
        permissionGate.didPreserveQueueHandoffGate &&
        permissionGate.shouldDeferQueuePermissionGate == false &&
        permissionGate.shouldReportQueuePermissionBlocked == false
    let permissionGateDeferred = permissionGate.canEnterQueuePermissionGate == false &&
        permissionGate.didPreserveQueueHandoffGate == false &&
        permissionGate.shouldDeferQueuePermissionGate &&
        permissionGate.shouldReportQueuePermissionBlocked == false
    let permissionGateInconsistent = (
        permissionGate.canEnterQueuePermissionGate &&
            (permissionGate.shouldDeferQueuePermissionGate ||
                permissionGate.shouldReportQueuePermissionBlocked)
        ) ||
        (permissionGate.didPreserveQueueHandoffGate &&
            permissionGate.canEnterQueuePermissionGate == false) ||
        (permissionGate.didPreserveQueueHandoffGate == false &&
            permissionGate.canEnterQueuePermissionGate) ||
        (permissionGate.shouldDeferQueuePermissionGate &&
            permissionGate.shouldReportQueuePermissionBlocked)

    // permission facts 不一致时必须 fail-closed，readiness 不能伪造成 enqueue readiness。
    if (permissionGate.shouldReportQueuePermissionBlocked || permissionGateInconsistent) {
        return CjguiInternalQueuePermissionReadiness(permissionGate, false, false, true, false)
    }

    if (permissionGateReady) {
        return CjguiInternalQueuePermissionReadiness(permissionGate, true, false, false, true)
    }

    if (permissionGateDeferred) {
        return CjguiInternalQueuePermissionReadiness(permissionGate, false, true, false, false)
    }

    return CjguiInternalQueuePermissionReadiness(permissionGate, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueuePermissionDraft(): CjguiInternalQueuePermissionReadiness {
    // 默认 draft 只串联 queue permission value pipeline，不写 queue、不 enqueue、不 drain。
    let handoffGate = cjguiInternalExecuteDefaultQueueHandoffConsumerDraft()
    let policy = cjguiInternalDefaultQueuePermissionPolicy()
    let permissionGate = cjguiInternalBuildQueuePermissionGate(handoffGate, policy)
    return cjguiInternalBuildQueuePermissionReadiness(permissionGate)
}

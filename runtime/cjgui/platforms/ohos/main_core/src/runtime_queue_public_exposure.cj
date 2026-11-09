package cjgui

// Internal Queue Public Exposure owner:
// - 本文件只消费 QueuePublicEntryResultHandoff。
// - Truth 是公开入口暴露前的 exposure gate / symbol readiness / naming policy / no-stable-compatibility facts。
// - Stop-line: exposure gate 是 internal-only value facts，不是真公开 API，不提供 C ABI，不执行真实入队；
//   不接收原始指针 / 原生句柄 / 平台对象，不写 process-wide queue storage，不创建 global mutable queue /
//   singleton，不做 item collection mutation，不 drain，不接 scheduler / event loop / platform callback / runtime
//   cycle，也不回塞 critical runtime_state.cj。

// Exposure gate 只接收 API shell handoff facts；它不是公开 API function，
// 也不会把 internal handoff 升格成稳定外部入口。
struct CjguiInternalQueuePublicExposureGate {
    let handoff: CjguiInternalQueuePublicEntryResultHandoff
    let didActivateQueuePublicExposureGate: Bool
    let didKeepQueuePublicExposureInternalOnly: Bool
    let didForbidQueuePublicVisibilityModifier: Bool
    let shouldDeferQueuePublicExposureGate: Bool
    let shouldReportQueuePublicExposureGateBlocked: Bool
    let shouldRejectQueuePublicExposureGate: Bool
    let shouldReportQueuePublicExposureGateIncompatible: Bool
    let shouldReportQueuePublicExposureGateUnauthorized: Bool
    let didPreserveQueuePublicEntryResultHandoff: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        handoff: CjguiInternalQueuePublicEntryResultHandoff,
        didActivateQueuePublicExposureGate: Bool,
        didKeepQueuePublicExposureInternalOnly: Bool,
        didForbidQueuePublicVisibilityModifier: Bool,
        shouldDeferQueuePublicExposureGate: Bool,
        shouldReportQueuePublicExposureGateBlocked: Bool,
        shouldRejectQueuePublicExposureGate: Bool,
        shouldReportQueuePublicExposureGateIncompatible: Bool,
        shouldReportQueuePublicExposureGateUnauthorized: Bool,
        didPreserveQueuePublicEntryResultHandoff: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.handoff = handoff
        this.didActivateQueuePublicExposureGate = didActivateQueuePublicExposureGate
        this.didKeepQueuePublicExposureInternalOnly = didKeepQueuePublicExposureInternalOnly
        this.didForbidQueuePublicVisibilityModifier = didForbidQueuePublicVisibilityModifier
        this.shouldDeferQueuePublicExposureGate = shouldDeferQueuePublicExposureGate
        this.shouldReportQueuePublicExposureGateBlocked = shouldReportQueuePublicExposureGateBlocked
        this.shouldRejectQueuePublicExposureGate = shouldRejectQueuePublicExposureGate
        this.shouldReportQueuePublicExposureGateIncompatible = shouldReportQueuePublicExposureGateIncompatible
        this.shouldReportQueuePublicExposureGateUnauthorized = shouldReportQueuePublicExposureGateUnauthorized
        this.didPreserveQueuePublicEntryResultHandoff = didPreserveQueuePublicEntryResultHandoff
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Symbol readiness 只表示内部符号可继续被下游 owner 审计；
// 它不新增可见性修饰符，也不形成外部 API contract。
struct CjguiInternalQueuePublicSymbolReadiness {
    let gate: CjguiInternalQueuePublicExposureGate
    let didPrepareQueuePublicSymbolReadiness: Bool
    let didKeepQueuePublicSymbolInternalOnly: Bool
    let didForbidQueuePublicVisibilityModifier: Bool
    let shouldDeferQueuePublicSymbolReadiness: Bool
    let shouldReportQueuePublicSymbolReadinessBlocked: Bool
    let shouldRejectQueuePublicSymbolReadiness: Bool
    let shouldReportQueuePublicSymbolReadinessIncompatible: Bool
    let shouldReportQueuePublicSymbolReadinessUnauthorized: Bool
    let didPreserveQueuePublicExposureGate: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        gate: CjguiInternalQueuePublicExposureGate,
        didPrepareQueuePublicSymbolReadiness: Bool,
        didKeepQueuePublicSymbolInternalOnly: Bool,
        didForbidQueuePublicVisibilityModifier: Bool,
        shouldDeferQueuePublicSymbolReadiness: Bool,
        shouldReportQueuePublicSymbolReadinessBlocked: Bool,
        shouldRejectQueuePublicSymbolReadiness: Bool,
        shouldReportQueuePublicSymbolReadinessIncompatible: Bool,
        shouldReportQueuePublicSymbolReadinessUnauthorized: Bool,
        didPreserveQueuePublicExposureGate: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.gate = gate
        this.didPrepareQueuePublicSymbolReadiness = didPrepareQueuePublicSymbolReadiness
        this.didKeepQueuePublicSymbolInternalOnly = didKeepQueuePublicSymbolInternalOnly
        this.didForbidQueuePublicVisibilityModifier = didForbidQueuePublicVisibilityModifier
        this.shouldDeferQueuePublicSymbolReadiness = shouldDeferQueuePublicSymbolReadiness
        this.shouldReportQueuePublicSymbolReadinessBlocked = shouldReportQueuePublicSymbolReadinessBlocked
        this.shouldRejectQueuePublicSymbolReadiness = shouldRejectQueuePublicSymbolReadiness
        this.shouldReportQueuePublicSymbolReadinessIncompatible =
            shouldReportQueuePublicSymbolReadinessIncompatible
        this.shouldReportQueuePublicSymbolReadinessUnauthorized =
            shouldReportQueuePublicSymbolReadinessUnauthorized
        this.didPreserveQueuePublicExposureGate = didPreserveQueuePublicExposureGate
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Naming policy 明确当前只允许 submission / submit intent 这类无副作用术语；
// 禁用真实入队动词，避免把内部 facts 误读成队列写入承诺。
struct CjguiInternalQueuePublicNamingPolicy {
    let readiness: CjguiInternalQueuePublicSymbolReadiness
    let didPrepareQueuePublicNamingPolicy: Bool
    let didPreferQueueSubmissionTerminology: Bool
    let didAvoidQueueSideEffectVerb: Bool
    let didForbidQueuePublicVisibilityModifier: Bool
    let shouldDeferQueuePublicNamingPolicy: Bool
    let shouldReportQueuePublicNamingPolicyBlocked: Bool
    let shouldRejectQueuePublicNamingPolicy: Bool
    let shouldReportQueuePublicNamingPolicyIncompatible: Bool
    let shouldReportQueuePublicNamingPolicyUnauthorized: Bool
    let didPreserveQueuePublicSymbolReadiness: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        readiness: CjguiInternalQueuePublicSymbolReadiness,
        didPrepareQueuePublicNamingPolicy: Bool,
        didPreferQueueSubmissionTerminology: Bool,
        didAvoidQueueSideEffectVerb: Bool,
        didForbidQueuePublicVisibilityModifier: Bool,
        shouldDeferQueuePublicNamingPolicy: Bool,
        shouldReportQueuePublicNamingPolicyBlocked: Bool,
        shouldRejectQueuePublicNamingPolicy: Bool,
        shouldReportQueuePublicNamingPolicyIncompatible: Bool,
        shouldReportQueuePublicNamingPolicyUnauthorized: Bool,
        didPreserveQueuePublicSymbolReadiness: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.readiness = readiness
        this.didPrepareQueuePublicNamingPolicy = didPrepareQueuePublicNamingPolicy
        this.didPreferQueueSubmissionTerminology = didPreferQueueSubmissionTerminology
        this.didAvoidQueueSideEffectVerb = didAvoidQueueSideEffectVerb
        this.didForbidQueuePublicVisibilityModifier = didForbidQueuePublicVisibilityModifier
        this.shouldDeferQueuePublicNamingPolicy = shouldDeferQueuePublicNamingPolicy
        this.shouldReportQueuePublicNamingPolicyBlocked = shouldReportQueuePublicNamingPolicyBlocked
        this.shouldRejectQueuePublicNamingPolicy = shouldRejectQueuePublicNamingPolicy
        this.shouldReportQueuePublicNamingPolicyIncompatible = shouldReportQueuePublicNamingPolicyIncompatible
        this.shouldReportQueuePublicNamingPolicyUnauthorized = shouldReportQueuePublicNamingPolicyUnauthorized
        this.didPreserveQueuePublicSymbolReadiness = didPreserveQueuePublicSymbolReadiness
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// No-stable-compatibility facts 是当前 canonical endpoint；
// 它明确记录：符号 readiness 不是稳定公开 API 兼容性承诺。
struct CjguiInternalQueuePublicNoStableCompatibility {
    let namingPolicy: CjguiInternalQueuePublicNamingPolicy
    let didPrepareQueuePublicNoStableCompatibility: Bool
    let hasStableQueuePublicApiCompatibilityPromise: Bool
    let didStateQueuePublicCompatibilityPromiseAbsent: Bool
    let shouldDeferQueuePublicNoStableCompatibility: Bool
    let shouldReportQueuePublicNoStableCompatibilityBlocked: Bool
    let shouldRejectQueuePublicNoStableCompatibility: Bool
    let shouldReportQueuePublicNoStableCompatibilityIncompatible: Bool
    let shouldReportQueuePublicNoStableCompatibilityUnauthorized: Bool
    let didPreserveQueuePublicNamingPolicy: Bool
    let didPreserveQueuePublicExposureGate: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        namingPolicy: CjguiInternalQueuePublicNamingPolicy,
        didPrepareQueuePublicNoStableCompatibility: Bool,
        hasStableQueuePublicApiCompatibilityPromise: Bool,
        didStateQueuePublicCompatibilityPromiseAbsent: Bool,
        shouldDeferQueuePublicNoStableCompatibility: Bool,
        shouldReportQueuePublicNoStableCompatibilityBlocked: Bool,
        shouldRejectQueuePublicNoStableCompatibility: Bool,
        shouldReportQueuePublicNoStableCompatibilityIncompatible: Bool,
        shouldReportQueuePublicNoStableCompatibilityUnauthorized: Bool,
        didPreserveQueuePublicNamingPolicy: Bool,
        didPreserveQueuePublicExposureGate: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.namingPolicy = namingPolicy
        this.didPrepareQueuePublicNoStableCompatibility = didPrepareQueuePublicNoStableCompatibility
        this.hasStableQueuePublicApiCompatibilityPromise = hasStableQueuePublicApiCompatibilityPromise
        this.didStateQueuePublicCompatibilityPromiseAbsent = didStateQueuePublicCompatibilityPromiseAbsent
        this.shouldDeferQueuePublicNoStableCompatibility = shouldDeferQueuePublicNoStableCompatibility
        this.shouldReportQueuePublicNoStableCompatibilityBlocked =
            shouldReportQueuePublicNoStableCompatibilityBlocked
        this.shouldRejectQueuePublicNoStableCompatibility = shouldRejectQueuePublicNoStableCompatibility
        this.shouldReportQueuePublicNoStableCompatibilityIncompatible =
            shouldReportQueuePublicNoStableCompatibilityIncompatible
        this.shouldReportQueuePublicNoStableCompatibilityUnauthorized =
            shouldReportQueuePublicNoStableCompatibilityUnauthorized
        this.didPreserveQueuePublicNamingPolicy = didPreserveQueuePublicNamingPolicy
        this.didPreserveQueuePublicExposureGate = didPreserveQueuePublicExposureGate
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueuePublicExposureGate(
    handoff: CjguiInternalQueuePublicEntryResultHandoff
): CjguiInternalQueuePublicExposureGate {
    let handoffReady = handoff.didPrepareQueuePublicEntryResultHandoff &&
        handoff.didKeepQueuePublicEntryResultHandoffInternalOnly &&
        handoff.didPreserveQueuePublicEntryResult &&
        handoff.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        handoff.didPreservePreviousQueueStoreSnapshot &&
        handoff.shouldDeferQueuePublicEntryResultHandoff == false &&
        handoff.shouldReportQueuePublicEntryResultHandoffBlocked == false &&
        handoff.shouldRejectQueuePublicEntryResultHandoff == false &&
        handoff.shouldReportQueuePublicEntryResultHandoffIncompatible == false &&
        handoff.shouldReportQueuePublicEntryResultHandoffUnauthorized == false
    let handoffDeferred = handoff.didPrepareQueuePublicEntryResultHandoff == false &&
        handoff.didKeepQueuePublicEntryResultHandoffInternalOnly == false &&
        handoff.didPreserveQueuePublicEntryResult == false &&
        handoff.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        handoff.didPreservePreviousQueueStoreSnapshot &&
        handoff.shouldDeferQueuePublicEntryResultHandoff &&
        handoff.shouldReportQueuePublicEntryResultHandoffBlocked == false &&
        handoff.shouldRejectQueuePublicEntryResultHandoff == false &&
        handoff.shouldReportQueuePublicEntryResultHandoffIncompatible == false &&
        handoff.shouldReportQueuePublicEntryResultHandoffUnauthorized == false
    let handoffInconsistent = (
        handoff.didPrepareQueuePublicEntryResultHandoff &&
            (
                handoff.didKeepQueuePublicEntryResultHandoffInternalOnly == false ||
                handoff.didPreserveQueuePublicEntryResult == false ||
                handoff.didPreserveQueuePublicPermissionAndRollbackLinkage == false ||
                handoff.shouldDeferQueuePublicEntryResultHandoff ||
                handoff.shouldReportQueuePublicEntryResultHandoffBlocked ||
                handoff.shouldRejectQueuePublicEntryResultHandoff ||
                handoff.shouldReportQueuePublicEntryResultHandoffIncompatible ||
                handoff.shouldReportQueuePublicEntryResultHandoffUnauthorized
            )
        ) ||
        (handoff.didKeepQueuePublicEntryResultHandoffInternalOnly &&
            handoff.didPrepareQueuePublicEntryResultHandoff == false) ||
        (handoff.didPreserveQueuePublicEntryResult &&
            handoff.didPrepareQueuePublicEntryResultHandoff == false) ||
        (handoff.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            handoff.didPrepareQueuePublicEntryResultHandoff == false) ||
        (handoff.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            handoff.shouldDeferQueuePublicEntryResultHandoff &&
            (
                handoff.shouldReportQueuePublicEntryResultHandoffBlocked ||
                handoff.shouldRejectQueuePublicEntryResultHandoff ||
                handoff.shouldReportQueuePublicEntryResultHandoffIncompatible ||
                handoff.shouldReportQueuePublicEntryResultHandoffUnauthorized
            )
        )

    // handoff 不一致时必须 fail-closed，不能伪造 exposure gate open。
    if (
        handoff.shouldReportQueuePublicEntryResultHandoffBlocked ||
        handoff.shouldRejectQueuePublicEntryResultHandoff ||
        handoff.shouldReportQueuePublicEntryResultHandoffIncompatible ||
        handoff.shouldReportQueuePublicEntryResultHandoffUnauthorized ||
        handoffInconsistent
    ) {
        return CjguiInternalQueuePublicExposureGate(
            handoff,
            false,
            false,
            true,
            false,
            true,
            true,
            handoff.shouldReportQueuePublicEntryResultHandoffIncompatible || handoffInconsistent,
            handoff.shouldReportQueuePublicEntryResultHandoffUnauthorized,
            false,
            false,
            handoff.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (handoffReady) {
        return CjguiInternalQueuePublicExposureGate(
            handoff,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true
        )
    }

    if (handoffDeferred) {
        return CjguiInternalQueuePublicExposureGate(
            handoff,
            false,
            false,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicExposureGate(
        handoff,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        handoff.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicSymbolReadiness(
    gate: CjguiInternalQueuePublicExposureGate
): CjguiInternalQueuePublicSymbolReadiness {
    let gateReady = gate.didActivateQueuePublicExposureGate &&
        gate.didKeepQueuePublicExposureInternalOnly &&
        gate.didForbidQueuePublicVisibilityModifier &&
        gate.didPreserveQueuePublicEntryResultHandoff &&
        gate.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        gate.didPreservePreviousQueueStoreSnapshot &&
        gate.shouldDeferQueuePublicExposureGate == false &&
        gate.shouldReportQueuePublicExposureGateBlocked == false &&
        gate.shouldRejectQueuePublicExposureGate == false &&
        gate.shouldReportQueuePublicExposureGateIncompatible == false &&
        gate.shouldReportQueuePublicExposureGateUnauthorized == false
    let gateDeferred = gate.didActivateQueuePublicExposureGate == false &&
        gate.didKeepQueuePublicExposureInternalOnly == false &&
        gate.didPreserveQueuePublicEntryResultHandoff == false &&
        gate.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        gate.didPreservePreviousQueueStoreSnapshot &&
        gate.shouldDeferQueuePublicExposureGate &&
        gate.shouldReportQueuePublicExposureGateBlocked == false &&
        gate.shouldRejectQueuePublicExposureGate == false &&
        gate.shouldReportQueuePublicExposureGateIncompatible == false &&
        gate.shouldReportQueuePublicExposureGateUnauthorized == false
    let gateInconsistent = (
        gate.didActivateQueuePublicExposureGate &&
            (
                gate.didKeepQueuePublicExposureInternalOnly == false ||
                gate.didForbidQueuePublicVisibilityModifier == false ||
                gate.didPreserveQueuePublicEntryResultHandoff == false ||
                gate.didPreserveQueuePublicPermissionAndRollbackLinkage == false ||
                gate.shouldDeferQueuePublicExposureGate ||
                gate.shouldReportQueuePublicExposureGateBlocked ||
                gate.shouldRejectQueuePublicExposureGate ||
                gate.shouldReportQueuePublicExposureGateIncompatible ||
                gate.shouldReportQueuePublicExposureGateUnauthorized
            )
        ) ||
        (gate.didForbidQueuePublicVisibilityModifier == false) ||
        (gate.didPreserveQueuePublicEntryResultHandoff &&
            gate.didActivateQueuePublicExposureGate == false) ||
        (gate.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            gate.didActivateQueuePublicExposureGate == false) ||
        (gate.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            gate.shouldDeferQueuePublicExposureGate &&
            (
                gate.shouldReportQueuePublicExposureGateBlocked ||
                gate.shouldRejectQueuePublicExposureGate ||
                gate.shouldReportQueuePublicExposureGateIncompatible ||
                gate.shouldReportQueuePublicExposureGateUnauthorized
            )
        )

    // exposure gate 不一致时必须 fail-closed，不能伪造 symbol readiness。
    if (
        gate.shouldReportQueuePublicExposureGateBlocked ||
        gate.shouldRejectQueuePublicExposureGate ||
        gate.shouldReportQueuePublicExposureGateIncompatible ||
        gate.shouldReportQueuePublicExposureGateUnauthorized ||
        gateInconsistent
    ) {
        return CjguiInternalQueuePublicSymbolReadiness(
            gate,
            false,
            false,
            true,
            false,
            true,
            true,
            gate.shouldReportQueuePublicExposureGateIncompatible || gateInconsistent,
            gate.shouldReportQueuePublicExposureGateUnauthorized,
            false,
            false,
            gate.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (gateReady) {
        return CjguiInternalQueuePublicSymbolReadiness(
            gate,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true
        )
    }

    if (gateDeferred) {
        return CjguiInternalQueuePublicSymbolReadiness(
            gate,
            false,
            false,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicSymbolReadiness(
        gate,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        gate.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicNamingPolicy(
    readiness: CjguiInternalQueuePublicSymbolReadiness
): CjguiInternalQueuePublicNamingPolicy {
    let readinessReady = readiness.didPrepareQueuePublicSymbolReadiness &&
        readiness.didKeepQueuePublicSymbolInternalOnly &&
        readiness.didForbidQueuePublicVisibilityModifier &&
        readiness.didPreserveQueuePublicExposureGate &&
        readiness.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        readiness.didPreservePreviousQueueStoreSnapshot &&
        readiness.shouldDeferQueuePublicSymbolReadiness == false &&
        readiness.shouldReportQueuePublicSymbolReadinessBlocked == false &&
        readiness.shouldRejectQueuePublicSymbolReadiness == false &&
        readiness.shouldReportQueuePublicSymbolReadinessIncompatible == false &&
        readiness.shouldReportQueuePublicSymbolReadinessUnauthorized == false
    let readinessDeferred = readiness.didPrepareQueuePublicSymbolReadiness == false &&
        readiness.didKeepQueuePublicSymbolInternalOnly == false &&
        readiness.didPreserveQueuePublicExposureGate == false &&
        readiness.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        readiness.didPreservePreviousQueueStoreSnapshot &&
        readiness.shouldDeferQueuePublicSymbolReadiness &&
        readiness.shouldReportQueuePublicSymbolReadinessBlocked == false &&
        readiness.shouldRejectQueuePublicSymbolReadiness == false &&
        readiness.shouldReportQueuePublicSymbolReadinessIncompatible == false &&
        readiness.shouldReportQueuePublicSymbolReadinessUnauthorized == false
    let readinessInconsistent = (
        readiness.didPrepareQueuePublicSymbolReadiness &&
            (
                readiness.didKeepQueuePublicSymbolInternalOnly == false ||
                readiness.didForbidQueuePublicVisibilityModifier == false ||
                readiness.didPreserveQueuePublicExposureGate == false ||
                readiness.didPreserveQueuePublicPermissionAndRollbackLinkage == false ||
                readiness.shouldDeferQueuePublicSymbolReadiness ||
                readiness.shouldReportQueuePublicSymbolReadinessBlocked ||
                readiness.shouldRejectQueuePublicSymbolReadiness ||
                readiness.shouldReportQueuePublicSymbolReadinessIncompatible ||
                readiness.shouldReportQueuePublicSymbolReadinessUnauthorized
            )
        ) ||
        (readiness.didForbidQueuePublicVisibilityModifier == false) ||
        (readiness.didPreserveQueuePublicExposureGate &&
            readiness.didPrepareQueuePublicSymbolReadiness == false) ||
        (readiness.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            readiness.didPrepareQueuePublicSymbolReadiness == false) ||
        (readiness.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            readiness.shouldDeferQueuePublicSymbolReadiness &&
            (
                readiness.shouldReportQueuePublicSymbolReadinessBlocked ||
                readiness.shouldRejectQueuePublicSymbolReadiness ||
                readiness.shouldReportQueuePublicSymbolReadinessIncompatible ||
                readiness.shouldReportQueuePublicSymbolReadinessUnauthorized
            )
        )

    // symbol readiness 不一致时必须 fail-closed，命名策略不能伪造可暴露状态。
    if (
        readiness.shouldReportQueuePublicSymbolReadinessBlocked ||
        readiness.shouldRejectQueuePublicSymbolReadiness ||
        readiness.shouldReportQueuePublicSymbolReadinessIncompatible ||
        readiness.shouldReportQueuePublicSymbolReadinessUnauthorized ||
        readinessInconsistent
    ) {
        return CjguiInternalQueuePublicNamingPolicy(
            readiness,
            false,
            false,
            true,
            true,
            false,
            true,
            true,
            readiness.shouldReportQueuePublicSymbolReadinessIncompatible || readinessInconsistent,
            readiness.shouldReportQueuePublicSymbolReadinessUnauthorized,
            false,
            false,
            readiness.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (readinessReady) {
        return CjguiInternalQueuePublicNamingPolicy(
            readiness,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalQueuePublicNamingPolicy(
            readiness,
            false,
            false,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicNamingPolicy(
        readiness,
        false,
        false,
        true,
        true,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        readiness.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicNoStableCompatibility(
    namingPolicy: CjguiInternalQueuePublicNamingPolicy
): CjguiInternalQueuePublicNoStableCompatibility {
    let namingReady = namingPolicy.didPrepareQueuePublicNamingPolicy &&
        namingPolicy.didPreferQueueSubmissionTerminology &&
        namingPolicy.didAvoidQueueSideEffectVerb &&
        namingPolicy.didForbidQueuePublicVisibilityModifier &&
        namingPolicy.didPreserveQueuePublicSymbolReadiness &&
        namingPolicy.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        namingPolicy.didPreservePreviousQueueStoreSnapshot &&
        namingPolicy.shouldDeferQueuePublicNamingPolicy == false &&
        namingPolicy.shouldReportQueuePublicNamingPolicyBlocked == false &&
        namingPolicy.shouldRejectQueuePublicNamingPolicy == false &&
        namingPolicy.shouldReportQueuePublicNamingPolicyIncompatible == false &&
        namingPolicy.shouldReportQueuePublicNamingPolicyUnauthorized == false
    let namingDeferred = namingPolicy.didPrepareQueuePublicNamingPolicy == false &&
        namingPolicy.didPreferQueueSubmissionTerminology == false &&
        namingPolicy.didPreserveQueuePublicSymbolReadiness == false &&
        namingPolicy.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        namingPolicy.didPreservePreviousQueueStoreSnapshot &&
        namingPolicy.shouldDeferQueuePublicNamingPolicy &&
        namingPolicy.shouldReportQueuePublicNamingPolicyBlocked == false &&
        namingPolicy.shouldRejectQueuePublicNamingPolicy == false &&
        namingPolicy.shouldReportQueuePublicNamingPolicyIncompatible == false &&
        namingPolicy.shouldReportQueuePublicNamingPolicyUnauthorized == false
    let namingInconsistent = (
        namingPolicy.didPrepareQueuePublicNamingPolicy &&
            (
                namingPolicy.didPreferQueueSubmissionTerminology == false ||
                namingPolicy.didAvoidQueueSideEffectVerb == false ||
                namingPolicy.didForbidQueuePublicVisibilityModifier == false ||
                namingPolicy.didPreserveQueuePublicSymbolReadiness == false ||
                namingPolicy.didPreserveQueuePublicPermissionAndRollbackLinkage == false ||
                namingPolicy.shouldDeferQueuePublicNamingPolicy ||
                namingPolicy.shouldReportQueuePublicNamingPolicyBlocked ||
                namingPolicy.shouldRejectQueuePublicNamingPolicy ||
                namingPolicy.shouldReportQueuePublicNamingPolicyIncompatible ||
                namingPolicy.shouldReportQueuePublicNamingPolicyUnauthorized
            )
        ) ||
        (namingPolicy.didAvoidQueueSideEffectVerb == false) ||
        (namingPolicy.didForbidQueuePublicVisibilityModifier == false) ||
        (namingPolicy.didPreserveQueuePublicSymbolReadiness &&
            namingPolicy.didPrepareQueuePublicNamingPolicy == false) ||
        (namingPolicy.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            namingPolicy.didPrepareQueuePublicNamingPolicy == false) ||
        (namingPolicy.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            namingPolicy.shouldDeferQueuePublicNamingPolicy &&
            (
                namingPolicy.shouldReportQueuePublicNamingPolicyBlocked ||
                namingPolicy.shouldRejectQueuePublicNamingPolicy ||
                namingPolicy.shouldReportQueuePublicNamingPolicyIncompatible ||
                namingPolicy.shouldReportQueuePublicNamingPolicyUnauthorized
            )
        )

    // 命名策略不一致时必须 fail-closed，不能伪造稳定兼容性缺席已被记录。
    if (
        namingPolicy.shouldReportQueuePublicNamingPolicyBlocked ||
        namingPolicy.shouldRejectQueuePublicNamingPolicy ||
        namingPolicy.shouldReportQueuePublicNamingPolicyIncompatible ||
        namingPolicy.shouldReportQueuePublicNamingPolicyUnauthorized ||
        namingInconsistent
    ) {
        return CjguiInternalQueuePublicNoStableCompatibility(
            namingPolicy,
            false,
            false,
            false,
            false,
            true,
            true,
            namingPolicy.shouldReportQueuePublicNamingPolicyIncompatible || namingInconsistent,
            namingPolicy.shouldReportQueuePublicNamingPolicyUnauthorized,
            false,
            false,
            false,
            namingPolicy.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (namingReady) {
        // 当前明确不承诺稳定公开 API 兼容性；本 endpoint 只记录这个事实。
        return CjguiInternalQueuePublicNoStableCompatibility(
            namingPolicy,
            true,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (namingDeferred) {
        return CjguiInternalQueuePublicNoStableCompatibility(
            namingPolicy,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicNoStableCompatibility(
        namingPolicy,
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        false,
        namingPolicy.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueuePublicExposureDraft(): CjguiInternalQueuePublicNoStableCompatibility {
    // 默认 draft 只串联 exposure readiness value facts；
    // 不是公开 API / C ABI，也不执行真实入队或写 queue storage。
    let handoff = cjguiInternalExecuteDefaultQueuePublicApiShellDraft()
    let gate = cjguiInternalBuildQueuePublicExposureGate(handoff)
    let readiness = cjguiInternalBuildQueuePublicSymbolReadiness(gate)
    let namingPolicy = cjguiInternalBuildQueuePublicNamingPolicy(readiness)
    return cjguiInternalBuildQueuePublicNoStableCompatibility(namingPolicy)
}

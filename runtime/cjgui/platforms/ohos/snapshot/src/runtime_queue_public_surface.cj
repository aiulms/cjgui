package cjgui

// Internal Queue Public Surface owner:
// - 本文件只消费 QueuePublicBoundaryReadiness。
// - Truth 是 future public surface 前的 policy / compatibility / error contract / audit / api-readiness 内部 value facts。
// - Stop-line: public surface policy 不是 public API / C ABI，也不是真实 enqueue；不写 process-wide queue storage、
//   不创建 global mutable queue / singleton、不做 item collection mutation、不 drain、不接 event loop / scheduler /
//   platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Public surface policy 只固定未来 public surface 的内部策略事实；
// 它不是 public API shape、C ABI contract，也不是 enqueue permission。
struct CjguiInternalQueuePublicSurfacePolicy {
    let readiness: CjguiInternalQueuePublicBoundaryReadiness
    let didEstablishQueuePublicSurfacePolicy: Bool
    let shouldDeferQueuePublicSurfacePolicy: Bool
    let shouldReportQueuePublicSurfacePolicyBlocked: Bool
    let shouldReportQueuePublicSurfacePolicyIncompatible: Bool
    let shouldReportQueuePublicSurfacePolicyUnauthorized: Bool
    let didPreserveQueuePublicBoundaryReadiness: Bool
    let didRequireQueuePublicSurfaceInternalGateLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        readiness: CjguiInternalQueuePublicBoundaryReadiness,
        didEstablishQueuePublicSurfacePolicy: Bool,
        shouldDeferQueuePublicSurfacePolicy: Bool,
        shouldReportQueuePublicSurfacePolicyBlocked: Bool,
        shouldReportQueuePublicSurfacePolicyIncompatible: Bool,
        shouldReportQueuePublicSurfacePolicyUnauthorized: Bool,
        didPreserveQueuePublicBoundaryReadiness: Bool,
        didRequireQueuePublicSurfaceInternalGateLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.readiness = readiness
        this.didEstablishQueuePublicSurfacePolicy = didEstablishQueuePublicSurfacePolicy
        this.shouldDeferQueuePublicSurfacePolicy = shouldDeferQueuePublicSurfacePolicy
        this.shouldReportQueuePublicSurfacePolicyBlocked = shouldReportQueuePublicSurfacePolicyBlocked
        this.shouldReportQueuePublicSurfacePolicyIncompatible = shouldReportQueuePublicSurfacePolicyIncompatible
        this.shouldReportQueuePublicSurfacePolicyUnauthorized = shouldReportQueuePublicSurfacePolicyUnauthorized
        this.didPreserveQueuePublicBoundaryReadiness = didPreserveQueuePublicBoundaryReadiness
        this.didRequireQueuePublicSurfaceInternalGateLinkage = didRequireQueuePublicSurfaceInternalGateLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Compatibility facts 只说明当前没有 stable public API compatibility promise，并保留未来兼容性评估事实；
// 它不是稳定 API 承诺，也不是对外 contract 发布。
struct CjguiInternalQueuePublicCompatibilityFacts {
    let policy: CjguiInternalQueuePublicSurfacePolicy
    let didRecordQueuePublicCompatibilityFacts: Bool
    let hasStableQueuePublicApiCompatibilityPromise: Bool
    let shouldDeferQueuePublicCompatibilityFacts: Bool
    let shouldReportQueuePublicCompatibilityFactsBlocked: Bool
    let shouldReportQueuePublicCompatibilityFactsIncompatible: Bool
    let shouldReportQueuePublicCompatibilityFactsUnauthorized: Bool
    let didPreserveQueuePublicSurfacePolicy: Bool
    let didPreserveQueuePublicSurfaceInternalGateLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        policy: CjguiInternalQueuePublicSurfacePolicy,
        didRecordQueuePublicCompatibilityFacts: Bool,
        hasStableQueuePublicApiCompatibilityPromise: Bool,
        shouldDeferQueuePublicCompatibilityFacts: Bool,
        shouldReportQueuePublicCompatibilityFactsBlocked: Bool,
        shouldReportQueuePublicCompatibilityFactsIncompatible: Bool,
        shouldReportQueuePublicCompatibilityFactsUnauthorized: Bool,
        didPreserveQueuePublicSurfacePolicy: Bool,
        didPreserveQueuePublicSurfaceInternalGateLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.policy = policy
        this.didRecordQueuePublicCompatibilityFacts = didRecordQueuePublicCompatibilityFacts
        this.hasStableQueuePublicApiCompatibilityPromise = hasStableQueuePublicApiCompatibilityPromise
        this.shouldDeferQueuePublicCompatibilityFacts = shouldDeferQueuePublicCompatibilityFacts
        this.shouldReportQueuePublicCompatibilityFactsBlocked = shouldReportQueuePublicCompatibilityFactsBlocked
        this.shouldReportQueuePublicCompatibilityFactsIncompatible =
            shouldReportQueuePublicCompatibilityFactsIncompatible
        this.shouldReportQueuePublicCompatibilityFactsUnauthorized =
            shouldReportQueuePublicCompatibilityFactsUnauthorized
        this.didPreserveQueuePublicSurfacePolicy = didPreserveQueuePublicSurfacePolicy
        this.didPreserveQueuePublicSurfaceInternalGateLinkage = didPreserveQueuePublicSurfaceInternalGateLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Error contract 只把 future public-facing error 映射成内部 value facts；
// 它不是真实 runtime error surface，也不向外暴露错误 ABI。
struct CjguiInternalQueuePublicErrorContract {
    let compatibility: CjguiInternalQueuePublicCompatibilityFacts
    let didPrepareQueuePublicErrorContract: Bool
    let didMapQueuePublicErrorsAsValueFacts: Bool
    let shouldDeferQueuePublicErrorContract: Bool
    let shouldReportQueuePublicErrorContractBlocked: Bool
    let shouldReportQueuePublicErrorContractIncompatible: Bool
    let shouldReportQueuePublicErrorContractUnauthorized: Bool
    let didPreserveQueuePublicCompatibilityFacts: Bool
    let didPreserveQueuePublicSurfaceInternalGateLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        compatibility: CjguiInternalQueuePublicCompatibilityFacts,
        didPrepareQueuePublicErrorContract: Bool,
        didMapQueuePublicErrorsAsValueFacts: Bool,
        shouldDeferQueuePublicErrorContract: Bool,
        shouldReportQueuePublicErrorContractBlocked: Bool,
        shouldReportQueuePublicErrorContractIncompatible: Bool,
        shouldReportQueuePublicErrorContractUnauthorized: Bool,
        didPreserveQueuePublicCompatibilityFacts: Bool,
        didPreserveQueuePublicSurfaceInternalGateLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.compatibility = compatibility
        this.didPrepareQueuePublicErrorContract = didPrepareQueuePublicErrorContract
        this.didMapQueuePublicErrorsAsValueFacts = didMapQueuePublicErrorsAsValueFacts
        this.shouldDeferQueuePublicErrorContract = shouldDeferQueuePublicErrorContract
        this.shouldReportQueuePublicErrorContractBlocked = shouldReportQueuePublicErrorContractBlocked
        this.shouldReportQueuePublicErrorContractIncompatible = shouldReportQueuePublicErrorContractIncompatible
        this.shouldReportQueuePublicErrorContractUnauthorized = shouldReportQueuePublicErrorContractUnauthorized
        this.didPreserveQueuePublicCompatibilityFacts = didPreserveQueuePublicCompatibilityFacts
        this.didPreserveQueuePublicSurfaceInternalGateLinkage = didPreserveQueuePublicSurfaceInternalGateLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Audit requirement 只要求 future public surface 继续挂接 permission / audit / rollback facts；
// 它不是 public audit log，也不是 observer callback。
struct CjguiInternalQueuePublicAuditRequirement {
    let errorContract: CjguiInternalQueuePublicErrorContract
    let didRequireQueuePublicAudit: Bool
    let didRequireQueuePublicPermissionLinkage: Bool
    let didRequireQueuePublicRollbackLinkage: Bool
    let shouldDeferQueuePublicAuditRequirement: Bool
    let shouldReportQueuePublicAuditRequirementBlocked: Bool
    let shouldReportQueuePublicAuditRequirementIncompatible: Bool
    let shouldReportQueuePublicAuditRequirementUnauthorized: Bool
    let didPreserveQueuePublicErrorContract: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        errorContract: CjguiInternalQueuePublicErrorContract,
        didRequireQueuePublicAudit: Bool,
        didRequireQueuePublicPermissionLinkage: Bool,
        didRequireQueuePublicRollbackLinkage: Bool,
        shouldDeferQueuePublicAuditRequirement: Bool,
        shouldReportQueuePublicAuditRequirementBlocked: Bool,
        shouldReportQueuePublicAuditRequirementIncompatible: Bool,
        shouldReportQueuePublicAuditRequirementUnauthorized: Bool,
        didPreserveQueuePublicErrorContract: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.errorContract = errorContract
        this.didRequireQueuePublicAudit = didRequireQueuePublicAudit
        this.didRequireQueuePublicPermissionLinkage = didRequireQueuePublicPermissionLinkage
        this.didRequireQueuePublicRollbackLinkage = didRequireQueuePublicRollbackLinkage
        this.shouldDeferQueuePublicAuditRequirement = shouldDeferQueuePublicAuditRequirement
        this.shouldReportQueuePublicAuditRequirementBlocked = shouldReportQueuePublicAuditRequirementBlocked
        this.shouldReportQueuePublicAuditRequirementIncompatible = shouldReportQueuePublicAuditRequirementIncompatible
        this.shouldReportQueuePublicAuditRequirementUnauthorized = shouldReportQueuePublicAuditRequirementUnauthorized
        this.didPreserveQueuePublicErrorContract = didPreserveQueuePublicErrorContract
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// API readiness candidate 是本轮 canonical endpoint；它只表示 future public API surface 可继续评估，
// 不是 public API 已开放、C ABI 已稳定或真实 enqueue 已允许。
struct CjguiInternalQueuePublicApiReadinessCandidate {
    let auditRequirement: CjguiInternalQueuePublicAuditRequirement
    let isQueuePublicApiReadinessCandidateReady: Bool
    let hasStableQueuePublicApiCompatibilityPromise: Bool
    let shouldDeferQueuePublicApiReadinessCandidate: Bool
    let shouldReportQueuePublicApiReadinessCandidateBlocked: Bool
    let shouldReportQueuePublicApiReadinessCandidateIncompatible: Bool
    let shouldReportQueuePublicApiReadinessCandidateUnauthorized: Bool
    let didPreserveQueuePublicAuditRequirement: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        auditRequirement: CjguiInternalQueuePublicAuditRequirement,
        isQueuePublicApiReadinessCandidateReady: Bool,
        hasStableQueuePublicApiCompatibilityPromise: Bool,
        shouldDeferQueuePublicApiReadinessCandidate: Bool,
        shouldReportQueuePublicApiReadinessCandidateBlocked: Bool,
        shouldReportQueuePublicApiReadinessCandidateIncompatible: Bool,
        shouldReportQueuePublicApiReadinessCandidateUnauthorized: Bool,
        didPreserveQueuePublicAuditRequirement: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.auditRequirement = auditRequirement
        this.isQueuePublicApiReadinessCandidateReady = isQueuePublicApiReadinessCandidateReady
        this.hasStableQueuePublicApiCompatibilityPromise = hasStableQueuePublicApiCompatibilityPromise
        this.shouldDeferQueuePublicApiReadinessCandidate = shouldDeferQueuePublicApiReadinessCandidate
        this.shouldReportQueuePublicApiReadinessCandidateBlocked =
            shouldReportQueuePublicApiReadinessCandidateBlocked
        this.shouldReportQueuePublicApiReadinessCandidateIncompatible =
            shouldReportQueuePublicApiReadinessCandidateIncompatible
        this.shouldReportQueuePublicApiReadinessCandidateUnauthorized =
            shouldReportQueuePublicApiReadinessCandidateUnauthorized
        this.didPreserveQueuePublicAuditRequirement = didPreserveQueuePublicAuditRequirement
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueuePublicSurfacePolicy(
    readiness: CjguiInternalQueuePublicBoundaryReadiness
): CjguiInternalQueuePublicSurfacePolicy {
    let readinessReady = readiness.isQueuePublicBoundaryReady &&
        readiness.didPreserveQueuePublicBoundaryAdmission &&
        readiness.didPreservePreviousQueueStoreSnapshot &&
        readiness.shouldDeferQueuePublicBoundaryReadiness == false &&
        readiness.shouldReportQueuePublicBoundaryReadinessBlocked == false &&
        readiness.shouldRejectQueuePublicBoundaryReadiness == false &&
        readiness.shouldReportQueuePublicBoundaryReadinessIncompatible == false &&
        readiness.shouldReportQueuePublicBoundaryReadinessUnauthorized == false
    let readinessDeferred = readiness.isQueuePublicBoundaryReady == false &&
        readiness.didPreserveQueuePublicBoundaryAdmission == false &&
        readiness.didPreservePreviousQueueStoreSnapshot &&
        readiness.shouldDeferQueuePublicBoundaryReadiness &&
        readiness.shouldReportQueuePublicBoundaryReadinessBlocked == false &&
        readiness.shouldRejectQueuePublicBoundaryReadiness == false
    let readinessInconsistent = (
        readiness.isQueuePublicBoundaryReady &&
            (
                readiness.shouldDeferQueuePublicBoundaryReadiness ||
                readiness.shouldReportQueuePublicBoundaryReadinessBlocked ||
                readiness.shouldRejectQueuePublicBoundaryReadiness ||
                readiness.shouldReportQueuePublicBoundaryReadinessIncompatible ||
                readiness.shouldReportQueuePublicBoundaryReadinessUnauthorized
            )
        ) ||
        (readiness.didPreserveQueuePublicBoundaryAdmission &&
            readiness.isQueuePublicBoundaryReady == false) ||
        (readiness.didPreserveQueuePublicBoundaryAdmission == false &&
            readiness.isQueuePublicBoundaryReady) ||
        (readiness.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            readiness.shouldDeferQueuePublicBoundaryReadiness &&
            readiness.shouldReportQueuePublicBoundaryReadinessBlocked
        )

    // public-boundary readiness 不一致时必须 fail-closed，不能建立 public surface policy。
    if (
        readiness.shouldReportQueuePublicBoundaryReadinessBlocked ||
        readiness.shouldRejectQueuePublicBoundaryReadiness ||
        readiness.shouldReportQueuePublicBoundaryReadinessIncompatible ||
        readiness.shouldReportQueuePublicBoundaryReadinessUnauthorized ||
        readinessInconsistent
    ) {
        return CjguiInternalQueuePublicSurfacePolicy(
            readiness,
            false,
            false,
            true,
            readiness.shouldReportQueuePublicBoundaryReadinessIncompatible || readinessInconsistent,
            readiness.shouldReportQueuePublicBoundaryReadinessUnauthorized,
            false,
            false,
            readiness.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (readinessReady) {
        return CjguiInternalQueuePublicSurfacePolicy(readiness, true, false, false, false, false, true, true, true)
    }

    if (readinessDeferred) {
        return CjguiInternalQueuePublicSurfacePolicy(readiness, false, true, false, false, false, false, false, true)
    }

    return CjguiInternalQueuePublicSurfacePolicy(
        readiness,
        false,
        false,
        true,
        true,
        false,
        false,
        false,
        readiness.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicCompatibilityFacts(
    policy: CjguiInternalQueuePublicSurfacePolicy
): CjguiInternalQueuePublicCompatibilityFacts {
    let policyReady = policy.didEstablishQueuePublicSurfacePolicy &&
        policy.didPreserveQueuePublicBoundaryReadiness &&
        policy.didRequireQueuePublicSurfaceInternalGateLinkage &&
        policy.didPreservePreviousQueueStoreSnapshot &&
        policy.shouldDeferQueuePublicSurfacePolicy == false &&
        policy.shouldReportQueuePublicSurfacePolicyBlocked == false &&
        policy.shouldReportQueuePublicSurfacePolicyIncompatible == false &&
        policy.shouldReportQueuePublicSurfacePolicyUnauthorized == false
    let policyDeferred = policy.didEstablishQueuePublicSurfacePolicy == false &&
        policy.didPreserveQueuePublicBoundaryReadiness == false &&
        policy.didRequireQueuePublicSurfaceInternalGateLinkage == false &&
        policy.didPreservePreviousQueueStoreSnapshot &&
        policy.shouldDeferQueuePublicSurfacePolicy &&
        policy.shouldReportQueuePublicSurfacePolicyBlocked == false
    let policyInconsistent = (
        policy.didEstablishQueuePublicSurfacePolicy &&
            (
                policy.shouldDeferQueuePublicSurfacePolicy ||
                policy.shouldReportQueuePublicSurfacePolicyBlocked ||
                policy.shouldReportQueuePublicSurfacePolicyIncompatible ||
                policy.shouldReportQueuePublicSurfacePolicyUnauthorized
            )
        ) ||
        (policy.didPreserveQueuePublicBoundaryReadiness &&
            policy.didEstablishQueuePublicSurfacePolicy == false) ||
        (policy.didPreserveQueuePublicBoundaryReadiness == false &&
            policy.didEstablishQueuePublicSurfacePolicy) ||
        (policy.didRequireQueuePublicSurfaceInternalGateLinkage &&
            policy.didEstablishQueuePublicSurfacePolicy == false) ||
        (policy.didRequireQueuePublicSurfaceInternalGateLinkage == false &&
            policy.didEstablishQueuePublicSurfacePolicy) ||
        (policy.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            policy.shouldDeferQueuePublicSurfacePolicy &&
            policy.shouldReportQueuePublicSurfacePolicyBlocked
        )

    // policy 不一致时必须 fail-closed，compatibility facts 不能伪造 stable API 承诺。
    if (
        policy.shouldReportQueuePublicSurfacePolicyBlocked ||
        policy.shouldReportQueuePublicSurfacePolicyIncompatible ||
        policy.shouldReportQueuePublicSurfacePolicyUnauthorized ||
        policyInconsistent
    ) {
        return CjguiInternalQueuePublicCompatibilityFacts(
            policy,
            false,
            false,
            false,
            true,
            policy.shouldReportQueuePublicSurfacePolicyIncompatible || policyInconsistent,
            policy.shouldReportQueuePublicSurfacePolicyUnauthorized,
            false,
            false,
            policy.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (policyReady) {
        return CjguiInternalQueuePublicCompatibilityFacts(policy, true, false, false, false, false, false, true, true, true)
    }

    if (policyDeferred) {
        return CjguiInternalQueuePublicCompatibilityFacts(
            policy,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicCompatibilityFacts(
        policy,
        false,
        false,
        false,
        true,
        true,
        false,
        false,
        false,
        policy.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicErrorContract(
    compatibility: CjguiInternalQueuePublicCompatibilityFacts
): CjguiInternalQueuePublicErrorContract {
    let compatibilityReady = compatibility.didRecordQueuePublicCompatibilityFacts &&
        compatibility.hasStableQueuePublicApiCompatibilityPromise == false &&
        compatibility.didPreserveQueuePublicSurfacePolicy &&
        compatibility.didPreserveQueuePublicSurfaceInternalGateLinkage &&
        compatibility.didPreservePreviousQueueStoreSnapshot &&
        compatibility.shouldDeferQueuePublicCompatibilityFacts == false &&
        compatibility.shouldReportQueuePublicCompatibilityFactsBlocked == false &&
        compatibility.shouldReportQueuePublicCompatibilityFactsIncompatible == false &&
        compatibility.shouldReportQueuePublicCompatibilityFactsUnauthorized == false
    let compatibilityDeferred = compatibility.didRecordQueuePublicCompatibilityFacts == false &&
        compatibility.hasStableQueuePublicApiCompatibilityPromise == false &&
        compatibility.didPreserveQueuePublicSurfacePolicy == false &&
        compatibility.didPreserveQueuePublicSurfaceInternalGateLinkage == false &&
        compatibility.didPreservePreviousQueueStoreSnapshot &&
        compatibility.shouldDeferQueuePublicCompatibilityFacts &&
        compatibility.shouldReportQueuePublicCompatibilityFactsBlocked == false
    let compatibilityInconsistent = (
        compatibility.didRecordQueuePublicCompatibilityFacts &&
            (
                compatibility.hasStableQueuePublicApiCompatibilityPromise ||
                compatibility.shouldDeferQueuePublicCompatibilityFacts ||
                compatibility.shouldReportQueuePublicCompatibilityFactsBlocked ||
                compatibility.shouldReportQueuePublicCompatibilityFactsIncompatible ||
                compatibility.shouldReportQueuePublicCompatibilityFactsUnauthorized
            )
        ) ||
        (compatibility.didPreserveQueuePublicSurfacePolicy &&
            compatibility.didRecordQueuePublicCompatibilityFacts == false) ||
        (compatibility.didPreserveQueuePublicSurfacePolicy == false &&
            compatibility.didRecordQueuePublicCompatibilityFacts) ||
        (compatibility.didPreserveQueuePublicSurfaceInternalGateLinkage &&
            compatibility.didRecordQueuePublicCompatibilityFacts == false) ||
        (compatibility.didPreserveQueuePublicSurfaceInternalGateLinkage == false &&
            compatibility.didRecordQueuePublicCompatibilityFacts) ||
        (compatibility.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            compatibility.shouldDeferQueuePublicCompatibilityFacts &&
            compatibility.shouldReportQueuePublicCompatibilityFactsBlocked
        )

    // compatibility facts 不一致时必须 fail-closed，但仍以内部 error contract value facts 记录拒绝原因。
    if (
        compatibility.shouldReportQueuePublicCompatibilityFactsBlocked ||
        compatibility.shouldReportQueuePublicCompatibilityFactsIncompatible ||
        compatibility.shouldReportQueuePublicCompatibilityFactsUnauthorized ||
        compatibilityInconsistent
    ) {
        return CjguiInternalQueuePublicErrorContract(
            compatibility,
            false,
            true,
            false,
            true,
            compatibility.shouldReportQueuePublicCompatibilityFactsIncompatible || compatibilityInconsistent,
            compatibility.shouldReportQueuePublicCompatibilityFactsUnauthorized,
            false,
            false,
            compatibility.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (compatibilityReady) {
        return CjguiInternalQueuePublicErrorContract(compatibility, true, true, false, false, false, false, true, true, true)
    }

    if (compatibilityDeferred) {
        return CjguiInternalQueuePublicErrorContract(
            compatibility,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicErrorContract(
        compatibility,
        false,
        true,
        false,
        true,
        true,
        false,
        false,
        false,
        compatibility.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicAuditRequirement(
    errorContract: CjguiInternalQueuePublicErrorContract
): CjguiInternalQueuePublicAuditRequirement {
    let contractReady = errorContract.didPrepareQueuePublicErrorContract &&
        errorContract.didMapQueuePublicErrorsAsValueFacts &&
        errorContract.didPreserveQueuePublicCompatibilityFacts &&
        errorContract.didPreserveQueuePublicSurfaceInternalGateLinkage &&
        errorContract.didPreservePreviousQueueStoreSnapshot &&
        errorContract.shouldDeferQueuePublicErrorContract == false &&
        errorContract.shouldReportQueuePublicErrorContractBlocked == false &&
        errorContract.shouldReportQueuePublicErrorContractIncompatible == false &&
        errorContract.shouldReportQueuePublicErrorContractUnauthorized == false
    let contractDeferred = errorContract.didPrepareQueuePublicErrorContract == false &&
        errorContract.didMapQueuePublicErrorsAsValueFacts == false &&
        errorContract.didPreserveQueuePublicCompatibilityFacts == false &&
        errorContract.didPreserveQueuePublicSurfaceInternalGateLinkage == false &&
        errorContract.didPreservePreviousQueueStoreSnapshot &&
        errorContract.shouldDeferQueuePublicErrorContract &&
        errorContract.shouldReportQueuePublicErrorContractBlocked == false
    let contractInconsistent = (
        errorContract.didPrepareQueuePublicErrorContract &&
            (
                errorContract.didMapQueuePublicErrorsAsValueFacts == false ||
                errorContract.shouldDeferQueuePublicErrorContract ||
                errorContract.shouldReportQueuePublicErrorContractBlocked ||
                errorContract.shouldReportQueuePublicErrorContractIncompatible ||
                errorContract.shouldReportQueuePublicErrorContractUnauthorized
            )
        ) ||
        (errorContract.didMapQueuePublicErrorsAsValueFacts &&
            errorContract.shouldDeferQueuePublicErrorContract) ||
        (errorContract.didPreserveQueuePublicCompatibilityFacts &&
            errorContract.didPrepareQueuePublicErrorContract == false) ||
        (errorContract.didPreserveQueuePublicCompatibilityFacts == false &&
            errorContract.didPrepareQueuePublicErrorContract) ||
        (errorContract.didPreserveQueuePublicSurfaceInternalGateLinkage &&
            errorContract.didPrepareQueuePublicErrorContract == false) ||
        (errorContract.didPreserveQueuePublicSurfaceInternalGateLinkage == false &&
            errorContract.didPrepareQueuePublicErrorContract) ||
        (errorContract.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            errorContract.shouldDeferQueuePublicErrorContract &&
            errorContract.shouldReportQueuePublicErrorContractBlocked
        )

    // error contract 不一致时必须 fail-closed，audit requirement 不能变成 public audit log。
    if (
        errorContract.shouldReportQueuePublicErrorContractBlocked ||
        errorContract.shouldReportQueuePublicErrorContractIncompatible ||
        errorContract.shouldReportQueuePublicErrorContractUnauthorized ||
        contractInconsistent
    ) {
        return CjguiInternalQueuePublicAuditRequirement(
            errorContract,
            false,
            false,
            false,
            false,
            true,
            errorContract.shouldReportQueuePublicErrorContractIncompatible || contractInconsistent,
            errorContract.shouldReportQueuePublicErrorContractUnauthorized,
            false,
            errorContract.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (contractReady) {
        return CjguiInternalQueuePublicAuditRequirement(errorContract, true, true, true, false, false, false, false, true, true)
    }

    if (contractDeferred) {
        return CjguiInternalQueuePublicAuditRequirement(
            errorContract,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicAuditRequirement(
        errorContract,
        false,
        false,
        false,
        false,
        true,
        true,
        false,
        false,
        errorContract.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicApiReadinessCandidate(
    auditRequirement: CjguiInternalQueuePublicAuditRequirement
): CjguiInternalQueuePublicApiReadinessCandidate {
    let auditReady = auditRequirement.didRequireQueuePublicAudit &&
        auditRequirement.didRequireQueuePublicPermissionLinkage &&
        auditRequirement.didRequireQueuePublicRollbackLinkage &&
        auditRequirement.didPreserveQueuePublicErrorContract &&
        auditRequirement.didPreservePreviousQueueStoreSnapshot &&
        auditRequirement.shouldDeferQueuePublicAuditRequirement == false &&
        auditRequirement.shouldReportQueuePublicAuditRequirementBlocked == false &&
        auditRequirement.shouldReportQueuePublicAuditRequirementIncompatible == false &&
        auditRequirement.shouldReportQueuePublicAuditRequirementUnauthorized == false
    let auditDeferred = auditRequirement.didRequireQueuePublicAudit == false &&
        auditRequirement.didRequireQueuePublicPermissionLinkage == false &&
        auditRequirement.didRequireQueuePublicRollbackLinkage == false &&
        auditRequirement.didPreserveQueuePublicErrorContract == false &&
        auditRequirement.didPreservePreviousQueueStoreSnapshot &&
        auditRequirement.shouldDeferQueuePublicAuditRequirement &&
        auditRequirement.shouldReportQueuePublicAuditRequirementBlocked == false
    let auditInconsistent = (
        auditRequirement.didRequireQueuePublicAudit &&
            (
                auditRequirement.didRequireQueuePublicPermissionLinkage == false ||
                auditRequirement.didRequireQueuePublicRollbackLinkage == false ||
                auditRequirement.shouldDeferQueuePublicAuditRequirement ||
                auditRequirement.shouldReportQueuePublicAuditRequirementBlocked ||
                auditRequirement.shouldReportQueuePublicAuditRequirementIncompatible ||
                auditRequirement.shouldReportQueuePublicAuditRequirementUnauthorized
            )
        ) ||
        (auditRequirement.didPreserveQueuePublicErrorContract &&
            auditRequirement.didRequireQueuePublicAudit == false) ||
        (auditRequirement.didPreserveQueuePublicErrorContract == false &&
            auditRequirement.didRequireQueuePublicAudit) ||
        (auditRequirement.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            auditRequirement.shouldDeferQueuePublicAuditRequirement &&
            auditRequirement.shouldReportQueuePublicAuditRequirementBlocked
        )

    // audit / permission / rollback facts 不一致时必须 fail-closed，API readiness candidate 不能被误当成 API ready。
    if (
        auditRequirement.shouldReportQueuePublicAuditRequirementBlocked ||
        auditRequirement.shouldReportQueuePublicAuditRequirementIncompatible ||
        auditRequirement.shouldReportQueuePublicAuditRequirementUnauthorized ||
        auditInconsistent
    ) {
        return CjguiInternalQueuePublicApiReadinessCandidate(
            auditRequirement,
            false,
            false,
            false,
            true,
            auditRequirement.shouldReportQueuePublicAuditRequirementIncompatible || auditInconsistent,
            auditRequirement.shouldReportQueuePublicAuditRequirementUnauthorized,
            false,
            false,
            auditRequirement.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (auditReady) {
        return CjguiInternalQueuePublicApiReadinessCandidate(
            auditRequirement,
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

    if (auditDeferred) {
        return CjguiInternalQueuePublicApiReadinessCandidate(
            auditRequirement,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicApiReadinessCandidate(
        auditRequirement,
        false,
        false,
        false,
        true,
        true,
        false,
        false,
        false,
        auditRequirement.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueuePublicSurfacePolicyDraft(): CjguiInternalQueuePublicApiReadinessCandidate {
    // 默认 draft 只串联 internal-only public surface policy value facts；不是 public API / C ABI，也不 real enqueue。
    let readiness = cjguiInternalExecuteDefaultQueuePublicBoundaryAdmissionDraft()
    let policy = cjguiInternalBuildQueuePublicSurfacePolicy(readiness)
    let compatibility = cjguiInternalBuildQueuePublicCompatibilityFacts(policy)
    let errorContract = cjguiInternalBuildQueuePublicErrorContract(compatibility)
    let auditRequirement = cjguiInternalBuildQueuePublicAuditRequirement(errorContract)
    return cjguiInternalBuildQueuePublicApiReadinessCandidate(auditRequirement)
}

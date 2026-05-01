package cjgui

// Internal Queue Public Submit Bool Result Hardening owner:
// - 本文件只消费 QueueExperimentalSubmitResult，不调用开放 shell 作为内部 truth。
// - Truth 是 Bool-only result contract / diagnostic projection / no-stable-compatibility /
//   no-real-queue-write guarantee value facts。
// - Stop-line: 这里不是新的开放符号，不改 Bool-only shell 签名，不返回 structured public result；
//   不做真实入队，不写 process-wide queue storage，不创建 global mutable queue / singleton，
//   不做 item collection mutation，不 drain，不接 scheduler / event loop / platform callback / runtime cycle，
//   不接收原始指针、原生句柄或平台对象，也不回塞 critical runtime_state.cj。

// Bool result contract 固定当前开放 shell 的 Bool-only 语义：
// true 只表示 internal readiness projection 可为真，不是稳定 API 成功结果。
struct CjguiInternalQueuePublicSubmitBoolResultContract {
    let result: CjguiInternalQueueExperimentalSubmitResult
    let didPrepareQueuePublicSubmitBoolResultContract: Bool
    let canProjectQueuePublicSubmitBoolReady: Bool
    let didKeepQueuePublicSubmitBoolOnlyResult: Bool
    let didPreserveQueueExperimentalSubmitResult: Bool
    let shouldDeferQueuePublicSubmitBoolResultContract: Bool
    let shouldReportQueuePublicSubmitBoolResultContractBlocked: Bool
    let shouldRejectQueuePublicSubmitBoolResultContract: Bool
    let shouldReportQueuePublicSubmitBoolResultContractIncompatible: Bool
    let shouldReportQueuePublicSubmitBoolResultContractUnauthorized: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        result: CjguiInternalQueueExperimentalSubmitResult,
        didPrepareQueuePublicSubmitBoolResultContract: Bool,
        canProjectQueuePublicSubmitBoolReady: Bool,
        didKeepQueuePublicSubmitBoolOnlyResult: Bool,
        didPreserveQueueExperimentalSubmitResult: Bool,
        shouldDeferQueuePublicSubmitBoolResultContract: Bool,
        shouldReportQueuePublicSubmitBoolResultContractBlocked: Bool,
        shouldRejectQueuePublicSubmitBoolResultContract: Bool,
        shouldReportQueuePublicSubmitBoolResultContractIncompatible: Bool,
        shouldReportQueuePublicSubmitBoolResultContractUnauthorized: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.result = result
        this.didPrepareQueuePublicSubmitBoolResultContract = didPrepareQueuePublicSubmitBoolResultContract
        this.canProjectQueuePublicSubmitBoolReady = canProjectQueuePublicSubmitBoolReady
        this.didKeepQueuePublicSubmitBoolOnlyResult = didKeepQueuePublicSubmitBoolOnlyResult
        this.didPreserveQueueExperimentalSubmitResult = didPreserveQueueExperimentalSubmitResult
        this.shouldDeferQueuePublicSubmitBoolResultContract = shouldDeferQueuePublicSubmitBoolResultContract
        this.shouldReportQueuePublicSubmitBoolResultContractBlocked =
            shouldReportQueuePublicSubmitBoolResultContractBlocked
        this.shouldRejectQueuePublicSubmitBoolResultContract = shouldRejectQueuePublicSubmitBoolResultContract
        this.shouldReportQueuePublicSubmitBoolResultContractIncompatible =
            shouldReportQueuePublicSubmitBoolResultContractIncompatible
        this.shouldReportQueuePublicSubmitBoolResultContractUnauthorized =
            shouldReportQueuePublicSubmitBoolResultContractUnauthorized
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Diagnostic projection 只解释 Bool shell 的诊断含义；
// 它不增加 structured public return，也不暴露 lower-level owner facts。
struct CjguiInternalQueuePublicSubmitDiagnosticProjection {
    let contract: CjguiInternalQueuePublicSubmitBoolResultContract
    let didPrepareQueuePublicSubmitDiagnosticProjection: Bool
    let didStateQueuePublicSubmitReadinessProjectionOnly: Bool
    let didAvoidQueuePublicSubmitStructuredReturn: Bool
    let didPreserveQueuePublicSubmitBoolResultContract: Bool
    let shouldDeferQueuePublicSubmitDiagnosticProjection: Bool
    let shouldReportQueuePublicSubmitDiagnosticProjectionBlocked: Bool
    let shouldRejectQueuePublicSubmitDiagnosticProjection: Bool
    let shouldReportQueuePublicSubmitDiagnosticProjectionIncompatible: Bool
    let shouldReportQueuePublicSubmitDiagnosticProjectionUnauthorized: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        contract: CjguiInternalQueuePublicSubmitBoolResultContract,
        didPrepareQueuePublicSubmitDiagnosticProjection: Bool,
        didStateQueuePublicSubmitReadinessProjectionOnly: Bool,
        didAvoidQueuePublicSubmitStructuredReturn: Bool,
        didPreserveQueuePublicSubmitBoolResultContract: Bool,
        shouldDeferQueuePublicSubmitDiagnosticProjection: Bool,
        shouldReportQueuePublicSubmitDiagnosticProjectionBlocked: Bool,
        shouldRejectQueuePublicSubmitDiagnosticProjection: Bool,
        shouldReportQueuePublicSubmitDiagnosticProjectionIncompatible: Bool,
        shouldReportQueuePublicSubmitDiagnosticProjectionUnauthorized: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.contract = contract
        this.didPrepareQueuePublicSubmitDiagnosticProjection = didPrepareQueuePublicSubmitDiagnosticProjection
        this.didStateQueuePublicSubmitReadinessProjectionOnly = didStateQueuePublicSubmitReadinessProjectionOnly
        this.didAvoidQueuePublicSubmitStructuredReturn = didAvoidQueuePublicSubmitStructuredReturn
        this.didPreserveQueuePublicSubmitBoolResultContract = didPreserveQueuePublicSubmitBoolResultContract
        this.shouldDeferQueuePublicSubmitDiagnosticProjection = shouldDeferQueuePublicSubmitDiagnosticProjection
        this.shouldReportQueuePublicSubmitDiagnosticProjectionBlocked =
            shouldReportQueuePublicSubmitDiagnosticProjectionBlocked
        this.shouldRejectQueuePublicSubmitDiagnosticProjection = shouldRejectQueuePublicSubmitDiagnosticProjection
        this.shouldReportQueuePublicSubmitDiagnosticProjectionIncompatible =
            shouldReportQueuePublicSubmitDiagnosticProjectionIncompatible
        this.shouldReportQueuePublicSubmitDiagnosticProjectionUnauthorized =
            shouldReportQueuePublicSubmitDiagnosticProjectionUnauthorized
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// No-stable-compatibility hardening 明确当前 Bool shell 仍不承诺稳定公开兼容性；
// 后续若要稳定 API contract，必须另开 decision。
struct CjguiInternalQueuePublicSubmitNoStableCompatibility {
    let projection: CjguiInternalQueuePublicSubmitDiagnosticProjection
    let didPrepareQueuePublicSubmitNoStableCompatibility: Bool
    let hasStableQueuePublicSubmitCompatibilityPromise: Bool
    let didStateQueuePublicSubmitCompatibilityPromiseAbsent: Bool
    let didPreserveQueuePublicSubmitDiagnosticProjection: Bool
    let shouldDeferQueuePublicSubmitNoStableCompatibility: Bool
    let shouldReportQueuePublicSubmitNoStableCompatibilityBlocked: Bool
    let shouldRejectQueuePublicSubmitNoStableCompatibility: Bool
    let shouldReportQueuePublicSubmitNoStableCompatibilityIncompatible: Bool
    let shouldReportQueuePublicSubmitNoStableCompatibilityUnauthorized: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        projection: CjguiInternalQueuePublicSubmitDiagnosticProjection,
        didPrepareQueuePublicSubmitNoStableCompatibility: Bool,
        hasStableQueuePublicSubmitCompatibilityPromise: Bool,
        didStateQueuePublicSubmitCompatibilityPromiseAbsent: Bool,
        didPreserveQueuePublicSubmitDiagnosticProjection: Bool,
        shouldDeferQueuePublicSubmitNoStableCompatibility: Bool,
        shouldReportQueuePublicSubmitNoStableCompatibilityBlocked: Bool,
        shouldRejectQueuePublicSubmitNoStableCompatibility: Bool,
        shouldReportQueuePublicSubmitNoStableCompatibilityIncompatible: Bool,
        shouldReportQueuePublicSubmitNoStableCompatibilityUnauthorized: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.projection = projection
        this.didPrepareQueuePublicSubmitNoStableCompatibility = didPrepareQueuePublicSubmitNoStableCompatibility
        this.hasStableQueuePublicSubmitCompatibilityPromise = hasStableQueuePublicSubmitCompatibilityPromise
        this.didStateQueuePublicSubmitCompatibilityPromiseAbsent =
            didStateQueuePublicSubmitCompatibilityPromiseAbsent
        this.didPreserveQueuePublicSubmitDiagnosticProjection =
            didPreserveQueuePublicSubmitDiagnosticProjection
        this.shouldDeferQueuePublicSubmitNoStableCompatibility =
            shouldDeferQueuePublicSubmitNoStableCompatibility
        this.shouldReportQueuePublicSubmitNoStableCompatibilityBlocked =
            shouldReportQueuePublicSubmitNoStableCompatibilityBlocked
        this.shouldRejectQueuePublicSubmitNoStableCompatibility =
            shouldRejectQueuePublicSubmitNoStableCompatibility
        this.shouldReportQueuePublicSubmitNoStableCompatibilityIncompatible =
            shouldReportQueuePublicSubmitNoStableCompatibilityIncompatible
        this.shouldReportQueuePublicSubmitNoStableCompatibilityUnauthorized =
            shouldReportQueuePublicSubmitNoStableCompatibilityUnauthorized
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// No-real-queue-write guarantee 是本轮 canonical endpoint；
// 它明确 Bool shell result 不是实际队列写入、不是 C 层二进制接口、也不是公开副作用。
struct CjguiInternalQueuePublicSubmitNoQueueWriteGuarantee {
    let compatibility: CjguiInternalQueuePublicSubmitNoStableCompatibility
    let didPrepareQueuePublicSubmitNoQueueWriteGuarantee: Bool
    let didStateQueuePublicSubmitHasNoRealQueueWrite: Bool
    let didStateQueuePublicSubmitHasNoPublicSideEffect: Bool
    let didPreserveQueuePublicSubmitNoStableCompatibility: Bool
    let shouldDeferQueuePublicSubmitNoQueueWriteGuarantee: Bool
    let shouldReportQueuePublicSubmitNoQueueWriteGuaranteeBlocked: Bool
    let shouldRejectQueuePublicSubmitNoQueueWriteGuarantee: Bool
    let shouldReportQueuePublicSubmitNoQueueWriteGuaranteeIncompatible: Bool
    let shouldReportQueuePublicSubmitNoQueueWriteGuaranteeUnauthorized: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        compatibility: CjguiInternalQueuePublicSubmitNoStableCompatibility,
        didPrepareQueuePublicSubmitNoQueueWriteGuarantee: Bool,
        didStateQueuePublicSubmitHasNoRealQueueWrite: Bool,
        didStateQueuePublicSubmitHasNoPublicSideEffect: Bool,
        didPreserveQueuePublicSubmitNoStableCompatibility: Bool,
        shouldDeferQueuePublicSubmitNoQueueWriteGuarantee: Bool,
        shouldReportQueuePublicSubmitNoQueueWriteGuaranteeBlocked: Bool,
        shouldRejectQueuePublicSubmitNoQueueWriteGuarantee: Bool,
        shouldReportQueuePublicSubmitNoQueueWriteGuaranteeIncompatible: Bool,
        shouldReportQueuePublicSubmitNoQueueWriteGuaranteeUnauthorized: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.compatibility = compatibility
        this.didPrepareQueuePublicSubmitNoQueueWriteGuarantee =
            didPrepareQueuePublicSubmitNoQueueWriteGuarantee
        this.didStateQueuePublicSubmitHasNoRealQueueWrite = didStateQueuePublicSubmitHasNoRealQueueWrite
        this.didStateQueuePublicSubmitHasNoPublicSideEffect = didStateQueuePublicSubmitHasNoPublicSideEffect
        this.didPreserveQueuePublicSubmitNoStableCompatibility =
            didPreserveQueuePublicSubmitNoStableCompatibility
        this.shouldDeferQueuePublicSubmitNoQueueWriteGuarantee =
            shouldDeferQueuePublicSubmitNoQueueWriteGuarantee
        this.shouldReportQueuePublicSubmitNoQueueWriteGuaranteeBlocked =
            shouldReportQueuePublicSubmitNoQueueWriteGuaranteeBlocked
        this.shouldRejectQueuePublicSubmitNoQueueWriteGuarantee =
            shouldRejectQueuePublicSubmitNoQueueWriteGuarantee
        this.shouldReportQueuePublicSubmitNoQueueWriteGuaranteeIncompatible =
            shouldReportQueuePublicSubmitNoQueueWriteGuaranteeIncompatible
        this.shouldReportQueuePublicSubmitNoQueueWriteGuaranteeUnauthorized =
            shouldReportQueuePublicSubmitNoQueueWriteGuaranteeUnauthorized
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueuePublicSubmitBoolResultContract(
    result: CjguiInternalQueueExperimentalSubmitResult
): CjguiInternalQueuePublicSubmitBoolResultContract {
    let resultAccepted = result.didPrepareQueueExperimentalSubmitResult &&
        result.didReportQueueExperimentalSubmitAccepted &&
        result.didProjectQueueExperimentalSubmitResultEnvelope &&
        result.didAvoidStableQueuePublicApiCompatibilityPromise &&
        result.didPreserveQueueExperimentalSubmitAdmission &&
        result.didPreservePreviousQueueStoreSnapshot &&
        result.didReportQueueExperimentalSubmitDeferred == false &&
        result.didReportQueueExperimentalSubmitBlocked == false &&
        result.didReportQueueExperimentalSubmitRejected == false &&
        result.didReportQueueExperimentalSubmitIncompatible == false &&
        result.didReportQueueExperimentalSubmitUnauthorized == false
    let resultDeferred = result.didPrepareQueueExperimentalSubmitResult == false &&
        result.didReportQueueExperimentalSubmitAccepted == false &&
        result.didReportQueueExperimentalSubmitDeferred &&
        result.didReportQueueExperimentalSubmitBlocked == false &&
        result.didReportQueueExperimentalSubmitRejected == false &&
        result.didReportQueueExperimentalSubmitIncompatible == false &&
        result.didReportQueueExperimentalSubmitUnauthorized == false &&
        result.didProjectQueueExperimentalSubmitResultEnvelope &&
        result.didAvoidStableQueuePublicApiCompatibilityPromise &&
        result.didPreservePreviousQueueStoreSnapshot
    let resultInconsistent = (
        result.didReportQueueExperimentalSubmitAccepted &&
            (
                result.didPrepareQueueExperimentalSubmitResult == false ||
                result.didProjectQueueExperimentalSubmitResultEnvelope == false ||
                result.didAvoidStableQueuePublicApiCompatibilityPromise == false ||
                result.didPreserveQueueExperimentalSubmitAdmission == false ||
                result.didReportQueueExperimentalSubmitDeferred ||
                result.didReportQueueExperimentalSubmitBlocked ||
                result.didReportQueueExperimentalSubmitRejected ||
                result.didReportQueueExperimentalSubmitIncompatible ||
                result.didReportQueueExperimentalSubmitUnauthorized
            )
        ) ||
        (result.didAvoidStableQueuePublicApiCompatibilityPromise == false) ||
        (result.didProjectQueueExperimentalSubmitResultEnvelope == false) ||
        (result.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            result.didReportQueueExperimentalSubmitDeferred &&
            (
                result.didReportQueueExperimentalSubmitBlocked ||
                result.didReportQueueExperimentalSubmitRejected ||
                result.didReportQueueExperimentalSubmitIncompatible ||
                result.didReportQueueExperimentalSubmitUnauthorized
            )
        )

    // experimental submit result 不一致时必须 fail-closed，Bool contract 不能伪造 ready true。
    if (
        result.didReportQueueExperimentalSubmitBlocked ||
        result.didReportQueueExperimentalSubmitRejected ||
        result.didReportQueueExperimentalSubmitIncompatible ||
        result.didReportQueueExperimentalSubmitUnauthorized ||
        resultInconsistent
    ) {
        return CjguiInternalQueuePublicSubmitBoolResultContract(
            result,
            false,
            false,
            true,
            false,
            false,
            true,
            true,
            result.didReportQueueExperimentalSubmitIncompatible || resultInconsistent,
            result.didReportQueueExperimentalSubmitUnauthorized,
            result.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (resultAccepted) {
        return CjguiInternalQueuePublicSubmitBoolResultContract(
            result,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    if (resultDeferred) {
        return CjguiInternalQueuePublicSubmitBoolResultContract(
            result,
            false,
            false,
            true,
            false,
            true,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicSubmitBoolResultContract(
        result,
        false,
        false,
        true,
        false,
        false,
        true,
        true,
        true,
        false,
        result.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicSubmitDiagnosticProjection(
    contract: CjguiInternalQueuePublicSubmitBoolResultContract
): CjguiInternalQueuePublicSubmitDiagnosticProjection {
    let contractReady = contract.didPrepareQueuePublicSubmitBoolResultContract &&
        contract.canProjectQueuePublicSubmitBoolReady &&
        contract.didKeepQueuePublicSubmitBoolOnlyResult &&
        contract.didPreserveQueueExperimentalSubmitResult &&
        contract.didPreservePreviousQueueStoreSnapshot &&
        contract.shouldDeferQueuePublicSubmitBoolResultContract == false &&
        contract.shouldReportQueuePublicSubmitBoolResultContractBlocked == false &&
        contract.shouldRejectQueuePublicSubmitBoolResultContract == false &&
        contract.shouldReportQueuePublicSubmitBoolResultContractIncompatible == false &&
        contract.shouldReportQueuePublicSubmitBoolResultContractUnauthorized == false
    let contractDeferred = contract.didPrepareQueuePublicSubmitBoolResultContract == false &&
        contract.canProjectQueuePublicSubmitBoolReady == false &&
        contract.didKeepQueuePublicSubmitBoolOnlyResult &&
        contract.didPreserveQueueExperimentalSubmitResult == false &&
        contract.didPreservePreviousQueueStoreSnapshot &&
        contract.shouldDeferQueuePublicSubmitBoolResultContract &&
        contract.shouldReportQueuePublicSubmitBoolResultContractBlocked == false &&
        contract.shouldRejectQueuePublicSubmitBoolResultContract == false &&
        contract.shouldReportQueuePublicSubmitBoolResultContractIncompatible == false &&
        contract.shouldReportQueuePublicSubmitBoolResultContractUnauthorized == false
    let contractInconsistent = (
        contract.didPrepareQueuePublicSubmitBoolResultContract &&
            (
                contract.canProjectQueuePublicSubmitBoolReady == false ||
                contract.didKeepQueuePublicSubmitBoolOnlyResult == false ||
                contract.didPreserveQueueExperimentalSubmitResult == false ||
                contract.shouldDeferQueuePublicSubmitBoolResultContract ||
                contract.shouldReportQueuePublicSubmitBoolResultContractBlocked ||
                contract.shouldRejectQueuePublicSubmitBoolResultContract ||
                contract.shouldReportQueuePublicSubmitBoolResultContractIncompatible ||
                contract.shouldReportQueuePublicSubmitBoolResultContractUnauthorized
            )
        ) ||
        (contract.didKeepQueuePublicSubmitBoolOnlyResult == false) ||
        (contract.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            contract.shouldDeferQueuePublicSubmitBoolResultContract &&
            (
                contract.shouldReportQueuePublicSubmitBoolResultContractBlocked ||
                contract.shouldRejectQueuePublicSubmitBoolResultContract ||
                contract.shouldReportQueuePublicSubmitBoolResultContractIncompatible ||
                contract.shouldReportQueuePublicSubmitBoolResultContractUnauthorized
            )
        )

    // Bool contract 不一致时必须 fail-closed，diagnostic projection 不能升级为 structured result。
    if (
        contract.shouldReportQueuePublicSubmitBoolResultContractBlocked ||
        contract.shouldRejectQueuePublicSubmitBoolResultContract ||
        contract.shouldReportQueuePublicSubmitBoolResultContractIncompatible ||
        contract.shouldReportQueuePublicSubmitBoolResultContractUnauthorized ||
        contractInconsistent
    ) {
        return CjguiInternalQueuePublicSubmitDiagnosticProjection(
            contract,
            false,
            true,
            true,
            false,
            false,
            true,
            true,
            contract.shouldReportQueuePublicSubmitBoolResultContractIncompatible || contractInconsistent,
            contract.shouldReportQueuePublicSubmitBoolResultContractUnauthorized,
            contract.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (contractReady) {
        return CjguiInternalQueuePublicSubmitDiagnosticProjection(
            contract,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    if (contractDeferred) {
        return CjguiInternalQueuePublicSubmitDiagnosticProjection(
            contract,
            false,
            true,
            true,
            false,
            true,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicSubmitDiagnosticProjection(
        contract,
        false,
        true,
        true,
        false,
        false,
        true,
        true,
        true,
        false,
        contract.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicSubmitNoStableCompatibility(
    projection: CjguiInternalQueuePublicSubmitDiagnosticProjection
): CjguiInternalQueuePublicSubmitNoStableCompatibility {
    let projectionReady = projection.didPrepareQueuePublicSubmitDiagnosticProjection &&
        projection.didStateQueuePublicSubmitReadinessProjectionOnly &&
        projection.didAvoidQueuePublicSubmitStructuredReturn &&
        projection.didPreserveQueuePublicSubmitBoolResultContract &&
        projection.didPreservePreviousQueueStoreSnapshot &&
        projection.shouldDeferQueuePublicSubmitDiagnosticProjection == false &&
        projection.shouldReportQueuePublicSubmitDiagnosticProjectionBlocked == false &&
        projection.shouldRejectQueuePublicSubmitDiagnosticProjection == false &&
        projection.shouldReportQueuePublicSubmitDiagnosticProjectionIncompatible == false &&
        projection.shouldReportQueuePublicSubmitDiagnosticProjectionUnauthorized == false
    let projectionDeferred = projection.didPrepareQueuePublicSubmitDiagnosticProjection == false &&
        projection.didStateQueuePublicSubmitReadinessProjectionOnly &&
        projection.didAvoidQueuePublicSubmitStructuredReturn &&
        projection.didPreserveQueuePublicSubmitBoolResultContract == false &&
        projection.didPreservePreviousQueueStoreSnapshot &&
        projection.shouldDeferQueuePublicSubmitDiagnosticProjection &&
        projection.shouldReportQueuePublicSubmitDiagnosticProjectionBlocked == false &&
        projection.shouldRejectQueuePublicSubmitDiagnosticProjection == false &&
        projection.shouldReportQueuePublicSubmitDiagnosticProjectionIncompatible == false &&
        projection.shouldReportQueuePublicSubmitDiagnosticProjectionUnauthorized == false
    let projectionInconsistent = (
        projection.didPrepareQueuePublicSubmitDiagnosticProjection &&
            (
                projection.didStateQueuePublicSubmitReadinessProjectionOnly == false ||
                projection.didAvoidQueuePublicSubmitStructuredReturn == false ||
                projection.didPreserveQueuePublicSubmitBoolResultContract == false ||
                projection.shouldDeferQueuePublicSubmitDiagnosticProjection ||
                projection.shouldReportQueuePublicSubmitDiagnosticProjectionBlocked ||
                projection.shouldRejectQueuePublicSubmitDiagnosticProjection ||
                projection.shouldReportQueuePublicSubmitDiagnosticProjectionIncompatible ||
                projection.shouldReportQueuePublicSubmitDiagnosticProjectionUnauthorized
            )
        ) ||
        (projection.didStateQueuePublicSubmitReadinessProjectionOnly == false) ||
        (projection.didAvoidQueuePublicSubmitStructuredReturn == false) ||
        (projection.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            projection.shouldDeferQueuePublicSubmitDiagnosticProjection &&
            (
                projection.shouldReportQueuePublicSubmitDiagnosticProjectionBlocked ||
                projection.shouldRejectQueuePublicSubmitDiagnosticProjection ||
                projection.shouldReportQueuePublicSubmitDiagnosticProjectionIncompatible ||
                projection.shouldReportQueuePublicSubmitDiagnosticProjectionUnauthorized
            )
        )

    // diagnostic projection 不一致时必须 fail-closed，不能伪造无稳定兼容承诺已满足。
    if (
        projection.shouldReportQueuePublicSubmitDiagnosticProjectionBlocked ||
        projection.shouldRejectQueuePublicSubmitDiagnosticProjection ||
        projection.shouldReportQueuePublicSubmitDiagnosticProjectionIncompatible ||
        projection.shouldReportQueuePublicSubmitDiagnosticProjectionUnauthorized ||
        projectionInconsistent
    ) {
        return CjguiInternalQueuePublicSubmitNoStableCompatibility(
            projection,
            false,
            false,
            true,
            false,
            false,
            true,
            true,
            projection.shouldReportQueuePublicSubmitDiagnosticProjectionIncompatible || projectionInconsistent,
            projection.shouldReportQueuePublicSubmitDiagnosticProjectionUnauthorized,
            projection.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (projectionReady) {
        return CjguiInternalQueuePublicSubmitNoStableCompatibility(
            projection,
            true,
            false,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    if (projectionDeferred) {
        return CjguiInternalQueuePublicSubmitNoStableCompatibility(
            projection,
            false,
            false,
            true,
            false,
            true,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicSubmitNoStableCompatibility(
        projection,
        false,
        false,
        true,
        false,
        false,
        true,
        true,
        true,
        false,
        projection.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicSubmitNoQueueWriteGuarantee(
    compatibility: CjguiInternalQueuePublicSubmitNoStableCompatibility
): CjguiInternalQueuePublicSubmitNoQueueWriteGuarantee {
    let compatibilityReady = compatibility.didPrepareQueuePublicSubmitNoStableCompatibility &&
        compatibility.hasStableQueuePublicSubmitCompatibilityPromise == false &&
        compatibility.didStateQueuePublicSubmitCompatibilityPromiseAbsent &&
        compatibility.didPreserveQueuePublicSubmitDiagnosticProjection &&
        compatibility.didPreservePreviousQueueStoreSnapshot &&
        compatibility.shouldDeferQueuePublicSubmitNoStableCompatibility == false &&
        compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityBlocked == false &&
        compatibility.shouldRejectQueuePublicSubmitNoStableCompatibility == false &&
        compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityIncompatible == false &&
        compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityUnauthorized == false
    let compatibilityDeferred = compatibility.didPrepareQueuePublicSubmitNoStableCompatibility == false &&
        compatibility.hasStableQueuePublicSubmitCompatibilityPromise == false &&
        compatibility.didStateQueuePublicSubmitCompatibilityPromiseAbsent &&
        compatibility.didPreserveQueuePublicSubmitDiagnosticProjection == false &&
        compatibility.didPreservePreviousQueueStoreSnapshot &&
        compatibility.shouldDeferQueuePublicSubmitNoStableCompatibility &&
        compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityBlocked == false &&
        compatibility.shouldRejectQueuePublicSubmitNoStableCompatibility == false &&
        compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityIncompatible == false &&
        compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityUnauthorized == false
    let compatibilityInconsistent = (
        compatibility.didPrepareQueuePublicSubmitNoStableCompatibility &&
            (
                compatibility.hasStableQueuePublicSubmitCompatibilityPromise ||
                compatibility.didStateQueuePublicSubmitCompatibilityPromiseAbsent == false ||
                compatibility.didPreserveQueuePublicSubmitDiagnosticProjection == false ||
                compatibility.shouldDeferQueuePublicSubmitNoStableCompatibility ||
                compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityBlocked ||
                compatibility.shouldRejectQueuePublicSubmitNoStableCompatibility ||
                compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityIncompatible ||
                compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityUnauthorized
            )
        ) ||
        (compatibility.hasStableQueuePublicSubmitCompatibilityPromise) ||
        (compatibility.didStateQueuePublicSubmitCompatibilityPromiseAbsent == false) ||
        (compatibility.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            compatibility.shouldDeferQueuePublicSubmitNoStableCompatibility &&
            (
                compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityBlocked ||
                compatibility.shouldRejectQueuePublicSubmitNoStableCompatibility ||
                compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityIncompatible ||
                compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityUnauthorized
            )
        )

    // no-stable-compatibility facts 不一致时必须 fail-closed，不能伪造无真实队列写入保证。
    if (
        compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityBlocked ||
        compatibility.shouldRejectQueuePublicSubmitNoStableCompatibility ||
        compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityIncompatible ||
        compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityUnauthorized ||
        compatibilityInconsistent
    ) {
        return CjguiInternalQueuePublicSubmitNoQueueWriteGuarantee(
            compatibility,
            false,
            true,
            true,
            false,
            false,
            true,
            true,
            compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityIncompatible ||
                compatibilityInconsistent,
            compatibility.shouldReportQueuePublicSubmitNoStableCompatibilityUnauthorized,
            compatibility.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (compatibilityReady) {
        return CjguiInternalQueuePublicSubmitNoQueueWriteGuarantee(
            compatibility,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    if (compatibilityDeferred) {
        return CjguiInternalQueuePublicSubmitNoQueueWriteGuarantee(
            compatibility,
            false,
            true,
            true,
            false,
            true,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueuePublicSubmitNoQueueWriteGuarantee(
        compatibility,
        false,
        true,
        true,
        false,
        false,
        true,
        true,
        true,
        false,
        compatibility.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueuePublicSubmitBoolResultHardeningDraft(
): CjguiInternalQueuePublicSubmitNoQueueWriteGuarantee {
    // 默认 draft 只串联 Bool result hardening facts；
    // 不是新的开放 API，不是真实入队，也不写任何队列 storage。
    let result = cjguiInternalExecuteDefaultQueueExperimentalSubmitShellDraft()
    let contract = cjguiInternalBuildQueuePublicSubmitBoolResultContract(result)
    let projection = cjguiInternalBuildQueuePublicSubmitDiagnosticProjection(contract)
    let compatibility = cjguiInternalBuildQueuePublicSubmitNoStableCompatibility(projection)
    return cjguiInternalBuildQueuePublicSubmitNoQueueWriteGuarantee(compatibility)
}

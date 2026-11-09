package cjgui

// Internal Queue Public API Admission owner:
// - 本文件只消费 QueuePublicApiReadinessCandidate。
// - Truth 是 future public API surface 前置的 submission request / admission / result 内部 value facts。
// - Stop-line: public API admission facts 不是 public runtime API / C ABI，也不是真实 enqueue；不接收 raw pointer /
//   native handle、不写 process-wide queue storage、不创建 global mutable queue / singleton、不做 item collection mutation、
//   不 drain、不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Public submission request 只表达 future API surface 的内部 request facts；
// 它不是 public API function，也不承诺真实 enqueue side effect。
struct CjguiInternalQueuePublicSubmissionRequest {
    let candidate: CjguiInternalQueuePublicApiReadinessCandidate
    let didCreateQueuePublicSubmissionRequest: Bool
    let didUseQueueSubmissionTerminology: Bool
    let shouldDeferQueuePublicSubmissionRequest: Bool
    let shouldReportQueuePublicSubmissionRequestBlocked: Bool
    let shouldRejectQueuePublicSubmissionRequest: Bool
    let shouldReportQueuePublicSubmissionRequestIncompatible: Bool
    let shouldReportQueuePublicSubmissionRequestUnauthorized: Bool
    let didPreserveQueuePublicApiReadinessCandidate: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        candidate: CjguiInternalQueuePublicApiReadinessCandidate,
        didCreateQueuePublicSubmissionRequest: Bool,
        didUseQueueSubmissionTerminology: Bool,
        shouldDeferQueuePublicSubmissionRequest: Bool,
        shouldReportQueuePublicSubmissionRequestBlocked: Bool,
        shouldRejectQueuePublicSubmissionRequest: Bool,
        shouldReportQueuePublicSubmissionRequestIncompatible: Bool,
        shouldReportQueuePublicSubmissionRequestUnauthorized: Bool,
        didPreserveQueuePublicApiReadinessCandidate: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.candidate = candidate
        this.didCreateQueuePublicSubmissionRequest = didCreateQueuePublicSubmissionRequest
        this.didUseQueueSubmissionTerminology = didUseQueueSubmissionTerminology
        this.shouldDeferQueuePublicSubmissionRequest = shouldDeferQueuePublicSubmissionRequest
        this.shouldReportQueuePublicSubmissionRequestBlocked = shouldReportQueuePublicSubmissionRequestBlocked
        this.shouldRejectQueuePublicSubmissionRequest = shouldRejectQueuePublicSubmissionRequest
        this.shouldReportQueuePublicSubmissionRequestIncompatible =
            shouldReportQueuePublicSubmissionRequestIncompatible
        this.shouldReportQueuePublicSubmissionRequestUnauthorized =
            shouldReportQueuePublicSubmissionRequestUnauthorized
        this.didPreserveQueuePublicApiReadinessCandidate = didPreserveQueuePublicApiReadinessCandidate
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Public API admission 只说明 submission request 是否可进入下一段内部 API-admission 评估；
// 它不是 public API admission side effect，也不是 C ABI 或真实 enqueue permission。
struct CjguiInternalQueuePublicApiAdmission {
    let request: CjguiInternalQueuePublicSubmissionRequest
    let didAdmitQueuePublicApiSubmissionRequest: Bool
    let shouldDeferQueuePublicApiAdmission: Bool
    let shouldReportQueuePublicApiAdmissionBlocked: Bool
    let shouldRejectQueuePublicApiAdmission: Bool
    let shouldReportQueuePublicApiAdmissionIncompatible: Bool
    let shouldReportQueuePublicApiAdmissionUnauthorized: Bool
    let didPreserveQueuePublicSubmissionRequest: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        request: CjguiInternalQueuePublicSubmissionRequest,
        didAdmitQueuePublicApiSubmissionRequest: Bool,
        shouldDeferQueuePublicApiAdmission: Bool,
        shouldReportQueuePublicApiAdmissionBlocked: Bool,
        shouldRejectQueuePublicApiAdmission: Bool,
        shouldReportQueuePublicApiAdmissionIncompatible: Bool,
        shouldReportQueuePublicApiAdmissionUnauthorized: Bool,
        didPreserveQueuePublicSubmissionRequest: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.request = request
        this.didAdmitQueuePublicApiSubmissionRequest = didAdmitQueuePublicApiSubmissionRequest
        this.shouldDeferQueuePublicApiAdmission = shouldDeferQueuePublicApiAdmission
        this.shouldReportQueuePublicApiAdmissionBlocked = shouldReportQueuePublicApiAdmissionBlocked
        this.shouldRejectQueuePublicApiAdmission = shouldRejectQueuePublicApiAdmission
        this.shouldReportQueuePublicApiAdmissionIncompatible = shouldReportQueuePublicApiAdmissionIncompatible
        this.shouldReportQueuePublicApiAdmissionUnauthorized = shouldReportQueuePublicApiAdmissionUnauthorized
        this.didPreserveQueuePublicSubmissionRequest = didPreserveQueuePublicSubmissionRequest
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Public API result 是本轮 canonical endpoint；它只记录 accepted / deferred / blocked / rejected 等内部 facts，
// 不是 public API response、C ABI result，也不执行 real enqueue。
struct CjguiInternalQueuePublicApiResult {
    let admission: CjguiInternalQueuePublicApiAdmission
    let didAcceptQueuePublicApiSubmission: Bool
    let shouldDeferQueuePublicApiResult: Bool
    let shouldReportQueuePublicApiResultBlocked: Bool
    let shouldRejectQueuePublicApiResult: Bool
    let shouldReportQueuePublicApiResultIncompatible: Bool
    let shouldReportQueuePublicApiResultUnauthorized: Bool
    let didPreserveQueuePublicApiAdmission: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        admission: CjguiInternalQueuePublicApiAdmission,
        didAcceptQueuePublicApiSubmission: Bool,
        shouldDeferQueuePublicApiResult: Bool,
        shouldReportQueuePublicApiResultBlocked: Bool,
        shouldRejectQueuePublicApiResult: Bool,
        shouldReportQueuePublicApiResultIncompatible: Bool,
        shouldReportQueuePublicApiResultUnauthorized: Bool,
        didPreserveQueuePublicApiAdmission: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.admission = admission
        this.didAcceptQueuePublicApiSubmission = didAcceptQueuePublicApiSubmission
        this.shouldDeferQueuePublicApiResult = shouldDeferQueuePublicApiResult
        this.shouldReportQueuePublicApiResultBlocked = shouldReportQueuePublicApiResultBlocked
        this.shouldRejectQueuePublicApiResult = shouldRejectQueuePublicApiResult
        this.shouldReportQueuePublicApiResultIncompatible = shouldReportQueuePublicApiResultIncompatible
        this.shouldReportQueuePublicApiResultUnauthorized = shouldReportQueuePublicApiResultUnauthorized
        this.didPreserveQueuePublicApiAdmission = didPreserveQueuePublicApiAdmission
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueuePublicSubmissionRequest(
    candidate: CjguiInternalQueuePublicApiReadinessCandidate
): CjguiInternalQueuePublicSubmissionRequest {
    let candidateReady = candidate.isQueuePublicApiReadinessCandidateReady &&
        candidate.hasStableQueuePublicApiCompatibilityPromise == false &&
        candidate.didPreserveQueuePublicAuditRequirement &&
        candidate.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        candidate.didPreservePreviousQueueStoreSnapshot &&
        candidate.shouldDeferQueuePublicApiReadinessCandidate == false &&
        candidate.shouldReportQueuePublicApiReadinessCandidateBlocked == false &&
        candidate.shouldReportQueuePublicApiReadinessCandidateIncompatible == false &&
        candidate.shouldReportQueuePublicApiReadinessCandidateUnauthorized == false
    let candidateDeferred = candidate.isQueuePublicApiReadinessCandidateReady == false &&
        candidate.hasStableQueuePublicApiCompatibilityPromise == false &&
        candidate.didPreserveQueuePublicAuditRequirement == false &&
        candidate.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        candidate.didPreservePreviousQueueStoreSnapshot &&
        candidate.shouldDeferQueuePublicApiReadinessCandidate &&
        candidate.shouldReportQueuePublicApiReadinessCandidateBlocked == false &&
        candidate.shouldReportQueuePublicApiReadinessCandidateIncompatible == false &&
        candidate.shouldReportQueuePublicApiReadinessCandidateUnauthorized == false
    let candidateInconsistent = (
        candidate.isQueuePublicApiReadinessCandidateReady &&
            (
                candidate.hasStableQueuePublicApiCompatibilityPromise ||
                candidate.shouldDeferQueuePublicApiReadinessCandidate ||
                candidate.shouldReportQueuePublicApiReadinessCandidateBlocked ||
                candidate.shouldReportQueuePublicApiReadinessCandidateIncompatible ||
                candidate.shouldReportQueuePublicApiReadinessCandidateUnauthorized
            )
        ) ||
        candidate.hasStableQueuePublicApiCompatibilityPromise ||
        (candidate.didPreserveQueuePublicAuditRequirement &&
            candidate.isQueuePublicApiReadinessCandidateReady == false) ||
        (candidate.didPreserveQueuePublicAuditRequirement == false &&
            candidate.isQueuePublicApiReadinessCandidateReady) ||
        (candidate.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            candidate.isQueuePublicApiReadinessCandidateReady == false) ||
        (candidate.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            candidate.isQueuePublicApiReadinessCandidateReady) ||
        (candidate.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            candidate.shouldDeferQueuePublicApiReadinessCandidate &&
            (
                candidate.shouldReportQueuePublicApiReadinessCandidateBlocked ||
                candidate.shouldReportQueuePublicApiReadinessCandidateIncompatible ||
                candidate.shouldReportQueuePublicApiReadinessCandidateUnauthorized
            )
        )

    // api-readiness candidate 不一致时必须 fail-closed，不能伪造 public submission request。
    if (
        candidate.shouldReportQueuePublicApiReadinessCandidateBlocked ||
        candidate.shouldReportQueuePublicApiReadinessCandidateIncompatible ||
        candidate.shouldReportQueuePublicApiReadinessCandidateUnauthorized ||
        candidateInconsistent
    ) {
        return CjguiInternalQueuePublicSubmissionRequest(
            candidate,
            false,
            false,
            false,
            true,
            true,
            candidate.shouldReportQueuePublicApiReadinessCandidateIncompatible || candidateInconsistent,
            candidate.shouldReportQueuePublicApiReadinessCandidateUnauthorized,
            false,
            false,
            candidate.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (candidateReady) {
        return CjguiInternalQueuePublicSubmissionRequest(
            candidate,
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

    if (candidateDeferred) {
        return CjguiInternalQueuePublicSubmissionRequest(
            candidate,
            false,
            false,
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

    return CjguiInternalQueuePublicSubmissionRequest(
        candidate,
        false,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        candidate.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicApiAdmission(
    request: CjguiInternalQueuePublicSubmissionRequest
): CjguiInternalQueuePublicApiAdmission {
    let requestReady = request.didCreateQueuePublicSubmissionRequest &&
        request.didUseQueueSubmissionTerminology &&
        request.didPreserveQueuePublicApiReadinessCandidate &&
        request.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        request.didPreservePreviousQueueStoreSnapshot &&
        request.shouldDeferQueuePublicSubmissionRequest == false &&
        request.shouldReportQueuePublicSubmissionRequestBlocked == false &&
        request.shouldRejectQueuePublicSubmissionRequest == false &&
        request.shouldReportQueuePublicSubmissionRequestIncompatible == false &&
        request.shouldReportQueuePublicSubmissionRequestUnauthorized == false
    let requestDeferred = request.didCreateQueuePublicSubmissionRequest == false &&
        request.didUseQueueSubmissionTerminology == false &&
        request.didPreserveQueuePublicApiReadinessCandidate == false &&
        request.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        request.didPreservePreviousQueueStoreSnapshot &&
        request.shouldDeferQueuePublicSubmissionRequest &&
        request.shouldReportQueuePublicSubmissionRequestBlocked == false &&
        request.shouldRejectQueuePublicSubmissionRequest == false &&
        request.shouldReportQueuePublicSubmissionRequestIncompatible == false &&
        request.shouldReportQueuePublicSubmissionRequestUnauthorized == false
    let requestInconsistent = (
        request.didCreateQueuePublicSubmissionRequest &&
            (
                request.didUseQueueSubmissionTerminology == false ||
                request.shouldDeferQueuePublicSubmissionRequest ||
                request.shouldReportQueuePublicSubmissionRequestBlocked ||
                request.shouldRejectQueuePublicSubmissionRequest ||
                request.shouldReportQueuePublicSubmissionRequestIncompatible ||
                request.shouldReportQueuePublicSubmissionRequestUnauthorized
            )
        ) ||
        (request.didUseQueueSubmissionTerminology &&
            request.didCreateQueuePublicSubmissionRequest == false) ||
        (request.didPreserveQueuePublicApiReadinessCandidate &&
            request.didCreateQueuePublicSubmissionRequest == false) ||
        (request.didPreserveQueuePublicApiReadinessCandidate == false &&
            request.didCreateQueuePublicSubmissionRequest) ||
        (request.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            request.didCreateQueuePublicSubmissionRequest == false) ||
        (request.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            request.didCreateQueuePublicSubmissionRequest) ||
        (request.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            request.shouldDeferQueuePublicSubmissionRequest &&
            (
                request.shouldReportQueuePublicSubmissionRequestBlocked ||
                request.shouldRejectQueuePublicSubmissionRequest ||
                request.shouldReportQueuePublicSubmissionRequestIncompatible ||
                request.shouldReportQueuePublicSubmissionRequestUnauthorized
            )
        )

    // submission request 不一致时必须 fail-closed，API admission 不能绕过 public surface policy。
    if (
        request.shouldReportQueuePublicSubmissionRequestBlocked ||
        request.shouldRejectQueuePublicSubmissionRequest ||
        request.shouldReportQueuePublicSubmissionRequestIncompatible ||
        request.shouldReportQueuePublicSubmissionRequestUnauthorized ||
        requestInconsistent
    ) {
        return CjguiInternalQueuePublicApiAdmission(
            request,
            false,
            false,
            true,
            true,
            request.shouldReportQueuePublicSubmissionRequestIncompatible || requestInconsistent,
            request.shouldReportQueuePublicSubmissionRequestUnauthorized,
            false,
            false,
            request.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (requestReady) {
        return CjguiInternalQueuePublicApiAdmission(request, true, false, false, false, false, false, true, true, true)
    }

    if (requestDeferred) {
        return CjguiInternalQueuePublicApiAdmission(
            request,
            false,
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

    return CjguiInternalQueuePublicApiAdmission(
        request,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        request.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicApiResult(
    admission: CjguiInternalQueuePublicApiAdmission
): CjguiInternalQueuePublicApiResult {
    let admissionReady = admission.didAdmitQueuePublicApiSubmissionRequest &&
        admission.didPreserveQueuePublicSubmissionRequest &&
        admission.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        admission.didPreservePreviousQueueStoreSnapshot &&
        admission.shouldDeferQueuePublicApiAdmission == false &&
        admission.shouldReportQueuePublicApiAdmissionBlocked == false &&
        admission.shouldRejectQueuePublicApiAdmission == false &&
        admission.shouldReportQueuePublicApiAdmissionIncompatible == false &&
        admission.shouldReportQueuePublicApiAdmissionUnauthorized == false
    let admissionDeferred = admission.didAdmitQueuePublicApiSubmissionRequest == false &&
        admission.didPreserveQueuePublicSubmissionRequest == false &&
        admission.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        admission.didPreservePreviousQueueStoreSnapshot &&
        admission.shouldDeferQueuePublicApiAdmission &&
        admission.shouldReportQueuePublicApiAdmissionBlocked == false &&
        admission.shouldRejectQueuePublicApiAdmission == false &&
        admission.shouldReportQueuePublicApiAdmissionIncompatible == false &&
        admission.shouldReportQueuePublicApiAdmissionUnauthorized == false
    let admissionInconsistent = (
        admission.didAdmitQueuePublicApiSubmissionRequest &&
            (
                admission.shouldDeferQueuePublicApiAdmission ||
                admission.shouldReportQueuePublicApiAdmissionBlocked ||
                admission.shouldRejectQueuePublicApiAdmission ||
                admission.shouldReportQueuePublicApiAdmissionIncompatible ||
                admission.shouldReportQueuePublicApiAdmissionUnauthorized
            )
        ) ||
        (admission.didPreserveQueuePublicSubmissionRequest &&
            admission.didAdmitQueuePublicApiSubmissionRequest == false) ||
        (admission.didPreserveQueuePublicSubmissionRequest == false &&
            admission.didAdmitQueuePublicApiSubmissionRequest) ||
        (admission.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            admission.didAdmitQueuePublicApiSubmissionRequest == false) ||
        (admission.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            admission.didAdmitQueuePublicApiSubmissionRequest) ||
        (admission.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            admission.shouldDeferQueuePublicApiAdmission &&
            (
                admission.shouldReportQueuePublicApiAdmissionBlocked ||
                admission.shouldRejectQueuePublicApiAdmission ||
                admission.shouldReportQueuePublicApiAdmissionIncompatible ||
                admission.shouldReportQueuePublicApiAdmissionUnauthorized
            )
        )

    // admission facts 不一致时必须 fail-closed，result 只能表达 rejected / blocked value facts。
    if (
        admission.shouldReportQueuePublicApiAdmissionBlocked ||
        admission.shouldRejectQueuePublicApiAdmission ||
        admission.shouldReportQueuePublicApiAdmissionIncompatible ||
        admission.shouldReportQueuePublicApiAdmissionUnauthorized ||
        admissionInconsistent
    ) {
        return CjguiInternalQueuePublicApiResult(
            admission,
            false,
            false,
            true,
            true,
            admission.shouldReportQueuePublicApiAdmissionIncompatible || admissionInconsistent,
            admission.shouldReportQueuePublicApiAdmissionUnauthorized,
            false,
            false,
            admission.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (admissionReady) {
        return CjguiInternalQueuePublicApiResult(admission, true, false, false, false, false, false, true, true, true)
    }

    if (admissionDeferred) {
        return CjguiInternalQueuePublicApiResult(
            admission,
            false,
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

    return CjguiInternalQueuePublicApiResult(
        admission,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        admission.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueuePublicApiAdmissionDraft(): CjguiInternalQueuePublicApiResult {
    // 默认 draft 只串联 internal-only public API admission value facts；
    // 不是 public runtime API / C ABI，也不 real enqueue 或写 queue storage。
    let candidate = cjguiInternalExecuteDefaultQueuePublicSurfacePolicyDraft()
    let request = cjguiInternalBuildQueuePublicSubmissionRequest(candidate)
    let admission = cjguiInternalBuildQueuePublicApiAdmission(request)
    return cjguiInternalBuildQueuePublicApiResult(admission)
}

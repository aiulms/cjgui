package cjgui

// Internal Queue Public Boundary owner:
// - 本文件只消费 QueueOwnerLocalWriteHandoffReceipt。
// - Truth 是 future public surface 前置的 intent / submission / admission / readiness 内部 value facts。
// - Stop-line: public-boundary 不是 public API / C ABI，也不是真实 enqueue；不写 process-wide queue storage、
//   不创建 global mutable queue / singleton、不做 item collection mutation、不 drain、不接 event loop / scheduler /
//   platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Public boundary intent 只表达“未来 public surface 可能提交请求”的内部意图事实；
// 它不是 public API shape，也不是 enqueue side effect。
struct CjguiInternalQueuePublicBoundaryIntent {
    let receipt: CjguiInternalQueueOwnerLocalWriteHandoffReceipt
    let didCreateQueuePublicBoundaryIntent: Bool
    let shouldDeferQueuePublicBoundaryIntent: Bool
    let shouldReportQueuePublicBoundaryIntentBlocked: Bool
    let shouldRejectQueuePublicBoundaryIntent: Bool
    let shouldReportQueuePublicBoundaryIntentIncompatible: Bool
    let shouldReportQueuePublicBoundaryIntentUnauthorized: Bool
    let didPreserveQueueOwnerLocalWriteHandoffReceipt: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        receipt: CjguiInternalQueueOwnerLocalWriteHandoffReceipt,
        didCreateQueuePublicBoundaryIntent: Bool,
        shouldDeferQueuePublicBoundaryIntent: Bool,
        shouldReportQueuePublicBoundaryIntentBlocked: Bool,
        shouldRejectQueuePublicBoundaryIntent: Bool,
        shouldReportQueuePublicBoundaryIntentIncompatible: Bool,
        shouldReportQueuePublicBoundaryIntentUnauthorized: Bool,
        didPreserveQueueOwnerLocalWriteHandoffReceipt: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.receipt = receipt
        this.didCreateQueuePublicBoundaryIntent = didCreateQueuePublicBoundaryIntent
        this.shouldDeferQueuePublicBoundaryIntent = shouldDeferQueuePublicBoundaryIntent
        this.shouldReportQueuePublicBoundaryIntentBlocked = shouldReportQueuePublicBoundaryIntentBlocked
        this.shouldRejectQueuePublicBoundaryIntent = shouldRejectQueuePublicBoundaryIntent
        this.shouldReportQueuePublicBoundaryIntentIncompatible = shouldReportQueuePublicBoundaryIntentIncompatible
        this.shouldReportQueuePublicBoundaryIntentUnauthorized = shouldReportQueuePublicBoundaryIntentUnauthorized
        this.didPreserveQueueOwnerLocalWriteHandoffReceipt = didPreserveQueueOwnerLocalWriteHandoffReceipt
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Public submission 只是 internal value submission，不是对外可调用 API，也不写 queue。
struct CjguiInternalQueuePublicSubmission {
    let intent: CjguiInternalQueuePublicBoundaryIntent
    let didPrepareQueuePublicSubmission: Bool
    let shouldDeferQueuePublicSubmission: Bool
    let shouldReportQueuePublicSubmissionBlocked: Bool
    let shouldRejectQueuePublicSubmission: Bool
    let shouldReportQueuePublicSubmissionIncompatible: Bool
    let shouldReportQueuePublicSubmissionUnauthorized: Bool
    let didPreserveQueuePublicBoundaryIntent: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        intent: CjguiInternalQueuePublicBoundaryIntent,
        didPrepareQueuePublicSubmission: Bool,
        shouldDeferQueuePublicSubmission: Bool,
        shouldReportQueuePublicSubmissionBlocked: Bool,
        shouldRejectQueuePublicSubmission: Bool,
        shouldReportQueuePublicSubmissionIncompatible: Bool,
        shouldReportQueuePublicSubmissionUnauthorized: Bool,
        didPreserveQueuePublicBoundaryIntent: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.intent = intent
        this.didPrepareQueuePublicSubmission = didPrepareQueuePublicSubmission
        this.shouldDeferQueuePublicSubmission = shouldDeferQueuePublicSubmission
        this.shouldReportQueuePublicSubmissionBlocked = shouldReportQueuePublicSubmissionBlocked
        this.shouldRejectQueuePublicSubmission = shouldRejectQueuePublicSubmission
        this.shouldReportQueuePublicSubmissionIncompatible = shouldReportQueuePublicSubmissionIncompatible
        this.shouldReportQueuePublicSubmissionUnauthorized = shouldReportQueuePublicSubmissionUnauthorized
        this.didPreserveQueuePublicBoundaryIntent = didPreserveQueuePublicBoundaryIntent
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Public boundary admission 只说明 submission 是否可进入下一段 public-boundary 评估；
// 它不是 public enqueue admission，也不是真实 authorization side effect。
struct CjguiInternalQueuePublicBoundaryAdmission {
    let submission: CjguiInternalQueuePublicSubmission
    let didAdmitQueuePublicBoundary: Bool
    let shouldDeferQueuePublicBoundaryAdmission: Bool
    let shouldReportQueuePublicBoundaryAdmissionBlocked: Bool
    let shouldRejectQueuePublicBoundaryAdmission: Bool
    let shouldReportQueuePublicBoundaryAdmissionIncompatible: Bool
    let shouldReportQueuePublicBoundaryAdmissionUnauthorized: Bool
    let didPreserveQueuePublicSubmission: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        submission: CjguiInternalQueuePublicSubmission,
        didAdmitQueuePublicBoundary: Bool,
        shouldDeferQueuePublicBoundaryAdmission: Bool,
        shouldReportQueuePublicBoundaryAdmissionBlocked: Bool,
        shouldRejectQueuePublicBoundaryAdmission: Bool,
        shouldReportQueuePublicBoundaryAdmissionIncompatible: Bool,
        shouldReportQueuePublicBoundaryAdmissionUnauthorized: Bool,
        didPreserveQueuePublicSubmission: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.submission = submission
        this.didAdmitQueuePublicBoundary = didAdmitQueuePublicBoundary
        this.shouldDeferQueuePublicBoundaryAdmission = shouldDeferQueuePublicBoundaryAdmission
        this.shouldReportQueuePublicBoundaryAdmissionBlocked = shouldReportQueuePublicBoundaryAdmissionBlocked
        this.shouldRejectQueuePublicBoundaryAdmission = shouldRejectQueuePublicBoundaryAdmission
        this.shouldReportQueuePublicBoundaryAdmissionIncompatible = shouldReportQueuePublicBoundaryAdmissionIncompatible
        this.shouldReportQueuePublicBoundaryAdmissionUnauthorized = shouldReportQueuePublicBoundaryAdmissionUnauthorized
        this.didPreserveQueuePublicSubmission = didPreserveQueuePublicSubmission
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Public boundary readiness 是本轮 canonical endpoint；readiness 只表示 future public boundary 可继续评估，
// 不表示 public API ready，也不表示 real enqueue ready。
struct CjguiInternalQueuePublicBoundaryReadiness {
    let admission: CjguiInternalQueuePublicBoundaryAdmission
    let isQueuePublicBoundaryReady: Bool
    let shouldDeferQueuePublicBoundaryReadiness: Bool
    let shouldReportQueuePublicBoundaryReadinessBlocked: Bool
    let shouldRejectQueuePublicBoundaryReadiness: Bool
    let shouldReportQueuePublicBoundaryReadinessIncompatible: Bool
    let shouldReportQueuePublicBoundaryReadinessUnauthorized: Bool
    let didPreserveQueuePublicBoundaryAdmission: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        admission: CjguiInternalQueuePublicBoundaryAdmission,
        isQueuePublicBoundaryReady: Bool,
        shouldDeferQueuePublicBoundaryReadiness: Bool,
        shouldReportQueuePublicBoundaryReadinessBlocked: Bool,
        shouldRejectQueuePublicBoundaryReadiness: Bool,
        shouldReportQueuePublicBoundaryReadinessIncompatible: Bool,
        shouldReportQueuePublicBoundaryReadinessUnauthorized: Bool,
        didPreserveQueuePublicBoundaryAdmission: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.admission = admission
        this.isQueuePublicBoundaryReady = isQueuePublicBoundaryReady
        this.shouldDeferQueuePublicBoundaryReadiness = shouldDeferQueuePublicBoundaryReadiness
        this.shouldReportQueuePublicBoundaryReadinessBlocked = shouldReportQueuePublicBoundaryReadinessBlocked
        this.shouldRejectQueuePublicBoundaryReadiness = shouldRejectQueuePublicBoundaryReadiness
        this.shouldReportQueuePublicBoundaryReadinessIncompatible = shouldReportQueuePublicBoundaryReadinessIncompatible
        this.shouldReportQueuePublicBoundaryReadinessUnauthorized = shouldReportQueuePublicBoundaryReadinessUnauthorized
        this.didPreserveQueuePublicBoundaryAdmission = didPreserveQueuePublicBoundaryAdmission
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueuePublicBoundaryIntent(
    receipt: CjguiInternalQueueOwnerLocalWriteHandoffReceipt
): CjguiInternalQueuePublicBoundaryIntent {
    let receiptReady = receipt.didRecordQueueOwnerLocalWriteHandoffReceipt &&
        receipt.didPreserveQueueOwnerLocalWriteHandoffAcceptance &&
        receipt.didPreservePreviousQueueStoreSnapshot &&
        receipt.acceptance.didAcceptQueueOwnerLocalWriteHandoff &&
        receipt.acceptance.shouldDeferQueueOwnerLocalWriteHandoffAcceptance == false &&
        receipt.acceptance.shouldReportQueueOwnerLocalWriteHandoffAcceptanceBlocked == false &&
        receipt.shouldDeferQueueOwnerLocalWriteHandoffReceipt == false &&
        receipt.shouldReportQueueOwnerLocalWriteHandoffReceiptBlocked == false
    let receiptDeferred = receipt.didRecordQueueOwnerLocalWriteHandoffReceipt == false &&
        receipt.didPreserveQueueOwnerLocalWriteHandoffAcceptance == false &&
        receipt.didPreservePreviousQueueStoreSnapshot &&
        receipt.shouldDeferQueueOwnerLocalWriteHandoffReceipt &&
        receipt.shouldReportQueueOwnerLocalWriteHandoffReceiptBlocked == false
    let receiptInconsistent = (
        receipt.didRecordQueueOwnerLocalWriteHandoffReceipt &&
            (
                receipt.shouldDeferQueueOwnerLocalWriteHandoffReceipt ||
                receipt.shouldReportQueueOwnerLocalWriteHandoffReceiptBlocked
            )
        ) ||
        (receipt.didPreserveQueueOwnerLocalWriteHandoffAcceptance &&
            receipt.didRecordQueueOwnerLocalWriteHandoffReceipt == false) ||
        (receipt.didPreserveQueueOwnerLocalWriteHandoffAcceptance == false &&
            receipt.didRecordQueueOwnerLocalWriteHandoffReceipt) ||
        (receipt.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            receipt.shouldDeferQueueOwnerLocalWriteHandoffReceipt &&
            receipt.shouldReportQueueOwnerLocalWriteHandoffReceiptBlocked
        ) ||
        (
            receipt.didRecordQueueOwnerLocalWriteHandoffReceipt &&
            receipt.acceptance.didAcceptQueueOwnerLocalWriteHandoff == false
        )

    // handoff receipt 不一致时必须 fail-closed，不能把内部 receipt 误升级为 public-boundary 意图。
    if (
        receipt.shouldReportQueueOwnerLocalWriteHandoffReceiptBlocked ||
        receiptInconsistent
    ) {
        return CjguiInternalQueuePublicBoundaryIntent(
            receipt,
            false,
            false,
            true,
            true,
            receiptInconsistent,
            false,
            false,
            receipt.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (receiptReady) {
        return CjguiInternalQueuePublicBoundaryIntent(receipt, true, false, false, false, false, false, true, true)
    }

    if (receiptDeferred) {
        return CjguiInternalQueuePublicBoundaryIntent(receipt, false, true, false, false, false, false, false, true)
    }

    return CjguiInternalQueuePublicBoundaryIntent(
        receipt,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        receipt.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicSubmission(
    intent: CjguiInternalQueuePublicBoundaryIntent
): CjguiInternalQueuePublicSubmission {
    let intentReady = intent.didCreateQueuePublicBoundaryIntent &&
        intent.didPreserveQueueOwnerLocalWriteHandoffReceipt &&
        intent.didPreservePreviousQueueStoreSnapshot &&
        intent.shouldDeferQueuePublicBoundaryIntent == false &&
        intent.shouldReportQueuePublicBoundaryIntentBlocked == false &&
        intent.shouldRejectQueuePublicBoundaryIntent == false &&
        intent.shouldReportQueuePublicBoundaryIntentIncompatible == false &&
        intent.shouldReportQueuePublicBoundaryIntentUnauthorized == false
    let intentDeferred = intent.didCreateQueuePublicBoundaryIntent == false &&
        intent.didPreserveQueueOwnerLocalWriteHandoffReceipt == false &&
        intent.didPreservePreviousQueueStoreSnapshot &&
        intent.shouldDeferQueuePublicBoundaryIntent &&
        intent.shouldReportQueuePublicBoundaryIntentBlocked == false &&
        intent.shouldRejectQueuePublicBoundaryIntent == false
    let intentInconsistent = (
        intent.didCreateQueuePublicBoundaryIntent &&
            (
                intent.shouldDeferQueuePublicBoundaryIntent ||
                intent.shouldReportQueuePublicBoundaryIntentBlocked ||
                intent.shouldRejectQueuePublicBoundaryIntent ||
                intent.shouldReportQueuePublicBoundaryIntentIncompatible ||
                intent.shouldReportQueuePublicBoundaryIntentUnauthorized
            )
        ) ||
        (intent.didPreserveQueueOwnerLocalWriteHandoffReceipt &&
            intent.didCreateQueuePublicBoundaryIntent == false) ||
        (intent.didPreserveQueueOwnerLocalWriteHandoffReceipt == false &&
            intent.didCreateQueuePublicBoundaryIntent) ||
        (intent.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            intent.shouldDeferQueuePublicBoundaryIntent &&
            intent.shouldReportQueuePublicBoundaryIntentBlocked
        )

    // public-boundary intent 不一致时必须 fail-closed，submission 不能被当成真实 public API 请求。
    if (
        intent.shouldReportQueuePublicBoundaryIntentBlocked ||
        intent.shouldRejectQueuePublicBoundaryIntent ||
        intent.shouldReportQueuePublicBoundaryIntentIncompatible ||
        intent.shouldReportQueuePublicBoundaryIntentUnauthorized ||
        intentInconsistent
    ) {
        return CjguiInternalQueuePublicSubmission(
            intent,
            false,
            false,
            true,
            true,
            intent.shouldReportQueuePublicBoundaryIntentIncompatible || intentInconsistent,
            intent.shouldReportQueuePublicBoundaryIntentUnauthorized,
            false,
            intent.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (intentReady) {
        return CjguiInternalQueuePublicSubmission(intent, true, false, false, false, false, false, true, true)
    }

    if (intentDeferred) {
        return CjguiInternalQueuePublicSubmission(intent, false, true, false, false, false, false, false, true)
    }

    return CjguiInternalQueuePublicSubmission(
        intent,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        intent.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicBoundaryAdmission(
    submission: CjguiInternalQueuePublicSubmission
): CjguiInternalQueuePublicBoundaryAdmission {
    let submissionReady = submission.didPrepareQueuePublicSubmission &&
        submission.didPreserveQueuePublicBoundaryIntent &&
        submission.didPreservePreviousQueueStoreSnapshot &&
        submission.shouldDeferQueuePublicSubmission == false &&
        submission.shouldReportQueuePublicSubmissionBlocked == false &&
        submission.shouldRejectQueuePublicSubmission == false &&
        submission.shouldReportQueuePublicSubmissionIncompatible == false &&
        submission.shouldReportQueuePublicSubmissionUnauthorized == false
    let submissionDeferred = submission.didPrepareQueuePublicSubmission == false &&
        submission.didPreserveQueuePublicBoundaryIntent == false &&
        submission.didPreservePreviousQueueStoreSnapshot &&
        submission.shouldDeferQueuePublicSubmission &&
        submission.shouldReportQueuePublicSubmissionBlocked == false &&
        submission.shouldRejectQueuePublicSubmission == false
    let submissionInconsistent = (
        submission.didPrepareQueuePublicSubmission &&
            (
                submission.shouldDeferQueuePublicSubmission ||
                submission.shouldReportQueuePublicSubmissionBlocked ||
                submission.shouldRejectQueuePublicSubmission ||
                submission.shouldReportQueuePublicSubmissionIncompatible ||
                submission.shouldReportQueuePublicSubmissionUnauthorized
            )
        ) ||
        (submission.didPreserveQueuePublicBoundaryIntent &&
            submission.didPrepareQueuePublicSubmission == false) ||
        (submission.didPreserveQueuePublicBoundaryIntent == false &&
            submission.didPrepareQueuePublicSubmission) ||
        (submission.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            submission.shouldDeferQueuePublicSubmission &&
            submission.shouldReportQueuePublicSubmissionBlocked
        )

    // submission 不一致时必须 fail-closed，admission 不能绕过 Action Router / Queue gates。
    if (
        submission.shouldReportQueuePublicSubmissionBlocked ||
        submission.shouldRejectQueuePublicSubmission ||
        submission.shouldReportQueuePublicSubmissionIncompatible ||
        submission.shouldReportQueuePublicSubmissionUnauthorized ||
        submissionInconsistent
    ) {
        return CjguiInternalQueuePublicBoundaryAdmission(
            submission,
            false,
            false,
            true,
            true,
            submission.shouldReportQueuePublicSubmissionIncompatible || submissionInconsistent,
            submission.shouldReportQueuePublicSubmissionUnauthorized,
            false,
            submission.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (submissionReady) {
        return CjguiInternalQueuePublicBoundaryAdmission(submission, true, false, false, false, false, false, true, true)
    }

    if (submissionDeferred) {
        return CjguiInternalQueuePublicBoundaryAdmission(submission, false, true, false, false, false, false, false, true)
    }

    return CjguiInternalQueuePublicBoundaryAdmission(
        submission,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        submission.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicBoundaryReadiness(
    admission: CjguiInternalQueuePublicBoundaryAdmission
): CjguiInternalQueuePublicBoundaryReadiness {
    let admissionReady = admission.didAdmitQueuePublicBoundary &&
        admission.didPreserveQueuePublicSubmission &&
        admission.didPreservePreviousQueueStoreSnapshot &&
        admission.shouldDeferQueuePublicBoundaryAdmission == false &&
        admission.shouldReportQueuePublicBoundaryAdmissionBlocked == false &&
        admission.shouldRejectQueuePublicBoundaryAdmission == false &&
        admission.shouldReportQueuePublicBoundaryAdmissionIncompatible == false &&
        admission.shouldReportQueuePublicBoundaryAdmissionUnauthorized == false
    let admissionDeferred = admission.didAdmitQueuePublicBoundary == false &&
        admission.didPreserveQueuePublicSubmission == false &&
        admission.didPreservePreviousQueueStoreSnapshot &&
        admission.shouldDeferQueuePublicBoundaryAdmission &&
        admission.shouldReportQueuePublicBoundaryAdmissionBlocked == false &&
        admission.shouldRejectQueuePublicBoundaryAdmission == false
    let admissionInconsistent = (
        admission.didAdmitQueuePublicBoundary &&
            (
                admission.shouldDeferQueuePublicBoundaryAdmission ||
                admission.shouldReportQueuePublicBoundaryAdmissionBlocked ||
                admission.shouldRejectQueuePublicBoundaryAdmission ||
                admission.shouldReportQueuePublicBoundaryAdmissionIncompatible ||
                admission.shouldReportQueuePublicBoundaryAdmissionUnauthorized
            )
        ) ||
        (admission.didPreserveQueuePublicSubmission &&
            admission.didAdmitQueuePublicBoundary == false) ||
        (admission.didPreserveQueuePublicSubmission == false &&
            admission.didAdmitQueuePublicBoundary) ||
        (admission.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            admission.shouldDeferQueuePublicBoundaryAdmission &&
            admission.shouldReportQueuePublicBoundaryAdmissionBlocked
        )

    // admission 不一致时必须 fail-closed，readiness 不能被解释为 public API ready 或 real enqueue ready。
    if (
        admission.shouldReportQueuePublicBoundaryAdmissionBlocked ||
        admission.shouldRejectQueuePublicBoundaryAdmission ||
        admission.shouldReportQueuePublicBoundaryAdmissionIncompatible ||
        admission.shouldReportQueuePublicBoundaryAdmissionUnauthorized ||
        admissionInconsistent
    ) {
        return CjguiInternalQueuePublicBoundaryReadiness(
            admission,
            false,
            false,
            true,
            true,
            admission.shouldReportQueuePublicBoundaryAdmissionIncompatible || admissionInconsistent,
            admission.shouldReportQueuePublicBoundaryAdmissionUnauthorized,
            false,
            admission.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (admissionReady) {
        return CjguiInternalQueuePublicBoundaryReadiness(admission, true, false, false, false, false, false, true, true)
    }

    if (admissionDeferred) {
        return CjguiInternalQueuePublicBoundaryReadiness(admission, false, true, false, false, false, false, false, true)
    }

    return CjguiInternalQueuePublicBoundaryReadiness(
        admission,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        admission.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueuePublicBoundaryAdmissionDraft(): CjguiInternalQueuePublicBoundaryReadiness {
    // 默认 draft 只串联 internal-only public-boundary value facts，不做真实 enqueue，也不暴露 public API。
    let receipt = cjguiInternalExecuteDefaultQueueOwnerLocalWriteHandoffDraft()
    let intent = cjguiInternalBuildQueuePublicBoundaryIntent(receipt)
    let submission = cjguiInternalBuildQueuePublicSubmission(intent)
    let admission = cjguiInternalBuildQueuePublicBoundaryAdmission(submission)
    return cjguiInternalBuildQueuePublicBoundaryReadiness(admission)
}

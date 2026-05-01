package cjgui

// Internal Queue Public Result Shape owner:
// - 本文件只消费 QueuePublicApiResult。
// - Truth 是 future public surface 的 response shape / result envelope / error projection / audit reference /
//   compatibility note 内部 value facts。
// - Stop-line: public result shape 不是 public runtime API / C ABI，也不是真实 enqueue；不接收 raw pointer /
//   native handle、不写 process-wide queue storage、不创建 global mutable queue / singleton、不做 item collection
//   mutation、不 drain、不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不回塞 critical
//   runtime_state.cj。

// Public response shape 只描述 future public response 的内部形态；它不暴露 lower-level internal owner facts，
// 也不是 public API response implementation。
struct CjguiInternalQueuePublicResponseShape {
    let result: CjguiInternalQueuePublicApiResult
    let didPrepareQueuePublicResponseShape: Bool
    let shouldDeferQueuePublicResponseShape: Bool
    let shouldReportQueuePublicResponseShapeBlocked: Bool
    let shouldRejectQueuePublicResponseShape: Bool
    let shouldReportQueuePublicResponseShapeIncompatible: Bool
    let shouldReportQueuePublicResponseShapeUnauthorized: Bool
    let didPreserveQueuePublicApiResult: Bool
    let didHideQueueInternalOwnerFactsFromPublicResponse: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        result: CjguiInternalQueuePublicApiResult,
        didPrepareQueuePublicResponseShape: Bool,
        shouldDeferQueuePublicResponseShape: Bool,
        shouldReportQueuePublicResponseShapeBlocked: Bool,
        shouldRejectQueuePublicResponseShape: Bool,
        shouldReportQueuePublicResponseShapeIncompatible: Bool,
        shouldReportQueuePublicResponseShapeUnauthorized: Bool,
        didPreserveQueuePublicApiResult: Bool,
        didHideQueueInternalOwnerFactsFromPublicResponse: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.result = result
        this.didPrepareQueuePublicResponseShape = didPrepareQueuePublicResponseShape
        this.shouldDeferQueuePublicResponseShape = shouldDeferQueuePublicResponseShape
        this.shouldReportQueuePublicResponseShapeBlocked = shouldReportQueuePublicResponseShapeBlocked
        this.shouldRejectQueuePublicResponseShape = shouldRejectQueuePublicResponseShape
        this.shouldReportQueuePublicResponseShapeIncompatible =
            shouldReportQueuePublicResponseShapeIncompatible
        this.shouldReportQueuePublicResponseShapeUnauthorized =
            shouldReportQueuePublicResponseShapeUnauthorized
        this.didPreserveQueuePublicApiResult = didPreserveQueuePublicApiResult
        this.didHideQueueInternalOwnerFactsFromPublicResponse = didHideQueueInternalOwnerFactsFromPublicResponse
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Public result envelope 只包装 public response shape 的 value facts；它不是 runtime return value、
// public API object，也不是 C ABI result。
struct CjguiInternalQueuePublicResultEnvelope {
    let shape: CjguiInternalQueuePublicResponseShape
    let didPrepareQueuePublicResultEnvelope: Bool
    let didWrapQueuePublicResultWithoutOwnerLeak: Bool
    let shouldDeferQueuePublicResultEnvelope: Bool
    let shouldReportQueuePublicResultEnvelopeBlocked: Bool
    let shouldRejectQueuePublicResultEnvelope: Bool
    let shouldReportQueuePublicResultEnvelopeIncompatible: Bool
    let shouldReportQueuePublicResultEnvelopeUnauthorized: Bool
    let didPreserveQueuePublicResponseShape: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        shape: CjguiInternalQueuePublicResponseShape,
        didPrepareQueuePublicResultEnvelope: Bool,
        didWrapQueuePublicResultWithoutOwnerLeak: Bool,
        shouldDeferQueuePublicResultEnvelope: Bool,
        shouldReportQueuePublicResultEnvelopeBlocked: Bool,
        shouldRejectQueuePublicResultEnvelope: Bool,
        shouldReportQueuePublicResultEnvelopeIncompatible: Bool,
        shouldReportQueuePublicResultEnvelopeUnauthorized: Bool,
        didPreserveQueuePublicResponseShape: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.shape = shape
        this.didPrepareQueuePublicResultEnvelope = didPrepareQueuePublicResultEnvelope
        this.didWrapQueuePublicResultWithoutOwnerLeak = didWrapQueuePublicResultWithoutOwnerLeak
        this.shouldDeferQueuePublicResultEnvelope = shouldDeferQueuePublicResultEnvelope
        this.shouldReportQueuePublicResultEnvelopeBlocked = shouldReportQueuePublicResultEnvelopeBlocked
        this.shouldRejectQueuePublicResultEnvelope = shouldRejectQueuePublicResultEnvelope
        this.shouldReportQueuePublicResultEnvelopeIncompatible =
            shouldReportQueuePublicResultEnvelopeIncompatible
        this.shouldReportQueuePublicResultEnvelopeUnauthorized =
            shouldReportQueuePublicResultEnvelopeUnauthorized
        this.didPreserveQueuePublicResponseShape = didPreserveQueuePublicResponseShape
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Public error projection 只能从 QueuePublicApiResult / public error contract 投影；
// 它不读取 lower-level mutable queue facts，也不暴露真实 runtime error surface。
struct CjguiInternalQueuePublicErrorProjection {
    let envelope: CjguiInternalQueuePublicResultEnvelope
    let didProjectQueuePublicErrors: Bool
    let didProjectQueuePublicErrorsFromApiResult: Bool
    let didAvoidLowerLevelMutableQueueFacts: Bool
    let shouldDeferQueuePublicErrorProjection: Bool
    let shouldReportQueuePublicErrorProjectionBlocked: Bool
    let shouldRejectQueuePublicErrorProjection: Bool
    let shouldReportQueuePublicErrorProjectionIncompatible: Bool
    let shouldReportQueuePublicErrorProjectionUnauthorized: Bool
    let didPreserveQueuePublicResultEnvelope: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        envelope: CjguiInternalQueuePublicResultEnvelope,
        didProjectQueuePublicErrors: Bool,
        didProjectQueuePublicErrorsFromApiResult: Bool,
        didAvoidLowerLevelMutableQueueFacts: Bool,
        shouldDeferQueuePublicErrorProjection: Bool,
        shouldReportQueuePublicErrorProjectionBlocked: Bool,
        shouldRejectQueuePublicErrorProjection: Bool,
        shouldReportQueuePublicErrorProjectionIncompatible: Bool,
        shouldReportQueuePublicErrorProjectionUnauthorized: Bool,
        didPreserveQueuePublicResultEnvelope: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.envelope = envelope
        this.didProjectQueuePublicErrors = didProjectQueuePublicErrors
        this.didProjectQueuePublicErrorsFromApiResult = didProjectQueuePublicErrorsFromApiResult
        this.didAvoidLowerLevelMutableQueueFacts = didAvoidLowerLevelMutableQueueFacts
        this.shouldDeferQueuePublicErrorProjection = shouldDeferQueuePublicErrorProjection
        this.shouldReportQueuePublicErrorProjectionBlocked = shouldReportQueuePublicErrorProjectionBlocked
        this.shouldRejectQueuePublicErrorProjection = shouldRejectQueuePublicErrorProjection
        this.shouldReportQueuePublicErrorProjectionIncompatible =
            shouldReportQueuePublicErrorProjectionIncompatible
        this.shouldReportQueuePublicErrorProjectionUnauthorized =
            shouldReportQueuePublicErrorProjectionUnauthorized
        this.didPreserveQueuePublicResultEnvelope = didPreserveQueuePublicResultEnvelope
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Public audit reference 只是 result shape 的 value-style audit reference；
// 它不是 public audit log writer、observer callback 或外部通知。
struct CjguiInternalQueuePublicAuditReference {
    let errorProjection: CjguiInternalQueuePublicErrorProjection
    let didPrepareQueuePublicAuditReference: Bool
    let didKeepQueuePublicAuditReferenceValueOnly: Bool
    let shouldDeferQueuePublicAuditReference: Bool
    let shouldReportQueuePublicAuditReferenceBlocked: Bool
    let shouldRejectQueuePublicAuditReference: Bool
    let shouldReportQueuePublicAuditReferenceIncompatible: Bool
    let shouldReportQueuePublicAuditReferenceUnauthorized: Bool
    let didPreserveQueuePublicErrorProjection: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        errorProjection: CjguiInternalQueuePublicErrorProjection,
        didPrepareQueuePublicAuditReference: Bool,
        didKeepQueuePublicAuditReferenceValueOnly: Bool,
        shouldDeferQueuePublicAuditReference: Bool,
        shouldReportQueuePublicAuditReferenceBlocked: Bool,
        shouldRejectQueuePublicAuditReference: Bool,
        shouldReportQueuePublicAuditReferenceIncompatible: Bool,
        shouldReportQueuePublicAuditReferenceUnauthorized: Bool,
        didPreserveQueuePublicErrorProjection: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.errorProjection = errorProjection
        this.didPrepareQueuePublicAuditReference = didPrepareQueuePublicAuditReference
        this.didKeepQueuePublicAuditReferenceValueOnly = didKeepQueuePublicAuditReferenceValueOnly
        this.shouldDeferQueuePublicAuditReference = shouldDeferQueuePublicAuditReference
        this.shouldReportQueuePublicAuditReferenceBlocked = shouldReportQueuePublicAuditReferenceBlocked
        this.shouldRejectQueuePublicAuditReference = shouldRejectQueuePublicAuditReference
        this.shouldReportQueuePublicAuditReferenceIncompatible = shouldReportQueuePublicAuditReferenceIncompatible
        this.shouldReportQueuePublicAuditReferenceUnauthorized = shouldReportQueuePublicAuditReferenceUnauthorized
        this.didPreserveQueuePublicErrorProjection = didPreserveQueuePublicErrorProjection
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Public compatibility note 是当前 canonical endpoint；它明确当前不承诺稳定 public API 兼容性，
// 只说明 future public API surface 可以继续评估。
struct CjguiInternalQueuePublicCompatibilityNote {
    let auditReference: CjguiInternalQueuePublicAuditReference
    let didPrepareQueuePublicCompatibilityNote: Bool
    let hasStableQueuePublicApiCompatibilityPromise: Bool
    let didStateQueuePublicCompatibilityPromiseAbsent: Bool
    let shouldDeferQueuePublicCompatibilityNote: Bool
    let shouldReportQueuePublicCompatibilityNoteBlocked: Bool
    let shouldRejectQueuePublicCompatibilityNote: Bool
    let shouldReportQueuePublicCompatibilityNoteIncompatible: Bool
    let shouldReportQueuePublicCompatibilityNoteUnauthorized: Bool
    let didPreserveQueuePublicAuditReference: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        auditReference: CjguiInternalQueuePublicAuditReference,
        didPrepareQueuePublicCompatibilityNote: Bool,
        hasStableQueuePublicApiCompatibilityPromise: Bool,
        didStateQueuePublicCompatibilityPromiseAbsent: Bool,
        shouldDeferQueuePublicCompatibilityNote: Bool,
        shouldReportQueuePublicCompatibilityNoteBlocked: Bool,
        shouldRejectQueuePublicCompatibilityNote: Bool,
        shouldReportQueuePublicCompatibilityNoteIncompatible: Bool,
        shouldReportQueuePublicCompatibilityNoteUnauthorized: Bool,
        didPreserveQueuePublicAuditReference: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.auditReference = auditReference
        this.didPrepareQueuePublicCompatibilityNote = didPrepareQueuePublicCompatibilityNote
        this.hasStableQueuePublicApiCompatibilityPromise = hasStableQueuePublicApiCompatibilityPromise
        this.didStateQueuePublicCompatibilityPromiseAbsent = didStateQueuePublicCompatibilityPromiseAbsent
        this.shouldDeferQueuePublicCompatibilityNote = shouldDeferQueuePublicCompatibilityNote
        this.shouldReportQueuePublicCompatibilityNoteBlocked = shouldReportQueuePublicCompatibilityNoteBlocked
        this.shouldRejectQueuePublicCompatibilityNote = shouldRejectQueuePublicCompatibilityNote
        this.shouldReportQueuePublicCompatibilityNoteIncompatible =
            shouldReportQueuePublicCompatibilityNoteIncompatible
        this.shouldReportQueuePublicCompatibilityNoteUnauthorized =
            shouldReportQueuePublicCompatibilityNoteUnauthorized
        this.didPreserveQueuePublicAuditReference = didPreserveQueuePublicAuditReference
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueuePublicResponseShape(
    result: CjguiInternalQueuePublicApiResult
): CjguiInternalQueuePublicResponseShape {
    let resultReady = result.didAcceptQueuePublicApiSubmission &&
        result.didPreserveQueuePublicApiAdmission &&
        result.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        result.didPreservePreviousQueueStoreSnapshot &&
        result.shouldDeferQueuePublicApiResult == false &&
        result.shouldReportQueuePublicApiResultBlocked == false &&
        result.shouldRejectQueuePublicApiResult == false &&
        result.shouldReportQueuePublicApiResultIncompatible == false &&
        result.shouldReportQueuePublicApiResultUnauthorized == false
    let resultDeferred = result.didAcceptQueuePublicApiSubmission == false &&
        result.didPreserveQueuePublicApiAdmission == false &&
        result.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        result.didPreservePreviousQueueStoreSnapshot &&
        result.shouldDeferQueuePublicApiResult &&
        result.shouldReportQueuePublicApiResultBlocked == false &&
        result.shouldRejectQueuePublicApiResult == false &&
        result.shouldReportQueuePublicApiResultIncompatible == false &&
        result.shouldReportQueuePublicApiResultUnauthorized == false
    let resultInconsistent = (
        result.didAcceptQueuePublicApiSubmission &&
            (
                result.shouldDeferQueuePublicApiResult ||
                result.shouldReportQueuePublicApiResultBlocked ||
                result.shouldRejectQueuePublicApiResult ||
                result.shouldReportQueuePublicApiResultIncompatible ||
                result.shouldReportQueuePublicApiResultUnauthorized
            )
        ) ||
        (result.didPreserveQueuePublicApiAdmission &&
            result.didAcceptQueuePublicApiSubmission == false) ||
        (result.didPreserveQueuePublicApiAdmission == false &&
            result.didAcceptQueuePublicApiSubmission) ||
        (result.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            result.didAcceptQueuePublicApiSubmission == false) ||
        (result.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            result.didAcceptQueuePublicApiSubmission) ||
        (result.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            result.shouldDeferQueuePublicApiResult &&
            (
                result.shouldReportQueuePublicApiResultBlocked ||
                result.shouldRejectQueuePublicApiResult ||
                result.shouldReportQueuePublicApiResultIncompatible ||
                result.shouldReportQueuePublicApiResultUnauthorized
            )
        )

    // API result 不一致时必须 fail-closed，不能伪造 accepted public response shape。
    if (
        result.shouldReportQueuePublicApiResultBlocked ||
        result.shouldRejectQueuePublicApiResult ||
        result.shouldReportQueuePublicApiResultIncompatible ||
        result.shouldReportQueuePublicApiResultUnauthorized ||
        resultInconsistent
    ) {
        return CjguiInternalQueuePublicResponseShape(
            result,
            false,
            false,
            true,
            true,
            result.shouldReportQueuePublicApiResultIncompatible || resultInconsistent,
            result.shouldReportQueuePublicApiResultUnauthorized,
            false,
            false,
            false,
            result.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (resultReady) {
        return CjguiInternalQueuePublicResponseShape(result, true, false, false, false, false, false, true, true, true, true)
    }

    if (resultDeferred) {
        return CjguiInternalQueuePublicResponseShape(
            result,
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

    return CjguiInternalQueuePublicResponseShape(
        result,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        false,
        result.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicResultEnvelope(
    shape: CjguiInternalQueuePublicResponseShape
): CjguiInternalQueuePublicResultEnvelope {
    let shapeReady = shape.didPrepareQueuePublicResponseShape &&
        shape.didPreserveQueuePublicApiResult &&
        shape.didHideQueueInternalOwnerFactsFromPublicResponse &&
        shape.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        shape.didPreservePreviousQueueStoreSnapshot &&
        shape.shouldDeferQueuePublicResponseShape == false &&
        shape.shouldReportQueuePublicResponseShapeBlocked == false &&
        shape.shouldRejectQueuePublicResponseShape == false &&
        shape.shouldReportQueuePublicResponseShapeIncompatible == false &&
        shape.shouldReportQueuePublicResponseShapeUnauthorized == false
    let shapeDeferred = shape.didPrepareQueuePublicResponseShape == false &&
        shape.didPreserveQueuePublicApiResult == false &&
        shape.didHideQueueInternalOwnerFactsFromPublicResponse == false &&
        shape.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        shape.didPreservePreviousQueueStoreSnapshot &&
        shape.shouldDeferQueuePublicResponseShape &&
        shape.shouldReportQueuePublicResponseShapeBlocked == false &&
        shape.shouldRejectQueuePublicResponseShape == false &&
        shape.shouldReportQueuePublicResponseShapeIncompatible == false &&
        shape.shouldReportQueuePublicResponseShapeUnauthorized == false
    let shapeInconsistent = (
        shape.didPrepareQueuePublicResponseShape &&
            (
                shape.didPreserveQueuePublicApiResult == false ||
                shape.didHideQueueInternalOwnerFactsFromPublicResponse == false ||
                shape.shouldDeferQueuePublicResponseShape ||
                shape.shouldReportQueuePublicResponseShapeBlocked ||
                shape.shouldRejectQueuePublicResponseShape ||
                shape.shouldReportQueuePublicResponseShapeIncompatible ||
                shape.shouldReportQueuePublicResponseShapeUnauthorized
            )
        ) ||
        (shape.didPreserveQueuePublicApiResult &&
            shape.didPrepareQueuePublicResponseShape == false) ||
        (shape.didHideQueueInternalOwnerFactsFromPublicResponse &&
            shape.didPrepareQueuePublicResponseShape == false) ||
        (shape.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            shape.didPrepareQueuePublicResponseShape == false) ||
        (shape.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            shape.didPrepareQueuePublicResponseShape) ||
        (shape.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            shape.shouldDeferQueuePublicResponseShape &&
            (
                shape.shouldReportQueuePublicResponseShapeBlocked ||
                shape.shouldRejectQueuePublicResponseShape ||
                shape.shouldReportQueuePublicResponseShapeIncompatible ||
                shape.shouldReportQueuePublicResponseShapeUnauthorized
            )
        )

    // response shape 不一致时必须 fail-closed，result envelope 不能泄露 internal owner facts。
    if (
        shape.shouldReportQueuePublicResponseShapeBlocked ||
        shape.shouldRejectQueuePublicResponseShape ||
        shape.shouldReportQueuePublicResponseShapeIncompatible ||
        shape.shouldReportQueuePublicResponseShapeUnauthorized ||
        shapeInconsistent
    ) {
        return CjguiInternalQueuePublicResultEnvelope(
            shape,
            false,
            false,
            false,
            true,
            true,
            shape.shouldReportQueuePublicResponseShapeIncompatible || shapeInconsistent,
            shape.shouldReportQueuePublicResponseShapeUnauthorized,
            false,
            false,
            shape.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (shapeReady) {
        return CjguiInternalQueuePublicResultEnvelope(shape, true, true, false, false, false, false, false, true, true, true)
    }

    if (shapeDeferred) {
        return CjguiInternalQueuePublicResultEnvelope(
            shape,
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

    return CjguiInternalQueuePublicResultEnvelope(
        shape,
        false,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        shape.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicErrorProjection(
    envelope: CjguiInternalQueuePublicResultEnvelope
): CjguiInternalQueuePublicErrorProjection {
    let envelopeReady = envelope.didPrepareQueuePublicResultEnvelope &&
        envelope.didWrapQueuePublicResultWithoutOwnerLeak &&
        envelope.didPreserveQueuePublicResponseShape &&
        envelope.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        envelope.didPreservePreviousQueueStoreSnapshot &&
        envelope.shouldDeferQueuePublicResultEnvelope == false &&
        envelope.shouldReportQueuePublicResultEnvelopeBlocked == false &&
        envelope.shouldRejectQueuePublicResultEnvelope == false &&
        envelope.shouldReportQueuePublicResultEnvelopeIncompatible == false &&
        envelope.shouldReportQueuePublicResultEnvelopeUnauthorized == false
    let envelopeDeferred = envelope.didPrepareQueuePublicResultEnvelope == false &&
        envelope.didWrapQueuePublicResultWithoutOwnerLeak == false &&
        envelope.didPreserveQueuePublicResponseShape == false &&
        envelope.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        envelope.didPreservePreviousQueueStoreSnapshot &&
        envelope.shouldDeferQueuePublicResultEnvelope &&
        envelope.shouldReportQueuePublicResultEnvelopeBlocked == false &&
        envelope.shouldRejectQueuePublicResultEnvelope == false &&
        envelope.shouldReportQueuePublicResultEnvelopeIncompatible == false &&
        envelope.shouldReportQueuePublicResultEnvelopeUnauthorized == false
    let envelopeInconsistent = (
        envelope.didPrepareQueuePublicResultEnvelope &&
            (
                envelope.didWrapQueuePublicResultWithoutOwnerLeak == false ||
                envelope.shouldDeferQueuePublicResultEnvelope ||
                envelope.shouldReportQueuePublicResultEnvelopeBlocked ||
                envelope.shouldRejectQueuePublicResultEnvelope ||
                envelope.shouldReportQueuePublicResultEnvelopeIncompatible ||
                envelope.shouldReportQueuePublicResultEnvelopeUnauthorized
            )
        ) ||
        (envelope.didWrapQueuePublicResultWithoutOwnerLeak &&
            envelope.didPrepareQueuePublicResultEnvelope == false) ||
        (envelope.didPreserveQueuePublicResponseShape &&
            envelope.didPrepareQueuePublicResultEnvelope == false) ||
        (envelope.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            envelope.didPrepareQueuePublicResultEnvelope == false) ||
        (envelope.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            envelope.didPrepareQueuePublicResultEnvelope) ||
        (envelope.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            envelope.shouldDeferQueuePublicResultEnvelope &&
            (
                envelope.shouldReportQueuePublicResultEnvelopeBlocked ||
                envelope.shouldRejectQueuePublicResultEnvelope ||
                envelope.shouldReportQueuePublicResultEnvelopeIncompatible ||
                envelope.shouldReportQueuePublicResultEnvelopeUnauthorized
            )
        )

    // result envelope 不一致时必须 fail-closed，error projection 不能读取 lower-level mutable queue facts。
    if (
        envelope.shouldReportQueuePublicResultEnvelopeBlocked ||
        envelope.shouldRejectQueuePublicResultEnvelope ||
        envelope.shouldReportQueuePublicResultEnvelopeIncompatible ||
        envelope.shouldReportQueuePublicResultEnvelopeUnauthorized ||
        envelopeInconsistent
    ) {
        return CjguiInternalQueuePublicErrorProjection(
            envelope,
            false,
            false,
            true,
            false,
            true,
            true,
            envelope.shouldReportQueuePublicResultEnvelopeIncompatible || envelopeInconsistent,
            envelope.shouldReportQueuePublicResultEnvelopeUnauthorized,
            false,
            false,
            envelope.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (envelopeReady) {
        return CjguiInternalQueuePublicErrorProjection(
            envelope,
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

    if (envelopeDeferred) {
        return CjguiInternalQueuePublicErrorProjection(
            envelope,
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

    return CjguiInternalQueuePublicErrorProjection(
        envelope,
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
        envelope.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicAuditReference(
    errorProjection: CjguiInternalQueuePublicErrorProjection
): CjguiInternalQueuePublicAuditReference {
    let projectionReady = errorProjection.didProjectQueuePublicErrors &&
        errorProjection.didProjectQueuePublicErrorsFromApiResult &&
        errorProjection.didAvoidLowerLevelMutableQueueFacts &&
        errorProjection.didPreserveQueuePublicResultEnvelope &&
        errorProjection.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        errorProjection.didPreservePreviousQueueStoreSnapshot &&
        errorProjection.shouldDeferQueuePublicErrorProjection == false &&
        errorProjection.shouldReportQueuePublicErrorProjectionBlocked == false &&
        errorProjection.shouldRejectQueuePublicErrorProjection == false &&
        errorProjection.shouldReportQueuePublicErrorProjectionIncompatible == false &&
        errorProjection.shouldReportQueuePublicErrorProjectionUnauthorized == false
    let projectionDeferred = errorProjection.didProjectQueuePublicErrors == false &&
        errorProjection.didProjectQueuePublicErrorsFromApiResult == false &&
        errorProjection.didPreserveQueuePublicResultEnvelope == false &&
        errorProjection.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        errorProjection.didPreservePreviousQueueStoreSnapshot &&
        errorProjection.shouldDeferQueuePublicErrorProjection &&
        errorProjection.shouldReportQueuePublicErrorProjectionBlocked == false &&
        errorProjection.shouldRejectQueuePublicErrorProjection == false &&
        errorProjection.shouldReportQueuePublicErrorProjectionIncompatible == false &&
        errorProjection.shouldReportQueuePublicErrorProjectionUnauthorized == false
    let projectionInconsistent = (
        errorProjection.didProjectQueuePublicErrors &&
            (
                errorProjection.didProjectQueuePublicErrorsFromApiResult == false ||
                errorProjection.didAvoidLowerLevelMutableQueueFacts == false ||
                errorProjection.shouldDeferQueuePublicErrorProjection ||
                errorProjection.shouldReportQueuePublicErrorProjectionBlocked ||
                errorProjection.shouldRejectQueuePublicErrorProjection ||
                errorProjection.shouldReportQueuePublicErrorProjectionIncompatible ||
                errorProjection.shouldReportQueuePublicErrorProjectionUnauthorized
            )
        ) ||
        (errorProjection.didProjectQueuePublicErrorsFromApiResult &&
            errorProjection.didProjectQueuePublicErrors == false) ||
        (errorProjection.didAvoidLowerLevelMutableQueueFacts == false &&
            errorProjection.didProjectQueuePublicErrors) ||
        (errorProjection.didPreserveQueuePublicResultEnvelope &&
            errorProjection.didProjectQueuePublicErrors == false) ||
        (errorProjection.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            errorProjection.didProjectQueuePublicErrors == false) ||
        (errorProjection.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            errorProjection.didProjectQueuePublicErrors) ||
        (errorProjection.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            errorProjection.shouldDeferQueuePublicErrorProjection &&
            (
                errorProjection.shouldReportQueuePublicErrorProjectionBlocked ||
                errorProjection.shouldRejectQueuePublicErrorProjection ||
                errorProjection.shouldReportQueuePublicErrorProjectionIncompatible ||
                errorProjection.shouldReportQueuePublicErrorProjectionUnauthorized
            )
        )

    // error projection 不一致时必须 fail-closed，audit reference 不能成为 public audit log writer。
    if (
        errorProjection.shouldReportQueuePublicErrorProjectionBlocked ||
        errorProjection.shouldRejectQueuePublicErrorProjection ||
        errorProjection.shouldReportQueuePublicErrorProjectionIncompatible ||
        errorProjection.shouldReportQueuePublicErrorProjectionUnauthorized ||
        projectionInconsistent
    ) {
        return CjguiInternalQueuePublicAuditReference(
            errorProjection,
            false,
            true,
            false,
            true,
            true,
            errorProjection.shouldReportQueuePublicErrorProjectionIncompatible || projectionInconsistent,
            errorProjection.shouldReportQueuePublicErrorProjectionUnauthorized,
            false,
            false,
            errorProjection.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (projectionReady) {
        return CjguiInternalQueuePublicAuditReference(
            errorProjection,
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

    if (projectionDeferred) {
        return CjguiInternalQueuePublicAuditReference(
            errorProjection,
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

    return CjguiInternalQueuePublicAuditReference(
        errorProjection,
        false,
        true,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        errorProjection.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicCompatibilityNote(
    auditReference: CjguiInternalQueuePublicAuditReference
): CjguiInternalQueuePublicCompatibilityNote {
    let auditReady = auditReference.didPrepareQueuePublicAuditReference &&
        auditReference.didKeepQueuePublicAuditReferenceValueOnly &&
        auditReference.didPreserveQueuePublicErrorProjection &&
        auditReference.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        auditReference.didPreservePreviousQueueStoreSnapshot &&
        auditReference.shouldDeferQueuePublicAuditReference == false &&
        auditReference.shouldReportQueuePublicAuditReferenceBlocked == false &&
        auditReference.shouldRejectQueuePublicAuditReference == false &&
        auditReference.shouldReportQueuePublicAuditReferenceIncompatible == false &&
        auditReference.shouldReportQueuePublicAuditReferenceUnauthorized == false
    let auditDeferred = auditReference.didPrepareQueuePublicAuditReference == false &&
        auditReference.didPreserveQueuePublicErrorProjection == false &&
        auditReference.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        auditReference.didPreservePreviousQueueStoreSnapshot &&
        auditReference.shouldDeferQueuePublicAuditReference &&
        auditReference.shouldReportQueuePublicAuditReferenceBlocked == false &&
        auditReference.shouldRejectQueuePublicAuditReference == false &&
        auditReference.shouldReportQueuePublicAuditReferenceIncompatible == false &&
        auditReference.shouldReportQueuePublicAuditReferenceUnauthorized == false
    let auditInconsistent = (
        auditReference.didPrepareQueuePublicAuditReference &&
            (
                auditReference.didKeepQueuePublicAuditReferenceValueOnly == false ||
                auditReference.shouldDeferQueuePublicAuditReference ||
                auditReference.shouldReportQueuePublicAuditReferenceBlocked ||
                auditReference.shouldRejectQueuePublicAuditReference ||
                auditReference.shouldReportQueuePublicAuditReferenceIncompatible ||
                auditReference.shouldReportQueuePublicAuditReferenceUnauthorized
            )
        ) ||
        (auditReference.didKeepQueuePublicAuditReferenceValueOnly == false &&
            auditReference.didPrepareQueuePublicAuditReference) ||
        (auditReference.didPreserveQueuePublicErrorProjection &&
            auditReference.didPrepareQueuePublicAuditReference == false) ||
        (auditReference.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            auditReference.didPrepareQueuePublicAuditReference == false) ||
        (auditReference.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            auditReference.didPrepareQueuePublicAuditReference) ||
        (auditReference.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            auditReference.shouldDeferQueuePublicAuditReference &&
            (
                auditReference.shouldReportQueuePublicAuditReferenceBlocked ||
                auditReference.shouldRejectQueuePublicAuditReference ||
                auditReference.shouldReportQueuePublicAuditReferenceIncompatible ||
                auditReference.shouldReportQueuePublicAuditReferenceUnauthorized
            )
        )

    // audit reference 不一致时必须 fail-closed，compatibility note 不能伪造 API readiness。
    if (
        auditReference.shouldReportQueuePublicAuditReferenceBlocked ||
        auditReference.shouldRejectQueuePublicAuditReference ||
        auditReference.shouldReportQueuePublicAuditReferenceIncompatible ||
        auditReference.shouldReportQueuePublicAuditReferenceUnauthorized ||
        auditInconsistent
    ) {
        return CjguiInternalQueuePublicCompatibilityNote(
            auditReference,
            false,
            false,
            false,
            false,
            true,
            true,
            auditReference.shouldReportQueuePublicAuditReferenceIncompatible || auditInconsistent,
            auditReference.shouldReportQueuePublicAuditReferenceUnauthorized,
            false,
            false,
            auditReference.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (auditReady) {
        // 当前不承诺稳定 public API 兼容性；这里只留下 future API surface 的 value-style note。
        return CjguiInternalQueuePublicCompatibilityNote(
            auditReference,
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
            true
        )
    }

    if (auditDeferred) {
        return CjguiInternalQueuePublicCompatibilityNote(
            auditReference,
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
            true
        )
    }

    return CjguiInternalQueuePublicCompatibilityNote(
        auditReference,
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
        auditReference.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueuePublicResultShapeDraft(): CjguiInternalQueuePublicCompatibilityNote {
    // 默认 draft 只串联 internal-only public response value facts；
    // 不是 public runtime API / C ABI，也不 real enqueue 或写 queue storage。
    let result = cjguiInternalExecuteDefaultQueuePublicApiAdmissionDraft()
    let shape = cjguiInternalBuildQueuePublicResponseShape(result)
    let envelope = cjguiInternalBuildQueuePublicResultEnvelope(shape)
    let errorProjection = cjguiInternalBuildQueuePublicErrorProjection(envelope)
    let auditReference = cjguiInternalBuildQueuePublicAuditReference(errorProjection)
    return cjguiInternalBuildQueuePublicCompatibilityNote(auditReference)
}

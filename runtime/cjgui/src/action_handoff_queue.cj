package cjgui

// Internal Action Handoff Queue Integration owner:
// - 本文件只消费 Action Handoff receipt 与 QueueAdmission readiness。
// - Truth 是 queue-adjacent handoff admission / integration / candidate 的内部 value facts。
// - Stop-line: 不写 queue storage、不 enqueue、不 drain、不执行 action、不接 event loop / scheduler /
//   platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Queue admission 只把 handoff receipt 与 queue readiness 对齐；
// 它不是 queue item、enqueue side effect 或 drain plan。
struct CjguiInternalActionHandoffQueueAdmission {
    let receipt: CjguiInternalActionHandoffReceipt
    let queueAdmission: CjguiInternalQueueAdmission
    let canAdmitActionHandoffToQueueBoundary: Bool
    let shouldDeferActionHandoffQueueAdmission: Bool
    let shouldReportActionHandoffQueueAdmissionBlocked: Bool
    let didPreserveActionHandoffReceipt: Bool
    let didPreserveQueueAdmission: Bool

    init(
        receipt: CjguiInternalActionHandoffReceipt,
        queueAdmission: CjguiInternalQueueAdmission,
        canAdmitActionHandoffToQueueBoundary: Bool,
        shouldDeferActionHandoffQueueAdmission: Bool,
        shouldReportActionHandoffQueueAdmissionBlocked: Bool,
        didPreserveActionHandoffReceipt: Bool,
        didPreserveQueueAdmission: Bool
    ) {
        this.receipt = receipt
        this.queueAdmission = queueAdmission
        this.canAdmitActionHandoffToQueueBoundary = canAdmitActionHandoffToQueueBoundary
        this.shouldDeferActionHandoffQueueAdmission = shouldDeferActionHandoffQueueAdmission
        this.shouldReportActionHandoffQueueAdmissionBlocked = shouldReportActionHandoffQueueAdmissionBlocked
        this.didPreserveActionHandoffReceipt = didPreserveActionHandoffReceipt
        this.didPreserveQueueAdmission = didPreserveQueueAdmission
    }
}

// Integration 只表达 handoff facts 与 queue admission facts 已形成内部集成候选；
// 它不创建 queue storage，也不调度后续 work。
struct CjguiInternalActionHandoffQueueIntegration {
    let admission: CjguiInternalActionHandoffQueueAdmission
    let didIntegrateActionHandoffWithQueue: Bool
    let shouldDeferActionHandoffQueueIntegration: Bool
    let shouldReportActionHandoffQueueIntegrationBlocked: Bool
    let didPreserveActionHandoffQueueAdmission: Bool

    init(
        admission: CjguiInternalActionHandoffQueueAdmission,
        didIntegrateActionHandoffWithQueue: Bool,
        shouldDeferActionHandoffQueueIntegration: Bool,
        shouldReportActionHandoffQueueIntegrationBlocked: Bool,
        didPreserveActionHandoffQueueAdmission: Bool
    ) {
        this.admission = admission
        this.didIntegrateActionHandoffWithQueue = didIntegrateActionHandoffWithQueue
        this.shouldDeferActionHandoffQueueIntegration = shouldDeferActionHandoffQueueIntegration
        this.shouldReportActionHandoffQueueIntegrationBlocked = shouldReportActionHandoffQueueIntegrationBlocked
        this.didPreserveActionHandoffQueueAdmission = didPreserveActionHandoffQueueAdmission
    }
}

// Candidate 是本轮 queue-adjacent canonical endpoint；
// 它只记录 internal integration candidate，不是 enqueue record、public audit 或执行结果。
struct CjguiInternalActionHandoffQueueCandidate {
    let integration: CjguiInternalActionHandoffQueueIntegration
    let isActionHandoffQueueCandidateReady: Bool
    let shouldDeferActionHandoffQueueCandidate: Bool
    let shouldReportActionHandoffQueueCandidateBlocked: Bool
    let didPreserveActionHandoffQueueIntegration: Bool

    init(
        integration: CjguiInternalActionHandoffQueueIntegration,
        isActionHandoffQueueCandidateReady: Bool,
        shouldDeferActionHandoffQueueCandidate: Bool,
        shouldReportActionHandoffQueueCandidateBlocked: Bool,
        didPreserveActionHandoffQueueIntegration: Bool
    ) {
        this.integration = integration
        this.isActionHandoffQueueCandidateReady = isActionHandoffQueueCandidateReady
        this.shouldDeferActionHandoffQueueCandidate = shouldDeferActionHandoffQueueCandidate
        this.shouldReportActionHandoffQueueCandidateBlocked = shouldReportActionHandoffQueueCandidateBlocked
        this.didPreserveActionHandoffQueueIntegration = didPreserveActionHandoffQueueIntegration
    }
}

func cjguiInternalBuildActionHandoffQueueAdmission(
    receipt: CjguiInternalActionHandoffReceipt,
    queueAdmission: CjguiInternalQueueAdmission
): CjguiInternalActionHandoffQueueAdmission {
    let receiptReady = receipt.didRecordActionHandoffReceipt &&
        receipt.shouldDeferActionHandoffReceipt == false &&
        receipt.shouldReportActionHandoffReceiptBlocked == false
    let receiptDeferred = receipt.didRecordActionHandoffReceipt == false &&
        receipt.shouldDeferActionHandoffReceipt &&
        receipt.shouldReportActionHandoffReceiptBlocked == false
    let receiptInconsistent = (
        receipt.didRecordActionHandoffReceipt &&
            (receipt.shouldDeferActionHandoffReceipt ||
                receipt.shouldReportActionHandoffReceiptBlocked)
        ) ||
        (receipt.shouldDeferActionHandoffReceipt &&
            receipt.shouldReportActionHandoffReceiptBlocked)

    let queueReady = queueAdmission.canAdmitToQueueBoundary &&
        queueAdmission.didPreserveIngressCandidate &&
        queueAdmission.shouldDeferQueueAdmission == false &&
        queueAdmission.shouldReportQueueAdmissionBlocked == false
    let queueDeferred = queueAdmission.canAdmitToQueueBoundary == false &&
        queueAdmission.didPreserveIngressCandidate == false &&
        queueAdmission.shouldDeferQueueAdmission &&
        queueAdmission.shouldReportQueueAdmissionBlocked == false
    let queueInconsistent = (
        queueAdmission.canAdmitToQueueBoundary &&
            (queueAdmission.shouldDeferQueueAdmission ||
                queueAdmission.shouldReportQueueAdmissionBlocked)
        ) ||
        (queueAdmission.didPreserveIngressCandidate &&
            queueAdmission.canAdmitToQueueBoundary == false) ||
        (queueAdmission.didPreserveIngressCandidate == false &&
            queueAdmission.canAdmitToQueueBoundary) ||
        (queueAdmission.shouldDeferQueueAdmission &&
            queueAdmission.shouldReportQueueAdmissionBlocked)

    // receipt 或 queue readiness 不一致时必须 fail-closed，避免伪造 queue-adjacent admission。
    if (
        receipt.shouldReportActionHandoffReceiptBlocked ||
        queueAdmission.shouldReportQueueAdmissionBlocked ||
        receiptInconsistent ||
        queueInconsistent
    ) {
        return CjguiInternalActionHandoffQueueAdmission(
            receipt,
            queueAdmission,
            false,
            false,
            true,
            false,
            false
        )
    }

    if (receiptReady && queueReady) {
        return CjguiInternalActionHandoffQueueAdmission(
            receipt,
            queueAdmission,
            true,
            false,
            false,
            true,
            true
        )
    }

    if (receiptDeferred || queueDeferred) {
        return CjguiInternalActionHandoffQueueAdmission(
            receipt,
            queueAdmission,
            false,
            true,
            false,
            false,
            false
        )
    }

    return CjguiInternalActionHandoffQueueAdmission(
        receipt,
        queueAdmission,
        false,
        false,
        true,
        false,
        false
    )
}

func cjguiInternalBuildActionHandoffQueueIntegration(
    admission: CjguiInternalActionHandoffQueueAdmission
): CjguiInternalActionHandoffQueueIntegration {
    let admissionReady = admission.canAdmitActionHandoffToQueueBoundary &&
        admission.didPreserveActionHandoffReceipt &&
        admission.didPreserveQueueAdmission &&
        admission.shouldDeferActionHandoffQueueAdmission == false &&
        admission.shouldReportActionHandoffQueueAdmissionBlocked == false
    let admissionDeferred = admission.canAdmitActionHandoffToQueueBoundary == false &&
        admission.didPreserveActionHandoffReceipt == false &&
        admission.didPreserveQueueAdmission == false &&
        admission.shouldDeferActionHandoffQueueAdmission &&
        admission.shouldReportActionHandoffQueueAdmissionBlocked == false
    let admissionInconsistent = (
        admission.canAdmitActionHandoffToQueueBoundary &&
            (admission.shouldDeferActionHandoffQueueAdmission ||
                admission.shouldReportActionHandoffQueueAdmissionBlocked)
        ) ||
        (admission.didPreserveActionHandoffReceipt &&
            admission.canAdmitActionHandoffToQueueBoundary == false) ||
        (admission.didPreserveQueueAdmission &&
            admission.canAdmitActionHandoffToQueueBoundary == false) ||
        (admission.didPreserveActionHandoffReceipt == false &&
            admission.canAdmitActionHandoffToQueueBoundary) ||
        (admission.didPreserveQueueAdmission == false &&
            admission.canAdmitActionHandoffToQueueBoundary) ||
        (admission.shouldDeferActionHandoffQueueAdmission &&
            admission.shouldReportActionHandoffQueueAdmissionBlocked)

    // admission facts 不一致时必须 fail-closed，integration 不能变成隐式 enqueue。
    if (admission.shouldReportActionHandoffQueueAdmissionBlocked || admissionInconsistent) {
        return CjguiInternalActionHandoffQueueIntegration(admission, false, false, true, false)
    }

    if (admissionDeferred) {
        return CjguiInternalActionHandoffQueueIntegration(admission, false, true, false, false)
    }

    if (admissionReady) {
        return CjguiInternalActionHandoffQueueIntegration(admission, true, false, false, true)
    }

    return CjguiInternalActionHandoffQueueIntegration(admission, false, false, true, false)
}

func cjguiInternalBuildActionHandoffQueueCandidate(
    integration: CjguiInternalActionHandoffQueueIntegration
): CjguiInternalActionHandoffQueueCandidate {
    let integrationReady = integration.didIntegrateActionHandoffWithQueue &&
        integration.didPreserveActionHandoffQueueAdmission &&
        integration.shouldDeferActionHandoffQueueIntegration == false &&
        integration.shouldReportActionHandoffQueueIntegrationBlocked == false
    let integrationDeferred = integration.didIntegrateActionHandoffWithQueue == false &&
        integration.didPreserveActionHandoffQueueAdmission == false &&
        integration.shouldDeferActionHandoffQueueIntegration &&
        integration.shouldReportActionHandoffQueueIntegrationBlocked == false
    let integrationInconsistent = (
        integration.didIntegrateActionHandoffWithQueue &&
            (integration.shouldDeferActionHandoffQueueIntegration ||
                integration.shouldReportActionHandoffQueueIntegrationBlocked)
        ) ||
        (integration.didPreserveActionHandoffQueueAdmission &&
            integration.didIntegrateActionHandoffWithQueue == false) ||
        (integration.didPreserveActionHandoffQueueAdmission == false &&
            integration.didIntegrateActionHandoffWithQueue) ||
        (integration.shouldDeferActionHandoffQueueIntegration &&
            integration.shouldReportActionHandoffQueueIntegrationBlocked)

    // integration facts 不一致时必须 fail-closed，candidate 不能被误读为 queue item。
    if (integration.shouldReportActionHandoffQueueIntegrationBlocked || integrationInconsistent) {
        return CjguiInternalActionHandoffQueueCandidate(integration, false, false, true, false)
    }

    if (integrationDeferred) {
        return CjguiInternalActionHandoffQueueCandidate(integration, false, true, false, false)
    }

    if (integrationReady) {
        return CjguiInternalActionHandoffQueueCandidate(integration, true, false, false, true)
    }

    return CjguiInternalActionHandoffQueueCandidate(integration, false, false, true, false)
}

func cjguiInternalExecuteDefaultActionHandoffQueueIntegrationDraft(
): CjguiInternalActionHandoffQueueCandidate {
    // 默认 draft 只串联 receipt 与 queue admission value pipeline，不写 queue 或执行 action。
    let receipt = cjguiInternalExecuteDefaultActionHandoffReceiptDraft()
    let queueAdmission = cjguiInternalExecuteDefaultQueueAdmissionDraft()
    let admission = cjguiInternalBuildActionHandoffQueueAdmission(receipt, queueAdmission)
    let integration = cjguiInternalBuildActionHandoffQueueIntegration(admission)
    return cjguiInternalBuildActionHandoffQueueCandidate(integration)
}

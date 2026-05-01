package cjgui

// Internal Action Handoff owner:
// - 本文件只消费 Action Router canonical handoff endpoint。
// - Truth 是 downstream consumer / acceptance / receipt 的内部 value facts。
// - Stop-line: 不执行 action、不写 queue、不接 provider / public API / event loop / platform、
//   不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Consumer 是 handoff endpoint 的第一个 downstream 接收边界；
// 它只记录内部接收事实，不是 queue enqueue、observer callback 或真实 action execution。
struct CjguiInternalActionHandoffConsumer {
    let handoff: CjguiInternalActionGuardedExecutionHandoffCandidate
    let didReceiveActionHandoff: Bool
    let shouldDeferActionHandoffConsumer: Bool
    let shouldReportActionHandoffConsumerBlocked: Bool
    let didPreserveActionHandoffCandidate: Bool

    init(
        handoff: CjguiInternalActionGuardedExecutionHandoffCandidate,
        didReceiveActionHandoff: Bool,
        shouldDeferActionHandoffConsumer: Bool,
        shouldReportActionHandoffConsumerBlocked: Bool,
        didPreserveActionHandoffCandidate: Bool
    ) {
        this.handoff = handoff
        this.didReceiveActionHandoff = didReceiveActionHandoff
        this.shouldDeferActionHandoffConsumer = shouldDeferActionHandoffConsumer
        this.shouldReportActionHandoffConsumerBlocked = shouldReportActionHandoffConsumerBlocked
        this.didPreserveActionHandoffCandidate = didPreserveActionHandoffCandidate
    }
}

// Acceptance 只表达 downstream consumer 是否接受 handoff facts；
// 它不是执行许可、queue commit 或 public audit。
struct CjguiInternalActionHandoffAcceptance {
    let consumer: CjguiInternalActionHandoffConsumer
    let didAcceptActionHandoff: Bool
    let shouldDeferActionHandoffAcceptance: Bool
    let shouldReportActionHandoffAcceptanceBlocked: Bool
    let didPreserveActionHandoffConsumer: Bool

    init(
        consumer: CjguiInternalActionHandoffConsumer,
        didAcceptActionHandoff: Bool,
        shouldDeferActionHandoffAcceptance: Bool,
        shouldReportActionHandoffAcceptanceBlocked: Bool,
        didPreserveActionHandoffConsumer: Bool
    ) {
        this.consumer = consumer
        this.didAcceptActionHandoff = didAcceptActionHandoff
        this.shouldDeferActionHandoffAcceptance = shouldDeferActionHandoffAcceptance
        this.shouldReportActionHandoffAcceptanceBlocked = shouldReportActionHandoffAcceptanceBlocked
        this.didPreserveActionHandoffConsumer = didPreserveActionHandoffConsumer
    }
}

// Receipt 是 downstream handoff 的 canonical endpoint；
// 它只记录内部 value receipt，不是外部通知、public audit log 或执行结果。
struct CjguiInternalActionHandoffReceipt {
    let acceptance: CjguiInternalActionHandoffAcceptance
    let didRecordActionHandoffReceipt: Bool
    let shouldDeferActionHandoffReceipt: Bool
    let shouldReportActionHandoffReceiptBlocked: Bool

    init(
        acceptance: CjguiInternalActionHandoffAcceptance,
        didRecordActionHandoffReceipt: Bool,
        shouldDeferActionHandoffReceipt: Bool,
        shouldReportActionHandoffReceiptBlocked: Bool
    ) {
        this.acceptance = acceptance
        this.didRecordActionHandoffReceipt = didRecordActionHandoffReceipt
        this.shouldDeferActionHandoffReceipt = shouldDeferActionHandoffReceipt
        this.shouldReportActionHandoffReceiptBlocked = shouldReportActionHandoffReceiptBlocked
    }
}

func cjguiInternalBuildActionHandoffConsumer(
    handoff: CjguiInternalActionGuardedExecutionHandoffCandidate
): CjguiInternalActionHandoffConsumer {
    let handoffReady = handoff.canHandoffGuardedExecutionResult &&
        handoff.didPreserveGuardedExecutionPublication &&
        handoff.shouldDeferGuardedExecutionHandoff == false &&
        handoff.shouldReportGuardedExecutionHandoffBlocked == false
    let handoffDeferred = handoff.canHandoffGuardedExecutionResult == false &&
        handoff.didPreserveGuardedExecutionPublication == false &&
        handoff.shouldDeferGuardedExecutionHandoff &&
        handoff.shouldReportGuardedExecutionHandoffBlocked == false
    let handoffInconsistent = (
        handoff.canHandoffGuardedExecutionResult &&
            (handoff.shouldDeferGuardedExecutionHandoff ||
                handoff.shouldReportGuardedExecutionHandoffBlocked)
        ) ||
        (handoff.didPreserveGuardedExecutionPublication &&
            handoff.canHandoffGuardedExecutionResult == false) ||
        (handoff.didPreserveGuardedExecutionPublication == false &&
            handoff.canHandoffGuardedExecutionResult) ||
        (handoff.shouldDeferGuardedExecutionHandoff &&
            handoff.shouldReportGuardedExecutionHandoffBlocked)

    // handoff facts 不一致时必须 fail-closed，防止 downstream consumer 误接收伪造候选。
    if (handoff.shouldReportGuardedExecutionHandoffBlocked || handoffInconsistent) {
        return CjguiInternalActionHandoffConsumer(handoff, false, false, true, false)
    }

    if (handoffDeferred) {
        return CjguiInternalActionHandoffConsumer(handoff, false, true, false, false)
    }

    if (handoffReady) {
        return CjguiInternalActionHandoffConsumer(handoff, true, false, false, true)
    }

    return CjguiInternalActionHandoffConsumer(handoff, false, false, true, false)
}

func cjguiInternalEvaluateActionHandoffAcceptance(
    consumer: CjguiInternalActionHandoffConsumer
): CjguiInternalActionHandoffAcceptance {
    let consumerReady = consumer.didReceiveActionHandoff &&
        consumer.didPreserveActionHandoffCandidate &&
        consumer.shouldDeferActionHandoffConsumer == false &&
        consumer.shouldReportActionHandoffConsumerBlocked == false
    let consumerDeferred = consumer.didReceiveActionHandoff == false &&
        consumer.didPreserveActionHandoffCandidate == false &&
        consumer.shouldDeferActionHandoffConsumer &&
        consumer.shouldReportActionHandoffConsumerBlocked == false
    let consumerInconsistent = (
        consumer.didReceiveActionHandoff &&
            (consumer.shouldDeferActionHandoffConsumer ||
                consumer.shouldReportActionHandoffConsumerBlocked)
        ) ||
        (consumer.didPreserveActionHandoffCandidate &&
            consumer.didReceiveActionHandoff == false) ||
        (consumer.didPreserveActionHandoffCandidate == false &&
            consumer.didReceiveActionHandoff) ||
        (consumer.shouldDeferActionHandoffConsumer &&
            consumer.shouldReportActionHandoffConsumerBlocked)

    // consumer facts 不一致时必须 fail-closed，acceptance 不能伪造 downstream 接受。
    if (consumer.shouldReportActionHandoffConsumerBlocked || consumerInconsistent) {
        return CjguiInternalActionHandoffAcceptance(consumer, false, false, true, false)
    }

    if (consumerDeferred) {
        return CjguiInternalActionHandoffAcceptance(consumer, false, true, false, false)
    }

    if (consumerReady) {
        return CjguiInternalActionHandoffAcceptance(consumer, true, false, false, true)
    }

    return CjguiInternalActionHandoffAcceptance(consumer, false, false, true, false)
}

func cjguiInternalBuildActionHandoffReceipt(
    acceptance: CjguiInternalActionHandoffAcceptance
): CjguiInternalActionHandoffReceipt {
    let acceptanceReady = acceptance.didAcceptActionHandoff &&
        acceptance.didPreserveActionHandoffConsumer &&
        acceptance.shouldDeferActionHandoffAcceptance == false &&
        acceptance.shouldReportActionHandoffAcceptanceBlocked == false
    let acceptanceDeferred = acceptance.didAcceptActionHandoff == false &&
        acceptance.didPreserveActionHandoffConsumer == false &&
        acceptance.shouldDeferActionHandoffAcceptance &&
        acceptance.shouldReportActionHandoffAcceptanceBlocked == false
    let acceptanceInconsistent = (
        acceptance.didAcceptActionHandoff &&
            (acceptance.shouldDeferActionHandoffAcceptance ||
                acceptance.shouldReportActionHandoffAcceptanceBlocked)
        ) ||
        (acceptance.didPreserveActionHandoffConsumer &&
            acceptance.didAcceptActionHandoff == false) ||
        (acceptance.didPreserveActionHandoffConsumer == false &&
            acceptance.didAcceptActionHandoff) ||
        (acceptance.shouldDeferActionHandoffAcceptance &&
            acceptance.shouldReportActionHandoffAcceptanceBlocked)

    // acceptance facts 不一致时必须 fail-closed，receipt 不能被误当成执行结果。
    if (acceptance.shouldReportActionHandoffAcceptanceBlocked || acceptanceInconsistent) {
        return CjguiInternalActionHandoffReceipt(acceptance, false, false, true)
    }

    if (acceptanceDeferred) {
        return CjguiInternalActionHandoffReceipt(acceptance, false, true, false)
    }

    if (acceptanceReady) {
        return CjguiInternalActionHandoffReceipt(acceptance, true, false, false)
    }

    return CjguiInternalActionHandoffReceipt(acceptance, false, false, true)
}

func cjguiInternalExecuteDefaultActionHandoffReceiptDraft(): CjguiInternalActionHandoffReceipt {
    // 默认 draft 只串联 Action Router handoff value pipeline，不执行 action 或写 queue。
    let handoff = cjguiInternalExecuteDefaultActionGuardedExecutionResultPublicationDraft()
    let consumer = cjguiInternalBuildActionHandoffConsumer(handoff)
    let acceptance = cjguiInternalEvaluateActionHandoffAcceptance(consumer)
    return cjguiInternalBuildActionHandoffReceipt(acceptance)
}

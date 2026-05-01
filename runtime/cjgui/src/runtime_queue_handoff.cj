package cjgui

// Internal Queue Handoff owner:
// - 本文件只消费 ActionHandoffQueueCandidate。
// - Truth 是 queue-side consumer / acceptance / gate 的内部 value facts。
// - Stop-line: 不写 queue storage、不 enqueue、不 drain、不执行 action、不接 event loop /
//   scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Queue handoff consumer 表达 queue owner 已接收 handoff candidate facts；
// 它不是 queue item、enqueue record、drain plan 或 scheduler task。
struct CjguiInternalQueueHandoffConsumer {
    let candidate: CjguiInternalActionHandoffQueueCandidate
    let didConsumeActionHandoffQueueCandidate: Bool
    let shouldDeferQueueHandoffConsumer: Bool
    let shouldReportQueueHandoffConsumerBlocked: Bool
    let didPreserveActionHandoffQueueCandidate: Bool

    init(
        candidate: CjguiInternalActionHandoffQueueCandidate,
        didConsumeActionHandoffQueueCandidate: Bool,
        shouldDeferQueueHandoffConsumer: Bool,
        shouldReportQueueHandoffConsumerBlocked: Bool,
        didPreserveActionHandoffQueueCandidate: Bool
    ) {
        this.candidate = candidate
        this.didConsumeActionHandoffQueueCandidate = didConsumeActionHandoffQueueCandidate
        this.shouldDeferQueueHandoffConsumer = shouldDeferQueueHandoffConsumer
        this.shouldReportQueueHandoffConsumerBlocked = shouldReportQueueHandoffConsumerBlocked
        this.didPreserveActionHandoffQueueCandidate = didPreserveActionHandoffQueueCandidate
    }
}

// Queue handoff acceptance 只确认 consumer facts 可被 queue-side boundary 接受；
// 它不是 enqueue permission，也不产生任何 queue mutation。
struct CjguiInternalQueueHandoffAcceptance {
    let consumer: CjguiInternalQueueHandoffConsumer
    let didAcceptQueueHandoff: Bool
    let shouldDeferQueueHandoffAcceptance: Bool
    let shouldReportQueueHandoffAcceptanceBlocked: Bool
    let didPreserveQueueHandoffConsumer: Bool

    init(
        consumer: CjguiInternalQueueHandoffConsumer,
        didAcceptQueueHandoff: Bool,
        shouldDeferQueueHandoffAcceptance: Bool,
        shouldReportQueueHandoffAcceptanceBlocked: Bool,
        didPreserveQueueHandoffConsumer: Bool
    ) {
        this.consumer = consumer
        this.didAcceptQueueHandoff = didAcceptQueueHandoff
        this.shouldDeferQueueHandoffAcceptance = shouldDeferQueueHandoffAcceptance
        this.shouldReportQueueHandoffAcceptanceBlocked = shouldReportQueueHandoffAcceptanceBlocked
        this.didPreserveQueueHandoffConsumer = didPreserveQueueHandoffConsumer
    }
}

// Queue handoff gate 是本轮 queue-side canonical endpoint；
// gate open 只表示 value facts 可继续流向未来 queue boundary，不是 enqueue 或 drain。
struct CjguiInternalQueueHandoffGate {
    let acceptance: CjguiInternalQueueHandoffAcceptance
    let isQueueHandoffGateOpen: Bool
    let shouldDeferQueueHandoffGate: Bool
    let shouldReportQueueHandoffGateBlocked: Bool
    let didPreserveQueueHandoffAcceptance: Bool

    init(
        acceptance: CjguiInternalQueueHandoffAcceptance,
        isQueueHandoffGateOpen: Bool,
        shouldDeferQueueHandoffGate: Bool,
        shouldReportQueueHandoffGateBlocked: Bool,
        didPreserveQueueHandoffAcceptance: Bool
    ) {
        this.acceptance = acceptance
        this.isQueueHandoffGateOpen = isQueueHandoffGateOpen
        this.shouldDeferQueueHandoffGate = shouldDeferQueueHandoffGate
        this.shouldReportQueueHandoffGateBlocked = shouldReportQueueHandoffGateBlocked
        this.didPreserveQueueHandoffAcceptance = didPreserveQueueHandoffAcceptance
    }
}

func cjguiInternalBuildQueueHandoffConsumer(
    candidate: CjguiInternalActionHandoffQueueCandidate
): CjguiInternalQueueHandoffConsumer {
    let candidateReady = candidate.isActionHandoffQueueCandidateReady &&
        candidate.didPreserveActionHandoffQueueIntegration &&
        candidate.shouldDeferActionHandoffQueueCandidate == false &&
        candidate.shouldReportActionHandoffQueueCandidateBlocked == false
    let candidateDeferred = candidate.isActionHandoffQueueCandidateReady == false &&
        candidate.didPreserveActionHandoffQueueIntegration == false &&
        candidate.shouldDeferActionHandoffQueueCandidate &&
        candidate.shouldReportActionHandoffQueueCandidateBlocked == false
    let candidateInconsistent = (
        candidate.isActionHandoffQueueCandidateReady &&
            (candidate.shouldDeferActionHandoffQueueCandidate ||
                candidate.shouldReportActionHandoffQueueCandidateBlocked)
        ) ||
        (candidate.didPreserveActionHandoffQueueIntegration &&
            candidate.isActionHandoffQueueCandidateReady == false) ||
        (candidate.didPreserveActionHandoffQueueIntegration == false &&
            candidate.isActionHandoffQueueCandidateReady) ||
        (candidate.shouldDeferActionHandoffQueueCandidate &&
            candidate.shouldReportActionHandoffQueueCandidateBlocked)

    // candidate facts 不一致时必须 fail-closed，避免把 handoff candidate 误当作 queue item。
    if (
        candidate.shouldReportActionHandoffQueueCandidateBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalQueueHandoffConsumer(candidate, false, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalQueueHandoffConsumer(candidate, true, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalQueueHandoffConsumer(candidate, false, true, false, false)
    }

    return CjguiInternalQueueHandoffConsumer(candidate, false, false, true, false)
}

func cjguiInternalBuildQueueHandoffAcceptance(
    consumer: CjguiInternalQueueHandoffConsumer
): CjguiInternalQueueHandoffAcceptance {
    let consumerReady = consumer.didConsumeActionHandoffQueueCandidate &&
        consumer.didPreserveActionHandoffQueueCandidate &&
        consumer.shouldDeferQueueHandoffConsumer == false &&
        consumer.shouldReportQueueHandoffConsumerBlocked == false
    let consumerDeferred = consumer.didConsumeActionHandoffQueueCandidate == false &&
        consumer.didPreserveActionHandoffQueueCandidate == false &&
        consumer.shouldDeferQueueHandoffConsumer &&
        consumer.shouldReportQueueHandoffConsumerBlocked == false
    let consumerInconsistent = (
        consumer.didConsumeActionHandoffQueueCandidate &&
            (consumer.shouldDeferQueueHandoffConsumer ||
                consumer.shouldReportQueueHandoffConsumerBlocked)
        ) ||
        (consumer.didPreserveActionHandoffQueueCandidate &&
            consumer.didConsumeActionHandoffQueueCandidate == false) ||
        (consumer.didPreserveActionHandoffQueueCandidate == false &&
            consumer.didConsumeActionHandoffQueueCandidate) ||
        (consumer.shouldDeferQueueHandoffConsumer &&
            consumer.shouldReportQueueHandoffConsumerBlocked)

    // consumer facts 不一致时必须 fail-closed，acceptance 不能伪造成 enqueue permission。
    if (consumer.shouldReportQueueHandoffConsumerBlocked || consumerInconsistent) {
        return CjguiInternalQueueHandoffAcceptance(consumer, false, false, true, false)
    }

    if (consumerReady) {
        return CjguiInternalQueueHandoffAcceptance(consumer, true, false, false, true)
    }

    if (consumerDeferred) {
        return CjguiInternalQueueHandoffAcceptance(consumer, false, true, false, false)
    }

    return CjguiInternalQueueHandoffAcceptance(consumer, false, false, true, false)
}

func cjguiInternalBuildQueueHandoffGate(
    acceptance: CjguiInternalQueueHandoffAcceptance
): CjguiInternalQueueHandoffGate {
    let acceptanceReady = acceptance.didAcceptQueueHandoff &&
        acceptance.didPreserveQueueHandoffConsumer &&
        acceptance.shouldDeferQueueHandoffAcceptance == false &&
        acceptance.shouldReportQueueHandoffAcceptanceBlocked == false
    let acceptanceDeferred = acceptance.didAcceptQueueHandoff == false &&
        acceptance.didPreserveQueueHandoffConsumer == false &&
        acceptance.shouldDeferQueueHandoffAcceptance &&
        acceptance.shouldReportQueueHandoffAcceptanceBlocked == false
    let acceptanceInconsistent = (
        acceptance.didAcceptQueueHandoff &&
            (acceptance.shouldDeferQueueHandoffAcceptance ||
                acceptance.shouldReportQueueHandoffAcceptanceBlocked)
        ) ||
        (acceptance.didPreserveQueueHandoffConsumer &&
            acceptance.didAcceptQueueHandoff == false) ||
        (acceptance.didPreserveQueueHandoffConsumer == false &&
            acceptance.didAcceptQueueHandoff) ||
        (acceptance.shouldDeferQueueHandoffAcceptance &&
            acceptance.shouldReportQueueHandoffAcceptanceBlocked)

    // acceptance facts 不一致时必须 fail-closed，gate open 不能被误读为 queue enqueue。
    if (acceptance.shouldReportQueueHandoffAcceptanceBlocked || acceptanceInconsistent) {
        return CjguiInternalQueueHandoffGate(acceptance, false, false, true, false)
    }

    if (acceptanceReady) {
        return CjguiInternalQueueHandoffGate(acceptance, true, false, false, true)
    }

    if (acceptanceDeferred) {
        return CjguiInternalQueueHandoffGate(acceptance, false, true, false, false)
    }

    return CjguiInternalQueueHandoffGate(acceptance, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueueHandoffConsumerDraft(): CjguiInternalQueueHandoffGate {
    // 默认 draft 只串联 queue-side handoff value pipeline，不写 queue、不 enqueue、不 drain。
    let candidate = cjguiInternalExecuteDefaultActionHandoffQueueIntegrationDraft()
    let consumer = cjguiInternalBuildQueueHandoffConsumer(candidate)
    let acceptance = cjguiInternalBuildQueueHandoffAcceptance(consumer)
    return cjguiInternalBuildQueueHandoffGate(acceptance)
}

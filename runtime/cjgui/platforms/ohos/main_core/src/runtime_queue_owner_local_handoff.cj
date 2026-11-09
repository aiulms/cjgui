package cjgui

// Internal Queue Owner-Local Write Handoff owner:
// - 本文件只消费 QueueOwnerLocalWriteResult。
// - Truth 是 downstream handoff consumer / acceptance / receipt 的内部 value facts。
// - Stop-line: 不写 process-wide queue storage、不创建 global mutable queue / singleton、不做 item collection mutation、
//   不公开 public API / C ABI、不 enqueue、不 drain、不接 event loop / scheduler / platform callback、不调用 runtime cycle，
//   也不回塞 critical runtime_state.cj。

// Owner-local write handoff consumer 是 write result 离开 realization owner 后的 downstream 接收边界；
// 它只记录内部接收事实，不是 public publication、observer callback、enqueue record 或真实队列写入。
struct CjguiInternalQueueOwnerLocalWriteHandoffConsumer {
    let result: CjguiInternalQueueOwnerLocalWriteResult
    let didConsumeQueueOwnerLocalWriteResult: Bool
    let shouldDeferQueueOwnerLocalWriteHandoffConsumer: Bool
    let shouldReportQueueOwnerLocalWriteHandoffConsumerBlocked: Bool
    let didPreserveQueueOwnerLocalWriteResult: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        result: CjguiInternalQueueOwnerLocalWriteResult,
        didConsumeQueueOwnerLocalWriteResult: Bool,
        shouldDeferQueueOwnerLocalWriteHandoffConsumer: Bool,
        shouldReportQueueOwnerLocalWriteHandoffConsumerBlocked: Bool,
        didPreserveQueueOwnerLocalWriteResult: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.result = result
        this.didConsumeQueueOwnerLocalWriteResult = didConsumeQueueOwnerLocalWriteResult
        this.shouldDeferQueueOwnerLocalWriteHandoffConsumer = shouldDeferQueueOwnerLocalWriteHandoffConsumer
        this.shouldReportQueueOwnerLocalWriteHandoffConsumerBlocked = shouldReportQueueOwnerLocalWriteHandoffConsumerBlocked
        this.didPreserveQueueOwnerLocalWriteResult = didPreserveQueueOwnerLocalWriteResult
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Owner-local write handoff acceptance 只说明 downstream consumer facts 可被 handoff owner 接受；
// 它不是 process-wide storage write admission，也不是 public enqueue permission。
struct CjguiInternalQueueOwnerLocalWriteHandoffAcceptance {
    let consumer: CjguiInternalQueueOwnerLocalWriteHandoffConsumer
    let didAcceptQueueOwnerLocalWriteHandoff: Bool
    let shouldDeferQueueOwnerLocalWriteHandoffAcceptance: Bool
    let shouldReportQueueOwnerLocalWriteHandoffAcceptanceBlocked: Bool
    let didPreserveQueueOwnerLocalWriteHandoffConsumer: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        consumer: CjguiInternalQueueOwnerLocalWriteHandoffConsumer,
        didAcceptQueueOwnerLocalWriteHandoff: Bool,
        shouldDeferQueueOwnerLocalWriteHandoffAcceptance: Bool,
        shouldReportQueueOwnerLocalWriteHandoffAcceptanceBlocked: Bool,
        didPreserveQueueOwnerLocalWriteHandoffConsumer: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.consumer = consumer
        this.didAcceptQueueOwnerLocalWriteHandoff = didAcceptQueueOwnerLocalWriteHandoff
        this.shouldDeferQueueOwnerLocalWriteHandoffAcceptance = shouldDeferQueueOwnerLocalWriteHandoffAcceptance
        this.shouldReportQueueOwnerLocalWriteHandoffAcceptanceBlocked = shouldReportQueueOwnerLocalWriteHandoffAcceptanceBlocked
        this.didPreserveQueueOwnerLocalWriteHandoffConsumer = didPreserveQueueOwnerLocalWriteHandoffConsumer
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Owner-local write handoff receipt 是本轮 downstream handoff canonical endpoint；
// receipt 只表示内部 handoff 已记录，不是 public publication、observer callback 或真实 queue result。
struct CjguiInternalQueueOwnerLocalWriteHandoffReceipt {
    let acceptance: CjguiInternalQueueOwnerLocalWriteHandoffAcceptance
    let didRecordQueueOwnerLocalWriteHandoffReceipt: Bool
    let shouldDeferQueueOwnerLocalWriteHandoffReceipt: Bool
    let shouldReportQueueOwnerLocalWriteHandoffReceiptBlocked: Bool
    let didPreserveQueueOwnerLocalWriteHandoffAcceptance: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        acceptance: CjguiInternalQueueOwnerLocalWriteHandoffAcceptance,
        didRecordQueueOwnerLocalWriteHandoffReceipt: Bool,
        shouldDeferQueueOwnerLocalWriteHandoffReceipt: Bool,
        shouldReportQueueOwnerLocalWriteHandoffReceiptBlocked: Bool,
        didPreserveQueueOwnerLocalWriteHandoffAcceptance: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.acceptance = acceptance
        this.didRecordQueueOwnerLocalWriteHandoffReceipt = didRecordQueueOwnerLocalWriteHandoffReceipt
        this.shouldDeferQueueOwnerLocalWriteHandoffReceipt = shouldDeferQueueOwnerLocalWriteHandoffReceipt
        this.shouldReportQueueOwnerLocalWriteHandoffReceiptBlocked = shouldReportQueueOwnerLocalWriteHandoffReceiptBlocked
        this.didPreserveQueueOwnerLocalWriteHandoffAcceptance = didPreserveQueueOwnerLocalWriteHandoffAcceptance
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueueOwnerLocalWriteHandoffConsumer(
    result: CjguiInternalQueueOwnerLocalWriteResult
): CjguiInternalQueueOwnerLocalWriteHandoffConsumer {
    let resultReady = result.isQueueOwnerLocalWriteResultReady &&
        result.didRealizeQueueOwnerLocalWrite &&
        result.didPreserveQueueOwnerLocalPostWriteHolder &&
        result.didPreservePreviousQueueStoreSnapshot &&
        result.shouldDeferQueueOwnerLocalWriteResult == false &&
        result.shouldReportQueueOwnerLocalWriteResultBlocked == false
    let resultDeferred = result.isQueueOwnerLocalWriteResultReady == false &&
        result.didRealizeQueueOwnerLocalWrite == false &&
        result.didPreserveQueueOwnerLocalPostWriteHolder == false &&
        result.didPreservePreviousQueueStoreSnapshot &&
        result.shouldDeferQueueOwnerLocalWriteResult &&
        result.shouldReportQueueOwnerLocalWriteResultBlocked == false
    let resultInconsistent = (
        result.isQueueOwnerLocalWriteResultReady &&
            (
                result.shouldDeferQueueOwnerLocalWriteResult ||
                result.shouldReportQueueOwnerLocalWriteResultBlocked
            )
        ) ||
        (result.didRealizeQueueOwnerLocalWrite &&
            result.isQueueOwnerLocalWriteResultReady == false) ||
        (result.didRealizeQueueOwnerLocalWrite == false &&
            result.isQueueOwnerLocalWriteResultReady) ||
        (result.didPreserveQueueOwnerLocalPostWriteHolder &&
            result.isQueueOwnerLocalWriteResultReady == false) ||
        (result.didPreserveQueueOwnerLocalPostWriteHolder == false &&
            result.isQueueOwnerLocalWriteResultReady) ||
        (result.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            result.shouldDeferQueueOwnerLocalWriteResult &&
            result.shouldReportQueueOwnerLocalWriteResultBlocked
        )

    // write result facts 不一致时必须 fail-closed，避免 downstream handoff 接收伪造成功结果。
    if (
        result.shouldReportQueueOwnerLocalWriteResultBlocked ||
        resultInconsistent
    ) {
        return CjguiInternalQueueOwnerLocalWriteHandoffConsumer(
            result,
            false,
            false,
            true,
            false,
            result.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (resultReady) {
        return CjguiInternalQueueOwnerLocalWriteHandoffConsumer(result, true, false, false, true, true)
    }

    if (resultDeferred) {
        return CjguiInternalQueueOwnerLocalWriteHandoffConsumer(
            result,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueOwnerLocalWriteHandoffConsumer(
        result,
        false,
        false,
        true,
        false,
        result.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueOwnerLocalWriteHandoffAcceptance(
    consumer: CjguiInternalQueueOwnerLocalWriteHandoffConsumer
): CjguiInternalQueueOwnerLocalWriteHandoffAcceptance {
    let consumerReady = consumer.didConsumeQueueOwnerLocalWriteResult &&
        consumer.didPreserveQueueOwnerLocalWriteResult &&
        consumer.didPreservePreviousQueueStoreSnapshot &&
        consumer.shouldDeferQueueOwnerLocalWriteHandoffConsumer == false &&
        consumer.shouldReportQueueOwnerLocalWriteHandoffConsumerBlocked == false
    let consumerDeferred = consumer.didConsumeQueueOwnerLocalWriteResult == false &&
        consumer.didPreserveQueueOwnerLocalWriteResult == false &&
        consumer.didPreservePreviousQueueStoreSnapshot &&
        consumer.shouldDeferQueueOwnerLocalWriteHandoffConsumer &&
        consumer.shouldReportQueueOwnerLocalWriteHandoffConsumerBlocked == false
    let consumerInconsistent = (
        consumer.didConsumeQueueOwnerLocalWriteResult &&
            (
                consumer.shouldDeferQueueOwnerLocalWriteHandoffConsumer ||
                consumer.shouldReportQueueOwnerLocalWriteHandoffConsumerBlocked
            )
        ) ||
        (consumer.didPreserveQueueOwnerLocalWriteResult &&
            consumer.didConsumeQueueOwnerLocalWriteResult == false) ||
        (consumer.didPreserveQueueOwnerLocalWriteResult == false &&
            consumer.didConsumeQueueOwnerLocalWriteResult) ||
        (consumer.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            consumer.shouldDeferQueueOwnerLocalWriteHandoffConsumer &&
            consumer.shouldReportQueueOwnerLocalWriteHandoffConsumerBlocked
        )

    // consumer facts 不一致时必须 fail-closed，acceptance 不能伪造成 public publication。
    if (
        consumer.shouldReportQueueOwnerLocalWriteHandoffConsumerBlocked ||
        consumerInconsistent
    ) {
        return CjguiInternalQueueOwnerLocalWriteHandoffAcceptance(
            consumer,
            false,
            false,
            true,
            false,
            consumer.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (consumerReady) {
        return CjguiInternalQueueOwnerLocalWriteHandoffAcceptance(consumer, true, false, false, true, true)
    }

    if (consumerDeferred) {
        return CjguiInternalQueueOwnerLocalWriteHandoffAcceptance(
            consumer,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueOwnerLocalWriteHandoffAcceptance(
        consumer,
        false,
        false,
        true,
        false,
        consumer.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueOwnerLocalWriteHandoffReceipt(
    acceptance: CjguiInternalQueueOwnerLocalWriteHandoffAcceptance
): CjguiInternalQueueOwnerLocalWriteHandoffReceipt {
    let acceptanceReady = acceptance.didAcceptQueueOwnerLocalWriteHandoff &&
        acceptance.didPreserveQueueOwnerLocalWriteHandoffConsumer &&
        acceptance.didPreservePreviousQueueStoreSnapshot &&
        acceptance.shouldDeferQueueOwnerLocalWriteHandoffAcceptance == false &&
        acceptance.shouldReportQueueOwnerLocalWriteHandoffAcceptanceBlocked == false
    let acceptanceDeferred = acceptance.didAcceptQueueOwnerLocalWriteHandoff == false &&
        acceptance.didPreserveQueueOwnerLocalWriteHandoffConsumer == false &&
        acceptance.didPreservePreviousQueueStoreSnapshot &&
        acceptance.shouldDeferQueueOwnerLocalWriteHandoffAcceptance &&
        acceptance.shouldReportQueueOwnerLocalWriteHandoffAcceptanceBlocked == false
    let acceptanceInconsistent = (
        acceptance.didAcceptQueueOwnerLocalWriteHandoff &&
            (
                acceptance.shouldDeferQueueOwnerLocalWriteHandoffAcceptance ||
                acceptance.shouldReportQueueOwnerLocalWriteHandoffAcceptanceBlocked
            )
        ) ||
        (acceptance.didPreserveQueueOwnerLocalWriteHandoffConsumer &&
            acceptance.didAcceptQueueOwnerLocalWriteHandoff == false) ||
        (acceptance.didPreserveQueueOwnerLocalWriteHandoffConsumer == false &&
            acceptance.didAcceptQueueOwnerLocalWriteHandoff) ||
        (acceptance.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            acceptance.shouldDeferQueueOwnerLocalWriteHandoffAcceptance &&
            acceptance.shouldReportQueueOwnerLocalWriteHandoffAcceptanceBlocked
        )

    // acceptance facts 不一致时必须 fail-closed，receipt 不能被误读为 observer callback。
    if (
        acceptance.shouldReportQueueOwnerLocalWriteHandoffAcceptanceBlocked ||
        acceptanceInconsistent
    ) {
        return CjguiInternalQueueOwnerLocalWriteHandoffReceipt(
            acceptance,
            false,
            false,
            true,
            false,
            acceptance.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (acceptanceReady) {
        return CjguiInternalQueueOwnerLocalWriteHandoffReceipt(acceptance, true, false, false, true, true)
    }

    if (acceptanceDeferred) {
        return CjguiInternalQueueOwnerLocalWriteHandoffReceipt(
            acceptance,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueOwnerLocalWriteHandoffReceipt(
        acceptance,
        false,
        false,
        true,
        false,
        acceptance.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueueOwnerLocalWriteHandoffDraft(): CjguiInternalQueueOwnerLocalWriteHandoffReceipt {
    // 默认 draft 只串联 downstream handoff value facts，不写真实队列，也不做 public publication。
    let result = cjguiInternalExecuteDefaultQueueOwnerLocalWriteDraft()
    let consumer = cjguiInternalBuildQueueOwnerLocalWriteHandoffConsumer(result)
    let acceptance = cjguiInternalBuildQueueOwnerLocalWriteHandoffAcceptance(consumer)
    return cjguiInternalBuildQueueOwnerLocalWriteHandoffReceipt(acceptance)
}

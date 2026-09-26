package cjgui

// Internal Queue Mutable Write Handoff owner:
// - 本文件只消费 QueueMutableWriteCommitResult。
// - Truth 是 downstream handoff consumer / acceptance / receipt 的内部 value facts。
// - Stop-line: 不写 process-wide queue storage、不创建 global mutable queue / singleton、不做 item collection mutation、
//   不公开 public API / C ABI、不 enqueue、不 drain、不接 event loop / scheduler / platform callback、不调用 runtime cycle，
//   也不回塞 critical runtime_state.cj。

// Mutable write handoff consumer 是 commit result 离开 commit owner 后的 downstream 接收边界；
// 它只记录内部接收事实，不是 public publication、observer callback、enqueue record 或真实队列写入。
struct CjguiInternalQueueMutableWriteHandoffConsumer {
    let result: CjguiInternalQueueMutableWriteCommitResult
    let didConsumeQueueMutableWriteCommitResult: Bool
    let shouldDeferQueueMutableWriteHandoffConsumer: Bool
    let shouldReportQueueMutableWriteHandoffConsumerBlocked: Bool
    let didPreserveQueueMutableWriteCommitResult: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        result: CjguiInternalQueueMutableWriteCommitResult,
        didConsumeQueueMutableWriteCommitResult: Bool,
        shouldDeferQueueMutableWriteHandoffConsumer: Bool,
        shouldReportQueueMutableWriteHandoffConsumerBlocked: Bool,
        didPreserveQueueMutableWriteCommitResult: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.result = result
        this.didConsumeQueueMutableWriteCommitResult = didConsumeQueueMutableWriteCommitResult
        this.shouldDeferQueueMutableWriteHandoffConsumer = shouldDeferQueueMutableWriteHandoffConsumer
        this.shouldReportQueueMutableWriteHandoffConsumerBlocked = shouldReportQueueMutableWriteHandoffConsumerBlocked
        this.didPreserveQueueMutableWriteCommitResult = didPreserveQueueMutableWriteCommitResult
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Mutable write handoff acceptance 只说明 downstream consumer facts 可被 handoff owner 接受；
// 它不是 process-wide storage write admission，也不是 public enqueue permission。
struct CjguiInternalQueueMutableWriteHandoffAcceptance {
    let consumer: CjguiInternalQueueMutableWriteHandoffConsumer
    let didAcceptQueueMutableWriteHandoff: Bool
    let shouldDeferQueueMutableWriteHandoffAcceptance: Bool
    let shouldReportQueueMutableWriteHandoffAcceptanceBlocked: Bool
    let didPreserveQueueMutableWriteHandoffConsumer: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        consumer: CjguiInternalQueueMutableWriteHandoffConsumer,
        didAcceptQueueMutableWriteHandoff: Bool,
        shouldDeferQueueMutableWriteHandoffAcceptance: Bool,
        shouldReportQueueMutableWriteHandoffAcceptanceBlocked: Bool,
        didPreserveQueueMutableWriteHandoffConsumer: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.consumer = consumer
        this.didAcceptQueueMutableWriteHandoff = didAcceptQueueMutableWriteHandoff
        this.shouldDeferQueueMutableWriteHandoffAcceptance = shouldDeferQueueMutableWriteHandoffAcceptance
        this.shouldReportQueueMutableWriteHandoffAcceptanceBlocked = shouldReportQueueMutableWriteHandoffAcceptanceBlocked
        this.didPreserveQueueMutableWriteHandoffConsumer = didPreserveQueueMutableWriteHandoffConsumer
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Mutable write handoff receipt 是本轮 downstream handoff canonical endpoint；
// receipt 只表示内部 handoff 已记录，不是 public publication、observer callback 或真实 queue result。
struct CjguiInternalQueueMutableWriteHandoffReceipt {
    let acceptance: CjguiInternalQueueMutableWriteHandoffAcceptance
    let didRecordQueueMutableWriteHandoffReceipt: Bool
    let shouldDeferQueueMutableWriteHandoffReceipt: Bool
    let shouldReportQueueMutableWriteHandoffReceiptBlocked: Bool
    let didPreserveQueueMutableWriteHandoffAcceptance: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        acceptance: CjguiInternalQueueMutableWriteHandoffAcceptance,
        didRecordQueueMutableWriteHandoffReceipt: Bool,
        shouldDeferQueueMutableWriteHandoffReceipt: Bool,
        shouldReportQueueMutableWriteHandoffReceiptBlocked: Bool,
        didPreserveQueueMutableWriteHandoffAcceptance: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.acceptance = acceptance
        this.didRecordQueueMutableWriteHandoffReceipt = didRecordQueueMutableWriteHandoffReceipt
        this.shouldDeferQueueMutableWriteHandoffReceipt = shouldDeferQueueMutableWriteHandoffReceipt
        this.shouldReportQueueMutableWriteHandoffReceiptBlocked = shouldReportQueueMutableWriteHandoffReceiptBlocked
        this.didPreserveQueueMutableWriteHandoffAcceptance = didPreserveQueueMutableWriteHandoffAcceptance
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueueMutableWriteHandoffConsumer(
    result: CjguiInternalQueueMutableWriteCommitResult
): CjguiInternalQueueMutableWriteHandoffConsumer {
    let resultReady = result.isQueueMutableWriteCommitResultReady &&
        result.didCommitOwnerLocalMutableWrite &&
        result.didPreserveQueueMutablePostWriteHolder &&
        result.didPreservePreviousQueueStoreSnapshot &&
        result.shouldDeferQueueMutableWriteCommitResult == false &&
        result.shouldReportQueueMutableWriteCommitResultBlocked == false
    let resultDeferred = result.isQueueMutableWriteCommitResultReady == false &&
        result.didCommitOwnerLocalMutableWrite == false &&
        result.didPreserveQueueMutablePostWriteHolder == false &&
        result.didPreservePreviousQueueStoreSnapshot &&
        result.shouldDeferQueueMutableWriteCommitResult &&
        result.shouldReportQueueMutableWriteCommitResultBlocked == false
    let resultInconsistent = (
        result.isQueueMutableWriteCommitResultReady &&
            (
                result.shouldDeferQueueMutableWriteCommitResult ||
                result.shouldReportQueueMutableWriteCommitResultBlocked
            )
        ) ||
        (result.didCommitOwnerLocalMutableWrite &&
            result.isQueueMutableWriteCommitResultReady == false) ||
        (result.didCommitOwnerLocalMutableWrite == false &&
            result.isQueueMutableWriteCommitResultReady) ||
        (result.didPreserveQueueMutablePostWriteHolder &&
            result.isQueueMutableWriteCommitResultReady == false) ||
        (result.didPreserveQueueMutablePostWriteHolder == false &&
            result.isQueueMutableWriteCommitResultReady) ||
        (result.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            result.shouldDeferQueueMutableWriteCommitResult &&
            result.shouldReportQueueMutableWriteCommitResultBlocked
        )

    // commit result facts 不一致时必须 fail-closed，避免 downstream handoff 接收伪造成功结果。
    if (
        result.shouldReportQueueMutableWriteCommitResultBlocked ||
        resultInconsistent
    ) {
        return CjguiInternalQueueMutableWriteHandoffConsumer(
            result,
            false,
            false,
            true,
            false,
            result.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (resultReady) {
        return CjguiInternalQueueMutableWriteHandoffConsumer(result, true, false, false, true, true)
    }

    if (resultDeferred) {
        return CjguiInternalQueueMutableWriteHandoffConsumer(
            result,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueMutableWriteHandoffConsumer(
        result,
        false,
        false,
        true,
        false,
        result.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueMutableWriteHandoffAcceptance(
    consumer: CjguiInternalQueueMutableWriteHandoffConsumer
): CjguiInternalQueueMutableWriteHandoffAcceptance {
    let consumerReady = consumer.didConsumeQueueMutableWriteCommitResult &&
        consumer.didPreserveQueueMutableWriteCommitResult &&
        consumer.didPreservePreviousQueueStoreSnapshot &&
        consumer.shouldDeferQueueMutableWriteHandoffConsumer == false &&
        consumer.shouldReportQueueMutableWriteHandoffConsumerBlocked == false
    let consumerDeferred = consumer.didConsumeQueueMutableWriteCommitResult == false &&
        consumer.didPreserveQueueMutableWriteCommitResult == false &&
        consumer.didPreservePreviousQueueStoreSnapshot &&
        consumer.shouldDeferQueueMutableWriteHandoffConsumer &&
        consumer.shouldReportQueueMutableWriteHandoffConsumerBlocked == false
    let consumerInconsistent = (
        consumer.didConsumeQueueMutableWriteCommitResult &&
            (
                consumer.shouldDeferQueueMutableWriteHandoffConsumer ||
                consumer.shouldReportQueueMutableWriteHandoffConsumerBlocked
            )
        ) ||
        (consumer.didPreserveQueueMutableWriteCommitResult &&
            consumer.didConsumeQueueMutableWriteCommitResult == false) ||
        (consumer.didPreserveQueueMutableWriteCommitResult == false &&
            consumer.didConsumeQueueMutableWriteCommitResult) ||
        (consumer.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            consumer.shouldDeferQueueMutableWriteHandoffConsumer &&
            consumer.shouldReportQueueMutableWriteHandoffConsumerBlocked
        )

    // consumer facts 不一致时必须 fail-closed，acceptance 不能伪造成 public publication。
    if (
        consumer.shouldReportQueueMutableWriteHandoffConsumerBlocked ||
        consumerInconsistent
    ) {
        return CjguiInternalQueueMutableWriteHandoffAcceptance(
            consumer,
            false,
            false,
            true,
            false,
            consumer.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (consumerReady) {
        return CjguiInternalQueueMutableWriteHandoffAcceptance(consumer, true, false, false, true, true)
    }

    if (consumerDeferred) {
        return CjguiInternalQueueMutableWriteHandoffAcceptance(
            consumer,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueMutableWriteHandoffAcceptance(
        consumer,
        false,
        false,
        true,
        false,
        consumer.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueMutableWriteHandoffReceipt(
    acceptance: CjguiInternalQueueMutableWriteHandoffAcceptance
): CjguiInternalQueueMutableWriteHandoffReceipt {
    let acceptanceReady = acceptance.didAcceptQueueMutableWriteHandoff &&
        acceptance.didPreserveQueueMutableWriteHandoffConsumer &&
        acceptance.didPreservePreviousQueueStoreSnapshot &&
        acceptance.shouldDeferQueueMutableWriteHandoffAcceptance == false &&
        acceptance.shouldReportQueueMutableWriteHandoffAcceptanceBlocked == false
    let acceptanceDeferred = acceptance.didAcceptQueueMutableWriteHandoff == false &&
        acceptance.didPreserveQueueMutableWriteHandoffConsumer == false &&
        acceptance.didPreservePreviousQueueStoreSnapshot &&
        acceptance.shouldDeferQueueMutableWriteHandoffAcceptance &&
        acceptance.shouldReportQueueMutableWriteHandoffAcceptanceBlocked == false
    let acceptanceInconsistent = (
        acceptance.didAcceptQueueMutableWriteHandoff &&
            (
                acceptance.shouldDeferQueueMutableWriteHandoffAcceptance ||
                acceptance.shouldReportQueueMutableWriteHandoffAcceptanceBlocked
            )
        ) ||
        (acceptance.didPreserveQueueMutableWriteHandoffConsumer &&
            acceptance.didAcceptQueueMutableWriteHandoff == false) ||
        (acceptance.didPreserveQueueMutableWriteHandoffConsumer == false &&
            acceptance.didAcceptQueueMutableWriteHandoff) ||
        (acceptance.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            acceptance.shouldDeferQueueMutableWriteHandoffAcceptance &&
            acceptance.shouldReportQueueMutableWriteHandoffAcceptanceBlocked
        )

    // acceptance facts 不一致时必须 fail-closed，receipt 不能被误读为 observer callback。
    if (
        acceptance.shouldReportQueueMutableWriteHandoffAcceptanceBlocked ||
        acceptanceInconsistent
    ) {
        return CjguiInternalQueueMutableWriteHandoffReceipt(
            acceptance,
            false,
            false,
            true,
            false,
            acceptance.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (acceptanceReady) {
        return CjguiInternalQueueMutableWriteHandoffReceipt(acceptance, true, false, false, true, true)
    }

    if (acceptanceDeferred) {
        return CjguiInternalQueueMutableWriteHandoffReceipt(
            acceptance,
            false,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueMutableWriteHandoffReceipt(
        acceptance,
        false,
        false,
        true,
        false,
        acceptance.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueueMutableWriteHandoffDraft(): CjguiInternalQueueMutableWriteHandoffReceipt {
    // 默认 draft 只串联 downstream handoff value facts，不写真实队列，也不做 public publication。
    let result = cjguiInternalExecuteDefaultQueueMutableWriteCommitDraft()
    let consumer = cjguiInternalBuildQueueMutableWriteHandoffConsumer(result)
    let acceptance = cjguiInternalBuildQueueMutableWriteHandoffAcceptance(consumer)
    return cjguiInternalBuildQueueMutableWriteHandoffReceipt(acceptance)
}

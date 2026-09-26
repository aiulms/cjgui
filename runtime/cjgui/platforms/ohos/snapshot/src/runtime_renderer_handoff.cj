package cjgui

// Internal Renderer Packet Handoff owner:
// - 本文件只消费 CjguiInternalRenderBatchingPacket。
// - Truth 是 renderer packet handoff consumer / acceptance / receipt 的内部 value facts。
// - Stop-line: 这里只把后端无关的 batching packet 交给 future adapter 前置边界；
//   不接平台渲染后端、不创建图形设备资源或命令缓冲、不触发真实渲染，
//   不做真实绘制合并、不实现增量渲染，也不回塞 critical runtime_state.cj。

// Renderer packet handoff consumer 是 batching packet 离开 material / batching hint layer 后的下游接收边界；
// 它只记录内部接收事实，不是渲染后端适配器、真实绘制提交或平台资源入口。
struct CjguiInternalRendererPacketHandoffConsumer {
    let batchingPacket: CjguiInternalRenderBatchingPacket
    let didConsumeRenderBatchingPacket: Bool
    let shouldDeferRendererPacketHandoffConsumer: Bool
    let shouldReportRendererPacketHandoffConsumerBlocked: Bool
    let didPreserveRenderBatchingPacket: Bool
    let didKeepRendererPacketHandoffAgnostic: Bool
    let didAvoidRendererAdapterExecution: Bool
    let didAvoidRenderSideEffect: Bool

    init(
        batchingPacket: CjguiInternalRenderBatchingPacket,
        didConsumeRenderBatchingPacket: Bool,
        shouldDeferRendererPacketHandoffConsumer: Bool,
        shouldReportRendererPacketHandoffConsumerBlocked: Bool,
        didPreserveRenderBatchingPacket: Bool,
        didKeepRendererPacketHandoffAgnostic: Bool,
        didAvoidRendererAdapterExecution: Bool,
        didAvoidRenderSideEffect: Bool
    ) {
        this.batchingPacket = batchingPacket
        this.didConsumeRenderBatchingPacket = didConsumeRenderBatchingPacket
        this.shouldDeferRendererPacketHandoffConsumer = shouldDeferRendererPacketHandoffConsumer
        this.shouldReportRendererPacketHandoffConsumerBlocked = shouldReportRendererPacketHandoffConsumerBlocked
        this.didPreserveRenderBatchingPacket = didPreserveRenderBatchingPacket
        this.didKeepRendererPacketHandoffAgnostic = didKeepRendererPacketHandoffAgnostic
        this.didAvoidRendererAdapterExecution = didAvoidRendererAdapterExecution
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
    }
}

// Renderer packet handoff acceptance 只说明下游 consumer facts 可被 handoff owner 接受；
// 它不是后端适配器 admission，也不是绘制许可或真实渲染队列入口。
struct CjguiInternalRendererPacketHandoffAcceptance {
    let consumer: CjguiInternalRendererPacketHandoffConsumer
    let didAcceptRendererPacketHandoff: Bool
    let shouldDeferRendererPacketHandoffAcceptance: Bool
    let shouldReportRendererPacketHandoffAcceptanceBlocked: Bool
    let didPreserveRendererPacketHandoffConsumer: Bool
    let didKeepRendererPacketHandoffAgnostic: Bool
    let didAvoidRendererAdapterExecution: Bool
    let didAvoidRenderSideEffect: Bool

    init(
        consumer: CjguiInternalRendererPacketHandoffConsumer,
        didAcceptRendererPacketHandoff: Bool,
        shouldDeferRendererPacketHandoffAcceptance: Bool,
        shouldReportRendererPacketHandoffAcceptanceBlocked: Bool,
        didPreserveRendererPacketHandoffConsumer: Bool,
        didKeepRendererPacketHandoffAgnostic: Bool,
        didAvoidRendererAdapterExecution: Bool,
        didAvoidRenderSideEffect: Bool
    ) {
        this.consumer = consumer
        this.didAcceptRendererPacketHandoff = didAcceptRendererPacketHandoff
        this.shouldDeferRendererPacketHandoffAcceptance = shouldDeferRendererPacketHandoffAcceptance
        this.shouldReportRendererPacketHandoffAcceptanceBlocked = shouldReportRendererPacketHandoffAcceptanceBlocked
        this.didPreserveRendererPacketHandoffConsumer = didPreserveRendererPacketHandoffConsumer
        this.didKeepRendererPacketHandoffAgnostic = didKeepRendererPacketHandoffAgnostic
        this.didAvoidRendererAdapterExecution = didAvoidRendererAdapterExecution
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
    }
}

// Renderer packet handoff receipt 是本轮 canonical endpoint；
// receipt 只表示 future adapter 可以继续评估 value packet，不是真实渲染执行或平台提交。
struct CjguiInternalRendererPacketHandoffReceipt {
    let acceptance: CjguiInternalRendererPacketHandoffAcceptance
    let didRecordRendererPacketHandoffReceipt: Bool
    let canFutureRendererAdapterEvaluatePacket: Bool
    let shouldDeferRendererPacketHandoffReceipt: Bool
    let shouldReportRendererPacketHandoffReceiptBlocked: Bool
    let didPreserveRendererPacketHandoffAcceptance: Bool
    let didKeepRendererPacketHandoffAgnostic: Bool
    let didAvoidRendererAdapterExecution: Bool
    let didAvoidRenderSideEffect: Bool

    init(
        acceptance: CjguiInternalRendererPacketHandoffAcceptance,
        didRecordRendererPacketHandoffReceipt: Bool,
        canFutureRendererAdapterEvaluatePacket: Bool,
        shouldDeferRendererPacketHandoffReceipt: Bool,
        shouldReportRendererPacketHandoffReceiptBlocked: Bool,
        didPreserveRendererPacketHandoffAcceptance: Bool,
        didKeepRendererPacketHandoffAgnostic: Bool,
        didAvoidRendererAdapterExecution: Bool,
        didAvoidRenderSideEffect: Bool
    ) {
        this.acceptance = acceptance
        this.didRecordRendererPacketHandoffReceipt = didRecordRendererPacketHandoffReceipt
        this.canFutureRendererAdapterEvaluatePacket = canFutureRendererAdapterEvaluatePacket
        this.shouldDeferRendererPacketHandoffReceipt = shouldDeferRendererPacketHandoffReceipt
        this.shouldReportRendererPacketHandoffReceiptBlocked = shouldReportRendererPacketHandoffReceiptBlocked
        this.didPreserveRendererPacketHandoffAcceptance = didPreserveRendererPacketHandoffAcceptance
        this.didKeepRendererPacketHandoffAgnostic = didKeepRendererPacketHandoffAgnostic
        this.didAvoidRendererAdapterExecution = didAvoidRendererAdapterExecution
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
    }
}

func cjguiInternalBuildRendererPacketHandoffConsumer(
    batchingPacket: CjguiInternalRenderBatchingPacket
): CjguiInternalRendererPacketHandoffConsumer {
    let packetReady = batchingPacket.isRenderBatchingPacketReady &&
        batchingPacket.didKeepBatchingPacketRendererAgnostic &&
        batchingPacket.didAvoidRenderSideEffect &&
        batchingPacket.didAvoidCommandMerge &&
        batchingPacket.didPreserveRenderBatchingPlan &&
        batchingPacket.batchingPlan.didUseFullRebuildBatchingPlan &&
        batchingPacket.batchingPlan.didAvoidCommandMerge &&
        batchingPacket.batchingPlan.didAvoidIncrementalBatchUpdate &&
        batchingPacket.shouldDeferRenderBatchingPacket == false &&
        batchingPacket.shouldReportRenderBatchingPacketBlocked == false
    let packetDeferred = batchingPacket.isRenderBatchingPacketReady == false &&
        batchingPacket.didKeepBatchingPacketRendererAgnostic &&
        batchingPacket.didAvoidRenderSideEffect &&
        batchingPacket.didAvoidCommandMerge &&
        batchingPacket.didPreserveRenderBatchingPlan == false &&
        batchingPacket.shouldDeferRenderBatchingPacket &&
        batchingPacket.shouldReportRenderBatchingPacketBlocked == false
    let packetInconsistent = (
        batchingPacket.isRenderBatchingPacketReady &&
            (
                batchingPacket.didKeepBatchingPacketRendererAgnostic == false ||
                batchingPacket.didAvoidRenderSideEffect == false ||
                batchingPacket.didAvoidCommandMerge == false ||
                batchingPacket.didPreserveRenderBatchingPlan == false ||
                batchingPacket.batchingPlan.didUseFullRebuildBatchingPlan == false ||
                batchingPacket.batchingPlan.didAvoidCommandMerge == false ||
                batchingPacket.batchingPlan.didAvoidIncrementalBatchUpdate == false ||
                batchingPacket.shouldDeferRenderBatchingPacket ||
                batchingPacket.shouldReportRenderBatchingPacketBlocked
            )
        ) ||
        (batchingPacket.didPreserveRenderBatchingPlan &&
            batchingPacket.isRenderBatchingPacketReady == false) ||
        (batchingPacket.shouldDeferRenderBatchingPacket &&
            batchingPacket.shouldReportRenderBatchingPacketBlocked)

    // batching packet facts 不一致时必须 fail-closed，避免 future adapter 接收伪造 handoff 成功。
    if (batchingPacket.shouldReportRenderBatchingPacketBlocked || packetInconsistent) {
        return CjguiInternalRendererPacketHandoffConsumer(
            batchingPacket,
            false,
            false,
            true,
            false,
            true,
            true,
            true
        )
    }

    if (packetReady) {
        return CjguiInternalRendererPacketHandoffConsumer(
            batchingPacket,
            true,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (packetDeferred) {
        return CjguiInternalRendererPacketHandoffConsumer(
            batchingPacket,
            false,
            true,
            false,
            false,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererPacketHandoffConsumer(
        batchingPacket,
        false,
        false,
        true,
        false,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPacketHandoffAcceptance(
    consumer: CjguiInternalRendererPacketHandoffConsumer
): CjguiInternalRendererPacketHandoffAcceptance {
    let consumerReady = consumer.didConsumeRenderBatchingPacket &&
        consumer.didPreserveRenderBatchingPacket &&
        consumer.didKeepRendererPacketHandoffAgnostic &&
        consumer.didAvoidRendererAdapterExecution &&
        consumer.didAvoidRenderSideEffect &&
        consumer.shouldDeferRendererPacketHandoffConsumer == false &&
        consumer.shouldReportRendererPacketHandoffConsumerBlocked == false
    let consumerDeferred = consumer.didConsumeRenderBatchingPacket == false &&
        consumer.didPreserveRenderBatchingPacket == false &&
        consumer.didKeepRendererPacketHandoffAgnostic &&
        consumer.didAvoidRendererAdapterExecution &&
        consumer.didAvoidRenderSideEffect &&
        consumer.shouldDeferRendererPacketHandoffConsumer &&
        consumer.shouldReportRendererPacketHandoffConsumerBlocked == false
    let consumerInconsistent = (
        consumer.didConsumeRenderBatchingPacket &&
            (
                consumer.didPreserveRenderBatchingPacket == false ||
                consumer.didKeepRendererPacketHandoffAgnostic == false ||
                consumer.didAvoidRendererAdapterExecution == false ||
                consumer.didAvoidRenderSideEffect == false ||
                consumer.shouldDeferRendererPacketHandoffConsumer ||
                consumer.shouldReportRendererPacketHandoffConsumerBlocked
            )
        ) ||
        (consumer.didPreserveRenderBatchingPacket &&
            consumer.didConsumeRenderBatchingPacket == false) ||
        (consumer.shouldDeferRendererPacketHandoffConsumer &&
            consumer.shouldReportRendererPacketHandoffConsumerBlocked)

    // consumer facts 不一致时必须 fail-closed，acceptance 不能升级成真实 adapter admission。
    if (
        consumer.shouldReportRendererPacketHandoffConsumerBlocked ||
        consumerInconsistent
    ) {
        return CjguiInternalRendererPacketHandoffAcceptance(
            consumer,
            false,
            false,
            true,
            false,
            true,
            true,
            true
        )
    }

    if (consumerReady) {
        return CjguiInternalRendererPacketHandoffAcceptance(
            consumer,
            true,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (consumerDeferred) {
        return CjguiInternalRendererPacketHandoffAcceptance(
            consumer,
            false,
            true,
            false,
            false,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererPacketHandoffAcceptance(
        consumer,
        false,
        false,
        true,
        false,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPacketHandoffReceipt(
    acceptance: CjguiInternalRendererPacketHandoffAcceptance
): CjguiInternalRendererPacketHandoffReceipt {
    let acceptanceReady = acceptance.didAcceptRendererPacketHandoff &&
        acceptance.didPreserveRendererPacketHandoffConsumer &&
        acceptance.didKeepRendererPacketHandoffAgnostic &&
        acceptance.didAvoidRendererAdapterExecution &&
        acceptance.didAvoidRenderSideEffect &&
        acceptance.shouldDeferRendererPacketHandoffAcceptance == false &&
        acceptance.shouldReportRendererPacketHandoffAcceptanceBlocked == false
    let acceptanceDeferred = acceptance.didAcceptRendererPacketHandoff == false &&
        acceptance.didPreserveRendererPacketHandoffConsumer == false &&
        acceptance.didKeepRendererPacketHandoffAgnostic &&
        acceptance.didAvoidRendererAdapterExecution &&
        acceptance.didAvoidRenderSideEffect &&
        acceptance.shouldDeferRendererPacketHandoffAcceptance &&
        acceptance.shouldReportRendererPacketHandoffAcceptanceBlocked == false
    let acceptanceInconsistent = (
        acceptance.didAcceptRendererPacketHandoff &&
            (
                acceptance.didPreserveRendererPacketHandoffConsumer == false ||
                acceptance.didKeepRendererPacketHandoffAgnostic == false ||
                acceptance.didAvoidRendererAdapterExecution == false ||
                acceptance.didAvoidRenderSideEffect == false ||
                acceptance.shouldDeferRendererPacketHandoffAcceptance ||
                acceptance.shouldReportRendererPacketHandoffAcceptanceBlocked
            )
        ) ||
        (acceptance.didPreserveRendererPacketHandoffConsumer &&
            acceptance.didAcceptRendererPacketHandoff == false) ||
        (acceptance.shouldDeferRendererPacketHandoffAcceptance &&
            acceptance.shouldReportRendererPacketHandoffAcceptanceBlocked)

    // acceptance facts 不一致时必须 fail-closed，receipt 不能被误读成真实渲染或平台提交。
    if (
        acceptance.shouldReportRendererPacketHandoffAcceptanceBlocked ||
        acceptanceInconsistent
    ) {
        return CjguiInternalRendererPacketHandoffReceipt(
            acceptance,
            false,
            false,
            false,
            true,
            false,
            true,
            true,
            true
        )
    }

    if (acceptanceReady) {
        return CjguiInternalRendererPacketHandoffReceipt(
            acceptance,
            true,
            true,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (acceptanceDeferred) {
        return CjguiInternalRendererPacketHandoffReceipt(
            acceptance,
            false,
            false,
            true,
            false,
            false,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererPacketHandoffReceipt(
        acceptance,
        false,
        false,
        false,
        true,
        false,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPacketHandoffDraft(): CjguiInternalRendererPacketHandoffReceipt {
    // 默认 draft 只串联 renderer packet handoff value facts；
    // 它不接平台渲染后端、不执行 adapter、不触发真实渲染或绘制合并。
    let batchingPacket = cjguiInternalExecuteDefaultRenderBatchingHintDraft()
    let consumer = cjguiInternalBuildRendererPacketHandoffConsumer(batchingPacket)
    let acceptance = cjguiInternalBuildRendererPacketHandoffAcceptance(consumer)
    return cjguiInternalBuildRendererPacketHandoffReceipt(acceptance)
}

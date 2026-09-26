package cjgui

// Internal Renderer Backend Adapter value owner:
// - 本文件只消费 CjguiInternalRendererPacketHandoffReceipt。
// - Truth 是后端适配器候选、能力占位、admission、no-render readiness 的内部 value facts。
// - Stop-line: 这里只有 future adapter 前置契约；不接平台渲染实现、
//   不创建图形设备资源、不触发真实绘制、不写 renderer state，
//   不做真实合批或增量渲染，也不回塞 critical runtime_state.cj。

// Backend adapter candidate 只说明 handoff receipt 可进入适配器前置评估；
// 它不是平台资源、真实适配器对象、绘制许可或 renderer state 写入。
struct CjguiInternalRendererBackendAdapterCandidate {
    let handoffReceipt: CjguiInternalRendererPacketHandoffReceipt
    let didPrepareRendererBackendAdapterCandidate: Bool
    let shouldDeferRendererBackendAdapterCandidate: Bool
    let shouldReportRendererBackendAdapterCandidateBlocked: Bool
    let didPreserveRendererPacketHandoffReceipt: Bool
    let didKeepRendererBackendAdapterValueOnly: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool

    init(
        handoffReceipt: CjguiInternalRendererPacketHandoffReceipt,
        didPrepareRendererBackendAdapterCandidate: Bool,
        shouldDeferRendererBackendAdapterCandidate: Bool,
        shouldReportRendererBackendAdapterCandidateBlocked: Bool,
        didPreserveRendererPacketHandoffReceipt: Bool,
        didKeepRendererBackendAdapterValueOnly: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool
    ) {
        this.handoffReceipt = handoffReceipt
        this.didPrepareRendererBackendAdapterCandidate = didPrepareRendererBackendAdapterCandidate
        this.shouldDeferRendererBackendAdapterCandidate = shouldDeferRendererBackendAdapterCandidate
        this.shouldReportRendererBackendAdapterCandidateBlocked = shouldReportRendererBackendAdapterCandidateBlocked
        this.didPreserveRendererPacketHandoffReceipt = didPreserveRendererPacketHandoffReceipt
        this.didKeepRendererBackendAdapterValueOnly = didKeepRendererBackendAdapterValueOnly
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
    }
}

// Backend capability placeholder 只记录能力占位 facts；
// 它不绑定平台能力、不创建图形资源，也不代表可以绘制。
struct CjguiInternalRendererBackendCapabilityPlaceholder {
    let candidate: CjguiInternalRendererBackendAdapterCandidate
    let didPrepareRendererBackendCapabilityPlaceholder: Bool
    let shouldDeferRendererBackendCapabilityPlaceholder: Bool
    let shouldReportRendererBackendCapabilityPlaceholderBlocked: Bool
    let didPreserveRendererBackendAdapterCandidate: Bool
    let didKeepRendererBackendCapabilityPlaceholderAgnostic: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool

    init(
        candidate: CjguiInternalRendererBackendAdapterCandidate,
        didPrepareRendererBackendCapabilityPlaceholder: Bool,
        shouldDeferRendererBackendCapabilityPlaceholder: Bool,
        shouldReportRendererBackendCapabilityPlaceholderBlocked: Bool,
        didPreserveRendererBackendAdapterCandidate: Bool,
        didKeepRendererBackendCapabilityPlaceholderAgnostic: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool
    ) {
        this.candidate = candidate
        this.didPrepareRendererBackendCapabilityPlaceholder = didPrepareRendererBackendCapabilityPlaceholder
        this.shouldDeferRendererBackendCapabilityPlaceholder = shouldDeferRendererBackendCapabilityPlaceholder
        this.shouldReportRendererBackendCapabilityPlaceholderBlocked = shouldReportRendererBackendCapabilityPlaceholderBlocked
        this.didPreserveRendererBackendAdapterCandidate = didPreserveRendererBackendAdapterCandidate
        this.didKeepRendererBackendCapabilityPlaceholderAgnostic = didKeepRendererBackendCapabilityPlaceholderAgnostic
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
    }
}

// Backend adapter admission 只是 candidate + capability placeholder 的内部准入 facts；
// 它不是 adapter 执行、平台提交、绘制队列或 renderer state mutation。
struct CjguiInternalRendererBackendAdapterAdmission {
    let capabilityPlaceholder: CjguiInternalRendererBackendCapabilityPlaceholder
    let didAdmitRendererBackendAdapterCandidate: Bool
    let shouldDeferRendererBackendAdapterAdmission: Bool
    let shouldReportRendererBackendAdapterAdmissionBlocked: Bool
    let didPreserveRendererBackendCapabilityPlaceholder: Bool
    let didKeepRendererBackendAdapterAdmissionValueOnly: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool

    init(
        capabilityPlaceholder: CjguiInternalRendererBackendCapabilityPlaceholder,
        didAdmitRendererBackendAdapterCandidate: Bool,
        shouldDeferRendererBackendAdapterAdmission: Bool,
        shouldReportRendererBackendAdapterAdmissionBlocked: Bool,
        didPreserveRendererBackendCapabilityPlaceholder: Bool,
        didKeepRendererBackendAdapterAdmissionValueOnly: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool
    ) {
        this.capabilityPlaceholder = capabilityPlaceholder
        this.didAdmitRendererBackendAdapterCandidate = didAdmitRendererBackendAdapterCandidate
        this.shouldDeferRendererBackendAdapterAdmission = shouldDeferRendererBackendAdapterAdmission
        this.shouldReportRendererBackendAdapterAdmissionBlocked = shouldReportRendererBackendAdapterAdmissionBlocked
        this.didPreserveRendererBackendCapabilityPlaceholder = didPreserveRendererBackendCapabilityPlaceholder
        this.didKeepRendererBackendAdapterAdmissionValueOnly = didKeepRendererBackendAdapterAdmissionValueOnly
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
    }
}

// No-render readiness 是本轮 canonical endpoint；
// readiness 只表示 future adapter boundary 可以继续评估，不代表允许真实绘制。
struct CjguiInternalRendererBackendNoRenderReadiness {
    let admission: CjguiInternalRendererBackendAdapterAdmission
    let isRendererBackendNoRenderReady: Bool
    let canFutureRendererBackendBoundaryEvaluate: Bool
    let shouldDeferRendererBackendNoRenderReadiness: Bool
    let shouldReportRendererBackendNoRenderReadinessBlocked: Bool
    let didRecordRendererBackendNoRenderReadiness: Bool
    let didPreserveRendererBackendAdapterAdmission: Bool
    let didKeepRendererBackendReadinessValueOnly: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        admission: CjguiInternalRendererBackendAdapterAdmission,
        isRendererBackendNoRenderReady: Bool,
        canFutureRendererBackendBoundaryEvaluate: Bool,
        shouldDeferRendererBackendNoRenderReadiness: Bool,
        shouldReportRendererBackendNoRenderReadinessBlocked: Bool,
        didRecordRendererBackendNoRenderReadiness: Bool,
        didPreserveRendererBackendAdapterAdmission: Bool,
        didKeepRendererBackendReadinessValueOnly: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.admission = admission
        this.isRendererBackendNoRenderReady = isRendererBackendNoRenderReady
        this.canFutureRendererBackendBoundaryEvaluate = canFutureRendererBackendBoundaryEvaluate
        this.shouldDeferRendererBackendNoRenderReadiness = shouldDeferRendererBackendNoRenderReadiness
        this.shouldReportRendererBackendNoRenderReadinessBlocked = shouldReportRendererBackendNoRenderReadinessBlocked
        this.didRecordRendererBackendNoRenderReadiness = didRecordRendererBackendNoRenderReadiness
        this.didPreserveRendererBackendAdapterAdmission = didPreserveRendererBackendAdapterAdmission
        this.didKeepRendererBackendReadinessValueOnly = didKeepRendererBackendReadinessValueOnly
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererBackendAdapterCandidate(
    handoffReceipt: CjguiInternalRendererPacketHandoffReceipt
): CjguiInternalRendererBackendAdapterCandidate {
    let receiptReady = handoffReceipt.didRecordRendererPacketHandoffReceipt &&
        handoffReceipt.canFutureRendererAdapterEvaluatePacket &&
        handoffReceipt.didPreserveRendererPacketHandoffAcceptance &&
        handoffReceipt.didKeepRendererPacketHandoffAgnostic &&
        handoffReceipt.didAvoidRendererAdapterExecution &&
        handoffReceipt.didAvoidRenderSideEffect &&
        handoffReceipt.shouldDeferRendererPacketHandoffReceipt == false &&
        handoffReceipt.shouldReportRendererPacketHandoffReceiptBlocked == false
    let receiptDeferred = handoffReceipt.didRecordRendererPacketHandoffReceipt == false &&
        handoffReceipt.canFutureRendererAdapterEvaluatePacket == false &&
        handoffReceipt.didPreserveRendererPacketHandoffAcceptance == false &&
        handoffReceipt.didKeepRendererPacketHandoffAgnostic &&
        handoffReceipt.didAvoidRendererAdapterExecution &&
        handoffReceipt.didAvoidRenderSideEffect &&
        handoffReceipt.shouldDeferRendererPacketHandoffReceipt &&
        handoffReceipt.shouldReportRendererPacketHandoffReceiptBlocked == false
    let receiptInconsistent = (
        handoffReceipt.didRecordRendererPacketHandoffReceipt &&
            (
                handoffReceipt.canFutureRendererAdapterEvaluatePacket == false ||
                handoffReceipt.didPreserveRendererPacketHandoffAcceptance == false ||
                handoffReceipt.didKeepRendererPacketHandoffAgnostic == false ||
                handoffReceipt.didAvoidRendererAdapterExecution == false ||
                handoffReceipt.didAvoidRenderSideEffect == false ||
                handoffReceipt.shouldDeferRendererPacketHandoffReceipt ||
                handoffReceipt.shouldReportRendererPacketHandoffReceiptBlocked
            )
        ) ||
        (handoffReceipt.canFutureRendererAdapterEvaluatePacket &&
            handoffReceipt.didRecordRendererPacketHandoffReceipt == false) ||
        (handoffReceipt.didPreserveRendererPacketHandoffAcceptance &&
            handoffReceipt.didRecordRendererPacketHandoffReceipt == false) ||
        (handoffReceipt.shouldDeferRendererPacketHandoffReceipt &&
            handoffReceipt.shouldReportRendererPacketHandoffReceiptBlocked)

    // receipt facts 不一致时必须 fail-closed，避免把 handoff 升级成真实 adapter readiness。
    if (
        handoffReceipt.shouldReportRendererPacketHandoffReceiptBlocked ||
        receiptInconsistent
    ) {
        return CjguiInternalRendererBackendAdapterCandidate(
            handoffReceipt,
            false,
            false,
            true,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (receiptReady) {
        return CjguiInternalRendererBackendAdapterCandidate(
            handoffReceipt,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (receiptDeferred) {
        return CjguiInternalRendererBackendAdapterCandidate(
            handoffReceipt,
            false,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererBackendAdapterCandidate(
        handoffReceipt,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererBackendCapabilityPlaceholder(
    candidate: CjguiInternalRendererBackendAdapterCandidate
): CjguiInternalRendererBackendCapabilityPlaceholder {
    let candidateReady = candidate.didPrepareRendererBackendAdapterCandidate &&
        candidate.didPreserveRendererPacketHandoffReceipt &&
        candidate.didKeepRendererBackendAdapterValueOnly &&
        candidate.didAvoidRendererBackendImplementation &&
        candidate.didAvoidPlatformResourceBinding &&
        candidate.didAvoidRendererStateWrite &&
        candidate.didAvoidDrawingSideEffect &&
        candidate.shouldDeferRendererBackendAdapterCandidate == false &&
        candidate.shouldReportRendererBackendAdapterCandidateBlocked == false
    let candidateDeferred = candidate.didPrepareRendererBackendAdapterCandidate == false &&
        candidate.didPreserveRendererPacketHandoffReceipt == false &&
        candidate.didKeepRendererBackendAdapterValueOnly &&
        candidate.didAvoidRendererBackendImplementation &&
        candidate.didAvoidPlatformResourceBinding &&
        candidate.didAvoidRendererStateWrite &&
        candidate.didAvoidDrawingSideEffect &&
        candidate.shouldDeferRendererBackendAdapterCandidate &&
        candidate.shouldReportRendererBackendAdapterCandidateBlocked == false
    let candidateInconsistent = (
        candidate.didPrepareRendererBackendAdapterCandidate &&
            (
                candidate.didPreserveRendererPacketHandoffReceipt == false ||
                candidate.didKeepRendererBackendAdapterValueOnly == false ||
                candidate.didAvoidRendererBackendImplementation == false ||
                candidate.didAvoidPlatformResourceBinding == false ||
                candidate.didAvoidRendererStateWrite == false ||
                candidate.didAvoidDrawingSideEffect == false ||
                candidate.shouldDeferRendererBackendAdapterCandidate ||
                candidate.shouldReportRendererBackendAdapterCandidateBlocked
            )
        ) ||
        (candidate.didPreserveRendererPacketHandoffReceipt &&
            candidate.didPrepareRendererBackendAdapterCandidate == false) ||
        (candidate.shouldDeferRendererBackendAdapterCandidate &&
            candidate.shouldReportRendererBackendAdapterCandidateBlocked)

    // candidate facts 不一致时必须 fail-closed，capability 只能保持占位 value。
    if (
        candidate.shouldReportRendererBackendAdapterCandidateBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalRendererBackendCapabilityPlaceholder(
            candidate,
            false,
            false,
            true,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (candidateReady) {
        return CjguiInternalRendererBackendCapabilityPlaceholder(
            candidate,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (candidateDeferred) {
        return CjguiInternalRendererBackendCapabilityPlaceholder(
            candidate,
            false,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererBackendCapabilityPlaceholder(
        candidate,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererBackendAdapterAdmission(
    capabilityPlaceholder: CjguiInternalRendererBackendCapabilityPlaceholder
): CjguiInternalRendererBackendAdapterAdmission {
    let placeholderReady = capabilityPlaceholder.didPrepareRendererBackendCapabilityPlaceholder &&
        capabilityPlaceholder.didPreserveRendererBackendAdapterCandidate &&
        capabilityPlaceholder.didKeepRendererBackendCapabilityPlaceholderAgnostic &&
        capabilityPlaceholder.didAvoidRendererBackendImplementation &&
        capabilityPlaceholder.didAvoidPlatformResourceBinding &&
        capabilityPlaceholder.didAvoidRendererStateWrite &&
        capabilityPlaceholder.didAvoidDrawingSideEffect &&
        capabilityPlaceholder.shouldDeferRendererBackendCapabilityPlaceholder == false &&
        capabilityPlaceholder.shouldReportRendererBackendCapabilityPlaceholderBlocked == false
    let placeholderDeferred = capabilityPlaceholder.didPrepareRendererBackendCapabilityPlaceholder == false &&
        capabilityPlaceholder.didPreserveRendererBackendAdapterCandidate == false &&
        capabilityPlaceholder.didKeepRendererBackendCapabilityPlaceholderAgnostic &&
        capabilityPlaceholder.didAvoidRendererBackendImplementation &&
        capabilityPlaceholder.didAvoidPlatformResourceBinding &&
        capabilityPlaceholder.didAvoidRendererStateWrite &&
        capabilityPlaceholder.didAvoidDrawingSideEffect &&
        capabilityPlaceholder.shouldDeferRendererBackendCapabilityPlaceholder &&
        capabilityPlaceholder.shouldReportRendererBackendCapabilityPlaceholderBlocked == false
    let placeholderInconsistent = (
        capabilityPlaceholder.didPrepareRendererBackendCapabilityPlaceholder &&
            (
                capabilityPlaceholder.didPreserveRendererBackendAdapterCandidate == false ||
                capabilityPlaceholder.didKeepRendererBackendCapabilityPlaceholderAgnostic == false ||
                capabilityPlaceholder.didAvoidRendererBackendImplementation == false ||
                capabilityPlaceholder.didAvoidPlatformResourceBinding == false ||
                capabilityPlaceholder.didAvoidRendererStateWrite == false ||
                capabilityPlaceholder.didAvoidDrawingSideEffect == false ||
                capabilityPlaceholder.shouldDeferRendererBackendCapabilityPlaceholder ||
                capabilityPlaceholder.shouldReportRendererBackendCapabilityPlaceholderBlocked
            )
        ) ||
        (capabilityPlaceholder.didPreserveRendererBackendAdapterCandidate &&
            capabilityPlaceholder.didPrepareRendererBackendCapabilityPlaceholder == false) ||
        (capabilityPlaceholder.shouldDeferRendererBackendCapabilityPlaceholder &&
            capabilityPlaceholder.shouldReportRendererBackendCapabilityPlaceholderBlocked)

    // capability placeholder facts 不一致时必须 fail-closed，admission 不能伪造成可执行 adapter。
    if (
        capabilityPlaceholder.shouldReportRendererBackendCapabilityPlaceholderBlocked ||
        placeholderInconsistent
    ) {
        return CjguiInternalRendererBackendAdapterAdmission(
            capabilityPlaceholder,
            false,
            false,
            true,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (placeholderReady) {
        return CjguiInternalRendererBackendAdapterAdmission(
            capabilityPlaceholder,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (placeholderDeferred) {
        return CjguiInternalRendererBackendAdapterAdmission(
            capabilityPlaceholder,
            false,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererBackendAdapterAdmission(
        capabilityPlaceholder,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererBackendNoRenderReadiness(
    admission: CjguiInternalRendererBackendAdapterAdmission
): CjguiInternalRendererBackendNoRenderReadiness {
    let admissionReady = admission.didAdmitRendererBackendAdapterCandidate &&
        admission.didPreserveRendererBackendCapabilityPlaceholder &&
        admission.didKeepRendererBackendAdapterAdmissionValueOnly &&
        admission.didAvoidRendererBackendImplementation &&
        admission.didAvoidPlatformResourceBinding &&
        admission.didAvoidRendererStateWrite &&
        admission.didAvoidDrawingSideEffect &&
        admission.shouldDeferRendererBackendAdapterAdmission == false &&
        admission.shouldReportRendererBackendAdapterAdmissionBlocked == false
    let admissionDeferred = admission.didAdmitRendererBackendAdapterCandidate == false &&
        admission.didPreserveRendererBackendCapabilityPlaceholder == false &&
        admission.didKeepRendererBackendAdapterAdmissionValueOnly &&
        admission.didAvoidRendererBackendImplementation &&
        admission.didAvoidPlatformResourceBinding &&
        admission.didAvoidRendererStateWrite &&
        admission.didAvoidDrawingSideEffect &&
        admission.shouldDeferRendererBackendAdapterAdmission &&
        admission.shouldReportRendererBackendAdapterAdmissionBlocked == false
    let admissionInconsistent = (
        admission.didAdmitRendererBackendAdapterCandidate &&
            (
                admission.didPreserveRendererBackendCapabilityPlaceholder == false ||
                admission.didKeepRendererBackendAdapterAdmissionValueOnly == false ||
                admission.didAvoidRendererBackendImplementation == false ||
                admission.didAvoidPlatformResourceBinding == false ||
                admission.didAvoidRendererStateWrite == false ||
                admission.didAvoidDrawingSideEffect == false ||
                admission.shouldDeferRendererBackendAdapterAdmission ||
                admission.shouldReportRendererBackendAdapterAdmissionBlocked
            )
        ) ||
        (admission.didPreserveRendererBackendCapabilityPlaceholder &&
            admission.didAdmitRendererBackendAdapterCandidate == false) ||
        (admission.shouldDeferRendererBackendAdapterAdmission &&
            admission.shouldReportRendererBackendAdapterAdmissionBlocked)

    // admission facts 不一致时必须 fail-closed，no-render readiness 不能变成真实绘制许可。
    if (
        admission.shouldReportRendererBackendAdapterAdmissionBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalRendererBackendNoRenderReadiness(
            admission,
            false,
            false,
            false,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (admissionReady) {
        return CjguiInternalRendererBackendNoRenderReadiness(
            admission,
            true,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (admissionDeferred) {
        return CjguiInternalRendererBackendNoRenderReadiness(
            admission,
            false,
            false,
            true,
            false,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererBackendNoRenderReadiness(
        admission,
        false,
        false,
        false,
        true,
        false,
        false,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererBackendAdapterDraft(): CjguiInternalRendererBackendNoRenderReadiness {
    // 默认 draft 只串联 backend-adapter 前置 value facts；
    // 它不执行平台适配器、不触发真实绘制，也不写 renderer state。
    let handoffReceipt = cjguiInternalExecuteDefaultRendererPacketHandoffDraft()
    let candidate = cjguiInternalBuildRendererBackendAdapterCandidate(handoffReceipt)
    let capabilityPlaceholder = cjguiInternalBuildRendererBackendCapabilityPlaceholder(candidate)
    let admission = cjguiInternalBuildRendererBackendAdapterAdmission(capabilityPlaceholder)
    return cjguiInternalBuildRendererBackendNoRenderReadiness(admission)
}

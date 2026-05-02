package cjgui

// Internal Renderer Backend Contract value owner:
// - 本文件只消费 CjguiInternalRendererBackendNoRenderReadiness。
// - Truth 是后端契约、能力集合占位、契约准入、no-render contract readiness 的内部 value facts。
// - Stop-line: 这里只有 future contract 前置契约；不接平台渲染实现、
//   不创建图形执行资源、不触发真实绘制、不写 renderer state，
//   不做真实合批或增量渲染，也不回塞 critical runtime_state.cj。

// Backend contract 只说明 no-render readiness 可以进入契约层评估；
// 它不是平台资源、真实后端对象、绘制许可或 renderer state 写入。
struct CjguiInternalRendererBackendContract {
    let noRenderReadiness: CjguiInternalRendererBackendNoRenderReadiness
    let didPrepareRendererBackendContract: Bool
    let shouldDeferRendererBackendContract: Bool
    let shouldReportRendererBackendContractBlocked: Bool
    let didPreserveRendererBackendNoRenderReadiness: Bool
    let didKeepRendererBackendContractValueOnly: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        noRenderReadiness: CjguiInternalRendererBackendNoRenderReadiness,
        didPrepareRendererBackendContract: Bool,
        shouldDeferRendererBackendContract: Bool,
        shouldReportRendererBackendContractBlocked: Bool,
        didPreserveRendererBackendNoRenderReadiness: Bool,
        didKeepRendererBackendContractValueOnly: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.noRenderReadiness = noRenderReadiness
        this.didPrepareRendererBackendContract = didPrepareRendererBackendContract
        this.shouldDeferRendererBackendContract = shouldDeferRendererBackendContract
        this.shouldReportRendererBackendContractBlocked = shouldReportRendererBackendContractBlocked
        this.didPreserveRendererBackendNoRenderReadiness = didPreserveRendererBackendNoRenderReadiness
        this.didKeepRendererBackendContractValueOnly = didKeepRendererBackendContractValueOnly
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Backend capability set 只记录后端无关的能力集合占位 facts；
// 它不绑定平台能力、不创建执行资源，也不代表可以绘制。
struct CjguiInternalRendererBackendCapabilitySet {
    let contract: CjguiInternalRendererBackendContract
    let didPrepareRendererBackendCapabilitySet: Bool
    let shouldDeferRendererBackendCapabilitySet: Bool
    let shouldReportRendererBackendCapabilitySetBlocked: Bool
    let didPreserveRendererBackendContract: Bool
    let didKeepRendererBackendCapabilitySetAgnostic: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        contract: CjguiInternalRendererBackendContract,
        didPrepareRendererBackendCapabilitySet: Bool,
        shouldDeferRendererBackendCapabilitySet: Bool,
        shouldReportRendererBackendCapabilitySetBlocked: Bool,
        didPreserveRendererBackendContract: Bool,
        didKeepRendererBackendCapabilitySetAgnostic: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.contract = contract
        this.didPrepareRendererBackendCapabilitySet = didPrepareRendererBackendCapabilitySet
        this.shouldDeferRendererBackendCapabilitySet = shouldDeferRendererBackendCapabilitySet
        this.shouldReportRendererBackendCapabilitySetBlocked = shouldReportRendererBackendCapabilitySetBlocked
        this.didPreserveRendererBackendContract = didPreserveRendererBackendContract
        this.didKeepRendererBackendCapabilitySetAgnostic = didKeepRendererBackendCapabilitySetAgnostic
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Adapter contract admission 只是 backend contract + capability set 的内部准入 facts；
// 它不是平台提交、绘制队列或 renderer state mutation。
struct CjguiInternalRendererAdapterContractAdmission {
    let capabilitySet: CjguiInternalRendererBackendCapabilitySet
    let didAdmitRendererAdapterContract: Bool
    let shouldDeferRendererAdapterContractAdmission: Bool
    let shouldReportRendererAdapterContractAdmissionBlocked: Bool
    let didPreserveRendererBackendCapabilitySet: Bool
    let didKeepRendererAdapterContractAdmissionValueOnly: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        capabilitySet: CjguiInternalRendererBackendCapabilitySet,
        didAdmitRendererAdapterContract: Bool,
        shouldDeferRendererAdapterContractAdmission: Bool,
        shouldReportRendererAdapterContractAdmissionBlocked: Bool,
        didPreserveRendererBackendCapabilitySet: Bool,
        didKeepRendererAdapterContractAdmissionValueOnly: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.capabilitySet = capabilitySet
        this.didAdmitRendererAdapterContract = didAdmitRendererAdapterContract
        this.shouldDeferRendererAdapterContractAdmission = shouldDeferRendererAdapterContractAdmission
        this.shouldReportRendererAdapterContractAdmissionBlocked = shouldReportRendererAdapterContractAdmissionBlocked
        this.didPreserveRendererBackendCapabilitySet = didPreserveRendererBackendCapabilitySet
        this.didKeepRendererAdapterContractAdmissionValueOnly = didKeepRendererAdapterContractAdmissionValueOnly
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// No-render contract readiness 是本轮 canonical endpoint；
// readiness 只表示 future backend contract boundary 可以继续评估，不代表允许真实绘制。
struct CjguiInternalRendererBackendNoRenderContractReadiness {
    let admission: CjguiInternalRendererAdapterContractAdmission
    let isRendererBackendNoRenderContractReady: Bool
    let canFutureRendererBackendContractBoundaryEvaluate: Bool
    let shouldDeferRendererBackendNoRenderContractReadiness: Bool
    let shouldReportRendererBackendNoRenderContractReadinessBlocked: Bool
    let didRecordRendererBackendNoRenderContractReadiness: Bool
    let didPreserveRendererAdapterContractAdmission: Bool
    let didKeepRendererBackendContractReadinessValueOnly: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        admission: CjguiInternalRendererAdapterContractAdmission,
        isRendererBackendNoRenderContractReady: Bool,
        canFutureRendererBackendContractBoundaryEvaluate: Bool,
        shouldDeferRendererBackendNoRenderContractReadiness: Bool,
        shouldReportRendererBackendNoRenderContractReadinessBlocked: Bool,
        didRecordRendererBackendNoRenderContractReadiness: Bool,
        didPreserveRendererAdapterContractAdmission: Bool,
        didKeepRendererBackendContractReadinessValueOnly: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.admission = admission
        this.isRendererBackendNoRenderContractReady = isRendererBackendNoRenderContractReady
        this.canFutureRendererBackendContractBoundaryEvaluate = canFutureRendererBackendContractBoundaryEvaluate
        this.shouldDeferRendererBackendNoRenderContractReadiness = shouldDeferRendererBackendNoRenderContractReadiness
        this.shouldReportRendererBackendNoRenderContractReadinessBlocked = shouldReportRendererBackendNoRenderContractReadinessBlocked
        this.didRecordRendererBackendNoRenderContractReadiness = didRecordRendererBackendNoRenderContractReadiness
        this.didPreserveRendererAdapterContractAdmission = didPreserveRendererAdapterContractAdmission
        this.didKeepRendererBackendContractReadinessValueOnly = didKeepRendererBackendContractReadinessValueOnly
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererBackendContract(
    noRenderReadiness: CjguiInternalRendererBackendNoRenderReadiness
): CjguiInternalRendererBackendContract {
    let readinessOpen = noRenderReadiness.isRendererBackendNoRenderReady &&
        noRenderReadiness.canFutureRendererBackendBoundaryEvaluate &&
        noRenderReadiness.didRecordRendererBackendNoRenderReadiness &&
        noRenderReadiness.didPreserveRendererBackendAdapterAdmission &&
        noRenderReadiness.didKeepRendererBackendReadinessValueOnly &&
        noRenderReadiness.didAvoidRendererBackendImplementation &&
        noRenderReadiness.didAvoidPlatformResourceBinding &&
        noRenderReadiness.didAvoidRendererStateWrite &&
        noRenderReadiness.didAvoidDrawingSideEffect &&
        noRenderReadiness.didStayFullRebuildOnly &&
        noRenderReadiness.shouldDeferRendererBackendNoRenderReadiness == false &&
        noRenderReadiness.shouldReportRendererBackendNoRenderReadinessBlocked == false
    let readinessDeferred = noRenderReadiness.isRendererBackendNoRenderReady == false &&
        noRenderReadiness.canFutureRendererBackendBoundaryEvaluate == false &&
        noRenderReadiness.didRecordRendererBackendNoRenderReadiness == false &&
        noRenderReadiness.didPreserveRendererBackendAdapterAdmission == false &&
        noRenderReadiness.didKeepRendererBackendReadinessValueOnly &&
        noRenderReadiness.didAvoidRendererBackendImplementation &&
        noRenderReadiness.didAvoidPlatformResourceBinding &&
        noRenderReadiness.didAvoidRendererStateWrite &&
        noRenderReadiness.didAvoidDrawingSideEffect &&
        noRenderReadiness.didStayFullRebuildOnly &&
        noRenderReadiness.shouldDeferRendererBackendNoRenderReadiness &&
        noRenderReadiness.shouldReportRendererBackendNoRenderReadinessBlocked == false
    let readinessInconsistent = (
        noRenderReadiness.isRendererBackendNoRenderReady &&
            (
                noRenderReadiness.canFutureRendererBackendBoundaryEvaluate == false ||
                noRenderReadiness.didRecordRendererBackendNoRenderReadiness == false ||
                noRenderReadiness.didPreserveRendererBackendAdapterAdmission == false ||
                noRenderReadiness.didKeepRendererBackendReadinessValueOnly == false ||
                noRenderReadiness.didAvoidRendererBackendImplementation == false ||
                noRenderReadiness.didAvoidPlatformResourceBinding == false ||
                noRenderReadiness.didAvoidRendererStateWrite == false ||
                noRenderReadiness.didAvoidDrawingSideEffect == false ||
                noRenderReadiness.didStayFullRebuildOnly == false ||
                noRenderReadiness.shouldDeferRendererBackendNoRenderReadiness ||
                noRenderReadiness.shouldReportRendererBackendNoRenderReadinessBlocked
            )
        ) ||
        (noRenderReadiness.canFutureRendererBackendBoundaryEvaluate &&
            noRenderReadiness.isRendererBackendNoRenderReady == false) ||
        (noRenderReadiness.didRecordRendererBackendNoRenderReadiness &&
            noRenderReadiness.isRendererBackendNoRenderReady == false) ||
        (noRenderReadiness.shouldDeferRendererBackendNoRenderReadiness &&
            noRenderReadiness.shouldReportRendererBackendNoRenderReadinessBlocked)

    // no-render readiness facts 不一致时必须 fail-closed，避免把契约层误升格为真实后端许可。
    if (
        noRenderReadiness.shouldReportRendererBackendNoRenderReadinessBlocked ||
        readinessInconsistent
    ) {
        return CjguiInternalRendererBackendContract(
            noRenderReadiness,
            false,
            false,
            true,
            false,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (readinessOpen) {
        return CjguiInternalRendererBackendContract(
            noRenderReadiness,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (readinessDeferred) {
        return CjguiInternalRendererBackendContract(
            noRenderReadiness,
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

    return CjguiInternalRendererBackendContract(
        noRenderReadiness,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererBackendCapabilitySet(
    contract: CjguiInternalRendererBackendContract
): CjguiInternalRendererBackendCapabilitySet {
    let contractReady = contract.didPrepareRendererBackendContract &&
        contract.didPreserveRendererBackendNoRenderReadiness &&
        contract.didKeepRendererBackendContractValueOnly &&
        contract.didAvoidRendererBackendImplementation &&
        contract.didAvoidPlatformResourceBinding &&
        contract.didAvoidRendererStateWrite &&
        contract.didAvoidDrawingSideEffect &&
        contract.didStayFullRebuildOnly &&
        contract.shouldDeferRendererBackendContract == false &&
        contract.shouldReportRendererBackendContractBlocked == false
    let contractDeferred = contract.didPrepareRendererBackendContract == false &&
        contract.didPreserveRendererBackendNoRenderReadiness == false &&
        contract.didKeepRendererBackendContractValueOnly &&
        contract.didAvoidRendererBackendImplementation &&
        contract.didAvoidPlatformResourceBinding &&
        contract.didAvoidRendererStateWrite &&
        contract.didAvoidDrawingSideEffect &&
        contract.didStayFullRebuildOnly &&
        contract.shouldDeferRendererBackendContract &&
        contract.shouldReportRendererBackendContractBlocked == false
    let contractInconsistent = (
        contract.didPrepareRendererBackendContract &&
            (
                contract.didPreserveRendererBackendNoRenderReadiness == false ||
                contract.didKeepRendererBackendContractValueOnly == false ||
                contract.didAvoidRendererBackendImplementation == false ||
                contract.didAvoidPlatformResourceBinding == false ||
                contract.didAvoidRendererStateWrite == false ||
                contract.didAvoidDrawingSideEffect == false ||
                contract.didStayFullRebuildOnly == false ||
                contract.shouldDeferRendererBackendContract ||
                contract.shouldReportRendererBackendContractBlocked
            )
        ) ||
        (contract.didPreserveRendererBackendNoRenderReadiness &&
            contract.didPrepareRendererBackendContract == false) ||
        (contract.shouldDeferRendererBackendContract &&
            contract.shouldReportRendererBackendContractBlocked)

    // contract facts 不一致时必须 fail-closed，capability set 只能保持占位 value。
    if (
        contract.shouldReportRendererBackendContractBlocked ||
        contractInconsistent
    ) {
        return CjguiInternalRendererBackendCapabilitySet(
            contract,
            false,
            false,
            true,
            false,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (contractReady) {
        return CjguiInternalRendererBackendCapabilitySet(
            contract,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (contractDeferred) {
        return CjguiInternalRendererBackendCapabilitySet(
            contract,
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

    return CjguiInternalRendererBackendCapabilitySet(
        contract,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererAdapterContractAdmission(
    capabilitySet: CjguiInternalRendererBackendCapabilitySet
): CjguiInternalRendererAdapterContractAdmission {
    let capabilitySetReady = capabilitySet.didPrepareRendererBackendCapabilitySet &&
        capabilitySet.didPreserveRendererBackendContract &&
        capabilitySet.didKeepRendererBackendCapabilitySetAgnostic &&
        capabilitySet.didAvoidRendererBackendImplementation &&
        capabilitySet.didAvoidPlatformResourceBinding &&
        capabilitySet.didAvoidRendererStateWrite &&
        capabilitySet.didAvoidDrawingSideEffect &&
        capabilitySet.didStayFullRebuildOnly &&
        capabilitySet.shouldDeferRendererBackendCapabilitySet == false &&
        capabilitySet.shouldReportRendererBackendCapabilitySetBlocked == false
    let capabilitySetDeferred = capabilitySet.didPrepareRendererBackendCapabilitySet == false &&
        capabilitySet.didPreserveRendererBackendContract == false &&
        capabilitySet.didKeepRendererBackendCapabilitySetAgnostic &&
        capabilitySet.didAvoidRendererBackendImplementation &&
        capabilitySet.didAvoidPlatformResourceBinding &&
        capabilitySet.didAvoidRendererStateWrite &&
        capabilitySet.didAvoidDrawingSideEffect &&
        capabilitySet.didStayFullRebuildOnly &&
        capabilitySet.shouldDeferRendererBackendCapabilitySet &&
        capabilitySet.shouldReportRendererBackendCapabilitySetBlocked == false
    let capabilitySetInconsistent = (
        capabilitySet.didPrepareRendererBackendCapabilitySet &&
            (
                capabilitySet.didPreserveRendererBackendContract == false ||
                capabilitySet.didKeepRendererBackendCapabilitySetAgnostic == false ||
                capabilitySet.didAvoidRendererBackendImplementation == false ||
                capabilitySet.didAvoidPlatformResourceBinding == false ||
                capabilitySet.didAvoidRendererStateWrite == false ||
                capabilitySet.didAvoidDrawingSideEffect == false ||
                capabilitySet.didStayFullRebuildOnly == false ||
                capabilitySet.shouldDeferRendererBackendCapabilitySet ||
                capabilitySet.shouldReportRendererBackendCapabilitySetBlocked
            )
        ) ||
        (capabilitySet.didPreserveRendererBackendContract &&
            capabilitySet.didPrepareRendererBackendCapabilitySet == false) ||
        (capabilitySet.shouldDeferRendererBackendCapabilitySet &&
            capabilitySet.shouldReportRendererBackendCapabilitySetBlocked)

    // capability set facts 不一致时必须 fail-closed，contract admission 不能伪造成可执行后端。
    if (
        capabilitySet.shouldReportRendererBackendCapabilitySetBlocked ||
        capabilitySetInconsistent
    ) {
        return CjguiInternalRendererAdapterContractAdmission(
            capabilitySet,
            false,
            false,
            true,
            false,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (capabilitySetReady) {
        return CjguiInternalRendererAdapterContractAdmission(
            capabilitySet,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (capabilitySetDeferred) {
        return CjguiInternalRendererAdapterContractAdmission(
            capabilitySet,
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

    return CjguiInternalRendererAdapterContractAdmission(
        capabilitySet,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererBackendNoRenderContractReadiness(
    admission: CjguiInternalRendererAdapterContractAdmission
): CjguiInternalRendererBackendNoRenderContractReadiness {
    let admissionReady = admission.didAdmitRendererAdapterContract &&
        admission.didPreserveRendererBackendCapabilitySet &&
        admission.didKeepRendererAdapterContractAdmissionValueOnly &&
        admission.didAvoidRendererBackendImplementation &&
        admission.didAvoidPlatformResourceBinding &&
        admission.didAvoidRendererStateWrite &&
        admission.didAvoidDrawingSideEffect &&
        admission.didStayFullRebuildOnly &&
        admission.shouldDeferRendererAdapterContractAdmission == false &&
        admission.shouldReportRendererAdapterContractAdmissionBlocked == false
    let admissionDeferred = admission.didAdmitRendererAdapterContract == false &&
        admission.didPreserveRendererBackendCapabilitySet == false &&
        admission.didKeepRendererAdapterContractAdmissionValueOnly &&
        admission.didAvoidRendererBackendImplementation &&
        admission.didAvoidPlatformResourceBinding &&
        admission.didAvoidRendererStateWrite &&
        admission.didAvoidDrawingSideEffect &&
        admission.didStayFullRebuildOnly &&
        admission.shouldDeferRendererAdapterContractAdmission &&
        admission.shouldReportRendererAdapterContractAdmissionBlocked == false
    let admissionInconsistent = (
        admission.didAdmitRendererAdapterContract &&
            (
                admission.didPreserveRendererBackendCapabilitySet == false ||
                admission.didKeepRendererAdapterContractAdmissionValueOnly == false ||
                admission.didAvoidRendererBackendImplementation == false ||
                admission.didAvoidPlatformResourceBinding == false ||
                admission.didAvoidRendererStateWrite == false ||
                admission.didAvoidDrawingSideEffect == false ||
                admission.didStayFullRebuildOnly == false ||
                admission.shouldDeferRendererAdapterContractAdmission ||
                admission.shouldReportRendererAdapterContractAdmissionBlocked
            )
        ) ||
        (admission.didPreserveRendererBackendCapabilitySet &&
            admission.didAdmitRendererAdapterContract == false) ||
        (admission.shouldDeferRendererAdapterContractAdmission &&
            admission.shouldReportRendererAdapterContractAdmissionBlocked)

    // admission facts 不一致时必须 fail-closed，no-render contract readiness 不能变成真实绘制许可。
    if (
        admission.shouldReportRendererAdapterContractAdmissionBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalRendererBackendNoRenderContractReadiness(
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
        return CjguiInternalRendererBackendNoRenderContractReadiness(
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
        return CjguiInternalRendererBackendNoRenderContractReadiness(
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

    return CjguiInternalRendererBackendNoRenderContractReadiness(
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

func cjguiInternalExecuteDefaultRendererBackendContractDraft(): CjguiInternalRendererBackendNoRenderContractReadiness {
    // 默认 draft 只串联 backend contract 前置 value facts；
    // 它不执行平台后端、不触发真实绘制，也不写 renderer state。
    let noRenderReadiness = cjguiInternalExecuteDefaultRendererBackendAdapterDraft()
    let contract = cjguiInternalBuildRendererBackendContract(noRenderReadiness)
    let capabilitySet = cjguiInternalBuildRendererBackendCapabilitySet(contract)
    let admission = cjguiInternalBuildRendererAdapterContractAdmission(capabilitySet)
    return cjguiInternalBuildRendererBackendNoRenderContractReadiness(admission)
}

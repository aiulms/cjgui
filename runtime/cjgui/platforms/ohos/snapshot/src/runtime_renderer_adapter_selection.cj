package cjgui

// Internal Renderer Adapter Selection value owner:
// - 本文件只消费 CjguiInternalRendererBackendNoRenderCapabilityReadiness。
// - Truth 是 adapter selection policy、candidate family、selection admission 与 no-render selection readiness 的内部 value facts。
// - Stop-line: 这里只描述 future selection 边界是否可继续评估；
//   不选择具体平台 adapter、不创建图形执行资源、不触发真实绘制、不写 renderer state，
//   不做真实合批或增量渲染，也不回塞 critical runtime_state.cj。

// Adapter selection policy 只说明 capability readiness 可以进入选择策略前置评估；
// 它不是具体平台 adapter 选择，也不是 renderer 侧效果许可。
struct CjguiInternalRendererAdapterSelectionPolicy {
    let capabilityReadiness: CjguiInternalRendererBackendNoRenderCapabilityReadiness
    let didPrepareRendererAdapterSelectionPolicy: Bool
    let shouldDeferRendererAdapterSelectionPolicy: Bool
    let shouldReportRendererAdapterSelectionPolicyBlocked: Bool
    let didPreserveRendererBackendCapabilityReadiness: Bool
    let didKeepRendererAdapterSelectionPolicyAgnostic: Bool
    let didAvoidConcreteRendererAdapterChoice: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        capabilityReadiness: CjguiInternalRendererBackendNoRenderCapabilityReadiness,
        didPrepareRendererAdapterSelectionPolicy: Bool,
        shouldDeferRendererAdapterSelectionPolicy: Bool,
        shouldReportRendererAdapterSelectionPolicyBlocked: Bool,
        didPreserveRendererBackendCapabilityReadiness: Bool,
        didKeepRendererAdapterSelectionPolicyAgnostic: Bool,
        didAvoidConcreteRendererAdapterChoice: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.capabilityReadiness = capabilityReadiness
        this.didPrepareRendererAdapterSelectionPolicy = didPrepareRendererAdapterSelectionPolicy
        this.shouldDeferRendererAdapterSelectionPolicy = shouldDeferRendererAdapterSelectionPolicy
        this.shouldReportRendererAdapterSelectionPolicyBlocked = shouldReportRendererAdapterSelectionPolicyBlocked
        this.didPreserveRendererBackendCapabilityReadiness = didPreserveRendererBackendCapabilityReadiness
        this.didKeepRendererAdapterSelectionPolicyAgnostic = didKeepRendererAdapterSelectionPolicyAgnostic
        this.didAvoidConcreteRendererAdapterChoice = didAvoidConcreteRendererAdapterChoice
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Adapter candidate family 只记录后端无关的候选族 facts；
// 它不承诺具体平台 adapter，也不触发真实 renderer 行为。
struct CjguiInternalRendererAdapterCandidateFamily {
    let selectionPolicy: CjguiInternalRendererAdapterSelectionPolicy
    let didPrepareRendererAdapterCandidateFamily: Bool
    let shouldDeferRendererAdapterCandidateFamily: Bool
    let shouldReportRendererAdapterCandidateFamilyBlocked: Bool
    let didPreserveRendererAdapterSelectionPolicy: Bool
    let didKeepRendererAdapterCandidateFamilyAgnostic: Bool
    let didAvoidConcreteRendererAdapterChoice: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        selectionPolicy: CjguiInternalRendererAdapterSelectionPolicy,
        didPrepareRendererAdapterCandidateFamily: Bool,
        shouldDeferRendererAdapterCandidateFamily: Bool,
        shouldReportRendererAdapterCandidateFamilyBlocked: Bool,
        didPreserveRendererAdapterSelectionPolicy: Bool,
        didKeepRendererAdapterCandidateFamilyAgnostic: Bool,
        didAvoidConcreteRendererAdapterChoice: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.selectionPolicy = selectionPolicy
        this.didPrepareRendererAdapterCandidateFamily = didPrepareRendererAdapterCandidateFamily
        this.shouldDeferRendererAdapterCandidateFamily = shouldDeferRendererAdapterCandidateFamily
        this.shouldReportRendererAdapterCandidateFamilyBlocked = shouldReportRendererAdapterCandidateFamilyBlocked
        this.didPreserveRendererAdapterSelectionPolicy = didPreserveRendererAdapterSelectionPolicy
        this.didKeepRendererAdapterCandidateFamilyAgnostic = didKeepRendererAdapterCandidateFamilyAgnostic
        this.didAvoidConcreteRendererAdapterChoice = didAvoidConcreteRendererAdapterChoice
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Adapter selection admission 只表达选择边界准入 facts；
// 它不是具体 adapter 绑定，也不会产生真实绘制侧效果。
struct CjguiInternalRendererAdapterSelectionAdmission {
    let candidateFamily: CjguiInternalRendererAdapterCandidateFamily
    let didAdmitRendererAdapterSelection: Bool
    let shouldDeferRendererAdapterSelectionAdmission: Bool
    let shouldReportRendererAdapterSelectionAdmissionBlocked: Bool
    let didPreserveRendererAdapterCandidateFamily: Bool
    let didKeepRendererAdapterSelectionAdmissionValueOnly: Bool
    let didAvoidConcreteRendererAdapterChoice: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        candidateFamily: CjguiInternalRendererAdapterCandidateFamily,
        didAdmitRendererAdapterSelection: Bool,
        shouldDeferRendererAdapterSelectionAdmission: Bool,
        shouldReportRendererAdapterSelectionAdmissionBlocked: Bool,
        didPreserveRendererAdapterCandidateFamily: Bool,
        didKeepRendererAdapterSelectionAdmissionValueOnly: Bool,
        didAvoidConcreteRendererAdapterChoice: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.candidateFamily = candidateFamily
        this.didAdmitRendererAdapterSelection = didAdmitRendererAdapterSelection
        this.shouldDeferRendererAdapterSelectionAdmission = shouldDeferRendererAdapterSelectionAdmission
        this.shouldReportRendererAdapterSelectionAdmissionBlocked = shouldReportRendererAdapterSelectionAdmissionBlocked
        this.didPreserveRendererAdapterCandidateFamily = didPreserveRendererAdapterCandidateFamily
        this.didKeepRendererAdapterSelectionAdmissionValueOnly = didKeepRendererAdapterSelectionAdmissionValueOnly
        this.didAvoidConcreteRendererAdapterChoice = didAvoidConcreteRendererAdapterChoice
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// No-render selection readiness 是本轮 canonical endpoint；
// readiness 只表示 future adapter selection boundary 可以继续评估，不代表允许真实绘制。
struct CjguiInternalRendererNoRenderSelectionReadiness {
    let selectionAdmission: CjguiInternalRendererAdapterSelectionAdmission
    let isRendererNoRenderSelectionReady: Bool
    let canFutureRendererAdapterSelectionBoundaryEvaluate: Bool
    let shouldDeferRendererNoRenderSelectionReadiness: Bool
    let shouldReportRendererNoRenderSelectionReadinessBlocked: Bool
    let didRecordRendererNoRenderSelectionReadiness: Bool
    let didPreserveRendererAdapterSelectionAdmission: Bool
    let didKeepRendererAdapterSelectionReadinessValueOnly: Bool
    let didAvoidConcreteRendererAdapterChoice: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        selectionAdmission: CjguiInternalRendererAdapterSelectionAdmission,
        isRendererNoRenderSelectionReady: Bool,
        canFutureRendererAdapterSelectionBoundaryEvaluate: Bool,
        shouldDeferRendererNoRenderSelectionReadiness: Bool,
        shouldReportRendererNoRenderSelectionReadinessBlocked: Bool,
        didRecordRendererNoRenderSelectionReadiness: Bool,
        didPreserveRendererAdapterSelectionAdmission: Bool,
        didKeepRendererAdapterSelectionReadinessValueOnly: Bool,
        didAvoidConcreteRendererAdapterChoice: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.selectionAdmission = selectionAdmission
        this.isRendererNoRenderSelectionReady = isRendererNoRenderSelectionReady
        this.canFutureRendererAdapterSelectionBoundaryEvaluate = canFutureRendererAdapterSelectionBoundaryEvaluate
        this.shouldDeferRendererNoRenderSelectionReadiness = shouldDeferRendererNoRenderSelectionReadiness
        this.shouldReportRendererNoRenderSelectionReadinessBlocked = shouldReportRendererNoRenderSelectionReadinessBlocked
        this.didRecordRendererNoRenderSelectionReadiness = didRecordRendererNoRenderSelectionReadiness
        this.didPreserveRendererAdapterSelectionAdmission = didPreserveRendererAdapterSelectionAdmission
        this.didKeepRendererAdapterSelectionReadinessValueOnly = didKeepRendererAdapterSelectionReadinessValueOnly
        this.didAvoidConcreteRendererAdapterChoice = didAvoidConcreteRendererAdapterChoice
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererAdapterSelectionPolicy(
    capabilityReadiness: CjguiInternalRendererBackendNoRenderCapabilityReadiness
): CjguiInternalRendererAdapterSelectionPolicy {
    let capabilityReady = capabilityReadiness.isRendererBackendNoRenderCapabilityReady &&
        capabilityReadiness.canFutureRendererBackendCapabilityBoundaryEvaluate &&
        capabilityReadiness.didRecordRendererBackendNoRenderCapabilityReadiness &&
        capabilityReadiness.didPreserveRendererBackendConstraintProfile &&
        capabilityReadiness.didKeepRendererBackendCapabilityReadinessValueOnly &&
        capabilityReadiness.didAvoidRendererBackendImplementation &&
        capabilityReadiness.didAvoidPlatformResourceBinding &&
        capabilityReadiness.didAvoidRendererStateWrite &&
        capabilityReadiness.didAvoidDrawingSideEffect &&
        capabilityReadiness.didAvoidConcretePlatformCapabilityPromise &&
        capabilityReadiness.didStayFullRebuildOnly &&
        capabilityReadiness.shouldDeferRendererBackendNoRenderCapabilityReadiness == false &&
        capabilityReadiness.shouldReportRendererBackendNoRenderCapabilityReadinessBlocked == false
    let capabilityDeferred = capabilityReadiness.isRendererBackendNoRenderCapabilityReady == false &&
        capabilityReadiness.canFutureRendererBackendCapabilityBoundaryEvaluate == false &&
        capabilityReadiness.didRecordRendererBackendNoRenderCapabilityReadiness == false &&
        capabilityReadiness.didPreserveRendererBackendConstraintProfile == false &&
        capabilityReadiness.didKeepRendererBackendCapabilityReadinessValueOnly &&
        capabilityReadiness.didAvoidRendererBackendImplementation &&
        capabilityReadiness.didAvoidPlatformResourceBinding &&
        capabilityReadiness.didAvoidRendererStateWrite &&
        capabilityReadiness.didAvoidDrawingSideEffect &&
        capabilityReadiness.didAvoidConcretePlatformCapabilityPromise &&
        capabilityReadiness.didStayFullRebuildOnly &&
        capabilityReadiness.shouldDeferRendererBackendNoRenderCapabilityReadiness &&
        capabilityReadiness.shouldReportRendererBackendNoRenderCapabilityReadinessBlocked == false
    let capabilityInconsistent = (
        capabilityReadiness.isRendererBackendNoRenderCapabilityReady &&
            (
                capabilityReadiness.canFutureRendererBackendCapabilityBoundaryEvaluate == false ||
                capabilityReadiness.didRecordRendererBackendNoRenderCapabilityReadiness == false ||
                capabilityReadiness.didPreserveRendererBackendConstraintProfile == false ||
                capabilityReadiness.didKeepRendererBackendCapabilityReadinessValueOnly == false ||
                capabilityReadiness.didAvoidRendererBackendImplementation == false ||
                capabilityReadiness.didAvoidPlatformResourceBinding == false ||
                capabilityReadiness.didAvoidRendererStateWrite == false ||
                capabilityReadiness.didAvoidDrawingSideEffect == false ||
                capabilityReadiness.didAvoidConcretePlatformCapabilityPromise == false ||
                capabilityReadiness.didStayFullRebuildOnly == false ||
                capabilityReadiness.shouldDeferRendererBackendNoRenderCapabilityReadiness ||
                capabilityReadiness.shouldReportRendererBackendNoRenderCapabilityReadinessBlocked
            )
        ) ||
        (capabilityReadiness.canFutureRendererBackendCapabilityBoundaryEvaluate &&
            capabilityReadiness.isRendererBackendNoRenderCapabilityReady == false) ||
        (capabilityReadiness.didRecordRendererBackendNoRenderCapabilityReadiness &&
            capabilityReadiness.isRendererBackendNoRenderCapabilityReady == false) ||
        (capabilityReadiness.shouldDeferRendererBackendNoRenderCapabilityReadiness &&
            capabilityReadiness.shouldReportRendererBackendNoRenderCapabilityReadinessBlocked)

    // capability readiness facts 不一致时必须 fail-closed，不能把 selection policy 伪造成真实 adapter 选择。
    if (
        capabilityReadiness.shouldReportRendererBackendNoRenderCapabilityReadinessBlocked ||
        capabilityInconsistent
    ) {
        return CjguiInternalRendererAdapterSelectionPolicy(
            capabilityReadiness,
            false,
            false,
            true,
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

    if (capabilityReady) {
        return CjguiInternalRendererAdapterSelectionPolicy(
            capabilityReadiness,
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

    if (capabilityDeferred) {
        return CjguiInternalRendererAdapterSelectionPolicy(
            capabilityReadiness,
            false,
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

    return CjguiInternalRendererAdapterSelectionPolicy(
        capabilityReadiness,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererAdapterCandidateFamily(
    selectionPolicy: CjguiInternalRendererAdapterSelectionPolicy
): CjguiInternalRendererAdapterCandidateFamily {
    let policyReady = selectionPolicy.didPrepareRendererAdapterSelectionPolicy &&
        selectionPolicy.didPreserveRendererBackendCapabilityReadiness &&
        selectionPolicy.didKeepRendererAdapterSelectionPolicyAgnostic &&
        selectionPolicy.didAvoidConcreteRendererAdapterChoice &&
        selectionPolicy.didAvoidRendererBackendImplementation &&
        selectionPolicy.didAvoidPlatformResourceBinding &&
        selectionPolicy.didAvoidRendererStateWrite &&
        selectionPolicy.didAvoidDrawingSideEffect &&
        selectionPolicy.didStayFullRebuildOnly &&
        selectionPolicy.shouldDeferRendererAdapterSelectionPolicy == false &&
        selectionPolicy.shouldReportRendererAdapterSelectionPolicyBlocked == false
    let policyDeferred = selectionPolicy.didPrepareRendererAdapterSelectionPolicy == false &&
        selectionPolicy.didPreserveRendererBackendCapabilityReadiness == false &&
        selectionPolicy.didKeepRendererAdapterSelectionPolicyAgnostic &&
        selectionPolicy.didAvoidConcreteRendererAdapterChoice &&
        selectionPolicy.didAvoidRendererBackendImplementation &&
        selectionPolicy.didAvoidPlatformResourceBinding &&
        selectionPolicy.didAvoidRendererStateWrite &&
        selectionPolicy.didAvoidDrawingSideEffect &&
        selectionPolicy.didStayFullRebuildOnly &&
        selectionPolicy.shouldDeferRendererAdapterSelectionPolicy &&
        selectionPolicy.shouldReportRendererAdapterSelectionPolicyBlocked == false
    let policyInconsistent = (
        selectionPolicy.didPrepareRendererAdapterSelectionPolicy &&
            (
                selectionPolicy.didPreserveRendererBackendCapabilityReadiness == false ||
                selectionPolicy.didKeepRendererAdapterSelectionPolicyAgnostic == false ||
                selectionPolicy.didAvoidConcreteRendererAdapterChoice == false ||
                selectionPolicy.didAvoidRendererBackendImplementation == false ||
                selectionPolicy.didAvoidPlatformResourceBinding == false ||
                selectionPolicy.didAvoidRendererStateWrite == false ||
                selectionPolicy.didAvoidDrawingSideEffect == false ||
                selectionPolicy.didStayFullRebuildOnly == false ||
                selectionPolicy.shouldDeferRendererAdapterSelectionPolicy ||
                selectionPolicy.shouldReportRendererAdapterSelectionPolicyBlocked
            )
        ) ||
        (selectionPolicy.didPreserveRendererBackendCapabilityReadiness &&
            selectionPolicy.didPrepareRendererAdapterSelectionPolicy == false) ||
        (selectionPolicy.shouldDeferRendererAdapterSelectionPolicy &&
            selectionPolicy.shouldReportRendererAdapterSelectionPolicyBlocked)

    // policy facts 不一致时必须 fail-closed，candidate family 不能变成具体平台 adapter。
    if (
        selectionPolicy.shouldReportRendererAdapterSelectionPolicyBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererAdapterCandidateFamily(
            selectionPolicy,
            false,
            false,
            true,
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

    if (policyReady) {
        return CjguiInternalRendererAdapterCandidateFamily(
            selectionPolicy,
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

    if (policyDeferred) {
        return CjguiInternalRendererAdapterCandidateFamily(
            selectionPolicy,
            false,
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

    return CjguiInternalRendererAdapterCandidateFamily(
        selectionPolicy,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererAdapterSelectionAdmission(
    candidateFamily: CjguiInternalRendererAdapterCandidateFamily
): CjguiInternalRendererAdapterSelectionAdmission {
    let familyReady = candidateFamily.didPrepareRendererAdapterCandidateFamily &&
        candidateFamily.didPreserveRendererAdapterSelectionPolicy &&
        candidateFamily.didKeepRendererAdapterCandidateFamilyAgnostic &&
        candidateFamily.didAvoidConcreteRendererAdapterChoice &&
        candidateFamily.didAvoidRendererBackendImplementation &&
        candidateFamily.didAvoidPlatformResourceBinding &&
        candidateFamily.didAvoidRendererStateWrite &&
        candidateFamily.didAvoidDrawingSideEffect &&
        candidateFamily.didStayFullRebuildOnly &&
        candidateFamily.shouldDeferRendererAdapterCandidateFamily == false &&
        candidateFamily.shouldReportRendererAdapterCandidateFamilyBlocked == false
    let familyDeferred = candidateFamily.didPrepareRendererAdapterCandidateFamily == false &&
        candidateFamily.didPreserveRendererAdapterSelectionPolicy == false &&
        candidateFamily.didKeepRendererAdapterCandidateFamilyAgnostic &&
        candidateFamily.didAvoidConcreteRendererAdapterChoice &&
        candidateFamily.didAvoidRendererBackendImplementation &&
        candidateFamily.didAvoidPlatformResourceBinding &&
        candidateFamily.didAvoidRendererStateWrite &&
        candidateFamily.didAvoidDrawingSideEffect &&
        candidateFamily.didStayFullRebuildOnly &&
        candidateFamily.shouldDeferRendererAdapterCandidateFamily &&
        candidateFamily.shouldReportRendererAdapterCandidateFamilyBlocked == false
    let familyInconsistent = (
        candidateFamily.didPrepareRendererAdapterCandidateFamily &&
            (
                candidateFamily.didPreserveRendererAdapterSelectionPolicy == false ||
                candidateFamily.didKeepRendererAdapterCandidateFamilyAgnostic == false ||
                candidateFamily.didAvoidConcreteRendererAdapterChoice == false ||
                candidateFamily.didAvoidRendererBackendImplementation == false ||
                candidateFamily.didAvoidPlatformResourceBinding == false ||
                candidateFamily.didAvoidRendererStateWrite == false ||
                candidateFamily.didAvoidDrawingSideEffect == false ||
                candidateFamily.didStayFullRebuildOnly == false ||
                candidateFamily.shouldDeferRendererAdapterCandidateFamily ||
                candidateFamily.shouldReportRendererAdapterCandidateFamilyBlocked
            )
        ) ||
        (candidateFamily.didPreserveRendererAdapterSelectionPolicy &&
            candidateFamily.didPrepareRendererAdapterCandidateFamily == false) ||
        (candidateFamily.shouldDeferRendererAdapterCandidateFamily &&
            candidateFamily.shouldReportRendererAdapterCandidateFamilyBlocked)

    // candidate family facts 不一致时必须 fail-closed，selection admission 不能伪造成可执行选择。
    if (
        candidateFamily.shouldReportRendererAdapterCandidateFamilyBlocked ||
        familyInconsistent
    ) {
        return CjguiInternalRendererAdapterSelectionAdmission(
            candidateFamily,
            false,
            false,
            true,
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

    if (familyReady) {
        return CjguiInternalRendererAdapterSelectionAdmission(
            candidateFamily,
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

    if (familyDeferred) {
        return CjguiInternalRendererAdapterSelectionAdmission(
            candidateFamily,
            false,
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

    return CjguiInternalRendererAdapterSelectionAdmission(
        candidateFamily,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererNoRenderSelectionReadiness(
    selectionAdmission: CjguiInternalRendererAdapterSelectionAdmission
): CjguiInternalRendererNoRenderSelectionReadiness {
    let admissionReady = selectionAdmission.didAdmitRendererAdapterSelection &&
        selectionAdmission.didPreserveRendererAdapterCandidateFamily &&
        selectionAdmission.didKeepRendererAdapterSelectionAdmissionValueOnly &&
        selectionAdmission.didAvoidConcreteRendererAdapterChoice &&
        selectionAdmission.didAvoidRendererBackendImplementation &&
        selectionAdmission.didAvoidPlatformResourceBinding &&
        selectionAdmission.didAvoidRendererStateWrite &&
        selectionAdmission.didAvoidDrawingSideEffect &&
        selectionAdmission.didStayFullRebuildOnly &&
        selectionAdmission.shouldDeferRendererAdapterSelectionAdmission == false &&
        selectionAdmission.shouldReportRendererAdapterSelectionAdmissionBlocked == false
    let admissionDeferred = selectionAdmission.didAdmitRendererAdapterSelection == false &&
        selectionAdmission.didPreserveRendererAdapterCandidateFamily == false &&
        selectionAdmission.didKeepRendererAdapterSelectionAdmissionValueOnly &&
        selectionAdmission.didAvoidConcreteRendererAdapterChoice &&
        selectionAdmission.didAvoidRendererBackendImplementation &&
        selectionAdmission.didAvoidPlatformResourceBinding &&
        selectionAdmission.didAvoidRendererStateWrite &&
        selectionAdmission.didAvoidDrawingSideEffect &&
        selectionAdmission.didStayFullRebuildOnly &&
        selectionAdmission.shouldDeferRendererAdapterSelectionAdmission &&
        selectionAdmission.shouldReportRendererAdapterSelectionAdmissionBlocked == false
    let admissionInconsistent = (
        selectionAdmission.didAdmitRendererAdapterSelection &&
            (
                selectionAdmission.didPreserveRendererAdapterCandidateFamily == false ||
                selectionAdmission.didKeepRendererAdapterSelectionAdmissionValueOnly == false ||
                selectionAdmission.didAvoidConcreteRendererAdapterChoice == false ||
                selectionAdmission.didAvoidRendererBackendImplementation == false ||
                selectionAdmission.didAvoidPlatformResourceBinding == false ||
                selectionAdmission.didAvoidRendererStateWrite == false ||
                selectionAdmission.didAvoidDrawingSideEffect == false ||
                selectionAdmission.didStayFullRebuildOnly == false ||
                selectionAdmission.shouldDeferRendererAdapterSelectionAdmission ||
                selectionAdmission.shouldReportRendererAdapterSelectionAdmissionBlocked
            )
        ) ||
        (selectionAdmission.didPreserveRendererAdapterCandidateFamily &&
            selectionAdmission.didAdmitRendererAdapterSelection == false) ||
        (selectionAdmission.shouldDeferRendererAdapterSelectionAdmission &&
            selectionAdmission.shouldReportRendererAdapterSelectionAdmissionBlocked)

    // selection admission facts 不一致时必须 fail-closed，readiness 不能变成真实绘制许可。
    if (
        selectionAdmission.shouldReportRendererAdapterSelectionAdmissionBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalRendererNoRenderSelectionReadiness(
            selectionAdmission,
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
            true,
            true
        )
    }

    if (admissionReady) {
        return CjguiInternalRendererNoRenderSelectionReadiness(
            selectionAdmission,
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
            true,
            true
        )
    }

    if (admissionDeferred) {
        return CjguiInternalRendererNoRenderSelectionReadiness(
            selectionAdmission,
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
            true,
            true
        )
    }

    return CjguiInternalRendererNoRenderSelectionReadiness(
        selectionAdmission,
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
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererAdapterSelectionDraft(): CjguiInternalRendererNoRenderSelectionReadiness {
    // 默认 draft 只串联 adapter selection 前置 value facts；
    // 它不选择具体平台 adapter、不触发真实绘制，也不写 renderer state。
    let capabilityReadiness = cjguiInternalExecuteDefaultRendererBackendCapabilityDraft()
    let selectionPolicy = cjguiInternalBuildRendererAdapterSelectionPolicy(capabilityReadiness)
    let candidateFamily = cjguiInternalBuildRendererAdapterCandidateFamily(selectionPolicy)
    let selectionAdmission = cjguiInternalBuildRendererAdapterSelectionAdmission(candidateFamily)
    return cjguiInternalBuildRendererNoRenderSelectionReadiness(selectionAdmission)
}

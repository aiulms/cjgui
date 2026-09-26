package cjgui

// Internal Renderer Backend Capability profile owner:
// - 本文件只消费 CjguiInternalRendererBackendNoRenderContractReadiness。
// - Truth 是后端能力 profile、feature placeholder、constraint profile 与 no-render capability readiness 的内部 value facts。
// - Stop-line: 这里只描述 future capability 边界是否可继续评估；
//   不绑定平台实现、不创建图形执行资源、不触发真实绘制、不写 renderer state，
//   不做真实合批或增量渲染，也不回塞 critical runtime_state.cj。

// Backend capability profile 只说明 contract readiness 可以进入能力 profile 前置评估；
// 它不是具体平台能力枚举承诺，也不是绘制许可或 renderer state 写入。
struct CjguiInternalRendererBackendCapabilityProfile {
    let contractReadiness: CjguiInternalRendererBackendNoRenderContractReadiness
    let didPrepareRendererBackendCapabilityProfile: Bool
    let shouldDeferRendererBackendCapabilityProfile: Bool
    let shouldReportRendererBackendCapabilityProfileBlocked: Bool
    let didPreserveRendererBackendContractReadiness: Bool
    let didKeepRendererBackendCapabilityProfileAgnostic: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didAvoidConcretePlatformCapabilityPromise: Bool
    let didStayFullRebuildOnly: Bool

    init(
        contractReadiness: CjguiInternalRendererBackendNoRenderContractReadiness,
        didPrepareRendererBackendCapabilityProfile: Bool,
        shouldDeferRendererBackendCapabilityProfile: Bool,
        shouldReportRendererBackendCapabilityProfileBlocked: Bool,
        didPreserveRendererBackendContractReadiness: Bool,
        didKeepRendererBackendCapabilityProfileAgnostic: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didAvoidConcretePlatformCapabilityPromise: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.contractReadiness = contractReadiness
        this.didPrepareRendererBackendCapabilityProfile = didPrepareRendererBackendCapabilityProfile
        this.shouldDeferRendererBackendCapabilityProfile = shouldDeferRendererBackendCapabilityProfile
        this.shouldReportRendererBackendCapabilityProfileBlocked = shouldReportRendererBackendCapabilityProfileBlocked
        this.didPreserveRendererBackendContractReadiness = didPreserveRendererBackendContractReadiness
        this.didKeepRendererBackendCapabilityProfileAgnostic = didKeepRendererBackendCapabilityProfileAgnostic
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didAvoidConcretePlatformCapabilityPromise = didAvoidConcretePlatformCapabilityPromise
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Feature placeholder 只记录后端无关的 feature 占位 facts；
// 它不描述具体平台能力，也不代表 future adapter 已经可执行。
struct CjguiInternalRendererBackendFeaturePlaceholder {
    let capabilityProfile: CjguiInternalRendererBackendCapabilityProfile
    let didPrepareRendererBackendFeaturePlaceholder: Bool
    let shouldDeferRendererBackendFeaturePlaceholder: Bool
    let shouldReportRendererBackendFeaturePlaceholderBlocked: Bool
    let didPreserveRendererBackendCapabilityProfile: Bool
    let didKeepRendererBackendFeaturePlaceholderAgnostic: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didAvoidConcretePlatformCapabilityPromise: Bool
    let didStayFullRebuildOnly: Bool

    init(
        capabilityProfile: CjguiInternalRendererBackendCapabilityProfile,
        didPrepareRendererBackendFeaturePlaceholder: Bool,
        shouldDeferRendererBackendFeaturePlaceholder: Bool,
        shouldReportRendererBackendFeaturePlaceholderBlocked: Bool,
        didPreserveRendererBackendCapabilityProfile: Bool,
        didKeepRendererBackendFeaturePlaceholderAgnostic: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didAvoidConcretePlatformCapabilityPromise: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.capabilityProfile = capabilityProfile
        this.didPrepareRendererBackendFeaturePlaceholder = didPrepareRendererBackendFeaturePlaceholder
        this.shouldDeferRendererBackendFeaturePlaceholder = shouldDeferRendererBackendFeaturePlaceholder
        this.shouldReportRendererBackendFeaturePlaceholderBlocked = shouldReportRendererBackendFeaturePlaceholderBlocked
        this.didPreserveRendererBackendCapabilityProfile = didPreserveRendererBackendCapabilityProfile
        this.didKeepRendererBackendFeaturePlaceholderAgnostic = didKeepRendererBackendFeaturePlaceholderAgnostic
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didAvoidConcretePlatformCapabilityPromise = didAvoidConcretePlatformCapabilityPromise
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Constraint profile 只约束 capability facts 的 stop-line；
// 它不是平台适配策略，也不会产生真实 renderer 侧效果。
struct CjguiInternalRendererBackendConstraintProfile {
    let featurePlaceholder: CjguiInternalRendererBackendFeaturePlaceholder
    let didPrepareRendererBackendConstraintProfile: Bool
    let shouldDeferRendererBackendConstraintProfile: Bool
    let shouldReportRendererBackendConstraintProfileBlocked: Bool
    let didPreserveRendererBackendFeaturePlaceholder: Bool
    let didKeepRendererBackendConstraintProfileValueOnly: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didAvoidConcretePlatformCapabilityPromise: Bool
    let didStayFullRebuildOnly: Bool

    init(
        featurePlaceholder: CjguiInternalRendererBackendFeaturePlaceholder,
        didPrepareRendererBackendConstraintProfile: Bool,
        shouldDeferRendererBackendConstraintProfile: Bool,
        shouldReportRendererBackendConstraintProfileBlocked: Bool,
        didPreserveRendererBackendFeaturePlaceholder: Bool,
        didKeepRendererBackendConstraintProfileValueOnly: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didAvoidConcretePlatformCapabilityPromise: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.featurePlaceholder = featurePlaceholder
        this.didPrepareRendererBackendConstraintProfile = didPrepareRendererBackendConstraintProfile
        this.shouldDeferRendererBackendConstraintProfile = shouldDeferRendererBackendConstraintProfile
        this.shouldReportRendererBackendConstraintProfileBlocked = shouldReportRendererBackendConstraintProfileBlocked
        this.didPreserveRendererBackendFeaturePlaceholder = didPreserveRendererBackendFeaturePlaceholder
        this.didKeepRendererBackendConstraintProfileValueOnly = didKeepRendererBackendConstraintProfileValueOnly
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didAvoidConcretePlatformCapabilityPromise = didAvoidConcretePlatformCapabilityPromise
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// No-render capability readiness 是本轮 canonical endpoint；
// readiness 只表示 future backend capability boundary 可以继续评估，不代表允许真实绘制。
struct CjguiInternalRendererBackendNoRenderCapabilityReadiness {
    let constraintProfile: CjguiInternalRendererBackendConstraintProfile
    let isRendererBackendNoRenderCapabilityReady: Bool
    let canFutureRendererBackendCapabilityBoundaryEvaluate: Bool
    let shouldDeferRendererBackendNoRenderCapabilityReadiness: Bool
    let shouldReportRendererBackendNoRenderCapabilityReadinessBlocked: Bool
    let didRecordRendererBackendNoRenderCapabilityReadiness: Bool
    let didPreserveRendererBackendConstraintProfile: Bool
    let didKeepRendererBackendCapabilityReadinessValueOnly: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didAvoidConcretePlatformCapabilityPromise: Bool
    let didStayFullRebuildOnly: Bool

    init(
        constraintProfile: CjguiInternalRendererBackendConstraintProfile,
        isRendererBackendNoRenderCapabilityReady: Bool,
        canFutureRendererBackendCapabilityBoundaryEvaluate: Bool,
        shouldDeferRendererBackendNoRenderCapabilityReadiness: Bool,
        shouldReportRendererBackendNoRenderCapabilityReadinessBlocked: Bool,
        didRecordRendererBackendNoRenderCapabilityReadiness: Bool,
        didPreserveRendererBackendConstraintProfile: Bool,
        didKeepRendererBackendCapabilityReadinessValueOnly: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didAvoidConcretePlatformCapabilityPromise: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.constraintProfile = constraintProfile
        this.isRendererBackendNoRenderCapabilityReady = isRendererBackendNoRenderCapabilityReady
        this.canFutureRendererBackendCapabilityBoundaryEvaluate = canFutureRendererBackendCapabilityBoundaryEvaluate
        this.shouldDeferRendererBackendNoRenderCapabilityReadiness = shouldDeferRendererBackendNoRenderCapabilityReadiness
        this.shouldReportRendererBackendNoRenderCapabilityReadinessBlocked = shouldReportRendererBackendNoRenderCapabilityReadinessBlocked
        this.didRecordRendererBackendNoRenderCapabilityReadiness = didRecordRendererBackendNoRenderCapabilityReadiness
        this.didPreserveRendererBackendConstraintProfile = didPreserveRendererBackendConstraintProfile
        this.didKeepRendererBackendCapabilityReadinessValueOnly = didKeepRendererBackendCapabilityReadinessValueOnly
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didAvoidConcretePlatformCapabilityPromise = didAvoidConcretePlatformCapabilityPromise
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererBackendCapabilityProfile(
    contractReadiness: CjguiInternalRendererBackendNoRenderContractReadiness
): CjguiInternalRendererBackendCapabilityProfile {
    let contractReady = contractReadiness.isRendererBackendNoRenderContractReady &&
        contractReadiness.canFutureRendererBackendContractBoundaryEvaluate &&
        contractReadiness.didRecordRendererBackendNoRenderContractReadiness &&
        contractReadiness.didPreserveRendererAdapterContractAdmission &&
        contractReadiness.didKeepRendererBackendContractReadinessValueOnly &&
        contractReadiness.didAvoidRendererBackendImplementation &&
        contractReadiness.didAvoidPlatformResourceBinding &&
        contractReadiness.didAvoidRendererStateWrite &&
        contractReadiness.didAvoidDrawingSideEffect &&
        contractReadiness.didStayFullRebuildOnly &&
        contractReadiness.shouldDeferRendererBackendNoRenderContractReadiness == false &&
        contractReadiness.shouldReportRendererBackendNoRenderContractReadinessBlocked == false
    let contractDeferred = contractReadiness.isRendererBackendNoRenderContractReady == false &&
        contractReadiness.canFutureRendererBackendContractBoundaryEvaluate == false &&
        contractReadiness.didRecordRendererBackendNoRenderContractReadiness == false &&
        contractReadiness.didPreserveRendererAdapterContractAdmission == false &&
        contractReadiness.didKeepRendererBackendContractReadinessValueOnly &&
        contractReadiness.didAvoidRendererBackendImplementation &&
        contractReadiness.didAvoidPlatformResourceBinding &&
        contractReadiness.didAvoidRendererStateWrite &&
        contractReadiness.didAvoidDrawingSideEffect &&
        contractReadiness.didStayFullRebuildOnly &&
        contractReadiness.shouldDeferRendererBackendNoRenderContractReadiness &&
        contractReadiness.shouldReportRendererBackendNoRenderContractReadinessBlocked == false
    let contractInconsistent = (
        contractReadiness.isRendererBackendNoRenderContractReady &&
            (
                contractReadiness.canFutureRendererBackendContractBoundaryEvaluate == false ||
                contractReadiness.didRecordRendererBackendNoRenderContractReadiness == false ||
                contractReadiness.didPreserveRendererAdapterContractAdmission == false ||
                contractReadiness.didKeepRendererBackendContractReadinessValueOnly == false ||
                contractReadiness.didAvoidRendererBackendImplementation == false ||
                contractReadiness.didAvoidPlatformResourceBinding == false ||
                contractReadiness.didAvoidRendererStateWrite == false ||
                contractReadiness.didAvoidDrawingSideEffect == false ||
                contractReadiness.didStayFullRebuildOnly == false ||
                contractReadiness.shouldDeferRendererBackendNoRenderContractReadiness ||
                contractReadiness.shouldReportRendererBackendNoRenderContractReadinessBlocked
            )
        ) ||
        (contractReadiness.canFutureRendererBackendContractBoundaryEvaluate &&
            contractReadiness.isRendererBackendNoRenderContractReady == false) ||
        (contractReadiness.didRecordRendererBackendNoRenderContractReadiness &&
            contractReadiness.isRendererBackendNoRenderContractReady == false) ||
        (contractReadiness.shouldDeferRendererBackendNoRenderContractReadiness &&
            contractReadiness.shouldReportRendererBackendNoRenderContractReadinessBlocked)

    // contract readiness facts 不一致时必须 fail-closed，不能把 profile 伪造成后端能力承诺。
    if (
        contractReadiness.shouldReportRendererBackendNoRenderContractReadinessBlocked ||
        contractInconsistent
    ) {
        return CjguiInternalRendererBackendCapabilityProfile(
            contractReadiness,
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

    if (contractReady) {
        return CjguiInternalRendererBackendCapabilityProfile(
            contractReadiness,
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

    if (contractDeferred) {
        return CjguiInternalRendererBackendCapabilityProfile(
            contractReadiness,
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

    return CjguiInternalRendererBackendCapabilityProfile(
        contractReadiness,
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

func cjguiInternalBuildRendererBackendFeaturePlaceholder(
    capabilityProfile: CjguiInternalRendererBackendCapabilityProfile
): CjguiInternalRendererBackendFeaturePlaceholder {
    let profileReady = capabilityProfile.didPrepareRendererBackendCapabilityProfile &&
        capabilityProfile.didPreserveRendererBackendContractReadiness &&
        capabilityProfile.didKeepRendererBackendCapabilityProfileAgnostic &&
        capabilityProfile.didAvoidRendererBackendImplementation &&
        capabilityProfile.didAvoidPlatformResourceBinding &&
        capabilityProfile.didAvoidRendererStateWrite &&
        capabilityProfile.didAvoidDrawingSideEffect &&
        capabilityProfile.didAvoidConcretePlatformCapabilityPromise &&
        capabilityProfile.didStayFullRebuildOnly &&
        capabilityProfile.shouldDeferRendererBackendCapabilityProfile == false &&
        capabilityProfile.shouldReportRendererBackendCapabilityProfileBlocked == false
    let profileDeferred = capabilityProfile.didPrepareRendererBackendCapabilityProfile == false &&
        capabilityProfile.didPreserveRendererBackendContractReadiness == false &&
        capabilityProfile.didKeepRendererBackendCapabilityProfileAgnostic &&
        capabilityProfile.didAvoidRendererBackendImplementation &&
        capabilityProfile.didAvoidPlatformResourceBinding &&
        capabilityProfile.didAvoidRendererStateWrite &&
        capabilityProfile.didAvoidDrawingSideEffect &&
        capabilityProfile.didAvoidConcretePlatformCapabilityPromise &&
        capabilityProfile.didStayFullRebuildOnly &&
        capabilityProfile.shouldDeferRendererBackendCapabilityProfile &&
        capabilityProfile.shouldReportRendererBackendCapabilityProfileBlocked == false
    let profileInconsistent = (
        capabilityProfile.didPrepareRendererBackendCapabilityProfile &&
            (
                capabilityProfile.didPreserveRendererBackendContractReadiness == false ||
                capabilityProfile.didKeepRendererBackendCapabilityProfileAgnostic == false ||
                capabilityProfile.didAvoidRendererBackendImplementation == false ||
                capabilityProfile.didAvoidPlatformResourceBinding == false ||
                capabilityProfile.didAvoidRendererStateWrite == false ||
                capabilityProfile.didAvoidDrawingSideEffect == false ||
                capabilityProfile.didAvoidConcretePlatformCapabilityPromise == false ||
                capabilityProfile.didStayFullRebuildOnly == false ||
                capabilityProfile.shouldDeferRendererBackendCapabilityProfile ||
                capabilityProfile.shouldReportRendererBackendCapabilityProfileBlocked
            )
        ) ||
        (capabilityProfile.didPreserveRendererBackendContractReadiness &&
            capabilityProfile.didPrepareRendererBackendCapabilityProfile == false) ||
        (capabilityProfile.shouldDeferRendererBackendCapabilityProfile &&
            capabilityProfile.shouldReportRendererBackendCapabilityProfileBlocked)

    // profile facts 不一致时必须 fail-closed，feature placeholder 不能变成具体能力承诺。
    if (
        capabilityProfile.shouldReportRendererBackendCapabilityProfileBlocked ||
        profileInconsistent
    ) {
        return CjguiInternalRendererBackendFeaturePlaceholder(
            capabilityProfile,
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

    if (profileReady) {
        return CjguiInternalRendererBackendFeaturePlaceholder(
            capabilityProfile,
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

    if (profileDeferred) {
        return CjguiInternalRendererBackendFeaturePlaceholder(
            capabilityProfile,
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

    return CjguiInternalRendererBackendFeaturePlaceholder(
        capabilityProfile,
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

func cjguiInternalBuildRendererBackendConstraintProfile(
    featurePlaceholder: CjguiInternalRendererBackendFeaturePlaceholder
): CjguiInternalRendererBackendConstraintProfile {
    let placeholderReady = featurePlaceholder.didPrepareRendererBackendFeaturePlaceholder &&
        featurePlaceholder.didPreserveRendererBackendCapabilityProfile &&
        featurePlaceholder.didKeepRendererBackendFeaturePlaceholderAgnostic &&
        featurePlaceholder.didAvoidRendererBackendImplementation &&
        featurePlaceholder.didAvoidPlatformResourceBinding &&
        featurePlaceholder.didAvoidRendererStateWrite &&
        featurePlaceholder.didAvoidDrawingSideEffect &&
        featurePlaceholder.didAvoidConcretePlatformCapabilityPromise &&
        featurePlaceholder.didStayFullRebuildOnly &&
        featurePlaceholder.shouldDeferRendererBackendFeaturePlaceholder == false &&
        featurePlaceholder.shouldReportRendererBackendFeaturePlaceholderBlocked == false
    let placeholderDeferred = featurePlaceholder.didPrepareRendererBackendFeaturePlaceholder == false &&
        featurePlaceholder.didPreserveRendererBackendCapabilityProfile == false &&
        featurePlaceholder.didKeepRendererBackendFeaturePlaceholderAgnostic &&
        featurePlaceholder.didAvoidRendererBackendImplementation &&
        featurePlaceholder.didAvoidPlatformResourceBinding &&
        featurePlaceholder.didAvoidRendererStateWrite &&
        featurePlaceholder.didAvoidDrawingSideEffect &&
        featurePlaceholder.didAvoidConcretePlatformCapabilityPromise &&
        featurePlaceholder.didStayFullRebuildOnly &&
        featurePlaceholder.shouldDeferRendererBackendFeaturePlaceholder &&
        featurePlaceholder.shouldReportRendererBackendFeaturePlaceholderBlocked == false
    let placeholderInconsistent = (
        featurePlaceholder.didPrepareRendererBackendFeaturePlaceholder &&
            (
                featurePlaceholder.didPreserveRendererBackendCapabilityProfile == false ||
                featurePlaceholder.didKeepRendererBackendFeaturePlaceholderAgnostic == false ||
                featurePlaceholder.didAvoidRendererBackendImplementation == false ||
                featurePlaceholder.didAvoidPlatformResourceBinding == false ||
                featurePlaceholder.didAvoidRendererStateWrite == false ||
                featurePlaceholder.didAvoidDrawingSideEffect == false ||
                featurePlaceholder.didAvoidConcretePlatformCapabilityPromise == false ||
                featurePlaceholder.didStayFullRebuildOnly == false ||
                featurePlaceholder.shouldDeferRendererBackendFeaturePlaceholder ||
                featurePlaceholder.shouldReportRendererBackendFeaturePlaceholderBlocked
            )
        ) ||
        (featurePlaceholder.didPreserveRendererBackendCapabilityProfile &&
            featurePlaceholder.didPrepareRendererBackendFeaturePlaceholder == false) ||
        (featurePlaceholder.shouldDeferRendererBackendFeaturePlaceholder &&
            featurePlaceholder.shouldReportRendererBackendFeaturePlaceholderBlocked)

    // placeholder facts 不一致时必须 fail-closed，constraint profile 只能保留 value stop-line。
    if (
        featurePlaceholder.shouldReportRendererBackendFeaturePlaceholderBlocked ||
        placeholderInconsistent
    ) {
        return CjguiInternalRendererBackendConstraintProfile(
            featurePlaceholder,
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

    if (placeholderReady) {
        return CjguiInternalRendererBackendConstraintProfile(
            featurePlaceholder,
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

    if (placeholderDeferred) {
        return CjguiInternalRendererBackendConstraintProfile(
            featurePlaceholder,
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

    return CjguiInternalRendererBackendConstraintProfile(
        featurePlaceholder,
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

func cjguiInternalBuildRendererBackendNoRenderCapabilityReadiness(
    constraintProfile: CjguiInternalRendererBackendConstraintProfile
): CjguiInternalRendererBackendNoRenderCapabilityReadiness {
    let constraintReady = constraintProfile.didPrepareRendererBackendConstraintProfile &&
        constraintProfile.didPreserveRendererBackendFeaturePlaceholder &&
        constraintProfile.didKeepRendererBackendConstraintProfileValueOnly &&
        constraintProfile.didAvoidRendererBackendImplementation &&
        constraintProfile.didAvoidPlatformResourceBinding &&
        constraintProfile.didAvoidRendererStateWrite &&
        constraintProfile.didAvoidDrawingSideEffect &&
        constraintProfile.didAvoidConcretePlatformCapabilityPromise &&
        constraintProfile.didStayFullRebuildOnly &&
        constraintProfile.shouldDeferRendererBackendConstraintProfile == false &&
        constraintProfile.shouldReportRendererBackendConstraintProfileBlocked == false
    let constraintDeferred = constraintProfile.didPrepareRendererBackendConstraintProfile == false &&
        constraintProfile.didPreserveRendererBackendFeaturePlaceholder == false &&
        constraintProfile.didKeepRendererBackendConstraintProfileValueOnly &&
        constraintProfile.didAvoidRendererBackendImplementation &&
        constraintProfile.didAvoidPlatformResourceBinding &&
        constraintProfile.didAvoidRendererStateWrite &&
        constraintProfile.didAvoidDrawingSideEffect &&
        constraintProfile.didAvoidConcretePlatformCapabilityPromise &&
        constraintProfile.didStayFullRebuildOnly &&
        constraintProfile.shouldDeferRendererBackendConstraintProfile &&
        constraintProfile.shouldReportRendererBackendConstraintProfileBlocked == false
    let constraintInconsistent = (
        constraintProfile.didPrepareRendererBackendConstraintProfile &&
            (
                constraintProfile.didPreserveRendererBackendFeaturePlaceholder == false ||
                constraintProfile.didKeepRendererBackendConstraintProfileValueOnly == false ||
                constraintProfile.didAvoidRendererBackendImplementation == false ||
                constraintProfile.didAvoidPlatformResourceBinding == false ||
                constraintProfile.didAvoidRendererStateWrite == false ||
                constraintProfile.didAvoidDrawingSideEffect == false ||
                constraintProfile.didAvoidConcretePlatformCapabilityPromise == false ||
                constraintProfile.didStayFullRebuildOnly == false ||
                constraintProfile.shouldDeferRendererBackendConstraintProfile ||
                constraintProfile.shouldReportRendererBackendConstraintProfileBlocked
            )
        ) ||
        (constraintProfile.didPreserveRendererBackendFeaturePlaceholder &&
            constraintProfile.didPrepareRendererBackendConstraintProfile == false) ||
        (constraintProfile.shouldDeferRendererBackendConstraintProfile &&
            constraintProfile.shouldReportRendererBackendConstraintProfileBlocked)

    // constraint facts 不一致时必须 fail-closed，no-render capability readiness 不能变成真实绘制许可。
    if (
        constraintProfile.shouldReportRendererBackendConstraintProfileBlocked ||
        constraintInconsistent
    ) {
        return CjguiInternalRendererBackendNoRenderCapabilityReadiness(
            constraintProfile,
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

    if (constraintReady) {
        return CjguiInternalRendererBackendNoRenderCapabilityReadiness(
            constraintProfile,
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

    if (constraintDeferred) {
        return CjguiInternalRendererBackendNoRenderCapabilityReadiness(
            constraintProfile,
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

    return CjguiInternalRendererBackendNoRenderCapabilityReadiness(
        constraintProfile,
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

func cjguiInternalExecuteDefaultRendererBackendCapabilityDraft(): CjguiInternalRendererBackendNoRenderCapabilityReadiness {
    // 默认 draft 只串联 backend capability profile 前置 value facts；
    // 它不执行平台后端、不触发真实绘制，也不写 renderer state。
    let contractReadiness = cjguiInternalExecuteDefaultRendererBackendContractDraft()
    let capabilityProfile = cjguiInternalBuildRendererBackendCapabilityProfile(contractReadiness)
    let featurePlaceholder = cjguiInternalBuildRendererBackendFeaturePlaceholder(capabilityProfile)
    let constraintProfile = cjguiInternalBuildRendererBackendConstraintProfile(featurePlaceholder)
    return cjguiInternalBuildRendererBackendNoRenderCapabilityReadiness(constraintProfile)
}

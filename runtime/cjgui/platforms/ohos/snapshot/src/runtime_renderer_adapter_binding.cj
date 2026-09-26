package cjgui

// Internal Renderer Adapter Binding value owner:
// - 本文件只消费 CjguiInternalRendererNoRenderSelectionReadiness。
// - Truth 是 adapter binding intent、binding candidate、binding admission 与 no-render binding readiness 的内部 value facts。
// - Stop-line: 这里只描述 future binding 边界是否可继续评估；
//   不绑定具体平台 adapter、不创建图形执行资源、不触发真实绘制、不写 renderer state，
//   不做真实合批或增量渲染，也不回塞 critical runtime_state.cj。

// Adapter binding intent 只说明 selection readiness 可以进入绑定意图前置评估；
// 它不是具体平台 adapter 绑定，也不是 renderer 侧效果许可。
struct CjguiInternalRendererAdapterBindingIntent {
    let selectionReadiness: CjguiInternalRendererNoRenderSelectionReadiness
    let didPrepareRendererAdapterBindingIntent: Bool
    let shouldDeferRendererAdapterBindingIntent: Bool
    let shouldReportRendererAdapterBindingIntentBlocked: Bool
    let didPreserveRendererAdapterSelectionReadiness: Bool
    let didKeepRendererAdapterBindingIntentAgnostic: Bool
    let didAvoidConcreteRendererAdapterBinding: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        selectionReadiness: CjguiInternalRendererNoRenderSelectionReadiness,
        didPrepareRendererAdapterBindingIntent: Bool,
        shouldDeferRendererAdapterBindingIntent: Bool,
        shouldReportRendererAdapterBindingIntentBlocked: Bool,
        didPreserveRendererAdapterSelectionReadiness: Bool,
        didKeepRendererAdapterBindingIntentAgnostic: Bool,
        didAvoidConcreteRendererAdapterBinding: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.selectionReadiness = selectionReadiness
        this.didPrepareRendererAdapterBindingIntent = didPrepareRendererAdapterBindingIntent
        this.shouldDeferRendererAdapterBindingIntent = shouldDeferRendererAdapterBindingIntent
        this.shouldReportRendererAdapterBindingIntentBlocked = shouldReportRendererAdapterBindingIntentBlocked
        this.didPreserveRendererAdapterSelectionReadiness = didPreserveRendererAdapterSelectionReadiness
        this.didKeepRendererAdapterBindingIntentAgnostic = didKeepRendererAdapterBindingIntentAgnostic
        this.didAvoidConcreteRendererAdapterBinding = didAvoidConcreteRendererAdapterBinding
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Adapter binding candidate 只记录后端无关的绑定候选 facts；
// 它不承诺具体平台对象引用，也不触发真实 renderer 行为。
struct CjguiInternalRendererAdapterBindingCandidate {
    let bindingIntent: CjguiInternalRendererAdapterBindingIntent
    let didPrepareRendererAdapterBindingCandidate: Bool
    let shouldDeferRendererAdapterBindingCandidate: Bool
    let shouldReportRendererAdapterBindingCandidateBlocked: Bool
    let didPreserveRendererAdapterBindingIntent: Bool
    let didKeepRendererAdapterBindingCandidateAgnostic: Bool
    let didAvoidConcreteRendererAdapterBinding: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        bindingIntent: CjguiInternalRendererAdapterBindingIntent,
        didPrepareRendererAdapterBindingCandidate: Bool,
        shouldDeferRendererAdapterBindingCandidate: Bool,
        shouldReportRendererAdapterBindingCandidateBlocked: Bool,
        didPreserveRendererAdapterBindingIntent: Bool,
        didKeepRendererAdapterBindingCandidateAgnostic: Bool,
        didAvoidConcreteRendererAdapterBinding: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.bindingIntent = bindingIntent
        this.didPrepareRendererAdapterBindingCandidate = didPrepareRendererAdapterBindingCandidate
        this.shouldDeferRendererAdapterBindingCandidate = shouldDeferRendererAdapterBindingCandidate
        this.shouldReportRendererAdapterBindingCandidateBlocked = shouldReportRendererAdapterBindingCandidateBlocked
        this.didPreserveRendererAdapterBindingIntent = didPreserveRendererAdapterBindingIntent
        this.didKeepRendererAdapterBindingCandidateAgnostic = didKeepRendererAdapterBindingCandidateAgnostic
        this.didAvoidConcreteRendererAdapterBinding = didAvoidConcreteRendererAdapterBinding
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Adapter binding admission 只表达绑定边界准入 facts；
// 它不是具体 adapter 绑定，也不会产生真实绘制侧效果。
struct CjguiInternalRendererAdapterBindingAdmission {
    let bindingCandidate: CjguiInternalRendererAdapterBindingCandidate
    let didAdmitRendererAdapterBinding: Bool
    let shouldDeferRendererAdapterBindingAdmission: Bool
    let shouldReportRendererAdapterBindingAdmissionBlocked: Bool
    let didPreserveRendererAdapterBindingCandidate: Bool
    let didKeepRendererAdapterBindingAdmissionValueOnly: Bool
    let didAvoidConcreteRendererAdapterBinding: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        bindingCandidate: CjguiInternalRendererAdapterBindingCandidate,
        didAdmitRendererAdapterBinding: Bool,
        shouldDeferRendererAdapterBindingAdmission: Bool,
        shouldReportRendererAdapterBindingAdmissionBlocked: Bool,
        didPreserveRendererAdapterBindingCandidate: Bool,
        didKeepRendererAdapterBindingAdmissionValueOnly: Bool,
        didAvoidConcreteRendererAdapterBinding: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.bindingCandidate = bindingCandidate
        this.didAdmitRendererAdapterBinding = didAdmitRendererAdapterBinding
        this.shouldDeferRendererAdapterBindingAdmission = shouldDeferRendererAdapterBindingAdmission
        this.shouldReportRendererAdapterBindingAdmissionBlocked = shouldReportRendererAdapterBindingAdmissionBlocked
        this.didPreserveRendererAdapterBindingCandidate = didPreserveRendererAdapterBindingCandidate
        this.didKeepRendererAdapterBindingAdmissionValueOnly = didKeepRendererAdapterBindingAdmissionValueOnly
        this.didAvoidConcreteRendererAdapterBinding = didAvoidConcreteRendererAdapterBinding
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// No-render binding readiness 是本轮 canonical endpoint；
// readiness 只表示 future adapter binding boundary 可以继续评估，不代表允许真实绘制。
struct CjguiInternalRendererNoRenderBindingReadiness {
    let bindingAdmission: CjguiInternalRendererAdapterBindingAdmission
    let isRendererNoRenderBindingReady: Bool
    let canFutureRendererAdapterBindingBoundaryEvaluate: Bool
    let shouldDeferRendererNoRenderBindingReadiness: Bool
    let shouldReportRendererNoRenderBindingReadinessBlocked: Bool
    let didRecordRendererNoRenderBindingReadiness: Bool
    let didPreserveRendererAdapterBindingAdmission: Bool
    let didKeepRendererAdapterBindingReadinessValueOnly: Bool
    let didAvoidConcreteRendererAdapterBinding: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidPlatformResourceBinding: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        bindingAdmission: CjguiInternalRendererAdapterBindingAdmission,
        isRendererNoRenderBindingReady: Bool,
        canFutureRendererAdapterBindingBoundaryEvaluate: Bool,
        shouldDeferRendererNoRenderBindingReadiness: Bool,
        shouldReportRendererNoRenderBindingReadinessBlocked: Bool,
        didRecordRendererNoRenderBindingReadiness: Bool,
        didPreserveRendererAdapterBindingAdmission: Bool,
        didKeepRendererAdapterBindingReadinessValueOnly: Bool,
        didAvoidConcreteRendererAdapterBinding: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidPlatformResourceBinding: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.bindingAdmission = bindingAdmission
        this.isRendererNoRenderBindingReady = isRendererNoRenderBindingReady
        this.canFutureRendererAdapterBindingBoundaryEvaluate = canFutureRendererAdapterBindingBoundaryEvaluate
        this.shouldDeferRendererNoRenderBindingReadiness = shouldDeferRendererNoRenderBindingReadiness
        this.shouldReportRendererNoRenderBindingReadinessBlocked = shouldReportRendererNoRenderBindingReadinessBlocked
        this.didRecordRendererNoRenderBindingReadiness = didRecordRendererNoRenderBindingReadiness
        this.didPreserveRendererAdapterBindingAdmission = didPreserveRendererAdapterBindingAdmission
        this.didKeepRendererAdapterBindingReadinessValueOnly = didKeepRendererAdapterBindingReadinessValueOnly
        this.didAvoidConcreteRendererAdapterBinding = didAvoidConcreteRendererAdapterBinding
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidPlatformResourceBinding = didAvoidPlatformResourceBinding
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererAdapterBindingIntent(
    selectionReadiness: CjguiInternalRendererNoRenderSelectionReadiness
): CjguiInternalRendererAdapterBindingIntent {
    let selectionReady = selectionReadiness.isRendererNoRenderSelectionReady &&
        selectionReadiness.canFutureRendererAdapterSelectionBoundaryEvaluate &&
        selectionReadiness.didRecordRendererNoRenderSelectionReadiness &&
        selectionReadiness.didPreserveRendererAdapterSelectionAdmission &&
        selectionReadiness.didKeepRendererAdapterSelectionReadinessValueOnly &&
        selectionReadiness.didAvoidConcreteRendererAdapterChoice &&
        selectionReadiness.didAvoidRendererBackendImplementation &&
        selectionReadiness.didAvoidPlatformResourceBinding &&
        selectionReadiness.didAvoidRendererStateWrite &&
        selectionReadiness.didAvoidDrawingSideEffect &&
        selectionReadiness.didStayFullRebuildOnly &&
        selectionReadiness.shouldDeferRendererNoRenderSelectionReadiness == false &&
        selectionReadiness.shouldReportRendererNoRenderSelectionReadinessBlocked == false
    let selectionDeferred = selectionReadiness.isRendererNoRenderSelectionReady == false &&
        selectionReadiness.canFutureRendererAdapterSelectionBoundaryEvaluate == false &&
        selectionReadiness.didRecordRendererNoRenderSelectionReadiness == false &&
        selectionReadiness.didPreserveRendererAdapterSelectionAdmission == false &&
        selectionReadiness.didKeepRendererAdapterSelectionReadinessValueOnly &&
        selectionReadiness.didAvoidConcreteRendererAdapterChoice &&
        selectionReadiness.didAvoidRendererBackendImplementation &&
        selectionReadiness.didAvoidPlatformResourceBinding &&
        selectionReadiness.didAvoidRendererStateWrite &&
        selectionReadiness.didAvoidDrawingSideEffect &&
        selectionReadiness.didStayFullRebuildOnly &&
        selectionReadiness.shouldDeferRendererNoRenderSelectionReadiness &&
        selectionReadiness.shouldReportRendererNoRenderSelectionReadinessBlocked == false
    let selectionInconsistent = (
        selectionReadiness.isRendererNoRenderSelectionReady &&
            (
                selectionReadiness.canFutureRendererAdapterSelectionBoundaryEvaluate == false ||
                selectionReadiness.didRecordRendererNoRenderSelectionReadiness == false ||
                selectionReadiness.didPreserveRendererAdapterSelectionAdmission == false ||
                selectionReadiness.didKeepRendererAdapterSelectionReadinessValueOnly == false ||
                selectionReadiness.didAvoidConcreteRendererAdapterChoice == false ||
                selectionReadiness.didAvoidRendererBackendImplementation == false ||
                selectionReadiness.didAvoidPlatformResourceBinding == false ||
                selectionReadiness.didAvoidRendererStateWrite == false ||
                selectionReadiness.didAvoidDrawingSideEffect == false ||
                selectionReadiness.didStayFullRebuildOnly == false ||
                selectionReadiness.shouldDeferRendererNoRenderSelectionReadiness ||
                selectionReadiness.shouldReportRendererNoRenderSelectionReadinessBlocked
            )
        ) ||
        (selectionReadiness.canFutureRendererAdapterSelectionBoundaryEvaluate &&
            selectionReadiness.isRendererNoRenderSelectionReady == false) ||
        (selectionReadiness.didRecordRendererNoRenderSelectionReadiness &&
            selectionReadiness.isRendererNoRenderSelectionReady == false) ||
        (selectionReadiness.shouldDeferRendererNoRenderSelectionReadiness &&
            selectionReadiness.shouldReportRendererNoRenderSelectionReadinessBlocked)

    // selection readiness facts 不一致时必须 fail-closed，不能把 binding intent 伪造成真实 adapter 绑定。
    if (
        selectionReadiness.shouldReportRendererNoRenderSelectionReadinessBlocked ||
        selectionInconsistent
    ) {
        return CjguiInternalRendererAdapterBindingIntent(
            selectionReadiness,
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

    if (selectionReady) {
        return CjguiInternalRendererAdapterBindingIntent(
            selectionReadiness,
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

    if (selectionDeferred) {
        return CjguiInternalRendererAdapterBindingIntent(
            selectionReadiness,
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

    return CjguiInternalRendererAdapterBindingIntent(
        selectionReadiness,
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

func cjguiInternalBuildRendererAdapterBindingCandidate(
    bindingIntent: CjguiInternalRendererAdapterBindingIntent
): CjguiInternalRendererAdapterBindingCandidate {
    let intentReady = bindingIntent.didPrepareRendererAdapterBindingIntent &&
        bindingIntent.didPreserveRendererAdapterSelectionReadiness &&
        bindingIntent.didKeepRendererAdapterBindingIntentAgnostic &&
        bindingIntent.didAvoidConcreteRendererAdapterBinding &&
        bindingIntent.didAvoidRendererBackendImplementation &&
        bindingIntent.didAvoidPlatformResourceBinding &&
        bindingIntent.didAvoidRendererStateWrite &&
        bindingIntent.didAvoidDrawingSideEffect &&
        bindingIntent.didStayFullRebuildOnly &&
        bindingIntent.shouldDeferRendererAdapterBindingIntent == false &&
        bindingIntent.shouldReportRendererAdapterBindingIntentBlocked == false
    let intentDeferred = bindingIntent.didPrepareRendererAdapterBindingIntent == false &&
        bindingIntent.didPreserveRendererAdapterSelectionReadiness == false &&
        bindingIntent.didKeepRendererAdapterBindingIntentAgnostic &&
        bindingIntent.didAvoidConcreteRendererAdapterBinding &&
        bindingIntent.didAvoidRendererBackendImplementation &&
        bindingIntent.didAvoidPlatformResourceBinding &&
        bindingIntent.didAvoidRendererStateWrite &&
        bindingIntent.didAvoidDrawingSideEffect &&
        bindingIntent.didStayFullRebuildOnly &&
        bindingIntent.shouldDeferRendererAdapterBindingIntent &&
        bindingIntent.shouldReportRendererAdapterBindingIntentBlocked == false
    let intentInconsistent = (
        bindingIntent.didPrepareRendererAdapterBindingIntent &&
            (
                bindingIntent.didPreserveRendererAdapterSelectionReadiness == false ||
                bindingIntent.didKeepRendererAdapterBindingIntentAgnostic == false ||
                bindingIntent.didAvoidConcreteRendererAdapterBinding == false ||
                bindingIntent.didAvoidRendererBackendImplementation == false ||
                bindingIntent.didAvoidPlatformResourceBinding == false ||
                bindingIntent.didAvoidRendererStateWrite == false ||
                bindingIntent.didAvoidDrawingSideEffect == false ||
                bindingIntent.didStayFullRebuildOnly == false ||
                bindingIntent.shouldDeferRendererAdapterBindingIntent ||
                bindingIntent.shouldReportRendererAdapterBindingIntentBlocked
            )
        ) ||
        (bindingIntent.didPreserveRendererAdapterSelectionReadiness &&
            bindingIntent.didPrepareRendererAdapterBindingIntent == false) ||
        (bindingIntent.shouldDeferRendererAdapterBindingIntent &&
            bindingIntent.shouldReportRendererAdapterBindingIntentBlocked)

    // intent facts 不一致时必须 fail-closed，binding candidate 不能变成具体平台对象引用。
    if (
        bindingIntent.shouldReportRendererAdapterBindingIntentBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererAdapterBindingCandidate(
            bindingIntent,
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

    if (intentReady) {
        return CjguiInternalRendererAdapterBindingCandidate(
            bindingIntent,
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

    if (intentDeferred) {
        return CjguiInternalRendererAdapterBindingCandidate(
            bindingIntent,
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

    return CjguiInternalRendererAdapterBindingCandidate(
        bindingIntent,
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

func cjguiInternalBuildRendererAdapterBindingAdmission(
    bindingCandidate: CjguiInternalRendererAdapterBindingCandidate
): CjguiInternalRendererAdapterBindingAdmission {
    let candidateReady = bindingCandidate.didPrepareRendererAdapterBindingCandidate &&
        bindingCandidate.didPreserveRendererAdapterBindingIntent &&
        bindingCandidate.didKeepRendererAdapterBindingCandidateAgnostic &&
        bindingCandidate.didAvoidConcreteRendererAdapterBinding &&
        bindingCandidate.didAvoidRendererBackendImplementation &&
        bindingCandidate.didAvoidPlatformResourceBinding &&
        bindingCandidate.didAvoidRendererStateWrite &&
        bindingCandidate.didAvoidDrawingSideEffect &&
        bindingCandidate.didStayFullRebuildOnly &&
        bindingCandidate.shouldDeferRendererAdapterBindingCandidate == false &&
        bindingCandidate.shouldReportRendererAdapterBindingCandidateBlocked == false
    let candidateDeferred = bindingCandidate.didPrepareRendererAdapterBindingCandidate == false &&
        bindingCandidate.didPreserveRendererAdapterBindingIntent == false &&
        bindingCandidate.didKeepRendererAdapterBindingCandidateAgnostic &&
        bindingCandidate.didAvoidConcreteRendererAdapterBinding &&
        bindingCandidate.didAvoidRendererBackendImplementation &&
        bindingCandidate.didAvoidPlatformResourceBinding &&
        bindingCandidate.didAvoidRendererStateWrite &&
        bindingCandidate.didAvoidDrawingSideEffect &&
        bindingCandidate.didStayFullRebuildOnly &&
        bindingCandidate.shouldDeferRendererAdapterBindingCandidate &&
        bindingCandidate.shouldReportRendererAdapterBindingCandidateBlocked == false
    let candidateInconsistent = (
        bindingCandidate.didPrepareRendererAdapterBindingCandidate &&
            (
                bindingCandidate.didPreserveRendererAdapterBindingIntent == false ||
                bindingCandidate.didKeepRendererAdapterBindingCandidateAgnostic == false ||
                bindingCandidate.didAvoidConcreteRendererAdapterBinding == false ||
                bindingCandidate.didAvoidRendererBackendImplementation == false ||
                bindingCandidate.didAvoidPlatformResourceBinding == false ||
                bindingCandidate.didAvoidRendererStateWrite == false ||
                bindingCandidate.didAvoidDrawingSideEffect == false ||
                bindingCandidate.didStayFullRebuildOnly == false ||
                bindingCandidate.shouldDeferRendererAdapterBindingCandidate ||
                bindingCandidate.shouldReportRendererAdapterBindingCandidateBlocked
            )
        ) ||
        (bindingCandidate.didPreserveRendererAdapterBindingIntent &&
            bindingCandidate.didPrepareRendererAdapterBindingCandidate == false) ||
        (bindingCandidate.shouldDeferRendererAdapterBindingCandidate &&
            bindingCandidate.shouldReportRendererAdapterBindingCandidateBlocked)

    // candidate facts 不一致时必须 fail-closed，binding admission 不能伪造成可执行绑定。
    if (
        bindingCandidate.shouldReportRendererAdapterBindingCandidateBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalRendererAdapterBindingAdmission(
            bindingCandidate,
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

    if (candidateReady) {
        return CjguiInternalRendererAdapterBindingAdmission(
            bindingCandidate,
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

    if (candidateDeferred) {
        return CjguiInternalRendererAdapterBindingAdmission(
            bindingCandidate,
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

    return CjguiInternalRendererAdapterBindingAdmission(
        bindingCandidate,
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

func cjguiInternalBuildRendererNoRenderBindingReadiness(
    bindingAdmission: CjguiInternalRendererAdapterBindingAdmission
): CjguiInternalRendererNoRenderBindingReadiness {
    let admissionReady = bindingAdmission.didAdmitRendererAdapterBinding &&
        bindingAdmission.didPreserveRendererAdapterBindingCandidate &&
        bindingAdmission.didKeepRendererAdapterBindingAdmissionValueOnly &&
        bindingAdmission.didAvoidConcreteRendererAdapterBinding &&
        bindingAdmission.didAvoidRendererBackendImplementation &&
        bindingAdmission.didAvoidPlatformResourceBinding &&
        bindingAdmission.didAvoidRendererStateWrite &&
        bindingAdmission.didAvoidDrawingSideEffect &&
        bindingAdmission.didStayFullRebuildOnly &&
        bindingAdmission.shouldDeferRendererAdapterBindingAdmission == false &&
        bindingAdmission.shouldReportRendererAdapterBindingAdmissionBlocked == false
    let admissionDeferred = bindingAdmission.didAdmitRendererAdapterBinding == false &&
        bindingAdmission.didPreserveRendererAdapterBindingCandidate == false &&
        bindingAdmission.didKeepRendererAdapterBindingAdmissionValueOnly &&
        bindingAdmission.didAvoidConcreteRendererAdapterBinding &&
        bindingAdmission.didAvoidRendererBackendImplementation &&
        bindingAdmission.didAvoidPlatformResourceBinding &&
        bindingAdmission.didAvoidRendererStateWrite &&
        bindingAdmission.didAvoidDrawingSideEffect &&
        bindingAdmission.didStayFullRebuildOnly &&
        bindingAdmission.shouldDeferRendererAdapterBindingAdmission &&
        bindingAdmission.shouldReportRendererAdapterBindingAdmissionBlocked == false
    let admissionInconsistent = (
        bindingAdmission.didAdmitRendererAdapterBinding &&
            (
                bindingAdmission.didPreserveRendererAdapterBindingCandidate == false ||
                bindingAdmission.didKeepRendererAdapterBindingAdmissionValueOnly == false ||
                bindingAdmission.didAvoidConcreteRendererAdapterBinding == false ||
                bindingAdmission.didAvoidRendererBackendImplementation == false ||
                bindingAdmission.didAvoidPlatformResourceBinding == false ||
                bindingAdmission.didAvoidRendererStateWrite == false ||
                bindingAdmission.didAvoidDrawingSideEffect == false ||
                bindingAdmission.didStayFullRebuildOnly == false ||
                bindingAdmission.shouldDeferRendererAdapterBindingAdmission ||
                bindingAdmission.shouldReportRendererAdapterBindingAdmissionBlocked
            )
        ) ||
        (bindingAdmission.didPreserveRendererAdapterBindingCandidate &&
            bindingAdmission.didAdmitRendererAdapterBinding == false) ||
        (bindingAdmission.shouldDeferRendererAdapterBindingAdmission &&
            bindingAdmission.shouldReportRendererAdapterBindingAdmissionBlocked)

    // binding admission facts 不一致时必须 fail-closed，readiness 不能变成真实绘制许可。
    if (
        bindingAdmission.shouldReportRendererAdapterBindingAdmissionBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalRendererNoRenderBindingReadiness(
            bindingAdmission,
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
        return CjguiInternalRendererNoRenderBindingReadiness(
            bindingAdmission,
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
        return CjguiInternalRendererNoRenderBindingReadiness(
            bindingAdmission,
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

    return CjguiInternalRendererNoRenderBindingReadiness(
        bindingAdmission,
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

func cjguiInternalExecuteDefaultRendererAdapterBindingDraft(): CjguiInternalRendererNoRenderBindingReadiness {
    // 默认 draft 只串联 adapter binding 前置 value facts；
    // 它不绑定具体平台 adapter、不触发真实绘制，也不写 renderer state。
    let selectionReadiness = cjguiInternalExecuteDefaultRendererAdapterSelectionDraft()
    let bindingIntent = cjguiInternalBuildRendererAdapterBindingIntent(selectionReadiness)
    let bindingCandidate = cjguiInternalBuildRendererAdapterBindingCandidate(bindingIntent)
    let bindingAdmission = cjguiInternalBuildRendererAdapterBindingAdmission(bindingCandidate)
    return cjguiInternalBuildRendererNoRenderBindingReadiness(bindingAdmission)
}

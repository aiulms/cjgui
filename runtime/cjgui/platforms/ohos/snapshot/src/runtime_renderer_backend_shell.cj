package cjgui

// Internal Renderer Backend Shell value owner:
// - 本文件只消费 CjguiInternalRendererNoRenderBindingReadiness。
// - Truth 是 backend shell intent、shell candidate、shell admission 与 no-render shell readiness 的内部 value facts。
// - Stop-line: 这里只固定 future backend shell 的 owner truth / vocabulary / entry contract；
//   它不是平台 shell，不绑定平台资源，不触发绘制执行，不写 renderer state，
//   不承诺稳定后端接口，也不回塞 critical runtime_state.cj。

// Backend shell intent 只说明 binding readiness 可以进入 shell 入口契约评估；
// Same-shape Boundary Brake 下，它必须携带 owner truth / vocabulary / entry contract，
// 不能只是 lifecycle / receipt / record 的改名包装。
struct CjguiInternalRendererBackendShellIntent {
    let bindingReadiness: CjguiInternalRendererNoRenderBindingReadiness
    let didPrepareRendererBackendShellIntent: Bool
    let shouldDeferRendererBackendShellIntent: Bool
    let shouldReportRendererBackendShellIntentBlocked: Bool
    let didPreserveRendererBackendBindingReadiness: Bool
    let didDefineRendererBackendShellOwnerTruth: Bool
    let didDefineRendererBackendShellVocabulary: Bool
    let didDefineRendererBackendShellEntryContract: Bool
    let didKeepRendererBackendShellInternalValueOnly: Bool
    let didAvoidPlatformShell: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didAvoidStableBackendInterfacePromise: Bool
    let didStayFullRebuildOnly: Bool

    init(
        bindingReadiness: CjguiInternalRendererNoRenderBindingReadiness,
        didPrepareRendererBackendShellIntent: Bool,
        shouldDeferRendererBackendShellIntent: Bool,
        shouldReportRendererBackendShellIntentBlocked: Bool,
        didPreserveRendererBackendBindingReadiness: Bool,
        didDefineRendererBackendShellOwnerTruth: Bool,
        didDefineRendererBackendShellVocabulary: Bool,
        didDefineRendererBackendShellEntryContract: Bool,
        didKeepRendererBackendShellInternalValueOnly: Bool,
        didAvoidPlatformShell: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didAvoidStableBackendInterfacePromise: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.bindingReadiness = bindingReadiness
        this.didPrepareRendererBackendShellIntent = didPrepareRendererBackendShellIntent
        this.shouldDeferRendererBackendShellIntent = shouldDeferRendererBackendShellIntent
        this.shouldReportRendererBackendShellIntentBlocked = shouldReportRendererBackendShellIntentBlocked
        this.didPreserveRendererBackendBindingReadiness = didPreserveRendererBackendBindingReadiness
        this.didDefineRendererBackendShellOwnerTruth = didDefineRendererBackendShellOwnerTruth
        this.didDefineRendererBackendShellVocabulary = didDefineRendererBackendShellVocabulary
        this.didDefineRendererBackendShellEntryContract = didDefineRendererBackendShellEntryContract
        this.didKeepRendererBackendShellInternalValueOnly = didKeepRendererBackendShellInternalValueOnly
        this.didAvoidPlatformShell = didAvoidPlatformShell
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didAvoidStableBackendInterfacePromise = didAvoidStableBackendInterfacePromise
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Backend shell candidate 只记录后端无关的 shell 候选 facts；
// 它不能持有平台对象，也不能代表已经选择或绑定了具体后端。
struct CjguiInternalRendererBackendShellCandidate {
    let shellIntent: CjguiInternalRendererBackendShellIntent
    let didPrepareRendererBackendShellCandidate: Bool
    let shouldDeferRendererBackendShellCandidate: Bool
    let shouldReportRendererBackendShellCandidateBlocked: Bool
    let didPreserveRendererBackendShellIntent: Bool
    let didDefineRendererBackendShellOwnerTruth: Bool
    let didDefineRendererBackendShellVocabulary: Bool
    let didDefineRendererBackendShellEntryContract: Bool
    let didKeepRendererBackendShellCandidateAgnostic: Bool
    let didAvoidPlatformShell: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didAvoidStableBackendInterfacePromise: Bool
    let didStayFullRebuildOnly: Bool

    init(
        shellIntent: CjguiInternalRendererBackendShellIntent,
        didPrepareRendererBackendShellCandidate: Bool,
        shouldDeferRendererBackendShellCandidate: Bool,
        shouldReportRendererBackendShellCandidateBlocked: Bool,
        didPreserveRendererBackendShellIntent: Bool,
        didDefineRendererBackendShellOwnerTruth: Bool,
        didDefineRendererBackendShellVocabulary: Bool,
        didDefineRendererBackendShellEntryContract: Bool,
        didKeepRendererBackendShellCandidateAgnostic: Bool,
        didAvoidPlatformShell: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didAvoidStableBackendInterfacePromise: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.shellIntent = shellIntent
        this.didPrepareRendererBackendShellCandidate = didPrepareRendererBackendShellCandidate
        this.shouldDeferRendererBackendShellCandidate = shouldDeferRendererBackendShellCandidate
        this.shouldReportRendererBackendShellCandidateBlocked = shouldReportRendererBackendShellCandidateBlocked
        this.didPreserveRendererBackendShellIntent = didPreserveRendererBackendShellIntent
        this.didDefineRendererBackendShellOwnerTruth = didDefineRendererBackendShellOwnerTruth
        this.didDefineRendererBackendShellVocabulary = didDefineRendererBackendShellVocabulary
        this.didDefineRendererBackendShellEntryContract = didDefineRendererBackendShellEntryContract
        this.didKeepRendererBackendShellCandidateAgnostic = didKeepRendererBackendShellCandidateAgnostic
        this.didAvoidPlatformShell = didAvoidPlatformShell
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didAvoidStableBackendInterfacePromise = didAvoidStableBackendInterfacePromise
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Backend shell admission 只表达 shell 入口契约是否可准入；
// 它不是平台提交、绘制执行或 renderer state mutation。
struct CjguiInternalRendererBackendShellAdmission {
    let shellCandidate: CjguiInternalRendererBackendShellCandidate
    let didAdmitRendererBackendShell: Bool
    let shouldDeferRendererBackendShellAdmission: Bool
    let shouldReportRendererBackendShellAdmissionBlocked: Bool
    let didPreserveRendererBackendShellCandidate: Bool
    let didDefineRendererBackendShellOwnerTruth: Bool
    let didDefineRendererBackendShellVocabulary: Bool
    let didDefineRendererBackendShellEntryContract: Bool
    let didKeepRendererBackendShellAdmissionValueOnly: Bool
    let didAvoidPlatformShell: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didAvoidStableBackendInterfacePromise: Bool
    let didStayFullRebuildOnly: Bool

    init(
        shellCandidate: CjguiInternalRendererBackendShellCandidate,
        didAdmitRendererBackendShell: Bool,
        shouldDeferRendererBackendShellAdmission: Bool,
        shouldReportRendererBackendShellAdmissionBlocked: Bool,
        didPreserveRendererBackendShellCandidate: Bool,
        didDefineRendererBackendShellOwnerTruth: Bool,
        didDefineRendererBackendShellVocabulary: Bool,
        didDefineRendererBackendShellEntryContract: Bool,
        didKeepRendererBackendShellAdmissionValueOnly: Bool,
        didAvoidPlatformShell: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didAvoidStableBackendInterfacePromise: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.shellCandidate = shellCandidate
        this.didAdmitRendererBackendShell = didAdmitRendererBackendShell
        this.shouldDeferRendererBackendShellAdmission = shouldDeferRendererBackendShellAdmission
        this.shouldReportRendererBackendShellAdmissionBlocked = shouldReportRendererBackendShellAdmissionBlocked
        this.didPreserveRendererBackendShellCandidate = didPreserveRendererBackendShellCandidate
        this.didDefineRendererBackendShellOwnerTruth = didDefineRendererBackendShellOwnerTruth
        this.didDefineRendererBackendShellVocabulary = didDefineRendererBackendShellVocabulary
        this.didDefineRendererBackendShellEntryContract = didDefineRendererBackendShellEntryContract
        this.didKeepRendererBackendShellAdmissionValueOnly = didKeepRendererBackendShellAdmissionValueOnly
        this.didAvoidPlatformShell = didAvoidPlatformShell
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didAvoidStableBackendInterfacePromise = didAvoidStableBackendInterfacePromise
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// No-render shell readiness 是 backend shell 边界的 endpoint；
// readiness 只表示 future shell boundary 可以继续评估，不代表允许绘制或写 renderer state。
struct CjguiInternalRendererBackendNoRenderShellReadiness {
    let shellAdmission: CjguiInternalRendererBackendShellAdmission
    let isRendererBackendNoRenderShellReady: Bool
    let canFutureRendererBackendShellBoundaryEvaluate: Bool
    let shouldDeferRendererBackendNoRenderShellReadiness: Bool
    let shouldReportRendererBackendNoRenderShellReadinessBlocked: Bool
    let didRecordRendererBackendNoRenderShellReadiness: Bool
    let didPreserveRendererBackendShellAdmission: Bool
    let didKeepRendererBackendShellReadinessValueOnly: Bool
    let didDefineRendererBackendShellOwnerTruth: Bool
    let didDefineRendererBackendShellVocabulary: Bool
    let didDefineRendererBackendShellEntryContract: Bool
    let didAvoidPlatformShell: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingSideEffect: Bool
    let didAvoidStableBackendInterfacePromise: Bool
    let didStayFullRebuildOnly: Bool

    init(
        shellAdmission: CjguiInternalRendererBackendShellAdmission,
        isRendererBackendNoRenderShellReady: Bool,
        canFutureRendererBackendShellBoundaryEvaluate: Bool,
        shouldDeferRendererBackendNoRenderShellReadiness: Bool,
        shouldReportRendererBackendNoRenderShellReadinessBlocked: Bool,
        didRecordRendererBackendNoRenderShellReadiness: Bool,
        didPreserveRendererBackendShellAdmission: Bool,
        didKeepRendererBackendShellReadinessValueOnly: Bool,
        didDefineRendererBackendShellOwnerTruth: Bool,
        didDefineRendererBackendShellVocabulary: Bool,
        didDefineRendererBackendShellEntryContract: Bool,
        didAvoidPlatformShell: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingSideEffect: Bool,
        didAvoidStableBackendInterfacePromise: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.shellAdmission = shellAdmission
        this.isRendererBackendNoRenderShellReady = isRendererBackendNoRenderShellReady
        this.canFutureRendererBackendShellBoundaryEvaluate = canFutureRendererBackendShellBoundaryEvaluate
        this.shouldDeferRendererBackendNoRenderShellReadiness = shouldDeferRendererBackendNoRenderShellReadiness
        this.shouldReportRendererBackendNoRenderShellReadinessBlocked = shouldReportRendererBackendNoRenderShellReadinessBlocked
        this.didRecordRendererBackendNoRenderShellReadiness = didRecordRendererBackendNoRenderShellReadiness
        this.didPreserveRendererBackendShellAdmission = didPreserveRendererBackendShellAdmission
        this.didKeepRendererBackendShellReadinessValueOnly = didKeepRendererBackendShellReadinessValueOnly
        this.didDefineRendererBackendShellOwnerTruth = didDefineRendererBackendShellOwnerTruth
        this.didDefineRendererBackendShellVocabulary = didDefineRendererBackendShellVocabulary
        this.didDefineRendererBackendShellEntryContract = didDefineRendererBackendShellEntryContract
        this.didAvoidPlatformShell = didAvoidPlatformShell
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingSideEffect = didAvoidDrawingSideEffect
        this.didAvoidStableBackendInterfacePromise = didAvoidStableBackendInterfacePromise
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererBackendShellIntent(
    bindingReadiness: CjguiInternalRendererNoRenderBindingReadiness
): CjguiInternalRendererBackendShellIntent {
    let bindingReady = bindingReadiness.isRendererNoRenderBindingReady &&
        bindingReadiness.canFutureRendererAdapterBindingBoundaryEvaluate &&
        bindingReadiness.didRecordRendererNoRenderBindingReadiness &&
        bindingReadiness.didPreserveRendererAdapterBindingAdmission &&
        bindingReadiness.didKeepRendererAdapterBindingReadinessValueOnly &&
        bindingReadiness.didAvoidConcreteRendererAdapterBinding &&
        bindingReadiness.didAvoidRendererBackendImplementation &&
        bindingReadiness.didAvoidPlatformResourceBinding &&
        bindingReadiness.didAvoidRendererStateWrite &&
        bindingReadiness.didAvoidDrawingSideEffect &&
        bindingReadiness.didStayFullRebuildOnly &&
        bindingReadiness.shouldDeferRendererNoRenderBindingReadiness == false &&
        bindingReadiness.shouldReportRendererNoRenderBindingReadinessBlocked == false
    let bindingDeferred = bindingReadiness.isRendererNoRenderBindingReady == false &&
        bindingReadiness.canFutureRendererAdapterBindingBoundaryEvaluate == false &&
        bindingReadiness.didRecordRendererNoRenderBindingReadiness == false &&
        bindingReadiness.didPreserveRendererAdapterBindingAdmission == false &&
        bindingReadiness.didKeepRendererAdapterBindingReadinessValueOnly &&
        bindingReadiness.didAvoidConcreteRendererAdapterBinding &&
        bindingReadiness.didAvoidRendererBackendImplementation &&
        bindingReadiness.didAvoidPlatformResourceBinding &&
        bindingReadiness.didAvoidRendererStateWrite &&
        bindingReadiness.didAvoidDrawingSideEffect &&
        bindingReadiness.didStayFullRebuildOnly &&
        bindingReadiness.shouldDeferRendererNoRenderBindingReadiness &&
        bindingReadiness.shouldReportRendererNoRenderBindingReadinessBlocked == false
    let bindingInconsistent = (
        bindingReadiness.isRendererNoRenderBindingReady &&
            (
                bindingReadiness.canFutureRendererAdapterBindingBoundaryEvaluate == false ||
                bindingReadiness.didRecordRendererNoRenderBindingReadiness == false ||
                bindingReadiness.didPreserveRendererAdapterBindingAdmission == false ||
                bindingReadiness.didKeepRendererAdapterBindingReadinessValueOnly == false ||
                bindingReadiness.didAvoidConcreteRendererAdapterBinding == false ||
                bindingReadiness.didAvoidRendererBackendImplementation == false ||
                bindingReadiness.didAvoidPlatformResourceBinding == false ||
                bindingReadiness.didAvoidRendererStateWrite == false ||
                bindingReadiness.didAvoidDrawingSideEffect == false ||
                bindingReadiness.didStayFullRebuildOnly == false ||
                bindingReadiness.shouldDeferRendererNoRenderBindingReadiness ||
                bindingReadiness.shouldReportRendererNoRenderBindingReadinessBlocked
            )
        ) ||
        (bindingReadiness.canFutureRendererAdapterBindingBoundaryEvaluate &&
            bindingReadiness.isRendererNoRenderBindingReady == false) ||
        (bindingReadiness.didRecordRendererNoRenderBindingReadiness &&
            bindingReadiness.isRendererNoRenderBindingReady == false) ||
        (bindingReadiness.shouldDeferRendererNoRenderBindingReadiness &&
            bindingReadiness.shouldReportRendererNoRenderBindingReadinessBlocked)

    // binding readiness facts 不一致时必须 fail-closed；
    // shell intent 不能伪造成平台 shell 或绘制许可。
    if (
        bindingReadiness.shouldReportRendererNoRenderBindingReadinessBlocked ||
        bindingInconsistent
    ) {
        return CjguiInternalRendererBackendShellIntent(
            bindingReadiness,
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
            true,
            true,
            true,
            true
        )
    }

    if (bindingReady) {
        return CjguiInternalRendererBackendShellIntent(
            bindingReadiness,
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
            true,
            true,
            true
        )
    }

    if (bindingDeferred) {
        return CjguiInternalRendererBackendShellIntent(
            bindingReadiness,
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
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererBackendShellIntent(
        bindingReadiness,
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
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererBackendShellCandidate(
    shellIntent: CjguiInternalRendererBackendShellIntent
): CjguiInternalRendererBackendShellCandidate {
    let intentReady = shellIntent.didPrepareRendererBackendShellIntent &&
        shellIntent.didPreserveRendererBackendBindingReadiness &&
        shellIntent.didDefineRendererBackendShellOwnerTruth &&
        shellIntent.didDefineRendererBackendShellVocabulary &&
        shellIntent.didDefineRendererBackendShellEntryContract &&
        shellIntent.didKeepRendererBackendShellInternalValueOnly &&
        shellIntent.didAvoidPlatformShell &&
        shellIntent.didAvoidRendererBackendImplementation &&
        shellIntent.didAvoidRendererStateWrite &&
        shellIntent.didAvoidDrawingSideEffect &&
        shellIntent.didAvoidStableBackendInterfacePromise &&
        shellIntent.didStayFullRebuildOnly &&
        shellIntent.shouldDeferRendererBackendShellIntent == false &&
        shellIntent.shouldReportRendererBackendShellIntentBlocked == false
    let intentDeferred = shellIntent.didPrepareRendererBackendShellIntent == false &&
        shellIntent.didPreserveRendererBackendBindingReadiness == false &&
        shellIntent.didDefineRendererBackendShellOwnerTruth &&
        shellIntent.didDefineRendererBackendShellVocabulary &&
        shellIntent.didDefineRendererBackendShellEntryContract &&
        shellIntent.didKeepRendererBackendShellInternalValueOnly &&
        shellIntent.didAvoidPlatformShell &&
        shellIntent.didAvoidRendererBackendImplementation &&
        shellIntent.didAvoidRendererStateWrite &&
        shellIntent.didAvoidDrawingSideEffect &&
        shellIntent.didAvoidStableBackendInterfacePromise &&
        shellIntent.didStayFullRebuildOnly &&
        shellIntent.shouldDeferRendererBackendShellIntent &&
        shellIntent.shouldReportRendererBackendShellIntentBlocked == false
    let intentInconsistent = (
        shellIntent.didPrepareRendererBackendShellIntent &&
            (
                shellIntent.didPreserveRendererBackendBindingReadiness == false ||
                shellIntent.didDefineRendererBackendShellOwnerTruth == false ||
                shellIntent.didDefineRendererBackendShellVocabulary == false ||
                shellIntent.didDefineRendererBackendShellEntryContract == false ||
                shellIntent.didKeepRendererBackendShellInternalValueOnly == false ||
                shellIntent.didAvoidPlatformShell == false ||
                shellIntent.didAvoidRendererBackendImplementation == false ||
                shellIntent.didAvoidRendererStateWrite == false ||
                shellIntent.didAvoidDrawingSideEffect == false ||
                shellIntent.didAvoidStableBackendInterfacePromise == false ||
                shellIntent.didStayFullRebuildOnly == false ||
                shellIntent.shouldDeferRendererBackendShellIntent ||
                shellIntent.shouldReportRendererBackendShellIntentBlocked
            )
        ) ||
        (shellIntent.didPreserveRendererBackendBindingReadiness &&
            shellIntent.didPrepareRendererBackendShellIntent == false) ||
        (shellIntent.shouldDeferRendererBackendShellIntent &&
            shellIntent.shouldReportRendererBackendShellIntentBlocked)

    // intent facts 不一致时必须 fail-closed；
    // shell candidate 不能退化成 lifecycle / receipt / record wrapper。
    if (
        shellIntent.shouldReportRendererBackendShellIntentBlocked ||
        intentInconsistent
    ) {
        return CjguiInternalRendererBackendShellCandidate(
            shellIntent,
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
            true,
            true,
            true,
            true
        )
    }

    if (intentReady) {
        return CjguiInternalRendererBackendShellCandidate(
            shellIntent,
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
            true,
            true,
            true
        )
    }

    if (intentDeferred) {
        return CjguiInternalRendererBackendShellCandidate(
            shellIntent,
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
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererBackendShellCandidate(
        shellIntent,
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
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererBackendShellAdmission(
    shellCandidate: CjguiInternalRendererBackendShellCandidate
): CjguiInternalRendererBackendShellAdmission {
    let candidateReady = shellCandidate.didPrepareRendererBackendShellCandidate &&
        shellCandidate.didPreserveRendererBackendShellIntent &&
        shellCandidate.didDefineRendererBackendShellOwnerTruth &&
        shellCandidate.didDefineRendererBackendShellVocabulary &&
        shellCandidate.didDefineRendererBackendShellEntryContract &&
        shellCandidate.didKeepRendererBackendShellCandidateAgnostic &&
        shellCandidate.didAvoidPlatformShell &&
        shellCandidate.didAvoidRendererBackendImplementation &&
        shellCandidate.didAvoidRendererStateWrite &&
        shellCandidate.didAvoidDrawingSideEffect &&
        shellCandidate.didAvoidStableBackendInterfacePromise &&
        shellCandidate.didStayFullRebuildOnly &&
        shellCandidate.shouldDeferRendererBackendShellCandidate == false &&
        shellCandidate.shouldReportRendererBackendShellCandidateBlocked == false
    let candidateDeferred = shellCandidate.didPrepareRendererBackendShellCandidate == false &&
        shellCandidate.didPreserveRendererBackendShellIntent == false &&
        shellCandidate.didDefineRendererBackendShellOwnerTruth &&
        shellCandidate.didDefineRendererBackendShellVocabulary &&
        shellCandidate.didDefineRendererBackendShellEntryContract &&
        shellCandidate.didKeepRendererBackendShellCandidateAgnostic &&
        shellCandidate.didAvoidPlatformShell &&
        shellCandidate.didAvoidRendererBackendImplementation &&
        shellCandidate.didAvoidRendererStateWrite &&
        shellCandidate.didAvoidDrawingSideEffect &&
        shellCandidate.didAvoidStableBackendInterfacePromise &&
        shellCandidate.didStayFullRebuildOnly &&
        shellCandidate.shouldDeferRendererBackendShellCandidate &&
        shellCandidate.shouldReportRendererBackendShellCandidateBlocked == false
    let candidateInconsistent = (
        shellCandidate.didPrepareRendererBackendShellCandidate &&
            (
                shellCandidate.didPreserveRendererBackendShellIntent == false ||
                shellCandidate.didDefineRendererBackendShellOwnerTruth == false ||
                shellCandidate.didDefineRendererBackendShellVocabulary == false ||
                shellCandidate.didDefineRendererBackendShellEntryContract == false ||
                shellCandidate.didKeepRendererBackendShellCandidateAgnostic == false ||
                shellCandidate.didAvoidPlatformShell == false ||
                shellCandidate.didAvoidRendererBackendImplementation == false ||
                shellCandidate.didAvoidRendererStateWrite == false ||
                shellCandidate.didAvoidDrawingSideEffect == false ||
                shellCandidate.didAvoidStableBackendInterfacePromise == false ||
                shellCandidate.didStayFullRebuildOnly == false ||
                shellCandidate.shouldDeferRendererBackendShellCandidate ||
                shellCandidate.shouldReportRendererBackendShellCandidateBlocked
            )
        ) ||
        (shellCandidate.didPreserveRendererBackendShellIntent &&
            shellCandidate.didPrepareRendererBackendShellCandidate == false) ||
        (shellCandidate.shouldDeferRendererBackendShellCandidate &&
            shellCandidate.shouldReportRendererBackendShellCandidateBlocked)

    // candidate facts 不一致时必须 fail-closed；
    // shell admission 不能被解释成真实后端可用。
    if (
        shellCandidate.shouldReportRendererBackendShellCandidateBlocked ||
        candidateInconsistent
    ) {
        return CjguiInternalRendererBackendShellAdmission(
            shellCandidate,
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
            true,
            true,
            true,
            true
        )
    }

    if (candidateReady) {
        return CjguiInternalRendererBackendShellAdmission(
            shellCandidate,
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
            true,
            true,
            true
        )
    }

    if (candidateDeferred) {
        return CjguiInternalRendererBackendShellAdmission(
            shellCandidate,
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
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererBackendShellAdmission(
        shellCandidate,
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
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererBackendNoRenderShellReadiness(
    shellAdmission: CjguiInternalRendererBackendShellAdmission
): CjguiInternalRendererBackendNoRenderShellReadiness {
    let admissionReady = shellAdmission.didAdmitRendererBackendShell &&
        shellAdmission.didPreserveRendererBackendShellCandidate &&
        shellAdmission.didDefineRendererBackendShellOwnerTruth &&
        shellAdmission.didDefineRendererBackendShellVocabulary &&
        shellAdmission.didDefineRendererBackendShellEntryContract &&
        shellAdmission.didKeepRendererBackendShellAdmissionValueOnly &&
        shellAdmission.didAvoidPlatformShell &&
        shellAdmission.didAvoidRendererBackendImplementation &&
        shellAdmission.didAvoidRendererStateWrite &&
        shellAdmission.didAvoidDrawingSideEffect &&
        shellAdmission.didAvoidStableBackendInterfacePromise &&
        shellAdmission.didStayFullRebuildOnly &&
        shellAdmission.shouldDeferRendererBackendShellAdmission == false &&
        shellAdmission.shouldReportRendererBackendShellAdmissionBlocked == false
    let admissionDeferred = shellAdmission.didAdmitRendererBackendShell == false &&
        shellAdmission.didPreserveRendererBackendShellCandidate == false &&
        shellAdmission.didDefineRendererBackendShellOwnerTruth &&
        shellAdmission.didDefineRendererBackendShellVocabulary &&
        shellAdmission.didDefineRendererBackendShellEntryContract &&
        shellAdmission.didKeepRendererBackendShellAdmissionValueOnly &&
        shellAdmission.didAvoidPlatformShell &&
        shellAdmission.didAvoidRendererBackendImplementation &&
        shellAdmission.didAvoidRendererStateWrite &&
        shellAdmission.didAvoidDrawingSideEffect &&
        shellAdmission.didAvoidStableBackendInterfacePromise &&
        shellAdmission.didStayFullRebuildOnly &&
        shellAdmission.shouldDeferRendererBackendShellAdmission &&
        shellAdmission.shouldReportRendererBackendShellAdmissionBlocked == false
    let admissionInconsistent = (
        shellAdmission.didAdmitRendererBackendShell &&
            (
                shellAdmission.didPreserveRendererBackendShellCandidate == false ||
                shellAdmission.didDefineRendererBackendShellOwnerTruth == false ||
                shellAdmission.didDefineRendererBackendShellVocabulary == false ||
                shellAdmission.didDefineRendererBackendShellEntryContract == false ||
                shellAdmission.didKeepRendererBackendShellAdmissionValueOnly == false ||
                shellAdmission.didAvoidPlatformShell == false ||
                shellAdmission.didAvoidRendererBackendImplementation == false ||
                shellAdmission.didAvoidRendererStateWrite == false ||
                shellAdmission.didAvoidDrawingSideEffect == false ||
                shellAdmission.didAvoidStableBackendInterfacePromise == false ||
                shellAdmission.didStayFullRebuildOnly == false ||
                shellAdmission.shouldDeferRendererBackendShellAdmission ||
                shellAdmission.shouldReportRendererBackendShellAdmissionBlocked
            )
        ) ||
        (shellAdmission.didPreserveRendererBackendShellCandidate &&
            shellAdmission.didAdmitRendererBackendShell == false) ||
        (shellAdmission.shouldDeferRendererBackendShellAdmission &&
            shellAdmission.shouldReportRendererBackendShellAdmissionBlocked)

    // shell admission facts 不一致时必须 fail-closed；
    // readiness 只能说明 future shell boundary 可继续评估，不能伪造成绘制许可。
    if (
        shellAdmission.shouldReportRendererBackendShellAdmissionBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalRendererBackendNoRenderShellReadiness(
            shellAdmission,
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
            true,
            true,
            true,
            true
        )
    }

    if (admissionReady) {
        return CjguiInternalRendererBackendNoRenderShellReadiness(
            shellAdmission,
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
            true,
            true,
            true,
            true
        )
    }

    if (admissionDeferred) {
        return CjguiInternalRendererBackendNoRenderShellReadiness(
            shellAdmission,
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
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererBackendNoRenderShellReadiness(
        shellAdmission,
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
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererBackendShellDraft(): CjguiInternalRendererBackendNoRenderShellReadiness {
    // 默认 draft 只串联 backend shell value facts；
    // 它用于固定 shell owner truth / vocabulary / entry contract，不触发真实后端行为或绘制执行。
    let bindingReadiness = cjguiInternalExecuteDefaultRendererAdapterBindingDraft()
    let shellIntent = cjguiInternalBuildRendererBackendShellIntent(bindingReadiness)
    let shellCandidate = cjguiInternalBuildRendererBackendShellCandidate(shellIntent)
    let shellAdmission = cjguiInternalBuildRendererBackendShellAdmission(shellCandidate)
    return cjguiInternalBuildRendererBackendNoRenderShellReadiness(shellAdmission)
}

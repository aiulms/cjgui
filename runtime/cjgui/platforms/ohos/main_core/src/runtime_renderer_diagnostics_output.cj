package cjgui

// Owner: Renderer diagnostics output admission boundary.
// Truth: 只消费 no-output readiness，产出通道策略、隐私准入、产物护栏、no-write readiness facts。
// Stop-line: 不写外部介质、不写控制台、不发外部信号、不保留外部诊断产物。
// Same-shape Boundary Brake: 本 owner 新增 output-channel / privacy / artifact / no-write 语义，
// 不是把 no-output readiness 再包成 receipt / record / 发布形态。

// Output sink intent 只固定 future output runway 的内部准入意图；
// 它不启动真实输出，也不收集原始 payload。
struct CjguiInternalRendererDiagnosticsOutputSinkIntent {
    let noOutputReadiness: CjguiInternalRendererDiagnosticsNoOutputReadiness
    let didPrepareRendererDiagnosticsOutputSinkIntent: Bool
    let isRendererDiagnosticsOutputSinkIntentOpen: Bool
    let shouldDeferRendererDiagnosticsOutputSinkIntent: Bool
    let shouldReportRendererDiagnosticsOutputSinkIntentBlocked: Bool
    let didPreserveRendererDiagnosticsNoOutputReadiness: Bool
    let didPreserveOutputChannelVocabulary: Bool
    let didPreserveNoWriteBoundary: Bool
    let didUseDehydratedDiagnosticFacts: Bool
    let didAvoidOriginalPayloadCapture: Bool
    let didKeepOutputSinkIntentInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalDiagnosticStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        noOutputReadiness: CjguiInternalRendererDiagnosticsNoOutputReadiness,
        didPrepareRendererDiagnosticsOutputSinkIntent: Bool,
        isRendererDiagnosticsOutputSinkIntentOpen: Bool,
        shouldDeferRendererDiagnosticsOutputSinkIntent: Bool,
        shouldReportRendererDiagnosticsOutputSinkIntentBlocked: Bool,
        didPreserveRendererDiagnosticsNoOutputReadiness: Bool,
        didPreserveOutputChannelVocabulary: Bool,
        didPreserveNoWriteBoundary: Bool,
        didUseDehydratedDiagnosticFacts: Bool,
        didAvoidOriginalPayloadCapture: Bool,
        didKeepOutputSinkIntentInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalDiagnosticStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.noOutputReadiness = noOutputReadiness
        this.didPrepareRendererDiagnosticsOutputSinkIntent =
            didPrepareRendererDiagnosticsOutputSinkIntent
        this.isRendererDiagnosticsOutputSinkIntentOpen =
            isRendererDiagnosticsOutputSinkIntentOpen
        this.shouldDeferRendererDiagnosticsOutputSinkIntent =
            shouldDeferRendererDiagnosticsOutputSinkIntent
        this.shouldReportRendererDiagnosticsOutputSinkIntentBlocked =
            shouldReportRendererDiagnosticsOutputSinkIntentBlocked
        this.didPreserveRendererDiagnosticsNoOutputReadiness =
            didPreserveRendererDiagnosticsNoOutputReadiness
        this.didPreserveOutputChannelVocabulary = didPreserveOutputChannelVocabulary
        this.didPreserveNoWriteBoundary = didPreserveNoWriteBoundary
        this.didUseDehydratedDiagnosticFacts = didUseDehydratedDiagnosticFacts
        this.didAvoidOriginalPayloadCapture = didAvoidOriginalPayloadCapture
        this.didKeepOutputSinkIntentInternalOnly = didKeepOutputSinkIntentInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidConsoleWrite = didAvoidConsoleWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalDiagnosticStore = didAvoidExternalDiagnosticStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Output channel policy 只描述 future channel 的 value-style 策略；
// 它不是通道实现，也不会执行写入动作。
struct CjguiInternalRendererDiagnosticsOutputChannelPolicy {
    let intent: CjguiInternalRendererDiagnosticsOutputSinkIntent
    let didPrepareRendererDiagnosticsOutputChannelPolicy: Bool
    let isRendererDiagnosticsOutputChannelNoWrite: Bool
    let shouldDeferRendererDiagnosticsOutputChannelPolicy: Bool
    let shouldReportRendererDiagnosticsOutputChannelPolicyBlocked: Bool
    let didPreserveRendererDiagnosticsOutputSinkIntent: Bool
    let didKeepOutputChannelAsPolicyOnly: Bool
    let didPreservePrivacyAdmissionBoundary: Bool
    let didPreserveArtifactGuardBoundary: Bool
    let didKeepOutputChannelPolicyInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalDiagnosticStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        intent: CjguiInternalRendererDiagnosticsOutputSinkIntent,
        didPrepareRendererDiagnosticsOutputChannelPolicy: Bool,
        isRendererDiagnosticsOutputChannelNoWrite: Bool,
        shouldDeferRendererDiagnosticsOutputChannelPolicy: Bool,
        shouldReportRendererDiagnosticsOutputChannelPolicyBlocked: Bool,
        didPreserveRendererDiagnosticsOutputSinkIntent: Bool,
        didKeepOutputChannelAsPolicyOnly: Bool,
        didPreservePrivacyAdmissionBoundary: Bool,
        didPreserveArtifactGuardBoundary: Bool,
        didKeepOutputChannelPolicyInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalDiagnosticStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.intent = intent
        this.didPrepareRendererDiagnosticsOutputChannelPolicy =
            didPrepareRendererDiagnosticsOutputChannelPolicy
        this.isRendererDiagnosticsOutputChannelNoWrite =
            isRendererDiagnosticsOutputChannelNoWrite
        this.shouldDeferRendererDiagnosticsOutputChannelPolicy =
            shouldDeferRendererDiagnosticsOutputChannelPolicy
        this.shouldReportRendererDiagnosticsOutputChannelPolicyBlocked =
            shouldReportRendererDiagnosticsOutputChannelPolicyBlocked
        this.didPreserveRendererDiagnosticsOutputSinkIntent =
            didPreserveRendererDiagnosticsOutputSinkIntent
        this.didKeepOutputChannelAsPolicyOnly = didKeepOutputChannelAsPolicyOnly
        this.didPreservePrivacyAdmissionBoundary = didPreservePrivacyAdmissionBoundary
        this.didPreserveArtifactGuardBoundary = didPreserveArtifactGuardBoundary
        this.didKeepOutputChannelPolicyInternalOnly =
            didKeepOutputChannelPolicyInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidConsoleWrite = didAvoidConsoleWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalDiagnosticStore = didAvoidExternalDiagnosticStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Privacy admission 只允许脱水后的 diagnostic facts 穿过边界；
// 它拒绝原始 payload，也不把内部 evidence 暴露到外部。
struct CjguiInternalRendererDiagnosticsPrivacyAdmission {
    let channelPolicy: CjguiInternalRendererDiagnosticsOutputChannelPolicy
    let didPrepareRendererDiagnosticsPrivacyAdmission: Bool
    let isRendererDiagnosticsPrivacyAdmissionSatisfied: Bool
    let shouldDeferRendererDiagnosticsPrivacyAdmission: Bool
    let shouldReportRendererDiagnosticsPrivacyAdmissionBlocked: Bool
    let didPreserveRendererDiagnosticsOutputChannelPolicy: Bool
    let didUseDehydratedDiagnosticFacts: Bool
    let didAvoidOriginalPayloadCapture: Bool
    let didAvoidExternalEvidenceExposure: Bool
    let didKeepPrivacyAdmissionInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalDiagnosticStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        channelPolicy: CjguiInternalRendererDiagnosticsOutputChannelPolicy,
        didPrepareRendererDiagnosticsPrivacyAdmission: Bool,
        isRendererDiagnosticsPrivacyAdmissionSatisfied: Bool,
        shouldDeferRendererDiagnosticsPrivacyAdmission: Bool,
        shouldReportRendererDiagnosticsPrivacyAdmissionBlocked: Bool,
        didPreserveRendererDiagnosticsOutputChannelPolicy: Bool,
        didUseDehydratedDiagnosticFacts: Bool,
        didAvoidOriginalPayloadCapture: Bool,
        didAvoidExternalEvidenceExposure: Bool,
        didKeepPrivacyAdmissionInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalDiagnosticStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.channelPolicy = channelPolicy
        this.didPrepareRendererDiagnosticsPrivacyAdmission =
            didPrepareRendererDiagnosticsPrivacyAdmission
        this.isRendererDiagnosticsPrivacyAdmissionSatisfied =
            isRendererDiagnosticsPrivacyAdmissionSatisfied
        this.shouldDeferRendererDiagnosticsPrivacyAdmission =
            shouldDeferRendererDiagnosticsPrivacyAdmission
        this.shouldReportRendererDiagnosticsPrivacyAdmissionBlocked =
            shouldReportRendererDiagnosticsPrivacyAdmissionBlocked
        this.didPreserveRendererDiagnosticsOutputChannelPolicy =
            didPreserveRendererDiagnosticsOutputChannelPolicy
        this.didUseDehydratedDiagnosticFacts = didUseDehydratedDiagnosticFacts
        this.didAvoidOriginalPayloadCapture = didAvoidOriginalPayloadCapture
        this.didAvoidExternalEvidenceExposure = didAvoidExternalEvidenceExposure
        this.didKeepPrivacyAdmissionInternalOnly = didKeepPrivacyAdmissionInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidConsoleWrite = didAvoidConsoleWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalDiagnosticStore = didAvoidExternalDiagnosticStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Artifact guard 只表达“不保留外部诊断产物”的 value facts；
// 它不创建外部存储，也不延长任何输出生命周期。
struct CjguiInternalRendererDiagnosticsArtifactGuard {
    let privacyAdmission: CjguiInternalRendererDiagnosticsPrivacyAdmission
    let didPrepareRendererDiagnosticsArtifactGuard: Bool
    let isRendererDiagnosticsArtifactGuardNoExternalStore: Bool
    let shouldDeferRendererDiagnosticsArtifactGuard: Bool
    let shouldReportRendererDiagnosticsArtifactGuardBlocked: Bool
    let didPreserveRendererDiagnosticsPrivacyAdmission: Bool
    let didKeepArtifactGuardInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalDiagnosticStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        privacyAdmission: CjguiInternalRendererDiagnosticsPrivacyAdmission,
        didPrepareRendererDiagnosticsArtifactGuard: Bool,
        isRendererDiagnosticsArtifactGuardNoExternalStore: Bool,
        shouldDeferRendererDiagnosticsArtifactGuard: Bool,
        shouldReportRendererDiagnosticsArtifactGuardBlocked: Bool,
        didPreserveRendererDiagnosticsPrivacyAdmission: Bool,
        didKeepArtifactGuardInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalDiagnosticStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.privacyAdmission = privacyAdmission
        this.didPrepareRendererDiagnosticsArtifactGuard =
            didPrepareRendererDiagnosticsArtifactGuard
        this.isRendererDiagnosticsArtifactGuardNoExternalStore =
            isRendererDiagnosticsArtifactGuardNoExternalStore
        this.shouldDeferRendererDiagnosticsArtifactGuard =
            shouldDeferRendererDiagnosticsArtifactGuard
        this.shouldReportRendererDiagnosticsArtifactGuardBlocked =
            shouldReportRendererDiagnosticsArtifactGuardBlocked
        this.didPreserveRendererDiagnosticsPrivacyAdmission =
            didPreserveRendererDiagnosticsPrivacyAdmission
        this.didKeepArtifactGuardInternalOnly = didKeepArtifactGuardInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidConsoleWrite = didAvoidConsoleWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalDiagnosticStore = didAvoidExternalDiagnosticStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// No-write readiness 是本 owner 的 canonical endpoint；
// ready 只表示 future output admission boundary 可继续评估，不代表允许真实写入。
struct CjguiInternalRendererDiagnosticsNoWriteReadiness {
    let artifactGuard: CjguiInternalRendererDiagnosticsArtifactGuard
    let isRendererDiagnosticsNoWriteReady: Bool
    let canFutureRendererBoundaryUseDiagnosticsOutputAdmission: Bool
    let shouldDeferRendererDiagnosticsNoWriteReadiness: Bool
    let shouldReportRendererDiagnosticsNoWriteReadinessBlocked: Bool
    let didPrepareRendererDiagnosticsNoWriteReadiness: Bool
    let didPreserveRendererDiagnosticsArtifactGuard: Bool
    let didPreserveOutputChannelPolicy: Bool
    let didPreservePrivacyAdmission: Bool
    let didPreserveNoExternalStoreGuard: Bool
    let didKeepDiagnosticsOutputAdmissionInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalDiagnosticStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        artifactGuard: CjguiInternalRendererDiagnosticsArtifactGuard,
        isRendererDiagnosticsNoWriteReady: Bool,
        canFutureRendererBoundaryUseDiagnosticsOutputAdmission: Bool,
        shouldDeferRendererDiagnosticsNoWriteReadiness: Bool,
        shouldReportRendererDiagnosticsNoWriteReadinessBlocked: Bool,
        didPrepareRendererDiagnosticsNoWriteReadiness: Bool,
        didPreserveRendererDiagnosticsArtifactGuard: Bool,
        didPreserveOutputChannelPolicy: Bool,
        didPreservePrivacyAdmission: Bool,
        didPreserveNoExternalStoreGuard: Bool,
        didKeepDiagnosticsOutputAdmissionInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalDiagnosticStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.artifactGuard = artifactGuard
        this.isRendererDiagnosticsNoWriteReady = isRendererDiagnosticsNoWriteReady
        this.canFutureRendererBoundaryUseDiagnosticsOutputAdmission =
            canFutureRendererBoundaryUseDiagnosticsOutputAdmission
        this.shouldDeferRendererDiagnosticsNoWriteReadiness =
            shouldDeferRendererDiagnosticsNoWriteReadiness
        this.shouldReportRendererDiagnosticsNoWriteReadinessBlocked =
            shouldReportRendererDiagnosticsNoWriteReadinessBlocked
        this.didPrepareRendererDiagnosticsNoWriteReadiness =
            didPrepareRendererDiagnosticsNoWriteReadiness
        this.didPreserveRendererDiagnosticsArtifactGuard =
            didPreserveRendererDiagnosticsArtifactGuard
        this.didPreserveOutputChannelPolicy = didPreserveOutputChannelPolicy
        this.didPreservePrivacyAdmission = didPreservePrivacyAdmission
        this.didPreserveNoExternalStoreGuard = didPreserveNoExternalStoreGuard
        this.didKeepDiagnosticsOutputAdmissionInternalOnly =
            didKeepDiagnosticsOutputAdmissionInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidConsoleWrite = didAvoidConsoleWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalDiagnosticStore = didAvoidExternalDiagnosticStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererDiagnosticsOutputSinkIntent(
    noOutputReadiness: CjguiInternalRendererDiagnosticsNoOutputReadiness
): CjguiInternalRendererDiagnosticsOutputSinkIntent {
    let noOutputReady = noOutputReadiness.isRendererDiagnosticsNoOutputReady &&
        noOutputReadiness.canFutureRendererBoundaryUseDiagnosticsSinkPolicy &&
        noOutputReadiness.didPrepareRendererDiagnosticsNoOutputReadiness &&
        noOutputReadiness.didPreserveRendererDiagnosticsLifecycleGuard &&
        noOutputReadiness.didKeepDiagnosticsSinkPolicyInternalOnly &&
        noOutputReadiness.didUseDehydratedDiagnosticFacts &&
        noOutputReadiness.didAvoidOriginalPayloadCapture &&
        noOutputReadiness.didAvoidExternalDiagnosticWrite &&
        noOutputReadiness.didAvoidStandardOutputWrite &&
        noOutputReadiness.didAvoidStandardErrorWrite &&
        noOutputReadiness.didAvoidExternalSignal &&
        noOutputReadiness.didAvoidExternalDiagnosticStore &&
        noOutputReadiness.didAvoidRuntimeSideEffect &&
        noOutputReadiness.didAvoidRendererStateWrite &&
        noOutputReadiness.didAvoidDrawingPermission &&
        noOutputReadiness.didStayFullRebuildOnly &&
        noOutputReadiness.shouldDeferRendererDiagnosticsNoOutputReadiness == false &&
        noOutputReadiness.shouldReportRendererDiagnosticsNoOutputReadinessBlocked == false
    let noOutputDeferred = noOutputReadiness.isRendererDiagnosticsNoOutputReady == false &&
        noOutputReadiness.canFutureRendererBoundaryUseDiagnosticsSinkPolicy == false &&
        noOutputReadiness.shouldDeferRendererDiagnosticsNoOutputReadiness &&
        noOutputReadiness.shouldReportRendererDiagnosticsNoOutputReadinessBlocked == false &&
        noOutputReadiness.didKeepDiagnosticsSinkPolicyInternalOnly &&
        noOutputReadiness.didAvoidExternalDiagnosticWrite &&
        noOutputReadiness.didAvoidStandardOutputWrite &&
        noOutputReadiness.didAvoidStandardErrorWrite &&
        noOutputReadiness.didAvoidExternalSignal &&
        noOutputReadiness.didAvoidExternalDiagnosticStore &&
        noOutputReadiness.didAvoidRuntimeSideEffect &&
        noOutputReadiness.didAvoidRendererStateWrite &&
        noOutputReadiness.didAvoidDrawingPermission &&
        noOutputReadiness.didStayFullRebuildOnly
    let noOutputInconsistent = (
        noOutputReadiness.isRendererDiagnosticsNoOutputReady &&
            (
                noOutputReadiness.canFutureRendererBoundaryUseDiagnosticsSinkPolicy == false ||
                noOutputReadiness.didPrepareRendererDiagnosticsNoOutputReadiness == false ||
                noOutputReadiness.didPreserveRendererDiagnosticsLifecycleGuard == false ||
                noOutputReadiness.didKeepDiagnosticsSinkPolicyInternalOnly == false ||
                noOutputReadiness.didUseDehydratedDiagnosticFacts == false ||
                noOutputReadiness.didAvoidOriginalPayloadCapture == false ||
                noOutputReadiness.didAvoidExternalDiagnosticWrite == false ||
                noOutputReadiness.didAvoidStandardOutputWrite == false ||
                noOutputReadiness.didAvoidStandardErrorWrite == false ||
                noOutputReadiness.didAvoidExternalSignal == false ||
                noOutputReadiness.didAvoidExternalDiagnosticStore == false ||
                noOutputReadiness.didAvoidRuntimeSideEffect == false ||
                noOutputReadiness.didAvoidRendererStateWrite == false ||
                noOutputReadiness.didAvoidDrawingPermission == false ||
                noOutputReadiness.didStayFullRebuildOnly == false ||
                noOutputReadiness.shouldDeferRendererDiagnosticsNoOutputReadiness ||
                noOutputReadiness.shouldReportRendererDiagnosticsNoOutputReadinessBlocked
            )
        ) ||
        (
            noOutputReadiness.canFutureRendererBoundaryUseDiagnosticsSinkPolicy &&
                noOutputReadiness.isRendererDiagnosticsNoOutputReady == false
        ) ||
        (
            noOutputReadiness.shouldDeferRendererDiagnosticsNoOutputReadiness &&
                noOutputReadiness.shouldReportRendererDiagnosticsNoOutputReadinessBlocked
        )

    // no-output readiness 阻塞或不一致时，output intent 必须 fail-closed，不能伪造成可写。
    if (
        noOutputReadiness.shouldReportRendererDiagnosticsNoOutputReadinessBlocked ||
        noOutputInconsistent
    ) {
        return CjguiInternalRendererDiagnosticsOutputSinkIntent(
            noOutputReadiness,
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
            true,
            true,
            true,
            true
        )
    }

    if (noOutputReady) {
        return CjguiInternalRendererDiagnosticsOutputSinkIntent(
            noOutputReadiness,
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
            true,
            true,
            true
        )
    }

    if (noOutputDeferred) {
        return CjguiInternalRendererDiagnosticsOutputSinkIntent(
            noOutputReadiness,
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
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererDiagnosticsOutputSinkIntent(
        noOutputReadiness,
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
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererDiagnosticsOutputChannelPolicy(
    intent: CjguiInternalRendererDiagnosticsOutputSinkIntent
): CjguiInternalRendererDiagnosticsOutputChannelPolicy {
    let intentReady = intent.didPrepareRendererDiagnosticsOutputSinkIntent &&
        intent.isRendererDiagnosticsOutputSinkIntentOpen &&
        intent.didPreserveRendererDiagnosticsNoOutputReadiness &&
        intent.didPreserveOutputChannelVocabulary &&
        intent.didPreserveNoWriteBoundary &&
        intent.didUseDehydratedDiagnosticFacts &&
        intent.didAvoidOriginalPayloadCapture &&
        intent.didKeepOutputSinkIntentInternalOnly &&
        intent.didAvoidExternalDiagnosticWrite &&
        intent.didAvoidConsoleWrite &&
        intent.didAvoidExternalSignal &&
        intent.didAvoidExternalDiagnosticStore &&
        intent.didAvoidRuntimeSideEffect &&
        intent.didAvoidRendererStateWrite &&
        intent.didAvoidDrawingPermission &&
        intent.didStayFullRebuildOnly &&
        intent.shouldDeferRendererDiagnosticsOutputSinkIntent == false &&
        intent.shouldReportRendererDiagnosticsOutputSinkIntentBlocked == false
    let intentDeferred = intent.didPrepareRendererDiagnosticsOutputSinkIntent == false &&
        intent.shouldDeferRendererDiagnosticsOutputSinkIntent &&
        intent.shouldReportRendererDiagnosticsOutputSinkIntentBlocked == false
    let intentBlocked = intent.shouldReportRendererDiagnosticsOutputSinkIntentBlocked ||
        (
            intent.didPrepareRendererDiagnosticsOutputSinkIntent &&
                intent.isRendererDiagnosticsOutputSinkIntentOpen == false &&
                intent.shouldDeferRendererDiagnosticsOutputSinkIntent == false
        )
    let intentInconsistent = (
        intent.didPrepareRendererDiagnosticsOutputSinkIntent &&
            (
                intent.didPreserveRendererDiagnosticsNoOutputReadiness == false ||
                intent.didPreserveOutputChannelVocabulary == false ||
                intent.didPreserveNoWriteBoundary == false ||
                intent.didUseDehydratedDiagnosticFacts == false ||
                intent.didAvoidOriginalPayloadCapture == false ||
                intent.didKeepOutputSinkIntentInternalOnly == false ||
                intent.didAvoidExternalDiagnosticWrite == false ||
                intent.didAvoidConsoleWrite == false ||
                intent.didAvoidExternalSignal == false ||
                intent.didAvoidExternalDiagnosticStore == false ||
                intent.didAvoidRuntimeSideEffect == false ||
                intent.didAvoidRendererStateWrite == false ||
                intent.didAvoidDrawingPermission == false ||
                intent.didStayFullRebuildOnly == false ||
                intent.shouldDeferRendererDiagnosticsOutputSinkIntent
            )
        ) ||
        (
            intent.shouldDeferRendererDiagnosticsOutputSinkIntent &&
                intent.shouldReportRendererDiagnosticsOutputSinkIntentBlocked
        )

    // output intent 阻塞或不一致时，channel policy 只能保持 no-write facts。
    if (intentBlocked || intentInconsistent) {
        return CjguiInternalRendererDiagnosticsOutputChannelPolicy(
            intent,
            true,
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
            true,
            true,
            true,
            true,
            true
        )
    }

    if (intentReady) {
        return CjguiInternalRendererDiagnosticsOutputChannelPolicy(
            intent,
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
            true,
            true
        )
    }

    if (intentDeferred) {
        return CjguiInternalRendererDiagnosticsOutputChannelPolicy(
            intent,
            false,
            true,
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
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererDiagnosticsOutputChannelPolicy(
        intent,
        true,
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
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererDiagnosticsPrivacyAdmission(
    channelPolicy: CjguiInternalRendererDiagnosticsOutputChannelPolicy
): CjguiInternalRendererDiagnosticsPrivacyAdmission {
    let channelReady = channelPolicy.didPrepareRendererDiagnosticsOutputChannelPolicy &&
        channelPolicy.isRendererDiagnosticsOutputChannelNoWrite &&
        channelPolicy.didPreserveRendererDiagnosticsOutputSinkIntent &&
        channelPolicy.didKeepOutputChannelAsPolicyOnly &&
        channelPolicy.didPreservePrivacyAdmissionBoundary &&
        channelPolicy.didPreserveArtifactGuardBoundary &&
        channelPolicy.didKeepOutputChannelPolicyInternalOnly &&
        channelPolicy.didAvoidExternalDiagnosticWrite &&
        channelPolicy.didAvoidConsoleWrite &&
        channelPolicy.didAvoidExternalSignal &&
        channelPolicy.didAvoidExternalDiagnosticStore &&
        channelPolicy.didAvoidRuntimeSideEffect &&
        channelPolicy.didAvoidRendererStateWrite &&
        channelPolicy.didAvoidDrawingPermission &&
        channelPolicy.didStayFullRebuildOnly &&
        channelPolicy.shouldDeferRendererDiagnosticsOutputChannelPolicy == false &&
        channelPolicy.shouldReportRendererDiagnosticsOutputChannelPolicyBlocked == false
    let channelDeferred =
        channelPolicy.didPrepareRendererDiagnosticsOutputChannelPolicy == false &&
        channelPolicy.shouldDeferRendererDiagnosticsOutputChannelPolicy &&
        channelPolicy.shouldReportRendererDiagnosticsOutputChannelPolicyBlocked == false
    let channelBlocked =
        channelPolicy.shouldReportRendererDiagnosticsOutputChannelPolicyBlocked ||
        (
            channelPolicy.didPrepareRendererDiagnosticsOutputChannelPolicy &&
                channelPolicy.isRendererDiagnosticsOutputChannelNoWrite == false &&
                channelPolicy.shouldDeferRendererDiagnosticsOutputChannelPolicy == false
        )
    let channelInconsistent = (
        channelPolicy.didPrepareRendererDiagnosticsOutputChannelPolicy &&
            (
                channelPolicy.didPreserveRendererDiagnosticsOutputSinkIntent == false ||
                channelPolicy.didKeepOutputChannelAsPolicyOnly == false ||
                channelPolicy.didPreservePrivacyAdmissionBoundary == false ||
                channelPolicy.didPreserveArtifactGuardBoundary == false ||
                channelPolicy.didKeepOutputChannelPolicyInternalOnly == false ||
                channelPolicy.didAvoidExternalDiagnosticWrite == false ||
                channelPolicy.didAvoidConsoleWrite == false ||
                channelPolicy.didAvoidExternalSignal == false ||
                channelPolicy.didAvoidExternalDiagnosticStore == false ||
                channelPolicy.didAvoidRuntimeSideEffect == false ||
                channelPolicy.didAvoidRendererStateWrite == false ||
                channelPolicy.didAvoidDrawingPermission == false ||
                channelPolicy.didStayFullRebuildOnly == false ||
                channelPolicy.shouldDeferRendererDiagnosticsOutputChannelPolicy
            )
        ) ||
        (
            channelPolicy.shouldDeferRendererDiagnosticsOutputChannelPolicy &&
                channelPolicy.shouldReportRendererDiagnosticsOutputChannelPolicyBlocked
        )

    // channel policy 阻塞或不一致时，privacy admission 拒绝原始 payload。
    if (channelBlocked || channelInconsistent) {
        return CjguiInternalRendererDiagnosticsPrivacyAdmission(
            channelPolicy,
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
            true,
            true,
            true
        )
    }

    if (channelReady) {
        return CjguiInternalRendererDiagnosticsPrivacyAdmission(
            channelPolicy,
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
            true,
            true
        )
    }

    if (channelDeferred) {
        return CjguiInternalRendererDiagnosticsPrivacyAdmission(
            channelPolicy,
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
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererDiagnosticsPrivacyAdmission(
        channelPolicy,
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
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererDiagnosticsArtifactGuard(
    privacyAdmission: CjguiInternalRendererDiagnosticsPrivacyAdmission
): CjguiInternalRendererDiagnosticsArtifactGuard {
    let privacyReady = privacyAdmission.didPrepareRendererDiagnosticsPrivacyAdmission &&
        privacyAdmission.isRendererDiagnosticsPrivacyAdmissionSatisfied &&
        privacyAdmission.didPreserveRendererDiagnosticsOutputChannelPolicy &&
        privacyAdmission.didUseDehydratedDiagnosticFacts &&
        privacyAdmission.didAvoidOriginalPayloadCapture &&
        privacyAdmission.didAvoidExternalEvidenceExposure &&
        privacyAdmission.didKeepPrivacyAdmissionInternalOnly &&
        privacyAdmission.didAvoidExternalDiagnosticWrite &&
        privacyAdmission.didAvoidConsoleWrite &&
        privacyAdmission.didAvoidExternalSignal &&
        privacyAdmission.didAvoidExternalDiagnosticStore &&
        privacyAdmission.didAvoidRuntimeSideEffect &&
        privacyAdmission.didAvoidRendererStateWrite &&
        privacyAdmission.didAvoidDrawingPermission &&
        privacyAdmission.didStayFullRebuildOnly &&
        privacyAdmission.shouldDeferRendererDiagnosticsPrivacyAdmission == false &&
        privacyAdmission.shouldReportRendererDiagnosticsPrivacyAdmissionBlocked == false
    let privacyDeferred = privacyAdmission.didPrepareRendererDiagnosticsPrivacyAdmission ==
        false &&
        privacyAdmission.shouldDeferRendererDiagnosticsPrivacyAdmission &&
        privacyAdmission.shouldReportRendererDiagnosticsPrivacyAdmissionBlocked == false
    let privacyBlocked =
        privacyAdmission.shouldReportRendererDiagnosticsPrivacyAdmissionBlocked ||
        (
            privacyAdmission.didPrepareRendererDiagnosticsPrivacyAdmission &&
                privacyAdmission.isRendererDiagnosticsPrivacyAdmissionSatisfied == false &&
                privacyAdmission.shouldDeferRendererDiagnosticsPrivacyAdmission == false
        )
    let privacyInconsistent = (
        privacyAdmission.didPrepareRendererDiagnosticsPrivacyAdmission &&
            (
                privacyAdmission.didPreserveRendererDiagnosticsOutputChannelPolicy == false ||
                privacyAdmission.didUseDehydratedDiagnosticFacts == false ||
                privacyAdmission.didAvoidOriginalPayloadCapture == false ||
                privacyAdmission.didAvoidExternalEvidenceExposure == false ||
                privacyAdmission.didKeepPrivacyAdmissionInternalOnly == false ||
                privacyAdmission.didAvoidExternalDiagnosticWrite == false ||
                privacyAdmission.didAvoidConsoleWrite == false ||
                privacyAdmission.didAvoidExternalSignal == false ||
                privacyAdmission.didAvoidExternalDiagnosticStore == false ||
                privacyAdmission.didAvoidRuntimeSideEffect == false ||
                privacyAdmission.didAvoidRendererStateWrite == false ||
                privacyAdmission.didAvoidDrawingPermission == false ||
                privacyAdmission.didStayFullRebuildOnly == false ||
                privacyAdmission.shouldDeferRendererDiagnosticsPrivacyAdmission
            )
        ) ||
        (
            privacyAdmission.shouldDeferRendererDiagnosticsPrivacyAdmission &&
                privacyAdmission.shouldReportRendererDiagnosticsPrivacyAdmissionBlocked
        )

    // privacy admission 阻塞或不一致时，artifact guard 禁止外部诊断存储。
    if (privacyBlocked || privacyInconsistent) {
        return CjguiInternalRendererDiagnosticsArtifactGuard(
            privacyAdmission,
            true,
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
            true,
            true
        )
    }

    if (privacyReady) {
        return CjguiInternalRendererDiagnosticsArtifactGuard(
            privacyAdmission,
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
            true
        )
    }

    if (privacyDeferred) {
        return CjguiInternalRendererDiagnosticsArtifactGuard(
            privacyAdmission,
            false,
            true,
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

    return CjguiInternalRendererDiagnosticsArtifactGuard(
        privacyAdmission,
        true,
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
        true,
        true
    )
}

func cjguiInternalBuildRendererDiagnosticsNoWriteReadiness(
    artifactGuard: CjguiInternalRendererDiagnosticsArtifactGuard
): CjguiInternalRendererDiagnosticsNoWriteReadiness {
    let artifactReady = artifactGuard.didPrepareRendererDiagnosticsArtifactGuard &&
        artifactGuard.isRendererDiagnosticsArtifactGuardNoExternalStore &&
        artifactGuard.didPreserveRendererDiagnosticsPrivacyAdmission &&
        artifactGuard.didKeepArtifactGuardInternalOnly &&
        artifactGuard.didAvoidExternalDiagnosticWrite &&
        artifactGuard.didAvoidConsoleWrite &&
        artifactGuard.didAvoidExternalSignal &&
        artifactGuard.didAvoidExternalDiagnosticStore &&
        artifactGuard.didAvoidRuntimeSideEffect &&
        artifactGuard.didAvoidRendererStateWrite &&
        artifactGuard.didAvoidDrawingPermission &&
        artifactGuard.didStayFullRebuildOnly &&
        artifactGuard.shouldDeferRendererDiagnosticsArtifactGuard == false &&
        artifactGuard.shouldReportRendererDiagnosticsArtifactGuardBlocked == false
    let artifactDeferred = artifactGuard.didPrepareRendererDiagnosticsArtifactGuard ==
        false &&
        artifactGuard.shouldDeferRendererDiagnosticsArtifactGuard &&
        artifactGuard.shouldReportRendererDiagnosticsArtifactGuardBlocked == false
    let artifactInconsistent = (
        artifactGuard.didPrepareRendererDiagnosticsArtifactGuard &&
            (
                artifactGuard.isRendererDiagnosticsArtifactGuardNoExternalStore == false ||
                artifactGuard.didPreserveRendererDiagnosticsPrivacyAdmission == false ||
                artifactGuard.didKeepArtifactGuardInternalOnly == false ||
                artifactGuard.didAvoidExternalDiagnosticWrite == false ||
                artifactGuard.didAvoidConsoleWrite == false ||
                artifactGuard.didAvoidExternalSignal == false ||
                artifactGuard.didAvoidExternalDiagnosticStore == false ||
                artifactGuard.didAvoidRuntimeSideEffect == false ||
                artifactGuard.didAvoidRendererStateWrite == false ||
                artifactGuard.didAvoidDrawingPermission == false ||
                artifactGuard.didStayFullRebuildOnly == false ||
                artifactGuard.shouldDeferRendererDiagnosticsArtifactGuard
            )
        ) ||
        (
            artifactGuard.shouldDeferRendererDiagnosticsArtifactGuard &&
                artifactGuard.shouldReportRendererDiagnosticsArtifactGuardBlocked
        )

    // artifact guard 阻塞或不一致时，readiness 必须 fail-closed，不能宣称可写。
    if (
        artifactGuard.shouldReportRendererDiagnosticsArtifactGuardBlocked ||
        artifactInconsistent
    ) {
        return CjguiInternalRendererDiagnosticsNoWriteReadiness(
            artifactGuard,
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
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (artifactReady) {
        return CjguiInternalRendererDiagnosticsNoWriteReadiness(
            artifactGuard,
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
            true,
            true,
            true
        )
    }

    if (artifactDeferred) {
        return CjguiInternalRendererDiagnosticsNoWriteReadiness(
            artifactGuard,
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
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererDiagnosticsNoWriteReadiness(
        artifactGuard,
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
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererDiagnosticsOutputSinkAdmissionDraft(
): CjguiInternalRendererDiagnosticsNoWriteReadiness {
    // 默认 draft 只串联 no-output readiness -> output / channel / privacy /
    // artifact / no-write facts；它不写外部介质、不发外部信号、不保留外部产物。
    let noOutputReadiness = cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft()
    let intent = cjguiInternalBuildRendererDiagnosticsOutputSinkIntent(noOutputReadiness)
    let channelPolicy = cjguiInternalBuildRendererDiagnosticsOutputChannelPolicy(intent)
    let privacyAdmission = cjguiInternalBuildRendererDiagnosticsPrivacyAdmission(channelPolicy)
    let artifactGuard = cjguiInternalBuildRendererDiagnosticsArtifactGuard(privacyAdmission)
    return cjguiInternalBuildRendererDiagnosticsNoWriteReadiness(artifactGuard)
}

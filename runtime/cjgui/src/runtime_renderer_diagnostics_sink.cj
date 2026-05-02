package cjgui

// Owner: Renderer diagnostics sink policy boundary.
// Truth: 只消费 diagnostics policy result，产出 sink / privacy / lifecycle / no-output value facts。
// Stop-line: 不写外部介质、不写标准输出/标准错误、不发事件、不外发诊断、不保留外部产物。
// Same-shape Boundary Brake: 本 owner 新增 sink / privacy / lifecycle / no-output 语义，
// 不是把 policy result 再包成 receipt / record / 发布形态。

// Sink intent 只固定 future diagnostics sink 的内部入口意图；
// 它不启动真实 sink，也不收集原始 payload。
struct CjguiInternalRendererDiagnosticsSinkIntent {
    let policyResult: CjguiInternalRendererDiagnosticsPolicyResult
    let didPrepareRendererDiagnosticsSinkIntent: Bool
    let isRendererDiagnosticsSinkIntentOpen: Bool
    let shouldDeferRendererDiagnosticsSinkIntent: Bool
    let shouldReportRendererDiagnosticsSinkIntentBlocked: Bool
    let didPreserveRendererDiagnosticsPolicyResult: Bool
    let didUseDehydratedDiagnosticFacts: Bool
    let didAvoidOriginalPayloadCapture: Bool
    let didKeepSinkIntentInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidStandardOutputWrite: Bool
    let didAvoidStandardErrorWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalDiagnosticStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        policyResult: CjguiInternalRendererDiagnosticsPolicyResult,
        didPrepareRendererDiagnosticsSinkIntent: Bool,
        isRendererDiagnosticsSinkIntentOpen: Bool,
        shouldDeferRendererDiagnosticsSinkIntent: Bool,
        shouldReportRendererDiagnosticsSinkIntentBlocked: Bool,
        didPreserveRendererDiagnosticsPolicyResult: Bool,
        didUseDehydratedDiagnosticFacts: Bool,
        didAvoidOriginalPayloadCapture: Bool,
        didKeepSinkIntentInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidStandardOutputWrite: Bool,
        didAvoidStandardErrorWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalDiagnosticStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.policyResult = policyResult
        this.didPrepareRendererDiagnosticsSinkIntent =
            didPrepareRendererDiagnosticsSinkIntent
        this.isRendererDiagnosticsSinkIntentOpen = isRendererDiagnosticsSinkIntentOpen
        this.shouldDeferRendererDiagnosticsSinkIntent =
            shouldDeferRendererDiagnosticsSinkIntent
        this.shouldReportRendererDiagnosticsSinkIntentBlocked =
            shouldReportRendererDiagnosticsSinkIntentBlocked
        this.didPreserveRendererDiagnosticsPolicyResult =
            didPreserveRendererDiagnosticsPolicyResult
        this.didUseDehydratedDiagnosticFacts = didUseDehydratedDiagnosticFacts
        this.didAvoidOriginalPayloadCapture = didAvoidOriginalPayloadCapture
        this.didKeepSinkIntentInternalOnly = didKeepSinkIntentInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidStandardOutputWrite = didAvoidStandardOutputWrite
        this.didAvoidStandardErrorWrite = didAvoidStandardErrorWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalDiagnosticStore = didAvoidExternalDiagnosticStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Sink policy 只描述 no-output 策略 facts；
// 它不是外部诊断写入器，也不创建可执行 sink。
struct CjguiInternalRendererDiagnosticsSinkPolicy {
    let intent: CjguiInternalRendererDiagnosticsSinkIntent
    let didPrepareRendererDiagnosticsSinkPolicy: Bool
    let isRendererDiagnosticsSinkPolicyNoOutput: Bool
    let shouldDeferRendererDiagnosticsSinkPolicy: Bool
    let shouldReportRendererDiagnosticsSinkPolicyBlocked: Bool
    let didPreserveRendererDiagnosticsSinkIntent: Bool
    let didPreservePrivacyBoundary: Bool
    let didPreserveLifecycleBoundary: Bool
    let didKeepSinkPolicyInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidStandardOutputWrite: Bool
    let didAvoidStandardErrorWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalDiagnosticStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        intent: CjguiInternalRendererDiagnosticsSinkIntent,
        didPrepareRendererDiagnosticsSinkPolicy: Bool,
        isRendererDiagnosticsSinkPolicyNoOutput: Bool,
        shouldDeferRendererDiagnosticsSinkPolicy: Bool,
        shouldReportRendererDiagnosticsSinkPolicyBlocked: Bool,
        didPreserveRendererDiagnosticsSinkIntent: Bool,
        didPreservePrivacyBoundary: Bool,
        didPreserveLifecycleBoundary: Bool,
        didKeepSinkPolicyInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidStandardOutputWrite: Bool,
        didAvoidStandardErrorWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalDiagnosticStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.intent = intent
        this.didPrepareRendererDiagnosticsSinkPolicy =
            didPrepareRendererDiagnosticsSinkPolicy
        this.isRendererDiagnosticsSinkPolicyNoOutput = isRendererDiagnosticsSinkPolicyNoOutput
        this.shouldDeferRendererDiagnosticsSinkPolicy =
            shouldDeferRendererDiagnosticsSinkPolicy
        this.shouldReportRendererDiagnosticsSinkPolicyBlocked =
            shouldReportRendererDiagnosticsSinkPolicyBlocked
        this.didPreserveRendererDiagnosticsSinkIntent =
            didPreserveRendererDiagnosticsSinkIntent
        this.didPreservePrivacyBoundary = didPreservePrivacyBoundary
        this.didPreserveLifecycleBoundary = didPreserveLifecycleBoundary
        this.didKeepSinkPolicyInternalOnly = didKeepSinkPolicyInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidStandardOutputWrite = didAvoidStandardOutputWrite
        this.didAvoidStandardErrorWrite = didAvoidStandardErrorWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalDiagnosticStore = didAvoidExternalDiagnosticStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Privacy guard 只允许脱水后的 diagnostic facts 穿过边界；
// 它拒绝原始 payload 捕获，也不把内部 evidence 暴露到外部。
struct CjguiInternalRendererDiagnosticsPrivacyGuard {
    let sinkPolicy: CjguiInternalRendererDiagnosticsSinkPolicy
    let didPrepareRendererDiagnosticsPrivacyGuard: Bool
    let isRendererDiagnosticsPrivacyGuardSatisfied: Bool
    let shouldDeferRendererDiagnosticsPrivacyGuard: Bool
    let shouldReportRendererDiagnosticsPrivacyGuardBlocked: Bool
    let didPreserveRendererDiagnosticsSinkPolicy: Bool
    let didUseDehydratedDiagnosticFacts: Bool
    let didAvoidOriginalPayloadCapture: Bool
    let didAvoidExternalEvidenceExposure: Bool
    let didKeepPrivacyGuardInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidStandardOutputWrite: Bool
    let didAvoidStandardErrorWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalDiagnosticStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        sinkPolicy: CjguiInternalRendererDiagnosticsSinkPolicy,
        didPrepareRendererDiagnosticsPrivacyGuard: Bool,
        isRendererDiagnosticsPrivacyGuardSatisfied: Bool,
        shouldDeferRendererDiagnosticsPrivacyGuard: Bool,
        shouldReportRendererDiagnosticsPrivacyGuardBlocked: Bool,
        didPreserveRendererDiagnosticsSinkPolicy: Bool,
        didUseDehydratedDiagnosticFacts: Bool,
        didAvoidOriginalPayloadCapture: Bool,
        didAvoidExternalEvidenceExposure: Bool,
        didKeepPrivacyGuardInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidStandardOutputWrite: Bool,
        didAvoidStandardErrorWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalDiagnosticStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.sinkPolicy = sinkPolicy
        this.didPrepareRendererDiagnosticsPrivacyGuard =
            didPrepareRendererDiagnosticsPrivacyGuard
        this.isRendererDiagnosticsPrivacyGuardSatisfied =
            isRendererDiagnosticsPrivacyGuardSatisfied
        this.shouldDeferRendererDiagnosticsPrivacyGuard =
            shouldDeferRendererDiagnosticsPrivacyGuard
        this.shouldReportRendererDiagnosticsPrivacyGuardBlocked =
            shouldReportRendererDiagnosticsPrivacyGuardBlocked
        this.didPreserveRendererDiagnosticsSinkPolicy =
            didPreserveRendererDiagnosticsSinkPolicy
        this.didUseDehydratedDiagnosticFacts = didUseDehydratedDiagnosticFacts
        this.didAvoidOriginalPayloadCapture = didAvoidOriginalPayloadCapture
        this.didAvoidExternalEvidenceExposure = didAvoidExternalEvidenceExposure
        this.didKeepPrivacyGuardInternalOnly = didKeepPrivacyGuardInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidStandardOutputWrite = didAvoidStandardOutputWrite
        this.didAvoidStandardErrorWrite = didAvoidStandardErrorWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalDiagnosticStore = didAvoidExternalDiagnosticStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Lifecycle guard 只记录“当前不启动 sink 生命周期”的 facts；
// 它不注册回调、不创建 worker，也不创建全局可变 sink。
struct CjguiInternalRendererDiagnosticsLifecycleGuard {
    let privacyGuard: CjguiInternalRendererDiagnosticsPrivacyGuard
    let didPrepareRendererDiagnosticsLifecycleGuard: Bool
    let isRendererDiagnosticsLifecycleGuardSatisfied: Bool
    let shouldDeferRendererDiagnosticsLifecycleGuard: Bool
    let shouldReportRendererDiagnosticsLifecycleGuardBlocked: Bool
    let didPreserveRendererDiagnosticsPrivacyGuard: Bool
    let didAvoidSinkLifecycleStart: Bool
    let didAvoidCallbackRegistration: Bool
    let didAvoidWorkerCreation: Bool
    let didAvoidGlobalMutableSink: Bool
    let didKeepLifecycleGuardInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidStandardOutputWrite: Bool
    let didAvoidStandardErrorWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalDiagnosticStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        privacyGuard: CjguiInternalRendererDiagnosticsPrivacyGuard,
        didPrepareRendererDiagnosticsLifecycleGuard: Bool,
        isRendererDiagnosticsLifecycleGuardSatisfied: Bool,
        shouldDeferRendererDiagnosticsLifecycleGuard: Bool,
        shouldReportRendererDiagnosticsLifecycleGuardBlocked: Bool,
        didPreserveRendererDiagnosticsPrivacyGuard: Bool,
        didAvoidSinkLifecycleStart: Bool,
        didAvoidCallbackRegistration: Bool,
        didAvoidWorkerCreation: Bool,
        didAvoidGlobalMutableSink: Bool,
        didKeepLifecycleGuardInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidStandardOutputWrite: Bool,
        didAvoidStandardErrorWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalDiagnosticStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.privacyGuard = privacyGuard
        this.didPrepareRendererDiagnosticsLifecycleGuard =
            didPrepareRendererDiagnosticsLifecycleGuard
        this.isRendererDiagnosticsLifecycleGuardSatisfied =
            isRendererDiagnosticsLifecycleGuardSatisfied
        this.shouldDeferRendererDiagnosticsLifecycleGuard =
            shouldDeferRendererDiagnosticsLifecycleGuard
        this.shouldReportRendererDiagnosticsLifecycleGuardBlocked =
            shouldReportRendererDiagnosticsLifecycleGuardBlocked
        this.didPreserveRendererDiagnosticsPrivacyGuard =
            didPreserveRendererDiagnosticsPrivacyGuard
        this.didAvoidSinkLifecycleStart = didAvoidSinkLifecycleStart
        this.didAvoidCallbackRegistration = didAvoidCallbackRegistration
        this.didAvoidWorkerCreation = didAvoidWorkerCreation
        this.didAvoidGlobalMutableSink = didAvoidGlobalMutableSink
        this.didKeepLifecycleGuardInternalOnly = didKeepLifecycleGuardInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidStandardOutputWrite = didAvoidStandardOutputWrite
        this.didAvoidStandardErrorWrite = didAvoidStandardErrorWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalDiagnosticStore = didAvoidExternalDiagnosticStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// No-output readiness 是本 owner 的 canonical endpoint；
// ready 只表示 future sink policy boundary 可继续评估，不代表允许输出或渲染。
struct CjguiInternalRendererDiagnosticsNoOutputReadiness {
    let lifecycleGuard: CjguiInternalRendererDiagnosticsLifecycleGuard
    let isRendererDiagnosticsNoOutputReady: Bool
    let canFutureRendererBoundaryUseDiagnosticsSinkPolicy: Bool
    let shouldDeferRendererDiagnosticsNoOutputReadiness: Bool
    let shouldReportRendererDiagnosticsNoOutputReadinessBlocked: Bool
    let didPrepareRendererDiagnosticsNoOutputReadiness: Bool
    let didPreserveRendererDiagnosticsLifecycleGuard: Bool
    let didKeepDiagnosticsSinkPolicyInternalOnly: Bool
    let didUseDehydratedDiagnosticFacts: Bool
    let didAvoidOriginalPayloadCapture: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidStandardOutputWrite: Bool
    let didAvoidStandardErrorWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalDiagnosticStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        lifecycleGuard: CjguiInternalRendererDiagnosticsLifecycleGuard,
        isRendererDiagnosticsNoOutputReady: Bool,
        canFutureRendererBoundaryUseDiagnosticsSinkPolicy: Bool,
        shouldDeferRendererDiagnosticsNoOutputReadiness: Bool,
        shouldReportRendererDiagnosticsNoOutputReadinessBlocked: Bool,
        didPrepareRendererDiagnosticsNoOutputReadiness: Bool,
        didPreserveRendererDiagnosticsLifecycleGuard: Bool,
        didKeepDiagnosticsSinkPolicyInternalOnly: Bool,
        didUseDehydratedDiagnosticFacts: Bool,
        didAvoidOriginalPayloadCapture: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidStandardOutputWrite: Bool,
        didAvoidStandardErrorWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalDiagnosticStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.lifecycleGuard = lifecycleGuard
        this.isRendererDiagnosticsNoOutputReady = isRendererDiagnosticsNoOutputReady
        this.canFutureRendererBoundaryUseDiagnosticsSinkPolicy =
            canFutureRendererBoundaryUseDiagnosticsSinkPolicy
        this.shouldDeferRendererDiagnosticsNoOutputReadiness =
            shouldDeferRendererDiagnosticsNoOutputReadiness
        this.shouldReportRendererDiagnosticsNoOutputReadinessBlocked =
            shouldReportRendererDiagnosticsNoOutputReadinessBlocked
        this.didPrepareRendererDiagnosticsNoOutputReadiness =
            didPrepareRendererDiagnosticsNoOutputReadiness
        this.didPreserveRendererDiagnosticsLifecycleGuard =
            didPreserveRendererDiagnosticsLifecycleGuard
        this.didKeepDiagnosticsSinkPolicyInternalOnly =
            didKeepDiagnosticsSinkPolicyInternalOnly
        this.didUseDehydratedDiagnosticFacts = didUseDehydratedDiagnosticFacts
        this.didAvoidOriginalPayloadCapture = didAvoidOriginalPayloadCapture
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidStandardOutputWrite = didAvoidStandardOutputWrite
        this.didAvoidStandardErrorWrite = didAvoidStandardErrorWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalDiagnosticStore = didAvoidExternalDiagnosticStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererDiagnosticsSinkIntent(
    policyResult: CjguiInternalRendererDiagnosticsPolicyResult
): CjguiInternalRendererDiagnosticsSinkIntent {
    let policyReady = policyResult.isRendererDiagnosticsPolicyReady &&
        policyResult.canFutureRendererBoundaryUseDiagnosticsPolicy &&
        policyResult.didPrepareRendererDiagnosticsPolicyResult &&
        policyResult.didPreserveRendererDiagnosticRetentionHint &&
        policyResult.didKeepDiagnosticsPolicyResultInternalOnly &&
        policyResult.didAvoidExternalDiagnosticWrite &&
        policyResult.didAvoidDiagnosticBroadcast &&
        policyResult.didAvoidExternalDiagnosticNotification &&
        policyResult.didAvoidExceptionMechanism &&
        policyResult.didAvoidRendererStateWrite &&
        policyResult.didAvoidDrawingPermission &&
        policyResult.didStayFullRebuildOnly &&
        policyResult.shouldDeferRendererDiagnosticsPolicyResult == false &&
        policyResult.shouldReportRendererDiagnosticsPolicyResultBlocked == false
    let policyDeferred = policyResult.isRendererDiagnosticsPolicyReady == false &&
        policyResult.canFutureRendererBoundaryUseDiagnosticsPolicy == false &&
        policyResult.shouldDeferRendererDiagnosticsPolicyResult &&
        policyResult.shouldReportRendererDiagnosticsPolicyResultBlocked == false &&
        policyResult.didKeepDiagnosticsPolicyResultInternalOnly &&
        policyResult.didAvoidExternalDiagnosticWrite &&
        policyResult.didAvoidDiagnosticBroadcast &&
        policyResult.didAvoidExternalDiagnosticNotification &&
        policyResult.didAvoidExceptionMechanism &&
        policyResult.didAvoidRendererStateWrite &&
        policyResult.didAvoidDrawingPermission &&
        policyResult.didStayFullRebuildOnly
    let policyInconsistent = (
        policyResult.isRendererDiagnosticsPolicyReady &&
            (
                policyResult.canFutureRendererBoundaryUseDiagnosticsPolicy == false ||
                policyResult.didPrepareRendererDiagnosticsPolicyResult == false ||
                policyResult.didPreserveRendererDiagnosticRetentionHint == false ||
                policyResult.didKeepDiagnosticsPolicyResultInternalOnly == false ||
                policyResult.didAvoidExternalDiagnosticWrite == false ||
                policyResult.didAvoidDiagnosticBroadcast == false ||
                policyResult.didAvoidExternalDiagnosticNotification == false ||
                policyResult.didAvoidExceptionMechanism == false ||
                policyResult.didAvoidRendererStateWrite == false ||
                policyResult.didAvoidDrawingPermission == false ||
                policyResult.didStayFullRebuildOnly == false ||
                policyResult.shouldDeferRendererDiagnosticsPolicyResult ||
                policyResult.shouldReportRendererDiagnosticsPolicyResultBlocked
            )
        ) ||
        (
            policyResult.canFutureRendererBoundaryUseDiagnosticsPolicy &&
                policyResult.isRendererDiagnosticsPolicyReady == false
        ) ||
        (
            policyResult.shouldDeferRendererDiagnosticsPolicyResult &&
                policyResult.shouldReportRendererDiagnosticsPolicyResultBlocked
        )

    // policy result 阻塞或不一致时，sink intent 必须 fail-closed，不能伪造成可用 sink。
    if (
        policyResult.shouldReportRendererDiagnosticsPolicyResultBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererDiagnosticsSinkIntent(
            policyResult,
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

    if (policyReady) {
        return CjguiInternalRendererDiagnosticsSinkIntent(
            policyResult,
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

    if (policyDeferred) {
        return CjguiInternalRendererDiagnosticsSinkIntent(
            policyResult,
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

    return CjguiInternalRendererDiagnosticsSinkIntent(
        policyResult,
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

func cjguiInternalBuildRendererDiagnosticsSinkPolicy(
    intent: CjguiInternalRendererDiagnosticsSinkIntent
): CjguiInternalRendererDiagnosticsSinkPolicy {
    let intentReady = intent.didPrepareRendererDiagnosticsSinkIntent &&
        intent.isRendererDiagnosticsSinkIntentOpen &&
        intent.didPreserveRendererDiagnosticsPolicyResult &&
        intent.didUseDehydratedDiagnosticFacts &&
        intent.didAvoidOriginalPayloadCapture &&
        intent.didKeepSinkIntentInternalOnly &&
        intent.didAvoidExternalDiagnosticWrite &&
        intent.didAvoidStandardOutputWrite &&
        intent.didAvoidStandardErrorWrite &&
        intent.didAvoidExternalSignal &&
        intent.didAvoidExternalDiagnosticStore &&
        intent.didAvoidRuntimeSideEffect &&
        intent.didAvoidRendererStateWrite &&
        intent.didAvoidDrawingPermission &&
        intent.didStayFullRebuildOnly &&
        intent.shouldDeferRendererDiagnosticsSinkIntent == false &&
        intent.shouldReportRendererDiagnosticsSinkIntentBlocked == false
    let intentDeferred = intent.didPrepareRendererDiagnosticsSinkIntent == false &&
        intent.shouldDeferRendererDiagnosticsSinkIntent &&
        intent.shouldReportRendererDiagnosticsSinkIntentBlocked == false
    let intentBlocked = intent.shouldReportRendererDiagnosticsSinkIntentBlocked ||
        (
            intent.didPrepareRendererDiagnosticsSinkIntent &&
                intent.isRendererDiagnosticsSinkIntentOpen == false &&
                intent.shouldDeferRendererDiagnosticsSinkIntent == false
        )
    let intentInconsistent = (
        intent.didPrepareRendererDiagnosticsSinkIntent &&
            (
                intent.didPreserveRendererDiagnosticsPolicyResult == false ||
                intent.didUseDehydratedDiagnosticFacts == false ||
                intent.didAvoidOriginalPayloadCapture == false ||
                intent.didKeepSinkIntentInternalOnly == false ||
                intent.didAvoidExternalDiagnosticWrite == false ||
                intent.didAvoidStandardOutputWrite == false ||
                intent.didAvoidStandardErrorWrite == false ||
                intent.didAvoidExternalSignal == false ||
                intent.didAvoidExternalDiagnosticStore == false ||
                intent.didAvoidRuntimeSideEffect == false ||
                intent.didAvoidRendererStateWrite == false ||
                intent.didAvoidDrawingPermission == false ||
                intent.didStayFullRebuildOnly == false ||
                intent.shouldDeferRendererDiagnosticsSinkIntent
            )
        ) ||
        (
            intent.shouldDeferRendererDiagnosticsSinkIntent &&
                intent.shouldReportRendererDiagnosticsSinkIntentBlocked
        )

    // sink intent 阻塞或不一致时，policy 保持 no-output，不能变成可执行 sink。
    if (intentBlocked || intentInconsistent) {
        return CjguiInternalRendererDiagnosticsSinkPolicy(
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
        return CjguiInternalRendererDiagnosticsSinkPolicy(
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
        return CjguiInternalRendererDiagnosticsSinkPolicy(
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

    return CjguiInternalRendererDiagnosticsSinkPolicy(
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

func cjguiInternalBuildRendererDiagnosticsPrivacyGuard(
    sinkPolicy: CjguiInternalRendererDiagnosticsSinkPolicy
): CjguiInternalRendererDiagnosticsPrivacyGuard {
    let sinkPolicyReady = sinkPolicy.didPrepareRendererDiagnosticsSinkPolicy &&
        sinkPolicy.isRendererDiagnosticsSinkPolicyNoOutput &&
        sinkPolicy.didPreserveRendererDiagnosticsSinkIntent &&
        sinkPolicy.didPreservePrivacyBoundary &&
        sinkPolicy.didPreserveLifecycleBoundary &&
        sinkPolicy.didKeepSinkPolicyInternalOnly &&
        sinkPolicy.didAvoidExternalDiagnosticWrite &&
        sinkPolicy.didAvoidStandardOutputWrite &&
        sinkPolicy.didAvoidStandardErrorWrite &&
        sinkPolicy.didAvoidExternalSignal &&
        sinkPolicy.didAvoidExternalDiagnosticStore &&
        sinkPolicy.didAvoidRuntimeSideEffect &&
        sinkPolicy.didAvoidRendererStateWrite &&
        sinkPolicy.didAvoidDrawingPermission &&
        sinkPolicy.didStayFullRebuildOnly &&
        sinkPolicy.shouldDeferRendererDiagnosticsSinkPolicy == false &&
        sinkPolicy.shouldReportRendererDiagnosticsSinkPolicyBlocked == false
    let sinkPolicyDeferred = sinkPolicy.didPrepareRendererDiagnosticsSinkPolicy == false &&
        sinkPolicy.shouldDeferRendererDiagnosticsSinkPolicy &&
        sinkPolicy.shouldReportRendererDiagnosticsSinkPolicyBlocked == false
    let sinkPolicyBlocked = sinkPolicy.shouldReportRendererDiagnosticsSinkPolicyBlocked ||
        (
            sinkPolicy.didPrepareRendererDiagnosticsSinkPolicy &&
                sinkPolicy.isRendererDiagnosticsSinkPolicyNoOutput == false &&
                sinkPolicy.shouldDeferRendererDiagnosticsSinkPolicy == false
        )
    let sinkPolicyInconsistent = (
        sinkPolicy.didPrepareRendererDiagnosticsSinkPolicy &&
            (
                sinkPolicy.didPreserveRendererDiagnosticsSinkIntent == false ||
                sinkPolicy.didPreservePrivacyBoundary == false ||
                sinkPolicy.didPreserveLifecycleBoundary == false ||
                sinkPolicy.didKeepSinkPolicyInternalOnly == false ||
                sinkPolicy.didAvoidExternalDiagnosticWrite == false ||
                sinkPolicy.didAvoidStandardOutputWrite == false ||
                sinkPolicy.didAvoidStandardErrorWrite == false ||
                sinkPolicy.didAvoidExternalSignal == false ||
                sinkPolicy.didAvoidExternalDiagnosticStore == false ||
                sinkPolicy.didAvoidRuntimeSideEffect == false ||
                sinkPolicy.didAvoidRendererStateWrite == false ||
                sinkPolicy.didAvoidDrawingPermission == false ||
                sinkPolicy.didStayFullRebuildOnly == false ||
                sinkPolicy.shouldDeferRendererDiagnosticsSinkPolicy
            )
        ) ||
        (
            sinkPolicy.shouldDeferRendererDiagnosticsSinkPolicy &&
                sinkPolicy.shouldReportRendererDiagnosticsSinkPolicyBlocked
        )

    // sink policy 阻塞或不一致时，privacy guard 拒绝原始 payload 进入。
    if (sinkPolicyBlocked || sinkPolicyInconsistent) {
        return CjguiInternalRendererDiagnosticsPrivacyGuard(
            sinkPolicy,
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

    if (sinkPolicyReady) {
        return CjguiInternalRendererDiagnosticsPrivacyGuard(
            sinkPolicy,
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

    if (sinkPolicyDeferred) {
        return CjguiInternalRendererDiagnosticsPrivacyGuard(
            sinkPolicy,
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

    return CjguiInternalRendererDiagnosticsPrivacyGuard(
        sinkPolicy,
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

func cjguiInternalBuildRendererDiagnosticsLifecycleGuard(
    privacyGuard: CjguiInternalRendererDiagnosticsPrivacyGuard
): CjguiInternalRendererDiagnosticsLifecycleGuard {
    let privacyReady = privacyGuard.didPrepareRendererDiagnosticsPrivacyGuard &&
        privacyGuard.isRendererDiagnosticsPrivacyGuardSatisfied &&
        privacyGuard.didPreserveRendererDiagnosticsSinkPolicy &&
        privacyGuard.didUseDehydratedDiagnosticFacts &&
        privacyGuard.didAvoidOriginalPayloadCapture &&
        privacyGuard.didAvoidExternalEvidenceExposure &&
        privacyGuard.didKeepPrivacyGuardInternalOnly &&
        privacyGuard.didAvoidExternalDiagnosticWrite &&
        privacyGuard.didAvoidStandardOutputWrite &&
        privacyGuard.didAvoidStandardErrorWrite &&
        privacyGuard.didAvoidExternalSignal &&
        privacyGuard.didAvoidExternalDiagnosticStore &&
        privacyGuard.didAvoidRuntimeSideEffect &&
        privacyGuard.didAvoidRendererStateWrite &&
        privacyGuard.didAvoidDrawingPermission &&
        privacyGuard.didStayFullRebuildOnly &&
        privacyGuard.shouldDeferRendererDiagnosticsPrivacyGuard == false &&
        privacyGuard.shouldReportRendererDiagnosticsPrivacyGuardBlocked == false
    let privacyDeferred = privacyGuard.didPrepareRendererDiagnosticsPrivacyGuard == false &&
        privacyGuard.shouldDeferRendererDiagnosticsPrivacyGuard &&
        privacyGuard.shouldReportRendererDiagnosticsPrivacyGuardBlocked == false
    let privacyBlocked = privacyGuard.shouldReportRendererDiagnosticsPrivacyGuardBlocked ||
        (
            privacyGuard.didPrepareRendererDiagnosticsPrivacyGuard &&
                privacyGuard.isRendererDiagnosticsPrivacyGuardSatisfied == false &&
                privacyGuard.shouldDeferRendererDiagnosticsPrivacyGuard == false
        )
    let privacyInconsistent = (
        privacyGuard.didPrepareRendererDiagnosticsPrivacyGuard &&
            (
                privacyGuard.didPreserveRendererDiagnosticsSinkPolicy == false ||
                privacyGuard.didUseDehydratedDiagnosticFacts == false ||
                privacyGuard.didAvoidOriginalPayloadCapture == false ||
                privacyGuard.didAvoidExternalEvidenceExposure == false ||
                privacyGuard.didKeepPrivacyGuardInternalOnly == false ||
                privacyGuard.didAvoidExternalDiagnosticWrite == false ||
                privacyGuard.didAvoidStandardOutputWrite == false ||
                privacyGuard.didAvoidStandardErrorWrite == false ||
                privacyGuard.didAvoidExternalSignal == false ||
                privacyGuard.didAvoidExternalDiagnosticStore == false ||
                privacyGuard.didAvoidRuntimeSideEffect == false ||
                privacyGuard.didAvoidRendererStateWrite == false ||
                privacyGuard.didAvoidDrawingPermission == false ||
                privacyGuard.didStayFullRebuildOnly == false ||
                privacyGuard.shouldDeferRendererDiagnosticsPrivacyGuard
            )
        ) ||
        (
            privacyGuard.shouldDeferRendererDiagnosticsPrivacyGuard &&
                privacyGuard.shouldReportRendererDiagnosticsPrivacyGuardBlocked
        )

    // privacy guard 阻塞或不一致时，lifecycle guard 不能启动 sink 生命周期。
    if (privacyBlocked || privacyInconsistent) {
        return CjguiInternalRendererDiagnosticsLifecycleGuard(
            privacyGuard,
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
            true,
            true
        )
    }

    if (privacyReady) {
        return CjguiInternalRendererDiagnosticsLifecycleGuard(
            privacyGuard,
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
            true,
            true
        )
    }

    if (privacyDeferred) {
        return CjguiInternalRendererDiagnosticsLifecycleGuard(
            privacyGuard,
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
            true,
            true
        )
    }

    return CjguiInternalRendererDiagnosticsLifecycleGuard(
        privacyGuard,
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
        true,
        true
    )
}

func cjguiInternalBuildRendererDiagnosticsNoOutputReadiness(
    lifecycleGuard: CjguiInternalRendererDiagnosticsLifecycleGuard
): CjguiInternalRendererDiagnosticsNoOutputReadiness {
    let lifecycleReady = lifecycleGuard.didPrepareRendererDiagnosticsLifecycleGuard &&
        lifecycleGuard.isRendererDiagnosticsLifecycleGuardSatisfied &&
        lifecycleGuard.didPreserveRendererDiagnosticsPrivacyGuard &&
        lifecycleGuard.didAvoidSinkLifecycleStart &&
        lifecycleGuard.didAvoidCallbackRegistration &&
        lifecycleGuard.didAvoidWorkerCreation &&
        lifecycleGuard.didAvoidGlobalMutableSink &&
        lifecycleGuard.didKeepLifecycleGuardInternalOnly &&
        lifecycleGuard.didAvoidExternalDiagnosticWrite &&
        lifecycleGuard.didAvoidStandardOutputWrite &&
        lifecycleGuard.didAvoidStandardErrorWrite &&
        lifecycleGuard.didAvoidExternalSignal &&
        lifecycleGuard.didAvoidExternalDiagnosticStore &&
        lifecycleGuard.didAvoidRuntimeSideEffect &&
        lifecycleGuard.didAvoidRendererStateWrite &&
        lifecycleGuard.didAvoidDrawingPermission &&
        lifecycleGuard.didStayFullRebuildOnly &&
        lifecycleGuard.shouldDeferRendererDiagnosticsLifecycleGuard == false &&
        lifecycleGuard.shouldReportRendererDiagnosticsLifecycleGuardBlocked == false
    let lifecycleDeferred = lifecycleGuard.didPrepareRendererDiagnosticsLifecycleGuard ==
        false &&
        lifecycleGuard.shouldDeferRendererDiagnosticsLifecycleGuard &&
        lifecycleGuard.shouldReportRendererDiagnosticsLifecycleGuardBlocked == false
    let lifecycleInconsistent = (
        lifecycleGuard.didPrepareRendererDiagnosticsLifecycleGuard &&
            (
                lifecycleGuard.isRendererDiagnosticsLifecycleGuardSatisfied == false ||
                lifecycleGuard.didPreserveRendererDiagnosticsPrivacyGuard == false ||
                lifecycleGuard.didAvoidSinkLifecycleStart == false ||
                lifecycleGuard.didAvoidCallbackRegistration == false ||
                lifecycleGuard.didAvoidWorkerCreation == false ||
                lifecycleGuard.didAvoidGlobalMutableSink == false ||
                lifecycleGuard.didKeepLifecycleGuardInternalOnly == false ||
                lifecycleGuard.didAvoidExternalDiagnosticWrite == false ||
                lifecycleGuard.didAvoidStandardOutputWrite == false ||
                lifecycleGuard.didAvoidStandardErrorWrite == false ||
                lifecycleGuard.didAvoidExternalSignal == false ||
                lifecycleGuard.didAvoidExternalDiagnosticStore == false ||
                lifecycleGuard.didAvoidRuntimeSideEffect == false ||
                lifecycleGuard.didAvoidRendererStateWrite == false ||
                lifecycleGuard.didAvoidDrawingPermission == false ||
                lifecycleGuard.didStayFullRebuildOnly == false ||
                lifecycleGuard.shouldDeferRendererDiagnosticsLifecycleGuard
            )
        ) ||
        (
            lifecycleGuard.shouldDeferRendererDiagnosticsLifecycleGuard &&
                lifecycleGuard.shouldReportRendererDiagnosticsLifecycleGuardBlocked
        )

    // lifecycle guard 阻塞或不一致时，readiness 必须 fail-closed，不能宣称可输出。
    if (
        lifecycleGuard.shouldReportRendererDiagnosticsLifecycleGuardBlocked ||
        lifecycleInconsistent
    ) {
        return CjguiInternalRendererDiagnosticsNoOutputReadiness(
            lifecycleGuard,
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

    if (lifecycleReady) {
        return CjguiInternalRendererDiagnosticsNoOutputReadiness(
            lifecycleGuard,
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

    if (lifecycleDeferred) {
        return CjguiInternalRendererDiagnosticsNoOutputReadiness(
            lifecycleGuard,
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

    return CjguiInternalRendererDiagnosticsNoOutputReadiness(
        lifecycleGuard,
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

func cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft(
): CjguiInternalRendererDiagnosticsNoOutputReadiness {
    // 默认 draft 只串联 policy result -> sink intent / policy / privacy / lifecycle /
    // no-output readiness facts；它不写外部介质、不发事件、不保留外部产物。
    let policyResult = cjguiInternalExecuteDefaultRendererDiagnosticsPolicyDraft()
    let intent = cjguiInternalBuildRendererDiagnosticsSinkIntent(policyResult)
    let sinkPolicy = cjguiInternalBuildRendererDiagnosticsSinkPolicy(intent)
    let privacyGuard = cjguiInternalBuildRendererDiagnosticsPrivacyGuard(sinkPolicy)
    let lifecycleGuard = cjguiInternalBuildRendererDiagnosticsLifecycleGuard(privacyGuard)
    return cjguiInternalBuildRendererDiagnosticsNoOutputReadiness(lifecycleGuard)
}

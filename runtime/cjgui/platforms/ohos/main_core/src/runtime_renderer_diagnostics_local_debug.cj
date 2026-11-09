package cjgui

// Owner: Renderer diagnostics local debug sink policy boundary.
// Truth: 只消费 no-op write readiness，产出本地调试意图、调试通道策略、
// opt-in 护栏、脱敏策略和 no-output debug readiness value facts。
// Stop-line: 不执行真实日志/调试输出，不写外部介质或控制台，不发外部信号。
// Same-shape Boundary Brake: 本 owner 新增 channel / opt-in / redaction / no-output 语义，
// 不是把 no-op write readiness 再包成收据、记录或发布包装。

// Local debug sink intent 只固定 future local debug runway 的内部意图；
// 它不启动真实输出，也不收集原始 payload。
struct CjguiInternalRendererLocalDebugSinkIntent {
    let noOpWriteReadiness: CjguiInternalRendererDiagnosticsNoOpWriteReadiness
    let didPrepareRendererLocalDebugSinkIntent: Bool
    let isRendererLocalDebugSinkIntentOpen: Bool
    let shouldDeferRendererLocalDebugSinkIntent: Bool
    let shouldReportRendererLocalDebugSinkIntentBlocked: Bool
    let didPreserveRendererDiagnosticsNoOpWriteReadiness: Bool
    let didPreserveDebugChannelPolicyVocabulary: Bool
    let didPreserveOptInGuardVocabulary: Bool
    let didPreserveRedactionPolicyVocabulary: Bool
    let didKeepLocalDebugIntentInternalOnly: Bool
    let didUseDehydratedDiagnosticFacts: Bool
    let didAvoidOriginalPayloadCapture: Bool
    let didAvoidActualSerializationOutput: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalArtifactStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        noOpWriteReadiness: CjguiInternalRendererDiagnosticsNoOpWriteReadiness,
        didPrepareRendererLocalDebugSinkIntent: Bool,
        isRendererLocalDebugSinkIntentOpen: Bool,
        shouldDeferRendererLocalDebugSinkIntent: Bool,
        shouldReportRendererLocalDebugSinkIntentBlocked: Bool,
        didPreserveRendererDiagnosticsNoOpWriteReadiness: Bool,
        didPreserveDebugChannelPolicyVocabulary: Bool,
        didPreserveOptInGuardVocabulary: Bool,
        didPreserveRedactionPolicyVocabulary: Bool,
        didKeepLocalDebugIntentInternalOnly: Bool,
        didUseDehydratedDiagnosticFacts: Bool,
        didAvoidOriginalPayloadCapture: Bool,
        didAvoidActualSerializationOutput: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalArtifactStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.noOpWriteReadiness = noOpWriteReadiness
        this.didPrepareRendererLocalDebugSinkIntent =
            didPrepareRendererLocalDebugSinkIntent
        this.isRendererLocalDebugSinkIntentOpen =
            isRendererLocalDebugSinkIntentOpen
        this.shouldDeferRendererLocalDebugSinkIntent =
            shouldDeferRendererLocalDebugSinkIntent
        this.shouldReportRendererLocalDebugSinkIntentBlocked =
            shouldReportRendererLocalDebugSinkIntentBlocked
        this.didPreserveRendererDiagnosticsNoOpWriteReadiness =
            didPreserveRendererDiagnosticsNoOpWriteReadiness
        this.didPreserveDebugChannelPolicyVocabulary =
            didPreserveDebugChannelPolicyVocabulary
        this.didPreserveOptInGuardVocabulary = didPreserveOptInGuardVocabulary
        this.didPreserveRedactionPolicyVocabulary =
            didPreserveRedactionPolicyVocabulary
        this.didKeepLocalDebugIntentInternalOnly =
            didKeepLocalDebugIntentInternalOnly
        this.didUseDehydratedDiagnosticFacts = didUseDehydratedDiagnosticFacts
        this.didAvoidOriginalPayloadCapture = didAvoidOriginalPayloadCapture
        this.didAvoidActualSerializationOutput = didAvoidActualSerializationOutput
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidConsoleWrite = didAvoidConsoleWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalArtifactStore = didAvoidExternalArtifactStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Debug channel policy 只描述 future debug channel 的策略 facts；
// 它不是通道实现，也不会执行任何输出动作。
struct CjguiInternalRendererDebugChannelPolicy {
    let intent: CjguiInternalRendererLocalDebugSinkIntent
    let didPrepareRendererDebugChannelPolicy: Bool
    let isRendererDebugChannelPolicyNoOutput: Bool
    let shouldDeferRendererDebugChannelPolicy: Bool
    let shouldReportRendererDebugChannelPolicyBlocked: Bool
    let didPreserveRendererLocalDebugSinkIntent: Bool
    let didKeepDebugChannelPolicyAsValueFact: Bool
    let didPreserveOptInGuardBoundary: Bool
    let didPreserveRedactionPolicyBoundary: Bool
    let didAvoidDebugChannelImplementation: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalArtifactStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        intent: CjguiInternalRendererLocalDebugSinkIntent,
        didPrepareRendererDebugChannelPolicy: Bool,
        isRendererDebugChannelPolicyNoOutput: Bool,
        shouldDeferRendererDebugChannelPolicy: Bool,
        shouldReportRendererDebugChannelPolicyBlocked: Bool,
        didPreserveRendererLocalDebugSinkIntent: Bool,
        didKeepDebugChannelPolicyAsValueFact: Bool,
        didPreserveOptInGuardBoundary: Bool,
        didPreserveRedactionPolicyBoundary: Bool,
        didAvoidDebugChannelImplementation: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalArtifactStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.intent = intent
        this.didPrepareRendererDebugChannelPolicy =
            didPrepareRendererDebugChannelPolicy
        this.isRendererDebugChannelPolicyNoOutput =
            isRendererDebugChannelPolicyNoOutput
        this.shouldDeferRendererDebugChannelPolicy =
            shouldDeferRendererDebugChannelPolicy
        this.shouldReportRendererDebugChannelPolicyBlocked =
            shouldReportRendererDebugChannelPolicyBlocked
        this.didPreserveRendererLocalDebugSinkIntent =
            didPreserveRendererLocalDebugSinkIntent
        this.didKeepDebugChannelPolicyAsValueFact =
            didKeepDebugChannelPolicyAsValueFact
        this.didPreserveOptInGuardBoundary = didPreserveOptInGuardBoundary
        this.didPreserveRedactionPolicyBoundary = didPreserveRedactionPolicyBoundary
        this.didAvoidDebugChannelImplementation =
            didAvoidDebugChannelImplementation
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidConsoleWrite = didAvoidConsoleWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalArtifactStore = didAvoidExternalArtifactStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Opt-in guard 只表达 future opt-in requirement；
// 它不是运行时开关，也不读取设置或写入全局状态。
struct CjguiInternalRendererDebugOptInGuard {
    let channelPolicy: CjguiInternalRendererDebugChannelPolicy
    let didPrepareRendererDebugOptInGuard: Bool
    let isRendererDebugOptInGuardSatisfied: Bool
    let shouldDeferRendererDebugOptInGuard: Bool
    let shouldReportRendererDebugOptInGuardBlocked: Bool
    let didPreserveRendererDebugChannelPolicy: Bool
    let didKeepOptInGuardAsValueFact: Bool
    let didAvoidRuntimeFlagRead: Bool
    let didAvoidGlobalSwitch: Bool
    let didPreserveRedactionPolicyBoundary: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalArtifactStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        channelPolicy: CjguiInternalRendererDebugChannelPolicy,
        didPrepareRendererDebugOptInGuard: Bool,
        isRendererDebugOptInGuardSatisfied: Bool,
        shouldDeferRendererDebugOptInGuard: Bool,
        shouldReportRendererDebugOptInGuardBlocked: Bool,
        didPreserveRendererDebugChannelPolicy: Bool,
        didKeepOptInGuardAsValueFact: Bool,
        didAvoidRuntimeFlagRead: Bool,
        didAvoidGlobalSwitch: Bool,
        didPreserveRedactionPolicyBoundary: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalArtifactStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.channelPolicy = channelPolicy
        this.didPrepareRendererDebugOptInGuard =
            didPrepareRendererDebugOptInGuard
        this.isRendererDebugOptInGuardSatisfied =
            isRendererDebugOptInGuardSatisfied
        this.shouldDeferRendererDebugOptInGuard =
            shouldDeferRendererDebugOptInGuard
        this.shouldReportRendererDebugOptInGuardBlocked =
            shouldReportRendererDebugOptInGuardBlocked
        this.didPreserveRendererDebugChannelPolicy =
            didPreserveRendererDebugChannelPolicy
        this.didKeepOptInGuardAsValueFact = didKeepOptInGuardAsValueFact
        this.didAvoidRuntimeFlagRead = didAvoidRuntimeFlagRead
        this.didAvoidGlobalSwitch = didAvoidGlobalSwitch
        this.didPreserveRedactionPolicyBoundary =
            didPreserveRedactionPolicyBoundary
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidConsoleWrite = didAvoidConsoleWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalArtifactStore = didAvoidExternalArtifactStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Redaction policy 只描述脱水诊断 facts 的脱敏口径；
// 它不捕获原始 payload，也不产生真实序列化输出。
struct CjguiInternalRendererDebugRedactionPolicy {
    let optInGuard: CjguiInternalRendererDebugOptInGuard
    let didPrepareRendererDebugRedactionPolicy: Bool
    let isRendererDebugRedactionPolicySatisfied: Bool
    let shouldDeferRendererDebugRedactionPolicy: Bool
    let shouldReportRendererDebugRedactionPolicyBlocked: Bool
    let didPreserveRendererDebugOptInGuard: Bool
    let didUseDehydratedDiagnosticFacts: Bool
    let didAvoidOriginalPayloadCapture: Bool
    let didAvoidActualSerializationOutput: Bool
    let didKeepRedactionPolicyAsValueFact: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalArtifactStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        optInGuard: CjguiInternalRendererDebugOptInGuard,
        didPrepareRendererDebugRedactionPolicy: Bool,
        isRendererDebugRedactionPolicySatisfied: Bool,
        shouldDeferRendererDebugRedactionPolicy: Bool,
        shouldReportRendererDebugRedactionPolicyBlocked: Bool,
        didPreserveRendererDebugOptInGuard: Bool,
        didUseDehydratedDiagnosticFacts: Bool,
        didAvoidOriginalPayloadCapture: Bool,
        didAvoidActualSerializationOutput: Bool,
        didKeepRedactionPolicyAsValueFact: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalArtifactStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.optInGuard = optInGuard
        this.didPrepareRendererDebugRedactionPolicy =
            didPrepareRendererDebugRedactionPolicy
        this.isRendererDebugRedactionPolicySatisfied =
            isRendererDebugRedactionPolicySatisfied
        this.shouldDeferRendererDebugRedactionPolicy =
            shouldDeferRendererDebugRedactionPolicy
        this.shouldReportRendererDebugRedactionPolicyBlocked =
            shouldReportRendererDebugRedactionPolicyBlocked
        this.didPreserveRendererDebugOptInGuard =
            didPreserveRendererDebugOptInGuard
        this.didUseDehydratedDiagnosticFacts = didUseDehydratedDiagnosticFacts
        this.didAvoidOriginalPayloadCapture = didAvoidOriginalPayloadCapture
        this.didAvoidActualSerializationOutput = didAvoidActualSerializationOutput
        this.didKeepRedactionPolicyAsValueFact = didKeepRedactionPolicyAsValueFact
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidConsoleWrite = didAvoidConsoleWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalArtifactStore = didAvoidExternalArtifactStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// No-output debug readiness 是本 owner 的 canonical endpoint；
// ready 只表示 future local debug policy boundary 可继续评估，不代表允许真实调试输出。
// 当前没有真实调试输出、日志、外部介质、控制台、遥测、观察者、事件总线、公开诊断或外部产物保留。
struct CjguiInternalRendererNoOutputDebugReadiness {
    let redactionPolicy: CjguiInternalRendererDebugRedactionPolicy
    let isRendererNoOutputDebugReady: Bool
    let canFutureRendererBoundaryUseLocalDebugPolicy: Bool
    let shouldDeferRendererNoOutputDebugReadiness: Bool
    let shouldReportRendererNoOutputDebugReadinessBlocked: Bool
    let didPrepareRendererNoOutputDebugReadiness: Bool
    let didPreserveRendererDebugRedactionPolicy: Bool
    let didPreserveDebugChannelPolicy: Bool
    let didPreserveDebugOptInGuard: Bool
    let didKeepLocalDebugPolicyInternalOnly: Bool
    let didAvoidActualSerializationOutput: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalArtifactStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        redactionPolicy: CjguiInternalRendererDebugRedactionPolicy,
        isRendererNoOutputDebugReady: Bool,
        canFutureRendererBoundaryUseLocalDebugPolicy: Bool,
        shouldDeferRendererNoOutputDebugReadiness: Bool,
        shouldReportRendererNoOutputDebugReadinessBlocked: Bool,
        didPrepareRendererNoOutputDebugReadiness: Bool,
        didPreserveRendererDebugRedactionPolicy: Bool,
        didPreserveDebugChannelPolicy: Bool,
        didPreserveDebugOptInGuard: Bool,
        didKeepLocalDebugPolicyInternalOnly: Bool,
        didAvoidActualSerializationOutput: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalArtifactStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.redactionPolicy = redactionPolicy
        this.isRendererNoOutputDebugReady = isRendererNoOutputDebugReady
        this.canFutureRendererBoundaryUseLocalDebugPolicy =
            canFutureRendererBoundaryUseLocalDebugPolicy
        this.shouldDeferRendererNoOutputDebugReadiness =
            shouldDeferRendererNoOutputDebugReadiness
        this.shouldReportRendererNoOutputDebugReadinessBlocked =
            shouldReportRendererNoOutputDebugReadinessBlocked
        this.didPrepareRendererNoOutputDebugReadiness =
            didPrepareRendererNoOutputDebugReadiness
        this.didPreserveRendererDebugRedactionPolicy =
            didPreserveRendererDebugRedactionPolicy
        this.didPreserveDebugChannelPolicy = didPreserveDebugChannelPolicy
        this.didPreserveDebugOptInGuard = didPreserveDebugOptInGuard
        this.didKeepLocalDebugPolicyInternalOnly =
            didKeepLocalDebugPolicyInternalOnly
        this.didAvoidActualSerializationOutput = didAvoidActualSerializationOutput
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidConsoleWrite = didAvoidConsoleWrite
        this.didAvoidExternalSignal = didAvoidExternalSignal
        this.didAvoidExternalArtifactStore = didAvoidExternalArtifactStore
        this.didAvoidRuntimeSideEffect = didAvoidRuntimeSideEffect
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererLocalDebugSinkIntent(
    noOpWriteReadiness: CjguiInternalRendererDiagnosticsNoOpWriteReadiness
): CjguiInternalRendererLocalDebugSinkIntent {
    let readiness = noOpWriteReadiness
    let noOpReady = readiness.isRendererDiagnosticsNoOpWriteReady &&
        readiness.canFutureRendererBoundaryUseDiagnosticsRealWriteNoOp &&
        readiness.didPrepareRendererDiagnosticsNoOpWriteReadiness &&
        readiness.didPreserveRendererDiagnosticsPrivacySafeSerializationPolicy &&
        readiness.didPreserveSinkTargetPolicy &&
        readiness.didPreserveWriteSafetyGate &&
        readiness.didKeepDiagnosticsRealWriteNoOpInternalOnly &&
        readiness.didAvoidActualSerializationOutput &&
        readiness.didAvoidExternalDiagnosticWrite &&
        readiness.didAvoidConsoleWrite &&
        readiness.didAvoidExternalSignal &&
        readiness.didAvoidExternalArtifactStore &&
        readiness.didAvoidRuntimeSideEffect &&
        readiness.didAvoidRendererStateWrite &&
        readiness.didAvoidDrawingPermission &&
        readiness.didStayFullRebuildOnly &&
        readiness.shouldDeferRendererDiagnosticsNoOpWriteReadiness == false &&
        readiness.shouldReportRendererDiagnosticsNoOpWriteReadinessBlocked == false
    let noOpDeferred = readiness.isRendererDiagnosticsNoOpWriteReady == false &&
        readiness.canFutureRendererBoundaryUseDiagnosticsRealWriteNoOp == false &&
        readiness.shouldDeferRendererDiagnosticsNoOpWriteReadiness &&
        readiness.shouldReportRendererDiagnosticsNoOpWriteReadinessBlocked == false &&
        readiness.didKeepDiagnosticsRealWriteNoOpInternalOnly &&
        readiness.didAvoidActualSerializationOutput &&
        readiness.didAvoidExternalDiagnosticWrite &&
        readiness.didAvoidConsoleWrite &&
        readiness.didAvoidExternalSignal &&
        readiness.didAvoidExternalArtifactStore &&
        readiness.didAvoidRuntimeSideEffect &&
        readiness.didAvoidRendererStateWrite &&
        readiness.didAvoidDrawingPermission &&
        readiness.didStayFullRebuildOnly
    let noOpInconsistent = (
        readiness.isRendererDiagnosticsNoOpWriteReady &&
            (
                readiness.canFutureRendererBoundaryUseDiagnosticsRealWriteNoOp ==
                    false ||
                readiness.didPrepareRendererDiagnosticsNoOpWriteReadiness == false ||
                readiness.didPreserveRendererDiagnosticsPrivacySafeSerializationPolicy ==
                    false ||
                readiness.didPreserveSinkTargetPolicy == false ||
                readiness.didPreserveWriteSafetyGate == false ||
                readiness.didKeepDiagnosticsRealWriteNoOpInternalOnly == false ||
                readiness.didAvoidActualSerializationOutput == false ||
                readiness.didAvoidExternalDiagnosticWrite == false ||
                readiness.didAvoidConsoleWrite == false ||
                readiness.didAvoidExternalSignal == false ||
                readiness.didAvoidExternalArtifactStore == false ||
                readiness.didAvoidRuntimeSideEffect == false ||
                readiness.didAvoidRendererStateWrite == false ||
                readiness.didAvoidDrawingPermission == false ||
                readiness.didStayFullRebuildOnly == false ||
                readiness.shouldDeferRendererDiagnosticsNoOpWriteReadiness ||
                readiness.shouldReportRendererDiagnosticsNoOpWriteReadinessBlocked
            )
        ) ||
        (
            readiness.canFutureRendererBoundaryUseDiagnosticsRealWriteNoOp &&
                readiness.isRendererDiagnosticsNoOpWriteReady == false
        ) ||
        (
            readiness.shouldDeferRendererDiagnosticsNoOpWriteReadiness &&
                readiness.shouldReportRendererDiagnosticsNoOpWriteReadinessBlocked
        )

    // no-op readiness 阻塞或不一致时，local debug intent 必须 fail-closed，
    // 不能伪造成可输出。
    if (
        readiness.shouldReportRendererDiagnosticsNoOpWriteReadinessBlocked ||
        noOpInconsistent
    ) {
        return CjguiInternalRendererLocalDebugSinkIntent(
            noOpWriteReadiness,
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
            true,
            true
        )
    }

    if (noOpReady) {
        return CjguiInternalRendererLocalDebugSinkIntent(
            noOpWriteReadiness,
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
            true,
            true
        )
    }

    if (noOpDeferred) {
        return CjguiInternalRendererLocalDebugSinkIntent(
            noOpWriteReadiness,
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
            true,
            true
        )
    }

    return CjguiInternalRendererLocalDebugSinkIntent(
        noOpWriteReadiness,
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
        true,
        true
    )
}

func cjguiInternalBuildRendererDebugChannelPolicy(
    intent: CjguiInternalRendererLocalDebugSinkIntent
): CjguiInternalRendererDebugChannelPolicy {
    let intentReady = intent.didPrepareRendererLocalDebugSinkIntent &&
        intent.isRendererLocalDebugSinkIntentOpen &&
        intent.didPreserveRendererDiagnosticsNoOpWriteReadiness &&
        intent.didPreserveDebugChannelPolicyVocabulary &&
        intent.didPreserveOptInGuardVocabulary &&
        intent.didPreserveRedactionPolicyVocabulary &&
        intent.didKeepLocalDebugIntentInternalOnly &&
        intent.didUseDehydratedDiagnosticFacts &&
        intent.didAvoidOriginalPayloadCapture &&
        intent.didAvoidActualSerializationOutput &&
        intent.didAvoidExternalDiagnosticWrite &&
        intent.didAvoidConsoleWrite &&
        intent.didAvoidExternalSignal &&
        intent.didAvoidExternalArtifactStore &&
        intent.didAvoidRuntimeSideEffect &&
        intent.didAvoidRendererStateWrite &&
        intent.didAvoidDrawingPermission &&
        intent.didStayFullRebuildOnly &&
        intent.shouldDeferRendererLocalDebugSinkIntent == false &&
        intent.shouldReportRendererLocalDebugSinkIntentBlocked == false
    let intentDeferred = intent.didPrepareRendererLocalDebugSinkIntent == false &&
        intent.shouldDeferRendererLocalDebugSinkIntent &&
        intent.shouldReportRendererLocalDebugSinkIntentBlocked == false
    let intentBlocked = intent.shouldReportRendererLocalDebugSinkIntentBlocked ||
        (
            intent.didPrepareRendererLocalDebugSinkIntent &&
                intent.isRendererLocalDebugSinkIntentOpen == false &&
                intent.shouldDeferRendererLocalDebugSinkIntent == false
        )
    let intentInconsistent = (
        intent.didPrepareRendererLocalDebugSinkIntent &&
            (
                intent.didPreserveRendererDiagnosticsNoOpWriteReadiness == false ||
                intent.didPreserveDebugChannelPolicyVocabulary == false ||
                intent.didPreserveOptInGuardVocabulary == false ||
                intent.didPreserveRedactionPolicyVocabulary == false ||
                intent.didKeepLocalDebugIntentInternalOnly == false ||
                intent.didUseDehydratedDiagnosticFacts == false ||
                intent.didAvoidOriginalPayloadCapture == false ||
                intent.didAvoidActualSerializationOutput == false ||
                intent.didAvoidExternalDiagnosticWrite == false ||
                intent.didAvoidConsoleWrite == false ||
                intent.didAvoidExternalSignal == false ||
                intent.didAvoidExternalArtifactStore == false ||
                intent.didAvoidRuntimeSideEffect == false ||
                intent.didAvoidRendererStateWrite == false ||
                intent.didAvoidDrawingPermission == false ||
                intent.didStayFullRebuildOnly == false ||
                intent.shouldDeferRendererLocalDebugSinkIntent
            )
        ) ||
        (
            intent.shouldDeferRendererLocalDebugSinkIntent &&
                intent.shouldReportRendererLocalDebugSinkIntentBlocked
        )

    // local debug intent 阻塞或不一致时，channel policy 只能保持 no-output facts。
    if (intentBlocked || intentInconsistent) {
        return CjguiInternalRendererDebugChannelPolicy(
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
        return CjguiInternalRendererDebugChannelPolicy(
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
        return CjguiInternalRendererDebugChannelPolicy(
            intent,
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

    return CjguiInternalRendererDebugChannelPolicy(
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

func cjguiInternalBuildRendererDebugOptInGuard(
    channelPolicy: CjguiInternalRendererDebugChannelPolicy
): CjguiInternalRendererDebugOptInGuard {
    let channelReady = channelPolicy.didPrepareRendererDebugChannelPolicy &&
        channelPolicy.isRendererDebugChannelPolicyNoOutput &&
        channelPolicy.didPreserveRendererLocalDebugSinkIntent &&
        channelPolicy.didKeepDebugChannelPolicyAsValueFact &&
        channelPolicy.didPreserveOptInGuardBoundary &&
        channelPolicy.didPreserveRedactionPolicyBoundary &&
        channelPolicy.didAvoidDebugChannelImplementation &&
        channelPolicy.didAvoidExternalDiagnosticWrite &&
        channelPolicy.didAvoidConsoleWrite &&
        channelPolicy.didAvoidExternalSignal &&
        channelPolicy.didAvoidExternalArtifactStore &&
        channelPolicy.didAvoidRuntimeSideEffect &&
        channelPolicy.didAvoidRendererStateWrite &&
        channelPolicy.didAvoidDrawingPermission &&
        channelPolicy.didStayFullRebuildOnly &&
        channelPolicy.shouldDeferRendererDebugChannelPolicy == false &&
        channelPolicy.shouldReportRendererDebugChannelPolicyBlocked == false
    let channelDeferred =
        channelPolicy.didPrepareRendererDebugChannelPolicy == false &&
        channelPolicy.shouldDeferRendererDebugChannelPolicy &&
        channelPolicy.shouldReportRendererDebugChannelPolicyBlocked == false
    let channelBlocked =
        channelPolicy.shouldReportRendererDebugChannelPolicyBlocked ||
        (
            channelPolicy.didPrepareRendererDebugChannelPolicy &&
                channelPolicy.shouldDeferRendererDebugChannelPolicy == false &&
                channelPolicy.isRendererDebugChannelPolicyNoOutput == false
        )
    let channelInconsistent = (
        channelPolicy.didPrepareRendererDebugChannelPolicy &&
            (
                channelPolicy.didPreserveRendererLocalDebugSinkIntent == false ||
                channelPolicy.didKeepDebugChannelPolicyAsValueFact == false ||
                channelPolicy.didPreserveOptInGuardBoundary == false ||
                channelPolicy.didPreserveRedactionPolicyBoundary == false ||
                channelPolicy.didAvoidDebugChannelImplementation == false ||
                channelPolicy.didAvoidExternalDiagnosticWrite == false ||
                channelPolicy.didAvoidConsoleWrite == false ||
                channelPolicy.didAvoidExternalSignal == false ||
                channelPolicy.didAvoidExternalArtifactStore == false ||
                channelPolicy.didAvoidRuntimeSideEffect == false ||
                channelPolicy.didAvoidRendererStateWrite == false ||
                channelPolicy.didAvoidDrawingPermission == false ||
                channelPolicy.didStayFullRebuildOnly == false ||
                channelPolicy.shouldDeferRendererDebugChannelPolicy
            )
        ) ||
        (
            channelPolicy.shouldDeferRendererDebugChannelPolicy &&
                channelPolicy.shouldReportRendererDebugChannelPolicyBlocked
        )

    // channel policy 阻塞或不一致时，opt-in guard 必须 fail-closed，
    // 不能伪造为已启用调试输出。
    if (channelBlocked || channelInconsistent) {
        return CjguiInternalRendererDebugOptInGuard(
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
        return CjguiInternalRendererDebugOptInGuard(
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
        return CjguiInternalRendererDebugOptInGuard(
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

    return CjguiInternalRendererDebugOptInGuard(
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

func cjguiInternalBuildRendererDebugRedactionPolicy(
    optInGuard: CjguiInternalRendererDebugOptInGuard
): CjguiInternalRendererDebugRedactionPolicy {
    let optInReady = optInGuard.didPrepareRendererDebugOptInGuard &&
        optInGuard.isRendererDebugOptInGuardSatisfied &&
        optInGuard.didPreserveRendererDebugChannelPolicy &&
        optInGuard.didKeepOptInGuardAsValueFact &&
        optInGuard.didAvoidRuntimeFlagRead &&
        optInGuard.didAvoidGlobalSwitch &&
        optInGuard.didPreserveRedactionPolicyBoundary &&
        optInGuard.didAvoidExternalDiagnosticWrite &&
        optInGuard.didAvoidConsoleWrite &&
        optInGuard.didAvoidExternalSignal &&
        optInGuard.didAvoidExternalArtifactStore &&
        optInGuard.didAvoidRuntimeSideEffect &&
        optInGuard.didAvoidRendererStateWrite &&
        optInGuard.didAvoidDrawingPermission &&
        optInGuard.didStayFullRebuildOnly &&
        optInGuard.shouldDeferRendererDebugOptInGuard == false &&
        optInGuard.shouldReportRendererDebugOptInGuardBlocked == false
    let optInDeferred = optInGuard.didPrepareRendererDebugOptInGuard == false &&
        optInGuard.shouldDeferRendererDebugOptInGuard &&
        optInGuard.shouldReportRendererDebugOptInGuardBlocked == false
    let optInBlocked = optInGuard.shouldReportRendererDebugOptInGuardBlocked ||
        (
            optInGuard.didPrepareRendererDebugOptInGuard &&
                optInGuard.shouldDeferRendererDebugOptInGuard == false &&
                optInGuard.isRendererDebugOptInGuardSatisfied == false
        )
    let optInInconsistent = (
        optInGuard.didPrepareRendererDebugOptInGuard &&
            (
                optInGuard.didPreserveRendererDebugChannelPolicy == false ||
                optInGuard.didKeepOptInGuardAsValueFact == false ||
                optInGuard.didAvoidRuntimeFlagRead == false ||
                optInGuard.didAvoidGlobalSwitch == false ||
                optInGuard.didPreserveRedactionPolicyBoundary == false ||
                optInGuard.didAvoidExternalDiagnosticWrite == false ||
                optInGuard.didAvoidConsoleWrite == false ||
                optInGuard.didAvoidExternalSignal == false ||
                optInGuard.didAvoidExternalArtifactStore == false ||
                optInGuard.didAvoidRuntimeSideEffect == false ||
                optInGuard.didAvoidRendererStateWrite == false ||
                optInGuard.didAvoidDrawingPermission == false ||
                optInGuard.didStayFullRebuildOnly == false ||
                optInGuard.shouldDeferRendererDebugOptInGuard
            )
        ) ||
        (
            optInGuard.shouldDeferRendererDebugOptInGuard &&
                optInGuard.shouldReportRendererDebugOptInGuardBlocked
        )

    // opt-in guard 阻塞或不一致时，redaction policy 只能保留脱水 facts 口径。
    if (optInBlocked || optInInconsistent) {
        return CjguiInternalRendererDebugRedactionPolicy(
            optInGuard,
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

    if (optInReady) {
        return CjguiInternalRendererDebugRedactionPolicy(
            optInGuard,
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

    if (optInDeferred) {
        return CjguiInternalRendererDebugRedactionPolicy(
            optInGuard,
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

    return CjguiInternalRendererDebugRedactionPolicy(
        optInGuard,
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

func cjguiInternalBuildRendererNoOutputDebugReadiness(
    redactionPolicy: CjguiInternalRendererDebugRedactionPolicy
): CjguiInternalRendererNoOutputDebugReadiness {
    let redactionReady = redactionPolicy.didPrepareRendererDebugRedactionPolicy &&
        redactionPolicy.isRendererDebugRedactionPolicySatisfied &&
        redactionPolicy.didPreserveRendererDebugOptInGuard &&
        redactionPolicy.didUseDehydratedDiagnosticFacts &&
        redactionPolicy.didAvoidOriginalPayloadCapture &&
        redactionPolicy.didAvoidActualSerializationOutput &&
        redactionPolicy.didKeepRedactionPolicyAsValueFact &&
        redactionPolicy.didAvoidExternalDiagnosticWrite &&
        redactionPolicy.didAvoidConsoleWrite &&
        redactionPolicy.didAvoidExternalSignal &&
        redactionPolicy.didAvoidExternalArtifactStore &&
        redactionPolicy.didAvoidRuntimeSideEffect &&
        redactionPolicy.didAvoidRendererStateWrite &&
        redactionPolicy.didAvoidDrawingPermission &&
        redactionPolicy.didStayFullRebuildOnly &&
        redactionPolicy.shouldDeferRendererDebugRedactionPolicy == false &&
        redactionPolicy.shouldReportRendererDebugRedactionPolicyBlocked == false
    let redactionDeferred =
        redactionPolicy.didPrepareRendererDebugRedactionPolicy == false &&
        redactionPolicy.shouldDeferRendererDebugRedactionPolicy &&
        redactionPolicy.shouldReportRendererDebugRedactionPolicyBlocked == false
    let redactionBlocked =
        redactionPolicy.shouldReportRendererDebugRedactionPolicyBlocked ||
        (
            redactionPolicy.didPrepareRendererDebugRedactionPolicy &&
                redactionPolicy.shouldDeferRendererDebugRedactionPolicy == false &&
                redactionPolicy.isRendererDebugRedactionPolicySatisfied == false
        )
    let redactionInconsistent = (
        redactionPolicy.didPrepareRendererDebugRedactionPolicy &&
            (
                redactionPolicy.didPreserveRendererDebugOptInGuard == false ||
                redactionPolicy.didUseDehydratedDiagnosticFacts == false ||
                redactionPolicy.didAvoidOriginalPayloadCapture == false ||
                redactionPolicy.didAvoidActualSerializationOutput == false ||
                redactionPolicy.didKeepRedactionPolicyAsValueFact == false ||
                redactionPolicy.didAvoidExternalDiagnosticWrite == false ||
                redactionPolicy.didAvoidConsoleWrite == false ||
                redactionPolicy.didAvoidExternalSignal == false ||
                redactionPolicy.didAvoidExternalArtifactStore == false ||
                redactionPolicy.didAvoidRuntimeSideEffect == false ||
                redactionPolicy.didAvoidRendererStateWrite == false ||
                redactionPolicy.didAvoidDrawingPermission == false ||
                redactionPolicy.didStayFullRebuildOnly == false ||
                redactionPolicy.shouldDeferRendererDebugRedactionPolicy
            )
        ) ||
        (
            redactionPolicy.shouldDeferRendererDebugRedactionPolicy &&
                redactionPolicy.shouldReportRendererDebugRedactionPolicyBlocked
        )

    // redaction policy 阻塞或不一致时，最终 readiness 必须 fail-closed，
    // 不能伪造成真实调试输出许可。
    if (redactionBlocked || redactionInconsistent) {
        return CjguiInternalRendererNoOutputDebugReadiness(
            redactionPolicy,
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

    if (redactionReady) {
        return CjguiInternalRendererNoOutputDebugReadiness(
            redactionPolicy,
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

    if (redactionDeferred) {
        return CjguiInternalRendererNoOutputDebugReadiness(
            redactionPolicy,
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
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererNoOutputDebugReadiness(
        redactionPolicy,
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

// Default draft 只生成 local debug sink policy value facts；
// 它不触发真实调试输出，不写外部介质，不发外部信号，也不保留外部诊断产物。
func cjguiInternalExecuteDefaultRendererLocalDebugSinkPolicyDraft():
    CjguiInternalRendererNoOutputDebugReadiness {
    let noOpWriteReadiness =
        cjguiInternalExecuteDefaultRendererDiagnosticsRealWriteNoOpDraft()
    let intent = cjguiInternalBuildRendererLocalDebugSinkIntent(
        noOpWriteReadiness
    )
    let channelPolicy = cjguiInternalBuildRendererDebugChannelPolicy(
        intent
    )
    let optInGuard = cjguiInternalBuildRendererDebugOptInGuard(
        channelPolicy
    )
    let redactionPolicy = cjguiInternalBuildRendererDebugRedactionPolicy(
        optInGuard
    )
    return cjguiInternalBuildRendererNoOutputDebugReadiness(
        redactionPolicy
    )
}

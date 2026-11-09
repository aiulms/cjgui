package cjgui

// Owner: Renderer diagnostics local debug output admission boundary.
// Truth: 只消费 no-output debug readiness，产出输出目标策略、opt-in 准入、
// 脱敏 readiness 和 no-write local output readiness value facts。
// Stop-line: 不执行真实日志或本地调试输出，不写外部介质或控制台，不发外部信号。
// Same-shape Boundary Brake: 本 owner 新增 target / opt-in / redaction / no-write 语义，
// 不是把 no-output debug readiness 再包成收据、记录或发布包装。

// Local debug output intent 只固定 future local output runway 的内部准入意图；
// 它不启动真实输出，也不收集原始 payload。
struct CjguiInternalRendererLocalDebugOutputIntent {
    let noOutputDebugReadiness: CjguiInternalRendererNoOutputDebugReadiness
    let didPrepareRendererLocalDebugOutputIntent: Bool
    let isRendererLocalDebugOutputIntentOpen: Bool
    let shouldDeferRendererLocalDebugOutputIntent: Bool
    let shouldReportRendererLocalDebugOutputIntentBlocked: Bool
    let didPreserveRendererNoOutputDebugReadiness: Bool
    let didPreserveOutputTargetPolicyVocabulary: Bool
    let didPreserveOptInAdmissionVocabulary: Bool
    let didPreserveRedactionReadinessVocabulary: Bool
    let didPreserveNoWriteOutputBoundary: Bool
    let didKeepLocalDebugOutputIntentInternalOnly: Bool
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
        noOutputDebugReadiness: CjguiInternalRendererNoOutputDebugReadiness,
        didPrepareRendererLocalDebugOutputIntent: Bool,
        isRendererLocalDebugOutputIntentOpen: Bool,
        shouldDeferRendererLocalDebugOutputIntent: Bool,
        shouldReportRendererLocalDebugOutputIntentBlocked: Bool,
        didPreserveRendererNoOutputDebugReadiness: Bool,
        didPreserveOutputTargetPolicyVocabulary: Bool,
        didPreserveOptInAdmissionVocabulary: Bool,
        didPreserveRedactionReadinessVocabulary: Bool,
        didPreserveNoWriteOutputBoundary: Bool,
        didKeepLocalDebugOutputIntentInternalOnly: Bool,
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
        this.noOutputDebugReadiness = noOutputDebugReadiness
        this.didPrepareRendererLocalDebugOutputIntent =
            didPrepareRendererLocalDebugOutputIntent
        this.isRendererLocalDebugOutputIntentOpen =
            isRendererLocalDebugOutputIntentOpen
        this.shouldDeferRendererLocalDebugOutputIntent =
            shouldDeferRendererLocalDebugOutputIntent
        this.shouldReportRendererLocalDebugOutputIntentBlocked =
            shouldReportRendererLocalDebugOutputIntentBlocked
        this.didPreserveRendererNoOutputDebugReadiness =
            didPreserveRendererNoOutputDebugReadiness
        this.didPreserveOutputTargetPolicyVocabulary =
            didPreserveOutputTargetPolicyVocabulary
        this.didPreserveOptInAdmissionVocabulary =
            didPreserveOptInAdmissionVocabulary
        this.didPreserveRedactionReadinessVocabulary =
            didPreserveRedactionReadinessVocabulary
        this.didPreserveNoWriteOutputBoundary = didPreserveNoWriteOutputBoundary
        this.didKeepLocalDebugOutputIntentInternalOnly =
            didKeepLocalDebugOutputIntentInternalOnly
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

// Output target policy 只描述 future output target 的 value facts；
// 它不是目标实现，也不会绑定任何可写目标。
struct CjguiInternalRendererLocalOutputTargetPolicy {
    let intent: CjguiInternalRendererLocalDebugOutputIntent
    let didPrepareRendererLocalOutputTargetPolicy: Bool
    let isRendererLocalOutputTargetPolicyNoWrite: Bool
    let shouldDeferRendererLocalOutputTargetPolicy: Bool
    let shouldReportRendererLocalOutputTargetPolicyBlocked: Bool
    let didPreserveRendererLocalDebugOutputIntent: Bool
    let didKeepOutputTargetPolicyAsValueFact: Bool
    let didAvoidTargetImplementation: Bool
    let didPreserveOptInAdmissionBoundary: Bool
    let didPreserveRedactionReadinessBoundary: Bool
    let didPreserveNoWriteOutputBoundary: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalArtifactStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        intent: CjguiInternalRendererLocalDebugOutputIntent,
        didPrepareRendererLocalOutputTargetPolicy: Bool,
        isRendererLocalOutputTargetPolicyNoWrite: Bool,
        shouldDeferRendererLocalOutputTargetPolicy: Bool,
        shouldReportRendererLocalOutputTargetPolicyBlocked: Bool,
        didPreserveRendererLocalDebugOutputIntent: Bool,
        didKeepOutputTargetPolicyAsValueFact: Bool,
        didAvoidTargetImplementation: Bool,
        didPreserveOptInAdmissionBoundary: Bool,
        didPreserveRedactionReadinessBoundary: Bool,
        didPreserveNoWriteOutputBoundary: Bool,
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
        this.didPrepareRendererLocalOutputTargetPolicy =
            didPrepareRendererLocalOutputTargetPolicy
        this.isRendererLocalOutputTargetPolicyNoWrite =
            isRendererLocalOutputTargetPolicyNoWrite
        this.shouldDeferRendererLocalOutputTargetPolicy =
            shouldDeferRendererLocalOutputTargetPolicy
        this.shouldReportRendererLocalOutputTargetPolicyBlocked =
            shouldReportRendererLocalOutputTargetPolicyBlocked
        this.didPreserveRendererLocalDebugOutputIntent =
            didPreserveRendererLocalDebugOutputIntent
        this.didKeepOutputTargetPolicyAsValueFact =
            didKeepOutputTargetPolicyAsValueFact
        this.didAvoidTargetImplementation = didAvoidTargetImplementation
        this.didPreserveOptInAdmissionBoundary =
            didPreserveOptInAdmissionBoundary
        this.didPreserveRedactionReadinessBoundary =
            didPreserveRedactionReadinessBoundary
        this.didPreserveNoWriteOutputBoundary = didPreserveNoWriteOutputBoundary
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

// Opt-in admission 只表达 future opt-in 准入 facts；
// 它不是运行时开关，也不读取设置或写入全局状态。
struct CjguiInternalRendererLocalDebugOptInAdmission {
    let targetPolicy: CjguiInternalRendererLocalOutputTargetPolicy
    let didPrepareRendererLocalDebugOptInAdmission: Bool
    let isRendererLocalDebugOptInAdmissionSatisfied: Bool
    let shouldDeferRendererLocalDebugOptInAdmission: Bool
    let shouldReportRendererLocalDebugOptInAdmissionBlocked: Bool
    let didPreserveRendererLocalOutputTargetPolicy: Bool
    let didKeepOptInAdmissionAsValueFact: Bool
    let didAvoidRuntimeFlagRead: Bool
    let didAvoidGlobalSwitch: Bool
    let didPreserveRedactionReadinessBoundary: Bool
    let didPreserveNoWriteOutputBoundary: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalArtifactStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        targetPolicy: CjguiInternalRendererLocalOutputTargetPolicy,
        didPrepareRendererLocalDebugOptInAdmission: Bool,
        isRendererLocalDebugOptInAdmissionSatisfied: Bool,
        shouldDeferRendererLocalDebugOptInAdmission: Bool,
        shouldReportRendererLocalDebugOptInAdmissionBlocked: Bool,
        didPreserveRendererLocalOutputTargetPolicy: Bool,
        didKeepOptInAdmissionAsValueFact: Bool,
        didAvoidRuntimeFlagRead: Bool,
        didAvoidGlobalSwitch: Bool,
        didPreserveRedactionReadinessBoundary: Bool,
        didPreserveNoWriteOutputBoundary: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalArtifactStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.targetPolicy = targetPolicy
        this.didPrepareRendererLocalDebugOptInAdmission =
            didPrepareRendererLocalDebugOptInAdmission
        this.isRendererLocalDebugOptInAdmissionSatisfied =
            isRendererLocalDebugOptInAdmissionSatisfied
        this.shouldDeferRendererLocalDebugOptInAdmission =
            shouldDeferRendererLocalDebugOptInAdmission
        this.shouldReportRendererLocalDebugOptInAdmissionBlocked =
            shouldReportRendererLocalDebugOptInAdmissionBlocked
        this.didPreserveRendererLocalOutputTargetPolicy =
            didPreserveRendererLocalOutputTargetPolicy
        this.didKeepOptInAdmissionAsValueFact = didKeepOptInAdmissionAsValueFact
        this.didAvoidRuntimeFlagRead = didAvoidRuntimeFlagRead
        this.didAvoidGlobalSwitch = didAvoidGlobalSwitch
        this.didPreserveRedactionReadinessBoundary =
            didPreserveRedactionReadinessBoundary
        this.didPreserveNoWriteOutputBoundary = didPreserveNoWriteOutputBoundary
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

// Redaction readiness 只描述脱水诊断 facts 的脱敏准入口径；
// 它不捕获原始 payload，也不产生真实序列化输出。
struct CjguiInternalRendererLocalDebugRedactionReadiness {
    let optInAdmission: CjguiInternalRendererLocalDebugOptInAdmission
    let didPrepareRendererLocalDebugRedactionReadiness: Bool
    let isRendererLocalDebugRedactionReady: Bool
    let shouldDeferRendererLocalDebugRedactionReadiness: Bool
    let shouldReportRendererLocalDebugRedactionReadinessBlocked: Bool
    let didPreserveRendererLocalDebugOptInAdmission: Bool
    let didUseDehydratedDiagnosticFacts: Bool
    let didAvoidOriginalPayloadCapture: Bool
    let didAvoidActualSerializationOutput: Bool
    let didKeepRedactionReadinessAsValueFact: Bool
    let didPreserveNoWriteOutputBoundary: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidConsoleWrite: Bool
    let didAvoidExternalSignal: Bool
    let didAvoidExternalArtifactStore: Bool
    let didAvoidRuntimeSideEffect: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        optInAdmission: CjguiInternalRendererLocalDebugOptInAdmission,
        didPrepareRendererLocalDebugRedactionReadiness: Bool,
        isRendererLocalDebugRedactionReady: Bool,
        shouldDeferRendererLocalDebugRedactionReadiness: Bool,
        shouldReportRendererLocalDebugRedactionReadinessBlocked: Bool,
        didPreserveRendererLocalDebugOptInAdmission: Bool,
        didUseDehydratedDiagnosticFacts: Bool,
        didAvoidOriginalPayloadCapture: Bool,
        didAvoidActualSerializationOutput: Bool,
        didKeepRedactionReadinessAsValueFact: Bool,
        didPreserveNoWriteOutputBoundary: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidConsoleWrite: Bool,
        didAvoidExternalSignal: Bool,
        didAvoidExternalArtifactStore: Bool,
        didAvoidRuntimeSideEffect: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.optInAdmission = optInAdmission
        this.didPrepareRendererLocalDebugRedactionReadiness =
            didPrepareRendererLocalDebugRedactionReadiness
        this.isRendererLocalDebugRedactionReady =
            isRendererLocalDebugRedactionReady
        this.shouldDeferRendererLocalDebugRedactionReadiness =
            shouldDeferRendererLocalDebugRedactionReadiness
        this.shouldReportRendererLocalDebugRedactionReadinessBlocked =
            shouldReportRendererLocalDebugRedactionReadinessBlocked
        this.didPreserveRendererLocalDebugOptInAdmission =
            didPreserveRendererLocalDebugOptInAdmission
        this.didUseDehydratedDiagnosticFacts = didUseDehydratedDiagnosticFacts
        this.didAvoidOriginalPayloadCapture = didAvoidOriginalPayloadCapture
        this.didAvoidActualSerializationOutput = didAvoidActualSerializationOutput
        this.didKeepRedactionReadinessAsValueFact =
            didKeepRedactionReadinessAsValueFact
        this.didPreserveNoWriteOutputBoundary = didPreserveNoWriteOutputBoundary
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

// No-write local output readiness 是本 owner 的 canonical endpoint；
// ready 只表示 future local debug output admission 可继续评估，不代表允许真实输出。
// 当前没有真实调试输出、日志、外部介质、控制台、遥测、观察者、事件总线、公开诊断或外部产物保留。
struct CjguiInternalRendererNoWriteLocalOutputReadiness {
    let redactionReadiness: CjguiInternalRendererLocalDebugRedactionReadiness
    let isRendererNoWriteLocalOutputReady: Bool
    let canFutureRendererBoundaryUseLocalDebugOutputAdmission: Bool
    let shouldDeferRendererNoWriteLocalOutputReadiness: Bool
    let shouldReportRendererNoWriteLocalOutputReadinessBlocked: Bool
    let didPrepareRendererNoWriteLocalOutputReadiness: Bool
    let didPreserveRendererLocalDebugRedactionReadiness: Bool
    let didPreserveLocalOutputTargetPolicy: Bool
    let didPreserveLocalDebugOptInAdmission: Bool
    let didKeepLocalDebugOutputAdmissionInternalOnly: Bool
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
        redactionReadiness: CjguiInternalRendererLocalDebugRedactionReadiness,
        isRendererNoWriteLocalOutputReady: Bool,
        canFutureRendererBoundaryUseLocalDebugOutputAdmission: Bool,
        shouldDeferRendererNoWriteLocalOutputReadiness: Bool,
        shouldReportRendererNoWriteLocalOutputReadinessBlocked: Bool,
        didPrepareRendererNoWriteLocalOutputReadiness: Bool,
        didPreserveRendererLocalDebugRedactionReadiness: Bool,
        didPreserveLocalOutputTargetPolicy: Bool,
        didPreserveLocalDebugOptInAdmission: Bool,
        didKeepLocalDebugOutputAdmissionInternalOnly: Bool,
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
        this.redactionReadiness = redactionReadiness
        this.isRendererNoWriteLocalOutputReady = isRendererNoWriteLocalOutputReady
        this.canFutureRendererBoundaryUseLocalDebugOutputAdmission =
            canFutureRendererBoundaryUseLocalDebugOutputAdmission
        this.shouldDeferRendererNoWriteLocalOutputReadiness =
            shouldDeferRendererNoWriteLocalOutputReadiness
        this.shouldReportRendererNoWriteLocalOutputReadinessBlocked =
            shouldReportRendererNoWriteLocalOutputReadinessBlocked
        this.didPrepareRendererNoWriteLocalOutputReadiness =
            didPrepareRendererNoWriteLocalOutputReadiness
        this.didPreserveRendererLocalDebugRedactionReadiness =
            didPreserveRendererLocalDebugRedactionReadiness
        this.didPreserveLocalOutputTargetPolicy =
            didPreserveLocalOutputTargetPolicy
        this.didPreserveLocalDebugOptInAdmission =
            didPreserveLocalDebugOptInAdmission
        this.didKeepLocalDebugOutputAdmissionInternalOnly =
            didKeepLocalDebugOutputAdmissionInternalOnly
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

func cjguiInternalBuildRendererLocalDebugOutputIntent(
    noOutputDebugReadiness: CjguiInternalRendererNoOutputDebugReadiness
): CjguiInternalRendererLocalDebugOutputIntent {
    let readiness = noOutputDebugReadiness
    let noOutputReady = readiness.isRendererNoOutputDebugReady &&
        readiness.canFutureRendererBoundaryUseLocalDebugPolicy &&
        readiness.didPrepareRendererNoOutputDebugReadiness &&
        readiness.didPreserveRendererDebugRedactionPolicy &&
        readiness.didPreserveDebugChannelPolicy &&
        readiness.didPreserveDebugOptInGuard &&
        readiness.didKeepLocalDebugPolicyInternalOnly &&
        readiness.didAvoidActualSerializationOutput &&
        readiness.didAvoidExternalDiagnosticWrite &&
        readiness.didAvoidConsoleWrite &&
        readiness.didAvoidExternalSignal &&
        readiness.didAvoidExternalArtifactStore &&
        readiness.didAvoidRuntimeSideEffect &&
        readiness.didAvoidRendererStateWrite &&
        readiness.didAvoidDrawingPermission &&
        readiness.didStayFullRebuildOnly &&
        readiness.shouldDeferRendererNoOutputDebugReadiness == false &&
        readiness.shouldReportRendererNoOutputDebugReadinessBlocked == false
    let noOutputDeferred = readiness.isRendererNoOutputDebugReady == false &&
        readiness.canFutureRendererBoundaryUseLocalDebugPolicy == false &&
        readiness.shouldDeferRendererNoOutputDebugReadiness &&
        readiness.shouldReportRendererNoOutputDebugReadinessBlocked == false &&
        readiness.didKeepLocalDebugPolicyInternalOnly &&
        readiness.didAvoidActualSerializationOutput &&
        readiness.didAvoidExternalDiagnosticWrite &&
        readiness.didAvoidConsoleWrite &&
        readiness.didAvoidExternalSignal &&
        readiness.didAvoidExternalArtifactStore &&
        readiness.didAvoidRuntimeSideEffect &&
        readiness.didAvoidRendererStateWrite &&
        readiness.didAvoidDrawingPermission &&
        readiness.didStayFullRebuildOnly
    let noOutputInconsistent = (
        readiness.isRendererNoOutputDebugReady &&
            (
                readiness.canFutureRendererBoundaryUseLocalDebugPolicy == false ||
                readiness.didPrepareRendererNoOutputDebugReadiness == false ||
                readiness.didPreserveRendererDebugRedactionPolicy == false ||
                readiness.didPreserveDebugChannelPolicy == false ||
                readiness.didPreserveDebugOptInGuard == false ||
                readiness.didKeepLocalDebugPolicyInternalOnly == false ||
                readiness.didAvoidActualSerializationOutput == false ||
                readiness.didAvoidExternalDiagnosticWrite == false ||
                readiness.didAvoidConsoleWrite == false ||
                readiness.didAvoidExternalSignal == false ||
                readiness.didAvoidExternalArtifactStore == false ||
                readiness.didAvoidRuntimeSideEffect == false ||
                readiness.didAvoidRendererStateWrite == false ||
                readiness.didAvoidDrawingPermission == false ||
                readiness.didStayFullRebuildOnly == false ||
                readiness.shouldDeferRendererNoOutputDebugReadiness ||
                readiness.shouldReportRendererNoOutputDebugReadinessBlocked
            )
        ) ||
        (
            readiness.canFutureRendererBoundaryUseLocalDebugPolicy &&
                readiness.isRendererNoOutputDebugReady == false
        ) ||
        (
            readiness.shouldDeferRendererNoOutputDebugReadiness &&
                readiness.shouldReportRendererNoOutputDebugReadinessBlocked
        )

    // no-output debug readiness 阻塞或不一致时，output intent 必须 fail-closed，
    // 不能伪造成可输出。
    if (
        readiness.shouldReportRendererNoOutputDebugReadinessBlocked ||
        noOutputInconsistent
    ) {
        return CjguiInternalRendererLocalDebugOutputIntent(
            noOutputDebugReadiness,
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
            true,
            true
        )
    }

    if (noOutputReady) {
        return CjguiInternalRendererLocalDebugOutputIntent(
            noOutputDebugReadiness,
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
            true,
            true
        )
    }

    if (noOutputDeferred) {
        return CjguiInternalRendererLocalDebugOutputIntent(
            noOutputDebugReadiness,
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
            true,
            true
        )
    }

    return CjguiInternalRendererLocalDebugOutputIntent(
        noOutputDebugReadiness,
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
        true,
        true
    )
}

func cjguiInternalBuildRendererLocalOutputTargetPolicy(
    intent: CjguiInternalRendererLocalDebugOutputIntent
): CjguiInternalRendererLocalOutputTargetPolicy {
    let intentReady = intent.didPrepareRendererLocalDebugOutputIntent &&
        intent.isRendererLocalDebugOutputIntentOpen &&
        intent.didPreserveRendererNoOutputDebugReadiness &&
        intent.didPreserveOutputTargetPolicyVocabulary &&
        intent.didPreserveOptInAdmissionVocabulary &&
        intent.didPreserveRedactionReadinessVocabulary &&
        intent.didPreserveNoWriteOutputBoundary &&
        intent.didKeepLocalDebugOutputIntentInternalOnly &&
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
        intent.shouldDeferRendererLocalDebugOutputIntent == false &&
        intent.shouldReportRendererLocalDebugOutputIntentBlocked == false
    let intentDeferred = intent.didPrepareRendererLocalDebugOutputIntent == false &&
        intent.shouldDeferRendererLocalDebugOutputIntent &&
        intent.shouldReportRendererLocalDebugOutputIntentBlocked == false
    let intentBlocked = intent.shouldReportRendererLocalDebugOutputIntentBlocked ||
        (
            intent.didPrepareRendererLocalDebugOutputIntent &&
                intent.isRendererLocalDebugOutputIntentOpen == false &&
                intent.shouldDeferRendererLocalDebugOutputIntent == false
        )
    let intentInconsistent = (
        intent.didPrepareRendererLocalDebugOutputIntent &&
            (
                intent.didPreserveRendererNoOutputDebugReadiness == false ||
                intent.didPreserveOutputTargetPolicyVocabulary == false ||
                intent.didPreserveOptInAdmissionVocabulary == false ||
                intent.didPreserveRedactionReadinessVocabulary == false ||
                intent.didPreserveNoWriteOutputBoundary == false ||
                intent.didKeepLocalDebugOutputIntentInternalOnly == false ||
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
                intent.shouldDeferRendererLocalDebugOutputIntent
            )
        ) ||
        (
            intent.shouldDeferRendererLocalDebugOutputIntent &&
                intent.shouldReportRendererLocalDebugOutputIntentBlocked
        )

    // output intent 阻塞或不一致时，target policy 只能保持 no-write facts。
    if (intentBlocked || intentInconsistent) {
        return CjguiInternalRendererLocalOutputTargetPolicy(
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
            true,
            true
        )
    }

    if (intentReady) {
        return CjguiInternalRendererLocalOutputTargetPolicy(
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
            true,
            true
        )
    }

    if (intentDeferred) {
        return CjguiInternalRendererLocalOutputTargetPolicy(
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
            true,
            true
        )
    }

    return CjguiInternalRendererLocalOutputTargetPolicy(
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
        true,
        true
    )
}

func cjguiInternalBuildRendererLocalDebugOptInAdmission(
    targetPolicy: CjguiInternalRendererLocalOutputTargetPolicy
): CjguiInternalRendererLocalDebugOptInAdmission {
    let targetReady = targetPolicy.didPrepareRendererLocalOutputTargetPolicy &&
        targetPolicy.isRendererLocalOutputTargetPolicyNoWrite &&
        targetPolicy.didPreserveRendererLocalDebugOutputIntent &&
        targetPolicy.didKeepOutputTargetPolicyAsValueFact &&
        targetPolicy.didAvoidTargetImplementation &&
        targetPolicy.didPreserveOptInAdmissionBoundary &&
        targetPolicy.didPreserveRedactionReadinessBoundary &&
        targetPolicy.didPreserveNoWriteOutputBoundary &&
        targetPolicy.didAvoidExternalDiagnosticWrite &&
        targetPolicy.didAvoidConsoleWrite &&
        targetPolicy.didAvoidExternalSignal &&
        targetPolicy.didAvoidExternalArtifactStore &&
        targetPolicy.didAvoidRuntimeSideEffect &&
        targetPolicy.didAvoidRendererStateWrite &&
        targetPolicy.didAvoidDrawingPermission &&
        targetPolicy.didStayFullRebuildOnly &&
        targetPolicy.shouldDeferRendererLocalOutputTargetPolicy == false &&
        targetPolicy.shouldReportRendererLocalOutputTargetPolicyBlocked == false
    let targetDeferred =
        targetPolicy.didPrepareRendererLocalOutputTargetPolicy == false &&
        targetPolicy.shouldDeferRendererLocalOutputTargetPolicy &&
        targetPolicy.shouldReportRendererLocalOutputTargetPolicyBlocked == false
    let targetBlocked =
        targetPolicy.shouldReportRendererLocalOutputTargetPolicyBlocked ||
        (
            targetPolicy.didPrepareRendererLocalOutputTargetPolicy &&
                targetPolicy.isRendererLocalOutputTargetPolicyNoWrite == false &&
                targetPolicy.shouldDeferRendererLocalOutputTargetPolicy == false
        )
    let targetInconsistent = (
        targetPolicy.didPrepareRendererLocalOutputTargetPolicy &&
            (
                targetPolicy.didPreserveRendererLocalDebugOutputIntent == false ||
                targetPolicy.didKeepOutputTargetPolicyAsValueFact == false ||
                targetPolicy.didAvoidTargetImplementation == false ||
                targetPolicy.didPreserveOptInAdmissionBoundary == false ||
                targetPolicy.didPreserveRedactionReadinessBoundary == false ||
                targetPolicy.didPreserveNoWriteOutputBoundary == false ||
                targetPolicy.didAvoidExternalDiagnosticWrite == false ||
                targetPolicy.didAvoidConsoleWrite == false ||
                targetPolicy.didAvoidExternalSignal == false ||
                targetPolicy.didAvoidExternalArtifactStore == false ||
                targetPolicy.didAvoidRuntimeSideEffect == false ||
                targetPolicy.didAvoidRendererStateWrite == false ||
                targetPolicy.didAvoidDrawingPermission == false ||
                targetPolicy.didStayFullRebuildOnly == false ||
                targetPolicy.shouldDeferRendererLocalOutputTargetPolicy
            )
        ) ||
        (
            targetPolicy.shouldDeferRendererLocalOutputTargetPolicy &&
                targetPolicy.shouldReportRendererLocalOutputTargetPolicyBlocked
        )

    // target policy 阻塞或不一致时，opt-in admission 必须 fail-closed，
    // 不能伪造成运行时开关已经打开。
    if (targetBlocked || targetInconsistent) {
        return CjguiInternalRendererLocalDebugOptInAdmission(
            targetPolicy,
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

    if (targetReady) {
        return CjguiInternalRendererLocalDebugOptInAdmission(
            targetPolicy,
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

    if (targetDeferred) {
        return CjguiInternalRendererLocalDebugOptInAdmission(
            targetPolicy,
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

    return CjguiInternalRendererLocalDebugOptInAdmission(
        targetPolicy,
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

func cjguiInternalBuildRendererLocalDebugRedactionReadiness(
    optInAdmission: CjguiInternalRendererLocalDebugOptInAdmission
): CjguiInternalRendererLocalDebugRedactionReadiness {
    let optInReady = optInAdmission.didPrepareRendererLocalDebugOptInAdmission &&
        optInAdmission.isRendererLocalDebugOptInAdmissionSatisfied &&
        optInAdmission.didPreserveRendererLocalOutputTargetPolicy &&
        optInAdmission.didKeepOptInAdmissionAsValueFact &&
        optInAdmission.didAvoidRuntimeFlagRead &&
        optInAdmission.didAvoidGlobalSwitch &&
        optInAdmission.didPreserveRedactionReadinessBoundary &&
        optInAdmission.didPreserveNoWriteOutputBoundary &&
        optInAdmission.didAvoidExternalDiagnosticWrite &&
        optInAdmission.didAvoidConsoleWrite &&
        optInAdmission.didAvoidExternalSignal &&
        optInAdmission.didAvoidExternalArtifactStore &&
        optInAdmission.didAvoidRuntimeSideEffect &&
        optInAdmission.didAvoidRendererStateWrite &&
        optInAdmission.didAvoidDrawingPermission &&
        optInAdmission.didStayFullRebuildOnly &&
        optInAdmission.shouldDeferRendererLocalDebugOptInAdmission == false &&
        optInAdmission.shouldReportRendererLocalDebugOptInAdmissionBlocked == false
    let optInDeferred =
        optInAdmission.didPrepareRendererLocalDebugOptInAdmission == false &&
        optInAdmission.shouldDeferRendererLocalDebugOptInAdmission &&
        optInAdmission.shouldReportRendererLocalDebugOptInAdmissionBlocked == false
    let optInBlocked =
        optInAdmission.shouldReportRendererLocalDebugOptInAdmissionBlocked ||
        (
            optInAdmission.didPrepareRendererLocalDebugOptInAdmission &&
                optInAdmission.isRendererLocalDebugOptInAdmissionSatisfied == false &&
                optInAdmission.shouldDeferRendererLocalDebugOptInAdmission == false
        )
    let optInInconsistent = (
        optInAdmission.didPrepareRendererLocalDebugOptInAdmission &&
            (
                optInAdmission.didPreserveRendererLocalOutputTargetPolicy ==
                    false ||
                optInAdmission.didKeepOptInAdmissionAsValueFact == false ||
                optInAdmission.didAvoidRuntimeFlagRead == false ||
                optInAdmission.didAvoidGlobalSwitch == false ||
                optInAdmission.didPreserveRedactionReadinessBoundary == false ||
                optInAdmission.didPreserveNoWriteOutputBoundary == false ||
                optInAdmission.didAvoidExternalDiagnosticWrite == false ||
                optInAdmission.didAvoidConsoleWrite == false ||
                optInAdmission.didAvoidExternalSignal == false ||
                optInAdmission.didAvoidExternalArtifactStore == false ||
                optInAdmission.didAvoidRuntimeSideEffect == false ||
                optInAdmission.didAvoidRendererStateWrite == false ||
                optInAdmission.didAvoidDrawingPermission == false ||
                optInAdmission.didStayFullRebuildOnly == false ||
                optInAdmission.shouldDeferRendererLocalDebugOptInAdmission
            )
        ) ||
        (
            optInAdmission.shouldDeferRendererLocalDebugOptInAdmission &&
                optInAdmission.shouldReportRendererLocalDebugOptInAdmissionBlocked
        )

    // opt-in admission 阻塞或不一致时，redaction readiness 只能 fail-closed，
    // 不得伪造成可序列化输出。
    if (optInBlocked || optInInconsistent) {
        return CjguiInternalRendererLocalDebugRedactionReadiness(
            optInAdmission,
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

    if (optInReady) {
        return CjguiInternalRendererLocalDebugRedactionReadiness(
            optInAdmission,
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

    if (optInDeferred) {
        return CjguiInternalRendererLocalDebugRedactionReadiness(
            optInAdmission,
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

    return CjguiInternalRendererLocalDebugRedactionReadiness(
        optInAdmission,
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

func cjguiInternalBuildRendererNoWriteLocalOutputReadiness(
    redactionReadiness: CjguiInternalRendererLocalDebugRedactionReadiness
): CjguiInternalRendererNoWriteLocalOutputReadiness {
    let redactionReady =
        redactionReadiness.didPrepareRendererLocalDebugRedactionReadiness &&
        redactionReadiness.isRendererLocalDebugRedactionReady &&
        redactionReadiness.didPreserveRendererLocalDebugOptInAdmission &&
        redactionReadiness.didUseDehydratedDiagnosticFacts &&
        redactionReadiness.didAvoidOriginalPayloadCapture &&
        redactionReadiness.didAvoidActualSerializationOutput &&
        redactionReadiness.didKeepRedactionReadinessAsValueFact &&
        redactionReadiness.didPreserveNoWriteOutputBoundary &&
        redactionReadiness.didAvoidExternalDiagnosticWrite &&
        redactionReadiness.didAvoidConsoleWrite &&
        redactionReadiness.didAvoidExternalSignal &&
        redactionReadiness.didAvoidExternalArtifactStore &&
        redactionReadiness.didAvoidRuntimeSideEffect &&
        redactionReadiness.didAvoidRendererStateWrite &&
        redactionReadiness.didAvoidDrawingPermission &&
        redactionReadiness.didStayFullRebuildOnly &&
        redactionReadiness.shouldDeferRendererLocalDebugRedactionReadiness ==
            false &&
        redactionReadiness.shouldReportRendererLocalDebugRedactionReadinessBlocked ==
            false
    let redactionDeferred =
        redactionReadiness.didPrepareRendererLocalDebugRedactionReadiness ==
            false &&
        redactionReadiness.shouldDeferRendererLocalDebugRedactionReadiness &&
        redactionReadiness.shouldReportRendererLocalDebugRedactionReadinessBlocked ==
            false
    let redactionBlocked =
        redactionReadiness.shouldReportRendererLocalDebugRedactionReadinessBlocked ||
        (
            redactionReadiness.didPrepareRendererLocalDebugRedactionReadiness &&
                redactionReadiness.isRendererLocalDebugRedactionReady == false &&
                redactionReadiness.shouldDeferRendererLocalDebugRedactionReadiness ==
                    false
        )
    let redactionInconsistent = (
        redactionReadiness.didPrepareRendererLocalDebugRedactionReadiness &&
            (
                redactionReadiness.didPreserveRendererLocalDebugOptInAdmission ==
                    false ||
                redactionReadiness.didUseDehydratedDiagnosticFacts == false ||
                redactionReadiness.didAvoidOriginalPayloadCapture == false ||
                redactionReadiness.didAvoidActualSerializationOutput == false ||
                redactionReadiness.didKeepRedactionReadinessAsValueFact == false ||
                redactionReadiness.didPreserveNoWriteOutputBoundary == false ||
                redactionReadiness.didAvoidExternalDiagnosticWrite == false ||
                redactionReadiness.didAvoidConsoleWrite == false ||
                redactionReadiness.didAvoidExternalSignal == false ||
                redactionReadiness.didAvoidExternalArtifactStore == false ||
                redactionReadiness.didAvoidRuntimeSideEffect == false ||
                redactionReadiness.didAvoidRendererStateWrite == false ||
                redactionReadiness.didAvoidDrawingPermission == false ||
                redactionReadiness.didStayFullRebuildOnly == false ||
                redactionReadiness.shouldDeferRendererLocalDebugRedactionReadiness
            )
        ) ||
        (
            redactionReadiness.shouldDeferRendererLocalDebugRedactionReadiness &&
                redactionReadiness.shouldReportRendererLocalDebugRedactionReadinessBlocked
        )

    // redaction readiness 阻塞或不一致时，最终 readiness 必须 fail-closed，
    // 不能伪造成本地调试输出许可。
    if (redactionBlocked || redactionInconsistent) {
        return CjguiInternalRendererNoWriteLocalOutputReadiness(
            redactionReadiness,
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
        return CjguiInternalRendererNoWriteLocalOutputReadiness(
            redactionReadiness,
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
        return CjguiInternalRendererNoWriteLocalOutputReadiness(
            redactionReadiness,
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

    return CjguiInternalRendererNoWriteLocalOutputReadiness(
        redactionReadiness,
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

// Default draft 只生成 local debug output admission value facts；
// 它不触发真实本地调试输出，不写外部介质，不发外部信号，也不保留外部诊断产物。
func cjguiInternalExecuteDefaultRendererLocalDebugOutputAdmissionDraft():
    CjguiInternalRendererNoWriteLocalOutputReadiness {
    let noOutputDebugReadiness =
        cjguiInternalExecuteDefaultRendererLocalDebugSinkPolicyDraft()
    let intent = cjguiInternalBuildRendererLocalDebugOutputIntent(
        noOutputDebugReadiness
    )
    let targetPolicy = cjguiInternalBuildRendererLocalOutputTargetPolicy(
        intent
    )
    let optInAdmission = cjguiInternalBuildRendererLocalDebugOptInAdmission(
        targetPolicy
    )
    let redactionReadiness =
        cjguiInternalBuildRendererLocalDebugRedactionReadiness(
            optInAdmission
        )
    return cjguiInternalBuildRendererNoWriteLocalOutputReadiness(
        redactionReadiness
    )
}

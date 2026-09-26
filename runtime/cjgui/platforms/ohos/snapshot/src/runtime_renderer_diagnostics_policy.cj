package cjgui

// Owner: Renderer diagnostics policy boundary.
// Truth: 只消费 packet diagnostics result，产出 internal diagnostics policy value facts。
// Stop-line: 不写外部诊断、不发事件、不触发外部通知、不保留外部 artifact。
// Same-shape Boundary Brake: 本 owner 新增 policy / severity handling / retention hint 语义，
// 不是把 diagnostics result 再包一层 receipt / record 形态。

// Diagnostics policy 固定 future diagnostics runway 的内部策略词汇；
// 它不连接日志系统、遥测、观察者回调或公开诊断出口。
struct CjguiInternalRendererDiagnosticsPolicy {
    let diagnosticsResult: CjguiInternalRendererPacketDiagnosticsResult
    let didPrepareRendererDiagnosticsPolicy: Bool
    let isRendererDiagnosticsPolicyAllowed: Bool
    let shouldDeferRendererDiagnosticsPolicy: Bool
    let shouldReportRendererDiagnosticsPolicyBlocked: Bool
    let didPreserveRendererPacketDiagnosticsResult: Bool
    let didKeepDiagnosticsPolicyInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidDiagnosticBroadcast: Bool
    let didAvoidExternalDiagnosticNotification: Bool
    let didAvoidBackendErrorHandling: Bool
    let didAvoidExceptionMechanism: Bool
    let didAvoidExternalArtifactRetention: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        diagnosticsResult: CjguiInternalRendererPacketDiagnosticsResult,
        didPrepareRendererDiagnosticsPolicy: Bool,
        isRendererDiagnosticsPolicyAllowed: Bool,
        shouldDeferRendererDiagnosticsPolicy: Bool,
        shouldReportRendererDiagnosticsPolicyBlocked: Bool,
        didPreserveRendererPacketDiagnosticsResult: Bool,
        didKeepDiagnosticsPolicyInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidDiagnosticBroadcast: Bool,
        didAvoidExternalDiagnosticNotification: Bool,
        didAvoidBackendErrorHandling: Bool,
        didAvoidExceptionMechanism: Bool,
        didAvoidExternalArtifactRetention: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.diagnosticsResult = diagnosticsResult
        this.didPrepareRendererDiagnosticsPolicy = didPrepareRendererDiagnosticsPolicy
        this.isRendererDiagnosticsPolicyAllowed = isRendererDiagnosticsPolicyAllowed
        this.shouldDeferRendererDiagnosticsPolicy = shouldDeferRendererDiagnosticsPolicy
        this.shouldReportRendererDiagnosticsPolicyBlocked =
            shouldReportRendererDiagnosticsPolicyBlocked
        this.didPreserveRendererPacketDiagnosticsResult =
            didPreserveRendererPacketDiagnosticsResult
        this.didKeepDiagnosticsPolicyInternalOnly = didKeepDiagnosticsPolicyInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidDiagnosticBroadcast = didAvoidDiagnosticBroadcast
        this.didAvoidExternalDiagnosticNotification = didAvoidExternalDiagnosticNotification
        this.didAvoidBackendErrorHandling = didAvoidBackendErrorHandling
        this.didAvoidExceptionMechanism = didAvoidExceptionMechanism
        this.didAvoidExternalArtifactRetention = didAvoidExternalArtifactRetention
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Severity handling policy 只说明 severity facts 的内部处理方式；
// 它不执行动作、不写外部介质，也不升级为错误处理系统。
struct CjguiInternalRendererDiagnosticSeverityHandlingPolicy {
    let policy: CjguiInternalRendererDiagnosticsPolicy
    let didPrepareRendererDiagnosticSeverityHandlingPolicy: Bool
    let isRendererDiagnosticSeverityHandledInternally: Bool
    let shouldDeferRendererDiagnosticSeverityHandlingPolicy: Bool
    let shouldReportRendererDiagnosticSeverityHandlingPolicyBlocked: Bool
    let didPreserveRendererDiagnosticsPolicy: Bool
    let didAvoidSeverityActionSideEffect: Bool
    let didKeepSeverityHandlingInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidDiagnosticBroadcast: Bool
    let didAvoidExternalDiagnosticNotification: Bool
    let didAvoidBackendErrorHandling: Bool
    let didAvoidExceptionMechanism: Bool
    let didAvoidExternalArtifactRetention: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        policy: CjguiInternalRendererDiagnosticsPolicy,
        didPrepareRendererDiagnosticSeverityHandlingPolicy: Bool,
        isRendererDiagnosticSeverityHandledInternally: Bool,
        shouldDeferRendererDiagnosticSeverityHandlingPolicy: Bool,
        shouldReportRendererDiagnosticSeverityHandlingPolicyBlocked: Bool,
        didPreserveRendererDiagnosticsPolicy: Bool,
        didAvoidSeverityActionSideEffect: Bool,
        didKeepSeverityHandlingInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidDiagnosticBroadcast: Bool,
        didAvoidExternalDiagnosticNotification: Bool,
        didAvoidBackendErrorHandling: Bool,
        didAvoidExceptionMechanism: Bool,
        didAvoidExternalArtifactRetention: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.policy = policy
        this.didPrepareRendererDiagnosticSeverityHandlingPolicy =
            didPrepareRendererDiagnosticSeverityHandlingPolicy
        this.isRendererDiagnosticSeverityHandledInternally =
            isRendererDiagnosticSeverityHandledInternally
        this.shouldDeferRendererDiagnosticSeverityHandlingPolicy =
            shouldDeferRendererDiagnosticSeverityHandlingPolicy
        this.shouldReportRendererDiagnosticSeverityHandlingPolicyBlocked =
            shouldReportRendererDiagnosticSeverityHandlingPolicyBlocked
        this.didPreserveRendererDiagnosticsPolicy = didPreserveRendererDiagnosticsPolicy
        this.didAvoidSeverityActionSideEffect = didAvoidSeverityActionSideEffect
        this.didKeepSeverityHandlingInternalOnly = didKeepSeverityHandlingInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidDiagnosticBroadcast = didAvoidDiagnosticBroadcast
        this.didAvoidExternalDiagnosticNotification = didAvoidExternalDiagnosticNotification
        this.didAvoidBackendErrorHandling = didAvoidBackendErrorHandling
        this.didAvoidExceptionMechanism = didAvoidExceptionMechanism
        this.didAvoidExternalArtifactRetention = didAvoidExternalArtifactRetention
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Retention hint 只描述内部诊断 facts 是否允许外部保留；
// 当前默认禁止外部 artifact 保留，且不产生任何 I/O side effect。
struct CjguiInternalRendererDiagnosticRetentionHint {
    let severityHandlingPolicy: CjguiInternalRendererDiagnosticSeverityHandlingPolicy
    let didPrepareRendererDiagnosticRetentionHint: Bool
    let isExternalDiagnosticArtifactRetentionDisabled: Bool
    let shouldDeferRendererDiagnosticRetentionHint: Bool
    let shouldReportRendererDiagnosticRetentionHintBlocked: Bool
    let didPreserveRendererDiagnosticSeverityHandlingPolicy: Bool
    let didKeepRetentionHintInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidDiagnosticBroadcast: Bool
    let didAvoidExternalDiagnosticNotification: Bool
    let didAvoidBackendErrorHandling: Bool
    let didAvoidExceptionMechanism: Bool
    let didAvoidExternalArtifactRetention: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        severityHandlingPolicy: CjguiInternalRendererDiagnosticSeverityHandlingPolicy,
        didPrepareRendererDiagnosticRetentionHint: Bool,
        isExternalDiagnosticArtifactRetentionDisabled: Bool,
        shouldDeferRendererDiagnosticRetentionHint: Bool,
        shouldReportRendererDiagnosticRetentionHintBlocked: Bool,
        didPreserveRendererDiagnosticSeverityHandlingPolicy: Bool,
        didKeepRetentionHintInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidDiagnosticBroadcast: Bool,
        didAvoidExternalDiagnosticNotification: Bool,
        didAvoidBackendErrorHandling: Bool,
        didAvoidExceptionMechanism: Bool,
        didAvoidExternalArtifactRetention: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.severityHandlingPolicy = severityHandlingPolicy
        this.didPrepareRendererDiagnosticRetentionHint =
            didPrepareRendererDiagnosticRetentionHint
        this.isExternalDiagnosticArtifactRetentionDisabled =
            isExternalDiagnosticArtifactRetentionDisabled
        this.shouldDeferRendererDiagnosticRetentionHint =
            shouldDeferRendererDiagnosticRetentionHint
        this.shouldReportRendererDiagnosticRetentionHintBlocked =
            shouldReportRendererDiagnosticRetentionHintBlocked
        this.didPreserveRendererDiagnosticSeverityHandlingPolicy =
            didPreserveRendererDiagnosticSeverityHandlingPolicy
        this.didKeepRetentionHintInternalOnly = didKeepRetentionHintInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidDiagnosticBroadcast = didAvoidDiagnosticBroadcast
        this.didAvoidExternalDiagnosticNotification = didAvoidExternalDiagnosticNotification
        this.didAvoidBackendErrorHandling = didAvoidBackendErrorHandling
        this.didAvoidExceptionMechanism = didAvoidExceptionMechanism
        this.didAvoidExternalArtifactRetention = didAvoidExternalArtifactRetention
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Diagnostics policy result 是本 owner 的 canonical endpoint；
// ready 只表示 policy value facts 已形成，不代表可输出诊断或可执行渲染。
struct CjguiInternalRendererDiagnosticsPolicyResult {
    let retentionHint: CjguiInternalRendererDiagnosticRetentionHint
    let isRendererDiagnosticsPolicyReady: Bool
    let canFutureRendererBoundaryUseDiagnosticsPolicy: Bool
    let shouldDeferRendererDiagnosticsPolicyResult: Bool
    let shouldReportRendererDiagnosticsPolicyResultBlocked: Bool
    let didPrepareRendererDiagnosticsPolicyResult: Bool
    let didPreserveRendererDiagnosticRetentionHint: Bool
    let didKeepDiagnosticsPolicyResultInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidDiagnosticBroadcast: Bool
    let didAvoidExternalDiagnosticNotification: Bool
    let didAvoidBackendErrorHandling: Bool
    let didAvoidExceptionMechanism: Bool
    let didAvoidExternalArtifactRetention: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        retentionHint: CjguiInternalRendererDiagnosticRetentionHint,
        isRendererDiagnosticsPolicyReady: Bool,
        canFutureRendererBoundaryUseDiagnosticsPolicy: Bool,
        shouldDeferRendererDiagnosticsPolicyResult: Bool,
        shouldReportRendererDiagnosticsPolicyResultBlocked: Bool,
        didPrepareRendererDiagnosticsPolicyResult: Bool,
        didPreserveRendererDiagnosticRetentionHint: Bool,
        didKeepDiagnosticsPolicyResultInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidDiagnosticBroadcast: Bool,
        didAvoidExternalDiagnosticNotification: Bool,
        didAvoidBackendErrorHandling: Bool,
        didAvoidExceptionMechanism: Bool,
        didAvoidExternalArtifactRetention: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.retentionHint = retentionHint
        this.isRendererDiagnosticsPolicyReady = isRendererDiagnosticsPolicyReady
        this.canFutureRendererBoundaryUseDiagnosticsPolicy =
            canFutureRendererBoundaryUseDiagnosticsPolicy
        this.shouldDeferRendererDiagnosticsPolicyResult =
            shouldDeferRendererDiagnosticsPolicyResult
        this.shouldReportRendererDiagnosticsPolicyResultBlocked =
            shouldReportRendererDiagnosticsPolicyResultBlocked
        this.didPrepareRendererDiagnosticsPolicyResult =
            didPrepareRendererDiagnosticsPolicyResult
        this.didPreserveRendererDiagnosticRetentionHint =
            didPreserveRendererDiagnosticRetentionHint
        this.didKeepDiagnosticsPolicyResultInternalOnly =
            didKeepDiagnosticsPolicyResultInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidDiagnosticBroadcast = didAvoidDiagnosticBroadcast
        this.didAvoidExternalDiagnosticNotification = didAvoidExternalDiagnosticNotification
        this.didAvoidBackendErrorHandling = didAvoidBackendErrorHandling
        this.didAvoidExceptionMechanism = didAvoidExceptionMechanism
        this.didAvoidExternalArtifactRetention = didAvoidExternalArtifactRetention
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererDiagnosticsPolicy(
    diagnosticsResult: CjguiInternalRendererPacketDiagnosticsResult
): CjguiInternalRendererDiagnosticsPolicy {
    let diagnosticsReady = diagnosticsResult.isRendererPacketDiagnosticsReady &&
        diagnosticsResult.canFutureRendererBoundaryUsePacketDiagnostics &&
        diagnosticsResult.didPrepareRendererPacketDiagnosticsResult &&
        diagnosticsResult.didPreserveRendererPacketDiagnosticEvidence &&
        diagnosticsResult.didKeepDiagnosticsResultInternalOnly &&
        diagnosticsResult.didAvoidExternalDiagnosticWrite &&
        diagnosticsResult.didAvoidDiagnosticPublication &&
        diagnosticsResult.didAvoidExternalDiagnosticNotification &&
        diagnosticsResult.didAvoidBackendErrorHandling &&
        diagnosticsResult.didAvoidRendererStateWrite &&
        diagnosticsResult.didAvoidDrawingPermission &&
        diagnosticsResult.didStayFullRebuildOnly &&
        diagnosticsResult.shouldDeferRendererPacketDiagnosticsResult == false &&
        diagnosticsResult.shouldReportRendererPacketDiagnosticsResultBlocked == false
    let diagnosticsDeferred = diagnosticsResult.isRendererPacketDiagnosticsReady == false &&
        diagnosticsResult.canFutureRendererBoundaryUsePacketDiagnostics == false &&
        diagnosticsResult.shouldDeferRendererPacketDiagnosticsResult &&
        diagnosticsResult.shouldReportRendererPacketDiagnosticsResultBlocked == false &&
        diagnosticsResult.didKeepDiagnosticsResultInternalOnly &&
        diagnosticsResult.didAvoidExternalDiagnosticWrite &&
        diagnosticsResult.didAvoidDiagnosticPublication &&
        diagnosticsResult.didAvoidExternalDiagnosticNotification &&
        diagnosticsResult.didAvoidBackendErrorHandling &&
        diagnosticsResult.didAvoidRendererStateWrite &&
        diagnosticsResult.didAvoidDrawingPermission &&
        diagnosticsResult.didStayFullRebuildOnly
    let diagnosticsInconsistent = (
        diagnosticsResult.isRendererPacketDiagnosticsReady &&
            (
                diagnosticsResult.canFutureRendererBoundaryUsePacketDiagnostics == false ||
                diagnosticsResult.didPrepareRendererPacketDiagnosticsResult == false ||
                diagnosticsResult.didPreserveRendererPacketDiagnosticEvidence == false ||
                diagnosticsResult.didKeepDiagnosticsResultInternalOnly == false ||
                diagnosticsResult.didAvoidExternalDiagnosticWrite == false ||
                diagnosticsResult.didAvoidDiagnosticPublication == false ||
                diagnosticsResult.didAvoidExternalDiagnosticNotification == false ||
                diagnosticsResult.didAvoidBackendErrorHandling == false ||
                diagnosticsResult.didAvoidRendererStateWrite == false ||
                diagnosticsResult.didAvoidDrawingPermission == false ||
                diagnosticsResult.didStayFullRebuildOnly == false ||
                diagnosticsResult.shouldDeferRendererPacketDiagnosticsResult ||
                diagnosticsResult.shouldReportRendererPacketDiagnosticsResultBlocked
            )
        ) ||
        (
            diagnosticsResult.canFutureRendererBoundaryUsePacketDiagnostics &&
                diagnosticsResult.isRendererPacketDiagnosticsReady == false
        ) ||
        (
            diagnosticsResult.shouldDeferRendererPacketDiagnosticsResult &&
                diagnosticsResult.shouldReportRendererPacketDiagnosticsResultBlocked
        )

    // diagnostics result 阻塞或不一致时，policy 只能 fail-closed，不能伪造成可用策略。
    if (
        diagnosticsResult.shouldReportRendererPacketDiagnosticsResultBlocked ||
        diagnosticsInconsistent
    ) {
        return CjguiInternalRendererDiagnosticsPolicy(
            diagnosticsResult,
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

    if (diagnosticsReady) {
        return CjguiInternalRendererDiagnosticsPolicy(
            diagnosticsResult,
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
            true
        )
    }

    if (diagnosticsDeferred) {
        return CjguiInternalRendererDiagnosticsPolicy(
            diagnosticsResult,
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
            true
        )
    }

    return CjguiInternalRendererDiagnosticsPolicy(
        diagnosticsResult,
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

func cjguiInternalBuildRendererDiagnosticSeverityHandlingPolicy(
    policy: CjguiInternalRendererDiagnosticsPolicy
): CjguiInternalRendererDiagnosticSeverityHandlingPolicy {
    let policyReady = policy.didPrepareRendererDiagnosticsPolicy &&
        policy.isRendererDiagnosticsPolicyAllowed &&
        policy.didPreserveRendererPacketDiagnosticsResult &&
        policy.didKeepDiagnosticsPolicyInternalOnly &&
        policy.didAvoidExternalDiagnosticWrite &&
        policy.didAvoidDiagnosticBroadcast &&
        policy.didAvoidExternalDiagnosticNotification &&
        policy.didAvoidBackendErrorHandling &&
        policy.didAvoidExceptionMechanism &&
        policy.didAvoidExternalArtifactRetention &&
        policy.didAvoidRendererStateWrite &&
        policy.didAvoidDrawingPermission &&
        policy.didStayFullRebuildOnly &&
        policy.shouldDeferRendererDiagnosticsPolicy == false &&
        policy.shouldReportRendererDiagnosticsPolicyBlocked == false
    let policyDeferred = policy.didPrepareRendererDiagnosticsPolicy == false &&
        policy.shouldDeferRendererDiagnosticsPolicy &&
        policy.shouldReportRendererDiagnosticsPolicyBlocked == false
    let policyBlocked = policy.shouldReportRendererDiagnosticsPolicyBlocked ||
        (
            policy.didPrepareRendererDiagnosticsPolicy &&
                policy.isRendererDiagnosticsPolicyAllowed == false &&
                policy.shouldDeferRendererDiagnosticsPolicy == false
        )
    let policyInconsistent = (
        policy.didPrepareRendererDiagnosticsPolicy &&
            (
                policy.didPreserveRendererPacketDiagnosticsResult == false ||
                policy.didKeepDiagnosticsPolicyInternalOnly == false ||
                policy.didAvoidExternalDiagnosticWrite == false ||
                policy.didAvoidDiagnosticBroadcast == false ||
                policy.didAvoidExternalDiagnosticNotification == false ||
                policy.didAvoidBackendErrorHandling == false ||
                policy.didAvoidExceptionMechanism == false ||
                policy.didAvoidExternalArtifactRetention == false ||
                policy.didAvoidRendererStateWrite == false ||
                policy.didAvoidDrawingPermission == false ||
                policy.didStayFullRebuildOnly == false ||
                policy.shouldDeferRendererDiagnosticsPolicy
            )
        ) ||
        (
            policy.shouldDeferRendererDiagnosticsPolicy &&
                policy.shouldReportRendererDiagnosticsPolicyBlocked
        )

    // policy 已阻塞或不一致时，severity handling 不执行任何动作，只保留内部 facts。
    if (policyBlocked || policyInconsistent) {
        return CjguiInternalRendererDiagnosticSeverityHandlingPolicy(
            policy,
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

    if (policyReady) {
        return CjguiInternalRendererDiagnosticSeverityHandlingPolicy(
            policy,
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

    if (policyDeferred) {
        return CjguiInternalRendererDiagnosticSeverityHandlingPolicy(
            policy,
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
            true
        )
    }

    return CjguiInternalRendererDiagnosticSeverityHandlingPolicy(
        policy,
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

func cjguiInternalBuildRendererDiagnosticRetentionHint(
    severityHandlingPolicy: CjguiInternalRendererDiagnosticSeverityHandlingPolicy
): CjguiInternalRendererDiagnosticRetentionHint {
    let severityReady =
        severityHandlingPolicy.didPrepareRendererDiagnosticSeverityHandlingPolicy &&
        severityHandlingPolicy.isRendererDiagnosticSeverityHandledInternally &&
        severityHandlingPolicy.didPreserveRendererDiagnosticsPolicy &&
        severityHandlingPolicy.didAvoidSeverityActionSideEffect &&
        severityHandlingPolicy.didKeepSeverityHandlingInternalOnly &&
        severityHandlingPolicy.didAvoidExternalDiagnosticWrite &&
        severityHandlingPolicy.didAvoidDiagnosticBroadcast &&
        severityHandlingPolicy.didAvoidExternalDiagnosticNotification &&
        severityHandlingPolicy.didAvoidBackendErrorHandling &&
        severityHandlingPolicy.didAvoidExceptionMechanism &&
        severityHandlingPolicy.didAvoidExternalArtifactRetention &&
        severityHandlingPolicy.didAvoidRendererStateWrite &&
        severityHandlingPolicy.didAvoidDrawingPermission &&
        severityHandlingPolicy.didStayFullRebuildOnly &&
        severityHandlingPolicy.shouldDeferRendererDiagnosticSeverityHandlingPolicy == false &&
        severityHandlingPolicy.shouldReportRendererDiagnosticSeverityHandlingPolicyBlocked ==
            false
    let severityDeferred =
        severityHandlingPolicy.didPrepareRendererDiagnosticSeverityHandlingPolicy == false &&
        severityHandlingPolicy.shouldDeferRendererDiagnosticSeverityHandlingPolicy &&
        severityHandlingPolicy.shouldReportRendererDiagnosticSeverityHandlingPolicyBlocked ==
            false
    let severityBlocked =
        severityHandlingPolicy.shouldReportRendererDiagnosticSeverityHandlingPolicyBlocked ||
        (
            severityHandlingPolicy.didPrepareRendererDiagnosticSeverityHandlingPolicy &&
                severityHandlingPolicy.isRendererDiagnosticSeverityHandledInternally == false &&
                severityHandlingPolicy.shouldDeferRendererDiagnosticSeverityHandlingPolicy ==
                    false
        )
    let severityInconsistent = (
        severityHandlingPolicy.didPrepareRendererDiagnosticSeverityHandlingPolicy &&
            (
                severityHandlingPolicy.didPreserveRendererDiagnosticsPolicy == false ||
                severityHandlingPolicy.didAvoidSeverityActionSideEffect == false ||
                severityHandlingPolicy.didKeepSeverityHandlingInternalOnly == false ||
                severityHandlingPolicy.didAvoidExternalDiagnosticWrite == false ||
                severityHandlingPolicy.didAvoidDiagnosticBroadcast == false ||
                severityHandlingPolicy.didAvoidExternalDiagnosticNotification == false ||
                severityHandlingPolicy.didAvoidBackendErrorHandling == false ||
                severityHandlingPolicy.didAvoidExceptionMechanism == false ||
                severityHandlingPolicy.didAvoidExternalArtifactRetention == false ||
                severityHandlingPolicy.didAvoidRendererStateWrite == false ||
                severityHandlingPolicy.didAvoidDrawingPermission == false ||
                severityHandlingPolicy.didStayFullRebuildOnly == false ||
                severityHandlingPolicy.shouldDeferRendererDiagnosticSeverityHandlingPolicy
            )
        ) ||
        (
            severityHandlingPolicy.shouldDeferRendererDiagnosticSeverityHandlingPolicy &&
                severityHandlingPolicy.shouldReportRendererDiagnosticSeverityHandlingPolicyBlocked
        )

    // severity handling 阻塞或不一致时，retention hint 必须保持外部保留关闭。
    if (severityBlocked || severityInconsistent) {
        return CjguiInternalRendererDiagnosticRetentionHint(
            severityHandlingPolicy,
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
            true
        )
    }

    if (severityReady) {
        return CjguiInternalRendererDiagnosticRetentionHint(
            severityHandlingPolicy,
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
            true
        )
    }

    if (severityDeferred) {
        return CjguiInternalRendererDiagnosticRetentionHint(
            severityHandlingPolicy,
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
            true
        )
    }

    return CjguiInternalRendererDiagnosticRetentionHint(
        severityHandlingPolicy,
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
        true
    )
}

func cjguiInternalBuildRendererDiagnosticsPolicyResult(
    retentionHint: CjguiInternalRendererDiagnosticRetentionHint
): CjguiInternalRendererDiagnosticsPolicyResult {
    let policyResultReady = retentionHint.didPrepareRendererDiagnosticRetentionHint &&
        retentionHint.isExternalDiagnosticArtifactRetentionDisabled &&
        retentionHint.didPreserveRendererDiagnosticSeverityHandlingPolicy &&
        retentionHint.didKeepRetentionHintInternalOnly &&
        retentionHint.didAvoidExternalDiagnosticWrite &&
        retentionHint.didAvoidDiagnosticBroadcast &&
        retentionHint.didAvoidExternalDiagnosticNotification &&
        retentionHint.didAvoidBackendErrorHandling &&
        retentionHint.didAvoidExceptionMechanism &&
        retentionHint.didAvoidExternalArtifactRetention &&
        retentionHint.didAvoidRendererStateWrite &&
        retentionHint.didAvoidDrawingPermission &&
        retentionHint.didStayFullRebuildOnly &&
        retentionHint.shouldDeferRendererDiagnosticRetentionHint == false &&
        retentionHint.shouldReportRendererDiagnosticRetentionHintBlocked == false
    let policyResultDeferred = retentionHint.didPrepareRendererDiagnosticRetentionHint ==
        false &&
        retentionHint.shouldDeferRendererDiagnosticRetentionHint &&
        retentionHint.shouldReportRendererDiagnosticRetentionHintBlocked == false
    let policyResultInconsistent = (
        retentionHint.didPrepareRendererDiagnosticRetentionHint &&
            (
                retentionHint.isExternalDiagnosticArtifactRetentionDisabled == false ||
                retentionHint.didPreserveRendererDiagnosticSeverityHandlingPolicy == false ||
                retentionHint.didKeepRetentionHintInternalOnly == false ||
                retentionHint.didAvoidExternalDiagnosticWrite == false ||
                retentionHint.didAvoidDiagnosticBroadcast == false ||
                retentionHint.didAvoidExternalDiagnosticNotification == false ||
                retentionHint.didAvoidBackendErrorHandling == false ||
                retentionHint.didAvoidExceptionMechanism == false ||
                retentionHint.didAvoidExternalArtifactRetention == false ||
                retentionHint.didAvoidRendererStateWrite == false ||
                retentionHint.didAvoidDrawingPermission == false ||
                retentionHint.didStayFullRebuildOnly == false ||
                retentionHint.shouldDeferRendererDiagnosticRetentionHint
            )
        ) ||
        (
            retentionHint.shouldDeferRendererDiagnosticRetentionHint &&
                retentionHint.shouldReportRendererDiagnosticRetentionHintBlocked
        )

    // policy result 只表示 internal policy facts；blocked / inconsistent 必须 fail-closed。
    if (
        retentionHint.shouldReportRendererDiagnosticRetentionHintBlocked ||
        policyResultInconsistent
    ) {
        return CjguiInternalRendererDiagnosticsPolicyResult(
            retentionHint,
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
            true
        )
    }

    if (policyResultReady) {
        return CjguiInternalRendererDiagnosticsPolicyResult(
            retentionHint,
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

    if (policyResultDeferred) {
        return CjguiInternalRendererDiagnosticsPolicyResult(
            retentionHint,
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

    return CjguiInternalRendererDiagnosticsPolicyResult(
        retentionHint,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererDiagnosticsPolicyDraft(
): CjguiInternalRendererDiagnosticsPolicyResult {
    // 默认 diagnostics policy draft 只串联 diagnostics result -> policy / severity handling /
    // retention hint / result facts；它不写外部诊断、不发事件、不保留外部 artifact。
    let diagnosticsResult = cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft()
    let policy = cjguiInternalBuildRendererDiagnosticsPolicy(diagnosticsResult)
    let severityHandlingPolicy = cjguiInternalBuildRendererDiagnosticSeverityHandlingPolicy(
        policy
    )
    let retentionHint = cjguiInternalBuildRendererDiagnosticRetentionHint(
        severityHandlingPolicy
    )
    return cjguiInternalBuildRendererDiagnosticsPolicyResult(retentionHint)
}

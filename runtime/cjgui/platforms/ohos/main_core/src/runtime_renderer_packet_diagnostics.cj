package cjgui

// Owner: Renderer packet diagnostics boundary.
// Truth: 只消费 packet error taxonomy result，产出 internal diagnostics value facts。
// Stop-line: 不写外部诊断、不发布事件、不触发外部通知、不暴露公开诊断、不进入后端错误处理。
// Same-shape Boundary Brake: 本 owner 新增 diagnostics summary / severity / evidence 语义，
// 不新增 receipt / record / publication 形态的薄尾巴。

// Diagnostics summary 只把 taxonomy result 概括为内部诊断摘要；
// 它不是外部诊断写入系统，也不是公开诊断接口。
struct CjguiInternalRendererPacketDiagnosticsSummary {
    let taxonomyResult: CjguiInternalRendererPacketErrorTaxonomyResult
    let didPrepareRendererPacketDiagnosticsSummary: Bool
    let isRendererPacketDiagnosticsClean: Bool
    let shouldDeferRendererPacketDiagnosticsSummary: Bool
    let shouldReportRendererPacketDiagnosticsSummaryBlocked: Bool
    let didPreserveRendererPacketErrorTaxonomyResult: Bool
    let didSummarizeNoIssueDiagnostics: Bool
    let didKeepDiagnosticsSummaryInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidDiagnosticPublication: Bool
    let didAvoidExternalDiagnosticNotification: Bool
    let didAvoidBackendErrorHandling: Bool

    init(
        taxonomyResult: CjguiInternalRendererPacketErrorTaxonomyResult,
        didPrepareRendererPacketDiagnosticsSummary: Bool,
        isRendererPacketDiagnosticsClean: Bool,
        shouldDeferRendererPacketDiagnosticsSummary: Bool,
        shouldReportRendererPacketDiagnosticsSummaryBlocked: Bool,
        didPreserveRendererPacketErrorTaxonomyResult: Bool,
        didSummarizeNoIssueDiagnostics: Bool,
        didKeepDiagnosticsSummaryInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidDiagnosticPublication: Bool,
        didAvoidExternalDiagnosticNotification: Bool,
        didAvoidBackendErrorHandling: Bool
    ) {
        this.taxonomyResult = taxonomyResult
        this.didPrepareRendererPacketDiagnosticsSummary = didPrepareRendererPacketDiagnosticsSummary
        this.isRendererPacketDiagnosticsClean = isRendererPacketDiagnosticsClean
        this.shouldDeferRendererPacketDiagnosticsSummary = shouldDeferRendererPacketDiagnosticsSummary
        this.shouldReportRendererPacketDiagnosticsSummaryBlocked =
            shouldReportRendererPacketDiagnosticsSummaryBlocked
        this.didPreserveRendererPacketErrorTaxonomyResult =
            didPreserveRendererPacketErrorTaxonomyResult
        this.didSummarizeNoIssueDiagnostics = didSummarizeNoIssueDiagnostics
        this.didKeepDiagnosticsSummaryInternalOnly = didKeepDiagnosticsSummaryInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidDiagnosticPublication = didAvoidDiagnosticPublication
        this.didAvoidExternalDiagnosticNotification = didAvoidExternalDiagnosticNotification
        this.didAvoidBackendErrorHandling = didAvoidBackendErrorHandling
    }
}

// Diagnostic severity 只给内部诊断摘要贴 value-style 严重度 facts；
// severity 为 none 不代表任何后端状态或绘制许可。
struct CjguiInternalRendererPacketDiagnosticSeverity {
    let summary: CjguiInternalRendererPacketDiagnosticsSummary
    let didPrepareRendererPacketDiagnosticSeverity: Bool
    let isRendererPacketDiagnosticSeverityNone: Bool
    let shouldDeferRendererPacketDiagnosticSeverity: Bool
    let shouldReportRendererPacketDiagnosticSeverityBlocked: Bool
    let didPreserveRendererPacketDiagnosticsSummary: Bool
    let didClassifyDiagnosticsSeverityAsValueFact: Bool
    let didKeepSeverityInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidDiagnosticPublication: Bool
    let didAvoidExternalDiagnosticNotification: Bool
    let didAvoidBackendErrorHandling: Bool

    init(
        summary: CjguiInternalRendererPacketDiagnosticsSummary,
        didPrepareRendererPacketDiagnosticSeverity: Bool,
        isRendererPacketDiagnosticSeverityNone: Bool,
        shouldDeferRendererPacketDiagnosticSeverity: Bool,
        shouldReportRendererPacketDiagnosticSeverityBlocked: Bool,
        didPreserveRendererPacketDiagnosticsSummary: Bool,
        didClassifyDiagnosticsSeverityAsValueFact: Bool,
        didKeepSeverityInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidDiagnosticPublication: Bool,
        didAvoidExternalDiagnosticNotification: Bool,
        didAvoidBackendErrorHandling: Bool
    ) {
        this.summary = summary
        this.didPrepareRendererPacketDiagnosticSeverity = didPrepareRendererPacketDiagnosticSeverity
        this.isRendererPacketDiagnosticSeverityNone = isRendererPacketDiagnosticSeverityNone
        this.shouldDeferRendererPacketDiagnosticSeverity = shouldDeferRendererPacketDiagnosticSeverity
        this.shouldReportRendererPacketDiagnosticSeverityBlocked =
            shouldReportRendererPacketDiagnosticSeverityBlocked
        this.didPreserveRendererPacketDiagnosticsSummary =
            didPreserveRendererPacketDiagnosticsSummary
        this.didClassifyDiagnosticsSeverityAsValueFact = didClassifyDiagnosticsSeverityAsValueFact
        this.didKeepSeverityInternalOnly = didKeepSeverityInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidDiagnosticPublication = didAvoidDiagnosticPublication
        this.didAvoidExternalDiagnosticNotification = didAvoidExternalDiagnosticNotification
        this.didAvoidBackendErrorHandling = didAvoidBackendErrorHandling
    }
}

// Diagnostic evidence 只保留 taxonomy / blocked / degraded facts 作为内部证据；
// 它不发布事件、不调用观察者，也不触发后端错误处理。
struct CjguiInternalRendererPacketDiagnosticEvidence {
    let severity: CjguiInternalRendererPacketDiagnosticSeverity
    let didPrepareRendererPacketDiagnosticEvidence: Bool
    let shouldDeferRendererPacketDiagnosticEvidence: Bool
    let shouldReportRendererPacketDiagnosticEvidenceBlocked: Bool
    let didPreserveRendererPacketDiagnosticSeverity: Bool
    let didPreserveRendererPacketTaxonomyEvidence: Bool
    let didPreserveFailureTaxonomyFacts: Bool
    let didPreserveDegradedReasonFacts: Bool
    let didPreserveBlockedReasonFacts: Bool
    let didKeepEvidenceInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidDiagnosticPublication: Bool
    let didAvoidExternalDiagnosticNotification: Bool
    let didAvoidBackendErrorHandling: Bool

    init(
        severity: CjguiInternalRendererPacketDiagnosticSeverity,
        didPrepareRendererPacketDiagnosticEvidence: Bool,
        shouldDeferRendererPacketDiagnosticEvidence: Bool,
        shouldReportRendererPacketDiagnosticEvidenceBlocked: Bool,
        didPreserveRendererPacketDiagnosticSeverity: Bool,
        didPreserveRendererPacketTaxonomyEvidence: Bool,
        didPreserveFailureTaxonomyFacts: Bool,
        didPreserveDegradedReasonFacts: Bool,
        didPreserveBlockedReasonFacts: Bool,
        didKeepEvidenceInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidDiagnosticPublication: Bool,
        didAvoidExternalDiagnosticNotification: Bool,
        didAvoidBackendErrorHandling: Bool
    ) {
        this.severity = severity
        this.didPrepareRendererPacketDiagnosticEvidence = didPrepareRendererPacketDiagnosticEvidence
        this.shouldDeferRendererPacketDiagnosticEvidence = shouldDeferRendererPacketDiagnosticEvidence
        this.shouldReportRendererPacketDiagnosticEvidenceBlocked =
            shouldReportRendererPacketDiagnosticEvidenceBlocked
        this.didPreserveRendererPacketDiagnosticSeverity =
            didPreserveRendererPacketDiagnosticSeverity
        this.didPreserveRendererPacketTaxonomyEvidence =
            didPreserveRendererPacketTaxonomyEvidence
        this.didPreserveFailureTaxonomyFacts = didPreserveFailureTaxonomyFacts
        this.didPreserveDegradedReasonFacts = didPreserveDegradedReasonFacts
        this.didPreserveBlockedReasonFacts = didPreserveBlockedReasonFacts
        this.didKeepEvidenceInternalOnly = didKeepEvidenceInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidDiagnosticPublication = didAvoidDiagnosticPublication
        this.didAvoidExternalDiagnosticNotification = didAvoidExternalDiagnosticNotification
        this.didAvoidBackendErrorHandling = didAvoidBackendErrorHandling
    }
}

// Diagnostics result 是本 owner 的 canonical endpoint；
// 它只表达内部诊断 value facts，不写外部诊断、不发布事件、不触发外部通知。
struct CjguiInternalRendererPacketDiagnosticsResult {
    let evidence: CjguiInternalRendererPacketDiagnosticEvidence
    let isRendererPacketDiagnosticsReady: Bool
    let canFutureRendererBoundaryUsePacketDiagnostics: Bool
    let shouldDeferRendererPacketDiagnosticsResult: Bool
    let shouldReportRendererPacketDiagnosticsResultBlocked: Bool
    let didPrepareRendererPacketDiagnosticsResult: Bool
    let didPreserveRendererPacketDiagnosticEvidence: Bool
    let didKeepDiagnosticsResultInternalOnly: Bool
    let didAvoidExternalDiagnosticWrite: Bool
    let didAvoidDiagnosticPublication: Bool
    let didAvoidExternalDiagnosticNotification: Bool
    let didAvoidBackendErrorHandling: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        evidence: CjguiInternalRendererPacketDiagnosticEvidence,
        isRendererPacketDiagnosticsReady: Bool,
        canFutureRendererBoundaryUsePacketDiagnostics: Bool,
        shouldDeferRendererPacketDiagnosticsResult: Bool,
        shouldReportRendererPacketDiagnosticsResultBlocked: Bool,
        didPrepareRendererPacketDiagnosticsResult: Bool,
        didPreserveRendererPacketDiagnosticEvidence: Bool,
        didKeepDiagnosticsResultInternalOnly: Bool,
        didAvoidExternalDiagnosticWrite: Bool,
        didAvoidDiagnosticPublication: Bool,
        didAvoidExternalDiagnosticNotification: Bool,
        didAvoidBackendErrorHandling: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.evidence = evidence
        this.isRendererPacketDiagnosticsReady = isRendererPacketDiagnosticsReady
        this.canFutureRendererBoundaryUsePacketDiagnostics =
            canFutureRendererBoundaryUsePacketDiagnostics
        this.shouldDeferRendererPacketDiagnosticsResult = shouldDeferRendererPacketDiagnosticsResult
        this.shouldReportRendererPacketDiagnosticsResultBlocked =
            shouldReportRendererPacketDiagnosticsResultBlocked
        this.didPrepareRendererPacketDiagnosticsResult =
            didPrepareRendererPacketDiagnosticsResult
        this.didPreserveRendererPacketDiagnosticEvidence =
            didPreserveRendererPacketDiagnosticEvidence
        this.didKeepDiagnosticsResultInternalOnly = didKeepDiagnosticsResultInternalOnly
        this.didAvoidExternalDiagnosticWrite = didAvoidExternalDiagnosticWrite
        this.didAvoidDiagnosticPublication = didAvoidDiagnosticPublication
        this.didAvoidExternalDiagnosticNotification = didAvoidExternalDiagnosticNotification
        this.didAvoidBackendErrorHandling = didAvoidBackendErrorHandling
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererPacketDiagnosticsSummary(
    taxonomyResult: CjguiInternalRendererPacketErrorTaxonomyResult
): CjguiInternalRendererPacketDiagnosticsSummary {
    let taxonomyReady = taxonomyResult.isRendererPacketErrorTaxonomyReady &&
        taxonomyResult.canFutureRendererBoundaryUsePacketErrorTaxonomy &&
        taxonomyResult.didRecordRendererPacketErrorTaxonomyResult &&
        taxonomyResult.didPreserveRendererPacketBlockedReason &&
        taxonomyResult.didKeepErrorTaxonomyInternalOnly &&
        taxonomyResult.didAvoidExceptionThrowing &&
        taxonomyResult.didAvoidErrorPublication &&
        taxonomyResult.didAvoidExternalNotification &&
        taxonomyResult.didAvoidRendererStateWrite &&
        taxonomyResult.didAvoidDrawingPermission &&
        taxonomyResult.didStayFullRebuildOnly &&
        taxonomyResult.shouldDeferRendererPacketErrorTaxonomyResult == false &&
        taxonomyResult.shouldReportRendererPacketErrorTaxonomyResultBlocked == false
    let taxonomyDeferred = taxonomyResult.isRendererPacketErrorTaxonomyReady == false &&
        taxonomyResult.canFutureRendererBoundaryUsePacketErrorTaxonomy == false &&
        taxonomyResult.shouldDeferRendererPacketErrorTaxonomyResult &&
        taxonomyResult.shouldReportRendererPacketErrorTaxonomyResultBlocked == false &&
        taxonomyResult.didKeepErrorTaxonomyInternalOnly &&
        taxonomyResult.didAvoidExceptionThrowing &&
        taxonomyResult.didAvoidErrorPublication &&
        taxonomyResult.didAvoidExternalNotification &&
        taxonomyResult.didAvoidRendererStateWrite &&
        taxonomyResult.didAvoidDrawingPermission &&
        taxonomyResult.didStayFullRebuildOnly
    let taxonomyInconsistent = (
        taxonomyResult.isRendererPacketErrorTaxonomyReady &&
            (
                taxonomyResult.canFutureRendererBoundaryUsePacketErrorTaxonomy == false ||
                taxonomyResult.didRecordRendererPacketErrorTaxonomyResult == false ||
                taxonomyResult.didPreserveRendererPacketBlockedReason == false ||
                taxonomyResult.didKeepErrorTaxonomyInternalOnly == false ||
                taxonomyResult.didAvoidExceptionThrowing == false ||
                taxonomyResult.didAvoidErrorPublication == false ||
                taxonomyResult.didAvoidExternalNotification == false ||
                taxonomyResult.didAvoidRendererStateWrite == false ||
                taxonomyResult.didAvoidDrawingPermission == false ||
                taxonomyResult.didStayFullRebuildOnly == false ||
                taxonomyResult.shouldDeferRendererPacketErrorTaxonomyResult ||
                taxonomyResult.shouldReportRendererPacketErrorTaxonomyResultBlocked
            )
        ) ||
        (
            taxonomyResult.canFutureRendererBoundaryUsePacketErrorTaxonomy &&
                taxonomyResult.isRendererPacketErrorTaxonomyReady == false
        ) ||
        (
            taxonomyResult.shouldDeferRendererPacketErrorTaxonomyResult &&
                taxonomyResult.shouldReportRendererPacketErrorTaxonomyResultBlocked
        )

    // taxonomy result 阻塞或不一致时，diagnostics summary 只能 fail-closed 记录内部 facts。
    if (
        taxonomyResult.shouldReportRendererPacketErrorTaxonomyResultBlocked ||
        taxonomyInconsistent
    ) {
        return CjguiInternalRendererPacketDiagnosticsSummary(
            taxonomyResult,
            true,
            false,
            false,
            true,
            true,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (taxonomyReady) {
        return CjguiInternalRendererPacketDiagnosticsSummary(
            taxonomyResult,
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
            true
        )
    }

    if (taxonomyDeferred) {
        return CjguiInternalRendererPacketDiagnosticsSummary(
            taxonomyResult,
            false,
            false,
            true,
            false,
            true,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererPacketDiagnosticsSummary(
        taxonomyResult,
        true,
        false,
        false,
        true,
        true,
        false,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPacketDiagnosticSeverity(
    summary: CjguiInternalRendererPacketDiagnosticsSummary
): CjguiInternalRendererPacketDiagnosticSeverity {
    let summaryReady = summary.didPrepareRendererPacketDiagnosticsSummary &&
        summary.isRendererPacketDiagnosticsClean &&
        summary.didPreserveRendererPacketErrorTaxonomyResult &&
        summary.didSummarizeNoIssueDiagnostics &&
        summary.didKeepDiagnosticsSummaryInternalOnly &&
        summary.didAvoidExternalDiagnosticWrite &&
        summary.didAvoidDiagnosticPublication &&
        summary.didAvoidExternalDiagnosticNotification &&
        summary.didAvoidBackendErrorHandling &&
        summary.shouldDeferRendererPacketDiagnosticsSummary == false &&
        summary.shouldReportRendererPacketDiagnosticsSummaryBlocked == false
    let summaryDeferred = summary.didPrepareRendererPacketDiagnosticsSummary == false &&
        summary.shouldDeferRendererPacketDiagnosticsSummary &&
        summary.shouldReportRendererPacketDiagnosticsSummaryBlocked == false
    let summaryBlocked = summary.shouldReportRendererPacketDiagnosticsSummaryBlocked ||
        (
            summary.didPrepareRendererPacketDiagnosticsSummary &&
                summary.isRendererPacketDiagnosticsClean == false &&
                summary.shouldDeferRendererPacketDiagnosticsSummary == false
        )
    let summaryInconsistent = (
        summary.didPrepareRendererPacketDiagnosticsSummary &&
            (
                summary.didPreserveRendererPacketErrorTaxonomyResult == false ||
                summary.didKeepDiagnosticsSummaryInternalOnly == false ||
                summary.didAvoidExternalDiagnosticWrite == false ||
                summary.didAvoidDiagnosticPublication == false ||
                summary.didAvoidExternalDiagnosticNotification == false ||
                summary.didAvoidBackendErrorHandling == false ||
                summary.shouldDeferRendererPacketDiagnosticsSummary
            )
        ) ||
        (
            summary.shouldDeferRendererPacketDiagnosticsSummary &&
                summary.shouldReportRendererPacketDiagnosticsSummaryBlocked
        )

    // summary 已阻塞或不一致时，severity 不能伪造成 none。
    if (summaryBlocked || summaryInconsistent) {
        return CjguiInternalRendererPacketDiagnosticSeverity(
            summary,
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

    if (summaryReady) {
        return CjguiInternalRendererPacketDiagnosticSeverity(
            summary,
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
            true
        )
    }

    if (summaryDeferred) {
        return CjguiInternalRendererPacketDiagnosticSeverity(
            summary,
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

    return CjguiInternalRendererPacketDiagnosticSeverity(
        summary,
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

func cjguiInternalBuildRendererPacketDiagnosticEvidence(
    severity: CjguiInternalRendererPacketDiagnosticSeverity
): CjguiInternalRendererPacketDiagnosticEvidence {
    let summary = severity.summary
    let taxonomyResult = summary.taxonomyResult
    let blockedReason = taxonomyResult.blockedReason
    let degradedReason = blockedReason.degradedReason
    let failureTaxonomy = degradedReason.failureTaxonomy
    let severityReady = severity.didPrepareRendererPacketDiagnosticSeverity &&
        severity.isRendererPacketDiagnosticSeverityNone &&
        severity.didPreserveRendererPacketDiagnosticsSummary &&
        severity.didClassifyDiagnosticsSeverityAsValueFact &&
        severity.didKeepSeverityInternalOnly &&
        severity.didAvoidExternalDiagnosticWrite &&
        severity.didAvoidDiagnosticPublication &&
        severity.didAvoidExternalDiagnosticNotification &&
        severity.didAvoidBackendErrorHandling &&
        severity.shouldDeferRendererPacketDiagnosticSeverity == false &&
        severity.shouldReportRendererPacketDiagnosticSeverityBlocked == false
    let severityDeferred = severity.didPrepareRendererPacketDiagnosticSeverity == false &&
        severity.shouldDeferRendererPacketDiagnosticSeverity &&
        severity.shouldReportRendererPacketDiagnosticSeverityBlocked == false
    let severityBlocked = severity.shouldReportRendererPacketDiagnosticSeverityBlocked ||
        (
            severity.didPrepareRendererPacketDiagnosticSeverity &&
                severity.isRendererPacketDiagnosticSeverityNone == false &&
                severity.shouldDeferRendererPacketDiagnosticSeverity == false
        )
    let severityInconsistent = (
        severity.didPrepareRendererPacketDiagnosticSeverity &&
            (
                severity.didPreserveRendererPacketDiagnosticsSummary == false ||
                severity.didClassifyDiagnosticsSeverityAsValueFact == false ||
                severity.didKeepSeverityInternalOnly == false ||
                severity.didAvoidExternalDiagnosticWrite == false ||
                severity.didAvoidDiagnosticPublication == false ||
                severity.didAvoidExternalDiagnosticNotification == false ||
                severity.didAvoidBackendErrorHandling == false ||
                severity.shouldDeferRendererPacketDiagnosticSeverity
            )
        ) ||
        (
            severity.shouldDeferRendererPacketDiagnosticSeverity &&
                severity.shouldReportRendererPacketDiagnosticSeverityBlocked
        )
    let didPreserveTaxonomyEvidence = severity.didPreserveRendererPacketDiagnosticsSummary &&
        summary.didPreserveRendererPacketErrorTaxonomyResult &&
        taxonomyResult.didPreserveRendererPacketBlockedReason
    let didPreserveFailureFacts = didPreserveTaxonomyEvidence &&
        failureTaxonomy.didPreserveRendererPacketNormalizationResult
    let didPreserveDegradedFacts = didPreserveTaxonomyEvidence &&
        degradedReason.didPreserveRendererPacketFailureTaxonomy
    let didPreserveBlockedFacts = didPreserveTaxonomyEvidence &&
        blockedReason.didPreserveRendererPacketDegradedReason

    // severity 阻塞或不一致时，evidence 只保留内部证据 facts，不发布事件。
    if (severityBlocked || severityInconsistent) {
        return CjguiInternalRendererPacketDiagnosticEvidence(
            severity,
            true,
            false,
            true,
            true,
            didPreserveTaxonomyEvidence,
            didPreserveFailureFacts,
            didPreserveDegradedFacts,
            didPreserveBlockedFacts,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (severityReady) {
        return CjguiInternalRendererPacketDiagnosticEvidence(
            severity,
            true,
            false,
            false,
            true,
            didPreserveTaxonomyEvidence,
            didPreserveFailureFacts,
            didPreserveDegradedFacts,
            didPreserveBlockedFacts,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (severityDeferred) {
        return CjguiInternalRendererPacketDiagnosticEvidence(
            severity,
            false,
            true,
            false,
            true,
            didPreserveTaxonomyEvidence,
            didPreserveFailureFacts,
            didPreserveDegradedFacts,
            didPreserveBlockedFacts,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererPacketDiagnosticEvidence(
        severity,
        true,
        false,
        true,
        true,
        didPreserveTaxonomyEvidence,
        didPreserveFailureFacts,
        didPreserveDegradedFacts,
        didPreserveBlockedFacts,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPacketDiagnosticsResult(
    evidence: CjguiInternalRendererPacketDiagnosticEvidence
): CjguiInternalRendererPacketDiagnosticsResult {
    let diagnosticsReady = evidence.didPrepareRendererPacketDiagnosticEvidence &&
        evidence.didPreserveRendererPacketDiagnosticSeverity &&
        evidence.didPreserveRendererPacketTaxonomyEvidence &&
        evidence.didPreserveFailureTaxonomyFacts &&
        evidence.didPreserveDegradedReasonFacts &&
        evidence.didPreserveBlockedReasonFacts &&
        evidence.didKeepEvidenceInternalOnly &&
        evidence.didAvoidExternalDiagnosticWrite &&
        evidence.didAvoidDiagnosticPublication &&
        evidence.didAvoidExternalDiagnosticNotification &&
        evidence.didAvoidBackendErrorHandling &&
        evidence.shouldDeferRendererPacketDiagnosticEvidence == false &&
        evidence.shouldReportRendererPacketDiagnosticEvidenceBlocked == false
    let diagnosticsDeferred = evidence.didPrepareRendererPacketDiagnosticEvidence == false &&
        evidence.shouldDeferRendererPacketDiagnosticEvidence &&
        evidence.shouldReportRendererPacketDiagnosticEvidenceBlocked == false
    let diagnosticsInconsistent = (
        evidence.didPrepareRendererPacketDiagnosticEvidence &&
            (
                evidence.didPreserveRendererPacketDiagnosticSeverity == false ||
                evidence.didPreserveRendererPacketTaxonomyEvidence == false ||
                evidence.didKeepEvidenceInternalOnly == false ||
                evidence.didAvoidExternalDiagnosticWrite == false ||
                evidence.didAvoidDiagnosticPublication == false ||
                evidence.didAvoidExternalDiagnosticNotification == false ||
                evidence.didAvoidBackendErrorHandling == false ||
                evidence.shouldDeferRendererPacketDiagnosticEvidence
            )
        ) ||
        (
            evidence.shouldDeferRendererPacketDiagnosticEvidence &&
                evidence.shouldReportRendererPacketDiagnosticEvidenceBlocked
        )

    // diagnostics result 不代表绘制许可；blocked / inconsistent 必须 fail-closed。
    if (
        evidence.shouldReportRendererPacketDiagnosticEvidenceBlocked ||
        diagnosticsInconsistent
    ) {
        return CjguiInternalRendererPacketDiagnosticsResult(
            evidence,
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
            true
        )
    }

    if (diagnosticsReady) {
        return CjguiInternalRendererPacketDiagnosticsResult(
            evidence,
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

    if (diagnosticsDeferred) {
        return CjguiInternalRendererPacketDiagnosticsResult(
            evidence,
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
            true
        )
    }

    return CjguiInternalRendererPacketDiagnosticsResult(
        evidence,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft(
): CjguiInternalRendererPacketDiagnosticsResult {
    // 默认 diagnostics draft 只串联 taxonomy result -> summary / severity / evidence / result facts；
    // 它不写外部诊断、不发布事件、不触发外部通知，也不进入后端错误处理。
    let taxonomyResult = cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()
    let summary = cjguiInternalBuildRendererPacketDiagnosticsSummary(taxonomyResult)
    let severity = cjguiInternalBuildRendererPacketDiagnosticSeverity(summary)
    let evidence = cjguiInternalBuildRendererPacketDiagnosticEvidence(severity)
    return cjguiInternalBuildRendererPacketDiagnosticsResult(evidence)
}

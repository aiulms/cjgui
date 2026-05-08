// Owner: real render execution 第一刀 internal-only shell 边界。
// Truth: 只消费 CjguiInternalRendererNoRealDrawCallShellReadiness，并记录
// render execution shell intent、execution admission shell、completion
// observation denial proof、rollback execution denial proof、failure
// classification 与 no-real-render-execution-shell readiness facts。
// Stop-line: 只产出 internal-only shell / dehydrated facts；不是真实 render、
// GPU work、command submission、presentation、primitive draw API、resource
// binding、native bridge、native handle、C ABI / FFI、renderer state write 或
// public API 许可。
// Same-shape Boundary Brake: 不得把本 shell 包成 render-ready、
// GPU-submission、completion-ready、renderer-state-write、receipt、record 或
// publication wrapper。
package cjgui

struct CjguiInternalRendererRealRenderExecutionShellIntent {
    let noRealDrawCallShellReadiness:
        CjguiInternalRendererNoRealDrawCallShellReadiness
    let didPrepareRendererRealRenderExecutionShellIntent: Bool
    let shouldDeferRendererRealRenderExecutionShellIntent: Bool
    let shouldReportRendererRealRenderExecutionShellIntentBlocked: Bool
    let didPreserveRendererNoRealDrawCallShellReadiness: Bool
    let didDefineFutureRenderExecutionShellIntent: Bool
    let didDescribeExecutionAdmissionNeed: Bool
    let didDescribeCompletionObservationDenialNeed: Bool
    let didDescribeRollbackExecutionDenialNeed: Bool
    let didDescribeRenderExecutionFailureClassificationNeed: Bool
    let didKeepRenderExecutionShellIntentDehydrated: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealDrawCallShellReadiness:
            CjguiInternalRendererNoRealDrawCallShellReadiness,
        didPrepareRendererRealRenderExecutionShellIntent: Bool,
        shouldDeferRendererRealRenderExecutionShellIntent: Bool,
        shouldReportRendererRealRenderExecutionShellIntentBlocked: Bool,
        didPreserveRendererNoRealDrawCallShellReadiness: Bool,
        didDefineFutureRenderExecutionShellIntent: Bool,
        didDescribeExecutionAdmissionNeed: Bool,
        didDescribeCompletionObservationDenialNeed: Bool,
        didDescribeRollbackExecutionDenialNeed: Bool,
        didDescribeRenderExecutionFailureClassificationNeed: Bool,
        didKeepRenderExecutionShellIntentDehydrated: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealDrawCallShellReadiness = noRealDrawCallShellReadiness
        this.didPrepareRendererRealRenderExecutionShellIntent =
            didPrepareRendererRealRenderExecutionShellIntent
        this.shouldDeferRendererRealRenderExecutionShellIntent =
            shouldDeferRendererRealRenderExecutionShellIntent
        this.shouldReportRendererRealRenderExecutionShellIntentBlocked =
            shouldReportRendererRealRenderExecutionShellIntentBlocked
        this.didPreserveRendererNoRealDrawCallShellReadiness =
            didPreserveRendererNoRealDrawCallShellReadiness
        this.didDefineFutureRenderExecutionShellIntent =
            didDefineFutureRenderExecutionShellIntent
        this.didDescribeExecutionAdmissionNeed =
            didDescribeExecutionAdmissionNeed
        this.didDescribeCompletionObservationDenialNeed =
            didDescribeCompletionObservationDenialNeed
        this.didDescribeRollbackExecutionDenialNeed =
            didDescribeRollbackExecutionDenialNeed
        this.didDescribeRenderExecutionFailureClassificationNeed =
            didDescribeRenderExecutionFailureClassificationNeed
        this.didKeepRenderExecutionShellIntentDehydrated =
            didKeepRenderExecutionShellIntentDehydrated
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealRenderExecutionAdmissionShell {
    let shellIntent:
        CjguiInternalRendererRealRenderExecutionShellIntent
    let didPrepareRendererRealRenderExecutionAdmissionShell: Bool
    let shouldDeferRendererRealRenderExecutionAdmissionShell: Bool
    let shouldReportRendererRealRenderExecutionAdmissionShellBlocked: Bool
    let didPreserveRendererRealRenderExecutionShellIntent: Bool
    let didDefineOwnerLocalRenderExecutionAdmissionShell: Bool
    let didConfirmNoRenderWorkExecution: Bool
    let didConfirmNoGpuWorkSubmission: Bool
    let didConfirmNoCommandSubmissionInvocation: Bool
    let didConfirmNoPresentationInvocation: Bool
    let didKeepRenderExecutionAdmissionShellDehydrated: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        shellIntent:
            CjguiInternalRendererRealRenderExecutionShellIntent,
        didPrepareRendererRealRenderExecutionAdmissionShell: Bool,
        shouldDeferRendererRealRenderExecutionAdmissionShell: Bool,
        shouldReportRendererRealRenderExecutionAdmissionShellBlocked: Bool,
        didPreserveRendererRealRenderExecutionShellIntent: Bool,
        didDefineOwnerLocalRenderExecutionAdmissionShell: Bool,
        didConfirmNoRenderWorkExecution: Bool,
        didConfirmNoGpuWorkSubmission: Bool,
        didConfirmNoCommandSubmissionInvocation: Bool,
        didConfirmNoPresentationInvocation: Bool,
        didKeepRenderExecutionAdmissionShellDehydrated: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shellIntent = shellIntent
        this.didPrepareRendererRealRenderExecutionAdmissionShell =
            didPrepareRendererRealRenderExecutionAdmissionShell
        this.shouldDeferRendererRealRenderExecutionAdmissionShell =
            shouldDeferRendererRealRenderExecutionAdmissionShell
        this.shouldReportRendererRealRenderExecutionAdmissionShellBlocked =
            shouldReportRendererRealRenderExecutionAdmissionShellBlocked
        this.didPreserveRendererRealRenderExecutionShellIntent =
            didPreserveRendererRealRenderExecutionShellIntent
        this.didDefineOwnerLocalRenderExecutionAdmissionShell =
            didDefineOwnerLocalRenderExecutionAdmissionShell
        this.didConfirmNoRenderWorkExecution =
            didConfirmNoRenderWorkExecution
        this.didConfirmNoGpuWorkSubmission =
            didConfirmNoGpuWorkSubmission
        this.didConfirmNoCommandSubmissionInvocation =
            didConfirmNoCommandSubmissionInvocation
        this.didConfirmNoPresentationInvocation =
            didConfirmNoPresentationInvocation
        this.didKeepRenderExecutionAdmissionShellDehydrated =
            didKeepRenderExecutionAdmissionShellDehydrated
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealRenderCompletionObservationDenialProof {
    let executionAdmissionShell:
        CjguiInternalRendererRealRenderExecutionAdmissionShell
    let didPrepareRendererRealRenderCompletionObservationDenialProof: Bool
    let shouldDeferRendererRealRenderCompletionObservationDenialProof: Bool
    let shouldReportRendererRealRenderCompletionObservationDenialProofBlocked:
        Bool
    let didPreserveRendererRealRenderExecutionAdmissionShell: Bool
    let didDefineOwnerLocalCompletionObservationDenialProof: Bool
    let didConfirmNoCompletionCallbackRegistration: Bool
    let didConfirmNoGpuCompletionObservation: Bool
    let didConfirmNoExternalDiagnosticPublication: Bool
    let didKeepCompletionObservationDenialProofDehydrated: Bool
    let didAvoidCompletionReadyWrapper: Bool
    let didAvoidPublicDiagnosticsWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        executionAdmissionShell:
            CjguiInternalRendererRealRenderExecutionAdmissionShell,
        didPrepareRendererRealRenderCompletionObservationDenialProof: Bool,
        shouldDeferRendererRealRenderCompletionObservationDenialProof: Bool,
        shouldReportRendererRealRenderCompletionObservationDenialProofBlocked:
            Bool,
        didPreserveRendererRealRenderExecutionAdmissionShell: Bool,
        didDefineOwnerLocalCompletionObservationDenialProof: Bool,
        didConfirmNoCompletionCallbackRegistration: Bool,
        didConfirmNoGpuCompletionObservation: Bool,
        didConfirmNoExternalDiagnosticPublication: Bool,
        didKeepCompletionObservationDenialProofDehydrated: Bool,
        didAvoidCompletionReadyWrapper: Bool,
        didAvoidPublicDiagnosticsWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.executionAdmissionShell = executionAdmissionShell
        this
            .didPrepareRendererRealRenderCompletionObservationDenialProof =
            didPrepareRendererRealRenderCompletionObservationDenialProof
        this
            .shouldDeferRendererRealRenderCompletionObservationDenialProof =
            shouldDeferRendererRealRenderCompletionObservationDenialProof
        this
            .shouldReportRendererRealRenderCompletionObservationDenialProofBlocked =
            shouldReportRendererRealRenderCompletionObservationDenialProofBlocked
        this.didPreserveRendererRealRenderExecutionAdmissionShell =
            didPreserveRendererRealRenderExecutionAdmissionShell
        this.didDefineOwnerLocalCompletionObservationDenialProof =
            didDefineOwnerLocalCompletionObservationDenialProof
        this.didConfirmNoCompletionCallbackRegistration =
            didConfirmNoCompletionCallbackRegistration
        this.didConfirmNoGpuCompletionObservation =
            didConfirmNoGpuCompletionObservation
        this.didConfirmNoExternalDiagnosticPublication =
            didConfirmNoExternalDiagnosticPublication
        this.didKeepCompletionObservationDenialProofDehydrated =
            didKeepCompletionObservationDenialProofDehydrated
        this.didAvoidCompletionReadyWrapper = didAvoidCompletionReadyWrapper
        this.didAvoidPublicDiagnosticsWrapper =
            didAvoidPublicDiagnosticsWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealRenderRollbackExecutionDenialProof {
    let completionObservationDenialProof:
        CjguiInternalRendererRealRenderCompletionObservationDenialProof
    let didPrepareRendererRealRenderRollbackExecutionDenialProof: Bool
    let shouldDeferRendererRealRenderRollbackExecutionDenialProof: Bool
    let shouldReportRendererRealRenderRollbackExecutionDenialProofBlocked:
        Bool
    let didPreserveRendererRealRenderCompletionObservationDenialProof: Bool
    let didDefineOwnerLocalRollbackExecutionDenialProof: Bool
    let didConfirmNoRollbackCallbackExecution: Bool
    let didConfirmNoFallbackRenderExecution: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didKeepRollbackExecutionDenialProofDehydrated: Bool
    let didAvoidRollbackReadyWrapper: Bool
    let didAvoidRendererStateWriteWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        completionObservationDenialProof:
            CjguiInternalRendererRealRenderCompletionObservationDenialProof,
        didPrepareRendererRealRenderRollbackExecutionDenialProof: Bool,
        shouldDeferRendererRealRenderRollbackExecutionDenialProof: Bool,
        shouldReportRendererRealRenderRollbackExecutionDenialProofBlocked:
            Bool,
        didPreserveRendererRealRenderCompletionObservationDenialProof: Bool,
        didDefineOwnerLocalRollbackExecutionDenialProof: Bool,
        didConfirmNoRollbackCallbackExecution: Bool,
        didConfirmNoFallbackRenderExecution: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didKeepRollbackExecutionDenialProofDehydrated: Bool,
        didAvoidRollbackReadyWrapper: Bool,
        didAvoidRendererStateWriteWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.completionObservationDenialProof =
            completionObservationDenialProof
        this.didPrepareRendererRealRenderRollbackExecutionDenialProof =
            didPrepareRendererRealRenderRollbackExecutionDenialProof
        this.shouldDeferRendererRealRenderRollbackExecutionDenialProof =
            shouldDeferRendererRealRenderRollbackExecutionDenialProof
        this
            .shouldReportRendererRealRenderRollbackExecutionDenialProofBlocked =
            shouldReportRendererRealRenderRollbackExecutionDenialProofBlocked
        this
            .didPreserveRendererRealRenderCompletionObservationDenialProof =
            didPreserveRendererRealRenderCompletionObservationDenialProof
        this.didDefineOwnerLocalRollbackExecutionDenialProof =
            didDefineOwnerLocalRollbackExecutionDenialProof
        this.didConfirmNoRollbackCallbackExecution =
            didConfirmNoRollbackCallbackExecution
        this.didConfirmNoFallbackRenderExecution =
            didConfirmNoFallbackRenderExecution
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didKeepRollbackExecutionDenialProofDehydrated =
            didKeepRollbackExecutionDenialProofDehydrated
        this.didAvoidRollbackReadyWrapper = didAvoidRollbackReadyWrapper
        this.didAvoidRendererStateWriteWrapper =
            didAvoidRendererStateWriteWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealRenderExecutionFailureClassification {
    let rollbackExecutionDenialProof:
        CjguiInternalRendererRealRenderRollbackExecutionDenialProof
    let didPrepareRendererRealRenderExecutionFailureClassification: Bool
    let shouldDeferRendererRealRenderExecutionFailureClassification: Bool
    let shouldReportRendererRealRenderExecutionFailureClassificationBlocked:
        Bool
    let didPreserveRendererRealRenderRollbackExecutionDenialProof: Bool
    let didDefineOwnerLocalRenderExecutionFailureClassification: Bool
    let didClassifyMissingDrawCommandAsFailClosed: Bool
    let didClassifyGpuSubmissionRequestAsFailClosed: Bool
    let didClassifyCompletionOptimismAsFailClosed: Bool
    let didClassifyRollbackOptimismAsFailClosed: Bool
    let didKeepRenderExecutionFailureClassificationDehydrated: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        rollbackExecutionDenialProof:
            CjguiInternalRendererRealRenderRollbackExecutionDenialProof,
        didPrepareRendererRealRenderExecutionFailureClassification: Bool,
        shouldDeferRendererRealRenderExecutionFailureClassification: Bool,
        shouldReportRendererRealRenderExecutionFailureClassificationBlocked:
            Bool,
        didPreserveRendererRealRenderRollbackExecutionDenialProof: Bool,
        didDefineOwnerLocalRenderExecutionFailureClassification: Bool,
        didClassifyMissingDrawCommandAsFailClosed: Bool,
        didClassifyGpuSubmissionRequestAsFailClosed: Bool,
        didClassifyCompletionOptimismAsFailClosed: Bool,
        didClassifyRollbackOptimismAsFailClosed: Bool,
        didKeepRenderExecutionFailureClassificationDehydrated: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.rollbackExecutionDenialProof = rollbackExecutionDenialProof
        this.didPrepareRendererRealRenderExecutionFailureClassification =
            didPrepareRendererRealRenderExecutionFailureClassification
        this.shouldDeferRendererRealRenderExecutionFailureClassification =
            shouldDeferRendererRealRenderExecutionFailureClassification
        this
            .shouldReportRendererRealRenderExecutionFailureClassificationBlocked =
            shouldReportRendererRealRenderExecutionFailureClassificationBlocked
        this.didPreserveRendererRealRenderRollbackExecutionDenialProof =
            didPreserveRendererRealRenderRollbackExecutionDenialProof
        this.didDefineOwnerLocalRenderExecutionFailureClassification =
            didDefineOwnerLocalRenderExecutionFailureClassification
        this.didClassifyMissingDrawCommandAsFailClosed =
            didClassifyMissingDrawCommandAsFailClosed
        this.didClassifyGpuSubmissionRequestAsFailClosed =
            didClassifyGpuSubmissionRequestAsFailClosed
        this.didClassifyCompletionOptimismAsFailClosed =
            didClassifyCompletionOptimismAsFailClosed
        this.didClassifyRollbackOptimismAsFailClosed =
            didClassifyRollbackOptimismAsFailClosed
        this.didKeepRenderExecutionFailureClassificationDehydrated =
            didKeepRenderExecutionFailureClassificationDehydrated
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealRenderExecutionShellReadiness {
    let failureClassification:
        CjguiInternalRendererRealRenderExecutionFailureClassification
    let didPrepareRendererNoRealRenderExecutionShellReadiness: Bool
    let didConfirmRendererNoRealRenderExecutionShellReadiness: Bool
    let shouldDeferRendererNoRealRenderExecutionShellReadiness: Bool
    let shouldReportRendererNoRealRenderExecutionShellReadinessBlocked: Bool
    let didPreserveRendererRealRenderExecutionFailureClassification: Bool
    let didConfirmNoRenderWorkExecution: Bool
    let didConfirmNoGpuWorkSubmission: Bool
    let didConfirmNoCommandSubmissionInvocation: Bool
    let didConfirmNoPresentationInvocation: Bool
    let didConfirmNoCompletionObservation: Bool
    let didConfirmNoRollbackExecution: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoPublicApiSurface: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidRendererStateWriteWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        failureClassification:
            CjguiInternalRendererRealRenderExecutionFailureClassification,
        didPrepareRendererNoRealRenderExecutionShellReadiness: Bool,
        didConfirmRendererNoRealRenderExecutionShellReadiness: Bool,
        shouldDeferRendererNoRealRenderExecutionShellReadiness: Bool,
        shouldReportRendererNoRealRenderExecutionShellReadinessBlocked: Bool,
        didPreserveRendererRealRenderExecutionFailureClassification: Bool,
        didConfirmNoRenderWorkExecution: Bool,
        didConfirmNoGpuWorkSubmission: Bool,
        didConfirmNoCommandSubmissionInvocation: Bool,
        didConfirmNoPresentationInvocation: Bool,
        didConfirmNoCompletionObservation: Bool,
        didConfirmNoRollbackExecution: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoPublicApiSurface: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidRendererStateWriteWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.failureClassification = failureClassification
        this.didPrepareRendererNoRealRenderExecutionShellReadiness =
            didPrepareRendererNoRealRenderExecutionShellReadiness
        this.didConfirmRendererNoRealRenderExecutionShellReadiness =
            didConfirmRendererNoRealRenderExecutionShellReadiness
        this.shouldDeferRendererNoRealRenderExecutionShellReadiness =
            shouldDeferRendererNoRealRenderExecutionShellReadiness
        this.shouldReportRendererNoRealRenderExecutionShellReadinessBlocked =
            shouldReportRendererNoRealRenderExecutionShellReadinessBlocked
        this.didPreserveRendererRealRenderExecutionFailureClassification =
            didPreserveRendererRealRenderExecutionFailureClassification
        this.didConfirmNoRenderWorkExecution =
            didConfirmNoRenderWorkExecution
        this.didConfirmNoGpuWorkSubmission =
            didConfirmNoGpuWorkSubmission
        this.didConfirmNoCommandSubmissionInvocation =
            didConfirmNoCommandSubmissionInvocation
        this.didConfirmNoPresentationInvocation =
            didConfirmNoPresentationInvocation
        this.didConfirmNoCompletionObservation =
            didConfirmNoCompletionObservation
        this.didConfirmNoRollbackExecution =
            didConfirmNoRollbackExecution
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoPublicApiSurface = didConfirmNoPublicApiSurface
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidRendererStateWriteWrapper =
            didAvoidRendererStateWriteWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererRealRenderExecutionShellIntent(
    noRealDrawCallShellReadiness:
        CjguiInternalRendererNoRealDrawCallShellReadiness
): CjguiInternalRendererRealRenderExecutionShellIntent {
    let upstreamReady =
        noRealDrawCallShellReadiness
            .didConfirmRendererNoRealDrawCallShellReadiness &&
        noRealDrawCallShellReadiness
            .shouldDeferRendererNoRealDrawCallShellReadiness == false &&
        noRealDrawCallShellReadiness
            .shouldReportRendererNoRealDrawCallShellReadinessBlocked == false
    let upstreamDeferred =
        noRealDrawCallShellReadiness
            .shouldDeferRendererNoRealDrawCallShellReadiness &&
        noRealDrawCallShellReadiness
            .shouldReportRendererNoRealDrawCallShellReadinessBlocked == false
    let upstreamInconsistent =
        noRealDrawCallShellReadiness
            .shouldReportRendererNoRealDrawCallShellReadinessBlocked ||
        (
            noRealDrawCallShellReadiness
                .didPrepareRendererNoRealDrawCallShellReadiness &&
            upstreamReady == false &&
            upstreamDeferred == false
        )

    return CjguiInternalRendererRealRenderExecutionShellIntent(
        noRealDrawCallShellReadiness,
        upstreamReady,
        upstreamDeferred,
        upstreamInconsistent,
        upstreamReady,
        upstreamReady,
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

func cjguiInternalBuildRendererRealRenderExecutionAdmissionShell(
    shellIntent: CjguiInternalRendererRealRenderExecutionShellIntent
): CjguiInternalRendererRealRenderExecutionAdmissionShell {
    let proofReady =
        shellIntent.didPrepareRendererRealRenderExecutionShellIntent &&
        shellIntent.didPreserveRendererNoRealDrawCallShellReadiness &&
        shellIntent.didDefineFutureRenderExecutionShellIntent &&
        shellIntent.didDescribeExecutionAdmissionNeed &&
        shellIntent.didKeepRenderExecutionShellIntentDehydrated &&
        shellIntent.didAvoidRenderReadyWrapper &&
        shellIntent.didAvoidGpuSubmissionWrapper &&
        shellIntent.didAvoidThinWrapper &&
        shellIntent.shouldDeferRendererRealRenderExecutionShellIntent ==
            false &&
        shellIntent
            .shouldReportRendererRealRenderExecutionShellIntentBlocked ==
            false
    let proofDeferred =
        shellIntent.didPrepareRendererRealRenderExecutionShellIntent == false &&
        shellIntent.shouldDeferRendererRealRenderExecutionShellIntent &&
        shellIntent
            .shouldReportRendererRealRenderExecutionShellIntentBlocked ==
            false
    let proofInconsistent =
        shellIntent
            .shouldReportRendererRealRenderExecutionShellIntentBlocked ||
        (
            shellIntent.didPrepareRendererRealRenderExecutionShellIntent &&
            proofReady == false
        )

    return CjguiInternalRendererRealRenderExecutionAdmissionShell(
        shellIntent,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        proofReady,
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

func cjguiInternalBuildRendererRealRenderCompletionObservationDenialProof(
    executionAdmissionShell:
        CjguiInternalRendererRealRenderExecutionAdmissionShell
): CjguiInternalRendererRealRenderCompletionObservationDenialProof {
    let proofReady =
        executionAdmissionShell
            .didPrepareRendererRealRenderExecutionAdmissionShell &&
        executionAdmissionShell
            .didPreserveRendererRealRenderExecutionShellIntent &&
        executionAdmissionShell
            .didDefineOwnerLocalRenderExecutionAdmissionShell &&
        executionAdmissionShell.didConfirmNoRenderWorkExecution &&
        executionAdmissionShell.didConfirmNoGpuWorkSubmission &&
        executionAdmissionShell.didConfirmNoCommandSubmissionInvocation &&
        executionAdmissionShell.didConfirmNoPresentationInvocation &&
        executionAdmissionShell
            .didKeepRenderExecutionAdmissionShellDehydrated &&
        executionAdmissionShell.didAvoidRenderReadyWrapper &&
        executionAdmissionShell.didAvoidGpuSubmissionWrapper &&
        executionAdmissionShell.didAvoidThinWrapper &&
        executionAdmissionShell
            .shouldDeferRendererRealRenderExecutionAdmissionShell == false &&
        executionAdmissionShell
            .shouldReportRendererRealRenderExecutionAdmissionShellBlocked ==
            false
    let proofDeferred =
        executionAdmissionShell
            .didPrepareRendererRealRenderExecutionAdmissionShell == false &&
        executionAdmissionShell
            .shouldDeferRendererRealRenderExecutionAdmissionShell &&
        executionAdmissionShell
            .shouldReportRendererRealRenderExecutionAdmissionShellBlocked ==
            false
    let proofInconsistent =
        executionAdmissionShell
            .shouldReportRendererRealRenderExecutionAdmissionShellBlocked ||
        (
            executionAdmissionShell
                .didPrepareRendererRealRenderExecutionAdmissionShell &&
            proofReady == false
        )

    return CjguiInternalRendererRealRenderCompletionObservationDenialProof(
        executionAdmissionShell,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        proofReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererRealRenderRollbackExecutionDenialProof(
    completionObservationDenialProof:
        CjguiInternalRendererRealRenderCompletionObservationDenialProof
): CjguiInternalRendererRealRenderRollbackExecutionDenialProof {
    let proofReady =
        completionObservationDenialProof
            .didPrepareRendererRealRenderCompletionObservationDenialProof &&
        completionObservationDenialProof
            .didPreserveRendererRealRenderExecutionAdmissionShell &&
        completionObservationDenialProof
            .didDefineOwnerLocalCompletionObservationDenialProof &&
        completionObservationDenialProof
            .didConfirmNoCompletionCallbackRegistration &&
        completionObservationDenialProof.didConfirmNoGpuCompletionObservation &&
        completionObservationDenialProof
            .didConfirmNoExternalDiagnosticPublication &&
        completionObservationDenialProof
            .didKeepCompletionObservationDenialProofDehydrated &&
        completionObservationDenialProof.didAvoidCompletionReadyWrapper &&
        completionObservationDenialProof.didAvoidPublicDiagnosticsWrapper &&
        completionObservationDenialProof.didAvoidThinWrapper &&
        completionObservationDenialProof
            .shouldDeferRendererRealRenderCompletionObservationDenialProof ==
            false &&
        completionObservationDenialProof
            .shouldReportRendererRealRenderCompletionObservationDenialProofBlocked ==
            false
    let proofDeferred =
        completionObservationDenialProof
            .didPrepareRendererRealRenderCompletionObservationDenialProof ==
            false &&
        completionObservationDenialProof
            .shouldDeferRendererRealRenderCompletionObservationDenialProof &&
        completionObservationDenialProof
            .shouldReportRendererRealRenderCompletionObservationDenialProofBlocked ==
            false
    let proofInconsistent =
        completionObservationDenialProof
            .shouldReportRendererRealRenderCompletionObservationDenialProofBlocked ||
        (
            completionObservationDenialProof
                .didPrepareRendererRealRenderCompletionObservationDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealRenderRollbackExecutionDenialProof(
        completionObservationDenialProof,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        proofReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererRealRenderExecutionFailureClassification(
    rollbackExecutionDenialProof:
        CjguiInternalRendererRealRenderRollbackExecutionDenialProof
): CjguiInternalRendererRealRenderExecutionFailureClassification {
    let proofReady =
        rollbackExecutionDenialProof
            .didPrepareRendererRealRenderRollbackExecutionDenialProof &&
        rollbackExecutionDenialProof
            .didPreserveRendererRealRenderCompletionObservationDenialProof &&
        rollbackExecutionDenialProof
            .didDefineOwnerLocalRollbackExecutionDenialProof &&
        rollbackExecutionDenialProof.didConfirmNoRollbackCallbackExecution &&
        rollbackExecutionDenialProof.didConfirmNoFallbackRenderExecution &&
        rollbackExecutionDenialProof.didConfirmNoRendererStateWrite &&
        rollbackExecutionDenialProof
            .didKeepRollbackExecutionDenialProofDehydrated &&
        rollbackExecutionDenialProof.didAvoidRollbackReadyWrapper &&
        rollbackExecutionDenialProof.didAvoidRendererStateWriteWrapper &&
        rollbackExecutionDenialProof.didAvoidThinWrapper &&
        rollbackExecutionDenialProof
            .shouldDeferRendererRealRenderRollbackExecutionDenialProof ==
            false &&
        rollbackExecutionDenialProof
            .shouldReportRendererRealRenderRollbackExecutionDenialProofBlocked ==
            false
    let proofDeferred =
        rollbackExecutionDenialProof
            .didPrepareRendererRealRenderRollbackExecutionDenialProof ==
            false &&
        rollbackExecutionDenialProof
            .shouldDeferRendererRealRenderRollbackExecutionDenialProof &&
        rollbackExecutionDenialProof
            .shouldReportRendererRealRenderRollbackExecutionDenialProofBlocked ==
            false
    let proofInconsistent =
        rollbackExecutionDenialProof
            .shouldReportRendererRealRenderRollbackExecutionDenialProofBlocked ||
        (
            rollbackExecutionDenialProof
                .didPrepareRendererRealRenderRollbackExecutionDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealRenderExecutionFailureClassification(
        rollbackExecutionDenialProof,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        proofReady,
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

func cjguiInternalBuildRendererNoRealRenderExecutionShellReadiness(
    failureClassification:
        CjguiInternalRendererRealRenderExecutionFailureClassification
): CjguiInternalRendererNoRealRenderExecutionShellReadiness {
    let proofReady =
        failureClassification
            .didPrepareRendererRealRenderExecutionFailureClassification &&
        failureClassification
            .didPreserveRendererRealRenderRollbackExecutionDenialProof &&
        failureClassification
            .didDefineOwnerLocalRenderExecutionFailureClassification &&
        failureClassification.didClassifyMissingDrawCommandAsFailClosed &&
        failureClassification
            .didClassifyGpuSubmissionRequestAsFailClosed &&
        failureClassification.didClassifyCompletionOptimismAsFailClosed &&
        failureClassification.didClassifyRollbackOptimismAsFailClosed &&
        failureClassification
            .didKeepRenderExecutionFailureClassificationDehydrated &&
        failureClassification.didAvoidRenderReadyWrapper &&
        failureClassification.didAvoidGpuSubmissionWrapper &&
        failureClassification.didAvoidThinWrapper &&
        failureClassification
            .shouldDeferRendererRealRenderExecutionFailureClassification ==
            false &&
        failureClassification
            .shouldReportRendererRealRenderExecutionFailureClassificationBlocked ==
            false
    let proofDeferred =
        failureClassification
            .didPrepareRendererRealRenderExecutionFailureClassification ==
            false &&
        failureClassification
            .shouldDeferRendererRealRenderExecutionFailureClassification &&
        failureClassification
            .shouldReportRendererRealRenderExecutionFailureClassificationBlocked ==
            false
    let proofInconsistent =
        failureClassification
            .shouldReportRendererRealRenderExecutionFailureClassificationBlocked ||
        (
            failureClassification
                .didPrepareRendererRealRenderExecutionFailureClassification &&
            proofReady == false
        )

    return CjguiInternalRendererNoRealRenderExecutionShellReadiness(
        failureClassification,
        proofReady,
        proofReady,
        proofDeferred,
        proofInconsistent,
        proofReady,
        true,
        true,
        true,
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

func cjguiInternalExecuteDefaultRendererRealRenderExecutionShellDraft():
    CjguiInternalRendererNoRealRenderExecutionShellReadiness {
    let noRealDrawCallShellReadiness =
        cjguiInternalExecuteDefaultRendererRealDrawCallShellDraft()
    let shellIntent =
        cjguiInternalBuildRendererRealRenderExecutionShellIntent(
            noRealDrawCallShellReadiness
        )
    let executionAdmissionShell =
        cjguiInternalBuildRendererRealRenderExecutionAdmissionShell(
            shellIntent
        )
    let completionObservationDenialProof =
        cjguiInternalBuildRendererRealRenderCompletionObservationDenialProof(
            executionAdmissionShell
        )
    let rollbackExecutionDenialProof =
        cjguiInternalBuildRendererRealRenderRollbackExecutionDenialProof(
            completionObservationDenialProof
        )
    let failureClassification =
        cjguiInternalBuildRendererRealRenderExecutionFailureClassification(
            rollbackExecutionDenialProof
        )
    return cjguiInternalBuildRendererNoRealRenderExecutionShellReadiness(
        failureClassification
    )
}

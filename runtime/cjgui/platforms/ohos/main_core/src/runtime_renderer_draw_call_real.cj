// Owner: real draw call 第一刀 internal-only shell 边界。
// Truth: 只消费 CjguiInternalRendererNoRealPipelineStateShellReadiness，并记录
// draw call shell intent、primitive command denial proof、geometry binding denial
// proof、draw ordering admission shell、draw execution denial proof 与
// no-real-draw-call-shell readiness facts。
// Stop-line: 只产出 internal-only shell / dehydrated facts；不是真实 draw
// command、primitive API、pipeline / buffer / texture / resource binding、GPU
// work、native bridge、native handle、C ABI / FFI、renderer state write 或 public
// API 许可。
// Same-shape Boundary Brake: 不得把本 shell 包成 draw-ready、binding-ready、
// GPU-submission、render-permission、renderer-state-write、receipt、record 或
// publication wrapper。
package cjgui

struct CjguiInternalRendererRealDrawCallShellIntent {
    let noRealPipelineStateShellReadiness:
        CjguiInternalRendererNoRealPipelineStateShellReadiness
    let didPrepareRendererRealDrawCallShellIntent: Bool
    let shouldDeferRendererRealDrawCallShellIntent: Bool
    let shouldReportRendererRealDrawCallShellIntentBlocked: Bool
    let didPreserveRendererNoRealPipelineStateShellReadiness: Bool
    let didDefineFutureDrawCallShellIntent: Bool
    let didDescribePrimitiveCommandDenialNeed: Bool
    let didDescribeGeometryBindingDenialNeed: Bool
    let didDescribeDrawOrderingAdmissionNeed: Bool
    let didDescribeDrawExecutionDenialNeed: Bool
    let didKeepDrawCallShellIntentDehydrated: Bool
    let didAvoidDrawReadyWrapper: Bool
    let didAvoidBindingReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        noRealPipelineStateShellReadiness:
            CjguiInternalRendererNoRealPipelineStateShellReadiness,
        didPrepareRendererRealDrawCallShellIntent: Bool,
        shouldDeferRendererRealDrawCallShellIntent: Bool,
        shouldReportRendererRealDrawCallShellIntentBlocked: Bool,
        didPreserveRendererNoRealPipelineStateShellReadiness: Bool,
        didDefineFutureDrawCallShellIntent: Bool,
        didDescribePrimitiveCommandDenialNeed: Bool,
        didDescribeGeometryBindingDenialNeed: Bool,
        didDescribeDrawOrderingAdmissionNeed: Bool,
        didDescribeDrawExecutionDenialNeed: Bool,
        didKeepDrawCallShellIntentDehydrated: Bool,
        didAvoidDrawReadyWrapper: Bool,
        didAvoidBindingReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noRealPipelineStateShellReadiness =
            noRealPipelineStateShellReadiness
        this.didPrepareRendererRealDrawCallShellIntent =
            didPrepareRendererRealDrawCallShellIntent
        this.shouldDeferRendererRealDrawCallShellIntent =
            shouldDeferRendererRealDrawCallShellIntent
        this.shouldReportRendererRealDrawCallShellIntentBlocked =
            shouldReportRendererRealDrawCallShellIntentBlocked
        this.didPreserveRendererNoRealPipelineStateShellReadiness =
            didPreserveRendererNoRealPipelineStateShellReadiness
        this.didDefineFutureDrawCallShellIntent =
            didDefineFutureDrawCallShellIntent
        this.didDescribePrimitiveCommandDenialNeed =
            didDescribePrimitiveCommandDenialNeed
        this.didDescribeGeometryBindingDenialNeed =
            didDescribeGeometryBindingDenialNeed
        this.didDescribeDrawOrderingAdmissionNeed =
            didDescribeDrawOrderingAdmissionNeed
        this.didDescribeDrawExecutionDenialNeed =
            didDescribeDrawExecutionDenialNeed
        this.didKeepDrawCallShellIntentDehydrated =
            didKeepDrawCallShellIntentDehydrated
        this.didAvoidDrawReadyWrapper = didAvoidDrawReadyWrapper
        this.didAvoidBindingReadyWrapper = didAvoidBindingReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealDrawPrimitiveCommandDenialProof {
    let shellIntent: CjguiInternalRendererRealDrawCallShellIntent
    let didPrepareRendererRealDrawPrimitiveCommandDenialProof: Bool
    let shouldDeferRendererRealDrawPrimitiveCommandDenialProof: Bool
    let shouldReportRendererRealDrawPrimitiveCommandDenialProofBlocked: Bool
    let didPreserveRendererRealDrawCallShellIntent: Bool
    let didDefineOwnerLocalPrimitiveCommandDenialProof: Bool
    let didConfirmNoPrimitiveDrawApiInvocation: Bool
    let didConfirmNoIndexedPrimitiveDrawApiInvocation: Bool
    let didConfirmNoPrimitiveCommandEmission: Bool
    let didKeepPrimitiveCommandDenialProofDehydrated: Bool
    let didAvoidPrimitiveCommandReadyWrapper: Bool
    let didAvoidDrawReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        shellIntent: CjguiInternalRendererRealDrawCallShellIntent,
        didPrepareRendererRealDrawPrimitiveCommandDenialProof: Bool,
        shouldDeferRendererRealDrawPrimitiveCommandDenialProof: Bool,
        shouldReportRendererRealDrawPrimitiveCommandDenialProofBlocked: Bool,
        didPreserveRendererRealDrawCallShellIntent: Bool,
        didDefineOwnerLocalPrimitiveCommandDenialProof: Bool,
        didConfirmNoPrimitiveDrawApiInvocation: Bool,
        didConfirmNoIndexedPrimitiveDrawApiInvocation: Bool,
        didConfirmNoPrimitiveCommandEmission: Bool,
        didKeepPrimitiveCommandDenialProofDehydrated: Bool,
        didAvoidPrimitiveCommandReadyWrapper: Bool,
        didAvoidDrawReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.shellIntent = shellIntent
        this.didPrepareRendererRealDrawPrimitiveCommandDenialProof =
            didPrepareRendererRealDrawPrimitiveCommandDenialProof
        this.shouldDeferRendererRealDrawPrimitiveCommandDenialProof =
            shouldDeferRendererRealDrawPrimitiveCommandDenialProof
        this
            .shouldReportRendererRealDrawPrimitiveCommandDenialProofBlocked =
            shouldReportRendererRealDrawPrimitiveCommandDenialProofBlocked
        this.didPreserveRendererRealDrawCallShellIntent =
            didPreserveRendererRealDrawCallShellIntent
        this.didDefineOwnerLocalPrimitiveCommandDenialProof =
            didDefineOwnerLocalPrimitiveCommandDenialProof
        this.didConfirmNoPrimitiveDrawApiInvocation =
            didConfirmNoPrimitiveDrawApiInvocation
        this.didConfirmNoIndexedPrimitiveDrawApiInvocation =
            didConfirmNoIndexedPrimitiveDrawApiInvocation
        this.didConfirmNoPrimitiveCommandEmission =
            didConfirmNoPrimitiveCommandEmission
        this.didKeepPrimitiveCommandDenialProofDehydrated =
            didKeepPrimitiveCommandDenialProofDehydrated
        this.didAvoidPrimitiveCommandReadyWrapper =
            didAvoidPrimitiveCommandReadyWrapper
        this.didAvoidDrawReadyWrapper = didAvoidDrawReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealDrawGeometryBindingDenialProof {
    let primitiveCommandDenialProof:
        CjguiInternalRendererRealDrawPrimitiveCommandDenialProof
    let didPrepareRendererRealDrawGeometryBindingDenialProof: Bool
    let shouldDeferRendererRealDrawGeometryBindingDenialProof: Bool
    let shouldReportRendererRealDrawGeometryBindingDenialProofBlocked: Bool
    let didPreserveRendererRealDrawPrimitiveCommandDenialProof: Bool
    let didDefineOwnerLocalGeometryBindingDenialProof: Bool
    let didConfirmNoVertexBufferBinding: Bool
    let didConfirmNoIndexBufferBinding: Bool
    let didConfirmNoTextureBinding: Bool
    let didConfirmNoResourceBinding: Bool
    let didConfirmNoPipelineRelationMutation: Bool
    let didKeepGeometryBindingDenialProofDehydrated: Bool
    let didAvoidGeometryBindingReadyWrapper: Bool
    let didAvoidResourceBindingReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        primitiveCommandDenialProof:
            CjguiInternalRendererRealDrawPrimitiveCommandDenialProof,
        didPrepareRendererRealDrawGeometryBindingDenialProof: Bool,
        shouldDeferRendererRealDrawGeometryBindingDenialProof: Bool,
        shouldReportRendererRealDrawGeometryBindingDenialProofBlocked: Bool,
        didPreserveRendererRealDrawPrimitiveCommandDenialProof: Bool,
        didDefineOwnerLocalGeometryBindingDenialProof: Bool,
        didConfirmNoVertexBufferBinding: Bool,
        didConfirmNoIndexBufferBinding: Bool,
        didConfirmNoTextureBinding: Bool,
        didConfirmNoResourceBinding: Bool,
        didConfirmNoPipelineRelationMutation: Bool,
        didKeepGeometryBindingDenialProofDehydrated: Bool,
        didAvoidGeometryBindingReadyWrapper: Bool,
        didAvoidResourceBindingReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.primitiveCommandDenialProof = primitiveCommandDenialProof
        this.didPrepareRendererRealDrawGeometryBindingDenialProof =
            didPrepareRendererRealDrawGeometryBindingDenialProof
        this.shouldDeferRendererRealDrawGeometryBindingDenialProof =
            shouldDeferRendererRealDrawGeometryBindingDenialProof
        this.shouldReportRendererRealDrawGeometryBindingDenialProofBlocked =
            shouldReportRendererRealDrawGeometryBindingDenialProofBlocked
        this.didPreserveRendererRealDrawPrimitiveCommandDenialProof =
            didPreserveRendererRealDrawPrimitiveCommandDenialProof
        this.didDefineOwnerLocalGeometryBindingDenialProof =
            didDefineOwnerLocalGeometryBindingDenialProof
        this.didConfirmNoVertexBufferBinding =
            didConfirmNoVertexBufferBinding
        this.didConfirmNoIndexBufferBinding = didConfirmNoIndexBufferBinding
        this.didConfirmNoTextureBinding = didConfirmNoTextureBinding
        this.didConfirmNoResourceBinding = didConfirmNoResourceBinding
        this.didConfirmNoPipelineRelationMutation =
            didConfirmNoPipelineRelationMutation
        this.didKeepGeometryBindingDenialProofDehydrated =
            didKeepGeometryBindingDenialProofDehydrated
        this.didAvoidGeometryBindingReadyWrapper =
            didAvoidGeometryBindingReadyWrapper
        this.didAvoidResourceBindingReadyWrapper =
            didAvoidResourceBindingReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealDrawOrderingAdmissionShell {
    let geometryBindingDenialProof:
        CjguiInternalRendererRealDrawGeometryBindingDenialProof
    let didPrepareRendererRealDrawOrderingAdmissionShell: Bool
    let shouldDeferRendererRealDrawOrderingAdmissionShell: Bool
    let shouldReportRendererRealDrawOrderingAdmissionShellBlocked: Bool
    let didPreserveRendererRealDrawGeometryBindingDenialProof: Bool
    let didDefineOwnerLocalDrawOrderingAdmissionShell: Bool
    let didRecordOrderingAsAdmissionOnly: Bool
    let didConfirmNoGpuOrderingExecution: Bool
    let didConfirmNoRenderPassMutation: Bool
    let didKeepDrawOrderingAdmissionShellDehydrated: Bool
    let didAvoidOrderingReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        geometryBindingDenialProof:
            CjguiInternalRendererRealDrawGeometryBindingDenialProof,
        didPrepareRendererRealDrawOrderingAdmissionShell: Bool,
        shouldDeferRendererRealDrawOrderingAdmissionShell: Bool,
        shouldReportRendererRealDrawOrderingAdmissionShellBlocked: Bool,
        didPreserveRendererRealDrawGeometryBindingDenialProof: Bool,
        didDefineOwnerLocalDrawOrderingAdmissionShell: Bool,
        didRecordOrderingAsAdmissionOnly: Bool,
        didConfirmNoGpuOrderingExecution: Bool,
        didConfirmNoRenderPassMutation: Bool,
        didKeepDrawOrderingAdmissionShellDehydrated: Bool,
        didAvoidOrderingReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.geometryBindingDenialProof = geometryBindingDenialProof
        this.didPrepareRendererRealDrawOrderingAdmissionShell =
            didPrepareRendererRealDrawOrderingAdmissionShell
        this.shouldDeferRendererRealDrawOrderingAdmissionShell =
            shouldDeferRendererRealDrawOrderingAdmissionShell
        this.shouldReportRendererRealDrawOrderingAdmissionShellBlocked =
            shouldReportRendererRealDrawOrderingAdmissionShellBlocked
        this.didPreserveRendererRealDrawGeometryBindingDenialProof =
            didPreserveRendererRealDrawGeometryBindingDenialProof
        this.didDefineOwnerLocalDrawOrderingAdmissionShell =
            didDefineOwnerLocalDrawOrderingAdmissionShell
        this.didRecordOrderingAsAdmissionOnly =
            didRecordOrderingAsAdmissionOnly
        this.didConfirmNoGpuOrderingExecution =
            didConfirmNoGpuOrderingExecution
        this.didConfirmNoRenderPassMutation = didConfirmNoRenderPassMutation
        this.didKeepDrawOrderingAdmissionShellDehydrated =
            didKeepDrawOrderingAdmissionShellDehydrated
        this.didAvoidOrderingReadyWrapper = didAvoidOrderingReadyWrapper
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererRealDrawExecutionDenialProof {
    let orderingAdmissionShell:
        CjguiInternalRendererRealDrawOrderingAdmissionShell
    let didPrepareRendererRealDrawExecutionDenialProof: Bool
    let shouldDeferRendererRealDrawExecutionDenialProof: Bool
    let shouldReportRendererRealDrawExecutionDenialProofBlocked: Bool
    let didPreserveRendererRealDrawOrderingAdmissionShell: Bool
    let didDefineOwnerLocalDrawExecutionDenialProof: Bool
    let didConfirmNoDrawCommandExecution: Bool
    let didConfirmNoEncoderCommandStreamMutation: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didKeepDrawExecutionDenialProofDehydrated: Bool
    let didAvoidDrawReadyWrapper: Bool
    let didAvoidGpuSubmissionWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        orderingAdmissionShell:
            CjguiInternalRendererRealDrawOrderingAdmissionShell,
        didPrepareRendererRealDrawExecutionDenialProof: Bool,
        shouldDeferRendererRealDrawExecutionDenialProof: Bool,
        shouldReportRendererRealDrawExecutionDenialProofBlocked: Bool,
        didPreserveRendererRealDrawOrderingAdmissionShell: Bool,
        didDefineOwnerLocalDrawExecutionDenialProof: Bool,
        didConfirmNoDrawCommandExecution: Bool,
        didConfirmNoEncoderCommandStreamMutation: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didKeepDrawExecutionDenialProofDehydrated: Bool,
        didAvoidDrawReadyWrapper: Bool,
        didAvoidGpuSubmissionWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.orderingAdmissionShell = orderingAdmissionShell
        this.didPrepareRendererRealDrawExecutionDenialProof =
            didPrepareRendererRealDrawExecutionDenialProof
        this.shouldDeferRendererRealDrawExecutionDenialProof =
            shouldDeferRendererRealDrawExecutionDenialProof
        this.shouldReportRendererRealDrawExecutionDenialProofBlocked =
            shouldReportRendererRealDrawExecutionDenialProofBlocked
        this.didPreserveRendererRealDrawOrderingAdmissionShell =
            didPreserveRendererRealDrawOrderingAdmissionShell
        this.didDefineOwnerLocalDrawExecutionDenialProof =
            didDefineOwnerLocalDrawExecutionDenialProof
        this.didConfirmNoDrawCommandExecution =
            didConfirmNoDrawCommandExecution
        this.didConfirmNoEncoderCommandStreamMutation =
            didConfirmNoEncoderCommandStreamMutation
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didKeepDrawExecutionDenialProofDehydrated =
            didKeepDrawExecutionDenialProofDehydrated
        this.didAvoidDrawReadyWrapper = didAvoidDrawReadyWrapper
        this.didAvoidGpuSubmissionWrapper = didAvoidGpuSubmissionWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNoRealDrawCallShellReadiness {
    let drawExecutionDenialProof:
        CjguiInternalRendererRealDrawExecutionDenialProof
    let didPrepareRendererNoRealDrawCallShellReadiness: Bool
    let didConfirmRendererNoRealDrawCallShellReadiness: Bool
    let shouldDeferRendererNoRealDrawCallShellReadiness: Bool
    let shouldReportRendererNoRealDrawCallShellReadinessBlocked: Bool
    let didPreserveRendererRealDrawExecutionDenialProof: Bool
    let didConfirmNoPrimitiveDrawApiInvocation: Bool
    let didConfirmNoIndexedPrimitiveDrawApiInvocation: Bool
    let didConfirmNoPipelineBinding: Bool
    let didConfirmNoGeometryResourceBinding: Bool
    let didConfirmNoGpuSubmission: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoPublicApiSurface: Bool
    let didAvoidDrawReadyWrapper: Bool
    let didAvoidBindingReadyWrapper: Bool
    let didAvoidReceiptRecordOutput: Bool
    let didAvoidThinWrapper: Bool

    init(
        drawExecutionDenialProof:
            CjguiInternalRendererRealDrawExecutionDenialProof,
        didPrepareRendererNoRealDrawCallShellReadiness: Bool,
        didConfirmRendererNoRealDrawCallShellReadiness: Bool,
        shouldDeferRendererNoRealDrawCallShellReadiness: Bool,
        shouldReportRendererNoRealDrawCallShellReadinessBlocked: Bool,
        didPreserveRendererRealDrawExecutionDenialProof: Bool,
        didConfirmNoPrimitiveDrawApiInvocation: Bool,
        didConfirmNoIndexedPrimitiveDrawApiInvocation: Bool,
        didConfirmNoPipelineBinding: Bool,
        didConfirmNoGeometryResourceBinding: Bool,
        didConfirmNoGpuSubmission: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoPublicApiSurface: Bool,
        didAvoidDrawReadyWrapper: Bool,
        didAvoidBindingReadyWrapper: Bool,
        didAvoidReceiptRecordOutput: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.drawExecutionDenialProof = drawExecutionDenialProof
        this.didPrepareRendererNoRealDrawCallShellReadiness =
            didPrepareRendererNoRealDrawCallShellReadiness
        this.didConfirmRendererNoRealDrawCallShellReadiness =
            didConfirmRendererNoRealDrawCallShellReadiness
        this.shouldDeferRendererNoRealDrawCallShellReadiness =
            shouldDeferRendererNoRealDrawCallShellReadiness
        this.shouldReportRendererNoRealDrawCallShellReadinessBlocked =
            shouldReportRendererNoRealDrawCallShellReadinessBlocked
        this.didPreserveRendererRealDrawExecutionDenialProof =
            didPreserveRendererRealDrawExecutionDenialProof
        this.didConfirmNoPrimitiveDrawApiInvocation =
            didConfirmNoPrimitiveDrawApiInvocation
        this.didConfirmNoIndexedPrimitiveDrawApiInvocation =
            didConfirmNoIndexedPrimitiveDrawApiInvocation
        this.didConfirmNoPipelineBinding = didConfirmNoPipelineBinding
        this.didConfirmNoGeometryResourceBinding =
            didConfirmNoGeometryResourceBinding
        this.didConfirmNoGpuSubmission = didConfirmNoGpuSubmission
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoPublicApiSurface = didConfirmNoPublicApiSurface
        this.didAvoidDrawReadyWrapper = didAvoidDrawReadyWrapper
        this.didAvoidBindingReadyWrapper = didAvoidBindingReadyWrapper
        this.didAvoidReceiptRecordOutput = didAvoidReceiptRecordOutput
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalBuildRendererRealDrawCallShellIntent(
    noRealPipelineStateShellReadiness:
        CjguiInternalRendererNoRealPipelineStateShellReadiness
): CjguiInternalRendererRealDrawCallShellIntent {
    let upstreamReady =
        noRealPipelineStateShellReadiness
            .isRendererNoRealPipelineStateShellReady &&
        noRealPipelineStateShellReadiness
            .shouldDeferRendererNoRealPipelineStateShellReadiness == false &&
        noRealPipelineStateShellReadiness
            .shouldReportRendererNoRealPipelineStateShellReadinessBlocked ==
            false
    let upstreamDeferred =
        noRealPipelineStateShellReadiness
            .shouldDeferRendererNoRealPipelineStateShellReadiness &&
        noRealPipelineStateShellReadiness
            .shouldReportRendererNoRealPipelineStateShellReadinessBlocked ==
            false
    let upstreamInconsistent =
        noRealPipelineStateShellReadiness
            .shouldReportRendererNoRealPipelineStateShellReadinessBlocked ||
        (
            noRealPipelineStateShellReadiness
                .didSealRendererNoRealPipelineStateShellReadiness &&
            upstreamReady == false &&
            upstreamDeferred == false
        )

    return CjguiInternalRendererRealDrawCallShellIntent(
        noRealPipelineStateShellReadiness,
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

func cjguiInternalBuildRendererRealDrawPrimitiveCommandDenialProof(
    shellIntent: CjguiInternalRendererRealDrawCallShellIntent
): CjguiInternalRendererRealDrawPrimitiveCommandDenialProof {
    let proofReady =
        shellIntent.didPrepareRendererRealDrawCallShellIntent &&
        shellIntent.didPreserveRendererNoRealPipelineStateShellReadiness &&
        shellIntent.didDefineFutureDrawCallShellIntent &&
        shellIntent.didDescribePrimitiveCommandDenialNeed &&
        shellIntent.didKeepDrawCallShellIntentDehydrated &&
        shellIntent.didAvoidDrawReadyWrapper &&
        shellIntent.didAvoidReceiptRecordOutput &&
        shellIntent.didAvoidThinWrapper &&
        shellIntent.shouldDeferRendererRealDrawCallShellIntent == false &&
        shellIntent.shouldReportRendererRealDrawCallShellIntentBlocked ==
            false
    let proofDeferred =
        shellIntent.didPrepareRendererRealDrawCallShellIntent == false &&
        shellIntent.shouldDeferRendererRealDrawCallShellIntent &&
        shellIntent.shouldReportRendererRealDrawCallShellIntentBlocked ==
            false
    let proofInconsistent =
        shellIntent.shouldReportRendererRealDrawCallShellIntentBlocked ||
        (
            shellIntent.didPrepareRendererRealDrawCallShellIntent &&
            proofReady == false
        )

    return CjguiInternalRendererRealDrawPrimitiveCommandDenialProof(
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
        true
    )
}

func cjguiInternalBuildRendererRealDrawGeometryBindingDenialProof(
    primitiveCommandDenialProof:
        CjguiInternalRendererRealDrawPrimitiveCommandDenialProof
): CjguiInternalRendererRealDrawGeometryBindingDenialProof {
    let proofReady =
        primitiveCommandDenialProof
            .didPrepareRendererRealDrawPrimitiveCommandDenialProof &&
        primitiveCommandDenialProof
            .didPreserveRendererRealDrawCallShellIntent &&
        primitiveCommandDenialProof
            .didDefineOwnerLocalPrimitiveCommandDenialProof &&
        primitiveCommandDenialProof.didConfirmNoPrimitiveDrawApiInvocation &&
        primitiveCommandDenialProof
            .didConfirmNoIndexedPrimitiveDrawApiInvocation &&
        primitiveCommandDenialProof.didConfirmNoPrimitiveCommandEmission &&
        primitiveCommandDenialProof
            .didKeepPrimitiveCommandDenialProofDehydrated &&
        primitiveCommandDenialProof.didAvoidPrimitiveCommandReadyWrapper &&
        primitiveCommandDenialProof.didAvoidDrawReadyWrapper &&
        primitiveCommandDenialProof.didAvoidThinWrapper &&
        primitiveCommandDenialProof
            .shouldDeferRendererRealDrawPrimitiveCommandDenialProof == false &&
        primitiveCommandDenialProof
            .shouldReportRendererRealDrawPrimitiveCommandDenialProofBlocked ==
            false
    let proofDeferred =
        primitiveCommandDenialProof
            .didPrepareRendererRealDrawPrimitiveCommandDenialProof == false &&
        primitiveCommandDenialProof
            .shouldDeferRendererRealDrawPrimitiveCommandDenialProof &&
        primitiveCommandDenialProof
            .shouldReportRendererRealDrawPrimitiveCommandDenialProofBlocked ==
            false
    let proofInconsistent =
        primitiveCommandDenialProof
            .shouldReportRendererRealDrawPrimitiveCommandDenialProofBlocked ||
        (
            primitiveCommandDenialProof
                .didPrepareRendererRealDrawPrimitiveCommandDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealDrawGeometryBindingDenialProof(
        primitiveCommandDenialProof,
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
        true,
        true
    )
}

func cjguiInternalBuildRendererRealDrawOrderingAdmissionShell(
    geometryBindingDenialProof:
        CjguiInternalRendererRealDrawGeometryBindingDenialProof
): CjguiInternalRendererRealDrawOrderingAdmissionShell {
    let proofReady =
        geometryBindingDenialProof
            .didPrepareRendererRealDrawGeometryBindingDenialProof &&
        geometryBindingDenialProof
            .didPreserveRendererRealDrawPrimitiveCommandDenialProof &&
        geometryBindingDenialProof
            .didDefineOwnerLocalGeometryBindingDenialProof &&
        geometryBindingDenialProof.didConfirmNoVertexBufferBinding &&
        geometryBindingDenialProof.didConfirmNoIndexBufferBinding &&
        geometryBindingDenialProof.didConfirmNoTextureBinding &&
        geometryBindingDenialProof.didConfirmNoResourceBinding &&
        geometryBindingDenialProof.didConfirmNoPipelineRelationMutation &&
        geometryBindingDenialProof
            .didKeepGeometryBindingDenialProofDehydrated &&
        geometryBindingDenialProof.didAvoidGeometryBindingReadyWrapper &&
        geometryBindingDenialProof.didAvoidResourceBindingReadyWrapper &&
        geometryBindingDenialProof.didAvoidThinWrapper &&
        geometryBindingDenialProof
            .shouldDeferRendererRealDrawGeometryBindingDenialProof == false &&
        geometryBindingDenialProof
            .shouldReportRendererRealDrawGeometryBindingDenialProofBlocked ==
            false
    let proofDeferred =
        geometryBindingDenialProof
            .didPrepareRendererRealDrawGeometryBindingDenialProof == false &&
        geometryBindingDenialProof
            .shouldDeferRendererRealDrawGeometryBindingDenialProof &&
        geometryBindingDenialProof
            .shouldReportRendererRealDrawGeometryBindingDenialProofBlocked ==
            false
    let proofInconsistent =
        geometryBindingDenialProof
            .shouldReportRendererRealDrawGeometryBindingDenialProofBlocked ||
        (
            geometryBindingDenialProof
                .didPrepareRendererRealDrawGeometryBindingDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererRealDrawOrderingAdmissionShell(
        geometryBindingDenialProof,
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

func cjguiInternalBuildRendererRealDrawExecutionDenialProof(
    orderingAdmissionShell:
        CjguiInternalRendererRealDrawOrderingAdmissionShell
): CjguiInternalRendererRealDrawExecutionDenialProof {
    let proofReady =
        orderingAdmissionShell
            .didPrepareRendererRealDrawOrderingAdmissionShell &&
        orderingAdmissionShell
            .didPreserveRendererRealDrawGeometryBindingDenialProof &&
        orderingAdmissionShell.didDefineOwnerLocalDrawOrderingAdmissionShell &&
        orderingAdmissionShell.didRecordOrderingAsAdmissionOnly &&
        orderingAdmissionShell.didConfirmNoGpuOrderingExecution &&
        orderingAdmissionShell.didConfirmNoRenderPassMutation &&
        orderingAdmissionShell.didKeepDrawOrderingAdmissionShellDehydrated &&
        orderingAdmissionShell.didAvoidOrderingReadyWrapper &&
        orderingAdmissionShell.didAvoidRenderReadyWrapper &&
        orderingAdmissionShell.didAvoidThinWrapper &&
        orderingAdmissionShell
            .shouldDeferRendererRealDrawOrderingAdmissionShell == false &&
        orderingAdmissionShell
            .shouldReportRendererRealDrawOrderingAdmissionShellBlocked ==
            false
    let proofDeferred =
        orderingAdmissionShell
            .didPrepareRendererRealDrawOrderingAdmissionShell == false &&
        orderingAdmissionShell
            .shouldDeferRendererRealDrawOrderingAdmissionShell &&
        orderingAdmissionShell
            .shouldReportRendererRealDrawOrderingAdmissionShellBlocked ==
            false
    let proofInconsistent =
        orderingAdmissionShell
            .shouldReportRendererRealDrawOrderingAdmissionShellBlocked ||
        (
            orderingAdmissionShell
                .didPrepareRendererRealDrawOrderingAdmissionShell &&
            proofReady == false
        )

    return CjguiInternalRendererRealDrawExecutionDenialProof(
        orderingAdmissionShell,
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

func cjguiInternalBuildRendererNoRealDrawCallShellReadiness(
    drawExecutionDenialProof:
        CjguiInternalRendererRealDrawExecutionDenialProof
): CjguiInternalRendererNoRealDrawCallShellReadiness {
    let proofReady =
        drawExecutionDenialProof
            .didPrepareRendererRealDrawExecutionDenialProof &&
        drawExecutionDenialProof
            .didPreserveRendererRealDrawOrderingAdmissionShell &&
        drawExecutionDenialProof.didDefineOwnerLocalDrawExecutionDenialProof &&
        drawExecutionDenialProof.didConfirmNoDrawCommandExecution &&
        drawExecutionDenialProof.didConfirmNoEncoderCommandStreamMutation &&
        drawExecutionDenialProof.didConfirmNoGpuSubmission &&
        drawExecutionDenialProof.didConfirmNoRendererStateWrite &&
        drawExecutionDenialProof.didKeepDrawExecutionDenialProofDehydrated &&
        drawExecutionDenialProof.didAvoidDrawReadyWrapper &&
        drawExecutionDenialProof.didAvoidGpuSubmissionWrapper &&
        drawExecutionDenialProof.didAvoidThinWrapper &&
        drawExecutionDenialProof
            .shouldDeferRendererRealDrawExecutionDenialProof == false &&
        drawExecutionDenialProof
            .shouldReportRendererRealDrawExecutionDenialProofBlocked == false
    let proofDeferred =
        drawExecutionDenialProof
            .didPrepareRendererRealDrawExecutionDenialProof == false &&
        drawExecutionDenialProof
            .shouldDeferRendererRealDrawExecutionDenialProof &&
        drawExecutionDenialProof
            .shouldReportRendererRealDrawExecutionDenialProofBlocked == false
    let proofInconsistent =
        drawExecutionDenialProof
            .shouldReportRendererRealDrawExecutionDenialProofBlocked ||
        (
            drawExecutionDenialProof
                .didPrepareRendererRealDrawExecutionDenialProof &&
            proofReady == false
        )

    return CjguiInternalRendererNoRealDrawCallShellReadiness(
        drawExecutionDenialProof,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererRealDrawCallShellDraft():
    CjguiInternalRendererNoRealDrawCallShellReadiness {
    let noRealPipelineStateShellReadiness =
        cjguiInternalExecuteDefaultRendererRealPipelineStateShellDraft()
    let shellIntent =
        cjguiInternalBuildRendererRealDrawCallShellIntent(
            noRealPipelineStateShellReadiness
        )
    let primitiveCommandDenialProof =
        cjguiInternalBuildRendererRealDrawPrimitiveCommandDenialProof(
            shellIntent
        )
    let geometryBindingDenialProof =
        cjguiInternalBuildRendererRealDrawGeometryBindingDenialProof(
            primitiveCommandDenialProof
        )
    let orderingAdmissionShell =
        cjguiInternalBuildRendererRealDrawOrderingAdmissionShell(
            geometryBindingDenialProof
        )
    let drawExecutionDenialProof =
        cjguiInternalBuildRendererRealDrawExecutionDenialProof(
            orderingAdmissionShell
        )
    return cjguiInternalBuildRendererNoRealDrawCallShellReadiness(
        drawExecutionDenialProof
    )
}

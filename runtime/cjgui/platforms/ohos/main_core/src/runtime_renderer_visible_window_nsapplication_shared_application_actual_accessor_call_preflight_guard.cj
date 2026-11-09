// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application actual accessor call preflight guard value boundary owner。
// Owner: runtime renderer internal NSApplication shared-application actual
// accessor call preflight guard owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness，
// 固定 future actual-call first slice 仍缺 explicit approval、必须
// main-thread confined、必须 isolated / probe-first，以及 no activation /
// activation policy mutation / event loop / bounded pump / visible order /
// drawable / render / artifact publication / public API / runtime_state.cj
// write / cjpm.toml change facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不实现 bounded pump，
// 不执行 actual teardown，不写 artifact，不发布 diagnostics，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不改 cjpm.toml，不扩 public API，不新增 native bridge C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、visible-ready、drawable-ready、render-ready、backend-ready、
// renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardFacts {
    let didPreserveActualAccessorSideEffectAuditReadiness: Bool
    let didRequireActualCallFirstSliceExplicitApproval: Bool
    let didConfirmActualCallFirstSliceExplicitApprovalMissing: Bool
    let didConfirmMainThreadConfinedPreflightRequired: Bool
    let didConfirmIsolatedProbeFirstRouteRequired: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoRender: Bool
    let didConfirmNoArtifactPublication: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didKeepActualApplicationSingletonAccessorCallBlocked: Bool
    let didKeepNoApplicationSingletonAccessorCall: Bool
    let didKeepApplicationSingletonCreationBlocked: Bool
    let didKeepActualTeardownExecutionBlocked: Bool
    let didKeepArtifactWriteBlocked: Bool
    let didKeepPublicDiagnosticsBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepActualAccessorCallPreflightGuardValueOnly: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPreserveActualAccessorSideEffectAuditReadiness: Bool,
        didRequireActualCallFirstSliceExplicitApproval: Bool,
        didConfirmActualCallFirstSliceExplicitApprovalMissing: Bool,
        didConfirmMainThreadConfinedPreflightRequired: Bool,
        didConfirmIsolatedProbeFirstRouteRequired: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoRender: Bool,
        didConfirmNoArtifactPublication: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didKeepActualApplicationSingletonAccessorCallBlocked: Bool,
        didKeepNoApplicationSingletonAccessorCall: Bool,
        didKeepApplicationSingletonCreationBlocked: Bool,
        didKeepActualTeardownExecutionBlocked: Bool,
        didKeepArtifactWriteBlocked: Bool,
        didKeepPublicDiagnosticsBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepActualAccessorCallPreflightGuardValueOnly: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPreserveActualAccessorSideEffectAuditReadiness =
            didPreserveActualAccessorSideEffectAuditReadiness
        this.didRequireActualCallFirstSliceExplicitApproval =
            didRequireActualCallFirstSliceExplicitApproval
        this.didConfirmActualCallFirstSliceExplicitApprovalMissing =
            didConfirmActualCallFirstSliceExplicitApprovalMissing
        this.didConfirmMainThreadConfinedPreflightRequired =
            didConfirmMainThreadConfinedPreflightRequired
        this.didConfirmIsolatedProbeFirstRouteRequired =
            didConfirmIsolatedProbeFirstRouteRequired
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoRender = didConfirmNoRender
        this.didConfirmNoArtifactPublication =
            didConfirmNoArtifactPublication
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didKeepActualApplicationSingletonAccessorCallBlocked =
            didKeepActualApplicationSingletonAccessorCallBlocked
        this.didKeepNoApplicationSingletonAccessorCall =
            didKeepNoApplicationSingletonAccessorCall
        this.didKeepApplicationSingletonCreationBlocked =
            didKeepApplicationSingletonCreationBlocked
        this.didKeepActualTeardownExecutionBlocked =
            didKeepActualTeardownExecutionBlocked
        this.didKeepArtifactWriteBlocked = didKeepArtifactWriteBlocked
        this.didKeepPublicDiagnosticsBlocked =
            didKeepPublicDiagnosticsBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicCAbi = didConfirmNoPublicCAbi
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepActualAccessorCallPreflightGuardValueOnly =
            didKeepActualAccessorCallPreflightGuardValueOnly
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidAccessorReadyWrapper = didAvoidAccessorReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuard {
    let actualAccessorCallPreflightGuardFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardFacts
    let didAdmitNsApplicationSharedApplicationActualAccessorCallPreflightGuardBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationActualAccessorCallPreflightGuardBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationActualAccessorCallPreflightGuardBlocked:
        Bool
    let didConfirmActualCallFirstSliceExplicitApprovalMissing: Bool
    let didConfirmMainThreadConfinedPreflightRequired: Bool
    let didConfirmIsolatedProbeFirstRouteRequired: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoRender: Bool
    let didConfirmNoArtifactPublication: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked:
        Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmActualTeardownExecutionStillBlocked: Bool
    let didConfirmArtifactWriteStillBlocked: Bool
    let didConfirmPublicDiagnosticsStillBlocked: Bool
    let didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardValueOnly:
        Bool

    init(
        actualAccessorCallPreflightGuardFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardFacts,
        didAdmitNsApplicationSharedApplicationActualAccessorCallPreflightGuardBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationActualAccessorCallPreflightGuardBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationActualAccessorCallPreflightGuardBlocked:
            Bool,
        didConfirmActualCallFirstSliceExplicitApprovalMissing: Bool,
        didConfirmMainThreadConfinedPreflightRequired: Bool,
        didConfirmIsolatedProbeFirstRouteRequired: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoRender: Bool,
        didConfirmNoArtifactPublication: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked:
            Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmActualTeardownExecutionStillBlocked: Bool,
        didConfirmArtifactWriteStillBlocked: Bool,
        didConfirmPublicDiagnosticsStillBlocked: Bool,
        didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardValueOnly:
            Bool
    ) {
        this.actualAccessorCallPreflightGuardFacts =
            actualAccessorCallPreflightGuardFacts
        this.didAdmitNsApplicationSharedApplicationActualAccessorCallPreflightGuardBoundary =
            didAdmitNsApplicationSharedApplicationActualAccessorCallPreflightGuardBoundary
        this.shouldDeferNsApplicationSharedApplicationActualAccessorCallPreflightGuardBoundary =
            shouldDeferNsApplicationSharedApplicationActualAccessorCallPreflightGuardBoundary
        this.shouldReportNsApplicationSharedApplicationActualAccessorCallPreflightGuardBlocked =
            shouldReportNsApplicationSharedApplicationActualAccessorCallPreflightGuardBlocked
        this.didConfirmActualCallFirstSliceExplicitApprovalMissing =
            didConfirmActualCallFirstSliceExplicitApprovalMissing
        this.didConfirmMainThreadConfinedPreflightRequired =
            didConfirmMainThreadConfinedPreflightRequired
        this.didConfirmIsolatedProbeFirstRouteRequired =
            didConfirmIsolatedProbeFirstRouteRequired
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoRender = didConfirmNoRender
        this.didConfirmNoArtifactPublication =
            didConfirmNoArtifactPublication
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmActualTeardownExecutionStillBlocked =
            didConfirmActualTeardownExecutionStillBlocked
        this.didConfirmArtifactWriteStillBlocked =
            didConfirmArtifactWriteStillBlocked
        this.didConfirmPublicDiagnosticsStillBlocked =
            didConfirmPublicDiagnosticsStillBlocked
        this.didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardValueOnly =
            didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness {
    let nsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness
    let nsApplicationSharedApplicationActualAccessorCallPreflightGuard:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuard
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness:
        Bool
    let didConfirmActualCallFirstSliceExplicitApprovalMissing: Bool
    let didConfirmMainThreadConfinedPreflightRequired: Bool
    let didConfirmIsolatedProbeFirstRouteRequired: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoRender: Bool
    let didConfirmNoArtifactPublication: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmActualApplicationSingletonAccessorCallStillBlocked:
        Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmActualTeardownExecutionStillBlocked: Bool
    let didConfirmArtifactWriteStillBlocked: Bool
    let didConfirmPublicDiagnosticsStillBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        nsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness,
        nsApplicationSharedApplicationActualAccessorCallPreflightGuard:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuard,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness:
            Bool,
        didConfirmActualCallFirstSliceExplicitApprovalMissing: Bool,
        didConfirmMainThreadConfinedPreflightRequired: Bool,
        didConfirmIsolatedProbeFirstRouteRequired: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoRender: Bool,
        didConfirmNoArtifactPublication: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmActualApplicationSingletonAccessorCallStillBlocked:
            Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmActualTeardownExecutionStillBlocked: Bool,
        didConfirmArtifactWriteStillBlocked: Bool,
        didConfirmPublicDiagnosticsStillBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.nsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness =
            nsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness
        this.nsApplicationSharedApplicationActualAccessorCallPreflightGuard =
            nsApplicationSharedApplicationActualAccessorCallPreflightGuard
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardBlocked
        this.didPreserveNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness =
            didPreserveNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness
        this.didConfirmActualCallFirstSliceExplicitApprovalMissing =
            didConfirmActualCallFirstSliceExplicitApprovalMissing
        this.didConfirmMainThreadConfinedPreflightRequired =
            didConfirmMainThreadConfinedPreflightRequired
        this.didConfirmIsolatedProbeFirstRouteRequired =
            didConfirmIsolatedProbeFirstRouteRequired
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoRender = didConfirmNoRender
        this.didConfirmNoArtifactPublication =
            didConfirmNoArtifactPublication
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmActualApplicationSingletonAccessorCallStillBlocked =
            didConfirmActualApplicationSingletonAccessorCallStillBlocked
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmActualTeardownExecutionStillBlocked =
            didConfirmActualTeardownExecutionStillBlocked
        this.didConfirmArtifactWriteStillBlocked =
            didConfirmArtifactWriteStillBlocked
        this.didConfirmPublicDiagnosticsStillBlocked =
            didConfirmPublicDiagnosticsStillBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicCAbi = didConfirmNoPublicCAbi
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadinessDehydrated =
            didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidAccessorReadyWrapper = didAvoidAccessorReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidRenderReadyWrapper = didAvoidRenderReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardFacts(
    actualAccessorSideEffectAuditReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardFacts {
    let upstreamReady =
        actualAccessorSideEffectAuditReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmActualAccessorSideEffectAuditRequired &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmApplicationSingletonLifecycleSideEffectRiskClassified &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmMainThreadAuditBeforeAccessorCallRequired &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmNoApplicationSingletonAccessorCall &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmActualTeardownExecutionStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmArtifactWriteStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmArtifactPublicationStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmPublicDiagnosticsStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmActualEventLoopStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmActualRunLoopPumpStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmActivationPolicyMutationStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmApplicationActivationStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmProductionDrawableStillBlocked &&
        actualAccessorSideEffectAuditReadiness.didConfirmRenderStillBlocked &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        actualAccessorSideEffectAuditReadiness.didConfirmNoPublicSurface &&
        actualAccessorSideEffectAuditReadiness.didConfirmNoPublicCAbi &&
        actualAccessorSideEffectAuditReadiness
            .didConfirmNoRendererStateWrite &&
        actualAccessorSideEffectAuditReadiness.didConfirmNoBackendReadyTruth &&
        actualAccessorSideEffectAuditReadiness
            .didKeepNsApplicationSharedApplicationActualAccessorSideEffectAuditReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardFacts(
        upstreamReady,
        true,
        true,
        true,
        true,
        actualAccessorSideEffectAuditReadiness
            .didConfirmActivationPolicyMutationStillBlocked,
        actualAccessorSideEffectAuditReadiness
            .didConfirmApplicationActivationStillBlocked,
        actualAccessorSideEffectAuditReadiness
            .didConfirmActualEventLoopStillBlocked,
        actualAccessorSideEffectAuditReadiness
            .didConfirmActualRunLoopPumpStillBlocked,
        actualAccessorSideEffectAuditReadiness
            .didConfirmNativeVisibleOrderStillBlocked,
        actualAccessorSideEffectAuditReadiness
            .didConfirmProductionDrawableStillBlocked,
        actualAccessorSideEffectAuditReadiness.didConfirmRenderStillBlocked,
        actualAccessorSideEffectAuditReadiness
            .didConfirmArtifactPublicationStillBlocked,
        actualAccessorSideEffectAuditReadiness.didConfirmNoPublicSurface,
        true,
        true,
        actualAccessorSideEffectAuditReadiness
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        actualAccessorSideEffectAuditReadiness
            .didConfirmNoApplicationSingletonAccessorCall,
        actualAccessorSideEffectAuditReadiness
            .didConfirmApplicationSingletonCreationStillBlocked,
        actualAccessorSideEffectAuditReadiness
            .didConfirmActualTeardownExecutionStillBlocked,
        actualAccessorSideEffectAuditReadiness.didConfirmArtifactWriteStillBlocked,
        actualAccessorSideEffectAuditReadiness
            .didConfirmPublicDiagnosticsStillBlocked,
        actualAccessorSideEffectAuditReadiness
            .didConfirmNoPointerHandleClassIdReturn,
        actualAccessorSideEffectAuditReadiness.didConfirmNoPublicCAbi,
        actualAccessorSideEffectAuditReadiness
            .didConfirmNoRendererStateWrite,
        actualAccessorSideEffectAuditReadiness.didConfirmNoBackendReadyTruth,
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuard(
    actualAccessorCallPreflightGuardFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuard {
    let admitted =
        actualAccessorCallPreflightGuardFacts
            .didPreserveActualAccessorSideEffectAuditReadiness &&
        actualAccessorCallPreflightGuardFacts
            .didRequireActualCallFirstSliceExplicitApproval &&
        actualAccessorCallPreflightGuardFacts
            .didConfirmActualCallFirstSliceExplicitApprovalMissing &&
        actualAccessorCallPreflightGuardFacts
            .didConfirmMainThreadConfinedPreflightRequired &&
        actualAccessorCallPreflightGuardFacts
            .didConfirmIsolatedProbeFirstRouteRequired &&
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoActivationPolicyMutation &&
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoApplicationActivation &&
        actualAccessorCallPreflightGuardFacts.didConfirmNoAppKitEventLoop &&
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoBoundedRunLoopPump &&
        actualAccessorCallPreflightGuardFacts.didConfirmNoVisibleOrder &&
        actualAccessorCallPreflightGuardFacts.didConfirmNoDrawable &&
        actualAccessorCallPreflightGuardFacts.didConfirmNoRender &&
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoArtifactPublication &&
        actualAccessorCallPreflightGuardFacts.didConfirmNoPublicApi &&
        actualAccessorCallPreflightGuardFacts.didConfirmNoRuntimeStateWrite &&
        actualAccessorCallPreflightGuardFacts.didConfirmNoCjpmTomlChange &&
        actualAccessorCallPreflightGuardFacts
            .didKeepActualApplicationSingletonAccessorCallBlocked &&
        actualAccessorCallPreflightGuardFacts
            .didKeepNoApplicationSingletonAccessorCall &&
        actualAccessorCallPreflightGuardFacts
            .didKeepApplicationSingletonCreationBlocked &&
        actualAccessorCallPreflightGuardFacts
            .didKeepActualTeardownExecutionBlocked &&
        actualAccessorCallPreflightGuardFacts.didKeepArtifactWriteBlocked &&
        actualAccessorCallPreflightGuardFacts
            .didKeepPublicDiagnosticsBlocked &&
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoPointerHandleClassIdReturn &&
        actualAccessorCallPreflightGuardFacts.didConfirmNoPublicCAbi &&
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoRendererStateWrite &&
        actualAccessorCallPreflightGuardFacts.didConfirmNoBackendReadyTruth &&
        actualAccessorCallPreflightGuardFacts
            .didKeepActualAccessorCallPreflightGuardValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuard(
        actualAccessorCallPreflightGuardFacts,
        admitted,
        !admitted,
        !admitted,
        actualAccessorCallPreflightGuardFacts
            .didConfirmActualCallFirstSliceExplicitApprovalMissing,
        actualAccessorCallPreflightGuardFacts
            .didConfirmMainThreadConfinedPreflightRequired,
        actualAccessorCallPreflightGuardFacts
            .didConfirmIsolatedProbeFirstRouteRequired,
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoActivationPolicyMutation,
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoApplicationActivation,
        actualAccessorCallPreflightGuardFacts.didConfirmNoAppKitEventLoop,
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoBoundedRunLoopPump,
        actualAccessorCallPreflightGuardFacts.didConfirmNoVisibleOrder,
        actualAccessorCallPreflightGuardFacts.didConfirmNoDrawable,
        actualAccessorCallPreflightGuardFacts.didConfirmNoRender,
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoArtifactPublication,
        actualAccessorCallPreflightGuardFacts.didConfirmNoPublicApi,
        actualAccessorCallPreflightGuardFacts.didConfirmNoRuntimeStateWrite,
        actualAccessorCallPreflightGuardFacts.didConfirmNoCjpmTomlChange,
        actualAccessorCallPreflightGuardFacts
            .didKeepActualApplicationSingletonAccessorCallBlocked,
        actualAccessorCallPreflightGuardFacts
            .didKeepNoApplicationSingletonAccessorCall,
        actualAccessorCallPreflightGuardFacts
            .didKeepApplicationSingletonCreationBlocked,
        actualAccessorCallPreflightGuardFacts
            .didKeepActualTeardownExecutionBlocked,
        actualAccessorCallPreflightGuardFacts.didKeepArtifactWriteBlocked,
        actualAccessorCallPreflightGuardFacts
            .didKeepPublicDiagnosticsBlocked,
        actualAccessorCallPreflightGuardFacts
            .didKeepActualAccessorCallPreflightGuardValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness(
    actualAccessorSideEffectAuditReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness,
    actualAccessorCallPreflightGuard:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuard
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness {
    let admitted =
        actualAccessorCallPreflightGuard
            .didAdmitNsApplicationSharedApplicationActualAccessorCallPreflightGuardBoundary
    let actualAccessorCallPreflightGuardFacts =
        actualAccessorCallPreflightGuard
            .actualAccessorCallPreflightGuardFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness(
        actualAccessorSideEffectAuditReadiness,
        actualAccessorCallPreflightGuard,
        admitted,
        !admitted,
        !admitted,
        actualAccessorCallPreflightGuardFacts
            .didPreserveActualAccessorSideEffectAuditReadiness,
        actualAccessorCallPreflightGuard
            .didConfirmActualCallFirstSliceExplicitApprovalMissing,
        actualAccessorCallPreflightGuard
            .didConfirmMainThreadConfinedPreflightRequired,
        actualAccessorCallPreflightGuard
            .didConfirmIsolatedProbeFirstRouteRequired,
        actualAccessorCallPreflightGuard
            .didConfirmNoActivationPolicyMutation,
        actualAccessorCallPreflightGuard
            .didConfirmNoApplicationActivation,
        actualAccessorCallPreflightGuard.didConfirmNoAppKitEventLoop,
        actualAccessorCallPreflightGuard.didConfirmNoBoundedRunLoopPump,
        actualAccessorCallPreflightGuard.didConfirmNoVisibleOrder,
        actualAccessorCallPreflightGuard.didConfirmNoDrawable,
        actualAccessorCallPreflightGuard.didConfirmNoRender,
        actualAccessorCallPreflightGuard.didConfirmNoArtifactPublication,
        actualAccessorCallPreflightGuard.didConfirmNoPublicApi,
        actualAccessorCallPreflightGuard.didConfirmNoRuntimeStateWrite,
        actualAccessorCallPreflightGuard.didConfirmNoCjpmTomlChange,
        actualAccessorCallPreflightGuard
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked,
        actualAccessorCallPreflightGuard
            .didConfirmNoApplicationSingletonAccessorCall,
        actualAccessorCallPreflightGuard
            .didConfirmApplicationSingletonCreationStillBlocked,
        actualAccessorCallPreflightGuard
            .didConfirmActualTeardownExecutionStillBlocked,
        actualAccessorCallPreflightGuard.didConfirmArtifactWriteStillBlocked,
        actualAccessorCallPreflightGuard
            .didConfirmPublicDiagnosticsStillBlocked,
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoPointerHandleClassIdReturn,
        actualAccessorCallPreflightGuardFacts.didConfirmNoPublicCAbi,
        actualAccessorCallPreflightGuardFacts
            .didConfirmNoRendererStateWrite,
        actualAccessorCallPreflightGuardFacts.didConfirmNoBackendReadyTruth,
        actualAccessorCallPreflightGuard
            .didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardValueOnly,
        actualAccessorCallPreflightGuardFacts.didAvoidApplicationReadyWrapper,
        actualAccessorCallPreflightGuardFacts.didAvoidAccessorReadyWrapper,
        actualAccessorCallPreflightGuardFacts.didAvoidVisibleReadyWrapper,
        actualAccessorCallPreflightGuardFacts.didAvoidDrawableReadyWrapper,
        actualAccessorCallPreflightGuardFacts.didAvoidRenderReadyWrapper,
        actualAccessorCallPreflightGuardFacts.didAvoidBackendReadyWrapper,
        actualAccessorCallPreflightGuardFacts.didAvoidReceiptRecordPublication
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness {
    let actualAccessorSideEffectAuditReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditDraft()
    let actualAccessorCallPreflightGuardFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardFacts(
            actualAccessorSideEffectAuditReadiness
        )
    let actualAccessorCallPreflightGuard =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuard(
            actualAccessorCallPreflightGuardFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness(
        actualAccessorSideEffectAuditReadiness,
        actualAccessorCallPreflightGuard
    )
}

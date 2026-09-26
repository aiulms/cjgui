// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application isolated actual accessor call probe evidence owner。
// Owner: runtime renderer internal NSApplication shared-application isolated
// actual accessor call probe evidence owner。
// Truth: 只消费 actual accessor call preflight guard readiness，并记录人工批准
// 后的 first slice 只能在 isolated native probe 中进行、必须 main-thread gate、
// 仅当 preexisting application singleton 已存在时才允许 actual accessor call，
// 否则 fail-closed，只返回 integer classification / dehydrated facts。
// Stop-line: 不创建 NSApplication，不 activation，不改 activation policy，不运行
// AppKit event loop，不实现 bounded pump，不创建 NSWindow，不 visible order，
// 不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，不 render，不写
// artifact / diagnostics publication，不返回 Class / id / pointer / handle，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、visible-ready、drawable-ready、render-ready、backend-ready、
// renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceFacts {
    let didPreserveActualAccessorCallPreflightGuardReadiness: Bool
    let didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice: Bool
    let didConfineActualAccessorCallToIsolatedNativeProbe: Bool
    let didRequireMainThreadGateBeforeActualAccessorCall: Bool
    let didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent:
        Bool
    let didFailClosedWhenPreexistingApplicationMissing: Bool
    let didReturnIntegerClassificationOnly: Bool
    let didReturnDehydratedFactsOnly: Bool
    let didClassifySideEffectBeforeAndAfterAccessor: Bool
    let didClassifyNilAccessorReturnAsFailure: Bool
    let didClassifySingletonCreationAsFailure: Bool
    let didConfirmNoApplicationCreation: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoWindowCreation: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoRender: Bool
    let didConfirmNoArtifactPublication: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepIsolatedActualAccessorCallProbeEvidenceValueOnly: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidAccessorReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool

    init(
        didPreserveActualAccessorCallPreflightGuardReadiness: Bool,
        didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice:
            Bool,
        didConfineActualAccessorCallToIsolatedNativeProbe: Bool,
        didRequireMainThreadGateBeforeActualAccessorCall: Bool,
        didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent:
            Bool,
        didFailClosedWhenPreexistingApplicationMissing: Bool,
        didReturnIntegerClassificationOnly: Bool,
        didReturnDehydratedFactsOnly: Bool,
        didClassifySideEffectBeforeAndAfterAccessor: Bool,
        didClassifyNilAccessorReturnAsFailure: Bool,
        didClassifySingletonCreationAsFailure: Bool,
        didConfirmNoApplicationCreation: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoWindowCreation: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoRender: Bool,
        didConfirmNoArtifactPublication: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepIsolatedActualAccessorCallProbeEvidenceValueOnly: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidAccessorReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool
    ) {
        this.didPreserveActualAccessorCallPreflightGuardReadiness =
            didPreserveActualAccessorCallPreflightGuardReadiness
        this.didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice =
            didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice
        this.didConfineActualAccessorCallToIsolatedNativeProbe =
            didConfineActualAccessorCallToIsolatedNativeProbe
        this.didRequireMainThreadGateBeforeActualAccessorCall =
            didRequireMainThreadGateBeforeActualAccessorCall
        this.didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent =
            didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent
        this.didFailClosedWhenPreexistingApplicationMissing =
            didFailClosedWhenPreexistingApplicationMissing
        this.didReturnIntegerClassificationOnly =
            didReturnIntegerClassificationOnly
        this.didReturnDehydratedFactsOnly = didReturnDehydratedFactsOnly
        this.didClassifySideEffectBeforeAndAfterAccessor =
            didClassifySideEffectBeforeAndAfterAccessor
        this.didClassifyNilAccessorReturnAsFailure =
            didClassifyNilAccessorReturnAsFailure
        this.didClassifySingletonCreationAsFailure =
            didClassifySingletonCreationAsFailure
        this.didConfirmNoApplicationCreation =
            didConfirmNoApplicationCreation
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoWindowCreation = didConfirmNoWindowCreation
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoRender = didConfirmNoRender
        this.didConfirmNoArtifactPublication =
            didConfirmNoArtifactPublication
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepIsolatedActualAccessorCallProbeEvidenceValueOnly =
            didKeepIsolatedActualAccessorCallProbeEvidenceValueOnly
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence {
    let isolatedActualAccessorCallProbeEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceFacts
    let didAdmitNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBoundary:
        Bool
    let shouldDeferNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBoundary:
        Bool
    let shouldReportNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBlocked:
        Bool
    let didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice: Bool
    let didConfineActualAccessorCallToIsolatedNativeProbe: Bool
    let didRequireMainThreadGateBeforeActualAccessorCall: Bool
    let didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent:
        Bool
    let didFailClosedWhenPreexistingApplicationMissing: Bool
    let didReturnIntegerClassificationOnly: Bool
    let didReturnDehydratedFactsOnly: Bool
    let didClassifySideEffectBeforeAndAfterAccessor: Bool
    let didClassifyNilAccessorReturnAsFailure: Bool
    let didClassifySingletonCreationAsFailure: Bool
    let didConfirmNoApplicationCreation: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoWindowCreation: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoRender: Bool
    let didConfirmNoArtifactPublication: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didKeepNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceValueOnly:
        Bool

    init(
        isolatedActualAccessorCallProbeEvidenceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceFacts,
        didAdmitNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBoundary:
            Bool,
        shouldDeferNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBoundary:
            Bool,
        shouldReportNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBlocked:
            Bool,
        didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice:
            Bool,
        didConfineActualAccessorCallToIsolatedNativeProbe: Bool,
        didRequireMainThreadGateBeforeActualAccessorCall: Bool,
        didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent:
            Bool,
        didFailClosedWhenPreexistingApplicationMissing: Bool,
        didReturnIntegerClassificationOnly: Bool,
        didReturnDehydratedFactsOnly: Bool,
        didClassifySideEffectBeforeAndAfterAccessor: Bool,
        didClassifyNilAccessorReturnAsFailure: Bool,
        didClassifySingletonCreationAsFailure: Bool,
        didConfirmNoApplicationCreation: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoWindowCreation: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoRender: Bool,
        didConfirmNoArtifactPublication: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didKeepNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceValueOnly:
            Bool
    ) {
        this.isolatedActualAccessorCallProbeEvidenceFacts =
            isolatedActualAccessorCallProbeEvidenceFacts
        this.didAdmitNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBoundary =
            didAdmitNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBoundary
        this.shouldDeferNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBoundary =
            shouldDeferNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBoundary
        this.shouldReportNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBlocked =
            shouldReportNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBlocked
        this.didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice =
            didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice
        this.didConfineActualAccessorCallToIsolatedNativeProbe =
            didConfineActualAccessorCallToIsolatedNativeProbe
        this.didRequireMainThreadGateBeforeActualAccessorCall =
            didRequireMainThreadGateBeforeActualAccessorCall
        this.didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent =
            didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent
        this.didFailClosedWhenPreexistingApplicationMissing =
            didFailClosedWhenPreexistingApplicationMissing
        this.didReturnIntegerClassificationOnly =
            didReturnIntegerClassificationOnly
        this.didReturnDehydratedFactsOnly = didReturnDehydratedFactsOnly
        this.didClassifySideEffectBeforeAndAfterAccessor =
            didClassifySideEffectBeforeAndAfterAccessor
        this.didClassifyNilAccessorReturnAsFailure =
            didClassifyNilAccessorReturnAsFailure
        this.didClassifySingletonCreationAsFailure =
            didClassifySingletonCreationAsFailure
        this.didConfirmNoApplicationCreation =
            didConfirmNoApplicationCreation
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoWindowCreation = didConfirmNoWindowCreation
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoRender = didConfirmNoRender
        this.didConfirmNoArtifactPublication =
            didConfirmNoArtifactPublication
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didKeepNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceValueOnly =
            didKeepNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness {
    let nsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness
    let nsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBlocked:
        Bool
    let didPreserveActualAccessorCallPreflightGuardReadiness: Bool
    let didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice: Bool
    let didConfineActualAccessorCallToIsolatedNativeProbe: Bool
    let didRequireMainThreadGateBeforeActualAccessorCall: Bool
    let didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent:
        Bool
    let didFailClosedWhenPreexistingApplicationMissing: Bool
    let didReturnIntegerClassificationOnly: Bool
    let didReturnDehydratedFactsOnly: Bool
    let didClassifySideEffectBeforeAndAfterAccessor: Bool
    let didClassifyNilAccessorReturnAsFailure: Bool
    let didClassifySingletonCreationAsFailure: Bool
    let didConfirmNoApplicationCreation: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoWindowCreation: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoRender: Bool
    let didConfirmNoArtifactPublication: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didKeepNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadinessDehydrated:
        Bool

    init(
        nsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness,
        nsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBlocked:
            Bool,
        didPreserveActualAccessorCallPreflightGuardReadiness: Bool,
        didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice:
            Bool,
        didConfineActualAccessorCallToIsolatedNativeProbe: Bool,
        didRequireMainThreadGateBeforeActualAccessorCall: Bool,
        didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent:
            Bool,
        didFailClosedWhenPreexistingApplicationMissing: Bool,
        didReturnIntegerClassificationOnly: Bool,
        didReturnDehydratedFactsOnly: Bool,
        didClassifySideEffectBeforeAndAfterAccessor: Bool,
        didClassifyNilAccessorReturnAsFailure: Bool,
        didClassifySingletonCreationAsFailure: Bool,
        didConfirmNoApplicationCreation: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoWindowCreation: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoRender: Bool,
        didConfirmNoArtifactPublication: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didKeepNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadinessDehydrated:
            Bool
    ) {
        this.nsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness =
            nsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness
        this.nsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence =
            nsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBlocked
        this.didPreserveActualAccessorCallPreflightGuardReadiness =
            didPreserveActualAccessorCallPreflightGuardReadiness
        this.didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice =
            didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice
        this.didConfineActualAccessorCallToIsolatedNativeProbe =
            didConfineActualAccessorCallToIsolatedNativeProbe
        this.didRequireMainThreadGateBeforeActualAccessorCall =
            didRequireMainThreadGateBeforeActualAccessorCall
        this.didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent =
            didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent
        this.didFailClosedWhenPreexistingApplicationMissing =
            didFailClosedWhenPreexistingApplicationMissing
        this.didReturnIntegerClassificationOnly =
            didReturnIntegerClassificationOnly
        this.didReturnDehydratedFactsOnly = didReturnDehydratedFactsOnly
        this.didClassifySideEffectBeforeAndAfterAccessor =
            didClassifySideEffectBeforeAndAfterAccessor
        this.didClassifyNilAccessorReturnAsFailure =
            didClassifyNilAccessorReturnAsFailure
        this.didClassifySingletonCreationAsFailure =
            didClassifySingletonCreationAsFailure
        this.didConfirmNoApplicationCreation =
            didConfirmNoApplicationCreation
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoWindowCreation = didConfirmNoWindowCreation
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoRender = didConfirmNoRender
        this.didConfirmNoArtifactPublication =
            didConfirmNoArtifactPublication
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didKeepNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadinessDehydrated =
            didKeepNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadinessDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceFacts(
    actualAccessorCallPreflightGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceFacts {
    let upstreamReady =
        actualAccessorCallPreflightGuardReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness &&
        actualAccessorCallPreflightGuardReadiness
            .didPreserveNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmMainThreadConfinedPreflightRequired &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmIsolatedProbeFirstRouteRequired &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoActivationPolicyMutation &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoApplicationActivation &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoAppKitEventLoop &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoBoundedRunLoopPump &&
        actualAccessorCallPreflightGuardReadiness.didConfirmNoVisibleOrder &&
        actualAccessorCallPreflightGuardReadiness.didConfirmNoDrawable &&
        actualAccessorCallPreflightGuardReadiness.didConfirmNoRender &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoArtifactPublication &&
        actualAccessorCallPreflightGuardReadiness.didConfirmNoPublicApi &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoRuntimeStateWrite &&
        actualAccessorCallPreflightGuardReadiness.didConfirmNoCjpmTomlChange &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        actualAccessorCallPreflightGuardReadiness.didConfirmNoPublicCAbi &&
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoRendererStateWrite &&
        actualAccessorCallPreflightGuardReadiness.didConfirmNoBackendReadyTruth &&
        actualAccessorCallPreflightGuardReadiness
            .didKeepNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadinessDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceFacts(
        upstreamReady,
        true,
        true,
        actualAccessorCallPreflightGuardReadiness
            .didConfirmMainThreadConfinedPreflightRequired,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        actualAccessorCallPreflightGuardReadiness
            .didConfirmApplicationSingletonCreationStillBlocked,
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoActivationPolicyMutation,
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoApplicationActivation,
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoAppKitEventLoop,
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoBoundedRunLoopPump,
        true,
        actualAccessorCallPreflightGuardReadiness.didConfirmNoVisibleOrder,
        actualAccessorCallPreflightGuardReadiness.didConfirmNoDrawable,
        actualAccessorCallPreflightGuardReadiness.didConfirmNoRender,
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoArtifactPublication,
        actualAccessorCallPreflightGuardReadiness.didConfirmNoPublicApi,
        actualAccessorCallPreflightGuardReadiness.didConfirmNoPublicCAbi,
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoRuntimeStateWrite,
        actualAccessorCallPreflightGuardReadiness.didConfirmNoCjpmTomlChange,
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoPointerHandleClassIdReturn,
        actualAccessorCallPreflightGuardReadiness
            .didConfirmNoRendererStateWrite,
        actualAccessorCallPreflightGuardReadiness.didConfirmNoBackendReadyTruth,
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence(
    isolatedActualAccessorCallProbeEvidenceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence {
    let admitted =
        isolatedActualAccessorCallProbeEvidenceFacts
            .didPreserveActualAccessorCallPreflightGuardReadiness &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfineActualAccessorCallToIsolatedNativeProbe &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didRequireMainThreadGateBeforeActualAccessorCall &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didFailClosedWhenPreexistingApplicationMissing &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didReturnIntegerClassificationOnly &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didReturnDehydratedFactsOnly &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didClassifySideEffectBeforeAndAfterAccessor &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didClassifyNilAccessorReturnAsFailure &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didClassifySingletonCreationAsFailure &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoApplicationCreation &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoActivationPolicyMutation &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoApplicationActivation &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoAppKitEventLoop &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoBoundedRunLoopPump &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoWindowCreation &&
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoVisibleOrder &&
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoDrawable &&
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoRender &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoArtifactPublication &&
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoPublicApi &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoProductionPublicCAbi &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoRuntimeStateWrite &&
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoCjpmTomlChange &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoPointerHandleClassIdReturn &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoRendererStateWrite &&
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoBackendReadyTruth &&
        isolatedActualAccessorCallProbeEvidenceFacts
            .didKeepIsolatedActualAccessorCallProbeEvidenceValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence(
        isolatedActualAccessorCallProbeEvidenceFacts,
        admitted,
        !admitted,
        !admitted,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfineActualAccessorCallToIsolatedNativeProbe,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didRequireMainThreadGateBeforeActualAccessorCall,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didFailClosedWhenPreexistingApplicationMissing,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didReturnIntegerClassificationOnly,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didReturnDehydratedFactsOnly,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didClassifySideEffectBeforeAndAfterAccessor,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didClassifyNilAccessorReturnAsFailure,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didClassifySingletonCreationAsFailure,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoApplicationCreation,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoActivationPolicyMutation,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoApplicationActivation,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoAppKitEventLoop,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoBoundedRunLoopPump,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoWindowCreation,
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoVisibleOrder,
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoDrawable,
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoRender,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoArtifactPublication,
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoPublicApi,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoProductionPublicCAbi,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didConfirmNoRuntimeStateWrite,
        isolatedActualAccessorCallProbeEvidenceFacts.didConfirmNoCjpmTomlChange,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didKeepIsolatedActualAccessorCallProbeEvidenceValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness(
    actualAccessorCallPreflightGuardReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness,
    isolatedActualAccessorCallProbeEvidence:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness {
    let admitted =
        isolatedActualAccessorCallProbeEvidence
            .didAdmitNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceBoundary
    let isolatedActualAccessorCallProbeEvidenceFacts =
        isolatedActualAccessorCallProbeEvidence
            .isolatedActualAccessorCallProbeEvidenceFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness(
        actualAccessorCallPreflightGuardReadiness,
        isolatedActualAccessorCallProbeEvidence,
        admitted,
        !admitted,
        !admitted,
        isolatedActualAccessorCallProbeEvidenceFacts
            .didPreserveActualAccessorCallPreflightGuardReadiness,
        isolatedActualAccessorCallProbeEvidence
            .didConfirmExplicitHumanApprovalForIsolatedActualCallFirstSlice,
        isolatedActualAccessorCallProbeEvidence
            .didConfineActualAccessorCallToIsolatedNativeProbe,
        isolatedActualAccessorCallProbeEvidence
            .didRequireMainThreadGateBeforeActualAccessorCall,
        isolatedActualAccessorCallProbeEvidence
            .didAllowActualAccessorCallOnlyWhenPreexistingNsApplicationPresent,
        isolatedActualAccessorCallProbeEvidence
            .didFailClosedWhenPreexistingApplicationMissing,
        isolatedActualAccessorCallProbeEvidence
            .didReturnIntegerClassificationOnly,
        isolatedActualAccessorCallProbeEvidence.didReturnDehydratedFactsOnly,
        isolatedActualAccessorCallProbeEvidence
            .didClassifySideEffectBeforeAndAfterAccessor,
        isolatedActualAccessorCallProbeEvidence
            .didClassifyNilAccessorReturnAsFailure,
        isolatedActualAccessorCallProbeEvidence
            .didClassifySingletonCreationAsFailure,
        isolatedActualAccessorCallProbeEvidence.didConfirmNoApplicationCreation,
        isolatedActualAccessorCallProbeEvidence
            .didConfirmNoActivationPolicyMutation,
        isolatedActualAccessorCallProbeEvidence
            .didConfirmNoApplicationActivation,
        isolatedActualAccessorCallProbeEvidence.didConfirmNoAppKitEventLoop,
        isolatedActualAccessorCallProbeEvidence
            .didConfirmNoBoundedRunLoopPump,
        isolatedActualAccessorCallProbeEvidence.didConfirmNoWindowCreation,
        isolatedActualAccessorCallProbeEvidence.didConfirmNoVisibleOrder,
        isolatedActualAccessorCallProbeEvidence.didConfirmNoDrawable,
        isolatedActualAccessorCallProbeEvidence.didConfirmNoRender,
        isolatedActualAccessorCallProbeEvidence
            .didConfirmNoArtifactPublication,
        isolatedActualAccessorCallProbeEvidence.didConfirmNoPublicApi,
        isolatedActualAccessorCallProbeEvidence
            .didConfirmNoProductionPublicCAbi,
        isolatedActualAccessorCallProbeEvidence.didConfirmNoRuntimeStateWrite,
        isolatedActualAccessorCallProbeEvidence.didConfirmNoCjpmTomlChange,
        isolatedActualAccessorCallProbeEvidence
            .didKeepNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceValueOnly
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness {
    let actualAccessorCallPreflightGuardReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()
    let isolatedActualAccessorCallProbeEvidenceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceFacts(
            actualAccessorCallPreflightGuardReadiness
        )
    let isolatedActualAccessorCallProbeEvidence =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidence(
            isolatedActualAccessorCallProbeEvidenceFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness(
        actualAccessorCallPreflightGuardReadiness,
        isolatedActualAccessorCallProbeEvidence
    )
}

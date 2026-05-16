// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application external preexisting singleton source witness admission
// policy preflight owner。
// Owner: runtime renderer internal external preexisting singleton source
// witness admission policy preflight owner。
// Truth: 只消费 source witness contract shape，固定未来 admission policy
// 必须先校验外部 owner identity、preexisting singleton observation、
// main-thread observation proof、source lifetime、cleanup ownership 与
// no-creation / no-accessor invariant，且仍保持 witness truth / production
// singleton ownership truth 为 false。
// Stop-line: 不实现 production singleton owner，不调用 application singleton
// accessor，不创建或激活 NSApplication，不修改 activation policy，不运行
// AppKit event loop / bounded pump，不执行 cleanup / teardown，不创建 window /
// view / layer，不 visible order，不取 drawable，不创建 command queue / command
// buffer / encoder，不 render / commit / present / GPU submission，不写 artifact
// / diagnostics publication，不返回 Class / id / pointer / handle，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、
// accessor-ready、singleton-owner-ready、visible-ready、drawable-ready、
// render-ready、backend-ready、renderer state write、receipt、record 或
// publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightFacts {
    let didPreserveExternalPreexistingSingletonSourceWitnessContractShape:
        Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDecision:
        Bool
    let didRequireAdmissionPolicyBeforeWitnessTruth: Bool
    let didRequireWitnessFieldsCompleteBeforeAdmission: Bool
    let didRequireExternalOwnerIdentityBeforeAdmission: Bool
    let didRequirePreexistingSingletonObservationBeforeAdmission: Bool
    let didRequireMainThreadObservationProofBeforeAdmission: Bool
    let didRequireSourceLifetimeProofBeforeAdmission: Bool
    let didRequireExternalCleanupOwnershipBeforeAdmission: Bool
    let didRequireNoRendererAccessorCallDuringAdmission: Bool
    let didRequireNoRendererCreationDuringAdmission: Bool
    let didRequireNoCleanupExecutionDuringAdmission: Bool
    let didRequireHeadlessFailClosedAdmission: Bool
    let didRequireNonUserVisibleAdmission: Bool
    let didRequireAdmissionResultRemainDehydrated: Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
        Bool
    let didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didConfirmNoActivationPolicyMutation: Bool
    let didConfirmNoApplicationActivation: Bool
    let didConfirmNoAppKitEventLoop: Bool
    let didConfirmNoBoundedRunLoopPump: Bool
    let didConfirmNoWindowViewLayerCreation: Bool
    let didConfirmNoVisibleOrder: Bool
    let didConfirmNoDrawable: Bool
    let didConfirmNoCommandQueueBufferEncoder: Bool
    let didConfirmNoRenderCommitPresentGpuSubmission: Bool
    let didConfirmNoArtifactOrDiagnosticsPublication: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didPreserveExternalPreexistingSingletonSourceWitnessContractShape:
            Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDecision:
            Bool,
        didRequireAdmissionPolicyBeforeWitnessTruth: Bool,
        didRequireWitnessFieldsCompleteBeforeAdmission: Bool,
        didRequireExternalOwnerIdentityBeforeAdmission: Bool,
        didRequirePreexistingSingletonObservationBeforeAdmission: Bool,
        didRequireMainThreadObservationProofBeforeAdmission: Bool,
        didRequireSourceLifetimeProofBeforeAdmission: Bool,
        didRequireExternalCleanupOwnershipBeforeAdmission: Bool,
        didRequireNoRendererAccessorCallDuringAdmission: Bool,
        didRequireNoRendererCreationDuringAdmission: Bool,
        didRequireNoCleanupExecutionDuringAdmission: Bool,
        didRequireHeadlessFailClosedAdmission: Bool,
        didRequireNonUserVisibleAdmission: Bool,
        didRequireAdmissionResultRemainDehydrated: Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didConfirmNoActivationPolicyMutation: Bool,
        didConfirmNoApplicationActivation: Bool,
        didConfirmNoAppKitEventLoop: Bool,
        didConfirmNoBoundedRunLoopPump: Bool,
        didConfirmNoWindowViewLayerCreation: Bool,
        didConfirmNoVisibleOrder: Bool,
        didConfirmNoDrawable: Bool,
        didConfirmNoCommandQueueBufferEncoder: Bool,
        didConfirmNoRenderCommitPresentGpuSubmission: Bool,
        didConfirmNoArtifactOrDiagnosticsPublication: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didPreserveExternalPreexistingSingletonSourceWitnessContractShape =
            didPreserveExternalPreexistingSingletonSourceWitnessContractShape
        this.didConfirmExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDecision =
            didConfirmExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDecision
        this.didRequireAdmissionPolicyBeforeWitnessTruth =
            didRequireAdmissionPolicyBeforeWitnessTruth
        this.didRequireWitnessFieldsCompleteBeforeAdmission =
            didRequireWitnessFieldsCompleteBeforeAdmission
        this.didRequireExternalOwnerIdentityBeforeAdmission =
            didRequireExternalOwnerIdentityBeforeAdmission
        this.didRequirePreexistingSingletonObservationBeforeAdmission =
            didRequirePreexistingSingletonObservationBeforeAdmission
        this.didRequireMainThreadObservationProofBeforeAdmission =
            didRequireMainThreadObservationProofBeforeAdmission
        this.didRequireSourceLifetimeProofBeforeAdmission =
            didRequireSourceLifetimeProofBeforeAdmission
        this.didRequireExternalCleanupOwnershipBeforeAdmission =
            didRequireExternalCleanupOwnershipBeforeAdmission
        this.didRequireNoRendererAccessorCallDuringAdmission =
            didRequireNoRendererAccessorCallDuringAdmission
        this.didRequireNoRendererCreationDuringAdmission =
            didRequireNoRendererCreationDuringAdmission
        this.didRequireNoCleanupExecutionDuringAdmission =
            didRequireNoCleanupExecutionDuringAdmission
        this.didRequireHeadlessFailClosedAdmission =
            didRequireHeadlessFailClosedAdmission
        this.didRequireNonUserVisibleAdmission =
            didRequireNonUserVisibleAdmission
        this.didRequireAdmissionResultRemainDehydrated =
            didRequireAdmissionResultRemainDehydrated
        this.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse
        this.didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didConfirmNoActivationPolicyMutation =
            didConfirmNoActivationPolicyMutation
        this.didConfirmNoApplicationActivation =
            didConfirmNoApplicationActivation
        this.didConfirmNoAppKitEventLoop = didConfirmNoAppKitEventLoop
        this.didConfirmNoBoundedRunLoopPump =
            didConfirmNoBoundedRunLoopPump
        this.didConfirmNoWindowViewLayerCreation =
            didConfirmNoWindowViewLayerCreation
        this.didConfirmNoVisibleOrder = didConfirmNoVisibleOrder
        this.didConfirmNoDrawable = didConfirmNoDrawable
        this.didConfirmNoCommandQueueBufferEncoder =
            didConfirmNoCommandQueueBufferEncoder
        this.didConfirmNoRenderCommitPresentGpuSubmission =
            didConfirmNoRenderCommitPresentGpuSubmission
        this.didConfirmNoArtifactOrDiagnosticsPublication =
            didConfirmNoArtifactOrDiagnosticsPublication
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly =
            didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight {
    let witnessAdmissionPolicyPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightFacts
    let didAdmitExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight:
        Bool
    let shouldDeferExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight:
        Bool
    let shouldReportExternalPreexistingSingletonSourceWitnessAdmissionPolicyBlocked:
        Bool
    let didRequireAdmissionPolicyBeforeWitnessTruth: Bool
    let didRequireWitnessFieldsCompleteBeforeAdmission: Bool
    let didRequireExternalOwnerIdentityBeforeAdmission: Bool
    let didRequirePreexistingSingletonObservationBeforeAdmission: Bool
    let didRequireMainThreadObservationProofBeforeAdmission: Bool
    let didRequireNoRendererAccessorCallDuringAdmission: Bool
    let didRequireNoRendererCreationDuringAdmission: Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly:
        Bool

    init(
        witnessAdmissionPolicyPreflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightFacts,
        didAdmitExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight:
            Bool,
        shouldDeferExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight:
            Bool,
        shouldReportExternalPreexistingSingletonSourceWitnessAdmissionPolicyBlocked:
            Bool,
        didRequireAdmissionPolicyBeforeWitnessTruth: Bool,
        didRequireWitnessFieldsCompleteBeforeAdmission: Bool,
        didRequireExternalOwnerIdentityBeforeAdmission: Bool,
        didRequirePreexistingSingletonObservationBeforeAdmission: Bool,
        didRequireMainThreadObservationProofBeforeAdmission: Bool,
        didRequireNoRendererAccessorCallDuringAdmission: Bool,
        didRequireNoRendererCreationDuringAdmission: Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly:
            Bool
    ) {
        this.witnessAdmissionPolicyPreflightFacts =
            witnessAdmissionPolicyPreflightFacts
        this.didAdmitExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight =
            didAdmitExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight
        this.shouldDeferExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight =
            shouldDeferExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight
        this.shouldReportExternalPreexistingSingletonSourceWitnessAdmissionPolicyBlocked =
            shouldReportExternalPreexistingSingletonSourceWitnessAdmissionPolicyBlocked
        this.didRequireAdmissionPolicyBeforeWitnessTruth =
            didRequireAdmissionPolicyBeforeWitnessTruth
        this.didRequireWitnessFieldsCompleteBeforeAdmission =
            didRequireWitnessFieldsCompleteBeforeAdmission
        this.didRequireExternalOwnerIdentityBeforeAdmission =
            didRequireExternalOwnerIdentityBeforeAdmission
        this.didRequirePreexistingSingletonObservationBeforeAdmission =
            didRequirePreexistingSingletonObservationBeforeAdmission
        this.didRequireMainThreadObservationProofBeforeAdmission =
            didRequireMainThreadObservationProofBeforeAdmission
        this.didRequireNoRendererAccessorCallDuringAdmission =
            didRequireNoRendererAccessorCallDuringAdmission
        this.didRequireNoRendererCreationDuringAdmission =
            didRequireNoRendererCreationDuringAdmission
        this.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly =
            didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness {
    let sourceWitnessContractShapeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness
    let witnessAdmissionPolicyPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight
    let didPrepareExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight:
        Bool
    let shouldDeferExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight:
        Bool
    let shouldReportExternalPreexistingSingletonSourceWitnessAdmissionPolicyBlocked:
        Bool
    let didPreserveExternalPreexistingSingletonSourceWitnessContractShape:
        Bool
    let didRequireAdmissionPolicyBeforeWitnessTruth: Bool
    let didRequireWitnessFieldsCompleteBeforeAdmission: Bool
    let didRequireExternalOwnerIdentityBeforeAdmission: Bool
    let didRequirePreexistingSingletonObservationBeforeAdmission: Bool
    let didRequireMainThreadObservationProofBeforeAdmission: Bool
    let didRequireNoRendererAccessorCallDuringAdmission: Bool
    let didRequireNoRendererCreationDuringAdmission: Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDehydrated:
        Bool

    init(
        sourceWitnessContractShapeReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness,
        witnessAdmissionPolicyPreflight:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight,
        didPrepareExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight:
            Bool,
        shouldDeferExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight:
            Bool,
        shouldReportExternalPreexistingSingletonSourceWitnessAdmissionPolicyBlocked:
            Bool,
        didPreserveExternalPreexistingSingletonSourceWitnessContractShape:
            Bool,
        didRequireAdmissionPolicyBeforeWitnessTruth: Bool,
        didRequireWitnessFieldsCompleteBeforeAdmission: Bool,
        didRequireExternalOwnerIdentityBeforeAdmission: Bool,
        didRequirePreexistingSingletonObservationBeforeAdmission: Bool,
        didRequireMainThreadObservationProofBeforeAdmission: Bool,
        didRequireNoRendererAccessorCallDuringAdmission: Bool,
        didRequireNoRendererCreationDuringAdmission: Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDehydrated:
            Bool
    ) {
        this.sourceWitnessContractShapeReadiness =
            sourceWitnessContractShapeReadiness
        this.witnessAdmissionPolicyPreflight =
            witnessAdmissionPolicyPreflight
        this.didPrepareExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight =
            didPrepareExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight
        this.shouldDeferExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight =
            shouldDeferExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight
        this.shouldReportExternalPreexistingSingletonSourceWitnessAdmissionPolicyBlocked =
            shouldReportExternalPreexistingSingletonSourceWitnessAdmissionPolicyBlocked
        this.didPreserveExternalPreexistingSingletonSourceWitnessContractShape =
            didPreserveExternalPreexistingSingletonSourceWitnessContractShape
        this.didRequireAdmissionPolicyBeforeWitnessTruth =
            didRequireAdmissionPolicyBeforeWitnessTruth
        this.didRequireWitnessFieldsCompleteBeforeAdmission =
            didRequireWitnessFieldsCompleteBeforeAdmission
        this.didRequireExternalOwnerIdentityBeforeAdmission =
            didRequireExternalOwnerIdentityBeforeAdmission
        this.didRequirePreexistingSingletonObservationBeforeAdmission =
            didRequirePreexistingSingletonObservationBeforeAdmission
        this.didRequireMainThreadObservationProofBeforeAdmission =
            didRequireMainThreadObservationProofBeforeAdmission
        this.didRequireNoRendererAccessorCallDuringAdmission =
            didRequireNoRendererAccessorCallDuringAdmission
        this.didRequireNoRendererCreationDuringAdmission =
            didRequireNoRendererCreationDuringAdmission
        this.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDehydrated =
            didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightFacts(
    sourceWitnessContractShapeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightFacts {
    let upstreamReady =
        sourceWitnessContractShapeReadiness
            .didPrepareExternalPreexistingSingletonSourceWitnessContractShape &&
        sourceWitnessContractShapeReadiness
            .didRequireWitnessProvidedByExternalOwner &&
        sourceWitnessContractShapeReadiness
            .didRequirePreexistingSingletonBeforeRendererObservation &&
        sourceWitnessContractShapeReadiness
            .didRequireWitnessCapturedBeforeRuntimeOwner &&
        sourceWitnessContractShapeReadiness
            .didRequireMainThreadWitnessDeclaration &&
        sourceWitnessContractShapeReadiness
            .didRequireNoRendererCreationInvariant &&
        sourceWitnessContractShapeReadiness
            .didRequireNoRendererAccessorCallInvariant &&
        sourceWitnessContractShapeReadiness
            .didRequireCleanupOwnershipRetainedByExternalSource &&
        sourceWitnessContractShapeReadiness
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse &&
        sourceWitnessContractShapeReadiness
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        sourceWitnessContractShapeReadiness
            .didConfirmProductionSingletonImplementationBlocked &&
        sourceWitnessContractShapeReadiness
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        sourceWitnessContractShapeReadiness
            .didKeepExternalPreexistingSingletonSourceWitnessContractShapeDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightFacts(
        upstreamReady,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
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

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight(
    witnessAdmissionPolicyPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight {
    let admitted =
        witnessAdmissionPolicyPreflightFacts
            .didPreserveExternalPreexistingSingletonSourceWitnessContractShape &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDecision &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireAdmissionPolicyBeforeWitnessTruth &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireWitnessFieldsCompleteBeforeAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireExternalOwnerIdentityBeforeAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequirePreexistingSingletonObservationBeforeAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireMainThreadObservationProofBeforeAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireSourceLifetimeProofBeforeAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireExternalCleanupOwnershipBeforeAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireNoRendererAccessorCallDuringAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireNoRendererCreationDuringAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireNoCleanupExecutionDuringAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireHeadlessFailClosedAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireNonUserVisibleAdmission &&
        witnessAdmissionPolicyPreflightFacts
            .didRequireAdmissionResultRemainDehydrated &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmProductionSingletonImplementationBlocked &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoActivationPolicyMutation &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoApplicationActivation &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoAppKitEventLoop &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoBoundedRunLoopPump &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoWindowViewLayerCreation &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoVisibleOrder &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoDrawable &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoCommandQueueBufferEncoder &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoRenderCommitPresentGpuSubmission &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoArtifactOrDiagnosticsPublication &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoPointerHandleClassIdReturn &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoPublicApi &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoProductionPublicCAbi &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoRuntimeStateWrite &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoCjpmTomlChange &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoRendererStateWrite &&
        witnessAdmissionPolicyPreflightFacts
            .didConfirmNoBackendReadyTruth &&
        witnessAdmissionPolicyPreflightFacts
            .didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight(
        witnessAdmissionPolicyPreflightFacts,
        admitted,
        !admitted,
        !admitted,
        witnessAdmissionPolicyPreflightFacts
            .didRequireAdmissionPolicyBeforeWitnessTruth,
        witnessAdmissionPolicyPreflightFacts
            .didRequireWitnessFieldsCompleteBeforeAdmission,
        witnessAdmissionPolicyPreflightFacts
            .didRequireExternalOwnerIdentityBeforeAdmission,
        witnessAdmissionPolicyPreflightFacts
            .didRequirePreexistingSingletonObservationBeforeAdmission,
        witnessAdmissionPolicyPreflightFacts
            .didRequireMainThreadObservationProofBeforeAdmission,
        witnessAdmissionPolicyPreflightFacts
            .didRequireNoRendererAccessorCallDuringAdmission,
        witnessAdmissionPolicyPreflightFacts
            .didRequireNoRendererCreationDuringAdmission,
        witnessAdmissionPolicyPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse,
        witnessAdmissionPolicyPreflightFacts
            .didConfirmProductionSingletonOwnershipTruthFalse,
        witnessAdmissionPolicyPreflightFacts
            .didConfirmProductionSingletonImplementationBlocked,
        witnessAdmissionPolicyPreflightFacts
            .didConfirmProductionActualAccessorCallSiteBlocked,
        witnessAdmissionPolicyPreflightFacts
            .didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness(
    sourceWitnessContractShapeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness,
    witnessAdmissionPolicyPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness {
    let admitted =
        witnessAdmissionPolicyPreflight
            .didAdmitExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight
    let facts =
        witnessAdmissionPolicyPreflight.witnessAdmissionPolicyPreflightFacts

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness(
        sourceWitnessContractShapeReadiness,
        witnessAdmissionPolicyPreflight,
        admitted,
        !admitted,
        !admitted,
        facts
            .didPreserveExternalPreexistingSingletonSourceWitnessContractShape,
        witnessAdmissionPolicyPreflight
            .didRequireAdmissionPolicyBeforeWitnessTruth,
        witnessAdmissionPolicyPreflight
            .didRequireWitnessFieldsCompleteBeforeAdmission,
        witnessAdmissionPolicyPreflight
            .didRequireExternalOwnerIdentityBeforeAdmission,
        witnessAdmissionPolicyPreflight
            .didRequirePreexistingSingletonObservationBeforeAdmission,
        witnessAdmissionPolicyPreflight
            .didRequireMainThreadObservationProofBeforeAdmission,
        witnessAdmissionPolicyPreflight
            .didRequireNoRendererAccessorCallDuringAdmission,
        witnessAdmissionPolicyPreflight.didRequireNoRendererCreationDuringAdmission,
        witnessAdmissionPolicyPreflight
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse,
        witnessAdmissionPolicyPreflight
            .didConfirmProductionSingletonOwnershipTruthFalse,
        witnessAdmissionPolicyPreflight
            .didConfirmProductionSingletonImplementationBlocked,
        witnessAdmissionPolicyPreflight
            .didConfirmProductionActualAccessorCallSiteBlocked,
        witnessAdmissionPolicyPreflight
            .didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightValueOnly
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness {
    let sourceWitnessContractShapeReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeDraft()
    let witnessAdmissionPolicyPreflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightFacts(
            sourceWitnessContractShapeReadiness
        )
    let witnessAdmissionPolicyPreflight =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight(
            witnessAdmissionPolicyPreflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness(
        sourceWitnessContractShapeReadiness,
        witnessAdmissionPolicyPreflight
    )
}

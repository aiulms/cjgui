// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application external preexisting singleton source witness payload
// schema preflight owner。
// Owner: runtime renderer internal external preexisting singleton source
// witness payload schema preflight owner。
// Truth: 只消费 witness admission policy preflight，固定未来 witness payload
// 必须包含版本、外部 owner 身份、preexisting singleton observation、
// main-thread observation、source lifetime、cleanup ownership、no-creation /
// no-accessor invariant 与 fail-closed classification 字段；payload 仍保持
// dehydrated，不携带 native object、pointer、handle、Class、id、artifact 或
// diagnostics。
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightFacts {
    let didPreserveExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight:
        Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDecision:
        Bool
    let didRequireSchemaBeforeWitnessTruth: Bool
    let didRequirePayloadVersionField: Bool
    let didRequireExternalOwnerIdentityField: Bool
    let didRequirePreexistingSingletonObservedField: Bool
    let didRequireMainThreadObservationField: Bool
    let didRequireSourceLifetimeField: Bool
    let didRequireCleanupOwnershipField: Bool
    let didRequireNoRendererAccessorInvariantField: Bool
    let didRequireNoRendererCreationInvariantField: Bool
    let didRequireHeadlessFailClosedClassificationField: Bool
    let didRequirePayloadRemainDehydrated: Bool
    let didRejectPointerHandleClassIdPayload: Bool
    let didRejectNativeObjectPayload: Bool
    let didRejectDiagnosticsOrArtifactPayload: Bool
    let didRequireMissingFieldFailClosed: Bool
    let didRequireAmbiguousOwnerFailClosed: Bool
    let didRequireWrongThreadFailClosed: Bool
    let didRequireRendererCreatedSingletonFailClosed: Bool
    let didRequireThrowawaySingletonFailClosed: Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
        Bool
    let didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidBackendReadyWrapper: Bool

    init(
        didPreserveExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight:
            Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDecision:
            Bool,
        didRequireSchemaBeforeWitnessTruth: Bool,
        didRequirePayloadVersionField: Bool,
        didRequireExternalOwnerIdentityField: Bool,
        didRequirePreexistingSingletonObservedField: Bool,
        didRequireMainThreadObservationField: Bool,
        didRequireSourceLifetimeField: Bool,
        didRequireCleanupOwnershipField: Bool,
        didRequireNoRendererAccessorInvariantField: Bool,
        didRequireNoRendererCreationInvariantField: Bool,
        didRequireHeadlessFailClosedClassificationField: Bool,
        didRequirePayloadRemainDehydrated: Bool,
        didRejectPointerHandleClassIdPayload: Bool,
        didRejectNativeObjectPayload: Bool,
        didRejectDiagnosticsOrArtifactPayload: Bool,
        didRequireMissingFieldFailClosed: Bool,
        didRequireAmbiguousOwnerFailClosed: Bool,
        didRequireWrongThreadFailClosed: Bool,
        didRequireRendererCreatedSingletonFailClosed: Bool,
        didRequireThrowawaySingletonFailClosed: Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidBackendReadyWrapper: Bool
    ) {
        this.didPreserveExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight =
            didPreserveExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight
        this.didConfirmExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDecision =
            didConfirmExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDecision
        this.didRequireSchemaBeforeWitnessTruth =
            didRequireSchemaBeforeWitnessTruth
        this.didRequirePayloadVersionField = didRequirePayloadVersionField
        this.didRequireExternalOwnerIdentityField =
            didRequireExternalOwnerIdentityField
        this.didRequirePreexistingSingletonObservedField =
            didRequirePreexistingSingletonObservedField
        this.didRequireMainThreadObservationField =
            didRequireMainThreadObservationField
        this.didRequireSourceLifetimeField = didRequireSourceLifetimeField
        this.didRequireCleanupOwnershipField = didRequireCleanupOwnershipField
        this.didRequireNoRendererAccessorInvariantField =
            didRequireNoRendererAccessorInvariantField
        this.didRequireNoRendererCreationInvariantField =
            didRequireNoRendererCreationInvariantField
        this.didRequireHeadlessFailClosedClassificationField =
            didRequireHeadlessFailClosedClassificationField
        this.didRequirePayloadRemainDehydrated =
            didRequirePayloadRemainDehydrated
        this.didRejectPointerHandleClassIdPayload =
            didRejectPointerHandleClassIdPayload
        this.didRejectNativeObjectPayload = didRejectNativeObjectPayload
        this.didRejectDiagnosticsOrArtifactPayload =
            didRejectDiagnosticsOrArtifactPayload
        this.didRequireMissingFieldFailClosed =
            didRequireMissingFieldFailClosed
        this.didRequireAmbiguousOwnerFailClosed =
            didRequireAmbiguousOwnerFailClosed
        this.didRequireWrongThreadFailClosed = didRequireWrongThreadFailClosed
        this.didRequireRendererCreatedSingletonFailClosed =
            didRequireRendererCreatedSingletonFailClosed
        this.didRequireThrowawaySingletonFailClosed =
            didRequireThrowawaySingletonFailClosed
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
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite =
            didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly =
            didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidBackendReadyWrapper = didAvoidBackendReadyWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight {
    let witnessPayloadSchemaPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightFacts
    let didAdmitExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight:
        Bool
    let shouldDeferExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight:
        Bool
    let shouldReportExternalPreexistingSingletonSourceWitnessPayloadSchemaBlocked:
        Bool
    let didRequireSchemaBeforeWitnessTruth: Bool
    let didRequirePayloadVersionField: Bool
    let didRequireExternalOwnerIdentityField: Bool
    let didRequirePreexistingSingletonObservedField: Bool
    let didRequireMainThreadObservationField: Bool
    let didRequireNoRendererAccessorInvariantField: Bool
    let didRequireNoRendererCreationInvariantField: Bool
    let didRequireHeadlessFailClosedClassificationField: Bool
    let didRequirePayloadRemainDehydrated: Bool
    let didRejectPointerHandleClassIdPayload: Bool
    let didRejectNativeObjectPayload: Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly:
        Bool

    init(
        witnessPayloadSchemaPreflightFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightFacts,
        didAdmitExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight:
            Bool,
        shouldDeferExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight:
            Bool,
        shouldReportExternalPreexistingSingletonSourceWitnessPayloadSchemaBlocked:
            Bool,
        didRequireSchemaBeforeWitnessTruth: Bool,
        didRequirePayloadVersionField: Bool,
        didRequireExternalOwnerIdentityField: Bool,
        didRequirePreexistingSingletonObservedField: Bool,
        didRequireMainThreadObservationField: Bool,
        didRequireNoRendererAccessorInvariantField: Bool,
        didRequireNoRendererCreationInvariantField: Bool,
        didRequireHeadlessFailClosedClassificationField: Bool,
        didRequirePayloadRemainDehydrated: Bool,
        didRejectPointerHandleClassIdPayload: Bool,
        didRejectNativeObjectPayload: Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly:
            Bool
    ) {
        this.witnessPayloadSchemaPreflightFacts =
            witnessPayloadSchemaPreflightFacts
        this.didAdmitExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight =
            didAdmitExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight
        this.shouldDeferExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight =
            shouldDeferExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight
        this.shouldReportExternalPreexistingSingletonSourceWitnessPayloadSchemaBlocked =
            shouldReportExternalPreexistingSingletonSourceWitnessPayloadSchemaBlocked
        this.didRequireSchemaBeforeWitnessTruth =
            didRequireSchemaBeforeWitnessTruth
        this.didRequirePayloadVersionField = didRequirePayloadVersionField
        this.didRequireExternalOwnerIdentityField =
            didRequireExternalOwnerIdentityField
        this.didRequirePreexistingSingletonObservedField =
            didRequirePreexistingSingletonObservedField
        this.didRequireMainThreadObservationField =
            didRequireMainThreadObservationField
        this.didRequireNoRendererAccessorInvariantField =
            didRequireNoRendererAccessorInvariantField
        this.didRequireNoRendererCreationInvariantField =
            didRequireNoRendererCreationInvariantField
        this.didRequireHeadlessFailClosedClassificationField =
            didRequireHeadlessFailClosedClassificationField
        this.didRequirePayloadRemainDehydrated =
            didRequirePayloadRemainDehydrated
        this.didRejectPointerHandleClassIdPayload =
            didRejectPointerHandleClassIdPayload
        this.didRejectNativeObjectPayload = didRejectNativeObjectPayload
        this.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly =
            didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightReadiness {
    let witnessAdmissionPolicyPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness
    let witnessPayloadSchemaPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight
    let didPrepareExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight:
        Bool
    let shouldDeferExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight:
        Bool
    let shouldReportExternalPreexistingSingletonSourceWitnessPayloadSchemaBlocked:
        Bool
    let didRequireSchemaBeforeWitnessTruth: Bool
    let didRequirePayloadVersionField: Bool
    let didRequireExternalOwnerIdentityField: Bool
    let didRequirePreexistingSingletonObservedField: Bool
    let didRequireMainThreadObservationField: Bool
    let didRequireNoRendererAccessorInvariantField: Bool
    let didRequireNoRendererCreationInvariantField: Bool
    let didRequireHeadlessFailClosedClassificationField: Bool
    let didRequirePayloadRemainDehydrated: Bool
    let didRejectPointerHandleClassIdPayload: Bool
    let didRejectNativeObjectPayload: Bool
    let didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
        Bool
    let didConfirmProductionSingletonOwnershipTruthFalse: Bool
    let didConfirmProductionSingletonImplementationBlocked: Bool
    let didConfirmProductionActualAccessorCallSiteBlocked: Bool
    let didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDehydrated:
        Bool

    init(
        witnessAdmissionPolicyPreflightReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness,
        witnessPayloadSchemaPreflight:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight,
        didPrepareExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight:
            Bool,
        shouldDeferExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight:
            Bool,
        shouldReportExternalPreexistingSingletonSourceWitnessPayloadSchemaBlocked:
            Bool,
        didRequireSchemaBeforeWitnessTruth: Bool,
        didRequirePayloadVersionField: Bool,
        didRequireExternalOwnerIdentityField: Bool,
        didRequirePreexistingSingletonObservedField: Bool,
        didRequireMainThreadObservationField: Bool,
        didRequireNoRendererAccessorInvariantField: Bool,
        didRequireNoRendererCreationInvariantField: Bool,
        didRequireHeadlessFailClosedClassificationField: Bool,
        didRequirePayloadRemainDehydrated: Bool,
        didRejectPointerHandleClassIdPayload: Bool,
        didRejectNativeObjectPayload: Bool,
        didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse:
            Bool,
        didConfirmProductionSingletonOwnershipTruthFalse: Bool,
        didConfirmProductionSingletonImplementationBlocked: Bool,
        didConfirmProductionActualAccessorCallSiteBlocked: Bool,
        didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDehydrated:
            Bool
    ) {
        this.witnessAdmissionPolicyPreflightReadiness =
            witnessAdmissionPolicyPreflightReadiness
        this.witnessPayloadSchemaPreflight = witnessPayloadSchemaPreflight
        this.didPrepareExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight =
            didPrepareExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight
        this.shouldDeferExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight =
            shouldDeferExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight
        this.shouldReportExternalPreexistingSingletonSourceWitnessPayloadSchemaBlocked =
            shouldReportExternalPreexistingSingletonSourceWitnessPayloadSchemaBlocked
        this.didRequireSchemaBeforeWitnessTruth =
            didRequireSchemaBeforeWitnessTruth
        this.didRequirePayloadVersionField = didRequirePayloadVersionField
        this.didRequireExternalOwnerIdentityField =
            didRequireExternalOwnerIdentityField
        this.didRequirePreexistingSingletonObservedField =
            didRequirePreexistingSingletonObservedField
        this.didRequireMainThreadObservationField =
            didRequireMainThreadObservationField
        this.didRequireNoRendererAccessorInvariantField =
            didRequireNoRendererAccessorInvariantField
        this.didRequireNoRendererCreationInvariantField =
            didRequireNoRendererCreationInvariantField
        this.didRequireHeadlessFailClosedClassificationField =
            didRequireHeadlessFailClosedClassificationField
        this.didRequirePayloadRemainDehydrated =
            didRequirePayloadRemainDehydrated
        this.didRejectPointerHandleClassIdPayload =
            didRejectPointerHandleClassIdPayload
        this.didRejectNativeObjectPayload = didRejectNativeObjectPayload
        this.didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse =
            didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse
        this.didConfirmProductionSingletonOwnershipTruthFalse =
            didConfirmProductionSingletonOwnershipTruthFalse
        this.didConfirmProductionSingletonImplementationBlocked =
            didConfirmProductionSingletonImplementationBlocked
        this.didConfirmProductionActualAccessorCallSiteBlocked =
            didConfirmProductionActualAccessorCallSiteBlocked
        this.didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDehydrated =
            didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightFacts(
    witnessAdmissionPolicyPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightFacts {
    let upstreamReady =
        witnessAdmissionPolicyPreflightReadiness
            .didPrepareExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight &&
        witnessAdmissionPolicyPreflightReadiness
            .didRequireAdmissionPolicyBeforeWitnessTruth &&
        witnessAdmissionPolicyPreflightReadiness
            .didRequireWitnessFieldsCompleteBeforeAdmission &&
        witnessAdmissionPolicyPreflightReadiness
            .didRequireExternalOwnerIdentityBeforeAdmission &&
        witnessAdmissionPolicyPreflightReadiness
            .didRequirePreexistingSingletonObservationBeforeAdmission &&
        witnessAdmissionPolicyPreflightReadiness
            .didRequireMainThreadObservationProofBeforeAdmission &&
        witnessAdmissionPolicyPreflightReadiness
            .didRequireNoRendererAccessorCallDuringAdmission &&
        witnessAdmissionPolicyPreflightReadiness
            .didRequireNoRendererCreationDuringAdmission &&
        witnessAdmissionPolicyPreflightReadiness
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse &&
        witnessAdmissionPolicyPreflightReadiness
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        witnessAdmissionPolicyPreflightReadiness
            .didConfirmProductionSingletonImplementationBlocked &&
        witnessAdmissionPolicyPreflightReadiness
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        witnessAdmissionPolicyPreflightReadiness
            .didKeepExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightFacts(
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
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight(
    witnessPayloadSchemaPreflightFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight {
    let admitted =
        witnessPayloadSchemaPreflightFacts
            .didPreserveExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflight &&
        witnessPayloadSchemaPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDecision &&
        witnessPayloadSchemaPreflightFacts
            .didRequireSchemaBeforeWitnessTruth &&
        witnessPayloadSchemaPreflightFacts.didRequirePayloadVersionField &&
        witnessPayloadSchemaPreflightFacts
            .didRequireExternalOwnerIdentityField &&
        witnessPayloadSchemaPreflightFacts
            .didRequirePreexistingSingletonObservedField &&
        witnessPayloadSchemaPreflightFacts
            .didRequireMainThreadObservationField &&
        witnessPayloadSchemaPreflightFacts.didRequireSourceLifetimeField &&
        witnessPayloadSchemaPreflightFacts.didRequireCleanupOwnershipField &&
        witnessPayloadSchemaPreflightFacts
            .didRequireNoRendererAccessorInvariantField &&
        witnessPayloadSchemaPreflightFacts
            .didRequireNoRendererCreationInvariantField &&
        witnessPayloadSchemaPreflightFacts
            .didRequireHeadlessFailClosedClassificationField &&
        witnessPayloadSchemaPreflightFacts.didRequirePayloadRemainDehydrated &&
        witnessPayloadSchemaPreflightFacts
            .didRejectPointerHandleClassIdPayload &&
        witnessPayloadSchemaPreflightFacts.didRejectNativeObjectPayload &&
        witnessPayloadSchemaPreflightFacts
            .didRejectDiagnosticsOrArtifactPayload &&
        witnessPayloadSchemaPreflightFacts.didRequireMissingFieldFailClosed &&
        witnessPayloadSchemaPreflightFacts
            .didRequireAmbiguousOwnerFailClosed &&
        witnessPayloadSchemaPreflightFacts.didRequireWrongThreadFailClosed &&
        witnessPayloadSchemaPreflightFacts
            .didRequireRendererCreatedSingletonFailClosed &&
        witnessPayloadSchemaPreflightFacts
            .didRequireThrowawaySingletonFailClosed &&
        witnessPayloadSchemaPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse &&
        witnessPayloadSchemaPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceReadinessTruthFalse &&
        witnessPayloadSchemaPreflightFacts
            .didConfirmProductionSingletonOwnershipTruthFalse &&
        witnessPayloadSchemaPreflightFacts
            .didConfirmProductionSingletonImplementationBlocked &&
        witnessPayloadSchemaPreflightFacts
            .didConfirmProductionActualAccessorCallSiteBlocked &&
        witnessPayloadSchemaPreflightFacts.didConfirmNoPublicApi &&
        witnessPayloadSchemaPreflightFacts.didConfirmNoProductionPublicCAbi &&
        witnessPayloadSchemaPreflightFacts.didConfirmNoRuntimeStateWrite &&
        witnessPayloadSchemaPreflightFacts.didConfirmNoCjpmTomlChange &&
        witnessPayloadSchemaPreflightFacts.didConfirmNoRendererStateWrite &&
        witnessPayloadSchemaPreflightFacts.didConfirmNoBackendReadyTruth &&
        witnessPayloadSchemaPreflightFacts
            .didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight(
        witnessPayloadSchemaPreflightFacts,
        admitted,
        !admitted,
        !admitted,
        witnessPayloadSchemaPreflightFacts.didRequireSchemaBeforeWitnessTruth,
        witnessPayloadSchemaPreflightFacts.didRequirePayloadVersionField,
        witnessPayloadSchemaPreflightFacts
            .didRequireExternalOwnerIdentityField,
        witnessPayloadSchemaPreflightFacts
            .didRequirePreexistingSingletonObservedField,
        witnessPayloadSchemaPreflightFacts
            .didRequireMainThreadObservationField,
        witnessPayloadSchemaPreflightFacts
            .didRequireNoRendererAccessorInvariantField,
        witnessPayloadSchemaPreflightFacts
            .didRequireNoRendererCreationInvariantField,
        witnessPayloadSchemaPreflightFacts
            .didRequireHeadlessFailClosedClassificationField,
        witnessPayloadSchemaPreflightFacts.didRequirePayloadRemainDehydrated,
        witnessPayloadSchemaPreflightFacts
            .didRejectPointerHandleClassIdPayload,
        witnessPayloadSchemaPreflightFacts.didRejectNativeObjectPayload,
        witnessPayloadSchemaPreflightFacts
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse,
        witnessPayloadSchemaPreflightFacts
            .didConfirmProductionSingletonOwnershipTruthFalse,
        witnessPayloadSchemaPreflightFacts
            .didConfirmProductionSingletonImplementationBlocked,
        witnessPayloadSchemaPreflightFacts
            .didConfirmProductionActualAccessorCallSiteBlocked,
        witnessPayloadSchemaPreflightFacts
            .didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightReadiness(
    witnessAdmissionPolicyPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness,
    witnessPayloadSchemaPreflight:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightReadiness {
    let admitted =
        witnessPayloadSchemaPreflight
            .didAdmitExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightReadiness(
        witnessAdmissionPolicyPreflightReadiness,
        witnessPayloadSchemaPreflight,
        admitted,
        !admitted,
        !admitted,
        witnessPayloadSchemaPreflight.didRequireSchemaBeforeWitnessTruth,
        witnessPayloadSchemaPreflight.didRequirePayloadVersionField,
        witnessPayloadSchemaPreflight.didRequireExternalOwnerIdentityField,
        witnessPayloadSchemaPreflight
            .didRequirePreexistingSingletonObservedField,
        witnessPayloadSchemaPreflight.didRequireMainThreadObservationField,
        witnessPayloadSchemaPreflight
            .didRequireNoRendererAccessorInvariantField,
        witnessPayloadSchemaPreflight
            .didRequireNoRendererCreationInvariantField,
        witnessPayloadSchemaPreflight
            .didRequireHeadlessFailClosedClassificationField,
        witnessPayloadSchemaPreflight.didRequirePayloadRemainDehydrated,
        witnessPayloadSchemaPreflight.didRejectPointerHandleClassIdPayload,
        witnessPayloadSchemaPreflight.didRejectNativeObjectPayload,
        witnessPayloadSchemaPreflight
            .didConfirmExternalPreexistingSingletonSourceWitnessTruthFalse,
        witnessPayloadSchemaPreflight
            .didConfirmProductionSingletonOwnershipTruthFalse,
        witnessPayloadSchemaPreflight
            .didConfirmProductionSingletonImplementationBlocked,
        witnessPayloadSchemaPreflight
            .didConfirmProductionActualAccessorCallSiteBlocked,
        witnessPayloadSchemaPreflight
            .didKeepExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightValueOnly
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightReadiness {
    let witnessAdmissionPolicyPreflightReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightDraft()
    let witnessPayloadSchemaPreflightFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightFacts(
            witnessAdmissionPolicyPreflightReadiness
        )
    let witnessPayloadSchemaPreflight =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflight(
            witnessPayloadSchemaPreflightFacts
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightReadiness(
        witnessAdmissionPolicyPreflightReadiness,
        witnessPayloadSchemaPreflight
    )
}

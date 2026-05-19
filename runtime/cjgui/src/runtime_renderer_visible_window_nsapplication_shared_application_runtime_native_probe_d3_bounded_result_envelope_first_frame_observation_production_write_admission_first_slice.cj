// 中文维护注释：本文件是 visible-window runtime native probe 的 first-frame
// observation production write admission first-slice readiness owner。
// Owner: runtime renderer internal first-frame observation production write
// admission first-slice owner。
// Truth: 只把 stage119 production truth admission readiness 转换为 production
// write admission preflight；first slice 本身不授权 renderer-state write，不写
// runtime_state.cj，也不把 production truth admission 升级为 backend-ready truth。
// Stop-line: 不做 baseline compare，不发布 production render truth，不新增
// production accessor call site，不扩 native bridge / public API / production
// C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceFacts {
    let didConsumeFirstFrameObservationProductionTruthAdmissionReadiness: Bool
    let didOpenFirstFrameObservationProductionWriteAdmissionFirstSliceRoute:
        Bool
    let didRequireProductionTruthAdmissionPreflightInput: Bool
    let didRequireProductionRenderTruthAdmissionReadyInput: Bool
    let didRequireProductionTruthAdmissionPreflightOnly: Bool
    let didRequireBaselineOrSemanticVerificationBeforeRendererStateWrite:
        Bool
    let didAdmitProductionWritePreflight: Bool
    let didConfirmProductionWriteAdmissionIsPreflightOnly: Bool
    let didKeepRendererStateWriteBlockedAfterProductionWriteAdmission: Bool
    let didKeepRuntimeStateWriteBlockedAfterProductionWriteAdmission: Bool
    let didKeepResultEnvelopePromotionBlocked: Bool
    let didKeepProductionRenderTruthBlocked: Bool
    let didKeepBackendReadyTruthBlocked: Bool
    let didConfirmNoProductionApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool

    init(
        didConsumeFirstFrameObservationProductionTruthAdmissionReadiness: Bool,
        didOpenFirstFrameObservationProductionWriteAdmissionFirstSliceRoute:
            Bool,
        didRequireProductionTruthAdmissionPreflightInput: Bool,
        didRequireProductionRenderTruthAdmissionReadyInput: Bool,
        didRequireProductionTruthAdmissionPreflightOnly: Bool,
        didRequireBaselineOrSemanticVerificationBeforeRendererStateWrite:
            Bool,
        didAdmitProductionWritePreflight: Bool,
        didConfirmProductionWriteAdmissionIsPreflightOnly: Bool,
        didKeepRendererStateWriteBlockedAfterProductionWriteAdmission: Bool,
        didKeepRuntimeStateWriteBlockedAfterProductionWriteAdmission: Bool,
        didKeepResultEnvelopePromotionBlocked: Bool,
        didKeepProductionRenderTruthBlocked: Bool,
        didKeepBackendReadyTruthBlocked: Bool,
        didConfirmNoProductionApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool
    ) {
        this.didConsumeFirstFrameObservationProductionTruthAdmissionReadiness =
            didConsumeFirstFrameObservationProductionTruthAdmissionReadiness
        this.didOpenFirstFrameObservationProductionWriteAdmissionFirstSliceRoute =
            didOpenFirstFrameObservationProductionWriteAdmissionFirstSliceRoute
        this.didRequireProductionTruthAdmissionPreflightInput =
            didRequireProductionTruthAdmissionPreflightInput
        this.didRequireProductionRenderTruthAdmissionReadyInput =
            didRequireProductionRenderTruthAdmissionReadyInput
        this.didRequireProductionTruthAdmissionPreflightOnly =
            didRequireProductionTruthAdmissionPreflightOnly
        this.didRequireBaselineOrSemanticVerificationBeforeRendererStateWrite =
            didRequireBaselineOrSemanticVerificationBeforeRendererStateWrite
        this.didAdmitProductionWritePreflight =
            didAdmitProductionWritePreflight
        this.didConfirmProductionWriteAdmissionIsPreflightOnly =
            didConfirmProductionWriteAdmissionIsPreflightOnly
        this.didKeepRendererStateWriteBlockedAfterProductionWriteAdmission =
            didKeepRendererStateWriteBlockedAfterProductionWriteAdmission
        this.didKeepRuntimeStateWriteBlockedAfterProductionWriteAdmission =
            didKeepRuntimeStateWriteBlockedAfterProductionWriteAdmission
        this.didKeepResultEnvelopePromotionBlocked =
            didKeepResultEnvelopePromotionBlocked
        this.didKeepProductionRenderTruthBlocked =
            didKeepProductionRenderTruthBlocked
        this.didKeepBackendReadyTruthBlocked = didKeepBackendReadyTruthBlocked
        this.didConfirmNoProductionApplicationAccessorCall =
            didConfirmNoProductionApplicationAccessorCall
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didAvoidApprovalExternalPacketRecoveryOrReportWrapper =
            didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceReadiness {
    let firstFrameObservationProductionTruthAdmissionFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionTruthAdmissionFirstSliceReadiness
    let firstFrameObservationProductionWriteAdmissionFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceReadiness:
        Bool
    let shouldContinueFirstFrameObservationProductionWriteAdmissionRoute: Bool
    let shouldAdmitProductionWriteAdmissionPreflight: Bool
    let shouldTreatProductionWriteAdmissionAsPreflightOnly: Bool
    let shouldRequireBaselineOrSemanticVerificationBeforeRendererStateWrite:
        Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let shouldKeepRuntimeStateWriteBlocked: Bool
    let shouldKeepResultEnvelopePromotionBlocked: Bool
    let shouldKeepProductionRenderTruthBlocked: Bool
    let shouldKeepBackendReadyTruthBlocked: Bool
    let didConfirmProductionTruthAdmissionInput: Bool
    let didConfirmProductionRenderTruthAdmissionReadyInput: Bool
    let didConfirmProductionTruthAdmissionPreflightOnly: Bool
    let didConfirmProductionWriteAdmissionPreflightReady: Bool
    let didConfirmProductionWriteAdmissionPreflightOnly: Bool
    let didConfirmBaselineOrSemanticVerificationBeforeRendererStateWriteRequired:
        Bool
    let didConfirmRendererStateWriteBlockedAfterProductionWriteAdmission: Bool
    let didConfirmRuntimeStateWriteBlockedAfterProductionWriteAdmission: Bool
    let didConfirmResultEnvelopePromotionBlocked: Bool
    let didConfirmProductionRenderTruthBlocked: Bool
    let didConfirmBackendReadyTruthBlocked: Bool
    let didConfirmNoProductionApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool

    init(
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionTruthAdmissionFirstSliceReadiness,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceReadiness:
            Bool,
        shouldContinueFirstFrameObservationProductionWriteAdmissionRoute: Bool,
        shouldAdmitProductionWriteAdmissionPreflight: Bool,
        shouldTreatProductionWriteAdmissionAsPreflightOnly: Bool,
        shouldRequireBaselineOrSemanticVerificationBeforeRendererStateWrite:
            Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        shouldKeepRuntimeStateWriteBlocked: Bool,
        shouldKeepResultEnvelopePromotionBlocked: Bool,
        shouldKeepProductionRenderTruthBlocked: Bool,
        shouldKeepBackendReadyTruthBlocked: Bool,
        didConfirmProductionTruthAdmissionInput: Bool,
        didConfirmProductionRenderTruthAdmissionReadyInput: Bool,
        didConfirmProductionTruthAdmissionPreflightOnly: Bool,
        didConfirmProductionWriteAdmissionPreflightReady: Bool,
        didConfirmProductionWriteAdmissionPreflightOnly: Bool,
        didConfirmBaselineOrSemanticVerificationBeforeRendererStateWriteRequired:
            Bool,
        didConfirmRendererStateWriteBlockedAfterProductionWriteAdmission: Bool,
        didConfirmRuntimeStateWriteBlockedAfterProductionWriteAdmission: Bool,
        didConfirmResultEnvelopePromotionBlocked: Bool,
        didConfirmProductionRenderTruthBlocked: Bool,
        didConfirmBackendReadyTruthBlocked: Bool,
        didConfirmNoProductionApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidApprovalExternalPacketRecoveryOrReportWrapper: Bool
    ) {
        this.firstFrameObservationProductionTruthAdmissionFirstSliceReadiness =
            firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
        this.firstFrameObservationProductionWriteAdmissionFirstSliceFacts =
            firstFrameObservationProductionWriteAdmissionFirstSliceFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceReadiness
        this.shouldContinueFirstFrameObservationProductionWriteAdmissionRoute =
            shouldContinueFirstFrameObservationProductionWriteAdmissionRoute
        this.shouldAdmitProductionWriteAdmissionPreflight =
            shouldAdmitProductionWriteAdmissionPreflight
        this.shouldTreatProductionWriteAdmissionAsPreflightOnly =
            shouldTreatProductionWriteAdmissionAsPreflightOnly
        this.shouldRequireBaselineOrSemanticVerificationBeforeRendererStateWrite =
            shouldRequireBaselineOrSemanticVerificationBeforeRendererStateWrite
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.shouldKeepRuntimeStateWriteBlocked =
            shouldKeepRuntimeStateWriteBlocked
        this.shouldKeepResultEnvelopePromotionBlocked =
            shouldKeepResultEnvelopePromotionBlocked
        this.shouldKeepProductionRenderTruthBlocked =
            shouldKeepProductionRenderTruthBlocked
        this.shouldKeepBackendReadyTruthBlocked =
            shouldKeepBackendReadyTruthBlocked
        this.didConfirmProductionTruthAdmissionInput =
            didConfirmProductionTruthAdmissionInput
        this.didConfirmProductionRenderTruthAdmissionReadyInput =
            didConfirmProductionRenderTruthAdmissionReadyInput
        this.didConfirmProductionTruthAdmissionPreflightOnly =
            didConfirmProductionTruthAdmissionPreflightOnly
        this.didConfirmProductionWriteAdmissionPreflightReady =
            didConfirmProductionWriteAdmissionPreflightReady
        this.didConfirmProductionWriteAdmissionPreflightOnly =
            didConfirmProductionWriteAdmissionPreflightOnly
        this.didConfirmBaselineOrSemanticVerificationBeforeRendererStateWriteRequired =
            didConfirmBaselineOrSemanticVerificationBeforeRendererStateWriteRequired
        this.didConfirmRendererStateWriteBlockedAfterProductionWriteAdmission =
            didConfirmRendererStateWriteBlockedAfterProductionWriteAdmission
        this.didConfirmRuntimeStateWriteBlockedAfterProductionWriteAdmission =
            didConfirmRuntimeStateWriteBlockedAfterProductionWriteAdmission
        this.didConfirmResultEnvelopePromotionBlocked =
            didConfirmResultEnvelopePromotionBlocked
        this.didConfirmProductionRenderTruthBlocked =
            didConfirmProductionRenderTruthBlocked
        this.didConfirmBackendReadyTruthBlocked =
            didConfirmBackendReadyTruthBlocked
        this.didConfirmNoProductionApplicationAccessorCall =
            didConfirmNoProductionApplicationAccessorCall
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didAvoidApprovalExternalPacketRecoveryOrReportWrapper =
            didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceFacts(
    firstFrameObservationProductionTruthAdmissionFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionTruthAdmissionFirstSliceReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceFacts(
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionTruthAdmissionFirstSliceReadiness,
        true,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .shouldContinueFirstFrameObservationProductionTruthAdmissionRoute,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmProductionRenderTruthAdmissionPreflightReady,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmProductionTruthAdmissionPreflightOnly,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmBaselineOrSemanticVerificationStillRequired,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmProductionWriteAdmissionAfterTruthAdmissionRequired &&
            firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
                .didConfirmProductionRenderTruthAdmissionPreflightReady,
        true,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmRendererStateWriteBlocked,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmNoRuntimeStateWrite,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmResultEnvelopePromotionBlocked,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmProductionRenderTruthBlocked,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmBackendReadyTruthBlocked,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmNoProductionApplicationAccessorCall,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmNoNativeBridgeExpansion,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmNoPublicApi,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmNoProductionPublicCAbi,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmNoRuntimeStateWrite,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmNoCjpmTomlChange,
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
            .didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceReadiness(
    firstFrameObservationProductionTruthAdmissionFirstSliceReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionTruthAdmissionFirstSliceReadiness,
    firstFrameObservationProductionWriteAdmissionFirstSliceFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceReadiness {
    let productionWriteAdmissionFirstSliceReady =
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConsumeFirstFrameObservationProductionTruthAdmissionReadiness &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didOpenFirstFrameObservationProductionWriteAdmissionFirstSliceRoute &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didRequireProductionTruthAdmissionPreflightInput &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didRequireProductionRenderTruthAdmissionReadyInput &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didRequireProductionTruthAdmissionPreflightOnly &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didRequireBaselineOrSemanticVerificationBeforeRendererStateWrite &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didAdmitProductionWritePreflight &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmProductionWriteAdmissionIsPreflightOnly &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepRendererStateWriteBlockedAfterProductionWriteAdmission &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepRuntimeStateWriteBlockedAfterProductionWriteAdmission &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepResultEnvelopePromotionBlocked &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepProductionRenderTruthBlocked &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepBackendReadyTruthBlocked &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoProductionApplicationAccessorCall &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoNativeBridgeExpansion &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoPublicApi &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoProductionPublicCAbi &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoRuntimeStateWrite &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoCjpmTomlChange &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoRendererStateWrite &&
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceReadiness(
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts,
        productionWriteAdmissionFirstSliceReady,
        productionWriteAdmissionFirstSliceReady,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didAdmitProductionWritePreflight,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmProductionWriteAdmissionIsPreflightOnly,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didRequireBaselineOrSemanticVerificationBeforeRendererStateWrite,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepRendererStateWriteBlockedAfterProductionWriteAdmission,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepRuntimeStateWriteBlockedAfterProductionWriteAdmission,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepResultEnvelopePromotionBlocked,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepProductionRenderTruthBlocked,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepBackendReadyTruthBlocked,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConsumeFirstFrameObservationProductionTruthAdmissionReadiness,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didRequireProductionRenderTruthAdmissionReadyInput,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didRequireProductionTruthAdmissionPreflightOnly,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didAdmitProductionWritePreflight,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmProductionWriteAdmissionIsPreflightOnly,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didRequireBaselineOrSemanticVerificationBeforeRendererStateWrite,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepRendererStateWriteBlockedAfterProductionWriteAdmission,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepRuntimeStateWriteBlockedAfterProductionWriteAdmission,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepResultEnvelopePromotionBlocked,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepProductionRenderTruthBlocked,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didKeepBackendReadyTruthBlocked,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoProductionApplicationAccessorCall,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoNativeBridgeExpansion,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoPublicApi,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoProductionPublicCAbi,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoRuntimeStateWrite,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoCjpmTomlChange,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didConfirmNoRendererStateWrite,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
            .didAvoidApprovalExternalPacketRecoveryOrReportWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceReadiness {
    let firstFrameObservationProductionTruthAdmissionFirstSliceReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionTruthAdmissionFirstSliceDraft()
    let firstFrameObservationProductionWriteAdmissionFirstSliceFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceFacts(
            firstFrameObservationProductionTruthAdmissionFirstSliceReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationProductionWriteAdmissionFirstSliceReadiness(
        firstFrameObservationProductionTruthAdmissionFirstSliceReadiness,
        firstFrameObservationProductionWriteAdmissionFirstSliceFacts
    )
}

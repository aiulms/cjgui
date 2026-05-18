// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application runtime native-readiness D3 result-envelope packet validation
// owner。
// Owner: runtime renderer internal D3 result-envelope packet-validation owner。
// Truth: 只消费 D3 result-envelope admission readiness，把未来 external
// Metal-capable shell D3 runtime native probe result envelope 的 packet validation
// contract 固定为 runtime value：必须先完成 packet version / route marker、
// capability packet binding、approval consumption binding、native result
// classification、artifact containment binding、failure-domain continuity 与
// renderer-state no-write preflight，才允许进入后续 promotion route；当前 default
// draft 不执行 native probe，不消费 approval，不调用 application accessor，不写
// renderer state。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call
// site，不调用 application singleton accessor，不创建或激活 NSApplication，不修改
// activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup /
// teardown，不创建 window / view / layer，不 visible order，不取 drawable，不创建
// command queue / command buffer / encoder，不 render / commit / present / GPU
// submission，不发布 artifact / diagnostics，不返回 native identity，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 本 owner 必须表达 external result-envelope packet
// validation 与 renderer-state no-write preflight，不得退化成 admission、
// environment recovery、approval handoff、no-accessor、no-bridge 或
// no-runtime-execution 同构 wrapper，也不得包装成 application-ready、native-ready、
// backend-ready、renderer state write、receipt、record 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationFacts {
    let didConsumeD3ResultEnvelopeAdmissionReadiness: Bool
    let didOpenD3ResultEnvelopePacketValidationRoute: Bool
    let didRequireExternalPacketBeforePromotion: Bool
    let didRequirePacketVersionAndRouteMarker: Bool
    let didRequireCapabilityPacketBinding: Bool
    let didRequireApprovalConsumptionBinding: Bool
    let didRequireNativeResultClassification: Bool
    let didRequireArtifactContainmentBinding: Bool
    let didRequireFailureDomainContinuity: Bool
    let didRequireRendererStateNoWritePreflight: Bool
    let didRequirePromotionQuarantine: Bool
    let didKeepCurrentShellPacketRejected: Bool
    let didKeepFutureExternalPacketSchemaOnly: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didAvoidSameShapeAdmissionWrapper: Bool
    let didKeepPacketValidationDehydrated: Bool

    init(
        didConsumeD3ResultEnvelopeAdmissionReadiness: Bool,
        didOpenD3ResultEnvelopePacketValidationRoute: Bool,
        didRequireExternalPacketBeforePromotion: Bool,
        didRequirePacketVersionAndRouteMarker: Bool,
        didRequireCapabilityPacketBinding: Bool,
        didRequireApprovalConsumptionBinding: Bool,
        didRequireNativeResultClassification: Bool,
        didRequireArtifactContainmentBinding: Bool,
        didRequireFailureDomainContinuity: Bool,
        didRequireRendererStateNoWritePreflight: Bool,
        didRequirePromotionQuarantine: Bool,
        didKeepCurrentShellPacketRejected: Bool,
        didKeepFutureExternalPacketSchemaOnly: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didAvoidSameShapeAdmissionWrapper: Bool,
        didKeepPacketValidationDehydrated: Bool
    ) {
        this.didConsumeD3ResultEnvelopeAdmissionReadiness =
            didConsumeD3ResultEnvelopeAdmissionReadiness
        this.didOpenD3ResultEnvelopePacketValidationRoute =
            didOpenD3ResultEnvelopePacketValidationRoute
        this.didRequireExternalPacketBeforePromotion =
            didRequireExternalPacketBeforePromotion
        this.didRequirePacketVersionAndRouteMarker =
            didRequirePacketVersionAndRouteMarker
        this.didRequireCapabilityPacketBinding =
            didRequireCapabilityPacketBinding
        this.didRequireApprovalConsumptionBinding =
            didRequireApprovalConsumptionBinding
        this.didRequireNativeResultClassification =
            didRequireNativeResultClassification
        this.didRequireArtifactContainmentBinding =
            didRequireArtifactContainmentBinding
        this.didRequireFailureDomainContinuity =
            didRequireFailureDomainContinuity
        this.didRequireRendererStateNoWritePreflight =
            didRequireRendererStateNoWritePreflight
        this.didRequirePromotionQuarantine = didRequirePromotionQuarantine
        this.didKeepCurrentShellPacketRejected =
            didKeepCurrentShellPacketRejected
        this.didKeepFutureExternalPacketSchemaOnly =
            didKeepFutureExternalPacketSchemaOnly
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoApplicationAccessorCall =
            didConfirmNoApplicationAccessorCall
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didAvoidSameShapeAdmissionWrapper =
            didAvoidSameShapeAdmissionWrapper
        this.didKeepPacketValidationDehydrated =
            didKeepPacketValidationDehydrated
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness {
    let d3ResultEnvelopeAdmissionReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeAdmissionReadiness
    let d3ResultEnvelopePacketValidationFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationFacts
    let didPrepareRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness: Bool
    let shouldRequireValidatedExternalPacketBeforePromotion: Bool
    let shouldRejectCurrentShellPacket: Bool
    let shouldKeepFutureExternalPacketSchemaOnly: Bool
    let shouldRunRendererStateNoWritePreflightBeforePromotion: Bool
    let shouldQuarantinePacketPromotion: Bool
    let shouldContinueD3ResultEnvelopePacketValidationRoute: Bool
    let shouldReportD3ResultEnvelopePacketValidationBlocked: Bool
    let didConfirmD3ResultEnvelopeAdmissionInput: Bool
    let didConfirmExternalPacketBeforePromotionRequired: Bool
    let didConfirmPacketVersionAndRouteMarkerRequired: Bool
    let didConfirmCapabilityPacketBindingRequired: Bool
    let didConfirmApprovalConsumptionBindingRequired: Bool
    let didConfirmNativeResultClassificationRequired: Bool
    let didConfirmArtifactContainmentBindingRequired: Bool
    let didConfirmFailureDomainContinuityRequired: Bool
    let didConfirmRendererStateNoWritePreflightRequired: Bool
    let didConfirmPromotionQuarantineRequired: Bool
    let didConfirmCurrentShellPacketRejected: Bool
    let didConfirmFutureExternalPacketSchemaOnly: Bool
    let didConfirmNoProductionTruthUpgradeRequired: Bool
    let didConfirmNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didAvoidSameShapeAdmissionWrapper: Bool
    let didKeepPacketValidationDehydrated: Bool

    init(
        d3ResultEnvelopeAdmissionReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeAdmissionReadiness,
        d3ResultEnvelopePacketValidationFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationFacts,
        didPrepareRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness: Bool,
        shouldRequireValidatedExternalPacketBeforePromotion: Bool,
        shouldRejectCurrentShellPacket: Bool,
        shouldKeepFutureExternalPacketSchemaOnly: Bool,
        shouldRunRendererStateNoWritePreflightBeforePromotion: Bool,
        shouldQuarantinePacketPromotion: Bool,
        shouldContinueD3ResultEnvelopePacketValidationRoute: Bool,
        shouldReportD3ResultEnvelopePacketValidationBlocked: Bool,
        didConfirmD3ResultEnvelopeAdmissionInput: Bool,
        didConfirmExternalPacketBeforePromotionRequired: Bool,
        didConfirmPacketVersionAndRouteMarkerRequired: Bool,
        didConfirmCapabilityPacketBindingRequired: Bool,
        didConfirmApprovalConsumptionBindingRequired: Bool,
        didConfirmNativeResultClassificationRequired: Bool,
        didConfirmArtifactContainmentBindingRequired: Bool,
        didConfirmFailureDomainContinuityRequired: Bool,
        didConfirmRendererStateNoWritePreflightRequired: Bool,
        didConfirmPromotionQuarantineRequired: Bool,
        didConfirmCurrentShellPacketRejected: Bool,
        didConfirmFutureExternalPacketSchemaOnly: Bool,
        didConfirmNoProductionTruthUpgradeRequired: Bool,
        didConfirmNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didAvoidSameShapeAdmissionWrapper: Bool,
        didKeepPacketValidationDehydrated: Bool
    ) {
        this.d3ResultEnvelopeAdmissionReadiness =
            d3ResultEnvelopeAdmissionReadiness
        this.d3ResultEnvelopePacketValidationFacts =
            d3ResultEnvelopePacketValidationFacts
        this.didPrepareRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness =
            didPrepareRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness
        this.shouldRequireValidatedExternalPacketBeforePromotion =
            shouldRequireValidatedExternalPacketBeforePromotion
        this.shouldRejectCurrentShellPacket = shouldRejectCurrentShellPacket
        this.shouldKeepFutureExternalPacketSchemaOnly =
            shouldKeepFutureExternalPacketSchemaOnly
        this.shouldRunRendererStateNoWritePreflightBeforePromotion =
            shouldRunRendererStateNoWritePreflightBeforePromotion
        this.shouldQuarantinePacketPromotion = shouldQuarantinePacketPromotion
        this.shouldContinueD3ResultEnvelopePacketValidationRoute =
            shouldContinueD3ResultEnvelopePacketValidationRoute
        this.shouldReportD3ResultEnvelopePacketValidationBlocked =
            shouldReportD3ResultEnvelopePacketValidationBlocked
        this.didConfirmD3ResultEnvelopeAdmissionInput =
            didConfirmD3ResultEnvelopeAdmissionInput
        this.didConfirmExternalPacketBeforePromotionRequired =
            didConfirmExternalPacketBeforePromotionRequired
        this.didConfirmPacketVersionAndRouteMarkerRequired =
            didConfirmPacketVersionAndRouteMarkerRequired
        this.didConfirmCapabilityPacketBindingRequired =
            didConfirmCapabilityPacketBindingRequired
        this.didConfirmApprovalConsumptionBindingRequired =
            didConfirmApprovalConsumptionBindingRequired
        this.didConfirmNativeResultClassificationRequired =
            didConfirmNativeResultClassificationRequired
        this.didConfirmArtifactContainmentBindingRequired =
            didConfirmArtifactContainmentBindingRequired
        this.didConfirmFailureDomainContinuityRequired =
            didConfirmFailureDomainContinuityRequired
        this.didConfirmRendererStateNoWritePreflightRequired =
            didConfirmRendererStateNoWritePreflightRequired
        this.didConfirmPromotionQuarantineRequired =
            didConfirmPromotionQuarantineRequired
        this.didConfirmCurrentShellPacketRejected =
            didConfirmCurrentShellPacketRejected
        this.didConfirmFutureExternalPacketSchemaOnly =
            didConfirmFutureExternalPacketSchemaOnly
        this.didConfirmNoProductionTruthUpgradeRequired =
            didConfirmNoProductionTruthUpgradeRequired
        this.didConfirmNoApplicationAccessorCall =
            didConfirmNoApplicationAccessorCall
        this.didConfirmNoNativeBridgeExpansion =
            didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi =
            didConfirmNoProductionPublicCAbi
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didAvoidSameShapeAdmissionWrapper =
            didAvoidSameShapeAdmissionWrapper
        this.didKeepPacketValidationDehydrated =
            didKeepPacketValidationDehydrated
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationFacts(
    d3ResultEnvelopeAdmissionReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeAdmissionReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationFacts(
        d3ResultEnvelopeAdmissionReadiness
            .didPrepareRuntimeNativeProbeD3ResultEnvelopeAdmissionReadiness,
        true,
        d3ResultEnvelopeAdmissionReadiness
            .didConfirmExternalMetalCapableShellPacketRequired,
        true,
        d3ResultEnvelopeAdmissionReadiness
            .didConfirmCapabilityPacketBeforeResultEnvelopeRequired,
        d3ResultEnvelopeAdmissionReadiness
            .didConfirmExternalApprovalConsumptionProofRequired,
        d3ResultEnvelopeAdmissionReadiness
            .didConfirmNativeResultPacketSchemaRequired,
        d3ResultEnvelopeAdmissionReadiness
            .didConfirmArtifactContainmentProofRequired,
        true,
        true,
        true,
        d3ResultEnvelopeAdmissionReadiness
            .didConfirmCurrentEnvironmentExecutionBlocked,
        d3ResultEnvelopeAdmissionReadiness
            .didKeepD3ResultEnvelopeAdmissionDehydrated,
        d3ResultEnvelopeAdmissionReadiness
            .didConfirmNoProductionTruthUpgradeRequired,
        d3ResultEnvelopeAdmissionReadiness.didConfirmNoApplicationAccessorCall,
        d3ResultEnvelopeAdmissionReadiness.didConfirmNoNativeBridgeExpansion,
        d3ResultEnvelopeAdmissionReadiness.didConfirmNoPublicApi,
        d3ResultEnvelopeAdmissionReadiness.didConfirmNoProductionPublicCAbi,
        d3ResultEnvelopeAdmissionReadiness.didConfirmNoRendererStateWrite,
        d3ResultEnvelopeAdmissionReadiness.didConfirmNoRuntimeStateWrite,
        d3ResultEnvelopeAdmissionReadiness.didConfirmNoCjpmTomlChange,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness(
    d3ResultEnvelopeAdmissionReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeAdmissionReadiness,
    d3ResultEnvelopePacketValidationFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness {
    let packetValidationReady =
        d3ResultEnvelopePacketValidationFacts
            .didConsumeD3ResultEnvelopeAdmissionReadiness &&
        d3ResultEnvelopePacketValidationFacts
            .didOpenD3ResultEnvelopePacketValidationRoute &&
        d3ResultEnvelopePacketValidationFacts
            .didRequireExternalPacketBeforePromotion &&
        d3ResultEnvelopePacketValidationFacts
            .didRequirePacketVersionAndRouteMarker &&
        d3ResultEnvelopePacketValidationFacts
            .didRequireCapabilityPacketBinding &&
        d3ResultEnvelopePacketValidationFacts
            .didRequireApprovalConsumptionBinding &&
        d3ResultEnvelopePacketValidationFacts
            .didRequireNativeResultClassification &&
        d3ResultEnvelopePacketValidationFacts
            .didRequireArtifactContainmentBinding &&
        d3ResultEnvelopePacketValidationFacts
            .didRequireFailureDomainContinuity &&
        d3ResultEnvelopePacketValidationFacts
            .didRequireRendererStateNoWritePreflight &&
        d3ResultEnvelopePacketValidationFacts.didRequirePromotionQuarantine &&
        d3ResultEnvelopePacketValidationFacts
            .didKeepCurrentShellPacketRejected &&
        d3ResultEnvelopePacketValidationFacts
            .didKeepFutureExternalPacketSchemaOnly &&
        d3ResultEnvelopePacketValidationFacts
            .didConfirmNoProductionTruthUpgrade &&
        d3ResultEnvelopePacketValidationFacts.didConfirmNoApplicationAccessorCall &&
        d3ResultEnvelopePacketValidationFacts.didConfirmNoNativeBridgeExpansion &&
        d3ResultEnvelopePacketValidationFacts.didConfirmNoPublicApi &&
        d3ResultEnvelopePacketValidationFacts.didConfirmNoProductionPublicCAbi &&
        d3ResultEnvelopePacketValidationFacts.didConfirmNoRendererStateWrite &&
        d3ResultEnvelopePacketValidationFacts.didConfirmNoRuntimeStateWrite &&
        d3ResultEnvelopePacketValidationFacts.didConfirmNoCjpmTomlChange &&
        d3ResultEnvelopePacketValidationFacts.didAvoidSameShapeAdmissionWrapper &&
        d3ResultEnvelopePacketValidationFacts.didKeepPacketValidationDehydrated

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness(
        d3ResultEnvelopeAdmissionReadiness,
        d3ResultEnvelopePacketValidationFacts,
        packetValidationReady,
        packetValidationReady,
        packetValidationReady,
        packetValidationReady,
        packetValidationReady,
        packetValidationReady,
        packetValidationReady,
        !packetValidationReady,
        d3ResultEnvelopePacketValidationFacts
            .didConsumeD3ResultEnvelopeAdmissionReadiness,
        d3ResultEnvelopePacketValidationFacts
            .didRequireExternalPacketBeforePromotion,
        d3ResultEnvelopePacketValidationFacts
            .didRequirePacketVersionAndRouteMarker,
        d3ResultEnvelopePacketValidationFacts
            .didRequireCapabilityPacketBinding,
        d3ResultEnvelopePacketValidationFacts
            .didRequireApprovalConsumptionBinding,
        d3ResultEnvelopePacketValidationFacts
            .didRequireNativeResultClassification,
        d3ResultEnvelopePacketValidationFacts
            .didRequireArtifactContainmentBinding,
        d3ResultEnvelopePacketValidationFacts
            .didRequireFailureDomainContinuity,
        d3ResultEnvelopePacketValidationFacts
            .didRequireRendererStateNoWritePreflight,
        d3ResultEnvelopePacketValidationFacts.didRequirePromotionQuarantine,
        d3ResultEnvelopePacketValidationFacts.didKeepCurrentShellPacketRejected,
        d3ResultEnvelopePacketValidationFacts
            .didKeepFutureExternalPacketSchemaOnly,
        d3ResultEnvelopePacketValidationFacts
            .didConfirmNoProductionTruthUpgrade,
        d3ResultEnvelopePacketValidationFacts.didConfirmNoApplicationAccessorCall,
        d3ResultEnvelopePacketValidationFacts.didConfirmNoNativeBridgeExpansion,
        d3ResultEnvelopePacketValidationFacts.didConfirmNoPublicApi,
        d3ResultEnvelopePacketValidationFacts.didConfirmNoProductionPublicCAbi,
        d3ResultEnvelopePacketValidationFacts.didConfirmNoRendererStateWrite,
        d3ResultEnvelopePacketValidationFacts.didConfirmNoRuntimeStateWrite,
        d3ResultEnvelopePacketValidationFacts.didConfirmNoCjpmTomlChange,
        d3ResultEnvelopePacketValidationFacts.didAvoidSameShapeAdmissionWrapper,
        d3ResultEnvelopePacketValidationFacts.didKeepPacketValidationDehydrated
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness {
    let d3ResultEnvelopeAdmissionReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeAdmissionDraft()
    let d3ResultEnvelopePacketValidationFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationFacts(
            d3ResultEnvelopeAdmissionReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness(
        d3ResultEnvelopeAdmissionReadiness,
        d3ResultEnvelopePacketValidationFacts
    )
}

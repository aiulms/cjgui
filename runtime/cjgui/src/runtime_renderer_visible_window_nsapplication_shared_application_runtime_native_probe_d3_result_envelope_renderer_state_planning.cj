// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application runtime native-readiness D3 result-envelope renderer-state
// planning owner。
// Owner: runtime renderer internal D3 result-envelope renderer-state planning
// owner。
// Truth: 只消费 D3 result-envelope packet-validation readiness，把 quarantined
// packet 进入 renderer state 之前的 transition planning contract 固定为 runtime
// value：必须有 validated packet input、quarantined packet input、renderer-state
// transition descriptor、no-write gate、external validation promotion hold、
// artifact containment、failure-domain continuity 与 runtime_state.cj line-count
// invariant。当前 default draft 不执行 native probe，不消费 approval，不调用
// application accessor，不写 renderer state，也不升级 production truth。
// Stop-line: 不实现 production singleton owner，不新增 production accessor call
// site，不调用 application singleton accessor，不创建或激活 NSApplication，不修改
// activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup /
// teardown，不创建 window / view / layer，不 visible order，不取 drawable，不创建
// command queue / command buffer / encoder，不 render / commit / present / GPU
// submission，不发布 artifact / diagnostics，不返回 native identity，不写
// runtime_state.cj，不改 cjpm.toml，不扩 public API，不新增 production C ABI。
// Same-shape Boundary Brake: 本 owner 必须表达 quarantined packet 到
// renderer-state transition plan 的 no-write planning boundary，不得退化成 packet
// validation、admission、environment recovery、approval handoff、no-accessor、
// no-bridge 或 no-runtime-execution 同构 wrapper，也不得包装成 application-ready、
// native-ready、backend-ready、renderer state write、receipt、record 或 publication
// wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningFacts {
    let didConsumeD3ResultEnvelopePacketValidationReadiness: Bool
    let didOpenD3ResultEnvelopeRendererStatePlanningRoute: Bool
    let didRequireValidatedPacketBeforeRendererStatePlan: Bool
    let didRequireQuarantinedPacketAsPlanningInput: Bool
    let didRequireRendererStateTransitionDescriptor: Bool
    let didRequireNoWriteGateBeforePromotion: Bool
    let didRequirePromotionHoldUntilExternalValidation: Bool
    let didRequireStatePlanArtifactContainment: Bool
    let didRequireFailureDomainContinuity: Bool
    let didRequireRuntimeStateLineCountInvariant: Bool
    let didKeepCurrentShellPromotionRejected: Bool
    let didKeepRendererStatePlanningDehydrated: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didAvoidSameShapePacketValidationWrapper: Bool

    init(
        didConsumeD3ResultEnvelopePacketValidationReadiness: Bool,
        didOpenD3ResultEnvelopeRendererStatePlanningRoute: Bool,
        didRequireValidatedPacketBeforeRendererStatePlan: Bool,
        didRequireQuarantinedPacketAsPlanningInput: Bool,
        didRequireRendererStateTransitionDescriptor: Bool,
        didRequireNoWriteGateBeforePromotion: Bool,
        didRequirePromotionHoldUntilExternalValidation: Bool,
        didRequireStatePlanArtifactContainment: Bool,
        didRequireFailureDomainContinuity: Bool,
        didRequireRuntimeStateLineCountInvariant: Bool,
        didKeepCurrentShellPromotionRejected: Bool,
        didKeepRendererStatePlanningDehydrated: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didAvoidSameShapePacketValidationWrapper: Bool
    ) {
        this.didConsumeD3ResultEnvelopePacketValidationReadiness =
            didConsumeD3ResultEnvelopePacketValidationReadiness
        this.didOpenD3ResultEnvelopeRendererStatePlanningRoute =
            didOpenD3ResultEnvelopeRendererStatePlanningRoute
        this.didRequireValidatedPacketBeforeRendererStatePlan =
            didRequireValidatedPacketBeforeRendererStatePlan
        this.didRequireQuarantinedPacketAsPlanningInput =
            didRequireQuarantinedPacketAsPlanningInput
        this.didRequireRendererStateTransitionDescriptor =
            didRequireRendererStateTransitionDescriptor
        this.didRequireNoWriteGateBeforePromotion =
            didRequireNoWriteGateBeforePromotion
        this.didRequirePromotionHoldUntilExternalValidation =
            didRequirePromotionHoldUntilExternalValidation
        this.didRequireStatePlanArtifactContainment =
            didRequireStatePlanArtifactContainment
        this.didRequireFailureDomainContinuity =
            didRequireFailureDomainContinuity
        this.didRequireRuntimeStateLineCountInvariant =
            didRequireRuntimeStateLineCountInvariant
        this.didKeepCurrentShellPromotionRejected =
            didKeepCurrentShellPromotionRejected
        this.didKeepRendererStatePlanningDehydrated =
            didKeepRendererStatePlanningDehydrated
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
        this.didAvoidSameShapePacketValidationWrapper =
            didAvoidSameShapePacketValidationWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningReadiness {
    let d3ResultEnvelopePacketValidationReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness
    let d3ResultEnvelopeRendererStatePlanningFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningFacts
    let didPrepareRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningReadiness: Bool
    let shouldBuildRendererStateTransitionPlan: Bool
    let shouldHoldPacketPromotion: Bool
    let shouldRequireExternalValidatedPacketForPromotion: Bool
    let shouldKeepRendererStateNoWrite: Bool
    let shouldContinueD3ResultEnvelopeRendererStatePlanningRoute: Bool
    let shouldReportD3ResultEnvelopeRendererStatePlanningBlocked: Bool
    let didConfirmD3ResultEnvelopePacketValidationInput: Bool
    let didConfirmValidatedPacketBeforeRendererStatePlanRequired: Bool
    let didConfirmQuarantinedPacketAsPlanningInputRequired: Bool
    let didConfirmRendererStateTransitionDescriptorRequired: Bool
    let didConfirmNoWriteGateBeforePromotionRequired: Bool
    let didConfirmPromotionHoldUntilExternalValidationRequired: Bool
    let didConfirmStatePlanArtifactContainmentRequired: Bool
    let didConfirmFailureDomainContinuityRequired: Bool
    let didConfirmRuntimeStateLineCountInvariantRequired: Bool
    let didConfirmCurrentShellPromotionRejected: Bool
    let didConfirmRendererStatePlanningDehydrated: Bool
    let didConfirmNoProductionTruthUpgradeRequired: Bool
    let didConfirmNoApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didAvoidSameShapePacketValidationWrapper: Bool

    init(
        d3ResultEnvelopePacketValidationReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness,
        d3ResultEnvelopeRendererStatePlanningFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningFacts,
        didPrepareRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningReadiness: Bool,
        shouldBuildRendererStateTransitionPlan: Bool,
        shouldHoldPacketPromotion: Bool,
        shouldRequireExternalValidatedPacketForPromotion: Bool,
        shouldKeepRendererStateNoWrite: Bool,
        shouldContinueD3ResultEnvelopeRendererStatePlanningRoute: Bool,
        shouldReportD3ResultEnvelopeRendererStatePlanningBlocked: Bool,
        didConfirmD3ResultEnvelopePacketValidationInput: Bool,
        didConfirmValidatedPacketBeforeRendererStatePlanRequired: Bool,
        didConfirmQuarantinedPacketAsPlanningInputRequired: Bool,
        didConfirmRendererStateTransitionDescriptorRequired: Bool,
        didConfirmNoWriteGateBeforePromotionRequired: Bool,
        didConfirmPromotionHoldUntilExternalValidationRequired: Bool,
        didConfirmStatePlanArtifactContainmentRequired: Bool,
        didConfirmFailureDomainContinuityRequired: Bool,
        didConfirmRuntimeStateLineCountInvariantRequired: Bool,
        didConfirmCurrentShellPromotionRejected: Bool,
        didConfirmRendererStatePlanningDehydrated: Bool,
        didConfirmNoProductionTruthUpgradeRequired: Bool,
        didConfirmNoApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didAvoidSameShapePacketValidationWrapper: Bool
    ) {
        this.d3ResultEnvelopePacketValidationReadiness =
            d3ResultEnvelopePacketValidationReadiness
        this.d3ResultEnvelopeRendererStatePlanningFacts =
            d3ResultEnvelopeRendererStatePlanningFacts
        this.didPrepareRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningReadiness =
            didPrepareRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningReadiness
        this.shouldBuildRendererStateTransitionPlan =
            shouldBuildRendererStateTransitionPlan
        this.shouldHoldPacketPromotion = shouldHoldPacketPromotion
        this.shouldRequireExternalValidatedPacketForPromotion =
            shouldRequireExternalValidatedPacketForPromotion
        this.shouldKeepRendererStateNoWrite = shouldKeepRendererStateNoWrite
        this.shouldContinueD3ResultEnvelopeRendererStatePlanningRoute =
            shouldContinueD3ResultEnvelopeRendererStatePlanningRoute
        this.shouldReportD3ResultEnvelopeRendererStatePlanningBlocked =
            shouldReportD3ResultEnvelopeRendererStatePlanningBlocked
        this.didConfirmD3ResultEnvelopePacketValidationInput =
            didConfirmD3ResultEnvelopePacketValidationInput
        this.didConfirmValidatedPacketBeforeRendererStatePlanRequired =
            didConfirmValidatedPacketBeforeRendererStatePlanRequired
        this.didConfirmQuarantinedPacketAsPlanningInputRequired =
            didConfirmQuarantinedPacketAsPlanningInputRequired
        this.didConfirmRendererStateTransitionDescriptorRequired =
            didConfirmRendererStateTransitionDescriptorRequired
        this.didConfirmNoWriteGateBeforePromotionRequired =
            didConfirmNoWriteGateBeforePromotionRequired
        this.didConfirmPromotionHoldUntilExternalValidationRequired =
            didConfirmPromotionHoldUntilExternalValidationRequired
        this.didConfirmStatePlanArtifactContainmentRequired =
            didConfirmStatePlanArtifactContainmentRequired
        this.didConfirmFailureDomainContinuityRequired =
            didConfirmFailureDomainContinuityRequired
        this.didConfirmRuntimeStateLineCountInvariantRequired =
            didConfirmRuntimeStateLineCountInvariantRequired
        this.didConfirmCurrentShellPromotionRejected =
            didConfirmCurrentShellPromotionRejected
        this.didConfirmRendererStatePlanningDehydrated =
            didConfirmRendererStatePlanningDehydrated
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
        this.didAvoidSameShapePacketValidationWrapper =
            didAvoidSameShapePacketValidationWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningFacts(
    d3ResultEnvelopePacketValidationReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningFacts(
        d3ResultEnvelopePacketValidationReadiness
            .didPrepareRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness,
        true,
        d3ResultEnvelopePacketValidationReadiness
            .shouldRequireValidatedExternalPacketBeforePromotion,
        d3ResultEnvelopePacketValidationReadiness.shouldQuarantinePacketPromotion,
        true,
        d3ResultEnvelopePacketValidationReadiness
            .shouldRunRendererStateNoWritePreflightBeforePromotion,
        true,
        d3ResultEnvelopePacketValidationReadiness
            .didConfirmArtifactContainmentBindingRequired,
        d3ResultEnvelopePacketValidationReadiness
            .didConfirmFailureDomainContinuityRequired,
        true,
        d3ResultEnvelopePacketValidationReadiness.shouldRejectCurrentShellPacket &&
            d3ResultEnvelopePacketValidationReadiness.shouldQuarantinePacketPromotion,
        true,
        d3ResultEnvelopePacketValidationReadiness
            .didConfirmNoProductionTruthUpgradeRequired,
        d3ResultEnvelopePacketValidationReadiness.didConfirmNoApplicationAccessorCall,
        d3ResultEnvelopePacketValidationReadiness.didConfirmNoNativeBridgeExpansion,
        d3ResultEnvelopePacketValidationReadiness.didConfirmNoPublicApi,
        d3ResultEnvelopePacketValidationReadiness.didConfirmNoProductionPublicCAbi,
        d3ResultEnvelopePacketValidationReadiness.didConfirmNoRendererStateWrite,
        d3ResultEnvelopePacketValidationReadiness.didConfirmNoRuntimeStateWrite,
        d3ResultEnvelopePacketValidationReadiness.didConfirmNoCjpmTomlChange,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningReadiness(
    d3ResultEnvelopePacketValidationReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationReadiness,
    d3ResultEnvelopeRendererStatePlanningFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningReadiness {
    let rendererStatePlanningReady =
        d3ResultEnvelopeRendererStatePlanningFacts
            .didConsumeD3ResultEnvelopePacketValidationReadiness &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didOpenD3ResultEnvelopeRendererStatePlanningRoute &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireValidatedPacketBeforeRendererStatePlan &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireQuarantinedPacketAsPlanningInput &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireRendererStateTransitionDescriptor &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireNoWriteGateBeforePromotion &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequirePromotionHoldUntilExternalValidation &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireStatePlanArtifactContainment &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireFailureDomainContinuity &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireRuntimeStateLineCountInvariant &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didKeepCurrentShellPromotionRejected &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didKeepRendererStatePlanningDehydrated &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didConfirmNoProductionTruthUpgrade &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didConfirmNoApplicationAccessorCall &&
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoNativeBridgeExpansion &&
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoPublicApi &&
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoProductionPublicCAbi &&
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoRendererStateWrite &&
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoRuntimeStateWrite &&
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoCjpmTomlChange &&
        d3ResultEnvelopeRendererStatePlanningFacts
            .didAvoidSameShapePacketValidationWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningReadiness(
        d3ResultEnvelopePacketValidationReadiness,
        d3ResultEnvelopeRendererStatePlanningFacts,
        rendererStatePlanningReady,
        rendererStatePlanningReady,
        rendererStatePlanningReady,
        rendererStatePlanningReady,
        rendererStatePlanningReady,
        rendererStatePlanningReady,
        !rendererStatePlanningReady,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didConsumeD3ResultEnvelopePacketValidationReadiness,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireValidatedPacketBeforeRendererStatePlan,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireQuarantinedPacketAsPlanningInput,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireRendererStateTransitionDescriptor,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireNoWriteGateBeforePromotion,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequirePromotionHoldUntilExternalValidation,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireStatePlanArtifactContainment,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireFailureDomainContinuity,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didRequireRuntimeStateLineCountInvariant,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didKeepCurrentShellPromotionRejected,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didKeepRendererStatePlanningDehydrated,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didConfirmNoProductionTruthUpgrade,
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoApplicationAccessorCall,
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoNativeBridgeExpansion,
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoPublicApi,
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoProductionPublicCAbi,
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoRendererStateWrite,
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoRuntimeStateWrite,
        d3ResultEnvelopeRendererStatePlanningFacts.didConfirmNoCjpmTomlChange,
        d3ResultEnvelopeRendererStatePlanningFacts
            .didAvoidSameShapePacketValidationWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningReadiness {
    let d3ResultEnvelopePacketValidationReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopePacketValidationDraft()
    let d3ResultEnvelopeRendererStatePlanningFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningFacts(
            d3ResultEnvelopePacketValidationReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStatePlanningReadiness(
        d3ResultEnvelopePacketValidationReadiness,
        d3ResultEnvelopeRendererStatePlanningFacts
    )
}

// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application runtime native-readiness D3 bounded result-envelope
// admission 到 renderer-state write-decision 的 join preflight owner。
// Owner: runtime renderer internal D3 bounded admission + independent
// renderer-state write-decision join owner。
// Truth: 只把 successful bounded result-envelope admission 与 independent
// write-decision contract 绑定成 guarded preflight；join 本身不是 production
// write permission，不写 renderer state，不升级 isolated evidence、production
// truth 或 backend-ready truth。
// Stop-line: 不新增 production accessor call site，不调用 application singleton
// accessor，不创建或激活 NSApplication，不扩 native bridge / public API /
// production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state，不把
// bounded isolated evidence 解释成 renderer backend ready。
// Same-shape Boundary Brake: 本 owner 必须表达 admitted bounded envelope 与
// independent write-decision contract 的 join preflight；不得退化成 admission、
// write-decision contract、two-key handoff、external packet、approval、recovery、
// no-runtime-execution 或 report wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts {
    let didConsumeBoundedResultEnvelopeAdmissionReadiness: Bool
    let didConsumeRendererStateWriteDecisionContractReadiness: Bool
    let didOpenBoundedAdmissionWriteDecisionJoinPreflightRoute: Bool
    let didRequireAdmittedBoundedResultEnvelopeInput: Bool
    let didRequireIndependentRendererStateWriteDecisionContractInput: Bool
    let didBindAdmittedEnvelopeToWriteDecisionContract: Bool
    let didConfirmBoundedEnvelopeRemainsIsolatedEvidenceOnly: Bool
    let didConfirmWriteDecisionContractIsNotWritePermission: Bool
    let didRequireProductionWriteAdmissionAfterJoinPreflight: Bool
    let didKeepRendererStateWriteBlockedAfterJoinPreflight: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruthUpgrade: Bool
    let didConfirmNoProductionApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidAdmissionContractOrExternalPacketWrapper: Bool

    init(
        didConsumeBoundedResultEnvelopeAdmissionReadiness: Bool,
        didConsumeRendererStateWriteDecisionContractReadiness: Bool,
        didOpenBoundedAdmissionWriteDecisionJoinPreflightRoute: Bool,
        didRequireAdmittedBoundedResultEnvelopeInput: Bool,
        didRequireIndependentRendererStateWriteDecisionContractInput: Bool,
        didBindAdmittedEnvelopeToWriteDecisionContract: Bool,
        didConfirmBoundedEnvelopeRemainsIsolatedEvidenceOnly: Bool,
        didConfirmWriteDecisionContractIsNotWritePermission: Bool,
        didRequireProductionWriteAdmissionAfterJoinPreflight: Bool,
        didKeepRendererStateWriteBlockedAfterJoinPreflight: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruthUpgrade: Bool,
        didConfirmNoProductionApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidAdmissionContractOrExternalPacketWrapper: Bool
    ) {
        this.didConsumeBoundedResultEnvelopeAdmissionReadiness =
            didConsumeBoundedResultEnvelopeAdmissionReadiness
        this.didConsumeRendererStateWriteDecisionContractReadiness =
            didConsumeRendererStateWriteDecisionContractReadiness
        this.didOpenBoundedAdmissionWriteDecisionJoinPreflightRoute =
            didOpenBoundedAdmissionWriteDecisionJoinPreflightRoute
        this.didRequireAdmittedBoundedResultEnvelopeInput =
            didRequireAdmittedBoundedResultEnvelopeInput
        this.didRequireIndependentRendererStateWriteDecisionContractInput =
            didRequireIndependentRendererStateWriteDecisionContractInput
        this.didBindAdmittedEnvelopeToWriteDecisionContract =
            didBindAdmittedEnvelopeToWriteDecisionContract
        this.didConfirmBoundedEnvelopeRemainsIsolatedEvidenceOnly =
            didConfirmBoundedEnvelopeRemainsIsolatedEvidenceOnly
        this.didConfirmWriteDecisionContractIsNotWritePermission =
            didConfirmWriteDecisionContractIsNotWritePermission
        this.didRequireProductionWriteAdmissionAfterJoinPreflight =
            didRequireProductionWriteAdmissionAfterJoinPreflight
        this.didKeepRendererStateWriteBlockedAfterJoinPreflight =
            didKeepRendererStateWriteBlockedAfterJoinPreflight
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruthUpgrade =
            didConfirmNoBackendReadyTruthUpgrade
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
        this.didAvoidAdmissionContractOrExternalPacketWrapper =
            didAvoidAdmissionContractOrExternalPacketWrapper
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness {
    let d3BoundedResultEnvelopeAdmissionReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionReadiness
    let d3ResultEnvelopeRendererStateWriteDecisionContractReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateWriteDecisionContractReadiness
    let d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
    let didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness: Bool
    let shouldContinueRendererStateWriteDecisionJoinRoute: Bool
    let shouldRequireAdmittedBoundedResultEnvelopeInput: Bool
    let shouldRequireIndependentRendererStateWriteDecisionContractInput: Bool
    let shouldTreatJoinPreflightAsNonWriting: Bool
    let shouldRequireProductionWriteAdmissionAfterJoinPreflight: Bool
    let shouldKeepRendererStateWriteBlocked: Bool
    let didConfirmBoundedAdmissionInput: Bool
    let didConfirmWriteDecisionContractInput: Bool
    let didConfirmAdmittedBoundedResultEnvelopeInputRequired: Bool
    let didConfirmIndependentWriteDecisionContractInputRequired: Bool
    let didConfirmBoundedEnvelopeWriteDecisionJoinBound: Bool
    let didConfirmBoundedEnvelopeIsolatedEvidenceOnly: Bool
    let didConfirmWriteDecisionContractIsNotWritePermission: Bool
    let didConfirmProductionWriteAdmissionAfterJoinPreflightRequired: Bool
    let didConfirmRendererStateWriteBlockedAfterJoinPreflight: Bool
    let didConfirmNoProductionTruthUpgrade: Bool
    let didConfirmNoBackendReadyTruthUpgrade: Bool
    let didConfirmNoProductionApplicationAccessorCall: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didAvoidAdmissionContractOrExternalPacketWrapper: Bool

    init(
        d3BoundedResultEnvelopeAdmissionReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionReadiness,
        d3ResultEnvelopeRendererStateWriteDecisionContractReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateWriteDecisionContractReadiness,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts,
        didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness: Bool,
        shouldContinueRendererStateWriteDecisionJoinRoute: Bool,
        shouldRequireAdmittedBoundedResultEnvelopeInput: Bool,
        shouldRequireIndependentRendererStateWriteDecisionContractInput: Bool,
        shouldTreatJoinPreflightAsNonWriting: Bool,
        shouldRequireProductionWriteAdmissionAfterJoinPreflight: Bool,
        shouldKeepRendererStateWriteBlocked: Bool,
        didConfirmBoundedAdmissionInput: Bool,
        didConfirmWriteDecisionContractInput: Bool,
        didConfirmAdmittedBoundedResultEnvelopeInputRequired: Bool,
        didConfirmIndependentWriteDecisionContractInputRequired: Bool,
        didConfirmBoundedEnvelopeWriteDecisionJoinBound: Bool,
        didConfirmBoundedEnvelopeIsolatedEvidenceOnly: Bool,
        didConfirmWriteDecisionContractIsNotWritePermission: Bool,
        didConfirmProductionWriteAdmissionAfterJoinPreflightRequired: Bool,
        didConfirmRendererStateWriteBlockedAfterJoinPreflight: Bool,
        didConfirmNoProductionTruthUpgrade: Bool,
        didConfirmNoBackendReadyTruthUpgrade: Bool,
        didConfirmNoProductionApplicationAccessorCall: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didAvoidAdmissionContractOrExternalPacketWrapper: Bool
    ) {
        this.d3BoundedResultEnvelopeAdmissionReadiness =
            d3BoundedResultEnvelopeAdmissionReadiness
        this.d3ResultEnvelopeRendererStateWriteDecisionContractReadiness =
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
        this.d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts =
            d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
        this.didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness =
            didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness
        this.shouldContinueRendererStateWriteDecisionJoinRoute =
            shouldContinueRendererStateWriteDecisionJoinRoute
        this.shouldRequireAdmittedBoundedResultEnvelopeInput =
            shouldRequireAdmittedBoundedResultEnvelopeInput
        this.shouldRequireIndependentRendererStateWriteDecisionContractInput =
            shouldRequireIndependentRendererStateWriteDecisionContractInput
        this.shouldTreatJoinPreflightAsNonWriting =
            shouldTreatJoinPreflightAsNonWriting
        this.shouldRequireProductionWriteAdmissionAfterJoinPreflight =
            shouldRequireProductionWriteAdmissionAfterJoinPreflight
        this.shouldKeepRendererStateWriteBlocked =
            shouldKeepRendererStateWriteBlocked
        this.didConfirmBoundedAdmissionInput = didConfirmBoundedAdmissionInput
        this.didConfirmWriteDecisionContractInput =
            didConfirmWriteDecisionContractInput
        this.didConfirmAdmittedBoundedResultEnvelopeInputRequired =
            didConfirmAdmittedBoundedResultEnvelopeInputRequired
        this.didConfirmIndependentWriteDecisionContractInputRequired =
            didConfirmIndependentWriteDecisionContractInputRequired
        this.didConfirmBoundedEnvelopeWriteDecisionJoinBound =
            didConfirmBoundedEnvelopeWriteDecisionJoinBound
        this.didConfirmBoundedEnvelopeIsolatedEvidenceOnly =
            didConfirmBoundedEnvelopeIsolatedEvidenceOnly
        this.didConfirmWriteDecisionContractIsNotWritePermission =
            didConfirmWriteDecisionContractIsNotWritePermission
        this.didConfirmProductionWriteAdmissionAfterJoinPreflightRequired =
            didConfirmProductionWriteAdmissionAfterJoinPreflightRequired
        this.didConfirmRendererStateWriteBlockedAfterJoinPreflight =
            didConfirmRendererStateWriteBlockedAfterJoinPreflight
        this.didConfirmNoProductionTruthUpgrade =
            didConfirmNoProductionTruthUpgrade
        this.didConfirmNoBackendReadyTruthUpgrade =
            didConfirmNoBackendReadyTruthUpgrade
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
        this.didAvoidAdmissionContractOrExternalPacketWrapper =
            didAvoidAdmissionContractOrExternalPacketWrapper
    }
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts(
    d3BoundedResultEnvelopeAdmissionReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionReadiness,
    d3ResultEnvelopeRendererStateWriteDecisionContractReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateWriteDecisionContractReadiness
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts {
    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts(
        d3BoundedResultEnvelopeAdmissionReadiness
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionReadiness,
        d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
            .didPrepareRuntimeNativeProbeD3ResultEnvelopeRendererStateWriteDecisionContractReadiness,
        true,
        d3BoundedResultEnvelopeAdmissionReadiness
            .shouldAdmitSuccessfulBoundedResultEnvelope &&
            d3BoundedResultEnvelopeAdmissionReadiness
                .didConfirmSuccessfulBoundedResultEnvelopeAdmission,
        d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
            .shouldPrepareIndependentRendererStateWriteDecisionContract &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .didConfirmIndependentRendererStateWriteDecisionPacketRequired,
        d3BoundedResultEnvelopeAdmissionReadiness
            .didConfirmSuccessfulBoundedResultEnvelopeAdmission &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .didConfirmIndependentRendererStateWriteDecisionPacketRequired,
        d3BoundedResultEnvelopeAdmissionReadiness
            .shouldKeepResultEnvelopeAsIsolatedEvidenceOnly &&
            d3BoundedResultEnvelopeAdmissionReadiness
                .didConfirmResultEnvelopeIsolatedEvidenceOnly,
        d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
            .didConfirmProvenanceReplayIsNotWritePermission,
        true,
        d3BoundedResultEnvelopeAdmissionReadiness
            .shouldKeepRendererStateWriteBlocked &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .shouldKeepRendererStateWriteBlocked,
        d3BoundedResultEnvelopeAdmissionReadiness
            .didConfirmResultEnvelopeIsNotProductionTruth &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .didConfirmNoProductionTruthUpgradeRequired,
        d3BoundedResultEnvelopeAdmissionReadiness
            .didConfirmNoBackendReadyTruthUpgrade,
        d3BoundedResultEnvelopeAdmissionReadiness
            .didConfirmNoProductionApplicationAccessorCall &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .didConfirmNoApplicationAccessorCall,
        d3BoundedResultEnvelopeAdmissionReadiness
            .didConfirmNoNativeBridgeExpansion &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .didConfirmNoNativeBridgeExpansion,
        d3BoundedResultEnvelopeAdmissionReadiness.didConfirmNoPublicApi &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .didConfirmNoPublicApi,
        d3BoundedResultEnvelopeAdmissionReadiness
            .didConfirmNoProductionPublicCAbi &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .didConfirmNoProductionPublicCAbi,
        d3BoundedResultEnvelopeAdmissionReadiness.didConfirmNoRuntimeStateWrite &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .didConfirmNoRuntimeStateWrite,
        d3BoundedResultEnvelopeAdmissionReadiness.didConfirmNoCjpmTomlChange &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .didConfirmNoCjpmTomlChange,
        d3BoundedResultEnvelopeAdmissionReadiness.didConfirmNoRendererStateWrite &&
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
                .didConfirmNoRendererStateWrite,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness(
    d3BoundedResultEnvelopeAdmissionReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionReadiness,
    d3ResultEnvelopeRendererStateWriteDecisionContractReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateWriteDecisionContractReadiness,
    d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness {
    let writeDecisionJoinReady =
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConsumeBoundedResultEnvelopeAdmissionReadiness &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConsumeRendererStateWriteDecisionContractReadiness &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didOpenBoundedAdmissionWriteDecisionJoinPreflightRoute &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didRequireAdmittedBoundedResultEnvelopeInput &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didRequireIndependentRendererStateWriteDecisionContractInput &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didBindAdmittedEnvelopeToWriteDecisionContract &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmBoundedEnvelopeRemainsIsolatedEvidenceOnly &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmWriteDecisionContractIsNotWritePermission &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didRequireProductionWriteAdmissionAfterJoinPreflight &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didKeepRendererStateWriteBlockedAfterJoinPreflight &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoProductionTruthUpgrade &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoBackendReadyTruthUpgrade &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoProductionApplicationAccessorCall &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoNativeBridgeExpansion &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoPublicApi &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoProductionPublicCAbi &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoRuntimeStateWrite &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoCjpmTomlChange &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoRendererStateWrite &&
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didAvoidAdmissionContractOrExternalPacketWrapper

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness(
        d3BoundedResultEnvelopeAdmissionReadiness,
        d3ResultEnvelopeRendererStateWriteDecisionContractReadiness,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts,
        writeDecisionJoinReady,
        writeDecisionJoinReady,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didRequireAdmittedBoundedResultEnvelopeInput,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didRequireIndependentRendererStateWriteDecisionContractInput,
        true,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didRequireProductionWriteAdmissionAfterJoinPreflight,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didKeepRendererStateWriteBlockedAfterJoinPreflight,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConsumeBoundedResultEnvelopeAdmissionReadiness,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConsumeRendererStateWriteDecisionContractReadiness,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didRequireAdmittedBoundedResultEnvelopeInput,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didRequireIndependentRendererStateWriteDecisionContractInput,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didBindAdmittedEnvelopeToWriteDecisionContract,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmBoundedEnvelopeRemainsIsolatedEvidenceOnly,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmWriteDecisionContractIsNotWritePermission,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didRequireProductionWriteAdmissionAfterJoinPreflight,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didKeepRendererStateWriteBlockedAfterJoinPreflight,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoProductionTruthUpgrade,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoBackendReadyTruthUpgrade,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoProductionApplicationAccessorCall,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoNativeBridgeExpansion,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoPublicApi,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoProductionPublicCAbi,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoRuntimeStateWrite,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoCjpmTomlChange,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didConfirmNoRendererStateWrite,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
            .didAvoidAdmissionContractOrExternalPacketWrapper
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness {
    let d3BoundedResultEnvelopeAdmissionReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionDraft()
    let d3ResultEnvelopeRendererStateWriteDecisionContractReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateWriteDecisionContractDraft()
    let d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts =
        cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts(
            d3BoundedResultEnvelopeAdmissionReadiness,
            d3ResultEnvelopeRendererStateWriteDecisionContractReadiness
        )
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeRendererStateWriteDecisionJoinReadiness(
        d3BoundedResultEnvelopeAdmissionReadiness,
        d3ResultEnvelopeRendererStateWriteDecisionContractReadiness,
        d3BoundedResultEnvelopeRendererStateWriteDecisionJoinFacts
    )
}

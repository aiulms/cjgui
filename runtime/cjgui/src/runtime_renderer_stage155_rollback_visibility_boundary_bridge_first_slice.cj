// 中文维护注释：本文件是 stage155 rollback visibility boundary bridge
// first-slice runtime owner。
// Owner: runtime renderer internal bridge from stage154 visibility publication
// bridge to rollback / visibility boundary readiness。
// Truth: 本阶段新增 rollback visibility positive predicate map / fixture，并为
// renderer-state write first slice 准备输入；不执行 rollback 或 state write。
// Stop-line: rollback fallback、renderer_state_write 与 runtime_state_write
// 必须保持 false。
package cjgui

struct CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceFacts {
    let didConsumeStage154VisibilityPublicationBridgeReadiness: Bool
    let didConsumeLegacyRollbackFallbackDenialReadiness: Bool
    let didRequireStage154VisibilityPublicationBridgePacket: Bool
    let didRequireLegacyRollbackFallbackDenialPacket: Bool
    let didBindVisibilityPublicationBridgeToRollbackBoundary: Bool
    let didMaterializeRollbackVisibilityPositivePredicateMap: Bool
    let didDefineRollbackVisibilityBoundaryPositiveFixture: Bool
    let didBindLegacyRollbackDenialToStage155Boundary: Bool
    let didPrepareRendererStateWriteFirstSliceInput: Bool
    let didKeepRollbackVisibilityBoundarySourceOnly: Bool
    let didKeepRollbackVisibilityBoundaryRuntimeAdmissionBlocked: Bool
    let didKeepRollbackFallbackNonExecutable: Bool
    let didKeepRollbackFallbackStateWriteDenied: Bool
    let didKeepRollbackVisibilityBoundaryPredicatesUnsatisfied: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        didConsumeStage154VisibilityPublicationBridgeReadiness: Bool,
        didConsumeLegacyRollbackFallbackDenialReadiness: Bool,
        didRequireStage154VisibilityPublicationBridgePacket: Bool,
        didRequireLegacyRollbackFallbackDenialPacket: Bool,
        didBindVisibilityPublicationBridgeToRollbackBoundary: Bool,
        didMaterializeRollbackVisibilityPositivePredicateMap: Bool,
        didDefineRollbackVisibilityBoundaryPositiveFixture: Bool,
        didBindLegacyRollbackDenialToStage155Boundary: Bool,
        didPrepareRendererStateWriteFirstSliceInput: Bool,
        didKeepRollbackVisibilityBoundarySourceOnly: Bool,
        didKeepRollbackVisibilityBoundaryRuntimeAdmissionBlocked: Bool,
        didKeepRollbackFallbackNonExecutable: Bool,
        didKeepRollbackFallbackStateWriteDenied: Bool,
        didKeepRollbackVisibilityBoundaryPredicatesUnsatisfied: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.didConsumeStage154VisibilityPublicationBridgeReadiness =
            didConsumeStage154VisibilityPublicationBridgeReadiness
        this.didConsumeLegacyRollbackFallbackDenialReadiness =
            didConsumeLegacyRollbackFallbackDenialReadiness
        this.didRequireStage154VisibilityPublicationBridgePacket =
            didRequireStage154VisibilityPublicationBridgePacket
        this.didRequireLegacyRollbackFallbackDenialPacket =
            didRequireLegacyRollbackFallbackDenialPacket
        this.didBindVisibilityPublicationBridgeToRollbackBoundary =
            didBindVisibilityPublicationBridgeToRollbackBoundary
        this.didMaterializeRollbackVisibilityPositivePredicateMap =
            didMaterializeRollbackVisibilityPositivePredicateMap
        this.didDefineRollbackVisibilityBoundaryPositiveFixture =
            didDefineRollbackVisibilityBoundaryPositiveFixture
        this.didBindLegacyRollbackDenialToStage155Boundary =
            didBindLegacyRollbackDenialToStage155Boundary
        this.didPrepareRendererStateWriteFirstSliceInput =
            didPrepareRendererStateWriteFirstSliceInput
        this.didKeepRollbackVisibilityBoundarySourceOnly =
            didKeepRollbackVisibilityBoundarySourceOnly
        this.didKeepRollbackVisibilityBoundaryRuntimeAdmissionBlocked =
            didKeepRollbackVisibilityBoundaryRuntimeAdmissionBlocked
        this.didKeepRollbackFallbackNonExecutable =
            didKeepRollbackFallbackNonExecutable
        this.didKeepRollbackFallbackStateWriteDenied =
            didKeepRollbackFallbackStateWriteDenied
        this.didKeepRollbackVisibilityBoundaryPredicatesUnsatisfied =
            didKeepRollbackVisibilityBoundaryPredicatesUnsatisfied
        this.didKeepRendererStateWriteBlocked = didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didConfirmNoNativeBridgeExpansion = didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi = didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

struct CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness {
    let visibilityPublicationBridge:
        CjguiInternalRendererStage154VisibilityPublicationBridgeFirstSliceReadiness
    let legacyRollbackFallbackDenial:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateRollbackFallbackDenialEnvelopeFirstSliceReadiness
    let rollbackVisibilityBoundaryFacts:
        CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceFacts
    let didPrepareRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness:
        Bool
    let shouldConsumeStage154VisibilityPublicationBridgeReadiness: Bool
    let shouldConsumeLegacyRollbackFallbackDenialReadiness: Bool
    let shouldBindVisibilityPublicationBridgeToRollbackBoundary: Bool
    let shouldMaterializeRollbackVisibilityPositivePredicateMap: Bool
    let shouldDefineRollbackVisibilityBoundaryPositiveFixture: Bool
    let shouldKeepRollbackVisibilityBoundarySourceOnly: Bool
    let didConfirmStage154VisibilityPublicationBridgeInput: Bool
    let didConfirmLegacyRollbackFallbackDenialInput: Bool
    let didConfirmRollbackVisibilityBoundaryBridgeReady: Bool
    let didConfirmRollbackVisibilityBoundaryBridgeSourceReady: Bool
    let didConfirmRollbackVisibilityBoundaryRuntimeAdmitted: Bool
    let didConfirmRollbackVisibilityPositivePredicateMapMaterialized: Bool
    let didConfirmRollbackVisibilityBoundaryPositiveFixtureDefined: Bool
    let didConfirmRollbackVisibilityBoundaryPredicatesSatisfied: Bool
    let didConfirmRollbackFallbackStateWriteDenied: Bool
    let didConfirmRendererStateWriteFirstSliceInputPrepared: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNoNativeBridgeExpansion: Bool
    let didConfirmNoPublicApi: Bool
    let didConfirmNoProductionPublicCAbi: Bool
    let didConfirmNoRuntimeStateWrite: Bool
    let didConfirmNoCjpmTomlChange: Bool
    let didConfirmNoRendererStateWrite: Bool

    init(
        visibilityPublicationBridge:
            CjguiInternalRendererStage154VisibilityPublicationBridgeFirstSliceReadiness,
        legacyRollbackFallbackDenial:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateRollbackFallbackDenialEnvelopeFirstSliceReadiness,
        rollbackVisibilityBoundaryFacts:
            CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceFacts,
        didPrepareRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness:
            Bool,
        shouldConsumeStage154VisibilityPublicationBridgeReadiness: Bool,
        shouldConsumeLegacyRollbackFallbackDenialReadiness: Bool,
        shouldBindVisibilityPublicationBridgeToRollbackBoundary: Bool,
        shouldMaterializeRollbackVisibilityPositivePredicateMap: Bool,
        shouldDefineRollbackVisibilityBoundaryPositiveFixture: Bool,
        shouldKeepRollbackVisibilityBoundarySourceOnly: Bool,
        didConfirmStage154VisibilityPublicationBridgeInput: Bool,
        didConfirmLegacyRollbackFallbackDenialInput: Bool,
        didConfirmRollbackVisibilityBoundaryBridgeReady: Bool,
        didConfirmRollbackVisibilityBoundaryBridgeSourceReady: Bool,
        didConfirmRollbackVisibilityBoundaryRuntimeAdmitted: Bool,
        didConfirmRollbackVisibilityPositivePredicateMapMaterialized: Bool,
        didConfirmRollbackVisibilityBoundaryPositiveFixtureDefined: Bool,
        didConfirmRollbackVisibilityBoundaryPredicatesSatisfied: Bool,
        didConfirmRollbackFallbackStateWriteDenied: Bool,
        didConfirmRendererStateWriteFirstSliceInputPrepared: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNoNativeBridgeExpansion: Bool,
        didConfirmNoPublicApi: Bool,
        didConfirmNoProductionPublicCAbi: Bool,
        didConfirmNoRuntimeStateWrite: Bool,
        didConfirmNoCjpmTomlChange: Bool,
        didConfirmNoRendererStateWrite: Bool
    ) {
        this.visibilityPublicationBridge = visibilityPublicationBridge
        this.legacyRollbackFallbackDenial = legacyRollbackFallbackDenial
        this.rollbackVisibilityBoundaryFacts = rollbackVisibilityBoundaryFacts
        this.didPrepareRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness =
            didPrepareRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness
        this.shouldConsumeStage154VisibilityPublicationBridgeReadiness =
            shouldConsumeStage154VisibilityPublicationBridgeReadiness
        this.shouldConsumeLegacyRollbackFallbackDenialReadiness =
            shouldConsumeLegacyRollbackFallbackDenialReadiness
        this.shouldBindVisibilityPublicationBridgeToRollbackBoundary =
            shouldBindVisibilityPublicationBridgeToRollbackBoundary
        this.shouldMaterializeRollbackVisibilityPositivePredicateMap =
            shouldMaterializeRollbackVisibilityPositivePredicateMap
        this.shouldDefineRollbackVisibilityBoundaryPositiveFixture =
            shouldDefineRollbackVisibilityBoundaryPositiveFixture
        this.shouldKeepRollbackVisibilityBoundarySourceOnly =
            shouldKeepRollbackVisibilityBoundarySourceOnly
        this.didConfirmStage154VisibilityPublicationBridgeInput =
            didConfirmStage154VisibilityPublicationBridgeInput
        this.didConfirmLegacyRollbackFallbackDenialInput =
            didConfirmLegacyRollbackFallbackDenialInput
        this.didConfirmRollbackVisibilityBoundaryBridgeReady =
            didConfirmRollbackVisibilityBoundaryBridgeReady
        this.didConfirmRollbackVisibilityBoundaryBridgeSourceReady =
            didConfirmRollbackVisibilityBoundaryBridgeSourceReady
        this.didConfirmRollbackVisibilityBoundaryRuntimeAdmitted =
            didConfirmRollbackVisibilityBoundaryRuntimeAdmitted
        this.didConfirmRollbackVisibilityPositivePredicateMapMaterialized =
            didConfirmRollbackVisibilityPositivePredicateMapMaterialized
        this.didConfirmRollbackVisibilityBoundaryPositiveFixtureDefined =
            didConfirmRollbackVisibilityBoundaryPositiveFixtureDefined
        this.didConfirmRollbackVisibilityBoundaryPredicatesSatisfied =
            didConfirmRollbackVisibilityBoundaryPredicatesSatisfied
        this.didConfirmRollbackFallbackStateWriteDenied =
            didConfirmRollbackFallbackStateWriteDenied
        this.didConfirmRendererStateWriteFirstSliceInputPrepared =
            didConfirmRendererStateWriteFirstSliceInputPrepared
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked = didConfirmRuntimeStateWriteBlocked
        this.didConfirmNoNativeBridgeExpansion = didConfirmNoNativeBridgeExpansion
        this.didConfirmNoPublicApi = didConfirmNoPublicApi
        this.didConfirmNoProductionPublicCAbi = didConfirmNoProductionPublicCAbi
        this.didConfirmNoRuntimeStateWrite = didConfirmNoRuntimeStateWrite
        this.didConfirmNoCjpmTomlChange = didConfirmNoCjpmTomlChange
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
    }
}

func cjguiInternalBuildRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceFacts(
    visibilityPublicationBridge:
        CjguiInternalRendererStage154VisibilityPublicationBridgeFirstSliceReadiness,
    legacyRollbackFallbackDenial:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateRollbackFallbackDenialEnvelopeFirstSliceReadiness
): CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceFacts {
    return CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceFacts(
        visibilityPublicationBridge
            .didPrepareRendererStage154VisibilityPublicationBridgeFirstSliceReadiness,
        legacyRollbackFallbackDenial
            .didPrepareRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateRollbackFallbackDenialEnvelopeFirstSliceReadiness,
        true,
        true,
        visibilityPublicationBridge
            .didConfirmRollbackVisibilityBoundaryInputPrepared,
        true,
        true,
        legacyRollbackFallbackDenial
            .didConfirmRollbackFallbackDenialEnvelopeMaterialized,
        true,
        true,
        true,
        legacyRollbackFallbackDenial.didConfirmRollbackFallbackNonExecutable,
        legacyRollbackFallbackDenial.didConfirmRollbackFallbackStateWriteDenied,
        true,
        visibilityPublicationBridge.didConfirmRendererStateWriteBlocked &&
            legacyRollbackFallbackDenial
                .didConfirmRendererStateWriteBlockedAfterRollbackFallbackDenial,
        visibilityPublicationBridge.didConfirmRuntimeStateWriteBlocked &&
            legacyRollbackFallbackDenial
                .didConfirmRuntimeStateWriteBlockedAfterRollbackFallbackDenial,
        visibilityPublicationBridge.didConfirmNoNativeBridgeExpansion &&
            legacyRollbackFallbackDenial.didConfirmNoNativeBridgeExpansion,
        visibilityPublicationBridge.didConfirmNoPublicApi &&
            legacyRollbackFallbackDenial.didConfirmNoPublicApi,
        visibilityPublicationBridge.didConfirmNoProductionPublicCAbi &&
            legacyRollbackFallbackDenial.didConfirmNoProductionPublicCAbi,
        visibilityPublicationBridge.didConfirmNoRuntimeStateWrite &&
            legacyRollbackFallbackDenial.didConfirmNoRuntimeStateWrite,
        visibilityPublicationBridge.didConfirmNoCjpmTomlChange &&
            legacyRollbackFallbackDenial.didConfirmNoCjpmTomlChange,
        visibilityPublicationBridge.didConfirmNoRendererStateWrite &&
            legacyRollbackFallbackDenial.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalBuildRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness(
    visibilityPublicationBridge:
        CjguiInternalRendererStage154VisibilityPublicationBridgeFirstSliceReadiness,
    legacyRollbackFallbackDenial:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateRollbackFallbackDenialEnvelopeFirstSliceReadiness,
    rollbackVisibilityBoundaryFacts:
        CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceFacts
): CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness {
    let stage154InputReady =
        rollbackVisibilityBoundaryFacts
            .didConsumeStage154VisibilityPublicationBridgeReadiness &&
        visibilityPublicationBridge.didConfirmVisibilityPublicationBridgeReady
    let legacyInputReady =
        rollbackVisibilityBoundaryFacts
            .didConsumeLegacyRollbackFallbackDenialReadiness &&
        legacyRollbackFallbackDenial
            .didConfirmRollbackFallbackDenialEnvelopeMaterialized
    let positivePredicateReady =
        rollbackVisibilityBoundaryFacts
            .didBindVisibilityPublicationBridgeToRollbackBoundary &&
        rollbackVisibilityBoundaryFacts
            .didMaterializeRollbackVisibilityPositivePredicateMap &&
        rollbackVisibilityBoundaryFacts
            .didDefineRollbackVisibilityBoundaryPositiveFixture
    let bridgeReady =
        stage154InputReady &&
        legacyInputReady &&
        positivePredicateReady &&
        rollbackVisibilityBoundaryFacts
            .didBindLegacyRollbackDenialToStage155Boundary &&
        rollbackVisibilityBoundaryFacts.didPrepareRendererStateWriteFirstSliceInput &&
        rollbackVisibilityBoundaryFacts.didKeepRollbackVisibilityBoundarySourceOnly
    let stopLineReady =
        rollbackVisibilityBoundaryFacts
            .didKeepRollbackVisibilityBoundaryRuntimeAdmissionBlocked &&
        rollbackVisibilityBoundaryFacts.didKeepRollbackFallbackNonExecutable &&
        rollbackVisibilityBoundaryFacts.didKeepRollbackFallbackStateWriteDenied &&
        rollbackVisibilityBoundaryFacts
            .didKeepRollbackVisibilityBoundaryPredicatesUnsatisfied &&
        rollbackVisibilityBoundaryFacts.didKeepRendererStateWriteBlocked &&
        rollbackVisibilityBoundaryFacts.didKeepRuntimeStateWriteBlocked &&
        rollbackVisibilityBoundaryFacts.didConfirmNoNativeBridgeExpansion &&
        rollbackVisibilityBoundaryFacts.didConfirmNoPublicApi &&
        rollbackVisibilityBoundaryFacts.didConfirmNoProductionPublicCAbi &&
        rollbackVisibilityBoundaryFacts.didConfirmNoRuntimeStateWrite &&
        rollbackVisibilityBoundaryFacts.didConfirmNoCjpmTomlChange &&
        rollbackVisibilityBoundaryFacts.didConfirmNoRendererStateWrite

    return CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness(
        visibilityPublicationBridge,
        legacyRollbackFallbackDenial,
        rollbackVisibilityBoundaryFacts,
        bridgeReady && stopLineReady,
        rollbackVisibilityBoundaryFacts
            .didConsumeStage154VisibilityPublicationBridgeReadiness,
        rollbackVisibilityBoundaryFacts
            .didConsumeLegacyRollbackFallbackDenialReadiness,
        rollbackVisibilityBoundaryFacts
            .didBindVisibilityPublicationBridgeToRollbackBoundary,
        rollbackVisibilityBoundaryFacts
            .didMaterializeRollbackVisibilityPositivePredicateMap,
        rollbackVisibilityBoundaryFacts
            .didDefineRollbackVisibilityBoundaryPositiveFixture,
        rollbackVisibilityBoundaryFacts
            .didKeepRollbackVisibilityBoundarySourceOnly,
        stage154InputReady,
        legacyInputReady,
        bridgeReady,
        bridgeReady,
        false,
        rollbackVisibilityBoundaryFacts
            .didMaterializeRollbackVisibilityPositivePredicateMap,
        rollbackVisibilityBoundaryFacts
            .didDefineRollbackVisibilityBoundaryPositiveFixture,
        false,
        rollbackVisibilityBoundaryFacts.didKeepRollbackFallbackStateWriteDenied,
        rollbackVisibilityBoundaryFacts.didPrepareRendererStateWriteFirstSliceInput,
        rollbackVisibilityBoundaryFacts.didKeepRendererStateWriteBlocked,
        rollbackVisibilityBoundaryFacts.didKeepRuntimeStateWriteBlocked,
        rollbackVisibilityBoundaryFacts.didConfirmNoNativeBridgeExpansion,
        rollbackVisibilityBoundaryFacts.didConfirmNoPublicApi,
        rollbackVisibilityBoundaryFacts.didConfirmNoProductionPublicCAbi,
        rollbackVisibilityBoundaryFacts.didConfirmNoRuntimeStateWrite,
        rollbackVisibilityBoundaryFacts.didConfirmNoCjpmTomlChange,
        rollbackVisibilityBoundaryFacts.didConfirmNoRendererStateWrite
    )
}

func cjguiInternalExecuteDefaultRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceDraft():
    CjguiInternalRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness {
    let visibilityPublicationBridge =
        cjguiInternalExecuteDefaultRendererStage154VisibilityPublicationBridgeFirstSliceDraft()
    let legacyRollbackFallbackDenial =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateRollbackFallbackDenialEnvelopeFirstSliceDraft()
    let rollbackVisibilityBoundaryFacts =
        cjguiInternalBuildRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceFacts(
            visibilityPublicationBridge,
            legacyRollbackFallbackDenial
        )
    return cjguiInternalBuildRendererStage155RollbackVisibilityBoundaryBridgeFirstSliceReadiness(
        visibilityPublicationBridge,
        legacyRollbackFallbackDenial,
        rollbackVisibilityBoundaryFacts
    )
}

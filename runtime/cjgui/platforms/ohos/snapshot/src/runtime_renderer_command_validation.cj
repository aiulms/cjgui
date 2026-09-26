package cjgui

// Internal Renderer Command Packet Validation owner:
// - 本文件只消费 CjguiInternalRenderBatchingPacket。
// - Truth 是 command packet validation、batching packet integrity、validation admission 与 validation result 的内部 value facts。
// - Stop-line: 这里只校验脱水 command / batching facts 的完整性；
//   不接平台图形后端、不持有平台资源、不触发绘制执行、不写 renderer state，
//   也不继续 backend shell readiness / lifecycle / receipt / record 同构尾巴。

// Command packet validation 回到 RenderCommand / BatchingPacket 数据完整性；
// 它不是 backend shell wrapper，也不把 shell readiness 再包装一层。
struct CjguiInternalRendererCommandPacketValidation {
    let batchingPacket: CjguiInternalRenderBatchingPacket
    let commandPacket: CjguiInternalRenderCommandPacket
    let didValidateRendererCommandPacket: Bool
    let shouldDeferRendererCommandPacketValidation: Bool
    let shouldReportRendererCommandPacketValidationBlocked: Bool
    let didPreserveRenderBatchingPacket: Bool
    let didPreserveRenderCommandPacket: Bool
    let didValidateFullRebuildOnly: Bool
    let didValidateStableNodeId: Bool
    let didValidateBoundsFacts: Bool
    let didValidateClipFacts: Bool
    let didValidateZOrderFacts: Bool
    let didValidateMaterialKeyFacts: Bool
    let didValidateVersionFacts: Bool
    let didValidateInvalidationHint: Bool
    let didValidatePlaceholderCommandKind: Bool
    let didKeepValidationBackendAgnostic: Bool
    let didAvoidRendererBackendShellTail: Bool
    let didAvoidDrawingPermission: Bool

    init(
        batchingPacket: CjguiInternalRenderBatchingPacket,
        commandPacket: CjguiInternalRenderCommandPacket,
        didValidateRendererCommandPacket: Bool,
        shouldDeferRendererCommandPacketValidation: Bool,
        shouldReportRendererCommandPacketValidationBlocked: Bool,
        didPreserveRenderBatchingPacket: Bool,
        didPreserveRenderCommandPacket: Bool,
        didValidateFullRebuildOnly: Bool,
        didValidateStableNodeId: Bool,
        didValidateBoundsFacts: Bool,
        didValidateClipFacts: Bool,
        didValidateZOrderFacts: Bool,
        didValidateMaterialKeyFacts: Bool,
        didValidateVersionFacts: Bool,
        didValidateInvalidationHint: Bool,
        didValidatePlaceholderCommandKind: Bool,
        didKeepValidationBackendAgnostic: Bool,
        didAvoidRendererBackendShellTail: Bool,
        didAvoidDrawingPermission: Bool
    ) {
        this.batchingPacket = batchingPacket
        this.commandPacket = commandPacket
        this.didValidateRendererCommandPacket = didValidateRendererCommandPacket
        this.shouldDeferRendererCommandPacketValidation = shouldDeferRendererCommandPacketValidation
        this.shouldReportRendererCommandPacketValidationBlocked = shouldReportRendererCommandPacketValidationBlocked
        this.didPreserveRenderBatchingPacket = didPreserveRenderBatchingPacket
        this.didPreserveRenderCommandPacket = didPreserveRenderCommandPacket
        this.didValidateFullRebuildOnly = didValidateFullRebuildOnly
        this.didValidateStableNodeId = didValidateStableNodeId
        this.didValidateBoundsFacts = didValidateBoundsFacts
        this.didValidateClipFacts = didValidateClipFacts
        this.didValidateZOrderFacts = didValidateZOrderFacts
        this.didValidateMaterialKeyFacts = didValidateMaterialKeyFacts
        this.didValidateVersionFacts = didValidateVersionFacts
        this.didValidateInvalidationHint = didValidateInvalidationHint
        this.didValidatePlaceholderCommandKind = didValidatePlaceholderCommandKind
        this.didKeepValidationBackendAgnostic = didKeepValidationBackendAgnostic
        this.didAvoidRendererBackendShellTail = didAvoidRendererBackendShellTail
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
    }
}

// Batching packet integrity 只校验 batch key / ordering / plan 仍是提示 facts；
// 它不执行排序、不合并绘制工作，也不升级为后端资源。
struct CjguiInternalRendererBatchingPacketIntegrity {
    let commandValidation: CjguiInternalRendererCommandPacketValidation
    let didValidateRendererBatchingPacketIntegrity: Bool
    let shouldDeferRendererBatchingPacketIntegrity: Bool
    let shouldReportRendererBatchingPacketIntegrityBlocked: Bool
    let didPreserveRendererCommandPacketValidation: Bool
    let didValidateBatchKeyAsHint: Bool
    let didValidateOrderingHintValueOnly: Bool
    let didValidateBatchingPlanDehydrated: Bool
    let didValidateNoCommandMerge: Bool
    let didValidateFullRebuildBatching: Bool
    let didKeepIntegrityBackendAgnostic: Bool
    let didAvoidRealBatching: Bool
    let didAvoidDrawingPermission: Bool

    init(
        commandValidation: CjguiInternalRendererCommandPacketValidation,
        didValidateRendererBatchingPacketIntegrity: Bool,
        shouldDeferRendererBatchingPacketIntegrity: Bool,
        shouldReportRendererBatchingPacketIntegrityBlocked: Bool,
        didPreserveRendererCommandPacketValidation: Bool,
        didValidateBatchKeyAsHint: Bool,
        didValidateOrderingHintValueOnly: Bool,
        didValidateBatchingPlanDehydrated: Bool,
        didValidateNoCommandMerge: Bool,
        didValidateFullRebuildBatching: Bool,
        didKeepIntegrityBackendAgnostic: Bool,
        didAvoidRealBatching: Bool,
        didAvoidDrawingPermission: Bool
    ) {
        this.commandValidation = commandValidation
        this.didValidateRendererBatchingPacketIntegrity = didValidateRendererBatchingPacketIntegrity
        this.shouldDeferRendererBatchingPacketIntegrity = shouldDeferRendererBatchingPacketIntegrity
        this.shouldReportRendererBatchingPacketIntegrityBlocked = shouldReportRendererBatchingPacketIntegrityBlocked
        this.didPreserveRendererCommandPacketValidation = didPreserveRendererCommandPacketValidation
        this.didValidateBatchKeyAsHint = didValidateBatchKeyAsHint
        this.didValidateOrderingHintValueOnly = didValidateOrderingHintValueOnly
        this.didValidateBatchingPlanDehydrated = didValidateBatchingPlanDehydrated
        this.didValidateNoCommandMerge = didValidateNoCommandMerge
        this.didValidateFullRebuildBatching = didValidateFullRebuildBatching
        this.didKeepIntegrityBackendAgnostic = didKeepIntegrityBackendAgnostic
        this.didAvoidRealBatching = didAvoidRealBatching
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
    }
}

// Validation admission 只说明 command / batching integrity 可被本 owner 接受；
// 它不是后端准入、不是绘制许可，也不创建 renderer state。
struct CjguiInternalRendererCommandValidationAdmission {
    let batchingIntegrity: CjguiInternalRendererBatchingPacketIntegrity
    let didAdmitRendererCommandValidation: Bool
    let shouldDeferRendererCommandValidationAdmission: Bool
    let shouldReportRendererCommandValidationAdmissionBlocked: Bool
    let didPreserveRendererBatchingPacketIntegrity: Bool
    let didKeepValidationAdmissionBackendAgnostic: Bool
    let didAvoidRendererBackendShellTail: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool

    init(
        batchingIntegrity: CjguiInternalRendererBatchingPacketIntegrity,
        didAdmitRendererCommandValidation: Bool,
        shouldDeferRendererCommandValidationAdmission: Bool,
        shouldReportRendererCommandValidationAdmissionBlocked: Bool,
        didPreserveRendererBatchingPacketIntegrity: Bool,
        didKeepValidationAdmissionBackendAgnostic: Bool,
        didAvoidRendererBackendShellTail: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool
    ) {
        this.batchingIntegrity = batchingIntegrity
        this.didAdmitRendererCommandValidation = didAdmitRendererCommandValidation
        this.shouldDeferRendererCommandValidationAdmission = shouldDeferRendererCommandValidationAdmission
        this.shouldReportRendererCommandValidationAdmissionBlocked = shouldReportRendererCommandValidationAdmissionBlocked
        this.didPreserveRendererBatchingPacketIntegrity = didPreserveRendererBatchingPacketIntegrity
        this.didKeepValidationAdmissionBackendAgnostic = didKeepValidationAdmissionBackendAgnostic
        this.didAvoidRendererBackendShellTail = didAvoidRendererBackendShellTail
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
    }
}

// Validation result 是本轮 endpoint；
// accepted 只表示 packet integrity gate 通过，不代表可以绘制、提交后端或写 renderer state。
struct CjguiInternalRendererCommandValidationResult {
    let admission: CjguiInternalRendererCommandValidationAdmission
    let isRendererCommandValidationAccepted: Bool
    let canFutureRendererBoundaryUseValidatedPacket: Bool
    let shouldDeferRendererCommandValidationResult: Bool
    let shouldReportRendererCommandValidationResultBlocked: Bool
    let didRecordRendererCommandValidationResult: Bool
    let didPreserveRendererCommandValidationAdmission: Bool
    let didKeepValidationResultBackendAgnostic: Bool
    let didAvoidRendererBackendShellTail: Bool
    let didAvoidRendererBackendImplementation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool

    init(
        admission: CjguiInternalRendererCommandValidationAdmission,
        isRendererCommandValidationAccepted: Bool,
        canFutureRendererBoundaryUseValidatedPacket: Bool,
        shouldDeferRendererCommandValidationResult: Bool,
        shouldReportRendererCommandValidationResultBlocked: Bool,
        didRecordRendererCommandValidationResult: Bool,
        didPreserveRendererCommandValidationAdmission: Bool,
        didKeepValidationResultBackendAgnostic: Bool,
        didAvoidRendererBackendShellTail: Bool,
        didAvoidRendererBackendImplementation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool
    ) {
        this.admission = admission
        this.isRendererCommandValidationAccepted = isRendererCommandValidationAccepted
        this.canFutureRendererBoundaryUseValidatedPacket = canFutureRendererBoundaryUseValidatedPacket
        this.shouldDeferRendererCommandValidationResult = shouldDeferRendererCommandValidationResult
        this.shouldReportRendererCommandValidationResultBlocked = shouldReportRendererCommandValidationResultBlocked
        this.didRecordRendererCommandValidationResult = didRecordRendererCommandValidationResult
        this.didPreserveRendererCommandValidationAdmission = didPreserveRendererCommandValidationAdmission
        this.didKeepValidationResultBackendAgnostic = didKeepValidationResultBackendAgnostic
        this.didAvoidRendererBackendShellTail = didAvoidRendererBackendShellTail
        this.didAvoidRendererBackendImplementation = didAvoidRendererBackendImplementation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
    }
}

func cjguiInternalBuildRendererCommandPacketValidation(
    batchingPacket: CjguiInternalRenderBatchingPacket
): CjguiInternalRendererCommandPacketValidation {
    let commandPacket = batchingPacket.batchingPlan.commandPacket
    let commandList = commandPacket.commandList
    let rootCommand = commandList.rootCommand
    let commandReady = batchingPacket.isRenderBatchingPacketReady &&
        commandPacket.isRenderCommandPacketReady &&
        commandPacket.didKeepCommandPacketRendererAgnostic &&
        commandPacket.didAvoidRenderSideEffect &&
        commandPacket.didPreserveRenderCommandList &&
        commandList.didPrepareRenderCommandList &&
        commandList.didUseFullRebuildCommandList &&
        commandList.didAvoidIncrementalCommandUpdate &&
        commandList.didAvoidRendererSubmission &&
        rootCommand.didPrepareRenderCommand &&
        rootCommand.didPreserveNodeFacts &&
        rootCommand.didAvoidActualDrawingOp &&
        rootCommand.nodeId.isStablePlaceholder &&
        rootCommand.bounds.didReserveStableBounds &&
        rootCommand.clip.didReserveClipFacts &&
        rootCommand.materialKey.didReserveMaterialFacts &&
        rootCommand.invalidationHint.requiresFullDisplayListRebuild &&
        rootCommand.invalidationHint.allowsIncrementalRebuild == false &&
        rootCommand.invalidationHint.allowsDisplayListMutation == false &&
        rootCommand.invalidationHint.allowsPartialRepaint == false &&
        rootCommand.invalidationHint.didReserveRepaintHint &&
        rootCommand.kind.isNodePlaceholder &&
        rootCommand.kind.isRealDrawingOp == false &&
        rootCommand.kind.didAvoidDrawCallBinding &&
        commandPacket.shouldDeferRenderCommandPacket == false &&
        commandPacket.shouldReportRenderCommandPacketBlocked == false &&
        batchingPacket.shouldDeferRenderBatchingPacket == false &&
        batchingPacket.shouldReportRenderBatchingPacketBlocked == false
    let commandDeferred = batchingPacket.isRenderBatchingPacketReady == false &&
        commandPacket.isRenderCommandPacketReady == false &&
        commandPacket.didKeepCommandPacketRendererAgnostic &&
        commandPacket.didAvoidRenderSideEffect &&
        commandPacket.didPreserveRenderCommandList == false &&
        batchingPacket.didPreserveRenderBatchingPlan == false &&
        commandPacket.shouldDeferRenderCommandPacket &&
        batchingPacket.shouldDeferRenderBatchingPacket &&
        commandPacket.shouldReportRenderCommandPacketBlocked == false &&
        batchingPacket.shouldReportRenderBatchingPacketBlocked == false
    let commandInconsistent = (
        batchingPacket.isRenderBatchingPacketReady &&
            (
                commandPacket.isRenderCommandPacketReady == false ||
                commandPacket.didKeepCommandPacketRendererAgnostic == false ||
                commandPacket.didAvoidRenderSideEffect == false ||
                commandPacket.didPreserveRenderCommandList == false ||
                commandList.didUseFullRebuildCommandList == false ||
                commandList.didAvoidIncrementalCommandUpdate == false ||
                commandList.didAvoidRendererSubmission == false ||
                rootCommand.didPrepareRenderCommand == false ||
                rootCommand.didPreserveNodeFacts == false ||
                rootCommand.didAvoidActualDrawingOp == false ||
                rootCommand.nodeId.isStablePlaceholder == false ||
                rootCommand.bounds.didReserveStableBounds == false ||
                rootCommand.clip.didReserveClipFacts == false ||
                rootCommand.materialKey.didReserveMaterialFacts == false ||
                rootCommand.invalidationHint.requiresFullDisplayListRebuild == false ||
                rootCommand.invalidationHint.allowsIncrementalRebuild ||
                rootCommand.invalidationHint.allowsDisplayListMutation ||
                rootCommand.invalidationHint.allowsPartialRepaint ||
                rootCommand.invalidationHint.didReserveRepaintHint == false ||
                rootCommand.kind.isNodePlaceholder == false ||
                rootCommand.kind.isRealDrawingOp ||
                rootCommand.kind.didAvoidDrawCallBinding == false ||
                commandPacket.shouldDeferRenderCommandPacket ||
                commandPacket.shouldReportRenderCommandPacketBlocked ||
                batchingPacket.shouldDeferRenderBatchingPacket ||
                batchingPacket.shouldReportRenderBatchingPacketBlocked
            )
        ) ||
        (commandPacket.didPreserveRenderCommandList && commandPacket.isRenderCommandPacketReady == false) ||
        (batchingPacket.didPreserveRenderBatchingPlan && batchingPacket.isRenderBatchingPacketReady == false) ||
        (commandPacket.shouldDeferRenderCommandPacket && commandPacket.shouldReportRenderCommandPacketBlocked) ||
        (batchingPacket.shouldDeferRenderBatchingPacket && batchingPacket.shouldReportRenderBatchingPacketBlocked)

    // command / batching facts 不一致时必须 fail-closed，不能伪造 validation accepted。
    if (
        batchingPacket.shouldReportRenderBatchingPacketBlocked ||
        commandPacket.shouldReportRenderCommandPacketBlocked ||
        commandInconsistent
    ) {
        return CjguiInternalRendererCommandPacketValidation(
            batchingPacket,
            commandPacket,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true
        )
    }

    if (commandReady) {
        return CjguiInternalRendererCommandPacketValidation(
            batchingPacket,
            commandPacket,
            true,
            false,
            false,
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

    if (commandDeferred) {
        return CjguiInternalRendererCommandPacketValidation(
            batchingPacket,
            commandPacket,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererCommandPacketValidation(
        batchingPacket,
        commandPacket,
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererBatchingPacketIntegrity(
    commandValidation: CjguiInternalRendererCommandPacketValidation
): CjguiInternalRendererBatchingPacketIntegrity {
    let batchingPacket = commandValidation.batchingPacket
    let batchingPlan = batchingPacket.batchingPlan
    let materialHint = batchingPlan.materialHint
    let batchKey = batchingPlan.batchKey
    let orderingHint = batchingPlan.orderingHint
    let validationReady = commandValidation.didValidateRendererCommandPacket &&
        commandValidation.didPreserveRenderBatchingPacket &&
        commandValidation.didPreserveRenderCommandPacket &&
        commandValidation.didValidateFullRebuildOnly &&
        commandValidation.didValidatePlaceholderCommandKind &&
        commandValidation.didKeepValidationBackendAgnostic &&
        commandValidation.didAvoidRendererBackendShellTail &&
        commandValidation.didAvoidDrawingPermission &&
        commandValidation.shouldDeferRendererCommandPacketValidation == false &&
        commandValidation.shouldReportRendererCommandPacketValidationBlocked == false
    let integrityReady = validationReady &&
        batchingPacket.isRenderBatchingPacketReady &&
        batchingPacket.didKeepBatchingPacketRendererAgnostic &&
        batchingPacket.didAvoidRenderSideEffect &&
        batchingPacket.didAvoidCommandMerge &&
        batchingPacket.didPreserveRenderBatchingPlan &&
        batchingPlan.didPrepareRenderBatchingPlan &&
        batchingPlan.didUseFullRebuildBatchingPlan &&
        batchingPlan.didKeepPlanRendererAgnostic &&
        batchingPlan.didAvoidCommandMerge &&
        batchingPlan.didAvoidIncrementalBatchUpdate &&
        batchingPlan.didPreserveRenderCommandPacket &&
        materialHint.didKeepMaterialHintRendererAgnostic &&
        materialHint.didAvoidMaterialResourceBinding &&
        batchKey.didKeepBatchKeyAsHint &&
        batchKey.didAvoidPipelineBinding &&
        orderingHint.didPreserveCommandOrderingFacts &&
        orderingHint.didAvoidSortSideEffect &&
        batchingPacket.shouldDeferRenderBatchingPacket == false &&
        batchingPacket.shouldReportRenderBatchingPacketBlocked == false
    let integrityDeferred = commandValidation.didValidateRendererCommandPacket == false &&
        commandValidation.shouldDeferRendererCommandPacketValidation &&
        commandValidation.shouldReportRendererCommandPacketValidationBlocked == false
    let integrityInconsistent = (
        commandValidation.didValidateRendererCommandPacket &&
            (
                commandValidation.didPreserveRenderBatchingPacket == false ||
                commandValidation.didPreserveRenderCommandPacket == false ||
                commandValidation.didValidateFullRebuildOnly == false ||
                commandValidation.didValidatePlaceholderCommandKind == false ||
                commandValidation.didKeepValidationBackendAgnostic == false ||
                commandValidation.didAvoidRendererBackendShellTail == false ||
                commandValidation.didAvoidDrawingPermission == false ||
                commandValidation.shouldDeferRendererCommandPacketValidation ||
                commandValidation.shouldReportRendererCommandPacketValidationBlocked
            )
        ) ||
        (
            batchingPacket.isRenderBatchingPacketReady &&
                (
                    batchingPacket.didKeepBatchingPacketRendererAgnostic == false ||
                    batchingPacket.didAvoidRenderSideEffect == false ||
                    batchingPacket.didAvoidCommandMerge == false ||
                    batchingPacket.didPreserveRenderBatchingPlan == false ||
                    batchingPlan.didPrepareRenderBatchingPlan == false ||
                    batchingPlan.didUseFullRebuildBatchingPlan == false ||
                    batchingPlan.didKeepPlanRendererAgnostic == false ||
                    batchingPlan.didAvoidCommandMerge == false ||
                    batchingPlan.didAvoidIncrementalBatchUpdate == false ||
                    batchingPlan.didPreserveRenderCommandPacket == false ||
                    materialHint.didKeepMaterialHintRendererAgnostic == false ||
                    materialHint.didAvoidMaterialResourceBinding == false ||
                    batchKey.didKeepBatchKeyAsHint == false ||
                    batchKey.didAvoidPipelineBinding == false ||
                    orderingHint.didPreserveCommandOrderingFacts == false ||
                    orderingHint.didAvoidSortSideEffect == false ||
                    batchingPacket.shouldDeferRenderBatchingPacket ||
                    batchingPacket.shouldReportRenderBatchingPacketBlocked
                )
        ) ||
        (batchingPacket.shouldDeferRenderBatchingPacket && batchingPacket.shouldReportRenderBatchingPacketBlocked)

    // batching facts 不一致时必须 fail-closed；integrity 不能变成真实合批或绘制许可。
    if (
        batchingPacket.shouldReportRenderBatchingPacketBlocked ||
        commandValidation.shouldReportRendererCommandPacketValidationBlocked ||
        integrityInconsistent
    ) {
        return CjguiInternalRendererBatchingPacketIntegrity(
            commandValidation,
            false,
            false,
            true,
            false,
            true,
            true,
            true,
            true,
            false,
            true,
            true,
            true
        )
    }

    if (integrityReady) {
        return CjguiInternalRendererBatchingPacketIntegrity(
            commandValidation,
            true,
            false,
            false,
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

    if (integrityDeferred) {
        return CjguiInternalRendererBatchingPacketIntegrity(
            commandValidation,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererBatchingPacketIntegrity(
        commandValidation,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        true,
        false,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererCommandValidationAdmission(
    batchingIntegrity: CjguiInternalRendererBatchingPacketIntegrity
): CjguiInternalRendererCommandValidationAdmission {
    let integrityReady = batchingIntegrity.didValidateRendererBatchingPacketIntegrity &&
        batchingIntegrity.didPreserveRendererCommandPacketValidation &&
        batchingIntegrity.didValidateBatchKeyAsHint &&
        batchingIntegrity.didValidateOrderingHintValueOnly &&
        batchingIntegrity.didValidateBatchingPlanDehydrated &&
        batchingIntegrity.didValidateNoCommandMerge &&
        batchingIntegrity.didValidateFullRebuildBatching &&
        batchingIntegrity.didKeepIntegrityBackendAgnostic &&
        batchingIntegrity.didAvoidRealBatching &&
        batchingIntegrity.didAvoidDrawingPermission &&
        batchingIntegrity.shouldDeferRendererBatchingPacketIntegrity == false &&
        batchingIntegrity.shouldReportRendererBatchingPacketIntegrityBlocked == false
    let integrityDeferred = batchingIntegrity.didValidateRendererBatchingPacketIntegrity == false &&
        batchingIntegrity.didPreserveRendererCommandPacketValidation == false &&
        batchingIntegrity.shouldDeferRendererBatchingPacketIntegrity &&
        batchingIntegrity.shouldReportRendererBatchingPacketIntegrityBlocked == false
    let integrityInconsistent = (
        batchingIntegrity.didValidateRendererBatchingPacketIntegrity &&
            (
                batchingIntegrity.didPreserveRendererCommandPacketValidation == false ||
                batchingIntegrity.didValidateBatchKeyAsHint == false ||
                batchingIntegrity.didValidateOrderingHintValueOnly == false ||
                batchingIntegrity.didValidateBatchingPlanDehydrated == false ||
                batchingIntegrity.didValidateNoCommandMerge == false ||
                batchingIntegrity.didValidateFullRebuildBatching == false ||
                batchingIntegrity.didKeepIntegrityBackendAgnostic == false ||
                batchingIntegrity.didAvoidRealBatching == false ||
                batchingIntegrity.didAvoidDrawingPermission == false ||
                batchingIntegrity.shouldDeferRendererBatchingPacketIntegrity ||
                batchingIntegrity.shouldReportRendererBatchingPacketIntegrityBlocked
            )
        ) ||
        (batchingIntegrity.didPreserveRendererCommandPacketValidation &&
            batchingIntegrity.didValidateRendererBatchingPacketIntegrity == false) ||
        (batchingIntegrity.shouldDeferRendererBatchingPacketIntegrity &&
            batchingIntegrity.shouldReportRendererBatchingPacketIntegrityBlocked)

    // integrity facts 不一致时必须 fail-closed，admission 不能升级成后端准入。
    if (
        batchingIntegrity.shouldReportRendererBatchingPacketIntegrityBlocked ||
        integrityInconsistent
    ) {
        return CjguiInternalRendererCommandValidationAdmission(
            batchingIntegrity,
            false,
            false,
            true,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (integrityReady) {
        return CjguiInternalRendererCommandValidationAdmission(
            batchingIntegrity,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (integrityDeferred) {
        return CjguiInternalRendererCommandValidationAdmission(
            batchingIntegrity,
            false,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererCommandValidationAdmission(
        batchingIntegrity,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererCommandValidationResult(
    admission: CjguiInternalRendererCommandValidationAdmission
): CjguiInternalRendererCommandValidationResult {
    let admissionReady = admission.didAdmitRendererCommandValidation &&
        admission.didPreserveRendererBatchingPacketIntegrity &&
        admission.didKeepValidationAdmissionBackendAgnostic &&
        admission.didAvoidRendererBackendShellTail &&
        admission.didAvoidRendererBackendImplementation &&
        admission.didAvoidRendererStateWrite &&
        admission.didAvoidDrawingPermission &&
        admission.shouldDeferRendererCommandValidationAdmission == false &&
        admission.shouldReportRendererCommandValidationAdmissionBlocked == false
    let admissionDeferred = admission.didAdmitRendererCommandValidation == false &&
        admission.didPreserveRendererBatchingPacketIntegrity == false &&
        admission.didKeepValidationAdmissionBackendAgnostic &&
        admission.didAvoidRendererBackendShellTail &&
        admission.didAvoidRendererBackendImplementation &&
        admission.didAvoidRendererStateWrite &&
        admission.didAvoidDrawingPermission &&
        admission.shouldDeferRendererCommandValidationAdmission &&
        admission.shouldReportRendererCommandValidationAdmissionBlocked == false
    let admissionInconsistent = (
        admission.didAdmitRendererCommandValidation &&
            (
                admission.didPreserveRendererBatchingPacketIntegrity == false ||
                admission.didKeepValidationAdmissionBackendAgnostic == false ||
                admission.didAvoidRendererBackendShellTail == false ||
                admission.didAvoidRendererBackendImplementation == false ||
                admission.didAvoidRendererStateWrite == false ||
                admission.didAvoidDrawingPermission == false ||
                admission.shouldDeferRendererCommandValidationAdmission ||
                admission.shouldReportRendererCommandValidationAdmissionBlocked
            )
        ) ||
        (admission.didPreserveRendererBatchingPacketIntegrity &&
            admission.didAdmitRendererCommandValidation == false) ||
        (admission.shouldDeferRendererCommandValidationAdmission &&
            admission.shouldReportRendererCommandValidationAdmissionBlocked)

    // admission facts 不一致时必须 fail-closed，result 不代表绘制或后端许可。
    if (
        admission.shouldReportRendererCommandValidationAdmissionBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalRendererCommandValidationResult(
            admission,
            false,
            false,
            false,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (admissionReady) {
        return CjguiInternalRendererCommandValidationResult(
            admission,
            true,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true,
            true
        )
    }

    if (admissionDeferred) {
        return CjguiInternalRendererCommandValidationResult(
            admission,
            false,
            false,
            true,
            false,
            false,
            false,
            true,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererCommandValidationResult(
        admission,
        false,
        false,
        false,
        true,
        false,
        false,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererCommandValidationDraft(): CjguiInternalRendererCommandValidationResult {
    // 默认 validation draft 只串联 batching packet -> command integrity -> validation result；
    // 它校验脱水 value facts，不触发绘制、不进入平台后端，也不继续 shell tail 自包。
    let batchingPacket = cjguiInternalExecuteDefaultRenderBatchingHintDraft()
    let commandValidation = cjguiInternalBuildRendererCommandPacketValidation(batchingPacket)
    let batchingIntegrity = cjguiInternalBuildRendererBatchingPacketIntegrity(commandValidation)
    let admission = cjguiInternalBuildRendererCommandValidationAdmission(batchingIntegrity)
    return cjguiInternalBuildRendererCommandValidationResult(admission)
}

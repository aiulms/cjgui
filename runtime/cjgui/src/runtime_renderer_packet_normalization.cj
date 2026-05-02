package cjgui

// Owner: Renderer packet normalization boundary.
// Truth: 只消费 command validation result，产出 backend-agnostic normalization value facts。
// Stop-line: 不进入平台后端、不持有平台资源、不触发绘制执行、不写 renderer state。
// Same-shape Boundary Brake: 本 owner 新增 normalization vocabulary / ordering facts /
// material grouping facts，不新增 receipt / record / publication 形态的薄尾巴。

// Normalized packet candidate 只描述已验证 packet 的规范化候选形态；
// 它不是后端包，也不是后续绘制许可。
struct CjguiInternalRendererNormalizedPacketCandidate {
    let validationResult: CjguiInternalRendererCommandValidationResult
    let commandPacket: CjguiInternalRenderCommandPacket
    let batchingPacket: CjguiInternalRenderBatchingPacket
    let didPrepareRendererNormalizedPacketCandidate: Bool
    let shouldDeferRendererNormalizedPacketCandidate: Bool
    let shouldReportRendererNormalizedPacketCandidateBlocked: Bool
    let didPreserveRendererCommandValidationResult: Bool
    let didDescribeNormalizedPacketShape: Bool
    let didPreserveStablePacketFacts: Bool
    let didKeepNormalizedPacketBackendAgnostic: Bool
    let didAvoidBackendPacketShape: Bool
    let didAvoidRendererStateWrite: Bool
    let didStayFullRebuildOnly: Bool

    init(
        validationResult: CjguiInternalRendererCommandValidationResult,
        commandPacket: CjguiInternalRenderCommandPacket,
        batchingPacket: CjguiInternalRenderBatchingPacket,
        didPrepareRendererNormalizedPacketCandidate: Bool,
        shouldDeferRendererNormalizedPacketCandidate: Bool,
        shouldReportRendererNormalizedPacketCandidateBlocked: Bool,
        didPreserveRendererCommandValidationResult: Bool,
        didDescribeNormalizedPacketShape: Bool,
        didPreserveStablePacketFacts: Bool,
        didKeepNormalizedPacketBackendAgnostic: Bool,
        didAvoidBackendPacketShape: Bool,
        didAvoidRendererStateWrite: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.validationResult = validationResult
        this.commandPacket = commandPacket
        this.batchingPacket = batchingPacket
        this.didPrepareRendererNormalizedPacketCandidate = didPrepareRendererNormalizedPacketCandidate
        this.shouldDeferRendererNormalizedPacketCandidate = shouldDeferRendererNormalizedPacketCandidate
        this.shouldReportRendererNormalizedPacketCandidateBlocked =
            shouldReportRendererNormalizedPacketCandidateBlocked
        this.didPreserveRendererCommandValidationResult = didPreserveRendererCommandValidationResult
        this.didDescribeNormalizedPacketShape = didDescribeNormalizedPacketShape
        this.didPreserveStablePacketFacts = didPreserveStablePacketFacts
        this.didKeepNormalizedPacketBackendAgnostic = didKeepNormalizedPacketBackendAgnostic
        this.didAvoidBackendPacketShape = didAvoidBackendPacketShape
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Normalized ordering facts 只说明排序相关 facts 已被规范化描述；
// 它不执行真实排序副作用，也不重排任何队列。
struct CjguiInternalRendererNormalizedOrderingFacts {
    let normalizedPacketCandidate: CjguiInternalRendererNormalizedPacketCandidate
    let didPrepareRendererNormalizedOrderingFacts: Bool
    let shouldDeferRendererNormalizedOrderingFacts: Bool
    let shouldReportRendererNormalizedOrderingFactsBlocked: Bool
    let didPreserveNormalizedPacketCandidate: Bool
    let didDescribeExistingPacketOrder: Bool
    let didAvoidSortSideEffect: Bool
    let didKeepOrderingFactsValueOnly: Bool
    let didStayFullRebuildOnly: Bool

    init(
        normalizedPacketCandidate: CjguiInternalRendererNormalizedPacketCandidate,
        didPrepareRendererNormalizedOrderingFacts: Bool,
        shouldDeferRendererNormalizedOrderingFacts: Bool,
        shouldReportRendererNormalizedOrderingFactsBlocked: Bool,
        didPreserveNormalizedPacketCandidate: Bool,
        didDescribeExistingPacketOrder: Bool,
        didAvoidSortSideEffect: Bool,
        didKeepOrderingFactsValueOnly: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.normalizedPacketCandidate = normalizedPacketCandidate
        this.didPrepareRendererNormalizedOrderingFacts = didPrepareRendererNormalizedOrderingFacts
        this.shouldDeferRendererNormalizedOrderingFacts = shouldDeferRendererNormalizedOrderingFacts
        this.shouldReportRendererNormalizedOrderingFactsBlocked =
            shouldReportRendererNormalizedOrderingFactsBlocked
        this.didPreserveNormalizedPacketCandidate = didPreserveNormalizedPacketCandidate
        this.didDescribeExistingPacketOrder = didDescribeExistingPacketOrder
        this.didAvoidSortSideEffect = didAvoidSortSideEffect
        this.didKeepOrderingFactsValueOnly = didKeepOrderingFactsValueOnly
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Normalized material grouping facts 只表达 backend-agnostic grouping hints；
// 它不做真实绘制合并，也不升级为图形合批。
struct CjguiInternalRendererNormalizedMaterialGroupingFacts {
    let normalizedOrderingFacts: CjguiInternalRendererNormalizedOrderingFacts
    let didPrepareRendererNormalizedMaterialGroupingFacts: Bool
    let shouldDeferRendererNormalizedMaterialGroupingFacts: Bool
    let shouldReportRendererNormalizedMaterialGroupingFactsBlocked: Bool
    let didPreserveNormalizedOrderingFacts: Bool
    let didDescribeMaterialGroupingHints: Bool
    let didPreserveBatchKeyHint: Bool
    let didAvoidCommandMerge: Bool
    let didAvoidRealBatching: Bool
    let didKeepGroupingFactsBackendAgnostic: Bool
    let didStayFullRebuildOnly: Bool

    init(
        normalizedOrderingFacts: CjguiInternalRendererNormalizedOrderingFacts,
        didPrepareRendererNormalizedMaterialGroupingFacts: Bool,
        shouldDeferRendererNormalizedMaterialGroupingFacts: Bool,
        shouldReportRendererNormalizedMaterialGroupingFactsBlocked: Bool,
        didPreserveNormalizedOrderingFacts: Bool,
        didDescribeMaterialGroupingHints: Bool,
        didPreserveBatchKeyHint: Bool,
        didAvoidCommandMerge: Bool,
        didAvoidRealBatching: Bool,
        didKeepGroupingFactsBackendAgnostic: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.normalizedOrderingFacts = normalizedOrderingFacts
        this.didPrepareRendererNormalizedMaterialGroupingFacts =
            didPrepareRendererNormalizedMaterialGroupingFacts
        this.shouldDeferRendererNormalizedMaterialGroupingFacts =
            shouldDeferRendererNormalizedMaterialGroupingFacts
        this.shouldReportRendererNormalizedMaterialGroupingFactsBlocked =
            shouldReportRendererNormalizedMaterialGroupingFactsBlocked
        this.didPreserveNormalizedOrderingFacts = didPreserveNormalizedOrderingFacts
        this.didDescribeMaterialGroupingHints = didDescribeMaterialGroupingHints
        this.didPreserveBatchKeyHint = didPreserveBatchKeyHint
        this.didAvoidCommandMerge = didAvoidCommandMerge
        this.didAvoidRealBatching = didAvoidRealBatching
        this.didKeepGroupingFactsBackendAgnostic = didKeepGroupingFactsBackendAgnostic
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Normalization result 是 packet normalization 的 canonical endpoint；
// 它只表示内部 value facts，不代表后端许可、绘制许可或 renderer state readiness。
struct CjguiInternalRendererPacketNormalizationResult {
    let materialGroupingFacts: CjguiInternalRendererNormalizedMaterialGroupingFacts
    let isRendererPacketNormalizationAccepted: Bool
    let canFutureRendererBoundaryUseNormalizedPacket: Bool
    let shouldDeferRendererPacketNormalizationResult: Bool
    let shouldReportRendererPacketNormalizationResultBlocked: Bool
    let didRecordRendererPacketNormalizationResult: Bool
    let didPreserveNormalizedMaterialGroupingFacts: Bool
    let didKeepNormalizationResultBackendAgnostic: Bool
    let didAvoidBackendPacketShape: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didAvoidSortSideEffect: Bool
    let didStayFullRebuildOnly: Bool

    init(
        materialGroupingFacts: CjguiInternalRendererNormalizedMaterialGroupingFacts,
        isRendererPacketNormalizationAccepted: Bool,
        canFutureRendererBoundaryUseNormalizedPacket: Bool,
        shouldDeferRendererPacketNormalizationResult: Bool,
        shouldReportRendererPacketNormalizationResultBlocked: Bool,
        didRecordRendererPacketNormalizationResult: Bool,
        didPreserveNormalizedMaterialGroupingFacts: Bool,
        didKeepNormalizationResultBackendAgnostic: Bool,
        didAvoidBackendPacketShape: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didAvoidSortSideEffect: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.materialGroupingFacts = materialGroupingFacts
        this.isRendererPacketNormalizationAccepted = isRendererPacketNormalizationAccepted
        this.canFutureRendererBoundaryUseNormalizedPacket = canFutureRendererBoundaryUseNormalizedPacket
        this.shouldDeferRendererPacketNormalizationResult = shouldDeferRendererPacketNormalizationResult
        this.shouldReportRendererPacketNormalizationResultBlocked =
            shouldReportRendererPacketNormalizationResultBlocked
        this.didRecordRendererPacketNormalizationResult = didRecordRendererPacketNormalizationResult
        this.didPreserveNormalizedMaterialGroupingFacts = didPreserveNormalizedMaterialGroupingFacts
        this.didKeepNormalizationResultBackendAgnostic = didKeepNormalizationResultBackendAgnostic
        this.didAvoidBackendPacketShape = didAvoidBackendPacketShape
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didAvoidSortSideEffect = didAvoidSortSideEffect
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererNormalizedPacketCandidate(
    validationResult: CjguiInternalRendererCommandValidationResult
): CjguiInternalRendererNormalizedPacketCandidate {
    let admission = validationResult.admission
    let batchingIntegrity = admission.batchingIntegrity
    let commandValidation = batchingIntegrity.commandValidation
    let commandPacket = commandValidation.commandPacket
    let batchingPacket = commandValidation.batchingPacket
    let batchingPlan = batchingPacket.batchingPlan
    let rootCommand = commandPacket.commandList.rootCommand
    let validationReady = validationResult.isRendererCommandValidationAccepted &&
        validationResult.canFutureRendererBoundaryUseValidatedPacket &&
        validationResult.didRecordRendererCommandValidationResult &&
        validationResult.didPreserveRendererCommandValidationAdmission &&
        validationResult.didKeepValidationResultBackendAgnostic &&
        validationResult.didAvoidRendererBackendShellTail &&
        validationResult.didAvoidRendererBackendImplementation &&
        validationResult.didAvoidRendererStateWrite &&
        validationResult.didAvoidDrawingPermission &&
        validationResult.shouldDeferRendererCommandValidationResult == false &&
        validationResult.shouldReportRendererCommandValidationResultBlocked == false
    let packetReady = validationReady &&
        commandPacket.isRenderCommandPacketReady &&
        commandPacket.didKeepCommandPacketRendererAgnostic &&
        commandPacket.didAvoidRenderSideEffect &&
        commandPacket.didPreserveRenderCommandList &&
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
        rootCommand.didPreserveNodeFacts &&
        rootCommand.kind.isRealDrawingOp == false &&
        rootCommand.kind.didAvoidDrawCallBinding &&
        rootCommand.invalidationHint.requiresFullDisplayListRebuild &&
        rootCommand.invalidationHint.allowsIncrementalRebuild == false &&
        rootCommand.invalidationHint.allowsDisplayListMutation == false &&
        rootCommand.invalidationHint.allowsPartialRepaint == false &&
        commandPacket.shouldDeferRenderCommandPacket == false &&
        commandPacket.shouldReportRenderCommandPacketBlocked == false &&
        batchingPacket.shouldDeferRenderBatchingPacket == false &&
        batchingPacket.shouldReportRenderBatchingPacketBlocked == false
    let packetDeferred = validationResult.isRendererCommandValidationAccepted == false &&
        validationResult.canFutureRendererBoundaryUseValidatedPacket == false &&
        validationResult.didKeepValidationResultBackendAgnostic &&
        validationResult.didAvoidRendererBackendImplementation &&
        validationResult.didAvoidRendererStateWrite &&
        validationResult.didAvoidDrawingPermission &&
        validationResult.shouldDeferRendererCommandValidationResult &&
        validationResult.shouldReportRendererCommandValidationResultBlocked == false
    let packetInconsistent = (
        validationResult.isRendererCommandValidationAccepted &&
            (
                validationResult.canFutureRendererBoundaryUseValidatedPacket == false ||
                validationResult.didRecordRendererCommandValidationResult == false ||
                validationResult.didPreserveRendererCommandValidationAdmission == false ||
                validationResult.didKeepValidationResultBackendAgnostic == false ||
                validationResult.didAvoidRendererBackendImplementation == false ||
                validationResult.didAvoidRendererStateWrite == false ||
                validationResult.didAvoidDrawingPermission == false ||
                validationResult.shouldDeferRendererCommandValidationResult ||
                validationResult.shouldReportRendererCommandValidationResultBlocked
            )
        ) ||
        (
            commandPacket.isRenderCommandPacketReady &&
                (
                    commandPacket.didKeepCommandPacketRendererAgnostic == false ||
                    commandPacket.didAvoidRenderSideEffect == false ||
                    commandPacket.didPreserveRenderCommandList == false ||
                    rootCommand.didPreserveNodeFacts == false ||
                    rootCommand.kind.isRealDrawingOp ||
                    rootCommand.kind.didAvoidDrawCallBinding == false ||
                    rootCommand.invalidationHint.requiresFullDisplayListRebuild == false ||
                    rootCommand.invalidationHint.allowsIncrementalRebuild ||
                    rootCommand.invalidationHint.allowsDisplayListMutation ||
                    rootCommand.invalidationHint.allowsPartialRepaint ||
                    commandPacket.shouldDeferRenderCommandPacket ||
                    commandPacket.shouldReportRenderCommandPacketBlocked
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
                    batchingPacket.shouldDeferRenderBatchingPacket ||
                    batchingPacket.shouldReportRenderBatchingPacketBlocked
                )
        ) ||
        (validationResult.shouldDeferRendererCommandValidationResult &&
            validationResult.shouldReportRendererCommandValidationResultBlocked) ||
        (commandPacket.shouldDeferRenderCommandPacket && commandPacket.shouldReportRenderCommandPacketBlocked) ||
        (batchingPacket.shouldDeferRenderBatchingPacket && batchingPacket.shouldReportRenderBatchingPacketBlocked)

    // validation / packet facts 不一致时必须 fail-closed，不能伪造成 normalized packet 可用。
    if (
        validationResult.shouldReportRendererCommandValidationResultBlocked ||
        commandPacket.shouldReportRenderCommandPacketBlocked ||
        batchingPacket.shouldReportRenderBatchingPacketBlocked ||
        packetInconsistent
    ) {
        return CjguiInternalRendererNormalizedPacketCandidate(
            validationResult,
            commandPacket,
            batchingPacket,
            false,
            false,
            true,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (packetReady) {
        return CjguiInternalRendererNormalizedPacketCandidate(
            validationResult,
            commandPacket,
            batchingPacket,
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

    if (packetDeferred) {
        return CjguiInternalRendererNormalizedPacketCandidate(
            validationResult,
            commandPacket,
            batchingPacket,
            false,
            true,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererNormalizedPacketCandidate(
        validationResult,
        commandPacket,
        batchingPacket,
        false,
        false,
        true,
        false,
        false,
        false,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNormalizedOrderingFacts(
    normalizedPacketCandidate: CjguiInternalRendererNormalizedPacketCandidate
): CjguiInternalRendererNormalizedOrderingFacts {
    let batchingPlan = normalizedPacketCandidate.batchingPacket.batchingPlan
    let orderingHint = batchingPlan.orderingHint
    let candidateReady = normalizedPacketCandidate.didPrepareRendererNormalizedPacketCandidate &&
        normalizedPacketCandidate.didPreserveRendererCommandValidationResult &&
        normalizedPacketCandidate.didDescribeNormalizedPacketShape &&
        normalizedPacketCandidate.didPreserveStablePacketFacts &&
        normalizedPacketCandidate.didKeepNormalizedPacketBackendAgnostic &&
        normalizedPacketCandidate.didAvoidBackendPacketShape &&
        normalizedPacketCandidate.didAvoidRendererStateWrite &&
        normalizedPacketCandidate.didStayFullRebuildOnly &&
        normalizedPacketCandidate.shouldDeferRendererNormalizedPacketCandidate == false &&
        normalizedPacketCandidate.shouldReportRendererNormalizedPacketCandidateBlocked == false
    let orderingReady = candidateReady &&
        orderingHint.didPrepareRenderOrderingHint &&
        orderingHint.didPreserveCommandOrderingFacts &&
        orderingHint.didAvoidSortSideEffect &&
        orderingHint.didPreserveRenderBatchKey &&
        batchingPlan.didUseFullRebuildBatchingPlan &&
        batchingPlan.didAvoidIncrementalBatchUpdate &&
        orderingHint.shouldDeferRenderOrderingHint == false &&
        orderingHint.shouldReportRenderOrderingHintBlocked == false
    let orderingDeferred = normalizedPacketCandidate.didPrepareRendererNormalizedPacketCandidate == false &&
        normalizedPacketCandidate.shouldDeferRendererNormalizedPacketCandidate &&
        normalizedPacketCandidate.shouldReportRendererNormalizedPacketCandidateBlocked == false
    let orderingInconsistent = (
        normalizedPacketCandidate.didPrepareRendererNormalizedPacketCandidate &&
            (
                normalizedPacketCandidate.didPreserveRendererCommandValidationResult == false ||
                normalizedPacketCandidate.didDescribeNormalizedPacketShape == false ||
                normalizedPacketCandidate.didPreserveStablePacketFacts == false ||
                normalizedPacketCandidate.didKeepNormalizedPacketBackendAgnostic == false ||
                normalizedPacketCandidate.didAvoidBackendPacketShape == false ||
                normalizedPacketCandidate.didAvoidRendererStateWrite == false ||
                normalizedPacketCandidate.didStayFullRebuildOnly == false ||
                normalizedPacketCandidate.shouldDeferRendererNormalizedPacketCandidate ||
                normalizedPacketCandidate.shouldReportRendererNormalizedPacketCandidateBlocked
            )
        ) ||
        (
            orderingHint.didPrepareRenderOrderingHint &&
                (
                    orderingHint.didPreserveCommandOrderingFacts == false ||
                    orderingHint.didAvoidSortSideEffect == false ||
                    orderingHint.didPreserveRenderBatchKey == false ||
                    batchingPlan.didUseFullRebuildBatchingPlan == false ||
                    batchingPlan.didAvoidIncrementalBatchUpdate == false ||
                    orderingHint.shouldDeferRenderOrderingHint ||
                    orderingHint.shouldReportRenderOrderingHintBlocked
                )
        ) ||
        (normalizedPacketCandidate.shouldDeferRendererNormalizedPacketCandidate &&
            normalizedPacketCandidate.shouldReportRendererNormalizedPacketCandidateBlocked) ||
        (orderingHint.shouldDeferRenderOrderingHint && orderingHint.shouldReportRenderOrderingHintBlocked)

    // ordering facts 不一致时必须 fail-closed；normalization 不执行真实排序副作用。
    if (
        normalizedPacketCandidate.shouldReportRendererNormalizedPacketCandidateBlocked ||
        orderingHint.shouldReportRenderOrderingHintBlocked ||
        orderingInconsistent
    ) {
        return CjguiInternalRendererNormalizedOrderingFacts(
            normalizedPacketCandidate,
            false,
            false,
            true,
            false,
            false,
            true,
            true,
            true
        )
    }

    if (orderingReady) {
        return CjguiInternalRendererNormalizedOrderingFacts(
            normalizedPacketCandidate,
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

    if (orderingDeferred) {
        return CjguiInternalRendererNormalizedOrderingFacts(
            normalizedPacketCandidate,
            false,
            true,
            false,
            false,
            false,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererNormalizedOrderingFacts(
        normalizedPacketCandidate,
        false,
        false,
        true,
        false,
        false,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNormalizedMaterialGroupingFacts(
    normalizedOrderingFacts: CjguiInternalRendererNormalizedOrderingFacts
): CjguiInternalRendererNormalizedMaterialGroupingFacts {
    let candidate = normalizedOrderingFacts.normalizedPacketCandidate
    let batchingPlan = candidate.batchingPacket.batchingPlan
    let materialHint = batchingPlan.materialHint
    let batchKey = batchingPlan.batchKey
    let orderingReady = normalizedOrderingFacts.didPrepareRendererNormalizedOrderingFacts &&
        normalizedOrderingFacts.didPreserveNormalizedPacketCandidate &&
        normalizedOrderingFacts.didDescribeExistingPacketOrder &&
        normalizedOrderingFacts.didAvoidSortSideEffect &&
        normalizedOrderingFacts.didKeepOrderingFactsValueOnly &&
        normalizedOrderingFacts.didStayFullRebuildOnly &&
        normalizedOrderingFacts.shouldDeferRendererNormalizedOrderingFacts == false &&
        normalizedOrderingFacts.shouldReportRendererNormalizedOrderingFactsBlocked == false
    let groupingReady = orderingReady &&
        materialHint.didPrepareRenderMaterialHint &&
        materialHint.didKeepMaterialHintRendererAgnostic &&
        materialHint.didAvoidMaterialResourceBinding &&
        materialHint.didPreserveRenderCommandPacket &&
        batchKey.didPrepareRenderBatchKey &&
        batchKey.didKeepBatchKeyAsHint &&
        batchKey.didAvoidPipelineBinding &&
        batchKey.didPreserveMaterialHint &&
        batchingPlan.didPrepareRenderBatchingPlan &&
        batchingPlan.didKeepPlanRendererAgnostic &&
        batchingPlan.didAvoidCommandMerge &&
        batchingPlan.didAvoidIncrementalBatchUpdate &&
        batchingPlan.didUseFullRebuildBatchingPlan &&
        materialHint.shouldDeferRenderMaterialHint == false &&
        materialHint.shouldReportRenderMaterialHintBlocked == false &&
        batchKey.shouldDeferRenderBatchKey == false &&
        batchKey.shouldReportRenderBatchKeyBlocked == false
    let groupingDeferred = normalizedOrderingFacts.didPrepareRendererNormalizedOrderingFacts == false &&
        normalizedOrderingFacts.shouldDeferRendererNormalizedOrderingFacts &&
        normalizedOrderingFacts.shouldReportRendererNormalizedOrderingFactsBlocked == false
    let groupingInconsistent = (
        normalizedOrderingFacts.didPrepareRendererNormalizedOrderingFacts &&
            (
                normalizedOrderingFacts.didPreserveNormalizedPacketCandidate == false ||
                normalizedOrderingFacts.didDescribeExistingPacketOrder == false ||
                normalizedOrderingFacts.didAvoidSortSideEffect == false ||
                normalizedOrderingFacts.didKeepOrderingFactsValueOnly == false ||
                normalizedOrderingFacts.didStayFullRebuildOnly == false ||
                normalizedOrderingFacts.shouldDeferRendererNormalizedOrderingFacts ||
                normalizedOrderingFacts.shouldReportRendererNormalizedOrderingFactsBlocked
            )
        ) ||
        (
            materialHint.didPrepareRenderMaterialHint &&
                (
                    materialHint.didKeepMaterialHintRendererAgnostic == false ||
                    materialHint.didAvoidMaterialResourceBinding == false ||
                    materialHint.didPreserveRenderCommandPacket == false ||
                    materialHint.shouldDeferRenderMaterialHint ||
                    materialHint.shouldReportRenderMaterialHintBlocked
                )
        ) ||
        (
            batchKey.didPrepareRenderBatchKey &&
                (
                    batchKey.didKeepBatchKeyAsHint == false ||
                    batchKey.didAvoidPipelineBinding == false ||
                    batchKey.didPreserveMaterialHint == false ||
                    batchKey.shouldDeferRenderBatchKey ||
                    batchKey.shouldReportRenderBatchKeyBlocked
                )
        ) ||
        (
            batchingPlan.didPrepareRenderBatchingPlan &&
                (
                    batchingPlan.didKeepPlanRendererAgnostic == false ||
                    batchingPlan.didAvoidCommandMerge == false ||
                    batchingPlan.didAvoidIncrementalBatchUpdate == false ||
                    batchingPlan.didUseFullRebuildBatchingPlan == false ||
                    batchingPlan.shouldDeferRenderBatchingPlan ||
                    batchingPlan.shouldReportRenderBatchingPlanBlocked
                )
        ) ||
        (normalizedOrderingFacts.shouldDeferRendererNormalizedOrderingFacts &&
            normalizedOrderingFacts.shouldReportRendererNormalizedOrderingFactsBlocked) ||
        (materialHint.shouldDeferRenderMaterialHint && materialHint.shouldReportRenderMaterialHintBlocked) ||
        (batchKey.shouldDeferRenderBatchKey && batchKey.shouldReportRenderBatchKeyBlocked) ||
        (batchingPlan.shouldDeferRenderBatchingPlan && batchingPlan.shouldReportRenderBatchingPlanBlocked)

    // material grouping facts 不一致时必须 fail-closed，不能伪造成真实绘制合并。
    if (
        normalizedOrderingFacts.shouldReportRendererNormalizedOrderingFactsBlocked ||
        materialHint.shouldReportRenderMaterialHintBlocked ||
        batchKey.shouldReportRenderBatchKeyBlocked ||
        batchingPlan.shouldReportRenderBatchingPlanBlocked ||
        groupingInconsistent
    ) {
        return CjguiInternalRendererNormalizedMaterialGroupingFacts(
            normalizedOrderingFacts,
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

    if (groupingReady) {
        return CjguiInternalRendererNormalizedMaterialGroupingFacts(
            normalizedOrderingFacts,
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

    if (groupingDeferred) {
        return CjguiInternalRendererNormalizedMaterialGroupingFacts(
            normalizedOrderingFacts,
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

    return CjguiInternalRendererNormalizedMaterialGroupingFacts(
        normalizedOrderingFacts,
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

func cjguiInternalBuildRendererPacketNormalizationResult(
    materialGroupingFacts: CjguiInternalRendererNormalizedMaterialGroupingFacts
): CjguiInternalRendererPacketNormalizationResult {
    let groupingReady = materialGroupingFacts.didPrepareRendererNormalizedMaterialGroupingFacts &&
        materialGroupingFacts.didPreserveNormalizedOrderingFacts &&
        materialGroupingFacts.didDescribeMaterialGroupingHints &&
        materialGroupingFacts.didPreserveBatchKeyHint &&
        materialGroupingFacts.didAvoidCommandMerge &&
        materialGroupingFacts.didAvoidRealBatching &&
        materialGroupingFacts.didKeepGroupingFactsBackendAgnostic &&
        materialGroupingFacts.didStayFullRebuildOnly &&
        materialGroupingFacts.shouldDeferRendererNormalizedMaterialGroupingFacts == false &&
        materialGroupingFacts.shouldReportRendererNormalizedMaterialGroupingFactsBlocked == false
    let groupingDeferred = materialGroupingFacts.didPrepareRendererNormalizedMaterialGroupingFacts == false &&
        materialGroupingFacts.didPreserveNormalizedOrderingFacts == false &&
        materialGroupingFacts.shouldDeferRendererNormalizedMaterialGroupingFacts &&
        materialGroupingFacts.shouldReportRendererNormalizedMaterialGroupingFactsBlocked == false
    let groupingInconsistent = (
        materialGroupingFacts.didPrepareRendererNormalizedMaterialGroupingFacts &&
            (
                materialGroupingFacts.didPreserveNormalizedOrderingFacts == false ||
                materialGroupingFacts.didDescribeMaterialGroupingHints == false ||
                materialGroupingFacts.didPreserveBatchKeyHint == false ||
                materialGroupingFacts.didAvoidCommandMerge == false ||
                materialGroupingFacts.didAvoidRealBatching == false ||
                materialGroupingFacts.didKeepGroupingFactsBackendAgnostic == false ||
                materialGroupingFacts.didStayFullRebuildOnly == false ||
                materialGroupingFacts.shouldDeferRendererNormalizedMaterialGroupingFacts ||
                materialGroupingFacts.shouldReportRendererNormalizedMaterialGroupingFactsBlocked
            )
        ) ||
        (materialGroupingFacts.didPreserveNormalizedOrderingFacts &&
            materialGroupingFacts.didPrepareRendererNormalizedMaterialGroupingFacts == false) ||
        (materialGroupingFacts.shouldDeferRendererNormalizedMaterialGroupingFacts &&
            materialGroupingFacts.shouldReportRendererNormalizedMaterialGroupingFactsBlocked)

    // normalization facts 不一致时必须 fail-closed，result 不能代表绘制或后端许可。
    if (
        materialGroupingFacts.shouldReportRendererNormalizedMaterialGroupingFactsBlocked ||
        groupingInconsistent
    ) {
        return CjguiInternalRendererPacketNormalizationResult(
            materialGroupingFacts,
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
            true,
            true
        )
    }

    if (groupingReady) {
        return CjguiInternalRendererPacketNormalizationResult(
            materialGroupingFacts,
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
            true,
            true
        )
    }

    if (groupingDeferred) {
        return CjguiInternalRendererPacketNormalizationResult(
            materialGroupingFacts,
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
            true,
            true
        )
    }

    return CjguiInternalRendererPacketNormalizationResult(
        materialGroupingFacts,
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
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererPacketNormalizationDraft(
): CjguiInternalRendererPacketNormalizationResult {
    // 默认 normalization draft 只串联 validation result -> normalized packet / ordering / grouping facts；
    // 它生成脱水 value facts，不触发绘制、不执行排序副作用，也不做真实合批。
    let validationResult = cjguiInternalExecuteDefaultRendererCommandValidationDraft()
    let candidate = cjguiInternalBuildRendererNormalizedPacketCandidate(validationResult)
    let orderingFacts = cjguiInternalBuildRendererNormalizedOrderingFacts(candidate)
    let groupingFacts = cjguiInternalBuildRendererNormalizedMaterialGroupingFacts(orderingFacts)
    return cjguiInternalBuildRendererPacketNormalizationResult(groupingFacts)
}

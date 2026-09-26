package cjgui

// Owner: Renderer packet ordering / material grouping hardening boundary.
// Truth: 只消费 CjguiInternalRendererPacketNormalizationResult，补强 ordering basis、
// grouping scope、hint preservation 与 no-sort-no-merge gate 的内部 value facts。
// Stop-line: 本文件不触发渲染、不改 packet、不排序、不合并、不写 renderer state。
// Same-shape Boundary Brake: 本 owner 新增 ordering / grouping hardening 语义，
// 不把 normalization result 薄包成下一层尾巴。

// Ordering basis 只说明 normalized ordering facts 的 value basis；
// 它不执行真实排序副作用，也不重排任何 packet。
struct CjguiInternalRendererPacketOrderingBasis {
    let normalizationResult: CjguiInternalRendererPacketNormalizationResult
    let orderingHint: CjguiInternalRenderOrderingHint
    let didPrepareRendererPacketOrderingBasis: Bool
    let shouldDeferRendererPacketOrderingBasis: Bool
    let shouldReportRendererPacketOrderingBasisBlocked: Bool
    let didPreserveRendererPacketNormalizationResult: Bool
    let didPreserveRenderOrderingHint: Bool
    let didDescribeRendererOrderingBasis: Bool
    let didKeepOrderingBasisValueOnly: Bool
    let didAvoidSortSideEffect: Bool
    let didAvoidPacketMutation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        normalizationResult: CjguiInternalRendererPacketNormalizationResult,
        orderingHint: CjguiInternalRenderOrderingHint,
        didPrepareRendererPacketOrderingBasis: Bool,
        shouldDeferRendererPacketOrderingBasis: Bool,
        shouldReportRendererPacketOrderingBasisBlocked: Bool,
        didPreserveRendererPacketNormalizationResult: Bool,
        didPreserveRenderOrderingHint: Bool,
        didDescribeRendererOrderingBasis: Bool,
        didKeepOrderingBasisValueOnly: Bool,
        didAvoidSortSideEffect: Bool,
        didAvoidPacketMutation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.normalizationResult = normalizationResult
        this.orderingHint = orderingHint
        this.didPrepareRendererPacketOrderingBasis = didPrepareRendererPacketOrderingBasis
        this.shouldDeferRendererPacketOrderingBasis = shouldDeferRendererPacketOrderingBasis
        this.shouldReportRendererPacketOrderingBasisBlocked =
            shouldReportRendererPacketOrderingBasisBlocked
        this.didPreserveRendererPacketNormalizationResult = didPreserveRendererPacketNormalizationResult
        this.didPreserveRenderOrderingHint = didPreserveRenderOrderingHint
        this.didDescribeRendererOrderingBasis = didDescribeRendererOrderingBasis
        this.didKeepOrderingBasisValueOnly = didKeepOrderingBasisValueOnly
        this.didAvoidSortSideEffect = didAvoidSortSideEffect
        this.didAvoidPacketMutation = didAvoidPacketMutation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Material grouping scope 只说明 material / batch hint 的 value scope；
// 它不做真实绘制合并，也不升级为外部合批行为。
struct CjguiInternalRendererMaterialGroupingScope {
    let orderingBasis: CjguiInternalRendererPacketOrderingBasis
    let materialHint: CjguiInternalRenderMaterialHint
    let batchKey: CjguiInternalRenderBatchKey
    let didPrepareRendererMaterialGroupingScope: Bool
    let shouldDeferRendererMaterialGroupingScope: Bool
    let shouldReportRendererMaterialGroupingScopeBlocked: Bool
    let didPreserveRendererPacketOrderingBasis: Bool
    let didPreserveRenderMaterialHint: Bool
    let didPreserveRenderBatchKey: Bool
    let didDescribeRendererMaterialGroupingScope: Bool
    let didKeepGroupingScopeValueOnly: Bool
    let didAvoidCommandMerge: Bool
    let didAvoidBatchingSideEffect: Bool
    let didAvoidPacketMutation: Bool
    let didStayFullRebuildOnly: Bool

    init(
        orderingBasis: CjguiInternalRendererPacketOrderingBasis,
        materialHint: CjguiInternalRenderMaterialHint,
        batchKey: CjguiInternalRenderBatchKey,
        didPrepareRendererMaterialGroupingScope: Bool,
        shouldDeferRendererMaterialGroupingScope: Bool,
        shouldReportRendererMaterialGroupingScopeBlocked: Bool,
        didPreserveRendererPacketOrderingBasis: Bool,
        didPreserveRenderMaterialHint: Bool,
        didPreserveRenderBatchKey: Bool,
        didDescribeRendererMaterialGroupingScope: Bool,
        didKeepGroupingScopeValueOnly: Bool,
        didAvoidCommandMerge: Bool,
        didAvoidBatchingSideEffect: Bool,
        didAvoidPacketMutation: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.orderingBasis = orderingBasis
        this.materialHint = materialHint
        this.batchKey = batchKey
        this.didPrepareRendererMaterialGroupingScope = didPrepareRendererMaterialGroupingScope
        this.shouldDeferRendererMaterialGroupingScope = shouldDeferRendererMaterialGroupingScope
        this.shouldReportRendererMaterialGroupingScopeBlocked =
            shouldReportRendererMaterialGroupingScopeBlocked
        this.didPreserveRendererPacketOrderingBasis = didPreserveRendererPacketOrderingBasis
        this.didPreserveRenderMaterialHint = didPreserveRenderMaterialHint
        this.didPreserveRenderBatchKey = didPreserveRenderBatchKey
        this.didDescribeRendererMaterialGroupingScope = didDescribeRendererMaterialGroupingScope
        this.didKeepGroupingScopeValueOnly = didKeepGroupingScopeValueOnly
        this.didAvoidCommandMerge = didAvoidCommandMerge
        this.didAvoidBatchingSideEffect = didAvoidBatchingSideEffect
        this.didAvoidPacketMutation = didAvoidPacketMutation
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Hint preservation policy 只说明 material / ordering / invalidation hints 如何被保留；
// 它不修改 packet，也不创建新的提交语义。
struct CjguiInternalRendererHintPreservationPolicy {
    let materialGroupingScope: CjguiInternalRendererMaterialGroupingScope
    let invalidationHint: CjguiInternalRenderInvalidationHint
    let didPrepareRendererHintPreservationPolicy: Bool
    let shouldDeferRendererHintPreservationPolicy: Bool
    let shouldReportRendererHintPreservationPolicyBlocked: Bool
    let didPreserveRendererMaterialGroupingScope: Bool
    let didPreserveMaterialHintFacts: Bool
    let didPreserveOrderingHintFacts: Bool
    let didPreserveBatchKeyHint: Bool
    let didPreserveInvalidationHintFacts: Bool
    let didAvoidPacketMutation: Bool
    let didAvoidRendererStateWrite: Bool
    let didStayFullRebuildOnly: Bool

    init(
        materialGroupingScope: CjguiInternalRendererMaterialGroupingScope,
        invalidationHint: CjguiInternalRenderInvalidationHint,
        didPrepareRendererHintPreservationPolicy: Bool,
        shouldDeferRendererHintPreservationPolicy: Bool,
        shouldReportRendererHintPreservationPolicyBlocked: Bool,
        didPreserveRendererMaterialGroupingScope: Bool,
        didPreserveMaterialHintFacts: Bool,
        didPreserveOrderingHintFacts: Bool,
        didPreserveBatchKeyHint: Bool,
        didPreserveInvalidationHintFacts: Bool,
        didAvoidPacketMutation: Bool,
        didAvoidRendererStateWrite: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.materialGroupingScope = materialGroupingScope
        this.invalidationHint = invalidationHint
        this.didPrepareRendererHintPreservationPolicy = didPrepareRendererHintPreservationPolicy
        this.shouldDeferRendererHintPreservationPolicy = shouldDeferRendererHintPreservationPolicy
        this.shouldReportRendererHintPreservationPolicyBlocked =
            shouldReportRendererHintPreservationPolicyBlocked
        this.didPreserveRendererMaterialGroupingScope = didPreserveRendererMaterialGroupingScope
        this.didPreserveMaterialHintFacts = didPreserveMaterialHintFacts
        this.didPreserveOrderingHintFacts = didPreserveOrderingHintFacts
        this.didPreserveBatchKeyHint = didPreserveBatchKeyHint
        this.didPreserveInvalidationHintFacts = didPreserveInvalidationHintFacts
        this.didAvoidPacketMutation = didAvoidPacketMutation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// No-sort-no-merge gate 是 hardening gate；它只确认没有排序 / 合并 / packet mutation 副作用，
// 不代表绘制许可，也不代表后续 owner 已经存在。
struct CjguiInternalRendererNoSortNoMergeGate {
    let hintPreservationPolicy: CjguiInternalRendererHintPreservationPolicy
    let didPrepareRendererNoSortNoMergeGate: Bool
    let shouldDeferRendererNoSortNoMergeGate: Bool
    let shouldReportRendererNoSortNoMergeGateBlocked: Bool
    let didPreserveRendererHintPreservationPolicy: Bool
    let didConfirmNoSortSideEffect: Bool
    let didConfirmNoCommandMerge: Bool
    let didConfirmNoBatchingSideEffect: Bool
    let didAvoidPacketMutation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        hintPreservationPolicy: CjguiInternalRendererHintPreservationPolicy,
        didPrepareRendererNoSortNoMergeGate: Bool,
        shouldDeferRendererNoSortNoMergeGate: Bool,
        shouldReportRendererNoSortNoMergeGateBlocked: Bool,
        didPreserveRendererHintPreservationPolicy: Bool,
        didConfirmNoSortSideEffect: Bool,
        didConfirmNoCommandMerge: Bool,
        didConfirmNoBatchingSideEffect: Bool,
        didAvoidPacketMutation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.hintPreservationPolicy = hintPreservationPolicy
        this.didPrepareRendererNoSortNoMergeGate = didPrepareRendererNoSortNoMergeGate
        this.shouldDeferRendererNoSortNoMergeGate = shouldDeferRendererNoSortNoMergeGate
        this.shouldReportRendererNoSortNoMergeGateBlocked = shouldReportRendererNoSortNoMergeGateBlocked
        this.didPreserveRendererHintPreservationPolicy = didPreserveRendererHintPreservationPolicy
        this.didConfirmNoSortSideEffect = didConfirmNoSortSideEffect
        this.didConfirmNoCommandMerge = didConfirmNoCommandMerge
        this.didConfirmNoBatchingSideEffect = didConfirmNoBatchingSideEffect
        this.didAvoidPacketMutation = didAvoidPacketMutation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

// Hardening result 是本 owner 的 canonical endpoint；
// accepted 只表示 ordering / grouping hardening facts 成立，不代表可以绘制。
struct CjguiInternalRendererPacketOrderingHardeningResult {
    let noSortNoMergeGate: CjguiInternalRendererNoSortNoMergeGate
    let isRendererPacketOrderingHardeningAccepted: Bool
    let canFutureRendererBoundaryUseHardenedOrderingFacts: Bool
    let shouldDeferRendererPacketOrderingHardeningResult: Bool
    let shouldReportRendererPacketOrderingHardeningResultBlocked: Bool
    let didSealRendererPacketOrderingHardeningResult: Bool
    let didPreserveRendererNoSortNoMergeGate: Bool
    let didKeepOrderingHardeningResultValueOnly: Bool
    let didAvoidPacketMutation: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        noSortNoMergeGate: CjguiInternalRendererNoSortNoMergeGate,
        isRendererPacketOrderingHardeningAccepted: Bool,
        canFutureRendererBoundaryUseHardenedOrderingFacts: Bool,
        shouldDeferRendererPacketOrderingHardeningResult: Bool,
        shouldReportRendererPacketOrderingHardeningResultBlocked: Bool,
        didSealRendererPacketOrderingHardeningResult: Bool,
        didPreserveRendererNoSortNoMergeGate: Bool,
        didKeepOrderingHardeningResultValueOnly: Bool,
        didAvoidPacketMutation: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.noSortNoMergeGate = noSortNoMergeGate
        this.isRendererPacketOrderingHardeningAccepted = isRendererPacketOrderingHardeningAccepted
        this.canFutureRendererBoundaryUseHardenedOrderingFacts =
            canFutureRendererBoundaryUseHardenedOrderingFacts
        this.shouldDeferRendererPacketOrderingHardeningResult =
            shouldDeferRendererPacketOrderingHardeningResult
        this.shouldReportRendererPacketOrderingHardeningResultBlocked =
            shouldReportRendererPacketOrderingHardeningResultBlocked
        this.didSealRendererPacketOrderingHardeningResult = didSealRendererPacketOrderingHardeningResult
        this.didPreserveRendererNoSortNoMergeGate = didPreserveRendererNoSortNoMergeGate
        this.didKeepOrderingHardeningResultValueOnly = didKeepOrderingHardeningResultValueOnly
        this.didAvoidPacketMutation = didAvoidPacketMutation
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererPacketOrderingBasis(
    normalizationResult: CjguiInternalRendererPacketNormalizationResult
): CjguiInternalRendererPacketOrderingBasis {
    let groupingFacts = normalizationResult.materialGroupingFacts
    let orderingFacts = groupingFacts.normalizedOrderingFacts
    let candidate = orderingFacts.normalizedPacketCandidate
    let batchingPlan = candidate.batchingPacket.batchingPlan
    let orderingHint = batchingPlan.orderingHint
    let normalizationReady = normalizationResult.isRendererPacketNormalizationAccepted &&
        normalizationResult.canFutureRendererBoundaryUseNormalizedPacket &&
        normalizationResult.didPreserveNormalizedMaterialGroupingFacts &&
        normalizationResult.didAvoidRendererStateWrite &&
        normalizationResult.didAvoidDrawingPermission &&
        normalizationResult.didAvoidSortSideEffect &&
        normalizationResult.didStayFullRebuildOnly &&
        normalizationResult.shouldDeferRendererPacketNormalizationResult == false &&
        normalizationResult.shouldReportRendererPacketNormalizationResultBlocked == false
    let basisReady = normalizationReady &&
        orderingFacts.didPrepareRendererNormalizedOrderingFacts &&
        orderingFacts.didPreserveNormalizedPacketCandidate &&
        orderingFacts.didDescribeExistingPacketOrder &&
        orderingFacts.didAvoidSortSideEffect &&
        orderingFacts.didKeepOrderingFactsValueOnly &&
        orderingFacts.didStayFullRebuildOnly &&
        orderingHint.didPrepareRenderOrderingHint &&
        orderingHint.didPreserveCommandOrderingFacts &&
        orderingHint.didAvoidSortSideEffect &&
        orderingHint.didPreserveRenderBatchKey &&
        orderingHint.shouldDeferRenderOrderingHint == false &&
        orderingHint.shouldReportRenderOrderingHintBlocked == false
    let basisDeferred = normalizationResult.isRendererPacketNormalizationAccepted == false &&
        normalizationResult.canFutureRendererBoundaryUseNormalizedPacket == false &&
        normalizationResult.shouldDeferRendererPacketNormalizationResult &&
        normalizationResult.shouldReportRendererPacketNormalizationResultBlocked == false
    let basisInconsistent = (
        normalizationResult.isRendererPacketNormalizationAccepted &&
            (
                normalizationResult.canFutureRendererBoundaryUseNormalizedPacket == false ||
                normalizationResult.didPreserveNormalizedMaterialGroupingFacts == false ||
                normalizationResult.didAvoidRendererStateWrite == false ||
                normalizationResult.didAvoidDrawingPermission == false ||
                normalizationResult.didAvoidSortSideEffect == false ||
                normalizationResult.didStayFullRebuildOnly == false ||
                normalizationResult.shouldDeferRendererPacketNormalizationResult ||
                normalizationResult.shouldReportRendererPacketNormalizationResultBlocked
            )
        ) ||
        (
            orderingFacts.didPrepareRendererNormalizedOrderingFacts &&
                (
                    orderingFacts.didPreserveNormalizedPacketCandidate == false ||
                    orderingFacts.didDescribeExistingPacketOrder == false ||
                    orderingFacts.didAvoidSortSideEffect == false ||
                    orderingFacts.didKeepOrderingFactsValueOnly == false ||
                    orderingFacts.didStayFullRebuildOnly == false ||
                    orderingFacts.shouldDeferRendererNormalizedOrderingFacts ||
                    orderingFacts.shouldReportRendererNormalizedOrderingFactsBlocked
                )
        ) ||
        (
            orderingHint.didPrepareRenderOrderingHint &&
                (
                    orderingHint.didPreserveCommandOrderingFacts == false ||
                    orderingHint.didAvoidSortSideEffect == false ||
                    orderingHint.didPreserveRenderBatchKey == false ||
                    orderingHint.shouldDeferRenderOrderingHint ||
                    orderingHint.shouldReportRenderOrderingHintBlocked
                )
        ) ||
        (normalizationResult.shouldDeferRendererPacketNormalizationResult &&
            normalizationResult.shouldReportRendererPacketNormalizationResultBlocked) ||
        (orderingFacts.shouldDeferRendererNormalizedOrderingFacts &&
            orderingFacts.shouldReportRendererNormalizedOrderingFactsBlocked) ||
        (orderingHint.shouldDeferRenderOrderingHint && orderingHint.shouldReportRenderOrderingHintBlocked)

    // ordering basis 必须 fail-closed；这里不能把 normalization result 伪造成可排序结果。
    if (
        normalizationResult.shouldReportRendererPacketNormalizationResultBlocked ||
        orderingFacts.shouldReportRendererNormalizedOrderingFactsBlocked ||
        orderingHint.shouldReportRenderOrderingHintBlocked ||
        basisInconsistent
    ) {
        return CjguiInternalRendererPacketOrderingBasis(
            normalizationResult,
            orderingHint,
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

    if (basisReady) {
        return CjguiInternalRendererPacketOrderingBasis(
            normalizationResult,
            orderingHint,
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

    if (basisDeferred) {
        return CjguiInternalRendererPacketOrderingBasis(
            normalizationResult,
            orderingHint,
            false,
            true,
            false,
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

    return CjguiInternalRendererPacketOrderingBasis(
        normalizationResult,
        orderingHint,
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

func cjguiInternalBuildRendererMaterialGroupingScope(
    orderingBasis: CjguiInternalRendererPacketOrderingBasis
): CjguiInternalRendererMaterialGroupingScope {
    let groupingFacts = orderingBasis.normalizationResult.materialGroupingFacts
    let candidate = groupingFacts.normalizedOrderingFacts.normalizedPacketCandidate
    let batchingPlan = candidate.batchingPacket.batchingPlan
    let materialHint = batchingPlan.materialHint
    let batchKey = batchingPlan.batchKey
    let basisReady = orderingBasis.didPrepareRendererPacketOrderingBasis &&
        orderingBasis.didPreserveRendererPacketNormalizationResult &&
        orderingBasis.didPreserveRenderOrderingHint &&
        orderingBasis.didDescribeRendererOrderingBasis &&
        orderingBasis.didKeepOrderingBasisValueOnly &&
        orderingBasis.didAvoidSortSideEffect &&
        orderingBasis.didAvoidPacketMutation &&
        orderingBasis.didAvoidRendererStateWrite &&
        orderingBasis.didAvoidDrawingPermission &&
        orderingBasis.didStayFullRebuildOnly &&
        orderingBasis.shouldDeferRendererPacketOrderingBasis == false &&
        orderingBasis.shouldReportRendererPacketOrderingBasisBlocked == false
    let scopeReady = basisReady &&
        groupingFacts.didPrepareRendererNormalizedMaterialGroupingFacts &&
        groupingFacts.didDescribeMaterialGroupingHints &&
        groupingFacts.didPreserveBatchKeyHint &&
        groupingFacts.didAvoidCommandMerge &&
        groupingFacts.didAvoidRealBatching &&
        groupingFacts.didStayFullRebuildOnly &&
        materialHint.didPrepareRenderMaterialHint &&
        materialHint.didKeepMaterialHintRendererAgnostic &&
        materialHint.didAvoidMaterialResourceBinding &&
        materialHint.didPreserveRenderCommandPacket &&
        batchKey.didPrepareRenderBatchKey &&
        batchKey.didKeepBatchKeyAsHint &&
        batchKey.didAvoidPipelineBinding &&
        batchKey.didPreserveMaterialHint &&
        batchingPlan.didKeepPlanRendererAgnostic &&
        batchingPlan.didAvoidCommandMerge &&
        batchingPlan.didAvoidIncrementalBatchUpdate &&
        batchingPlan.didUseFullRebuildBatchingPlan &&
        materialHint.shouldDeferRenderMaterialHint == false &&
        materialHint.shouldReportRenderMaterialHintBlocked == false &&
        batchKey.shouldDeferRenderBatchKey == false &&
        batchKey.shouldReportRenderBatchKeyBlocked == false
    let scopeDeferred = orderingBasis.didPrepareRendererPacketOrderingBasis == false &&
        orderingBasis.shouldDeferRendererPacketOrderingBasis &&
        orderingBasis.shouldReportRendererPacketOrderingBasisBlocked == false
    let scopeInconsistent = (
        orderingBasis.didPrepareRendererPacketOrderingBasis &&
            (
                orderingBasis.didPreserveRendererPacketNormalizationResult == false ||
                orderingBasis.didPreserveRenderOrderingHint == false ||
                orderingBasis.didDescribeRendererOrderingBasis == false ||
                orderingBasis.didKeepOrderingBasisValueOnly == false ||
                orderingBasis.didAvoidSortSideEffect == false ||
                orderingBasis.didAvoidPacketMutation == false ||
                orderingBasis.didAvoidRendererStateWrite == false ||
                orderingBasis.didAvoidDrawingPermission == false ||
                orderingBasis.didStayFullRebuildOnly == false ||
                orderingBasis.shouldDeferRendererPacketOrderingBasis ||
                orderingBasis.shouldReportRendererPacketOrderingBasisBlocked
            )
        ) ||
        (
            groupingFacts.didPrepareRendererNormalizedMaterialGroupingFacts &&
                (
                    groupingFacts.didDescribeMaterialGroupingHints == false ||
                    groupingFacts.didPreserveBatchKeyHint == false ||
                    groupingFacts.didAvoidCommandMerge == false ||
                    groupingFacts.didAvoidRealBatching == false ||
                    groupingFacts.didStayFullRebuildOnly == false ||
                    groupingFacts.shouldDeferRendererNormalizedMaterialGroupingFacts ||
                    groupingFacts.shouldReportRendererNormalizedMaterialGroupingFactsBlocked
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
        (orderingBasis.shouldDeferRendererPacketOrderingBasis &&
            orderingBasis.shouldReportRendererPacketOrderingBasisBlocked) ||
        (groupingFacts.shouldDeferRendererNormalizedMaterialGroupingFacts &&
            groupingFacts.shouldReportRendererNormalizedMaterialGroupingFactsBlocked) ||
        (materialHint.shouldDeferRenderMaterialHint && materialHint.shouldReportRenderMaterialHintBlocked) ||
        (batchKey.shouldDeferRenderBatchKey && batchKey.shouldReportRenderBatchKeyBlocked) ||
        (batchingPlan.shouldDeferRenderBatchingPlan && batchingPlan.shouldReportRenderBatchingPlanBlocked)

    // grouping scope 不一致时必须 fail-closed，不能把 hint scope 升级成真实合批行为。
    if (
        orderingBasis.shouldReportRendererPacketOrderingBasisBlocked ||
        groupingFacts.shouldReportRendererNormalizedMaterialGroupingFactsBlocked ||
        materialHint.shouldReportRenderMaterialHintBlocked ||
        batchKey.shouldReportRenderBatchKeyBlocked ||
        batchingPlan.shouldReportRenderBatchingPlanBlocked ||
        scopeInconsistent
    ) {
        return CjguiInternalRendererMaterialGroupingScope(
            orderingBasis,
            materialHint,
            batchKey,
            false,
            false,
            true,
            false,
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

    if (scopeReady) {
        return CjguiInternalRendererMaterialGroupingScope(
            orderingBasis,
            materialHint,
            batchKey,
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

    if (scopeDeferred) {
        return CjguiInternalRendererMaterialGroupingScope(
            orderingBasis,
            materialHint,
            batchKey,
            false,
            true,
            false,
            false,
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

    return CjguiInternalRendererMaterialGroupingScope(
        orderingBasis,
        materialHint,
        batchKey,
        false,
        false,
        true,
        false,
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

func cjguiInternalBuildRendererHintPreservationPolicy(
    materialGroupingScope: CjguiInternalRendererMaterialGroupingScope
): CjguiInternalRendererHintPreservationPolicy {
    let materialHint = materialGroupingScope.materialHint
    let batchKey = materialGroupingScope.batchKey
    let orderingHint = materialGroupingScope.orderingBasis.orderingHint
    let commandPacket = materialHint.commandPacket
    let invalidationHint = commandPacket.commandList.rootCommand.invalidationHint
    let scopeReady = materialGroupingScope.didPrepareRendererMaterialGroupingScope &&
        materialGroupingScope.didPreserveRendererPacketOrderingBasis &&
        materialGroupingScope.didPreserveRenderMaterialHint &&
        materialGroupingScope.didPreserveRenderBatchKey &&
        materialGroupingScope.didDescribeRendererMaterialGroupingScope &&
        materialGroupingScope.didKeepGroupingScopeValueOnly &&
        materialGroupingScope.didAvoidCommandMerge &&
        materialGroupingScope.didAvoidBatchingSideEffect &&
        materialGroupingScope.didAvoidPacketMutation &&
        materialGroupingScope.didStayFullRebuildOnly &&
        materialGroupingScope.shouldDeferRendererMaterialGroupingScope == false &&
        materialGroupingScope.shouldReportRendererMaterialGroupingScopeBlocked == false
    let policyReady = scopeReady &&
        materialHint.didKeepMaterialHintRendererAgnostic &&
        materialHint.didAvoidMaterialResourceBinding &&
        materialHint.didPreserveRenderCommandPacket &&
        batchKey.didKeepBatchKeyAsHint &&
        batchKey.didAvoidPipelineBinding &&
        batchKey.didPreserveMaterialHint &&
        orderingHint.didPreserveCommandOrderingFacts &&
        orderingHint.didAvoidSortSideEffect &&
        orderingHint.didPreserveRenderBatchKey &&
        invalidationHint.requiresFullDisplayListRebuild &&
        invalidationHint.allowsIncrementalRebuild == false &&
        invalidationHint.allowsDisplayListMutation == false &&
        invalidationHint.allowsPartialRepaint == false &&
        invalidationHint.didReserveRepaintHint
    let policyDeferred = materialGroupingScope.didPrepareRendererMaterialGroupingScope == false &&
        materialGroupingScope.shouldDeferRendererMaterialGroupingScope &&
        materialGroupingScope.shouldReportRendererMaterialGroupingScopeBlocked == false
    let policyInconsistent = (
        materialGroupingScope.didPrepareRendererMaterialGroupingScope &&
            (
                materialGroupingScope.didPreserveRendererPacketOrderingBasis == false ||
                materialGroupingScope.didPreserveRenderMaterialHint == false ||
                materialGroupingScope.didPreserveRenderBatchKey == false ||
                materialGroupingScope.didDescribeRendererMaterialGroupingScope == false ||
                materialGroupingScope.didKeepGroupingScopeValueOnly == false ||
                materialGroupingScope.didAvoidCommandMerge == false ||
                materialGroupingScope.didAvoidBatchingSideEffect == false ||
                materialGroupingScope.didAvoidPacketMutation == false ||
                materialGroupingScope.didStayFullRebuildOnly == false ||
                materialGroupingScope.shouldDeferRendererMaterialGroupingScope ||
                materialGroupingScope.shouldReportRendererMaterialGroupingScopeBlocked
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
            orderingHint.didPrepareRenderOrderingHint &&
                (
                    orderingHint.didPreserveCommandOrderingFacts == false ||
                    orderingHint.didAvoidSortSideEffect == false ||
                    orderingHint.didPreserveRenderBatchKey == false ||
                    orderingHint.shouldDeferRenderOrderingHint ||
                    orderingHint.shouldReportRenderOrderingHintBlocked
                )
        ) ||
        (
            invalidationHint.requiresFullDisplayListRebuild == false ||
            invalidationHint.allowsIncrementalRebuild ||
            invalidationHint.allowsDisplayListMutation ||
            invalidationHint.allowsPartialRepaint ||
            invalidationHint.didReserveRepaintHint == false
        ) ||
        (materialGroupingScope.shouldDeferRendererMaterialGroupingScope &&
            materialGroupingScope.shouldReportRendererMaterialGroupingScopeBlocked) ||
        (materialHint.shouldDeferRenderMaterialHint && materialHint.shouldReportRenderMaterialHintBlocked) ||
        (batchKey.shouldDeferRenderBatchKey && batchKey.shouldReportRenderBatchKeyBlocked) ||
        (orderingHint.shouldDeferRenderOrderingHint && orderingHint.shouldReportRenderOrderingHintBlocked)

    // hint preservation policy 不一致时必须 fail-closed，不能改写 packet 或 hints。
    if (
        materialGroupingScope.shouldReportRendererMaterialGroupingScopeBlocked ||
        materialHint.shouldReportRenderMaterialHintBlocked ||
        batchKey.shouldReportRenderBatchKeyBlocked ||
        orderingHint.shouldReportRenderOrderingHintBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalRendererHintPreservationPolicy(
            materialGroupingScope,
            invalidationHint,
            false,
            false,
            true,
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

    if (policyReady) {
        return CjguiInternalRendererHintPreservationPolicy(
            materialGroupingScope,
            invalidationHint,
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

    if (policyDeferred) {
        return CjguiInternalRendererHintPreservationPolicy(
            materialGroupingScope,
            invalidationHint,
            false,
            true,
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

    return CjguiInternalRendererHintPreservationPolicy(
        materialGroupingScope,
        invalidationHint,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererNoSortNoMergeGate(
    hintPreservationPolicy: CjguiInternalRendererHintPreservationPolicy
): CjguiInternalRendererNoSortNoMergeGate {
    let policyReady = hintPreservationPolicy.didPrepareRendererHintPreservationPolicy &&
        hintPreservationPolicy.didPreserveRendererMaterialGroupingScope &&
        hintPreservationPolicy.didPreserveMaterialHintFacts &&
        hintPreservationPolicy.didPreserveOrderingHintFacts &&
        hintPreservationPolicy.didPreserveBatchKeyHint &&
        hintPreservationPolicy.didPreserveInvalidationHintFacts &&
        hintPreservationPolicy.didAvoidPacketMutation &&
        hintPreservationPolicy.didAvoidRendererStateWrite &&
        hintPreservationPolicy.didStayFullRebuildOnly &&
        hintPreservationPolicy.shouldDeferRendererHintPreservationPolicy == false &&
        hintPreservationPolicy.shouldReportRendererHintPreservationPolicyBlocked == false
    let gateDeferred = hintPreservationPolicy.didPrepareRendererHintPreservationPolicy == false &&
        hintPreservationPolicy.shouldDeferRendererHintPreservationPolicy &&
        hintPreservationPolicy.shouldReportRendererHintPreservationPolicyBlocked == false
    let gateInconsistent = (
        hintPreservationPolicy.didPrepareRendererHintPreservationPolicy &&
            (
                hintPreservationPolicy.didPreserveRendererMaterialGroupingScope == false ||
                hintPreservationPolicy.didPreserveMaterialHintFacts == false ||
                hintPreservationPolicy.didPreserveOrderingHintFacts == false ||
                hintPreservationPolicy.didPreserveBatchKeyHint == false ||
                hintPreservationPolicy.didPreserveInvalidationHintFacts == false ||
                hintPreservationPolicy.didAvoidPacketMutation == false ||
                hintPreservationPolicy.didAvoidRendererStateWrite == false ||
                hintPreservationPolicy.didStayFullRebuildOnly == false ||
                hintPreservationPolicy.shouldDeferRendererHintPreservationPolicy ||
                hintPreservationPolicy.shouldReportRendererHintPreservationPolicyBlocked
            )
        ) ||
        (hintPreservationPolicy.didPreserveRendererMaterialGroupingScope &&
            hintPreservationPolicy.didPrepareRendererHintPreservationPolicy == false) ||
        (hintPreservationPolicy.shouldDeferRendererHintPreservationPolicy &&
            hintPreservationPolicy.shouldReportRendererHintPreservationPolicyBlocked)

    // gate facts 不一致时必须 fail-closed；gate 只确认 no-sort-no-merge value facts。
    if (
        hintPreservationPolicy.shouldReportRendererHintPreservationPolicyBlocked ||
        gateInconsistent
    ) {
        return CjguiInternalRendererNoSortNoMergeGate(
            hintPreservationPolicy,
            false,
            false,
            true,
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

    if (policyReady) {
        return CjguiInternalRendererNoSortNoMergeGate(
            hintPreservationPolicy,
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

    if (gateDeferred) {
        return CjguiInternalRendererNoSortNoMergeGate(
            hintPreservationPolicy,
            false,
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

    return CjguiInternalRendererNoSortNoMergeGate(
        hintPreservationPolicy,
        false,
        false,
        true,
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

func cjguiInternalBuildRendererPacketOrderingHardeningResult(
    noSortNoMergeGate: CjguiInternalRendererNoSortNoMergeGate
): CjguiInternalRendererPacketOrderingHardeningResult {
    let gateReady = noSortNoMergeGate.didPrepareRendererNoSortNoMergeGate &&
        noSortNoMergeGate.didPreserveRendererHintPreservationPolicy &&
        noSortNoMergeGate.didConfirmNoSortSideEffect &&
        noSortNoMergeGate.didConfirmNoCommandMerge &&
        noSortNoMergeGate.didConfirmNoBatchingSideEffect &&
        noSortNoMergeGate.didAvoidPacketMutation &&
        noSortNoMergeGate.didAvoidRendererStateWrite &&
        noSortNoMergeGate.didAvoidDrawingPermission &&
        noSortNoMergeGate.didStayFullRebuildOnly &&
        noSortNoMergeGate.shouldDeferRendererNoSortNoMergeGate == false &&
        noSortNoMergeGate.shouldReportRendererNoSortNoMergeGateBlocked == false
    let gateDeferred = noSortNoMergeGate.didPrepareRendererNoSortNoMergeGate == false &&
        noSortNoMergeGate.shouldDeferRendererNoSortNoMergeGate &&
        noSortNoMergeGate.shouldReportRendererNoSortNoMergeGateBlocked == false
    let gateInconsistent = (
        noSortNoMergeGate.didPrepareRendererNoSortNoMergeGate &&
            (
                noSortNoMergeGate.didPreserveRendererHintPreservationPolicy == false ||
                noSortNoMergeGate.didConfirmNoSortSideEffect == false ||
                noSortNoMergeGate.didConfirmNoCommandMerge == false ||
                noSortNoMergeGate.didConfirmNoBatchingSideEffect == false ||
                noSortNoMergeGate.didAvoidPacketMutation == false ||
                noSortNoMergeGate.didAvoidRendererStateWrite == false ||
                noSortNoMergeGate.didAvoidDrawingPermission == false ||
                noSortNoMergeGate.didStayFullRebuildOnly == false ||
                noSortNoMergeGate.shouldDeferRendererNoSortNoMergeGate ||
                noSortNoMergeGate.shouldReportRendererNoSortNoMergeGateBlocked
            )
        ) ||
        (noSortNoMergeGate.didPreserveRendererHintPreservationPolicy &&
            noSortNoMergeGate.didPrepareRendererNoSortNoMergeGate == false) ||
        (noSortNoMergeGate.shouldDeferRendererNoSortNoMergeGate &&
            noSortNoMergeGate.shouldReportRendererNoSortNoMergeGateBlocked)

    // hardening result 只封 value facts；不产生真实排序、合并或绘制许可。
    if (
        noSortNoMergeGate.shouldReportRendererNoSortNoMergeGateBlocked ||
        gateInconsistent
    ) {
        return CjguiInternalRendererPacketOrderingHardeningResult(
            noSortNoMergeGate,
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

    if (gateReady) {
        return CjguiInternalRendererPacketOrderingHardeningResult(
            noSortNoMergeGate,
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

    if (gateDeferred) {
        return CjguiInternalRendererPacketOrderingHardeningResult(
            noSortNoMergeGate,
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

    return CjguiInternalRendererPacketOrderingHardeningResult(
        noSortNoMergeGate,
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

func cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft(
): CjguiInternalRendererPacketOrderingHardeningResult {
    // 默认 draft 只串联 normalization result -> ordering / grouping hardening facts；
    // 它不排序、不合并、不改 packet，也不触发绘制。
    let normalizationResult = cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()
    let orderingBasis = cjguiInternalBuildRendererPacketOrderingBasis(normalizationResult)
    let groupingScope = cjguiInternalBuildRendererMaterialGroupingScope(orderingBasis)
    let hintPolicy = cjguiInternalBuildRendererHintPreservationPolicy(groupingScope)
    let noSortNoMergeGate = cjguiInternalBuildRendererNoSortNoMergeGate(hintPolicy)
    return cjguiInternalBuildRendererPacketOrderingHardeningResult(noSortNoMergeGate)
}

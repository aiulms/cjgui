package cjgui

// Owner: Renderer packet error taxonomy boundary.
// Truth: 只消费 packet normalization result，产出 failure / degraded / blocked 分类 facts。
// Stop-line: 不进入平台后端、不抛异常、不发布公开错误、不触发外部通知、不触发绘制。
// Same-shape Boundary Brake: 本 owner 新增 taxonomy / degraded reason / blocked reason 语义，
// 不新增 receipt / record / publication 形态的薄尾巴。

// Failure taxonomy 只给 normalization result 的失败形态分类；
// 它不是异常系统，也不是后端错误处理器。
struct CjguiInternalRendererPacketFailureTaxonomy {
    let normalizationResult: CjguiInternalRendererPacketNormalizationResult
    let didClassifyRendererPacketFailureTaxonomy: Bool
    let isRendererPacketFailureAbsent: Bool
    let shouldDeferRendererPacketFailureTaxonomy: Bool
    let shouldReportRendererPacketFailureTaxonomyBlocked: Bool
    let didPreserveRendererPacketNormalizationResult: Bool
    let didKeepFailureTaxonomyValueOnly: Bool
    let didAvoidExceptionThrowing: Bool
    let didAvoidErrorPublication: Bool
    let didAvoidExternalNotification: Bool

    init(
        normalizationResult: CjguiInternalRendererPacketNormalizationResult,
        didClassifyRendererPacketFailureTaxonomy: Bool,
        isRendererPacketFailureAbsent: Bool,
        shouldDeferRendererPacketFailureTaxonomy: Bool,
        shouldReportRendererPacketFailureTaxonomyBlocked: Bool,
        didPreserveRendererPacketNormalizationResult: Bool,
        didKeepFailureTaxonomyValueOnly: Bool,
        didAvoidExceptionThrowing: Bool,
        didAvoidErrorPublication: Bool,
        didAvoidExternalNotification: Bool
    ) {
        this.normalizationResult = normalizationResult
        this.didClassifyRendererPacketFailureTaxonomy = didClassifyRendererPacketFailureTaxonomy
        this.isRendererPacketFailureAbsent = isRendererPacketFailureAbsent
        this.shouldDeferRendererPacketFailureTaxonomy = shouldDeferRendererPacketFailureTaxonomy
        this.shouldReportRendererPacketFailureTaxonomyBlocked =
            shouldReportRendererPacketFailureTaxonomyBlocked
        this.didPreserveRendererPacketNormalizationResult = didPreserveRendererPacketNormalizationResult
        this.didKeepFailureTaxonomyValueOnly = didKeepFailureTaxonomyValueOnly
        this.didAvoidExceptionThrowing = didAvoidExceptionThrowing
        this.didAvoidErrorPublication = didAvoidErrorPublication
        this.didAvoidExternalNotification = didAvoidExternalNotification
    }
}

// Degraded reason 当前只保留“无降级”或“随上游阻塞”的内部分类位置；
// 它不记录日志，也不把错误暴露给外部接口。
struct CjguiInternalRendererPacketDegradedReason {
    let failureTaxonomy: CjguiInternalRendererPacketFailureTaxonomy
    let didClassifyRendererPacketDegradedReason: Bool
    let isRendererPacketDegradedReasonAbsent: Bool
    let shouldDeferRendererPacketDegradedReason: Bool
    let shouldReportRendererPacketDegradedReasonBlocked: Bool
    let didPreserveRendererPacketFailureTaxonomy: Bool
    let didIdentifyNormalizationDegradedReason: Bool
    let didKeepDegradedReasonValueOnly: Bool
    let didAvoidExceptionThrowing: Bool
    let didAvoidErrorPublication: Bool
    let didAvoidExternalNotification: Bool

    init(
        failureTaxonomy: CjguiInternalRendererPacketFailureTaxonomy,
        didClassifyRendererPacketDegradedReason: Bool,
        isRendererPacketDegradedReasonAbsent: Bool,
        shouldDeferRendererPacketDegradedReason: Bool,
        shouldReportRendererPacketDegradedReasonBlocked: Bool,
        didPreserveRendererPacketFailureTaxonomy: Bool,
        didIdentifyNormalizationDegradedReason: Bool,
        didKeepDegradedReasonValueOnly: Bool,
        didAvoidExceptionThrowing: Bool,
        didAvoidErrorPublication: Bool,
        didAvoidExternalNotification: Bool
    ) {
        this.failureTaxonomy = failureTaxonomy
        this.didClassifyRendererPacketDegradedReason = didClassifyRendererPacketDegradedReason
        this.isRendererPacketDegradedReasonAbsent = isRendererPacketDegradedReasonAbsent
        this.shouldDeferRendererPacketDegradedReason = shouldDeferRendererPacketDegradedReason
        this.shouldReportRendererPacketDegradedReasonBlocked =
            shouldReportRendererPacketDegradedReasonBlocked
        this.didPreserveRendererPacketFailureTaxonomy = didPreserveRendererPacketFailureTaxonomy
        this.didIdentifyNormalizationDegradedReason = didIdentifyNormalizationDegradedReason
        this.didKeepDegradedReasonValueOnly = didKeepDegradedReasonValueOnly
        this.didAvoidExceptionThrowing = didAvoidExceptionThrowing
        this.didAvoidErrorPublication = didAvoidErrorPublication
        this.didAvoidExternalNotification = didAvoidExternalNotification
    }
}

// Blocked reason 记录 fail-closed 的内部原因分类；
// 它只服务 packet value pipeline，不触发后端处理。
struct CjguiInternalRendererPacketBlockedReason {
    let degradedReason: CjguiInternalRendererPacketDegradedReason
    let didClassifyRendererPacketBlockedReason: Bool
    let isRendererPacketBlockedReasonAbsent: Bool
    let shouldDeferRendererPacketBlockedReason: Bool
    let shouldReportRendererPacketBlockedReasonBlocked: Bool
    let didPreserveRendererPacketDegradedReason: Bool
    let didIdentifyNormalizationBlockedReason: Bool
    let didPreserveFailClosedReason: Bool
    let didKeepBlockedReasonValueOnly: Bool
    let didAvoidExceptionThrowing: Bool
    let didAvoidErrorPublication: Bool
    let didAvoidExternalNotification: Bool

    init(
        degradedReason: CjguiInternalRendererPacketDegradedReason,
        didClassifyRendererPacketBlockedReason: Bool,
        isRendererPacketBlockedReasonAbsent: Bool,
        shouldDeferRendererPacketBlockedReason: Bool,
        shouldReportRendererPacketBlockedReasonBlocked: Bool,
        didPreserveRendererPacketDegradedReason: Bool,
        didIdentifyNormalizationBlockedReason: Bool,
        didPreserveFailClosedReason: Bool,
        didKeepBlockedReasonValueOnly: Bool,
        didAvoidExceptionThrowing: Bool,
        didAvoidErrorPublication: Bool,
        didAvoidExternalNotification: Bool
    ) {
        this.degradedReason = degradedReason
        this.didClassifyRendererPacketBlockedReason = didClassifyRendererPacketBlockedReason
        this.isRendererPacketBlockedReasonAbsent = isRendererPacketBlockedReasonAbsent
        this.shouldDeferRendererPacketBlockedReason = shouldDeferRendererPacketBlockedReason
        this.shouldReportRendererPacketBlockedReasonBlocked = shouldReportRendererPacketBlockedReasonBlocked
        this.didPreserveRendererPacketDegradedReason = didPreserveRendererPacketDegradedReason
        this.didIdentifyNormalizationBlockedReason = didIdentifyNormalizationBlockedReason
        this.didPreserveFailClosedReason = didPreserveFailClosedReason
        this.didKeepBlockedReasonValueOnly = didKeepBlockedReasonValueOnly
        this.didAvoidExceptionThrowing = didAvoidExceptionThrowing
        this.didAvoidErrorPublication = didAvoidErrorPublication
        this.didAvoidExternalNotification = didAvoidExternalNotification
    }
}

// Error taxonomy result 是本 owner 的 canonical endpoint；
// 它只表达内部分类结果，不抛异常、不写日志、不发布外部错误。
struct CjguiInternalRendererPacketErrorTaxonomyResult {
    let blockedReason: CjguiInternalRendererPacketBlockedReason
    let isRendererPacketErrorTaxonomyReady: Bool
    let canFutureRendererBoundaryUsePacketErrorTaxonomy: Bool
    let shouldDeferRendererPacketErrorTaxonomyResult: Bool
    let shouldReportRendererPacketErrorTaxonomyResultBlocked: Bool
    let didRecordRendererPacketErrorTaxonomyResult: Bool
    let didPreserveRendererPacketBlockedReason: Bool
    let didKeepErrorTaxonomyInternalOnly: Bool
    let didAvoidExceptionThrowing: Bool
    let didAvoidErrorPublication: Bool
    let didAvoidExternalNotification: Bool
    let didAvoidRendererStateWrite: Bool
    let didAvoidDrawingPermission: Bool
    let didStayFullRebuildOnly: Bool

    init(
        blockedReason: CjguiInternalRendererPacketBlockedReason,
        isRendererPacketErrorTaxonomyReady: Bool,
        canFutureRendererBoundaryUsePacketErrorTaxonomy: Bool,
        shouldDeferRendererPacketErrorTaxonomyResult: Bool,
        shouldReportRendererPacketErrorTaxonomyResultBlocked: Bool,
        didRecordRendererPacketErrorTaxonomyResult: Bool,
        didPreserveRendererPacketBlockedReason: Bool,
        didKeepErrorTaxonomyInternalOnly: Bool,
        didAvoidExceptionThrowing: Bool,
        didAvoidErrorPublication: Bool,
        didAvoidExternalNotification: Bool,
        didAvoidRendererStateWrite: Bool,
        didAvoidDrawingPermission: Bool,
        didStayFullRebuildOnly: Bool
    ) {
        this.blockedReason = blockedReason
        this.isRendererPacketErrorTaxonomyReady = isRendererPacketErrorTaxonomyReady
        this.canFutureRendererBoundaryUsePacketErrorTaxonomy =
            canFutureRendererBoundaryUsePacketErrorTaxonomy
        this.shouldDeferRendererPacketErrorTaxonomyResult = shouldDeferRendererPacketErrorTaxonomyResult
        this.shouldReportRendererPacketErrorTaxonomyResultBlocked =
            shouldReportRendererPacketErrorTaxonomyResultBlocked
        this.didRecordRendererPacketErrorTaxonomyResult = didRecordRendererPacketErrorTaxonomyResult
        this.didPreserveRendererPacketBlockedReason = didPreserveRendererPacketBlockedReason
        this.didKeepErrorTaxonomyInternalOnly = didKeepErrorTaxonomyInternalOnly
        this.didAvoidExceptionThrowing = didAvoidExceptionThrowing
        this.didAvoidErrorPublication = didAvoidErrorPublication
        this.didAvoidExternalNotification = didAvoidExternalNotification
        this.didAvoidRendererStateWrite = didAvoidRendererStateWrite
        this.didAvoidDrawingPermission = didAvoidDrawingPermission
        this.didStayFullRebuildOnly = didStayFullRebuildOnly
    }
}

func cjguiInternalBuildRendererPacketFailureTaxonomy(
    normalizationResult: CjguiInternalRendererPacketNormalizationResult
): CjguiInternalRendererPacketFailureTaxonomy {
    let normalizationReady = normalizationResult.isRendererPacketNormalizationAccepted &&
        normalizationResult.canFutureRendererBoundaryUseNormalizedPacket &&
        normalizationResult.didRecordRendererPacketNormalizationResult &&
        normalizationResult.didPreserveNormalizedMaterialGroupingFacts &&
        normalizationResult.didKeepNormalizationResultBackendAgnostic &&
        normalizationResult.didAvoidBackendPacketShape &&
        normalizationResult.didAvoidRendererStateWrite &&
        normalizationResult.didAvoidDrawingPermission &&
        normalizationResult.didAvoidSortSideEffect &&
        normalizationResult.didStayFullRebuildOnly &&
        normalizationResult.shouldDeferRendererPacketNormalizationResult == false &&
        normalizationResult.shouldReportRendererPacketNormalizationResultBlocked == false
    let normalizationDeferred = normalizationResult.isRendererPacketNormalizationAccepted == false &&
        normalizationResult.canFutureRendererBoundaryUseNormalizedPacket == false &&
        normalizationResult.shouldDeferRendererPacketNormalizationResult &&
        normalizationResult.shouldReportRendererPacketNormalizationResultBlocked == false &&
        normalizationResult.didKeepNormalizationResultBackendAgnostic &&
        normalizationResult.didAvoidBackendPacketShape &&
        normalizationResult.didAvoidRendererStateWrite &&
        normalizationResult.didAvoidDrawingPermission &&
        normalizationResult.didAvoidSortSideEffect &&
        normalizationResult.didStayFullRebuildOnly
    let normalizationInconsistent = (
        normalizationResult.isRendererPacketNormalizationAccepted &&
            (
                normalizationResult.canFutureRendererBoundaryUseNormalizedPacket == false ||
                normalizationResult.didRecordRendererPacketNormalizationResult == false ||
                normalizationResult.didPreserveNormalizedMaterialGroupingFacts == false ||
                normalizationResult.didKeepNormalizationResultBackendAgnostic == false ||
                normalizationResult.didAvoidBackendPacketShape == false ||
                normalizationResult.didAvoidRendererStateWrite == false ||
                normalizationResult.didAvoidDrawingPermission == false ||
                normalizationResult.didAvoidSortSideEffect == false ||
                normalizationResult.didStayFullRebuildOnly == false ||
                normalizationResult.shouldDeferRendererPacketNormalizationResult ||
                normalizationResult.shouldReportRendererPacketNormalizationResultBlocked
            )
        ) ||
        (normalizationResult.canFutureRendererBoundaryUseNormalizedPacket &&
            normalizationResult.isRendererPacketNormalizationAccepted == false) ||
        (normalizationResult.shouldDeferRendererPacketNormalizationResult &&
            normalizationResult.shouldReportRendererPacketNormalizationResultBlocked)

    // normalization result 不一致时必须 fail-closed，taxonomy 只记录内部分类 facts。
    if (
        normalizationResult.shouldReportRendererPacketNormalizationResultBlocked ||
        normalizationInconsistent
    ) {
        return CjguiInternalRendererPacketFailureTaxonomy(
            normalizationResult,
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

    if (normalizationReady) {
        return CjguiInternalRendererPacketFailureTaxonomy(
            normalizationResult,
            true,
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

    if (normalizationDeferred) {
        return CjguiInternalRendererPacketFailureTaxonomy(
            normalizationResult,
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

    return CjguiInternalRendererPacketFailureTaxonomy(
        normalizationResult,
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

func cjguiInternalBuildRendererPacketDegradedReason(
    failureTaxonomy: CjguiInternalRendererPacketFailureTaxonomy
): CjguiInternalRendererPacketDegradedReason {
    let taxonomyReady = failureTaxonomy.didClassifyRendererPacketFailureTaxonomy &&
        failureTaxonomy.isRendererPacketFailureAbsent &&
        failureTaxonomy.didPreserveRendererPacketNormalizationResult &&
        failureTaxonomy.didKeepFailureTaxonomyValueOnly &&
        failureTaxonomy.didAvoidExceptionThrowing &&
        failureTaxonomy.didAvoidErrorPublication &&
        failureTaxonomy.didAvoidExternalNotification &&
        failureTaxonomy.shouldDeferRendererPacketFailureTaxonomy == false &&
        failureTaxonomy.shouldReportRendererPacketFailureTaxonomyBlocked == false
    let taxonomyDeferred = failureTaxonomy.didClassifyRendererPacketFailureTaxonomy == false &&
        failureTaxonomy.shouldDeferRendererPacketFailureTaxonomy &&
        failureTaxonomy.shouldReportRendererPacketFailureTaxonomyBlocked == false
    let taxonomyBlocked = failureTaxonomy.shouldReportRendererPacketFailureTaxonomyBlocked ||
        (
            failureTaxonomy.didClassifyRendererPacketFailureTaxonomy &&
                failureTaxonomy.isRendererPacketFailureAbsent == false &&
                failureTaxonomy.shouldDeferRendererPacketFailureTaxonomy == false
        )
    let taxonomyInconsistent = (
        failureTaxonomy.didClassifyRendererPacketFailureTaxonomy &&
            (
                failureTaxonomy.didPreserveRendererPacketNormalizationResult == false ||
                failureTaxonomy.didKeepFailureTaxonomyValueOnly == false ||
                failureTaxonomy.didAvoidExceptionThrowing == false ||
                failureTaxonomy.didAvoidErrorPublication == false ||
                failureTaxonomy.didAvoidExternalNotification == false ||
                failureTaxonomy.shouldDeferRendererPacketFailureTaxonomy
            )
        ) ||
        (failureTaxonomy.shouldDeferRendererPacketFailureTaxonomy &&
            failureTaxonomy.shouldReportRendererPacketFailureTaxonomyBlocked)

    // failure taxonomy 已阻塞或不一致时，degraded reason 不能伪造成通过。
    if (taxonomyBlocked || taxonomyInconsistent) {
        return CjguiInternalRendererPacketDegradedReason(
            failureTaxonomy,
            true,
            false,
            false,
            true,
            true,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (taxonomyReady) {
        return CjguiInternalRendererPacketDegradedReason(
            failureTaxonomy,
            true,
            true,
            false,
            false,
            true,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (taxonomyDeferred) {
        return CjguiInternalRendererPacketDegradedReason(
            failureTaxonomy,
            false,
            false,
            true,
            false,
            true,
            false,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererPacketDegradedReason(
        failureTaxonomy,
        true,
        false,
        false,
        true,
        true,
        false,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererPacketBlockedReason(
    degradedReason: CjguiInternalRendererPacketDegradedReason
): CjguiInternalRendererPacketBlockedReason {
    let degradedReady = degradedReason.didClassifyRendererPacketDegradedReason &&
        degradedReason.isRendererPacketDegradedReasonAbsent &&
        degradedReason.didPreserveRendererPacketFailureTaxonomy &&
        degradedReason.didKeepDegradedReasonValueOnly &&
        degradedReason.didAvoidExceptionThrowing &&
        degradedReason.didAvoidErrorPublication &&
        degradedReason.didAvoidExternalNotification &&
        degradedReason.shouldDeferRendererPacketDegradedReason == false &&
        degradedReason.shouldReportRendererPacketDegradedReasonBlocked == false
    let degradedDeferred = degradedReason.didClassifyRendererPacketDegradedReason == false &&
        degradedReason.shouldDeferRendererPacketDegradedReason &&
        degradedReason.shouldReportRendererPacketDegradedReasonBlocked == false
    let degradedBlocked = degradedReason.shouldReportRendererPacketDegradedReasonBlocked ||
        (
            degradedReason.didClassifyRendererPacketDegradedReason &&
                degradedReason.isRendererPacketDegradedReasonAbsent == false &&
                degradedReason.shouldDeferRendererPacketDegradedReason == false
        )
    let degradedInconsistent = (
        degradedReason.didClassifyRendererPacketDegradedReason &&
            (
                degradedReason.didPreserveRendererPacketFailureTaxonomy == false ||
                degradedReason.didKeepDegradedReasonValueOnly == false ||
                degradedReason.didAvoidExceptionThrowing == false ||
                degradedReason.didAvoidErrorPublication == false ||
                degradedReason.didAvoidExternalNotification == false ||
                degradedReason.shouldDeferRendererPacketDegradedReason
            )
        ) ||
        (degradedReason.shouldDeferRendererPacketDegradedReason &&
            degradedReason.shouldReportRendererPacketDegradedReasonBlocked)

    // degraded reason 阻塞或不一致时，blocked reason 记录 fail-closed 分类。
    if (degradedBlocked || degradedInconsistent) {
        return CjguiInternalRendererPacketBlockedReason(
            degradedReason,
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

    if (degradedReady) {
        return CjguiInternalRendererPacketBlockedReason(
            degradedReason,
            true,
            true,
            false,
            false,
            true,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (degradedDeferred) {
        return CjguiInternalRendererPacketBlockedReason(
            degradedReason,
            false,
            false,
            true,
            false,
            true,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    return CjguiInternalRendererPacketBlockedReason(
        degradedReason,
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

func cjguiInternalBuildRendererPacketErrorTaxonomyResult(
    blockedReason: CjguiInternalRendererPacketBlockedReason
): CjguiInternalRendererPacketErrorTaxonomyResult {
    let taxonomyReady = blockedReason.didClassifyRendererPacketBlockedReason &&
        blockedReason.isRendererPacketBlockedReasonAbsent &&
        blockedReason.didPreserveRendererPacketDegradedReason &&
        blockedReason.didKeepBlockedReasonValueOnly &&
        blockedReason.didAvoidExceptionThrowing &&
        blockedReason.didAvoidErrorPublication &&
        blockedReason.didAvoidExternalNotification &&
        blockedReason.shouldDeferRendererPacketBlockedReason == false &&
        blockedReason.shouldReportRendererPacketBlockedReasonBlocked == false
    let taxonomyDeferred = blockedReason.didClassifyRendererPacketBlockedReason == false &&
        blockedReason.shouldDeferRendererPacketBlockedReason &&
        blockedReason.shouldReportRendererPacketBlockedReasonBlocked == false
    let taxonomyInconsistent = (
        blockedReason.didClassifyRendererPacketBlockedReason &&
            (
                blockedReason.didPreserveRendererPacketDegradedReason == false ||
                blockedReason.didKeepBlockedReasonValueOnly == false ||
                blockedReason.didAvoidExceptionThrowing == false ||
                blockedReason.didAvoidErrorPublication == false ||
                blockedReason.didAvoidExternalNotification == false ||
                blockedReason.shouldDeferRendererPacketBlockedReason
            )
        ) ||
        (blockedReason.shouldDeferRendererPacketBlockedReason &&
            blockedReason.shouldReportRendererPacketBlockedReasonBlocked)

    // taxonomy result 只表达内部分类；blocked / inconsistent 不得伪造成可继续。
    if (
        blockedReason.shouldReportRendererPacketBlockedReasonBlocked ||
        taxonomyInconsistent
    ) {
        return CjguiInternalRendererPacketErrorTaxonomyResult(
            blockedReason,
            false,
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
            true
        )
    }

    if (taxonomyReady) {
        return CjguiInternalRendererPacketErrorTaxonomyResult(
            blockedReason,
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
            true,
            true
        )
    }

    if (taxonomyDeferred) {
        return CjguiInternalRendererPacketErrorTaxonomyResult(
            blockedReason,
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
            true,
            true
        )
    }

    return CjguiInternalRendererPacketErrorTaxonomyResult(
        blockedReason,
        false,
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
        true
    )
}

func cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft(
): CjguiInternalRendererPacketErrorTaxonomyResult {
    // 默认 taxonomy draft 只串联 normalization result -> failure / degraded / blocked 分类 facts；
    // 它不抛异常、不发布错误、不触发外部通知，也不触发绘制。
    let normalizationResult = cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()
    let failureTaxonomy = cjguiInternalBuildRendererPacketFailureTaxonomy(normalizationResult)
    let degradedReason = cjguiInternalBuildRendererPacketDegradedReason(failureTaxonomy)
    let blockedReason = cjguiInternalBuildRendererPacketBlockedReason(degradedReason)
    return cjguiInternalBuildRendererPacketErrorTaxonomyResult(blockedReason)
}

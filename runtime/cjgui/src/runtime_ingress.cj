package cjgui

struct CjguiInternalRuntimeIngressCoordinator {
    let inputIngress: CjguiInternalInputRuntimeIngress
    let schedulerIngress: CjguiInternalSchedulerRuntimeIngress
    let canEnterRuntimeIngressFrontDoor: Bool
    let hasInputIngressCandidate: Bool
    let hasSchedulerPacingCandidate: Bool
    let shouldDeferRuntimeIngress: Bool
    let shouldReportRuntimeIngressBlocked: Bool

    init(
        inputIngress: CjguiInternalInputRuntimeIngress,
        schedulerIngress: CjguiInternalSchedulerRuntimeIngress,
        canEnterRuntimeIngressFrontDoor: Bool,
        hasInputIngressCandidate: Bool,
        hasSchedulerPacingCandidate: Bool,
        shouldDeferRuntimeIngress: Bool,
        shouldReportRuntimeIngressBlocked: Bool
    ) {
        this.inputIngress = inputIngress
        this.schedulerIngress = schedulerIngress
        this.canEnterRuntimeIngressFrontDoor = canEnterRuntimeIngressFrontDoor
        this.hasInputIngressCandidate = hasInputIngressCandidate
        this.hasSchedulerPacingCandidate = hasSchedulerPacingCandidate
        this.shouldDeferRuntimeIngress = shouldDeferRuntimeIngress
        this.shouldReportRuntimeIngressBlocked = shouldReportRuntimeIngressBlocked
    }
}

func cjguiInternalCoordinateRuntimeIngress(
    inputIngress: CjguiInternalInputRuntimeIngress,
    schedulerIngress: CjguiInternalSchedulerRuntimeIngress
): CjguiInternalRuntimeIngressCoordinator {
    let inputCandidate = inputIngress.canEnterRuntimeIngress &&
        inputIngress.shouldDeferRuntimeIngress == false &&
        inputIngress.shouldReportRuntimeIngressBlocked == false &&
        inputIngress.didPreserveRuntimeIngressCandidate
    let inputDeferred = inputIngress.canEnterRuntimeIngress == false &&
        inputIngress.didPreserveRuntimeIngressCandidate == false &&
        inputIngress.shouldDeferRuntimeIngress &&
        inputIngress.shouldReportRuntimeIngressBlocked == false
    let inputInconsistent = (
        inputIngress.canEnterRuntimeIngress &&
            (inputIngress.shouldDeferRuntimeIngress ||
                inputIngress.shouldReportRuntimeIngressBlocked)
        ) ||
        (inputIngress.didPreserveRuntimeIngressCandidate &&
            inputIngress.canEnterRuntimeIngress == false) ||
        (inputIngress.didPreserveRuntimeIngressCandidate == false &&
            inputIngress.canEnterRuntimeIngress) ||
        (inputIngress.shouldDeferRuntimeIngress &&
            inputIngress.shouldReportRuntimeIngressBlocked)
    let schedulerCandidate = schedulerIngress.canEnterRuntimePacing &&
        schedulerIngress.shouldDeferRuntimePacing == false &&
        schedulerIngress.shouldReportRuntimePacingBlocked == false &&
        schedulerIngress.didPreserveSchedulerTick
    let schedulerDeferred = schedulerIngress.canEnterRuntimePacing == false &&
        schedulerIngress.didPreserveSchedulerTick == false &&
        schedulerIngress.shouldDeferRuntimePacing &&
        schedulerIngress.shouldReportRuntimePacingBlocked == false
    let schedulerInconsistent = (
        schedulerIngress.canEnterRuntimePacing &&
            (schedulerIngress.shouldDeferRuntimePacing ||
                schedulerIngress.shouldReportRuntimePacingBlocked)
        ) ||
        (schedulerIngress.didPreserveSchedulerTick &&
            schedulerIngress.canEnterRuntimePacing == false) ||
        (schedulerIngress.didPreserveSchedulerTick == false &&
            schedulerIngress.canEnterRuntimePacing) ||
        (schedulerIngress.shouldDeferRuntimePacing &&
            schedulerIngress.shouldReportRuntimePacingBlocked)
    let canEnter = inputCandidate && schedulerCandidate
    let shouldDefer = canEnter == false &&
        inputInconsistent == false &&
        schedulerInconsistent == false &&
        inputIngress.shouldReportRuntimeIngressBlocked == false &&
        schedulerIngress.shouldReportRuntimePacingBlocked == false &&
        (inputDeferred || schedulerDeferred)
    if (canEnter) {
        return CjguiInternalRuntimeIngressCoordinator(
            inputIngress,
            schedulerIngress,
            true,
            true,
            true,
            false,
            false
        )
    }
    return CjguiInternalRuntimeIngressCoordinator(
        inputIngress,
        schedulerIngress,
        false,
        inputCandidate,
        schedulerCandidate,
        shouldDefer,
        shouldDefer == false
    )
}

func cjguiInternalExecuteDefaultRuntimeIngressCoordinatorDraft(
): CjguiInternalRuntimeIngressCoordinator {
    let inputIngress = cjguiInternalExecuteDefaultInputRuntimeIngressDraft()
    let schedulerIngress = cjguiInternalExecuteDefaultSchedulerRuntimeIngressDraft()
    return cjguiInternalCoordinateRuntimeIngress(
        inputIngress,
        schedulerIngress
    )
}

func cjguiInternalRuntimeIngressCoordinatorCanEnter(
    coordinator: CjguiInternalRuntimeIngressCoordinator
): Bool {
    return coordinator.canEnterRuntimeIngressFrontDoor
}

func cjguiInternalRuntimeIngressCoordinatorShouldReportBlocked(
    coordinator: CjguiInternalRuntimeIngressCoordinator
): Bool {
    return coordinator.shouldReportRuntimeIngressBlocked
}

package cjgui

// Internal runtime ingress owner:
// - This file owns the first front-door coordination summary between input
//   ingress and scheduler ingress.
// - Its truth is already-dehydrated input/scheduler readiness facts; it does
//   not own input semantics, scheduler ticks, queue admission, runtime state,
//   app lifecycle, window lifecycle, or platform truth.
// - It outputs only an internal ingress coordinator summary for downstream
//   queue/action boundaries.
// - Stop-line: no event loop, no queue drain, no scheduler driving, no action
//   execution, no platform bridge, no public runtime API, and no public C ABI.

// Coordinator is a value summary of two upstream ingress facts. It is not a
// runtime state machine and does not mutate either upstream owner.
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
    // Any non-ready path that is not a clean deferral is reported as blocked.
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
    // Default draft only chains existing default value facts; it does not run a loop.
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

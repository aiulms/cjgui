package cjgui

// Internal queue admission owner:
// - This file owns the first dehydrated queue-boundary admission summary.
// - Its truth is runtime ingress readiness plus local admission policy facts;
//   it does not own runtime state, scheduler ticks, app/window lifecycle,
//   platform runloop truth, action execution, or queue drain behavior.
// - It outputs only internal queue admission Bool summaries for downstream
//   action routing.
// - Stop-line: no real queue storage, no drain, no event loop, no scheduler
//   driving, no action execution, no public runtime API, and no public C ABI.

// Policy is a local value fact for admission rules, not a queue implementation.
struct CjguiInternalQueueAdmissionPolicy {
    let requiresIngressFrontDoorReady: Bool
    let allowsDeferredAdmission: Bool

    init() {
        this.requiresIngressFrontDoorReady = true
        this.allowsDeferredAdmission = false
    }

    init(requiresIngressFrontDoorReady: Bool, allowsDeferredAdmission: Bool) {
        this.requiresIngressFrontDoorReady = requiresIngressFrontDoorReady
        this.allowsDeferredAdmission = allowsDeferredAdmission
    }
}

// Admission is a boundary summary over ingress facts and policy facts.
struct CjguiInternalQueueAdmission {
    let ingress: CjguiInternalRuntimeIngressCoordinator
    let policy: CjguiInternalQueueAdmissionPolicy
    let canAdmitToQueueBoundary: Bool
    let shouldDeferQueueAdmission: Bool
    let shouldReportQueueAdmissionBlocked: Bool
    let didPreserveIngressCandidate: Bool

    init(
        ingress: CjguiInternalRuntimeIngressCoordinator,
        policy: CjguiInternalQueueAdmissionPolicy,
        canAdmitToQueueBoundary: Bool,
        shouldDeferQueueAdmission: Bool,
        shouldReportQueueAdmissionBlocked: Bool,
        didPreserveIngressCandidate: Bool
    ) {
        this.ingress = ingress
        this.policy = policy
        this.canAdmitToQueueBoundary = canAdmitToQueueBoundary
        this.shouldDeferQueueAdmission = shouldDeferQueueAdmission
        this.shouldReportQueueAdmissionBlocked = shouldReportQueueAdmissionBlocked
        this.didPreserveIngressCandidate = didPreserveIngressCandidate
    }
}

func cjguiInternalDefaultQueueAdmissionPolicy(): CjguiInternalQueueAdmissionPolicy {
    return CjguiInternalQueueAdmissionPolicy()
}

func cjguiInternalEvaluateQueueAdmission(
    ingress: CjguiInternalRuntimeIngressCoordinator,
    policy: CjguiInternalQueueAdmissionPolicy
): CjguiInternalQueueAdmission {
    let ingressReady = ingress.canEnterRuntimeIngressFrontDoor &&
        ingress.hasInputIngressCandidate &&
        ingress.hasSchedulerPacingCandidate &&
        ingress.shouldDeferRuntimeIngress == false &&
        ingress.shouldReportRuntimeIngressBlocked == false
    let ingressDeferred = ingress.canEnterRuntimeIngressFrontDoor == false &&
        ingress.shouldDeferRuntimeIngress &&
        ingress.shouldReportRuntimeIngressBlocked == false
    let ingressInconsistent = (
        ingress.canEnterRuntimeIngressFrontDoor &&
            (ingress.shouldDeferRuntimeIngress ||
                ingress.shouldReportRuntimeIngressBlocked)
        ) ||
        (ingress.canEnterRuntimeIngressFrontDoor &&
            (
                ingress.hasInputIngressCandidate == false ||
                ingress.hasSchedulerPacingCandidate == false
            )
        ) ||
        (ingress.shouldDeferRuntimeIngress &&
            ingress.shouldReportRuntimeIngressBlocked)
    let policyInconsistent = policy.requiresIngressFrontDoorReady == false &&
        policy.allowsDeferredAdmission == false
    let canAdmit = ingressReady &&
        policy.requiresIngressFrontDoorReady &&
        policyInconsistent == false &&
        ingressInconsistent == false
    let shouldDefer = canAdmit == false &&
        ingressInconsistent == false &&
        policyInconsistent == false &&
        ingressDeferred &&
        policy.allowsDeferredAdmission
    if (canAdmit) {
        return CjguiInternalQueueAdmission(
            ingress,
            policy,
            true,
            false,
            false,
            true
        )
    }
    // Inconsistent or non-deferred queue facts fail closed as blocked.
    return CjguiInternalQueueAdmission(
        ingress,
        policy,
        false,
        shouldDefer,
        shouldDefer == false,
        false
    )
}

func cjguiInternalExecuteDefaultQueueAdmissionDraft(): CjguiInternalQueueAdmission {
    // Default draft evaluates value facts only; it does not enqueue or drain work.
    let ingress = cjguiInternalExecuteDefaultRuntimeIngressCoordinatorDraft()
    let policy = cjguiInternalDefaultQueueAdmissionPolicy()
    return cjguiInternalEvaluateQueueAdmission(ingress, policy)
}

func cjguiInternalQueueAdmissionCanAdmit(admission: CjguiInternalQueueAdmission): Bool {
    return admission.canAdmitToQueueBoundary
}

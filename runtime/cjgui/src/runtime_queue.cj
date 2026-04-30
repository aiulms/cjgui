package cjgui

// Internal-only dehydrated queue admission facts. This file owns queue
// readiness so runtime_state.cj does not keep growing for new subsystems.
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
    let ingress = cjguiInternalExecuteDefaultRuntimeIngressCoordinatorDraft()
    let policy = cjguiInternalDefaultQueueAdmissionPolicy()
    return cjguiInternalEvaluateQueueAdmission(ingress, policy)
}

func cjguiInternalQueueAdmissionCanAdmit(admission: CjguiInternalQueueAdmission): Bool {
    return admission.canAdmitToQueueBoundary
}

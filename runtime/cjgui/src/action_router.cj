package cjgui

// Internal-only dehydrated action facts. This file owns the first Action Router
// slice so runtime_state.cj does not keep growing for new subsystems.
struct CjguiInternalActionSource {
    let isHumanOrigin: Bool
    let isAgentOrigin: Bool
    let isSystemOrigin: Bool

    init() {
        this.isHumanOrigin = false
        this.isAgentOrigin = false
        this.isSystemOrigin = true
    }

    init(isHumanOrigin: Bool, isAgentOrigin: Bool, isSystemOrigin: Bool) {
        this.isHumanOrigin = isHumanOrigin
        this.isAgentOrigin = isAgentOrigin
        this.isSystemOrigin = isSystemOrigin
    }
}

struct CjguiInternalActionKind {
    let isInputAction: Bool
    let isSchedulerAction: Bool
    let isRuntimeBoundaryAction: Bool
    let isDiagnosticAction: Bool

    init() {
        this.isInputAction = false
        this.isSchedulerAction = false
        this.isRuntimeBoundaryAction = true
        this.isDiagnosticAction = false
    }

    init(
        isInputAction: Bool,
        isSchedulerAction: Bool,
        isRuntimeBoundaryAction: Bool,
        isDiagnosticAction: Bool
    ) {
        this.isInputAction = isInputAction
        this.isSchedulerAction = isSchedulerAction
        this.isRuntimeBoundaryAction = isRuntimeBoundaryAction
        this.isDiagnosticAction = isDiagnosticAction
    }
}

struct CjguiInternalActionIntent {
    let source: CjguiInternalActionSource
    let kind: CjguiInternalActionKind
    let isActionIntentPresent: Bool

    init(
        source: CjguiInternalActionSource,
        kind: CjguiInternalActionKind,
        isActionIntentPresent: Bool
    ) {
        this.source = source
        this.kind = kind
        this.isActionIntentPresent = isActionIntentPresent
    }
}

struct CjguiInternalActionAdmission {
    let intent: CjguiInternalActionIntent
    let queueAdmission: CjguiInternalQueueAdmission
    let canAdmitActionIntent: Bool
    let shouldDeferActionIntent: Bool
    let shouldReportActionIntentBlocked: Bool
    let didPreserveActionIntent: Bool

    init(
        intent: CjguiInternalActionIntent,
        queueAdmission: CjguiInternalQueueAdmission,
        canAdmitActionIntent: Bool,
        shouldDeferActionIntent: Bool,
        shouldReportActionIntentBlocked: Bool,
        didPreserveActionIntent: Bool
    ) {
        this.intent = intent
        this.queueAdmission = queueAdmission
        this.canAdmitActionIntent = canAdmitActionIntent
        this.shouldDeferActionIntent = shouldDeferActionIntent
        this.shouldReportActionIntentBlocked = shouldReportActionIntentBlocked
        this.didPreserveActionIntent = didPreserveActionIntent
    }
}

struct CjguiInternalActionRoutingResult {
    let admission: CjguiInternalActionAdmission
    let isRuntimeBoundaryRouteCandidate: Bool
    let shouldDeferActionRouting: Bool
    let shouldReportActionRoutingBlocked: Bool
    let didPreserveActionIntent: Bool

    init(
        admission: CjguiInternalActionAdmission,
        isRuntimeBoundaryRouteCandidate: Bool,
        shouldDeferActionRouting: Bool,
        shouldReportActionRoutingBlocked: Bool,
        didPreserveActionIntent: Bool
    ) {
        this.admission = admission
        this.isRuntimeBoundaryRouteCandidate = isRuntimeBoundaryRouteCandidate
        this.shouldDeferActionRouting = shouldDeferActionRouting
        this.shouldReportActionRoutingBlocked = shouldReportActionRoutingBlocked
        this.didPreserveActionIntent = didPreserveActionIntent
    }
}

struct CjguiInternalActionDispatchAdmission {
    let routing: CjguiInternalActionRoutingResult
    let canEnterDispatchBoundary: Bool
    let shouldDeferDispatch: Bool
    let shouldReportDispatchBlocked: Bool
    let didPreserveActionRoute: Bool

    init(
        routing: CjguiInternalActionRoutingResult,
        canEnterDispatchBoundary: Bool,
        shouldDeferDispatch: Bool,
        shouldReportDispatchBlocked: Bool,
        didPreserveActionRoute: Bool
    ) {
        this.routing = routing
        this.canEnterDispatchBoundary = canEnterDispatchBoundary
        this.shouldDeferDispatch = shouldDeferDispatch
        this.shouldReportDispatchBlocked = shouldReportDispatchBlocked
        this.didPreserveActionRoute = didPreserveActionRoute
    }
}

struct CjguiInternalActionDispatchPlan {
    let admission: CjguiInternalActionDispatchAdmission
    let shouldPlanDispatch: Bool
    let shouldDeferPlan: Bool
    let shouldReportPlanBlocked: Bool
    let didPreserveDispatchCandidate: Bool

    init(
        admission: CjguiInternalActionDispatchAdmission,
        shouldPlanDispatch: Bool,
        shouldDeferPlan: Bool,
        shouldReportPlanBlocked: Bool,
        didPreserveDispatchCandidate: Bool
    ) {
        this.admission = admission
        this.shouldPlanDispatch = shouldPlanDispatch
        this.shouldDeferPlan = shouldDeferPlan
        this.shouldReportPlanBlocked = shouldReportPlanBlocked
        this.didPreserveDispatchCandidate = didPreserveDispatchCandidate
    }
}

struct CjguiInternalActionDispatchConvergence {
    let plan: CjguiInternalActionDispatchPlan
    let didConvergeDispatchPlan: Bool
    let shouldDeferDispatchConvergence: Bool
    let shouldReportDispatchConvergenceBlocked: Bool
    let didPreserveDispatchCandidate: Bool

    init(
        plan: CjguiInternalActionDispatchPlan,
        didConvergeDispatchPlan: Bool,
        shouldDeferDispatchConvergence: Bool,
        shouldReportDispatchConvergenceBlocked: Bool,
        didPreserveDispatchCandidate: Bool
    ) {
        this.plan = plan
        this.didConvergeDispatchPlan = didConvergeDispatchPlan
        this.shouldDeferDispatchConvergence = shouldDeferDispatchConvergence
        this.shouldReportDispatchConvergenceBlocked = shouldReportDispatchConvergenceBlocked
        this.didPreserveDispatchCandidate = didPreserveDispatchCandidate
    }
}

struct CjguiInternalActionDispatchCommitCandidate {
    let convergence: CjguiInternalActionDispatchConvergence
    let canCommitDispatchCandidate: Bool
    let shouldDeferDispatchCommit: Bool
    let shouldReportDispatchCommitBlocked: Bool
    let didPreserveDispatchCandidate: Bool

    init(
        convergence: CjguiInternalActionDispatchConvergence,
        canCommitDispatchCandidate: Bool,
        shouldDeferDispatchCommit: Bool,
        shouldReportDispatchCommitBlocked: Bool,
        didPreserveDispatchCandidate: Bool
    ) {
        this.convergence = convergence
        this.canCommitDispatchCandidate = canCommitDispatchCandidate
        this.shouldDeferDispatchCommit = shouldDeferDispatchCommit
        this.shouldReportDispatchCommitBlocked = shouldReportDispatchCommitBlocked
        this.didPreserveDispatchCandidate = didPreserveDispatchCandidate
    }
}

struct CjguiInternalActionDispatchFinalization {
    let candidate: CjguiInternalActionDispatchCommitCandidate
    let didFinalizeDispatchBoundary: Bool
    let shouldDeferDispatchFinalization: Bool
    let shouldReportDispatchFinalizationBlocked: Bool

    init(
        candidate: CjguiInternalActionDispatchCommitCandidate,
        didFinalizeDispatchBoundary: Bool,
        shouldDeferDispatchFinalization: Bool,
        shouldReportDispatchFinalizationBlocked: Bool
    ) {
        this.candidate = candidate
        this.didFinalizeDispatchBoundary = didFinalizeDispatchBoundary
        this.shouldDeferDispatchFinalization = shouldDeferDispatchFinalization
        this.shouldReportDispatchFinalizationBlocked = shouldReportDispatchFinalizationBlocked
    }
}

struct CjguiInternalActionDispatchRecord {
    let finalization: CjguiInternalActionDispatchFinalization
    let didRecordDispatchBoundary: Bool
    let shouldDeferDispatchRecord: Bool
    let shouldReportDispatchRecordBlocked: Bool

    init(
        finalization: CjguiInternalActionDispatchFinalization,
        didRecordDispatchBoundary: Bool,
        shouldDeferDispatchRecord: Bool,
        shouldReportDispatchRecordBlocked: Bool
    ) {
        this.finalization = finalization
        this.didRecordDispatchBoundary = didRecordDispatchBoundary
        this.shouldDeferDispatchRecord = shouldDeferDispatchRecord
        this.shouldReportDispatchRecordBlocked = shouldReportDispatchRecordBlocked
    }
}

struct CjguiInternalActionEffectModel {
    let record: CjguiInternalActionDispatchRecord
    let isRuntimeBoundaryEffect: Bool
    let shouldDeferEffect: Bool
    let shouldReportEffectBlocked: Bool
    let didPreserveDispatchRecord: Bool

    init(
        record: CjguiInternalActionDispatchRecord,
        isRuntimeBoundaryEffect: Bool,
        shouldDeferEffect: Bool,
        shouldReportEffectBlocked: Bool,
        didPreserveDispatchRecord: Bool
    ) {
        this.record = record
        this.isRuntimeBoundaryEffect = isRuntimeBoundaryEffect
        this.shouldDeferEffect = shouldDeferEffect
        this.shouldReportEffectBlocked = shouldReportEffectBlocked
        this.didPreserveDispatchRecord = didPreserveDispatchRecord
    }
}

struct CjguiInternalActionExecutionGuard {
    let effect: CjguiInternalActionEffectModel
    let canEnterExecutionGuard: Bool
    let shouldDeferExecutionGuard: Bool
    let shouldReportExecutionGuardBlocked: Bool
    let didPreserveEffectModel: Bool

    init(
        effect: CjguiInternalActionEffectModel,
        canEnterExecutionGuard: Bool,
        shouldDeferExecutionGuard: Bool,
        shouldReportExecutionGuardBlocked: Bool,
        didPreserveEffectModel: Bool
    ) {
        this.effect = effect
        this.canEnterExecutionGuard = canEnterExecutionGuard
        this.shouldDeferExecutionGuard = shouldDeferExecutionGuard
        this.shouldReportExecutionGuardBlocked = shouldReportExecutionGuardBlocked
        this.didPreserveEffectModel = didPreserveEffectModel
    }
}

struct CjguiInternalActionExecutionReadiness {
    let guard: CjguiInternalActionExecutionGuard
    let isReadyForFutureExecution: Bool
    let shouldDeferFutureExecution: Bool
    let shouldReportFutureExecutionBlocked: Bool

    init(
        guard: CjguiInternalActionExecutionGuard,
        isReadyForFutureExecution: Bool,
        shouldDeferFutureExecution: Bool,
        shouldReportFutureExecutionBlocked: Bool
    ) {
        this.guard = guard
        this.isReadyForFutureExecution = isReadyForFutureExecution
        this.shouldDeferFutureExecution = shouldDeferFutureExecution
        this.shouldReportFutureExecutionBlocked = shouldReportFutureExecutionBlocked
    }
}

struct CjguiInternalActionExecutionAttempt {
    let readiness: CjguiInternalActionExecutionReadiness
    let didAttemptActionExecution: Bool
    let shouldDeferActionExecutionAttempt: Bool
    let shouldReportActionExecutionAttemptBlocked: Bool
    let didPreserveExecutionReadiness: Bool

    init(
        readiness: CjguiInternalActionExecutionReadiness,
        didAttemptActionExecution: Bool,
        shouldDeferActionExecutionAttempt: Bool,
        shouldReportActionExecutionAttemptBlocked: Bool,
        didPreserveExecutionReadiness: Bool
    ) {
        this.readiness = readiness
        this.didAttemptActionExecution = didAttemptActionExecution
        this.shouldDeferActionExecutionAttempt = shouldDeferActionExecutionAttempt
        this.shouldReportActionExecutionAttemptBlocked = shouldReportActionExecutionAttemptBlocked
        this.didPreserveExecutionReadiness = didPreserveExecutionReadiness
    }
}

struct CjguiInternalActionExecutionAttemptResult {
    let attempt: CjguiInternalActionExecutionAttempt
    let didAcceptActionExecutionAttempt: Bool
    let shouldDeferActionExecutionResult: Bool
    let shouldReportActionExecutionBlocked: Bool

    init(
        attempt: CjguiInternalActionExecutionAttempt,
        didAcceptActionExecutionAttempt: Bool,
        shouldDeferActionExecutionResult: Bool,
        shouldReportActionExecutionBlocked: Bool
    ) {
        this.attempt = attempt
        this.didAcceptActionExecutionAttempt = didAcceptActionExecutionAttempt
        this.shouldDeferActionExecutionResult = shouldDeferActionExecutionResult
        this.shouldReportActionExecutionBlocked = shouldReportActionExecutionBlocked
    }
}

func cjguiInternalDefaultActionSource(): CjguiInternalActionSource {
    return CjguiInternalActionSource()
}

func cjguiInternalDefaultActionKind(): CjguiInternalActionKind {
    return CjguiInternalActionKind()
}

func cjguiInternalBuildActionIntent(
    source: CjguiInternalActionSource,
    kind: CjguiInternalActionKind,
    isActionIntentPresent: Bool
): CjguiInternalActionIntent {
    return CjguiInternalActionIntent(source, kind, isActionIntentPresent)
}

func cjguiInternalActionSourceIsValid(source: CjguiInternalActionSource): Bool {
    return (
        source.isHumanOrigin &&
        source.isAgentOrigin == false &&
        source.isSystemOrigin == false
    ) || (
        source.isHumanOrigin == false &&
        source.isAgentOrigin &&
        source.isSystemOrigin == false
    ) || (
        source.isHumanOrigin == false &&
        source.isAgentOrigin == false &&
        source.isSystemOrigin
    )
}

func cjguiInternalActionKindIsValid(kind: CjguiInternalActionKind): Bool {
    return (
        kind.isInputAction &&
        kind.isSchedulerAction == false &&
        kind.isRuntimeBoundaryAction == false &&
        kind.isDiagnosticAction == false
    ) || (
        kind.isInputAction == false &&
        kind.isSchedulerAction &&
        kind.isRuntimeBoundaryAction == false &&
        kind.isDiagnosticAction == false
    ) || (
        kind.isInputAction == false &&
        kind.isSchedulerAction == false &&
        kind.isRuntimeBoundaryAction &&
        kind.isDiagnosticAction == false
    ) || (
        kind.isInputAction == false &&
        kind.isSchedulerAction == false &&
        kind.isRuntimeBoundaryAction == false &&
        kind.isDiagnosticAction
    )
}

func cjguiInternalEvaluateActionAdmission(
    intent: CjguiInternalActionIntent,
    queueAdmission: CjguiInternalQueueAdmission
): CjguiInternalActionAdmission {
    let queueReady = queueAdmission.canAdmitToQueueBoundary &&
        queueAdmission.shouldDeferQueueAdmission == false &&
        queueAdmission.shouldReportQueueAdmissionBlocked == false &&
        queueAdmission.didPreserveIngressCandidate
    let queueDeferred = queueAdmission.canAdmitToQueueBoundary == false &&
        queueAdmission.didPreserveIngressCandidate == false &&
        queueAdmission.shouldDeferQueueAdmission &&
        queueAdmission.shouldReportQueueAdmissionBlocked == false
    let queueInconsistent = (
        queueAdmission.canAdmitToQueueBoundary &&
            (queueAdmission.shouldDeferQueueAdmission ||
                queueAdmission.shouldReportQueueAdmissionBlocked)
        ) ||
        (queueAdmission.didPreserveIngressCandidate &&
            queueAdmission.canAdmitToQueueBoundary == false) ||
        (queueAdmission.didPreserveIngressCandidate == false &&
            queueAdmission.canAdmitToQueueBoundary) ||
        (queueAdmission.shouldDeferQueueAdmission &&
            queueAdmission.shouldReportQueueAdmissionBlocked)

    if (queueAdmission.shouldReportQueueAdmissionBlocked || queueInconsistent) {
        return CjguiInternalActionAdmission(intent, queueAdmission, false, false, true, false)
    }

    if (intent.isActionIntentPresent == false || queueDeferred) {
        return CjguiInternalActionAdmission(intent, queueAdmission, false, true, false, false)
    }

    if (
        cjguiInternalActionSourceIsValid(intent.source) &&
        cjguiInternalActionKindIsValid(intent.kind) &&
        queueReady
    ) {
        return CjguiInternalActionAdmission(intent, queueAdmission, true, false, false, true)
    }

    return CjguiInternalActionAdmission(intent, queueAdmission, false, false, true, false)
}

func cjguiInternalExecuteDefaultActionAdmissionDraft(): CjguiInternalActionAdmission {
    let source = cjguiInternalDefaultActionSource()
    let kind = cjguiInternalDefaultActionKind()
    let intent = cjguiInternalBuildActionIntent(source, kind, true)
    let queueAdmission = cjguiInternalExecuteDefaultQueueAdmissionDraft()
    return cjguiInternalEvaluateActionAdmission(intent, queueAdmission)
}

func cjguiInternalActionAdmissionCanAdmit(admission: CjguiInternalActionAdmission): Bool {
    return admission.canAdmitActionIntent
}

func cjguiInternalRouteActionAdmission(
    admission: CjguiInternalActionAdmission
): CjguiInternalActionRoutingResult {
    let admissionReady = admission.canAdmitActionIntent &&
        admission.didPreserveActionIntent &&
        admission.shouldDeferActionIntent == false &&
        admission.shouldReportActionIntentBlocked == false
    let admissionDeferred = admission.canAdmitActionIntent == false &&
        admission.didPreserveActionIntent == false &&
        admission.shouldDeferActionIntent &&
        admission.shouldReportActionIntentBlocked == false
    let admissionInconsistent = (
        admission.canAdmitActionIntent &&
            (admission.shouldDeferActionIntent ||
                admission.shouldReportActionIntentBlocked)
        ) ||
        (admission.didPreserveActionIntent &&
            admission.canAdmitActionIntent == false) ||
        (admission.didPreserveActionIntent == false &&
            admission.canAdmitActionIntent) ||
        (admission.shouldDeferActionIntent &&
            admission.shouldReportActionIntentBlocked)

    if (admission.shouldReportActionIntentBlocked || admissionInconsistent) {
        return CjguiInternalActionRoutingResult(admission, false, false, true, false)
    }

    if (admissionDeferred) {
        return CjguiInternalActionRoutingResult(admission, false, true, false, false)
    }

    if (admissionReady) {
        return CjguiInternalActionRoutingResult(admission, true, false, false, true)
    }

    return CjguiInternalActionRoutingResult(admission, false, false, true, false)
}

func cjguiInternalExecuteDefaultActionRoutingDraft(): CjguiInternalActionRoutingResult {
    let admission = cjguiInternalExecuteDefaultActionAdmissionDraft()
    return cjguiInternalRouteActionAdmission(admission)
}

func cjguiInternalActionRoutingCanRoute(result: CjguiInternalActionRoutingResult): Bool {
    return result.isRuntimeBoundaryRouteCandidate
}

func cjguiInternalActionRoutingShouldDefer(result: CjguiInternalActionRoutingResult): Bool {
    return result.shouldDeferActionRouting
}

func cjguiInternalActionRoutingShouldReportBlocked(result: CjguiInternalActionRoutingResult): Bool {
    return result.shouldReportActionRoutingBlocked
}

func cjguiInternalBuildActionDispatchAdmission(
    routing: CjguiInternalActionRoutingResult
): CjguiInternalActionDispatchAdmission {
    let routingReady = routing.isRuntimeBoundaryRouteCandidate &&
        routing.didPreserveActionIntent &&
        routing.shouldDeferActionRouting == false &&
        routing.shouldReportActionRoutingBlocked == false
    let routingDeferred = routing.isRuntimeBoundaryRouteCandidate == false &&
        routing.didPreserveActionIntent == false &&
        routing.shouldDeferActionRouting &&
        routing.shouldReportActionRoutingBlocked == false
    let routingInconsistent = (
        routing.isRuntimeBoundaryRouteCandidate &&
            (routing.shouldDeferActionRouting ||
                routing.shouldReportActionRoutingBlocked)
        ) ||
        (routing.didPreserveActionIntent &&
            routing.isRuntimeBoundaryRouteCandidate == false) ||
        (routing.didPreserveActionIntent == false &&
            routing.isRuntimeBoundaryRouteCandidate) ||
        (routing.shouldDeferActionRouting &&
            routing.shouldReportActionRoutingBlocked)

    if (routing.shouldReportActionRoutingBlocked || routingInconsistent) {
        return CjguiInternalActionDispatchAdmission(routing, false, false, true, false)
    }

    if (routingDeferred) {
        return CjguiInternalActionDispatchAdmission(routing, false, true, false, false)
    }

    if (routingReady) {
        return CjguiInternalActionDispatchAdmission(routing, true, false, false, true)
    }

    return CjguiInternalActionDispatchAdmission(routing, false, false, true, false)
}

func cjguiInternalExecuteDefaultActionDispatchAdmissionDraft(): CjguiInternalActionDispatchAdmission {
    let routing = cjguiInternalExecuteDefaultActionRoutingDraft()
    return cjguiInternalBuildActionDispatchAdmission(routing)
}

func cjguiInternalActionDispatchAdmissionCanDispatch(
    admission: CjguiInternalActionDispatchAdmission
): Bool {
    return admission.canEnterDispatchBoundary
}

func cjguiInternalBuildActionDispatchPlan(
    admission: CjguiInternalActionDispatchAdmission
): CjguiInternalActionDispatchPlan {
    let admissionReady = cjguiInternalActionDispatchAdmissionCanDispatch(admission) &&
        admission.didPreserveActionRoute &&
        admission.shouldDeferDispatch == false &&
        admission.shouldReportDispatchBlocked == false
    let admissionDeferred = admission.canEnterDispatchBoundary == false &&
        admission.didPreserveActionRoute == false &&
        admission.shouldDeferDispatch &&
        admission.shouldReportDispatchBlocked == false
    let admissionInconsistent = (
        admission.canEnterDispatchBoundary &&
            (admission.shouldDeferDispatch ||
                admission.shouldReportDispatchBlocked)
        ) ||
        (admission.didPreserveActionRoute &&
            admission.canEnterDispatchBoundary == false) ||
        (admission.didPreserveActionRoute == false &&
            admission.canEnterDispatchBoundary) ||
        (admission.shouldDeferDispatch &&
            admission.shouldReportDispatchBlocked)

    if (admission.shouldReportDispatchBlocked || admissionInconsistent) {
        return CjguiInternalActionDispatchPlan(admission, false, false, true, false)
    }

    if (admissionDeferred) {
        return CjguiInternalActionDispatchPlan(admission, false, true, false, false)
    }

    if (admissionReady) {
        return CjguiInternalActionDispatchPlan(admission, true, false, false, true)
    }

    return CjguiInternalActionDispatchPlan(admission, false, false, true, false)
}

func cjguiInternalExecuteDefaultActionDispatchPlanDraft(): CjguiInternalActionDispatchPlan {
    let admission = cjguiInternalExecuteDefaultActionDispatchAdmissionDraft()
    return cjguiInternalBuildActionDispatchPlan(admission)
}

func cjguiInternalActionDispatchPlanShouldDispatch(plan: CjguiInternalActionDispatchPlan): Bool {
    return plan.shouldPlanDispatch
}

func cjguiInternalBuildActionDispatchConvergence(
    plan: CjguiInternalActionDispatchPlan
): CjguiInternalActionDispatchConvergence {
    let planReady = cjguiInternalActionDispatchPlanShouldDispatch(plan) &&
        plan.didPreserveDispatchCandidate &&
        plan.shouldDeferPlan == false &&
        plan.shouldReportPlanBlocked == false
    let planDeferred = plan.shouldPlanDispatch == false &&
        plan.didPreserveDispatchCandidate == false &&
        plan.shouldDeferPlan &&
        plan.shouldReportPlanBlocked == false
    let planInconsistent = (
        plan.shouldPlanDispatch &&
            (plan.shouldDeferPlan || plan.shouldReportPlanBlocked)
        ) ||
        (plan.didPreserveDispatchCandidate &&
            plan.shouldPlanDispatch == false) ||
        (plan.didPreserveDispatchCandidate == false &&
            plan.shouldPlanDispatch) ||
        (plan.shouldDeferPlan && plan.shouldReportPlanBlocked)

    if (plan.shouldReportPlanBlocked || planInconsistent) {
        return CjguiInternalActionDispatchConvergence(plan, false, false, true, false)
    }

    if (planDeferred) {
        return CjguiInternalActionDispatchConvergence(plan, false, true, false, false)
    }

    if (planReady) {
        return CjguiInternalActionDispatchConvergence(plan, true, false, false, true)
    }

    return CjguiInternalActionDispatchConvergence(plan, false, false, true, false)
}

func cjguiInternalActionDispatchConvergenceDidConverge(
    convergence: CjguiInternalActionDispatchConvergence
): Bool {
    return convergence.didConvergeDispatchPlan
}

func cjguiInternalBuildActionDispatchCommitCandidate(
    convergence: CjguiInternalActionDispatchConvergence
): CjguiInternalActionDispatchCommitCandidate {
    let convergenceReady = cjguiInternalActionDispatchConvergenceDidConverge(convergence) &&
        convergence.didPreserveDispatchCandidate &&
        convergence.shouldDeferDispatchConvergence == false &&
        convergence.shouldReportDispatchConvergenceBlocked == false
    let convergenceDeferred = convergence.didConvergeDispatchPlan == false &&
        convergence.didPreserveDispatchCandidate == false &&
        convergence.shouldDeferDispatchConvergence &&
        convergence.shouldReportDispatchConvergenceBlocked == false
    let convergenceInconsistent = (
        convergence.didConvergeDispatchPlan &&
            (convergence.shouldDeferDispatchConvergence ||
                convergence.shouldReportDispatchConvergenceBlocked)
        ) ||
        (convergence.didPreserveDispatchCandidate &&
            convergence.didConvergeDispatchPlan == false) ||
        (convergence.didPreserveDispatchCandidate == false &&
            convergence.didConvergeDispatchPlan) ||
        (convergence.shouldDeferDispatchConvergence &&
            convergence.shouldReportDispatchConvergenceBlocked)

    if (convergence.shouldReportDispatchConvergenceBlocked || convergenceInconsistent) {
        return CjguiInternalActionDispatchCommitCandidate(convergence, false, false, true, false)
    }

    if (convergenceDeferred) {
        return CjguiInternalActionDispatchCommitCandidate(convergence, false, true, false, false)
    }

    if (convergenceReady) {
        return CjguiInternalActionDispatchCommitCandidate(convergence, true, false, false, true)
    }

    return CjguiInternalActionDispatchCommitCandidate(convergence, false, false, true, false)
}

func cjguiInternalActionDispatchCommitCandidateCanCommit(
    candidate: CjguiInternalActionDispatchCommitCandidate
): Bool {
    return candidate.canCommitDispatchCandidate
}

func cjguiInternalFinalizeActionDispatchCandidate(
    candidate: CjguiInternalActionDispatchCommitCandidate
): CjguiInternalActionDispatchFinalization {
    let candidateReady = cjguiInternalActionDispatchCommitCandidateCanCommit(candidate) &&
        candidate.didPreserveDispatchCandidate &&
        candidate.shouldDeferDispatchCommit == false &&
        candidate.shouldReportDispatchCommitBlocked == false
    let candidateDeferred = candidate.canCommitDispatchCandidate == false &&
        candidate.didPreserveDispatchCandidate == false &&
        candidate.shouldDeferDispatchCommit &&
        candidate.shouldReportDispatchCommitBlocked == false
    let candidateInconsistent = (
        candidate.canCommitDispatchCandidate &&
            (candidate.shouldDeferDispatchCommit ||
                candidate.shouldReportDispatchCommitBlocked)
        ) ||
        (candidate.didPreserveDispatchCandidate &&
            candidate.canCommitDispatchCandidate == false) ||
        (candidate.didPreserveDispatchCandidate == false &&
            candidate.canCommitDispatchCandidate) ||
        (candidate.shouldDeferDispatchCommit &&
            candidate.shouldReportDispatchCommitBlocked)

    if (candidate.shouldReportDispatchCommitBlocked || candidateInconsistent) {
        return CjguiInternalActionDispatchFinalization(candidate, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalActionDispatchFinalization(candidate, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalActionDispatchFinalization(candidate, true, false, false)
    }

    return CjguiInternalActionDispatchFinalization(candidate, false, false, true)
}

func cjguiInternalExecuteDefaultActionDispatchConvergenceDraft(
): CjguiInternalActionDispatchFinalization {
    let plan = cjguiInternalExecuteDefaultActionDispatchPlanDraft()
    let convergence = cjguiInternalBuildActionDispatchConvergence(plan)
    let candidate = cjguiInternalBuildActionDispatchCommitCandidate(convergence)
    return cjguiInternalFinalizeActionDispatchCandidate(candidate)
}

func cjguiInternalBuildActionDispatchRecord(
    finalization: CjguiInternalActionDispatchFinalization
): CjguiInternalActionDispatchRecord {
    let finalizationReady = finalization.didFinalizeDispatchBoundary &&
        finalization.shouldDeferDispatchFinalization == false &&
        finalization.shouldReportDispatchFinalizationBlocked == false
    let finalizationDeferred = finalization.didFinalizeDispatchBoundary == false &&
        finalization.shouldDeferDispatchFinalization &&
        finalization.shouldReportDispatchFinalizationBlocked == false
    let finalizationInconsistent = (
        finalization.didFinalizeDispatchBoundary &&
            (finalization.shouldDeferDispatchFinalization ||
                finalization.shouldReportDispatchFinalizationBlocked)
        ) ||
        (finalization.shouldDeferDispatchFinalization &&
            finalization.shouldReportDispatchFinalizationBlocked)

    if (finalization.shouldReportDispatchFinalizationBlocked || finalizationInconsistent) {
        return CjguiInternalActionDispatchRecord(finalization, false, false, true)
    }

    if (finalizationDeferred) {
        return CjguiInternalActionDispatchRecord(finalization, false, true, false)
    }

    if (finalizationReady) {
        return CjguiInternalActionDispatchRecord(finalization, true, false, false)
    }

    return CjguiInternalActionDispatchRecord(finalization, false, false, true)
}

func cjguiInternalExecuteDefaultActionDispatchRecordDraft(): CjguiInternalActionDispatchRecord {
    let finalization = cjguiInternalExecuteDefaultActionDispatchConvergenceDraft()
    return cjguiInternalBuildActionDispatchRecord(finalization)
}

func cjguiInternalActionDispatchRecordDidRecord(
    record: CjguiInternalActionDispatchRecord
): Bool {
    return record.didRecordDispatchBoundary
}

func cjguiInternalBuildActionEffectModel(
    record: CjguiInternalActionDispatchRecord
): CjguiInternalActionEffectModel {
    let recordReady = cjguiInternalActionDispatchRecordDidRecord(record) &&
        record.shouldDeferDispatchRecord == false &&
        record.shouldReportDispatchRecordBlocked == false
    let recordDeferred = record.didRecordDispatchBoundary == false &&
        record.shouldDeferDispatchRecord &&
        record.shouldReportDispatchRecordBlocked == false
    let recordInconsistent = (
        record.didRecordDispatchBoundary &&
            (record.shouldDeferDispatchRecord ||
                record.shouldReportDispatchRecordBlocked)
        ) ||
        (record.shouldDeferDispatchRecord &&
            record.shouldReportDispatchRecordBlocked)

    if (record.shouldReportDispatchRecordBlocked || recordInconsistent) {
        return CjguiInternalActionEffectModel(record, false, false, true, false)
    }

    if (recordDeferred) {
        return CjguiInternalActionEffectModel(record, false, true, false, false)
    }

    if (recordReady) {
        return CjguiInternalActionEffectModel(record, true, false, false, true)
    }

    return CjguiInternalActionEffectModel(record, false, false, true, false)
}

func cjguiInternalActionEffectModelIsReady(effect: CjguiInternalActionEffectModel): Bool {
    return effect.isRuntimeBoundaryEffect
}

func cjguiInternalBuildActionExecutionGuard(
    effect: CjguiInternalActionEffectModel
): CjguiInternalActionExecutionGuard {
    let effectReady = cjguiInternalActionEffectModelIsReady(effect) &&
        effect.didPreserveDispatchRecord &&
        effect.shouldDeferEffect == false &&
        effect.shouldReportEffectBlocked == false
    let effectDeferred = effect.isRuntimeBoundaryEffect == false &&
        effect.didPreserveDispatchRecord == false &&
        effect.shouldDeferEffect &&
        effect.shouldReportEffectBlocked == false
    let effectInconsistent = (
        effect.isRuntimeBoundaryEffect &&
            (effect.shouldDeferEffect ||
                effect.shouldReportEffectBlocked)
        ) ||
        (effect.didPreserveDispatchRecord &&
            effect.isRuntimeBoundaryEffect == false) ||
        (effect.didPreserveDispatchRecord == false &&
            effect.isRuntimeBoundaryEffect) ||
        (effect.shouldDeferEffect &&
            effect.shouldReportEffectBlocked)

    if (effect.shouldReportEffectBlocked || effectInconsistent) {
        return CjguiInternalActionExecutionGuard(effect, false, false, true, false)
    }

    if (effectDeferred) {
        return CjguiInternalActionExecutionGuard(effect, false, true, false, false)
    }

    if (effectReady) {
        return CjguiInternalActionExecutionGuard(effect, true, false, false, true)
    }

    return CjguiInternalActionExecutionGuard(effect, false, false, true, false)
}

func cjguiInternalActionExecutionGuardCanEnter(
    guard: CjguiInternalActionExecutionGuard
): Bool {
    return guard.canEnterExecutionGuard
}

func cjguiInternalBuildActionExecutionReadiness(
    guard: CjguiInternalActionExecutionGuard
): CjguiInternalActionExecutionReadiness {
    let guardReady = cjguiInternalActionExecutionGuardCanEnter(guard) &&
        guard.didPreserveEffectModel &&
        guard.shouldDeferExecutionGuard == false &&
        guard.shouldReportExecutionGuardBlocked == false
    let guardDeferred = guard.canEnterExecutionGuard == false &&
        guard.didPreserveEffectModel == false &&
        guard.shouldDeferExecutionGuard &&
        guard.shouldReportExecutionGuardBlocked == false
    let guardInconsistent = (
        guard.canEnterExecutionGuard &&
            (guard.shouldDeferExecutionGuard ||
                guard.shouldReportExecutionGuardBlocked)
        ) ||
        (guard.didPreserveEffectModel &&
            guard.canEnterExecutionGuard == false) ||
        (guard.didPreserveEffectModel == false &&
            guard.canEnterExecutionGuard) ||
        (guard.shouldDeferExecutionGuard &&
            guard.shouldReportExecutionGuardBlocked)

    if (guard.shouldReportExecutionGuardBlocked || guardInconsistent) {
        return CjguiInternalActionExecutionReadiness(guard, false, false, true)
    }

    if (guardDeferred) {
        return CjguiInternalActionExecutionReadiness(guard, false, true, false)
    }

    if (guardReady) {
        return CjguiInternalActionExecutionReadiness(guard, true, false, false)
    }

    return CjguiInternalActionExecutionReadiness(guard, false, false, true)
}

func cjguiInternalActionExecutionReadinessIsReady(
    readiness: CjguiInternalActionExecutionReadiness
): Bool {
    return readiness.isReadyForFutureExecution
}

func cjguiInternalExecuteDefaultActionExecutionReadinessDraft(
): CjguiInternalActionExecutionReadiness {
    let record = cjguiInternalExecuteDefaultActionDispatchRecordDraft()
    let effect = cjguiInternalBuildActionEffectModel(record)
    let guard = cjguiInternalBuildActionExecutionGuard(effect)
    return cjguiInternalBuildActionExecutionReadiness(guard)
}

func cjguiInternalBuildActionExecutionAttempt(
    readiness: CjguiInternalActionExecutionReadiness
): CjguiInternalActionExecutionAttempt {
    let readinessReady = cjguiInternalActionExecutionReadinessIsReady(readiness) &&
        readiness.shouldDeferFutureExecution == false &&
        readiness.shouldReportFutureExecutionBlocked == false
    let readinessDeferred = readiness.isReadyForFutureExecution == false &&
        readiness.shouldDeferFutureExecution &&
        readiness.shouldReportFutureExecutionBlocked == false
    let readinessInconsistent = (
        readiness.isReadyForFutureExecution &&
            (readiness.shouldDeferFutureExecution ||
                readiness.shouldReportFutureExecutionBlocked)
        ) ||
        (readiness.shouldDeferFutureExecution &&
            readiness.shouldReportFutureExecutionBlocked)

    if (readiness.shouldReportFutureExecutionBlocked || readinessInconsistent) {
        return CjguiInternalActionExecutionAttempt(readiness, false, false, true, false)
    }

    if (readinessDeferred) {
        return CjguiInternalActionExecutionAttempt(readiness, false, true, false, false)
    }

    if (readinessReady) {
        return CjguiInternalActionExecutionAttempt(readiness, true, false, false, true)
    }

    return CjguiInternalActionExecutionAttempt(readiness, false, false, true, false)
}

func cjguiInternalActionExecutionAttemptDidAttempt(
    attempt: CjguiInternalActionExecutionAttempt
): Bool {
    return attempt.didAttemptActionExecution
}

func cjguiInternalEvaluateActionExecutionAttempt(
    attempt: CjguiInternalActionExecutionAttempt
): CjguiInternalActionExecutionAttemptResult {
    let attemptAccepted = cjguiInternalActionExecutionAttemptDidAttempt(attempt) &&
        attempt.didPreserveExecutionReadiness &&
        attempt.shouldDeferActionExecutionAttempt == false &&
        attempt.shouldReportActionExecutionAttemptBlocked == false
    let attemptDeferred = attempt.didAttemptActionExecution == false &&
        attempt.didPreserveExecutionReadiness == false &&
        attempt.shouldDeferActionExecutionAttempt &&
        attempt.shouldReportActionExecutionAttemptBlocked == false
    let attemptInconsistent = (
        attempt.didAttemptActionExecution &&
            (attempt.shouldDeferActionExecutionAttempt ||
                attempt.shouldReportActionExecutionAttemptBlocked)
        ) ||
        (attempt.didPreserveExecutionReadiness &&
            attempt.didAttemptActionExecution == false) ||
        (attempt.didPreserveExecutionReadiness == false &&
            attempt.didAttemptActionExecution) ||
        (attempt.shouldDeferActionExecutionAttempt &&
            attempt.shouldReportActionExecutionAttemptBlocked)

    if (attempt.shouldReportActionExecutionAttemptBlocked || attemptInconsistent) {
        return CjguiInternalActionExecutionAttemptResult(attempt, false, false, true)
    }

    if (attemptDeferred) {
        return CjguiInternalActionExecutionAttemptResult(attempt, false, true, false)
    }

    if (attemptAccepted) {
        return CjguiInternalActionExecutionAttemptResult(attempt, true, false, false)
    }

    return CjguiInternalActionExecutionAttemptResult(attempt, false, false, true)
}

func cjguiInternalActionExecutionAttemptResultDidAccept(
    result: CjguiInternalActionExecutionAttemptResult
): Bool {
    return result.didAcceptActionExecutionAttempt
}

func cjguiInternalExecuteDefaultActionExecutionAttemptDraft(
): CjguiInternalActionExecutionAttemptResult {
    let readiness = cjguiInternalExecuteDefaultActionExecutionReadinessDraft()
    let attempt = cjguiInternalBuildActionExecutionAttempt(readiness)
    return cjguiInternalEvaluateActionExecutionAttempt(attempt)
}

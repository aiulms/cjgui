package cjgui

// Internal scheduler ingress owner:
// - This file owns the first dehydrated scheduler tick and runtime pacing
//   admission summaries.
// - Its truth is local tick intent facts plus runtime state-store transition
//   facts; it does not own frame scheduling, render invalidation, event loops,
//   queue drain, action execution, app/window lifecycle, or platform runloop.
// - It outputs only internal scheduler ingress Bool summaries for runtime
//   ingress coordination.
// - Stop-line: no real scheduler, no frame loop, no timer, no queue drain, no
//   platform bridge, no public runtime API, and no public C ABI.

// Tick source is a dehydrated origin fact. Exactly one source should be true.
struct CjguiInternalSchedulerTickSource {
    let isSynthetic: Bool
    let isFramePacing: Bool
    let isDeferredWork: Bool

    init() {
        this.isSynthetic = true
        this.isFramePacing = false
        this.isDeferredWork = false
    }

    init(isSynthetic: Bool, isFramePacing: Bool, isDeferredWork: Bool) {
        this.isSynthetic = isSynthetic
        this.isFramePacing = isFramePacing
        this.isDeferredWork = isDeferredWork
    }
}

// Tick kind is a routing fact, not a render or idle implementation.
struct CjguiInternalSchedulerTickKind {
    let isCyclePreparationTick: Bool
    let isRenderPreparationTick: Bool
    let isIdleMaintenanceTick: Bool

    init() {
        this.isCyclePreparationTick = true
        this.isRenderPreparationTick = false
        this.isIdleMaintenanceTick = false
    }

    init(
        isCyclePreparationTick: Bool,
        isRenderPreparationTick: Bool,
        isIdleMaintenanceTick: Bool
    ) {
        this.isCyclePreparationTick = isCyclePreparationTick
        this.isRenderPreparationTick = isRenderPreparationTick
        this.isIdleMaintenanceTick = isIdleMaintenanceTick
    }
}

struct CjguiInternalSchedulerTickIntent {
    let source: CjguiInternalSchedulerTickSource
    let kind: CjguiInternalSchedulerTickKind
    let isSchedulerTickPresent: Bool

    init(
        source: CjguiInternalSchedulerTickSource,
        kind: CjguiInternalSchedulerTickKind,
        isSchedulerTickPresent: Bool
    ) {
        this.source = source
        this.kind = kind
        this.isSchedulerTickPresent = isSchedulerTickPresent
    }
}

struct CjguiInternalSchedulerTickAdmission {
    let intent: CjguiInternalSchedulerTickIntent
    let canAdmitSchedulerTick: Bool
    let shouldDeferSchedulerTick: Bool
    let shouldReportSchedulerTickBlocked: Bool

    init(
        intent: CjguiInternalSchedulerTickIntent,
        canAdmitSchedulerTick: Bool,
        shouldDeferSchedulerTick: Bool,
        shouldReportSchedulerTickBlocked: Bool
    ) {
        this.intent = intent
        this.canAdmitSchedulerTick = canAdmitSchedulerTick
        this.shouldDeferSchedulerTick = shouldDeferSchedulerTick
        this.shouldReportSchedulerTickBlocked = shouldReportSchedulerTickBlocked
    }
}

// Scheduler runtime ingress only combines tick admission with state-store
// transition facts; it does not drive pacing by itself.
struct CjguiInternalSchedulerRuntimeIngress {
    let admission: CjguiInternalSchedulerTickAdmission
    let stateTransition: CjguiInternalRuntimeStateStoreTransition
    let canEnterRuntimePacing: Bool
    let shouldDeferRuntimePacing: Bool
    let shouldReportRuntimePacingBlocked: Bool
    let didPreserveSchedulerTick: Bool

    init(
        admission: CjguiInternalSchedulerTickAdmission,
        stateTransition: CjguiInternalRuntimeStateStoreTransition,
        canEnterRuntimePacing: Bool,
        shouldDeferRuntimePacing: Bool,
        shouldReportRuntimePacingBlocked: Bool,
        didPreserveSchedulerTick: Bool
    ) {
        this.admission = admission
        this.stateTransition = stateTransition
        this.canEnterRuntimePacing = canEnterRuntimePacing
        this.shouldDeferRuntimePacing = shouldDeferRuntimePacing
        this.shouldReportRuntimePacingBlocked = shouldReportRuntimePacingBlocked
        this.didPreserveSchedulerTick = didPreserveSchedulerTick
    }
}

func cjguiInternalDefaultSchedulerTickSource(): CjguiInternalSchedulerTickSource {
    return CjguiInternalSchedulerTickSource()
}

func cjguiInternalDefaultSchedulerTickKind(): CjguiInternalSchedulerTickKind {
    return CjguiInternalSchedulerTickKind()
}

func cjguiInternalBuildSchedulerTickIntent(
    source: CjguiInternalSchedulerTickSource,
    kind: CjguiInternalSchedulerTickKind,
    isSchedulerTickPresent: Bool
): CjguiInternalSchedulerTickIntent {
    return CjguiInternalSchedulerTickIntent(source, kind, isSchedulerTickPresent)
}

func cjguiInternalSchedulerTickSourceIsValid(source: CjguiInternalSchedulerTickSource): Bool {
    return (
        source.isSynthetic &&
        source.isFramePacing == false &&
        source.isDeferredWork == false
    ) || (
        source.isSynthetic == false &&
        source.isFramePacing &&
        source.isDeferredWork == false
    ) || (
        source.isSynthetic == false &&
        source.isFramePacing == false &&
        source.isDeferredWork
    )
}

func cjguiInternalSchedulerTickKindIsValid(kind: CjguiInternalSchedulerTickKind): Bool {
    return (
        kind.isCyclePreparationTick &&
        kind.isRenderPreparationTick == false &&
        kind.isIdleMaintenanceTick == false
    ) || (
        kind.isCyclePreparationTick == false &&
        kind.isRenderPreparationTick &&
        kind.isIdleMaintenanceTick == false
    ) || (
        kind.isCyclePreparationTick == false &&
        kind.isRenderPreparationTick == false &&
        kind.isIdleMaintenanceTick
    )
}

func cjguiInternalEvaluateSchedulerTickAdmission(
    intent: CjguiInternalSchedulerTickIntent
): CjguiInternalSchedulerTickAdmission {
    if (intent.isSchedulerTickPresent == false) {
        return CjguiInternalSchedulerTickAdmission(intent, false, true, false)
    }

    if (
        cjguiInternalSchedulerTickSourceIsValid(intent.source) &&
        cjguiInternalSchedulerTickKindIsValid(intent.kind)
    ) {
        return CjguiInternalSchedulerTickAdmission(intent, true, false, false)
    }

    // Invalid source/kind combinations fail closed as blocked.
    return CjguiInternalSchedulerTickAdmission(intent, false, false, true)
}

func cjguiInternalExecuteDefaultSchedulerTickAdmissionDraft(): CjguiInternalSchedulerTickAdmission {
    // Default draft constructs synthetic value facts only; it does not tick a scheduler.
    let source = cjguiInternalDefaultSchedulerTickSource()
    let kind = cjguiInternalDefaultSchedulerTickKind()
    let intent = cjguiInternalBuildSchedulerTickIntent(source, kind, true)
    return cjguiInternalEvaluateSchedulerTickAdmission(intent)
}

func cjguiInternalBuildSchedulerRuntimeIngress(
    admission: CjguiInternalSchedulerTickAdmission,
    stateTransition: CjguiInternalRuntimeStateStoreTransition
): CjguiInternalSchedulerRuntimeIngress {
    let admissionReady = admission.canAdmitSchedulerTick &&
        admission.shouldDeferSchedulerTick == false &&
        admission.shouldReportSchedulerTickBlocked == false
    let admissionDeferred = admission.canAdmitSchedulerTick == false &&
        admission.shouldDeferSchedulerTick &&
        admission.shouldReportSchedulerTickBlocked == false
    let admissionInconsistent = (
        admission.canAdmitSchedulerTick &&
            (admission.shouldDeferSchedulerTick ||
                admission.shouldReportSchedulerTickBlocked)
        ) ||
        (admission.shouldDeferSchedulerTick &&
            admission.shouldReportSchedulerTickBlocked)
    let transitionReady = stateTransition.didTransitionRuntimeStateStore &&
        stateTransition.shouldDeferRuntimeStateStoreTransition == false &&
        stateTransition.shouldReportRuntimeStateStoreTransitionBlocked == false
    let transitionDeferred = stateTransition.didTransitionRuntimeStateStore == false &&
        stateTransition.shouldDeferRuntimeStateStoreTransition &&
        stateTransition.shouldReportRuntimeStateStoreTransitionBlocked == false
    let transitionInconsistent = (
        stateTransition.didTransitionRuntimeStateStore &&
            (stateTransition.shouldDeferRuntimeStateStoreTransition ||
                stateTransition.shouldReportRuntimeStateStoreTransitionBlocked)
        ) ||
        (stateTransition.shouldDeferRuntimeStateStoreTransition &&
            stateTransition.shouldReportRuntimeStateStoreTransitionBlocked)
    let canEnter = admissionReady && transitionReady
    let shouldDefer = canEnter == false &&
        admissionInconsistent == false &&
        transitionInconsistent == false &&
        admission.shouldReportSchedulerTickBlocked == false &&
        stateTransition.shouldReportRuntimeStateStoreTransitionBlocked == false &&
        (admissionDeferred || transitionDeferred)
    if (canEnter) {
        return CjguiInternalSchedulerRuntimeIngress(
            admission,
            stateTransition,
            true,
            false,
            false,
            true
        )
    }
    // Non-ready paths that are not clean deferrals become blocked ingress.
    return CjguiInternalSchedulerRuntimeIngress(
        admission,
        stateTransition,
        false,
        shouldDefer,
        shouldDefer == false,
        false
    )
}

func cjguiInternalExecuteDefaultSchedulerRuntimeIngressDraft(
): CjguiInternalSchedulerRuntimeIngress {
    let admission = cjguiInternalExecuteDefaultSchedulerTickAdmissionDraft()
    let stateTransition = cjguiInternalExecuteDefaultRuntimeStateStoreTransitionDraft()
    return cjguiInternalBuildSchedulerRuntimeIngress(
        admission,
        stateTransition
    )
}

package cjgui

// Internal Action Router owner:
// - This file owns the first internal action-routing value pipeline.
// - Its truth is dehydrated Action / Queue / Dispatch / Effect / Execution
//   summary facts, not app state, window state, queue state, platform truth,
//   provider truth, or controller ownership.
// - It outputs only internal Bool summaries that later owner boundaries may
//   consume.
// - Stop-line: no real action execution, no event loop, no queue drain, no
//   scheduler driving, no controller registry, no platform bridge, no public
//   runtime API, and no public C ABI.

// Action source is a dehydrated origin fact. Exactly one origin should be true;
// invalid combinations are rejected by admission instead of normalized here.
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

// Action kind is a dehydrated routing hint, not a behavior implementation.
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

// Intent only pairs origin/kind with presence; it does not invoke handlers.
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

// Admission consumes queue readiness and action facts; it does not own the
// queue boundary or execute an action.
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

// Dispatch tail 是 Action Router 当前 canonical path 的前半段，只沉淀 value facts，
// 不代表 queue enqueue、dispatch 执行或 public audit。
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

// Execution tail 是 Action Router 当前 canonical path 的后半段，只沉淀 value facts，
// 不代表真实 action execution，也不产生 side effect。
struct CjguiInternalActionExecutionConvergence {
    let attemptResult: CjguiInternalActionExecutionAttemptResult
    let didConvergeActionExecution: Bool
    let shouldDeferActionExecutionConvergence: Bool
    let shouldReportActionExecutionConvergenceBlocked: Bool
    let didPreserveActionExecutionAttempt: Bool

    init(
        attemptResult: CjguiInternalActionExecutionAttemptResult,
        didConvergeActionExecution: Bool,
        shouldDeferActionExecutionConvergence: Bool,
        shouldReportActionExecutionConvergenceBlocked: Bool,
        didPreserveActionExecutionAttempt: Bool
    ) {
        this.attemptResult = attemptResult
        this.didConvergeActionExecution = didConvergeActionExecution
        this.shouldDeferActionExecutionConvergence = shouldDeferActionExecutionConvergence
        this.shouldReportActionExecutionConvergenceBlocked = shouldReportActionExecutionConvergenceBlocked
        this.didPreserveActionExecutionAttempt = didPreserveActionExecutionAttempt
    }
}

struct CjguiInternalActionExecutionCommitCandidate {
    let convergence: CjguiInternalActionExecutionConvergence
    let canCommitActionExecution: Bool
    let shouldDeferActionExecutionCommit: Bool
    let shouldReportActionExecutionCommitBlocked: Bool
    let didPreserveActionExecutionFacts: Bool

    init(
        convergence: CjguiInternalActionExecutionConvergence,
        canCommitActionExecution: Bool,
        shouldDeferActionExecutionCommit: Bool,
        shouldReportActionExecutionCommitBlocked: Bool,
        didPreserveActionExecutionFacts: Bool
    ) {
        this.convergence = convergence
        this.canCommitActionExecution = canCommitActionExecution
        this.shouldDeferActionExecutionCommit = shouldDeferActionExecutionCommit
        this.shouldReportActionExecutionCommitBlocked = shouldReportActionExecutionCommitBlocked
        this.didPreserveActionExecutionFacts = didPreserveActionExecutionFacts
    }
}

struct CjguiInternalActionExecutionFinalization {
    let candidate: CjguiInternalActionExecutionCommitCandidate
    let didFinalizeActionExecutionBoundary: Bool
    let shouldDeferActionExecutionFinalization: Bool
    let shouldReportActionExecutionFinalizationBlocked: Bool

    init(
        candidate: CjguiInternalActionExecutionCommitCandidate,
        didFinalizeActionExecutionBoundary: Bool,
        shouldDeferActionExecutionFinalization: Bool,
        shouldReportActionExecutionFinalizationBlocked: Bool
    ) {
        this.candidate = candidate
        this.didFinalizeActionExecutionBoundary = didFinalizeActionExecutionBoundary
        this.shouldDeferActionExecutionFinalization = shouldDeferActionExecutionFinalization
        this.shouldReportActionExecutionFinalizationBlocked = shouldReportActionExecutionFinalizationBlocked
    }
}

// 记录层只把 execution finalization 固定成可追踪 value，不代表真实 action execution、
// queue enqueue record 或 public audit log。
struct CjguiInternalActionExecutionRecord {
    let finalization: CjguiInternalActionExecutionFinalization
    let didRecordActionExecutionBoundary: Bool
    let shouldDeferActionExecutionRecord: Bool
    let shouldReportActionExecutionRecordBlocked: Bool

    init(
        finalization: CjguiInternalActionExecutionFinalization,
        didRecordActionExecutionBoundary: Bool,
        shouldDeferActionExecutionRecord: Bool,
        shouldReportActionExecutionRecordBlocked: Bool
    ) {
        this.finalization = finalization
        this.didRecordActionExecutionBoundary = didRecordActionExecutionBoundary
        this.shouldDeferActionExecutionRecord = shouldDeferActionExecutionRecord
        this.shouldReportActionExecutionRecordBlocked = shouldReportActionExecutionRecordBlocked
    }
}

// Policy model 只把 execution record 投影成未来执行约束，不代表授权真实执行。
struct CjguiInternalActionExecutionPolicyModel {
    let record: CjguiInternalActionExecutionRecord
    let allowsFutureActionExecution: Bool
    let shouldDeferExecutionPolicy: Bool
    let shouldReportExecutionPolicyBlocked: Bool
    let didPreserveExecutionRecord: Bool

    init(
        record: CjguiInternalActionExecutionRecord,
        allowsFutureActionExecution: Bool,
        shouldDeferExecutionPolicy: Bool,
        shouldReportExecutionPolicyBlocked: Bool,
        didPreserveExecutionRecord: Bool
    ) {
        this.record = record
        this.allowsFutureActionExecution = allowsFutureActionExecution
        this.shouldDeferExecutionPolicy = shouldDeferExecutionPolicy
        this.shouldReportExecutionPolicyBlocked = shouldReportExecutionPolicyBlocked
        this.didPreserveExecutionRecord = didPreserveExecutionRecord
    }
}

// Gate 只判断 policy facts 是否能打开未来执行门，不执行 action、不写状态。
struct CjguiInternalActionExecutionPolicyGate {
    let policy: CjguiInternalActionExecutionPolicyModel
    let canOpenExecutionPolicyGate: Bool
    let shouldDeferExecutionPolicyGate: Bool
    let shouldReportExecutionPolicyGateBlocked: Bool
    let didPreserveExecutionPolicy: Bool

    init(
        policy: CjguiInternalActionExecutionPolicyModel,
        canOpenExecutionPolicyGate: Bool,
        shouldDeferExecutionPolicyGate: Bool,
        shouldReportExecutionPolicyGateBlocked: Bool,
        didPreserveExecutionPolicy: Bool
    ) {
        this.policy = policy
        this.canOpenExecutionPolicyGate = canOpenExecutionPolicyGate
        this.shouldDeferExecutionPolicyGate = shouldDeferExecutionPolicyGate
        this.shouldReportExecutionPolicyGateBlocked = shouldReportExecutionPolicyGateBlocked
        this.didPreserveExecutionPolicy = didPreserveExecutionPolicy
    }
}

// Readiness 是本轮 policy endpoint，只表达 future execution policy 已准备好。
struct CjguiInternalActionExecutionPolicyReadiness {
    let gate: CjguiInternalActionExecutionPolicyGate
    let isReadyForPolicyExecution: Bool
    let shouldDeferPolicyExecution: Bool
    let shouldReportPolicyExecutionBlocked: Bool

    init(
        gate: CjguiInternalActionExecutionPolicyGate,
        isReadyForPolicyExecution: Bool,
        shouldDeferPolicyExecution: Bool,
        shouldReportPolicyExecutionBlocked: Bool
    ) {
        this.gate = gate
        this.isReadyForPolicyExecution = isReadyForPolicyExecution
        this.shouldDeferPolicyExecution = shouldDeferPolicyExecution
        this.shouldReportPolicyExecutionBlocked = shouldReportPolicyExecutionBlocked
    }
}

// Guarded attempt 只记录 policy readiness 允许进入受控尝试，不代表真实 action execution。
struct CjguiInternalActionGuardedExecutionAttempt {
    let readiness: CjguiInternalActionExecutionPolicyReadiness
    let didAttemptGuardedExecution: Bool
    let shouldDeferGuardedExecutionAttempt: Bool
    let shouldReportGuardedExecutionAttemptBlocked: Bool
    let didPreservePolicyReadiness: Bool

    init(
        readiness: CjguiInternalActionExecutionPolicyReadiness,
        didAttemptGuardedExecution: Bool,
        shouldDeferGuardedExecutionAttempt: Bool,
        shouldReportGuardedExecutionAttemptBlocked: Bool,
        didPreservePolicyReadiness: Bool
    ) {
        this.readiness = readiness
        this.didAttemptGuardedExecution = didAttemptGuardedExecution
        this.shouldDeferGuardedExecutionAttempt = shouldDeferGuardedExecutionAttempt
        this.shouldReportGuardedExecutionAttemptBlocked = shouldReportGuardedExecutionAttemptBlocked
        this.didPreservePolicyReadiness = didPreservePolicyReadiness
    }
}

struct CjguiInternalActionGuardedExecutionAttemptResult {
    let attempt: CjguiInternalActionGuardedExecutionAttempt
    let didAcceptGuardedExecutionAttempt: Bool
    let shouldDeferGuardedExecutionResult: Bool
    let shouldReportGuardedExecutionBlocked: Bool
    let didPreserveGuardedAttempt: Bool

    init(
        attempt: CjguiInternalActionGuardedExecutionAttempt,
        didAcceptGuardedExecutionAttempt: Bool,
        shouldDeferGuardedExecutionResult: Bool,
        shouldReportGuardedExecutionBlocked: Bool,
        didPreserveGuardedAttempt: Bool
    ) {
        this.attempt = attempt
        this.didAcceptGuardedExecutionAttempt = didAcceptGuardedExecutionAttempt
        this.shouldDeferGuardedExecutionResult = shouldDeferGuardedExecutionResult
        this.shouldReportGuardedExecutionBlocked = shouldReportGuardedExecutionBlocked
        this.didPreserveGuardedAttempt = didPreserveGuardedAttempt
    }
}

// Acceptance 是 guarded attempt 的 canonical endpoint，只表达 value facts 已被接纳。
struct CjguiInternalActionGuardedExecutionAcceptance {
    let result: CjguiInternalActionGuardedExecutionAttemptResult
    let isGuardedExecutionAccepted: Bool
    let shouldDeferGuardedExecutionAcceptance: Bool
    let shouldReportGuardedExecutionAcceptanceBlocked: Bool
    let didPreserveGuardedExecutionFacts: Bool

    init(
        result: CjguiInternalActionGuardedExecutionAttemptResult,
        isGuardedExecutionAccepted: Bool,
        shouldDeferGuardedExecutionAcceptance: Bool,
        shouldReportGuardedExecutionAcceptanceBlocked: Bool,
        didPreserveGuardedExecutionFacts: Bool
    ) {
        this.result = result
        this.isGuardedExecutionAccepted = isGuardedExecutionAccepted
        this.shouldDeferGuardedExecutionAcceptance = shouldDeferGuardedExecutionAcceptance
        this.shouldReportGuardedExecutionAcceptanceBlocked = shouldReportGuardedExecutionAcceptanceBlocked
        this.didPreserveGuardedExecutionFacts = didPreserveGuardedExecutionFacts
    }
}

// Guarded effect plan 只把 guarded acceptance 投影为未来 effect 计划事实，
// 不执行 action、不产生 side effect，也不写 queue。
struct CjguiInternalActionGuardedExecutionEffectPlan {
    let acceptance: CjguiInternalActionGuardedExecutionAcceptance
    let shouldPlanGuardedExecutionEffect: Bool
    let shouldDeferGuardedExecutionEffect: Bool
    let shouldReportGuardedExecutionEffectBlocked: Bool
    let didPreserveGuardedExecutionAcceptance: Bool

    init(
        acceptance: CjguiInternalActionGuardedExecutionAcceptance,
        shouldPlanGuardedExecutionEffect: Bool,
        shouldDeferGuardedExecutionEffect: Bool,
        shouldReportGuardedExecutionEffectBlocked: Bool,
        didPreserveGuardedExecutionAcceptance: Bool
    ) {
        this.acceptance = acceptance
        this.shouldPlanGuardedExecutionEffect = shouldPlanGuardedExecutionEffect
        this.shouldDeferGuardedExecutionEffect = shouldDeferGuardedExecutionEffect
        this.shouldReportGuardedExecutionEffectBlocked = shouldReportGuardedExecutionEffectBlocked
        this.didPreserveGuardedExecutionAcceptance = didPreserveGuardedExecutionAcceptance
    }
}

// Commit candidate 只收束 guarded effect plan 的 value facts，
// 不是执行许可、queue commit 或 platform callback。
struct CjguiInternalActionGuardedExecutionCommitCandidate {
    let plan: CjguiInternalActionGuardedExecutionEffectPlan
    let canCommitGuardedExecutionEffect: Bool
    let shouldDeferGuardedExecutionCommit: Bool
    let shouldReportGuardedExecutionCommitBlocked: Bool
    let didPreserveGuardedExecutionEffect: Bool

    init(
        plan: CjguiInternalActionGuardedExecutionEffectPlan,
        canCommitGuardedExecutionEffect: Bool,
        shouldDeferGuardedExecutionCommit: Bool,
        shouldReportGuardedExecutionCommitBlocked: Bool,
        didPreserveGuardedExecutionEffect: Bool
    ) {
        this.plan = plan
        this.canCommitGuardedExecutionEffect = canCommitGuardedExecutionEffect
        this.shouldDeferGuardedExecutionCommit = shouldDeferGuardedExecutionCommit
        this.shouldReportGuardedExecutionCommitBlocked = shouldReportGuardedExecutionCommitBlocked
        this.didPreserveGuardedExecutionEffect = didPreserveGuardedExecutionEffect
    }
}

// Finalization 是本轮 guarded commit/effect endpoint，只记录边界事实已收束，
// 不代表真实 action execution 已发生。
struct CjguiInternalActionGuardedExecutionFinalization {
    let candidate: CjguiInternalActionGuardedExecutionCommitCandidate
    let didFinalizeGuardedExecutionBoundary: Bool
    let shouldDeferGuardedExecutionFinalization: Bool
    let shouldReportGuardedExecutionFinalizationBlocked: Bool

    init(
        candidate: CjguiInternalActionGuardedExecutionCommitCandidate,
        didFinalizeGuardedExecutionBoundary: Bool,
        shouldDeferGuardedExecutionFinalization: Bool,
        shouldReportGuardedExecutionFinalizationBlocked: Bool
    ) {
        this.candidate = candidate
        this.didFinalizeGuardedExecutionBoundary = didFinalizeGuardedExecutionBoundary
        this.shouldDeferGuardedExecutionFinalization = shouldDeferGuardedExecutionFinalization
        this.shouldReportGuardedExecutionFinalizationBlocked = shouldReportGuardedExecutionFinalizationBlocked
    }
}

// Result publication 只把 guarded finalization 固定为内部 publication facts，
// 不是 public publication、observer callback 或真实 action execution。
struct CjguiInternalActionGuardedExecutionResultPublication {
    let finalization: CjguiInternalActionGuardedExecutionFinalization
    let didPublishGuardedExecutionResult: Bool
    let shouldDeferGuardedExecutionPublication: Bool
    let shouldReportGuardedExecutionPublicationBlocked: Bool
    let didPreserveGuardedExecutionFinalization: Bool

    init(
        finalization: CjguiInternalActionGuardedExecutionFinalization,
        didPublishGuardedExecutionResult: Bool,
        shouldDeferGuardedExecutionPublication: Bool,
        shouldReportGuardedExecutionPublicationBlocked: Bool,
        didPreserveGuardedExecutionFinalization: Bool
    ) {
        this.finalization = finalization
        this.didPublishGuardedExecutionResult = didPublishGuardedExecutionResult
        this.shouldDeferGuardedExecutionPublication = shouldDeferGuardedExecutionPublication
        this.shouldReportGuardedExecutionPublicationBlocked = shouldReportGuardedExecutionPublicationBlocked
        this.didPreserveGuardedExecutionFinalization = didPreserveGuardedExecutionFinalization
    }
}

// Handoff candidate 只表达 guarded publication 可交给后续内部边界，
// 不写 queue、不通知外部 observer，也不执行 action。
struct CjguiInternalActionGuardedExecutionHandoffCandidate {
    let publication: CjguiInternalActionGuardedExecutionResultPublication
    let canHandoffGuardedExecutionResult: Bool
    let shouldDeferGuardedExecutionHandoff: Bool
    let shouldReportGuardedExecutionHandoffBlocked: Bool
    let didPreserveGuardedExecutionPublication: Bool

    init(
        publication: CjguiInternalActionGuardedExecutionResultPublication,
        canHandoffGuardedExecutionResult: Bool,
        shouldDeferGuardedExecutionHandoff: Bool,
        shouldReportGuardedExecutionHandoffBlocked: Bool,
        didPreserveGuardedExecutionPublication: Bool
    ) {
        this.publication = publication
        this.canHandoffGuardedExecutionResult = canHandoffGuardedExecutionResult
        this.shouldDeferGuardedExecutionHandoff = shouldDeferGuardedExecutionHandoff
        this.shouldReportGuardedExecutionHandoffBlocked = shouldReportGuardedExecutionHandoffBlocked
        this.didPreserveGuardedExecutionPublication = didPreserveGuardedExecutionPublication
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

    // Missing action intent or deferred queue admission remains deferred, not executed.
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

    // Invalid source/kind or non-ready queue facts fail closed as blocked.
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

    // Inconsistent admission facts fail closed before any route candidate is exposed.
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

    // Dispatch admission only accepts a preserved route candidate.
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
    // 默认 draft 只串联 dispatch value pipeline，不执行 dispatch、queue 或 action。
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

    // dispatch finalization facts 不一致时必须 fail-closed，不能被记录为可提交边界。
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
    // dispatch record 是 canonical dispatch endpoint，不是 enqueue record。
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

func cjguiInternalBuildActionExecutionConvergence(
    result: CjguiInternalActionExecutionAttemptResult
): CjguiInternalActionExecutionConvergence {
    let resultAccepted = cjguiInternalActionExecutionAttemptResultDidAccept(result) &&
        result.shouldDeferActionExecutionResult == false &&
        result.shouldReportActionExecutionBlocked == false
    let resultDeferred = result.didAcceptActionExecutionAttempt == false &&
        result.shouldDeferActionExecutionResult &&
        result.shouldReportActionExecutionBlocked == false
    let resultInconsistent = (
        result.didAcceptActionExecutionAttempt &&
            (result.shouldDeferActionExecutionResult ||
                result.shouldReportActionExecutionBlocked)
        ) ||
        (result.shouldDeferActionExecutionResult &&
            result.shouldReportActionExecutionBlocked)

    // Fail closed so inconsistent attempt facts cannot be treated as accepted execution.
    if (result.shouldReportActionExecutionBlocked || resultInconsistent) {
        return CjguiInternalActionExecutionConvergence(result, false, false, true, false)
    }

    if (resultDeferred) {
        return CjguiInternalActionExecutionConvergence(result, false, true, false, false)
    }

    if (resultAccepted) {
        return CjguiInternalActionExecutionConvergence(result, true, false, false, true)
    }

    return CjguiInternalActionExecutionConvergence(result, false, false, true, false)
}

func cjguiInternalActionExecutionConvergenceDidConverge(
    convergence: CjguiInternalActionExecutionConvergence
): Bool {
    return convergence.didConvergeActionExecution
}

func cjguiInternalBuildActionExecutionCommitCandidate(
    convergence: CjguiInternalActionExecutionConvergence
): CjguiInternalActionExecutionCommitCandidate {
    let convergenceReady = cjguiInternalActionExecutionConvergenceDidConverge(convergence) &&
        convergence.didPreserveActionExecutionAttempt &&
        convergence.shouldDeferActionExecutionConvergence == false &&
        convergence.shouldReportActionExecutionConvergenceBlocked == false
    let convergenceDeferred = convergence.didConvergeActionExecution == false &&
        convergence.didPreserveActionExecutionAttempt == false &&
        convergence.shouldDeferActionExecutionConvergence &&
        convergence.shouldReportActionExecutionConvergenceBlocked == false
    let convergenceInconsistent = (
        convergence.didConvergeActionExecution &&
            (convergence.shouldDeferActionExecutionConvergence ||
                convergence.shouldReportActionExecutionConvergenceBlocked)
        ) ||
        (convergence.didPreserveActionExecutionAttempt &&
            convergence.didConvergeActionExecution == false) ||
        (convergence.didPreserveActionExecutionAttempt == false &&
            convergence.didConvergeActionExecution) ||
        (convergence.shouldDeferActionExecutionConvergence &&
            convergence.shouldReportActionExecutionConvergenceBlocked)

    // Fail closed so convergence contradictions cannot become commit candidates.
    if (convergence.shouldReportActionExecutionConvergenceBlocked || convergenceInconsistent) {
        return CjguiInternalActionExecutionCommitCandidate(convergence, false, false, true, false)
    }

    if (convergenceDeferred) {
        return CjguiInternalActionExecutionCommitCandidate(convergence, false, true, false, false)
    }

    if (convergenceReady) {
        return CjguiInternalActionExecutionCommitCandidate(convergence, true, false, false, true)
    }

    return CjguiInternalActionExecutionCommitCandidate(convergence, false, false, true, false)
}

func cjguiInternalActionExecutionCommitCandidateCanCommit(
    candidate: CjguiInternalActionExecutionCommitCandidate
): Bool {
    return candidate.canCommitActionExecution
}

func cjguiInternalFinalizeActionExecutionCandidate(
    candidate: CjguiInternalActionExecutionCommitCandidate
): CjguiInternalActionExecutionFinalization {
    let candidateReady = cjguiInternalActionExecutionCommitCandidateCanCommit(candidate) &&
        candidate.didPreserveActionExecutionFacts &&
        candidate.shouldDeferActionExecutionCommit == false &&
        candidate.shouldReportActionExecutionCommitBlocked == false
    let candidateDeferred = candidate.canCommitActionExecution == false &&
        candidate.didPreserveActionExecutionFacts == false &&
        candidate.shouldDeferActionExecutionCommit &&
        candidate.shouldReportActionExecutionCommitBlocked == false
    let candidateInconsistent = (
        candidate.canCommitActionExecution &&
            (candidate.shouldDeferActionExecutionCommit ||
                candidate.shouldReportActionExecutionCommitBlocked)
        ) ||
        (candidate.didPreserveActionExecutionFacts &&
            candidate.canCommitActionExecution == false) ||
        (candidate.didPreserveActionExecutionFacts == false &&
            candidate.canCommitActionExecution) ||
        (candidate.shouldDeferActionExecutionCommit &&
            candidate.shouldReportActionExecutionCommitBlocked)

    // Fail closed so blocked commit facts cannot finalize as accepted execution.
    if (candidate.shouldReportActionExecutionCommitBlocked || candidateInconsistent) {
        return CjguiInternalActionExecutionFinalization(candidate, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalActionExecutionFinalization(candidate, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalActionExecutionFinalization(candidate, true, false, false)
    }

    return CjguiInternalActionExecutionFinalization(candidate, false, false, true)
}

func cjguiInternalExecuteDefaultActionExecutionConvergenceDraft(
): CjguiInternalActionExecutionFinalization {
    // Default draft only chains value facts; it does not execute action side effects.
    let result = cjguiInternalExecuteDefaultActionExecutionAttemptDraft()
    let convergence = cjguiInternalBuildActionExecutionConvergence(result)
    let candidate = cjguiInternalBuildActionExecutionCommitCandidate(convergence)
    return cjguiInternalFinalizeActionExecutionCandidate(candidate)
}

func cjguiInternalBuildActionExecutionRecord(
    finalization: CjguiInternalActionExecutionFinalization
): CjguiInternalActionExecutionRecord {
    let finalizationReady = finalization.didFinalizeActionExecutionBoundary &&
        finalization.shouldDeferActionExecutionFinalization == false &&
        finalization.shouldReportActionExecutionFinalizationBlocked == false
    let finalizationDeferred = finalization.didFinalizeActionExecutionBoundary == false &&
        finalization.shouldDeferActionExecutionFinalization &&
        finalization.shouldReportActionExecutionFinalizationBlocked == false
    let finalizationInconsistent = (
        finalization.didFinalizeActionExecutionBoundary &&
            (finalization.shouldDeferActionExecutionFinalization ||
                finalization.shouldReportActionExecutionFinalizationBlocked)
        ) ||
        (finalization.shouldDeferActionExecutionFinalization &&
            finalization.shouldReportActionExecutionFinalizationBlocked)

    // 不一致的 finalization facts 必须 fail-closed，避免被误读成真实执行记录。
    if (finalization.shouldReportActionExecutionFinalizationBlocked || finalizationInconsistent) {
        return CjguiInternalActionExecutionRecord(finalization, false, false, true)
    }

    if (finalizationDeferred) {
        return CjguiInternalActionExecutionRecord(finalization, false, true, false)
    }

    if (finalizationReady) {
        return CjguiInternalActionExecutionRecord(finalization, true, false, false)
    }

    return CjguiInternalActionExecutionRecord(finalization, false, false, true)
}

func cjguiInternalExecuteDefaultActionExecutionRecordDraft(
): CjguiInternalActionExecutionRecord {
    // execution record 是 canonical Action Router endpoint，只串联 value pipeline。
    let finalization = cjguiInternalExecuteDefaultActionExecutionConvergenceDraft()
    return cjguiInternalBuildActionExecutionRecord(finalization)
}

func cjguiInternalBuildActionExecutionPolicyModel(
    record: CjguiInternalActionExecutionRecord
): CjguiInternalActionExecutionPolicyModel {
    let recordReady = record.didRecordActionExecutionBoundary &&
        record.shouldDeferActionExecutionRecord == false &&
        record.shouldReportActionExecutionRecordBlocked == false
    let recordDeferred = record.didRecordActionExecutionBoundary == false &&
        record.shouldDeferActionExecutionRecord &&
        record.shouldReportActionExecutionRecordBlocked == false
    let recordInconsistent = (
        record.didRecordActionExecutionBoundary &&
            (record.shouldDeferActionExecutionRecord ||
                record.shouldReportActionExecutionRecordBlocked)
        ) ||
        (record.shouldDeferActionExecutionRecord &&
            record.shouldReportActionExecutionRecordBlocked)

    // execution record facts 不一致时必须 fail-closed，不能进入 policy runway。
    if (record.shouldReportActionExecutionRecordBlocked || recordInconsistent) {
        return CjguiInternalActionExecutionPolicyModel(record, false, false, true, false)
    }

    if (recordDeferred) {
        return CjguiInternalActionExecutionPolicyModel(record, false, true, false, false)
    }

    if (recordReady) {
        return CjguiInternalActionExecutionPolicyModel(record, true, false, false, true)
    }

    return CjguiInternalActionExecutionPolicyModel(record, false, false, true, false)
}

func cjguiInternalBuildActionExecutionPolicyGate(
    policy: CjguiInternalActionExecutionPolicyModel
): CjguiInternalActionExecutionPolicyGate {
    let policyReady = policy.allowsFutureActionExecution &&
        policy.didPreserveExecutionRecord &&
        policy.shouldDeferExecutionPolicy == false &&
        policy.shouldReportExecutionPolicyBlocked == false
    let policyDeferred = policy.allowsFutureActionExecution == false &&
        policy.didPreserveExecutionRecord == false &&
        policy.shouldDeferExecutionPolicy &&
        policy.shouldReportExecutionPolicyBlocked == false
    let policyInconsistent = (
        policy.allowsFutureActionExecution &&
            (policy.shouldDeferExecutionPolicy ||
                policy.shouldReportExecutionPolicyBlocked)
        ) ||
        (policy.didPreserveExecutionRecord &&
            policy.allowsFutureActionExecution == false) ||
        (policy.didPreserveExecutionRecord == false &&
            policy.allowsFutureActionExecution) ||
        (policy.shouldDeferExecutionPolicy &&
            policy.shouldReportExecutionPolicyBlocked)

    // policy facts 不一致时必须 fail-closed，避免把约束摘要误当作执行许可。
    if (policy.shouldReportExecutionPolicyBlocked || policyInconsistent) {
        return CjguiInternalActionExecutionPolicyGate(policy, false, false, true, false)
    }

    if (policyDeferred) {
        return CjguiInternalActionExecutionPolicyGate(policy, false, true, false, false)
    }

    if (policyReady) {
        return CjguiInternalActionExecutionPolicyGate(policy, true, false, false, true)
    }

    return CjguiInternalActionExecutionPolicyGate(policy, false, false, true, false)
}

func cjguiInternalBuildActionExecutionPolicyReadiness(
    gate: CjguiInternalActionExecutionPolicyGate
): CjguiInternalActionExecutionPolicyReadiness {
    let gateReady = gate.canOpenExecutionPolicyGate &&
        gate.didPreserveExecutionPolicy &&
        gate.shouldDeferExecutionPolicyGate == false &&
        gate.shouldReportExecutionPolicyGateBlocked == false
    let gateDeferred = gate.canOpenExecutionPolicyGate == false &&
        gate.didPreserveExecutionPolicy == false &&
        gate.shouldDeferExecutionPolicyGate &&
        gate.shouldReportExecutionPolicyGateBlocked == false
    let gateInconsistent = (
        gate.canOpenExecutionPolicyGate &&
            (gate.shouldDeferExecutionPolicyGate ||
                gate.shouldReportExecutionPolicyGateBlocked)
        ) ||
        (gate.didPreserveExecutionPolicy &&
            gate.canOpenExecutionPolicyGate == false) ||
        (gate.didPreserveExecutionPolicy == false &&
            gate.canOpenExecutionPolicyGate) ||
        (gate.shouldDeferExecutionPolicyGate &&
            gate.shouldReportExecutionPolicyGateBlocked)

    // gate facts 不一致时保持 blocked，readiness 不能伪造执行可用性。
    if (gate.shouldReportExecutionPolicyGateBlocked || gateInconsistent) {
        return CjguiInternalActionExecutionPolicyReadiness(gate, false, false, true)
    }

    if (gateDeferred) {
        return CjguiInternalActionExecutionPolicyReadiness(gate, false, true, false)
    }

    if (gateReady) {
        return CjguiInternalActionExecutionPolicyReadiness(gate, true, false, false)
    }

    return CjguiInternalActionExecutionPolicyReadiness(gate, false, false, true)
}

func cjguiInternalExecuteDefaultActionExecutionPolicyReadinessDraft(
): CjguiInternalActionExecutionPolicyReadiness {
    // 默认 draft 只串联 execution record 到 policy readiness，不执行 action。
    let record = cjguiInternalExecuteDefaultActionExecutionRecordDraft()
    let policy = cjguiInternalBuildActionExecutionPolicyModel(record)
    let gate = cjguiInternalBuildActionExecutionPolicyGate(policy)
    return cjguiInternalBuildActionExecutionPolicyReadiness(gate)
}

func cjguiInternalBuildActionGuardedExecutionAttempt(
    readiness: CjguiInternalActionExecutionPolicyReadiness
): CjguiInternalActionGuardedExecutionAttempt {
    let readinessReady = readiness.isReadyForPolicyExecution &&
        readiness.shouldDeferPolicyExecution == false &&
        readiness.shouldReportPolicyExecutionBlocked == false
    let readinessDeferred = readiness.isReadyForPolicyExecution == false &&
        readiness.shouldDeferPolicyExecution &&
        readiness.shouldReportPolicyExecutionBlocked == false
    let readinessInconsistent = (
        readiness.isReadyForPolicyExecution &&
            (readiness.shouldDeferPolicyExecution ||
                readiness.shouldReportPolicyExecutionBlocked)
        ) ||
        (readiness.shouldDeferPolicyExecution &&
            readiness.shouldReportPolicyExecutionBlocked)

    // policy readiness 不一致时必须 fail-closed，不能伪造成 guarded attempt。
    if (readiness.shouldReportPolicyExecutionBlocked || readinessInconsistent) {
        return CjguiInternalActionGuardedExecutionAttempt(readiness, false, false, true, false)
    }

    if (readinessDeferred) {
        return CjguiInternalActionGuardedExecutionAttempt(readiness, false, true, false, false)
    }

    if (readinessReady) {
        return CjguiInternalActionGuardedExecutionAttempt(readiness, true, false, false, true)
    }

    return CjguiInternalActionGuardedExecutionAttempt(readiness, false, false, true, false)
}

func cjguiInternalEvaluateActionGuardedExecutionAttempt(
    attempt: CjguiInternalActionGuardedExecutionAttempt
): CjguiInternalActionGuardedExecutionAttemptResult {
    let attemptReady = attempt.didAttemptGuardedExecution &&
        attempt.didPreservePolicyReadiness &&
        attempt.shouldDeferGuardedExecutionAttempt == false &&
        attempt.shouldReportGuardedExecutionAttemptBlocked == false
    let attemptDeferred = attempt.didAttemptGuardedExecution == false &&
        attempt.didPreservePolicyReadiness == false &&
        attempt.shouldDeferGuardedExecutionAttempt &&
        attempt.shouldReportGuardedExecutionAttemptBlocked == false
    let attemptInconsistent = (
        attempt.didAttemptGuardedExecution &&
            (attempt.shouldDeferGuardedExecutionAttempt ||
                attempt.shouldReportGuardedExecutionAttemptBlocked)
        ) ||
        (attempt.didPreservePolicyReadiness &&
            attempt.didAttemptGuardedExecution == false) ||
        (attempt.didPreservePolicyReadiness == false &&
            attempt.didAttemptGuardedExecution) ||
        (attempt.shouldDeferGuardedExecutionAttempt &&
            attempt.shouldReportGuardedExecutionAttemptBlocked)

    // guarded attempt facts 不一致时必须 fail-closed，避免被误读为已接受执行。
    if (attempt.shouldReportGuardedExecutionAttemptBlocked || attemptInconsistent) {
        return CjguiInternalActionGuardedExecutionAttemptResult(attempt, false, false, true, false)
    }

    if (attemptDeferred) {
        return CjguiInternalActionGuardedExecutionAttemptResult(attempt, false, true, false, false)
    }

    if (attemptReady) {
        return CjguiInternalActionGuardedExecutionAttemptResult(attempt, true, false, false, true)
    }

    return CjguiInternalActionGuardedExecutionAttemptResult(attempt, false, false, true, false)
}

func cjguiInternalBuildActionGuardedExecutionAcceptance(
    result: CjguiInternalActionGuardedExecutionAttemptResult
): CjguiInternalActionGuardedExecutionAcceptance {
    let resultReady = result.didAcceptGuardedExecutionAttempt &&
        result.didPreserveGuardedAttempt &&
        result.shouldDeferGuardedExecutionResult == false &&
        result.shouldReportGuardedExecutionBlocked == false
    let resultDeferred = result.didAcceptGuardedExecutionAttempt == false &&
        result.didPreserveGuardedAttempt == false &&
        result.shouldDeferGuardedExecutionResult &&
        result.shouldReportGuardedExecutionBlocked == false
    let resultInconsistent = (
        result.didAcceptGuardedExecutionAttempt &&
            (result.shouldDeferGuardedExecutionResult ||
                result.shouldReportGuardedExecutionBlocked)
        ) ||
        (result.didPreserveGuardedAttempt &&
            result.didAcceptGuardedExecutionAttempt == false) ||
        (result.didPreserveGuardedAttempt == false &&
            result.didAcceptGuardedExecutionAttempt) ||
        (result.shouldDeferGuardedExecutionResult &&
            result.shouldReportGuardedExecutionBlocked)

    // attempt result 不一致时保持 blocked，acceptance 不能伪造真实执行结果。
    if (result.shouldReportGuardedExecutionBlocked || resultInconsistent) {
        return CjguiInternalActionGuardedExecutionAcceptance(result, false, false, true, false)
    }

    if (resultDeferred) {
        return CjguiInternalActionGuardedExecutionAcceptance(result, false, true, false, false)
    }

    if (resultReady) {
        return CjguiInternalActionGuardedExecutionAcceptance(result, true, false, false, true)
    }

    return CjguiInternalActionGuardedExecutionAcceptance(result, false, false, true, false)
}

func cjguiInternalExecuteDefaultActionGuardedExecutionAttemptDraft(
): CjguiInternalActionGuardedExecutionAcceptance {
    // 默认 draft 只串联 policy readiness 到 guarded acceptance，不执行 action。
    let readiness = cjguiInternalExecuteDefaultActionExecutionPolicyReadinessDraft()
    let attempt = cjguiInternalBuildActionGuardedExecutionAttempt(readiness)
    let result = cjguiInternalEvaluateActionGuardedExecutionAttempt(attempt)
    return cjguiInternalBuildActionGuardedExecutionAcceptance(result)
}

func cjguiInternalBuildActionGuardedExecutionEffectPlan(
    acceptance: CjguiInternalActionGuardedExecutionAcceptance
): CjguiInternalActionGuardedExecutionEffectPlan {
    let acceptanceReady = acceptance.isGuardedExecutionAccepted &&
        acceptance.didPreserveGuardedExecutionFacts &&
        acceptance.shouldDeferGuardedExecutionAcceptance == false &&
        acceptance.shouldReportGuardedExecutionAcceptanceBlocked == false
    let acceptanceDeferred = acceptance.isGuardedExecutionAccepted == false &&
        acceptance.didPreserveGuardedExecutionFacts == false &&
        acceptance.shouldDeferGuardedExecutionAcceptance &&
        acceptance.shouldReportGuardedExecutionAcceptanceBlocked == false
    let acceptanceInconsistent = (
        acceptance.isGuardedExecutionAccepted &&
            (acceptance.shouldDeferGuardedExecutionAcceptance ||
                acceptance.shouldReportGuardedExecutionAcceptanceBlocked)
        ) ||
        (acceptance.didPreserveGuardedExecutionFacts &&
            acceptance.isGuardedExecutionAccepted == false) ||
        (acceptance.didPreserveGuardedExecutionFacts == false &&
            acceptance.isGuardedExecutionAccepted) ||
        (acceptance.shouldDeferGuardedExecutionAcceptance &&
            acceptance.shouldReportGuardedExecutionAcceptanceBlocked)

    // guarded acceptance 不一致时必须 fail-closed，避免 effect plan 被误当作真实执行计划。
    if (acceptance.shouldReportGuardedExecutionAcceptanceBlocked || acceptanceInconsistent) {
        return CjguiInternalActionGuardedExecutionEffectPlan(acceptance, false, false, true, false)
    }

    if (acceptanceDeferred) {
        return CjguiInternalActionGuardedExecutionEffectPlan(acceptance, false, true, false, false)
    }

    if (acceptanceReady) {
        return CjguiInternalActionGuardedExecutionEffectPlan(acceptance, true, false, false, true)
    }

    return CjguiInternalActionGuardedExecutionEffectPlan(acceptance, false, false, true, false)
}

func cjguiInternalBuildActionGuardedExecutionCommitCandidate(
    plan: CjguiInternalActionGuardedExecutionEffectPlan
): CjguiInternalActionGuardedExecutionCommitCandidate {
    let planReady = plan.shouldPlanGuardedExecutionEffect &&
        plan.didPreserveGuardedExecutionAcceptance &&
        plan.shouldDeferGuardedExecutionEffect == false &&
        plan.shouldReportGuardedExecutionEffectBlocked == false
    let planDeferred = plan.shouldPlanGuardedExecutionEffect == false &&
        plan.didPreserveGuardedExecutionAcceptance == false &&
        plan.shouldDeferGuardedExecutionEffect &&
        plan.shouldReportGuardedExecutionEffectBlocked == false
    let planInconsistent = (
        plan.shouldPlanGuardedExecutionEffect &&
            (plan.shouldDeferGuardedExecutionEffect ||
                plan.shouldReportGuardedExecutionEffectBlocked)
        ) ||
        (plan.didPreserveGuardedExecutionAcceptance &&
            plan.shouldPlanGuardedExecutionEffect == false) ||
        (plan.didPreserveGuardedExecutionAcceptance == false &&
            plan.shouldPlanGuardedExecutionEffect) ||
        (plan.shouldDeferGuardedExecutionEffect &&
            plan.shouldReportGuardedExecutionEffectBlocked)

    // effect plan facts 不一致时必须 fail-closed，不能形成 guarded commit candidate。
    if (plan.shouldReportGuardedExecutionEffectBlocked || planInconsistent) {
        return CjguiInternalActionGuardedExecutionCommitCandidate(plan, false, false, true, false)
    }

    if (planDeferred) {
        return CjguiInternalActionGuardedExecutionCommitCandidate(plan, false, true, false, false)
    }

    if (planReady) {
        return CjguiInternalActionGuardedExecutionCommitCandidate(plan, true, false, false, true)
    }

    return CjguiInternalActionGuardedExecutionCommitCandidate(plan, false, false, true, false)
}

func cjguiInternalFinalizeActionGuardedExecutionCandidate(
    candidate: CjguiInternalActionGuardedExecutionCommitCandidate
): CjguiInternalActionGuardedExecutionFinalization {
    let candidateReady = candidate.canCommitGuardedExecutionEffect &&
        candidate.didPreserveGuardedExecutionEffect &&
        candidate.shouldDeferGuardedExecutionCommit == false &&
        candidate.shouldReportGuardedExecutionCommitBlocked == false
    let candidateDeferred = candidate.canCommitGuardedExecutionEffect == false &&
        candidate.didPreserveGuardedExecutionEffect == false &&
        candidate.shouldDeferGuardedExecutionCommit &&
        candidate.shouldReportGuardedExecutionCommitBlocked == false
    let candidateInconsistent = (
        candidate.canCommitGuardedExecutionEffect &&
            (candidate.shouldDeferGuardedExecutionCommit ||
                candidate.shouldReportGuardedExecutionCommitBlocked)
        ) ||
        (candidate.didPreserveGuardedExecutionEffect &&
            candidate.canCommitGuardedExecutionEffect == false) ||
        (candidate.didPreserveGuardedExecutionEffect == false &&
            candidate.canCommitGuardedExecutionEffect) ||
        (candidate.shouldDeferGuardedExecutionCommit &&
            candidate.shouldReportGuardedExecutionCommitBlocked)

    // commit candidate 不一致时必须 fail-closed，finalization 不能伪造执行完成。
    if (candidate.shouldReportGuardedExecutionCommitBlocked || candidateInconsistent) {
        return CjguiInternalActionGuardedExecutionFinalization(candidate, false, false, true)
    }

    if (candidateDeferred) {
        return CjguiInternalActionGuardedExecutionFinalization(candidate, false, true, false)
    }

    if (candidateReady) {
        return CjguiInternalActionGuardedExecutionFinalization(candidate, true, false, false)
    }

    return CjguiInternalActionGuardedExecutionFinalization(candidate, false, false, true)
}

func cjguiInternalExecuteDefaultActionGuardedExecutionCommitEffectDraft(
): CjguiInternalActionGuardedExecutionFinalization {
    // 默认 draft 只串联 guarded execution value pipeline，不执行 action side effect。
    let acceptance = cjguiInternalExecuteDefaultActionGuardedExecutionAttemptDraft()
    let plan = cjguiInternalBuildActionGuardedExecutionEffectPlan(acceptance)
    let candidate = cjguiInternalBuildActionGuardedExecutionCommitCandidate(plan)
    return cjguiInternalFinalizeActionGuardedExecutionCandidate(candidate)
}

func cjguiInternalBuildActionGuardedExecutionResultPublication(
    finalization: CjguiInternalActionGuardedExecutionFinalization
): CjguiInternalActionGuardedExecutionResultPublication {
    let finalizationReady = finalization.didFinalizeGuardedExecutionBoundary &&
        finalization.shouldDeferGuardedExecutionFinalization == false &&
        finalization.shouldReportGuardedExecutionFinalizationBlocked == false
    let finalizationDeferred = finalization.didFinalizeGuardedExecutionBoundary == false &&
        finalization.shouldDeferGuardedExecutionFinalization &&
        finalization.shouldReportGuardedExecutionFinalizationBlocked == false
    let finalizationInconsistent = (
        finalization.didFinalizeGuardedExecutionBoundary &&
            (finalization.shouldDeferGuardedExecutionFinalization ||
                finalization.shouldReportGuardedExecutionFinalizationBlocked)
        ) ||
        (finalization.shouldDeferGuardedExecutionFinalization &&
            finalization.shouldReportGuardedExecutionFinalizationBlocked)

    // finalization facts 不一致时必须 fail-closed，避免 publication 被误读成外部发布。
    if (finalization.shouldReportGuardedExecutionFinalizationBlocked || finalizationInconsistent) {
        return CjguiInternalActionGuardedExecutionResultPublication(
            finalization,
            false,
            false,
            true,
            false
        )
    }

    if (finalizationDeferred) {
        return CjguiInternalActionGuardedExecutionResultPublication(
            finalization,
            false,
            true,
            false,
            false
        )
    }

    if (finalizationReady) {
        return CjguiInternalActionGuardedExecutionResultPublication(
            finalization,
            true,
            false,
            false,
            true
        )
    }

    return CjguiInternalActionGuardedExecutionResultPublication(finalization, false, false, true, false)
}

func cjguiInternalBuildActionGuardedExecutionHandoffCandidate(
    publication: CjguiInternalActionGuardedExecutionResultPublication
): CjguiInternalActionGuardedExecutionHandoffCandidate {
    let publicationReady = publication.didPublishGuardedExecutionResult &&
        publication.didPreserveGuardedExecutionFinalization &&
        publication.shouldDeferGuardedExecutionPublication == false &&
        publication.shouldReportGuardedExecutionPublicationBlocked == false
    let publicationDeferred = publication.didPublishGuardedExecutionResult == false &&
        publication.didPreserveGuardedExecutionFinalization == false &&
        publication.shouldDeferGuardedExecutionPublication &&
        publication.shouldReportGuardedExecutionPublicationBlocked == false
    let publicationInconsistent = (
        publication.didPublishGuardedExecutionResult &&
            (publication.shouldDeferGuardedExecutionPublication ||
                publication.shouldReportGuardedExecutionPublicationBlocked)
        ) ||
        (publication.didPreserveGuardedExecutionFinalization &&
            publication.didPublishGuardedExecutionResult == false) ||
        (publication.didPreserveGuardedExecutionFinalization == false &&
            publication.didPublishGuardedExecutionResult) ||
        (publication.shouldDeferGuardedExecutionPublication &&
            publication.shouldReportGuardedExecutionPublicationBlocked)

    // publication facts 不一致时必须 fail-closed，不能交给后续边界。
    if (publication.shouldReportGuardedExecutionPublicationBlocked || publicationInconsistent) {
        return CjguiInternalActionGuardedExecutionHandoffCandidate(publication, false, false, true, false)
    }

    if (publicationDeferred) {
        return CjguiInternalActionGuardedExecutionHandoffCandidate(publication, false, true, false, false)
    }

    if (publicationReady) {
        return CjguiInternalActionGuardedExecutionHandoffCandidate(publication, true, false, false, true)
    }

    return CjguiInternalActionGuardedExecutionHandoffCandidate(publication, false, false, true, false)
}

func cjguiInternalExecuteDefaultActionGuardedExecutionResultPublicationDraft(
): CjguiInternalActionGuardedExecutionHandoffCandidate {
    // 默认 draft 只串联 guarded finalization 到 publication / handoff facts，不执行 action。
    let finalization = cjguiInternalExecuteDefaultActionGuardedExecutionCommitEffectDraft()
    let publication = cjguiInternalBuildActionGuardedExecutionResultPublication(finalization)
    return cjguiInternalBuildActionGuardedExecutionHandoffCandidate(publication)
}

package cjgui

// 内部 runtime root state owner:
// - 本文件承载默认 internal runtime root state summary。
// - 它只聚合既有 runtime bootstrap snapshot 与 runtime readiness Bool。
// - 它不拥有 app lifecycle state truth、window lifecycle state truth 或
//   platform object truth。
// - 它不实现 app run、event loop、queue / drain、window create 或 shutdown。
// - 它不改变 bootstrap、projection、coordination、state shape、constructor shape、
//   public runtime API 或 public C ABI。

// 内部 runtime root state:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只聚合 bootstrap snapshot 与 isRuntimeReady Bool。
// - 它不定义 runtime state machine、run behavior 或 shutdown behavior。
// - 它不新增 public runtime API 或 public C ABI。

struct CjguiInternalRuntimeRootState {
    let bootstrap: CjguiInternalRuntimeBootstrapSnapshot
    let isRuntimeReady: Bool

    init(
        bootstrap: CjguiInternalRuntimeBootstrapSnapshot,
        isRuntimeReady: Bool
    ) {
        this.bootstrap = bootstrap
        this.isRuntimeReady = isRuntimeReady
    }
}

// 内部 runtime step result:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只聚合 step 后的 root state、didAdvance Bool 和最小 blocked outcome。
// - 它不定义 runtime state machine、event loop、queue / drain 或 app run。
// - 它不改变 root state shape、bootstrap behavior、projection、coordination、
//   constructor shape、public runtime API 或 public C ABI。

struct CjguiInternalRuntimeStepResult {
    let state: CjguiInternalRuntimeRootState
    let didAdvance: Bool
    let isBlocked: Bool
    let isBlockedByRuntimeNotReady: Bool
    let isBlockedByInput: Bool

    init(
        state: CjguiInternalRuntimeRootState,
        didAdvance: Bool,
        isBlocked: Bool,
        isBlockedByRuntimeNotReady: Bool,
        isBlockedByInput: Bool
    ) {
        this.state = state
        this.didAdvance = didAdvance
        this.isBlocked = isBlocked
        this.isBlockedByRuntimeNotReady = isBlockedByRuntimeNotReady
        this.isBlockedByInput = isBlockedByInput
    }
}

// 内部 runtime step input:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - allowsAdvance 只是 internal step gate。
// - hasExternalWork 只是脱水 marker, 不代表真实 queue、event loop 或
//   platform callback。

struct CjguiInternalRuntimeStepInput {
    let allowsAdvance: Bool
    let hasExternalWork: Bool

    init() {
        this.allowsAdvance = true
        this.hasExternalWork = false
    }

    init(
        allowsAdvance: Bool,
        hasExternalWork: Bool
    ) {
        this.allowsAdvance = allowsAdvance
        this.hasExternalWork = hasExternalWork
    }
}

// 内部 runtime step policy:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 internal step decision 所需的脱水 gate policy。
// - 它不定义 public runtime contract、event loop 或 queue / drain policy。

struct CjguiInternalRuntimeStepPolicy {
    let requiresRuntimeReady: Bool
    let requiresInputAllowsAdvance: Bool

    init() {
        this.requiresRuntimeReady = true
        this.requiresInputAllowsAdvance = true
    }

    init(
        requiresRuntimeReady: Bool,
        requiresInputAllowsAdvance: Bool
    ) {
        this.requiresRuntimeReady = requiresRuntimeReady
        this.requiresInputAllowsAdvance = requiresInputAllowsAdvance
    }
}

// 内部 runtime step decision:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 step gate 的脱水 decision summary。
// - 它不改变 root state, 也不运行 event loop 或消费真实 queue。

struct CjguiInternalRuntimeStepDecision {
    let shouldAdvance: Bool
    let isBlockedByRuntimeNotReady: Bool
    let isBlockedByInput: Bool

    init(
        shouldAdvance: Bool,
        isBlockedByRuntimeNotReady: Bool,
        isBlockedByInput: Bool
    ) {
        this.shouldAdvance = shouldAdvance
        this.isBlockedByRuntimeNotReady = isBlockedByRuntimeNotReady
        this.isBlockedByInput = isBlockedByInput
    }
}

// 内部 runtime cycle request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只把 root state、step input 与 step policy 组合成一次脱水 request。
// - 它不代表 event loop、queue / drain、platform callback 或 app run。

struct CjguiInternalRuntimeCycleRequest {
    let state: CjguiInternalRuntimeRootState
    let input: CjguiInternalRuntimeStepInput
    let policy: CjguiInternalRuntimeStepPolicy

    init(
        state: CjguiInternalRuntimeRootState,
        input: CjguiInternalRuntimeStepInput,
        policy: CjguiInternalRuntimeStepPolicy
    ) {
        this.state = state
        this.input = input
        this.policy = policy
    }
}

// 内部 runtime cycle result:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只聚合 cycle request、step result、step decision 与内部进度 marker。
// - 它不改变 root state, 也不消费真实外部事件。

struct CjguiInternalRuntimeCycleResult {
    let request: CjguiInternalRuntimeCycleRequest
    let step: CjguiInternalRuntimeStepResult
    let decision: CjguiInternalRuntimeStepDecision
    let didProduceProgress: Bool

    init(
        request: CjguiInternalRuntimeCycleRequest,
        step: CjguiInternalRuntimeStepResult,
        decision: CjguiInternalRuntimeStepDecision,
        didProduceProgress: Bool
    ) {
        this.request = request
        this.step = step
        this.decision = decision
        this.didProduceProgress = didProduceProgress
    }
}

// 内部 runtime command draft:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达一次 internal cycle 后的下一步意图摘要。
// - 它不是 public command API、renderer command list、event loop task、
//   queue / drain item、platform callback 或 AppKit / Metal command。

struct CjguiInternalRuntimeCommandDraft {
    let shouldRequestNextCycle: Bool
    let shouldReportBlocked: Bool
    let didObserveProgress: Bool

    init(
        shouldRequestNextCycle: Bool,
        shouldReportBlocked: Bool,
        didObserveProgress: Bool
    ) {
        this.shouldRequestNextCycle = shouldRequestNextCycle
        this.shouldReportBlocked = shouldReportBlocked
        this.didObserveProgress = didObserveProgress
    }
}

// 内部 runtime command pipeline request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装一次 internal cycle request, 作为 command pipeline 的输入摘要。
// - 它不是 public API、event loop request、queue item 或 platform callback。

struct CjguiInternalRuntimeCommandPipelineRequest {
    let cycleRequest: CjguiInternalRuntimeCycleRequest

    init(cycleRequest: CjguiInternalRuntimeCycleRequest) {
        this.cycleRequest = cycleRequest
    }
}

// 内部 runtime command pipeline result:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只聚合 pipeline request、cycle result、command draft 与完成 marker。
// - didCompletePipeline 表示 internal summary 已生成, 不代表真实 runtime run。
// - 它不是 renderer command list、event loop、queue / drain 或 platform callback。

struct CjguiInternalRuntimeCommandPipelineResult {
    let request: CjguiInternalRuntimeCommandPipelineRequest
    let cycle: CjguiInternalRuntimeCycleResult
    let draft: CjguiInternalRuntimeCommandDraft
    let didCompletePipeline: Bool

    init(
        request: CjguiInternalRuntimeCommandPipelineRequest,
        cycle: CjguiInternalRuntimeCycleResult,
        draft: CjguiInternalRuntimeCommandDraft,
        didCompletePipeline: Bool
    ) {
        this.request = request
        this.cycle = cycle
        this.draft = draft
        this.didCompletePipeline = didCompletePipeline
    }
}

// 内部 runtime driver request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 command pipeline request, 作为 driver draft 的输入摘要。
// - 它不持有 platform object, 不表示 event loop task 或 queue item。

struct CjguiInternalRuntimeDriverRequest {
    let pipelineRequest: CjguiInternalRuntimeCommandPipelineRequest

    init(pipelineRequest: CjguiInternalRuntimeCommandPipelineRequest) {
        this.pipelineRequest = pipelineRequest
    }
}

// 内部 runtime driver result:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只从 pipeline result / command draft 投影 driver-level summary。
// - didCompleteDriverPass 只表示 internal summary pass 已完成。
// - 它不代表真实 runtime driver、app run、event loop 或 queue / drain。

struct CjguiInternalRuntimeDriverResult {
    let request: CjguiInternalRuntimeDriverRequest
    let pipeline: CjguiInternalRuntimeCommandPipelineResult
    let didCompleteDriverPass: Bool
    let shouldRequestNextCycle: Bool
    let shouldReportBlocked: Bool
    let didObserveProgress: Bool

    init(
        request: CjguiInternalRuntimeDriverRequest,
        pipeline: CjguiInternalRuntimeCommandPipelineResult,
        didCompleteDriverPass: Bool,
        shouldRequestNextCycle: Bool,
        shouldReportBlocked: Bool,
        didObserveProgress: Bool
    ) {
        this.request = request
        this.pipeline = pipeline
        this.didCompleteDriverPass = didCompleteDriverPass
        this.shouldRequestNextCycle = shouldRequestNextCycle
        this.shouldReportBlocked = shouldReportBlocked
        this.didObserveProgress = didObserveProgress
    }
}

// 内部 runtime driver input:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 driver-level 脱水 input gate。
// - hasExternalDriverWork 只是 marker, 不代表 event queue、callback、
//   platform event、render command 或 native task。

struct CjguiInternalRuntimeDriverInput {
    let allowsDriverPass: Bool
    let hasExternalDriverWork: Bool

    init() {
        this.allowsDriverPass = true
        this.hasExternalDriverWork = true
    }

    init(
        allowsDriverPass: Bool,
        hasExternalDriverWork: Bool
    ) {
        this.allowsDriverPass = allowsDriverPass
        this.hasExternalDriverWork = hasExternalDriverWork
    }
}

// 内部 runtime driver policy:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 driver pass 是否允许执行 pipeline summary 的脱水 policy。
// - 它不是 scheduling policy、threading policy、queue drain policy 或
//   platform runloop policy。

struct CjguiInternalRuntimeDriverPolicy {
    let requiresRuntimeReady: Bool
    let requiresInputAllowsDriverPass: Bool

    init() {
        this.requiresRuntimeReady = true
        this.requiresInputAllowsDriverPass = true
    }

    init(
        requiresRuntimeReady: Bool,
        requiresInputAllowsDriverPass: Bool
    ) {
        this.requiresRuntimeReady = requiresRuntimeReady
        this.requiresInputAllowsDriverPass = requiresInputAllowsDriverPass
    }
}

// 内部 runtime driver decision:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 driver pass gate 的脱水 decision summary。
// - 它不执行 pipeline, 不产生真实 runtime side effect。

struct CjguiInternalRuntimeDriverDecision {
    let shouldRunPipeline: Bool
    let isBlockedByRuntimeNotReady: Bool
    let isBlockedByInput: Bool

    init(
        shouldRunPipeline: Bool,
        isBlockedByRuntimeNotReady: Bool,
        isBlockedByInput: Bool
    ) {
        this.shouldRunPipeline = shouldRunPipeline
        this.isBlockedByRuntimeNotReady = isBlockedByRuntimeNotReady
        this.isBlockedByInput = isBlockedByInput
    }
}

// 内部 runtime driver report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只把 driver pass result 规整为 internal next-action summary。
// - isReadyForNextInternalPass 只表示 internal report 派生 marker。
// - 它不是 scheduler decision、queue item、event loop command 或
//   renderer command list。

struct CjguiInternalRuntimeDriverReport {
    let result: CjguiInternalRuntimeDriverResult
    let didCompleteDriverPass: Bool
    let shouldRequestNextCycle: Bool
    let shouldReportBlocked: Bool
    let didObserveProgress: Bool
    let isReadyForNextInternalPass: Bool

    init(
        result: CjguiInternalRuntimeDriverResult,
        didCompleteDriverPass: Bool,
        shouldRequestNextCycle: Bool,
        shouldReportBlocked: Bool,
        didObserveProgress: Bool,
        isReadyForNextInternalPass: Bool
    ) {
        this.result = result
        this.didCompleteDriverPass = didCompleteDriverPass
        this.shouldRequestNextCycle = shouldRequestNextCycle
        this.shouldReportBlocked = shouldReportBlocked
        this.didObserveProgress = didObserveProgress
        this.isReadyForNextInternalPass = isReadyForNextInternalPass
    }
}

// 内部 runtime run intent:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只把 driver report 投影为 internal run-boundary intent summary。
// - 它不表示真实 run loop、scheduler、queue item、event loop command
//   或 public runtime run API。

struct CjguiInternalRuntimeRunIntent {
    let report: CjguiInternalRuntimeDriverReport
    let mayRequestRuntimeRun: Bool
    let shouldContinueInternalCycles: Bool
    let shouldSurfaceBlockedReport: Bool
    let didObserveInternalProgress: Bool

    init(
        report: CjguiInternalRuntimeDriverReport,
        mayRequestRuntimeRun: Bool,
        shouldContinueInternalCycles: Bool,
        shouldSurfaceBlockedReport: Bool,
        didObserveInternalProgress: Bool
    ) {
        this.report = report
        this.mayRequestRuntimeRun = mayRequestRuntimeRun
        this.shouldContinueInternalCycles = shouldContinueInternalCycles
        this.shouldSurfaceBlockedReport = shouldSurfaceBlockedReport
        this.didObserveInternalProgress = didObserveInternalProgress
    }
}

// 内部 runtime run request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只把 run intent 包装为 internal run request summary。
// - isRequestAllowed 只来自 intent.mayRequestRuntimeRun。
// - 它不是 public run() 调用、event loop start、platform callback
//   或 queue item。

struct CjguiInternalRuntimeRunRequest {
    let intent: CjguiInternalRuntimeRunIntent
    let isRequestAllowed: Bool

    init(
        intent: CjguiInternalRuntimeRunIntent,
        isRequestAllowed: Bool
    ) {
        this.intent = intent
        this.isRequestAllowed = isRequestAllowed
    }
}

// 内部 runtime run request report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 internal request evaluation summary。
// - 它不启动 runtime, 不循环, 不调用平台。

struct CjguiInternalRuntimeRunRequestReport {
    let request: CjguiInternalRuntimeRunRequest
    let didAcceptRequest: Bool
    let shouldDeferRequest: Bool
    let shouldSurfaceBlockedReport: Bool
    let didObserveInternalProgress: Bool

    init(
        request: CjguiInternalRuntimeRunRequest,
        didAcceptRequest: Bool,
        shouldDeferRequest: Bool,
        shouldSurfaceBlockedReport: Bool,
        didObserveInternalProgress: Bool
    ) {
        this.request = request
        this.didAcceptRequest = didAcceptRequest
        this.shouldDeferRequest = shouldDeferRequest
        this.shouldSurfaceBlockedReport = shouldSurfaceBlockedReport
        this.didObserveInternalProgress = didObserveInternalProgress
    }
}

// 内部 runtime shutdown intent:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 shutdown / cancellation 的脱水 intent summary。
// - 它不表示真实 app shutdown、event loop stop、queue drain 或
//   platform close callback。

struct CjguiInternalRuntimeShutdownIntent {
    let shouldRequestShutdown: Bool
    let shouldRequestCancellation: Bool

    init(
        shouldRequestShutdown: Bool,
        shouldRequestCancellation: Bool
    ) {
        this.shouldRequestShutdown = shouldRequestShutdown
        this.shouldRequestCancellation = shouldRequestCancellation
    }
}

// 内部 runtime shutdown request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只把 shutdown intent 包装为 internal request summary。
// - 它不执行 shutdown, 不取消 task, 不消费 queue。

struct CjguiInternalRuntimeShutdownRequest {
    let intent: CjguiInternalRuntimeShutdownIntent
    let isShutdownRequested: Bool
    let isCancellationRequested: Bool

    init(
        intent: CjguiInternalRuntimeShutdownIntent,
        isShutdownRequested: Bool,
        isCancellationRequested: Bool
    ) {
        this.intent = intent
        this.isShutdownRequested = isShutdownRequested
        this.isCancellationRequested = isCancellationRequested
    }
}

// 内部 runtime shutdown report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 shutdown/cancel request 对 run request 的内部影响。
// - 它不是真实 error system, 不执行 shutdown 或 cancellation。

struct CjguiInternalRuntimeShutdownReport {
    let request: CjguiInternalRuntimeShutdownRequest
    let shouldDeferRunRequest: Bool
    let shouldEnterShutdownPath: Bool
    let shouldEnterCancellationPath: Bool

    init(
        request: CjguiInternalRuntimeShutdownRequest,
        shouldDeferRunRequest: Bool,
        shouldEnterShutdownPath: Bool,
        shouldEnterCancellationPath: Bool
    ) {
        this.request = request
        this.shouldDeferRunRequest = shouldDeferRunRequest
        this.shouldEnterShutdownPath = shouldEnterShutdownPath
        this.shouldEnterCancellationPath = shouldEnterCancellationPath
    }
}

// 内部 run boundary request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只聚合 internal run request report 与 shutdown/cancellation report。
// - 它不表示 public run() request、event loop request 或 platform callback。

struct CjguiInternalRunBoundaryRequest {
    let runRequestReport: CjguiInternalRuntimeRunRequestReport
    let shutdownReport: CjguiInternalRuntimeShutdownReport

    init(
        runRequestReport: CjguiInternalRuntimeRunRequestReport,
        shutdownReport: CjguiInternalRuntimeShutdownReport
    ) {
        this.runRequestReport = runRequestReport
        this.shutdownReport = shutdownReport
    }
}

// 内部 run boundary report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 internal run boundary readiness summary。
// - 它不执行 run, 不启动 loop, 不触发 shutdown。

struct CjguiInternalRunBoundaryReport {
    let request: CjguiInternalRunBoundaryRequest
    let isBoundaryOpen: Bool
    let isBoundaryDeferred: Bool
    let isBoundaryBlocked: Bool
    let isBlockedByRunRequest: Bool
    let isBlockedByShutdown: Bool
    let isBlockedByCancellation: Bool

    init(
        request: CjguiInternalRunBoundaryRequest,
        isBoundaryOpen: Bool,
        isBoundaryDeferred: Bool,
        isBoundaryBlocked: Bool,
        isBlockedByRunRequest: Bool,
        isBlockedByShutdown: Bool,
        isBlockedByCancellation: Bool
    ) {
        this.request = request
        this.isBoundaryOpen = isBoundaryOpen
        this.isBoundaryDeferred = isBoundaryDeferred
        this.isBoundaryBlocked = isBoundaryBlocked
        this.isBlockedByRunRequest = isBlockedByRunRequest
        this.isBlockedByShutdown = isBlockedByShutdown
        this.isBlockedByCancellation = isBlockedByCancellation
    }
}

// 内部 app run surface state:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只从 run boundary report 投影 app-run surface facts。
// - 它不表示真实 app running 状态、event loop active 或 platform app object。

struct CjguiInternalAppRunState {
    let boundaryReport: CjguiInternalRunBoundaryReport
    let isAppRunAllowed: Bool
    let isAppRunDeferred: Bool
    let isAppRunBlocked: Bool

    init(
        boundaryReport: CjguiInternalRunBoundaryReport,
        isAppRunAllowed: Bool,
        isAppRunDeferred: Bool,
        isAppRunBlocked: Bool
    ) {
        this.boundaryReport = boundaryReport
        this.isAppRunAllowed = isAppRunAllowed
        this.isAppRunDeferred = isAppRunDeferred
        this.isAppRunBlocked = isAppRunBlocked
    }
}

// 内部 app run request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 internal run boundary report。
// - 它不是 public run() request, 也不是 platform run request。

struct CjguiInternalAppRunRequest {
    let boundaryReport: CjguiInternalRunBoundaryReport

    init(
        boundaryReport: CjguiInternalRunBoundaryReport
    ) {
        this.boundaryReport = boundaryReport
    }
}

// 内部 app run report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 internal app run surface evaluation summary。
// - 它不执行 run, 不启动 loop, 不调用平台。

struct CjguiInternalAppRunReport {
    let request: CjguiInternalAppRunRequest
    let state: CjguiInternalAppRunState
    let didAcceptAppRun: Bool
    let shouldDeferAppRun: Bool
    let shouldReportAppRunBlocked: Bool

    init(
        request: CjguiInternalAppRunRequest,
        state: CjguiInternalAppRunState,
        didAcceptAppRun: Bool,
        shouldDeferAppRun: Bool,
        shouldReportAppRunBlocked: Bool
    ) {
        this.request = request
        this.state = state
        this.didAcceptAppRun = didAcceptAppRun
        this.shouldDeferAppRun = shouldDeferAppRun
        this.shouldReportAppRunBlocked = shouldReportAppRunBlocked
    }
}

// 内部 app run controller request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 AppRun surface report。
// - 它不是 public run request、event loop task、platform callback 或 queue item。

struct CjguiInternalAppRunControllerRequest {
    let appRunReport: CjguiInternalAppRunReport

    init(
        appRunReport: CjguiInternalAppRunReport
    ) {
        this.appRunReport = appRunReport
    }
}

// 内部 app run controller decision:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只从 AppRun report 派生 internal next-action summary。
// - 它不执行 accepted / deferred / blocked action, 也不是 scheduler decision。

struct CjguiInternalAppRunControllerDecision {
    let shouldEnterAcceptedPath: Bool
    let shouldEnterDeferredPath: Bool
    let shouldEnterBlockedPath: Bool
    let shouldRequestFutureRunBoundary: Bool

    init(
        shouldEnterAcceptedPath: Bool,
        shouldEnterDeferredPath: Bool,
        shouldEnterBlockedPath: Bool,
        shouldRequestFutureRunBoundary: Bool
    ) {
        this.shouldEnterAcceptedPath = shouldEnterAcceptedPath
        this.shouldEnterDeferredPath = shouldEnterDeferredPath
        this.shouldEnterBlockedPath = shouldEnterBlockedPath
        this.shouldRequestFutureRunBoundary = shouldRequestFutureRunBoundary
    }
}

// 内部 app run controller report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 controller draft evaluation summary。
// - didEvaluateController 只表示 internal evaluation completed, 不表示 run loop started。

struct CjguiInternalAppRunControllerReport {
    let request: CjguiInternalAppRunControllerRequest
    let decision: CjguiInternalAppRunControllerDecision
    let didEvaluateController: Bool

    init(
        request: CjguiInternalAppRunControllerRequest,
        decision: CjguiInternalAppRunControllerDecision,
        didEvaluateController: Bool
    ) {
        this.request = request
        this.decision = decision
        this.didEvaluateController = didEvaluateController
    }
}

// 内部 app run execution plan request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 AppRun controller report。
// - 它不是 public run request、event loop task、platform callback 或 queue item。

struct CjguiInternalAppRunExecutionPlanRequest {
    let controllerReport: CjguiInternalAppRunControllerReport

    init(
        controllerReport: CjguiInternalAppRunControllerReport
    ) {
        this.controllerReport = controllerReport
    }
}

// 内部 app run execution plan:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 future execution phases 的脱水 internal plan。
// - shouldEnterRunLoopDraft 不是真实 event loop, 本 struct 不执行任何阶段。

struct CjguiInternalAppRunExecutionPlan {
    let shouldPrepareRuntime: Bool
    let shouldEnterRunLoopDraft: Bool
    let shouldDeferExecution: Bool
    let shouldReportBlockedExecution: Bool
    let shouldRequestFutureBoundary: Bool

    init(
        shouldPrepareRuntime: Bool,
        shouldEnterRunLoopDraft: Bool,
        shouldDeferExecution: Bool,
        shouldReportBlockedExecution: Bool,
        shouldRequestFutureBoundary: Bool
    ) {
        this.shouldPrepareRuntime = shouldPrepareRuntime
        this.shouldEnterRunLoopDraft = shouldEnterRunLoopDraft
        this.shouldDeferExecution = shouldDeferExecution
        this.shouldReportBlockedExecution = shouldReportBlockedExecution
        this.shouldRequestFutureBoundary = shouldRequestFutureBoundary
    }
}

// 内部 app run execution plan report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 plan draft 已构建。
// - didBuildPlan 只表示 internal planning completed, 不表示 plan 已执行。

struct CjguiInternalAppRunExecutionPlanReport {
    let request: CjguiInternalAppRunExecutionPlanRequest
    let plan: CjguiInternalAppRunExecutionPlan
    let didBuildPlan: Bool

    init(
        request: CjguiInternalAppRunExecutionPlanRequest,
        plan: CjguiInternalAppRunExecutionPlan,
        didBuildPlan: Bool
    ) {
        this.request = request
        this.plan = plan
        this.didBuildPlan = didBuildPlan
    }
}

// 内部 app run dispatch request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 AppRun execution plan report。
// - 它不是 queue item、event loop task、platform callback 或 public run request。

struct CjguiInternalAppRunDispatchRequest {
    let planReport: CjguiInternalAppRunExecutionPlanReport

    init(
        planReport: CjguiInternalAppRunExecutionPlanReport
    ) {
        this.planReport = planReport
    }
}

// 内部 app run dispatch summary:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 dispatch-facing 脱水 summary。
// - shouldDispatchRunLoopDraft 不是真实 event loop, 本 struct 不执行 dispatch。

struct CjguiInternalAppRunDispatchSummary {
    let shouldDispatchPrepareRuntime: Bool
    let shouldDispatchRunLoopDraft: Bool
    let shouldDispatchDeferredNotice: Bool
    let shouldDispatchBlockedNotice: Bool
    let shouldDispatchFutureBoundaryRequest: Bool

    init(
        shouldDispatchPrepareRuntime: Bool,
        shouldDispatchRunLoopDraft: Bool,
        shouldDispatchDeferredNotice: Bool,
        shouldDispatchBlockedNotice: Bool,
        shouldDispatchFutureBoundaryRequest: Bool
    ) {
        this.shouldDispatchPrepareRuntime = shouldDispatchPrepareRuntime
        this.shouldDispatchRunLoopDraft = shouldDispatchRunLoopDraft
        this.shouldDispatchDeferredNotice = shouldDispatchDeferredNotice
        this.shouldDispatchBlockedNotice = shouldDispatchBlockedNotice
        this.shouldDispatchFutureBoundaryRequest = shouldDispatchFutureBoundaryRequest
    }
}

// 内部 app run dispatch report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 dispatch summary 已构建。
// - didBuildDispatchSummary 只表示 internal dispatch planning completed。

struct CjguiInternalAppRunDispatchReport {
    let request: CjguiInternalAppRunDispatchRequest
    let summary: CjguiInternalAppRunDispatchSummary
    let didBuildDispatchSummary: Bool

    init(
        request: CjguiInternalAppRunDispatchRequest,
        summary: CjguiInternalAppRunDispatchSummary,
        didBuildDispatchSummary: Bool
    ) {
        this.request = request
        this.summary = summary
        this.didBuildDispatchSummary = didBuildDispatchSummary
    }
}

// 内部 run loop draft request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 AppRun dispatch report。
// - 它不是 real event loop request、queue item、platform callback 或 scheduler task。

struct CjguiInternalRunLoopDraftRequest {
    let dispatchReport: CjguiInternalAppRunDispatchReport

    init(
        dispatchReport: CjguiInternalAppRunDispatchReport
    ) {
        this.dispatchReport = dispatchReport
    }
}

// 内部 run loop draft intent:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 loop-intent 脱水 summary。
// - shouldEnterLoopDraft 不是真实 event loop, 本 struct 不启动 loop。

struct CjguiInternalRunLoopDraftIntent {
    let shouldEnterLoopDraft: Bool
    let shouldDeferLoopDraft: Bool
    let shouldReportLoopBlocked: Bool
    let shouldRequestFutureBoundary: Bool

    init(
        shouldEnterLoopDraft: Bool,
        shouldDeferLoopDraft: Bool,
        shouldReportLoopBlocked: Bool,
        shouldRequestFutureBoundary: Bool
    ) {
        this.shouldEnterLoopDraft = shouldEnterLoopDraft
        this.shouldDeferLoopDraft = shouldDeferLoopDraft
        this.shouldReportLoopBlocked = shouldReportLoopBlocked
        this.shouldRequestFutureBoundary = shouldRequestFutureBoundary
    }
}

// 内部 run loop draft report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 loop draft 已构建。
// - didBuildLoopDraft 只表示 internal loop-intent planning completed。

struct CjguiInternalRunLoopDraftReport {
    let request: CjguiInternalRunLoopDraftRequest
    let intent: CjguiInternalRunLoopDraftIntent
    let didBuildLoopDraft: Bool

    init(
        request: CjguiInternalRunLoopDraftRequest,
        intent: CjguiInternalRunLoopDraftIntent,
        didBuildLoopDraft: Bool
    ) {
        this.request = request
        this.intent = intent
        this.didBuildLoopDraft = didBuildLoopDraft
    }
}

// 内部 single loop iteration draft request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 RunLoopDraft report。
// - 它不是 real loop iteration request、queue item、platform callback 或
//   scheduler task。

struct CjguiInternalLoopIterationDraftRequest {
    let loopDraftReport: CjguiInternalRunLoopDraftReport

    init(
        loopDraftReport: CjguiInternalRunLoopDraftReport
    ) {
        this.loopDraftReport = loopDraftReport
    }
}

// 内部 single loop iteration draft intent:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 single iteration intent 脱水 summary。
// - shouldAttemptIteration 不是真实 loop iteration, 本 struct 不执行 iteration。

struct CjguiInternalLoopIterationDraftIntent {
    let shouldAttemptIteration: Bool
    let shouldDeferIteration: Bool
    let shouldReportIterationBlocked: Bool
    let shouldRequestFutureBoundary: Bool

    init(
        shouldAttemptIteration: Bool,
        shouldDeferIteration: Bool,
        shouldReportIterationBlocked: Bool,
        shouldRequestFutureBoundary: Bool
    ) {
        this.shouldAttemptIteration = shouldAttemptIteration
        this.shouldDeferIteration = shouldDeferIteration
        this.shouldReportIterationBlocked = shouldReportIterationBlocked
        this.shouldRequestFutureBoundary = shouldRequestFutureBoundary
    }
}

// 内部 single loop iteration draft report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 single iteration draft 已构建。
// - didBuildIterationDraft 只表示 internal iteration planning completed。

struct CjguiInternalLoopIterationDraftReport {
    let request: CjguiInternalLoopIterationDraftRequest
    let intent: CjguiInternalLoopIterationDraftIntent
    let didBuildIterationDraft: Bool

    init(
        request: CjguiInternalLoopIterationDraftRequest,
        intent: CjguiInternalLoopIterationDraftIntent,
        didBuildIterationDraft: Bool
    ) {
        this.request = request
        this.intent = intent
        this.didBuildIterationDraft = didBuildIterationDraft
    }
}

// 内部 iteration work packet draft request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 LoopIterationDraft report。
// - 它不是 queue item、work execution request、platform callback 或
//   input / layout / render task。

struct CjguiInternalIterationWorkPacketDraftRequest {
    let iterationReport: CjguiInternalLoopIterationDraftReport

    init(
        iterationReport: CjguiInternalLoopIterationDraftReport
    ) {
        this.iterationReport = iterationReport
    }
}

// 内部 iteration work packet draft:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 single iteration 可能涉及的 internal work-category summary。
// - shouldProcessLifecycleWork 不是真实 lifecycle execution。
// - 本 struct 不执行 runtime work、input processing、layout 或 render。

struct CjguiInternalIterationWorkPacketDraft {
    let shouldPrepareRuntimeWork: Bool
    let shouldProcessLifecycleWork: Bool
    let shouldPrepareFutureBoundaryWork: Bool
    let shouldDeferWork: Bool
    let shouldReportBlockedWork: Bool

    init(
        shouldPrepareRuntimeWork: Bool,
        shouldProcessLifecycleWork: Bool,
        shouldPrepareFutureBoundaryWork: Bool,
        shouldDeferWork: Bool,
        shouldReportBlockedWork: Bool
    ) {
        this.shouldPrepareRuntimeWork = shouldPrepareRuntimeWork
        this.shouldProcessLifecycleWork = shouldProcessLifecycleWork
        this.shouldPrepareFutureBoundaryWork = shouldPrepareFutureBoundaryWork
        this.shouldDeferWork = shouldDeferWork
        this.shouldReportBlockedWork = shouldReportBlockedWork
    }
}

// 内部 iteration work packet draft report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 work packet draft 已构建。
// - didBuildWorkPacket 只表示 internal packet planning completed。

struct CjguiInternalIterationWorkPacketDraftReport {
    let request: CjguiInternalIterationWorkPacketDraftRequest
    let packet: CjguiInternalIterationWorkPacketDraft
    let didBuildWorkPacket: Bool

    init(
        request: CjguiInternalIterationWorkPacketDraftRequest,
        packet: CjguiInternalIterationWorkPacketDraft,
        didBuildWorkPacket: Bool
    ) {
        this.request = request
        this.packet = packet
        this.didBuildWorkPacket = didBuildWorkPacket
    }
}

// 内部 lifecycle work draft request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 IterationWorkPacketDraft report。
// - 它不是 lifecycle execution request、app/window state mutation request、
//   platform callback 或 queue item。

struct CjguiInternalLifecycleWorkDraftRequest {
    let workPacketReport: CjguiInternalIterationWorkPacketDraftReport

    init(
        workPacketReport: CjguiInternalIterationWorkPacketDraftReport
    ) {
        this.workPacketReport = workPacketReport
    }
}

// 内部 lifecycle work draft:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 lifecycle-work summary。
// - shouldProcessLifecycleWork 不是真实 lifecycle execution。
// - 本 struct 不修改 app/window state, 不调用 platform。

struct CjguiInternalLifecycleWorkDraft {
    let shouldProcessLifecycleWork: Bool
    let shouldDeferLifecycleWork: Bool
    let shouldReportLifecycleBlocked: Bool
    let shouldPrepareFutureBoundaryAfterLifecycle: Bool

    init(
        shouldProcessLifecycleWork: Bool,
        shouldDeferLifecycleWork: Bool,
        shouldReportLifecycleBlocked: Bool,
        shouldPrepareFutureBoundaryAfterLifecycle: Bool
    ) {
        this.shouldProcessLifecycleWork = shouldProcessLifecycleWork
        this.shouldDeferLifecycleWork = shouldDeferLifecycleWork
        this.shouldReportLifecycleBlocked = shouldReportLifecycleBlocked
        this.shouldPrepareFutureBoundaryAfterLifecycle = shouldPrepareFutureBoundaryAfterLifecycle
    }
}

// 内部 lifecycle work draft report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 lifecycle work draft 已构建。
// - didBuildLifecycleWorkDraft 只表示 internal planning completed。

struct CjguiInternalLifecycleWorkDraftReport {
    let request: CjguiInternalLifecycleWorkDraftRequest
    let draft: CjguiInternalLifecycleWorkDraft
    let didBuildLifecycleWorkDraft: Bool

    init(
        request: CjguiInternalLifecycleWorkDraftRequest,
        draft: CjguiInternalLifecycleWorkDraft,
        didBuildLifecycleWorkDraft: Bool
    ) {
        this.request = request
        this.draft = draft
        this.didBuildLifecycleWorkDraft = didBuildLifecycleWorkDraft
    }
}

// 内部 lifecycle owner handoff request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 runtime-level LifecycleWorkDraft report。
// - runtime_state.cj 在这里仅作为 cross-owner routing owner。
// - 它不拥有 app/window lifecycle semantics。

struct CjguiInternalLifecycleOwnerHandoffRequest {
    let lifecycleWorkReport: CjguiInternalLifecycleWorkDraftReport

    init(
        lifecycleWorkReport: CjguiInternalLifecycleWorkDraftReport
    ) {
        this.lifecycleWorkReport = lifecycleWorkReport
    }
}

// 内部 lifecycle owner handoff report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 app/window owner-facing handoff drafts 已生成。
// - 它不执行 app/window lifecycle work, 不修改 app/window state。

struct CjguiInternalLifecycleOwnerHandoffReport {
    let request: CjguiInternalLifecycleOwnerHandoffRequest
    let appDraft: CjguiInternalAppLifecycleWorkHandoffDraft
    let windowDraft: CjguiInternalWindowLifecycleWorkHandoffDraft
    let didBuildOwnerHandoff: Bool

    init(
        request: CjguiInternalLifecycleOwnerHandoffRequest,
        appDraft: CjguiInternalAppLifecycleWorkHandoffDraft,
        windowDraft: CjguiInternalWindowLifecycleWorkHandoffDraft,
        didBuildOwnerHandoff: Bool
    ) {
        this.request = request
        this.appDraft = appDraft
        this.windowDraft = windowDraft
        this.didBuildOwnerHandoff = didBuildOwnerHandoff
    }
}

// 内部 lifecycle mutation readiness request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 owner handoff report。
// - runtime_state.cj 在这里仅作为 cross-owner readiness routing owner。
// - 它不拥有 app/window lifecycle mutation semantics。

struct CjguiInternalLifecycleMutationReadinessRequest {
    let ownerHandoffReport: CjguiInternalLifecycleOwnerHandoffReport

    init(
        ownerHandoffReport: CjguiInternalLifecycleOwnerHandoffReport
    ) {
        this.ownerHandoffReport = ownerHandoffReport
    }
}

// 内部 lifecycle mutation readiness report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 app/window mutation readiness summary。
// - canMutateLifecycleOwners 不是真实 mutation execution。
// - 它不执行 lifecycle mutation, 不修改 app/window state。

struct CjguiInternalLifecycleMutationReadinessReport {
    let request: CjguiInternalLifecycleMutationReadinessRequest
    let appReadiness: CjguiInternalAppLifecycleMutationReadinessDraft
    let windowReadiness: CjguiInternalWindowLifecycleMutationReadinessDraft
    let canMutateLifecycleOwners: Bool
    let shouldDeferLifecycleMutation: Bool
    let shouldReportLifecycleMutationBlocked: Bool
    let didBuildMutationReadiness: Bool

    init(
        request: CjguiInternalLifecycleMutationReadinessRequest,
        appReadiness: CjguiInternalAppLifecycleMutationReadinessDraft,
        windowReadiness: CjguiInternalWindowLifecycleMutationReadinessDraft,
        canMutateLifecycleOwners: Bool,
        shouldDeferLifecycleMutation: Bool,
        shouldReportLifecycleMutationBlocked: Bool,
        didBuildMutationReadiness: Bool
    ) {
        this.request = request
        this.appReadiness = appReadiness
        this.windowReadiness = windowReadiness
        this.canMutateLifecycleOwners = canMutateLifecycleOwners
        this.shouldDeferLifecycleMutation = shouldDeferLifecycleMutation
        this.shouldReportLifecycleMutationBlocked = shouldReportLifecycleMutationBlocked
        this.didBuildMutationReadiness = didBuildMutationReadiness
    }
}

// 内部 lifecycle mutation plan request:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只包装 mutation readiness report。
// - runtime_state.cj 在这里仅作为 cross-owner mutation plan routing owner。
// - 它不拥有 app/window lifecycle mutation semantics。

struct CjguiInternalLifecycleMutationPlanRequest {
    let readinessReport: CjguiInternalLifecycleMutationReadinessReport

    init(
        readinessReport: CjguiInternalLifecycleMutationReadinessReport
    ) {
        this.readinessReport = readinessReport
    }
}

// 内部 lifecycle mutation plan report:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 app/window mutation plan summary。
// - shouldPlanLifecycleMutation 不是真实 mutation execution。
// - 它不执行 lifecycle mutation, 不修改 app/window state。

struct CjguiInternalLifecycleMutationPlanReport {
    let request: CjguiInternalLifecycleMutationPlanRequest
    let appPlan: CjguiInternalAppLifecycleMutationPlanDraft
    let windowPlan: CjguiInternalWindowLifecycleMutationPlanDraft
    let shouldPlanLifecycleMutation: Bool
    let shouldDeferLifecycleMutationPlan: Bool
    let shouldReportLifecycleMutationPlanBlocked: Bool
    let didBuildMutationPlan: Bool

    init(
        request: CjguiInternalLifecycleMutationPlanRequest,
        appPlan: CjguiInternalAppLifecycleMutationPlanDraft,
        windowPlan: CjguiInternalWindowLifecycleMutationPlanDraft,
        shouldPlanLifecycleMutation: Bool,
        shouldDeferLifecycleMutationPlan: Bool,
        shouldReportLifecycleMutationPlanBlocked: Bool,
        didBuildMutationPlan: Bool
    ) {
        this.request = request
        this.appPlan = appPlan
        this.windowPlan = windowPlan
        this.shouldPlanLifecycleMutation = shouldPlanLifecycleMutation
        this.shouldDeferLifecycleMutationPlan = shouldDeferLifecycleMutationPlan
        this.shouldReportLifecycleMutationPlanBlocked = shouldReportLifecycleMutationPlanBlocked
        this.didBuildMutationPlan = didBuildMutationPlan
    }
}

func cjguiInternalDefaultRuntimeStepInput(): CjguiInternalRuntimeStepInput {
    return CjguiInternalRuntimeStepInput()
}

func cjguiInternalDefaultRuntimeStepPolicy(): CjguiInternalRuntimeStepPolicy {
    return CjguiInternalRuntimeStepPolicy()
}

// 内部 runtime root state builder:
// - 这是普通顶层函数, 使用默认 internal 可见性。
// - 它只复用既有 bootstrap snapshot builder。
// - 它用 bootstrap readiness Bool 形成 runtime readiness marker。
// - 它不实现 app run、event loop、queue / drain、window create 或 shutdown。
// - 它不改变 bootstrap、projection、coordination、state shape、constructor shape、
//   public runtime API 或 public C ABI。

func cjguiInternalBuildRuntimeRootState(): CjguiInternalRuntimeRootState {
    let bootstrap = cjguiInternalBuildRuntimeBootstrapSnapshot()
    return CjguiInternalRuntimeRootState(
        bootstrap,
        bootstrap.isBootstrapReady
    )
}

func cjguiInternalDefaultRuntimeCycleRequest(): CjguiInternalRuntimeCycleRequest {
    return CjguiInternalRuntimeCycleRequest(
        cjguiInternalBuildRuntimeRootState(),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
}

func cjguiInternalDefaultRuntimeCommandPipelineRequest(
): CjguiInternalRuntimeCommandPipelineRequest {
    return CjguiInternalRuntimeCommandPipelineRequest(
        cjguiInternalDefaultRuntimeCycleRequest()
    )
}

func cjguiInternalDefaultRuntimeDriverRequest(
): CjguiInternalRuntimeDriverRequest {
    return CjguiInternalRuntimeDriverRequest(
        cjguiInternalDefaultRuntimeCommandPipelineRequest()
    )
}

func cjguiInternalDefaultRuntimeDriverInput(): CjguiInternalRuntimeDriverInput {
    return CjguiInternalRuntimeDriverInput()
}

func cjguiInternalDefaultRuntimeDriverPolicy(
): CjguiInternalRuntimeDriverPolicy {
    return CjguiInternalRuntimeDriverPolicy()
}

// 内部 runtime root ready sanity helper:
// - 这是普通顶层函数, 使用默认 internal 可见性。
// - 它只复用既有 root state builder。
// - 它返回 root readiness Bool, 不新增 runtime behavior。
// - 它不改变 root state shape、bootstrap builder behavior、projection、
//   coordination、constructor shape、public runtime API 或 public C ABI。

func cjguiInternalRuntimeRootStateReadySanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    return root.isRuntimeReady
}

// 内部 runtime step:
// - 这是普通顶层函数, 使用默认 internal 可见性。
// - 它只读取 root readiness Bool 并返回脱水 step result。
// - 它原样保留输入 state, 不新增 runtime behavior。
// - 它不实现 app run、event loop、callback binding、queue / drain、
//   window create 或 shutdown。
// - 它不改变 root state shape、bootstrap behavior、projection、coordination、
//   constructor shape、public runtime API 或 public C ABI。

func cjguiInternalRuntimeStep(
    state: CjguiInternalRuntimeRootState
): CjguiInternalRuntimeStepResult {
    if (state.isRuntimeReady) {
        return CjguiInternalRuntimeStepResult(
            state,
            true,
            false,
            false,
            false
        )
    }

    return CjguiInternalRuntimeStepResult(
        state,
        false,
        true,
        true,
        false
    )
}

// 内部 runtime step decision function:
// - 它只组合 root readiness、step input 与 step policy。
// - 它不改变 root state, 不运行 event loop, 不消费真实 queue。
// - runtime-not-ready blocker 优先于 input blocker, 保持单一 fail-closed reason。

func cjguiInternalDecideRuntimeStep(
    state: CjguiInternalRuntimeRootState,
    input: CjguiInternalRuntimeStepInput,
    policy: CjguiInternalRuntimeStepPolicy
): CjguiInternalRuntimeStepDecision {
    if (policy.requiresRuntimeReady) {
        if (state.isRuntimeReady == false) {
            return CjguiInternalRuntimeStepDecision(
                false,
                true,
                false
            )
        }
    }

    if (policy.requiresInputAllowsAdvance) {
        if (input.allowsAdvance == false) {
            return CjguiInternalRuntimeStepDecision(
                false,
                false,
                true
            )
        }
    }

    return CjguiInternalRuntimeStepDecision(
        true,
        false,
        false
    )
}

// 内部 runtime step-with-input-policy:
// - 它复用 decision function 并原样返回输入 state。
// - didAdvance 只来自 decision.shouldAdvance。
// - 它不改变既有 cjguiInternalRuntimeStep(state) 行为。

func cjguiInternalRuntimeStepWithInput(
    state: CjguiInternalRuntimeRootState,
    input: CjguiInternalRuntimeStepInput,
    policy: CjguiInternalRuntimeStepPolicy
): CjguiInternalRuntimeStepResult {
    let decision = cjguiInternalDecideRuntimeStep(state, input, policy)
    if (decision.shouldAdvance) {
        return CjguiInternalRuntimeStepResult(
            state,
            true,
            false,
            decision.isBlockedByRuntimeNotReady,
            decision.isBlockedByInput
        )
    }

    return CjguiInternalRuntimeStepResult(
        state,
        false,
        true,
        decision.isBlockedByRuntimeNotReady,
        decision.isBlockedByInput
    )
}

// 内部 runtime cycle executor:
// - 它只对 request 内的 state/input/policy 运行一次脱水 decision 与 step。
// - didProduceProgress 只由 step.didAdvance 派生。
// - 它不改变 request.state, 不循环, 不消费 queue 或 platform callback。
// - 它不实现 app run、event loop、window create 或 shutdown。

func cjguiInternalExecuteRuntimeCycle(
    request: CjguiInternalRuntimeCycleRequest
): CjguiInternalRuntimeCycleResult {
    let decision = cjguiInternalDecideRuntimeStep(
        request.state,
        request.input,
        request.policy
    )
    let step = cjguiInternalRuntimeStepWithInput(
        request.state,
        request.input,
        request.policy
    )
    return CjguiInternalRuntimeCycleResult(
        request,
        step,
        decision,
        step.didAdvance
    )
}

func cjguiInternalBuildRuntimeCommandDraft(
    cycle: CjguiInternalRuntimeCycleResult
): CjguiInternalRuntimeCommandDraft {
    return CjguiInternalRuntimeCommandDraft(
        cycle.didProduceProgress,
        cycle.step.isBlocked,
        cycle.didProduceProgress
    )
}

func cjguiInternalExecuteRuntimeCycleDraftCommand(
    request: CjguiInternalRuntimeCycleRequest
): CjguiInternalRuntimeCommandDraft {
    let cycle = cjguiInternalExecuteRuntimeCycle(request)
    return cjguiInternalBuildRuntimeCommandDraft(cycle)
}

// 内部 runtime command pipeline executor:
// - 它只串联一次 cycle executor 与 command draft builder。
// - didCompletePipeline 只表示 internal pipeline summary 已生成。
// - 它不改变 root state, 不循环, 不消费 queue, 不触发 callback,
//   不产生 renderer command。

func cjguiInternalExecuteRuntimeCommandPipeline(
    request: CjguiInternalRuntimeCommandPipelineRequest
): CjguiInternalRuntimeCommandPipelineResult {
    let cycle = cjguiInternalExecuteRuntimeCycle(request.cycleRequest)
    let draft = cjguiInternalBuildRuntimeCommandDraft(cycle)
    return CjguiInternalRuntimeCommandPipelineResult(
        request,
        cycle,
        draft,
        true
    )
}

func cjguiInternalExecuteDefaultRuntimeCommandPipeline(
): CjguiInternalRuntimeCommandPipelineResult {
    return cjguiInternalExecuteRuntimeCommandPipeline(
        cjguiInternalDefaultRuntimeCommandPipelineRequest()
    )
}

// 内部 runtime driver pass executor:
// - 它只组织一次 command pipeline pass 并投影 driver-level summary。
// - didCompleteDriverPass 来自 pipeline.didCompletePipeline。
// - 它不实现真实 runtime driver、app run、event loop、queue / drain、
//   platform callback 或 renderer command list。

func cjguiInternalExecuteRuntimeDriverPass(
    request: CjguiInternalRuntimeDriverRequest
): CjguiInternalRuntimeDriverResult {
    let pipeline = cjguiInternalExecuteRuntimeCommandPipeline(
        request.pipelineRequest
    )
    return CjguiInternalRuntimeDriverResult(
        request,
        pipeline,
        pipeline.didCompletePipeline,
        pipeline.draft.shouldRequestNextCycle,
        pipeline.draft.shouldReportBlocked,
        pipeline.draft.didObserveProgress
    )
}

func cjguiInternalExecuteDefaultRuntimeDriverPass(
): CjguiInternalRuntimeDriverResult {
    return cjguiInternalExecuteRuntimeDriverPass(
        cjguiInternalDefaultRuntimeDriverRequest()
    )
}

// 内部 runtime driver pass decision function:
// - 它只组合 root readiness、driver input 与 driver policy。
// - runtime-not-ready blocker 优先于 input blocker, 保持单一 fail-closed reason。
// - 它不执行 pipeline, 不实现 scheduling、queue / drain 或 platform runloop。

func cjguiInternalDecideRuntimeDriverPass(
    root: CjguiInternalRuntimeRootState,
    input: CjguiInternalRuntimeDriverInput,
    policy: CjguiInternalRuntimeDriverPolicy
): CjguiInternalRuntimeDriverDecision {
    if (policy.requiresRuntimeReady) {
        if (root.isRuntimeReady == false) {
            return CjguiInternalRuntimeDriverDecision(
                false,
                true,
                false
            )
        }
    }

    if (policy.requiresInputAllowsDriverPass) {
        if (input.allowsDriverPass == false) {
            return CjguiInternalRuntimeDriverDecision(
                false,
                false,
                true
            )
        }
    }

    return CjguiInternalRuntimeDriverDecision(
        true,
        false,
        false
    )
}

// 内部 runtime driver pass with input/policy:
// - 它先通过 driver decision gate 决定是否执行既有 pipeline pass。
// - allowed path 复用既有 cjguiInternalExecuteRuntimeDriverPass 行为。
// - blocked path 只构造 fail-closed summary, 不执行 pipeline pass。
// - 它不改变 root state, 不消费 queue, 不产生 platform callback。

func cjguiInternalExecuteRuntimeDriverPassWithInput(
    request: CjguiInternalRuntimeDriverRequest,
    input: CjguiInternalRuntimeDriverInput,
    policy: CjguiInternalRuntimeDriverPolicy
): CjguiInternalRuntimeDriverResult {
    let root = request.pipelineRequest.cycleRequest.state
    let decision = cjguiInternalDecideRuntimeDriverPass(
        root,
        input,
        policy
    )
    if (decision.shouldRunPipeline) {
        return cjguiInternalExecuteRuntimeDriverPass(request)
    }

    let cycleRequest = request.pipelineRequest.cycleRequest
    let step = CjguiInternalRuntimeStepResult(
        cycleRequest.state,
        false,
        true,
        decision.isBlockedByRuntimeNotReady,
        decision.isBlockedByInput
    )
    let stepDecision = CjguiInternalRuntimeStepDecision(
        false,
        decision.isBlockedByRuntimeNotReady,
        decision.isBlockedByInput
    )
    let cycle = CjguiInternalRuntimeCycleResult(
        cycleRequest,
        step,
        stepDecision,
        false
    )
    let draft = CjguiInternalRuntimeCommandDraft(
        false,
        true,
        false
    )
    let pipeline = CjguiInternalRuntimeCommandPipelineResult(
        request.pipelineRequest,
        cycle,
        draft,
        false
    )
    return CjguiInternalRuntimeDriverResult(
        request,
        pipeline,
        false,
        false,
        true,
        false
    )
}

// 内部 runtime driver report builder:
// - 它只从 driver result 投影 stable internal report fields。
// - isReadyForNextInternalPass 由 didCompleteDriverPass 与
//   shouldRequestNextCycle 派生。
// - 它不运行 pipeline, 不调度 event loop, 不消费 queue。

func cjguiInternalBuildRuntimeDriverReport(
    result: CjguiInternalRuntimeDriverResult
): CjguiInternalRuntimeDriverReport {
    if (result.didCompleteDriverPass) {
        if (result.shouldRequestNextCycle) {
            return CjguiInternalRuntimeDriverReport(
                result,
                result.didCompleteDriverPass,
                result.shouldRequestNextCycle,
                result.shouldReportBlocked,
                result.didObserveProgress,
                true
            )
        }
    }

    return CjguiInternalRuntimeDriverReport(
        result,
        result.didCompleteDriverPass,
        result.shouldRequestNextCycle,
        result.shouldReportBlocked,
        result.didObserveProgress,
        false
    )
}

func cjguiInternalExecuteRuntimeDriverPassReport(
    request: CjguiInternalRuntimeDriverRequest,
    input: CjguiInternalRuntimeDriverInput,
    policy: CjguiInternalRuntimeDriverPolicy
): CjguiInternalRuntimeDriverReport {
    let result = cjguiInternalExecuteRuntimeDriverPassWithInput(
        request,
        input,
        policy
    )
    return cjguiInternalBuildRuntimeDriverReport(result)
}

func cjguiInternalExecuteDefaultRuntimeDriverPassReport(
): CjguiInternalRuntimeDriverReport {
    return cjguiInternalExecuteRuntimeDriverPassReport(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
}

// 内部 runtime run intent builder:
// - 它只从 driver report 投影 run-boundary intent fields。
// - mayRequestRuntimeRun 等价于 report.isReadyForNextInternalPass。
// - 它不进入 run loop, 不调度 event loop, 不消费 queue。

func cjguiInternalBuildRuntimeRunIntent(
    report: CjguiInternalRuntimeDriverReport
): CjguiInternalRuntimeRunIntent {
    return CjguiInternalRuntimeRunIntent(
        report,
        report.isReadyForNextInternalPass,
        report.shouldRequestNextCycle,
        report.shouldReportBlocked,
        report.didObserveProgress
    )
}

func cjguiInternalExecuteRuntimeRunIntentDraft(
    request: CjguiInternalRuntimeDriverRequest,
    input: CjguiInternalRuntimeDriverInput,
    policy: CjguiInternalRuntimeDriverPolicy
): CjguiInternalRuntimeRunIntent {
    let report = cjguiInternalExecuteRuntimeDriverPassReport(
        request,
        input,
        policy
    )
    return cjguiInternalBuildRuntimeRunIntent(report)
}

func cjguiInternalExecuteDefaultRuntimeRunIntentDraft(
): CjguiInternalRuntimeRunIntent {
    return cjguiInternalExecuteRuntimeRunIntentDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
}

// 内部 runtime run request builder:
// - 它只把 run intent 包装为 request summary。
// - isRequestAllowed 等价于 intent.mayRequestRuntimeRun。
// - 它不实现 run(), 不启动 event loop, 不消费 queue。

func cjguiInternalBuildRuntimeRunRequest(
    intent: CjguiInternalRuntimeRunIntent
): CjguiInternalRuntimeRunRequest {
    return CjguiInternalRuntimeRunRequest(
        intent,
        intent.mayRequestRuntimeRun
    )
}

func cjguiInternalEvaluateRuntimeRunRequest(
    request: CjguiInternalRuntimeRunRequest
): CjguiInternalRuntimeRunRequestReport {
    if (request.isRequestAllowed) {
        return CjguiInternalRuntimeRunRequestReport(
            request,
            true,
            false,
            request.intent.shouldSurfaceBlockedReport,
            request.intent.didObserveInternalProgress
        )
    }

    return CjguiInternalRuntimeRunRequestReport(
        request,
        false,
        true,
        request.intent.shouldSurfaceBlockedReport,
        request.intent.didObserveInternalProgress
    )
}

func cjguiInternalExecuteRuntimeRunRequestDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    input: CjguiInternalRuntimeDriverInput,
    policy: CjguiInternalRuntimeDriverPolicy
): CjguiInternalRuntimeRunRequestReport {
    let intent = cjguiInternalExecuteRuntimeRunIntentDraft(
        driverRequest,
        input,
        policy
    )
    let request = cjguiInternalBuildRuntimeRunRequest(intent)
    return cjguiInternalEvaluateRuntimeRunRequest(request)
}

func cjguiInternalExecuteDefaultRuntimeRunRequestDraft(
): CjguiInternalRuntimeRunRequestReport {
    return cjguiInternalExecuteRuntimeRunRequestDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
}

func cjguiInternalDefaultRuntimeShutdownIntent(
): CjguiInternalRuntimeShutdownIntent {
    return CjguiInternalRuntimeShutdownIntent(false, false)
}

func cjguiInternalBuildRuntimeShutdownIntent(
    shouldRequestShutdown: Bool,
    shouldRequestCancellation: Bool
): CjguiInternalRuntimeShutdownIntent {
    return CjguiInternalRuntimeShutdownIntent(
        shouldRequestShutdown,
        shouldRequestCancellation
    )
}

func cjguiInternalBuildRuntimeShutdownRequest(
    intent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalRuntimeShutdownRequest {
    return CjguiInternalRuntimeShutdownRequest(
        intent,
        intent.shouldRequestShutdown,
        intent.shouldRequestCancellation
    )
}

func cjguiInternalEvaluateRuntimeShutdownRequest(
    request: CjguiInternalRuntimeShutdownRequest
): CjguiInternalRuntimeShutdownReport {
    if (request.isShutdownRequested) {
        return CjguiInternalRuntimeShutdownReport(
            request,
            true,
            true,
            request.isCancellationRequested
        )
    }

    if (request.isCancellationRequested) {
        return CjguiInternalRuntimeShutdownReport(
            request,
            true,
            false,
            true
        )
    }

    return CjguiInternalRuntimeShutdownReport(
        request,
        false,
        false,
        false
    )
}

func cjguiInternalBuildRunBoundaryRequest(
    runRequestReport: CjguiInternalRuntimeRunRequestReport,
    shutdownReport: CjguiInternalRuntimeShutdownReport
): CjguiInternalRunBoundaryRequest {
    return CjguiInternalRunBoundaryRequest(
        runRequestReport,
        shutdownReport
    )
}

// 内部 run boundary evaluator:
// - 它只聚合 run request report 与 shutdown report。
// - open path 要求 run request accepted 且 shutdown report 不要求 defer。
// - blocked / deferred 只是 internal summary, 不是真实 error system。

func cjguiInternalEvaluateRunBoundaryRequest(
    request: CjguiInternalRunBoundaryRequest
): CjguiInternalRunBoundaryReport {
    if (request.runRequestReport.didAcceptRequest) {
        if (request.shutdownReport.shouldDeferRunRequest == false) {
            return CjguiInternalRunBoundaryReport(
                request,
                true,
                false,
                false,
                false,
                false,
                false
            )
        }
    }

    if (request.runRequestReport.shouldDeferRequest) {
        return CjguiInternalRunBoundaryReport(
            request,
            false,
            true,
            true,
            true,
            request.shutdownReport.shouldEnterShutdownPath,
            request.shutdownReport.shouldEnterCancellationPath
        )
    }

    if (request.shutdownReport.shouldDeferRunRequest) {
        return CjguiInternalRunBoundaryReport(
            request,
            false,
            true,
            true,
            false,
            request.shutdownReport.shouldEnterShutdownPath,
            request.shutdownReport.shouldEnterCancellationPath
        )
    }

    return CjguiInternalRunBoundaryReport(
        request,
        false,
        false,
        true,
        false,
        request.shutdownReport.shouldEnterShutdownPath,
        request.shutdownReport.shouldEnterCancellationPath
    )
}

func cjguiInternalExecuteRunBoundaryDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalRunBoundaryReport {
    let runRequestReport = cjguiInternalExecuteRuntimeRunRequestDraft(
        driverRequest,
        driverInput,
        driverPolicy
    )
    let shutdownRequest = cjguiInternalBuildRuntimeShutdownRequest(
        shutdownIntent
    )
    let shutdownReport = cjguiInternalEvaluateRuntimeShutdownRequest(
        shutdownRequest
    )
    let request = cjguiInternalBuildRunBoundaryRequest(
        runRequestReport,
        shutdownReport
    )
    return cjguiInternalEvaluateRunBoundaryRequest(request)
}

func cjguiInternalExecuteDefaultRunBoundaryDraft(
): CjguiInternalRunBoundaryReport {
    return cjguiInternalExecuteRunBoundaryDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 app run surface state builder:
// - 它只消费 run boundary report, 不绕过 boundary 读取 lower-level facts。
// - 它不执行 run(), 不启动 event loop, 不消费 queue, 不调用平台。

func cjguiInternalBuildAppRunState(
    boundaryReport: CjguiInternalRunBoundaryReport
): CjguiInternalAppRunState {
    return CjguiInternalAppRunState(
        boundaryReport,
        boundaryReport.isBoundaryOpen,
        boundaryReport.isBoundaryDeferred,
        boundaryReport.isBoundaryBlocked
    )
}

func cjguiInternalBuildAppRunRequest(
    boundaryReport: CjguiInternalRunBoundaryReport
): CjguiInternalAppRunRequest {
    return CjguiInternalAppRunRequest(boundaryReport)
}

func cjguiInternalEvaluateAppRunRequest(
    request: CjguiInternalAppRunRequest
): CjguiInternalAppRunReport {
    let state = cjguiInternalBuildAppRunState(request.boundaryReport)
    return CjguiInternalAppRunReport(
        request,
        state,
        state.isAppRunAllowed,
        state.isAppRunDeferred,
        state.isAppRunBlocked
    )
}

func cjguiInternalExecuteAppRunSurfaceDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalAppRunReport {
    let boundaryReport = cjguiInternalExecuteRunBoundaryDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildAppRunRequest(boundaryReport)
    return cjguiInternalEvaluateAppRunRequest(request)
}

func cjguiInternalExecuteDefaultAppRunSurfaceDraft(
): CjguiInternalAppRunReport {
    return cjguiInternalExecuteAppRunSurfaceDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 app run controller draft:
// - 它只消费 AppRun report, 不越级读取 RunBoundaryReport 或 lower-level facts。
// - 它只派生 next-action summary, 不执行 action、不启动 loop、不调用平台。

func cjguiInternalBuildAppRunControllerRequest(
    appRunReport: CjguiInternalAppRunReport
): CjguiInternalAppRunControllerRequest {
    return CjguiInternalAppRunControllerRequest(appRunReport)
}

func cjguiInternalDecideAppRunController(
    request: CjguiInternalAppRunControllerRequest
): CjguiInternalAppRunControllerDecision {
    let appRunReport = request.appRunReport
    return CjguiInternalAppRunControllerDecision(
        appRunReport.didAcceptAppRun,
        appRunReport.shouldDeferAppRun,
        appRunReport.shouldReportAppRunBlocked,
        appRunReport.didAcceptAppRun
    )
}

func cjguiInternalEvaluateAppRunController(
    request: CjguiInternalAppRunControllerRequest
): CjguiInternalAppRunControllerReport {
    let decision = cjguiInternalDecideAppRunController(request)
    return CjguiInternalAppRunControllerReport(
        request,
        decision,
        true
    )
}

func cjguiInternalExecuteAppRunControllerDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalAppRunControllerReport {
    let appRunReport = cjguiInternalExecuteAppRunSurfaceDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildAppRunControllerRequest(appRunReport)
    return cjguiInternalEvaluateAppRunController(request)
}

func cjguiInternalExecuteDefaultAppRunControllerDraft(
): CjguiInternalAppRunControllerReport {
    return cjguiInternalExecuteAppRunControllerDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 app run execution plan draft:
// - 它只消费 AppRun controller report, 不越级读取 AppRunReport / RunBoundaryReport。
// - 它只构建 future execution plan summary, 不执行 plan、不启动 loop、不调用平台。

func cjguiInternalBuildAppRunExecutionPlanRequest(
    controllerReport: CjguiInternalAppRunControllerReport
): CjguiInternalAppRunExecutionPlanRequest {
    return CjguiInternalAppRunExecutionPlanRequest(controllerReport)
}

func cjguiInternalBuildAppRunExecutionPlan(
    request: CjguiInternalAppRunExecutionPlanRequest
): CjguiInternalAppRunExecutionPlan {
    let decision = request.controllerReport.decision
    return CjguiInternalAppRunExecutionPlan(
        decision.shouldEnterAcceptedPath,
        decision.shouldEnterAcceptedPath,
        decision.shouldEnterDeferredPath,
        decision.shouldEnterBlockedPath,
        decision.shouldRequestFutureRunBoundary
    )
}

func cjguiInternalEvaluateAppRunExecutionPlan(
    request: CjguiInternalAppRunExecutionPlanRequest
): CjguiInternalAppRunExecutionPlanReport {
    let plan = cjguiInternalBuildAppRunExecutionPlan(request)
    return CjguiInternalAppRunExecutionPlanReport(
        request,
        plan,
        true
    )
}

func cjguiInternalExecuteAppRunExecutionPlanDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalAppRunExecutionPlanReport {
    let controllerReport = cjguiInternalExecuteAppRunControllerDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildAppRunExecutionPlanRequest(
        controllerReport
    )
    return cjguiInternalEvaluateAppRunExecutionPlan(request)
}

func cjguiInternalExecuteDefaultAppRunExecutionPlanDraft(
): CjguiInternalAppRunExecutionPlanReport {
    return cjguiInternalExecuteAppRunExecutionPlanDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 app run dispatch draft:
// - 它只消费 AppRun execution plan report, 不越级读取 ControllerReport。
// - 它只构建 dispatch summary, 不执行 dispatch、不写 queue、不调用平台。

func cjguiInternalBuildAppRunDispatchRequest(
    planReport: CjguiInternalAppRunExecutionPlanReport
): CjguiInternalAppRunDispatchRequest {
    return CjguiInternalAppRunDispatchRequest(planReport)
}

func cjguiInternalBuildAppRunDispatchSummary(
    request: CjguiInternalAppRunDispatchRequest
): CjguiInternalAppRunDispatchSummary {
    let plan = request.planReport.plan
    return CjguiInternalAppRunDispatchSummary(
        plan.shouldPrepareRuntime,
        plan.shouldEnterRunLoopDraft,
        plan.shouldDeferExecution,
        plan.shouldReportBlockedExecution,
        plan.shouldRequestFutureBoundary
    )
}

func cjguiInternalEvaluateAppRunDispatch(
    request: CjguiInternalAppRunDispatchRequest
): CjguiInternalAppRunDispatchReport {
    let summary = cjguiInternalBuildAppRunDispatchSummary(request)
    return CjguiInternalAppRunDispatchReport(
        request,
        summary,
        true
    )
}

func cjguiInternalExecuteAppRunDispatchDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalAppRunDispatchReport {
    let planReport = cjguiInternalExecuteAppRunExecutionPlanDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildAppRunDispatchRequest(
        planReport
    )
    return cjguiInternalEvaluateAppRunDispatch(request)
}

func cjguiInternalExecuteDefaultAppRunDispatchDraft(
): CjguiInternalAppRunDispatchReport {
    return cjguiInternalExecuteAppRunDispatchDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 run loop draft:
// - 它只消费 AppRun dispatch report, 不越级读取 ExecutionPlanReport。
// - 它只构建 loop-intent summary, 不执行 loop、不写 queue、不调用平台。

func cjguiInternalBuildRunLoopDraftRequest(
    dispatchReport: CjguiInternalAppRunDispatchReport
): CjguiInternalRunLoopDraftRequest {
    return CjguiInternalRunLoopDraftRequest(dispatchReport)
}

func cjguiInternalBuildRunLoopDraftIntent(
    request: CjguiInternalRunLoopDraftRequest
): CjguiInternalRunLoopDraftIntent {
    let summary = request.dispatchReport.summary
    return CjguiInternalRunLoopDraftIntent(
        summary.shouldDispatchRunLoopDraft,
        summary.shouldDispatchDeferredNotice,
        summary.shouldDispatchBlockedNotice,
        summary.shouldDispatchFutureBoundaryRequest
    )
}

func cjguiInternalEvaluateRunLoopDraft(
    request: CjguiInternalRunLoopDraftRequest
): CjguiInternalRunLoopDraftReport {
    let intent = cjguiInternalBuildRunLoopDraftIntent(request)
    return CjguiInternalRunLoopDraftReport(
        request,
        intent,
        true
    )
}

func cjguiInternalExecuteRunLoopDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalRunLoopDraftReport {
    let dispatchReport = cjguiInternalExecuteAppRunDispatchDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildRunLoopDraftRequest(
        dispatchReport
    )
    return cjguiInternalEvaluateRunLoopDraft(request)
}

func cjguiInternalExecuteDefaultRunLoopDraft(
): CjguiInternalRunLoopDraftReport {
    return cjguiInternalExecuteRunLoopDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 single loop iteration draft:
// - 它只消费 RunLoopDraft report, 不越级读取 AppRun dispatch report。
// - 它只构建 single-iteration intent summary, 不执行 loop、iteration、
//   scheduling、queue 或 platform callback。

func cjguiInternalBuildLoopIterationDraftRequest(
    loopDraftReport: CjguiInternalRunLoopDraftReport
): CjguiInternalLoopIterationDraftRequest {
    return CjguiInternalLoopIterationDraftRequest(loopDraftReport)
}

func cjguiInternalBuildLoopIterationDraftIntent(
    request: CjguiInternalLoopIterationDraftRequest
): CjguiInternalLoopIterationDraftIntent {
    let intent = request.loopDraftReport.intent
    return CjguiInternalLoopIterationDraftIntent(
        intent.shouldEnterLoopDraft,
        intent.shouldDeferLoopDraft,
        intent.shouldReportLoopBlocked,
        intent.shouldRequestFutureBoundary
    )
}

func cjguiInternalEvaluateLoopIterationDraft(
    request: CjguiInternalLoopIterationDraftRequest
): CjguiInternalLoopIterationDraftReport {
    let intent = cjguiInternalBuildLoopIterationDraftIntent(request)
    return CjguiInternalLoopIterationDraftReport(
        request,
        intent,
        true
    )
}

func cjguiInternalExecuteLoopIterationDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalLoopIterationDraftReport {
    let loopDraftReport = cjguiInternalExecuteRunLoopDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildLoopIterationDraftRequest(
        loopDraftReport
    )
    return cjguiInternalEvaluateLoopIterationDraft(request)
}

func cjguiInternalExecuteDefaultLoopIterationDraft(
): CjguiInternalLoopIterationDraftReport {
    return cjguiInternalExecuteLoopIterationDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 iteration work packet draft:
// - 它只消费 LoopIterationDraft report, 不越级读取 RunLoopDraft report。
// - 它只构建 work-category summary, 不执行 work、input processing、
//   layout、render、queue 或 platform callback。

func cjguiInternalBuildIterationWorkPacketDraftRequest(
    iterationReport: CjguiInternalLoopIterationDraftReport
): CjguiInternalIterationWorkPacketDraftRequest {
    return CjguiInternalIterationWorkPacketDraftRequest(iterationReport)
}

func cjguiInternalBuildIterationWorkPacketDraft(
    request: CjguiInternalIterationWorkPacketDraftRequest
): CjguiInternalIterationWorkPacketDraft {
    let intent = request.iterationReport.intent
    return CjguiInternalIterationWorkPacketDraft(
        intent.shouldAttemptIteration,
        intent.shouldAttemptIteration,
        intent.shouldRequestFutureBoundary,
        intent.shouldDeferIteration,
        intent.shouldReportIterationBlocked
    )
}

func cjguiInternalEvaluateIterationWorkPacketDraft(
    request: CjguiInternalIterationWorkPacketDraftRequest
): CjguiInternalIterationWorkPacketDraftReport {
    let packet = cjguiInternalBuildIterationWorkPacketDraft(request)
    return CjguiInternalIterationWorkPacketDraftReport(
        request,
        packet,
        true
    )
}

func cjguiInternalExecuteIterationWorkPacketDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalIterationWorkPacketDraftReport {
    let iterationReport = cjguiInternalExecuteLoopIterationDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildIterationWorkPacketDraftRequest(
        iterationReport
    )
    return cjguiInternalEvaluateIterationWorkPacketDraft(request)
}

func cjguiInternalExecuteDefaultIterationWorkPacketDraft(
): CjguiInternalIterationWorkPacketDraftReport {
    return cjguiInternalExecuteIterationWorkPacketDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 lifecycle work draft:
// - 它只消费 IterationWorkPacketDraft report, 不越级读取 LoopIterationDraft report。
// - 它只构建 lifecycle-work summary, 不执行 app/window lifecycle、
//   state mutation、queue 或 platform callback。

func cjguiInternalBuildLifecycleWorkDraftRequest(
    workPacketReport: CjguiInternalIterationWorkPacketDraftReport
): CjguiInternalLifecycleWorkDraftRequest {
    return CjguiInternalLifecycleWorkDraftRequest(workPacketReport)
}

func cjguiInternalBuildLifecycleWorkDraft(
    request: CjguiInternalLifecycleWorkDraftRequest
): CjguiInternalLifecycleWorkDraft {
    let packet = request.workPacketReport.packet
    return CjguiInternalLifecycleWorkDraft(
        packet.shouldProcessLifecycleWork,
        packet.shouldDeferWork,
        packet.shouldReportBlockedWork,
        packet.shouldPrepareFutureBoundaryWork
    )
}

func cjguiInternalEvaluateLifecycleWorkDraft(
    request: CjguiInternalLifecycleWorkDraftRequest
): CjguiInternalLifecycleWorkDraftReport {
    let draft = cjguiInternalBuildLifecycleWorkDraft(request)
    return CjguiInternalLifecycleWorkDraftReport(
        request,
        draft,
        true
    )
}

func cjguiInternalExecuteLifecycleWorkDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalLifecycleWorkDraftReport {
    let workPacketReport = cjguiInternalExecuteIterationWorkPacketDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildLifecycleWorkDraftRequest(
        workPacketReport
    )
    return cjguiInternalEvaluateLifecycleWorkDraft(request)
}

func cjguiInternalExecuteDefaultLifecycleWorkDraft(
): CjguiInternalLifecycleWorkDraftReport {
    return cjguiInternalExecuteLifecycleWorkDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 lifecycle owner handoff routing summary:
// - 它只消费 LifecycleWorkDraft report, 不越级读取 work packet 或 lower-level facts。
// - app/window owner-specific facts 由各自 lifecycle owner module 构建。
// - runtime_state.cj 只负责 cross-owner routing, 不执行 lifecycle mutation。

func cjguiInternalBuildLifecycleOwnerHandoffRequest(
    lifecycleWorkReport: CjguiInternalLifecycleWorkDraftReport
): CjguiInternalLifecycleOwnerHandoffRequest {
    return CjguiInternalLifecycleOwnerHandoffRequest(lifecycleWorkReport)
}

func cjguiInternalEvaluateLifecycleOwnerHandoff(
    request: CjguiInternalLifecycleOwnerHandoffRequest
): CjguiInternalLifecycleOwnerHandoffReport {
    let draft = request.lifecycleWorkReport.draft
    let appDraft = cjguiInternalBuildAppLifecycleWorkHandoffDraft(
        draft.shouldProcessLifecycleWork,
        draft.shouldDeferLifecycleWork,
        draft.shouldReportLifecycleBlocked
    )
    let windowDraft = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        draft.shouldProcessLifecycleWork,
        draft.shouldDeferLifecycleWork,
        draft.shouldReportLifecycleBlocked
    )
    return CjguiInternalLifecycleOwnerHandoffReport(
        request,
        appDraft,
        windowDraft,
        true
    )
}

func cjguiInternalExecuteLifecycleOwnerHandoffDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalLifecycleOwnerHandoffReport {
    let lifecycleWorkReport = cjguiInternalExecuteLifecycleWorkDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildLifecycleOwnerHandoffRequest(
        lifecycleWorkReport
    )
    return cjguiInternalEvaluateLifecycleOwnerHandoff(request)
}

func cjguiInternalExecuteDefaultLifecycleOwnerHandoffDraft(
): CjguiInternalLifecycleOwnerHandoffReport {
    return cjguiInternalExecuteLifecycleOwnerHandoffDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 lifecycle mutation readiness cross-owner summary:
// - 它只消费 OwnerHandoffReport, 不越级读取 LifecycleWorkDraft 或 lower-level facts。
// - app/window mutation readiness facts 由各自 lifecycle owner module 构建。
// - runtime_state.cj 只负责 cross-owner summary, 不执行 lifecycle mutation。

func cjguiInternalBuildLifecycleMutationReadinessRequest(
    ownerHandoffReport: CjguiInternalLifecycleOwnerHandoffReport
): CjguiInternalLifecycleMutationReadinessRequest {
    return CjguiInternalLifecycleMutationReadinessRequest(ownerHandoffReport)
}

func cjguiInternalEvaluateLifecycleMutationReadiness(
    request: CjguiInternalLifecycleMutationReadinessRequest
): CjguiInternalLifecycleMutationReadinessReport {
    let appReadiness = cjguiInternalBuildAppLifecycleMutationReadinessDraft(
        request.ownerHandoffReport.appDraft
    )
    let windowReadiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        request.ownerHandoffReport.windowDraft
    )
    return CjguiInternalLifecycleMutationReadinessReport(
        request,
        appReadiness,
        windowReadiness,
        appReadiness.canMutateAppLifecycle && windowReadiness.canMutateWindowLifecycle,
        appReadiness.shouldDeferAppLifecycleMutation || windowReadiness.shouldDeferWindowLifecycleMutation,
        appReadiness.shouldReportAppLifecycleMutationBlocked || windowReadiness.shouldReportWindowLifecycleMutationBlocked,
        true
    )
}

func cjguiInternalExecuteLifecycleMutationReadinessDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalLifecycleMutationReadinessReport {
    let ownerHandoffReport = cjguiInternalExecuteLifecycleOwnerHandoffDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildLifecycleMutationReadinessRequest(
        ownerHandoffReport
    )
    return cjguiInternalEvaluateLifecycleMutationReadiness(request)
}

func cjguiInternalExecuteDefaultLifecycleMutationReadinessDraft(
): CjguiInternalLifecycleMutationReadinessReport {
    return cjguiInternalExecuteLifecycleMutationReadinessDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 lifecycle mutation plan cross-owner summary:
// - 它只消费 MutationReadinessReport, 不越级读取 OwnerHandoffReport 或 lower-level facts。
// - app/window mutation plan facts 由各自 lifecycle owner module 构建。
// - runtime_state.cj 只负责 cross-owner summary, 不执行 lifecycle mutation。

func cjguiInternalBuildLifecycleMutationPlanRequest(
    readinessReport: CjguiInternalLifecycleMutationReadinessReport
): CjguiInternalLifecycleMutationPlanRequest {
    return CjguiInternalLifecycleMutationPlanRequest(readinessReport)
}

func cjguiInternalEvaluateLifecycleMutationPlan(
    request: CjguiInternalLifecycleMutationPlanRequest
): CjguiInternalLifecycleMutationPlanReport {
    let appPlan = cjguiInternalBuildAppLifecycleMutationPlanDraft(
        request.readinessReport.appReadiness
    )
    let windowPlan = cjguiInternalBuildWindowLifecycleMutationPlanDraft(
        request.readinessReport.windowReadiness
    )
    return CjguiInternalLifecycleMutationPlanReport(
        request,
        appPlan,
        windowPlan,
        appPlan.shouldPlanAppLifecycleMutation && windowPlan.shouldPlanWindowLifecycleMutation,
        appPlan.shouldDeferAppLifecycleMutationPlan || windowPlan.shouldDeferWindowLifecycleMutationPlan,
        appPlan.shouldReportAppLifecycleMutationPlanBlocked || windowPlan.shouldReportWindowLifecycleMutationPlanBlocked,
        true
    )
}

func cjguiInternalExecuteLifecycleMutationPlanDraft(
    driverRequest: CjguiInternalRuntimeDriverRequest,
    driverInput: CjguiInternalRuntimeDriverInput,
    driverPolicy: CjguiInternalRuntimeDriverPolicy,
    shutdownIntent: CjguiInternalRuntimeShutdownIntent
): CjguiInternalLifecycleMutationPlanReport {
    let readinessReport = cjguiInternalExecuteLifecycleMutationReadinessDraft(
        driverRequest,
        driverInput,
        driverPolicy,
        shutdownIntent
    )
    let request = cjguiInternalBuildLifecycleMutationPlanRequest(
        readinessReport
    )
    return cjguiInternalEvaluateLifecycleMutationPlan(request)
}

func cjguiInternalExecuteDefaultLifecycleMutationPlanDraft(
): CjguiInternalLifecycleMutationPlanReport {
    return cjguiInternalExecuteLifecycleMutationPlanDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
}

// 内部 runtime step ready sanity helper:
// - 这是普通顶层函数, 使用默认 internal 可见性。
// - 它只复用既有 root state builder 与 first internal runtime step。
// - 它返回 step didAdvance Bool, 不新增 runtime behavior。
// - 它不改变 step behavior、root state shape、bootstrap builder behavior、
//   projection、coordination、constructor shape、public runtime API 或 public C ABI。

func cjguiInternalRuntimeStepReadySanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let step = cjguiInternalRuntimeStep(root)
    return step.didAdvance
}

func cjguiInternalRuntimeStepInputPolicyReadySanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let step = cjguiInternalRuntimeStepWithInput(
        root,
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    return step.didAdvance
}

func cjguiInternalRuntimeStepInputPolicyNotReadyBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let notReadyRoot = CjguiInternalRuntimeRootState(
        root.bootstrap,
        false
    )
    let decision = cjguiInternalDecideRuntimeStep(
        notReadyRoot,
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    if (decision.shouldAdvance) {
        return false
    }
    if (decision.isBlockedByInput) {
        return false
    }
    return decision.isBlockedByRuntimeNotReady
}

func cjguiInternalRuntimeStepInputPolicyInputBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let decision = cjguiInternalDecideRuntimeStep(
        root,
        CjguiInternalRuntimeStepInput(false, false),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    if (decision.shouldAdvance) {
        return false
    }
    if (decision.isBlockedByRuntimeNotReady) {
        return false
    }
    return decision.isBlockedByInput
}

func cjguiInternalRuntimeStepReadyOutcomeSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let step = cjguiInternalRuntimeStep(root)
    if (step.didAdvance == false) {
        return false
    }
    if (step.isBlocked) {
        return false
    }
    if (step.isBlockedByRuntimeNotReady) {
        return false
    }
    return step.isBlockedByInput == false
}

func cjguiInternalRuntimeStepBlockedOutcomeSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let notReadyRoot = CjguiInternalRuntimeRootState(
        root.bootstrap,
        false
    )
    let simpleBlocked = cjguiInternalRuntimeStep(notReadyRoot)
    if (simpleBlocked.didAdvance) {
        return false
    }
    if (simpleBlocked.isBlocked == false) {
        return false
    }
    if (simpleBlocked.isBlockedByRuntimeNotReady == false) {
        return false
    }
    if (simpleBlocked.isBlockedByInput) {
        return false
    }

    let inputBlocked = cjguiInternalRuntimeStepWithInput(
        root,
        CjguiInternalRuntimeStepInput(false, false),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    if (inputBlocked.didAdvance) {
        return false
    }
    if (inputBlocked.isBlocked == false) {
        return false
    }
    if (inputBlocked.isBlockedByRuntimeNotReady) {
        return false
    }
    return inputBlocked.isBlockedByInput
}

func cjguiInternalRuntimeCycleReadySanity(): Bool {
    let result = cjguiInternalExecuteRuntimeCycle(
        cjguiInternalDefaultRuntimeCycleRequest()
    )
    if (result.decision.shouldAdvance == false) {
        return false
    }
    if (result.step.didAdvance == false) {
        return false
    }
    if (result.didProduceProgress == false) {
        return false
    }
    if (result.step.isBlocked) {
        return false
    }
    if (result.decision.isBlockedByRuntimeNotReady) {
        return false
    }
    if (result.decision.isBlockedByInput) {
        return false
    }
    if (result.step.isBlockedByRuntimeNotReady) {
        return false
    }
    return result.step.isBlockedByInput == false
}

func cjguiInternalRuntimeCycleNotReadyBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let request = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let result = cjguiInternalExecuteRuntimeCycle(request)
    if (result.decision.shouldAdvance) {
        return false
    }
    if (result.step.didAdvance) {
        return false
    }
    if (result.didProduceProgress) {
        return false
    }
    if (result.step.isBlocked == false) {
        return false
    }
    if (result.decision.isBlockedByRuntimeNotReady == false) {
        return false
    }
    if (result.step.isBlockedByRuntimeNotReady == false) {
        return false
    }
    if (result.decision.isBlockedByInput) {
        return false
    }
    return result.step.isBlockedByInput == false
}

func cjguiInternalRuntimeCycleInputBlockedSanity(): Bool {
    let request = CjguiInternalRuntimeCycleRequest(
        cjguiInternalBuildRuntimeRootState(),
        CjguiInternalRuntimeStepInput(false, false),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let result = cjguiInternalExecuteRuntimeCycle(request)
    if (result.decision.shouldAdvance) {
        return false
    }
    if (result.step.didAdvance) {
        return false
    }
    if (result.didProduceProgress) {
        return false
    }
    if (result.step.isBlocked == false) {
        return false
    }
    if (result.decision.isBlockedByRuntimeNotReady) {
        return false
    }
    if (result.step.isBlockedByRuntimeNotReady) {
        return false
    }
    if (result.decision.isBlockedByInput == false) {
        return false
    }
    return result.step.isBlockedByInput
}

func cjguiInternalRuntimeCycleProgressReadySanity(): Bool {
    let result = cjguiInternalExecuteRuntimeCycle(
        cjguiInternalDefaultRuntimeCycleRequest()
    )
    if (result.decision.shouldAdvance == false) {
        return false
    }
    if (result.step.didAdvance == false) {
        return false
    }
    if (result.didProduceProgress == false) {
        return false
    }
    return result.step.isBlocked == false
}

func cjguiInternalRuntimeCycleProgressBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let notReadyRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let notReadyResult = cjguiInternalExecuteRuntimeCycle(notReadyRequest)
    if (notReadyResult.didProduceProgress) {
        return false
    }
    if (notReadyResult.step.didAdvance) {
        return false
    }
    if (notReadyResult.step.isBlocked == false) {
        return false
    }

    let inputBlockedRequest = CjguiInternalRuntimeCycleRequest(
        root,
        CjguiInternalRuntimeStepInput(false, false),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let inputBlockedResult = cjguiInternalExecuteRuntimeCycle(
        inputBlockedRequest
    )
    if (inputBlockedResult.didProduceProgress) {
        return false
    }
    if (inputBlockedResult.step.didAdvance) {
        return false
    }
    return inputBlockedResult.step.isBlocked
}

func cjguiInternalRuntimeCommandDraftReadySanity(): Bool {
    let draft = cjguiInternalExecuteRuntimeCycleDraftCommand(
        cjguiInternalDefaultRuntimeCycleRequest()
    )
    if (draft.didObserveProgress == false) {
        return false
    }
    if (draft.shouldRequestNextCycle == false) {
        return false
    }
    return draft.shouldReportBlocked == false
}

func cjguiInternalRuntimeCommandDraftNotReadyBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let request = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let draft = cjguiInternalExecuteRuntimeCycleDraftCommand(request)
    if (draft.didObserveProgress) {
        return false
    }
    if (draft.shouldRequestNextCycle) {
        return false
    }
    return draft.shouldReportBlocked
}

func cjguiInternalRuntimeCommandDraftInputBlockedSanity(): Bool {
    let request = CjguiInternalRuntimeCycleRequest(
        cjguiInternalBuildRuntimeRootState(),
        CjguiInternalRuntimeStepInput(false, false),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let draft = cjguiInternalExecuteRuntimeCycleDraftCommand(request)
    if (draft.didObserveProgress) {
        return false
    }
    if (draft.shouldRequestNextCycle) {
        return false
    }
    return draft.shouldReportBlocked
}

func cjguiInternalRuntimeCommandPipelineReadySanity(): Bool {
    let result = cjguiInternalExecuteDefaultRuntimeCommandPipeline()
    if (result.didCompletePipeline == false) {
        return false
    }
    if (result.cycle.decision.shouldAdvance == false) {
        return false
    }
    if (result.cycle.didProduceProgress == false) {
        return false
    }
    if (result.draft.didObserveProgress == false) {
        return false
    }
    if (result.draft.shouldRequestNextCycle == false) {
        return false
    }
    return result.draft.shouldReportBlocked == false
}

func cjguiInternalRuntimeCommandPipelineNotReadyBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let result = cjguiInternalExecuteRuntimeCommandPipeline(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    if (result.didCompletePipeline == false) {
        return false
    }
    if (result.cycle.step.isBlocked == false) {
        return false
    }
    if (result.cycle.didProduceProgress) {
        return false
    }
    if (result.draft.didObserveProgress) {
        return false
    }
    if (result.draft.shouldRequestNextCycle) {
        return false
    }
    return result.draft.shouldReportBlocked
}

func cjguiInternalRuntimeCommandPipelineInputBlockedSanity(): Bool {
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        cjguiInternalBuildRuntimeRootState(),
        CjguiInternalRuntimeStepInput(false, false),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let result = cjguiInternalExecuteRuntimeCommandPipeline(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    if (result.didCompletePipeline == false) {
        return false
    }
    if (result.cycle.step.isBlocked == false) {
        return false
    }
    if (result.cycle.didProduceProgress) {
        return false
    }
    if (result.draft.didObserveProgress) {
        return false
    }
    if (result.draft.shouldRequestNextCycle) {
        return false
    }
    return result.draft.shouldReportBlocked
}

func cjguiInternalRuntimeDriverReadySanity(): Bool {
    let result = cjguiInternalExecuteDefaultRuntimeDriverPass()
    if (result.didCompleteDriverPass == false) {
        return false
    }
    if (result.pipeline.didCompletePipeline == false) {
        return false
    }
    if (result.pipeline.cycle.decision.shouldAdvance == false) {
        return false
    }
    if (result.pipeline.cycle.didProduceProgress == false) {
        return false
    }
    if (result.didObserveProgress == false) {
        return false
    }
    if (result.shouldRequestNextCycle == false) {
        return false
    }
    return result.shouldReportBlocked == false
}

func cjguiInternalRuntimeDriverNotReadyBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let request = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let result = cjguiInternalExecuteRuntimeDriverPass(request)
    if (result.didCompleteDriverPass == false) {
        return false
    }
    if (result.pipeline.cycle.step.isBlocked == false) {
        return false
    }
    if (result.pipeline.cycle.didProduceProgress) {
        return false
    }
    if (result.didObserveProgress) {
        return false
    }
    if (result.shouldRequestNextCycle) {
        return false
    }
    return result.shouldReportBlocked
}

func cjguiInternalRuntimeDriverInputBlockedSanity(): Bool {
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        cjguiInternalBuildRuntimeRootState(),
        CjguiInternalRuntimeStepInput(false, false),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let request = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let result = cjguiInternalExecuteRuntimeDriverPass(request)
    if (result.didCompleteDriverPass == false) {
        return false
    }
    if (result.pipeline.cycle.step.isBlocked == false) {
        return false
    }
    if (result.pipeline.cycle.didProduceProgress) {
        return false
    }
    if (result.didObserveProgress) {
        return false
    }
    if (result.shouldRequestNextCycle) {
        return false
    }
    return result.shouldReportBlocked
}

func cjguiInternalRuntimeDriverInputPolicyReadySanity(): Bool {
    let result = cjguiInternalExecuteRuntimeDriverPassWithInput(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (result.didCompleteDriverPass == false) {
        return false
    }
    if (result.pipeline.didCompletePipeline == false) {
        return false
    }
    if (result.pipeline.cycle.decision.shouldAdvance == false) {
        return false
    }
    if (result.didObserveProgress == false) {
        return false
    }
    if (result.shouldRequestNextCycle == false) {
        return false
    }
    return result.shouldReportBlocked == false
}

func cjguiInternalRuntimeDriverInputPolicyRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let request = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let decision = cjguiInternalDecideRuntimeDriverPass(
        cycleRequest.state,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (decision.shouldRunPipeline) {
        return false
    }
    if (decision.isBlockedByInput) {
        return false
    }
    if (decision.isBlockedByRuntimeNotReady == false) {
        return false
    }

    let result = cjguiInternalExecuteRuntimeDriverPassWithInput(
        request,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (result.didCompleteDriverPass) {
        return false
    }
    if (result.pipeline.didCompletePipeline) {
        return false
    }
    if (result.pipeline.cycle.step.isBlocked == false) {
        return false
    }
    if (result.pipeline.cycle.decision.isBlockedByRuntimeNotReady == false) {
        return false
    }
    if (result.didObserveProgress) {
        return false
    }
    if (result.shouldRequestNextCycle) {
        return false
    }
    return result.shouldReportBlocked
}

func cjguiInternalRuntimeDriverInputPolicyInputBlockedSanity(): Bool {
    let blockedInput = CjguiInternalRuntimeDriverInput(
        false,
        false
    )
    let request = cjguiInternalDefaultRuntimeDriverRequest()
    let decision = cjguiInternalDecideRuntimeDriverPass(
        request.pipelineRequest.cycleRequest.state,
        blockedInput,
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (decision.shouldRunPipeline) {
        return false
    }
    if (decision.isBlockedByRuntimeNotReady) {
        return false
    }
    if (decision.isBlockedByInput == false) {
        return false
    }

    let result = cjguiInternalExecuteRuntimeDriverPassWithInput(
        request,
        blockedInput,
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (result.didCompleteDriverPass) {
        return false
    }
    if (result.pipeline.didCompletePipeline) {
        return false
    }
    if (result.pipeline.cycle.step.isBlocked == false) {
        return false
    }
    if (result.pipeline.cycle.decision.isBlockedByInput == false) {
        return false
    }
    if (result.didObserveProgress) {
        return false
    }
    if (result.shouldRequestNextCycle) {
        return false
    }
    return result.shouldReportBlocked
}

func cjguiInternalRuntimeDriverReportReadySanity(): Bool {
    let report = cjguiInternalExecuteDefaultRuntimeDriverPassReport()
    if (report.didCompleteDriverPass == false) {
        return false
    }
    if (report.shouldRequestNextCycle == false) {
        return false
    }
    if (report.shouldReportBlocked) {
        return false
    }
    if (report.didObserveProgress == false) {
        return false
    }
    return report.isReadyForNextInternalPass
}

func cjguiInternalRuntimeDriverReportRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let request = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteRuntimeDriverPassReport(
        request,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (report.didCompleteDriverPass) {
        return false
    }
    if (report.shouldRequestNextCycle) {
        return false
    }
    if (report.shouldReportBlocked == false) {
        return false
    }
    if (report.didObserveProgress) {
        return false
    }
    return report.isReadyForNextInternalPass == false
}

func cjguiInternalRuntimeDriverReportInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteRuntimeDriverPassReport(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (report.didCompleteDriverPass) {
        return false
    }
    if (report.shouldRequestNextCycle) {
        return false
    }
    if (report.shouldReportBlocked == false) {
        return false
    }
    if (report.didObserveProgress) {
        return false
    }
    return report.isReadyForNextInternalPass == false
}

func cjguiInternalRuntimeRunIntentReadySanity(): Bool {
    let intent = cjguiInternalExecuteDefaultRuntimeRunIntentDraft()
    if (intent.mayRequestRuntimeRun == false) {
        return false
    }
    if (intent.shouldContinueInternalCycles == false) {
        return false
    }
    if (intent.shouldSurfaceBlockedReport) {
        return false
    }
    return intent.didObserveInternalProgress
}

func cjguiInternalRuntimeRunIntentRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let request = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let intent = cjguiInternalExecuteRuntimeRunIntentDraft(
        request,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (intent.mayRequestRuntimeRun) {
        return false
    }
    if (intent.shouldContinueInternalCycles) {
        return false
    }
    if (intent.shouldSurfaceBlockedReport == false) {
        return false
    }
    return intent.didObserveInternalProgress == false
}

func cjguiInternalRuntimeRunIntentInputBlockedSanity(): Bool {
    let intent = cjguiInternalExecuteRuntimeRunIntentDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (intent.mayRequestRuntimeRun) {
        return false
    }
    if (intent.shouldContinueInternalCycles) {
        return false
    }
    if (intent.shouldSurfaceBlockedReport == false) {
        return false
    }
    return intent.didObserveInternalProgress == false
}

func cjguiInternalRuntimeRunRequestReadySanity(): Bool {
    let report = cjguiInternalExecuteDefaultRuntimeRunRequestDraft()
    if (report.didAcceptRequest == false) {
        return false
    }
    if (report.shouldDeferRequest) {
        return false
    }
    if (report.shouldSurfaceBlockedReport) {
        return false
    }
    return report.didObserveInternalProgress
}

func cjguiInternalRuntimeRunRequestRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let request = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteRuntimeRunRequestDraft(
        request,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (report.didAcceptRequest) {
        return false
    }
    if (report.shouldDeferRequest == false) {
        return false
    }
    if (report.shouldSurfaceBlockedReport == false) {
        return false
    }
    return report.didObserveInternalProgress == false
}

func cjguiInternalRuntimeRunRequestInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteRuntimeRunRequestDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy()
    )
    if (report.didAcceptRequest) {
        return false
    }
    if (report.shouldDeferRequest == false) {
        return false
    }
    if (report.shouldSurfaceBlockedReport == false) {
        return false
    }
    return report.didObserveInternalProgress == false
}

func cjguiInternalRuntimeShutdownIdleSanity(): Bool {
    let intent = cjguiInternalDefaultRuntimeShutdownIntent()
    let request = cjguiInternalBuildRuntimeShutdownRequest(intent)
    let report = cjguiInternalEvaluateRuntimeShutdownRequest(request)
    if (report.shouldDeferRunRequest) {
        return false
    }
    if (report.shouldEnterShutdownPath) {
        return false
    }
    return report.shouldEnterCancellationPath == false
}

func cjguiInternalRuntimeShutdownRequestedSanity(): Bool {
    let intent = cjguiInternalBuildRuntimeShutdownIntent(true, false)
    let request = cjguiInternalBuildRuntimeShutdownRequest(intent)
    let report = cjguiInternalEvaluateRuntimeShutdownRequest(request)
    if (report.shouldDeferRunRequest == false) {
        return false
    }
    if (report.shouldEnterShutdownPath == false) {
        return false
    }
    return report.shouldEnterCancellationPath == false
}

func cjguiInternalRuntimeCancellationRequestedSanity(): Bool {
    let intent = cjguiInternalBuildRuntimeShutdownIntent(false, true)
    let request = cjguiInternalBuildRuntimeShutdownRequest(intent)
    let report = cjguiInternalEvaluateRuntimeShutdownRequest(request)
    if (report.shouldDeferRunRequest == false) {
        return false
    }
    if (report.shouldEnterShutdownPath) {
        return false
    }
    return report.shouldEnterCancellationPath
}

func cjguiInternalRuntimeShutdownAndCancellationRequestedSanity(): Bool {
    let intent = cjguiInternalBuildRuntimeShutdownIntent(true, true)
    let request = cjguiInternalBuildRuntimeShutdownRequest(intent)
    let report = cjguiInternalEvaluateRuntimeShutdownRequest(request)
    if (report.shouldDeferRunRequest == false) {
        return false
    }
    if (report.shouldEnterShutdownPath == false) {
        return false
    }
    return report.shouldEnterCancellationPath
}

func cjguiInternalRunBoundaryOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultRunBoundaryDraft()
    if (report.isBoundaryOpen == false) {
        return false
    }
    if (report.isBoundaryDeferred) {
        return false
    }
    return report.isBoundaryBlocked == false
}

func cjguiInternalRunBoundaryRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteRunBoundaryDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.isBoundaryOpen) {
        return false
    }
    if (report.isBoundaryDeferred == false) {
        return false
    }
    if (report.isBoundaryBlocked == false) {
        return false
    }
    if (report.isBlockedByShutdown) {
        return false
    }
    if (report.isBlockedByCancellation) {
        return false
    }
    return report.isBlockedByRunRequest
}

func cjguiInternalRunBoundaryInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteRunBoundaryDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.isBoundaryOpen) {
        return false
    }
    if (report.isBoundaryDeferred == false) {
        return false
    }
    if (report.isBoundaryBlocked == false) {
        return false
    }
    if (report.isBlockedByShutdown) {
        return false
    }
    if (report.isBlockedByCancellation) {
        return false
    }
    return report.isBlockedByRunRequest
}

func cjguiInternalRunBoundaryShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteRunBoundaryDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.isBoundaryOpen) {
        return false
    }
    if (report.isBoundaryDeferred == false) {
        return false
    }
    if (report.isBoundaryBlocked == false) {
        return false
    }
    if (report.isBlockedByRunRequest) {
        return false
    }
    if (report.isBlockedByCancellation) {
        return false
    }
    return report.isBlockedByShutdown
}

func cjguiInternalRunBoundaryCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteRunBoundaryDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.isBoundaryOpen) {
        return false
    }
    if (report.isBoundaryDeferred == false) {
        return false
    }
    if (report.isBoundaryBlocked == false) {
        return false
    }
    if (report.isBlockedByRunRequest) {
        return false
    }
    if (report.isBlockedByShutdown) {
        return false
    }
    return report.isBlockedByCancellation
}

func cjguiInternalAppRunSurfaceOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultAppRunSurfaceDraft()
    if (report.didAcceptAppRun == false) {
        return false
    }
    if (report.shouldDeferAppRun) {
        return false
    }
    return report.shouldReportAppRunBlocked == false
}

func cjguiInternalAppRunSurfaceRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteAppRunSurfaceDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didAcceptAppRun) {
        return false
    }
    if (report.shouldDeferAppRun == false) {
        return false
    }
    return report.shouldReportAppRunBlocked
}

func cjguiInternalAppRunSurfaceInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunSurfaceDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didAcceptAppRun) {
        return false
    }
    if (report.shouldDeferAppRun == false) {
        return false
    }
    return report.shouldReportAppRunBlocked
}

func cjguiInternalAppRunSurfaceShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunSurfaceDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didAcceptAppRun) {
        return false
    }
    if (report.shouldDeferAppRun == false) {
        return false
    }
    return report.shouldReportAppRunBlocked
}

func cjguiInternalAppRunSurfaceCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunSurfaceDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didAcceptAppRun) {
        return false
    }
    if (report.shouldDeferAppRun == false) {
        return false
    }
    return report.shouldReportAppRunBlocked
}

func cjguiInternalAppRunControllerOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultAppRunControllerDraft()
    if (report.didEvaluateController == false) {
        return false
    }
    if (report.decision.shouldEnterAcceptedPath == false) {
        return false
    }
    if (report.decision.shouldEnterDeferredPath) {
        return false
    }
    if (report.decision.shouldEnterBlockedPath) {
        return false
    }
    return report.decision.shouldRequestFutureRunBoundary
}

func cjguiInternalAppRunControllerRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteAppRunControllerDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didEvaluateController == false) {
        return false
    }
    if (report.decision.shouldEnterAcceptedPath) {
        return false
    }
    if (report.decision.shouldEnterDeferredPath == false) {
        return false
    }
    if (report.decision.shouldEnterBlockedPath == false) {
        return false
    }
    return report.decision.shouldRequestFutureRunBoundary == false
}

func cjguiInternalAppRunControllerInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunControllerDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didEvaluateController == false) {
        return false
    }
    if (report.decision.shouldEnterAcceptedPath) {
        return false
    }
    if (report.decision.shouldEnterDeferredPath == false) {
        return false
    }
    if (report.decision.shouldEnterBlockedPath == false) {
        return false
    }
    return report.decision.shouldRequestFutureRunBoundary == false
}

func cjguiInternalAppRunControllerShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunControllerDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didEvaluateController == false) {
        return false
    }
    if (report.decision.shouldEnterAcceptedPath) {
        return false
    }
    if (report.decision.shouldEnterDeferredPath == false) {
        return false
    }
    if (report.decision.shouldEnterBlockedPath == false) {
        return false
    }
    return report.decision.shouldRequestFutureRunBoundary == false
}

func cjguiInternalAppRunControllerCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunControllerDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didEvaluateController == false) {
        return false
    }
    if (report.decision.shouldEnterAcceptedPath) {
        return false
    }
    if (report.decision.shouldEnterDeferredPath == false) {
        return false
    }
    if (report.decision.shouldEnterBlockedPath == false) {
        return false
    }
    return report.decision.shouldRequestFutureRunBoundary == false
}

func cjguiInternalAppRunExecutionPlanOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultAppRunExecutionPlanDraft()
    if (report.didBuildPlan == false) {
        return false
    }
    if (report.plan.shouldPrepareRuntime == false) {
        return false
    }
    if (report.plan.shouldEnterRunLoopDraft == false) {
        return false
    }
    if (report.plan.shouldDeferExecution) {
        return false
    }
    if (report.plan.shouldReportBlockedExecution) {
        return false
    }
    return report.plan.shouldRequestFutureBoundary
}

func cjguiInternalAppRunExecutionPlanRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteAppRunExecutionPlanDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildPlan == false) {
        return false
    }
    if (report.plan.shouldPrepareRuntime) {
        return false
    }
    if (report.plan.shouldEnterRunLoopDraft) {
        return false
    }
    if (report.plan.shouldDeferExecution == false) {
        return false
    }
    if (report.plan.shouldReportBlockedExecution == false) {
        return false
    }
    return report.plan.shouldRequestFutureBoundary == false
}

func cjguiInternalAppRunExecutionPlanInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunExecutionPlanDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildPlan == false) {
        return false
    }
    if (report.plan.shouldPrepareRuntime) {
        return false
    }
    if (report.plan.shouldEnterRunLoopDraft) {
        return false
    }
    if (report.plan.shouldDeferExecution == false) {
        return false
    }
    if (report.plan.shouldReportBlockedExecution == false) {
        return false
    }
    return report.plan.shouldRequestFutureBoundary == false
}

func cjguiInternalAppRunExecutionPlanShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunExecutionPlanDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didBuildPlan == false) {
        return false
    }
    if (report.plan.shouldPrepareRuntime) {
        return false
    }
    if (report.plan.shouldEnterRunLoopDraft) {
        return false
    }
    if (report.plan.shouldDeferExecution == false) {
        return false
    }
    if (report.plan.shouldReportBlockedExecution == false) {
        return false
    }
    return report.plan.shouldRequestFutureBoundary == false
}

func cjguiInternalAppRunExecutionPlanCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunExecutionPlanDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didBuildPlan == false) {
        return false
    }
    if (report.plan.shouldPrepareRuntime) {
        return false
    }
    if (report.plan.shouldEnterRunLoopDraft) {
        return false
    }
    if (report.plan.shouldDeferExecution == false) {
        return false
    }
    if (report.plan.shouldReportBlockedExecution == false) {
        return false
    }
    return report.plan.shouldRequestFutureBoundary == false
}

func cjguiInternalAppRunDispatchOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultAppRunDispatchDraft()
    if (report.didBuildDispatchSummary == false) {
        return false
    }
    if (report.summary.shouldDispatchPrepareRuntime == false) {
        return false
    }
    if (report.summary.shouldDispatchRunLoopDraft == false) {
        return false
    }
    if (report.summary.shouldDispatchDeferredNotice) {
        return false
    }
    if (report.summary.shouldDispatchBlockedNotice) {
        return false
    }
    return report.summary.shouldDispatchFutureBoundaryRequest
}

func cjguiInternalAppRunDispatchRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteAppRunDispatchDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildDispatchSummary == false) {
        return false
    }
    if (report.summary.shouldDispatchPrepareRuntime) {
        return false
    }
    if (report.summary.shouldDispatchRunLoopDraft) {
        return false
    }
    if (report.summary.shouldDispatchDeferredNotice == false) {
        return false
    }
    if (report.summary.shouldDispatchBlockedNotice == false) {
        return false
    }
    return report.summary.shouldDispatchFutureBoundaryRequest == false
}

func cjguiInternalAppRunDispatchInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunDispatchDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildDispatchSummary == false) {
        return false
    }
    if (report.summary.shouldDispatchPrepareRuntime) {
        return false
    }
    if (report.summary.shouldDispatchRunLoopDraft) {
        return false
    }
    if (report.summary.shouldDispatchDeferredNotice == false) {
        return false
    }
    if (report.summary.shouldDispatchBlockedNotice == false) {
        return false
    }
    return report.summary.shouldDispatchFutureBoundaryRequest == false
}

func cjguiInternalAppRunDispatchShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunDispatchDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didBuildDispatchSummary == false) {
        return false
    }
    if (report.summary.shouldDispatchPrepareRuntime) {
        return false
    }
    if (report.summary.shouldDispatchRunLoopDraft) {
        return false
    }
    if (report.summary.shouldDispatchDeferredNotice == false) {
        return false
    }
    if (report.summary.shouldDispatchBlockedNotice == false) {
        return false
    }
    return report.summary.shouldDispatchFutureBoundaryRequest == false
}

func cjguiInternalAppRunDispatchCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteAppRunDispatchDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didBuildDispatchSummary == false) {
        return false
    }
    if (report.summary.shouldDispatchPrepareRuntime) {
        return false
    }
    if (report.summary.shouldDispatchRunLoopDraft) {
        return false
    }
    if (report.summary.shouldDispatchDeferredNotice == false) {
        return false
    }
    if (report.summary.shouldDispatchBlockedNotice == false) {
        return false
    }
    return report.summary.shouldDispatchFutureBoundaryRequest == false
}

func cjguiInternalRunLoopDraftOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultRunLoopDraft()
    if (report.didBuildLoopDraft == false) {
        return false
    }
    if (report.intent.shouldEnterLoopDraft == false) {
        return false
    }
    if (report.intent.shouldDeferLoopDraft) {
        return false
    }
    if (report.intent.shouldReportLoopBlocked) {
        return false
    }
    return report.intent.shouldRequestFutureBoundary
}

func cjguiInternalRunLoopDraftRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteRunLoopDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildLoopDraft == false) {
        return false
    }
    if (report.intent.shouldEnterLoopDraft) {
        return false
    }
    if (report.intent.shouldDeferLoopDraft == false) {
        return false
    }
    if (report.intent.shouldReportLoopBlocked == false) {
        return false
    }
    return report.intent.shouldRequestFutureBoundary == false
}

func cjguiInternalRunLoopDraftInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteRunLoopDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildLoopDraft == false) {
        return false
    }
    if (report.intent.shouldEnterLoopDraft) {
        return false
    }
    if (report.intent.shouldDeferLoopDraft == false) {
        return false
    }
    if (report.intent.shouldReportLoopBlocked == false) {
        return false
    }
    return report.intent.shouldRequestFutureBoundary == false
}

func cjguiInternalRunLoopDraftShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteRunLoopDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didBuildLoopDraft == false) {
        return false
    }
    if (report.intent.shouldEnterLoopDraft) {
        return false
    }
    if (report.intent.shouldDeferLoopDraft == false) {
        return false
    }
    if (report.intent.shouldReportLoopBlocked == false) {
        return false
    }
    return report.intent.shouldRequestFutureBoundary == false
}

func cjguiInternalRunLoopDraftCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteRunLoopDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didBuildLoopDraft == false) {
        return false
    }
    if (report.intent.shouldEnterLoopDraft) {
        return false
    }
    if (report.intent.shouldDeferLoopDraft == false) {
        return false
    }
    if (report.intent.shouldReportLoopBlocked == false) {
        return false
    }
    return report.intent.shouldRequestFutureBoundary == false
}

func cjguiInternalLoopIterationDraftOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultLoopIterationDraft()
    if (report.didBuildIterationDraft == false) {
        return false
    }
    if (report.intent.shouldAttemptIteration == false) {
        return false
    }
    if (report.intent.shouldDeferIteration) {
        return false
    }
    if (report.intent.shouldReportIterationBlocked) {
        return false
    }
    return report.intent.shouldRequestFutureBoundary
}

func cjguiInternalLoopIterationDraftRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteLoopIterationDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildIterationDraft == false) {
        return false
    }
    if (report.intent.shouldAttemptIteration) {
        return false
    }
    if (report.intent.shouldDeferIteration == false) {
        return false
    }
    if (report.intent.shouldReportIterationBlocked == false) {
        return false
    }
    return report.intent.shouldRequestFutureBoundary == false
}

func cjguiInternalLoopIterationDraftInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLoopIterationDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildIterationDraft == false) {
        return false
    }
    if (report.intent.shouldAttemptIteration) {
        return false
    }
    if (report.intent.shouldDeferIteration == false) {
        return false
    }
    if (report.intent.shouldReportIterationBlocked == false) {
        return false
    }
    return report.intent.shouldRequestFutureBoundary == false
}

func cjguiInternalLoopIterationDraftShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLoopIterationDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didBuildIterationDraft == false) {
        return false
    }
    if (report.intent.shouldAttemptIteration) {
        return false
    }
    if (report.intent.shouldDeferIteration == false) {
        return false
    }
    if (report.intent.shouldReportIterationBlocked == false) {
        return false
    }
    return report.intent.shouldRequestFutureBoundary == false
}

func cjguiInternalLoopIterationDraftCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLoopIterationDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didBuildIterationDraft == false) {
        return false
    }
    if (report.intent.shouldAttemptIteration) {
        return false
    }
    if (report.intent.shouldDeferIteration == false) {
        return false
    }
    if (report.intent.shouldReportIterationBlocked == false) {
        return false
    }
    return report.intent.shouldRequestFutureBoundary == false
}

func cjguiInternalIterationWorkPacketDraftOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultIterationWorkPacketDraft()
    if (report.didBuildWorkPacket == false) {
        return false
    }
    if (report.packet.shouldPrepareRuntimeWork == false) {
        return false
    }
    if (report.packet.shouldProcessLifecycleWork == false) {
        return false
    }
    if (report.packet.shouldPrepareFutureBoundaryWork == false) {
        return false
    }
    if (report.packet.shouldDeferWork) {
        return false
    }
    return report.packet.shouldReportBlockedWork == false
}

func cjguiInternalIterationWorkPacketDraftRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteIterationWorkPacketDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildWorkPacket == false) {
        return false
    }
    if (report.packet.shouldPrepareRuntimeWork) {
        return false
    }
    if (report.packet.shouldProcessLifecycleWork) {
        return false
    }
    if (report.packet.shouldPrepareFutureBoundaryWork) {
        return false
    }
    if (report.packet.shouldDeferWork == false) {
        return false
    }
    return report.packet.shouldReportBlockedWork
}

func cjguiInternalIterationWorkPacketDraftInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteIterationWorkPacketDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildWorkPacket == false) {
        return false
    }
    if (report.packet.shouldPrepareRuntimeWork) {
        return false
    }
    if (report.packet.shouldProcessLifecycleWork) {
        return false
    }
    if (report.packet.shouldPrepareFutureBoundaryWork) {
        return false
    }
    if (report.packet.shouldDeferWork == false) {
        return false
    }
    return report.packet.shouldReportBlockedWork
}

func cjguiInternalIterationWorkPacketDraftShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteIterationWorkPacketDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didBuildWorkPacket == false) {
        return false
    }
    if (report.packet.shouldPrepareRuntimeWork) {
        return false
    }
    if (report.packet.shouldProcessLifecycleWork) {
        return false
    }
    if (report.packet.shouldPrepareFutureBoundaryWork) {
        return false
    }
    if (report.packet.shouldDeferWork == false) {
        return false
    }
    return report.packet.shouldReportBlockedWork
}

func cjguiInternalIterationWorkPacketDraftCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteIterationWorkPacketDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didBuildWorkPacket == false) {
        return false
    }
    if (report.packet.shouldPrepareRuntimeWork) {
        return false
    }
    if (report.packet.shouldProcessLifecycleWork) {
        return false
    }
    if (report.packet.shouldPrepareFutureBoundaryWork) {
        return false
    }
    if (report.packet.shouldDeferWork == false) {
        return false
    }
    return report.packet.shouldReportBlockedWork
}

func cjguiInternalLifecycleWorkDraftOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultLifecycleWorkDraft()
    if (report.didBuildLifecycleWorkDraft == false) {
        return false
    }
    if (report.draft.shouldProcessLifecycleWork == false) {
        return false
    }
    if (report.draft.shouldDeferLifecycleWork) {
        return false
    }
    if (report.draft.shouldReportLifecycleBlocked) {
        return false
    }
    return report.draft.shouldPrepareFutureBoundaryAfterLifecycle
}

func cjguiInternalLifecycleWorkDraftRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteLifecycleWorkDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildLifecycleWorkDraft == false) {
        return false
    }
    if (report.draft.shouldProcessLifecycleWork) {
        return false
    }
    if (report.draft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.draft.shouldReportLifecycleBlocked == false) {
        return false
    }
    return report.draft.shouldPrepareFutureBoundaryAfterLifecycle == false
}

func cjguiInternalLifecycleWorkDraftInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleWorkDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildLifecycleWorkDraft == false) {
        return false
    }
    if (report.draft.shouldProcessLifecycleWork) {
        return false
    }
    if (report.draft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.draft.shouldReportLifecycleBlocked == false) {
        return false
    }
    return report.draft.shouldPrepareFutureBoundaryAfterLifecycle == false
}

func cjguiInternalLifecycleWorkDraftShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleWorkDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didBuildLifecycleWorkDraft == false) {
        return false
    }
    if (report.draft.shouldProcessLifecycleWork) {
        return false
    }
    if (report.draft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.draft.shouldReportLifecycleBlocked == false) {
        return false
    }
    return report.draft.shouldPrepareFutureBoundaryAfterLifecycle == false
}

func cjguiInternalLifecycleWorkDraftCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleWorkDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didBuildLifecycleWorkDraft == false) {
        return false
    }
    if (report.draft.shouldProcessLifecycleWork) {
        return false
    }
    if (report.draft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.draft.shouldReportLifecycleBlocked == false) {
        return false
    }
    return report.draft.shouldPrepareFutureBoundaryAfterLifecycle == false
}

func cjguiInternalLifecycleOwnerHandoffOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultLifecycleOwnerHandoffDraft()
    if (report.didBuildOwnerHandoff == false) {
        return false
    }
    if (report.appDraft.shouldAcceptLifecycleWork == false) {
        return false
    }
    if (report.windowDraft.shouldAcceptLifecycleWork == false) {
        return false
    }
    if (report.appDraft.shouldDeferLifecycleWork) {
        return false
    }
    if (report.windowDraft.shouldDeferLifecycleWork) {
        return false
    }
    if (report.appDraft.shouldReportLifecycleBlocked) {
        return false
    }
    return report.windowDraft.shouldReportLifecycleBlocked == false
}

func cjguiInternalLifecycleOwnerHandoffRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteLifecycleOwnerHandoffDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildOwnerHandoff == false) {
        return false
    }
    if (report.appDraft.shouldAcceptLifecycleWork) {
        return false
    }
    if (report.windowDraft.shouldAcceptLifecycleWork) {
        return false
    }
    if (report.appDraft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.windowDraft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.appDraft.shouldReportLifecycleBlocked == false) {
        return false
    }
    return report.windowDraft.shouldReportLifecycleBlocked
}

func cjguiInternalLifecycleOwnerHandoffInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleOwnerHandoffDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildOwnerHandoff == false) {
        return false
    }
    if (report.appDraft.shouldAcceptLifecycleWork) {
        return false
    }
    if (report.windowDraft.shouldAcceptLifecycleWork) {
        return false
    }
    if (report.appDraft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.windowDraft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.appDraft.shouldReportLifecycleBlocked == false) {
        return false
    }
    return report.windowDraft.shouldReportLifecycleBlocked
}

func cjguiInternalLifecycleOwnerHandoffShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleOwnerHandoffDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didBuildOwnerHandoff == false) {
        return false
    }
    if (report.appDraft.shouldAcceptLifecycleWork) {
        return false
    }
    if (report.windowDraft.shouldAcceptLifecycleWork) {
        return false
    }
    if (report.appDraft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.windowDraft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.appDraft.shouldReportLifecycleBlocked == false) {
        return false
    }
    return report.windowDraft.shouldReportLifecycleBlocked
}

func cjguiInternalLifecycleOwnerHandoffCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleOwnerHandoffDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didBuildOwnerHandoff == false) {
        return false
    }
    if (report.appDraft.shouldAcceptLifecycleWork) {
        return false
    }
    if (report.windowDraft.shouldAcceptLifecycleWork) {
        return false
    }
    if (report.appDraft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.windowDraft.shouldDeferLifecycleWork == false) {
        return false
    }
    if (report.appDraft.shouldReportLifecycleBlocked == false) {
        return false
    }
    return report.windowDraft.shouldReportLifecycleBlocked
}

func cjguiInternalLifecycleMutationReadinessOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultLifecycleMutationReadinessDraft()
    if (report.didBuildMutationReadiness == false) {
        return false
    }
    if (report.appReadiness.canMutateAppLifecycle == false) {
        return false
    }
    if (report.windowReadiness.canMutateWindowLifecycle == false) {
        return false
    }
    if (report.canMutateLifecycleOwners == false) {
        return false
    }
    if (report.shouldDeferLifecycleMutation) {
        return false
    }
    return report.shouldReportLifecycleMutationBlocked == false
}

func cjguiInternalLifecycleMutationReadinessRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteLifecycleMutationReadinessDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildMutationReadiness == false) {
        return false
    }
    if (report.appReadiness.canMutateAppLifecycle) {
        return false
    }
    if (report.windowReadiness.canMutateWindowLifecycle) {
        return false
    }
    if (report.canMutateLifecycleOwners) {
        return false
    }
    if (report.shouldDeferLifecycleMutation == false) {
        return false
    }
    return report.shouldReportLifecycleMutationBlocked
}

func cjguiInternalLifecycleMutationReadinessInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleMutationReadinessDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildMutationReadiness == false) {
        return false
    }
    if (report.appReadiness.canMutateAppLifecycle) {
        return false
    }
    if (report.windowReadiness.canMutateWindowLifecycle) {
        return false
    }
    if (report.canMutateLifecycleOwners) {
        return false
    }
    if (report.shouldDeferLifecycleMutation == false) {
        return false
    }
    return report.shouldReportLifecycleMutationBlocked
}

func cjguiInternalLifecycleMutationReadinessShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleMutationReadinessDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didBuildMutationReadiness == false) {
        return false
    }
    if (report.appReadiness.canMutateAppLifecycle) {
        return false
    }
    if (report.windowReadiness.canMutateWindowLifecycle) {
        return false
    }
    if (report.canMutateLifecycleOwners) {
        return false
    }
    if (report.shouldDeferLifecycleMutation == false) {
        return false
    }
    return report.shouldReportLifecycleMutationBlocked
}

func cjguiInternalLifecycleMutationReadinessCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleMutationReadinessDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didBuildMutationReadiness == false) {
        return false
    }
    if (report.appReadiness.canMutateAppLifecycle) {
        return false
    }
    if (report.windowReadiness.canMutateWindowLifecycle) {
        return false
    }
    if (report.canMutateLifecycleOwners) {
        return false
    }
    if (report.shouldDeferLifecycleMutation == false) {
        return false
    }
    return report.shouldReportLifecycleMutationBlocked
}

func cjguiInternalLifecycleMutationPlanOpenSanity(): Bool {
    let report = cjguiInternalExecuteDefaultLifecycleMutationPlanDraft()
    if (report.didBuildMutationPlan == false) {
        return false
    }
    if (report.appPlan.shouldPlanAppLifecycleMutation == false) {
        return false
    }
    if (report.windowPlan.shouldPlanWindowLifecycleMutation == false) {
        return false
    }
    if (report.shouldPlanLifecycleMutation == false) {
        return false
    }
    if (report.shouldDeferLifecycleMutationPlan) {
        return false
    }
    return report.shouldReportLifecycleMutationPlanBlocked == false
}

func cjguiInternalLifecycleMutationPlanRuntimeBlockedSanity(): Bool {
    let root = cjguiInternalBuildRuntimeRootState()
    let cycleRequest = CjguiInternalRuntimeCycleRequest(
        CjguiInternalRuntimeRootState(
            root.bootstrap,
            false
        ),
        cjguiInternalDefaultRuntimeStepInput(),
        cjguiInternalDefaultRuntimeStepPolicy()
    )
    let driverRequest = CjguiInternalRuntimeDriverRequest(
        CjguiInternalRuntimeCommandPipelineRequest(cycleRequest)
    )
    let report = cjguiInternalExecuteLifecycleMutationPlanDraft(
        driverRequest,
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildMutationPlan == false) {
        return false
    }
    if (report.appPlan.shouldPlanAppLifecycleMutation) {
        return false
    }
    if (report.windowPlan.shouldPlanWindowLifecycleMutation) {
        return false
    }
    if (report.shouldPlanLifecycleMutation) {
        return false
    }
    if (report.shouldDeferLifecycleMutationPlan == false) {
        return false
    }
    return report.shouldReportLifecycleMutationPlanBlocked
}

func cjguiInternalLifecycleMutationPlanInputBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleMutationPlanDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        CjguiInternalRuntimeDriverInput(false, false),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalDefaultRuntimeShutdownIntent()
    )
    if (report.didBuildMutationPlan == false) {
        return false
    }
    if (report.appPlan.shouldPlanAppLifecycleMutation) {
        return false
    }
    if (report.windowPlan.shouldPlanWindowLifecycleMutation) {
        return false
    }
    if (report.shouldPlanLifecycleMutation) {
        return false
    }
    if (report.shouldDeferLifecycleMutationPlan == false) {
        return false
    }
    return report.shouldReportLifecycleMutationPlanBlocked
}

func cjguiInternalLifecycleMutationPlanShutdownBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleMutationPlanDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(true, false)
    )
    if (report.didBuildMutationPlan == false) {
        return false
    }
    if (report.appPlan.shouldPlanAppLifecycleMutation) {
        return false
    }
    if (report.windowPlan.shouldPlanWindowLifecycleMutation) {
        return false
    }
    if (report.shouldPlanLifecycleMutation) {
        return false
    }
    if (report.shouldDeferLifecycleMutationPlan == false) {
        return false
    }
    return report.shouldReportLifecycleMutationPlanBlocked
}

func cjguiInternalLifecycleMutationPlanCancellationBlockedSanity(): Bool {
    let report = cjguiInternalExecuteLifecycleMutationPlanDraft(
        cjguiInternalDefaultRuntimeDriverRequest(),
        cjguiInternalDefaultRuntimeDriverInput(),
        cjguiInternalDefaultRuntimeDriverPolicy(),
        cjguiInternalBuildRuntimeShutdownIntent(false, true)
    )
    if (report.didBuildMutationPlan == false) {
        return false
    }
    if (report.appPlan.shouldPlanAppLifecycleMutation) {
        return false
    }
    if (report.windowPlan.shouldPlanWindowLifecycleMutation) {
        return false
    }
    if (report.shouldPlanLifecycleMutation) {
        return false
    }
    if (report.shouldDeferLifecycleMutationPlan == false) {
        return false
    }
    return report.shouldReportLifecycleMutationPlanBlocked
}

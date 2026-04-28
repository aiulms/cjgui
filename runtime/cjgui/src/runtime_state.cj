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

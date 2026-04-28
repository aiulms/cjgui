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
// - 它只聚合 step 后的 root state 与 didAdvance Bool。
// - 它不定义 runtime state machine、event loop、queue / drain 或 app run。
// - 它不改变 root state shape、bootstrap behavior、projection、coordination、
//   constructor shape、public runtime API 或 public C ABI。

struct CjguiInternalRuntimeStepResult {
    let state: CjguiInternalRuntimeRootState
    let didAdvance: Bool

    init(
        state: CjguiInternalRuntimeRootState,
        didAdvance: Bool
    ) {
        this.state = state
        this.didAdvance = didAdvance
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
    return CjguiInternalRuntimeStepResult(
        state,
        state.isRuntimeReady
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
    return CjguiInternalRuntimeStepResult(
        state,
        decision.shouldAdvance
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

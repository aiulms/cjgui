package cjgui

// P1 minimal app/window lifecycle runtime skeleton.
// 日期: 2026-04-26
//
// 本文件当前只承载一个默认 internal 的 window lifecycle 状态标记、
// 一个最小 no-op transition、一个最小 state marker transition,
// 两个最小脱水 Bool 形状字段,
// 以及边界说明注释。
// 它不定义 stable public API。
// 它不实现真实 window lifecycle 行为。
// 它不创建、关闭或销毁 platform window。
// 它不暴露 native handles 或 platform objects。

// 内部 window lifecycle 状态标记:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只标记 window lifecycle state 边界存在。
// - 它同时标记 window state machine 尚未定义。
// - 它只有两个不可变 Bool 字段:
//   - hasWindowState, 只标记 window state boundary 存在,
//     不定义 window state taxonomy。
//   - hasObservedPlatformReady, 默认构造为 false, 只标记已观察到脱水
//     platform readiness fact, 不定义 window create / close / destroy 行为。
// - 它的构造期初始化只允许写入这两枚不可变 Bool facts。
// - 它没有其他字段、enum、handle、handle table、generation、import 或行为。
// - 它不是 window create、request close、destroy、release、
//   public runtime API、public C ABI、platform object wrapper 或 native handle。

struct CjguiInternalWindowLifecycleState {
    let hasWindowState: Bool
    let hasObservedPlatformReady: Bool

    init() {
        this.hasWindowState = false
        this.hasObservedPlatformReady = false
    }

    init(hasWindowState: Bool, hasObservedPlatformReady: Bool) {
        this.hasWindowState = hasWindowState
        this.hasObservedPlatformReady = hasObservedPlatformReady
    }
}

// 内部 no-op window lifecycle transition 函数:
// - 这是普通顶层函数, 使用默认 internal 可见性。
// - 它只证明 package 可以承载内部 window lifecycle transition 函数形状。
// - 它原样返回输入 state。
// - 它不修改 hasWindowState。
// - 它不修改 hasObservedPlatformReady。
// - 它不是 create、request close、destroy、release、public runtime API、
//   public C ABI、platform object wrapper 或 native handle。

func cjguiInternalNoOpWindowLifecycleTransition(
    state: CjguiInternalWindowLifecycleState
): CjguiInternalWindowLifecycleState {
    state
}

// 内部 window lifecycle state marker transition 函数:
// - 这是普通顶层函数, 使用默认 internal 可见性。
// - 它只把 hasWindowState 推进为 true。
// - 它保留输入 state 的 hasObservedPlatformReady 值。
// - 它不定义 window state taxonomy。
// - 它不是 create、request close、destroy、release、public runtime API、
//   public C ABI、platform object wrapper 或 native handle。

func cjguiInternalWindowLifecycleStateMarkerTransition(
    state: CjguiInternalWindowLifecycleState
): CjguiInternalWindowLifecycleState {
    CjguiInternalWindowLifecycleState(
        true,
        state.hasObservedPlatformReady
    )
}

// 内部 window lifecycle readiness predicate:
// - 这是普通顶层函数, 使用默认 internal 可见性。
// - 它只读取 hasObservedPlatformReady 这一枚脱水 Bool fact。
// - 它不改变 state shape、constructor shape 或 projection behavior。
// - 它不是 create、request close、destroy、release、public runtime API、
//   public C ABI、platform object wrapper 或 native handle。

func cjguiInternalWindowLifecycleHasObservedPlatformReady(
    state: CjguiInternalWindowLifecycleState
): Bool {
    state.hasObservedPlatformReady
}

// 内部 window lifecycle owner handoff draft:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 window lifecycle owner-facing handoff facts。
// - 它不修改 window lifecycle state, 不执行 create / close / destroy / release。
// - 它不是 public runtime API、public C ABI、platform object wrapper 或 native handle。

struct CjguiInternalWindowLifecycleWorkHandoffDraft {
    let shouldAcceptLifecycleWork: Bool
    let shouldDeferLifecycleWork: Bool
    let shouldReportLifecycleBlocked: Bool

    init(
        shouldAcceptLifecycleWork: Bool,
        shouldDeferLifecycleWork: Bool,
        shouldReportLifecycleBlocked: Bool
    ) {
        this.shouldAcceptLifecycleWork = shouldAcceptLifecycleWork
        this.shouldDeferLifecycleWork = shouldDeferLifecycleWork
        this.shouldReportLifecycleBlocked = shouldReportLifecycleBlocked
    }
}

func cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
    shouldProcessLifecycleWork: Bool,
    shouldDeferLifecycleWork: Bool,
    shouldReportLifecycleBlocked: Bool
): CjguiInternalWindowLifecycleWorkHandoffDraft {
    return CjguiInternalWindowLifecycleWorkHandoffDraft(
        shouldProcessLifecycleWork,
        shouldDeferLifecycleWork,
        shouldReportLifecycleBlocked
    )
}

func cjguiInternalWindowLifecycleWorkHandoffOpenSanity(): Bool {
    let draft = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        true,
        false,
        false
    )
    if (draft.shouldAcceptLifecycleWork == false) {
        return false
    }
    if (draft.shouldDeferLifecycleWork) {
        return false
    }
    return draft.shouldReportLifecycleBlocked == false
}

func cjguiInternalWindowLifecycleWorkHandoffBlockedSanity(): Bool {
    let draft = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        false,
        true,
        true
    )
    if (draft.shouldAcceptLifecycleWork) {
        return false
    }
    if (draft.shouldDeferLifecycleWork == false) {
        return false
    }
    return draft.shouldReportLifecycleBlocked
}

// 内部 window lifecycle mutation readiness draft:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 window lifecycle owner 是否具备 mutation readiness。
// - 它不修改 CjguiInternalWindowLifecycleState, 不调用 transition functions。
// - 它不执行 create / close / destroy / release。
// - 它不是 public runtime API、public C ABI、platform object wrapper 或 native handle。

struct CjguiInternalWindowLifecycleMutationReadinessDraft {
    let canMutateWindowLifecycle: Bool
    let shouldDeferWindowLifecycleMutation: Bool
    let shouldReportWindowLifecycleMutationBlocked: Bool

    init(
        canMutateWindowLifecycle: Bool,
        shouldDeferWindowLifecycleMutation: Bool,
        shouldReportWindowLifecycleMutationBlocked: Bool
    ) {
        this.canMutateWindowLifecycle = canMutateWindowLifecycle
        this.shouldDeferWindowLifecycleMutation = shouldDeferWindowLifecycleMutation
        this.shouldReportWindowLifecycleMutationBlocked = shouldReportWindowLifecycleMutationBlocked
    }
}

func cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
    handoff: CjguiInternalWindowLifecycleWorkHandoffDraft
): CjguiInternalWindowLifecycleMutationReadinessDraft {
    return CjguiInternalWindowLifecycleMutationReadinessDraft(
        handoff.shouldAcceptLifecycleWork,
        handoff.shouldDeferLifecycleWork,
        handoff.shouldReportLifecycleBlocked
    )
}

func cjguiInternalWindowLifecycleMutationReadinessOpenSanity(): Bool {
    let handoff = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        true,
        false,
        false
    )
    let readiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        handoff
    )
    if (readiness.canMutateWindowLifecycle == false) {
        return false
    }
    if (readiness.shouldDeferWindowLifecycleMutation) {
        return false
    }
    return readiness.shouldReportWindowLifecycleMutationBlocked == false
}

func cjguiInternalWindowLifecycleMutationReadinessBlockedSanity(): Bool {
    let handoff = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        false,
        true,
        true
    )
    let readiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        handoff
    )
    if (readiness.canMutateWindowLifecycle) {
        return false
    }
    if (readiness.shouldDeferWindowLifecycleMutation == false) {
        return false
    }
    return readiness.shouldReportWindowLifecycleMutationBlocked
}

// 内部 window lifecycle mutation plan draft:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 window lifecycle owner 是否应计划 mutation。
// - 它不修改 CjguiInternalWindowLifecycleState, 不调用 transition functions。
// - 它不执行 create / close / destroy / release。
// - 它不是 public runtime API、public C ABI、platform object wrapper 或 native handle。

struct CjguiInternalWindowLifecycleMutationPlanDraft {
    let shouldPlanWindowLifecycleMutation: Bool
    let shouldDeferWindowLifecycleMutationPlan: Bool
    let shouldReportWindowLifecycleMutationPlanBlocked: Bool

    init(
        shouldPlanWindowLifecycleMutation: Bool,
        shouldDeferWindowLifecycleMutationPlan: Bool,
        shouldReportWindowLifecycleMutationPlanBlocked: Bool
    ) {
        this.shouldPlanWindowLifecycleMutation = shouldPlanWindowLifecycleMutation
        this.shouldDeferWindowLifecycleMutationPlan = shouldDeferWindowLifecycleMutationPlan
        this.shouldReportWindowLifecycleMutationPlanBlocked = shouldReportWindowLifecycleMutationPlanBlocked
    }
}

func cjguiInternalBuildWindowLifecycleMutationPlanDraft(
    readiness: CjguiInternalWindowLifecycleMutationReadinessDraft
): CjguiInternalWindowLifecycleMutationPlanDraft {
    return CjguiInternalWindowLifecycleMutationPlanDraft(
        readiness.canMutateWindowLifecycle,
        readiness.shouldDeferWindowLifecycleMutation,
        readiness.shouldReportWindowLifecycleMutationBlocked
    )
}

func cjguiInternalWindowLifecycleMutationPlanOpenSanity(): Bool {
    let handoff = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        true,
        false,
        false
    )
    let readiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        handoff
    )
    let plan = cjguiInternalBuildWindowLifecycleMutationPlanDraft(readiness)
    if (plan.shouldPlanWindowLifecycleMutation == false) {
        return false
    }
    if (plan.shouldDeferWindowLifecycleMutationPlan) {
        return false
    }
    return plan.shouldReportWindowLifecycleMutationPlanBlocked == false
}

func cjguiInternalWindowLifecycleMutationPlanBlockedSanity(): Bool {
    let handoff = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        false,
        true,
        true
    )
    let readiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        handoff
    )
    let plan = cjguiInternalBuildWindowLifecycleMutationPlanDraft(readiness)
    if (plan.shouldPlanWindowLifecycleMutation) {
        return false
    }
    if (plan.shouldDeferWindowLifecycleMutationPlan == false) {
        return false
    }
    return plan.shouldReportWindowLifecycleMutationPlanBlocked
}

// 内部 window lifecycle mutation commit gate draft:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 window lifecycle owner 是否可以进入 mutation commit gate。
// - 它不修改 CjguiInternalWindowLifecycleState, 不调用 transition functions。
// - 它不执行 create / close / destroy / release。
// - 它不是 public runtime API、public C ABI、platform object wrapper 或 native handle。

struct CjguiInternalWindowLifecycleMutationCommitGateDraft {
    let canEnterWindowLifecycleMutationCommit: Bool
    let shouldDeferWindowLifecycleMutationCommit: Bool
    let shouldReportWindowLifecycleMutationCommitBlocked: Bool

    init(
        canEnterWindowLifecycleMutationCommit: Bool,
        shouldDeferWindowLifecycleMutationCommit: Bool,
        shouldReportWindowLifecycleMutationCommitBlocked: Bool
    ) {
        this.canEnterWindowLifecycleMutationCommit = canEnterWindowLifecycleMutationCommit
        this.shouldDeferWindowLifecycleMutationCommit = shouldDeferWindowLifecycleMutationCommit
        this.shouldReportWindowLifecycleMutationCommitBlocked = shouldReportWindowLifecycleMutationCommitBlocked
    }
}

func cjguiInternalBuildWindowLifecycleMutationCommitGateDraft(
    plan: CjguiInternalWindowLifecycleMutationPlanDraft
): CjguiInternalWindowLifecycleMutationCommitGateDraft {
    return CjguiInternalWindowLifecycleMutationCommitGateDraft(
        plan.shouldPlanWindowLifecycleMutation,
        plan.shouldDeferWindowLifecycleMutationPlan,
        plan.shouldReportWindowLifecycleMutationPlanBlocked
    )
}

func cjguiInternalWindowLifecycleMutationCommitGateOpenSanity(): Bool {
    let handoff = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        true,
        false,
        false
    )
    let readiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        handoff
    )
    let plan = cjguiInternalBuildWindowLifecycleMutationPlanDraft(readiness)
    let gate = cjguiInternalBuildWindowLifecycleMutationCommitGateDraft(plan)
    if (gate.canEnterWindowLifecycleMutationCommit == false) {
        return false
    }
    if (gate.shouldDeferWindowLifecycleMutationCommit) {
        return false
    }
    return gate.shouldReportWindowLifecycleMutationCommitBlocked == false
}

func cjguiInternalWindowLifecycleMutationCommitGateBlockedSanity(): Bool {
    let handoff = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        false,
        true,
        true
    )
    let readiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        handoff
    )
    let plan = cjguiInternalBuildWindowLifecycleMutationPlanDraft(readiness)
    let gate = cjguiInternalBuildWindowLifecycleMutationCommitGateDraft(plan)
    if (gate.canEnterWindowLifecycleMutationCommit) {
        return false
    }
    if (gate.shouldDeferWindowLifecycleMutationCommit == false) {
        return false
    }
    return gate.shouldReportWindowLifecycleMutationCommitBlocked
}

// 内部 window lifecycle mutation apply draft:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只表达 window lifecycle owner 是否应产生 mutation apply intent。
// - 它不修改 CjguiInternalWindowLifecycleState, 不调用 transition functions。
// - 它不执行 create / close / destroy / release。
// - 它不是 public runtime API、public C ABI、platform object wrapper 或 native handle。

struct CjguiInternalWindowLifecycleMutationApplyDraft {
    let shouldApplyWindowLifecycleMutation: Bool
    let shouldDeferWindowLifecycleMutationApply: Bool
    let shouldReportWindowLifecycleMutationApplyBlocked: Bool

    init(
        shouldApplyWindowLifecycleMutation: Bool,
        shouldDeferWindowLifecycleMutationApply: Bool,
        shouldReportWindowLifecycleMutationApplyBlocked: Bool
    ) {
        this.shouldApplyWindowLifecycleMutation = shouldApplyWindowLifecycleMutation
        this.shouldDeferWindowLifecycleMutationApply = shouldDeferWindowLifecycleMutationApply
        this.shouldReportWindowLifecycleMutationApplyBlocked = shouldReportWindowLifecycleMutationApplyBlocked
    }
}

func cjguiInternalBuildWindowLifecycleMutationApplyDraft(
    commitGate: CjguiInternalWindowLifecycleMutationCommitGateDraft
): CjguiInternalWindowLifecycleMutationApplyDraft {
    return CjguiInternalWindowLifecycleMutationApplyDraft(
        commitGate.canEnterWindowLifecycleMutationCommit,
        commitGate.shouldDeferWindowLifecycleMutationCommit,
        commitGate.shouldReportWindowLifecycleMutationCommitBlocked
    )
}

func cjguiInternalWindowLifecycleMutationApplyOpenSanity(): Bool {
    let handoff = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        true,
        false,
        false
    )
    let readiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        handoff
    )
    let plan = cjguiInternalBuildWindowLifecycleMutationPlanDraft(readiness)
    let gate = cjguiInternalBuildWindowLifecycleMutationCommitGateDraft(plan)
    let apply = cjguiInternalBuildWindowLifecycleMutationApplyDraft(gate)
    if (apply.shouldApplyWindowLifecycleMutation == false) {
        return false
    }
    if (apply.shouldDeferWindowLifecycleMutationApply) {
        return false
    }
    return apply.shouldReportWindowLifecycleMutationApplyBlocked == false
}

func cjguiInternalWindowLifecycleMutationApplyBlockedSanity(): Bool {
    let handoff = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        false,
        true,
        true
    )
    let readiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        handoff
    )
    let plan = cjguiInternalBuildWindowLifecycleMutationPlanDraft(readiness)
    let gate = cjguiInternalBuildWindowLifecycleMutationCommitGateDraft(plan)
    let apply = cjguiInternalBuildWindowLifecycleMutationApplyDraft(gate)
    if (apply.shouldApplyWindowLifecycleMutation) {
        return false
    }
    if (apply.shouldDeferWindowLifecycleMutationApply == false) {
        return false
    }
    return apply.shouldReportWindowLifecycleMutationApplyBlocked
}

struct CjguiInternalWindowLifecycleMutationResult {
    let previousState: CjguiInternalWindowLifecycleState
    let nextState: CjguiInternalWindowLifecycleState
    let didMutateWindowLifecycle: Bool
    let shouldDeferWindowLifecycleMutation: Bool
    let shouldReportWindowLifecycleMutationBlocked: Bool

    init(
        previousState: CjguiInternalWindowLifecycleState,
        nextState: CjguiInternalWindowLifecycleState,
        didMutateWindowLifecycle: Bool,
        shouldDeferWindowLifecycleMutation: Bool,
        shouldReportWindowLifecycleMutationBlocked: Bool
    ) {
        this.previousState = previousState
        this.nextState = nextState
        this.didMutateWindowLifecycle = didMutateWindowLifecycle
        this.shouldDeferWindowLifecycleMutation = shouldDeferWindowLifecycleMutation
        this.shouldReportWindowLifecycleMutationBlocked = shouldReportWindowLifecycleMutationBlocked
    }
}

func cjguiInternalApplyWindowLifecycleMutationDraft(
    state: CjguiInternalWindowLifecycleState,
    apply: CjguiInternalWindowLifecycleMutationApplyDraft
): CjguiInternalWindowLifecycleMutationResult {
    if (apply.shouldApplyWindowLifecycleMutation) {
        return CjguiInternalWindowLifecycleMutationResult(
            state,
            CjguiInternalWindowLifecycleState(
                true,
                state.hasObservedPlatformReady
            ),
            true,
            false,
            false
        )
    }

    return CjguiInternalWindowLifecycleMutationResult(
        state,
        state,
        false,
        apply.shouldDeferWindowLifecycleMutationApply,
        apply.shouldReportWindowLifecycleMutationApplyBlocked
    )
}

func cjguiInternalWindowLifecycleMutationOpenSanity(): Bool {
    let state = CjguiInternalWindowLifecycleState(false, true)
    let handoff = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        true,
        false,
        false
    )
    let readiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        handoff
    )
    let plan = cjguiInternalBuildWindowLifecycleMutationPlanDraft(readiness)
    let gate = cjguiInternalBuildWindowLifecycleMutationCommitGateDraft(plan)
    let apply = cjguiInternalBuildWindowLifecycleMutationApplyDraft(gate)
    let result = cjguiInternalApplyWindowLifecycleMutationDraft(state, apply)

    return result.didMutateWindowLifecycle &&
        result.shouldDeferWindowLifecycleMutation == false &&
        result.shouldReportWindowLifecycleMutationBlocked == false &&
        result.previousState.hasWindowState == state.hasWindowState &&
        result.previousState.hasObservedPlatformReady == state.hasObservedPlatformReady &&
        result.nextState.hasWindowState &&
        result.nextState.hasObservedPlatformReady == state.hasObservedPlatformReady
}

func cjguiInternalWindowLifecycleMutationBlockedSanity(): Bool {
    let state = CjguiInternalWindowLifecycleState(false, true)
    let handoff = cjguiInternalBuildWindowLifecycleWorkHandoffDraft(
        false,
        true,
        true
    )
    let readiness = cjguiInternalBuildWindowLifecycleMutationReadinessDraft(
        handoff
    )
    let plan = cjguiInternalBuildWindowLifecycleMutationPlanDraft(readiness)
    let gate = cjguiInternalBuildWindowLifecycleMutationCommitGateDraft(plan)
    let apply = cjguiInternalBuildWindowLifecycleMutationApplyDraft(gate)
    let result = cjguiInternalApplyWindowLifecycleMutationDraft(state, apply)

    return result.didMutateWindowLifecycle == false &&
        result.shouldDeferWindowLifecycleMutation &&
        result.shouldReportWindowLifecycleMutationBlocked &&
        result.previousState.hasWindowState == state.hasWindowState &&
        result.previousState.hasObservedPlatformReady == state.hasObservedPlatformReady &&
        result.nextState.hasWindowState == state.hasWindowState &&
        result.nextState.hasObservedPlatformReady == state.hasObservedPlatformReady
}

// 未来 window lifecycle owner:
// - 归属正式 runtime core window lifecycle 模块。
// - 拥有脱水 window lifecycle state。
// - 拥有 window-target lifecycle facts, 例如 create requested、close requested、
//   closing、destroyed、release completed 与 stale window message classification。
// - 不拥有 app-level run、quit、shutdown 或 queue acceptance policy。
// - 所有 platform object 工作都委托给 platform adapter。
// - 不得拥有 Renderer、Scene、Widget、Layout、Text、Input、IME、Accessibility、
//   semantic tree、Action Router 或 render scheduling state。

// 与 app lifecycle 的关系:
// - app lifecycle 是 app-level state、queue acceptance、shutdown policy 与未来
//   main-thread queue / drain policy 的概念 owner。
// - window lifecycle 在已接受的 window-targeted lifecycle request 到达 window 层后,
//   拥有 window-target state transitions。
// - request close 未来应先经过 app lifecycle queue acceptance 与 platform-adapter
//   main-thread drain, 然后再推进 window state。
// - 本文件不实现 app lifecycle、event loop、queue、drain、run、request quit 或
//   shutdown 行为。

// 与 platform adapter 的关系:
// - platform adapter 拥有 platform runloop callbacks、platform close events、
//   platform object creation 与 platform object release。
// - core window lifecycle 只接收脱水 lifecycle facts。
// - AppKit、Metal、Objective-C、NSWindow、NSView、CAMetalLayer、MTLDevice、
//   CAMetalDrawable、CGImageRef、Objective-C id、native handles 与 raw pointers
//   只属于 platform-adapter 内部关注点。
// - 这些名字在这里出现时, 只表示禁止泄漏的平台真相, 不表示 API、field、
//   parameter、return value 或 implementation。

// 未来槽位, 本文件不实现:
// - create window:
//   - 记录未来 creation request, 并绑定脱水 window state。
//   - platform adapter 未来可在 platform main thread 上创建 platform objects。
//   - core 只应观察 created / failed facts。
//   - 不得暴露 native handles, 不得创建 renderers、scenes、widgets,
//     也不得隐式启动 app run。
// - request close:
//   - 记录未来面向目标 window 的幂等 close request。
//   - 应把 auto-close、manual close 与未来 async close 收敛为同一条 close path。
//   - 不得直接释放 platform objects, 也不得绕过 app lifecycle queue / drain。
// - destroy / release:
//   - destroy 是未来脱水 window state 的 terminal transition 候选。
//   - release 是 platform cleanup 之后未来 platform-adapter completion fact。
//   - core 不得直接释放 AppKit、Metal 或 Objective-C objects。
// - stale message / destroyed window handling:
//   - destroyed window state 必须是 terminal。
//   - stale close 与 stale message 不得复活窗口。
//   - stale operations 必须被安全丢弃, 或由未来 structured errors 分类。
// - single-window first slice:
//   - 第一段真实实现可以保持 single-window, 以维持 lifecycle surface 狭窄。
//   - single-window 不是长期 runtime 限制。

// 句柄表 / generation 未来触发条件:
// - 本 first skeleton 不实现。
// - 在没有 public window handle、multi-window、target update、async UI message
//   targeting、destroyed-target identity reuse 或 cross-thread target validation 之前,
//   该方向必须保持关闭。
// - 一旦出现上述任一需求, 必须先开单独的 handle table / generation preflight
//   或 execution card, 再实现。

// 与 error strategy 的关系:
// - window lifecycle 未来可识别 duplicate close、close after destroyed、
//   destroy before create、platform create failure、platform release failure、
//   stale message、wrong thread、invalid target identity 或 future generation mismatch
//   等 error / diagnostics cases。
// - 具体 error types 属于未来 error strategy 工作。
// - smoke last_error 不得直接迁移到正式 runtime。
// - future errors 必须是 call-associated、structured、non-global 且 concurrency-safe。

// 停止线 (Stop-line):
// - 不实现真实 window create / close / destroy。
// - 不实现 handle table / generation。
// - 不做 multi-window、target update 或 async UI message targeting。
// - 不提供 public runtime API。
// - 不做 Renderer / Scene / Widget / Layout / DSL。
// - 不做 Dirty Rect、global tick、blind redraw 或 frame scheduler。
// - 不做 Text / Input / IME / Accessibility。
// - 不做 semantic tree / Action Router。
// - 不做 command-list hash、pixel diff、baseline 或 offscreen renderer。

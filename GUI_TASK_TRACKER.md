# 仓颉 GUI 项目任务账本

最后更新：2026-04-29

## 账本职责

本文件只保留：

- 当前阶段判断
- 当前 healthy stop-line
- 当前 active / future openings

不写长流水实现细节，不写聊天记录，不写过长设计推演。

## 当前阶段

当前项目处于：

> `P1 runtime 受限实现准备阶段`

当前已完成的基础不是代码，而是：

- 仓颉官方文档已本地化
- 仓颉桌面路线已完成初步判断
- GUI 项目思考框架已落地
- GUI 项目 docs-only governance gate 已落地

当前已经完成实验性 P0 bridge smoke、P1 bridge boundary cleanup、P1 main-thread UI message queue first slice、P1 automated GUI verification first slice、P1 frame metadata / render stats first slice、P1 screenshot / Metal readback verification preflight、P1 Metal readback feasibility first slice、P1 user-visible window verification evidence preflight、P1 user-visible window screenshot feasibility execution card、P1 user-visible window screenshot feasibility first slice、P1 user-visible window screenshot verification preflight、P1 user-visible window screenshot verification execution card、P1 user-visible window screenshot verification first slice、P1 screenshot verification artifact retention policy preflight、P1 screenshot artifact retention execution card、P1 screenshot artifact retention first slice、P1 pixel diff / frame hash prerequisites preflight、P1 frame hash feasibility execution card、P1 frame hash feasibility first slice、P1 frame hash evidence review / baseline policy preflight、P1 frame hash baseline-readiness diagnostics execution card、P1 frame hash baseline-readiness diagnostics first slice、P1 frame hash baseline owner / update policy preflight、P1 frame hash baseline owner / update policy execution card、P1 frame hash baseline owner / update policy first slice、P1 frame hash source normalization policy preflight、P1 frame hash source normalization policy execution card、P1 frame hash source normalization readiness diagnostics first slice、P1 frame hash source normalization evidence closure / next-boundary preflight、P1 frame hash bounds / crop semantics policy preflight、P1 frame hash bounds / crop semantics policy execution card、P1 frame hash bounds / crop semantics readiness diagnostics first slice、P1 frame hash verification evidence line closure / runtime pivot preflight、P1 smoke-to-runtime boundary preflight、P1 minimal app/window lifecycle runtime boundary preflight、P1 red-team risk intake / runtime guardrails preflight、P1 minimal app/window lifecycle runtime execution card、P1 minimal app/window lifecycle runtime skeleton first slice、P1 self-drawn platform reduction / IME / accessibility guardrails preflight、P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight、P1 app lifecycle surface boundary preflight、P1 app lifecycle surface execution card、P1 app lifecycle surface comment-only refinement first slice、P1 window lifecycle surface boundary preflight、P1 window lifecycle surface execution card、P1 window lifecycle surface comment-only refinement first slice、P1 platform adapter boundary preflight、P1 platform adapter boundary execution card、P1 platform adapter surface comment-only refinement first slice、P1 error strategy boundary preflight、P1 error strategy boundary execution card、P1 error strategy surface comment-only refinement first slice、P1 minimal runtime skeleton surface phase closure / compaction preflight、P1 runtime build/package boundary preflight、P1 runtime build/package boundary execution card、P1 runtime build/package metadata first slice、P1 first compilable runtime source boundary preflight、P1 first compilable runtime source execution card、P1 first compilable runtime source first slice、P1 first compilable runtime source closure / next implementation boundary preflight、P1 runtime visibility / internal symbol boundary preflight、P1 runtime internal symbol boundary execution card、P1 runtime internal symbol boundary first slice、P1 runtime internal symbol closure / first internal type boundary preflight、P1 first internal runtime type execution card、P1 first internal runtime type first slice、P1 first internal runtime type closure / error fact shape boundary preflight、P1 error fact shape execution card、P1 error fact shape first slice、P1 error fact shape closure / error taxonomy boundary preflight、P1 error taxonomy boundary execution card、P1 error taxonomy marker first slice、P1 error taxonomy marker closure / recoverability boundary preflight、P1 first internal app lifecycle state execution card、P1 first internal app lifecycle state first slice、P1 app lifecycle state shape execution card、P1 app lifecycle state shape first slice，以及 P1 app lifecycle transition boundary execution card。
2026-04-27 已完成 `CjguiInternalAppLifecycleState` 的最小脱水 Bool 字段 first slice；字段为 `isStateMachineActive: Bool = false`，只表达 state shape，不定义 state machine 或 runtime 行为。

最新补充：P1 app lifecycle transition marker first slice 已完成，新增 `CjguiInternalAppLifecycleTransitionMarker`，当前 next opening 转向 `P1 app lifecycle transition marker closure / first internal no-op transition decision`。

最新补充：P1 app lifecycle no-op transition execution card 已完成，当前 next opening 转向 `P1 app lifecycle no-op transition first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 app lifecycle no-op transition first slice 已完成，新增 `cjguiInternalNoOpAppLifecycleTransition`，closure review 已封账；当前 next opening 转向 `P1 first real app lifecycle transition boundary decision`。

最新补充：P1 app lifecycle phase marker execution card 已完成，当前 next opening 转向 `P1 app lifecycle phase marker first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 app lifecycle phase marker first slice 已完成，新增 `hasLifecyclePhase: Bool = false`，closure review 已封账；当前 next opening 转向 `P1 app lifecycle phase marker closure / first real transition readiness decision`。

最新补充：P1 app lifecycle first state-changing transition execution card 已完成，当前 next opening 转向 `P1 app lifecycle first state-changing transition first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 app lifecycle first state-changing transition first slice 已 fail closed；当前 state 只生成无参构造函数，无法在“只新增一个 transition function”的授权内构造 `hasLifecyclePhase = true` 的新 state。未修改 runtime，build / smoke guard 通过；当前 next opening 转向 `P1 app lifecycle state construction authority decision`。

最新补充：P1 app lifecycle state construction execution card 已完成；下一刀只允许给 `CjguiInternalAppLifecycleState` 打开最小默认 internal 构造 shape，推荐显式 `init` 只覆盖既有两个 Bool 字段且无副作用。当前 next opening 转向 `P1 app lifecycle state construction first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 app lifecycle state construction first slice 已 fail closed；显式 `init` 与当前两个默认初始化 `let` 字段冲突，仓颉编译器报 `cannot assign to immutable value`。临时 runtime 修改已撤回，build / smoke guard 通过；当前 next opening 转向 `P1 app lifecycle state construction fail-closed / constructor shape decision`。

最新补充：P1 app lifecycle state initialization shape execution card 已完成；下一刀只允许把 `CjguiInternalAppLifecycleState` 从字段默认值初始化推进到主构造或等价构造期初始化 shape，保留两个 immutable Bool facts 并允许构造不同 state。当前 next opening 转向 `P1 app lifecycle state initialization shape first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 app lifecycle state initialization shape first slice 已完成；`CjguiInternalAppLifecycleState` 改为默认 internal 构造期初始化 shape，两个 facts 仍为 `let`，无参构造保持 inactive / no lifecycle phase，带参构造允许构造不同 internal state。build / smoke guard 通过；当前 next opening 转向 `P1 app lifecycle state initialization shape closure / retry first state-changing transition`。

最新补充：P1 app lifecycle first state-changing transition retry first slice 已完成；新增默认 internal `cjguiInternalAppLifecyclePhaseMarkerTransition`，只把 returned state 的 `hasLifecyclePhase` 推进为 `true`，并保留输入 `isStateMachineActive`。build / smoke guard 通过；当前 next opening 转向 `P1 app lifecycle first state-changing transition closure / app lifecycle mini-slice compaction`。

最新补充：P1 app lifecycle mini-slice compaction 已完成；已将 app lifecycle 从 state marker、shape、construction shape、no-op transition 到 first state-changing transition 的事实压缩到 [2026-04-27-p1-app-lifecycle-mini-slice-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-mini-slice-compaction.md)。当前 next opening 转向 `P1 app lifecycle first real phase taxonomy decision`，不自动开启实现。

最新补充：P1 app lifecycle phase taxonomy execution card 已完成；下一刀最多只能新增一个默认 internal 空 phase taxonomy marker / placeholder type，不定义真实 taxonomy、enum 或 state machine。当前 next opening 转向 `P1 app lifecycle phase taxonomy marker first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 app lifecycle phase taxonomy marker first slice 已完成；新增默认 internal 空 `CjguiInternalAppLifecyclePhaseTaxonomyMarker`，只表达 phase taxonomy boundary exists but taxonomy is not yet defined。build / smoke guard 通过；当前 next opening 转向 `P1 app lifecycle phase taxonomy marker closure / window lifecycle pivot decision`。

最新补充：P1 first internal window lifecycle state execution card 已完成；已从 app lifecycle mini-slice pivot 到 window lifecycle，下一刀最多只能在 `runtime/cjgui/src/window_lifecycle.cj` 新增默认 internal 空 window lifecycle state marker / placeholder type。当前 next opening 转向 `P1 first internal window lifecycle state first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 first internal window lifecycle state first slice 已完成；新增默认 internal 空 `CjguiInternalWindowLifecycleState`，只表达 window lifecycle state boundary exists but window state machine is not yet defined。build / smoke guard 通过；当前 next opening 转向 `P1 first internal window lifecycle state closure / window state shape decision`。

最新补充：P1 window lifecycle state shape execution card 已完成；下一刀最多只能给 `CjguiInternalWindowLifecycleState` 新增一个不可变 Bool 字段，推荐语义等价于 `hasWindowState: Bool = false`，只表达 window state boundary exists，但 window state taxonomy 尚未定义。当前 next opening 转向 `P1 window lifecycle state shape first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 window lifecycle state shape first slice 已完成；`CjguiInternalWindowLifecycleState` 新增唯一不可变 Bool 字段 `hasWindowState: Bool = false`，只表达 window state boundary exists，但 window state taxonomy 尚未定义。build / smoke guard 通过；当前 next opening 转向 `P1 window lifecycle state shape closure / combined construction transition slice decision`。

最新补充：P1 window lifecycle construction + no-op transition execution card 已完成；下一刀允许同时修改 `CjguiInternalWindowLifecycleState` 的 initialization shape，并新增默认 internal no-op window lifecycle transition function。当前 next opening 转向 `P1 window lifecycle construction + no-op transition first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 window lifecycle construction + no-op transition first slice 已完成；`CjguiInternalWindowLifecycleState` 改为默认 internal explicit init pair，仍只保留 immutable `hasWindowState`，并新增默认 internal `cjguiInternalNoOpWindowLifecycleTransition` 原样返回输入 state。临时探针、runtime build、smoke guard 通过；当前 next opening 转向 `P1 window lifecycle construction + no-op transition closure / first state-changing transition decision`。

最新补充：P1 window lifecycle first state-changing transition execution card 已完成；下一刀最多只能新增一个默认 internal state-changing transition function，唯一允许的 state change 是返回一个 `hasWindowState = true` 的 `CjguiInternalWindowLifecycleState`。当前 next opening 转向 `P1 window lifecycle first state-changing transition first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 window lifecycle first state-changing transition first slice 已完成；新增默认 internal `cjguiInternalWindowLifecycleStateMarkerTransition`，只返回 `hasWindowState=true` 的 new state，不定义 window taxonomy、handle、create / close / destroy / release。build / smoke guard 通过；当前 next opening 转向 `P1 window lifecycle first state-changing transition closure / lifecycle parity compaction`。

最新补充：P1 lifecycle parity compaction 已完成；已将 app/window lifecycle 两条 internal mini-slice 的对称能力压缩到 [2026-04-27-p1-lifecycle-parity-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-lifecycle-parity-compaction.md)。当前 next opening 转向 `P1 lifecycle internal mini-runtime closure / next functional slice decision`，不自动开启实现。

最新补充：P1 platform adapter fact ingestion execution card 已完成；已从 lifecycle mini-runtime pivot 到 platform adapter fact ingestion，下一刀最多只能在 `runtime/cjgui/src/platform_adapter.cj` 新增一个默认 internal 空 platform adapter fact marker / placeholder type。当前 next opening 转向 `P1 platform adapter fact marker first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 platform adapter fact marker first slice 已完成；新增默认 internal 空 `CjguiInternalPlatformAdapterFact`，只表达 platform adapter can provide dehydrated facts, but fact shape is not yet defined。build / smoke guard 通过；当前 next opening 转向 `P1 platform adapter fact marker closure / fact shape decision`。

最新补充：P1 platform adapter fact shape + construction + no-op ingestion execution card 已完成；这是 W1 internal concept slice，不是 one-symbol slice。下一刀最多只能围绕 `CjguiInternalPlatformAdapterFact` 增加一个 immutable Bool fact shape、构造期初始化能力和一个默认 internal no-op fact ingestion function。当前 next opening 转向 `P1 platform adapter fact shape + construction + no-op ingestion first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 platform adapter fact shape + construction + no-op ingestion first slice 已完成；`CjguiInternalPlatformAdapterFact` 新增唯一 immutable Bool fact `hasPlatformFact`、默认 internal explicit init pair，以及默认 internal `cjguiInternalNoOpPlatformAdapterFactIngestion` 原样返回输入 fact。临时探针、runtime build、smoke guard 通过；当前 next opening 转向 `P1 platform adapter fact shape + construction + no-op ingestion closure / next functional slice decision`。

最新补充：P1 runtime internal concept compaction 已完成；已将 app lifecycle、window lifecycle、platform adapter 三条 internal code slice 的当前能力压缩到 [2026-04-27-p1-runtime-internal-concept-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-runtime-internal-concept-compaction.md)。当前 next opening 转向 `P1 platform fact to lifecycle ingestion boundary decision`，不自动开启实现。

最新补充：P1 platform fact to lifecycle ingestion execution card 已完成；这是 W2 light internal concept slice，用 [2026-04-27-p1-runtime-internal-concept-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-runtime-internal-concept-compaction.md) 作为 authority，授权下一轮实现 platform adapter dehydrated fact -> app/window lifecycle internal marker state 的最小 ingestion / projection。当前 next opening 转向 `P1 platform fact to lifecycle ingestion first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 platform fact to lifecycle ingestion first slice 已完成；新增默认 internal `cjguiInternalProjectPlatformFactToAppLifecycleState` 与 `cjguiInternalProjectPlatformFactToWindowLifecycleState`，让 `hasPlatformFact=true` 的脱水 platform fact 可以推进 app/window internal marker state。runtime build 与 smoke guard 通过；当前 next opening 转向 `P1 platform fact to lifecycle ingestion closure / next functional slice decision`。

最新补充：P1 internal lifecycle coordination execution card 已完成；这是 W2 internal concept slice，授权下一轮把已有 platform fact、app lifecycle state、window lifecycle state 串成最小 internal coordination 入口。当前 next opening 转向 `P1 internal lifecycle coordination first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 internal lifecycle coordination first slice 已完成；新增默认 internal `CjguiInternalLifecycleCoordinationResult` 与 `cjguiInternalCoordinateLifecycleFromPlatformFact`，用既有 platform fact projection functions 返回协调后的 app/window marker state。runtime build 与 smoke guard 通过；当前 next opening 转向 `P1 internal lifecycle coordination closure / next functional slice decision`。

最新补充：P1 internal lifecycle coordination sanity execution card 已完成；这是 W1 light internal concept slice，授权下一轮新增一个默认 internal sanity function，用最小 platform fact、默认 app/window state 调用现有 coordination 链条并返回 `CjguiInternalLifecycleCoordinationResult`。当前 next opening 转向 `P1 internal lifecycle coordination sanity first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 internal lifecycle coordination sanity first slice 已完成；先做了窄口恢复修正，把 `cjguiInternalNo0pAppLifecycleTransition`、`cjguiInternalNo0pWindowLifecycleTransition`、`cjguiInternalNo0pPlatformAdapterFactIngestion` 统一修正为 `NoOp` 命名，并同步更新 `runtime/cjgui/README.md`。随后新增默认 internal `cjguiInternalLifecycleCoordinationSanity`，它构造 `CjguiInternalPlatformAdapterFact(true)`、默认 app/window state，并调用 `cjguiInternalCoordinateLifecycleFromPlatformFact` 返回 `CjguiInternalLifecycleCoordinationResult`。runtime build、smoke guard 与 `git diff --check` 通过；当前 next opening 转向 `P1 internal lifecycle coordination sanity closure / next functional slice decision`。

最新补充：P1 platform readiness fact semantics execution card 已完成；这是 W2 internal concept slice，授权下一轮把 `CjguiInternalPlatformAdapterFact` 的泛化 `hasPlatformFact` marker 语义推进为更明确的 internal platform readiness fact 语义，仍保持 internal-only、脱水、无平台对象、无 public runtime API / public C ABI。当前 next opening 转向 `P1 platform readiness fact semantics first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 platform readiness fact semantics first slice 已完成；`CjguiInternalPlatformAdapterFact` 的核心 Bool fact 已从 `hasPlatformFact` 窄口替换为 `isPlatformReady`，并同步更新 constructor、no-op ingestion 语义说明、projection、coordination 与 sanity 调用。未保留兼容字段，避免 internal skeleton 出现双字段语义膨胀。runtime build、smoke guard 与 `git diff --check` 通过；当前 next opening 转向 `P1 platform readiness fact semantics closure / next functional slice decision`。

最新补充：P1 app lifecycle platform readiness state execution card 已完成；这是 W2 internal concept slice，授权下一轮让 `CjguiInternalAppLifecycleState` 承载 internal `hasObservedPlatformReady` 或等价 Bool fact，并让现有 platform readiness -> app lifecycle projection 在 `isPlatformReady=true` 时推进该 app state。当前 next opening 转向 `P1 app lifecycle platform readiness state first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 app lifecycle platform readiness state first slice 已完成；`CjguiInternalAppLifecycleState` 新增 immutable `hasObservedPlatformReady: Bool`，默认构造为 `false`，带参构造同步扩展。`cjguiInternalAppLifecyclePhaseMarkerTransition` 保留该 fact，`cjguiInternalProjectPlatformFactToAppLifecycleState` 在 `isPlatformReady=true` 时将其推进为 `true`。runtime build、smoke guard 与 `git diff --check` 通过；当前 next opening 转向 `P1 app lifecycle platform readiness state closure / next functional slice decision`。

最新补充：P1 window lifecycle platform readiness state execution card 已完成；这是 W2 internal concept slice，授权下一轮让 `CjguiInternalWindowLifecycleState` 承载 internal `hasObservedPlatformReady` 或等价 Bool fact，并让现有 platform readiness -> window lifecycle projection 在 `isPlatformReady=true` 时推进该 window state。当前 next opening 转向 `P1 window lifecycle platform readiness state first slice`；下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最新补充：P1 window lifecycle platform readiness state first slice 已完成；`CjguiInternalWindowLifecycleState` 新增 immutable `hasObservedPlatformReady: Bool`，默认构造为 `false`，带参构造同步扩展。`cjguiInternalWindowLifecycleStateMarkerTransition` 保留该 fact，`cjguiInternalProjectPlatformFactToWindowLifecycleState` 在 `isPlatformReady=true` 时将其推进为 `true`。runtime build、smoke guard 与 `git diff --check` 通过；当前 next opening 转向 `P1 window lifecycle platform readiness state closure / next functional slice decision`。

最新补充：治理节奏修正 + P1 readiness state helper bundle execution card 已完成；低风险 internal-only runtime work 现在允许一张 bundled execution card 授权 2-3 个连续小切片，每个 slice 仍独立跑 build / smoke / `git diff --check`，slice 后可先只写 tracker 简短日志，bundle 完成后再写 mini-compaction / bundled closure。当前 next opening 转向 `P1 readiness helper bundle slice A`；下一轮默认进入 bundle 内 bounded implementation，不再为 Slice A 单独创建 execution card。

最新补充：P1 readiness helper bundle slice A 已完成；新增默认 internal `cjguiInternalAppLifecycleHasObservedPlatformReady` 与 `cjguiInternalWindowLifecycleHasObservedPlatformReady`，分别只读取 app/window state 的 `hasObservedPlatformReady` Bool fact，不改变 state shape、constructor shape、projection 或 coordination behavior。`cjpm build --target-dir /tmp/cjgui-readiness-helper-bundle-slice-a-target --skip-script`、smoke guard 与 `git diff --check` 通过；未新增独立 closure review。当前 next opening 转向 `P1 readiness helper bundle slice B`。

最新补充：P1 readiness helper bundle slice B 已完成；新增默认 internal `cjguiInternalLifecycleCoordinationSanityObservedPlatformReady`，复用 `cjguiInternalLifecycleCoordinationSanity()` 并通过 app/window readiness predicate helpers 确认两侧都已 observed platform ready，返回 `Bool`。`cjpm build --target-dir /tmp/cjgui-readiness-helper-bundle-slice-b-target --skip-script`、smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-readiness-state-helper-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-state-helper-bundle-closure-review.md)。当前 next opening 转向 `P1 readiness helper bundle closure / next functional slice decision`。

最新补充：P1 readiness coordination negative-path bundle execution card 已完成；这是 bundled execution card，授权后续两个 internal-only slices：Slice A 新增 negative platform readiness fact sanity helper，确认 `isPlatformReady=false` 不会推进默认 app/window observed platform ready；Slice B 新增 readiness sanity parity helper，同时检查 positive 与 negative sanity。当前 next opening 转向 `P1 readiness coordination negative-path bundle slice A`；下一轮默认进入 bundle 内 bounded implementation，不再为 Slice A 单独创建 execution card。

最新补充：P1 readiness coordination negative-path bundle slice A 已完成；新增默认 internal `cjguiInternalLifecycleCoordinationSanityNotObservedPlatformReady`，构造 `CjguiInternalPlatformAdapterFact(false)` 与默认 app/window state，调用 `cjguiInternalCoordinateLifecycleFromPlatformFact`，并通过 app/window readiness predicate helpers 确认两侧都没有 observed platform ready。`cjpm build --target-dir /tmp/cjgui-readiness-negative-path-bundle-slice-a-target --skip-script`、smoke guard 与 `git diff --check` 通过；未新增独立 closure review。当前 next opening 转向 `P1 readiness coordination negative-path bundle slice B`。

最新补充：P1 readiness coordination negative-path bundle slice B 已完成；新增默认 internal `cjguiInternalLifecycleCoordinationReadinessSanityParity`，同时调用 positive sanity helper 与 negative sanity helper，只有两者都为 true 时返回 true。`cjpm build --target-dir /tmp/cjgui-readiness-negative-path-bundle-slice-b-target --skip-script`、smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-readiness-coordination-negative-path-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-coordination-negative-path-bundle-closure-review.md)。当前 next opening 转向 `P1 readiness coordination negative-path bundle closure / next functional slice decision`。

最新补充：P1 internal runtime readiness aggregate bundle execution card 已完成；这是 bundled execution card，授权后续两个 internal-only slices：Slice A 新增默认 internal runtime readiness aggregate type，聚合 app state、window state 与 readiness parity Bool；Slice B 新增 aggregate builder，复用 coordination sanity 与 readiness parity sanity 返回 aggregate。owner 选择为 `runtime/cjgui/src/platform_adapter.cj`，因为 aggregate 聚合的是 platform readiness coordination summary，不拥有 app/window state truth。当前 next opening 转向 `P1 internal runtime readiness aggregate bundle slice A`；下一轮默认进入 bundle 内 bounded implementation，不再为 Slice A 单独创建 execution card。

最新补充：P1 internal runtime readiness aggregate bundle slice A 已完成；新增默认 internal `CjguiInternalRuntimeReadinessAggregate`，聚合 `appState: CjguiInternalAppLifecycleState`、`windowState: CjguiInternalWindowLifecycleState` 与 `isReadinessParityClean: Bool`，只作为 readiness coordination summary，不拥有 app/window state truth。`cjpm build --target-dir /tmp/cjgui-readiness-aggregate-bundle-slice-a-target --skip-script`、smoke guard 与 `git diff --check` 通过；未新增独立 closure review。当前 next opening 转向 `P1 internal runtime readiness aggregate bundle slice B`。

最新补充：P1 internal runtime readiness aggregate bundle slice B 已完成；新增默认 internal `cjguiInternalBuildRuntimeReadinessAggregate()`，复用 `cjguiInternalLifecycleCoordinationSanity()` 得到 app/window state，并复用 `cjguiInternalLifecycleCoordinationReadinessSanityParity()` 得到 readiness parity Bool，返回 `CjguiInternalRuntimeReadinessAggregate`。`cjpm build --target-dir /tmp/cjgui-readiness-aggregate-bundle-slice-b-target --skip-script`、smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-readiness-aggregate-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-readiness-aggregate-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime readiness aggregate bundle closure / next functional slice decision`。

最新补充：P1 internal runtime bootstrap draft bundle execution card 已完成；这是 bundled execution card，授权后续两个 internal-only slices：Slice A 新增默认 internal runtime bootstrap snapshot type，聚合 readiness aggregate 与 `isBootstrapReady` Bool；Slice B 新增 bootstrap snapshot builder，复用 `cjguiInternalBuildRuntimeReadinessAggregate()` 并根据 `readiness.isReadinessParityClean` 决定 bootstrap readiness。owner 选择为 `runtime/cjgui/src/platform_adapter.cj`，因为 bootstrap draft 只消费 readiness aggregate summary，不拥有 app/window state truth，也不实现 app run / event loop / queue / drain / window create。当前 next opening 转向 `P1 internal runtime bootstrap draft bundle slice A`；下一轮默认进入 bundle 内 bounded implementation，不再为 Slice A 单独创建 execution card。

最新补充：P1 internal runtime bootstrap draft bundle slice A 已完成；新增默认 internal `CjguiInternalRuntimeBootstrapSnapshot`，聚合 `readiness: CjguiInternalRuntimeReadinessAggregate` 与 `isBootstrapReady: Bool`，只作为 internal bootstrap draft snapshot，不实现 app run、event loop、queue / drain、window create 或 shutdown。`cjpm build --target-dir /tmp/cjgui-bootstrap-draft-bundle-slice-a-target --skip-script`、smoke guard 与 `git diff --check` 通过；未新增独立 closure review。当前 next opening 转向 `P1 internal runtime bootstrap draft bundle slice B`。

最新补充：P1 internal runtime bootstrap draft bundle slice B 已完成；新增默认 internal `cjguiInternalBuildRuntimeBootstrapSnapshot()`，复用 `cjguiInternalBuildRuntimeReadinessAggregate()`，并用 `readiness.isReadinessParityClean` 作为 `isBootstrapReady`，返回 `CjguiInternalRuntimeBootstrapSnapshot`。`cjpm build --target-dir /tmp/cjgui-bootstrap-draft-bundle-slice-b-target --skip-script`、smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-bootstrap-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-bootstrap-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime bootstrap draft bundle closure / next functional slice decision`。

最新补充：P1 internal runtime bootstrap owner cleanup bundle execution card 已完成；这是 bundled execution card，授权后续两个 internal-only slices：Slice A 新建 `runtime/cjgui/src/runtime_bootstrap.cj` 并迁移 runtime readiness aggregate / bootstrap snapshot owner symbols；Slice B 做 owner boundary cleanup / imports if needed，并在 bundle 完成后写 bundled closure。owner cleanup 策略是让 `platform_adapter.cj` 回到 platform fact、projection、coordination sanity / readiness sanity 的 adapter-facing summary 边界，把 runtime bootstrap summary 聚合物迁到 `runtime_bootstrap.cj`。当前 next opening 转向 `P1 internal runtime bootstrap owner cleanup bundle slice A`；下一轮默认进入 bundle 内 bounded implementation，不再为 Slice A 单独创建 execution card。

最新补充：P1 internal runtime bootstrap owner cleanup bundle slice A 已完成；新增 `runtime/cjgui/src/runtime_bootstrap.cj`，并从 `platform_adapter.cj` 迁移 `CjguiInternalRuntimeReadinessAggregate`、`cjguiInternalBuildRuntimeReadinessAggregate`、`CjguiInternalRuntimeBootstrapSnapshot`、`cjguiInternalBuildRuntimeBootstrapSnapshot`。envsetup 后 `cjpm build --target-dir /tmp/cjgui-bootstrap-owner-cleanup-bundle-slice-a-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；未新增独立 closure review。当前 next opening 转向 `P1 internal runtime bootstrap owner cleanup bundle slice B`。

最新补充：P1 internal runtime bootstrap owner cleanup bundle slice B 已完成；只做注释级 owner cleanup，确认 `platform_adapter.cj` 保留 platform fact / projection / coordination / readiness sanity helpers，`runtime_bootstrap.cj` 拥有 readiness aggregate / bootstrap snapshot / bootstrap builder。envsetup 后 `cjpm build --target-dir /tmp/cjgui-bootstrap-owner-cleanup-bundle-slice-b-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-bootstrap-owner-cleanup-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-bootstrap-owner-cleanup-bundle-closure-review.md)。当前 next opening 转向 `P1 runtime bootstrap owner cleanup closure / next larger runtime slice decision`。

最新补充：P1 internal runtime root state bundle execution card 已完成；这是 bundled execution card，授权后续两个 internal-only slices：Slice A 新建 `runtime/cjgui/src/runtime_state.cj` 并新增默认 internal runtime root state type；Slice B 新增 root state builder，复用 `cjguiInternalBuildRuntimeBootstrapSnapshot()` 并用 `bootstrap.isBootstrapReady` 作为 `isRuntimeReady`。owner 选择为 `runtime_state.cj`，因为 root state 是 bootstrap 之后的 runtime-level summary，不属于 platform adapter 或 runtime bootstrap owner。当前 next opening 转向 `P1 internal runtime root state bundle slice A`；下一轮默认进入 bundle 内 bounded implementation，不再为 Slice A 单独创建 execution card。

最新补充：P1 internal runtime root state bundle slice A 已完成；新增 `runtime/cjgui/src/runtime_state.cj` 与默认 internal `CjguiInternalRuntimeRootState`，聚合 `bootstrap: CjguiInternalRuntimeBootstrapSnapshot` 和 `isRuntimeReady: Bool`，只作为 runtime root state summary，不实现 app run、event loop、queue / drain、window create 或 shutdown。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-root-state-bundle-slice-a-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；未新增独立 closure review。当前 next opening 转向 `P1 internal runtime root state bundle slice B`。

最新补充：P1 internal runtime root state bundle slice B 已完成；新增默认 internal `cjguiInternalBuildRuntimeRootState()`，复用 `cjguiInternalBuildRuntimeBootstrapSnapshot()`，并用 `bootstrap.isBootstrapReady` 作为 `isRuntimeReady`，返回 `CjguiInternalRuntimeRootState`。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-root-state-bundle-slice-b-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-root-state-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-state-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime root state bundle closure / next functional slice decision`。

最新补充：P1 internal runtime root sanity bundle execution card 已完成；这是 bundled execution card，授权后续两个 internal-only slices：Slice A 在 `runtime_state.cj` 新增默认 internal root ready sanity helper，调用 `cjguiInternalBuildRuntimeRootState()` 并返回 `root.isRuntimeReady`；Slice B 默认只做 bundle closure / mini-compaction，记录 root state 已有 ready sanity 且不继续堆 helper 链。当前 next opening 转向 `P1 internal runtime root sanity bundle slice A`；下一轮默认进入 bundle 内 bounded implementation，不再为 Slice A 单独创建 execution card。

最新补充：P1 internal runtime root sanity bundle slice A 已完成；新增默认 internal `cjguiInternalRuntimeRootStateReadySanity()`，调用 `cjguiInternalBuildRuntimeRootState()` 并返回 `root.isRuntimeReady`，只证明 root state builder 的 ready path，不改变 root state shape、bootstrap builder behavior、projection 或 coordination behavior。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-root-sanity-bundle-slice-a-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；未新增独立 closure review。当前 next opening 转向 `P1 internal runtime root sanity bundle slice B`。

最新补充：P1 internal runtime root sanity bundle slice B 已完成；本轮未新增 helper function、未新增 runtime behavior，只新增 bundled closure [2026-04-28-p1-internal-runtime-root-sanity-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-sanity-bundle-closure-review.md)，确认 `cjguiInternalRuntimeRootStateReadySanity(): Bool` 已足够表达当前最小 ready path，并明确停止 root helper 链。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-root-sanity-bundle-slice-b-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过。当前 next opening 转向 `P1 first internal runtime step bundle decision`。

最新补充：P1 first internal runtime step bundle execution card 已完成；这是 bundled execution card，授权后续两个 internal-only slices：Slice A 在 `runtime_state.cj` 新增默认 internal `CjguiInternalRuntimeStepResult`，聚合 `state: CjguiInternalRuntimeRootState` 与 `didAdvance: Bool`；Slice B 新增默认 internal `cjguiInternalRuntimeStep(state: CjguiInternalRuntimeRootState): CjguiInternalRuntimeStepResult`，只根据 `state.isRuntimeReady` 返回 didAdvance Bool 与原 state。当前 next opening 转向 `P1 first internal runtime step bundle slice A`；下一轮默认进入 bundle 内 bounded implementation，不再为 Slice A 单独创建 execution card。

最新补充：P1 first internal runtime step bundle slice A 已完成；新增默认 internal `CjguiInternalRuntimeStepResult`，聚合 `state: CjguiInternalRuntimeRootState` 与 `didAdvance: Bool`，只作为脱水 step result summary，不实现 event loop、queue / drain、app run 或 window create。envsetup 后 `cjpm build --target-dir /tmp/cjgui-first-internal-runtime-step-bundle-slice-a-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；未新增独立 closure review。当前 next opening 转向 `P1 first internal runtime step bundle slice B`。

最新补充：P1 first internal runtime step bundle slice B 已完成；新增默认 internal `cjguiInternalRuntimeStep(state: CjguiInternalRuntimeRootState): CjguiInternalRuntimeStepResult`，原样保留输入 state，并将 `state.isRuntimeReady` 映射为 `didAdvance`，返回 `CjguiInternalRuntimeStepResult`。envsetup 后 `cjpm build --target-dir /tmp/cjgui-first-internal-runtime-step-bundle-slice-b-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-first-internal-runtime-step-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-first-internal-runtime-step-bundle-closure-review.md)。当前 next opening 转向 `P1 first internal runtime step bundle closure / next functional slice decision`。

最新补充：P1 internal runtime step sanity bundle execution card 已完成；这是 bundled execution card，授权后续两个 internal-only slices：Slice A 在 `runtime_state.cj` 新增默认 internal runtime step ready sanity helper，调用 `cjguiInternalBuildRuntimeRootState()` 与 `cjguiInternalRuntimeStep(root)` 并返回 `step.didAdvance`；Slice B 默认只做 bundle closure / mini-compaction，记录 step sanity 已足够且不继续堆 helper 链。当前 next opening 转向 `P1 internal runtime step sanity bundle slice A`；下一轮默认进入 bundle 内 bounded implementation，不再为 Slice A 单独创建 execution card。

最新补充：P1 internal runtime step sanity bundle slice A 已完成；新增默认 internal `cjguiInternalRuntimeStepReadySanity()`，调用 `cjguiInternalBuildRuntimeRootState()`、再调用 `cjguiInternalRuntimeStep(root)`，并返回 `step.didAdvance`，只验证 ready path 会推进 `didAdvance=true`。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-step-sanity-bundle-slice-a-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；未新增独立 closure review。当前 next opening 转向 `P1 internal runtime step sanity bundle slice B`。

最新补充：P1 internal runtime step sanity bundle slice B 已完成；本轮未新增 helper function、未新增 runtime behavior，只新增 bundled closure [2026-04-28-p1-internal-runtime-step-sanity-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-sanity-bundle-closure-review.md)，确认 `cjguiInternalRuntimeStepReadySanity(): Bool` 已足够覆盖当前最小 step ready path，并明确停止 helper-by-helper 链。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-step-sanity-bundle-slice-b-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过。当前 next opening 转向 `P1 internal runtime step input / policy bundle decision`；下一张 bundle 应提升授权粒度，进入完整 internal behavior concept，不再继续单 helper 粒度。

最新补充：P1 internal runtime step input policy bundle execution card 已完成；这是 W2 internal behavior bundle，授权下一轮一次完成 internal step input、policy、decision、default builders、decision function、step-with-input-policy、少量直接相关 sanity / parity 和 bundled closure。当前 next opening 转向 `P1 internal runtime step input policy bundle implementation`；下一轮默认进入 bounded implementation，不再拆成多个 one-helper slices。

最新补充：P1 internal runtime step input policy bundle implementation 已完成；一次新增 `CjguiInternalRuntimeStepInput`、`CjguiInternalRuntimeStepPolicy`、`CjguiInternalRuntimeStepDecision`、default input / policy builders、`cjguiInternalDecideRuntimeStep`、`cjguiInternalRuntimeStepWithInput` 与三条直接相关 sanity helpers。既有 `cjguiInternalRuntimeStep(state)` 行为未改变，`hasExternalWork` 仍只是脱水 marker，不代表真实 queue / event loop / platform callback。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-step-input-policy-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-step-input-policy-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-input-policy-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime step input policy closure / next runtime behavior bundle decision`。

最新补充：P1 internal runtime step outcome bundle execution card 已完成；这是 W2 internal behavior bundle，授权下一轮一次扩展 `CjguiInternalRuntimeStepResult` 的 internal-only outcome shape，并同步更新 simple step、step-with-input-policy、相关 sanity、README、tracker、plans README 与 bundled closure。当前 next opening 转向 `P1 internal runtime step outcome bundle implementation`；下一轮默认进入 bounded implementation，不再拆成 one-helper slices。

最新补充：P1 internal runtime step outcome bundle implementation 已完成；`CjguiInternalRuntimeStepResult` 新增 `isBlocked`、`isBlockedByRuntimeNotReady`、`isBlockedByInput` 三个 internal-only outcome fields，并更新 `cjguiInternalRuntimeStep` 与 `cjguiInternalRuntimeStepWithInput` 填充 blocked outcome。新增 `cjguiInternalRuntimeStepReadyOutcomeSanity` 与 `cjguiInternalRuntimeStepBlockedOutcomeSanity` 两个直接相关 sanity helpers。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-step-outcome-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-step-outcome-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-outcome-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime step outcome closure / next runtime behavior bundle decision`。

最新补充：P1 internal runtime cycle request bundle implementation 已完成；新增默认 internal `CjguiInternalRuntimeCycleRequest` 与 `CjguiInternalRuntimeCycleResult`，以及 `cjguiInternalDefaultRuntimeCycleRequest()`、`cjguiInternalExecuteRuntimeCycle(request)` 和三条直接相关 sanity helpers。该 cycle 只组合 root state、step input、step policy、decision 与 step result，不代表 event loop、queue / drain、platform callback 或 app run。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-cycle-request-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-cycle-request-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-cycle-request-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime cycle request bundle closure / next runtime behavior bundle decision`。

最新补充：P1 internal runtime cycle state progress bundle implementation 已完成；`CjguiInternalRuntimeCycleResult` 新增 `didProduceProgress: Bool`，由 `cjguiInternalExecuteRuntimeCycle(request)` 使用 `step.didAdvance` 派生。已有 cycle sanity helpers 已适配 progress marker，并新增 `cjguiInternalRuntimeCycleProgressReadySanity()` 与 `cjguiInternalRuntimeCycleProgressBlockedSanity()`。该 progress 只是 internal cycle outcome marker，不代表 frame/render/layout progress、event loop tick、queue drain、platform callback 或 app run。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-cycle-state-progress-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-cycle-state-progress-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-cycle-state-progress-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime cycle state progress bundle closure / next runtime behavior bundle decision`。

最新补充：P1 internal runtime command draft bundle implementation 已完成；新增默认 internal `CjguiInternalRuntimeCommandDraft`，以及 `cjguiInternalBuildRuntimeCommandDraft(cycle)`、`cjguiInternalExecuteRuntimeCycleDraftCommand(request)` 和三条直接相关 sanity helpers。command draft 只从 cycle result 派生 internal runtime intent summary：progress 时 request-next-cycle，blocked 时 report-blocked；它不是 public command API、renderer command list、event loop task、queue / drain item、platform callback 或 AppKit / Metal command。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-command-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-command-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-command-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime command draft bundle closure / next runtime behavior bundle decision`。

最新补充：P1 internal runtime command pipeline subsystem draft implementation 已完成；新增默认 internal `CjguiInternalRuntimeCommandPipelineRequest` 与 `CjguiInternalRuntimeCommandPipelineResult`，以及 `cjguiInternalDefaultRuntimeCommandPipelineRequest()`、`cjguiInternalExecuteRuntimeCommandPipeline(request)`、`cjguiInternalExecuteDefaultRuntimeCommandPipeline()` 和三条直接相关 sanity helpers。pipeline 只把 existing cycle request、cycle result 与 command draft 串成 internal summary pipeline；`didCompletePipeline=true` 只表示 summary 已生成，不代表真实 runtime run。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-command-pipeline-subsystem-draft-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-command-pipeline-subsystem-draft-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-command-pipeline-subsystem-draft-closure-review.md)。当前 next opening 转向 `P1 internal runtime command pipeline subsystem draft closure / next runtime behavior decision`。

最新补充：P1 internal runtime driver draft bundle implementation 已完成；新增默认 internal `CjguiInternalRuntimeDriverRequest` 与 `CjguiInternalRuntimeDriverResult`，以及 `cjguiInternalDefaultRuntimeDriverRequest()`、`cjguiInternalExecuteRuntimeDriverPass(request)`、`cjguiInternalExecuteDefaultRuntimeDriverPass()` 和三条直接相关 sanity helpers。driver draft 只组织一次 internal command pipeline pass，并把 pipeline draft 投影为 driver-level summary；`didCompleteDriverPass` 只表示 internal summary pass 已完成，不代表真实 runtime driver。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-driver-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-driver-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-driver-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime driver draft bundle closure / next runtime behavior decision`。

最新补充：P1 internal runtime driver input policy bundle implementation 已完成；新增默认 internal `CjguiInternalRuntimeDriverInput`、`CjguiInternalRuntimeDriverPolicy`、`CjguiInternalRuntimeDriverDecision`，以及 default driver input / policy builders、`cjguiInternalDecideRuntimeDriverPass`、`cjguiInternalExecuteRuntimeDriverPassWithInput` 和三条直接相关 sanity helpers。driver input / policy 只作为 driver pass 的脱水 gate；allowed path 复用既有 driver pass，blocked path 只返回 fail-closed summary，不执行 pipeline pass、不消费 queue、不触发 callback。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-driver-input-policy-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-28-p1-internal-runtime-driver-input-policy-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-driver-input-policy-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime driver input policy bundle closure / next runtime behavior decision`。

最新补充：P1 internal runtime driver report bundle implementation 已完成；新增默认 internal `CjguiInternalRuntimeDriverReport`，以及 `cjguiInternalBuildRuntimeDriverReport(result)`、`cjguiInternalExecuteRuntimeDriverPassReport(request, input, policy)`、`cjguiInternalExecuteDefaultRuntimeDriverPassReport()` 和三条直接相关 sanity helpers。driver report 只把 gated driver pass result 规整成 internal next-action summary；`isReadyForNextInternalPass` 只由 `didCompleteDriverPass` 与 `shouldRequestNextCycle` 派生，不是 scheduler、event loop command、queue item 或 renderer command list。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-driver-report-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-runtime-driver-report-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-driver-report-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime driver report bundle closure / next runtime behavior decision`。

最新补充：P1 internal runtime run intent bundle implementation 已完成；新增默认 internal `CjguiInternalRuntimeRunIntent`，以及 `cjguiInternalBuildRuntimeRunIntent(report)`、`cjguiInternalExecuteRuntimeRunIntentDraft(request, input, policy)`、`cjguiInternalExecuteDefaultRuntimeRunIntentDraft()` 和三条直接相关 sanity helpers。run intent 只把 driver report 投影为 internal run-boundary intent summary；`mayRequestRuntimeRun` 只由 `report.isReadyForNextInternalPass` 派生，不是 run loop、scheduler、queue item、event loop command 或 public runtime run API。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-run-intent-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-runtime-run-intent-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-run-intent-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime run intent bundle closure / next runtime behavior decision`。

最新补充：P1 internal runtime run request bundle implementation 已完成；新增默认 internal `CjguiInternalRuntimeRunRequest` 与 `CjguiInternalRuntimeRunRequestReport`，以及 `cjguiInternalBuildRuntimeRunRequest(intent)`、`cjguiInternalEvaluateRuntimeRunRequest(request)`、`cjguiInternalExecuteRuntimeRunRequestDraft(driverRequest, input, policy)`、`cjguiInternalExecuteDefaultRuntimeRunRequestDraft()` 和三条直接相关 sanity helpers。run request 只把 run intent 包装并评估为 internal request summary；`isRequestAllowed` 只由 `intent.mayRequestRuntimeRun` 派生，不是 public `run()` 调用、event loop start、scheduler、queue item、platform callback 或 public runtime API。envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-run-request-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-runtime-run-request-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-run-request-bundle-closure-review.md)。当前 next opening 转向 `P1 internal runtime run request bundle closure / next runtime behavior decision`。

最新补充：P1 internal runtime readiness / run-boundary chain compaction 已完成；新增 [2026-04-29-p1-internal-runtime-readiness-run-boundary-chain-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-readiness-run-boundary-chain-compaction.md)，将 root state、runtime step、runtime cycle、command draft、command pipeline、driver pass、driver report、run intent、run request 压缩为一份短结论。关键判断：不建议继续增加纯 report / wrapper 层；下一步推荐先补 `shutdown / cancellation intent`，避免 run-boundary 只有进入方向没有退出方向。当前 next opening 转向 `P1 internal shutdown / cancellation intent bundle implementation`。

最新补充：P1 internal shutdown / cancellation intent bundle implementation 已完成；新增默认 internal `CjguiInternalRuntimeShutdownIntent`、`CjguiInternalRuntimeShutdownRequest`、`CjguiInternalRuntimeShutdownReport`，以及 default intent、intent builder、request builder、request evaluator 和四条直接相关 sanity helpers。shutdown / cancellation intent 只表达 internal exit-direction 脱水意图；shutdown report 只把 shutdown/cancel 对 run request 的影响规整为 defer-run 与 enter-path flags，不是真实 app shutdown、event loop stop、queue drain、platform callback 或 task cancellation。envsetup 后 `cjpm build --target-dir /tmp/cjgui-shutdown-cancellation-intent-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-shutdown-cancellation-intent-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-shutdown-cancellation-intent-bundle-closure-review.md)。当前 next opening 转向 `P1 internal shutdown / cancellation intent bundle closure / next run-boundary decision`。

最新补充：P1 internal run-boundary readiness compaction 已完成；新增 [2026-04-29-p1-internal-run-boundary-readiness-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-run-boundary-readiness-compaction.md)，将 readiness / root state、step / cycle、command draft / pipeline、driver pass / report、run intent / run request 与 shutdown / cancellation intent 压缩成 run-boundary 前结论。关键判断：不建议继续增加纯 report / wrapper 层；可以进入第一个 internal run boundary draft，但只能聚合 run request report + shutdown report 并判断 open / deferred / blocked，不能执行 `run()`、启动 loop、drain queue 或调平台。当前 next opening 转向 `P1 internal run boundary draft bundle implementation`。

最新补充：P1 internal run boundary draft bundle implementation 已完成；新增默认 internal `CjguiInternalRunBoundaryRequest` 与 `CjguiInternalRunBoundaryReport`，以及 run boundary request builder、evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。run boundary draft 只聚合 run request report + shutdown report，并判断 boundary open / deferred / blocked；ready path open，runtime-not-ready / input-blocked run request fail closed，shutdown / cancellation intent 会 defer 并标记对应 blocker。本轮不执行 `run()`、不启动 event loop、不 drain queue、不调平台、不触发真实 shutdown / cancellation。envsetup 后 `cjpm build --target-dir /tmp/cjgui-run-boundary-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-run-boundary-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-run-boundary-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal run boundary draft bundle closure / next runtime behavior decision`。

最新补充：P1 internal app run surface boundary compaction 已完成；新增 [2026-04-29-p1-internal-app-run-surface-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-app-run-surface-boundary-compaction.md)，将 run request report、shutdown / cancellation report、run boundary request/report 与 open / deferred / blocked 判断压缩成 app run surface 前结论。关键判断：可以开始定义 internal-only app run surface，但第一刀只能定义脱水 `AppRunState` / `AppRunRequest` / `AppRunReport` 与 internal evaluator；该 surface 必须消费 run boundary report，不能绕过 run boundary 直接读 lower-level platform / lifecycle facts。本轮没有写 runtime code，没有创建 preflight / execution card；`git diff --check` 通过。当前 next opening 转向 `P1 internal app run surface bundle implementation`。

最新补充：P1 internal app run surface bundle implementation 已完成；新增默认 internal `CjguiInternalAppRunState`、`CjguiInternalAppRunRequest`、`CjguiInternalAppRunReport`，以及 AppRun state/request builder、request evaluator、surface draft executor、default draft executor 和五条直接相关 sanity helpers。AppRun surface 只消费 `CjguiInternalRunBoundaryReport`，并把 boundary open / deferred / blocked 投影为 accept / defer / blocked summary；它不执行 `run()`、不启动 event loop、不 drain queue、不调平台，也不绕过 run boundary 读取 lower-level readiness / platform / lifecycle facts。RED build 在缺少 AppRun executor 时失败；GREEN 后 `cjpm build --target-dir /tmp/cjgui-app-run-surface-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-app-run-surface-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-app-run-surface-bundle-closure-review.md)。当前 next opening 转向 `P1 internal app run surface bundle closure / next runtime behavior decision`。

最新补充：P1 internal app run controller boundary compaction 已完成；新增 [2026-04-29-p1-internal-app-run-controller-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-app-run-controller-boundary-compaction.md)，将 AppRunState、AppRunRequest、AppRunReport 与 ready/open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths 压缩成 controller 前结论。关键判断：可以开始定义 internal-only AppRun controller draft；controller 只能从 AppRunReport 派生 accepted / deferred / blocked / future-boundary next-action summary，不能执行 action，也不能绕过 AppRunReport 直接读取 RunBoundaryReport 或 lower-level facts。本轮没有写 runtime code，没有创建 preflight / execution card；当前 next opening 转向 `P1 internal app run controller draft bundle implementation`。

最新补充：P1 internal app run controller draft bundle implementation 已完成；新增默认 internal `CjguiInternalAppRunControllerRequest`、`CjguiInternalAppRunControllerDecision`、`CjguiInternalAppRunControllerReport`，以及 controller request builder、decision function、evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。AppRun controller draft 只消费 `CjguiInternalAppRunReport`，并派生 accepted / deferred / blocked / future-boundary next-action summary；它不执行 action、不执行 `run()`、不启动 event loop、不 drain queue、不调平台，也不绕过 AppRunReport 读取 RunBoundaryReport 或 lower-level facts。RED build 在缺少 controller executor 时失败；GREEN 后 `cjpm build --target-dir /tmp/cjgui-app-run-controller-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-app-run-controller-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-app-run-controller-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal app run controller draft bundle closure / next runtime behavior decision`。

最新补充：P1 internal app run execution plan draft bundle implementation 已完成；新增默认 internal `CjguiInternalAppRunExecutionPlanRequest`、`CjguiInternalAppRunExecutionPlan`、`CjguiInternalAppRunExecutionPlanReport`，以及 execution plan request builder、plan builder、evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。AppRun execution plan draft 只消费 `CjguiInternalAppRunControllerReport`，并从 controller decision 投影 prepare-runtime / run-loop-draft / defer / blocked-report / future-boundary plan summary；它不执行 plan、不执行 `run()`、不启动 event loop、不 drain queue、不调平台，也不绕过 ControllerReport 读取 AppRunReport、RunBoundaryReport 或 lower-level facts。RED build 在缺少 execution plan executor 时失败；GREEN 后 `cjpm build --target-dir /tmp/cjgui-app-run-execution-plan-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-app-run-execution-plan-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-app-run-execution-plan-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal app run execution plan draft bundle closure / next runtime behavior decision`。

最新补充：P1 internal app run dispatch draft bundle implementation 已完成；新增默认 internal `CjguiInternalAppRunDispatchRequest`、`CjguiInternalAppRunDispatchSummary`、`CjguiInternalAppRunDispatchReport`，以及 dispatch request builder、summary builder、evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。AppRun dispatch draft 只消费 `CjguiInternalAppRunExecutionPlanReport`，并从 execution plan 投影 prepare-runtime / run-loop-draft / deferred notice / blocked notice / future-boundary request summary；它不执行 dispatch、不写 queue、不执行 `run()`、不启动 event loop、不 drain queue、不调平台，也不绕过 ExecutionPlanReport 读取 ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level facts。RED build 在缺少 dispatch executor 时失败；GREEN 后 `cjpm build --target-dir /tmp/cjgui-app-run-dispatch-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-app-run-dispatch-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-app-run-dispatch-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal app run dispatch draft bundle closure / next runtime behavior decision`。

最新补充：P1 internal run loop draft boundary compaction 已完成；新增 [2026-04-29-p1-internal-run-loop-draft-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-run-loop-draft-boundary-compaction.md)，将 AppRun surface、AppRun controller、AppRun execution plan 与 AppRun dispatch draft 压缩成 run loop draft 前结论。关键判断：可以开始定义 internal-only RunLoopDraft boundary，但它只能从 AppRun dispatch report 派生 loop-intent summary，不能执行 loop、不能 `while`、不能 schedule、不能 drain queue、不能调平台，也不能越级读取 ExecutionPlanReport / ControllerReport / lower-level facts。本轮没有写 runtime code，没有创建 preflight / execution card；当前 next opening 转向 `P1 internal run loop draft bundle implementation`。

最新补充：P1 internal run loop draft bundle implementation 已完成；新增默认 internal `CjguiInternalRunLoopDraftRequest`、`CjguiInternalRunLoopDraftIntent`、`CjguiInternalRunLoopDraftReport`，以及 request builder、intent builder、evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。RunLoopDraft 只消费 `CjguiInternalAppRunDispatchReport`，并从 dispatch summary 投影 enter-loop-draft / defer-loop / blocked-loop / future-boundary intent summary；它不执行真实 event loop、不写 `while` / scheduling loop、不写 queue、不 drain queue、不调平台，也不绕过 DispatchReport 读取 ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level facts。RED build 在缺少 RunLoopDraft executor 时失败；GREEN 后 `cjpm build --target-dir /tmp/cjgui-run-loop-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-run-loop-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-run-loop-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal run loop draft bundle closure / next runtime behavior decision`。

最新补充：P1 internal loop iteration draft boundary compaction 已完成；新增 [2026-04-29-p1-internal-loop-iteration-draft-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-loop-iteration-draft-boundary-compaction.md)，将 RunLoopDraft request / intent / report 与 open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths 压缩成 LoopIterationDraft 前结论。关键判断：可以开始定义 internal-only single LoopIterationDraft surface，但它只能消费 RunLoopDraftReport 并派生 shouldAttemptIteration / shouldDeferIteration / shouldReportIterationBlocked / shouldRequestFutureBoundary，不能执行 loop、不能 `while`、不能 schedule、不能 drain queue、不能调平台，也不能越级读取 DispatchReport / ExecutionPlanReport / lower-level facts。本轮没有写 runtime code，没有创建 preflight / execution card；当前 next opening 转向 `P1 internal loop iteration draft bundle implementation`。

最新补充：P1 internal loop iteration draft bundle implementation 已完成；新增默认 internal `CjguiInternalLoopIterationDraftRequest`、`CjguiInternalLoopIterationDraftIntent`、`CjguiInternalLoopIterationDraftReport`，以及 request builder、intent builder、evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。LoopIterationDraft 只消费 `CjguiInternalRunLoopDraftReport`，并从 RunLoopDraft intent 投影 attempt-iteration / defer-iteration / blocked-iteration / future-boundary summary；它不执行真实 loop iteration、不写 `while` / scheduling loop、不写 queue、不 drain queue、不调平台，也不绕过 RunLoopDraftReport 读取 DispatchReport、ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level facts。envsetup 后 `cjpm build --target-dir /tmp/cjgui-loop-iteration-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-loop-iteration-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-loop-iteration-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal loop iteration draft bundle closure / next runtime behavior decision`。

最新补充：P1 internal iteration work packet boundary compaction 已完成；新增 [2026-04-29-p1-internal-iteration-work-packet-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-iteration-work-packet-boundary-compaction.md)，将 LoopIterationDraft request / intent / report 与 open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths 压缩成 IterationWorkPacketDraft 前结论。关键判断：可以开始定义 internal-only iteration work packet draft，但它只能从 LoopIterationDraftReport 派生 work-category summary，不能执行 work、不能 drain queue、不能 process input、不能 layout / render、不能调平台，也不能越级读取 RunLoopDraftReport / DispatchReport / lower-level facts。本轮没有写 runtime code，没有创建 preflight / execution card；当前 next opening 转向 `P1 internal iteration work packet draft bundle implementation`。

最新补充：P1 internal iteration work packet draft bundle implementation 已完成；新增默认 internal `CjguiInternalIterationWorkPacketDraftRequest`、`CjguiInternalIterationWorkPacketDraft`、`CjguiInternalIterationWorkPacketDraftReport`，以及 request builder、packet builder、evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。IterationWorkPacketDraft 只消费 `CjguiInternalLoopIterationDraftReport`，并从 LoopIterationDraft intent 投影 prepare-runtime work / lifecycle work / future-boundary work / defer work / blocked-work summary；它不执行 work、不 drain queue、不 process input、不 layout / render、不调平台，也不绕过 LoopIterationDraftReport 读取 RunLoopDraftReport、DispatchReport、ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level facts。envsetup 后 `cjpm build --target-dir /tmp/cjgui-iteration-work-packet-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-iteration-work-packet-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-iteration-work-packet-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal iteration work packet draft bundle closure / next runtime behavior decision`。

最新补充：P1 internal lifecycle work draft boundary compaction 已完成；新增 [2026-04-29-p1-internal-lifecycle-work-draft-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-lifecycle-work-draft-boundary-compaction.md)，将 IterationWorkPacketDraft request / packet / report 与 open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths 压缩成 LifecycleWorkDraft 前结论。关键判断：可以开始定义 internal-only lifecycle work draft，但它只能消费 IterationWorkPacketDraftReport 并派生 lifecycle-work summary，不能执行 app/window lifecycle、不能修改 app/window state、不能调平台，也不能越级读取 LoopIterationDraftReport / RunLoopDraftReport / lower-level facts。本轮没有写 runtime code，没有创建 preflight / execution card；当前 next opening 转向 `P1 internal lifecycle work draft bundle implementation`。

最新补充：P1 internal lifecycle work draft bundle implementation 已完成；新增默认 internal `CjguiInternalLifecycleWorkDraftRequest`、`CjguiInternalLifecycleWorkDraft`、`CjguiInternalLifecycleWorkDraftReport`，以及 request builder、draft builder、evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。LifecycleWorkDraft 只消费 `CjguiInternalIterationWorkPacketDraftReport`，并从 work packet 投影 process-lifecycle / defer-lifecycle / blocked-lifecycle / future-boundary-after-lifecycle summary；它不执行 app/window lifecycle、不修改 app/window state、不 drain queue、不调平台，也不绕过 IterationWorkPacketDraftReport 读取 LoopIterationDraftReport、RunLoopDraftReport、DispatchReport、ExecutionPlanReport、ControllerReport、AppRunReport、RunBoundaryReport 或 lower-level facts。envsetup 后 `cjpm build --target-dir /tmp/cjgui-lifecycle-work-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-internal-lifecycle-work-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-lifecycle-work-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 internal lifecycle work draft bundle closure / next runtime behavior decision`。

最新补充：P1 lifecycle owner handoff draft boundary compaction 已完成；新增 [2026-04-29-p1-lifecycle-owner-handoff-draft-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-lifecycle-owner-handoff-draft-boundary-compaction.md)，将 LifecycleWorkDraft request / draft / report 与 open、runtime-blocked、input-blocked、shutdown-blocked、cancellation-blocked paths 压缩成 owner handoff 前结论。关键判断：可以开始定义 internal-only lifecycle owner handoff draft；app lifecycle owner-specific draft facts 应切回 `app_lifecycle.cj`，window lifecycle owner-specific draft facts 应切回 `window_lifecycle.cj`，`runtime_state.cj` 只做 cross-owner routing summary 并消费 `CjguiInternalLifecycleWorkDraftReport`，不继续拥有 app/window lifecycle semantics。本轮没有写 runtime code，没有创建 preflight / execution card；当前 next opening 转向 `P1 lifecycle owner handoff draft bundle implementation`。

最新补充：P1 lifecycle owner handoff draft bundle implementation 已完成；在 `app_lifecycle.cj` 新增默认 internal `CjguiInternalAppLifecycleWorkHandoffDraft`、builder 与 open / blocked sanity，在 `window_lifecycle.cj` 新增默认 internal `CjguiInternalWindowLifecycleWorkHandoffDraft`、builder 与 open / blocked sanity，在 `runtime_state.cj` 新增默认 internal `CjguiInternalLifecycleOwnerHandoffRequest`、`CjguiInternalLifecycleOwnerHandoffReport`、routing request builder、routing evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。runtime routing 只消费 `CjguiInternalLifecycleWorkDraftReport.draft`，不越级读取 IterationWorkPacketDraftReport、LoopIterationDraftReport、RunLoopDraftReport 或 lower-level facts；app/window owner drafts 只表达 accept / defer / blocked handoff facts，不执行 lifecycle mutation、不修改 app/window state、不调平台。RED probe 证明新 symbols 缺失后，envsetup 后 `cjpm build --target-dir /tmp/cjgui-lifecycle-owner-handoff-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-lifecycle-owner-handoff-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-lifecycle-owner-handoff-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 lifecycle owner handoff draft bundle closure / next runtime behavior decision`。

最新补充：P1 lifecycle mutation readiness draft boundary compaction 已完成；新增 [2026-04-29-p1-lifecycle-mutation-readiness-draft-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-lifecycle-mutation-readiness-draft-boundary-compaction.md)，将 lifecycle owner handoff 的 app owner draft、window owner draft 与 runtime cross-owner routing summary 压缩成 mutation readiness 前结论。关键判断：可以进入 internal-only mutation readiness draft；app mutation readiness facts 应继续归属 `app_lifecycle.cj`，window mutation readiness facts 应继续归属 `window_lifecycle.cj`，`runtime_state.cj` 只做 cross-owner mutation readiness summary。下一刀只能表达 `canMutate` / `shouldDefer` / `shouldReportBlocked`，不能修改 app/window state，不能调用 state-changing transition functions，也不能进入 queue / drain、event loop、platform callback、window create / close / destroy、public API 或 C ABI。本轮没有写 runtime code，没有创建 preflight / execution card；当前 next opening 转向 `P1 lifecycle mutation readiness draft bundle implementation`。

最新补充：P1 lifecycle mutation readiness draft bundle implementation 已完成；在 `app_lifecycle.cj` 新增默认 internal `CjguiInternalAppLifecycleMutationReadinessDraft`、builder 与 open / blocked sanity，在 `window_lifecycle.cj` 新增默认 internal `CjguiInternalWindowLifecycleMutationReadinessDraft`、builder 与 open / blocked sanity，在 `runtime_state.cj` 新增默认 internal `CjguiInternalLifecycleMutationReadinessRequest`、`CjguiInternalLifecycleMutationReadinessReport`、request builder、cross-owner evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。runtime summary 只消费 `CjguiInternalLifecycleOwnerHandoffReport.appDraft` / `windowDraft`，不越级读取 LifecycleWorkDraftReport 或 lower-level facts；app/window readiness drafts 只表达 canMutate / defer / blocked facts，不修改 app/window state、不调用 state-changing transition functions、不执行 lifecycle work。envsetup 后 `cjpm build --target-dir /tmp/cjgui-lifecycle-mutation-readiness-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-lifecycle-mutation-readiness-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-lifecycle-mutation-readiness-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 lifecycle mutation readiness draft bundle closure / next runtime behavior decision`。

最新补充：P1 lifecycle mutation plan draft boundary compaction 已完成；新增 [2026-04-29-p1-lifecycle-mutation-plan-draft-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-lifecycle-mutation-plan-draft-boundary-compaction.md)，将 app/window mutation readiness facts 与 runtime cross-owner readiness summary 压缩成 mutation plan 前结论。关键判断：可以进入 internal-only lifecycle mutation plan draft；app mutation plan facts 应继续归属 `app_lifecycle.cj`，window mutation plan facts 应继续归属 `window_lifecycle.cj`，`runtime_state.cj` 只做 cross-owner mutation plan routing summary。下一刀只能表达 `shouldPlanMutation` / `shouldDeferPlan` / `shouldReportPlanBlocked`，不能修改 app/window state，不能调用 state-changing transition functions，也不能进入 queue / drain、event loop、platform callback、window create / close / destroy、public API 或 C ABI。本轮没有写 runtime code，没有创建 preflight / execution card；当前 next opening 转向 `P1 lifecycle mutation plan draft bundle implementation`。

最新补充：P1 lifecycle mutation plan draft bundle implementation 已完成；在 `app_lifecycle.cj` 新增默认 internal `CjguiInternalAppLifecycleMutationPlanDraft`、builder 与 open / blocked sanity，在 `window_lifecycle.cj` 新增默认 internal `CjguiInternalWindowLifecycleMutationPlanDraft`、builder 与 open / blocked sanity，在 `runtime_state.cj` 新增默认 internal `CjguiInternalLifecycleMutationPlanRequest`、`CjguiInternalLifecycleMutationPlanReport`、request builder、cross-owner evaluator、draft executor、default draft executor 和五条直接相关 sanity helpers。runtime summary 只消费 `CjguiInternalLifecycleMutationReadinessReport.appReadiness` / `windowReadiness`，不越级读取 OwnerHandoffReport、LifecycleWorkDraftReport 或 lower-level facts；app/window plan drafts 只表达 shouldPlan / defer-plan / blocked-plan facts，不修改 app/window state、不调用 state-changing transition functions、不执行 lifecycle work。envsetup 后 `cjpm build --target-dir /tmp/cjgui-lifecycle-mutation-plan-draft-bundle-target --skip-script` 通过（仅 unused warnings），smoke guard 与 `git diff --check` 通过；bundle closure 已封账为 [2026-04-29-p1-lifecycle-mutation-plan-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-lifecycle-mutation-plan-draft-bundle-closure-review.md)。当前 next opening 转向 `P1 lifecycle mutation plan draft bundle closure / next runtime behavior decision`。

## 当前 current-state summary

### 1. 项目目标已清楚

- 做一个仓颉原生 GUI 框架
- 上层尽量保持仓颉原生
- 底层允许必要且向上接口极窄的平台桥接
- 第一阶段优先做桌面运行时，而不是大而全 GUI 框架

### 2. 当前推荐阶段顺序已清楚

- 先单平台
- 先窗口 / 事件循环 / 重绘 / 基础绘制
- 再进入布局、控件、文本
- 输入法、无障碍、复杂文本都属于后期开口

### 3. 当前治理框架已落地

当前项目已经具备：

- [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)
- [GUI_THINKING_FRAMEWORK.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_THINKING_FRAMEWORK.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)
- [HUMAN_COLLABORATION_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/HUMAN_COLLABORATION_GOVERNANCE.md)
- [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)

## 当前统一 stop-line

在新的批准出现之前，当前项目统一保持：

- 不做跨平台抽象
- 不做公共声明式 DSL
- 不做输入框
- 不做 IME
- 不做无障碍
- 不做大而全控件库
- 不引入重型 GUI 框架
- 不把平台原生事件直接暴露成公共 API
- 不把 demo 当成熟能力
- 不让状态真相和渲染真相分裂为双源
- 不让后台线程 / 协程直接写 GUI 资源
- 不让 FFI 平台对象以裸指针语义泄露到仓颉公共层

## 当前 active opening

当前推荐开启的下一条 opening：

### `P1 lifecycle mutation plan draft bundle closure / next runtime behavior decision`

性质：closure review / architecture decision

目标：

- 基于 [2026-04-29-p1-lifecycle-mutation-plan-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-lifecycle-mutation-plan-draft-bundle-closure-review.md)，封账 internal-only lifecycle mutation plan draft。
- app mutation plan facts 已放在 `app_lifecycle.cj`；window mutation plan facts 已放在 `window_lifecycle.cj`。
- `runtime_state.cj` 只做 cross-owner mutation plan routing summary，消费 mutation readiness report，不拥有 lifecycle mutation semantics。
- 下一步需要先判断是否继续进入 lifecycle mutation execution readiness / command draft，或转向更高层 compaction。

本 opening 仍禁止：

- 修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 修改 `cjpm.toml`，新增 `src/main.cj` 或 `package_anchor.cj`。
- 新增 `public` runtime API 或 public C ABI。
- 引用 AppKit / Metal / Objective-C，或暴露 platform object、native handle、raw pointer。
- 实现 event loop、`while` loop / scheduling loop、callback binding、queue / drain、input processing、layout / render、app lifecycle execution、window lifecycle execution、app/window state mutation、调用 state-changing transition functions、app run / shutdown、window create / close / destroy / release。
- 新增 handle table / generation。
- 进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、pixel diff / baseline / offscreen renderer。

最近完成的 bounded implementation opening：

### `P1 minimal app/window lifecycle runtime skeleton bounded implementation first slice`

- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md)
- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)

完成内容：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/` minimal runtime skeleton。
- `.cj` 文件全部保持 comment-only，占位记录 app lifecycle、window lifecycle、platform adapter boundary 和 error strategy placeholder。
- 未创建 build config / package config。
- 未定义稳定 public API。
- 未实现真实 app lifecycle、window lifecycle、event loop、window create / close / destroy、handle table / generation。
- smoke guard `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，退出码 `0`。
- Cangjie build check 暂不适用：当前没有 runtime package/build entry，且 `.cj` 文件为 comment-only skeleton。
- 当前 next opening 更新为 docs-only `P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不实现真实 app lifecycle、window lifecycle、event loop、window create / close / destroy、handle table / generation。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 command-list hash、semantic tree / Action Router、pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

最近完成的 docs-only opening：

### `P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight`

- [2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md)

完成内容：

- 复核当前 `runtime/cjgui` comment-only skeleton 足以作为 architectural placeholder 封账。
- 确认 skeleton 仍符合 execution card：不实现 runtime、不定义 public API、不迁移 smoke、不暴露平台对象。
- 判断 app lifecycle surface 应作为下一条优先冻结边界，因为它先决定 runtime owner、main-thread queue / drain、`init` / `run` / `request quit` / `shutdown` 和 platform adapter 驱动关系。
- 明确不建议直接进入 runtime implementation，也不建议先开 window lifecycle implementation、build / package、Renderer、Scene、Widget 或 Layout。
- 吸收 self-drawn guardrails：不默认 global tick / blind redraw，不暗中打开 Text / Input / IME / Accessibility，不把自绘解释为忽略 platform adapter、IME 坐标同步或 accessibility semantic bridge。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 app lifecycle、window lifecycle、event loop、window create / close / destroy、handle table / generation。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。

### `P1 app lifecycle surface boundary preflight`

- [2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)

完成内容：

- 冻结 future app lifecycle owner 属于 `runtime/cjgui` core app lifecycle module。
- 明确 platform adapter 负责平台 event loop / callback / runloop truth，core app lifecycle 只消费脱水 lifecycle facts、queue drain request、quit request、platform readiness / failure。
- 明确 main-thread queue / drain 的 conceptual owner 可归 app lifecycle，但实际平台主线程执行必须留在 platform adapter / bridge。
- 明确 `init` / `run` / `request quit` / `shutdown` / `drain main-thread queue` 仍只是 future slot，不是 API 或实现。
- 明确第一刀不定义 public runtime API，不创建 package / build config，不实现 run / shutdown / queue / drain。
- 明确 app lifecycle 不拥有 window target identity、stale handle validation 或 handle generation；这些属于 window lifecycle / future handle table。
- 吸收 self-drawn guardrails：不默认 global tick / blind redraw，不把 frame loop 当成 app lifecycle 默认事实，不暗中打开 Text / Input / IME / Accessibility。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 app lifecycle / event loop / run / shutdown。
- 不实现 main-thread queue / drain。
- 不实现 window lifecycle / window create / close / destroy、handle table / generation。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。

### `P1 app lifecycle surface execution card`

- [2026-04-26-p1-app-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-execution-card.md)

完成内容：

- 将 app lifecycle surface boundary preflight 收束成受限 execution card。
- 明确创建 execution card 不等于实现，不自动开启 runtime implementation。
- 明确 future first slice 最多只能做 `runtime/cjgui/src/app_lifecycle.cj` 和 / 或 `runtime/cjgui/README.md` 的 comment-only / documentation-level surface refinement。
- 明确 future first slice 不得写非注释仓颉语法，不得创建 package / build config，不得定义稳定函数签名或 public API。
- 明确不允许实现真实 app lifecycle、`run`、`shutdown`、`request quit`、main-thread queue / drain。
- 明确不允许把 `NSRunLoop`、`NSEvent`、`dispatch_main` 或 Objective-C callback truth 写进 core runtime。
- 明确不允许 default global tick / blind redraw / frame scheduler、Text / Input / IME / Accessibility、Renderer / Scene / Widget / Layout / DSL、handle table / generation、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 app lifecycle / event loop / run / shutdown / queue / drain。
- 不实现 window lifecycle / window create / close / destroy、handle table / generation。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。

### `P1 app lifecycle surface comment-only refinement first slice`

- [2026-04-26-p1-app-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-execution-card.md)
- [2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md)

完成内容：

- 只在 `runtime/cjgui/src/app_lifecycle.cj` 中补清 app lifecycle future slot 的 comment-only 边界。
- 轻量更新 `runtime/cjgui/README.md` 的 app lifecycle surface boundary section。
- `.cj` 文件仍为 comment-only，未写非注释仓颉语法。
- 未新增 package / build config。
- 未定义 public runtime API。
- 未实现 app lifecycle、`run`、`shutdown`、`request quit`、main-thread queue / drain。
- smoke guard `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，退出码 `0`。
- Cangjie build check 暂不适用：`Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.`
- 当前 next opening 更新为 docs-only `P1 app lifecycle surface closure / window lifecycle surface boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 app lifecycle / event loop / run / shutdown / queue / drain。
- 不实现 window lifecycle / window create / close / destroy、handle table / generation。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。

### `P1 first internal app lifecycle state execution card`

- [2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md)

完成内容：

- 创建一张短 execution card；创建本卡不等于实现。
- 授权未来 first slice 只在 `runtime/cjgui/src/app_lifecycle.cj` 中新增一个默认 internal app lifecycle state marker / placeholder type。
- marker 只能表达 `app lifecycle state boundary exists but lifecycle state machine is not yet defined`。
- future first slice 必须先查证仓颉 struct / package / visibility / build 规则，并运行 `cjpm build` 与 smoke guard。
- 当前 next opening 更新为 `P1 first internal app lifecycle state first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge、仓颉入口或 `cjpm.toml`。
- 不定义字段、`public`、import、函数、方法、显式 init、构造逻辑或 runtime behavior。
- 不实现 `run` / `shutdown` / `request quit` / queue / drain、platform adapter callback binding、window lifecycle behavior 或 error strategy behavior。
- 不定义 public runtime API、public C ABI，也不引用 AppKit / Metal / Objective-C。

### `P1 first internal app lifecycle state first slice`

- [2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md)
- [2026-04-27-p1-first-internal-app-lifecycle-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-closure-review.md)

完成内容：

- 只在 `runtime/cjgui/src/app_lifecycle.cj` 中新增默认 internal 空 `struct CjguiInternalAppLifecycleState {}`。
- 该 marker 只表达 `app lifecycle state boundary exists but lifecycle state machine is not yet defined`。
- `state_machine_defined=false`、`run_behavior_present=false`、`shutdown_behavior_present=false`、`request_quit_behavior_present=false`、`queue_behavior_present=false`、`drain_behavior_present=false`。
- 未新增字段、`public`、import、函数、方法、显式 init、runtime behavior、public runtime API 或 public C ABI。
- 未修改 `cjpm.toml`、`src/main.cj`、`package_anchor.cj`、smoke / harness / native bridge / 仓颉入口。
- `cjpm build --target-dir /tmp/cjgui-first-internal-app-lifecycle-state-target --skip-script` 通过，smoke guard 通过。
- 当前 next opening 更新为 `P1 first internal app lifecycle state closure / lifecycle state shape decision`，但不自动开启下一步。

### `P1 app lifecycle state shape execution card`

- [2026-04-27-p1-app-lifecycle-state-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-execution-card.md)

完成内容：

- 创建一张短 execution card；创建本卡不等于实现。
- 授权未来 first slice 只修改 `runtime/cjgui/src/app_lifecycle.cj` 中的 `CjguiInternalAppLifecycleState`。
- future first slice 最多新增一个不可变 `Bool` 字段，语义等价于 `stateMachineActive: Bool = false`。
- 该字段只表达最小脱水 state shape，不代表 state machine、`run`、`shutdown`、`request quit`、queue 或 drain 已实现。
- future first slice 必须先查证仓颉 struct field / package / visibility / build 规则，并运行 `cjpm build` 与 smoke guard。
- 当前 next opening 更新为 `P1 app lifecycle state shape first slice`，但不自动开启实现。

### `P1 app lifecycle state shape first slice`

- [2026-04-27-p1-app-lifecycle-state-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-execution-card.md)
- [2026-04-27-p1-app-lifecycle-state-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-closure-review.md)

完成内容：

- 只修改 `runtime/cjgui/src/app_lifecycle.cj` 中现有 `CjguiInternalAppLifecycleState`。
- 新增唯一默认 internal 不可变字段 `isStateMachineActive: Bool = false`，只表达最小脱水 app lifecycle state shape。
- `state_machine_defined=false`、`run_behavior_present=false`、`shutdown_behavior_present=false`、`request_quit_behavior_present=false`、`queue_behavior_present=false`、`drain_behavior_present=false`。
- 未新增 `public`、import、函数、方法、显式 init、runtime behavior、public runtime API 或 public C ABI。
- 未修改 `cjpm.toml`、`src/main.cj`、`package_anchor.cj`、smoke / harness / native bridge / 仓颉入口。
- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-shape-target --skip-script` 通过，smoke guard 通过。
- 当前 next opening 更新为 `P1 app lifecycle state shape closure / lifecycle transition boundary decision`，但不自动开启下一步。

### `P1 app lifecycle transition boundary execution card`

- [2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md)

完成内容：

- 创建一张短 execution card；创建本卡不等于实现。
- 授权下一刀进入 bounded implementation：最多只在 `runtime/cjgui/src/app_lifecycle.cj` 新增一个默认 internal、无 `public`、无 import 的 app lifecycle transition marker type。
- 推荐 marker 语义为 `transition boundary exists but transition behavior is not yet defined`。
- 默认不授权函数；如果选择函数，必须 fail closed，除非另有单独授权。
- 继续禁止修改 `isStateMachineActive` 的值或语义、第二个 state 字段、`run` / `shutdown` / `request quit` / queue / drain、platform adapter callback binding、window / error behavior、public runtime API、public C ABI、AppKit / Metal / Objective-C 引用、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`、smoke / harness / native bridge / 仓颉入口修改。
- 当前 next opening 更新为 `P1 app lifecycle transition marker first slice`；根据 Docs Exit Rule，下一轮默认应进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

### `P1 app lifecycle transition marker first slice`

- [2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md)
- [2026-04-27-p1-app-lifecycle-transition-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-marker-closure-review.md)

完成内容：

- 新增默认 internal 空 `struct CjguiInternalAppLifecycleTransitionMarker {}`。
- 该 marker 只表达 app lifecycle transition boundary exists but transition behavior is not yet defined。
- 未修改 `CjguiInternalAppLifecycleState` 或 `isStateMachineActive`，未新增字段、函数、方法、显式 init、import、runtime behavior、public runtime API 或 public C ABI。
- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-transition-marker-target --skip-script` 通过，smoke guard 通过，`cjpm.toml` 与 smoke / harness / native bridge / 仓颉入口未修改。
- 当前 next opening 更新为 `P1 app lifecycle transition marker closure / first internal no-op transition decision`，但不自动开启下一步。

### `P1 app lifecycle no-op transition execution card`

- [2026-04-27-p1-app-lifecycle-no-op-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-no-op-transition-execution-card.md)

完成内容：

- 创建一张短 execution card；创建本卡不等于实现。
- 授权下一刀进入 bounded implementation：最多只在 `runtime/cjgui/src/app_lifecycle.cj` 新增一个默认 internal no-op transition function。
- 推荐函数语义为接收并返回同一个 `CjguiInternalAppLifecycleState`，只证明包内可以承载 internal lifecycle transition function。
- 继续禁止 state change、state machine activation、真实 lifecycle API 名称、`public`、import、enum、`Result` type、queue / drain / request quit / shutdown / run 行为、platform adapter callback binding、window / error behavior、public runtime API、public C ABI、AppKit / Metal / Objective-C 引用、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`、smoke / harness / native bridge / 仓颉入口修改。
- 当前 next opening 更新为 `P1 app lifecycle no-op transition first slice`；根据 Docs Exit Rule，下一轮默认应进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

### `P1 app lifecycle no-op transition first slice`

- [2026-04-27-p1-app-lifecycle-no-op-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-no-op-transition-execution-card.md)
- [2026-04-27-p1-app-lifecycle-no-op-transition-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-no-op-transition-closure-review.md)

完成内容：

- 在 `runtime/cjgui/src/app_lifecycle.cj` 新增默认 internal `func cjguiInternalNoOpAppLifecycleTransition(state: CjguiInternalAppLifecycleState): CjguiInternalAppLifecycleState`。
- 函数返回输入 state 本身，只证明包内可以承载 internal lifecycle transition function。
- `state_modified=false`、`is_state_machine_active_modified=false`、`state_machine_activated=false`、`run_behavior_present=false`、`shutdown_behavior_present=false`、`request_quit_behavior_present=false`、`queue_behavior_present=false`、`drain_behavior_present=false`。
- `public_api_present=false`、`public_c_abi_present=false`、`behavior_code_present=false`、`public_present=false`、`import_present=false`、`enum_present=false`、`result_type_present=false`。
- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-no-op-transition-target --skip-script` 通过并报告 existing unused function warning；smoke guard 通过，`cjpm_toml_changed=false`、`smoke_changed=false`。
- 当前 next opening 更新为 `P1 first real app lifecycle transition boundary decision`，但不自动开启下一步。

### `P1 app lifecycle phase marker execution card`

- [2026-04-27-p1-app-lifecycle-phase-marker-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-marker-execution-card.md)

完成内容：

- 创建短 execution card，不等于实现。
- 授权下一刀最多只给 `CjguiInternalAppLifecycleState` 新增一个默认 internal、不可变 `Bool` phase marker / field，语义等价于 `hasLifecyclePhase: Bool = false`。
- 明确 phase marker 只表达 phase boundary exists，不定义 lifecycle phase taxonomy。
- 继续禁止 `public`、enum、`Result` type、string / int code、category、severity、修改 no-op transition、真实 lifecycle behavior、public runtime API、public C ABI、AppKit / Metal / Objective-C 引用、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`、smoke / harness / native bridge / 仓颉入口修改。
- 当前 next opening 更新为 `P1 app lifecycle phase marker first slice`；根据 Docs Exit Rule，下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

### `P1 app lifecycle phase marker first slice`

- [2026-04-27-p1-app-lifecycle-phase-marker-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-marker-execution-card.md)
- [2026-04-27-p1-app-lifecycle-phase-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-marker-closure-review.md)

完成内容：

- 在 `CjguiInternalAppLifecycleState` 中新增默认 internal 不可变 `Bool` 字段 `hasLifecyclePhase: Bool = false`。
- 字段只表达 phase boundary exists，不定义 lifecycle phase taxonomy、state machine 或真实 transition behavior。
- `no_op_transition_modified=false`、`is_state_machine_active_modified=false`、`enum_present=false`、`result_type_present=false`、`string_code_present=false`、`int_code_present=false`、`category_present=false`、`severity_present=false`。
- `run_behavior_present=false`、`shutdown_behavior_present=false`、`request_quit_behavior_present=false`、`queue_behavior_present=false`、`drain_behavior_present=false`。
- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-phase-marker-target --skip-script` 通过并报告 existing unused function warning；smoke guard 通过，`cjpm_toml_changed=false`、`smoke_changed=false`。
- 当前 next opening 更新为 `P1 app lifecycle phase marker closure / first real transition readiness decision`，但不自动开启下一步。

### `P1 app lifecycle first state-changing transition execution card`

- [2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md)

完成内容：

- 创建短 execution card，不等于实现。
- 授权下一刀进入 bounded implementation：最多新增一个默认 internal state-changing transition function。
- 该函数只能接收并返回 `CjguiInternalAppLifecycleState`，唯一允许的 state change 是返回 `hasLifecyclePhase = true`。
- 继续禁止把 `isStateMachineActive` 改成 true、phase taxonomy、enum、`Result` type、run / shutdown / request quit / queue / drain、platform / window / error behavior、public runtime API、public C ABI、AppKit / Metal / Objective-C 引用、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`、smoke / harness / native bridge / 仓颉入口修改。
- 当前 next opening 更新为 `P1 app lifecycle first state-changing transition first slice`；根据 Docs Exit Rule，下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

### `P1 app lifecycle first state-changing transition first slice`

- [2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md)
- [2026-04-27-p1-app-lifecycle-first-state-changing-transition-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-closure-review.md)

完成内容：

- 本轮按要求 fail closed，未修改 runtime。
- 仓颉 struct 文档和临时编译探针确认：当前 `CjguiInternalAppLifecycleState` 因只有带默认值的 `let` 字段且无自定义构造函数，只自动生成无参构造函数。
- `CjguiInternalAppLifecycleState(false, true)` 和 `CjguiInternalAppLifecycleState(hasLifecyclePhase: true)` 均不可编译。
- 若要返回 `hasLifecyclePhase = true` 的新 state，必须另行授权显式 init / 主构造函数 / state construction shape；这超出本轮“只新增一个 transition function”的 write set。
- `state_changing_transition_added=false`、`no_op_transition_modified=false`、`field_added=false`、`phase_taxonomy_defined=false`、`is_state_machine_active_set_true=false`。
- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-first-state-changing-transition-target --skip-script` 通过并报告 existing unused function warning；smoke guard 通过，`cjpm_toml_changed=false`、`smoke_changed=false`。
- 当前 next opening 更新为 `P1 app lifecycle state construction authority decision`，本轮不会自动打开下一步。

### `P1 app lifecycle state construction execution card`

- [2026-04-27-p1-app-lifecycle-state-construction-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-execution-card.md)

完成内容：

- 创建短 execution card，不等于实现。
- 本卡只回应上一轮 fail-closed 暴露的构造能力缺口。
- 授权下一刀最多只修改 `CjguiInternalAppLifecycleState` 的构造 shape。
- 推荐方向是新增默认 internal 显式 `init`，参数只允许覆盖既有 `isStateMachineActive` 与 `hasLifecyclePhase` 两个 `Bool` 字段，且只能赋值、无副作用。
- 继续禁止新增字段、enum、`Result` type、phase taxonomy、state-changing transition function、修改 no-op transition function、把默认状态改成 active、run / shutdown / request quit / queue / drain、platform / window / error behavior、public runtime API、public C ABI、AppKit / Metal / Objective-C 引用、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`、smoke / harness / native bridge / 仓颉入口修改。
- 后续 implementation 已 fail closed；见 [2026-04-27-p1-app-lifecycle-state-construction-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-closure-review.md)。

### `P1 app lifecycle state construction first slice`

- [2026-04-27-p1-app-lifecycle-state-construction-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-execution-card.md)
- [2026-04-27-p1-app-lifecycle-state-construction-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-closure-review.md)
- [2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md)

完成内容：

- 本轮按要求 fail closed，未保留 runtime 修改。
- 仓颉 struct `init` 探针确认：当前 `CjguiInternalAppLifecycleState` 的两个字段是带默认值的不可变 `let` 字段，在显式 `init` 中再次赋值会触发 `cannot assign to immutable value`。
- 临时显式 `init` 已撤回；`state_construction_added=false`、`field_added=false`、`state_changing_transition_added=false`、`no_op_transition_modified=false`、`default_state_active=false`、`default_has_lifecycle_phase=false`。
- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-construction-target --skip-script` 通过并报告 existing unused function warning；smoke guard 通过，`cjpm_toml_changed=false`、`smoke_changed=false`。
- 当前 next opening 更新为 `P1 app lifecycle state construction fail-closed / constructor shape decision`，本轮不会自动打开下一步。

后续 decision / execution card 已完成：

- [2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md)
- 授权下一轮进入 bounded implementation：只允许把 `CjguiInternalAppLifecycleState` 改为主构造或等价构造期初始化 shape；不得改成 `var`，不得新增字段、state-changing transition function、真实 lifecycle API 或 public contract。

### `P1 app lifecycle state initialization shape first slice`

- [2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md)
- [2026-04-27-p1-app-lifecycle-state-initialization-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-closure-review.md)

完成内容：

- `CjguiInternalAppLifecycleState` 从字段默认值初始化改为默认 internal 显式 `init` 构造期初始化 shape。
- `isStateMachineActive` 与 `hasLifecyclePhase` 仍为 `let`，未改成 `var`。
- 无参 `init()` 继续构造 inactive / no lifecycle phase。
- 带参 `init(isStateMachineActive: Bool, hasLifecyclePhase: Bool)` 只写入这两个 `Bool` facts，允许内部构造不同 state。
- 未新增字段、state-changing transition function、enum、`Result` type 或 phase taxonomy。
- no-op transition function 未修改。
- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-initialization-shape-target --skip-script` 通过，smoke guard 通过。

最近完成的 bounded implementation opening：

### `P1 app lifecycle first state-changing transition retry first slice`

- [2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md)
- [2026-04-27-p1-app-lifecycle-state-initialization-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-closure-review.md)
- [2026-04-27-p1-app-lifecycle-first-state-changing-transition-retry-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-retry-closure-review.md)

完成内容：

- 在 `runtime/cjgui/src/app_lifecycle.cj` 新增默认 internal `cjguiInternalAppLifecyclePhaseMarkerTransition`。
- 函数接收并返回 `CjguiInternalAppLifecycleState`，唯一 state change 是 returned state 的 `hasLifecyclePhase=true`。
- 函数保留输入 `isStateMachineActive`，不强制把它改成 `true`。
- 未新增字段、enum、`Result` type、phase taxonomy、string / int code、category、severity、public runtime API 或 public C ABI。
- no-op transition function 未修改。
- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-first-state-changing-transition-retry-target --skip-script` 通过；smoke guard 通过。

最近完成的 docs-only compaction：

### `P1 app lifecycle first state-changing transition closure / app lifecycle mini-slice compaction`

- [2026-04-27-p1-app-lifecycle-mini-slice-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-mini-slice-compaction.md)

完成内容：

- 压缩当前 app lifecycle internal surface：`CjguiInternalAppLifecycleState`、`isStateMachineActive`、`hasLifecyclePhase`、`CjguiInternalAppLifecycleTransitionMarker`、no-op transition function、phase marker transition function。
- 明确这些 symbol 只证明 internal state / transition surface 可编译，不证明 state machine、phase taxonomy、run、shutdown、request quit、queue、drain、platform callback binding、window lifecycle behavior、public runtime API 或 public C ABI。
- 后续 app lifecycle 线建议优先读取 compaction、当轮 current execution card 和 `runtime/cjgui/src/app_lifecycle.cj`，不默认读取完整 marker / shape / constructor / transition closure 历史。

最近完成的 docs-only opening：

### `P1 app lifecycle phase taxonomy execution card`

- [2026-04-27-p1-app-lifecycle-phase-taxonomy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-taxonomy-execution-card.md)

完成内容：

- 创建短 execution card，不等于实现。
- 授权下一刀最多新增一个默认 internal 空 phase taxonomy marker / placeholder type，推荐语义类似 `CjguiInternalAppLifecyclePhaseTaxonomyMarker`。
- 明确 marker 只表达 phase taxonomy boundary exists but taxonomy is not yet defined。
- 继续禁止 enum、string / int code、category、severity、修改 `CjguiInternalAppLifecycleState`、新增字段、修改 no-op / phase marker transition、新增 state-changing transition、run / shutdown / request quit / queue / drain、platform / window / error behavior、public runtime API、public C ABI、AppKit / Metal / Objective-C 引用、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`、smoke / harness / native bridge / 仓颉入口修改。
- 当前 next opening 更新为 `P1 app lifecycle phase taxonomy marker first slice`；根据 Docs Exit Rule，下一轮默认进入 bounded implementation，除非发现 HIGH / CRITICAL 风险或 authority 冲突。

最近完成的 bounded implementation opening：

### `P1 app lifecycle phase taxonomy marker first slice`

- [2026-04-27-p1-app-lifecycle-phase-taxonomy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-taxonomy-execution-card.md)
- [2026-04-27-p1-app-lifecycle-phase-taxonomy-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-taxonomy-marker-closure-review.md)

完成内容：

- 在 `runtime/cjgui/src/app_lifecycle.cj` 新增默认 internal 空 `CjguiInternalAppLifecyclePhaseTaxonomyMarker`。
- 该 marker 只表达 phase taxonomy boundary exists but taxonomy is not yet defined。
- 未定义真实 phase taxonomy、enum、string code、int code、category、severity、public runtime API 或 public C ABI。
- 未修改 `CjguiInternalAppLifecycleState`、no-op transition 或 phase marker transition。
- 未新增字段、state-changing transition、run / shutdown / request quit / queue / drain。
- `cjpm build --target-dir /tmp/cjgui-app-lifecycle-phase-taxonomy-marker-target --skip-script` 通过；smoke guard 通过。

### `P1 window lifecycle surface boundary preflight`

- [2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)

完成内容：

- 冻结 future window lifecycle owner 属于 `runtime/cjgui` core window lifecycle module。
- 明确 window lifecycle 与 app lifecycle 的边界：app lifecycle 负责 app-level queue acceptance / shutdown policy，window lifecycle 负责 window target state、request close、destroyed / stale target classification。
- 明确 platform adapter 负责 AppKit / Metal / Objective-C 平台对象和平台 callback truth；core window lifecycle 只处理脱水 window facts。
- 明确 `create window` / `request close` / `destroy` / `release` 仍只是 future slot，不是 API 或实现。
- 明确 request close 应经过 app lifecycle / main-thread queue / drain 的 future conceptual path。
- 明确 auto-close、manual close、future async close 必须汇入同一 request close path，避免生命周期竞态。
- 明确 handle table / generation 现在不做；只有进入 public handle、多窗口、target update 或 async UI message targeting 时才必须同步打开。
- 明确第一阶段继续 single-window，但不能写成长期 runtime 限制。
- 当前 next opening 更新为 docs-only `P1 window lifecycle surface execution card`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 window lifecycle / window create / request close / destroy / release。
- 不实现 app lifecycle / event loop / queue / drain。
- 不实现 handle table / generation。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。

### `P1 window lifecycle surface execution card`

- [2026-04-26-p1-window-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-execution-card.md)

完成内容：

- 将 window lifecycle surface boundary preflight 收束成受限 docs-only execution card。
- 明确创建 execution card 不等于实现，不自动开启 runtime implementation。
- 明确 future first slice 最多只能做 `runtime/cjgui/src/window_lifecycle.cj` 和 / 或 `runtime/cjgui/README.md` 的 comment-only / documentation-level surface refinement。
- 明确 future first slice 不得写非注释仓颉语法，不得创建 package / build config，不得定义稳定函数签名或 public API。
- 明确不允许实现真实 window lifecycle、window create / request close / destroy / release。
- 明确不允许实现 app lifecycle / event loop / queue / drain。
- 明确不允许暴露 AppKit / Metal / Objective-C 平台对象。
- 明确不允许 handle table / generation、多窗口、target update 或 async UI message targeting。
- 明确不允许 default global tick / blind redraw / frame scheduler、Text / Input / IME / Accessibility、Renderer / Scene / Widget / Layout / DSL、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 当前 next opening 更新为 `P1 window lifecycle surface comment-only refinement first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 window lifecycle / window create / request close / destroy / release。
- 不实现 app lifecycle / event loop / queue / drain。
- 不实现 handle table / generation、多窗口、target update 或 async UI message targeting。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 window lifecycle surface comment-only refinement first slice`

- [2026-04-26-p1-window-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-execution-card.md)
- [2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md)

完成内容：

- 只在 `runtime/cjgui/src/window_lifecycle.cj` 中补清 window lifecycle future slot 的 comment-only 边界。
- 轻量更新 `runtime/cjgui/README.md` 的 window lifecycle surface boundary section。
- `.cj` 文件仍为 comment-only，未写非注释仓颉语法。
- 未新增 package / build config。
- 未定义 public runtime API。
- 未实现 window lifecycle、window create、request close、destroy 或 release。
- 未实现 app lifecycle、event loop、main-thread queue 或 drain。
- 未实现 handle table / generation、多窗口、target update 或 async UI message targeting。
- 未引用或调用 smoke C ABI。
- 未暴露 platform object / raw pointer public surface。
- AppKit / Metal / Objective-C 相关词只作为禁止事项或 platform adapter 内部边界出现。
- smoke guard `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，退出码 `0`。
- Cangjie build check 暂不适用：`Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.`
- 当前 next opening 更新为 docs-only `P1 window lifecycle surface closure / platform adapter boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 window lifecycle / window create / request close / destroy / release。
- 不实现 app lifecycle / event loop / queue / drain。
- 不实现 handle table / generation、多窗口、target update 或 async UI message targeting。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 platform adapter boundary preflight`

- [2026-04-26-p1-platform-adapter-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-preflight.md)

完成内容：

- 冻结 future platform adapter owner 属于 `runtime/cjgui` platform adapter module。
- 明确 platform adapter 与 app lifecycle 的边界：adapter 拥有平台 runloop / callback / main-thread execution，app lifecycle 只消费脱水 lifecycle facts 并拥有 app-level policy。
- 明确 platform adapter 与 window lifecycle 的边界：adapter 持有平台窗口对象并输出脱水 window facts，window lifecycle 持有 target state 与 stale / destroyed classification。
- 明确 adapter 可以在内部持有 AppKit / Metal / Objective-C 平台对象，但不得泄露到 core public surface。
- 明确 core runtime 不允许持有 `NSRunLoop`、`NSEvent`、`dispatch_main` 或 Objective-C callback truth。
- 明确 adapter 可交给 core 的事实只能是 lifecycle、platform readiness / failure、queue drain request、quit / close request、window state、future input、future frame / redraw 等脱水 facts。
- 明确 adapter 不应交给 core platform object pointer、AppKit / Metal object ownership、raw event object、runloop truth 或 callback ownership。
- 明确 smoke bridge 只提供经验，不提供直接可迁移 API；smoke `last_error` 只能迁移为 future adapter error boundary 的经验，不能升格为长期并发错误系统。
- 明确当前不定义 public C ABI / runtime API，不进入 platform adapter implementation。
- 当前 next opening 更新为 docs-only `P1 platform adapter boundary execution card`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API 或 public C ABI。
- 不实现 platform adapter、app lifecycle / event loop / queue / drain、window lifecycle / window create / close / destroy。
- 不迁移 smoke code，不复用 smoke C ABI。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 platform adapter boundary execution card`

- [2026-04-26-p1-platform-adapter-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-execution-card.md)

完成内容：

- 将 platform adapter boundary preflight 收束成受限 docs-only execution card。
- 明确创建 execution card 不等于实现，不自动开启 runtime implementation。
- 明确 future first slice 最多只能做 `runtime/cjgui/src/platform_adapter.cj` 和 / 或 `runtime/cjgui/README.md` 的 comment-only / documentation-level surface refinement。
- 明确 future first slice 不得写非注释仓颉语法，不得创建 package / build config，不得定义稳定函数签名、public runtime API 或 public C ABI。
- 明确不允许实现 platform adapter、app lifecycle / event loop / queue / drain、window lifecycle / window create / close / destroy。
- 明确不允许迁移 smoke code、复用 smoke C ABI、暴露 AppKit / Metal / Objective-C platform objects，或让 core 持有 `NSRunLoop`、`NSEvent`、`dispatch_main`、Objective-C callback truth。
- 明确不允许 default global tick / blind redraw / frame scheduler、Text / Input / IME / Accessibility、Renderer / Scene / Widget / Layout / DSL、semantic tree / Action Router、command-list hash、pixel diff、baseline、offscreen renderer 或 `CJGUI_TRUTH_MANIFEST.md`。
- 当前 next opening 更新为 `P1 platform adapter surface comment-only refinement first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API 或 public C ABI。
- 不实现 platform adapter、app lifecycle / event loop / queue / drain、window lifecycle / window create / close / destroy。
- 不迁移 smoke code，不复用 smoke C ABI。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 platform adapter surface comment-only refinement first slice`

- [2026-04-26-p1-platform-adapter-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-execution-card.md)
- [2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md)

完成内容：

- 只在 `runtime/cjgui/src/platform_adapter.cj` 中补清 platform adapter future slot 的 comment-only 边界。
- 轻量更新 `runtime/cjgui/README.md` 的 platform adapter / core boundary section。
- `.cj` 文件仍为 comment-only，未写非注释仓颉语法。
- 未新增 package / build config。
- 未定义 public runtime API 或 public C ABI。
- 未实现 platform adapter、event loop、callback binding、app lifecycle、window lifecycle 或 handle table / generation。
- 未迁移 smoke code，未复用或调用 smoke C ABI。
- 未暴露 platform object / raw pointer public surface。
- `NSRunLoop`、`NSEvent`、`dispatch_main`、AppKit、Metal、Objective-C 相关词只作为禁止事项或 adapter 内部边界出现。
- smoke guard `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，退出码 `0`。
- Cangjie build check 暂不适用：`Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.`
- 当前 next opening 更新为 docs-only `P1 platform adapter surface closure / error strategy boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API 或 public C ABI。
- 不实现 platform adapter / event loop / callback binding。
- 不实现 app lifecycle / event loop / queue / drain。
- 不实现 window lifecycle / window create / close / destroy。
- 不实现 handle table / generation、多窗口、target update 或 async UI message targeting。
- 不迁移 smoke code，不复用 smoke C ABI。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 error strategy boundary preflight`

- [2026-04-26-p1-error-strategy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-preflight.md)

完成内容：

- 冻结 future error strategy owner 属于 `runtime/cjgui` error strategy module。
- 明确 error strategy 与 app lifecycle 的边界：app lifecycle 拥有 app state / policy，error strategy 只分类 app-level failure / diagnostics。
- 明确 error strategy 与 window lifecycle 的边界：window lifecycle 拥有 target state，error strategy 只分类 create / close / destroy / stale target 等失败。
- 明确 error strategy 与 platform adapter 的边界：adapter 持有 native failure details，core 只接收脱水 failure summary。
- 明确 smoke `last_error` 只能迁移“需要可观察、结构化错误边界”的经验，不能迁移 global mutable last-error、smoke C ABI、单实例语义或最近一次错误模型。
- 明确 future runtime errors 应调用关联、结构化、非全局、并发安全。
- 明确最小错误分类语义包括 fatal、recoverable、degraded、invalid usage / contract violation、platform capability missing、stale handle / stale message。
- 明确 required capability missing、destroyed target、stale / unknown ownership、非主线程直接平台 UI 操作等必须 fail closed。
- 明确默认不允许静默吞错，除非是明确 degraded diagnostics，且不得改变 state truth。
- 明确 diagnostics / logs / harness / AI 只能消费错误 evidence，不能成为第二状态真相源。
- 当前不定义 public runtime API / public C ABI，不定义 error enum / Result type，不进入 implementation。
- 当前 next opening 更新为 docs-only `P1 error strategy boundary execution card`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API 或 public C ABI。
- 不实现 error type / error enum / Result type。
- 不实现 app lifecycle、window lifecycle、platform adapter 或 handle table / generation。
- 不迁移 smoke `last_error`，不复用 smoke C ABI。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 error strategy boundary execution card`

- [2026-04-26-p1-error-strategy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-execution-card.md)

完成内容：

- 将 [2026-04-26-p1-error-strategy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-preflight.md) 收束成受限 docs-only execution card。
- 明确创建 execution card 不等于实现，不自动开启 runtime implementation。
- 明确 future first slice 最多只能做 `runtime/cjgui/src/error.cj` 和 / 或 `runtime/cjgui/README.md` 的 comment-only / documentation-level error strategy surface refinement。
- 明确 future first slice 不得写非注释仓颉语法，不得创建 package / build config，不得定义稳定函数签名、public runtime API 或 public C ABI。
- 明确不允许实现 error strategy，不允许定义 error enum / Result type / exception-like mechanism。
- 明确不允许迁移 smoke `last_error`、复用 smoke C ABI，或把 diagnostics 当成第二状态真相源。
- 明确 error strategy 只能描述失败 / degraded diagnostics，不能拥有 app state、window state、platform adapter truth 或 runtime public surface。
- 明确 future verification 必须检查 comment-only、无 package / build config、无 smoke C ABI reference、无 `last_error` API migration、无 public enum / Result type / function signature、diagnostics 未写成 state truth。
- 当前 next opening 更新为 `P1 error strategy surface comment-only refinement first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不定义 public runtime API 或 public C ABI。
- 不实现 error strategy、error enum、Result type 或 exception-like mechanism。
- 不迁移 smoke `last_error`，不复用 smoke C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter 或 handle table / generation。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 error strategy surface comment-only refinement first slice`

- [2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md)

完成内容：

- 只对 [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj) 和 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md) 做 comment-only / documentation-level refinement。
- 明确 error strategy owner、app lifecycle relation、window lifecycle relation、platform adapter relation、smoke `last_error` non-migration。
- 明确 future errors 必须是 structured / call-associated / non-global / concurrency-safe。
- 明确 fatal / recoverable / degraded / invalid usage / capability missing / stale handle 等最小分类词汇仍只是语义边界，不是 enum / Result type。
- 明确 fail-closed policy，以及 diagnostics 只能作为 evidence / closure review 辅助材料，不能成为第二状态真相源。
- `runtime/cjgui/src/error.cj` 仍为 comment-only；未新增 package / build config。
- smoke guard `verify_auto_close.sh` 通过。
- 当前 next opening 更新为 docs-only `P1 minimal runtime skeleton surface phase closure / compaction preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不写 runtime 行为代码。
- 不定义 public runtime API 或 public C ABI。
- 不实现 error strategy、error enum、Result type 或 exception-like mechanism。
- 不迁移 smoke `last_error`，不复用 smoke C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter 或 handle table / generation。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 minimal runtime skeleton surface phase closure / compaction preflight`

- [2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md)

完成内容：

- 复核 app lifecycle、window lifecycle、platform adapter、error strategy 四条 comment-only surface 已足够封账。
- 明确当前 minimal runtime skeleton surface phase 可以收束，且只收束为 comment-only architectural placeholder。
- 明确不建议继续拆更多 comment-only runtime surface，以免加剧治理反噬和上下文过载。
- 冻结当前阶段 truth：`runtime/` 独立于 `labs/`，smoke code / C ABI / diagnostics 不迁移，core 只消费脱水 facts，platform object 不泄露，diagnostics 不是第二状态真相源。
- 明确仍未实现 package / build entry、public API、public C ABI、app/window lifecycle、platform adapter、error strategy、handle table、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 和 offscreen renderer。
- 明确当前不创建 `CJGUI_TRUTH_MANIFEST.md`，只登记 future governance compaction / truth manifest preflight。
- 当前 next opening 更新为 docs-only `P1 runtime build/package boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不写非注释仓颉 runtime 代码。
- 不定义 public runtime API 或 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、error enum / Result type、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 runtime build/package boundary preflight`

- [2026-04-26-p1-runtime-build-package-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-preflight.md)

完成内容：

- 明确可以准备从 comment-only skeleton 进入可编译 runtime package skeleton，但必须先冻结 build / package boundary，不能直接实现。
- 冻结 future runtime package owner 应属于 `runtime/cjgui`，不属于 `labs/macos_bridge_smoke`、smoke build script、smoke C ABI 或 verification harness。
- 明确 package / module boundary 候选仍是 [runtime/cjgui](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui)，但具体 `cjpm` layout、metadata、module syntax、import syntax、visibility 和 build command 必须查证本地工具链文档、CangjieSkills 或官方文档。
- 明确 runtime package 不依赖 `labs/macos_bridge_smoke`；smoke guard 与 future runtime package build check 是并列验证轴，不能互相替代。
- 明确本轮不允许非注释仓颉语法、public runtime API、public C ABI 或 real behavior。
- 明确 future first slice 默认最多创建 package / build metadata 并保持 source comment-only；若工具链要求最小非注释 source，必须由 execution card 在查证后极窄授权。
- 当前 next opening 更新为 docs-only `P1 runtime build/package boundary execution card`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不写非注释仓颉 runtime 代码。
- 不定义 public runtime API 或 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、error enum / Result type、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 runtime build/package boundary execution card`

- [2026-04-26-p1-runtime-build-package-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-execution-card.md)

完成内容：

- 将 runtime build / package boundary preflight 收束成受限 execution card，创建本卡不等于实现。
- 明确唯一 authority 是 [2026-04-26-p1-runtime-build-package-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-preflight.md)。
- 明确 future first slice 最多只能创建最小 package / build metadata，并保持 runtime source comment-only。
- 明确 package owner 候选是 [runtime/cjgui](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui)。
- 明确 future first slice 必须先查证 `cjpm` / `cjc` layout、命令和语法，按需读取 setup 文档、CangjieSkills 和本地官方仓颉文档，不能凭模型记忆猜。
- 明确 future first slice 不得修改现有 `.cj` 文件为非注释代码，不得定义稳定函数签名 / public API，不得创建 runtime behavior。
- 明确禁止迁移 smoke code、smoke C ABI、smoke `last_error`，禁止 runtime package 依赖 `labs/macos_bridge_smoke`。
- 当前 next opening 更新为 `P1 runtime build/package metadata first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 package / build config。
- 不写非注释仓颉 runtime 代码。
- 不定义 public runtime API 或 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、error enum / Result type、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 runtime build/package metadata first slice`

- [2026-04-26-p1-runtime-build-package-metadata-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-metadata-closure-review.md)

完成内容：

- 按 [P1 runtime build/package boundary execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-execution-card.md) 执行极窄 metadata first slice。
- 查证本地 setup 文档、`cangjie-toolchains` skill 和 `cjpm` package 文档后，新增 [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。
- 更新 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)，明确 package / build metadata 不是 runtime behavior、public runtime API 或 public C ABI。
- 四个 `.cj` source 继续保持 comment-only，未写非注释仓颉 runtime code。
- `cjpm build` 已按查证命令执行，exit code 为 `1`，真实原因是 comment-only source 缺少 package declaration；本轮按 stop-line fail closed，未临时添加非注释 source。
- smoke guard `verify_auto_close.sh` 通过；forbidden source / harness / native bridge / 仓颉入口 hash 未变。
- 当前 next opening 更新为 docs-only `P1 runtime package metadata closure / first compilable source boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不写非注释仓颉 runtime 行为代码。
- 不定义 public runtime API 或 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、error enum / Result type、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不让 runtime package 依赖 `labs/macos_bridge_smoke`。
- 不修改 `labs/macos_bridge_smoke` source / harness / native bridge / 仓颉入口。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 runtime package metadata closure / first compilable source boundary preflight`

- [2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md)

完成内容：

- 复核 [P1 runtime build/package metadata closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-metadata-closure-review.md) 中 `cjpm build` 的真实失败原因。
- 查证仓颉 package declaration、`cjpm` package layout、static package 与 executable `main` 的边界。
- 明确当前失败不是 runtime failure，而是 `runtime/cjgui/src` 缺少与 `name = "cjgui"` 匹配的 package declaration。
- 基于“同一包所有文件须有相同 package declaration”的规则，默认不推荐只新增单个 package anchor；future first slice 更适合只给四个现有 `src/*.cj` 添加一致的 `package cjgui` declaration。
- 明确 future first slice 不允许函数、public runtime API、public C ABI、runtime behavior、`src/main.cj`、smoke dependency、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 或 offscreen renderer。
- 当前 next opening 更新为 docs-only `P1 first compilable runtime source execution card`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不写非注释仓颉语法。
- 不新增 package / build config。
- 不修改 `cjpm.toml`。
- 不定义函数签名、public runtime API 或 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、error enum / Result type、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 first compilable runtime source execution card`

- [2026-04-26-p1-first-compilable-runtime-source-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-execution-card.md)

完成内容：

- 将 [P1 first compilable runtime source boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md) 收束成受限 execution card。
- 明确创建 execution card 不等于实现，不自动开启 runtime implementation。
- 明确 future first slice 只能给四个现有 `runtime/cjgui/src/*.cj` 添加一致的 `package cjgui` declaration，且该 declaration 必须是每个文件第一条非空 / 非注释行。
- 明确 future first slice 不允许函数、类型、import、public runtime API、public C ABI 或 runtime behavior。
- 明确 future first slice 不新增 `src/main.cj`、不新增 `package_anchor.cj`、不修改 `cjpm.toml`。
- 明确 closure review 必须区分 `strict_comment_only=false`、`package_declaration_only=true`、`behavior_code_present=false`、`public_api_present=false`。
- 当前 next opening 更新为 `P1 first compilable runtime source first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`，除非用户明确批准下一条 first slice。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不写 runtime 行为代码。
- 不定义函数、类型、import、public runtime API 或 public C ABI。
- 不修改 `cjpm.toml`，不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、error enum / Result type、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 first compilable runtime source first slice`

- [2026-04-26-p1-first-compilable-runtime-source-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-execution-card.md)
- [2026-04-26-p1-first-compilable-runtime-source-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-review.md)

完成内容：

- 按 execution card 执行极窄 first slice，只给四个现有 `runtime/cjgui/src/*.cj` 添加一致的 `package cjgui` declaration。
- `package cjgui` 均为每个文件第 1 行，也是第一条非空 / 非注释行。
- 四个 `.cj` 文件当前状态为 `strict_comment_only=false`、`package_declaration_only=true`、`behavior_code_present=false`、`public_api_present=false`。
- `cjpm build --target-dir /tmp/cjgui-first-compilable-runtime-source-target --skip-script` 通过，退出码 `0`，关键输出 `cjpm build success`。
- 未新增 `src/main.cj`，未新增 `package_anchor.cj`，未修改 `cjpm.toml`。
- 未定义函数、类型、import、public runtime API、public C ABI 或 runtime behavior。
- 未迁移 smoke code / smoke C ABI / smoke `last_error`，runtime package 不依赖 `labs/macos_bridge_smoke`。
- smoke guard `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，退出码 `0`。
- 当前 next opening 更新为 docs-only `P1 first compilable runtime source closure / next implementation boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不修改 `cjpm.toml`。
- 不定义函数、类型、import、public runtime API 或 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、error enum / Result type、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 first compilable runtime source closure / next implementation boundary preflight`

- [2026-04-26-p1-first-compilable-runtime-source-closure-next-implementation-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-next-implementation-boundary-preflight.md)

完成内容：

- 复核 first compilable runtime source first slice 可以封账。
- 明确 `cjpm build success` 只证明 package identity / metadata / empty source package 可被工具链接受，不证明 runtime 能力。
- 明确不建议直接进入真实 runtime implementation。
- 判断下一条最合适的 docs-only opening 是 `P1 runtime visibility / internal symbol boundary preflight`。
- 明确在冻结 visibility / internal symbol boundary 前，不应定义函数、类型、public API、internal anchor、empty marker、import、public C ABI 或 runtime behavior。
- 明确 `P1 runtime empty internal anchor execution card` 还太早，必须先完成 visibility / internal symbol preflight。
- 当前 next opening 更新为 docs-only `P1 runtime visibility / internal symbol boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不写 runtime 代码。
- 不写非 package declaration 的仓颉语法。
- 不修改 `cjpm.toml`，不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不定义函数、类型、import、public runtime API 或 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、error enum / Result type、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 runtime visibility / internal symbol boundary preflight`

- [2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md)

完成内容：

- 查证仓颉 package / module / visibility / test 规则，确认 `package` 声明必须是第一条非空 / 非注释行，同包文件需相同 package declaration。
- 明确仓颉顶层 `private` / `internal` / `protected` / `public` 可见性：普通顶层声明默认 `internal`，`internal` 可见于当前包及子包，`public` 全局可见。
- 明确第一批 runtime 非 package declaration symbol 不应 public，不应定义 public runtime API、public C ABI、函数签名、empty marker、namespace-like anchor、import、error enum / Result type 或 runtime behavior。
- 明确 app lifecycle / window lifecycle / platform adapter / error strategy 的第一批 symbol 若未来获批，也只能保持 internal 或等价受限边界，服务 internal package sanity，而不是 public API。
- 明确未来 tests 访问 internal symbol 需要另开 test boundary preflight；本轮不新增 test source。
- 当前 next opening 更新为 docs-only `P1 runtime internal symbol boundary execution card`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不写 runtime 代码。
- 不写新的仓颉 symbol。
- 不修改 `cjpm.toml`，不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不定义函数、类型、import、public runtime API 或 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、error enum / Result type、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 runtime internal symbol boundary execution card`

- [2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md)

完成内容：

- 将 runtime visibility / internal symbol boundary preflight 收束成受限 execution card。
- 明确创建 execution card 不等于实现。
- 未来 first slice 最多只能定义一个普通默认 internal 的 compile sanity marker，用来验证 runtime package 可以承载非 public symbol。
- 明确 future write set 最多只允许一个 existing runtime source file、`runtime/cjgui/README.md`、future closure review、`docs/plans/README.md` 和本账本。
- 明确优先候选 runtime source 是 `runtime/cjgui/src/error.cj`，但 future slice 必须重新查证仓颉 marker 语法；如果无法安全落 marker，必须 fail closed。
- 明确 future closure 必须记录 `public_api_present=false`、`public_c_abi_present=false`、`behavior_code_present=false`、`internal_symbol_only=true`。
- 当前 next opening 更新为 `P1 runtime internal symbol boundary first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不写 runtime 代码。
- 不新增仓颉 symbol。
- 不修改 `cjpm.toml`，不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不定义函数、类型、import、public runtime API 或 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、error enum / Result type、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 runtime internal symbol boundary first slice`

- [2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md)
- [2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md)

完成内容：

- 按 execution card 执行极窄 first slice，只在 `runtime/cjgui/src/error.cj` 中新增一个默认 internal compile sanity marker：`CjguiInternalCompileSanityMarker`。
- 该 marker 是普通顶层 `struct`，不带 `public`，不定义函数，不写 import，不引用 smoke / FFI / platform object / AppKit / Metal / Objective-C。
- `runtime/cjgui/README.md` 已更新为 `internal symbol sanity surface`，记录 `public_api_present=false`、`public_c_abi_present=false`、`behavior_code_present=false`、`internal_symbol_only=true`、`function_present=false`、`import_present=false`。
- `cjpm build --target-dir /tmp/cjgui-runtime-internal-symbol-boundary-target --skip-script` 通过，退出码 `0`，关键输出 `cjpm build success`。
- smoke guard `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，退出码 `0`。
- 未修改 `cjpm.toml`，未新增 `src/main.cj` 或 `package_anchor.cj`，未修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 当前 next opening 更新为 docs-only `P1 runtime internal symbol closure / first internal type boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不定义 public runtime API 或 public C ABI。
- 不定义函数、import、error enum / Result type 或稳定行为 surface。
- 不实现 app lifecycle、window lifecycle、platform adapter、error strategy、handle table / generation。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Dirty Rect / global tick / frame scheduler、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 runtime internal symbol closure / first internal type boundary preflight`

- [2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md)

完成内容：

- 复盘 `P1 runtime internal symbol boundary first slice` 可以封账。
- 明确 `CjguiInternalCompileSanityMarker` 只证明 `runtime/cjgui` 可以承载默认 internal symbol 并通过 build，不证明 runtime capability、runtime domain type、public API 或行为。
- 明确该 marker 不应被视为 runtime domain type，只是 compile sanity marker。
- 判断下一步不应直接实现第一个有语义的 internal type，应先创建 docs-only execution card。
- 比较 app lifecycle state、window lifecycle state、platform facts、error facts 四类候选，判断 `internal error facts boundary` 风险相对最低，但仍禁止 error enum / Result type / diagnostics-as-state-truth。
- 继续禁止 public、import、function、runtime behavior、`cjpm.toml` 修改、`src/main.cj`、`package_anchor.cj`、public runtime API / public C ABI、handle table / generation、platform object wrapper、Renderer / Scene / Widget / Layout / DSL。
- 当前 next opening 更新为 docs-only `P1 first internal runtime type execution card`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不写 runtime 代码。
- 不定义新的仓颉 type / function / import。
- 不定义 public runtime API 或 public C ABI。
- 不实现 app/window/platform/error behavior。
- 不进入 handle table / generation、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 first internal runtime type execution card`

- [2026-04-26-p1-first-internal-runtime-type-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-execution-card.md)

完成内容：

- 将 first internal type boundary preflight 收束成受限 execution card。
- 明确创建本卡不等于实现，不自动开启 runtime implementation。
- 明确 future first slice 最多只能在 `runtime/cjgui/src/error.cj` 定义一个默认 internal、无行为、无 `public`、无 `import`、无 public runtime API / public C ABI 的最小 error-facts type。
- 明确第一候选边界是 `internal error facts boundary`，但不能实现 error strategy、error enum、`Result` type 或 exception-like 机制。
- 明确 future first slice 必须先查证仓颉 type / visibility / package 规则，优先使用 CangjieSkills / 本地官方文档。
- 继续禁止函数、方法、构造逻辑、runtime behavior、handle、handle table、generation、多窗口、async target message、AppKit / Metal / Objective-C platform object wrapper、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash、pixel diff、baseline、offscreen renderer、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj` 和 smoke 迁移。
- 当前 next opening 更新为 `P1 first internal runtime type first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不写 runtime 代码。
- 不定义新的仓颉 type / function / method / import。
- 不定义 public runtime API 或 public C ABI。
- 不实现 app/window/platform/error behavior。
- 不进入 handle table / generation、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 first internal runtime type first slice`

- [2026-04-26-p1-first-internal-runtime-type-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-execution-card.md)
- [2026-04-26-p1-first-internal-runtime-type-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-review.md)

完成内容：

- 在 `runtime/cjgui/src/error.cj` 新增默认 internal `CjguiInternalErrorFact`。
- `CjguiInternalErrorFact` 只作为 future internal error facts boundary 的 compile-level placeholder。
- 同步轻量更新 `runtime/cjgui/README.md`，记录 first internal error fact type surface。
- `public_api_present=false`。
- `public_c_abi_present=false`。
- `behavior_code_present=false`。
- `function_present=false`。
- `import_present=false`。
- `error_enum_present=false`。
- `result_type_present=false`。
- `platform_object_wrapper_present=false`。
- `cjpm_toml_changed=false`。
- `smoke_changed=false`。
- `cjpm build --target-dir /tmp/cjgui-first-internal-runtime-type-target --skip-script` 通过，退出码 `0`。
- smoke guard `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，退出码 `0`。
- 当前 next opening 更新为 docs-only `P1 first internal runtime type closure / error fact shape boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不写 `public` declaration、import、函数、方法、字段或用户定义构造逻辑。
- 不定义 public runtime API 或 public C ABI。
- 不实现 app/window/platform/error behavior。
- 不进入 error enum / Result type、handle table / generation、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 first internal runtime type closure / error fact shape boundary preflight`

- [2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md)

完成内容：

- 复盘 `CjguiInternalErrorFact` 是否可以封账。
- 明确 `CjguiInternalErrorFact` 只证明 `runtime/cjgui` 可以承载一个默认 internal、无行为、无 public / import / public API / public C ABI 的 first internal error facts boundary type。
- 明确它不是 error strategy，不证明 error taxonomy、Result type、exception-like mechanism、diagnostics truth、app/window/platform behavior 或 public API。
- 明确当前不得给 `CjguiInternalErrorFact` 添加字段；添加字段前必须先冻结 code taxonomy、message ownership、source module、correlation id、lifetime、threading、serialization、privacy 和 diagnostics relationship。
- 明确 diagnostics / logs 只能作为 evidence，不能成为第二状态真相源。
- 明确 smoke `last_error` 仍不能迁移为 runtime error system，只能迁移“错误需要结构化、调用关联、非全局、并发安全、可观察”的经验。
- 当前 next opening 更新为 docs-only `P1 error fact shape execution card`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`。
- 不写 runtime 代码。
- 不修改 `CjguiInternalErrorFact`，不新增字段。
- 不新增 type、function 或 import。
- 不定义 error enum、Result type、exception-like mechanism、public runtime API 或 public C ABI。
- 不实现 error strategy、app/window/platform behavior。
- 不进入 handle table / generation、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 error fact shape execution card`

- [2026-04-26-p1-error-fact-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-execution-card.md)

完成内容：

- 将 error fact shape boundary preflight 收束成受限 execution card。
- 明确创建本卡不等于实现，不自动开启 runtime implementation。
- 明确未来 first slice 最多只能围绕 `CjguiInternalErrorFact` 做一个极窄 internal error fact shape refinement。
- 明确该 shape 不是 error strategy、public API、public C ABI、error enum、`Result` type、exception-like mechanism、diagnostics truth system 或 smoke `last_error` 迁移。
- 明确 diagnostics / logs 只能作为 evidence，不能成为第二状态真相源。
- 明确未来 shape 必须保持默认 internal，必须脱水，并继续禁止 platform object、raw pointer、opaque native error object、stack trace blob、global / thread-local `last_error`、AppKit / Metal / Objective-C、handle / generation、多窗口、async target message、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 和 offscreen renderer。
- 明确未来 first slice 修改前必须查证 CangjieSkills / 本地官方文档中的 struct field、visibility、initialization 和 build 规则。
- 明确未来 first slice 修改前必须记录 taxonomy、message ownership、source module、correlation id、lifetime、threading、serialization、privacy 默认均为 absent / not yet defined。
- 当前 next opening 更新为 `P1 error fact shape first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`。
- 不写 runtime 代码。
- 不修改 `CjguiInternalErrorFact`，不新增字段。
- 不新增 type、function 或 import。
- 不定义 error enum、Result type、exception-like mechanism、public runtime API 或 public C ABI。
- 不实现 error strategy、app/window/platform behavior。
- 不迁移 smoke `last_error`。
- 不进入 handle table / generation、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 error fact shape first slice`

- [2026-04-26-p1-error-fact-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-execution-card.md)
- [2026-04-26-p1-error-fact-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md)

完成内容：

- 在 `runtime/cjgui/src/error.cj` 中只修改现有 `CjguiInternalErrorFact`。
- 新增唯一默认 internal 不可变字段：`hasNativePayload: Bool = false`。
- 该字段只表示当前 error fact 不携带 native payload，只证明最小脱水 shape 可编译。
- 该字段不定义 error taxonomy、message ownership、source module、correlation id、lifetime、threading、serialization、privacy、error strategy 或 diagnostics truth system。
- `public_api_present=false`、`public_c_abi_present=false`、`behavior_code_present=false`、`function_present=false`、`method_present=false`、`explicit_init_present=false`、`import_present=false`。
- `error_enum_present=false`、`result_type_present=false`、`exception_like_mechanism_present=false`、`smoke_last_error_migrated=false`。
- `platform_object_present=false`、`raw_pointer_present=false`、`opaque_native_error_object_present=false`、`stack_trace_blob_present=false`、`global_last_error_present=false`、`thread_local_last_error_present=false`、`appkit_metal_objective_c_reference_present=false`。
- `cjpm build --target-dir /tmp/cjgui-error-fact-shape-target --skip-script` 通过，退出码 `0`。
- smoke guard `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，退出码 `0`。
- `cjpm.toml` / smoke / harness / native bridge / 仓颉入口未修改。
- 当前 next opening 更新为 docs-only `P1 error fact shape closure / error taxonomy boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不新增其他字段。
- 不使用 `public`。
- 不新增 import、函数、方法或显式 init。
- 不定义 error enum、Result type、exception-like mechanism、public runtime API 或 public C ABI。
- 不实现 error strategy、app/window/platform behavior。
- 不迁移 smoke `last_error`。
- 不进入 handle table / generation、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 error fact shape closure / error taxonomy boundary preflight`

- [2026-04-26-p1-error-fact-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md)
- [2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md)

完成内容：

- 复盘 P1 error fact shape first slice 可以封账。
- 确认 `hasNativePayload: Bool = false` 只证明最小脱水 fact 字段可编译，不证明 error taxonomy、error strategy、error enum、Result type、public runtime API、public C ABI 或 diagnostics truth system。
- 确认 `CjguiInternalErrorFact` 当前仍不是 error strategy。
- 确认当前仍没有 error taxonomy。
- 明确不能直接定义 error enum、Result type、severity / category / code 字段。
- 冻结 future taxonomy owner 倾向属于 `runtime/cjgui` error strategy module，但本轮不实现 owner。
- 明确 taxonomy 与 app lifecycle / window lifecycle / platform adapter 只应交换脱水 failure facts，不能拥有 app/window/platform state 或平台对象。
- 明确 diagnostics / logs 只能作为 evidence，不能成为第二状态真相源。
- 明确 smoke `last_error` 只能迁移经验，不能迁移形态、C ABI、全局状态或字符串 taxonomy。
- 当前 next opening 更新为 docs-only `P1 error taxonomy boundary execution card`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`。
- 不写 runtime 代码。
- 不修改 `CjguiInternalErrorFact`，不新增字段。
- 不新增 type、function 或 import。
- 不定义 error enum、Result type、severity / category / code 字段、public runtime API 或 public C ABI。
- 不实现 error strategy、app/window/platform behavior。
- 不迁移 smoke `last_error`。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 error taxonomy boundary execution card`

- [2026-04-26-p1-error-taxonomy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-boundary-execution-card.md)

完成内容：

- 将 error taxonomy boundary preflight 收束成受限 execution card。
- 明确创建本卡不等于实现，不自动开启 runtime implementation。
- 明确 future taxonomy owner 倾向属于 `runtime/cjgui` error strategy module，但当前仍不是 error strategy implementation。
- 明确 future first slice 最多只能在 `runtime/cjgui/src/error.cj` 新增一个默认 internal、无行为、无 public、无 import 的 taxonomy marker / placeholder。
- 明确 marker 只能表达 taxonomy boundary exists but taxonomy is not yet defined。
- 继续禁止完整 taxonomy、error enum、Result type、exception-like mechanism、severity / category / code 字段、修改 `CjguiInternalErrorFact`、public runtime API、public C ABI、diagnostics truth system、smoke `last_error` 迁移、platform object / raw pointer / native error object、handle / generation、多窗口、async target message、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 当前 next opening 更新为 `P1 error taxonomy marker first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`。
- 不写 runtime 代码。
- 不修改 `CjguiInternalErrorFact`，不新增 type / function / import。
- 不定义完整 taxonomy、error enum、Result type、severity / category / code 字段、public runtime API 或 public C ABI。
- 不实现 error strategy、app/window/platform behavior。
- 不迁移 smoke `last_error`。
- 不进入 handle table / generation、多窗口、async target message、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 error taxonomy marker first slice`

- [2026-04-26-p1-error-taxonomy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-boundary-execution-card.md)
- [2026-04-26-p1-error-taxonomy-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-review.md)

完成内容：

- 在 `runtime/cjgui/src/error.cj` 中新增默认 internal 空 marker：`CjguiInternalErrorTaxonomyMarker`。
- 该 marker 只表达 taxonomy boundary exists but taxonomy is not yet defined。
- 同步轻量更新 `runtime/cjgui/README.md`，记录 taxonomy marker boundary。
- `taxonomy_marker_added=true`。
- `taxonomy_defined=false`。
- `error_enum_present=false`。
- `result_type_present=false`。
- `severity_field_present=false`。
- `category_field_present=false`。
- `code_field_present=false`。
- `error_fact_modified=false`。
- `public_api_present=false`。
- `public_c_abi_present=false`。
- `behavior_code_present=false`。
- `function_present=false`、`method_present=false`、`explicit_init_present=false`、`import_present=false`。
- `diagnostics_truth_system_present=false`、`smoke_last_error_migrated=false`。
- `cjpm build --target-dir /tmp/cjgui-error-taxonomy-marker-target --skip-script` 通过，退出码 `0`。
- smoke guard `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，退出码 `0`。
- `cjpm.toml` / smoke / harness / native bridge / 仓颉入口未修改。
- 当前 next opening 更新为 docs-only `P1 error taxonomy marker closure / recoverability boundary preflight`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不修改 `CjguiInternalErrorFact`。
- 不新增字段。
- 不使用 `public`。
- 不新增 import、函数、方法或显式 init。
- 不定义完整 taxonomy、error enum、Result type、severity / category / code 字段、exception-like mechanism、public runtime API 或 public C ABI。
- 不实现 error strategy、app/window/platform behavior。
- 不迁移 smoke `last_error`。
- 不进入 handle table / generation、多窗口、async target message、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 error taxonomy marker closure / recoverability boundary preflight`

- [2026-04-26-p1-error-taxonomy-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-review.md)
- [2026-04-26-p1-error-taxonomy-marker-closure-recoverability-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-recoverability-boundary-preflight.md)

完成内容：

- 复盘 P1 error taxonomy marker first slice 可以封账。
- 明确 `CjguiInternalErrorTaxonomyMarker` 只证明 taxonomy boundary marker 可构建。
- 明确当前仍没有 error taxonomy，也没有 recoverability policy。
- 冻结 recoverability 与 taxonomy、error strategy、app lifecycle、window lifecycle、platform adapter、diagnostics / logs 的关系。
- 明确 diagnostics / logs 只能作为 evidence，不能成为第二状态真相源。
- 明确不能直接定义 recoverable / fatal / degraded enum、severity / category / code 字段或 `Result` type。
- 明确不能修改 `CjguiInternalErrorFact` 或 `CjguiInternalErrorTaxonomyMarker`。
- 明确 future recoverability owner 倾向属于 `runtime/cjgui` error strategy module，但当前仍不是 error strategy implementation。
- 原 current next opening 曾更新为 docs-only `P1 error recoverability boundary execution card`；2026-04-27 治理出口修正后，该结论被收窄替换为 code-first `P1 error recoverability bounded implementation first slice`。

当前 stop-line 仍然有效：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`。
- 不写 runtime 代码。
- 不修改 `CjguiInternalErrorFact` 或 `CjguiInternalErrorTaxonomyMarker`。
- 不新增字段、type、function 或 import。
- 不定义 recoverability enum、fatal / recoverable / degraded enum、severity / category / code 字段、`Result` type、public runtime API 或 public C ABI。
- 不实现 error strategy、app/window/platform behavior。
- 不迁移 smoke `last_error`。
- 不进入 Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 self-drawn platform reduction / IME / accessibility guardrails preflight`

- [2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md)

完成内容：

- 接收“自绘降维”和“IME 隔离”相关外部盲点输入。
- 判断自绘路线可以降低平台原生控件耦合，但不能免除 platform adapter 对窗口管理器、DPI、resize、compositor、IME 和 accessibility 的责任。
- 明确 `final committed string only` 只能作为 future early IME isolation candidate，不能成为完整输入系统 contract。
- 明确默认不允许 global tick / blind redraw；未来 redraw 应 event / invalidation / dirty region driven，animation frame scheduling 必须另开 preflight。
- 登记 future slots：redraw invalidation / dirty rect policy、scroll physics and text rendering backend boundary、IME composition isolation / cursor rect sync、accessibility semantic bridge。
- 当前 next opening 不变，仍是 docs-only `P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight`。

当前 stop-line 仍然有效：

- 不写 runtime 代码。
- 不修改 runtime skeleton。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不实现 Dirty Rect / invalidation system。
- 不实现 global tick / frame scheduler。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 ScrollView / Text / Input / IME。
- 不实现 Accessibility / semantic tree / Action Router。

### `P1 minimal app/window lifecycle runtime execution card`

- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md)

完成内容：

- 将 minimal app / window lifecycle runtime boundary preflight 收束成受限 execution card。
- 吸收 red-team guardrails：不扩大每轮必读历史文档集、不创建 `CJGUI_TRUTH_MANIFEST.md`、不进入 pixel diff / baseline / command-list hash、隔离 AppKit event loop 与 core runtime truth、不实现 semantic tree / Action Router。
- 明确未来 first slice 最多只能创建最小 runtime skeleton / app-window lifecycle surface。
- 明确推荐新 runtime 目录为 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/`，但本轮不创建目录。
- 明确不允许复用 `labs/macos_bridge_smoke`、不直接升格 smoke C ABI、不暴露平台对象、不实现真实 app / window lifecycle、不进入 Renderer / Scene / Widget / Layout / DSL。
- 明确 handle table / generation、multi-window、target update、Renderer / Scene、command-list evidence、semantic projection 都保留为 future slot。
- 当前 next opening 更新为 `P1 minimal app/window lifecycle runtime skeleton bounded implementation first slice`，但不自动开启实现。

当前 stop-line 仍然有效：

- 不写 runtime 代码。
- 不创建 runtime 目录。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不实现 app lifecycle、window lifecycle、handle table / generation、Renderer / Scene / Widget / Layout / DSL。
- 不实现 command-list hash、semantic tree / Action Router、pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 red-team risk intake / runtime guardrails preflight`

- [2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)

完成内容：

- 接收第三方红队提出的四类结构性风险：治理反噬、像素哈希陷阱、macOS runloop / AppKit 过拟合、AI semantic tree 热路径性能陷阱。
- 判断治理反噬是最近真实风险，登记 future opening：`P1 governance compaction / truth manifest preflight`。
- 判断像素哈希陷阱已被当前 `hash_value_persistence_allowed=false`、`baseline_allowed=false`、`pixel_diff_allowed=false` 防线部分覆盖；登记 future opening：`P1 render evidence model / command list hash preflight`，但不提前打开 Renderer / Display List。
- 判断 macOS runloop / AppKit 过拟合必须进入下一张 runtime execution card：platform adapter 可以拥有 AppKit event loop，core runtime 不得持有 `NSRunLoop` / `NSEvent` / `dispatch_main` truth。
- 判断 AI semantic tree 性能风险应登记为 future invariant：semantic projection 默认 cold / lazy / on-demand，render hot path 不维护完整 semantic tree，semantic dirty 与 render dirty 未来必须分离。
- 当前 next opening 不变，仍是 `P1 minimal app/window lifecycle runtime execution card`，但该卡必须吸收本轮 guardrails。

当前 stop-line 仍然有效：

- 不写 runtime 代码。
- 不创建 runtime 目录。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不实现 command list / display list、semantic tree / Action Router、pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

### `P1 minimal app/window lifecycle runtime boundary preflight`

- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md)

完成内容：

- 明确 future runtime app owner 应属于未来正式 runtime app lifecycle module，不属于 smoke bridge 或示例入口。
- 明确 future runtime window lifecycle owner 应属于未来正式 runtime window lifecycle module，平台 bridge 只负责内部平台对象。
- 明确 main-thread event loop / queue owner 应归 future app lifecycle runtime，后台 / async / Agent action 不得直接写 UI。
- 明确不允许直接复用 smoke C ABI、smoke 目录或平台对象裸指针作为 public runtime API。
- 明确 create / close / destroy 最小 contract 倾向：create window 返回受控 handle，request close 经主线程 drain，destroy / release 走单一幂等路径，destroyed 后 stale message 丢弃或返回结构化错误。
- 明确 handle table / generation 是 future runtime 需要的能力，但 single-window first slice 若不暴露 public handle、不做 target update、不做多窗口，可以先不实现。
- 明确第一刀继续 single-window，multi-window、target routing、handle generation 属于 future slot。
- 明确 smoke `last_error` 只能迁移为错误策略经验，future runtime 需要结构化、调用关联、非全局并发安全的错误策略。
- 明确 smoke guard 继续验证旧链路不退化，但不是正式 runtime test framework。
- 明确第一条 runtime opening 不包含 Renderer / Scene / Widget / Layout / DSL。
- 明确创建 runtime 目录前必须先有 execution card。
- 推荐下一篇 docs-only opening 为 `P1 minimal app/window lifecycle runtime execution card`。

当前 stop-line 仍然有效：

- 不写 runtime 代码。
- 不创建 runtime 目录。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不实现 app lifecycle、window lifecycle 或 handle table / generation。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象、文本 / 输入法 / 无障碍、AI semantic tree / Action Router。
- 不做 pixel diff / baseline / offscreen renderer。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 smoke-to-runtime boundary preflight`

- [2026-04-26-p1-smoke-to-runtime-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)

完成内容：

- 明确 `labs/macos_bridge_smoke` 继续定位为实验室 smoke，不是正式 runtime。
- 明确不再继续把 smoke demo 扩写成 framework。
- 明确 smoke 的目录结构、build script、C ABI 形态、单实例全局状态、auto-close、clear-color render path、diagnostics 字段、`last_error` 全局语义和 verification harness 都不能直接迁移为 runtime。
- 明确可迁移的是约束：macOS UI 主线程 owner、async UI 更新必须经主线程 queue / drain、受控 close / destroy、平台对象隐藏、实验期 `last_error` 不能扩展为长期并发错误系统、verification harness 只能作为 smoke guard。
- 明确当前 verification harness 不是正式 runtime test framework。
- 明确未来正式 runtime 倾向另开新目录，但本轮不创建目录。
- 该 opening 推荐的 `P1 minimal app/window lifecycle runtime boundary preflight` 已由上方最新 docs-only opening 完成。

当前 stop-line 仍然有效：

- 不写 runtime 代码。
- 不创建正式 runtime 目录。
- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象、文本 / 输入法 / 无障碍、AI semantic tree / Action Router。
- 不做 pixel diff / baseline / offscreen renderer。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash verification evidence line closure / runtime pivot preflight`

- [2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md)

完成内容：

- 复核 automated GUI verification、frame metadata / render stats、Metal readback、user-visible screenshot、artifact retention、frame hash feasibility、baseline readiness、baseline owner policy、source normalization readiness 和 bounds / crop semantics readiness diagnostics 的整条 evidence line。
- 明确当前 screenshot / frame hash verification 线可以暂时收口。
- 明确不继续新增 scale / color space / pixel format / timing / CI-headless / pixel diff / baseline 的细分 slice。
- 明确当前验证护栏已经足够支持回到 runtime 边界讨论，但不足以支持 pixel diff、baseline、full visual regression 或正式 runtime API。
- 该 opening 推荐的 `P1 smoke-to-runtime boundary preflight` 已由上方最新 docs-only opening 完成。

当前 stop-line 仍然有效：

- 不写 runtime 代码。
- 不修改 harness 或 `labs/macos_bridge_smoke`。
- 不实现 bounds normalization、content interior extraction、baseline / golden hash、baseline compare、pixel diff 或 offscreen renderer。
- 不保存或输出 hash value，不读取或输出 raw bytes，不保存成功 screenshot artifact。
- 不修改 native bridge、仓颉入口，不新增 public C ABI / runtime API。
- 不进入 Renderer / Scene / Widget / Layout / DSL，不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

最近完成的 bounded implementation opening：

### `P1 frame hash bounds / crop semantics readiness diagnostics bounded implementation first slice`

- [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md)
- [2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md)

完成内容：

- 只在现有 screenshot verification harness 内增加 bounds / crop semantics readiness diagnostics summary。
- 实际日志输出 `requested=true`、`source=target_window_screenshot_crop`、`source_truth=user_visible_screenshot`、`screen_bounds_points_observed=true`、`capture_bounds_pixels_observed=true`、`target_window_crop_bounds_observed=true`、`content_interior_bounds_observed=false`、`hash_input_bounds_defined=false`、`point_pixel_conversion_defined=false`、`rounding_policy_defined=false`、`decoration_policy_defined=false`、`content_interior_extraction_allowed=false`、`whole_window_crop_baseline_allowed=false`、`source_normalized=false`、`baseline_allowed=false`、`hash_value_persistence_allowed=false`、`pixel_diff_allowed=false` 和 `success=true reason=none`。
- 原有 screenshot verification、frame hash feasibility、source normalization readiness、artifact cleanup、artifact lifecycle 和 auto-close harness 语义仍通过验证。

当前 stop-line 仍然有效：

- 不实现真正 bounds normalization。
- 不实现 content interior extraction。
- 不把 `content_interior_bounds` 宣称为当前可用 source。
- 不把 `target_window_crop_bounds` 或 whole window crop 升级为 baseline input contract。
- 不修改 capture 行为、artifact lifecycle、frame hash feasibility、baseline readiness 或 source normalization readiness。
- 不修改 native bridge、仓颉入口、build script、auto-close harness 或 screenshot feasibility harness。
- 不新增 public C ABI 或 public runtime API。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash source normalization readiness diagnostics bounded implementation first slice`

- [2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md)
- [2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md)

完成内容：

- 只在现有 screenshot verification harness 内增加 source normalization readiness diagnostics summary。
- 实际日志输出 `requested=true`、`source=target_window_screenshot_crop`、`source_truth=user_visible_screenshot`、`source_normalized=false`、`blocked_reason=source_policy_incomplete`、`bounds_policy_defined=false`、`scale_policy_defined=false`、`color_space_defined=false`、`pixel_format_defined=false`、`decoration_policy_defined=false`、`timing_policy_defined=false`、`ci_headless_supported=false`、`baseline_allowed=false`、`hash_value_persistence_allowed=false`、`pixel_diff_allowed=false` 和 `success=true reason=none`。
- 原有 screenshot verification、frame hash feasibility、baseline readiness、baseline owner policy、artifact cleanup、artifact lifecycle 和 auto-close harness 语义仍通过验证。

当前 stop-line 仍然有效：

- 不实现真正 source normalization。
- 不把 `source_normalized` 改成 `true`。
- 不修改 native bridge、仓颉入口、build script、auto-close harness 或 screenshot feasibility harness。
- 不新增 public C ABI 或 public runtime API。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash baseline owner / update policy bounded implementation first slice`

- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md)
- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md)

完成内容：

- 只在现有 screenshot verification harness 内增加 owner / update policy diagnostics summary。
- 实际日志输出 `owner_required=human_architect_or_maintainer`、`owner_runtime_api=false`、`ai_owner_allowed=false`、`ai_auto_update_allowed=false`、`proposal_required=true`、`human_approval_required=true`、`approval_flow_runtime_api=false`、`baseline_allowed=false`、`hash_value_persistence_allowed=false`、`baseline_compare_allowed=false`、`pixel_diff_allowed=false` 和 `success=true reason=none`。
- baseline readiness 仍保持 `baseline_allowed=false`、`baseline_owner_defined=false`、`baseline_update_policy_defined=false`、`human_review_required=true` 和 `ai_auto_update_allowed=false`。
- 原有 screenshot verification、frame hash feasibility、baseline readiness、artifact cleanup、artifact lifecycle 和 auto-close harness 语义仍通过验证。

当前 stop-line 仍然有效：

- 不修改 native bridge、仓颉入口、build script、auto-close harness 或 screenshot feasibility harness。
- 不新增 public C ABI 或 public runtime API。
- 不保存 hash value。
- 不输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不保存 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash baseline-readiness diagnostics bounded implementation first slice`

- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md)
- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)

完成内容：

- 只在现有 screenshot verification harness 内增加 baseline readiness diagnostics summary。
- source 继续只选择 `target_window_screenshot_crop`。
- source truth 继续只声明为 `user_visible_screenshot`。
- 实际日志输出 `baseline_allowed=false`、`baseline_blocked_reason=baseline_policy_incomplete`、`human_review_required=true`、`ai_auto_update_allowed=false`、`hash_value_persistence_allowed=false`、`pixel_diff_allowed=false` 和 `success=true reason=none`。
- 成功路径仍输出 `artifact_deleted=true`、`artifact_retained=false`。
- 原有 frame hash feasibility summary 仍输出 `hash_computed=true`、`hash_persisted=false`、`hash_value_logged=false`、`baseline_compared=false`。
- 原有 auto-close harness 仍通过。

当前 stop-line 仍然有效：

- 不修改 native bridge、仓颉入口、build script、auto-close harness 或 screenshot feasibility harness。
- 不新增 public C ABI 或 public runtime API。
- 不保存 hash value。
- 不输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不保存 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash feasibility bounded implementation first slice`

- [2026-04-25-p1-frame-hash-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-execution-card.md)
- [2026-04-25-p1-frame-hash-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)

完成内容：

- 只在现有 screenshot verification harness 内增加 frame hash feasibility summary。
- source 只选择 `target_window_screenshot_crop`。
- source truth 只声明为 `user_visible_screenshot`，不等同于 Metal readback truth。
- hash 只作为当前运行内 feasibility summary，算法为 `sha256`。
- 实际日志输出 `hash_computed=true`、`hash_persisted=false`、`hash_value_logged=false`、`baseline_compared=false`、`success=true reason=none`。
- 成功路径仍输出 `artifact_deleted=true`、`artifact_retained=false`。
- 原有 auto-close harness 仍通过。

当前 stop-line 仍然有效：

- 不修改 native bridge、仓颉入口、build script、auto-close harness 或 screenshot feasibility harness。
- 不新增 public C ABI 或 public runtime API。
- 不保存成功 screenshot artifact。
- 不提交 screenshot artifact。
- 不保存 raw bytes。
- 不建立 baseline / golden image。
- 不做 pixel diff、threshold diff、region diff 或 baseline compare。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 screenshot artifact retention bounded implementation first slice`

- [2026-04-25-p1-screenshot-artifact-retention-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-execution-card.md)
- [2026-04-25-p1-screenshot-artifact-retention-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md)

完成内容：

- 只修改现有 screenshot verification harness 的 artifact retention / cleanup policy。
- 成功 artifact 继续默认删除，当前成功路径输出 `artifact_deleted=true`、`artifact_retained=false`。
- 失败且 artifact 已创建时允许短期保留，并输出保留原因、failure classification、路径、24 小时 TTL 和删除策略。
- harness 启动时只清理超过 24 小时的 `/tmp/cjgui-p1-screenshot-verification.*` 历史临时目录。
- cleanup 不删除任意 `/tmp` 内容，不跟随 symlink，不删除当前运行实例临时目录。
- 本轮验证中受控 stale 目录被清理，summary 输出 `cleanup_requested=true`、`cleanup_pattern=/tmp/cjgui-p1-screenshot-verification.*`、`cleanup_ttl_hours=24`、`cleanup_deleted_count=1`。
- 原有 auto-close harness 仍通过。

当前 stop-line 仍然有效：

- 不修改 native bridge、仓颉入口、build script、auto-close harness 或 screenshot feasibility harness。
- 不新增 public C ABI 或 public runtime API。
- 不保存成功 screenshot artifact。
- 不提交 screenshot artifact。
- 不建立 baseline / golden image。
- 不做 pixel diff、frame hash 或 offscreen renderer。
- 不读取整图像素或输出 raw bytes。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 user-visible window screenshot verification bounded implementation first slice`

- [2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md)
- [2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)

完成内容：

- 新增独立 harness：`labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`。
- harness 调用现有 `build_and_run.sh`，等待 `window created`、`metal setup complete`、`first frame rendered` readiness 日志。
- readiness 达成后，记录 smoke process id，并通过 CoreGraphics window list 匹配 owner pid、title 和 bounds。
- harness 使用 CoreGraphics 对目标 bounds 做一次 on-screen capture，临时写入 `/tmp/cjgui-p1-screenshot-verification.XXXXXX/target-window.png`。
- harness 使用 `NSBitmapImageRep` 只读取目标截图中心附近 `3x3` clear-color sample，并输出脱水 summary。
- 当前本机结果为 `success=true reason=none`，`sample_points=9`，`sample_match=true`。
- 成功后默认删除 artifact 和临时目录；本轮实际为 `artifact_deleted=true`、`artifact_retained=false`。

当前 stop-line 仍然有效：

- 不提交 screenshot artifact。
- 不建立 baseline。
- 不读取整图像素或输出 raw bytes。
- 不做 pixel diff、frame hash 或 offscreen renderer。
- 不新增 public C ABI 或 public runtime API。
- 不修改 `cjgui_macos.m`、`cjgui_macos.h`、`src/main.cj`、`build_and_run.sh` 或 `verify_auto_close.sh`。
- 不把 screenshot verification first slice 宣称为完整视觉验证、CI / headless proof、Renderer / Scene 设计或正式 GUI runtime。

### `P1 user-visible window screenshot feasibility bounded implementation first slice`

- [2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md)
- [2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md)

完成内容：

- 新增独立 harness：`labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`。
- harness 调用现有 `build_and_run.sh`，等待 `window created`、`metal setup complete`、`first frame rendered` readiness 日志。
- readiness 达成后，通过 `osascript -l JavaScript` 调用 CoreGraphics `CGWindowListCreateImage` 请求一次 on-screen image feasibility probe。
- harness 只输出脱水 summary：`requested=true`、`image_created=true`、`success=true reason=none`。
- 当前本机结果为 `success=true reason=none`，但该结果只证明可以请求并创建一次 screenshot image object。

当前 stop-line 仍然有效：

- 不保存 screenshot artifact。
- 不读取或比较像素颜色。
- 不做 full screenshot verification。
- 不做 pixel diff、frame hash 或 offscreen renderer。
- 不新增 public C ABI 或 public runtime API。
- 不修改 `cjgui_macos.m`、`cjgui_macos.h`、`src/main.cj`、`build_and_run.sh` 或 `verify_auto_close.sh`。
- 不把 screenshot feasibility 宣称为用户可见窗口像素正确、compositor 正确或正式 GUI runtime 测试框架。

### `P1 Metal readback feasibility bounded implementation first slice`

- [2026-04-25-p1-metal-readback-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-execution-card.md)
- [2026-04-25-p1-metal-readback-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)

完成内容：

- `labs/macos_bridge_smoke/native/cjgui_macos.m` 只新增 smoke bridge 内部 single-frame clear-color Metal readback feasibility probe。
- readback 发生在 command buffer completion 之后，当前仅在 diagnostics first frame 使用 `waitUntilCompleted` 作为实验期同步点。
- readback 使用 bridge 内部临时 staging buffer，只输出脱水 summary。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 继续验证原有 auto-close / capability / metadata needle，并新增 readback summary needle。
- 当前 readback summary 字段包括 requested、command_buffer_completed、source、clear_color_match、success 和 degraded。
- harness 继续明确这不是用户可见窗口验证；本 slice 也不证明 compositor / display presentation 正确。

当前 stop-line 仍然有效：

- 不保存 raw pixel bytes。
- 不生成 screenshot artifact。
- 不做 window screenshot。
- 不做 frame hash。
- 不做 pixel diff。
- 不做 offscreen renderer。
- 不新增 public C ABI 或 public runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不暴露 AppKit / Metal / Objective-C 平台对象指针。
- 不把 readback summary 宣称为用户可见窗口验证。

### `P1 frame metadata / render stats bounded implementation first slice`

- [2026-04-25-p1-frame-metadata-render-stats-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-execution-card.md)
- [2026-04-25-p1-frame-metadata-render-stats-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)

完成内容：

- `labs/macos_bridge_smoke/native/cjgui_macos.m` 只新增 smoke bridge 内部脱水 frame metadata / render stats 日志。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 继续验证原有 auto-close needle，并新增 metadata / stats needle。
- 当前 metadata 字段包括 index、drawable、scale、pixel_format、clear_color、submitted、committed、attempts、success 和 degraded。
- `committed=unknown`，因为当前 bridge 不能诚实证明 GPU / display 完成状态。
- `clear_color` 只是 intended metadata，不是像素正确证明。
- 该 first slice 当时不读取像素；后续 Metal readback feasibility 已由独立 execution card 授权并封账。

当前 stop-line 仍然有效：

- 不读取像素。
- 不生成 screenshot artifact。
- 不做 window screenshot。
- 不做 Metal readback。
- 不做 frame hash。
- 不做 pixel diff。
- 不做 offscreen renderer。
- 不新增 JSON schema / parser。
- 不新增 C ABI 或 public runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不暴露 AppKit / Metal / Objective-C 平台对象指针。

### `P1 automated GUI verification bounded implementation first slice`

- [2026-04-25-p1-automated-gui-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-execution-card.md)
- [2026-04-25-p1-automated-gui-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)

完成内容：

- 新增 `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`。
- harness 默认设置 `CJGUI_AUTOCLOSE_SECONDS=1`。
- harness 默认调用 `labs/macos_bridge_smoke/scripts/build_and_run.sh`。
- harness 默认捕获日志到 `/tmp/cjgui-p1-auto-close-verify.log`。
- harness 检查 SDKROOT、bridge init、Metal capability check、window created、metal setup complete、first frame rendered、post close request、main-thread drain、close requested、destroy complete、event loop exited 和 `Cangjie: cjgui_app_run returned 0`。
- 该 first slice 当时不包含像素级验证；后续 Metal readback summary 只由独立 first slice 覆盖。

当前 stop-line 仍然有效：

- 不修改 Objective-C bridge。
- 不修改仓颉入口。
- 不修改 `build_and_run.sh`。
- 不实现自动截图、window screenshot、pixel diff、Metal readback、frame hash 或 offscreen renderer。
- 不在 automated GUI verification first slice 中新增 frame metadata / render stats 代码；该能力已由后续独立 execution card 授权并封账。
- 不把 harness 宣称为正式 GUI runtime 测试框架。

### `P1 main-thread UI message queue bounded implementation first slice`

- [2026-04-25-p1-main-thread-ui-message-queue-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-execution-card.md)
- [2026-04-25-p1-main-thread-ui-message-queue-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)

完成内容：

- `labs/macos_bridge_smoke` 内部已实现单实例 lifecycle queue first slice。
- 第一刀只支持 `RequestClose` lifecycle message。
- 自动关闭会先 post close request，再由主线程 drain 进入已有 close / destroy 路径。
- 人工关闭通过 `windowShouldClose` 先 post close request，再由主线程 drain 进入同一条关闭路径。
- 自动关闭日志断言已覆盖 post close request、main-thread drain、close requested、destroy complete、event loop exited、`cjgui_app_run()` 返回 `0`。

当前 stop-line 仍然有效：

- 不支持通用 UI update。
- 不支持 target update。
- 不实现 handle table / generation。
- 不新增 public runtime API。
- 不设计 Scene / Renderer / Widget / Layout / DSL。
- 不做跨平台抽象、文本、输入法、无障碍、AI semantic tree / Action Router。

最近完成的 implementation opening：

### `P1 AppKit/Metal bridge boundary cleanup implementation`

- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)

完成内容：

- `labs/macos_bridge_smoke` 已补生命周期日志。
- 已补最小 Metal capability 检查。
- 已补实验期 last-error C ABI。
- 自动关闭 smoke 已通过日志断言验证。

当前 stop-line 仍然有效：

- 不创建正式 GUI runtime。
- 不设计公共 Widget / DSL / Scene / Renderer API。
- 不做跨平台抽象。
- 不开启文本 / 输入 / IME / 无障碍。
- 不实现 AI semantic tree / action router。

最近完成的 docs-only opening：

### `P1 frame hash bounds / crop semantics policy execution card`

- [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md)

完成内容：

- 将 bounds / crop semantics policy preflight 收束成受限 execution card。
- 明确创建本卡本身不等于实现，后续必须由用户显式确认 bounded implementation first slice。
- 明确未来第一刀最多只能输出 bounds / crop semantics readiness diagnostics。
- 明确未来第一刀不得实现真正 bounds normalization、content interior extraction、native bridge 修改、public C ABI / runtime API、baseline / golden hash、baseline compare、pixel diff 或 offscreen renderer。
- 明确未来第一刀不得把 `content_interior_bounds` 宣称为当前可用 source，也不得把 `target_window_crop_bounds` 或 whole window crop 升级为 baseline input contract。
- 继续保持 `source=target_window_screenshot_crop`、`source_truth=user_visible_screenshot`、`source_normalized=false`、`baseline_allowed=false`、`hash_value_persistence_allowed=false` 和 `pixel_diff_allowed=false`。

本轮 stop-line 已守住：

- 不实现 bounds normalization。
- 不实现 bounds readiness diagnostics。
- 不修改 harness 或 `labs/macos_bridge_smoke`。
- 不修改 native bridge、仓颉入口或 public C ABI / runtime API。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash bounds / crop semantics policy preflight`

- [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md)

完成内容：

- 冻结 `target_window_screenshot_crop` 作为 frame hash source 时的 bounds / crop semantics policy。
- 明确 `screen_bounds_points`、`capture_bounds_pixels`、`target_window_crop_bounds` 和 `content_interior_bounds` 的区别。
- 明确当前 harness 已观测 target bounds、capture coverage、scale 等 diagnostics，但这些 bounds 仍不能升级为 baseline input contract。
- 明确 whole window crop 不能直接成为长期 baseline source，因为 title bar、shadow、rounded corner、traffic-light buttons、active / inactive state、Retina scale、multi-display、negative origin 和 rounding 都会污染 hash。
- 明确长期更合理的 hash source 倾向是 `content_interior_bounds`，但当前没有正式 runtime view / content geometry API，不能修改 native bridge 或新增 public runtime API，因此不能实现。
- 继续保持 `source=target_window_screenshot_crop`、`source_truth=user_visible_screenshot`、`source_normalized=false`、`baseline_allowed=false`、`hash_value_persistence_allowed=false` 和 `pixel_diff_allowed=false`。

本轮 stop-line 已冻结：

- 不实现 bounds normalization。
- 不修改 harness 或 `labs/macos_bridge_smoke`。
- 不修改 native bridge、仓颉入口或 public C ABI / runtime API。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash source normalization evidence closure / next-boundary preflight`

- [2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md)

完成内容：

- 复核 source normalization readiness diagnostics evidence。
- 明确当前 diagnostics 只证明可输出脱水 readiness summary，不证明 source 已 normalized。
- 明确当前继续保持 `source=target_window_screenshot_crop`、`source_truth=user_visible_screenshot`、`source_normalized=false`、`blocked_reason=source_policy_incomplete`、`baseline_allowed=false`、`hash_value_persistence_allowed=false` 和 `pixel_diff_allowed=false`。
- 明确 `success=true reason=none` 只表示 diagnostics 输出成功，不表示 source normalized、baseline 允许或 pixel diff 可开启。
- 明确当前 screenshot crop hash 仍不能作为长期 regression truth。
- 推荐下一条边界优先冻结 `bounds / crop semantics`，因为 scale、window decoration、color space、pixel format 和 timing 都依赖先定义 hash 输入矩形。

本轮 stop-line 已冻结：

- 不实现 source normalization。
- 不修改 harness 或 `labs/macos_bridge_smoke`。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不修改 native bridge、仓颉入口或 public C ABI / runtime API。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash source normalization policy execution card`

- [2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md)

完成内容：

- 将 frame hash source normalization policy preflight 收束成受限 implementation authorization。
- 明确创建本卡本身不等于实现，也不自动授权 baseline、pixel diff 或 source normalization runtime。
- 明确 future first slice 最多只能在现有 screenshot verification harness 中输出 source normalization readiness diagnostics。
- 明确 source 继续只能是 `target_window_screenshot_crop`，source truth 继续只能是 `user_visible_screenshot`。
- 明确继续保持 `source_normalized=false`、`baseline_allowed=false`。
- 明确继续禁止 hash value persistence、成功 screenshot artifact 保留、raw bytes、baseline / golden hash、baseline compare、pixel diff、offscreen renderer、public runtime API、native bridge 修改和 Renderer / Scene / Widget / Layout / DSL。

本轮 stop-line 已冻结：

- 不实现 source normalization。
- 不修改任何 harness 或 `labs/macos_bridge_smoke`。
- 不保存 hash value。
- 不实现 baseline / golden hash、baseline compare、pixel diff 或 offscreen renderer。
- 不读取或输出 raw bytes。
- 不新增 public runtime API。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash source normalization policy preflight`

- [2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md)

完成内容：

- 明确当前 source normalization 尚未完成。
- 明确 `target-window screenshot crop` 的 bounds 需要区分 screen point-space、pixel-space、target-window crop bounds 和 content interior bounds。
- 明确当前 scale 只够做 diagnostics，不足以作为 baseline normalization。
- 明确 `color_space=unknown`、`pixel_format=unknown` 是诚实降级，未定义前不允许 baseline。
- 明确 window decoration、timing、target attribution、frontmost app、visibility、display、Space / Mission Control、多显示器和 CI / headless 都会影响 source normalization。
- 明确 baseline owner / update policy 不能绕过 source normalization，source normalization 也不能绕过 human owner / review。

本轮 stop-line 已冻结：

- 不实现 source normalization。
- 不修改 screenshot verification harness、`labs/macos_bridge_smoke`、`verify_auto_close.sh` 或 native bridge。
- 不保存 hash value。
- 不把 hash value 写入日志、文档或仓库。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不保存成功 screenshot artifact。
- 不保存 raw bytes。
- 不新增 public C ABI / runtime API。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash baseline owner / update policy execution card`

- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md)

完成内容：

- 将 frame hash baseline owner / update policy preflight 收束成受限 implementation authorization。
- 明确创建本卡本身不等于实现。
- 明确本卡最多只授权未来一个极窄 policy / diagnostics first slice。
- 明确 baseline owner 未来必须是 human architect / maintainer；AI 不能成为 baseline owner。
- 明确 AI 不能自动更新 baseline；AI 未来最多只能生成 proposal、汇总 evidence、列风险并等待 human approval。
- 明确 future first slice 最多只能把 owner / update policy 以脱水 diagnostics 或 checklist 形式写入 harness / closure，不得改变 `baseline_allowed=false`。
- 明确 proposal / approval / rejection / defer flow 必须是文档化流程，不是 runtime API。

本轮 stop-line 已冻结：

- 不实现 baseline owner diagnostics。
- 不实现 baseline / golden hash。
- 不实现 baseline update workflow。
- 不保存 hash value。
- 不把 hash value 写入日志、文档或仓库。
- 不保存成功 screenshot artifact。
- 不保存 raw bytes。
- 不实现 baseline compare。
- 不实现 pixel diff。
- 不修改 screenshot verification harness、`labs/macos_bridge_smoke`、`verify_auto_close.sh` 或 native bridge。
- 不新增 public C ABI / runtime API。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash baseline owner / update policy preflight`

- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md)

完成内容：

- 明确当前仍不允许建立 baseline / golden hash。
- 明确 baseline owner 尚未设立，未来必须是 human architect / maintainer 显式批准，而不是 harness、脚本、AI 或 smoke demo 自然继承。
- 明确 baseline creation、update、rejection 和 defer 都必须经过 human review。
- 明确 AI 不允许自动更新 baseline；AI 未来最多只能生成 proposal、汇总 evidence、列风险并等待 human approval。
- 明确 proposal 必须包含 source truth、target attribution、artifact lifecycle、sample summary、frame hash feasibility、baseline readiness、环境风险和 negative assertions。
- 明确成功 screenshot artifact 不允许作为 baseline 输入，failure artifact 不能提升为 baseline artifact。
- 明确 baseline owner 未设立时，harness 必须继续保持 `baseline_allowed=false`。
- 明确 pixel diff 不能作为下一步。

本轮 stop-line 已冻结：

- 不实现 baseline / golden hash。
- 不实现 baseline owner runtime。
- 不实现 baseline update workflow。
- 不保存 hash value。
- 不把 hash value 写入日志、文档或仓库。
- 不保存成功 screenshot artifact。
- 不保存 raw bytes。
- 不实现 baseline compare。
- 不实现 pixel diff。
- 不修改 screenshot verification harness、`labs/macos_bridge_smoke`、`verify_auto_close.sh` 或 native bridge。
- 不新增 public C ABI / runtime API。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash baseline-readiness diagnostics execution card`

- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md)

完成内容：

- 将 frame hash evidence review / baseline policy preflight 收束成受限 implementation authorization。
- 明确创建本卡本身不等于实现。
- 明确未来 first slice 只允许做 `baseline readiness diagnostics`。
- 明确未来 first slice 继续只能使用 `target_window_screenshot_crop`，继续只能声明 `source_truth=user_visible_screenshot`。
- 明确未来 first slice 最多只能输出脱水 readiness summary，不得保存 hash value，不得建立 baseline / golden hash，不得做 baseline compare，不得做 pixel diff。
- 明确未来 first slice 必须继续遵守 artifact retention policy：成功删除，失败短期受控保留。
- 明确未来 first slice 必须继续保留现有 screenshot verification、frame hash feasibility、artifact cleanup 和 auto-close 验证语义。
- 建议未来 readiness summary 输出 `baseline_allowed=false`、`human_review_required=true`、`ai_auto_update_allowed=false`、`hash_value_persistence_allowed=false`、`pixel_diff_allowed=false` 等字段。

本轮 stop-line 已冻结：

- 不实现 baseline readiness diagnostics。
- 不实现 baseline / golden hash。
- 不实现 pixel diff。
- 不实现 baseline compare。
- 不保存 hash value。
- 不保存 raw bytes。
- 不保存成功 screenshot artifact。
- 不修改 screenshot verification harness、`labs/macos_bridge_smoke`、`verify_auto_close.sh` 或 native bridge。
- 不新增 public C ABI / runtime API。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash evidence review / baseline policy preflight`

- [2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md)

完成内容：

- 复核 frame hash feasibility evidence 后，明确当前不允许建立 baseline / golden hash。
- 明确不允许保存 hash value，不允许把 hash value 写入日志、文档或仓库。
- 明确 baseline owner 当前未设立，未来必须有 human architect / maintainer 审核。
- 明确 AI 不允许自动更新 baseline，只能生成候选报告和 evidence 摘要。
- 明确成功 screenshot artifact 不允许保留为 baseline 输入，失败 artifact 只服务短期诊断，不能自动提升为 baseline artifact。
- 明确 target-window screenshot crop 目前只足够作为 feasibility source，不足以作为 baseline source。
- 明确 Metal readback hash 和 screenshot hash 不能混用，二者 truth 不同。
- 明确 CI / headless 当前不可声称可复核。
- 明确 pixel diff 不能作为下一步。
- 建议未来若继续推进，只能先开 `P1 frame hash baseline-readiness diagnostics execution card`。

本轮 stop-line 已冻结：

- 不实现 baseline / golden hash。
- 不实现 pixel diff。
- 不实现 baseline compare。
- 不保存 hash value。
- 不保存成功 screenshot artifact。
- 不修改 screenshot verification harness、`labs/macos_bridge_smoke`、`verify_auto_close.sh` 或 native bridge。
- 不新增 public C ABI / runtime API。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 frame hash feasibility execution card`

- [2026-04-25-p1-frame-hash-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-execution-card.md)

完成内容：

- 将 pixel diff / frame hash prerequisites preflight 收束成受限 implementation authorization。
- 明确创建本卡本身不等于实现。
- 明确本卡只允许未来 first slice 做 frame hash feasibility，不允许 pixel diff。
- 明确未来 source image 二选一后选择 `target-window screenshot crop`，不同时支持 screenshot、Metal readback 和 offscreen renderer。
- 明确 target-window screenshot crop 只作为 user-visible evidence source，不等同于 Metal readback truth。
- 明确当前不选择 Metal readback source，避免修改 native bridge 和扩大 readback。
- 明确未来 first slice 最多只能在当前运行内计算脱水 hash feasibility summary。
- 明确不允许 baseline / golden image、raw bytes 保存、成功 screenshot artifact 保留、长期 golden hash、hash mismatch render failure、pixel diff、threshold diff、区域 diff 或 baseline compare。
- 明确必须继续遵守 screenshot artifact retention policy：成功删除，失败短期受控保留。

本轮 stop-line 已冻结：

- 不实现 frame hash。
- 不实现 pixel diff。
- 不建立 baseline / golden image。
- 不读取整图像素。
- 不保存 raw bytes。
- 不保存 screenshot artifact。
- 不修改 `labs/macos_bridge_smoke`、screenshot verification harness、`verify_auto_close.sh` 或 native bridge。
- 不新增 public C ABI / runtime API。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 pixel diff / frame hash prerequisites preflight`

- [2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md)

完成内容：

- 明确当前不具备进入 pixel diff 或正式 frame hash 的实现条件。
- 明确 pixel diff 需要稳定 source image、baseline owner、diff 阈值、颜色空间、scale、alpha、artifact 隐私和 failure classification。
- 明确 frame hash 可以早于 pixel diff，但只能作为 future feasibility，不能建立 baseline 或保存 raw bytes。
- 明确 source image 当前不能定论；user-visible screenshot、Metal readback 和 future offscreen renderer 分别服务不同 truth。
- 明确 baseline / golden image 当前没有 owner，不允许建立。
- 明确 artifact retention policy 继续禁止 artifact 进入仓库、baseline / golden image 或 long-term cache。
- 明确当前不允许读取整图像素，不允许保存 raw bytes、hash 或 diff result。
- 明确颜色空间、Retina scale、window decoration、透明度、compositor、遮挡、多显示器、timing 和 anti-aliasing 风险。
- 建议下一步如继续，只能先开 docs-only `P1 frame hash feasibility execution card`。

本轮 stop-line 已冻结：

- 不实现 pixel diff。
- 不实现 frame hash。
- 不建立 baseline / golden image。
- 不保存 screenshot artifact。
- 不读取整图像素。
- 不输出 raw bytes。
- 不修改 `labs/macos_bridge_smoke`、screenshot verification harness、`verify_auto_close.sh` 或 native bridge。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做 offscreen renderer。
- 不把 smoke demo 宣称为正式 GUI runtime。

### `P1 screenshot artifact retention execution card`

- [2026-04-25-p1-screenshot-artifact-retention-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-execution-card.md)

完成内容：

- 将 artifact retention policy preflight 收束成受限 implementation authorization。
- 明确创建本卡本身不等于实现。
- 限定未来第一刀最多围绕现有 screenshot verification harness 的 artifact retention / cleanup policy 做极窄调整。
- 明确成功 artifact 默认必须删除。
- 明确失败 artifact 只允许短期、受控、可解释地保留。
- 明确 artifact 默认只能位于 `/tmp` 或 `mktemp -d` 临时目录。
- 明确不允许 artifact 进入仓库、baseline / golden image 或 long-term cache。
- 明确不允许 full-screen screenshot retention；target-window crop retention 只能服务失败诊断。
- 明确未来历史残留清理只能做 TTL / pattern 限定的安全清理。

本轮 stop-line 已冻结：

- 不实现 artifact retention / cleanup policy。
- 不修改 screenshot verification harness。
- 不保存 screenshot artifact。
- 不读取或比较像素。
- 不实现 pixel diff、frame hash 或 offscreen renderer。
- 不修改 `labs/macos_bridge_smoke`、`verify_user_visible_window_screenshot_verification.sh`、`verify_auto_close.sh` 或 `cjgui_macos.m`。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把当前 smoke demo 宣称为正式 runtime。

### `P1 screenshot verification artifact review / retention policy preflight`

- [2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md)

完成内容：

- 冻结 screenshot verification artifact 的审查、保留、清理、隐私和 baseline 边界。
- 明确成功 artifact 默认删除，只有未来 execution card 明确授权时才允许短期保留为 closure evidence。
- 明确失败 artifact 可以在受控条件下短期保留，但必须记录路径、保留原因、failure classification、删除策略和人工审查责任。
- 明确 artifact 不允许进入仓库、baseline / golden image 或长期缓存。
- 明确 full screen screenshot 默认不允许保留，target-window crop 未来可在 execution card 中受限允许。
- 明确 artifact review 是 pixel diff / frame hash 的前置治理，不是 pixel diff / frame hash 本身。

本轮 stop-line 已冻结：

- 不修改 screenshot verification harness。
- 不保存 screenshot artifact。
- 不读取或比较像素。
- 不实现 pixel diff、frame hash 或 offscreen renderer。
- 不修改 `labs/macos_bridge_smoke`、`verify_user_visible_window_screenshot_verification.sh`、`verify_auto_close.sh` 或 `cjgui_macos.m`。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把当前 smoke demo 宣称为正式 runtime。

### `P1 user-visible window screenshot verification execution card`

- [2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md)

完成内容：

- 将 screenshot verification preflight 收束成受限 implementation authorization。
- 明确创建本卡本身不等于已实现。
- 限定未来第一刀只能做 user-visible window screenshot verification bounded implementation first slice。
- 未来最多允许独立 harness 保存一个临时 screenshot artifact、确认目标 smoke window 归属，并做极窄 clear-color sample summary。
- 明确 screenshot verification 不能替代 Metal readback truth，也不能升级为 full GUI verification。
- 明确临时 artifact 只能在 `/tmp` 或 `mktemp -d` 临时目录中，成功默认删除，失败保留必须记录原因、路径、分类和删除策略。
- 明确允许的像素读取仅限极窄 clear-color sample，不允许读取整图、输出 raw bytes、建立 baseline、提交 artifact、做 pixel diff、frame hash 或 offscreen renderer。

本轮 stop-line 已冻结：

- 不实现 screenshot verification。
- 不保存 screenshot artifact。
- 不读取或比较像素。
- 不实现 pixel diff、frame hash 或 offscreen renderer。
- 不修改 `labs/macos_bridge_smoke`、`verify_user_visible_window_screenshot_feasibility.sh`、`verify_auto_close.sh` 或 `cjgui_macos.m`。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把当前 smoke demo 宣称为正式 runtime。

### `P1 user-visible window screenshot verification preflight`

- [2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md)

完成内容：

- 冻结是否从 screenshot feasibility 进入真正 screenshot verification。
- 明确 feasibility 只证明当前本机可以创建 CoreGraphics on-screen image object，不证明目标窗口内容或像素正确。
- 建议未来第一张 execution card 最多允许临时 screenshot artifact、目标窗口归属和极窄 clear-color sample。
- 明确临时 artifact 只能在 `/tmp` 或 `mktemp -d` 临时目录内，默认不提交、不 baseline，成功后删除，失败保留必须记录删除策略。
- 明确 pixel diff、frame hash 和 offscreen renderer 继续延后，必须另开 preflight / execution card。

本轮 stop-line 已冻结：

- 不实现 screenshot verification。
- 不保存 screenshot artifact。
- 不读取或比较屏幕像素。
- 不实现 pixel diff、frame hash 或 offscreen renderer。
- 不修改 `labs/macos_bridge_smoke`、`verify_user_visible_window_screenshot_feasibility.sh`、`verify_auto_close.sh` 或 `cjgui_macos.m`。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。

### `P1 user-visible window screenshot feasibility execution card`

- [2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md)

完成内容：

- 将用户可见窗口证据线收束为一张受限 implementation authorization。
- 明确创建本卡本身不等于已实现。
- 限定未来第一刀只允许新增独立 screenshot feasibility harness。
- 建议 harness 路径为 `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`。
- 明确未来 harness 最多判断 smoke 运行期间能否请求一次截图，并输出脱水 success / failure classification summary。
- 明确 failure classification 必须覆盖 `permission_denied`、`display_unavailable`、`window_not_found`、`window_not_visible`、`capture_failed`、`render_not_ready`、`render_failure` 和 `unknown`。
- 明确 screenshot feasibility 不能替代 Metal readback truth，也不能证明用户可见窗口像素正确。

本轮 stop-line 已冻结：

- 不实现 screenshot / window screenshot。
- 不读取屏幕像素。
- 不保存 screenshot artifact。
- 不实现 pixel diff、frame hash 或 offscreen renderer。
- 不修改 `labs/macos_bridge_smoke`、`verify_auto_close.sh` 或 `cjgui_macos.m`。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。

### `P1 user-visible window verification evidence preflight`

- [2026-04-25-p1-user-visible-window-verification-evidence-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-verification-evidence-preflight.md)

完成内容：

- 冻结用户可见窗口验证证据线。
- 明确 Metal readback summary 只证明 smoke bridge 内部受控 Metal render target 的 clear-color sample summary，不证明用户可见窗口、compositor / display presentation 或 CI / headless 稳定性。
- 明确用户可见窗口验证和 Metal render target readback 是不同 truth：前者是 OS / compositor 之后的 evidence，后者是 GPU render target evidence。
- 明确当前不应直接实现 screenshot；如果继续推进，第一刀只能是 screenshot feasibility probe，而不是 full verification。
- 明确 screenshot / window screenshot 的风险：屏幕录制权限、窗口焦点、Space / Mission Control、Retina scale、多显示器、窗口遮挡、动画 timing、CI / headless，以及历史上的 `could not create image from display`。
- 明确未来 screenshot feasibility execution card 的最大 write set、harness 最多可断言的内容，以及 failure classification。

本轮 stop-line 已冻结：

- 不实现 screenshot / window screenshot。
- 不读取屏幕像素。
- 不保存 screenshot artifact。
- 不实现 pixel diff、frame hash 或 offscreen renderer。
- 不修改 `labs/macos_bridge_smoke` 或 `verify_auto_close.sh`。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。

### `P1 Metal readback feasibility execution card`

- [2026-04-25-p1-metal-readback-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-execution-card.md)

完成内容：

- 将 screenshot / Metal readback verification preflight 收束为一张受限 implementation authorization。
- 明确创建本卡本身不等于已实现。
- 限定未来第一刀只允许在 `labs/macos_bridge_smoke` 内部探索 smoke-only、single-frame、clear-color Metal readback feasibility。
- 明确唯一 authority 是 [2026-04-25-p1-screenshot-metal-readback-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-metal-readback-verification-preflight.md)。
- 明确选择 Metal readback 而不是 screenshot 的原因：避免窗口可见性、焦点、权限、遮挡、多显示器、Retina scale、timing 和 CI / headless 环境噪音。
- 明确未来 readback 结果只能输出脱水 summary，不允许保存 raw pixel bytes，不允许生成 screenshot artifact。
- 明确不得新增 public C ABI / runtime API，不得暴露 `CAMetalDrawable*`、`id<MTLTexture>`、`id<MTLCommandBuffer>` 或 Objective-C `id`。
- 明确 command buffer completion 必须诚实处理，`committed=unknown` 不能伪装成 completed / displayed / pixel correct。
- 明确 `waitUntilCompleted` 如未来使用，只能限于 smoke 内部单帧 feasibility，不能变成长期 render loop 架构承诺。

本轮 stop-line 已冻结：

- 不修改 `labs/macos_bridge_smoke`。
- 不修改 `verify_auto_close.sh`。
- 不读取像素。
- 不实现 Metal readback。
- 不生成 screenshot artifact。
- 不保存 raw pixel bytes。
- 不实现 frame hash、pixel diff 或 offscreen renderer。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。

### `P1 screenshot / Metal readback verification preflight`

- [2026-04-25-p1-screenshot-metal-readback-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-metal-readback-verification-preflight.md)

完成内容：

- 冻结未来像素级 / 视觉级 GUI 验证的第一证据链选择。
- 明确当前日志 harness 和 frame metadata / render stats 只能证明执行路径、bridge diagnostics 和自动关闭，不证明屏幕真实颜色正确。
- 将当前 smoke 阶段的最小视觉正确性定义为：受控 render target 中出现预期 clear color 的机器可复核像素证据。
- 比较 screenshot、Metal readback、frame hash、pixel diff 和 offscreen renderer 的风险、成本、稳定性和维护代价。
- 结论倾向：本轮继续只做 preflight；如果继续推进，第一候选应是 smoke-only `Metal readback feasibility execution card`，而不是直接 screenshot。
- 明确 screenshot 受窗口可见性、焦点、权限、Retina scale、多显示器、遮挡、timing 和 CI / headless 环境影响。
- 明确 Metal readback 必须处理 command buffer completion、storage mode / CPU readback / 同步成本，且不能暴露 Metal 对象或变成 renderer abstraction。
- 明确 frame hash / pixel diff 必须等稳定 source image / readback bytes 之后。
- 明确 offscreen renderer 很可能越过当前 P1 边界，本轮不能引入。

本轮 stop-line 已冻结：

- 不修改 `labs/macos_bridge_smoke`。
- 不修改 `verify_auto_close.sh`。
- 不新增 public C ABI / runtime API。
- 不实现 screenshot、Metal readback、frame hash、pixel diff 或 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。

### `P1 frame metadata / render stats execution card`

- [2026-04-25-p1-frame-metadata-render-stats-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-execution-card.md)

完成内容：

- 将 frame metadata / render stats preflight 收束为一张受限 implementation authorization。
- 明确创建本卡本身不等于已实现。
- 限定未来第一刀只允许 smoke bridge 输出脱水 frame metadata / render stats 日志。
- 限定 `verify_auto_close.sh` 只允许增加 metadata / stats 日志 needle。
- 明确允许字段：frame index、drawable width / height、scale factor、pixel format、clear color metadata、first frame submitted / committed、render attempt count、render success / degraded reason。
- 明确禁止 raw pixels、screenshot artifact、Metal texture bytes、frame hash、pixel diff result、renderer scene id、widget / layout information 和任何 AppKit / Metal / Objective-C 平台对象。
- 明确不读取像素，不做截图、Metal readback、frame hash、pixel diff、offscreen renderer，不设计 Renderer / Scene / Widget / Layout / DSL。

### `P1 frame metadata / render stats preflight`

- [2026-04-25-p1-frame-metadata-render-stats-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-preflight.md)

完成内容：

- 冻结未来 frame metadata / render stats 的边界。
- 明确当前 `verify_auto_close.sh` 只能证明构建、生命周期、Metal capability、first-frame-submitted 日志、自动关闭和返回码。
- 明确当前仍不能证明真实像素正确。
- 明确 metadata / stats 只解决日志过粗的问题，不替代 screenshot、Metal readback、frame hash、pixel diff 或 offscreen renderer。
- 明确 owner 拆分：bridge 产出脱水 diagnostics，verification harness 消费并断言，future renderer 暂不参与，独立 diagnostics surface 只能作为实验期 read surface。
- 明确第一阶段允许字段：frame index、drawable width / height、scale factor、pixel format、clear color metadata、first frame submitted / committed、render attempt count、render success / degraded reason。
- 明确禁止 raw pixels、screenshot artifact、Metal texture bytes、frame hash、pixel diff result、renderer scene id、widget/layout information 和任何平台对象。
- 明确本轮没有修改 `labs/macos_bridge_smoke`，没有修改 `verify_auto_close.sh`，没有实现 frame metadata / render stats。

### `P1 automated GUI verification execution card`

- [2026-04-25-p1-automated-gui-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-execution-card.md)

完成内容：

- 将 automated GUI verification preflight 收束为一张受限 implementation authorization。
- 明确创建本卡本身不等于已实现。
- 限定未来第一刀只创建 `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 或等价极窄脚本。
- 明确 harness 只验证现有日志证据，包括 SDKROOT、bridge init、Metal capability check、window created、metal setup complete、first frame rendered、post close request、main-thread drain、close requested、destroy complete、event loop exited 和 `Cangjie: cjgui_app_run returned 0`。
- 明确不得声称完成像素级验证。
- 明确不修改 Objective-C bridge，除非另开 execution card。
- 明确不做截图、Metal readback、frame hash、pixel diff、offscreen renderer 或重型 GUI 测试框架。

### `P1 automated GUI verification preflight`

- [2026-04-25-p1-automated-gui-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-preflight.md)

完成内容：

- 冻结从“日志 + 人工视觉确认”走向自动化 GUI 验证的路线。
- 明确当前已经能自动验证构建、日志、lifecycle、Metal capability、first frame submitted 和退出码。
- 明确当前仍不能自动验证真实像素、窗口截图、frame hash 或 pixel diff。
- 明确 `could not create image from display` 代表 macOS 截图路径存在权限和环境不确定性。
- 推荐近期第一刀优先做日志断言 + 可选 frame metadata / render stats。
- 明确截图、Metal readback、frame hash、pixel diff、offscreen render 都必须另开 execution card。
- 明确本轮没有修改 `labs/macos_bridge_smoke`，没有实现任何自动视觉验证。

### `P1 main-thread UI message queue execution card`

- [2026-04-25-p1-main-thread-ui-message-queue-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-execution-card.md)

完成内容：

- 将 main-thread UI message queue preflight 收束为受限实现授权卡。
- 明确创建本卡本身不等于已实现；后续实现必须严格按本卡执行。
- 限定未来第一刀只做 `labs/macos_bridge_smoke` 内部单实例 lifecycle queue。
- 建议第一刀只支持 `RequestClose`，不支持通用 UI update。
- 明确不做 handle table / generation 的原因和后续 target update 的升级条件。
- 固定日志断言验证要求：post close request、main-thread drain、close requested、destroy complete、event loop exited、`cjgui_app_run()` 返回 `0`。

### `P1 main-thread UI message queue preflight`

- [2026-04-25-p1-main-thread-ui-message-queue-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-preflight.md)

完成内容：

- 冻结未来后台任务 / Agent action / runtime 异步更新 UI 回到 macOS 主线程的规则。
- 明确 UI message queue owner 是主线程 bridge runtime owner。
- 明确 enqueue 只能来自受控入口，drain 只能由主线程 event-loop adapter 执行。
- 明确 message payload 不允许携带 AppKit / Metal 平台对象。
- 明确 stale message 必须通过 handle / generation / lifecycle state 校验后丢弃。
- 明确 `last_error` 不能扩展成长期并发错误系统。

近期已完成的基础 opening：

### `E0 仓颉 SDK 与本机工具链就绪 preflight`

目标：

- 先确认本机能稳定编译和运行仓颉程序
- 先确认 `cjc`、`cjpm`、SDK、macOS 依赖和 shell 环境变量可用
- 为后续 `P0 macOS + Metal` 运行时实现扫清环境障碍

当前已知现实：

- 本机是 `macOS arm64`
- Xcode Command Line Tools 已存在
- 仓颉 SDK 已解压到 `/Users/jiangxuanyang/cangjie-toolchains/cangjie`
- `source envsetup.sh` 后 `cjc` 可用
- `source envsetup.sh` 后 `cjpm` 可用
- 默认 `MacOSX26.4.sdk` 会导致仓颉 hello 链接失败
- 指定 `MacOSX15.4.sdk` 后，最小 `hello.cj` 已能编译并运行
- 指定 `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk` 后，`cjpm run` 已能运行最小项目
- `libffi 3.5.2` 已通过 Homebrew 安装，路径为 `/opt/homebrew/opt/libffi`
- 仓颉调用本地 C 静态库的最小 FFI smoke test 已通过，输出 `C FFI result: 42`

预期只覆盖：

- 安装或定位仓颉 macOS aarch64 SDK
- 执行 `envsetup.sh`
- 验证 `cjc -v`
- 验证 `cjpm --version` 或 `cjpm -h`
- 编译并运行一个最小 `hello.cj`
- 用 `cjpm init` / `cjpm run` 验证项目管理工具链

当前 E0 已完成。
后续统一参考：

- [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [cffi_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke)

P0 preflight 已创建：

- [2026-04-25-p0-macos-bridge-runtime-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-runtime-preflight.md)

P0 bridge smoke 已落地：

- [macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)
- [2026-04-25-p0-macos-bridge-smoke-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-execution-card.md)
- [2026-04-25-p0-macos-bridge-smoke-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)

人工视觉检查已确认：运行 smoke 后出现青色窗口。

P1 bridge boundary cleanup、P1 main-thread UI message queue first slice、P1 automated GUI verification first slice、P1 frame metadata / render stats first slice、P1 screenshot / Metal readback verification preflight、P1 Metal readback feasibility first slice、P1 user-visible window verification evidence preflight、P1 user-visible window screenshot feasibility execution card、P1 user-visible window screenshot feasibility first slice、P1 user-visible window screenshot verification preflight、P1 user-visible window screenshot verification execution card、P1 user-visible window screenshot verification first slice、P1 screenshot verification artifact retention policy preflight、P1 screenshot artifact retention execution card、P1 screenshot artifact retention first slice、P1 pixel diff / frame hash prerequisites preflight、P1 frame hash feasibility execution card、P1 frame hash feasibility first slice、P1 frame hash evidence review / baseline policy preflight、P1 frame hash baseline-readiness diagnostics execution card、P1 frame hash baseline-readiness diagnostics first slice、P1 frame hash baseline owner / update policy preflight、P1 frame hash baseline owner / update policy execution card、P1 frame hash baseline owner / update policy first slice、P1 frame hash source normalization policy preflight、P1 frame hash source normalization policy execution card、P1 frame hash source normalization readiness diagnostics first slice、P1 frame hash source normalization evidence closure / next-boundary preflight、P1 frame hash bounds / crop semantics policy preflight、P1 frame hash bounds / crop semantics policy execution card、P1 frame hash bounds / crop semantics readiness diagnostics first slice、P1 frame hash verification evidence line closure / runtime pivot preflight、P1 smoke-to-runtime boundary preflight、P1 minimal app/window lifecycle runtime boundary preflight、P1 red-team risk intake / runtime guardrails preflight、P1 minimal app/window lifecycle runtime execution card、P1 minimal app/window lifecycle runtime skeleton first slice、P1 self-drawn platform reduction / IME / accessibility guardrails preflight、P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight、P1 app lifecycle surface boundary preflight、P1 app lifecycle surface execution card、P1 app lifecycle surface comment-only refinement first slice、P1 window lifecycle surface boundary preflight、P1 window lifecycle surface execution card、P1 window lifecycle surface comment-only refinement first slice、P1 platform adapter boundary preflight、P1 platform adapter boundary execution card、P1 platform adapter surface comment-only refinement first slice、P1 error strategy boundary preflight、P1 error strategy boundary execution card、P1 error strategy surface comment-only refinement first slice、P1 minimal runtime skeleton surface phase closure / compaction preflight、P1 runtime build/package boundary preflight、P1 runtime build/package boundary execution card、P1 runtime build/package metadata first slice、P1 first compilable runtime source boundary preflight、P1 first compilable runtime source execution card、P1 first compilable runtime source first slice、P1 first compilable runtime source closure / next implementation boundary preflight、P1 runtime visibility / internal symbol boundary preflight、P1 runtime internal symbol boundary execution card、P1 runtime internal symbol boundary first slice、P1 runtime internal symbol closure / first internal type boundary preflight、P1 first internal runtime type execution card、P1 first internal runtime type first slice、P1 first internal runtime type closure / error fact shape boundary preflight、P1 error fact shape execution card、P1 error fact shape first slice、P1 error fact shape closure / error taxonomy boundary preflight、P1 error taxonomy boundary execution card、P1 error taxonomy marker first slice、P1 error taxonomy marker closure / recoverability boundary preflight、P1 first internal app lifecycle state execution card、P1 first internal app lifecycle state first slice、P1 app lifecycle state shape execution card、P1 app lifecycle state shape first slice，以及 P1 app lifecycle transition boundary execution card 都已完成。下一步进入极窄 app lifecycle transition marker first slice，仍不能扩写正式 GUI runtime。

## 当前 next opening

当前推荐的下一条 opening 是：

### `P1 lifecycle mutation plan draft bundle closure / next runtime behavior decision`

性质：closure review / architecture decision

目标：

- 基于 [2026-04-29-p1-lifecycle-mutation-plan-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-lifecycle-mutation-plan-draft-bundle-closure-review.md)，封账 internal-only lifecycle mutation plan draft。
- app mutation plan facts 已归属 `app_lifecycle.cj`；window mutation plan facts 已归属 `window_lifecycle.cj`。
- `runtime_state.cj` 只做 cross-owner mutation plan routing summary，消费 mutation readiness report，不拥有 app/window lifecycle mutation semantics。
- 下一步需要判断是否进入 lifecycle mutation execution readiness / command draft，或转向更高层 compaction。

禁止：

- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`，不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不新增 `public` runtime API 或 public C ABI。
- 不引用 AppKit / Metal / Objective-C，或暴露 platform object、native handle、raw pointer。
- 不实现 event loop、`while` loop / scheduling loop、callback binding、queue / drain、input processing、layout / render、app lifecycle execution、window lifecycle execution、app/window state mutation、调用 state-changing transition functions、app run / shutdown、window create / close / destroy / release。
- 不新增 handle table / generation。

## 历史 next opening 记录（旧内容，当前以 active / next opening 为准）

当前推荐的下一条 opening 是：

### `P1 app lifecycle transition marker first slice`

性质：bounded implementation / app lifecycle transition marker

目标：

- 基于 [P1 app lifecycle transition boundary execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md)，只新增一个默认 internal app lifecycle transition marker type。
- 该 marker 只表达 transition boundary exists but transition behavior is not yet defined。
- 不定义 state machine、transition behavior、`run` / `shutdown` / `request quit`、queue / drain、public runtime API 或 public C ABI。

禁止：

- 不修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`，不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不修改 `isStateMachineActive` 的值或语义，不新增第二个 state 字段。
- 不新增 `public`、import、函数、方法、显式 init、构造逻辑或 runtime behavior。
- 不实现 `run` / `shutdown` / `request quit` / queue / drain、platform adapter callback binding、window lifecycle behavior 或 error strategy behavior。
- 不定义 public runtime API、public C ABI，或引用 AppKit / Metal / Objective-C。
- 不进入 Renderer / Scene / Widget / Layout / DSL、global tick / blind redraw、Text / Input / IME / Accessibility、command-list hash、semantic tree / Action Router、`CJGUI_TRUTH_MANIFEST.md`、pixel diff、baseline 或 offscreen renderer。

前置依据：

- [2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md)
- [2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)
- [2026-04-26-p1-app-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-execution-card.md)
- [2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md)
- [2026-04-26-p1-error-taxonomy-marker-closure-recoverability-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-recoverability-boundary-preflight.md)
- [2026-04-26-p1-error-taxonomy-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-review.md)
- [2026-04-26-p1-error-taxonomy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-boundary-execution-card.md)
- [2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md)
- [2026-04-26-p1-error-fact-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md)
- [2026-04-26-p1-error-fact-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-execution-card.md)
- [2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md)
- [2026-04-26-p1-first-internal-runtime-type-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-review.md)
- [2026-04-26-p1-first-internal-runtime-type-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-execution-card.md)
- [2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md)
- [2026-04-26-p1-runtime-build-package-metadata-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-metadata-closure-review.md)
- [2026-04-26-p1-runtime-build-package-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-execution-card.md)
- [2026-04-26-p1-runtime-build-package-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-preflight.md)
- [2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md)
- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- [2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md)
- [2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)
- [2026-04-26-p1-app-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-execution-card.md)
- [2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md)
- [2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)
- [2026-04-26-p1-window-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-execution-card.md)
- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md)
- [2026-04-26-p1-smoke-to-runtime-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md)
- [2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md)
- [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md)
- [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md)
- [2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md)
- [2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md)
- [2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md)
- [2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md)
- [2026-04-25-p1-frame-hash-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-execution-card.md)
- [2026-04-25-p1-frame-hash-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md)
- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md)
- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)
- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md)
- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md)
- [2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md)
- [2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md)
- [2026-04-25-p1-screenshot-artifact-retention-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-execution-card.md)
- [2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md)
- [2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md)
- [2026-04-25-p1-user-visible-window-verification-evidence-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-verification-evidence-preflight.md)
- [2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md)
- [2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md)
- [2026-04-25-p1-metal-readback-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [2026-04-25-p1-metal-readback-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-execution-card.md)
- [2026-04-25-p1-screenshot-metal-readback-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-metal-readback-verification-preflight.md)
- [2026-04-25-p1-frame-metadata-render-stats-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-preflight.md)
- [2026-04-25-p1-frame-metadata-render-stats-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
- [2026-04-25-p1-frame-metadata-render-stats-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-execution-card.md)
- [2026-04-25-p1-automated-gui-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [2026-04-25-p1-automated-gui-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-preflight.md)
- [2026-04-25-p1-main-thread-ui-message-queue-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)

Stop-line：

- 不实现通用 GUI verification framework。
- 不继续扩写 Metal readback。
- 不继续扩写 screenshot verification harness。
- 不读取整图像素、不输出 raw bytes、不比较任意 UI 区域颜色。
- 不保存长期 screenshot artifact 或 baseline。
- 不修改 `cjgui_macos.m`。
- 不修改 `verify_auto_close.sh`。
- 不做 pixel diff / frame hash / offscreen renderer。
- 不新增 public C ABI / runtime API。
- 不进入正式 Scene / Renderer 实现。
- 不设计公共 Widget API。
- 不引入重型 GUI 测试框架。
- 不做跨平台抽象。
- 不开启文本 / 输入 / IME / 无障碍。
- 不引入 AI semantic tree / action router。
- 不把平台对象泄露到仓颉公共层。

历史上一条 `P0 单平台桌面运行时 first slice` 已通过 smoke 形式完成：

当前 `P0 macOS bridge smoke implementation` 已完成。
已验证自动关闭模式：

- 编译成功
- 链接成功
- 进入 macOS event loop
- 自动关闭窗口
- `cjgui_app_run()` 返回 `0`

已验证人工视觉模式：

- 运行 smoke 后出现青色窗口

残留：

- 自动截图失败，错误为 `could not create image from display`
- P1 cleanup 未解决 headless / pixel-diff 验证。
- P1 main-thread UI message queue first slice 只覆盖单实例 `RequestClose` lifecycle message，不覆盖真实多线程压力、handle generation、多窗口、target update 或自动视觉验证。
- P1 automated GUI verification first slice 只封装自动关闭日志断言，不覆盖截图、Metal readback、frame hash、pixel diff、offscreen renderer 或真实自动视觉验证。
- P1 frame metadata / render stats first slice 只输出脱水 metadata / stats 日志，不覆盖截图、Metal readback、frame hash、pixel diff、offscreen renderer 或真实像素验证。
- P1 screenshot / Metal readback verification preflight 只冻结下一阶段证据链选择；当前只实现了 smoke-only clear-color Metal readback feasibility summary，尚未实现 screenshot、frame hash、pixel diff 或 offscreen renderer。
- P1 Metal readback feasibility first slice 只验证 smoke bridge 内部单帧 clear-color readback summary，不证明用户可见窗口、compositor / display presentation 或真实视觉正确性。
- P1 user-visible window verification evidence preflight 只冻结用户可见窗口证据线；尚未实现 screenshot / window screenshot，也没有保存 screenshot artifact、frame hash、pixel diff 或 offscreen renderer。
- P1 user-visible window screenshot feasibility first slice 只证明当前本机 smoke 运行期间可以请求一次 CoreGraphics on-screen image feasibility probe 并得到 `success=true reason=none`；它不证明用户可见窗口内容正确、compositor / display presentation 正确、CI / headless 可复核，也没有保存 screenshot artifact、读取 / 比较屏幕像素、pixel diff、frame hash 或 offscreen renderer。
- P1 user-visible window screenshot verification preflight 只冻结未来是否允许进入真正 screenshot verification；尚未保存 screenshot artifact，尚未读取或比较像素，也没有实现 pixel diff、frame hash、offscreen renderer 或 public runtime API。
- P1 user-visible window screenshot verification execution card 只授权未来一个 bounded implementation first slice；本卡创建本身未实现 screenshot verification，未保存 artifact，未读取或比较像素，未实现 pixel diff、frame hash、offscreen renderer 或 public runtime API。
- P1 user-visible window screenshot verification first slice 只验证当前本机一次目标 bounds 截图、owner pid / title / bounds 归属和中心 `3x3` clear-color sample summary；它不是 full GUI verification，不证明 CI / headless、遮挡、多窗口、多显示器、pixel diff、frame hash、baseline 或 offscreen renderer。
- P1 screenshot verification artifact retention policy preflight 只冻结 artifact review / retention / cleanup / privacy / baseline 边界；尚未修改 screenshot harness，尚未保存 artifact，尚未读取或比较像素，也没有实现 pixel diff、frame hash、offscreen renderer 或 public runtime API。
- P1 screenshot artifact retention execution card 只授权未来一个 bounded implementation first slice；本卡创建本身未修改 harness、未保存 artifact、未读取或比较像素，未实现 pixel diff、frame hash、baseline、offscreen renderer 或 public runtime API。
- P1 frame hash feasibility first slice 只在当前运行内对 target-window screenshot crop 计算脱水 `sha256` feasibility summary，不记录 hash 值，不持久化 hash，不建立 baseline / golden image，不做 pixel diff、baseline compare、offscreen renderer 或正式 regression。
- P1 frame hash evidence review / baseline policy preflight 只冻结 baseline / golden hash 的 owner、hash value、artifact、source truth、CI / headless 和 pixel diff 边界；尚未允许 baseline、未保存 hash value、未修改 harness、未实现 baseline compare、pixel diff 或 offscreen renderer。
- P1 frame hash baseline-readiness diagnostics first slice 已在 screenshot verification harness 内输出脱水 readiness summary；当前仍 `baseline_allowed=false`，不保存 hash value，不建立 baseline / golden hash，不做 baseline compare、pixel diff、offscreen renderer 或 public runtime API。
- P1 frame hash baseline owner / update policy preflight 只冻结 human owner、human review、AI auto-update 禁止规则和 proposal / approval / rejection / defer 流程；当前仍不允许 baseline / golden hash，不保存 hash value，不做 baseline compare、pixel diff 或 offscreen renderer。
- P1 frame hash baseline owner / update policy execution card 只授权未来极窄 owner / update policy diagnostics 或 checklist first slice；本卡创建本身未修改 harness、未保存 hash value、未实现 baseline / golden hash、baseline compare、pixel diff、offscreen renderer 或 public runtime API。

## 当前 future openings

以下内容可以保留为 future opening，但都不自动开启：

### 0A. AI-native UI semantics

状态：

- 已记录为长期方向
- 不作为当前实现入口

入口：

- [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)

边界：

- 不实现 semantic tree
- 不实现 action router
- 不引入 AI runtime
- 不开启无障碍系统
- 只在未来 Element / Scene / Renderer 设计中保留语义投影空间
- P1 最多预留稳定 `id` / `tag` / debug label 这类拓扑口，不生成语义系统

### 0A.1 AI Action Protocol S-expression Experiment

状态：

- 已记录为长期协议实验归档
- 不作为当前实现入口
- 不改变当前 window lifecycle / runtime lifecycle 主线

入口：

- [AI_ACTION_PROTOCOL_EXPERIMENT.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_ACTION_PROTOCOL_EXPERIMENT.md)

当前结论：

- RPN rejected：隐式栈不适合作为 AI-authored UI action command 格式。
- JSON not preferred for complex AI-authored action DSL：JSON 不作为复杂 AI 生成动作 DSL 的默认首选，但仍可作为 snapshot、debug、IPC envelope、audit log 等普通数据格式候选。
- Lisp-style S-expression 是未来 AI-authored Action Command 的 preferred north-star candidate。

当前边界：

- 不实现 S-expression action protocol。
- 不实现 Action Router。
- 不实现 semantic tree。
- 不引入 AI runtime。
- 不设计 IPC server。
- 不把 S-expression 当成 executable Lisp。
- 禁止 `eval`、macro、user-defined function、arbitrary symbol execution。
- 未来正式协议必须先 parse 成 restricted AST / typed ActionRequest，再经过 zero-trust Action Gateway 回到 application owner。

### 0B. open-nwe future host demand map

状态：

- 已记录为 future demand map
- 不作为当前实现入口

入口：

- [OPEN_NWE_PRODUCT_DEMAND_MAP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/OPEN_NWE_PRODUCT_DEMAND_MAP.md)

边界：

- 不迁移 `open-nwe` 当前 React 前端
- 不为了 `open-nwe` 提前开启输入框 / IME / 富文本 / 终端 / 编辑器
- 只把 `open-nwe` 当作复杂桌面应用压力测试样本

### 0C. Cangjie GUI Skillization / Knowledge Distillation Preflight

状态：

- 已记录为 knowledge / skill future opening
- 不作为当前实现入口
- 不干扰当前 P1 GUI runtime 推进
- `CangjieSkills` / `DocFlow` 可以安装或保留为本地辅助知识源，但安装不等于每轮强制读取

2026-04-25 检查 / 接入结果：

- `CangjieSkills` 已从本地仓库 [repos/CangjieSkills](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills) 接入到 `/Users/jiangxuanyang/.agents/skills`，采用符号链接指向本地仓库的 `.agents/skills/*`。
- 当前可用的 `CangjieSkills` skill 名称：`cangjie-lang-features`、`cangjie-original-docs`、`cangjie-regulations`、`cangjie-std`、`cangjie-stdx`、`cangjie-toolchains`。
- `DocFlow` 本地仓库 [repos/DocFlow](/Users/jiangxuanyang/Desktop/cangjie/repos/DocFlow) 当前没有 `SKILL.md`，不强行包装为 Codex skill；只保留为 knowledge / tool repo。
- 本次接入不构成新的 GUI runtime opening，不改变当前 next opening，也不让任何外部 skill 成为项目事实真相源。

背景：

- 本项目不只有 GUI runtime 线，也有 Knowledge / Skill 线。
- 早期已经研究过 `CangjieSkills` 和 `DocFlow`，当前本地仓库位于 [repos/CangjieSkills](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills) 和 [repos/DocFlow](/Users/jiangxuanyang/Desktop/cangjie/repos/DocFlow)。
- 后续又把仓颉官方文档、本机 SDK 安装、`MacOSX26.4.sdk` 链接问题、C FFI smoke、macOS AppKit / Metal bridge smoke、P1 bridge cleanup、主线程消息队列和 GUI 验证经验沉淀到本地文档。

未来 preflight 要回答：

- 哪些内容应该进入 Codex / AI skill，哪些只留在项目文档。
- skill 的入口文件是什么。
- skill 如何引用本地仓颉官方文档、issue ledger、`BUILD_FROM_ZERO.md` 和 smoke demos。
- 如何避免 skill 变成过时知识。
- 哪些仓颉工具链 bug / workaround 要进入 skill。
- AI 执行 GUI 任务前应该自动读取哪些最小知识。
- skill 和项目文档谁是真相源。

当前共识：

- 可以安装 `CangjieSkills` / `DocFlow` 相关 skill 或工具作为本地辅助知识源，前提是记录来源和版本，不把安装动作解释为新的 runtime opening。
- 安装后的 `CangjieSkills` / `DocFlow` 不作为每轮 execution card 的强制必读入口，也不自动扩大执行 AI 的默认上下文。
- 如果安装后的 skill 触发行为过宽、内容过时或与本项目治理冲突，应以本项目文档和已验证 smoke / harness 为准。
- 凡涉及仓颉语法、FFI、`cjc` / `cjpm`、标准库、构建参数或工具链 workaround，执行 AI 不能只凭模型记忆。
- 执行 AI 不应每轮大量翻阅 `CangjieSkills` / `DocFlow`，避免知识源过载、效率下降和过时知识干扰当前 bounded slice。
- 默认查证顺序应是：先读当前 execution card / closure / tracker，再读本项目最小相关文档和 smoke；只有遇到仓颉语法、FFI、`cjc` / `cjpm`、标准库或工具链不确定性时，才按需查本地仓颉官方文档、[BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)、[CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)、[cffi_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke)、[macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)。
- `CangjieSkills` / `DocFlow` 只作为第三层辅助参考：当本项目文档和官方本地文档不能回答问题，或需要理解已有 skill 经验时再查，不作为每次执行的强制阅读项。
- 凡进入代码实现的仓颉语法或 FFI 判断，必须通过 `cjc` / `cjpm` 编译、smoke 或相应 harness 验证。

当前边界：

- 不创建 skill。
- 不在本 opening 内实现 skill installer / skill package，也不把安装辅助 skill 当作 GUI runtime 进度。
- 不重写现有项目文档为 skill。
- 不把 skill 当成项目事实真相源；当前真相仍以项目文档、官方本地文档和已验证 smoke 为准。
- 不让 Knowledge / Skill 线抢占当前 P1 runtime 的 bounded slice。

### 0D. Governance Compaction / Truth Manifest Preflight

状态：

- 已由 [2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md) 登记为 future opening
- 不作为当前实现入口
- 不阻塞下一张 minimal app / window lifecycle runtime execution card，但在 runtime 线继续扩大前应重新评估

目标：

- 压缩已经稳定的 P0 / P1 决策。
- 降低执行 AI 每轮上下文负担。
- 明确当前最小 truth snapshot。
- 判断是否创建 `CJGUI_TRUTH_MANIFEST.md` 或等价 manifest。

当前边界：

- 不创建 manifest。
- 不重写历史文档。
- 不让 compaction 发明新能力。
- 不取代 current execution card 的局部 authority。

### 0E. Render Evidence Model / Command List Hash Preflight

状态：

- 已由 red-team risk intake 登记为 future opening
- 不作为当前 runtime lifecycle 入口
- 应在进入 Renderer / render pipeline 前重新打开

目标：

- 判断业务回归 evidence 是否应优先基于 render command list / display list，而不是 pixel-perfect screenshot hash。
- 明确 command list 是 truth、projection 还是 diagnostics。
- 明确 command hash 是否允许保存、谁拥有 baseline、如何避免第二真相源。

当前边界：

- 不定义 Display List / Command Buffer API。
- 不实现 command hash。
- 不重开 pixel diff / baseline。
- 不进入 Renderer / Scene。

### 0F. Semantic Projection Lazy / Dirty Policy Preflight

状态：

- 已由 red-team risk intake 登记为 future opening
- 不作为当前 runtime lifecycle 入口
- 应在 Element / Scene / AI semantic tree 之前重新打开

目标：

- 冻结 semantic tree 是否默认 lazy / on-demand。
- 区分 render dirty 与 semantic dirty。
- 避免 semantic tree 进入 render hot path。
- 明确 Action Router 的 zero-trust 边界。

当前边界：

- 不实现 semantic tree。
- 不实现 Action Router。
- 不引入 AI runtime。
- 不开启无障碍系统。

### 0G. Redraw Invalidation / Dirty Rect Policy Preflight

状态：

- 已由 [2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md) 登记为 future opening
- 不作为当前 runtime lifecycle 入口
- 应在进入 redraw scheduling、Renderer 或 animation frame loop 前重新打开

目标：

- 冻结 invalidation owner、dirty region、idle behavior、animation request、resize / expose / state change 如何触发 redraw。
- 防止默认 global tick / blind redraw 变成 runtime 调度模型。

当前边界：

- 不实现 Dirty Rect。
- 不实现 frame scheduler。
- 不进入 Renderer / Scene。

### 0H. IME Composition Isolation / Cursor Rect Sync Preflight

状态：

- 已由 self-drawn / IME guardrails 登记为 future opening
- 不作为当前 runtime lifecycle 入口
- 应在 Text / Input / IME 之前重新打开

目标：

- 判断 `final committed string only` 能否作为早期隔离策略。
- 明确 preedit、candidate position、cursor rect / screen coordinate sync、composition cancel / commit、selection 和 scroll / layout 更新关系。

当前边界：

- 不实现 Input。
- 不实现 IME。
- 不把 committed string only 当成完整输入系统 contract。

### 0I. Accessibility Semantic Bridge Preflight

状态：

- 已由 self-drawn / IME guardrails 登记为 future opening
- 不作为当前 runtime lifecycle 入口
- 应在 accessibility 或 semantic projection 进入实现前重新打开

目标：

- 判断自绘 UI 如何在未来接回 OS accessibility。
- 明确 accessibility semantic bridge 与 AI semantic projection 的关系。
- 继续坚持 lazy / on-demand、render dirty 与 semantic dirty 分离。

当前边界：

- 不实现 Accessibility。
- 不实现 semantic tree。
- 不实现 Action Router。

### 1. 框架级事件模型冻结

前提：

- 第一平台运行时已经稳定

目标：

- 把平台原生事件翻译成框架自己的事件结构

### 2. 最小文本能力 preflight

前提：

- 窗口、事件、重绘已经稳定

目标：

- 明确第一阶段 `Text` 到底支持到什么程度

### 3. 基础布局系统 preflight

前提：

- 基础绘制路径稳定

目标：

- 明确布局 owner、布局输入输出、控件与布局的边界

### 4. 核心控件 first slice

前提：

- 运行时、事件、基础布局已清楚

目标：

- 只做极少量基础控件，而不是控件大全

## 当前不自动重开的线

下面这些线，在单独批准之前都不自动重开：

- 跨平台 backend
- 公共 DSL
- 输入框
- IME
- 无障碍
- 富文本
- 动画系统
- 主题系统
- 热重载
- 完整控件库

## 当前建议的下一步

如果继续推进，最合适的下一步是：

> `P1 lifecycle mutation plan draft bundle closure / next runtime behavior decision`

范围基于 [P1 lifecycle mutation plan draft bundle closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-lifecycle-mutation-plan-draft-bundle-closure-review.md)，对 internal-only mutation plan draft 做封账并决定下一条 runtime behavior boundary。当前 mutation plan 已能把 app lifecycle plan facts 放在 `app_lifecycle.cj`、window lifecycle plan facts 放在 `window_lifecycle.cj`，`runtime_state.cj` 只做 cross-owner plan summary；下一刀不应继续无判断地堆 wrapper。

当前 app lifecycle、window lifecycle 与 platform adapter 已证明 internal immutable state / fact、construction shape、NoOp function、极窄 marker transition、platform readiness fact -> lifecycle marker projection、internal lifecycle coordination result / function、默认 internal sanity function、app lifecycle observed platform readiness state、window lifecycle observed platform readiness state、app/window readiness predicate helpers、positive coordination readiness sanity helper、negative coordination readiness sanity helper、readiness sanity parity helper、internal runtime readiness aggregate type、internal runtime readiness aggregate builder、internal runtime bootstrap snapshot type、internal runtime bootstrap snapshot builder、internal runtime root state type、internal runtime root state builder、internal runtime root ready sanity helper、internal runtime step result type、first internal runtime step function，以及 internal runtime step ready sanity helper 都能落地。

下一步默认进入 `P1 lifecycle mutation plan draft bundle closure / next runtime behavior decision`。仍不得新增 public runtime API、public C ABI、AppKit / Metal / Objective-C 引用、platform object、native handle、raw pointer、callback binding、真实 event loop、真实 loop iteration、真实 work execution、真实 app/window lifecycle execution、app/window state mutation、调用 state-changing transition functions、`while` loop / scheduling loop、queue / drain、input processing、layout / render、app run / shutdown、window create / request close / destroy / release、handle table / generation、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、pixel diff、baseline 或 offscreen renderer。

本轮已完成 lifecycle mutation plan draft bundle implementation；下一轮应先做 closure / next-boundary decision，避免直接把 plan draft 变成真实 lifecycle mutation。

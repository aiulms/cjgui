# 仓颉 GUI 项目任务账本

最后更新：2026-05-01

本文件现在只做当前状态仪表盘，不再保存逐轮流水账。历史决策、closure、execution card 与 compaction 由 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 索引；本轮未新增 archive，因为被移除的 tracker 长历史已由 plans 索引与各 closure review 可追溯。

## 当前阶段

当前项目处于：

> `P1 runtime 受限实现 / runtime state transition runway`

长期目标仍是仓颉原生 GUI runtime / framework：上层尽量保持仓颉原生，底层通过极窄平台桥接接入窗口系统与渲染后端。当前还不是成熟 GUI toolkit，也不提供稳定 public API 或 public C ABI。

## 最小上下文入口

后续会话默认只需先读：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)：仓库总入口。
- 本 tracker：当前阶段、tail、stop-line、next opening。
- [2026-04-30-p1-runtime-tracker-compaction-execution-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-tracker-compaction-execution-runway.md)：当前 execution runway。
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)：runtime 内部链路与 stop-line。
- [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)：仅按 next opening 窄口读取相关 symbols。
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)：历史索引，不默认全文阅读。

## 当前 runtime execution tail

当前 execution-state loop closure tail 已到：

> `CjguiInternalRuntimeExecutionStateLoopClosure`

保留的 first internal execution attempt 仍是唯一允许执行 one-cycle candidate 的入口：

- `CjguiInternalRuntimeExecutionAttemptRequest`
- `CjguiInternalRuntimeExecutionAttemptReport`
- `cjguiInternalBuildRuntimeExecutionAttemptRequest`
- `cjguiInternalEvaluateRuntimeExecutionAttempt`
- `cjguiInternalExecuteRuntimeExecutionAttemptDraft`
- `cjguiInternalExecuteDefaultRuntimeExecutionAttemptDraft`

已移除的 pure post-attempt wrapper：

- `CjguiInternalRuntimeExecutionAttemptOutcomeRequest`
- `CjguiInternalRuntimeExecutionAttemptOutcomeReport`
- outcome builder / evaluator / executor
- outcome open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers

当前语义边界：

- allowed path 最多执行一个 `CjguiInternalRuntimeCycleRequest` candidate。
- blocked / deferred path 不执行 candidate。
- attempt report 不持有伪造 `CjguiInternalRuntimeCycleResult`。
- 这不是 event loop、scheduler、queue / drain、app run、global state commit、public API 或 C ABI。

## 最近关键 landed facts

- macOS AppKit / Metal smoke、auto-close guard、screenshot / frame hash / readback 相关实验已形成验证基础，但仍是 lab，不是 public runtime contract。
- `runtime/cjgui` 已具备最小 compilable package / internal source skeleton。
- app/window lifecycle owner-local state 已存在，并已完成 first internal immutable-copy mutation。
- runtime chain 已走过 readiness、run boundary、AppRun / RunLoop draft、lifecycle mutation、state publication、carry-forward、state holder、committed store、cycle feedback、next-cycle request、handoff、replay、replay outcome、execution admission、dry-run plan。
- first internal execution attempt 已落地：allowed path 调用一次 `cjguiInternalExecuteRuntimeCycle(plan.cycleRequestCandidate)`，blocked / deferred path 不执行。
- governance slimming / execution pivot 已生效：冻结继续新增 pure post-attempt wrapper / observation / feedback / result report 层。
- tail outcome wrapper compression 已完成：post-attempt outcome wrapper 被删除，execution tail 回到 attempt report。
- runtime execution convergence 已落地：新增单个 `CjguiInternalRuntimeExecutionConvergenceReport` 和直接 evaluator，将 attempt report 收敛为 converged / deferred / blocked / inconsistent fail-closed，不新增 Request 层或五件套 sanity。
- execution convergence next boundary decision 已完成：下一刀转向 commit candidate，只消费 convergence report，不新增 outcome / admission / dry-run wrapper。
- runtime execution commit candidate 已落地：新增单个 `CjguiInternalRuntimeExecutionCommitCandidate` 和直接 builder / default draft，只消费 convergence report，不执行新 cycle。
- runtime execution commit candidate next boundary decision 已完成：下一刀转向 commit readiness，只消费 commit candidate，不做 runtime global state commit。
- runtime execution commit readiness 已落地：新增单个 `CjguiInternalRuntimeExecutionCommitReadiness` 和直接 builder / default draft，只消费 commit candidate，不写 global state。
- runtime execution commit boundary 已落地：新增 commit record / finalization summary，只消费 commit readiness，不写 runtime global state。
- runtime state integration / tail consolidation decision 已完成：下一刀进入 W4 bundle，从 commit finalization 接回 existing runtime state tail chain，并清理重复尾链。
- runtime state integration / tail consolidation 已落地：新增 `CjguiInternalRuntimeExecutionStateIntegration`，从 commit finalization 接回 committed-state / feedback tail，并移除 carry-forward 恒 true marker。
- runtime execution-state loop closure decision 已完成：下一刀从 integration tail 进入 loop closure bundle，不回到 tiny boundary 或 admission / dry-run / replay / outcome wrapper。
- runtime execution-state loop closure 已落地：新增 `CjguiInternalRuntimeExecutionStateLoopClosure`，从 integration feedback 直接归拢 next internal cycle request candidate，并抽出 shared next-cycle request candidate helper；旧 replay / admission / dry-run wrappers 未删除但已被新 closure path 绕过。
- runtime old tail deprecation boundary decision 已完成：下一刀以 `CjguiInternalRuntimeExecutionStateLoopClosure` 作为 default tail endpoint，清理或降级旧 replay / admission / dry-run default-path helper。
- runtime old tail deprecation / default-path cleanup 已落地：新增 `cjguiInternalExecuteDefaultRuntimeTailDraft()` 指向 loop closure，删除旧 replay / replay outcome / admission / dry-run open-default sanity helper；旧 core tail symbols 与 blocked sanity 保留为 legacy diagnostics / trace。
- runtime internal tail milestone decision 已完成：当前 P1 runtime internal tail 达到 milestone baseline；下一刀转向 manifest / docs stabilization，而不是继续无限清理 old tail 或新增 behavior wrapper。
- runtime internal tail milestone stabilization 已完成：新增 [internal tail manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-internal-tail-milestone-manifest.md)，runtime README 已压缩 tail history 并指向 default tail / legacy diagnostics baseline；本轮未修改 `runtime_state.cj`。
- next real runtime boundary decision 已完成：选择 internal runtime state store transition 作为下一块真实边界；暂不进入 input intent、scheduler tick、app/window mutation follow-up 或 platform fact ingestion。
- internal runtime state store transition boundary 已落地：新增 value-style version / snapshot / transition，default executor 从 `cjguiInternalExecuteDefaultRuntimeTailDraft()` 取得 loop closure，并从 integration committed state 构造 previous snapshot；open path 只返回 version+1 的 next snapshot，defer / blocked path 保留 previous snapshot。
- runtime state store transition next boundary decision 已完成：选择先做 state store transition stabilization，稳定 version / snapshot / transition owner 与 manifest；暂缓 input intent、scheduler tick 和 platform fact。
- runtime state store transition stabilization 已完成：新增 [state store transition manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-state-store-transition-manifest.md)，补充 open/defer/blocked derived helper，并将 README 指向 manifest；未新增 wrapper / Request+Report / 五件套 sanity。
- runtime input-or-scheduler boundary decision 已完成：选择 `P1 internal input intent boundary bundle implementation`；input intent 作为 future event loop / platform input 前置，但必须保持脱水、internal-only，不接平台事件 / queue / scheduler。
- internal input intent boundary 已落地：新增 source / kind / intent / admission value types，默认 synthetic activation present 可 admit；absent intent defer，invalid source / kind fail-closed blocked；本层不是 platform event object，不写 queue / event loop / scheduler，不执行 runtime cycle。
- input routing boundary decision 已完成：下一刀进入 `P1 internal input routing boundary bundle implementation`；routing 只消费 `CjguiInternalInputIntentAdmission`，只表达 future runtime ingress candidate，不接平台事件、queue、event loop 或 scheduler。
- internal input routing boundary 已落地：新增 `CjguiInternalInputRoutingResult`、route function 与 default routing draft；admitted intent 变成 future runtime ingress candidate，defer / blocked 维持 defer / fail-closed blocked；不 enqueue、不 dispatch、不执行 cycle。
- input-to-runtime ingress boundary decision 已完成：下一刀进入 `P1 internal input-to-runtime ingress boundary bundle implementation`；ingress 只消费 input routing result，并可消费 runtime state store transition context，只判断 future runtime state boundary 是否接受 input candidate。
- internal input-to-runtime ingress boundary 已落地：新增 `CjguiInternalInputRuntimeIngress`、builder 与 default draft；它组合 input routing result 与 runtime state store transition context，只表达当前 runtime state boundary 是否接受脱水 input candidate；不 enqueue、不 dispatch、不接 event loop / queue / scheduler / platform、不执行 runtime cycle、不写 global state。
- input-to-runtime ingress next boundary decision 已完成：选择先做 `P1 internal input-to-runtime ingress stabilization bundle implementation`，稳定 ingress manifest / default path / stop-lines，暂缓 scheduler tick 与 Action Router。
- input-to-runtime ingress stabilization 已完成：新增 [ingress manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-input-to-runtime-ingress-manifest.md)，runtime README 指向 ingress 主线 / stop-line；因 `runtime_state.cj` 已处于 critical warning，本轮未新增源码 helper。
- scheduler-or-Action-Router boundary decision 已完成：选择 `P1 internal scheduler tick intent boundary bundle implementation`，但下一轮默认新建 `runtime_scheduler.cj` 或等价 scheduler owner file，不继续把新 scheduler subsystem 塞进 critical `runtime_state.cj`。
- internal scheduler tick intent boundary 已落地：新增 `runtime_scheduler.cj` 承载 scheduler tick source / kind / intent / admission；默认 synthetic cycle-preparation present 可 admit，absent tick defer，invalid source / kind fail-closed blocked；本层不是 event loop、queue / drain、scheduler implementation、platform timer 或 runtime cycle execution，且未触碰 critical `runtime_state.cj`。
- scheduler-to-runtime ingress boundary decision 已完成：下一刀进入 `P1 internal scheduler-to-runtime ingress boundary bundle implementation`；默认 owner / write set 仍是 `runtime_scheduler.cj`，只消费 scheduler tick admission 并可读取 runtime state store transition context，不实现 scheduler、queue、event loop 或 runtime cycle。
- internal scheduler-to-runtime ingress boundary 已落地：新增 `CjguiInternalSchedulerRuntimeIngress`、builder 与 default draft；它组合 scheduler tick admission 与 runtime state store transition context，只表达 admitted tick 是否可成为 future runtime pacing / cycle-preparation candidate；不 enqueue、不实现 scheduler、不接 queue / event loop / platform timer、不执行 runtime cycle，且 `runtime_state.cj` 未触碰。
- runtime pacing next boundary decision 已完成：选择 `P1 internal runtime ingress coordinator boundary bundle implementation`；下一刀归并 input-to-runtime ingress 与 scheduler-to-runtime ingress，默认新建 `runtime_ingress.cj` 或等价 ingress owner file，不回塞 critical `runtime_state.cj`。
- internal runtime ingress coordinator boundary 已落地：新增 `runtime_ingress.cj` 承载 `CjguiInternalRuntimeIngressCoordinator`、coordinator builder 与 default draft；它只组合 input ingress 与 scheduler ingress 的 ready / defer / blocked facts，不 enqueue、不 dispatch、不接 event loop / queue / scheduler implementation、不执行 runtime cycle，且 `runtime_state.cj` / `runtime_scheduler.cj` 未触碰。
- runtime ingress manifest stabilization decision 已完成：下一刀进入 `P1 internal runtime ingress manifest stabilization bundle implementation`，先固定 input / scheduler / coordinator 三条 ingress 主线与 owner / truth / stop-line，暂缓 Action Router。
- runtime ingress manifest stabilization 已完成：新增 [runtime ingress manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-ingress-manifest.md)，README 指向 current ingress front door；`runtime_ingress.cj` 只新增两个 derived helper，不新增 behavior wrapper，且 `runtime_state.cj` / `runtime_scheduler.cj` 未触碰。
- Action Router or queue boundary decision 已完成：选择 `P1 internal queue admission boundary bundle implementation`；先定义 dehydrated queue admission readiness 作为 Action Router 的下游前置，不实现 queue storage / enqueue side effect / drain / event loop。
- internal queue admission boundary 已落地：新增 `runtime_queue.cj` 承载 queue admission policy / admission / evaluator / default draft；它只消费 runtime ingress coordinator，表达 future queue admission readiness，不实现 queue storage、enqueue side effect、drain、scheduler、event loop 或 runtime cycle，且 `runtime_state.cj` / `runtime_ingress.cj` 未触碰。
- queue or Action Router boundary decision 已完成：选择 `P1 internal Action Router boundary decision / implementation runway`；下一步从 internal-only dehydrated action intent / admission runway 开始，并消费 queue admission readiness 作为下游提交门，暂不继续 enqueue-intent wrapper。
- Action Router implementation runway decision 已完成：批准下一刀进入 `P1 internal Action Router action intent boundary bundle implementation`；第一刀只允许 new `action_router.cj` owner file 中的 dehydrated action source / kind / intent / admission，并必须消费 queue admission readiness，不接 AI provider / prompt / external agent，不执行 action。
- internal Action Router action intent boundary 已落地：新增 `action_router.cj` 承载 action source / kind / intent / admission；default 为 system origin + runtime-boundary action，并消费 queue admission readiness 作为下游 gate；本层不执行 action、不公开 AI API、不接 model provider / prompt / external agent、不写 queue / enqueue / drain、不接 event loop / scheduler / platform，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- Action Router routing boundary decision 已完成：下一刀进入 `P1 internal Action Router routing boundary bundle implementation`；routing 只消费 `CjguiInternalActionAdmission`，只表达 runtime boundary route candidate / defer / blocked，不执行 action、不接 AI provider / public API、不写 queue，并继续使用 `action_router.cj` owner file。
- internal Action Router routing boundary 已落地：新增 `CjguiInternalActionRoutingResult`、route function、default routing draft 与 single derived helper；admitted action intent 转成 runtime boundary route candidate，defer / blocked / inconsistent fail-closed；本层不执行 action、不写 queue / enqueue / drain、不接 AI provider / public API / event loop / scheduler / platform，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- Action Router manifest stabilization decision 已完成：下一刀进入 `P1 internal Action Router manifest stabilization bundle implementation`；先固定 action intent / admission / routing 的 owner / truth / stop-line，暂缓 action execution、AI provider / prompt / external agent、public API、queue enqueue / drain。
- Action Router manifest stabilization 已完成：新增 [Action Router manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-action-router-manifest.md)，固定 `action_router.cj` owner、`CjguiInternalQueueAdmission` upstream gate、`ActionIntent -> ActionAdmission -> ActionRoutingResult` 主线与 stop-line；`action_router.cj` 只新增两个 pure derived helper，`runtime_state.cj` / `runtime_queue.cj` 未触碰。
- action execution-or-queue next boundary decision 已完成：选择 `P1 internal Action Router dispatch admission boundary bundle implementation`；下一刀只消费 `CjguiInternalActionRoutingResult` 并表达 dispatch admission readiness，不直接 action execution、不写 queue / enqueue / drain、不接 AI provider / prompt / external agent。
- internal Action Router dispatch admission boundary 已落地：新增 `CjguiInternalActionDispatchAdmission`、builder、default draft 与 single derived helper；它只消费 `CjguiInternalActionRoutingResult`，把 route candidate 投影为 future dispatch boundary readiness；不执行 action、不写 queue / enqueue / drain、不接 AI provider / prompt / external agent、不公开 API / C ABI、不接 event loop / scheduler / platform、不执行 runtime cycle，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- action dispatch next boundary decision 已完成：选择 `P1 internal Action Router dispatch plan boundary bundle implementation`；下一刀只消费 `CjguiInternalActionDispatchAdmission` 并表达 value-style dispatch plan candidate / defer / blocked，仍不执行 action、不写 queue / enqueue / drain、不接 AI provider / prompt / external agent。
- internal Action Router dispatch plan boundary 已落地：新增 `CjguiInternalActionDispatchPlan`、builder、default draft 与 single derived helper；它只消费 `CjguiInternalActionDispatchAdmission`，把 dispatch admission 投影为 value-style dispatch plan candidate / defer / blocked；不执行 action、不写 queue / enqueue / drain、不接 AI provider / prompt / external agent、不公开 API / C ABI、不接 event loop / scheduler / platform、不执行 runtime cycle，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- internal Action Router dispatch convergence bundle 已落地：新增 dispatch convergence / commit candidate / finalization 三段相邻 value-style stages；它们只从 `CjguiInternalActionDispatchPlan` 向下收束 ready / defer / blocked facts，不执行 action、不写 queue / enqueue / drain、不接 AI provider / prompt / external agent、不公开 API / C ABI、不接 event loop / scheduler / platform、不执行 runtime cycle，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- action boundary next decision 已完成：选择 `P1 internal Action Router dispatch record / manifest stabilization bundle implementation`；下一刀围绕 dispatch finalization 固定 lightweight record / manifest，暂缓 action execution、queue enqueue / drain 和 AI provider / semantic projection。
- internal Action Router dispatch record / manifest stabilization 已落地：新增 `CjguiInternalActionDispatchRecord`、builder、default draft 与 single derived helper，并更新 Action Router manifest 当前 runway；record 只记录 finalization 形成的 internal value-style dispatch boundary，不是 action execution record、queue enqueue record 或 public audit log，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- Action Router same-owner bundle runway decision 已完成：选择 `P1 internal Action Router effect model / execution guard same-owner bundle implementation`；下一刀必须是 `action_router.cj` same-owner W3 bundle，而不是 one-symbol micro-slice，仍不执行 action、不写 queue、不接 AI provider / public surface。
- internal Action Router effect model / execution guard same-owner bundle 已落地：新增 effect model / execution guard / execution readiness 三段相邻 value-style concepts；它们只从 dispatch record 投影 future action execution 的 effect category / guard / readiness，不执行 action、不写 queue、不接 AI provider / prompt / external agent、不公开 API / C ABI、不接 event loop / scheduler / platform、不执行 runtime cycle，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- Action execution boundary decision 已完成：选择 `P1 internal Action Router first execution attempt bundle implementation`；下一刀只允许把 `CjguiInternalActionExecutionReadiness` 投影为 internal value-style attempt / result summary，仍不执行真实 action、不写 queue、不接 AI provider / public surface。
- internal Action Router first execution attempt bundle 已落地：新增 `CjguiInternalActionExecutionAttempt` / `CjguiInternalActionExecutionAttemptResult`、builder / evaluator / default draft 与 two derived helpers；它们只消费 execution readiness 并表达 attempt accepted / deferred / blocked summary，不产生真实 action side effect、不写 queue、不接 AI provider / prompt / external agent、不公开 API / C ABI、不接 event loop / scheduler / platform、不执行 runtime cycle，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- Action execution attempt next-boundary decision 已完成：选择 `P1 internal Action Router execution convergence / commit candidate bundle implementation`；下一刀只允许消费 `CjguiInternalActionExecutionAttemptResult`，将 accepted / deferred / blocked attempt facts 收束为 future execution commit candidate values，仍不执行真实 action、不产生 side effect、不写 queue、不接 AI provider / public surface。
- internal Action Router execution convergence / commit candidate bundle 已落地：新增 execution convergence / commit candidate / finalization 三段相邻 value-style concepts；它们只消费 `CjguiInternalActionExecutionAttemptResult` 的 accepted / deferred / blocked facts，收束为 internal execution boundary summary，不执行真实 action、不产生 side effect、不写 queue、不接 AI provider / public surface，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- Action execution convergence next-boundary decision 已完成：选择 `P1 internal Action Router execution record / manifest stabilization bundle implementation`；下一刀先固定 lightweight execution record + manifest truth，暂缓 execution policy、真实 action side effect、queue enqueue / drain 和 AI provider / public surface。
- internal Action Router execution record / manifest stabilization 已落地：新增 `CjguiInternalActionExecutionRecord`、builder、default draft 与 single derived helper，并更新 Action Router manifest 当前 runway；record 只记录 finalization 形成的 internal value-style execution boundary，不是真实 action execution record、queue enqueue record、provider response 或 public audit log，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- Action Router tail consolidation-or-execution-policy decision 已完成：选择 `P1 internal Action Router tail consolidation bundle implementation`；下一刀不再继续新增薄 outcome / readiness / report wrapper，而是先做 same-owner tail consolidation，降低 Action Router tail 模型债务。
- internal Action Router tail consolidation 已落地：删除无 `.cj` 调用点的 `cjguiInternalActionRoutingShouldDefer`、`cjguiInternalActionRoutingShouldReportBlocked`、`cjguiInternalActionExecutionRecordDidRecord`，保留被 canonical builder 消费的 helper，并补充 dispatch / execution tail 中文维护注释；未改变 open / defer / blocked 语义。
- Action Router tail consolidation closure next execution policy decision 已完成：确认 `CjguiInternalActionExecutionRecord` / `cjguiInternalExecuteDefaultActionExecutionRecordDraft()` 是 canonical endpoint，下一刀进入 `P1 internal Action Router execution policy model bundle implementation`；policy 只能消费 execution record 并表达 internal value-style future execution constraints，不执行真实 action、不写 queue、不接 AI provider / public surface。
- internal Action Router execution policy model bundle 已落地：新增 `CjguiInternalActionExecutionPolicyModel` / `Gate` / `Readiness` 与 builders / default draft；它们只消费 `CjguiInternalActionExecutionRecord`，把 execution record 投影为 future execution policy constraints / gate / readiness，不执行真实 action、不产生 side effect、不写 queue、不接 AI provider / public surface，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- Action execution policy next-boundary decision 已完成：选择 `P1 internal Action Router guarded execution attempt boundary bundle implementation`；下一刀只消费 `CjguiInternalActionExecutionPolicyReadiness`，把 policy readiness 投影为 guarded attempt / result value facts，仍不执行真实 action、不产生 side effect、不写 queue、不接 AI provider / public surface。
- internal Action Router guarded execution attempt boundary 已落地：新增 `CjguiInternalActionGuardedExecutionAttempt` / `AttemptResult` / `Acceptance` 与 builders / evaluator / default draft；它们只消费 `CjguiInternalActionExecutionPolicyReadiness`，把 policy readiness 投影为 guarded attempt accepted / deferred / blocked facts，不执行真实 action、不产生 side effect、不写 queue、不接 AI provider / public surface，且 `runtime_state.cj` / `runtime_queue.cj` 未触碰。
- guarded execution next-boundary decision 已完成：选择 `P1 internal Action Router guarded execution commit / effect boundary bundle implementation`；下一刀只消费 `CjguiInternalActionGuardedExecutionAcceptance`，把 acceptance 收束为 future execution commit / effect value facts，仍不执行真实 action、不产生 side effect、不写 queue、不接 AI provider / public surface。
- internal Action Router guarded execution commit / effect boundary 已落地：新增 `CjguiInternalActionGuardedExecutionEffectPlan` / `CommitCandidate` / `Finalization` 与 builders / finalizer / default draft；它们只消费 `CjguiInternalActionGuardedExecutionAcceptance`，把 guarded acceptance 收束为 future execution effect plan / commit candidate / finalization facts，不执行真实 action、不产生 side effect、不写 queue、不接 AI provider / public surface，且 `runtime_state.cj` / `runtime_queue.cj` / `runtime_scheduler.cj` / `runtime_ingress.cj` 未触碰。
- guarded execution finalization next-boundary decision 已完成：选择 `P1 internal Action Router guarded execution result publication boundary bundle implementation`；下一刀只消费 `CjguiInternalActionGuardedExecutionFinalization`，把 finalization 投影为 internal result publication / handoff candidate facts，仍不执行真实 action、不产生 side effect、不写 queue、不接 AI provider / public surface。
- internal Action Router guarded execution result publication boundary 已落地：新增 `CjguiInternalActionGuardedExecutionResultPublication` / `HandoffCandidate` 与 publication / handoff builders / default draft；它们只消费 `CjguiInternalActionGuardedExecutionFinalization` 和 downstream publication value，把 guarded finalization 投影为 internal result publication / handoff candidate facts，不执行真实 action、不产生 side effect、不写 queue、不接 AI provider / public surface，不触发 observer callback，且 `runtime_state.cj` / `runtime_queue.cj` / `runtime_scheduler.cj` / `runtime_ingress.cj` 未触碰。
- tail endpoint exit governance patch 已完成：新增 Tail Endpoint Exit Gate，明确 `CjguiInternalActionGuardedExecutionHandoffCandidate` 是当前 Action Router canonical endpoint；下一步不得继续追加同 owner handoff readiness / record / outcome / publication record 等薄 tail，必须转向 downstream consumer / handoff integration、permission gate decision、milestone closure 或 tail consolidation。
- Action Router handoff endpoint next-boundary decision 已完成：选择 `P1 internal Action Router handoff downstream consumer boundary bundle implementation`；下一刀应由新的 downstream handoff owner 消费 `CjguiInternalActionGuardedExecutionHandoffCandidate`，表达 internal receiver / consumer acceptance facts，而不是继续在 `action_router.cj` 自我包装，也不执行真实 action、不写 queue、不接 provider / public surface。
- internal Action Router handoff downstream consumer boundary 已落地：新增 `runtime/cjgui/src/action_handoff.cj`，定义 `CjguiInternalActionHandoffConsumer` / `Acceptance` / `Receipt` 与 builders / default draft；它只消费 `CjguiInternalActionGuardedExecutionHandoffCandidate`，把 Action Router canonical endpoint 投影为 downstream receiver / acceptance / receipt facts，不执行真实 action、不写 queue、不接 provider / public surface，且未回改 `action_router.cj` / `runtime_state.cj` / `runtime_queue.cj` / `runtime_scheduler.cj` / `runtime_ingress.cj`。
- Action Handoff receipt next-integration decision 已完成：选择 `P1 internal Action Handoff queue integration boundary bundle implementation`；下一刀应新建 `action_handoff_queue.cj` 或等价 queue-integration owner，消费 `CjguiInternalActionHandoffReceipt` 并可读取 `CjguiInternalQueueAdmission` readiness，表达 internal queue handoff admission / integration candidate facts，不写 queue、不 enqueue、不 drain。
- internal Action Handoff queue integration boundary 已落地：新增 `runtime/cjgui/src/action_handoff_queue.cj`，定义 `CjguiInternalActionHandoffQueueAdmission` / `Integration` / `Candidate` 与 builders / default draft；它只消费 `CjguiInternalActionHandoffReceipt` 和 `CjguiInternalQueueAdmission` readiness，把 handoff receipt 投影为 queue-adjacent admission / integration candidate facts，不写 queue storage、不 enqueue、不 drain、不执行真实 action、不接 provider / public surface，且未回改 `action_router.cj` / `action_handoff.cj` / `runtime_queue.cj` / `runtime_state.cj` / `runtime_scheduler.cj` / `runtime_ingress.cj`。
- Action Handoff queue next-boundary decision 已完成：选择 `P1 internal Queue owner handoff consumer boundary bundle implementation`；下一刀应把 `CjguiInternalActionHandoffQueueCandidate` 交给 queue-side owner，优先新建 `runtime_queue_handoff.cj`，表达 queue owner consumer / acceptance / gate facts，仍不写 queue storage、不 enqueue、不 drain、不回塞 `runtime_state.cj` 或 `action_handoff_queue.cj` thin tail。
- internal Queue owner handoff consumer boundary 已落地：新增 `runtime/cjgui/src/runtime_queue_handoff.cj`，定义 `CjguiInternalQueueHandoffConsumer` / `Acceptance` / `Gate` 与 builders / default draft；它只消费 `CjguiInternalActionHandoffQueueCandidate`，把 queue-adjacent handoff candidate 投影为 queue-side consumer / acceptance / gate facts，不写 queue storage、不 enqueue、不 drain、不执行真实 action、不接 provider / public surface，且未回改 `action_router.cj` / `action_handoff.cj` / `action_handoff_queue.cj` / `runtime_queue.cj` / `runtime_state.cj` / `runtime_scheduler.cj` / `runtime_ingress.cj`。
- Queue handoff gate next-boundary decision 已完成：选择 `P1 internal Queue permission gate boundary bundle implementation`；下一刀应优先新建 `runtime_queue_permission.cj`，只消费 `CjguiInternalQueueHandoffGate`，表达 enqueue 前 internal permission / policy gate facts，仍不写 queue storage、不 enqueue、不 drain、不接 scheduler / event loop / runtime cycle。
- internal Queue permission gate boundary 已落地：新增 `runtime/cjgui/src/runtime_queue_permission.cj`，定义 `CjguiInternalQueuePermissionPolicy` / `Gate` / `Readiness` 与 builders / default draft；它只消费 `CjguiInternalQueueHandoffGate`，把 queue-side gate 投影为 enqueue 前 permission / policy / readiness facts，不写 queue storage、不 enqueue、不 drain、不执行真实 action、不接 provider / public surface，且未回改 `action_router.cj` / `action_handoff.cj` / `action_handoff_queue.cj` / `runtime_queue_handoff.cj` / `runtime_queue.cj` / `runtime_state.cj` / `runtime_scheduler.cj` / `runtime_ingress.cj`。
- Queue permission next-staging decision 已完成：选择 `P1 internal Queue staging model boundary bundle implementation`；下一刀应优先新建 `runtime_queue_staging.cj`，只消费 `CjguiInternalQueuePermissionReadiness`，表达 value-style queue staging model / candidate / readiness facts，仍不写真实 queue storage、不 enqueue、不 drain、不接 scheduler / event loop / runtime cycle，也不在 `runtime_queue_permission.cj` 末尾追加 permission thin wrapper。
- internal Queue staging model boundary 已落地：新增 `runtime/cjgui/src/runtime_queue_staging.cj`，定义 `CjguiInternalQueueStagedItem` / `StagingCandidate` / `StagingReadiness` 与 builders / default draft；它只消费 `CjguiInternalQueuePermissionReadiness`，把 enqueue 前 permission readiness 投影为 staged item / staging candidate / staging readiness facts，不写 queue storage、不 enqueue、不 drain、不接 scheduler / event loop / runtime cycle，且未回改 `runtime_queue_permission.cj` / `runtime_queue_handoff.cj` / `runtime_queue.cj` / `runtime_state.cj`。
- Queue staging next enqueue-boundary decision 已完成：选择 `P1 internal Queue enqueue dry-run plan boundary bundle implementation`；下一刀应新建 `runtime_queue_enqueue.cj` 或等价 enqueue dry-run owner，只消费 `CjguiInternalQueueStagingReadiness`，表达 future enqueue dry-run / shadow plan facts，仍不写 queue storage、不 enqueue、不 drain、不接 scheduler / event loop / runtime cycle，也不继续在 `runtime_queue_staging.cj` 末尾追加 thin tail wrapper。
- internal Queue enqueue dry-run plan boundary 已落地：新增 `runtime/cjgui/src/runtime_queue_enqueue.cj`，定义 `CjguiInternalQueueEnqueueDryRunPlan` / `ShadowCandidate` / `DryRunReadiness` 与 builders / default draft；它只消费 `CjguiInternalQueueStagingReadiness`，把 staging readiness 投影为 future enqueue dry-run / shadow candidate / dry-run readiness facts，不写 queue storage、不 enqueue、不 drain、不接 scheduler / event loop / runtime cycle，且未回改 `runtime_queue_staging.cj` / `runtime_queue_permission.cj` / `runtime_queue_handoff.cj` / `runtime_queue.cj` / `runtime_state.cj`。
- Queue enqueue dry-run next storage-boundary decision 已完成：选择 `P1 internal Queue value-style storage model boundary bundle implementation`；下一刀应优先新建 `runtime_queue_storage.cj`，只消费 `CjguiInternalQueueEnqueueDryRunReadiness`，表达 pending store / storage candidate / commit candidate value facts，仍不写真实 queue storage、不创建 global mutable queue、不 enqueue、不 drain、不接 scheduler / event loop / runtime cycle。
- internal Queue value-style storage model boundary 已落地：新增 `runtime/cjgui/src/runtime_queue_storage.cj`，定义 `CjguiInternalQueuePendingStore` / `StorageCandidate` / `StorageCommitCandidate` 与 builders / default draft；它只消费 `CjguiInternalQueueEnqueueDryRunReadiness`，把 dry-run readiness 投影为 pending store / storage candidate / commit candidate value facts，不写真实 queue storage、不创建 global mutable queue、不 enqueue、不 drain、不接 scheduler / event loop / runtime cycle，且未回改 `runtime_queue_enqueue.cj` / `runtime_queue_staging.cj` / `runtime_queue_permission.cj` / `runtime_queue_handoff.cj` / `runtime_queue.cj` / `runtime_state.cj`。
- Queue storage next commit-boundary decision 已完成：选择 `P1 internal Queue storage commit gate boundary bundle implementation`；下一刀应优先新建 `runtime_queue_commit.cj`，只消费 `CjguiInternalQueueStorageCommitCandidate`，表达 value-style storage commit gate / commit readiness facts，仍不写真实 queue storage、不创建 global mutable queue、不 enqueue、不 drain、不接 scheduler / event loop / runtime cycle。
- internal Queue storage commit gate boundary 已落地：新增 `runtime/cjgui/src/runtime_queue_commit.cj`，定义 `CjguiInternalQueueStorageCommitGate` / `CommitReadiness` / `CommitFinalizationCandidate` 与 builders / default draft；它只消费 `CjguiInternalQueueStorageCommitCandidate`，把 storage commit candidate 投影为 commit gate / readiness / finalization candidate value facts，不写真实 queue storage、不创建 global mutable queue、不 enqueue、不 drain、不接 scheduler / event loop / runtime cycle，且未回改 `runtime_queue_storage.cj` / `runtime_queue_enqueue.cj` / `runtime_queue_staging.cj` / `runtime_queue_permission.cj` / `runtime_queue_handoff.cj` / `runtime_queue.cj` / `runtime_state.cj`。
- Queue storage commit next-finalization decision 已完成：选择 `P1 internal Queue committed snapshot value boundary bundle implementation`；下一刀应优先新建 `runtime_queue_snapshot.cj` 或等价 committed-snapshot owner，只消费 `CjguiInternalQueueStorageCommitFinalizationCandidate`，表达 value-style committed queue snapshot / committed state candidate facts，仍不写真实 queue storage、不创建 global mutable queue、不 enqueue、不 drain、不接 scheduler / event loop / runtime cycle，也不继续在 `runtime_queue_commit.cj` 末尾追加 thin wrapper。
- 当前 tracker 已压缩为 current-state dashboard；历史追溯入口改为 plans README 与 closure review 链。
- source comment sufficiency / owner header cleanup 已完成：补充 `action_router.cj`、`runtime_ingress.cj`、`runtime_queue.cj`、`runtime_scheduler.cj` 的 owner / truth / stop-line 与少量 fail-closed / default draft 维护注释；本轮只做 comment-only cleanup，不改行为、签名、字段或 build config；`runtime_state.cj` 当前 10065 行 critical 已扫描但未触碰；closure 见 [2026-05-01-p1-source-comment-sufficiency-owner-header-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-source-comment-sufficiency-owner-header-cleanup-closure-review.md)。
- overnight automation produced unreviewed report：本轮自动化报告将写入 [2026-05-01-p1-overnight-safe-worktree-report.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-overnight-safe-worktree-report.md)；awaiting human review，后续自动化不得在人工确认前继续叠加推进。

## 当前 verification baseline

最近 runtime code 变更的验证基线来自 internal Queue storage commit gate boundary closure：

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-queue-storage-commit-gate-boundary-target --skip-script` 通过；仅保留既有 internal skeleton unused warnings 与 new queue storage commit-gate internal skeleton unused warning。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。
- GitNexus / owner split：new `runtime_queue_commit.cj` symbols impact 为 UNKNOWN / not found，`detect_changes(scope=unstaged)` 已运行；`runtime_state.cj` 当前 10065 行，处于 critical warning，本轮未修改该文件，`runtime_queue_storage.cj` / `runtime_queue_enqueue.cj` / `runtime_queue_staging.cj` / `runtime_queue_permission.cj` / `runtime_queue_handoff.cj` / `runtime_queue.cj` / `runtime_scheduler.cj` / `runtime_ingress.cj` / `action_router.cj` / `action_handoff.cj` / `action_handoff_queue.cj` 未修改。

## 当前统一 stop-line

继续禁止：

- public runtime API / public C ABI。
- AppKit / Metal / Objective-C 新接入，platform object、native handle、raw pointer 暴露。
- event loop、`while` loop / scheduling loop、scheduler、queue / drain、callback binding。
- app run / shutdown。
- window create / request close / close / destroy / release。
- runtime global state write、global mutable singleton。
- 多 cycle execution、next-cycle execution、真实 runtime step 扩展。
- new app/window state mutation、in-place mutation、改变既有 state field semantics。
- Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility。
- 修改 `runtime/cjgui/cjpm.toml`、`labs/macos_bridge_smoke` tracked source、harness、native bridge、仓颉入口、`src/main.cj`、`package_anchor.cj`。
- 单文件体积闸门已生效：`.cj` 文件超过 `1500` / `3000` / `8000` 行分别触发 soft / hard / critical warning。`runtime_state.cj` 当前已处于 critical warning 区间，后续提示词若继续修改它，必须包含 file-size / owner split check，并优先考虑 stabilization、tail consolidation 或 module extraction。
- AI 资源效率门已生效：同一 owner / truth / write set / stop-line 已清楚时，默认使用 W2 / W3 same-owner bundle。禁止把 `no execution` / `no queue` / `no provider` 写成“一轮只能新增一个 symbol”。连续两轮低风险薄 value-stage 后，下一轮必须升级为 bundle、consolidation 或 manifest stabilization。
- Tail Endpoint Exit Gate 已生效：manifest / tracker / closure 标记 canonical endpoint 后，下一步默认不得继续同 owner tail self-wrapping；应选择 downstream consumer / handoff integration、permission gate decision、milestone closure 或 tail consolidation。
- AI 发挥空间规则已生效：提示词应写目标、输入输出、invariant、stop-line 和验收标准，建议 symbol 不能默认变成填空式硬限制；同一 owner 内可让 AI 自主做合理拆分、合并、cleanup、注释补账和 manifest 同步。
- 代码注释充分性门已生效：新增 owner file、关键 boundary type、fail-closed / inconsistent 分支、default draft / executor 或 workaround 时，必须补最小维护注释；新增代码注释默认必须中文，必要英文技术名词可保留原文；不要给机械赋值写空注释，也不要把 comment-only 当 implementation。

## 当前 active opening

### `P1 internal Queue committed snapshot value boundary bundle implementation`

性质：bounded implementation / value-style committed queue snapshot

目标：

- 基于 [2026-05-01-p1-queue-storage-commit-next-finalization-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-queue-storage-commit-next-finalization-boundary-decision.md)，从 `CjguiInternalQueueStorageCommitFinalizationCandidate` 进入 value-style committed queue snapshot / committed state candidate。
- 默认新建 `runtime_queue_snapshot.cj` 或等价 committed-snapshot owner；不要继续在 `runtime_queue_commit.cj` 末尾追加 commit receipt / record / outcome / thin wrapper。
- 继续禁止真实 queue storage write、global mutable queue / singleton、enqueue side effect、drain、AI provider / public API、event loop / scheduler / platform 或 runtime cycle。

## 当前建议的下一步

> `P1 internal Queue committed snapshot value boundary bundle implementation`

下一轮应做 bounded implementation，优先新建 committed-snapshot owner，只消费 `CjguiInternalQueueStorageCommitFinalizationCandidate`，并生成 dehydrated committed queue snapshot / committed state candidate facts；不得打开真实 queue storage write / global mutable queue / enqueue / drain，也不得触碰 critical `runtime_state.cj`。

本 opening 不批准真实 action side effect、public API / C ABI、AI provider / prompt / external agent、event loop、queue / scheduler、platform callback、app run / shutdown、window create / close / destroy / release、多个 cycle execution、runtime global state write，或继续堆 pure wrapper / report / sanity 层。

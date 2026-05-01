# P1 Action Router Tail Consolidation Or Execution Policy Decision

日期：2026-05-01

## Current Landed Facts

- `ActionExecutionRecord` / manifest stabilization 已封账；`CjguiInternalActionExecutionRecord` 只消费 `CjguiInternalActionExecutionFinalization`。
- 当前 Action Router runway 已到 `ActionIntent -> ActionAdmission -> ActionRoutingResult -> ActionDispatchAdmission -> ActionDispatchPlan -> ActionDispatchConvergence -> ActionDispatchCommitCandidate -> ActionDispatchFinalization -> ActionDispatchRecord -> ActionEffectModel -> ActionExecutionGuard -> ActionExecutionReadiness -> ActionExecutionAttempt -> ActionExecutionAttemptResult -> ActionExecutionConvergence -> ActionExecutionCommitCandidate -> ActionExecutionFinalization -> ActionExecutionRecord`。
- execution record 只是 internal value-style execution boundary record，不是真实 action execution、queue enqueue record 或 public audit log。
- 新增关键 boundary / fail-closed / default draft 已补中文维护注释。
- `runtime_state.cj` 当前 10065 行，处于 critical warning，本轮不得触碰。

## Governance Notes

- 当前代码量少是因为 record stabilization 本身是薄边界，不是 AI 能力问题。
- AI 资源效率门继续生效：同一 owner / truth / stop-line 清楚时，不应继续 one-symbol 微切片。
- 下一步不得继续新增薄 execution outcome / readiness / report wrapper；应在 tail consolidation 与 execution policy runway 之间选择。

## Candidate Comparison

- A. `P1 internal Action Router tail consolidation bundle implementation`：推荐选择。Action Router tail 已出现多段 value-style finalization / record / convergence，继续追加 outcome / readiness wrapper 收益递减；先压缩或标记 legacy / diagnostics-only helpers，可降低模型债务。
- B. `P1 internal Action Router execution policy model bundle implementation`：可选但略早。policy / blocked reason / effect category 更实质，但当前 tail 过长，先 consolidation 更稳。
- C. 继续新增 execution outcome / readiness / report wrapper：禁止选择。这会回到薄 wrapper 链。
- D. 真实 action execution：禁止选择。真实 side effect 仍缺 policy、queue commit、rollback / audit、effect executor 边界。
- E. queue enqueue / drain：暂缓。Action execution record 不是 queue item，queue 仍不能被写入或 drain。
- F. AI provider / semantic projection：暂缓。当前仍不接 model / prompt / external agent / public surface。

## Decision

选择 A：`P1 internal Action Router tail consolidation bundle implementation`。

这是治理瘦身，不是阻止推进：tail consolidation 先把 Action Router 当前 canonical path、legacy / diagnostics-only symbols 与低价值 helper 边界讲清楚，避免在真实 execution policy 前继续堆薄 wrapper 债务。

## Approved Next Opening

`P1 internal Action Router tail consolidation bundle implementation`

## Guardrails For Next Implementation

- 默认 owner / write set：`runtime/cjgui/src/action_router.cj` + docs。
- 允许在同 owner 内做 behavior-preserving consolidation：删除或合并低价值 derived helper、固定 manifest canonical path、为 legacy / diagnostics-only symbols 加中文维护注释、在安全时合并明显重复的 finalization / record 投影逻辑。
- 不要求为了多写而多写；如果检查后没有安全可删项，应 fail closed 并只做 manifest stabilization，同时说明原因。
- 不得真实执行 action，不得产生 side effect。
- 不得写 queue / enqueue / drain。
- 不得接 AI provider / prompt / external agent。
- 不得新增 public API / C ABI。
- 不得接 event loop / scheduler / platform callback。
- 不得调用 runtime cycle。
- 不得触碰 critical `runtime_state.cj`；如未来必须触碰，必须先做 file-size / owner split check。
- 禁止新增 Request+Report 双层、五件套 sanity、execution outcome / readiness / report wrapper。
- 必须遵守中文注释规则。

## Verification Note

- 本轮 docs-only，不跑 `cjpm build` / smoke guard。
- 只跑 `git diff --check` / link check / Markdown absolute link check / forbidden file check。

# P1 Action Execution Convergence Next Boundary Decision

日期：2026-05-01

## Current Landed Facts

- Action Router owner file 是 `runtime/cjgui/src/action_router.cj`。
- 当前 runway 已到 `ActionIntent -> ActionAdmission -> ActionRoutingResult -> ActionDispatchAdmission -> ActionDispatchPlan -> ActionDispatchConvergence -> ActionDispatchCommitCandidate -> ActionDispatchFinalization -> ActionDispatchRecord -> ActionEffectModel -> ActionExecutionGuard -> ActionExecutionReadiness -> ActionExecutionAttempt -> ActionExecutionAttemptResult -> ActionExecutionConvergence -> ActionExecutionCommitCandidate -> ActionExecutionFinalization`。
- execution convergence / commit candidate bundle 已封账，且是 W2/W3 same-owner bundle，不是 one-symbol micro-slice。
- 新增维护注释已覆盖关键 boundary type、fail-closed / inconsistent 分支和 default draft。
- 当前仍没有真实 action execution、side effect、queue / enqueue / drain、AI provider / prompt / external agent、public API / C ABI、event loop / scheduler / platform 或 runtime cycle。
- `runtime_state.cj` 仍处于 10065 行 critical warning；Action Router work 不得回塞该文件。

## Candidate Comparison

- A. `P1 internal Action Router execution record / manifest stabilization bundle implementation`：推荐。execution finalization 已出现，应先固定 lightweight execution record + manifest truth，避免后续误读为真实 execution。
- B. `P1 internal Action Router execution policy runway bundle implementation`：有价值但稍早。effect execution policy / authorization 会靠近真实 side effect，应等 record / manifest 固定后再开。
- C. 真实 action execution：禁止。真实 side effect 仍缺 policy、queue commit、rollback / audit、effect executor 边界。
- D. queue enqueue / drain：暂缓。Action execution finalization 仍不是 queue item，queue 仍不能被写入或 drain。
- E. AI provider / semantic projection：暂缓。当前仍是 internal runtime contract，不接 model、prompt、external agent 或 public surface。

## Decision

选择 A：`P1 internal Action Router execution record / manifest stabilization bundle implementation`。

这是 next action boundary decision，但不是放开真实 execution。下一步只允许把 `CjguiInternalActionExecutionFinalization` 固定为 internal value-style execution boundary record，并同步 Action Router manifest；record 不是 action side-effect record，不是 queue enqueue record，也不是 public audit log。

AI 资源效率门继续生效：下一轮应是 W2 same-owner bundle，不回到 one-symbol micro-slice。代码注释充分性门也继续生效：新增 record / manifest stop-line 必须补最小维护注释。

## Approved Next Opening

`P1 internal Action Router execution record / manifest stabilization bundle implementation`

## Guardrails For Next Implementation

- 默认 owner / write set：`runtime/cjgui/src/action_router.cj` + docs。
- 只允许消费 `CjguiInternalActionExecutionFinalization`。
- 可新增 `CjguiInternalActionExecutionRecord`、builder、default draft、1 个 derived helper，并更新 Action Router manifest 当前 runway。
- record 只表示 internal value-style execution boundary 已形成，不是真实 execution record、public audit log 或 queue enqueue record。
- 不得真实执行 action，不得产生 side effect。
- 不得写 queue / enqueue / drain。
- 不得接 AI provider / prompt / external agent。
- 不得新增 public API / C ABI。
- 不得接 event loop / scheduler / platform callback。
- 不得调用 runtime cycle。
- 不得触碰 critical `runtime_state.cj`；若未来必须触碰，必须先做 file-size / owner split check。
- 禁止 Request+Report 双层、五件套 sanity、wrapper 链回潮。
- 必须遵守代码注释充分性门。

## Verification Note

- 本轮 docs-only，不跑 `cjpm build` / smoke guard。
- 只跑 `git diff --check` / link check / forbidden check。
- `CANGJIE_ISSUE_LEDGER.md` 正常不触发更新。

# P1 Guarded Execution Next Boundary Decision

日期：2026-05-01

## Current Landed Facts

- `P1 internal Action Router guarded execution attempt boundary bundle implementation` 已完成。
- 当前 guarded execution runway 是 `CjguiInternalActionExecutionPolicyReadiness -> CjguiInternalActionGuardedExecutionAttempt -> CjguiInternalActionGuardedExecutionAttemptResult -> CjguiInternalActionGuardedExecutionAcceptance`。
- 这些仍是 internal value-style guarded execution facts，不是真实 action execution。
- open path 将 policy readiness ready 投影为 attempted / accepted / acceptance；defer-only 保持 defer；blocked / inconsistent fail-closed blocked。
- 当前仍没有真实 action side effect、queue / enqueue / drain、AI provider / prompt / external agent / model session、public API / C ABI、event loop / scheduler / platform callback、runtime cycle 或 runtime global state write。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不触碰 runtime code。

## Candidate Comparison

- A. Guarded execution record / manifest stabilization：风险低，但 acceptance 后立刻新增 record 容易变成 thin record wrapper，除非 manifest truth 已明显缺口。
- B. Guarded execution commit / effect boundary：推荐。它只消费 guarded execution acceptance，把 accepted / deferred / blocked facts 收束为 future execution commit / effect plan value facts，继续不执行 action。
- C. Guarded execution tail consolidation：只有发现明确重复 helper 或 low-value projection 时才值得做；当前没有足够证据需要先 cleanup。

## Decision

选择 B：下一步进入 guarded execution commit / effect boundary。

理由：guarded acceptance 已经给出 policy-controlled execution runway 的入口，继续做 record/stabilization 会偏薄，直接 cleanup 也没有明确目标。commit / effect boundary 可以用 W2/W3 same-owner bundle 把 acceptance 推进为更有信息量的 future execution commit/effect facts，同时仍保持 no real execution、no side effect、no queue、no provider、no public surface。

## Approved Next Opening

`P1 internal Action Router guarded execution commit / effect boundary bundle implementation`

## Guardrails For Next Implementation

- 默认 owner / write set：`runtime/cjgui/src/action_router.cj` + docs。
- 只允许消费 `CjguiInternalActionGuardedExecutionAcceptance`。
- 允许 W2/W3 same-owner bundle，一次落相邻 value-style concepts，而不是 one-symbol 微切片。
- 推荐方向：guarded execution effect plan / commit candidate / finalization 或等价 endpoint。
- 输出只能是 internal value-style future execution commit / effect facts。
- 不得真实执行 action，不得产生 side effect。
- 不得写 queue / enqueue / drain / storage。
- 不得接 AI provider / prompt / external agent / model session。
- 不得新增 public API / C ABI。
- 不得接 event loop / scheduler / platform callback。
- 不得调用 runtime cycle，不得写 runtime global state。
- 不得触碰 critical `runtime_state.cj`；若未来声称必须触碰，必须先做 file-size / owner split check。
- 禁止 Request+Report 双层、五件套 sanity、thin outcome / report wrapper 回潮。

## Verification Note

- 本轮 docs-only，不运行 `cjpm build` / smoke guard。
- 只运行 `git diff --check`、entry link check、Markdown absolute link missing target check 和 forbidden 文件检查。
- 未发现新的仓颉语言 / SDK / FFI / 工具链 / 文档问题，`CANGJIE_ISSUE_LEDGER.md` 不触发更新。

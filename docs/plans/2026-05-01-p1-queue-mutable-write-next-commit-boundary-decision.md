# P1 Queue Mutable Write Next Commit-Boundary Decision

日期：2026-05-01

## 当前事实

`P1 internal Queue mutable store write admission boundary bundle implementation` 已完成。当前 endpoint 是 `CjguiInternalQueueMutableWriteReadiness`，由 `runtime_queue_mutable_write.cj` 提供，只消费 `CjguiInternalQueueMutableStoreShell`，表达 owner-local mutable write policy / version-check / admission / readiness value facts。

本轮是 docs-only boundary decision，未写 runtime code，未创建 execution card。`runtime_state.cj` 仍为 10065 行 critical warning，下一轮仍不得触碰，除非先做 file-size / owner split check。

## 候选比较

- A. milestone / manifest stabilization：风险最低，但 write admission 刚完成后继续只做 stabilization，会让 mutable write runway 停在文档空转；当前 owner / truth / stop-line 已清楚，不作为首选。
- B. owner-local mutable write commit boundary：只消费 `CjguiInternalQueueMutableWriteReadiness`，表达 owner-local mutable write commit / commit result / post-write holder facts；仍禁止 module-level `var`、global singleton、process-wide queue storage、public mutable API、cross-owner mutable reference、runtime global state write、public enqueue、drain、scheduler / event loop / platform / runtime cycle。它是 write admission 后的自然下一刀，选择。
- C. rollback / failure strengthening：`runtime_queue_store_rollback.cj` 已覆盖 previous-snapshot-preservation，mutable write admission 也已有 fail-closed / version mismatch 语义；如果 commit result shape 落地后发现 rollback token 或 post-write holder failure 缺口，再补更有目标。
- D. public enqueue API / enqueue surface：暂缓。当前还没有 owner-local mutable commit result，更不应靠近 public API 或用户可见 side effect。
- E. drain / scheduler / event loop boundary：暂缓。当前还没有真实 enqueue 或 committed mutable holder，靠近 scheduler / event loop / runtime cycle 太早。
- F. runtime state integration：暂缓。会靠近 critical `runtime_state.cj` 与 runtime global state write，必须等 owner-local mutable write runway 更清楚后再评估。
- G. tail consolidation：暂缓。当前没有发现明确 dead helper、重复 projection 或 self-wrapping 债务；为了 cleanup 而 cleanup 会分散主线。

## Decision

选择 B：`P1 internal Queue owner-local mutable write commit boundary bundle implementation`。

这不是批准真实 queue storage write。下一轮只允许从 `CjguiInternalQueueMutableWriteReadiness` 进入 owner-local mutable write commit value facts，形成 commit / result / post-write holder summary；不得变成 process-wide queue storage、global singleton、public enqueue API、drain plan、scheduler task、event-loop task、platform callback、runtime cycle 或 runtime global state write。

## 下一轮 Implementation Scope

- 默认新建 owner file：`/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_mutable_commit.cj`。
- 只消费 `CjguiInternalQueueMutableWriteReadiness`。
- 不回塞 `runtime_queue_mutable_write.cj` 的薄尾巴。
- 不触碰 `runtime_state.cj`；它仍为 10065 行 critical warning。
- 允许 function-local `var` 用于 builder / evaluator 内部 value construction。
- instance-local holder field 只有在 internal / owner-local / no public mutable API / no cross-owner escape 时才可考虑；如果使用，必须补中文维护注释。
- 禁止 module-level `var`、global singleton、cross-owner mutable reference、process-wide queue storage write、item collection mutation、public mutable API、public API / C ABI、enqueue、drain、scheduler / event loop / platform callback、runtime cycle、runtime global state write。
- 新增关键 owner / boundary / fail-closed / default draft 注释必须为中文。

## Verification For This Decision

- 本轮 docs-only，不运行 `cjpm build` / smoke guard。
- 必须通过 `git diff --check`。
- README / GUI_TASK_TRACKER / docs/plans README 必须能找到本 decision 与 next opening。
- Markdown 绝对链接 missing target 检查必须通过。
- Forbidden scope 检查必须确认本轮未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- `CANGJIE_ISSUE_LEDGER.md` 未触发更新。

## Next Opening

`P1 internal Queue owner-local mutable write commit boundary bundle implementation`

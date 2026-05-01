# P1 Queue Mutable Write Commit Next Boundary Decision

Date: 2026-05-01

## Current State

`P1 internal Queue owner-local mutable write commit boundary bundle implementation` 已完成。当前 endpoint 是 `CjguiInternalQueueMutableWriteCommitResult`，owner file 是 [runtime_queue_mutable_commit.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_mutable_commit.cj)。

该 endpoint 只消费 `CjguiInternalQueueMutableWriteReadiness`，表达 owner-local mutable write commit / post-write holder / commit result facts。上一轮没有使用 `var`，没有 holder field mutation，没有 module-level `var`、global singleton、public mutable API / C ABI、cross-owner mutable reference、item collection mutation、process-wide storage write、enqueue、drain、scheduler / event loop / runtime cycle。

`runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## Candidates

- A. Milestone / manifest stabilization：风险最低，但当前 README / tracker / plans README 已能找到 commit endpoint 与 stop-line；若无新事实继续选择 stabilization，会让 mutable write runway 停在文档空转。
- B. Mutable write result publication / handoff boundary：选择。新建 downstream handoff owner，只消费 `CjguiInternalQueueMutableWriteCommitResult`，表达 internal result publication / handoff candidate / receipt facts；它让 current endpoint 退出 `runtime_queue_mutable_commit.cj`，符合 Tail Endpoint Exit Gate，且仍不是 public publication、observer callback、public enqueue API、queue drain、scheduler / event loop / runtime cycle。
- C. Process-local write preflight：暂缓。它更靠近真实 storage side effect；先让 commit result 形成 handoff / publication candidate 后，再评估 process-local write preflight 更稳。
- D. Real mutable storage write：拒绝。当前仍缺 process-local write preflight、holder lifecycle write guard、rollback verification 与 global-state escape 检查。
- E. Public enqueue API / C ABI：拒绝。当前太早公开 queue surface，会把 internal value facts 误读成用户可见 side effect。
- F. Drain / scheduler / event loop：拒绝。当前太早靠近 scheduler、event loop 与 runtime cycle。
- G. Tail consolidation：不选择。没有发现明确 dead helper、重复 projection 或 same-owner self-wrapping 需要立即 cleanup；不为 cleanup 而 cleanup。

## Decision

选择 B：

`P1 internal Queue mutable write result handoff boundary bundle implementation`

这是推进，不是放开真实 storage write。下一轮应让 `CjguiInternalQueueMutableWriteCommitResult` 被 downstream owner 消费，而不是继续在 `runtime_queue_mutable_commit.cj` 末尾追加 commit publication record / outcome / thin wrapper。

## Next Implementation Boundary

默认 owner / write set:

- 新建 `runtime/cjgui/src/runtime_queue_mutable_handoff.cj` 或等价 downstream handoff owner file。
- 只消费 `CjguiInternalQueueMutableWriteCommitResult`。
- 不回塞 `runtime_queue_mutable_commit.cj` 的薄尾巴。
- 不触碰 `runtime_state.cj`。

允许表达:

- Internal owner-local mutable write result publication facts。
- Internal handoff candidate facts。
- Internal receipt facts。

Stop-lines:

- 不批准 process-wide queue storage write。
- 不批准 module-level `var`、global mutable queue / singleton、public mutable API / C ABI、cross-owner mutable reference。
- 不批准 public enqueue API、enqueue side effect、queue drain、scheduler、event loop、platform callback 或 runtime cycle。
- 不批准 runtime global state write，不触碰 critical `runtime_state.cj`。

## Verification

- 本轮 docs-only，没有写 runtime code。
- `git diff --check` 通过。
- README / GUI_TASK_TRACKER / docs/plans README 均可找到本 decision 与 next opening。
- Markdown 绝对链接 missing target 检查通过。
- Forbidden scope 检查通过：未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。
- 本轮未运行 `cjpm build` / smoke guard，因为没有修改 runtime code。
- `CANGJIE_ISSUE_LEDGER.md` 未触发更新。

## Next Opening

`P1 internal Queue mutable write result handoff boundary bundle implementation`

# P1 Queue Mutable Handoff Next Process-Local Write Decision

Date: 2026-05-01

## Current State

`P1 internal Queue mutable write result handoff boundary bundle implementation` 已完成。当前 endpoint 是 `CjguiInternalQueueMutableWriteHandoffReceipt`，owner file 是 [runtime_queue_mutable_handoff.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_mutable_handoff.cj)。

该 endpoint 只消费 `CjguiInternalQueueMutableWriteCommitResult`，表达 downstream handoff consumer / acceptance / receipt facts。上一轮没有 `var`、没有 mutable holder fields、没有 process-wide storage write、没有 item collection mutation、没有 enqueue / drain / scheduler / event loop / runtime cycle。

`runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## Candidates

- A. Milestone / manifest stabilization：风险低，但当前 README / tracker / plans README 已能找到 handoff endpoint 与 stop-line；没有 manifest drift 时继续选择 stabilization 会导致文档空转。
- B. Process-local write preflight boundary：选择。只消费 `CjguiInternalQueueMutableWriteHandoffReceipt`，新建 `runtime_queue_process_local_write.cj` 或等价 owner，表达 process-local write preflight / owner-local write scope / lifecycle / rollback availability / verification facts；仍不做真实 item collection mutation、不 enqueue、不 drain、不公开 public API。
- C. Owner-local write realization boundary：暂缓。它可以作为 B 后的下一步，但当前还缺最后一层 process-local preflight facts 来审计允许范围。
- D. Real queue item collection mutation：拒绝。当前缺少 process-local preflight、verification 与 rollback confirmation。
- E. Public enqueue API / C ABI：拒绝。当前太早公开 queue surface，会把 internal value facts 变成用户可见 side effect。
- F. Drain / scheduler / event loop：拒绝。当前太早靠近 scheduler 与 runtime cycle。
- G. Runtime state integration：拒绝。当前会靠近 critical `runtime_state.cj` 与 global runtime state。
- H. Tail consolidation：不选择。没有发现明确 dead helper、重复 projection 或 same-owner self-wrapping；不为 cleanup 而 cleanup。

## Decision

选择 B：

`P1 internal Queue process-local write preflight boundary bundle implementation`

这是打开 owner-local write realization 前的最后一层可审计 preflight，不是真实 mutable write。它的价值是先明确 process-local write scope、lifecycle、rollback availability 与 verification requirements，再决定是否进入 owner-local write realization。

## Next Implementation Boundary

默认 owner / write set:

- 新建 `runtime/cjgui/src/runtime_queue_process_local_write.cj` 或等价 owner。
- 只消费 `CjguiInternalQueueMutableWriteHandoffReceipt`。
- 不回塞 `runtime_queue_mutable_handoff.cj` 的薄尾巴。
- 不触碰 `runtime_state.cj`。

允许表达:

- Process-local write preflight facts。
- Owner-local write scope facts。
- Lifecycle facts。
- Rollback availability facts。
- Verification requirements / write realization candidate facts。

Stop-lines:

- 不做真实 item collection mutation。
- 不写 process-wide queue storage。
- 不创建 global mutable queue / singleton。
- 不公开 public API / C ABI。
- 不 enqueue、不 drain、不接 scheduler / event loop / platform callback、不调用 runtime cycle。
- 不写 runtime global state，不触碰 critical `runtime_state.cj`。

## Verification

- 本轮 docs-only，没有写 runtime code。
- `git diff --check` 通过。
- README / GUI_TASK_TRACKER / docs/plans README 均可找到本 decision 与 next opening。
- Markdown 绝对链接 missing target 检查通过。
- Forbidden scope 检查通过：未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。
- 本轮未运行 `cjpm build` / smoke guard，因为没有修改 runtime code。
- `CANGJIE_ISSUE_LEDGER.md` 未触发更新。

## Next Opening

`P1 internal Queue process-local write preflight boundary bundle implementation`

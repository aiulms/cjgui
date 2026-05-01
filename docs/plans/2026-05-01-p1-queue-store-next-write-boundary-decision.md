# P1 Queue Store Next Write Boundary Decision

## Context

- `P1 internal Queue real storage owner/value-store boundary bundle implementation` 已完成。
- Current queue store runway:
  `CjguiInternalQueueSnapshotPublicationCandidate -> CjguiInternalQueueStoreVersion -> CjguiInternalQueueStoreSnapshot -> CjguiInternalQueueStoreTransition -> CjguiInternalQueueStoreCommitCandidate`.
- `CjguiInternalQueueStoreCommitCandidate` 只是 immutable value-store owner shell 的 commit candidate。
- Open path 只生成 next immutable store snapshot，并把 version marker 从 previous value 推进到 `value + 1`。
- Defer-only / blocked / inconsistent path 保留 previous snapshot。
- 这仍不是真实 queue storage write、global mutable queue、enqueue side effect、drain、scheduler / event loop / platform callback 或 runtime cycle。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## Storage-write Preflight Conclusion

可以继续推进 queue storage-write runway，但下一刀不应直接写 storage，也不应直接生成 committed store value。当前最需要的是第一道 write admission boundary：它只把 `CjguiInternalQueueStoreCommitCandidate` 投影成 can-write / defer / blocked facts，回答 future write boundary 是否可进入。

本结论刻意区分三件事：

- Immutable store commit value: 可以作为未来 value-style commit 的结果，但还不应在没有 admission gate 时直接产生。
- Process-wide mutable queue: 当前不批准；不能创建 global mutable queue / singleton，也不能 in-place mutation。
- Write admission: 当前可批准；它仍是 internal value facts，不写 storage，不 enqueue，不 drain。

## Candidate Comparison

- A. `P1 internal Queue store milestone / manifest stabilization bundle implementation`: 风险最低，但当前 owner / truth / stop-line 已经由 closure 和 manifest 记录清楚；再做 milestone 会延缓 write runway。
- B. `P1 internal Queue store write admission boundary bundle implementation`: 选择。它只消费 `CjguiInternalQueueStoreCommitCandidate`，建立 write admission / can-write / defer / blocked facts，是进入 storage-write 前的自然安全门，且不写 storage。
- C. `P1 internal Queue immutable store commit boundary bundle implementation`: 暂缓。它仍可保持 value-style，但会把 commit candidate 收束成 committed value；在没有 write admission / failure gate 前略早。
- D. `P1 internal Queue store rollback / failure model boundary bundle implementation`: 暂缓。failure / rollback 很重要，但当前还没有 write admission 的 accepted / blocked facts，先做 rollback 容易缺少触发上下文。
- E. `P1 internal Queue real mutable storage preflight`: 暂缓。immutable store shell 刚落地，尚未建立 write admission / rollback / ownership guard，不应靠近 mutable in-memory queue。
- F. `P1 internal Queue drain / scheduler preflight decision`: 暂缓。drain / scheduler 依赖真实 storage 与 enqueue 语义，当前太早。
- G. `P1 internal Queue store tail consolidation bundle implementation`: 不选择。当前未发现明确重复 helper / dead symbols；为了 cleanup 而 cleanup 会偏离 write runway。

## Decision

选择 B：

`P1 internal Queue store write admission boundary bundle implementation`

## Next Implementation Scope

- 默认 owner/write set：优先新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_store_write.cj`，同步 runtime README、root README、GUI tracker、plans README 和 closure review。
- 只允许消费 `CjguiInternalQueueStoreCommitCandidate`。
- 输出只能是 internal value-style write admission / write gate / write readiness facts。
- 可以一次完成 W2/W3 same-owner bundle，而不是 one-symbol 微切片。
- Suggested concepts: `CjguiInternalQueueStoreWriteAdmission`、`CjguiInternalQueueStoreWriteGate`、`CjguiInternalQueueStoreWriteReadiness` 或等价 endpoint。
- Open path: store commit candidate ready 且 no defer/block -> can-write facts true。
- Defer-only path: 保持 defer，不伪造 write readiness。
- Blocked / inconsistent path: fail-closed blocked。

## Stop-lines

- 不得写真实 queue storage。
- 不得创建 process-wide mutable queue / singleton。
- 不得 enqueue / drain。
- 不得执行 action。
- 不得接 AI provider / prompt / external agent / model session。
- 不得新增 public API / C ABI。
- 不得接 event loop / scheduler / platform callback。
- 不得调用 runtime cycle。
- 不得写 runtime global state。
- 不得触碰 critical `runtime_state.cj`。
- 不得绕过 `CjguiInternalQueueStoreCommitCandidate` 读取 lower-level facts。
- 不得新增 Request+Report 双层、五件套 sanity 或 thin outcome/report wrapper。

## Verification Plan

- 下一轮 implementation 需要 GitNexus impact / detect_changes。
- `runtime_state.cj` file-size / hash guard 必须记录。
- `cjpm build --target-dir /tmp/cjgui-queue-store-write-admission-boundary-target --skip-script`。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`。
- `git diff --check`。
- Markdown absolute-link missing target check。
- Forbidden-file guard。

## Current Next Opening

`P1 internal Queue store write admission boundary bundle implementation`

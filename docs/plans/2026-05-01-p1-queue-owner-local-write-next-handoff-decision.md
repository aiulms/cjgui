# P1 Queue Owner-Local Write Next Handoff Decision

日期：2026-05-01

## 当前事实

- `P1 internal Queue owner-local write realization boundary bundle implementation` 已完成。
- 当前 owner file: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_owner_local_write.cj`
- 当前 endpoint: `CjguiInternalQueueOwnerLocalWriteResult`
- 当前 runway: `CjguiInternalQueueProcessLocalWritePreflight -> CjguiInternalQueueOwnerLocalWriteRealization -> CjguiInternalQueueOwnerLocalPostWriteHolder -> CjguiInternalQueueOwnerLocalWriteResult`
- `CjguiInternalQueueOwnerLocalWriteResult` 只消费 `CjguiInternalQueueProcessLocalWritePreflight`，表达 owner-local realization / post-realization holder / write result facts。
- 上轮未使用 `var`，未使用 mutable holder fields，未新增 module-level `var`、global singleton、public API / C ABI 或 cross-owner mutable reference。
- 当前仍未做 item collection mutation、process-wide storage write、enqueue、drain、scheduler、event loop 或 runtime cycle。
- `runtime_state.cj` 仍为 `10065` 行 critical warning，本轮和下一轮默认不得触碰。
- 已存在的 future radar 文档 `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-ai-native-architecture-radar-future-plan.md` 不改变当前 Queue runway，本轮不扩展该文档。

## 候选比较

### A. milestone / manifest stabilization

优点是风险最低，可以把 `CjguiInternalQueueOwnerLocalWriteResult` 固定为当前 realization endpoint。

不选择原因：本轮 manifest / README / tracker 只需要常规同步，没有发现足以阻断下一步的 drift。若此时只做 stabilization，会让 mutable write runway 停在文档空转，且没有新增 downstream consumer truth。

### B. owner-local write result handoff boundary

优点是符合 Tail Endpoint Exit Gate：`CjguiInternalQueueOwnerLocalWriteResult` 已经是 `runtime_queue_owner_local_write.cj` 的 canonical endpoint，下一步不应继续在同 owner 末尾自我包装，而应交给 downstream handoff owner 消费。

该候选默认新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_owner_local_handoff.cj` 或等价 owner file，只消费 `CjguiInternalQueueOwnerLocalWriteResult`，表达 owner-local write result handoff consumer / acceptance / receipt facts。它仍不是 public publication、observer callback、public enqueue API、process-wide storage write、drain、scheduler / event loop 或 runtime cycle。

### C. public enqueue API / C ABI

当前拒绝。项目还缺 public surface policy、input API shape、compatibility strategy、real queue lifecycle 与 public observable semantics。直接公开会绕过当前 internal-only runway。

### D. drain / scheduler / event loop

当前拒绝。Queue 仍停在 owner-local realization / handoff 事实层，尚未批准 drain plan、scheduler task、event loop task 或 runtime cycle 入口；现在打开会过早靠近 runtime cycle。

### E. runtime state integration

当前拒绝。该方向会靠近 critical `runtime_state.cj` 与 runtime global state write；在 file-size / owner split check 和 downstream handoff facts 出现前，不应打开。

### F. rollback / failure strengthening

暂缓。当前已有 rollback availability、fallback snapshot、blocked / inconsistent fail-closed facts；进一步 strengthening 更适合在 handoff receipt 或 public boundary 前再评估，因为 handoff receipt 会让 failure / rollback 的下游消费点更清楚。

### G. tail consolidation

不选择。当前没有发现明确 dead helper、重复 projection 或同 owner self-wrapping debt。为了 cleanup 而 cleanup 会打断 owner-local result 向 downstream consumer 退出的主线。

## Decision

选择 B：

`P1 internal Queue owner-local write result handoff boundary bundle implementation`

理由：

- `CjguiInternalQueueOwnerLocalWriteResult` 已经是 owner-local realization 的 canonical endpoint。
- Tail Endpoint Exit Gate 要求下一步优先换挡到 downstream consumer，而不是继续给 `runtime_queue_owner_local_write.cj` 追加 receipt / record / outcome thin wrapper。
- handoff boundary 能把 result 交给新的 owner，同时仍保持 internal value-style facts，不触发 public enqueue、process-wide storage write、drain、scheduler / event loop 或 runtime cycle。
- rollback / failure strengthening 当前已有基础 facts，等 handoff receipt shape 出现后再评估更有目标。

## 下一轮 owner / write set

推荐下一轮：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_owner_local_handoff.cj` 或等价 downstream handoff owner file。
- 只消费 `CjguiInternalQueueOwnerLocalWriteResult`。
- 新增 owner-local write result handoff consumer / acceptance / receipt value facts。
- 不回塞 `runtime_queue_owner_local_write.cj` 的薄尾巴。
- 不触碰 `runtime_state.cj`。

## Stop-Line

下一轮仍禁止：

- process-wide queue storage write
- global mutable queue / singleton
- public enqueue API / public C ABI
- item collection mutation that escapes owner-local value facts
- observer callback / public publication
- drain
- scheduler / event loop / platform callback
- runtime cycle
- runtime global state write
- touching critical `runtime_state.cj`

## 验证

本轮是 docs-only decision，不运行 `cjpm build` 或 smoke guard。

验证要求：

- `git diff --check`
- README / GUI_TASK_TRACKER / docs/plans README 均能找到本 decision 与 next opening。
- Markdown 绝对链接 missing target 检查通过。
- forbidden 文件检查确认未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。

## Next Opening

`P1 internal Queue owner-local write result handoff boundary bundle implementation`

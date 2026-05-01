# P1 Queue Owner-Local Handoff Next Public-Boundary Decision

日期：2026-05-01

## 当前事实

- `P1 internal Queue owner-local write result handoff boundary bundle implementation` 已完成。
- 当前 owner file: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_owner_local_handoff.cj`
- 当前 endpoint: `CjguiInternalQueueOwnerLocalWriteHandoffReceipt`
- 当前 runway: `CjguiInternalQueueOwnerLocalWriteResult -> CjguiInternalQueueOwnerLocalWriteHandoffConsumer -> CjguiInternalQueueOwnerLocalWriteHandoffAcceptance -> CjguiInternalQueueOwnerLocalWriteHandoffReceipt`
- `CjguiInternalQueueOwnerLocalWriteHandoffReceipt` 只消费 `CjguiInternalQueueOwnerLocalWriteResult`，表达 downstream handoff consumer / acceptance / receipt facts。
- 上轮未使用 `var`，未使用 mutable holder fields，未新增 module-level `var`、global singleton、public API / C ABI 或 cross-owner mutable reference。
- 当前仍未做 item collection mutation、process-wide storage write、enqueue、drain、scheduler、event loop 或 runtime cycle。
- `runtime_state.cj` 仍为 `10065` 行 critical warning，本轮和下一轮默认不得触碰。

## 候选比较

### A. milestone / manifest stabilization

优点是风险最低，可以把 `CjguiInternalQueueOwnerLocalWriteHandoffReceipt` 固定为当前 internal handoff endpoint。

不选择原因：本轮 README / tracker / plans README 没有发现阻断下一步的 manifest drift。若此时只做 milestone，会让 owner-local write runway 停在文档空转，无法回答 public surface 前的关键问题。

### B. public queue boundary preflight

优点是能在进入任何 public queue API 或 public enqueue wording 之前，先把 public surface 风险讲清楚。它仍是 docs-only preflight，不直接实现 public API / C ABI，不批准 real enqueue、queue drain、scheduler / event loop 或 runtime cycle。

该候选需要评估 public queue surface / enqueue terminology / API shape / compatibility / failure / audit / permission / rollback / verification，并明确 public-facing truth owner 与 internal owner-local write runway 的关系。

### C. internal public-admission value boundary

暂缓。它可能把 internal facts 过早投影成 public-admission value stage，而 public queue owner、API shape、compatibility promise 和 error model 尚未冻结。先做 public boundary preflight，可以避免把 `CjguiInternalQueueOwnerLocalWriteHandoffReceipt` 误升格为 public API facts。

### D. direct public enqueue API / C ABI

当前拒绝。项目还缺 public boundary preflight、API compatibility、user-facing error model、permission / rollback / audit 投影和 verification strategy。直接公开 enqueue API 会绕过当前 Action Router / Queue gates 的 internal runway。

### E. drain / scheduler / event loop

当前拒绝。Queue 仍未批准 public surface，更未批准 drain plan、scheduler task、event loop task 或 runtime cycle 入口；现在打开会过早靠近 runtime cycle。

### F. runtime state integration

当前拒绝。该方向会靠近 critical `runtime_state.cj` 与 runtime global state write；在 file-size / owner split check、public boundary preflight 和 storage ownership 进一步明确前，不应打开。

### G. rollback / failure strengthening

暂缓为独立 implementation。当前已有 rollback availability、fallback snapshot、blocked / inconsistent fail-closed facts。public surface 前确实需要评估 rollback / failure 是否足够，但它更适合被纳入 public boundary preflight 的问题清单；若 preflight 发现 public-facing failure model 不足，再单独打开 strengthening。

### H. tail consolidation

不选择。当前没有发现明确 dead helper、重复 projection 或 same-owner self-wrapping debt。为了 cleanup 而 cleanup 会打断从 internal handoff receipt 进入 public-boundary preflight 的主线。

## Decision

选择 B：

`P1 internal Queue public boundary preflight decision`

理由：

- `CjguiInternalQueueOwnerLocalWriteHandoffReceipt` 已经把 owner-local write result 交给 downstream internal handoff owner，Tail Endpoint Exit Gate 已满足。
- 下一步不应继续同 owner tail wrapping，也不应直接打开 public enqueue API。
- public boundary preflight 能在任何 public API / C ABI 或 enqueue side effect 之前，先冻结 owner、truth、API shape、compatibility、permission、rollback、audit 和 verification 问题。
- rollback / failure strengthening 当前已有基础 facts；是否需要专门 strengthening 应由 public boundary preflight 判断。

## Public Boundary Preflight 必答问题

- 哪个 owner 拥有 public queue truth？
- public enqueue 与 internal owner-local write / handoff runway 的关系是什么？
- public-facing 错误如何返回，哪些错误仍保持 internal-only？
- permission / admission / rollback / audit 如何从 internal facts 投影，哪些不得公开？
- 是否需要 stable API shape / compatibility promise，承诺粒度是什么？
- 如何避免 public enqueue 绕过 Action Router / Queue gates？
- 验证方式是什么：docs-only review、internal value sanity、build / smoke、forbidden scan、public surface scan 分别何时需要？
- 是否必须先完成 file-size / owner split check，才能触碰 `runtime_state.cj` 或任何 runtime global state？

## 下一轮 owner / write set

推荐下一轮：

- 新增 docs-only preflight / decision 文档，命名可为 `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-queue-public-boundary-preflight-decision.md` 或等价文件。
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/README.md`、`/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`、`/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`。
- 不修改 runtime code，不触碰 `runtime_state.cj`。

## Stop-Line

下一轮仍禁止：

- public API implementation
- public C ABI implementation
- real enqueue
- process-wide queue storage write
- item collection mutation
- global mutable queue / singleton
- observer callback / public publication implementation
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

`P1 internal Queue public boundary preflight decision`

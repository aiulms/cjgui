# P1 Queue Public Boundary Next Surface Decision

日期：2026-05-01

## 当前事实

- `P1 internal Queue public boundary admission value bundle implementation` 已完成，owner file 为 [runtime_queue_public_boundary.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_boundary.cj)。
- 当前 endpoint 是 `CjguiInternalQueuePublicBoundaryReadiness`。
- 它只消费 `CjguiInternalQueueOwnerLocalWriteHandoffReceipt`，表达 internal-only public-boundary intent / submission / admission / readiness value facts。
- 当前 public-boundary 不是 public API implementation、不是 public C ABI、不是 real enqueue。
- 仍未写 process-wide queue storage，未创建 global mutable queue，未做 item collection mutation，未 drain，未接 scheduler / event loop / runtime cycle。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## 候选比较

- A. milestone / manifest stabilization：风险最低，可以短暂停账，但当前 README / tracker / manifest 没有阻塞性 drift；若只做 stabilization，会让 public-boundary readiness 停在文档空转。
- B. public surface policy / compatibility value boundary：选择。它把 `CjguiInternalQueuePublicBoundaryReadiness` 交给新的 public surface owner，先表达 public surface policy / compatibility facts / error contract / audit requirement / api readiness candidate，仍不实现 public API / C ABI。
- C. public error taxonomy bundle：暂缓。public-facing error 可以先纳入 B 的 error contract facts，不需要单独开薄 taxonomy owner。
- D. direct public API implementation：拒绝。当前缺少 public surface policy、compatibility promise、error contract、versioning 和 verification strategy。
- E. public C ABI boundary：拒绝。C ABI 需要更稳定的 runtime handle、lifecycle 与 error ABI，当前风险高于 public policy facts。
- F. real enqueue：拒绝。`CjguiInternalQueuePublicBoundaryReadiness` 不是 enqueue permission，也不是 queue storage write admission。
- G. drain / scheduler / event loop：拒绝。当前仍未进入 queue drain、scheduler 或 runtime cycle owner，过早靠近 runtime loop。
- H. runtime state integration：拒绝。它会靠近 critical `runtime_state.cj` 与 runtime global state write。
- I. tail consolidation：不选。未发现明确 dead helper、重复 projection 或 same-owner self-wrapping；不为 cleanup 而 cleanup。

## Decision

选择 B：

> `P1 internal Queue public surface policy boundary bundle implementation`

下一轮默认新建 `runtime/cjgui/src/runtime_queue_public_surface.cj` 或等价 owner file，只消费 `CjguiInternalQueuePublicBoundaryReadiness`。

下一轮 terminology 应优先使用：

- `public surface policy`
- `compatibility facts`
- `error contract`
- `audit requirement`
- `api readiness candidate`

## Boundary

- 当前没有 stable public API compatibility promise。
- 下一轮即使实现，也只是 internal value facts，不是 public API implementation。
- public-facing errors 先作为 error contract facts 表达，不作为真实 runtime error surface。
- audit / permission / rollback 必须关联现有 Action Router / Queue gates，不能绕过 internal pipeline。
- 不开放 public API / C ABI。
- 不 real enqueue，不写 process-wide queue storage，不创建 global mutable queue，不做 item collection mutation。
- 不 drain，不接 scheduler / event loop / platform callback / runtime cycle。
- 不触碰 `runtime_state.cj`。

## Verification Plan

- `git diff --check`
- README / GUI_TASK_TRACKER / docs/plans README 均能找到本 decision 与 next opening。
- Markdown 绝对链接 missing target 检查。
- forbidden 检查：本轮不得修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。
- 本轮 docs-only，不运行 `cjpm build` / smoke guard，除非意外修改 runtime code。

## Next Opening

`P1 internal Queue public surface policy boundary bundle implementation`

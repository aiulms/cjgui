# P1 Queue Process-Local Write Next Realization Decision

日期：2026-05-01

## 当前事实

- `P1 internal Queue process-local write preflight boundary bundle implementation` 已完成。
- 当前 owner file: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_process_local_write.cj`
- 当前 endpoint: `CjguiInternalQueueProcessLocalWritePreflight`
- 该 endpoint 只消费 `CjguiInternalQueueMutableWriteHandoffReceipt`，表达 process-local write scope / lifecycle / rollback availability / preflight ready facts。
- 上轮未使用 `var`，未使用 mutable holder fields，未新增 module-level `var`、global singleton、public mutable API / C ABI 或 cross-owner mutable reference。
- 当前仍未做 item collection mutation，未写 process-wide queue storage，未 enqueue，未 drain，未接 scheduler / event loop / runtime cycle。
- `runtime_state.cj` 仍为 `10065` 行 critical warning，本轮不得触碰。

## 候选比较

- A. `milestone / manifest stabilization`
  - 优点是风险最低，可继续固定 manifest truth。
  - 不选择：当前 README / tracker / plans README / manifest 已能找到 process-local preflight endpoint，没有明显 manifest drift；继续 stabilization 会让 mutable write runway 停在文档空转。

- B. `P1 internal Queue owner-local write realization boundary bundle implementation`
  - 只消费 `CjguiInternalQueueProcessLocalWritePreflight`。
  - 默认新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_owner_local_write.cj` 或等价 owner file。
  - 表达 owner-local write realization / realization result / post-realization holder facts。
  - 可以允许 function-local `var`，但仅用于 owner-local realization facts 选择；禁止 module-level `var`、global singleton、public mutable API、cross-owner mutable reference、process-wide storage write、runtime global state write。
  - 选择：preflight 已提供 scope / lifecycle / rollback availability / realization candidate，足以作为 realization 的入口 gate。下一刀推进能力而不是继续自包。

- C. `realization admission / final gate`
  - 优点是更保守。
  - 不选择：`CjguiInternalQueueProcessLocalWritePreflight` 已是入口 gate，再加 admission / final gate 容易变成 preflight 后薄 wrapper。若下一轮 implementation 发现 realization facts 还缺 guard，可在 realization owner 内合并表达，而不是先独立追加薄层。

- D. `public enqueue API / C ABI`
  - 拒绝：当前仍缺 owner-local realization result、post-realization holder 和验证闭环；过早公开会把 internal value facts 升格为用户可见 side effect。

- E. `drain / scheduler / event loop`
  - 拒绝：当前尚未形成 owner-local realization result，更不应靠近 scheduler、event loop 或 runtime cycle。

- F. `runtime state integration`
  - 拒绝：会靠近 critical `runtime_state.cj` 与 runtime global state write；当前必须继续保持新 owner / owner-local 边界。

- G. `rollback / failure strengthening`
  - 暂缓：已有 rollback availability facts，且上游已有 `runtime_queue_store_rollback.cj` 的 rollback model。更合适的时机是在 owner-local realization result shape 出现后，再根据实际 result / holder facts 补 rollback strengthening。

- H. `tail consolidation`
  - 不选择：未发现明确 dead helper、重复 projection 或 same-owner self-wrapping。为了 cleanup 而 cleanup 会降低主线推进速度。

## Decision

选择 B：

`P1 internal Queue owner-local write realization boundary bundle implementation`

## 下一轮边界

- 默认新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_owner_local_write.cj`。
- 只消费 `CjguiInternalQueueProcessLocalWritePreflight`。
- 输出 owner-local write realization / realization result / post-realization holder facts。
- 允许 function-local `var`，但仅用于 owner-local realization facts 选择。
- instance-local holder fields 只有在 internal / owner-local / no public mutable API / no cross-owner escape 时才可考虑；默认优先不用。
- 禁止 module-level `var`、global singleton、public mutable API / C ABI、cross-owner mutable reference、process-wide storage write、runtime global state write。
- 禁止 public enqueue、drain、scheduler / event loop / platform callback、runtime cycle。
- 禁止触碰 `runtime_state.cj`，除非先做 file-size / owner split check 并获得明确新 decision。

## 验证

- 本轮 docs-only，未运行 `cjpm build` / smoke guard。
- `git diff --check` 通过。
- README / GUI_TASK_TRACKER / docs/plans README 均可找到本 decision 与 next opening。
- Markdown 绝对链接 missing target 检查通过。
- forbidden scope 检查通过：未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。

未发现新的仓颉语言 / SDK / FFI / 工具链 / 文档问题，`CANGJIE_ISSUE_LEDGER.md` 未触发更新。

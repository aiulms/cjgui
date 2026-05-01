# P1 Queue Public API Next Result-Boundary Decision

日期：2026-05-01

## 当前事实

- `P1 internal Queue public API admission value boundary bundle implementation` 已完成。
- 新 owner file 已建立：`/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_api.cj`。
- 当前 endpoint 是 `CjguiInternalQueuePublicApiResult`。
- `CjguiInternalQueuePublicApiResult` 只消费 `CjguiInternalQueuePublicApiReadinessCandidate`，表达 internal-only public API submission request / admission / accepted-deferred-blocked-rejected result facts。
- 当前仍不是 public API implementation，不是 public C ABI，不是 real enqueue。
- 当前不接受 raw pointer / native handle。
- 当前仍未写 process-wide queue storage，未创建 global mutable queue，未做 item collection mutation，未 drain，未接 scheduler / event loop / runtime cycle。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## 候选比较

### A. Milestone / Manifest Stabilization

风险最低，适合发现 README / manifest 明显 drift 时使用。但当前 public API admission value boundary 已有 closure、tracker 与 manifest 同步，继续只做 stabilization 会让 runway 停在文档空转，不推进 public-facing result shape 的必要约束。

结论：不选。

### B. Public Result / Response Shape Boundary

新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_result.cj` 或等价 owner，只消费 `CjguiInternalQueuePublicApiResult`，表达 public-facing response shape / result envelope / error projection / audit reference / compatibility note value facts。

这一步仍不是 public API implementation，也不是 C ABI。它的价值是先把未来 public-facing 返回形态固定下来，避免后续 public API 直接暴露 internal owner facts。错误投影必须来自 `CjguiInternalQueuePublicApiResult` / public error contract，不得绕过到 lower-level mutable queue facts；audit reference 只是 value fact，不是 public audit log writer。

结论：选择。

### C. Public API Implementation Preflight

可以讨论 public API shape / compatibility / tests，但当前还缺 public response shape、error projection、audit reference 与 compatibility note 的 value boundary。若直接 preflight public implementation，容易在没有 result envelope 的情况下把 internal facts 当成 API contract。

结论：暂缓，等 public result shape boundary 后再评估。

### D. Direct Public Runtime API Implementation

当前缺少 public response shape、API tests、compatibility / version policy，且当前没有 stable public API compatibility promise。直接实现 public runtime API 会过早对外承诺。

结论：拒绝。

### E. Public C ABI Boundary

C ABI 需要更稳定的 handle / lifecycle / error ABI。当前仍不接受 raw pointer / native handle，也没有 public API result envelope 或 stable compatibility promise。

结论：拒绝。

### F. Real Enqueue

`CjguiInternalQueuePublicApiResult` 只是 admission / result value facts，不是 enqueue permission，也不是 queue write authorization。

结论：拒绝。

### G. Drain / Scheduler / Event Loop

当前仍未形成 public response shape，也未进入真实 enqueue；靠近 drain / scheduler / event loop 会跳过 queue stop-line 并靠近 runtime cycle。

结论：拒绝。

### H. Runtime State Integration

会靠近 critical `runtime_state.cj` 和 runtime global state write。当前 public API admission result 仍是 internal-only value facts，不应接 runtime state。

结论：拒绝。

### I. Tail Consolidation

只有发现明确 dead helper、重复 projection 或 same-owner self-wrapping 时才应选择。当前没有明确可压缩对象，且下一步应退出 admission owner，转入 result shape owner。

结论：不选。

## Decision

选择 B：

`P1 internal Queue public result shape boundary bundle implementation`

下一轮建议：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_result.cj`。
- 只消费 `CjguiInternalQueuePublicApiResult`。
- 使用 terminology：`public response shape` / `result envelope` / `error projection` / `audit reference` / `compatibility note`。
- 继续 internal-only，不开放 public API / C ABI。
- 不 real enqueue，不 drain，不接 scheduler / event loop / runtime cycle。
- 不触碰 `runtime_state.cj`。

## Stop-line

- 当前没有 stable public API compatibility promise。
- 下一轮即使实现，也只是 internal value facts，不是 public API。
- Public-facing response 不得直接暴露 internal owner facts。
- Error projection 必须来自 `CjguiInternalQueuePublicApiResult` / public error contract，而不是 lower-level mutable queue facts。
- Audit reference 只是 value fact，不是 public audit log writer。
- 不得批准 public runtime API implementation、public C ABI、real enqueue、queue drain、scheduler / event loop、runtime cycle、process-wide queue storage write、runtime global state write或 critical `runtime_state.cj` 修改。

## Verification

- `git diff --check`。
- README / GUI_TASK_TRACKER / docs/plans README 均能找到本 decision 与 next opening。
- Markdown 绝对链接 missing target 检查。
- forbidden 检查：本轮不得修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。
- 本轮 docs-only，不运行 `cjpm build` / smoke guard，除非意外修改 runtime code。

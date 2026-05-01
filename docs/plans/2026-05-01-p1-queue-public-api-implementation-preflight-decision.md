# P1 Queue public API implementation preflight decision

日期：2026-05-01

## Context

上一轮已完成 `P1 internal Queue public result shape boundary bundle implementation`。

当前 internal endpoint：

`CjguiInternalQueuePublicApiResult -> CjguiInternalQueuePublicResponseShape -> CjguiInternalQueuePublicResultEnvelope -> CjguiInternalQueuePublicErrorProjection -> CjguiInternalQueuePublicAuditReference -> CjguiInternalQueuePublicCompatibilityNote`

当前 canonical endpoint 是 `CjguiInternalQueuePublicCompatibilityNote`。它只表示 internal-only public response shape / result envelope / error projection / audit reference / compatibility note facts，并明确当前没有 stable public API compatibility promise。

当前仍不是 public runtime API，不是 public C ABI，不是 real enqueue；仍未写 process-wide queue storage，未创建 global mutable queue，未做 item collection mutation，未 drain，未接 scheduler / event loop / runtime cycle。`runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## Preflight Answers

### 1. 第一刀是否能叫 public API？

可以使用 `public API` 作为 runway 名称的一部分，但下一刀必须限定为 internal package 内的 `public API shell / API entry value facts`。它不是 stable external public API，不承诺兼容性，不提供真实 runtime API function，也不形成用户可见 side effect。

为了降低误读，下一轮 implementation 的 symbol 命名优先使用：

- `ApiShell`
- `SubmissionEntry`
- `EntryAdmission`
- `EntryResult`

不得使用 `enqueue` 作为 public API 行为承诺。

### 2. 是否允许 `public` 修饰符？

当前不允许。下一轮应继续使用 internal-only symbols，不新增 `public` 修饰符。

原因：

- `CjguiInternalQueuePublicCompatibilityNote` 已明确当前没有 stable public API compatibility promise。
- 公开符号容易被误读为可依赖 API surface。
- 当前还没有 user-facing docs、versioning policy、API compatibility tests、C ABI handle / lifecycle / error ABI。

如果未来确实需要 public symbol，必须先有单独 decision 说明为什么它不会形成稳定 compatibility promise，以及如何限制实验性可见性、文档措辞、版本策略和验证范围。

### 3. 输入 shape

下一轮只允许消费 `CjguiInternalQueuePublicCompatibilityNote`。

API entry shell 的输入只能是 dehydrated submission value / entry intent / already-shaped public result facts 的内部表示。不得接受：

- raw pointer
- native handle
- platform object
- AppKit / Metal / Objective-C object
- process-wide queue store reference
- lower-level mutable queue owner facts

### 4. 输出 shape

输出只能是 public API shell / submission entry / entry admission / entry result value facts。

输出可以携带：

- public result envelope handoff facts
- error projection summary
- audit reference value
- no-stable-compatibility note

输出不得直接暴露 lower-level owner facts，尤其不得暴露 mutable queue holder、store snapshot internals、rollback implementation detail、runtime global state 或 platform handle。

### 5. 是否允许 real enqueue？

不允许。`CjguiInternalQueuePublicCompatibilityNote` 不是 enqueue permission。下一轮只可表达 API entry shell value facts，不得 enqueue、不写 queue storage、不做 item collection mutation。

### 6. 是否允许 C ABI？

不允许。C ABI 需要更稳定的 runtime handle、lifecycle、ownership、threading、error ABI 和 compatibility policy。当前缺口仍未补齐。

### 7. 是否允许 scheduler / drain / event loop？

不允许。public result shape 只到 response / compatibility note；它不能绕过 queue gates 进入 drain、scheduler、event loop、platform callback 或 runtime cycle。

### 8. 验证策略

下一轮若进入 bounded implementation，应至少验证：

- `cjpm build --target-dir <tmp-target> --skip-script`
- smoke guard
- `git diff --check`
- Markdown 绝对链接 missing target 检查
- closure 链接可从 `GUI_TASK_TRACKER.md` 与 `docs/plans/README.md` 找到
- forbidden 检查：不修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`
- extra API-shell 检查：无 `public` 修饰符、无 C ABI、无 raw pointer / native handle、无 enqueue / drain / scheduler / event loop / runtime cycle、无 process-wide storage write、无 global singleton、无 module-level `var`
- GitNexus impact / detect_changes；新 owner symbols 若尚未索引，可记录 UNKNOWN / not found fallback evidence

## Candidate Comparison

### A. Milestone / manifest stabilization

优点：风险最低，可以进一步固定 `CjguiInternalQueuePublicCompatibilityNote` 是当前 endpoint。

风险：当前 manifest 与 README 已跟上 result shape closure；如果继续只 stabilization，会让 public API runway 进入文档空转。

Decision：不选择。

### B. Internal public API shell / entry value boundary

优点：自然消费 `CjguiInternalQueuePublicCompatibilityNote`，把 public result shape 推进到 API entry shell / submission entry / entry result value facts；同时保留 internal-only、no-stable-compatibility、no real enqueue、no C ABI stop-line。

风险：名称包含 `public API`，容易被误解为公开稳定 API。因此下一轮必须使用 `ApiShell` / `SubmissionEntry` / `EntryResult` 等命名，且不得使用 `public` 修饰符。

Decision：选择。

### C. Direct stable public API implementation

风险：缺少 stable compatibility promise、versioning、user docs、API tests、error return model 和 public lifecycle strategy。

Decision：拒绝。

### D. Public C ABI boundary

风险：C ABI 需要稳定 runtime handle、lifecycle、ownership、threading、error ABI 和 compatibility policy；当前公共 API shell 尚未建立。

Decision：拒绝。

### E. Real enqueue implementation

风险：`CjguiInternalQueuePublicCompatibilityNote` 不是 enqueue permission。直接 enqueue 会绕过 storage write / queue gates / public API shell / error contract。

Decision：拒绝。

### F. Drain / scheduler / event loop

风险：过早靠近 runtime cycle，且当前没有 public queue drain lifecycle 或 scheduler ownership。

Decision：拒绝。

### G. Runtime state integration

风险：会靠近 critical `runtime_state.cj` / runtime global state write。当前 `runtime_state.cj` 仍为 10065 行 critical warning。

Decision：拒绝。

### H. Tail consolidation

当前未发现明确 dead helper、重复 projection 或 same-owner self-wrapping。`runtime_queue_public_result.cj` 是下游 owner，不是同 owner tail 自包。

Decision：不选择。

## Decision

选择 B：

`P1 internal Queue public API shell / entry value boundary bundle implementation`

下一轮建议：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_api_shell.cj`。
- 只消费 `CjguiInternalQueuePublicCompatibilityNote`。
- 命名优先使用 `ApiShell` / `SubmissionEntry` / `EntryAdmission` / `EntryResult`，不要命名成 `enqueue`。
- 继续 internal-only，不新增 `public` 修饰符，不承诺 stable public API compatibility。
- 不实现 public runtime API function。
- 不实现 public C ABI。
- 不 real enqueue。
- 不写 process-wide queue storage。
- 不创建 global mutable queue / singleton。
- 不接 drain / scheduler / event loop / platform callback / runtime cycle。
- 不触碰 `runtime_state.cj`。

## Verification

本轮 docs-only：

- 不写 runtime code。
- 不运行 `cjpm build` / smoke guard。
- 需运行 `git diff --check`。
- README / GUI_TASK_TRACKER / docs/plans README 需能找到本 preflight 与 next opening。
- Markdown 绝对链接 missing target 检查需通过。
- Forbidden 检查需确认未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。

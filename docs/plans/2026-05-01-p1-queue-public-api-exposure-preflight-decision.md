# P1 Queue public API exposure preflight decision

日期：2026-05-01

## Context

上一轮已完成 `P1 internal Queue public API shell / entry value boundary bundle implementation`。

当前 internal endpoint：

`CjguiInternalQueuePublicCompatibilityNote -> CjguiInternalQueuePublicApiShell -> CjguiInternalQueuePublicSubmissionEntry -> CjguiInternalQueuePublicEntryResult -> CjguiInternalQueuePublicEntryResultHandoff`

当前 canonical endpoint 是 `CjguiInternalQueuePublicEntryResultHandoff`。它只表示 internal-only API shell / submission entry / entry result / handoff value facts；新 owner file `runtime_queue_public_api_shell.cj` 没有 `public` 修饰符，没有 `enqueue` 命名，也不接受 raw pointer / native handle / platform object。

当前仍不是 public runtime API，不是 public C ABI，不是 real enqueue；仍没有 stable public API compatibility promise；仍未写 process-wide queue storage，未创建 global mutable queue，未做 item collection mutation，未 drain，未接 scheduler / event loop / runtime cycle。`runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## Preflight Answers

### 1. 是否允许下一轮新增 `public` 修饰符？

不允许。`CjguiInternalQueuePublicEntryResultHandoff` 只能证明 internal API shell facts 已经可被下游 owner 消费，不能证明 public symbol visibility、compatibility promise、user docs、versioning 或 API tests 已经足够。

下一轮若继续推进，应表达 `public exposure gate` / `symbol readiness` value facts，而不是直接引入 `public` 修饰符。

### 2. 是否允许使用 `enqueue` 命名？

不允许。`enqueue` 会暗示真实队列写入或 side effect；当前仍没有 real enqueue permission、queue drain lifecycle 或 scheduler handoff。

下一轮命名优先使用：

- `ExposureGate`
- `SymbolReadiness`
- `SubmissionNamingPolicy`
- `NoStableCompatibility`

如果未来需要 public-facing terminology，也应先使用 `submit` / `submission` / `queueSubmission`，避免承诺真实 enqueue。

### 3. 是否允许 public C ABI？

不允许。C ABI 需要稳定 handle、lifecycle、threading、ownership、error ABI、versioning 与 compatibility policy。当前 API shell 只是 internal value facts，不具备 C ABI 前置条件。

### 4. 是否允许 real enqueue side effect？

不允许。`CjguiInternalQueuePublicEntryResultHandoff` 不是 enqueue permission。下一轮不得写 queue storage、不得创建 queue item collection mutation、不得产生 process-wide mutable queue write。

### 5. 如果不开 public API，下一步还可以推进什么？

下一步可以推进 internal-only public exposure gate / symbol readiness boundary。它只消费 `CjguiInternalQueuePublicEntryResultHandoff`，把 API shell handoff 收束为：

- public exposure gate facts
- symbol readiness facts
- naming policy facts
- no-stable-compatibility facts

这些 facts 可以为未来 public API exposure 做审计准备，但不会开放 public API。

### 6. 输入输出是否稳定？

输入仍只能是 dehydrated submission / entry / handoff value facts，不接受 raw pointer、native handle、platform object、callback、runtime state reference 或 lower-level mutable queue facts。

输出仍只能是 result envelope / error projection / audit reference / compatibility note 的 value projection，不得直接暴露 lower-level owner facts，也不得返回 public queue handle、native handle、scheduler task 或 real enqueue record。

### 7. 兼容性承诺如何表达？

当前没有 stable public API promise。下一轮若进入 exposure gate，必须继续显式记录 no-stable-compatibility facts，说明 symbol readiness 不是 compatibility commitment。

### 8. 验证策略

下一轮若进入 bounded implementation，应至少验证：

- `cjpm build --target-dir <tmp-target> --skip-script`
- smoke guard
- `git diff --check`
- Markdown 绝对链接 missing target 检查
- closure 链接可从 `GUI_TASK_TRACKER.md` 与 `docs/plans/README.md` 找到
- forbidden 检查：不修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`
- extra exposure 检查：无 `public` 修饰符、无 `enqueue` 命名、无 C ABI、无 raw pointer / native handle / platform object、无 real enqueue、无 drain / scheduler / event loop / runtime cycle、无 process-wide storage write、无 global singleton、无 module-level `var`
- GitNexus impact / detect_changes；新 owner symbols 若尚未索引，可记录 UNKNOWN / not found fallback evidence

## Candidate Comparison

### A. Milestone / manifest stabilization

优点：风险最低，可以进一步固定 `CjguiInternalQueuePublicEntryResultHandoff` 是当前 endpoint。

风险：当前 README / tracker / manifest 已跟上 public API shell closure；如果没有 manifest drift，继续 stabilization 会让 runway 进入文档空转。

Decision：不选择。

### B. Internal public exposure gate / symbol readiness boundary

优点：自然消费 `CjguiInternalQueuePublicEntryResultHandoff`，把 API shell handoff 交给下游 exposure owner，符合 Tail Endpoint Exit Gate；同时继续以 value facts 固定 visibility strategy、naming policy、symbol readiness 和 no-stable-compatibility stop-line。

风险：名称靠近 public API exposure，容易被误读为 public API implementation。因此下一轮必须继续 internal-only，不新增 `public` 修饰符，不使用 `enqueue` 命名，不开放 public runtime API / C ABI。

Decision：选择。

### C. Direct internal package public API implementation

风险：缺少 stable compatibility、API tests、versioning、user docs、public error return contract 和 lifecycle strategy。当前没有足够理由直接新增 `public` 修饰符。

Decision：拒绝。

### D. Public C ABI boundary

风险：C ABI 需要稳定 handle / lifecycle / ownership / threading / error ABI。当前仅有 internal API shell handoff facts。

Decision：拒绝。

### E. Real enqueue implementation

风险：当前 endpoint 不是 enqueue permission。直接 real enqueue 会绕过 public exposure gate、storage write safeguards、queue drain stop-line 与 scheduler / runtime cycle stop-line。

Decision：拒绝。

### F. Drain / scheduler / event loop

风险：过早靠近 runtime cycle；当前没有 public queue drain lifecycle、scheduler ownership 或 event loop contract。

Decision：拒绝。

### G. Runtime state integration

风险：会靠近 critical `runtime_state.cj` / runtime global state write。当前 `runtime_state.cj` 仍为 10065 行 critical warning。

Decision：拒绝。

### H. Tail consolidation

当前未发现明确 dead helper、重复 projection 或 same-owner self-wrapping。`runtime_queue_public_api_shell.cj` 的 endpoint 应交给下游 exposure owner，而不是继续同 owner 自包或 cleanup。

Decision：不选择。

## Decision

选择 B：

`P1 internal Queue public exposure gate / symbol readiness boundary bundle implementation`

下一轮建议：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_exposure.cj`。
- 只消费 `CjguiInternalQueuePublicEntryResultHandoff`。
- 表达 exposure gate / symbol readiness / naming policy / no-stable-compatibility facts。
- 继续 internal-only，不新增 `public` 修饰符。
- 继续不使用 `enqueue` 命名。
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
- 不创建 execution card。
- 不运行 `cjpm build` / smoke guard。
- 需运行 `git diff --check`。
- README / GUI_TASK_TRACKER / docs/plans README 需能找到本 preflight 与 next opening。
- Markdown 绝对链接 missing target 检查需通过。
- Forbidden 检查需确认未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。

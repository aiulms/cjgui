# P1 Queue Public Boundary Preflight Decision

日期：2026-05-01

## 当前事实

- 上一轮 docs-only decision 已选择进入 public queue boundary preflight。
- 当前 internal endpoint: `CjguiInternalQueueOwnerLocalWriteHandoffReceipt`
- 当前 owner file: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_owner_local_handoff.cj`
- 当前仍没有 public queue API、public C ABI、real enqueue、queue drain、scheduler、event loop 或 runtime cycle。
- `runtime_state.cj` 仍为 `10065` 行 critical warning，本轮和下一轮默认不得触碰。

## Preflight 结论

可以打开 public queue boundary 的第一刀，但只能是 internal-only public-boundary admission value facts。

下一步推荐：

`P1 internal Queue public boundary admission value bundle implementation`

该 opening 不实现 public API，不实现 public C ABI，不执行 real enqueue，不写 process-wide queue storage，不 drain，不接 scheduler / event loop / platform callback / runtime cycle。它只把 `CjguiInternalQueueOwnerLocalWriteHandoffReceipt` 投影成 public-boundary intent / submission / admission / rejection / readiness value facts，为未来真正 public surface 做可审计前置。

## 必答问题

### 1. Public Queue Truth Owner

Public queue truth 暂时不归 `runtime_state.cj`，也不归既有 `runtime_queue.cj` 主体。下一刀应新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_boundary.cj` 或等价 owner file。

理由：

- `runtime_state.cj` 已是 `10065` 行 critical warning，且 public boundary 不应借机写 runtime global state。
- `runtime_queue.cj` 当前承载 queue admission readiness 语义，不应被塞入 public surface 的第一刀。
- 新 owner 可以只消费 `CjguiInternalQueueOwnerLocalWriteHandoffReceipt`，保持与 internal owner-local write chain 的单向关系，避免绕过 Action Router / Queue gates。

Public boundary owner 的 truth 只能是 internal value facts：public-boundary intent、submission、admission、rejection、readiness。它不是 public API truth，不是 process-wide queue storage truth，也不是 enqueue side effect truth。

### 2. Public Enqueue Terminology

当前不能把下一刀称为 public enqueue。

推荐术语：

- `public queue intent`
- `public queue submission`
- `public boundary admission`
- `public boundary readiness`

原因：`enqueue` 容易被误读为真实 queue storage write / user-visible side effect。下一刀最多表达“一个 public-boundary-shaped request 是否可被 internal pipeline 接受”的 value facts，不执行 enqueue，不创建 queue item collection，不产生 drainable work。

### 3. Public API Shape

当前只允许 internal-only public-boundary value facts。

继续禁止：

- public runtime API
- public C ABI
- stable external API shape
- callback / observer surface
- direct user-facing enqueue function

下一刀可以定义内部 struct / builder / default draft，但这些 symbols 仍属于 internal package facts，不构成 compatibility promise。

### 4. 错误模型

Public-facing error 暂时应先映射成 value facts，而不是真实 error return API。

建议最小分类：

- `deferred`: public-boundary request 需要保持 defer，不伪造 admission。
- `blocked`: internal facts blocked / inconsistent，fail-closed。
- `rejected`: public-boundary request 语义不被当前 policy 接受。
- `incompatible`: API shape / compatibility promise 尚未冻结。
- `unauthorized`: permission / admission 不允许。

这些分类可以进入 public boundary admission value bundle；不需要先单独开薄 taxonomy owner。若下一轮发现 error fields 会膨胀，再另开 taxonomy / failure strengthening。

### 5. Permission / Admission / Rollback / Audit

Public-boundary request 必须保留 internal gates 的来源链：

- 必须只消费 `CjguiInternalQueueOwnerLocalWriteHandoffReceipt`。
- 必须保留 handoff receipt facts，不能绕过 owner-local write result handoff。
- Permission / admission 只能投影为 internal value facts，不是 public authorization side effect。
- Rollback / fallback facts 必须可追溯到既有 rollback availability / previous snapshot preservation，不执行 rollback side effect。
- Audit 只能是 internal value fact，不是 public audit log、observer callback 或 external notification。

### 6. Compatibility Promise

当前没有 stable API compatibility promise。

原因：

- 没有 public runtime API / C ABI shape。
- 没有 user-facing error return contract。
- 没有 public queue item schema。
- 没有 real enqueue / storage / drain lifecycle。

下一刀如实现 public-boundary value facts，也必须明确这些 facts 不构成 external compatibility promise。

### 7. 验证策略

Docs-only preflight 本轮验证：

- `git diff --check`
- README / GUI_TASK_TRACKER / docs/plans README 可找到 preflight 与 next opening。
- Markdown 绝对链接 missing target 检查。
- forbidden scope 检查，确认未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。

若下一轮进入 implementation，应验证：

- GitNexus impact on `CjguiInternalQueueOwnerLocalWriteHandoffReceipt` 与 `cjguiInternalExecuteDefaultQueueOwnerLocalWriteHandoffDraft`。
- `cjpm build --target-dir /tmp/cjgui-queue-public-boundary-admission-value-target --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`
- Markdown 绝对链接 missing target 检查。
- forbidden scan: 不修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public surface scan: 不出现 public runtime API / public C ABI / real enqueue / drain / scheduler / event loop / runtime cycle implementation。

## 候选比较

### A. Public boundary manifest stabilization

优点是风险低。

不选择原因：本轮已经能够明确 public boundary 的 owner、truth、terminology 和 stop-line。若只做 manifest stabilization，会在 public surface 前继续空转。

### B. Public boundary admission value bundle implementation

选择。下一轮可新建 `runtime_queue_public_boundary.cj`，只消费 `CjguiInternalQueueOwnerLocalWriteHandoffReceipt`，表达 public-boundary intent / submission / admission / rejection / readiness value facts。

它仍不提供 public API / C ABI，不 real enqueue，不 drain，不接 scheduler / event loop / runtime cycle。

### C. Public error taxonomy bundle implementation

暂缓。错误模型需要出现，但可以内嵌到 public boundary admission value facts 中。当前没有必要单独开薄 taxonomy。

### D. Public API implementation

拒绝。缺少 public API shape、compatibility promise、user-facing error contract、permission model 和 verification strategy。

### E. C ABI boundary

拒绝。C ABI 会形成外部兼容承诺，并可能绕过 internal queue gates；当前不具备开放条件。

### F. Drain / scheduler preflight

拒绝。Public boundary 尚未建立，drain / scheduler 会过早靠近 runtime cycle。

### G. Runtime-state integration

拒绝。该方向靠近 critical `runtime_state.cj` 与 runtime global state write；当前必须继续保持 owner split。

## Decision

选择 B：

`P1 internal Queue public boundary admission value bundle implementation`

理由：

- public boundary 的 owner / truth / terminology / stop-line 已足够清楚。
- 下一刀可以推进 public surface 前置能力，同时仍保持 internal-only value facts。
- 不需要先开独立 error taxonomy；error 分类可随 admission facts 一并落下。
- 直接 public API / C ABI / real enqueue / drain / runtime-state integration 都仍过早。

## 下一轮 owner / write set

推荐下一轮：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_boundary.cj`。
- 只消费 `CjguiInternalQueueOwnerLocalWriteHandoffReceipt`。
- 使用 terminology: `public boundary intent` / `public queue submission` / `public boundary admission` / `public boundary readiness`。
- 不直接命名为 public enqueue，不实现 public enqueue。
- 不回改 `runtime_queue_owner_local_handoff.cj` 的薄尾巴。
- 不触碰 `runtime_state.cj`。

## Stop-Line

下一轮仍禁止：

- public API implementation
- public C ABI implementation
- real enqueue
- queue storage write
- item collection mutation
- global mutable queue / singleton
- observer callback / public publication
- drain
- scheduler / event loop / platform callback
- runtime cycle
- runtime global state write
- touching critical `runtime_state.cj`

## Next Opening

`P1 internal Queue public boundary admission value bundle implementation`

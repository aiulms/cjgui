# P1 Renderer diagnostics policy next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Context

上一轮已完成 `P1 internal Renderer diagnostics policy boundary bundle implementation`。

当前 canonical endpoint：

- `CjguiInternalRendererDiagnosticsPolicyResult`
- `cjguiInternalExecuteDefaultRendererDiagnosticsPolicyDraft()`

当前 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_policy.cj`

当前 truth：

- internal diagnostics policy facts。
- severity handling policy facts。
- retention hint facts。
- no-external-diagnostics policy result facts。

该 endpoint 只表示 future diagnostics policy boundary 可继续评估，不是 logging subsystem、telemetry、observer callback、public diagnostics、exception system、backend handler、command buffer、renderer state write 或 render permission。

本轮不写 runtime code，不修改 `.cj`，不运行 build / smoke。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 decision 生效。

`CjguiInternalRendererDiagnosticsPolicyResult` 已经是 policy endpoint。继续新增 policy receipt / record / publication 会把 policy result 换名包装，缺少新的 owner truth、consumer、integration 或风险证据。

因此下一阶段不得默认实现：

- diagnostics policy receipt。
- diagnostics policy record。
- diagnostics policy publication。
- logging sink readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- public diagnostics readiness wrapper。

如果未来要靠近真实 diagnostics sink，必须先做 docs-only preflight，明确 sink owner、privacy、lifecycle、thread-safety、artifact policy 和 stop-line，而不能直接实现 logging / telemetry / observer。

## Candidate Comparison

### A. P1 internal Renderer diagnostics policy manifest stabilization bundle implementation

选择。

理由：

- Policy endpoint 已足够作为当前 tail：owner / truth / canonical endpoint / stop-line 已清楚。
- manifest stabilization 可以固定 `DiagnosticsPolicy` / `SeverityHandlingPolicy` / `RetentionHint` / `DiagnosticsPolicyResult` 的语义，防止下一轮误把 policy result 解释成 logging sink readiness、telemetry readiness 或 public diagnostics readiness。
- 这是对 Same-shape Boundary Brake 的直接响应：先封账，而不是继续新增 policy receipt / record / publication。

### B. P1 internal Renderer diagnostics sink preflight decision

暂缓。

只有当下一阶段确实要靠近真实 diagnostics sink runway 时才开。该 preflight 必须仍是 docs-only，并评估 sink owner、privacy、lifecycle、thread-safety、artifact policy 与 no-runtime-side-effect stop-line；不得直接实现 logging subsystem、telemetry、observer callback 或 public diagnostics。

### C. P1 internal Renderer diagnostics policy consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前读取 `runtime_renderer_diagnostics_policy.cj` 后未发现必须立即 cleanup 的对象。

### D. Diagnostics policy receipt / record / publication thin wrapper

拒绝。

这会直接触发 Same-shape Boundary Brake，且没有新增 owner truth。

### E. Logging subsystem / telemetry / observer callback / public diagnostics implementation

拒绝。

Policy result 只表达 internal value facts，不写文件、不打 stdout、不发事件、不保留外部 artifact，也不开放 public diagnostics。

### F. Backend packet / command buffer / backend submission

拒绝。

Diagnostics policy 不产生 backend packet，不接 command buffer，也不是 backend submission readiness。

### G. Sorting side effect / draw-call merge / GPU batching

拒绝。

Diagnostics policy 不执行 ordering mutation、draw-call merge 或 GPU batching。

### H. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full DisplayList / command list rebuild only，不做 incremental render。

### I. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

Diagnostics policy 不接平台对象、不持有 native handle，也不是 backend adapter。

### J. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth，不能混入 diagnostics policy endpoint。

### K. Runtime / Queue / Action integration

暂缓。

Diagnostics policy 当前只消费 `CjguiInternalRendererPacketDiagnosticsResult`，不读取 Queue / Action / Runtime lower-level mutable facts。

### L. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终选择：

`P1 internal Renderer diagnostics policy manifest stabilization bundle implementation`

下一轮默认 docs / manifest stabilization：

- 新增 diagnostics policy manifest。
- 固定 owner file：`runtime/cjgui/src/runtime_renderer_diagnostics_policy.cj`。
- 固定 canonical endpoint：`CjguiInternalRendererDiagnosticsPolicyResult` / `cjguiInternalExecuteDefaultRendererDiagnosticsPolicyDraft()`。
- 固定 current truth：internal diagnostics policy / severity handling / retention hint / no-external-diagnostics policy result facts。
- 明确不是 logging subsystem、telemetry、observer callback、public diagnostics、exception system、backend handler、backend packet、command buffer、renderer state write 或 render permission。
- 不新增 runtime code，不修改 `.cj`。

## Stop-line

下一轮继续禁止：

- no runtime code in manifest round。
- no `.cj` edits。
- no Metal / AppKit / backend implementation。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no stable backend API promise。
- no render side effect / draw call execution。
- no real draw op semantics。
- no real GPU batching / draw-call merge。
- no sorting side effect。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no exception system / public error API / logging subsystem / telemetry / observer callback。
- no file write / stdout / event publication / external artifact retention。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Verification Plan

本轮 docs-only decision 验证：

- `git diff --check`。
- Markdown absolute link missing target check。
- README / GUI_TASK_TRACKER / docs/plans README 能找到本 decision 与 next opening。
- forbidden check 确认未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`。
- 不运行 build / smoke。

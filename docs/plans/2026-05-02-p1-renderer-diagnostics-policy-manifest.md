# P1 Renderer diagnostics policy manifest

日期：2026-05-02

状态：manifest stabilization

## Purpose

本 manifest 固定 renderer diagnostics policy 的 owner / truth / canonical endpoint / stop-line，防止 `CjguiInternalRendererDiagnosticsPolicyResult` 后继续长 diagnostics policy receipt / record / publication 同构尾巴。

这不是 logging manifest、telemetry manifest、observer manifest 或 public diagnostics manifest。它只封账 renderer diagnostics value pipeline 内部的 diagnostics policy、severity handling policy、retention hint 与 no-external-diagnostics policy result facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_diagnostics_policy.cj`

Upstream facts：

- `CjguiInternalRendererPacketDiagnosticsResult`
- `CjguiInternalRendererPacketDiagnosticEvidence`
- `CjguiInternalRendererPacketDiagnosticSeverity`
- `CjguiInternalRendererPacketDiagnosticsSummary`

Canonical endpoint：

- `CjguiInternalRendererDiagnosticsPolicyResult`
- `cjguiInternalExecuteDefaultRendererDiagnosticsPolicyDraft()`

Current truth：

- internal diagnostics policy facts。
- diagnostic severity handling policy facts。
- diagnostic retention hint facts。
- no-logging / no-telemetry / no-observer / no-public-diagnostics value facts。
- no file write / no stdout / no event publication / no external artifact retention facts。

该 truth 不是 diagnostics policy receipt、diagnostics policy record 或 diagnostics policy publication。它也不是 logging subsystem、telemetry、observer callback、public diagnostics、exception system、backend handler、command buffer、renderer state write 或 render permission。

## Current Pipeline

当前 diagnostics policy pipeline：

1. `CjguiInternalRendererPacketDiagnosticsResult`
2. `CjguiInternalRendererDiagnosticsPolicy`
3. `CjguiInternalRendererDiagnosticSeverityHandlingPolicy`
4. `CjguiInternalRendererDiagnosticRetentionHint`
5. `CjguiInternalRendererDiagnosticsPolicyResult`

Default draft：

- `cjguiInternalExecuteDefaultRendererDiagnosticsPolicyDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / platform resources。
- 不写 file / stdout，不发布 event，不保留 external artifact。
- 不进入 logging subsystem、telemetry、observer callback、public diagnostics 或 backend handler。

## Policy Truth

Diagnostics policy 固定以下 facts：

- open / clean path 表达 policy allowed。
- defer-only path 保持 defer。
- blocked / inconsistent path fail-closed，并记录 policy blocked value facts。
- policy 是 internal-only value facts，不写外部诊断、不发事件、不触发外部通知。

Severity handling policy 固定以下 facts：

- open / clean path severity handling 为 internal-only / no action。
- defer-only path 保持 defer。
- blocked / inconsistent path 不伪造成可执行 action。
- severity handling 不写日志、不发布 telemetry、不调用 observer、不开放 public diagnostics。

Retention hint 固定以下 facts：

- open / clean path external artifact retention disabled。
- defer-only path 保持 defer。
- blocked / inconsistent path 仍保持 external retention disabled。
- retention hint 不写文件、不打 stdout、不保留外部 artifact。

Diagnostics policy result 只表示 internal diagnostics policy value facts 已形成。它不表示 logging sink readiness、telemetry readiness、observer readiness、public diagnostics readiness、backend permission、render permission、command buffer readiness 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

`CjguiInternalRendererDiagnosticsPolicyResult` 已经是当前 diagnostics policy endpoint。继续新增 diagnostics policy receipt / record / publication 会把同一结果换名包装，缺少新的 owner truth、consumer、integration 或风险证据。

因此下一阶段不得默认实现：

- diagnostics policy receipt。
- diagnostics policy record。
- diagnostics policy publication。
- logging sink readiness wrapper。
- telemetry readiness wrapper。
- observer readiness wrapper。
- public diagnostics readiness wrapper。

如果未来要靠近真实 diagnostics sink，必须先做 docs-only preflight，明确 sink owner、privacy、lifecycle、thread-safety、artifact policy、debug-only boundary 与 no-runtime-side-effect stop-line，而不能直接实现 logging / telemetry / observer callback。

## Explicit Non-Truth

本 manifest 明确当前 diagnostics policy endpoint 不是：

- diagnostics policy receipt / record / publication。
- logging subsystem。
- telemetry。
- observer callback。
- public diagnostics。
- exception system。
- public error API。
- backend handler。
- backend packet。
- backend submission。
- command buffer。
- Metal / AppKit。
- CAMetalLayer / MTLDevice。
- native handle / raw pointer / platform object。
- renderer state write。
- render permission。
- file write。
- stdout output。
- event publication。
- external artifact retention。
- sorting side effect。
- draw call。
- GPU batching。
- draw-call merge。
- dirty-region / diff / patch / incremental render。
- Widget / Layout / Text / IME / Accessibility / ECS。
- public API / public C ABI。

## Full Rebuild Policy

P1 仍保持 full DisplayList / command list / batching packet rebuild only。

当前不实现：

- dirty region。
- repaint boundary。
- display list diff。
- display list patch。
- incremental command update。
- incremental batching update。
- partial repaint。
- render cache。
- actual sort mutation。
- actual draw-call merge。
- GPU batching。

Diagnostics policy 只投影 diagnostics pipeline 的 internal value facts，不引入 incremental render 语义。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
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
- no backend handler / render failure callback。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI、public diagnostics 或 public error API。

## Next Stage Candidate Comparison

### A. P1 internal Renderer diagnostics sink preflight decision

选择。

理由：

- Diagnostics policy endpoint 已封账后，若要继续靠近 diagnostics runway，下一步应先 docs-only 评估 future sink owner / privacy / lifecycle / thread-safety / artifact policy / debug-only stop-line。
- 该 preflight 不实现 logging，不创建 sink runtime code，不写文件、不打 stdout、不发事件、不保留外部 artifact。
- 相比 policy receipt / record / publication，sink preflight 能讨论真实下游边界，但仍保持 no-runtime-code guard。

### B. P1 internal Renderer diagnostics policy consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper、dead helper 或 manifest drift 时才开。当前 manifest 先固定 endpoint 和 stop-line，不为 cleanup 而 cleanup。

### C. Diagnostics policy receipt / record / publication

拒绝。

这会直接触发 Same-shape Boundary Brake。

### D. Logging / telemetry / observer callback / public diagnostics implementation

拒绝。

Diagnostics policy result 只表达 internal value facts，不写文件、不打 stdout、不发事件、不保留外部 artifact，也不开放 public diagnostics。

### E. Backend packet / command buffer / render permission / renderer state write

拒绝。

Diagnostics policy 不产生 backend packet，不接 command buffer，不写 renderer state，也不是 render permission。

### F. Dirty-region / UI system / Widget / Layout / Text / IME / Accessibility

暂缓。

这些需要独立 owner truth，不能混入 diagnostics policy endpoint。

### G. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer diagnostics sink preflight decision`

下一轮应保持 docs-only preflight，评估 future diagnostics sink owner / privacy / lifecycle / thread-safety / artifact policy / debug-only stop-line。它不批准 logging subsystem、telemetry、observer callback、public diagnostics、file write、stdout、event publication、external artifact retention、backend packet、command buffer、render execution、sorting side effect、draw-call merge、GPU batching、diff / patch 或 public surface expansion。

## Downstream Status

`P1 internal Renderer diagnostics sink preflight decision` 已完成，decision 见：

- [2026-05-02-p1-renderer-diagnostics-sink-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-sink-preflight-decision.md)

`P1 internal Renderer diagnostics sink policy value boundary bundle implementation` 已完成，closure 见：

- [2026-05-02-p1-internal-renderer-diagnostics-sink-policy-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-diagnostics-sink-policy-boundary-closure-review.md)

当前 downstream canonical endpoint 是：

- `CjguiInternalRendererDiagnosticsNoOutputReadiness`
- `cjguiInternalExecuteDefaultRendererDiagnosticsSinkPolicyDraft()`

该 endpoint 仍只允许 internal value facts，不批准 logging subsystem、telemetry、observer callback、event bus、public diagnostics、file write、stdout / stderr、event publication、external artifact retention、backend packet、command buffer、renderer state write 或 render permission。当前 next opening 是 `P1 internal Renderer diagnostics sink policy closure / next diagnostics sink decision`。

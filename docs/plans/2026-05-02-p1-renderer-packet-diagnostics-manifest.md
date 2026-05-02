# P1 Renderer packet diagnostics manifest

日期：2026-05-02

状态：manifest stabilization

## Purpose

本 manifest 固定 renderer packet diagnostics 的 owner / truth / canonical endpoint / stop-line，防止 `CjguiInternalRendererPacketDiagnosticsResult` 后继续长 diagnostics receipt / record / publication 同构尾巴。

这不是 public diagnostics manifest，也不是 logging / telemetry / observer manifest。它只封账 renderer packet value pipeline 内部的 diagnostics summary、diagnostic severity 与 diagnostic evidence facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_packet_diagnostics.cj`

Upstream facts：

- `CjguiInternalRendererPacketErrorTaxonomyResult`
- `CjguiInternalRendererPacketNormalizationResult`

Canonical endpoint：

- `CjguiInternalRendererPacketDiagnosticsResult`
- `cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft()`

Current truth：

- internal packet diagnostics summary facts。
- diagnostic severity facts。
- diagnostic evidence facts。
- no-logging / no-telemetry / no-observer / no-public-diagnostics facts。

该 truth 不是 diagnostics receipt、diagnostics record 或 diagnostics publication。它也不是 logging subsystem、telemetry、observer callback、public diagnostics、backend error handler、render failure callback、backend packet、command buffer、renderer state write 或 render permission。

## Current Pipeline

当前 diagnostics pipeline：

1. `CjguiInternalRendererPacketErrorTaxonomyResult`
2. preserved failure / degraded / blocked reason taxonomy facts
3. `CjguiInternalRendererPacketDiagnosticsSummary`
4. `CjguiInternalRendererPacketDiagnosticSeverity`
5. `CjguiInternalRendererPacketDiagnosticEvidence`
6. `CjguiInternalRendererPacketDiagnosticsResult`

Default draft：

- `cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / platform resources。
- 不写 logging subsystem、不发布 telemetry、不调用 observer callback、不开放 public diagnostics。

## Diagnostics Truth

Diagnostics summary 固定以下 facts：

- open / valid path 表达 clean / no issue diagnostics。
- defer-only path 保持 defer。
- blocked / inconsistent path fail-closed，并记录内部 blocked summary facts。
- summary 是 internal value facts，不写日志、不发布事件、不触发外部通知。

Diagnostic severity 固定以下 facts：

- open / valid path severity 为 none。
- defer-only path 保持 defer。
- blocked / inconsistent path 不伪造成 severity none。
- severity 是 value fact，不代表 backend status、render permission 或 command buffer readiness。

Diagnostic evidence 固定以下 facts：

- 保留 failure taxonomy、degraded reason、blocked reason 作为内部证据 facts。
- evidence 不发布 public diagnostics，不触发 observer callback，不进入 backend error handler。
- evidence 不拥有日志、telemetry 或 renderer state truth。

Diagnostics result 只表示 internal diagnostics value facts 已形成。它不表示 logging readiness、telemetry readiness、observer readiness、backend permission、render permission、backend error handling readiness、command buffer readiness 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

`CjguiInternalRendererPacketDiagnosticsResult` 已经是当前 diagnostics endpoint。继续新增 diagnostics receipt / record / publication 会把同一结果换名包装，缺少新的 owner truth、consumer、integration 或风险证据。

因此下一阶段不得默认实现：

- diagnostics receipt。
- diagnostics record。
- diagnostics publication。
- diagnostics logging wrapper。
- diagnostics telemetry wrapper。
- diagnostics observer wrapper。
- backend readiness wrapper。
- public diagnostics wrapper。

若未来要继续实现，必须证明新边界新增不可替代语义，例如 internal diagnostics policy、明确 downstream owner、backend-agnostic packet handoff preflight 或明确 consolidation target。

## Explicit Non-Truth

本 manifest 明确当前 diagnostics endpoint 不是：

- diagnostics receipt / record / publication。
- logging subsystem。
- telemetry。
- observer callback。
- public diagnostics。
- exception system。
- public error API。
- backend error handler。
- render failure callback。
- backend packet。
- backend submission。
- command buffer。
- Metal / AppKit。
- CAMetalLayer / MTLDevice。
- native handle / raw pointer / platform object。
- renderer state write。
- render permission。
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

Diagnostics 只投影 validation / normalization / taxonomy pipeline 的 internal value facts，不引入 incremental render 语义。

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
- no backend error handler / render failure callback。
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

### A. P1 internal Renderer diagnostics policy boundary bundle implementation

选择。

理由：

- Diagnostics endpoint 已封账后，internal diagnostics policy / severity handling policy / retention hint / no-public-diagnostics facts 是自然下游候选。
- Policy 可以回答 severity facts 如何被 future internal runway 使用，但仍保持 value facts，不进入 logging / telemetry / observer / public diagnostics。
- 相比 diagnostics receipt / publication，它新增的是 policy vocabulary，而不是把 diagnostics result 换名包装。

### B. P1 internal Renderer normalized packet handoff preflight decision

暂缓。

只有找到明确 downstream owner 时才开。没有 downstream owner 时，handoff 容易退化成 receipt wrapper，不满足 Same-shape Boundary Brake。

### C. P1 internal Renderer packet diagnostics consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前 manifest 先固定 endpoint 和 stop-line，不为 cleanup 而 cleanup。

### D. Diagnostics receipt / record / publication

拒绝。

这会直接触发 Same-shape Boundary Brake。

### E. Logging subsystem / telemetry / observer callback / public diagnostics

拒绝。

Diagnostics result 只表达 internal value facts，不发布、不写外部日志、不调用 observer、不开放 public diagnostics。

### F. Backend packet / command buffer / backend submission

拒绝。

Diagnostics result 不是 backend packet readiness，也不允许生成 command buffer 或 backend submission。

### G. Sorting side effect / draw-call merge / GPU batching

拒绝。

Diagnostics 不执行 ordering mutation、draw-call merge 或 GPU batching。

### H. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full DisplayList / command list / batching packet rebuild only。

### I. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

Diagnostics endpoint 不接平台对象，不持有 native handle，也不是 backend adapter。

### J. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth，不能混入 renderer packet diagnostics endpoint。

### K. Runtime / Queue / Action integration

暂缓。

Diagnostics owner 当前只消费 `CjguiInternalRendererPacketErrorTaxonomyResult`，不读取 Queue / Action / Runtime lower-level mutable facts。

### L. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer diagnostics policy boundary bundle implementation`

下一轮若实现，应保持 internal-only backend-agnostic value facts，只消费 `CjguiInternalRendererPacketDiagnosticsResult`，表达 internal diagnostics policy / severity handling policy / retention hint / no-public-diagnostics facts。它不批准 logging subsystem、telemetry、observer callback、public diagnostics、backend error handler、render failure callback、backend packet、command buffer、render execution、sorting side effect、draw-call merge、GPU batching、diff / patch 或 public surface expansion。

## Downstream Status

`P1 internal Renderer diagnostics policy boundary bundle implementation` 已完成，closure 见：

- [2026-05-02-p1-internal-renderer-diagnostics-policy-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-diagnostics-policy-boundary-closure-review.md)

当前 downstream endpoint 是 `CjguiInternalRendererDiagnosticsPolicyResult` / `cjguiInternalExecuteDefaultRendererDiagnosticsPolicyDraft()`。它仍只表达 internal value facts，不批准 diagnostics receipt / record wrapper、logging subsystem、telemetry、observer callback、public diagnostics、backend packet、command buffer、renderer state write 或 render permission。

Diagnostics policy downstream manifest 已完成：

- [2026-05-02-p1-renderer-diagnostics-policy-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-diagnostics-policy-manifest.md)
- [2026-05-02-p1-internal-renderer-diagnostics-policy-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-diagnostics-policy-manifest-stabilization-closure-review.md)

当前 next opening 已转向 `P1 internal Renderer diagnostics sink preflight decision`，仍为 docs-only preflight，不批准 logging subsystem、telemetry、observer callback、public diagnostics、file write、stdout、event publication 或 external artifact retention。

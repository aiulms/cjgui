# P1 Renderer packet error taxonomy manifest

日期：2026-05-02

状态：manifest stabilization

## Purpose

本 manifest 固定 renderer packet error taxonomy 的 owner / truth / canonical endpoint / stop-line，防止 `CjguiInternalRendererPacketErrorTaxonomyResult` 后继续长 taxonomy receipt / record / publication 同构尾巴。

这不是 exception manifest，也不是 public error API manifest。它只封账 renderer packet value pipeline 内部的 failure taxonomy、degraded reason 与 blocked reason facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_packet_error_taxonomy.cj`

Upstream facts：

- `CjguiInternalRendererPacketNormalizationResult`
- `CjguiInternalRendererCommandValidationResult`

Canonical endpoint：

- `CjguiInternalRendererPacketErrorTaxonomyResult`
- `cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()`

Current truth：

- renderer packet failure taxonomy facts。
- renderer packet degraded reason facts。
- renderer packet blocked reason facts。
- no-exception / no-public-error / no-backend-callback taxonomy result facts。

该 truth 不是 taxonomy receipt、taxonomy record 或 taxonomy publication。它也不是 exception system、public error API、backend error handler、render failure callback、backend packet、command buffer、renderer state write 或 render permission。

## Current Pipeline

当前 taxonomy pipeline：

1. `CjguiInternalRendererPacketNormalizationResult`
2. preserved normalization result facts
3. `CjguiInternalRendererPacketFailureTaxonomy`
4. `CjguiInternalRendererPacketDegradedReason`
5. `CjguiInternalRendererPacketBlockedReason`
6. `CjguiInternalRendererPacketErrorTaxonomyResult`

Default draft：

- `cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / platform resources。
- 不抛异常、不写日志、不发布 public error、不触发 observer callback。

## Taxonomy Truth

Failure taxonomy 固定以下 facts：

- open / valid path 表达 no failure。
- defer-only path 保持 defer。
- blocked / inconsistent path fail-closed，并记录内部 failure 分类。
- failure taxonomy 是 internal value facts，不抛异常，不发布错误，不触发外部通知。

Degraded reason 固定以下 facts：

- open / valid path 表达 no degraded reason。
- defer-only path 保持 defer。
- blocked / inconsistent path 不伪造成 degraded-ready。
- degraded reason 只保留内部分类位置，不对外暴露错误协议。

Blocked reason 固定以下 facts：

- open / valid path 表达 no blocked reason。
- blocked / inconsistent path 记录 fail-closed blocked reason。
- blocked reason 是 value fact，不触发 backend handler、observer callback 或 render callback。

Taxonomy result 只表示 internal value-fact taxonomy gate 的结果。它不表示 backend permission、render permission、backend error handling readiness、diagnostics publication readiness、command buffer readiness 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

`CjguiInternalRendererPacketErrorTaxonomyResult` 已经是当前 taxonomy endpoint。继续新增 taxonomy receipt / record / publication 会把同一结果换名包装，缺少新的 owner truth、consumer、integration 或风险证据。

因此下一阶段不得默认实现：

- taxonomy receipt。
- taxonomy record。
- taxonomy publication。
- diagnostics publication wrapper。
- backend readiness wrapper。
- public error wrapper。

若未来要继续实现，必须证明新边界新增不可替代语义，例如 internal diagnostics facts、明确 downstream owner、backend packet preflight 或明确 consolidation target。

## Explicit Non-Truth

本 manifest 明确当前 taxonomy endpoint 不是：

- taxonomy receipt / record / publication。
- exception system。
- public error API。
- logging subsystem。
- observer callback。
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

Taxonomy 只分类 validation / normalization pipeline 的 value facts，不引入 incremental render 语义。

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
- no exception system / public error API / logging subsystem / observer callback。
- no backend error handler / render failure callback。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI 或 public error API。

## Next Stage Candidate Comparison

### A. P1 internal Renderer packet diagnostics boundary bundle implementation

选择。

理由：

- Taxonomy endpoint 已封账后，从 taxonomy result 形成 internal diagnostics facts 是自然下游。
- Diagnostics 可以只表达 internal diagnostic subject / severity placeholder / diagnostic projection / result value facts。
- 它可以保留 failure / degraded / blocked reason 的内部可读性，而不引入 public diagnostics、logging subsystem、observer callback 或 backend error handler。
- 相比 taxonomy receipt / publication，它新增的是 diagnostics vocabulary，而不是把 taxonomy result 换名包装。

### B. P1 internal Renderer normalized packet handoff preflight decision

暂缓。

只有找到明确 downstream owner 时才开。没有 downstream owner 时，handoff 容易退化成 receipt wrapper，不满足 Same-shape Boundary Brake。

### C. P1 internal Renderer packet taxonomy consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前 manifest 先固定 endpoint 和 stop-line，不为 cleanup 而 cleanup。

### D. Taxonomy receipt / record / publication

拒绝。

这会直接触发 Same-shape Boundary Brake。

### E. Backend packet / command buffer / backend submission

拒绝。

Taxonomy result 不是 backend packet readiness，也不允许生成 command buffer 或 backend submission。

### F. Sorting side effect / draw-call merge / GPU batching

拒绝。

Taxonomy 只分类 packet value facts，不执行 ordering mutation、draw-call merge 或 GPU batching。

### G. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full DisplayList / command list / batching packet rebuild only。

### H. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

Taxonomy endpoint 不接平台对象，不持有 native handle，也不是 backend adapter。

### I. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth，不能混入 renderer packet taxonomy endpoint。

### J. Runtime / Queue / Action integration

暂缓。

Taxonomy owner 当前只消费 `CjguiInternalRendererPacketNormalizationResult`，不读取 Queue / Action / Runtime lower-level mutable facts。

### K. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer packet diagnostics boundary bundle implementation`

下一轮若实现，应保持 internal-only backend-agnostic value facts，只消费 `CjguiInternalRendererPacketErrorTaxonomyResult`，表达 internal diagnostics facts。它不批准 public diagnostics、logging subsystem、observer callback、backend error handler、render failure callback、backend packet、command buffer、render execution、sorting side effect、draw-call merge、GPU batching、diff / patch 或 public surface expansion。

## Downstream Status

Renderer packet diagnostics boundary 已落地：

- [2026-05-02-p1-internal-renderer-packet-diagnostics-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-diagnostics-boundary-closure-review.md)

当前 downstream endpoint 是 `CjguiInternalRendererPacketDiagnosticsResult` / `cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft()`。它只消费 `CjguiInternalRendererPacketErrorTaxonomyResult`，表达 internal diagnostics summary / severity / evidence / result value facts；它不是 taxonomy receipt / record / publication、public diagnostics、外部诊断写入、observer callback、backend error handler、render failure callback、backend packet、command buffer、renderer state write 或 render permission。Same-shape Boundary Brake 生效：diagnostics 新增 summary / severity / evidence 语义，而不是把 taxonomy result 换名包装。

Renderer packet diagnostics manifest 已完成：

- [2026-05-02-p1-renderer-packet-diagnostics-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-diagnostics-manifest.md)
- [2026-05-02-p1-internal-renderer-packet-diagnostics-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-diagnostics-manifest-stabilization-closure-review.md)

该 manifest 固定 `CjguiInternalRendererPacketDiagnosticsResult` / `cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft()` 为 diagnostics canonical endpoint。Same-shape Boundary Brake 生效：下一阶段不新增 diagnostics receipt / record / publication，而是进入 internal diagnostics policy boundary。

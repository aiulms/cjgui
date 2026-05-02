# P1 internal Renderer packet diagnostics manifest stabilization closure review

日期：2026-05-02

## Scope

本轮完成 `P1 internal Renderer packet diagnostics manifest stabilization bundle implementation`。

实际新增文档：

- [2026-05-02-p1-renderer-packet-diagnostics-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-diagnostics-manifest.md)

同步文档：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-02-p1-renderer-packet-error-taxonomy-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-error-taxonomy-manifest.md)
- [2026-05-02-p1-renderer-packet-normalization-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-normalization-manifest.md)

本轮未新增 runtime code，未修改 `.cj` 文件，未运行 build / smoke。

## Manifest Conclusion

新增 manifest 固定当前 diagnostics owner：

- owner file：`runtime_renderer_packet_diagnostics.cj`
- upstream facts：`CjguiInternalRendererPacketErrorTaxonomyResult` / `CjguiInternalRendererPacketNormalizationResult`
- canonical endpoint：`CjguiInternalRendererPacketDiagnosticsResult` / `cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft()`
- current truth：internal diagnostics summary / diagnostic severity / diagnostic evidence / no-logging / no-telemetry / no-observer / no-public-diagnostics value facts

Manifest 明确 diagnostics endpoint 不是 diagnostics receipt / record / publication、logging subsystem、telemetry、observer callback、public diagnostics、backend error handler、render failure callback、backend packet、command buffer、native handle / raw pointer、renderer state write 或 render permission。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 manifest 封账生效。

原因：

- `CjguiInternalRendererPacketDiagnosticsResult` 已经是 current diagnostics endpoint。
- 上一轮 implementation 已新增 summary / severity / evidence 语义。
- 若继续追加 diagnostics receipt / record / publication，会把同一 result 换名包装，缺少新的 owner truth。
- Manifest 选择固定 endpoint 与 stop-line，而不是继续新增同构 owner file。

## Next Stage Candidate Comparison

### A. P1 internal Renderer diagnostics policy boundary bundle implementation

选择为下一步。

理由：diagnostics endpoint 封账后，internal diagnostics policy / severity handling policy / retention hint / no-public-diagnostics facts 是自然下游。但下一轮仍必须保持 internal-only value facts，不得进入 logging subsystem、telemetry、observer callback 或 public diagnostics。

### B. P1 internal Renderer normalized packet handoff preflight decision

暂缓。

只有能找到明确 downstream owner 时才开；否则 handoff 容易成为 receipt wrapper。

### C. P1 internal Renderer packet diagnostics consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper 或 self-wrapping helper 时才开。

### D. Diagnostics receipt / record / publication

拒绝。

这会违反 Same-shape Boundary Brake。

### E. Logging subsystem / telemetry / observer callback / public diagnostics

拒绝。

当前 diagnostics 是 internal value facts，不是外部诊断机制。

### F. Backend packet / command buffer / backend submission

拒绝，过早。

Diagnostics endpoint 不是 backend readiness。

### G. Sorting side effect / draw-call merge / GPU batching

拒绝。

Diagnostics 不执行排序或 batching 副作用。

### H. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full rebuild only。

### I. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

Diagnostics endpoint 不接平台对象。

### J. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth。

### K. Runtime / Queue / Action integration

暂缓。

Diagnostics owner 不读取 lower-level mutable facts。

### L. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Stop-line

本轮保持：

- no runtime code；
- no `.cj` edits；
- no Metal / AppKit / backend implementation；
- no CAMetalLayer / MTLDevice / command buffer；
- no native handle / raw pointer / platform object；
- no stable backend API promise；
- no render execution / draw call；
- no real draw op / GPU batching / draw-call merge；
- no sorting side effect；
- no dirty-region / diff / patch / incremental render；
- no Widget / Layout / Text / IME / Accessibility / ECS；
- no exception system / public error API / logging subsystem / telemetry / observer callback；
- no backend error handler / render failure callback；
- no Queue / Action / Runtime lower-level mutable facts；
- no public symbol expansion；
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change；
- no `runtime_state.cj` touch。

## Verification

Docs-only checks：

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- README / GUI_TASK_TRACKER / docs/plans README reachability for manifest / closure / next opening：通过。
- forbidden check：通过；本轮未修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke / harness / native bridge / entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan：通过；仍只有 `runtime_queue_public_submit.cj` 内允许的 `public func cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`：risk level low，affected processes 0。

本轮按要求未运行 `cjpm build` 或 smoke guard。

## Next Opening

建议下一步：

`P1 internal Renderer diagnostics policy boundary bundle implementation`

下一轮若实现，应只消费 `CjguiInternalRendererPacketDiagnosticsResult`，表达 internal diagnostics policy / severity handling policy / retention hint / no-public-diagnostics facts。不得引入 logging subsystem、telemetry、observer callback、public diagnostics、backend error handler、render failure callback、backend packet、command buffer、render execution、sorting side effect、draw-call merge、GPU batching、dirty-region / diff / patch 或 public surface expansion。

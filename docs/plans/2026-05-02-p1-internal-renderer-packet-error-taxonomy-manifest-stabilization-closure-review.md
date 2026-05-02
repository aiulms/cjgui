# P1 internal Renderer packet error taxonomy manifest stabilization closure review

日期：2026-05-02

本轮任务：实现 `P1 internal Renderer packet error taxonomy manifest stabilization bundle implementation`。

## Landed Scope

新增 manifest：

- `docs/plans/2026-05-02-p1-renderer-packet-error-taxonomy-manifest.md`

更新索引 / 状态文档：

- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md`
- `docs/plans/2026-05-02-p1-renderer-packet-normalization-manifest.md`

本轮没有修改 runtime source，没有修改任何 `.cj` 文件，没有运行 build / smoke。

## Manifest Conclusion

`CjguiInternalRendererPacketErrorTaxonomyResult` / `cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()` 被固定为 renderer packet error taxonomy canonical endpoint。

当前 truth 是：

- renderer packet failure taxonomy facts；
- renderer packet degraded reason facts；
- renderer packet blocked reason facts；
- no-exception / no-public-error / no-backend-callback taxonomy result facts。

该 endpoint 不是 taxonomy receipt、taxonomy record、taxonomy publication、异常系统、public error API、logging subsystem、observer callback、backend error handler、render failure callback、backend packet、command buffer、renderer state write 或 render permission。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮通过 manifest 封账生效。

上一轮 taxonomy boundary 已新增 failure taxonomy / degraded reason / blocked reason 语义；本轮没有继续新增 taxonomy receipt / record / publication，也没有把 taxonomy result 解释成 diagnostics publication、backend packet readiness 或 render permission。

因此本轮选择 manifest stabilization，而不是继续延长 taxonomy tail。

## Next Stage Candidate Comparison

### A. P1 internal Renderer packet diagnostics boundary bundle implementation

选择。

原因是 taxonomy endpoint 封账后，internal diagnostics facts 是自然下游；它可以投影 internal diagnostic subject / severity placeholder / diagnostic projection / result value facts，但必须继续不是 public diagnostics、logging subsystem、observer callback、backend error handler 或 render failure callback。

### B. P1 internal Renderer normalized packet handoff preflight decision

暂缓。

只有能找到明确 downstream owner 时才开，不得只是 taxonomy result handoff receipt wrapper。

### C. P1 internal Renderer packet taxonomy consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。

### D. Taxonomy receipt / record / publication

拒绝。

这会直接违反 Same-shape Boundary Brake。

### E. Backend packet / command buffer / backend submission

拒绝。

Taxonomy endpoint 不是 backend packet readiness。

### F. Sorting side effect / draw-call merge / GPU batching

拒绝。

Taxonomy 只分类 value facts。

### G. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full DisplayList / command list rebuild only。

### H. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

Taxonomy endpoint 不接平台资源。

### I. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth。

### J. Runtime / Queue / Action integration

暂缓。

Taxonomy owner 不读取 lower-level mutable facts。

### K. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Stop-line

本轮保持：

- no runtime code；
- no `.cj` edits；
- no platform backend implementation；
- no platform adapter；
- no native handle / raw pointer / platform object；
- no command buffer；
- no renderer state write；
- no render permission；
- no sorting side effect；
- no real drawing work / batching / merge；
- no dirty-region / diff / patch / incremental render；
- no Widget / Layout / Text / IME / Accessibility / ECS；
- no exception system；
- no public error API；
- no logging subsystem；
- no observer callback；
- no backend error handler；
- no render failure callback；
- no Queue / Action / Runtime lower-level mutable facts；
- no public symbol expansion；
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change；
- no `runtime_state.cj` touch。

## Verification

Required docs-only checks：

- `git diff --check`
- Markdown absolute link missing target check
- README / GUI_TASK_TRACKER / docs/plans README reachability for manifest / closure / next opening
- forbidden check for runtime code, `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke / harness / native bridge / entry, `AGENTS.md`, `CLAUDE.md`, `CANGJIE_ISSUE_LEDGER.md`
- public declaration scan
- GitNexus `detect_changes(scope=unstaged)`

本轮按要求不运行 `cjpm build` 或 smoke guard。

## Next Opening

建议下一步：

`P1 internal Renderer packet diagnostics boundary bundle implementation`

下一轮若实现，应只消费 `CjguiInternalRendererPacketErrorTaxonomyResult`，表达 internal diagnostics value facts。不得引入 public diagnostics、logging subsystem、observer callback、backend error handler、render failure callback、backend packet、command buffer、render execution、sorting side effect、draw-call merge、GPU batching、dirty-region / diff / patch 或 public surface expansion。

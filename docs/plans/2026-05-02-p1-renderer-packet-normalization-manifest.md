# P1 Renderer packet normalization manifest

日期：2026-05-02

状态：manifest stabilization

## Purpose

本 manifest 固定 renderer packet normalization 的 owner / truth / canonical endpoint / stop-line，防止 `CjguiInternalRendererPacketNormalizationResult` 后继续长 normalization receipt / record / publication 同构尾巴。

这不是 backend manifest，也不是 renderer execution manifest。它只封账 normalized packet、ordering facts 与 material grouping hints 的 backend-agnostic value boundary。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_packet_normalization.cj`

Upstream facts：

- `CjguiInternalRendererCommandValidationResult`
- `CjguiInternalRenderBatchingPacket`
- `CjguiInternalRenderCommandPacket`

Canonical endpoint：

- `CjguiInternalRendererPacketNormalizationResult`
- `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`

Current truth：

- backend-agnostic normalized packet candidate facts。
- normalized ordering facts。
- normalized material grouping hint facts。
- no-render / no-backend / no-command-buffer normalization result facts。

该 truth 不是 normalization receipt、normalization record 或 normalization publication。它也不是 backend packet、backend shell、platform adapter、Metal / AppKit adapter、command buffer、renderer state write、render permission、真实排序结果或真实 draw / batching。

## Current Pipeline

当前 normalization pipeline：

1. `CjguiInternalRendererCommandValidationResult`
2. preserved `CjguiInternalRenderCommandPacket` facts
3. preserved `CjguiInternalRenderBatchingPacket` facts
4. `CjguiInternalRendererNormalizedPacketCandidate`
5. `CjguiInternalRendererNormalizedOrderingFacts`
6. `CjguiInternalRendererNormalizedMaterialGroupingFacts`
7. `CjguiInternalRendererPacketNormalizationResult`

Default draft：

- `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererCommandValidationDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / platform resources。
- 不执行 sorting side effect。

## Normalization Truth

Normalized packet candidate 固定以下 facts：

- validated command / batching facts 被保留。
- stable node id、bounds、clip、z-order、material key、version 与 invalidation hint 被保留。
- packet shape 仍是 backend-agnostic value facts。
- P1 仍是 full rebuild only。
- candidate 不是 backend packet。

Normalized ordering facts 固定以下 facts：

- packet ordering facts 已被 value-style normalized 描述。
- ordering facts 不执行真实排序副作用。
- 不重排 queue、renderer state 或 command list。
- P1 仍是 full rebuild only。

Normalized material grouping facts 固定以下 facts：

- material grouping 只是 backend-agnostic grouping hints。
- batch key 仍是 hint。
- batching plan 仍是 dehydrated value plan。
- 不做真实 draw-call merge。
- 不做 GPU batching。

Normalization result 只表示 internal value-fact normalization gate 的结果。它不表示 backend permission、render permission、backend packet readiness、command buffer readiness、renderer state write 或 stable backend API promise。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

`CjguiInternalRendererPacketNormalizationResult` 已经是当前 normalization endpoint。继续新增 normalization receipt / record / publication 会把同一结果换名包装，缺少新的 owner truth、consumer、integration 或风险证据。

因此下一阶段不得默认实现：

- normalization receipt。
- normalization record。
- normalization publication。
- backend packet readiness wrapper。
- normalized packet handoff without downstream owner。

若未来要继续实现，必须证明新边界新增不可替代语义，例如 packet error taxonomy、明确 downstream owner、backend packet preflight 或明确 consolidation target。

## Explicit Non-Truth

本 manifest 明确当前 normalization endpoint 不是：

- normalization receipt / record / publication。
- backend packet。
- backend shell。
- platform adapter。
- Metal / AppKit。
- CAMetalLayer / MTLDevice / command buffer。
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

Normalization 只确认 full rebuild value facts 被保留并被规范化描述，不引入 incremental render 语义。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
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
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Stage Candidate Comparison

### A. P1 internal Renderer packet error taxonomy boundary bundle implementation

选择。

理由：

- Normalization endpoint 已封账后，补 failure / degraded / blocked reason taxonomy 能新增明确语义。
- Error taxonomy 仍可保持 backend-agnostic value facts，不进入 renderer backend execution。
- 它比 receipt / handoff / backend packet 更稳：只解释 normalization failure shape，不承诺 backend packet readiness。
- 它可以为未来 normalized packet handoff 或 backend packet preflight 提供更清楚的 blocked reason。

### B. P1 internal Renderer normalized packet handoff preflight decision

暂缓。

只有找到明确 downstream owner 时才开。没有 downstream owner 时，handoff 容易退化成 receipt wrapper，不满足 Same-shape Boundary Brake。

### C. P1 internal Renderer backend packet preflight decision

暂缓并谨慎。

Backend packet vocabulary 风险较高，容易被误读为 command buffer / backend submission。若未来进入，必须先明确它仍不是 command buffer、backend submission、platform resource 或 render permission。

### D. P1 internal Renderer packet normalization consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才开。当前 manifest 先固定 endpoint 和 stop-line，不为 cleanup 而 cleanup。

### E. Normalization receipt / record / publication

拒绝。

这会直接触发 Same-shape Boundary Brake。

### F. Backend packet / command buffer / backend submission

拒绝。

Normalization result 不是 backend packet readiness，也不允许生成 command buffer 或 backend submission。

### G. Sorting side effect / draw-call merge / GPU batching

拒绝。

Ordering facts 只描述 value facts；material grouping facts 不是真实 draw-call merge 或 GPU batching。

### H. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍是 full DisplayList / command list / batching packet rebuild only。

### I. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

Normalization endpoint 不持有平台资源，也不是平台 bridge 或 backend adapter。

### J. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth，不能混入 packet normalization endpoint。

### K. Runtime / Queue / Action integration

暂缓。

Normalization owner 当前只消费 renderer command validation result，不读取 Queue / Action / Runtime lower-level mutable facts。

### L. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer packet error taxonomy boundary bundle implementation`

下一轮若实现，应保持 backend-agnostic value facts，只消费 `CjguiInternalRendererPacketNormalizationResult`，表达 normalization failure / degraded / blocked reason taxonomy。它不批准 backend packet、command buffer、sorting side effect、draw-call merge、GPU batching、render execution、diff / patch 或 public surface expansion。

## Downstream Status

Renderer packet error taxonomy boundary 已落地：

- [2026-05-02-p1-internal-renderer-packet-error-taxonomy-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-error-taxonomy-boundary-closure-review.md)

当前 downstream endpoint 是 `CjguiInternalRendererPacketErrorTaxonomyResult` / `cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()`。它只消费 `CjguiInternalRendererPacketNormalizationResult`，表达 failure taxonomy / degraded reason / blocked reason / taxonomy result value facts；它不是异常系统、公开错误入口、后端错误处理器、外部通知入口、绘制失败回调、backend packet、command buffer、renderer state write 或 render permission。

Renderer packet error taxonomy next-boundary decision 已完成：

- [2026-05-02-p1-renderer-packet-error-taxonomy-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-error-taxonomy-next-boundary-decision.md)

该 decision 判定 `CjguiInternalRendererPacketErrorTaxonomyResult` 已足够作为 taxonomy endpoint；下一步进入 error taxonomy manifest stabilization，而不是新增 taxonomy receipt / record / publication、diagnostics publication wrapper 或 backend readiness wrapper。

Renderer packet error taxonomy manifest 已完成：

- [2026-05-02-p1-renderer-packet-error-taxonomy-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-error-taxonomy-manifest.md)
- [2026-05-02-p1-internal-renderer-packet-error-taxonomy-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-error-taxonomy-manifest-stabilization-closure-review.md)

该 manifest 固定 `CjguiInternalRendererPacketErrorTaxonomyResult` / `cjguiInternalExecuteDefaultRendererPacketErrorTaxonomyDraft()` 为 taxonomy canonical endpoint。Same-shape Boundary Brake 生效：下一阶段不新增 taxonomy receipt / record / publication，而是进入 internal packet diagnostics boundary。

Renderer packet diagnostics boundary 已完成：

- [2026-05-02-p1-internal-renderer-packet-diagnostics-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-diagnostics-boundary-closure-review.md)

该 boundary 将 taxonomy endpoint 投影为 `CjguiInternalRendererPacketDiagnosticsResult` / `cjguiInternalExecuteDefaultRendererPacketDiagnosticsDraft()`，只表达 internal diagnostics summary / severity / evidence / result value facts。它不是 public diagnostics、外部诊断写入、observer callback、backend error handler、render failure callback、backend packet、command buffer、renderer state write 或 render permission。

Renderer packet diagnostics manifest 已完成：

- [2026-05-02-p1-renderer-packet-diagnostics-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-diagnostics-manifest.md)
- [2026-05-02-p1-internal-renderer-packet-diagnostics-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-internal-renderer-packet-diagnostics-manifest-stabilization-closure-review.md)

该 manifest 固定 diagnostics endpoint，并明确它不是 diagnostics receipt / record / publication、logging subsystem、telemetry、observer callback、public diagnostics、backend packet、command buffer、renderer state write 或 render permission。

## Downstream Post-normalization Handoff Preflight

Renderer command packet post-normalization handoff preflight 已完成：

- [2026-05-03-p1-renderer-command-packet-post-normalization-handoff-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-packet-post-normalization-handoff-preflight-decision.md)

Preflight 结论：当前没有足够 concrete downstream consumer / gate / integration evidence 来批准 post-normalization handoff implementation。现有 `runtime_renderer_handoff.cj` 只消费 `CjguiInternalRenderBatchingPacket`，canonical endpoint 是 `CjguiInternalRendererPacketHandoffReceipt`，属于旧 batching-packet handoff / backend no-render tail 起点；本轮不复用它，也不新建 handoff wrapper。

新的 next opening 是：

`P1 internal Renderer command packet ordering / material grouping hardening boundary bundle implementation`

## Downstream Ordering / Grouping Hardening Boundary

Renderer command packet ordering / material grouping hardening boundary 已落地：

- [2026-05-03-p1-internal-renderer-command-packet-ordering-material-grouping-hardening-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-packet-ordering-material-grouping-hardening-boundary-closure-review.md)

新增 owner file：

- `runtime/cjgui/src/runtime_renderer_packet_ordering.cj`

当前 downstream endpoint：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

该 endpoint 只消费 `CjguiInternalRendererPacketNormalizationResult`，表达 ordering basis / material grouping scope / hint preservation policy / no-sort-no-merge gate / hardening result value facts。它不是 normalization receipt / record / publication、post-normalization handoff wrapper、backend packet、command buffer、renderer state write、render permission、sorting side effect、draw-call merge 或 GPU batching。

新的 next opening 是：

`P1 internal Renderer command packet ordering / material grouping hardening closure / next renderer packet boundary decision`

## Downstream Ordering / Grouping Next-boundary Decision

Renderer command packet ordering / material grouping next-boundary decision 已完成：

- [2026-05-03-p1-renderer-command-packet-ordering-material-grouping-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-packet-ordering-material-grouping-next-boundary-decision.md)

Decision 结论：`CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()` 已足够作为当前 ordering / material grouping hardening endpoint。下一步应先做 manifest stabilization，固定 `runtime_renderer_packet_ordering.cj` owner / truth / canonical endpoint / stop-line，而不是新增 ordering receipt / record / publication、post-normalization handoff wrapper、backend readiness、command buffer readiness、renderer state write 或 render permission。

新的 next opening 是：

`P1 internal Renderer command packet ordering / material grouping manifest stabilization bundle implementation`

## Downstream Ordering / Grouping Manifest

Renderer command packet ordering / material grouping manifest stabilization 已完成：

- [2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md)
- [2026-05-03-p1-internal-renderer-command-packet-ordering-material-grouping-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-packet-ordering-material-grouping-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_packet_ordering.cj` owner / truth / canonical endpoint / stop-line。当前 downstream endpoint 是 `CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`；它只消费 `CjguiInternalRendererPacketNormalizationResult`，表达 ordering basis / material grouping scope / hint preservation policy / no-sort-no-merge gate / hardening result value facts。它不是 ordering receipt / record / publication、post-normalization handoff wrapper、backend readiness、command buffer readiness、renderer state write 或 render permission。

新的 next opening 是：

`P1 internal Renderer post-normalization packet integration preflight decision`

## Downstream Post-normalization Integration Preflight

Renderer post-normalization packet integration preflight 已完成：

- [2026-05-03-p1-renderer-post-normalization-packet-integration-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-post-normalization-packet-integration-preflight-decision.md)

Preflight 结论：ordering / material grouping hardening endpoint 后仍缺少足够 downstream owner / consumer / gate / integration evidence，因此不批准 runtime packet integration implementation、不复用旧 `runtime_renderer_handoff.cj` batching-packet receipt 语义、不新增 integration receipt / record / publication 或 backend readiness。

新的 next opening 是：

`P1 internal Renderer packet integration manifest / owner-truth preflight stabilization`

## Downstream Integration Owner-truth Manifest

Renderer packet integration owner-truth preflight manifest 已完成：

- [2026-05-03-p1-renderer-packet-integration-owner-truth-preflight-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-integration-owner-truth-preflight-manifest.md)
- [2026-05-03-p1-internal-renderer-packet-integration-owner-truth-preflight-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-packet-integration-owner-truth-preflight-stabilization-closure-review.md)

Manifest 结论：normalization -> ordering hardening 后仍没有足够 downstream owner / consumer / gate / integration evidence，因此不批准 runtime packet integration owner、不新增 integration receipt / record / publication、不复用旧 `runtime_renderer_handoff.cj` batching-packet receipt 语义。

新的 next opening 是：

`P1 internal Renderer packet owner-truth milestone stabilization bundle implementation`

## Downstream Packet Owner-truth Milestone

Renderer packet owner-truth milestone 已完成：

- [2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md)

Milestone 将 `CjguiInternalRendererPacketNormalizationResult` 固定为 command packet 非 diagnostics owner chain 的 normalization 层，并确认当前 canonical packet truth 已到 `CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`。它不批准 `runtime_renderer_packet_integration.cj`、post-normalization handoff wrapper、backend readiness wrapper、command buffer、render execution 或 renderer state write。

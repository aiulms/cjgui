# P1 Renderer command packet ordering / material grouping manifest

日期：2026-05-03

状态：manifest stabilization

## Purpose

本 manifest 固定 Renderer command packet ordering / material grouping hardening 的 owner / truth / canonical endpoint / stop-line，防止 `CjguiInternalRendererPacketOrderingHardeningResult` 后继续长 ordering receipt / record / publication、hardening readiness wrapper 或 post-normalization handoff wrapper。

这不是 backend manifest，也不是 renderer execution manifest。它只封账 normalized packet 后的 ordering basis、material grouping scope、hint preservation policy、no-sort-no-merge gate 与 hardening result value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_packet_ordering.cj`

Upstream facts：

- `CjguiInternalRendererPacketNormalizationResult`
- `CjguiInternalRendererNormalizedOrderingFacts`
- `CjguiInternalRendererNormalizedMaterialGroupingFacts`
- preserved `CjguiInternalRenderOrderingHint`
- preserved `CjguiInternalRenderMaterialHint`
- preserved `CjguiInternalRenderBatchKey`
- preserved `CjguiInternalRenderInvalidationHint`

Canonical endpoint：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

Current truth：

- ordering basis value facts。
- material grouping scope value facts。
- hint preservation policy value facts。
- no-sort-no-merge gate value facts。
- hardening result value facts。

该 truth 不是 ordering receipt、hardening record、publication、post-normalization handoff wrapper、backend packet、command buffer、renderer state write、render execution、draw call、GPU batching、Metal / AppKit adapter、platform resource 或 native handle。

## Current Pipeline

当前 ordering / material grouping hardening pipeline：

1. `CjguiInternalRendererPacketNormalizationResult`
2. `CjguiInternalRendererPacketOrderingBasis`
3. `CjguiInternalRendererMaterialGroupingScope`
4. `CjguiInternalRendererHintPreservationPolicy`
5. `CjguiInternalRendererNoSortNoMergeGate`
6. `CjguiInternalRendererPacketOrderingHardeningResult`

Default draft：

- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / platform resources。
- 不执行 sorting side effect。
- 不做 draw-call merge / GPU batching。
- 不写 renderer state。
- 不触发 render execution。

## Ordering / Grouping Truth

`CjguiInternalRendererPacketOrderingBasis` 固定以下 facts：

- ordering basis 只说明 normalized ordering facts 的 value basis。
- ordering hint 被保留。
- full rebuild policy 被保留。
- 不执行排序。
- 不重排 packet、command list、queue 或 renderer state。

`CjguiInternalRendererMaterialGroupingScope` 固定以下 facts：

- material grouping scope 只说明 material / batch hint 的 value scope。
- material hint 被保留。
- batch key 仍是 hint。
- grouping scope 不是真实 draw-call merge。
- grouping scope 不是真实 GPU batching。
- grouping scope 不创建 backend packet、batching engine 或 platform object。

`CjguiInternalRendererHintPreservationPolicy` 固定以下 facts：

- material hint facts 被保留。
- ordering hint facts 被保留。
- batch key hint 被保留。
- invalidation hint facts 被保留。
- policy 只说明 preservation，不改 packet。
- policy 不写 renderer state，不触发 render side effect。

`CjguiInternalRendererNoSortNoMergeGate` 固定以下 facts：

- 当前无 sorting side effect。
- 当前无 merge side effect。
- 当前无 batching side effect。
- 当前无 backend packet mutation。
- 当前无 renderer state write。
- 当前无 render permission。

`CjguiInternalRendererPacketOrderingHardeningResult` 只表示 internal ordering / material grouping hardening facts 成立。它不表示 downstream handoff、backend readiness、command buffer readiness、renderer state write permission、render permission 或 stable backend API promise。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

`CjguiInternalRendererPacketOrderingHardeningResult` 已经是当前 ordering / material grouping hardening endpoint。继续新增 ordering receipt / hardening record / publication / readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、integration 或风险证据。

因此下一阶段不得默认实现：

- ordering receipt。
- hardening record。
- hardening publication。
- hardening readiness wrapper。
- post-normalization handoff wrapper。
- backend readiness wrapper。

若未来要靠近 integration / backend readiness，必须先做 docs-only preflight，并提供明确 downstream owner / consumer / gate evidence。

## Explicit Non-Truth

本 manifest 明确当前 ordering / material grouping hardening endpoint 不是：

- ordering receipt / record / publication。
- hardening readiness wrapper。
- post-normalization handoff wrapper。
- backend packet。
- backend shell continuation。
- platform adapter。
- Metal / AppKit。
- CAMetalLayer / MTLDevice / command buffer。
- native handle / raw pointer / platform object。
- renderer state write。
- render permission。
- render execution。
- draw call。
- GPU batching。
- draw-call merge。
- sorting side effect。
- packet mutation。
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

Ordering / grouping hardening 只确认 full rebuild value facts、ordering facts、material grouping hints 与 invalidation hints 被保留并被 no-sort / no-merge gate 约束，不引入 incremental render 语义。

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
- no packet mutation。
- no renderer state write。
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

### A. P1 internal Renderer post-normalization packet integration preflight decision

选择为下一阶段 opening。

理由：

- Ordering / material grouping hardening endpoint 已封账后，下一步如果继续前进，应先 docs-only 评估是否存在 downstream owner / consumer / gate evidence。
- Preflight 可以判断 integration 是否有不可替代语义，避免直接把 hardening result 包成 receipt / publication。
- 该 preflight 仍不得实现 integration、backend readiness、command buffer、renderer state write 或 render execution。

### B. Renderer packet backend-readiness preflight

暂缓。

Backend-readiness vocabulary 仍太靠近 backend / command buffer / render permission。没有 post-normalization integration evidence 前，不应进入 backend-readiness preflight。

### C. Ordering / material grouping hardening follow-up

暂缓。

只有发现 no-sort、no-merge、hint preservation、full rebuild 或 gate facts 表达不足时才开。当前 manifest 未发现 hardening 缺口。

### D. Consolidation

暂缓。

只有发现 duplicate fields、duplicate builders、low-value helper、self-wrapping owner、manifest drift 或 build-level dead code evidence 时才开。当前没有这类 evidence。

### E. Normalized / ordering packet receipt / record / publication

拒绝。

这会直接触发 Same-shape Boundary Brake。

### F. Backend shell continuation

谨慎暂缓。

Backend shell tail 曾触发 Same-shape Boundary Brake。除非未来有新增 owner truth、consumer、gate 或 integration evidence，不应回到 shell continuation。

### G. Backend / command buffer / render execution / renderer state write

拒绝。

Ordering hardening result 不是 backend permission、command buffer readiness、render execution gate 或 renderer state write gate。

### H. Metal / AppKit / platform resource / native handle

拒绝。

当前 endpoint 不持有平台资源，不允许创建或传递 platform object、native handle 或 raw pointer。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

P1 仍固定 full DisplayList / command list rebuild。UI system、layout、text、IME、accessibility、dirty-region、diff / patch 需要独立 owner truth。

### J. Diagnostics branch reopening

暂缓。

Diagnostics branch 刚封账，本 manifest 不重开 diagnostics tail。

### K. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

最终 next opening：

`P1 internal Renderer post-normalization packet integration preflight decision`

下一轮必须 docs-only preflight。它只评估 `CjguiInternalRendererPacketOrderingHardeningResult` 后是否存在明确 downstream owner / consumer / gate evidence；不得直接实现 integration、backend readiness、command buffer、render execution、renderer state write、sorting side effect、draw-call merge、GPU batching、dirty-region、Widget / Layout / Text / IME / Accessibility 或 public surface expansion。

## Downstream Integration Preflight

Renderer post-normalization packet integration preflight 已完成：

- [2026-05-03-p1-renderer-post-normalization-packet-integration-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-post-normalization-packet-integration-preflight-decision.md)

Preflight 结论：`CjguiInternalRendererPacketOrderingHardeningResult` 后仍缺少足够 downstream owner / consumer / gate / integration evidence，不批准新建 `runtime_renderer_packet_integration.cj`、integration wrapper、integration receipt / record / publication、backend readiness、command buffer readiness、renderer state write 或 render permission。

新的 next opening 是：

`P1 internal Renderer packet integration manifest / owner-truth preflight stabilization`

## Downstream Integration Owner-truth Manifest

Renderer packet integration owner-truth preflight manifest 已完成：

- [2026-05-03-p1-renderer-packet-integration-owner-truth-preflight-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-integration-owner-truth-preflight-manifest.md)
- [2026-05-03-p1-internal-renderer-packet-integration-owner-truth-preflight-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-packet-integration-owner-truth-preflight-stabilization-closure-review.md)

Manifest 结论：当前不批准新建 `runtime_renderer_packet_integration.cj`，不批准 integration receipt / record / publication，不复用旧 `runtime_renderer_handoff.cj` batching-packet handoff receipt 语义。缺口是 downstream owner / consumer / gate / integration evidence 不足，不是 ordering / material grouping hardening 失败。

新的 next opening 是：

`P1 internal Renderer packet owner-truth milestone stabilization bundle implementation`

## Downstream Packet Owner-truth Milestone

Renderer packet owner-truth milestone 已完成：

- [2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md)

Milestone 将 `CjguiInternalRendererPacketOrderingHardeningResult` 固定为 command packet 非 diagnostics runway 的 current canonical packet truth。它确认 integration / backend-readiness evidence 暂不足，不批准 post-normalization handoff wrapper、integration receipt / record / publication、backend readiness wrapper、command buffer、render execution 或 renderer state write。

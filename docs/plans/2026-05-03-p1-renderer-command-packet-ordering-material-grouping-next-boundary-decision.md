# P1 Renderer command packet ordering / material grouping next-boundary decision

日期：2026-05-03

状态：docs-only decision

## Purpose

本 decision 评估 `CjguiInternalRendererPacketOrderingHardeningResult` 是否已经足够作为 ordering / material grouping hardening endpoint，并决定下一步是否先做 manifest stabilization，还是进入后续 renderer packet preflight。

本轮不新增 runtime code，不修改 `.cj`，不实现 backend、command buffer、render execution、renderer state write、真实排序副作用、draw-call merge、GPU batching、Metal / AppKit / platform resource、dirty-region、Widget / Layout / Text / IME / Accessibility 或 public surface expansion。

## Inputs Reviewed

- [2026-05-03-p1-internal-renderer-command-packet-ordering-material-grouping-hardening-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-packet-ordering-material-grouping-hardening-boundary-closure-review.md)
- [2026-05-02-p1-renderer-packet-normalization-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-packet-normalization-manifest.md)
- [2026-05-02-p1-renderer-command-packet-validation-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md)
- [2026-05-02-p1-render-command-material-batching-hint-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md)
- [2026-05-03-p1-renderer-diagnostics-branch-milestone-closure-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-diagnostics-branch-milestone-closure-next-boundary-decision.md)

## Current Endpoint Assessment

Current ordering / material grouping hardening endpoint:

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

Assessment:

- `CjguiInternalRendererPacketOrderingHardeningResult` 已经足够作为当前 ordering / material grouping hardening endpoint。
- It captures ordering basis, material grouping scope, hint preservation policy, no-sort-no-merge gate and hardening result facts.
- It consumes only `CjguiInternalRendererPacketNormalizationResult`.
- It does not create downstream handoff, backend readiness, command buffer readiness, renderer state write permission or render permission.
- It does not execute sorting side effects, packet mutation, draw-call merge, GPU batching, dirty-region, diff, patch or incremental render.

因此，下一步不应继续新增 ordering readiness、hardening receipt、record、publication 或 post-normalization handoff wrapper。更稳的下一阶段是先做 manifest stabilization，固定 owner / truth / canonical endpoint / stop-line。

## Candidate Comparison

### A. P1 internal Renderer command packet ordering / material grouping manifest stabilization bundle implementation

选择。

理由：

- Hardening result 已经是当前 endpoint，先固定 owner / truth / canonical endpoint / stop-line，能阻止后续继续长 ordering receipt / record / publication 同构尾巴。
- Manifest 可以把 ordering basis、material grouping scope、hint preservation policy 与 no-sort-no-merge gate 的 truth 固定下来。
- Manifest 能明确该 endpoint 不是 post-normalization handoff wrapper、backend readiness、command buffer readiness、renderer state write 或 render permission。
- 这符合 Same-shape Boundary Brake：endpoint 足够时先封账，而不是继续包壳。

### B. P1 internal Renderer post-normalization packet integration preflight decision

暂缓到 manifest 后。

只有在 manifest 后发现明确 downstream owner、consumer、gate 或 integration evidence，才应重新评估 integration preflight。当前 hardening closure 没有提供足够证据批准 integration runway。

### C. P1 internal Renderer command packet backend-readiness preflight decision

暂缓。

当前仍不能接 backend、command buffer、render execution、renderer state write、Metal / AppKit、platform resource、native handle 或 raw pointer。Backend-readiness vocabulary 容易被误读为 render permission，必须先有更强 evidence。

### D. Ordering / material grouping hardening follow-up

暂缓。

只有发现 no-sort、no-merge、hint preservation 或 full rebuild facts 表达不足时才选择。当前 closure 未暴露 hardening 缺口。

### E. Normalized packet receipt / record / publication

拒绝。

这会把 `CjguiInternalRendererPacketOrderingHardeningResult` 包成 thin wrapper，直接触发 Same-shape Boundary Brake。

### F. Backend shell continuation

谨慎暂缓。

Backend shell tail 曾触发 Same-shape Boundary Brake。除非未来能证明新增 owner truth、consumer、gate 或 integration evidence，不应回到 shell continuation。

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

Diagnostics branch 刚完成 milestone closure、audit 与 stop-line hardening，本轮不重开 diagnostics tail。

### K. Public surface expansion

拒绝。

Public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### L. Consolidation

暂缓。

只有发现明确 duplicate fields、duplicate builders、low-value helper、self-wrapping owner、manifest drift 或 dead code evidence 时才选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 endpoint sufficiency decision 生效：

- `CjguiInternalRendererPacketOrderingHardeningResult` 已经是当前 ordering / material grouping endpoint。
- 不批准 ordering receipt、hardening record、publication 或 readiness wrapper。
- 不批准把 hardening result 直接解释成 post-normalization handoff、backend readiness、command buffer readiness 或 render permission。
- 若未来靠近 integration / backend readiness，必须先 docs-only preflight，并证明 concrete owner / consumer / gate / integration evidence，不能直接实现。

## Decision

最终 decision：

- `CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()` 足够作为当前 ordering / material grouping hardening endpoint。
- 下一步先做 manifest stabilization，固定 `runtime_renderer_packet_ordering.cj` 的 owner / truth / canonical endpoint / stop-line。
- 不继续新增 ordering receipt / record / publication / readiness wrapper。
- 不直接进入 backend-readiness、command buffer、render execution、renderer state write 或 platform resource。

最终 next opening：

`P1 internal Renderer command packet ordering / material grouping manifest stabilization bundle implementation`

下一轮仍应默认 docs-only / manifest stabilization，不修改 runtime code；若后续靠近 post-normalization integration 或 backend readiness，必须先另做 docs-only preflight。

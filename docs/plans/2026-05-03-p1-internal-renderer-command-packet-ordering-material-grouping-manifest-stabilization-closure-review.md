# P1 internal Renderer command packet ordering / material grouping manifest stabilization closure review

日期：2026-05-03

状态：closed

## Scope

本轮为 docs-only manifest stabilization，新增：

- [2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-packet-ordering-material-grouping-manifest.md)

本轮没有修改 `.cj`，没有运行 build / smoke，没有实现 backend、command buffer、render execution、renderer state write、真实 sorting side effect、draw-call merge、GPU batching、Metal / AppKit / platform resource、native handle、dirty-region、Widget / Layout / Text / IME / Accessibility 或 public surface expansion。

## Manifest Conclusion

Manifest 固定：

- owner file：`runtime/cjgui/src/runtime_renderer_packet_ordering.cj`
- canonical endpoint：`CjguiInternalRendererPacketOrderingHardeningResult`
- default draft：`cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`
- current truth：ordering basis / material grouping scope / hint preservation policy / no-sort-no-merge gate / hardening result value facts

Endpoint 结论：

- `CjguiInternalRendererPacketOrderingBasis` 只说明 ordering facts 的 value basis，不执行排序。
- `CjguiInternalRendererMaterialGroupingScope` 只说明 material / batch hint 的 value scope，不做 draw-call merge / GPU batching。
- `CjguiInternalRendererHintPreservationPolicy` 只说明 material / ordering / invalidation hints 如何被保留，不改 packet。
- `CjguiInternalRendererNoSortNoMergeGate` 明确当前无 sorting side effect、无 merge side effect、无 backend packet mutation、无 renderer state write、无 render permission。
- `CjguiInternalRendererPacketOrderingHardeningResult` 只表示 internal hardening facts 成立，不代表 downstream handoff、backend readiness、command buffer readiness、renderer state write 或 render permission。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 manifest 封账生效：

- 不继续新增 ordering receipt。
- 不新增 hardening record。
- 不新增 publication。
- 不新增 hardening readiness wrapper。
- 不新增 post-normalization handoff wrapper。
- 不把 hardening result 解释成 backend readiness、command buffer readiness 或 render permission。

如果未来靠近 integration / backend readiness，必须先做 docs-only preflight，并提供明确 downstream owner / consumer / gate evidence；不能直接实现 integration、backend readiness、command buffer、render execution 或 renderer state write。

## Candidate Comparison

### A. P1 internal Renderer post-normalization packet integration preflight decision

选择为唯一 next opening。

理由：

- ordering / material grouping hardening endpoint 已封账后，若继续前进，应先评估 downstream owner / consumer / gate evidence。
- 它仍是 docs-only preflight，不直接实现 integration。
- 它能防止把 hardening result 直接包成 receipt / record / publication。

### B. Renderer packet backend-readiness preflight

暂缓。

当前仍太靠近 backend、command buffer、render permission 与 platform resource。

### C. Ordering / material grouping hardening follow-up

暂缓。

当前没有发现 no-sort、no-merge 或 hint preservation 表达不足。

### D. Consolidation

暂缓。

当前没有明确 duplicate / low-value helper / self-wrapping evidence。

### E. Normalized / ordering packet receipt / record / publication

拒绝。

这会触发 Same-shape Boundary Brake。

### F. Backend shell continuation

谨慎暂缓。

Backend shell tail 曾触发 Same-shape Brake，当前无新增 shell owner truth。

### G. Backend / command buffer / render execution / renderer state write

拒绝。

### H. Metal / AppKit / platform resource / native handle

拒绝。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### J. Diagnostics branch reopening

暂缓。

### K. Public surface expansion

拒绝。

## Verification

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过，均能找到 manifest、closure 与 next opening。
- forbidden check：通过；无 tracked `.cj` diff，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`：risk `low`，changed files `9`，changed symbols `19`，affected processes `0`。
- build / smoke：本轮 docs-only，按要求未运行。

## Next Opening

`P1 internal Renderer post-normalization packet integration preflight decision`

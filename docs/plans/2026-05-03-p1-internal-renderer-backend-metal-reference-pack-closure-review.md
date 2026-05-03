# P1 internal Renderer backend / Metal reference pack closure review

日期：2026-05-03

状态：closed

## Scope

本轮为 docs-only reference pack bundle，新增：

- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)

本轮没有修改 `.cj`，没有新建 runtime owner，没有运行 build / smoke，没有实现 backend、Metal / AppKit、CAMetalLayer、command buffer、render execution、renderer state write、platform resource owner、dirty-region、Widget / Layout / Text / IME / Accessibility 或 public surface expansion。

## Reference Pack Conclusion

Reference pack 只服务 future backend-readiness preflight。

它记录了小而硬的官方资料范围：

- Metal command buffer lifecycle。
- Metal render command encoder / render pass lifecycle。
- `CAMetalLayer` drawable lifecycle。
- AppKit `NSView` / layer-backed view / resize lifecycle。
- frame pacing / display refresh / drawable acquisition timing。
- Retina backing scale factor / color space / resize behavior。
- resource ownership：device / layer / command queue / drawable / render pass / command buffer 谁拥有、谁释放、谁只能临时借用。

Current renderer packet truth 仍是：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

Reference pack 不改变 packet truth，不批准 backend implementation，不打开 command buffer / render execution / renderer state write。

## Future Backend Preflight Checklist

下一轮 backend-readiness preflight 必须至少回答：

- backend owner 是谁。
- platform resources 是否能限制在 backend owner 内。
- command queue / command buffer 生命周期如何不反向污染 core。
- drawable acquisition 在何处发生。
- resize / scale / color space 如何进入 dehydrated facts。
- frame pacing 由谁控制。
- render packet 如何保持可丢弃、可重建、无 side effect。
- failure / rollback / no-draw path 如何表达。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮通过 reference pack 生效：

- 不是 runtime boundary。
- 不是 backend-readiness wrapper。
- 不新增 owner file / readiness / receipt / record / publication。
- 不把 official reference pack 当成 backend implementation permission。
- 后续若要进入 backend-readiness，必须另开 docs-only preflight，并引用 reference pack 的具体 evidence。

## Candidate Comparison

### A. P1 internal Renderer backend-readiness preflight decision

选择为唯一 next opening。

Reference pack 已提供 future backend-readiness preflight 的官方资料起点。下一轮仍必须 docs-only，只评估 owner / gate / lifecycle / no-render evidence。

### B. Platform resource owner preflight

暂缓。

应等 backend-readiness preflight 后再拆 platform resource owner。

### C. Command buffer lifecycle preflight

暂缓。

Command buffer lifecycle 太靠近真实 backend execution，应等 backend-readiness preflight 后再拆。

### D. Backend / Metal implementation

拒绝。

### E. Command buffer / render execution / renderer state write

拒绝。

### F. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### G. Public surface expansion

拒绝。

### H. Consolidation

暂缓，除非未来发现明确 duplicate / low-value helper / self-wrapping evidence。

## Verification

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过，检查 65 个 changed markdown files。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过，均能找到 reference pack、closure 与 next opening。
- forbidden check：通过；tracked `.cj` diff 为空，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`：risk `low`，changed files `11`，changed symbols `23`，affected processes `0`。
- build / smoke：本轮 docs-only，按要求不运行。

## Next Opening

`P1 internal Renderer backend-readiness preflight decision`

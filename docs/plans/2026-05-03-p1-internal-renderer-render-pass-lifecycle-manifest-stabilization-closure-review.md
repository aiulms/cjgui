# P1 internal Renderer render pass lifecycle manifest stabilization closure review

日期：2026-05-03

状态：manifest stabilization closure

## Scope

本轮 docs-only 固定 `runtime_renderer_render_pass.cj` 的 owner / truth / canonical endpoint / stop-line，并封账 no-render-pass lifecycle endpoint。

本轮没有修改 `.cj`，没有创建 render pass，没有创建或引用真实 `MTLRenderPassDescriptor`、`MTLRenderCommandEncoder`、drawable、texture、attachment object、command buffer、native handle 或 raw pointer；没有实现 backend / Metal / AppKit、render execution 或 renderer state write；没有运行 build / smoke；没有触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。

## Files

新增：

- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-render-pass-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-render-pass-lifecycle-manifest-stabilization-closure-review.md)

同步更新：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-03-p1-renderer-render-pass-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-preflight-decision.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-render-pass-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-next-boundary-decision.md)

## Manifest Conclusion

Owner file：

- `runtime/cjgui/src/runtime_renderer_render_pass.cj`

Canonical endpoint：

- `CjguiInternalRendererNoRenderPassReadiness`
- `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`

Current truth：

- render pass lifecycle intent value facts。
- attachment policy value facts。
- load-store policy value facts。
- clear-color policy value facts。
- no-render-pass readiness value facts。

The manifest confirms:

- `RenderPassAttachmentPolicy` 不创建 texture / attachment / descriptor。
- `RenderPassLoadStorePolicy` 不操作 attachment。
- `RenderPassClearColorPolicy` 只表达 dehydrated clear-color facts，不设置 platform descriptor。
- `NoRenderPassReadiness` 明确不是 render pass permission、backend readiness、encoder permission、render permission 或 renderer state write。
- 当前没有 `MTLRenderPassDescriptor` / encoder / drawable / texture / attachment object / command buffer / native handle / raw pointer，没有 backend / render execution。
- render pass 与 command buffer / drawable / color space / resize 的关系只作为 dehydrated lifecycle facts，不是平台对象引用。

## Same-shape Boundary Brake

本轮选择 manifest 封账。

Same-shape Boundary Brake 生效点：

- 明确拒绝 render pass receipt / record / publication。
- 明确拒绝 backend-readiness wrapper。
- 明确拒绝 encoder readiness wrapper。
- 明确拒绝 render permission wrapper。

`CjguiInternalRendererNoRenderPassReadiness` 已经是当前 no-render-pass lifecycle endpoint；继续新增 receipt / record / publication 或 readiness wrapper 会变成 thin wrapper。

若未来靠近 encoder / draw call / platform lifecycle，必须先 docs-only preflight，并提供 reference pack evidence；不能直接实现 encoder、draw call、render execution、backend object、platform object、native handle 或 raw pointer。

## Next Stage Candidate Comparison

### A. P1 internal Renderer encoder lifecycle preflight decision

推荐。

Render pass lifecycle owner / truth / canonical endpoint / stop-line 已封账后，下一步若继续前进，应只做 docs-only encoder lifecycle preflight。该 preflight 只能评估 encoder owner / lifecycle / readiness runway，不创建 encoder，不绑定 pipeline state，不绑定 resources，不发 draw calls。

### B. P1 internal Renderer draw call lifecycle preflight decision

暂缓。

Draw call lifecycle 通常等 encoder lifecycle preflight 后再开。

### C. Render pass lifecycle hardening

暂缓。

仅在发现 attachment / load-store / clear-color 表达不足时选择。当前未发现硬化缺口。

### D. Backend-readiness preflight revisit

暂缓。

等 encoder / draw call lifecycle 进一步拆清后再评估，避免 backend-readiness wrapper。

### E. Render pass / Metal implementation

拒绝。

### F. Render execution / renderer state write

拒绝。

### G. Metal / AppKit / platform resource / native handle implementation

拒绝。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### I. Public surface expansion

拒绝。

### J. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Verification

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check：通过；四处均可找到 manifest、closure 与 next opening。
- forbidden check：通过；没有 tracked `.cj` runtime code diff，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- public declaration scan：通过；仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`：risk `low`，affected processes `0`。
- `cjpm build` / smoke：本轮 docs-only，按要求未运行。

## Next Opening

唯一 next opening：

`P1 internal Renderer encoder lifecycle preflight decision`

下一轮必须 docs-only，评估 encoder owner / lifecycle / readiness runway；不得创建 encoder、render pass descriptor、command buffer、drawable、texture、attachment object、backend object、platform object、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

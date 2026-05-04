# P1 internal Renderer command buffer lifecycle manifest stabilization closure review

日期：2026-05-03

状态：manifest stabilization closure

## Scope

本轮 docs-only 固定 `runtime_renderer_command_buffer.cj` 的 owner / truth / canonical endpoint / stop-line，并封账 no-command-buffer lifecycle endpoint。

本轮没有修改 `.cj`，没有创建 command buffer，没有创建或引用 `MTLCommandBuffer`、`MTLCommandQueue`、drawable、render pass、encoder、native handle 或 raw pointer；没有实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Files

新增：

- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md)

同步更新：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-next-boundary-decision.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-preflight-decision.md)
- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)

## Manifest Conclusion

Command buffer lifecycle owner / truth / canonical endpoint / stop-line 已封账。

Owner file：

- `runtime/cjgui/src/runtime_renderer_command_buffer.cj`

Canonical endpoint：

- `CjguiInternalRendererNoCommandBufferReadiness`
- `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()`

Current truth：

- command buffer lifecycle intent value facts。
- command buffer creation policy value facts。
- command buffer commit timing guard value facts。
- command buffer single-use policy value facts。
- no-command-buffer readiness value facts。

`CommandBufferCreationPolicy` 不创建 command buffer。`CommandBufferCommitTimingGuard` 不 commit。`CommandBufferSingleUsePolicy` 只表达 future single-use / post-commit invalidation / completion-failure / rollback facts，不管理真实 buffer。

`CjguiInternalRendererNoCommandBufferReadiness` 不是 command buffer permission、backend readiness、render pass permission、encoder permission、render permission 或 renderer state write。

当前没有 `MTLCommandBuffer` / render pass / encoder / drawable / command queue / native handle / raw pointer，没有 backend / render execution。

Command buffer 与 queue / drawable / render pass / frame pacing 的关系只作为 dehydrated lifecycle facts，不是平台对象引用。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

本轮选择 manifest 封账，明确拒绝：

- command buffer receipt / record / publication。
- backend-readiness wrapper。
- render pass readiness wrapper。
- encoder readiness wrapper。
- command buffer permission wrapper。

后续若靠近 render pass / encoder / platform lifecycle，必须先做 docs-only preflight，并提供 reference pack evidence。不得直接实现 render pass、encoder、command buffer、backend object、platform object、render execution 或 renderer state write。

## Next Stage Candidate Comparison

### A. P1 internal Renderer render pass lifecycle preflight decision

推荐。

Command buffer lifecycle endpoint 已封账后，下一步可 docs-only 评估 render pass owner / lifecycle / readiness runway，但仍不创建 render pass。

### B. P1 internal Renderer encoder lifecycle preflight decision

暂缓。

Encoder lifecycle 通常等 render pass lifecycle preflight 后再开。

### C. Command buffer lifecycle hardening

暂缓。

当前未发现 creation / commit timing / single-use / failure rollback 表达不足。

### D. Backend-readiness preflight revisit

暂缓。

等 render pass / encoder lifecycle 进一步拆清后再评估。

### E. Command buffer / Metal implementation

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

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。

## Verification

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README manifest / closure / next opening reachability：通过。
- forbidden check：通过；未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。
- `.cj` runtime code diff check：通过；tracked `.cj` diff 为空。本工作区仍保留前序 untracked `runtime_renderer_command_buffer.cj` / `runtime_renderer_drawable_acquisition.cj`，本轮未修改 `.cj`。
- public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`：risk low，affected processes 0；报告 10 changed symbols / 7 changed files。
- 本轮 docs-only，未运行 `cjpm build` / smoke。

## Next Opening

唯一 next opening：

`P1 internal Renderer render pass lifecycle preflight decision`

下一轮必须 docs-only，评估 render pass owner / lifecycle / readiness runway；不得创建 render pass、encoder、command buffer、backend object、platform object、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

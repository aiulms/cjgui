# P1 internal Renderer drawable acquisition lifecycle manifest stabilization closure review

日期：2026-05-03

状态：docs-only closure

## Scope

本轮固定 `runtime_renderer_drawable_acquisition.cj` 的 owner / truth / canonical endpoint / stop-line，并封账 no-drawable lifecycle endpoint。

本轮没有修改 `.cj`，没有获取 drawable，没有创建或引用 `CAMetalLayer`、`CAMetalDrawable`、`MTLDrawable`、command buffer、render pass、native handle 或 raw pointer；没有实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Manifest Result

新增 manifest：

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)

Manifest 结论：

- owner file：`runtime/cjgui/src/runtime_renderer_drawable_acquisition.cj`
- canonical endpoint：`CjguiInternalRendererNoDrawableReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`
- current truth：drawable lifecycle intent / drawable availability policy / acquisition timing guard / presentation ownership policy / no-drawable readiness value facts

`DrawableAvailabilityPolicy` 不调用或持有 drawable。`DrawableAcquisitionTimingGuard` 不获取 drawable。`PresentationOwnershipPolicy` 不 present drawable。No-drawable readiness 明确不是 drawable permission、backend readiness、command buffer permission、render permission 或 renderer state write。

当前没有 `CAMetalLayer` / `CAMetalDrawable` / `MTLDrawable` / command buffer / render pass / encoder / native handle / raw pointer，没有 backend / render execution。Drawable acquisition 与 command queue / layer / frame pacing / resize 的关系只作为 dehydrated lifecycle facts，不是平台对象引用。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

本轮选择 manifest 封账，明确拒绝 drawable receipt / record / publication、backend-readiness wrapper、command buffer readiness wrapper 与 render pass readiness wrapper。

若未来靠近 command buffer / render pass / platform lifecycle，必须先 docs-only preflight，并提供 reference pack 证据。不得直接实现 command buffer、render pass、encoder、backend / Metal / AppKit implementation、render execution 或 renderer state write。

## Next Stage Candidate Comparison

### A. P1 internal Renderer command buffer lifecycle preflight decision

推荐。

Drawable lifecycle endpoint 已封账后，下一步可以 docs-only 评估 command buffer owner / lifecycle / readiness runway，但仍不创建 command buffer。

### B. P1 internal Renderer render pass lifecycle preflight decision

暂缓。

通常等 command buffer lifecycle preflight 后再开。

### C. Drawable lifecycle hardening

暂缓。

仅在发现 availability / timing / presentation ownership 表达不足时选。当前没有发现缺口。

### D. Backend-readiness preflight revisit

暂缓。

等 command buffer / render pass lifecycle 进一步拆清后再评估。

### E. Drawable / Metal implementation

拒绝。

### F. Command buffer / render execution / renderer state write

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
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过；均可找到 manifest、closure 与 next opening。
- forbidden check：通过；无 tracked `.cj` runtime code diff，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。工作区仍保留上一轮已有的 untracked `runtime/cjgui/src/runtime_renderer_drawable_acquisition.cj`，本轮未修改。
- public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`：risk low，affected processes 0。
- 本轮 docs-only，未运行 `cjpm build` / smoke。

## Next Opening

唯一 next opening：

`P1 internal Renderer command buffer lifecycle preflight decision`

下一轮必须 docs-only，不得创建 command buffer，不得创建 render pass / encoder，不得获取 drawable，不得接 backend / Metal / AppKit implementation，不得 render，不得写 renderer state。

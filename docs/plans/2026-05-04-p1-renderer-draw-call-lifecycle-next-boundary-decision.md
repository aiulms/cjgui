# P1 Renderer draw call lifecycle next-boundary decision

日期：2026-05-04

状态：next-boundary decision

## Date Prefix

本 decision 使用 `2026-05-04` 前缀，因为当前日期是 2026-05-04，且本轮是 draw call lifecycle value boundary closure 之后的新 docs-only decision。

上游材料继续引用 2026-05-03 renderer lifecycle 文档串，但本轮不沿用 `2026-05-03` 文件名前缀。

## Scope

本轮 docs-only 评估 `CjguiInternalRendererNoDrawCallReadiness` 是否已经足够作为当前 no-draw-call lifecycle endpoint，并决定下一步是否先做 manifest stabilization。

本轮不修改 `.cj`，不执行 draw call，不创建或引用 `MTLRenderCommandEncoder`、pipeline state、vertex buffer、index buffer、texture、command buffer、native handle 或 raw pointer；不实现 backend / Metal / AppKit、render execution 或 renderer state write；不运行 build / smoke。

## Read Inputs

- [2026-05-03-p1-internal-renderer-draw-call-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-draw-call-lifecycle-value-boundary-closure-review.md)
- [2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md)
- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Endpoint Assessment

`CjguiInternalRendererNoDrawCallReadiness` 已经足够作为当前 no-draw-call lifecycle endpoint。

Current canonical endpoint：

- `CjguiInternalRendererNoDrawCallReadiness`
- `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`

Current owner：

- `runtime/cjgui/src/runtime_renderer_draw_call.cj`

Current truth：

- draw call lifecycle intent value facts。
- draw command shape policy value facts。
- geometry source policy value facts。
- draw sequencing guard value facts。
- no-draw-call readiness value facts。

当前 endpoint 不是真实 draw call permission、encoder call permission、pipeline binding permission、resource binding permission、GPU submission permission、backend readiness、render execution gate 或 renderer state write。

## Candidate Comparison

### A. P1 internal Renderer draw call lifecycle manifest stabilization bundle implementation

推荐。

`CjguiInternalRendererNoDrawCallReadiness` 已足够封住当前 no-draw-call endpoint；下一步应固定 `runtime_renderer_draw_call.cj` 的 owner / truth / canonical endpoint / stop-line，而不是继续朝 pipeline state 或 render execution 靠近。

### B. Pipeline state lifecycle preflight

暂缓。

Pipeline state lifecycle 更靠近 shader / pipeline object / resource layout / backend-local binding truth。应等 draw call lifecycle manifest 封账后，再用 docs-only preflight 判断是否有足够 owner / lifecycle / no-pipeline-state evidence。

### C. Render execution preflight

暂缓。

Render execution 必须等 draw call / pipeline state lifecycle 进一步拆清后再评估。当前仍禁止 GPU submission、draw call execution、renderer state write 与 backend implementation。

### D. Draw call lifecycle hardening

暂缓。

仅在发现 draw command shape / geometry source / sequencing 表达不足时选择。当前 closure 没有显示 hardening gap。

### E. Draw-call receipt / record / publication

拒绝。

这会把 `CjguiInternalRendererNoDrawCallReadiness` 重新包装成 thin wrapper，缺少新的 owner truth / consumer / lifecycle evidence。

### F. Backend-readiness wrapper

拒绝。

Backend-readiness 当前证据不足且极易退化为 packet / draw-call endpoint thin wrapper。

### G. Draw call / Metal implementation

拒绝。

### H. Render execution / renderer state write

拒绝。

### I. Metal / AppKit / platform resource / native handle implementation

拒绝。

### J. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### K. Public surface expansion

拒绝。

public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

`CjguiInternalRendererNoDrawCallReadiness` 已经是当前 no-draw-call endpoint；本轮不批准：

- draw-call receipt / record / publication。
- backend-readiness wrapper。
- render-execution readiness wrapper。
- pipeline-state readiness wrapper。
- draw permission wrapper。

如果未来靠近 pipeline state / render execution / platform lifecycle，必须先做 docs-only preflight，并提供 reference pack 证据；不能直接实现 draw call、pipeline binding、GPU submission、backend / Metal / AppKit implementation 或 renderer state write。

## Decision

选择：

`P1 internal Renderer draw call lifecycle manifest stabilization bundle implementation`

理由：

- 当前 no-draw-call endpoint 已足够。
- 当前主要需要固定 owner / truth / canonical endpoint / stop-line。
- 继续新增 draw-call receipt / record / publication 或 backend-readiness wrapper 会触发 thin-wrapper 风险。
- Pipeline state / render execution 仍过早，应等 manifest stabilization 后再评估。

唯一 next opening：

`P1 internal Renderer draw call lifecycle manifest stabilization bundle implementation`

下一轮必须 docs-only，不得执行 draw call，不得调用 encoder，不得绑定 pipeline state / buffer / texture，不得创建 command buffer / render pass / drawable / platform object，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Draw Call Lifecycle Manifest

Renderer draw call lifecycle manifest stabilization 已完成：

- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 封账 `runtime_renderer_draw_call.cj` owner / truth / canonical endpoint / stop-line。唯一 next opening 改为 `P1 internal Renderer pipeline state lifecycle preflight decision`，仍只能 docs-only，不批准 pipeline state creation、pipeline binding、draw call execution、render execution 或 backend implementation。

## Validation

本轮 docs-only 验证结果：

- `git diff --check`: passed。
- Markdown absolute link missing target check: passed。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check: passed。
- Forbidden tracked diff check: passed；没有 tracked `.cj` runtime code diff，未触碰 `runtime_state.cj`、`cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`。工作区仍保留前序实现轮产生的 untracked renderer owner `.cj` files，本轮未修改它们。
- Public declaration scan: passed；仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: risk `low`，affected processes `0`。

本轮按要求未运行 `cjpm build` / smoke。

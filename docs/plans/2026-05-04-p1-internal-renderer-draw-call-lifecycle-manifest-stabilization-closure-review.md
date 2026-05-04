# P1 internal Renderer draw call lifecycle manifest stabilization closure review

日期：2026-05-04

本轮执行 `P1 internal Renderer draw call lifecycle manifest stabilization bundle implementation`。它是 docs-only manifest stabilization，不是 draw call implementation、pipeline state implementation、render execution implementation、backend implementation、Metal / AppKit implementation 或 renderer state write runway。

## Scope

新增 docs：

- `docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md`
- `docs/plans/2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md`

同步文档：

- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md`
- `docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md`
- `docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-next-boundary-decision.md`

未触碰：

- `.cj` runtime code
- `runtime_state.cj`
- `runtime/cjgui/cjpm.toml`
- smoke tracked source / harness / native bridge / entry
- `AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`

本轮按要求未运行 `cjpm build` / smoke。

## Manifest Conclusion

Draw call lifecycle owner / truth / canonical endpoint / stop-line 已封账：

- owner file：`runtime/cjgui/src/runtime_renderer_draw_call.cj`
- canonical endpoint：`CjguiInternalRendererNoDrawCallReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`
- current truth：draw call lifecycle intent / draw command shape policy / geometry source policy / draw sequencing guard / no-draw-call readiness value facts

`CjguiInternalRendererNoDrawCallReadiness` 是当前 no-draw-call lifecycle endpoint。它不是 draw-call permission、pipeline binding permission、backend readiness、render execution permission 或 renderer state write。

当前没有 draw call、encoder call、pipeline binding、buffer binding、texture binding、GPU submission、native handle 或 raw pointer，没有 backend / render execution。Primitive kind / vertex-index source / instance count / draw order relation / material grouping hints 只作为 dehydrated lifecycle facts。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 manifest 封账生效。

本轮明确拒绝：

- draw-call receipt / record / publication。
- backend-readiness wrapper。
- render-execution readiness wrapper。
- pipeline-state readiness wrapper。
- draw permission wrapper。
- render permission wrapper。

如果未来靠近 pipeline state / render execution / platform lifecycle，必须先 docs-only preflight，并提供 reference pack evidence。不得直接创建 pipeline state、绑定 pipeline、调用 encoder、发 draw call、创建 platform object、进入 render execution 或写 renderer state。

## Next Stage Candidate Comparison

### A. P1 internal Renderer pipeline state lifecycle preflight decision

推荐。

Draw call lifecycle endpoint 已封账，下一步若继续靠近 backend lifecycle，应先 docs-only 评估 pipeline state owner / lifecycle / readiness runway。该 preflight 仍不创建 pipeline state、不绑定 pipeline、不调用 encoder、不发 draw call、不接 backend。

### B. P1 internal Renderer render execution preflight decision

暂缓。

Render execution 通常等 pipeline state lifecycle preflight 后再开，避免把 no-draw-call endpoint 包成 render-execution readiness wrapper。

### C. Draw call lifecycle hardening

暂缓。

当前 draw command shape / geometry source / sequencing 表达足够，未发现硬化缺口。

### D. Backend-readiness preflight revisit

暂缓。

等 pipeline state / render execution lifecycle 进一步拆清后再评估，避免 backend-readiness wrapper。

### E. Draw call / Metal implementation

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

暂缓，仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。

## Validation

Validation results:

- `git diff --check`: passed。
- Markdown absolute link missing target check: passed。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check: passed。
- Forbidden tracked diff check: passed；没有 tracked `.cj` runtime code diff，未触碰 `runtime_state.cj`、`cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`。工作区仍保留前序实现轮产生的 untracked renderer owner `.cj` files，本轮未修改它们。
- Public declaration scan: passed；仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: risk `low`，affected processes `0`，changed indexed files `7`。

本轮按要求未运行 `cjpm build` / smoke。

## Next Opening

唯一 next opening：

`P1 internal Renderer pipeline state lifecycle preflight decision`

下一轮必须 docs-only，评估 pipeline state owner / lifecycle / readiness runway；不得直接创建 pipeline state，不得绑定 pipeline，不得调用 encoder，不得执行 draw call，不得创建 command buffer / render pass / drawable / platform object，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

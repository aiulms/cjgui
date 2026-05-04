# P1 internal Renderer pipeline state lifecycle manifest stabilization closure review

日期：2026-05-04

本轮执行 `P1 internal Renderer pipeline state lifecycle manifest stabilization bundle implementation`。它是 docs-only manifest stabilization，不是 pipeline state implementation、shader / library implementation、render execution implementation、backend implementation、Metal / AppKit implementation、draw call implementation 或 renderer state write runway。

## Scope

新增 docs：

- `docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md`
- `docs/plans/2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md`

同步文档：

- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-next-boundary-decision.md`
- `docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md`
- `docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md`

未触碰：

- `.cj` runtime code
- `runtime_state.cj`
- `runtime/cjgui/cjpm.toml`
- smoke tracked source / harness / native bridge / entry
- `AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`

本轮按要求未运行 `cjpm build` / smoke。

## Manifest Conclusion

Pipeline state lifecycle owner / truth / canonical endpoint / stop-line 已封账：

- owner file：`runtime/cjgui/src/runtime_renderer_pipeline_state.cj`
- canonical endpoint：`CjguiInternalRendererNoPipelineStateReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`
- current truth：pipeline state lifecycle intent / shader function policy / pipeline descriptor policy / pipeline compatibility guard / no-pipeline-state readiness value facts

`CjguiInternalRendererNoPipelineStateReadiness` 是当前 no-pipeline-state lifecycle endpoint。它不是 pipeline-state permission、shader loading permission、backend readiness、render execution permission 或 renderer state write。

当前没有 `MTLRenderPipelineState`、`MTLRenderPipelineDescriptor`、shader function、shader library、encoder binding、buffer / texture binding、native handle 或 raw pointer，没有 backend / render execution。Material key / render pass / encoder / draw call compatibility 只作为 dehydrated lifecycle facts。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 manifest 封账生效。

本轮明确拒绝：

- pipeline-state receipt / record / publication。
- backend-readiness wrapper。
- render-execution readiness wrapper。
- shader-library readiness wrapper。
- pipeline compile / cache wrapper。
- pipeline-state permission wrapper。
- render permission wrapper。

如果未来靠近 render execution / shader library / platform lifecycle，必须先 docs-only preflight，并提供 reference pack evidence。不得直接创建 pipeline state、加载 shader library / function、创建 descriptor、绑定 pipeline、调用 encoder、绑定 buffer / texture、发 draw call、创建 platform object、进入 render execution 或写 renderer state。

## Next Stage Candidate Comparison

### A. P1 internal Renderer render execution preflight decision

推荐。

Pipeline state lifecycle endpoint 已封账，下一步若继续靠近 backend lifecycle，应先 docs-only 评估 render execution owner / lifecycle / readiness runway。该 preflight 仍不执行 render、不提交 GPU work、不写 renderer state、不接 backend。

### B. P1 internal Renderer shader/library lifecycle preflight decision

暂缓。

当前 shader function policy 只表达 shader role placeholder / future shader selection facts，未发现 shader owner truth 缺口。

### C. Pipeline state lifecycle hardening

暂缓。

当前 shader role / descriptor policy / compatibility 表达足够，未发现硬化缺口。

### D. Backend-readiness preflight revisit

暂缓。

等 render execution lifecycle 进一步拆清后再评估，避免 backend-readiness wrapper。

### E. Pipeline state / Metal implementation

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
- Forbidden tracked diff check: passed；没有 tracked `.cj` runtime code diff，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`。工作区仍保留前序实现轮产生的 untracked renderer owner `.cj` files，本轮未修改它们。
- Public declaration scan: passed；仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: risk `low`，affected processes `[]`，affected count `0`。

本轮按要求未运行 `cjpm build` / smoke。

## Next Opening

唯一 next opening：

`P1 internal Renderer render execution preflight decision`

下一轮必须 docs-only，评估 render execution owner / lifecycle / readiness runway；不得执行 render，不得提交 GPU work，不得创建 pipeline state / shader library / descriptor / encoder / buffer / texture / command buffer / render pass / drawable / platform object，不得实现 backend / Metal / AppKit 或 renderer state write。

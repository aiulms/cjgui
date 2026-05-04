# P1 internal Renderer encoder lifecycle manifest stabilization closure review

日期：2026-05-03

本轮执行 `P1 internal Renderer encoder lifecycle manifest stabilization bundle implementation`。它是 docs-only manifest stabilization，不是 encoder implementation、draw call implementation、pipeline state implementation、backend implementation、Metal / AppKit implementation、render execution 或 renderer state write runway。

## Scope

新增 docs：

- `docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md`
- `docs/plans/2026-05-03-p1-internal-renderer-encoder-lifecycle-manifest-stabilization-closure-review.md`

同步文档：

- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-preflight-decision.md`
- `docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md`

未触碰：

- `.cj` runtime code
- `runtime_state.cj`
- `runtime/cjgui/cjpm.toml`
- smoke tracked source / harness / native bridge / entry
- `AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`

本轮按要求未运行 `cjpm build` / smoke。

## Manifest Conclusion

Encoder lifecycle owner / truth / canonical endpoint / stop-line 已封账：

- owner file：`runtime/cjgui/src/runtime_renderer_encoder.cj`
- canonical endpoint：`CjguiInternalRendererNoEncoderReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`
- current truth：encoder lifecycle intent / encoding scope policy / pipeline binding guard / end-encoding policy / no-encoder readiness value facts

`CjguiInternalRendererNoEncoderReadiness` 是当前 no-encoder lifecycle endpoint。它不是 encoder permission、pipeline binding permission、draw-call permission、backend readiness、render permission 或 renderer state write。

当前没有 `MTLRenderCommandEncoder`、pipeline state、draw call、render pass descriptor、command buffer、native handle 或 raw pointer，没有 backend / render execution。Viewport / scissor placeholder 只作为 dehydrated lifecycle facts，不设置 platform state。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 manifest 封账生效。

本轮明确拒绝：

- encoder receipt / record / publication。
- backend-readiness wrapper。
- draw-call readiness wrapper。
- pipeline-state readiness wrapper。
- encoder permission wrapper。
- render permission wrapper。

如果未来靠近 draw call / pipeline state / platform lifecycle，必须先 docs-only preflight，并提供 reference pack evidence。不得直接创建 encoder、绑定 pipeline、发 draw call、创建 platform object、进入 render execution 或写 renderer state。

## Next Stage Candidate Comparison

### A. P1 internal Renderer draw call lifecycle preflight decision

推荐。

Encoder lifecycle endpoint 已封账，下一步若继续靠近 backend lifecycle，应先 docs-only 评估 draw call owner / lifecycle / readiness runway。该 preflight 仍不执行 draw call、不绑定 pipeline state、不创建 encoder、不接 backend。

### B. P1 internal Renderer pipeline state lifecycle preflight decision

暂缓。

Pipeline state lifecycle 通常等 draw call lifecycle preflight 后再拆，避免把 no-encoder endpoint包成 pipeline-state readiness wrapper。

### C. Encoder lifecycle hardening

暂缓。

当前 encoding scope / pipeline binding guard / end-encoding 表达足够，未发现硬化缺口。

### D. Backend-readiness preflight revisit

暂缓。

等 draw call / pipeline state lifecycle 进一步拆清后再评估，避免 backend-readiness wrapper。

### E. Encoder / Metal implementation

拒绝。

### F. Render execution / renderer state write / draw call implementation

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
- GitNexus `detect_changes(scope=unstaged)`: initial `repo="cangjie"` lookup was unavailable in this tool session, rerun with repo path `/Users/jiangxuanyang/Desktop/cangjie`; risk `low`, affected processes `0`, changed indexed files `7`。

## Next Opening

唯一 next opening：

`P1 internal Renderer draw call lifecycle preflight decision`

下一轮必须 docs-only，评估 draw call owner / lifecycle / readiness runway；不得直接执行 draw call，不得绑定 pipeline state，不得创建 encoder / command buffer / render pass / drawable / platform object，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

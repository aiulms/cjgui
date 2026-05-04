# P1 Renderer encoder lifecycle next-boundary decision

日期：2026-05-03

状态：docs-only next-boundary decision

## Scope

本轮 docs-only 评估 `CjguiInternalRendererNoEncoderReadiness` 是否已经足够作为当前 no-encoder lifecycle endpoint，并决定下一步是否先做 manifest stabilization，还是进入 draw call lifecycle preflight。

本轮不修改 `.cj`，不创建 encoder，不创建或引用 `MTLRenderCommandEncoder`、pipeline state、command buffer、render pass、drawable、texture、native handle 或 raw pointer；不实现 backend / Metal / AppKit、render execution、renderer state write 或 draw call；不运行 build / smoke。

## Read Inputs

- [2026-05-03-p1-internal-renderer-encoder-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-encoder-lifecycle-value-boundary-closure-review.md)
- [2026-05-03-p1-renderer-encoder-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-preflight-decision.md)
- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Endpoint Assessment

`CjguiInternalRendererNoEncoderReadiness` is sufficient as the current no-encoder lifecycle endpoint.

Current canonical endpoint:

- `CjguiInternalRendererNoEncoderReadiness`
- `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`

Current owner:

- `runtime/cjgui/src/runtime_renderer_encoder.cj`

Current truth:

- encoder lifecycle intent value facts。
- encoding scope policy value facts。
- pipeline binding guard value facts。
- end-encoding policy value facts。
- no-encoder readiness value facts。

The endpoint already records the facts needed to close the current value boundary:

- no encoder object。
- no pipeline state object。
- no draw command。
- no render pass descriptor object。
- no command buffer object。
- no native resource token or pointer-like resource。
- no backend permission。
- no render permission。
- no renderer state mutation。

This is enough for the current no-encoder endpoint. The next safer step is to stabilize owner / truth / canonical endpoint / stop-line in a manifest before considering draw call lifecycle preflight.

## Candidate Comparison

### A. P1 internal Renderer encoder lifecycle manifest stabilization bundle implementation

推荐。

`CjguiInternalRendererNoEncoderReadiness` 已经足够作为当前 no-encoder lifecycle endpoint。下一步应先固定 `runtime_renderer_encoder.cj` 的 owner / truth / canonical endpoint / stop-line，避免 draw call / pipeline state / backend-readiness 在 endpoint 尚未 manifest 封账前被误读为可实现。

### B. Draw call lifecycle preflight

暂缓，等 encoder manifest 后再评估；仍只能 docs-only。

Draw call lifecycle 更靠近 pipeline state、resource binding、draw command sequencing、GPU submission 与 render execution。如果现在直接进入 draw call preflight，容易把 no-encoder endpoint 包成 draw-call readiness wrapper。需要先让 encoder manifest 明确 no-encoder endpoint 不是 draw permission。

### C. Pipeline state lifecycle preflight

暂缓。

Pipeline state lifecycle 通常应等 draw call / encoder truth 后再拆。当前不应直接靠近 pipeline object creation、shader state、resource binding implementation 或 backend readiness。

### D. Encoder lifecycle hardening

暂缓。

只有在发现 encoding scope / pipeline binding guard / end-encoding 表达不足时才选择。当前 closure 已覆盖 command sequencing、viewport / scissor placeholder、pipeline/resource binding preconditions、end-encoding boundary、post-encoding invalidation 与 failure rollback facts，未发现硬化缺口。

### E. Encoder receipt / record / publication

拒绝。

这会把 `CjguiInternalRendererNoEncoderReadiness` 换名包装成 thin wrapper，缺少新的 owner truth。

### F. Backend-readiness wrapper

拒绝。

Backend-readiness evidence 仍不足且容易变成 packet / encoder endpoint 的 thin wrapper。未来必须先通过 docs-only preflight，并提供 concrete owner / platform lifecycle / resource confinement evidence。

### G. Encoder / Metal implementation

拒绝。

### H. Render execution / renderer state write / draw call

拒绝。

### I. Metal / AppKit / platform resource / native handle implementation

拒绝。

### J. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### K. Public surface expansion

拒绝。

Public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

`CjguiInternalRendererNoEncoderReadiness` 已经是当前 no-encoder endpoint。它不是：

- encoder receipt / record / publication。
- backend-readiness wrapper。
- draw-call readiness wrapper。
- pipeline state lifecycle wrapper。
- render permission wrapper。

不批准新增 encoder receipt / record / publication、backend-readiness wrapper 或 draw-call readiness wrapper。

如果未来靠近 draw call / pipeline state / platform lifecycle，必须先 docs-only preflight，不能直接实现。未来 preflight 必须明确 draw command sequencing、pipeline state/resource binding、failure rollback 与 backend-local ownership evidence，且继续禁止真实 encoder、pipeline state、draw call、backend object、platform object、render execution 或 renderer state write。

## Decision

选择：

`P1 internal Renderer encoder lifecycle manifest stabilization bundle implementation`

唯一 next opening：

`P1 internal Renderer encoder lifecycle manifest stabilization bundle implementation`

下一轮必须 docs-only，固定 `runtime_renderer_encoder.cj` owner / truth / canonical endpoint / stop-line，并封账 no-encoder lifecycle endpoint。不得创建 encoder，不得绑定 pipeline state，不得发 draw call，不得创建 command buffer / render pass / drawable / platform object，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Validation

本轮 docs-only 验证结果：

- `git diff --check`: passed。
- Markdown absolute link missing target check: passed。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check: passed。
- Forbidden tracked diff check: passed；没有 tracked `.cj` runtime code diff，未触碰 `runtime_state.cj`、`cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`。工作区仍保留前序实现轮产生的 untracked renderer owner `.cj` files，本轮未修改它们。
- Public declaration scan: passed；仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`: risk `low`，affected processes `0`。

本轮按要求未运行 `cjpm build` / smoke。

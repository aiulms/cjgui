# P1 Renderer render pass lifecycle next-boundary decision

日期：2026-05-03

状态：next-boundary decision

## Scope

本轮 docs-only 评估 `CjguiInternalRendererNoRenderPassReadiness` 是否已经足够作为当前 no-render-pass lifecycle endpoint，并决定下一步是否先做 manifest stabilization，还是进入 encoder lifecycle preflight。

本轮不修改 `.cj`，不创建 render pass，不创建或引用 `MTLRenderPassDescriptor`、`MTLRenderCommandEncoder`、drawable、texture、attachment object、command buffer、native handle 或 raw pointer；不实现 backend / Metal / AppKit、render execution 或 renderer state write；不运行 build / smoke。

## Read Inputs

- [2026-05-03-p1-internal-renderer-render-pass-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-render-pass-lifecycle-value-boundary-closure-review.md)
- [2026-05-03-p1-renderer-render-pass-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-preflight-decision.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Endpoint Assessment

`CjguiInternalRendererNoRenderPassReadiness` 已足够作为当前 no-render-pass lifecycle endpoint。

Canonical owner / endpoint：

- Owner file：`runtime/cjgui/src/runtime_renderer_render_pass.cj`
- Canonical endpoint：`CjguiInternalRendererNoRenderPassReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`

当前 truth 只包括：

- render pass lifecycle intent value facts。
- attachment policy value facts。
- load-store policy value facts。
- clear-color policy value facts。
- no-render-pass readiness value facts。

它已经覆盖当前 runway 需要的 attachment role / target relation、load / store intent、dehydrated clear-color、drawable-size / color-space / resize relation、failure / no-draw fallback 与 no-render-pass stop-line。没有证据表明需要立即做 hardening，也没有证据表明可以跳过 manifest stabilization 直接进入 encoder lifecycle preflight。

## Decision

选择 A：`P1 internal Renderer render pass lifecycle manifest stabilization bundle implementation`。

理由：

- 当前 endpoint 已经完整表达 no-render-pass lifecycle value facts。
- 下一步最稳妥的是固定 `runtime_renderer_render_pass.cj` 的 owner / truth / canonical endpoint / stop-line。
- Encoder lifecycle 更靠近 command encoding、resource binding、pipeline state 与 draw-call path，必须等 render pass manifest 封账后再 docs-only preflight。
- 当前仍无 evidence 支持 backend-readiness wrapper、render pass receipt / record / publication 或真实 Metal implementation。

## Candidate Comparison

### A. P1 internal Renderer render pass lifecycle manifest stabilization bundle implementation

推荐。

固定 render pass lifecycle owner / truth / canonical endpoint / stop-line，封账当前 no-render-pass endpoint。下一轮仍 docs-only，不创建 descriptor、encoder、drawable、texture、attachment object、command buffer、backend object、platform object、native handle 或 raw pointer。

### B. Encoder lifecycle preflight

暂缓，等 render pass manifest 后再评估；仍只能 docs-only。

Encoder lifecycle 必须建立在已封账的 render pass owner truth 之上，否则容易把 no-render-pass endpoint 直接包成 encoder readiness wrapper。

### C. Draw call lifecycle preflight

暂缓，必须等 encoder lifecycle 后。

Draw call lifecycle 更靠近 pipeline state、resource binding、draw command 与 GPU submission，不应越过 encoder lifecycle。

### D. Render pass lifecycle hardening

暂缓。

仅在发现 attachment / load-store / clear-color 表达不足时选择。当前 closure 已覆盖 attachment role / target relation、load / store intent、dehydrated clear-color、drawable-size / color-space / resize relation 与 no-draw fallback。

### E. Render pass receipt / record / publication

拒绝。

Thin wrapper 风险高，会把 current endpoint 换名包装成 receipt / record / publication，缺少新的 owner truth。

### F. Backend-readiness wrapper

拒绝。

当前 backend-readiness evidence 仍不足，且 wrapper 形态容易绕过 platform resource / command queue / drawable / command buffer / render pass lifecycle stop-line。

### G. Render pass / Metal implementation

拒绝。

### H. Render execution / renderer state write

拒绝。

### I. Metal / AppKit / platform resource / native handle implementation

拒绝。

### J. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### K. Public surface expansion

拒绝。

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

`CjguiInternalRendererNoRenderPassReadiness` 已经是当前 no-render-pass endpoint。

本轮不批准：

- render pass receipt / record / publication。
- backend-readiness wrapper。
- encoder readiness wrapper。
- render permission wrapper。
- render pass / Metal implementation。

若未来靠近 encoder / draw call / platform lifecycle，必须先 docs-only preflight，不能直接实现 encoder、draw call、render execution、backend object、platform object、native handle 或 raw pointer。

## Stop-line

继续禁止：

- no `.cj` modifications in this decision round。
- no render pass creation。
- no `MTLRenderPassDescriptor` creation or reference as runtime type。
- no `MTLRenderCommandEncoder` creation or reference as runtime type。
- no drawable / texture / attachment object ownership。
- no command buffer creation or permission。
- no backend / Metal / AppKit implementation。
- no render execution / draw call。
- no renderer state write。
- no native handle / raw pointer / platform object。
- no backend-readiness wrapper。
- no encoder readiness wrapper。
- no render pass receipt / record / publication。
- no dirty-region / Widget / Layout / Text / IME / Accessibility。
- no public surface expansion。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 decision 不批准第二个 public symbol、不修改 Bool-only signature、不新增 public C ABI。

## Next Opening

唯一 next opening：

`P1 internal Renderer render pass lifecycle manifest stabilization bundle implementation`

下一轮必须 docs-only，固定 `runtime/cjgui/src/runtime_renderer_render_pass.cj` 的 owner / truth / canonical endpoint / stop-line；不得创建 render pass descriptor、encoder、drawable、texture、attachment object、command buffer、backend object、platform object、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Render Pass Lifecycle Manifest

Renderer render pass lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-render-pass-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-render-pass-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_render_pass.cj` owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoRenderPassReadiness`。下一步唯一 opening 是 docs-only `P1 internal Renderer encoder lifecycle preflight decision`。

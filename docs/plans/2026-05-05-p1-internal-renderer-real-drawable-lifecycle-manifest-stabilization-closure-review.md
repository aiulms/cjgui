# P1 internal Renderer real drawable lifecycle manifest stabilization closure review

日期：2026-05-05

状态：closure review

## Scope

本轮执行 `P1 internal Renderer real drawable lifecycle manifest stabilization bundle implementation`。

目标是固定 `runtime_renderer_real_drawable.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-real-drawable endpoint。

本轮保持 docs-only：没有修改 `.cj`，没有运行 `cjpm build` / smoke，没有触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，没有获取 drawable，没有调用 `nextDrawable`，没有创建 `CAMetalDrawable` / `MTLDrawable`，没有创建 command buffer / render pass / encoder / pipeline state，没有调用 Metal / AppKit / Objective-C / FFI，没有 present / commit / submit GPU work，没有执行 render，没有写 renderer state，没有扩 public API / C ABI。

## Inputs Read

- [runtime_renderer_real_drawable.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_drawable.cj)
- [2026-05-05-p1-renderer-real-drawable-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-next-boundary-decision.md)
- [2026-05-05-p1-internal-renderer-real-drawable-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-lifecycle-value-boundary-closure-review.md)
- [2026-05-05-p1-renderer-real-drawable-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-preflight-decision.md)
- [2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)

## Docs Added

- [2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [2026-05-05-p1-internal-renderer-real-drawable-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-lifecycle-manifest-stabilization-closure-review.md)

## Manifest Conclusion

Owner file：

- `runtime/cjgui/src/runtime_renderer_real_drawable.cj`

Canonical endpoint：

- `CjguiInternalRendererNoRealDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()`

Runtime input：

- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`

Current truth：

- real drawable lifecycle intent value facts.
- drawable availability policy value facts.
- drawable acquisition guard value facts.
- presentation ownership policy value facts.
- no-real-drawable-readiness value facts.

`RealDrawableAvailabilityPolicy` does not query a real drawable pool. It only records future availability, unavailable fallback and resize / scale / color relation facts.

`RealDrawableAcquisitionGuard` does not call `nextDrawable` and does not acquire drawable. It only records late-bound acquisition constraints, unavailable / timeout fallback and no borrowed resource facts.

`RealDrawablePresentationOwnershipPolicy` does not present drawable and does not submit command buffer. It only records future presentation ownership, release expectation and no-present facts.

`NoRealDrawableReadiness` is not drawable permission, command buffer permission, GPU submission permission, backend implementation permission, render permission, renderer state write permission, diagnostics permission, public API permission or C ABI permission.

## Same-shape Boundary Brake

This manifest closes the no-real-drawable endpoint and prevents another tail wrapper.

Rejected next shapes:

- real drawable receipt / record / publication.
- drawable-ready permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.
- public API / C ABI wrapper.

`CjguiInternalRendererNoRealDrawableReadiness` is now the canonical no-real-drawable endpoint. Future work near command buffer commit / GPU submission, real backend shell implementation or real drawable acquisition must first run docs-only preflight with fresh owner / lifecycle / teardown / failure / verification evidence.

## Synchronized Docs

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [Real drawable lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-preflight-decision.md)
- [Real drawable lifecycle next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-next-boundary-decision.md)
- [Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)

## Next Stage Candidate Comparison

### A. P1 internal Renderer command buffer commit / GPU submission preflight decision

推荐为唯一 next opening。

It remains docs-only and only evaluates command buffer commit / GPU submission gating, drawable present relation, no-submit fallback, command buffer ownership relation and verification strategy. It must not create command buffer, present drawable, submit GPU work, execute render or write renderer state.

### B. Real backend shell implementation preflight

暂缓。

Real backend shell implementation should wait until command buffer commit / GPU submission has been assessed as docs-only evidence.

### C. Real drawable hardening

仅在 availability / acquisition / presentation ownership expression gap appears 时选择。Current manifest does not show that gap.

### D. Direct drawable acquisition implementation

拒绝。

### E. Direct command buffer / render pass / encoder implementation

拒绝。

### F. GPU submission / render execution implementation

拒绝。

### G. Renderer state write

拒绝。

### H. Public API / C ABI expansion

拒绝。

### I. Receipt / record / publication

拒绝。

### J. Consolidation

仅在明确 duplicate / low-value / self-wrapping evidence 出现时选择。

## Validation

- `git diff --check`：passed.
- Markdown absolute link missing target check：passed, scoped to project docs and excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：passed for manifest, closure and next opening.
- Forbidden path check：passed; no tracked `.cj` diff, no protected path diff/status, and `runtime_state.cj` remains `10065` lines.
- Public declaration scan：passed; the only public declaration remains `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：recorded as LOW risk with no affected processes.
- Build / smoke：not run by design; this round is docs-only.

## Unique Next Opening

`P1 internal Renderer command buffer commit / GPU submission preflight decision`

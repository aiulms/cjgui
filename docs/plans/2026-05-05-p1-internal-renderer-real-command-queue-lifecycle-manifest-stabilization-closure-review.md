# P1 internal Renderer real command queue lifecycle manifest stabilization closure review

日期：2026-05-05

状态：closure review

## Scope

本轮执行 `P1 internal Renderer real command queue lifecycle manifest stabilization bundle implementation`。

目标是固定 `runtime_renderer_real_command_queue.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-real-command-queue endpoint。

本轮保持 docs-only：没有修改 `.cj`，没有运行 `cjpm build` / smoke，没有触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，没有创建 `MTLCommandQueue`，没有创建 command buffer / drawable / render pass / encoder / pipeline state，没有调用 Metal / AppKit / Objective-C / FFI，没有 commit / present / submit GPU work，没有执行 render，没有写 renderer state，没有扩 public API / C ABI。

## Inputs Read

- [runtime_renderer_real_command_queue.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_queue.cj)
- [2026-05-05-p1-renderer-real-command-queue-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-next-boundary-decision.md)
- [2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-value-boundary-closure-review.md)
- [2026-05-05-p1-renderer-real-command-queue-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-preflight-decision.md)
- [2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)

## Docs Added

- [2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md)

## Manifest Conclusion

Owner file：

- `runtime/cjgui/src/runtime_renderer_real_command_queue.cj`

Canonical endpoint：

- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`

Runtime input：

- `CjguiInternalRendererNoBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`

Current truth：

- real command queue lifecycle intent value facts.
- queue creation policy value facts.
- queue ownership guard value facts.
- queue teardown policy value facts.
- no-real-command-queue-readiness value facts.

`RealCommandQueueCreationPolicy` does not create `MTLCommandQueue` and does not call `newCommandQueue`. It only records future queue creation prerequisite / fallback value facts.

`RealCommandQueueOwnershipGuard` does not hold native handle, raw pointer, foreign resource token or backend resource. It only records backend-local confinement, no core resource leak and no resource borrow facts.

`RealCommandQueueTeardownPolicy` does not execute real release, destroy, foreign teardown, bridge cleanup or state mutation. It only records future shutdown ordering, failure rollback and no-real-queue cleanup facts.

`NoRealCommandQueueReadiness` is not `MTLCommandQueue` permission, command buffer permission, drawable permission, GPU submission permission, backend implementation permission, render permission, renderer state write permission, diagnostics permission, public API permission or C ABI permission.

## Same-shape Boundary Brake

This manifest closes the no-real-command-queue endpoint and prevents another tail wrapper.

Rejected next shapes:

- real command queue receipt / record / publication.
- queue-ready permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.
- public API / C ABI wrapper.

`CjguiInternalRendererNoRealCommandQueueReadiness` is now the canonical no-real-command-queue endpoint. Future work near real drawable lifecycle, command buffer commit / GPU submission or real backend shell implementation must first run docs-only preflight with fresh owner / lifecycle / teardown / failure / verification evidence.

## Synchronized Docs

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [Real command queue lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-preflight-decision.md)
- [Real command queue lifecycle next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-next-boundary-decision.md)
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)

## Next Stage Candidate Comparison

### A. P1 internal Renderer real drawable lifecycle preflight decision

推荐为唯一 next opening。

It remains docs-only and only evaluates drawable availability, acquisition timing, borrowing / presentation ownership, resize / scale / color relation and no-real-drawable readiness. It must not acquire drawable, expose texture, create command buffer, submit GPU work or render.

### B. Command buffer commit / GPU submission preflight

暂缓。

Real drawable lifecycle and command buffer ownership must be clarified first.

### C. Real backend shell implementation preflight

暂缓。

No-draw backend shell and real command queue lifecycle remain value facts only.

### D. Real command queue hardening

仅在 creation / ownership / teardown expression gap appears 时选择。Current manifest does not show that gap.

### E. Direct `MTLCommandQueue` implementation

拒绝。

### F. Command buffer / GPU submission / render execution

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
- New docs whitespace check：passed.
- Markdown absolute link missing target check：passed, scoped to project docs and excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：passed for manifest, closure and next opening.
- Forbidden path check：passed; no tracked `.cj` diff, no protected path diff/status, and `runtime_state.cj` remains `10065` lines.
- Public declaration scan：passed; the only public declaration remains `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：recorded as LOW risk with no affected processes.
- Build / smoke：not run by design; this round is docs-only.

## Unique Next Opening

`P1 internal Renderer real drawable lifecycle preflight decision`

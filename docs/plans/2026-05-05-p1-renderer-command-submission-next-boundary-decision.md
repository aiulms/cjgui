# P1 Renderer command submission next-boundary decision

日期：2026-05-05

状态：docs-only next-boundary decision

## Scope

本轮评估 `CjguiInternalRendererNoGpuSubmissionReadiness` 是否已经足够作为当前 no-gpu-submission endpoint，并决定下一步是否先做 manifest stabilization。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不调用 `commit`、`present` 或 `nextDrawable`，不创建 command buffer、drawable、render pass、encoder 或 pipeline state，不调用 Metal / AppKit / Objective-C / FFI，不提交 GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [runtime_renderer_command_submission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_submission.cj)
- [2026-05-05-p1-internal-renderer-command-submission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-command-submission-value-boundary-closure-review.md)
- [2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md)
- [2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)

## Endpoint Decision

`CjguiInternalRendererNoGpuSubmissionReadiness` / `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()` is sufficient as the current no-gpu-submission endpoint.

It is sufficient because the owner now has a distinct value chain:

1. `CjguiInternalRendererNoRealDrawableReadiness`
2. `CjguiInternalRendererCommandSubmissionIntent`
3. `CjguiInternalRendererCommandBufferCommitPolicy`
4. `CjguiInternalRendererDrawablePresentationGate`
5. `CjguiInternalRendererGpuSubmissionFailurePolicy`
6. `CjguiInternalRendererNoGpuSubmissionReadiness`

The endpoint only represents:

- command submission intent value facts.
- command buffer commit policy value facts.
- drawable presentation gate value facts.
- GPU submission failure policy value facts.
- no-gpu-submission readiness value facts.

It is not:

- command buffer permission.
- drawable present permission.
- GPU submission permission.
- render permission.
- backend implementation permission.
- renderer state write permission.
- public API permission.
- public C ABI permission.

## Evidence

### Command submission owner evidence

[runtime_renderer_command_submission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_submission.cj) consumes only `CjguiInternalRendererNoRealDrawableReadiness`.

It builds command submission intent, command buffer commit policy, drawable presentation gate, GPU submission failure policy and no-gpu-submission readiness in owner-local value facts. Open path preserves upstream no-real-drawable facts and seals no-gpu-submission readiness; defer remains defer; blocked / inconsistent facts fail closed.

The owner explicitly records denial facts for no command buffer creation, no command buffer commit, no drawable presentation, no GPU work submitted, no render execution / renderer state write, no foreign or pointer resource, no callback / telemetry publication, no bridge / smoke / harness / entry change, no GPU submission permission, no command-buffer-ready wrapper, no drawable-present-ready wrapper, no backend implementation wrapper, no render-permission wrapper and no receipt / record / publication.

### Closure evidence

[Command submission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-command-submission-value-boundary-closure-review.md) records the landed owner and verification. It confirms the boundary added commit policy / presentation gate / GPU submission failure / no-gpu-submission readiness semantics rather than a thin wrapper over `CjguiInternalRendererNoRealDrawableReadiness`.

The closure also records that `cjpm build` passed through the local toolchain environment, smoke auto-close passed, stop-line scans found no actual `commit(...)`, `present(...)`, `nextDrawable(...)`, platform API token, native handle / raw pointer token, public declaration or module-level `var`, and GitNexus `detect_changes` reported low risk with no affected processes.

### Preflight evidence

[Command buffer commit / GPU submission preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md) already proved enough evidence to open the value boundary. It grounded the owner shape in real drawable endpoint, real command queue endpoint, no-draw backend shell endpoint, command buffer lifecycle, render execution no-op, state write no-write and backend / Metal reference evidence.

### Upstream lifecycle evidence

[Real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md) fixed `CjguiInternalRendererNoRealDrawableReadiness` as the upstream endpoint. It does not query drawable pools, call `nextDrawable`, acquire drawable, present drawable, create command buffer, submit GPU work, execute render or write renderer state.

[Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md) provides queue creation / ownership / teardown vocabulary while denying `MTLCommandQueue` permission, command buffer permission, drawable permission, GPU submission permission and render permission.

[No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md) keeps the backend shell path value-only and denies backend shell permission, backend implementation permission, GPU submission permission, render permission and renderer state write permission.

## Candidate Comparison

### A. P1 internal Renderer command submission manifest stabilization bundle implementation

推荐选择。

`CjguiInternalRendererNoGpuSubmissionReadiness` is now a meaningful endpoint with command submission intent / commit policy / presentation gate / failure policy / no-gpu-submission facts. The next move should stabilize owner / truth / canonical endpoint / stop-line before opening real backend shell implementation, completion tracking or any implementation runway.

### B. Real backend shell implementation preflight

暂缓。

The no-gpu-submission endpoint is new and should first be manifest-stabilized. Real backend shell implementation preflight would be easier to reason about once command submission stop-lines are fixed in a manifest.

### C. Render completion / frame completion tracking preflight

暂缓。

Completion tracking is too close to callback, telemetry, observer, frame completion and renderer state visibility. Current owner only allows dehydrated failure / rollback / no-draw facts and explicitly denies callback registration / telemetry publication.

### D. Command submission hardening

暂缓，仅在发现不足时选择。

Current commit policy / presentation gate / failure policy expression is sufficient for endpoint closure. Choose hardening only if a future review finds a concrete gap in those facts.

### E. Command buffer commit implementation

拒绝。

No command buffer creation or `commit` is approved.

### F. Drawable present implementation

拒绝。

No drawable acquisition or `present` is approved.

### G. GPU submission / render execution implementation

拒绝。

No GPU work submission, render execution, encoder calls, draw calls or command buffer execution is approved.

### H. Renderer state write

拒绝。

No renderer state mutation and no `runtime_state.cj` write are approved.

### I. Public API / C ABI expansion

拒绝。

Public allowlist remains unchanged.

### J. Receipt / record / publication

拒绝。

Do not add command submission receipt / record / publication, GPU-submission permission wrapper, command-buffer-ready wrapper, drawable-present-ready wrapper, render-permission wrapper, backend implementation wrapper or renderer-state-write wrapper.

### K. Consolidation

仅在发现明确 duplicate / self-wrapping evidence 时选择。

Current evidence points to endpoint stabilization, not deletion or consolidation.

## Same-shape Boundary Brake

`CjguiInternalRendererNoGpuSubmissionReadiness` must not be wrapped into another tail endpoint.

This decision explicitly rejects:

- command submission receipt / record / publication.
- GPU-submission permission wrapper.
- command-buffer-ready wrapper.
- drawable-present-ready wrapper.
- render-permission wrapper.
- backend implementation wrapper.
- renderer-state-write wrapper.
- public API / C ABI wrapper.

The current endpoint only represents command submission intent / command buffer commit policy / drawable presentation gate / GPU submission failure policy / no-gpu-submission readiness value facts. It is not permission to create command buffer, present drawable, submit GPU work, render, implement backend, write renderer state or expose public API.

## Future Stop-line

The next manifest stabilization round must remain docs-only and must not:

- modify `.cj`.
- run build or smoke.
- create command buffer, drawable, render pass, encoder or pipeline state.
- call `commit`, `present` or `nextDrawable`.
- call Metal / AppKit / Objective-C / FFI.
- submit GPU work.
- execute render.
- write renderer state or touch `runtime_state.cj`.
- expand public API / C ABI.
- touch protected paths.

## Validation Plan

This docs-only decision should be verified with:

- `git diff --check`
- new decision no-index whitespace check.
- Markdown absolute link missing target check, scoped to project docs and excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability.
- forbidden check: no tracked `.cj` diff, no protected path diff / status, `runtime_state.cj` line count remains `10065`.
- public declaration scan still finds only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`.

## Unique Next Opening

`P1 internal Renderer command submission manifest stabilization bundle implementation`

## Downstream

Downstream command submission manifest stabilization is now recorded in:

- [2026-05-05-p1-renderer-command-submission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [2026-05-05-p1-internal-renderer-command-submission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-command-submission-manifest-stabilization-closure-review.md)

That manifest fixes `runtime_renderer_command_submission.cj` owner / truth / canonical endpoint / stop-line. The downstream no-gpu-submission endpoint remains value-only and still denies command buffer creation, `commit`, drawable present, `present`, `nextDrawable`, GPU submission, render execution, renderer state write, backend implementation and public API / C ABI expansion.

The next opening after manifest stabilization is:

- `P1 internal Renderer real backend shell implementation preflight decision`

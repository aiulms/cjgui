# P1 Renderer real command queue lifecycle next-boundary decision

日期：2026-05-05

状态：docs-only next-boundary decision

## Scope

本轮评估 `CjguiInternalRendererNoRealCommandQueueReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()` 是否已经足够作为当前 no-real-command-queue endpoint，并决定下一步是否先做 manifest stabilization。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 `MTLCommandQueue`，不创建 command buffer / drawable / render pass / encoder / pipeline state，不调用 Metal / AppKit / Objective-C / FFI，不 commit / present / submit GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [runtime_renderer_real_command_queue.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_queue.cj)
- [Real command queue lifecycle value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-value-boundary-closure-review.md)
- [Real command queue lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-preflight-decision.md)
- [Command queue / drawable real lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-queue-drawable-real-lifecycle-preflight-decision.md)
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [Command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)

## Endpoint Assessment

`CjguiInternalRendererNoRealCommandQueueReadiness` is sufficient as the current no-real-command-queue endpoint.

Why it is sufficient:

- It is owned by `runtime/cjgui/src/runtime_renderer_real_command_queue.cj`.
- It consumes only `CjguiInternalRendererNoBackendShellReadiness` through `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`.
- It seals the owner-local chain: real command queue lifecycle intent -> queue creation policy -> queue ownership guard -> queue teardown policy -> no-real-command-queue readiness.
- It has open / defer / blocked semantics and fails closed for inconsistent upstream or local facts.
- It confirms no real queue creation, no foreign API call, no backend resource creation, no resource borrow, no foreign resource token, no pointer-like resource, no work submit, no render work, no state mutation and no external surface.
- It rejects queue-ready permission, backend implementation wrapper, work-submit wrapper, buffer-ready wrapper, receipt / record / publication and thin wrapper semantics.

Current truth is exactly:

- real command queue lifecycle intent value facts.
- queue creation policy value facts.
- queue ownership guard value facts.
- queue teardown policy value facts.
- no-real-command-queue-readiness value facts.

## Decision

Choose:

`P1 internal Renderer real command queue lifecycle manifest stabilization bundle implementation`

Reasoning:

- The value boundary has enough independent queue creation / ownership / teardown semantics to be closed as an endpoint.
- The next safe step is to fix owner / truth / canonical endpoint / stop-line in a manifest before opening downstream real drawable lifecycle or command buffer / GPU submission questions.
- Real drawable lifecycle depends on queue owner truth and should wait until this no-real-command-queue endpoint is manifest-stabilized.
- Command buffer commit / GPU submission remains too close to real platform work and is not justified by this endpoint.

## Candidate Comparison

### A. P1 internal Renderer real command queue lifecycle manifest stabilization bundle implementation

推荐。

This fixes `runtime_renderer_real_command_queue.cj` owner / truth / canonical endpoint / stop-line and closes the no-real-command-queue endpoint. It should state that `CjguiInternalRendererNoRealCommandQueueReadiness` is not command queue permission, command buffer permission, GPU submission permission, backend implementation permission, render permission, renderer state write permission, public API permission or C ABI permission.

### B. Real drawable lifecycle preflight

暂缓。

Drawable lifecycle is downstream of queue owner vocabulary. It should wait until the real command queue lifecycle manifest stabilizes the owner, creation policy, ownership guard, teardown policy and no-real-command-queue endpoint.

### C. Command buffer commit / GPU submission preflight

暂缓。

This is still too close to real GPU work. It requires at least real command queue manifest truth, real drawable lifecycle truth, command buffer ownership and no-submit / failure semantics.

### D. Real backend shell implementation preflight

暂缓。

No-draw backend shell and real command queue lifecycle remain value facts only. Real backend shell implementation should wait until real resource owner manifests clarify queue / drawable / teardown / failure boundaries.

### E. Real command queue lifecycle hardening

暂缓。

Only choose hardening if manifest stabilization discovers missing queue creation policy / ownership guard / teardown / failure vocabulary. Current closure evidence is sufficient.

### F. Direct `MTLCommandQueue` implementation

拒绝。

This would create a real platform queue without approved real device owner, bridge ownership ABI, teardown path, drawable relation, command buffer gate or verification strategy.

### G. Command buffer / drawable / render pass / encoder implementation

拒绝。

These are downstream platform lifecycle questions and require separate docs-only preflights after the queue endpoint is manifest-stabilized.

### H. GPU submission / render execution

拒绝。

No-submit / no-render remains active.

### I. Renderer state write

拒绝。

No renderer state mutation is approved.

### J. Public API / C ABI expansion

拒绝。

The public declaration allowlist remains unchanged.

### K. Real command queue receipt / record / publication

拒绝。

These would repackage `CjguiInternalRendererNoRealCommandQueueReadiness` without adding new owner truth.

### L. Queue-ready permission wrapper

拒绝。

The endpoint is no-real-command-queue readiness, not permission to create or use a real queue.

### M. Backend implementation wrapper

拒绝。

Backend implementation remains explicitly out of scope.

### N. GPU-submission wrapper

拒绝。

The owner explicitly preserves no-submit semantics.

### O. Command-buffer-ready wrapper

拒绝。

Command buffer lifecycle remains downstream and must not be inferred from queue value facts.

### P. Consolidation

暂缓。

Only choose consolidation if explicit duplicate / low-value / self-wrapping evidence appears. Current evidence points to manifest stabilization, not deletion or consolidation.

## Same-shape Boundary Brake

`CjguiInternalRendererNoRealCommandQueueReadiness` must not continue as a tail wrapper.

Current endpoint represents only:

- real command queue lifecycle intent.
- queue creation policy.
- ownership guard.
- teardown policy.
- no-real-command-queue-readiness value facts.

It is not:

- `MTLCommandQueue` permission.
- command buffer permission.
- drawable permission.
- render pass / encoder / pipeline state permission.
- GPU submission permission.
- backend implementation permission.
- render permission.
- renderer state write permission.
- public API permission.
- C ABI permission.

Do not approve:

- real command queue receipt / record / publication.
- queue-ready permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.
- public API / C ABI wrapper.

Future work approaching real drawable lifecycle, command buffer commit / GPU submission, real backend shell implementation or platform APIs must first pass docs-only preflight and must not be inferred from this endpoint.

## Stop-line

This decision does not approve:

- `MTLCommandQueue` creation.
- command buffer creation.
- drawable acquisition.
- render pass creation.
- encoder creation.
- pipeline state creation.
- Metal / AppKit / Objective-C / FFI calls.
- command buffer commit.
- drawable present.
- GPU submission.
- render execution.
- renderer state write.
- public API / C ABI expansion.
- smoke / harness / native bridge / entry modification.

## Validation Plan

This docs-only round must validate:

- `git diff --check`
- Markdown absolute link missing target check, scoped to project docs and excluding `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability for this decision and the next opening
- forbidden check confirming no tracked `.cj` diff, no protected path diff/status and `runtime_state.cj` remains `10065` lines
- public declaration scan confirming only `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`

Build / smoke must not run in this round.

## Unique Next Opening

`P1 internal Renderer real command queue lifecycle manifest stabilization bundle implementation`

## Downstream Manifest Stabilization

Real command queue lifecycle manifest stabilization is now recorded in:

- [2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md)

The manifest fixes `runtime_renderer_real_command_queue.cj` owner / truth / canonical endpoint / stop-line and keeps the no-real-command-queue endpoint value-only. It does not approve `MTLCommandQueue` creation, drawable acquisition, command buffer creation, GPU submission, render execution, renderer state write or public API / C ABI expansion.

Current downstream next opening:

`P1 internal Renderer real drawable lifecycle preflight decision`

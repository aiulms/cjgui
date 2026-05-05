# P1 Renderer real drawable lifecycle next-boundary decision

日期：2026-05-05

状态：docs-only next-boundary decision

## Scope

本轮评估 `CjguiInternalRendererNoRealDrawableReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()` 是否已经足够作为当前 no-real-drawable endpoint，并决定下一步是否进入 manifest stabilization。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不获取 drawable，不调用 `nextDrawable`，不创建 `CAMetalDrawable` / `MTLDrawable`，不创建 command buffer / render pass / encoder / pipeline state，不调用 Metal / AppKit / Objective-C / FFI，不 present / commit / submit GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [runtime_renderer_real_drawable.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_drawable.cj)
- [Real drawable lifecycle value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-lifecycle-value-boundary-closure-review.md)
- [Real drawable lifecycle preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-preflight-decision.md)
- [Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [Drawable acquisition lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)

## Endpoint Assessment

`CjguiInternalRendererNoRealDrawableReadiness` is sufficient as the current no-real-drawable endpoint.

Reasoning:

- The owner has distinct real drawable lifecycle semantics: lifecycle intent, drawable availability policy, drawable acquisition guard, presentation ownership policy and no-real-drawable readiness value facts.
- The default draft consumes only `CjguiInternalRendererNoRealCommandQueueReadiness` and keeps all drawable evidence dehydrated; docs evidence remains evidence only.
- The endpoint preserves fail-closed behavior for defer-only, blocked and inconsistent upstream states, so it does not fabricate drawable readiness.
- The endpoint explicitly records that no drawable is acquired, no drawable object is held, no drawable texture is exposed, no submission object is created, no pass / encoder object is created, no foreign API is called, no resource token or pointer-like resource is held, no work is submitted, no render work is executed, no renderer state is mutated and no bridge / smoke / harness / native entry is changed.
- The value boundary closure already verified build, smoke, forbidden-path, public declaration and stop-line scans for the implementation round; this docs-only decision does not re-run build or smoke.

## Decision

Choose:

`P1 internal Renderer real drawable lifecycle manifest stabilization bundle implementation`

This decision has now been implemented by:

- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [real drawable lifecycle manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-lifecycle-manifest-stabilization-closure-review.md)

That manifest fixes the owner / truth / canonical endpoint / stop-line for `runtime/cjgui/src/runtime_renderer_real_drawable.cj` and closes the current no-real-drawable endpoint. It remains docs-only and does not acquire drawable, call platform APIs, present / commit / submit GPU work, execute render, write renderer state or expand public API / C ABI.

## Candidate Comparison

### A. P1 internal Renderer real drawable lifecycle manifest stabilization bundle implementation

推荐。

`CjguiInternalRendererNoRealDrawableReadiness` is already a sufficiently shaped no-real-drawable endpoint, so the safest next step is manifest stabilization: owner file, current truth, canonical endpoint, default draft and stop-line should be fixed before evaluating command buffer commit / GPU submission or real backend implementation.

### B. Command buffer commit / GPU submission preflight

暂缓。

This must wait until the real drawable endpoint is manifest-stabilized. Commit / submit is too close to real GPU work and needs closed drawable ownership, command buffer and no-submit failure evidence first.

### C. Real backend shell implementation preflight

暂缓。

The current chain still contains no-real-command-queue and no-real-drawable value facts. Real backend shell implementation should wait until real queue / drawable lifecycle manifests and later resource teardown evidence are closed.

### D. Real drawable hardening

暂缓。

Only choose hardening if manifest review finds a concrete gap in drawable availability, acquisition guard or presentation ownership expression. Current evidence is sufficient for manifest stabilization.

### E. Real drawable receipt / record / publication

拒绝。

This would repackage the endpoint without adding owner truth.

### F. Drawable-ready permission wrapper

拒绝。

The current endpoint is explicitly no-real-drawable readiness, not drawable-ready permission.

### G. Backend implementation wrapper

拒绝。

No backend implementation owner, platform object, bridge ABI, teardown implementation or verification strategy is approved.

### H. GPU-submission wrapper

拒绝。

No present / commit / submit permission exists in this endpoint.

### I. Command-buffer-ready wrapper

拒绝。

Command buffer creation / commit remains a separate downstream runway and cannot be inferred from no-real-drawable facts.

### J. Render-permission wrapper

拒绝。

The endpoint does not execute render and does not grant render permission.

### K. Public API / C ABI expansion

拒绝。

The public declaration allowlist remains unchanged.

### L. Consolidation

暂缓。

Only choose consolidation if explicit duplicate / low-value / self-wrapping evidence appears. Current evidence points to manifest stabilization, not deletion or consolidation.

## Same-shape Boundary Brake

`CjguiInternalRendererNoRealDrawableReadiness` must not be wrapped again as a tail endpoint.

Current endpoint truth is only:

- real drawable lifecycle intent value facts.
- drawable availability policy value facts.
- drawable acquisition guard value facts.
- presentation ownership policy value facts.
- no-real-drawable-readiness value facts.

It is not drawable permission, command buffer permission, GPU submission permission, backend implementation permission, render permission, renderer state write permission, public API permission or C ABI permission.

The next step must stabilize this endpoint. It must not add real drawable receipt / record / publication, drawable-ready permission wrapper, backend implementation wrapper, GPU-submission wrapper, command-buffer-ready wrapper, render-permission wrapper or public API / C ABI expansion.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no drawable acquisition.
- no `nextDrawable`.
- no `CAMetalDrawable` / `MTLDrawable` creation or holding.
- no drawable texture exposure.
- no command buffer.
- no render pass.
- no encoder.
- no pipeline state.
- no Metal / AppKit / Objective-C / FFI call.
- no drawable present.
- no command buffer commit.
- no GPU submission.
- no render execution.
- no renderer state write.
- no bridge / smoke / harness / native entry modification.
- no public API / public C ABI expansion.

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

Implemented by:

- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [real drawable lifecycle manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-lifecycle-manifest-stabilization-closure-review.md)

The next opening after manifest stabilization is:

`P1 internal Renderer command buffer commit / GPU submission preflight decision`

下一轮必须 docs-only；评估 command buffer commit / GPU submission runway。不得获取 drawable，不得调用 `nextDrawable`，不得创建或持有 `CAMetalDrawable` / `MTLDrawable`，不得创建 command buffer / render pass / encoder / pipeline state，不得调用 Metal / AppKit / Objective-C / FFI，不得 present / commit / submit GPU work，不得执行 render，不得写 renderer state，不得扩 public API / C ABI。

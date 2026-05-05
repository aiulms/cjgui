# P1 Renderer real drawable lifecycle preflight decision

日期：2026-05-05

状态：docs-only preflight decision

## Scope

本轮评估是否允许打开 real drawable lifecycle runway，并决定下一步是否可以进入 internal value boundary。

本轮 docs-only：不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不获取 drawable，不创建 `CAMetalDrawable` / `MTLDrawable`，不创建 command buffer / render pass / encoder / pipeline state，不创建 `MTLCommandQueue` / `MTLDevice` / `CAMetalLayer`，不调用 Metal / AppKit / Objective-C / FFI，不 present / commit / submit GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [Real command queue lifecycle manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md)
- [Drawable acquisition lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [Command queue / drawable real lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-queue-drawable-real-lifecycle-preflight-decision.md)
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

## Decision

允许打开 real drawable lifecycle runway。

下一步选择：

`P1 internal Renderer real drawable lifecycle value boundary bundle implementation`

Reasoning:

- Real command queue lifecycle manifest has closed `CjguiInternalRendererNoRealCommandQueueReadiness` as the current no-real-command-queue endpoint.
- Existing drawable acquisition lifecycle manifest already proves independent drawable lifecycle vocabulary: drawable availability policy, acquisition timing guard, presentation ownership policy and no-drawable readiness value facts.
- Backend / Metal reference pack gives enough official evidence that drawable acquisition is late-bound, availability-sensitive, may fail / return unavailable, and must remain backend-local.
- GUI risk ledger reinforces that GPU resource lifetime and FFI ownership must be explicit before any real resource is created.
- Therefore the next safe step is a value-only owner for real drawable lifecycle facts, not a real drawable acquisition implementation.

## Recommended Owner And Runtime Input

Default candidate owner:

- `runtime/cjgui/src/runtime_renderer_real_drawable.cj`

Runtime input should only consume:

- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`

Docs evidence may cite the drawable acquisition lifecycle manifest, backend / Metal reference pack, command queue / drawable real lifecycle preflight, no-draw backend shell manifest, real command queue manifest and GUI risk ledger. These documents must remain evidence only and must not become additional runtime inputs.

The earlier split placeholder `runtime_renderer_real_drawable_lifecycle.cj` is treated as an equivalent runway name only. This preflight recommends `runtime_renderer_real_drawable.cj` for consistency with the current task and owner file naming.

## Future Truth Shape

If a future value boundary is approved, output truth must be limited to:

- real drawable lifecycle intent value facts.
- drawable availability policy value facts.
- drawable acquisition guard value facts.
- presentation ownership policy value facts.
- no-real-drawable-readiness value facts.

Allowed dehydrated facts:

- drawable availability phase.
- late acquisition constraint.
- unavailable / timeout / invalid layer fallback.
- borrowing / presentation ownership relation.
- resize / backing scale / drawable size / color relation.
- no-draw fallback and rollback expectation.

These facts must not hold `CAMetalDrawable`, `MTLDrawable`, drawable texture, `CAMetalLayer`, command buffer, render pass, encoder, pipeline state, native handle, raw pointer, platform object, callback, resource token or backend-local object.

## Boundary Requirements

The future real drawable lifecycle owner must not:

- acquire drawable.
- call `nextDrawable`.
- hold `CAMetalDrawable` / `MTLDrawable`.
- expose drawable texture.
- create command buffer.
- create render pass / encoder / pipeline state.
- create `MTLCommandQueue` / `MTLDevice` / `CAMetalLayer`.
- call Metal / AppKit / Objective-C / FFI APIs.
- present drawable.
- commit command buffer.
- submit GPU work.
- execute render.
- modify bridge / smoke / harness / native entry.
- write renderer state.
- expand public API / C ABI.

`CjguiInternalRendererNoRealDrawableReadiness`, if implemented later, must not be drawable-ready permission, drawable acquisition permission, command buffer permission, render pass permission, encoder permission, GPU submission permission, backend implementation permission, render permission, renderer state write permission, public API permission or C ABI permission.

## Reference Evidence

Evidence supports choosing A:

- Real command queue lifecycle manifest fixed the upstream no-real-command-queue endpoint and explicitly denies drawable permission, command buffer permission, GPU submission permission and render permission.
- Drawable acquisition lifecycle manifest fixed availability / acquisition timing / presentation ownership / no-drawable readiness as distinct lifecycle facts; this proves real drawable lifecycle has more semantics than a tail wrapper.
- Backend / Metal reference pack records that `CAMetalLayer` owns a limited drawable pool, `nextDrawable()` can wait or return unavailable, drawable texture is the render target, and drawable should be requested late and released quickly.
- Backend / Metal reference pack also states `MTKView` current drawable / render pass conveniences remain platform owner choices, not core renderer packet truth.
- No-draw backend shell manifest preserves no-submit / no-render semantics and requires command queue / drawable real lifecycle to stay docs-first until separately approved.
- GUI risk ledger identifies GPU resource lifecycle, FFI ownership, platform object teardown and main-thread exclusivity as risks, which argues for value facts before acquisition.

Evidence is still not enough to implement:

- no real drawable owner exists.
- no bridge ownership ABI, handle table, generation table or teardown implementation is approved.
- no real platform object / native handle representation is approved.
- no command buffer creation or commit gate is approved.
- no presentation ownership implementation is approved.
- no renderer state write or completion observation implementation is approved.
- lab smoke remains evidence only and cannot become runtime truth.

## Candidate Comparison

### A. P1 internal Renderer real drawable lifecycle value boundary bundle implementation

推荐。

This is justified because availability / acquisition guard / presentation ownership / failure fallback / no-real-drawable semantics are distinct from `CjguiInternalRendererNoRealCommandQueueReadiness`. The next round still must only add internal value facts and must not acquire drawable or call platform APIs.

### B. Command buffer commit / GPU submission preflight

暂缓。

This should wait until real drawable lifecycle is manifest-stabilized. Commit / submit requires drawable relation, command buffer owner, resource lifetime and no-submit failure semantics.

### C. Real backend shell implementation preflight

暂缓。

No-draw backend shell, real command queue and real drawable lifecycle remain value facts. Real backend shell implementation should wait until resource owner manifests cover queue, drawable, teardown and failure paths.

### D. Real drawable reference hardening docs

暂缓。

Only choose this if future review finds availability / acquisition / presentation ownership / failure evidence insufficient. Current evidence is sufficient for a value boundary.

### E. Direct drawable acquisition implementation

拒绝。

No owner, handle model, bridge ABI, teardown path, command buffer relation or verification strategy has been approved for real drawable acquisition.

### F. Command buffer / render pass / encoder implementation

拒绝。

These are downstream of real drawable lifecycle and require separate docs-only preflights.

### G. GPU submission / render execution

拒绝。

No-submit / no-render remains active.

### H. Renderer state write

拒绝。

No renderer state mutation is approved.

### I. Public API / C ABI expansion

拒绝。

The public declaration allowlist remains unchanged.

### J. Receipt / record / publication / drawable-ready permission wrapper

拒绝。

These would repackage `CjguiInternalRendererNoRealCommandQueueReadiness` without adding drawable availability / acquisition guard / presentation ownership semantics.

### K. Consolidation

暂缓。

Only choose consolidation if explicit duplicate / low-value / self-wrapping evidence appears. Current evidence points to a new real drawable value boundary, not deletion or consolidation.

## Same-shape Boundary Brake

Do not wrap `CjguiInternalRendererNoRealCommandQueueReadiness` into:

- real drawable receipt.
- real drawable record.
- real drawable publication.
- drawable-ready permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.
- public API / C ABI wrapper.

The next step must add drawable availability / acquisition guard / presentation ownership / no-real-drawable-readiness semantics. It must not be a no-real-command-queue tail wrapper.

## Future Stop-line

The next round, even if it implements a value boundary, must not:

- acquire drawable.
- call `nextDrawable`.
- create or hold `CAMetalDrawable` / `MTLDrawable`.
- expose drawable texture.
- create command buffer.
- create render pass / encoder / pipeline state.
- create `MTLCommandQueue` / `MTLDevice` / `CAMetalLayer`.
- call Metal / AppKit / Objective-C / FFI.
- modify bridge / smoke / harness / native entry.
- present drawable.
- commit command buffer.
- submit GPU work.
- execute render.
- write renderer state.
- expand public API / C ABI.

## Validation Plan

This docs-only round must validate:

- `git diff --check`
- Markdown absolute link missing target check, scoped to project docs and excluding `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability for this preflight and the next opening
- forbidden check confirming no tracked `.cj` diff, no protected path diff/status and `runtime_state.cj` remains `10065` lines
- public declaration scan confirming only `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`

Build / smoke must not run in this round.

## Unique Next Opening

Implemented by:

- [real drawable lifecycle value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-lifecycle-value-boundary-closure-review.md)

Next-boundary decision after implementation is recorded in:

- [real drawable lifecycle next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-next-boundary-decision.md)

Manifest stabilization after that decision is recorded in:

- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [real drawable lifecycle manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-lifecycle-manifest-stabilization-closure-review.md)

The next opening after manifest stabilization is:

`P1 internal Renderer command buffer commit / GPU submission preflight decision`

下一轮必须 docs-only；评估 command buffer commit / GPU submission runway。不得修改 `.cj`，不得获取 drawable，不得调用 `nextDrawable`，不得创建或持有 `CAMetalDrawable` / `MTLDrawable`，不得创建 command buffer / render pass / encoder / pipeline state，不得调用 Metal / AppKit / Objective-C / FFI，不得 present / commit / submit GPU work，不得执行 render，不得写 renderer state，不得扩 public API / C ABI。

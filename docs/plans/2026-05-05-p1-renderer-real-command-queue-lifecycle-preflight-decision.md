# P1 Renderer real command queue lifecycle preflight decision

日期：2026-05-05

状态：docs-only preflight decision

## Scope

本轮评估是否允许打开 real command queue lifecycle runway。

本轮 docs-only：不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 `MTLCommandQueue`，不创建 `MTLDevice` / `CAMetalLayer`，不获取 drawable，不创建 command buffer / render pass / encoder / pipeline state，不调用 FFI / Objective-C / Metal / AppKit API，不 commit / present / submit GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [Command queue / drawable real lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-queue-drawable-real-lifecycle-preflight-decision.md)
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [Command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [Drawable acquisition lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

## Decision

允许打开 real command queue lifecycle runway。

下一步选择：

`P1 internal Renderer real command queue lifecycle value boundary bundle implementation`

下一步仍只能是 internal value boundary，不是真实 `MTLCommandQueue` creation。它只能新增 real command queue lifecycle value facts，不得调用 Metal / AppKit / Objective-C / FFI，不得创建 command queue、command buffer、drawable、render pass、encoder、pipeline state、`MTLDevice`、`CAMetalLayer`、platform object、native handle or raw pointer，不得 commit / present / submit GPU work，不得执行 render，不得写 renderer state，不得扩 public API / C ABI。

## Proposed Runtime Boundary

默认候选 owner：

- `runtime/cjgui/src/runtime_renderer_real_command_queue.cj`

建议唯一 runtime input：

- `CjguiInternalRendererNoBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`

Docs evidence 可以引用 command queue lifecycle manifest、command queue / drawable real lifecycle preflight、no-draw backend shell manifest、Metal device-layer owner manifest、drawable acquisition lifecycle manifest、backend / Metal reference pack 和 GUI risk ledger，但不得作为多 runtime input。

允许 output truth 仅限：

- real command queue lifecycle intent value facts.
- queue creation policy value facts.
- queue ownership guard value facts.
- queue teardown policy value facts.
- no-real-command-queue-readiness value facts.

## Required Boundary Truth

下一轮 value boundary 必须明确：

- Real command queue lifecycle owner 只表达 future command queue lifecycle intent，不创建 `MTLCommandQueue`。
- Queue creation policy 只表达 future creation preconditions / no-device / no-backend-shell fallback facts，不调用 `newCommandQueue` 或任何 Metal API。
- Queue ownership guard 只表达 future backend-local queue ownership / confinement / no-core-leak facts，不持有 native handle、raw pointer、platform object or resource token。
- Queue teardown policy 只表达 future shutdown / rollback / no-queue cleanup ordering facts，不执行 retain / release / destroy / foreign teardown calls。
- No-real-command-queue readiness 不是 queue-ready permission、backend implementation permission、command buffer permission、drawable permission、GPU submission permission、render permission、renderer state write permission、public API permission or C ABI permission。
- Default draft must consume only `CjguiInternalRendererNoBackendShellReadiness` and fail closed on blocked / inconsistent input.

## Reference Evidence

Evidence 足够选择 A：

- Command queue / drawable real lifecycle preflight 已拆分 queue 与 drawable runway，并选择 real command queue lifecycle as first owner question because queue ownership / creation / lifetime is upstream of drawable and command buffer creation.
- No-draw backend shell manifest has sealed `CjguiInternalRendererNoBackendShellReadiness` and explicitly denies command queue / drawable / command buffer / render permission. A real command queue value boundary can preserve that endpoint while adding queue creation policy / ownership guard / teardown / no-real-queue facts.
- Command queue lifecycle manifest already provides lifecycle intent, lifecycle ownership policy, creation guard, lifetime / shutdown / rollback and no-command-queue readiness vocabulary. That evidence supports a real command queue value boundary, but the old owner remains no-resource value facts.
- Backend / Metal reference pack states that `MTLDevice` is the root for device-specific objects, `MTLCommandQueue` creates command buffers and orders execution, and future command queue / command buffer lifecycle must remain backend-local.
- Metal device-layer owner manifest confirms device / layer policy facts exist but no real `MTLDevice` / `CAMetalLayer` permission exists.
- Drawable acquisition lifecycle manifest confirms drawable lifecycle is separate, late-bound and availability-sensitive; it should stay downstream of real command queue lifecycle.
- GUI risk ledger highlights GPU resource lifecycle, FFI ownership, platform thread exclusivity and verification gaps, which argues for a no-resource value boundary before any real command queue implementation.

Evidence 不足以 implement：

- no runtime real command queue owner exists.
- no `MTLDevice` owner or platform object creation permission exists.
- no bridge ownership ABI, handle table, generation table or teardown implementation is approved.
- no `newCommandQueue` call surface is approved.
- no command buffer creation / commit / GPU submission gate is approved.
- no drawable real lifecycle owner is approved.
- no renderer state write or completion tracking implementation is approved.
- lab smoke evidence remains lab-only and cannot become runtime truth.

## Candidate Comparison

### A. P1 internal Renderer real command queue lifecycle value boundary bundle implementation

推荐。

Evidence is sufficient to add internal-only value facts for real command queue lifecycle intent / queue creation policy / queue ownership guard / queue teardown policy / no-real-command-queue readiness. 下一轮仍不得创建 `MTLCommandQueue` or call any Metal API.

### B. Real drawable lifecycle preflight

暂缓。

Drawable lifecycle should wait until real command queue lifecycle manifest fixes queue owner truth. Drawable availability and late acquisition depend on backend-local queue / layer / no-submit relation, and should not be opened before queue lifecycle vocabulary is stabilized.

### C. Command buffer commit / GPU submission preflight

暂缓。

Still too early. Command buffer commit requires real command queue owner truth, drawable / presentation relation, resource lifetime policy and completion / failure semantics.

### D. Real backend shell implementation preflight

暂缓。

No-draw backend shell remains value facts only. Real backend shell implementation should wait until real command queue and drawable owner preflights clarify resource boundaries.

### E. Command queue reference hardening docs

暂缓。

Current evidence is sufficient. Choose hardening only if the next implementation finds creation / ownership / teardown / failure vocabulary insufficient.

### F. Direct `MTLCommandQueue` implementation

拒绝。

This would create a Metal object without approved `MTLDevice`, platform owner, native handle policy, teardown path or verification strategy.

### G. Command buffer / drawable implementation

拒绝。

Command buffer and drawable materialization remain downstream of real command queue lifecycle and later real drawable lifecycle preflight.

### H. GPU submission / render execution

拒绝。

No-submit / no-render remains active.

### I. Renderer state write

拒绝。

No renderer state mutation is approved.

### J. Public API / C ABI expansion

拒绝。

Public allowlist remains unchanged.

### K. Receipt / record / publication / queue-ready permission wrapper

拒绝。

These would repackage `CjguiInternalRendererNoBackendShellReadiness` without adding queue creation policy / ownership guard / teardown policy / no-real-command-queue readiness semantics.

### L. Consolidation

暂缓。

Only choose consolidation if explicit duplicate / low-value / self-wrapping evidence appears. Current evidence points to a real command queue lifecycle value boundary.

## Same-shape Boundary Brake

Do not wrap `CjguiInternalRendererNoBackendShellReadiness` into:

- real command queue receipt.
- real command queue record.
- real command queue publication.
- queue-ready permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.
- public API / C ABI wrapper.

If the next step chooses A, it must prove the new owner adds queue creation policy / ownership guard / teardown policy / no-real-command-queue-readiness semantics. It must not be a no-backend-shell tail wrapper.

## Future Stop-line

下一轮即使实现 value boundary，也继续禁止：

- no `MTLCommandQueue` creation.
- no `newCommandQueue` call.
- no `MTLDevice` creation.
- no `CAMetalLayer` creation.
- no drawable acquisition.
- no command buffer creation.
- no command buffer commit.
- no render pass creation.
- no encoder creation.
- no pipeline state creation.
- no backend shell object creation.
- no backend object creation.
- no platform object creation.
- no native handle.
- no raw pointer.
- no FFI / Objective-C / Metal / AppKit API call.
- no bridge / smoke / harness / native entry modification.
- no drawable present.
- no GPU submission.
- no render execution.
- no renderer state write.
- no diagnostics / event bus / observer / telemetry.
- no public API / public C ABI expansion.

## Downstream Result

[Real command queue lifecycle value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-value-boundary-closure-review.md) completed the recommended next step.

It added `runtime/cjgui/src/runtime_renderer_real_command_queue.cj` with:

- `CjguiInternalRendererRealCommandQueueLifecycleIntent`
- `CjguiInternalRendererRealCommandQueueCreationPolicy`
- `CjguiInternalRendererRealCommandQueueOwnershipGuard`
- `CjguiInternalRendererRealCommandQueueTeardownPolicy`
- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`

The next opening after the value boundary is:

`P1 internal Renderer real command queue lifecycle closure / next real command queue decision`

## Downstream Next-Boundary Decision

[Real command queue lifecycle next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-next-boundary-decision.md) confirmed `CjguiInternalRendererNoRealCommandQueueReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()` is sufficient as the current no-real-command-queue endpoint.

The next opening after that decision is:

`P1 internal Renderer real command queue lifecycle manifest stabilization bundle implementation`

## Downstream Manifest Stabilization

Real command queue lifecycle manifest stabilization is now recorded in:

- [2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md)

The manifest closes `CjguiInternalRendererNoRealCommandQueueReadiness` as the canonical no-real-command-queue endpoint. The current downstream next opening is:

`P1 internal Renderer real drawable lifecycle preflight decision`

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

`P1 internal Renderer real command queue lifecycle value boundary bundle implementation`

下一轮仍只能新增 internal value facts；不得创建 `MTLCommandQueue`、`MTLDevice`、`CAMetalLayer`、drawable、command buffer、render pass、encoder、pipeline state、backend shell object、backend object、platform object、native handle or raw pointer，不得调用 Metal / AppKit / Objective-C / FFI，不得 commit / present / submit GPU work，不得执行 render，不得写 renderer state，不得扩 public API / C ABI。

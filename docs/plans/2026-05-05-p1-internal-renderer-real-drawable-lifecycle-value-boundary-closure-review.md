# P1 internal Renderer real drawable lifecycle value boundary closure review

日期：2026-05-05

状态：bounded implementation closure

## Scope

本轮新增 internal-only real drawable lifecycle value boundary，并保持 no-real-drawable / no-platform-object / no-render stop-line。

允许的 runtime write set 只有：

- [runtime_renderer_real_drawable.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_drawable.cj)

同步文档：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [real drawable lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-preflight-decision.md)
- [real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)

## GitNexus Impact

Pre-edit impact was run for the required upstream symbols:

- `CjguiInternalRendererNoRealCommandQueueReadiness`: `UNKNOWN / not found`, impacted count `0`.
- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft`: `UNKNOWN / not found`, impacted count `0`.

No HIGH / CRITICAL result was returned. This matches the recent renderer owner pattern where newly added symbols are not yet indexed. This closure therefore relies on source existence, build, smoke and stop-line scans as the fallback verification path.

## Landed Owner

Owner file:

- [runtime_renderer_real_drawable.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_drawable.cj)

Runtime input:

- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`

Canonical endpoint:

- `CjguiInternalRendererNoRealDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()`

## New Internal Symbols

- `CjguiInternalRendererRealDrawableLifecycleIntent`
- `CjguiInternalRendererRealDrawableAvailabilityPolicy`
- `CjguiInternalRendererRealDrawableAcquisitionGuard`
- `CjguiInternalRendererRealDrawablePresentationOwnershipPolicy`
- `CjguiInternalRendererNoRealDrawableReadiness`
- `cjguiInternalBuildRendererRealDrawableLifecycleIntent`
- `cjguiInternalBuildRendererRealDrawableAvailabilityPolicy`
- `cjguiInternalBuildRendererRealDrawableAcquisitionGuard`
- `cjguiInternalBuildRendererRealDrawablePresentationOwnershipPolicy`
- `cjguiInternalBuildRendererNoRealDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()`

## Boundary Conclusion

The new owner only forms value facts:

- real drawable lifecycle intent.
- drawable availability policy.
- drawable acquisition guard.
- presentation ownership policy.
- no-real-drawable readiness.

`CjguiInternalRendererNoRealDrawableReadiness` is not drawable-ready permission, drawable acquisition permission, command buffer permission, backend implementation permission, work submission permission, render permission, renderer state write permission, public API permission or C ABI permission.

The owner does not acquire drawable, call a platform API, hold a platform drawable object, expose a drawable texture, create a submission object, create pass / encoder / pipeline objects, submit work, execute render, write renderer state, modify bridge / smoke / harness / native entry, or expand public API / C ABI.

## Same-shape Boundary Brake

This boundary is not a wrapper around `CjguiInternalRendererNoRealCommandQueueReadiness`.

The added semantics are:

- drawable availability and unavailable fallback facts.
- late-bound acquisition guard facts.
- no borrowed resource / no resource token facts.
- presentation ownership and release expectation facts.
- no-real-drawable stop-line facts.

Explicitly rejected:

- real drawable receipt / record / publication.
- drawable-ready permission wrapper.
- backend implementation wrapper.
- work-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.
- public API / C ABI wrapper.

## Validation

- `cjpm build --target-dir /tmp/cjgui-renderer-real-drawable-lifecycle-value-boundary-target --skip-script`
  - Bare `cjpm` was not on PATH.
  - Re-run with `/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` passed.
  - Result: `cjpm build success`; warnings were existing unused-symbol warnings.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
  - Passed: `cjgui verify: auto-close log assertions passed`.
  - The smoke remains legacy guard evidence only, not runtime truth.
- `git diff --check`
  - Passed.
- Markdown absolute link missing target check, scoped to project docs / project docs entrypoints and excluding `reference_repos/`
  - Passed.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README closure reachability
  - Passed; all four entrypoints mention this closure and the next opening.
- Forbidden path check
  - Passed; protected paths showed no diff / status.
  - `runtime/cjgui/src/runtime_state.cj` remains `10065` lines.
- Public declaration scan
  - Passed; the only public declaration remains `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- New owner stop-line source scan
  - Passed; `runtime_renderer_real_drawable.cj` does not contain real drawable acquisition, platform object, foreign API, resource token, pointer-like resource, work submit, render work, state mutation, public declaration or module-level `var` implementation.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`
  - Risk: `low`.
  - Affected processes: none.
  - Changed indexed symbols were documentation sections only; the new owner follows the recent unindexed-owner fallback path covered by build and source scans.

## Unique Next Opening

`P1 internal Renderer real drawable lifecycle closure / next real drawable decision`

The next round must be docs-only. It should decide whether `CjguiInternalRendererNoRealDrawableReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()` is sufficient as the current no-real-drawable endpoint and whether to proceed to manifest stabilization. It must not acquire drawable, call platform APIs, present / commit / submit work, execute render, write renderer state, or expand public API / C ABI.

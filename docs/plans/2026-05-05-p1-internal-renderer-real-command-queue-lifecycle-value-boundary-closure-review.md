# P1 internal Renderer real command queue lifecycle value boundary closure review

日期：2026-05-05

状态：完成

## Scope

本轮执行 `P1 internal Renderer real command queue lifecycle value boundary bundle implementation`。

允许新增一个 internal-only runtime owner，但继续禁止真实 `MTLCommandQueue` / Metal / AppKit / Objective-C / FFI / GPU submission / render execution / renderer state write。

## Inputs Read

- [runtime_renderer_no_draw_backend_shell.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_no_draw_backend_shell.cj)
- [Real command queue lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-preflight-decision.md)
- [Command queue / drawable real lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-queue-drawable-real-lifecycle-preflight-decision.md)
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [Command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)

## GitNexus Impact

Required pre-edit impact:

- `CjguiInternalRendererNoBackendShellReadiness`: `UNKNOWN / not found`, impacted count `0`.
- `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft`: `UNKNOWN / not found`, impacted count `0`.

No HIGH / CRITICAL impact was reported. This matches recent unindexed renderer owner behavior, so the round used source existence plus build and scans as fallback evidence.

## Landed Runtime Owner

Added:

- [runtime_renderer_real_command_queue.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_queue.cj)

New internal symbols:

- `CjguiInternalRendererRealCommandQueueLifecycleIntent`
- `CjguiInternalRendererRealCommandQueueCreationPolicy`
- `CjguiInternalRendererRealCommandQueueOwnershipGuard`
- `CjguiInternalRendererRealCommandQueueTeardownPolicy`
- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `cjguiInternalBuildRendererRealCommandQueueLifecycleIntent`
- `cjguiInternalBuildRendererRealCommandQueueCreationPolicy`
- `cjguiInternalBuildRendererRealCommandQueueOwnershipGuard`
- `cjguiInternalBuildRendererRealCommandQueueTeardownPolicy`
- `cjguiInternalBuildRendererNoRealCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`

## Boundary Conclusion

The owner consumes only:

- `CjguiInternalRendererNoBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`

The canonical endpoint is:

- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`

The landed truth is limited to:

- real command queue lifecycle intent value facts.
- queue creation policy value facts.
- queue ownership guard value facts.
- queue teardown policy value facts.
- no-real-command-queue-readiness value facts.

Open path preserves the upstream no-backend-shell readiness and projects it into queue lifecycle facts. Defer-only path remains deferred without fabricating queue readiness. Blocked or inconsistent input fails closed.

## Stop-line

The new owner does not:

- create `MTLCommandQueue`.
- call `newCommandQueue`.
- call FFI / Objective-C / Metal / AppKit API.
- create `MTLDevice` / `CAMetalLayer`.
- create drawable / command buffer / render pass / encoder / pipeline state.
- hold native handle / raw pointer.
- modify bridge / smoke / harness / native entry.
- commit / present / submit GPU work.
- execute render.
- write renderer state or touch `runtime_state.cj`.
- add module-level `var`.
- add public declaration or C ABI.
- attach diagnostics / event bus / observer / telemetry / public API.

## Same-shape Boundary Brake

This is not a wrapper around `CjguiInternalRendererNoBackendShellReadiness`.

The new fields and builder stages add queue creation policy / ownership guard / teardown policy / no-real-command-queue-readiness semantics. The closure rejects:

- real command queue receipt / record / publication.
- queue-ready permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.

## Validation

- Bare `cjpm build --target-dir /tmp/cjgui-renderer-real-command-queue-lifecycle-value-boundary-target --skip-script`: `cjpm` was not in PATH.
- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-renderer-real-command-queue-lifecycle-value-boundary-target --skip-script`: passed with existing unused warnings only.
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`: passed.
- `git diff --check`: passed.
- `git diff --check --no-index /dev/null` for the new runtime owner and new closure doc: passed.
- Markdown absolute link missing target check, scoped to project docs and excluding `reference_repos/`: passed.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README closure reachability: passed.
- Forbidden path check: no protected path diff/status; `runtime_state.cj` remains `10065` lines.
- Public declaration scan: still only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- New owner stop-line scan: no forbidden platform / submit / state / visibility terms were found.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: risk `low`, affected processes `0`.

## Unique Next Opening

`P1 internal Renderer real command queue lifecycle closure / next real command queue decision`

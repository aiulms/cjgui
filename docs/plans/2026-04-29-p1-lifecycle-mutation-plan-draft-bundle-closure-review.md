# P1 Lifecycle Mutation Plan Draft Bundle Closure Review

## Scope Closed

- Added app owner-specific `CjguiInternalAppLifecycleMutationPlanDraft`, `cjguiInternalBuildAppLifecycleMutationPlanDraft`, and open / blocked sanity helpers in `runtime/cjgui/src/app_lifecycle.cj`.
- Added window owner-specific `CjguiInternalWindowLifecycleMutationPlanDraft`, `cjguiInternalBuildWindowLifecycleMutationPlanDraft`, and open / blocked sanity helpers in `runtime/cjgui/src/window_lifecycle.cj`.
- Added runtime cross-owner `CjguiInternalLifecycleMutationPlanRequest`, `CjguiInternalLifecycleMutationPlanReport`, builder, evaluator, executor, default executor, and open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers in `runtime/cjgui/src/runtime_state.cj`.

## Behavior Summary

- App/window plan drafts only project mutation readiness into should-plan / defer-plan / blocked-plan facts.
- Runtime plan summary only consumes `CjguiInternalLifecycleMutationReadinessReport.appReadiness` / `windowReadiness`.
- The plan draft does not execute lifecycle mutation, does not modify app/window state, and does not call state-changing transition functions.

## Verification

- `cjpm build --target-dir /tmp/cjgui-lifecycle-mutation-plan-draft-bundle-target --skip-script` passed after envsetup, with unused warnings only.
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed.
- `git diff --check` passed.

## Stop-Line

- No public runtime API or public C ABI.
- No `cjpm.toml`, `src/main.cj`, `package_anchor.cj`, smoke, harness, native bridge, or Cangjie entry changes.
- No AppKit / Metal / Objective-C binding, platform object, native handle, raw pointer, event loop, scheduling loop, callback binding, queue / drain, input processing, layout / render, app run / shutdown, window create / close / destroy / release, handle table, or generation work.

## Next Opening

`P1 lifecycle mutation plan draft bundle closure / next runtime behavior decision`

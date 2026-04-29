# P1 Lifecycle Mutation Apply Draft Bundle Closure Review

## Scope Closed

- Added app owner-specific `CjguiInternalAppLifecycleMutationApplyDraft`, `cjguiInternalBuildAppLifecycleMutationApplyDraft`, and open / blocked sanity helpers in `runtime/cjgui/src/app_lifecycle.cj`.
- Added window owner-specific `CjguiInternalWindowLifecycleMutationApplyDraft`, `cjguiInternalBuildWindowLifecycleMutationApplyDraft`, and open / blocked sanity helpers in `runtime/cjgui/src/window_lifecycle.cj`.
- Added runtime cross-owner `CjguiInternalLifecycleMutationApplyRequest`, `CjguiInternalLifecycleMutationApplyReport`, builder, evaluator, executor, default executor, and open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity helpers in `runtime/cjgui/src/runtime_state.cj`.

## Behavior Summary

- App/window apply drafts only project mutation commit gate facts into apply / defer-apply / blocked-apply intent.
- Runtime apply summary only consumes `CjguiInternalLifecycleMutationCommitGateReport.appCommitGate` / `windowCommitGate`.
- The apply draft does not execute lifecycle mutation, does not apply state, does not modify app/window state, and does not call state-changing transition functions.

## Verification

- `cjpm build --target-dir /tmp/cjgui-lifecycle-mutation-apply-draft-bundle-target --skip-script` passed after envsetup, with unused warnings only.
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` passed.
- `git diff --check` passed.

## Stop-Line

- No public runtime API or public C ABI.
- No `cjpm.toml`, `src/main.cj`, `package_anchor.cj`, smoke, harness, native bridge, Cangjie entry, `AGENTS.md`, or `CLAUDE.md` changes.
- No AppKit / Metal / Objective-C binding, platform object, native handle, raw pointer, event loop, scheduling loop, callback binding, queue / drain, input processing, layout / render, app run / shutdown, window create / close / destroy / release, handle table, generation, lifecycle mutation, transition execution, or state apply work.

## Next Opening

`P1 lifecycle mutation apply draft bundle closure / next runtime behavior decision`

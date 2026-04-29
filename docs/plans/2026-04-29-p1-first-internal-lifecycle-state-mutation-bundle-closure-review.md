# P1 First Internal Lifecycle State Mutation Bundle Closure Review

日期：2026-04-29

## Scope Closed

- `app_lifecycle.cj` 新增 `CjguiInternalAppLifecycleMutationResult`、`cjguiInternalApplyAppLifecycleMutationDraft`、open / blocked sanity。
- `window_lifecycle.cj` 新增 `CjguiInternalWindowLifecycleMutationResult`、`cjguiInternalApplyWindowLifecycleMutationDraft`、open / blocked sanity。
- `runtime_state.cj` 新增 `CjguiInternalLifecycleStateMutationRequest`、`CjguiInternalLifecycleStateMutationReport`、builder、evaluator、draft executor、default executor，以及 open / runtime-blocked / input-blocked / shutdown-blocked / cancellation-blocked sanity。

## Behavior Summary

- 这是 first internal state value transition，但仍只在 internal runtime skeleton 内。
- App open path 以 immutable-copy 生成 `CjguiInternalAppLifecycleState(true, true, state.hasObservedPlatformReady)`。
- Window open path 以 immutable-copy 生成 `CjguiInternalWindowLifecycleState(true, state.hasObservedPlatformReady)`。
- Blocked / deferred path 返回原 state unchanged，并保留 defer / blocked flags。
- `runtime_state.cj` 只消费 `CjguiInternalLifecycleMutationApplyReport.appApply` / `windowApply` 与 prior app/window states，汇总 cross-owner result。

## Verification

- `cjpm build --target-dir /tmp/cjgui-first-lifecycle-state-mutation-bundle-target --skip-script`：通过，仅 existing unused warnings。
- smoke guard：通过。
- `git diff --check`：通过。

## Stop-Line

- 不新增 public runtime API 或 public C ABI。
- 不接入 AppKit / Metal / Objective-C，不暴露 platform object、native handle 或 raw pointer。
- 不实现 event loop、`while` / scheduling loop、queue / drain、platform callback、input processing、layout / render、app run / shutdown 或 window create / close / destroy / release。
- 不使用 var / in-place mutation，不改变既有 state field semantics，不调用 existing app/window state-changing transition functions。
- 不修改 `cjpm.toml`、`src/main.cj`、`package_anchor.cj`、`labs/macos_bridge_smoke`、harness、native bridge、`AGENTS.md` 或 `CLAUDE.md`。

## Next Opening

`P1 first internal lifecycle state mutation bundle closure / next runtime behavior decision`

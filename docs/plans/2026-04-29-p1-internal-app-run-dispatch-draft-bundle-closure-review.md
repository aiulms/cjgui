# P1 Internal App Run Dispatch Draft Bundle Closure Review

日期：2026-04-29

## Scope Closed

本轮完成 `P1 internal app run dispatch draft bundle implementation`，作为 W3 internal subsystem draft 直接实现，不新增 preflight / execution card，也不拆成 one-helper slices。

新增 internal-only types：

- `CjguiInternalAppRunDispatchRequest`
- `CjguiInternalAppRunDispatchSummary`
- `CjguiInternalAppRunDispatchReport`

新增 internal-only functions：

- `cjguiInternalBuildAppRunDispatchRequest`
- `cjguiInternalBuildAppRunDispatchSummary`
- `cjguiInternalEvaluateAppRunDispatch`
- `cjguiInternalExecuteAppRunDispatchDraft`
- `cjguiInternalExecuteDefaultAppRunDispatchDraft`
- `cjguiInternalAppRunDispatchOpenSanity`
- `cjguiInternalAppRunDispatchRuntimeBlockedSanity`
- `cjguiInternalAppRunDispatchInputBlockedSanity`
- `cjguiInternalAppRunDispatchShutdownBlockedSanity`
- `cjguiInternalAppRunDispatchCancellationBlockedSanity`

## Behavior Summary

Dispatch draft 只消费 `CjguiInternalAppRunExecutionPlanReport`，并只读取 `planReport.plan`。它把 execution plan 的 prepare / run-loop-draft / defer / blocked / future-boundary signals 投影为 dispatch-facing summary。

Open path 会构建 prepare-runtime、run-loop-draft 与 future-boundary request summary；runtime-not-ready、input-blocked、shutdown-blocked、cancellation-blocked path 都 fail closed，并生成 deferred / blocked notice summary。

## Verification

- RED build：缺少 dispatch executor 时，`cjpm build --target-dir /tmp/cjgui-app-run-dispatch-draft-bundle-red-target --skip-script` 按预期失败。
- GREEN build：`cjpm build --target-dir /tmp/cjgui-app-run-dispatch-draft-bundle-target --skip-script` 通过，仅有既有 unused warnings。
- Smoke guard：`labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- Diff check：`git diff --check` 通过。

## Stop-Line

本轮未新增 public runtime API / public C ABI，未接入 AppKit / Metal / Objective-C，未暴露 platform object / native handle / raw pointer，未实现 event loop / callback binding / queue / drain，未执行 dispatch / `run()` / shutdown / cancellation，未创建 window，未新增 handle table / generation。

Dispatch draft 不得被解释为真实 dispatch result；`shouldDispatchRunLoopDraft` 只是 internal dehydrated marker，不表示真实 event loop 或 queue item。

## Next Opening

建议 next opening：

`P1 internal app run dispatch draft bundle closure / next runtime behavior decision`

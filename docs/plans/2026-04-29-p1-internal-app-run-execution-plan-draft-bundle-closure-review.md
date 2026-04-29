# P1 Internal App Run Execution Plan Draft Bundle Closure Review

日期：2026-04-29

## Scope Closed

本轮完成 `P1 internal app run execution plan draft bundle implementation`，作为 W3 internal subsystem draft 直接实现，不新增 preflight / execution card，也不拆成 one-helper slices。

新增 internal-only types：

- `CjguiInternalAppRunExecutionPlanRequest`
- `CjguiInternalAppRunExecutionPlan`
- `CjguiInternalAppRunExecutionPlanReport`

新增 internal-only functions：

- `cjguiInternalBuildAppRunExecutionPlanRequest`
- `cjguiInternalBuildAppRunExecutionPlan`
- `cjguiInternalEvaluateAppRunExecutionPlan`
- `cjguiInternalExecuteAppRunExecutionPlanDraft`
- `cjguiInternalExecuteDefaultAppRunExecutionPlanDraft`
- `cjguiInternalAppRunExecutionPlanOpenSanity`
- `cjguiInternalAppRunExecutionPlanRuntimeBlockedSanity`
- `cjguiInternalAppRunExecutionPlanInputBlockedSanity`
- `cjguiInternalAppRunExecutionPlanShutdownBlockedSanity`
- `cjguiInternalAppRunExecutionPlanCancellationBlockedSanity`

## Behavior Summary

Execution plan draft 只消费 `CjguiInternalAppRunControllerReport`，并只读取 `controllerReport.decision`。它把 accepted / deferred / blocked / future-boundary controller decision 投影为 `shouldPrepareRuntime`、`shouldEnterRunLoopDraft`、`shouldDeferExecution`、`shouldReportBlockedExecution` 与 `shouldRequestFutureBoundary`。

Open path 会构建 accepted plan；runtime-not-ready、input-blocked、shutdown-blocked、cancellation-blocked path 都 fail closed，并生成 defer / blocked-report plan summary。

## Verification

- RED build：缺少 execution plan executor 时，`cjpm build --target-dir /tmp/cjgui-app-run-execution-plan-draft-bundle-red-target --skip-script` 按预期失败。
- GREEN build：`cjpm build --target-dir /tmp/cjgui-app-run-execution-plan-draft-bundle-target --skip-script` 通过，仅有既有 unused warnings。
- Smoke guard：`labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- Diff check：`git diff --check` 通过。

## Stop-Line

本轮未新增 public runtime API / public C ABI，未接入 AppKit / Metal / Objective-C，未暴露 platform object / native handle / raw pointer，未实现 event loop / callback binding / queue / drain，未执行 `run()` / shutdown / cancellation，未创建 window，未新增 handle table / generation。

Execution plan draft 不得被解释为真实 execution plan executor；`shouldEnterRunLoopDraft` 只是 internal dehydrated marker，不表示真实 event loop。

## Next Opening

建议 next opening：

`P1 internal app run execution plan draft bundle closure / next runtime behavior decision`

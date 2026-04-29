# P1 Internal Shutdown / Cancellation Intent Bundle Closure Review

日期：2026-04-29

## Scope

本轮完成 `P1 internal shutdown / cancellation intent bundle implementation`，authority 来自 [2026-04-29-p1-internal-runtime-readiness-run-boundary-chain-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-readiness-run-boundary-chain-compaction.md)。

新增默认 internal shutdown / cancellation intent layer：

- `CjguiInternalRuntimeShutdownIntent`
- `CjguiInternalRuntimeShutdownRequest`
- `CjguiInternalRuntimeShutdownReport`
- `cjguiInternalDefaultRuntimeShutdownIntent()`
- `cjguiInternalBuildRuntimeShutdownIntent(shouldRequestShutdown: Bool, shouldRequestCancellation: Bool)`
- `cjguiInternalBuildRuntimeShutdownRequest(intent: CjguiInternalRuntimeShutdownIntent)`
- `cjguiInternalEvaluateRuntimeShutdownRequest(request: CjguiInternalRuntimeShutdownRequest)`
- `cjguiInternalRuntimeShutdownIdleSanity()`
- `cjguiInternalRuntimeShutdownRequestedSanity()`
- `cjguiInternalRuntimeCancellationRequestedSanity()`
- `cjguiInternalRuntimeShutdownAndCancellationRequestedSanity()`

## Result

默认 intent 为 idle，不 defer run request。shutdown、cancellation 或二者同时请求时，shutdown report 只把内部影响规整为 defer-run 与 enter-path flags。

本轮没有把 shutdown intent 宣称为真实 shutdown，也没有把 cancellation intent 宣称为真实 task / queue cancellation。

## Verification

- `cjpm build --target-dir /tmp/cjgui-shutdown-cancellation-intent-bundle-target --skip-script`：通过，仅 existing/internal unused warnings。
- `verify_auto_close.sh`：通过。
- `git diff --check`：通过。

## Stop-Line

未新增 public runtime API / public C ABI，未修改 `cjpm.toml`，未新增 `src/main.cj` / `package_anchor.cj`，未修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。

未接入 AppKit / Metal / Objective-C，未暴露 platform object / native handle / raw pointer，未实现 event loop、callback binding、queue / drain、app run / shutdown、window create / close / destroy / release 或 handle table / generation。

## Next Opening

`P1 internal shutdown / cancellation intent bundle closure / next run-boundary decision`

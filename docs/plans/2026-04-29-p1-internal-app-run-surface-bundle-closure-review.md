# P1 Internal App Run Surface Bundle Closure Review

日期：2026-04-29

类型：bundled closure / mini-compaction

authority：

- [2026-04-29-p1-internal-app-run-surface-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-app-run-surface-boundary-compaction.md)

## Closed Scope

本轮一次完成 W3 internal app run surface bundle，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal types：

- `CjguiInternalAppRunState`
  - `boundaryReport: CjguiInternalRunBoundaryReport`
  - `isAppRunAllowed: Bool`
  - `isAppRunDeferred: Bool`
  - `isAppRunBlocked: Bool`
- `CjguiInternalAppRunRequest`
  - `boundaryReport: CjguiInternalRunBoundaryReport`
- `CjguiInternalAppRunReport`
  - `request: CjguiInternalAppRunRequest`
  - `state: CjguiInternalAppRunState`
  - `didAcceptAppRun: Bool`
  - `shouldDeferAppRun: Bool`
  - `shouldReportAppRunBlocked: Bool`

新增默认 internal functions：

- `cjguiInternalBuildAppRunState(boundaryReport)`
- `cjguiInternalBuildAppRunRequest(boundaryReport)`
- `cjguiInternalEvaluateAppRunRequest(request)`
- `cjguiInternalExecuteAppRunSurfaceDraft(driverRequest, driverInput, driverPolicy, shutdownIntent)`
- `cjguiInternalExecuteDefaultAppRunSurfaceDraft()`
- `cjguiInternalAppRunSurfaceOpenSanity()`
- `cjguiInternalAppRunSurfaceRuntimeBlockedSanity()`
- `cjguiInternalAppRunSurfaceInputBlockedSanity()`
- `cjguiInternalAppRunSurfaceShutdownBlockedSanity()`
- `cjguiInternalAppRunSurfaceCancellationBlockedSanity()`

## Behavior Summary

AppRun surface 只消费 `CjguiInternalRunBoundaryReport`，并把 run boundary open / deferred / blocked 投影为脱水 app run state / request / report。

- default open path：`didAcceptAppRun=true`。
- runtime-not-ready / input-blocked boundary：defer app run and report blocked。
- shutdown / cancellation boundary：defer app run and report blocked。

本轮不执行 `run()`，不启动 event loop，不 drain queue，不调用平台，不触发真实 shutdown / cancellation。

## Verification

- RED：只加入 AppRun sanity helpers 后，`cjpm build --target-dir /tmp/cjgui-app-run-surface-bundle-red-target --skip-script` 因缺少 AppRun draft executor 符号失败。
- GREEN：`cjpm build --target-dir /tmp/cjgui-app-run-surface-bundle-target --skip-script`：通过，仅 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `git diff --check`：通过。

## Stop-Line

- 未新增 public runtime API 或 public C ABI。
- 未修改 `cjpm.toml`。
- 未新增 `src/main.cj` 或 `package_anchor.cj`。
- 未修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 未接入 AppKit / Metal / Objective-C。
- 未暴露 platform object、native handle 或 raw pointer。
- 未实现 event loop、callback binding、queue / drain。
- 未实现 app run / shutdown。
- 未实现 window create / close / destroy / release。
- 未新增 handle table / generation。
- 未改变 existing root / bootstrap / readiness / platform / app / window type shape。
- 未改变 existing projection / coordination / bootstrap / cycle / command pipeline / driver / run request / shutdown intent / run boundary behavior。
- 未让 AppRun surface 绕过 run boundary 读取 lower-level facts。
- 未把 AppRun state 宣称为真实 running state。
- 未把 AppRun request 宣称为 public `run()` request。
- 未把 AppRun report 宣称为真实 run result。

## Next Opening

`P1 internal app run surface bundle closure / next runtime behavior decision`

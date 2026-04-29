# P1 Internal App Run Controller Draft Bundle Closure Review

日期：2026-04-29

类型：bundled closure / mini-compaction

authority：

- [2026-04-29-p1-internal-app-run-controller-boundary-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-app-run-controller-boundary-compaction.md)

## Closed Scope

本轮一次完成 W3 internal AppRun controller draft bundle，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal types：

- `CjguiInternalAppRunControllerRequest`
  - `appRunReport: CjguiInternalAppRunReport`
- `CjguiInternalAppRunControllerDecision`
  - `shouldEnterAcceptedPath: Bool`
  - `shouldEnterDeferredPath: Bool`
  - `shouldEnterBlockedPath: Bool`
  - `shouldRequestFutureRunBoundary: Bool`
- `CjguiInternalAppRunControllerReport`
  - `request: CjguiInternalAppRunControllerRequest`
  - `decision: CjguiInternalAppRunControllerDecision`
  - `didEvaluateController: Bool`

新增默认 internal functions：

- `cjguiInternalBuildAppRunControllerRequest(appRunReport)`
- `cjguiInternalDecideAppRunController(request)`
- `cjguiInternalEvaluateAppRunController(request)`
- `cjguiInternalExecuteAppRunControllerDraft(driverRequest, driverInput, driverPolicy, shutdownIntent)`
- `cjguiInternalExecuteDefaultAppRunControllerDraft()`
- `cjguiInternalAppRunControllerOpenSanity()`
- `cjguiInternalAppRunControllerRuntimeBlockedSanity()`
- `cjguiInternalAppRunControllerInputBlockedSanity()`
- `cjguiInternalAppRunControllerShutdownBlockedSanity()`
- `cjguiInternalAppRunControllerCancellationBlockedSanity()`

## Behavior Summary

AppRun controller draft 只消费 `CjguiInternalAppRunReport`，并从 AppRun surface report 派生 accepted / deferred / blocked / future-boundary next-action summary。

- default open path：accepted path=true, future boundary request=true。
- runtime-not-ready / input-blocked path：deferred + blocked, accepted=false。
- shutdown / cancellation path：deferred + blocked, accepted=false。

本轮不执行任何 action，不执行 `run()`，不启动 event loop，不 drain queue，不调用平台，不触发真实 shutdown / cancellation。

## Verification

- RED：只加入 controller sanity helpers 后，`cjpm build --target-dir /tmp/cjgui-app-run-controller-draft-bundle-red-target --skip-script` 因缺少 controller draft executor 符号失败。
- GREEN：`cjpm build --target-dir /tmp/cjgui-app-run-controller-draft-bundle-target --skip-script`：通过，仅 unused warnings。
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
- 未改变 existing projection / coordination / bootstrap / cycle / command pipeline / driver / run request / shutdown intent / run boundary / AppRun surface behavior。
- 未让 controller 绕过 AppRunReport 读取 RunBoundaryReport 或 lower-level facts。
- 未把 AppRunControllerDecision 宣称为真实 scheduler decision。
- 未把 AppRunControllerReport 宣称为真实 run result。
- 未执行 accepted / deferred / blocked action。

## Next Opening

`P1 internal app run controller draft bundle closure / next runtime behavior decision`

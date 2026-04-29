# P1 Internal Run Boundary Draft Bundle Closure Review

日期：2026-04-29

类型：bundled closure / mini-compaction

authority：

- [2026-04-29-p1-internal-run-boundary-readiness-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-run-boundary-readiness-compaction.md)

## Closed Scope

本轮一次完成 W3 internal run boundary draft bundle，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal types：

- `CjguiInternalRunBoundaryRequest`
  - `runRequestReport: CjguiInternalRuntimeRunRequestReport`
  - `shutdownReport: CjguiInternalRuntimeShutdownReport`
- `CjguiInternalRunBoundaryReport`
  - `request: CjguiInternalRunBoundaryRequest`
  - `isBoundaryOpen: Bool`
  - `isBoundaryDeferred: Bool`
  - `isBoundaryBlocked: Bool`
  - `isBlockedByRunRequest: Bool`
  - `isBlockedByShutdown: Bool`
  - `isBlockedByCancellation: Bool`

新增默认 internal functions：

- `cjguiInternalBuildRunBoundaryRequest(runRequestReport, shutdownReport)`
- `cjguiInternalEvaluateRunBoundaryRequest(request)`
- `cjguiInternalExecuteRunBoundaryDraft(driverRequest, driverInput, driverPolicy, shutdownIntent)`
- `cjguiInternalExecuteDefaultRunBoundaryDraft()`
- `cjguiInternalRunBoundaryOpenSanity()`
- `cjguiInternalRunBoundaryRuntimeBlockedSanity()`
- `cjguiInternalRunBoundaryInputBlockedSanity()`
- `cjguiInternalRunBoundaryShutdownBlockedSanity()`
- `cjguiInternalRunBoundaryCancellationBlockedSanity()`

## Behavior Summary

Run boundary draft 只聚合 run request report 与 shutdown report，并把结果规整为 open / deferred / blocked summary。

- ready + no shutdown / cancel：boundary open。
- runtime-not-ready 或 input-blocked run request：boundary deferred / blocked by run request。
- shutdown intent：boundary deferred / blocked by shutdown。
- cancellation intent：boundary deferred / blocked by cancellation。

本轮不执行 `run()`，不启动 event loop，不 drain queue，不调用平台，不触发真实 shutdown / cancellation。

## Verification

- `cjpm build --target-dir /tmp/cjgui-run-boundary-draft-bundle-target --skip-script`：通过，仅 unused warnings。
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
- 未改变 existing projection / coordination / bootstrap / cycle / command pipeline / driver / run request / shutdown intent behavior。
- 未把 run boundary draft 宣称为真实 `run()`、event loop、scheduler、queue policy、runloop policy 或 public run API。
- 未把 boundary blocked report 变成真实 error system。

## Next Opening

`P1 internal run boundary draft bundle closure / next runtime behavior decision`

# P1 Internal Runtime Run Intent Bundle Closure Review

日期：2026-04-29

类型：bundled closure / mini-compaction

authority：

- [2026-04-29-p1-internal-runtime-driver-report-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-driver-report-bundle-closure-review.md)

## Closed Scope

本轮一次完成 W3 internal runtime run intent bundle，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal type：

- `CjguiInternalRuntimeRunIntent`
  - `report: CjguiInternalRuntimeDriverReport`
  - `mayRequestRuntimeRun: Bool`
  - `shouldContinueInternalCycles: Bool`
  - `shouldSurfaceBlockedReport: Bool`
  - `didObserveInternalProgress: Bool`

新增默认 internal functions：

- `cjguiInternalBuildRuntimeRunIntent(report)`
- `cjguiInternalExecuteRuntimeRunIntentDraft(request, input, policy)`
- `cjguiInternalExecuteDefaultRuntimeRunIntentDraft()`
- `cjguiInternalRuntimeRunIntentReadySanity()`
- `cjguiInternalRuntimeRunIntentRuntimeBlockedSanity()`
- `cjguiInternalRuntimeRunIntentInputBlockedSanity()`

## Behavior Summary

- run intent 只从 `CjguiInternalRuntimeDriverReport` 投影 internal run-boundary intent fields。
- `mayRequestRuntimeRun` 等价于 `report.isReadyForNextInternalPass`。
- `shouldContinueInternalCycles` 等价于 `report.shouldRequestNextCycle`。
- `shouldSurfaceBlockedReport` 等价于 `report.shouldReportBlocked`。
- `didObserveInternalProgress` 等价于 `report.didObserveProgress`。
- ready path intent 允许 request runtime run boundary、继续 internal cycles、观察到 internal progress，且不 surface blocked report。
- runtime-not-ready blocked 与 input-blocked intent 均 fail closed：不 request runtime run boundary、不继续 internal cycles、surface blocked report、不 observe progress。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-run-intent-bundle-target --skip-script` 通过，仅 unused warnings。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。

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
- 未改变 existing driver report、driver pass、command pipeline、cycle、step、bootstrap、projection 或 coordination behavior。
- 未把 run intent 宣称为真实 run loop、scheduler、queue policy、runloop policy 或 public run API。
- 未把 blocked intent 变成真实 error system。

## Next Opening

建议 next opening：

- `P1 internal runtime run intent bundle closure / next runtime behavior decision`

下一步应基于 internal run-boundary intent summary 判断后续 runtime behavior bundle；仍不得自动进入 app run、event loop、queue / drain、window create、renderer command list 或 public surface。

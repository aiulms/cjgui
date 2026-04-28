# P1 Internal Runtime Driver Report Bundle Closure Review

日期：2026-04-29

类型：bundled closure / mini-compaction

authority：

- [2026-04-28-p1-internal-runtime-driver-input-policy-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-driver-input-policy-bundle-closure-review.md)

## Closed Scope

本轮一次完成 W3 internal runtime driver report bundle，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal type：

- `CjguiInternalRuntimeDriverReport`
  - `result: CjguiInternalRuntimeDriverResult`
  - `didCompleteDriverPass: Bool`
  - `shouldRequestNextCycle: Bool`
  - `shouldReportBlocked: Bool`
  - `didObserveProgress: Bool`
  - `isReadyForNextInternalPass: Bool`

新增默认 internal functions：

- `cjguiInternalBuildRuntimeDriverReport(result)`
- `cjguiInternalExecuteRuntimeDriverPassReport(request, input, policy)`
- `cjguiInternalExecuteDefaultRuntimeDriverPassReport()`
- `cjguiInternalRuntimeDriverReportReadySanity()`
- `cjguiInternalRuntimeDriverReportRuntimeBlockedSanity()`
- `cjguiInternalRuntimeDriverReportInputBlockedSanity()`

## Behavior Summary

- driver report 只从 `CjguiInternalRuntimeDriverResult` 复制 / 投影 stable fields。
- `isReadyForNextInternalPass` 只在 `didCompleteDriverPass=true` 且 `shouldRequestNextCycle=true` 时为 true。
- ready path report 记录 driver pass completed、request-next-cycle、observed progress 且不 report blocked。
- runtime-not-ready blocked 与 input-blocked report 均 fail closed：不 complete driver pass、不 request next cycle、report blocked、不 observe progress。
- 未改变 existing driver pass、driver input / policy / decision、gated executor、command pipeline、cycle、step、bootstrap、projection 或 coordination behavior。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-driver-report-bundle-target --skip-script` 通过，仅 unused warnings。
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
- 未新增 scheduler、runloop policy、queue policy、renderer command list 或真实 error system。
- 未把 report 宣称为真实 runtime next action。

## Next Opening

建议 next opening：

- `P1 internal runtime driver report bundle closure / next runtime behavior decision`

下一步应基于 internal driver report / next-action summary 判断后续 runtime behavior bundle；仍不得自动进入 app run、event loop、queue / drain、window create、renderer command list 或 public surface。

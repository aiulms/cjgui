# P1 Internal Runtime Run Request Bundle Closure Review

日期：2026-04-29

类型：bundled closure / mini-compaction

authority：

- [2026-04-29-p1-internal-runtime-run-intent-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-29-p1-internal-runtime-run-intent-bundle-closure-review.md)

## Closed Scope

本轮一次完成 W3 internal runtime run request bundle，没有创建新的 preflight / execution card，也没有拆成 one-helper slices。

新增默认 internal types：

- `CjguiInternalRuntimeRunRequest`
  - `intent: CjguiInternalRuntimeRunIntent`
  - `isRequestAllowed: Bool`
- `CjguiInternalRuntimeRunRequestReport`
  - `request: CjguiInternalRuntimeRunRequest`
  - `didAcceptRequest: Bool`
  - `shouldDeferRequest: Bool`
  - `shouldSurfaceBlockedReport: Bool`
  - `didObserveInternalProgress: Bool`

新增默认 internal functions：

- `cjguiInternalBuildRuntimeRunRequest(intent)`
- `cjguiInternalEvaluateRuntimeRunRequest(request)`
- `cjguiInternalExecuteRuntimeRunRequestDraft(driverRequest, input, policy)`
- `cjguiInternalExecuteDefaultRuntimeRunRequestDraft()`
- `cjguiInternalRuntimeRunRequestReadySanity()`
- `cjguiInternalRuntimeRunRequestRuntimeBlockedSanity()`
- `cjguiInternalRuntimeRunRequestInputBlockedSanity()`

## Behavior Summary

- run request 只从 `CjguiInternalRuntimeRunIntent` 包装 internal request summary。
- `isRequestAllowed` 等价于 `intent.mayRequestRuntimeRun`。
- request report 只评估 internal request：`didAcceptRequest` 等价于 `request.isRequestAllowed`，`shouldDeferRequest` 为其反向 fail-closed marker。
- `shouldSurfaceBlockedReport` 与 `didObserveInternalProgress` 只从 request intent 投影。
- ready path request report accepted、not deferred、not blocked、observed internal progress。
- runtime-not-ready blocked 与 input-blocked request report 均 fail closed：not accepted、deferred、surface blocked report、not observe progress。

## Verification

- envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-run-request-bundle-target --skip-script` 通过，仅 unused warnings。
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
- 未改变 existing driver report、run intent、driver pass、command pipeline、cycle、step、bootstrap、projection 或 coordination behavior。
- 未把 run request 宣称为真实 `run()`、event loop start、scheduler、queue policy、runloop policy 或 public run API。
- 未把 deferred request 变成真实 error system。

## Next Opening

建议 next opening：

- `P1 internal runtime run request bundle closure / next runtime behavior decision`

下一步应基于 internal run request evaluation summary 判断后续 runtime behavior bundle；仍不得自动进入 app run、event loop、queue / drain、window create、renderer command list 或 public surface。

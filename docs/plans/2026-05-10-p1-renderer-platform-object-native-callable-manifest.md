# P1 内部渲染器 platform object native callable 清单

日期：2026-05-10

状态：manifest stabilization / value boundary

## 清单结论

platform object native callable stage 已封账，当前 route 是 value boundary。它只定义 future platform object native callable 的 no-object admission 前置边界，不新增 native callable，不创建 platform object，不导入 AppKit / Metal，不返回 token / pointer / handle。

## 固定对象

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_native_callable.cj`
- Runtime input：`CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNativeCallableReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft()`
- Actual route：value boundary
- Native callable list：无新增

## No-object admission policy

当前只固定 no-object admission policy：

- platform object native callable 必须先经过 no-object admission。
- 当前不得创建 `NSWindow` / `NSView` / `CAMetalLayer`。
- 当前不得创建 `MTLDevice` / `MTLCommandQueue`。
- 当前不得导入 Cocoa / AppKit / Metal / QuartzCore。
- 当前不得返回 token、native pointer、native handle 或 object identity。

## Prerequisites

future platform object native callable 必须先满足：

- main-thread gate prerequisite。
- token issue/revoke prerequisite。
- teardown callable policy prerequisite。
- fail-closed admission path。
- no-token-return-before-object policy。

这些 prerequisites 只定义 future callable 进入真实 object creation 前的安全边界。

## Native / package 状态

- `runtime/cjgui/native/cjgui_native_bridge.h` 未修改。
- `runtime/cjgui/native/cjgui_native_bridge.m` 未修改。
- `runtime/cjgui/cjpm.toml` 未修改。
- smoke native files 未修改。
- probe scripts 未新增 platform object allowlist。

## 停止线

- no platform object native C ABI。
- no `NSWindow` / `NSView` / `CAMetalLayer`。
- no `MTLDevice` / `MTLCommandQueue`。
- no native object / handle / raw pointer。
- no native pointer return。
- no platform object token return。
- no Cocoa / AppKit / Metal / QuartzCore import。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public API / diagnostics。
- no backend-ready truth。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-native-callable-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-native-callable-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-native-callable-next-boundary-decision.md)
- [native token table no-resource issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)
- [native resource creation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-resource-creation-admission-manifest.md)
- [native bridge teardown callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md)

## 后续入口

唯一后续入口：

`P1 internal Renderer native bridge teardown callable implementation preflight decision`

该入口必须重新评估 teardown callable implementation，不得直接创建 platform object、native object、native handle、raw pointer、AppKit / Metal object、public API、renderer state write 或 backend-ready truth。

## 下游 implementation 封账

下游 [native bridge teardown callable implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-teardown-callable-implementation-manifest-stabilization-closure-review.md) 已完成。该 downstream 只把 `CjguiInternalRendererNoPlatformObjectNativeCallableReadiness` 作为 runtime input，并输出 `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft()`。

下游 [platform object AppKit import manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-import-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-appkit-import-manifest-stabilization-closure-review.md) 也已完成。该 downstream 只把 teardown admission endpoint 作为 runtime input，并输出 `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()`。

当前全局唯一后续入口已经由 no-object creation callable stage 与 real `NSView` allocation feasibility stage 接续后转为：

`P1 internal Renderer platform object token-backed NSView object table preflight decision`

该入口仍不批准跳过 preflight 的 actual platform object creation、native object、resource callable、public API、Metal / AppKit object、renderer state write 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object native callable stage 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定 `CjguiInternalRendererNoPlatformObjectNativeCallableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_native_callable.cj`；truth 固定为 no-object admission facts；stop-line 固定为 no platform object creation / no AppKit / no Metal / no public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge teardown callable implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
